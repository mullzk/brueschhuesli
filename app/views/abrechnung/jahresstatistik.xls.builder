adding_excel_methods_to_builder(xml)
xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
xml.Workbook({
	'xmlns'			=> "urn:schemas-microsoft-com:office:spreadsheet", 
	'xmlns:o'		=> "urn:schemas-microsoft-com:office:office",
	'xmlns:x'		=> "urn:schemas-microsoft-com:office:excel",		
	'xmlns:html' => "http://www.w3.org/TR/REC-html40",
	'xmlns:ss'	=> "urn:schemas-microsoft-com:office:spreadsheet" 
	}) do

	xml.Styles do
		xml.Style 'ss:ID' => 'Default', 'ss:Name' => 'Normal' do
			xml.Alignment 'ss:Vertical' => 'Bottom'
			xml.Borders
			xml.Font 'ss:FontName' => 'Verdana', "ss.Size" => "11"
			xml.Interior
			xml.NumberFormat
			xml.Protection
		end
		xml.Style 'ss:ID' => 'ap_one_precision' do
		  xml.NumberFormat "ss:Format"=>"0.000"
		end
		xml.Style 'ss:ID' => 'ap_int_precision' do
		  xml.NumberFormat "ss:Format"=>"0"
		end
      
		xml.Style 'ss:ID' => 'ap_bold' do
			xml.Font "ss:Bold" => "1"
		end
		xml.Style 'ss:ID' => 'ap_bold_bigger' do
			xml.Font "ss:Bold" => "1", "ss:Size" => "13"
		end
		xml.Style 'ss:ID' => 'ap_smaller' do
			xml.Font "ss:Size" => "9"
		end
		xml.Style 'ss:ID' => 'ap_warning' do
			xml.Interior "ss:Color" => "#FCFFA6", "ss:Pattern"=>'Solid'
		end
		xml.Style 'ss:ID' => 'ap_short_date' do
			xml.NumberFormat 'ss:Format' => 'd.m.yyyy'
		end
		xml.Style 'ss:ID' => 'ap_short_time' do
			xml.NumberFormat 'ss:Format' => 'HH:MM'
		end
		xml.Style 'ss:ID' => 'ap_full_datetime' do
			xml.NumberFormat 'ss:Format' => 'd.m.yyyy HH:MM'
		end
	end
	xml.Worksheet 'ss:Name' => @listed_year.year do
		xml.Table do
			# Title Section
			xml.Row do 
				xml.e_cell("Brüschhüsli-Abrechnung für #{@listed_year.year}"  , "ap_bold_bigger")
			end
			xml.Row { xml.Cell {}}


			# Header
			xml.Row "ss:StyleID" => "ap_bold" do
				xml.e_cell("Wer")
				xml.e_cell("Anzahl Reservationen")
				xml.e_cell("Total Kosten")
			end



      for stat in @stats
				xml.Row do
					xml.e_cell(h(stat[0].name))
          xml.e_cell_number(stat[1], "ap_int_precision")
          xml.e_cell_number(stat[2], "ap_int_precision")
				end
			end
			xml.Row "ss:StyleID" => "ap_bold" do
			  xml.e_cell("Total")
			  xml.e_sum_above(@stats.size)
			  xml.e_sum_above(@stats.size)
		  end
			xml.Row "ss:StyleID" => "ap_bold" do
		  end
			xml.Row "ss:StyleID" => "ap_smaller" do
			  xml.e_cell("Stand #{Date.today.strftime("%d.%m.%Y")}")
		  end
		end
	end
end