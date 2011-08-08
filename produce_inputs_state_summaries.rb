require 'csv'
require './TMY3.rb'

filenames = Dir.glob('../tmy3_files_reduced_for_PM/*')
states = Hash.new
filenames.sort.each do |filename|
  puts "reading file #{filename}"
  current_file = CSV.read(filename)
  header1 = current_file.shift
  header2 = current_file.shift
  state = header1[2]
  states[state] ||= {}
  current_file.each do |station_row|
    month = station_row[0].to_i
    day = station_row[1].to_i
    hour = station_row[2].to_i

    states[state][month] ||= {}
    states[state][month][day] ||= {}
    states[state][month][day][hour] ||= {}
    states[state][month][day][hour]["ghi"] ||= []
    states[state][month][day][hour]["dni"] ||= []
    states[state][month][day][hour]["cloud_cover"] ||= []
    states[state][month][day][hour]["temp"] ||= []
    states[state][month][day][hour]["dew_temp"] ||= []
    states[state][month][day][hour]["wind_speed"] ||= []
    states[state][month][day][hour]["precip"] ||= []

    states[state][month][day][hour]["ghi"] << station_row[3].to_f 
    states[state][month][day][hour]["dni"] << station_row[4].to_f
    states[state][month][day][hour]["cloud_cover"] << station_row[5].to_f
    states[state][month][day][hour]["temp"] << station_row[6].to_f
    states[state][month][day][hour]["dew_temp"] << station_row[7].to_f
    states[state][month][day][hour]["wind_speed"] << station_row[8].to_f
    states[state][month][day][hour]["precip"] << station_row[9].to_f
  end
end

states.keys.sort.each do |state|
  puts "writing file #{state}.csv"
  CSV.open("../tmy3_inputs_state_summaries/#{state}.csv", "wb") do |row|
    row << [
      "month","day","hour",
      "GHI",
      "DNI",
      "cloud_cover",
      "temp",
      "dew_temp",
      "wind_speed",
      "precip"
    ]

    (1..12).each do |month|
      (1..days_in_month(month)).each do |day|
        (0..23).each do |hour|

          row << [
            month,
            day,
            hour,
            sum(states[state][month][day][hour]["ghi"])/states[state][month][day][hour]["ghi"].size,
            sum(states[state][month][day][hour]["dni"])/states[state][month][day][hour]["ghi"].size,
            sum(states[state][month][day][hour]["cloud_cover"])/states[state][month][day][hour]["ghi"].size,
            sum(states[state][month][day][hour]["temp"])/states[state][month][day][hour]["ghi"].size,
            sum(states[state][month][day][hour]["dew_temp"])/states[state][month][day][hour]["ghi"].size,
            sum(states[state][month][day][hour]["wind_speed"])/states[state][month][day][hour]["ghi"].size,
            sum(states[state][month][day][hour]["precip"])/states[state][month][day][hour]["ghi"].size
          ]
        end
      end
    end
  end
end
