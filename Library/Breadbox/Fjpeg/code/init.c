/***********************************************************************
 *
 *	Copyright (c) NewDeal Inc. 2000 -- All Rights Reserved
 *
 * PROJECT:     Fast JPEG Decompression Library
 * FILE:	main.c
 * AUTHOR:	Jens-Michael Gross, July 28, 2000
 *
 * VERSIONS:
 *          00-08-08    JMG     Initial version
 *          00-09-04    JMG     final version for baseline jpeg
 *
 *
 * DESCRIPTION:
 *
 * Init module for the fast jpeg decompression library.
 *
 * This module contains init functions no longer needed after
 * decompression has started.
 * Currently, initialisation code for interlaced jpeg is not implemented.
 *
 * The code holds a lot of comments from the original IJGJPEG source code.
 ***********************************************************************/


#include "fjpeg.h"
#include "intern.h"
#include <geode.h>
#include <library.h>
#include <heap.h>
/*#include <Ansi/stdlib.h>*/
#include <Ansi/string.h>


#define FILL_INPUT_BUFFER fill_input_buffer_i

/*
 * Fill the input buffer --- called whenever buffer is emptied.
 *
 * In typical applications, this should read fresh data into the buffer
 * (ignoring the current state of next_input_byte & bytes_in_buffer),
 * reset the pointer & count to the start of the buffer, and return TRUE
 * indicating that the buffer has been reloaded.  It is not necessary to
 * fill the buffer entirely, only to obtain at least one more byte.
 *
 * There is no such thing as an EOF return.  If the end of the file has been
 * reached, the routine has a choice of ERREXIT() or inserting fake data into
 * the buffer.  In most cases, generating a warning message and inserting a
 * fake EOI marker is the best course of action --- this will allow the
 * decompressor to output however much of the image is there.  However,
 * the resulting error message is misleading if the real problem is an empty
 * input file, so we handle that case specially.
 *
 * In applications that need to be able to suspend compression due to input
 * not being available yet, a FALSE return indicates that no more data can be
 * obtained right now, but more may be forthcoming later.  In this situation,
 * the decompressor will return to its caller (with an indication of the
 * number of scanlines it has read, if any).  The application should resume
 * decompression after it has loaded more data into the input buffer.  Note
 * that there are substantial restrictions on the use of suspension --- see
 * the documentation.
 *
 * When suspending, the decompressor will back up to a convenient restart point
 * (typically the start of the current MCU). next_input_byte & bytes_in_buffer
 * indicate where the restart point will be if the current call returns FALSE.
 * Data beyond this point must be rescanned after resumption, so move it to
 * the front of the buffer rather than discarding it.
 */

Boolean fill_input_buffer_i (j_decompress_ptr cinfo)
{
  size_t nbytes;

  if (cinfo->src.loadProgressDataP) {
      /* get data */
      nbytes = ((pcfm_LoadProgressCallback *)ProcCallFixedOrMovable_pascal)(
		  cinfo->src.loadProgressDataP, cinfo->global_state == DSTATE_INHEADER ? LPCT_PRE_READ : LPCT_READ,
	  cinfo->src.buffer, INPUT_BUF_SIZE,
	  cinfo->src.loadProgressDataP->LPD_callback);
  } else {

	  nbytes = (size_t) fread( (void *) cinfo->src.buffer,
                           (size_t) 1,
                           (size_t) INPUT_BUF_SIZE,
                           cinfo->src.infile);
  }

  if (nbytes <= 0) {
    if (cinfo->src.start_of_file)     /* Treat empty input file as fatal error */
      {
        set_error (cinfo,JERR_INPUT_EMPTY);
        return FALSE;
      };
    WARNMS(cinfo, JWRN_JPEG_EOF);
    /* Insert a fake EOI marker */
    cinfo->src.buffer[0] = (JOCTET) 0xFF;
    cinfo->src.buffer[1] = (JOCTET) JPEG_EOI;
    nbytes = 2;
  }

  cinfo->src.next_input_byte = cinfo->src.buffer;
  cinfo->src.bytes_in_buffer = nbytes;
  cinfo->src.start_of_file = FALSE;

  return TRUE;
}


/*
 * Skip data --- used to skip over a potentially large amount of
 * uninteresting data (such as an APPn marker).
 *
 * Writers of suspendable-input applications must note that skip_input_data
 * is not granted the right to give a suspension return.  If the skip extends
 * beyond the data currently in the buffer, the buffer can be marked empty so
 * that the next read will cause a fill_input_buffer call that can suspend.
 * Arranging for additional bytes to be discarded before reloading the input
 * buffer is the application writer's problem.
 */

void skip_input_data_i (j_decompress_ptr cinfo, long num_bytes)
{
  /* Just a dumb implementation for now.  Could use fseek() except
   * it doesn't work on pipes.  Not clear that being smart is worth
   * any trouble anyway --- large skips are infrequent.
   */
  if (num_bytes > 0) {
    while (num_bytes > (long) cinfo->src.bytes_in_buffer) {
      num_bytes -= (long) cinfo->src.bytes_in_buffer;
      (void) fill_input_buffer_i (cinfo);
      /* note we assume that fill_input_buffer will never return FALSE,
       * so suspension need not be handled.
       */
    }
    cinfo->src.next_input_byte += (size_t) num_bytes;
    cinfo->src.bytes_in_buffer -= (size_t) num_bytes;
  }
}

/*
 * Several decompression processes need to range-limit values to the range
 * 0..MAXJSAMPLE; the input value may fall somewhat outside this range
 * due to noise introduced by quantization, roundoff error, etc.  These
 * processes are inner loops and need to be as fast as possible.  On most
 * machines, particularly CPUs with pipelines or instruction prefetch,
 * a (subscript-check-less) C table lookup
 *		x = sample_range_limit[x];
 * is faster than explicit tests
 *		if (x < 0)  x = 0;
 *		else if (x > MAXJSAMPLE)  x = MAXJSAMPLE;
 * These processes all use a common table prepared by the routine below.
 *
 * For most steps we can mathematically guarantee that the initial value
 * of x is within MAXJSAMPLE+1 of the legal range, so a table running from
 * -(MAXJSAMPLE+1) to 2*MAXJSAMPLE+1 is sufficient.  But for the initial
 * limiting step (just after the IDCT), a wildly out-of-range value is 
 * possible if the input data is corrupt.  To avoid any chance of indexing
 * off the end of memory and getting a bad-pointer trap, we perform the
 * post-IDCT limiting thus:
 *		x = range_limit[x & MASK];
 * where MASK is 2 bits wider than legal sample data, ie 10 bits for 8-bit
 * samples.  Under normal circumstances this is more than enough range and
 * a correct output will be generated; with bogus input data the mask will
 * cause wraparound, and we will safely generate a bogus-but-in-range output.
 * For the post-IDCT step, we want to convert the data from signed to unsigned
 * representation by adding CENTERJSAMPLE at the same time that we limit it.
 * So the post-IDCT limiting table ends up looking like this:
 *   CENTERJSAMPLE,CENTERJSAMPLE+1,...,MAXJSAMPLE,
 *   MAXJSAMPLE (repeat 2*(MAXJSAMPLE+1)-CENTERJSAMPLE times),
 *   0          (repeat 2*(MAXJSAMPLE+1)-CENTERJSAMPLE times),
 *   0,1,...,CENTERJSAMPLE-1
 * Negative inputs select values from the upper half of the table after
 * masking.
 *
 * We can save some space by overlapping the start of the post-IDCT table
 * with the simpler range limiting table.  The post-IDCT table begins at
 * sample_range_limit + CENTERJSAMPLE.
 *
 * Note that the table is allocated in near data space on PCs; it's small
 * enough and used often enough to justify this.
 */

void prepare_range_limit_table (j_decompress_ptr cinfo)
/* Allocate and fill in the sample_range_limit table */
{
  JSAMPLE * table;
  int i;

  table = (JSAMPLE *) smalloc(cinfo,(5 * (MAXJSAMPLE+1) + CENTERJSAMPLE) * sizeof(JSAMPLE));
  table += (MAXJSAMPLE+1);	/* allow negative subscripts of simple table */
  cinfo->sample_range_limit = table;
  /* First segment of "simple" table: limit[x] = 0 for x < 0 */
  jzero_far(table - (MAXJSAMPLE+1), (MAXJSAMPLE+1) * sizeof(JSAMPLE));
  /* Main part of "simple" table: limit[x] = x */
  for (i = 0; i <= MAXJSAMPLE; i++)
    table[i] = (JSAMPLE) i;
  table += CENTERJSAMPLE;	/* Point to where post-IDCT table starts */
  /* End of simple table, rest of first half of post-IDCT table */
  for (i = CENTERJSAMPLE; i < 2*(MAXJSAMPLE+1); i++)
    table[i] = MAXJSAMPLE;
  /* Second half of post-IDCT table */
  jzero_far((void*)(table + (2 * (MAXJSAMPLE+1))),
	    (2 * (MAXJSAMPLE+1) - CENTERJSAMPLE) * sizeof(JSAMPLE));
  memcpy((void*)(table + (4 * (MAXJSAMPLE+1) - CENTERJSAMPLE)),
	 (void*)cinfo->sample_range_limit,
         CENTERJSAMPLE * sizeof(JSAMPLE));
}


/*
 * Initialize tables for YCC->RGB colorspace conversion.
 */

void build_ycc_rgb_table (j_decompress_ptr cinfo)
{
  int i;
  INT32 x;

  cinfo->upsample.Cr_r_tab = (int *) smalloc(cinfo,(MAXJSAMPLE+1) * sizeof(int));
  cinfo->upsample.Cb_b_tab = (int *) smalloc(cinfo,(MAXJSAMPLE+1) * sizeof(int));
  cinfo->upsample.Cr_g_tab = (INT32 *) smalloc(cinfo,(MAXJSAMPLE+1) * sizeof(INT32));
  cinfo->upsample.Cb_g_tab = (INT32 *) smalloc(cinfo,(MAXJSAMPLE+1) * sizeof(INT32));

  for (i = 0, x = -CENTERJSAMPLE; i <= MAXJSAMPLE; i++, x++) {
    /* i is the actual input pixel value, in the range 0..MAXJSAMPLE */
    /* The Cb or Cr value we are thinking of is x = i - CENTERJSAMPLE */
    /* Cr=>R value is nearest int to 1.40200 * x */
    cinfo->upsample.Cr_r_tab[i] = (int)
		    RIGHT_SHIFT(FIX(1.40200) * x + ONE_HALF, SCALEBITS);
    /* Cb=>B value is nearest int to 1.77200 * x */
    cinfo->upsample.Cb_b_tab[i] = (int)
		    RIGHT_SHIFT(FIX(1.77200) * x + ONE_HALF, SCALEBITS);
    /* Cr=>G value is scaled-up -0.71414 * x */
    cinfo->upsample.Cr_g_tab[i] = (- FIX(0.71414)) * x;
    /* Cb=>G value is scaled-up -0.34414 * x */
    /* We also add in ONE_HALF so that need not do it in inner loop */
    cinfo->upsample.Cb_g_tab[i] = (- FIX(0.34414)) * x + ONE_HALF;
  }
}




void jinit_color_deconverter (j_decompress_ptr cinfo)
{

  /* Make sure num_components agrees with jpeg_color_space */
  switch (cinfo->jpeg_color_space) {
  case JCS_GRAYSCALE:
    if (cinfo->num_components != 1){
      set_error(cinfo,JERR_BAD_J_COLORSPACE);
      return;
    }
    break;

  case JCS_RGB:
    if (cinfo->num_components != 3){
      set_error(cinfo,JERR_BAD_J_COLORSPACE);
      return;
    }
    cinfo->decomp_mode = cinfo->decomp_mode & ~DM_YCCRGB;
    break;

  case JCS_YCbCr:
    if (cinfo->num_components != 3){
      set_error(cinfo,JERR_BAD_J_COLORSPACE);
      return;
    }
    cinfo->decomp_mode = cinfo->decomp_mode | DM_YCCRGB;
    build_ycc_rgb_table(cinfo);
    break;
  default:			/* JCS_UNKNOWN can be anything */
    set_error(cinfo,JERR_BAD_J_COLORSPACE);
    return;
  }
}


/*
 * Module initialization routine for upsampling.
 */

void jinit_upsampler (j_decompress_ptr cinfo)
{
  int ci;
  jpeg_component_info * compptr;
  Boolean need_buffer;
  int h_in_group, v_in_group, h_out_group, v_out_group;

  if (cinfo->CCIR601_sampling) {  /* this isn't supported */
    set_error(cinfo,JERR_CCIR601_NOTIMPL);
    return;
  }

  /* Verify we can handle the sampling factors, select per-component methods,
   * and create storage as needed.
   */
  for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
       ci++, compptr++) {
    /* Compute size of an "input group" after IDCT scaling.  This many samples
     * are to be converted to max_h_samp_factor * max_v_samp_factor pixels.
     */
    h_in_group = (compptr->h_samp_factor * compptr->DCT_scaled_size) /
		 cinfo->min_DCT_scaled_size;
    v_in_group = (compptr->v_samp_factor * compptr->DCT_scaled_size) /
		 cinfo->min_DCT_scaled_size;
    h_out_group = cinfo->max_h_samp_factor;
    v_out_group = cinfo->max_v_samp_factor;
    cinfo->upsample.rowgroup_height[ci] = v_in_group; /* save for use later */
    need_buffer = TRUE;
    if (! compptr->component_needed) {
      /* Don't bother to upsample an uninteresting component. */
      cinfo->upsample.methods[ci] = NU_NO_OP;
      need_buffer = FALSE;
    } else if (h_in_group == h_out_group && v_in_group == v_out_group) {
      /* Fullsize components can be processed without any work. */
      cinfo->upsample.methods[ci] = NU_FULL_US;
      need_buffer = FALSE;
    } else if (h_in_group * 2 == h_out_group &&
	       v_in_group == v_out_group) {
      /* Special cases for 2h1v upsampling */
      cinfo->upsample.methods[ci] = NU_21_US;
    } else if (h_in_group * 2 == h_out_group &&
	       v_in_group * 2 == v_out_group) {
      /* Special cases for 2h2v upsampling */
      cinfo->upsample.methods[ci] = NU_22_US;
    } else if ((h_out_group % h_in_group) == 0 &&
	       (v_out_group % v_in_group) == 0) {
      /* Generic integral-factors upsampling method */
      cinfo->upsample.methods[ci] = NU_INT_US;
      cinfo->upsample.h_expand[ci] = (UINT8) (h_out_group / h_in_group);
      cinfo->upsample.v_expand[ci] = (UINT8) (v_out_group / v_in_group);
    } else {
      set_error(cinfo,JERR_FRACT_SAMPLE_NOTIMPL);
      return;
    }
    if (need_buffer) {
/*
      upsample->color_buf[ci] = MCALL4(alloc_sarray, cinfo->mem,
         (j_common_ptr) cinfo, JPOOL_IMAGE,
	 (JDIMENSION) jround_up((long) cinfo->output_width,
				(long) cinfo->max_h_samp_factor),
	 (JDIMENSION) cinfo->max_v_samp_factor);

*/
      cinfo->upsample.color_buf[ci] = smallocarr (  cinfo,
                                                    jround_up( (long) cinfo->image_width,
                                                               (long) cinfo->max_h_samp_factor
                                                             ),
                                                    cinfo->max_v_samp_factor);
    }
  }
}


/*
 * Initialize IDCT manager.
 */

void jinit_inverse_dct (j_decompress_ptr cinfo)
{
  int ci;
  jpeg_component_info *compptr;

  for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
       ci++, compptr++) {
    /* Allocate and pre-zero a multiplier table for each component */
    compptr->dct_table = smalloc(cinfo, sizeof(multiplier_table));
    jzero_far(compptr->dct_table, sizeof(multiplier_table));
    /* Mark multiplier table not yet set up for any method */
    cinfo->idct.cur_method[ci] = -1;
  }
}

/*
 * Module initialization routine for Huffman entropy decoding.
 */

void jinit_huff_decoder (j_decompress_ptr cinfo)
{
  int i;
  /* Mark tables unallocated */
  for (i = 0; i < NUM_HUFF_TBLS; i++) {
    cinfo->entropy.dc_derived_tbls[i] = cinfo->entropy.ac_derived_tbls[i] = NULL;
  }
}

/*
 * Initialize coefficient buffer controller.
 */

void jinit_d_coef_controller (j_decompress_ptr cinfo, Boolean need_full_buffer)
{
  /* Create the coefficient buffer. */
  if (need_full_buffer) {
    /* Allocate a full-image virtual array for each component, */
    /* padded to a multiple of samp_factor DCT blocks in each direction. */
    /* Note we ask for a pre-zeroed array. */
#ifdef D_MULTISCAN_FILES_SUPPORTED
/*
    int ci, access_rows;
    jpeg_component_info *compptr;

    for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
	 ci++, compptr++) {
      access_rows = compptr->v_samp_factor;
      coef->whole_image[ci] = MCALL6(request_virt_barray, cinfo->mem,
         (j_common_ptr) cinfo, JPOOL_IMAGE, TRUE,
	 (JDIMENSION) jround_up((long) compptr->width_in_blocks,
				(long) compptr->h_samp_factor),
	 (JDIMENSION) jround_up((long) compptr->height_in_blocks,
				(long) compptr->v_samp_factor),
	 (JDIMENSION) access_rows);
    }
    MASSIGN(coef->pub.consume_data, consume_data);
    MASSIGN(coef->pub.decompress_data, decompress_data);
    coef->pub.coef_arrays = coef->whole_image; /* link to virtual arrays */
*/
#else
    set_error(cinfo,JERR_NO_PROGRESSIVE);
    return;
#endif
  } else {
    /* We only need a single-MCU buffer. */
    JBLOCKROW buffer;
    int i;

    buffer = (JBLOCKROW) smalloc(cinfo,D_MAX_BLOCKS_IN_MCU * sizeof(JBLOCK));
    for (i = 0; i < D_MAX_BLOCKS_IN_MCU; i++) {
      cinfo->coef.MCU_buffer[i] = buffer + i;
    }
  }
}


/*
 * Initialize main buffer controller.
 */

void jinit_d_main_controller (j_decompress_ptr cinfo, Boolean need_full_buffer)
{
  int ci, rgroup, ngroups;
  jpeg_component_info *compptr;

  if (need_full_buffer)   {      /* shouldn't happen */
    set_error(cinfo,JERR_BAD_BUFFER_MODE);
    return;
  }

  /* Allocate the workspace.
   * ngroups is the number of row groups we need.
   */
  ngroups = cinfo->min_DCT_scaled_size;

  for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
       ci++, compptr++) {
    rgroup = (compptr->v_samp_factor * compptr->DCT_scaled_size) /
      cinfo->min_DCT_scaled_size; /* height of a row group of component */
/*
    main->buffer[ci] = MCALL4(alloc_sarray, cinfo->mem,
                         (j_common_ptr) cinfo, JPOOL_IMAGE,
			 compptr->width_in_blocks * compptr->DCT_scaled_size,
			 (JDIMENSION) (rgroup * ngroups));

*/
    cinfo->main.buffer[ci] = smallocarr( cinfo,
                                           compptr->width_in_blocks
                                         * compptr->DCT_scaled_size,
                                         (rgroup * ngroups)
                                       );
  }
}

/*
 * Convenience routines for allocating quantization and Huffman tables.
 * (Would jutils.c be a more reasonable place to put these?)
 */

JQUANT_TBL * jpeg_alloc_quant_table (j_decompress_ptr cinfo)
{
  JQUANT_TBL *tbl;

  tbl = (JQUANT_TBL *) smalloc(cinfo,sizeof(JQUANT_TBL));
  tbl->sent_table = FALSE;	/* make sure this is false in any new table */

  return tbl;
}


JHUFF_TBL * jpeg_alloc_huff_table (j_decompress_ptr cinfo)
{
  JHUFF_TBL *tbl;

  tbl = (JHUFF_TBL *) smalloc(cinfo,sizeof(JHUFF_TBL));
  tbl->sent_table = FALSE;	/* make sure this is false in any new table */

  return tbl;
}

/*
 * Reset marker processing state to begin a fresh datastream.
 */

void reset_marker_reader (j_decompress_ptr cinfo)
{
  cinfo->comp_info = NULL;		/* until allocated by get_sof */
  cinfo->input_scan_number = 0;		/* no SOS seen yet */
  cinfo->unread_marker = 0;		/* no pending marker */
  cinfo->marker.saw_SOI = FALSE;	/* set internal state too */
  cinfo->marker.saw_SOF = FALSE;
  cinfo->marker.discarded_bytes = 0;
}



/*
 * Reset state to begin a fresh datastream.
 */

void reset_input_controller (j_decompress_ptr cinfo)
{
  cinfo->inputctl.has_multiple_scans = FALSE; /* "unknown" would be better */
  cinfo->inputctl.eoi_reached = FALSE;
  cinfo->inputctl.inheaders = TRUE;
  /* Reset other modules */
  reset_marker_reader(cinfo);
  /* Reset progression state -- would be cleaner if entropy decoder did this */
  cinfo->coef_bits = NULL;
}



/* Called once, when first SOS marker is reached */
void marker_initial_setup (j_decompress_ptr cinfo)
{
  int ci;
  jpeg_component_info *compptr;

  /* Make sure image isn't bigger than I can handle */
  if ((long) cinfo->image_height > (long) JPEG_MAX_DIMENSION ||
      (long) cinfo->image_width > (long) JPEG_MAX_DIMENSION) {
     set_error(cinfo,JERR_IMAGE_TOO_BIG);
     return;
  }

  /* For now, precision must match compiled-in value... */
  if (cinfo->data_precision != BITS_IN_JSAMPLE) {
    set_error(cinfo,JERR_BAD_PRECISION);
    return;
  }

  /* Check that number of components won't exceed internal array sizes */
  if (cinfo->num_components > MAX_COMPONENTS) {
    set_error(cinfo,JERR_COMPONENT_COUNT);
    return;
  }

  /* Compute maximum sampling factors; check factor validity */
  cinfo->max_h_samp_factor = 1;
  cinfo->max_v_samp_factor = 1;
  for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
       ci++, compptr++) {
    if (compptr->h_samp_factor<=0 || compptr->h_samp_factor>MAX_SAMP_FACTOR ||
        compptr->v_samp_factor<=0 || compptr->v_samp_factor>MAX_SAMP_FACTOR) {
      set_error(cinfo,JERR_BAD_SAMPLING);
      return;
    }
    cinfo->max_h_samp_factor = MAX(cinfo->max_h_samp_factor,
				   compptr->h_samp_factor);
    cinfo->max_v_samp_factor = MAX(cinfo->max_v_samp_factor,
				   compptr->v_samp_factor);
  }

  /* We initialize DCT_scaled_size and min_DCT_scaled_size to DCTSIZE.
   * In the full decompressor, this will be overridden by jdmaster.c;
   * but in the transcoder, jdmaster.c is not used, so we must do it here.
   */
  cinfo->min_DCT_scaled_size = DCTSIZE;

  /* Compute dimensions of components */
  for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
       ci++, compptr++) {
    compptr->DCT_scaled_size = DCTSIZE;
    /* Size in DCT blocks */
    compptr->width_in_blocks = (JDIMENSION)
      jdiv_round_up((long) cinfo->image_width * (long) compptr->h_samp_factor,
		    (long) (cinfo->max_h_samp_factor * DCTSIZE));
    compptr->height_in_blocks = (JDIMENSION)
      jdiv_round_up((long) cinfo->image_height * (long) compptr->v_samp_factor,
		    (long) (cinfo->max_v_samp_factor * DCTSIZE));
    /* downsampled_width and downsampled_height will also be overridden by
     * jdmaster.c if we are doing full decompression.  The transcoder library
     * doesn't use these values, but the calling application might.
     */
    /* Size in samples */
    compptr->downsampled_width = (JDIMENSION)
      jdiv_round_up((long) cinfo->image_width * (long) compptr->h_samp_factor,
		    (long) cinfo->max_h_samp_factor);
    compptr->downsampled_height = (JDIMENSION)
      jdiv_round_up((long) cinfo->image_height * (long) compptr->v_samp_factor,
		    (long) cinfo->max_v_samp_factor);
    /* Mark component needed, until color conversion says otherwise */
    compptr->component_needed = TRUE;
    /* Mark no quantization table yet saved for component */
    compptr->quant_table = NULL;
  }

  /* Compute number of fully interleaved MCU rows. */
  cinfo->total_iMCU_rows = (JDIMENSION)
    jdiv_round_up((long) cinfo->image_height,
		  (long) (cinfo->max_v_samp_factor*DCTSIZE));

  /* Decide whether file contains multiple scans */
  if (cinfo->comps_in_scan < cinfo->num_components || cinfo->progressive_mode)
    cinfo->inputctl.has_multiple_scans = TRUE;
  else
    cinfo->inputctl.has_multiple_scans = FALSE;
}



/*
 * Routines to process JPEG markers.
 *
 * Entry condition: JPEG marker itself has been read and its code saved
 *   in cinfo->unread_marker; input restart point is just after the marker.
 *
 * Exit: if return TRUE, have read and processed any parameters, and have
 *   updated the restart point to point after the parameters.
 *   If return FALSE, was forced to suspend before reaching end of
 *   marker parameters; restart point has not been moved.  Same routine
 *   will be called again after application supplies more input data.
 *
 * This approach to suspension assumes that all of a marker's parameters can
 * fit into a single input bufferload.  This should hold for "normal"
 * markers.  Some COM/APPn markers might have large parameter segments,
 * but we use skip_input_data to get past those, and thereby put the problem
 * on the source manager's shoulders.
 *
 * Note that we don't bother to avoid duplicate trace messages if a
 * suspension occurs within marker parameters.  Other side effects
 * require more care.
 */


Boolean get_soi (j_decompress_ptr cinfo)
/* Process an SOI marker */
{
  int i;

  TRACEMS(cinfo, 1, JTRC_SOI);

  if (cinfo->marker.saw_SOI) {
    set_error(cinfo,JERR_SOI_DUPLICATE);
    return FALSE;
  }

  /* Reset all parameters that are defined to be reset by SOI */

  for (i = 0; i < NUM_ARITH_TBLS; i++) {
    cinfo->arith_dc_L[i] = 0;
    cinfo->arith_dc_U[i] = 1;
    cinfo->arith_ac_K[i] = 5;
  }
  cinfo->restart_interval = 0;

  /* Set initial assumptions for colorspace etc */

  cinfo->jpeg_color_space = JCS_UNKNOWN;
  cinfo->CCIR601_sampling = FALSE; /* Assume non-CCIR sampling??? */

  cinfo->saw_JFIF_marker = FALSE;
  cinfo->density_unit = 0;	/* set default JFIF APP0 values */
  cinfo->X_density = 1;
  cinfo->Y_density = 1;
  cinfo->saw_Adobe_marker = FALSE;
  cinfo->Adobe_transform = 0;

  cinfo->marker.saw_SOI = TRUE;

  return TRUE;
}


Boolean get_sof (j_decompress_ptr cinfo, Boolean is_prog, Boolean is_arith)
/* Process a SOFn marker */
{
  INT32 length;
  int c, ci;
  jpeg_component_info * compptr;
  INPUT_VARS(cinfo);

  cinfo->progressive_mode = is_prog;
  cinfo->arith_code = is_arith;

  INPUT_2BYTES(cinfo, length, return FALSE);

  INPUT_BYTE(cinfo, cinfo->data_precision, return FALSE);
  INPUT_2BYTES(cinfo, cinfo->image_height, return FALSE);
  INPUT_2BYTES(cinfo, cinfo->image_width, return FALSE);
  INPUT_BYTE(cinfo, cinfo->num_components, return FALSE);

  length -= 8;

  TRACEMS4(cinfo, 1, JTRC_SOF, cinfo->unread_marker,
	   (int) cinfo->image_width, (int) cinfo->image_height,
	   cinfo->num_components);

  if (cinfo->marker.saw_SOF) {
    set_error(cinfo,JERR_SOF_DUPLICATE);
    return FALSE;
  }
  /* We don't support files in which the image height is initially specified */
  /* as 0 and is later redefined by DNL.  As long as we have to check that,  */
  /* might as well have a general sanity check. */
  if (cinfo->image_height <= 0 || cinfo->image_width <= 0
      || cinfo->num_components <= 0) {
    set_error(cinfo,JERR_EMPTY_IMAGE);
    return FALSE;
  }

  if (length != (cinfo->num_components * 3)) {
    set_error(cinfo,JERR_BAD_LENGTH);
    return FALSE;
  }

  if (cinfo->comp_info == NULL)	/* do only once, even if suspend */
    cinfo->comp_info = (jpeg_component_info *) smalloc( cinfo, cinfo->num_components * sizeof(jpeg_component_info));

  for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
       ci++, compptr++) {
    compptr->component_index = ci;
    INPUT_BYTE(cinfo, compptr->component_id, return FALSE);
    INPUT_BYTE(cinfo, c, return FALSE);
    compptr->h_samp_factor = (c >> 4) & 15;
    compptr->v_samp_factor = (c     ) & 15;
    INPUT_BYTE(cinfo, compptr->quant_tbl_no, return FALSE);

    TRACEMS4(cinfo, 1, JTRC_SOF_COMPONENT,
	     compptr->component_id, compptr->h_samp_factor,
	     compptr->v_samp_factor, compptr->quant_tbl_no);
  }

  cinfo->marker.saw_SOF = TRUE;

  INPUT_SYNC(cinfo);
  return TRUE;
}


Boolean get_sos (j_decompress_ptr cinfo)
/* Process a SOS marker */
{
  INT32 length;
  int i, ci, n, c, cc;
  jpeg_component_info * compptr;
  INPUT_VARS(cinfo);

  if (! cinfo->marker.saw_SOF) {
    set_error(cinfo,JERR_SOS_NO_SOF);
    return FALSE;
  }

  INPUT_2BYTES(cinfo, length, return FALSE);

  INPUT_BYTE(cinfo, n, return FALSE); /* Number of components */

  if (length != (n * 2 + 6) || n < 1 || n > MAX_COMPS_IN_SCAN) {
    set_error(cinfo,JERR_BAD_LENGTH);
    return FALSE;
  }

  TRACEMS1(cinfo, 1, JTRC_SOS, n);

  cinfo->comps_in_scan = n;

  /* Collect the component-spec parameters */

  for (i = 0; i < n; i++) {
    INPUT_BYTE(cinfo, cc, return FALSE);
    INPUT_BYTE(cinfo, c, return FALSE);

    for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
	 ci++, compptr++) {
      if (cc == compptr->component_id)
	goto id_found;
    }
    set_error(cinfo,JERR_BAD_COMPONENT_ID);
    return FALSE;

  id_found:

    cinfo->cur_comp_info[i] = compptr;
    compptr->dc_tbl_no = (c >> 4) & 15;
    compptr->ac_tbl_no = (c     ) & 15;

    TRACEMS3(cinfo, 1, JTRC_SOS_COMPONENT, cc,
	     compptr->dc_tbl_no, compptr->ac_tbl_no);
  }

  /* Collect the additional scan parameters Ss, Se, Ah/Al. */
  INPUT_BYTE(cinfo, c, return FALSE);
  cinfo->Ss = c;
  INPUT_BYTE(cinfo, c, return FALSE);
  cinfo->Se = c;
  INPUT_BYTE(cinfo, c, return FALSE);
  cinfo->Ah = (c >> 4) & 15;
  cinfo->Al = (c     ) & 15;

  TRACEMS4(cinfo, 1, JTRC_SOS_PARAMS, cinfo->Ss, cinfo->Se,
	   cinfo->Ah, cinfo->Al);

  /* Prepare to scan data & restart markers */
  cinfo->marker.next_restart_num = 0;

  /* Count another SOS marker */
  cinfo->input_scan_number++;

  INPUT_SYNC(cinfo);
  return TRUE;
}


Boolean get_app0 (j_decompress_ptr cinfo)
/* Process an APP0 marker */
{
#define JFIF_LEN 14
  INT32 length;
  UINT8 b[JFIF_LEN];
  int buffp;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);
  length -= 2;

  /* See if a JFIF APP0 marker is present */

  if (length >= JFIF_LEN) {
    for (buffp = 0; buffp < JFIF_LEN; buffp++)
      INPUT_BYTE(cinfo, b[buffp], return FALSE);
    length -= JFIF_LEN;

    if (b[0]==0x4A && b[1]==0x46 && b[2]==0x49 && b[3]==0x46 && b[4]==0) {
      /* Found JFIF APP0 marker: check version */
      /* Major version must be 1, anything else signals an incompatible change.
       * We used to treat this as an error, but now it's a nonfatal warning,
       * because some bozo at Hijaak couldn't read the spec.
       * Minor version should be 0..2, but process anyway if newer.
       */
/*
      if (b[5] != 1)
	WARNMS2(cinfo, JWRN_JFIF_MAJOR, b[5], b[6]);
      else if (b[6] > 2)
	TRACEMS2(cinfo, 1, JTRC_JFIF_MINOR, b[5], b[6]);
*/
      /* Save info */
      cinfo->saw_JFIF_marker = TRUE;
      cinfo->density_unit = b[7];
      cinfo->X_density = (b[8] << 8) + b[9];
      cinfo->Y_density = (b[10] << 8) + b[11];
      TRACEMS3(cinfo, 1, JTRC_JFIF,
	       cinfo->X_density, cinfo->Y_density, cinfo->density_unit);
/*
      if (b[12] | b[13])
	TRACEMS2(cinfo, 1, JTRC_JFIF_THUMBNAIL, b[12], b[13]);
      if (length != ((INT32) b[12] * (INT32) b[13] * (INT32) 3))
	TRACEMS1(cinfo, 1, JTRC_JFIF_BADTHUMBNAILSIZE, (int) length);
*/
    } else {
      /* Start of APP0 does not match "JFIF" */
      TRACEMS1(cinfo, 1, JTRC_APP0, (int) length + JFIF_LEN);
    }
  } else {
    /* Too short to be JFIF marker */
    TRACEMS1(cinfo, 1, JTRC_APP0, (int) length);
  }

  INPUT_SYNC(cinfo);
  if (length > 0)		/* skip any remaining data -- could be lots */
    skip_input_data_i(cinfo,(long)length);
    /* skip_input_data_? are all identical */
  return TRUE;
}


Boolean get_app14 (j_decompress_ptr cinfo)
/* Process an APP14 marker */
{
#define ADOBE_LEN 12
  INT32 length;
  UINT8 b[ADOBE_LEN];
  int buffp;
//  unsigned int version, flags0, flags1;
  unsigned int transform;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);
  length -= 2;

  /* See if an Adobe APP14 marker is present */

  if (length >= ADOBE_LEN) {
    for (buffp = 0; buffp < ADOBE_LEN; buffp++)
      INPUT_BYTE(cinfo, b[buffp], return FALSE);
    length -= ADOBE_LEN;

    if (b[0]==0x41 && b[1]==0x64 && b[2]==0x6F && b[3]==0x62 && b[4]==0x65) {
      /* Found Adobe APP14 marker */
//      version = (b[5] << 8) + b[6];
//      flags0 = (b[7] << 8) + b[8];
//      flags1 = (b[9] << 8) + b[10];
      transform = b[11];
      TRACEMS4(cinfo, 1, JTRC_ADOBE, version, flags0, flags1, transform);
      cinfo->saw_Adobe_marker = TRUE;
      cinfo->Adobe_transform = (UINT8) transform;
    } else {
      /* Start of APP14 does not match "Adobe" */
      TRACEMS1(cinfo, 1, JTRC_APP14, (int) length + ADOBE_LEN);
    }
  } else {
    /* Too short to be Adobe marker */
    TRACEMS1(cinfo, 1, JTRC_APP14, (int) length);
  }

  INPUT_SYNC(cinfo);
  if (length > 0)		/* skip any remaining data -- could be lots */
    skip_input_data_i(cinfo,(long) length);

  return TRUE;
}


Boolean get_dac (j_decompress_ptr cinfo)
/* Process a DAC marker */
{
  INT32 length;
  int index, val;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);
  length -= 2;

  while (length > 0) {
    INPUT_BYTE(cinfo, index, return FALSE);
    INPUT_BYTE(cinfo, val, return FALSE);

    length -= 2;

    TRACEMS2(cinfo, 1, JTRC_DAC, index, val);

    if (index < 0 || index >= (2*NUM_ARITH_TBLS)) {
      set_error(cinfo,JERR_DAC_INDEX);
      return FALSE;
    }

    if (index >= NUM_ARITH_TBLS) { /* define AC table */
      cinfo->arith_ac_K[index-NUM_ARITH_TBLS] = (UINT8) val;
    } else {			/* define DC table */
      cinfo->arith_dc_L[index] = (UINT8) (val & 0x0F);
      cinfo->arith_dc_U[index] = (UINT8) (val >> 4);
      if (cinfo->arith_dc_L[index] > cinfo->arith_dc_U[index]) {
        set_error(cinfo,JERR_DAC_VALUE);
        return FALSE;
      }
    }
  }

  INPUT_SYNC(cinfo);
  return TRUE;
}


Boolean get_dht (j_decompress_ptr cinfo)
/* Process a DHT marker */
{
  INT32 length;
  UINT8 bits[17];
  UINT8 huffval[256];
  int i, index, count;
  JHUFF_TBL **htblptr;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);
  length -= 2;

  while (length > 0) {
    INPUT_BYTE(cinfo, index, return FALSE);

    TRACEMS1(cinfo, 1, JTRC_DHT, index);

    bits[0] = 0;
    count = 0;
    for (i = 1; i <= 16; i++) {
      INPUT_BYTE(cinfo, bits[i], return FALSE);
      count += bits[i];
    }

    length -= 1 + 16;

    TRACEMS8(cinfo, 2, JTRC_HUFFBITS,
	     bits[1], bits[2], bits[3], bits[4],
	     bits[5], bits[6], bits[7], bits[8]);
    TRACEMS8(cinfo, 2, JTRC_HUFFBITS,
	     bits[9], bits[10], bits[11], bits[12],
	     bits[13], bits[14], bits[15], bits[16]);

    if (count > 256 || ((INT32) count) > length) {
      set_error(cinfo,JERR_DHT_COUNTS);
      return FALSE;
    }

    for (i = 0; i < count; i++)
      INPUT_BYTE(cinfo, huffval[i], return FALSE);

    length -= count;

    if (index & 0x10) {		/* AC table definition */
      index -= 0x10;
      htblptr = &cinfo->ac_huff_tbl_ptrs[index];
    } else {			/* DC table definition */
      htblptr = &cinfo->dc_huff_tbl_ptrs[index];
    }

    if (index < 0 || index >= NUM_HUFF_TBLS) {
      set_error(cinfo,JERR_DHT_INDEX);
      return FALSE;
    }

    if (*htblptr == NULL)
      *htblptr = jpeg_alloc_huff_table(cinfo);

    memcpy((void *)(*htblptr)->bits, (const void *) bits, sizeof((*htblptr)->bits));
    memcpy((void*)(*htblptr)->huffval, (const void *)huffval, sizeof((*htblptr)->huffval));
  }

  INPUT_SYNC(cinfo);
  return TRUE;
}


Boolean get_dqt (j_decompress_ptr cinfo)
/* Process a DQT marker */
{
  INT32 length;
  int n, i, prec;
  unsigned int tmp;
  JQUANT_TBL *quant_ptr;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);
  length -= 2;

  while (length > 0) {
    INPUT_BYTE(cinfo, n, return FALSE);
    prec = n >> 4;
    n &= 0x0F;

    TRACEMS2(cinfo, 1, JTRC_DQT, n, prec);

    if (n >= NUM_QUANT_TBLS) {
      set_error(cinfo,JERR_DQT_INDEX);
      return FALSE;
    }

    if (cinfo->quant_tbl_ptrs[n] == NULL)
      cinfo->quant_tbl_ptrs[n] = jpeg_alloc_quant_table(cinfo);
    quant_ptr = cinfo->quant_tbl_ptrs[n];

/* since we're accessing the only global constant here, we have to switch dgroup */
    PUSHDS;
    GeodeLoadDGroup(GeodeGetCodeProcessHandle());

    for (i = 0; i < DCTSIZE2; i++) {
      if (prec)
	INPUT_2BYTES(cinfo, tmp, return FALSE);
      else
	INPUT_BYTE(cinfo, tmp, return FALSE);
      /* We convert the zigzag-order table to natural array order. */
      quant_ptr->quantval[jpeg_natural_order[i]] = (UINT16) tmp;
    }

    POPDS;
/* and back to application dgroup */

    for (i = 0; i < DCTSIZE2; i += 8) {
      TRACEMS8(cinfo, 2, JTRC_QUANTVALS,
	       quant_ptr->quantval[i],   quant_ptr->quantval[i+1],
	       quant_ptr->quantval[i+2], quant_ptr->quantval[i+3],
	       quant_ptr->quantval[i+4], quant_ptr->quantval[i+5],
	       quant_ptr->quantval[i+6], quant_ptr->quantval[i+7]);
    }


    length -= DCTSIZE2+1;
    if (prec) length -= DCTSIZE2;
  }

  INPUT_SYNC(cinfo);
  return TRUE;
}


Boolean get_dri (j_decompress_ptr cinfo)
/* Process a DRI marker */
{
  INT32 length;
  unsigned int tmp;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);

  if (length != 4) {
    set_error(cinfo,JERR_BAD_LENGTH);
    return FALSE;
  }

  INPUT_2BYTES(cinfo, tmp, return FALSE);

  TRACEMS1(cinfo, 1, JTRC_DRI, tmp);

  cinfo->restart_interval = tmp;

  INPUT_SYNC(cinfo);
  return TRUE;
}



Boolean skip_variable (j_decompress_ptr cinfo)
/* Skip over an unknown or uninteresting variable-length marker */
{
  INT32 length;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);

  TRACEMS2(cinfo, 1, JTRC_MISC_MARKER, cinfo->unread_marker, (int) length);

  INPUT_SYNC(cinfo);		/* do before skip_input_data */
  skip_input_data_i (cinfo, (long) length - 2L);

  return TRUE;
}



/*
 * Find the next JPEG marker, save it in cinfo->unread_marker.
 * Returns FALSE if had to suspend before reaching a marker;
 * in that case cinfo->unread_marker is unchanged.
 *
 * Note that the result might not be a valid marker code,
 * but it will never be 0 or FF.
 */

Boolean next_marker (j_decompress_ptr cinfo)
{
  int c;
  INPUT_VARS(cinfo);

  for (;;) {
    INPUT_BYTE(cinfo, c, return FALSE);
    /* Skip any non-FF bytes.
     * This may look a bit inefficient, but it will not occur in a valid file.
     * We sync after each discarded byte so that a suspending data source
     * can discard the byte from its buffer.
     */
    while (c != 0xFF) {
      cinfo->marker.discarded_bytes++;
      INPUT_SYNC(cinfo);
      INPUT_BYTE(cinfo, c, return FALSE);
    }
    /* This loop swallows any duplicate FF bytes.  Extra FFs are legal as
     * pad bytes, so don't count them in discarded_bytes.  We assume there
     * will not be so many consecutive FF bytes as to overflow a suspending
     * data source's input buffer.
     */
    do {
      INPUT_BYTE(cinfo, c, return FALSE);
    } while (c == 0xFF);
    if (c != 0)
      break;			/* found a valid marker, exit loop */
    /* Reach here if we found a stuffed-zero data sequence (FF/00).
     * Discard it and loop back to try again.
     */
    cinfo->marker.discarded_bytes += 2;
    INPUT_SYNC(cinfo);
  }

  if (cinfo->marker.discarded_bytes != 0) {
    WARNMS2(cinfo, JWRN_EXTRANEOUS_DATA, cinfo->marker.discarded_bytes, c);
    cinfo->marker.discarded_bytes = 0;
  }

  cinfo->unread_marker = c;

  INPUT_SYNC(cinfo);
  return TRUE;
}


Boolean first_marker (j_decompress_ptr cinfo)
/* Like next_marker, but used to obtain the initial SOI marker. */
/* For this marker, we do not allow preceding garbage or fill; otherwise,
 * we might well scan an entire input file before realizing it ain't JPEG.
 * If an application wants to process non-JFIF files, it must seek to the
 * SOI before calling the JPEG library.
 */
{
  int c, c2;
  INPUT_VARS(cinfo);

  INPUT_BYTE(cinfo, c, return FALSE);
  INPUT_BYTE(cinfo, c2, return FALSE);
  if (c != 0xFF || c2 != (int) M_SOI) {
    set_error(cinfo,JERR_NO_SOI);
    return FALSE;
  }
  cinfo->unread_marker = c2;

  INPUT_SYNC(cinfo);
  return TRUE;
}


/*
 * Read markers until SOS or EOI.
 *
 * Returns same codes as are defined for jpeg_consume_input:
 * JPEG_SUSPENDED, JPEG_REACHED_SOS, or JPEG_REACHED_EOI.
 */

int read_markers (j_decompress_ptr cinfo)
{
  /* Outer loop repeats once for each marker. */
  for (;;) {
    /* Collect the marker proper, unless we already did. */
    /* NB: first_marker() enforces the requirement that SOI appear first. */
    if (cinfo->unread_marker == 0) {
      if (! cinfo->marker.saw_SOI) {
	if (! first_marker(cinfo)) {
          set_error(cinfo,JERR_CANT_SUSPEND);
	  return JPEG_REACHED_EOI;
        }
      } else {
	if (! next_marker(cinfo)) {
          set_error(cinfo,JERR_CANT_SUSPEND);
	  return JPEG_REACHED_EOI;
        }
      }
    }
    /* At this point cinfo->unread_marker contains the marker code and the
     * input point is just past the marker proper, but before any parameters.
     * A suspension will cause us to return with this state still true.
     */
    switch (cinfo->unread_marker) {
    case M_SOI:
      if (! get_soi(cinfo)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
	return JPEG_REACHED_EOI;
      }
      break;

    case M_SOF0:		/* Baseline */
    case M_SOF1:		/* Extended sequential, Huffman */
      if (! get_sof(cinfo, FALSE, FALSE)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
        return JPEG_REACHED_EOI;
      }
      break;

    case M_SOF2:		/* Progressive, Huffman */
      if (! get_sof(cinfo, TRUE, FALSE)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
        return JPEG_REACHED_EOI;
      }
      break;

    case M_SOF9:		/* Extended sequential, arithmetic */
      if (! get_sof(cinfo, FALSE, TRUE)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
        return JPEG_REACHED_EOI;
      }
      break;

    case M_SOF10:		/* Progressive, arithmetic */
      if (! get_sof(cinfo, TRUE, TRUE)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
        return JPEG_REACHED_EOI;
      }
      break;

    /* Currently unsupported SOFn types */
    case M_SOF3:		/* Lossless, Huffman */
    case M_SOF5:		/* Differential sequential, Huffman */
    case M_SOF6:		/* Differential progressive, Huffman */
    case M_SOF7:		/* Differential lossless, Huffman */
    case M_JPG:			/* Reserved for JPEG extensions */
    case M_SOF11:		/* Lossless, arithmetic */
    case M_SOF13:		/* Differential sequential, arithmetic */
    case M_SOF14:		/* Differential progressive, arithmetic */
    case M_SOF15:		/* Differential lossless, arithmetic */
      set_error(cinfo,JERR_SOF_UNSUPPORTED);
        return JPEG_REACHED_EOI;
        /*break;*/
    case M_SOS:
      if (! get_sos(cinfo)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
        return JPEG_REACHED_EOI;
      }
      cinfo->unread_marker = 0;	/* processed the marker */
      return JPEG_REACHED_SOS;

    case M_EOI:
      TRACEMS(cinfo, 1, JTRC_EOI);
      cinfo->unread_marker = 0;	/* processed the marker */
      return JPEG_REACHED_EOI;

    case M_DAC:
      if (! get_dac(cinfo)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
        return JPEG_REACHED_EOI;
      }
      break;

    case M_DHT:
      if (! get_dht(cinfo)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
        return JPEG_REACHED_EOI;
      }
      break;

    case M_DQT:
      if (! get_dqt(cinfo)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
        return JPEG_REACHED_EOI;
      }
      break;

    case M_DRI:
      if (! get_dri(cinfo)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
        return JPEG_REACHED_EOI;
      }
      break;

    case M_APP0:
      if (! get_app0(cinfo)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
        return JPEG_REACHED_EOI;
      }
      break;

    case M_APP14:
       if (! get_app14(cinfo)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
        return JPEG_REACHED_EOI;
      }
      break;


    case M_APP1:
    case M_APP2:
    case M_APP3:
    case M_APP4:
    case M_APP5:
    case M_APP6:
    case M_APP7:
    case M_APP8:
    case M_APP9:
    case M_APP10:
    case M_APP11:
    case M_APP12:
    case M_APP13:
    case M_APP15:
    case M_COM:
      skip_variable(cinfo);
      break;

    case M_RST0:		/* these are all parameterless */
    case M_RST1:
    case M_RST2:
    case M_RST3:
    case M_RST4:
    case M_RST5:
    case M_RST6:
    case M_RST7:
    case M_TEM:
      TRACEMS1(cinfo, 1, JTRC_PARMLESS_MARKER, cinfo->unread_marker);
      break;

    case M_DNL:			/* Ignore DNL ... perhaps the wrong thing */
      if (! skip_variable(cinfo)) {
        set_error(cinfo,JERR_CANT_SUSPEND);
        return JPEG_REACHED_EOI;
      }
      break;

    default:			/* must be DHP, EXP, JPGn, or RESn */
      /* For now, we treat the reserved markers as fatal errors since they are
       * likely to be used to signal incompatible JPEG Part 3 extensions.
       * Once the JPEG 3 version-number marker is well defined, this code
       * ought to change!
       */
      set_error(cinfo,JERR_UNKNOWN_MARKER);
      return JPEG_REACHED_EOI;
      /*break;*/
    }
    /* Successfully processed marker, so reset state variable */
    cinfo->unread_marker = 0;
  } /* end loop */
}




/*
 * Read JPEG markers before, between, or after compressed-data scans.
 * Change state as necessary when a new scan is reached.
 * Return value is JPEG_SUSPENDED, JPEG_REACHED_SOS, or JPEG_REACHED_EOI.
 *
 * The consume_input method pointer points either here or to the
 * coefficient controller's consume_data routine, depending on whether
 * we are reading a compressed data segment or inter-segment markers.
 */

int consume_markers (j_decompress_ptr cinfo)
{
  int val;

  if (cinfo->inputctl.eoi_reached) /* After hitting EOI, read no further */
    return JPEG_REACHED_EOI;

  val = read_markers(cinfo);

  switch (val) {
  case JPEG_REACHED_SOS:	/* Found SOS */
    if (cinfo->inputctl.inheaders) {	/* 1st SOS */
      marker_initial_setup(cinfo);
      cinfo->inputctl.inheaders = FALSE;
      /* Note: start_input_pass must be called by jdmaster.c
       * before any more input can be consumed.  jdapi.c is
       * responsible for enforcing this sequencing.
       */
    } else {			/* 2nd or later SOS marker */
      if (! cinfo->inputctl.has_multiple_scans) {
        set_error(cinfo,JERR_EOI_EXPECTED); /* Oops, I wasn't expecting this! */
        return JPEG_REACHED_EOI;
      }
      start_input_pass(cinfo);
    }
    break;
  case JPEG_REACHED_EOI:	/* Found EOI */
    cinfo->inputctl.eoi_reached = TRUE;
    if (cinfo->inputctl.inheaders) {	/* Tables-only datastream, apparently */
      if (cinfo->marker.saw_SOF) {
        set_error(cinfo,JERR_SOF_NO_SOS);
        return JPEG_REACHED_EOI;
      }
    } else {
      /* Prevent infinite loop in coef ctlr's decompress_data routine
       * if user set output_scan_number larger than number of scans.
       */
      if (cinfo->output_scan_number > cinfo->input_scan_number)
	cinfo->output_scan_number = cinfo->input_scan_number;
    }
    break;
  }
  return val;
}


void per_scan_setup (j_decompress_ptr cinfo)
/* Do computations that are needed before processing a JPEG scan */
/* cinfo->comps_in_scan and cinfo->cur_comp_info[] were set from SOS marker */
{
  int ci, mcublks, tmp;
  jpeg_component_info *compptr;

  if (cinfo->comps_in_scan == 1) {

    /* Noninterleaved (single-component) scan */
    compptr = cinfo->cur_comp_info[0];
    
    /* Overall image size in MCUs */
    cinfo->MCUs_per_row = compptr->width_in_blocks;
    cinfo->MCU_rows_in_scan = compptr->height_in_blocks;
    
    /* For noninterleaved scan, always one block per MCU */
    compptr->MCU_width = 1;
    compptr->MCU_height = 1;
    compptr->MCU_blocks = 1;
    compptr->MCU_sample_width = compptr->DCT_scaled_size;
    compptr->last_col_width = 1;
    /* For noninterleaved scans, it is convenient to define last_row_height
     * as the number of block rows present in the last iMCU row.
     */
    tmp = (int) (compptr->height_in_blocks % compptr->v_samp_factor);
    if (tmp == 0) tmp = compptr->v_samp_factor;
    compptr->last_row_height = tmp;
    
    /* Prepare array describing MCU composition */
    cinfo->blocks_in_MCU = 1;
    cinfo->MCU_membership[0] = 0;

  } else {

    /* Interleaved (multi-component) scan */
    if (cinfo->comps_in_scan <= 0 || cinfo->comps_in_scan > MAX_COMPS_IN_SCAN) {
      set_error(cinfo,JERR_COMPONENT_COUNT);
      return;
    }

    /* Overall image size in MCUs */
    cinfo->MCUs_per_row = (JDIMENSION)
      jdiv_round_up((long) cinfo->image_width,
		    (long) (cinfo->max_h_samp_factor*DCTSIZE));
    cinfo->MCU_rows_in_scan = (JDIMENSION)
      jdiv_round_up((long) cinfo->image_height,
		    (long) (cinfo->max_v_samp_factor*DCTSIZE));

    cinfo->blocks_in_MCU = 0;

    for (ci = 0; ci < cinfo->comps_in_scan; ci++) {
      compptr = cinfo->cur_comp_info[ci];
      /* Sampling factors give # of blocks of component in each MCU */
      compptr->MCU_width = compptr->h_samp_factor;
      compptr->MCU_height = compptr->v_samp_factor;
      compptr->MCU_blocks = compptr->MCU_width * compptr->MCU_height;
      compptr->MCU_sample_width = compptr->MCU_width * compptr->DCT_scaled_size;
      /* Figure number of non-dummy blocks in last MCU column & row */
      tmp = (int) (compptr->width_in_blocks % compptr->MCU_width);
      if (tmp == 0) tmp = compptr->MCU_width;
      compptr->last_col_width = tmp;
      tmp = (int) (compptr->height_in_blocks % compptr->MCU_height);
      if (tmp == 0) tmp = compptr->MCU_height;
      compptr->last_row_height = tmp;
      /* Prepare array describing MCU composition */
      mcublks = compptr->MCU_blocks;
      if (cinfo->blocks_in_MCU + mcublks > D_MAX_BLOCKS_IN_MCU) {
        set_error(cinfo,JERR_BAD_MCU_SIZE);
        return;
      }
      while (mcublks-- > 0) {
	cinfo->MCU_membership[cinfo->blocks_in_MCU++] = ci;
      }
    }

  }
}




/*
 * Save away a copy of the Q-table referenced by each component present
 * in the current scan, unless already saved during a prior scan.
 *
 * In a multiple-scan JPEG file, the encoder could assign different components
 * the same Q-table slot number, but change table definitions between scans
 * so that each component uses a different Q-table.  (The IJG encoder is not
 * currently capable of doing this, but other encoders might.)  Since we want
 * to be able to dequantize all the components at the end of the file, this
 * means that we have to save away the table actually used for each component.
 * We do this by copying the table at the start of the first scan containing
 * the component.
 * The JPEG spec prohibits the encoder from changing the contents of a Q-table
 * slot between scans of a component using that slot.  If the encoder does so
 * anyway, this decoder will simply use the Q-table values that were current
 * at the start of the first scan for the component.
 *
 * The decompressor output side looks only at the saved quant tables,
 * not at the current Q-table slots.
 */

void latch_quant_tables (j_decompress_ptr cinfo)
{
  int ci, qtblno;
  jpeg_component_info *compptr;
  JQUANT_TBL * qtbl;

  for (ci = 0; ci < cinfo->comps_in_scan; ci++) {
    compptr = cinfo->cur_comp_info[ci];
    /* No work if we already saved Q-table for this component */
    if (compptr->quant_table != NULL)
      continue;
    /* Make sure specified quantization table is present */
    qtblno = compptr->quant_tbl_no;
    if (qtblno < 0 || qtblno >= NUM_QUANT_TBLS ||
	cinfo->quant_tbl_ptrs[qtblno] == NULL) {
      set_error (cinfo, JERR_NO_QUANT_TABLE);
      return;
    }
    /* OK, save away the quantization table */
    qtbl = (JQUANT_TBL *) smalloc(cinfo, sizeof(JQUANT_TBL));
    memcpy(qtbl, cinfo->quant_tbl_ptrs[qtblno], sizeof(JQUANT_TBL));
    compptr->quant_table = qtbl;
  }
}


/*
 * Compute the derived values for a Huffman table.
 * Note this is also used by jdphuff.c.
 */

void jpeg_make_d_derived_tbl ( j_decompress_ptr cinfo, JHUFF_TBL * htbl,
			       d_derived_tbl ** pdtbl)
{
  d_derived_tbl *dtbl;
  int p, i, l, si;
  int lookbits, ctr;
  char huffsize[257];
  unsigned int huffcode[257];
  unsigned int code;

  /* Allocate a workspace if we haven't already done so. */
  if (*pdtbl == NULL)
    *pdtbl = (d_derived_tbl *) smalloc(cinfo, sizeof(d_derived_tbl));
  dtbl = *pdtbl;
  dtbl->pub = htbl;		/* fill in back link */

  /* Figure C.1: make table of Huffman code length for each symbol */
  /* Note that this is in code-length order. */

  p = 0;
  for (l = 1; l <= 16; l++) {
    for (i = 1; i <= (int) htbl->bits[l]; i++)
      huffsize[p++] = (char) l;
  }
  huffsize[p] = 0;

  /* Figure C.2: generate the codes themselves */
  /* Note that this is in code-length order. */
  
  code = 0;
  si = huffsize[0];
  p = 0;
  while (huffsize[p]) {
    while (((int) huffsize[p]) == si) {
      huffcode[p++] = code;
      code++;
    }
    code <<= 1;
    si++;
  }

  /* Figure F.15: generate decoding tables for bit-sequential decoding */

  p = 0;
  for (l = 1; l <= 16; l++) {
    if (htbl->bits[l]) {
      dtbl->valptr[l] = p; /* huffval[] index of 1st symbol of code length l */
      dtbl->mincode[l] = huffcode[p]; /* minimum code of length l */
      p += htbl->bits[l];
      dtbl->maxcode[l] = huffcode[p-1]; /* maximum code of length l */
    } else {
      dtbl->maxcode[l] = -1;	/* -1 if no codes of this length */
    }
  }
  dtbl->maxcode[17] = 0xFFFFFL; /* ensures jpeg_huff_decode terminates */

  /* Compute lookahead tables to speed up decoding.
   * First we set all the table entries to 0, indicating "too long";
   * then we iterate through the Huffman codes that are short enough and
   * fill in all the entries that correspond to bit sequences starting
   * with that code.
   */

  jzero_far(dtbl->look_nbits, sizeof(dtbl->look_nbits));

  p = 0;
  for (l = 1; l <= HUFF_LOOKAHEAD; l++) {
    for (i = 1; i <= (int) htbl->bits[l]; i++, p++) {
      /* l = current code's length, p = its index in huffcode[] & huffval[]. */
      /* Generate left-justified code followed by all possible bit sequences */
      lookbits = huffcode[p] << (HUFF_LOOKAHEAD-l);
      for (ctr = 1 << (HUFF_LOOKAHEAD-l); ctr > 0; ctr--) {
	dtbl->look_nbits[lookbits] = l;
	dtbl->look_sym[lookbits] = htbl->huffval[p];
	lookbits++;
      }
    }
  }
}


/*
 * Initialize for a Huffman-compressed scan.
 */

void start_pass_huff_decoder (j_decompress_ptr cinfo)
{
  int ci, dctbl, actbl;
  jpeg_component_info * compptr;

  /* Check that the scan parameters Ss, Se, Ah/Al are OK for sequential JPEG.
   * This ought to be an error condition, but we make it a warning because
   * there are some baseline files out there with all zeroes in these bytes.
   */
  if (cinfo->Ss != 0 || cinfo->Se != DCTSIZE2-1 ||
      cinfo->Ah != 0 || cinfo->Al != 0)
    WARNMS(cinfo, JWRN_NOT_SEQUENTIAL);


  for (ci = 0; ci < cinfo->comps_in_scan; ci++) {
    compptr = cinfo->cur_comp_info[ci];
    dctbl = compptr->dc_tbl_no;
    actbl = compptr->ac_tbl_no;
    /* Make sure requested tables are present */
    if (dctbl < 0 || dctbl >= NUM_HUFF_TBLS ||
	cinfo->dc_huff_tbl_ptrs[dctbl] == NULL) {
      set_error(cinfo, JERR_NO_HUFF_TABLE);
      return;
    }
    if (actbl < 0 || actbl >= NUM_HUFF_TBLS ||
	cinfo->ac_huff_tbl_ptrs[actbl] == NULL) {
      set_error(cinfo, JERR_NO_HUFF_TABLE);
      return;
    }
    /* Compute derived values for Huffman tables */
    /* We may do this more than once for a table, but it's not expensive */
    jpeg_make_d_derived_tbl(cinfo, cinfo->dc_huff_tbl_ptrs[dctbl],
			    & cinfo->entropy.dc_derived_tbls[dctbl]);
    jpeg_make_d_derived_tbl(cinfo, cinfo->ac_huff_tbl_ptrs[actbl],
			    & cinfo->entropy.ac_derived_tbls[actbl]);
    /* Initialize DC predictions to 0 */
    cinfo->entropy.saved.last_dc_val[ci] = 0;
  }

  /* Initialize bitread state variables */
  cinfo->entropy.bitstate.bits_left = 0;
  cinfo->entropy.bitstate.get_buffer = 0; /* unnecessary, but keeps Purify quiet */
  cinfo->entropy.bitstate.printed_eod = FALSE;

  /* Initialize restart counter */
  cinfo->entropy.restarts_to_go = cinfo->restart_interval;
}

void start_iMCU_row (j_decompress_ptr cinfo)
/* Reset within-iMCU-row counters for a new row (input side) */
{
  /* In an interleaved scan, an MCU row is the same as an iMCU row.
   * In a noninterleaved scan, an iMCU row has v_samp_factor MCU rows.
   * But at the bottom of the image, process only what's left.
   */
  if (cinfo->comps_in_scan > 1) {
    cinfo->coef.MCU_rows_per_iMCU_row = 1;
  } else {
    if (cinfo->input_iMCU_row < (cinfo->total_iMCU_rows-1))
      cinfo->coef.MCU_rows_per_iMCU_row = cinfo->cur_comp_info[0]->v_samp_factor;
    else
      cinfo->coef.MCU_rows_per_iMCU_row = cinfo->cur_comp_info[0]->last_row_height;
  }

  cinfo->coef.MCU_ctr = 0;
  cinfo->coef.MCU_vert_offset = 0;
}


/*
 * Initialize for an input processing pass.
 */

void start_input_pass_jdcoefct (j_decompress_ptr cinfo)
{
  cinfo->input_iMCU_row = 0;
  start_iMCU_row(cinfo);
}





/*
 * Master selection of decompression modules.
 * This is done once at jpeg_start_decompress time.  We determine
 * which modules will be used and give them appropriate initialization calls.
 * We also initialize the decompressor input side to begin consuming data.
 *
 * Since jpeg_read_header has finished, we know what is in the SOF
 * and (first) SOS markers.  We also have all the application parameter
 * settings.
 */

void master_selection (j_decompress_ptr cinfo)
{
  Boolean use_c_buffer;
  long samplesperrow;
  JDIMENSION jd_samplesperrow;

  /* Initialize dimensions and other stuff */
  cinfo->rec_outbuf_height = 1;   // always, since no merged upsampling
  prepare_range_limit_table(cinfo);

  /* Width of an output scanline must be representable as JDIMENSION. */
  samplesperrow = (long) cinfo->image_width * (long) cinfo->num_components;
  jd_samplesperrow = (JDIMENSION) samplesperrow;
  if ((long) jd_samplesperrow != samplesperrow){
    set_error(cinfo,JERR_WIDTH_OVERFLOW);
    return;
  }
  /* Initialize my private state */
  cinfo->master.pass_number = 0;

  /* Post-processing: in particular, color conversion first */
  jinit_color_deconverter(cinfo);
  jinit_upsampler(cinfo);
  /* Inverse DCT */
  jinit_inverse_dct(cinfo);
  /* Entropy decoding: either Huffman or arithmetic coding. */
  if (cinfo->arith_code) {
    set_error(cinfo,JERR_ARITH_NOTIMPL);
    return;
  } else {
    if (cinfo->progressive_mode) {
#ifdef D_PROGRESSIVE_SUPPORTED
      jinit_phuff_decoder(cinfo);
#else
      set_error(cinfo,JERR_NO_PROGRESSIVE);
      return;
#endif
    } else
      jinit_huff_decoder(cinfo);
  }

  /* Initialize principal buffer controllers. */
  use_c_buffer = cinfo->inputctl.has_multiple_scans || cinfo->buffered_image;
  jinit_d_coef_controller(cinfo, use_c_buffer);

  jinit_d_main_controller(cinfo, FALSE /* never need full buffer here */);

  /* Initialize input side of decompressor to consume first scan. */
  start_input_pass(cinfo);

}

#if PROGRESS_DISPLAY
void _pascal fjpeg_init_loadProgress(j_decompress_ptr cinfo,
		       LoadProgressData *loadProgressDataP)
{
    cinfo->src.loadProgressDataP = loadProgressDataP;
}
#endif
