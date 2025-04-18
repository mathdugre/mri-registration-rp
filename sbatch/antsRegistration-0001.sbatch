#!/bin/bash
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=6G
#SBATCH -o log/0001/%x-%A-%a.out

set -u
set -e

module load apptainer

export SUBJECT_ID=$(sed -n ${SLURM_ARRAY_TASK_ID}p < subject_ids.txt)
export INPUT_IMG=${DATA_DIR}/derivatives/mri-registration-rp/antsBrainExtraction/sub-${SUBJECT_ID}/BrainExtractionBrain.nii.gz
export OUTPUT_DIR=${DATA_DIR}/derivatives/mri-registration-rp/0001/${EXPERIMENT_NAME}/sub-${SUBJECT_ID}
mkdir -p ${OUTPUT_DIR}

OUTPUT_FILE=${OUTPUT_DIR}/Warped.nii.gz
if [ -e ${OUTPUT_FILE} ]; then
    echo "Registration already completed for sub-${SUBJECT_ID}"
    rm log/0001/${SLURM_JOB_NAME}-${SLURM_ARRAY_JOB_ID}-${SLURM_ARRAY_TASK_ID}.out
    exit 0
fi

# Use SLURM environment variables to set the number of threads
export APPTAINERENV_ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${SLURM_CPUS_PER_TASK}
VFC_BACKENDS=${APPTAINERENV_VFC_BACKENDS}

echo "
##########################
# Experiment information #
##########################

EXPERIMENT_NAME: $EXPERIMENT_NAME
VFC_BACKENDS: $VFC_BACKENDS

SIF_IMG: $SIF_IMG

SUBJECT_ID: $SUBJECT_ID
INPUT_IMG: $INPUT_IMG
OUTPUT_DIR: $OUTPUT_DIR

FIXED_IMG: $FIXED_IMG
DATA_DIR: $DATA_DIR
TEMPLATEFLOW_DIR: $TEMPLATEFLOW_DIR
ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS: $APPTAINERENV_ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS
##########################
"

export APPTAINERENV_VFC_BACKENDS="libinterflop_ieee.so"
sh ./sbatch/ants-initial-align.sh
sh ./sbatch/ants-rigid.sh
sh ./sbatch/ants-affine.sh

export APPTAINERENV_VFC_BACKENDS=$VFC_BACKENDS
sh ./sbatch/ants-syn.sh
