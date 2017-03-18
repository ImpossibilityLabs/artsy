defmodule Artsy.ApiHelpers do
  @moduledoc """
  Macroses and functions to reduce boilerplate
  for API requests.
  """

  @doc """
  Simple wrapper to reduce boilerplate for processing GET requests.
  """
  @spec get_request(map(), map(), fun()) :: {{:ok, map()}, map()} | {{:error, Exception.t}, map()}
  def get_request(state, raw_response, func) do
    with {:ok, %{body: json_body, status_code: 200}} <- raw_response,
      {:ok, response} <- Poison.decode(json_body)
    do
      func.(state, response)
    else
      {:ok, %{status_code: 400}} ->
        {{:error, Artsy.InvalidRequestData}, state}
      {:ok, %{status_code: 401}} ->
        {{:error, Artsy.NoSecurityHeader}, state}
      {:ok, %{status_code: 406}} ->
        {{:error, Artsy.UnsupportedAcceptType}, state}
      {:ok, %{status_code: 409}} ->
        {{:error, Artsy.NoApplication}, state}
      {:ok, %{status_code: 500}} ->
        {{:error, Artsy.ApiError}, state}
      {:error, _} ->
        {{:error, Artsy.ApiError}, state}
      _ ->
        {{:error, Artsy.GenericError}, state}
    end
  end
end
