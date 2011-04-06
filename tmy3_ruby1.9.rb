require 'rubygems' #think this is uncessary. when program works, delete this line.
require 'csv'

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

def set_state_values
  if @state
    @states[@state] = {} unless @states[@state]
    if @subregion
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
        #Set up the arrays...
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
    end #subregion
  end #state
end

def set_monthly_averages
  overnight_lows_sum = sum(@overnight_lows.values)
  daily_highs_sum = sum(@daily_highs.values) 
  dew_sum = sum(@days_dew.values)
  wind_sum = sum(@days_wind.values)
  sunshine_sum = sum(@days_sunshine.values)
  total_monthly_precipitation = sum(@daily_precips.values)

  days_in_month = @daily_highs.size #this appears to be returning n-1
  @weather_averages_by_month[@month] = {                                    #@weather_averages_by_month[1] ...
    :avg_monthly_high => daily_highs_sum.to_f / days_in_month,              #this is that month's average overnight low
    :avg_monthly_low => overnight_lows_sum.to_f / days_in_month,            #this is that month's average daily high
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
  @month = @current_row_month
  @day = 1
  reset_daily_weather_variables
end

def set_daily_values
  @daily_highs[@day] = @max_temp
  @overnight_lows[@day] = @min_temp
  @days_dew[@day] = @dew / 24
  @days_wind[@day] = @wind / 24
  @days_sunshine[@day] = @sunshine #total accumulated hours of sunshine
  @daily_precips[@day] = @precipitation #total accumulated mm of precip
  @day = @current_row_day
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
  #initialize arrays to hold data from this particular weather station
  @weather_averages_by_month = {}
  @overnight_lows = {}
  @daily_highs = {}
  @days_dew = {}
  @days_wind = {}
  @days_sunshine = {}
  @daily_precips = {}
  @month = 1
  @day = 1
  reset_daily_weather_variables
end

def write_to_the_csv_file(filename)
  CSV.open(filename, "w") do |writer|
    writer.add_row(%w(state
                      subregion
                      month 
                      avg_max_temp 
                      avg_min_temp 
                      avg_dew_temp 
                      wind_speed_(m/s) 
                      latitude 
                      longitude 
                      elevation_(m) 
                      sunshine 
                      accumulated_liquid_precipitation_(mm) 
                      category 
                      stations))

    state_keys = @states.keys.sort
    state_keys.each do |state|
      subregion_keys = @states[state].keys.sort
      subregion_keys.each do |subregion|
        (1..12).to_a.each do |month|
          number_of_stations =        @states[state][subregion][:avg_monthly_highs][month].size 
          latitude =              sum(@states[state][subregion][:latitudes]) / number_of_stations
          longitude =             sum(@states[state][subregion][:longitudes]) / number_of_stations
          elevation =             sum(@states[state][subregion][:elevations]) / number_of_stations
          state_daily_highs =     sum(@states[state][subregion][:avg_monthly_highs][month]).to_f/ number_of_stations
          state_overnight_lows =  sum(@states[state][subregion][:avg_monthly_lows][month]).to_f/ number_of_stations
          state_dew =             sum(@states[state][subregion][:dews][month]).to_f/ number_of_stations
          state_wind =            sum(@states[state][subregion][:winds][month]).to_f/ number_of_stations
          state_sunshine =        sum(@states[state][subregion][:sunshines][month]).to_f/ number_of_stations
          state_precipitation =   sum(@states[state][subregion][:monthly_accumulated_precipitations][month]).to_f/ number_of_stations
          writer << [
                    state,
                    subregion,
                    month,
                    state_daily_highs,
                    state_overnight_lows,
                    state_dew,
                    state_wind,
                    latitude,
                    longitude,
                    elevation,
                    state_sunshine,
                    state_precipitation,
                    number_of_stations
                    ]
        end
      end
    end 
  end
end

def collect_station_weather_data
  @current_tmy3_file.each do |row| #Loop through each row. Each row is one hour; 24 rows per day.

    current_row_date = Date.strptime(row[0], '%m/%d/%Y') 
    @current_row_month = current_row_date.month
    @current_row_day = current_row_date.day
      
    # If month changes, we've looped through all hours for that month and 
    # stored all day-level information. Now store it:
    set_monthly_averages unless @month == @current_row_month 
    set_daily_values unless @day == @current_row_day

    #we want the daily high temp and the overnight low temp
    @max_temp = row[31].to_f if row[31].to_f > @max_temp #which was initialized to -999 in "reset_values" method
    @min_temp = row[31].to_f if row[31].to_f < @min_temp #which was initizlized to 999
     
    @dew += row[34].to_f
    @wind += row[46].to_f
    @precipitation += row[64].to_f unless row[64].to_i == -9900
    @sunshine = @sunshine + 1 if row[7].to_i > 120
    # we want (hours of sunshine)/day, which is defined as 
    # direct normal irradiance normal to sun > 120 W/m^2. http://www.satel-light.com/guide/glosstoz.htm
  end
  # The file ends without triggering final day and month writes. We call them explicitly:
  set_daily_values
  set_monthly_averages
  set_state_values
end

def valid?
  elevation = ( @elevation <= 1000 )
  state = ( @state != ("AK" or "HI"))
  if elevation and state
    return true
  else
    return false
  end
end

@states = Hash.new

filenames = Dir.glob('tmy3_test_files/*')
filenames.sort.each do |filename|
  @current_tmy3_file = CSV.read(filename)
  collect_station_characteristics 
  puts filename #progress indicator
  puts valid?
  initialize_arrays_and_variables
  collect_station_weather_data if valid?
end

write_to_the_csv_file("test.csv")
