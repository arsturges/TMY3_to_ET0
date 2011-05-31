start_time = Time.now
require 'read_TMY3_files_and_populate_array.rb'
require 'write_to_csv_file.rb'
require 'penman-monteith_monthly.rb'

#1: Read TMY3 Files
#2: Populate array @states (this is done simultaneously with step 1)
#3: Go through array and add in t_max_previous and t_min_previous?
#4: Print out CSV file for posterity and debugging purposes
#5: Feed array to penman-monteith_monthly.rb
#6: Populate new array of ET0 values
#


@states = Hash.new

filenames = Dir.glob('../tmy3_test_files/*')
filenames.sort.each do |filename|
  @current_tmy3_file = CSV.read(filename)
  collect_station_characteristics 
  puts filename #progress indicator
  initialize_arrays_and_variables
  collect_station_weather_data unless invalid?
  set_state_values unless invalid?
end

flatten_array_into_national_averages
add_previous_temp_to_states_array
write_to_the_csv_file("test.csv")

end_time = Time.now
execution_time = end_time - start_time
puts "Program completed in #{execution_time} seconds."
