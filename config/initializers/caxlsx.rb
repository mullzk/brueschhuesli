# frozen_string_literal: true

# Register the xlsx MIME type/renderer and the axlsx template handler eagerly at
# boot. caxlsx_rails wires these up through lazy on_load hooks; depending on the
# test load order, an early template lookup can otherwise cache a negative
# result in ActionView's resolver and make later `.xlsx` renders raise
# MissingTemplate.
require "axlsx_rails/action_controller"
require "axlsx_rails/template_handler"

handler = AxlsxRails::TemplateHandler.new
if defined?(ActionView::Template)
  ActionView::Template.register_template_handler :axlsx, handler
else
  ActiveSupport.on_load(:action_view) do
    ActionView::Template.register_template_handler :axlsx, handler
  end
end
