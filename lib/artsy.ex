defmodule Artsy do
  @moduledoc """
  REST API wrapper for [Artsy](http://artsy.net).
  """

  import Artsy.ApiHelpers
  use Application
  use GenServer
  use HTTPoison.Base
  require Logger

  @token_min_delay 5000
  @token_reload 60 * 3
  @token_failure_delay 1000
  @token_max_retries 5

  unless Application.get_env(:artsy, Artsy) do
    raise Artsy.ConfigError, message: "Artsy is not configured"
  end

  unless Keyword.get(Application.get_env(:artsy, Artsy), :url) do
    raise Artsy.ConfigError, message: "Artsy requires url"
  end
  unless Keyword.get(Application.get_env(:artsy, Artsy), :client_id) do
    raise Artsy.ConfigError, message: "Artsy requires client_id"
  end
  unless Keyword.get(Application.get_env(:artsy, Artsy), :client_secret) do
    raise Artsy.ConfigError, message: "Artsy requires client_secret"
  end

  @spec start(any(), [any()]) :: {:ok, pid}
  def start(_type, _args) do
    Artsy.start_link()
  end

  @spec start_link() :: {:ok, pid}
  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end
  @spec start_link(atom()) :: {:ok, pid}
  def start_link(name) when is_atom(name) do
    GenServer.start_link(__MODULE__, %{})
  end

  @spec init(map()) :: {:ok, pid}
  def init(_) do
    with {:ok, token, expire} <- get_token() do
      timer = Process.send_after(self(), {:get_new_token}, get_token_delay(expire))
      {:ok, %{
        "token" => token,
        "token_expire_ts" => expire,
        "token_timer" => timer,
        "token_retries" => 0
      }}
    else
      _ ->
        raise Artsy.TokenError, message: "Can't load initial JWT token"
    end
  end


  @doc """
  Get all artworks from decoded JSON object.
  Each call will call the next page with artworks.
  """
  @spec artworks() :: {:ok, map()} | {:error, Exception.t}
  def artworks() do
    GenServer.call(__MODULE__, {:artworks})
  end

  @doc """
  Reset pagination for artworks.
  """
  @spec artworks(:reset) :: :ok
  def artworks(:reset) do
    GenServer.call(__MODULE__, {:artworks_reset})
  end

  
  @doc """
  Get all artists from decoded JSON object.
  Each call will call the next page with artists.
  """
  @spec artists() :: {:ok, map()} | {:error, Exception.t}
  def artists() do
    GenServer.call(__MODULE__, {:artists})
  end
  
  @doc """
  Get all artists for specific artwork.
  """
  @spec artists(:artwork, String.t) :: {:ok, map()} | {:error, Exception.t}
  def artists(:artwork, artwork_id) do
    GenServer.call(__MODULE__, {:artists_artwork, artwork_id})
  end


  @doc """
  Load artworks.
  We save cursor in state for effective pagination, of next request.
  Use artworks_reset to reset a pagination cursor.
  """
  def handle_call({:artworks}, _from, %{"token" => token} = state) when token != nil do
    url = Map.get(state, "next_artworks", "/artworks")
    raw_response = Artsy.get(url, headers(:token, token))
    {result, new_state} = get_request state, raw_response, fn(state, response) ->
      new_state = case response do
        %{"_links" => %{"next" => %{"href" => next_url}}} ->
          Map.put(state, "next_artworks", String.replace(next_url, config(:url), ""))
        _ ->
          state
      end
      {{:ok, response}, new_state}
    end
    {:reply, result, new_state}
  end

  @doc """
  Reset pagination for artworks.
  """
  def handle_call({:artworks_reset}, _from, %{"next_artworks" => next_artworks} = state)
  when next_artworks != nil do
    {:reply, :ok, Map.drop(state, ["next_artworks"])}
  end


  @doc """
  Load artists.
  We save cursor in state for effective pagination, of next request.
  Use artists_reset to reset a pagination cursor.
  """
  def handle_call({:artists}, _from, %{"token" => token} = state) when token != nil do
    url = Map.get(state, "next_artists", "/artists")
    raw_response = Artsy.get(url, headers(:token, token))
    {result, new_state} = get_request state, raw_response, fn(state, response) ->
      new_state = case response do
        %{"_links" => %{"next" => %{"href" => next_url}}} ->
          Map.put(state, "next_artists", String.replace(next_url, config(:url), ""))
        _ ->
          state
      end
      {{:ok, response}, new_state}
    end
    {:reply, result, new_state}
  end

  @doc """
  Load artists for specific artwork.
  """
  def handle_call({:artists_artwork, artwork_id}, _from, %{"token" => token} = state) when token != nil do
    url = "/artists?artwork_id=#{artwork_id}"
    raw_response = Artsy.get(url, headers(:token, token))
    {result, _state} = get_request state, raw_response, fn(state, response) ->
      {{:ok, response}, state}
    end
    {:reply, result, state}
  end

  @doc """
  Reset pagination for artists.
  """
  def handle_call({:artists_reset}, _from, %{"next_artists" => next_artists} = state)
  when next_artists != nil do
    {:reply, :ok, Map.drop(state, ["next_artists"])}
  end


  @doc """
  Generate new token and put it's metadata to state.
  We cancel all the pending reload timers, before setting a new timer.
  """
  def handle_cast({:get_new_token}, %{"token_timer" => token_timer} = state)
  when token_timer != nil do
    Process.cancel_timer(token_timer)
    handle_cast({:get_new_token}, state)
  end
  def handle_cast({:get_new_token}, %{"token_retries" => token_retries} = state)
  when token_retries >= @token_max_retries do
    Logger.error fn() -> "Artsy JWT was not loaded, total attempts: #{token_retries}" end
    {:noreply, state}
  end
  def handle_cast({:get_new_token}, %{"token_retries" => token_retries} = state) do
    with {:ok, token, expire} <- get_token() do
      timer = Process.send_after(self(), {:get_new_token}, get_token_delay(expire))
      new_state = %{
        state | "token" => token,
          "token_expire_ts" => expire,
          "token_timer" => timer,
          "token_retries" => 0
      }
      {:noreply, new_state}
    else
      _ ->
        Logger.warn fn() -> "Artsy JWT was not loaded" end
        timer = Process.send_after(self(), {:get_new_token}, @token_failure_delay)
        {:noreply, %{state | "token_timer" => timer, "token_retries" => token_retries + 1}}
    end
  end

  
  @doc """
  Helper function to read global config in scope of this module.
  """
  def config, do: Application.get_env(:artsy, Artsy)
  def config(key, default \\ nil) do
    config() |> Keyword.get(key, default) |> resolve_config(default)
  end


  @doc """
  Append REST API main url.
  """
  @spec process_url(String.t) :: String.t
  def process_url(url) do
    config(:url) <> url
  end


  @doc """
  Generate new JWT to access Artsy API.
  """
  @spec get_token() :: {:ok, String.t, Integer} | {:error, Exception.t}
  def get_token do
    url = "/tokens/xapp_token?client_id=#{config(:client_id)}&client_secret=#{config(:client_secret)}"
    with {:ok, %{body: json_body, status_code: 201}} <- Artsy.post(url, ""),
      {:ok, %{"token" => token, "expires_at" => expires_at}} <- Poison.decode(json_body),
      {:ok, datetime, _offset} <- DateTime.from_iso8601(expires_at)
    do
      {:ok, token, DateTime.to_unix(datetime)}
    else
      er ->
        IO.inspect er
        {:error, Artsy.TokenError}
    end
  end

  @spec get_token_delay(integer) :: integer
  defp get_token_delay(expire) do
    reload_delay = (expire - :os.system_time(:seconds) - @token_reload) * 1000
    get_token_delay(:valid?, reload_delay)
  end
  defp get_token_delay(:valid?, delay) when delay < @token_min_delay, do: @token_min_delay
  defp get_token_delay(:valid?, delay), do: delay

  
  # Add security header
  defp process_request_headers(headers) when is_map(headers) do
    Enum.into(headers, headers())
  end
  defp process_request_headers(headers), do: headers ++ headers()
  
  # Default headers added to all requests
  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]
  end
  defp headers(:token, token), do: [{"X-XAPP-Token", token}]


  defp resolve_config({:system, var_name}, default),
    do: System.get_env(var_name) || default
  defp resolve_config(value, _default),
    do: value
end
