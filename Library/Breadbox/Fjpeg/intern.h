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
 *
 *
 * DESCRIPTION:
 *
 *	C include file for using the FJPEG library
 *
 *      This files contains declarations and definitions internal to the
 *      library
 *
 ***********************************************************************/

typedef enum {			/* Operating modes for buffer controllers */
	JBUF_PASS_THRU,		/* Plain stripwise operation */
	/* Remaining modes require a full-image buffer to have been created */
	JBUF_SAVE_SOURCE,	/* Run source subobject only, save output */
	JBUF_CRANK_DEST,	/* Run dest subobject only, using saved data */
	JBUF_SAVE_AND_PASS	/* Run both subobjects, save output */
} J_BUF_MODE;


/* Values of global_state field (jdapi.c has some dependencies on ordering!) */
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

#define JPEG_RST0	0xD0	/* RST0 marker code */
#define JPEG_EOI	0xD9	/* EOI marker code */
#define JPEG_APP0	0xE0	/* APP0 marker code */
#define JPEG_COM	0xFE	/* COM marker code */

#define RGB_RED		0	/* Offset of Red in an RGB scanline element */
#define RGB_GREEN	1	/* Offset of Green */
#define RGB_BLUE	2	/* Offset of Blue */
#define RGB_PIXELSIZE	3	/* JSAMPLEs per RGB scanline element */



#define WARNMS(cinfo,msg)
#define WARNMS1(cinfo,msg,value)
#define WARNMS2(cinfo,msg,v1,v2)


#define TRACEMS(cinfo,x,msg)
#define TRACEMS1(cinfo,x,msg,v1)
#define TRACEMS2(cinfo,x,msg,v1,v2)
#define TRACEMS3(cinfo,x,msg,v1,v2,v3)
#define TRACEMS4(cinfo,x,msg,v1,v2,v3,v4)
#define TRACEMS8(cinfo,x,msg,v1,v2,v3,v4,v5,v6,v7,v8)

/* Macros to deal with vptr-like objects. A vptr can either refer to a
   fixed/locked block, or to a movable memory block. */
#define VptrGetHandle(_seg) (MemHandle)(((_seg)<<4))
#define VptrMakeFromHandle(_mh) (word)(((_mh)>>4)|0xF000)
#define VptrIsLocked(_seg) (((_seg)&0xF000)!=0xF000)

/* Miscellaneous useful macros */
#undef MAX
#define MAX(a,b)	((a) > (b) ? (a) : (b))
#undef MIN
#define MIN(a,b)	((a) < (b) ? (a) : (b))

/* We assume that right shift corresponds to signed division by 2 with
 * rounding towards minus infinity.
 */
#define RIGHT_SHIFT(x,shft)	((x) >> (shft))
#define IRIGHT_SHIFT(x,shft)	((x) >> (shft))

/*
 * Macros for handling fixed-point arithmetic; these are used by many
 * but not all of the DCT/IDCT modules.
 *
 * All values are expected to be of type INT32.
 * Fractional constants are scaled left by CONST_BITS bits.
 * CONST_BITS is defined within each module using these macros,
 * and may differ from one module to the next.
 */

#define ONE	((INT32) 1)
#define CONST_SCALE (ONE << CONST_BITS)


/*
 * Each IDCT routine is responsible for range-limiting its results and
 * converting them to unsigned form (0..MAXJSAMPLE).  The raw outputs could
 * be quite far out of range if the input data is corrupt, so a bulletproof
 * range-limiting step is required.  We use a mask-and-table-lookup method
 * to do the combined operations quickly.  See the comments with
 * prepare_range_limit_table (in jdmaster.c) for more info.
 */

#define IDCT_range_limit(cinfo)  ((cinfo)->sample_range_limit + CENTERJSAMPLE)

#define RANGE_MASK  (MAXJSAMPLE * 4 + 3) /* 2 bits wider than legal samples */




/* Multiply a DCTELEM variable by an INT32 constant, and immediately
 * descale to yield a DCTELEM result.
 */

#define MULTIPLY(var,const)  ((int) DESCALE((var) * (const), CONST_BITS))

/* Dequantize a coefficient by multiplying it by the multiplier-table
 * entry; produce a DCTELEM result.  For 8-bit data a 16x16->16
 * multiplication will do.
 */
#define DEQUANTIZE(coef,quantval)  (((int) (coef)) * (quantval))

/* Descale and correctly round an INT32 value that's scaled by N bits.
 * We assume RIGHT_SHIFT rounds towards minus infinity, so adding
 * the fudge factor is correct for either sign of X.
 */

#define DESCALE(x,n)  RIGHT_SHIFT((x) + (ONE << ((n)-1)), n)

/* Multiply an INT32 variable by an INT32 constant to yield an INT32 result.
 * This macro is used only when the two inputs will actually be no more than
 * 16 bits wide, so that a 16x16->32 bit multiply can be used instead of a
 * full 32x32 multiply.  This provides a useful speedup on many machines.
 * Unfortunately there is no way to specify a 16x16->32 multiply portably
 * in C, but some C compilers will do the right thing if you provide the
 * correct combination of casts.
 */

#ifdef SHORTxSHORT_32		/* may work if 'int' is 32 bits */
#define MULTIPLY16C16(var,const)  (((INT16) (var)) * ((INT16) (const)))
#endif
#ifdef SHORTxLCONST_32		/* known to work with Microsoft C 6.0 */
#define MULTIPLY16C16(var,const)  (((INT16) (var)) * ((INT32) (const)))
#endif

#ifndef MULTIPLY16C16		/* default definition */
#define MULTIPLY16C16(var,const)  ((var) * (const))
#endif

/* Same except both inputs are variables. */

#ifdef SHORTxSHORT_32		/* may work if 'int' is 32 bits */
#define MULTIPLY16V16(var1,var2)  (((INT16) (var1)) * ((INT16) (var2)))
#endif

#ifndef MULTIPLY16V16		/* default definition */
#define MULTIPLY16V16(var1,var2)  ((var1) * (var2))
#endif


/*
 * Macros for fetching data from the data source module.
 *
 * At all times, cinfo->src->next_input_byte and ->bytes_in_buffer reflect
 * the current restart point; we update them only when we have reached a
 * suitable place to restart if a suspension occurs.
 */

#define MAKESTMT(stuff)		do { stuff } while (0)


/* Declare and initialize local copies of input pointer/count */
#define INPUT_VARS(cinfo)  \
	const JOCTET * next_input_byte = cinfo->src.next_input_byte;  \
	size_t bytes_in_buffer = cinfo->src.bytes_in_buffer

/* Unload the local copies --- do this only at a restart boundary */
#define INPUT_SYNC(cinfo)  \
	( cinfo->src.next_input_byte = next_input_byte,  \
	  cinfo->src.bytes_in_buffer = bytes_in_buffer )

/* Reload the local copies --- seldom used except in MAKE_BYTE_AVAIL */
#define INPUT_RELOAD(cinfo)  \
	( next_input_byte = cinfo->src.next_input_byte,  \
	  bytes_in_buffer = cinfo->src.bytes_in_buffer )

/* Internal macro for INPUT_BYTE and INPUT_2BYTES: make a byte available.
 * Note we do *not* do INPUT_SYNC before calling fill_input_buffer,
 * but we must reload the local copies after a successful fill.
 */
#define MAKE_BYTE_AVAIL(cinfo,action)  \
	if (bytes_in_buffer == 0) {  \
      if (! FILL_INPUT_BUFFER(cinfo))  \
	    { action; }  \
	  INPUT_RELOAD(cinfo);  \
	}  \
	bytes_in_buffer--

/* Read a byte into variable V.
 * If must suspend, take the specified action (typically "return FALSE").
 */
#define INPUT_BYTE(cinfo,V,action)  \
	MAKESTMT( MAKE_BYTE_AVAIL(cinfo,action); \
		  V = GETJOCTET(*next_input_byte++); )

/* As above, but read two bytes interpreted as an unsigned 16-bit integer.
 * V should be declared unsigned int or perhaps INT32.
 */
#define INPUT_2BYTES(cinfo,V,action)  \
	MAKESTMT( MAKE_BYTE_AVAIL(cinfo,action); \
		  V = ((unsigned int) GETJOCTET(*next_input_byte++)) << 8; \
		  MAKE_BYTE_AVAIL(cinfo,action); \
		  V += GETJOCTET(*next_input_byte++); )


/* merged_upsampler definitions */

#define SCALEBITS	16	/* speediest right-shift on some machines */
#define ONE_HALF	((INT32) 1 << (SCALEBITS-1))

/* Convert a positive real constant to an integer scaled by CONST_SCALE.
 * Caution: some C compilers fail to reduce "FIX(constant)" at compile time,
 * thus causing a lot of useless floating-point operations at run time.
 */

//define FIX(x)	((INT32) ((x) * CONST_SCALE + 0.5))
#define FIX(x)		((INT32) ((x) * (1L<<SCALEBITS) + 0.5))


/* Macros to declare and load/save bitread local variables. */
#define BITREAD_STATE_VARS  \
	register INT32 get_buffer;  \
	register int bits_left;  \
	bitread_working_state br_state

#define BITREAD_LOAD_STATE(cinfop,permstate)  \
	br_state.cinfo = cinfop; \
	br_state.next_input_byte = cinfop->src.next_input_byte; \
	br_state.bytes_in_buffer = cinfop->src.bytes_in_buffer; \
	br_state.unread_marker = cinfop->unread_marker; \
	get_buffer = permstate.get_buffer; \
	bits_left = permstate.bits_left; \
	br_state.printed_eod_ptr = & permstate.printed_eod

#define BITREAD_SAVE_STATE(cinfop,permstate)  \
	cinfop->src.next_input_byte = br_state.next_input_byte; \
	cinfop->src.bytes_in_buffer = br_state.bytes_in_buffer; \
	cinfop->unread_marker = br_state.unread_marker; \
	permstate.get_buffer = get_buffer; \
	permstate.bits_left = bits_left

/*
 * These macros provide the in-line portion of bit fetching.
 * Use CHECK_BIT_BUFFER to ensure there are N bits in get_buffer
 * before using GET_BITS, PEEK_BITS, or DROP_BITS.
 * The variables get_buffer and bits_left are assumed to be locals,
 * but the state struct might not be (jpeg_huff_decode needs this).
 *	CHECK_BIT_BUFFER(state,n,action);
 *		Ensure there are N bits in get_buffer; if suspend, take action.
 *      val = GET_BITS(n);
 *		Fetch next N bits.
 *      val = PEEK_BITS(n);
 *		Fetch next N bits without removing them from the buffer.
 *	DROP_BITS(n);
 *		Discard next N bits.
 * The value N should be a simple variable, not an expression, because it
 * is evaluated multiple times.
 */

#define MIN_GET_BITS  25

#define CHECK_BIT_BUFFER(state,nbits,action) \
	{ if (bits_left < (nbits)) {  \
	    if (! JPEG_FILL_BIT_BUFFER(&(state),get_buffer,bits_left,nbits))  \
	      { action; }  \
	    get_buffer = (state).get_buffer; bits_left = (state).bits_left; } }

#define GET_BITS(nbits) \
	(((int) (get_buffer >> (bits_left -= (nbits)))) & ((1<<(nbits))-1))

#define PEEK_BITS(nbits) \
	(((int) (get_buffer >> (bits_left -  (nbits)))) & ((1<<(nbits))-1))

#define DROP_BITS(nbits) \
	(bits_left -= (nbits))



/*
 * Code for extracting next Huffman-coded symbol from input bit stream.
 * Again, this is time-critical and we make the main paths be macros.
 *
 * We use a lookahead table to process codes of up to HUFF_LOOKAHEAD bits
 * without looping.  Usually, more than 95% of the Huffman codes will be 8
 * or fewer bits long.  The few overlength codes are handled with a loop,
 * which need not be inline code.
 *
 * Notes about the HUFF_DECODE macro:
 * 1. Near the end of the data segment, we may fail to get enough bits
 *    for a lookahead.  In that case, we do it the hard way.
 * 2. If the lookahead table contains no entry, the next code must be
 *    more than HUFF_LOOKAHEAD bits long.
 * 3. jpeg_huff_decode returns -1 if forced to suspend.
 */

#define HUFF_DECODE(result,state,htbl,failaction,slowlabel) \
{ register int nb, look; \
  if (bits_left < HUFF_LOOKAHEAD) { \
    if (! JPEG_FILL_BIT_BUFFER(&state,get_buffer,bits_left, 0)) {failaction;} \
    get_buffer = state.get_buffer; bits_left = state.bits_left; \
    if (bits_left < HUFF_LOOKAHEAD) { \
      nb = 1; goto slowlabel; \
    } \
  } \
  look = PEEK_BITS(HUFF_LOOKAHEAD); \
  if ((nb = htbl->look_nbits[look]) != 0) { \
    DROP_BITS(nb); \
    result = htbl->look_sym[look]; \
  } else { \
    nb = HUFF_LOOKAHEAD+1; \
slowlabel: \
    if ((result=JPEG_HUFF_DECODE(&state,get_buffer,bits_left,htbl,nb)) < 0) \
	{ failaction; } \
    get_buffer = state.get_buffer; bits_left = state.bits_left; \
  } \
}


#define HUFF_EXTEND(x,s)  ((x) < jdhuff_extend_test[s] ? (x) + jdhuff_extend_offset[s] : (x))


/* huffman decoder definitions */

typedef struct {		/* Bitreading working state within an MCU */
  /* current data source state */
  const JOCTET * next_input_byte; /* => next byte to read from source */
  size_t bytes_in_buffer;	/* # of bytes remaining in source buffer */
  int unread_marker;		/* nonzero if we have hit a marker */
  /* bit input buffer --- note these values are kept in register variables,
   * not in this struct, inside the inner loops.
   */
  INT32 get_buffer;	        /* current bit-extraction buffer */
  int bits_left;		/* # of unused bits in it */
  /* pointers needed by jpeg_fill_bit_buffer */
  j_decompress_ptr cinfo;	/* back link to decompress master record */
  Boolean * printed_eod_ptr;	/* => flag in permanent state */
} bitread_working_state;




/* idct definitions */
typedef struct {
  int ifast_array[DCTSIZE2];
} multiplier_table;

/* external data structures (defined in MAIN) */

extern const int jpeg_natural_order[DCTSIZE2+16];
extern const int jdhuff_extend_test[16];
extern const int jdhuff_extend_offset[16];
/*extern const INT16 jddctmgr_aanscales[DCTSIZE2];*/



/* functions in MAIN */
void jzero_far (void * target, size_t bytestozero);
Boolean lmalloc(int size, LargeMem * dest);
void lmlock (LargeMem * mem);
void lmunlock(LargeMem * mem);
void * lmptr (LargeMem * mem);
void lmfree (LargeMem * mem);
long jdiv_round_up (long a, long b);
long jround_up (long a, long b);
void set_error (j_decompress_ptr cinfo, FatalErrors error_code);
void start_input_pass (j_decompress_ptr cinfo);
void finish_input_pass (j_decompress_ptr cinfo);
void per_scan_setup(j_decompress_ptr cinfo);
void latch_quant_tables(j_decompress_ptr cinfo);
void start_pass_huff_decoder(j_decompress_ptr cinfo);
void start_input_pass_jdcoefct (j_decompress_ptr cinfo);

// functions in INIT
void master_selection (j_decompress_ptr cinfo);
int consume_markers (j_decompress_ptr cinfo);
void reset_input_controller (j_decompress_ptr cinfo);

// functions in DECOMP
JDIMENSION _pascal jpeg_read_scanlines_a (j_decompress_ptr cinfo, JSAMPARRAY scanlines, JDIMENSION max_lines);



/*
 * Macros to use Libary dgroup.
 */
#ifdef __HIGHC__

#ifndef PUSHDS
#define PUSHDS	_inline(0x1e)	/* push	ds */
#endif

#ifndef POPDS
#define POPDS	_inline(0x1f)	/* pop	ds */
#endif

#endif

#ifdef __BORLANDC__

#ifndef PUSHDS
#define PUSHDS  asm{push ds}
#endif

#ifndef POPDS
#define POPDS   asm{pop  ds}
#endif

#endif

#ifdef __WATCOMC__

#ifndef PUSHDS
void _PUSHDS();
#pragma aux _PUSHDS = "push ds";
#define PUSHDS  _PUSHDS();
#endif

#ifndef POPDS
void _POPDS();
#pragma aux _POPDS = "pop ds";
#define POPDS   _POPDS();
#endif

#endif
