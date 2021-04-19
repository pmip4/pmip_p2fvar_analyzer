; This script was used to create an alternate version of lgm_tempchange_in_latbands.csv
; generated using the data that was included in Kageyama et al (2021,https://doi.org/10.5194/cp-2019-169) 
; - I have been provided with a tar bundle of all these climatologies data. It is not paleocaladjust-ed, but that doesn't matter for annual means

DATA_DIR="/data/aod/PMIP4_LGM_climatologies/"
models=systemfunc("ls -Icheck_plots_21-01-29 -IMPI-ESM1-2-LR "+DATA_DIR)
area_avg_names=(/"GLOBAL","GLOBAL (over land)","GLOBAL (over ocean)","60-90oN","60-90oN (over land)","60-90oN (over ocean)","30-60oN","30-60oN (over land)","30-60oN (over ocean)","0-30oN","0-30oN (over land)","0-30oN (over ocean)","30oS-0","30oS-0 (over land)","30oS-0 (over ocean)","60-30oS","60-30oS (over land)","60-30oS (over ocean)","90-60oS","90-60oS (over land)","90-60oS (over ocean)"/)
array=new((/dimsizes(models),dimsizes(area_avg_names)/),float)

latN=(/90.,90.,60.,30.,0.,-30.,-60./)
latS=(/-90.,60.,30.,0.,-30.,-60.,-90./)
do mod_i=0,dimsizes(models)-1
    ; Load in this model's data
    lgm_tas_fi=addfile(DATA_DIR+models(mod_i)+"/tas_Amon_"+models(mod_i)+"_lgm_monClim.nc","r")
    lgm_tas_mon=lgm_tas_fi->tas(:,:,:)
    lgm_tas=dim_avg_n_Wrap(lgm_tas_mon,0)
    lgm_lf_fi=addfile(DATA_DIR+models(mod_i)+"/sftlf_fx_"+models(mod_i)+"_lgm.nc","r")
    lgm_lf=lgm_lf_fi->sftlf
    pi_lf_fi=addfile(DATA_DIR+models(mod_i)+"/sftlf_fx_"+models(mod_i)+"_piControl.nc","r")
    pi_lf=pi_lf_fi->sftlf
    lgm_area_fi=addfile(DATA_DIR+models(mod_i)+"/areacella_fx_"+models(mod_i)+"_lgm.nc","r")
    lgm_area=lgm_area_fi->areacella
    lgm_tas_lnd=lgm_tas
    lgm_tas_ocn=lgm_tas
    ; The below follows one of Dan Lunt's suggestions as considering the changes in land-sea mask as part of the area averages 
    ;    lgm_tas_lnd=mask(lgm_tas,lgm_lf.ge.50,True)
    ;    lgm_tas_ocn=mask(lgm_tas,lgm_lf.lt.50,True)
    ; Adopting Alan Haywood's approach for "over land/sea" as being over land/sea in both LGM and piControl
    lgm_tas_lnd=mask(lgm_tas,lgm_lf.ge.50.and.pi_lf.ge.50,True)
    lgm_tas_ocn=mask(lgm_tas,lgm_lf.lt.50.and.pi_lf.lt.50,True)
    pi_tas_fi=addfile(DATA_DIR+models(mod_i)+"/tas_Amon_"+models(mod_i)+"_piControl_monClim.nc","r")
    pi_tas_mon=pi_tas_fi->tas(:,:,:)
    pi_tas=dim_avg_n_Wrap(pi_tas_mon,0)
    pi_area_fi=addfile(DATA_DIR+models(mod_i)+"/areacella_fx_"+models(mod_i)+"_piControl.nc","r")
    pi_area=pi_area_fi->areacella
    pi_tas_lnd=pi_tas
    pi_tas_ocn=pi_tas
    ; The below follows one of Dan Lunt's suggestions as considering the changes in land-sea mask as part of the area averages 
    ;   pi_tas_lnd=mask(pi_tas,pi_lf.ge.50,True)
    ;   pi_tas_ocn=mask(pi_tas,pi_lf.lt.50,True)
    ; Adopting Alan Haywood's approach for "over land/sea" as being over land/sea in both LGM and piControl
    pi_tas_lnd=mask(pi_tas,lgm_lf.ge.50.and.pi_lf.ge.50,True)
    pi_tas_ocn=mask(pi_tas,lgm_lf.lt.50.and.pi_lf.lt.50,True)

    do band_i=0,dimsizes(latN)-1
        ; compute the values for each area average...
        lgm_aa=tofloat(wgt_areaave2(lgm_tas({latS(band_i):latN(band_i)},:),lgm_area({latS(band_i):latN(band_i)},:),0))
        pi_aa=tofloat(wgt_areaave2(pi_tas({latS(band_i):latN(band_i)},:),pi_area({latS(band_i):latN(band_i)},:),0))
        lgm_aa_lnd=tofloat(wgt_areaave2(lgm_tas_lnd({latS(band_i):latN(band_i)},:),lgm_area({latS(band_i):latN(band_i)},:),0))
        pi_aa_lnd=tofloat(wgt_areaave2(pi_tas_lnd({latS(band_i):latN(band_i)},:),pi_area({latS(band_i):latN(band_i)},:),0))
        lgm_aa_ocn=tofloat(wgt_areaave2(lgm_tas_ocn({latS(band_i):latN(band_i)},:),lgm_area({latS(band_i):latN(band_i)},:),0))
        pi_aa_ocn=tofloat(wgt_areaave2(pi_tas_ocn({latS(band_i):latN(band_i)},:),pi_area({latS(band_i):latN(band_i)},:),0))
        array(mod_i,3*band_i)=lgm_aa-pi_aa
        array(mod_i,3*band_i+1)=lgm_aa_lnd-pi_aa_lnd
        array(mod_i,3*band_i+2)=lgm_aa_ocn-pi_aa_ocn
    end do
    delete([/lgm_tas_fi,lgm_tas_mon,lgm_tas,lgm_lf_fi,lgm_lf,pi_tas_fi,pi_tas_mon,pi_tas,pi_lf_fi,pi_lf,\
             pi_area,pi_area_fi,lgm_area,lgm_area_fi,lgm_tas_ocn,lgm_tas_lnd,pi_tas_ocn,pi_tas_lnd/])
end do

print("Simulated Temperature Changes,"+str_join(models,","))
do aa_i=0,dimsizes(area_avg_names)-1
  print(area_avg_names(aa_i)+","+str_join(tostring(array(:,aa_i)),","))
;  print(area_avg_names(aa_i)+","+str_join(tostring(array(ind(models.eq."INM-CM4-8"),aa_i)),","))
end do

;ratio=array(:,1)/array(:,2)
;print(ratio)