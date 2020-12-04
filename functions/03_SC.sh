#!/bin/bash
#
# DWI POST structural TRACTOGRAPHY processing with bash:
#
# POST processing workflow for diffusion MRI TRACTOGRAPHY.
#
# This workflow makes use of MRtrix3
#
# Atlas an templates are avaliable from:
#
# https://github.com/MICA-MNI/micaopen/templates
#
#   ARGUMENTS order:
#   $1 : BIDS directory
#   $2 : participant
#   $3 : Out parcDirectory
#

BIDS=$1
id=$2
out=$3
SES=$4
PROC=$5
nocleanup=$6
tracts=$7
autoTract=$8
here=`pwd`

#------------------------------------------------------------------------------#
# qsub configuration
if [ "$PROC" = "qsub-MICA" ] || [ "$PROC" = "qsub-all.q" ];then
    export MICAPIPE=/data_/mica1/01_programs/micapipe
    source ${MICAPIPE}/functions/init.sh;
fi

# source utilities
source $MICAPIPE/functions/utilities.sh

# Assigns variables names
bids_variables $BIDS $id $out $SES

# Check inputs: DWI post TRACTOGRAPHY
fod=$proc_dwi/${id}_wm_fod_norm.mif
dwi_5tt=$proc_dwi/${id}_dwi_5tt.nii.gz
T1str_nat=${id}_t1w_${res}mm_nativepro
T1_seg_cerebellum=${dir_volum}/${T1str_nat}_cerebellum.nii.gz
T1_seg_subcortex=${dir_volum}/${T1str_nat}_subcortical.nii.gz
dwi_b0=$proc_dwi/${id}_dwi_b0.nii.gz
mat_dwi_affine=${dir_warp}/${id}_dwi_to_nativepro_0GenericAffine.mat
tdi=$proc_dwi/${id}_tdi_iFOD2-${tracts}.mif
lut_sc="$util_lut/lut_subcortical-cerebellum_mics.csv"
dwi_mask=$proc_dwi/${id}_dwi_mask.nii.gz
fa=$proc_dwi/${id}_dti_FA.mif

# Check inputs
if [ ! -f $fod ]; then Error "Subject $id doesn't have FOD:\n\t\tRUN -proc_dwi"; exit; fi
if [ ! -f $dwi_b0 ]; then Error "Subject $id doesn't have dwi_b0:\n\t\tRUN -proc_dwi"; exit; fi
if [ ! -f $mat_dwi_affine ]; then Error "Subject $id doesn't have an affine mat from T1nativepro to DWI space:\n\t\tRUN -proc_dwi"; exit; fi
if [ ! -f $dwi_5tt ]; then Error "Subject $id doesn't have 5tt in dwi space:\n\t\tRUN -proc_dwi"; exit; fi
if [ ! -f $T1_seg_cerebellum ]; then Error "Subject $id doesn't have cerebellar segmentation:\n\t\tRUN -post_structural"; exit; fi
if [ ! -f $T1_seg_subcortex ]; then Error "Subject $id doesn't have subcortical segmentation:\n\t\tRUN -post_structural"; exit; fi
if [ ! -f $dwi_mask ]; then Error "Subject $id doesn't have DWI binary mask:\n\t\tRUN -proc_dwi"; exit; fi
if [ ! -f $fa ]; then Error "Subject $id doesn't have a FA:\n\t\tRUN -proc_dwi"; exit; fi

# -----------------------------------------------------------------------------------------------
# Check IF output exits then EXIT
N=`ls ${dwi_cnntm}/${id}_${tracts}_*-connectome.txt | wc -l`
if [ $N -gt 3 ]; then Error "Subject $id already have some connectomes. If you want to re-run -SC first clean the outpus:
        micapipe_cleanup -SC -sub $id -out $out -bids $BIDS"; Do_cmd exit; fi
if [ -f $tdi ]; then Error "Subject $id has a TDI QC image of ${tracts} check the connectomes:\n\t\t${dwi_cnntm}"; Do_cmd exit; fi


#------------------------------------------------------------------------------#
Title "Running MICA POST-DWI processing (Tractography)"
micapipe_software
Info "Number of streamlines: $tracts"
Info "Auto-tractograms: $autoTract"
Info "Not erasing temporal dir: $nocleanup"

#	Timer
aloita=$(date +%s)
here=`pwd`
Nparc=0

# if temporary directory is empty
if [ -z ${tmp} ]; then tmp=/tmp; fi
# Create temporal directory
tmp=${tmp}/${RANDOM}_micapipe_post-dwi_${id}
[[ ! -d $tmp ]] && Do_cmd mkdir -p $tmp

# Create Connectomes directory for the outpust
[[ ! -d $dwi_cnntm ]] && Do_cmd mkdir -p $dwi_cnntm
[[ ! -d $dir_QC_png ]] && Do_cmd mkdir -p $dir_QC_png
Do_cmd cd ${tmp}

# -----------------------------------------------------------------------------------------------
# Prepare the segmentatons
parcellations=`find ${dir_volum} -name "*.nii.gz" ! -name "*cerebellum*" ! -name "*subcortical*"`
T1_seg_cerebellum=${dir_volum}/${T1str_nat}_cerebellum.nii.gz
T1_seg_subcortex=${dir_volum}/${T1str_nat}_subcortical.nii.gz
dwi_cere=${proc_dwi}/${id}_dwi_cerebellum.nii.gz
dwi_subc=${proc_dwi}/${id}_dwi_subcortical.nii.gz

if [[ ! -f $dwi_cere ]]; then Info "Registering Cerebellar parcellation to DWI-b0 space"
      Do_cmd antsApplyTransforms -d 3 -e 3 -i $T1_seg_cerebellum -r $dwi_b0 -n GenericLabel -t [$mat_dwi_affine,1] -o $dwi_cere -v -u int
      if [[ -f $dwi_cere ]]; then ((Nparc++)); fi
      # Threshold cerebellar nuclei (29,30,31,32,33,34) and add 100
      # Do_cmd fslmaths $dwi_cere -uthr 28 $dwi_cere
      Do_cmd fslmaths $dwi_cere -bin -mul 100 -add $dwi_cere $dwi_cere
else Info "Subject ${id} has a Cerebellar segmentation in DWI space"; ((Nparc++)); fi

if [[ ! -f $dwi_subc ]]; then Info "Registering Subcortical parcellation to DWI-b0 space"
      Do_cmd antsApplyTransforms -d 3 -e 3 -i $T1_seg_subcortex -r $dwi_b0 -n GenericLabel -t [$mat_dwi_affine,1] -o $dwi_subc -v -u int
      # Remove brain-stem (label 16)
      Do_cmd fslmaths $dwi_subc -thr 16 -uthr 16 -binv -mul $dwi_subc $dwi_subc
      if [[ -f $dwi_subc ]]; then ((Nparc++)); fi
else Info "Subject ${id} has a Subcortical segmentation in DWI space"; ((Nparc++)); fi

# -----------------------------------------------------------------------------------------------
# Generate probabilistic tracts
Info "Building the ${tracts} streamlines connectome!!!"
tck=${tmp}/DWI_tractogram_${tracts}.tck
weights=${tmp}/SIFT2_${tracts}.txt
Do_cmd tckgen -nthreads $CORES \
    $fod \
    $tck \
    -act $dwi_5tt \
    -crop_at_gmwmi \
    -seed_dynamic $fod \
    -maxlength 300 \
    -minlength 10 \
    -angle 22.5 \
    -backtrack \
    -select ${tracts} \
    -step .5 \
    -cutoff 0.06 \
    -algorithm iFOD2

# SIFT2
Do_cmd tcksift2 -nthreads $CORES $tck $fod $weights

# TDI for QC
Info "Creating a Track Density Image (tdi) of the $tracts connectome for QC"
Do_cmd tckmap -vox 1,1,1 -dec -nthreads $CORES $tck $tdi -force

# -----------------------------------------------------------------------------------------------
# Build the Connectomes
for seg in $parcellations; do
    parc_name=`echo ${seg/.nii.gz/} | awk -F 'nativepro_' '{print $2}'`
    nom=${dwi_cnntm}/${id}_${tracts}_${parc_name}
    lut="${util_lut}/lut_${parc_name}_mics.csv"
    dwi_cortex=$tmp/${id}_${parc_name}-cor_dwi.nii.gz # Segmentation in dwi space

    # -----------------------------------------------------------------------------------------------
    # Build the Cortical-Subcortical connectomes
    Info "Building $parc_name cortical connectome"
    # Take parcellation into DWI space
    Do_cmd antsApplyTransforms -d 3 -e 3 -i $seg -r $dwi_b0 -n GenericLabel -t [$mat_dwi_affine,1] -o $dwi_cortex -v -u int
    # Remove the medial wall
    for i in 1000 2000; do Do_cmd fslmaths $dwi_cortex -thr $i -uthr $i -binv -mul $dwi_cortex  $dwi_cortex; done

    # Build the Cortical connectomes
    Do_cmd tck2connectome -nthreads $CORES \
        $tck $dwi_cortex "${nom}_cor-connectome.txt" \
        -tck_weights_in $weights -quiet
    Do_cmd Rscript ${MICAPIPE}/functions/connectome_slicer.R --conn="${nom}_cor-connectome.txt" --lut1=${lut_sc} --lut2=${lut} --mica=${MICAPIPE}

    # Calculate the edge lenghts
    Do_cmd tck2connectome -nthreads $CORES \
        $tck $dwi_cortex "${nom}_cor-edgeLengths.txt" \
        -tck_weights_in $weights -scale_length -stat_edge mean -quiet
    Do_cmd Rscript ${MICAPIPE}/functions/connectome_slicer.R --conn="${nom}_cor-edgeLengths.txt" --lut1=${lut_sc} --lut2=${lut} --mica=${MICAPIPE}
    if [[ -f "${nom}_cor-connectome.txt" ]]; then ((Nparc++)); fi

    # -----------------------------------------------------------------------------------------------
    # Build the Cortical-Subcortical connectomes (-sub)
    Info "Building $parc_name cortical-subcortical connectome"
    dwi_cortexSub=$tmp/${id}_${parc_name}-sub_dwi.nii.gz
    Do_cmd fslmaths $dwi_cortex -binv -mul $dwi_subc -add $dwi_cortex $dwi_cortexSub -odt int # added the subcortical parcellation

    # Build the Cortical-Subcortical connectomes
    Do_cmd tck2connectome -nthreads $CORES \
        $tck $dwi_cortexSub "${nom}_sub-connectome.txt" \
        -tck_weights_in $weights -quiet
    Do_cmd Rscript ${MICAPIPE}/functions/connectome_slicer.R --conn="${nom}_sub-connectome.txt" --lut1=${lut_sc} --lut2=${lut} --mica=${MICAPIPE}

    # Calculate the edge lenghts
    Do_cmd tck2connectome -nthreads $CORES \
        $tck $dwi_cortexSub "${nom}_sub-edgeLengths.txt" \
        -tck_weights_in $weights -scale_length -stat_edge mean -quiet
    Do_cmd Rscript ${MICAPIPE}/functions/connectome_slicer.R --conn="${nom}_sub-edgeLengths.txt" --lut1=${lut_sc} --lut2=${lut} --mica=${MICAPIPE}
    if [[ -f "${nom}_sub-connectome.txt" ]]; then ((Nparc++)); fi

    # -----------------------------------------------------------------------------------------------
    # Build the Cortical-Subcortical-Cerebellar connectomes (-sub-cereb)
    Info "Building $parc_name cortical-subcortical-cerebellum connectome"
    dwi_all=$tmp/${id}_${parc_name}-full_dwi.nii.gz
    Do_cmd fslmaths $dwi_cortex -binv -mul $dwi_cere -add $dwi_cortexSub $dwi_all -odt int # added the cerebellar parcellation

    # Build the Cortical-Subcortical-Cerebellum connectomes
    Do_cmd tck2connectome -nthreads $CORES \
        $tck $dwi_all "${nom}_full-connectome.txt" \
        -tck_weights_in $weights -quiet
    Do_cmd Rscript ${MICAPIPE}/functions/connectome_slicer.R --conn="${nom}_full-connectome.txt" --lut1=${lut_sc} --lut2=${lut} --mica=${MICAPIPE}

    # Calculate the edge lenghts
    Do_cmd tck2connectome -nthreads $CORES \
        $tck $dwi_all "${nom}_full-edgeLengths.txt" \
        -tck_weights_in $weights -scale_length -stat_edge mean -quiet
    Do_cmd Rscript ${MICAPIPE}/functions/connectome_slicer.R --conn="${nom}_full-edgeLengths.txt" --lut1=${lut_sc} --lut2=${lut} --mica=${MICAPIPE}
    if [[ -f "${nom}_full-connectome.txt" ]]; then ((Nparc++)); fi
done

# Change connectome permissions
Do_cmd chmod 770 -R ${dwi_cnntm}/*

# -----------------------------------------------------------------------------------------------
# Compute Auto-Tractography
if [ $autoTract == "TRUE" ]; then
    Info "Running Auto-tract"
    autoTract_dir=$proc_dwi/auto_tract
    [[ ! -d $autoTract_dir ]] && Do_cmd mkdir -p $autoTract_dir
    fa_niigz=$tmp/${id}_dti_FA.nii.gz
    Do_cmd mrconvert $fa $fa_niigz
    echo -e "\033[38;5;118m\nCOMMAND -->  \033[38;5;122m03_auto_tracts.sh -tck $tck -outbase $autoTract_dir/${id} -mask $dwi_mask -fa $fa_niigz -tmpDir $tmp -keep_tmp  \033[0m"
    ${MICAPIPE}/functions/03_auto_tracts.sh -tck $tck -outbase $autoTract_dir/${id}_${tracts} -mask $dwi_mask -fa $fa_niigz -weights $weights -tmpDir $tmp -keep_tmp
fi

# -----------------------------------------------------------------------------------------------
# Clean temporal directory
if [[ $nocleanup == "FALSE" ]]; then Do_cmd rm -rf $tmp; else Info "Mica-pipe tmp directory was not erased: \n\t\t\t${tmp}"; fi
cd $here

# QC notification of completition
lopuu=$(date +%s)
eri=$(echo "$lopuu - $aloita" | bc)
eri=`echo print $eri/60 | perl`

# Notification of completition
if [ "$Nparc" -eq 56 ]; then status="DONE"; else status="ERROR missing a connectome: "; fi
Title "DWI-post TRACTOGRAPHY processing ended in \033[38;5;220m `printf "%0.3f\n" ${eri}` minutes \033[38;5;141m:
\t\tNumber of connectomes: `printf "%02d" $Nparc`/56
\tlogs:
`ls ${dir_logs}/post-dwi_*.txt`"
# Print QC stamp
echo "${id}, post_dwi, $status N=`printf "%02d" $Nparc`/56, `whoami`, `uname -n`, $(date), `printf "%0.3f\n" ${eri}`, $PROC" >> ${out}/brain-proc.csv
