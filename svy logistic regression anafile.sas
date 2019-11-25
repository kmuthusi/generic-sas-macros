dm 'odsresults; clear; log; clear; out; clear';

* to remove all datasets from within the WORK folder;
proc datasets lib=work nolist kill; quit; run;

%let dir=C:\NHANES III\SAS;

* %let _missval=-100;

* print log to file;
proc printto log="&dir.\output\logs\svy_logistic_regression log file.txt" new; run;

* track program run time;
* program start time;
%let datetime_start = %sysfunc(TIME()) ;
%put START TIME: %sysfunc(datetime(),datetime14.);

* load data setup file;
%include "&dir.\setup\setup.sas";

* load required macros;
%include "&dir.\macros\svy_logistic_regression.sas";

* data steps ...;
data clean_nhanes;
set clean_nhanes;
domain_all=1;
freq=1;
label freq="Total";

* set values for refused to answer and don't know to missing;
if dmqmiliz=7 then dmqmiliz=.;
if dmqadfc=9 then dmqadfc=.;
if dmdborn4 in (77,99) then dmdborn4=.;
if dmdcitzn in (7,9) then dmdcitzn=.;
if dmdyrsus in (77,99) then dmdyrsus=.;
if dmdeduc2 in (7,9) then dmdeduc2=.;
if dmdmartl in (77,99) then dmdmartl=.;

/*
* replace missing values code with .;
	array a(*) _numeric_;
	do i=1 to dim(a);
	if a(i) = &_missval then a(i) = .;
	end;
	drop i;
*/
run;

proc corr data=clean_nhanes spearman;
var riagendr ridageyrcat ridreth1 ridexmon dmqmiliz dmqadfc dmdborn4 dmdeduc2 dmdmartl;
run;

* call svy_logistic_regression macro;
option mlogic mprint symbolgen;

* initialize outcome variable;
%let outcome = lbxha;
%let outevent= Positive;
%let data = clean_nhanes;

* define simple logistic regression model input parameters;
%let classvarb= riagendr(ref="Male") ridageyrcat2 (ref=">= 60") ridreth1 (ref="Non-Hispanic White") 
				dmqadfc (ref="No") dmdeduc2 (ref="College graduate or above") dmdmartl (ref="Separated");

%let catvarsb = riagendr ridageyrcat2 ridreth1 dmqadfc dmdeduc2 dmdmartl;
%let contvarsb= ridageyr;

* fit simple logistic regression model;
%svy_unilogit ( dataset 		= &data., 
		outcome 		= &outcome.,
		outevent		= &outevent.,
		catvars	 		= &catvarsb., 
		contvars		= &contvarsb.,
		class 			= &classvarb., 
		weight			= wtmec2yr,
		cluster			= sdmvpsu,
		strata			= sdmvstra,
		domain			= dmqmiliz,
		domvalue		= 1,
		varmethod		= ,
		rep_weights_values	= ,
		varmethod_opts		= ,
		missval_opts		= ,
		missval_lab		= -100,
		condition 		= if ridageyr>=20,
		pvalue_decimal		= 4,
		or_decimal		= 3,
		print			= YES); 

* define parameters for selected predictor variables;
%let classvarm= riagendr(ref="Male") ridageyrcat2 (ref=">= 60") ridreth1 (ref="Non-Hispanic White") 
				dmqadfc (ref="No") dmdmartl (ref="Separated");
%let catvarsm = riagendr ridageyrcat2 ridreth1 dmqadfc dmdmartl;
%let contvarsm=;

* fit multiple logistic regression model;
%svy_multilogit (dataset 		= &data., 
		outcome 		= &outcome.,
		outevent		= &outevent.,
		catvars	 		= &catvarsm., 
		contvars		= &contvarsm.,
		class 			= &classvarm., 
		weight			= wtmec2yr,
		cluster			= sdmvpsu,
		strata			= sdmvstra,
		domain			= dmqmiliz,
		domvalue		= 1,
		varmethod		= ,
		rep_weights_values	= ,
		varmethod_opts		= ,
		missval_opts		= ,
		missval_lab		= -100,
		condition 		= if ridageyr>=20,
		pvalue_decimal		= 4,
		or_decimal		= 3,
		print			= YES); 

* output final table;
%svy_printlogit(tablename	= logit_table,
		outcome		= &outcome.,
		outevent	= &outevent.,
		outdir		= &dir.\output\tables, 
		tabletitle	= Table 2: Factors associated with Hepatitis A prevalence among participants who served in the US Armed Forces - NHANES 2013-2014);

* program end time;
%put END TIME: %sysfunc(datetime(),datetime14.);
%put PROCESSING TIME:  %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&datetime_start.),mmss.)) (mm:ss);

* reset print to log;
proc printto; run;
