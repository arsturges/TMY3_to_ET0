#these are methods to read TMY3 files and produce daily output.
# The needed values are:
# t_max (maximum temp over the 24-hour period)
# t_min (minimum temp over the 24-hour period)
# t_dew 
# wind_speed (average for 24 hours of wind speed)
# G (daily heat flux) may be ignored for 24-hour time steps
# n (actual hours of sunshine in the 24-hour period)
require 'date'
require './TMY3_common.rb'

