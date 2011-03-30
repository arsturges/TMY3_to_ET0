# This program runs with Ruby 1.9 and the CSV class instead of 1.8.7's FasterCSV class.
# Written by Andy Sturges, 10/2010. arsturges@lbl.gov
# This program requires the following files to run:
#   crop_IDML.csv
#   crops_by_state.csv
#   et0.csv
#   Kc.csv
#   regions.csv
#   USDA_FAO_join.csv
# It will produce a file called "water_requirements_by_region.csv".
require 'csv'

def load_files
	@crops = CSV.read("crops_by_state.csv")
	@usda_to_fao_join = CSV.read("USDA_FAO_join.csv")
	@crop_IDML = CSV.read("crop_IDML.csv")
	@regions= CSV.read("regions.csv")
	@et0_data = CSV.read("et0.csv")
	@kc = CSV.read("Kc.csv")

	#take the header rows off
	@crops.shift
	@usda_to_fao_join.shift
	@crop_IDML.shift
	@regions.shift
	@et0_data.shift
	@kc.shift
end

def usda_to_fao # replace USDA crop categories and names with their FAO counterparts
	@crops.each do |usda_crop|
		@usda_to_fao_join.each do |fao_crop|
			if usda_crop[0] == fao_crop[0] && usda_crop[2] == fao_crop[1]
				usda_crop[0] = fao_crop[2] 
				usda_crop[2] = fao_crop[3]
			end
		end
	end
end

def look_up_crop_kc(crop, month, state, subregion) #returns @crop_kc (unitless)
	@climate_zone = nil
	@regions.each do |region_row|
		@climate_zone = region_row[3] if region_row[0] == state && region_row[2] == subregion
	end
	@crop_maturity = nil
	@crop_IDML.each do |crop_row|
		@crop_maturity = crop_row[2+month] if crop_row[1] == crop && crop_row[2] == @climate_zone 
	end
	
	@crop_kc = nil 
	case
		when @crop_maturity == "I" then idml = 1
		when @crop_maturity == "D" then idml = 2
		when @crop_maturity == "M" then idml = 3
		when @crop_maturity == "L" then idml = 4
		else @crop_kc = 0
	end
	unless @crop_kc == 0
		@kc.each do |crop_row|
			@crop_kc = crop_row[1+idml].to_f if crop_row[1] == crop
		end
	end
end

def look_up_region_et0(state, subregion, elevation_band, month) #returns @et0 (floating point) mm/day
	@regions.each do |region_row|
		@state_abbreviation = region_row[1] if region_row[0] == state #two-letter code now
	end
	@et0_data.each do |region_row|
		@et0 = region_row[5].to_f if 
			region_row[1] == @state_abbreviation && 
			region_row[2]==subregion && 
			region_row[3].to_i==month.to_i && 
			region_row[4].to_i == elevation_band
	end
		days_in_month = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month] #assumes no leap year
end

def get_precipitation(state, subregion, month) #returns @precipitation mm/day
	 @regions.each do |region_row|
		if region_row[0] == state && region_row[2] == subregion then
			@precipitation = region_row[3+month.to_i].to_f # mm/month 
			#the next two lines are here to conver the monthly precip to daily precip.
			days_in_month = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month] #assumes no leap year
			@precipitation = @precipitation/days_in_month # mm/day
		end
	 end #region_row
end

# here begins the actual water calculation
def perform_water_calculation
	@water_requirement = {} unless @water_requirement
	@current_crop_row = 0
	@total_crop_rows = 672 #crops_by_state.csv
	@crops.each do |crop_row|
		crop = crop_row[2]
		@current_crop_row +=1
		percent_completed = @current_crop_row*100.to_f/@total_crop_rows.to_f
		puts percent_completed.to_i 
		state =	crop_row[3] #full name, not two-letter abbreviation
		subregion = crop_row[4] 
#		irr_acres = (crop_row[6].to_f + crop_row[9].to_f)/2 # average of 2002 and 2007 data.
		(1..12).each do |month| 
			precipitation_deficit = nil #unset the variable from the last time through
			look_up_crop_kc(crop, month, state, subregion) #this returns @crop_kc (Soybeans, Ark, none, 4; 0.4) (mm/day)
			look_up_region_et0(state, subregion, 1, month) #this returns @et0 (4.2mm/day)
			etc = @crop_kc*@et0 # e.g. (0.4)*(4.2 mm/day) = 1.68mm/day
#			irr_square_meters = irr_acres*4046.85642 # eg 7.1 billion square meters
			get_precipitation(state, subregion, month) #this returns @precipitation e.g. 0.67mm/day.

			unless etc == 0
				if etc > @precipitation then
					precipitation_deficit = etc - @precipitation # e.g. (1.68 mm/day) - (0.67 mm/day) = 1.01 mm/day for that month
					precipitation_deficit = precipitation_deficit*30.4 #this is hackery and you should be fired.
				else
					precipitation_deficit = 0
				end
			end

			@water_requirement[crop] = {} 				unless @water_requirement[crop]
			@water_requirement[crop][state] = {} 			unless @water_requirement[crop][state]
			@water_requirement[crop][state][subregion] = {} 	unless @water_requirement[crop][state][subregion]
			@water_requirement[crop][state][subregion][month] = {} 	unless @water_requirement[crop][state][subregion][month]
			@water_requirement[crop][state][subregion][month] = precipitation_deficit
		end #month
	end #crop_row
end

def write_to_csv_file
	CSV.open("water_requirements_by_region.csv", "w") do |write_new_row|
		write_new_row << %w(Crop State Subregion 1 2 3 4 5 6 7 8 9 10 11 12)
	  	@water_requirement.keys.each do |crop|
			@water_requirement[crop].keys.sort.each do |state|
				@water_requirement[crop][state].keys.sort.each do |subregion|
					crop_name = crop
					crop_state = state
					crop_subregion = subregion
					irrigation01 = @water_requirement[crop][state][subregion][1]
					irrigation02 = @water_requirement[crop][state][subregion][2]
					irrigation03 = @water_requirement[crop][state][subregion][3]
					irrigation04 = @water_requirement[crop][state][subregion][4]
					irrigation05 = @water_requirement[crop][state][subregion][5]
					irrigation06 = @water_requirement[crop][state][subregion][6]
					irrigation07 = @water_requirement[crop][state][subregion][7]
					irrigation08 = @water_requirement[crop][state][subregion][8]
					irrigation09 = @water_requirement[crop][state][subregion][9]
					irrigation10 = @water_requirement[crop][state][subregion][10]
					irrigation11 = @water_requirement[crop][state][subregion][11]
					irrigation12 = @water_requirement[crop][state][subregion][12]
					write_new_row << [
						crop_name, 
						crop_state, 
						crop_subregion,
						irrigation01, 
						irrigation02, 
						irrigation03,
						irrigation04,
						irrigation05,
						irrigation06,
						irrigation07,
						irrigation08,
						irrigation09,
						irrigation10,
						irrigation11,
						irrigation12]
				end #subregion
			end #state
		end #crop
	end
end

load_files
usda_to_fao
#look_up_region_et0("New Mexico", "none", 1, 4)
perform_water_calculation
write_to_csv_file
