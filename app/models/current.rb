# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :request_host
  delegate :user, to: :session, allow_nil: true
end
