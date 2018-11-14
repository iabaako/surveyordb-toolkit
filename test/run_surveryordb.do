clear all

net install surveyordb, all replace from("C:\Users\Ishamial Boako\Box Sync\git\surveyordb-toolkit/ado")

/* set trace on
surveyordb append using "X:\Box\IPA_GHA_SCs-DMs private folder\Surveyor_Database\00_Archive\Merged Databases/surveyor_database_combined", ///
	req("contract request/sts_cq_ep_ipvs_northern") fmoutput("fmo_ipvs_northern.xlsx") save(newdatabase) replace
