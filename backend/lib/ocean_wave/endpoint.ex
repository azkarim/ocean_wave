defmodule OceanWave.Endpoint do
  use Plug.Router

  plug(Plug.Static,
    at: "/",
    # Path relative to where the server is started
    from: "../frontend",
    only: ~w(index.html elm.js manifest.json sw.js icon-192.png icon-512.png)
  )

  plug(:match)
  plug(:dispatch)

  # Default route to serve index.html
  get "/" do
    conn
    |> put_resp_header("content-type", "text/html")
    |> send_file(200, "../frontend/index.html")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
