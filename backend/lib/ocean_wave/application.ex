defmodule OceanWave.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: OceanWave.Endpoint, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: OceanWave.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
