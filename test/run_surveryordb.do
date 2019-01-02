clear all
cls

net install surveyordb, all replace from("C:\Users\Ishamial Boako\Box Sync\git\surveyordb-toolkit/ado")

surveyordb select using "X:\Box\IPA_GHA_SCs-DMs private folder\Surveyor Database New\01_database/006_surveyor_database_181207", ///
	request(C:\Users\Ishamial Boako\Box Sync\git\surveyordb-toolkit\excel/Recruitment Request Form.xlsm) ///
	outfile(C:\Users\Ishamial Boako\Box Sync\git\surveyordb-toolkit\test/outfile.xlsx) replace
