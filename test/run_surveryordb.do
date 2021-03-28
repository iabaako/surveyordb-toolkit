clear all
cls

net install surveyordb, all replace from("C:\Users\Ishamial Boako\Documents\github\sdb_release2\surveyordb-toolkit\src")
/*
surveyordb update using "../testfiles_ignore/datatase/17_surveyor_database_20210219_mb.dta", ///
	crf("../testfiles_ignore/crf/Contract Request Form_IDS_training_20201209.xlsm") ///
	save("../testfiles_ignore/datatase/17_surveyor_database_20210327_iab") ///
	co(GH) replace

surveyordb update using "../testfiles_ignore/datatase/17_surveyor_database_20210219_mb.dta", ///
	crf("../testfiles_ignore/crf/Contract Request Form_QP4G_UKRI_2020.xlsm") ///
	save("../testfiles_ignore/datatase/17_surveyor_database_20210327_iab") ///
	co(GH) replace

surveyordb update using "../testfiles_ignore/datatase/17_surveyor_database_20210219_mb.dta", ///
	crf("../testfiles_ignore/crf/031_STS Contract Request_EP Endline Survey_NR.xlsx") ///
	save("../testfiles_ignore/datatase/17_surveyor_database_20210327_iab") ///
	co(GH) replace
*/
surveyordb append using "../testfiles_ignore/datatase/17_surveyor_database_20210219_mb.dta", ///
	crf("../testfiles_ignore/crf/031_STS Contract Request_EP Endline Survey_NR.xlsx") ///
	fmo("../testfiles_ignore/fmo/018_ep_endline_monreport_final_my.xlsx") ///
	save("../testfiles_ignore/datatase/17_surveyor_database_20210327_iab") ///
	co(GH) replace


/*
surveyordb select using "17_surveyor_database_20210219_mb.dta", ///
	request("Recruitment Request Form  Tracta Endline_IA.xlsm") ///
	exclude(SurveyorDB_unavailable_2021.xlsx) ///
	outfile(sample_shortlist.xlsx) replace
*/
