require 'csv'

def write_to_the_csv_file(filename)
  CSV.open(filename, "w") do |writer|
    writer.add_row(%w(state
                      subregion
                      month 
                      avg_max_temp 
                      avg_min_temp 
                      avg_dew_temp 
                      elevation_(m) 
                      wind_speed_(m/s) 
                      latitude 
                      sunshine 
                      longitude 
                      accumulated_liquid_precipitation_(mm) 
                      stations
                      t_max_previous
                      t_min_previous))

    state_keys = @national_data.keys.sort
    state_keys.each do |state|
      subregion_keys = @national_data[state].keys.sort
      subregion_keys.each do |subregion|
        number_of_stations = @national_data[state][subregion][:number_of_stations]
        latitude =           @national_data[state][subregion][:latitude]
        longitude =          @national_data[state][subregion][:longitude]
        elevation =          @national_data[state][subregion][:elevation]
        (1..12).to_a.each do |month|
          state_daily_highs =    @national_data[state][subregion][:t_max][month]
          state_overnight_lows = @national_data[state][subregion][:t_min][month]
          state_dew =            @national_data[state][subregion][:t_dew][month]
          state_wind =           @national_data[state][subregion][:wind_speed][month]
          state_sunshine =       @national_data[state][subregion][:hours_of_sunshine][month]
          state_precipitation =  @national_data[state][subregion][:accumulated_precipitation][month]
          state_daily_previous_highs = @national_data[state][subregion][:t_max_previous][month]
          state_daily_previous_lows = @national_data[state][subregion][:t_min_previous][month]

          writer << [
                    state,
                    subregion,
                    month,
                    state_daily_highs,
                    state_overnight_lows,
                    state_dew,
                    elevation,
                    state_wind,
                    latitude,
                    state_sunshine,
                    longitude,
                    state_precipitation,
                    number_of_stations,
                    state_daily_previous_highs,
                    state_daily_previous_lows
                    ]
        end
      end
    end 
  end
end
