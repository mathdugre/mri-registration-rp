#!/bin/bash
#SBATCH -J antsBrainExtraction
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=6G
#SBATCH -o log/brainExtraction/%x-%A-%a.out
set -e
set -u

module load apptainer

SUBJECT_ID=$(sed -n ${SLURM_ARRAY_TASK_ID}p < subject_ids.txt)
echo "
SUBJECT_ID: ${SUBJECT_ID}
DATA_DIR: ${DATA_DIR}
"

OUTPUT_FILE=${DATA_DIR}/derivatives/mri-registration-rp/antsBrainExtraction/sub-${SUBJECT_ID}/BrainExtractionBrain.nii.gz
if [ -e ${OUTPUT_FILE} ]; then
    echo "Brain extracted image already exists. Exiting."
    rm log/brainExtraction/${SLURM_JOB_NAME}-${SLURM_ARRAY_JOB_ID}-${SLURM_ARRAY_TASK_ID}.out
    exit 0
fi

APPTAINERENV_ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${SLURM_CPUS_PER_TASK}
apptainer exec --cleanenv \
    -B ${DATA_DIR}:/data \
    --env SUBJECT_ID=${SUBJECT_ID} \
    ${SIF_IMG} \
    antsBrainExtraction.sh \
    -d 3 \
    -a /data/sub-${SUBJECT_ID}/ses-open/anat/sub-${SUBJECT_ID}_ses-open_T1w.nii.gz \
    -e "/opt/templates/OASIS"/T_template0.nii.gz \
    -m "/opt/templates/OASIS"/T_template0_BrainCerebellumProbabilityMask.nii.gz \
    -o /data/derivatives/mri-registration-rp/antsBrainExtraction/sub-${SUBJECT_ID}/
