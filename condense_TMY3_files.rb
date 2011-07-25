require 'csv'
require './penman-monteith.rb'

def collect_station_characteristics(tmy3_array)
  @header1 = tmy3_array.shift
  @header2 = tmy3_array.shift #remove column headers
  
  #read basic info about the weather station  
  @state = @header1[2]
  @time_zone = @header1[3]
  @subregion = nil
  @latitude =  @header1[4].to_f.abs
  @longitude = @header1[5].to_f.abs
  @elevation = @header1[6].to_i
end

def create_new_csv_file_populate_and_close(array)
  new_file_name = @header1[0]
  puts new_file_name
  CSV.open("../tmy3_files_reduced_for_PM_equation/#{new_file_name}.csv", "wb") do |new_row|
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
      "et0_T_and_Td_-10%"]
    array.each do |row| #Loop through each row. Each row is one hour; 24 rows per day.
      read_hourly_data(row[0], row[1], row[4], row[7], row[25], row[31], row[34], row[46], row[64])
      generate_time_variables(@row_date, @row_hour)

      compute_et0_perturbations
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
          @hourly_sky_coverage),
        @et0_T_up_5,
        @et0_T_down_5, 
        @et0_T_up_10,
        @et0_T_down_10,
        @et0_Td_up_5,
        @et0_Td_down_5,
        @et0_Td_up_10,
        @et0_Td_down_10,
        @et0_T_and_Td_up_5,
        @et0_T_and_Td_down_5,
        @et0_T_and_Td_up_10,
        @et0_T_and_Td_down_10]
    end
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
  @hourly_precipitation = row64.to_f unless row64.to_f == -9900
end

def generate_time_variables(date, time)
  @current_row_datetime = DateTime.strptime(@row_date +" "+@row_hour, '%m/%d/%Y %H:%M') - 1/(24.0*60) #subtract 1 hr because DateTime puts "24:00" in the next day as "00:00"
  @year = @current_row_datetime.year
  @month = @current_row_datetime.month
  @day = @current_row_datetime.day
  @hour = @current_row_datetime.hour #spans 0..23
end

def compute_et0_perturbations
  @et0_T_up_5 = compute_hourly_et0(
          @time_zone,
          @elevation,
          @longitude,
          @latitude,
          @month,
          @day,
          @hour,
          @hourly_temp + (@hourly_temp * 0.05).abs,
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
          @hourly_temp - (@hourly_temp * 0.05).abs,
          @hourly_dew_point_temp,
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
          @hourly_temp + (@hourly_temp * 0.1).abs,
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
          @hourly_temp - (@hourly_temp * 0.1).abs,
          @hourly_dew_point_temp,
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
          @hourly_dew_point_temp + (@hourly_dew_point_temp * 0.05).abs,
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
          @hourly_dew_point_temp - (@hourly_dew_point_temp * 0.05).abs,
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
          @hourly_dew_point_temp + (@hourly_dew_point_temp * 0.1).abs,
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
          @hourly_dew_point_temp - (@hourly_dew_point_temp * 0.1).abs,
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
          @hourly_temp + (@hourly_temp * 0.05).abs,
          @hourly_dew_point_temp + (@hourly_dew_point_temp * 0.05).abs,
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
          @hourly_temp + (@hourly_temp * 0.05).abs,
          @hourly_dew_point_temp - (@hourly_dew_point_temp * 0.05).abs,
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
          @hourly_temp + (@hourly_temp * 0.05).abs,
          @hourly_dew_point_temp + (@hourly_dew_point_temp * 0.1).abs,
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
          @hourly_temp + (@hourly_temp * 0.05).abs,
          @hourly_dew_point_temp - (@hourly_dew_point_temp * 0.1).abs,
          @hourly_wind_speed,
          @hourly_global_horizontal_irradiance,
          @hourly_direct_normal_irradiance,
          @hourly_sky_coverage)
end

filenames = Dir.glob('../tmy3_test_files/*')
filenames.sort.each do |filename|
  start_time = Time.now
  current_tmy3_file = CSV.read(filename)
  collect_station_characteristics(current_tmy3_file)
  create_new_csv_file_populate_and_close(current_tmy3_file)
  end_time = Time.now
  elapsed_time = end_time - start_time
  puts "Elapsed time: #{elapsed_time} seconds."
end
