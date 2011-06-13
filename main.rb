require './TMY3.rb'
require './write_to_csv_file.rb'
require './penman-monteith.rb'

start_time = Time.now
@hourly_data = Hash.new

filenames = Dir.glob('../tmy3_test_files/*')
filenames.sort.each do |filename|
  @current_tmy3_file = CSV.read(filename)
  collect_station_characteristics 
  puts filename #progress indicator
  loop_through_TMY3_rows_and_populate_station_array unless invalid?(@state, @elevation)
end

flatten_station_data_into_subregional_data
write_subregional_data_to_csv_file("hourly.csv")
generate_monthly_et0
write_monthly_summary_data_to_csv("monthly.csv")

end_time = Time.now
execution_time = end_time - start_time
puts "Program completed in #{execution_time} seconds."
puts "Program completed in #{execution_time/60} minutes."
puts "Program completed in #{execution_time/60/60} hours."
