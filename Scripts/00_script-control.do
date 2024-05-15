////////////////////////////////////////////////////////////////////////////////
// Do File: 00_script-control.do
// Primary Author: James Hawkins, Berkeley Institute for Young Americans
// Date: 5/15/24
// Stata Version: 17
// Description: From this script, you can reproduce all of the output for the 
// accompanying brief "Are Wealth Data Representative of Young Adults?" 
// Total script runtime is 131 seconds on an 11th Gen Intel i7 @ 3.00GHz.
// 
// The script is separated into the following sections:
// 		1. Miscellaneous Set Up
//		2. Execute Scripts
////////////////////////////////////////////////////////////////////////////////
timer on 1

/// ============================================================================
**# 1. Miscellaneous Set Up
/// ============================================================================
/*  In this section, I define the random number seeds, the local directory of 
    the repository, set up the python environment for use with IPUMS API, and 
	provide code to set a user's IPUMS API key (in my own analysis, I use a 
	profile.do script to establish the IPUMS API key each time Stata starts). */
	
// Random number seeds
// -----------------------------------------------------------------------------
set seed 43716732
set sortseed 20231964


// Set directory for repository
// -----------------------------------------------------------------------------
global directory "" // enter your own directory here

// Set up python (only applicable if using IPUMS API)
// -----------------------------------------------------------------------------
python query
set python_exec "" // enter your own python directory here

// Set IPUMS API key
// -----------------------------------------------------------------------------
/* NOTE: To set up an API key to access IPUMS API, follow these instructions:
   https://developer.ipums.org/docs/v2/get-started/. To define your API key,
   uncomment the following line and replace "INSERT HERE" with your API key.
   Alternatively, create a profile.do script that defines the API key by 
   following these instructions: 
   https://www.stata.com/manuals/gswb.pdf#B.3ExecutingcommandseverytimeStataisstarted 
   */
** global MY_API_KEY "INSERT HERE" // if not using a profile.do script, uncomment this line and enter your own API key here


/// ============================================================================
**# 2. Execute Scripts
/// ============================================================================
/*  In this sub-section, I execute the scripts necessary to reproduce my 
    analysis of SCF and CPS homeownership rates. */

// Execute data wrangling script
cd "$directory\scripts"
do 01_wrangling.do

// Execute data analysis script
cd "$directory\scripts"
do 02_analysis.do

timer off 1
timer list 1
noi display as text "Runtime was " as result %3.2f `=r(t1)/60' " minutes"