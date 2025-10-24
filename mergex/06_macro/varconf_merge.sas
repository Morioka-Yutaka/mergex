/*** HELP START ***//*

Macro Name:    %varconf_merge()
 Purpose:    Perform a conditional merge between two SAS datasets with automated variable conflict handling.

 Description:
    This macro merges two datasets while automatically detecting and renaming variables 
    that exist in both datasets (except BY variables). It supports conditional inclusion 
    of observations based on IN flags and allows optional automatic sorting before merging.

 Parameters:
    lib1        - Library name of the first dataset (default=WORK)
    ds1         - Name of the first dataset
    lib2        - Library name of the second dataset (default=WORK)
    ds2         - Name of the second dataset
    byvars      - List of BY variables (space-separated)
    output_ds   - Output dataset name (default=merge_output)
    in1         - Condition flag for dataset 1 (1 or 0)
    operator    - Logical operator to combine IN conditions (AND/OR)
    in2         - Condition flag for dataset 2 (1 or 0)
    auto_sort   - Whether to sort by BY variables before merge (Y/N, default=N)

 Features:
    - Automatically detects overlapping variable names (excluding BY variables)
    - Renames conflicting variables as varname_DS1 / varname_DS2

 Usage Example:
    data wk1;
    do X = 1,2,3;
      Y="A";
      Z=x+1;
      output;
    end;
    run;

    data wk2;
    do X = 2,3,4;
      Y="A";
      Z=X*100;
      output;
    end;
    run;
    %varconf_merge(
        ds1=wk1,
        ds2=wk2,
        byvars=x y,
        output_ds=merge_output,
        in1=1,
        operator=OR,
        in2=1,
        auto_sort=N
    );

*//*** HELP END ***/

%macro varconf_merge(
lib1=WORK,
ds1=,
lib2=WORK,
ds2=,
byvars=,
output_ds=merge_output,
in1=1,
operator= ,
in2=,
auto_sort=N
);
%let ds1 = %upcase(&ds1);
%let ds2 = %upcase(&ds2);
%let lib1 = %upcase(&lib1);
%let lib2 = %upcase(&lib2);
%let byvars = %upcase(%sysfunc(compbl(&byvars)));
%let  byvars_lst  = %sysfunc( tranwrd( %str("&byvars.") , %str( ) , %str(",") ) );
%let auto_sort =%upcase(&auto_sort);

proc sql noprint;
  create view vw1 as
  select upcase(name) as vname
           , count(*) as ct
           , cats(calculated vname,"_","&ds1") as vname_main
           , cats(calculated vname,"_","&ds2") as vname_sub
           , catx("=", calculated vname , calculated vname_main) as main_rename
           , catx("=", calculated vname , calculated vname_sub) as sub_rename

  from dictionary.COLUMNS
  where 
    (libname="&lib1" and upcase(memname)="&ds1")
    or
    (libname="&lib2" and upcase(memname)="&ds2")
group by vname
having vname not in (&byvars_lst.) and 1 < ct;
;
select main_rename  into: main_rename separated by " " from  vw1;
select sub_rename  into: sub_rename separated by " " from  vw1;

quit;

%if %length(&main_rename) ne 0 %then %do;
  data work.&ds1._copy;
  set &lib1..&ds1.;
  rename
  &main_rename ;
  run;
  data work.&ds2._copy;
  set &lib2..&ds2.;
  rename
  &sub_rename ;
  run;
 %if &auto_sort = Y %then %do;
    proc sort data=&ds1._copy;
      by &byvars.;
    run;
    proc sort data=&ds2._copy;
      by &byvars.;
    run;
 %end;
%end;

 %else %if &auto_sort = Y %then %do;
    proc sort data=&lib1..&ds1. out=&ds1._copy;
      by &byvars.;
    run;
    proc sort data=&lib2..&ds2.  out=&ds2._copy;
      by &byvars.;
    run;
 %end;

data &output_ds;
merge 
%if &auto_sort = Y or %length(&main_rename) ne 0 %then %do; 
 &ds1._copy(in=in1)
 &ds2._copy(in=in2)
%end;
%else %do;
 &lib1..&ds1. (in=in1)
 &lib2..&ds2. (in=in2)
%end;
;
%if %length(&byvars.) ne 0 %then %do;
by &byvars.;
%end;
%if %length(&in1) ne 0 or %length(&in2) ne 0 %then %do; 
  if 
  %if %length(&in1) ne 0 %then %do;
    in1 =&in1.
  %end;
  %if %length(&operator) ne 0 %then %do;
   &operator. 
   %end;
  %if %length(&in2) ne 0 %then %do;
   in2 =&in2. 
   %end;
  ;
%end;
run;

proc delete data=vw1(memtype=view);
run;

%if %length(&main_rename) ne 0 or &auto_sort=Y %then %do;
proc delete data=&ds1._copy;
run;
proc delete data=&ds2._copy;
run;
%end;


%mend;
