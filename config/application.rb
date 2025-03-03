require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sgt
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Set sidekiq as worker for active_job
    config.active_job.queue_adapter = :sidekiq
    Sidekiq.configure_server do |config|
      Time.zone = "Eastern Time (US & Canada)"
      config.redis = { url: ENV["REDIS_URL"] }
    end
    
    config.time_zone = "Eastern Time (US & Canada)"
    config.active_record.default_timezone = :utc
    # config.eager_load_paths << Rails.root.join("extras")
    
    Sidekiq.configure_client do |config|
      config.redis = { url: ENV["REDIS_URL"] }
    end
    

    config.generators do |g|
      g.factory_bot dir: 'spec/factories'
    end
  end
end