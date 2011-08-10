require 'csv'
require './TMY3.rb'

filenames = Dir.glob('../tmy3_files_reduced_for_PM_with_perturbations/*')
#filenames = Dir.glob('../tmy3_test_files/*')
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
    states[state][month][day][hour]["et0_base"] ||= []
    states[state][month][day][hour]["et0_T_+5%"] ||= []
    states[state][month][day][hour]["et0_T_-5%"] ||= []
    states[state][month][day][hour]["et0_T_+10%"] ||= []
    states[state][month][day][hour]["et0_T_-10%"] ||= []
    states[state][month][day][hour]["et0_Td_+5%"] ||= []
    states[state][month][day][hour]["et0_Td_-5%"] ||= []
    states[state][month][day][hour]["et0_Td_+10%"] ||= []
    states[state][month][day][hour]["et0_Td_-10%"] ||= []
    states[state][month][day][hour]["et0_T_and_Td_+5%"] ||= []
    states[state][month][day][hour]["et0_T_and_Td_-5%"] ||= []
    states[state][month][day][hour]["et0_T_and_Td_+10%"] ||= []
    states[state][month][day][hour]["et0_T_and_Td_-10%"] ||= []

    states[state][month][day][hour]["et0_base"] << sprintf("%.3f", station_row[10].to_f)
    states[state][month][day][hour]["et0_T_+5%"] << sprintf("%.3f", station_row[11].to_f)
    states[state][month][day][hour]["et0_T_-5%"] << sprintf("%.3f", station_row[12].to_f)
    states[state][month][day][hour]["et0_T_+10%"] << sprintf("%.3f", station_row[13].to_f)
    states[state][month][day][hour]["et0_T_-10%"] << sprintf("%.3f", station_row[14].to_f)
    states[state][month][day][hour]["et0_Td_+5%"] << sprintf("%.3f", station_row[15].to_f)
    states[state][month][day][hour]["et0_Td_-5%"] << sprintf("%.3f", station_row[16].to_f)
    states[state][month][day][hour]["et0_Td_+10%"] << sprintf("%.3f", station_row[17].to_f)
    states[state][month][day][hour]["et0_Td_-10%"] << sprintf("%.3f", station_row[18].to_f)
    states[state][month][day][hour]["et0_T_and_Td_+5%"] << sprintf("%.3f", station_row[19].to_f)
    states[state][month][day][hour]["et0_T_and_Td_-5%"] << sprintf("%.3f", station_row[20].to_f)
    states[state][month][day][hour]["et0_T_and_Td_+10%"] << sprintf("%.3f", station_row[21].to_f)
    states[state][month][day][hour]["et0_T_and_Td_-10%"] << sprintf("%.3f", station_row[22].to_f)
  end
end

states.keys.sort.each do |state|
  puts "writing file #{state}.csv"
  CSV.open("../tmy3_et0_state_summaries/#{state}.csv", "wb") do |row|
    row << [
      "month","day","hour",
      "et0_base",
      "et0_T_+5%",
      "et0_T_-5%",
      "et0_T_+10%",
      "et0_T_-10%",
      "et0_Td_+5%",
      "et0_Td_-5%",
      "et0_Td_+10%",
      "et0_Td_-10%",
      "et0_T_and_Td_+5%",
      "et0_T_and_Td_-5%",
      "et0_T_and_Td_+10%",
      "et0_T_and_Td_-10%"
    ]

    (1..12).each do |month|
      (1..days_in_month(month)).each do |day|
        (0..23).each do |hour|

          row << [
            month,
            day,
            hour,
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_base"])/states[state][month][day][hour]["et0_base"].size),
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_T_+5%"])/states[state][month][day][hour]["et0_T_+5%"].size),
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_T_-5%"])/states[state][month][day][hour]["et0_T_-5%"].size),
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_T_+10%"])/states[state][month][day][hour]["et0_T_+10%"].size),
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_T_-10%"])/states[state][month][day][hour]["et0_T_-10%"].size),
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_Td_+5%"])/states[state][month][day][hour]["et0_Td_+5%"].size),
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_Td_-5%"])/states[state][month][day][hour]["et0_Td_-5%"].size),
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_Td_+10%"])/states[state][month][day][hour]["et0_Td_+10%"].size),
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_Td_-10%"])/states[state][month][day][hour]["et0_Td_-10%"].size),
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_T_and_Td_+5%"])/states[state][month][day][hour]["et0_T_and_Td_+5%"].size),
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_T_and_Td_-5%"])/states[state][month][day][hour]["et0_T_and_Td_-5%"].size),
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_T_and_Td_+10%"])/states[state][month][day][hour]["et0_T_and_Td_+10%"].size),
            sprintf("%.3f", sum(states[state][month][day][hour]["et0_T_and_Td_-10%"])/states[state][month][day][hour]["et0_T_and_Td_-10%"].size)
          ]
        end
      end
    end
  end
end
