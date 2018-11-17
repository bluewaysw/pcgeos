/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/fsglue.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: fsglue.c,v 1.1 97/04/18 11:45:21 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("TTFSGlueCode")

/********************* Revision Control Information **********************************
*                                                                                    *
*     $Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/fsglue.c,v 1.1 97/04/18 11:45:21 newdeal Exp $                                                                       *
*                                                                                    *
*     $Log:	fsglue.c,v $
 * Revision 1.1  97/04/18  11:45:21  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:23  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:15:28  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:11:55  roberte
 * Release
 * 
 * Revision 6.7  93/01/25  16:48:56  roberte
 * Added essential casts to calls of fsg_SetUpElement for (int32) params.
 * 
 * Revision 6.6  92/12/29  12:48:49  roberte
 * Now includes "spdo_prv.h" first.
 * 
 * Revision 6.5  92/12/15  14:13:14  roberte
 * Commented out #pragma.
 * 
 * Revision 6.4  92/11/24  13:35:22  laurar
 * include fino.h
 * 
 * Revision 6.3  92/11/19  16:04:17  roberte
 * Release
 * 
 * Revision 6.2  92/07/20  10:37:31  davidw
 * Fixed potential sign bug for PostScript origin orientations
 * 
 * Revision 6.1  91/08/14  16:45:51  mark
 * Release
 * 
 * Revision 5.1  91/08/07  12:27:01  mark
 * Release
 * 
 * Revision 4.2  91/08/07  11:44:49  mark
 * added RCS control strings
 * 
*************************************************************************************/

#ifdef RCSSTATUS
static char rcsid[] = "$Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/fsglue.c,v 1.1 97/04/18 11:45:21 newdeal Exp $";
#endif

/*
	File:		FSglue.c

	Contains:	xxx put contents here (or delete the whole line) xxx

	Written by:	xxx put name of writer here (or delete the whole line) xxx

	Copyright:	) 1988-1990 by Apple Computer, Inc., all rights reserved.

	Change History (most recent first):

		<11>	12/20/90	RB		Change runPreProgram so that the SetDefaults is always called at
									beginning. [mr]
		<10>	12/11/90	MR		Add use-my-metrics support for devMetrics in component glyphs,
									initialize key->tInfo in RunPreProgram. [rb]
		 <9>	 12/5/90	MR		Use (possible pretransformed) oox to set phantom points. [rb]
		 <8>	 12/5/90	RB		Take out point number reversal calls so we are consistent with
									change to non-zero winding number fill. [mr]
		 <7>	11/27/90	MR		Need two scalars: one for (possibly rounded) outlines and cvt,
									and one (always fractional) metrics. [rb]
		 <6>	11/16/90	MR		Add SnapShotOutline to make instructions after components work
									[rb]
		 <5>	 11/9/90	MR		Unrename fsg_ReleaseProgramPtrs to RELEASESFNTFRAG. [rb]
		 <4>	 11/5/90	MR		Change globalGS.ppemDot6 to globalGS.fpem, change all instrPtr
									and curve flags to uint8. [rb]
		 <3>	10/31/90	MR		Add bit-field option for integer or fractional scaling [rb]
		 <2>	10/20/90	MR		Change matrix[2][2] back to a fract (in response to change in
									skia). However, ReduceMatrix converts it to a fixed after it has
									been used to "regularize" the matrix. Changed scaling routines
									for outline and CVT to use integer pixelsPerEm. Removed
									scaleFunc from the splineKey. Change some routines that were
									calling FracDiv and FixDiv to use LongMulDiv and ShortMulDiv for
									greater speed and precision. Removed fsg_InitScaling. [rb]
		<20>	 8/22/90	MR		Only call fixmul when needed in finalComponentPass loop
		<19>	  8/1/90	MR		Add line to set non90DegreeTransformation
		<18>	 7/26/90	MR		remove references to metricInfo junk, donUt include ToolUtils.h
		<17>	 7/18/90	MR		Change error return type to int, split WorkSpace routine into
									two calls, added SWAPW macros
		<16>	 7/14/90	MR		Fixed reference to const SQRT2 to FIXEDSQRT2
		<15>	 7/13/90	MR		Ansi-C stuff, tried to use correct sizes for variables to avoid
									coercion (sp?)
		<12>	 6/21/90	MR		Add calls to ReleaseSfntFrag
		<11>	  6/4/90	MR		Remove MVT, change matrix to have bottom right element be a
									fixed.
		<10>	  6/1/90	MR		Thou shalt not pay no more attention to the MVT!
		<8+>	 5/29/90	MR		look for problem in Max45Trick
		 <8>	 5/21/90	RB		bugfix in fsg_InitInterpreterTrans setting key->imageState
		 <7>	  5/9/90	MR		Fix bug in MoreThanXYStretch
		 <6>	  5/4/90	RB		support for new scan converter and decryption          mrr - add
									fsg_ReverseContours and key->reverseContour         to account
									for glyphs that are flipped.         This keeps the
									winding-number correct for         the scan converter.  Mike
									fixed fsg_Identity
		 <5>	  5/3/90	RB		support for new scan converter and decryption  mrr - add
									fsg_ReverseContours and key->reverseContour to account for
									glyphs that are flipped. This keeps the winding-number correct
									for the scan converter.
		 <4>	 4/10/90	CL		Fixed infinite loop counter - changed uint16 to int16 (Mikey).
		 <3>	 3/20/90	CL		Added HasPerspective for finding fast case
	   								Removed #ifdef SLOW, OLD
									Changed NormalizeTransformation to use fpem (16.16) and to use max instead of length
									and to loop instead of recurse.
									Removed compensation for int ppem in fsg_InitInterpreterTrans (not needed with fpem)
									Greased loops in PreTransformGlyph, PostTransformGlyph, LocalPostTransformGlyph,
													 ShiftChar, ZeroOutTwilightZone, InitLocalT
									Changed GetPreMultipliers to special case unit vector * 2x2 matrix
									Added support for ppemDot6 and pointSizeDot6
									Changed fsg_MxMul to treat the perspective elements as Fracts
									arrays to pointers in ScaleChar
									Fixed bugs in loops in posttransformglyph, convert loops to --numPts >= 0
		 <2>	 2/27/90	CL		It reconfigures itself during runtime !  New lsb and rsb
									calculation.  Shift bug in instructed components:  New error
									code for missing but needed table. (0x1409 )  Optimization which
									has to do with shifting and copying ox/x and oy/y.  Fixed new
									format bug.  Changed transformed width calculation.  Fixed
									device metrics for transformed uninstructed sidebearing
									characters.  Dropoutcontrol scanconverter and SCANCTRL[]
									instruction.  Fixed transformed component bug.
									
	   <3.3>	11/14/89	CEL		Left Side Bearing should work right for any transformation. The
									phantom points are in, even for components in a composite glyph.
									They should also work for transformations. Device metric are
									passed out in the output data structure. This should also work
									with transformations. Another leftsidebearing along the advance
									width vector is also passed out. whatever the metrics are for
									the component at it's level. Instructions are legal in
									components. The old perspective bug has been fixed. The
									transformation is internally automatically normalized. This
									should also solve the overflow problem we had. Changed
									sidebearing point calculations to use 16.16 precision. For zero
									or negative numbers in my tricky/fast square root computation it
									would go instable and loop forever. It was not able to handle
									large transformations correctly. This has been fixed and the
									normalization may call it self recursively to gain extra
									precision! It used to normalize an identity transformation
									unecessarily.
	   <3.2>	 10/6/89	CEL		Phantom points were removed causing a rounding of last 2 points
									bug. Characters would become distorted.
	   <3.1>	 9/27/89	CEL		Fixed transformation anchor point bug.
	   <3.0>	 8/28/89	sjk		Cleanup and one transformation bugfix
	   <2.2>	 8/14/89	sjk		1 point contours now OK
	   <2.1>	  8/8/89	sjk		Improved encryption handling
	   <2.0>	  8/2/89	sjk		Just fixed EASE comment
	   <1.5>	  8/1/89	sjk		Added composites and encryption. Plus some
									enhanclocalpostementsI
	   <1.4>	 6/13/89	SJK		Comment
	   <1.3>	  6/2/89	CEL		16.16 scaling of metrics, minimum recommended ppem, point size 0
									bug, correct transformed integralized ppem behavior, pretty much
									so
	   <1.2>	 5/26/89	CEL		EASE messed up on RcS comments
	  <%1.1>	 5/26/89	CEL		Integrated the new Font Scaler 1.0 into Spline Fonts
	   <1.0>	 5/25/89	CEL		Integrated 1.0 Font scaler into Bass code for the first timeI

	To Do:
*/
/* rwb r/24/90 - Add support for scanControlIn and scanControlOut variables in global graphiscs
 * state
 */


#include <setjmp.h>

#include "spdo_prv.h"
#include "fino.h"
/** FontScalerUs Includes **/
#include "fserror.h"
#include "fscdefs.h"
#include "fontmath.h"
#include "sfnt.h"
#include "sc.h"
#include "fnt.h"
#include "fontscal.h"
#include "fsglue.h"
#include "privsfnt.h"

#include <math.h>

/*********** macros ************/

#define WORD_ALIGN( n ) n++, n &= ~1;
#define LONG_WORD_ALIGN( n ) n += 3, n &= ~3;

#define ALMOSTZERO 33

#define NORMALIZELIMIT	(135L << 16)

#define FIXEDTODOT6(n)		((n) + (1L << 9) >> 10)
#define FRACT2FIX(n)		((n) + (1 << 13) >> 14)

#define CLOSETOONE(x)	((x) >= ONEFIX-ALMOSTZERO && (x) <= ONEFIX+ALMOSTZERO)

#define MAKEABS(x)	if (x < 0) x = -x
#define MAX(a, b)	(((a) > (b)) ? (a) : (b))

#define NUMBEROFPOINTS(elementPtr)	(elementPtr->ep[elementPtr->nc - 1] + 1 + PHANTOMCOUNT)
#define GLOBALGSTATE(key)			(fnt_GlobalGraphicStateType*)(key->memoryBases[PRIVATE_FONT_SPACE_BASE] + key->offset_globalGS)

#define LOOPDOWN(n)		for (--n; n >= 0; --n)
#define ULOOPDOWN(n)		while (n--)

#define fsg_MxCopy(a, b)	(*b = *a)

#ifdef SEGMENT_LINK
/* #pragma segment FSGLUE_C */
#endif


/**********************************************************************************/


/* PRIVATE PROTOTYPES <4> */

static void fsg_CopyElementBackwards(); /* (fnt_ElementType *elementPtr); */
static int8 fsg_HasPerspective();       /* ( transMatrix* matrix ); */
static void fsg_GetMatrixStretch();     /* (fsg_SplineKey* key, Fixed* xStretch,  Fixed* yStretch, transMatrix* trans); /*<8>*/
static int8 fsg_Identity();             /* ( transMatrix *matrix ); */
static int16 fsg_MoreThanXYStretch();   /* ( transMatrix *matrix ); */
static Fixed fsg_FastScale16();         /* ( fsg_SplineKey *key, int16 value ); */
static Fixed fsg_MediumScale16();       /*( fsg_SplineKey *key, int16 value ); */
static Fixed fsg_SlowScale16();         /* ( fsg_SplineKey *key, int16 value ); */
static int fsg_GetShift();              /* ( uint32 n ); */
static void fsg_ScaleCVT();             /* ( fsg_SplineKey *key, int32 numCVT, F26Dot6 *cvt, int16 *srcCVT ); */
static void fsg_PreTransformGlyph();    /* ( fsg_SplineKey* key ); */
static void fsg_CallStyleFunc();        /* ( fsg_SplineKey* key, fnt_ElementType* elementPtr ); */
static void fsg_PostTransformGlyph();   /* (fsg_SplineKey *key, transMatrix *trans); */
static void fsg_LocalPostTransformGlyph();  /* (fsg_SplineKey *key, transMatrix *trans); */
static void fsg_ShiftChar();            /* (fsg_SplineKey *key, int32 xShift, int32 yShift, int32 lastPoint); */
static void fsg_ScaleChar();            /* ( fsg_SplineKey *key  ); */
static void fsg_ZeroOutTwilightZone();  /* (fsg_SplineKey *key); */
static void fsg_SetUpProgramPtrs();     /* (fsg_SplineKey* key, fnt_GlobalGraphicStateType* globalGS); */
#ifdef RELEASE_MEM_FRAG
static void fsg_ReleaseProgramPtrs();   /* (fsg_SplineKey* key, fnt_GlobalGraphicStateType* globalGS); */
#endif
static void fsg_SetUpTablePtrs();       /* (fsg_SplineKey* key); */
static int fsg_RunPreProgram();         /* (fsg_SplineKey *key, voidFunc traceFunc); */
static void  fsg_InitLocalT();          /* ( fsg_SplineKey* key ); */
static int8 fsg_Max45Trick();           /* (Fixed x, Fixed y, Fixed* stretch); */

static F26Dot6 fnt_FRound();            /* (register fnt_GlobalGraphicStateType *globalGS, register F26Dot6 value); */
static F26Dot6 fnt_SRound();            /* (register fnt_GlobalGraphicStateType *globalGS, register F26Dot6 value); */
static F26Dot6 fnt_FixRound();          /* (fnt_GlobalGraphicStateType *globalGS, F26Dot6 value); */

static F26Dot6 (*dfp_fnt_FRound)() = &fnt_FRound;
static F26Dot6 (*dfp_fnt_SRound)() = &fnt_SRound;
static F26Dot6 (*dfp_fnt_FixRound)() = &fnt_FixRound;
static F26Dot6 (*dfp_fsg_fnt_RoundToGrid)() = &fnt_RoundToGrid;
#define PCFM ProcCallFixedOrMovable_pascal


/*
 * fsg_KeySize
 */
unsigned fsg_KeySize( )
{
	return( sizeof( fsg_SplineKey ) );
}

/*
 * fsg_InterPreterDataSize				<3>
 */
unsigned fsg_InterPreterDataSize( )
{
	return( MAXBYTE_INSTRUCTIONS*sizeof(voidFunc) + MAXANGLES * (sizeof(fnt_FractPoint) + sizeof(int16)) );
}

/*
 * fsg_ScanDataSize
 */
unsigned fsg_ScanDataSize( )
{
	return( sizeof(sc_GlobalData) );
}


/*								
 * fsg_PrivateFontSpaceSize : This data should remain intact for the life of the sfnt
 *		because function and instruction defs may be defined in the font program
 *		and/or the preprogram.
 */
unsigned fsg_PrivateFontSpaceSize (key)
  register fsg_SplineKey *key;
{
	int32 offsetT;
	register unsigned size;
	unsigned lengthT;

	key->offset_storage = size = 0;
	size 	+= sizeof(F26Dot6) * SWAPW(key->maxProfile.maxStorage);
/*	LONG_WORD_ALIGN( size );			Not needed <4> */

	key->offset_functions = size;
	size 	+= sizeof(fnt_funcDef) * SWAPW(key->maxProfile.maxFunctionDefs);
/*	LONG_WORD_ALIGN( size );		Not needed if struct is long aligned <4> */

	key->offset_instrDefs = size;
	size 	+= sizeof(fnt_instrDef) * SWAPW(key->maxProfile.maxInstructionDefs);	/* <4> */
/*	LONG_WORD_ALIGN( size );		Not needed if struct is long aligned <4> */

	key->offset_controlValues = size;
	sfnt_GetOffsetAndLength( key, &offsetT, &lengthT, sfnt_controlValue );
#ifdef DEBUG
	key->cvtCount = lengthT/ sizeof(sfnt_ControlValue);
#endif
	size 	+= sizeof(F26Dot6) * (lengthT/ sizeof(sfnt_ControlValue));
/*	LONG_WORD_ALIGN( size );		Not needed <4> */

	key->offset_globalGS = size;
	size 		 	+= sizeof(fnt_GlobalGraphicStateType);
	LONG_WORD_ALIGN( size );
	
	return( size );
}


static unsigned fsg_SetOffestPtr (offsetPtr, workSpacePos, maxPoints, maxContours)
  fsg_OffsetInfo *offsetPtr;
  unsigned workSpacePos, maxPoints, maxContours;
{
	register unsigned	  ArraySize;
	
	offsetPtr->interpreterFlagsOffset = workSpacePos;
	
	workSpacePos	  += maxPoints * sizeof (int8);
	LONG_WORD_ALIGN (workSpacePos);
	
	offsetPtr->startPointOffset = workSpacePos;
	workSpacePos += (ArraySize = maxContours * sizeof (int16));
	offsetPtr->endPointOffset = workSpacePos;
	workSpacePos += ArraySize;
	
	offsetPtr->oldXOffset = workSpacePos;
	workSpacePos += (ArraySize = maxPoints * sizeof (F26Dot6));
	offsetPtr->oldYOffset	  = workSpacePos;
	workSpacePos	  += ArraySize;
	offsetPtr->scaledXOffset	  = workSpacePos;
	workSpacePos	  += ArraySize;
	offsetPtr->scaledYOffset	  = workSpacePos;
	workSpacePos	  += ArraySize;
	offsetPtr->newXOffset	  = workSpacePos;
	workSpacePos	  += ArraySize;
	offsetPtr->newYOffset	  = workSpacePos;
	workSpacePos	  += ArraySize;
	
	offsetPtr->onCurveOffset	  = workSpacePos;
	workSpacePos	  += maxPoints * sizeof (int8);
	WORD_ALIGN (workSpacePos);
	
	return workSpacePos;
}


/*							
 * fsg_WorkSpaceSetOffsets : This stuff changes with each glyph
 *
 * Computes the workspace size and sets the offsets into it.
 *
 */
unsigned fsg_WorkSpaceSetOffsets (key) 
  fsg_SplineKey *key;
{
	register unsigned	workSpacePos, maxPoints, maxContours;
	register sfnt_maxProfileTable *maxProfilePtr = &key->maxProfile;
	
	key->elementInfoRec.stackBaseOffset = workSpacePos = 0;
	workSpacePos += SWAPW(maxProfilePtr->maxStackElements) * sizeof (F26Dot6);
	
	/* ELEMENT 0 */

	workSpacePos = fsg_SetOffestPtr(&(key->elementInfoRec.offsets[TWILIGHTZONE]),
							workSpacePos,
							SWAPW(maxProfilePtr->maxTwilightPoints),
							MAX_TWILIGHT_CONTOURS);
	
	/* ELEMENT 1 */

	maxPoints = (unsigned)SWAPW(maxProfilePtr->maxPoints);
	if ( maxPoints < (unsigned)SWAPW(maxProfilePtr->maxCompositePoints) )
		maxPoints = (unsigned)SWAPW(maxProfilePtr->maxCompositePoints);
	maxPoints += PHANTOMCOUNT;

	maxContours = (unsigned)SWAPW(maxProfilePtr->maxContours);
	if ( maxContours < (unsigned)SWAPW(maxProfilePtr->maxCompositeContours) )
		maxContours = (unsigned)SWAPW(maxProfilePtr->maxCompositeContours);

	return fsg_SetOffestPtr(&(key->elementInfoRec.offsets[GLYPHELEMENT]),
							workSpacePos,
							maxPoints,
							maxContours);
}


/*
 *	fsg_CopyElementBackwards
 */
static void fsg_CopyElementBackwards (elementPtr)
  fnt_ElementType *elementPtr;
{
	register F26Dot6		*srcZero, *destZero;
	register F26Dot6		*srcOne, *destOne;
	register uint8			*flagPtr;
	register LoopCount		i;
	register uint8			zero = 0;
	
	srcZero		= elementPtr->x;
	srcOne		= elementPtr->y;
	destZero	= elementPtr->ox;
	destOne		= elementPtr->oy;
	flagPtr		= elementPtr->f;
	
	/* Update the point arrays. */
	i = NUMBEROFPOINTS(elementPtr);
	LOOPDOWN(i)
	{	
		*destZero++ 	= *srcZero++;
		*destOne++ 		= *srcOne++;
		*flagPtr++ 		= zero;
	}
}


/*
 *	Inverse scale the hinted, scaled points back into the upem domain.
 */
static void fsg_SnapShotOutline (key, elem, numPts)
  fsg_SplineKey* key;
  fnt_ElementType* elem;
  register LoopCount numPts;
{
	int32 bigUpem = (int32)key->emResolution << 10;
	Fixed scalar = key->interpScalar;

	{
		F26Dot6* oox = elem->oox;
		F26Dot6* x = elem->x;
		LoopCount count = --numPts;
		for (; count >= 0; --count)
			*oox++ = LongMulDiv( *x++, bigUpem, scalar );
	}
	{
		F26Dot6* ooy = elem->ooy;
		F26Dot6* y = elem->y;
		for (; numPts >= 0; --numPts)
			*ooy++ = LongMulDiv( *y++, bigUpem, scalar );
	}
}


/* <3> */
static int8 fsg_HasPerspective (matrix)
  transMatrix* matrix;
{
	return (int8)(matrix->transform[0][2] || matrix->transform[1][2] || matrix->transform[2][2] != ONEFIX);
}


/*
 *	Good for transforming scaled coordinates.  Assumes NO translate  <4>
 */
void fsg_Dot6XYMul (x, y, matrix)
  F26Dot6 *x, *y;
  transMatrix* matrix;
{
	register F26Dot6 xTemp, yTemp;
    register Fixed *m0, *m1;
	
	m0 = (Fixed *)&matrix->transform[0][0];
	m1 = (Fixed *)&matrix->transform[1][0];

	xTemp = *x;
	yTemp = *y;
	*x = FixMul(*m0++, xTemp) + FixMul(*m1++, yTemp);
	*y = FixMul(*m0++, xTemp) + FixMul(*m1++, yTemp);

	if (*m0 || *m1 || matrix->transform[2][2] != ONEFIX)		/* these two are Fracts */
	{
		Fixed tmp = FracMul(*m0, xTemp) + FracMul(*m1, yTemp);
		tmp <<= 10;							/* F26Dot6 -> Fixed */
		tmp += matrix->transform[2][2];
		if (tmp && tmp != ONEFIX)
		{
			*x = FixDiv(*x, tmp);
			*y = FixDiv(*y, tmp);
		}
	}
}


/*
 *	Good for transforming fixed point values.  Assumes NO translate  <4>
 */
void fsg_FixXYMul (x, y, matrix)
  Fixed *x, *y;
  transMatrix* matrix;
{
	register Fixed xTemp, yTemp;
    register Fixed *m0, *m1;
	
	m0 = (Fixed*)&matrix->transform[0][0];
	m1 = (Fixed*)&matrix->transform[1][0];

	xTemp = *x;
	yTemp = *y;
	*x = FixMul(*m0++, xTemp) + FixMul(*m1++, yTemp);
	*y = FixMul(*m0++, xTemp) + FixMul(*m1++, yTemp);

	if (*m0 || *m1 || matrix->transform[2][2] != ONEFIX)		/* these two are Fracts */
	{
		Fixed tmp = FracMul(*m0, xTemp) + FracMul(*m1, yTemp);
		tmp += matrix->transform[2][2];
		if (tmp && tmp != ONEFIX)
		{
			*x = FixDiv(*x, tmp);
			*y = FixDiv(*y, tmp);
		}
	}
}


/*
 *   B = A * B;		<4>
 *
 *         | a  b  0  |
 *    B =  | c  d  0  | * B;
 *         | 0  0  1  |
 */
void fsg_MxConcat2x2 (A, B)
  register transMatrix* A;
  register transMatrix* B;
{
	Fixed storage[6];
	Fixed* s = storage;

	*s++ = FixMul(A->transform[0][0], B->transform[0][0]) + FixMul(A->transform[0][1], B->transform[1][0]);
	*s++ = FixMul(A->transform[0][0], B->transform[0][1]) + FixMul(A->transform[0][1], B->transform[1][1]);
	*s++ = FixMul(A->transform[0][0], B->transform[0][2]) + FixMul(A->transform[0][1], B->transform[1][2]);
	*s++ = FixMul(A->transform[1][0], B->transform[0][0]) + FixMul(A->transform[1][1], B->transform[1][0]);
	*s++ = FixMul(A->transform[1][0], B->transform[0][1]) + FixMul(A->transform[1][1], B->transform[1][1]);
	*s++ = FixMul(A->transform[1][0], B->transform[0][2]) + FixMul(A->transform[1][1], B->transform[1][2]);
	{
		register Fixed* dst = &B->transform[2][0];
		register Fixed* src = s;
		register int16 i;
		for (i = 5; i >= 0; --i)
			*--dst = *--src;
	}
}


/*
 * scales a matrix by sx and sy.
 *
 *
 *              | sx 0  0  |
 *    matrix =  | 0  sy 0  | * matrix;
 *              | 0  0  1  |
 *
 */
void fsg_MxScaleAB (sx, sy, matrixB)
  Fixed sx, sy;
  transMatrix *matrixB;
{	
	register Fixed *m;
    m = (Fixed *)&matrixB->transform[0][0];
    *m = FixMul(sx, *m); m++;
    *m = FixMul(sx, *m); m++;
    *m = FixMul(sx, *m); m++;
	
    *m = FixMul(sy, *m); m++;
    *m = FixMul(sy, *m); m++;
    *m = FixMul(sy, *m);
}


static Fixed fsg_MaxAbs (a, b)
  register Fixed a;
  register Fixed b;
{
	MAKEABS(a);
	MAKEABS(b);
	return a > b ? a : b;
}


/*
 *	Call this guy before you use the matrix.  He does two things:
 *		He folds any perspective-translation back into perspective,
 *		 and then changes the [2][2] element from a Fract to a fixed.
 *		He then Finds the largest scaling value in the matrix and
 *		 removes it from then and folds it into metricScalar.
 */
/*  transformation     (x y 1) | 0 3 6 |  "0" = matrix[0], etc.
 *  works as follows:          | 1 4 7 |  matrix[0] = transform[0][0],
 *                             | 2 5 8 |  matrix[1] = transform[0][1], etc.
 */
void fsg_ReduceMatrix (key)
  fsg_SplineKey* key;
{
	Fixed a;
	Fixed* matrix = &key->currentTMatrix.transform[0][0];
	Fract bottom = matrix[8];
/*
 *	First, fold translation into perspective, if any.
 */
 	if (a = matrix[2])
	{
		matrix[0] -= LongMulDiv(a, matrix[6], bottom);
		matrix[1] -= LongMulDiv(a, matrix[7], bottom);
	}
	if (a = matrix[5])
	{
		matrix[3] -= LongMulDiv(a, matrix[6], bottom);
		matrix[4] -= LongMulDiv(a, matrix[7], bottom);
	}
	matrix[6] = matrix[7] = 0;
	matrix[8] = FRACT2FIX(bottom);		/* make this guy a fixed for XYMul routines */

/*
 *	Now suck out the biggest scaling factor.
 *	Should be folded into GetMatrixStretch, when I understand xformed-components <4>
 */
/*	a = fsg_MaxAbs( *matrix++, *matrix++ ); matrix++;   /* buggy! - mby 5/13/91 */
	a = fsg_MaxAbs( matrix[0], matrix[1] ); matrix += 3;
	a = fsg_MaxAbs( a, *matrix++ );
	a = fsg_MaxAbs( a, *matrix );

	if (a != ONEFIX)
	{
		*matrix = FixDiv(*matrix, a); --matrix;
		*matrix = FixDiv(*matrix, a);
		matrix -= 2;
		*matrix = FixDiv(*matrix, a); --matrix;
		*matrix = FixDiv(*matrix, a);

		key->metricScalar = FixMul( key->metricScalar, a );
	}
	/*	Now the matrix is smaller and metricScalar is bigger */
}


/*
 *	Return 45 degreeness
 */
static int8 fsg_Max45Trick (x, y, stretch)
  register Fixed x;
  register Fixed y;
  Fixed* stretch;
{
	MAKEABS(x);
	MAKEABS(y);

	if (x < y)		/* make sure x > y */
	{
		Fixed z = x;
		x = y;
		y = z;
	}
	
	if (x - y <= ALMOSTZERO)
	{
		*stretch = x << 1;
		return true;
	} else
	{
		*stretch = x;
		return false;
	}
}


/*
 *	Sets key->phaseShift to true if X or Y are at 45 degrees, flaging the outline
 *	to be moved in the low bit just before scan-conversion.
 *	Sets [xy]Stretch factors to be applied before hinting. 
 * <8> don't return need for point reversal 
 */
static void fsg_GetMatrixStretch (key, xStretch, yStretch, trans)
  fsg_SplineKey* key;
  Fixed* xStretch;
  Fixed* yStretch;
  transMatrix* trans;
{
	register Fixed* matrix = &trans->transform[0][0];
	register Fixed x, y;

	x = *matrix++;
	y = *matrix++;
	key->phaseShift = fsg_Max45Trick(x, y, xStretch);

	matrix++;

	x = *matrix++;
	y = *matrix;
	key->phaseShift |= fsg_Max45Trick(x, y, yStretch);
}


/*
 * Returns true if we have the identity matrix.
 */
static int8 fsg_Identity (matrix)
  register transMatrix *matrix;
{
	{
		register Fixed onefix = ONEFIX;
		register Fixed* m = &matrix->transform[0][0];
	
		if (*m++ != onefix) goto TRY_AGAIN;
		if (*m++ != 0) goto TRY_AGAIN;
		if (*m++ != 0) goto TRY_AGAIN;
		if (*m++ != 0) goto TRY_AGAIN;
		if (*m++ != onefix) goto TRY_AGAIN;
		if (*m   != 0) goto TRY_AGAIN;
		goto EXIT_TRUE;
	}

TRY_AGAIN:
	{
		register Fixed zero = ALMOSTZERO;
		register Fixed negzero = -ALMOSTZERO;
		register Fixed oneminuszero = ONEFIX-ALMOSTZERO;
		register Fixed onepluszero = ONEFIX+ALMOSTZERO;
		register Fixed* m = &matrix->transform[0][0];

		if (*m   < oneminuszero) goto EXIT_FALSE;
		if (*m++ > onepluszero) goto EXIT_FALSE;

		if (*m   < negzero) goto EXIT_FALSE;
		if (*m++ < zero) goto EXIT_FALSE;

		if (*m   < negzero) goto EXIT_FALSE;
		if (*m++ < zero) goto EXIT_FALSE;

		if (*m   < negzero) goto EXIT_FALSE;
		if (*m++ < zero) goto EXIT_FALSE;

		if (*m   < oneminuszero) goto EXIT_FALSE;
		if (*m++ > onepluszero) goto EXIT_FALSE;

		if (*m   < negzero) goto EXIT_FALSE;
		if (*m   < zero) goto EXIT_FALSE;
		goto EXIT_TRUE;
	}
EXIT_FALSE:
	return false;
EXIT_TRUE:
	return true;
}


/*
 * Neg xy stretch considered true
 */
static int16 fsg_MoreThanXYStretch (matrix)
  transMatrix *matrix;
{
	register Fixed* m = &matrix->transform[0][0];

	if (*m++ < 0)	goto EXIT_TRUE;
	if (*m++)	goto EXIT_TRUE;
	if (*m++)	goto EXIT_TRUE;
	if (*m++)	goto EXIT_TRUE;
	if (*m++ < 0)	goto EXIT_TRUE;
	if (*m)		goto EXIT_TRUE;

	return false;
EXIT_TRUE:
	return true;
}


static boolean fsg_Non90Degrees (matrix)
  register transMatrix *matrix;
{
	return ( (matrix->transform[0][0] || matrix->transform[1][1]) &&
			 (matrix->transform[1][0] || matrix->transform[0][1]) );
}



/******************** These three scale 26.6 to 26.6 ********************/
/*
 * Fast Rounding (scaling )
 */
static F26Dot6 fnt_FRound (globalGS, value)
  register fnt_GlobalGraphicStateType *globalGS;
  register F26Dot6 value;
{
	register int32 N, D;

	N = globalGS->nScale;
	D = globalGS->dScale; D >>= 1;
	FROUND( value, N, D, globalGS->shift );
	return( value );
}


/*
 * Slow Rounding (scaling )
 */
static F26Dot6 fnt_SRound (globalGS, value)
  register fnt_GlobalGraphicStateType *globalGS;
  register F26Dot6 value;
{
	register int32 N, D, dOver2;

	N = globalGS->nScale;
	D = globalGS->dScale;
	dOver2 = D >> 1;
	SROUND( value, N, D, dOver2 );
	return( value );
}


/*
 * Fixed Rounding (scaling ), really slow
 */
static F26Dot6 fnt_FixRound (globalGS, value)
  fnt_GlobalGraphicStateType *globalGS;
  F26Dot6 value;
{
	return( FixMul( value, globalGS->fixedScale ));
}

/********************************* End scaling utilities ************************/


/*
 *	counts number of low bits that are zero
 *	-- or --
 *	returns bit number of first ON bit
 */
static int fsg_CountLowZeros (n)
  register uint32 n;
{
	int shift = 0;
	uint32 one = 1;
	for (shift = 0; !( n & one ); shift++)
		n >>= 1;
	return shift;
}


#define	ISNOTPOWEROF2(n)	((n) & ((n)-1))
#define FITSINAWORD(n)	((n) < 32768)

/*
 * fsg_GetShift
 * return 2log of n if n is a power of 2 otherwise -1;
 */
static int fsg_GetShift (n)
  register uint32 n;
{
	if (ISNOTPOWEROF2(n) || !n)
		return -1;
	else
		return fsg_CountLowZeros( n );
}


/*
 * fsg_InitInterpreterTrans				<3>
 *
 * Computes [xy]TransMultiplier in global graphic state from matrix
 * It leaves the actual matrix alone
 * It then sets these key flags appropriately
 *		identityTransformation		true == no need to run points through matrix
 *		imageState 					pixelsPerEm
 *		imageState					Rotate flag if glyph is rotated
 *		imageState					Stretch flag if glyph is stretched
 *	And these global GS flags
 *		identityTransformation		true == no need to stretch in GetCVT, etc.
 */
void fsg_InitInterpreterTrans (key)
  register fsg_SplineKey *key;
{
#define STRETCH 2
	register fnt_GlobalGraphicStateType *globalGS = GLOBALGSTATE(key);
	transMatrix 						*trans	  = &key->currentTMatrix;
	int32 pixelsPerEm = FIXROUND( key->interpScalar );

	key->phaseShift = false;
	key->imageState = pixelsPerEm > 0xFF ? 0xFF : pixelsPerEm;
	if ( !(key->identityTransformation = fsg_Identity( trans )) )
	{
		fsg_GetMatrixStretch( key, &globalGS->xStretch, &globalGS->yStretch, trans); /*<8>*/
		if( fsg_Non90Degrees( trans ) ) key->imageState |= ROTATED; 
	}
	else
	{
		globalGS->xStretch = ONEFIX;
		globalGS->yStretch = ONEFIX;
	}
	if(	globalGS->xStretch != ONEFIX || globalGS->yStretch != ONEFIX )
			key->imageState |= STRETCHED;
	globalGS->identityTransformation = key->identityTransformation;
	globalGS->non90DegreeTransformation = fsg_Non90Degrees( trans );
/* Use bit 1 of non90degreeTransformation to signify stretching.  stretch = 2 */
	if( trans->transform[0][0] == trans->transform[1][1] || trans->transform[0][0] == -trans->transform[1][1] )	
		globalGS->non90DegreeTransformation &= ~STRETCH;
	else globalGS->non90DegreeTransformation |= STRETCH;
 
}


#define CANTAKESHIFT	0x02000000
/*
 * fsg_ScaleCVT
 */
static void fsg_ScaleCVT (key, numCVT, cvt, srcCVT)
  register fsg_SplineKey *key;
  int32 numCVT;
  register F26Dot6 *cvt;
  register int16 *srcCVT;
{
	/* N is the Nummerator, and D is the Denominator */
	/* V is used as a temporary Value */
	register int32 N, D, V;
	register F26Dot6 					*endCvt   = cvt + numCVT;
	register fnt_GlobalGraphicStateType *globalGS = GLOBALGSTATE(key);
	transMatrix 						*trans	  = &key->currentTMatrix;

	N = key->interpScalar;
	D = (int32)key->emResolution << 16;
	/* We would like D to be perfectly dividable by 2 */
	{
		int shift = fsg_CountLowZeros( N | D ) - 1;
		if (shift > 0)
		{
			N >>= shift;
			D >>= shift;
		}
	}

		/* take the ABS(N) due to PostScript origin issues */
	if ( labs(N) < CANTAKESHIFT ) {
		N <<= fnt_pixelShift;
	} else {
		D >>= fnt_pixelShift;
	}

	if ( FITSINAWORD( (labs(N)) ) ) {
		register int16 	shift1 = fsg_GetShift( D );
		globalGS->nScale = N;
		globalGS->dScale = D;

	    if ( shift1 >= 0 ) {	/* FAST SCALE */
		globalGS->ScaleFunc = dfp_fnt_FRound;
		globalGS->shift	= shift1;
        	D >>= 1;
		for (; cvt < endCvt; cvt++ ) {
			V = SWAPWINC(srcCVT); FROUND( V, N, D, shift1 ); *cvt = V;
		}
	     } else {			/* MEDIUM SCALE */
			register int32 dOver2 = D >> 1;
			globalGS->ScaleFunc 	= dfp_fnt_SRound;
			for (; cvt < endCvt; cvt++ ) {
				V = SWAPWINC(srcCVT); SROUND( V, N, D, dOver2 ); *cvt = V;
			}
	     }
	} else {												/* SLOW SCALE */
		globalGS->ScaleFunc  = dfp_fnt_FixRound;
		globalGS->fixedScale = FixDiv( N, D );
		{
			register int16 tmp;
			int16 count = numCVT;
			Fixed scaler = globalGS->fixedScale;
			for (--count; count >= 0; --count)
				{
				tmp = SWAPWINC(srcCVT);
				*cvt++ = FixMul((Fixed)tmp , scaler );
				}
		}
	}
}


/*
 *	fsg_PreTransformGlyph				<3>
 */
static void fsg_PreTransformGlyph (key)
  register fsg_SplineKey* key;
{
	fnt_ElementType	*elementPtr	= &(key->elementInfoRec.interpreterElements[key->elementNumber]);
    register int16 numPts = NUMBEROFPOINTS(elementPtr);
	register Fixed	scale;

	scale = key->tInfo.xScale;
	if ( scale != ONEFIX )
	{
		register int32* oox = elementPtr->oox;
		register int16 count = numPts;
		for ( --count; count >= 0; --count, oox++ )
			*oox = FixMul( scale, *oox );
	}

	scale = key->tInfo.yScale;
	if ( scale != ONEFIX )
	{
		register int32* ooy = elementPtr->ooy;
		register int16 count = numPts;
		for ( --count; count >= 0; --count, ooy++ )
			*ooy = FixMul( scale, *ooy );
	}
}


/*
 * Styles for Cary
 */
static void fsg_CallStyleFunc (key, elementPtr)
  register fsg_SplineKey* key;
  register fnt_ElementType* elementPtr;
{
	register fs_GlyphInfoType* outputPtr = key->outputPtr;
	
	outputPtr->outlinesExist = key->glyphLength != 0;
	outputPtr->xPtr			 = elementPtr->x;
	outputPtr->yPtr			 = elementPtr->y;
	outputPtr->startPtr		 = elementPtr->sp;
	outputPtr->endPtr		 = elementPtr->ep;
	outputPtr->onCurve		 = elementPtr->onCurve;
	outputPtr->numberOfContours = elementPtr->nc;
	key->styleFunc( key->outputPtr );
}


/*
 *	fsg_PostTransformGlyph				<3>
 */
static void fsg_PostTransformGlyph (key, trans)
  register fsg_SplineKey *key;
  transMatrix *trans;
{
	register int16 	numPts;
	fnt_ElementType	*elementPtr	= &(key->elementInfoRec.interpreterElements[key->elementNumber]);
	register Fixed 	xStretch, yStretch;
	register F26Dot6* x;
	register F26Dot6* y;

	if ( key->identityTransformation ) return;

	numPts = NUMBEROFPOINTS(elementPtr);
	
	xStretch = key->tInfo.xScale;
	yStretch = key->tInfo.yScale;

	x = elementPtr->x;
	y = elementPtr->y;

	if ( xStretch == 0L || yStretch == 0L )
	{
		register F26Dot6 zero = 0;
		LOOPDOWN(numPts)
			*y++ = *x++ = zero;
	}
	else if ( !key->styleFunc )
	{
		if (fsg_HasPerspective( trans ))	/* undo stretch, then apply matrix */
		{
			LOOPDOWN(numPts)
			{
				*x = FixDiv( *x, xStretch );
				*y = FixDiv( *y, yStretch );;
				fsg_Dot6XYMul( x++, y++, trans );
			}
		}
		else	/* unroll the common case.  Fold stretch-undo and matrix together <4> */
		{
			Fixed m00 = FixDiv(trans->transform[0][0], xStretch);
			Fixed m01 = FixDiv(trans->transform[0][1], xStretch);
			Fixed m10 = FixDiv(trans->transform[1][0], yStretch);
			Fixed m11 = FixDiv(trans->transform[1][1], yStretch);
			LOOPDOWN(numPts)
			{
				register Fixed origx = *x;
				register Fixed origy = *y;
				*x++ = FixMul(m00, origx) + FixMul(m10, origy);
				*y++ = FixMul(m01, origx) + FixMul(m11, origy);
			}
		}
	}
	else	/* undo stretch, call stylefunc, then apply matrix */
	{
		register int16 count = numPts;
		LOOPDOWN(count)
		{
			*x = FixDiv( *x, xStretch );
			++x;
			*y = FixDiv( *y, yStretch );
			++y;
		}

		fsg_CallStyleFunc( key, elementPtr );	/* does this still work??? */

		x = elementPtr->x;
		y = elementPtr->y;
		LOOPDOWN(numPts)
			fsg_Dot6XYMul( x++, y++, trans );
	}
/*<8> take out contour reversal */
}


/*
 *	fsg_LocalPostTransformGlyph				<3>
 *
 * (1) Inverts the stretch from the CTM
 * (2) Applies the local transformation passed in in the trans parameter
 * (3) Applies the global stretch from the root CTM
 * (4) Restores oox, ooy, oy, ox, and f.
 */
static void fsg_LocalPostTransformGlyph (key, trans)
  register fsg_SplineKey *key;
  transMatrix *trans;
{
    register int16		numPts, count;
	register Fixed 		xScale, yScale;
	register F26Dot6*	x;
	register F26Dot6*	y;
	fnt_ElementType*	elementPtr = &(key->elementInfoRec.interpreterElements[key->elementNumber]);

	if ( !fsg_MoreThanXYStretch( trans ) ) return;

	numPts = count = NUMBEROFPOINTS(elementPtr);
	
	xScale = key->tInfo.xScale;
	yScale = key->tInfo.yScale;
	x = elementPtr->x;
	y = elementPtr->y;

	if ( xScale == 0L || yScale == 0L )
	{
		register F26Dot6 zero = 0;
		LOOPDOWN(numPts)
			*x++ = *y++ = zero;
	}
	else
	{
		LOOPDOWN(numPts)
		{
			*x = FixDiv( *x, xScale );
			*y = FixDiv( *y, yScale );
			fsg_Dot6XYMul( x++, y++, trans );
		}
	}

	xScale = key->globalTInfo.xScale;
	yScale = key->globalTInfo.yScale;
	
	if ( xScale != ONEFIX )
	{
		x = elementPtr->x;
		numPts = count;
		LOOPDOWN(numPts)
		{
			*x = FixMul( xScale, *x );
			x++;
		}
	}
	if ( yScale != ONEFIX )
	{
		y = elementPtr->y;
		numPts = count;
		LOOPDOWN(numPts)
		{
			*y = FixMul( yScale, *y );
			y++;
		}
	}

	fsg_CopyElementBackwards( &(key->elementInfoRec.interpreterElements[GLYPHELEMENT]) );
	x = elementPtr->oox;
	y = elementPtr->ooy;
	LOOPDOWN(count)
		fsg_Dot6XYMul( x++, y++, trans );
}


/*
 *	fsg_ShiftChar
 *
 *	Shifts a character			<3>
 */
static void fsg_ShiftChar (key, xShift, yShift, lastPoint)
  register fsg_SplineKey *key;
  register F26Dot6 xShift;
  register F26Dot6 yShift;
  int32 lastPoint;
{
	fnt_ElementType *elementPtr	= &(key->elementInfoRec.interpreterElements[key->elementNumber]);

	if ( xShift )
	{
		register F26Dot6* x = elementPtr->x;
		register LoopCount loop;
		for (loop = lastPoint; loop >= 0; --loop)
			*x++ += xShift;
	}
	if ( yShift )
	{
		register F26Dot6* y = elementPtr->y;
		register F26Dot6* lasty = y + lastPoint;
		while (y <= lasty)
			*y++ += yShift;
	}
}


/*
 *	fsg_ScaleChar						<3>
 *
 *	Scales a character and the advancewidth + leftsidebearing.
 */
static void fsg_ScaleChar (key)
  register fsg_SplineKey *key;
{
	fnt_ElementType			*elementPtr	= &(key->elementInfoRec.interpreterElements[key->elementNumber]);
	fnt_GlobalGraphicStateType *globalGS = GLOBALGSTATE(key);
	int16 numPts = NUMBEROFPOINTS(elementPtr);

	if ( globalGS->ScaleFunc == dfp_fnt_FRound )
	{
		register int32*	oop = elementPtr->oox;
		register F26Dot6* p = elementPtr->x;
		register int16 shift = globalGS->shift;
		register int32 N = globalGS->nScale;
		register int32 D = globalGS->dScale >> 1;
		register int32 V;
		register int16 count = numPts;		/* do I get this many registers? */
		LOOPDOWN(count)
		{
			V = *oop++; FROUND( V, N, D, shift ); *p++ = V;
		}
		p = elementPtr->y;
		oop = elementPtr->ooy;
		count = numPts;
		LOOPDOWN(count)
		{
			V = *oop++; FROUND( V, N, D, shift ); *p++ = V;
		}
	}
	else if ( globalGS->ScaleFunc == dfp_fnt_SRound )
	{
		register int32*	oop = elementPtr->oox;
		register F26Dot6* p = elementPtr->x;
		register int32 N = globalGS->nScale;
		register int32 D = globalGS->dScale;
		register int32 V;
		register int32 dOver2 = D >> 1;
		register int16 count = numPts;
		LOOPDOWN(count)
		{
			V = *oop++; SROUND( V, N, D, dOver2 ); *p++ = V;
		}
		
		p = elementPtr->y;
		oop = elementPtr->ooy;
		count = numPts;
		LOOPDOWN(count)
		{
			V = *oop++; SROUND( V, N, D, dOver2 ); *p++ = V;
		}
	}
	else
	{
		register int32*	oop = elementPtr->oox;
		register F26Dot6* p = elementPtr->x;
	    register int32 N = globalGS->fixedScale;
		register int16 count = numPts;
		LOOPDOWN(count)
			*p++ = FixMul( *oop++, N );
		p = elementPtr->y;
		oop = elementPtr->ooy;
		count = numPts;
		LOOPDOWN(count)
			*p++ = FixMul( *oop++, N );
	}
}


/*
 *	fsg_SetUpElement
 */
void fsg_SetUpElement (key, n)
  fsg_SplineKey *key;
  int32 n;
{
	register int8				*workSpacePtr	= (int8 *)key->memoryBases[WORK_SPACE_BASE];
	register fnt_ElementType 	*elementPtr;
	register fsg_OffsetInfo		*offsetPtr;


	offsetPtr			= &(key->elementInfoRec.offsets[n]);
	elementPtr			= &(key->elementInfoRec.interpreterElements[n]);

	
    elementPtr->x		= (int32 *)(workSpacePtr + offsetPtr->newXOffset);
    elementPtr->y		= (int32 *)(workSpacePtr + offsetPtr->newYOffset);
    elementPtr->ox		= (int32 *)(workSpacePtr + offsetPtr->scaledXOffset);
    elementPtr->oy		= (int32 *)(workSpacePtr + offsetPtr->scaledYOffset);
	elementPtr->oox		= (int32 *)(workSpacePtr + offsetPtr->oldXOffset);
	elementPtr->ooy		= (int32 *)(workSpacePtr + offsetPtr->oldYOffset);
    elementPtr->sp		= (int16 *)(workSpacePtr + offsetPtr->startPointOffset);
    elementPtr->ep		= (int16 *)(workSpacePtr + offsetPtr->endPointOffset);
    elementPtr->onCurve	= (uint8 *)(workSpacePtr + offsetPtr->onCurveOffset);
    elementPtr->f     	= (uint8 *)(workSpacePtr + offsetPtr->interpreterFlagsOffset);
	if ( n == TWILIGHTZONE ) {
		/* register int i, j; */
		elementPtr->sp[0]	= 0;	
		elementPtr->ep[0]	= SWAPW(key->maxProfile.maxTwilightPoints)-1;
	    elementPtr->nc		= MAX_TWILIGHT_CONTOURS;
	}
}


/*
 *	fsg_IncrementElement
 */
void fsg_IncrementElement (key, n, numPoints, numContours)
  fsg_SplineKey *key;
  int32 n, numPoints, numContours;
{
	register fnt_ElementType 	*elementPtr;

	elementPtr			= &(key->elementInfoRec.interpreterElements[n]);

	
    elementPtr->x		+= numPoints;
    elementPtr->y		+= numPoints;
    elementPtr->ox		+= numPoints;
    elementPtr->oy		+= numPoints;
	elementPtr->oox		+= numPoints;
	elementPtr->ooy		+= numPoints;
    elementPtr->sp		+= numContours;
    elementPtr->ep		+= numContours;
    elementPtr->onCurve	+= numPoints;
    elementPtr->f     	+= numPoints;

}


/*
 * fsg_ZeroOutTwilightZone			<3>
 */
static void fsg_ZeroOutTwilightZone (key)
  fsg_SplineKey *key;
{
	register int16 origCount = SWAPW(key->maxProfile.maxTwilightPoints);
	register F26Dot6 zero = 0;
	fnt_ElementType*  elementPtr = &(key->elementInfoRec.interpreterElements[TWILIGHTZONE]);
	{
		register F26Dot6* x = elementPtr->x;
		register F26Dot6* y = elementPtr->y;
		register int16 count = origCount;
		LOOPDOWN(count)
		{
			*x++ = zero;
			*y++ = zero;
		}
	}
	{
		register F26Dot6* ox = elementPtr->ox;
		register F26Dot6* oy = elementPtr->oy;
		LOOPDOWN(origCount)
		{
			*ox++ = zero;
			*oy++ = zero;
		}
	}
}


/*
 *	Assign pgmList[] for each pre program
 */
static void fsg_SetUpProgramPtrs (key, globalGS)
  fsg_SplineKey* key;
  fnt_GlobalGraphicStateType* globalGS;
{
	switch (globalGS->pgmIndex) {
	case PREPROGRAM:
		globalGS->pgmList[PREPROGRAM] = (uint8*)sfnt_GetTablePtr(key, sfnt_preProgram, false);
	case FONTPROGRAM:
		globalGS->pgmList[FONTPROGRAM] = (uint8*)sfnt_GetTablePtr(key, sfnt_fontProgram, false);
	}
#ifdef DEBUG
	globalGS->maxp = &key->maxProfile;
	globalGS->cvtCount = key->cvtCount;
#endif
}


static void fsg_SetUpTablePtrs (key)
  fsg_SplineKey* key;
{
	char** memoryBases = key->memoryBases;
	char* private_FontSpacePtr = memoryBases[PRIVATE_FONT_SPACE_BASE];
	fnt_GlobalGraphicStateType* globalGS = GLOBALGSTATE(key);
	
	switch (globalGS->pgmIndex) {
	case PREPROGRAM:
		globalGS->controlValueTable	= (F26Dot6*)(private_FontSpacePtr + key->offset_controlValues);
	case FONTPROGRAM:
		globalGS->store				= (F26Dot6*)(private_FontSpacePtr + key->offset_storage);
		globalGS->funcDef			= (fnt_funcDef*)(private_FontSpacePtr + key->offset_functions);
		globalGS->instrDef			= (fnt_instrDef*)(private_FontSpacePtr + key->offset_instrDefs);
		globalGS->stackBase			= (F26Dot6*)(memoryBases[WORK_SPACE_BASE] + key->elementInfoRec.stackBaseOffset);
		globalGS->function			= (FntFunc*)(memoryBases[VOID_FUNC_PTR_BASE]);
	}
}

/*
 *	Release pgmList[] for each pre program.
 *	Important that the order be reversed from SetUpProgramPtrs
 *		so that memory fragments are allocated and release in stack order
 */
#ifdef RELEASE_MEM_FRAG
static void fsg_ReleaseProgramPtrs(key, globalGS)
fsg_SplineKey* key;
fnt_GlobalGraphicStateType* globalGS;
{
	switch (globalGS->pgmIndex) {
	case FONTPROGRAM:
		RELEASESFNTFRAG(key, globalGS->pgmList[FONTPROGRAM]);
		break;
	case PREPROGRAM:
		RELEASESFNTFRAG(key, globalGS->pgmList[FONTPROGRAM]);
		RELEASESFNTFRAG(key, globalGS->pgmList[PREPROGRAM]);
	}
}
#endif


/*
 * fsg_RunPreProgram
 *
 * Runs the pre-program and scales the control value table
 *
 */
static int fsg_RunPreProgram (key, traceFunc)
  register fsg_SplineKey *key;
  voidFunc traceFunc;
{
	int32	offsetT;
	unsigned lengthT;
	int result;
	uint8* private_FontSpacePtr = (uint8*)key->memoryBases[PRIVATE_FONT_SPACE_BASE];
	F26Dot6* cvt = (F26Dot6*)(private_FontSpacePtr + key->offset_controlValues);

	fnt_GlobalGraphicStateType	*globalGS = GLOBALGSTATE(key);
	int32 numCvt;
	sfnt_ControlValue* cvtSrc = (sfnt_ControlValue*)sfnt_GetTablePtr( key, sfnt_controlValue, false );

	sfnt_GetOffsetAndLength( key, &offsetT, &lengthT, sfnt_controlValue );
	numCvt = lengthT / sizeof(sfnt_ControlValue);
	
	/* Set up the engine compensation array for the interpreter */
	/* This will be indexed into by the booleans in some instructions */
	globalGS->engine[0] = globalGS->engine[3] = 0;							/* Grey and ? distance */
	globalGS->engine[1] = FIXEDTODOT6(FIXEDSQRT2 - key->pixelDiameter);		/* Black distance */
	globalGS->engine[2] = -globalGS->engine[1];								/* White distance */

	globalGS->init 			= true;
	globalGS->pixelsPerEm	= FIXROUND( key->interpScalar );
	globalGS->pointSize		= FIXROUND( key->fixedPointSize );
	globalGS->fpem			= key->interpScalar;
	if( result = fsg_SetDefaults( key )) return result;		/* Set graphic state to default values */
	globalGS->localParBlock = globalGS->defaultParBlock;	/* copy gState parameters */

	key->globalTInfo.xScale = key->tInfo.xScale = globalGS->xStretch;
	key->globalTInfo.yScale = key->tInfo.yScale = globalGS->yStretch;

	fsg_ScaleCVT( key, numCvt, cvt, cvtSrc );

	RELEASESFNTFRAG(key, cvtSrc);

	globalGS->pgmIndex = (uint8)PREPROGRAM;
	fsg_SetUpProgramPtrs(key, globalGS);
	sfnt_GetOffsetAndLength( key, &offsetT, &lengthT, sfnt_preProgram );

	/** TWILIGHT ZONE ELEMENT **/
	fsg_SetUpElement( key, (int32)TWILIGHTZONE );
	fsg_ZeroOutTwilightZone( key );

	fsg_SetUpTablePtrs(key);
#ifdef DEBUG
	globalGS->glyphProgram = false;
#endif
	result = fnt_Execute( key->elementInfoRec.interpreterElements, globalGS->pgmList[PREPROGRAM],
							globalGS->pgmList[PREPROGRAM] + lengthT, globalGS, traceFunc );
	
	if( !(globalGS->localParBlock.instructControl & DEFAULTFLAG) )
		globalGS->defaultParBlock = globalGS->localParBlock;	/* change default parameters */
#ifdef RELEASE_MEM_FRAG
	fsg_ReleaseProgramPtrs(key, globalGS);
#endif

	return result;
}


/*
 *	All this guy does is record FDEFs and IDEFs, anything else is ILLEGAL
 */
int fsg_RunFontProgram (key, traceFunc)
  fsg_SplineKey* key;
  voidFunc traceFunc;
{
	int32 offsetT;
	unsigned lengthT;
	int result;
	fnt_GlobalGraphicStateType *globalGS = GLOBALGSTATE(key);

	globalGS->instrDefCount = 0;		/* none allocated yet, always do this, even if there's no fontProgram */
	
	sfnt_GetOffsetAndLength( key, &offsetT, &lengthT, sfnt_fontProgram );
	if (lengthT)
	{
		globalGS->pgmIndex = (uint8)FONTPROGRAM;
		fsg_SetUpProgramPtrs(key, globalGS);
		fsg_SetUpTablePtrs(key);
#ifdef DEBUG
		globalGS->glyphProgram = false;
#endif
		result = fnt_Execute( key->elementInfoRec.interpreterElements, globalGS->pgmList[FONTPROGRAM],
			globalGS->pgmList[FONTPROGRAM] + lengthT, globalGS, traceFunc );
#ifdef RELEASE_MEM_FRAG
		fsg_ReleaseProgramPtrs(key, globalGS);
#endif

		return result;
	}
	return NO_ERR;
}

#ifdef __GEOS__
F26Dot6 fsg_dummyRound (xin, engine, gs)
  register F26Dot6 xin;
  F26Dot6 engine;
  fnt_LocalGraphicStateType* gs;
{
	return(fnt_RoundToGrid(xin, engine, gs));
}
#endif


/* Set default values for all variables in globalGraphicsState DefaultParameterBlock
 *	Eventually, we should provide for a Default preprogram that could optionally be 
 *	run at this time to provide a different set of default values.
 */
int fsg_SetDefaults (key)
  fsg_SplineKey* key;
{
	register fnt_GlobalGraphicStateType *globalGS = GLOBALGSTATE(key);
	register fnt_ParameterBlock *par = &globalGS->defaultParBlock;
	
#if 0
	par->RoundValue = (dfpf26 = &fsg_dummyRound);
	/* code below generates virtual segment even though it is in same
	   code segment */
#else
	par->RoundValue  = dfp_fsg_fnt_RoundToGrid;
#endif
	par->minimumDistance = fnt_pixelSize;
	par->wTCI = fnt_pixelSize * 17 / 16;
	par->sWCI = 0;
	par->sW   = 0;
	par->autoFlip = true;
	par->deltaBase = 9;
	par->deltaShift = 3;
	par->angleWeight = 128;
	par->scanControl = 0;
	par->instructControl = 0;
	return 0;
}


/* 
 * Runs the pre program and scales the control value table
 */
int fsg_NewTransformation (key, traceFunc)
  register fsg_SplineKey *key;
  voidFunc traceFunc;
{
	/* Run the pre program and scale the control value table */
	key->executePrePgm = false;
	return fsg_RunPreProgram( key, traceFunc );
}


/*
 *	fsg_InnerGridFit
 */
int fsg_InnerGridFit (key, useHints, traceFunc, bbox, sizeOfInstructions,
                      instructionPtr, finalCompositePass)
  register fsg_SplineKey *key;
  int16 useHints;
  voidFunc traceFunc;
  sfnt_BBox *bbox;
  int32 sizeOfInstructions;
  uint8 *instructionPtr;
  int finalCompositePass;
{
	fnt_GlobalGraphicStateType* globalGS = GLOBALGSTATE(key);

	register fnt_ElementType 	*elementPtr;

	/* this is so we can allow recursion */
	int32 *save_x, *save_y, *save_ox, *save_oy, *save_oox, *save_ooy;
	int16 *save_sp, *save_ep;
	uint8 *save_onCurve, *save_f;
	int16 save_nc, numPts;
	
	elementPtr = &(key->elementInfoRec.interpreterElements[GLYPHELEMENT]);
	if ( finalCompositePass ) {
		/* save stuff we are going to muck up below, so we can recurse */
		save_x 			= elementPtr->x;
		save_y 			= elementPtr->y;
		save_ox 		= elementPtr->ox;
		save_oy 		= elementPtr->oy;
		save_oox 		= elementPtr->oox;
		save_ooy 		= elementPtr->ooy;
		save_sp 		= elementPtr->sp;
		save_ep 		= elementPtr->ep;
		save_onCurve 	= elementPtr->onCurve;
		save_f 			= elementPtr->f;
		save_nc 		= elementPtr->nc;
	
		elementPtr->nc = key->totalContours;
		fsg_SetUpElement( key, (int32)GLYPHELEMENT ); /* Set it up again so we can process as one glyph */
	}
	
	key->elementNumber = GLYPHELEMENT;
	numPts = NUMBEROFPOINTS(elementPtr);
	{
		F26Dot6 xMinMinusLSB = bbox->xMin - key->nonScaledLSB;

		/* left side bearing point */
		elementPtr->oox[numPts-PHANTOMCOUNT+LEFTSIDEBEARING] = xMinMinusLSB;
		elementPtr->ooy[numPts-PHANTOMCOUNT+LEFTSIDEBEARING] = 0;
		
		/* origin left side bearing point */
		elementPtr->oox[numPts-PHANTOMCOUNT+ORIGINPOINT] = xMinMinusLSB;
		elementPtr->ooy[numPts-PHANTOMCOUNT+ORIGINPOINT] = 0;
		
		/* left edge point */
		elementPtr->oox[numPts-PHANTOMCOUNT+LEFTEDGEPOINT] = bbox->xMin;
		elementPtr->ooy[numPts-PHANTOMCOUNT+LEFTEDGEPOINT] = 0;
		
		/* right side bearing point */
		elementPtr->oox[numPts-PHANTOMCOUNT+RIGHTSIDEBEARING] = xMinMinusLSB + key->nonScaledAW;
		elementPtr->ooy[numPts-PHANTOMCOUNT+RIGHTSIDEBEARING] = 0;
	}
	key->tInfo.xScale = globalGS->xStretch;
	key->tInfo.yScale = globalGS->yStretch;

		/* Pretransform, scale, and copy */
	if ( finalCompositePass)
	{
		register GlobalGSScaleFunc ScaleFunc = globalGS->ScaleFunc;
		register int32 j;
		register Fixed scale = key->tInfo.xScale;

		for ( j = numPts - PHANTOMCOUNT; j < numPts; j++ )
		{
			if (scale != ONEFIX)
				elementPtr->oox[j] = FixMul( scale, elementPtr->oox[j] );
/* FCALL */
			elementPtr->ox[j]  = PCFM(globalGS, elementPtr->oox[j], ScaleFunc );
			elementPtr->x[j]   = elementPtr->ox[j];
		}
		scale = key->tInfo.yScale;
		for ( j = numPts - PHANTOMCOUNT; j < numPts; j++ )
		{
			if (scale != ONEFIX)
				elementPtr->ooy[j] = FixMul( scale, elementPtr->ooy[j] );
/* FCALL */
			elementPtr->oy[j]  = PCFM(globalGS, elementPtr->ooy[j], ScaleFunc );
			elementPtr->y[j]   = elementPtr->oy[j];
		}
	}
	else
	{
		fsg_PreTransformGlyph( key );
		fsg_ScaleChar( key );
	}
	
	if ( useHints ) { /* AutoRound */
		int32 oldLeftOrigin, newLeftOrigin, xShift;

		newLeftOrigin = oldLeftOrigin = elementPtr->x[numPts-PHANTOMCOUNT+LEFTSIDEBEARING];
		newLeftOrigin += fnt_pixelSize/2; /* round to a pixel boundary */
		newLeftOrigin &= ~(fnt_pixelSize-1);
		xShift = newLeftOrigin - oldLeftOrigin;
		
		if ( !finalCompositePass ) {
			/* We can't shift if it is the final composite pass */
			fsg_ShiftChar( key, xShift, 0L, (int32)NUMBEROFPOINTS(elementPtr) - 1 );
			/* Now the distance from the left origin point to the character is exactly lsb */
		}
		fsg_CopyElementBackwards( elementPtr );
		/* Fill in after fsg_ShiftChar(), since this point should not be shifted. */
		elementPtr->x[numPts-PHANTOMCOUNT+LEFTSIDEBEARING]  = newLeftOrigin;
		elementPtr->ox[numPts-PHANTOMCOUNT+LEFTSIDEBEARING] = newLeftOrigin;
		{
			F26Dot6 width = ShortMulDiv( key->interpScalar,
							elementPtr->oox[numPts-PHANTOMCOUNT+RIGHTSIDEBEARING]
							- elementPtr->oox[numPts-PHANTOMCOUNT+LEFTSIDEBEARING],
							key->emResolution ) + (1L << 9) >> 10;
			elementPtr->x[numPts-PHANTOMCOUNT+RIGHTSIDEBEARING] = 
			elementPtr->x[numPts-PHANTOMCOUNT+LEFTSIDEBEARING] + (width + (1 << 5)) & ~63;
		}
	}

	globalGS->init			= false;
	globalGS->pixelsPerEm	= FIXROUND( key->interpScalar );
	globalGS->pointSize		= FIXROUND( key->fixedPointSize );
	globalGS->fpem			= key->interpScalar;
	globalGS->localParBlock = globalGS->defaultParBlock;	/* default parameters for glyphs */
	if ( useHints && sizeOfInstructions > 0 )
	{
		int32 result;

		if ( finalCompositePass )
			fsg_SnapShotOutline( key, elementPtr, numPts );

		globalGS->pgmIndex = (uint8)PREPROGRAM;
		fsg_SetUpProgramPtrs(key, globalGS);
		fsg_SetUpTablePtrs(key);
#ifdef DEBUG
		globalGS->glyphProgram = true;
#endif
		result = fnt_Execute( key->elementInfoRec.interpreterElements, instructionPtr, 
					 instructionPtr + sizeOfInstructions, globalGS, traceFunc );
#ifdef RELEASE_MEM_FRAG
		fsg_ReleaseProgramPtrs(key, globalGS);
#endif
		if (result)
			return result;
	}
	/* Now make everything into one big glyph. */
	if ( key->weGotComponents  && !finalCompositePass ) {
		int16 n, ctr;
		int32 xOffset, yOffset;	

		/* Fix start points and end points */
		n = 0;
		if ( key->totalComponents != GLYPHELEMENT )
			n += elementPtr->ep[-1] + 1; /* number of points */

		if ( !key->localTIsIdentity )
			fsg_LocalPostTransformGlyph( key, &key->localTMatrix );

		if ( key->compFlags & ARGS_ARE_XY_VALUES ) {
			xOffset = key->arg1;
			yOffset = key->arg2;
/* FCALL */
			xOffset = PCFM(globalGS, xOffset, globalGS->ScaleFunc );
/* FCALL */
			yOffset = PCFM(globalGS, yOffset, globalGS->ScaleFunc );
			
			
			if ( !key->identityTransformation ) {
				/* transform offsets into this funky domain */
				xOffset = FixMul( globalGS->xStretch, xOffset );			
				yOffset = FixMul( globalGS->yStretch, yOffset );			
			}
			
			if ( key->compFlags & ROUND_XY_TO_GRID ) {
				xOffset += fnt_pixelSize/2; xOffset &= ~(fnt_pixelSize-1);
				yOffset += fnt_pixelSize/2; yOffset &= ~(fnt_pixelSize-1);
			}
		} else {
			xOffset = elementPtr->x[ key->arg1 - n ] - elementPtr->x[ key->arg2 ];
			yOffset = elementPtr->y[ key->arg1 - n ] - elementPtr->y[ key->arg2 ];
		}
		
		/* shift all the points == Align the component */
		fsg_ShiftChar( key, xOffset, yOffset, (int32)NUMBEROFPOINTS(elementPtr) - 1 );

		/*
		 *	Remember this component's phantom points after we've munged it
		 */
		if (key->compFlags & USE_MY_METRICS)
		{
			ArrayIndex index = elementPtr->ep[ elementPtr->nc - 1 ] + 1;
			F26Dot6* x = &elementPtr->x[ index ];
			F26Dot6* y = &elementPtr->y[ index ];
			key->devLSB.x = *x++;
			key->devLSB.y = *y++;
			key->devRSB.x = *x;
			key->devRSB.y = *y;
			key->useMyMetrics = true;
		}

		/* reverse contours if needed; <8> not any more */

		if ( key->totalComponents != GLYPHELEMENT ) {
			/* Fix start points and end points */
			for ( ctr = 0; ctr < elementPtr->nc; ctr++ ) {
				elementPtr->sp[ctr] += n;			
				elementPtr->ep[ctr] += n;
			}
		}
	}
	
	if ( finalCompositePass )
	{
		/*
		 *	This doesn't work recursively yet, but then again, nothing does.
		 */
		if (key->useMyMetrics)
		{
			ArrayIndex index = elementPtr->ep[ elementPtr->nc - 1 ] + 1;
			F26Dot6* x = &elementPtr->x[ index ];
			F26Dot6* y = &elementPtr->y[ index ];
			*x++ = key->devLSB.x;
			*y++ = key->devLSB.y;
			*x = key->devRSB.x;
			*y = key->devRSB.y;
			key->useMyMetrics = false;
		}
		elementPtr->x		= save_x;
		elementPtr->y		= save_y;
		elementPtr->ox		= save_ox;
		elementPtr->oy		= save_oy;
		elementPtr->oox		= save_oox;
		elementPtr->ooy		= save_ooy;
		elementPtr->sp		= save_sp;
		elementPtr->ep		= save_ep;
		elementPtr->onCurve	= save_onCurve;
		elementPtr->f     	= save_f;
		elementPtr->nc		= save_nc;
	}
	key->scanControl = globalGS->localParBlock.scanControl; /*rwb */
	return NO_ERR;
}


/*
 * Internal routine.	changed to use pointer			<3>
 */
static void fsg_InitLocalT (key)
  fsg_SplineKey* key;
{
	register Fixed* p = &key->localTMatrix.transform[0][0];
	register Fixed one = ONEFIX;
	register Fixed zero = 0;
	*p++ = one;
	*p++ = zero;
	*p++ = zero;
	
	*p++ = zero;
	*p++ = one;
	*p++ = zero;
	
	*p++ = zero;
	*p++ = zero;
	*p   = one;		/* Internal routines assume ONEFIX here, though client assumes ONEFRAC */
}


/*
 *	fsg_GridFit
 */
int fsg_GridFit (key, traceFunc, useHints)
  register fsg_SplineKey* key;
  voidFunc traceFunc;
  boolean useHints;
{
 	int	result;
	int16	elementCount;
	fnt_GlobalGraphicStateType* globalGS = GLOBALGSTATE(key);
	
	fsg_SetUpElement( key, (int32)TWILIGHTZONE );/* TWILIGHT ZONE ELEMENT */

	elementCount = GLYPHELEMENT;

	key->weGotComponents = false;
	key->compFlags = NON_OVERLAPPING;
	key->useMyMetrics = false;

	/* This also calls fsg_InnerGridFit() .*/
	if( globalGS->localParBlock.instructControl & NOGRIDFITFLAG ) useHints = false;
	key->localTIsIdentity = true;
	fsg_InitLocalT( key );
	if ( (result = sfnt_ReadSFNT( key, &elementCount, key->glyphIndex, useHints, traceFunc )) == NO_ERR )
	{		
		key->elementInfoRec.interpreterElements[GLYPHELEMENT].nc = key->totalContours;
	
		if ( key->weGotComponents )
			fsg_SetUpElement( key, (int32)GLYPHELEMENT ); /* Set it up again so we can transform */
	
		fsg_PostTransformGlyph( key, &key->currentTMatrix );
	}
	return result;
}

#pragma Code ()
