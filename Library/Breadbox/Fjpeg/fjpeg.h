/***********************************************************************
 *
 *	Copyright (c) NewDeal Inc. 2000 -- All Rights Reserved
 *
 * PROJECT:     Fast JPEG Decompression Library
 * FILE:	fjpeg.h
 * AUTHOR:	Jens-Michael Gross, July 28, 2000
 *
 * VERSIONS:
 *          00-07-28    JMG     Initial version
 *			00-10-06	FR		Export function suffixed by fjpeg
 *
 *
 * DESCRIPTION:
 *
 *	C include file for using the FJPEG library
 *
 *      This files contains all information for including and using the
 *      fast JPEG decompression library.
 *      This library uses fast, inaccurate calculations to speed up
 *      browser and/or thumbnail display of standard baseline huffman
 *      encoded JPG files (JFIF). This means 8-bit, 3 color planes,
 *      YCbCr color space (2-1-1 and 2-2-2), no color quantization.
 *      For memory reasons, images with a width or height > 2048 are not
 *      supported too.
 *
 *      For everything else use the free IJGJPEG library
 *
 *      *** Interleaved JPEG currently not supported.  ***
 *
 ***********************************************************************/


#ifndef __FJPEG_H
#define __FJPEG_H

#include <product.h>
#include <geos.h>
#include <resource.h>
#include <Ansi/stdio.h>

#if PROGRESS_DISPLAY
#define MIME_MAXBUF 32          /* shouldn't really have to be here... */
#include <htmlprog.h>
#endif


#define UPSAMPLE_MERGING_SUPPORTED
#undef D_PROGRESSIVE_SUPPORTED
#undef D_MULTISCAN_FILES_SUPPORTED

/* Various constants determining the sizes of things.
 * All of these are specified by the JPEG standard, so don't change them
 * if you want to be compatible.
 */

#define DCTSIZE		    8	/* The basic DCT block is 8x8 samples */
#define DCTSIZE2	    64	/* DCTSIZE squared; # of elements in a block */
#define NUM_QUANT_TBLS      3	/* Quantization tables are numbered 0..3 */
#define NUM_HUFF_TBLS       3	/* Huffman tables are numbered 0..3 */
#define NUM_ARITH_TBLS      16	/* Arith-coding tables are numbered 0..15 */
#define MAX_COMPS_IN_SCAN   3	/* JPEG limit on # of components in one scan */
#define MAX_SAMP_FACTOR     4	/* JPEG limit on sampling factors */
#define D_MAX_BLOCKS_IN_MCU 10  /* decompressor's limit on blocks per MCU */
#define BITS_IN_JSAMPLE     8	/* only 8 bit support */
#define MAX_COMPONENTS      3	/* only RGB/YCbCr support */

#define INPUT_BUF_SIZE  1024	/* choose an efficiently fread'able size */

typedef unsigned char  JSAMPLE;
#define GETJSAMPLE(value)  ((int) (value))
#define MAXJSAMPLE	255
#define CENTERJSAMPLE	128

typedef short          JCOEF;
typedef unsigned char  JOCTET;
#define GETJOCTET(value)  (value)

typedef unsigned char  UINT8;
typedef unsigned short UINT16;
typedef short          INT16;
typedef long           INT32;

typedef unsigned int   JDIMENSION;
#define JPEG_MAX_DIMENSION  2048L /* maximum dimension for this lib */
// 65500L  /* a tad under 64K to prevent overflows */

#define _RGB_RED		0	/* Offset of Red in an RGB scanline element */
#define _RGB_GREEN	1	/* Offset of Green */
#define _RGB_BLUE	2	/* Offset of Blue */
#define _RGB_PIXELSIZE	3	/* JSAMPLEs per RGB scanline element */


/* Data structures for images (arrays of samples and of DCT coefficients).
 * On 80x86 machines, the image arrays are too big for near pointers,
 * but the pointer arrays can fit in near memory.
 */

typedef JSAMPLE     *JSAMPROW;	  /* ptr to one image row of pixel samples. */
typedef JSAMPROW    *JSAMPARRAY;  /* ptr to some rows (a 2-D sample array) */
typedef JSAMPARRAY  *JSAMPIMAGE;  /* a 3-D sample array: top index is color */

typedef JCOEF       JBLOCK[DCTSIZE2]; /* one block of coefficients */
typedef JBLOCK      *JBLOCKROW;	  /* pointer to one row of coefficient blocks */
typedef JBLOCKROW   *JBLOCKARRAY; /* a 2-D array of coefficient blocks */
typedef JBLOCKARRAY *JBLOCKIMAGE; /* a 3-D array of coefficient blocks */


typedef JCOEF       *JCOEFPTR;    /* useful in a couple of places */


/* DCT coefficient quantization tables. */

typedef struct {
  /* This array gives the coefficient quantizers in natural array order
   * (not the zigzag order in which they are stored in a JPEG DQT marker).
   */
  UINT16 quantval[DCTSIZE2];	/* quantization step for each coefficient */
  Boolean sent_table;		/* TRUE when table has been output */
} JQUANT_TBL;


/* Huffman coding tables. */

typedef struct {
  /* These two fields directly represent the contents of a JPEG DHT marker */
  UINT8 bits[17];		/* bits[k] = # of symbols with codes of */
				/* length k bits; bits[0] is unused */
  UINT8 huffval[256];		/* The symbols, in order of incr code length */
  Boolean sent_table;		/* TRUE when table has been output */
} JHUFF_TBL;


/* Basic info about one component (color channel). */

/**/typedef struct {
  /* These values are fixed over the whole image. */
  /* for decompression, they are read from the SOF marker. */
  int component_id;		/* identifier for this component (0..255) */
  int component_index;		/* its index in SOF or cinfo->comp_info[] */
  int h_samp_factor;		/* horizontal sampling factor (1..4) */
  int v_samp_factor;		/* vertical sampling factor (1..4) */
  int quant_tbl_no;		/* quantization table selector (0..3) */
  /* These values may vary between scans. */
  /* for decompression, they are read from the SOS marker. */
  /* The decompressor output side may not use these variables. */
  int dc_tbl_no;		/* DC entropy table selector (0..3) */
  int ac_tbl_no;		/* AC entropy table selector (0..3) */

  /* Remaining fields should be treated as private by applications. */

  /* These values are computed during compression or decompression startup: */
  /* Component's size in DCT blocks.
   * Any dummy blocks added to complete an MCU are not counted; therefore
   * these values do not depend on whether a scan is interleaved or not.
   */
  JDIMENSION width_in_blocks;
  JDIMENSION height_in_blocks;
  /* Size of a DCT block in samples.  Always DCTSIZE for compression.
   * For decompression this is the size of the output from one DCT block,
   * reflecting any scaling we choose to apply during the IDCT step.
   * Values of 1,2,4,8 are likely to be supported.  Note that different
   * components may receive different IDCT scalings.
   */
  int DCT_scaled_size;
  /* The downsampled dimensions are the component's actual, unpadded number
   * of samples at the main buffer (preprocessing/compression interface),
   * For decompression, IDCT scaling is included, so
   * downsampled_width = ceil(image_width * Hi/Hmax * DCT_scaled_size/DCTSIZE)
   */
  JDIMENSION downsampled_width;	 /* actual width in samples */
  JDIMENSION downsampled_height; /* actual height in samples */
  /* This flag is used only for decompression.  In cases where some of the
   * components will be ignored (eg grayscale output from YCbCr image),
   * we can skip most computations for the unused components.
   */
  Boolean component_needed;	/* do we need the value of this component? */

  /* These values are computed before starting a scan of the component. */
  /* The decompressor output side may not use these variables. */
  int MCU_width;		/* number of blocks per MCU, horizontally */
  int MCU_height;		/* number of blocks per MCU, vertically */
  int MCU_blocks;		/* MCU_width * MCU_height */
  int MCU_sample_width;		/* MCU width in samples, MCU_width*DCT_scaled_size */
  int last_col_width;		/* # of non-dummy blocks across in last MCU */
  int last_row_height;		/* # of non-dummy blocks down in last MCU */

  /* Saved quantization table for component; NULL if none yet saved.
   * See jdinput.c comments about the need for this information.
   * This field is currently used only for decompression.
   */
  JQUANT_TBL * quant_table;

  /* Private per-component storage for DCT or IDCT subsystem. */
  void * dct_table;
} jpeg_component_info;


/* The script for encoding a multiple-scan file is an array of these: */

/**/typedef struct {
  int comps_in_scan;		/* number of components encoded in this scan */
  int component_index[MAX_COMPS_IN_SCAN]; /* their SOF/comp_info[] indexes */
  int Ss, Se;			/* progressive JPEG spectral selection parms */
  int Ah, Al;			/* progressive JPEG successive approx. parms */
} jpeg_scan_info;


/* Known color spaces. */

/**/typedef enum {
	JCS_UNKNOWN,		/* error/unspecified */
	JCS_GRAYSCALE,		/* monochrome */
	JCS_RGB,		/* red/green/blue */
	JCS_YCbCr		/* Y/Cb/Cr (also known as YUV) */
} J_COLOR_SPACE;

/*  large memory structure handle struct */

typedef struct {
  MemHandle handle;
  void far * deref;
  int locked;
  int size;
} LargeMem;


/* Derived data constructed for each Huffman table */

#define HUFF_LOOKAHEAD	8	/* # of bits of lookahead */

typedef struct {
  /* Basic tables: (element [0] of each array is unused) */
  INT32 mincode[17];		/* smallest code of length k */
  INT32 maxcode[18];		/* largest code of length k (-1 if none) */
  /* (maxcode[17] is a sentinel to ensure jpeg_huff_decode terminates) */
  int valptr[17];		/* huffval[] index of 1st symbol of length k */

  /* Link to public Huffman table (needed only in jpeg_huff_decode) */
  JHUFF_TBL *pub;

  /* Lookahead tables: indexed by the next HUFF_LOOKAHEAD bits of
   * the input data stream.  If the next Huffman code is no more
   * than HUFF_LOOKAHEAD bits long, we can obtain its length and
   * the corresponding symbol directly from these tables.
   */
  int look_nbits[1<<HUFF_LOOKAHEAD]; /* # bits, or 0 if too long */
  UINT8 look_sym[1<<HUFF_LOOKAHEAD]; /* symbol, or unused */
} d_derived_tbl;

typedef struct {		/* Bitreading state saved across MCUs */
  INT32 get_buffer;      	/* current bit-extraction buffer */
  int bits_left;		/* # of unused bits in it */
  Boolean printed_eod;		/* flag to suppress multiple warning msgs */
} bitread_perm_state;

/*
 * Expanded entropy decoder object for Huffman decoding.
 *
 * The jdhuff_savable_state subrecord contains fields that change within an MCU,
 * but must not be updated permanently until we complete the MCU.
 */

typedef struct {
  int last_dc_val[MAX_COMPS_IN_SCAN]; /* last DC coef for each component */
} jdhuff_savable_state;



/* defines for decomp_mode */
#define DM_PROGRESS 1
#define DM_YCCRGB   2

/* defines for non-merged upsampling */
#define NU_NO_OP    0
#define NU_FULL_US  1
#define NU_21_US    2
#define NU_22_US    3
#define NU_INT_US   4

/* Master record for a decompression instance */

struct fjpeg_decompress_struct {
  int global_state;		/* for checking call sequence validity */
  int decomp_mode;              /* stores decompressor to use */
  void far * far * memchain;    /* anchor for smalloc memory chain */

  struct {
    const JOCTET * next_input_byte; /* => next byte to read from buffer */
    size_t bytes_in_buffer;	/* # of bytes remaining in buffer */
    FILE * infile;
    JOCTET * buffer;
    Boolean start_of_file;

#if PROGRESS_DISPLAY
	/* pointer to load progress data */
	LoadProgressData *loadProgressDataP;
#endif
  } src;

  struct {
    Boolean has_multiple_scans;	/* True if file has multiple scans */
    Boolean eoi_reached;		/* True when EOI has been consumed */
    Boolean inheaders;		/* TRUE until first SOS is reached */
  } inputctl;

  struct {
    /* State of marker reader --- nominally internal, but applications
     * supplying COM or APPn handlers might like to know the state.
     */
    Boolean saw_SOI;		/* found SOI? */
    Boolean saw_SOF;		/* found SOF? */
    int next_restart_num;		/* next restart number expected (0-7) */
    unsigned int discarded_bytes;	/* # of bytes skipped looking for a marker */
  } marker;

  struct {
    int pass_number;		/* # of passes completed */
  } master;

  struct {
    /* common upsampler data fields */
    JDIMENSION rows_to_go;	/* counts rows remaining in image */

    /* merged upsampler data fields */

    /* number of routine to do actual upsampling/conversion of one row group */
    int upmethod;
    /* Private state for YCC->RGB conversion */
    int * Cr_r_tab;		/* => table for Cr to R conversion */
    int * Cb_b_tab;		/* => table for Cb to B conversion */
    INT32 * Cr_g_tab;		/* => table for Cr to G conversion */
    INT32 * Cb_g_tab;		/* => table for Cb to G conversion */
    /* For 2:1 vertical sampling, we produce two output rows at a time.
     * We need a "spare" row buffer to hold the second output row if the
     * application provides just a one-row buffer; we also use the spare
     * to discard the dummy last row if the image height is odd.
     */
    JDIMENSION out_row_width;	/* samples per output row */

    /* normal 1:1 upsampler data fields */

    /* Color conversion buffer.  When using separate upsampling and color
     * conversion steps, this buffer holds one upsampled row group until it
     * has been color converted and output.
     * Note: we do not allocate any storage for component(s) which are full-size,
     * ie do not need rescaling.  The corresponding entry of color_buf[] is
     * simply set to point to the input data array, thereby avoiding copying.
     */
    JSAMPARRAY color_buf[MAX_COMPONENTS];
    /* Per-component upsampling method pointers */
    int methods[MAX_COMPONENTS];
    int next_row_out;		/* counts rows emitted from color_buf */
    /* Height of an input row group for each component. */
    int rowgroup_height[MAX_COMPONENTS];
    /* These arrays save pixel expansion factors so that int_expand need not
     * recompute them each time.  They are unused for other upsampling methods.
     */
    UINT8 h_expand[MAX_COMPONENTS];
    UINT8 v_expand[MAX_COMPONENTS];
  } upsample;

  struct {
    //MPTR(id_start_pass);
    /* This array contains the IDCT method code that each multiplier table
     * is currently set up for, or -1 if it's not yet set up.
     * there is only the FAST-Integer method, so it is -1 or 1 here.
     * The actual multiplier tables are pointed to by dct_table in the
     * per-component comp_info structures.
     */
    int cur_method[MAX_COMPONENTS];
  } idct;


  struct {
    /* These fields are loaded into local variables at start of each MCU.
     * In case of suspension, we exit WITHOUT updating them.
     */
    bitread_perm_state bitstate;	/* Bit buffer at start of MCU */
    jdhuff_savable_state saved;     /* Other state at start of MCU */
    /* These fields are NOT loaded into local working state. */
    unsigned int restarts_to_go;	/* MCUs left in this restart interval */
    /* Pointers to derived tables (these workspaces have image lifespan) */
    d_derived_tbl * dc_derived_tbls[NUM_HUFF_TBLS];
    d_derived_tbl * ac_derived_tbls[NUM_HUFF_TBLS];
  } entropy;

  struct {
    /* These variables keep track of the current location of the input side. */
    /* cinfo->input_iMCU_row is also used for this. */
    JDIMENSION MCU_ctr;		/* counts MCUs processed in current row */
    int MCU_vert_offset;		/* counts MCU rows within iMCU row */
    int MCU_rows_per_iMCU_row;	/* number of such rows needed */
    /* The output side's location is represented by cinfo->output_iMCU_row. */
    /* In single-pass modes, it's sufficient to buffer just one MCU.
     * We allocate a workspace of D_MAX_BLOCKS_IN_MCU coefficient blocks,
     * and let the entropy decoder write into that workspace each time.
     * (On 80x86, the workspace is FAR even though it's not really very big;
     * this is to keep the module interfaces unchanged when a large coefficient
     * buffer is necessary.)
     * In multi-pass modes, this array points to the current MCU's blocks
     * within the virtual arrays; it is used only by the input side.
     */
    JBLOCKROW MCU_buffer[D_MAX_BLOCKS_IN_MCU];
  #ifdef D_MULTISCAN_FILES_SUPPORTED
    /* In multi-pass modes, we need a virtual block array for each component. */
    jvirt_barray_ptr whole_image[MAX_COMPONENTS];
  #endif
  } coef;

  struct { /* Private buffer controller object */
    /* Pointer to allocated workspace (M or M+2 row groups). */
    JSAMPARRAY buffer[MAX_COMPONENTS];
    Boolean buffer_full;		/* Have we gotten an iMCU row from decoder? */
    JDIMENSION rowgroup_ctr;	/* counts row groups output to postprocessor */
    /* Remaining fields are only used in the context case. */
    /* These are the master pointers to the funny-order pointer lists. */
    JSAMPIMAGE xbuffer[2];	/* pointers to weird pointer lists */
    int whichptr;			/* indicates which pointer set is now in use */
    int context_state;		/* process_data state machine status */
    JDIMENSION rowgroups_avail;	/* row groups available to postprocessor */
    JDIMENSION iMCU_row_ctr;	/* counts iMCU rows to detect image top/bot */
  } main;





  /* Basic description of image --- filled in by jpeg_read_header(). */
  /* Application may inspect these values to decide how to process image. */

  JDIMENSION image_width;	/* nominal image width (from SOF marker) */
  JDIMENSION image_height;	/* nominal image height */
  int num_components;		/* # of color components in JPEG image */
  J_COLOR_SPACE jpeg_color_space; /* colorspace of JPEG image */

  unsigned int scale_num, scale_denom; /* fraction by which to scale image */

  Boolean buffered_image;	/* TRUE=multiple output passes */

  /* Description of actual output image that will be returned to application.
   * These fields are computed by jpeg_start_decompress().
   * You can also use jpeg_calc_output_dimensions() to determine these values
   * in advance of calling jpeg_start_decompress().
   */

  int rec_outbuf_height;	/* min recommended height of scanline buffer */
  /* If the buffer passed to jpeg_read_scanlines() is less than this many rows
   * high, space and time will be wasted due to unnecessary data copying.
   * Usually rec_outbuf_height will be 1 or 2, at most 4.
   */

  /* State variables: these variables indicate the progress of decompression.
   * The application may examine these but must not modify them.
   */

  /* Row index of next scanline to be read from jpeg_read_scanlines().
   * Application may use this to control its processing loop, e.g.,
   * "while (output_scanline < output_height)".
   */
  JDIMENSION output_scanline;	/* 0 .. output_height-1  */

  /* Current input scan number and number of iMCU rows completed in scan.
   * These indicate the progress of the decompressor input side.
   */
  int input_scan_number;	/* Number of SOS markers seen so far */
  JDIMENSION input_iMCU_row;	/* Number of iMCU rows completed */

  /* The "output scan number" is the notional scan being displayed by the
   * output side.  The decompressor will not allow output scan/row number
   * to get ahead of input scan/row, but it can fall arbitrarily far behind.
   */
  int output_scan_number;	/* Nominal scan number being displayed */
  JDIMENSION output_iMCU_row;	/* Number of iMCU rows read */

  /* Current progression status.  coef_bits[c][i] indicates the precision
   * with which component c's DCT coefficient i (in zigzag order) is known.
   * It is -1 when no data has yet been received, otherwise it is the point
   * transform (shift) value for the most recent scan of the coefficient
   * (thus, 0 at completion of the progression).
   * This pointer is NULL when reading a non-progressive file.
   */
  int (*coef_bits)[DCTSIZE2];	/* -1 or current Al value for each coef */

  /* Internal JPEG parameters --- the application usually need not look at
   * these fields.  Note that the decompressor output side may not use
   * any parameters that can change between scans.
   */

  /* Quantization and Huffman tables are carried forward across input
   * datastreams when processing abbreviated JPEG datastreams.
   */

  JQUANT_TBL * quant_tbl_ptrs[NUM_QUANT_TBLS];
  /* ptrs to coefficient quantization tables, or NULL if not defined */

  JHUFF_TBL * dc_huff_tbl_ptrs[NUM_HUFF_TBLS];
  JHUFF_TBL * ac_huff_tbl_ptrs[NUM_HUFF_TBLS];
  /* ptrs to Huffman coding tables, or NULL if not defined */

  /* These parameters are never carried across datastreams, since they
   * are given in SOF/SOS markers or defined to be reset by SOI.
   */

  int data_precision;		/* bits of precision in image data */

  jpeg_component_info * comp_info;
  /* comp_info[i] describes component that appears i'th in SOF */

  Boolean progressive_mode;	/* TRUE if SOFn specifies progressive mode */
  Boolean arith_code;		/* TRUE=arithmetic coding, FALSE=Huffman */

  UINT8 arith_dc_L[NUM_ARITH_TBLS]; /* L values for DC arith-coding tables */
  UINT8 arith_dc_U[NUM_ARITH_TBLS]; /* U values for DC arith-coding tables */
  UINT8 arith_ac_K[NUM_ARITH_TBLS]; /* Kx values for AC arith-coding tables */

  unsigned int restart_interval; /* MCUs per restart interval, or 0 for no restart */

  /* These fields record data obtained from optional markers recognized by
   * the JPEG library.
   */
  Boolean saw_JFIF_marker;	/* TRUE if a JFIF APP0 marker was found */
  /* Data copied from JFIF marker: */
  UINT8 density_unit;		/* JFIF code for pixel size units */
  UINT16 X_density;		/* Horizontal pixel density */
  UINT16 Y_density;		/* Vertical pixel density */
  Boolean saw_Adobe_marker;	/* TRUE iff an Adobe APP14 marker was found */
  UINT8 Adobe_transform;	/* Color transform code from Adobe marker */

  Boolean CCIR601_sampling;	/* TRUE=first samples are cosited */

  /* Remaining fields are known throughout decompressor, but generally
   * should not be touched by a surrounding application.
   */

  /*
   * These fields are computed during decompression startup
   */
  int max_h_samp_factor;	/* largest h_samp_factor */
  int max_v_samp_factor;	/* largest v_samp_factor */

  int min_DCT_scaled_size;	/* smallest DCT_scaled_size of any component */

  JDIMENSION total_iMCU_rows;	/* # of iMCU rows in image */
  /* The coefficient controller's input and output progress is measured in
   * units of "iMCU" (interleaved MCU) rows.  These are the same as MCU rows
   * in fully interleaved JPEG scans, but are used whether the scan is
   * interleaved or not.  We define an iMCU row as v_samp_factor DCT block
   * rows of each component.  Therefore, the IDCT output contains
   * v_samp_factor*DCT_scaled_size sample rows of a component per iMCU row.
   */

  JSAMPLE * sample_range_limit; /* table for fast range-limiting */

  /*
   * These fields are valid during any one scan.
   * They describe the components and MCUs actually appearing in the scan.
   * Note that the decompressor output side must not use these fields.
   */
  int comps_in_scan;		/* # of JPEG components in this scan */
  jpeg_component_info * cur_comp_info[MAX_COMPS_IN_SCAN];
  /* *cur_comp_info[i] describes component that appears i'th in SOS */

  JDIMENSION MCUs_per_row;	/* # of MCUs across the image */
  JDIMENSION MCU_rows_in_scan;	/* # of MCU rows in the image */

  int blocks_in_MCU;		/* # of DCT blocks per MCU */
  int MCU_membership[D_MAX_BLOCKS_IN_MCU];
  /* MCU_membership[i] is index in cur_comp_info of component owning */
  /* i'th block in an MCU */

  int Ss, Se, Ah, Al;		/* progressive JPEG parameters for scan */

  /* This field is shared between entropy decoder and marker parser.
   * It is either zero or the code of a JPEG marker that has been
   * read from the data source, but has not yet been processed.
   */
  int unread_marker;

  /*
   *  Global error code. Set if anything causes an exit condition.
   *  If set, most functions will return immediately.
   */
      int error;
};
#define jpeg_decompress_struct fjpeg_decompress_struct

typedef struct jpeg_decompress_struct * fj_decompress_ptr;
#define j_decompress_ptr fj_decompress_ptr

/*
 * Function Prototypes
 */

/*
 *  These function header suffixes are changed to fjpeg to avoid
 *  conflicts with using FJPEG and IJGJPEG the same time.
 *	The defines at the end make sure that the source is still compatible.
 *  Including ijgjpeg.h and fjpeg.h into the same module is not allowed.
 *  FR 00/06/10
 */
void _pascal fjpeg_create_decompress (j_decompress_ptr cinfo);
void _pascal fjpeg_stdio_src (j_decompress_ptr cinfo, FILE * infile);
int  _pascal fjpeg_read_header (j_decompress_ptr cinfo);
/* Return value is one of: */
#define JPEG_UNSUPPORTED    0 /* Suspended due to lack of input data */
#define JPEG_HEADER_OK	    1 /* Found valid image datastream */
Boolean _pascal fjpeg_start_decompress (j_decompress_ptr cinfo);
JDIMENSION _pascal fjpeg_read_scanlines (j_decompress_ptr cinfo,
					JSAMPARRAY scanlines,
					JDIMENSION max_lines);
void _pascal fjpeg_destroy_decompress (j_decompress_ptr cinfo);

void far * _pascal smalloc (j_decompress_ptr cinfo, size_t size);
JSAMPARRAY _pascal fjpeg_smallocarr (j_decompress_ptr cinfo, size_t size, int elements);
void _pascal fjpeg_smfree (j_decompress_ptr cinfo, void far * far * ptr);


#if PROGRESS_DISPLAY
/* set pointer to load progress data */
void _pascal fjpeg_init_loadProgress(j_decompress_ptr cinfo,
					 LoadProgressData * loadProgressDataP);
#endif

#define jpeg_create_decompress(cinfo)	fjpeg_create_decompress(cinfo)
#define jpeg_stdio_src(cinfo,infile)	fjpeg_stdio_src(cinfo,infile)
#define jpeg_read_header(cinfo)			fjpeg_read_header(cinfo)
#define jpeg_start_decompress(cinfo)	fjpeg_start_decompress(cinfo)
#define jpeg_read_scanlines(cinfo,scanlines,max_lines) \
										fjpeg_read_scanlines(cinfo,scanlines,max_lines)
#define jpeg_destroy_decompress(cinfo)	fjpeg_destroy_decompress(cinfo)
#define smallocarr(cinfo,size,elements) \
										fjpeg_smallocarr(cinfo,size,elements)
#define smfree(cinfo,ptr)				fjpeg_smfree(cinfo,ptr)
#define jpeg_init_loadProgress(cinfo,loadProgressDataP) \
										fjpeg_init_loadProgress(cinfo,loadProgressDataP)


/* Additional entry points for buffered-image mode. ??? */
/*
EXTERN(Boolean) jpeg_has_multiple_scans JPP((j_decompress_ptr cinfo));
EXTERN(Boolean) jpeg_start_output JPP((j_decompress_ptr cinfo,
				       int scan_number));
EXTERN(Boolean) jpeg_finish_output JPP((j_decompress_ptr cinfo));
EXTERN(Boolean) jpeg_input_complete JPP((j_decompress_ptr cinfo));
EXTERN(void) jpeg_new_colormap JPP((j_decompress_ptr cinfo));
EXTERN(int) jpeg_consume_input JPP((j_decompress_ptr cinfo));
*/
/* Return value is one of: */
#define JPEG_SUSPENDED          0 /* nothing was done (only happens when jpeg_consume_input was called directly) */
#define JPEG_REACHED_SOS	1 /* Reached start of new scan */
#define JPEG_REACHED_EOI	2 /* Reached end of image */
#define JPEG_ROW_COMPLETED	3 /* Completed one iMCU row */
#define JPEG_SCAN_COMPLETED	4 /* Completed last iMCU row of a scan */


#define JMESSAGE(code,string)	code ,
typedef enum {
JMESSAGE(NO_ERROR, "All is well")
JMESSAGE(SYSTEM_ERROR_MESSAGES,         "GEOS System fatal error")
/* For maintenance convenience, list is alphabetical by message code name */
JMESSAGE(JERR_ARITH_NOTIMPL,     "Sorry, there are legal restrictions on arithmetic coding")
JMESSAGE(JERR_BAD_ALIGN_TYPE,    "ALIGN_TYPE is wrong, please fix")
JMESSAGE(JERR_BAD_ALLOC_CHUNK,   "MAX_ALLOC_CHUNK is wrong, please fix")
JMESSAGE(JERR_BAD_BUFFER_MODE,   "Bogus buffer control mode")
JMESSAGE(JERR_BAD_COMPONENT_ID,  "Invalid component ID %d in SOS")
JMESSAGE(JERR_BAD_DCTSIZE,       "IDCT output block size %d not supported")
JMESSAGE(JERR_BAD_IN_COLORSPACE, "Bogus input colorspace")
JMESSAGE(JERR_BAD_J_COLORSPACE,  "Bogus JPEG colorspace")
JMESSAGE(JERR_BAD_LENGTH,        "Bogus marker length")
JMESSAGE(JERR_BAD_MCU_SIZE,      "Sampling factors too large for interleaved scan")
JMESSAGE(JERR_BAD_POOL_ID,       "Invalid memory pool code %d")
JMESSAGE(JERR_BAD_PRECISION,     "Unsupported JPEG data precision %d")
JMESSAGE(JERR_BAD_PROGRESSION,   "Invalid progressive parameters Ss=%d Se=%d Ah=%d Al=%d")
JMESSAGE(JERR_BAD_PROG_SCRIPT,   "Invalid progressive parameters at scan script entry %d")
JMESSAGE(JERR_BAD_SAMPLING,      "Bogus sampling factors")
JMESSAGE(JERR_BAD_SCAN_SCRIPT,   "Invalid scan script at entry %d")
JMESSAGE(JERR_BAD_STATE,         "Improper call to JPEG library in state %d")
JMESSAGE(JERR_BAD_STRUCT_SIZE,   "JPEG parameter struct mismatch: library thinks size is %u, caller expects %u")
JMESSAGE(JERR_BAD_VIRTUAL_ACCESS,"Bogus virtual array access")
JMESSAGE(JERR_BUFFER_SIZE,       "Buffer passed to JPEG library is too small")
JMESSAGE(JERR_CANT_SUSPEND,      "Suspension not allowed here")
JMESSAGE(JERR_CCIR601_NOTIMPL,   "CCIR601 sampling not implemented yet")
JMESSAGE(JERR_NO_PROGRESSIVE,    "Progressive Jpeg not supported yet")
JMESSAGE(JERR_NO_USMERGE,        "upsample merging not supported yet")
JMESSAGE(JERR_COMPONENT_COUNT,   "Too many color components: %d, max %d")
JMESSAGE(JERR_CONVERSION_NOTIMPL,"Unsupported color conversion request")
JMESSAGE(JERR_DAC_INDEX,         "Bogus DAC index %d")
JMESSAGE(JERR_DAC_VALUE,         "Bogus DAC value 0x%x")
JMESSAGE(JERR_DHT_COUNTS,        "Bogus DHT counts")
JMESSAGE(JERR_DHT_INDEX,         "Bogus DHT index %d")
JMESSAGE(JERR_DQT_INDEX,         "Bogus DQT index %d")
JMESSAGE(JERR_EMPTY_IMAGE,       "Empty JPEG image (DNL not supported)")
JMESSAGE(JERR_EOI_EXPECTED,      "Didn't expect more than one scan")
JMESSAGE(JERR_FILE_READ,         "Input file read error")
JMESSAGE(JERR_FILE_WRITE,        "Output file write error --- out of disk space?")
JMESSAGE(JERR_FRACT_SAMPLE_NOTIMPL,"Fractional sampling not implemented yet")
JMESSAGE(JERR_HUFF_CLEN_OVERFLOW, "Huffman code size table overflow")
JMESSAGE(JERR_HUFF_MISSING_CODE, "Missing Huffman code table entry")
JMESSAGE(JERR_IMAGE_TOO_BIG,     "Maximum supported image dimension is %u pixels")
JMESSAGE(JERR_INPUT_EMPTY,       "Empty input file")
JMESSAGE(JERR_INPUT_EOF,         "Premature end of input file")
JMESSAGE(JERR_MISMATCHED_QUANT_TABLE,"Cannot transcode due to multiple use of quantization table %d")
JMESSAGE(JERR_MISSING_DATA,      "Scan script does not transmit all data")
JMESSAGE(JERR_MODE_CHANGE,       "Invalid color quantization mode change")
JMESSAGE(JERR_NOTIMPL,           "Not implemented yet")
JMESSAGE(JERR_NO_BACKING_STORE,  "Backing store not supported")
JMESSAGE(JERR_NO_HUFF_TABLE,     "Huffman table 0x%02x was not defined")
JMESSAGE(JERR_NO_IMAGE,          "JPEG datastream contains no image")
JMESSAGE(JERR_NO_QUANT_TABLE,    "Quantization table 0x%02x was not defined")
JMESSAGE(JERR_NO_SOI,            "Not a JPEG file: starts with 0x%02x 0x%02x")
JMESSAGE(JERR_OUT_OF_MEMORY,     "Insufficient memory (case %d)")
JMESSAGE(JERR_SOF_DUPLICATE,     "Invalid JPEG file structure: two SOF markers")
JMESSAGE(JERR_SOF_NO_SOS,        "Invalid JPEG file structure: missing SOS marker")
JMESSAGE(JERR_SOF_UNSUPPORTED,   "Unsupported JPEG process: SOF type 0x%02x")
JMESSAGE(JERR_SOI_DUPLICATE,     "Invalid JPEG file structure: two SOI markers")
JMESSAGE(JERR_SOS_NO_SOF,        "Invalid JPEG file structure: SOS before SOF")
JMESSAGE(JERR_TFILE_CREATE,      "Failed to create temporary file %s")
JMESSAGE(JERR_TFILE_READ,        "Read failed on temporary file")
JMESSAGE(JERR_TFILE_SEEK,        "Seek failed on temporary file")
JMESSAGE(JERR_TFILE_WRITE,       "Write failed on temporary file --- out of disk space?")
JMESSAGE(JERR_UNKNOWN_MARKER,    "Unsupported marker type 0x%02x")
JMESSAGE(JERR_VIRTUAL_BUG,       "Virtual array controller messed up")
JMESSAGE(JERR_WIDTH_OVERFLOW,    "Image too wide for this implementation")
JMESSAGE(JERR_MEMFREE,           "memory to be freed was not allocated")
JMESSAGE(JERR_MEMFULL,           "memory allocation failed")
JMESSAGE(JTRC_16BIT_TABLES,      "Caution: quantization tables are too coarse for baseline JPEG")
JMESSAGE(JTRC_ADOBE,             "Adobe APP14 marker: version %d, flags 0x%04x 0x%04x, transform %d")
JMESSAGE(JTRC_APP0,              "Unknown APP0 marker (not JFIF), length %u")
JMESSAGE(JTRC_APP14,             "Unknown APP14 marker (not Adobe), length %u")
JMESSAGE(JTRC_DAC,               "Define Arithmetic Table 0x%02x: 0x%02x")
JMESSAGE(JTRC_DHT,               "Define Huffman Table 0x%02x")
JMESSAGE(JTRC_DQT,               "Define Quantization Table %d  precision %d")
JMESSAGE(JTRC_DRI,               "Define Restart Interval %u")
JMESSAGE(JTRC_EOI,               "End Of Image")
JMESSAGE(JTRC_HUFFBITS,          "        %3d %3d %3d %3d %3d %3d %3d %3d")
JMESSAGE(JTRC_JFIF,              "JFIF APP0 marker, density %dx%d  %d")
JMESSAGE(JTRC_JFIF_BADTHUMBNAILSIZE, "Warning: thumbnail image size does not match data length %u")
JMESSAGE(JTRC_JFIF_MINOR,        "Unknown JFIF minor revision number %d.%02d")
JMESSAGE(JTRC_MISC_MARKER,       "Skipping marker 0x%02x, length %u")
JMESSAGE(JTRC_PARMLESS_MARKER,   "Unexpected marker 0x%02x")
JMESSAGE(JTRC_RECOVERY_ACTION,   "At marker 0x%02x, recovery action %d")
JMESSAGE(JTRC_RST,               "RST%d")
JMESSAGE(JTRC_SMOOTH_NOTIMPL,   "Smoothing not supported with nonstandard sampling ratios")
JMESSAGE(JTRC_SOF,               "Start Of Frame 0x%02x: width=%u, height=%u, components=%d")
JMESSAGE(JTRC_SOF_COMPONENT,     "    Component %d: %dhx%dv q=%d")
JMESSAGE(JTRC_SOI,               "Start of Image")
JMESSAGE(JTRC_SOS,               "Start Of Scan: %d components")
JMESSAGE(JTRC_SOS_COMPONENT,     "    Component %d: dc=%d ac=%d")
JMESSAGE(JTRC_SOS_PARAMS,        "  Ss=%d, Se=%d, Ah=%d, Al=%d")
JMESSAGE(JTRC_TFILE_CLOSE,       "Closed temporary file %s")
JMESSAGE(JTRC_TFILE_OPEN,        "Opened temporary file %s")
JMESSAGE(JTRC_UNKNOWN_IDS,       "Unrecognized component IDs %d %d %d, assuming YCbCr")
JMESSAGE(JWRN_ADOBE_XFORM,       "Unknown Adobe color transform code %d")
JMESSAGE(JWRN_BOGUS_PROGRESSION, "Inconsistent progression sequence for component %d coefficient %d")
JMESSAGE(JWRN_EXTRANEOUS_DATA,   "Corrupt JPEG data: %u extraneous bytes before marker 0x%02x")
JMESSAGE(JWRN_HIT_MARKER,        "Corrupt JPEG data: premature end of data segment")
JMESSAGE(JWRN_HUFF_BAD_CODE,     "Corrupt JPEG data: bad Huffman code")
JMESSAGE(JWRN_JFIF_MAJOR,        "Warning: unknown JFIF revision number %d.%02d")
JMESSAGE(JWRN_JPEG_EOF,          "Premature end of JPEG file")
JMESSAGE(JWRN_MUST_RESYNC,       "Corrupt JPEG data: found marker 0x%02x instead of RST%d")
JMESSAGE(JWRN_NOT_SEQUENTIAL,    "Invalid SOS parameters for sequential JPEG")
  JMSG_LASTMSGCODE
} FatalErrors;

typedef enum {			/* JPEG marker codes */
  M_SOF0  = 0xc0,
  M_SOF1  = 0xc1,
  M_SOF2  = 0xc2,
  M_SOF3  = 0xc3,

  M_SOF5  = 0xc5,
  M_SOF6  = 0xc6,
  M_SOF7  = 0xc7,

  M_JPG   = 0xc8,
  M_SOF9  = 0xc9,
  M_SOF10 = 0xca,
  M_SOF11 = 0xcb,

  M_SOF13 = 0xcd,
  M_SOF14 = 0xce,
  M_SOF15 = 0xcf,

  M_DHT   = 0xc4,

  M_DAC   = 0xcc,

  M_RST0  = 0xd0,
  M_RST1  = 0xd1,
  M_RST2  = 0xd2,
  M_RST3  = 0xd3,
  M_RST4  = 0xd4,
  M_RST5  = 0xd5,
  M_RST6  = 0xd6,
  M_RST7  = 0xd7,
  
  M_SOI   = 0xd8,
  M_EOI   = 0xd9,
  M_SOS   = 0xda,
  M_DQT   = 0xdb,
  M_DNL   = 0xdc,
  M_DRI   = 0xdd,
  M_DHP   = 0xde,
  M_EXP   = 0xdf,
  
  M_APP0  = 0xe0,
  M_APP1  = 0xe1,
  M_APP2  = 0xe2,
  M_APP3  = 0xe3,
  M_APP4  = 0xe4,
  M_APP5  = 0xe5,
  M_APP6  = 0xe6,
  M_APP7  = 0xe7,
  M_APP8  = 0xe8,
  M_APP9  = 0xe9,
  M_APP10 = 0xea,
  M_APP11 = 0xeb,
  M_APP12 = 0xec,
  M_APP13 = 0xed,
  M_APP14 = 0xee,
  M_APP15 = 0xef,
  
  M_JPG0  = 0xf0,
  M_JPG13 = 0xfd,
  M_COM   = 0xfe,
  
  M_TEM   = 0x01,
  
  M_ERROR = 0x100
} JPEG_MARKER;


#endif /* __FJPEG_H */
