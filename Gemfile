# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".tool-versions"

gem "rails", "~> 8.1"
gem "trilogy"
gem "puma", ">= 6.0"
gem "bootsnap", ">= 1.1.0", require: false

gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

gem "bcrypt", "~> 3.1.7"
gem "will_paginate"
gem "caxlsx"
gem "caxlsx_rails"

group :development, :test do
  gem "debug", require: "debug/prelude"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "brakeman", "~> 8.0", require: false
  gem "bundler-audit", require: false
end

group :development do
  gem "web-console", ">= 3.3.0"
  gem "annotaterb"
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-minitest", require: false
  gem "erb_lint", require: false

  gem "capistrano", "~> 3.18"
  gem "capistrano-rails"
  gem "capistrano-bundler"
  # net-ssh needs these to authenticate with ED25519 SSH keys.
  gem "ed25519", "~> 1.2"
  gem "bcrypt_pbkdf", "~> 1.0"
end

group :test do
  gem "minitest", "~> 6.0"
  gem "capybara", ">= 2.15"
  gem "selenium-webdriver"
  gem "mocha"
  gem "simplecov", require: false
end
