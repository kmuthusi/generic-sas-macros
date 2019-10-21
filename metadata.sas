**************************************************************************************
**************************************************************************************
** Filename     : metadata.sas                                                 		**
**				                                            						**
** Author       : Muthusi, Jacques                        Date: 20OCT2016      		**
**				                                            						**
** Platform     : Windows                                                      		**
**				                                            						**
** Description  : Generic macro to create metadata dictionary for analysis datasets	**
**				                                            						**
** Macros used  : %low_case   - macro to convert all variables to lower case	 	**
**  			: %dictionary - macro to create frequencies and combine with 		**
**								contents and format metadata 						**
**				                                            						**
** Input        : Any dataset with formats for variables                          	**
**				                                            						**
** Output       : Metadata dictionary table in MS Word								**
**				                                            						**
** Assumptions  :                                                               	**
**																					**
** Macro parameters:																**
**		_dataset	 = input dataset,												**
**		_missval	 = value of missingness code,									**
**		_outputpath	 = SAS path for output folder,									**
**		_tablename	 = shortname of output table,									**
**		_tabletitle	 = title of output table,										**
**		_studyname	 = shortname of survey/study ,									**
**				                                            						**
** Example call:																	**
**	%metadata(_dataset	  = clean_lstick_all,										**
**			  _missval	  = -100,													**
**			  _tablename  = lstik_metadata,											**
**			  _outputpath = C:\LSTIK II\SAS\output\tables,							**
**			  _tabletitle = Appendix 1: &studyname Main Data Dictionary,			**
**			  _studyname  = LSTIK II);												**
**																					**
** Validation history                                                         		**
**       Validated by : Muthusi, Jacques                  Date: 19NOV2016  	    	**
**																					**
** Modification history                                                    	    	**
**       Modified by  : Muthusi, Jacques                  Date: 31MAR2017       	**
**                                                                         	    	**
**************************************************************************************
*************************************************************************************;

options mlogic mprint symbolgen;

%macro metadata(_dataset	= ,
				_missval	= ,
				_outdir		= ,
				_tablename	= ,
				_tabletitle	= ,
				_studyname	= );

%* convert variables to lower case;
%low_case(&_dataset);

%* get dataset content;
ods output "Variables" = var_list;
proc contents data=&_dataset; run;
ods output close;

proc sort data=var_list out=sort_var_list;
	by num;
run;

%* get format data;
data formats ;
set formats;
	fmtname=lowcase(fmtname);
run;

proc sort data=formats (keep=fmtname start end label rename=(label=fmtlabel)) out=sort_fmtcntl;
	by fmtname;
run;

%* get contents metadata;
data sort_var_list;
length fmtname $32;
set sort_var_list;
	by num;

%* create format name variable from contents that matches format name variable from CNTLOUT;
	fmtname = lowcase(compress(format,'.'));

%* get the total observations;
	if last.num then call symput("total_obs",put(num,8.));
run;

%* call the macro to get metadata;
%dictionary;

%* prepare the data for the report;
proc sort data=var_list_2;
	by num start;
run;

data rev_var_list_2;
length full_fmtlabel freq pct $20000;
set var_list_2;
	by num;

%* new variables for concatenated format labels, freqs, percentages;
	retain
	full_fmtlabel freq pct fmtval notes "";

%* set to blank at the start of each variable/num;
	if first.num then do;
		fmtval ="";
		full_fmtlabel = "";
		freq = "";
		pct = "";
	end;

%* concatenate format label(s) for each variable;
	if first.num then full_fmtlabel = "";
		labeln = strip(fmtlabel) || "^n" ;
		full_fmtlabel = cats(full_fmtlabel, start, " = ", labeln);

%* concatenate freq(s) for each variable;
	if first.num then freq = trim(put(frequency,comma8.));
	else freq = left(trim(freq)) || "^n" || trim(put(frequency,comma8.));

%* concatenate percentage(s) for each variable;
	if first.num then pct = trim(put(percent,8.1));
	else pct = left(trim(pct)) || "^n" || trim(put(percent,8.1));
	if last.num then output;
run;

%* add numeric uncategorized variables;

data &_dataset;
set &_dataset;

%* replace missing values code with .;
	array a(*) _numeric_;
	do i=1 to dim(a);
	if a(i) = &_missval then a(i) = .;
	end;
	drop i;
run;

proc transpose data=&_dataset out=trans_data; run;

data _null_ ;
set &_dataset nobs=n ;
	call symputx('total',n);
	stop;
run;

data rev_var_tr;
set trans_data (drop=_LABEL_ rename=(_NAME_=variable));
	array chars(*) _character_;
	array num(*) _numeric_;
	count=0;
	do i=1 to dim(chars);
		if missing(chars(i))=0 then count=count+1;
	end;
	do j=1 to dim(num);
		if missing(num(j))=0 then count=count+1;
	end;
	drop i j;
run;

data rev_var_tr;
set rev_var_tr;
	count2=count-1;
run;

data rev_var_tr (keep=variable freq pct);
set rev_var_tr ;
	pct=put(count2/&total*100,8.1);
	freq=trim(put(count2,comma8.));
run;

proc sql;
	create table rev_var_num as 
	select * from sort_var_list 
	where variable not in (select variable from rev_var_list_2);
quit;

proc sort data=rev_var_num; by variable; run;
proc sort data=rev_var_tr; by variable; run;

data rev_var_num;
merge rev_var_num (in=a) rev_var_tr;
	by variable;
	if a;
run;

%* append to the rest of the variables;
data rev_var_all;
set rev_var_list_2 rev_var_num;
	proc sort;
	by num;
run;

proc sql;
	create table rev_var_char as 
	select * from rev_var_all 
	where trim(left(type)) = "Char" and (full_fmtlabel is missing or trim(left(pct))=".");

	create table rev_var_char_dt as 
	select * from rev_var_all 
	where variable not in (select variable from rev_var_char);
quit;

proc sort data=rev_var_char; by variable; run;
proc sort data=rev_var_tr; by variable; run;

data rev_var_char;
merge rev_var_char (in=a) rev_var_tr;
	by variable;
	if a;
run;

%* append to the rest of the variables;
data rev_var_all_2;
set rev_var_char_dt rev_var_char;
	proc sort;
	by num;
run;

%* add notes/remark;
data rev_var_final;
length notes $500;
set rev_var_all_2;
	* add notes...;
run;

%* define report template;
proc template;
define style META;
	parent = styles.printer;
	replace fonts /
		"titlefont2" = ("Times New Roman", 9pt, Bold)
		"titlefont" = ("Times New Roman", 10pt, Bold)
		"strongfont" = ("Times New Roman", 8pt, Bold)
		"emphasisfont" = ("Times New Roman", 8pt, Bold)
		"fixedemphasisfont" = ("Times New Roman", 8pt, Bold)
		"fixedstrongfont" = ("Times New Roman", 8pt, Bold)
		"fixedheadingfont" = ("Times New Roman", 8pt, Bold)
		"batchfixedfont" = ("Times New Roman", 8pt, Bold)
		"fixedfont" = ("Times New Roman", 8pt, Bold)
		"headingemphasisfont" = ("Times New Roman", 8pt, Bold)
		"headingfont" = ("Times New Roman", 8pt, Bold)
		"docfont" = ("Times New Roman", 8pt);
	end; 
run;

%* suppress macro options;
option nomprint nosymbolgen nomlogic nodate nonumber;

%* create report;
ods rtf file="&_outdir\&_tablename..rtf" style= META;
ods escapechar='^';
title "&_tabletitle"; 
footnote height=8pt j=l "(Revised. &sysdate)" j=c "{\b\ Page }{\field{\*\fldinst {\b\i PAGE}}}" j=r "&_studyname";
options nodate nonumber;
proc report data=rev_var_final headline center nowindows style(report)=[font_size=0.5];
column num variable label type freq pct full_fmtlabel /*notes*/;
	define num / order noprint;
	define variable / order display width=10 "Variable name" style=[cellwidth=100];
	define label / flow display width=20 "Variable label" style=[cellwidth=200];
	define type / display "Type" center style=[cellwidth=100];
	define freq / flow display width=10 "n" center style=[cellwidth=100];
	define pct / flow display width=10 "%" center style=[cellwidth=100];
	define full_fmtlabel / flow display width=15 "Values of variable" style=[cellwidth=200];
%*	define notes / flow display width=15 "Notes" style=[cellwidth=200];
run;
footnote;
title;
ods rtf close;

%mend metadata;

%* macro to create frequencies and combine with contents and format metadata;
%macro dictionary; 

%* step  1: set up a %DO loop and go through the contents metadata and get the name of each variable;
%do i=1 %to &total_obs;

%* %DO loop will start with the first variable (i=1) and continue through each variable till the last one (i=&total_obs);
	data _null_;
	set sort_var_list;
		by num;

%* remember that num=logical position of variable in the data set;
		if &i = num then call symput("next_var",variable);
	run;

%* step 2: merge the contents metadata with the format metadata for each variable;
	data tempa&i;
	merge sort_var_list (in=in_cont where=(num = &i))
		sort_fmtcntl;
		by fmtname;
		if in_cont;
	run;

%* step 3: use PROC FREQ and ODS statements to get the frequencies for each variable. use the MISSPRINT option on the TABLES statement to display the missing value frequencies;
	ods output "One-Way Frequencies" = freq_&i;
	proc freq data=&_dataset;
		tables &next_var / missprint;
	run;
	ods output close;

%* step 8. sort the contents and format metadata and the frequency data set by FMTLABEL (the variable to merge by);
	proc sort data=tempa&i;
		by fmtlabel;
	run;

	proc sort data=freq_&i (rename=(f_&next_var = fmtlabel));
		by fmtlabel;
	run;

%* step 5: merge the two datasets by the value label;
	data temp&i;
	merge tempa&i
		freq_&i (in=in_freq keep=fmtlabel frequency percent);
		by fmtlabel;
		if in_freq;
	run;

proc delete data = freq_&i tempa&i; run;
%end;

%* step 6: now that the %DO loop is done, there are separate data sets with data on the contents, the formats, and the frequencies for each variable. combine the data for each variable into a single data set;
data var_list_2;
set
	%do i=1 %to &total_obs;
		temp&i
	%end;
	;
run;

%do i=1 %to &total_obs;
	proc delete data = temp&i; run;
%end;

%mend dictionary; 

* macro to covert all variables names to lowercase;
%macro low_case(dsn); 
     %let dsid=%sysfunc(open(&dsn)); 
     %let num=%sysfunc(attrn(&dsid,nvars)); 
     %put &num;
     data &dsn; 
           set &dsn(rename=( 
        %do i = 1 %to &num; 

%* function of varname returns the name of a SAS data set variable;
        	%let var&i=%sysfunc(varname(&dsid,&i)); 

%* rename all variables to lower case;
        	&&var&i=%sysfunc(lowcase(&&var&i))          
        %end;)); 
        %let close=%sysfunc(close(&dsid)); 
  run; 
%mend low_case; 
