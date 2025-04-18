#!/bin/bash
set -e
set -u

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
    --write-composite-transform 1 \
    --output [${OUTPUT_DIR}/align_,${OUTPUT_DIR}/Aligned.nii.gz] \
    --initial-moving-transform [${FIXED_IMG},${INPUT_IMG},1] \
    --transform Rigid[0.1] \
    --metric MI[${FIXED_IMG},${INPUT_IMG},1,32,Regular,0.25] \
    --convergence [0,1e-6,10] \
    --shrink-factors 1 \
    --smoothing-sigmas 0vox
