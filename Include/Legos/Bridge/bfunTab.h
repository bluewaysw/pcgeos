/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:        L E G O S	
MODULE:		
FILE:		bfuntab.h

AUTHOR:		Roy Goldman, Jul  7, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 7/95	Initial version.

DESCRIPTION:

        FunTab header information needed by *BOTH* basco and basrun

	$Id: bfunTab.h,v 1.1 97/12/05 12:15:52 gene Exp $
	$Revision: 1.1 $

	Liberty version control

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _BFUNTAB_H_
#define _BFUNTAB_H_

#ifndef LIBERTY
#include <geos.h>
#endif

/* NOTE: be very careful about changing the order of the values in this
   struct, Liberty assumes a specific order!!!!!!!!!!!!!!!! */
typedef struct 
{
    /* the first entry in this hugearray just an array of RunFastFTabEntrys
     * this serves two purposed, one of which is to avoid using an extra
     * MemHandle in the case of small modules, and the other is to avoid
     * ever having code in element 0, which is an assumption in basrun
     * right now (0 being the token for code not being loaded in)
     */
#ifndef LIBERTY
    VMFileHandle    FTI_vmFile;
    VMBlockHandle   FTI_code;
#endif
    /* we created this array then we should free it, if not, then don't */
    MemHandle  	    FTI_ftabTable;

    word	    FTI_funCount;        /* Number of functions in table */ 

#ifndef LIBERTY
    byte	    FTI_ownArray;
#endif
} FunTabInfo;

/* Create a new function table... */
#ifdef LIBERTY
FunTabInfo FunTabCreate(void);
dword FunTabGetMemoryUsedBy(FunTabInfo *fti);

#else	/* GEOS version below */
FunTabInfo FunTabCreate(MemHandle vmFile, MemHandle codeBlock);
#endif

/* Destroy a function table and all associated code... */
void FunTabDestroy(FunTabInfo *fti);

/* Append a new routine (and the table info too)
   (essentially calls FunTabAppendRoutine and then
   FunTabAppendTableEntry)*/
void FunTabAppendRoutine(FunTabInfo *fti, word startSeg,
			 word numLocals, byte page);

#endif /* _BFUNTAB_H_ */

