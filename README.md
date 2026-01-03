# mergex
MERGEX is a package that enables non-standard or unconventional joins not easily handled or supported by standard SAS syntax.
It currently implements variable-name conflict-safe joins, and rolling joins .

<img width="360" height="360" alt="Image" src="https://github.com/user-attachments/assets/eb5050c7-3866-4244-9bad-57cc0d7b956e" />


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



