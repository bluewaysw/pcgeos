/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		jdcoefct.c

AUTHOR:		Joon Song, Oct 29, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/29/95   	Initial version.

DESCRIPTION:
	

	$Id: jdcoefct.c,v 1.1.11.9 97/11/11 09:58:04 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 * jdcoefct.c
 *
 * Copyright (C) 1994-1995, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file contains the coefficient buffer controller for decompression.
 * This controller is the top level of the JPEG decompressor proper.
 * The coefficient buffer lies between entropy decoding and inverse-DCT steps.
 *
 * In buffered-image mode, this controller is the interface between
 * input-oriented processing and output-oriented processing.
 * Also, the input side (only) is used when reading a file for transcoding.
 */

#define JPEG_INTERNALS
#include <jinclude.h>
#include <jpeglib.h>

/* Private buffer controller object */

typedef struct {
  struct jpeg_d_coef_controller pub; /* public fields */

  /* These variables keep track of the current location of the input side. */
  /* cinfo->input_iMCU_row is also used for this. */
  JDIMENSION MCU_ctr;		/* counts MCUs processed in current row */
  int MCU_vert_offset;		/* counts MCU rows within iMCU row */
  int MCU_rows_per_iMCU_row;	/* number of such rows needed */

  /* The output side's location is represented by cinfo->output_iMCU_row. */

  /* In single-pass modes, it's sufficient to buffer just one MCU.
   * We allocate a workspace of D_MAX_BLOCKS_IN_MCU coefficient blocks,
   * and let the entropy decoder write into that workspace each time.
   */
  JBLOCKROW MCU_buffer[D_MAX_BLOCKS_IN_MCU];

} my_coef_controller;

typedef my_coef_controller * my_coef_ptr;


LOCAL void
start_iMCU_row (j_decompress_ptr cinfo)
/* Reset within-iMCU-row counters for a new row (input side) */
{
  my_coef_ptr coef = (my_coef_ptr) cinfo->coef;

  /* In an interleaved scan, an MCU row is the same as an iMCU row.
   * In a noninterleaved scan, an iMCU row has v_samp_factor MCU rows.
   * But at the bottom of the image, process only what's left.
   */
  if (cinfo->comps_in_scan > 1) {
    coef->MCU_rows_per_iMCU_row = 1;
  } else {
    if (cinfo->input_iMCU_row < (cinfo->total_iMCU_rows-1))
      coef->MCU_rows_per_iMCU_row = cinfo->cur_comp_info[0]->v_samp_factor;
    else
      coef->MCU_rows_per_iMCU_row = cinfo->cur_comp_info[0]->last_row_height;
  }

  coef->MCU_ctr = 0;
  coef->MCU_vert_offset = 0;
}


/*
 * Initialize for an input processing pass.
 */

void
coefct_start_input_pass (j_decompress_ptr cinfo)
{
  cinfo->input_iMCU_row = 0;
  start_iMCU_row(cinfo);
}


/*
 * Initialize for an output processing pass.
 */

void
coefct_start_output_pass (j_decompress_ptr cinfo)
{
  cinfo->output_iMCU_row = 0;
}


/*
 * Decompress and return some data in the single-pass case.
 * Always attempts to emit one fully interleaved MCU row ("iMCU" row).
 * Input and output must run in lockstep since we have only a one-MCU buffer.
 * Return value is JPEG_ROW_COMPLETED, JPEG_SCAN_COMPLETED, or JPEG_SUSPENDED.
 *
 * NB: output_buf contains a plane for each component in image.
 * For single pass, this is the same as the components in the scan.
 */

int
decompress_onepass (j_decompress_ptr cinfo, JSAMPIMAGE output_buf)
{
  my_coef_ptr coef = (my_coef_ptr) cinfo->coef;
  JDIMENSION MCU_col_num;	/* index of current MCU within row */
  JDIMENSION last_MCU_col = cinfo->MCUs_per_row - 1;
  JDIMENSION last_iMCU_row = cinfo->total_iMCU_rows - 1;
  int blkn, ci, xindex, yindex, yoffset, useful_width;
  JSAMPARRAY output_ptr;
  JDIMENSION start_col, output_col;
  jpeg_component_info *compptr;
  inverse_DCT_method_ptr inverse_DCT;

  /* Loop to process as much as one whole iMCU row */
  for (yoffset = coef->MCU_vert_offset; yoffset < coef->MCU_rows_per_iMCU_row;
       yoffset++) {
    for (MCU_col_num = coef->MCU_ctr; MCU_col_num <= last_MCU_col;
	 MCU_col_num++) {
      /* Try to fetch an MCU.  Entropy decoder expects buffer to be zeroed. */
      jzero_far((void *) coef->MCU_buffer[0],
		(size_t) (cinfo->blocks_in_MCU * SIZEOF(JBLOCK)));
      if (! (*cinfo->entropy->decode_mcu) (cinfo, coef->MCU_buffer)) {
	/* Suspension forced; update state counters and exit */
	coef->MCU_vert_offset = yoffset;
	coef->MCU_ctr = MCU_col_num;
	return JPEG_SUSPENDED;
      }
      /* Determine where data should go in output_buf and do the IDCT thing.
       * We skip dummy blocks at the right and bottom edges (but blkn gets
       * incremented past them!).  Note the inner loop relies on having
       * allocated the MCU_buffer[] blocks sequentially.
       */
      blkn = 0;			/* index of current DCT block within MCU */
      for (ci = 0; ci < cinfo->comps_in_scan; ci++) {
	compptr = cinfo->cur_comp_info[ci];
	/* Don't bother to IDCT an uninteresting component. */
	if (! compptr->component_needed) {
	  blkn += compptr->MCU_blocks;
	  continue;
	}
	inverse_DCT = cinfo->idct->inverse_DCT[compptr->component_index];
	useful_width = (MCU_col_num < last_MCU_col) ? compptr->MCU_width
						    : compptr->last_col_width;
	output_ptr = output_buf[ci] + yoffset * compptr->DCT_scaled_size;
	start_col = MCU_col_num * compptr->MCU_sample_width;
	for (yindex = 0; yindex < compptr->MCU_height; yindex++) {
	  if (cinfo->input_iMCU_row < last_iMCU_row ||
	      yoffset+yindex < compptr->last_row_height) {
	    output_col = start_col;
	    for (xindex = 0; xindex < useful_width; xindex++) {
	      (*inverse_DCT) (cinfo, compptr,
			      (JCOEFPTR) coef->MCU_buffer[blkn+xindex],
			      output_ptr, output_col);
	      output_col += compptr->DCT_scaled_size;
	    }
	  }
	  blkn += compptr->MCU_width;
	  output_ptr += compptr->DCT_scaled_size;
	}
      }
    }
    /* Completed an MCU row, but perhaps not an iMCU row */
    coef->MCU_ctr = 0;
  }
  /* Completed the iMCU row, advance counters for next one */
  cinfo->output_iMCU_row++;
  if (++(cinfo->input_iMCU_row) < cinfo->total_iMCU_rows) {
    start_iMCU_row(cinfo);
    return JPEG_ROW_COMPLETED;
  }
  /* Completed the scan */
  (*cinfo->inputctl->finish_input_pass) (cinfo);
  return JPEG_SCAN_COMPLETED;
}


/*
 * Dummy consume-input routine for single-pass operation.
 */

EXTERN int dummy_consume_data (j_decompress_ptr cinfo);

int
METHODDEF_dummy_consume_data (j_decompress_ptr cinfo)
{
  return JPEG_SUSPENDED;	/* Always indicate nothing was done */
}


/*
 * Initialize coefficient buffer controller.
 */

GLOBAL void
jinit_d_coef_controller (j_decompress_ptr cinfo)
{
  my_coef_ptr coef;
  JBLOCKROW buffer;
  int i;

  coef = (my_coef_ptr)
    alloc_small((j_common_ptr) cinfo, JPOOL_IMAGE, SIZEOF(my_coef_controller));
  cinfo->coef = (struct jpeg_d_coef_controller *) coef;

  /* Create the coefficient buffer. */
  /* We only need a single-MCU buffer. */

  buffer = (JBLOCKROW) alloc_small((j_common_ptr) cinfo, JPOOL_IMAGE,
				   D_MAX_BLOCKS_IN_MCU * SIZEOF(JBLOCK));
  for (i = 0; i < D_MAX_BLOCKS_IN_MCU; i++) {
    coef->MCU_buffer[i] = buffer + i;
  }
}
