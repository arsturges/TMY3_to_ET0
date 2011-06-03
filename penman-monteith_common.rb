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

def compute_Delta(_T)
  #equation 13
  #kPa/C
  _Delta = 4098 * (0.6108 * Math.exp(17.27 * _T / (_T + 237.3))) / (_T + 237.3) ** 2
end

def compute_es(_T)
  #table 2.3, equation 11
  #http://www.fao.org/docrep/X0490E/x0490e0j.htm#annex 2. meteorological tables
  #t units are celsius, es units are kPa
  es = 0.6108 * Math.exp((17.27 * _T) / (_T + 237.3))
end

def compute_ea(dew_point)
  #equation 14
  ea = 0.6108 * Math.exp((17.27 * dew_point) / (dew_point + 237.3))
end

def compute_Rn(_Rns, _Rnl)
  # equation 40
  _Rn = _Rns - _Rnl
end

def compute_Rns(_Rs, albedo=0.23)
  #equation 38
  #albedo is 0.23 for hypothetical grass reference crop (dimensionless)
  _Rns = (1 - albedo) * _Rs
end

def compute_N(sunset_hour_angle)
  #equation 34
  #angle needs to be in radians
  _N = (24/Math::PI) * sunset_hour_angle
end

def compute_solar_declination(number_of_day_in_year)
  #equation 24
  #this returns an angle in radians, oscillating between +/-0.4 rads (+/- 22 degrees)
  solar_declination = 0.409 * Math.sin((2 * Math::PI / 365) * number_of_day_in_year - 1.39)
end

def compute_dr(day_of_the_year)
  #equation 23
  #inverse relative distance Earth-Sun
  dr = 1 + 0.033 * Math.cos((2 * Math::PI/365) * day_of_the_year)
end

def compute_sunset_hour_angle(latitude, solar_declination)
  #equation 25
  latitude = latitude * Math::PI / 180 #convert degrees to radians
  sunset_hour_angle = Math.acos(-Math.tan(latitude) * Math.tan(solar_declination))
  #note that arccos can only accept values between +/-1 rads; if latitude exceeds 68, this may be violated. United States upper boundary is at lat. 48.
end

def compute_Rso(_Ra, elevation)
  #equation 36
  #TODO: calibrate a and b
  _Rso = (0.75 + 2 * (10**(-5) * elevation )) * _Ra
end


