#!/bin/bash
#
# MICA BIDS structural processing
#
# Utilities

bids_variables() {
  # This functions assignes variables names acording to:
  #     BIDS directory = $1
  #     participant ID = $2
  #     Out directory  = $3
  BIDS=$1
  id=$2
  out=$3

  id=${id/sub-/}
  subject=sub-${id}
  subject_dir=$out/${subject}/ses-pre     # Output directory
  subject_bids=${BIDS}/${subject}/ses-pre # Input BIDS directory

  # Structural directories derivatives/
  proc_struct=$subject_dir/proc_struct # structural processing directory
  	 dir_first=$proc_struct/first      # FSL first
  	 dir_volum=$proc_struct/volumetric # Cortical segmentarion
  	 dir_patc=$proc_struct/surfpatch   # Surfpatch
  	 dir_surf=$proc_struct/surfaces    # surfaces
  			     dir_fs=$dir_surf/$subject     # freesurfer dir
  			     dir_conte=$dir_surf/conte69   # conte69
  proc_dwi=$subject_dir/proc_dwi      # DWI processing directory
  dir_unassigned=$subject_dir/unassigned/ # niftiTemp
  dir_warp=$subject_dir/xfms              # Transformation matrices
  dir_logs=$subject_dir/logs          # directory with log files

  # BIDS Files
  bids_T1ws=(`ls ${subject_bids}/anat/*T1w.nii*`)
  bids_dwis=(`ls ${subject_bids}/dwi/*dwi.nii*`)

}

bids_print.variables() {
  # This functions prints BIDS variables names
  # IF they exist
  Info "Inputs:"
  Note "id   =" $id
  Note "BIDS =" $BIDS
  Note "out  =" $out

  Info "BIDS naming:"
  Note "subject_bids =" $subject_bids
  Note "bids_T1ws    =" "N-${#bids_T1ws[@]}, $bids_T1ws"
  Note "bids_dwis    =" "N-${#bids_dwis[@]}, $bids_dwis"
  Note "subject      =" $subject
  Note "subject_dir  =" $subject_dir
  Note "proc_struct  =" $proc_struct
  Note "dir_warp     =" $dir_warp
  Note "logs         =" $dir_logs

  Info "Utilities:"
  Note "util_MNIvolumes   =" $util_MNIvolumes
  Note "util_parcelations =" $util_parcelations
  Note "util_surface      =" $util_surface
}

t1w_str() {
  # This function aims to create a NAME strig with homogeneous format
  # NEW name format:
  #      <id>_<source>_<resolution>_<brain-space>_<class>_<extras>.<extension>
  #
  id=$1
  t1w_full=$2
  space=$3
  res=`mrinfo ${bids_T1ws[i]} -spacing | awk '{printf "%.1f\n", $2}'`
  echo ${id}_t1w_${res}mm_${space}${run}
}

#---------------- FUNCTION: PRINT ERROR & Note ----------------#
# The following functions are only to print on the terminal colorful messages:
# This is optional on the pipelines
#     Error messages
#     Warning messages
#     Note messages
#     Warn messages
#     Title messages
Error() {
echo -e "\033[38;5;9m\n-------------------------------------------------------------\n\n[ ERROR ]..... $1\n
-------------------------------------------------------------\033[0m\n"
}
Note(){
# I replaced color \033[38;5;197m to \033[38;5;122m
echo -e "\t\t$1\t\033[38;5;122m$2\033[0m"
}
Info() {
Col="38;5;75m" # Color code
if [[ ${quiet} != TRUE ]]; then echo  -e "\033[$Col\n[ INFO ]..... $1 \033[0m"; fi
}
Warning() {
Col="38;5;184m" # Color code
if [[ ${quiet} != TRUE ]]; then echo  -e "\033[$Col\n[ WARNING ]..... $1 \033[0m"; fi
}
Warn() {
Col="38;5;184m" # Color code
if [[ ${quiet} != TRUE ]]; then echo  -e "\033[$Col
-------------------------------------------------------------\n
[ WARNING ]..... $1
\n-------------------------------------------------------------\033[0m"; fi
}
Title() {
if [[ ${quiet} != TRUE ]]; then echo -e "\n\033[38;5;141m
-------------------------------------------------------------
\t$1
-------------------------------------------------------------\033[0m"; fi
}

#---------------- FUNCTION: PRINT COLOR COMMAND ----------------#
function Do_cmd() {
# do_cmd sends command to stdout before executing it.
str="`whoami` @ `uname -n` `date`"
local l_command=""
local l_sep=" "
local l_index=1
while [ ${l_index} -le $# ]; do
    eval arg=\${$l_index}
    if [ "$arg" = "-fake" ]; then
      isFake=1
      arg=""
    fi
    if [ "$arg" = "-no_stderr" ]; then
      stderr=0
      arg=""
    fi
    if [ "$arg" == "-log" ]; then
      nextarg=`expr ${l_index} + 1`
      eval logfile=\${${nextarg}}
      arg=""
      l_index=$[${l_index}+1]
    fi
    l_command="${l_command}${l_sep}${arg}"
    l_sep=" "
    l_index=$[${l_index}+1]
   done
if [[ ${quiet} != TRUE ]]; then echo -e "\033[38;5;118m\n${str}:\nCOMMAND -->  \033[38;5;122m${l_command}  \033[0m"; fi
if [ -z $TEST ]; then $l_command; fi
}

cmd() {
text=$1
if [[ ${quiet} != TRUE ]]; then echo -e "\033[38;5;118mCOMMAND -->  \033[38;5;122m${text}  \033[0m"; fi
eval $text
}