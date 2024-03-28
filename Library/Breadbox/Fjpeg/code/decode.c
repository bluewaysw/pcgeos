
/***********************************************************************
 *
 *	Copyright (c) NewDeal Inc. 2000 -- All Rights Reserved
 *
 * PROJECT:     Fast JPEG Decompression Library
 * FILE:	decode.c
 * AUTHOR:	Jens-Michael Gross, July 31, 2000
 *
 * VERSIONS:
 *          00-07-31    JMG     Initial version
 *          00-09-04    JMG     final version for baseline jpeg.
 *
 *
 * DESCRIPTION:
 *
 * decompression module for the fast jpeg decompression library.
 *
 * this module is only called through jpeg_read_scanlines() and does not
 * call any other resources of the FJPEG library except for error conditions
 * or after finishing a decompression pass. Al memory should be already
 * allocated in the INIT or MAIN module.
 *
 * many of the functions here have to be duplicated in everz decompressor
 * module. They are naed with an _a extension. For those function called
 * by a macro, there are defines to be duplicated (with a different
 * extenstion) in every decompressor module, even if the macro itself
 * is defined globally.
 *
 * The code holds a lot of comments from the original IJGJPEG source code.
 ***********************************************************************/


#include "fjpeg.h"
#include "intern.h"
#include <geode.h>
#include <library.h>
/*#include <Ansi/stdlib.h>*/

/* local define, alows different fill functions in different decode modules */
#define FILL_INPUT_BUFFER fill_input_buffer_a
#define JPEG_FILL_BIT_BUFFER jpeg_fill_bit_buffer_a
#define JPEG_HUFF_DECODE jpeg_huff_decode_a



/* Scaling decisions are generally the same as in the LL&M algorithm;
 * see jidctint.c for more details.  However, we choose to descale
 * (right shift) multiplication products as soon as they are formed,
 * rather than carrying additional fractional bits into subsequent additions.
 * This compromises accuracy slightly, but it lets us save a few shifts.
 * More importantly, 16-bit arithmetic is then adequate (for 8-bit samples)
 * everywhere except in the multiplications proper; this saves a good deal
 * of work on 16-bit-int machines.
 *
 * The dequantized coefficients are not integers because the AA&N scaling
 * factors have been incorporated.  We represent them scaled up by PASS1_BITS,
 * so that the first and second IDCT rounds have the same input scaling.
 * For 8-bit JSAMPLEs, we choose IFAST_SCALE_BITS = PASS1_BITS so as to
 * avoid a descaling shift; this compromises accuracy rather drastically
 * for small quantization table entries, but it saves a lot of shifts.
 *
 * A final compromise is to represent the multiplicative constants to only
 * 8 fractional bits, rather than 13.  This saves some shifting work on some
 * machines, and may also reduce the cost of multiplication (since there
 * are fewer one-bits in the constants).
 */

#define CONST_BITS  8
#define PASS1_BITS  2

/* Some C compilers fail to reduce "FIX(constant)" at compile time, thus
 * causing a lot of useless floating-point operations at run time.
 * To get around this we use the following pre-calculated constants.
 * If you change CONST_BITS you may want to add appropriate values.
 * (With a reasonable C compiler, you can just rely on the FIX() macro...)
 */

#define FIX_1_082392200  ((INT32)  277)		/* FIX(1.082392200) */
#define FIX_1_414213562  ((INT32)  362)		/* FIX(1.414213562) */
#define FIX_1_847759065  ((INT32)  473)		/* FIX(1.847759065) */
#define FIX_2_613125930  ((INT32)  669)		/* FIX(2.613125930) */


/* We can gain a little more speed, with a further compromise in accuracy,
 * by omitting the addition in a descaling shift.  This yields an incorrectly
 * rounded result half the time...
 */

#ifndef USE_ACCURATE_ROUNDING
#undef DESCALE
#define DESCALE(x,n)  RIGHT_SHIFT(x, n)
#endif

#ifdef USE_ACCURATE_ROUNDING
#define IDESCALE(x,n)  ((int) IRIGHT_SHIFT((x) + (1 << ((n)-1)), n))
#else
#define IDESCALE(x,n)  ((int) IRIGHT_SHIFT(x, n))
#endif





/* On normal machines we can apply MEMCOPY() and MEMZERO() to sample arrays
 * and coefficient-block arrays.  This won't work on 80x86 because the arrays
 * are FAR and we're assuming a small-pointer memory model.  However, some
 * DOS compilers provide far-pointer versions of memcpy() and memset() even
 * in the small-model libraries.  These will be used if USE_FMEM is defined.
 * Otherwise, the routines below do it the hard way.  (The performance cost
 * is not all that great, because these routines aren't very heavily used.)
 */

void jcopy_sample_rows_a (JSAMPARRAY input_array, int source_row,
                          JSAMPARRAY output_array, int dest_row,
		          int num_rows, JDIMENSION num_cols)
/* Copy some rows of samples from one place to another.
 * num_rows rows are copied from input_array[source_row++]
 * to output_array[dest_row++]; these areas may overlap for duplication.
 * The source and destination arrays must be at least as wide as num_cols.
 */
{
  register JSAMPROW inptr, outptr;
  register JDIMENSION count;
  register int row;

  input_array += source_row;
  output_array += dest_row;

  for (row = num_rows; row > 0; row--) {
    inptr = *input_array++;
    outptr = *output_array++;
    for (count = num_cols; count > 0; count--)
      *outptr++ = *inptr++;	/* needn't bother with GETJSAMPLE() here */
  }
}


void jcopy_block_row_a (JBLOCKROW input_row, JBLOCKROW output_row,
		        JDIMENSION num_blocks)
/* Copy a row of coefficient blocks from one place to another. */
{
  register JCOEFPTR inptr, outptr;
  register long count;

  inptr = (JCOEFPTR) input_row;
  outptr = (JCOEFPTR) output_row;
  for (count = (long) num_blocks * DCTSIZE2; count > 0; count--) {
    *outptr++ = *inptr++;
  }
}


/* for some reason, GLUE creates a dummy entry into the reloc table, if there
 * are only 7 relocations (as there are in this resource)
 * this dummy function creates an eight reloc entry, and suddenly all is
 * well.
 */

void dummy (j_decompress_ptr cinfo)
{ start_input_pass(cinfo); }


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


Boolean fill_input_buffer_a (j_decompress_ptr cinfo)
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

Boolean jpeg_fill_bit_buffer_a (bitread_working_state * state,
		               register INT32 get_buffer,
                               register int bits_left,
		               int nbits)
/* Load up the bit buffer to a depth of at least nbits */
{
  /* Copy heavily used state fields into locals (hopefully registers) */
  register const JOCTET * next_input_byte = state->next_input_byte;
  register size_t bytes_in_buffer = state->bytes_in_buffer;
  register int c;

  /* Attempt to load at least MIN_GET_BITS bits into get_buffer. */
  /* (It is assumed that no request will be for more than that many bits.) */

  while (bits_left < MIN_GET_BITS) {
    /* Attempt to read a byte */
    if (state->unread_marker != 0)
      goto no_more_data;	/* can't advance past a marker */

    if (bytes_in_buffer == 0) {
      if (! fill_input_buffer_a(state->cinfo))
	return FALSE;
      next_input_byte = state->cinfo->src.next_input_byte;
      bytes_in_buffer = state->cinfo->src.bytes_in_buffer;
    }
    bytes_in_buffer--;
    c = GETJOCTET(*next_input_byte++);

    /* If it's 0xFF, check and discard stuffed zero byte */
    if (c == 0xFF) {
      do {
	if (bytes_in_buffer == 0) {
      if (! fill_input_buffer_a(state->cinfo))
	    return FALSE;
	  next_input_byte = state->cinfo->src.next_input_byte;
	  bytes_in_buffer = state->cinfo->src.bytes_in_buffer;
	}
	bytes_in_buffer--;
	c = GETJOCTET(*next_input_byte++);
      } while (c == 0xFF);

      if (c == 0) {
	/* Found FF/00, which represents an FF data byte */
	c = 0xFF;
      } else {
	/* Oops, it's actually a marker indicating end of compressed data. */
	/* Better put it back for use later */
	state->unread_marker = c;

      no_more_data:
	/* There should be enough bits still left in the data segment; */
	/* if so, just break out of the outer while loop. */
	if (bits_left >= nbits)
	  break;
	/* Uh-oh.  Report corrupted data to user and stuff zeroes into
	 * the data stream, so that we can produce some kind of image.
	 * Note that this code will be repeated for each byte demanded
	 * for the rest of the segment.  We use a nonvolatile flag to ensure
	 * that only one warning message appears.
	 */
	if (! *(state->printed_eod_ptr)) {
	  WARNMS(state->cinfo, JWRN_HIT_MARKER);
	  *(state->printed_eod_ptr) = TRUE;
	}
	c = 0;			/* insert a zero byte into bit buffer */
      }
    }

    /* OK, load c into get_buffer */
    get_buffer = (get_buffer << 8) | c;
    bits_left += 8;
  }

  /* Unload the local registers */
  state->next_input_byte = next_input_byte;
  state->bytes_in_buffer = bytes_in_buffer;
  state->get_buffer = get_buffer;
  state->bits_left = bits_left;

  return TRUE;
}



void start_iMCU_row_a (j_decompress_ptr cinfo)
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




int jpeg_huff_decode_a (bitread_working_state * state,
		        register INT32 get_buffer,
                        register int bits_left,
		        d_derived_tbl * htbl,
                        int min_bits)
{
  register int l = min_bits;
  register INT32 code;

  /* HUFF_DECODE has determined that the code is at least min_bits */
  /* bits long, so fetch that many bits in one swoop. */

  CHECK_BIT_BUFFER(*state, l, return -1);
  code = GET_BITS(l);

  /* Collect the rest of the Huffman code one bit at a time. */
  /* This is per Figure F.16 in the JPEG spec. */

  while (code > htbl->maxcode[l]) {
    code <<= 1;
    CHECK_BIT_BUFFER(*state, 1, return -1);
    code |= GET_BITS(1);
    l++;
  }

  /* Unload the local registers */
  state->get_buffer = get_buffer;
  state->bits_left = bits_left;

  /* With garbage input we may reach the sentinel value l = 17. */

  if (l > 16) {
    WARNMS(state->cinfo, JWRN_HUFF_BAD_CODE);
    return 0;			/* fake a zero as the safest result */
  }

  return htbl->pub->huffval[ htbl->valptr[l] +
			    ((int) (code - htbl->mincode[l])) ];
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

void skip_input_data_a (j_decompress_ptr cinfo, long num_bytes)
{
  /* Just a dumb implementation for now.  Could use fseek() except
   * it doesn't work on pipes.  Not clear that being smart is worth
   * any trouble anyway --- large skips are infrequent.
   */
  if (num_bytes > 0) {
    while (num_bytes > (long) cinfo->src.bytes_in_buffer) {
      num_bytes -= (long) cinfo->src.bytes_in_buffer;
      (void) fill_input_buffer_a (cinfo);
      /* note we assume that fill_input_buffer will never return FALSE,
       * so suspension need not be handled.
       */
    }
    cinfo->src.next_input_byte += (size_t) num_bytes;
    cinfo->src.bytes_in_buffer -= (size_t) num_bytes;
  }
}

/*
 * Perform dequantization and inverse DCT on one block of coefficients.
 */

void idct_ifast_a ( j_decompress_ptr cinfo,
                    jpeg_component_info * compptr,
		    JCOEFPTR coef_block,
		    JSAMPARRAY output_buf,
                    JDIMENSION output_col)
{
  int tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
  int tmp10, tmp11, tmp12, tmp13;
  int z5, z10, z11, z12, z13;
  JCOEFPTR inptr;
  int * quantptr;
  int * wsptr;
  JSAMPROW outptr;
  JSAMPLE *range_limit = IDCT_range_limit(cinfo);
  int ctr;
  int workspace[DCTSIZE2];	/* buffers data between passes */

  /* Pass 1: process columns from input, store into work array. */

  inptr = coef_block;
  quantptr = (int *) compptr->dct_table;
  wsptr = workspace;
  for (ctr = DCTSIZE; ctr > 0; ctr--) {
    /* Due to quantization, we will usually find that many of the input
     * coefficients are zero, especially the AC terms.  We can exploit this
     * by short-circuiting the IDCT calculation for any column in which all
     * the AC terms are zero.  In that case each output is equal to the
     * DC coefficient (with scale factor as needed).
     * With typical images and quantization tables, half or more of the
     * column DCT calculations can be simplified this way.
     */

    if ((inptr[DCTSIZE*1] | inptr[DCTSIZE*2] | inptr[DCTSIZE*3] |
	 inptr[DCTSIZE*4] | inptr[DCTSIZE*5] | inptr[DCTSIZE*6] |
	 inptr[DCTSIZE*7]) == 0) {
      /* AC terms all zero */
      int dcval = (int) DEQUANTIZE(inptr[DCTSIZE*0], quantptr[DCTSIZE*0]);

      wsptr[DCTSIZE*0] = dcval;
      wsptr[DCTSIZE*1] = dcval;
      wsptr[DCTSIZE*2] = dcval;
      wsptr[DCTSIZE*3] = dcval;
      wsptr[DCTSIZE*4] = dcval;
      wsptr[DCTSIZE*5] = dcval;
      wsptr[DCTSIZE*6] = dcval;
      wsptr[DCTSIZE*7] = dcval;
      
      inptr++;			/* advance pointers to next column */
      quantptr++;
      wsptr++;
      continue;
    }
    
    /* Even part */

    tmp0 = DEQUANTIZE(inptr[DCTSIZE*0], quantptr[DCTSIZE*0]);
    tmp1 = DEQUANTIZE(inptr[DCTSIZE*2], quantptr[DCTSIZE*2]);
    tmp2 = DEQUANTIZE(inptr[DCTSIZE*4], quantptr[DCTSIZE*4]);
    tmp3 = DEQUANTIZE(inptr[DCTSIZE*6], quantptr[DCTSIZE*6]);

    tmp10 = tmp0 + tmp2;	/* phase 3 */
    tmp11 = tmp0 - tmp2;

    tmp13 = tmp1 + tmp3;	/* phases 5-3 */
    tmp12 = MULTIPLY(tmp1 - tmp3, FIX_1_414213562) - tmp13; /* 2*c4 */

    tmp0 = tmp10 + tmp13;	/* phase 2 */
    tmp3 = tmp10 - tmp13;
    tmp1 = tmp11 + tmp12;
    tmp2 = tmp11 - tmp12;
    
    /* Odd part */

    tmp4 = DEQUANTIZE(inptr[DCTSIZE*1], quantptr[DCTSIZE*1]);
    tmp5 = DEQUANTIZE(inptr[DCTSIZE*3], quantptr[DCTSIZE*3]);
    tmp6 = DEQUANTIZE(inptr[DCTSIZE*5], quantptr[DCTSIZE*5]);
    tmp7 = DEQUANTIZE(inptr[DCTSIZE*7], quantptr[DCTSIZE*7]);

    z13 = tmp6 + tmp5;		/* phase 6 */
    z10 = tmp6 - tmp5;
    z11 = tmp4 + tmp7;
    z12 = tmp4 - tmp7;

    tmp7 = z11 + z13;		/* phase 5 */
    tmp11 = MULTIPLY(z11 - z13, FIX_1_414213562); /* 2*c4 */

    z5 = MULTIPLY(z10 + z12, FIX_1_847759065); /* 2*c2 */
    tmp10 = MULTIPLY(z12, FIX_1_082392200) - z5; /* 2*(c2-c6) */
    tmp12 = MULTIPLY(z10, - FIX_2_613125930) + z5; /* -2*(c2+c6) */

    tmp6 = tmp12 - tmp7;	/* phase 2 */
    tmp5 = tmp11 - tmp6;
    tmp4 = tmp10 + tmp5;

    wsptr[DCTSIZE*0] = (int) (tmp0 + tmp7);
    wsptr[DCTSIZE*7] = (int) (tmp0 - tmp7);
    wsptr[DCTSIZE*1] = (int) (tmp1 + tmp6);
    wsptr[DCTSIZE*6] = (int) (tmp1 - tmp6);
    wsptr[DCTSIZE*2] = (int) (tmp2 + tmp5);
    wsptr[DCTSIZE*5] = (int) (tmp2 - tmp5);
    wsptr[DCTSIZE*4] = (int) (tmp3 + tmp4);
    wsptr[DCTSIZE*3] = (int) (tmp3 - tmp4);

    inptr++;			/* advance pointers to next column */
    quantptr++;
    wsptr++;
  }
  
  /* Pass 2: process rows from work array, store into output array. */
  /* Note that we must descale the results by a factor of 8 == 2**3, */
  /* and also undo the PASS1_BITS scaling. */

  wsptr = workspace;
  for (ctr = 0; ctr < DCTSIZE; ctr++) {
    outptr = output_buf[ctr] + output_col;
    /* Rows of zeroes can be exploited in the same way as we did with columns.
     * However, the column calculation has created many nonzero AC terms, so
     * the simplification applies less often (typically 5% to 10% of the time).
     * On machines with very fast multiplication, it's possible that the
     * test takes more time than it's worth.  In that case this section
     * may be commented out.
     */
    
#ifndef NO_ZERO_ROW_TEST
    if ((wsptr[1] | wsptr[2] | wsptr[3] | wsptr[4] | wsptr[5] | wsptr[6] |
	 wsptr[7]) == 0) {
      /* AC terms all zero */
      JSAMPLE dcval = range_limit[IDESCALE(wsptr[0], PASS1_BITS+3)
				  & RANGE_MASK];
      
      outptr[0] = dcval;
      outptr[1] = dcval;
      outptr[2] = dcval;
      outptr[3] = dcval;
      outptr[4] = dcval;
      outptr[5] = dcval;
      outptr[6] = dcval;
      outptr[7] = dcval;

      wsptr += DCTSIZE;		/* advance pointer to next row */
      continue;
    }
#endif
    
    /* Even part */

    tmp10 = ((int) wsptr[0] + (int) wsptr[4]);
    tmp11 = ((int) wsptr[0] - (int) wsptr[4]);

    tmp13 = ((int) wsptr[2] + (int) wsptr[6]);
    tmp12 = MULTIPLY((int) wsptr[2] - (int) wsptr[6], FIX_1_414213562)
	    - tmp13;

    tmp0 = tmp10 + tmp13;
    tmp3 = tmp10 - tmp13;
    tmp1 = tmp11 + tmp12;
    tmp2 = tmp11 - tmp12;

    /* Odd part */

    z13 = (int) wsptr[5] + (int) wsptr[3];
    z10 = (int) wsptr[5] - (int) wsptr[3];
    z11 = (int) wsptr[1] + (int) wsptr[7];
    z12 = (int) wsptr[1] - (int) wsptr[7];

    tmp7 = z11 + z13;		/* phase 5 */
    tmp11 = MULTIPLY(z11 - z13, FIX_1_414213562); /* 2*c4 */

    z5 = MULTIPLY(z10 + z12, FIX_1_847759065); /* 2*c2 */
    tmp10 = MULTIPLY(z12, FIX_1_082392200) - z5; /* 2*(c2-c6) */
    tmp12 = MULTIPLY(z10, - FIX_2_613125930) + z5; /* -2*(c2+c6) */

    tmp6 = tmp12 - tmp7;	/* phase 2 */
    tmp5 = tmp11 - tmp6;
    tmp4 = tmp10 + tmp5;

    /* Final output stage: scale down by a factor of 8 and range-limit */

    outptr[0] = range_limit[IDESCALE(tmp0 + tmp7, PASS1_BITS+3)
			    & RANGE_MASK];
    outptr[7] = range_limit[IDESCALE(tmp0 - tmp7, PASS1_BITS+3)
			    & RANGE_MASK];
    outptr[1] = range_limit[IDESCALE(tmp1 + tmp6, PASS1_BITS+3)
			    & RANGE_MASK];
    outptr[6] = range_limit[IDESCALE(tmp1 - tmp6, PASS1_BITS+3)
			    & RANGE_MASK];
    outptr[2] = range_limit[IDESCALE(tmp2 + tmp5, PASS1_BITS+3)
			    & RANGE_MASK];
    outptr[5] = range_limit[IDESCALE(tmp2 - tmp5, PASS1_BITS+3)
			    & RANGE_MASK];
    outptr[4] = range_limit[IDESCALE(tmp3 + tmp4, PASS1_BITS+3)
			    & RANGE_MASK];
    outptr[3] = range_limit[IDESCALE(tmp3 - tmp4, PASS1_BITS+3)
			    & RANGE_MASK];

    wsptr += DCTSIZE;		/* advance pointer to next row */
  }
}



/*
 * Find the next JPEG marker, save it in cinfo->unread_marker.
 * Returns FALSE if had to suspend before reaching a marker;
 * in that case cinfo->unread_marker is unchanged.
 *
 * Note that the result might not be a valid marker code,
 * but it will never be 0 or FF.
 */

Boolean next_marker_a (j_decompress_ptr cinfo)
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


/*
 * This is the default resync_to_restart method for data source managers
 * to use if they don't have any better approach.  Some data source managers
 * may be able to back up, or may have additional knowledge about the data
 * which permits a more intelligent recovery strategy; such managers would
 * presumably supply their own resync method.
 *
 * read_restart_marker calls resync_to_restart if it finds a marker other than
 * the restart marker it was expecting.  (This code is *not* used unless
 * a nonzero restart interval has been declared.)  cinfo->unread_marker is
 * the marker code actually found (might be anything, except 0 or FF).
 * The desired restart marker number (0..7) is passed as a parameter.
 * This routine is supposed to apply whatever error recovery strategy seems
 * appropriate in order to position the input stream to the next data segment.
 * Note that cinfo->unread_marker is treated as a marker appearing before
 * the current data-source input point; usually it should be reset to zero
 * before returning.
 * Returns FALSE if suspension is required.
 *
 * This implementation is substantially constrained by wanting to treat the
 * input as a data stream; this means we can't back up.  Therefore, we have
 * only the following actions to work with:
 *   1. Simply discard the marker and let the entropy decoder resume at next
 *      byte of file.
 *   2. Read forward until we find another marker, discarding intervening
 *      data.  (In theory we could look ahead within the current bufferload,
 *      without having to discard data if we don't find the desired marker.
 *      This idea is not implemented here, in part because it makes behavior
 *      dependent on buffer size and chance buffer-boundary positions.)
 *   3. Leave the marker unread (by failing to zero cinfo->unread_marker).
 *      This will cause the entropy decoder to process an empty data segment,
 *      inserting dummy zeroes, and then we will reprocess the marker.
 *
 * #2 is appropriate if we think the desired marker lies ahead, while #3 is
 * appropriate if the found marker is a future restart marker (indicating
 * that we have missed the desired restart marker, probably because it got
 * corrupted).
 * We apply #2 or #3 if the found marker is a restart marker no more than
 * two counts behind or ahead of the expected one.  We also apply #2 if the
 * found marker is not a legal JPEG marker code (it's certainly bogus data).
 * If the found marker is a restart marker more than 2 counts away, we do #1
 * (too much risk that the marker is erroneous; with luck we will be able to
 * resync at some future point).
 * For any valid non-restart JPEG marker, we apply #3.  This keeps us from
 * overrunning the end of a scan.  An implementation limited to single-scan
 * files might find it better to apply #2 for markers other than EOI, since
 * any other marker would have to be bogus data in that case.
 */

Boolean resync_to_restart_a (j_decompress_ptr cinfo, int desired)
{
  int marker = cinfo->unread_marker;
  int action = 1;

  /* Always put up a warning. */
  WARNMS2(cinfo, JWRN_MUST_RESYNC, marker, desired);

  /* Outer loop handles repeated decision after scanning forward. */
  for (;;) {
    if (marker < (int) M_SOF0)
      action = 2;		/* invalid marker */
    else if (marker < (int) M_RST0 || marker > (int) M_RST7)
      action = 3;		/* valid non-restart marker */
    else {
      if (marker == ((int) M_RST0 + ((desired+1) & 7)) ||
	  marker == ((int) M_RST0 + ((desired+2) & 7)))
	action = 3;		/* one of the next two expected restarts */
      else if (marker == ((int) M_RST0 + ((desired-1) & 7)) ||
	       marker == ((int) M_RST0 + ((desired-2) & 7)))
	action = 2;		/* a prior restart, so advance */
      else
	action = 1;		/* desired restart or too far away */
    }
    TRACEMS2(cinfo, 4, JTRC_RECOVERY_ACTION, marker, action);
    switch (action) {
    case 1:
      /* Discard marker and let entropy decoder resume processing. */
      cinfo->unread_marker = 0;
      return TRUE;
    case 2:
      /* Scan to the next marker, and repeat the decision loop. */
      if (! next_marker_a(cinfo))
      {
	return FALSE;
      }
      marker = cinfo->unread_marker;
      break;
    case 3:
      /* Return without advancing past this marker. */
      /* Entropy decoder will be forced to process an empty segment. */
      return TRUE;
    }
  } /* end loop */
}




/*
 * Read a restart marker, which is expected to appear next in the datastream;
 * if the marker is not there, take appropriate recovery action.
 * Returns FALSE if suspension is required.
 *
 * This is called by the entropy decoder after it has read an appropriate
 * number of MCUs.  cinfo->unread_marker may be nonzero if the entropy decoder
 * has already read a marker from the data source.  Under normal conditions
 * cinfo->unread_marker will be reset to 0 before returning; if not reset,
 * it holds a marker which the decoder will be unable to read past.
 */

Boolean read_restart_marker_a (j_decompress_ptr cinfo)
{
  /* Obtain a marker unless we already did. */
  /* Note that next_marker will complain if it skips any data. */
  if (cinfo->unread_marker == 0) {
    if (! next_marker_a(cinfo))
      return FALSE;
  }

  if (cinfo->unread_marker ==
      ((int) M_RST0 + cinfo->marker.next_restart_num)) {
    /* Normal case --- swallow the marker and let entropy decoder continue */
    TRACEMS1(cinfo, 3, JTRC_RST, cinfo->marker->next_restart_num);
    cinfo->unread_marker = 0;
  } else {
    /* Uh-oh, the restart markers have been messed up. */
    /* Let the data source manager determine how to resync. */
    if (! resync_to_restart_a(cinfo, cinfo->marker.next_restart_num))
      return FALSE;
  }

  /* Update next-restart state */
  cinfo->marker.next_restart_num = (cinfo->marker.next_restart_num + 1) & 7;

  return TRUE;
}



/*
 * Check for a restart marker & resynchronize decoder.
 * Returns FALSE if must suspend.
 */

Boolean process_restart_a (j_decompress_ptr cinfo)
{
  int ci;

  /* Throw away any unused bits remaining in bit buffer; */
  /* include any full bytes in next_marker's count of discarded bytes */
  cinfo->marker.discarded_bytes += cinfo->entropy.bitstate.bits_left / 8;
  cinfo->entropy.bitstate.bits_left = 0;

  /* Advance past the RSTn marker */
    if (! read_restart_marker_a(cinfo) )
    return FALSE;

  /* Re-initialize DC predictions to 0 */
  for (ci = 0; ci < cinfo->comps_in_scan; ci++)
    cinfo->entropy.saved.last_dc_val[ci] = 0;

  /* Reset restart counter */
  cinfo->entropy.restarts_to_go = cinfo->restart_interval;

  /* Next segment can get another out-of-data warning */
  cinfo->entropy.bitstate.printed_eod = FALSE;

  return TRUE;
}


/*
 * Decode and return one MCU's worth of Huffman-compressed coefficients.
 * The coefficients are reordered from zigzag order into natural array order,
 * but are not dequantized.
 *
 * The i'th block of the MCU is stored into the block pointed to by
 * MCU_data[i].  WE ASSUME THIS AREA HAS BEEN ZEROED BY THE CALLER.
 * (Wholesale zeroing is usually a little faster than retail...)
 *
 * Returns FALSE if data source requested suspension.  In that case no
 * changes have been made to permanent state.  (Exception: some output
 * coefficients may already have been assigned.  This is harmless for
 * this module, since we'll just re-assign them on the next call.)
 */

Boolean decode_mcu_a (j_decompress_ptr cinfo, JBLOCKROW *MCU_data)
{
  register int s, k, r;
  int blkn, ci;
  JBLOCKROW block;
  BITREAD_STATE_VARS;
  jdhuff_savable_state state;
  d_derived_tbl * dctbl;
  d_derived_tbl * actbl;
  jpeg_component_info * compptr;

  /* Process restart marker if needed; may have to suspend */
  if (cinfo->restart_interval) {
    if (cinfo->entropy.restarts_to_go == 0)
      if (! process_restart_a(cinfo))
	return FALSE;
  }

  /* Load up working state */
  BITREAD_LOAD_STATE(cinfo, cinfo->entropy.bitstate);
  state= cinfo->entropy.saved;

  /* Outer loop handles each block in the MCU */

  for (blkn = 0; blkn < cinfo->blocks_in_MCU; blkn++) {
    block = MCU_data[blkn];
    ci = cinfo->MCU_membership[blkn];
    compptr = cinfo->cur_comp_info[ci];
    dctbl = cinfo->entropy.dc_derived_tbls[compptr->dc_tbl_no];
    actbl = cinfo->entropy.ac_derived_tbls[compptr->ac_tbl_no];

    /* Decode a single block's worth of coefficients */

    /* Section F.2.2.1: decode the DC coefficient difference */
    HUFF_DECODE(s, br_state, dctbl, return FALSE, label1);
    if (s) {
      CHECK_BIT_BUFFER(br_state, s, return FALSE);
      r = GET_BITS(s);
      s = HUFF_EXTEND(r, s);
    }

    /* Shortcut if component's values are not interesting */
    if (! compptr->component_needed)
      goto skip_ACs;

    /* Convert DC difference to actual value, update last_dc_val */
    s += state.last_dc_val[ci];
    state.last_dc_val[ci] = s;
    /* Output the DC coefficient (assumes jpeg_natural_order[0] = 0) */
    (*block)[0] = (JCOEF) s;

    /* Do we need to decode the AC coefficients for this component? */
    if (compptr->DCT_scaled_size > 1) {

      /* Section F.2.2.2: decode the AC coefficients */
      /* Since zeroes are skipped, output area must be cleared beforehand */
      for (k = 1; k < DCTSIZE2; k++) {
	HUFF_DECODE(s, br_state, actbl, return FALSE, label2);
      
	r = s >> 4;
	s &= 15;
      
	if (s) {
	  k += r;
	  CHECK_BIT_BUFFER(br_state, s, return FALSE);
	  r = GET_BITS(s);
	  s = HUFF_EXTEND(r, s);
	  /* Output coefficient in natural (dezigzagged) order.
	   * Note: the extra entries in jpeg_natural_order[] will save us
	   * if k >= DCTSIZE2, which could happen if the data is corrupted.
	   */
	  (*block)[jpeg_natural_order[k]] = (JCOEF) s;
	} else {
	  if (r != 15)
	    break;
	  k += 15;
	}
      }

    } else {
skip_ACs:

      /* Section F.2.2.2: decode the AC coefficients */
      /* In this path we just discard the values */
      for (k = 1; k < DCTSIZE2; k++) {
	HUFF_DECODE(s, br_state, actbl, return FALSE, label3);
      
	r = s >> 4;
	s &= 15;
      
	if (s) {
	  k += r;
	  CHECK_BIT_BUFFER(br_state, s, return FALSE);
	  DROP_BITS(s);
	} else {
	  if (r != 15)
	    break;
	  k += 15;
	}
      }

    }
  }

  /* Completed MCU, so update state */
  BITREAD_SAVE_STATE(cinfo,cinfo->entropy.bitstate);
  cinfo->entropy.saved= state;

  /* Account for restart interval (no-op if not using restarts) */
  cinfo->entropy.restarts_to_go--;

  return TRUE;
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

int decompress_onepass_a (j_decompress_ptr cinfo, JSAMPIMAGE output_buf)
{
  JDIMENSION MCU_col_num;	/* index of current MCU within row */
  JDIMENSION last_MCU_col = cinfo->MCUs_per_row - 1;
  JDIMENSION last_iMCU_row = cinfo->total_iMCU_rows - 1;
  int blkn, ci, xindex, yindex, yoffset, useful_width;
  JSAMPARRAY output_ptr;
  JDIMENSION start_col, output_col;
  jpeg_component_info *compptr;

  /* Loop to process as much as one whole iMCU row */
  for (yoffset = cinfo->coef.MCU_vert_offset; yoffset < cinfo->coef.MCU_rows_per_iMCU_row;
       yoffset++) {
    for (MCU_col_num = cinfo->coef.MCU_ctr; MCU_col_num <= last_MCU_col;
	 MCU_col_num++) {
      /* Try to fetch an MCU.  Entropy decoder expects buffer to be zeroed. */
      jzero_far((void far *) cinfo->coef.MCU_buffer[0],
		(size_t) (cinfo->blocks_in_MCU * sizeof(JBLOCK)));
      decode_mcu_a(cinfo, cinfo->coef.MCU_buffer);
      /* may never return FALSE (suspend condition) */

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
	useful_width = (MCU_col_num < last_MCU_col) ? compptr->MCU_width
						    : compptr->last_col_width;
	output_ptr = output_buf[ci] + yoffset * compptr->DCT_scaled_size;
	start_col = MCU_col_num * compptr->MCU_sample_width;
	for (yindex = 0; yindex < compptr->MCU_height; yindex++) {
	  if (cinfo->input_iMCU_row < last_iMCU_row ||
	      yoffset+yindex < compptr->last_row_height) {
	    output_col = start_col;
	    for (xindex = 0; xindex < useful_width; xindex++) {
              idct_ifast_a ( cinfo, compptr,
	                     (JCOEFPTR) cinfo->coef.MCU_buffer[blkn+xindex],
                             output_ptr,
                             output_col);
	      output_col += compptr->DCT_scaled_size;
	    }
	  }
	  blkn += compptr->MCU_width;
	  output_ptr += compptr->DCT_scaled_size;
	}
      }
    }
    /* Completed an MCU row, but perhaps not an iMCU row */
    cinfo->coef.MCU_ctr = 0;
  }
  /* Completed the iMCU row, advance counters for next one */
  cinfo->output_iMCU_row++;
  if (++(cinfo->input_iMCU_row) < cinfo->total_iMCU_rows) {
    start_iMCU_row_a(cinfo);
    return JPEG_ROW_COMPLETED;
  }
  /* Completed the scan */
  finish_input_pass(cinfo);
  return JPEG_SCAN_COMPLETED;
}



/*
 * Convert some rows of samples to the output colorspace.
 *
 * Note that we change from noninterleaved, one-plane-per-component format
 * to interleaved-pixel format.  The output buffer is therefore three times
 * as wide as the input buffer.
 * A starting row offset is provided only for the input buffer.  The caller
 * can easily adjust the passed output_buf value to accommodate any row
 * offset required on that side.
 */

void ycc_rgb_convert_a ( j_decompress_ptr cinfo,
		         JSAMPIMAGE input_buf, JDIMENSION input_row,
		         JSAMPARRAY output_buf, int num_rows)
{
  register int y, cb, cr;
  register JSAMPROW outptr;
  register JSAMPROW inptr0, inptr1, inptr2;
  register JDIMENSION col;
  JDIMENSION num_cols = cinfo->image_width;
  /* copy these pointers into registers if possible */
  register JSAMPLE * range_limit = cinfo->sample_range_limit;
  register int * Crrtab = cinfo->upsample.Cr_r_tab;
  register int * Cbbtab = cinfo->upsample.Cb_b_tab;
  register INT32 * Crgtab = cinfo->upsample.Cr_g_tab;
  register INT32 * Cbgtab = cinfo->upsample.Cb_g_tab;

  while (--num_rows >= 0) {
    inptr0 = input_buf[0][input_row];
    inptr1 = input_buf[1][input_row];
    inptr2 = input_buf[2][input_row];
    input_row++;
    outptr = *output_buf++;
    for (col = 0; col < num_cols; col++) {
      y  = GETJSAMPLE(inptr0[col]);
      cb = GETJSAMPLE(inptr1[col]);
      cr = GETJSAMPLE(inptr2[col]);
      /* Range-limiting is essential due to noise introduced by DCT losses. */
      outptr[RGB_RED] =   range_limit[y + Crrtab[cr]];
      outptr[RGB_GREEN] = range_limit[y +
			      ((int) RIGHT_SHIFT(Cbgtab[cb] + Crgtab[cr],
						 SCALEBITS))];
      outptr[RGB_BLUE] =  range_limit[y + Cbbtab[cb]];
      outptr += RGB_PIXELSIZE;
    }
  }
}

/*
 * Color conversion for no colorspace change: just copy the data,
 * converting from separate-planes to interleaved representation.
 */

void null_convert_a ( j_decompress_ptr cinfo,
	            JSAMPIMAGE input_buf, JDIMENSION input_row,
	            JSAMPARRAY output_buf, int num_rows)
{
  register JSAMPROW inptr, outptr;
  register JDIMENSION count;
  register int num_components = cinfo->num_components;
  JDIMENSION num_cols = cinfo->image_width;
  int ci;

  while (--num_rows >= 0) {
    for (ci = 0; ci < num_components; ci++) {
      inptr = input_buf[ci][input_row];
      outptr = output_buf[0] + ci;
      for (count = num_cols; count > 0; count--) {
	*outptr = *inptr++;	/* needn't bother with GETJSAMPLE() here */
	outptr += num_components;
      }
    }
    input_row++;
    output_buf++;
  }
}




/*
 * These are the routines invoked by sep_upsample to upsample pixel values
 * of a single component.  One row group is processed per call.
 */


/*
 * For full-size components, we just make color_buf[ci] point at the
 * input buffer, and thus avoid copying any data.  Note that this is
 * safe only because sep_upsample doesn't declare the input row group
 * "consumed" until we are done color converting and emitting it.
 */

void fullsize_upsample_a (JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr)
{
  *output_data_ptr = input_data;
}



/*
 * This is a no-op version used for "uninteresting" components.
 * These components will not be referenced by color conversion.
 */

void noop_upsample_a ( JSAMPARRAY * output_data_ptr)
{
  *output_data_ptr = NULL;	/* safety check */
}

/*
 * This version handles any integral sampling ratios.
 * This is not used for typical JPEG files, so it need not be fast.
 * Nor, for that matter, is it particularly accurate: the algorithm is
 * simple replication of the input pixel onto the corresponding output
 * pixels.  The hi-falutin sampling literature refers to this as a
 * "box filter".  A box filter tends to introduce visible artifacts,
 * so if you are actually going to use 3:1 or 4:1 sampling ratios
 * you would be well advised to improve this code.
 */

void int_upsample_a ( j_decompress_ptr cinfo, jpeg_component_info * compptr,
	              JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr)
{
  JSAMPARRAY output_data = *output_data_ptr;
  register JSAMPROW inptr, outptr;
  register JSAMPLE invalue;
  register int h;
  JSAMPROW outend;
  int h_expand, v_expand;
  int inrow, outrow;

  h_expand = cinfo->upsample.h_expand[compptr->component_index];
  v_expand = cinfo->upsample.v_expand[compptr->component_index];

  inrow = outrow = 0;
  while (outrow < cinfo->max_v_samp_factor) {
    /* Generate one output row with proper horizontal expansion */
    inptr = input_data[inrow];
    outptr = output_data[outrow];
    outend = outptr + cinfo->image_width;
    while (outptr < outend) {
      invalue = *inptr++;	/* don't need GETJSAMPLE() here */
      for (h = h_expand; h > 0; h--) {
	*outptr++ = invalue;
      }
    }
    /* Generate any additional output rows by duplicating the first one */
    if (v_expand > 1) {
      jcopy_sample_rows_a( output_data, outrow, output_data, outrow+1,
			   v_expand-1, cinfo->image_width);
    }
    inrow++;
    outrow += v_expand;
  }
}


/*
 * Fast processing for the common case of 2:1 horizontal and 1:1 vertical.
 * It's still a box filter.
 */

void h2v1_upsample_a ( j_decompress_ptr cinfo, jpeg_component_info * compptr,
	               JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr)
{
  JSAMPARRAY output_data = *output_data_ptr;
  register JSAMPROW inptr, outptr;
  register JSAMPLE invalue;
  JSAMPROW outend;
  int inrow;

  for (inrow = 0; inrow < cinfo->max_v_samp_factor; inrow++) {
    inptr = input_data[inrow];
    outptr = output_data[inrow];
    outend = outptr + cinfo->image_width;
    while (outptr < outend) {
      invalue = *inptr++;	/* don't need GETJSAMPLE() here */
      *outptr++ = invalue;
      *outptr++ = invalue;
    }
  }
}


/*
 * Fast processing for the common case of 2:1 horizontal and 2:1 vertical.
 * It's still a box filter.
 */

void h2v2_upsample_a ( j_decompress_ptr cinfo, jpeg_component_info * compptr,
	               JSAMPARRAY input_data, JSAMPARRAY * output_data_ptr)
{
  JSAMPARRAY output_data = *output_data_ptr;
  register JSAMPROW inptr, outptr;
  register JSAMPLE invalue;
  JSAMPROW outend;
  int inrow, outrow;

  inrow = outrow = 0;
  while (outrow < cinfo->max_v_samp_factor) {
    inptr = input_data[inrow];
    outptr = output_data[outrow];
    outend = outptr + cinfo->image_width;
    while (outptr < outend) {
      invalue = *inptr++;	/* don't need GETJSAMPLE() here */
      *outptr++ = invalue;
      *outptr++ = invalue;
    }
    jcopy_sample_rows_a( output_data, outrow, output_data, outrow+1,
		         1, cinfo->image_width);
    inrow++;
    outrow += 2;
  }
}



/*
 * Control routine to do upsampling (and color conversion).
 *
 * In this version we upsample each component independently.
 * We upsample one row group into the conversion buffer, then apply
 * color conversion a row at a time.
 */

void sep_upsample_a ( j_decompress_ptr cinfo,
                      JSAMPIMAGE input_buf,
                      JDIMENSION *in_row_group_ctr,
	              JDIMENSION in_row_groups_avail,
	              JSAMPARRAY output_buf,
                      JDIMENSION *out_row_ctr,
	              JDIMENSION out_rows_avail)
{
  int ci;
  jpeg_component_info * compptr;
  JDIMENSION num_rows;

  /* Fill the conversion buffer, if it's empty */
  if (cinfo->upsample.next_row_out >= cinfo->max_v_samp_factor) {
    for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
	 ci++, compptr++) {
      /* Invoke per-component upsample method.  Notice we pass a POINTER
       * to color_buf[ci], so that fullsize_upsample can change it.
       */
      switch(cinfo->upsample.methods[ci]) {
        case NU_NO_OP:
          noop_upsample_a ( cinfo->upsample.color_buf+ci );
          break;
        case NU_FULL_US:
          fullsize_upsample_a ( input_buf[ci] + (*in_row_group_ctr * cinfo->upsample.rowgroup_height[ci]),
                                cinfo->upsample.color_buf+ci );;
          break;
        case NU_21_US:
          h2v1_upsample_a ( cinfo, compptr,
                            input_buf[ci] + (*in_row_group_ctr * cinfo->upsample.rowgroup_height[ci]),
                            cinfo->upsample.color_buf+ci );;
          break;
        case NU_22_US:
          h2v2_upsample_a ( cinfo, compptr,
                            input_buf[ci] + (*in_row_group_ctr * cinfo->upsample.rowgroup_height[ci]),
                            cinfo->upsample.color_buf+ci );;
          break;
        case NU_INT_US:
          int_upsample_a ( cinfo, compptr,
                           input_buf[ci] + (*in_row_group_ctr * cinfo->upsample.rowgroup_height[ci]),
                           cinfo->upsample.color_buf+ci );;
          break;
        default:
          return;
     }

/*      MCALL(upsample1_ptr,
        (cinfo, compptr,
	input_buf[ci] + (*in_row_group_ctr * cinfo->upsample.rowgroup_height[ci]),
        cinfo->upsample.color_buf + ci, cinfo->upsample.methods[ci]));
*/
    }
    cinfo->upsample.next_row_out = 0;
  }

  /* Color-convert and emit rows */

  /* How many we have in the buffer: */
  num_rows = (JDIMENSION) (cinfo->max_v_samp_factor - cinfo->upsample.next_row_out);
  /* Not more than the distance to the end of the image.  Need this test
   * in case the image height is not a multiple of max_v_samp_factor:
   */
  if (num_rows > cinfo->upsample.rows_to_go)
    num_rows = cinfo->upsample.rows_to_go;
  /* And not more than what the client can accept: */
  out_rows_avail -= *out_row_ctr;
  if (num_rows > out_rows_avail)
    num_rows = out_rows_avail;

  if((cinfo->decomp_mode & DM_YCCRGB))
    ycc_rgb_convert_a ( cinfo, cinfo->upsample.color_buf,
		        (JDIMENSION) cinfo->upsample.next_row_out,
		        output_buf + *out_row_ctr,
		        (int) num_rows);

  else
    null_convert_a ( cinfo, cinfo->upsample.color_buf,
		     (JDIMENSION) cinfo->upsample.next_row_out,
		     output_buf + *out_row_ctr,
		     (int) num_rows);

  /* Adjust counts */
  *out_row_ctr += num_rows;
  cinfo->upsample.rows_to_go -= num_rows;
  cinfo->upsample.next_row_out += num_rows;
  /* When the buffer is emptied, declare this input row group consumed */
  if (cinfo->upsample.next_row_out >= cinfo->max_v_samp_factor)
    (*in_row_group_ctr)++;
}

/*
 * Process some data.
 * This handles the simple case where no context is required.
 */

void process_data_simple_main_a (j_decompress_ptr cinfo,
                                 JSAMPARRAY output_buf,
                                 JDIMENSION *out_row_ctr,
                                 JDIMENSION out_rows_avail)
{
  JDIMENSION rowgroups_avail;

  /* Read input data if we haven't filled the main buffer yet */
  if (! cinfo->main.buffer_full) {
    if (! decompress_onepass_a(cinfo, cinfo->main.buffer))
      return;			/* suspension forced, can do nothing more */
    cinfo->main.buffer_full = TRUE;	/* OK, we have an iMCU row to work with */
  }

  /* There are always min_DCT_scaled_size row groups in an iMCU row. */
  rowgroups_avail = (JDIMENSION) cinfo->min_DCT_scaled_size;
  /* Note: at the bottom of the image, we may pass extra garbage row groups
   * to the postprocessor.  The postprocessor has to check for bottom
   * of image anyway (at row resolution), so no point in us doing it too.
   */

  /* Feed the postprocessor */
  sep_upsample_a ( cinfo, cinfo->main.buffer,
                   &cinfo->main.rowgroup_ctr,
                   rowgroups_avail,
	           output_buf,
                   out_row_ctr,
                   out_rows_avail);
  /* Has postprocessor consumed all the data yet? If so, mark buffer empty */
  if (cinfo->main.rowgroup_ctr >= rowgroups_avail) {
    cinfo->main.buffer_full = FALSE;
    cinfo->main.rowgroup_ctr = 0;
  }
}




/*
 * Read some scanlines of data from the JPEG decompressor.
 *
 * The return value will be the number of lines actually read.
 * This may be less than the number requested in several cases,
 * including bottom of image, data source suspension, and operating
 * modes that emit multiple scanlines at a time.
 *
 * Note: we warn about excess calls to jpeg_read_scanlines() since
 * this likely signals an application programmer error.  However,
 * an oversize buffer (max_lines > scanlines remaining) is not an error.
 */

JDIMENSION _pascal jpeg_read_scanlines_a (j_decompress_ptr cinfo,
                                          JSAMPARRAY scanlines,
		                          JDIMENSION max_lines)
{
  JDIMENSION row_ctr;
  if (cinfo->global_state != DSTATE_SCANNING) {
    set_error (cinfo,JERR_BAD_STATE);
    return 0;
  }
  if (cinfo->output_scanline >= cinfo->image_height) {
    WARNMS(cinfo, JWRN_TOO_MUCH_DATA);
    return 0;
  }
  /* Process some data */
  row_ctr = 0;
  process_data_simple_main_a(cinfo, scanlines, &row_ctr, max_lines);
  cinfo->output_scanline += row_ctr;
  return row_ctr;
}

