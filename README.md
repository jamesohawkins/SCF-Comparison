# SCF Comparison
![](https://github.com/jamesohawkins/SCF-Comparison/blob/main/Output/own_surveyXage.png)

This repository contains all necessary raw data and Stata scripts for replicating the results from the analysis of the Current Population Survey (CPS) and the Survey of Consumer Finances (SCF) contained in the [accompanying issue brief](youngamericans.berkeley.edu/scf-comparison). This repository also includes all output and accompanying estimates.

## Repository Structure

### [Scripts](https://github.com/jamesohawkins/SCF-Comparison/tree/main/Scripts)
The Stata scripts for this repository can be found in the scripts folder. All scripts for this repository can be run from 00_script-control.do. To run these scripts, users will need to set their directory in 00_script-control.do. Furthermore, users will need to set up Python and define their IPUMS API key in 00_script-control.do if they intend to access IPUMS-CPS data via the API (see [Raw-data](#raw-data)).

### [Raw-data](https://github.com/jamesohawkins/SCF-Comparison/tree/main/Raw-Data)
I use data from the CPS via [IPUMS-CPS](https://cps.ipums.org/cps/) and SCF (summary public data) via the [Federal Reserve](https://www.federalreserve.gov/econres/scfindex.htm). Access to IPUMS-CPS requires creating an account and agreeing to their user agreement. They also place restrictions on publicly disseminating their data; therefore, replication of this analysis requires accessing CPS data either through the [IPUMS API](https://developer.ipums.org/docs/v2/apiprogram/) (the method implemented in my scripts) or directly through the IPUMS-CPS extract system. If the latter method is used, the user can ignore code in section 1A of 01_wrangling.do and edit the script to directly access their own IPUMS-CPS extract.

### [Derived-data](https://github.com/jamesohawkins/SCF-Comparison/tree/main/Derived-Data)
Empty folder where wrangled data is stored.

### [Output](https://github.com/jamesohawkins/SCF-Comparison/tree/main/Output)
Contains all output (visualizations and csv files) from the analysis.
