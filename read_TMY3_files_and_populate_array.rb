# This file is for computing monthly time steps.
require 'date'

def sum(values)
  total = 0
  values.each {|val| total += val.to_f}
  total
end

def reset_daily_weather_variables
  @dew = 0
  @max_temp = -999
  @min_temp = 999
  @wind = 0
  @sunshine = 0
  @precipitation = 0
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

def days_in_month(year, month)
  days = (Date.new(year, 12, 31) << (12-month)).day
  if days == 29
    return 28 #this is because TMY data does not include February 29
  else 
    return days
  end
end

def last_hour_of_day?
  @current_row_datetime.hour == 23
end

def last_day_of_month?
  days_left_in_month = days_in_month(@current_row_datetime.year, @current_row_datetime.month) - @current_row_datetime.day
  days_left_in_month == 0
end

def set_daily_values
  @daily_highs[@current_row_datetime.day] = @max_temp
  @overnight_lows[@current_row_datetime.day] = @min_temp
  @days_dew[@current_row_datetime.day] = @dew / 24
  @days_wind[@current_row_datetime.day] = @wind / 24
  @days_sunshine[@current_row_datetime.day] = @sunshine #total accumulated hours of sunshine
  @daily_precips[@current_row_datetime.day] = @precipitation #total accumulated mm of precip
  reset_daily_weather_variables
end

def set_monthly_averages
  overnight_lows_sum = sum(@overnight_lows.values)
  daily_highs_sum = sum(@daily_highs.values) 
  dew_sum = sum(@days_dew.values)
  wind_sum = sum(@days_wind.values)
  sunshine_sum = sum(@days_sunshine.values)
  total_monthly_precipitation = sum(@daily_precips.values)

  days_in_month = days_in_month(@current_row_datetime.year, @current_row_datetime.month)
  @weather_averages_by_month[@current_row_datetime.month] = {       #@weather_averages_by_month[1] ...
    :avg_monthly_high => daily_highs_sum.to_f / days_in_month,      #this is that month's average overnight low
    :avg_monthly_low => overnight_lows_sum.to_f / days_in_month,    #this is that month's average daily high
    :dew => dew_sum.to_f / days_in_month,
    :wind => wind_sum.to_f / days_in_month,
    :sunshine => sunshine_sum.to_f / days_in_month,
    :monthly_precipitation_accumulation => total_monthly_precipitation.to_f #this is that month's total accumulated rainful.
  }

  #now reset everything for the next month:
  @daily_highs ={}
  @overnight_lows ={}
  @days_dew = {}
  @days_wind = {}
  @days_sunshine = {}
  @daily_precips
  reset_daily_weather_variables
end

def collect_station_characteristics
  header1 = @current_tmy3_file.shift
  header2 = @current_tmy3_file.shift #get rid of the column headers
  
  #read basic info about the weather station  
  @state = header1[2]
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

def initialize_arrays_and_variables
  @weather_averages_by_month = {}
  @overnight_lows = {}
  @daily_highs = {}
  @days_dew = {}
  @days_wind = {}
  @days_sunshine = {}
  @daily_precips = {}
  reset_daily_weather_variables
end

def collect_station_weather_data
  @current_tmy3_file.each do |row| #Loop through each row. Each row is one hour; 24 rows per day.
      
    @max_temp = row[31].to_f if row[31].to_f > @max_temp #which was initialized to -999 in "reset_values" method
    @min_temp = row[31].to_f if row[31].to_f < @min_temp #which was initizlized to 999
    @dew += row[34].to_f
    @wind += row[46].to_f
    @precipitation += row[64].to_f unless row[64].to_i == -9900
    @sunshine = @sunshine + 1 if row[7].to_i > 120
    # we want (hours of sunshine)/day, which is defined as 
    # direct normal irradiance normal to sun > 120 W/m^2. http://www.satel-light.com/guide/glosstoz.htm

    @current_row_datetime = DateTime.strptime(row[0]+" "+row[1], '%m/%d/%Y %H:%M') - 1/(24.0*60) #format date to remove Ruby 1.8/1.9 inconsistencies
    # subtract 1 hr because DateTime puts "24:00" in the next day as "00:00"
    set_daily_values if last_hour_of_day?
    set_monthly_averages if (last_hour_of_day? and last_day_of_month?)
  end
end

def set_state_values
  @states[@state] ||= {}
    @states[@state][@subregion] ||= { 
                                      :avg_monthly_highs => {}, 
                                      :avg_monthly_lows => {}, 
                                      :dews => {},
                                      :winds => {},
                                      :elevations => [],
                                      :latitudes => [],
                                      :longitudes => [],
                                      :sunshines => {},
                                      :monthly_accumulated_precipitations => {} }
    (1..12).to_a.each do |month|
      #Set up the arrays if they don't exist...
      @states[@state][@subregion][:avg_monthly_highs][month] ||= []
      @states[@state][@subregion][:avg_monthly_lows][month] ||= []
      @states[@state][@subregion][:dews][month] ||= []
      @states[@state][@subregion][:winds][month] ||= []
      @states[@state][@subregion][:sunshines][month] ||= []
      @states[@state][@subregion][:monthly_accumulated_precipitations][month] ||= [] #algorith wants total accumulated rainfall in a given month

      #...and add the weather averages into each array. Each new file from the tmy3 folder appends one element to its state's array.
      @states[@state][@subregion][:avg_monthly_highs][month] << @weather_averages_by_month[month][:avg_monthly_high]
      @states[@state][@subregion][:avg_monthly_lows][month] << @weather_averages_by_month[month][:avg_monthly_low]
      @states[@state][@subregion][:dews][month] << @weather_averages_by_month[month][:dew]
      @states[@state][@subregion][:winds][month] << @weather_averages_by_month[month][:wind]
      @states[@state][@subregion][:sunshines][month] << @weather_averages_by_month[month][:sunshine]
      @states[@state][@subregion][:monthly_accumulated_precipitations][month] << @weather_averages_by_month[month][:monthly_precipitation_accumulation]
    end
  @states[@state][@subregion][:latitudes] << @latitude
  @states[@state][@subregion][:longitudes] << @longitude
  @states[@state][@subregion][:elevations] << @elevation.to_i
end

def flatten_array_into_national_averages
  @national_data = Hash.new
  state_keys = @states.keys.sort
  state_keys.each do |state|
    subregion_keys = @states[state].keys.sort
    subregion_keys.each do |subregion|
      number_of_stations = @states[state][subregion][:avg_monthly_highs][1].size #arbitrarily use size of January high_temp array to find # of stations 

      @national_data[state] ||= {}
      @national_data[state][subregion] ||= {}
      @national_data[state][subregion][:number_of_stations] = number_of_stations 
      @national_data[state][subregion][:latitude] = sum(@states[state][subregion][:latitudes]) / number_of_stations
      @national_data[state][subregion][:longitude] = sum(@states[state][subregion][:longitudes]) / number_of_stations
      @national_data[state][subregion][:elevation] = sum(@states[state][subregion][:elevations]) / number_of_stations

      (1..12).to_a.each do |month|
        @national_data[state][subregion][:t_max] ||= {}
        @national_data[state][subregion][:t_min] ||= {}
        @national_data[state][subregion][:t_dew] ||= {}
        @national_data[state][subregion][:wind_speed] ||= {}
        @national_data[state][subregion][:hours_of_sunshine] ||= {}
        @national_data[state][subregion][:accumulated_precipitation] ||= {}
        @national_data[state][subregion][:t_max][month] = sum(@states[state][subregion][:avg_monthly_highs][month]).to_f/ number_of_stations
        @national_data[state][subregion][:t_min][month] = sum(@states[state][subregion][:avg_monthly_lows][month]).to_f/ number_of_stations
        @national_data[state][subregion][:t_dew][month] = sum(@states[state][subregion][:dews][month]).to_f/ number_of_stations
        @national_data[state][subregion][:wind_speed][month] = sum(@states[state][subregion][:winds][month]).to_f/ number_of_stations
        @national_data[state][subregion][:hours_of_sunshine][month] = sum(@states[state][subregion][:sunshines][month]).to_f/ number_of_stations
        @national_data[state][subregion][:accumulated_precipitation][month] = sum(@states[state][subregion][:monthly_accumulated_precipitations][month]).to_f/ number_of_stations
      end
    end
  end
end

def previous_month(current_month)
  if current_month == 1
    previous_month = 12
  else
    previous_month = current_month - 1
  end
end

def add_previous_temp_to_states_array
  #get the array
  #drill down to t_max_previous = @states["CA"]["none"][:avg_monthly_highs][1]
  #drill down to @states["CA"]["none"][:previous_avg_monthly_highs][2] = t_max_previous
  #that will work for month's 2 through 11; for month 12, need to record the date as t_max_previous, then go back to month 1 and place it in
  #@states["CA"]["none"][:previous_avg_monthly_highs[1]. I guess do that with an if statement. 

  state_keys = @national_data.keys.sort
  state_keys.each do |state|
    subregion_keys = @national_data[state].keys.sort
    subregion_keys.each do |subregion|
      @national_data[state][subregion][:t_max_previous] ||= {}
      @national_data[state][subregion][:t_min_previous] ||= {}
      (1..12).each do |month|
        @national_data[state][subregion][:t_max_previous][month] = @national_data[state][subregion][:t_max][previous_month(month)]
        @national_data[state][subregion][:t_min_previous][month] = @national_data[state][subregion][:t_min][previous_month(month)]
      end
    end
  end
end
