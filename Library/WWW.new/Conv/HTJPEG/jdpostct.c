/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		jdpostct.c

AUTHOR:		Joon Song, Oct 29, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/29/95   	Initial version.

DESCRIPTION:
	

	$Id: jdpostct.c,v 1.1.11.6 97/11/11 10:12:22 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 * jdpostct.c
 *
 * Copyright (C) 1994-1995, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file contains the decompression postprocessing controller.
 * This controller manages the upsampling, color conversion, and color
 * quantization/reduction steps; specifically, it controls the buffering
 * between upsample/color conversion and color quantization/reduction.
 *
 * If no color quantization/reduction is required, then this module has no
 * work to do, and it just hands off to the upsample/color conversion code.
 * An integrated upsample/convert/quantize process would replace this module
 * entirely.
 */

#define JPEG_INTERNALS
#include <jinclude.h>
#include <jpeglib.h>


/* Private buffer controller object */

typedef struct {
  struct jpeg_d_post_controller pub; /* public fields */

  /* Color quantization source buffer: this holds output data from
   * the upsample/color conversion step to be passed to the quantizer.
   * For two-pass color quantization, we need a full-image buffer;
   * for one-pass operation, a strip buffer is sufficient.
   */
  jvirt_sarray_ptr whole_image;	/* virtual array, or NULL if one-pass */
  JSAMPARRAY buffer;		/* strip buffer, or current strip of virtual */
  JDIMENSION strip_height;	/* buffer size in rows */
  /* for two-pass mode only: */
  JDIMENSION starting_row;	/* row # of first row in current strip */
  JDIMENSION next_row;		/* index of next row to fill/empty in strip */
} my_post_controller;

typedef my_post_controller * my_post_ptr;


/* Forward declarations */
EXTERN void post_process_1pass
	(j_decompress_ptr cinfo,
	 JSAMPIMAGE input_buf, JDIMENSION *in_row_group_ctr,
	 JDIMENSION in_row_groups_avail,
	 JSAMPARRAY output_buf, JDIMENSION *out_row_ctr,
	 JDIMENSION out_rows_avail);


/*
 * Initialize for a processing pass.
 */

EXTERN void start_pass_dpost (j_decompress_ptr cinfo, J_BUF_MODE pass_mode);

void
METHODDEF_start_pass_dpost (j_decompress_ptr cinfo, J_BUF_MODE pass_mode)
{
  my_post_ptr post = (my_post_ptr) cinfo->post;

  switch (pass_mode) {
  case JBUF_PASS_THRU:
    if (cinfo->quantize_colors) {
      /* Single-pass processing with color quantization. */
      post->pub.post_process_data = post_process_1pass;
      /* We could be doing buffered-image output before starting a 2-pass
       * color quantization; in that case, jinit_d_post_controller did not
       * allocate a strip buffer.  Use the virtual-array buffer as workspace.
       */
      if (post->buffer == NULL) {
	post->buffer = 
	  access_virt_sarray ((j_common_ptr) cinfo, post->whole_image,
			      (JDIMENSION) 0, post->strip_height, TRUE);
      }
    } else {
      /* For single-pass processing without color quantization,
       * I have no work to do; just call the upsampler directly.
       */
      post->pub.post_process_data = cinfo->upsample->upsample;
    }
    break;
  default:
    ERREXIT(cinfo, JERR_BAD_BUFFER_MODE);
    break;
  }
  post->starting_row = post->next_row = 0;
}


/*
 * Process some data in the one-pass (strip buffer) case.
 * This is used for color precision reduction as well as one-pass quantization.
 */

EXTERN void post_process_1pass (j_decompress_ptr cinfo,
		    JSAMPIMAGE input_buf, JDIMENSION *in_row_group_ctr,
		    JDIMENSION in_row_groups_avail,
		    JSAMPARRAY output_buf, JDIMENSION *out_row_ctr,
		    JDIMENSION out_rows_avail);

void
METHODDEF_post_process_1pass (j_decompress_ptr cinfo,
		    JSAMPIMAGE input_buf, JDIMENSION *in_row_group_ctr,
		    JDIMENSION in_row_groups_avail,
		    JSAMPARRAY output_buf, JDIMENSION *out_row_ctr,
		    JDIMENSION out_rows_avail)
{
  my_post_ptr post = (my_post_ptr) cinfo->post;
  JDIMENSION num_rows, max_rows;

  /* Fill the buffer, but not more than what we can dump out in one go. */
  /* Note we rely on the upsampler to detect bottom of image. */
  max_rows = out_rows_avail - *out_row_ctr;
  if (max_rows > post->strip_height)
    max_rows = post->strip_height;
  num_rows = 0;
  (*cinfo->upsample->upsample) (cinfo,
		input_buf, in_row_group_ctr, in_row_groups_avail,
		post->buffer, &num_rows, max_rows);
  /* Quantize and emit data. */
  quantize_fs_dither (cinfo,
		      post->buffer, output_buf + *out_row_ctr, (int) num_rows);
  *out_row_ctr += num_rows;
}


/*
 * Initialize postprocessing controller.
 */

GLOBAL void
jinit_d_post_controller (j_decompress_ptr cinfo)
{
  my_post_ptr post;

  post = (my_post_ptr) alloc_small ((j_common_ptr) cinfo, JPOOL_IMAGE,
				    SIZEOF(my_post_controller));
  cinfo->post = (struct jpeg_d_post_controller *) post;
  post->pub.start_pass = start_pass_dpost;
  post->whole_image = NULL;	/* flag for no virtual arrays */
  post->buffer = NULL;		/* flag for no strip buffer */

  /* Create the quantization buffer, if needed */
  if (cinfo->quantize_colors) {
    /* The buffer strip height is max_v_samp_factor, which is typically
     * an efficient number of rows for upsampling to return.
     * (In the presence of output rescaling, we might want to be smarter?)
     */
    post->strip_height = (JDIMENSION) cinfo->max_v_samp_factor;
    /* One-pass color quantization: just make a strip buffer. */
    post->buffer =
      alloc_sarray ((j_common_ptr) cinfo, JPOOL_IMAGE,
		    cinfo->output_width * cinfo->out_color_components,
		    post->strip_height);
  }
}
