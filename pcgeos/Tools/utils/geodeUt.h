/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Tools
MODULE:		Utils library
FILE:		geodeUt.h

AUTHOR:		Chris Boyke, Jan 12, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/12/94   	Initial version.

DESCRIPTION:
	

	$Id: geodeUt.h,v 1.2 96/05/20 18:55:35 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 * WARNING: these only do the right thing on 32-bit integers in Intel
 * byte-order!  In Unix, this is mainly for values read from a file.
 */
#define Offset(fptr) (swapl(fptr) & 0xffff)
#define Segment(fptr) (swapl((unsigned long)(fptr)) >> 16)

#define GHResCount(gh) (swaps((gh)->resCount))
#define GHLibCount(gh) (swaps(gh->libCount))
#define GHLibOffset(gh) (swaps(gh->libOffset))
#define GHExportEntryCount(gh) (swaps(gh->exportEntryCount))

#define ParagraphAlign(x) (((x)+15) & 0xfff0)

extern word 	GeodeGetSizeOfNthResource(GeodeHeader2 *gh, 
					    FILE *fp, 
					    int resourceId);

extern word 	GeodeGetAllocationFlagsOfNthResource(GeodeHeader2 *gh, 
						       FILE *fp, 
						       int resourceId);

extern dword 	GeodeGetPositionOfNthResource(GeodeHeader2 *gh, 
					       	FILE *fp,
					     	int resourceId);

extern word 	GeodeGetRelocationTableSizeOfNthResource(GeodeHeader2 *gh,
							    FILE *fp,
							    int resourceId);

extern byte 	*GeodeReadResource(GeodeHeader2 *gh, FILE *fp,
				   int size, int resourceId);
