# This file runs in R, the free and open source project for statistical computing.
# For more information on R, see http://www.r-project.org/

# Run this file from within an R command line session with the following command:
# source("temp_distribution.r")

# load the hourly data sets:
print("loading hourly_base.csv...")
#base <- read.csv("~/TMY3_to_ET0/hourly_base.csv")
print("loading hourly_temp_+2%.csv...")
#plus_2_temp <- read.csv("~/TMY3_to_ET0/hourly_temp_+2%.csv")
print("loading hourly_temp_+5%.csv...")
#plus_5_temp <- read.csv("~/TMY3_to_ET0/hourly_temp_+5%.csv")
print("loading hourly_temp_-5%.csv...")
#minus_5_temp <- read.csv("~/TMY3_to_ET0/hourly_temp_-5%.csv")
print("loading hourly_humidity_+2%.csv...")
#plus_2_humid <- read.csv("~/TMY3_to_ET0/hourly_humidity_+2%.csv")
print("loading hourly_humidity_+5%.csv...")
#plus_5_humid <- read.csv("~/TMY3_to_ET0/hourly_humidity_+5%.csv")

# plot a histogram of all temperatures:
hist(base$temperature)

# plot a histogram of daytime temps, then nighttime temps:
hist(base$temperature[base$direct_normal_irradiance > 0]) #daytime
hist(base$temperature[base$direct_normal_irradiance == 0]) #nighttime

# Calculate delta ET0/delta T:
(mean(base$et0_from_et0s)-mean(plus_2$et0_from_et0s))/(mean(base$temperature)-mean(plus_2$temperature))

coefficient_of_temperature_variation <- function(data_set_1, data_set_2) {
  delta_et0 = mean(data_set_1$et0_from_et0s) - mean(data_set_2$et0_from_et0s)
  delta_t = mean(data_set_1$temperature) - mean(data_set_2$temperature)
  coefficient_of_variation = delta_et0 / delta_t
  return(coefficient_of_variation)
}

coefficient_of_dew_point_variation <- function(data_set_1, data_set_2) {
  delta_et0 = mean(data_set_1$et0_from_et0s) - mean(data_set_2$et0_from_et0s)
  delta_dew_point = mean(data_set_1$dew_point) - mean(data_set_2$dew_point)
  coefficient_of_dew_point_variation = delta_et0 / delta_dew_point
  return(coefficient_of_dew_point_variation)
}
# Print coefficients of variation on temperature
print(coefficient_of_temperature_variation(minus_5_temp, base))
print(coefficient_of_temperature_variation(minus_5_temp, plus_2_temp))
print(coefficient_of_temperature_variation(minus_5_temp, plus_5_temp))
print(coefficient_of_temperature_variation(base, plus_2_temp))
print(coefficient_of_temperature_variation(base, plus_5_temp))
print(coefficient_of_temperature_variation(base, minus_5_temp))
print(coefficient_of_variation(plus_2_temp, plus_5_temp))

# Pring coefficients of variation on humiditiy
print(coefficient_of_humidity_variation(base, plus_2_humid))
print(coefficient_of_humidity_variation(base, plus_5_humid))
print(coefficient_of_humidity_variation(plus_2_humid, plus_5_humid))
