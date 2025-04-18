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
    --output [${OUTPUT_DIR}/syn_,${OUTPUT_DIR}/Warped.nii.gz,${OUTPUT_DIR}/InverseWarped.nii.gz] \
    --initial-moving-transform ${OUTPUT_DIR}/affine_Composite.h5 \
    --transform SyN[ 0.1,3,0 ] \
    --metric CC[${FIXED_IMG},${INPUT_IMG},1,4] \
    --convergence [100x70x50x20,1e-6,10] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox

