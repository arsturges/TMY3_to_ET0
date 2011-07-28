require 'csv'


filenames = Dir.glob("../tmy3_files_reduced_for_PM_equation_base_only/*")
CSV.open("station_data.csv", "wb") do |writer|
  writer << ["station_id","state","latitude","longitude","elevation","t_max","t_min","t_dew_max","t_dew_min"]

  filenames.sort.each do |filename|
    puts filename
    tmy3_data_array = CSV.read(filename)
    header1 = tmy3_data_array.shift
    header2 = tmy3_data_array.shift
    t_max = -999
    t_min = 999
    t_dew_max = -999
    t_dew_min = 999
    station_id = header1[0]
    state = header1[2]
    latitude = header1[4]
    longitude = header1[5]
    elevation = header1[6]

    tmy3_data_array.each do |row|
      t_max = row[6].to_f if row[6].to_f > t_max
      t_min = row[6].to_f if row[6].to_f < t_min
      t_dew_max = row[7].to_f if row[7].to_f > t_dew_max
      t_dew_min= row[8].to_f if row[7].to_f < t_dew_max
    end

    writer << [
      station_id,
      state,
      latitude,
      longitude,
      elevation,
      t_max,
      t_min,
      t_dew_max,
      t_dew_min]
  end
end
