# This file is for computing monthly time steps.
require 'date'
require './TMY3_common.rb'

def reset_daily_weather_variables
  @accumulated_dew_temp = 0
  @max_temp = -999
  @min_temp = 999
  @accumulated_wind_speed = 0
  @hours_of_sunshine = 0
  @accumulated_precipitation = 0
end

def last_hour_of_day?
  @current_row_datetime.hour == 23
end

def last_day_of_month?
  days_left_in_month = days_in_month(@current_row_datetime.month) - @current_row_datetime.day
  days_left_in_month == 0
end

def set_daily_values
  @daily_highs[@current_row_datetime.day] = @max_temp
  @overnight_lows[@current_row_datetime.day] = @min_temp
  @days_dew[@current_row_datetime.day] = @accumlated_dew_temp / 24
  @days_wind[@current_row_datetime.day] = @accumulated_wind_speed / 24
  @days_sunshine[@current_row_datetime.day] = @hours_of_sunshine #total accumulated hours of sunshine
  @daily_precips[@current_row_datetime.day] = @accumulated_precipitation #total accumulated mm of precip
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
    :avg_monthly_high                   => daily_highs_sum.to_f / days_in_month,      #this is that month's average overnight low
    :avg_monthly_low                    => overnight_lows_sum.to_f / days_in_month,    #this is that month's average daily high
    :dew                                => dew_sum.to_f / days_in_month,
    :wind                               => wind_sum.to_f / days_in_month,
    :sunshine                           => sunshine_sum.to_f / days_in_month,
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

def calculate_daily_monthly_weather_data
    @max_temp       = @hourly_temp if @hourly_temp > @max_temp #which was initialized to -999 in "reset_values" method
    @min_temp       = @hourly_temp if @hourly_temp < @min_temp #which was initizlized to 999
    @accumulated_dew_temp       = @accumulated_dew_temp + @hourly_dewpoint_temp
    @accumulated_wind_speed    += @hourly_wind_speed 
    @accumulated_precipitation += @hourly_precipiation unless @hourly_precipiation.to_i == -9900 #it may under-report precip, but ET0 calc doesn't use precip.
    @hours_of_sunshine = @hours_of_sunshine + 1 if @hourly_irradiance.to_i > 120
    # we want (hours of sunshine)/day, which is defined as 
    # direct normal irradiance normal to sun > 120 W/m^2. http://www.satel-light.com/guide/glosstoz.htm

    set_daily_values if last_hour_of_day?
    set_monthly_averages if (last_hour_of_day? and last_day_of_month?)
end


def set_state_values
  @states[@state] ||= {}
    @states[@state][@subregion] ||= { 
                                      :elevations => [],
                                      :latitudes => [],
                                      :longitudes => [],
                                      :avg_monthly_highs => {}, 
                                      :avg_monthly_lows => {}, 
                                      :dews => {},
                                      :winds => {},
                                      :sunshines => {},
                                      :monthly_accumulated_precipitations => {} }

    @states[@state][@subregion][:elevations] << @elevation
    @states[@state][@subregion][:latitudes] << @latitude
    @states[@state][@subregion][:longitudes] << @longitude
    (1..12).each do |month|
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
end

def flatten_array_into_national_averages
  @national_data = Hash.new
  @states.keys.sort.each do |state|
    @states[state].keys.sort.each do |subregion|
      number_of_stations = @states[state][subregion][:avg_monthly_highs][1].size #arbitrarily use size of January high_temp array to find # of stations 

      @national_data[state] ||= {}
      @national_data[state][subregion] ||= {}
      @national_data[state][subregion][:number_of_stations] = number_of_stations 
      @national_data[state][subregion][:latitude] = sum(@states[state][subregion][:latitudes]) / number_of_stations
      @national_data[state][subregion][:longitude] = sum(@states[state][subregion][:longitudes]) / number_of_stations
      @national_data[state][subregion][:elevation] = sum(@states[state][subregion][:elevations]) / number_of_stations

      (1..12).to_a.each do |month|
        # set up the hashes...
        @national_data[state][subregion][:t_max] ||= {}
        @national_data[state][subregion][:t_min] ||= {}
        @national_data[state][subregion][:t_dew] ||= {}
        @national_data[state][subregion][:wind_speed] ||= {}
        @national_data[state][subregion][:hours_of_sunshine] ||= {}
        @national_data[state][subregion][:accumulated_precipitation] ||= {}
        # ...and populate them.
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

def add_previous_month_temp_to_array
  @national_data.keys.sort.each do |state|
    @national_data[state].keys.sort.each do |subregion|
      @national_data[state][subregion][:t_max_previous] ||= {}
      @national_data[state][subregion][:t_min_previous] ||= {}
      (1..12).each do |month|
        @national_data[state][subregion][:t_max_previous][month] = @national_data[state][subregion][:t_max][previous_month(month)]
        @national_data[state][subregion][:t_min_previous][month] = @national_data[state][subregion][:t_min][previous_month(month)]
      end
    end
  end
end
