require 'date'
require './penman-monteith_common.rb'

def compute_Rnl_hourly(_T, ea, _Rs, _Rso)
  # equation 39
  stefan_boltzmann=(4.903/24) * 10**(-9) #MJ/m2-hour
  t_hr_k4 = (_T + 273.16)**4
  _Rnl = stefan_boltzmann * t_hr_k4 * (0.34 - 0.14 * Math.sqrt(ea)) * (1.35 * (_Rs / _Rso) - 0.35)
  #see note about calculating Rnl with hourly vs. daily time steps in chapter 4.
end

def compute_Ra_hourly(dr, solar_declination, latitude, solar_time_angle_start, solar_time_angle_end)
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

def compute_is_sun_shining(direct_normal_irradiance)
  direct_normal_irradiance > 120 ? 1 : 0
end

def compute_day_in_year(month, day)
  day_in_year = Date.new(2011, month, day).yday #because 2011 is not a leap year, and February 29 does not ever appear in TMY3
end

def compute_Lz(hours_from_Greenwich)
  #returns the longitude of the center of the time zone. See equation 31.
  case hours_from_Greenwich.to_i
    when -5 then _Lz = 75
    when -6 then _Lz = 90
    when -7 then _Lz = 105
    when -8 then _Lz = 120
  end
end

def compute_solar_time_angle_start(solar_time_angle_midpoint, t1 = 1)
  solar_time_angle_start = solar_time_angle_midpoint - ((Math::PI * t1) / 24)
end

def compute_solar_time_angle_end(solar_time_angle_midpoint, t1 = 1)
  solar_time_angle_end = solar_time_angle_midpoint + ((Math::PI * t1) / 24)
end

def compute_solar_time_angle_midpoint(time, _Lz, longitude, _Sc)
  #equation 31
  solar_time_angle_midpoint = (Math::PI / 12) * ((time + 0.06667 * (_Lz - longitude)) - 12)
  #time is standard clock time at the midpoint of the period (hour), e.g. 2pm--3pm would be 14.5
  #_Lz is longitude of the center of the local time zone (degrees west of Greenwich)
  #longitude is of measurement site
  #_Sc is seasonal correction for solar time (hour)
end

def compute_Sc(day_in_year)
  #equation 33
  b = 2 * Math::PI * (day_in_year - 81) / 364

  #equation 32
  _Sc = 0.1645 * Math.sin(2 * b) - 0.1255 * Math.cos(b) - 0.025 * Math.sin(b)
end

def compute_G_hourly(direct_normal_irradiance, _Rn)
  # need to find what defines "daylight periods" and "nighttime"
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
  middle_day_of_the_month = 30.4 * month - 15
  solar_declination = compute_solar_declination(middle_day_of_the_month)
  sunset_hour_angle = compute_sunset_hour_angle(latitude, solar_declination)
  dr = compute_dr(middle_day_of_the_month)
  n = compute_is_sun_shining(direct_normal_irradiance)
  _Lz = compute_Lz(hours_from_Greenwich)
  _Sc = compute_Sc(compute_day_in_year(month, day))
  solar_time_angle_midpoint = compute_solar_time_angle_midpoint(hour + 0.5, _Lz, longitude, _Sc)
  solar_time_angle_start = compute_solar_time_angle_start(solar_time_angle_midpoint)
  solar_time_angle_end = compute_solar_time_angle_end(solar_time_angle_midpoint)
  _Ra = compute_Ra_hourly(dr, solar_declination, latitude, solar_time_angle_start, solar_time_angle_end)
  _Rso = compute_Rso(_Ra, elevation)
  _N = compute_N(sunset_hour_angle)
  #_Rs = compute_Rs_hourly(n, _N, _Ra)
  _Rs = global_horizontal_irradiance * (60 * 60) / (10**6) #convert W/m2 to MJ/hour/m2
  _Rns = compute_Rns(_Rs)
  _T = temp_hr
  _Rnl = compute_Rnl_hourly(_T, compute_ea(dew_point), _Rs, _Rso)
  atmospheric_pressure = compute_atmospheric_pressure(elevation)

  _Rn = compute_Rn(_Rns, _Rnl)
  _G = compute_G_hourly(direct_normal_irradiance, _Rn)
  _gamma = compute_gamma(atmospheric_pressure)
  _Delta = compute_Delta(_T)
  _u2 = wind_speed
  _es = compute_es(_T)
  _ea = compute_ea(dew_point)

  et0_numerator = 0.408 * (_Delta) * (_Rn - _G) + _gamma*(37/(_T+273)) * _u2 * (_es - _ea)
  et0_denominator = _Delta + _gamma * (1 + 0.34 * _u2)
  et0 = et0_numerator / et0_denominator
end

#puts compute_hourly_et0("AL",
                         #"none",
                         #-6,
                         #120.571428571429,
                         #90.1111111111111,
                         #32.6225714285714,
                         #1,
                         #15,
                         #18,
                         #12.4140552995392,
                         #1.82115015360983,
                         #3.06410330261137,
                         #280, #W/m2
                         #680, #W/m2
                         #13.6566820276498,
                         #2.30092165898618) 
