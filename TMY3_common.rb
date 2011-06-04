#this file is for holding methods common to monthly.rb, daily.rb, and hourly.rb
def sum(values)
  total = 0
  values.each {|val| total += val.to_f}
  total
end

def days_in_month(month)
  #TMY3 doesn't include January 29, so we don't need to account for leap years
  days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31] 
  days_in_month[month-1]
end

def invalid?
  elevation = ( @elevation >= 1000 )
  disallowed_states = ["AK", "HI", "GU", "PR", "VI"]
  state = disallowed_states.include?(@state)
  if state or elevation 
    return true
  else
    return false
  end
end

def collect_station_characteristics
  header1 = @current_tmy3_file.shift
  header2 = @current_tmy3_file.shift #get rid of the column headers
  
  #read basic info about the weather station  
  @state = header1[2]
  @time_zone = header1[3]
  @subregion = nil
  @latitude =  header1[4].to_f.abs
  @longitude = header1[5].to_f.abs
  @elevation = header1[6].to_i

  case @state
    when "OR" then @subregion = (@longitude > 120 ? "west"  : "east")
    when "WA" then @subregion = (@longitude > 120 ? "west"  : "east")
    when "ND" then @subregion = (@longitude > 100 ? "west"  : "east")
    when "SD" then @subregion = (@longitude > 100 ? "west"  : "east")
    when "NE" then @subregion = (@longitude > 100 ? "west"  : "east")
    when "KS" then @subregion = (@longitude > 98 ? "west"  : "east")
    when "OK" then @subregion = (@longitude > 98 ? "west"  : "east")
    when "FL" then @subregion = (@latitude > 27 ? "north"  : "south")
    when "TX" then @subregion = (@longitude > 98 ? "west"  : "east")
    else @subregion = "none"
  end
end
