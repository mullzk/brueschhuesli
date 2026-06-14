# frozen_string_literal: true

# Registered by name so the class is resolved lazily (reloading-safe). The guard
# ensures the redirect never happens outside development.
ActionMailer::Base.register_interceptor("DevelopmentMailInterceptor") if Rails.env.development?
