# Surveyor Database Toolkit

Stata Module for managing the IPA Ghana Surveyor Database


## Overview

IPA Ghana Database is a collection of information and evaluation scores of field staff. Which is mainly used
for the purpose of recruitment at IPA. This toolkit is intended for internal use only at IPA-Ghana. The Module
contains the following subcmds: 
* update    : Updates availability status of field staff using the CRF form
* append    : Appends new performance data to surveyor database using CRF and FMO 
* summarize : Summarize database and output useful statistics
* select    : Selects internal candidates using RRF

## Installation (Beta)

```stata
net install surveyordb, all replace ///
	from("https://raw.githubusercontent.com/iabaako/surveyordb-toolkit/master/ado")
```

## Syntax
```stata
* surveyordb update

surveyordb update using filename, REQuest(string) [sheet(string)] save(string) [replace]

options
	REQuest 		- Contract Request Form
	sheet	 		- Request SHeet. If not specified "Request" is assumed
	save		 	- save updated database as
	replace			- Replace if filename in save already exist

* Use dialog box
db surveyordb_update

* surveyordb append

surveyordb append using filename, REQuest(string) [sheet(string)] FMOutput(string) save(string) [replace]

options
	REQuest 		- Contract Request Form
	sheet	 		- Request SHeet. If not specified "Request" is assumed
	FMOutput		- Field Monitoring Output
	save		 	- save updated database as
	replace			- Replace if filename in save already exist

* use dialog box
db surveyordb_append

```


Please report all bugs/feature request to the [github issues page](https://github.com/PovertyAction/high-frequency-checks/issues)