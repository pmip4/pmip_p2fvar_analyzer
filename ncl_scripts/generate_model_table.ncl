;This script makes a table showing the available simulations and how many years exist for each.
; It makes full use of the programs in cvdp_data.functions.ncl to plot figures solely from the output data of cvdp (without needing recomputation).
; It has been used in Brown et al (2020) and Brierley & Wainer (2018). 

; The script should be run in ncl_scripts/ with 
; > ncl -n generate_model_table.ncl

; Define some input parameters
variable_name="nino34"
expts=(/"piControl","historical","midHolocene-cal-adj","lgm-cal-adj","lig127k-cal-adj","1pctCO2","abrupt4xCO2"/)

; Define some parameters around the output table
out_dir="./" ;relative to ncl_scripts/ (present directory). Needs trailing /
output_format="tex" ; options are "tex" or "csv"
filename="model_table" ;

; Set options
GCM_DICTIONARY=False; if True, will not print model names, but alphabetic look up from table

;load the functions
loadscript("./cvdp_data.functions.ncl")

if GCM_DICTIONARY then
  ;create a translation table if needed
  gcm_dict=createGCMsNameDictionary(expts,variable_name)
end if

; combine various user settings to determine the filepath of output
filepath=output_dir+filename+output_format

; Actually make the table
if GCM_DICTIONARY then
  createTableGCMsExptsYears(expts,variable_name,gcm_dict,output_format,filepath)
else
  createTableGCMsExptsYears(expts,variable_name,False,output_format,filepath)
end if