*************************************************************************
* v2.0.0, 27mar2021 
* valGH 
* CO: GHANA
* Purpose: List of locals required for Ghana
*************************************************************************


* CONTRACT REQUEST FORM

* CRF vars to keep

	#d;
	gl crf_vars
		"
		type
		firstname middlename lastname fullname popularname 
		gender	
		education	
		phone1 phone2 email	
		region district	town	
		nhisid nhis_expires	
		id_type	id_number
		uniqueid		
		role
		contract_start contract_end		
		"
	;
	#d cr

* start row to import
	
	gl 	crf_startcell "A14"

* rows for project details 
	
	gl 	crf_projcellrange "A1:B11"

* rows to import from project details section

	gl 	crf_projrows "3 4 5 9 10"

* varnames of rows in project details
	
	#d;
	gl 	crf_projvars
		"project_acronym 
		project_head 
		project_manager 
		project_phase 
		field_office"
	;
	#d cr


* define values for database variables

	#d;
	gl  sdb_role 
		""SURVEYOR" 
		 "AUDITOR (FIELD/PHONE)" 
		 "AUDITOR (AUDIO)" 
		 "EDITOR" 
		 "NOTE TAKER" 
		 "FACILITATOR" 
		 "INDEPTH INTERVIEWER" 
		 "OBSERVER" 
		 "VIDEO CODER" 
		 "TRANSCRIPTIONIST" 
		 "TRANSLATOR" 
		 "DATA ENTRY OFFICER" 
		 "TEAM LEADER" 
		 "FIELD SUPERVISOR" 
		 "MOBILIZER" 
		 "CHILD MEASUREMENT" 
		 "ASSESSOR""
		;
	
	gl  sdb_gender 
		""MALE" 
		 "FEMALE""
		;
	
	gl  sdb_education 
		""BECE"
		"SSCE"
		"CERTIFICATE"
		"DIPLOMA"
		"HND"
		"BACHELORS"
		"MASTERS" 
		"DOCTORATE""
		;

	gl  sdb_proficiency 
		""None" 
		 "Elementary" 
		 "Limited Working" 
		 "Minimum Professional" 
		 "Full Professional" 
		 "Native""
		;
		
	gl  sdb_paper_or_capi 
		""PAPER" 
		 "CAPI" 
		 "PAPER/CAPI""
		;

	gl  sdb_interview_mode 
		""IN-PERSON" 
		 "ON PHONE" 
		 "IN-PERSON/ON PHONE""
		;

	gl  sdb_quantitative_or_qualitative 
		""QUANTITATIVE" 
		 "QUALITATIVE" 
		 "QUANTITATIVE/QUALITATIVE""
		;
	#d cr
