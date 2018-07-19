
**************************************************************************************
**************************************************************************************
** Filename     : svy_freq.sas                                                 		**
**				                                            						**
** Author       : Muthusi, Jacques                        Date: 19JUL2016      		**
**				                                            						**
** Platform     : Windows                                                      		**
**				                                            						**
** Description  : Generic macro to create publication ready table of  				**
** 				  crosstabulation between a factor and a by group variable given a  **
**				  third variable using survey/non-survey data. It also recodes		**
**				  variables with character values to numeric values					**
**				                                            						**
** Macros used  : %svy_col 	  - macro to perform crosstabulation between a factor 	**
**				                and by a group variable and output COL%				**
**  			: %svy_row 	  - macro to perform crosstabulation between a factor 	**
**				             	and by a group variable  and output ROW%			**
** 				: %svy_prev   - macro to perform crosstabulation between a factor 	**
**				                and by a group variable given a third variable 		**
**								and output ROW% (PREVALENCE)						**
** 				: %svy_median - macro to perform MEDIAN statistics for a continuous **
**				             	variable and a by group variable					**
** 				: %svy_mean	  - macro to perform MEAN statistics for a continuous	**
**				             	variable and a by group variable					**
**				: %charvar 	  - macro to recode variables with character 			**
** 				  			 	values to numeric values							**
**				: %distcolval - macro to get one instance of repeated values		**
**				                                            						**
** Input        : Any dataset                                            			**
**				                                            						**
** Output       : Publication ready table of cross tabulation in MS Word and Excel	**
**				                                            						**
** Assumptions  :                                                               	**
**																					**
** Macro parameters:																**
**		_data		 = input dataset,												**
**		_condition	 = (optional) any conditional statements to create /fine-tune	**
**					   final analysis dataset,										**
**		_outcome	 = the third variable of interest e.g, HIV status,				**
**		_outvalue	 = the value of third variable e.g., for HIV status 			**
**					   we are interested in the positive outcome which is 			**
**					   coded as 1,													**
**		_factors	 = list of factor variables (separated by space) that 			**
**					   goes to the rows,											**
**		_contivars	 = list of continuous variables (separated by space) that 		**
**					   goes to the rows as well,									**
**		_byvar		 = by group variable that goes to the columns,					**
**		_domain		 = sub-population (domain) variable of interest,				**
**		_domainvalue = the value of domain variable of interest 					**
**		_strata		 = (optional) survey stratification variable,					**
**		_cluster	 = (optional) survey clustring variable,						**
**		_weight		 = (optional) survey weighting variable,						**
**		_idvar		 = unique subject (participant) identifier,						**
**		_cat_type	 = type of analysis for categorical variables (ROW=row, 		**
**					   COL=col, PREV=prevalence),									**
**		_cont_type	 = type of analysis for continuous variables (MEAN=for mean,    **
**					   MEDIAN=for median),											**
**		_title		 = title of output table,										**
**		_tablename	 = shortname of output table,									**
**		_surveyname	 = shortname of survey name,									**
**		_print		 = variable for displaying/suppressing the output table 		**
**					   on the output window (NO=suppress, YES=show),				**
**				                                            						**
** Example call:																	**
**	%svy_freqs ( _data			=kais_final,										**
**				 _condition		=,													**
**				 _outcome		=freq,												**
**				 _outvalue		=1,													**
**				 _factors		=agecat resid educ marital constcd,					**
**				 _contvars		=age,												**
**				 _byvar			=sex,												**
**				 _domain		=hiv,												**
**				 _domainvalue	=1,													**
**				 _strata		=strata,											**
**				 _cluster		=cluster,											**
**	             _weight		=bl_weight,											**
**				 _idvar			=pid,												**
**				 _analysis		=prev,												**
**				 _title			=Table 1: Prevalence of HIV among sampled clients,	**
**				 _tablename		=kais_row,											**
**				 _print			=YES);												**
**																					**
** Validation history                                                         		**
**       Validated by : Muthusi, Jacques                  Date: 19AUG2016  	    	**
**																					**
** Modification history                                                    	    	**
**       Modified by  : Muthusi, Jacques                  Date: 16OCT2017       	**
**                                                                         	    	**
**						Fixed %charvar macro										**
**                                                                         	    	**
**************************************************************************************
**************************************************************************************;

options mlogic mprint symbolgen;

* helper macro to test for error and exit if so -PWY;
%macro runquit;
  ; run; quit;
  %if &syserr. ne 0 %then %do;
     %abort cancel;
  %end;
%mend runquit;

%macro svy_freqs(_data=,
				 _condition=,
				 _outcome=,
				 _factors=,
				 _contvars=,
				 _byvar=,
				 _missval=.,
				 _outvalue=,
				 _domain=,
				 _domainvalue=,
				 _strata=,
				 _cluster=,
                 _weight=,
				 _idvar=,
				 _cat_type=,
				 _cont_type=,
				 _title=,
				 _tablename=,
				 _surveyname=,
				 _outdir=,
				 _print=);

data _dataset re_dataset xx_dataset _final_report_freq _report_freq _final_report_cont _report_cont _final_report ; run;

%* prepare dataset;
data _dataset;
set &_data;
	&_condition;
	%if &_domain eq %then %do; 
		domain_all=1;
		%let _domain=domain_all;
		%let _domainvalue=1;
	%end;
 	%if &_outcome eq %then %do; 
		freq=1;
		%let _outcome=freq;
	%end;
	%runquit;
run;


ods exclude all;

%* get number of row variables;
data _final_report_freq _report_freq; run;

data _null_;
i = 0;
do while (scanq("&_factors",i+1) ^= ''); i+1; end;
	call symput('no_factors', trim(left(i)));
run;

%* check for variables with character values and format/recode to numeric ones;
%let _allvars= &_outcome &_byvar &_factors ;

data _null_;
j = 0;
do while (scanq("&_allvars",j+1) ^= ''); j+1; end;
	call symput('no_allvars', trim(left(j)));
run;

%do xi = 1 %to &no_allvars;
    %let _allvar = %scan(&_allvars, &xi); 
		
		data _null_; set _dataset;
		 	call symput ("vartype", vtype(&_allvar));
		run;

		%if &vartype=C %then %do;
			%charvar(_data=_dataset, _allvar=&_allvar, _idvar=&_idvar);
		%end;
			
    %if &xi = 1 %then %do; 
		data re_dataset; 
			set _dataset;
		run; 
	%end;

    %else %do; 
    	proc sort data=_dataset; by &_idvar; run;
    	data re_dataset; 
			%if %sysfunc(exist(char_&_data)) %then %do;
				merge _dataset char_&_data;
				by &_idvar;
			%end;
			%else %do;
				set _dataset;
			%end;
		run; 
	%end;
%end;

data xx_dataset;
set _dataset;
	%do xi  =  1 %to &no_allvars;
	%if &vartype=C %then %do;
		drop &_allvar&xi;
		%end;
	%end;
	&_condition;
run;

proc sort data=re_dataset; by &_idvar; run;
proc sort data=xx_dataset; by &_idvar; run;

data xx_dataset;
merge xx_dataset(drop=&_allvar) re_dataset;
	by &_idvar;
run;

%* for categorical variables;
%do vi  =  1 %to &no_factors;
    %let _factor  =  %scan(&_factors,&vi);

%* for prevalence;
	%if %upcase(&_cat_type) = PREV %then %do;
		%svy_prev	(_data			= xx_dataset,
					 _outcome		= &_outcome,
					 _factor		= &_factor,
					 _byvar			= &_byvar,
					 _missval		= &_missval,
					 _outvalue		= &_outvalue,
					 _domain		= &_domain,
					 _domainvalue	= &_domainvalue,
					 _strata		= &_strata,
					 _cluster		= &_cluster,
	                 _weight		= &_weight);
	%end;

%* for row percentages;
	%if %upcase(&_cat_type) = ROW %then %do;
		%svy_row	(_data			= xx_dataset,
					 _outcome		= &_outcome,
					 _factor		= &_factor,
					 _byvar			= &_byvar,
					 _missval		= &_missval,
					 _outvalue		= &_outvalue,
					 _domain		= &_domain,
					 _domainvalue	= &_domainvalue,
					 _strata		= &_strata,
					 _cluster		= &_cluster,
	                 _weight		= &_weight);
	%end;

%* for column percentages;
	%if %upcase(&_cat_type) = COL %then %do;
		%svy_col(_data			= xx_dataset,
				 _outcome		= &_outcome,
				 _factor		= &_factor,
				 _byvar			= &_byvar,
				 _missval		= &_missval,
				 _outvalue		= &_outvalue,
				 _domain		= &_domain,
				 _domainvalue	= &_domainvalue,
				 _strata		= &_strata,
				 _cluster		= &_cluster,
                 _weight		= &_weight);
	%end;

    %if &vi = 1 %then %do; 
		data _final_report_freq; set _report_freq; 
		run; 
	%end;

    %else %do; 
		data _final_report_freq; set _final_report_freq _report_freq; 
		run; 
	%end;
%end;

%* for continuous variables get number of row variables;
data _final_report_cont _report_cont; run;

data _null_;
k = 0;
do while (scanq("&_contvars",k+1) ^= " "); k+1; end;
	call symput("no_contvars", trim(left(k)));
run;

%do vii  =  1 %to &no_contvars;
    %let _contvar  =  %scan(&_contvars,&vii); 
		%if %upcase(&_cont_type)=MEDIAN %then %do;

			%svy_median(_data		= xx_dataset,
						_outcome	= &_outcome,
						_outvalue	= &_outvalue,
						_contvar	= &_contvar,
						_missval	= &_missval,
						_byvar		= &_byvar,
					  	_domain		= &_domain,
					  	_domainvalue= &_domainvalue,
						_strata		= &_strata,
						_cluster	= &_cluster,
				        _weight		= &_weight);

		%end;

		%if %upcase(&_cont_type)=MEAN %then %do;
			%svy_mean(	_data		= xx_dataset,
						_outcome	= &_outcome,
						_outvalue	= &_outvalue,
						_contvar	= &_contvar,
						_missval	= &_missval,
						_byvar		= &_byvar,
					  	_domain		= &_domain,
					  	_domainvalue= &_domainvalue,
						_strata		= &_strata,
						_cluster	= &_cluster,
				        _weight		= &_weight);

		%end;

		%if &vii = 1 %then %do; 
		data _final_report_cont; set _report_cont; 
		run; 
	%end;
    %else %do; 
		data _final_report_cont; set _final_report_cont _report_cont; 
		run; 
	%end;
%end;

%* get domain size;
proc sql noprint;
	select count(*) into: nobs separated by ' ' from _temp_ 
	where &_domain = &_domainvalue and &_byvar ne &_missval and 
		%if %upcase(&_cat_type) = PREV %then %do; &_outcome ne &_missval %end;
		%else %do; &_outcome=&_outvalue %end;;
quit;

%global domsize;
%let domsize=&nobs;

%* merge data table from factors and medians;
data _final_report;
	%if %sysfunc(exist(_final_report_freq)) %then %do;
		set _final_report_freq _final_report_cont;
	%end;
	%else %do;
		set _final_report_cont;
	%end;
run;

%* create a reporting template;
proc sort data =xx_dataset; by &_byvar; run;

data _null_; set  xx_dataset; by &_byvar; 
if first.&_byvar and &_byvar ne &_missval then do;
	i+1;
	call symput("colvname"||trim(left(i)), "&_byvar._"||trim(left(&_byvar))); 
	call symput("collabel"||trim(left(i)), trim(left(vvalue(&_byvar))));
	call symput('no_cols', trim(left(i)));
	end;
run;

%if %upcase(&_print) = NO %then %do; ods exclude all; %end;
%else  %do; ods exclude none; %end;

%* define report template;
proc template;
define style KAIS;
parent = styles.printer;
replace fonts /
	"titlefont2" = ("Times New Roman", 11pt, Bold)
	"titlefont" = ("Times New Roman", 12pt, Bold)
	"strongfont" = ("Times New Roman", 10pt, Bold)
	"emphasisfont" = ("Times New Roman", 10pt, Bold)
	"fixedemphasisfont" = ("Times New Roman", 10pt, Bold)
	"fixedstrongfont" = ("Times New Roman", 10pt, Bold)
	"fixedheadingfont" = ("Times New Roman", 10pt, Bold)
	"batchfixedfont" = ("Times New Roman", 10pt, Bold)
	"fixedfont" = ("Times New Roman", 10pt, Bold)
	"headingemphasisfont" = ("Times New Roman", 10pt, Bold)
	"headingfont" = ("Times New Roman", 10pt, Bold)
	"docfont" = ("Times New Roman", 10pt);
end; 
run;

%* suppress macro options;
option nomprint nosymbolgen nomlogic nodate nonumber;

%* generate output table in MS Word and Excel using defined template;
ods escapechar = "^";
%* ods noresults; %* trying to suppress auto opening of files - PWY;
%* removed by muthusi - option already defined in the macro;

ods rtf file="&_outdir\&_tablename..rtf" style=KAIS;
ods tagsets.ExcelXP file="&_outdir\&_tablename..xls" style=KAIS;
ods tagsets.ExcelXP options(sheet_label="&_tablename" suppress_bylines="yes" embedded_titles="yes");

title "&_title" ", N=&domsize";
footnote height=8pt j=l "(Dated: &sysdate)" j=c "{\b\ Page }{\field{\*\fldinst {\b\i PAGE}}}" j=r "&_surveyname";

options papersize = A4 orientation = landscape;

%* output for prevalence tables;
%if %upcase(&_cat_type) = PREV %then %do;
proc report data=_final_report  headline split="*" missing spacing=1 nowd;
        column variable
        %do i  =  1 %to &no_cols;
        ("&&collabel&i."  N_&&colvname&i.  _c_&&colvname&i. _i_&&colvname&i) %end;
		("Total"  N_total_&_byvar _c_total_&_byvar _i_total_&_byvar);
		define variable 		/ display width = 30 right "Characteristic" flow;
        %do j=1 %to &no_cols;
        define N_&&colvname&j.  / display width=10 right "Unweighted * n/N" flow;
		define _c_&&colvname&j. / display width=10  center "Weighted * Prev. %" flow;
        define _i_&&colvname&j. / display width=20 center "95 % CI" flow;
        %end;
        define N_total_&_byvar  / display width=10 right "Unweighted * n/N" flow;
		define _c_total_&_byvar / display width=10  center "Weighted * Prev. %" flow;
        define _i_total_&_byvar / display width=20 center "95 % CI" flow;
run;
%end;

%else %do;
%* output for tables with continuous variables only;
%if %length(&_factors) = 0 %then %do;

%if %upcase(&_cat_type) = ROW %then %do;
proc report data=_final_report  headline split="*" missing spacing=1 nowd;
        column variable
        %do i  =  1 %to &no_cols;
        ("&&collabel&i."  N_&&colvname&i.  _c_&&colvname&i. _i_&&colvname&i) %end;;
		*("Total"  N_total_&_byvar _c_total_&_byvar _i_total_&_byvar);
		define variable 		/ display width = 30 right "Characteristic" flow;
        %do j=1 %to &no_cols;
        define N_&&colvname&j. 	/ display width=10 right "Unweighted * n/N" flow;
		define _c_&&colvname&j. / display width=10  center 
			%if %upcase(&_cont_type) = MEDIAN %then %do; "Weighted * Median" flow; %end;
			%if %upcase(&_cont_type) = MEAN %then %do; "Weighted * Mean" flow; %end;; 
		define _i_&&colvname&j. / display width=20 center 
			%if %upcase(&_cont_type) = MEDIAN %then %do; "IQR * " flow; %end;
			%if %upcase(&_cont_type) = MEAN %then %do; "95 % CI * " flow; %end;;
		* define breakvar/ ' ' style(column)={cellwidth=3%};
        %end;
        * define N_total_&_byvar  / display width=10 right "Unweighted * n/N " flow;
		* define _c_total_&_byvar / display width=10  center "Weighted %" flow;
        * define _i_total_&_byvar / display width=20 center "95 % CI" flow;
run;
%end;

%if %upcase(&_cat_type) = COL %then %do;
proc report data=_final_report  headline split="*" missing spacing=1 nowd;
        column variable
        %do i  =  1 %to &no_cols;
        ("&&collabel&i."  _n_&&colvname&i.  _c_&&colvname&i. _i_&&colvname&i) %end;
		("Total"  _n_total_&_byvar _c_total_&_byvar _i_total_&_byvar);
		define variable 		/ display width = 30 right "Characteristic" flow;
        %do j=1 %to &no_cols;
        define _n_&&colvname&j. / display width=10 right "Unweighted * n" flow;
		define _c_&&colvname&j. / display width=10  center 
			%if %upcase(&_cont_type) = MEDIAN %then %do; "Weighted * median" flow; %end;
			%if %upcase(&_cont_type) = MEAN %then %do; "Weighted * mean" flow; %end;; 
        define _i_&&colvname&j. / display width=20 center 
			%if %upcase(&_cont_type) = MEDIAN %then %do; "IQR" flow; %end;
			%if %upcase(&_cont_type) = MEAN %then %do; "95 % CI" flow; %end;;
		* define breakvar/ ' ' style(column)={cellwidth=3%};
        %end;
        define _n_total_&_byvar / display width=10 right "Unweighted * N" flow;
		define _c_total_&_byvar / display width=10  center 
			%if %upcase(&_cont_type) = MEDIAN %then %do; "Weighted * Median" flow; %end;
			%if %upcase(&_cont_type) = MEAN %then %do; "Weighted * Mean" flow; %end;; 
        define _i_total_&_byvar / display width=20 center 
			%if %upcase(&_cont_type) = MEDIAN %then %do; "IQR * " flow; %end;
			%if %upcase(&_cont_type) = MEAN %then %do; "95 % CI * " flow; %end;;
run;
%end;
%end;

%* output options for table with categorical variables only;
%if %length(&_contvars) = 0 %then %do;
%if %upcase(&_cat_type) = ROW %then %do;

proc report data=_final_report  headline split="*" missing spacing=1 nowd;
        column variable
        %do i  =  1 %to &no_cols;
        ("&&collabel&i."  N_&&colvname&i.  _c_&&colvname&i. _i_&&colvname&i) %end;;
		*("Total"  N_total_&_byvar _c_total_&_byvar _i_total_&_byvar);
		define variable 		/ display width = 30 right "Characteristic" flow;
        %do j=1 %to &no_cols;
        define N_&&colvname&j.  / display width=10 right "Unweighted * n/N" flow;
		define _c_&&colvname&j. / display width=10  center "Weighted % * " flow;
		define _i_&&colvname&j. / display width=20 center "95 % CI * " flow;
		* define breakvar/ ' ' style(column)={cellwidth=3%};
        %end;
        * define N_total_&_byvar  / display width=10 right "Unweighted * n/N " flow;
		* define _c_total_&_byvar / display width=10  center "Weighted %" flow;
        * define _i_total_&_byvar / display width=20 center "95 % CI" flow;
run;
%end;

%if %upcase(&_cat_type) = COL %then %do;
proc report data=_final_report  headline split="*" missing spacing=1 nowd;
        column variable
        %do i  =  1 %to &no_cols;
        ("&&collabel&i."  _n_&&colvname&i.  _c_&&colvname&i. _i_&&colvname&i) %end;
		("Total"  _n_total_&_byvar _c_total_&_byvar _i_total_&_byvar);
		define variable 		/ display width = 30 right "Characteristic" flow;
        %do j=1 %to &no_cols;
        define _n_&&colvname&j. / display width=10 right "Unweighted * n" flow;
		define _c_&&colvname&j. / display width=10  center "Weighted % * " flow;
	    define _i_&&colvname&j. / display width=20 center "95 % CI * " flow;
        %end;
        define _n_total_&_byvar / display width=10 right "Unweighted * N " flow;
		define _c_total_&_byvar / display width=10  center  "Weighted % * " flow;
        define _i_total_&_byvar / display width=20 center "95 % CI * " flow;
run;
%end;
%end;

%* output options for table containing both categorical and continuous variables;
%else %do;
%if %upcase(&_cat_type) = ROW %then %do;

proc report data=_final_report  headline split="*" missing spacing=1 nowd;
        column variable
        %do i  =  1 %to &no_cols;
        ("&&collabel&i."  N_&&colvname&i.  _c_&&colvname&i. _i_&&colvname&i) %end;;
		*("Total"  N_total_&_byvar _c_total_&_byvar _i_total_&_byvar);
		define variable / display width = 30 right "Characteristic" flow;
        %do j=1 %to &no_cols;
        define N_&&colvname&j.  / display width=10 right "Unweighted * n/N " flow;
		define _c_&&colvname&j. / display width=10  center 
			%if %upcase(&_cont_type) = MEDIAN %then %do; "Weighted % * (or Median)" flow; %end;
			%if %upcase(&_cont_type) = MEAN %then %do; "Weighted % * (or Mean)" flow; %end;; 
		define _i_&&colvname&j. / display width=20 center 
			%if %upcase(&_cont_type) = MEDIAN %then %do; "95 % CI * (or IQR)" flow; %end;
			%if %upcase(&_cont_type) = MEAN %then %do; "95 % CI * " flow; %end;;
		* define breakvar/ ' ' style(column)={cellwidth=3%};
        %end;
        * define N_total_&_byvar  / display width=10 right "Unweighted * n/N " flow;
		* define _c_total_&_byvar / display width=10  center "Weighted %" flow;
        * define _i_total_&_byvar / display width=20 center "95 % CI" flow;
run;
%end;

%if %upcase(&_cat_type) = COL %then %do;
proc report data=_final_report  headline split="*" missing spacing=1 nowd;
        column variable
        %do i  =  1 %to &no_cols;
        ("&&collabel&i."  _n_&&colvname&i.  _c_&&colvname&i. _i_&&colvname&i) %end;
		("Total"  _n_total_&_byvar _c_total_&_byvar _i_total_&_byvar);
		define variable / display width = 30 right "Characteristic" flow;
        %do j=1 %to &no_cols;
        define _n_&&colvname&j. / display width=10 right "Unweighted * n " flow;
		define _c_&&colvname&j. / display width=10  center 
			%if %upcase(&_cont_type) = MEDIAN %then %do; "Weighted % * (or median)" flow; %end;
			%if %upcase(&_cont_type) = MEAN %then %do; "Weighted % * (or mean)" flow; %end;; 
        define _i_&&colvname&j. / display width=20 center 
			%if %upcase(&_cont_type) = MEDIAN %then %do; "95 % CI * (or IQR)" flow; %end;
			%if %upcase(&_cont_type) = MEAN %then %do; "95 % CI * " flow; %end;;
		* define breakvar/ ' ' style(column)={cellwidth=3%};
        %end;
        define _n_total_&_byvar / display width=10 right "Unweighted * N " flow;
		define _c_total_&_byvar / display width=10  center 
			%if %upcase(&_cont_type) = MEDIAN %then %do; "Weighted % * (or median)" flow; %end;
			%if %upcase(&_cont_type) = MEAN %then %do; "Weighted % * (or mean)" flow; %end;; 
        define _i_total_&_byvar / display width=20 center 
			%if %upcase(&_cont_type) = MEDIAN %then %do; "95 % CI * (or IQR)" flow; %end;
			%if %upcase(&_cont_type) = MEAN %then %do; "95 % CI * " flow; %end;;
run;
%end;
%end;
%end;

footnote;
title;
ods tagsets.excelxp close;
ods rtf close;

ods exclude none;

%mend svy_freqs;

%* main cross tabulation macro for column percentages;
%macro svy_col(	_data=,
				_condition=,
				_outcome=,
				_outvalue=,
				_factor=,
				_byvar=,
				_missval=,
				_domain=,
				_domainvalue=,
				_strata=,
				_cluster=,
                _weight=);

%* clean temporary datasets;
data _temp_ Crosstab1 Crosstabtotal1 Crosstabtotal Crosstab totals merged final xtab0 xtab1 _merge _merge_level _merge_total _merge_varname _report_freq; run;

%* finetuning the data;
data _temp_;
set &_data;
	if &_byvar ne &_missval;
run;

%* create the cross-tabluation table;
ods output CrossTabs=Crosstab1;
proc surveyfreq data=_temp_;  

%* apply if survey design if specified; 
 	%if &_strata ne %then %do;  
		stratum &_strata;
	%end;
	%if &_cluster ne %then %do;  
		cluster &_cluster;
	%end;
	%if &_weight ne %then %do;  
		weight  &_weight;
	%end;
		tables  &_domain*&_byvar*&_factor*&_outcome/col cl chisq; 
run;

%* create the cross-tabluation totals;
ods output CrossTabs=Crosstabtotal1;
proc surveyfreq data=_temp_;  
 
%* apply if survey design if specified; 
 	%if &_strata ne %then %do;  
		stratum &_strata;
	%end;
	%if &_cluster ne %then %do;  
		cluster &_cluster;
	%end;
	%if &_weight ne %then %do;  
		weight  &_weight;
	%end;
		tables  &_domain*&_factor*&_outcome/col cl; 
run;

data Crosstabtotal;
set Crosstabtotal1;
	f_&_factor=vvalue(&_factor);
run;

data Crosstabtotal;
set Crosstabtotal;
	if &_factor = . then f_&_factor ="Total";
run;

data Crosstab;
set Crosstab1 Crosstabtotal;
proc sort;
	by f_&_factor;
run;

data Crosstab;
set Crosstab;
	f_&_byvar=vvalue(&_byvar);
	if &_byvar = . then f_&_byvar ="Total";
run;

%* create total for each rows;
data totals (keep=f_&_byvar freqtot);
	set crosstab(rename=(frequency=freqtot));
		if f_&_factor = "Total" and &_outcome=&_outvalue then output;
proc sort;
by f_&_byvar;
run;

proc sort data=Crosstab;
	by f_&_byvar;
run;

%* merge back with the frequency table to adds "Totals" back to surveyfreq ods ouput;
data merged;
	merge totals crosstab ; 
		by f_&_byvar;
			if &_outcome=&_outvalue and &_domain=&_domainvalue then output; 
run;

%* create table for the output;
data final(keep=f_&_factor &_factor f_&_byvar &_byvar _n N _i _c variable);
set merged;
	charLCL     	= put(ColLowerCL,4.1);
	charUCL     	= put(ColUpperCL,4.1);
    _c     			= put(ColPercent,4.1);
	_n   			= put(frequency, 5.0);
	denominator 	= put(freqtot, 5.0);
    variable		= f_&_factor;
	_i 				= '('||trim(left(charLCL))||' - '||trim(left(charUCL))||')'; *confidence _i (LCL, UCL);
	N 				= trim((_n))||'/'||trim(left(denominator));
 	label N 		= 'Unweighted n/N';
	label _c 		= '%';
	label _i 		= '95% CI';
	if f_&_factor	= "Total" then do;
	    charLCL		= "";
		charUCL		= "";
    end;
	proc sort;
		by &_factor f_&_byvar;
run;

%* prepare data for reporting;
proc surveyfreq data = _temp_;
	tables &_byvar*&_outcome;
	ods output 'CrossTabulation Table' = xtab0;
run;

data xtab1;
set xtab0;
	_ordervar=_n_;
run;

proc sort data=xtab1 nodupkey;
	by f_&_byvar;
run;

proc sort data=xtab1 ;
	by _ordervar;
run; 

proc sort data =_temp_; by &_byvar; run;

data _null_; set  _temp_; by &_byvar; 
if first.&_byvar and &_byvar ne &_missval then do;
	i+1;
	call symput("colvname"||trim(left(i)), "&_byvar._"||trim(left(&_byvar))); 
	call symput("collabel"||trim(left(i)), trim(left(vvalue(&_byvar))));
	call symput('no_cols', trim(left(i)));
	end;
run;

%do i  =  1 %to &no_cols;
data  A_&&colvname&i &&colvname&i; run;

data  A_&&colvname&i;
set final;
	if upcase(trim(left(f_&_byvar))) = upcase(trim(left("&&collabel&i"))) then output;
run;

data &&colvname&i;
set A_&&colvname&i;
	_n_&&colvname&i.	=_n;
	N_&&colvname&i.		=N;
	_i_&&colvname&i.	=_i;
	_c_&&colvname&i.	=_c;
		output;
run;

proc sort data=&&colvname&i;
	by &_factor;
run;

%* totals;
data  A_total_&_byvar;
set final;
	if upcase(trim(left(f_&_byvar))) = upcase(trim(left("Total"))) then output;
run;

data total_&_byvar;
set A_total_&_byvar;
	_n_total_&_byvar	= _n;
	N_total_&_byvar		= N;
	_i_total_&_byvar	= _i;
	_c_total_&_byvar	= _c;
	output;
run;

proc sort data=total_&_byvar;
	by &_factor;
run;

%end;

data _merge;
merge %do i  =  1 %to &no_cols; &&colvname&i %end; total_&_byvar;
	by &_factor;
	breakvar='';                                 
run;

data _merge_level;
set _merge;
	if f_&_factor="Total" then delete;
run;

data _merge_total;
set _merge;
	if f_&_factor="Total" then output;
run;

data _null_; 
set _temp_;
	 call symput("flabel", trim(left(vlabel(&_factor))));
run;

data _merge_varname (keep=variable);
length variable $200;
set _merge;
	variable="&flabel";
run;

%* get only one instance of varname (total frequency);
%distcolval(_data=_merge_varname, _var=variable);

data _report_freq;
set _merge_varname _merge_level _merge_total;                                
run;

%mend svy_col;

%* main cross tabulation macro for row percentages;
%macro svy_row(	_data=,
				_outcome=,
				_outvalue=,
				_byvar=,
				_factor=,
				_missval=,
				_domain=,
				_domainvalue=,
				_strata=,
				_cluster=,
                _weight=);

%* clean temporary datasets;
data _temp_ _report_freq Crosstab1 Crosstabtotal1 Crosstabtotal Crosstab totals merged final xtab0 xtab1 _merge _merge_level _merge_total _merge_varname; run;

%* finetuning the data;
data _temp_;
set &_data;
	if &_byvar ne &_missval ;
run;

%* create the cross-tabluation table;
ods output CrossTabs=Crosstab1;
proc surveyfreq data=_temp_;  

%* apply survey design if specified; 
 	%if &_strata ne %then %do;  
		stratum &_strata;
	%end;
	%if &_cluster ne %then %do;  
		cluster &_cluster;
	%end;
	%if &_weight ne %then %do;  
		weight  &_weight;
	%end;
		tables  &_domain*&_factor*&_byvar*&_outcome/col cl chisq; 
run;

%* create the cross-tabluation totals;
ods output CrossTabs=Crosstabtotal1;
proc surveyfreq data=_temp_;    
 
%* apply survey design if specified; 
 	%if &_strata ne %then %do;  
		stratum &_strata;
	%end;
	%if &_cluster ne %then %do;  
		cluster &_cluster;
	%end;
	%if &_weight ne %then %do;  
		weight  &_weight;
	%end;
		tables  &_domain*&_byvar*&_outcome/col cl chisq; 
run;

data Crosstabtotal;
set Crosstabtotal1;
	f_&_factor=vvalue(&_factor);
	if &_outcome=&_outvalue;
run;

data Crosstabtotal;
set Crosstabtotal;
	if &_factor = . then f_&_factor ="Total";
run;

data Crosstab;
set Crosstab1 Crosstabtotal;
proc sort;
	by f_&_factor;
run;

data Crosstab;
set Crosstab;
	f_&_byvar=vvalue(&_byvar);
	f_&_factor=vvalue(&_factor);
	if &_byvar = . then f_&_byvar ="Total";
	if &_factor = . then f_&_factor ="Total";
run;

%* create total for each rows;
data totals (keep=table f_&_factor &_factor f_&_byvar freqtot);
	set crosstab(rename=(frequency=freqtot));
		f_&_factor=vvalue(&_factor);
		if &_byvar = . then f_&_byvar ="Total";
		if &_factor = . then f_&_factor ="Total";

%* searches for "Totals" from surveyfreq ods output;
		scan_&_outcome = scan(f_&_outcome,1);
			if scan_&_outcome = "Total" and f_&_byvar ="Total";
run;

proc sort data=crosstab;
	by table &_factor f_&_byvar;
run;

proc sort data=totals;
	by table &_factor f_&_byvar;
run;

%* merge back with the frequency table to adds "Totals" back to surveyfreq ods ouput;
data merged;
	merge crosstab totals; 
		by table &_factor f_&_byvar;
		if f_&_byvar="Total" then do;
        ColLowerCL=LowerCL;
		ColUpperCL=UpperCL;
		ColPercent=Percent;
        end;
			if freqtot=. and trim(left(f_&_byvar))="Total" then freqtot=Frequency;
			if &_outcome=&_outvalue and &_domain=&_domainvalue  then output; 
 	  
run;

%* populate missing freqtot with non-missing one by &_factor;
data merged(drop=next initial);
    retain next;
    do until (freqtot ne . or last.&_factor);
        set merged;
        by table &_factor f_&_byvar;
    end;
    if freqtot ne . then next = freqtot;
    do until (initial ne . or last.&_factor);
        set merged;
        by table &_factor f_&_byvar;
        initial = freqtot;
        if initial = . then freqtot = next;
        output;
    end;
run;

%* create table for the output;
data final(keep=f_&_factor &_factor f_&_byvar &_byvar _n N _i _c variable frequency freqtot);
set merged;
	charLCL     	= put(ColLowerCL,4.1);
	charUCL     	= put(ColUpperCL,4.1);
    _c     			= put(ColPercent,4.1);
	_n   			= put(frequency, 5.0);
	denominator 	= put(freqtot, 5.0);
    variable		= f_&_factor;
	_i 				= '('||trim(left(charLCL))||' - '||trim(left(charUCL))||')';
	N 				= trim((_n))||'/'||trim(left(denominator));
 	label N 		= 'Unweighted n/N';
	label _c 		= '%';
	label _i 		= '95% CI';
	if f_&_factor	= "Total" then do;
	    charLCL		= "";
		charUCL		= "";
    end;
	proc sort;
		by &_factor f_&_byvar;
run;

%* prepare data for reporting;
proc surveyfreq data = _temp_;
	tables &_byvar*&_outcome;
	ods output 'CrossTabulation Table' = xtab0;
run;

data xtab0;
set xtab0;
if &_outcome=&_outvalue;
run;

data xtab1;
set xtab0;
	_ordervar=_n_;
run;

proc sort data=xtab1 nodupkey;
	by f_&_byvar;
run;

proc sort data=xtab1 ;
	by _ordervar;
run; 

proc sort data =_temp_; by &_byvar; run;

data _null_; set  _temp_; by &_byvar; 
if first.&_byvar and &_byvar ne &_missval then do;
	i+1;
	call symput("colvname"||trim(left(i)), "&_byvar._"||trim(left(&_byvar))); 
	call symput("collabel"||trim(left(i)), trim(left(vvalue(&_byvar))));
	call symput('no_cols', trim(left(i)));
	end;
run;

%do i  =  1 %to &no_cols;
data  A_&&colvname&i &&colvname&i; run;

data  A_&&colvname&i;
set final;
	if upcase(trim(left(f_&_byvar))) =  upcase(trim(left("&&collabel&i"))) then output;
run;

data &&colvname&i;
set A_&&colvname&i;
	_n_&&colvname&i.=_n;
	N_&&colvname&i.=N;
	_i_&&colvname&i.=_i;
	_c_&&colvname&i.=_c;
		output;
run;

proc sort data=&&colvname&i;
	by &_factor;
run;

%* totals;
data  A_total_&_byvar;
set final;
	if upcase(trim(left(f_&_byvar))) =  upcase(trim(left("Total"))) then output;
run;

data total_&_byvar;
set A_total_&_byvar;
	_n_total_&_byvar=_n;
	N_total_&_byvar=N;
	_i_total_&_byvar=_i;
	_c_total_&_byvar=_c;
		output;
run;

proc sort data=total_&_byvar;
	by &_factor;
run;

%end;

data _merge;
merge %do i = 1 %to &no_cols; &&colvname&i %end; total_&_byvar;
	by &_factor;
	breakvar='';                                 
run;

data _merge_level;
set _merge;
	if f_&_factor="Total" then delete;
run;

data _merge_total;
set _merge;
	if f_&_factor="Total" then output;
run;

data _null_; 
set _temp_;
	 call symput("flabel", trim(left(vlabel(&_factor))));
run;

data _merge_varname (keep=variable);
length variable $200;
set _merge;
	variable="&flabel";
run;

%* get only one instance of varname (total frequency);
%distcolval(_data=_merge_varname, _var=variable);

data _report_freq;
set _merge_varname _merge_level _merge_total;                                
run;

%mend svy_row;

%* main macro for prevalence;
%macro svy_prev(_data=,
				_outcome=,
				_outvalue=,
				_factor=,
				_byvar=,
				_missval=,
				_domain=,
				_domainvalue=,
				_strata=,
				_cluster=,
                _weight=);

%* create the cross-tabluation table;
data _temp_ _report_freq Crosstab1 Crosstabtotal1 Crosstabtotal Crosstab totals merged final xtab0 xtab1 _merge _merge_level _merge_total _merge_varname; run;

%* finetuning the data;
data _temp_;
set &_data;
	if &_byvar ne &_missval and &_factor ne .;
run;

%* create the cross-tabluation table;
ods output CrossTabs=Crosstab1;
proc surveyfreq data=_temp_;   

%* apply survey design if specified; 
 	%if &_strata ne %then %do;  
		stratum &_strata;
	%end;
	%if &_cluster ne %then %do;  
		cluster &_cluster;
	%end;
	%if &_weight ne %then %do;  
		weight &_weight;
	%end;
		tables &_domain*&_factor*&_byvar*&_outcome/row cl chisq;
run;

data Crosstab1;
set Crosstab1;
	f_&_factor=vvalue(&_factor);
run;

ods output CrossTabs=Crosstabtotal;
proc surveyfreq data=_temp_;            

%* apply survey design if specified; 
 	%if &_strata ne %then %do;  
		stratum &_strata;
	%end;
	%if &_cluster ne %then %do;  
		cluster &_cluster;
	%end;
	%if &_weight ne %then %do;  
		weight &_weight;
	%end;
		tables &_domain*&_byvar*&_outcome/row cl chisq; 
run;

data Crosstabtotal;
set Crosstabtotal;
	f_&_factor="Total";
run;

data Crosstab;
set Crosstab1 Crosstabtotal;
proc sort;
	by f_&_factor;
run;

%* create total for each rows;
data totals (keep=table f_&_factor &_factor f_&_byvar freqtot);
	set crosstab(rename=(frequency=freqtot));

%* searches for "Totals" from surveyfreq ods output;
		scan_&_outcome = scan(f_&_outcome,1);
			if scan_&_outcome = "Total";
proc sort;
	by table &_factor f_&_byvar;
run;

proc sort data=Crosstab;
	by table &_factor f_&_byvar;
run;

%* merge back with the frequency table to adds "Totals" back to surveyfreq ods ouput;
data merged;
	merge crosstab totals; 
		by table &_factor f_&_byvar;
		if f_&_byvar="Total" then do;
        RowLowerCL=LowerCL;
		RowUpperCL=UpperCL;
		RowPercent=Percent;
        end;
			if &_outcome=&_outvalue and &_domain=&_domainvalue then output; 
run;

%* create table for the output;
data final(keep=f_&_factor &_factor f_&_byvar _n N _i _c variable);
set merged;
	charLCL     	= put(RowLowerCL,4.1);
	charUCL     	= put(RowUpperCL,4.1);
	_c     			= put(RowPercent,4.1);
	_n  	 		= put(frequency, 5.0);
	denominator 	= put(freqtot, 5.0);
	variable		= f_&_factor;
	_i 				= '('||trim(left(charLCL))||' - '||trim(left(charUCL))||')';
	N 				= trim((_n))||'/'||trim(left(denominator));
	label N 		= 'Unweighted n/N';
	label _c 		= '%';
	label _i 		= '95% CI';
	proc sort;
		by &_factor f_&_byvar;
run;

%* prepare data for reporting;
proc surveyfreq data = _temp_;
	tables &_byvar*&_outcome;
	ods output 'CrossTabulation Table' = xtab0;
run;
 
data xtab1;
set xtab0;
	_ordervar=_n_;
run;

proc sort data=xtab1 nodupkey;
by  f_&_byvar;
run;

proc sort data=xtab1 ;
by _ordervar;
run;

%* create reporting columns;
proc sort data =_temp_; by &_byvar; run;

data _null_; set  _temp_; by &_byvar; 
if first.&_byvar and &_byvar ne &_missval then do;
	i+1;
	call symput("colvname"||trim(left(i)), "&_byvar._"||trim(left(&_byvar))); 
	call symput("collabel"||trim(left(i)), trim(left(vvalue(&_byvar))));
	call symput('no_cols', trim(left(i)));
	end;
run;

%do i  =  1 %to &no_cols;
data  A_&&colvname&i &&colvname&i; run;

data  A_&&colvname&i;
set final;
	if upcase(trim(left(f_&_byvar))) = upcase(trim(left("&&collabel&i."))) then output;
run;

data &&colvname&i;
set A_&&colvname&i;
	_n_&&colvname&i.=_n;
	N_&&colvname&i.=N;
	_i_&&colvname&i.=_i;
	_c_&&colvname&i.=_c;
	output;
run;

proc sort data=&&colvname&i;
by &_factor;
run;
%end;

%* totals;
data  A_total_&_byvar;
set final;
	if upcase(trim(left(f_&_byvar))) =  upcase(trim(left("Total"))) then output;
run;

data total_&_byvar;
set A_total_&_byvar;
	_n_total_&_byvar=_n;
	N_total_&_byvar=N;
	_i_total_&_byvar=_i;
	_c_total_&_byvar=_c;
		output;
run;

proc sort data=total_&_byvar;
	by &_factor;
run;

%* merge with totals;
data _merge;
merge %do i = 1 %to &no_cols; &&colvname&i %end; total_&_byvar;
	by &_factor;
	breakvar='';                                 
run;

data _merge_level;
set _merge;
	if f_&_factor="Total" then delete;
run;

data _merge_total;
set _merge;
	if f_&_factor="Total" then output;
run;

data _null_; 
set _merge;
	call symput("flabel", trim(left(vlabel(&_factor))));
run;

data _merge_varname (keep=variable);
length variable $200;
set _merge;
	variable="&flabel";
run;

%* get only one instance of varname (total frequency);
%distcolval(_data=_merge_varname, _var=variable);

data _report_freq;
set _merge_varname _merge_level _merge_total;                                
run;

%mend svy_prev;

%* macro to compute Median (IQR);
%macro svy_median (	_data=,
					_outcome=,
					_contvar=,
					_missval=,
					_byvar=,
					_outvalue=,
					_domain=,
					_domainvalue=,
					_strata=,
					_cluster=,
	                _weight=);

data _temp_ _report_cont _median_total _q1_total _q3_total _median_sub _q1_sub _q3_sub _median_freq _q1_freq _q3_freq _summc _summb _summa _summ3n _summ3s _summ _summ2 _summ1 _summ2n _summ2s _summ1n _summ1s; run;

* finetuning the data;
data _temp_;
set &_data;
	if &_byvar ne &_missval and &_contvar ne &_missval;
run;

%* quantiles for totals;
ods output 	Summary=_summ1n
			Quantiles=_summ1s;
proc surveymeans data=_temp_ median q1 q3;
%if &_strata ne %then %do;
	strata &_strata;
%end;
%if &_cluster ne %then %do;
	cluster &_cluster;
%end;
%if &_weight ne %then %do;
	weight &_weight;
%end;
	var &_contvar;
	where &_domain=&_domainvalue and &_outcome=&_outvalue;
run;

* extract median Q1 and Q3 from visits data;
data _median_total;
set _summ1s;
Median=Estimate;
if Quantile=0.5;
keep VarName VarLabel Median;
run;

data _q1_total;
set _summ1s;
Q1=Estimate;
if Quantile=0.25;
keep VarName VarLabel Q1;
run;

data _q3_total;
set _summ1s;
Q3=Estimate;
if Quantile=0.75;
keep VarName VarLabel Q3;
run;

data _summ1s;
merge _median_total _q1_total _q3_total;
by VarName;
run;

data _NULL_;
	if 0 then set _summ1n nobs=n;
	call symputx('nfrows',n);
	stop;
run;

%if &nfrows eq 1 %then %do;
data _summ1n;
set _summ1n;
run;
%end;

%else %if &nfrows gt 1 %then %do;
data _summ1n;
set _summ1n;
	if label1="Number of Observations" then output;
run;
%end;

data _summ1;
merge _summ1n _summ1s ;
run;

data _summ1;
set _summ1;
	f_&_byvar="Total";
run;

%* Quantiles by _byvar;
proc sort data = _temp_; by &_byvar; run;

ods output Summary=_summ2n;
proc means data=_temp_ n;
	var &_contvar;
	by &_byvar;
	where &_domain=&_domainvalue and &_outcome=&_outvalue and &_contvar ne &_missval;
run;

data _summ2n;
set _summ2n;
	cValue1 =trim(left(put(&_contvar._N, 4.0)));
run;

ods output Quantiles=_summ2s;
proc surveymeans data=_temp_ median q1 q3;
%if &_strata ne %then %do;
	strata &_strata;
%end;
%if &_cluster ne %then %do;
	cluster &_cluster;
%end;
%if &_weight ne %then %do;
	weight &_weight;
%end;
	var &_contvar;
	by &_byvar;
	where &_domain=&_domainvalue and &_outcome=&_outvalue;
run;

* extract median Q1 and Q3 from visits data;
data _median_freq;
set _summ2s;
Median=Estimate;
if Quantile=0.5;
keep &_byvar VarName VarLabel Median;
proc sort; by &_byvar;
run;

data _q1_freq;
set _summ2s;
Q1=Estimate;
if Quantile=0.25;
keep &_byvar VarName VarLabel Q1;
proc sort; by &_byvar;
run;

data _q3_freq;
set _summ2s;
Q3=Estimate;
if Quantile=0.75;
keep &_byvar VarName VarLabel Q3;
proc sort; by &_byvar;
run;

data _summ2s;
merge _median_freq _q1_freq _q3_freq;
by VarName &_byvar;
run;

data _summ2;
merge _summ2n _summ2s;
	by &_byvar;
run;

data _summ2;
set _summ2;
	f_&_byvar= vvalue(&_byvar);
run;

data _summ;
set _summ2 _summ1;
	FREQ=cValue1+0;
	_n=trim(left(put(cValue1, 4.0)));
	_c=trim(left(put(Median,4.1)));
	Q1=trim(left(put(Q1,4.1)));
	Q3=trim(left(put(Q3,4.1)));
	s_order=_n_;
	keep &_byvar f_&_byvar FREQ _n _c Q1 Q3 s_order;
	proc sort; by s_order;
run;

data _summ;
set _summ;
	cum_n+FREQ;
		if _n = "" then _n=trim(left(put(cum_n, 4.0)));
run;

proc sort data = _temp_; by &_byvar ; run;

data _null_; set  _temp_; by &_byvar; 
 if first.&_byvar and &_byvar ne &_missval then do;
 i+1;
  	call symput("colvname"||trim(left(i)), "&_byvar._"||trim(left(&_byvar)));
  	call symput("collabel"||trim(left(i)), trim(left(vvalue(&_byvar))));
  	call symput("no_cols", trim(left(i)));
	end;
run;

data _summa;
set _summ;
	variable = trim(left(vlabel(&_contvar)));

%do i  =  1 %to &no_cols;
if upcase(trim(left(f_&_byvar))) = upcase(trim(left("&&collabel&i"))) then do;
	_n_&&colvname&i	=_n;
	N_&&colvname&i	=_n_&&colvname&i;
	_c_&&colvname&i	=trim(left(put(_c,4.1)));
	Q1&&colvname&i	=Q1;
	Q3&&colvname&i	=Q3;
	_i_&&colvname&i	="("||TRIM(LEFT(put(Q1&&colvname&i,4.1)))||" - "||TRIM(LEFT(put(Q3&&colvname&i,4.1)))||")";
end;
%end;

retain 
%do i  =  1 %to &no_cols;
	N_&&colvname&i
	_n_&&colvname&i			
	_c_&&colvname&i
	_i_&&colvname&i
%end; ;

if upcase(variable)="-10" then variable="Missing";
run;

data _summb;
set _summa;
	if f_&_byvar="Total" then output;
	*if s_order="Total" then output;
run;

%* column for totals;
ods output Summary=_summ3n;
ods output Quantiles=_summ3s;
proc surveymeans data=_temp_ median q1 q3;
%if &_strata ne %then %do;
	strata &_strata;
%end;
%if &_cluster ne %then %do;
	cluster &_cluster;
%end;
%if &_weight ne %then %do;
	weight &_weight;
%end;
	var &_contvar;
	where &_domain=&_domainvalue and &_outcome=&_outvalue;
run;

data _NULL_;
	if 0 then set _summ3n nobs=n;
	call symputx('nrows',n);
	stop;
run;

* extract median Q1 and Q3 from visits data;
data _median_sub;
set _summ3s;
Median=Estimate;
if Quantile=0.5;
keep VarName VarLabel Median;
run;

data _q1_sub;
set _summ3s;
Q1=Estimate;
if Quantile=0.25;
keep VarName VarLabel Q1;
run;

data _q3_sub;
set _summ3s;
Q3=Estimate;
if Quantile=0.75;
keep VarName VarLabel Q3;
run;

data _summ3s;
merge _median_sub _q1_sub _q3_sub;
by VarName;
run;

%if &nfrows eq 1 %then %do;
data _summ3n;
set _summ3n;
run;
%end;

%else %if &nrows gt 1 %then %do;
data _summ3n;
set _summ3n;
	if label1="Number of Observations" then output;
run;
%end;

data _summc;
merge _summ3n _summ3s ;
run;

data _summc;
set _summc;
	N_total	 = cValue1;
	_i_total = "("||trim(left(put(Q1, 4.1))) ||" - "|| trim(left(put(Q3, 4.1))) ||")";
run;

data _null_; 
set &_data;
	 call symput("varlabel", vlabel(&_contvar));
run;

data _summc;
length varname $50;
	merge _summb _summc;
	varname="&varlabel";
	label varname="Characteristic";
	if f_&_byvar="Total";
run;

data _report_cont;
length 
	 variable  f_&_byvar
	%do i = 1 %to &no_cols;
		_i_&&colvname&i	
		_i_total_&&colvname&i	
	%end; $50;
set _summc;
	variable=varname;
	_c_total_&_byvar = trim(left(put(_c,4.1)));
	N_total_&_byvar	 = trim(left(put(_n,4.0)));
	_n_total_&_byvar = trim(left(put(_n,4.0)));
	_i_total_&_byvar = "("||trim(left(put(Q1, 4.1))) ||" - "|| trim(left(put(Q3, 4.1))) ||")";

run;

%mend svy_median;

%* macro to compute Mean (95% CI);
%macro svy_mean (	_data=,
					_outcome=,
					_contvar=,
					_missval=,
					_byvar=,
					_outvalue=,
					_domain=,
					_domainvalue=,
					_strata=,
					_cluster=,
	                _weight=);

data _temp_ _report_cont _summc _summb _summa _summ3n _summ3s _summ _summ2 _summ1 _summ2n _summ2s _summ1n _summ1s; run;

* data steps ...;
data _temp_;
set &_data;
	if &_byvar ne &_missval and &_contvar ne &_missval;
run;

%* statistics for totals;
ods output 	Summary=_summ1n
			Statistics=_summ1s;
proc surveymeans data=_temp_ mean clm;
%if &_strata ne %then %do;
	strata &_strata;
%end;
%if &_cluster ne %then %do;
	cluster &_cluster;
%end;
%if &_weight ne %then %do;
	weight &_weight;
%end;
%if &_domain ne %then %do;
	domain &_domain;
%end;
	var &_contvar;
	where &_domain=&_domainvalue and &_outcome=&_outvalue;
run;

data _NULL_;
	if 0 then set _summ1n nobs=n;
	call symputx('nfrows',n);
	stop;
run;

%if &nfrows eq 1 %then %do;
data _summ1n;
set _summ1n;
run;
%end;

%else %if &nfrows gt 1 %then %do;
data _summ1n;
set _summ1n;
	if label1="Number of Observations" then output;
run;
%end;

data _summ1;
merge _summ1n _summ1s ;
run;

data _summ1;
set _summ1;
	f_&_byvar="Total";
run;

%* statistics by _byvar;
proc sort data = _temp_; by &_byvar; run;

ods output Summary=_summ2n;
proc means data=_temp_ n;
	var &_contvar;
	by &_byvar;
	where &_domain=&_domainvalue and &_outcome=&_outvalue;
run;

data _summ2n;
set _summ2n;
	cValue1 =trim(left(put(&_contvar._N, 4.0)));
run;

ods output Statistics=_summ2s;
proc surveymeans data=_temp_ mean clm;
%if &_strata ne %then %do;
	strata &_strata;
%end;
%if &_cluster ne %then %do;
	cluster &_cluster;
%end;
%if &_weight ne %then %do;
	weight &_weight;
%end;
%if &_domain ne %then %do;
	domain &_domain;
%end;
	var &_contvar;
	by &_byvar;
	where &_domain=&_domainvalue and &_outcome=&_outvalue;
run;

data _summ2;
merge _summ2n _summ2s;
	by &_byvar;
run;

data _summ2;
set _summ2;
	f_&_byvar= vvalue(&_byvar);
run;

data _summ;
set _summ2 _summ1;
	FREQ=cValue1+0;
	_n=trim(left(put(cValue1, 4.0)));
	_c=trim(left(put(Mean,4.1)));
	LowerCLMean=LowerCLMean;
	UpperCLMean=UpperCLMean;
	s_order=_n_;
	keep &_byvar f_&_byvar FREQ _n _c LowerCLMean UpperCLMean s_order;
	proc sort; by s_order;
run;

data _summ;
set _summ;
	cum_n+FREQ;
		if _n = "" then _n=trim(left(put(cum_n, 4.0)));
run;

proc sort data = _temp_; by &_byvar ; run;

data _null_; set  _temp_; by &_byvar; 
 if first.&_byvar and &_byvar ne &_missval then do;
 i+1;
  	call symput("colvname"||trim(left(i)), "&_byvar._"||trim(left(&_byvar)));
  	call symput("collabel"||trim(left(i)), trim(left(vvalue(&_byvar))));
  	call symput("no_cols", trim(left(i)));
	end;
run;

data _summa;
set _summ;
	variable = trim(left(vlabel(&_contvar)));

%do i  =  1 %to &no_cols;
if upcase(trim(left(f_&_byvar))) = upcase(trim(left("&&collabel&i"))) then do;
	_n_&&colvname&i	= _n;
	N_&&colvname&i	= _n_&&colvname&i;
	_c_&&colvname&i	= trim(left(put(_c, 4.1)));
	_i_&&colvname&i	= "("||TRIM(LEFT(put(LowerCLMean,4.1)))||" - "||TRIM(LEFT(put(UpperCLMean,4.1)))||")";
end;
%end;

retain 
%do i  =  1 %to &no_cols;
	N_&&colvname&i
	_n_&&colvname&i			
	_c_&&colvname&i
	_i_&&colvname&i
%end; ;

if upcase(variable)="-10" then variable="Missing";

run;

data _summb;
set _summa;
	if f_&_byvar="Total" then output;
	*if s_order="Total" then output;
run;

%* column for totals;
ods output Summary=_summ3n;
ods output Statistics=_summ3s;
proc surveymeans data=_temp_ mean clm;
%if &_strata ne %then %do;
	strata &_strata;
%end;
%if &_cluster ne %then %do;
	cluster &_cluster;
%end;
%if &_weight ne %then %do;
	weight &_weight;
%end;
%if &_domain ne %then %do;
	domain &_domain;
%end;
	var &_contvar;
run;

data _NULL_;
	if 0 then set _summ3n nobs=n;
	call symputx('nrows',n);
	stop;
run;

%if &nfrows eq 1 %then %do;
data _summ3n;
set _summ3n;
run;
%end;

%else %if &nrows gt 1 %then %do;
data _summ3n;
set _summ3n;
	if label1="Number of Observations" then output;
run;
%end;

data _summc;
merge _summ3n _summ3s ;
run;

data _summc;
set _summc;
	N_total	 = cValue1;
	_i_total = "("||trim(left(put(LowerCLMean, 4.1))) ||" - "|| trim(left(put(UpperCLMean, 4.1)))||")";
run;

data _null_; 
set &_data;
	 	call symput("varlabel", vlabel(&_contvar));
run;

data _summc;
length varname $50;
	merge _summb _summc;
	varname="&varlabel";
	label varname="Characteristic";
	if f_&_byvar="Total";
run;

data _report_cont;
length 
	 variable  f_&_byvar
	%do i  =  1 %to &no_cols;
		_i_&&colvname&i	
		_i_total_&&colvname&i	
	%end; $50;
set _summc;
	variable=varname;
	_c_total_&_byvar = trim(left(put(_c,4.1)));
	N_total_&_byvar	 = trim(left(put(_n,4.0)));
	_n_total_&_byvar = trim(left(put(_n,4.0)));
	_i_total_&_byvar = "("||trim(left(put(LowerCLMean, 4.1))) ||" - "|| trim(left(put(UpperCLMean, 4.1))) ||")";
run;

%mend svy_mean;

%* macro to get one instance of repeated values;
%macro distcolval(_data=, _var=);

proc sql;
	create table &_var as select distinct &_var from &_data;
quit;

data &_data;
set &_data;
	drop &_var;
run;

data &_data;
merge &_var &_data;
	if &_var ="" then delete;
run;

%mend distcolval;

%* macro to recode variables with character values to numeric values;
%macro charvar(_data=, _allvar=, _idvar=);

data _xtab; run;

proc freq data = &_data;
tables &_allvar ;
	ods output 'One-Way Frequencies' = _xtab;
run;

data _xtab;
length label $100;
set _xtab;
	start=_n_;
	new&_allvar=_n_;
	label=f_&_allvar;
	fmtname=compress("&_allvar"||"_f");
	keep &_allvar new&_allvar start fmtname label;
run;

proc format cntlin=_xtab; run;

proc sort data=&_data; by &_allvar; run;
proc sort data=_xtab; by &_allvar; run;

data &_data;
merge _xtab (keep=&_allvar new&_allvar) &_data;
format new&_allvar &_allvar._f.;
by &_allvar;
	%let dsid = %sysfunc(open(&_data));
	%let vnum = %sysfunc(varnum(&dsid,&_allvar));
	%let vlab = %sysfunc(varlabel(&dsid,&vnum));
	label new&_allvar="&vlab";
	%let rc = %sysfunc(close(&dsid));
run;

data &_data;
set &_data;
	drop &_allvar;
	rename new&_allvar =&_allvar;
run;

data char_&_data;
set &_data;
	keep &_allvar &_idvar;
run;

proc sort data=char_&_data; by &_idvar; run;

%mend charvar;
