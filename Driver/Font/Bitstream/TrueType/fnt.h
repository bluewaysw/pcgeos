/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/fnt.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: fnt.h,v 1.1 97/04/18 11:45:20 newdeal Exp $
 *
 ***********************************************************************/

/********************* Revision Control Information **********************************
*                                                                                    *
*     $Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/fnt.h,v 1.1 97/04/18 11:45:20 newdeal Exp $                                                                       *
*                                                                                    *
*     $Log:	fnt.h,v $
 * Revision 1.1  97/04/18  11:45:20  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:08  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:14:50  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:08:24  roberte
 * Release
 * 
 * Revision 6.3  92/11/19  15:45:51  roberte
 * Release
 * 
 * Revision 6.2  92/04/30  11:22:06  leeann
 * take out non-Ascii bytes
 * 
 * Revision 6.1  91/08/14  16:45:08  mark
 * Release
 * 
 * Revision 5.1  91/08/07  12:26:20  mark
 * Release
 * 
 * Revision 4.3  91/08/07  11:50:12  mark
 * remove rcsstatus string
 * 
 * Revision 4.2  91/08/07  11:39:15  mark
 * added RCS control strings
 * 
*************************************************************************************/

/*
	File:		fnt.h

	Contains:	xxx put contents here (or delete the whole line) xxx

	Written by:	xxx put name of writer here (or delete the whole line) xxx

	Copyright:	) 1987-1990 by Apple Computer, Inc., all rights reserved.

	Change History (most recent first):

		 <6>	 12/5/90	MR		Remove unneeded leftSideBearing[in,out] and advanceWidth[in,out]
									fields. [rb]
		 <5>	11/27/90	MR		Better typedefs for function pointers [rb]
		 <4>	11/16/90	MR		More debugging code [rb]
		 <3>	 11/5/90	MR		Change globalGS.ppemDot6 to globalGS.fpem. InstrPtrs and
									curvePtr are now all uint8*. [rb]
		 <2>	10/20/90	MR		Restore changes since project died.  Converting to 2.14 vectors,
									smart math routines. [rb]
		<0+>	10/19/90	MR		Restore changes since project died.  Converting to 2.14 vectors,
									smart math routines.
		<10>	 7/26/90	MR		rearrange local graphic state, remove unused parBlockPtr
		 <9>	 7/18/90	MR		change loop variable from long to short, and other Ansi-changes
		 <8>	 7/13/90	MR		Prototypes for function pointers
		 <5>	  6/4/90	MR		Remove MVT
		 <4>	  5/3/90	RB		replaced dropoutcontrol with scancontrolin and scancontrol out
									in global graphics state
		 <3>	 3/20/90	CL		fields for multiple preprograms fields for ppemDot6 and
									pointSizeDot6 changed SROUND to take D/2 as argument
		 <2>	 2/27/90	CL		Added DSPVTL[] instruction.  Dropoutcontrol scanconverter and
									SCANCTRL[] instruction
	   <3.1>	11/14/89	CEL		Fixed two small bugs/feature in RTHG, and RUTG. Added SROUND &
									S45ROUND.
	   <3.0>	 8/28/89	sjk		Cleanup and one transformation bugfix
	   <2.2>	 8/14/89	sjk		1 point contours now OK
	   <2.1>	  8/8/89	sjk		Improved encryption handling
	   <2.0>	  8/2/89	sjk		Just fixed EASE comment
	   <1.7>	  8/1/89	sjk		Added composites and encryption. Plus some enhancementsI
	   <1.6>	 6/13/89	SJK		Comment
	   <1.5>	  6/2/89	CEL		16.16 scaling of metrics, minimum recommended ppem, point size 0
									bug, correct transformed integralized ppem behavior, pretty much
									so
	   <1.4>	 5/26/89	CEL		EASE messed up on RcS comments
	  <%1.3>	 5/26/89	CEL		Integrated the new Font Scaler 1.0 into Spline Fonts

	To Do:
*/
/*	rwb 4/24/90 Replaced dropoutControl with scanControlIn and scanControlOut in
		global graphics state. 
		<3+>	 3/20/90	mrr		Added support for IDEFs.  Made funcDefs long aligned
									by storing int16 length instead of int32 end.
*/

#define fnt_pixelSize 0x40L
#define fnt_pixelShift 6

#define MAXBYTE_INSTRUCTIONS 256

#define VECTORTYPE					ShortFrac
#define ONEVECTOR					ONESHORTFRAC
#define VECTORMUL(value, component)	ShortFracMul(value, component)
#define VECTORDOT(a,b)				ShortFracDot(a,b)
#define VECTORMULDIV(a,b,c)			ShortMulDiv(a,b,c)
#define ONESIXTEENTHVECTOR			((ONEVECTOR) >> 4)

typedef struct VECTOR {
	VECTORTYPE x;
	VECTORTYPE y;
} VECTOR;

typedef struct {
    F26Dot6  *x; /* The Points the Interpreter modifies */
    F26Dot6  *y; /* The Points the Interpreter modifies */
    F26Dot6  *ox; /* Old Points */
    F26Dot6  *oy; /* Old Points */
    F26Dot6  *oox; /* Old Unscaled Points, really ints */
    F26Dot6  *ooy; /* Old Unscaled Points, really ints */
	uint8 *onCurve; /* indicates if a point is on or off the curve */
	int16 nc;  /* Number of contours */
	int16 padWord;	/* <4> */
	int16 *sp;  /* Start points */
	int16 *ep;  /* End points */
	uint8 *f;  /* Internal flags, one byte for every point */
} fnt_ElementType;

typedef struct {
    int32 start;		/* offset to first instruction */
	uint16 length;		/* number of bytes to execute <4> */
	uint16 pgmIndex;	/* index to appropriate preprogram for this func (0..1) */
} fnt_funcDef;

/* <4> pretty much the same as fnt_funcDef, with the addition of opCode */
typedef struct {
	int32 start;
	uint16 length;
	uint8  pgmIndex;
	uint8  opCode;
} fnt_instrDef;

typedef struct {
	Fract x;
	Fract y;
} fnt_FractPoint;

/***************** This is stored as FractPoint[] and distance[]
typedef struct {
	Fract x, y;
	int16 distance;
} fnt_AngleInfo;
*******************/

/*
typedef void (*FntFunc)(struct fnt_LocalGraphicStateType*);
typedef void (*InterpreterFunc)(struct fnt_LocalGraphicStateType*, uint8*, uint8*);
typedef void (*FntMoveFunc)(struct fnt_LocalGraphicStateType*, fnt_ElementType*, ArrayIndex, F26Dot6);
typedef F26Dot6 (*FntRoundFunc)(F26Dot6 xin, F26Dot6 engine, struct fnt_LocalGraphicStateType* gs);
typedef F26Dot6 (*FntProjFunc)(struct fnt_LocalGraphicStateType*, F26Dot6 x, F26Dot6 y);
*/
typedef void (*FntFunc)();
typedef void (*InterpreterFunc)();
typedef void (*FntMoveFunc)();
typedef F26Dot6 (*FntRoundFunc)();
typedef F26Dot6 (*FntProjFunc)();

typedef struct {

/* PARAMETERS CHANGEABLE BY TT INSTRUCTIONS */
    F26Dot6 wTCI;     				/* width table cut in */
	F26Dot6 sWCI;     				/* single width cut in */
	F26Dot6 scaledSW; 				/* scaled single width */
	int32 scanControl;				/* controls kind and when of dropout control */
	int32 instructControl;			/* controls gridfitting and default setting */
	
	F26Dot6 minimumDistance;		/* moved from local gs  7/1/90  */
	FntRoundFunc RoundValue;		/*								*/
	F26Dot6 	periodMask; 			/* ~(gs->period-1) 				*/
	Fract	period45;				/*								*/
	int16	period;					/* for power of 2 periods 		*/
	int16 	phase;					/*								*/
	int16 	threshold;				/* moved from local gs  7/1/90  */
	
	int16 deltaBase;
	int16 deltaShift;
	int16 angleWeight;
	int16 sW;         				/* single width, expressed in the same units as the character */
	int8 autoFlip;   				/* The auto flip Boolean */
	int8 pad;	
} fnt_ParameterBlock;				/* this is exported to client */

#define MAXANGLES		20
#define ROTATEDGLYPH	0x100
#define STRETCHEDGLYPH  0x200
#define NOGRIDFITFLAG	1
#define DEFAULTFLAG		2

typedef enum {
	PREPROGRAM,
	FONTPROGRAM,
	MAXPREPROGRAMS
} fnt_ProgramIndex;

typedef struct fnt_GlobalGraphicStateType {
	F26Dot6* stackBase; 			/* the stack area */
	F26Dot6* store; 				/* the storage area */
	F26Dot6* controlValueTable; 	/* the control value table */
	
	uint16	pixelsPerEm; 			/* number of pixels per em as an integer */
	uint16	pointSize; 				/* the requested point size as an integer */
	Fixed	fpem;					/* fractional pixels per em    <3> */
	F26Dot6 engine[4]; 				/* Engine Characteristics */
	
	fnt_ParameterBlock defaultParBlock;	/* variables settable by TT instructions */
	fnt_ParameterBlock localParBlock;

	/* Only the above is exported to Client throught FontScaler.h */

/* VARIABLES NOT DIRECTLY MANIPULABLE BY TT INSTRUCTIONS  */
	
    FntFunc* function; 				/* pointer to instruction definition area */
	fnt_funcDef* funcDef; 			/* function Definitions identifiers */
	fnt_instrDef* instrDef;			/* instruction Definitions identifiers */
/*  F26Dot6	(*ScaleFunc)(struct fnt_GlobalGraphicStateType*, F26Dot6); 			/* Call back function to do scaling */
    F26Dot6 (*ScaleFunc)();         /* Call back function to do scaling */
	uint8* pgmList[MAXPREPROGRAMS];	/* each program ptr is in here */
	
    /* These are parameters used by the call back function */
	Fixed fixedScale; 			/* fixed sc aling factor */
	int32  nScale; 				/* numerator required to scale points to the right size*/
	int32  dScale; 				/* denumerator required to scale points to the right size */
	int16  shift; 				/* 2log of dScale */
	int8   identityTransformation; 	/* true/false  (does not mean identity from a global sense) */
	int8   non90DegreeTransformation; /* bit 0 is 1 if non-90 degree, bit 1 is 1 if x scale doesn't equal y scale */
	Fixed  xStretch; 			/* Tweaking for glyphs under transformational stress <4> */
	Fixed  yStretch;
	
	/** these two together make fnt_AngleInfo **/
	fnt_FractPoint*	anglePoint;
	int16*			angleDistance;

    int8 init; 						/* executing preprogram ?? */
	uint8 pgmIndex;					/* which preprogram is current */
	LoopCount instrDefCount;		/* number of currently defined IDefs */

#ifdef DEBUG
	sfnt_maxProfileTable*	maxp;
	uint16					cvtCount;
	uint16					glyphIndex;
	boolean					glyphProgram;
#endif

} fnt_GlobalGraphicStateType;

/* typedef F26Dot6 (*GlobalGSScaleFunc)(fnt_GlobalGraphicStateType*, F26Dot6); */
typedef F26Dot6 (*GlobalGSScaleFunc)();

/* 
 * This is the local graphics state  
 */
typedef struct fnt_LocalGraphicStateType {
	fnt_ElementType *CE0, *CE1, *CE2; 	/* The character element pointers */
	VECTOR proj; 						/* Projection Vector */
	VECTOR free;						/* Freedom Vector */
	VECTOR oldProj; 					/* Old Projection Vector */
	F26Dot6 *stackPointer;

	uint8 *insPtr; 						/* Pointer to the instruction we are about to execute */
    fnt_ElementType *elements;
    fnt_GlobalGraphicStateType *globalGS;
	FntFunc	TraceFunc;

    ArrayIndex Pt0, Pt1, Pt2; 			/* The internal reference points */
	int16   roundToGrid;			
	LoopCount loop; 					/* The loop variable */	
	uint8 opCode; 						/* The instruction we are executing */
	uint8 padByte;
	int16 padWord;

	/* Above is exported to client in FontScaler.h */

	VECTORTYPE pfProj; /* = pvx * fvx + pvy * fvy */

	FntMoveFunc MovePoint;
	FntProjFunc Project;
	FntProjFunc OldProject;
	InterpreterFunc Interpreter;
/*  F26Dot6 (*GetCVTEntry) (struct fnt_LocalGraphicStateType *gs, ArrayIndex n); */
/*  F26Dot6 (*GetSingleWidth) (struct fnt_LocalGraphicStateType *gs); */
    F26Dot6 (*GetCVTEntry) ();
    F26Dot6 (*GetSingleWidth) ();

	jmp_buf	env;		/* always be at the end, since it is unknown size */

} fnt_LocalGraphicStateType;

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
 *		local graphics state if TraceFunc is not null. The call is made just before
 *		every instruction is executed.
 *
 * Note: The stuff globalGS is pointing at must remain intact
 *       between calls to this function.
 */
/* extern int fnt_Execute(fnt_ElementType *elements, uint8 *ptr, uint8 *eptr,
                          fnt_GlobalGraphicStateType *globalGS, voidFunc TraceFunc); */
extern int fnt_Execute();
/*
 * Init routine, to be called at boot time.
 */
/* extern void fnt_Init(fnt_GlobalGraphicStateType *globalGS); */
extern void fnt_Init();
/* Export internal rounding routines so globalGraphicsState->defaultParBlock.RoundValue
 * can be set in fsglue.c
 */
/* extern F26Dot6 fnt_RoundToDoubleGrid(F26Dot6 xin, F26Dot6 engine, fnt_LocalGraphicStateType *gs); */
/* extern F26Dot6 fnt_RoundDownToGrid(F26Dot6 xin, F26Dot6 engine, fnt_LocalGraphicStateType *gs); */
/* extern F26Dot6 fnt_RoundUpToGrid(F26Dot6 xin, F26Dot6 engine, fnt_LocalGraphicStateType *gs); */
/* extern F26Dot6 fnt_RoundToGrid(F26Dot6 xin, F26Dot6 engine, fnt_LocalGraphicStateType *gs); */
/* extern F26Dot6 fnt_RoundToHalfGrid(F26Dot6 xin, F26Dot6 engine, fnt_LocalGraphicStateType *gs); */
/* extern F26Dot6 fnt_RoundOff(F26Dot6 xin, F26Dot6 engine, fnt_LocalGraphicStateType *gs); */
/* extern F26Dot6 fnt_SuperRound(F26Dot6 xin, F26Dot6 engine, fnt_LocalGraphicStateType *gs); */
/* extern F26Dot6 fnt_Super45Round(F26Dot6 xin, F26Dot6 engine, fnt_LocalGraphicStateType *gs); */
extern F26Dot6 fnt_RoundToDoubleGrid();
extern F26Dot6 fnt_RoundDownToGrid();
extern F26Dot6 fnt_RoundUpToGrid();
extern F26Dot6 fnt_RoundToGrid();
extern F26Dot6 fnt_RoundToHalfGrid();
extern F26Dot6 fnt_RoundOff();
extern F26Dot6 fnt_SuperRound();
extern F26Dot6 fnt_Super45Round();

