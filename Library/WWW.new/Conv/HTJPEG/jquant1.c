/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		jquant1.c

AUTHOR:		Joon Song, Oct 29, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/29/95   	Initial version.

DESCRIPTION:
	

	$Id: jquant1.c,v 1.1.11.7 97/11/11 10:32:33 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 * jquant1.c
 *
 * Copyright (C) 1991-1995, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file contains 1-pass color quantization (color mapping) routines.
 * These routines provide mapping to a fixed color map using equally spaced
 * color values.  Optional Floyd-Steinberg or ordered dithering is available.
 */

#define JPEG_INTERNALS
#include <jinclude.h>
#include <jpeglib.h>


/*
 * The main purpose of 1-pass quantization is to provide a fast, if not very
 * high quality, colormapped output capability.  A 2-pass quantizer usually
 * gives better visual quality; however, for quantized grayscale output this
 * quantizer is perfectly adequate.  Dithering is highly recommended with this
 * quantizer, though you can turn it off if you really want to.
 *
 * In 1-pass quantization the colormap must be chosen in advance of seeing the
 * image.  We use a map consisting of all combinations of Ncolors[i] color
 * values for the i'th component.  The Ncolors[] values are chosen so that
 * their product, the total number of colors, is no more than that requested.
 * (In most cases, the product will be somewhat less.)
 *
 * Since the colormap is orthogonal, the representative value for each color
 * component can be determined without considering the other components;
 * then these indexes can be combined into a colormap index by a standard
 * N-dimensional-array-subscript calculation.  Most of the arithmetic involved
 * can be precalculated and stored in the lookup table colorindex[].
 * colorindex[i][j] maps pixel value j in component i to the nearest
 * representative value (grid plane) for that component; this index is
 * multiplied by the array stride for component i, so that the
 * index of the colormap entry closest to a given pixel value is just
 *    sum( colorindex[component-number][pixel-component-value] )
 * Aside from being fast, this scheme allows for variable spacing between
 * representative values with no additional lookup cost.
 *
 * If gamma correction has been applied in color conversion, it might be wise
 * to adjust the color grid spacing so that the representative colors are
 * equidistant in linear space.  At this writing, gamma correction is not
 * implemented by jdcolor, so nothing is done here.
 */


/* Declarations for Floyd-Steinberg dithering.
 *
 * Errors are accumulated into the array fserrors[], at a resolution of
 * 1/16th of a pixel count.  The error at a given pixel is propagated
 * to its not-yet-processed neighbors using the standard F-S fractions,
 *		...	(here)	7/16
 *		3/16	5/16	1/16
 * We work left-to-right on even rows, right-to-left on odd rows.
 *
 * We can get away with a single array (holding one row's worth of errors)
 * by using it to store the current row's errors at pixel columns not yet
 * processed, but the next row's errors at columns already processed.  We
 * need only a few extra variables to hold the errors immediately around the
 * current column.  (If we are lucky, those variables are in registers, but
 * even if not, they're probably cheaper to access than array elements are.)
 *
 * The fserrors[] array is indexed [component#][position].
 * We provide (#columns + 2) entries per component; the extra entry at each
 * end saves us from special-casing the first and last pixels.
 */

#if BITS_IN_JSAMPLE == 8
typedef INT16 FSERROR;		/* 16 bits should be enough */
typedef int LOCFSERROR;		/* use 'int' for calculation temps */
#else
typedef INT32 FSERROR;		/* may need more than 16 bits */
typedef INT32 LOCFSERROR;	/* be sure calculation temps are big enough */
#endif

typedef FSERROR *FSERRPTR;	/* pointer to error array */


/* Private subobject */

#define MAX_Q_COMPS 4		/* max components I can handle */

typedef struct {
  struct jpeg_color_quantizer pub; /* public fields */

  /* Initially allocated colormap is saved here */
  JSAMPARRAY sv_colormap;	/* The color map as a 2-D pixel array */
  int sv_actual;		/* number of entries in use */

  JSAMPARRAY colorindex;	/* Precomputed mapping for speed */
  /* colorindex[i][j] = index of color closest to pixel value j in component i,
   * premultiplied as described above.  Since colormap indexes must fit into
   * JSAMPLEs, the entries of this array will too.
   */
  int Ncolors[MAX_Q_COMPS];	/* # of values alloced to each component */

  /* Variables for Floyd-Steinberg dithering */
  FSERRPTR fserrors[MAX_Q_COMPS]; /* accumulated errors */
  boolean on_odd_row;		/* flag to remember which row we are on */
} my_cquantizer;

typedef my_cquantizer * my_cquantize_ptr;


/*
 * Policy-making subroutines for create_colormap and create_colorindex.
 * These routines determine the colormap to be used.  The rest of the module
 * only assumes that the colormap is orthogonal.
 *
 *  * select_ncolors decides how to divvy up the available colors
 *    among the components.
 *  * output_value defines the set of representative values for a component.
 *  * largest_input_value defines the mapping from input values to
 *    representative values for a component.
 * Note that the latter two routines may impose different policies for
 * different components, though this is not currently done.
 */


LOCAL int
select_ncolors (j_decompress_ptr cinfo, int Ncolors[])
/* Determine allocation of desired colors to components, */
/* and fill in Ncolors[] array to indicate choice. */
/* Return value is total number of colors (product of Ncolors[] values). */
{
  int nc = cinfo->out_color_components; /* number of color components */
  int max_colors = cinfo->desired_number_of_colors;
  int total_colors, iroot, i, j;
  boolean changed;
  long temp;
  static const int RGB_order[3] = { RGB_GREEN, RGB_RED, RGB_BLUE };

  /* We can allocate at least the nc'th root of max_colors per component. */
  /* Compute floor(nc'th root of max_colors). */
  iroot = 1;
  do {
    iroot++;
    temp = iroot;		/* set temp = iroot ** nc */
    for (i = 1; i < nc; i++)
      temp *= iroot;
  } while (temp <= (long) max_colors); /* repeat till iroot exceeds root */
  iroot--;			/* now iroot = floor(root) */

  /* Must have at least 2 color values per component */
  if (iroot < 2)
    ERREXIT1(cinfo, JERR_QUANT_FEW_COLORS, (int) temp);

  /* Initialize to iroot color values for each component */
  total_colors = 1;
  for (i = 0; i < nc; i++) {
    Ncolors[i] = iroot;
    total_colors *= iroot;
  }
  /* We may be able to increment the count for one or more components without
   * exceeding max_colors, though we know not all can be incremented.
   * Sometimes, the first component can be incremented more than once!
   * (Example: for 16 colors, we start at 2*2*2, go to 3*2*2, then 4*2*2.)
   * In RGB colorspace, try to increment G first, then R, then B.
   */
  do {
    changed = FALSE;
    for (i = 0; i < nc; i++) {
/*      j = (cinfo->out_color_space == JCS_RGB ? RGB_order[i] : i); */
      if(cinfo->out_color_space == JCS_RGB) 
	  j = RGB_order[i];
      else
	  j = i;

      /* calculate new total_colors if Ncolors[j] is incremented */
      temp = total_colors / Ncolors[j];
      temp *= Ncolors[j]+1;	/* done in long arith to avoid oflo */
      if (temp > (long) max_colors)
	break;			/* won't fit, done with this pass */
      Ncolors[j]++;		/* OK, apply the increment */
      total_colors = (int) temp;
      changed = TRUE;
    }
  } while (changed);

  return total_colors;
}


LOCAL int
output_value (j_decompress_ptr cinfo, int ci, int j, int maxj)
/* Return j'th output value, where j will range from 0 to maxj */
/* The output values must fall in 0..MAXJSAMPLE in increasing order */
{
  /* We always provide values 0 and MAXJSAMPLE for each component;
   * any additional values are equally spaced between these limits.
   * (Forcing the upper and lower values to the limits ensures that
   * dithering can't produce a color outside the selected gamut.)
   */
  return (int) (((INT32) j * MAXJSAMPLE + maxj/2) / maxj);
}


LOCAL int
largest_input_value (j_decompress_ptr cinfo, int ci, int j, int maxj)
/* Return largest input value that should map to j'th output value */
/* Must have largest(j=0) >= 0, and largest(j=maxj) >= MAXJSAMPLE */
{
  /* Breakpoints are halfway between values returned by output_value */
  return (int) (((INT32) (2*j + 1) * MAXJSAMPLE + maxj) / (2*maxj));
}


/*
 * Create the colormap.
 */

LOCAL void
create_colormap (j_decompress_ptr cinfo)
{
  my_cquantize_ptr cquantize = (my_cquantize_ptr) cinfo->cquantize;
  JSAMPARRAY colormap;		/* Created colormap */
  int total_colors;		/* Number of distinct output colors */
  int i,j,k, nci, blksize, blkdist, ptr, val;

  /* Select number of colors for each component */
  total_colors = select_ncolors(cinfo, cquantize->Ncolors);

  /* Allocate and fill in the colormap. */
  /* The colors are ordered in the map in standard row-major order, */
  /* i.e. rightmost (highest-indexed) color changes most rapidly. */

  colormap = alloc_sarray ((j_common_ptr) cinfo, JPOOL_IMAGE,
			   (JDIMENSION) total_colors,
			   (JDIMENSION) cinfo->out_color_components);

  /* blksize is number of adjacent repeated entries for a component */
  /* blkdist is distance between groups of identical entries for a component */
  blkdist = total_colors;

  for (i = 0; i < cinfo->out_color_components; i++) {
    /* fill in colormap entries for i'th color component */
    nci = cquantize->Ncolors[i]; /* # of distinct values for this color */
    blksize = blkdist / nci;
    for (j = 0; j < nci; j++) {
      /* Compute j'th output value (out of nci) for component */
      val = output_value(cinfo, i, j, nci-1);
      /* Fill in all colormap entries that have this value of this component */
      for (ptr = j * blksize; ptr < total_colors; ptr += blkdist) {
	/* fill in blksize entries beginning at ptr */
	for (k = 0; k < blksize; k++)
	  colormap[i][ptr+k] = (JSAMPLE) val;
      }
    }
    blkdist = blksize;		/* blksize of this color is blkdist of next */
  }

  /* Save the colormap in private storage,
   * where it will survive color quantization mode changes.
   */
  cquantize->sv_colormap = colormap;
  cquantize->sv_actual = total_colors;
}


/*
 * Create the color index table.
 */

LOCAL void
create_colorindex (j_decompress_ptr cinfo)
{
  my_cquantize_ptr cquantize = (my_cquantize_ptr) cinfo->cquantize;
  JSAMPROW indexptr;
  int i,j,k, nci, blksize, val;

  cquantize->colorindex =
    alloc_sarray ((j_common_ptr) cinfo, JPOOL_IMAGE,
		  (JDIMENSION) (MAXJSAMPLE+1),
		  (JDIMENSION) cinfo->out_color_components);

  /* blksize is number of adjacent repeated entries for a component */
  blksize = cquantize->sv_actual;

  for (i = 0; i < cinfo->out_color_components; i++) {
    /* fill in colorindex entries for i'th color component */
    nci = cquantize->Ncolors[i]; /* # of distinct values for this color */
    blksize = blksize / nci;

    /* in loop, val = index of current output value, */
    /* and k = largest j that maps to current val */
    indexptr = cquantize->colorindex[i];
    val = 0;
    k = largest_input_value(cinfo, i, 0, nci-1);
    for (j = 0; j <= MAXJSAMPLE; j++) {
      while (j > k)		/* advance val if past boundary */
	k = largest_input_value(cinfo, i, ++val, nci-1);
      /* premultiply so that no multiplication needed in main processing */
      indexptr[j] = (JSAMPLE) (val * blksize);
    }
  }
}


void
quantize_fs_dither (j_decompress_ptr cinfo, JSAMPARRAY input_buf,
		    JSAMPARRAY output_buf, int num_rows)
/* General case, with Floyd-Steinberg dithering */
{
  my_cquantize_ptr cquantize = (my_cquantize_ptr) cinfo->cquantize;
  register LOCFSERROR cur;	/* current error or pixel value */
  LOCFSERROR belowerr;		/* error for pixel below cur */
  LOCFSERROR bpreverr;		/* error for below/prev col */
  LOCFSERROR bnexterr;		/* error for below/next col */
  LOCFSERROR delta;
  register FSERRPTR errorptr;	/* => fserrors[] at column before current */
  register JSAMPROW input_ptr;
  register JSAMPROW output_ptr;
  JSAMPROW colorindex_ci;
  JSAMPROW colormap_ci;
  int pixcode;
  int nc = cinfo->out_color_components;
  int dir;			/* 1 for left-to-right, -1 for right-to-left */
  int dirnc;			/* dir * nc */
  int ci;
  int row;
  JDIMENSION col;
  JDIMENSION width = cinfo->output_width;
  JSAMPLE *range_limit = cinfo->sample_range_limit;

  for (row = 0; row < num_rows; row++) {
    /* Initialize output values to 0 so can process components separately */
    jzero_far((void *) output_buf[row],
	      (size_t) (width * SIZEOF(JSAMPLE)));
    for (ci = 0; ci < nc; ci++) {
      input_ptr = input_buf[row] + ci;
      output_ptr = output_buf[row];
      if (cquantize->on_odd_row) {
	/* work right to left in this row */
	input_ptr += (width-1) * nc; /* so point to rightmost pixel */
	output_ptr += width-1;
	dir = -1;
	dirnc = -nc;
	errorptr = cquantize->fserrors[ci] + (width+1); /* => entry after last column */
      } else {
	/* work left to right in this row */
	dir = 1;
	dirnc = nc;
	errorptr = cquantize->fserrors[ci]; /* => entry before first column */
      }
      colorindex_ci = cquantize->colorindex[ci];
      colormap_ci = cquantize->sv_colormap[ci];
      /* Preset error values: no error propagated to first pixel from left */
      cur = 0;
      /* and no error propagated to row below yet */
      belowerr = bpreverr = 0;

      for (col = width; col > 0; col--) {
	/* cur holds the error propagated from the previous pixel on the
	 * current line.  Add the error propagated from the previous line
	 * to form the complete error correction term for this pixel, and
	 * round the error term (which is expressed * 16) to an integer.
	 * RIGHT_SHIFT rounds towards minus infinity, so adding 8 is correct
	 * for either sign of the error value.
	 * Note: errorptr points to *previous* column's array entry.
	 */
	cur = RIGHT_SHIFT(cur + errorptr[dir] + 8, 4);
	/* Form pixel value + error, and range-limit to 0..MAXJSAMPLE.
	 * The maximum error is +- MAXJSAMPLE; this sets the required size
	 * of the range_limit array.
	 */
	cur += GETJSAMPLE(*input_ptr);
	cur = GETJSAMPLE(range_limit[cur]);
	/* Select output value, accumulate into output code for this pixel */
	pixcode = GETJSAMPLE(colorindex_ci[cur]);
	*output_ptr += (JSAMPLE) pixcode;
	/* Compute actual representation error at this pixel */
	/* Note: we can do this even though we don't have the final */
	/* pixel code, because the colormap is orthogonal. */
	cur -= GETJSAMPLE(colormap_ci[pixcode]);
	/* Compute error fractions to be propagated to adjacent pixels.
	 * Add these into the running sums, and simultaneously shift the
	 * next-line error sums left by 1 column.
	 */
	bnexterr = cur;
	delta = cur * 2;
	cur += delta;		/* form error * 3 */
	errorptr[0] = (FSERROR) (bpreverr + cur);
	cur += delta;		/* form error * 5 */
	bpreverr = belowerr + cur;
	belowerr = bnexterr;
	cur += delta;		/* form error * 7 */
	/* At this point cur contains the 7/16 error value to be propagated
	 * to the next pixel on the current line, and all the errors for the
	 * next line have been shifted over. We are therefore ready to move on.
	 */
	input_ptr += dirnc;	/* advance input ptr to next column */
	output_ptr += dir;	/* advance output ptr to next column */
	errorptr += dir;	/* advance errorptr to current column */
      }
      /* Post-loop cleanup: we must unload the final error value into the
       * final fserrors[] entry.  Note we need not unload belowerr because
       * it is for the dummy column before or after the actual array.
       */
      errorptr[0] = (FSERROR) bpreverr; /* unload prev err into array */
    }
    cquantize->on_odd_row = (cquantize->on_odd_row ? FALSE : TRUE);
  }
}


/*
 * Allocate workspace for Floyd-Steinberg errors.
 */

LOCAL void
alloc_fs_workspace (j_decompress_ptr cinfo)
{
  my_cquantize_ptr cquantize = (my_cquantize_ptr) cinfo->cquantize;
  size_t arraysize;
  int i;

  arraysize = (size_t) ((cinfo->output_width + 2) * SIZEOF(FSERROR));
  for (i = 0; i < cinfo->out_color_components; i++) {
    cquantize->fserrors[i] = (FSERRPTR)
      alloc_small((j_common_ptr) cinfo, JPOOL_IMAGE, arraysize);
  }
}


/*
 * Initialize for one-pass color quantization.
 */

EXTERN void start_pass_1_quant (j_decompress_ptr cinfo);

void
METHODDEF_start_pass_1_quant (j_decompress_ptr cinfo)
{
  my_cquantize_ptr cquantize = (my_cquantize_ptr) cinfo->cquantize;
  size_t arraysize;
  int i;

  /* Install my colormap. */
  cinfo->colormap = cquantize->sv_colormap;
  cinfo->actual_number_of_colors = cquantize->sv_actual;

  /* Initialize for desired dithering mode. */
  cquantize->on_odd_row = FALSE; /* initialize state for F-S dither */
  /* Allocate Floyd-Steinberg workspace if didn't already. */
  if (cquantize->fserrors[0] == NULL)
    alloc_fs_workspace(cinfo);
  /* Initialize the propagated errors to zero. */
  arraysize = (size_t) ((cinfo->output_width + 2) * SIZEOF(FSERROR));
  for (i = 0; i < cinfo->out_color_components; i++)
    jzero_far((void *) cquantize->fserrors[i], arraysize);
}


/*
 * Finish up at the end of the pass.
 */

EXTERN void finish_pass_1_quant (j_decompress_ptr cinfo);

void
METHODDEF_finish_pass_1_quant (j_decompress_ptr cinfo)
{
  /* no work in 1-pass case */
}


/*
 * Module initialization routine for 1-pass color quantization.
 */

GLOBAL void
jinit_1pass_quantizer (j_decompress_ptr cinfo)
{
  my_cquantize_ptr cquantize;

  cquantize = (my_cquantize_ptr)
    alloc_small((j_common_ptr) cinfo, JPOOL_IMAGE, SIZEOF(my_cquantizer));
  cinfo->cquantize = (struct jpeg_color_quantizer *) cquantize;
  cquantize->pub.start_pass = start_pass_1_quant;
  cquantize->pub.finish_pass = finish_pass_1_quant;
  cquantize->fserrors[0] = NULL; /* Flag FS workspace not allocated */

  /* Make sure my internal arrays won't overflow */
  if (cinfo->out_color_components > MAX_Q_COMPS)
    ERREXIT1(cinfo, JERR_QUANT_COMPONENTS, MAX_Q_COMPS);
  /* Make sure colormap indexes can be represented by JSAMPLEs */
  if (cinfo->desired_number_of_colors > (MAXJSAMPLE+1))
    ERREXIT1(cinfo, JERR_QUANT_MANY_COLORS, MAXJSAMPLE+1);

  /* Create the colormap and color index table. */
  create_colormap(cinfo);
  create_colorindex(cinfo);

  /* Allocate Floyd-Steinberg workspace now if requested.
   * We do this now since it is FAR storage and may affect the memory
   * manager's space calculations.  If the user changes to FS dither
   * mode in a later pass, we will allocate the space then, and will
   * possibly overrun the max_memory_to_use setting.
   */
  alloc_fs_workspace(cinfo);
}
