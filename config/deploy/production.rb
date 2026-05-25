# frozen_string_literal: true

set :application_instance, "brueschhuesliprod"
set :branch,               "production"
set :deploy_to,            "/var/www/brueschhuesliprod"

server ENV.fetch("DEPLOY_PRODUCTION_HOST"),
       user: ENV.fetch("DEPLOY_PRODUCTION_USER"),
       roles: %w[app db web]
