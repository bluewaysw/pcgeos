/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/fserror.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: fserror.h,v 1.1 97/04/18 11:45:21 newdeal Exp $
 *
 ***********************************************************************/

/********************* Revision Control Information **********************************
*                                                                                    *
*     $Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/fserror.h,v 1.1 97/04/18 11:45:21 newdeal Exp $                                                                       *
*                                                                                    *
*     $Log:	fserror.h,v $
 * Revision 1.1  97/04/18  11:45:21  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:19  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:15:20  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:11:42  roberte
 * Release
 * 
 * Revision 6.3  92/11/19  16:04:10  roberte
 * Release
 * 
 * Revision 6.1  91/08/14  16:45:43  mark
 * Release
 * 
 * Revision 5.1  91/08/07  12:26:54  mark
 * Release
 * 
 * Revision 4.3  91/08/07  12:23:54  mark
 * remove rcsstatus string
 * 
 * Revision 4.2  91/08/07  11:44:15  mark
 * added RCS control strings
 * 
*************************************************************************************/

/*
	File:		FSError.h

	Contains:	xxx put contents here (or delete the whole line) xxx

	Written by:	xxx put name of writer here (or delete the whole line) xxx

	Copyright:	© 1989-1990 by Apple Computer, Inc., all rights reserved.

	Change History (most recent first):

		 <3>	12/20/90	RB		Define INVALID_GLYPH_INDEX error (0x100A) return for
									fs_NewGlyph. [mr]
		 <2>	12/11/90	MR		Add unknown_cmap_format error code. [rb]
		 <4>	 7/13/90	MR		made endif at bottom use a comment
		 <3>	  5/3/90	RB		Changed char to int8 for variable type.   Now it is legal to
									pass in zero as the address of memory when a piece of
		 <2>	 2/27/90	CL		New error code for missing but needed table. (0x1409 )
	   <3.1>	11/14/89	CEL		Now it is legal to pass in zero as the address of memory when a
									piece of the sfnt is requested by the scaler. If this happens
									the scaler will simply exit with an error code !
	   <3.0>	 8/28/89	sjk		Cleanup and one transformation bugfix
	   <2.2>	 8/14/89	sjk		1 point contours now OK
	   <2.1>	  8/8/89	sjk		Improved encryption handling
	   <2.0>	  8/2/89	sjk		Just fixed EASE comment
	   <1.5>	  8/1/89	sjk		Added composites and encryption. Plus some enhancements…
	   <1.4>	 6/13/89	SJK		Comment
	   <1.3>	  6/2/89	CEL		16.16 scaling of metrics, minimum recommended ppem, point size 0
									bug, correct transformed integralized ppem behavior, pretty much
									so
	   <1.2>	 5/26/89	CEL		EASE messed up on “c” comments
	  <•1.1>	 5/26/89	CEL		Integrated the new Font Scaler 1.0 into Spline Fonts
	   <1.0>	 5/25/89	CEL		Integrated 1.0 Font scaler into Bass code for the first time…

	To Do:
*/
/************/
/** ERRORS **/
/************/
#define NO_ERR						0x0000
#define NULL_KEY					0x0000




/** EXTERNAL INTERFACE PACKAGE **/
#define MALLOC_FAILURE              0x1000
#define NULL_KEY_ERR				0x1001
#define NULL_INPUT_PTR_ERR			0x1002
#define NULL_MEMORY_BASES_ERR		0x1003
#define VOID_FUNC_PTR_BASE_ERR		0x1004
#define OUT_OFF_SEQUENCE_CALL_ERR	0x1005
#define BAD_CLIENT_ID_ERR			0x1006
#define NULL_SFNT_DIR_ERR			0x1007
#define	NULL_SFNT_FRAG_PTR_ERR		0x1008
#define NULL_OUTPUT_PTR_ERR			0x1009
#define INVALID_GLYPH_INDEX			0x100A
#define UNDEFINED_GLYPH				0x100B

/* fnt_execute */
#define UNDEFINED_INSTRUCTION_ERR	0x1101
#define TRASHED_MEM_ERR				0x1102


/* fsg_CalculateBBox */
#define POINT_MIGRATION_ERR			0x1201

/* sc_ScanChar */
#define BAD_START_POINT_ERR			0x1301
#define SCAN_ERR					0x1302



/** SFNT DATA ERROR and errors in sfnt.c **/
#define SFNT_DATA_ERR				0x1400
#define POINTS_DATA_ERR				0x1401
#define INSTRUCTION_SIZE_ERR 		0x1402
#define CONTOUR_DATA_ERR			0x1403
#define GLYPH_INDEX_ERR				0x1404
#define BAD_MAGIC_ERR				0x1405
#define OUT_OF_RANGE_SUBTABLE		0x1406
#define UNKNOWN_COMPOSITE_VERSION	0x1407
#define CLIENT_RETURNED_NULL		0x1408
#define MISSING_SFNT_TABLE			0x1409
#define UNKNOWN_CMAP_FORMAT			0x140A

/* spline call errors */
#define BAD_CALL_ERR				0x1500

#define TRASHED_OUTLINE_CACHE		0x1600

/************ For Debugging *************/

#ifdef XXX
#define DEBUG_ON
pascal 	Debug()						/* User break drop into Macsbug */
#ifdef	DEBUG_ON
extern	0xA9FF;
#else
{
	;
}
#endif

#ifdef	LEAVEOUT
pascal 	void DebugStr( aString) int8 *aString; extern 0xABFF;
int8 	*c2pstr();
#define BugInfo( aString) DebugStr( c2pstr(aString))
#endif

#endif	/* XXX */
/****************************************/
