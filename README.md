# mergex
MERGEX is a package that enables non-standard or unconventional joins not easily handled or supported by standard SAS syntax. It currently implements variable-name conflict-safe joins, and will support rolling joins and other advanced join types in future releases.

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

<img width="258" height="146" alt="Image" src="https://github.com/user-attachments/assets/d83e1c98-935c-4a01-af26-c888c80a7101" />
<img width="258" height="146" alt="Image" src="https://github.com/user-attachments/assets/42e52a83-2802-447c-b428-5215929f9581" /> 
↓  
<img width="488" height="166" alt="Image" src="https://github.com/user-attachments/assets/46b752cb-bfa1-436e-a85c-ba1d358b7045" />


---
 
