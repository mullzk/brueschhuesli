class Date
  EN_TO_GERMAN_MONTHS = {
    'January'  => 'Januar', 'February' => 'Februar', 'March'    => 'Maerz', 'April'    => 'April',
    'May'      => 'Mai', 'June'     => 'Juni', 'July'     => 'Juli', 'August'   => 'August',
    'September'=> 'September', 'October'  =>'Oktober', 'November' =>'November', 'December' =>'Dezember'
  }
  EN_TO_GERMAN_DAYS = {
    'Sunday'   => 'Sonntag', 'Monday'   => 'Montag', 'Tuesday'  => 'Dienstag', 'Wednesday'=> 'Mittwoch',
    'Thursday' => 'Donnerstag', 'Friday'   => 'Freitag', 'Saturday' => 'Samstag'
  }

  EN_TO_GERMAN_ABBR_MONTHS = {
    'Jan'      => 'Jan', 'Feb'      => 'Feb', 'Mar'      => 'Mae', 'Apr'      => 'Apr',
    'May'      => 'Mai', 'Jun'      => 'Jun', 'Jul'      => 'Jul', 'Aug'      => 'Aug',
    'Sep'      => 'Sep', 'Oct'      => 'Okt', 'Nov'      => 'Nov', 'Dec'      => 'Dez'
  }

  EN_TO_GERMAN_ABBR_DAYS = {
    'Sun'      => 'So', 'Mon'      => 'Mo', 'Tue'      => 'Di', 'Wed'      => 'Mi',
    'Thu'      => 'Do', 'Fri'      => 'Fr', 'Sat'      => 'Sa'
  }

  def self.parse_german_string(str)
    date_string = str

    # We do not merge these hashes, as the order of gsubs could be important, e.g. you want dezember be substituted before dez
    EN_TO_GERMAN_MONTHS.each do |en, de|
      date_string.gsub!(/\b#{de}\b/i, en)
    end
    EN_TO_GERMAN_DAYS.each do |en, de|
      date_string.gsub!(/\b#{de}\b/i, en)
    end
    EN_TO_GERMAN_ABBR_MONTHS.each do |en, de|
      date_string.gsub!(/\b#{de}\b/i, en)
    end
    EN_TO_GERMAN_ABBR_DAYS.each do |en, de|
      date_string.gsub!(/\b#{de}\b/i, en)
    end

    begin
      date = self.parse(date_string)
    rescue ArgumentError
      # "22.12.77" crashes, "22.12.1977" not
      date_components = date_string.split(/-|\.|\//).map{|x|x.strip}  
      if date_components.size == 3 && (1..99).include?(date_components[2].to_i)
        if date_components[2].to_i < 50
          date_components[2] = ((date_components[2].to_i) + 2000).to_s
        else
          date_components[2] = ((date_components[2].to_i) + 1900).to_s
        end
        date_string = date_components.join("-")
        retry
      end
    end

    # Date.parse("22.12.77") crashed and got corrected, but Date.parse("22.Oct.77") gets parsed as 22.10.0077. This fixes it. Of course, we now cannot express Dates in the first century.
    if (0..99).include? date.year
      if date.year < 50
        date = self.civil(date.year+2000, date.month, date.day)
      else 
        date = self.civil(date.year+1900, date.month, date.day)
      end
    end
    date
  end
  
  def strftime_german(format)
    str = strftime(format)
    EN_TO_GERMAN_MONTHS.each do |en, de|
      str.gsub!(/\b#{en}\b/i, de)
    end
    EN_TO_GERMAN_DAYS.each do |en, de|
      str.gsub!(/\b#{en}\b/i, de)
    end
    EN_TO_GERMAN_ABBR_MONTHS.each do |en, de|
      str.gsub!(/\b#{en}\b/i, de)
    end
    EN_TO_GERMAN_ABBR_DAYS.each do |en, de|
      str.gsub!(/\b#{en}\b/i, de)
    end
    str
  end
  
  def long_german_std
    self.strftime_german("%A, %d. %B %Y")
  end
  
  def short_german_std
    self.strftime_german("%d.%m.%Y")
  end
  
  def medium_german_std
    self.strftime_german("%d. %b %Y")
  end
    
end


