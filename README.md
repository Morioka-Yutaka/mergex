# mergex
MERGEX is a package that enables non-standard or unconventional joins not easily handled or supported by standard SAS syntax.
It currently implements variable-name conflict-safe joins, and rolling joins .

<img width="360" height="360" alt="Image" src="https://github.com/user-attachments/assets/eb5050c7-3866-4244-9bad-57cc0d7b956e" />

## `%rolling_match()` macro <a name="rollingmatch-macro-1"></a> ######

### Purpose  
- Performs rolling (as-of) matching from a master dataset to the current DATA step observation.  
- For each current record, finds the best-matching record(s) in the master dataset within the same key group, using a time-like variable (rollvar).  
- Retrieves one or more variables (var=) from the matched master record and assigns them to the current Data step (PDV).  .  

### How matching works (conceptual)  
- The master data are internally prepared with an observation sequence identifier (___row_number) to provide deterministic tie-breaking.  
- The macro scans candidate master records within the same key group and determines a winner based on rolltype= and distance limits.  
- Ties (same direction and same distance) are resolved by choosing the record with the smallest original master observation number (earliest stored observation).  
- Optionally emits a WARNING message when ties/duplicates are encountered (dupWARN=Y).  

### Parameters  
~~~text
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
~~~
### Outputs / side effects  
- The macro does not create a standalone output dataset by itself; it operates within a DATA step and populates var= in the current PDV.  
- Temporary internal views are created and dropped automatically.  
- When no match is found, the requested var= variables are set to missing.  
- When dupWARN=Y, warning messages may appear in the SAS log for tied candidates.  

### Usage examples  
#### Test Data
~~~sas
data A;
ID=1;TIME=-1;output;
ID=1;TIME=2;output;
ID=1;TIME=5;output;
ID=1;TIME=10;output;
ID=2;TIME=2;output;
ID=2;TIME=5;output;
ID=2;TIME=10;output;
ID=2;TIME=16;output;
run;

data B;
ID=1;TIME=4;VAL="B";VAL2=1;output;
ID=1;TIME=1;VAL="A";VAL2=2;output;
ID=1;TIME=6;VAL="C";VAL2=3;output;
ID=1;TIME=10;VAL="D";VAL2=4;output;
ID=2;TIME=2;VAL="E";VAL2=10;output;
ID=2;TIME=5;VAL="F";VAL2=10;output;
ID=2;TIME=10;VAL="G";VAL2=30;output;
ID=2;TIME=10;VAL="H";VAL2=40;output;
run;
~~~
<img width="172" height="132" alt="image" src="https://github.com/user-attachments/assets/88f9aa06-eebb-4e0c-83c2-4162b4f44df1" />
<img width="251" height="133" alt="image" src="https://github.com/user-attachments/assets/552f5968-a333-4488-b96c-845f1adfb768" />

  
1) Basic BACK (default) with no distance limit
~~~sas
data out_back;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=BACK, var=VAL VAL2);  
run;  
~~~
<img width="253" height="132" alt="image" src="https://github.com/user-attachments/assets/378156d3-1daf-4680-b4a0-409689a0200f" />  

2) BACK with a backward distance limit (e.g., within 3 units)
~~~sas
data out_back_lim;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=BACK, roll_back_limit=3, var=VAL);  
run;  
~~~
3) FORWARD with a forward distance limit (e.g., within 5 units)
~~~sas
data out_fwd_lim;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=FORWARD, roll_forward_limit=5, var=VAL);  
run;  
~~~
4) NEAREST with default tie direction (BACK: prefer past when equidistant)
~~~sas
data out_nearest_back;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=NEAREST, var=VAL);  
run;  
~~~
5) NEAREST preferring future when equidistant
~~~sas
data out_nearest_fwd;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=NEAREST, var=VAL, nearest_tie_dir=FORWARD);  
run;  
~~~
6) NEAREST with symmetric limits (both past and future constrained)
~~~sas
data out_nearest_lim;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=NEAREST, var=VAL, roll_back_limit=3, roll_forward_limit=5);  
run;  
~~~
7) Restrict master candidates with wh= (example: only non-missing values)
~~~sas
data out_wh;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=BACK, var=VAL, wh=%nrbquote(not missing(VAL)));  
run;  
~~~
8) Retrieve multiple variables from master
~~~sas
data out_multi;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=BACK, var=VAL OTHERFLAG);  
run;  
~~~
9) Composite keys (multiple key variables)
~~~sas
data out_keys;  
  set A2;  
  %rolling_match(master=B2, key=STUDYID USUBJID, rollvar=ADY, rolltype=NEAREST, var=PARAMCD AVAL, nearest_tie_dir=BACK);  
run;  
~~~

10) Suppress duplicate/tie warnings
~~~sas
data out_nowarn;  
  set A;  
  %rolling_match(master=B, key=ID, rollvar=TIME, rolltype=NEAREST, var=VAL, dupWARN=N);  
run;  
~~~

Notes  
- Ensure that rollvar has comparable scale/units between the current dataset and the master dataset.  
- Ensure that key variables uniquely define intended matching groups; ties may occur if the master contains duplicate candidates at the same distance.  
- The macro is intended to be invoked inside a DATA step (it uses PDV and hash objects).

  
---

## `%varconf_merge()` macro <a name="varconfmerge-macro-1"></a> ######
Purpose:    Perform a conditional merge between two SAS datasets with automated variable conflict handling.  
  
 Description:  
    This macro merges two datasets while automatically detecting and renaming variables that exist in both datasets (except BY variables).  
    It supports conditional inclusion of observations based on IN flags and allows optional automatic sorting before merging.  

 Parameters:  
 ~~~text
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
~~~

 Features:  
    - Automatically detects overlapping variable names (excluding BY variables)
    - Renames conflicting variables as varname_DS1 / varname_DS2

 Usage Example:  
 ~~~sas
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
~~~

<img width="682" height="158" alt="Image" src="https://github.com/user-attachments/assets/43a3e935-1a7b-4fe1-876c-f40523ef9f9c" />  

▼  
▼  
▼  

<img width="488" height="166" alt="Image" src="https://github.com/user-attachments/assets/46b752cb-bfa1-436e-a85c-ba1d358b7045" />  

~~~sas
   %varconf_merge(
       ds1=wk1,
       ds2=wk2,
       byvars=x,
       output_ds=merge_output2,
       in1=1,
       auto_sort=N
   );
~~~
<img width="762" height="154" alt="Image" src="https://github.com/user-attachments/assets/c37abfaf-7c0d-4a3a-bc70-10a40fa061c3" />

---

 

## Notes on versions history
- 0.2.0(05December2026): Add Rolling match.
- 0.1.0(24October2025): Initial version.

---

## What is SAS Packages?

The package is built on top of **SAS Packages Framework(SPF)** developed by Bartosz Jablonski.

For more information about the framework, see [SAS Packages Framework](https://github.com/yabwon/SAS_PACKAGES).

You can also find more SAS Packages (SASPacs) in the [SAS Packages Archive(SASPAC)](https://github.com/SASPAC).

## How to use SAS Packages? (quick start)

### 1. Set-up SAS Packages Framework

First, create a directory for your packages and assign a `packages` fileref to it.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
filename packages "\path\to\your\packages";
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Secondly, enable the SAS Packages Framework.
(If you don't have SAS Packages Framework installed, follow the instruction in 
[SPF documentation](https://github.com/yabwon/SAS_PACKAGES/tree/main/SPF/Documentation) 
to install SAS Packages Framework.)

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
%include packages(SPFinit.sas)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


### 2. Install SAS package

Install SAS package you want to use with the SPF's `%installPackage()` macro.

- For packages located in **SAS Packages Archive(SASPAC)** run:
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
  %installPackage(packageName)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- For packages located in **PharmaForest** run:
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
  %installPackage(packageName, mirror=PharmaForest)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- For packages located at some network location run:
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
  %installPackage(packageName, sourcePath=https://some/internet/location/for/packages)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  (e.g. `%installPackage(ABC, sourcePath=https://github.com/SomeRepo/ABC/raw/main/)`)


### 3. Load SAS package

Load SAS package you want to use with the SPF's `%loadPackage()` macro.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
%loadPackage(packageName)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


### Enjoy!



