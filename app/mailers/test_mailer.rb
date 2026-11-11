# frozen_string_literal: true

class TestMailer < ApplicationMailer
  def test_email(recipient)
    mail(to: recipient, subject: "Test-Mail vom Brüschhüsli-Reservationssystem")
  end
end
