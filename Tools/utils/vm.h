/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM file manipulation
 * FILE:	  vm.h
 *
 * AUTHOR:  	  Adam de Boor: Jul 17, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/17/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header file for clients of the C/UNIX implementation of
 *	PC GEOS VM files.
 *
 *
 * 	$Id: vm.h,v 3.13 93/10/12 13:37:14 gene Exp $
 *
 ***********************************************************************/
#ifndef _VM_H_
#define _VM_H_

#include    <os90File.h>
#include    <mem.h>
#include    <lmem.h>

typedef genptr  VMHandle;    	/* Handle to open VM file */
typedef word 	VMBlockHandle; 	/* Handle to block in VM file */
typedef word 	VMID;	     	/* Identifier assigned to a
				 * VMBlockHandle by the user */

#define SVMID_DB_MAP	    0xff00
#define SVMID_DB_GROUP	    0xff01
#define SVMID_DB_ITEM	    0xff02
#define SVMID_HA_DIR	    0xff03
#define SVMID_HA_BLOCK	    0xff04

typedef unsigned long VMPtr;
#define VMP_BLOCK(ptr)	((VMBlockHandle) (((ptr) >> 16) & 0xffff))
#define VMP_OFFSET(ptr)	((ptr) & 0xffff)
#define MAKE_VMP(block, offset) (((block)<<16)|((offset) & 0xffff))
#define NullVMPtr 0

/*
 * Routine called to relocate a block, if defined for the VMHandle.
 * vmHandle, vmBlock and vmID identify the block just loaded, while
 * block points to the base of the block to be relocated.
 *
 * XXX: direction flag? with callout on block write as well? would then need
 * another call after block is written to relocate the thing to be
 * memory-resident again...
 */
typedef void	    VMRelocRoutine(VMHandle 	    vmHandle,
				   VMBlockHandle    vmBlock,
				   VMID    	    vmID,
				   MemHandle	    handle,
				   genptr    	    block);
/*
 * Open a VM file, returning the handle by which it should be accessed.
 *
 * Access and sharing modes are also passed in the flags word.
 *
 * Compress is the compression threshold (as a percentage of used to total
 * allocated below which the file will be compressed).
 *
 * reloc may be NULL if no special relocation is required.
 */
extern VMHandle	    	VMOpen(short flags, short compress,
			       const char *fileName,
			       short *status);
/* FLAGS argument: */
#define VMO_OPEN_TYPE	0xff00	    /* Mask for type of open: */
#define VMO_CREATE_TRUNCATE 0x0400  	/* Truncate file if it exists, else
					 * create it */
#define VMO_CREATE_ONLY	0x0300	    	/* Can only create the file -- it
					 * cannot have existed before the
					 * VMOpen call */
#define VMO_TEMP_FILE	0x0200	    	/* Opening temp file (file removed on
					 * close). fileName is actually the
					 * directory in which a uniquely named
					 * file will be created */
#define VMO_CREATE  	0x0100	    	/* Create the given file if doesn't
					 * exist. */
#define VMO_OPEN    	0x0000	    	/* Open existing VM file */

#define VMO_SHARE_MODE	0x00f0	    /* Permissions for other openers */
#define     FILE_DENY_RW	0x0090	    /* Exclusive */
#define     FILE_DENY_W 	0x00a0	    /* No one else may modify */
#define     FILE_DENY_R 	0x00b0	    /* No on else may read */
#define     FILE_DENY_NONE	0x00c0	    /* Summer of Love mode */

#define VMO_ACCESS_TYPE	0x0003	    /* The way we want to access it */
#define	    FILE_ACCESS_R   	0x0000	    /* Read only */
#define	    FILE_ACCESS_W   	0x0001	    /* Write only (?!) */
#define	    FILE_ACCESS_RW  	0x0002

/* STATUS return: */
#define VM_OPEN_OK  	    0x0080  /* Uninhibited open, file existed */
#define VM_CREATE_OK	    0x0081  /* Uninhibited open, file created */
#define VM_SHARING_OK	    0x0082  /* Open successful -- file shared */
#define VM_SHARING_DENIED   0x0083  /* Open unsuccessful -- conflicting
				     * SHARE_MODEs */

/*
 * Lock a VM block down, returning its address and handle.
 */
extern genptr 	    	 VMLock(VMHandle	vmHandle,
				VMBlockHandle   vmBlock,
				MemHandle   	*handlePtr);

#define VMLockVMPtr(file, vmp, han) \
    	    	    (VMLock(file, VMP_BLOCK(vmp), han)+VMP_OFFSET(vmp))

/*
 * Release a VM block, allowing it to go away, if necessary.
 */
#define VMUnlock(vmHandle, vmBlock)

/*
 * Mark a VM block as dirty, then unlock it. In a real implementation, this
 * would be an actual function. However, since VMUnlock is a no-op, we
 * just make it a macro for VMDirty.
 */
#define VMUnlockDirty(vmHandle, vmBlock) VMDirty(vmHandle, vmBlock)

extern void 	    	VMEmpty(VMHandle  	vmHandle,
				VMBlockHandle	vmBlock);
/*
 * Allocate a new VM block, returning its block handle.
 * If numBytes is 0, a single paragraph is allocated.
 * The memory is initialized to 0.
 */
extern VMBlockHandle	VMAlloc(VMHandle    vmHandle,
				int 	    numBytes,
				VMID	    id);
/*
 * Free a VM block and its data
 */
extern void 	    	VMFree(VMHandle	    	vmHandle,
			       VMBlockHandle	vmBlock);

/*
 * Mark a VM block as dirty
 */
extern void 	    	VMDirty(VMHandle    	vmHandle,
				VMBlockHandle	vmBlock);

/*
 * Close a VM file, removing it if the file was temporary.
 */
extern void 	    	VMClose(VMHandle    	vmHandle);

/*
 * Play with the map block for the file. The map block of a VM file is
 * a well-known block the application can use to find its way to the
 * other blocks in the file. Without such a thing, how would you know where
 * to begin?
 */
extern VMBlockHandle	VMGetMapBlock(VMHandle	vmHandle);
extern void 	    	VMSetMapBlock(VMHandle	    vmHandle,
				      VMBlockHandle vmBlock);

/*
 * Play with the map block for the DB portion of the file. Not to be messed
 * with lightly :)
 */
extern VMBlockHandle	VMGetDBMap(VMHandle	    vmHandle);
extern void 	    	VMSetDBMap(VMHandle 	    vmHandle,
				   VMBlockHandle    vmBlock);

/*
 * Flush all modified VM blocks to disk. Returns 0 on success, else an error
 * code.
 */
extern int  	    	VMUpdate(VMHandle   vmHandle);

/*
 * Set the routine to relocate loaded blocks. Can be used if it's unclear
 * when the file is first opened if blocks will need relocating or not.
 */
extern void 	    	VMSetReloc(VMHandle 	    vmHandle,
				   VMRelocRoutine   *reloc);
				   
/*
 * Functions to manipulate the standard geos file header on the file.
 */
extern void  	    	VMGetHeader(VMHandle	    vmHandle,
				    genptr  gfhPtr);
extern void  	    	VMSetHeader(VMHandle	    vmHandle,
				    genptr  gfhPtr);
/*
 * Returns major version of PC/GEOS for which the file was created.
 */
extern int  	    	VMGetVersion(VMHandle	vmHandle);

/*
 * Fetch info about a VM block
 */
extern void 	    	VMInfo(VMHandle	    	vmHandle,
			       VMBlockHandle	vmBlock,
			       word 	    	*sizePtr,
			       MemHandle    	*memPtr,
			       VMID 	    	*idPtr);

/*
 * Set/get attribute bits for the file
 */
extern byte 	    	VMGetAttributes(VMHandle    vmHandle);
extern void 	    	VMSetAttributes(VMHandle    vmHandle,
					byte	    set,
					byte	    reset);
#define VMA_SYNC_UPDATE		0x80	    /* Allow synchronous updates only.
					     * Tells the system it may not
					     * write dirty blocks to the file
					     * except via a VMUpdate */
#define VMA_BACKUP		0x40	    /* Maintain a backup copy of all
					     * data */
#define VMA_OBJECT_RELOC	0x20	    /* Use built-in object relocation
					     * routines to relocate and
					     * unrelocate blocks as they
					     * come in and go out */
#define VMA_PRESERVE_HANDLES    0x10	    /* Preserve memory handles while
					     * file is open, even if block
					     * is written to disk or discarded
					     */
#define VMA_NOTIFY_DIRTY    	0x08	    /* Notify when first block marked
					     * dirty */
/*
 * Mark a VM block as containing an LMem heap
 */
extern void 	    VMSetLMemFlag(VMHandle  	vmHandle,
				  VMBlockHandle	vmBlock);
/*
 * Mark a VM block as needing to have its memory handle preserved.
 */
extern void 	    VMSetPreserveFlag(VMHandle  	vmHandle,
				      VMBlockHandle	vmBlock);

/*
 * Fetch the data from a VM block into a memory block unassociated with the file
 */
extern MemHandle    VMDetach(VMHandle vmHandle, VMBlockHandle vmBlock);

/*
 * Attach a block of memory to an existing VM block
 */
extern void 	    VMAttach(VMHandle vmHandle, VMBlockHandle vmBlock,
			     MemHandle mem);

/*
 * DBASE DATA STRUCTURES
 */
typedef struct {
    word    	DBIBI_next; 	/* Next item block in list */
    word    	DBIBI_block;	/* VM handle of item block */
    short   	DBIBI_refCount;	/* Number of items in the block */
} DBItemBlockInfo;

typedef struct {
    word    	DBII_block; 	/* Offset of DBItemBlockInfo */
    word    	DBII_chunk; 	/* LMem chunk of item within the block */
} DBItemInfo;

typedef struct {
    word    	DBGH_vmemHandle;    /* VM block handle of the group */
    word    	DBGH_handle;	    /* Memory handle of the group */
    word    	DBGH_flags; 	    /* Flags for the group: */
#define DBGF_IS_UNGROUP	    0x8000  	/* Set if the group is the "ungroup" for
					 * the file */
    word    	DBGH_itemBlocks;    /* Head of DBItemBlockInfo list */
    word    	DBGH_itemFreeList;  /* Head of free-DBItemInfo list */
    word    	DBGH_blockFreeList; /* Head of free-DBItemBlockInfo list */
    word    	DBGH_blockSize;	    /* Size of the group block */
} DBGroupHeader;

typedef struct {
    LMemBlockHeader 	DBIBH_standard;
    word    	    	DBIBH_vmHandle;	    /* VM Block handle for this block */
    word    	    	DBIBH_infoStruct;   /* Offset within group block of
					     * the DBItemBlockInfo structure
					     * for this block */
} DBItemBlockHeader;

typedef struct {
    word    	DBMB_vmemHandle;    	/* VM block handle of this block */
    word    	DBMB_handle;	    	/* Memory handle of this block */
    word    	DBMB_mapGroup;	    	/* VM block handle of group containing
					 * the map item */
    word    	DBMB_mapItem;	    	/* Offset of DBItemInfo structure for
					 * the map item within that block */
    word    	DBMB_ungrouped;	    	/* Current "ungrouped" group */
} DBMapBlock;

/*
 * Convert a SBCS string into a DBCS string.
 * Returns the size of the DBCS string.
 */
extern int  	VMCopyToDBCSString(char *dest,
				   char *source,
				   int max);


#endif /* _VM_H_ */
