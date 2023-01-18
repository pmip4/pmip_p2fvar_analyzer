;This script cycles through all the files in a "data_netcdf" directory and calculates the standard devations of the timeseries and their correlations/regressions

;History:
; 1. It was originally used to create the supplementary table for Brierley & Wainer (2018) - although that was then tidied up in Excel to make it presentable
; 2. It was then modified to output amplitude of EOF-based indexs, as well as index-based ones. The output of this script was then plotted as Fig 3 in Rehfeld et al (2020,Earth Sys. Dynam.)
; 3. Now it's being overwritten to provide some tables as inputs for my PMIP4_past2future_analyzer repo

; run with:
; ncl -n owner_scripts/mk_index_tables.ncl from the main directory

load "ncl_scripts/cvdp_data.functions.ncl"

PRINT_OUT_CSV=True
OVERWRITE_INTERIM=True

;data_dir="data_netcdfs"
data_dir="/home/p2f-v/public_html/PMIPVarData/cvdp_data"
models=systemfunc("ls -I README -I C20-Reanalysis -I AWI-ESM-old /data/CMIP/curated_ESGF_replica")
;models=(/"IPSL-CM6A-LR","IPSL-CM5A-LR"/)
model_id=ispan(0, dimsizes(models)-1,1)
models!0="model_id"
models&model_id=model_id
expts=(/"piControl","midHolocene","lgm","lig127k","midPliocene-eoi400","midHolocene-cal-adj","lgm-cal-adj","lig127k-cal-adj","1pctCO2","abrupt4xCO2","rcp26","rcp85"/)
expt_id=ispan(0, dimsizes(expts)-1,1)
expts!0="expt_id"
expts&expt_id=expt_id
timeseries=(/"amoc_timeseries_ann","sic_nh_extent_climo_min","sic_nh_area_climo_min"/)
patterns=(/"tas_spatialmean_ann","pr_spatialmean_ann","tas_spatialmean_jja","pr_spatialmean_jja"/)
patterns_regions=(/(/(/-90.,90./),(/0.,359./)/),\ ;tas_spatialmean_ann - global mean 
                   (/(/-90.,90./),(/0.,359./)/),\ ;pr_spatialmean_ann - global mean
                   (/(/0.,90./),(/0.,359./)/),\ ;tas_spatialmean_jja - summer land NH 
                   (/(/0.,90./),(/0.,359./)/)/) ;pr_spatialmean_jja - summer land NH
patterns_stat=(/"mean","mean","mean_lnd","mean_lnd"/)
patterns_human_names=(/"global_mean_absolute_temperatures","global_mean_precipitation","NH_terrestrial_summer_temperature","NH_terrestrial_summer_rainfall"/)

indexnames=array_append_record(timeseries, patterns, 0)
indexs_id=ispan(0, dimsizes(indexnames)-1,1)
indexnames!0="indexs_id"
indexnames&indexs_id=indexs_id

indexs_array=new((/dimsizes(models),dimsizes(expts),dimsizes(timeseries)+dimsizes(patterns)/),float)
indexs_array@_FillValue=default_fillvalue("float")
indexs_array!0="model_id"
indexs_array&model_id=model_id
indexs_array!1="expt_id"
indexs_array&expt_id=expt_id
indexs_array!2="indexs_id"
indexs_array&indexs_id=indexs_id

interim_filename="owner_scripts/indexs_array.nc"
if .not.fileexists(interim_filename).or.OVERWRITE_INTERIM then
  setfileoption("nc", "Format",  "NetCDF4")
  do mod_i=0,dimsizes(models)-1
    do expt_i=0,dimsizes(expts)-1
      filenames=systemfunc("ls "+data_dir+"/"+models(mod_i)+"_"+expts(expt_i)+".cvdp_data.*-*.nc 2>/dev/null")
      if all(ismissing(filenames)) then 
        indexs_array(mod_i,expt_i,:)=indexs_array@_FillValue
      else ;file exists
        if dimsizes(filenames).ne.1 then
           print("ERROR: "+models(mod_i)+"_"+expts(expt_i)+".cvdp_data.*-*.nc results in multiple files")
          exit()
        else
          print("Working on "+filenames)
          ts_opt=True
          ts_opt@NO_EXIT_ON_ERROR=True
          if any(expts(expt_i).eq.(/"1pctCO2","abrupt4xCO2","rcp26","rcp85"/)) then
            ts_opt@subset=True
            ts_opt@subset_syear=-30
            ts_opt@subset_eyear=0
            ts_opt@DETREND=True
          end if
          do ts_i=0,dimsizes(timeseries)-1
            done_special_behaviour=False
            if isStrSubset(timeseries(ts_i),"global") then
              foo_str=str_sub_str(timeseries(ts_i),"mon_stddev","mon")
              indexs_array(mod_i,expt_i,ts_i)=(/stat_ts_var(filenames,foo_str,"stddev",ts_opt)/)
              delete(foo_str)
              done_special_behaviour=True
            end if
            if isStrSubset(timeseries(ts_i),"amoc") then
              indexs_array(mod_i,expt_i,ts_i)=(/stat_ts_var(filenames,timeseries(ts_i),"mean",ts_opt)/)
              done_special_behaviour=True
            end if
            if isStrSubset(timeseries(ts_i),"sic").and.isStrSubset(timeseries(ts_i),"min") then
              foo_str=str_sub_str(timeseries(ts_i),"climo_min","climo");strip off _min
              indexs_array(mod_i,expt_i,ts_i)=(/stat_ts_var(filenames,foo_str,"min",ts_opt)/)
              delete(foo_str)
              done_special_behaviour=True
            end if
            if (timeseries(ts_i).eq."nino34_skew") then
              indexs_array(mod_i,expt_i,ts_i)=(/stat_ts_var(filenames,"nino34","skew",ts_opt)/)
              done_special_behaviour=True
            end if
            if .not.done_special_behaviour then
              indexs_array(mod_i,expt_i,ts_i)=(/stat_ts_var(filenames,timeseries(ts_i),"mean",ts_opt)/)
            end if
          end do ;ts_i
          do patt_i=0,dimsizes(patterns)-1
            f=addfile(filenames,"r")
            if isfilevar(f,patterns(patt_i)) then
              indexs_array(mod_i,expt_i,dimsizes(timeseries)+patt_i)=extract_latlon_areastat(filenames,patterns(patt_i),patterns_regions(patt_i,0,:),patterns_regions(patt_i,1,:),patterns_stat(patt_i))
            else
              indexs_array(mod_i,expt_i,dimsizes(timeseries)+patt_i)=indexs_array@_FillValue
            end if
            delete(f)
          end do
          delete(ts_opt)
        end if; dimsizes(filenames).ne.1
      end if; all(ismissing(filenames))  
      delete(filenames)
    end do ;expt_i
  end do ;mod_i
  system("rm -f "+interim_filename)
  ifil=addfile(interim_filename,"c")
  ifil->indexs_array=indexs_array
  ifil->models=models
  ifil->expts=expts
  ifil->indexnames=indexnames
  delete(ifil)
else
  ifil=addfile(interim_filename,"r")
  indexs_array=ifil->indexs_array
end if

if PRINT_OUT_CSV then 
  ;write out values for each timeseries 
  hlist=[/"model,"+str_join(expts,",")/]
  do ts_i=0,dimsizes(timeseries)-1
    fname="tables/"+timeseries(ts_i)+".csv"
    write_table(fname, "w", hlist, "%s ")
    alist=NewList("lifo")
    ListAppend(alist,models)
    format_string="%s"
    do expt_i=0,dimsizes(expts)-1
      values=indexs_array(:,expt_i,ts_i)
      values@_FillValue=-999.
      str = unique_string("polymarker")
      values@$str$=values
     ListAppend(alist,values@$str$)
      format_string=format_string+",%5.2f"
    end do
    write_table(fname, "a", alist,format_string)
    delete([/alist,values,format_string,fname/])
  end do ;loop over timeseries 
  delete(hlist)
end if

if PRINT_OUT_CSV then 
  ;write out values for each pattern
  hlist=[/"model,"+str_join(expts,",")/]
  do patt_i=0,dimsizes(patterns)-1
    fname="tables/"+patterns_human_names(patt_i)+".csv"
    write_table(fname, "w", hlist, "%s ")
    alist=NewList("lifo")
    ListAppend(alist,models)
    format_string="%s"
    do expt_i=0,dimsizes(expts)-1
      values=indexs_array(:,expt_i,dimsizes(timeseries)+patt_i)
      values@_FillValue=-999.
      str = unique_string("polymarker")
      values@$str$=values
      ListAppend(alist,values@$str$)  
      format_string=format_string+",%5.2f"
    end do
    write_table(fname, "a", alist,format_string)
    delete([/alist,values,format_string,fname/])
  end do ;loop over timeseries 
  delete(hlist)
end if

;Change from piControl

;Write out the ensemble mean variance ratios
if PRINT_OUT_CSV then
  var_ratio_array=indexs_array(:,1:,:)^2/conform(indexs_array(:,1:,:), indexs_array(:,0,:),(/0,2/))^2
  ens_mn_var_ratio=dim_avg_n(var_ratio_array,0)
  ;write out values for each timeseries
  joint = array_append_record (timeseries, patterns, 0)
  hlist=[/"index,"+str_join(expts(1:),",")/];avoid piControl
  fname="data_frames/ensemble_mean_variance_ratio.csv"
  write_table(fname, "w", hlist, "%s ")
  alist=NewList("lifo")
  ListAppend(alist,joint)
  format_string="%s"
  do expt_i=0,dimsizes(expts)-2
    values=ens_mn_var_ratio(expt_i,:)
    values@_FillValue=-999.
    str = unique_string("polymarker")
    values@$str$=values
    ListAppend(alist,values@$str$)
    format_string=format_string+",%5.2f"
  end do
  write_table(fname, "a", alist,format_string)
  delete([/hlist,alist,values,format_string,fname/])
end if
