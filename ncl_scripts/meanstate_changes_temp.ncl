;This script was used to block out some figures to populate a research publication on ENSO
;It makes full use of the programs in cvdp_data.functions.ncl to plot figures solely from the output data of cvdp (without needing recomputation).
; It makes 1 table (showing simulations used) and many figures. 

;load some functions
present_dir=systemfunc("pwd")
if ismissing(str_match_ind(present_dir,"scripts")) then
  loadscript("./scripts/cvdp_enso.functions.ncl")
  plots_dir=present_dir+"/plots/"
else
  loadscript("./cvdp_enso.functions.ncl")
  plots_dir=present_dir+"/../plots/"
end if


;some plot switches
VERBOSE=False ;if True, provides a modicum of more information about whats going on in the plots - used for debugging mainly.
OUTPUT_TYPE="pdf"; either "png" or "pdf"
INC_PREIND_wHIST=True; adds the preindustrial to all the plots including the Historical 
troppac_region=(/(/-25.,25./),(/100.,280./)/);lat and lons of the edge of the plots (/(/latS,latN/),(/lonW,lonE/)/)
expts=(/"piControl","historical","midHolocene-cal-adj","lgm-cal-adj","lig127k-cal-adj","1pctCO2","abrupt4xCO2"/)
expts_color=(/"grey60","black","darkgreen","dodgerblue4","yellowgreen","firebrick","orangered2"/)
plot_letters=(/(/"a","b"/),(/"c","d"/),(/"e","f"/),(/"g","h"/),(/"i","j"/),(/"k","l"/)/)
CONSISTENCY=True
OVERLAY_PREIND=True
OVERLAY_PREIND_MANUALLEV=(/0,40,2/);ie 0:12:2 mm/day
TS_NOT_TAS=True ;if True use SST rather TAS in the mean state figure

if TS_NOT_TAS then
  djf_field="sst_spatialmean_djf"
  jja_field="sst_spatialmean_jja"
else
  djf_field="tas_spatialmean_djf"
  jja_field="tas_spatialmean_jja"
end if


wks=gsn_open_wks(OUTPUT_TYPE,plots_dir+"meanstate_changes_temp")
wks@VERBOSE=VERBOSE
opt=True
  opt@mpProjection="CylindricalEqualArea"
  opt@mpLimitMode="LatLon"
  opt@mpMinLonF=troppac_region(1,0)
  opt@mpMaxLonF=troppac_region(1,1)
  opt@mpMinLatF=troppac_region(0,0)
  opt@mpMaxLatF=troppac_region(0,1)
  opt@mpCenterLonF=180.
  opt@lbLabelBarOn=False
  opt@tiMainString=""
  opt@gsnCenterString=""
  opt@cnFillPalette="CBR_coldhot"
  opt@cnLevelSelectionMode = "ExplicitLevels"   
  opt@cnLevels=(/-5.,-3.,-2.,-1.,-0.5,0.5,1.,2.,3.,5./)
  opt@gsnStringFontHeightF=0.03
  opt@CONSISTENCY=CONSISTENCY ;Turn on stippling
  opt@OVERLAY_CONTROL=OVERLAY_PREIND
  opt@OVERLAY_CONTROL_MANUALLEVS=OVERLAY_PREIND_MANUALLEV
opt_pan=True
  opt_pan@lbTitleOn=False
  opt_pan@lbOrientation = "vertical"
  opt_pan@gsnPanelLabelBar=True
  opt_pan@gsnFrame=False
  opt_pan@lbTitleString="Temperature Difference (oC)"
  opt_pan@lbLabelFontHeightF=0.016
  opt_pan@dims=(/1,2/)

n_expts=dimsizes(expts)-2
do i=0,n_expts-1
  opt@gsnLeftString=plot_letters(i,:)
  opt@gsnRightString=expts(i+2)+(/" DJF"," JJA"/)
  opt_pan@gsnPanelTop=1-(tofloat(i)/n_expts)
  opt_pan@gsnPanelBottom=1-(tofloat(i+1)/n_expts)
  plotDiffEnsMnMaps(expts(i+2),expts(0),(/djf_field,jja_field/),wks,opt,opt_pan)
end do

frame(wks)
delete(wks)
delete([/opt,opt_pan/])