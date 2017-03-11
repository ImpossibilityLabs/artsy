defmodule Artsy.ConfigError do
  @moduledoc """
  Raised in case there is issues with the config.
  """
  defexception [:message]
end

defmodule Artsy.TokenError do
  @moduledoc """
  Raised then we are unable to get JWT to access Artsy API.
  """
  defexception [:message]
end

defmodule Artsy.ApiError do
  @moduledoc """
  Raised in case invalid response is returned from Artsy API.
  """
  defexception [:message]
end

defmodule Artsy.InvalidRequestData do
  @moduledoc """
  Raised in case request data is invalid.
  """
  defexception [:message]
end

defmodule Artsy.UnsupportedAcceptType do
  @moduledoc """
  Raised in case request media type specified in Accept
  header is not application/json.
  """
  defexception [:message]
end

defmodule Artsy.UnsupportedMediaType do
  @moduledoc """
  Raised in case request content type specified in Content-Type
  header is not application/json.
  """
  defexception [:message]
end

defmodule Artsy.NoApplication do
  @moduledoc """
  Raised in case application doesn't exist.
  """
  defexception [:message]
end

defmodule Artsy.MethodNotAllowed do
  @moduledoc """
  Raised in case request method is not allowed.
  """
  defexception [:message]
end

defmodule Artsy.NoSecurityHeader do
  @moduledoc """
  Raised in case the clientSecret header value did not match.
  """
  defexception [:message]
end

defmodule Artsy.GenericError do
  @moduledoc """
  Raised for non-specific backend errors related to this library.
  """
  defexception [:message]
end
