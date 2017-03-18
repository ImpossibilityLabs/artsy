# Artsy

Stateful REST API wrapper for [Artsy](https://developers.artsy.net/docs/artworks). It automatically generates JWT token to access API and keeps it updated.

## Installation

The package can be installed by adding `artsy` to your list of dependencies and applications in `mix.exs`:

```elixir
def deps do
  [{:artsy, "~> 0.1"}]
end

def application do
  [extra_applications: [:artsy]]
end
```

### Config

Put API credentials for your Artsy application.

```
config :artsy, Artsy,
  url: "https://api.artsy.net/api",
  client_id: "******",
  client_secret: "*********"
```

## Usage

### Artworks
Calls of `Artsy.artworks()` will paginate through a listed artworks, use `Artsy.artworks(:reset)` to reset pagination cursor back to the first page.

### Artists
Calls of `Artsy.artists()` will paginate through a listed artists, use `Artsy.artists(:reset)` to reset pagination cursor back to the first page.

In case you need to get artist for a specific artwork use: `Artsy.artists(:artwork, artwork_id)`.

## Diclaimer

**This library is in it's early beta and lack most of features.**
