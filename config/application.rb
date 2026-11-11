# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module Brueschhuesli
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    # Framework strings like validation messages are not translated in
    # config/locales, so they fall back to English.
    config.i18n.default_locale = :de
    config.i18n.fallbacks = [ :en ]
  end
end
