/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		jmethoddef.c

AUTHOR:		Joon Song, Oct 18, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/18/95   	Initial version.

DESCRIPTION:
	

	$Id: jmethoddef.c,v 1.1.11.14 97/11/11 20:47:38 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#define JPEG_INTERNALS
#include <jinclude.h>
#include <jpeglib.h>

#ifdef __HIGHC__
#pragma Code ("JpegFixedCodeC");
#endif
#ifdef __BORLANDC__
#pragma codeseg JpegFixedCodeC
#endif

/* jdcoefct.c */

EXTERN int METHODDEF_dummy_consume_data (j_decompress_ptr cinfo);

int dummy_consume_data (j_decompress_ptr cinfo)
{
    return METHODDEF_dummy_consume_data (cinfo);
}


/* jdcolor.c */

EXTERN void METHODDEF_ycc_rgb_convert (j_decompress_ptr cinfo, JSAMPIMAGE input_buf, JDIMENSION input_row, JSAMPARRAY output_buf, int num_rows);

void ycc_rgb_convert (j_decompress_ptr cinfo, JSAMPIMAGE input_buf,
		      JDIMENSION input_row, JSAMPARRAY output_buf,
		      int num_rows)
{
    METHODDEF_ycc_rgb_convert (cinfo, input_buf, input_row, output_buf,
			       num_rows);
}

EXTERN void METHODDEF_null_convert (j_decompress_ptr cinfo, JSAMPIMAGE input_buf, JDIMENSION input_row, JSAMPARRAY output_buf, int num_rows);

void null_convert (j_decompress_ptr cinfo, JSAMPIMAGE input_buf,
		   JDIMENSION input_row, JSAMPARRAY output_buf, int num_rows)
{
    METHODDEF_null_convert (cinfo, input_buf, input_row, output_buf, num_rows);
}

EXTERN void METHODDEF_grayscale_convert (j_decompress_ptr cinfo, JSAMPIMAGE input_buf, JDIMENSION input_row, JSAMPARRAY output_buf, int num_rows);

void grayscale_convert (j_decompress_ptr cinfo, JSAMPIMAGE input_buf,
			JDIMENSION input_row, JSAMPARRAY output_buf,
			int num_rows)
{
    METHODDEF_grayscale_convert (cinfo, input_buf, input_row, output_buf,
				 num_rows);
}

EXTERN void METHODDEF_ycck_cmyk_convert (j_decompress_ptr cinfo, JSAMPIMAGE input_buf, JDIMENSION input_row, JSAMPARRAY output_buf, int num_rows);

void ycck_cmyk_convert (j_decompress_ptr cinfo, JSAMPIMAGE input_buf,
			JDIMENSION input_row, JSAMPARRAY output_buf,
			int num_rows)
{
    METHODDEF_ycck_cmyk_convert (cinfo, input_buf, input_row, output_buf,
				 num_rows);
}

EXTERN void METHODDEF_start_pass_dcolor (j_decompress_ptr cinfo);

void start_pass_dcolor (j_decompress_ptr cinfo)
{
    METHODDEF_start_pass_dcolor (cinfo);
}


/* jddctmgr.c */

EXTERN void METHODDEF_start_pass (j_decompress_ptr cinfo);

void start_pass (j_decompress_ptr cinfo)
{
    METHODDEF_start_pass (cinfo);
}


/* jdhuff.c */

EXTERN void METHODDEF_start_pass_huff_decoder (j_decompress_ptr cinfo);

void start_pass_huff_decoder (j_decompress_ptr cinfo)
{
    METHODDEF_start_pass_huff_decoder (cinfo);
}

EXTERN boolean METHODDEF_decode_mcu (j_decompress_ptr cinfo, JBLOCKROW *MCU_data);

boolean decode_mcu (j_decompress_ptr cinfo, JBLOCKROW *MCU_data)
{
    return METHODDEF_decode_mcu (cinfo, MCU_data);
}


/* jdinput.c */

EXTERN void METHODDEF_start_input_pass (j_decompress_ptr cinfo);

void start_input_pass (j_decompress_ptr cinfo)
{
    METHODDEF_start_input_pass (cinfo);
}

EXTERN void METHODDEF_finish_input_pass (j_decompress_ptr cinfo);

void finish_input_pass (j_decompress_ptr cinfo)
{
    METHODDEF_finish_input_pass (cinfo);
}

EXTERN int METHODDEF_consume_markers (j_decompress_ptr cinfo);

int consume_markers (j_decompress_ptr cinfo)
{
    return METHODDEF_consume_markers (cinfo);
}

EXTERN void METHODDEF_reset_input_controller (j_decompress_ptr cinfo);

void reset_input_controller (j_decompress_ptr cinfo)
{
    METHODDEF_reset_input_controller (cinfo);
}


/* jdmainct.c */

EXTERN void METHODDEF_start_pass_main (j_decompress_ptr cinfo, J_BUF_MODE pass_mode);

void start_pass_main (j_decompress_ptr cinfo, J_BUF_MODE pass_mode)
{
    METHODDEF_start_pass_main (cinfo, pass_mode);
}

EXTERN void METHODDEF_process_data_simple_main (j_decompress_ptr cinfo, JSAMPARRAY output_buf, JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail);

void process_data_simple_main (j_decompress_ptr cinfo, JSAMPARRAY output_buf,
			       JDIMENSION *out_row_ctr,
			       JDIMENSION out_rows_avail)
{
    METHODDEF_process_data_simple_main (cinfo, output_buf, out_row_ctr,
					out_rows_avail);
}

EXTERN void METHODDEF_process_data_context_main (j_decompress_ptr cinfo, JSAMPARRAY output_buf,	JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail);

void process_data_context_main (j_decompress_ptr cinfo, JSAMPARRAY output_buf,
				JDIMENSION *out_row_ctr,
				JDIMENSION out_rows_avail)
{
    METHODDEF_process_data_context_main (cinfo, output_buf, out_row_ctr,
					 out_rows_avail);
}


/* jdmarker.c */

EXTERN boolean METHODDEF_get_app0 (j_decompress_ptr cinfo);

boolean get_app0 (j_decompress_ptr cinfo)
{
    return METHODDEF_get_app0 (cinfo);
}

EXTERN boolean METHODDEF_get_app14 (j_decompress_ptr cinfo);

boolean get_app14 (j_decompress_ptr cinfo)
{
    return METHODDEF_get_app14 (cinfo);
}

EXTERN boolean METHODDEF_skip_variable (j_decompress_ptr cinfo);

boolean skip_variable (j_decompress_ptr cinfo)
{
    return METHODDEF_skip_variable (cinfo);
}


/* jdmaster.c */

EXTERN void METHODDEF_prepare_for_output_pass (j_decompress_ptr cinfo);

void prepare_for_output_pass (j_decompress_ptr cinfo)
{
    METHODDEF_prepare_for_output_pass (cinfo);
}

EXTERN void METHODDEF_finish_output_pass (j_decompress_ptr cinfo);

void finish_output_pass (j_decompress_ptr cinfo)
{
    METHODDEF_finish_output_pass (cinfo);
}


/* jdpostct.c */

EXTERN void METHODDEF_start_pass_dpost (j_decompress_ptr cinfo, J_BUF_MODE pass_mode);

void start_pass_dpost (j_decompress_ptr cinfo, J_BUF_MODE pass_mode)
{
    METHODDEF_start_pass_dpost (cinfo, pass_mode);
}

EXTERN void METHODDEF_post_process_1pass (j_decompress_ptr cinfo, JSAMPIMAGE input_buf, JDIMENSION *in_row_group_ctr, JDIMENSION in_row_groups_avail, JSAMPARRAY output_buf, JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail);

void post_process_1pass (j_decompress_ptr cinfo, JSAMPIMAGE input_buf,
			 JDIMENSION *in_row_group_ctr,
			 JDIMENSION in_row_groups_avail, JSAMPARRAY output_buf,
			 JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail)
{
    METHODDEF_post_process_1pass (cinfo, input_buf, in_row_group_ctr,
				  in_row_groups_avail, output_buf, out_row_ctr,
				  out_rows_avail);
}


/* jdsample.c */

EXTERN void METHODDEF_start_pass_upsample (j_decompress_ptr cinfo);

void start_pass_upsample (j_decompress_ptr cinfo)
{
    METHODDEF_start_pass_upsample (cinfo);
}

EXTERN void METHODDEF_sep_upsample (j_decompress_ptr cinfo, JSAMPIMAGE input_buf, JDIMENSION *in_row_group_ctr, JDIMENSION in_row_groups_avail, JSAMPARRAY output_buf, JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail);

void sep_upsample (j_decompress_ptr cinfo, JSAMPIMAGE input_buf,
		   JDIMENSION *in_row_group_ctr,
		   JDIMENSION in_row_groups_avail, JSAMPARRAY output_buf,
		   JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail)
{
    METHODDEF_sep_upsample (cinfo, input_buf, in_row_group_ctr,
			    in_row_groups_avail, output_buf, out_row_ctr,
			    out_rows_avail);
}

EXTERN void METHODDEF_fullsize_upsample (j_decompress_ptr cinfo, jpeg_component_info * compptr,	JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr);

void fullsize_upsample (j_decompress_ptr cinfo, jpeg_component_info * compptr,
			JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr)
{
    METHODDEF_fullsize_upsample (cinfo, compptr, input_data, output_data_ptr);
}

EXTERN void METHODDEF_noop_upsample (j_decompress_ptr cinfo, jpeg_component_info * compptr, JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr);

void noop_upsample (j_decompress_ptr cinfo, jpeg_component_info * compptr,
		    JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr)
{
    METHODDEF_noop_upsample (cinfo, compptr, input_data, output_data_ptr);
}

EXTERN void METHODDEF_int_upsample (j_decompress_ptr cinfo, jpeg_component_info * compptr, JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr);

void int_upsample (j_decompress_ptr cinfo, jpeg_component_info * compptr,
		   JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr)
{
    METHODDEF_int_upsample (cinfo, compptr, input_data, output_data_ptr);
}

EXTERN void METHODDEF_h2v1_upsample (j_decompress_ptr cinfo, jpeg_component_info * compptr, JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr);

void h2v1_upsample (j_decompress_ptr cinfo, jpeg_component_info * compptr,
		    JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr)
{
    METHODDEF_h2v1_upsample (cinfo, compptr, input_data, output_data_ptr);
}

EXTERN void METHODDEF_h2v2_upsample (j_decompress_ptr cinfo, jpeg_component_info * compptr, JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr);

void h2v2_upsample (j_decompress_ptr cinfo, jpeg_component_info * compptr,
		    JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr)
{
    METHODDEF_h2v2_upsample (cinfo, compptr, input_data, output_data_ptr);
}

EXTERN void METHODDEF_h2v1_fancy_upsample (j_decompress_ptr cinfo, jpeg_component_info * compptr, JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr);

void h2v1_fancy_upsample (j_decompress_ptr cinfo,
			  jpeg_component_info * compptr,
			  JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr)
{
    METHODDEF_h2v1_fancy_upsample (cinfo, compptr, input_data,
				   output_data_ptr);
}

EXTERN void METHODDEF_h2v2_fancy_upsample (j_decompress_ptr cinfo, jpeg_component_info * compptr, JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr);

void h2v2_fancy_upsample (j_decompress_ptr cinfo,
			  jpeg_component_info * compptr,
			  JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr)
{
    METHODDEF_h2v2_fancy_upsample (cinfo, compptr, input_data,
				   output_data_ptr);
}


/* jquant1.c */

EXTERN void METHODDEF_start_pass_1_quant (j_decompress_ptr cinfo);

void start_pass_1_quant (j_decompress_ptr cinfo)
{
    METHODDEF_start_pass_1_quant (cinfo);
}

EXTERN void METHODDEF_finish_pass_1_quant (j_decompress_ptr cinfo);

void finish_pass_1_quant (j_decompress_ptr cinfo)
{
    METHODDEF_finish_pass_1_quant (cinfo);
}


/* jidctfst.c */

#ifdef DCT_IFAST_SUPPORTED
EXTERN void GLOBAL_jpeg_idct_ifast (j_decompress_ptr cinfo, jpeg_component_info * compptr, JCOEFPTR coef_block, JSAMPARRAY output_buf, JDIMENSION output_col);

void jpeg_idct_ifast (j_decompress_ptr cinfo, jpeg_component_info * compptr,
		      JCOEFPTR coef_block,
		      JSAMPARRAY output_buf, JDIMENSION output_col)
{
    GLOBAL_jpeg_idct_ifast(cinfo, compptr, coef_block, output_buf, output_col);
}
#endif


/* jidctint.c */

#ifdef DCT_ISLOW_SUPPORTED
EXTERN void GLOBAL_jpeg_idct_islow (j_decompress_ptr cinfo, jpeg_component_info * compptr, JCOEFPTR coef_block, JSAMPARRAY output_buf, JDIMENSION output_col);

void jpeg_idct_islow (j_decompress_ptr cinfo, jpeg_component_info * compptr,
		      JCOEFPTR coef_block,
		      JSAMPARRAY output_buf, JDIMENSION output_col)
{
    GLOBAL_jpeg_idct_islow(cinfo, compptr, coef_block, output_buf, output_col);
}
#endif
