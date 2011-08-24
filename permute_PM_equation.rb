require 'csv'
require './penman-monteith.rb'
require './TMY3.rb'

def determine_temp_ranges(station_id, array_of_station_data)
  array_of_station_data.each do |row|
    if row[0] == station_id
      t_max = row[5].to_f 
      t_min = row[6].to_f
      t_dew_max = row[7].to_f
      t_dew_min = row[8].to_f
      @ranges = {:temp_range => t_max - t_min, :dew_point_range => t_dew_max - t_dew_min} 
      #returns a hash
    end
  end
end

def create_new_csv_file_populate_and_close(tmy3_array, station_data_array)
  new_file_name = @header1[0]
  puts new_file_name
  CSV.open("../tmy3_files_reduced_for_PM_with_perturbations/#{new_file_name}.csv", "wb") do |new_row|

    new_row << [@header1[0], @header1[1], @header1[2], @header1[3], @header1[4], @header1[5], @header1[6]]
    new_row << [
      "month", 
      "day", 
      "hour",  
      @header2[3], #ghi
      @header2[4], #DNI 
      @header2[5], # cldcover
      @header2[6], #temp
      @header2[7], #dew point
      @header2[8], #wind speed
      @header2[9], #precip
      "et0_base", 
      "et0_T_+5%", 
      "et0_T_-5%",
      "et0_T_+10%",
      "et0_T_-5%",
      "et0_Td_+5%",
      "et0_Td_-5%",
      "et0_Td_+10%",
      "et0_Td_-10%",
      "et0_T_and_Td_+5%",
      "et0_T_and_Td_-5%",
      "et0_T_and_Td_+10%",
      "et0_T_and_Td_-10%",
      "eto_T_+5%_and_Td_-5%",
      "et0_T_+10%_and_Td_-10%",
      "et0_T_-5%_and_Td_+5%",
      "et0_T_-10%_and_Td_+10%"
    ]
    determine_temp_ranges(new_file_name, station_data_array) #returns a hash called @ranges
    tmy3_array.each do |row| #Loop through each row of tmy3 data. Each row is one hour; 24 rows per day.
      @month = row[0].to_i
      @day = row[1].to_i
      @hour = row[2].to_i
      @hourly_global_horizontal_irradiance = row[3].to_f
      @hourly_direct_normal_irradiance = row[4].to_f
      @hourly_sky_coverage = row[5].to_i
      @hourly_temp = row[6].to_f
      @hourly_dew_point_temp = row[7].to_f
      @hourly_wind_speed = row[8].to_f
      @hourly_precip = row[9].to_f

      compute_et0_perturbations(@ranges)

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
        sprintf('%.4f', compute_hourly_et0(
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
          @hourly_sky_coverage)),
        sprintf('%.4f', @et0_T_up_5),
        sprintf('%.4f', @et0_T_down_5),
        sprintf('%.4f', @et0_T_up_10),
        sprintf('%.4f', @et0_T_down_10),
        sprintf('%.4f', @et0_Td_up_5),
        sprintf('%.4f', @et0_Td_down_5),
        sprintf('%.4f', @et0_Td_up_10),
        sprintf('%.4f', @et0_Td_down_10),
        sprintf('%.4f', @et0_T_and_Td_up_5),
        sprintf('%.4f', @et0_T_and_Td_down_5),
        sprintf('%.4f', @et0_T_and_Td_up_10),
        sprintf('%.4f', @et0_T_and_Td_down_10),
        sprintf('%.4f', @et0_T_up_5_and_Td_down_5),
        sprintf('%.4f', @et0_T_up_10_and_Td_down_10),
        sprintf('%.4f', @et0_T_down_5_and_Td_up_5),
        sprintf('%.4f', @et0_T_down_10_and_Td_up_10)
      ]
    end
  end
end

def compute_et0_perturbations(hash_of_ranges)
  @et0_T_up_5 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          @hourly_temp + hash_of_ranges[:temp_range] * 0.05,
          @hourly_dew_point_temp,
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_T_down_5 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          hourly_temp = @hourly_temp - hash_of_ranges[:temp_range] * 0.05,
          [@hourly_dew_point_temp, hourly_temp].min, #dew point may be forced down to match adjusted temp
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_T_up_10 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          @hourly_temp + hash_of_ranges[:temp_range] * 0.1,
          @hourly_dew_point_temp,
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_T_down_10 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          hourly_temp = @hourly_temp - hash_of_ranges[:temp_range] * 0.1,
          [@hourly_dew_point_temp, hourly_temp].min, #dew point may be forced down to match adjusted temp
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_Td_up_5 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          @hourly_temp,
          [@hourly_dew_point_temp + hash_of_ranges[:dew_point_range] * 0.05, @hourly_temp].min, #dew point is upwardly constrained by temp
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_Td_down_5 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          @hourly_temp,
          @hourly_dew_point_temp - hash_of_ranges[:dew_point_range] * 0.05,
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_Td_up_10 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          @hourly_temp,
          [@hourly_dew_point_temp + hash_of_ranges[:dew_point_range] * 0.1, @hourly_temp].min, #dew point is upwardly constrained by temp
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_Td_down_10 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          @hourly_temp,
          @hourly_dew_point_temp - hash_of_ranges[:dew_point_range] * 0.1,
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_T_and_Td_up_5 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          hourly_temp = @hourly_temp + hash_of_ranges[:temp_range] * 0.05,
          [@hourly_dew_point_temp + hash_of_ranges[:dew_point_range] * 0.05, hourly_temp].min, #upwardly constrained by adjusted temp
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_T_and_Td_down_5 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          hourly_temp = @hourly_temp - hash_of_ranges[:temp_range] * 0.05,
          [@hourly_dew_point_temp - hash_of_ranges[:dew_point_range] * 0.05, hourly_temp].min, #upwardly constrained by adjusted temp
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_T_and_Td_up_10 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          hourly_temp = @hourly_temp + hash_of_ranges[:temp_range] * 0.1,
          [@hourly_dew_point_temp + hash_of_ranges[:dew_point_range] * 0.1, hourly_temp].min, #upwardly constrained by adjusted temp
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_T_and_Td_down_10 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          hourly_temp = @hourly_temp - hash_of_ranges[:temp_range] * 0.1,
          [@hourly_dew_point_temp - hash_of_ranges[:dew_point_range] * 0.1, hourly_temp].min, #upwardly constrained by adjusted temp
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_T_up_5_and_Td_down_5 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          @hourly_temp + hash_of_ranges[:temp_range] * 0.05,
          @hourly_dew_point_temp - hash_of_ranges[:dew_point_range] * 0.05,
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_T_up_10_and_Td_down_10 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          @hourly_temp + hash_of_ranges[:temp_range] * 0.1,
          @hourly_dew_point_temp - hash_of_ranges[:dew_point_range] * 0.1,
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_T_down_5_and_Td_up_5 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          hourly_temp = @hourly_temp - hash_of_ranges[:temp_range] * 0.05,
          [@hourly_dew_point_temp + hash_of_ranges[:dew_point_range] * 0.05, hourly_temp].min, #dew point upwardly constrained by adjusted temp
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
  @et0_T_down_10_and_Td_up_10 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          hourly_temp = @hourly_temp - hash_of_ranges[:temp_range] * 0.1,
          [@hourly_dew_point_temp + hash_of_ranges[:dew_point_range] * 0.1, hourly_temp].min, #dew point upwardly constrained by adjusted temp
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
end

station_data_array = CSV.read("station_data.csv")
filenames = Dir.glob('../tmy3_files_reduced_for_PM/*')
filenames.sort.each do |filename|
  start_time = Time.now
  current_tmy3_file = CSV.read(filename)
  collect_station_characteristics(current_tmy3_file)
  create_new_csv_file_populate_and_close(current_tmy3_file, station_data_array) unless invalid?(@state, @elevation)
  end_time = Time.now
  elapsed_time = end_time - start_time
  puts "Elapsed time: #{elapsed_time} seconds."
end
