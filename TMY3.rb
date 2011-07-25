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

def invalid?(state, elevation)
  elevation_is_too_great = ( elevation >= 1000 )
  disallowed_states = ["GU", "PR", "VI"]
  this_state_is_not_allowed = disallowed_states.include?(state)
  if elevation_is_too_great or this_state_is_not_allowed 
    return true
  else
    return false
  end
end

def collect_station_characteristics
  header1 = @current_tmy3_file.shift
  header2 = @current_tmy3_file.shift #remove column headers
  
  #read basic info about the weather station  
  @state = header1[2]
  @time_zone = header1[3]
  @subregion = nil
  @latitude =  header1[4].to_f.abs
  @longitude = header1[5].to_f.abs
  @elevation = header1[6].to_i

  #identify subregions
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

def read_hourly_data(row0, row1, row4, row7, row25, row31, row34, row46, row64)
  @row_date = row0
  @row_hour = row1
  @hourly_global_horizontal_irradiance = row4.to_f # need to convert this to MJ/m2 hour
  @hourly_direct_normal_irradiance = row7.to_f # need to convert this to MJ/m2 hour
  @hourly_sky_coverage = row25.to_i
  @hourly_temp = row31.to_f
  @hourly_dew_point_temp = row34.to_f + (row34.to_f*0.05).abs #will always increase to the right on the number line
  @hourly_wind_speed = row46.to_f
  @hourly_precipiation = row64.to_f
end

def generate_time_variables(date, time)
  @current_row_datetime = DateTime.strptime(@row_date +" "+@row_hour, '%m/%d/%Y %H:%M') - 1/(24.0*60) #subtract 1 hr because DateTime puts "24:00" in the next day as "00:00"
  @year = @current_row_datetime.year
  @month = @current_row_datetime.month
  @day = @current_row_datetime.day
  @hour = @current_row_datetime.hour #spans 0..23
end

def loop_through_TMY3_rows_and_populate_station_array
  @station_array = Array.new
  @current_tmy3_file.each do |row| #Loop through each row. Each row is one hour; 24 rows per day.
    read_hourly_data(row[0], row[1], row[4], row[7], row[25], row[31], row[34], row[46], row[64])
    generate_time_variables(@row_date, @row_hour)

    @station_array[@month] ||= []
    @station_array[@month][@day] ||= []
    @station_array[@month][@day][@hour] = Hash.new
    @station_array[@month][@day][@hour] = {
      :temperature => @hourly_temp,
      :dew_point => @hourly_dew_point_temp,
      :wind_speed => @hourly_wind_speed,
      :precipitation => @hourly_precipitation,
      :global_horizontal_irradiance => @hourly_global_horizontal_irradiance,
      :direct_normal_irradiance => @hourly_direct_normal_irradiance,
      :total_sky_cover => @hourly_sky_coverage,
      :station_et0 => compute_hourly_et0(
        @state,
        @subregion,
        @time_zone,
        @elevation,
        @longitude,
        @latitude,
        @month,
        @day,
        @hour,
        @hourly_temp,
        @hourly_dew_point_temp,
        @hourly_wind_speed,
        @hourly_global_horizontal_irradiance,
        @hourly_direct_normal_irradiance,
        @hourly_sky_coverage)
    }
    end
  inject_station_array_values_into_main_hash
end

def inject_station_array_values_into_main_hash
  #Set up the arrays if they don't exist...
  @hourly_data[@state] ||= {}
  @hourly_data[@state][@subregion] ||= { 
                                      :time_zones => [],
                                      :elevations => [],
                                      :latitudes => [],
                                      :longitudes => [],
                                      :temperatures => {}, 
                                      :dew_points => {},
                                      :wind_speeds => {},
                                      :global_horizontal_irradiances => {},
                                      :direct_normal_irradiances => {},
                                      :precipitations => {},
                                      :total_sky_covers => {},
                                      :station_et0s => {},
                                      #below, set up hashes for averaged national values later
                                      :number_of_stations => [], #:elevations.size, below
                                      :time_zone => [],
                                      :elevation => [],
                                      :latitude => [],
                                      :longitude => [],
                                      :temperature => {}, 
                                      :dew_point => {},
                                      :wind_speed => {},
                                      :global_horizontal_irradiance => {},
                                      :direct_normal_irradiance => {},
                                      :total_sky_cover => {},
                                      :precipitation => {},
                                      :et0_from_et0s => {},
                                      :et0_from_weather_data => {} }

  @hourly_data[@state][@subregion][:time_zones] << @time_zone
  @hourly_data[@state][@subregion][:elevations] << @elevation
  @hourly_data[@state][@subregion][:latitudes] << @latitude
  @hourly_data[@state][@subregion][:longitudes] << @longitude
  (1..12).each do |month|
    @hourly_data[@state][@subregion][:temperatures][month] ||= []
    @hourly_data[@state][@subregion][:dew_points][month] ||= []
    @hourly_data[@state][@subregion][:wind_speeds][month] ||= []
    @hourly_data[@state][@subregion][:global_horizontal_irradiances][month] ||= []
    @hourly_data[@state][@subregion][:direct_normal_irradiances][month] ||= []
    @hourly_data[@state][@subregion][:total_sky_covers][month] ||= []
    @hourly_data[@state][@subregion][:precipitations][month] ||= []
    @hourly_data[@state][@subregion][:station_et0s][month] ||= []
    #averages below
    @hourly_data[@state][@subregion][:temperature][month] ||= []
    @hourly_data[@state][@subregion][:dew_point][month] ||= []
    @hourly_data[@state][@subregion][:wind_speed][month] ||= []
    @hourly_data[@state][@subregion][:global_horizontal_irradiance][month] ||= []
    @hourly_data[@state][@subregion][:direct_normal_irradiance][month] ||= []
    @hourly_data[@state][@subregion][:total_sky_cover][month] ||= []
    @hourly_data[@state][@subregion][:precipitation][month] ||= []
    @hourly_data[@state][@subregion][:et0_from_et0s][month] ||= []
    @hourly_data[@state][@subregion][:et0_from_weather_data][month] ||= []
   (1..days_in_month(month)).each do |day|
      @hourly_data[@state][@subregion][:temperatures][month][day] ||= []
      @hourly_data[@state][@subregion][:dew_points][month][day] ||= []
      @hourly_data[@state][@subregion][:wind_speeds][month][day] ||= []
      @hourly_data[@state][@subregion][:global_horizontal_irradiances][month][day] ||= []
      @hourly_data[@state][@subregion][:direct_normal_irradiances][month][day] ||= []
      @hourly_data[@state][@subregion][:total_sky_covers][month][day] ||= []
      @hourly_data[@state][@subregion][:precipitations][month][day] ||= []
      @hourly_data[@state][@subregion][:station_et0s][month][day] ||= []
      #averages below
      @hourly_data[@state][@subregion][:temperature][month][day] ||= []
      @hourly_data[@state][@subregion][:dew_point][month][day] ||= []
      @hourly_data[@state][@subregion][:wind_speed][month][day] ||= []
      @hourly_data[@state][@subregion][:global_horizontal_irradiance][month][day] ||= []
      @hourly_data[@state][@subregion][:direct_normal_irradiance][month][day] ||= []
      @hourly_data[@state][@subregion][:total_sky_cover][month][day] ||= []
      @hourly_data[@state][@subregion][:precipitation][month][day] ||= []
      @hourly_data[@state][@subregion][:et0_from_et0s][month][day] ||= []
      @hourly_data[@state][@subregion][:et0_from_weather_data][month][day] ||= []
      (0..23).each do |hour|
         @hourly_data[@state][@subregion][:temperatures][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:dew_points][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:wind_speeds][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:global_horizontal_irradiances][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:direct_normal_irradiances][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:total_sky_covers][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:precipitations][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:station_et0s][month][day][hour] ||= []
         #averages below. may not be necessary
         @hourly_data[@state][@subregion][:temperature][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:dew_point][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:wind_speed][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:global_horizontal_irradiance][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:direct_normal_irradiance][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:total_sky_cover][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:precipitation][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:et0_from_et0s][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:et0_from_weather_data][month][day][hour] ||= []

         #...and add the hourly data. Each new file from the tmy3 folder appends one element to this array.
         @hourly_data[@state][@subregion][:temperatures][month][day][hour] << @station_array[month][day][hour][:temperature]
         @hourly_data[@state][@subregion][:dew_points][month][day][hour] << @station_array[month][day][hour][:dew_point]
         @hourly_data[@state][@subregion][:wind_speeds][month][day][hour] << @station_array[month][day][hour][:wind_speed]
         @hourly_data[@state][@subregion][:global_horizontal_irradiances][month][day][hour] << @station_array[month][day][hour][:global_horizontal_irradiance]
         @hourly_data[@state][@subregion][:direct_normal_irradiances][month][day][hour] << @station_array[month][day][hour][:direct_normal_irradiance]
         @hourly_data[@state][@subregion][:total_sky_covers][month][day][hour] << @station_array[month][day][hour][:total_sky_cover]
         @hourly_data[@state][@subregion][:precipitations][month][day][hour] << @station_array[month][day][hour][:precipitation]
         @hourly_data[@state][@subregion][:station_et0s][month][day][hour] << @station_array[month][day][hour][:station_et0]
      end
    end
  end
end

def flatten_station_data_into_subregional_data
  @hourly_data.keys.sort.each do |state|
    @hourly_data[state].keys.sort.each do |subregion|
      number_of_stations = @hourly_data[state][subregion][:elevations].size
      time_zone = sum(@hourly_data[state][subregion][:time_zones]) / number_of_stations
      elevation = sum(@hourly_data[state][subregion][:elevations]) / number_of_stations
      latitude = sum(@hourly_data[state][subregion][:latitudes]) / number_of_stations
      longitude = sum(@hourly_data[state][subregion][:longitudes]) / number_of_stations

      @hourly_data[state][subregion][:number_of_stations] = number_of_stations 
      @hourly_data[state][subregion][:time_zone] = time_zone.to_i 
      @hourly_data[state][subregion][:elevation] = elevation
      @hourly_data[state][subregion][:latitude] = latitude 
      @hourly_data[state][subregion][:longitude] = longitude 

      (1..12).each do |month|
        (1..days_in_month(month)).each do |day|
          (0..23).each do |hour|
            temperature     = sum(@hourly_data[state][subregion][:temperatures][month][day][hour]) / number_of_stations
            dew_point       = sum(@hourly_data[state][subregion][:dew_points][month][day][hour]) / number_of_stations
            wind_speed      = sum(@hourly_data[state][subregion][:wind_speeds][month][day][hour]) / number_of_stations
            global_horizontal_irradiance = sum(@hourly_data[state][subregion][:global_horizontal_irradiances][month][day][hour]) / number_of_stations
            direct_normal_irradiance = sum(@hourly_data[state][subregion][:direct_normal_irradiances][month][day][hour]) / number_of_stations
            total_sky_cover = sum(@hourly_data[state][subregion][:total_sky_covers][month][day][hour]) / number_of_stations
            precipitation   = sum(@hourly_data[state][subregion][:precipitations][month][day][hour]) / number_of_stations
            et0_from_et0s = sum(@hourly_data[state][subregion][:station_et0s][month][day][hour]) / number_of_stations
            et0_from_weather_data = compute_hourly_et0(
              state,
              subregion,
              time_zone,
              elevation,
              longitude,
              latitude,
              month,
              day,
              hour,
              temperature,
              dew_point,
              wind_speed,
              global_horizontal_irradiance,
              direct_normal_irradiance,
              total_sky_cover)

            @hourly_data[state][subregion][:temperature][month][day][hour] = temperature
            @hourly_data[state][subregion][:dew_point][month][day][hour] = dew_point 
            @hourly_data[state][subregion][:wind_speed][month][day][hour] = wind_speed 
            @hourly_data[state][subregion][:global_horizontal_irradiance][month][day][hour] = global_horizontal_irradiance 
            @hourly_data[state][subregion][:direct_normal_irradiance][month][day][hour] = direct_normal_irradiance 
            @hourly_data[state][subregion][:total_sky_cover][month][day][hour] = total_sky_cover
            @hourly_data[state][subregion][:precipitation][month][day][hour] = precipitation 
            @hourly_data[state][subregion][:et0_from_et0s][month][day][hour] = et0_from_et0s 
            @hourly_data[state][subregion][:et0_from_weather_data][month][day][hour] = et0_from_weather_data
          end
        end
      end
    end
  end
end

def generate_monthly_et0
  @monthly_data = Hash.new
  @hourly_data.keys.sort.each do |state|
    @monthly_data[state] = {}
    @hourly_data[state].keys.sort.each do |subregion|
      @monthly_data[state][subregion] = {}
      @monthly_data[state][subregion][:number_of_stations] = @hourly_data[state][subregion][:number_of_stations]
      @monthly_data[state][subregion][:time_zone] = @hourly_data[state][subregion][:time_zone]
      @monthly_data[state][subregion][:elevation] = @hourly_data[state][subregion][:elevation]
      @monthly_data[state][subregion][:latitude] = @hourly_data[state][subregion][:latitude]
      @monthly_data[state][subregion][:longitude] = @hourly_data[state][subregion][:longitude]
      @monthly_data[state][subregion][:et0] = Array.new
      @monthly_data[state][subregion][:temperature] = Array.new
      @monthly_data[state][subregion][:avg_day_temp] = Array.new
      @monthly_data[state][subregion][:avg_night_temp] = Array.new
      (1..12).each do |month|
        @monthly_data[state][subregion][:et0][month] = 0
        @monthly_data[state][subregion][:temperature][month] = 0 
        daytime_temps = Array.new
        nighttime_temps = Array.new
        (1..days_in_month(month)).each do |day|
          (0..23).each do |hour|
            et0 = @hourly_data[state][subregion][:et0_from_et0s][month][day][hour]
            @monthly_data[state][subregion][:et0][month] += et0
            temp = @hourly_data[state][subregion][:temperature][month][day][hour]
            @monthly_data[state][subregion][:temperature][month] += temp

            if @hourly_data[state][subregion][:direct_normal_irradiance][month][day][hour] > 0
              daytime_temps << @hourly_data[state][subregion][:temperature][month][day][hour] 
            else
              nighttime_temps << @hourly_data[state][subregion][:temperature][month][day][hour] 
            end
          end #hour
        end #day
        @monthly_data[state][subregion][:temperature][month] = @monthly_data[state][subregion][:temperature][month] / (days_in_month(month) * 24) #hours in month
        @monthly_data[state][subregion][:avg_day_temp][month] = sum(daytime_temps)/daytime_temps.size
        @monthly_data[state][subregion][:avg_night_temp][month] = sum(nighttime_temps)/nighttime_temps.size
      end #month
    end
  end
end
