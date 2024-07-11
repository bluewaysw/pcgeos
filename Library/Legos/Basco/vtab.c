/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		vtab.c

AUTHOR:		Paul L. DuBois, May 16, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 5/16/95   	Initial version.

DESCRIPTION:
	Variable table module.
	
	Assumes that strings passed in are elements in the task's
	stringIdentTable.

	A VTab is an optr to a chunkarray of VTabEntries, and a size.

	VTabs may be created and destroyed; variables may be added
	and looked up in a VTab.

	$Id: vtab.c,v 1.1 98/10/13 21:43:57 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <geos.h>
#include <lmem.h>
#include <chunkarr.h>
#include <Ansi/string.h>
#include "stable.h"
#include "vtab.h"
#include "bascoint.h"

/* Pointer to callback used in ChunkArraySort */
typedef PCB(sword, CASProcPtr, (void *el1, void *el2, word valueForCallback));

VTabEntry*
VT_LookupLow(MemHandle vtHeap, word table, word nameId, word* elt);


/*********************************************************************
 *			VTabInit
 *********************************************************************
 * SYNOPSIS:	Initialize variable table module
 * CALLED BY:	EXTERNAL
 * RETURN:	Handle to a VTabHeap (containing all vtab module state)
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/16/95	Initial version
 * 
 *********************************************************************/
MemHandle
VTabInit()
{
    MemHandle	vtHeap;
    VTabHeap*	vth;
    ChunkHandle	chunk;

    vtHeap = MemAllocLMem(LMEM_TYPE_GENERAL, sizeof(VTabHeap));
    MemModifyFlags(vtHeap, HF_SHARABLE, 0);
    vth = MemLock(vtHeap);
    
    vth->VTH_freeHead = CA_NULL_ELEMENT;
    chunk = ChunkArrayCreate(vtHeap, sizeof(ChunkHandle), 0, 0); /* shuffle */
    vth = MemDeref(vtHeap);
    vth->VTH_tableArray = chunk;
    MemUnlock(vtHeap);
    return vtHeap;
}

/*********************************************************************
 *			VTabExit
 *********************************************************************
 * SYNOPSIS:	Clean up variable table module
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/16/95	Initial version
 * 
 *********************************************************************/
void
VTabExit(MemHandle vtHeap)
{
    MemFree(vtHeap);
    return;
}

/*********************************************************************
 *			VTAlloc
 *********************************************************************
 * SYNOPSIS:	Create a new VTab and return its index
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/16/95	Initial version
 * 
 *********************************************************************/
word
VTAlloc(MemHandle vtHeap)
{
    VTabHeap*	vth;
    optr	array;
    word	dummy;
    word	index;
    ChunkHandle* newEltP;	/* Pointer to a chunkarray element */
    ChunkHandle	newElt;		/* handle of new VTab chunkarray */

    (void) MemLock(vtHeap);

    /* Create new array first, as it may cause the LMem heap to shuffle
     */
    ;{
	VTab*	vt;
	
	newElt = ChunkArrayCreate(vtHeap, 0, sizeof(VTab), 0); /* shuffle */
	vt = LMemDerefHandles(vtHeap, newElt);
	vt->VT_size = 0;
    }

    /* Grab an element off the free list, or create a new one
     */
    vth = MemDeref(vtHeap);
    array = ConstructOptr(vtHeap, vth->VTH_tableArray);
    if (vth->VTH_freeHead != CA_NULL_ELEMENT)
    {
	index = vth->VTH_freeHead;
	newEltP = ChunkArrayElementToPtr(array, index, &dummy);
	vth->VTH_freeHead = *newEltP;
    }
    else
    {
	index = ChunkArrayGetCount(array);
	newEltP = ChunkArrayAppend(array, 0); /* shuffle */
    }
    *newEltP = newElt;

    MemUnlock(vtHeap);
    return index;
}




/*********************************************************************
 *			VTDestroy
 *********************************************************************
 * SYNOPSIS:	Destroy a VTab
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/16/95	Initial version
 * 
 *********************************************************************/
void
VTDestroy(MemHandle vtHeap, word table)
{
    VTabHeap*	vth;
    ChunkHandle* chunk;
    word	dummy;

    vth = MemLock(vtHeap);
    
    EC_ERROR_IF(table >= ChunkArrayGetCountHandles(vtHeap,vth->VTH_tableArray),
		BE_INVALID_VTAB);

    chunk = ChunkArrayElementToPtrHandles
	(vtHeap, vth->VTH_tableArray, table, &dummy);
    LMemFreeHandles(vtHeap, *chunk);

    /* Push this index onto the free list
     */
    *chunk = vth->VTH_freeHead;
    vth->VTH_freeHead = table;
    
    MemUnlock(vtHeap);
    return;
}

/*********************************************************************
 *			VTAdd
 *********************************************************************
 * SYNOPSIS:	Add a variable in a scope.  Allows redefinition.
 * CALLED BY:	EXTERNAL
 * RETURN:	Variable # in scope.
 * SIDE EFFECTS:
 * STRATEGY:
 *	Only allow redeclaration over forward references; all other
 *	redeclarations are errors.
 *
 *	If (flags & VTF_FORWARD_REF), the add is "soft" ie, if the
 *	entry already exists, then it will not be destroyed or
 *	modified.
 *
 *	Resizing variables isn't supported.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/16/95	Initial version
 * 
 *********************************************************************/   
word
VTAdd(MemHandle vtHeap, word table, word nameId,
      LegosType type, byte varSize, byte flags, word extraInfo, 
      word funcNumber)
{
    VTabHeap*	vth;
    optr	vtab;		/* VTH_tableArray[table] */
    word	elt;		/* elt # of newly added var */
    VTabEntry*	vte;		/* vtab[elt] */

    vth = MemLock(vtHeap);

    /* vtab <- VTH_tableArray[table] */
    ;{
	word	dummy;

	EC_ERROR_IF(table >= ChunkArrayGetCountHandles
		    (vtHeap,vth->VTH_tableArray),
		    BE_INVALID_VTAB);
	vtab = ConstructOptr
	    (vtHeap,
	     *(word*)ChunkArrayElementToPtrHandles(vtHeap, vth->VTH_tableArray,
						   table, &dummy));
    }

    vte = VT_LookupLow(vtHeap, table, nameId, &elt);

    if (!vte)
    {
	/* Not found; append an entry
	 */
	VTab*	vt;
	word	curOffset;

	vt = LMemDeref(vtab);
	curOffset = vt->VT_size;
	vt->VT_size += varSize;

	elt = ChunkArrayGetCount(vtab);
	vte = ChunkArrayAppend(vtab, sizeof(VTabEntry));	/* shuffle */
	vte->VTE_name = nameId;
	vte->VTE_offset = curOffset;
	vte->VTE_size = varSize;
	/* initial our index in the array */
	vte->VTE_index = elt;
    }
    else
    {
	word	dummy;

	/* Found a pre-existing entry.
	 *  Punt if adding a forward ref
	 *  Allow if adding _over_ a forward ref
	 *  Error if entry is from a different function
	 *  Otherwise, allow
	 */
	/* Changing var size isn't supported; if you need it, add it */
	EC_ERROR_IF(varSize != vte->VTE_size, BE_FAILED_ASSERTION);

	if (flags & VTF_FORWARD_REF) {
	    goto done;
	}

	/* if the variable is not yet assign a function or is deleted
	 * (0xffff), or is just a forward reference,
	 * then it's OK to write over it
	 */
	if ((vte->VTE_funcNumber == 0xffff)	||
	    (vte->VTE_flags & VTF_FORWARD_REF) )
	{
	    ;/* OK */
	} else {
	    elt = VTAB_ERROR;
	    goto done;
	}
		
	/* Get rid of info possibly appended with VTAppendInfo.
	 * Rederef for kicks.
	 */
	ChunkArrayElementResize(vtab, elt, sizeof(VTabEntry));
	vte = ChunkArrayElementToPtr(vtab, elt, &dummy);

	/* if we change types of a global variable or struct field
	 * we will need a full recompile as type specific
	 * opcode may have been generated in other routines
	 *
	 * Writing over a forward reference doesn't count as changing
	 * a type
	 */
	if (vte->VTE_type != type &&
	    table == GLOBAL_VTAB &&
	    !(vte->VTE_flags & VTF_FORWARD_REF))
	{
	    elt = VTAB_RECOMPILE;
	    funcNumber = 0xffff;
	}
    }

    vte->VTE_funcNumber = funcNumber;
    vte->VTE_flags = flags;
    vte->VTE_type = type;
    vte->VTE_extraInfo = extraInfo;

 done:
    MemUnlock(vtHeap);
    return elt;
}

/*********************************************************************
 *			VTMove
 *********************************************************************
 * SYNOPSIS:	Move a variable to a different offset in the scope
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	There must be a variable already at <newOffset>
 *	The offsets will just be swapped
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	2/21/96  	Initial version
 * 
 *********************************************************************/
void
VTMove(MemHandle vtHeap, word table, word element, word newOffset)
{
    VTabHeap*	vth;
    ChunkHandle* vtabChunk;
    optr	vtabArray;
    VTabEntry	*eltVte;
    word	dummy, count;

    /* For now, all vars assumed to be aligned on 5-byte boundaries */
    EC_ERROR_IF(newOffset % 5 != 0, BE_FAILED_ASSERTION);

    vth = MemLock(vtHeap);

    vtabChunk = ChunkArrayElementToPtrHandles
	(vtHeap, vth->VTH_tableArray, table, &dummy);
    vtabArray = ConstructOptr(vtHeap, *vtabChunk);

    count = ChunkArrayGetCount(vtabArray);
    EC_ERROR_IF(element >= count, BE_FAILED_ASSERTION);
    eltVte = ChunkArrayElementToPtr(vtabArray, element, &dummy);

    if (eltVte->VTE_offset != newOffset)
    {
	word	i;
	VTabEntry	*destVte;

	for (i=0; i<count; i++)
	{
	    destVte = ChunkArrayElementToPtr(vtabArray, i, &dummy);
	    if (destVte->VTE_offset == newOffset)
	    {
		/* swap the two and bail */
		destVte->VTE_offset = eltVte->VTE_offset;
		eltVte->VTE_offset = newOffset;
		break;
	    }
	}
    }

    MemUnlock(vtHeap);
    return;
}

/*********************************************************************
 *			VTAppendInfo
 *********************************************************************
 * SYNOPSIS:	Append some data to a VTab entry
 * CALLED BY:	GLOBAL
 * RETURN:	nothing
 * SIDE EFFECTS:
 *	Fatal errors if <nameId> isn't in the VTab.
 *
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 7/13/95	Initial version
 * 
 *********************************************************************/
void
VTAppendDims(MemHandle vtHeap, word table, word nameId,
	     VTabStaticDims* dims)
{
    VTabHeap*	vth;
    optr	vtab;		/* VTH_tableArray[table] */
    word	elt;		/* elt # of newly added var */
    byte*	eltData;
    word	dummy;

    vth = MemLock(vtHeap);

    /* vtab <- VTH_tableArray[table] */
    ;{
	word	dummy;

	EC_ERROR_IF(table >= ChunkArrayGetCountHandles
		    (vtHeap,vth->VTH_tableArray),
		    BE_INVALID_VTAB);
	vtab = ConstructOptr
	    (vtHeap,
	     *(word*)ChunkArrayElementToPtrHandles(vtHeap, vth->VTH_tableArray,
						   table, &dummy));
    }

    (void) VT_LookupLow(vtHeap, table, nameId, &elt);
    EC_ERROR_IF(elt == CA_NULL_ELEMENT, BE_FAILED_ASSERTION);

    ChunkArrayElementResize(vtab, elt,
			    sizeof(VTabEntry)+ sizeof(VTabStaticDims));
    eltData = ChunkArrayElementToPtr(vtab, elt, &dummy);
    eltData += sizeof(VTabEntry);
    memcpy(eltData, dims, sizeof(VTabStaticDims));
    MemUnlock(vtHeap);
    return;
}

/*********************************************************************
 *			VTLookupIndex
 *********************************************************************
 * SYNOPSIS:	Get a VTabEntry given a vtab and an element #
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/17/95	Initial version
 * 
 *********************************************************************/
void
VTLookupIndex(MemHandle vtHeap, word table, word element,
	      VTabEntry* retVte)
{
    VTabHeap*	vth;
    ChunkHandle* chunk;
    optr	carr;		/* chunkarray */
    VTabEntry*	vte;
    word	size;

    EC_BOUNDS(retVte);

    vth = MemLock(vtHeap);

    EC_ERROR_IF(table >= ChunkArrayGetCountHandles(vtHeap,vth->VTH_tableArray),
		BE_INVALID_VTAB);
    chunk = ChunkArrayElementToPtrHandles
	(vtHeap, vth->VTH_tableArray, table, &size);
    carr = ConstructOptr(vtHeap, *chunk);

    EC_ERROR_IF(element >= ChunkArrayGetCount(carr), BE_FAILED_ASSERTION);
    
    vte = ChunkArrayElementToPtr(carr, element, &size);
    *retVte = *vte;

    MemUnlock(vtHeap);
    return;
}


/*********************************************************************
 *			VTLookupOffset
 *********************************************************************
 * SYNOPSIS:	Get a VTabEntry given a vtab and an offset
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/17/95	Initial version
 * 
 *********************************************************************/
void VTLookupOffset(MemHandle vtHeap, word table, word offset,
		    VTabEntry* retVte)
{
    VTabHeap*	vth;
    ChunkHandle* chunk;
    optr	carr;		/* chunkarray */
    VTabEntry*	vte;
    word	size;
    int		count, i;

    EC_BOUNDS(retVte);

    vth = MemLock(vtHeap);
    EC_ERROR_IF(table >= ChunkArrayGetCountHandles(vtHeap,vth->VTH_tableArray),
		BE_INVALID_VTAB);
    chunk = ChunkArrayElementToPtrHandles(vtHeap, vth->VTH_tableArray, 
					  table, &size);
    carr = ConstructOptr(vtHeap, *chunk);

    count = VTGetCount(vtHeap, table);
    for (i = 0; i < count; i++)
    {
	vte = ChunkArrayElementToPtr(carr, i, &size);
	if (vte->VTE_offset == offset)
	{
	    *retVte = *vte;
	    break;
	}
    }
    MemUnlock(vtHeap);
    return;
}


/*********************************************************************
 *			VTLookupDimsIndex
 *********************************************************************
 * SYNOPSIS:	Get a VTabEntry given a vtab and an element #
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/17/95	Initial version
 * 
 *********************************************************************/
void
VTLookupDimsIndex(MemHandle vtHeap, word table, word element,
		  VTabStaticDims* dims)
{
    VTabHeap*	vth;
    ChunkHandle* chunk;
    optr	carr;		/* chunkarray */
    VTabEntry*	vte;
    word	size;

    EC_BOUNDS(dims);

    vth = MemLock(vtHeap);

    EC_ERROR_IF(table >= ChunkArrayGetCountHandles(vtHeap,vth->VTH_tableArray),
		BE_INVALID_VTAB);
    chunk = ChunkArrayElementToPtrHandles
	(vtHeap, vth->VTH_tableArray, table, &size);
    carr = ConstructOptr(vtHeap, *chunk);

    EC_ERROR_IF(element >= ChunkArrayGetCount(carr), BE_FAILED_ASSERTION);
    
    vte = ChunkArrayElementToPtr(carr, element, &size);

    /* Punt if var doesn't have extra info */
    EC_ERROR_IF(size != sizeof(VTabEntry) + sizeof(VTabStaticDims),
		BE_FAILED_ASSERTION);
    *dims = *(VTabStaticDims*)(vte+1);

    MemUnlock(vtHeap);
    return;
}

/*********************************************************************
 *			VTGetSize
 *********************************************************************
 * SYNOPSIS:	Get the size of a variable table
 * CALLED BY:	EXTERNAL
 * RETURN:	size in bytes
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/18/95	Initial version
 * 
 *********************************************************************/
word
VTGetSize(MemHandle vtHeap, word table)
{
    VTabHeap*	vth;
    ChunkHandle* chunk;
    VTab*	vt;
    word	size, dummy;

    vth = MemLock(vtHeap);
    EC_ERROR_IF(table >= ChunkArrayGetCountHandles(vtHeap,vth->VTH_tableArray),
		BE_INVALID_VTAB);
    chunk = ChunkArrayElementToPtrHandles
	(vtHeap, vth->VTH_tableArray, table, &dummy);
    vt = LMemDerefHandles(vtHeap, *chunk);
    size = vt->VT_size;
    MemUnlock(vtHeap);

    return size;
}

/*********************************************************************
 *			VTGetCount
 *********************************************************************
 * SYNOPSIS:	Get # of variables in this table
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/17/95	Initial version
 * 
 *********************************************************************/
word
VTGetCount(MemHandle vtHeap, word table)
{
    VTabHeap*	vth;
    word	count, dummy;
    ChunkHandle* chunk;

    vth = MemLock(vtHeap);

    EC_ERROR_IF(table >= ChunkArrayGetCountHandles(vtHeap,vth->VTH_tableArray),
		BE_INVALID_VTAB);
    chunk = ChunkArrayElementToPtrHandles
	(vtHeap, vth->VTH_tableArray, table, &dummy);
    count = ChunkArrayGetCountHandles(vtHeap, *chunk);

    MemUnlock(vtHeap);
    return count;
}

/*********************************************************************
 *			VTLookup
 *********************************************************************
 * SYNOPSIS:	Look up a variable in a VTab
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/16/95	Initial version
 * 
 *********************************************************************/
Boolean
VTLookup(MemHandle vtHeap, word table, word nameId,
	 VTabEntry* retVte, word* elt)
{
    VTabEntry*	vte;

#if ERROR_CHECK
    if (retVte) EC_BOUNDS(retVte);
#endif

    (void) MemLock(vtHeap);

    vte = VT_LookupLow(vtHeap, table, nameId, elt);

    if (vte)
    {
	/* if the funcNumber is -1 its been deleted */
	if (vte->VTE_funcNumber != (word)-1)
	{
	    if ( retVte ) {
		*retVte = *vte;
	    }
	}
	else
	{
	    vte = NULL;
	}
    }
    MemUnlock(vtHeap);

    
    return ( vte != NULL );
}

/*********************************************************************
 *			VT_LookupLow
 *********************************************************************
 * SYNOPSIS:	Return pointer to VTabEntry
 * CALLED BY:	INTERNAL, VTAdd VTLookup
 * RETURN:	NULL if not found (elt will be CA_NULL_ELEMENT)
 * SIDE EFFECTS:
 * STRATEGY:
 *	Note: Make sure heap is locked.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/16/95	Initial version
 * 
 *********************************************************************/
VTabEntry*
VT_LookupLow(MemHandle vtHeap, word table, word nameId, word* elt)
{
    VTabHeap*		vth;
    ChunkHandle*	chunk;

    optr		array;
    ChunkArrayHeader*	cah;
    register VTabEntry*	vte;
    register word	i;
    word		nEntries, dummy;

#if ERROR_CHECK
    if (elt) EC_BOUNDS(elt);
#endif

    vth = MemDeref(vtHeap);

    /* Find chunkhandle of chunkarray corresponding to table
     */
    EC_ERROR_IF(table >= ChunkArrayGetCountHandles(vtHeap,vth->VTH_tableArray),
		BE_INVALID_VTAB);
    chunk = ChunkArrayElementToPtrHandles
	(vtHeap, vth->VTH_tableArray, table, &dummy);

    array = ConstructOptr(vtHeap, *chunk);

    cah = LMemDeref(array);
    nEntries = cah->CAH_count;

    /* Search for entry with matching name
     */
    for (i=0; i<nEntries; i++)
    {
	vte = ChunkArrayElementToPtr(array, i, &dummy);
	if (vte->VTE_name == nameId)
	{
	    if ( elt ) *elt = i;
	    return vte;
	}
    }

    if ( elt ) *elt = CA_NULL_ELEMENT;
    return NULL;
}



/*********************************************************************
 *			VTResetGlobalsForFunction
 *********************************************************************
 * SYNOPSIS:	reset all the funcnumbers for globals from a function
 * CALLED BY:	VarAnalyzeFunction
 * RETURN:  	nothing
 * SIDE EFFECTS:
 * STRATEGY:	    	mark all globals for this function as being
 *	    	    	gone updating oldOffset and setting funcnumber
 *	    	    	to -1. If, at the end of variable analyses they
 *	    	    	are still -1, they are no longer in the routine
 *	    	    	and need to be deleted after checking for 
 *	    	    	references for them in the Fixup pass at the end
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/ 8/95	Initial version
 * 
 *********************************************************************/
void
VTResetGlobalsForFunction(MemHandle vtHeap, word funcNumber, Boolean delete)
{
    int	    	c, i;
    VTabEntry	*vte;
    VTabHeap*	vth;
    ChunkHandle* chunk;
    optr	carr;		/* chunkarray */
    word    	size;

    c = VTGetCount(vtHeap, GLOBAL_VTAB);

    vth = MemLock(vtHeap);
    for (i = 0; i < c; i++)
    {
	EC_ERROR_IF(GLOBAL_VTAB >= 
		    ChunkArrayGetCountHandles(vtHeap,vth->VTH_tableArray),
		    BE_INVALID_VTAB);
	chunk = ChunkArrayElementToPtrHandles
	    (vtHeap, vth->VTH_tableArray, GLOBAL_VTAB, &size);
	carr = ConstructOptr(vtHeap, *chunk);

	EC_ERROR_IF(i >= ChunkArrayGetCount(carr), BE_FAILED_ASSERTION);
    
	vte = ChunkArrayElementToPtr(carr, i, &size);
	if (vte->VTE_funcNumber == funcNumber)
	{
	    vte->VTE_funcNumber = -1;
	}
	else if (delete && vte->VTE_funcNumber > funcNumber)
	{
	    /* adjust all the higher function numbers since we are
	     * deleting the funcNumber passed in.
	     */
	    --vte->VTE_funcNumber;
	}
    }
    MemUnlock(vtHeap);
}

/*********************************************************************
 *			VT_SortByOffsetCB
 *********************************************************************
 * SYNOPSIS:	Sorting callback
 * CALLED BY:	INTERNAL VT_CreateIndex
 * RETURN:	-1 if el1 < el2, 1 if el1 > el2, fatal error otherwise
 * SIDE EFFECTS:
 * STRATEGY:
 *	*el1 and *el2 are indices into a vtab.  They happen to point
 *	to a chunkarray within the vtab heap.  Thus we can get the
 *	memhandle to the vtab heap from them.
 *
 *	We could use VTLookupIndex to get at the entries, but our
 *	caller thoughtfully provided us with the chunkhandle to
 *	the VTab; use that instead.  The two give us an optr, yay.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/14/95	Initial version
 * 
 *********************************************************************/
sword _pascal
VT_SortByOffsetCB(void* el1, void* el2, word valueForCallback)
{
    MemHandle	vtHeap;
    optr	vtabArray;
    VTabEntry	*vte1, *vte2;

    vtHeap = ((LMemBlockHeader*)((dword)el1&0xffff0000))->LMBH_handle;
    vtabArray = ConstructOptr(vtHeap, valueForCallback);
    vte1 = ChunkArrayElementToPtr(vtabArray, *(word*)el1, NULL);
    vte2 = ChunkArrayElementToPtr(vtabArray, *(word*)el2, NULL);
    EC_ERROR_IF(vte1->VTE_offset == vte2->VTE_offset, BE_FAILED_ASSERTION);

    if (vte1->VTE_offset > vte2->VTE_offset) {
	return 1;
    } else {
	return -1;
    }
}

/*********************************************************************
 *			VTCreateIndex
 *********************************************************************
 * SYNOPSIS:	Create index of a vtab, sorted by offset, to pass to
 *		VTCompactUncompactGlobals
 * CALLED BY:	EXTERNAL
 * RETURN:	Chunkarray of vtab indices
 *		Chunk sits in vtab heap.
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/14/95	Initial version
 * 
 *********************************************************************/
optr
VTCreateIndex(MemHandle vtHeap, word table)
{
    VTabHeap*	vth;
    ChunkHandle	indexChunk, vtabChunk;
    optr	index, vtabArray;
    word	i, count;
    CASProcPtr	funcPtr;

    /* Avoid a highc push cs */
    funcPtr = &VT_SortByOffsetCB;
    
    /* vtabArray is array of chunkhandles
     */
    vth = MemLock(vtHeap);
    vtabArray = ConstructOptr(vtHeap, vth->VTH_tableArray);
    vtabChunk = *(ChunkHandle*)ChunkArrayElementToPtr(vtabArray, table, NULL);
    count = ChunkArrayGetCountHandles(vtHeap, vtabChunk);

    /* Use swat to get in here */
#if 0
	VTabEntry* vte;
	vte = ChunkArrayElementToPtrHandles(vtHeap, vtabChunk, 0, NULL);
	vte->VTE_offset = 5;
	vte = ChunkArrayElementToPtrHandles(vtHeap, vtabChunk, 1, NULL);
	vte->VTE_offset = 0;
#endif

    /* Create and initialize an identity permutation
     * Invalidates *vth
     */
    indexChunk = ChunkArrayCreate(vtHeap, sizeof(word), 0, 0);
    index = ConstructOptr(vtHeap, indexChunk);
    for (i=0; i<count; i++)
    {
	word*	newElt;
	newElt = ChunkArrayAppend(index, 0);
	*newElt = i;
    }

    ChunkArraySort(index, vtabChunk, funcPtr);
    MemUnlock(vtHeap);
    return index;
}

/*********************************************************************
 *			VTCompactGlobals
 *********************************************************************
 * SYNOPSIS:	adjust global variables offsets taking into account
 *	    	unsed globals which have been deleted
 * CALLED BY:	LabelFixupGlobalRefs
 * RETURN:  	number of globals deleted
 * SIDE EFFECTS:
 * STRATEGY:	    	any globals with funcNumber of -1 are no longer
 *	    	    	around, so adjust all other global offsets
 *	    	    	this needs to be done before LabelFixedGlobalRefs
 *	    	    	so we know which globals moved (of any)
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/ 8/95	Initial version
 * 
 *********************************************************************/

/* an "array" of vte, in order of ascending vte_offset */
#define VTE_BYOFFSET(_i) ChunkArrayElementToPtr(globalVtab, index[_i], &dummy)

/* an "array" of vte, in normal by-index order */
#define VTE_BYINDEX(_i) ChunkArrayElementToPtr(globalVtab, _i, &dummy)

word
VTCompactUncompactGlobals(MemHandle vtHeap, optr indexOptr, Boolean uncompact)
{
    optr	globalVtab;	/* chunkarray, used in macro */
    word	dummy;		/* used in macro */

    int	    	c, i;
    VTabEntry	*vte;
    VTabHeap	*vth;
    word	vtOffset, vtIndex, numDeleted;

    word*	index;		/* Treat index like a c array */

    vth = MemLock(vtHeap);
    c = ChunkArrayGetCount(indexOptr);

    /* Set up index and globalVTab */
    ;{
	ChunkArrayHeader*	cah;
	cah = LMemDeref(indexOptr);
	index = (word*)FIXED_CA_FIRST_ELEMENT(cah);

	EC_ERROR_IF(GLOBAL_VTAB >= 
		    ChunkArrayGetCountHandles(vtHeap,vth->VTH_tableArray),
		    BE_INVALID_VTAB);
	globalVtab = ConstructOptr
	    (vtHeap, *(word*)ChunkArrayElementToPtrHandles
	     (vtHeap, vth->VTH_tableArray, GLOBAL_VTAB, NULL));
    }

    for (numDeleted=vtOffset=vtIndex=0, i=0; i < c; i++)
    {
	/* update our offset skipping "deleted" entries.
	 * don't skip if we're uncompacting
	 */
	vte = VTE_BYOFFSET(i);
	if (vte->VTE_funcNumber == (word)-1) numDeleted++;
	if (uncompact || (vte->VTE_funcNumber != (word)-1))
	{
	    vte->VTE_offset = vtOffset;
	    vtOffset += vte->VTE_size;
	}

	/* update our index skipping "deleted" entries.
	 * don't skip if we're uncompacting
	 */
	vte = VTE_BYINDEX(i);
	if (uncompact || (vte->VTE_funcNumber != (word)-1))
	{
	    vte->VTE_index = vtIndex;
	    vtIndex += 1;
	} 
    }
    MemUnlock(vtHeap);
    return numDeleted;
}

/*********************************************************************
 *			VTCompactGlobals
 *********************************************************************
 * SYNOPSIS:	adjust global variables offsets taking into account
 *	    	unsed globals which have been deleted
 * CALLED BY:	LabelFixupGlobalRefs
 * RETURN:  	number of globals deleted
 * SIDE EFFECTS:
 * STRATEGY:	    	any globals with funcNumber of -1 are no longer
 *	    	    	around, so adjust all other global offsets
 *	    	    	this needs to be done before LabelFixedGlobalRefs
 *	    	    	so we know which globals moved (of any)
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/ 8/95	Initial version
 * 
 *********************************************************************/
word
VTCompactUncompactGlobals_old(MemHandle vtHeap, Boolean uncompact)
{
    int	    	c, i;
    VTabEntry	*vte;
    VTabHeap	*vth;
    ChunkHandle* chunk;
    optr	carr;		/* chunkarray */
    word	size, vtOffset=0;
    word    	delta = 0;

    /* Assumes that vtab is sorted by offset
     */
    c = VTGetCount(vtHeap, GLOBAL_VTAB);
    vth = MemLock(vtHeap);
    for (i = 0; i < c; i++)
    {
	EC_ERROR_IF(GLOBAL_VTAB >= 
		    ChunkArrayGetCountHandles(vtHeap,vth->VTH_tableArray),
		    BE_INVALID_VTAB);
	chunk = ChunkArrayElementToPtrHandles
	    (vtHeap, vth->VTH_tableArray, GLOBAL_VTAB, &size);
	carr = ConstructOptr(vtHeap, *chunk);

	EC_ERROR_IF(i >= ChunkArrayGetCount(carr), BE_FAILED_ASSERTION);
    
	vte = ChunkArrayElementToPtr(carr, i, &size);
	if (uncompact)
	{
	    vte->VTE_offset = vtOffset;
	    vte->VTE_index = i;
	    vtOffset += vte->VTE_size;
	} 
	else if (vte->VTE_funcNumber != (word)-1)
	{
	    /* update our offset skipping "deleted" entries */
	    vte->VTE_offset = vtOffset;
	    vtOffset += vte->VTE_size;
	    vte->VTE_index = i - delta;
	}
	else
	{
	    /* we get one change per deleted element, and it affects
	     * all elements following the deleted one
	     */
	    delta++;
	}
    }
    MemUnlock(vtHeap);
    return delta;
}



/*********************************************************************
 *			VTDeleteUnusedGlobals
 *********************************************************************
 * SYNOPSIS:	just cleans out unneeded entries
 * CALLED BY:	LabelFixupGlobalRefs
 * RETURN:  	nothing
 * SIDE EFFECTS:
 * STRATEGY:	    	we can't do this in the same pass as the compact
 *	    	    	pass, as we need the unsed entries around during
 *	    	    	fixups to see if there are still references to
 *	    	    	deleted globals lying around
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/ 8/95	Initial version
 * 
 *********************************************************************/
void
VTDeleteUnusedGlobals(MemHandle vtHeap)
{
    int	    	c, i;
    VTab    	*vtab;
    VTabEntry	*vte;
    VTabHeap	*vth;
    ChunkHandle* chunk;
    optr	carr;		/* chunkarray */
    word	size;
    

    c = VTGetCount(vtHeap, GLOBAL_VTAB);

    vth = MemLock(vtHeap);
    for (i = 0; i < c;)
    {
	EC_ERROR_IF(GLOBAL_VTAB >= 
		    ChunkArrayGetCountHandles(vtHeap,vth->VTH_tableArray),
		    BE_INVALID_VTAB);
	chunk = ChunkArrayElementToPtrHandles
	    (vtHeap, vth->VTH_tableArray, GLOBAL_VTAB, &size);
	carr = ConstructOptr(vtHeap, *chunk);

	EC_ERROR_IF(i >= ChunkArrayGetCount(carr), BE_FAILED_ASSERTION);
    
	vte = ChunkArrayElementToPtr(carr, i, &size);
	if (vte->VTE_funcNumber == (word)-1)
	{
	    /* adjust the size of the size */
	    vtab = LMemDeref(carr);
	    vtab->VT_size -= vte->VTE_size;
	    ChunkArrayDelete(carr, vte);
	    c--;
	}
	else
	{
	    EC_ERROR_IF(vte->VTE_index != i, BE_FAILED_ASSERTION);
	    i++;
	}
    }
    MemUnlock(vtHeap);
}





/*********************************************************************
 *			VTCompareTables
 *********************************************************************
 * SYNOPSIS:	compare two tables to see if they are the same
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	7/ 8/96  	Initial version
 * 
 *********************************************************************/
Boolean 
VTCompareTables(MemHandle vtHeap, word t1, word t2)
{
    int	    count, i, diff;
    word	size;
    optr    carr1, carr2;
    ChunkHandle	*c1, *c2;
    VTabHeap	*vth;
    
    if ((count = VTGetCount(vtHeap, t1)) != VTGetCount(vtHeap, t2))
    {
	return TRUE;
    }

    vth = MemLock(vtHeap);

    c1 = ChunkArrayElementToPtrHandles(vtHeap, vth->VTH_tableArray, 
				       t1, &size);
    carr1 = ConstructOptr(vtHeap, *c1);
    c2 = ChunkArrayElementToPtrHandles(vtHeap, vth->VTH_tableArray, 
				       t2, &size);

    carr2 = ConstructOptr(vtHeap, *c2);
    diff = FALSE;

    for (i = 0; i < count; i++)
    {
	VTabEntry   *e1, *e2;

	e1 = ChunkArrayElementToPtr(carr1, i, &size);
	e2 = ChunkArrayElementToPtr(carr2, i, &size);
	if (e1->VTE_type != e2->VTE_type ||
	    e1->VTE_name != e2->VTE_name)
	{
	    diff = TRUE;
	    break;
	}
    }
    MemUnlock(vtHeap);
    return diff;
}





