require 'rubygems'
require 'numru/netcdf'
require 'csv'

#files:
doubling = "../NOAA_CM2.1_NetCDF_files/1%_tas_A1.020101-022012.nc"
sresa2 = "../NOAA_CM2.1_NetCDF_files/SRESA2_tas_A1.200101-210012.nc"

file = NumRu::NetCDF.open(sresa2)
# Goal: return tas data for just North America. 
# This means I should limit all data to lon/lat box of:
# NW corner: Latitude 50, longitude -125 (longitude +235)
# SE corner: Lattidue 25, longitude -67 (longitude +293)
tas_data = Array.new
sum_of_temperatures = 0
western_longitude_boundary = 95
eastern_longitude_boundary = 113
southern_latitude_boundary = 60
northern_latitude_boundary = 68
total_number_of_geographic_points = (eastern_longitude_boundary - western_longitude_boundary + 1)*(northern_latitude_boundary - southern_latitude_boundary + 1)
tas_data = Array.new
number_of_months = file.var("time").shape_current[0] - 1

(0..number_of_months).each do |month|
  (western_longitude_boundary..eastern_longitude_boundary).each do |longitude|
    (southern_latitude_boundary..northern_latitude_boundary).each do |latitude|
      sum_of_temperatures = sum_of_temperatures + file.var("tas").get[longitude, latitude, month]
      if latitude == northern_latitude_boundary && longitude == eastern_longitude_boundary
	tas_data[month] = sum_of_temperatures/total_number_of_geographic_points
	sum_of_temperatures = 0
        puts "Month=#{month} out of #{number_of_months}"
      end
    end
  end
end

puts tas_data

CSV.open("tas_SRESA2.csv", "w") do |write_new_row|
  tas_data.each do |row|
    write_new_row << [row]
  end
end
