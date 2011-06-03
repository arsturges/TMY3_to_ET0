#this file is for methods related to reading TMY3 data and outputing hourly ET0 inputs.
#this files needs to output for each hour of the year:
#temperature
#dew_point_temp
#wind_speed
#global_horizontal_irradiance
#direct_normal_irradiance (MJ m-2 hour-1)



def read_hourly_data(row0, row1, row4, row7, row31, row34, row46, row64)
  @row_date = row0
  @row_hour = row1
  @hourly_global_horizontal_irradiance = row4.to_f # need to convert this to MJ/m2 hour
  @hourly_direct_normal_irradiance = row7.to_f # need to convert this to MJ/m2 hour
  @hourly_temp = row31.to_f
  @hourly_dewpoint_temp = row34.to_f
  @hourly_wind_speed = row46.to_f
  @hourly_precipiation = row64.to_f
end

def generate_time_variables(date, time)
  #subtract 1 hr because DateTime puts "24:00" in the next day as "00:00"
  @current_row_datetime = DateTime.strptime(@row_date +" "+@row_hour, '%m/%d/%Y %H:%M') - 1/(24.0*60) 
  @year = @current_row_datetime.year
  @month = @current_row_datetime.month
  @day = @current_row_datetime.day
  @hour = @current_row_datetime.hour #spans 0..23
end

def loop_through_TMY3_rows 
  @station_array = Array.new
  @current_tmy3_file.each do |row| #Loop through each row. Each row is one hour; 24 rows per day.
    read_hourly_data(row[0], row[1], row[4], row[7], row[31], row[34], row[46], row[64])
    generate_time_variables(@row_date, @row_hour)

    @station_array[@month] ||= []
    @station_array[@month][@day] ||= []
    @station_array[@month][@day][@hour] = Hash.new
    @station_array[@month][@day][@hour] = {
      :temperature => @hourly_temp,
      :dew_point => @hourly_dewpoint_temp,
      :wind_speed => @hourly_wind_speed,
      :precipitation => @hourly_precipitation,
      :global_horizontal_irradiance => @hourly_global_horizontal_irradiance,
      :direct_normal_irradiance => @hourly_direct_normal_irradiance
    }
   end
  inject_station_values_into_main_hash
end

def inject_station_values_into_main_hash
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
                                      #below, set up hashes for averaged national values later
                                      :time_zone => [],
                                      :elevation => [],
                                      :latitude => [],
                                      :longitude => [],
                                      :temperature => {}, 
                                      :dew_point => {},
                                      :wind_speed => {},
                                      :global_horizontal_irradiance => {},
                                      :direct_normal_irradiance => {},
                                      :precipitation => {} }

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
    @hourly_data[@state][@subregion][:precipitations][month] ||= []
    #averages below
    @hourly_data[@state][@subregion][:temperature][month] ||= []
    @hourly_data[@state][@subregion][:dew_point][month] ||= []
    @hourly_data[@state][@subregion][:wind_speed][month] ||= []
    @hourly_data[@state][@subregion][:global_horizontal_irradiance][month] ||= []
    @hourly_data[@state][@subregion][:direct_normal_irradiance][month] ||= []
    @hourly_data[@state][@subregion][:precipitation][month] ||= []
   (1..days_in_month(month)).each do |day|
      @hourly_data[@state][@subregion][:temperatures][month][day] ||= []
      @hourly_data[@state][@subregion][:dew_points][month][day] ||= []
      @hourly_data[@state][@subregion][:wind_speeds][month][day] ||= []
      @hourly_data[@state][@subregion][:global_horizontal_irradiances][month][day] ||= []
      @hourly_data[@state][@subregion][:direct_normal_irradiances][month][day] ||= []
      @hourly_data[@state][@subregion][:precipitations][month][day] ||= []
      #averages below
      @hourly_data[@state][@subregion][:temperature][month][day] ||= []
      @hourly_data[@state][@subregion][:dew_point][month][day] ||= []
      @hourly_data[@state][@subregion][:wind_speed][month][day] ||= []
      @hourly_data[@state][@subregion][:global_horizontal_irradiance][month][day] ||= []
      @hourly_data[@state][@subregion][:direct_normal_irradiance][month][day] ||= []
      @hourly_data[@state][@subregion][:precipitation][month][day] ||= []
      (0..23).each do |hour|
         @hourly_data[@state][@subregion][:temperatures][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:dew_points][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:wind_speeds][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:global_horizontal_irradiances][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:direct_normal_irradiances][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:precipitations][month][day][hour] ||= []
         #averages below. may not be necessary
         @hourly_data[@state][@subregion][:temperature][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:dew_point][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:wind_speed][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:global_horizontal_irradiance][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:direct_normal_irradiance][month][day][hour] ||= []
         @hourly_data[@state][@subregion][:precipitation][month][day][hour] ||= []

         #...and add the hourly datay. Each new file from the tmy3 folder appends one element to this array.
  @hourly_data[@state][@subregion][:global_horizontal_irradiance][1][1][11]
         @hourly_data[@state][@subregion][:temperatures][month][day][hour] << @station_array[month][day][hour][:temperature]
         @hourly_data[@state][@subregion][:dew_points][month][day][hour] << @station_array[month][day][hour][:dew_point]
         @hourly_data[@state][@subregion][:wind_speeds][month][day][hour] << @station_array[month][day][hour][:wind_speed]
         @hourly_data[@state][@subregion][:global_horizontal_irradiances][month][day][hour] << @station_array[month][day][hour][:global_horizontal_irradiance]
         @hourly_data[@state][@subregion][:direct_normal_irradiances][month][day][hour] << @station_array[month][day][hour][:direct_normal_irradiance]
         @hourly_data[@state][@subregion][:precipitations][month][day][hour] << @station_array[month][day][hour][:precipitation]
       end
    end
  end
end

def flatten_hourly_data_into_national_hourly_data
  @hourly_data.keys.sort.each do |state|
    @hourly_data[state].keys.sort.each do |subregion|
      number_of_stations = @hourly_data[state][subregion][:elevations].size
      time_zone = sum(@hourly_data[state][subregion][:time_zones]) / number_of_stations
      elevation = sum(@hourly_data[state][subregion][:elevations]) / number_of_stations
      latitude = sum(@hourly_data[state][subregion][:latitudes]) / number_of_stations
      longitude = sum(@hourly_data[state][subregion][:longitudes]) / number_of_stations

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
            precipitation   = sum(@hourly_data[state][subregion][:precipitation][month][day][hour]) / number_of_stations
            
            @hourly_data[state][subregion][:temperature][month][day][hour] = temperature
            @hourly_data[state][subregion][:dew_point][month][day][hour] = dew_point 
            @hourly_data[state][subregion][:wind_speed][month][day][hour] = wind_speed 
            @hourly_data[state][subregion][:global_horizontal_irradiance][month][day][hour] = global_horizontal_irradiance 
            @hourly_data[state][subregion][:direct_normal_irradiance][month][day][hour] = direct_normal_irradiance 
            @hourly_data[state][subregion][:precipitation][month][day][hour] = precipitation 
          end
        end
      end
    end
  end
end
