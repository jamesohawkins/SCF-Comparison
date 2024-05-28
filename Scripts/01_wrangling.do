////////////////////////////////////////////////////////////////////////////////
// Do File: 01_wrangling.do.do
// Primary Author: James Hawkins, Berkeley Institute for Young Americans
// Date: 5/28/24
// Stata Version: 17
// Description: In this script, I import and wrangle ASEC samples from
// IPUMS-CPS (via the IPUMS API) and summary data of the triennial SCF files 
// from the Survey of Consumer Finances (SCF) via the Federal Reserve. The ASEC
// samples correspond with the same year as the SCF samples.
// 
// The script is separated into the following sections:
// 		1. Wrangle Current Population Survey (CPS) Data
//		2. Wrangle Unified SCF Files from Summary Files
////////////////////////////////////////////////////////////////////////////////

/// ============================================================================
**# 1. Wrangle Current Population Survey (CPS) Data
/// ============================================================================
/*  In this section, I obtain CPS records via the IPUMS api and wrangle that 
    data in preparation for analysis/comparison with the SCF. */

// A. Obtain CPS data via IPUMS api
// -----------------------------------------------------------------------------
/* In this sub-section, I obtain CPS data from the IPUMS API. Instructions for 
   implementing using the IPUMS API in Stata are available here: 
   https://blog.popdata.org/making-ipums-extracts-from-stata/. General 
   instructions for creating extracts via the API are available here:
   https://v1.developer.ipums.org/docs/workflows/create_extracts/cps/. Users
   seeking to replicate my analysis will need to obtain an API key from IPUMS
   and insert it below or define their API key in their profile.do script that 
   executes every time Stata starts. Instructions to implement the latter are 
   available here: 
   https://www.stata.com/support/faqs/programming/profile-do-file/. */

// Import data via IPUMS API
/* NOTE: Data obtained from IPUMS API on 5/15/24. */
cd "$directory\raw-data"
clear
python
import gzip
import shutil

from ipumspy import IpumsApiClient, UsaExtract, CpsExtract
from sfi import Macro

my_api_key = Macro.getGlobal("MY_API_KEY")

ipums = IpumsApiClient(my_api_key)

# define extract
ipums_collection = "cps"
samples = ["cps1989_03s", "cps1992_03s", "cps1995_03s", "cps1998_03s",
"cps2001_03s", "cps2004_03s", "cps2007_03s", "cps2010_03s", 
"cps2013_03s", "cps2016_03s", "cps2019_03s", "cps2022_03s"]

variables = ["YEAR", "SERIAL", "MONTH", "CPSID", "CPSIDP", "ASECFLAG", "ASECWT", 
"ASECWTH", "PERNUM", "AGE", "OWNERSHP", "RELATE", "GQ"]
extract_description = "SCF Comparison"

extract = CpsExtract(samples, variables, description=extract_description)
	 
# submit your extract to the IPUMS extract system
ipums.submit_extract(extract)

# wait for the extract to finish
ipums.wait_for_extract(extract, collection=ipums_collection)

# download it to your current working directory
ipums.download_extract(extract, stata_command_file=True)

Macro.setLocal("id", str(extract.extract_id).zfill(5))
Macro.setLocal("collection", ipums_collection)

extract_name = f"{ipums_collection}_{str(extract.extract_id).zfill(5)}"
# unzip the extract data file
with gzip.open(f"{extract_name}.dat.gz", 'rb') as f_in:
	with open(f"{extract_name}.dat", 'wb') as f_out:
		shutil.copyfileobj(f_in, f_out)

# exit python
end
qui do `collection'_`id'.do


// B. Wrangle CPS data
// -----------------------------------------------------------------------------
/* In this sub-section, I wrangle the CPS data in prepration for use in the rest
   of my analysis. */

// Restrict sample to adult records
/* NOTE: In some marginal cases, this will lead to households having no 
   household head (aka absent from the household measure) but include other 
   persons in the household who are adults (person measure). */
keep if age >= 18

// Restrict sample to household records
keep if gq == 1

// Top-code age
replace age = 80 if age > 80

// Define individual-level age group measure (primary groupings used in analysis across time)
gen agegroup = 1 if age <= 3
replace agegroup = 2 if age >= 4 & age <= 6
replace agegroup = 3 if age >= 7 & age <= 12
replace agegroup = 4 if age >= 13 & age <= 17
replace agegroup = 5 if age >= 18 & age <= 24
replace agegroup = 6 if age >= 25 & age <= 34
replace agegroup = 7 if age >= 35 & age <= 44
replace agegroup = 8 if age >= 45 & age <= 54
replace agegroup = 9 if age >= 55 & age <= 64
replace agegroup = 10 if age >= 65
** label(s)
lab var agegroup "Primary age groups for household heads (harmonized across time)"
lab def agegroup_lbl ///
	1 "3 or younger" ///
	2 "4-6" ///
	3 "7-12" ///
	4 "13-17" ///
	5 "18-24" ///
	6 "25-34" ///
	7 "35-44" ///
	8 "45-54" ///
	9 "55-64" ///
	10 "65+"
lab val agegroup agegroup_lbl

// Define alternative individual-level age group measure (wider young adult bin)
gen agegroup_alt = 1 if age <= 3
replace agegroup_alt = 2 if age >= 4 & age <= 6
replace agegroup_alt = 3 if age >= 7 & age <= 12
replace agegroup_alt = 4 if age >= 13 & age <= 17
replace agegroup_alt = 5 if age >= 18 & age <= 24
replace agegroup_alt = 6 if age >= 25 & age <= 39
replace agegroup_alt = 7 if age >= 40 & age <= 54
replace agegroup_alt = 8 if age >= 55 & age <= 64
replace agegroup_alt = 9 if age >= 65
** label(s)
lab var agegroup_alt "Alternative age groups for household heads (harmonized across time)"
lab def agegroup_alt_lbl ///
	1 "3 or younger" ///
	2 "4-6" ///
	3 "7-12" ///
	4 "13-17" ///
	5 "18-24" ///
	6 "25-39" ///
	7 "40-54" ///
	8 "55-64" ///
	9 "65+"
lab val agegroup_alt agegroup_alt_lbl

// Define homeownership measure (household)
gen ownhh = 1 if ownershp == 10 & relate == 101
replace ownhh = 0 if inlist(ownershp, 21, 22) & relate == 101
lab var ownhh "Homeownership (household)"

// Define homeownership measures (person)
** partners included (preferred measure)
gen ownp1 = 0
replace ownp1 = 1 if ownershp == 10 & inlist(relate, 101, 201, 202, 203, 1114, 1116, 1117)
lab var ownp1 "Homeownership (person, including spouses and partners)"
** partner/roommates (1989 and 1992) included
gen ownp2 = 0
replace ownp2 = 1 if ownershp == 10 & inlist(relate, 101, 201, 202, 203, 1113, 1114, 1116, 1117)
lab var ownp2 "Homeownership (person, including spouses, partners, and partner/roommates)"
** spouses
gen ownp3 = 0
replace ownp3 = 1 if ownershp == 10 & inlist(relate, 101, 201, 202, 203)
lab var ownp3 "Homeownership (person, including spouses)"

// Define headship measures
** partners included (preferred measure)
gen headship1 = 0
replace headship1 = 1 if inlist(relate, 101, 201, 202, 203, 1114, 1116, 1117)
lab var headship1 "Headship (including spouses and partners)"
** partner/roommates (1989 and 1992) included
gen headship2 = 0
replace headship2 = 1 if inlist(relate, 101, 201, 202, 203, 1113, 1114, 1116, 1117)
lab var headship2 "Homeownership (person, including spouses, partners, and partner/roommates)"
** spouses
gen headship3 = 0
replace headship3 = 1 if inlist(relate, 101, 201, 202, 203)
lab var headship3 "Homeownership (person, including spouses)"

// Save data
cd "$directory\derived-data"
compress
save cps_wrangled.dta, replace


/// ============================================================================
**# 2. Wrangle Unified SCF Files from Summary Files
/// ============================================================================
/*  In this section, I import the triennial summary files for the SCF and 
    wrangle this data in preparation for comparison with the CPS. Public data 
    files in Stata format for the SCF are available via the Federal Reserve 
    website at: https://www.federalreserve.gov/econres/scfindex.htm. */

// Import each triennial file in Stata and temporary save
/* NOTE: Data obtained from IPUMS on 4/2/24. */
cd "$directory\Raw-Data\scf_summary"
foreach year of numlist 1989 1992 1995 1998 2001 2004 2007 2010 2013 2016 2019 2022 {
	use rscfp`year'.dta, clear
	gen year = `year'
	tempfile scf`year'
	save `scf`year''.dta, replace
}

// Append all individual year files
clear
foreach year of numlist 1989 1992 1995 1998 2001 2004 2007 2010 2013 2016 2019 2022 {
	append using `scf`year''.dta
}
replace y1 = x1 if year == 1989

// Define household indicator
gen hh = y1

// Identify implicates
tostring hh, replace
gen implicate = substr(hh, -1, 1)
destring implicate hh, replace
order hh implicate

// Define age measure for reference person
rename age agehh

// Define individual-level age group measure (primary groupings used in analysis across time)
gen agegroup = 1 if agehh <= 3
replace agegroup = 2 if agehh >= 4 & agehh <= 6
replace agegroup = 3 if agehh >= 7 & agehh <= 12
replace agegroup = 4 if agehh >= 13 & agehh <= 17
replace agegroup = 5 if agehh >= 18 & agehh <= 24
replace agegroup = 6 if agehh >= 25 & agehh <= 34
replace agegroup = 7 if agehh >= 35 & agehh <= 44
replace agegroup = 8 if agehh >= 45 & agehh <= 54
replace agegroup = 9 if agehh >= 55 & agehh <= 64
replace agegroup = 10 if agehh >= 65
** label(s)
lab var agegroup "Primary age groups for household heads (harmonized across time)"
lab def agegroup_lbl ///
	1 "3 or younger" ///
	2 "4-6" ///
	3 "7-12" ///
	4 "13-17" ///
	5 "18-24" ///
	6 "25-34" ///
	7 "35-44" ///
	8 "45-54" ///
	9 "55-64" ///
	10 "65+"
lab val agegroup agegroup_lbl

// Define alternative individual-level age group measure (wider young adult bin)
gen agegroup_alt = 1 if agehh <= 3
replace agegroup_alt = 2 if agehh >= 4 & agehh <= 6
replace agegroup_alt = 3 if agehh >= 7 & agehh <= 12
replace agegroup_alt = 4 if agehh >= 13 & agehh <= 17
replace agegroup_alt = 5 if agehh >= 18 & agehh <= 24
replace agegroup_alt = 6 if agehh >= 25 & agehh <= 39
replace agegroup_alt = 7 if agehh >= 40 & agehh <= 54
replace agegroup_alt = 8 if agehh >= 55 & agehh <= 64
replace agegroup_alt = 9 if agehh >= 65
** label(s)
lab var agegroup_alt "Alternative age groups for household heads (harmonized across time)"
lab def agegroup_alt_lbl ///
	1 "3 or younger" ///
	2 "4-6" ///
	3 "7-12" ///
	4 "13-17" ///
	5 "18-24" ///
	6 "25-39" ///
	7 "40-54" ///
	8 "55-64" ///
	9 "65+"
lab val agegroup_alt agegroup_alt_lbl

// Define homeownership measure (household)
** codebook: have owned principal residence: 1=yes, 0=no
gen ownhh = hhouses
lab var ownhh "Homeownership (household)"

// Define weight at original value
/* NOTE: wgt var given in summary files is divided by 5 to make analysis across
   all implicates weighted correctly. I separate my analysis by implicates and 
   take the mean of final implicate-specific estimates (this can be confirmed by
   comparing against aggregate household counts from the CPS. For estimates of
   homeownership rates, neither the multiple of the weight nor the calculation
   over implicates will have an effect on the final estimates). */
gen weight = wgt * 5
	
// Save unified file
cd "$directory\Derived-Data"
compress
save scf_summaryunified.dta, replace