#!/bin/bash
set -e
set -u

module load apptainer

export PROJECT_DIR=/home/mdugre/scratch/mri-registration-rp
export SIF_DIR=/home/mdugre/projects/rrg-glatard/mdugre/containers
export TEMPLATEFLOW_DIR=/home/mdugre/projects/rrg-glatard/mdugre/templateflow
export DATA_DIR=${PROJECT_DIR}/datasets/ds004513
SLURM_OPTS="--account=rrg-glatard"

#####################
# ANTs Registration #
#####################
export FIXED_IMG=/templateflow/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_desc-brain_T1w.nii.gz
export SIF_IMG=${SIF_DIR}/ants-vprec-no_metrics.simg

# Space search
export NUM_SUBJECTS=$(wc -l < subject_ids.txt)
for precision in {6..23}; do
    for range in {8..7}; do
        export EXPERIMENT_NAME="antsRegistration-r${range}-p${precision}"
        export APPTAINERENV_VFC_BACKENDS="libinterflop_vprec.so --range-binary32=$range --precision-binary32=$precision --range-binary64=$range --precision-binary64=$precision"
        # sbatch --job-name=${EXPERIMENT_NAME} --array=1-${NUM_SUBJECTS} ${SLURM_OPTS} ./sbatch/antsRegistration-0001.sbatch
        # sbatch --job-name=${EXPERIMENT_NAME} --array=1-${NUM_SUBJECTS} ${SLURM_OPTS} ./sbatch/antsRegistration-0011.sbatch
        # sbatch --job-name=${EXPERIMENT_NAME} --array=1-${NUM_SUBJECTS} ${SLURM_OPTS} ./sbatch/antsRegistration-0100.sbatch
        # sbatch --job-name=${EXPERIMENT_NAME} --array=1-${NUM_SUBJECTS} ${SLURM_OPTS} ./sbatch/antsRegistration-0110.sbatch
        # sbatch --job-name=${EXPERIMENT_NAME} --array=1-${NUM_SUBJECTS} ${SLURM_OPTS} ./sbatch/antsRegistration-0111.sbatch
        # sbatch --job-name=${EXPERIMENT_NAME} --array=1-${NUM_SUBJECTS} ${SLURM_OPTS} ./sbatch/antsRegistration-1111.sbatch
    done
done
