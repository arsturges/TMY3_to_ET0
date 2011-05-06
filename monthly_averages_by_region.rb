require 'rubygems'
require 'numru/netcdf'
require 'csv'
tas_co2_doubling = NumRu::NetCDF.open("../Downloads/tas_A1.020101-022012.nc")
# Goal: return tas data for just North America. 
# This means I should limit all data to lon/lat box of:
# NW corner: Latitude 50, longitude -125 (longitude +235)
# SE corner: Lattidue 25, longitude -67 (longitude +293)
geographic_point_total = 0
western_longitude_boundary = 112#95
eastern_longitude_boundary = 113
southern_latitude_boundary = 67#60
northern_latitude_boundary = 68
total_number_of_geographic_points = (eastern_longitude_boundary - western_longitude_boundary + 1)*(northern_latitude_boundary - southern_latitude_boundary + 1)
tas_data = Array.new
(0..4).each do |month|
  (western_longitude_boundary..eastern_longitude_boundary).each do |longitude|
    (southern_latitude_boundary..northern_latitude_boundary).each do |latitude|
      (1..total_number_of_geographic_points).each do |geographic_point|
        geographic_point_total = geographic_point_total + tas_co2_doubling.var("tas").get[longitude, latitude, month]
        if geographic_point == total_number_of_geographic_points
          tas_data[month] = geographic_point_total/total_number_of_geographic_points
          geographic_point_total = 0
        end

        puts "longitude = #{longitude}"
        puts "latitude = #{latitude}"
        puts "month = #{month}"
      end
    end
  end
end
puts tas_data
