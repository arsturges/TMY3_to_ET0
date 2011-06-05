require './TMY3.rb'
require './write_to_csv_file.rb'
require './penman-monteith.rb'
require 'pp'

#1: Read TMY3 Files
#2: Populate hash (this is done simultaneously with step 1)
#3: Go through hash and add in t_max_previous and t_min_previous?
#4: Print out CSV file for posterity and debugging purposes
#5: Feed hash to penman-monteith_monthly.rb
#6: Populate new hash of ET0 values

start_time = Time.now
@hourly_data = Hash.new

filenames = Dir.glob('../tmy3_test_files/*')
filenames.sort.each do |filename|
  @current_tmy3_file = CSV.read(filename)
  collect_station_characteristics 
  puts filename #progress indicator
  loop_through_TMY3_rows unless invalid?(@state, @elevation)
end
flatten_hourly_data_into_national_hourly_data
write_hourly_TMY3_data_to_the_csv_file("hourly_inputs.csv")

end_time = Time.now
execution_time = end_time - start_time
puts "Program completed in #{execution_time} seconds."
