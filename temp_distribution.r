# load the hourly data sets:
print("loading hourly_base.csv...")
#base <- read.csv("~/TMY3_to_ET0/hourly_base.csv")
print("loading hourly_+2%.csv...")
#plus_2 <- read.csv("~/TMY3_to_ET0/hourly_+2%.csv")
print("loading hourly_+5%.csv...")
#plus_5 <- read.csv("~/TMY3_to_ET0/hourly_+5%.csv")
print("loading hourly_-5%.csv...")
#minus_5 <- read.csv("~/TMY3_to_ET0/hourly_-5%.csv")

# plot a histogram of all temperatures:
hist(base$temperature)

# plot a histogram of daytime temps, then nighttime temps:
hist(base$temperature[base$direct_normal_irradiance > 0]) #daytime
hist(base$temperature[base$direct_normal_irradiance == 0]) #nighttime

# Calculate delta ET0/delta T:
(mean(base$et0_from_et0s)-mean(plus_2$et0_from_et0s))/(mean(base$temperature)-mean(plus_2$temperature))

coefficient_of_variation <- function(data_set_1, data_set_2) {
  delta_et0 = mean(data_set_1$et0_from_et0s) - mean(data_set_2$et0_from_et0s)
  delta_t = mean(data_set_1$temperature) - mean(data_set_2$temperature)
  coefficient_of_variation = delta_t / delta_et0
  return(coefficient_of_variation)
}

# going from low to high:
print(coefficient_of_variation(minus_5, base))
print(coefficient_of_variation(minus_5, plus_2))
print(coefficient_of_variation(minus_5, plus_5))
print(coefficient_of_variation(base, plus_2))
print(coefficient_of_variation(base, plus_5))
print(coefficient_of_variation(base, minus_5))
print(coefficient_of_variation(plus_2, plus_5))
