dm 'odsresults; clear; log; clear; out; clear';

* to remove all datasets from within the WORK folder;
proc datasets lib=work nolist kill; quit; run;

* set working directory;
%let dir=C:\NHANES III\SAS;

* set output directory;
%let outdir=&dir.\output\tables;

* print log to file;
proc printto log="&dir.\output\logs\metadata log file.txt" new; run;

* track program run time;
* program start time;
%let datetime_start = %sysfunc(TIME()) ;
%put START TIME: %sysfunc(datetime(),datetime14.);

* load data setup file;
%include "&dir.\setup\setup.sas";

* load required macros;
%include "&dir.\macros\metadata.sas";

* data steps ...;
data clean_nhanes;
set clean_nhanes;
	* data statements;
run;

* call main macro;
option mlogic mprint symbolgen;

* define input/output parameters;
%let _outdir = &outdir;
%let _tablename	 = nhanes_metadata;
%let _studyname	 = NHANES;
%let _tabletitle = Appendix 1: National Health and Nutrition Examination Survey (&_studyname) Data Dictionary;

%metadata(_dataset		= clean_nhanes,
		  _missval		= -100,
		  _outdir		= &_outdir.,
		  _studyname	= &_studyname.,
	 	  _tablename	= &_tablename.,
		  _tabletitle	= &_tabletitle.);

* program end time;
%put END TIME: %sysfunc(datetime(),datetime14.);
%put PROCESSING TIME:  %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&datetime_start.),mmss.)) (mm:ss);

proc printto; run;
