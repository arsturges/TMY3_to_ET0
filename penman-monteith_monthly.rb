# This file performs the Penman-Monteith equation for monthly time steps.
require 'date'
require './penman-monteith_common.rb'

def compute_Rnl_monthly(t_max, t_min, ea, _Rs, _Rso)
  # equation 39
  stefan_boltzmann=4.903 * 10**(-9) #MJ/m2-hour
  t_max_k4 = (t_max + 273.16)**4
  t_min_k4 = (t_min + 273.16)**4
  _Rnl = stefan_boltzmann * ((t_max_k4 + t_min_k4) / 2) * (0.34 - 0.14 * Math.sqrt(ea)) * (1.35 * (_Rs / _Rso) - 0.35)
end

def compute_Rs_monthly(n, _N, _Ra, as=0.25, bs=0.5)
  #equation 35
  _Rs = (as + bs * (n/_N)) * _Ra
end

def compute_Ra_monthly(dr, sunset_hour_angle, latitude, solar_declination)
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

def compute_G_monthly(_T, t_max_previous, t_min_previous)
  #equation 44
  t_mean_previous = (t_max_previous + t_min_previous) / 2
  _G = 0.14 * (_T - t_mean_previous)
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

def compute_monthly_et0(state, 
                        subregion, 
                        elevation, 
                        latitude, 
                        month, 
                        t_max, 
                        t_min, 
                        t_dew, 
                        wind_speed, 
                        hours_of_daylight, 
                        t_max_previous, 
                        t_min_previous)
  middle_day_of_the_month = 30.4 * month - 15
  solar_declination = compute_solar_declination(middle_day_of_the_month)
  sunset_hour_angle = compute_sunset_hour_angle(latitude, solar_declination)
  dr = compute_dr(middle_day_of_the_month)
  _Ra = compute_Ra_monthly(dr, sunset_hour_angle, latitude, solar_declination)
  _Rso = compute_Rso(_Ra, elevation)
  _N = compute_N(sunset_hour_angle)
  _Rs = compute_Rs_monthly(hours_of_daylight, _N, _Ra)
  _Rns = compute_Rns(_Rs)
  _Rnl = compute_Rnl_monthly(t_max, t_min, compute_ea(t_dew), _Rs, _Rso)
  atmospheric_pressure = compute_atmospheric_pressure(elevation)

  _Rn = compute_Rn(_Rns, _Rnl)
  _T = (t_min + t_max) / 2
  _G = compute_G_monthly(_T, t_max_previous, t_min_previous)
  _gamma = compute_gamma(atmospheric_pressure)
  _Delta = compute_Delta(_T)
  _u2 = wind_speed
  _es = (compute_es(t_max) + compute_es(t_min)) / 2
  _ea = compute_ea(t_dew)

  et0_numerator = 0.408 * (_Delta) * (_Rn - _G) + _gamma*(900/(_T+273)) * _u2 * (_es - _ea)
  et0_denominator = _Delta + _gamma * (1 + 0.34 * _u2)
  et0 = et0_numerator / et0_denominator
end

#puts compute_monthly_et0("AL",
                         #"none",
                         #120.571428571429,
                         #32.6225714285714,
                         #1,
                         #12.4140552995392,
                         #1.67557603686636,
                         #1.82115015360983,
                         #3.06410330261137,
                         #5.38940092165899,
                         #13.6566820276498,
                         #2.30092165898618) 
