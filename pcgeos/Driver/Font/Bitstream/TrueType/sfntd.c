/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/sfntd.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: sfntd.c,v 1.1 97/04/18 11:45:24 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("TTSfntdCode")

/********************* Revision Control Information **********************************
*                                                                                    *
*     $Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/sfntd.c,v 1.1 97/04/18 11:45:24 newdeal Exp $                                                                       *
*                                                                                    *
*     $Log:	sfntd.c,v $
 * Revision 1.1  97/04/18  11:45:24  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:53  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:16:28  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:22:44  roberte
 * Release
 * 
 * Revision 6.14  93/03/09  13:07:28  roberte
 * Added cast of n to int.  Some compilers hated this line of code.
 * 
 * Revision 6.13  93/03/04  11:52:22  roberte
 * Added a cast for 3rd param in call to MapString4_16().
 * Added SWAPW macro in reference to mapping ptr for INTEL port.
 * 
 * Revision 6.12  93/01/25  16:50:26  roberte
 * Added essential casts in calls to fsg_SetUpElement() and fsg_IncrementElement() for (int32) params.
 * 
 * Revision 6.11  93/01/25  09:38:24  roberte
 * Employed PROTO macro for all function prototypes.
 * Added casting to sfnt_GetDataPtr() call for second formal param. Changed 3rd param to (int32) cast.
 * 
 * Revision 6.10  92/12/29  12:49:06  roberte
 * Now includes "spdo_prv.h" first.
 * 
 * Revision 6.9  92/12/15  14:13:58  roberte
 * Commented out #pragma
 * 
 * Revision 6.8  92/11/24  13:36:22  laurar
 * include fino.h
 * 
 * Revision 6.7  92/11/11  10:47:43  roberte
 * #ifdef'ed out great expanses of code if PCLETTO is defined.
 * 
 * Revision 6.6  92/11/10  11:04:44  roberte
 * Undid last stupid PCLETTO #ifdef INTEL!
 * 
 * Revision 6.5  92/11/10  10:45:06  roberte
 * Test reversing SWAPINC logic by defining INTEL if PCLETTO.
 * 
 * Revision 6.4  92/11/10  09:43:33  roberte
 * Corrected spelling of PCLETTO.
 * 
 * Revision 6.3  92/11/09  16:40:18  roberte
 * Added callback calls to tt_get_char_addr() in #ifdef PCLETTO blocks.
 * 
 * Revision 6.2  92/10/15  11:50:50  roberte
 * Changed all ifdef PROTOS_AVAIL statements to if PROTOS_AVAIL.
 * 
 * Revision 6.1  91/08/14  16:48:13  mark
 * Release
 * 
 * Revision 5.1  91/08/07  12:29:20  mark
 * Release
 * 
 * Revision 4.2  91/08/07  11:55:10  mark
 * add rcs control strings
 * 
*************************************************************************************/

#ifdef RCSSTATUS
static char rcsid[] = "$Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/sfntd.c,v 1.1 97/04/18 11:45:24 newdeal Exp $";
#endif

/*
	File:		sfnt.c

	Contains:	xxx put contents here (or delete the whole line) xxx

	Written by:	xxx put name of writer here (or delete the whole line) xxx

	Copyright:	(c) 1989-1990 by Apple Computer, Inc., all rights reserved.

	Change History (most recent first):

		 <6>	12/18/90	RB		Move ReleaseSfntFrag into block where table is defined. [mr]
		 <5>	12/11/90	MR		Support platform==-1 meaning this sfnt has no cmap, don't return
									an error.
		 <4>	11/16/90	MR		Fix bogus call to SWAPW in ReadSfnt for instructions after
									components. [rb]
		 <3>	 11/5/90	MR		Remove mac include files, clean up release macros. [rb]
		 <2>	10/20/90	MR		Removed unused tables in sfnt_Classify. [rb]
		<17>	 8/10/90	MR		Pass nil for textLength parameter to MapString2, checked in
									other files to their precious little system will BUILD.  Talk
									about touchy!
		<16>	 8/10/90	gbm		rolling out Mike's textLength change, because he hasn't checked
									in all the relevant files, and the build is BROKEN!
		<15>	 8/10/90	MR		Add textLength arg to MapString2
		<14>	 7/26/90	MR		don't include ToolUtils.h
		<13>	 7/23/90	MR		Change computeindex routines to call functins in MapString.c
		<12>	 7/18/90	MR		Add SWAPW macro for INTEL
		<11>	 7/13/90	MR		Lots of Ansi-C stuff, change behavior of ComputeMapping to take
									platform and script
		 <9>	 6/27/90	MR		Changes for modified format 4: range is now times two, loose pad
									word between first two arrays.  Eric Mader
		 <8>	 6/21/90	MR		Add calls to ReleaseSfntFrag
		 <7>	  6/5/90	MR		remove vector mapping functions
		 <6>	  6/4/90	MR		Remove MVT
		 <5>	  5/3/90	RB		simplified decryption.
		 <4>	 4/10/90	CL		Fixed mapping table routines for double byte codes.
		 <3>	 3/20/90	CL		Joe found bug in mappingtable format 6 Added vector mapping
									functions use pointer-loops in sfnt_UnfoldCurve, changed z from
									int32 to int16
		 <2>	 2/27/90	CL		New error code for missing but needed table. (0x1409 )	New
									CharToIndexMap Table format.
									Assume subtablenumber zero for old sfnt format.  Fixed
									transformed component bug.
	   <3.2>	11/14/89	CEL		Left Side Bearing should work right for any transformation. The
									phantom points are in, even for components in a composite glyph.
									They should also work for transformations. Device metric are
									passed out in the output data structure. This should also work
									with transformations. Another leftsidebearing along the advance
									width vector is also passed out. whatever the metrics are for
									the component at it's level. Instructions are legal in
									components. Instructions are legal in components. Glyph-length 0
									bug in sfnt.c is fixed. Now it is legal to pass in zero as the
									address of memory when a piece of the sfnt is requested by the
									scaler. If this happens the scaler will simply exit with an
									error code ! Fixed bug with instructions in components.
	   <3.1>	 9/27/89	CEL		Removed phantom points.
	   <3.0>	 8/28/89	sjk		Cleanup and one transformation bugfix
	   <2.2>	 8/14/89	sjk		1 point contours now OK
	   <2.1>	  8/8/89	sjk		Improved encryption handling
	   <2.0>	  8/2/89	sjk		Just fixed EASE comment
	   <1.5>	  8/1/89	sjk		Added composites and encryption. Plus some enhancementsI
	   <1.4>	 6/13/89	SJK		Comment
	   <1.3>	  6/2/89	CEL		16.16 scaling of metrics, minimum recommended ppem, point size 0
									bug, correct transformed integralized ppem behavior, pretty much
									so
	   <1.2>	 5/26/89	CEL		EASE messed up on RcS comments
	  <%1.1>	 5/26/89	CEL		Integrated the new Font Scaler 1.0 into Spline Fonts
	   <1.0>	 5/25/89	CEL		Integrated 1.0 Font scaler into Bass code for the first timeI

	To Do:
		<3+>	 3/20/90	mrr		Fixed mapping table routines for double byte codes.
									Added support for font program.
									Changed count from uint16 to int16 in vector char2index routines.
*/

#define BYTEREAD
 
#include <setjmp.h>

#include "spdo_prv.h"
#include "fino.h"
/** FontScaler's Includes **/
#include "fserror.h"
#include "fscdefs.h"
#include "fontmath.h"
#include "sfnt.h"
#include "fnt.h"
#include "sc.h"
#include "fontscal.h"
#include "fsglue.h"
#include "privsfnt.h"
#include "mapstrng.h"

/** SFNT Packed format **/
typedef struct {
	int16 		numberContours;
	int16 		*endPoints;				/** vector: indexes into x[], y[] **/
	int16 		numberInstructions;
	uint8  		*instructions;			/** vector **/
	uint8 		*flags;					/** vector **/
	sfnt_BBox	bbox;
} sfnt_PackedSplineFormat;


/* #define GetUnsignedByte( p ) *(((uint8  *)p)++) */
/* #define GetUnsignedByte( p ) ((uint8)(*p++)) */
#define GetUnsignedByte( p ) ((uint8)(*p++))

/** <4> **/
#define fsg_MxCopy(a, b)	(*(b) = *(a))


/* PRIVATE PROTOTYES */

int sfnt_UnfoldCurve PROTO((fsg_SplineKey *key, sfnt_PackedSplineFormat *charData, int32 *sizeOfInstructions, uint8 **instructionPtr, int32 length, int16 *elementCount));
void sfnt_Classify PROTO((fsg_SplineKey *key, sfnt_TableTag tag, int16 index));
void* sfnt_GetDataPtr PROTO((fsg_SplineKey *key, int32 offset, int32 length, sfnt_tableIndex n, boolean mustHaveTable));
uint16 sfnt_ComputeUnkownIndex PROTO((fsg_SplineKey *key, uint16 charCode));
#ifndef PCLETTO
uint16 sfnt_ComputeIndex0 PROTO((fsg_SplineKey *key, uint16 charCode));
uint16 sfnt_ComputeIndex2 PROTO((fsg_SplineKey *key, uint16 charCode));
uint16 sfnt_ComputeIndex4 PROTO((fsg_SplineKey *key, uint16 charCode));
uint16 sfnt_ComputeIndex6 PROTO((fsg_SplineKey *key, uint16 charCode));
void sfnt_GetGlyphLocation PROTO(( fsg_SplineKey* key, uint16 gIndex, int32* offset, int32* length ));
#endif /* PCLETTO */

#ifdef SEGMENT_LINK
/* #pragma segment SFNT_C */
#endif

#ifdef DEBUG
static  char  *debug1;
static  int16  *debug2;
static  int32  *debug3;
#endif

static uint16 (*dfp_sfnt_ComputeUnkownIndex)() = &sfnt_ComputeUnkownIndex;
static uint16 (*dfp_sfnt_ComputeIndex0)() = &sfnt_ComputeIndex0;
static uint16 (*dfp_sfnt_ComputeIndex2)() = &sfnt_ComputeIndex2;
static uint16 (*dfp_sfnt_ComputeIndex4)() = &sfnt_ComputeIndex4;
static uint16 (*dfp_sfnt_ComputeIndex6)() = &sfnt_ComputeIndex6;
#define PCFM ProcCallFixedOrMovable_pascal


/*								
 *
 *	sfnt_UnfoldCurve			<3>
 *
 *	ERROR:	return NON-ZERO
 *
 */
static int sfnt_UnfoldCurve (key, charData, sizeOfInstructions,
                             instructionPtr, length, elementCount)
  fsg_SplineKey* key;
  sfnt_PackedSplineFormat* charData;
  int32* sizeOfInstructions;
  uint8** instructionPtr;
  int32 length;
  int16* elementCount;
{
	register int z;
	register uint8 flag, *byteP, *byteP2;
	register int8 *p;
	register F26Dot6* longP;
	fnt_ElementType *elementPtr;
	int numPoints;

	elementPtr	= &(key->elementInfoRec.interpreterElements[GLYPHELEMENT]);

	if ( *elementCount == GLYPHELEMENT ) {
		key->totalContours = 0;
 		fsg_SetUpElement( key, (int32)GLYPHELEMENT );
	} else {
		/*                                       # of points in previous component */
		fsg_IncrementElement( key, (int32)GLYPHELEMENT, (int32)key->numberOfRealPointsInComponent, (int32)elementPtr->nc );
	}
	key->totalComponents = *elementCount;
	
	(*elementCount)++;
	key->glyphLength = length;
	if ( length <= 0 ) {
		elementPtr->nc = 1;
		key->totalContours += 1;
		
		elementPtr->sp[0] = 0;
		elementPtr->ep[0] = 0;
		
		*sizeOfInstructions = 0;
		
		elementPtr->onCurve[0] = ONCURVE;
		elementPtr->oox[0] = 0;
		elementPtr->ooy[0] = 0;
		return NO_ERR; /***************** exit here ! *****************/
	}

	elementPtr->nc = charData->numberContours;
	z = (int)elementPtr->nc;
	key->totalContours += z;
	if ( z < 0 || z > (int)SWAPW(key->maxProfile.maxContours) )
		return CONTOUR_DATA_ERR;

	{	/* <4> */
		register int16* sp = elementPtr->sp;
		register int16* ep = elementPtr->ep;
		int16* charDataEP = charData->endPoints;
		register LoopCount i;
		*sp++ = 0;
		*ep = SWAPWINC(charDataEP);
		for (i = z - 2; i >= 0; --i)
		{
			*sp++ = *ep++ + 1;
			*ep = SWAPWINC(charDataEP);
		}
	}

	numPoints = elementPtr->ep[elementPtr->nc - 1] + 1;
	key->numberOfRealPointsInComponent = (uint16)numPoints;
	if (numPoints < 0 || numPoints > (int)SWAPW(key->maxProfile.maxPoints))
		return POINTS_DATA_ERR;

	*sizeOfInstructions = charData->numberInstructions;
	z = (int)charData->numberInstructions;
	
	if ( z < 0 || z > (int)SWAPW(key->maxProfile.maxSizeOfInstructions) )
		return INSTRUCTION_SIZE_ERR;

	*instructionPtr	= charData->instructions;
	
	/* Do flags */
	p = (int8*)charData->flags;
	byteP = elementPtr->onCurve;
	byteP2 = byteP + numPoints;			/* only need to set this guy once */
	while (byteP < byteP2)
	{
		*byteP++ = flag = GetUnsignedByte( p );
		if ( flag & REPEAT_FLAGS ) {
			LoopCount count = GetUnsignedByte( p );
			for (--count; count >= 0; --count)
				*byteP++ = flag;
		}
	}

	/* Do X first */
	z = 0;
	byteP = elementPtr->onCurve;
	longP = elementPtr->oox;
	while (byteP < byteP2)
	{
		if ( (flag = *byteP++) & XSHORT ) {
			if ( flag & SHORT_X_IS_POS )
				z += GetUnsignedByte( p );
			else
				z -= GetUnsignedByte( p );
		} else if ( !(flag & NEXT_X_IS_ZERO) ) { /* This means we have a int32 (2 byte) vector */
#ifdef BYTEREAD
			z += (int16)(*p++) << 8;
			z += (uint8)*p++;
#else
			z += *((int16 *)p); p += sizeof( int16 );
#endif
		}
		*longP++ = (F26Dot6)z;
	}

	/* Now Do Y */
	z = 0;
	byteP = elementPtr->onCurve;
	longP = elementPtr->ooy;
	while (byteP < byteP2)
	{
		if ( (flag = *byteP) & YSHORT ) {
			if ( flag & SHORT_Y_IS_POS )
				z += GetUnsignedByte( p );
			else
				z -= GetUnsignedByte( p );
		} else if ( !(flag & NEXT_Y_IS_ZERO) ) { /* This means we have a int32 (2 byte) vector */
#ifdef BYTEREAD
			z += (int16)(*p++) << 8;
			z += (uint8)*p++;
#else
			z += *((int16 *)p); p += sizeof( int16 );
#endif
		}
		*longP++ = (F26Dot6)z;
	
		*byteP++ = flag & (uint8)ONCURVE; /* Filter out unwanted stuff */
	}
	if ( !(key->compFlags & NON_OVERLAPPING) ) {
		elementPtr->onCurve[0] |= OVERLAP;
	}
	
	return NO_ERR;
}


/*
 * Internal routine		(make this an array and do a look up?)
 */
static void sfnt_Classify (key, tag, index)
  register fsg_SplineKey *key;
  register sfnt_TableTag tag;
  int16 index;
{
#if 1
    if (tag == (long int)tag_FontHeader)
        {
		key->offsetTableMap[sfnt_fontHeader] = index;
		        }
	else if (tag == (long int)tag_HoriHeader)
        {
		key->offsetTableMap[sfnt_horiHeader] = index;
		        }
	else if (tag == (long int)tag_IndexToLoc)
        {
		key->offsetTableMap[sfnt_indexToLoc] = index;
		        }
	else if (tag == (long int)tag_MaxProfile)
        {
		key->offsetTableMap[sfnt_maxProfile] = index;
		        }
	else if (tag == (long int)tag_ControlValue)
        {
		key->offsetTableMap[sfnt_controlValue] = index;
		        }
	else if (tag == (long int)tag_PreProgram)
        {
		key->offsetTableMap[sfnt_preProgram] = index;
		        }
	else if (tag == (long int)tag_GlyphData)
        {
		key->offsetTableMap[sfnt_glyphData] = index;
		        }
	else if (tag == (long int)tag_HorizontalMetrics)
        {
		key->offsetTableMap[sfnt_horizontalMetrics] = index;
		        }
	else if (tag == (long int)tag_CharToIndexMap)
        {
		key->offsetTableMap[sfnt_charToIndexMap] = index;
		        }
	else if (tag == (long int)tag_FontProgram)
        {
		key->offsetTableMap[sfnt_fontProgram] = index;		/* <4> */
		        }
#else
	switch ( tag ) {
	
	case tag_FontHeader:
		key->offsetTableMap[sfnt_fontHeader] = index;
		break;
	case tag_HoriHeader:
		key->offsetTableMap[sfnt_horiHeader] = index;
		break;
	case tag_IndexToLoc:
		key->offsetTableMap[sfnt_indexToLoc] = index;
		break;
	case tag_MaxProfile:
		key->offsetTableMap[sfnt_maxProfile] = index;
		break;
	case tag_ControlValue:
		key->offsetTableMap[sfnt_controlValue] = index;
		break;
	case tag_PreProgram:
		key->offsetTableMap[sfnt_preProgram] = index;
		break;
	case tag_GlyphData:
		key->offsetTableMap[sfnt_glyphData] = index;
		break;
	case tag_HorizontalMetrics:
		key->offsetTableMap[sfnt_horizontalMetrics] = index;
		break;
	case tag_CharToIndexMap:
		key->offsetTableMap[sfnt_charToIndexMap] = index;
		break;
	case tag_FontProgram:
		key->offsetTableMap[sfnt_fontProgram] = index;		/* <4> */
		break;
	}
#endif

}


/*
 * Creates mapping for finding offset table		<4>
 */
void sfnt_DoOffsetTableMap (key)
  register fsg_SplineKey *key;
{
	register int16 i;

	{
		register int16* table = key->offsetTableMap;
        i = (int16)sfnt_NUMTABLEINDEX; i--;
		for ( ; i >= 0; --i )
			*table++ = -1; /* Initialize */
	}
	{
		uint16 last = key->sfntDirectory->numOffsets - 1;
		register sfnt_DirectoryEntry* dir = &key->sfntDirectory->table[last];
		for ( i = last; i >= 0; --i )
		{
			sfnt_Classify( key, dir->tag, i );
			--dir;
		}
	}
}


/*
 * Returns offset and length for table n	<4>
 */
void sfnt_GetOffsetAndLength (key, offsetT, lengthT, n)
  register fsg_SplineKey *key;
  int32 *offsetT;
  unsigned *lengthT;
  register sfnt_tableIndex n;
{
	register ArrayIndex tableNumber = key->offsetTableMap[(int)n];
	if ( tableNumber >= 0 )
	{
		sfnt_DirectoryEntry* dir = &key->sfntDirectory->table[tableNumber];
		*lengthT = (unsigned)dir->length;
		*offsetT = dir->offset;
	} else {
		*lengthT = 0; *offsetT = 0; /* missing table */
	}
}


/*
 * Use this when the whole table is neded.
 *
 * n is the table number.
 */
void* sfnt_GetTablePtr (key, n, mustHaveTable)
  register fsg_SplineKey *key;
  register sfnt_tableIndex n;
  register boolean mustHaveTable;
{
	return sfnt_GetDataPtr( key, (int32)0, (int32)-1, n, mustHaveTable );	/* 0, -1 means give me whole table */
}


/*
 * Use this function when only part of the table is needed.
 *
 * n is the table number.
 * offset is within table.
 * length is length of data needed.
 * To get an entire table, pass length = -1		<4>
 */
static void* sfnt_GetDataPtr (key, offset, length, n, mustHaveTable)
  register fsg_SplineKey *key;
  register int32 offset;
  register int32 length;
  register sfnt_tableIndex n;
  register boolean mustHaveTable;
{
	int32 offsetT;
	unsigned lengthT;
	void* fragment;

	sfnt_GetOffsetAndLength( key, &offsetT, &lengthT, n );

	if ( lengthT ) {
		if (length == -1) length = lengthT;
		offset += offsetT;
/* FCALL */
		fragment = (void *)key->GetSfntFragmentPtr( key->clientID, offset, length );
		if ( fragment ) {
			return fragment;
		} else {
			longjmp( key->env, CLIENT_RETURNED_NULL ); /* Do a gracefull recovery  */
		}
	} else {
		if ( mustHaveTable )
			longjmp( key->env, MISSING_SFNT_TABLE ); /* Do a gracefull recovery  */
		else
			return 0;
	}
}


/*
 * This, is when we don't know what is going on
 */
static uint16 sfnt_ComputeUnkownIndex (key, charCode)
  fsg_SplineKey* key;
  uint16 charCode;
{
/* #pragma unused(key, charCode) */
	return 0;
}


#ifndef PCLETTO
/*
 * Byte Table Mapping 256->256			<4>
 */
static uint16 sfnt_ComputeIndex0 (key, charCode)
  register fsg_SplineKey *key;
  uint16 charCode;
{
	if (charCode & ~(255)) return 0;

	{
		uint8 *mappingPtr = (uint8*)sfnt_GetTablePtr( key, sfnt_charToIndexMap, true );
		register uint8* mapping = mappingPtr;
		uint16 glyph;
			
		mapping += key->mappOffset; /* Point at mapping table offset. */
		glyph = mapping[charCode];
		RELEASESFNTFRAG(key, mappingPtr);

		return glyph;
	}
}


/*
 * High byte mapping through table
 *
 * Useful for the national standards for Japanese, Chinese, and Korean characters.
 *
 * Dedicated in spirit and logic to Mark Davis and the International group.
 *
 *	Algorithm: (I think)
 *		First byte indexes into KeyOffset table.  If the offset is 0, keep going, else use second byte.
 *		That offset is from beginning of data into subHeader, which has 4 words per entry.
 *			entry, extent, delta, range
 *
 */
uint16 sfnt_ComputeIndex2 (key, charCode)
  fsg_SplineKey* key; uint16 charCode;
{
	void* mappingPtr = sfnt_GetTablePtr( key, sfnt_charToIndexMap, true );
	uint8* mapping = (uint8*)mappingPtr;
	uint16 index;
	
	mapping += key->mappOffset; /* Point at mapping table offset. */

	key->numberOfBytesTaken = MapString2((uint16*)mapping, (uint8*)&charCode, (int16*)&index, 1, 0);
	RELEASESFNTFRAG(key, mappingPtr);

	return index;
}


/*
 * Segment mapping to delta values, Yack.. !
 *
 * In memory of Peter Edberg. Initial code taken from code example supplied by Peter.
 */
uint16 sfnt_ComputeIndex4 (key, charCode)
  fsg_SplineKey *key;
  uint16 charCode;
{
	void* mappingPtr = sfnt_GetTablePtr( key, sfnt_charToIndexMap, true );
	uint8* mapping = (uint8*)mappingPtr;
	uint16 index;
	
	mapping += key->mappOffset; /* Point at mapping table offset. */

	MapString4_16((uint16*)mapping, &charCode, (int16*)&index, 1L);
	RELEASESFNTFRAG(key, mappingPtr);

	return index;
}


/*
 * Trimmed Table Mapping
 */
uint16 sfnt_ComputeIndex6 (key, charCode)
  fsg_SplineKey* key;
  uint16 charCode;
{
	void* mappingPtr = sfnt_GetTablePtr( key, sfnt_charToIndexMap, true );
	uint8* mapping = (uint8*)mappingPtr;
	uint16 index;
		
	mapping += key->mappOffset; /* Point at mapping table offset. */

	MapString6_16((uint16*)mapping, &charCode, (int16*)&index, 1);	
	RELEASESFNTFRAG(key, mappingPtr);

	return index;
}
#endif /* PCLETTO */


/*
 * Sets up our mapping function pointer.
 */
int sfnt_ComputeMapping (key, platformID, specificID)
  register fsg_SplineKey *key;
  uint16 platformID, specificID;
{
	int result = NO_ERR;

	key->numberOfBytesTaken = 2; /* Initialize */

	if (platformID == 0xffff)
		key->mappingF = dfp_sfnt_ComputeUnkownIndex;
#ifndef PCLETTO	
	else
	{
		sfnt_char2IndexDirectory *table= (sfnt_char2IndexDirectory*)sfnt_GetTablePtr( key, sfnt_charToIndexMap, true );
		uint8 *mapping = (uint8 *)table;
		register uint16 format = -1;
		register int16 i;
		int16 found = false;
		
		if ( table->version == 0 )
		{
			register sfnt_platformEntry* plat = table->platform;	/* <4> */
			for ( i = SWAPW(table->numTables)-1; i >= 0; --i )
			{
				if ( SWAPW(plat->platformID) == platformID && SWAPW(plat->specificID) == specificID)
				{
					found = true;
					key->mappOffset = SWAPL(plat->offset) + 6;	/* skip header */
					break;
				}
				++plat;
			}
		}
		
		if ( !found )
		{
			key->mappingF = dfp_sfnt_ComputeUnkownIndex;
			result = OUT_OF_RANGE_SUBTABLE;
		}
		else
		{
			mapping += key->mappOffset - 6;		/* back up for header */
			format = SWAPW(*(uint16 *)mapping);
			
			switch ( format ) {
			case 0:
				key->mappingF = dfp_sfnt_ComputeIndex0;
				break;
			case 2:
				key->mappingF = dfp_sfnt_ComputeIndex2;
				break;
			case 4:
				key->mappingF = dfp_sfnt_ComputeIndex4;
				break;
			case 6:
				key->mappingF = dfp_sfnt_ComputeIndex6;
				break;
			default:
				key->mappingF = dfp_sfnt_ComputeUnkownIndex;
				result = UNKNOWN_CMAP_FORMAT;
				break;
			}
		}
		RELEASESFNTFRAG(key, table);
	}
#endif /* PCLETTO */
	return result;
}


/*
 *
 */
void sfnt_ReadSFNTMetrics (key, glyphIndex)
  fsg_SplineKey* key;
  register uint16 glyphIndex;
{
	register sfnt_HorizontalMetrics		*horizMetricPtr;
	register uint16						numberOf_LongHorMetrics = key->numberOf_LongHorMetrics;

	horizMetricPtr 	= (sfnt_HorizontalMetrics *)sfnt_GetTablePtr( key, sfnt_horizontalMetrics, true );

	if ( glyphIndex < numberOf_LongHorMetrics ) {
		key->nonScaledAW  	= SWAPW(horizMetricPtr[glyphIndex].advanceWidth);
		key->nonScaledLSB 	= SWAPW(horizMetricPtr[glyphIndex].leftSideBearing);
	} else {
		int16 *lsb = (int16 *)&horizMetricPtr[numberOf_LongHorMetrics]; /* first entry after[AW,LSB] array */
		
		key->nonScaledLSB 	= SWAPW(lsb[glyphIndex - numberOf_LongHorMetrics]);
		key->nonScaledAW 	= SWAPW(horizMetricPtr[numberOf_LongHorMetrics-1].advanceWidth);
	}
	RELEASESFNTFRAG(key, horizMetricPtr);
}


#ifndef PCLETTO
static void sfnt_GetGlyphLocation (key, gIndex, offset, length)
  fsg_SplineKey* key;
  uint16 gIndex;
  int32 *offset, *length;
{
	sfnt_FontHeader* fontHead = (sfnt_FontHeader*)sfnt_GetTablePtr( key, sfnt_fontHeader, true );
	void* indexPtr = sfnt_GetTablePtr( key, sfnt_indexToLoc, true );

	if ( SWAPW(fontHead->indexToLocFormat) == SHORT_INDEX_TO_LOC_FORMAT )
	{
		register uint16 tmp;
		register uint16* shortIndexToLoc = (uint16*)indexPtr;
		shortIndexToLoc += gIndex;
		tmp = SWAPWINC(shortIndexToLoc);
		*offset = (int32)tmp << 1;
		*length = ((int32)SWAPW(*shortIndexToLoc) << 1) - *offset;
	}
	else
	{
		register uint32* longIndexToLoc = (uint32*)indexPtr;
		longIndexToLoc += gIndex;
		*offset = SWAPL(*longIndexToLoc);
		longIndexToLoc++;
		*length = SWAPL(*longIndexToLoc) - *offset;
	}
	RELEASESFNTFRAG(key, indexPtr);
	RELEASESFNTFRAG(key, fontHead);
}
#endif /* PCLETTO */


/*
 *	<4>
 */
int sfnt_ReadSFNT (key, elementCount, gIndex, useHints, traceFunc)
  register fsg_SplineKey *key;
  int16 *elementCount;
  register uint16 gIndex;
  boolean useHints;
  voidFunc traceFunc;
{
	int32 		sizeOfInstructions;
	uint8* 		instructionPtr; 
	int32		length, offset;
	int			result	= NO_ERR;
	int16*		shortP;
	void*		glyphDataPtr = 0;		/* to signal ReleaseSfntFrag if we never asked for it */
	sfnt_PackedSplineFormat charData;

	sfnt_ReadSFNTMetrics( key, gIndex );
#ifdef PCLETTO
	glyphDataPtr = tt_get_char_addr(gIndex, &length);
#else
	sfnt_GetGlyphLocation( key, gIndex, &offset, &length );
#endif
	if ( length > 0 )
	{
#ifndef PCLETTO
		glyphDataPtr = sfnt_GetDataPtr( key, offset, length, sfnt_glyphData, true );
#endif

		shortP = (int16*)glyphDataPtr;

		charData.numberContours = SWAPWINC(shortP);
		charData.bbox.xMin = SWAPWINC(shortP);
		charData.bbox.yMin = SWAPWINC(shortP);
		charData.bbox.xMax = SWAPWINC(shortP);
		charData.bbox.yMax = SWAPWINC(shortP);
	}
	else
		charData.numberContours = 1;

	if ( charData.numberContours >= 0 )	/* Not a component glyph */
	{
		key->lastGlyph = !( key->weGotComponents && (key->compFlags & MORE_COMPONENTS) );
		
		if ( length > 0 )
		{
			charData.endPoints = shortP;
			shortP += charData.numberContours;
			charData.numberInstructions = SWAPWINC(shortP);
			charData.instructions = (uint8*)shortP;
			charData.flags = (uint8*)shortP + charData.numberInstructions;
		}
		if ( result = sfnt_UnfoldCurve( key, &charData, &sizeOfInstructions, &instructionPtr, length, elementCount ))
			goto EXIT;
			
		if ( result = fsg_InnerGridFit( key, useHints, traceFunc, &charData.bbox, sizeOfInstructions, instructionPtr, false ) )
			goto EXIT;
	}
	else if ( key->weGotComponents = (charData.numberContours == -1) )
	{
		uint16 flags;
		boolean transformTrashed = false;
		
		do {
			transMatrix ctmSaveT, localSaveT;
			uint16 glyphIndex;
			int16 arg1, arg2;

			flags 		= (uint16)SWAPWINC(shortP);
			glyphIndex	= (uint16)SWAPWINC(shortP);
		
			if ( flags & ARG_1_AND_2_ARE_WORDS ) {
				arg1 	= SWAPWINC(shortP);
				arg2 	= SWAPWINC(shortP);
			} else {
				int8* byteP = (int8*)shortP;
				if ( flags & ARGS_ARE_XY_VALUES ) {
					/* offsets are signed */
					arg1 = *byteP++;
					arg2 = *byteP;
				} else {
					/* anchor points are unsigned */
					arg1 = (uint8)*byteP++;
					arg2 = (uint8)*byteP;
				}
				++shortP;
			}
			
			if ( flags & (WE_HAVE_A_SCALE | WE_HAVE_AN_X_AND_Y_SCALE | WE_HAVE_A_TWO_BY_TWO) )
			{
				fsg_MxCopy( &key->currentTMatrix, &ctmSaveT );
				fsg_MxCopy( &key->localTMatrix, &localSaveT );
				transformTrashed = true;
				if ( flags & WE_HAVE_A_TWO_BY_TWO )
				{
					register Fixed multiplier;
					transMatrix mulT;
		
					multiplier 	= SWAPWINC(shortP); /* read 2.14 */
					mulT.transform[0][0] = (multiplier << 2); /* turn into 16.16 */
					
					multiplier 	= SWAPWINC(shortP); /* read 2.14 */
					mulT.transform[0][1] = (multiplier << 2); /* turn into 16.16 */
					
					multiplier 	= SWAPWINC(shortP); /* read 2.14 */
					mulT.transform[1][0] = (multiplier << 2); /* turn into 16.16 */
					
					multiplier 	= SWAPWINC(shortP); /* read 2.14 */
					mulT.transform[1][1] = (multiplier << 2); /* turn into 16.16 */
					
					fsg_MxConcat2x2( &mulT, &key->currentTMatrix );
					fsg_MxConcat2x2( &mulT, &key->localTMatrix );
				}
				else
				{
					Fixed xScale, yScale;
					if ( flags & WE_HAVE_AN_X_AND_Y_SCALE )
					{
						xScale 	= (Fixed)SWAPWINC(shortP); /* read 2.14 */
						xScale <<= 2; /* turn into 16.16 */
						yScale 	= (Fixed)SWAPWINC(shortP); /* read 2.14 */
						yScale <<= 2; /* turn into 16.16 */
					} else {
						xScale 	= (Fixed)SWAPWINC(shortP); /* read 2.14 */
						xScale <<= 2; /* turn into 16.16 */
						yScale = xScale;
					}
					fsg_MxScaleAB( xScale, yScale, &key->currentTMatrix );
					fsg_MxScaleAB( xScale, yScale, &key->localTMatrix );
				}
				fsg_InitInterpreterTrans( key ); /*** Compute global stretch etc. ***/
				key->localTIsIdentity = false;
			}
			key->compFlags = flags;
			key->arg1 = arg1;
			key->arg2 = arg2;

			result = sfnt_ReadSFNT( key, elementCount, glyphIndex, useHints, traceFunc );

			if ( transformTrashed )
			{
				fsg_MxCopy( &ctmSaveT, &key->currentTMatrix );
				fsg_InitInterpreterTrans( key  ); /** Restore global stretch etc. ***/	
				fsg_MxCopy( &localSaveT, &key->localTMatrix );
				transformTrashed = false;
			}
		} while ( flags & MORE_COMPONENTS && result == NO_ERR );

		/* Do Final Composite Pass */
		sfnt_ReadSFNTMetrics( key, gIndex ); /* read metrics again */
		if ( flags & WE_HAVE_INSTRUCTIONS ) {
			sizeOfInstructions = (uint16)SWAPW(*shortP);
			instructionPtr = (uint8*)(++shortP);
		} else {
			sizeOfInstructions = 0;
			instructionPtr = 0;
		}
		if ( result = fsg_InnerGridFit( key, useHints, traceFunc, &charData.bbox, sizeOfInstructions, instructionPtr, true ) )
			goto EXIT;
	}
	else
		result = UNKNOWN_COMPOSITE_VERSION;

EXIT:
#ifndef PCLETTO
#ifdef RELEASE_MEM_FRAG
	if (glyphDataPtr)
		RELEASESFNTFRAG(key, glyphDataPtr);
#endif
#endif

	return result;
}

#pragma Code ()
