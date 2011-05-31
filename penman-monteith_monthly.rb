# This file performs the Penman-Monteith equation for monthly time steps.

def compute_atmospheric_pressure(elevation)
  #table 2.1
  #http://www.fao.org/docrep/X0490E/x0490e0j.htm#annex 2. meteorological tables
  #elevation units are meters; atmospheric_pressure units are kPa
  atmospheric_pressure = 101.3 * ((293 - (0.0065 * elevation)) / 293)**5.26
end

def compute_gamma(atmospheric_pressure) 
  # table 2.2
  # psychrometric constant; atmospheric_pressure in kPa
  # http://www.fao.org/docrep/X0490E/x0490e0j.htm#annex 2. meteorological tables
  _Cp = 0.00103 # kPa
  _sigma = 0.622 # unitless ratio
  _lambda = 2.45 # MJ/kg
  gamma = atmospheric_pressure * _Cp / (_sigma * _lambda) #kPa/degree Celsius
end

def compute_es(t_max, t_min)
  #table 2.3, equation 11
  #this averages together e(t_max) and e(t_min) to get es. This is for monthly time-step. 
  #For hourly, may have to simplify this and do the averaging outside the method.
  #http://www.fao.org/docrep/X0490E/x0490e0j.htm#annex 2. meteorological tables
  #t units are celsius, es units are kPa
  e_of_t_max = 0.6108 * Math.exp((17.27 * t_max) / (t_max + 237.3))
  e_of_t_min = 0.6108 * Math.exp((17.27 * t_min) / (t_min + 237.3))
  es = (e_of_t_max + e_of_t_min) / 2
end

def compute_ea(t_dew)
  #equation 14
  ea = 0.6108 * Math.exp((17.27 * t_dew) / (t_dew + 237.3))
end

def compute_Rnl(t_max, t_min, ea, _Rs, _Rso)
  # equation 39
  stefan_boltzmann=4.903 * 10**(-9)
  t_max_k4 = (t_max + 273.16)**4
  t_min_k4 = (t_min + 273.16)**4
  _Rnl = stefan_boltzmann * ((t_max_k4 + t_min_k4) / 2) * (0.34 - 0.14 * Math.sqrt(ea)) * (1.35 * (_Rs / _Rso) - 0.35)
end

def compute_Rn(_Rns, _Rnl)
  # equation 40
  _Rn = _Rns - _Rnl
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

def compute_N(sunset_hour_angle)
  #equation 34
  #angle needs to be in radians
  _N = (24/Math::PI) * sunset_hour_angle
end

def compute_Rs(n, _N, _Ra, as=0.25, bs=0.5)
  #equation 35
  _Rs = (as + bs * (n/_N)) * _Ra
end

def compute_dr(day_of_the_year)
  dr = 1 + 0.033 * Math.cos((2 * Math::PI/365) * day_of_the_year)
end

def compute_Ra(dr, latitude, solar_declination, sunset_hour_angle)
  #equation 21
  #NB: this is not suitable for hour-level time detail; just daily and monthly
  solar_constant = 0.0820 #MJ/m2day
  latitude = latitude * Math::PI / 180 #convert degrees to radians
  _Ra = (24*60/Math::PI) * 
    solar_constant * 
    dr * 
    (sunset_hour_angle * 
     Math.sin(latitude) * 
     Math.sin(solar_declination) + 
     Math.cos(latitude) * 
     Math.cos(solar_declination) * 
     Math.sin(sunset_hour_angle))
end

def compute_Rso(_Ra, elevation)
  #equation 36
  _Rso = (0.75 + 2 * (elevation / 100000)) * _Ra
end

def compute_Rns(_Rs, albedo=0.23)
  #equation 38
  _Rns = (1 - albedo) * _Rs
end

def compute_Delta(_T)
  #equation 13
  #kPa/C
  _Delta = 4098 * (0.6108 * Math.exp(17.27 * _T / (_T + 237.3))) / (_T + 237.3) ** 2
end

def compute_G(t_max, t_min, t_max_previous, t_min_previous)
  #equation 44
  t_mean = (t_max + t_min) / 2
  t_mean_previous = (t_max_previous + t_min_previous) / 2
  _G = 0.14 * (t_mean - t_mean_previous)
end

#state = "AL"
#subregion = "none"
#elevation = 120.571428571429
#latitude = 32.6225714285714
#month = 1
#t_max = 12.4140552995392
#t_min = 1.67557603686636
#t_dew = 1.82115015360983
#wind_speed = 3.06410330261137
#hours_of_daylight = 5.38940092165899
#t_max_previous = 13.6566820276498
#t_min_previous = 2.30092165898618

def compute_monthly_et0(state, subregion, elevation, latitude, month, t_max, t_min, t_dew, wind_speed, hours_of_daylight, t_max_previous, t_min_previous)
  middle_day_of_the_month = 30.4 * month - 15
  solar_declination = compute_solar_declination(middle_day_of_the_month)
  sunset_hour_angle = compute_sunset_hour_angle(latitude, solar_declination)
  dr = compute_dr(middle_day_of_the_month)
  _Ra = compute_Ra(dr, latitude, solar_declination, sunset_hour_angle)
  _Rso = compute_Rso(_Ra, elevation)
  _N = compute_N(sunset_hour_angle)
  _Rs = compute_Rs(hours_of_daylight, _N, _Ra)
  _Rns = compute_Rns(_Rs)
  _Rnl = compute_Rnl(t_max, t_min, compute_ea(t_dew), _Rs, _Rso)
  atmospheric_pressure = compute_atmospheric_pressure(elevation)

  _Rn = compute_Rn(_Rns, _Rnl)
  _G = compute_G(t_max, t_min, t_max_previous, t_min_previous)
  _gamma = compute_gamma(atmospheric_pressure)
  _T = (t_min + t_max) / 2
  _Delta = compute_Delta(_T)
  _u2 = wind_speed
  _es = compute_es(t_max, t_min)
  _ea = compute_ea(t_dew)

  et0_numerator = 0.408 * (_Delta) * (_Rn - _G) + _gamma*(900/(_T+273)) * _u2 * (_es - _ea)
  et0_denominator = _Delta + _gamma * (1 + 0.34 * _u2)
  et0 = et0_numerator / et0_denominator
  puts et0 
end

puts compute_monthly_et0("AL", 
                         "none",
                         120.571428571429, 
                         32.6225714285714, 
                         1, 
                         12.4140552995392, 
                         1.67557603686636, 
                         1.82115015360983, 
                         3.06410330261137, 
                         5.38940092165899,
                         13.6566820276498, 
                         2.30092165898618) 
