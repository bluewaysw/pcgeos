##############################################################################
#
# PROJECT:      IJGJPEG
# FILE:         IJGJPEG.gp
#
# AUTHOR:       Marcus Gr”ber
#
##############################################################################

name            ijgjpeg.lib
longname        "Breadbox IJG JPEG Library"
tokenchars      "IJPG"
tokenid         16424

type            library, single, c-api

entry IJGJPEGENTRY

library	geos
library ui
library ansic

export JPEG_STD_ERROR
export JPEG_CREATECOMPRESS   
export JPEG_CREATEDECOMPRESS
export JPEG_DESTROY_COMPRESS
export JPEG_DESTROY_DECOMPRESS
export JPEG_STDIO_DEST
export JPEG_STDIO_SRC
export JPEG_SET_DEFAULTS
export JPEG_SET_COLORSPACE
export JPEG_DEFAULT_COLORSPACE
export JPEG_SET_QUALITY
export JPEG_SET_LINEAR_QUALITY
export JPEG_ADD_QUANT_TABLE
export JPEG_QUALITY_SCALING
export JPEG_SIMPLE_PROGRESSION
export JPEG_SUPPRESS_TABLES
export JPEG_ALLOC_QUANT_TABLE
export JPEG_ALLOC_HUFF_TABLE
export JPEG_START_COMPRESS
export JPEG_WRITE_SCANLINES
export JPEG_FINISH_COMPRESS
export JPEG_WRITE_RAW_DATA
export JPEG_WRITE_MARKER
export JPEG_WRITE_TABLES
export JPEG_READ_HEADER
export JPEG_START_DECOMPRESS
export JPEG_READ_SCANLINES
export JPEG_FINISH_DECOMPRESS
export JPEG_READ_RAW_DATA
export JPEG_HAS_MULTIPLE_SCANS
export JPEG_START_OUTPUT
export JPEG_FINISH_OUTPUT
export JPEG_INPUT_COMPLETE
export JPEG_NEW_COLORMAP
export JPEG_CONSUME_INPUT
export JPEG_CALC_OUTPUT_DIMENSIONS
export JPEG_SET_MARKER_PROCESSOR
export JPEG_READ_COEFFICIENTS
export JPEG_WRITE_COEFFICIENTS
export JPEG_COPY_CRITICAL_PARAMETERS
export JPEG_ABORT_COMPRESS
export JPEG_ABORT_DECOMPRESS
export JPEG_ABORT
export JPEG_DESTROY
export JPEG_RESYNC_TO_RESTART
#only if PROGRESS_DISPLAY turned on in CInclude/htmldrv.h
export JPEG_INIT_LOADPROGRESS

export JPEG_SET_ERROR_HANDLER_CONTEXT

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

