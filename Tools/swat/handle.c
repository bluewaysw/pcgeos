/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- handle tracking.
 * FILE:	  handle.c
 *
 * AUTHOR:  	  Adam de Boor: Aug 10, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Handle_Init	    Initialize the module.
 *	Handle_Find	    Find a Handle encompassing an address.
 *	Handle_Lookup	    Find a Handle given its 16-bit id #.
 *	Handle_ID 	    Return the ID # of the handle.
 *	Handle_Address	    Return the real address of a handle.
 *	Handle_Segment	    Return segment address of a handle
 *	Handle_State	    Return the state of a handle.
 *	Handle_Owner	    Return the id # for the owner of the handle
 *	Handle_Patient	    Return the Patient structure for the owner of
 *	    	  	    the handle
 *	Handle_Size	    Return the number of bytes allocated to the handle.
 *	Handle_Interest	    Register interest in a handle by a
 *	    	  	    (procedure, data) pair.
 *	Handle_NoInterest   Unregister interest for a (procedure, data) pair.
 *	Handle_Create	    Create a handle with the given attributes.
 *			    USED BY THE IBM MODULE ONLY. Calls appropriate
 *			    interest procedures.
 *	Handle_Change	    Change the data parameters for a handle. Calls
 *	    	    	    appropriate interest procedures.
 *	Handle_Reset	    Reset the parameters for a resource handle.
 *	Handle_TypeStruct   Return Type token for structure describing
 *	    	    	    a given non-memory handle.
 *
 * REVISION HISTORY:
 *	Date	    Name    Description
 *	----	    ----    -----------
 *	8/10/88	    ardeb   Initial version
 *	5/3/89	    ardeb   Added handle caching
 *
 * DESCRIPTION:
 *	Module to track the allocation of memory in PC GEOS.
 *
 *	The abstraction provided by this module serves to insulate most
 *	of the debugger from the innards of the memory allocation scheme
 *	GEOS uses.
 *
 *	Most references to memory by the debugger make use of a Handle,
 *	allowing the stub on the PC to swap in blocks as necessary.
 *
 *	A client module can register interest in what happens to a handle
 *	and its associated block by calling Handle_Interest and passing
 *	it a procedure and a piece of data. Whenever the block changes
 *	its state, the procedure will be called with the handle, type
 *	of change and the piece of data it gave as arguments. This is
 *	intended for such modules as Break, where a module's breakpoints
 *	must be installed each time the module is loaded.
 *
 *	Clients must be prepared for these functions to return NULL on
 *	error. E.g. if a client requests the handle for an address and no
 *	such handle exists, Handle_Find will return NullHandle.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: handle.c,v 4.30 97/04/18 15:30:47 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cmd.h"
#include "event.h"
#include "handle.h"
#include "ibmInt.h"
#include "rpc.h"
#include "type.h"
#include "expr.h"
#include "gc.h"
#include <compat/stdlib.h>

#define size_t	ickyickyickyphtang
#include <stddef.h>
#undef size_t

/*
 * Structure used to track GEOS's use of handles for breakpoints and
 * suchlike. THE FIRST PART MUST MATCH THAT IN SWAT.H.
 */
typedef struct _Handle {
    /*
     * Public portion
     */
    Opaque  	    otherInfo;	/* Other information:
				 *  Sym of module if RESOURCE
				 */
    /*
     * Private portion
     */
    Address 	    segment;   	/* Actual address of handle */
    word   	    id;	    	/* PC GEOS handle number */
    word    	    ownerId;  	/* ID of owner of handle */
    Patient 	    patient;	/* Owner of handle */
    long    	    state;    	/* Handle's state */
    dword    	    size;    	/* Size of block. This is a dword b/c of the
				 * BIOS resource handle for the kernel. Also,
				 * there's no way to represent a 64k block
				 * otherwise. */
    unsigned	    gen;    	/* Generation number, updated to match the
				 * current generation each time the handle's
				 * data are refreshed. */
    word    	    xipPage;	/* xip page number, or -1 if none */
    Lst	    	    interest; 	/* Callback procedures for state changes */
} HandleRec, *HandlePtr;

/*
 * Record in a handle's interest chain.
 */
typedef struct {
    HandleInterestProc	*interestProc;
    Opaque  	    	data;
} HInterestRec, *HInterestPtr;
static void HandleCallInterest(HandlePtr, Handle_Status);

static Handle HandleValidate(Handle);
static Handle HandleUpdate(Handle, Handle, Address, long, long, word);

/*
 * All known handles
 */
static Hash_Table   handles;

/*
 * A counter that is incremented each time the machine is continued in any
 * way. Any handle that doesn't have HANDLE_ATTACHED set is assumed invalid
 * if its generation number doesn't match this. The HandleValid macro can
 * be used to determine if a handle is known to be valid.
 */
static unsigned	    generation = 0;
#define HandleValid(hp) ((((HandlePtr)(hp))->state & (HANDLE_ATTACHED|HANDLE_KERNEL)) || \
			 (((HandlePtr)(hp))->gen == generation))

#define HandleRetain(flags) ((flags & HANDLE_KERNEL) || Handle_IsThread(flags))

/*
 * Cache of last 10 handles found by address. On continue, handleACLen is
 * set to 0. The idea here is to avoid the 430 (avg) calls to Hash_EnumNext
 * traversing the entire hash table to find something, when most of the
 * entries in the table are not up-to-date.
 */
#define HANDLE_MAX_ADDR_CACHE	10
static HandlePtr    handleAddrCache[HANDLE_MAX_ADDR_CACHE];
static int  	    handleACLen = 0;

/*
 * Communication types
 */
static Type 	    typeFindArgs;
static Type 	    typeFindReply;  /* Type for RPC_BLOCK_FIND reply */
static Type    	    typeInfoReply;  /* Type for RPC_BLOCK_INFO reply */
static Type 	    type2WordArg;   /* Type for BLOCK_IN, BLOCK_OUT, 
				     * BLOCK_LOAD, and BLOCK_CHANGE args */
static Type 	    typeReallocArg; /* Type for BLOCK_REALLOC */

/***********************************************************************
 *				HandleAttach
 ***********************************************************************
 * SYNOPSIS:	    Make sure a handle is attached and won't be flushed
 * CALLED BY:	    Handle_Create, Handle_Change, Handle_Interest
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The handle will be removed from the cached list, if
 *	    	    present. RPC_BLOCK_ATTACH will be called if not
 *	    	    already attached.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 3/89		Initial Revision
 *
 ***********************************************************************/
static void
HandleAttach(HandlePtr	hp)
{
    if ((hp->state & (HANDLE_ATTACHED|HANDLE_KERNEL)) == 0) {
	word	id = hp->id;

	/* Caller must have already validated this handle */
	assert(hp->gen == generation);
	
	if (Handle_IsMemory(hp->state) &&
	    Rpc_Call(RPC_BLOCK_ATTACH,
		     sizeof(id), type_Word, (Opaque)&id,
		     0, NullType, NullOpaque) != RPC_SUCCESS)
	{
	    dprintf("Couldn't attach to handle %04xh: %s\n", hp->id,
		    Rpc_LastError());
	} else {
	    hp->state |= HANDLE_ATTACHED;
	}
    }
}

/***********************************************************************
 *				HandleDetach
 ***********************************************************************
 * SYNOPSIS:	    Detach from a handle, if attached
 * CALLED BY:	    Handle_Change, Handle_NoInterest
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Handle is placed on the cached list if not already
 *	    	    there. RPC_BLOCK_DETACH is called, too
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 3/89		Initial Revision
 *
 ***********************************************************************/
static void
HandleDetach(HandlePtr	hp)
{
    if (hp->state & HANDLE_ATTACHED) {
	word	id = hp->id;

	if (Handle_IsMemory(hp->state) &&
	    Rpc_Call(RPC_BLOCK_DETACH,
		     sizeof(id), type_Word, (Opaque)&id,
		     0, NullType, NullOpaque) != RPC_SUCCESS)
	{
	    dprintf("Couldn't detach from handle %04xh: %s\n", hp->id,
		    Rpc_LastError());
	    return;
	} else {
	    hp->state &= ~HANDLE_ATTACHED;
	}
    }
}

/***********************************************************************
 *				HandleFlush
 ***********************************************************************
 * SYNOPSIS:	    Nuke all unattached, cached handles
 * CALLED BY:	    EVENT_DETACH, EVENT_CONTINUE
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 3/89		Initial Revision
 *
 ***********************************************************************/
static int
HandleFlush(Event   	event,
	    Opaque  	callData,
	    Opaque	clientData)
{
    /*
     * Up the generation number so we know anything not attached is invalid
     */
    generation += 1;

    /*
     * Flush the by-address cache
     */
    handleACLen = 0;

    return(EVENT_HANDLED);
}

/***********************************************************************
 *				HandleConvertFlags
 ***********************************************************************
 * SYNOPSIS:	    Convert from GEOS handle flags to SWAT flags
 * CALLED BY:	    Handle_Lookup and Handle_Find
 * RETURN:	    The proper flags for the handle or -1 if the flags
 *	    	    make no sense.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/15/88	Initial Revision
 *
 ***********************************************************************/
static int
HandleConvertFlags(word geosFlags, word dataAddress, word id)
{
    long    flags;

    if (dataAddress >= SIG_NON_MEM) {
	/*
	 * The HANDLE_TYPE field for a non-memory handle is simply
	 * bits 8-11 shifted left 8 bits (can't just shift it up four
	 * since f0 is a valid signature and we need some way to know
	 * that a handle is a memory handle...)
	 */
	flags = ((long)dataAddress & 0x0f00) << 8;
    } else {
	/*
	 * Must be a memory handle of some sort, so geosFlags are for real.
	 */
	flags = HANDLE_MEMORY;
	
	if (geosFlags & FIXED) {
	    flags |= HANDLE_FIXED;
	}
	if (geosFlags & SHARABLE) {
	    flags |= HANDLE_SHARED;
	}
	if (geosFlags & DISCARDABLE) {
	    flags |= HANDLE_DISCARDABLE;
	}
	if (geosFlags & SWAPABLE) {
	    flags |= HANDLE_SWAPABLE;
	}
	if (geosFlags & LMEM) {
	    flags |= HANDLE_LMEM;
	}
	
	if ((geosFlags & FIXED) && (geosFlags & ~(FIXED|SHARABLE|DEBUG|LMEM|DISCARDABLE))) {
	    Warning("%04xh: FIXED block with bogus other bits (%02xh)", id,
		    geosFlags & ~(FIXED|SHARABLE|DEBUG|LMEM|DISCARDABLE));
	    return(-1);
	}
	
	if (dataAddress == 0) {
	    if (geosFlags & FIXED) {
		Warning("%04xh: non-resident FIXED block", id);
		return(-1);
	    }
	    if (geosFlags & DISCARDED) {
		flags |= HANDLE_DISCARDED;
	    } else {
		flags |= HANDLE_SWAPPED;
	    }
	} else {
	    flags |= HANDLE_IN;
	}
    }
    return(flags);
}



/***********************************************************************
 *				Handle_Find
 ***********************************************************************
 * SYNOPSIS:	  Find a handle that encompasses an address
 * CALLED BY:	  GLOBAL
 * RETURN:	  The Handle token for that block
 * SIDE EFFECTS:
 *	The stub may be called to locate the information and a HandleRec
 *	entered into the hash table.
 *
 * STRATEGY:
 *	First search through the table looking for an existing handle
 *	that covers the block. If none, call the target for the info.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/12/88		Initial Revision
 *
 ***********************************************************************/
Handle
Handle_Find(Address 	address)    /* Address that the handle should contain.
				     * This is a 32-bit address. */
{
    Hash_Search	  	search;	    /* Thing used to traverse the table */
    Hash_Entry	  	*entry;	    /* Current entry in table */
    HandlePtr	  	hp; 	    /* Current handle */
    FindReply	  	fr; 	    /* Reply from BLOCK_FIND rpc */
    FindArgs	    	fa; 	    /* args to BLOCK_FIND */
    word    	    	segment;    /* Segment-equivalent of address */
    int	    	    	i;
    
    /*
     * Look in our cache first.
     */
    for (i = 0; i < handleACLen; i++) {
	hp = handleAddrCache[i];
	if ((hp->segment <= address) && (address < hp->segment + hp->size) &&
	   (hp->xipPage == curXIPPage || hp->xipPage == HANDLE_NOT_XIP)) {
	    /*
	     * Found it -- move the handle up to the head of the cache.
	     */
	    while (i > 0) {
		handleAddrCache[i] = handleAddrCache[i-1];
		i--;
	    }
	    handleAddrCache[0] = hp;
	    return((Handle)hp);
	}
    }

    /*
     * Traverse the table looking for a handle that covers the address
     * range.
     */
    for (entry = Hash_EnumFirst(&handles, &search);
	 entry != (Hash_Entry *)NULL;
	 entry = Hash_EnumNext(&search))
    {
	hp = (HandlePtr)Hash_GetValue(entry);
	if (HandleValid(hp) &&
	    (hp->state & HANDLE_IN) && (hp->segment <= address) &&
	    (address < hp->segment + hp->size) && 
	    (hp->xipPage == curXIPPage || hp->xipPage == HANDLE_NOT_XIP))
	{
	    goto done;
	}
    }

    /*
     * Nope. Ask the stub to do the same thing.
     */
    segment = SegmentOf(address) ;
    fa.fa_address = segment;
    fa.fa_xipPage = curXIPPage;
    if (Rpc_Call(RPC_BLOCK_FIND,
		 sizeof(fa), typeFindArgs, (Opaque)&fa,
		 sizeof(fr), typeFindReply, (Opaque)&fr))
    {
/*	dprintf("Couldn't find handle covering %x", address);*/
	return (NullHandle);
    }
    else
    {
	Handle 	    owner;

	owner = Handle_Lookup(fr.fr_owner);
	if (owner == NullHandle) {
	    /*
	     * Owner was ignored -- can't tell the caller anything.
	     */
	    return(NullHandle);
	}

	if (fr.fr_id == fr.fr_owner) {
	    /*
	     * All the work done for us by Handle_Lookup.
	     * 5/4/94: to cope with having looked up a geode handle during the
	     * loading of the geode, when it didn't own itself, make sure
	     * here that the HandleRec reflects the knowledge returned us by
	     * RPC_BLOCK_FIND, namely that the block is supposed to own itself.
	     * If the HandleRec and the FindReply disagree, we need to validate
	     * the handle here to get the proper info in it. -- ardeb
	     */
	    hp = (HandlePtr)owner;
	    if (hp->ownerId != fr.fr_id) {
		HandleValidate(owner);
	    }
	} else {
	    int	flags = HandleConvertFlags(fr.fr_flags, fr.fr_dataAddress,
					   fr.fr_id);

	    if (flags == -1) {
		return(NullHandle);
	    } else {
		/*
		 * Lookup of owner could well have created this handle.
		 * If we just create the thing without checking for this,
		 * we'll thrash the flags and be generally unhappy.
		 */
		entry = Hash_FindEntry(&handles, (Address)fr.fr_id);

		if (entry == (Hash_Entry *)NULL) {
		    hp = (HandlePtr)Handle_Create(((HandlePtr)owner)->patient,
						  fr.fr_id,
						  owner,
                                                  MakeAddress(fr.fr_dataAddress, 0),
						  fr.fr_paraSize << 4,
						  flags,
						  (Opaque)(dword)fr.fr_otherInfo,
						  fr.fr_xipPage);
		} else {
		    hp = (HandlePtr)HandleUpdate((Handle)Hash_GetValue(entry),
						 owner,
                                                 MakeAddress(fr.fr_dataAddress, 0),
						 fr.fr_paraSize <<  4,
						 flags,
						 fr.fr_xipPage);
		}
	    }
	}

	/* if the flags are zero, then its a fake block, and we don't want
	 * Handle_Find to return fake blocks as they are aren't meaningful, but
	 * in XIP systems, a FAKE block covers the mapped in addresses so
	 * if we set the size to zero, Handle_Find won't realize that the
	 * FAKE block is covering that address, so it will return the 
	 * appropriate thing...jimmy 5/94
	 */
	if (!fr.fr_flags) {
	    hp->size = 0;
	}
    }
    /*
     * Store the handle at the front of the cache, if we've actually got
     * something.
     */
    if (hp != (HandlePtr)NULL) {
	/*
	 * If the cache isn't full, up the length by one.
	 */
    done:

	if (handleACLen != HANDLE_MAX_ADDR_CACHE) {
	    handleACLen++;
	}
	/*
	 * Shift everything in the cache up one.
	 */
	for (i = handleACLen-1; i > 0; i--) {
	    handleAddrCache[i] = handleAddrCache[i-1];
	}
	/*
	 * Store this handle in slot 0.
	 */
	handleAddrCache[0] = hp;
    }
    return((Handle)hp);
}


/***********************************************************************
 *				Handle_SetOwner
 ***********************************************************************
 * SYNOPSIS:	Set the real patient to own a core block handle, now
 *	    	the patient-dependent interface has created/found the
 *	    	Patient record. This must be done before any handles are
 *	    	created or reset that are owned by the passed handle,
 *	    	else all those handles will be pointed to the wrong
 *	    	patient.
 *
 * CALLED BY:	patient-dependent interface
 * RETURN:	nothing
 * SIDE EFFECTS:the handle is made to own itself, with the passed patient
 *	    	token recorded as the owning one.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/91		Initial Revision
 *
 ***********************************************************************/
void
Handle_SetOwner(Handle	    handle,
		Patient	    patient)
{
    HandlePtr	hp = (HandlePtr)handle;
    
    assert(VALIDTPTR(handle, TAG_HANDLE));
    assert(patient->resources != NULL);
    hp->ownerId = hp->id;
    hp->patient = patient;
}


/***********************************************************************
 *				Handle_Lookup
 ***********************************************************************
 * SYNOPSIS:	  Find a handle by handle ID
 * CALLED BY:	  GLOBAL, Handle_Create
 * RETURN:	  The given Handle, or NullHandle
 * SIDE EFFECTS:
 *	None.
 *
 * STRATEGY:
 *	Just does a hash-table lookup of the ID.
 *	If it's not there, call the PC (RPC_BLOCK_INFO) to get the lowdown
 *	on the handle.
 *	If it owns itself, it must be a process handle, so call
 *	    Ibm_NewGeode on it.
 *	Else, find its owner's Handle and call Handle_Create to enter it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/12/88		Initial Revision
 *
 ***********************************************************************/
Handle
Handle_Lookup(word	id) 	/* Handle ID to find. */
{
    Hash_Entry	  	*entry;

    entry = Hash_FindEntry(&handles, (Address)id);
    
    if (entry == (Hash_Entry *)NULL) {
	InfoReply   ir;
	word	    sacrificeID = id;

	/*
	 * Make sure the handle ID is paragraph-aligned. Other checks are done
	 * in the stub....
	 */
	if ((id & 0xf) || (id==0)) {
	    return(NullHandle);
	}

	if (Rpc_Call(RPC_BLOCK_INFO,
		     sizeof(word), type_Word, (Opaque)&sacrificeID,
		     sizeof(ir), typeInfoReply, (Opaque)&ir) != RPC_SUCCESS)
	{
	    dprintf("Couldn't lookup handle %xh: %s\n", id, Rpc_LastError());
	    return(NullHandle);
	} else {
	    int 	flags;
	    
	    flags = HandleConvertFlags(ir.ir_flags, ir.ir_dataAddress, id);
	    if (flags == -1) {
		return(NullHandle);
	    }

	    if (id == ir.ir_owner) {
		/*
		 * If the handle owns itself, it must be a geode's core block.
		 * Since we've never heard of it before, it must be a geode/
		 * patient we don't know about, so go create it and initialize
		 * it properly.
		 * 9/5/91: to deal with core blocks that might be swapped out,
		 * we need to actually create a handle and enter it before
		 * calling Ibm_NewGeode. This makes its life easier when
		 * fetching data from the core block, and, more importantly,
		 * allows us to track if the block gets swapped back in again
		 * by the act of reading things from the core block. Since we
		 * don't have a Patient handle yet, we initially make the
		 * thing owned by the kernel. Ibm_NewGeode must call
		 * Handle_SetOwner when it has determined it can actually
		 * attach to the patient and has created the Patient
		 * record for it. -- ardeb
		 *
		 */
		Handle	h;
		Patient	patient;

		if (ir.ir_flags & DISCARDED) {
		    /*
		     * A discarded core block is an XIP geode that has not been
		     * loaded yet. We refuse to find such handles or things
		     * owned by such handles as it confuses the issue
		     * 	    	-- ardeb 10/16/95
		     */
		    return(NullHandle);
		}

		h = Handle_Create(loader, id, loader->core,
                                  MakeAddress(ir.ir_dataAddress, 0),
				  ir.ir_paraSize << 4,
				  flags|HANDLE_PROCESS,
				  0,
				  ir.ir_xipPage);
		/*
		 * Attach to the handle to make sure that if the stub is forced
		 * to swap the thing in we actually get notified.
		 */
		HandleAttach((HandlePtr)h);
		patient = Ibm_NewGeode(h,
				       id,
                                       MakeAddress(ir.ir_dataAddress, 0),
				       ir.ir_paraSize << 4);
		if (patient == NullPatient) {
		    /*
		     * Throw away the handle we created and return NULL.
		     */
		    Handle_Free(h);
		    h = NullHandle;
		} else if (((HandlePtr)h)->interest == NULL) {
		    /*
		     * If no one else has expressed an interest, we don't much
		     * care about it (the handle will just be marked invalid
		     * when we continue; it won't be freed).
		     */
		    HandleDetach((HandlePtr)h);
		}
		return(h);
	    } else if (Handle_IsThread(flags)) {
		/*
		 * ir_otherInfo is SS, ir_paraSize is maximum SP
		 */
		return(Ibm_NewThread(id, ir.ir_owner,
				     ir.ir_otherInfo,
				     ir.ir_paraSize,
				     TRUE,
				     0));
	    } else if (((flags & HANDLE_TYPE) == HANDLE_EVENT) ||
		       ((flags & HANDLE_TYPE) == HANDLE_EVENT_STACK) ||
		       ((flags & HANDLE_TYPE) == HANDLE_EVENT_DATA) ||
		       ((flags & HANDLE_TYPE) == HANDLE_VM) ||
		       ((flags & HANDLE_TYPE) == HANDLE_DISK))
	    {
		/*
		 * All of the above handle types do not have a valid
		 * HG_owner field. As such, they belong to the kernel.
		 */
		return(Handle_Create(kernel, id,
				     kernel->core,
				     0,
				     0,
				     flags,
				     (Opaque)(dword)ir.ir_otherInfo,
		       	    	     ir.ir_xipPage));
	    } else {
		Handle	owner;	    	/* Owner of this handle */
		
		/*
		 * Recurse to find the owner of the handle (takes care of
		 * ownership by unknown geodes).
		 */
		owner = Handle_Lookup(ir.ir_owner);
		if (owner == NullHandle) {
		    /*
		     * Owner was ignored -- can't do much about this handle
		     */
		    return(NullHandle);
		}

		/*
		 * Lookup of owner could well have created this handle.
		 * If we just create the thing without checking for this,
		 * we'll thrash the flags and be generally unhappy.
		 */
		entry = Hash_FindEntry(&handles, (Address)id);
		
		if (entry == (Hash_Entry *)NULL) {
		    return(Handle_Create(Handle_Patient(owner), id, owner,
                                         MakeAddress(ir.ir_dataAddress, 0),
					 ir.ir_paraSize << 4,
					 flags,
					 (Opaque)(dword)ir.ir_otherInfo,
					 ir.ir_xipPage));
		} else {
		    return((Handle)Hash_GetValue(entry));
		}
	    }
	}
    } else {
	/*
	 * This used to perform a HandleValidate(), but it seems a high price
	 * to pay when attaching and all you want is the handle token so you
	 * can find the patient so you can stuff that into your library table...
	 *  	    	-- ardeb 1/19/94
	 * note: this required putting in two hacks in ibm.c because of
	 * showcalls -L, which caused geode handles to be created while still
	 * owned by the geode loaded the new geode causing all sorts of havoc
	 * as it was not getting updated here...jimmy 5/4/94
	 */
	return(Hash_GetValue(entry));
    }
}


/***********************************************************************
 *				Handle_Reset
 ***********************************************************************
 * SYNOPSIS:	    Reset the parameters for a Handle given its new
 *	    	    handle ID
 * CALLED BY:	    Ibm_NewGeode
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Lots
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 9/89		Initial Revision
 *
 ***********************************************************************/
void
Handle_Reset(Handle 	handle,
	     word   	id)
{
    word    	sacID;
    InfoReply	ir;
    HandlePtr	hp = (HandlePtr)handle;

    if (hp->interest) {
	/*
	 * Make sacrificial copy
	 */
	sacID = id;
	/*
	 * Get the scoop on the handle
	 */
	if (Rpc_Call(RPC_BLOCK_INFO, sizeof(sacID),type_Word,
		     (Opaque)&sacID,
		     sizeof(ir), typeInfoReply, (Opaque)&ir))
	{
	    dprintf("Couldn't find info for %xh: %s\n", id, Rpc_LastError());
	} else {
	    /*
	     * Set existing Handle with new parameters -- it
	     * will call out to interested parties...Note that we must preserve
	     * the RESOURCE and READ_ONLY bits...Note also that if the handle
	     * is pre-loaded and we pass the HANDLE_IN flag to Handle_Change,
	     * a LOAD interest call will never be made, since Handle_Change
	     * won't think the state has changed. Hence we remove the HANDLE_IN
	     * flag from the flags we got back from HandleConvertFlags.
	     *
	     * XXX: Does this need to be solved more generally in
	     * Handle_Change, or is this enough?
	     */
	    int flags = HandleConvertFlags(ir.ir_flags, ir.ir_dataAddress, id);
	    
	    if (flags != -1) {
		/*
		 * Record the current generation number in the handle, so we
		 * know when we refreshed its data.
		 */
		hp->gen = generation;
		
		flags |= (hp->state & (HANDLE_READ_ONLY|HANDLE_RESOURCE));
		if (id == ir.ir_owner) {
		    flags |= HANDLE_PROCESS;
		}
		flags &= ~HANDLE_IN;
		
		Handle_Change(handle,
			      HANDLE_ID|HANDLE_ADDRESS|HANDLE_SIZE|HANDLE_FLAGS,
			      id,
                              MakeAddress(ir.ir_dataAddress, 0),
			      ir.ir_paraSize << 4,
			      flags,
			      ir.ir_xipPage);
		/*
		 * Install the (possibly different) owner ID as well...
		 */
		hp->ownerId = ir.ir_owner;
	    }
	    
	    /*
	     * If someone's expressed an interest in this sucker, attach to it
	     * now...
	     */
	    HandleAttach(hp);
	}
    } else {
	/*
	 * If handle wasn't attached before, we have no need to know its
	 * current parameters. Not even its owner (since that won't have
	 * changed). We simply enter the thing in our table under the
	 * appropriate ID. The generation-number/update stuff will take
	 * care of filling in the details.
	 */
	Hash_Entry  *entry;
	Boolean new;

	entry = Hash_CreateEntry(&handles, (ClientData)id, &new);
	Hash_SetValue(entry, hp);
	hp->id = id;
    }
}

/***********************************************************************
 *				HandleUpdate
 ***********************************************************************
 * SYNOPSIS:	    Update the data in an existing handle based on the
 *	    	    values returned by RPC_BLOCK_FIND or RPC_BLOCK_INFO
 * CALLED BY:	    Handle_Find, Handle_Lookup
 * RETURN:	    The passed handle
 * SIDE EFFECTS:    Most fields in the handle are updated.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/30/90		Initial Revision
 *
 ***********************************************************************/
static Handle
HandleUpdate(Handle 	handle,
	     Handle 	owner,
	     Address	dataAddress,
	     long   	size,
	     long   	flags,
	     word   	xipPage)
{
    /*
     * Maintain previous RESOURCE/PROCESS/READ_ONLY status...
     */
    flags |= ((HandlePtr)handle)->state &
	(HANDLE_RESOURCE|HANDLE_PROCESS|HANDLE_READ_ONLY);

    /*
     * Install the (possibly different) owner ID as well...
     */
    ((HandlePtr)handle)->ownerId = ((HandlePtr)owner)->id;

    /*
     * Because of the new generation number scheme we've got, the handle's
     * patient might require updating, too, as a memory handle might have
     * been invalidated, but remained in our table and now have been reused
     * by another geode.
     */
    ((HandlePtr)handle)->patient = Handle_Patient(owner);

    /*
     * Record the current generation number in the handle, so we know when
     * we refreshed its data.
     */
    ((HandlePtr)handle)->gen = generation;

    /*
     * Now that things are set up so any interest procedures won't get confused,
     * call Handle_Change to update the rest of things and tell the world.
     */
    Handle_Change(handle,
		  HANDLE_ADDRESS|HANDLE_SIZE|HANDLE_FLAGS,
		  0,
		  (Address)dataAddress,
		  size,
		  flags,
		  xipPage);
    return(handle);
}
    

/***********************************************************************
 *				HandleValidate
 ***********************************************************************
 * SYNOPSIS:	Make sure a passed handle contains up-to-date information
 * CALLED BY:	INTERNAL
 * RETURN:	the passed handle
 * SIDE EFFECTS:the data in the handle may be updated
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/30/90		Initial Revision
 *
 ***********************************************************************/
static Handle
HandleValidate(Handle	handle)
{
    HandlePtr	hp = (HandlePtr)handle;

    if ((handle != NullHandle) && !HandleValid(hp)) {
	InfoReply   ir;
	word	    sacrificeID = hp->id;

	if (Rpc_Call(RPC_BLOCK_INFO,
		     sizeof(word), type_Word, (Opaque)&sacrificeID,
		     sizeof(ir), typeInfoReply, (Opaque)&ir) != RPC_SUCCESS)
	{
	    dprintf("Couldn't validate handle %xh: %s\n", hp->id,
		    Rpc_LastError());
	    return(NullHandle);
	} else {
	    int 	flags;
	    Handle	owner;	    	/* Owner of this handle */
	    
	    flags = HandleConvertFlags(ir.ir_flags, ir.ir_dataAddress, hp->id);
	    if (flags == -1) {
		return(NullHandle);
	    }
	    
	    /*
	     * Recurse to find the owner of the handle (takes care of
	     * ownership by unknown geodes).
	     */
	    if (ir.ir_owner != hp->id) {
		owner = Handle_Lookup(ir.ir_owner);
	    } else {
		owner = handle;
		flags |= HANDLE_PROCESS;
	    }
	    
	    if (owner == NullHandle) {
		/*
		 * Owner was ignored -- can't do much about this handle
		 */
		return(NullHandle);
	    }
	    HandleUpdate(handle,
			 owner,
                         MakeAddress(ir.ir_dataAddress, 0),
			 ir.ir_paraSize << 4,
			 flags,
			 ir.ir_xipPage);

	    if ((owner == handle) &&
		((hp->patient->core != handle) ||
		 (Lst_Member(patients, (LstClientData)hp->patient) ==
		  NILLNODE)))
	    {
		/*
		 * Haven't encountered this geode before (handle owns itself
		 * but isn't the core block handle of the patient bound
		 * to it, or it is the core block handle, and the patient
		 * bound to it is dead), so we must play games to have it
		 * created.
		 */
		if (Ibm_NewGeode(handle, hp->id,
                                 MakeAddress(ir.ir_dataAddress, 0),
				 ir.ir_paraSize << 4) == NullPatient)
		{
		    Handle_Free(handle);
		    return(NullHandle);
		}
	    }
	}
    }
    return(handle);
}
	

/***********************************************************************
 *				HandleFreeInterest
 ***********************************************************************
 * SYNOPSIS:	    Stupid callback function that just calls free so
 *	    	    we can tell if an interest record is what was biffed.
 * CALLED BY:	    Lst_Destroy
 * RETURN:	    Nothing
 * SIDE EFFECTS:    HInterestPtr is freed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/15/90		Initial Revision
 *
 ***********************************************************************/
static void
HandleFreeInterest(HInterestPtr	hip)
{
    free((malloc_t)hip);
}

/***********************************************************************
 *				Handle_Free
 ***********************************************************************
 * SYNOPSIS:	    Nuke a handle
 * CALLED BY:	    Ibm module to nuke thread handles, and HandleFree
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The handle is removed, a HANDLE_FREE interest call
 *	    	    is dispatched.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/19/88	Initial Revision
 *
 ***********************************************************************/
void
Handle_Free(Handle  handle)
{
    HandlePtr	    hp = (HandlePtr)handle;
    Hash_Entry	    *entry = (Hash_Entry *)NULL; /* Init for GCC */
    
    assert(VALIDTPTR(handle, TAG_HANDLE));
    
    if ((hp->state & HANDLE_TYPE) == HANDLE_THREAD) {
	dprintf("freeing thread handle %04xh, owned by %s\n", hp->id,
		hp->patient->name);
    }
    
    if ((hp->id != 0) || (hp->state & HANDLE_KERNEL)) {
	/*
	 * This was intended to alert the stub to our lack of interest in the
	 * core block for something, but it causes near-endless delays when
	 * one detaches after the stub has gone south, so don't do it.
	if (Handle_IsMemory(hp->state)) {
	    HandleDetach(hp);
	}
	 */

	entry = Hash_FindEntry(&handles, (Address)hp->id);
    
	assert(entry != (Hash_Entry *)NULL);
    }

    dprintf("Handle %xh freed\n", hp->id);

    HandleCallInterest(hp, HANDLE_FREE);

    if (hp->interest) {
	Lst_Destroy(hp->interest, HandleFreeInterest);
    }

    /*
     * Nuke the entry from the hash table if its ID hasn't been changed to 0
     * (or wasn't 0 to begin with :)
     */
    if ((hp->id != 0) || (hp->state & HANDLE_KERNEL)) {
	Hash_DeleteEntry(&handles, entry);
    }

    free((char *)hp);
}

/***********************************************************************
 *				Handle_Address
 ***********************************************************************
 * SYNOPSIS:	  Return the segment address for the handle
 * CALLED BY:	  GLOBAL
 * RETURN:	  The segment address or -1 if it has none.
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *	Just references into the structure.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/12/88		Initial Revision
 *
 ***********************************************************************/
Address
Handle_Address(Handle  	    handle) 	/* Handle whose address is desired */
{
    register HandlePtr	hp = (HandlePtr)handle;

    assert(VALIDTPTR(handle, TAG_HANDLE));

    HandleValidate(handle);

    if ((handle != NullHandle) && (hp->state & HANDLE_IN)) {
	return(hp->segment);
    } else {
	return ((Address)-1);
    }
}

/***********************************************************************
 *				Handle_Segment
 ***********************************************************************
 * SYNOPSIS:	  Return the segment  for the handle
 * CALLED BY:	  GLOBAL
 * RETURN:	  The segment or -1 if it has none.
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *	Just references into the structure and shifts segment right 4.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/28/88	Initial Revision
 *
 ***********************************************************************/
word
Handle_Segment(Handle  	    handle) 	/* Handle whose segment is desired */
{
    register HandlePtr	hp = (HandlePtr)handle;

    assert(VALIDTPTR(handle, TAG_HANDLE));

    HandleValidate(handle);

    if ((handle != NullHandle) && (hp->state & HANDLE_IN)) {
	return(SegmentOf(hp->segment));
    } else {
	return (0);
    }
}


/***********************************************************************
 *				Handle_ID
 ***********************************************************************
 * SYNOPSIS:	  Return the ID # of a handle
 * CALLED BY:	  GLOBAL
 * RETURN:	  The ID # for the handle.
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *	Just references into the HandleRec
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/12/88		Initial Revision
 *
 ***********************************************************************/
word
Handle_ID(Handle handle)    /* Handle whose ID is desired */
{
    assert(VALIDTPTR(handle, TAG_HANDLE));

    if (handle != NullHandle) {
	return (((HandlePtr)handle)->id);
    } else {
	return((word)0xffff);
    }
}

/***********************************************************************
 *				Handle_State
 ***********************************************************************
 * SYNOPSIS:	  Return the current state of a handle
 * CALLED BY:	  GLOBAL
 * RETURN:	  The state bits for the handle
 * SIDE EFFECTS:  None
 *
 * STRATEGY:	  None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/12/88		Initial Revision
 *
 ***********************************************************************/
long
Handle_State(Handle handle) 	/* Handle whose state is desired */
{
    assert(VALIDTPTR(handle, TAG_HANDLE));

    HandleValidate(handle);

    if (handle != NullHandle) {
	return (((HandlePtr)handle)->state);
    } else {
	return(0);
    }
}


/***********************************************************************
 *				Handle_XipPage
 ***********************************************************************
 * SYNOPSIS:	  Return the xip page of the handle
 * CALLED BY:	  GLOBAL
 * RETURN:	  xip page or -1 if none
 * SIDE EFFECTS:  None
 *
 * STRATEGY:	  None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	4/94		Initial Revision
 *
 ***********************************************************************/
word
Handle_XipPage(Handle handle) 	/* Handle whose state is desired */
{
    assert(VALIDTPTR(handle, TAG_HANDLE));

    HandleValidate(handle);

    if (handle != NullHandle) {
	return (((HandlePtr)handle)->xipPage);
    } else {
	return(-1);
    }
}


/***********************************************************************
 *				Handle_Owner
 ***********************************************************************
 * SYNOPSIS:	  Return the handle of the owner of this handle
 * CALLED BY:	  GLOBAL
 * RETURN:	  A Handle for the owner
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:	  Call Handle_Lookup with the ownerId for this handle
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/12/88		Initial Revision
 *
 ***********************************************************************/
Handle
Handle_Owner(Handle handle) 	/* Handle whose owner is desired */
{
    Hash_Entry	  	*entry;

    assert(VALIDTPTR(handle, TAG_HANDLE));

    HandleValidate(handle);

    if (handle != NullHandle) {
	entry = Hash_FindEntry(&handles,
			       (Address)((HandlePtr)handle)->ownerId);
	if (entry != (Hash_Entry *)NULL) {
	    return ((Handle)Hash_GetValue(entry));
	}
    } 

    return (NullHandle);
}


/***********************************************************************
 *				Handle_Patient
 ***********************************************************************
 * SYNOPSIS:	  Return the Patient that owns the handle
 * CALLED BY:	  GLOBAL
 * RETURN:	  The Patient for the handle
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:	  None.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/12/88		Initial Revision
 *
 ***********************************************************************/
Patient
Handle_Patient(Handle	handle)	    /* Handle whose patient is desired */
{
    assert(VALIDTPTR(handle, TAG_HANDLE));
#if 0
    HandleValidate(handle);	/* don't need to fetch info just to get the
				   patient -- it should always be accurate */
#endif
    if (handle != NullHandle) {
	return(((HandlePtr)handle)->patient);
    } else {
	return (NullPatient);
    }
}


/***********************************************************************
 *				Handle_Size
 ***********************************************************************
 * SYNOPSIS:	  Return the size of the block associated with handle
 * CALLED BY:	  GLOBAL
 * RETURN:	  The size...
 * SIDE EFFECTS:  None
 *
 * STRATEGY:	  If the block isn't actually resident, return 0.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/12/88		Initial Revision
 *
 ***********************************************************************/
int
Handle_Size(Handle  handle) 	/* Handle whose size is desired */
{
    assert(VALIDTPTR(handle, TAG_HANDLE));

    HandleValidate(handle);

    if ((handle != NullHandle) && (((HandlePtr)handle)->state & HANDLE_IN)){
	return(((HandlePtr)handle)->size);
    } else {
	return(0);
    }
}


/***********************************************************************
 *				Handle_TypeStruct
 ***********************************************************************
 * SYNOPSIS:	    Return the Type token that describes the structure
 *	    	    of a non-memory handle
 * CALLED BY:	    GLOBAL (expression parser)
 * RETURN:	    A Type token
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Use the handle type recorded in the state field to
 *	    	    locate a structure name, then find the symbol with
 *	    	    that name and return it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 2/89		Initial Revision
 *
 ***********************************************************************/
Type
Handle_TypeStruct(Handle    handle)
{
    static const char	*typeNames[] = {
	NULL,	    	    	/* f0 */
	NULL,	    	    	/* f1 */
	NULL,	    	    	/* f2 */
	NULL,	    	    	/* f3 */
	"HandleQueue", 	    	/* f4 SIG_QUEUE */
	"HandleDisk",  	    	/* f5 SIG_DISK */
	"HandleTimer",	    	/* f6 SIG_TIMER */
	"HandleEventData",  	/* f7 SIG_EVENT_DATA */
	"HandleEvent",	    	/* f8 SIG_EVENT_STACK */
	"HandleEvent",	    	/* f9 SIG_EVENT_REG */
	"HandleSavedBlock", 	/* fa SIG_SAVED_BLOCK */
	"HandleSem",   	    	/* fb SIG_SEMAPHORE */
	"HandleVM", 	    	/* fc SIG_VM */
	"HandleFile",	    	/* fd SIG_FILE */
	"HandleThread",	    	/* fe SIG_THREAD */
	"HandleGSeg",	    	/* ff SIG_GSEG */
    };
    const char 	*name;
    
    assert(VALIDTPTR(handle, TAG_HANDLE));

    name = typeNames[((HandlePtr)handle)->state >> 16];
    if (name != NULL) {
	/*
	 * Type of structure for handle is known -- find it in the kernel and
	 * return its token.
	 */
	Sym 	sym = Sym_Lookup(name, SYM_TYPE, kernel->global);

	return (TypeCast(sym));
    } else {
	/*
	 * Who knows?
	 */
	return(NullType);
    }
}
    

/***********************************************************************
 *				HandleCallInterest
 ***********************************************************************
 * SYNOPSIS:	  Call all interested procedures for this handle
 * CALLED BY:	  Handle_Change, Handle_In, Handle_Out
 * RETURN:	  Nothing
 * SIDE EFFECTS:  The interested procedures are called.
 *
 * STRATEGY:
 *	Pass down the list calling each procedure in turn.
 *	
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/17/88		Initial Revision
 *
 ***********************************************************************/
static void
HandleCallInterest(HandlePtr  	    hp,     	/* Handle that changed */
		   Handle_Status    status)     /* How it changed */
{
    LstNode 	  	ln; 	/* Current node in interest list */
    HInterestPtr  	hip;	/* Actual record of interest */

    if (hp->interest && (Lst_Open(hp->interest) == SUCCESS)) {
	while ((ln = Lst_Next(hp->interest)) != NILLNODE) {
	    hip = (HInterestPtr)Lst_Datum(ln);
	    (* hip->interestProc)((Handle)hp, status, hip->data);
	    /*
	     * If the function we called called Handle_NoInterest, causing
	     * the interest list to be nuked, get out now.
	     */
	    if (hp->interest == NULL) {
		return;
	    }
	}
	Lst_Close(hp->interest);
    }
}

/***********************************************************************
 *				Handle_Interest
 ***********************************************************************
 * SYNOPSIS:	  Register interest in the state of a handle
 * CALLED BY:	  GLOBAL    
 * RETURN:	  Nothing
 * SIDE EFFECTS:  An HInterestRec is created for the procedure.
 *
 * STRATEGY:
 *	Just create the record and add it to le liste.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/17/88		Initial Revision
 *
 ***********************************************************************/
void
Handle_Interest(Handle      	    handle,    	    /* Interesting handle */
		HandleInterestProc  *interestProc,  /* Procedure to be told */
		Opaque  	    data)    	    /* Data to pass it */
{
    HInterestPtr  	hip;
    HandlePtr	  	hp = (HandlePtr)handle;

    assert(VALIDTPTR(handle, TAG_HANDLE));

    HandleValidate(handle);

#if 0
    /* if its an XIP handle, don't bother */
    if (Handle_XipPage(handle) != HANDLE_NOT_XIP)
    {
	return;
    }
#endif

    /*
     * If the handle's only cached, remove it from the cache -- it's
     * a full-fledged handle now.
     */
    HandleAttach(hp);
    /*
     * Allocate the interest list if it doesn't exist yet.
     */
    if (hp->interest == NULL) {
	hp->interest = Lst_Init(FALSE);
    }
    /*
     * Create an HInterestRec to hold the interest procedure
     */
    hip = (HInterestPtr)malloc_tagged(sizeof(HInterestRec), TAG_HANDLE);

    hip->interestProc = interestProc;
    hip->data = data;
    Lst_AtEnd(hp->interest, (LstClientData)hip);
}


/***********************************************************************
 *				Handle_NoInterest
 ***********************************************************************
 * SYNOPSIS:	  Stop being interested in a handle
 * CALLED BY:	  GLOBAL
 * RETURN:	  Nothing
 * SIDE EFFECTS:  If an HInterestRec with the same procedure and data
 *		  exists, it is removed.
 *
 * STRATEGY:
 *	None.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/17/88		Initial Revision
 *
 ***********************************************************************/
void
Handle_NoInterest(Handle  	    handle, 	    	/* Boring handle */
		  HandleInterestProc *interestProc,    	/* Old procedure */
		  Opaque  	    data)   	    	/* Datum that was
							 * passed */
{
    HandlePtr	  	hp = (HandlePtr)handle;
    HInterestPtr  	hip;
    LstNode 	  	ln;

    assert(VALIDTPTR(handle, TAG_HANDLE));

    if (hp->interest == NULL) {
	/*
	 * The Ibm module likes to call Handle_NoInterest at the end of
	 * all things to keep from nuking itself when kinit is nuked.
	 * If initialization is complete, however, there will be no one
	 * interested in kinit, so hp->interest will be null...
	 */
	return;
    }

    for (ln = Lst_First(hp->interest); ln != NILLNODE; ln = Lst_Succ(ln)) {
	hip = (HInterestPtr)Lst_Datum(ln);

	if ((hip->interestProc == interestProc) && (hip->data == data)) {
	    Lst_Remove(hp->interest, ln);
	    free((char *)hip);
	    break;
	}
    }
    /*
     * If the handle isn't one of those that's automatically retained, and
     * there's now no one with an interest in the handle, detach from it.
     */
    if (!HandleRetain(hp->state) && Lst_IsEmpty(hp->interest)) {
	HandleDetach(hp);
	Lst_Destroy(hp->interest, HandleFreeInterest);
	hp->interest = NULL;
    }
}


/***********************************************************************
 *				Handle_MakeReadOnly
 ***********************************************************************
 * SYNOPSIS:	    Mark a block of memory as being read-only. Exists
 *	    	    to avoid having to do a BLOCK_INFO just to mark
 *		    read-only resources as read-only when a geode is
 *		    first encountered.
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    HANDLE_FCHANGE interest call goes out
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/19/94		Initial Revision
 *
 ***********************************************************************/
void
Handle_MakeReadOnly(Handle handle)
{
    assert(VALIDTPTR(handle, TAG_HANDLE));

    ((HandlePtr)handle)->state |= HANDLE_READ_ONLY;

    HandleCallInterest((HandlePtr)handle, HANDLE_FCHANGE);
}

/***********************************************************************
 *				Handle_CreateResource
 ***********************************************************************
 * SYNOPSIS:	    Create a handle for a resource of a new geode, but
 *	    	    don't fill in any details; just leave the handle
 *		    setup so it gets validated when first referenced.
 * CALLED BY:	    Ibm_NewGeode
 * RETURN:	    Handle
 * SIDE EFFECTS:    handle is entered in the table with its generation
 *		    number one less than the current generation.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/17/94		Initial Revision
 *
 ***********************************************************************/
Handle
Handle_CreateResource(Patient patient, word id, word resid)
{
    Handle  result;

    result = Handle_Create(patient, id, patient->core, 0, 0,
			   HANDLE_MEMORY|HANDLE_DISCARDED|HANDLE_RESOURCE,
			   (Opaque)resid, HANDLE_NOT_XIP);

    ((HandlePtr)result)->gen = generation - 1;

    return (result);
}

/***********************************************************************
 *				Handle_Create
 ***********************************************************************
 * SYNOPSIS:	  Create a record for a handle
 * CALLED BY:	  Ibm module
 * RETURN:	  The new Handle
 * SIDE EFFECTS:  A HandleRec is created.
 *
 * STRATEGY:
 *	Well...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/16/88		Initial Revision
 *
 ***********************************************************************/
Handle
Handle_Create(Patient	patient,    	/* Patient that owns the handle */
	      word	id, 	    	/* Handle's ID # */
	      Handle  	owner,	    	/* Owner handle */
	      Address	address,    	/* Current address (0 if n/r). This
					 * is a 32-bit address (i.e. the
					 * segment << SEGMENT_SHIFT) */
	      dword	size,	    	/* Size of block */
	      long	flags,	    	/* Block flags (HANDLE_* bits) */
	      Opaque	otherInfo,  	/* otherInfo field of handle */
	      word  	xipPage)    	/* xip page number or -1 if none */
{
    Hash_Entry	  	*entry;
    Boolean 	  	new;
    HandlePtr		hp;

    if ((id != 0) || (flags & HANDLE_KERNEL)) {
	entry = Hash_CreateEntry(&handles, (ClientData)id, &new);
	if (new) {
	    hp = (HandlePtr)malloc_tagged(sizeof(HandleRec), TAG_HANDLE);
	    Hash_SetValue(entry, hp);
	} else {
	    hp = (HandlePtr)Hash_GetValue(entry);
	}
    } else {
	/*
	 * Resource handles are created before their corresponding PC
	 * GEOS handles are. Their initial ID is 0. They aren't entered
	 * into the table. Note, however, that handle ID 0 is actually
	 * the kernel's thread, so we test for the handle belonging to the
	 * kernel, above.
	 * XXX: This isn't strictly true....
	 */
	hp = (HandlePtr)malloc_tagged(sizeof(HandleRec), TAG_HANDLE);
    }

    hp->id = id;

    if (owner != NullHandle) {
	hp->ownerId = ((HandlePtr)owner)->id;
	hp->patient = ((HandlePtr)owner)->patient;
	assert(hp->patient->resources != NULL);
    } else {
	/*
	 * If owner is NULL, handle is owned by itself.
	 */
	hp->ownerId = id;
	hp->patient = patient;
	assert(hp->patient->resources != NULL);
    }

    hp->segment = address;
    hp->size = size;
    hp->state = flags;
    hp->gen = generation;
    hp->xipPage = xipPage;
    
    /*
     * Verify the state of the passed bits:
     *	- either the segment is 0 or the block is marked in
     *	- the SWAPPED and DISCARDED bits may not both be on
     *	- if the block is FIXED, it may not be SWAPABLE
     */
    if (!((hp->segment==0) || (flags&HANDLE_IN) || !Handle_IsMemory(flags)) ||
	(((flags & HANDLE_SWAPPED) << 1) & (flags & HANDLE_DISCARDED)) ||
	((flags & HANDLE_FIXED) &&
	 (flags & (HANDLE_SWAPABLE))))
    {
	Punt("Invalid flags passed to Handle_Create");
    }

    
    /*
     * Initialize the interest list and store away the bit of other
     * info. We expect the caller to know what to put there.
     */
    hp->interest = NULL;
    hp->otherInfo = (Opaque)otherInfo;

    if (HandleRetain(flags)) {
	HandleAttach(hp);
    }
    return((Handle)hp);
}


/***********************************************************************
 *				Handle_Change
 ***********************************************************************
 * SYNOPSIS:	  Change the recorded attributes of a handle.
 * CALLED BY:	  Ibm module.
 * RETURN:	  Nothing
 * SIDE EFFECTS:  An interest call is generated to indicate the state change.
 *
 * STRATEGY:
 *	Set the new data for the block.
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/15/88		Initial Revision
 *
 ***********************************************************************/
void
Handle_Change(Handle  	handle,	    /* Handle to "alter" */
	      int	which,	    /* What about it to change */
	      word    	id, 	    /* New ID */
	      Address 	address,    /* New address */
	      dword	size,	    /* New size */
	      long	flags,	    /* New flags */
	      word  	xipPage)    /* page number or -1 if no change */
{
    HandlePtr	  	hp; 	    /* Internal representation */
    int			state;
    Handle_Status   	mainChange;
    Boolean 	    	sendNotify = TRUE;
    
    assert(VALIDTPTR(handle, TAG_HANDLE));

    hp = (HandlePtr)handle;

    if (xipPage != HANDLE_NOT_XIP) {
	hp->xipPage = xipPage;
    }
    /*
     * Record previous state so we can detect state changes, even if
     * HANDLE_FLAGS given...
     */
    state = hp->state;

    /*
     * Make appropriate changes to the handle's information. At the end of
     * this, "which" is left with bits set for those things that actually
     * changed.
     */
    if (which & HANDLE_ID) {
	Hash_Entry	*entry;
	
	if ((hp->id != 0) && (id != hp->id)) {
	    /*
	     * Handle actually had an id before -- remove the entry for it
	     */
	    entry = Hash_FindEntry(&handles, (ClientData)hp->id);
	    if (entry != (Hash_Entry *)NULL) {
		Hash_DeleteEntry(&handles, entry);
	    }
	}

	if (id != hp->id) {
	    entry = Hash_CreateEntry(&handles, (ClientData)id,
				     (Boolean *)NULL);
	    hp->id = id;
	    Hash_SetValue(entry, hp);
	} else {
	    which &= ~HANDLE_ID;
	}
    }
    
    if (which & HANDLE_ADDRESS) {
	if (hp->segment != address) {
	    hp->segment = address;
	} else {
	    which &= ~HANDLE_ADDRESS;
	}
    }
    if (which & HANDLE_SIZE) {
	if (hp->size != size) {
	    hp->size = size;
	} else {
	    which &= ~HANDLE_SIZE;
	}
    }
    if (which & HANDLE_FLAGS) {
	hp->state = flags;
	/*
	 * If state changed to one of the auto-retained ones and not already
	 * attached to the handle, attach now. If changed from auto-retained,
	 * no-one's interested and we're attached to the handle, detach now.
	 */
	if (HandleRetain(hp->state)) {
	    if (!(hp->state & HANDLE_ATTACHED)) {
		HandleAttach(hp);
	    }
	} else if ((hp->interest == NULL) && (hp->state & HANDLE_ATTACHED)) {
	    HandleDetach(hp);
	}
    }
    
    if ((hp->segment != 0) && !(state & HANDLE_IN)) {
	/*
	 * Block now resident, so must have been swapped in or loaded.
	 */
	hp->state |= HANDLE_IN;
	hp->state &= ~(HANDLE_DISCARDED|HANDLE_SWAPPED);

	if (state & HANDLE_DISCARDED) {
	    dprintf("Handle %04xh loaded\n", hp->id);
	    mainChange = HANDLE_LOAD;
	} else {
	    dprintf("Handle %04xh swapped in\n", hp->id);
	    mainChange = HANDLE_SWAPIN;
	}
    } else if ((hp->segment == 0) && (state & HANDLE_IN)) {
	/*
	 * Block went away. HANDLE_DISCARDED or HANDLE_SWAPPED must have been
	 * set in the flags so we know what happened to nuke the block
	 */
	hp->state &= ~HANDLE_IN;
	assert(hp->state & (HANDLE_DISCARDED|HANDLE_SWAPPED));

	if (hp->state & HANDLE_DISCARDED) {
	    dprintf("Handle %04xh discarded\n", hp->id);
	    mainChange = HANDLE_DISCARD;
	} else {
	    dprintf("Handle %04xh swapped out\n", hp->id);
	    mainChange = HANDLE_SWAPOUT;
	}
    } else if (which & HANDLE_SIZE) {
	/*
	 * Actually reallocated (size changed). Signal a RESIZE.
	 */
	dprintf("Handle %04xh resized to %d\n", hp->id, hp->size);
	mainChange = HANDLE_RESIZE;
    } else if (which & HANDLE_ADDRESS) {
	/*
	 * Block just moved. Signal a MOVE
	 */
	dprintf("Handle %04xh moved to %04xh\n", hp->id,
		SegmentOf(hp->segment)) ;
	mainChange = HANDLE_MOVE;
    } else {
	sendNotify = FALSE;
	mainChange = 0;		/* To keep GCC from complaining */
    }

    if (which & HANDLE_FLAGS) {
	HandleCallInterest(hp, HANDLE_FCHANGE);
    }
    if (sendNotify) {
	HandleCallInterest(hp, mainChange);
    }
}


/***********************************************************************
 *				HandleOut
 ***********************************************************************
 * SYNOPSIS:	  Signal a block's departure.
 * CALLED BY:	  Rpc module by RPC_BLOCK_OUT
 * RETURN:	  Nothing
 * SIDE EFFECTS:  Interested routines are called and our data structures
 *		  updated
 *
 * STRATEGY:
 *	Find the handle in le table
 *	Set its state
 *	Generate SWAPOUT if block not discarded,
 *	Else generate DISCARD.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/15/88		Initial Revision
 *
 ***********************************************************************/
static void
HandleOut(Rpc_Message		msg,	    /* Message to which to reply */
	  int			length,	    /* Length of args */
	  Rpc_Opaque	    	data,	    /* Args themselves */
	  Rpc_Opaque	    	clientData) /* UNUSED */
{
    HandlePtr	  	hp;
    Hash_Entry		*entry;
    OutArgs		*oa = (OutArgs *)data;

    entry = Hash_FindEntry(&handles, (Address)oa->oa_handle);
    if (entry == (Hash_Entry *)NULL) {
	dprintf("Block %xh swapped out but I don't care\n", oa->oa_handle);
	Rpc_Error(msg, RPC_BADARGS);
	return;
    }
	    
    hp = (HandlePtr)Hash_GetValue(entry);

    /*
     * Only pay attention if the handle is valid, as that's the only time
     * we really care (we can be called if the stub causes something to be
     * swapped out, even if we've never expressed interest in the handle)
     */
    if (HandleValid(hp)) {
	/*
	 * Clear what needs clearing to note the block's non-residence. Note
	 * that a swapped block can be discarded, so we clear out the
	 * HANDLE_SWAPPED bit too.
	 */
	hp->segment = 0;
	hp->state &= ~(HANDLE_IN|HANDLE_SWAPPED);
	
	if (oa->oa_discarded) {
	    hp->state |= HANDLE_DISCARDED;
	    
	    dprintf("Handle %xh discarded\n", hp->id);
	    HandleCallInterest(hp, HANDLE_DISCARD);
	} else {
	    hp->state |= HANDLE_SWAPPED;
	    
	    dprintf("Handle %xh swapped out\n", hp->id);
	    HandleCallInterest(hp, HANDLE_SWAPOUT);
	}
	
	if (sysFlags & PATIENT_RUNNING) {
	    (void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_HALF);
	}
    }

    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}


/***********************************************************************
 *				HandleLoad
 ***********************************************************************
 * SYNOPSIS:	  Note that a block has come back in (again).
 * CALLED BY:	  Rpc module by RPC_BLOCK_LOAD, which see.
 * RETURN:	  Nothing.
 * SIDE EFFECTS:  The handle's segment field is updated.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/15/88		Initial Revision
 *
 ***********************************************************************/
static void
HandleLoad(Rpc_Message	    msg,	/* Message for reply */
	   int		    length,	/* Length of passed data */
	   Rpc_Opaque	    data,   	/* Args fior call */
	   Rpc_Opaque	    clientData)	/* UNUSED */
{
    Hash_Entry	  	*entry;
    HandlePtr	  	hp;
    LoadArgs	    	*la = (LoadArgs *)data;

    entry = Hash_FindEntry(&handles, (ClientData)la->la_handle);

    if (entry == (Hash_Entry *)NULL) {
	dprintf("Handle %d came in, but I don't care (yet)\n", la->la_handle);
	Rpc_Error(msg, RPC_BADARGS);
	return;
    }
    hp = (HandlePtr)Hash_GetValue(entry);

    /*
     * Only pay attention if the handle is valid, as that's the only time
     * we really care (we can be called if the stub causes something to be
     * loaded, even if we've never expressed interest in the handle)
     */
    if (HandleValid(hp)) {
        hp->segment = MakeAddress(la->la_dataAddress, 0) ;
	hp->state |= (HANDLE_IN);
	hp->state &= ~HANDLE_SWAPPED;
	
	dprintf("Handle %xh swapped in\n", hp->id);
	HandleCallInterest(hp, HANDLE_SWAPIN);
	
	if (sysFlags & PATIENT_RUNNING) {
	    (void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_HALF);
	}
    }

    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}
	

/***********************************************************************
 *				HandleResLoad
 ***********************************************************************
 * SYNOPSIS:	  Note that a Resource has been loaded.
 * CALLED BY:	  Rpc Module by RPC_RES_LOAD, which see
 * RETURN:	  Nothing.
 * SIDE EFFECTS:  If you're lucky
 *
 * STRATEGY:	  Not really.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/22/88		Initial Revision
 *
 ***********************************************************************/
static void
HandleResLoad(Rpc_Message   msg,    	    /* Message to which to reply */
	      int	    length, 	    /* Length of args */
	      Rpc_Opaque    data,   	    /* Args themselves */
	      Rpc_Opaque    clientData)	    /* UNUSED */
{
    Hash_Entry	  	*entry;
    HandlePtr	  	hp;
    LoadArgs	    	*la = (LoadArgs *)data;

    entry = Hash_FindEntry(&handles, (ClientData)la->la_handle);

    if (entry == (Hash_Entry *)NULL) {
	dprintf("Handle %d came in, but I don't care (yet)\n", la->la_handle);
	Rpc_Error(msg, RPC_BADARGS);
	return;
    }
    hp = (HandlePtr)Hash_GetValue(entry);

    /*
     * Only pay attention if the handle is valid, as that's the only time
     * we really care (we can be called if the stub causes something to be
     * loaded, even if we've never expressed interest in the handle)
     */
    if (HandleValid(hp)) {
	hp->segment = (Address)(la->la_dataAddress << 4);
	hp->state |= HANDLE_IN;
	hp->state &= ~HANDLE_DISCARDED;
	
	dprintf("Resource handle %xh loaded\n", hp->id);
	HandleCallInterest(hp, HANDLE_LOAD);
	
	if (sysFlags & PATIENT_RUNNING) {
	    (void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_HALF);
	}
    }

    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}
	

/***********************************************************************
 *				HandleMove
 ***********************************************************************
 * SYNOPSIS:	  Note that a handle's data have moved
 * CALLED BY:	  Rpc module
 * RETURN:	  Nothing
 * SIDE EFFECTS:  ...
 *
 * STRATEGY:	  ...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/22/88		Initial Revision
 *
 ***********************************************************************/
static void
HandleMove(Rpc_Message	  	msg,
	   int			length,
	   Rpc_Opaque	    	data,
	   Rpc_Opaque	    	clientData)
{
    HandlePtr		hp;
    MoveArgs		*ma = (MoveArgs *)data;
    

    if (ma->ma_handle == 0) {
	/*
	 * Special case to handle the relocation of the loader up into high
	 * memory. Just adjust all the handles for the loader that aren't
	 * special (resources[i].flags & RESF_READ_ONLY is false).
	 */
	Ibm_LoaderMoved(ma->ma_dataAddress);
    } else {
	Hash_Entry	  	*entry;
	
	entry = Hash_FindEntry(&handles, (ClientData)ma->ma_handle);
	if (entry == (Hash_Entry *)0) {
	    dprintf("Handle %xh moved but I don't care\n", ma->ma_handle);
	    Rpc_Error(msg, RPC_BADARGS);
	    return;
	}
	hp = (HandlePtr)Hash_GetValue(entry);
	
	/*
	 * Only pay attention if the handle is valid, as that's the only time
	 * we really care (we can be called if the stub causes something to be
	 * moved, even if we've never expressed interest in the handle)
	 */
	if (HandleValid(hp)) {
            hp->segment = MakeAddress(ma->ma_dataAddress, 0) ;
	    
	    dprintf("Handle %xh moved to %xh\n", hp->id, ma->ma_dataAddress);
	    
	    HandleCallInterest(hp, HANDLE_MOVE);
	}
    }
    if (sysFlags & PATIENT_RUNNING) {
	(void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_HALF);
    }

    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}


/***********************************************************************
 *				HandleRealloc
 ***********************************************************************
 * SYNOPSIS:	  Note that a block has been resized
 * CALLED BY:	  Rpc module
 * RETURN:	  Nothing
 * SIDE EFFECTS:  ...
 *
 * STRATEGY:	  ...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/22/88		Initial Revision
 *
 ***********************************************************************/
static void
HandleRealloc(Rpc_Message   msg,
	      int	    length,
	      Rpc_Opaque    data,
	      Rpc_Opaque    clientData)
{
    Hash_Entry	  	*entry;
    HandlePtr	  	hp;
    ReallocArgs     	*rea = (ReallocArgs *)data;

    entry = Hash_FindEntry(&handles, (ClientData)rea->rea_handle);
    if (entry == (Hash_Entry *)0) {
	dprintf("Handle %xh resized but I don't care\n", rea->rea_handle);
	Rpc_Error(msg, RPC_BADARGS);
	return;
    }

    hp = (HandlePtr)Hash_GetValue(entry);

    /*
     * Only pay attention if the handle is valid, as that's the only time
     * we really care (we can be called if the stub causes something to be
     * realloced, even if we've never expressed interest in the handle)
     */
    if(HandleValid(hp)) {
        hp->segment = MakeAddress(rea->rea_dataAddress, 0) ;
	hp->size = rea->rea_paraSize << 4;
	hp->state |= HANDLE_IN;
	hp->state &= ~(HANDLE_DISCARDED|HANDLE_SWAPPED);
	
	dprintf("Handle %xh resized to %d bytes at %xh\n", hp->id, hp->size,
		rea->rea_dataAddress);
	
	HandleCallInterest(hp, HANDLE_RESIZE);
	
	if (sysFlags & PATIENT_RUNNING) {
	    (void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_HALF);
	}
    }

    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}


/***********************************************************************
 *				HandleFreeResource
 ***********************************************************************
 * SYNOPSIS:	Free a resource handle
 * CALLED BY:	HandleFree, HandleExit
 * RETURN:	nothing
 * SIDE EFFECTS:the handle is removed from the handle table
 *	    	interested parties are called with HANDLE_DISCARD, as
 *	    	resource handles don't actually get freed, they just
 *	    	get marked as discarded.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/91		Initial Revision
 *
 ***********************************************************************/
static void
HandleFreeResource(HandlePtr	hp,
		   Hash_Entry	*entry)
{
    /*
     * Resource handle was explicitly freed. We don't want to call
     * Handle_Free w/o nuking the Patient that owns it too. In fact,
     * we'd rather not free the thing at all. Instead, we pretend the
     * thing was discarded (a resource handle is explicitly freed
     * only in the weirdest of circumstances anyway) and set its
     * id to 0.
     */
    dprintf("Handle %xh discarded (resource freed)\n", hp->id);
    hp->state &= ~HANDLE_IN;
    hp->state |= HANDLE_DISCARDED;
    HandleCallInterest(hp, HANDLE_DISCARD);
    HandleDetach(hp);
    hp->id = 0;
    Hash_DeleteEntry(&handles, entry);
}


/***********************************************************************
 *				HandleFree
 ***********************************************************************
 * SYNOPSIS:	  Note that a handle has been freed
 * CALLED BY:	  Rpc module
 * RETURN:	  Nothing
 * SIDE EFFECTS:  The handle is removed from the table
 *
 * STRATEGY:	  ...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/22/88		Initial Revision
 *
 ***********************************************************************/
static void
HandleFree(Rpc_Message	msg,
	   int		length,
	   Rpc_Opaque	data,
	   Rpc_Opaque	clientData)
{
    Hash_Entry	  	*entry;
    HandlePtr	  	hp;

    entry = Hash_FindEntry(&handles, (Address)*(word *)data);
    if (entry == (Hash_Entry *)0) {
	dprintf("Handle %xh freed but I don't care\n", *(word *)data);
	Rpc_Error(msg, RPC_BADARGS);
	return;
    }

    hp = (HandlePtr)Hash_GetValue(entry);

    /*
     * Only pay attention if the handle is valid, as that's the only time
     * we really care (we can be called if the stub causes something to be
     * freed, even if we've never expressed interest in the handle)
     */
    if (HandleValid(hp)) {
	if (hp->state & HANDLE_KERNEL) {
	    dprintf("Kernel handle %xh freed\n", hp->id);
	} else if (hp->state & (HANDLE_RESOURCE|HANDLE_PROCESS)) {
	    HandleFreeResource(hp, entry);
	} else {
	    Handle_Free((Handle)hp);
	}
	
	if (sysFlags & PATIENT_RUNNING) {
	    (void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_HALF);
	}
    }
    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}

/***********************************************************************
 *				HandleExit
 ***********************************************************************
 * SYNOPSIS:	    Handle the exit of a patient by nuking all
 *	    	    non-resource handles for the patient.
 * CALLED BY:	    Event_Dispatch
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *	shared resource handles:
 *	    change owner to be next patient on patients list w/same name
 *	non-shared resource handles:
 *	    change ID to 0 and remove from table, generating a HANDLE_DISCARD
 *	    interest call
 *	other:
 *	    generate HANDLE_FREE interest call and nuke handle
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/16/88	Initial Revision
 *
 ***********************************************************************/
int
HandleExit(Event    	event,
	   Opaque   	callData,
	   Opaque	clientData)
{
    Patient 	patient = (Patient)callData;
    Hash_Search	search;
    Hash_Entry	*entry;
    HandlePtr	hp;

    for (entry = Hash_EnumFirst(&handles, &search);
	 entry != (Hash_Entry *)NULL;
	 entry = Hash_EnumNext(&search))
    {
	Patient 	new = NullPatient;
	
	/*
	 * Look for another patient of the same name who will inherit
	 * any shared resource handles.
	 */
	if (patient != loader) {
	    new = IbmFindOtherInstance(
			(GeodeName *)&patient->geode.v2->geodeFileType,
			    	    	patient,
				       	(int *)NULL);
	}
	
	assert(new == NullPatient || new->resources != NULL);

	hp = (HandlePtr)Hash_GetValue(entry);

	if (hp->patient == patient) {
	    switch (hp->state & (HANDLE_RESOURCE|HANDLE_READ_ONLY)) {
		case HANDLE_RESOURCE|HANDLE_READ_ONLY:
		{
		    /*
		     * Shared resource -- try and find another known patient on
		     * the list who will inherit the handle (as is done by
		     * GEOS itself).
		     */
		    if (new != NULL) {
			hp->patient = new;
			dprintf("Handle %xh now owned by %s\n",
				hp->id, new->name);
			break;
		    }
		    /*
		     * Fall through if no other patient of the same name
		     */
		}
		case HANDLE_RESOURCE:
		    /*
		     * Resource handles have their ID set to 0 and are nuked
		     * from the table if no one owns them, but they are
		     * *not* freed, since Ibm_NewGeode needs a handle
		     * structure around should it re-use the patient.
		     */
		    HandleFreeResource(hp, entry);
		    break;
		default:
		    /*
		     * Any other non-thread, non-kernel handle owned by the
		     * patient is nuked (thread handles will be taken care of
		     * by the Ibm module). We don't get an RPC_BLOCK_FREE call
		     * for these things.
		     *
		     * Postpone freeing the process handle until the end, so
		     * we can cope with having received an RPC_BLOCK_FREE call
		     * for the core block (in which case HandleFreeResource
		     * will have been called on the thing and the handle won't
		     * be in the table), or not.
		     */
		    if (!Handle_IsThread(hp->state)) {
			if (hp->state & (HANDLE_KERNEL|HANDLE_PROCESS)) {
			    /*
			     * For kernel handles, we wish to call the interest
			     * function but not actually nuke the thing. This
			     * is invoked only on a "detach" command and we
			     * don't want to have to set up the handles again
			     * should the kernel not have changed.
			     */
			    HandleCallInterest(hp, HANDLE_DISCARD);
			    hp->segment = 0;
			    hp->state &= ~(HANDLE_IN|HANDLE_ATTACHED);
			    hp->state |= HANDLE_DISCARDED;
			} else {
			    /*XXX: Makes it search for entry again... */
			    Handle_Free((Handle)hp);
			}
		    }
		    break;
	    }
	}
    }

    /*
     * Now the thing has exited, free up the core block handle, as no one
     * can possibly require it again. The thing was already removed from the
     * table by HandleFree()
     */
    if (patient->core && !(((HandlePtr)patient->core)->state & HANDLE_KERNEL)) {
	Handle_Free(patient->core);
	patient->core = 0;
    }

    return(EVENT_HANDLED);
}
typedef struct {
    Handle	    handle; 	/* Handle to which record is attached */
    char    	    *proc;  	/* Procedure to invoke */
    char    	    *data;  	/* Data to pass */
    int	    	    locked; 	/* Non-zero if interest procedure being
				 * called and record will be freed at the
				 * end of the call, so don't nuke it, please */
} TclInterestRec, *TclInterestPtr;

/***********************************************************************
 *				HandleTclInterest
 ***********************************************************************
 * SYNOPSIS:	    Call a tcl-level interest procedure
 * CALLED BY:	    HandleCallInterest
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/14/89		Initial Revision
 *
 ***********************************************************************/
static void
HandleTclInterest(Handle   	    handle,
		  Handle_Status     status,
		  Opaque   	    data)
{
    TclInterestPtr  tip = (TclInterestPtr)data;
    static char *statusNames[] = {
	"swapin", "load", "swapout", "discard", "resize", "move", "free",
	"fchange",
    };
    char    	*cmd;

    /*
     * Allocate room for the thing. 12 is for the bounding spaces and the
     * ascii representation of the handle.
     */
    cmd = (char *)malloc(strlen(tip->proc) + 12 +
			 strlen(statusNames[status]) + 1 +
			 (tip->data ? strlen(tip->data) : 0) + 1);
    /*
     * Create the command string, invoking the procedure with the
     * handle, the status change and the data as args.
     */
    sprintf(cmd, "%s %d %s %s", tip->proc, (int)handle, statusNames[status],
	    tip->data ? tip->data : "");

    tip->locked = (status == HANDLE_FREE);

    /*
     * Evaluate the command, ignoring the result (except on error).
     */
    if (Tcl_Eval(interp, cmd, 0, 0) != TCL_OK) {
	Warning("%s: %s", tip->proc, interp->result);
    }

    free(cmd);

    /*
     * Take care of freeing our data structure, since the interest list
     * will be going away...
     */
    if (status == HANDLE_FREE) {
	free(tip->proc);
	if (tip->data) {
	    free(tip->data);
	}
	free((char *)tip);
    }

}

/***********************************************************************
 *				HandleCmd
 ***********************************************************************
 * SYNOPSIS:	    Tcl-access to our structures
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK or TCL_ERROR
 * SIDE EFFECTS:    Handles may be loaded...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 2/88	Initial Revision
 *
 ***********************************************************************/
#define HANDLE_LOOKUP	(ClientData)0
#define HANDLE_FIND 	(ClientData)1
#define HANDLE_ALL  	(ClientData)2
#define HANDLE_NOINTEREST (ClientData)3
#define HANDLE_INTEREST	(ClientData)4
#define HANDLE_SEGMENT	(ClientData)5
#define HANDLE_SIZECMD	(ClientData)6
#define HANDLE_STATE	(ClientData)7
#define HANDLE_OWNER	(ClientData)8
#define HANDLE_PATIENT	(ClientData)9
#define HANDLE_OTHER	(ClientData)10
#define HANDLE_IDCMD	(ClientData)11
#define HANDLE_ISTHREAD	(ClientData)12
#define HANDLE_ISKERNEL	(ClientData)13
#define HANDLE_ISFILE	(ClientData)14
#define HANDLE_ISVM 	(ClientData)15
#define HANDLE_ISGSEG	(ClientData)16
#define HANDLE_ISMEM	(ClientData)17
#define HANDLE_ISXIP	(ClientData)18
#define HANDLE_XIPPAGE	(ClientData)19

static const CmdSubRec handleCmds[] = {
    {"lookup",	HANDLE_LOOKUP,	1, 1, "<id>"},
    {"find", 	HANDLE_FIND,	1, 2, "<address> [<frame>]"},
    {"all",  	HANDLE_ALL, 	0, 0, ""},
    {"nointerest",HANDLE_NOINTEREST,1,1,"<interest>"},
    {"interest",HANDLE_INTEREST,2, 3, "<handle> <proc> [<data>]"},
    {"segment",	HANDLE_SEGMENT,	1, 1, "<handle>"},
    {"size", 	HANDLE_SIZECMD,	1, 1, "<handle>"},
    {"state",	HANDLE_STATE,	1, 1, "<handle>"},
    {"owner",	HANDLE_OWNER,	1, 1, "<handle>"},
    {"patient",	HANDLE_PATIENT,	1, 1, "<handle>"},
    {"other",	HANDLE_OTHER,	1, 1, "<handle>"},
    {"id",   	HANDLE_IDCMD,	1, 1, "<handle>"},
    {"isthread",HANDLE_ISTHREAD,1, 1, "<handle>"},
    {"iskernel",HANDLE_ISKERNEL,1, 1, "<handle>"},
    {"isfile",	HANDLE_ISFILE,	1, 1, "<handle>"},
    {"isvm",	HANDLE_ISVM,	1, 1, "<handle>"},
    {"isgseg",	HANDLE_ISGSEG,	1, 1, "<handle>"},
    {"ismem",	HANDLE_ISMEM,	1, 1, "<handle>"},
    {"isxip",	HANDLE_ISXIP,	1, 1, "<handle>"},
    {"xippage",  HANDLE_XIPPAGE, 1, 1, "<handle>"},
    {NULL,   	(ClientData)NULL,	    	0, 0, NULL}
};

DEFCMD(handle,Handle,TCL_EXACT,handleCmds,swat_prog,
"Usage:\n\
    handle lookup <id>\n\
    handle find <address> [<frame>]\n\
    handle all\n\
    handle nointerest <interest-record>\n\
    handle interest <handle> <proc> [<data>+]\n\
    handle segment <handle>\n\
    handle size <handle>\n\
    handle state <handle>\n\
    handle owner <handle>\n\
    handle patient <handle>\n\
    handle other <handle>\n\
    handle id <handle>\n\
    handle isthread <handle>\n\
    handle iskernel <handle>\n\
    handle isfile <handle>\n\
    handle isvm <handle>\n\
    handle ismem <handle>\n\
    handle isxip <handle>\n\
\n\
Examples:\n\
    \"handle lookup [read-reg bx]\"   get the handle token for the handle whose\n\
				    ID is in the bx register.\n\
    \"handle interest $h ob-interest-proc [concat si=$chunk $method]\"\n\
    	    	    	    	    call ob-interest-proc, passing the\n\
				    list {si=$chunk $method}, whenever the\n\
				    state of the handle whose token is in $h\n\
				    changes.\n\
    \"handle patient $h\"	    	    get the token for the patient that owns\n\
				    the handle whose token is in $h\n\
    \"handle all\"    	    	    get the list of the ID's of all handles\n\
				    currently in Swat's handle table.\n\
\n\
Synopsis:\n\
    The \"handle\" command provides access to the structures Swat uses to track\n\
    memory and thread allocation on the PC.\n\
\n\
Notes:\n\
    * As with most other commands that deal with Swat structures, you use\n\
      this one by calling a lookup function (the \"lookup\" and \"find\"\n\
      subcommands) to obtain a token that you use for further manipulations.\n\
      A handle token is also returned by a few other commands, such as\n\
      addr-parse.\n\
\n\
    * Handle tokens are valid only until the machine is continued. If you\n\
      need to keep the token for a while, you will need to register interest\n\
      in the handle using the \"interest\" subcommand. Most handles tokens\n\
      will simply be cached while the machine is stopped and flushed from\n\
      the cache when the machine continues. Only those handles for which all\n\
      state changes must be known remain in Swat's handle table. For\n\
      example, when a conditional breakpoint has been registered with the\n\
      stub using the segment of a handle, the condition for that breakpoint\n\
      must be updated immediately should the memory referred to by the\n\
      handle be moved, swapped or discarded. Keeping the number of tracked\n\
      handles low reduces the number of calls the stub must make to tell\n\
      Swat about handle-state changes.\n\
\n\
    * The <id> passed to the \"lookup\" subcommand is an integer. Its default\n\
      radix is decimal, but you can specify the radix to use in all the\n\
      usual ways. The value returned is the token to use to obtain further\n\
      information about the handle.\n\
\n\
    * \"handle size\" returns the number of bytes allocated to the handle.\n\
\n\
    * \"handle segment\" returns the handle's segment (if it's resident) in\n\
      decimal, as it's intended for use by TCL programs, not people.\n\
\n\
    * \"handle owner\" returns the token of the handle that owns the given\n\
      handle, not its ID.\n\
\n\
    * \"handle all\" returns a list of *handle ID numbers* NOT a list of\n\
      handle tokens. The list is only those handles currently known to Swat.\n\
\n\
    * \"handle interest\" tells Swat you wish to be informed when the handle\n\
      you pass changes state in some way. The procedure <proc> will be\n\
      called with two or more arguments. The first is the token of the\n\
      handle whose state has changed, and the second is the state change the\n\
      handle has undergone, taken from the following set of strings:\n\
	    swapin  	Block swapped in from disk/memory\n\
	    load	Resource freshly loaded from disk\n\
	    swapout 	Block swapped to disk/memory\n\
	    discard 	Block discarded\n\
	    resize	Block changed size and maybe moved\n\
	    move	Block moved on heap\n\
	    free	Block has been freed\n\
	    fchange	Block's HeapFlags changed\n\
      Any further arguments are taken from the <data>+ arguments provided\n\
      when you expressed interest in the handle.\n\
\n\
      This command returns a token for an interest record that you pass to\n\
      \"handle nointerest\" when you no longer care about the handle.  When\n\
      the block is freed (the state change is \"free\"), there is no need to\n\
      call \"handle nointerest\" as the interest record is automatically\n\
      deleted.\n\
\n\
    * \"handle state\" returns an integer indicating the state of the handle.\n\
      The integer is a mask of bits that mean different things:\n\
	    0xf8000 Type        0x00800 LMem        0x00400 Kernel\n\
	    0x00200 Attached    0x00100 Process     0x00080 Resource\n\
	    0x00040 Discarded   0x00020 Swapped     0x00010 Shared\n\
	    0x00008 Fixed   	0x00004 Discardable 0x00002 Swapable\n\
 	    0x00001 Resident\n\
\n\
      When the integer is anded with the mask for Type (0xf8000), the\n\
      following values indicate the following types of handles:\n\
	    0xe0000 Thread  	0xd0000 File	    0xc0000 VM File\n\
	    0xb0000 Semaphore	0xa0000 Saved block 0x90000 Event\n\
	    0x80000 Event with stack data chain	    0x60000 Timer\n\
	    0x70000 Stack data chain element	    0x40000 Event queue\n\
	    	    	    	0x08000 Memory\n\
\n\
    * \"handle other\" returns the handle's otherInfo field. NOTE: This isn't\n\
      necessarily the otherInfo field from the PC. For resource\n\
      handles, e.g., it's the symbol token of the module for the handle.\n\
")
{
    Handle  	handle;

    /*
     * Deal with the handle argument for those that take it.
     */
    if (clientData >= HANDLE_INTEREST) {
	handle = (Handle)atoi(argv[2]);
	if (!VALIDTPTR(handle, TAG_HANDLE)) {
	    Tcl_Error(interp, "invalid handle");
	}
    } else {
	handle = NullHandle;	/* For GCC */
    }
    switch((int)clientData) {
    case HANDLE_LOOKUP:
    {
	word 	id;
	char	*cp;

	id = cvtnum(argv[2], &cp);
	if (*cp == '\0') {
	    handle = Handle_Lookup(id);
	    if (handle != NullHandle) {
		Tcl_RetPrintf(interp, "%d", handle);
	    } else {
		Tcl_Return(interp, "nil", TCL_STATIC);
	    }
	} else {
	    Tcl_Return(interp, "nil", TCL_STATIC);
	}
	break;
    }
    case HANDLE_FIND:
    {
	GeosAddr    addr;
	Frame	    *f = NullFrame;

	if (argc == 4) {
	    f = (Frame *)atoi(argv[3]);
	    if (!VALIDTPTR(f, TAG_FRAME)) {
		Tcl_RetPrintf(interp, "%.50s: invalid frame", argv[3]);
		return(TCL_ERROR);
	    }
	}

	if ((!Expr_Eval(argv[2], f, &addr, (Type *)NULL, TRUE)) ||
	    (addr.handle == NullHandle))
	{
	    Tcl_Return(interp, "nil", TCL_STATIC);
	} else {
	    Tcl_RetPrintf(interp, "%d", addr.handle);
	}
	break;
    }
    case HANDLE_ALL:
    {
	Hash_Entry  *entry;
	Hash_Search search;
	char	    *retval, *cp;

	/*
	 * Each id can be at most 65536, which gives a max length of 6 chars
	 * per id, when you add in the separating spaces and final null. Still
	 * need 1 extra so the final sprintf won't overwrite malloc space.
	 */
	retval = (char *)malloc_tagged(handles.numEntries * 6 + 1, TAG_ETC);

	for (cp = retval, entry = Hash_EnumFirst(&handles, &search);
	     entry != NULL;
	     entry = Hash_EnumNext(&search))
	{
	    sprintf(cp, "%d ", (int)(entry->key.ptr));
	    cp += strlen(cp);
	}
	cp[-1] = '\0';
	Tcl_Return(interp, retval, TCL_DYNAMIC);
	break;
    }
    case HANDLE_SEGMENT:
	Tcl_RetPrintf(interp, "%d", Handle_Segment(handle));
	break;
    case HANDLE_SIZECMD:
	Tcl_RetPrintf(interp, "%d", Handle_Size(handle));
	break;
    case HANDLE_XIPPAGE:
    {
	word	xipPage = Handle_XipPage(handle);

	if (xipPage == HANDLE_NOT_XIP) {
	    Tcl_RetPrintf(interp, "-1");
	} else {
	    Tcl_RetPrintf(interp, "%d", xipPage);
	}
	break;
    }
    case HANDLE_STATE:
	Tcl_RetPrintf(interp, "%d", Handle_State(handle));
	break;
    case HANDLE_OWNER:
	Tcl_RetPrintf(interp, "%d", Handle_Owner(handle));
	break;
    case HANDLE_PATIENT:
	Tcl_RetPrintf(interp, "%d", Handle_Patient(handle));
	break;
    case HANDLE_OTHER:
    {
	/*
	 * To avoid an interface change at this late date, if the handle is
	 * a resource handle, treat the otherInfo field as the resource index
	 * it is and return, instead of the index, the symbol token for that
	 * resource (admittedly, the caller could get it itself, but....)
	 */
	HandlePtr   hp = (HandlePtr)handle;
	
	if ((hp->state & (HANDLE_RESOURCE|HANDLE_KERNEL)) &&
	    (hp->state & HANDLE_MEMORY))
	{
	    if (Sym_IsNull(hp->patient->resources[(int)hp->otherInfo].sym))
	    {
		Tcl_Return(interp, "", TCL_STATIC);
	    }
	    Tcl_Return(interp,
		       Sym_ToAscii(hp->patient->resources[(int)hp->otherInfo].sym),
		       TCL_STATIC);
	} else {
	    Tcl_RetPrintf(interp, "%d", handle->otherInfo);
	}
	break;
    }
    case HANDLE_IDCMD:
	Tcl_RetPrintf(interp, "%d", Handle_ID(handle));
	break;
    case HANDLE_ISTHREAD:
	Tcl_Return(interp,
		   Handle_IsThread(((HandlePtr)handle)->state) ? "1" : "0",
		   TCL_STATIC);
	break;
    case HANDLE_ISKERNEL:
	Tcl_Return(interp,
		   (((HandlePtr)handle)->state & HANDLE_KERNEL) ? "1" : "0",
		   TCL_STATIC);
	break;
    case HANDLE_ISFILE:
	Tcl_Return(interp,
		   Handle_IsFile(((HandlePtr)handle)->state) ? "1" : "0",
		   TCL_STATIC);
	break;
    case HANDLE_ISVM:
	Tcl_Return(interp,
		   Handle_IsVM(((HandlePtr)handle)->state) ? "1" : "0",
		   TCL_STATIC);
	break;
    case HANDLE_ISGSEG:
	Tcl_Return(interp,
		   Handle_IsGSeg(((HandlePtr)handle)->state) ? "1" : "0",
		   TCL_STATIC);
	break;
    case HANDLE_ISMEM:
	Tcl_Return(interp,
		   Handle_IsMemory(((HandlePtr)handle)->state) ? "1" : "0",
		   TCL_STATIC);
	break;
    case HANDLE_ISXIP:
    	Tcl_Return(interp,
		   Handle_XipPage(handle) == HANDLE_NOT_XIP ? "0" : "1", 
		   TCL_STATIC);
    	break;
    case HANDLE_INTEREST:
    {
	TclInterestPtr	tip;

	tip = (TclInterestPtr)malloc_tagged(sizeof(TclInterestRec),
					    TAG_INTRST);
	tip->handle = handle;
	tip->proc = (char *)malloc(strlen(argv[3])+1);
	tip->locked = 0;
	strcpy(tip->proc, argv[3]);
	if (argc == 5) {
	    /*
	     * Use Tcl_Merge to deal with necessary quoting.
	     */
	    tip->data = Tcl_Merge(1, &argv[4]);
	} else {
	    tip->data = NULL;
	}

	Handle_Interest(handle, HandleTclInterest, (Opaque)tip);

	Tcl_RetPrintf(interp, "%d", tip);

	break;
    }
    case HANDLE_NOINTEREST:
    {
	TclInterestPtr	tip = (TclInterestPtr)atoi(argv[2]);

	if (!VALIDTPTR(tip, TAG_INTRST)) {
	    Tcl_RetPrintf(interp, "%s: not a handle interest record",
			  argv[2]);
	    return(TCL_ERROR);
	} else {
	    Handle_NoInterest(tip->handle, HandleTclInterest, (Opaque)tip);
	    if (!tip->locked) {
		free(tip->proc);
		if (tip->data) {
		    free(tip->data);
		}
		free((char *)tip);
	    }
	}
	break;
    }
    }
    return(TCL_OK);
}
    

/***********************************************************************
 *				Handle_Init
 ***********************************************************************
 * SYNOPSIS:	Initialize handle stuff.
 * CALLED BY:	main
 * RETURN:	Nothing
 * SIDE EFFECTS:
 *	'handles' is initialized and the
 *	Types we use for RPCs created..
 *
 * STRATEGY:
 *	init handles table, then create the
 *	Types we use. NOTE: These must be kept up-to-date.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/12/88		Initial Revision
 *
 ***********************************************************************/
void
Handle_Init(void)
{
    Hash_InitTable(&handles, 0, HASH_ONE_WORD_KEYS, 0);
    
    typeFindReply =
	Type_CreatePackedStruct("fr_id", type_Word,
				"fr_dataAddress", type_Word,
				"fr_paraSize", type_Word,
				"fr_owner", type_Word,
				"fr_otherInfo", type_Word,
				"fr_flags", type_Byte,
				"fr_pad", type_Byte,
				"fr_xipPage", type_Word,
				(char *)0);
    GC_RegisterType(typeFindReply);

    typeFindArgs = 
	Type_CreatePackedStruct("fa_address", type_Word,
				"fa_xipPage", type_Word,
				(char *)0);
    GC_RegisterType(typeFindArgs);

    typeInfoReply =
	Type_CreatePackedStruct("ir_dataAddress", type_Word,
				"ir_paraSize", type_Word,
				"ir_owner", type_Word,
				"ir_otherInfo", type_Word,
				"ir_flags", type_Byte,
				"ir_pad", type_Byte,
				"ir_xipPage", type_Word,
				(char *)0);
    GC_RegisterType(typeInfoReply);

    type2WordArg = Type_CreateArray(0, 1, type_Int, type_Word);
    GC_RegisterType(type2WordArg);

    typeReallocArg =
	Type_CreatePackedStruct("ra_handle", type_Word,
				"ra_dataAddress", type_Word,
				"ra_paraSize", type_Word,
				(char *)0);
    GC_RegisterType(typeReallocArg);
    /*
     * Register our servers with the RPC module
     */
    Rpc_ServerCreate(RPC_BLOCK_LOAD, HandleLoad,
		     type2WordArg, NullType, (Rpc_Opaque)NULL);
    Rpc_ServerCreate(RPC_RES_LOAD, HandleResLoad,
		     type2WordArg, NullType, (Rpc_Opaque)NULL);
    Rpc_ServerCreate(RPC_BLOCK_OUT, HandleOut,
		     type2WordArg, NullType, (Rpc_Opaque)NULL);
    Rpc_ServerCreate(RPC_BLOCK_MOVE, HandleMove,
		     type2WordArg, NullType, (Rpc_Opaque)NULL);
    Rpc_ServerCreate(RPC_BLOCK_REALLOC, HandleRealloc,
		     typeReallocArg, NullType, (Rpc_Opaque)NULL);
    Rpc_ServerCreate(RPC_BLOCK_FREE, HandleFree,
		     type_Word, NullType, (Rpc_Opaque)NULL);

    /*
     * Catch EXIT events to nuke non-resource handles owned by the patient
     */
    Event_Handle(EVENT_EXIT, 0, HandleExit, (ClientData)NULL);
    
    /*
     * Catch CONTINUE and DETACH events to flush cached handles
     */
    Event_Handle(EVENT_CONTINUE, 0, HandleFlush, (ClientData)NULL);
    Event_Handle(EVENT_DETACH, 0, HandleFlush, (ClientData)NULL);

    Cmd_Create(&HandleCmdRec);
}
