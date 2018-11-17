/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/mapstrng.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: mapstrng.c,v 1.1 97/04/18 11:45:22 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("TTMapStrngCode")

/********************* Revision Control Information **********************************
*                                                                                    *
*     $Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/mapstrng.c,v 1.1 97/04/18 11:45:22 newdeal Exp $                                                                       *
*                                                                                    *
*     $Log:	mapstrng.c,v $
 * Revision 1.1  97/04/18  11:45:22  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:33  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:15:41  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:13:41  roberte
 * Release
 * 
 * Revision 6.6  93/03/04  11:51:54  roberte
 * Made ComputeIndex4 INTEL portable.
 * 
 * Revision 6.5  92/12/29  12:50:11  roberte
 * Now includes "spdo_prv.h" first.
 * 
 * Revision 6.4  92/11/24  13:36:56  laurar
 * include fino.h
 * 
 * Revision 6.3  92/11/19  16:05:23  roberte
 * Release
 * 
 * Revision 6.2  92/11/11  11:18:48  roberte
 * #ifdef'ed out entire file if PCLETTO is defined.
 * 
 * Revision 6.1  91/08/14  16:46:21  mark
 * Release
 * 
 * Revision 5.1  91/08/07  12:27:34  mark
 * Release
 * 
 * Revision 4.2  91/08/07  11:45:45  mark
 * added RCS control strings
 * 
*************************************************************************************/

#ifdef RCSSTATUS
static char rcsid[] = "$Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/mapstrng.c,v 1.1 97/04/18 11:45:22 newdeal Exp $";
#endif

/*
	File:		MapString.c

	Contains:	Character to glyph mapping functions

	Written by:	Mike Reed

	Copyright:	(c) 1990 by Apple Computer, Inc., all rights reserved.

	Change History (most recent first):

		 <2>	11/16/90	MR		Fix range field of cmap-4 (thanks Eric) [rb]
		 <3>	 9/27/90	MR		Change selector in ComputeIndex4 to be log2(range) instead of
									2*log2(range), and fixed up comments
		 <2>	 8/10/90	MR		Add textLength field to MapString2
		 <1>	 7/23/90	MR		first checked in
				 7/23/90	MR		xxx put comment here xxx

	To Do:
*/


#include "spdo_prv.h"
#include "fino.h"
#include "fscdefs.h"
#include "mapstrng.h"
#ifdef __GEOS__
extern double _pascal floor(double __x);
#endif


#ifndef PCLETTO
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
 *	textLength is optional.  If it is nil, it is ignored.
 */
long MapString2 (map, charCodes, glyphs, glyphCount, textLength)
  register uint16* map;
  uint8* charCodes;
  int16* glyphs;
  long glyphCount;
  long* textLength;
{
	register short count = glyphCount;
	register uint8* codeP = charCodes;
	register uint16 mapMe;
	int16* origGlyphs = glyphs;

	for (--count; count >= 0; --count)
	{
		uint16 highByte = *codeP++;

		if ( map[highByte] != 0 )
			mapMe = *codeP++;
		else
			mapMe = highByte;

		if (textLength && *textLength < codeP - charCodes)
		{
			--codeP;
			if ( map[highByte] )
				--codeP;
			break;
		}

		map = ((uint16*)((int8*)map + map[highByte])) + 256;	/* <4> bad mapping */
		mapMe -= *map++; 		/* Subtract first code. */

		if ( mapMe < *map++ ) {	/* See if within range. */
			uint16 idDelta;

			idDelta = *map++;
			mapMe += mapMe; /* turn into word offset */

			map = (uint16*)((int32)map + *map + mapMe );

			if ( *map )
				*glyphs++ = *map + idDelta;
			else
				*glyphs++ = 0;		/* missing */
		} else
			*glyphs++ = 0;			/* missing */					/* <4> bad mapping */
	}
	if (textLength)
		*textLength = codeP - charCodes;		/* report # bytes eaten */

	return glyphs - origGlyphs;				/* return # glyphs processed */
}


#define maxLinearX2 16
#define BinaryIteration \
		newP = (uint16 *) ((int8 *)tableP + (range >>= 1)); \
		if ( charCode > *newP ) tableP = newP;

/*
 * Segment mapping to delta values, Yack.. !
 *
 * In memory of Peter Edberg. Initial code taken from code example supplied by Peter.
 */
static uint16 ComputeIndex4 (tableP, charCode)
  uint16* tableP;
  uint16 charCode;
{
	register uint16 idDelta;
	register uint16 offset, segCountX2, index;

	index = 0; /* assume missing initially */
	segCountX2 = SWAPWINC(tableP);

	if ( segCountX2 < maxLinearX2 ) {
		tableP += 3; /* skip binary search parameters */
	} else {
		/* start with unrolled binary search */
		register uint16 *newP;
		register int16  range; 		/* size of current search range */
		register uint16 selector; 	/* where to jump into unrolled binary search */
		register uint16 shift; 		/* for shifting of range */

		range 		= SWAPWINC(tableP); 	/* == 2*(2**floor(log2(segCount))) == 2*largest power of two <= segCount */
		selector 	= SWAPWINC(tableP);	/* == log2(range/2) */
		shift 		= SWAPWINC(tableP); 	/* == 2*segCount-range */
		/* tableP points at endCount[] */

		if ( charCode >= SWAPW(*((uint16 *)((int8 *)tableP + range))))
			tableP = (uint16 *) ((int8 *)tableP + shift); /* range to low shift it up */
		switch ( selector )
		{
		case 15: BinaryIteration;
		case 14: BinaryIteration;
		case 13: BinaryIteration;
		case 12: BinaryIteration;
		case 11: BinaryIteration;
		case 10: BinaryIteration;
		case  9: BinaryIteration;
		case  8: BinaryIteration;
		case  7: BinaryIteration;
		case  6: BinaryIteration;
		case  5: BinaryIteration;
		case  4: BinaryIteration;
		case  3:
		case  2:  /* drop through */
		case  1:
		case  0:
			break;
		}
	}
	/* Now do linear search */
	while ( charCode > SWAPW(*tableP)) /* goes one to far, so we can skip the reservedPad */
		tableP++;
	tableP++; /* one more */

	/* End of search, now do mapping */

	tableP = (uint16 *) ((int8 *)tableP + segCountX2); /* point at startCount[] */
	if ( charCode >= SWAPW(*tableP) ) {
		offset = charCode - SWAPW(*tableP);
		tableP = (uint16 *) ((int8 *)tableP + segCountX2); /* point to idDelta[] */
		idDelta = SWAPW(*tableP);
		tableP = (uint16 *) ((int8 *)tableP + segCountX2); /* point to idRangeOffset[] */
		if ( SWAPW(*tableP) == 0 ) {
			index	= charCode + idDelta;
		} else {
			offset += offset; /* make word offset */
			tableP 	= (uint16 *) ((int8 *)tableP + SWAPW(*tableP) + offset ); /* point to glyphIndexArray[] */
			if (index = SWAPW(*tableP))
				index += idDelta;
		}
	}
	return index;
}


long MapString4_16 (map, charCodes, glyphs, glyphCount)
  uint16* map;
  uint16* charCodes;
  int16* glyphs;
  long glyphCount;
{
	register short count = glyphCount;

	for (--count; count >= 0; --count)
		*glyphs++ = ComputeIndex4( map, *charCodes++ );

	return glyphCount << 1;
}


/*
 * Trimmed Table Mapping - 16 bit character codes
 */
long MapString6_16 (map, charCodes, glyphs, glyphCount)
  register uint16* map;
  uint16* charCodes;
  register int16* glyphs;
  long glyphCount;
{
	register short count = glyphCount - 1;
	uint16 firstCode = *map++;
	uint16 entryCount = *map++;
	int16* origGlyphs = glyphs;

	for (; count >= 0; --count)
	{
		uint16 charCode = *charCodes++ - firstCode;
		if ( charCode < entryCount )
			*glyphs++ = map[ charCode ];
		else
			*glyphs++ = 0; /* missing char */
	}
	return glyphs - origGlyphs;
}
#endif /* PCLETTO */

#pragma Code ()
