# load the data set:
hourly <- read.csv("~/TMY3_to_ET0/hourly.csv")

#plot a histogram of all temperatures:
hist(hourly$temperature_.C.)

#plot a histogram of daytime temps, then nighttime temps:
hist(hourly$temperature_.C.[hourly$direct_normal_irradiance_.W.m2. > 0])
> hist(hourly$temperature_.C.[hourly$direct_normal_irradiance_.W.m2. == 0])

