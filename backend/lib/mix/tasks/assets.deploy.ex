defmodule Mix.Tasks.Assets.Deploy do
  use Mix.Task

  @shortdoc "Build and copy frontend assets"

  def run(_) do
    Mix.shell().cmd("cd ../frontend && elm make src/Main.elm --optimize --output=elm.js")

    File.cp_r!("../frontend/elm.js", "priv/static/elm.js")
    File.cp_r!("../frontend/index.html", "priv/static/index.html")
    File.cp_r!("../frontend/manifest.json", "priv/static/manifest.json")
    File.cp_r!("../frontend/sw.js", "priv/static/sw.js")

    Mix.shell().info("Assets deployed")
  end
end
