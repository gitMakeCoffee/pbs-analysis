#!/bin/bash

set -e

# Required inputs:
# -f, -n, -g, --is_input_control



# DEFAULTS:
BIN_SIZE=5000
GENOME="hg19"
BIN_OUTPUT_PREFIX="output"
BIN_OUTPUT_SUFFIX="bins"
RESCALED_OUTPUT_SUFFIX="mappability_rescaled"
SNR_OUTPUT_SUFFIX="snr.txt"
CNV_OUTPUT_SUFFIX="cnv_rescaled"
CNV_FLAG_FILENAME_SUFFIX="cnv_flag.txt"
CNV_RATIOS_FILENAME=NULL
BYPASS_CNV_RESCALING_STEP=FALSE
SCRIPTS_DIR=$(dirname "$0")
REFS_DIR="${SCRIPTS_DIR}/../references"



# Argument parsing
while [ $# -gt 0 ]
do
    case $1 in
        -f) # Path to bam file
            shift
            BAM=$1
            shift
            ;;
        -w) # Bin size
            shift
            BIN_SIZE=$1
            shift
            ;;
        -g) # Genome
            shift
            GENOME=$1
            shift
            ;;
        -n) # Prefix, ie sample name
            shift
            BIN_OUTPUT_PREFIX=$1
            shift
            ;;
        -s) # Suffix for binning step
            shift
            BIN_OUTPUT_SUFFIX=$1
            shift
            ;;
        --rescaled_output_suffix) # Suffix for BED output of mappability rescaling step
            shift
            RESCALED_OUTPUT_SUFFIX=$1
            shift
            ;;
        --snr_output_suffix) # Suffix for signal to noise ratio output of mappability rescaling step
            shift
            SNR_OUTPUT_SUFFIX=$1 
            shift
            ;;
        --is_input_control) # If TRUE, will generate cnv_ratios_filename. If FALSE, will need input from --cnv_ratios_filename, generated from input
            shift
            IS_INPUT_CONTROL=$1
            shift
            ;;
        --cnv_ratios_filename) # If input sample, name of output. If epitope sample, path to file generated using input.
            shift
            CNV_RATIOS_FILENAME=$1
            shift
            ;;
        --gc_content_filename) # Used in CNV rescaling step. Will be generated if not found.
            shift
            GC_CONTENT_FILENAME=$1
            shift
            ;;
        --cnv_output_suffix) # CNV scaling step, suffix for bed output containing CNV-rescaled windows
            shift
            CNV_OUTPUT_SUFFIX=$1
            shift
            ;;
        --cnv_flag_filename_suffix) # TSV output for P values of multimodality tests
            shift
            CNV_FLAG_FILENAME_SUFFIX=$1
            shift
            ;;
        --cnv_rescale_success_output) # File containing "true" if CNV rescaling succeeded
            shift
            CNV_RESCALE_SUCCESS_OUTPUT=$1
            shift
            ;;
        --bypass_cnv_rescaling_step) # Bool
            shift
            BYPASS_CNV_RESCALING_STEP=$1
            shift
            ;;
        --params_output) # Fitting step output
            shift
            PARAMS_OUTPUT=$1
            shift
            ;;
        --pbs_output) # Final step
            shift
            PBS_OUTPUT=$1
            shift
            ;;
        *)
            echo "ERROR: Unknown flag"
            exit 1
            ;;
    esac
done

GC_CONTENT_FILENAME="${REFS_DIR}/${GENOME}_${BIN_SIZE}_gc.bed"  
echo ""



echo "RUNNING PBS
"




# Binning
echo "===== BINNING ====="
#${SCRIPTS_DIR}/binning/bin.sh -f $BAM -n $BIN_OUTPUT_PREFIX -s $BIN_OUTPUT_SUFFIX -w $BIN_SIZE -g $GENOME
BED_FILENAME=${BIN_OUTPUT_PREFIX}_${GENOME}_${BIN_SIZE}bp_${BIN_OUTPUT_SUFFIX}.bedGraph
echo "Binning COMPLETE
"


sleep 1



# Mappability rescaling and signal to noise ratio
echo "===== MAPPABILITY RESCALING AND SIGNAL TO NOISE RATIO ====="
RESCALED_OUTPUT=${BIN_OUTPUT_PREFIX}_${RESCALED_OUTPUT_SUFFIX}.bedGraph
SNR_OUTPUT=${BIN_OUTPUT_PREFIX}_${SNR_OUTPUT_SUFFIX}
Rscript ${SCRIPTS_DIR}/rescaling/SubmitRescaleBinnedFiles.R --bam_filename $BAM --binned_bed_filename $BED_FILENAME --genome $GENOME --output_filename $RESCALED_OUTPUT --snr_output_filename $SNR_OUTPUT
echo "Mappability rescaling COMPLETE
"



sleep 1




# CNV rescaling with CNAnorm
echo "===== CNV RESCALING ====="
CNV_RESCALED_OUTPUT=${BIN_OUTPUT_PREFIX}_${CNV_OUTPUT_SUFFIX}.bedGraph
CNV_FLAG_OUTPUT_FILENAME=${BIN_OUTPUT_PREFIX}_${CNV_FLAG_FILENAME_SUFFIX}
CNV_RESCALE_SUCCESS_OUTPUT=${BIN_OUTPUT_PREFIX}_CNV_rescale_success.txt
# Rscript ${SCRIPTS_DIR}/cnvRescaling/SubmitCNVRescale.R --binned_bed_filename $RESCALED_OUTPUT --is_input_control $IS_INPUT_CONTROL --cnv_ratios_filename $CNV_RATIOS_FILENAME --assembly $GENOME --cnv_rescale_output $CNV_RESCALED_OUTPUT --saved_gc_filename $GC_CONTENT_FILENAME --cnv_flag_output_filename $CNV_FLAG_OUTPUT_FILENAME --cnv_rescale_success_output $CNV_RESCALE_SUCCESS_OUTPUT --bypass_cnv_rescaling_step $BYPASS_CNV_RESCALING_STEP
echo "CNV rescaling COMPLETE
"



sleep 1



# fitting
echo "===== FITTING ====="
PARAMS_OUTPUT="${BIN_OUTPUT_PREFIX}_fitting_params.tsv"
#time ${SCRIPTS_DIR}/fitting/SubmitFitDistributionWithCVM.R --binned_bed_filename $CNV_RESCALED_OUTPUT --sample_name $BIN_OUTPUT_PREFIX --params_output $PARAMS_OUTPUT --plot_data TRUE --plot_terra TRUE
echo "Fitting COMPLETE
"



sleep 1




# calculate PBS
echo "===== PBS ====="
PBS_OUTPUT="${BIN_OUTPUT_PREFIX}_PBS.bedGraph"
#${SCRIPTS_DIR}/pbs/SubmitProbabilityBeingSignal.R --binned_bed_filename $CNV_RESCALED_OUTPUT --params_df_filename $PARAMS_OUTPUT --pbs_filename $PBS_OUTPUT
echo "Calculating PBS COMPLETE
"
