/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  ffDPaste.h
 * FILE:	  ffDPaste.h
 *
 * AUTHOR:  	  Jeremy Dashe: Aug 14, 1992
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/14/92	  jeremy    Initial version
 *
 * DESCRIPTION:
 *	This file contains structure definitions used when cutting and
 *	pasting database fields.
 *
 * 	$Id: ffDPaste.h,v 1.1 97/04/04 15:50:46 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _FFDPASTE_H_
#define _FFDPASTE_H_

#include <geos.h>

#define MAX_NUMBER_OF_PASTED_LABELS 256

typedef struct {
    VMBlockHandle VMBlock;
    ChunkHandle chunk;
    optr labelOptr;
} LabelIDSet;

typedef struct {
    optr    databaseOptr;
    byte    numLabels;
    LabelIDSet labelSet[MAX_NUMBER_OF_PASTED_LABELS];
} LabelIDArray;

#endif /* _FFDPASTE_H_ */
