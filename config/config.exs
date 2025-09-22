# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :web_phoenix, WebPhoenixWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: WebPhoenixWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: WebPhoenix.PubSub,
  live_view: [signing_salt: "IypWn4uJ"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Documentation menu configuration
config :web_phoenix, :menu_config,
  # Fixed menu items (always shown in this order)
  fixed_items: [
    %{
      type: :section,
      title: "Architecture",
      icon: "fas fa-sitemap",
      items: [
        %{title: "How It Works", path: "/content/how-it-works", icon: "fas fa-info-circle"},
        %{title: "Tenant System", path: "/content/tenant-system", icon: "fas fa-building"}
      ]
    }
  ],
  # LLM provider configuration (dynamic content will be added under these)
  llm_providers: [
    %{
      name: "claude",
      title: "Claude",
      icon: "fas fa-brain",
      description: "Anthropic's Claude AI",
      frameworks: ["blissframework"]
    },
    %{
      name: "gemini",
      title: "Gemini",
      icon: "fas fa-gem",
      description: "Google's Gemini AI",
      frameworks: ["blissframework"]
    }
  ],
  # Framework configuration
  frameworks: %{
    "blissframework" => %{title: "Bliss Framework", icon: "fas fa-magic", priority: 1}
  }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
