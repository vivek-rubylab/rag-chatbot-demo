require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module TutorChat
  class Application < Rails::Application
    config.load_defaults 8.0

    # Auto-load app/services
    config.autoload_paths << Rails.root.join("app/services")

    # Propshaft: also sweep app/javascript so importmap can serve local JS files
    config.assets.paths << Rails.root.join("app/javascript")

    config.time_zone = "UTC"
    config.i18n.default_locale = :en
  end
end
