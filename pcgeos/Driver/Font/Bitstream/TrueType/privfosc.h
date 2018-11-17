/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/privfosc.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: privfosc.h,v 1.1 97/04/18 11:45:23 newdeal Exp $
 *
 ***********************************************************************/

/********************* Revision Control Information **********************************
*                                                                                    *
*     $Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/privfosc.h,v 1.1 97/04/18 11:45:23 newdeal Exp $                                                                       *
*                                                                                    *
*     $Log:	privfosc.h,v $
 * Revision 1.1  97/04/18  11:45:23  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:47  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:16:00  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:21:38  roberte
 * Release
 * 
 * Revision 6.3  92/11/19  16:06:25  roberte
 * Release
 * 
 * Revision 6.2  92/04/30  11:26:45  leeann
 * stripped 2 non-ASCII characters
 * 
 * Revision 6.1  91/08/14  16:47:25  mark
 * Release
 * 
 * Revision 5.1  91/08/07  12:28:34  mark
 * Release
 * 
 * Revision 4.2  91/08/07  11:47:59  mark
 * lock fnt.h
 * added RCS control strings
 * 
*************************************************************************************/

/*
	File:		privateFontScaler.h

	Contains:	Nothing Important

	Written by:	Charlton E. Lui

	Copyright:	) 1990 by Apple Computer, Inc., all rights reserved.

	Change History (most recent first):

		 <3>	 7/18/90	MR		change parameters of SetupKey to be input*, unsigned and int
		 <2>	  5/3/90	RB		nothing new
		 <1>	 4/16/90	HJR		first checked in
		 <1>	 4/10/90	CL		first checked in

	To Do:
*/

/* ****************************************************
**
** CKL	02/20/1990	Added ANSI-C prototypes
**
** ****************************************************
*/
 
/*
 *
 *  ) Apple Computer Inc. 1988, 1989, 1990.
 *
 *	The file defines private sfnt stuff
 *
 * History:
 * 
 */




/* extern pascal int32 fs_SetMem(register fs_GlyphInputType *inputPtr, fs_GlyphInfoType *outputPtr); */
/* extern fsg_SplineKey* fs_SetUpKey(fs_GlyphInputType* inptr, unsigned stateBits, int* error); */
extern int32 fs_SetMem();
extern fsg_SplineKey* fs_SetUpKey();

