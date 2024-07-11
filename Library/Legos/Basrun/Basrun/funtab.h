/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	uuuuuuuuuuuuhhhhhhh, LEGOS
MODULE:		
FILE:		funtab.h

AUTHOR:		Roy Goldman, May  9, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 5/ 9/95	Initial version.

DESCRIPTION:
	
        Header for runtime code storage.
	FunTabInfo struct is actually defined in bfuntab.h, since
	it's used by basco also.

	This header is for runtime use only.
	
	
	$Revision: 1.1 $

	Liberty version control
	$Id: funtab.h,v 1.1 98/10/05 12:35:12 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _FUNTAB_H_
#define _FUNTAB_H_

#ifdef LIBERTY
#include <Legos/bfuntab.h>
#else
#include <geos.h>
#include <Legos/Bridge/bfuntab.h>
#endif

/* Initial size and increment size for the memory blocks
   where compiled code will be stored. */

#if ERROR_CHECK

#define INC_ROUTINES 8
#define INC_ROUTINE_BLOCKS 2

#define INC_BLOCK_SIZE 128                        
#define MAX_ROUTINE_BLOCK_SIZE (48*INC_BLOCK_SIZE)

#else

#define INC_ROUTINES 32
#define INC_ROUTINE_BLOCKS 32

#define INC_BLOCK_SIZE 1024
#define MAX_ROUTINE_BLOCK_SIZE (6*INC_BLOCK_SIZE)

#endif

/* The function table is filled with RunFastFTabEntry structures,
   one for each routine.
*/

typedef struct 
{
    /* a handle to where the code is stored for the function
     * in GEOS, this is now a huge array index pointing to the first segment
     * of the function
     */
    MemHandle   RFFTE_codeHandle;

    /* Page number of the rountine */
    /* In Liberty, this is always 0 */
    byte        RFFTE_page;

    /* Number of local variables for this routine */
    word        RFFTE_numLocals;

} RunFastFTabEntry;


/* In Bridge/bfuntab.h:
   FunTabInfo struct     
   routines to Create & Destroy a function table
   Plus FunTabAppendRoutine
   and FunTabSlimFast...
*/

/* Append a routine's function table info */

Boolean FunTabAppendTableEntry(FunTabInfo *fti, RunFastFTabEntry *fte);

/* Append a function's code to the code store, returning
   the handle/offset reference... */
/* In liberty, no code will ever be appended.  It will either be all
   in ROM or loaded in one piece into RAM */
#ifndef LIBERTY
void FunTabAppendRoutineCode(VMFileHandle vmFile,
			     FunTabInfo *fti, byte *code, word codeLen,
			     word *startSeg);
#endif

/* Return the number of local variables for a given function
   (used by debugger) */

word FunTabGetNumLocals(FunTabInfo *fti, word funcNum);

/* Lock down the function table and return a pointer to the entry
   for funcNum. This is in efficient if for some reason you need
   to access the entries for more than one routine at a time,
   in that case, just call MemLock on the table once and index
   as often as needed to get the different entries */

#ifndef LIBERTY
#define FUNTAB_LOCK_TABLE_ENTRY(_fti, _rfte, _funcNum) 			\
_rfte =	&((RunFastFTabEntry*)MemLock((_fti).FTI_ftabTable))[_funcNum]

#define FUNTAB_UNLOCK_TABLE_ENTRY(_fti, _rfte) MemUnlock((_fti).FTI_ftabTable)

#else
#define FUNTAB_LOCK_TABLE_ENTRY(_fti, _rfte, _funcNum) 			\
_rfte =	(theHeapDataMap.ValueIsHandle((_fti).FTI_ftabTable)) ? 		\
	&((RunFastFTabEntry*)MemLock((_fti).FTI_ftabTable))[_funcNum] :	\
	&((RunFastFTabEntry*)((_fti).FTI_ftabTable))[_funcNum]

#define FUNTAB_UNLOCK_TABLE_ENTRY(_fti, _rfte)				\
	if (theHeapDataMap.ValueIsHandle((_fti).FTI_ftabTable))		\
		MemUnlock((_fti).FTI_ftabTable);


#endif
  
#endif /* _FUNTAB_H_ */
