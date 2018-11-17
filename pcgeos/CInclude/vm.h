/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	vm.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines VM structures and routines.
 *
 *	$Id: vm.h,v 1.1 97/04/04 15:56:57 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__VMEM_H
#define __VMEM_H

#include <lmem.h>

/* VMOpen status codes */

#define VM_OPEN_OK_READ_ONLY			256
#define VM_OPEN_OK_TEMPLATE 	    	    	257
#define VM_OPEN_OK_READ_WRITE_NOT_SHARED    	258
#define VM_OPEN_OK_READ_WRITE_SINGLE		259
#define VM_OPEN_OK_READ_WRITE_MULTIPLE		260
#define VM_OPEN_OK_BLOCK_LEVEL			261
#define VM_CREATE_OK				262

/* VMGrabExclusive return values */

typedef enum /* word */ {
    VMSERV_NO_CHANGES,
    VMSERV_CHANGES,
    VMSERV_TIMEOUT
} VMStartExclusiveReturnValue;

/* VM operations (for transaction based apps) */

typedef enum /* word */ {
    VMO_READ,
    VMO_INTERNAL,
    VMO_SAVE,
    VMO_SAVE_AS,
    VMO_REVERT,
    VMO_UPDATE,
    VMO_WRITE
} VMOperation;

#define VMO_FIRST_APP_CODE	0x8000

/* VM error codes */

#define VM_FILE_EXISTS				263
#define VM_FILE_NOT_FOUND			264
#define VM_SHARING_DENIED			265
#define VM_OPEN_INVALID_VM_FILE			266
#define VM_CANNOT_CREATE			267
#define VM_TRUNCATE_FAILED			268
#define VM_WRITE_PROTECTED			269
#define VM_CANNOT_OPEN_SHARED_MULTIPLE	    	270
#define VM_FILE_FORMAT_MISMATCH		        271

/* VMUpdate status codes */

#define VM_UPDATE_NOTHING_DIRTY			272
#define VM_UPDATE_INSUFFICIENT_DISK_SPACE	273
#define VM_UPDATE_BLOCK_WAS_LOCKED		274

/* VMDiscardDirtyBlock status codes */

#define  VM_DISCARD_CANNOT_DISCARD_BLOCK        275

/* Macros for VMChain */

#define VMCHAIN_IS_DBITEM(chain) \
    ((word) (chain))
#define VMCHAIN_GET_VM_BLOCK(chain) \
    ((VMBlockHandle) ((chain) >> 16))
#define VMCHAIN_MAKE_FROM_VM_BLOCK(block) \
    (((VMChain) (block)) << 16)

/* VM file attributes */

typedef ByteFlags VMAttributes;
#define VMA_SYNC_UPDATE			0x80
#define VMA_BACKUP			0x40
#define VMA_OBJECT_RELOC		0x20
#define VMA_NOTIFY_DIRTY		0x08
#define VMA_NO_DISCARD_IF_IN_USE	0x04
#define VMA_COMPACT_OBJ_BLOCK		0x02
#define VMA_SINGLE_THREAD_ACCESS	0x01

/* Attribute bits that must be enabled if the file contains object blocks */

#define VMA_OBJECT_ATTRS (VMA_OBJECT_RELOC | VMA_NO_DISCARD_IF_IN_USE \
			  | VMA_SINGLE_THREAD_ACCESS)


/***/

extern void *
    _pascal VMLock(VMFileHandle file, VMBlockHandle block, MemHandle *mh);

/***/

extern void
    _pascal VMUnlock(MemHandle mh);

/***/

extern VMBlockHandle
    _pascal VMAlloc(VMFileHandle file, word size, word userId);

/***/

extern VMBlockHandle	/*XXX*/
    _pascal VMFind(VMFileHandle file, VMBlockHandle startBlock, word userId);

/***/

extern void	/*XXX*/
    _pascal VMFree(VMFileHandle file, VMBlockHandle block);

/***/

extern void
    _pascal VMDirty(MemHandle mh);

/***/

extern void	/*XXX*/
    _pascal VMModifyUserID(VMFileHandle file, VMBlockHandle block, word userId);

/***/

typedef struct {
    MemHandle	mh;
    word	size;
    word	userId;
} VMInfoStruct;

extern Boolean	/*XXX*/
    _pascal VMInfo(VMFileHandle file, VMBlockHandle block, VMInfoStruct *info);

/***/

#define VMDIRTY_SINCE_LAST_SAVE(val) \
    ((val) & 0xff)
#define VMDIRTY_SINCE_LAST_AUTO_SAVE(val) \
    ((val) >> 8)

extern word	/*XXX*/
    _pascal VMGetDirtyState(VMFileHandle file);

/***/

extern VMBlockHandle
    _pascal VMGetMapBlock(VMFileHandle file);

/***/

extern void
    _pascal VMSetMapBlock(VMFileHandle file, VMBlockHandle block);

/***/

typedef ByteEnum VMOpenType;
#define VMO_OPEN 0
#define VMO_TEMP_FILE 1
#define VMO_CREATE 2
#define VMO_CREATE_ONLY 3
#define VMO_CREATE_TRUNCATE 4

#define VMO_NATIVE_WITH_EXT_ATTRS   0x80

typedef ByteFlags VMAccessFlags;
#define VMAF_FORCE_READ_ONLY	    	    0x80
#define VMAF_FORCE_READ_WRITE	    	    0x40
#define VMAF_ALLOW_SHARED_MEMORY    	    0x20
#define VMAF_FORCE_DENY_WRITE	    	    0x10
#define VMAF_DISALLOW_SHARED_MULTIPLE	    0x08
#define VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION 0x04
#define VMAF_FORCE_SHARED_MULTIPLE  	    0x02

extern VMFileHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal VMOpen(char *name, VMAccessFlags flags, VMOpenType mode, word compression);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal VMUpdate(VMFileHandle file);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal VMClose(VMFileHandle file, Boolean noErrorFlag);

/***/

extern word	/*XXX*/
    _pascal VMGetAttributes(VMFileHandle file);

/***/

extern VMAttributes	/*XXX*/
    _pascal VMSetAttributes(VMFileHandle file,
		    VMAttributes attrToSet,
		    VMAttributes AttrToClear);

/***/

extern VMStartExclusiveReturnValue
    _pascal VMGrabExclusive(VMFileHandle file,
		    word timeout,
		    VMOperation operation,
		    VMOperation *currentOperation);

/***/

extern void
    _pascal VMReleaseExclusive(VMFileHandle file);

/***/

extern Boolean	/*XXX*/
    _pascal VMCheckForModifications(VMFileHandle file);

/***/

typedef enum /* word */ {
    VMRT_UNRELOCATE_BEFORE_WRITE,
    VMRT_RELOCATE_AFTER_READ,
    VMRT_RELOCATE_AFTER_WRITE,
    VMRT_RELOCATE_FROM_RESOURCE,
    VMRT_UNRELOCATE_FROM_RESOURCE,
} VMRelocType;

/* HELP !!! DON'T USE THIS ROUTINE FROM C */
extern void	/*XXX*/
    _pascal VMSetReloc(VMFileHandle file,
	       PCB(void, reloc,(VMFileHandle file,
			     VMBlockHandle block,
			     MemHandle mh,
			     void *data,
			     VMRelocType type)));

/***/

extern VMBlockHandle
    _pascal VMAttach(VMFileHandle file, VMBlockHandle block, MemHandle mh);

/***/

extern MemHandle	/*XXX*/
    _pascal VMDetach(VMFileHandle file, VMBlockHandle block, GeodeHandle owner);

/***/

extern VMBlockHandle	/*XXX*/
    _pascal VMMemBlockToVMBlock(MemHandle mh, VMFileHandle *file);

/***/

extern MemHandle	/*XXX*/
    _pascal VMVMBlockToMemBlock(VMFileHandle file, VMBlockHandle block);

/***/

extern Boolean	/*XXX*/
    _pascal VMSave(VMFileHandle file);

/***/

extern VMFileHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal VMSaveAs(VMFileHandle file,
	     const char *name,
	     VMAccessFlags flags,
	     VMOpenType mode,
	     word compression);

/***/

extern void	/*XXX*/
    _pascal VMRevert(VMFileHandle file);

/***/

extern void	/*XXX*/
    _pascal VMPreserveBlocksHandle(VMFileHandle file, VMBlockHandle block);

/***/

extern VMChain	/*XXX*/
    _pascal VMCopyVMChain(VMFileHandle sourceFile,
		  VMChain sourceChain,
		  VMFileHandle destFile);

/***/

extern void	/*XXX*/
    _pascal VMFreeVMChain(VMFileHandle file, VMChain chain);

/***/

extern Boolean	/*XXX*/
    _pascal VMCompareVMChains(VMFileHandle sourceFile,
		      VMChain sourceChain,
		      VMFileHandle destFile,
		      VMChain destChain);

/***/

extern Boolean	/*XXX*/
    _pascal VMInfoVMChain(VMFileHandle sourceFile,
			  VMChain sourceChain,
			  dword *chainSize,
			  word  *vmBlockCount,
			  word  *dbItemCount
		      );

/***/

extern VMBlockHandle	/*XXX*/
    _pascal VMCopyVMBlock(VMFileHandle sourceFile,
		  VMBlockHandle sourceBlock,
		  VMFileHandle destFile);


/* Structure of a VM chain */

#define VM_CHAIN_TREE		0xffff

typedef struct {
    VMBlockHandle	VMC_next;
} VMChainLink;

typedef struct {
    VMChainLink		VMCT_meta;
    word		VMCT_offset;
    word		VMCT_count;
} VMChainTree;

/***/

extern void	/*XXX*/
    _pascal VMSetExecThread(VMFileHandle file, ThreadHandle thread);

/***/

extern VMBlockHandle	/*XXX*/
    _pascal VMAllocLMem(VMFileHandle file, LMemType ltype, word headerSize);

/***/

typedef struct {
    word	usedBlocks;
    word	headerSize;
    word	freeBlocks;
} VMHeaderInfoStruct;

extern void	/*XXX*/
    _pascal VMGetHeaderInfo(VMFileHandle file, VMHeaderInfoStruct *vmInfo);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal VMDiscardDirtyBlocks(VMFileHandle file);

/***/

/*
 *		System VM ID's
 *
 *      VM ID's from 0xff00 to 0xffff are reserved for use by the 
 *      system and system libraries
 */

#define SVMID_RANGE_DBASE  	0xff00	/* Reserved for DB code */

typedef enum /* word */ {

    DB_MAP_ID = 0xff00,		/*  ID for DB map block */
    DB_GROUP_ID,		/*  ID for new DB group */
    DB_ITEM_BLOCK_ID,		/*  ID for new DB item block */
    SVMID_HA_DIR_ID,		/*  ID for HugeArray dir blocks */
    SVMID_HA_BLOCK_ID,		/*  ID for HugeArray data blocks */
    SVMID_DOCUMENT_NOTES,	/*  ID for document note block */

} SystemVMID;

extern void     /*XXX*/
   _pascal VMSetDirtyLimit(VMFileHandle file, word dirtyLimit);

extern void
   _pascal VMEnforceHandleLimits(VMFileHandle file, word low, word high);

/***/


#ifdef __HIGHC__
pragma Alias(VMLock, "VMLOCK");
pragma Alias(VMUnlock, "VMUNLOCK");
pragma Alias(VMAlloc, "VMALLOC");
pragma Alias(VMFind, "VMFIND");
pragma Alias(VMFree, "VMFREE");
pragma Alias(VMDirty, "VMDIRTY");
pragma Alias(VMModifyUserID, "VMMODIFYUSERID");
pragma Alias(VMInfo, "VMINFO");
pragma Alias(VMGetDirtyState, "VMGETDIRTYSTATE");
pragma Alias(VMGetMapBlock, "VMGETMAPBLOCK");
pragma Alias(VMSetMapBlock, "VMSETMAPBLOCK");
pragma Alias(VMOpen, "VMOPEN");
pragma Alias(VMUpdate, "VMUPDATE");
pragma Alias(VMClose, "VMCLOSE");
pragma Alias(VMGetAttributes, "VMGETATTRIBUTES");
pragma Alias(VMSetAttributes, "VMSETATTRIBUTES");
pragma Alias(VMGrabExclusive, "VMGRABEXCLUSIVE");
pragma Alias(VMReleaseExclusive, "VMRELEASEEXCLUSIVE");
pragma Alias(VMCheckForModifications, "VMCHECKFORMODIFICATIONS");
pragma Alias(VMSetReloc, "VMSETRELOC");
pragma Alias(VMAttach, "VMATTACH");
pragma Alias(VMDetach, "VMDETACH");
pragma Alias(VMMemBlockToVMBlock, "VMMEMBLOCKTOVMBLOCK");
pragma Alias(VMVMBlockToMemBlock, "VMVMBLOCKTOMEMBLOCK");
pragma Alias(VMSave, "VMSAVE");
pragma Alias(VMSaveAs, "VMSAVEAS");
pragma Alias(VMRevert, "VMREVERT");
pragma Alias(VMPreserveBlocksHandle, "VMPRESERVEBLOCKSHANDLE");
pragma Alias(VMCopyVMChain, "VMCOPYVMCHAIN");
pragma Alias(VMFreeVMChain, "VMFREEVMCHAIN");
pragma Alias(VMCompareVMChains, "VMCOMPAREVMCHAINS");
pragma Alias(VMCopyVMBlock, "VMCOPYVMBLOCK");
pragma Alias(VMInfoVMChain, "VMINFOVMCHAIN");
pragma Alias(VMSetExecThread, "VMSETEXECTHREAD");
pragma Alias(VMAllocLMem, "VMALLOCLMEM");
pragma Alias(VMGetHeaderInfo, "VMGETHEADERINFO");
pragma Alias(VMDiscardDirtyBlocks, "VMDISCARDDIRTYBLOCKS");
pragma Alias(VMSetDirtyLimit, "VMSETDIRTYLIMIT");
pragma Alias(VMEnforceHandleLimits, "VMENFORCEHANDLELIMITS");
#endif

#endif


