# frozen_string_literal: true

module ApplicationHelper
  def time_components_of(numeric)
    (reminder, secs) = numeric.divmod(60)
    (reminder, mins) = reminder.divmod(60)
    (days, hours) = reminder.divmod(24)

    { seconds: secs, minutes: mins, hours:, days: }
  end

  def time_component_string_of(numeric)
    comps = time_components_of(numeric)
    days = comps[:days]
    hours = comps[:hours]

    if days.positive?
      format('%id %.2ih', days, hours)
    else
      format('%.ih', hours)
    end
  end

  # Excel Cell Helpers
  def adding_excel_methods_to_builder(xml)
    def xml.e_cell(value = nil, style = nil, type = 'String')
      if style
        self.Cell 'ss:StyleID' => style do
          self.Data value, 'ss:Type' => type
        end
      else
        self.Cell do
          self.Data value, 'ss:Type' => type
        end
      end
    end

    def xml.e_formula(formula)
      self.Cell 'ss:Formula' => formula
    end

    def xml.e_sum_above(rows)
      e_formula("=SUM(R[-#{rows}]C:R[-1]C)")
    end

    def xml.e_sum_left(columns)
      e_formula("=SUM(RC[-#{columns}]:RC[-1])")
    end

    def xml.e_cell_number(number, style = nil)
      e_cell(number, style, 'Number')
    end

    def xml.e_cell_float(number)
      e_cell(float_as_three_precision_decimal_hours(number), 'ap_one_precision', 'Number')
    end

    def xml.e_cell_time(time, style = 'ap_short_time')
      e_cell(time.strftime('%Y-%m-%dT%H:%M:%S'), style, 'DateTime')
    end

    def xml.e_cell_date(time, style = 'ap_short_date')
      e_cell(time.strftime('%Y-%m-%dT%H:%M:%S'), style, 'DateTime')
    end

    def xml.e_cell_datetime(time, style = 'ap_full_datetime')
      e_cell(time.strftime('%Y-%m-%dT%H:%M:%S'), style, 'DateTime')
    end

    def xml.e_cell_empty
      self.Cell {}
    end

    def xml.float_as_three_precision_decimal_hours(floatTimeIntervall)
      return unless floatTimeIntervall

      format('%.3f', (floatTimeIntervall / 60.0 / 60.0))
    end
  end
end
