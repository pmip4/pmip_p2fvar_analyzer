; This script shows how to create a multi-panel plot using NCL
; This particular script makes Fig. 7 of Brown et al (2020, https://cp.copernicus.org/articles/16/1777/2020/)
; It uses the plotDiffEnsMnMaps procedure to create ensemble-mean differences.
; There are 6 experiments (which are differenced from piControl)
; Two different variables from the cvdp_data files are plotted
; Run from ncl_scripts/ with
; > ncl multi-panel_plot.ncl

; Specify the experiments
expts=(/"piControl","historical","midHolocene-cal-adj","lgm-cal-adj","lig127k-cal-adj","1pctCO2","abrupt4xCO2"/)
; All the anomalies are computed with respect to the first experiment

; Specify the resulting image file
OUTPUT_TYPE="pdf"; either "png" or "pdf"
output_filename="Brownetal2020_Fig7" ; Add a (relative) directory with "dirname/" beforehand  

; Set some plot switches built for the NCL analyzer scripts
CONSISTENCY=True ; Stipple where >66% of ensemble members agree on sign. 
OVERLAY_PREIND=True ; Overlay contour lines to show the ensemble mean pattern in the control run
OVERLAY_PREIND_MANUALLEV=(/0,12,2/) ;Manually specify the contour level (from 0 to 12 in steps of 2 mm/day)
VERBOSE=False ;if True, provides a modicum of more information about whats going on in the plots - used for debugging mainly.

; Define tropical focus of the figure
troppac_region=(/(/-25.,25./),(/100.,280./)/);lat and lons of the edge of the plots (/(/latS,latN/),(/lonW,lonE/)/)

; Provide some strings to label each of the panels
plot_letters=(/(/"a","b"/),(/"c","d"/),(/"e","f"/),(/"g","h"/),(/"i","j"/),(/"k","l"/)/)

; Define the plot resources
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
  opt@cnFillPalette="CBR_drywet"
  opt@cnLevelSelectionMode = "ExplicitLevels"   
  opt@cnLevels=(/-5.,-2.,-1.,-0.5,-0.1,0.1,0.5,1.,2.,5./)
  opt@gsnStringFontHeightF=0.03
  opt@CONSISTENCY=CONSISTENCY ;Turn on stippling
  opt@OVERLAY_CONTROL=OVERLAY_PREIND
  opt@OVERLAY_CONTROL_MANUALLEVS=OVERLAY_PREIND_MANUALLEV

; Define the resources associated with the panelling
opt_pan=True
  opt_pan@lbTitleOn=False
  opt_pan@lbOrientation = "vertical"
  opt_pan@gsnPanelLabelBar=True
  opt_pan@gsnFrame=False
  opt_pan@lbTitleString="Precip. Difference (mm/day)"
  opt_pan@lbLabelFontHeightF=0.016
  opt_pan@dims=(/1,2/)

;;;;;;;;;;;;; Start the NCL script ;;;;;;;;;;;;;;

; Load in the ncl functions and procedures
loadscript("./cvdp_data.functions.ncl")

; Open the workstation
wks=gsn_open_wks(OUTPUT_TYPE,output_filename)
wks@VERBOSE=VERBOSE

; Loop over and make the 5 different pairs of panels
n_expts=dimsizes(expts)-2
do i=0,n_expts-1
  opt@gsnLeftString=plot_letters(i,:)
  opt@gsnRightString=expts(i+2)+(/" DJF"," JJA"/)
  opt_pan@gsnPanelTop=1-(tofloat(i)/n_expts)
  opt_pan@gsnPanelBottom=1-(tofloat(i+1)/n_expts)
  plotDiffEnsMnMaps(expts(i+2),expts(0),(/"pr_spatialmean_djf","pr_spatialmean_jja"/),wks,opt,opt_pan)
end do

frame(wks)
delete(wks)
delete([/opt,opt_pan/])