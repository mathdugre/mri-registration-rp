#!/bin/bash
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=6G
#SBATCH -o log/0000/%x-%A-%a.out

set -u
set -e

module load apptainer

SUBJECT_ID=$(sed -n ${SLURM_ARRAY_TASK_ID}p < subject_ids.txt)
INPUT_IMG=${DATA_DIR}/derivatives/mri-registration-rp/antsBrainExtraction/sub-${SUBJECT_ID}/BrainExtractionBrain.nii.gz
OUTPUT_DIR=${DATA_DIR}/derivatives/mri-registration-rp/0000/${EXPERIMENT_NAME}/sub-${SUBJECT_ID}

OUTPUT_FILE=${OUTPUT_DIR}/Warped.nii.gz
if [ -e ${OUTPUT_FILE} ]; then
    echo "Registration already completed for sub-${SUBJECT_ID}"
    rm log/0000/${SLURM_JOB_NAME}-${SLURM_ARRAY_JOB_ID}-${SLURM_ARRAY_TASK_ID}.out
    exit 0
fi

# Use SLURM environment variables to set the number of threads
APPTAINERENV_ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${SLURM_CPUS_PER_TASK}
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
# Initial alignment
mkdir -p ${OUTPUT_DIR}
# export APPTAINERENV_VFC_BACKENDS=$VFC_BACKENDS
export APPTAINERENV_VFC_BACKENDS="libinterflop_ieee.so"
apptainer exec --cleanenv \
    -B ${DATA_DIR}:${DATA_DIR} \
    -B ${OUTPUT_DIR}:${OUTPUT_DIR} \
    -B ${TEMPLATEFLOW_DIR}:/templateflow \
    ${SIF_IMG} antsRegistration \
    --verbose 1 \
    --dimensionality 3 \
    --collapse-output-transforms 0 \
    --use-histogram-matching 0 \
    --winsorize-image-intensities [0.005,0.995] \
    --interpolation Linear \
    --random-seed 1 \
    --output [${OUTPUT_DIR}/,${OUTPUT_DIR}/Aligned.nii.gz] \
    --initial-moving-transform [${FIXED_IMG},${INPUT_IMG},1] \
    --transform Rigid[0.1] \
    --metric MI[${FIXED_IMG},${INPUT_IMG},1,32,Regular,0.25] \
    --convergence [0,1e-6,10] \
    --shrink-factors 1 \
    --smoothing-sigmas 0vox

# Rigid
# export APPTAINERENV_VFC_BACKENDS=$VFC_BACKENDS
export APPTAINERENV_VFC_BACKENDS="libinterflop_ieee.so"
INPUT_IMG=${OUTPUT_DIR}/Aligned.nii.gz
apptainer exec --cleanenv \
    -B ${DATA_DIR}:${DATA_DIR} \
    -B ${OUTPUT_DIR}:${OUTPUT_DIR} \
    -B ${TEMPLATEFLOW_DIR}:/templateflow \
    ${SIF_IMG} antsRegistration \
    --verbose 1 \
    --dimensionality 3 \
    --collapse-output-transforms 0 \
    --use-histogram-matching 0 \
    --winsorize-image-intensities [0.005,0.995] \
    --interpolation Linear \
    --random-seed 1 \
    --output [${OUTPUT_DIR}/,${OUTPUT_DIR}/Rigid.nii.gz] \
    --transform Rigid[0.1] \
    --metric MI[${FIXED_IMG},${INPUT_IMG},1,32,Regular,0.25] \
    --convergence [1000x500x250x100,1e-6,10] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox

# Affine
# export APPTAINERENV_VFC_BACKENDS=$VFC_BACKENDS
export APPTAINERENV_VFC_BACKENDS="libinterflop_ieee.so"
INPUT_IMG=${OUTPUT_DIR}/Rigid.nii.gz
apptainer exec --cleanenv \
    -B ${DATA_DIR}:${DATA_DIR} \
    -B ${OUTPUT_DIR}:${OUTPUT_DIR} \
    -B ${TEMPLATEFLOW_DIR}:/templateflow \
    ${SIF_IMG} antsRegistration \
    --verbose 1 \
    --dimensionality 3 \
    --collapse-output-transforms 0 \
    --use-histogram-matching 0 \
    --winsorize-image-intensities [0.005,0.995] \
    --interpolation Linear \
    --random-seed 1 \
    --output [${OUTPUT_DIR}/,${OUTPUT_DIR}/Affine.nii.gz] \
    --transform Affine[0.1] \
    --metric MI[${FIXED_IMG},${INPUT_IMG},1,32,Regular,0.25] \
    --convergence [1000x500x250x100,1e-6,10] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox

# Syn
# export APPTAINERENV_VFC_BACKENDS=$VFC_BACKENDS
export APPTAINERENV_VFC_BACKENDS="libinterflop_ieee.so"
INPUT_IMG=${OUTPUT_DIR}/Affine.nii.gz
apptainer exec --cleanenv \
    -B ${DATA_DIR}:${DATA_DIR} \
    -B ${OUTPUT_DIR}:${OUTPUT_DIR} \
    -B ${TEMPLATEFLOW_DIR}:/templateflow \
    ${SIF_IMG} antsRegistration \
    --verbose 1 \
    --dimensionality 3 \
    --collapse-output-transforms 0 \
    --use-histogram-matching 0 \
    --winsorize-image-intensities [0.005,0.995] \
    --interpolation Linear \
    --random-seed 1 \
    --output [${OUTPUT_DIR}/,${OUTPUT_DIR}/Warped.nii.gz,${OUTPUT_DIR}/InverseWarped.nii.gz] \
    --transform SyN[ 0.1,3,0 ] \
    --metric CC[${FIXED_IMG},${INPUT_IMG},1,4] \
    --convergence [100x70x50x20,1e-6,10] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox