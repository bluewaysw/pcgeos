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
	

	$Id: jmethoddef.c,v 1.1 97/04/07 11:50:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#define JPEG_INTERNALS
#include "jinclude.h"
#include "jpeglib.h"

#ifdef __HIGHC__
#pragma Code ("JpegFixedCodeC");
#endif
#ifdef __BORLANDC__
#pragma codeseg JpegFixedCodeC
#endif
#ifdef __WATCOMC__
#pragma code_seg ("JpegFixedCodeC")
#endif

/* jdatasrc.c */

EXTERN void METHODDEF_init_source (j_decompress_ptr cinfo);

void init_source (j_decompress_ptr cinfo)
{
    METHODDEF_init_source (cinfo);
}

EXTERN boolean METHODDEF_fill_input_buffer (j_decompress_ptr cinfo);

boolean fill_input_buffer (j_decompress_ptr cinfo)
{
    return METHODDEF_fill_input_buffer (cinfo);
}

EXTERN void METHODDEF_skip_input_data (j_decompress_ptr cinfo, long num_bytes);

void skip_input_data (j_decompress_ptr cinfo, long num_bytes)
{
    METHODDEF_skip_input_data (cinfo, num_bytes);
}

EXTERN void METHODDEF_term_source (j_decompress_ptr cinfo);

void term_source (j_decompress_ptr cinfo)
{
    METHODDEF_term_source (cinfo);
}


/* jdcoefct.c */

EXTERN void METHODDEF_coefct_start_input_pass (j_decompress_ptr cinfo);

void coefct_start_input_pass (j_decompress_ptr cinfo)
{
    METHODDEF_coefct_start_input_pass (cinfo);
}

EXTERN void METHODDEF_coefct_start_output_pass (j_decompress_ptr cinfo);

void coefct_start_output_pass (j_decompress_ptr cinfo)
{
    METHODDEF_coefct_start_output_pass (cinfo);
}

EXTERN int METHODDEF_decompress_onepass (j_decompress_ptr cinfo, JSAMPIMAGE output_buf);

int decompress_onepass (j_decompress_ptr cinfo, JSAMPIMAGE output_buf)
{
    return METHODDEF_decompress_onepass (cinfo, output_buf);
}

EXTERN int METHODDEF_dummy_consume_data (j_decompress_ptr cinfo);

int dummy_consume_data (j_decompress_ptr cinfo)
{
    return METHODDEF_dummy_consume_data (cinfo);
}

EXTERN int METHODDEF_consume_data (j_decompress_ptr cinfo);

int consume_data (j_decompress_ptr cinfo)
{
    return METHODDEF_consume_data (cinfo);
}

EXTERN int METHODDEF_decompress_data (j_decompress_ptr cinfo, JSAMPIMAGE output_buf);

int decompress_data (j_decompress_ptr cinfo, JSAMPIMAGE output_buf)
{
    return METHODDEF_decompress_data (cinfo, output_buf);
}

#ifdef BLOCK_SMOOTHING_SUPPORTED
EXTERN int METHODDEF_decompress_smooth_data (j_decompress_ptr cinfo, JSAMPIMAGE output_buf);

int decompress_smooth_data (j_decompress_ptr cinfo, JSAMPIMAGE output_buf)
{
    return METHODDEF_decompress_smooth_data (cinfo, output_buf);
}
#endif

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

#ifdef QUANT_2PASS_SUPPORTED
EXTERN void METHODDEF_process_data_crank_post (j_decompress_ptr cinfo, JSAMPARRAY output_buf, JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail);

void process_data_crank_post (j_decompress_ptr cinfo, JSAMPARRAY output_buf,
			      JDIMENSION *out_row_ctr,
			      JDIMENSION out_rows_avail)
{
    METHODDEF_process_data_crank_post (cinfo, output_buf, out_row_ctr,
				       out_rows_avail);
}
#endif


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

EXTERN int METHODDEF_read_markers (j_decompress_ptr cinfo);

int read_markers (j_decompress_ptr cinfo)
{
    return METHODDEF_read_markers (cinfo);
}

EXTERN boolean METHODDEF_read_restart_marker (j_decompress_ptr cinfo);

boolean read_restart_marker (j_decompress_ptr cinfo)
{
    return METHODDEF_read_restart_marker (cinfo);
}

EXTERN void METHODDEF_reset_marker_reader (j_decompress_ptr cinfo);

void reset_marker_reader (j_decompress_ptr cinfo)
{
    METHODDEF_reset_marker_reader (cinfo);
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


/* jdmerge.c */

EXTERN void METHODDEF_start_pass_merged_upsample (j_decompress_ptr cinfo);

void start_pass_merged_upsample (j_decompress_ptr cinfo)
{
    METHODDEF_start_pass_merged_upsample (cinfo);
}

EXTERN void METHODDEF_merged_2v_upsample (j_decompress_ptr cinfo, JSAMPIMAGE input_buf, JDIMENSION *in_row_group_ctr, JDIMENSION in_row_groups_avail, JSAMPARRAY output_buf, JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail);

void merged_2v_upsample (j_decompress_ptr cinfo, JSAMPIMAGE input_buf,
			 JDIMENSION *in_row_group_ctr,
			 JDIMENSION in_row_groups_avail, JSAMPARRAY output_buf,
			 JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail)
{
    METHODDEF_merged_2v_upsample (cinfo, input_buf, in_row_group_ctr,
				  in_row_groups_avail, output_buf, out_row_ctr,
				  out_rows_avail);
}

EXTERN void METHODDEF_merged_1v_upsample (j_decompress_ptr cinfo, JSAMPIMAGE input_buf, JDIMENSION *in_row_group_ctr, JDIMENSION in_row_groups_avail, JSAMPARRAY output_buf, JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail);

void merged_1v_upsample (j_decompress_ptr cinfo, JSAMPIMAGE input_buf,
			 JDIMENSION *in_row_group_ctr,
			 JDIMENSION in_row_groups_avail, JSAMPARRAY output_buf,
			 JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail)
{
    METHODDEF_merged_1v_upsample (cinfo, input_buf, in_row_group_ctr,
				  in_row_groups_avail, output_buf, out_row_ctr,
				  out_rows_avail);
}

EXTERN void METHODDEF_h2v1_merged_upsample (j_decompress_ptr cinfo, JSAMPIMAGE input_buf, JDIMENSION in_row_group_ctr, JSAMPARRAY output_buf);

void h2v1_merged_upsample (j_decompress_ptr cinfo, JSAMPIMAGE input_buf,
			   JDIMENSION in_row_group_ctr, JSAMPARRAY output_buf)
{
    METHODDEF_h2v1_merged_upsample (cinfo, input_buf, in_row_group_ctr,
				    output_buf);
}

EXTERN void METHODDEF_h2v2_merged_upsample (j_decompress_ptr cinfo, JSAMPIMAGE input_buf, JDIMENSION in_row_group_ctr, JSAMPARRAY output_buf);

void h2v2_merged_upsample (j_decompress_ptr cinfo, JSAMPIMAGE input_buf,
			   JDIMENSION in_row_group_ctr, JSAMPARRAY output_buf)
{
    METHODDEF_h2v2_merged_upsample (cinfo, input_buf, in_row_group_ctr,
				    output_buf);
}


/* jdpbuff.c */

EXTERN void METHODDEF_start_pass_phuff_decoder (j_decompress_ptr cinfo);

void start_pass_phuff_decoder (j_decompress_ptr cinfo)
{
    METHODDEF_start_pass_phuff_decoder (cinfo);
}

EXTERN boolean METHODDEF_decode_mcu_DC_first (j_decompress_ptr cinfo, JBLOCKROW *MCU_data);

boolean decode_mcu_DC_first (j_decompress_ptr cinfo, JBLOCKROW *MCU_data)
{
    return METHODDEF_decode_mcu_DC_first (cinfo, MCU_data);
}

EXTERN boolean METHODDEF_decode_mcu_AC_first (j_decompress_ptr cinfo, JBLOCKROW *MCU_data);

boolean decode_mcu_AC_first (j_decompress_ptr cinfo, JBLOCKROW *MCU_data)
{
    return METHODDEF_decode_mcu_AC_first (cinfo, MCU_data);
}

EXTERN boolean METHODDEF_decode_mcu_DC_refine (j_decompress_ptr cinfo, JBLOCKROW *MCU_data);

boolean decode_mcu_DC_refine (j_decompress_ptr cinfo, JBLOCKROW *MCU_data)
{
    return METHODDEF_decode_mcu_DC_refine (cinfo, MCU_data);
}

EXTERN boolean METHODDEF_decode_mcu_AC_refine (j_decompress_ptr cinfo, JBLOCKROW *MCU_data);

boolean decode_mcu_AC_refine (j_decompress_ptr cinfo, JBLOCKROW *MCU_data)
{
    return METHODDEF_decode_mcu_AC_refine (cinfo, MCU_data);
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

#ifdef QUANT_2PASS_SUPPORTED
EXTERN void METHODDEF_post_process_prepass (j_decompress_ptr cinfo, JSAMPIMAGE input_buf, JDIMENSION *in_row_group_ctr, JDIMENSION in_row_groups_avail, JSAMPARRAY output_buf, JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail);

void post_process_prepass (j_decompress_ptr cinfo, JSAMPIMAGE input_buf,
			   JDIMENSION *in_row_group_ctr,
			   JDIMENSION in_row_groups_avail,
			   JSAMPARRAY output_buf, JDIMENSION *out_row_ctr,
			   JDIMENSION out_rows_avail)
{
    METHODDEF_post_process_prepass (cinfo, input_buf, in_row_group_ctr,
				    in_row_groups_avail, output_buf,
				    out_row_ctr, out_rows_avail);
}
#endif

#ifdef QUANT_2PASS_SUPPORTED
EXTERN void METHODDEF_post_process_2pass (j_decompress_ptr cinfo, JSAMPIMAGE input_buf, JDIMENSION *in_row_group_ctr, JDIMENSION in_row_groups_avail, JSAMPARRAY output_buf, JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail);

void post_process_2pass (j_decompress_ptr cinfo, JSAMPIMAGE input_buf,
			 JDIMENSION *in_row_group_ctr,
			 JDIMENSION in_row_groups_avail, JSAMPARRAY output_buf,
			 JDIMENSION *out_row_ctr, JDIMENSION out_rows_avail)
{
    METHODDEF_post_process_2pass (cinfo, input_buf, in_row_group_ctr,
				  in_row_groups_avail, output_buf,
				  out_row_ctr, out_rows_avail);
}
#endif


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


/* jerror.c */

EXTERN void METHODDEF_error_exit (j_common_ptr cinfo);

void error_exit (j_common_ptr cinfo)
{
    METHODDEF_error_exit (cinfo);
}

void output_message (j_common_ptr cinfo)
{
}

void emit_message (j_common_ptr cinfo, int msg_level)
{
}

void format_message (j_common_ptr cinfo, char * buffer)
{
}

EXTERN void METHODDEF_reset_error_mgr (j_common_ptr cinfo);

void reset_error_mgr (j_common_ptr cinfo)
{
    METHODDEF_reset_error_mgr (cinfo);
}


/* jmemmgr.c */

EXTERN void * METHODDEF_alloc_small (j_common_ptr cinfo, int pool_id, 
				     size_t sizeofobject);

void * alloc_small (j_common_ptr cinfo, int pool_id, size_t sizeofobject)
{
    return METHODDEF_alloc_small (cinfo, pool_id, sizeofobject);
}

EXTERN void FAR * METHODDEF_alloc_large (j_common_ptr cinfo, int pool_id, size_t sizeofobject);

void FAR * alloc_large (j_common_ptr cinfo, int pool_id, size_t sizeofobject)
{
    return METHODDEF_alloc_large (cinfo, pool_id, sizeofobject);
}

EXTERN JSAMPARRAY METHODDEF_alloc_sarray (j_common_ptr cinfo, int pool_id, JDIMENSION samplesperrow, JDIMENSION numrows);

JSAMPARRAY alloc_sarray (j_common_ptr cinfo, int pool_id,
			 JDIMENSION samplesperrow, JDIMENSION numrows)
{
    return METHODDEF_alloc_sarray (cinfo, pool_id, samplesperrow, numrows);
}

EXTERN JBLOCKARRAY METHODDEF_alloc_barray (j_common_ptr cinfo, int pool_id, JDIMENSION blocksperrow, JDIMENSION numrows);

JBLOCKARRAY alloc_barray (j_common_ptr cinfo, int pool_id,
			  JDIMENSION blocksperrow, JDIMENSION numrows)
{
    return METHODDEF_alloc_barray (cinfo, pool_id, blocksperrow, numrows);
}

EXTERN jvirt_sarray_ptr METHODDEF_request_virt_sarray (j_common_ptr cinfo, int pool_id, boolean pre_zero, JDIMENSION samplesperrow, JDIMENSION numrows, JDIMENSION maxaccess);

jvirt_sarray_ptr request_virt_sarray (j_common_ptr cinfo, int pool_id,
				      boolean pre_zero,
				      JDIMENSION samplesperrow,
				      JDIMENSION numrows,
				      JDIMENSION maxaccess)
{
    return METHODDEF_request_virt_sarray (cinfo, pool_id, pre_zero,
					  samplesperrow, numrows, maxaccess);
}

EXTERN jvirt_barray_ptr METHODDEF_request_virt_barray (j_common_ptr cinfo, int pool_id, boolean pre_zero, JDIMENSION blocksperrow, JDIMENSION numrows, JDIMENSION maxaccess);

jvirt_barray_ptr request_virt_barray (j_common_ptr cinfo, int pool_id,
				      boolean pre_zero,
				      JDIMENSION blocksperrow,
				      JDIMENSION numrows,
				      JDIMENSION maxaccess)
{
    return METHODDEF_request_virt_barray (cinfo, pool_id, pre_zero,
					  blocksperrow, numrows, maxaccess);
}

EXTERN void METHODDEF_realize_virt_arrays (j_common_ptr cinfo);

void realize_virt_arrays (j_common_ptr cinfo)
{
    METHODDEF_realize_virt_arrays (cinfo);
}

EXTERN JSAMPARRAY METHODDEF_access_virt_sarray (j_common_ptr cinfo, jvirt_sarray_ptr ptr, JDIMENSION start_row, JDIMENSION num_rows, boolean writable);

JSAMPARRAY access_virt_sarray (j_common_ptr cinfo, jvirt_sarray_ptr ptr,
			       JDIMENSION start_row, JDIMENSION num_rows,
			       boolean writable)
{
    return METHODDEF_access_virt_sarray (cinfo, ptr, start_row, num_rows,
					 writable);
}

EXTERN JBLOCKARRAY METHODDEF_access_virt_barray (j_common_ptr cinfo, jvirt_barray_ptr ptr, JDIMENSION start_row, JDIMENSION num_rows, boolean writable);

JBLOCKARRAY access_virt_barray (j_common_ptr cinfo, jvirt_barray_ptr ptr,
				JDIMENSION start_row, JDIMENSION num_rows,
				boolean writable)
{
    return METHODDEF_access_virt_barray (cinfo, ptr, start_row, num_rows,
					 writable);
}

EXTERN void METHODDEF_free_pool (j_common_ptr cinfo, int pool_id);

void free_pool (j_common_ptr cinfo, int pool_id)
{
    METHODDEF_free_pool (cinfo, pool_id);
}

EXTERN void METHODDEF_self_destruct (j_common_ptr cinfo);

void self_destruct (j_common_ptr cinfo)
{
    METHODDEF_self_destruct (cinfo);
}


/* jquant1.c */

#ifdef QUANT_1PASS_SUPPORTED

EXTERN void METHODDEF_color_quantize (j_decompress_ptr cinfo, JSAMPARRAY input_buf, JSAMPARRAY output_buf, int num_rows);

void color_quantize (j_decompress_ptr cinfo, JSAMPARRAY input_buf,
		     JSAMPARRAY output_buf, int num_rows)
{
    METHODDEF_color_quantize (cinfo, input_buf, output_buf, num_rows);
}

EXTERN void METHODDEF_color_quantize3 (j_decompress_ptr cinfo, JSAMPARRAY input_buf, JSAMPARRAY output_buf, int num_rows);

void color_quantize3 (j_decompress_ptr cinfo, JSAMPARRAY input_buf,
		      JSAMPARRAY output_buf, int num_rows)
{
    METHODDEF_color_quantize3 (cinfo, input_buf, output_buf, num_rows);
}

EXTERN void METHODDEF_quantize_ord_dither (j_decompress_ptr cinfo, JSAMPARRAY input_buf, JSAMPARRAY output_buf, int num_rows);

void quantize_ord_dither (j_decompress_ptr cinfo, JSAMPARRAY input_buf,
			  JSAMPARRAY output_buf, int num_rows)
{
    METHODDEF_quantize_ord_dither (cinfo, input_buf, output_buf, num_rows);
}

EXTERN void METHODDEF_quantize3_ord_dither (j_decompress_ptr cinfo, JSAMPARRAY input_buf, JSAMPARRAY output_buf, int num_rows);

void quantize3_ord_dither (j_decompress_ptr cinfo, JSAMPARRAY input_buf,
			   JSAMPARRAY output_buf, int num_rows)
{
    METHODDEF_quantize3_ord_dither (cinfo, input_buf, output_buf, num_rows);
}

#ifdef QUANT_FS_DITHER
EXTERN void METHODDEF_quantize_fs_dither (j_decompress_ptr cinfo, JSAMPARRAY input_buf, JSAMPARRAY output_buf, int num_rows);

void quantize_fs_dither (j_decompress_ptr cinfo, JSAMPARRAY input_buf,
			 JSAMPARRAY output_buf, int num_rows)
{
    METHODDEF_quantize_fs_dither (cinfo, input_buf, output_buf, num_rows);
}
#endif

EXTERN void METHODDEF_start_pass_1_quant (j_decompress_ptr cinfo, boolean is_pre_scan);

void start_pass_1_quant (j_decompress_ptr cinfo, boolean is_pre_scan)
{
    METHODDEF_start_pass_1_quant (cinfo, is_pre_scan);
}

EXTERN void METHODDEF_finish_pass_1_quant (j_decompress_ptr cinfo);

void finish_pass_1_quant (j_decompress_ptr cinfo)
{
    METHODDEF_finish_pass_1_quant (cinfo);
}

EXTERN void METHODDEF_new_color_map_1_quant (j_decompress_ptr cinfo);

void new_color_map_1_quant (j_decompress_ptr cinfo)
{
    METHODDEF_new_color_map_1_quant (cinfo);
}

#endif


/* jquant2.c */

#ifdef QUANT_2PASS_SUPPORTED

EXTERN void METHODDEF_prescan_quantize (j_decompress_ptr cinfo, JSAMPARRAY input_buf, JSAMPARRAY output_buf, int num_rows);

void prescan_quantize (j_decompress_ptr cinfo, JSAMPARRAY input_buf,
		       JSAMPARRAY output_buf, int num_rows)
{
    METHODDEF_prescan_quantize (cinfo, input_buf, output_buf, num_rows);
}

EXTERN void METHODDEF_pass2_no_dither (j_decompress_ptr cinfo, JSAMPARRAY input_buf, JSAMPARRAY output_buf, int num_rows);

void pass2_no_dither (j_decompress_ptr cinfo,
		      JSAMPARRAY input_buf,
		      JSAMPARRAY output_buf, int num_rows)
{
    METHODDEF_pass2_no_dither (cinfo, input_buf, output_buf, num_rows);
}

EXTERN void METHODDEF_pass2_fs_dither (j_decompress_ptr cinfo, JSAMPARRAY input_buf, JSAMPARRAY output_buf, int num_rows);

void pass2_fs_dither (j_decompress_ptr cinfo, JSAMPARRAY input_buf,
		      JSAMPARRAY output_buf, int num_rows)
{
    METHODDEF_pass2_fs_dither (cinfo, input_buf, output_buf, num_rows);
}

EXTERN void METHODDEF_finish_pass1 (j_decompress_ptr cinfo);

void finish_pass1 (j_decompress_ptr cinfo)
{
    METHODDEF_finish_pass1 (cinfo);
}

EXTERN void METHODDEF_finish_pass2 (j_decompress_ptr cinfo);

void finish_pass2 (j_decompress_ptr cinfo)
{
    METHODDEF_finish_pass2 (cinfo);
}

EXTERN void METHODDEF_start_pass_2_quant (j_decompress_ptr cinfo, boolean is_pre_scan);

void start_pass_2_quant (j_decompress_ptr cinfo, boolean is_pre_scan)
{
    METHODDEF_start_pass_2_quant (cinfo, is_pre_scan);
}

EXTERN void METHODDEF_new_color_map_2_quant (j_decompress_ptr cinfo);

void new_color_map_2_quant (j_decompress_ptr cinfo)
{
    METHODDEF_new_color_map_2_quant (cinfo);
}

#endif	/* QUANT_2PASS_SUPPORTED */


/* jidctred.c */

#ifdef IDCT_SCALING_SUPPORTED

EXTERN void GLOBAL_jpeg_idct_4x4 (j_decompress_ptr cinfo, jpeg_component_info * compptr, JCOEFPTR coef_block, JSAMPARRAY output_buf, JDIMENSION output_col);

void jpeg_idct_4x4 (j_decompress_ptr cinfo, jpeg_component_info * compptr,
		    JCOEFPTR coef_block,
		    JSAMPARRAY output_buf, JDIMENSION output_col)
{
    GLOBAL_jpeg_idct_4x4 (cinfo, compptr, coef_block, output_buf, output_col);
}

EXTERN void GLOBAL_jpeg_idct_2x2 (j_decompress_ptr cinfo, jpeg_component_info * compptr, JCOEFPTR coef_block, JSAMPARRAY output_buf, JDIMENSION output_col);

void jpeg_idct_2x2 (j_decompress_ptr cinfo, jpeg_component_info * compptr,
		    JCOEFPTR coef_block,
		    JSAMPARRAY output_buf, JDIMENSION output_col)
{
    GLOBAL_jpeg_idct_2x2 (cinfo, compptr, coef_block, output_buf, output_col);
}

EXTERN void GLOBAL_jpeg_idct_1x1 (j_decompress_ptr cinfo, jpeg_component_info * compptr, JCOEFPTR coef_block, JSAMPARRAY output_buf, JDIMENSION output_col);

void jpeg_idct_1x1 (j_decompress_ptr cinfo, jpeg_component_info * compptr,
		    JCOEFPTR coef_block,
		    JSAMPARRAY output_buf, JDIMENSION output_col)
{
    GLOBAL_jpeg_idct_1x1 (cinfo, compptr, coef_block, output_buf, output_col);
}

#endif	/* IDCT_SCALING_SUPPORTED */


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
