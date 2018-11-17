/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  st.h
 *
 * AUTHOR:  	  Adam de Boor: Aug  3, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 3/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header file for users of the ST string table module. All binary
 *	data for the table are written in the current machine's
 *	byte-order. The client of this module is expected to register
 *	a relocation routine with the VM module and call ST_Reloc when
 *	a string-table block is brought into memory, should byte-swapping
 *	be necessary. See below for the VMID numbers assigned to all
 *	string-table blocks.
 *
 * 	$Id: st.h,v 1.6 91/04/26 11:49:14 adam Exp $
 *
 ***********************************************************************/
#ifndef _ST_H_
#define _ST_H_

/*
 * The string table module is layered on top of the VM module...
 */
#include    <vm.h>

/*
 * Value returned by ST_Enter and ST_Lookup and passed to
 * ST_Lock and ST_Unlock to indicate what string is to be locked
 * or unlocked.
 */
typedef unsigned long	ID;
#define NullID	((ID)0)

/*
 * Initialize a string table in a VM file. Returns the block handle that
 * must be passed to all future ST functions to indicate the table
 * to be used.
 */
extern VMBlockHandle	ST_Create(VMHandle    	vmHandle);

/*
 * Given a table, a name, and the name's length, return the ID for the
 * name. The name will be entered in the table if not already there.
 */
extern ID   	    	ST_Enter(VMHandle   	vmHandle,
				 VMBlockHandle	table,
				 char   	*name,
				 int    	len);
/*
 * Similar to above, but calls strlen(name) before calling ST_Enter.
 * This is a code-saving device, no more.
 */
extern ID   	    	ST_EnterNoLen(VMHandle	    vmHandle,
				      VMBlockHandle table,
				      char   	    *name);

/*
 * Copy a string from one string table to another. This is used in preference
 * to locking the string and calling ST_EnterNoLen, as the all the info
 * required can be gotten from the source table.
 */
extern ID   	    	ST_Dup(VMHandle	    	vmSrcHandle,
			       ID   	    	srcID,
			       VMHandle	    	vmDstHandle,
			       VMBlockHandle	dstTable);

/*
 * Look up a string from one string table in another. This is used in preference
 * to locking the string and calling ST_LookupNoLen, as the all the info
 * required can be gotten from the source table. Returns NullID if the string
 * isn't in the destination table.
 */
extern ID   	    	ST_DupNoEnter(VMHandle	    	vmSrcHandle,
				      ID   	    	srcID,
				      VMHandle	    	vmDstHandle,
				      VMBlockHandle	dstTable);

/*
 * Given a table, a name, and the name's length, return the ID for the
 * name. If the name isn't in the table, returns NullID rather than entering
 * the name into the table.
 */
extern ID   	    	ST_Lookup(VMHandle  	vmHandle,
				  VMBlockHandle	table,
				  const char   	*name,
				  int    	len);
/*
 * Similar to above, but calls strlen(name) before calling ST_Lookup.
 * This is a code-saving device, no more.
 */
extern ID   	    	ST_LookupNoLen(VMHandle	    	vmHandle,
				       VMBlockHandle	table,
				       const char      	*name);

/*
 * Lock down a string for use by caller.
 */
#define ST_Lock(vmHandle,id) \
    ((char *)VMLock((vmHandle),(VMBlockHandle)((id)>>16),(MemHandle *)NULL)+((id)&0xffff))

/*
 * Release a string after it's been used
 */
#define ST_Unlock(vmHandle,id) \
    VMUnlock((vmHandle),(id))

/*
 * Return the index for an identifier. This is a hash value that can be used
 * by other modules to allow for a better hashing of things on the ID than can
 * be achieved by using the ID itself.
 */
extern word 	    	ST_Index(VMHandle   vmHandle,
				 ID 	    id);

/*
 * Finish with a string table, releasing any extra space that may
 * have been allocated with an eye toward efficiency...
 *
 * Returns non-zero if table is non-empty. If table *is* empty, the caller
 * is free to (read: should) call VMFree(vmHandle, table).
 */
extern int 	    	ST_Close(VMHandle   	vmHandle,
				 VMBlockHandle	table);

/*
 * Destroy a string table, freeing up all its VM blocks.
 */
extern void 	    	ST_Destroy(VMHandle   	    vmHandle,
				   VMBlockHandle    table);

/*
 * Relocation routine for the two types of binary-data blocks in a symbol
 * table. This routine takes care of byte-swapping all the entries in
 * the block. It is only to be called if the byte-order of the file doesn't
 * match that of the current machine when the VMID of the block matches one
 * of the two ID's defined below.
 */
#define ST_HEADER_ID	((VMID)0x0001)
#define ST_CHAIN_ID 	((VMID)0x0002)
extern VMRelocRoutine	ST_Reloc;

/*
 * Routines for setting the string table file used by %i in printf.
 */
extern void UtilSetIDFile(VMHandle file);
extern VMHandle UtilGetIDFile(void);
#endif /* _ST_H_ */
