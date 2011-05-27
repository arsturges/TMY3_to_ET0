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
                    elevation,
                    state_wind,
                    latitude,
                    state_sunshine,
                    longitude,
                    state_precipitation,
                    number_of_stations
                    ]
        end
      end
    end 
  end
end

puts "the file 'write_to_csv_file.rb' has been read."
