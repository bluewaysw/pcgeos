/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/fnt.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: fnt.c,v 1.1 97/04/18 11:45:19 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("TTFntCode")

/* fnt.c */
/* Revision Control Information *********************************
 *	$Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/fnt.c,v 1.1 97/04/18 11:45:19 newdeal Exp $
 *	$Log:	fnt.c,v $
 * Revision 1.1  97/04/18  11:45:19  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:05  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:14:43  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:07:41  roberte
 * Release
 * 
 * Revision 6.9  93/03/09  13:06:06  roberte
 * Broke assignment of gs->Interpreter apart from call of the function pointer.
 * Clearer more portable code.
 * 
 * Revision 6.8  93/01/25  09:37:47  roberte
 * Employed PROTO macro for all function prototypes.
 * 
 * Revision 6.7  93/01/19  10:41:09  davidw
 * 80 column cleanup, ANSI compatability cleanup
 * 
 *
 * Revision 6.6  92/12/29  12:49:24  roberte
 * Now includes "spdo_prv.h" first.
 * Also handled conflict for BIT0..BIT7 macros with those in speedo.h.
 * 
 * Revision 6.5  92/12/15  14:11:58  roberte
 * Commented out #pragma.
 * 
 * Revision 6.4  92/11/24  13:35:55  laurar
 * include fino.h
 * 
 * Revision 6.3  92/11/19  15:45:35  roberte
 * Release
 * 
 * Revision 6.2  92/10/15  11:48:47  roberte
 * Changed all ifdef PROTOS_AVAIL statements to if PROTOS_AVAIL.
 * 
 * Revision 6.1  91/08/14  16:44:56  mark
 * Release
 * 
 * Revision 5.1  91/08/07  12:26:08  mark
 * Release
 * 
 * Revision 4.2  91/08/07  11:38:58  mark
 * added RCS control strings
 * 
*/

#ifdef RCSSTATUS
static char rcsid[] = "$Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/fnt.c,v 1.1 97/04/18 11:45:19 newdeal Exp $";
#endif

/*
	File:		fnt.c

	Copyright:(c) 1987-1990 by Apple Computer, Inc., all rights reserved.

    This file is used in these builds: BigBang

	Change History (most recent first):

		 <9>	12/20/90	RB		Add mr initials to previous change comment. [mr]
		 <8>	12/20/90	RB		Fix bug in INSTCTRL so unselected flags are not
									changed.[mr]
		 <7>	 12/5/90	MR		Change RAW to use the phantom points.
		 <6>	11/27/90	MR		Fix bogus debugging in Check_ElementPtr. [rb]
		 <5>	11/16/90	MR		More debugging code [rb]
		 <4>	 11/9/90	MR		Fix non-portable C (dup, depth, pushsomestuff)
									[rb]
		 <3>	 11/5/90	MR		Use proper types in fnt_Normalize, change
									globalGS.ppemDot6 to globalGS.fpem. Make
									instrPtrs all uint8*. Removed conditional code
									for long vectors. [rb]
		 <2>	10/20/90	MR		Restore changes since project died. Converting
									to 2.14 vectors, smart math routines. [rb]
		<24>	 8/16/90	RB		Fix IP to use oo domain
		<22>	 8/11/90	MR		Add Print debugging function
		<21>	 8/10/90	MR		Make SFVTL check like SPVTL does
		<20>	  8/1/90	MR		remove call to fnt_NextPt1 macro in fnt_SHC
		<19>	 7/26/90	MR		Fix bug in SHC
		<18>	 7/19/90	dba		get rid of C warnings
		<17>	 7/18/90	MR		What else, more Ansi-C fixes
		<16>	 7/13/90	MR		Added runtime range checking, various ansi-fixes
		<15>	  7/2/90	RB		combine variables into parameter block.
		<12>	 6/26/90	RB		bugfix in divide instruction
		<11>	 6/21/90	RB		bugfix in scantype
		<10>	 6/12/90	RB		add scantype instruction, add selector variable
									to getinfo instruction
		 <9>	 6/11/90	CL		Using the debug call.
		 <8>	  6/4/90	MR		Remove MVT
		 <7>	  6/3/90	RB		no change
		 <6>	  5/8/90	RB		revert to version 4
		 <5>	  5/4/90	RB		mrr-more optimization, errorchecking
		 <4>	  5/3/90	RB		more optimization. decreased code size.
		 <4>	  5/2/90	MR		mrr - added support for IDEF mrr - combined
									multiple small instructions into switchs e.g.
									BinaryOperands, UnaryOperand, etc. (to save
									space) mrr - added twilightzone support to
									fnt_WC, added fnt_ROTATE, fnt_MAX and fnt_MIN.
									Max and Min are in fnt_BinaryOperand. Optimized
									various functions for size.  Optimized loops in
									push statements and alignrp for speed. gs->loop
									now is base-0. so gs->loop == 4 means do it 5
									times.
		 <3>	 3/20/90	MR		Added support for multiple preprograms. This
									touched function calls, definitions. Fractional
									ppem (called ppemDot6 in globalGS Add new
									instructions ELSE, JMPR Experimenting with
									RMVT, WMVT Removed lots of the MR_MAC #ifdefs,
									GOSLOW, Added MFPPEM, MFPS as experiments
									(fractional versions) Added high precision
									multiply and divide for MUL and DIV Changed
									fnt_MD to use oox instead of ox when it can
									(more precise) fnt_Init: Initialize instruction
									jump table with *p++ instead of p[index]
									Changed fnt_AngleInfo into fnt_FractPoint and
									int16 for speed and to maintain long alignment
									Switch to Loop in PUSHB and PUSHW for size
									reduction Speed up GetCVTScale to avoid
									FracMul(1.0, transScale) (sampo)
		 <2>	 2/27/90	CL		Added DSPVTL[] instruction.  Dropout control
									scanconverter and SCANCTRL[] instruction.
									BugFix in SFVTL[], and SFVTOPV[]. 
									Fixed bug in fnt_ODD[] and fnt_EVEN[]. 
									Fixed bug in fnt_Normalize 
		<3.4>	11/16/89	CEL		Added new functions fnt_FLIPPT, fnt_FLIPRGON
									and fnt_FLIPRGOFF.
	   <3.3>	11/15/89	CEL		Put function array check in ifndef so printer
									folks could
									exclude the check.
	   <3.2>	11/14/89	CEL		Fixed two small bugs/feature in RTHG, and RUTG.
									Added SROUND & S45ROUND.
	   <3.1>	 9/27/89	CEL		GetSingleWidth slow was set to incorrect value.
									Changed rounding routines, so that the sign
									flip check only apply if the input value is
									nonzero.
	   <3.0>	 8/28/89	sjk		Cleanup and one transformation bugfix
	   <2.3>	 8/14/89	sjk		1 point contours now OK
	   <2.2>	  8/8/89	sjk		Now allow the system to muck with high bytes of
									addresses
	   <2.1>	  8/8/89	sjk		Improved encryption handling
	   <2.0>	  8/2/89	sjk		Just fixed EASE comment
	   <1.8>	  8/1/89	sjk		Added in composites and encryption. Plus other
									enhancementsI
	   <1.7>	 6/13/89	sjk		fixed broken delta instruction
	   <1.6>	 6/13/89	SJK		Comment
	   <1.5>	  6/2/89	CEL		16.16 scaling of metrics, minimum recommended
									ppem, point size 0 bug, correct transformed
									integralized ppem behavior, pretty much so
	   <1.4>	 5/26/89	CEL		EASE messed up on RcS comments
	  <%1.3>	 5/26/89	CEL		Integrated the new Font Scaler 1.0 into Spline
									Fonts

	To Do:
/* rwb 4/24/90 - changed scanctrl instruction to take 16 bit argument */
/******* MIKE PLEASE FIX up these comments so they fit in the header above with the same FORMAT!!! */
/*
 * File: fnt.c
 *
 * This module contains the interpreter that executes font instructions
 *
 * The BASS Project Interpreter and Font Instruction Set sub ERS contains
 * relevant information.
 *
 * (c) Apple Computer Inc. 1987, 1988, 1989, 1990.
 *
 * History:
 * Work on this module began in the fall of 1987
 *
 * Written June 23, 1988 by Sampo Kaasila
 *
 * Rewritten October 18, 1988 by Sampo Kaasila. Added a jump table instead of the
 * switch statement. Also added CALL(), LOOPCALL(), FDEF(), ENDF(), and replaced
 * WX(),WY(), RX(), RY(), MD() with new WC(), RC(), MD(). Reimplemented IUP(). Also
 * optimized the code somewhat. Cast code into a more digestable form using a local
 * and global graphics state.
 *
 * December 20, 1988. Added DELTA(), SDB(), SDS(), and deleted ONTON(), and
 * ONTOFF(). ---Sampo.
 * January 17, 1989 Added DEBUG(), RAW(), RLSB(), WLSB(), ALIGNPTS(), SANGW(), AA().
 *			    Brought up this module to an alpha ready state. ---Sampo
 *
 * January 31, 1989 Added RDTG(), and RUTG().
 *
 * Feb 16, 1989 Completed final bug fixes for the alpha release.
 *
 * March 21, 1989 Fixed a small Twilight Zone bug in MIAP(), MSIRP(), and MIRP().
 *
 * March 28, 1989 Took away the need and reason for directional switches in the
 * control value table. However, this forced a modification of all the code that
 * reads or writes to the control value table and the single width. Also WCVT was
 * replaced by WCVTFOL, WCVTFOD, and WCVTFCVT. ---Sampo
 *
 * April 17, 1989 Modified RPV(), RFV(), WPV(), WFV() to work with an x & y pair
 * instead of just x. --- Sampo
 *
 * April 25, 1989 Fixed bugs in CEILING(), RUTG(), FDEF(), and IF(). Made MPPEM() a
 * function of the projection vector. ---Sampo
 *
 * June 7, 1989 Made ALIGNRP() dependent on the loop variable, and also made it
 * blissfully ignorant of the twilight zone. Also, added ROFF(), removed WCVTFCVT()
 * , renamed WCVTFOL() to WCVT(), made MIRP() and MDRP() compensate for the engine
 * even when there is no rounding. --- Sampo
 *
 * June 8, 1989 Made DELTA() dependent on the Transformation. ---Sampo
 *
 * June 19, 1989 Added JROF() and JROT(). ---Sampo
 *
 * July 14, 1989 Forced a pretty tame behaviour when abs((projection vector) *
 * (freedoom vector)) < 1/16. The old behaviour was to grossly blow up the outline.
 * This situation may happen for low pointsizes when the character is severly
 * distorted due to the gridfitting ---Sampo
 *
 * July 17, 1989 Prevented the rounding routines from changing the sign of a
 * quantity due to the engine compensation. ---Sampo
 *
 * July 19, 1989 Increased nummerical precision of fnt_MovePoint by 8 times.
 * ---Sampo
 *
 * July 28, 1989 Introduced 5 more Delta instructions. (Now 3 are for points and 3
 * for the cvt.) ---Sampo
 *
 * Aug 24, 1989 fixed fnt_GetCVTEntrySlow and fnt_GetSingleWidthSlow bug ---Sampo
 *
 * Sep 26, 1989 changed rounding routines, so that the sign flip check only apply
 * if the input value is nonzero. ---Sampo
 *
 * Oct 26, 1989 Fixed small bugs/features in fnt_RoundUpToGrid() and
 * fnt_RoundToHalfGrid. Added SROUND() and S45ROUND(). ---Sampo
 *
 * Oct 31, 1989 Fixed transformation bug in fnt_MPPEM, fnt_DeltaEngine,
 * fnt_GetCvtEntrySlow, fnt_GetSingleWidthSlow. ---Sampo
 *
 * Nov 3, 1989 Added FLIPPT(), FLIPRGON(), FLIPRGOFF(). ---Sampo
 *
 * Nov 16, 1989 Merged back in lost Nov 3 changes.---Sampo
 *
 * Dec 2, 1989 Added READMETRICS() aand WRITEMETRICS(). --- Sampo
 *
 * Jan 8, 1990 Added SDPVTL(). --- Sampo
 *
 * Jan 8, 1990 Eliminated bug in SFVTPV[] ( old bug ) and SFVTL[] (showed up
 * because of SDPVTL[]). --- Sampo
 *
 * Jan 9, 1990 Added the SCANCTRL[] instruction. --- Sampo
 *
 * Jan 24, 1990 Fixed bug in fnt_ODD and fnt_EVEN. ---Sampo
 *
 * Jan 28, 1990 Fixed bug in fnt_Normalize. --- Sampo
 *
 * 2/9/90	mrr	ReFixed Normalize bug, added ELSE and JMPR.  Added pgmList[] to
 * globalGS in preparation for 3 preprograms.  affected CALL, LOOPCALL, FDEF
 * 2/21/90	mrr	Added RMVT, WMVT.
 * 3/7/90	mrr		put in high precision versions of MUL and DIV.
 */


#include <setjmp.h>

#include "spdo_prv.h"
#include "fino.h"

/** FontScalerUs Includes **/
#include "fscdefs.h"
#include "fontmath.h"
#include "sc.h"
#include "fnt.h"
#include "fserror.h"

/****** Macros *******/
#define POP( p )     ( *(--p) )
#define PUSH( p, x ) ( *(p)++ = (x) )

#define BADCOMPILER

#ifdef BADCOMPILER
#define BOOLEANPUSH( p, x ) PUSH( p, ((x) ? 1 : 0) ) /* MPW 3.0 */
#else
#define BOOLEANPUSH( p, x ) PUSH( p, x )
#endif


#define MAX(a,b)	((a) > (b) ? (a) : (b))

#ifdef DEBUG
void CHECK_RANGE(int32 n, int32 min, int32 max);
void CHECK_RANGE(int32 n, int32 min, int32 max)
{
	if (n > max || n < min)
		Debugger();
}
void CHECK_ASSERTION( int expression );
void CHECK_ASSERTION( int expression )
{
	if (!expression)
		Debugger();
}
void CHECK_CVT(fnt_LocalGraphicStateType* gs, int cvt);
void CHECK_CVT(fnt_LocalGraphicStateType* gs, int cvt)
{
	CHECK_RANGE(cvt, 0, gs->globalGS->cvtCount-1);
}
void CHECK_FDEF(fnt_LocalGraphicStateType* gs, int fdef);
void CHECK_FDEF(fnt_LocalGraphicStateType* gs, int fdef)
{
	CHECK_RANGE(fdef, 0, gs->globalGS->maxp->maxFunctionDefs-1);
}
void CHECK_PROGRAM(int pgmIndex);
void CHECK_PROGRAM(int pgmIndex)
{
	CHECK_RANGE(pgmIndex, 0, MAXPREPROGRAMS-1);
}
void CHECK_ELEMENT(fnt_LocalGraphicStateType* gs, int elem);
void CHECK_ELEMENT(fnt_LocalGraphicStateType* gs, int elem)
{
	CHECK_RANGE(elem, 0, gs->globalGS->maxp->maxElements-1);
}
void CHECK_ELEMENTPTR(fnt_LocalGraphicStateType* gs, fnt_ElementType* elem);
void CHECK_ELEMENTPTR(fnt_LocalGraphicStateType* gs, fnt_ElementType* elem)
{	
	if (elem == &gs->elements[1]) {
		int maxctrs, maxpts;

		maxctrs = MAX(gs->globalGS->maxp->maxContours,
					  gs->globalGS->maxp->maxCompositeContours);
		maxpts  = MAX(gs->globalGS->maxp->maxPoints,
					  gs->globalGS->maxp->maxCompositePoints);

		CHECK_RANGE(elem->nc, 1, maxctrs);
		CHECK_RANGE(elem->ep[elem->nc-1], 0, maxpts-1);
	} else if (elem != &gs->elements[0])
	{
		Debugger();
	}
}
void CHECK_STORAGE(fnt_LocalGraphicStateType* gs, int index);
void CHECK_STORAGE(fnt_LocalGraphicStateType* gs, int index)
{
	CHECK_RANGE(index, 0, gs->globalGS->maxp->maxStorage-1);
}
void CHECK_STACK(fnt_LocalGraphicStateType* gs);
void CHECK_STACK(fnt_LocalGraphicStateType* gs)
{
	CHECK_RANGE(gs->stackPointer - gs->globalGS->stackBase,
				0,
				gs->globalGS->maxp->maxStackElements-1);
}
void CHECK_POINT(fnt_LocalGraphicStateType* gs, fnt_ElementType* elem, int pt);
void CHECK_POINT(fnt_LocalGraphicStateType* gs, fnt_ElementType* elem, int pt)
{
	CHECK_ELEMENTPTR(gs, elem);
	if (gs->elements == elem)
		CHECK_RANGE(pt, 0, gs->globalGS->maxp->maxTwilightPoints - 1);
	else
		CHECK_RANGE(pt, 0, elem->ep[elem->nc-1] + 2);	/* phantom points */
}
void CHECK_CONTOUR(fnt_LocalGraphicStateType* gs, fnt_ElementType* elem, int ctr);
void CHECK_CONTOUR(fnt_LocalGraphicStateType* gs, fnt_ElementType* elem, int ctr)
{
	CHECK_ELEMENTPTR(gs, elem);
	CHECK_RANGE(ctr, 0, elem->nc - 1);
}
#define CHECK_POP(gs, s)		POP(s)
#define CHECK_PUSH(gs, s, v)	PUSH(s, v)
#else
#define CHECK_RANGE(a,b,c)
#define CHECK_ASSERTION(a)
#define CHECK_CVT(a,b)
#define CHECK_POINT(a,b,c)
#define CHECK_CONTOUR(a,b,c)
#define CHECK_FDEF(a,b)
#define CHECK_PROGRAM(a)
#define CHECK_ELEMENT(a,b)
#define CHECK_ELEMENTPTR(a,b)
#define CHECK_STORAGE(a,b)
#define CHECK_STACK(a)
#define CHECK_POP(gs, s)		POP(s)
#define CHECK_PUSH(gs, s, v)	PUSH(s, v)
#endif

#define GETBYTE(ptr)	( (uint8)*ptr++ )
#define MABS(x)			( (x) < 0 ? (-(x)) : (x) )

#ifdef BIT0
/* these are defined differently in speedo.h: */
#undef BIT0
#undef BIT1
#undef BIT2
#undef BIT3
#undef BIT4
#undef BIT5
#undef BIT6
#undef BIT7
#endif

#define BIT0( t ) ( (t) & 0x01 )
#define BIT1( t ) ( (t) & 0x02 )
#define BIT2( t ) ( (t) & 0x04 )
#define BIT3( t ) ( (t) & 0x08 )
#define BIT4( t ) ( (t) & 0x10 )
#define BIT5( t ) ( (t) & 0x20 )
#define BIT6( t ) ( (t) & 0x40 )
#define BIT7( t ) ( (t) & 0x80 )

/******** 12 BinaryOperators **********/
#define LT_CODE		0x50
#define LTEQ_CODE	0x51
#define GT_CODE		0x52
#define GTEQ_CODE	0x53
#define EQ_CODE		0x54
#define NEQ_CODE	0x55
#define AND_CODE	0x5A
#define OR_CODE		0x5B
#define ADD_CODE	0x60
#define SUB_CODE	0x61
#define DIV_CODE	0x62
#define MUL_CODE	0x63
#define MAX_CODE	0x8b
#define MIN_CODE	0x8c

/******** 9 UnaryOperators **********/
#define ODD_CODE		0x56
#define EVEN_CODE		0x57
#define NOT_CODE		0x5C
#define ABS_CODE		0x64
#define NEG_CODE		0x65
#define FLOOR_CODE		0x66
#define CEILING_CODE	0x67

/******** 6 RoundState Codes **********/
#define RTG_CODE		0x18
#define RTHG_CODE		0x19
#define RTDG_CODE		0x3D
#define ROFF_CODE		0x7A
#define RUTG_CODE		0x7C
#define RDTG_CODE		0x7D

/****** LocalGS Codes *********/
#define POP_CODE	0x21
#define SRP0_CODE	0x10
#define SRP1_CODE	0x11
#define SRP2_CODE	0x12
#define LLOOP_CODE	0x17
#define LMD_CODE	0x1A

/****** Element Codes *********/
#define SCE0_CODE	0x13
#define SCE1_CODE	0x14
#define SCE2_CODE	0x15
#define SCES_CODE	0x16

/****** Control Codes *********/
#define IF_CODE		0x58
#define ELSE_CODE	0x1B
#define EIF_CODE	0x59
#define ENDF_CODE	0x2d
#define MD_CODE		0x49

/* flags for UTP, IUP, MovePoint */
#define XMOVED 0x01
#define YMOVED 0x02

#ifdef SEGMENT_LINK
/* #pragma segment FNT_C */
#endif


/* Private function prototypes */

void fnt_Panic PROTO((fnt_LocalGraphicStateType *gs, int error));
void fnt_IllegalInstruction PROTO((fnt_LocalGraphicStateType *gs));
void fnt_Normalize PROTO((F26Dot6 x, F26Dot6 y, VECTOR *v));
void fnt_MovePoint PROTO((fnt_LocalGraphicStateType *gs,
				   fnt_ElementType *element,
				   ArrayIndex point,
				   F26Dot6 delta));
void fnt_XMovePoint PROTO((fnt_LocalGraphicStateType *gs,
					fnt_ElementType *element,
					ArrayIndex point,
					F26Dot6 delta) );
void fnt_YMovePoint PROTO((fnt_LocalGraphicStateType *gs,
					fnt_ElementType *element,
					ArrayIndex point,
					F26Dot6 delta) );
F26Dot6 fnt_Project PROTO((fnt_LocalGraphicStateType *gs,
					F26Dot6 x,
					F26Dot6 y));
F26Dot6 fnt_OldProject PROTO((fnt_LocalGraphicStateType *gs,
					   F26Dot6 x,
					   F26Dot6 y));
F26Dot6 fnt_XProject PROTO((fnt_LocalGraphicStateType *gs, F26Dot6 x, F26Dot6 y));
F26Dot6 fnt_YProject PROTO((fnt_LocalGraphicStateType *gs, F26Dot6 x, F26Dot6 y));
Fixed fnt_GetCVTScale PROTO((fnt_LocalGraphicStateType *gs));
F26Dot6 fnt_GetCVTEntryFast PROTO((fnt_LocalGraphicStateType *gs, ArrayIndex n));
F26Dot6 fnt_GetCVTEntrySlow PROTO((fnt_LocalGraphicStateType *gs, ArrayIndex n));
F26Dot6 fnt_GetSingleWidthFast PROTO((fnt_LocalGraphicStateType *gs));
F26Dot6 fnt_GetSingleWidthSlow PROTO((fnt_LocalGraphicStateType *gs));
void fnt_ChangeCvt PROTO((fnt_LocalGraphicStateType *gs,
				   fnt_ElementType *element,
				   ArrayIndex number,
				   F26Dot6 delta));
void fnt_InnerTraceExecute PROTO((fnt_LocalGraphicStateType *gs, uint8 *ptr, uint8 *eptr));
void fnt_InnerExecute PROTO((fnt_LocalGraphicStateType *gs, uint8 *ptr, uint8 *eptr));
void fnt_Check_PF_Proj PROTO((fnt_LocalGraphicStateType *gs));
void fnt_ComputeAndCheck_PF_Proj PROTO((fnt_LocalGraphicStateType *gs));
Fract fnt_QuickDist PROTO((Fract dx, Fract dy));
void fnt_SetRoundValues PROTO((fnt_LocalGraphicStateType *gs, int arg1, int normalRound));
F26Dot6 fnt_CheckSingleWidth PROTO((F26Dot6 value, fnt_LocalGraphicStateType *gs));
fnt_instrDef* fnt_FindIDef PROTO((fnt_LocalGraphicStateType* gs, uint8 opCode));
void fnt_DeltaEngine PROTO((fnt_LocalGraphicStateType *gs,
					 FntMoveFunc doIt,
					 int16 base,
					 int16 shift));
void fnt_DefaultJumpTable PROTO(( voidFunc* function ));

/* Actual instructions for the jump table */
void fnt_SVTCA_0 PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SVTCA_1 PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SPVTCA PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SFVTCA PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SPVTL PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SDPVTL PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SFVTL PROTO(	(fnt_LocalGraphicStateType *gs));
void fnt_WPV PROTO((fnt_LocalGraphicStateType *gs));
void fnt_WFV PROTO((fnt_LocalGraphicStateType *gs));
void fnt_RPV PROTO((fnt_LocalGraphicStateType *gs));
void fnt_RFV PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SFVTPV PROTO((fnt_LocalGraphicStateType *gs));
void fnt_ISECT PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SetLocalGraphicState PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SetElementPtr PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SetRoundState PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SROUND PROTO((fnt_LocalGraphicStateType *gs));
void fnt_S45ROUND PROTO((fnt_LocalGraphicStateType *gs));
void fnt_LMD PROTO((fnt_LocalGraphicStateType *gs));
void fnt_RAW PROTO((fnt_LocalGraphicStateType *gs));
void fnt_WLSB PROTO((fnt_LocalGraphicStateType *gs));
void fnt_LWTCI PROTO((fnt_LocalGraphicStateType *gs));
void fnt_LSWCI PROTO((fnt_LocalGraphicStateType *gs));
void fnt_LSW PROTO((fnt_LocalGraphicStateType *gs));
void fnt_DUP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_POP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_CLEAR PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SWAP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_DEPTH PROTO((fnt_LocalGraphicStateType *gs));
void fnt_CINDEX PROTO((fnt_LocalGraphicStateType *gs));
void fnt_MINDEX PROTO((fnt_LocalGraphicStateType *gs));
void fnt_ROTATE PROTO(( fnt_LocalGraphicStateType* gs ));
void fnt_MDAP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_MIAP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_IUP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SHP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SHC PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SHE PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SHPIX PROTO((fnt_LocalGraphicStateType *gs));
void fnt_IP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_MSIRP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_ALIGNRP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_ALIGNPTS PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SANGW PROTO((fnt_LocalGraphicStateType *gs));
void fnt_FLIPPT PROTO((fnt_LocalGraphicStateType *gs));
void fnt_FLIPRGON PROTO((fnt_LocalGraphicStateType *gs));
void fnt_FLIPRGOFF PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SCANCTRL PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SCANTYPE PROTO((fnt_LocalGraphicStateType *gs));
void fnt_INSTCTRL PROTO((fnt_LocalGraphicStateType *gs));
void fnt_AA PROTO((fnt_LocalGraphicStateType *gs));
void fnt_NPUSHB PROTO((fnt_LocalGraphicStateType *gs));
void fnt_NPUSHW PROTO((fnt_LocalGraphicStateType *gs));
void fnt_WS PROTO((fnt_LocalGraphicStateType *gs));
void fnt_RS PROTO((fnt_LocalGraphicStateType *gs));
void fnt_WCVT PROTO((fnt_LocalGraphicStateType *gs));
void fnt_WCVTFOD PROTO((fnt_LocalGraphicStateType *gs));
void fnt_RCVT PROTO((fnt_LocalGraphicStateType *gs));
void fnt_RC PROTO((fnt_LocalGraphicStateType *gs));
void fnt_WC PROTO((fnt_LocalGraphicStateType *gs));
void fnt_MD PROTO((fnt_LocalGraphicStateType *gs));
void fnt_MPPEM PROTO((fnt_LocalGraphicStateType *gs));
void fnt_MPS PROTO((fnt_LocalGraphicStateType *gs));
void fnt_GETINFO PROTO((fnt_LocalGraphicStateType* gs));
void fnt_FLIPON PROTO((fnt_LocalGraphicStateType *gs));
void fnt_FLIPOFF PROTO((fnt_LocalGraphicStateType *gs));
#ifndef NOT_ON_THE_MAC
#ifdef DEBUG
void fnt_DDT PROTO((int8 c, int32 n));
#endif
#endif
void fnt_DEBUG PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SkipPushCrap PROTO((fnt_LocalGraphicStateType *gs));
void fnt_IF PROTO((fnt_LocalGraphicStateType *gs));
void fnt_ELSE PROTO(( fnt_LocalGraphicStateType* gs ));
void fnt_EIF PROTO((fnt_LocalGraphicStateType *gs));
void fnt_JMPR PROTO(( fnt_LocalGraphicStateType* gs ));
void fnt_JROT PROTO((fnt_LocalGraphicStateType *gs));
void fnt_JROF PROTO((fnt_LocalGraphicStateType *gs));
void fnt_BinaryOperand PROTO((fnt_LocalGraphicStateType *gs));
void fnt_UnaryOperand PROTO((fnt_LocalGraphicStateType *gs));
void fnt_ROUND PROTO((fnt_LocalGraphicStateType *gs));
void fnt_NROUND PROTO((fnt_LocalGraphicStateType *gs));
void fnt_PUSHB PROTO((fnt_LocalGraphicStateType *gs));
void fnt_PUSHW PROTO((fnt_LocalGraphicStateType *gs));
void fnt_MDRP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_MIRP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_CALL PROTO((fnt_LocalGraphicStateType *gs));
void fnt_FDEF PROTO((fnt_LocalGraphicStateType *gs));
void fnt_LOOPCALL PROTO((fnt_LocalGraphicStateType *gs));
void fnt_IDefPatch PROTO(( fnt_LocalGraphicStateType* gs ));
void fnt_IDEF PROTO(( fnt_LocalGraphicStateType* gs ));
void fnt_UTP PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SDB PROTO((fnt_LocalGraphicStateType *gs));
void fnt_SDS PROTO((fnt_LocalGraphicStateType *gs));
void fnt_DELTAP1 PROTO((fnt_LocalGraphicStateType *gs));
void fnt_DELTAP2 PROTO((fnt_LocalGraphicStateType *gs));
void fnt_DELTAP3 PROTO((fnt_LocalGraphicStateType *gs));
void fnt_DELTAC1 PROTO((fnt_LocalGraphicStateType *gs));
void fnt_DELTAC2 PROTO((fnt_LocalGraphicStateType *gs));
void fnt_DELTAC3 PROTO((fnt_LocalGraphicStateType *gs));

static F26Dot6 (*dfp_fnt_RoundToGrid)() = &fnt_RoundToGrid;
static F26Dot6 (*dfp_fnt_RoundToHalfGrid)() = &fnt_RoundToHalfGrid;
static F26Dot6 (*dfp_fnt_RoundToDoubleGrid)() = &fnt_RoundToDoubleGrid;
static F26Dot6 (*dfp_fnt_RoundDownToGrid)() = &fnt_RoundDownToGrid;
static F26Dot6 (*dfp_fnt_RoundUpToGrid)() = &fnt_RoundUpToGrid;
static F26Dot6 (*dfp_fnt_RoundOff)() = &fnt_RoundOff;
static F26Dot6 (*dfp_fnt_SuperRound)() = &fnt_SuperRound;
static F26Dot6 (*dfp_fnt_Super45Round)() = &fnt_Super45Round;
static F26Dot6 (*dfp_fnt_GetCVTEntryFast)() = &fnt_GetCVTEntryFast;
static F26Dot6 (*dfp_fnt_GetSingleWidthFast)() = &fnt_GetSingleWidthFast;
static F26Dot6 (*dfp_fnt_GetCVTEntrySlow)() = &fnt_GetCVTEntrySlow;
static F26Dot6 (*dfp_fnt_GetSingleWidthSlow)() = &fnt_GetSingleWidthSlow;
static F26Dot6 (*dfp_fnt_YProject)() = &fnt_YProject;
static F26Dot6 (*dfp_fnt_XProject)() = &fnt_XProject;
static F26Dot6 (*dfp_fnt_Project)() = &fnt_Project;
static F26Dot6 (*dfp_fnt_OldProject)() = &fnt_OldProject;
static FntMoveFunc dfp_fnt_XMovePoint = &fnt_XMovePoint;
static FntMoveFunc dfp_fnt_YMovePoint = &fnt_YMovePoint;
static FntMoveFunc dfp_fnt_MovePoint = &fnt_MovePoint;
static FntFunc dfp_fnt_InnerTraceExecute = &fnt_InnerTraceExecute;
static FntFunc dfp_fnt_InnerExecute = &fnt_InnerExecute;
static voidFunc dfp_fnt_SVTCA_0 = &fnt_SVTCA_0;
static voidFunc dfp_fnt_SVTCA_1 = &fnt_SVTCA_1;
static voidFunc dfp_fnt_SPVTCA = &fnt_SPVTCA;
static voidFunc dfp_fnt_SPVTL = &fnt_SPVTL;
static voidFunc dfp_fnt_WPV = &fnt_WPV;
static voidFunc dfp_fnt_RPV = &fnt_RPV;
static voidFunc dfp_fnt_RFV = &fnt_RFV;
static voidFunc dfp_fnt_SFVTPV = &fnt_SFVTPV;
static voidFunc dfp_fnt_ISECT = &fnt_ISECT;
static voidFunc dfp_fnt_SetLocalGraphicState = &fnt_SetLocalGraphicState;
static voidFunc dfp_fnt_SetElementPtr = &fnt_SetElementPtr;
static voidFunc dfp_fnt_SetRoundState = &fnt_SetRoundState;
static voidFunc dfp_fnt_LMD = &fnt_LMD;
static voidFunc dfp_fnt_ELSE = &fnt_ELSE;
static voidFunc dfp_fnt_JMPR = &fnt_JMPR;
static voidFunc dfp_fnt_LWTCI = &fnt_LWTCI;
static voidFunc dfp_fnt_LSWCI = &fnt_LSWCI;
static voidFunc dfp_fnt_LSW = &fnt_LSW;
static voidFunc dfp_fnt_DUP = &fnt_DUP;
static voidFunc dfp_fnt_CLEAR = &fnt_CLEAR;
static voidFunc dfp_fnt_SWAP = &fnt_SWAP;
static voidFunc dfp_fnt_DEPTH = &fnt_DEPTH;
static voidFunc dfp_fnt_CINDEX = &fnt_CINDEX;
static voidFunc dfp_fnt_MINDEX = &fnt_MINDEX;
static voidFunc dfp_fnt_ALIGNPTS = &fnt_ALIGNPTS;
static voidFunc dfp_fnt_RAW = &fnt_RAW;
static voidFunc dfp_fnt_UTP = &fnt_UTP;
static voidFunc dfp_fnt_LOOPCALL = &fnt_LOOPCALL;
static voidFunc dfp_fnt_CALL = &fnt_CALL;
static voidFunc dfp_fnt_FDEF = &fnt_FDEF;
static voidFunc dfp_fnt_IllegalInstruction = &fnt_IllegalInstruction;
static voidFunc dfp_fnt_MDAP = &fnt_MDAP;
static voidFunc dfp_fnt_IUP = &fnt_IUP;
static voidFunc dfp_fnt_SHP = &fnt_SHP;
static voidFunc dfp_fnt_SHC = &fnt_SHC;
static voidFunc dfp_fnt_SHE = &fnt_SHE;
static voidFunc dfp_fnt_SHPIX = &fnt_SHPIX;
static voidFunc dfp_fnt_IP = &fnt_IP;
static voidFunc dfp_fnt_MSIRP = &fnt_MSIRP;
static voidFunc dfp_fnt_ALIGNRP = &fnt_ALIGNRP;
static voidFunc dfp_fnt_MIAP = &fnt_MIAP;
static voidFunc dfp_fnt_NPUSHB = &fnt_NPUSHB;
static voidFunc dfp_fnt_NPUSHW = &fnt_NPUSHW;
static voidFunc dfp_fnt_WS = &fnt_WS;
static voidFunc dfp_fnt_RS = &fnt_RS;
static voidFunc dfp_fnt_WCVT = &fnt_WCVT;
static voidFunc dfp_fnt_RCVT = &fnt_RCVT;
static voidFunc dfp_fnt_RC = &fnt_RC;
static voidFunc dfp_fnt_WC = &fnt_WC;
static voidFunc dfp_fnt_MD = &fnt_MD;
static voidFunc dfp_fnt_MPPEM = &fnt_MPPEM;
static voidFunc dfp_fnt_MPS = &fnt_MPS;
static voidFunc dfp_fnt_FLIPON = &fnt_FLIPON;
static voidFunc dfp_fnt_FLIPOFF = &fnt_FLIPOFF;
static voidFunc dfp_fnt_DEBUG = &fnt_DEBUG;
static voidFunc dfp_fnt_BinaryOperand = &fnt_BinaryOperand;
static voidFunc dfp_fnt_UnaryOperand = &fnt_UnaryOperand;
static voidFunc dfp_fnt_IF = &fnt_IF;
static voidFunc dfp_fnt_EIF = &fnt_EIF;
static voidFunc dfp_fnt_DELTAP1 = &fnt_DELTAP1;
static voidFunc dfp_fnt_SDB = &fnt_SDB;
static voidFunc dfp_fnt_SDS = &fnt_SDS;
static voidFunc dfp_fnt_ROUND = &fnt_ROUND;
static voidFunc dfp_fnt_NROUND = &fnt_NROUND;
static voidFunc dfp_fnt_WCVTFOD = &fnt_WCVTFOD;
static voidFunc dfp_fnt_DELTAP2 = &fnt_DELTAP2;
static voidFunc dfp_fnt_DELTAP3 = &fnt_DELTAP3;
static voidFunc dfp_fnt_DELTAC1 = &fnt_DELTAC1;
static voidFunc dfp_fnt_DELTAC2 = &fnt_DELTAC2;
static voidFunc dfp_fnt_DELTAC3 = &fnt_DELTAC3;
static voidFunc dfp_fnt_SROUND = &fnt_SROUND;
static voidFunc dfp_fnt_S45ROUND = &fnt_S45ROUND;
static voidFunc dfp_fnt_JROT = &fnt_JROT;
static voidFunc dfp_fnt_JROF = &fnt_JROF;
static voidFunc dfp_fnt_SANGW = &fnt_SANGW;
static voidFunc dfp_fnt_AA = &fnt_AA;
static voidFunc dfp_fnt_FLIPPT = &fnt_FLIPPT;
static voidFunc dfp_fnt_FLIPRGON = &fnt_FLIPRGON;
static voidFunc dfp_fnt_FLIPRGOFF = &fnt_FLIPRGOFF;
static voidFunc dfp_fnt_IDefPatch = &fnt_IDefPatch;
static voidFunc dfp_fnt_SCANCTRL = &fnt_SCANCTRL;
static voidFunc dfp_fnt_SDPVTL = &fnt_SDPVTL;
static voidFunc dfp_fnt_GETINFO = &fnt_GETINFO;
static voidFunc dfp_fnt_IDEF = &fnt_IDEF;
static voidFunc dfp_fnt_ROTATE = &fnt_ROTATE;
static voidFunc dfp_fnt_SCANTYPE = &fnt_SCANTYPE;
static voidFunc dfp_fnt_INSTCTRL = &fnt_INSTCTRL;
static voidFunc dfp_fnt_PUSHB = &fnt_PUSHB;
static voidFunc dfp_fnt_PUSHW = &fnt_PUSHW;
static voidFunc dfp_fnt_MDRP = &fnt_MDRP;
static voidFunc dfp_fnt_MIRP = &fnt_MIRP;
#define PCFM ProcCallFixedOrMovable_pascal


/*
 * We exit through here, when we detect serious errors.
 */
void fnt_Panic (gs, error)
  fnt_LocalGraphicStateType* gs;
  int error;
{
	longjmp( gs->env, error ); /* Do a gracefull recovery  */
}


/***************************/

#define fnt_NextPt1( pt, elem, ctr )\
( (pt) == elem->ep[(ctr)] ? elem->sp[(ctr)] : (pt)+1 )

/*
 * Illegal instruction panic
 */
static void fnt_IllegalInstruction (gs)
  register fnt_LocalGraphicStateType *gs;
{
	fnt_Panic( gs, UNDEFINED_INSTRUCTION_ERR );
}


static int bitcount (a)
  uint32 a;
{
	int count = 0;
	while (a) {
		a >>= 1;
		count++;
	}
	return count;
}


static void fnt_Normalize (x, y, v)
  F26Dot6 x, y;
  VECTOR* v;
{
	/*
	 *	Since x and y are 26.6, and currently that means they are really 16.6,
	 *	when treated as Fract, they are 0.[8]22, so shift up to 0.30 for accuracy
	 */

	CHECK_RANGE(x, -32768L << 6, 32767L << 6);
	CHECK_RANGE(y, -32768L << 6, 32767L << 6);

	{
		Fract xx = x;
		Fract yy = y;
		int shift;
		if (xx < 0)	xx = -xx;
		if (yy < 0) yy = -yy;
		if (xx < yy) xx = yy;
		/*
		 *	0.5 <= max(x,y) < 1
		 */
		shift = 8 * sizeof(Fract) - 2 - bitcount(xx);
		x <<= shift;
		y <<= shift;
	}
	{
		Fract length = FracSqrt( FracMul( x, x ) + FracMul( y, y ) );
		v->x = FIXROUND( FracDiv( x, length ) );
		v->y = FIXROUND( FracDiv( y, length ) );
	}
}


/******************** BEGIN Rounding Routines ***************************/

/*
 * Internal rounding routine
 */
F26Dot6 fnt_RoundToDoubleGrid (xin, engine, gs)
  register F26Dot6 xin;
  F26Dot6 engine;
  fnt_LocalGraphicStateType* gs;
{
/* #pragma unused(gs) */
	register F26Dot6 x = xin;

    if ( x >= 0 ) {
	    x += engine;
		x += fnt_pixelSize/4;
		x &= ~(fnt_pixelSize/2-1);
	} else {
	    x = -x;
	    x += engine;
		x += fnt_pixelSize/4;
		x &= ~(fnt_pixelSize/2-1);
		x = -x;
	}
	if ( ((int32)(xin ^ x)) < 0 && xin ) {
		x = 0; /* The sign flipped, make zero */
	}
	return x;
}


/*
 * Internal rounding routine
 */
F26Dot6 fnt_RoundDownToGrid (xin, engine, gs)
  register F26Dot6 xin;
  F26Dot6 engine;
  fnt_LocalGraphicStateType* gs;
{
/* #pragma unused(gs) */
	register F26Dot6 x = xin;

    if ( x >= 0 ) {
	    x += engine;
		x &= ~(fnt_pixelSize-1);
	} else {
	    x = -x;
	    x += engine;
		x &= ~(fnt_pixelSize-1);
		x = -x;
	}
	if ( ((int32)(xin ^ x)) < 0 && xin ) {
		x = 0; /* The sign flipped, make zero */
	}
	return x;
}


/*
 * Internal rounding routine
 */
F26Dot6 fnt_RoundUpToGrid (xin, engine, gs)
  register F26Dot6 xin;
  F26Dot6 engine;
  fnt_LocalGraphicStateType* gs;
{
/* #pragma unused(gs) */
	register F26Dot6 x = xin;

    if ( x >= 0 ) {
	    x += engine;
		x += fnt_pixelSize - 1;
		x &= ~(fnt_pixelSize-1);
	} else {
	    x = -x;
	    x += engine;
		x += fnt_pixelSize - 1;
		x &= ~(fnt_pixelSize-1);
		x = -x;
	}
	if ( ((int32)(xin ^ x)) < 0 && xin ) {
		x = 0; /* The sign flipped, make zero */
	}
	return x;
}


/*
 * Internal rounding routine
 */
F26Dot6 fnt_RoundToGrid (xin, engine, gs)
  register F26Dot6 xin;
  F26Dot6 engine;
  fnt_LocalGraphicStateType* gs;
{
/* #pragma unused(gs) */
	register F26Dot6 x = xin;

    if ( x >= 0 ) {
	    x += engine;
		x += fnt_pixelSize/2;
		x &= ~(fnt_pixelSize-1);
	} else {
	    x = -x;
	    x += engine;
		x += fnt_pixelSize/2;
		x &= ~(fnt_pixelSize-1);
		x = -x;
	}
	if ( ((int32)(xin ^ x)) < 0 && xin ) {
		x = 0; /* The sign flipped, make zero */
	}
	return x;
}



/*
 * Internal rounding routine
 */
F26Dot6 fnt_RoundToHalfGrid (xin, engine, gs)
  register F26Dot6 xin;
  F26Dot6 engine;
  fnt_LocalGraphicStateType* gs;
{
/* #pragma unused(gs) */
	register F26Dot6 x = xin;

    if ( x >= 0 ) {
	    x += engine;
		x &= ~(fnt_pixelSize-1);
	    x += fnt_pixelSize/2;
	} else {
	    x = -x;
	    x += engine;
		x &= ~(fnt_pixelSize-1);
	    x += fnt_pixelSize/2;
		x = -x;
	}
	if ( ((int32)(xin ^ x)) < 0 && xin ) {
		x = xin > 0 ? fnt_pixelSize/2 : -fnt_pixelSize/2; /* The sign flipped, make equal to smallest valid value */
	}
	return x;
}


/*
 * Internal rounding routine
 */
F26Dot6 fnt_RoundOff (xin, engine, gs)
  register F26Dot6 xin;
  F26Dot6 engine;
  fnt_LocalGraphicStateType* gs;
{
/* #pragma unused(gs) */
	register F26Dot6 x = xin;

    if ( x >= 0 ) {
	    x += engine;
	} else {
	    x -= engine;
	}
	if ( ((int32)(xin ^ x)) < 0 && xin) {
		x = 0; /* The sign flipped, make zero */
	}
	return x;
}


/*
 * Internal rounding routine
 */
F26Dot6 fnt_SuperRound (xin, engine, gs)
  register F26Dot6 xin;
  F26Dot6 engine;
  register fnt_LocalGraphicStateType *gs;
{
	register F26Dot6 x = xin;
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;

    if ( x >= 0 ) {
	    x += engine;
		x += pb->threshold - pb->phase;
		x &= pb->periodMask;
		x += pb->phase;
	} else {
	    x = -x;
	    x += engine;
		x += pb->threshold - pb->phase;
		x &= pb->periodMask;
		x += pb->phase;
		x = -x;
	}
	if ( ((int32)(xin ^ x)) < 0 && xin ) {
		x = xin > 0 ? pb->phase : -pb->phase; /* The sign flipped, make equal to smallest phase */
	}
	return x;
}


/*
 * Internal rounding routine
 */
F26Dot6 fnt_Super45Round (xin, engine, gs)
  register F26Dot6 xin;
  F26Dot6 engine;
  register fnt_LocalGraphicStateType *gs;
{
	register F26Dot6 x = xin;
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;

    if ( x >= 0 ) {
	    x += engine;
		x += pb->threshold - pb->phase;
		x = FracDiv( x, pb->period45 );
		x  &= ~(fnt_pixelSize-1);
		x = FracMul( x, pb->period45 );
		x += pb->phase;
	} else {
	    x = -x;
	    x += engine;
		x += pb->threshold - pb->phase;
		x = FracDiv( x, pb->period45 );
		x  &= ~(fnt_pixelSize-1);
		x = FracMul( x, pb->period45 );
		x += pb->phase;
		x = -x;
	}
	if ( ((int32)(xin ^ x)) < 0 && xin ) {
		x = xin > 0 ? pb->phase : -pb->phase; /* The sign flipped, make equal to smallest phase */
	}
	return x;
}


/******************** END Rounding Routines ***************************/


/* 3-versions ************************************************************************/

/*
 * Moves the point in element by delta (measured against the projection vector)
 * along the freedom vector.
 */
static void fnt_MovePoint (gs, element, point, delta)
  register fnt_LocalGraphicStateType *gs;
  register fnt_ElementType *element;
  register ArrayIndex point;
  register F26Dot6 delta;
{
    register VECTORTYPE pfProj = gs->pfProj;
	register VECTORTYPE fx = gs->free.x;
	register VECTORTYPE fy = gs->free.y;

	CHECK_POINT( gs, element, point );

	if ( pfProj != ONEVECTOR )
	{
		if ( fx ) {
			element->x[point] += VECTORMULDIV( delta, fx, pfProj );
			element->f[point] |= XMOVED;
		}
		if ( fy ) {
			element->y[point] += VECTORMULDIV( delta, fy, pfProj );
			element->f[point] |= YMOVED;
		}
	}
	else
	{
		if ( fx ) {
			element->x[point] += VECTORMUL( delta, fx );
			element->f[point] |= XMOVED;
		}
		if ( fy ) {
			element->y[point] += VECTORMUL( delta, fy );
			element->f[point] |= YMOVED;
		}
	}
}


/*
 * For use when the projection and freedom vectors coincide along the x-axis.
 */
static void fnt_XMovePoint (gs, element, point, delta)
  fnt_LocalGraphicStateType* gs;
  fnt_ElementType* element;
  ArrayIndex point;
  register F26Dot6 delta;
{
#ifndef DEBUG
/* #pragma unused(gs) */
#endif
	CHECK_POINT( gs, element, point );
	element->x[point] += delta;
	element->f[point] |= XMOVED;
}

/*
 * For use when the projection and freedom vectors coincide along the y-axis.
 */
static void fnt_YMovePoint (gs, element, point, delta)
  fnt_LocalGraphicStateType* gs;
  register fnt_ElementType *element;
  ArrayIndex point;
  F26Dot6 delta;
{
#ifndef DEBUG
/* #pragma unused(gs) */
#endif
	CHECK_POINT( gs, element, point );
	element->y[point] += delta;
	element->f[point] |= YMOVED;
}


/*
 * projects x and y into the projection vector.
 */
static F26Dot6 fnt_Project (gs, x, y)
fnt_LocalGraphicStateType* gs;
F26Dot6 x, y;
{
    return( VECTORMUL( x, gs->proj.x ) + VECTORMUL( y, gs->proj.y ) );
}

/*
 * projects x and y into the old projection vector.
 */
static F26Dot6 fnt_OldProject (gs, x, y)
  fnt_LocalGraphicStateType* gs;
  F26Dot6 x, y;
{
    return( VECTORMUL( x, gs->oldProj.x ) + VECTORMUL( y, gs->oldProj.y ) );
}

/*
 * Projects when the projection vector is along the x-axis
 */
static F26Dot6 fnt_XProject (gs, x, y)
  fnt_LocalGraphicStateType* gs;
  F26Dot6 x, y;
{
/* #pragma unused(gs,y) */
    return( x );
}

/*
 * Projects when the projection vector is along the y-axis
 */
static F26Dot6 fnt_YProject (gs, x, y)
  fnt_LocalGraphicStateType* gs;
  F26Dot6 x, y;
{
/* #pragma unused(gs,x) */
    return( y );
}


/*************************************************************************/
/*** Compensation for Transformations ***/

/*
 * Internal support routine, keep this guy FAST!!!!!!!		<3>
 */
static Fixed fnt_GetCVTScale (gs)
  register fnt_LocalGraphicStateType* gs;
{
	register VECTORTYPE pvx, pvy;
	register Fixed scale;
	register fnt_GlobalGraphicStateType *globalGS = gs->globalGS;
	/* Do as few Math routines as possible to gain speed */

	pvx = gs->proj.x;
	pvy = gs->proj.y;
	if ( pvy ) {
		if ( pvx )
		{
			pvy = VECTORDOT( pvy, pvy );
			scale = VECTORMUL( globalGS->yStretch, pvy );
			pvx = VECTORDOT( pvx, pvx );
			return scale + VECTORMUL( globalGS->xStretch, pvx );
		}
		else	/* pvy == +1 or -1 */
			return globalGS->yStretch;
	}
	else	/* pvx == +1 or -1 */
		return globalGS->xStretch;
}


/*	Functions for function pointer in local graphic state
*/
static F26Dot6 fnt_GetCVTEntryFast (gs, n)
  fnt_LocalGraphicStateType* gs;
  ArrayIndex n;
{
	CHECK_CVT( gs, n );
 	return gs->globalGS->controlValueTable[ n ];
}

static F26Dot6 fnt_GetCVTEntrySlow (gs, n)
  register fnt_LocalGraphicStateType *gs;
  ArrayIndex n;
{
	register Fixed scale;

	CHECK_CVT( gs, n );
	scale = fnt_GetCVTScale( gs );
	return ( FixMul( gs->globalGS->controlValueTable[ n ], scale ) );
}


static F26Dot6 fnt_GetSingleWidthFast (gs)
  register fnt_LocalGraphicStateType *gs;
{
 	return gs->globalGS->localParBlock.scaledSW;
}


/*
 *
 */
static F26Dot6 fnt_GetSingleWidthSlow (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register Fixed scale;

	scale = fnt_GetCVTScale( gs );
	return ( FixMul( gs->globalGS->localParBlock.scaledSW, scale ) );
}



/*************************************************************************/


static void fnt_ChangeCvt (gs, elem, number, delta)
  fnt_LocalGraphicStateType* gs;
  fnt_ElementType* elem;
  ArrayIndex number;
  F26Dot6 delta;
{
/* #pragma unused(elem) */
	CHECK_CVT( gs, number );
	gs->globalGS->controlValueTable[ number ] += delta;
}


/*
 * This is the tracing interpreter.
 */
static void fnt_InnerTraceExecute (gs, ptr, eptr)
  register fnt_LocalGraphicStateType *gs;
  uint8 *ptr;
  register uint8 *eptr;
{
    register FntFunc* function;
	register uint8 *oldInsPtr;
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;

	oldInsPtr = gs->insPtr;
	gs->insPtr = ptr;
	function = gs->globalGS->function;

	if ( !gs->TraceFunc ) return; /* so we exit properly out of CALL() */

	while ( gs->insPtr < eptr ) {
		/* The interpreter does not use gs->roundToGrid, so set it here */
		if ( pb->RoundValue == dfp_fnt_RoundToGrid )
			gs->roundToGrid = 1;
		else if ( pb->RoundValue == dfp_fnt_RoundToHalfGrid )
			gs->roundToGrid = 0;
		else if ( pb->RoundValue == dfp_fnt_RoundToDoubleGrid )
			gs->roundToGrid = 2;
		else if ( pb->RoundValue == dfp_fnt_RoundDownToGrid )
			gs->roundToGrid = 3;
		else if ( pb->RoundValue == dfp_fnt_RoundUpToGrid )
			gs->roundToGrid = 4;
		else if ( pb->RoundValue == dfp_fnt_RoundOff )
			gs->roundToGrid = 5;
		else if ( pb->RoundValue == dfp_fnt_SuperRound )
			gs->roundToGrid = 6;
		else if ( pb->RoundValue == dfp_fnt_Super45Round )
			gs->roundToGrid = 7;
		else
			gs->roundToGrid = -1;

		PCFM(gs, gs->TraceFunc );

		if ( !gs->TraceFunc ) break; /* in case the editor wants to exit */

/* FCALL */
		PCFM(gs, function[ gs->opCode = *gs->insPtr++ ]);
	}
	gs->insPtr = oldInsPtr;
}


#ifdef DEBUG
#define LIMIT		65536L*64L

void CHECK_STATE PROTO(( fnt_LocalGraphicStateType* ));

void CHECK_STATE (gs)
  fnt_LocalGraphicStateType *gs;
{
	fnt_ElementType* elem;
	F26Dot6* x;
	F26Dot6* y;
	int16 count;
	F26Dot6 xmin, xmax, ymin, ymax;

	if (!gs->globalGS->glyphProgram) return;

	elem = &gs->elements[1];
	x = elem->x;
	y = elem->y;
	count = elem->ep[elem->nc - 1];
	xmin = xmax = *x;
	ymin = ymax = *y;

	for (; count >= 0; --count)
	{
		if (*x < xmin)
			xmin = *x;
		else if (*x > xmax)
			xmax = *x;
		if (*y < ymin)
			ymin = *y;
		else if (*y > ymax)
			ymax = *y;
		x++, y++;
	}
	if (xmin < -LIMIT || xmax > LIMIT || ymin < -LIMIT || ymax > LIMIT)
		Debugger();
}
#else
#define CHECK_STATE(gs)
#endif


/*
 * This is the fast non-tracing interpreter.
 */
static void fnt_InnerExecute (gs, ptr, eptr)
  register fnt_LocalGraphicStateType *gs;
  uint8 *ptr;
  uint8 *eptr;
{
    register FntFunc* function;
	uint8 *oldInsPtr;

	oldInsPtr = gs->insPtr;
	gs->insPtr = ptr;
	function = gs->globalGS->function;

	CHECK_STATE( gs );
	while ( gs->insPtr < eptr )
	{
/* FCALL */
		PCFM(gs, function[ gs->opCode = *gs->insPtr++ ]);
		CHECK_STATE( gs );
	}

	gs->insPtr = oldInsPtr;
}


extern void fnt_SVTCA_0();

#ifdef DEBUG
static int32 fnt_NilFunction PROTO((void));

static int32 fnt_NilFunction()
{
#ifdef DEBUG
	Debugger();
#endif
	return 0;
}
#endif

#ifdef DEBUG
static F26Dot6 (*dfp_fnt_NilFunction)() = &fnt_NilFunction;
#endif


/*
 * Executes the font instructions.
 * This is the external interface to the interpreter.
 *
 * Parameter Description
 *
 * elements points to the character elements. Element 0 is always
 * reserved and not used by the actual character.
 *
 * ptr points at the first instruction.
 * eptr points to right after the last instruction
 *
 * globalGS points at the global graphics state
 *
 * TraceFunc is pointer to a callback functioned called with a pointer to the
 *		local graphics state if TraceFunc is not null.
 *
 * Note: The stuff globalGS is pointing at must remain intact
 *       between calls to this function.
 */
int fnt_Execute (elements, ptr, eptr, globalGS, TraceFunc)
  fnt_ElementType *elements;
  uint8 *ptr;
  register uint8 *eptr;
  fnt_GlobalGraphicStateType *globalGS;
  voidFunc TraceFunc;
{
    fnt_LocalGraphicStateType GS;
	register fnt_LocalGraphicStateType *gs; /* the local graphics state pointer */
	register int result;

	gs = &GS;
	gs->globalGS = globalGS;

	gs->elements = elements;
	gs->Pt0 = gs->Pt1 = gs->Pt2 = 0;
	gs->CE0 = gs->CE1 = gs->CE2 = &elements[1];
    gs->free.x = gs->proj.x = gs->oldProj.x = ONEVECTOR;
    gs->free.y = gs->proj.y = gs->oldProj.y = 0;
	gs->pfProj = ONEVECTOR;
	gs->MovePoint = dfp_fnt_XMovePoint;
	gs->Project   = dfp_fnt_XProject;
	gs->OldProject = dfp_fnt_XProject;
	gs->loop = 0;		/* 1 less than count for faster loops. mrr */

	if ( globalGS->pgmIndex == FONTPROGRAM )
	{
#ifdef DEBUG
		gs->GetCVTEntry = dfp_fnt_NilFunction;
		gs->GetSingleWidth = dfp_fnt_NilFunction;
#endif
		goto ASSIGN_POINTERS;
	}

	if ( globalGS->pixelsPerEm <= 1 )
		return NO_ERR;
	if ( globalGS->identityTransformation ) {
		gs->GetCVTEntry = dfp_fnt_GetCVTEntryFast;
		gs->GetSingleWidth = dfp_fnt_GetSingleWidthFast;
	} else {
		gs->GetCVTEntry = dfp_fnt_GetCVTEntrySlow;
		gs->GetSingleWidth = dfp_fnt_GetSingleWidthSlow;
		if ( FixMul( globalGS->fpem, globalGS->xStretch ) <= ONEFIX ||
			 FixMul( globalGS->fpem, globalGS->yStretch ) <= ONEFIX )
			return NO_ERR;
	}

	if ( globalGS->init ) {
#ifndef NO_CHECK_TRASHED_MEMORY
#ifdef CLEANMACHINE
		if ( globalGS->function[ 0x00 ] != dfp_fnt_SVTCA_0 ) {
#else
		/* Clean off high byte for checking .... */
		if ( ((int32)globalGS->function[ 0x00 ] & 0x00ffffff) != ((int32)dfp_fnt_SVTCA_0 & 0x00ffffff) ) {
#endif
			/* Who trashed my memory ???? */
			return( TRASHED_MEM_ERR  );
		}
#endif
	} else if ( globalGS->localParBlock.sW ) {
	    /* We need to scale the single width for this size  */
/* FCALL */
		globalGS->localParBlock.scaledSW = (F26Dot6)PCFM(globalGS, globalGS->localParBlock.sW, globalGS->ScaleFunc);
	}

ASSIGN_POINTERS:

	gs->stackPointer = globalGS->stackBase;
	if ( result = setjmp(gs->env) )		return( result );	/* got an error */
	globalGS->anglePoint = (fnt_FractPoint*)((char*)globalGS->function + MAXBYTE_INSTRUCTIONS * sizeof(voidFunc));
	globalGS->angleDistance = (int16*)(globalGS->anglePoint + MAXANGLES);
	if ( globalGS->anglePoint[1].y != 759250125L ) { /* should be same as set to in fnt_Init() */
		/* Who trashed my memory ???? */
		fnt_Panic( gs, TRASHED_MEM_ERR );
	}

	/* first assign */
    gs->Interpreter = (gs->TraceFunc = TraceFunc) ?
						dfp_fnt_InnerTraceExecute : dfp_fnt_InnerExecute;
	/* then call */
/* FCALL */
	PCFM(gs, ptr, eptr, gs->Interpreter);
	return NO_ERR;
}


/*************************************************************************/


/*** 2 internal gs->pfProj computation support routines ***/

/*
 * Only does the check of gs->pfProj
 */
static void fnt_Check_PF_Proj (gs)
  fnt_LocalGraphicStateType *gs;
{
	register VECTORTYPE pfProj = gs->pfProj;

	if ( pfProj > -ONESIXTEENTHVECTOR && pfProj < ONESIXTEENTHVECTOR) {
		gs->pfProj = pfProj < 0 ? -ONEVECTOR : ONEVECTOR; /* Prevent divide by small number */
	}
}


/*
 * Computes gs->pfProj and then does the check
 */
static void fnt_ComputeAndCheck_PF_Proj (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register VECTORTYPE pfProj;

	pfProj = VECTORDOT( gs->proj.x, gs->free.x ) + VECTORDOT( gs->proj.y, gs->free.y );
	if ( pfProj > -ONESIXTEENTHVECTOR && pfProj < ONESIXTEENTHVECTOR) {
		pfProj = pfProj < 0 ? -ONEVECTOR : ONEVECTOR; /* Prevent divide by small number */
	}
	gs->pfProj = pfProj;
}

#pragma Code()

#pragma Code ("TTFntInstrCode")


/******************************************/
/******** The Actual Instructions *********/
/******************************************/

/*
 * Set Vectors To Coordinate Axis - Y
 */
static void fnt_SVTCA_0 (gs)
  register fnt_LocalGraphicStateType* gs;
{
	gs->free.x = gs->proj.x = 0;
	gs->free.y = gs->proj.y = ONEVECTOR;
	gs->MovePoint = dfp_fnt_YMovePoint;
	gs->Project = dfp_fnt_YProject;
	gs->OldProject = dfp_fnt_YProject;
	gs->pfProj = ONEVECTOR;
}


/*
 * Set Vectors To Coordinate Axis - X
 */
static void fnt_SVTCA_1 (gs)
  register fnt_LocalGraphicStateType* gs;
{
	gs->free.x = gs->proj.x = ONEVECTOR;
	gs->free.y = gs->proj.y = 0;
	gs->MovePoint = dfp_fnt_XMovePoint;
	gs->Project = dfp_fnt_XProject;
	gs->OldProject = dfp_fnt_XProject;
	gs->pfProj = ONEVECTOR;
}


/*
 * Set Projection Vector To Coordinate Axis
 */
static void fnt_SPVTCA (gs)
  register fnt_LocalGraphicStateType* gs;
{
	if ( BIT0( gs->opCode )  ) {
		gs->proj.x = ONEVECTOR;
		gs->proj.y = 0;
		gs->Project = dfp_fnt_XProject;
		gs->pfProj = gs->free.x;
	} else {
		gs->proj.x = 0;
		gs->proj.y = ONEVECTOR;
		gs->Project = dfp_fnt_YProject;
		gs->pfProj = gs->free.y;
	}
	fnt_Check_PF_Proj( gs );
	gs->MovePoint = dfp_fnt_MovePoint;
	gs->OldProject = gs->Project;
}


/*
 * Set Freedom Vector to Coordinate Axis
 */
static void fnt_SFVTCA (gs)
  register fnt_LocalGraphicStateType* gs;
{
	if ( BIT0( gs->opCode )  ) {
		gs->free.x = ONEVECTOR;
		gs->free.y = 0;
		gs->pfProj = gs->proj.x;
	} else {
		gs->free.x = 0;
		gs->free.y = ONEVECTOR;
		gs->pfProj = gs->proj.y;
	}
	fnt_Check_PF_Proj( gs );
	gs->MovePoint = dfp_fnt_MovePoint;
}


/*
 * Set Projection Vector To Line
 */
static void fnt_SPVTL (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex arg1, arg2;

	arg2 = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	arg1 = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );

	CHECK_POINT( gs, gs->CE2, arg2 );
	CHECK_POINT( gs, gs->CE1, arg1 );

	fnt_Normalize( gs->CE1->x[arg1] - gs->CE2->x[arg2], gs->CE1->y[arg1] - gs->CE2->y[arg2], &gs->proj );
	if ( BIT0( gs->opCode ) ) {
		/* rotate 90 degrees */
		VECTORTYPE tmp	= gs->proj.y;
		gs->proj.y		= gs->proj.x;
		gs->proj.x		= -tmp;
	}
	fnt_ComputeAndCheck_PF_Proj( gs );
	gs->MovePoint = dfp_fnt_MovePoint;
	gs->Project = dfp_fnt_Project;
	gs->OldProject = gs->Project;
}



/*
 * Set Dual Projection Vector To Line
 */
static void fnt_SDPVTL (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex arg1, arg2;

	arg2 = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	arg1 = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );

	CHECK_POINT( gs, gs->CE2, arg2 );
	CHECK_POINT( gs, gs->CE1, arg1 );

	/* Do the current domain */
	fnt_Normalize( gs->CE1->x[arg1] - gs->CE2->x[arg2], gs->CE1->y[arg1] - gs->CE2->y[arg2], &gs->proj );

	/* Do the old domain */
	fnt_Normalize( gs->CE1->ox[arg1] - gs->CE2->ox[arg2], gs->CE1->oy[arg1] - gs->CE2->oy[arg2], &gs->oldProj );

	if ( BIT0( gs->opCode ) ) {
		/* rotate 90 degrees */
		VECTORTYPE tmp	= gs->proj.y;
		gs->proj.y		= gs->proj.x;
		gs->proj.x		= -tmp;

		tmp				= gs->oldProj.y;
		gs->oldProj.y	= gs->oldProj.x;
		gs->oldProj.x	= -tmp;
	}
	fnt_ComputeAndCheck_PF_Proj( gs );

	gs->MovePoint = dfp_fnt_MovePoint;
	gs->Project = dfp_fnt_Project;
	gs->OldProject = dfp_fnt_OldProject;
}


/*
 * Set Freedom Vector To Line
 */
static void fnt_SFVTL (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex arg1, arg2;

	arg2 = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	arg1 = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );

	CHECK_POINT( gs, gs->CE2, arg2 );
	CHECK_POINT( gs, gs->CE1, arg1 );

	fnt_Normalize( gs->CE1->x[arg1] - gs->CE2->x[arg2], gs->CE1->y[arg1] - gs->CE2->y[arg2], &gs->free );
	if ( BIT0( gs->opCode ) ) {
		/* rotate 90 degrees */
		VECTORTYPE tmp	= gs->free.y;
		gs->free.y		= gs->free.x;
		gs->free.x		= -tmp;
	}
	fnt_ComputeAndCheck_PF_Proj( gs );
	gs->MovePoint = dfp_fnt_MovePoint;
}


/*
 * Write Projection Vector
 */
static void fnt_WPV (gs)
  register fnt_LocalGraphicStateType *gs;
{
	gs->proj.y = (VECTORTYPE)CHECK_POP(gs, gs->stackPointer);
	gs->proj.x = (VECTORTYPE)CHECK_POP(gs, gs->stackPointer);

	fnt_ComputeAndCheck_PF_Proj( gs );

	gs->MovePoint = dfp_fnt_MovePoint;
	gs->Project = dfp_fnt_Project;
	gs->OldProject = gs->Project;
}


/*
 * Write Freedom vector
 */
static void fnt_WFV (gs)
  register fnt_LocalGraphicStateType *gs;
{
	gs->free.y = (VECTORTYPE)CHECK_POP(gs, gs->stackPointer);
	gs->free.x = (VECTORTYPE)CHECK_POP(gs, gs->stackPointer);

	fnt_ComputeAndCheck_PF_Proj( gs );

	gs->MovePoint = dfp_fnt_MovePoint;
}


/*
 * Read Projection Vector
 */
static void fnt_RPV (gs)
  register fnt_LocalGraphicStateType *gs;
{
	CHECK_PUSH( gs, gs->stackPointer, gs->proj.x );
	CHECK_PUSH( gs, gs->stackPointer, gs->proj.y );
}


/*
 * Read Freedom Vector
 */
static void fnt_RFV (gs)
  register fnt_LocalGraphicStateType *gs;
{
	CHECK_PUSH( gs, gs->stackPointer, gs->free.x );
	CHECK_PUSH( gs, gs->stackPointer, gs->free.y );
}


/*
 * Set Freedom Vector To Projection Vector
 */
static void fnt_SFVTPV (gs)
  register fnt_LocalGraphicStateType *gs;
{
	gs->free = gs->proj;
	gs->pfProj = ONEVECTOR;
	gs->MovePoint = dfp_fnt_MovePoint;
}


/*
 * fnt_ISECT()
 *
 * Computes the intersection of two lines without using floating point!!
 *
 * (1) Bx + dBx * t0 = Ax + dAx * t1
 * (2) By + dBy * t0 = Ay + dAy * t1
 *
 *  1  =>  (t1 = Bx - Ax + dBx * t0 ) / dAx
 *  +2 =>   By + dBy * t0 = Ay + dAy/dAx * [ Bx - Ax + dBx * t0 ]
 *     => t0 * [dAy/dAx * dBx - dBy = By - Ay - dAy/dAx*(Bx-Ax)
 *     => t0(dAy*DBx - dBy*dAx) = dAx(By - Ay) + dAy(Ax-Bx)
 *     => t0 = [dAx(By-Ay) + dAy(Ax-Bx)] / [dAy*dBx - dBy*dAx]
 *     => t0 = [dAx(By-Ay) - dAy(Bx-Ax)] / [dBx*dAy - dBy*dAx]
 *     t0 = N/D
 *     =>
 *	    N = (By - Ay) * dAx - (Bx - Ax) * dAy;
 *		D = dBx * dAy - dBy * dAx;
 *      A simple floating point implementation would only need this, and
 *      the check to see if D is zero.
 *		But to gain speed we do some tricks and avoid floating point.
 *
 */
static void fnt_ISECT (gs)
  fnt_LocalGraphicStateType *gs;
{
	register F26Dot6 N, D;
	register Fract t;
	register ArrayIndex arg1, arg2;
	F26Dot6 Bx, By, Ax, Ay;
	F26Dot6 dBx, dBy, dAx, dAy;

	{
		register fnt_ElementType* element = gs->CE0;
		register F26Dot6* stack = gs->stackPointer;

		arg2 = (ArrayIndex)CHECK_POP(gs, stack ); /* get one line */
		arg1 = (ArrayIndex)CHECK_POP(gs, stack );
		dAx = element->x[arg2] - (Ax = element->x[arg1]);
		dAy = element->y[arg2] - (Ay = element->y[arg1]);

		element = gs->CE1;
		arg2 = (ArrayIndex)CHECK_POP(gs, stack ); /* get the other line */
		arg1 = (ArrayIndex)CHECK_POP(gs, stack );
		dBx = element->x[arg2] - (Bx = element->x[arg1]);
		dBy = element->y[arg2] - (By = element->y[arg1]);

		arg1 = (ArrayIndex)CHECK_POP(gs, stack ); /* get the point number */
		gs->stackPointer = stack;
	}
	gs->CE2->f[arg1] |= XMOVED | YMOVED;
	{
		register F26Dot6* elementx = gs->CE2->x;
		register F26Dot6* elementy = gs->CE2->y;
		if ( dAy == 0 ) {
			if ( dBx == 0 ) {
				elementx[arg1] = Bx;
				elementy[arg1] = Ay;
				return;
			}
			N = By - Ay;
			D = -dBy;
		} else if ( dAx == 0 ) {
			if ( dBy == 0 ) {
				elementx[arg1] = Ax;
				elementy[arg1] = By;
				return;
			}
			N = Bx - Ax;
			D = -dBx;
		} else if ( MABS( dAx ) > MABS( dAy ) ) {
			/* To prevent out of range problems divide both N and D with the max */
			t = FracDiv( dAy, dAx );
			N = (By - Ay) - FracMul( (Bx - Ax), t );
			D = FracMul( dBx, t ) - dBy;
		} else {
			t = FracDiv( dAx, dAy );
			N = FracMul( (By - Ay), t ) - (Bx - Ax);
			D = dBx - FracMul( dBy, t );
		}

		if ( D ) {
			if ( MABS( N ) < MABS( D ) ) {
				/* this is the normal case */
				t = FracDiv( N, D );
				elementx[arg1] = Bx + FracMul( dBx, t );
				elementy[arg1] = By + FracMul( dBy, t );
			} else {
				if ( N ) {
					/* Oh well, invert t and use it instead */
					t = FracDiv( D, N );
					elementx[arg1] = Bx + FracDiv( dBx, t );
					elementy[arg1] = By + FracDiv( dBy, t );
				} else {
					elementx[arg1] = Bx;
					elementy[arg1] = By;
				}
			}
		} else {
			/* degenerate case: parallell lines, put point in the middle */
			elementx[arg1] = (Bx + (dBx>>1) + Ax + (dAx>>1)) >> 1;
			elementy[arg1] = (By + (dBy>>1) + Ay + (dAy>>1)) >> 1;
		}
	}
}


/*
 * Load Minimum Distanc
 */
static void fnt_LMD (gs)
  register fnt_LocalGraphicStateType *gs;
{
	gs->globalGS->localParBlock.minimumDistance = CHECK_POP(gs, gs->stackPointer );
}


/*
 * Load Control Value Table Cut In
 */
static void fnt_LWTCI (gs)
  register fnt_LocalGraphicStateType *gs;
{
	gs->globalGS->localParBlock.wTCI = CHECK_POP(gs, gs->stackPointer );
}


/*
 * Load Single Width Cut In
 */
static void fnt_LSWCI (gs)
  register fnt_LocalGraphicStateType *gs;
{
	gs->globalGS->localParBlock.sWCI = CHECK_POP(gs, gs->stackPointer );
}


/*
 * Load Single Width , assumes value comes from the original domain, not the cvt or outline
 */
static void fnt_LSW (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_GlobalGraphicStateType *globalGS = gs->globalGS;
	register fnt_ParameterBlock *pb = &globalGS->localParBlock;

	pb->sW = (int16)CHECK_POP(gs, gs->stackPointer );

/* FCALL */
	pb->scaledSW = (F26Dot6)PCFM(globalGS, pb->sW, globalGS->ScaleFunc); /* measurement should not come from the outline */
}


static void fnt_SetLocalGraphicState (gs)
  register fnt_LocalGraphicStateType *gs;
{
	int arg = (int)CHECK_POP(gs, gs->stackPointer );

	switch (gs->opCode) {
	case SRP0_CODE:	 gs->Pt0 = (ArrayIndex)arg; break;
	case SRP1_CODE:	 gs->Pt1 = (ArrayIndex)arg; break;
	case SRP2_CODE:	 gs->Pt2 = (ArrayIndex)arg; break;

	case LLOOP_CODE: gs->loop = (LoopCount)arg - 1; break;

	case POP_CODE: break;
#ifdef DEBUG
	default:
		Debugger();
		break;
#endif
	}
}


static void fnt_SetElementPtr (gs)
  register fnt_LocalGraphicStateType *gs;
{
	ArrayIndex arg = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	fnt_ElementType* element = &gs->elements[ arg ];

	CHECK_ELEMENT( gs, arg );

	switch (gs->opCode) {
	case SCES_CODE: gs->CE2 = element;
					gs->CE1 = element;
	case SCE0_CODE: gs->CE0 = element; break;
	case SCE1_CODE: gs->CE1 = element; break;
	case SCE2_CODE: gs->CE2 = element; break;
#ifdef DEBUG
	default:
		Debugger();
		break;
#endif
	}
}


/*
 * Super Round
 */
static void fnt_SROUND (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register int arg1 = (int)CHECK_POP(gs, gs->stackPointer );
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;

	fnt_SetRoundValues( gs, arg1, true );
	pb->RoundValue = dfp_fnt_SuperRound;
}


/*
 * Super Round
 */
static void fnt_S45ROUND (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register int arg1 = (int)CHECK_POP(gs, gs->stackPointer );
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;

	fnt_SetRoundValues( gs, arg1, false );
	pb->RoundValue = dfp_fnt_Super45Round;
}


/*
 *	These functions just set a field of the graphics state
 *	They pop no arguments
 */
static void fnt_SetRoundState (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register FntRoundFunc *rndFunc = &gs->globalGS->localParBlock.RoundValue;

	switch (gs->opCode) {
	case RTG_CODE:  *rndFunc = dfp_fnt_RoundToGrid; break;
	case RTHG_CODE: *rndFunc = dfp_fnt_RoundToHalfGrid; break;
	case RTDG_CODE: *rndFunc = dfp_fnt_RoundToDoubleGrid; break;
	case ROFF_CODE: *rndFunc = dfp_fnt_RoundOff; break;
	case RDTG_CODE: *rndFunc = dfp_fnt_RoundDownToGrid; break;
	case RUTG_CODE: *rndFunc = dfp_fnt_RoundUpToGrid; break;
#ifdef DEBUG
	default:
		Debugger();
		break;
#endif
	}
}


#define FRACSQRT2DIV2 759250125
/*
 * Internal support routine for the super rounding routines
 */
static void fnt_SetRoundValues (gs, arg1, normalRound)
  register fnt_LocalGraphicStateType *gs;
  register int arg1, normalRound;
{
	register int tmp;
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;

	tmp = arg1 & 0xC0;

	if ( normalRound ) {
		switch ( tmp ) {
		case 0x00:
			pb->period = fnt_pixelSize/2;
			break;
		case 0x40:
			pb->period = fnt_pixelSize;
			break;
		case 0x80:
			pb->period = fnt_pixelSize*2;
			break;
		default:
			pb->period = 999; /* Illegal */
		}
		pb->periodMask = ~(pb->period-1);
	} else {
		pb->period45 = FRACSQRT2DIV2;
		switch ( tmp ) {
		case 0x00:
			pb->period45 >>= 1;
			break;
		case 0x40:
			break;
		case 0x80:
			pb->period45 <<= 1;
			break;
		default:
			pb->period45 = 999; /* Illegal */
		}
		tmp = (sizeof(Fract) * 8 - 2 - fnt_pixelShift);
		pb->period = (int16)((pb->period45 + (1L<<(tmp-1))) >> tmp); /*convert from 2.30 to 26.6 */
	}

	tmp = arg1 & 0x30;
	switch ( tmp ) {
	case 0x00:
		pb->phase = 0;
		break;
	case 0x10:
		pb->phase = (pb->period + 2) >> 2;
		break;
	case 0x20:
		pb->phase = (pb->period + 1) >> 1;
		break;
	case 0x30:
		pb->phase = (pb->period + pb->period + pb->period + 2) >> 2;
		break;
	}
	tmp = arg1 & 0x0f;
	if ( tmp == 0 ) {
		pb->threshold = pb->period-1;
	} else {
		pb->threshold = ((tmp - 4) * pb->period + 4) >> 3;
	}
}


/*
 * Read Advance Width
 */
static void fnt_RAW (gs)
  register fnt_LocalGraphicStateType *gs;
{
	fnt_ElementType* elem = &gs->elements[1];
	F26Dot6* ox = elem->ox;
	ArrayIndex index = elem->ep[elem->nc - 1] + 1;		/* lsb point */

	CHECK_PUSH( gs, gs->stackPointer, ox[index+1] - ox[index] );
}


/*
 * DUPlicate
 */
static void fnt_DUP (gs)
  register fnt_LocalGraphicStateType *gs;
{
	F26Dot6 top = gs->stackPointer[-1];
	CHECK_PUSH( gs, gs->stackPointer, top);
}


/*
 * CLEAR stack
 */
static void fnt_CLEAR (gs)
  register fnt_LocalGraphicStateType *gs;
{
	gs->stackPointer = gs->globalGS->stackBase;
}


/*
 * SWAP
 */
static void fnt_SWAP (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register F26Dot6* stack = gs->stackPointer;
	register F26Dot6 arg2 = CHECK_POP(gs, stack );
	register F26Dot6 arg1 = CHECK_POP(gs, stack );

	CHECK_PUSH( gs, stack, arg2 );
	CHECK_PUSH( gs, stack, arg1 );
}


/*
 * DEPTH
 */
static void fnt_DEPTH (gs)
  register fnt_LocalGraphicStateType *gs;
{
	F26Dot6 depth = gs->stackPointer - gs->globalGS->stackBase;
	CHECK_PUSH( gs, gs->stackPointer, depth);
}


/*
 * Copy INDEXed value
 */
static void fnt_CINDEX (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex arg1;
	register F26Dot6 tmp;
	register F26Dot6* stack = gs->stackPointer;

	arg1 = (ArrayIndex)CHECK_POP(gs, stack );
	tmp = *(stack - arg1 );
	CHECK_PUSH( gs, stack , tmp );
}


/*
 * Move INDEXed value
 */
static void fnt_MINDEX (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex arg1;
	register F26Dot6 tmp, *p;
	register F26Dot6* stack = gs->stackPointer;

	arg1 = (ArrayIndex)CHECK_POP(gs, stack );
	tmp = *(p = (stack - arg1));
	if ( arg1 ) {
		do {
			*p = *(p + 1); p++;
		} while ( --arg1 );
		CHECK_POP(gs, stack );
	}
	CHECK_PUSH( gs, stack, tmp );
	gs->stackPointer = stack;
}


/*
 *	Rotate element 3 to the top of the stack			<4>
 *	Thanks to Oliver for the obscure code.
 */
static void fnt_ROTATE (gs)
  register fnt_LocalGraphicStateType* gs;
{
	register F26Dot6 *stack = gs->stackPointer;
	register F26Dot6 element1 = *--stack;
	register F26Dot6 element2 = *--stack;
	*stack = element1;
	element1 = *--stack;
	*stack = element2;
	*(stack + 2) = element1;
}


/*
 * Move Direct Absolute Point
 */
static void fnt_MDAP (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register F26Dot6 proj;
	register fnt_ElementType* ce0 = gs->CE0;
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;
	register ArrayIndex ptNum;

	ptNum = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	gs->Pt0 = gs->Pt1 = ptNum;

	if ( BIT0( gs->opCode ) )
	{
/* FCALL */
		proj = (F26Dot6)PCFM(gs, ce0->x[ptNum], ce0->y[ptNum], gs->Project);
/* FCALL */
		proj = (F26Dot6)PCFM(proj, gs->globalGS->engine[0], gs, pb->RoundValue) - proj;
	}
	else
		proj = 0;		/* mark the point as touched */

/* FCALL */
	PCFM(gs, ce0, ptNum, proj, gs->MovePoint);
}


/*
 * Move Indirect Absolute Point
 */
static void fnt_MIAP (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex ptNum;
	register F26Dot6 newProj, origProj;
	register fnt_ElementType* ce0 = gs->CE0;
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;

	newProj = (F26Dot6)PCFM(gs, CHECK_POP(gs, gs->stackPointer ), gs->GetCVTEntry );
	ptNum = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );

	CHECK_POINT(gs, ce0, ptNum);
	gs->Pt0 = gs->Pt1 = ptNum;

	if ( ce0 == gs->elements )		/* twilightzone */
	{
		ce0->x[ptNum] = ce0->ox[ptNum] = VECTORMUL( newProj, gs->proj.x );
		ce0->y[ptNum] = ce0->oy[ptNum] = VECTORMUL( newProj, gs->proj.y );
	}

	origProj = (F26Dot6)PCFM(gs, ce0->x[ptNum], ce0->y[ptNum], gs->Project );

	if ( BIT0( gs->opCode ) )
	{
		register F26Dot6 tmp = newProj - origProj;
		if ( tmp < 0 )
			tmp = -tmp;
		if ( tmp > pb->wTCI )
			newProj = origProj;
/* FCALL */
		newProj = (F26Dot6)PCFM(newProj, gs->globalGS->engine[0], gs, pb->RoundValue );
	}

	newProj -= origProj;
/* FCALL */
	PCFM(gs, ce0, ptNum, newProj, gs->MovePoint );
}


/*
 * Interpolate Untouched Points
 */
static void fnt_IUP (gs)
  fnt_LocalGraphicStateType *gs;
{
	register fnt_ElementType* CE2 = gs->CE2;
	register int32 tmp32B;
	F26Dot6 *coord, *oCoord, *ooCoord;
    LoopCount ctr;
	F26Dot6 dx, dx1, dx2;
	F26Dot6 dlow, dhigh;
	F26Dot6 tmp32, high, low;
	int mask;
	ArrayIndex tmp16B;

	if ( gs->opCode & 0x01 ) {
		/* do x */
		coord = CE2->x;
		oCoord = CE2->ox;
		ooCoord = CE2->oox;
		mask = XMOVED;
	} else {
		/* do y */
		coord = CE2->y;
		oCoord = CE2->oy;
		ooCoord = CE2->ooy;
		mask = YMOVED;
	}
	for ( ctr = 0; ctr < CE2->nc; ctr++ )
	{
		ArrayIndex start = CE2->sp[ctr];
		int16 tmp16 = CE2->ep[ctr];
		while( !(CE2->f[start] & mask) && start <= tmp16 )
			start++;
		if ( start > tmp16 )
			continue;
		tmp16B = start;
		do {
			ArrayIndex end;
			tmp16 = end = fnt_NextPt1( start, CE2, ctr );
			while( !(CE2->f[end] & mask) ) {
				end = fnt_NextPt1( end, CE2, ctr );
				if ( start == end )
					break;
			}

			if ( ooCoord[start] < ooCoord[end] ) {
				dx  = coord[start];
				dx1 = oCoord[start];
				dx2 = ooCoord[start];
				high = oCoord[end];
				dhigh = coord[end] - high;
				tmp32  = coord[end] - dx;
				tmp32B = ooCoord[end] - dx2;
			} else {
				dx  = coord[end];
				dx1 = oCoord[end];
				dx2 = ooCoord[end];
				high = oCoord[start];
				dhigh = coord[start] - high;
				tmp32  = coord[start] - dx;
				tmp32B = ooCoord[start] - dx2;
			}
			low = dx1;
			dlow = dx - dx1;

			if ( tmp32B ) {
				if ( tmp32B < 32768 && tmp32 < 32768 )
				{
					F26Dot6 corr = tmp32B >> 1;
					while ( tmp16 != end )
					{
						F26Dot6 tmp32C = oCoord[tmp16];
						if ( tmp32C <= low )
							tmp32C += dlow;
						else if ( tmp32C >= high )
							tmp32C += dhigh;
						else
						{
							tmp32C = ooCoord[tmp16];
							tmp32C -= dx2;
							tmp32C  = SHORTMUL(tmp32C, tmp32);
							tmp32C += corr;
							if ( tmp32C < 32768 )
							    tmp32C = SHORTDIV(tmp32C, tmp32B);
							else
							    tmp32C /= (int16)tmp32B;
							tmp32C += dx;
						}
						coord[tmp16] = tmp32C;
						tmp16 = fnt_NextPt1( tmp16, CE2, ctr);
					}
				}
				else
				{
					Fixed ratio;
				    int firstTime = true;
					while ( tmp16 != end )
					{
						F26Dot6 tmp32C = oCoord[tmp16];
						if ( tmp32C <= low )
							tmp32C += dlow;
						else if ( tmp32C >= high )
							tmp32C += dhigh;
						else
						{
						    if ( firstTime )
							{
						        ratio = FixDiv( tmp32, tmp32B );
								firstTime = 0;
						    }
							tmp32C = ooCoord[tmp16];
							tmp32C -= dx2;
							tmp32C = FixMul( tmp32C, ratio );
							tmp32C += dx;
						}
						coord[tmp16] = tmp32C;
						tmp16 = fnt_NextPt1( tmp16, CE2, ctr);
					}
				}
			} else {
				while ( tmp16 != end ) {
					coord[tmp16] += dx - dx1;
					tmp16 = fnt_NextPt1( tmp16, CE2, ctr);
				}
			}
			start = end;
		} while ( start != tmp16B );
	}

}


static fnt_ElementType* fnt_SH_Common(gs, dx, dy, point)
  fnt_LocalGraphicStateType* gs;
  F26Dot6* dx;
  F26Dot6* dy;
  ArrayIndex* point;
{
	F26Dot6 proj;
	ArrayIndex pt;
	fnt_ElementType* element;

	if ( BIT0( gs->opCode ) ) {
		pt = gs->Pt1;
		element = gs->CE0;
	} else {
		pt = gs->Pt2;
		element = gs->CE1;
	}
/* FCALL */
	proj = (F26Dot6)PCFM(gs, element->x[pt] - element->ox[pt],
                            element->y[pt] - element->oy[pt], gs->Project );

	if ( gs->pfProj != ONEVECTOR )
	{
		if ( gs->free.x )
			*dx = VECTORMULDIV( proj, gs->free.x, gs->pfProj );
		if ( gs->free.y )
			*dy = VECTORMULDIV( proj, gs->free.y, gs->pfProj );
	}
	else
	{
		if ( gs->free.x )
			*dx = VECTORMUL( proj, gs->free.x );
		if ( gs->free.y )
			*dy = VECTORMUL( proj, gs->free.y );
	}
	*point = pt;
	return element;
}


static void fnt_SHP_Common (gs, dx, dy)
  fnt_LocalGraphicStateType *gs;
  F26Dot6 dx, dy;
{
	register fnt_ElementType* CE2 = gs->CE2;
	register LoopCount count = gs->loop;
	for (; count >= 0; --count)
	{
		ArrayIndex point = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
		if ( gs->free.x ) {
			CE2->x[point] += dx;
			CE2->f[point] |= XMOVED;
		}
		if ( gs->free.y ) {
			CE2->y[point] += dy;
			CE2->f[point] |= YMOVED;
		}
	}
	gs->loop = 0;
}


/*
 * SHift Point
 */
static void fnt_SHP (gs)
  register fnt_LocalGraphicStateType *gs;
{
	F26Dot6 dx, dy;
	ArrayIndex point;

	fnt_SH_Common(gs, &dx, &dy, &point);
	fnt_SHP_Common(gs, dx, dy);
}


/*
 * SHift Contour
 */
static void fnt_SHC (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register fnt_ElementType *element;
	register F26Dot6 dx, dy;
	register ArrayIndex contour, point;

	{
		F26Dot6 x, y;
		ArrayIndex pt;
		element = fnt_SH_Common(gs, &x, &y, &pt);
		point = pt;
		dx = x;
		dy = y;
	}
    contour = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );

	CHECK_CONTOUR(gs, gs->CE2, contour);

	{
		VECTORTYPE fvx = gs->free.x;
		VECTORTYPE fvy = gs->free.y;
		register fnt_ElementType* CE2 = gs->CE2;
		ArrayIndex currPt = CE2->sp[contour];
		LoopCount count = CE2->ep[contour] - currPt;
		CHECK_POINT(gs, CE2, currPt + count);
		for (; count >= 0; --count)
		{
			if ( currPt != point || element != CE2 )
			{
				if ( fvx ) {
					CE2->x[currPt] += dx;
					CE2->f[currPt] |= XMOVED;
				}
				if ( fvy ) {
					CE2->y[currPt] += dy;
					CE2->f[currPt] |= YMOVED;
				}
			}
			currPt++;
		}
	}
}


/*
 * SHift Element			<4>
 */
static void fnt_SHE (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register fnt_ElementType *element;
	register F26Dot6 dx, dy;
	ArrayIndex firstPoint, origPoint, lastPoint, arg1;

	{
		F26Dot6 x, y;
		element = fnt_SH_Common(gs, &x, &y, &origPoint);
		dx = x;
		dy = y;
	}

	arg1 = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	CHECK_ELEMENT(gs, arg1);

	lastPoint = gs->elements[arg1].ep[gs->elements[arg1].nc - 1];
	CHECK_POINT(gs, &gs->elements[arg1], lastPoint);
	firstPoint  = gs->elements[arg1].sp[0];
	CHECK_POINT(gs, &gs->elements[arg1], firstPoint);

/*** changed this			<4>
	do {
		if ( origPoint != firstPoint || element != &gs->elements[arg1] ) {
			if ( gs->free.x ) {
				gs->elements[ arg1 ].x[firstPoint] += dx;
				gs->elements[ arg1 ].f[firstPoint] |= XMOVED;
			}
			if ( gs->free.y ) {
				gs->elements[ arg1 ].y[firstPoint] += dy;
				gs->elements[ arg1 ].f[firstPoint] |= YMOVED;
			}
		}
		firstPoint++;
	} while ( firstPoint <= lastPoint );
***** To this ? *********/

	if (element != &gs->elements[arg1])		/* we're in different zones */
		origPoint = -1;						/* no need to skip orig point */
	{
		register int8 mask = 0;
		if ( gs->free.x )
		{
			register F26Dot6 deltaX = dx;
			register F26Dot6* x = &gs->elements[ arg1 ].x[firstPoint];
			register LoopCount count = origPoint - firstPoint - 1;
			for (; count >= 0; --count )
				*x++ += deltaX;
			if (origPoint == -1)
				count = lastPoint - firstPoint;
			else
			{
				count = lastPoint - origPoint - 1;
				x++;							/* skip origPoint */
			}
			for (; count >= 0; --count )
				*x++ += deltaX;
			mask = XMOVED;
		}
		if ( gs->free.y )		/* fix me semore */
		{
			register F26Dot6 deltaY = dy;
			register F26Dot6* y = &gs->elements[ arg1 ].y[firstPoint];
			register uint8* f = &gs->elements[ arg1 ].f[firstPoint];
			register LoopCount count = origPoint - firstPoint - 1;
			for (; count >= 0; --count )
			{
				*y++ += deltaY;
				*f++ |= mask;
			}
			if (origPoint == -1)
				count = lastPoint - firstPoint;
			else
			{
				count = lastPoint - origPoint - 1;
				y++, f++;						/* skip origPoint */
			}
			mask |= YMOVED;
			for (; count >= 0; --count )
			{
				*y++ += deltaY;
				*f++ |= mask;
			}
		}
	}
}


/*
 * SHift point by PIXel amount
 */
static void fnt_SHPIX (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register F26Dot6 proj, dx, dy;

	proj = CHECK_POP(gs, gs->stackPointer );
	if ( gs->free.x )
		dx = VECTORMUL( proj, gs->free.x );
	if ( gs->free.y )
		dy = VECTORMUL( proj, gs->free.y );

	fnt_SHP_Common(gs, dx, dy);
}


/*
 * Interpolate Point
 */
static void fnt_IP (gs)
  register fnt_LocalGraphicStateType *gs;
{
	F26Dot6 oldRange, currentRange;
	register ArrayIndex RP1 = gs->Pt1;
	register ArrayIndex pt2 = gs->Pt2;
	register fnt_ElementType* CE0 = gs->CE0;
	boolean twilight = CE0 == gs->elements || gs->CE1 == gs->elements || gs->CE2 == gs->elements;

	{
/* FCALL */
		currentRange = (F26Dot6)PCFM(gs, gs->CE1->x[pt2] - CE0->x[RP1],
										gs->CE1->y[pt2] - CE0->y[RP1], gs->Project );
		if ( twilight )
/* FCALL */
			oldRange = (F26Dot6)PCFM(gs, gs->CE1->ox[pt2] - CE0->ox[RP1],
										   gs->CE1->oy[pt2] - CE0->oy[RP1], gs->OldProject );
		else
/* FCALL */
			oldRange = (F26Dot6)PCFM(gs, gs->CE1->oox[pt2] - CE0->oox[RP1],
										   gs->CE1->ooy[pt2] - CE0->ooy[RP1], gs->OldProject );
	}
	for (; gs->loop >= 0; --gs->loop)
	{
		register ArrayIndex arg1 = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
		register F26Dot6 tmp;
		if ( twilight )
/* FCALL */
			tmp = (F26Dot6)PCFM(gs, gs->CE2->ox[arg1] - CE0->ox[RP1],
									  gs->CE2->oy[arg1] - CE0->oy[RP1], gs->OldProject );
		else
/* FCALL */
			tmp = (F26Dot6)PCFM(gs, gs->CE2->oox[arg1] - CE0->oox[RP1],
									  gs->CE2->ooy[arg1] - CE0->ooy[RP1], gs->OldProject );

		if ( oldRange )
			tmp = LongMulDiv( currentRange, tmp, oldRange );
		/* Otherwise => desired projection = old projection */
		
/* FCALL */
		tmp -= (F26Dot6)PCFM(gs, gs->CE2->x[arg1] - CE0->x[RP1],
							    gs->CE2->y[arg1] - CE0->y[RP1], gs->Project ); /* delta = desired projection - current projection */
/* FCALL */
		PCFM(gs, gs->CE2, arg1, tmp, gs->MovePoint );
	}
	gs->loop = 0;
}


/*
 * Move Stack Indirect Relative Point
 */
void fnt_MSIRP (gs)
  fnt_LocalGraphicStateType* gs;
{
	register fnt_ElementType* CE0 = gs->CE0;
	register fnt_ElementType* CE1 = gs->CE1;
	register ArrayIndex Pt0 = gs->Pt0;
	register F26Dot6 dist = CHECK_POP(gs, gs->stackPointer ); /* distance   */
	register ArrayIndex pt2 = (ArrayIndex)CHECK_POP(gs, gs->stackPointer ); /* point #    */

	if ( CE1 == gs->elements )
	{
		CE1->ox[pt2] = CE0->ox[Pt0] + VECTORMUL( dist, gs->proj.x );
		CE1->oy[pt2] = CE0->oy[Pt0] + VECTORMUL( dist, gs->proj.y );
		CE1->x[pt2] = CE1->ox[pt2];
		CE1->y[pt2] = CE1->oy[pt2];
	}
/* FCALL */
	dist -= (F26Dot6)PCFM(gs, CE1->x[pt2] - CE0->x[Pt0],
							  CE1->y[pt2] - CE0->y[Pt0], gs->Project );
/* FCALL */
	PCFM(gs, CE1, pt2, dist, gs->MovePoint);
	gs->Pt1 = Pt0;
	gs->Pt2 = pt2;
	if ( BIT0( gs->opCode ) ) {
		gs->Pt0 = pt2; /* move the reference point */
	}
}


/*
 * Align Relative Point
 */
static void fnt_ALIGNRP (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_ElementType* ce1 = gs->CE1;
	register F26Dot6 pt0x = gs->CE0->x[gs->Pt0];
	register F26Dot6 pt0y = gs->CE0->y[gs->Pt0];

	for (; gs->loop >= 0; --gs->loop)
	{
		register ArrayIndex ptNum = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
		register F26Dot6 proj = -(F26Dot6)PCFM(gs, ce1->x[ptNum] - pt0x, ce1->y[ptNum] - pt0y, gs->Project );
/* FCALL */
		PCFM(gs, ce1, ptNum, proj, gs->MovePoint );
	}
	gs->loop = 0;
}



/*
 * Align Two Points ( by moving both of them )
 */
static void fnt_ALIGNPTS (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex pt1, pt2;
	register F26Dot6 move1, dist;

	pt2  = (ArrayIndex)CHECK_POP(gs, gs->stackPointer ); /* point # 2   */
	pt1  = (ArrayIndex)CHECK_POP(gs, gs->stackPointer ); /* point # 1   */
	/* We do not have to check if we are in character element zero (the twilight zone)
	   since both points already have to have defined values before we execute this instruction */
/* FCALL */
	dist = (F26Dot6)PCFM(gs, gs->CE0->x[pt2] - gs->CE1->x[pt1],
							 gs->CE0->y[pt2] - gs->CE1->y[pt1], gs->Project );

	move1 = dist >> 1;
/* FCALL */
	PCFM(gs, gs->CE0, pt1, move1, gs->MovePoint );
/* FCALL */
	PCFM(gs, gs->CE1, pt2, move1 - dist, gs->MovePoint ); /* make sure the total movement equals tmp32 */
}


/*
 * Set Angle Weight
 */
static void fnt_SANGW (gs)
  register fnt_LocalGraphicStateType *gs;
{
	gs->globalGS->localParBlock.angleWeight = (int16)CHECK_POP(gs, gs->stackPointer );
}


/*
 * Does a cheap approximation of Euclidian distance.
 */
static Fract fnt_QuickDist (dx, dy)
  register Fract dx, dy;
{
	if ( dx < 0 ) dx = -dx;
	if ( dy < 0 ) dy = -dy;

	return( dx > dy ? dx + ( dy >> 1 ) : dy + ( dx >> 1 ) );
}


/*
 * Flip Point
 */
static void fnt_FLIPPT (gs)
  fnt_LocalGraphicStateType *gs;
{
	register uint8 *onCurve = gs->CE0->onCurve;
	register F26Dot6* stack = gs->stackPointer;
	register LoopCount count = gs->loop;

	for (; count >= 0; --count)
	{
		register ArrayIndex point = (ArrayIndex)CHECK_POP(gs, stack );
		onCurve[ point ] ^= ONCURVE;
	}
	gs->loop = 0;

	gs->stackPointer = stack;
}


/*
 * Flip On a Range
 */
static void fnt_FLIPRGON (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex lo, hi;
	register LoopCount count;
	register uint8 *onCurve = gs->CE0->onCurve;
	register F26Dot6* stack = gs->stackPointer;

	hi = (ArrayIndex)CHECK_POP(gs, stack );
	CHECK_POINT( gs, gs->CE0, hi );
	lo = (ArrayIndex)CHECK_POP(gs, stack );
	CHECK_POINT( gs, gs->CE0, lo );

	onCurve += lo;
	for (count = (LoopCount)(hi - lo); count >= 0; --count)
		*onCurve++ |= ONCURVE;
	gs->stackPointer = stack;
}


/*
 * Flip On a Range
 */
static void fnt_FLIPRGOFF (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex lo, hi;
	register LoopCount count;
	register uint8 *onCurve = gs->CE0->onCurve;

	hi = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	CHECK_POINT( gs, gs->CE0, hi );
	lo = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	CHECK_POINT( gs, gs->CE0, lo );

	onCurve += lo;
	for (count = (LoopCount)(hi - lo); count >= 0; --count)
		*onCurve++ &= ~ONCURVE;
}


/* 4/22/90 rwb - made more general
 * Sets lower 16 flag bits of ScanControl variable.  Sets scanContolIn if we are in one
 * of the preprograms; else sets scanControlOut.
 *
 * stack: value => -;
 *
 */
static void fnt_SCANCTRL (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_GlobalGraphicStateType *globalGS = gs->globalGS;
	register fnt_ParameterBlock *pb = &globalGS->localParBlock;

	pb->scanControl = (pb->scanControl & 0xFFFF0000) | CHECK_POP(gs, gs->stackPointer );
}


/* 5/24/90 rwb
 * Sets upper 16 bits of ScanControl variable. Sets scanContolIn if we are in one
 * of the preprograms; else sets scanControlOut.
 */

static void fnt_SCANTYPE (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_GlobalGraphicStateType *globalGS = gs->globalGS;
	register fnt_ParameterBlock *pb = &globalGS->localParBlock;
	register int value = (int)CHECK_POP(gs, gs->stackPointer );
	register int32 *scanPtr = &(pb->scanControl);
	if		( value == 0 )  *scanPtr &= 0xFFFF;
	else if ( value == 1 )	*scanPtr = (*scanPtr & 0xFFFF) | STUBCONTROL;
	else if ( value == 2 )	*scanPtr = (*scanPtr & 0xFFFF) | NODOCONTROL;
}


/* 6/28/90 rwb
 * Sets instructControl flags in global graphic state.  Only legal in pre program.
 * A selector is used to choose the flag to be set.
 * Bit0 - NOGRIDFITFLAG - if set, then truetype instructions are not executed.
 * 		A font may want to use the preprogram to check if the glyph is rotated or
 * 	 	transformed in such a way that it is better to not gridfit the glyphs.
 * Bit1 - DEFAULTFLAG - if set, then changes in localParameterBlock variables in the
 *		globalGraphics state made in the CVT preprogram are not copied back into
 *		the defaultParameterBlock.  So, the original default values are the starting
 *		values for each glyph.
 *
 * stack: value, selector => -;
 *
 */
static void fnt_INSTCTRL (gs)   /* <13> */
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_GlobalGraphicStateType *globalGS = gs->globalGS;
	register int32 *ic = &globalGS->localParBlock.instructControl;
	int selector 	= (int)CHECK_POP(gs, gs->stackPointer );
	int32 value 	= (int32)CHECK_POP(gs, gs->stackPointer );
	if( globalGS->init )
	{
		if( selector == 1 )
		{
			*ic &= ~NOGRIDFITFLAG;
			*ic |= (value & NOGRIDFITFLAG);
		}
		else if( selector == 2 )
		{
			*ic &= ~DEFAULTFLAG;
			*ic |= (value & DEFAULTFLAG);
		}
	}
}


/*
 * AdjustAngle         <4>
 */
static void fnt_AA (gs)
  register fnt_LocalGraphicStateType *gs;
{

	register fnt_GlobalGraphicStateType *globalGS = gs->globalGS;
	ArrayIndex ptNum, bestAngle;
	F26Dot6 dx, dy, tmp32;
	Fract pvx, pvy; /* Projection Vector */
    Fract pfProj;
	Fract tpvx, tpvy;
	Fract* anglePoint;		/* x,y, x,y, x,y, ... */
	int16 distance, *angleDistance;
	int32 minPenalty;			/* should this be the same as distance??? mrr-7/17/90 */
	LoopCount i;
	int yFlip, xFlip, xySwap;		/* boolean */


	ptNum = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	/* save the projection vector */
	pvx = gs->proj.x;
	pvy = gs->proj.y;
	pfProj = gs->pfProj;

	dx = gs->CE1->x[ptNum] - gs->CE0->x[gs->Pt0];
	dy = gs->CE1->y[ptNum] - gs->CE0->y[gs->Pt0];

	/* map to the first and second quadrant */
	yFlip = dy < 0 ? dy = -dy, 1 : 0;

	/* map to the first quadrant */
	xFlip = dx < 0 ? dx = -dx, 1 : 0;

	/* map to the first octant */
	xySwap = dy > dx ? tmp32 = dy, dy = dx, dx = tmp32, 1 : 0;

	/* Now tpvy, tpvx contains the line rotated by 90 degrees, so it is in the 3rd octant */
	{
		VECTOR v;
		fnt_Normalize( -dy, dx, &v );
		tpvx = v.x;
		tpvy = v.y;
	}

	/* find the best angle */
	minPenalty = 10 * fnt_pixelSize; bestAngle = -1;
	anglePoint = &globalGS->anglePoint[0].x;		/* x,y, x,y, x,y, ... */
	angleDistance = globalGS->angleDistance;
	for ( i = 0; i < MAXANGLES; i++ )
	{
		if ( (distance = *angleDistance++) >= minPenalty )
			break; /* No more improvement is possible */
		gs->proj.x = *anglePoint++;
		gs->proj.y = *anglePoint++;
		/* Now find the distance between these vectors, this will help us gain speed */
		if ( fnt_QuickDist( gs->proj.x - tpvx, gs->proj.y - tpvy ) > ( 210831287 ) ) /* 2PI / 32 */
			continue; /* Difference is to big, we will at most change the angle +- 360/32 = +- 11.25 degrees */

		tmp32 = fnt_Project( gs, dx, dy ); /* Calculate the projection */
		if ( tmp32 < 0 ) tmp32 = -tmp32;

		tmp32 = ( globalGS->localParBlock.angleWeight * tmp32 ) >> fnt_pixelShift;
		tmp32 +=  distance;
		if ( tmp32 < minPenalty ) {
			minPenalty = tmp32;
			bestAngle = i;
		}
	}

	tmp32 = 0;
	if ( bestAngle >= 0 ) {
		/* OK, we found a good angle */
		gs->proj.x = globalGS->anglePoint[bestAngle].x;
		gs->proj.y = globalGS->anglePoint[bestAngle].y;
		/* Fold the projection vector back into the full coordinate plane. */
		if ( xySwap ) {
			tmp32 = gs->proj.y; gs->proj.y = gs->proj.x; gs->proj.x = tmp32;
		}
		if ( xFlip ) {
			gs->proj.x = -gs->proj.x;
		}
		if ( yFlip ) {
			gs->proj.y = -gs->proj.y;
		}
		fnt_ComputeAndCheck_PF_Proj( gs );

		tmp32 = fnt_Project( gs, gs->CE1->x[gs->Pt0] - gs->CE0->x[ptNum], gs->CE1->y[gs->Pt0] - gs->CE0->y[ptNum] );
	}
	fnt_MovePoint( gs, gs->CE1, ptNum, tmp32 );

	gs->proj.x = pvx; /* restore the projection vector */
	gs->proj.y = pvy;
	gs->pfProj = pfProj;
}


/*
 *	Called by fnt_PUSHB and fnt_NPUSHB
 */
static void fnt_PushSomeStuff (gs, count, pushBytes)
  fnt_LocalGraphicStateType *gs;
  register LoopCount count;
  boolean pushBytes;
{
	register F26Dot6* stack = gs->stackPointer;
	register uint8* instr = gs->insPtr;
	if (pushBytes)
		for (--count; count >= 0; --count)
			CHECK_PUSH( gs, stack, GETBYTE( instr ));
	else
	{
		for (--count; count >= 0; --count)
		{
			int16 word = *instr++;
			CHECK_PUSH( gs, stack, (int16)((word << 8) + *instr++));
		}
	}
	gs->stackPointer = stack;
	gs->insPtr = instr;
}


/*
 * PUSH Bytes		<3>
 */
static void fnt_PUSHB (gs)
  fnt_LocalGraphicStateType *gs;
{
	fnt_PushSomeStuff(gs, gs->opCode - 0xb0 + 1, true);
}


/*
 * N PUSH Bytes
 */
static void fnt_NPUSHB (gs)
  register fnt_LocalGraphicStateType *gs;
{
	fnt_PushSomeStuff(gs, GETBYTE( gs->insPtr ), true);
}


/*
 * PUSH Words		<3>
 */
static void fnt_PUSHW (gs)
  register fnt_LocalGraphicStateType *gs;
{
	fnt_PushSomeStuff(gs, gs->opCode - 0xb8 + 1, false);
}


/*
 * N PUSH Words
 */
static void fnt_NPUSHW (gs)
  register fnt_LocalGraphicStateType *gs;
{
	fnt_PushSomeStuff(gs, GETBYTE( gs->insPtr ), false);
}


/*
 * Write Store
 */
static void fnt_WS (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register F26Dot6 storage;
	register ArrayIndex storeIndex;

	storage = CHECK_POP(gs, gs->stackPointer );
	storeIndex = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );

	CHECK_STORAGE( gs, storeIndex );

	gs->globalGS->store[ storeIndex ] = storage;
}


/*
 * Read Store
 */
static void fnt_RS (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex storeIndex;

	storeIndex = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	CHECK_STORAGE( gs, storeIndex );
	CHECK_PUSH( gs, gs->stackPointer, gs->globalGS->store[storeIndex] );
}


/*
 * Write Control Value Table from outLine, assumes the value comes form the outline domain
 */
static void fnt_WCVT (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex cvtIndex;
	register F26Dot6 cvtValue;

	cvtValue = CHECK_POP(gs, gs->stackPointer );
	cvtIndex = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );

	CHECK_CVT( gs, cvtIndex );

	gs->globalGS->controlValueTable[ cvtIndex ] = cvtValue;

	/* The BASS outline is in the transformed domain but the cvt is not so apply the inverse transform */
	if ( cvtValue ) {
		register F26Dot6 tmpCvt;
/* FCALL */
		if ( (tmpCvt = (F26Dot6)PCFM(gs, cvtIndex, gs->GetCVTEntry )) && tmpCvt != cvtValue ) {
			gs->globalGS->controlValueTable[ cvtIndex ] = FixMul( cvtValue,  FixDiv( cvtValue, tmpCvt ) );
		}
	}
}


/*
 * Write Control Value Table From Original Domain, assumes the value comes from the original domain, not the cvt or outline
 */
static void fnt_WCVTFOD (gs)
  fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex cvtIndex;
	register F26Dot6 cvtValue;
	register fnt_GlobalGraphicStateType *globalGS = gs->globalGS;

	cvtValue = CHECK_POP(gs, gs->stackPointer );
	cvtIndex = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	CHECK_CVT( gs, cvtIndex );
/* FCALL */
	globalGS->controlValueTable[ cvtIndex ] = (F26Dot6)PCFM(globalGS, cvtValue, globalGS->ScaleFunc);
}


/*
 * Read Control Value Table
 */
static void fnt_RCVT (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex cvtIndex;

	cvtIndex = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
/* FCALL */
	CHECK_PUSH( gs, gs->stackPointer, (F26Dot6)PCFM(gs, cvtIndex, gs->GetCVTEntry ) );
}


/*
 * Read Coordinate
 */
static void fnt_RC (gs)
  register fnt_LocalGraphicStateType *gs;
{
    ArrayIndex pt;
	fnt_ElementType *element;
	register F26Dot6 proj;

	pt = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	element = gs->CE2;

    if ( BIT0( gs->opCode ) )
/* FCALL */
	    proj = (F26Dot6)PCFM(gs, element->ox[pt], element->oy[pt], gs->OldProject );
	else
/* FCALL */
	    proj = (F26Dot6)PCFM(gs, element->x[pt], element->y[pt], gs->Project );

	CHECK_PUSH( gs, gs->stackPointer, proj );
}


/*
 * Write Coordinate
 */
static void fnt_WC (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register F26Dot6 proj, coord;
	register ArrayIndex pt;
	register fnt_ElementType *element;

	coord = CHECK_POP(gs, gs->stackPointer );/* value */
	pt = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );/* point */
	element = gs->CE2;

/* FCALL */
	proj = (F26Dot6)PCFM(gs, element->x[pt],  element->y[pt], gs->Project );
	proj = coord - proj;

/* FCALL */
	PCFM(gs, element, pt, proj, gs->MovePoint );

	if (element == gs->elements)		/* twilightzone */
	{
		element->ox[pt] = element->x[pt];
		element->oy[pt] = element->y[pt];
	}
}


/*
 * Measure Distance
 */
static void fnt_MD (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register ArrayIndex pt1, pt2;
	register F26Dot6 proj, *stack = gs->stackPointer;
	register fnt_GlobalGraphicStateType *globalGS = gs->globalGS;

	pt2 = (ArrayIndex)CHECK_POP(gs, stack );
	pt1 = (ArrayIndex)CHECK_POP(gs, stack );
	if ( BIT0( gs->opCode - MD_CODE ) )
	{
/* FCALL */
		proj  = (F26Dot6)PCFM(gs, gs->CE0->oox[pt1] - gs->CE1->oox[pt2],
								     gs->CE0->ooy[pt1] - gs->CE1->ooy[pt2], gs->OldProject );
/* FCALL */
	    proj = (F26Dot6)PCFM(globalGS, proj, globalGS->ScaleFunc );
	}								 
	else
/* FCALL */
		proj  = (F26Dot6)PCFM(gs, gs->CE0->x[pt1] - gs->CE1->x[pt2],
								  gs->CE0->y[pt1] - gs->CE1->y[pt2], gs->Project );
	CHECK_PUSH( gs, stack, proj );
	gs->stackPointer = stack;
}


/*
 * Measure Pixels Per EM
 */
static void fnt_MPPEM (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register uint16 ppem;
/*    register Fixed fixedppem;*/
	register fnt_GlobalGraphicStateType *globalGS = gs->globalGS;

			/* convert integer globalGS->pixelsPerEm to Fixed */
	ppem = globalGS->pixelsPerEm;
/*	fixedppem = (Fixed)ppem;*/

	if ( !globalGS->identityTransformation )
		ppem = (uint16)FixMul( (Fixed)ppem, fnt_GetCVTScale( gs ) );

	CHECK_PUSH( gs, gs->stackPointer, ppem );
}


/*
 * Measure Point Size
 */
static void fnt_MPS (gs)
  register fnt_LocalGraphicStateType *gs;
{
	CHECK_PUSH( gs, gs->stackPointer, gs->globalGS->pointSize );
}


/*
 * Get Miscellaneous info: version number, rotated, stretched 	<6>
 * Version number is 8 bits.  This is version 0x01 : 5/1/90
 *
 */

static void fnt_GETINFO (gs)
  register fnt_LocalGraphicStateType* gs;
{
	register fnt_GlobalGraphicStateType *globalGS = gs->globalGS;
	register int selector = (int)CHECK_POP(gs, gs->stackPointer );
	register int info = 0;

	if( selector & 1)								/* version */
		info |= 1;
	if( (selector & 2) && (globalGS->non90DegreeTransformation & 0x1) )
		info |= ROTATEDGLYPH;
	if( (selector & 4) &&  (globalGS->non90DegreeTransformation & 0x2))
		info |= STRETCHEDGLYPH;
	CHECK_PUSH( gs, gs->stackPointer, info );
}


/*
 * FLIP ON
 */
static void fnt_FLIPON (gs)
  register fnt_LocalGraphicStateType *gs;
{
	gs->globalGS->localParBlock.autoFlip = true;
}


/*
 * FLIP OFF
 */
static void fnt_FLIPOFF (gs)
  register fnt_LocalGraphicStateType *gs;
{
	gs->globalGS->localParBlock.autoFlip = false;
}


#ifndef NOT_ON_THE_MAC
#ifdef DEBUG
/*
 * DEBUG
 */
static void fnt_DEBUG (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register int32 arg;
	int8 buffer[24];

	arg = CHECK_POP(gs, gs->stackPointer );

	buffer[1] = 'D';
	buffer[2] = 'E';
	buffer[3] = 'B';
	buffer[4] = 'U';
	buffer[5] = 'G';
	buffer[6] = ' ';
	if ( arg >= 0 ) {
		buffer[7] = '+';
	} else {
		arg = -arg;
		buffer[7] = '-';
	}

	buffer[13] = arg % 10 + '0'; arg /= 10;
	buffer[12] = arg % 10 + '0'; arg /= 10;
	buffer[11] = arg % 10 + '0'; arg /= 10;
	buffer[10] = arg % 10 + '0'; arg /= 10;
	buffer[ 9] = arg % 10 + '0'; arg /= 10;
	buffer[ 8] = arg % 10 + '0'; arg /= 10;

	buffer[14] = arg ? '*' : ' ';


	buffer[0] = 14; /* convert to pascal */
	DebugStr( buffer );
}

#else		/* debug */

static void fnt_DEBUG (gs)
  register fnt_LocalGraphicStateType* gs;
{
	CHECK_POP(gs, gs->stackPointer );
}

#endif		/* debug */
#else

static void fnt_DEBUG (gs)
  register fnt_LocalGraphicStateType* gs;
{
	CHECK_POP(gs, gs->stackPointer );
}

#endif		/* ! not on the mac */


/*
 *	This guy is here to save space for simple insructions
 *	that pop two arguments and push one back on.
 */
static void fnt_BinaryOperand (gs)
  fnt_LocalGraphicStateType* gs;
{
	F26Dot6* stack = gs->stackPointer;
	F26Dot6 arg2 = CHECK_POP(gs, stack );
	F26Dot6 arg1 = CHECK_POP(gs, stack );

	switch (gs->opCode) {
	case LT_CODE:	BOOLEANPUSH( stack, arg1 < arg2 );  break;
	case LTEQ_CODE:	BOOLEANPUSH( stack, arg1 <= arg2 ); break;
	case GT_CODE:	BOOLEANPUSH( stack, arg1 > arg2 );  break;
	case GTEQ_CODE:	BOOLEANPUSH( stack, arg1 >= arg2 ); break;
	case EQ_CODE:	BOOLEANPUSH( stack, arg1 == arg2 ); break;
	case NEQ_CODE:	BOOLEANPUSH( stack, arg1 != arg2 ); break;

	case AND_CODE:	BOOLEANPUSH( stack, arg1 && arg2 ); break;
	case OR_CODE:	BOOLEANPUSH( stack, arg1 || arg2 ); break;

	case ADD_CODE:	CHECK_PUSH( gs, stack, arg1 + arg2 ); break;
	case SUB_CODE:	CHECK_PUSH( gs, stack, arg1 - arg2 ); break;
	case MUL_CODE:	CHECK_PUSH( gs, stack, Mul26Dot6( arg1, arg2 )); break;
	case DIV_CODE:	CHECK_PUSH( gs, stack, Div26Dot6( arg1, arg2 )); break;
	case MAX_CODE:	if (arg1 < arg2) arg1 = arg2; CHECK_PUSH( gs, stack, arg1 ); break;
	case MIN_CODE:	if (arg1 > arg2) arg1 = arg2; CHECK_PUSH( gs, stack, arg1 ); break;
#ifdef DEBUG
	default:
		Debugger();
#endif
	}
	gs->stackPointer = stack;
	CHECK_STACK(gs);
}


static void fnt_UnaryOperand (gs)
  fnt_LocalGraphicStateType* gs;
{
	F26Dot6* stack = gs->stackPointer;
	F26Dot6 arg = CHECK_POP(gs, stack );
	uint8 opCode = gs->opCode;

	switch (opCode) {
	case ODD_CODE:
	case EVEN_CODE:
		arg = fnt_RoundToGrid( arg, 0L, gs );
		arg >>= fnt_pixelShift;
		if ( opCode == ODD_CODE )
			arg++;
		BOOLEANPUSH( stack, (arg & 1) == 0 );
		break;
	case NOT_CODE:	BOOLEANPUSH( stack, !arg );  break;

	case ABS_CODE:	CHECK_PUSH( gs, stack, arg > 0 ? arg : -arg ); break;
	case NEG_CODE:	CHECK_PUSH( gs, stack, -arg ); break;

	case CEILING_CODE:
		arg += fnt_pixelSize - 1;
	case FLOOR_CODE:
		arg &= ~(fnt_pixelSize-1);
		CHECK_PUSH( gs, stack, arg );
		break;
#ifdef DEBUG
	default:
		Debugger();
#endif
	}
	gs->stackPointer = stack;
	CHECK_STACK(gs);
}


#define NPUSHB_CODE 0x40
#define NPUSHW_CODE 0x41

#define PUSHB_START 0xb0
#define PUSHB_END 	0xb7
#define PUSHW_START 0xb8
#define PUSHW_END 	0xbf

/*
 * Internal function for fnt_IF(), and fnt_FDEF()
 */
static void fnt_SkipPushCrap (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register uint8 opCode = gs->opCode;
	register uint8* instr = gs->insPtr;
	register ArrayIndex count;

	if ( opCode == NPUSHB_CODE ) {
		count = (ArrayIndex)*instr++;
		instr += count;
	} else if ( opCode == NPUSHW_CODE ) {
		count = (ArrayIndex)*instr++;
		instr += count + count;
	} else if ( opCode >= PUSHB_START && opCode <= PUSHB_END ) {
		count = (ArrayIndex)(opCode - PUSHB_START + 1);
		instr += count;
	} else if ( opCode >= PUSHW_START && opCode <= PUSHW_END ) {
		count = (ArrayIndex)(opCode - PUSHW_START + 1);
		instr += count + count;
	}
	gs->insPtr = instr;
}


/*
 * IF
 */
static void fnt_IF (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register int level;
	register uint8 opCode;

	if ( ! CHECK_POP(gs, gs->stackPointer ) ) {
		/* Now skip instructions */
		for ( level = 1; level; ) {
			/* level = # of "ifs" minus # of "endifs" */
			if ( (gs->opCode = opCode = *gs->insPtr++) == EIF_CODE ) {
				level--;
			} else if ( opCode == IF_CODE ) {
				level++;
			} else if ( opCode == ELSE_CODE ) {
				if ( level == 1 ) break;
			} else
				fnt_SkipPushCrap( gs );
		}
	}
}


/*
 *	ELSE for the IF
 */
static void fnt_ELSE (gs)
  fnt_LocalGraphicStateType* gs;
{
    register int level;
	register uint8 opCode;

	for ( level = 1; level; ) {
		/* level = # of "ifs" minus # of "endifs" */
		if ( (gs->opCode = opCode = *gs->insPtr++) == EIF_CODE ) { /* EIF */
			level--;
		} else if ( opCode == IF_CODE ) {
			level++;
		} else
			fnt_SkipPushCrap( gs );
	}
}


/*
 * End IF
 */
static void fnt_EIF (gs)
  fnt_LocalGraphicStateType* gs;
{
/* #pragma unused(gs) */
}


/*
 * Jump Relative
 */
static void fnt_JMPR (gs)
  register fnt_LocalGraphicStateType* gs;
{
	register ArrayIndex offset;

	offset = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	offset--; /* since the interpreter post-increments the IP */
	gs->insPtr += offset;
}


/*
 * Jump Relative On True
 */
static void fnt_JROT (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register ArrayIndex offset;
	register F26Dot6* stack = gs->stackPointer;

	if ( CHECK_POP(gs, stack ) ) {
		offset = (ArrayIndex)CHECK_POP(gs, stack );
		--offset; /* since the interpreter post-increments the IP */
		gs->insPtr += offset;
	} else {
		--stack;/* same as POP */
	}
	gs->stackPointer = stack;
}


/*
 * Jump Relative On False
 */
static void fnt_JROF (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register ArrayIndex offset;
	register F26Dot6* stack = gs->stackPointer;

	if ( CHECK_POP(gs, stack ) ) {
		--stack;/* same as POP */
	} else {
		offset = (ArrayIndex)CHECK_POP(gs, stack );
		offset--; /* since the interpreter post-increments the IP */
		gs->insPtr += offset;
	}
	gs->stackPointer = stack;
}


/*
 * ROUND
 */
static void fnt_ROUND (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register F26Dot6 arg1;
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;

	arg1 = CHECK_POP(gs, gs->stackPointer );

	CHECK_RANGE( gs->opCode, 0x68, 0x6B );

/* FCALL */
	arg1 = (F26Dot6)PCFM(arg1, gs->globalGS->engine[gs->opCode - 0x68], gs, pb->RoundValue);
	CHECK_PUSH( gs, gs->stackPointer , arg1 );
}


/*
 * No ROUND
 */
static void fnt_NROUND (gs)
  register fnt_LocalGraphicStateType *gs;
{
    register F26Dot6 arg1;

	arg1 = CHECK_POP(gs, gs->stackPointer );

	CHECK_RANGE( gs->opCode, 0x6C, 0x6F );

	arg1 = fnt_RoundOff( arg1, gs->globalGS->engine[gs->opCode - 0x6c], gs );
	CHECK_PUSH( gs, gs->stackPointer , arg1 );
}


/*
 * An internal function used by MIRP an MDRP.
 */
static F26Dot6 fnt_CheckSingleWidth (value, gs)
  register F26Dot6 value;
  register fnt_LocalGraphicStateType *gs;
{
	register F26Dot6 delta, scaledSW;
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;

/* FCALL */
	scaledSW = (F26Dot6)PCFM(gs, gs->GetSingleWidth );

	if ( value >= 0 ) {
		delta = value - scaledSW;
		if ( delta < 0 )    delta = -delta;
		if ( delta < pb->sWCI )    value = scaledSW;
	} else {
		value = -value;
		delta = value - scaledSW;
		if ( delta < 0 )    delta = -delta;
		if ( delta < pb->sWCI )    value = scaledSW;
		value = -value;
	}
	return value;
}


/*
 * Move Direct Relative Point
 */
static void fnt_MDRP (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register ArrayIndex pt1, pt0 = gs->Pt0;
	register F26Dot6 tmp, tmpC;
    register fnt_ElementType *element = gs->CE1;
	register fnt_GlobalGraphicStateType *globalGS = gs->globalGS;
	register fnt_ParameterBlock *pb = &globalGS->localParBlock;

	pt1 = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );

	CHECK_POINT(gs, gs->CE0, pt0);
	CHECK_POINT(gs, element, pt1);

	if ( gs->CE0 == gs->elements || element == gs->elements ) {
/* FCALL */
		tmp  = (F26Dot6)PCFM(gs, element->ox[pt1] - gs->CE0->ox[pt0],
								     element->oy[pt1] - gs->CE0->oy[pt0], gs->OldProject );
	} else {
/* FCALL */
		tmp  = (F26Dot6)PCFM(gs, element->oox[pt1] - gs->CE0->oox[pt0],
								     element->ooy[pt1] - gs->CE0->ooy[pt0], gs->OldProject );
/* FCALL */
	    tmp = (F26Dot6)PCFM(globalGS, tmp, globalGS->ScaleFunc );
	}

	if ( pb->sWCI ) {
		tmp = fnt_CheckSingleWidth( tmp, gs );
	}

	tmpC = tmp;
	if ( BIT2( gs->opCode )  ) {
/* FCALL */
		tmp = (F26Dot6)PCFM(tmp, globalGS->engine[gs->opCode & 0x03], gs, pb->RoundValue );
	} else {
		tmp = fnt_RoundOff( tmp, globalGS->engine[gs->opCode & 0x03], gs );
	}


	if ( BIT3( gs->opCode ) )
	{
		F26Dot6 tmpB = pb->minimumDistance;
		if ( tmpC >= 0 ) {
			if ( tmp < tmpB ) {
				tmp = tmpB;
			}
		} else {
			tmpB = -tmpB;
			if ( tmp > tmpB ) {
				tmp = tmpB;
			}
		}
	}

/* FCALL */
	tmpC = (F26Dot6)PCFM(gs, element->x[pt1] - gs->CE0->x[pt0],
							element->y[pt1] - gs->CE0->y[pt0], gs->Project );
	tmp -= tmpC;
/* FCALL */
	PCFM(gs, element, pt1, tmp, gs->MovePoint );
	gs->Pt1 = pt0;
	gs->Pt2 = pt1;
	if ( BIT4( gs->opCode ) ) {
		gs->Pt0 = pt1; /* move the reference point */
	}
}


/*
 * Move Indirect Relative Point
 */
static void fnt_MIRP (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register ArrayIndex ptNum;
	register F26Dot6 tmp, tmpB, tmpC;
	register fnt_GlobalGraphicStateType *globalGS = gs->globalGS;
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;

/* FCALL */
	tmp = (F26Dot6)PCFM(gs, (ArrayIndex)CHECK_POP(gs, gs->stackPointer ), gs->GetCVTEntry );
	ptNum = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );

	if ( pb->sWCI ) {
		tmp = fnt_CheckSingleWidth( tmp, gs );
	}

	if ( gs->CE1 == gs->elements )
	{
		gs->CE1->ox[ptNum] = gs->CE0->ox[gs->Pt0];
		gs->CE1->oy[ptNum] = gs->CE0->oy[gs->Pt0];
		gs->CE1->ox[ptNum] += VECTORMUL( tmp, gs->proj.x );
		gs->CE1->oy[ptNum] += VECTORMUL( tmp, gs->proj.y );
		gs->CE1->x[ptNum] = gs->CE1->ox[ptNum];
		gs->CE1->y[ptNum] = gs->CE1->oy[ptNum];
	}

/* FCALL */
	tmpC  = (F26Dot6)PCFM(gs, gs->CE1->ox[ptNum] - gs->CE0->ox[gs->Pt0],
							      gs->CE1->oy[ptNum] - gs->CE0->oy[gs->Pt0], gs->OldProject );
	if ( pb->autoFlip ) {
		if ( ((int32)(tmpC ^ tmp)) < 0 ) {
			tmp = -tmp; /* Do the auto flip */
		}
	}

	if ( BIT2( gs->opCode )  ) {
		tmpB = tmp - tmpC;
		if ( tmpB < 0 )    tmpB = -tmpB;
		if ( tmpB > pb->wTCI )    tmp = tmpC;
/* FCALL */
		tmp = (F26Dot6)PCFM(tmp, globalGS->engine[gs->opCode & 0x03], gs, pb->RoundValue );
	} else {
		tmp = fnt_RoundOff( tmp, globalGS->engine[gs->opCode & 0x03], gs );
	}


	if ( BIT3( gs->opCode ) ) {
		tmpB = gs->globalGS->localParBlock.minimumDistance;
		if ( tmpC >= 0 ) {
			if ( tmp < tmpB ) {
				tmp = tmpB;
			}
		} else {
			tmpB = -tmpB;
			if ( tmp > tmpB ) {
				tmp = tmpB;
			}
		}
	}

/* FCALL */
	tmpC  = (F26Dot6)PCFM(gs, gs->CE1->x[ptNum] - gs->CE0->x[gs->Pt0],
							   gs->CE1->y[ptNum] - gs->CE0->y[gs->Pt0], gs->Project );

	tmp  -= tmpC;

/* FCALL */
	PCFM(gs, gs->CE1, ptNum, tmp, gs->MovePoint );
	gs->Pt1 = gs->Pt0;
	gs->Pt2 = ptNum;
	if ( BIT4( gs->opCode ) ) {
		gs->Pt0 = ptNum; /* move the reference point */
	}
}


/*
 * CALL a function
 */
static void fnt_CALL (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_funcDef *funcDef;
	uint8 *ins;
	fnt_GlobalGraphicStateType *globalGS = gs->globalGS;
	ArrayIndex arg = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );

	CHECK_ASSERTION( globalGS->funcDef != 0 );
	CHECK_FDEF( gs, arg );
    funcDef = &globalGS->funcDef[ arg ];

	CHECK_PROGRAM(funcDef->pgmIndex);
	ins     = globalGS->pgmList[ funcDef->pgmIndex ];

	CHECK_ASSERTION( ins != 0 );

	ins += funcDef->start;
/* FCALL */
    PCFM(gs, ins, ins + funcDef->length, gs->Interpreter);
}


/*
 * Function DEFinition
 */
static void fnt_FDEF (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_funcDef *funcDef;
	uint8* program, *funcStart;
	fnt_GlobalGraphicStateType *globalGS = gs->globalGS;
	ArrayIndex arg = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );

	CHECK_FDEF( gs, arg );

    funcDef = &globalGS->funcDef[ arg ];
	program = globalGS->pgmList[ funcDef->pgmIndex = globalGS->pgmIndex ];

	CHECK_PROGRAM(funcDef->pgmIndex);
	CHECK_ASSERTION( globalGS->funcDef != 0 );
	CHECK_ASSERTION( globalGS->pgmList[funcDef->pgmIndex] != 0 );

	funcDef->start = gs->insPtr - program;
	funcStart = gs->insPtr;
	while ( (gs->opCode = *gs->insPtr++) != ENDF_CODE )
		fnt_SkipPushCrap( gs );

	funcDef->length = gs->insPtr - funcStart - 1; /* don't execute ENDF */
}


/*
 * LOOP while CALLing a function
 */
static void fnt_LOOPCALL (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register uint8 *start, *stop;
	register InterpreterFunc Interpreter;
	register fnt_funcDef *funcDef;
	ArrayIndex arg = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	register LoopCount loop;

	CHECK_FDEF( gs, arg );

    funcDef	= &(gs->globalGS->funcDef[ arg ]);
	{
		uint8* ins;
		
		CHECK_PROGRAM(funcDef->pgmIndex);
		ins = gs->globalGS->pgmList[ funcDef->pgmIndex ];

		start		= &ins[funcDef->start];
		stop		= &ins[funcDef->start + funcDef->length];	/* funcDef->end -> funcDef->length <4> */
	}
	Interpreter = gs->Interpreter;
	loop = (LoopCount)CHECK_POP(gs, gs->stackPointer );
    for (--loop; loop >= 0; --loop )
/* FCALL */
        PCFM(gs, start, stop, Interpreter );
}


/*
 *	This guy returns the index of the given opCode, or 0 if not found <4>
 */
static fnt_instrDef* fnt_FindIDef (gs, opCode)
  fnt_LocalGraphicStateType* gs;
  register uint8 opCode;
{
	register fnt_GlobalGraphicStateType* globalGS = gs->globalGS;
	register LoopCount count = globalGS->instrDefCount;
	register fnt_instrDef* instrDef = globalGS->instrDef;
	for (--count; count >= 0; instrDef++, --count)
		if (instrDef->opCode == opCode)
			return instrDef;
	return 0;
}


/*
 *	This guy gets called for opCodes that has been patch by the font's IDEF	<4>
 *	or if they have never been defined.  If there is no corresponding IDEF,
 *	flag it as an illegal instruction.
 */
static void fnt_IDefPatch (gs)
  register fnt_LocalGraphicStateType* gs;
{
	register fnt_instrDef* instrDef = fnt_FindIDef(gs, gs->opCode);
	if (instrDef == 0)
		fnt_IllegalInstruction( gs );
	else
	{
		register uint8* program;

		CHECK_PROGRAM(instrDef->pgmIndex);
		program = gs->globalGS->pgmList[ instrDef->pgmIndex ];

		program += instrDef->start;
/* FCALL */
	    PCFM(gs, program, program + instrDef->length, gs->Interpreter);
	}
}


/*
 * Instruction DEFinition	<4>
 */
static void fnt_IDEF (gs)
  register fnt_LocalGraphicStateType* gs;
{
	register uint8 opCode = (uint8)CHECK_POP(gs, gs->stackPointer );
	register fnt_instrDef* instrDef = fnt_FindIDef(gs, opCode);
	register ArrayIndex pgmIndex = (ArrayIndex)gs->globalGS->pgmIndex;
	uint8* program = gs->globalGS->pgmList[ pgmIndex ];
	uint8* instrStart = gs->insPtr;

	CHECK_PROGRAM(pgmIndex);

	if (!instrDef)
		instrDef = gs->globalGS->instrDef + gs->globalGS->instrDefCount++;

	instrDef->pgmIndex = pgmIndex;
	instrDef->opCode = opCode;		/* this may or may not have been set */
	instrDef->start = gs->insPtr - program;

	while ( (gs->opCode = *gs->insPtr++) != ENDF_CODE )
		fnt_SkipPushCrap( gs );

	instrDef->length = gs->insPtr - instrStart - 1; /* don't execute ENDF */
}


/*
 * UnTouch Point
 */
static void fnt_UTP (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register ArrayIndex point = (ArrayIndex)CHECK_POP(gs, gs->stackPointer );
	register uint8* f = gs->CE0->f;

	if ( gs->free.x ) {
		f[point] &= ~XMOVED;
	}
	if ( gs->free.y ) {
		f[point] &= ~YMOVED;
	}
}


/*
 * Set Delta Base
 */
static void fnt_SDB (gs)
  register fnt_LocalGraphicStateType *gs;
{
	gs->globalGS->localParBlock.deltaBase = (int16)CHECK_POP(gs, gs->stackPointer );
}


/*
 * Set Delta Shift
 */
static void fnt_SDS (gs)
  register fnt_LocalGraphicStateType *gs;
{
	gs->globalGS->localParBlock.deltaShift = (int16)CHECK_POP(gs, gs->stackPointer );
}


/*
 * DeltaEngine, internal support routine
 */
static void fnt_DeltaEngine (gs, doIt, base, shift)
  register fnt_LocalGraphicStateType *gs;
  FntMoveFunc doIt;
  int16 base, shift;
{
	register int32 tmp;
	register int32 fakePixelsPerEm, ppem;
	register int32 aim, high;
	register int32 tmp32;

	/* Find the beginning of data pairs for this particular size */
	high = (int32)CHECK_POP(gs, gs->stackPointer ) << 1; /* -= number of pops required */
	gs->stackPointer -= high;

	/* same as fnt_MPPEM() */
	tmp32 = gs->globalGS->pixelsPerEm;

	if ( !gs->globalGS->identityTransformation ) {
		Fixed scale;

		scale = fnt_GetCVTScale( gs );
		tmp32 = FixMul( tmp32, scale );
	}

	fakePixelsPerEm = tmp32 - base;



	if ( fakePixelsPerEm >= 16 ||fakePixelsPerEm < 0 ) return; /* Not within exception range */
	fakePixelsPerEm <<= 4;

	aim = 0;
	tmp = high >> 1; tmp &= ~1;
	while ( tmp > 2 ) {
		ppem  = gs->stackPointer[ aim + tmp ]; /* [ ppem << 4 | exception ] */
		if ( (ppem & ~0x0f) < fakePixelsPerEm ) {
			aim += tmp;
		}
		tmp >>= 1; tmp &= ~1;
	}

	while ( aim < high ) {
		ppem  = gs->stackPointer[ aim ]; /* [ ppem << 4 | exception ] */
		if ( (tmp = (ppem & ~0x0f)) == fakePixelsPerEm ) {
			/* We found an exception, go ahead and apply it */
			tmp  = ppem & 0xf; /* 0 ... 15 */
			tmp -= tmp >= 8 ? 7 : 8; /* -8 ... -1, 1 ... 8 */
			tmp <<= fnt_pixelShift; /* convert to pixels */
			tmp >>= shift; /* scale to right size */
/* FCALL */
			PCFM(gs, gs->CE0, gs->stackPointer[aim+1] /* point number */, tmp /* the delta */, doIt );
		} else if ( tmp > fakePixelsPerEm ) {
			break; /* we passed the data */
		}
		aim += 2;
	}
}


/*
 * DELTAP1
 */
static void fnt_DELTAP1 (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;
	fnt_DeltaEngine( gs, gs->MovePoint, pb->deltaBase, pb->deltaShift );
}


/*
 * DELTAP2
 */
static void fnt_DELTAP2 (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;
	fnt_DeltaEngine( gs, gs->MovePoint, pb->deltaBase+16, pb->deltaShift );
}


/*
 * DELTAP3
 */
static void fnt_DELTAP3 (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;
	fnt_DeltaEngine( gs, gs->MovePoint, pb->deltaBase+32, pb->deltaShift );
}


/*
 * DELTAC1
 */
static void fnt_DELTAC1 (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;
	fnt_DeltaEngine( gs, fnt_ChangeCvt, pb->deltaBase, pb->deltaShift );
}


/*
 * DELTAC2
 */
static void fnt_DELTAC2 (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;
	fnt_DeltaEngine( gs, fnt_ChangeCvt, pb->deltaBase+16, pb->deltaShift );
}


/*
 * DELTAC3
 */
static void fnt_DELTAC3 (gs)
  register fnt_LocalGraphicStateType *gs;
{
	register fnt_ParameterBlock *pb = &gs->globalGS->localParBlock;
	fnt_DeltaEngine( gs, fnt_ChangeCvt, pb->deltaBase+32, pb->deltaShift );
}

#pragma Code()

#pragma Code ("TTFntCode")


/*
 *	Rebuild the jump table		<4>
 */
static void fnt_DefaultJumpTable (function)
  register voidFunc* function;
{
	register LoopCount i;
#define DEFINE_FUNCTION(f) (static voidFunc dfp_%f = &f; dfpv = &f);

	/***** 0x00 - 0x0f *****/
    *function++ = dfp_fnt_SVTCA_0;
	*function++ = dfp_fnt_SVTCA_1;
	*function++ = dfp_fnt_SPVTCA;
	*function++ = dfp_fnt_SPVTCA;
	*function++ = dfp_fnt_SPVTCA;
	*function++ = dfp_fnt_SPVTCA;
	*function++ = dfp_fnt_SPVTL;
	*function++ = dfp_fnt_SPVTL;
	*function++ = dfp_fnt_SPVTL;
	*function++ = dfp_fnt_SPVTL;
	*function++ = dfp_fnt_WPV;
	*function++ = dfp_fnt_WPV;
	*function++ = dfp_fnt_RPV;
	*function++ = dfp_fnt_RFV;
	*function++ = dfp_fnt_SFVTPV;
	*function++ = dfp_fnt_ISECT;

	/***** 0x10 - 0x1f *****/
	*function++ = dfp_fnt_SetLocalGraphicState;
	*function++ = dfp_fnt_SetLocalGraphicState;
	*function++ = dfp_fnt_SetLocalGraphicState;
	*function++ = dfp_fnt_SetElementPtr;
	*function++ = dfp_fnt_SetElementPtr;
	*function++ = dfp_fnt_SetElementPtr;
	*function++ = dfp_fnt_SetElementPtr;
	*function++ = dfp_fnt_SetLocalGraphicState;
	*function++ = dfp_fnt_SetRoundState;
	*function++ = dfp_fnt_SetRoundState;
	*function++ = dfp_fnt_LMD;						/* fnt_LMD; */
	*function++ = dfp_fnt_ELSE;						/* used to be fnt_RLSB */
	*function++ = dfp_fnt_JMPR;						/* used to be fnt_WLSB */
	*function++ = dfp_fnt_LWTCI;
	*function++ = dfp_fnt_LSWCI;
	*function++ = dfp_fnt_LSW;

	/***** 0x20 - 0x2f *****/
	*function++ = dfp_fnt_DUP;
	*function++ = dfp_fnt_SetLocalGraphicState;
	*function++ = dfp_fnt_CLEAR;
	*function++ = dfp_fnt_SWAP;
	*function++ = dfp_fnt_DEPTH;
	*function++ = dfp_fnt_CINDEX;
	*function++ = dfp_fnt_MINDEX;
	*function++ = dfp_fnt_ALIGNPTS;
	*function++ = dfp_fnt_RAW;
	*function++ = dfp_fnt_UTP;
	*function++ = dfp_fnt_LOOPCALL;
	*function++ = dfp_fnt_CALL;
	*function++ = dfp_fnt_FDEF;
	*function++ = dfp_fnt_IllegalInstruction; 		/* fnt_ENDF; used for FDEF and IDEF */
	*function++ = dfp_fnt_MDAP;
	*function++ = dfp_fnt_MDAP;


	/***** 0x30 - 0x3f *****/
	*function++ = dfp_fnt_IUP;
	*function++ = dfp_fnt_IUP;
	*function++ = dfp_fnt_SHP;
	*function++ = dfp_fnt_SHP;
	*function++ = dfp_fnt_SHC;
	*function++ = dfp_fnt_SHC;
	*function++ = dfp_fnt_SHE;
	*function++ = dfp_fnt_SHE;
	*function++ = dfp_fnt_SHPIX;
	*function++ = dfp_fnt_IP;
	*function++ = dfp_fnt_MSIRP;
	*function++ = dfp_fnt_MSIRP;
	*function++ = dfp_fnt_ALIGNRP;
	*function++ = dfp_fnt_SetRoundState;	/* fnt_RTDG; */
	*function++ = dfp_fnt_MIAP;
	*function++ = dfp_fnt_MIAP;

	/***** 0x40 - 0x4f *****/
	*function++ = dfp_fnt_NPUSHB;
	*function++ = dfp_fnt_NPUSHW;
	*function++ = dfp_fnt_WS;
	*function++ = dfp_fnt_RS;
	*function++ = dfp_fnt_WCVT;
	*function++ = dfp_fnt_RCVT;
	*function++ = dfp_fnt_RC;
	*function++ = dfp_fnt_RC;
	*function++ = dfp_fnt_WC;
	*function++ = dfp_fnt_MD;
	*function++ = dfp_fnt_MD;
	*function++ = dfp_fnt_MPPEM;
	*function++ = dfp_fnt_MPS;
	*function++ = dfp_fnt_FLIPON;
	*function++ = dfp_fnt_FLIPOFF;
	*function++ = dfp_fnt_DEBUG;

	/***** 0x50 - 0x5f *****/
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_LT; */
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_LTEQ; */
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_GT; */
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_GTEQ; */
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_EQ; */
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_NEQ; */
	*function++ = dfp_fnt_UnaryOperand;		/* fnt_ODD; */
	*function++ = dfp_fnt_UnaryOperand;		/* fnt_EVEN; */
	*function++ = dfp_fnt_IF;
	*function++ = dfp_fnt_EIF;		/* should this guy be an illegal instruction??? */
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_AND; */
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_OR; */
	*function++ = dfp_fnt_UnaryOperand;		/* fnt_NOT; */
	*function++ = dfp_fnt_DELTAP1;
	*function++ = dfp_fnt_SDB;
	*function++ = dfp_fnt_SDS;

	/***** 0x60 - 0x6f *****/
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_ADD; */
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_SUB; */
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_DIV;  */
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_MUL; */
	*function++ = dfp_fnt_UnaryOperand;		/* fnt_ABS; */
	*function++ = dfp_fnt_UnaryOperand;		/* fnt_NEG; */
	*function++ = dfp_fnt_UnaryOperand;		/* fnt_FLOOR; */
	*function++ = dfp_fnt_UnaryOperand;		/* fnt_CEILING */
	*function++ = dfp_fnt_ROUND;
	*function++ = dfp_fnt_ROUND;
	*function++ = dfp_fnt_ROUND;
	*function++ = dfp_fnt_ROUND;
	*function++ = dfp_fnt_NROUND;
	*function++ = dfp_fnt_NROUND;
	*function++ = dfp_fnt_NROUND;
	*function++ = dfp_fnt_NROUND;

	/***** 0x70 - 0x7f *****/
	*function++ = dfp_fnt_WCVTFOD;
	*function++ = dfp_fnt_DELTAP2;
	*function++ = dfp_fnt_DELTAP3;
	*function++ = dfp_fnt_DELTAC1;
	*function++ = dfp_fnt_DELTAC2;
	*function++ = dfp_fnt_DELTAC3;
	*function++ = dfp_fnt_SROUND;
	*function++ = dfp_fnt_S45ROUND;
	*function++ = dfp_fnt_JROT;
	*function++ = dfp_fnt_JROF;
 	*function++ = dfp_fnt_SetRoundState;	/* fnt_ROFF; */
	*function++ = dfp_fnt_IllegalInstruction;/* 0x7b reserved for data compression */
	*function++ = dfp_fnt_SetRoundState;	/* fnt_RUTG; */
	*function++ = dfp_fnt_SetRoundState;	/* fnt_RDTG; */
	*function++ = dfp_fnt_SANGW;
	*function++ = dfp_fnt_AA;

	/***** 0x80 - 0x8d *****/
	*function++ = dfp_fnt_FLIPPT;
	*function++ = dfp_fnt_FLIPRGON;
	*function++ = dfp_fnt_FLIPRGOFF;
	*function++ = dfp_fnt_IDefPatch;		/* fnt_RMVT, this space for rent */
	*function++ = dfp_fnt_IDefPatch;		/* fnt_WMVT, this space for rent */
	*function++ = dfp_fnt_SCANCTRL;
	*function++ = dfp_fnt_SDPVTL;
	*function++ = dfp_fnt_SDPVTL;
	*function++ = dfp_fnt_GETINFO;			/* <7> */
	*function++ = dfp_fnt_IDEF;
	*function++ = dfp_fnt_ROTATE;
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_MAX; */
	*function++ = dfp_fnt_BinaryOperand;	/* fnt_MIN; */
	*function++ = dfp_fnt_SCANTYPE;			/* <7> */
	*function++ = dfp_fnt_INSTCTRL;			/* <13> */

	/***** 0x8f - 0xaf *****/
	for ( i = 32; i >= 0; --i )
	    *function++ = dfp_fnt_IDefPatch;		/* potentially fnt_IllegalInstruction  <4> */

	/***** 0xb0 - 0xb7 *****/
	for ( i = 7; i >= 0; --i )
	    *function++ = dfp_fnt_PUSHB;

	/***** 0xb8 - 0xbf *****/
	for ( i = 7; i >= 0; --i )
	    *function++ = dfp_fnt_PUSHW;

	/***** 0xc0 - 0xdf *****/
	for ( i = 31; i >= 0; --i )
	    *function++ = dfp_fnt_MDRP;

	/***** 0xe0 - 0xff *****/
	for ( i = 31; i >= 0; --i )
	    *function++ = dfp_fnt_MIRP;
}


/*
 *	Init routine, to be called at boot time.
 *	globalGS->function has to be set up when this function is called.
 *	rewrite initialization from p[] to *p++							<3>
 *	restructure fnt_AngleInfo into fnt_FractPoint and int16			<3>
 *
 *	Only gs->function is valid at this time.
 */
void fnt_Init (globalGS)
  fnt_GlobalGraphicStateType* globalGS;
{
	fnt_DefaultJumpTable( globalGS->function );

	/* These 20 x and y pairs are all stepping patterns that have a repetition period of less than 9 pixels.
	   They are sorted in order according to increasing period (distance). The period is expressed in
	   	pixels * fnt_pixelSize, and is a simple Euclidian distance. The x and y values are Fracts and they are
		at a 90 degree angle to the stepping pattern. Only stepping patterns for the first octant are stored.
		This means that we can derrive (20-1) * 8 = 152 different angles from this data base */

	globalGS->anglePoint = (fnt_FractPoint *)((char*)globalGS->function + MAXBYTE_INSTRUCTIONS * sizeof(voidFunc));
	globalGS->angleDistance = (int16*)(globalGS->anglePoint + MAXANGLES);
	{
		register Fract* coord = (Fract*)globalGS->anglePoint;
		register int16* dist = globalGS->angleDistance;

		/**		 x						 y						d	**/

		*coord++ = 0L;			*coord++ = 1073741824L;	*dist++ = 64;
		*coord++ = -759250125L; *coord++ = 759250125L;	*dist++ = 91;
		*coord++ = -480191942L; *coord++ = 960383883L;	*dist++ = 143;
		*coord++ = -339546978L; *coord++ = 1018640935L;	*dist++ = 202;
		*coord++ = -595604800L; *coord++ = 893407201L;	*dist++ = 231;
		*coord++ = -260420644L; *coord++ = 1041682578L;	*dist++ = 264;
		*coord++ = -644245094L; *coord++ = 858993459L;	*dist++ = 320;
		*coord++ = -210578097L;	*coord++ = 1052890483L;	*dist++ = 326;
		*coord++ = -398777702L; *coord++ = 996944256L;	*dist++ = 345;
		*coord++ = -552435611L; *coord++ = 920726018L;	*dist++ = 373;
		*coord++ = -176522068L; *coord++ = 1059132411L;	*dist++ = 389;
		*coord++ = -670761200L; *coord++ = 838451500L;	*dist++ = 410;
		*coord++ = -151850025L; *coord++ = 1062950175L;	*dist++ = 453;
		*coord++ = -294979565L; *coord++ = 1032428477L;	*dist++ = 466;
		*coord++ = -422967626L; *coord++ = 986924461L;	*dist++ = 487;
		*coord++ = -687392765L; *coord++ = 824871318L;	*dist++ = 500;
		*coord++ = -532725129L; *coord++ = 932268975L;	*dist++ = 516;
		*coord++ = -133181282L; *coord++ = 1065450257L;	*dist++ = 516;
		*coord++ = -377015925L; *coord++ = 1005375799L;	*dist++ = 547;
		*coord   = -624099758L; *coord   = 873739662L;	*dist   = 551;
	}
}

/* END OF fnt.c */

#pragma Code()
