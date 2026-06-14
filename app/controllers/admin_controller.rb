# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :require_owner

  def index
  end

  def test_email
    begin
      TestMailer.test_email(params[:email]).deliver_now
      flash[:notice] = "Test-Mail an #{params[:email]} versendet."
    rescue StandardError => e
      flash[:notice] = "Versand fehlgeschlagen: #{e.message}"
    end
    redirect_to admin_path
  end
end
