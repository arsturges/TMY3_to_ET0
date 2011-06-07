require 'csv'

def write_subregional_data_to_csv_file(filename)
  CSV.open(filename, "w") do |writer|
    writer.add_row(%w(state
                      subregion
                      number_of_stations
                      time_zone_(hours)
                      elevation_(m) 
                      latitude 
                      longitude 
                      month 
                      day
                      hour
                      temperature_(C)
                      dew_point_(C)
                      wind_speed_(m/s) 
                      global_horizontal_irradiance_(W/m2)
                      direct_normal_irradiance_(W/m2)
                      precipitation_(mm) 
                      et0_from_et0s
                      et0_from_weather_data))

    @hourly_data.keys.sort.each do |state|
      @hourly_data[state].keys.sort.each do |subregion|
        number_of_stations = @hourly_data[state][subregion][:number_of_stations]
        time_zone = @hourly_data[state][subregion][:time_zone]
        elevation =          @hourly_data[state][subregion][:elevation]
        latitude =           @hourly_data[state][subregion][:latitude]
        longitude =          @hourly_data[state][subregion][:longitude]
        (1..12).each do |month|
          (1..days_in_month(month)).each do |day|
            (0..23).each do |hour|
              temperature =                   @hourly_data[state][subregion][:temperature][month][day][hour]
              dew_point =                     @hourly_data[state][subregion][:dew_point][month][day][hour]
              wind_speed =                    @hourly_data[state][subregion][:wind_speed][month][day][hour]
              global_horizontal_irradiance =  @hourly_data[state][subregion][:global_horizontal_irradiance][month][day][hour]
              direct_normal_irradiance =      @hourly_data[state][subregion][:direct_normal_irradiance][month][day][hour]
              precipitation =                 @hourly_data[state][subregion][:precipitation][month][day][hour]
              et0_from_et0s =                 @hourly_data[state][subregion][:et0_from_et0s][month][day][hour]
              et0_from_weather_data =         @hourly_data[state][subregion][:et0_from_weather_data][month][day][hour]

              writer << [
                    state,
                    subregion,
                    number_of_stations,
                    time_zone,
                    elevation,
                    latitude,
                    longitude,
                    month,
                    day,
                    hour,
                    temperature,
                    dew_point,
                    wind_speed,
                    global_horizontal_irradiance,
                    direct_normal_irradiance,
                    precipitation,
                    et0_from_et0s,
                    et0_from_weather_data
                    ]
            end
          end
        end
      end
    end 
  end
end

def write_monthly_summary_data_to_csv(filename)
  CSV.open(filename, "w") do |writer|
    writer.add_row(%w(state
                      subregion
                      elevation_(m) 
                      month 
                      avg_24-hour_temperature
                      avg_day_temp
                      avg_night_temp
                      et0))
    @monthly_data.keys.sort.each do |state|
      @monthly_data[state].keys.sort.each do |subregion|
        (1..12).each do |month|
          writer << [
            state,
            subregion,
            @monthly_data[state][subregion][:elevation],
            month,
            @monthly_data[state][subregion][:temperature][month],
            @monthly_data[state][subregion][:avg_day_temp][month],
            @monthly_data[state][subregion][:avg_night_temp][month],
            @monthly_data[state][subregion][:et0][month]
          ]
        end
      end
    end
  end
end
