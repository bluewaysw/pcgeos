/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/privsfnt.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: privsfnt.h,v 1.1 97/04/18 11:45:23 newdeal Exp $
 *
 ***********************************************************************/

/********************* Revision Control Information **********************************
*                                                                                    *
*     $Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/privsfnt.h,v 1.1 97/04/18 11:45:23 newdeal Exp $                                                                       *
*                                                                                    *
*     $Log:	privsfnt.h,v $
 * Revision 1.1  97/04/18  11:45:23  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:48  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:16:08  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:21:44  roberte
 * Release
 * 
 * Revision 6.3  92/11/19  16:06:31  roberte
 * Release
 * 
 * Revision 6.2  92/04/30  11:31:59  leeann
 * stripped 1 non-ASCII character
 * 
 * Revision 6.1  91/08/14  16:47:30  mark
 * Release
 * 
 * Revision 5.1  91/08/07  12:28:39  mark
 * Release
 * 
 * Revision 4.2  91/08/07  11:53:04  mark
 * add rcs control strings
 * 
*************************************************************************************/

/*
	File:		private sfnt.h

	Contains:	xxx put contents here xxx

	Written by:	xxx put writers here xxx

	Copyright:	) 1990 by Apple Computer, Inc., all rights reserved.

	Change History (most recent first):

		 <4>	 7/18/90	MR		Change return types to int for computemapping and readsfnt
		 <3>	 7/14/90	MR		changed SQRT to conditional FIXEDSQRT2
		 <2>	 7/13/90	MR		Change parameters to ReadSFNT and ComputeMapping
		<1+>	 4/18/90	CL		
		 <1>	 3/21/90	EMT		First checked in with Mike Reed's blessing.

	To Do:
*/

/* PUBLIC PROTOTYPE CALLS */

/*
 * Below we have private stuff
 * This has nothing to do with the file format.
 */
/* extern void* sfnt_GetTablePtr (fsg_SplineKey *key, sfnt_tableIndex n, boolean mustHaveTable); */
extern void* sfnt_GetTablePtr ();

/*
 * Creates mapping for finding offset table
 */
/* extern void sfnt_DoOffsetTableMap(fsg_SplineKey *key); */
extern void sfnt_DoOffsetTableMap();

/* perfect spot size (Fixed) */
#ifndef FIXEDSQRT2
#define FIXEDSQRT2 0x00016A0A
#endif

/*
 * Returns offset and length for table n
 */
/* extern void sfnt_GetOffsetAndLength(fsg_SplineKey *key, int32 *offsetT, unsigned *lengthT, sfnt_tableIndex n); */
extern void sfnt_GetOffsetAndLength();

/* extern int sfnt_ComputeMapping(fsg_SplineKey *key, uint16 platformID, uint16 specificID); */
extern int sfnt_ComputeMapping();

/* extern void sfnt_ReadSFNTMetrics(fsg_SplineKey *key, uint16 glyphIndex); */
extern void sfnt_ReadSFNTMetrics();

/* extern int sfnt_ReadSFNT(fsg_SplineKey *key, int16 *elementCount, uint16 gIndex, boolean useHints, voidFunc traceFunc); */
extern int sfnt_ReadSFNT();
