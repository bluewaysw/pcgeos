/*
 * jpegint.h
 *
 * Copyright (C) 1991-1996, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file provides common declarations for the various JPEG modules.
 * These declarations are considered internal to the JPEG library; most
 * applications using the library shouldn't need to include this file.
 */


/* Declarations for both compression & decompression */

typedef enum {			/* Operating modes for buffer controllers */
	JBUF_PASS_THRU,		/* Plain stripwise operation */
	/* Remaining modes require a full-image buffer to have been created */
	JBUF_SAVE_SOURCE,	/* Run source subobject only, save output */
	JBUF_CRANK_DEST,	/* Run dest subobject only, using saved data */
	JBUF_SAVE_AND_PASS	/* Run both subobjects, save output */
} J_BUF_MODE;

/* Values of global_state field (jdapi.c has some dependencies on ordering!) */
#define CSTATE_START	100	/* after create_compress */
#define CSTATE_SCANNING	101	/* start_compress done, write_scanlines OK */
#define CSTATE_RAW_OK	102	/* start_compress done, write_raw_data OK */
#define CSTATE_WRCOEFS	103	/* jpeg_write_coefficients done */
#define DSTATE_START	200	/* after create_decompress */
#define DSTATE_INHEADER	201	/* reading header markers, no SOS yet */
#define DSTATE_READY	202	/* found SOS, ready for start_decompress */
#define DSTATE_PRELOAD	203	/* reading multiscan file in start_decompress*/
#define DSTATE_PRESCAN	204	/* performing dummy pass for 2-pass quant */
#define DSTATE_SCANNING	205	/* start_decompress done, read_scanlines OK */
#define DSTATE_RAW_OK	206	/* start_decompress done, read_raw_data OK */
#define DSTATE_BUFIMAGE	207	/* expecting jpeg_start_output */
#define DSTATE_BUFPOST	208	/* looking for SOS/EOI in jpeg_finish_output */
#define DSTATE_RDCOEFS	209	/* reading file in jpeg_read_coefficients */
#define DSTATE_STOPPING	210	/* looking for EOI in jpeg_finish_decompress */


/* Declarations for compression modules */

/* Master control module */

MDEF1(void, prepare_for_pass, j_compress_ptr cinfo);
MDEF1(void, pass_startup, j_compress_ptr cinfo);
MDEF1(void, cm_finish_pass, j_compress_ptr cinfo);

struct jpeg_comp_master {
  MPTR(prepare_for_pass);
  MPTR(pass_startup);
  MPTR(cm_finish_pass);

  /* State variables made visible to other modules */
  boolean call_pass_startup;	/* True if pass_startup must be called */
  boolean is_last_pass;		/* True during last pass */
};

/* Main buffer control (downsampled-data buffer) */

MDEF2(void, cmc_start_pass, j_compress_ptr cinfo, J_BUF_MODE pass_mode);
MDEF4(void, cmc_process_data, j_compress_ptr cinfo,
			       JSAMPARRAY input_buf, JDIMENSION *in_row_ctr,
                JDIMENSION in_rows_avail);

struct jpeg_c_main_controller {
  MPTR(cmc_start_pass);
  MPTR(cmc_process_data);
};

/* Compression preprocessing (downsampling input buffer control) */

MDEF2(void, cpc_start_pass, j_compress_ptr cinfo, J_BUF_MODE pass_mode);
MDEF7(void, pre_process_data, j_compress_ptr cinfo,
				   JSAMPARRAY input_buf,
				   JDIMENSION *in_row_ctr,
				   JDIMENSION in_rows_avail,
				   JSAMPIMAGE output_buf,
				   JDIMENSION *out_row_group_ctr,
               JDIMENSION out_row_groups_avail);

struct jpeg_c_prep_controller {
  MPTR(cpc_start_pass);
  MPTR(pre_process_data);
};

/* Coefficient buffer control */

MDEF2(void, ccc_start_pass, j_compress_ptr cinfo, J_BUF_MODE pass_mode);
MDEF2(boolean, compress_data, j_compress_ptr cinfo,
               JSAMPIMAGE input_buf);

struct jpeg_c_coef_controller {
  MPTR(ccc_start_pass);
  MPTR(compress_data);
};

/* Colorspace conversion */

MDEF1(void, cc_start_pass, j_compress_ptr cinfo);
MDEF5(void, cc_color_convert, j_compress_ptr cinfo,
				JSAMPARRAY input_buf, JSAMPIMAGE output_buf,
            JDIMENSION output_row, int num_rows);

struct jpeg_color_converter {
  MPTR(cc_start_pass);
  MPTR(cc_color_convert);
};

/* Downsampling */

MDEF1(void, ds_start_pass, j_compress_ptr cinfo);
MDEF5(void, downsample, j_compress_ptr cinfo,
			     JSAMPIMAGE input_buf, JDIMENSION in_row_index,
			     JSAMPIMAGE output_buf,
              JDIMENSION out_row_group_index);

struct jpeg_downsampler {
  MPTR(ds_start_pass);
  MPTR(downsample);

  boolean need_context_rows;	/* TRUE if need rows above & below */
};

/* Forward DCT (also controls coefficient quantization) */

MDEF1(void, fd_start_pass, j_compress_ptr cinfo);
  /* perhaps this should be an array??? */
MDEF7(void, forward_DCT, j_compress_ptr cinfo,
			      jpeg_component_info * compptr,
			      JSAMPARRAY sample_data, JBLOCKROW coef_blocks,
			      JDIMENSION start_row, JDIMENSION start_col,
               JDIMENSION num_blocks);

struct jpeg_forward_dct {
  MPTR(fd_start_pass);
  MPTR(forward_DCT);
};

/* Entropy encoding */

MDEF2(void, ee_start_pass, j_compress_ptr cinfo, boolean gather_statistics);
MDEF2(boolean, encode_mcu, j_compress_ptr cinfo, JBLOCKROW *MCU_data);
MDEF1(void, ee_finish_pass, j_compress_ptr cinfo);

struct jpeg_entropy_encoder {
  MPTR(ee_start_pass);
  MPTR(encode_mcu);
  MPTR(ee_finish_pass);
};

/* Marker writing */

MDEF4(void, write_any_marker, j_compress_ptr cinfo, int marker,
               const JOCTET *dataptr, unsigned int datalen);
MDEF1(void, write_file_header, j_compress_ptr cinfo);
MDEF1(void, write_frame_header, j_compress_ptr cinfo);
MDEF1(void, write_scan_header, j_compress_ptr cinfo);
MDEF1(void, write_file_trailer, j_compress_ptr cinfo);
MDEF1(void, write_tables_only, j_compress_ptr cinfo);

struct jpeg_marker_writer {
  /* write_any_marker is exported for use by applications */
  /* Probably only COM and APPn markers should be written */
  MPTR(write_any_marker);
  MPTR(write_file_header);
  MPTR(write_frame_header);
  MPTR(write_scan_header);
  MPTR(write_file_trailer);
  MPTR(write_tables_only);
};


/* Declarations for decompression modules */

/* Master control module */

MDEF1(void, prepare_for_output_pass, j_decompress_ptr cinfo);
MDEF1(void, finish_output_pass, j_decompress_ptr cinfo);

struct jpeg_decomp_master {
  MPTR(prepare_for_output_pass);
  MPTR(finish_output_pass);

  /* State variables made visible to other modules */
  boolean is_dummy_pass;	/* True during 1st pass for 2-pass quant */
};

/* Input control module */

MDEF1(int, consume_input, j_decompress_ptr cinfo);
MDEF1(void, reset_input_controller, j_decompress_ptr cinfo);
MDEF1(void, start_input_pass, j_decompress_ptr cinfo);
MDEF1(void, finish_input_pass, j_decompress_ptr cinfo);

struct jpeg_input_controller {
  MPTR(consume_input);
  MPTR(reset_input_controller);
  MPTR(start_input_pass);
  MPTR(finish_input_pass);

  /* State variables made visible to other modules */
  boolean has_multiple_scans;	/* True if file has multiple scans */
  boolean eoi_reached;		/* True when EOI has been consumed */

#if PROGRESS_DISPLAY
  /* pointer to load progress data */
  LoadProgressData *loadProgressDataP;
#endif
};

/* Main buffer control (downsampled-data buffer) */

MDEF2(void, dmc_start_pass, j_decompress_ptr cinfo, J_BUF_MODE pass_mode);
MDEF4(void, dmc_process_data, j_decompress_ptr cinfo,
			       JSAMPARRAY output_buf, JDIMENSION *out_row_ctr,
                JDIMENSION out_rows_avail);

struct jpeg_d_main_controller {
  MPTR(dmc_start_pass);
  MPTR(dmc_process_data);
};

/* Coefficient buffer control */

MDEF1(void, start_input_pass, j_decompress_ptr cinfo);
MDEF1(int, consume_data, j_decompress_ptr cinfo);
MDEF1(void, start_output_pass, j_decompress_ptr cinfo);
MDEF2(int, decompress_data, j_decompress_ptr cinfo,
             JSAMPIMAGE output_buf);

struct jpeg_d_coef_controller {
  MPTR(start_input_pass);
  MPTR(consume_data);
  MPTR(start_output_pass);
  MPTR(decompress_data);

  /* Pointer to array of coefficient virtual arrays, or NULL if none */
  jvirt_barray_ptr *coef_arrays;
};

/* Decompression postprocessing (color quantization buffer control) */

MDEF2(void, dpc_start_pass, j_decompress_ptr cinfo, J_BUF_MODE pass_mode);
MDEF7(void, post_process_data, j_decompress_ptr cinfo,
				    JSAMPIMAGE input_buf,
				    JDIMENSION *in_row_group_ctr,
				    JDIMENSION in_row_groups_avail,
				    JSAMPARRAY output_buf,
				    JDIMENSION *out_row_ctr,
                JDIMENSION out_rows_avail);

struct jpeg_d_post_controller {
  MPTR(dpc_start_pass);
  MPTR(post_process_data);
};

/* Marker reading & parsing */

MDEF1(void, reset_marker_reader, j_decompress_ptr cinfo);
  /* Read markers until SOS or EOI.
   * Returns same codes as are defined for jpeg_consume_input:
   * JPEG_SUSPENDED, JPEG_REACHED_SOS, or JPEG_REACHED_EOI.
   */
MDEF1(int, read_markers, j_decompress_ptr cinfo);
  /* Read a restart marker --- exported for use by entropy decoder only */

struct jpeg_marker_reader {
  MPTR(reset_marker_reader);
  MPTR(read_markers);
 
  jpeg_marker_parser_method read_restart_marker;
  /* Application-overridable marker processing methods */
  jpeg_marker_parser_method process_COM;
  jpeg_marker_parser_method process_APPn[16];

  /* State of marker reader --- nominally internal, but applications
   * supplying COM or APPn handlers might like to know the state.
   */
  boolean saw_SOI;		/* found SOI? */
  boolean saw_SOF;		/* found SOF? */
  int next_restart_num;		/* next restart number expected (0-7) */
  unsigned int discarded_bytes;	/* # of bytes skipped looking for a marker */
};

/* Entropy decoding */
MDEF1(void, ed_start_pass, j_decompress_ptr cinfo);
MDEF2(boolean, decode_mcu, j_decompress_ptr cinfo,
            JBLOCKROW *MCU_data);

struct jpeg_entropy_decoder {
  MPTR(ed_start_pass);
  MPTR(decode_mcu);
};

/* Inverse DCT (also performs dequantization) */

MDEF1(void, id_start_pass, j_decompress_ptr cinfo);
MDEF5(void, inverse_DCT_method_ptr,
      j_decompress_ptr cinfo, jpeg_component_info * compptr,
      JCOEFPTR coef_block,
      JSAMPARRAY output_buf, JDIMENSION output_col);

typedef MPTR(inverse_DCT_method_ptr);

struct jpeg_inverse_dct {
  MPTR(id_start_pass);
  /* It is useful to allow each component to have a separate IDCT method. */
  inverse_DCT_method_ptr inverse_DCT[MAX_COMPONENTS];
};

/* Upsampling (note that upsampler must also call color converter) */

MDEF1(void, us_start_pass, j_decompress_ptr cinfo);
MDEF7(void, upsample, j_decompress_ptr cinfo,
			   JSAMPIMAGE input_buf,
			   JDIMENSION *in_row_group_ctr,
			   JDIMENSION in_row_groups_avail,
			   JSAMPARRAY output_buf,
			   JDIMENSION *out_row_ctr,
            JDIMENSION out_rows_avail);

struct jpeg_upsampler {
  MPTR(us_start_pass);
  MPTR(upsample);

  boolean need_context_rows;	/* TRUE if need rows above & below */
};

/* Colorspace conversion */

MDEF1(void, cd_start_pass, j_decompress_ptr cinfo);
MDEF5(void, cd_color_convert, j_decompress_ptr cinfo,
            JSAMPIMAGE input_buf, JDIMENSION input_row,
            JSAMPARRAY output_buf, int num_rows);

struct jpeg_color_deconverter {
  MPTR(cd_start_pass);
  MPTR(cd_color_convert);
};

/* Color quantization or color precision reduction */

MDEF2(void, cq_start_pass, j_decompress_ptr cinfo, boolean is_pre_scan);
MDEF4(void, color_quantize, j_decompress_ptr cinfo,
				 JSAMPARRAY input_buf, JSAMPARRAY output_buf,
             int num_row);
MDEF1(void, cq_finish_pass, j_decompress_ptr cinfo);
MDEF1(void, new_color_map, j_decompress_ptr cinfo);

struct jpeg_color_quantizer {
  MPTR(cq_start_pass);
  MPTR(color_quantize);
  MPTR(cq_finish_pass);
  MPTR(new_color_map);
};


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

#ifdef RIGHT_SHIFT_IS_UNSIGNED
#define SHIFT_TEMPS	INT32 shift_temp;
#define RIGHT_SHIFT(x,shft)  \
	((shift_temp = (x)) < 0 ? \
	 (shift_temp >> (shft)) | ((~((INT32) 0)) << (32-(shft))) : \
	 (shift_temp >> (shft)))
#else
#define SHIFT_TEMPS
#define RIGHT_SHIFT(x,shft)	((x) >> (shft))
#endif


/* Short forms of external names for systems with brain-damaged linkers. */

#ifdef NEED_SHORT_EXTERNAL_NAMES
#define jinit_compress_master	jICompress
#define jinit_c_master_control	jICMaster
#define jinit_c_main_controller	jICMainC
#define jinit_c_prep_controller	jICPrepC
#define jinit_c_coef_controller	jICCoefC
#define jinit_color_converter	jICColor
#define jinit_downsampler	jIDownsampler
#define jinit_forward_dct	jIFDCT
#define jinit_huff_encoder	jIHEncoder
#define jinit_phuff_encoder	jIPHEncoder
#define jinit_marker_writer	jIMWriter
#define jinit_master_decompress	jIDMaster
#define jinit_d_main_controller	jIDMainC
#define jinit_d_coef_controller	jIDCoefC
#define jinit_d_post_controller	jIDPostC
#define jinit_input_controller	jIInCtlr
#define jinit_marker_reader	jIMReader
#define jinit_huff_decoder	jIHDecoder
#define jinit_phuff_decoder	jIPHDecoder
#define jinit_inverse_dct	jIIDCT
#define jinit_upsampler		jIUpsampler
#define jinit_color_deconverter	jIDColor
#define jinit_1pass_quantizer	jI1Quant
#define jinit_2pass_quantizer	jI2Quant
#define jinit_merged_upsampler	jIMUpsampler
#define jinit_memory_mgr	jIMemMgr
#define jdiv_round_up		jDivRound
#define jround_up		jRound
#define jcopy_sample_rows	jCopySamples
#define jcopy_block_row		jCopyBlocks
#define jzero_far		jZeroFar
#define jpeg_zigzag_order	jZIGTable
#define jpeg_natural_order	jZAGTable
#endif /* NEED_SHORT_EXTERNAL_NAMES */


/* Compression module initialization routines */
EXTERN(void) jinit_compress_master JPP((j_compress_ptr cinfo));
EXTERN(void) jinit_c_master_control JPP((j_compress_ptr cinfo,
					 boolean transcode_only));
EXTERN(void) jinit_c_main_controller JPP((j_compress_ptr cinfo,
					  boolean need_full_buffer));
EXTERN(void) jinit_c_prep_controller JPP((j_compress_ptr cinfo,
					  boolean need_full_buffer));
EXTERN(void) jinit_c_coef_controller JPP((j_compress_ptr cinfo,
					  boolean need_full_buffer));
EXTERN(void) jinit_color_converter JPP((j_compress_ptr cinfo));
EXTERN(void) jinit_downsampler JPP((j_compress_ptr cinfo));
EXTERN(void) jinit_forward_dct JPP((j_compress_ptr cinfo));
EXTERN(void) jinit_huff_encoder JPP((j_compress_ptr cinfo));
EXTERN(void) jinit_phuff_encoder JPP((j_compress_ptr cinfo));
EXTERN(void) jinit_marker_writer JPP((j_compress_ptr cinfo));
/* Decompression module initialization routines */
EXTERN(void) jinit_master_decompress JPP((j_decompress_ptr cinfo));
EXTERN(void) jinit_d_main_controller JPP((j_decompress_ptr cinfo,
					  boolean need_full_buffer));
EXTERN(void) jinit_d_coef_controller JPP((j_decompress_ptr cinfo,
					  boolean need_full_buffer));
EXTERN(void) jinit_d_post_controller JPP((j_decompress_ptr cinfo,
					  boolean need_full_buffer));
EXTERN(void) jinit_input_controller JPP((j_decompress_ptr cinfo));
EXTERN(void) jinit_marker_reader JPP((j_decompress_ptr cinfo));
EXTERN(void) jinit_huff_decoder JPP((j_decompress_ptr cinfo));
EXTERN(void) jinit_phuff_decoder JPP((j_decompress_ptr cinfo));
EXTERN(void) jinit_inverse_dct JPP((j_decompress_ptr cinfo));
EXTERN(void) jinit_upsampler JPP((j_decompress_ptr cinfo));
EXTERN(void) jinit_color_deconverter JPP((j_decompress_ptr cinfo));
EXTERN(void) jinit_1pass_quantizer JPP((j_decompress_ptr cinfo));
EXTERN(void) jinit_2pass_quantizer JPP((j_decompress_ptr cinfo));
EXTERN(void) jinit_merged_upsampler JPP((j_decompress_ptr cinfo));
/* Memory manager initialization */
EXTERN(void) jinit_memory_mgr JPP((j_common_ptr cinfo));

/* Utility routines in jutils.c */
EXTERN(long) jdiv_round_up JPP((long a, long b));
EXTERN(long) jround_up JPP((long a, long b));
EXTERN(void) jcopy_sample_rows JPP((JSAMPARRAY input_array, int source_row,
				    JSAMPARRAY output_array, int dest_row,
				    int num_rows, JDIMENSION num_cols));
EXTERN(void) jcopy_block_row JPP((JBLOCKROW input_row, JBLOCKROW output_row,
				  JDIMENSION num_blocks));
EXTERN(void) jzero_far JPP((void FAR * target, size_t bytestozero));
/* Constant tables in jutils.c */
extern const int jpeg_zigzag_order[]; /* natural coef order to zigzag order */
extern const int jpeg_natural_order[]; /* zigzag coef order to natural order */

