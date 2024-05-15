////////////////////////////////////////////////////////////////////////////////
// Do File: 02_analysis.do.do
// Primary Author: James Hawkins, Berkeley Institute for Young Americans
// Date: 5/15/24
// Stata Version: 17
// Description: In this script, I implement analysis comparing homeownership in
// the CPS and SCF, as well as analysis of housing wealth in the SCF, and 
// headship rates in the CPS. All code for the visualizations from the 
// accompanying brief are contained in this script. Visualizations are saved in
// the directory's output folder.
// 
// The script is separated into the following sections:
//		1. Comparison of SCF and CPS Homeownership
//		2. Estimate Headship Rates
//		3. Net housing wealth shares
//		4. Comparison of SCF and CPS Homeownership (Prime-Age Population)
//		5. Comparison of SCF and CPS Homeownership (All Adults)
//		6. Comparison of SCF and CPS Homeownership (Alternative Young Adult Age Group)
////////////////////////////////////////////////////////////////////////////////


/// ============================================================================
**# 1. Comparison of SCF and CPS Homeownership
/// ============================================================================
/*  In this section, I compare homeownership rates by age groups in the CPS and 
    Survey of Consumer Finances (SCF) based on alternative definitions of 
    homeownership in the CPS, dependent on treatment of partners of the 
	household reference person in the CPS. In my preferred measure of person 
	level homeownership, I count spouse/partners as owners if they reside in an 
	owned house and exclude the partner/roommate category as owners, which 
	represents the most detailed categorization of partners in the 1989 and 1992 
	CPS. The preferred measure should be conservative measure of trends in 
	person homeownership over time since it will undercount homeownership in 
	1989 and 1992. */

// Estimate alternative homeownership rates
// -----------------------------------------------------------------------------
/* In this sub-section, I calculate alternative homeownership rates based on an
   SCF household measure, CPS household measure, and CPS person measure over 
   time and across binned age groups. */

// SCF: household measure
cd "$directory\derived-data"
use scf_summaryunified.dta, clear
** restrict sample to adult records
keep if agehh >= 18
** estimate homeownership rates (separately by implicate, but this will not matter for rates)
collapse (mean) ownhh_scf = ownhh [pw = weight], by(agegroup year implicate)
collapse (mean) ownhh_scf, by(agegroup year)
** save
tempfile ownhh_scf
save `ownhh_scf'.dta, replace

// CPS: household measure
use cps_wrangled.dta if inlist(year, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019, 2022), clear
** restrict to heads of households
keep if relate == 101
** estimate homeownership rates
collapse (mean) ownhh_cps = ownhh [pw = asecwth], by(agegroup year)
** temporary save
tempfile ownhh_cps
save `ownhh_cps'.dta, replace

// CPS: person measure
use cps_wrangled.dta if inlist(year, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019, 2022), clear
* estimate homeownership rates
collapse (mean) ownp1_cps = ownp1 ownp2_cps = ownp2 ownp3_cps = ownp3 [pw = asecwt], by(agegroup year)
** temporary save
tempfile ownp_cps
save `ownp_cps'.dta, replace

// Combine estimates
use `ownhh_scf'.dta, clear
merge 1:1 agegroup year using `ownhh_cps'.dta, nogen
merge 1:1 agegroup year using `ownp_cps'.dta, nogen

// Define ratios of different ownership measures
** scf household to cps household ratio
gen ratio_ownhh = ownhh_scf / ownhh_cps
** preferred cps person to cps household ratio
gen ratio1_owncps = ownp1_cps / ownhh_cps
** cps person to scf household ratios
gen ratio1 = ownp1_cps / ownhh_scf
gen ratio2 = ownp2_cps / ownhh_scf
gen ratio3 = ownp3_cps / ownhh_scf

// Export results
cd "$directory\output"
export delimited own_mainresults.csv, replace


// Visualization: Comparing survey measures of homeownership
// -----------------------------------------------------------------------------
* chart notes
linewrap, maxlength(180) name("notes") stack longstring("In this figure I report the ratio of my preferred measure of person-level CPS homeownership relative to the SCF household measure of homeownership. The person-level CPS measure defines homeowners as 1) any reference person (aka householder) in a dwelling that is owned and 2) the spouse/partner of a reference person in a dwelling that is owned. All other persons are considered non-owners.")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
if `y' < 5 {
	local notes = `"`notes' """'
}
* graph
twoway (connected ownhh_cps ownhh_scf ownp1_cps year, mcolor("253 181 21" "0 176 218" "238 31 96") msize(vsmall vsmall vsmall) msymbol(square circle triangle) lcolor("253 181 21" "0 176 218" "238 31 96") lpattern(solid solid solid)) ///
, ///
by(agegroup, rows(1) imargin(vsmall)) ///
by(, title("Comparing survey measures of homeownership", color("0 50 98") size(large) pos(11) justification(left))) ///
by(, subtitle("Homeownership rate (household or person measure), by age group", color("59 126 161") size(small) pos(11) justification(left))) ///
subtitle(,  color(white) size(vsmall) lcolor("59 126 161") fcolor("59 126 161")) ///
xtitle("", size(small) color(gs6) bmargin(zero)) xscale(lstyle(none)) ///
xlabel(1989 "1989" 1992 "1992" 1995 "1995" 1998 "1998" 2001 "2001" 2004 "2004" 2007 "2007" 2010 "2010" 2013 "2013" 2016 "2016" 2019 "2019" 2022 "2022", angle(45) labsize(tiny) glcolor(gs9%0) labcolor(gs6) tlength(1.25) tlcolor(gs6%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%" .6 "60%" .7 "70%" .8 "80%", angle(0) gmax gmin glpattern(solid) glcolor(gs9%15) glwidth(vthin) labcolor("59 126 161") labsize(2.5) tlength(0) tlcolor(gs9%15)) ///
legend(order(1 "CPS: Household" 2 "SCF: Household" 3 "CPS: Person") rows(1) pos(12) bmargin(zero)) ///
by(, legend(order(1 "CPS (Household)" 2 "CPS (Person)" 3 "SCF") pos(12) bmargin(zero))) ///
by(, note("Source: {fontface Lato:Author's analysis of the Current Population Survey via IPUMS-CPS and the Survey of Consumer Finances.} Sample: {fontface Lato:U.S. adult household residents (person measure) or householders (household}" "{fontface Lato:measure).}" `notes', margin(l+1.5) color(gs7) span size(1.75) position(7))) ///
by(, caption("@jamesohawkins {fontface Lato:with} youngamericans.berkeley.edu", margin(l+1.5 t-1) color(gs7%50) span size(1.75) position(7))) ///
by(, graphregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
by(, plotregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
by(, graphregion(margin(r+1)))
cd "$directory\output"
graph export own_surveyXage.png, replace

// Visualization: Ratio of CPS person measure to SCF household measure (ages 25+)
// -----------------------------------------------------------------------------
* chart notes
linewrap, maxlength(180) name("notes") stack longstring("In this figure I report the ratio of my preferred measure of person-level CPS homeownership relative to the SCF household measure of homeownership. The person-level CPS measure defines homeowners as 1) any reference person (aka householder) in a dwelling that is owned and 2) the spouse/partner of a reference person in a dwelling that is owned. All other persons are considered non-owners.")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
if `y' < 5 {
	local notes = `"`notes' """'
}
* graph
twoway (connected ratio1 year, mcolor("59 126 161") msize(vsmall) msymbol(diamond) lcolor("59 126 161") lpattern(solid)) ///
if agegroup >= 6 ///
, ///
by(agegroup, rows(1) imargin(vsmall)) ///
by(, title("Comparing survey measures of homeownership", color("0 50 98") size(large) pos(11) justification(left) lwidth(thin))) ///
by(, subtitle("Ratio of CPS person measure to SCF household measure of homeownership rates, by age group", color("59 126 161") size(small) pos(11) justification(left))) ///
subtitle(,  color(white) size(vsmall) lcolor("59 126 161") fcolor("59 126 161")) ///
yline(1, lpattern(solid) lcolor("221 213 199")) ///
xtitle("", size(small) color(gs6) bmargin(zero)) xscale(lstyle(none)) ///
xlabel(1989 "1989" 1992 "1992" 1995 "1995" 1998 "1998" 2001 "2001" 2004 "2004" 2007 "2007" 2010 "2010" 2013 "2013" 2016 "2016" 2019 "2019" 2022 "2022", angle(45) labsize(tiny) glcolor(gs9%0) labcolor(gs6) tlength(1.25) tlcolor(gs6%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(.75 "0.75" .8 "0.80" .85 "0.85" .9 "0.90" .95 "0.95" 1 "1.0", angle(0) gmax gmin glpattern(solid) glcolor(gs9%15) glwidth(vthin) labcolor("59 126 161") labsize(2.5) tlength(0) tlcolor(gs9%15)) ///
legend(order(1 "Ratio of SCF Household to CPS Household Measure" 2 "Ratio of CPS Person to CPS Household Measure") rows(1) pos(12) bmargin(zero)) ///
by(, legend(order(1 "CPS (Household)" 2 "CPS (Person)" 3 "SCF") pos(12) bmargin(zero))) ///
by(, note("Source: {fontface Lato:Author's analysis of the Current Population Survey via IPUMS-CPS and the Survey of Consumer Finances.} Sample: {fontface Lato:U.S. household residents (person measure) or}" "{fontface Lato:householders (household measure) ages 25+.}" `notes', margin(l+1.5) color(gs7) span size(1.75) position(7))) ///
by(, caption("@jamesohawkins {fontface Lato:with} youngamericans.berkeley.edu", margin(l+1.5 t-1) color(gs7%50) span size(1.75) position(7))) ///
by(, graphregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
by(, plotregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
by(, graphregion(margin(r+1)))
cd "$directory\output"
graph export ownratio_age6-10.png, replace

// Visualization: Ratio of CPS person measure to SCF household measure (ages 18+ and alternative specifications)
// -----------------------------------------------------------------------------
* chart notes
linewrap, maxlength(180) name("notes") stack longstring("In this figure I report the ratio of various person-level CPS homeownership measures relative to the SCF household measure of homeownership. The first (preferred) measure defines homeowners as 1) any reference person (aka householder) in a dwelling that is owned and 2) the spouse/partner of a reference person in a dwelling that is owned. All other persons are considered non-owners. The second measure is equivalent to the first measure but also includes individuals as owners if they are designated as partner/roommates in 1989 and 1992 in a dwelling that is owned. Finally, the third measure is equivalent to the first measure but excludes any partners as potential owners.")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
if `y' < 5 {
	local notes = `"`notes' """'
}
* graph
twoway (connected ratio3 year, mcolor("238 31 96") msize(small) msymbol(triangle) lcolor("238 31 96") lpattern(solid)) ///
(connected ratio2 year, mcolor("221 213 199") msize(small) msymbol(circle) lcolor("221 213 199") lpattern(solid)) ///
(connected ratio1 year, mcolor("59 126 161") msize(vsmall) msymbol(square) lcolor("59 126 161") lpattern(solid)) ///
, ///
by(agegroup, rows(1) imargin(vsmall)) ///
by(, title("Comparing survey measures of homeownership", color("0 50 98") size(large) pos(11) justification(left) lwidth(thin))) ///
by(, subtitle("Ratio of CPS person measures to SCF household measure of homeownership rates, by age group", color("59 126 161") size(small) pos(11) justification(left))) ///
subtitle(,  color(white) size(vsmall) lcolor("59 126 161") fcolor("59 126 161")) ///
yline(1, lpattern(solid) lcolor("221 213 199")) ///
xtitle("", size(small) color(gs6) bmargin(zero)) xscale(lstyle(none)) ///
xlabel(1989 "1989" 1992 "1992" 1995 "1995" 1998 "1998" 2001 "2001" 2004 "2004" 2007 "2007" 2010 "2010" 2013 "2013" 2016 "2016" 2019 "2019" 2022 "2022", angle(45) labsize(tiny) glcolor(gs9%0) labcolor(gs6) tlength(1.25) tlcolor(gs6%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(.3 "0.3" .4 "0.4" .5 "0.5" .6 "0.6" .7 "0.7" .8 "0.8" .9 "0.9" 1 "1.0" 1.1 "1.1", angle(0) gmax gmin glpattern(solid) glcolor(gs9%15) glwidth(vthin) labcolor("59 126 161") labsize(2.5) tlength(0) tlcolor(gs9%15)) ///
legend(order(3 "1. Ratio with Preferred CPS Measure" 2 "2. Ratio with CPS Partners/Roommates" 1 "3. Ratio with CPS Spouses") rows(1) pos(12) bmargin(zero)) ///
by(, legend(order(3 "1. Ratio with Preferred CPS Measure" 2 "2. Ratio with CPS Partners/Roommates" 1 "3. Ratio with CPS Spouses") pos(12) bmargin(zero))) ///
by(, note("Source: {fontface Lato:Author's analysis of the Current Population Survey via IPUMS-CPS and the Survey of Consumer Finances.} Sample: {fontface Lato:U.S. adult household residents (person measure) or}" "{fontface Lato:householders (household measure).}" `notes', margin(l+1.5) color(gs7) span size(1.75) position(7))) ///
by(, caption("@jamesohawkins {fontface Lato:with} youngamericans.berkeley.edu", margin(l+1.5 t-1) color(gs7%50) span size(1.75) position(7))) ///
by(, graphregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
by(, plotregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
by(, graphregion(margin(r+1)))
cd "$directory\output"
graph export ownratio_age5-10.png, replace


/// ============================================================================
**# 2. Estimate Headship Rates
/// ============================================================================
/*  In this section, I compare alternative definitions of headship rates over
    time in the Current Population Survey via IPUMS-CPS based on various 
    conceptions of partners of the household reference person in defining the 
    heads of households. */

// Import wrangled cps data
cd "$directory\derived-data"
use cps_wrangled.dta if inlist(year, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019, 2022), clear

// Estimate headship rates
collapse (mean) headship1 headship2 headship3 [pw = asecwt], by(agegroup year)

// Export results
cd "$directory\output"
export delimited headship.csv, replace

// Visualization: Comparing survey measures of homeownership
* chart notes
linewrap, maxlength(180) name("notes") stack longstring("In this figure I report headship rates in the CPS based on various measures of the count of household heads and their partners/spouses for each age group. The first (preferred) measure defines head(s) of households as 1) any reference person (aka householder) and 2) the spouse/partner of the reference person. All other persons are considered non-heads. The second measure is equivalent to the first measure but also includes individuals who are designated as partners/roommates in the 1989 and 1992 samples. The third measure limits heads to the reference person or the spouse of the reference person (excludes any partners).")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
if `y' < 5 {
	local notes = `"`notes' """'
}
* graph
twoway (connected headship3 year, mcolor("238 31 96") msize(small) msymbol(triangle) lcolor("238 31 96") lpattern(solid)) ///
(connected headship2 year, mcolor("221 213 199") msize(small) msymbol(circle) lcolor("221 213 199") lpattern(solid)) ///
(connected headship1 year, mcolor("59 126 161") msize(vsmall) msymbol(square) lcolor("59 126 161") lpattern(solid)) ///
, ///
by(agegroup, rows(1) imargin(vsmall)) ///
by(, title("Comparing alternative measures of headship rates", color("0 50 98") size(large) pos(11) justification(left))) ///
by(, subtitle("Headship rate, by age group", color("59 126 161") size(small) pos(11) justification(left))) ///
subtitle(,  color(white) size(vsmall) lcolor("59 126 161") fcolor("59 126 161")) ///
xtitle("", size(small) color(gs6) bmargin(zero)) xscale(lstyle(none)) ///
xlabel(1989 "1989" 1992 "1992" 1995 "1995" 1998 "1998" 2001 "2001" 2004 "2004" 2007 "2007" 2010 "2010" 2013 "2013" 2016 "2016" 2019 "2019" 2022 "2022", angle(45) labsize(tiny) glcolor(gs9%0) labcolor(gs6) tlength(1.25) tlcolor(gs6%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1 "100%", angle(0) gmax gmin glpattern(solid) glcolor(gs9%15) glwidth(vthin) labcolor("59 126 161") labsize(2.5) tlength(0) tlcolor(gs9%15)) ///
legend(order(3 "1. Preferred CPS measure" 2 "2. CPS Measure with partners/roommates" 1 "3. CPS measure with spouses only") rows(1) pos(12) bmargin(zero)) ///
by(, legend(order(3 "Ratio with Preferred CPS Measure" 2 "Ratio with CPS Partners/Roommates" 1 "Ratio with CPS Spouses") pos(12) bmargin(zero))) ///
by(, note("Source: {fontface Lato:Author's analysis of the Current Population Survey via IPUMS-CPS.} Sample: {fontface Lato:U.S. adult household residents.}" `notes', margin(l+1.5) color(gs7) span size(1.75) position(7))) ///
by(, caption("@jamesohawkins {fontface Lato:with} youngamericans.berkeley.edu", margin(l+1.5 t-1) color(gs7%50) span size(1.75) position(7))) ///
by(, graphregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
by(, plotregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
by(, graphregion(margin(r+1)))
cd "$directory\output"
graph export headship_measureXage.png, replace


/// ============================================================================
**# 3. Net housing wealth shares
/// ============================================================================
/* In this section, I estimate total net housing wealth as a share of total net worth
   across various age groups in the SCF. */
cd "$directory\derived-data"
use scf_summaryunified.dta, clear

// Define net housing wealth measure
gen nethouse = houses - mrthel

// Estimate net housing wealth share
collapse (sum) nethouse networth [pw = weight], by(agegroup year implicate)
collapse (mean) nethouse networth, by(agegroup year)
gen houseshare = nethouse / networth

// Drop households not headed by adults
drop if agegroup <= 4

// Export results
cd "$directory\output"
export delimited housingwealthshare.csv, replace

// Visualization: Net housing wealth share
* chart notes
linewrap, maxlength(180) name("notes") stack longstring("In this figure I report the sum of net housing wealth of the primary residence as a share of the sum of total net worth. Net housing wealth is measured as the self-reported value of the primary residence net of debt secured by that residence (e.g., mortgages). Net worth is based on the Federal Reserve 'Bulletin' measure of total wealth.")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
if `y' < 5 {
	local notes = `"`notes' """'
}
* graph
twoway (bar houseshare year, barwidth(1.7) fcolor("0 50 98") lwidth(none)) ///
, ///
by(agegroup, rows(1) imargin(vsmall)) ///
by(, title("What share of net worth is made up by housing wealth?", color("0 50 98") size(large) pos(11) justification(left))) ///
by(, subtitle("Total net value of primary residence (net of debt secured by primary residence) as a share of total net worth, by age group", color("59 126 161") size(small) pos(11) justification(left))) ///
subtitle(,  color(white) size(vsmall) lcolor("59 126 161") fcolor("59 126 161")) ///
xtitle("", size(small) color(gs6) bmargin(zero)) xscale(lstyle(none)) ///
xlabel(1989 "1989" 1992 "1992" 1995 "1995" 1998 "1998" 2001 "2001" 2004 "2004" 2007 "2007" 2010 "2010" 2013 "2013" 2016 "2016" 2019 "2019" 2022 "2022", angle(45) labsize(tiny) glcolor(gs9%0) labcolor(gs6) tlength(1.25) tlcolor(gs6%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%", angle(0) gmax gmin glpattern(solid) glcolor(gs9%15) glwidth(vthin) labcolor("59 126 161") labsize(2.5) tlength(0) tlcolor(gs9%15)) ///
legend(order(3 "Preferred CPS measure" 2 "CPS Measure with partners/roommates" 1 "CPS measure with spouses only") rows(1) pos(12) bmargin(zero)) ///
by(, legend(order(3 "Ratio with Preferred CPS Measure" 2 "Ratio with CPS Partners/Roommates" 1 "Ratio with CPS Spouses") pos(12) bmargin(zero))) ///
by(, note("Source: {fontface Lato:Author's analysis of the Survey of Consumer Finances.} Sample: {fontface Lato:U.S. adult householders.}" `notes', margin(l+1.5) color(gs7) span size(1.75) position(7))) ///
by(, caption("@jamesohawkins {fontface Lato:with} youngamericans.berkeley.edu", margin(l+1.5 t-1) color(gs7%50) span size(1.75) position(7))) ///
by(, graphregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
by(, plotregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
by(, graphregion(margin(r+0)))
cd "$directory\output"
graph export housingwealthshare.png, replace


/// ============================================================================
**# 4. Comparison of SCF and CPS Homeownership (Prime-Age Population)
/// ============================================================================
/*  In this section, I compare homeownership rates in the CPS and Survey of 
    Consumer Finances (SCF) based on alternative definitions of homeownership in
    the CPS, dependent on treatment of partners of the household reference 
	person in the CPS among 25-54-year-olds. */

// Estimate alternative homeownership rates
// -----------------------------------------------------------------------------
/* In this sub-section, I calculate alternative homeownership rates based on an
   SCF household measure, CPS household measure, and CPS person measure over 
   time and across binned age groups. */

// SCF: household measure
cd "$directory\derived-data"
use scf_summaryunified.dta, clear
** restrict to prime-age population
keep if inrange(agegroup, 6, 8)
** estimate homeownership rates (separately by implicate, but this will not matter for rates)
collapse (mean) ownhh_scf = ownhh [pw = weight], by(year implicate)
collapse (mean) ownhh_scf, by(year)
** save
tempfile ownhh_scf
save `ownhh_scf'.dta, replace

// CPS: household measure
use cps_wrangled.dta if inlist(year, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019, 2022), clear
** restrict to prime-age population
keep if inrange(agegroup, 6, 8)
** restrict to heads of households
keep if relate == 101
** estimate homeownership rates
collapse (mean) ownhh_cps = ownhh [pw = asecwth], by(year)
** temporary save
tempfile ownhh_cps
save `ownhh_cps'.dta, replace

// CPS: person measure
use cps_wrangled.dta if inlist(year, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019, 2022), clear
** restrict to prime-age population
keep if inrange(agegroup, 6, 8)
* estimate homeownership rates
collapse (mean) ownp1_cps = ownp1 ownp2_cps = ownp2 ownp3_cps = ownp3 [pw = asecwt], by(year)
** temporary save
tempfile ownp_cps
save `ownp_cps'.dta, replace

// Combine estimates
use `ownhh_scf'.dta, clear
merge 1:1 year using `ownhh_cps'.dta, nogen
merge 1:1 year using `ownp_cps'.dta, nogen

// Define ratios of different ownership measures
** scf household to cps household ratio
gen ratio_ownhh = ownhh_scf / ownhh_cps
** preferred cps person to cps household ratio
gen ratio1_owncps = ownp1_cps / ownhh_cps
** cps person to scf household ratios
gen ratio1 = ownp1_cps / ownhh_scf
gen ratio2 = ownp2_cps / ownhh_scf
gen ratio3 = ownp3_cps / ownhh_scf

// Export results
cd "$directory\output"
export delimited own_primeagepop.csv, replace

// Visualization: Ratio of CPS person measure to SCF household measure (25-54 years old)
// -----------------------------------------------------------------------------
* labels
gen ratio1lab = ratio1
tostring ratio1lab, replace format("%12.3f") force
* chart notes
linewrap, maxlength(180) name("notes") stack longstring("In this figure I report the ratio of my preferred measure of person-level CPS homeownership relative to the SCF household measure of homeownership. The CPS person measure defines homeownership as any reference person (household head) in a dwelling that is owned, as well as the spouse or partner of the reference person in a dwelling that is owned.")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
if `y' < 5 {
	local notes = `"`notes' """'
}
* graph
twoway (bar ratio1 year, barwidth(1.5) mcolor("59 126 161") msize(vsmall) msymbol(diamond) lcolor(none) fcolor("59 126 161") lpattern(solid)) ///
(scatter ratio1 year, mlab(ratio1lab) mlabsize(vsmall) mlabcolor(white) mlabpos(6) mlabgap(.1) msymbol(none) msize(tiny)) ///
, ///
title("Comparing survey measures of homeownership (prime-age pop.)", color("0 50 98") size(large) pos(11) justification(left) lwidth(thin)) ///
subtitle("Ratio of CPS person measures to SCF household measure of homeownership rates (among 25-54-year-olds)", color("59 126 161") size(small) pos(11) justification(left)) ///
xtitle("", size(small) color(gs6) bmargin(zero)) xscale(lstyle(none)) ///
xlabel(1989 "1989" 1992 "1992" 1995 "1995" 1998 "1998" 2001 "2001" 2004 "2004" 2007 "2007" 2010 "2010" 2013 "2013" 2016 "2016" 2019 "2019" 2022 "2022", angle(0) labsize(vsmall) glcolor(gs9%0) labcolor(gs6) tlength(0) tlcolor(gs6%30)) ///
ytitle("") ///
yscale(lstyle(none) range(.85 .95)) ///
ylabel(none) ///
legend(off) ///
note("Source: {fontface Lato:Author's analysis of IPUMS-CPS.} Sample: {fontface Lato:U.S. household residents (person measure) or householders (household measure) 25-54 years old.}" `notes', margin(l+1.5) color(gs7) span size(1.75) position(7)) ///
caption("@jamesohawkins {fontface Lato:with} youngamericans.berkeley.edu", margin(l+1.5 t-1) color(gs7%50) span size(1.75) position(7)) ///
graphregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium)) ///
plotregion(margin(l+1 r+1 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium)) ///
graphregion(margin(r+3))
cd "$directory\output"
graph export ownratio_primeagepop.png, replace


/// ============================================================================
**# 5. Comparison of SCF and CPS Homeownership (All Adults)
/// ============================================================================
/* In this section, I compare homeownership rates in the CPS and Survey of 
   Consumer Finances (SCF) based on alternative definitions of homeownership in
   the CPS, dependent on treatment of partners of the household reference person
   in the CPS among 25-54-year-olds. */

// Estimate alternative homeownership rates
// -----------------------------------------------------------------------------
/* In this sub-section, I calculate alternative homeownership rates based on an
   SCF household measure, CPS household measure, and CPS person measure over 
   time and across binned age groups. */

// SCF: household measure
cd "$directory\derived-data"
use scf_summaryunified.dta, clear
** restrict sample to adult records
keep if agehh >= 18
** estimate homeownership rates (separately by implicate, but this will not matter for rates)
collapse (mean) ownhh_scf = ownhh [pw = weight], by(year implicate)
collapse (mean) ownhh_scf, by(year)
** save
tempfile ownhh_scf
save `ownhh_scf'.dta, replace

// CPS: household measure
use cps_wrangled.dta if inlist(year, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019, 2022), clear
** restrict to heads of households
keep if relate == 101
** estimate homeownership rates
collapse (mean) ownhh_cps = ownhh [pw = asecwth], by(year)
** temporary save
tempfile ownhh_cps
save `ownhh_cps'.dta, replace

// CPS: person measure
use cps_wrangled.dta if inlist(year, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019, 2022), clear
* estimate homeownership rates
collapse (mean) ownp1_cps = ownp1 ownp2_cps = ownp2 ownp3_cps = ownp3 [pw = asecwt], by(year)
** temporary save
tempfile ownp_cps
save `ownp_cps'.dta, replace

// Combine estimates
use `ownhh_scf'.dta, clear
merge 1:1 year using `ownhh_cps'.dta, nogen
merge 1:1 year using `ownp_cps'.dta, nogen

// Define ratios of different ownership measures
** scf household to cps household ratio
gen ratio_ownhh = ownhh_scf / ownhh_cps
** preferred cps person to cps household ratio
gen ratio1_owncps = ownp1_cps / ownhh_cps
** cps person to scf household ratios
gen ratio1 = ownp1_cps / ownhh_scf
gen ratio2 = ownp2_cps / ownhh_scf
gen ratio3 = ownp3_cps / ownhh_scf

// Export results
cd "$directory\output"
export delimited own_alladults.csv, replace

// Visualization: Ratio of CPS person measure to SCF household measure (ages 25+)
// -----------------------------------------------------------------------------
* labels
gen ratio1lab = ratio1
tostring ratio1lab, replace format("%12.3f") force
* chart notes
linewrap, maxlength(180) name("notes") stack longstring("In this figure I report the ratio of my preferred measure of person-level CPS homeownership relative to the SCF household measure of homeownership. The CPS person measure defines homeownership as any reference person (household head) in a dwelling that is owned, as well as the spouse or partner of the reference person in a dwelling that is owned.")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
if `y' < 5 {
	local notes = `"`notes' """'
}
* graph
twoway (bar ratio1 year, barwidth(1.5) mcolor("59 126 161") msize(vsmall) msymbol(diamond) lcolor(none) fcolor("59 126 161") lpattern(solid)) ///
(scatter ratio1 year, mlab(ratio1lab) mlabsize(vsmall) mlabcolor(white) mlabpos(6) mlabgap(.1) msymbol(none) msize(tiny)) ///
, ///
title("Comparing survey measures of homeownership (all adults)", color("0 50 98") size(large) pos(11) justification(left) lwidth(thin)) ///
subtitle("Ratio of CPS person measures to SCF household measure of homeownership rates (18 or older)", color("59 126 161") size(small) pos(11) justification(left)) ///
xtitle("", size(small) color(gs6) bmargin(zero)) xscale(lstyle(none)) ///
xlabel(1989 "1989" 1992 "1992" 1995 "1995" 1998 "1998" 2001 "2001" 2004 "2004" 2007 "2007" 2010 "2010" 2013 "2013" 2016 "2016" 2019 "2019" 2022 "2022", angle(0) labsize(vsmall) glcolor(gs9%0) labcolor(gs6) tlength(0) tlcolor(gs6%30)) ///
ytitle("") ///
yscale(lstyle(none) range(.83 .87)) ///
ylabel(none) ///
legend(off) ///
note("Source: {fontface Lato:Author's analysis of IPUMS-CPS.} Sample: {fontface Lato:U.S. adult household residents (person measure) or householders (household measure).}" `notes', margin(l+1.5) color(gs7) span size(1.75) position(7)) ///
caption("@jamesohawkins {fontface Lato:with} youngamericans.berkeley.edu", margin(l+1.5 t-1) color(gs7%50) span size(1.75) position(7)) ///
graphregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium)) ///
plotregion(margin(l+1 r+1 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium)) ///
graphregion(margin(r+3))
cd "$directory\output"
graph export ownratio_alladults.png, replace


/// ============================================================================
**# 6. Comparison of SCF and CPS Homeownership (Alternative Young Adult Age Group)
/// ============================================================================
/*  In this section, I compare homeownership rates by age groups (with an 
    alternative grouping of young adults between ages 25-39 years old) in the 
	CPS and Survey of Consumer Finances (SCF) based on alternative definitions 
	of homeownership in the CPS, dependent on treatment of partners of the 
	household reference person in the CPS. */

// Estimate alternative homeownership rates
// -----------------------------------------------------------------------------
/* In this sub-section, I calculate alternative homeownership rates based on an
   SCF household measure, CPS household measure, and CPS person measure over 
   time and across binned age groups. */

// SCF: household measure
cd "$directory\derived-data"
use scf_summaryunified.dta, clear
** restrict sample to adult records
keep if agehh >= 18
** estimate homeownership rates (separately by implicate, but this will not matter for rates)
collapse (mean) ownhh_scf = ownhh [pw = weight], by(agegroup_alt year implicate)
collapse (mean) ownhh_scf, by(agegroup_alt year)
** save
tempfile ownhh_scf
save `ownhh_scf'.dta, replace

// CPS: household measure
cd "$directory\derived-data"
use cps_wrangled.dta if inlist(year, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019, 2022), clear
** restrict to heads of households
keep if relate == 101
** estimate homeownership rates
collapse (mean) ownhh_cps = ownhh [pw = asecwth], by(agegroup_alt year)
** temporary save
tempfile ownhh_cps
save `ownhh_cps'.dta, replace

// CPS: person measure
use cps_wrangled.dta if inlist(year, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019, 2022), clear
* estimate homeownership rates
collapse (mean) ownp1_cps = ownp1 ownp2_cps = ownp2 ownp3_cps = ownp3 [pw = asecwt], by(agegroup_alt year)
** temporary save
tempfile ownp_cps
save `ownp_cps'.dta, replace

// Combine estimates
use `ownhh_scf'.dta, clear
merge 1:1 agegroup_alt year using `ownhh_cps'.dta, nogen
merge 1:1 agegroup_alt year using `ownp_cps'.dta, nogen

// Define ratios of different ownership measures
** scf household to cps household ratio
gen ratio_ownhh = ownhh_scf / ownhh_cps
** preferred cps person to cps household ratio
gen ratio1_owncps = ownp1_cps / ownhh_cps
** cps person to scf household ratios
gen ratio1 = ownp1_cps / ownhh_scf
gen ratio2 = ownp2_cps / ownhh_scf
gen ratio3 = ownp3_cps / ownhh_scf

// Export results
cd "$directory\output"
export delimited own_altyoungadults.csv, replace

// Visualization: Ratio of CPS person measure to SCF household measure (alternative age specifications)
// -----------------------------------------------------------------------------
* chart notes
linewrap, maxlength(180) name("notes") stack longstring("In this figure I report the ratio of various person-level CPS homeownership relative to the SCF household measure of homeownership. The first (preferred) measure defines homeowners as 1) any reference person (aka householder) in a dwelling that is owned and 2) the spouse/partner of a reference person in a dwelling that is owned. All other persons are considered non-owners. The second measure is equivalent to the first measure but also includes individuals as owners if they are designated as partner/roommates in 1989 and 1992 and the respective reference person of the household is an owner. Finally, the third measure is equivalent to the first measure but excludes any partners as potential owners.")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
if `y' < 5 {
	local notes = `"`notes' """'
}
* graph
twoway (connected ratio3 year, mcolor("238 31 96") msize(small) msymbol(triangle) lcolor("238 31 96") lpattern(solid)) ///
(connected ratio2 year, mcolor("221 213 199") msize(small) msymbol(circle) lcolor("221 213 199") lpattern(solid)) ///
(connected ratio1 year, mcolor("59 126 161") msize(vsmall) msymbol(square) lcolor("59 126 161") lpattern(solid)) ///
, ///
by(agegroup, rows(1) imargin(vsmall)) ///
by(, title("Comparing survey measures of homeownership (alt. age groups)", color("0 50 98") size(large) pos(11) justification(left) lwidth(thin))) ///
by(, subtitle("Ratio of CPS person measures to SCF household measure of homeownership rates, by age group", color("59 126 161") size(small) pos(11) justification(left))) ///
subtitle(,  color(white) size(vsmall) lcolor("59 126 161") fcolor("59 126 161")) ///
yline(1, lpattern(solid) lcolor("221 213 199")) ///
xtitle("", size(small) color(gs6) bmargin(zero)) xscale(lstyle(none)) ///
xlabel(1989 "1989" 1992 "1992" 1995 "1995" 1998 "1998" 2001 "2001" 2004 "2004" 2007 "2007" 2010 "2010" 2013 "2013" 2016 "2016" 2019 "2019" 2022 "2022", angle(45) labsize(tiny) glcolor(gs9%0) labcolor(gs6) tlength(1.25) tlcolor(gs6%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(.3 "0.3" .4 "0.4" .5 "0.5" .6 "0.6" .7 "0.7" .8 "0.8" .9 "0.9" 1 "1.0" 1.1 "1.1", angle(0) gmax gmin glpattern(solid) glcolor(gs9%15) glwidth(vthin) labcolor("59 126 161") labsize(2.5) tlength(0) tlcolor(gs9%15)) ///
legend(order(3 "1. Ratio with Preferred CPS Measure" 2 "2. Ratio with CPS Partners/Roommates" 1 "3. Ratio with CPS Spouses") rows(1) pos(12) bmargin(zero)) ///
by(, legend(order(3 "1. Ratio with Preferred CPS Measure" 2 "2. Ratio with CPS Partners/Roommates" 1 "3. Ratio with CPS Spouses") pos(12) bmargin(zero))) ///
by(, note("Source: {fontface Lato:Author's analysis of IPUMS-CPS and the Survey of Consumer Finances.} Sample: {fontface Lato:U.S. adult household residents (person measure) or householders (household measure).}" `notes', margin(l+1.5) color(gs7) span size(1.75) position(7))) ///
by(, caption("@jamesohawkins {fontface Lato:with} youngamericans.berkeley.edu", margin(l+1.5 t-1) color(gs7%50) span size(1.75) position(7))) ///
by(, graphregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
by(, plotregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
by(, graphregion(margin(r+1)))
cd "$directory\output"
graph export ownratio_altage.png, replace