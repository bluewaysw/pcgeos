/***********************************************************************
 *
 *	Copyright (c) NewDeal Inc. 2000 -- All Rights Reserved
 *
 * PROJECT:     Fast JPEG Decompression Library
 * FILE:	main.c
 * AUTHOR:	Jens-Michael Gross, July 28, 2000
 *
 * VERSIONS:
 *          00-07-28    JMG     Initial version
 *          00-09-04    JMG     Baseline JPEG finished
 *
 *
 * DESCRIPTION:
 *
 * Main module for the fast jpeg decompression library.
 *
 * All entrypoints are here. The given JPEG source is analyzed, the
 * proper decompression module is selected (if there will ever be more than
 * the initial RGB baseline module) and calls to JPEG_READ_SCANLINES are
 * forwarded to the proper decompressor.
 * For speed optimizations are all decompressors completely in one resource
 * and may have (certainly) duplicate code. While this wastes disk space,
 * it is definitely the fastest way to go(no inter-resource jumps) and
 * reduces memory usage as well as only one decompressor resource is needed
 * for a jpeg file.
 *
 * The code holds a lot of comments from the original IJGJPEG source code.
 ***********************************************************************/


#include "fjpeg.h"
#include "intern.h"
#include <geode.h>
#include <library.h>
#include <heap.h>
#include <Ansi/stdlib.h>
#include <Ansi/string.h>


/*
 * jpeg_natural_order[i] is the natural-order position of the i'th element
 * of zigzag order.
 *
 * When reading corrupted data, the Huffman decoders could attempt
 * to reference an entry beyond the end of this array (if the decoded
 * zero run length reaches past the end of the block).  To prevent
 * wild stores without adding an inner-loop test, we put some extra
 * "63"s after the real entries.  This will cause the extra coefficient
 * to be stored in location 63 of the block, not somewhere random.
 * The worst case would be a run-length of 15, which means we need 16
 * fake entries.
 */


const int jpeg_natural_order[DCTSIZE2+16] = {
  0,  1,  8, 16,  9,  2,  3, 10,
 17, 24, 32, 25, 18, 11,  4,  5,
 12, 19, 26, 33, 40, 48, 41, 34,
 27, 20, 13,  6,  7, 14, 21, 28,
 35, 42, 49, 56, 57, 50, 43, 36,
 29, 22, 15, 23, 30, 37, 44, 51,
 58, 59, 52, 45, 38, 31, 39, 46,
 53, 60, 61, 54, 47, 55, 62, 63,
 63, 63, 63, 63, 63, 63, 63, 63,
 63, 63, 63, 63, 63, 63, 63, 63
};
/* last two lines extra entries for safety in decoder */



const int jdhuff_extend_test[16] =   /* entry n is 2**(n-1) */
  { 0, 0x0001, 0x0002, 0x0004, 0x0008, 0x0010, 0x0020, 0x0040, 0x0080,
    0x0100, 0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000 };

const int jdhuff_extend_offset[16] = /* entry n is (-1 << n) + 1 */
  { 0, ((-1)<<1) + 1, ((-1)<<2) + 1, ((-1)<<3) + 1, ((-1)<<4) + 1,
    ((-1)<<5) + 1, ((-1)<<6) + 1, ((-1)<<7) + 1, ((-1)<<8) + 1,
    ((-1)<<9) + 1, ((-1)<<10) + 1, ((-1)<<11) + 1, ((-1)<<12) + 1,
    ((-1)<<13) + 1, ((-1)<<14) + 1, ((-1)<<15) + 1 };




//define CONST_BITS 14

static const INT16 jddctmgr_aanscales[DCTSIZE2] = {
  /* precomputed values scaled up by 14 bits */
  16384, 22725, 21407, 19266, 16384, 12873,  8867,  4520,
  22725, 31521, 29692, 26722, 22725, 17855, 12299,  6270,
  21407, 29692, 27969, 25172, 21407, 16819, 11585,  5906,
  19266, 26722, 25172, 22654, 19266, 15137, 10426,  5315,
  16384, 22725, 21407, 19266, 16384, 12873,  8867,  4520,
  12873, 17855, 16819, 15137, 12873, 10114,  6967,  3552,
   8867, 12299, 11585, 10426,  8867,  6967,  4799,  2446,
   4520,  6270,  5906,  5315,  4520,  3552,  2446,  1247
};


/* function to set error value. Intentionally not designed inline
 * to allow setting a breakpoint in SWAT
 */

void set_error (j_decompress_ptr cinfo, FatalErrors error_code)
{
  cinfo->error = error_code;
}


/*  smalloc() allocates a small amount of fixed memory. The amount allocated
 *  is 4 bytes larger than requested. These 4 bytes hold a pointer to the
 *  last allocated memorz area, the current top of this daisy-chain is
 *  stored in the memchain field of cinfo. The returned void far * points
 *  to the byte after the link pointer storage area, so that the calling
 *  function does not see a difference to a normal malloc.
 *  ensure that no more than 65530 bytes are requested at once.
 *
 *  the calling function should check for a valid (non-NULL) return value.
 */
void far * _pascal smalloc (j_decompress_ptr cinfo, size_t size)
{
  void far * far * ptr;
  ptr =  malloc (size+sizeof(ptr));
  if(ptr== NULL) {
    set_error(cinfo,JERR_MEMFULL);
    return ptr;
  }
  ptr[0]= cinfo->memchain;
  cinfo->memchain=ptr;
  return ptr+1;
}


/*  smallocarr() allocates an array of size*elements bytes. It returns a
 *  pointer to a table of pointers pointing to the starting points of each
 *  element.
 *  The current implementation allocates all memorz for the pointer table
 *  and the element space at once, saving maagement overhead and handles.
 *  For this reason, the maximum amount of memory requestable by this
 *  function may not exceed 65530 bytes, including 4*elemts bytes for the
 *  pointer table.
 *  Baseline jpeg does not request more than 48KB as the FJPEG lib only
 *  allows up to 2048 pixel width. (2Kpixel*3components*8rows buffer size)
 */
JSAMPARRAY _pascal fjpeg_smallocarr (j_decompress_ptr cinfo, size_t size, int elements)
{
  JSAMPARRAY ptr;
  int i;
  long total_size;
  total_size = (size*elements)+(sizeof(ptr)*elements);
  ptr = smalloc (cinfo, total_size);
  if(ptr== NULL) {
    set_error(cinfo,JERR_MEMFULL);
    return ptr;
  }
  for (i=0;i<elements;i++)
    ptr[i] = (void*)((long)ptr+(sizeof(ptr)*elements)+(i*size));
  return ptr;
}

/*  smfree() frees a memory portion previously allocated with smalloc().
 *  It will look down the memorz chain starting in cinfo->memchain to
 *  check for a valid free pointer before calling free().
 */
void _pascal fjpeg_smfree (j_decompress_ptr cinfo, void far * far * ptr)
{
  void far * far * ptr2;
  ptr--;
  if(cinfo->memchain ==NULL) {
    set_error(cinfo,JERR_MEMFREE);
    return;
  }
  if (cinfo->memchain ==ptr) {
    cinfo->memchain = cinfo->memchain[0];
    free(ptr);
    return;
  }
  ptr2 = cinfo->memchain;
  while ((ptr2[0]!=NULL)&&(ptr2[0]!=ptr)) {
    ptr2 = ptr2[0];
  }
  if (ptr2[0]==NULL) {
    set_error (cinfo, JERR_MEMFREE);
  } else {
    ptr2[0]=ptr[0];
    free(ptr);
  }
}

/* freeall() walks down the chain in cinfo->memchain and frees all memory
 * chunks allocated with smalloc() since jpeg_create_decompress() or last
 * freeall(). It is automatically caled by jpeg_destroy_decompress().
 */
void _pascal freeall (j_decompress_ptr cinfo)
{
   void far * far * ptr;
   while(cinfo->memchain!= NULL) {
     ptr = cinfo->memchain;
     cinfo->memchain = ptr[0];
     free (ptr);
   }
}

/*
 * Arithmetic utilities
 */

long jdiv_round_up (long a, long b)
/* Compute a/b rounded up to next integer, ie, ceil(a/b) */
/* Assumes a >= 0, b > 0 */
{
  return (a + b - 1L) / b;
}


long jround_up (long a, long b)
/* Compute a rounded up to next multiple of b, ie, ceil(a/b)*b */
/* Assumes a >= 0, b > 0 */
{
  a += b - 1L;
  return a - (a % b);
}


void jzero_far (void * target, size_t bytestozero)
/* Zero out a chunk of FAR memory. */
/* This might be sample-array data, block-array data, or alloc_large data. */
{
  register char * ptr = (char *) target;
  register size_t count;

  for (count = bytestozero; count > 0; count--) {
    *ptr++ = 0;
  }
}



/*  The lm...() functions are for allocating and accessing larger areas of
 *  memory. Baseline JPEG does not need them at all.
 *  currently, lmalloc() allocates a movable memory block, lmlock()/lmunlock()
 *  lock/unlock the block and lmptr returns a void far * to the locked block.
 *  the functions are more foolproof than the GESO functions, as lmptr()
 *  automatically locks a block if it wasn't locked, and lmfree() does all
 *  all necessary unlocks, while lmunlock() doesn't complain about excess
 *  calls. Of course this shouldn't be necessary for the final code, but
 *  makes work on the code easier.
 *  Since a full-sized jpeg picture (up to 2048*2048 are alowed for the FJPEG
 *  library) takes up to 2Kwidth*2Kheight*3components*2buffer = 24MB, these
 *  functions should be probably extended to VM files.
 */

Boolean lmalloc(int size, LargeMem * dest)
{
  dest->size = size;
  dest->locked = 0;
  dest->deref = NULL;
  dest->handle = MemAlloc(size,HF_SWAPABLE,0);
  if (dest->handle==NullHandle)
    return TRUE;
  return FALSE;
}

void lmlock (LargeMem * mem)
{
  if (mem->handle!=NullHandle) {
    if (!mem->locked) {
      mem->deref = MemLock(mem->handle);
    }
    mem->locked ++;
  }
}

void lmunlock(LargeMem * mem)
{
  if (mem->handle!=NullHandle) {
    mem->locked--;
    if (!mem->locked) {
      MemUnlock(mem->handle);
      mem->deref = NULL;
    }
  }
}

void * lmptr (LargeMem * mem)
{
  if (mem->handle!=NullHandle) {
    if (!mem->locked)
      // this should be an error condition!
      lmlock (mem);
    return mem->deref;
  } else {
    return NULL;
  }
}

void lmfree (LargeMem * mem)
{
  if (mem->handle!=NullHandle) {
    if (mem->locked) {
      mem->locked = 1;
      lmunlock(mem);
    }
    MemFree(mem->handle);
    mem->handle = NullHandle;
  }
}



/*
 * entry function, nothing to do here.
 */

#pragma argsused
Boolean _pascal FJPEGENTRY(LibraryCallType ty, GeodeHandle client)
{
    return FALSE;
}




/*
 * Initialize the input modules to read a scan of compressed data.
 * The first call to this is done by jdmaster.c after initializing
 * the entire decompressor (during jpeg_start_decompress).
 * Subsequent calls come from consume_markers, below.
 */

void start_input_pass (j_decompress_ptr cinfo)
{
  per_scan_setup(cinfo);
  latch_quant_tables(cinfo);
  start_pass_huff_decoder(cinfo);
  start_input_pass_jdcoefct (cinfo);
//  cinfo->inputctl->consume_input = cinfo->coef->consume_data;
}




/*
 * Finish up after inputting a compressed-data scan.
 * This is called by the coefficient controller after it's read all
 * the expected data of the scan.
 */

void finish_input_pass (j_decompress_ptr cinfo)
{
//  MASSIGN(cinfo->inputctl->consume_input, consume_markers);
}





/*
 * Initialize for a processing pass.
 */

void start_pass_main (j_decompress_ptr cinfo, J_BUF_MODE pass_mode)
{

  switch (pass_mode) {
  case JBUF_PASS_THRU:
    cinfo->main.buffer_full = FALSE;	/* Mark buffer empty */
    cinfo->main.rowgroup_ctr = 0;
    break;
  default:
    set_error(cinfo,JERR_BAD_BUFFER_MODE);
    return;
  }
}




/*
 * Prepare for an output pass.
 * Here we select the proper IDCT routine for each component and build
 * a matching multiplier table.
 */

void start_pass (j_decompress_ptr cinfo)
{
  int * ifmtbl;
  int ci, i;
  jpeg_component_info *compptr;
  JQUANT_TBL * qtbl;
  /* set to lib dgroup */
  PUSHDS;
  GeodeLoadDGroup(GeodeGetCodeProcessHandle());
  for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
       ci++, compptr++) {
    /* Create multiplier table from quant table.
     * However, we can skip this if the component is uninteresting
     * or if we already built the table.  Also, if no quant table
     * has yet been saved for the component, we leave the
     * multiplier table all-zero; we'll be reading zeroes from the
     * coefficient controller's buffer anyway.
     */
    ifmtbl = (int *) compptr->dct_table;
    if (! compptr->component_needed || cinfo->idct.cur_method[ci] == 1)
      continue;
    qtbl = compptr->quant_table;
    if (qtbl == NULL)		/* happens if no data yet for component */
      continue;
    cinfo->idct.cur_method[ci] = 1;
    /* For AA&N IDCT method, multipliers are equal to quantization
     * coefficients scaled by scalefactor[row]*scalefactor[col], where
     *   scalefactor[0] = 1
     *   scalefactor[k] = cos(k*PI/16) * sqrt(2)    for k=1..7
     * For integer operation, the multiplier table is to be scaled by
     * IFAST_SCALE_BITS.
     */
/*
	for (i = 0; i < DCTSIZE2; i++) {
	  ifmtbl[i] = (IFAST_MULT_TYPE)
	    DESCALE(MULTIPLY16V16((INT32) qtbl->quantval[i],
              (INT32) jddctmgr_aanscales[i]),
		    CONST_BITS-IFAST_SCALE_BITS);
*/
    for (i = 0; i < DCTSIZE2; i++) {
      ifmtbl[i] = (int)  DESCALE( MULTIPLY16V16((INT32) qtbl->quantval[i],
                                  (INT32) jddctmgr_aanscales[i]),
                                  12);
    }
  }
  /*back to appl dgroup*/
  POPDS;
}







/*
 * Set default decompression parameters.
 */

void default_decompress_parms(j_decompress_ptr cinfo)
{
  /* Guess the input colorspace, and set output colorspace accordingly. */
  /* (Wish JPEG committee had provided a real way to specify this...) */
  /* Note application may override our guesses. */
  switch (cinfo->num_components) {
  case 1:
    cinfo->jpeg_color_space = JCS_GRAYSCALE;
    break;

  case 3:
    if (cinfo->saw_JFIF_marker) {
      cinfo->jpeg_color_space = JCS_YCbCr; /* JFIF implies YCbCr */
    } else if (cinfo->saw_Adobe_marker) {
      switch (cinfo->Adobe_transform) {
      case 0:
	cinfo->jpeg_color_space = JCS_RGB;
	break;
      case 1:
	cinfo->jpeg_color_space = JCS_YCbCr;
	break;
      default:
	WARNMS1(cinfo, JWRN_ADOBE_XFORM, cinfo->Adobe_transform);
	cinfo->jpeg_color_space = JCS_YCbCr; /* assume it's YCbCr */
	break;
      }
    } else {
      /* Saw no special markers, try to guess from the component IDs */
      int cid0 = cinfo->comp_info[0].component_id;
      int cid1 = cinfo->comp_info[1].component_id;
      int cid2 = cinfo->comp_info[2].component_id;

      if (cid0 == 1 && cid1 == 2 && cid2 == 3)
	cinfo->jpeg_color_space = JCS_YCbCr; /* assume JFIF w/out marker */
      else if (cid0 == 82 && cid1 == 71 && cid2 == 66)
	cinfo->jpeg_color_space = JCS_RGB; /* ASCII 'R', 'G', 'B' */
      else {
	TRACEMS3(cinfo, 1, JTRC_UNKNOWN_IDS, cid0, cid1, cid2);
	cinfo->jpeg_color_space = JCS_YCbCr; /* assume it's YCbCr */
      }
    }
    break;

  default:
    cinfo->jpeg_color_space = JCS_UNKNOWN;
    break;
  }

  /* Set defaults for other decompression parameters. */
  cinfo->scale_num = 1;		/* 1:1 scaling */
  cinfo->scale_denom = 1;
  cinfo->buffered_image = FALSE;
  /* Initialize for no mode change in buffered-image mode. */
}






/*
 * Decompression startup: read start of JPEG datastream to see what's there.
 * Need only initialize JPEG object and supply a data source before calling.
 *
 * This routine will read as far as the first SOS marker (ie, actual start of
 * compressed data), and will save all tables and parameters in the JPEG
 * object.  It will also initialize the decompression parameters to default
 * values, and finally return JPEG_HEADER_OK.  On return, the application may
 * adjust the decompression parameters and then call jpeg_start_decompress.
 * (Or, if the application only wanted to determine the image parameters,
 * the data need not be decompressed.  In that case, call jpeg_abort or
 * jpeg_destroy to release any temporary space.)
 * If an abbreviated (tables only) datastream is presented, the routine will
 * return JPEG_HEADER_TABLES_ONLY upon reaching EOI.  The application may then
 * re-use the JPEG object to read the abbreviated image datastream(s).
 * It is unnecessary (but OK) to call jpeg_abort in this case.
 * The JPEG_SUSPENDED return code only occurs if the data source module
 * requests suspension of the decompressor.  In this case the application
 * should load more source data and then re-call jpeg_read_header to resume
 * processing.
 * If a non-suspending data source is used and require_image is TRUE, then the
 * return code need not be inspected since only JPEG_HEADER_OK is possible.
 *
 * This routine is now just a front end to jpeg_consume_input, with some
 * extra error checking.
 */


int jpeg_consume_input (j_decompress_ptr cinfo); // forward declaration
int  _pascal jpeg_read_header (j_decompress_ptr cinfo)
{
  int retcode;

  if (cinfo->global_state != DSTATE_START &&
      cinfo->global_state != DSTATE_INHEADER) {
      set_error(cinfo,JERR_BAD_STATE);
      return 0;
  }

  retcode = jpeg_consume_input(cinfo);

  switch (retcode) {
  case JPEG_REACHED_SOS:
    retcode = JPEG_HEADER_OK;
    break;
  case JPEG_REACHED_EOI:
    set_error(cinfo,JERR_NO_IMAGE);
    retcode = 0;
    break;
  }
  return retcode;
}


/*
 * Initialize source --- called by jpeg_read_header
 * before any data is actually read.
 */

void init_source (j_decompress_ptr cinfo)
{
  /* We reset the empty-input-file flag for each image,
   * but we don't clear the input buffer.
   * This is correct behavior for reading a series of images from one source.
   */
  cinfo->src.start_of_file = TRUE;
}

/*
 * Dummy consume-input routine for single-pass operation.
 */

int dummy_consume_data (j_decompress_ptr cinfo)
{
  return JPEG_SUSPENDED;	/* Always indicate nothing was done */
}

/*
 * Consume data in advance of what the decompressor requires.
 * This can be called at any time once the decompressor object has
 * been created and a data source has been set up.
 *
 * This routine is essentially a state machine that handles a couple
 * of critical state-transition actions, namely initial setup and
 * transition from header scanning to ready-for-start_decompress.
 * All the actual input is done via the input controller's consume_input
 * method.
 */

int jpeg_consume_input (j_decompress_ptr cinfo)
{
  int retcode = 0;

  /* NB: every possible DSTATE value should be listed in this switch */
  switch (cinfo->global_state) {
  case DSTATE_START:
    /* Start-of-datastream actions: reset appropriate modules */
    reset_input_controller(cinfo);
    /* Initialize application's data source module */
    init_source(cinfo);
    cinfo->global_state = DSTATE_INHEADER;
    /*FALLTHROUGH*/
  case DSTATE_INHEADER:
    retcode = consume_markers(cinfo);
    if (retcode == JPEG_REACHED_SOS) { /* Found SOS, prepare to decompress */
      /* Set up default parameters based on header data */
      default_decompress_parms(cinfo);
      /* Set global state: ready for start_decompress */
      cinfo->global_state = DSTATE_READY;
    }
    break;
  case DSTATE_READY:
    /* Can't advance past first SOS until start_decompress is called */
    retcode = JPEG_REACHED_SOS;
    break;
  case DSTATE_PRELOAD:
  case DSTATE_PRESCAN:
  case DSTATE_SCANNING:
  case DSTATE_RAW_OK:
  case DSTATE_BUFIMAGE:
  case DSTATE_BUFPOST:
  case DSTATE_STOPPING:
    /*  need switch for interlaced !
        for baseline, the variable used for the next call is originally
        set to dummy_consume_data after start_input_pass and reset to
        consume_markers after finish_input_pass.
        I wonder if it will do anything at all, as jpeg_consume_input is
        only called from jpeg_read_header and nowhere in baseline JPG
        decompression. Perhaps from interlaced. If so, this needs a change
        !!!
     */
    retcode = dummy_consume_data(cinfo);

    break;
  default:
    set_error(cinfo,JERR_BAD_STATE);
  }
  return retcode;
}

/*
 * Initialize for an output processing pass.
 */

void start_output_pass (j_decompress_ptr cinfo)
{
  cinfo->output_iMCU_row = 0;
}

/*
 * Initialize for an upsampling pass.
 */
void start_pass_upsample (j_decompress_ptr cinfo)
{
  /* Mark the conversion buffer empty */
  cinfo->upsample.next_row_out = cinfo->max_v_samp_factor;
  /* Initialize total-height counter for detecting bottom of image */
  cinfo->upsample.rows_to_go = cinfo->image_height;
}


/*
 * Per-pass setup.
 * This is called at the beginning of each output pass.  We determine which
 * modules will be active during this pass and give them appropriate
 * start_pass calls.
 */

void prepare_for_output_pass (j_decompress_ptr cinfo)
{
  start_pass(cinfo);  /* IDCT */
  start_output_pass(cinfo);  /* coefficient controller */
  start_pass_upsample(cinfo);
/* no post-processing, since we do not make color reduction
  start_pass_dpost(cinfo,(master->pub.is_dummy_pass ? JBUF_SAVE_AND_PASS : JBUF_PASS_THRU));
*/
  start_pass_main(cinfo, JBUF_PASS_THRU);
}



/*
 * Finish up at end of an output pass.
 */

void finish_output_pass (j_decompress_ptr cinfo)
{
  cinfo->master.pass_number++;
}




/*
 * Set up for an output pass, and perform any dummy pass(es) needed.
 * Common subroutine for jpeg_start_decompress and jpeg_start_output.
 * Entry: global_state = DSTATE_PRESCAN only if previously suspended.
 * Exit: If done, returns TRUE and sets global_state for proper output mode.
 */

Boolean output_pass_setup (j_decompress_ptr cinfo)
{
  if (cinfo->global_state != DSTATE_PRESCAN) {
    /* First call: do pass setup */
    prepare_for_output_pass(cinfo);
    cinfo->output_scanline = 0;
    cinfo->global_state = DSTATE_PRESCAN;
  }
  /* Ready for application to drive output pass through
   * jpeg_read_scanlines.
   */
  cinfo->global_state = DSTATE_SCANNING;
  return TRUE;
}






void _pascal fjpeg_create_decompress (j_decompress_ptr cinfo)
{
  jzero_far(cinfo, sizeof(struct jpeg_decompress_struct));
  cinfo->global_state = DSTATE_START;
}

void _pascal fjpeg_stdio_src (j_decompress_ptr cinfo, FILE * infile)
{
  cinfo->src.buffer = (JOCTET *) smalloc(cinfo, INPUT_BUF_SIZE * sizeof(JOCTET));
  cinfo->src.infile = infile;
  cinfo->src.bytes_in_buffer = 0; /* forces fill_input_buffer on first read */
  cinfo->src.next_input_byte = NULL; /* until buffer loaded */
  cinfo->src.loadProgressDataP = 0;
}




/*
 * Decompression initialization.
 * jpeg_read_header must be completed before calling this.
 *
 * If a multipass operating mode was selected, this will do all but the
 * last pass, and thus may take a great deal of time.
 *
 * Returns FALSE if suspended.  The return value need be inspected only if
 * a suspending data source is used.
 */

Boolean _pascal fjpeg_start_decompress (j_decompress_ptr cinfo)
{
  if (cinfo->global_state == DSTATE_READY) {
    /* First call: initialize master control, select active modules */
    master_selection(cinfo);
    if (cinfo->buffered_image) {
      /* No more work here; expecting jpeg_start_output next */
      cinfo->global_state = DSTATE_BUFIMAGE;
      return TRUE;
    }
    cinfo->global_state = DSTATE_PRELOAD;
  }
  if (cinfo->global_state == DSTATE_PRELOAD) {
    /* If file has multiple scans, absorb them all into the coef buffer */
    if (cinfo->inputctl.has_multiple_scans) {
#ifdef D_MULTISCAN_FILES_SUPPORTED

/*
 * this needs to be rewritten as soon as multiscan is supported
 */
      for (;;) {
	int retcode;
	/* Absorb some more input */
        retcode = MCALL1(consume_input, cinfo->inputctl, cinfo);
	if (retcode == JPEG_SUSPENDED)
        {
	  return FALSE;
        }
	if (retcode == JPEG_REACHED_EOI)
	  break;
	/* Advance progress counter if appropriate */
	if (cinfo->progress != NULL &&
	    (retcode == JPEG_ROW_COMPLETED || retcode == JPEG_REACHED_SOS)) {
	  if (++cinfo->progress->pass_counter >= cinfo->progress->pass_limit) {
	    /* jdmaster underestimated number of scans; ratchet up one scan */
	    cinfo->progress->pass_limit += (long) cinfo->total_iMCU_rows;
	  }
	}
      }
#else
      set_error(cinfo,JERR_NOTIMPL);
      return FALSE;
#endif /* D_MULTISCAN_FILES_SUPPORTED */
    }
    cinfo->output_scan_number = cinfo->input_scan_number;
  }
  else if (cinfo->global_state != DSTATE_PRESCAN) {
    set_error(cinfo,JERR_BAD_STATE);
    return FALSE;
  }
  /* Perform any dummy output passes, and set up for the final pass */

  return output_pass_setup(cinfo);
}








Boolean _pascal fjpeg_finish_decompress (j_decompress_ptr cinfo)
{
  return 0;
}


// free all allocated buffers
void _pascal fjpeg_destroy_decompress (j_decompress_ptr cinfo)
{
   freeall(cinfo);
}



JDIMENSION _pascal fjpeg_read_scanlines (j_decompress_ptr cinfo,
                                        JSAMPARRAY scanlines,
					JDIMENSION max_lines)
{
  volatile JDIMENSION retval;
  PUSHDS;
  GeodeLoadDGroup(GeodeGetCodeProcessHandle());

  /* need switch as soon as progressive supported !!! */

  retval = jpeg_read_scanlines_a (cinfo, scanlines, max_lines);

  POPDS;
  return retval;
}




