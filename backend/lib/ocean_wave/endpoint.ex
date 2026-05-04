defmodule OceanWave.Endpoint do
  use Plug.Router

  # Serve static assets from the application's priv/static directory.
  # This ensures assets are available when packaged in an Elixir release.
  plug(Plug.Static,
    at: "/",
    from: {:ocean_wave, "priv/static"},
    only: ~w(index.html elm.js manifest.json sw.js icon-192.png icon-512.png)
  )

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  # Explicitly serve index.html for the root path
  get "/" do
    index_path = Application.app_dir(:ocean_wave, "priv/static/index.html")

    conn
    |> put_resp_header("content-type", "text/html")
    |> send_file(200, index_path)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
