dm 'odsresults; clear; log; clear; out; clear';

* to remove all datasets from within the WORK folder;
proc datasets lib=work nolist kill; quit; run;

* set working directory;
%let dir=C:\NHANES III\SAS;

* set output directory;
%let outdir=&dir.\output\tables;

proc printto log="&dir.\output\logs\svy_freqs log.log" new; run;

* program start time;
%let datetime_start = %sysfunc(TIME()) ;
%put START TIME: %sysfunc(datetime(),datetime14.);

* load setup file;
%include "&dir.\setup\setup.sas";

* load required macros;
%include "&dir.\macros\svy_freqs_jrr_dev_10_18_19.sas";
*%include "&dir.\macros\svy_freqs_jrr_dev.sas";

* data steps ...;
data clean_nhanes;
	set clean_nhanes;
	domain_all=1;
	total=1;

	* replace missing values code with .;
	/*
	array a(*) _numeric_;
	do i=1 to dim(a);
		if a(i) = -100 then a(i) = .;
	end;
	drop i;
	*/
run;

* call main macro;
option mlogic mprint symbolgen;

* Table 1: Distribution of socio-demographic characteristics by Hepatitis A status;
%let fvars=ridageyrcat2 ridreth1 dmqadfc lbxha;
%let cvars=ridageyr;
%let tablename=svy_freq_table_1;
%let title =Table 1: Distribution of socio-demographic characteristics by Hepatitis A status;

%svy_freqs(_data=clean_nhanes,
		   _outcome=,
		   _outvalue=,
		   _factors=&fvars.,
		   _contvars=&cvars.,
		   _byvar=riagendr,
		   _domain=dmqmiliz,
		   _domainvalue=1,
		   _strata=sdmvstra,
		   _cluster=sdmvpsu,
           _weight=wtmec2yr,
		   _varmethod=,
		   _rep_weights_values=,
		   _varmethod_opts=,
		   _missval_lab=-100,
		   _missval_opts=missing,
		   _idvar=seqn,
		   _cat_type=col,
		   _cont_type=median,
		   _condition=if ridageyr>=20,
		   _title=&title.,
		   _tablename=&tablename.,
		   _surveyname=NHANES,
		   _outdir=&outdir.,
		   _print=YES);

* Table 2: Socio-demographic characteristics by Hepatitis A status;
%let fvars=riagendr ridageyrcat2 ridreth1 dmqadfc;
%let cvars=ridageyr;
%let tablename=svy_freq_table_2;
%let title =Table 2: Socio-demographic characteristics by Hepatitis A status;

%svy_freqs(_data=clean_nhanes,
		   _outcome=total,
		   _outvalue=1,
		   _factors=&fvars.,
		   _contvars=&cvars.,
		   _byvar=lbxha,
		   _domain=dmqmiliz,
		   _domainvalue=1,
		   _strata=sdmvstra,
		   _cluster=sdmvpsu,
           _weight=wtmec2yr,
		   _varmethod=,
		   _rep_weights_values=,
		   _varmethod_opts=,
		   _missval_lab=-100,
		   _missval_opts=missing,
		   _idvar=seqn,
		   _cat_type=row,
		   _cont_type=median,
		   _condition=if ridageyr>=20,
		   _title=&title.,
		   _tablename=&tablename.,
		   _surveyname=NHANES,
		   _outdir=&outdir.,
		   _print=YES);

* Table 3: Distribution of Hepatitis A prevalence by selected socio-demographic characteristics and sex;
%let fvars=ridageyrcat2 ridreth1 dmqadfc;
%let cvars=ridageyr;
%let tablename=svy_freq_table_3;
%let title =Table 3: Distribution of Hepatitis A prevalence by selected socio-demographic characteristics and sex;

%svy_freqs(_data=clean_nhanes,
		   _outcome=lbxha,
		   _outvalue=1,
		   _factors=&fvars.,
		   _contvars=&cvars.,
		   _byvar=riagendr,
		   _domain=dmqmiliz,
		   _domainvalue=1,
		   _strata=sdmvstra,
		   _cluster=sdmvpsu,
           _weight=wtmec2yr,
		   _varmethod=,
		   _rep_weights_values=,
		   _varmethod_opts=,
		   _missval_lab=-100,
		   _missval_opts=missing,
		   _idvar=seqn,
		   _cat_type=prev,
		   _cont_type=median,
		   _condition=if ridageyr>=20,
		   _title=&title.,
		   _tablename=&tablename.,
		   _surveyname=NHANES,
		   _outdir=&outdir.,
		   _print=YES);

* program end time;
%put END TIME: %sysfunc(datetime(),datetime14.);
%put PROCESSING TIME:  %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&datetime_start.),mmss.)) (mm:ss);

* reset print to log;
proc printto; run;

