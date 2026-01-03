/*** HELP START ***//*

Purpose  
- Performs rolling (as-of) matching from a master dataset to the current DATA step observation.  
- For each current record, finds the best-matching record(s) in the master dataset within the same key group, using a time-like variable (rollvar).  
- Retrieves one or more variables (var=) from the matched master record and assigns them to the current Data step (PDV).  .  

How matching works (conceptual)  
- The master data are internally prepared with an observation sequence identifier (___row_number) to provide deterministic tie-breaking.  
- The macro scans candidate master records within the same key group and determines a winner based on rolltype= and distance limits.  
- Ties (same direction and same distance) are resolved by choosing the record with the smallest original master observation number (earliest stored observation).  
- Optionally emits a WARNING message when ties/duplicates are encountered (dupWARN=Y).  

Parameters  
- master= (required)  
  Master dataset to be searched (e.g., B). This dataset supplies the matched values.  

- key= (required)  
  One or more key variables used to define matching groups (space-delimited list).  
  Examples: key=ID  /  key=STUDYID USUBJID  /  key=SITEID SUBJID VISITNUM  

- rollvar= (required)  
  The time-like variable used for rolling logic. Typically numeric (e.g., datetime, date, visit day, time).  
  The current DATA step dataset must have rollvar present; the master dataset must also contain rollvar.  

- rolltype= (optional, default=BACK)  
  Rolling direction / strategy. Allowed values: BACK, FORWARD, NEAREST.  
  BACK:  
    Selects the closest prior value (master.rollvar <= current.rollvar).  
    Distance is defined as diff = current.rollvar - master.rollvar (diff >= 0).  
  FORWARD:  
    Selects the closest subsequent value (master.rollvar >= current.rollvar).  
    Distance is defined as diff = current.rollvar - master.rollvar (diff <= 0).  
  NEAREST:  
    Selects the closest value in either direction (minimize abs(diff)).  
    If both past and future candidates are equidistant, the preferred direction can be controlled by nearest_tie_dir=.  

- roll_back_limit= (optional, default blank = no limit)  
  Maximum allowed backward distance for BACK and NEAREST.  
  Interpreted on diff = current - master (diff >= 0).  
  Candidate must satisfy: 0 <= diff <= roll_back_limit.  
  If blank, no backward distance limit is applied.  

- roll_forward_limit= (optional, default blank = no limit)  
  Maximum allowed forward distance for FORWARD and NEAREST.  
  Interpreted on diff = current - master (diff <= 0).  
  Candidate must satisfy: -roll_forward_limit <= diff <= 0.  
  If blank, no forward distance limit is applied.  

- var= (required)  
  One or more variables to retrieve from the matched master record (space-delimited list).  
  These variables are created/overwritten in the current DATA step PDV.  
  Examples: var=VAL  /  var=VAL FLAG  /  var=LABVAL LABUNIT  

- wh= (optional, default blank)  
  WHERE condition applied to the master dataset when building the internal lookup view.  
  This parameter is intended to be used with macro masking functions such as %nrbquote().  
  The condition is inserted verbatim into a DATA step WHERE statement.  
  Typical usage examples:  
    wh=%nrbquote(SEX="F")  
    wh=%nrbquote(ANLFL='Y')  
    wh=%nrbquote(not missing(VAL))   

- nearest_tie_dir= (optional, default=BACK)  
  Applies only when rolltype=NEAREST and a past candidate and a future candidate are equidistant.  
  Allowed values: BACK, FORWARD.  
  BACK:  prefer the past candidate (diff > 0) over the future candidate (diff < 0).  
  FORWARD: prefer the future candidate (diff < 0) over the past candidate (diff > 0).  
  Note: This does not change tie-breaking within the same direction; those ties are always resolved by earliest master observation number.  

- dupWARN= (optional, default=Y)  
  Controls whether a WARNING message is written to the log when ties/duplicate candidates are detected.  
  Y: write WARNING lines via PUT statements.  
  N: suppress WARNING output.  

Outputs / side effects  
- The macro does not create a standalone output dataset by itself; it operates within a DATA step and populates var= in the current PDV.  
- Temporary internal views are created and dropped automatically.  
- When no match is found, the requested var= variables are set to missing.  
- When dupWARN=Y, warning messages may appear in the SAS log for tied candidates.  

Usage examples  
1) Basic BACK (default) with no distance limit  
data out_back;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=BACK, var=VAL);  
run;  

2) BACK with a backward distance limit (e.g., within 3 units)  
data out_back_lim;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=BACK, roll_back_limit=3, var=VAL);  
run;  

3) FORWARD with a forward distance limit (e.g., within 5 units)  
data out_fwd_lim;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=FORWARD, roll_forward_limit=5, var=VAL);  
run;  

4) NEAREST with default tie direction (BACK: prefer past when equidistant)  
data out_nearest_back;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=NEAREST, var=VAL);  
run;  

5) NEAREST preferring future when equidistant  
data out_nearest_fwd;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=NEAREST, var=VAL, nearest_tie_dir=FORWARD);  
run;  

6) NEAREST with symmetric limits (both past and future constrained)  
data out_nearest_lim;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=NEAREST, var=VAL, roll_back_limit=3, roll_forward_limit=5);  
run;  

7) Restrict master candidates with wh= (example: only non-missing values)  
data out_wh;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=BACK, var=VAL, wh=(not missing(VAL)));  
run;  

8) Retrieve multiple variables from master  
data out_multi;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=BACK, var=VAL OTHERFLAG);  
run;  

9) Composite keys (multiple key variables)  
data out_keys;  
  set A2;  
  %rolling_match(master=B2, key=STUDYID USUBJID, rollvar=ADY, rolltype=NEAREST, var=PARAMCD AVAL, nearest_tie_dir=BACK);  
run;  

10) Suppress duplicate/tie warnings  
data out_nowarn;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=NEAREST, var=VAL, dupWARN=N);  
run;  

Notes  
- Ensure that rollvar has comparable scale/units between the current dataset and the master dataset.  
- Ensure that key variables uniquely define intended matching groups; ties may occur if the master contains duplicate candidates at the same distance.  
- The macro is intended to be invoked inside a DATA step (it uses PDV and hash objects).

*//*** HELP END ***/

%macro rolling_match(master=,key=,rollvar=,rolltype=BACK,roll_back_limit=,roll_forward_limit=,var=,wh=,nearest_tie_dir=BACK,dupWARN=Y);
%local name qkey ckey qvar keynum key var wh;

%if %upcase(&rolltype) ne BACK and %upcase(&rolltype) ne FORWARD and %upcase(&rolltype) ne NEAREST %then %do;
 %put ERROR:  The only possible parameters for rolltype are BACK, FORWARD, or NEAREST.;
  %return;
%end;
%if %upcase(&nearest_tie_dir) ne BACK and %upcase(&nearest_tie_dir) ne FORWARD and %length(&nearest_tie_dir) > 0 %then %do;
 %put ERROR:  The only possible parameters for nearest_tie_dir  are BACK or FORWARD.;
  %return;
%end;

%if %superq(master)= %then %do;
  %put ERROR: master= is required.;
  %return;
%end;
%if %superq(key)= %then %do;
  %put ERROR: key= is required.;
  %return;
%end;
%if %superq(rollvar)= %then %do;
  %put ERROR: rollvar= is required.;
  %return;
%end;
%if %superq(var)= %then %do;
  %put ERROR: var= is required.;
  %return;
%end;

%let key=%sysfunc(compbl(&key));
%let ckey  = %sysfunc( tranwrd( %str(&key) , %str( ) , %str(,) ) );
%let qkey  = %sysfunc( tranwrd( %str("&key") , %str( ) , %str(",") ) );
%let keynum = %sysfunc( count( &key, %str ( ) ));

%if %length(&var) ne 0 %then %do;
%let var=%sysfunc(compbl(&var));
%end;
if 0 then set &master(keep= &key &var &rollvar);
%let name  = &sysindex;
retain _N_&name 1;
if _N_&name = 1 then do;
length ___row_number ___&rollvar 8.;
call missing(of ___row_number ___&rollvar min_diff hash_diff target_row_number);
rc&name.=dosubl("data h&name.0/view=h&name.0;set &master curobs=_cur; where &wh.; cobs=_cur;run;");
rc&name.=dosubl("proc sql noprint;
create view h&name.1 as select *, cobs as ___row_number,&rollvar as ___&rollvar from h&name.0 order by &ckey, &rollvar;
quit;"
);
declare hash h1&name(dataset:"h&name.1",multidata:"Y");
h1&name..definekey(&qkey);
h1&name..definedata("___&rollvar","___row_number");
h1&name..definedone();
declare hash h2&name(dataset:"h&name.1(keep=___row_number &var.)");
h2&name..definekey("___row_number");
h2&name..definedata(all:'Y');
h2&name..definedone();

call execute("proc sql noprint;
drop view h&name.0 ;
drop view h&name.1 ;
quit;");
_N_&name = 0 ;

end;

call missing(of ___row_number ___&rollvar.);
call missing(of min_diff  target_row_number hash_diff);

/*BACK*/
%if %upcase(&rolltype) eq BACK %then %do;
do while(h1&name..do_over()=0);
 if n(of &rollvar. ___&rollvar.) =2 then hash_diff = &rollvar. - ___&rollvar.;
 else call missing(hash_diff);
  %if %length(&roll_back_limit) ne 0 %then %do; if . < hash_diff <= &roll_back_limit then do;%end;
   if ^missing(hash_diff) and 0<=hash_diff then do;
      if missing(min_diff) or hash_diff <= min_diff then do;
            %if %upcase(&dupWARN) = Y %then %do;
            if hash_diff =min_diff  then put "WARNING:For ties in the same direction and distance, the earliest observation in the original dataset is chosen; be aware that these are duplicate records." ___row_number= target_row_number= min_diff= &rollvar.= ___&rollvar.=;
            %end;
            if hash_diff =min_diff and  ___row_number < target_row_number  then do;
              target_row_number =___row_number;
            end;
            else do;
              target_row_number =___row_number;
            end;
            min_diff = hash_diff;
      end;
   end;
 %if %length(&roll_back_limit) ne 0 %then %do;end;%end;
end;
%end;

/*FORWARD*/
%if %upcase(&rolltype) eq FORWARD %then %do;
do while(h1&name..do_over()=0);
 if n(of &rollvar. ___&rollvar.) =2 then hash_diff = &rollvar. - ___&rollvar.;
 else call missing(hash_diff);
  %if %length(&roll_forward_limit) ne 0 %then %do; if -1*&roll_forward_limit <=hash_diff  then do;%end;
   if ^missing(hash_diff) and hash_diff<=0 then do;
      if missing(min_diff) or hash_diff >= min_diff then do;
            %if %upcase(&dupWARN) = Y %then %do;
            if hash_diff =min_diff  then put "WARNING:For ties in the same direction and distance, the earliest observation in the original dataset is chosen; be aware that these are duplicate records." ___row_number= target_row_number= min_diff= &rollvar.= ___&rollvar.=;
            %end;
            if hash_diff =min_diff and  ___row_number < target_row_number  then do;
              target_row_number =___row_number;
            end;
            else do;
              target_row_number =___row_number;
            end;
            min_diff = hash_diff;
      end;
   end;
 %if %length(&roll_forward_limit) ne 0 %then %do;end;%end;
end;
%end;

/*NEAREST*/
%if %upcase(&rolltype) eq NEAREST %then %do;
do while(h1&name..do_over()=0);
 if n(of &rollvar. ___&rollvar.) =2 then hash_diff = &rollvar. - ___&rollvar.;
 else call missing(hash_diff);
 %if %length(&roll_back_limit) ne 0 %then %do; if . < hash_diff <= &roll_back_limit then do;%end;
 %if %length(&roll_forward_limit) ne 0 %then %do; if -1*&roll_forward_limit <=hash_diff  then do;%end;
  if missing(min_diff)
     or abs(hash_diff) < abs(coalesce(min_diff,0)) then do;
    min_diff = hash_diff;
    target_row_number = ___row_number;
  end;

  else if abs(hash_diff) = abs(coalesce(min_diff,0)) then do;
    %if %upcase(&dupWARN) = Y %then %do;
    if hash_diff =min_diff  then put "WARNING:For ties in the same direction and distance, the earliest observation in the original dataset is chosen; be aware that these are duplicate records." ___row_number= target_row_number= min_diff= &rollvar.= ___&rollvar.=;
    %end;

   %if %upcase(&nearest_tie_dir)=BACK %then %do;
    if (hash_diff > 0 and coalesce(min_diff,0) < 0) then do;
      min_diff = hash_diff;
      target_row_number = ___row_number;
    end;
  %end;
   %if %upcase(&nearest_tie_dir)=FORWARD %then %do;
   if (hash_diff < 0 and coalesce(min_diff,0) > 0) then do;     
       min_diff = hash_diff;
      target_row_number = ___row_number;
    end;
  %end;

    else if ___row_number < target_row_number then do;
      min_diff = hash_diff;
      target_row_number = ___row_number;
    end;
 end;
 %if %length(&roll_forward_limit) ne 0 %then %do;end;%end;
 %if %length(&roll_back_limit) ne 0 %then %do;end;%end;
end;
%end;


___row_number=target_row_number;
if h2&name..find() ne 0 then do;
 call missing(of &var.);
end;

drop ___row_number target_row_number rc&name. min_diff hash_diff ___&rollvar. _N_&name;
%mend;
