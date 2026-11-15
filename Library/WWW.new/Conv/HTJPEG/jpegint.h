/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 * PROJECT:	  PC GEOS
 * MODULE:	  
 * FILE:	  jpegint.h
 *
 * AUTHOR:  	  Joon Song: Oct 29, 1995
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Joon	10/29/95   	Initial version
 *
 * DESCRIPTION:
 *	
 *
 *
 * 	$Id: jpegint.h,v 1.1.11.8 97/11/11 10:30:28 joon Exp $
 *
 ***********************************************************************/

#ifndef _JPEGINT_H_
#define _JPEGINT_H_

#endif /* _JPEGINT_H_ */
/*
 * jpegint.h
 *
 * Copyright (C) 1991-1995, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file provides common declarations for the various JPEG modules.
 * These declarations are considered internal to the JPEG library; most
 * applications using the library shouldn't need to include this file.
 */


/* Declarations for decompression */

/* Values of global_state field (jdapi.c has some dependencies on ordering!) */
#define DSTATE_START	200	/* after create_decompress */
#define DSTATE_INHEADER	201	/* reading header markers, no SOS yet */
#define DSTATE_READY	202	/* found SOS, ready for start_decompress */
#define DSTATE_PRELOAD	203	/* reading multiscan file in start_decompress*/
#define DSTATE_PRESCAN	204	/* performing dummy pass for 2-pass quant */
#define DSTATE_SCANNING	205	/* start_decompress done, read_scanlines OK */
#define DSTATE_STOPPING	210	/* looking for EOI in jpeg_finish_decompress */


/* Miscellaneous useful macros */

#undef MAX
#define MAX(a,b)	((a) > (b) ? (a) : (b))
#undef MIN
#define MIN(a,b)	((a) < (b) ? (a) : (b))


/* We assume that right shift corresponds to signed division by 2 with
 * rounding towards minus infinity.  This is correct for typical "arithmetic
 * shift" instructions that shift in copies of the sign bit.  But some
 * C compilers implement >> with an unsigned shift.  For these machines you
 * must define RIGHT_SHIFT_IS_UNSIGNED.
 * RIGHT_SHIFT provides a proper signed right shift of an INT32 quantity.
 * It is only applied with constant shift counts.  SHIFT_TEMPS must be
 * included in the variables of any routine using RIGHT_SHIFT.
 */

#define RIGHT_SHIFT(x,shft)	((x) >> (shft))


/* Decompression module initialization routines */
EXTERN void jinit_master_decompress(j_decompress_ptr cinfo);
EXTERN void jinit_d_main_controller(j_decompress_ptr cinfo);
EXTERN void jinit_d_coef_controller(j_decompress_ptr cinfo);
EXTERN void jinit_d_post_controller(j_decompress_ptr cinfo);
EXTERN void jinit_input_controller(j_decompress_ptr cinfo);
EXTERN void jinit_marker_reader(j_decompress_ptr cinfo);
EXTERN void jinit_huff_decoder(j_decompress_ptr cinfo);
EXTERN void jinit_inverse_dct(j_decompress_ptr cinfo);
EXTERN void jinit_upsampler(j_decompress_ptr cinfo);
EXTERN void jinit_color_deconverter(j_decompress_ptr cinfo);
EXTERN void jinit_1pass_quantizer(j_decompress_ptr cinfo);

/* Memory manager initialization */
EXTERN void jinit_memory_mgr(j_common_ptr cinfo);

/* Utility routines in jutils.c */
EXTERN long jdiv_round_up(long a, long b);
EXTERN long jround_up(long a, long b);
EXTERN void jcopy_sample_rows(JSAMPARRAY input_array, int source_row,
			      JSAMPARRAY output_array, int dest_row,
			      int num_rows, JDIMENSION num_cols);
EXTERN void jcopy_block_row(JBLOCKROW input_row, JBLOCKROW output_row,
			    JDIMENSION num_blocks);
EXTERN void jzero_far(void * target, size_t bytestozero);

/* Constant tables in jutils.c */
extern const int jpeg_zigzag_order[]; /* natural coef order to zigzag order */
extern const int jpeg_natural_order[]; /* zigzag coef order to natural order */
