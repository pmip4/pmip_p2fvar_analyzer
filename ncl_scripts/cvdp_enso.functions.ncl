;=================================================================================================
; These functions are not required to run the CVDP software.
; Rather they are aimed at operating on resultant cvdp_enso.*.nc output files
; The aim of them is to allow easy plotting of say
;    - change in climate mode between two runs
;    - ensemble mean plots for certain experiments
;    - difference with observations
;
; Author: Chris Brierley, from Summer 2017
;         Forked off and rejigged for this repository in Summer 2019
;
;
; NOTE: all programs assume filenames like modelname_exptname.cvdp_enso.Y-Y.nc
;  The cvdp_enso files download from http://www.cesm.ucar.edu/working_groups/CVC/cvdp/data-repository.html
;  will need to be modified through e.g. "rename .cvdp_ rcp26.cvdp_ *.cvdp_enso.*.nc"

;=================================================================================================
; Check that the user-specified climatological period is within the time range of the data
;    copied from functions.ncl
undef("check_custom_climo")
procedure check_custom_climo(mn:string,startyear:numeric,endyear:numeric,climo_startyear:numeric,climo_endyear:numeric)
local startyear,endyear,climo_startyear,climo_endyear,mn
begin  
  do gg = 0,dimsizes(startyear)-1
     if (climo_startyear.ge.startyear(gg).and.climo_endyear.le.endyear(gg)) then
     else
        print("check_custom_climo: Warning! Beginning and/or ending of climatological period is outside time range of data.")
        print("Dataset: "+mn+", years = "+startyear(gg)+":"+endyear(gg)+", set climatological period = "+climo_startyear+":"+climo_endyear)
        print("The diagnostics package will proceed, but one or more dataset(s) will not have the full climatological period removed and/or tha package may fail with the following message: fatal:NclOneDValGetRangeIndex: start coordinate index out of range.")
     end if
  end do
end

;=================================================================================================
; find netcdf files that contain a desired variable and fit a filename string. 
;
undef("find_files_wVar")
function find_files_wVar(name_str:string,variable_name:string)
local data_dir,name_str,variable_name,fil
begin
  present_dir=systemfunc("pwd")
  if ismissing(str_match_ind(present_dir,"scripts")) then
    data_dir=present_dir+"/data/"
  else
    data_dir=present_dir+"/../data/"
  end if
  if isatt(name_str,"quiet") then
    QUIET=name_str@quiet
  else
    QUIET=False
  end if
  ncfiles=systemfunc("ls "+data_dir+"/*.cvdp_enso.[0-9]*-*.nc")
  if any(ismissing(ncfiles)) then
    if .not.QUIET then
     print("find_files_wVar: There are no cvdp_enso netcdf files in "+data_dir+". You may want to run the download_cvdp_enso_data.sh script")
    end if
    ncfiles_wVar="missing"
  else
    if any(ismissing(str_match_ind(ncfiles,name_str))) then
      if .not.QUIET then
        print("find_files_wVar: There are no cvdp_enso netcdf files in "+data_dir+"/ containing the string "+name_str)
      end if
      ncfiles_wVar="missing"
    else
      ncfiles_match=str_match(ncfiles,name_str)
      relevant=new((/dimsizes(ncfiles_match),dimsizes(variable_name)/),logical)
      relevant=(/False/)
      do i=0,dimsizes(ncfiles_match)-1
        this_file=ncfiles_match(i)
        if isfilepresent(this_file) then
          fil = addfile (this_file, "r")
          do var_i=0,dimsizes(variable_name)-1
            if isfilevar(fil,variable_name(var_i)) then
              relevant(i,var_i) = True
            end if
          end do
        end if
      end do
      if all(.not.(dim_num(relevant).eq.dimsizes(variable_name))) then
        ncfiles_wVar="missing"
        if .not.QUIET then
          print("find_files_wVar: There are no cvdp_enso netcdf files that contain "+name_str+" and have the requested variable")    
        end if
      else
        ncfiles_wVar=ncfiles_match(ind(dim_num(relevant).eq.dimsizes(variable_name)))
      end if
    end if
  end if
  return(ncfiles_wVar)
end;find_files_wVar

;===================================================================================================
; read in latlon variable from a file
; optionally interpolate onto a common 1x1 grid (to help with ensemble averaging)
undef("read_latlon_var")
function read_latlon_var(name_wfullpath:string,variable_name:string,REGRID:logical)
local name_wfullpath,variable_name,REGRID,fil
begin
  ;read in variable and perform some checks.
  if .not.isfilepresent(name_wfullpath) then
    ;Hard exit if not correct, as only valid files should have been selected with find_files_wVar  
    print("There is not a appropriate file called "+name_wfullpath)
    exit
  end if
  fil=addfile(name_wfullpath,"r")
  if .not.isfilevar(fil,variable_name) then
    ;Hard exit if not correct, as only valid files should have been selected with find_files_wVar  
    print("There is not a "+variable_name+" variable in "+name_wfullpath)
    exit
  end if
  var_in = fil->$variable_name$

  ;rename the (x,y) variables for later compatibility
  if var_in!0.eq."latitude" then
    var_in!0="lat"
  end if
  if var_in!1.eq."longitude" then
    var_in!1="lon"
  end if
  
  
  if REGRID then
    a = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
    lsdata = a->LSMASK
    lat=lsdata&lat
    lat@axis = "Y"
    lat@long_name = "latitude"
    lat@standard_name = "latitude"
    lon=lsdata&lon
    lon@axis = "X" 
    lon@long_name = "longitude"
    lon@standard_name = "longitude"
    var_out=new((/dimsizes(lat),dimsizes(lon)/),float,getFillValue(var_in))
    var_out!0="lat"
    var_out&lat=lat
    var_out!1="lon"
    var_out&lon=lon
    copy_VarAtts(var_in,var_out)
    var_out=linint2(var_in&lon,var_in&lat,var_in,True,lon,lat,0)
    var_out@regrid="regridded from native grid using bilinear interpolation"
  else
    var_out=var_in
  end if
  
  return(var_out)
end;read_latlon_var

;===================================================================================================
; read in latlon variable from two files
; compute the difference in them
; optionally interpolate onto a common 1x1 grid (to help with ensemble averaging)
undef("read_diff_latlon_var")
function read_diff_latlon_var(name_wfullpath_a:string,name_wfullpath_b:string,variable_name:string,REGRID:logical)
; path for TS file(s), variable name, start year, and end year are read in.
local name_wfullpath_a,name_wfullpath_b,variable_name,REGRID,fil
begin
  ;read in variable and perform some checks.
  if .not.isfilepresent(name_wfullpath_b).or..not.isfilepresent(name_wfullpath_a) then
    ;Hard exit if not correct, as only valid files should have been selected with find_files_wVar  
    print("There is either not a appropriate file called "+name_wfullpath_a+" or "+name_wfullpath_b)
    exit
  end if
  fila=addfile(name_wfullpath_a,"r")
  if .not.isfilevar(fila,variable_name) then
    ;Hard exit if not correct, as only valid files should have been selected with find_files_wVar  
    print("There is not a "+variable_name+" variable in "+name_wfullpath_a)
    exit
  end if
  var_in_a = fila->$variable_name$
  filb=addfile(name_wfullpath_b,"r")
  if .not.isfilevar(filb,variable_name) then
    ;Hard exit if not correct, as only valid files should have been selected with find_files_wVar  
    print("There is not a "+variable_name+" variable in "+name_wfullpath_b)
    exit
  end if
  var_in_b = filb->$variable_name$
  diff_in=var_in_a
  diff_in=var_in_a-var_in_b
  diff_in@difference=name_wfullpath_a+" - "+name_wfullpath_b
  
  ;rename the (x,y) variables for later compatibility
  if diff_in!0.eq."latitude" then
    diff_in!0="lat"
  end if
  if diff_in!1.eq."longitude" then
    diff_in!1="lon"
  end if
  
  if REGRID then
    a = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
    lsdata = a->LSMASK
    lat=lsdata&lat
    lat@axis = "Y"
    lat@long_name = "latitude"
    lat@standard_name = "latitude"
    lon=lsdata&lon
    lon@axis = "X"
    lon@long_name = "longitude"
    lon@standard_name = "longitude"
    diff_out=new((/dimsizes(lat),dimsizes(lon)/),float,getFillValue(diff_in))
    diff_out!0="lat"
    diff_out&lat=lat
    diff_out!1="lon"
    diff_out&lon=lon
    copy_VarAtts(diff_in,diff_out)
    diff_out=linint2(diff_in&lon,diff_in&lat,diff_in,True,lon,lat,0)
    diff_out@regrid="regridded from native grid using bilinear interpolation"
  else
    diff_out=diff_in
  end if
  
  return(diff_out)
end;read_diff_latlon_var 

;===================================================================================================
; extract a summary statistic for a region of a latlon variable from a file
undef("extract_latlon_areastat")
function extract_latlon_areastat(name_wfullpath:string,variable_name:string,lat_range:numeric,lon_range:numeric,stat_name:string)
local name_wfullpath,variable_name,fil,lat_range,lon_range,stat_name
begin
  poss_stats=(/"mean","stddev"/)
  if .not.any(poss_stats.eq.stat_name) then
    print("extract_latlon_areastat: The only possible statistics currently accepted are "+str_join(poss_stats,","))
    exit
  end if
  ;read in variable and perform some checks.
  if .not.isfilepresent(name_wfullpath) then
    ;Hard exit if not correct, as only valid files should have been selected with find_files_wVar  
    print("extract_latlon_areastat: There is not a appropriate file called "+name_wfullpath)
    exit
  end if
  fil=addfile(name_wfullpath,"r")
  if .not.isfilevar(fil,variable_name) then
    ;Hard exit if not correct, as only valid files should have been selected with find_files_wVar  
    print("extract_latlon_areastat: There is not a "+variable_name+" variable in "+name_wfullpath)
    exit
  end if
  var_in = fil->$variable_name$

  ;rename the (x,y) variables for later compatibility
  if var_in!0.eq."latitude" then
    var_in!0="lat"
  end if
  if var_in!1.eq."longitude" then
    var_in!1="lon"
  end if
  
  if .not.isdim(var_in,"lat") then
    print("extract_latlon_areastat:"+variable_name+" does not have a latitude dimension in "+name_wfullpath)
    exit
    ;not testing longitude as may need to apply this script for amoc at some point
  end if    

  lon_range_posi=lon_range.ge.180.and.lon_range.le.360
  lon_range_negi=lon_range.ge.-180.and.lon_range.lt.0
  if any(lon_range_negi) then
    if any(lon_range_posi) then
      print("extract_latlon_areastat: Your lon_range is ("+lon_range(0)+","+lon_range(1)+") and I don't whether to use longitude of (-180:180) or (0:360)")
      exit
    else
      var_in=lonFlip(var_in)
    end if
  end if
  
  ;extract subset and calculate lat. weights
  wgts=NormCosWgtGlobe(var_in&lat)
  wgts!0="lat"
  wgts&lat=var_in&lat
  subset=var_in({lat|lat_range(0):lat_range(1)},{lon|lon_range(0):lon_range(1)})
  wgts_subset=wgts({lat_range(0):lat_range(1)})

  ;Calculate statistics
  if stat_name.eq."mean".or.stat_name.eq."stddev" then
    area_mn=wgt_areaave_Wrap(subset,wgts_subset,1.,0)
    var_out=area_mn
    if stat_name.eq."stddev" then
      subset=(/(subset-area_mn)^2/)
      var_out=sqrt(wgt_areaave(subset,wgts_subset,1.,0))
    end if      
  end if
  
  return(var_out)
end;read_latlon_var

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
undef("find_pair_files_wVar")
function find_pair_files_wVar(name_str_a:string,name_str_b:string,variable_name:string)
local name_str_a,name_str_b,variable_name,ncfile_wVar_a,ncfiles_wVar_b,match_count,name_i,ncfiles_wVar_both
begin
  if isStrSubset(name_str_b,name_str_a).or.isStrSubset(name_str_a,name_str_b) then
    print("find_pair_files_wVar: This program cannot work with one name string being a subset of the other")
    print("find_pair_files_wVar:  You may want to rename your cvdp_enso files")
    exit
  end if
  ncfiles_wVar_a=find_files_wVar(name_str_a,variable_name)
  ncfiles_wVar_b=find_files_wVar(name_str_b,variable_name)
  ncfiles_wVar_both=new((/dimsizes(ncfiles_wVar_a),2/),string) ;create a holding array for the matching ones
  match_count=0
  do name_i=0,dimsizes(ncfiles_wVar_a)-1
    a_nopath=str_get_field(ncfiles_wVar_a(name_i),str_fields_count(ncfiles_wVar_a(name_i),"/"),"/")
    gcm=str_get_field(str_sub_str(a_nopath,name_str_a,":"),1,":")
    if .not.any(ismissing(str_match_ind(ncfiles_wVar_b,gcm))) then
      if dimsizes(str_match_ind(ncfiles_wVar_b,gcm)).ne.1 then
        print("find_pair_files_wVar: I've found multiple gcm id matches for "+gcm+" in "+name_str_a)
        print("find_pair_files_wVar:  I'm not sure how to continue.")
        print("find_pair_files_wVar:   matches = "+str_match(ncfiles_wVar_b,gcm))
        exit
      else
        ncfiles_wVar_both(match_count,0)=ncfiles_wVar_a(name_i)
        ncfiles_wVar_both(match_count,1)=str_match(ncfiles_wVar_b,gcm)
        match_count=match_count+1
      end if
    end if
  end do

  if match_count.eq.0 then
    print("find_pair_files_wVar: No matches found for cvdp_enso names that differ solely by having "+name_str_b+" instead of "+name_str_a+" at the end")
    ncfiles_wVar="missing"
  else
    ncfiles_wVar=ncfiles_wVar_both(ind(.not.ismissing(ncfiles_wVar_both(:,0))),:)
  end if
  
  return(ncfiles_wVar)
end;find_pair_files_wVar

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Program to run up a quick plot of a field 
undef("roughlatlonplot")
procedure roughlatlonplot(Field)
local title,res,wks,plot
begin

  if dimsizes(dimsizes(Field)).ne.2 then
    print("Input only 2D latxlon arrays, please.")
    return
  end if

  if isatt(Field,"long_name") then
    title="rough plot of "+Field@long_name
  else
    title="rough plot"
  end if

  wks=gsn_open_wks("X11",title) 
  gsn_define_colormap(wks,"rainbow")
  res                       = True                ; plot mods desired
  res@cnFillMode            = "RasterFill"       ; raster plot
  res@cnFillOn              = True
  if isatt(Field,"cnLinesOn") then
    res@cnLinesOn = Field@cnLinesOn
  else
    res@cnLinesOn             = True
  end if
  res@cnLineLabelsOn        = True
  res@cnLevelSelectionMode  = "AutomaticLevels" 
  res@gsnSpreadColors	  = True 
  res@gsnDraw               = True
  res@gsnFrame              = True
  res@gsnAddCyclic          = False
  if isatt(Field,"valid_range") then
    res@cnLevelSelectionMode  = "ManualLevels" 
    res@cnMaxLevelValF       =  Field@valid_range(1)
    res@cnMinLevelValF       =  Field@valid_range(0)
    res@cnLevelSpacingF      =  (Field@valid_range(1)-Field@valid_range(0))/10.
  end if
  if isatt(Field,"plotLatLons") then
    res@mpLimitMode="LatLon"
    res@mpMinLatF =  Field@plotLatLons(0)
    res@mpMaxLatF =  Field@plotLatLons(1)
    res@mpMinLonF =  Field@plotLatLons(2)
    res@mpMaxLonF =  Field@plotLatLons(3)
  end if
  plot = gsn_csm_contour_map(wks,Field,res)
  delete(wks)
end;roughlatlonplot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;===================================================================================================
; read in a timeseries and return it along with its metadata (including @AnnCycle)
; options: ts_opt@renorm_climo=True alters when is the climatological period (set by ts_opt@renorm_climo_syear and ts_opt@renorm_climo_eyear) 
;          ts_opt@subset=True just strips out a subset of the timeseries [starting in ts_opt@subset_syear and ending ts_opt@subset_eyear)
;          ts_opt@SEASON="DJF","MAM","JJA","SON" will convert a monthly timeseries into a seasonal one and return that. Also supports "ANN" for annual mean
;          ts_opt@DETREND=True removes a linear trend from the timeseries
;          ts_opt@RUN_STDDEV=True returns the running standard deviation of the timeseries rather than the timeseries itself
;                                 It is caluclated over ts_opt@nstddev timepoints, which defaults to 30 years
;          ts_opt@make_absolute=True will add the Annual Cycle back onto the timeseries (stopping it being anomalies)
;          ts_opt@NO_EXIT_ON_ERROR=True will override the default behaviour of failing upon error   
undef("read_ts")
function read_ts(name_wfullpath:string,variable_name:string,ts_opt:logical)
local name_wfullpath,variable_name,ts_opt,fil,var_in,eyear,syear,file_years,file_syear,file_eyear,nmo,anncyc_correction,AnnCycle
begin
  ;read in variable and perform some checks.
  if ts_opt.and.isatt(ts_opt,"NO_EXIT_ON_ERROR") then  
    NO_EXIT_ON_ERROR=ts_opt@NO_EXIT_ON_ERROR
    missing=default_fillvalue("float")
    missing@_FillValue=default_fillvalue("float")
  else
    NO_EXIT_ON_ERROR=False
  end if
  if .not.isfilepresent(name_wfullpath) then
    ;Hard exit if not correct, as only valid files should have been selected with find_files_wVar  
    if NO_EXIT_ON_ERROR then
      return(missing)
    else
      print("There is not a appropriate file called "+name_wfullpath)
      exit
    end if
  end if
  fil=addfile(name_wfullpath,"r")
  if any(variable_name.eq.(/"NWP","NCT"/)) then
    if .not.isfilevar(fil,"nino34") then
      if NO_EXIT_ON_ERROR then
        return(missing)
      else
        ;Hard exit if not correct, as only valid files should have been selected with find_files_wVar  
        print("There is not a "+variable_name+" variable in "+name_wfullpath)
        exit
      end if 
    end if
    nino3=fil->nino3
    nino4=fil->nino4
    alpha=nino3*nino4 ;set up alpha array
    alpha=where(alpha.gt.0,0.4,0)
    var_in=nino3
    if variable_name.eq."NWP" then
      var_in=nino3-alpha*nino4;NCT
    else
      var_in=nino4-alpha*nino3;NWP
    end if
    delete([/nino3,nino4,alpha/])
  else
    if .not.isfilevar(fil,variable_name) then
      if NO_EXIT_ON_ERROR then
        return(missing)
      else
        ;Hard exit if not correct, as only valid files should have been selected with find_files_wVar  
        print("There is not a "+variable_name+" variable in "+name_wfullpath)
        exit
      end if 
    end if
    var_in = fil->$variable_name$
  end if

  read_ts_note=""
  if .not.(isdim(var_in,"time").or.isdim(var_in,"TIME")) then
    if NO_EXIT_ON_ERROR then
      return(missing)
    else
      print("read_ts: "+variable_name+" does not have a time or TIME dimension. Suspect this is not a timeseries")
      exit
    end if 
  end if
  
  if ts_opt.and.isatt(ts_opt,"make_absolute").and.ts_opt@make_absolute then
    if .not.isStrSubset(variable_name,"monsoon") then 
      ;ignore monsoon as they are already absolute variables
      if .not.isatt(var_in,"AnnCycle").or.(dimsizes(var_in@AnnCycle).ne.12) then
        if NO_EXIT_ON_ERROR then
          return(missing)
        else
          print("read_ts: you have asked for make_absolute, but "+variable_name+" does not have a viable AnnCycle attribute")
          exit
        end if 
      else
        AnnCycle=var_in@AnnCycle
        do yr=0,dimsizes(var_in)-1,12
          var_in(yr:yr+11) = (/ var_in(yr:yr+11)+AnnCycle/)
        end do
      end if
    end if
  end if

  ;Renormalised the climatology, if requested
  if ts_opt.and.isatt(ts_opt,"renorm_climo").and.ts_opt@renorm_climo then
    if .not.isatt(ts_opt,"renorm_climo_syear").or..not.isatt(ts_opt,"renorm_climo_eyear") then
      print("read_ts: you have asked for renorm_climo, but not set the start or end year")
    else
      file_years=str_get_field(str_sub_str(name_wfullpath,"/../","/"),3,".")
      file_syear = stringtointeger(str_get_field(file_years,1,"-"))
      file_eyear = stringtointeger(str_get_field(file_years,2,"-"))
      if (ts_opt@renorm_climo_syear.gt.0) then
        check_custom_climo(name_wfullpath,file_syear,file_eyear,ts_opt@renorm_climo_syear,ts_opt@renorm_climo_eyear)
        syear=ts_opt@renorm_climo_syear-file_syear
        eyear=ts_opt@renorm_climo_eyear-file_syear
        read_ts_note=read_ts_note+"Renormed climatology to "+ts_opt@renorm_climo_syear+"-"+ts_opt@renorm_climo_eyear+". "
      else
        ;negative years are relative from end of the file  
        nyrs=(file_eyear-file_syear)+1
        if abs(ts_opt@renorm_climo_syear).gt.nyrs then
          print("read_ts: your relative climatolgy renormalisation starts before the file does")  
        else
          syear=nyrs+ts_opt@renorm_climo_syear
          eyear=nyrs+ts_opt@renorm_climo_eyear
          read_ts_note=read_ts_note+"Renormed climatology to yrs "+(file_eyear+ts_opt@renorm_climo_syear)+"-"+(file_eyear+ts_opt@renorm_climo_eyear)+". "
        end if
      end if
      if isdim(var_in,"time") then
        ;monthly timeseries
        anncyc_correction = new(12,typeof(var_in),getFillValue(var_in))
        do nmo=0,11
          anncyc_correction(nmo) = dim_avg(var_in(nmo+(syear-1)*12:nmo+(eyear-1)*12:12))
        end do
        if isatt(var_in,"AnnCycle") then
          AnnCycle=var_in@AnnCycle
          AnnCycle=AnnCycle+anncyc_correction
          var_in@AnnCycle=AnnCycle
        end if
        do yr=0,(file_eyear-file_syear),12
          var_in(yr:yr+11) = (/ var_in(yr:yr+11)- anncyc_correction /)
        end do
      else
        ;annual timeseries
        var_in=var_in-avg(var_in(syear-1:eyear))
      end if
    end if
  end if

  ;take just a subset of the timeseries
  if ts_opt.and.isatt(ts_opt,"subset").and.ts_opt@subset then
    if .not.isatt(ts_opt,"subset_syear").or..not.isatt(ts_opt,"subset_eyear") then
      print("read_ts: you have asked for 'subset', but not set start (subset_syear) or end (subset_eyear")
    else
      file_years=str_get_field(str_sub_str(name_wfullpath,"/../","/"),3,".")
      file_syear = stringtointeger(str_get_field(file_years,1,"-"))
      file_eyear = stringtointeger(str_get_field(file_years,2,"-"))
      if (ts_opt@subset_syear.gt.0) then
        check_custom_climo(name_wfullpath,file_syear,file_eyear,ts_opt@subset_syear,ts_opt@subset_eyear)
        syear=ts_opt@subset_syear-file_syear
        eyear=ts_opt@subset_eyear-file_syear
        read_ts_note=read_ts_note+"Taken subset from "+ts_opt@subset_syear+" to "+ts_opt@subset_eyear+". "
      else
        ;negative years are relative from end of the file  
        nyrs=(file_eyear-file_syear)+1
        if abs(ts_opt@subset_syear).gt.nyrs then
          print("read_ts: your relative temporal subset starts before the file does")  
        else
          syear=nyrs+ts_opt@subset_syear
          eyear=nyrs+ts_opt@subset_eyear
          read_ts_note=read_ts_note+"Taken subset of yrs "+(file_eyear+ts_opt@subset_syear)+"-"+(file_eyear+ts_opt@subset_eyear)+". "
        end if
      end if
      if isdim(var_in,"time") then ;monthly timeseries
        var_out = var_in((syear-1)*12:eyear*12-1)
      else ;annual timeseries
        var_out=var_in(syear-1:eyear-1)
      end if
    end if
  else
    var_out=var_in ;return whole timeseries if subset not specified
  end if

  ;Convert monthly to seasonal dataset
  if ts_opt.and.isatt(ts_opt,"SEASON") then
    if isdim(var_in,"time") then
      ;monthly timeseries
      seasons=(/"MAM","JJA","SON","DJF","ANN"/)
      if .not.any(seasons.eq.ts_opt@SEASON) then
        print("read_ts: SEASON is set to convert to "+ts_opt@SEASON+" but I only take MAM, JJA, SON and DJF")
        exit
      else
        if ts_opt@SEASON.eq."ANN" then
          var_seas=var_out(5::12);set up array
          var_seas=(/month_to_annual(var_out,1)/)
        else
          start_month=3*ind(seasons.eq.ts_opt@SEASON)-1
          var_seas=var_out(start_month::12);set up array
          var_seas=dim_avg_n((/var_out(start_month::12),var_out(start_month+1::12),var_out(start_month+2::12)/),0)
        end if
        delete(var_out)
        var_out=var_seas;switch over variable
        read_ts_note=read_ts_note+"Converted from monthly to "+ts_opt@SEASON+". "
      end if
    else
      print("read_ts: SEASON is set to convert to "+ts_opt@SEASON+" but "+variable_name+" is not a monthly timseries")
      exit
    end if  
  end if
  
  ;remove a linear trend from the timeseries
  if ts_opt.and.isatt(ts_opt,"DETREND").and.ts_opt@DETREND then
    if isdim(var_out,"time") then
      years=cd_calendar(var_out&time,4)
    else
      years=cd_calendar(var_out&TIME,4)
    end if
    var_out = dtrend_msg(years,var_out,True,False)
    read_ts_note=read_ts_note+"A linear trend has been removed. "
  end if

  
  if ts_opt.and.isatt(ts_opt,"RUN_STDDEV").and.ts_opt@RUN_STDDEV then
    if isatt(ts_opt,"nstddev") then
      nstddev=ts_opt@nstddev
    else
      if isdim(var_out,"time").and.(.not.isatt(ts_opt,"SEASON")) then
        nstddev=30*12 ;30 years
      else
        nstddev=30 ;30 years
      end if
    end if
    ts_stddev=var_out
    ;set beginning and end to missing
    ts_stddev(0:nstddev/2-1)=var_out@_FillValue
    ts_stddev(dimsizes(ts_stddev)-nstddev/2:dimsizes(ts_stddev)-1)=var_out@_FillValue
    do i=nstddev/2,dimsizes(ts_stddev)-nstddev/2-1
      ts_stddev(i)=dim_stddev(var_out(i-nstddev/2:i+nstddev/2))
    end do
    var_out=(/ts_stddev/)
    read_ts_note=read_ts_note+" The timeseries has been converted to a Running Standard Deviation over "+nstddev+" points. "
    delete([/ts_stddev,nstddev/])
  end if


  var_out@read_ts_note=read_ts_note
  return(var_out)
end;read_ts

;===================================================================================================
; return a single summary statistic for a timeseries
;   stat_name = either one of "mean","stddev","skew","kurtosis" (as computed by stat4)
;      or "pcvar", which gives the %-age variance explained (for EOF-based timeseries)
;      or "AnnCycAmp" which gives max(AnnCycle)-min(AnnCycle)

undef("stat_ts_var")
function stat_ts_var(name_wfullpath:string,variable_name:string,stat_name_in:string,ts_opt:logical)
local name_wfullpath,variable_name,ts_opt,fil,poss_stats,stat_name
begin
  ;read in variable and perform some checks.
  poss_stats=(/"mean","stddev","skew","kurtosis","pcvar","AnnCycAmp","stddev_bandpass_2-8yrs"/)
  if .not.any(poss_stats.eq.stat_name_in) then
    print("stat_ts_var: The only possible statistics accepted are "+str_join(poss_stats,","))
    exit
  else
    stat_name=stat_name_in
  end if
  
  var_in=read_ts(name_wfullpath,variable_name,ts_opt)
  
  if stat_name.eq."stddev_bandpass_2-8yrs" then
    ; deploy a 2-8 yrs bandpass filter and set the variable to "stddev"
    sigma = 1.0                           ; Lanczos sigma
    offset = 24                           ; loose 2 years at each end
    nwgt  = 2*offset+1                            
    low_thres = 1/(8.*12)                 ; freq for period of 8 yrs (1/months)
    hi_thres = 1/(2.*12)                  ; freq for period of 2 yrs (1/months)
    wgts_interann  = filwgts_lanczos (nwgt,2,low_thres,hi_thres,sigma)
    var_in=wgt_runave(var_in,wgts_interann,0)
    stat_name="stddev"
  end if
  
  if .not.all(ismissing(var_in)) then  
    if stat_name.eq."AnnCycAmp" then      
      if .not.isatt(var_in,"AnnCycle") then
        stat_out=default_fillvalue("float")
        stat_out@_FillValue=default_fillvalue("float")
      else
        stat_out=max(var_in@AnnCycle)-min(var_in@AnnCycle)
      end if
    else   
      if stat_name.eq."pcvar" then      
        pcvar=str_squeeze(str_sub_str(var_in@pcvar,"%"," "))
        stat_out=stringtofloat(pcvar)
      else
        stats=dim_stat4(var_in)
        stat_ind=ind(poss_stats.eq.stat_name)
        if stat_ind.gt.0.and.(all(var_in.eq.stats(0))) then
          ;If all the values are identical, only the mean is relevant
          stat_out=default_fillvalue("float")
          stat_out@_FillValue=default_fillvalue("float")
        else
          if stat_name.eq."stddev" then          
            stat_out=sqrt(stats(stat_ind))
          else
            stat_out=stats(stat_ind)
          end if
        end if 
      end if
      copy_VarAtts(var_in,stat_out)
      stat_out@stat=stat_name
    end if
  else
    stat_out=default_fillvalue("float")
    stat_out@_FillValue=default_fillvalue("float")
  end if

return(stat_out)
end;stat_ts_var

;===================================================================================================
; read in timeseries variable from multiple files
undef("read_ts_all")
function read_ts_all(name_str:string,variable_name:string,ts_opt:logical)
local name_str,variable_name,ncfiles,fil,var_in,file_years,file_syear,file_eyear
begin
  ;calculate the length of the longest timeseries (from the file and variable names)
  ncfiles=find_files_wVar(name_str,variable_name)
  max_years=0
  names=ncfiles
  do file_i=0,dimsizes(ncfiles)-1
    file_years=str_get_field(str_sub_str(ncfiles(file_i),".cvdp_enso.",":"),2,":")
    file_syear = stringtointeger(str_get_field(file_years,1,"-."))
    file_eyear = stringtointeger(str_get_field(file_years,2,"-."))
    length_years=file_eyear-file_syear+1
    if length_years.gt.max_years then
      max_years=length_years
      longest_file=file_i
    end if
    name_nopath=str_get_field(ncfiles(file_i),str_fields_count(ncfiles(file_i),"/"),"/")
    names(file_i)=str_get_field(str_sub_str(name_nopath,".cvdp_enso.",":"),1,":")
  end do

  ;determine if field is monthly or annual
  var_in = read_ts(ncfiles(longest_file),variable_name,ts_opt)
  if isdim(var_in,"time") then
    time=var_in&time
  else
    time=var_in&TIME
  end if
  var_out=new((/dimsizes(ncfiles),dimsizes(var_in)/),float)
  var_out!0="runs"
  var_out@run_names=names
  var_out!1="time"
  var_out&time=time
  copy_VarAtts(var_in,var_out)
  delete(var_in)
  
  ;read in the timeseries
  do file_i=0,dimsizes(ncfiles)-1
    var_in = read_ts(ncfiles(file_i),variable_name,ts_opt)
    var_out(file_i,0:dimsizes(var_in)-1)=(/var_in/)
    delete(var_in)
  end do
  
  return(var_out)
end;read_ts_all

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Plot obs vs ensemble mean maps ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
undef("plotCVDPcomparisonMaps")
procedure plotCVDPcomparisonMaps(strs,variable_name:string,wks_name,opt_res:logical,opt_panel_res:logical)
local mapres,panres,plots,ensmn,ensmn,patt,nvars,LeftStrings,RightStrings,CenterStrings,fnames,fnames,lat,lon,dims,opt_res,opt_panel_res
begin
; This has the supra-option of for opt_res NORMALISE and name_to_normalise_by

  if opt_res.and.isatt(opt_res,"NORMALISE") then
    ;this option will plot the ratio of the fields 
    NORMALISE=opt_res@NORMALISE
    delete(opt_res@NORMALISE)
    if isatt(opt_res,"name_to_normalise_by") then
      name_to_normalise_by=opt_res@name_to_normalise_by
      delete(opt_res@name_to_normalise_by)
    else
      print("You have selected NORMALISE, but not provided the attribute name by which to normalise it (as name_to_normalise_by)")
      exit
    end if
  else
    NORMALISE=False
  end if

  ;process some of the input variables
  nvars=dimsizes(variable_name)
  nstrs=dimsizes(strs)
  plots=new(nstrs*nvars,graphic)
  if isstring(wks_name) then
    ;Creating a new wks called wks_name
    if isatt(wks_name,"filetype") then
      wks=gsn_open_wks(wks_name@filetype,wks_name)
    else
      wks=gsn_open_wks("pdf",wks_name)
    end if
  else
    ;Adding this plot to pre-existing workstation
    wks=wks_name
  end if

  mapres = True
  ;Altering some defaults
  mapres@gsnDraw      = False
  mapres@gsnFrame     = False
  if nvars.eq.1 then
    mapres@lbLabelBarOn    = False
  end if
  mapres@cnLineLabelsOn = False
  mapres@cnFillOn        = True
  mapres@cnLinesOn       = False
  mapres@cnFillPalette = "BlueDarkRed18"
  mapres@mpGridAndLimbOn = True
  mapres@mpGridLatSpacingF =  15.            ; change latitude  line spacing
  mapres@mpGridLonSpacingF = 15.           ; change longitude line spacing

  ;copy across the optional resources
  copy_VarAtts(opt_res,mapres)

  ;using mpProjection as a major switch
  if isatt(mapres,"mpProjection").and.mapres@mpProjection.eq."WinkelTripel" then
    mapres@vpYF = 0.95
    mapres@vpHeightF = 0.3
    mapres@vpXF = 0.2
    mapres@vpWidthF = 0.6
    mapres@gsnLeftStringOrthogonalPosF = -0.05
    mapres@gsnLeftStringParallelPosF = .005
    mapres@gsnRightStringOrthogonalPosF = -0.05
    mapres@gsnRightStringParallelPosF = 0.96
    mapres@gsnLeftStringFontHeightF = 0.02
    mapres@gsnRightStringFontHeightF = 0.02
    mapres@mpGeophysicalLineColor = "gray42"
    mapres@mpPerimOn    = False
    mapres@mpGridLineColor   = "transparent"  ; trick ncl into drawing perimeter
  end if
  
  ;load in the optional ones
  if isatt(mapres,"gsnLeftString").and.dimsizes(mapres@gsnLeftString).eq.nstrs*nvars then
    LeftStrings=mapres@gsnLeftString
    delete(mapres@gsnLeftString)
  end if
  if isatt(mapres,"gsnRightString").and.dimsizes(mapres@gsnRightString).eq.nstrs*nvars then
    RightStrings=mapres@gsnRightString
    delete(mapres@gsnRightString)
  end if
  if isatt(mapres,"gsnCenterString").and.dimsizes(mapres@gsnCenterString).eq.nstrs*nvars then
    CenterStrings=mapres@gsnCenterString
    delete(mapres@gsnCenterString)
  end if
  if isatt(mapres,"tiMainString").and.dimsizes(mapres@tiMainString).eq.nstrs*nvars then
    MainStrings=mapres@tiMainString
    delete(mapres@tiMainString)
  end if
  
  panres=True
  if opt_panel_res then
    copy_VarAtts(opt_panel_res,panres)
  end if    
  panres_options=(/"gsnMaximize","gsnPaperOrientation","gsnPanelYWhiteSpacePercent"/)
  panres_new_defaults=True
  panres_new_defaults@gsnMaximize = True
  panres_new_defaults@gsnPaperOrientation = "portrait"
  panres_new_defaults@gsnPanelYWhiteSpacePercent = 3.0
  do i=0,dimsizes(panres_options)-1
    if .not.isatt(panres,panres_options(i)) then
      panres@$panres_options(i)$=panres_new_defaults@$panres_options(i)$
    end if
  end do
  if nvars.eq.1 then
    panres_singlevar_options=(/"gsnPanelLabelBar","pmLabelBarHeightF","pmLabelBarWidthF","lbBoxLineColor","lbTitleFontHeightF","lbTitlePosition","pmLabelBarOrthogonalPosF"/)
    panres_new_defaults@gsnPanelLabelBar = True
    panres_new_defaults@pmLabelBarHeightF = 0.05
    panres_new_defaults@pmLabelBarWidthF = 0.55
    panres_new_defaults@lbBoxLineColor = "gray70"
    panres_new_defaults@lbTitleFontHeightF = 0.014
    panres_new_defaults@lbTitlePosition = "Bottom"
    panres_new_defaults@pmLabelBarOrthogonalPosF=-0.05 
    do i=0,dimsizes(panres_singlevar_options)-1
      if .not.isatt(panres,panres_singlevar_options(i)) then
        panres@$panres_singlevar_options(i)$=panres_new_defaults@$panres_singlevar_options(i)$
      end if
    end do
  end if

  ;;determine names of files that have the correct field
  do str_i=0,nstrs-1
    do var_i=0,nvars-1
      fnames=find_files_wVar(strs(str_i),variable_name(var_i))
      dummy=read_latlon_var(fnames(0),variable_name(var_i),True)
      lat=dummy&lat
      lon=dummy&lon
      ensmn=dummy
      ;load and average historical
      patt=new((/dimsizes(fnames),dimsizes(lat),dimsizes(lon)/),float)
      patt!0="run"
      patt!1="lat"
      patt&lat=lat
      patt!2="lon" 
      patt&lon=lon
      if NORMALISE then
        norm_attrs=new(dimsizes(fnames),float)
      end if
      do mod_i=0,dimsizes(fnames)-1
        if isatt(wks_name,"VERBOSE").and.(wks_name@VERBOSE) then
          print("Loading "+variable_name(var_i)+" from file "+mod_i+":"+fnames(mod_i))
        end if
        if NORMALISE then
          this_patt=read_latlon_var(fnames(mod_i),variable_name(var_i),True)
          if (name_to_normalise_by.eq."relative_to_plot_area_average") then
            norm_attrs(mod_i)=extract_latlon_areastat(fnames(mod_i),variable_name(var_i),(/mapres@mpMinLatF,mapres@mpMaxLatF/),(/mapres@mpMinLonF,mapres@mpMaxLonF/),"mean")
            patt(mod_i,:,:)=(/this_patt-norm_attrs(mod_i)/)
          else
            norm_attrs(mod_i)=this_patt@$name_to_normalise_by$
            patt(mod_i,:,:)=(/this_patt/norm_attrs(mod_i)/)
          end if
          delete(this_patt)
        else
          patt(mod_i,:,:)=read_latlon_var(fnames(mod_i),variable_name(var_i),True)
        end if
      end do
      ensmn=(/dim_avg(patt(lat|:,lon|:,run|:))/)

      ;make the variable name the LabelBar title if not set
      if .not.isatt(panres,"lbTitleString") then
        panres@lbTitleString=dummy@long_name
        if NORMALISE then
          panres@lbTitleString="Normalised "+panres@lbTitleString
        end if
      end if
      mapres@lbTitleString=panres@lbTitleString
      
      ;now create the ensemble mean plot
      if isvar("LeftStrings") then
        mapres@gsnLeftString = LeftStrings(nvars*str_i+var_i)
      end if
      if isvar("RightStrings") then
        mapres@gsnRightString = RightStrings(nvars*str_i+var_i)
      else
        if NORMALISE then
          mapres@gsnRightString = avg(norm_attrs)       
        end if
      end if
      if isvar("CenterStrings") then
        mapres@gsnCenterString = CenterStrings(nvars*str_i+var_i)
      end if
      if isvar("MainStrings") then
        mapres@tiMainString = MainStrings(nvars*str_i+var_i)
      end if

      plots(nvars*str_i+var_i)=gsn_csm_contour_map(wks,ensmn,mapres) 
      if NORMALISE then
        delete([/patt,ensmn,dummy,fnames,norm_attrs/])
      else
        delete([/patt,ensmn,dummy,fnames/])
      end if
    end do;finish looping over the variables
  end do
  
  ;now panel all the plots together...
  if isatt(panres,"dims") then
    dims=panres@dims
    delete(panres@dims)
    gsn_panel(wks,plots,dims,panres)
  else
    gsn_panel(wks,plots,(/nstrs,nvars/),panres)
  end if
  if isstring(wks_name) then
    delete(wks)
  end if

  end;plotObsVsEnsMnMaps

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Plot obs vs ensemble mean maps ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
undef("plotDiffEnsMnMaps")
procedure plotDiffEnsMnMaps(expt_str_a:string,expt_str_b:string,variable_name:string,wks_name,opt_res_in:logical,opt_panel_res_in:logical)
local wks,mapres,panres,plots,ensmn,patt,nvars,LeftStrings,RightStrings,CenterStrings,fnames_both,lat,lon,dummy_for_latlon,opt_res,opt_pan_res,conf_res
begin

  ;process some of the input variables
  nvars=dimsizes(variable_name)
  plots=new(nvars,graphic)
  if isstring (wks_name) then
    ;have been given just a name for a workstation not an actual variable
    if isatt(wks_name,"filetype") then
      wks=gsn_open_wks(wks_name@filetype,wks_name)
    else
      wks=gsn_open_wks("pdf",wks_name)
    end if
  else
    ;use exiting workstation
    wks=wks_name
  end if
  opt_res=opt_res_in
  opt_panel_res=opt_panel_res_in

  ;Look for some major opt_res switches/attributes
  if isatt(wks_name,"VERBOSE").and.(wks_name@VERBOSE) then
    ;Provides a modicum of more information
    VERBOSE=wks_name@VERBOSE
  else
    VERBOSE=False
  end if
  if opt_res.and.isatt(opt_res,"CONSISTENCY") then
    ;this option stipples locations where >2/3 of the model have the same sign 
    CONSISTENCY=opt_res@CONSISTENCY
    delete(opt_res@CONSISTENCY)
  else
    CONSISTENCY=False
  end if
  if opt_res.and.isatt(opt_res,"OVERLAY_CONTROL") then
    ;this option will add some contour lines of the Ensemble Mean of B.
    OVERLAY_CONTROL=opt_res@OVERLAY_CONTROL
    delete(opt_res@OVERLAY_CONTROL)
    if isatt(opt_res,"OVERLAY_CONTROL_MANUALLEVS") then
      overlay_levs=opt_res@OVERLAY_CONTROL_MANUALLEVS
      delete(opt_res@OVERLAY_CONTROL_MANUALLEVS)
    end if
  else
    OVERLAY_CONTROL=False
  end if
  if opt_res.and.(isatt(opt_res,"MASK_TRIVIAL").or.isatt(opt_res,"TRIVIAL")) then
    ;this option will mask out any instances where the magnitude of both patterns is less than 10% of the global mean
    if isatt(opt_res,"MASK_TRIVIAL") then
      MASK_TRIVIAL=opt_res@MASK_TRIVIAL
      delete(opt_res@MASK_TRIVIAL)
    else
      MASK_TRIVIAL=opt_res@TRIVIAL
      delete(opt_res@TRIVIAL)
    end if
  else
    MASK_TRIVIAL=False
  end if
  if opt_res.and.isatt(opt_res,"RATIO") then
    ;this option will plot the ratio of the fields 
    RATIO=opt_res@RATIO
    delete(opt_res@RATIO)
  else
    RATIO=False
  end if
  if opt_res.and.isatt(opt_res,"PERCENTAGE") then
    ;this option will plot the ratio of the fields 
    PERCENTAGE=opt_res@PERCENTAGE
    delete(opt_res@PERCENTAGE)
  else
    PERCENTAGE=False
  end if
  if RATIO.and.PERCENTAGE then
    print("plotDiffEnsMnMaps: Both RATIO and PERCENTAGE have been selected. This is not valid.")
    print("plotDiffEnsMnMaps: RATIO is a/b and PERCENTAGE is 100*(a-b)/a - please go back and select the correct option")
    exit
  end if
  if opt_res.and.isatt(opt_res,"NORMALISE") then
    ;this option will plot the ratio of the fields 
    NORMALISE=opt_res@NORMALISE
    delete(opt_res@NORMALISE)
    if isatt(opt_res,"name_to_normalise_by") then
      name_to_normalise_by=opt_res@name_to_normalise_by
      delete(opt_res@name_to_normalise_by)
    else
      print("You have selected NORMALISE, but not provided the attribute name by which to normalise it (as name_to_normalise_by)")
      exit
    end if
  else
    NORMALISE=False
  end if

  if opt_res then
    if isatt(opt_res,"gsnLeftString").and.dimsizes(opt_res@gsnLeftString).eq.nvars then
      LeftStrings=opt_res@gsnLeftString
      delete(opt_res@gsnLeftString)
    end if
    if isatt(opt_res,"gsnRightString").and.dimsizes(opt_res@gsnRightString).eq.nvars then
      RightStrings=opt_res@gsnRightString
      delete(opt_res@gsnRightString)
    end if
    if isatt(opt_res,"tiMainString") then
      if dimsizes(opt_res@tiMainString).eq.nvars then
        CenterStrings=opt_res@tiMainString
        delete(opt_res@tiMainString)
      end if
    end if
  end if    
  
  ;set some default map plotting resources
  mapres = True
  mapres@gsnDraw      = False
  mapres@gsnFrame     = False
  mapres@cnLineLabelsOn = False
  mapres@cnFillOn        = True
  mapres@cnLinesOn       = False
  if CONSISTENCY then
    conf_res=mapres
    conf_plots=plots
    conf_res@lbLabelBarOn=False
  end if
  mapres@mpFillOn = False
  mapres@mpCenterLonF = -20.
  mapres@mpOutlineOn = True  
  mapres@cnFillPalette = "BlueWhiteOrangeRed"
  mapres@mpGridAndLimbOn = True
  mapres@mpGridLatSpacingF =  15.            ; change latitude  line spacing
  mapres@mpGridLonSpacingF = 15.           ; change longitude line spacing

  copy_VarAtts(opt_res,mapres)

  ;use mpProjection as a supra-option
  if isatt(mapres,"mpProjection").and.mapres@mpProjection.eq."WinkelTripel" then
    WinkTripSwitch=True
  else
    WinkTripSwitch=False
  end if
    
  if WinkTripSwitch then
    mapres@gsnLeftStringOrthogonalPosF = -0.05
    mapres@gsnLeftStringParallelPosF = .005
    mapres@gsnRightStringOrthogonalPosF = -0.05
    mapres@gsnRightStringParallelPosF = 0.96
    mapres@gsnLeftStringFontHeightF = 0.014
    mapres@gsnRightStringFontHeightF = 0.014
    mapres@vpYF = 0.95
    mapres@vpHeightF = 0.3
    mapres@vpXF = 0.2
    mapres@vpWidthF = 0.6
    mapres@mpGeophysicalLineColor = "gray42"
    mapres@mpPerimOn    = False
    mapres@mpGridLatSpacingF =  15.            ; change latitude  line spacing
    mapres@mpGridLonSpacingF = 15.           ; change longitude line spacing
    mapres@mpGridLineColor   = "transparent"  ; trick ncl into drawing perimeter
    mapres@mpGridAndLimbOn   = True           ; turn on lat/lon lines  
  end if
  ;load in the optional ones
  defaulted=True
  if (.not.isatt(mapres,"tiMainString")).or.isvar("CenterStrings") then
    defaulted@tiMainString=True
    mapres@tiMainString=(/"Ens. Mean Difference ("+expt_str_a+"-"+expt_str_b+")"/)
  end if
  if WinkTripSwitch.and.isatt(mapres,"lbLabelBarOn").and.\
     mapres@lbLabelBarOn.and.(.not.isatt(opt_res,"lbTitlePosition")) then
    lbres_names=(/"pmLabelBarHeightF","pmLabelBarWidthF","lbBoxLineColor","lbTitleFontHeightF","lbTitlePosition","pmLabelBarOrthogonalPosF"/)
    lbres_values=[/0.05,0.55,"gray70",0.01,"Bottom",-0.05/]
    do res_i=0,dimsizes(lbres_names)-1
      if .not.isatt(opt_res,lbres_names(res_i)) then
        mapres@$lbres_names(res_i)$=lbres_values[res_i]
      end if
    end do
  end if
  if MASK_TRIVIAL then
    mapres@cnMissingValFillColor="gainsboro"
  end if

  panres=True
  panres@gsnMaximize = True
  panres@gsnPaperOrientation = "portrait"
  panres@gsnPanelLabelBar = False
  panres@gsnPanelYWhiteSpacePercent = 3.0
  if opt_panel_res then
    copy_VarAtts(opt_panel_res,panres)
  end if    
  if WinkTripSwitch.and.panres@gsnPanelLabelBar.and..not.isatt(opt_panel_res,"lbTitlePosition") then
    lbres_names=(/"pmLabelBarHeightF","pmLabelBarWidthF","lbBoxLineColor","lbTitleFontHeightF","lbTitlePosition","pmLabelBarOrthogonalPosF"/)
    lbres_values=[/0.05,0.55,"gray70",0.01,"Bottom",-0.05/]
    do res_i=0,dimsizes(lbres_names)-1
      if .not.isatt(opt_panel_res,lbres_names(res_i)) then
        panres@$lbres_names(res_i)$=lbres_values[res_i]
      end if
    end do
  end if

  ;;determine names of files that have the correct field
  do var_i=0,nvars-1
    ;check to see if either str identifies a single simulation
    fnames_a=find_files_wVar(expt_str_a,variable_name(var_i))
    fnames_b=find_files_wVar(expt_str_b,variable_name(var_i))
    if dimsizes(fnames_a).eq.1.or.dimsizes(fnames_b).eq.1 then
      ;As single simultion found presume doing ens.mn(A)-ens.mn(B)
      if VERBOSE then
        print("plotDiffEnsMnMaps: Either "+expt_str_a+" or "+expt_str_b+" identifies a single simulation. Differencing the two ensemble means")
      end if
      dummy_for_latlon=read_latlon_var(fnames_a(0),variable_name(var_i),True)
      lat=dummy_for_latlon&lat
      lon=dummy_for_latlon&lon
      ensmn_diff=dummy_for_latlon
      if MASK_TRIVIAL then
        pi=4.*atan(1.0)
        rad=(pi/180.)
        coswgt=cos(rad*lat)
        coswgt!0 = "lat"
        coswgt&lat= lat
        gm_patt_a=new((/dimsizes(fnames_a)/),float)
        gm_patt_b=new((/dimsizes(fnames_b)/),float)
      end if
      patt_a=new((/dimsizes(fnames_a),dimsizes(lat),dimsizes(lon)/),float)
      patt_a!0="gcm"
      patt_a!1="lat"
      patt_a&lat=lat
      patt_a!2="lon" 
      patt_a&lon=lon
      do mod_i=0,dimsizes(fnames_a)-1
        if VERBOSE then
          print("Loading "+variable_name(var_i)+" from file "+mod_i+":"+fnames_a(mod_i))
        end if
        patt_a(mod_i,:,:)=read_latlon_var(fnames_a(mod_i),variable_name(var_i),True)
        if MASK_TRIVIAL then
          gm_patt_a(mod_i)= (/wgt_areaave_Wrap(patt_a(mod_i,:,:),coswgt,1.0,0)/)
        end if
      end do
      patt_b=new((/dimsizes(fnames_b),dimsizes(lat),dimsizes(lon)/),float)
      patt_b!0="gcm"
      patt_b!1="lat"
      patt_b&lat=lat
      patt_b!2="lon" 
      patt_b&lon=lon
      do mod_i=0,dimsizes(fnames_b)-1
        if VERBOSE then
          print("Loading "+variable_name(var_i)+" from file "+mod_i+":"+fnames_b(mod_i))
        end if
        patt_b(mod_i,:,:)=read_latlon_var(fnames_b(mod_i),variable_name(var_i),True)
        if MASK_TRIVIAL then
          gm_patt_b(mod_i)= (/wgt_areaave_Wrap(patt_b(mod_i,:,:),coswgt,1.0,0)/)
        end if
      end do
      avg_patt_a=dim_avg(patt_a(lat|:,lon|:,gcm|:))
      avg_patt_b=dim_avg(patt_b(lat|:,lon|:,gcm|:))
      if RATIO.or.PERCENTAGE then
        ;mask out zero values for the division
        avg_patt_b=where(avg_patt_b.ne.0,avg_patt_b,avg_patt_b@_FillValue)
        if RATIO then
          ensmn_diff=(/avg_patt_a/avg_patt_b/)
        else
          ensmn_diff=(/100*(avg_patt_a-avg_patt_b)/avg_patt_b/)
        end if
      else
        ensmn_diff=(/avg_patt_a-avg_patt_b/)
      end if
      if MASK_TRIVIAL then
        if VERBOSE then
          print("plotDiffEnsMnMaps: Masking out locations that are order of magnitude smaller than the global mean pattern for both "+expt_str_a+" and "+expt_str_b)
        end if
        thres_a=conform(avg_patt_a,0.1*avg(gm_patt_a),-1)
        thres_b=conform(avg_patt_b,0.1*avg(gm_patt_b),-1)
        ensmn_diff=where(avg_patt_a.lt.thres_a.and.avg_patt_b.lt.thres_b,ensmn_diff@_FillValue,ensmn_diff)
        delete([/thres_a,thres_b,gm_patt_a,gm_patt_b/])
      end if
      if CONSISTENCY then
        nsims=max((/dimsizes(fnames_a),dimsizes(fnames_b)/))
        if nsims.le.2 then
          print("plotDiffEnsMnMaps: You have set CONSISTENCY=True, but there are insufficient simulations for this to be meaningful")
          CONSISTENCY=False
        end if
        if dimsizes(fnames_a).eq.1 then
          diff=patt_b(lat|:,lon|:,gcm|:)
          if RATIO then
            diff=(/conform(patt_b(lat|:,lon|:,gcm|:),patt_a(lat|:,lon|:,gcm|0),(/0,1/))/patt_b(lat|:,lon|:,gcm|:)/)
          else
            diff=(/conform(patt_b(lat|:,lon|:,gcm|:),patt_a(lat|:,lon|:,gcm|0),(/0,1/))-patt_b(lat|:,lon|:,gcm|:)/)
          end if
        else
          diff=patt_a(lat|:,lon|:,gcm|:)
          if RATIO then
            diff=(/patt_a(lat|:,lon|:,gcm|:)/conform(patt_a(lat|:,lon|:,gcm|:),patt_b(lat|:,lon|:,gcm|0),(/0,1/))/)
          else
            diff=(/patt_a(lat|:,lon|:,gcm|:)-conform(patt_a(lat|:,lon|:,gcm|:),patt_b(lat|:,lon|:,gcm|0),(/0,1/))/)
          end if
        end if
      end if
      if OVERLAY_CONTROL then
        delete([/patt_a,patt_b,fnames_a,fnames_b,avg_patt_a/])
      else
        delete([/patt_a,patt_b,fnames_a,fnames_b,avg_patt_a,avg_patt_b/])
      end if
    else  
      if VERBOSE then
        print("plotDiffEnsMnMaps: Both "+expt_str_a+" and "+expt_str_b+" identifies multiple simulations. Creating ensemble mean of the model differences")
      end if
      fnames_both=find_pair_files_wVar(expt_str_a,expt_str_b,variable_name(var_i))
      if all(ismissing(fnames_both)) then
        exit
      end if
      dummy_for_latlon=read_latlon_var(fnames_both(0,0),variable_name(var_i),True)
      lat=dummy_for_latlon&lat
      lon=dummy_for_latlon&lon
      if MASK_TRIVIAL then
        pi=4.*atan(1.0)
        rad=(pi/180.)
        coswgt=cos(rad*lat)
        coswgt!0 = "lat"
        coswgt&lat= lat
        gm_patt=new((/dimsizes(fnames_both(:,0)),2/),float) 
      end if
      ;load and average historical
      patt=new((/dimsizes(fnames_both(:,0)),2,dimsizes(lat),dimsizes(lon)/),float)
      patt!0="gcm"
      patt!1="expt"
      patt!2="lat"
      patt&lat=lat
      patt!3="lon" 
      patt&lon=lon
      do mod_i=0,dimsizes(fnames_both(:,0))-1
        if VERBOSE then
          print("Loading "+variable_name(var_i)+" from file "+mod_i+":"+fnames_both(mod_i,:))
        end if
        if NORMALISE then
          if (name_to_normalise_by.eq."relative_to_plot_area_average") then
            this_patt=read_latlon_var(fnames_both(mod_i,0),variable_name(var_i),True)
            this_paa=extract_latlon_areastat(fnames_both(mod_i,0),variable_name(var_i),(/mapres@mpMinLatF,mapres@mpMaxLatF/),(/mapres@mpMinLonF,mapres@mpMaxLonF/),"mean")
            patt(mod_i,0,:,:)=(/this_patt-this_paa/)
            this_patt=read_latlon_var(fnames_both(mod_i,1),variable_name(var_i),True)
            this_paa=extract_latlon_areastat(fnames_both(mod_i,1),variable_name(var_i),(/mapres@mpMinLatF,mapres@mpMaxLatF/),(/mapres@mpMinLonF,mapres@mpMaxLonF/),"mean")
            patt(mod_i,1,:,:)=(/this_patt-this_paa/)
          else
            this_patt=read_latlon_var(fnames_both(mod_i,0),variable_name(var_i),True)
            patt(mod_i,0,:,:)=(/this_patt/this_patt@$name_to_normalise_by$/)
            this_patt=read_latlon_var(fnames_both(mod_i,1),variable_name(var_i),True)
            patt(mod_i,1,:,:)=(/this_patt/this_patt@$name_to_normalise_by$/)
          end if
          delete(this_patt)
        else
          patt(mod_i,0,:,:)=read_latlon_var(fnames_both(mod_i,0),variable_name(var_i),True)
          patt(mod_i,1,:,:)=read_latlon_var(fnames_both(mod_i,1),variable_name(var_i),True)
        end if
        if MASK_TRIVIAL then
          gm_patt(mod_i,0)= (/wgt_areaave_Wrap(patt(mod_i,0,:,:),coswgt,1.0,0)/)
          gm_patt(mod_i,1)= (/wgt_areaave_Wrap(patt(mod_i,1,:,:),coswgt,1.0,0)/)
        end if
      end do
      diff=patt(:,0,:,:)
      if RATIO.or.PERCENTAGE then
        ;mask out zero values for the division
        patt=where(patt.ne.0,patt,patt@_FillValue)
        if RATIO then
          diff=patt(:,0,:,:)/patt(:,1,:,:)
        else
          diff=100*(patt(:,0,:,:)-patt(:,1,:,:))/patt(:,1,:,:)
        end if
      else
        diff=patt(:,0,:,:)-patt(:,1,:,:)
      end if
      ensmn_diff=dummy_for_latlon
      ensmn_diff=(/dim_avg(diff(lat|:,lon|:,gcm|:))/)
      if OVERLAY_CONTROL then
        ;create the control average to be overlaid
        avg_patt_b=dim_avg_n_Wrap(patt(:,1,:,:),0)
      end if
      if MASK_TRIVIAL then
        if VERBOSE then
          print("plotDiffEnsMnMaps: Masking out locations that are order of magnitude smaller than the global mean pattern for both "+expt_str_a+" and "+expt_str_b)
        end if
        thres=conform(patt,0.1*gm_patt,(/0,1/))
        below_thres=patt ; to copy meta
        below_thres=where(patt.lt.thres,1,0)
        below_thres_expt0=dim_avg(below_thres(lat|:,lon|:,expt|0,gcm|:))
        below_thres_expt1=dim_avg(below_thres(lat|:,lon|:,expt|1,gcm|:))
        ;mask if more than 50% of model patterns are below threshold in both experiments
        ensmn_diff=where(below_thres_expt1.gt.0.5.and.below_thres_expt0.gt.0.5,ensmn_diff@_FillValue,ensmn_diff)
        delete([/thres,below_thres,gm_patt/])
      end if
      if CONSISTENCY then
        nsims=dimsizes(fnames_both(:,0))
        if nsims.le.2 then
          print("plotDiffEnsMnMaps: You have set CONSISTENCY=True, but there insufficient simulations for this to be meaningful")
          CONSISTENCY=False
        end if
      else
        delete(diff);otherwise it's needed below
      end if
      delete([/fnames_both,patt,fnames_a,fnames_b/])
    end if
    
    if .not.isatt(mapres,"cnLevelSelectionMode") then
      defaulted@cnLevelSelectionMode=True
      ;use modified version of symMinMaxPlt to spread 5-95% range
      stats=stat_dispersion(ensmn_diff,False)
      if RATIO then
        cmnmx=max((/fabs(stats(24)-1), fabs(stats(25)-1)/))
        mnmxint = nice_mnmxintvl(1-cmnmx,1+cmnmx,20,True)
      else
        cmnmx=max((/fabs(stats(24)), fabs(stats(25))/) )
        mnmxint = nice_mnmxintvl( -cmnmx, cmnmx,20,True)
      end if
      mapres@cnLevelSelectionMode = "ManualLevels"   
      mapres@cnMinLevelValF       = mnmxint(0)
      mapres@cnMaxLevelValF       = mnmxint(1)
      if (isnan_ieee(mnmxint(2))) then            ; extreme case
        mapres@cnLevelSpacingF  = 1.0
      else
        mapres@cnLevelSpacingF  = mnmxint(2)
      end if
    end if
    
    ;now create the ensemble mean plot
    if isvar("LeftStrings") then
      mapres@gsnLeftString = LeftStrings(var_i)
    end if
    if .not.isatt(defaulted,"gsnRightString").or.isvar("RightStrings") then
      defaulted@gsnRightString = True
      if isvar("RightStrings") then
        mapres@gsnRightString = RightStrings(var_i)
      end if
    end if
    if isvar("CenterStrings") then
      mapres@tiMainString = CenterStrings(var_i)
    end if
    ;make the variable name the LabelBar title if not set
    if .not.isatt(panres,"lbTitleString").and..not.isatt(defaulted,"gsnRightString") then
      defaulted@lbTitleString=True
      panres@lbTitleString=ensmn_diff@long_name
      mapres@lbTitleString=panres@lbTitleString
    end if

    if VERBOSE.and.var_i.eq.0 then
      print("plotDiffEnsMnMaps: the resources being used to plot the map and panel for the first variable are...")
      printVarSummary(mapres)
      printVarSummary(panres)
    end if

    if OVERLAY_CONTROL then
      res2 = True
      res2@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
      if isvar("overlay_levs") then
        res2@cnMinLevelValF   = overlay_levs(0)
        res2@cnMaxLevelValF   = overlay_levs(1)
        res2@cnLevelSpacingF  = overlay_levs(2)
      else
        stats=stat_dispersion(avg_patt_b,False)
        cmnmx=max((/fabs(stats(23)), fabs(stats(26))/) )
        mnmxint = nice_mnmxintvl( -cmnmx, cmnmx,9,True)
        res2@cnMinLevelValF       = mnmxint(0)
        res2@cnMaxLevelValF       = mnmxint(1)
        if (isnan_ieee(mnmxint(2))) then            ; extreme case
          res2@cnLevelSpacingF  = 1.0
        else
          res2@cnLevelSpacingF  = mnmxint(2)
        end if
      end if
      res2@cnLineLabelsOn       = True
      res2@cnLineLabelDensityF   = 1.5               ; increase the number of line labels/line
      res2@cnLineLabelInterval   = 1                 ; labels for every line (default=2)
      res2@cnLabelMasking        = True              ; do not draw labels over contour 
      res2@cnInfoLabelOn = False
      res2@cnLineLabelFormat = "@*+^sg"
      res2@gsnContourZeroLineThicknessF = 2. 	; doubles thickness of zero contour
      res2@gsnContourNegLineDashPattern = 1 	; sets negative contours to dash pattern 1
      res2@tiMainString=""
      plots(var_i)=gsn_csm_contour_map_overlay(wks,ensmn_diff,avg_patt_b,mapres,res2) 
    else
      plots(var_i)=gsn_csm_contour_map(wks,ensmn_diff,mapres) 
    end if
    
    if CONSISTENCY then
      if isatt(opt_res,"confidence_level") then
        confidence_level=tofloat(opt_res@confidence_level)
        if confidence_level.gt.1 then
          ;test for a confidence level as a %-age rather than ratio
          confidence_level=confidence_level/100.
        end if
      else
        ;default confidence level is 0.66 (i.e. IPCC's "likely")
        ;pick a number just below 2/3 to make sure that 2 of 3 sims gets colored.
        confidence_level=0.655
      end if
      conf_res@cnLevelSelectionMode = "ExplicitLevels"
      if isatt(conf_res,"cnLevels") then
        delete(conf_res@cnLevels)
      end if
      conf_res@gsnRightString=""
      conf_res@gsnLeftString=""
      conf_res@cnLevels=confidence_level
      conf_res@cnMonoFillPattern    = False        ; Use multiple fill patterns
      conf_res@cnFillPatterns    = (/17,0/) ;stippling for confidence
      conf_res@cnFillColors      = (/"Black","Transparent"/)
      conf_res@cnInfoLabelOn = False
      if RATIO then
        posi_diff=diff(lat|:,lon|:,gcm|:).gt.1
        posi_ensmn_diff=ensmn_diff.gt.1
      else
        posi_diff=diff(lat|:,lon|:,gcm|:).gt.0
        posi_ensmn_diff=ensmn_diff.gt.0
      end if
      conf=ensmn_diff ;number of models showing same sign as ensmn ...
      posi_match=dim_num(posi_diff.eq.conform(posi_diff,posi_ensmn_diff,(/0,1/)))
      conf=(/tofloat(posi_match)/tofloat(nsims)/)
      conf_plots(var_i)=gsn_csm_contour(wks,conf,conf_res)
      overlay(plots(var_i),conf_plots(var_i))
      delete([/posi_match,diff,posi_ensmn_diff,conf,posi_diff/])
    end if
    
    ; remove defaulted values for next varialble) 
    if isatt(defaulted,"cnLevelSelectionMode") then
      delete([/mapres@cnLevelSelectionMode,mapres@cnMinLevelValF,mapres@cnMaxLevelValF,mapres@cnLevelSpacingF/])
    end if
    if isatt(defaulted,"lbTitleString") then
      delete([/mapres@lbTitleString,panres@lbTitleString/])
    end if
    if isatt(defaulted,"tiMainString").and.isatt(mapres,"tiMainString") then
       delete([/mapres@tiMainString/])
    end if
  end do;finish looping over the variables

  ;now panel all the plots together...
  if isatt(opt_panel_res,"dims") then
    gsn_panel(wks,plots,opt_panel_res@dims,panres)
  else
    gsn_panel(wks,plots,(/nvars,1/),panres)
  end if
  if isstring (wks_name) then
    delete(wks)
  end if
end;plotDiffEnsMnMaps

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
undef("plotEnsTimeseries")
procedure plotEnsTimeseries(name_str:string,variable_name:string,ts_opt:logical,wks_name,opt_res:logical,opt_panel_res:logical)
local wks,xyres,panres,plots,ts_var,nvars,YAxisStrings,XAxisStrings,MainStrings
begin

  ;process some of the input variables
  nvars=dimsizes(variable_name)
  plots=new(nvars,graphic)
  if isstring(wks_name) then
    if isatt(wks_name,"filetype") then
      wks=gsn_open_wks(wks_name@filetype,wks_name)
    else
      wks=gsn_open_wks("pdf",wks_name)
    end if
  else
    wks=wks_name
  end if
  
  ;set some default map plotting resources
  xyres = True
  xyres@gsnDraw = False
  xyres@gsnFrame = False
  xyres@gsnYRefLine = 0.0
  xyres@gsnYRefLineColor = "gray42"
  xyres@xyLineThicknessF = 2.
  xyres@xyMonoDashPattern=True
  if (nvars.le.5) then
    xyres@tmXBLabelFontHeightF = 0.0125
    xyres@tmYLLabelFontHeightF = 0.0125
    xyres@tiYAxisFontHeightF = 0.017     
    xyres@tiXAxisFontHeightF = 0.013     
  else
    xyres@tmXBLabelFontHeightF = 0.018
    xyres@tmYLLabelFontHeightF = 0.018
    xyres@tiYAxisFontHeightF = 0.024
    xyres@tiXAxisFontHeightF = 0.020     
  end if
  xyres@vpXF = 0.05
  xyres@vpHeightF = 0.15
  xyres@vpWidthF = 0.9
  xyres@tiYAxisString = ""     
  xyres@tiMainString = ""
  xyres@tiXAxisString = ""
  
  if opt_res then
    if isatt(opt_res,"tiYAxisString").and.dimsizes(opt_res@tiYAxisString).eq.nvars then
      YAxisStrings=opt_res@tiYAxisString
      delete(opt_res@tiYAxisString)
    end if
    if isatt(opt_res,"tiXAxisString").and.dimsizes(opt_res@tiXAxisString).eq.nvars then
      XAxisStrings=opt_res@tiXAxisString
      delete(opt_res@tiXAxisString)
    end if
    if isatt(opt_res,"tiMainString") then
      if dimsizes(opt_res@tiMainString).eq.nvars then
        MainStrings=opt_res@tiMainString
        delete(opt_res@tiMainString)
      end if
    end if
    copy_VarAtts(opt_res,xyres)
  end if    
  
  panres=True
  panres@gsnMaximize = True
  panres@gsnPaperOrientation = "portrait"
  panres@gsnPanelLabelBar = False
  panres@gsnPanelYWhiteSpacePercent = 3.0
  if opt_panel_res then
    copy_VarAtts(opt_panel_res,panres)
  end if    
  if panres@gsnPanelLabelBar.and..not.isatt(opt_panel_res,"lbTitleFontHeightF") then
    panres@pmLabelBarHeightF = 0.05
    panres@pmLabelBarWidthF = 0.55
    panres@lbBoxLineColor = "gray70"
    panres@lbTitleFontHeightF = 0.014
    panres@lbTitlePosition = "Bottom"
    panres@pmLabelBarOrthogonalPosF=-0.05 
  end if

  ;;load in the actual timeseries
  do var_i=0,nvars-1
    ts=read_ts_all(name_str,variable_name(var_i),ts_opt)
    years=cd_calendar(ts&time,4)
    ;now create the xy plot
    if isvar("YAxisStrings") then
      xyres@tiYAxisString = YAxisStrings(var_i)
    end if
    if isvar("XAxisStrings") then
      xyres@tiXAxisString = XAxisStrings(var_i)
    end if
    if isvar("MainStrings") then
      xyres@tiMainString = MainStrings(var_i)
    end if
    plots(var_i)=gsn_csm_xy(wks,years,ts,xyres) 
    delete([/ts/])
  end do;finish looping over the variables

  ;now panel all the plots together...
  gsn_panel(wks,plots,(/nvars,1/),panres)
  if isstring(wks_name) then
    delete(wks)
  end if
end;plotEnsTimeseries

undef("createTableGCMsExptsYears")
procedure createTableGCMsExptsYears(expt_names:string,variable_name:string,gcm_names_dict,output_format:string,output_filename:string)
local filenames
begin

  if .not.(typeof(gcm_names_dict).eq."string") then
    GCM_DECODE_COLUMN=False
  else
    GCM_DECODE_COLUMN=True    
  end if
  
  gcm_names=new((/dimsizes(expt_names),100/),string) 
  yrs=new((/dimsizes(expt_names),100/),integer) 
  do i=0,dimsizes(expt_names)-1
    these_filenames=find_files_wVar(expt_names(i),variable_name)
    if dimsizes(these_filenames).gt.100 then
      print("createTableGCMsExptsYears:There are so many filenames that you'll need to extend my array")
      exit
    end if
    do j=0,dimsizes(these_filenames)-1
      a_nopath=str_get_field(these_filenames(j),str_fields_count(these_filenames(j),"/"),"/")
      gcm=str_get_field(str_sub_str(a_nopath,"_"+expt_names(i),":"),1,":")
      post_data=str_get_field(str_sub_str(a_nopath,"_enso.",":"),2,":")
      file_years=str_get_field(post_data,1,".")
      file_syear = stringtointeger(str_get_field(file_years,1,"-"))
      file_eyear = stringtointeger(str_get_field(file_years,2,"-"))
      nyrs=file_eyear-file_syear+1
      gcm_names(i,j)=gcm
      yrs(i,j)=nyrs
      delete([/a_nopath,gcm,post_data,file_years,file_syear,file_eyear/])
    end do
    delete(these_filenames)
  end do  

  unique_gcm_names=get_unique_values(gcm_names)
  if GCM_DECODE_COLUMN then
    if dimsizes(unique_gcm_names).ne.dimsizes(gcm_names_dict) then
      print("createTableGCMsExptsYears: The size of your dictionary doesn't fit the amount of unique gcm names")
      exit
    end if
    j_offset=2
  else
    j_offset=1
  end if
  table=new((/dimsizes(unique_gcm_names),dimsizes(expt_names)+j_offset/),string)
  table@_FillValue="-"
  table=table@_FillValue
  if GCM_DECODE_COLUMN then
    table(:,0)=gcm_names_dict
    table(:,1)=unique_gcm_names
  else    
    table(:,0)=unique_gcm_names
  end if
  do i=0,dimsizes(unique_gcm_names)-1
    do j=0,dimsizes(expt_names)-1
      inds=ind(gcm_names(j,:).eq.unique_gcm_names(i))
      if dimsizes(inds).ne.1 then
        print("createTableGCMsExptsYears: Duplicate file names exist in the data directory (prob. with differnet years)")
        exit
      else
        if .not.ismissing(inds) then
          if .not.(inds.le.-999) then
            table(i,j+j_offset)=tostring(yrs(j,ind(gcm_names(j,:).eq.unique_gcm_names(i))))
          end if
        end if
      end if
      delete(inds)
    end do
  end do

  if output_format.eq."csv" then
    header=(/"The number of years of data for "+variable_name+" in the CVDP archive",\
             " ",\
             "Model, "+str_join(expt_names,", ")/) 
    write_table(output_filename, "w", [/header/], "%s")
    do i=0,dimsizes(unique_gcm_names)-1
      write_table(output_filename, "a", [/str_join(table(i,:),", ")/], "%s")
    end do
  end if

  if output_format.eq."tex" then
    header=(/"\begin{table}{t}","\begin{tabular}{ c | "+str_join(conform(expt_names," c ",-1),"|")+" } ",\
             "\hline","Model&"+str_join(expt_names,"&")+"\\ \hline"/) 
    write_table(output_filename, "w", [/header/], "%s")
    do i=0,dimsizes(unique_gcm_names)-1
      write_table(output_filename, "a", [/str_sub_str(str_join(table(i,:),"&"),"_"," ")+"\\"/], "%s")
    end do 
    footer=(/"\hline","\end{tabular}",\
             "\caption{The number of years of data for "+str_sub_str(variable_name,"_"," ")+" in the CVDP archive}",\
             "\label{tab:model}",\
             "\end{table}"/)
    write_table(output_filename, "a", [/footer/], "%s")
  end if
  
end;createTableGCMsExptsYears

undef("createGCMsNameDictionary")
function createGCMsNameDictionary(expt_names:string,variable_name:string)
local filenames,a_nopath,gcm,alphabet
begin

  gcm_names=new((/dimsizes(expt_names),100/),string) 
  do i=0,dimsizes(expt_names)-1
    these_filenames=find_files_wVar(expt_names(i),variable_name)
    if dimsizes(these_filenames).gt.100 then
      print("createGCMsNameDictionary:There are so many filenames that you'll need to extend my array")
      exit
    end if
    do j=0,dimsizes(these_filenames)-1
      a_nopath=str_get_field(these_filenames(j),str_fields_count(these_filenames(j),"/"),"/")
      gcm=str_get_field(str_sub_str(a_nopath,"_"+expt_names(i),":"),1,":")
      gcm_names(i,j)=gcm
      delete([/a_nopath,gcm/])
    end do
    delete(these_filenames)
  end do  

  alphabet=(/"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","AA","AB","AC","AD","AE","AF","AG","AH","AI","AJ","AK","AL","AM","AN","AO","AP","AQ","AR","AS","AT","AU","AV","AW","AX","AY","AZ","BA","BB","BC","BD","BE","BF","BG","BH","BI","BJ","BK","BL","BM","BN","BO","BP","BQ","BR","BS","BT","BU","BV","BW","BX","BY","BZ","CA","CB","CC","CD","CE","CF","CG","CH","CI","CJ","CK","CL","CM","CN","CO","CP","CQ","CR","CS","CT","CU","CV"/)

  unique_gcm_names=get_unique_values(gcm_names)
  gcm_names_dict=alphabet(0:dimsizes(unique_gcm_names)-1)
  gcm_names_dict@translation=unique_gcm_names

  return(gcm_names_dict)
end;createGCMsNameDictionary

undef("translateGCMsNameDictionary")
function translateGCMsNameDictionary(gcm_names,gcm_names_dict,STRIP_ENS_MEM)
local translation,this_gcm_ind,this_gcm_name
;At times there can be more one ensemble member - designated with a _0 or _1
; STRIP_ENS_MEM=True removes this trailling digit and just translates the main string
begin

  gcm_letters=gcm_names;set up a holding arrary
  translation=gcm_names_dict@translation
  if STRIP_ENS_MEM then
    do i=0,dimsizes(gcm_names)-1
      if isStrSubset(gcm_names(i),"_") then
        gcm_letters(i)=str_get_field(gcm_names(i),str_fields_count(gcm_names(i),"_")-1,"_")
      end if
    end do
    do i=0,dimsizes(translation)-1
      if isStrSubset(translation(i),"_") then
        translation(i)=str_get_field(translation(i),str_fields_count(translation(i),"_")-1,"_")
      end if
    end do
  end if
  do i=0,dimsizes(gcm_names)-1
    this_gcm_ind=ind(gcm_letters(i).eq.translation)
    if all(ismissing(this_gcm_ind)).or.(dimsizes(this_gcm_ind).ne.1) then
      print("translateGCMsNameDictionary: There is an error in the dictionary with translating "+gcm_names(i))
      exit
    else
      gcm_letters(i)=gcm_names_dict(this_gcm_ind)
    end if
    delete(this_gcm_ind)
  end do
  return(gcm_letters)
end;translateGCMsNameDictionary

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Plot obs vs ensemble mean maps ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
undef("plot_output_CVDPmap")
procedure plot_output_CVDPmap(expt_str:string,variable_name:string,output_string:string,opt_res:logical)
local mapres,plots,ensmn,patt,LeftStrings,RightStrings,CenterStrings,fnames,lat,lon,dims,opt_res
begin

  ;Creating a new wks called output_string
  if isatt(output_string,"filetype") then
    wks=gsn_open_wks(output_string@filetype,output_string)
  else
    wks=gsn_open_wks("pdf",output_string)
  end if

  mapres = True
  mapres@cnLineLabelsOn = False
  mapres@cnFillOn        = True
  mapres@cnLinesOn       = False
  mapres@cnFillPalette = "BlueDarkRed18"
  ;copy across the optional resources
  copy_VarAtts(opt_res,mapres)

  ;using mpProjection as a major switch
  if isatt(mapres,"mpProjection").and.mapres@mpProjection.eq."WinkelTripel" then
    mapres@vpYF = 0.95
    mapres@vpHeightF = 0.3
    mapres@vpXF = 0.2
    mapres@vpWidthF = 0.6
    mapres@gsnLeftStringOrthogonalPosF = -0.05
    mapres@gsnLeftStringParallelPosF = .005
    mapres@gsnRightStringOrthogonalPosF = -0.05
    mapres@gsnRightStringParallelPosF = 0.96
    mapres@gsnLeftStringFontHeightF = 0.02
    mapres@gsnRightStringFontHeightF = 0.02
    mapres@mpGeophysicalLineColor = "gray42"
    mapres@mpPerimOn    = False
    mapres@mpGridLatSpacingF =  15.            ; change latitude  line spacing
    mapres@mpGridLonSpacingF = 15.           ; change longitude line spacing
    mapres@mpGridLineColor   = "transparent"  ; trick ncl into drawing perimeter
    mapres@mpGridAndLimbOn   = True           ; turn on lat/lon lines  
  end if
  
  ;;determine names of files that have the correct field
  fnames=find_files_wVar(expt_str,variable_name)
  dummy=read_latlon_var(fnames(0),variable_name,True)
  lat=dummy&lat
  lon=dummy&lon
  ensmn=dummy
  ;load and average historical
  patt=new((/dimsizes(fnames),dimsizes(lat),dimsizes(lon)/),float)
  patt!0="run"
  patt!1="lat"
  patt&lat=lat
  patt!2="lon" 
  patt&lon=lon
  do mod_i=0,dimsizes(fnames)-1
    if isatt(opt_res,"VERBOSE").and.(opt_res@VERBOSE) then
      print("Loading "+variable_name(var)+" from file "+mod_i+":"+fnames(mod_i))
    end if
    patt(mod_i,:,:)=read_latlon_var(fnames(mod_i),variable_name,True)
  end do
  ensmn=(/dim_avg(patt(lat|:,lon|:,run|:))/)

  system("/bin/rm -f "+output_string+".nc")   ; remove any pre-existing file
  ncdf = addfile(output_string+".nc" ,"c")  ; open output netCDF file
  fAtt               = True            ; assign file attributes
  fAtt@title         = "Ensemble mean of "+expt_str
  fAtt@source_files   =  fnames
  fAtt@creation_date = systemfunc ("date")
  fileattdef( ncdf, fAtt )            ; copy file attributes
  ncdf->$variable_name$ = ensmn                          ; 4D               

  plot=gsn_csm_contour_map(wks,ensmn,mapres) 
  delete([/wks,patt,ensmn,dummy/])
end;plot_output_CVDPmap

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Plot obs vs ensemble mean maps ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
undef("plot_output_DiffEnsMn")
procedure plot_output_DiffEnsMn(expt_str_a:string,expt_str_b:string,variable_name:string,output_string:string,opt_res:logical)
local wks,mapres,panres,plots,ensmn,patt,nvars,LeftStrings,RightStrings,CenterStrings,fnames_both,lat,lon,dummy_for_latlon,opt_resconf_res
begin

  ;Creating a new wks called output_string
  if isatt(output_string,"filetype") then
    wks=gsn_open_wks(output_string@filetype,output_string)
  else
    wks=gsn_open_wks("pdf",output_string)
  end if

  ;Look for some major opt_res switches/attributes
  if isatt(output_string,"VERBOSE").and.(output_string@VERBOSE) then
    ;Provides a modicum of more information
    VERBOSE=output_string@VERBOSE
  else
    VERBOSE=False
  end if
  if opt_res.and.isatt(opt_res,"CONSISTENCY") then
    ;this option stipples locations where >2/3 of the model have the same sign 
    CONSISTENCY=opt_res@CONSISTENCY
    delete(opt_res@CONSISTENCY)
  else
    CONSISTENCY=False
  end if
  if opt_res.and.isatt(opt_res,"OVERLAY_CONTROL") then
    ;this option will add some contour lines of the Ensemble Mean of B.
    OVERLAY_CONTROL=opt_res@OVERLAY_CONTROL
    delete(opt_res@OVERLAY_CONTROL)
    if isatt(opt_res,"OVERLAY_CONTROL_MANUALLEVS") then
      overlay_levs=opt_res@OVERLAY_CONTROL_MANUALLEVS
      delete(opt_res@OVERLAY_CONTROL_MANUALLEVS)
    end if
  else
    OVERLAY_CONTROL=False
  end if
  if opt_res.and.(isatt(opt_res,"MASK_TRIVIAL").or.isatt(opt_res,"TRIVIAL")) then
    ;this option will mask out any instances where the magnitude of both patterns is less than 10% of the global mean
    if isatt(opt_res,"MASK_TRIVIAL") then
      MASK_TRIVIAL=opt_res@MASK_TRIVIAL
      delete(opt_res@MASK_TRIVIAL)
    else
      MASK_TRIVIAL=opt_res@TRIVIAL
      delete(opt_res@TRIVIAL)
    end if
  else
    MASK_TRIVIAL=False
  end if
  if opt_res.and.isatt(opt_res,"RATIO") then
    ;this option will plot the ratio of the fields 
    RATIO=opt_res@RATIO
    delete(opt_res@RATIO)
  else
    RATIO=False
  end if
  if opt_res.and.isatt(opt_res,"PERCENTAGE") then
    ;this option will plot the ratio of the fields 
    PERCENTAGE=opt_res@PERCENTAGE
    delete(opt_res@PERCENTAGE)
  else
    PERCENTAGE=False
  end if
  if RATIO.and.PERCENTAGE then
    print("plotDiffEnsMnMaps: Both RATIO and PERCENTAGE have been selected. This is not valid.")
    print("plotDiffEnsMnMaps: RATIO is a/b and PERCENTAGE is 100*(a-b)/a - please go back and select the correct option")
    exit
  end if
  
  ;set some default map plotting resources
  mapres = True
  mapres@cnLineLabelsOn = False
  mapres@cnFillOn        = True
  mapres@cnLinesOn       = False
  if CONSISTENCY then
    conf_res=mapres
    conf_plots=plots
    conf_res@lbLabelBarOn=False
  end if
  mapres@mpFillOn = False
  mapres@mpCenterLonF = -20.
  mapres@mpOutlineOn = True  
  mapres@cnFillPalette = "BlueWhiteOrangeRed"
  copy_VarAtts(opt_res,mapres)

  ;use mpProjection as a supra-option
  if isatt(mapres,"mpProjection").and.mapres@mpProjection.eq."WinkelTripel" then
    WinkTripSwitch=True
  else
    WinkTripSwitch=False
  end if
    
  if WinkTripSwitch then
    mapres@gsnLeftStringOrthogonalPosF = -0.05
    mapres@gsnLeftStringParallelPosF = .005
    mapres@gsnRightStringOrthogonalPosF = -0.05
    mapres@gsnRightStringParallelPosF = 0.96
    mapres@gsnLeftStringFontHeightF = 0.014
    mapres@gsnRightStringFontHeightF = 0.014
    mapres@vpYF = 0.95
    mapres@vpHeightF = 0.3
    mapres@vpXF = 0.2
    mapres@vpWidthF = 0.6
    mapres@mpGeophysicalLineColor = "gray42"
    mapres@mpPerimOn    = False
    mapres@mpGridLatSpacingF =  15.            ; change latitude  line spacing
    mapres@mpGridLonSpacingF = 15.           ; change longitude line spacing
    mapres@mpGridLineColor   = "transparent"  ; trick ncl into drawing perimeter
    mapres@mpGridAndLimbOn   = True           ; turn on lat/lon lines  
  end if

  ;load in the optional ones
  if MASK_TRIVIAL then
    mapres@cnMissingValFillColor="gainsboro"
  end if

  system("/bin/rm -f "+output_string+".nc")   ; remove any pre-existing file
  ncdf = addfile(output_string+".nc" ,"c")  ; open output netCDF file
  fAtt               = True            ; assign file attributes
  fAtt@title         = "Ensemble means for "+expt_str_a+" - "+expt_str_b
  fAtt@creation_date = systemfunc ("date")

  ;check to see if either str identifies a single simulation
  fnames_a=find_files_wVar(expt_str_a,variable_name)
  fnames_b=find_files_wVar(expt_str_b,variable_name)
  if dimsizes(fnames_a).eq.1.or.dimsizes(fnames_b).eq.1 then
    str=expt_str_a+"_source_files"
    fAtt@$str$   =  str_join(fnames_a,",")
    str=expt_str_b+"_source_files"
    fAtt@$str$   =  str_join(fnames_b,",")
    fileattdef( ncdf, fAtt )            ; copy file attributes
   ;As single simultion found presume doing ens.mn(A)-ens.mn(B)
    if VERBOSE then
      print("plotDiffEnsMnMaps: Either "+expt_str_a+" or "+expt_str_b+" identifies a single simulation. Differencing the two ensemble means")
    end if
    dummy_for_latlon=read_latlon_var(fnames_a(0),variable_name,True)
    lat=dummy_for_latlon&lat
    lon=dummy_for_latlon&lon
    ensmn_diff=dummy_for_latlon
    if MASK_TRIVIAL then
      pi=4.*atan(1.0)
      rad=(pi/180.)
      coswgt=cos(rad*lat)
      coswgt!0 = "lat"
      coswgt&lat= lat
      gm_patt_a=new((/dimsizes(fnames_a)/),float)
      gm_patt_b=new((/dimsizes(fnames_b)/),float)
    end if
    patt_a=new((/dimsizes(fnames_a),dimsizes(lat),dimsizes(lon)/),float)
    patt_a!0="gcm"
    patt_a!1="lat"
    patt_a&lat=lat
    patt_a!2="lon" 
    patt_a&lon=lon
    do mod_i=0,dimsizes(fnames_a)-1
      if VERBOSE then
        print("Loading "+variable_name+" from file "+mod_i+":"+fnames_a(mod_i))
      end if
      patt_a(mod_i,:,:)=read_latlon_var(fnames_a(mod_i),variable_name,True)
      if MASK_TRIVIAL then
        gm_patt_a(mod_i)= (/wgt_areaave_Wrap(patt_a(mod_i,:,:),coswgt,1.0,0)/)
      end if
    end do
    patt_b=new((/dimsizes(fnames_b),dimsizes(lat),dimsizes(lon)/),float)
    patt_b!0="gcm"
    patt_b!1="lat"
    patt_b&lat=lat
    patt_b!2="lon" 
    patt_b&lon=lon
    do mod_i=0,dimsizes(fnames_b)-1
      if VERBOSE then
        print("Loading "+variable_name+" from file "+mod_i+":"+fnames_b(mod_i))
      end if
      patt_b(mod_i,:,:)=read_latlon_var(fnames_b(mod_i),variable_name,True)
      if MASK_TRIVIAL then
        gm_patt_b(mod_i)= (/wgt_areaave_Wrap(patt_b(mod_i,:,:),coswgt,1.0,0)/)
      end if
    end do
    avg_patt_a=dim_avg(patt_a(lat|:,lon|:,gcm|:))
    avg_patt_b=dim_avg(patt_b(lat|:,lon|:,gcm|:))
    if RATIO.or.PERCENTAGE then
      ;mask out zero values for the division
      avg_patt_b=where(avg_patt_b.ne.0,avg_patt_b,avg_patt_b@_FillValue)
      if RATIO then 
        ensmn_diff@long_name="Ensemble mean ratio of "+variable_name+" of "+expt_str_a+" over "+expt_str_b
        ensmn_diff=(/avg_patt_a/avg_patt_b/)
      else
        ensmn_diff@long_name="Ensemble mean percentage change of "+variable_name+" in "+expt_str_a+" from "+expt_str_b
        ensmn_diff=(/100*(avg_patt_a-avg_patt_b)/avg_patt_b/)
      end if
    else
      ensmn_diff@long_name="Ensemble mean anomaly in "+variable_name+" between "+expt_str_a+" and "+expt_str_b
      ensmn_diff=(/avg_patt_a-avg_patt_b/)
    end if
    if MASK_TRIVIAL then
      if VERBOSE then
        print("plotDiffEnsMnMaps: Masking out locations that are order of magnitude smaller than the global mean pattern for both "+expt_str_a+" and "+expt_str_b)
      end if
      thres_a=conform(avg_patt_a,0.1*avg(gm_patt_a),-1)
      thres_b=conform(avg_patt_b,0.1*avg(gm_patt_b),-1)
      ensmn_diff=where(avg_patt_a.lt.thres_a.and.avg_patt_b.lt.thres_b,ensmn_diff@_FillValue,ensmn_diff)
      delete([/thres_a,thres_b,gm_patt_a,gm_patt_b/])
    end if
    ncdf->difference = ensmn_diff               
    
    if CONSISTENCY then
      nsims=max((/dimsizes(fnames_a),dimsizes(fnames_b)/))
      if nsims.le.2 then
        print("plotDiffEnsMnMaps: You have set CONSISTENCY=True, but there are insufficient simulations for this to be meaningful")
        CONSISTENCY=False
      end if
      if dimsizes(fnames_a).eq.1 then
        diff=patt_b(lat|:,lon|:,gcm|:)
        if RATIO then
          diff=(/conform(patt_b(lat|:,lon|:,gcm|:),patt_a(lat|:,lon|:,gcm|0),(/0,1/))/patt_b(lat|:,lon|:,gcm|:)/)
        else
          diff=(/conform(patt_b(lat|:,lon|:,gcm|:),patt_a(lat|:,lon|:,gcm|0),(/0,1/))-patt_b(lat|:,lon|:,gcm|:)/)
        end if
      else
        diff=patt_a(lat|:,lon|:,gcm|:)
        if RATIO then
          diff=(/patt_a(lat|:,lon|:,gcm|:)/conform(patt_a(lat|:,lon|:,gcm|:),patt_b(lat|:,lon|:,gcm|0),(/0,1/))/)
        else
          diff=(/patt_a(lat|:,lon|:,gcm|:)-conform(patt_a(lat|:,lon|:,gcm|:),patt_b(lat|:,lon|:,gcm|0),(/0,1/))/)
        end if
      end if
    end if
    if OVERLAY_CONTROL then
      delete([/patt_a,patt_b,fnames_a,fnames_b,avg_patt_a/])
    else
      delete([/patt_a,patt_b,fnames_a,fnames_b,avg_patt_a,avg_patt_b/])
    end if
  else  
    if VERBOSE then
      print("plotDiffEnsMnMaps: Both "+expt_str_a+" and "+expt_str_b+" identifies multiple simulations. Creating ensemble mean of the model differences")
    end if
    fnames_both=find_pair_files_wVar(expt_str_a,expt_str_b,variable_name)
    if all(ismissing(fnames_both)) then
      exit
    end if
    str=expt_str_a+"_source_files"
    fAtt@$str$   =  str_join(fnames_both(:,0),",")
    str=expt_str_b+"_source_files"
    fAtt@$str$   =  str_join(fnames_both(:,1),",")
    fileattdef( ncdf, fAtt )            ; copy file attributes
    dummy_for_latlon=read_latlon_var(fnames_both(0,0),variable_name,True)
    lat=dummy_for_latlon&lat
    lon=dummy_for_latlon&lon
    if MASK_TRIVIAL then
      pi=4.*atan(1.0)
      rad=(pi/180.)
      coswgt=cos(rad*lat)
      coswgt!0 = "lat"
      coswgt&lat= lat
      gm_patt=new((/dimsizes(fnames_both(:,0)),2/),float) 
    end if
    ;load and average historical
    patt=new((/dimsizes(fnames_both(:,0)),2,dimsizes(lat),dimsizes(lon)/),float)
    patt!0="gcm"
    patt!1="expt"
    patt!2="lat"
    patt&lat=lat
    patt!3="lon" 
    patt&lon=lon
    do mod_i=0,dimsizes(fnames_both(:,0))-1
      if VERBOSE then
        print("Loading "+variable_name+" from file "+mod_i+":"+fnames_both(mod_i,:))
      end if
      patt(mod_i,0,:,:)=read_latlon_var(fnames_both(mod_i,0),variable_name,True)
      patt(mod_i,1,:,:)=read_latlon_var(fnames_both(mod_i,1),variable_name,True)
      if MASK_TRIVIAL then
        gm_patt(mod_i,0)= (/wgt_areaave_Wrap(patt(mod_i,0,:,:),coswgt,1.0,0)/)
        gm_patt(mod_i,1)= (/wgt_areaave_Wrap(patt(mod_i,1,:,:),coswgt,1.0,0)/)
      end if
    end do
    diff=patt(:,0,:,:)
    if RATIO.or.PERCENTAGE then
      ;mask out zero values for the division
      patt=where(patt.ne.0,patt,patt@_FillValue)
      if RATIO then
        long_name="Ensemble mean ratio of "+variable_name+" of "+expt_str_a+" over "+expt_str_b
        diff=patt(:,0,:,:)/patt(:,1,:,:)
      else
        long_name="Ensemble mean percentage change of "+variable_name+" in "+expt_str_a+" from "+expt_str_b
        diff=100*(patt(:,0,:,:)-patt(:,1,:,:))/patt(:,1,:,:)
      end if
    else
      long_name="Ensemble mean anomaly in "+variable_name+" between "+expt_str_a+" and "+expt_str_b
      diff=patt(:,0,:,:)-patt(:,1,:,:)
    end if
    ensmn_diff=dummy_for_latlon
    ensmn_diff@long_name=long_name
    ensmn_diff=(/dim_avg(diff(lat|:,lon|:,gcm|:))/)
    if OVERLAY_CONTROL then
      ;create the control average to be overlaid
      avg_patt_b=dim_avg_n_Wrap(patt(:,1,:,:),0)
    end if
    if MASK_TRIVIAL then
      if VERBOSE then
        print("plotDiffEnsMnMaps: Masking out locations that are order of magnitude smaller than the global mean pattern for both "+expt_str_a+" and "+expt_str_b)
      end if
      thres=conform(patt,0.1*gm_patt,(/0,1/))
      below_thres=patt ; to copy meta
      below_thres=where(patt.lt.thres,1,0)
      below_thres_expt0=dim_avg(below_thres(lat|:,lon|:,expt|0,gcm|:))
      below_thres_expt1=dim_avg(below_thres(lat|:,lon|:,expt|1,gcm|:))
      ;mask if more than 50% of model patterns are below threshold in both experiments
      ensmn_diff=where(below_thres_expt1.gt.0.5.and.below_thres_expt0.gt.0.5,ensmn_diff@_FillValue,ensmn_diff)
      ensmn_diff@notes="Anywhere that more than 50% of model patterns are less than 1/10th of the global mean pattern in both experiments has been masked out" 
      delete([/thres,below_thres,gm_patt/])
    end if
    ncdf->difference = ensmn_diff               
    if CONSISTENCY then
      nsims=dimsizes(fnames_both(:,0))
      if nsims.le.2 then
        print("plotDiffEnsMnMaps: You have set CONSISTENCY=True, but there insufficient simulations for this to be meaningful")
        CONSISTENCY=False
      end if
    else
      delete(diff);otherwise it's needed below
    end if
    delete([/fnames_both,patt,fnames_a,fnames_b/])
  end if
    
  ;use modified version of symMinMaxPlt to spread 5-95% range
  stats=stat_dispersion(ensmn_diff,False)
  if RATIO then
    cmnmx=max((/fabs(stats(24)-1), fabs(stats(25)-1)/))
    mnmxint = nice_mnmxintvl(1-cmnmx,1+cmnmx,20,True)
  else
    cmnmx=max((/fabs(stats(24)), fabs(stats(25))/) )
    mnmxint = nice_mnmxintvl( -cmnmx, cmnmx,20,True)
  end if
  mapres@cnLevelSelectionMode = "ManualLevels"   
  mapres@cnMinLevelValF       = mnmxint(0)
  mapres@cnMaxLevelValF       = mnmxint(1)
  if (isnan_ieee(mnmxint(2))) then            ; extreme case
    mapres@cnLevelSpacingF  = 1.0
  else
    mapres@cnLevelSpacingF  = mnmxint(2)
  end if
   
  if OVERLAY_CONTROL then
    res2 = True
    res2@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
    stats=stat_dispersion(avg_patt_b,False)
    cmnmx=max((/fabs(stats(23)), fabs(stats(26))/) )
    mnmxint = nice_mnmxintvl( -cmnmx, cmnmx,9,True)
    res2@cnMinLevelValF       = mnmxint(0)
    res2@cnMaxLevelValF       = mnmxint(1)
    if (isnan_ieee(mnmxint(2))) then            ; extreme case
      res2@cnLevelSpacingF  = 1.0
    else
      res2@cnLevelSpacingF  = mnmxint(2)
    end if
    res2@cnLineLabelsOn       = True
    res2@cnLineLabelDensityF   = 1.5               ; increase the number of line labels/line
    res2@cnLineLabelInterval   = 1                 ; labels for every line (default=2)
    res2@cnLabelMasking        = True              ; do not draw labels over contour 
    res2@cnInfoLabelOn = False
    res2@cnLineLabelFormat = "@*+^sg"
    res2@gsnContourZeroLineThicknessF = 2. 	; doubles thickness of zero contour
    res2@gsnContourNegLineDashPattern = 1 	; sets negative contours to dash pattern 1
    res2@tiMainString=""
    plots=gsn_csm_contour_map_overlay(wks,ensmn_diff,avg_patt_b,mapres,res2) 
  else
    plot=gsn_csm_contour_map(wks,ensmn_diff,mapres) 
  end if
    
  if CONSISTENCY then
    if isatt(opt_res,"confidence_level") then
      confidence_level=tofloat(opt_res@confidence_level)
      if confidence_level.gt.1 then
        ;test for a confidence level as a %-age rather than ratio
        confidence_level=confidence_level/100.
      end if
    else
      ;default confidence level is 0.66 (i.e. IPCC's "likely")
      ;pick a number just below 2/3 to make sure that 2 of 3 sims gets colored.
      confidence_level=0.655
    end if
    conf_res@cnLevelSelectionMode = "ExplicitLevels"
    conf_res@gsnRightString=""
    conf_res@gsnLeftString=""
    conf_res@cnLevels=confidence_level
    conf_res@cnMonoFillPattern    = False        ; Use multiple fill patterns
    conf_res@cnFillPatterns    = (/17,0/) ;stippling for confidence
    conf_res@cnFillColors      = (/"Black","Transparent"/)
    conf_res@cnInfoLabelOn = False
    if RATIO then
      posi_diff=diff(lat|:,lon|:,gcm|:).gt.1
      posi_ensmn_diff=ensmn_diff.gt.1
    else
      posi_diff=diff(lat|:,lon|:,gcm|:).gt.0
      posi_ensmn_diff=ensmn_diff.gt.0
    end if
    conf=ensmn_diff ;number of models showing same sign as ensmn ...
    posi_match=dim_num(posi_diff.eq.conform(posi_diff,posi_ensmn_diff,(/0,1/)))
    conf=(/tofloat(posi_match)/tofloat(nsims)/)
    conf@long_name="Ratio of ensemble members shown the same sign"
    ncdf->consistency = conf               
    conf_plots=gsn_csm_contour(wks,conf,conf_res)
    overlay(plots,conf_plots)
    delete([/posi_match,diff,posi_ensmn_diff,conf,posi_diff/])
  end if
  delete(wks)
end;plot_output_DiffEnsMn
