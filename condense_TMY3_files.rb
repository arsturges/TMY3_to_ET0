require 'csv'
require './penman-monteith.rb'
require './TMY3.rb'

def create_new_csv_file_populate_and_close(tmy3_array, station_data_array)
  new_file_name = @header1[0]
  puts new_file_name
  CSV.open("../tmy3_files_reduced_for_PM/#{new_file_name}.csv", "wb") do |new_row|
    new_row << [@header1[0], @header1[1], @header1[2], @header1[3], @header1[4], @header1[5], @header1[6]]
    new_row << [
      "month", 
      "day", 
      "hour",  
      @header2[4], 
      @header2[7], 
      @header2[25], 
      @header2[31], 
      @header2[34], 
      @header2[46], 
      @header2[64], 
      "et0_base"
    ]
    determine_temp_ranges(new_file_name, station_data_array) #returns a hash called @ranges
    tmy3_array.each do |row| #Loop through each row of tmy3 data. Each row is one hour; 24 rows per day.
      read_hourly_data(row[0], row[1], row[4], row[7], row[25], row[31], row[34], row[46], row[64])
      generate_time_variables(@row_date, @row_hour)

      new_row << [
        @month,
        @day,
        @hour,
        @hourly_global_horizontal_irradiance,
        @hourly_direct_normal_irradiance,
        @hourly_sky_coverage,
        @hourly_temp,
        @hourly_dew_point_temp,
        @hourly_wind_speed,
        @hourly_precipitation,
        compute_hourly_et0(
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
      ]
    end
  end
end

station_data_array = CSV.read("station_data.csv")
filenames = Dir.glob('../tmy3/*')
filenames.sort.each do |filename|
  start_time = Time.now
  current_tmy3_file = CSV.read(filename)
  collect_station_characteristics(current_tmy3_file)
  create_new_csv_file_populate_and_close(current_tmy3_file, station_data_array) unless invalid?(@state, @elevation)
  end_time = Time.now
  elapsed_time = end_time - start_time
  puts "Elapsed time: #{elapsed_time} seconds."
end
