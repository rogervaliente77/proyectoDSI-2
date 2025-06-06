require_relative "boot"

require "rails"

require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "active_storage/engine"
require "rails/test_unit/railtie"

require "mongoid"               # ✅ primero
require "mongoid/railtie"       # ✅ después

Bundler.require(*Rails.groups)

module AuthWithRails
  class Application < Rails::Application
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w(assets tasks))

    config.time_zone = "America/El_Salvador"
  end
end
