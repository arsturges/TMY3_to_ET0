# This file computes the reference evapotranspiration with the Penman-Montheith equation 
# as outlined in FAO 56: 
# http://www.fao.org/docrep/X0490E/x0490e00.htm

require 'date'

def compute_atmospheric_pressure(elevation)
  #equation 7
  #elevation units are meters; atmospheric_pressure units are kPa
  atmospheric_pressure = 101.3 * ((293 - (0.0065 * elevation)) / 293)**5.26
end

def compute_gamma(atmospheric_pressure) 
  # equation 8
  # psychrometric constant; atmospheric_pressure in kPa
  _Cp = 0.00103 # kPa
  _sigma = 0.622 # unitless ratio
  _lambda = 2.45 # MJ/kg
  gamma = atmospheric_pressure * _Cp / (_sigma * _lambda) #kPa/degree Celsius
end

#equation 9: not used for hourly measurements
#equation 10: relative humidity is not used; we derive ea from dew point instead

def compute_es(_T)
  #equation 11
  #t units are celsius, es units are kPa
  es = 0.6108 * Math.exp((17.27 * _T) / (_T + 237.3))
end

#equation 12: not used for hourly measurements

def compute_Delta(_T)
  #equation 13
  #kPa/C
  _Delta = 4098 * (0.6108 * Math.exp(17.27 * _T / (_T + 237.3))) / (_T + 237.3) ** 2
end

def compute_ea(dew_point)
  #equation 14
  ea = 0.6108 * Math.exp((17.27 * dew_point) / (dew_point + 237.3))
end

# equation 15: not used (we use equation 14 instead)
# equation 16: not used (it relates to equation 15)
# equation 17: not used (it calculates ea with RH; we do it with equation 14 instead)
# equation 18: not used (relates to equation 17)
# equation 19: not used (relates to equation 17)
# equation 20: not used (related ET to radiation)
# equation 21: not used (computes Ra for daily period; we use hourly period instead--equation 28)
# equation 22: not used (converts radians to decimal degrees)

def compute_dr(day_of_the_year)
  #equation 23
  #inverse relative distance Earth-Sun
  dr = 1 + 0.033 * Math.cos((2 * Math::PI/365) * day_of_the_year)
end

def compute_solar_declination(number_of_day_in_year)
  #equation 24
  #this returns an angle in radians, oscillating between +/-0.4 rads (+/- 22 degrees)
  solar_declination = 0.409 * Math.sin((2 * Math::PI / 365) * number_of_day_in_year - 1.39)
end

def compute_sunset_hour_angle(latitude, solar_declination)
  #equation 25
  latitude = latitude * Math::PI / 180 #convert degrees to radians
  sunset_hour_angle = Math.acos(-Math.tan(latitude) * Math.tan(solar_declination))
  #note that arccos can only accept values between +/-1 rads; if latitude exceeds 68, this may be violated. United States upper boundary is at lat. 48.
end

# equation 26: not used (alternative to equation 25 using arctan instead of arccos)
# equation 27: not used (relates to equation 26)

def compute_Ra(dr, solar_declination, latitude, solar_time_angle_start, solar_time_angle_end)
  #equation 28
  solar_constant = 0.0820 #MJ/m2day
  _Ra = ((12*60)/Math::PI) * 
    solar_constant * 
    dr * 
    ((solar_time_angle_end - solar_time_angle_start) * 
    Math.sin(latitude) * 
    Math.sin(solar_declination) + 
    Math.cos(latitude) * 
    Math.cos(solar_declination) *
    (Math.sin(solar_time_angle_end) - Math.sin(solar_time_angle_start)))
end

def compute_solar_time_angle_start(solar_time_angle_midpoint, t1 = 1)
  # equation 29
  solar_time_angle_start = solar_time_angle_midpoint - ((Math::PI * t1) / 24)
end

def compute_solar_time_angle_end(solar_time_angle_midpoint, t1 = 1)
  # equation 30
  solar_time_angle_end = solar_time_angle_midpoint + ((Math::PI * t1) / 24)
end

def compute_solar_time_angle_midpoint(time, _Lz, longitude, _Sc)
  # equation 31
  solar_time_angle_midpoint = (Math::PI / 12) * ((time + 0.06667 * (_Lz - longitude)) - 12)
  #time is standard clock time at the midpoint of the period (hour), e.g. 2pm--3pm would be 14.5
  #_Lz is longitude of the center of the local time zone (degrees west of Greenwich)
  #longitude is of measurement site
  #_Sc is seasonal correction for solar time (hour)
end

def compute_Lz(hours_from_Greenwich)
  # See equation 31.
  # Returns the longitude of the center of the time zone. 
  case hours_from_Greenwich.to_i
    when -5 then _Lz = 75
    when -6 then _Lz = 90
    when -7 then _Lz = 105
    when -8 then _Lz = 120
  end
end

def compute_Sc(day_in_year)
  # equation 33
  b = 2 * Math::PI * (day_in_year - 81) / 364

  # equation 32
  _Sc = 0.1645 * Math.sin(2 * b) - 0.1255 * Math.cos(b) - 0.025 * Math.sin(b)
end

# equation 34: not used (computes N, daylight hours in 24-hour period; not used for hourly time steps)
# equation 35: not used (_Rs is measured, not calculated)
# equation 36: not used (alternative to equation 37)

def compute_Rso(_Ra, elevation)
  # equation 37
  # solar radiation that would reach surface under cloudless conditions
  #TODO: calibrate a and b for each station?
  _Rso = (0.75 + 2 * (10**(-5) * elevation )) * _Ra
end

def compute_Rns(_Rs, albedo=0.23)
  # equation 38
  # albedo is 0.23 for hypothetical grass reference crop (dimensionless)
  _Rns = (1 - albedo) * _Rs
end

def compute_Rnl(_T, ea, cloud_cover)
  # equation 39
  stefan_boltzmann=(4.903/24) * 10**(-9) #MJ/m2-hour
  t_hr_k4 = (_T + 273.16)**4
  # if it's daytime, use current _Rs/_Rso
  # if it's pre-sunset or after, use the pre-sunset _Rs/Rso
  _Rnl = stefan_boltzmann * t_hr_k4 * (0.34 - 0.14 * Math.sqrt(ea)) * (1.35 * (cloud_cover) - 0.35)
  # See note about calculating Rnl with hourly vs. daily time steps in chapter 4, below equation 54.
  
  # Since the ratio Rs/Rso is used to represent cloud cover, when calculating Rnl for hourly periods during the nighttime, 
  # the ratio Rs/Rso can be set equal to the Rs/Rso calculated for a time period occurring 2-3 hours before sunset, 
  # before the sun angle becomes small. 
  # This will generally serve as a good approximation of cloudiness occurring during the subsequent nighttime. 
  # The hourly period that is 2 to 3 hours before sunset can be identified during computation of Ra as the period where w, 
  # calculated from Equation 31, is within the range (w s - 0.79) < w < (w s - 0.52), where w s is calculated using Equation 25. 
  # As a more approximate alternative, one can assume Rs/Rso = 0.4 to 0.6 during nighttime periods in humid and subhumid climates 
  # and Rs/Rso = 0.7 to 0.8 in arid and semiarid climates. 
  # A value of Rs/Rso = 0.3 presumes total cloud cover.
end

def compute_cloud_cover(_Rs, _Rso, day, hour, it_is_a_few_hours_before_sunset, global_horizontal_irradiance, pre_sunset_cloud_cover)
  if day == 1 and global_horizontal_irradiance == 0 and hour < 15 # because months aren't actually chronological 
    cloud_cover = 0.65 # average suggested nighttime value (starting at midnight)
  elsif it_is_a_few_hours_before_sunset or global_horizontal_irradiance == 0
    cloud_cover = (_Rs / _Rso) # pre_sunset_cloud_cover
  else # daytime
    cloud_cover = (_Rs / _Rso)
  end
end

def it_is_a_few_hours_before_sunset(solar_time_angle_midpoint, sunset_hour_angle)
  condition_1 = (sunset_hour_angle - 0.79) <= solar_time_angle_midpoint
  condition_2 = solar_time_angle_midpoint <= (sunset_hour_angle - 0.52)
  if condition_1 and condition_2
    return true
  else
    return false
  end
end

def compute_Rn(_Rns, _Rnl)
  # equation 40
  _Rn = _Rns - _Rnl
end

# equation 41: not used (relates to G for longer time steps)
# equation 42: not used (relates to G for longer time steps)
# equation 43: not used (relates to G for longer time steps)
# equation 44: not used (relates to G for longer time steps)

def compute_G(direct_normal_irradiance, _Rn)
  # we define "daytime" as any period when sun is shining.
  if direct_normal_irradiance > 0
    period_of_day = "daytime"
  else
    period_of_day = "nighttime"
  end

  case period_of_day
    when "daytime" then _G = 0.1 * _Rn #equation 45
    when "nighttime" then _G = 0.5 * _Rn #equation 46
  end
end

def compute_day_in_year(month, day)
  day_in_year = Date.new(2011, month, day).yday #because 2011 is not a leap year, and February 29 does not ever appear in TMY3
end

def compute_hourly_et0(state, 
                        subregion, 
                        hours_from_Greenwich,
                        elevation,
                        longitude,
                        latitude,
                        month,
                        day,
                        hour,
                        temp_hr,
                        dew_point,
                        wind_speed,
                        global_horizontal_irradiance,
                        direct_normal_irradiance)
  # equation 53

  solar_declination = compute_solar_declination(compute_day_in_year(month, day))
  sunset_hour_angle = compute_sunset_hour_angle(latitude, solar_declination)
  dr = compute_dr(compute_day_in_year(month, day))
  _Lz = compute_Lz(hours_from_Greenwich)
  _Sc = compute_Sc(compute_day_in_year(month, day))
  solar_time_angle_midpoint = compute_solar_time_angle_midpoint(hour + 0.5, _Lz, longitude, _Sc)
  solar_time_angle_start = compute_solar_time_angle_start(solar_time_angle_midpoint)
  solar_time_angle_end = compute_solar_time_angle_end(solar_time_angle_midpoint)
  _Ra = compute_Ra(dr, solar_declination, latitude, solar_time_angle_start, solar_time_angle_end)
  _Rso = compute_Rso(_Ra, elevation)
  _Rs = global_horizontal_irradiance * (60 * 60) / (10**6) #convert W/m2 to MJ/hour/m2
  _Rns = compute_Rns(_Rs)
  _T = temp_hr
  _ea = compute_ea(dew_point)
  it_is_a_few_hours_before_sunset = it_is_a_few_hours_before_sunset(solar_time_angle_midpoint, sunset_hour_angle)
  pre_sunset_cloud_cover = 0.5
  cloud_cover = compute_cloud_cover(_Rs, _Rso, day, hour, it_is_a_few_hours_before_sunset, global_horizontal_irradiance, pre_sunset_cloud_cover)
  _Rnl = compute_Rnl(_T, _ea, cloud_cover)
  atmospheric_pressure = compute_atmospheric_pressure(elevation)

  _Rn = compute_Rn(_Rns, _Rnl)
  _G = compute_G(direct_normal_irradiance, _Rn)
  _gamma = compute_gamma(atmospheric_pressure)
  _Delta = compute_Delta(_T)
  _u2 = wind_speed
  _es = compute_es(_T)

  et0_numerator = 0.408 * (_Delta) * (_Rn - _G) + _gamma*(37/(_T+273)) * _u2 * (_es - _ea)
  et0_denominator = _Delta + _gamma * (1 + 0.34 * _u2)
  et0 = et0_numerator / et0_denominator
end
