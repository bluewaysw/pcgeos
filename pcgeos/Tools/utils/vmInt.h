/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Utilities -- VM Internal definitions.
 * FILE:	  vmInt.h
 *
 * AUTHOR:  	  Adam de Boor: Aug  1, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 1/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Internal header file for VM module.
 *
 *	UNIX implementation of PC/GEOS VM facilities.
 *
 *	For now, this implementation is incomplete. It will need
 *	substantial revision before being included in the MPDE.
 *
 *	This library is intended to allow a UNIX-based tool to create
 *	and modify a VM file for PC GEOS. There's no support for
 *	concurrency (there being no multi-threaded UNIX-based tools here).
 *
 *	All VM-related structures are written in the PC's byte order.
 *	They are created and maintained in native order when in-core,
 *	however, except for the VMFileHeader, which we use only on
 *	open and modify only on update. Hence the file header is always
 *	kept in the PC byte order, even in-core.
 *
 *	As for the OS90 VM, space in the file isn't actually allocated
 *	until the block is written out. This means that, since blocks
 *	are never thrown out here, there is no compression required
 *	unless something needs to actually *edit* a VM file. Until that
 *	time, therefore, compression isn't implemented.
 *
 *	Internally, the "assigned" list is kept as a singly-linked
 *	list, with back-links being established only when the header
 *	is written out, if necessary. See below for why I doubt
 *	it will be...
 *
 * NOTES:
 *	As a first-pass implementation, this lacks certain important
 *	facilities. The expected uses of these functions are:
 *
 *	    - creation and final update. Used by Esp and Glue in the
 *	      creation of their output files. All data are kept in-core and
 *	      only at the end written out to the file. File space isn't
 *	      allocated to any block until the file is closed.
 *	    - read-only access. Swat and Glue treat Glue and Esp output,
 *	      respectively, in this manner, using the VM file merely as
 *	      a source of data. The data are never changed.
 *
 *	These and time constraints necessitate the lack of:
 *	    - compaction -- blocks never get freed, or if they do, they
 *	      won't have been written to disk yet, so they'll have no
 *	      space in the file.
 *	    - the size of the block is kept in the VMB_size field of the
 *	      VMBlock record. Since we never need to alter the size of
 *	      a block on disk (blocks are either built in memory and
 *	      written to disk at close time or simply read from disk), it
 *	      seems pointless to keep the size of the block in memory
 *	      and its size on disk separate. This will be necessary for
 *	      MPDE, but perhaps using a PD malloc library (in contrast
 *	      to what Swat has, which is Sun-proprietary) and adding a
 *	      malloc_size function.
 *
 * 	$Id: vmInt.h,v 3.9 96/05/20 18:58:22 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _VMINT_H_
#define _VMINT_H_

#include    <vm.h>

#include    "fileUtil.h"
#include    <assert.h>
#include    <stddef.h>	/* Must come *after* or our kludge to gcc's stddef.h
			 * will cause stdtypes.h to have no effect, preventing
			 * the other types in there from being defined. */

#define VM_INIT_NUM_BLKS    	((65536-sizeof(VMHeader))/sizeof(VMBlock))
    	    	    	    	    /* Number of VM block handles to create
				     * initially */
#define VM_EXTEND_NUM_BLKS  	3   /* Number of VM block handles to add
				     * when need to extend the table */
#define VM_DEF_COMPACT_THRESH	70  /* Default compaction threshold (just
				     * stored; not actually used) */
/******************************************************************************
 *
 *		      Header for VM file on disk
 *
 *****************************************************************************/
typedef struct {
    GeosFileHeader  VMFH_gfh;
    word	    VMFH_signature;	/* Signature (magic number) */
#define VMFH_SIG	0xadeb
    word    	    VMFH_headerSize;    /* Size of header block */
    dword   	    VMFH_headerPos; 	/* Offset into file of the block */
} VMFileHeader;

typedef struct {
    GeosFileHeader2  VMFH_gfh;
    word	    VMFH_signature;	/* Signature (magic number) */
#define VMFH_SIG	0xadeb
    word    	    VMFH_headerSize;    /* Size of header block */
    dword   	    VMFH_headerPos; 	/* Offset into file of the block */
    word    	    VMFH_updateCounter;	/* Counter incremented on changes */
    word    	    VMFH_updateType;	/* Type of operation being performed */
#define VMO_READ    	    0
#define VMO_INTERNAL	    1
#define VMO_SAVE    	    2
#define VMO_SAVE_AS 	    3
#define VMO_REVERT  	    4
#define VMO_UPDATE  	    5
#define VMO_WRITE   	    6
#define VMO_FIRST_APP_CODE  0x8000
    word    	    VMFH_reserved[6];	/* Reserved for future use */
} VMFileHeader2;    	/* 2.0 version */

/******************************************************************************
 *
 *		  Data that make up a block handle.
 *
 *****************************************************************************/
typedef union {
    struct {
	MemHandle    	VMBU_memHandle;	/* Memory handle (0 if not resident
					 * or header block) */
	byte        	VMBU_sig;   	/* Signature for used block (0 if not
					 * used) */
#define VM_USED_BLK_SIG	    0xff    	    /* Signature (is illegal handle) */
#define VM_DIRTY_BLK_SIG    0xfe	    /* Signature if dirty (also an
					     * illegal handle) */
#define VM_IN_USE(block) ((block)->VMB_used.VMBU_sig >= VM_DIRTY_BLK_SIG)
	byte	    	VMBU_flags; 	/* Flags for block */
#define VMBF_LMEM    	0x01	    	    /* Block contains LMem heap */
#define VMBF_HAS_BACKUP	0x02	    	    /* Block has backup version
					     * (unused here) */
#define VMBF_PRESERVE	0x04	    	    /* Preserve block's handle while
					     * file is open (unused here); 2.0
					     * only */
	VMID        	VMBU_uid;   	/* ID assigned to block by user */
	word        	VMBU_size; 	/* Size of block in file */
	dword       	VMBU_pos; 	/* Position in file */
    } VMB_used;
    struct {
	VMBlockHandle	VMBF_nextPtr;	/* Handle of next block in chain */
	VMBlockHandle	VMBF_prevPtr;	/* Handle of previous block in chain */
	dword        	VMBF_size; 	/* Size of block on disk (if 0, handle
					 * is unassigned) */
	dword	    	VMBF_pos;   	/* Position of block in file */
    } VMB_free;
} VMBlock;

#define VMB_memHandle	VMB_used.VMBU_memHandle
#define VMB_sig	    	VMB_used.VMBU_sig
#define VMB_flags   	VMB_used.VMBU_flags
#define VMB_uid	    	VMB_used.VMBU_uid
#define VMB_size    	VMB_used.VMBU_size
#define VMB_pos	    	VMB_used.VMBU_pos
#define VMB_nextPtr 	VMB_free.VMBF_nextPtr
#define VMB_prevPtr 	VMB_free.VMBF_prevPtr

/******************************************************************************
 *
 * Macros to convert from a VM Handle ID to a VMBlock * and vice versa, given
 * the header for the file. VM_NULL is the value VM_HANDLE_TO_BLOCK will
 * return when given a null handle ID.
 *
 *****************************************************************************/
#define VM_HANDLE_TO_BLOCK(hid,hdr) \
    (assert(((hid) >= VM_HEADER_ID && (hid) < (hdr)->VMH_lastHandle) || (hid) == 0),\
     ((VMBlock *)((char *)(hdr)+(hid))))

#define VM_BLOCK_TO_HANDLE(block,hdr) \
    ((VMBlockHandle)((char *)(block)-(char *)(hdr)))

#define VM_NULL(file) ((VMBlock *)(file)->blkHdr)
#define VM_LAST(file) ((VMBlock *)((char *)(file)->blkHdr + (file)->blkHdr->VMH_lastHandle))

/******************************************************************************
 *
 *		     Header block for entire file
 *
 * There are two different block chains active in the header:
 *	- free:	the handles themselves are freed (singly-linked)
 *	- assigned: unused by client, but the handles are tracking
 *	  free space in the file. Singly-linked and ordered for easy
 *	  coalescing. This list is doubly-linked when written out.
 * The third category of handles is "used". These aren't on any chain.
 *
 *****************************************************************************/
typedef struct {
    word    	    VMH_signature;	/* Signature for header */
#define VM_HEADER_SIG	0x00fb
    VMBlockHandle   VMH_assigned;	/* Handle for first assigned block */
    VMBlockHandle   VMH_lastAssigned;   /* Handle for last assigned block */
    VMBlockHandle   VMH_unassigned;	/* Head of free handle list */
    VMBlockHandle   VMH_lastHandle;	/* non-inclusive end of range of valid
					 * VMBlockHandle's for the file (i.e.
					 * the size of the header block) */
    short    	    VMH_numAssigned;    /* Length of assigned list */
    short    	    VMH_numUnassigned;  /* Length of unassigned list */
    short	    VMH_numUsed;	/* Number of used handles */

    short    	    VMH_numResident;	/* Number of dirty blocks that need
					 * flushing */
    short    	    VMH_numExtra;	/* Number of extra unassigned
					 * handles still around (unused here --
					 * we don't deal with tony's
					 * TransferToVM kludge) */
    VMBlockHandle   VMH_mapBlock;	/* Handle of map block */
    word    	    VMH_compactThresh;  /* Percentage of file dedicated to
					 * used blocks, below which compaction
					 * is triggered */
    dword   	    VMH_usedSize;	/* Total size of all in-use blocks */
    byte    	    VMH_attributes;	/* Flags indicating mode in which
					 * the file is operating */
    byte    	    VMH_noCompress; 	/* True if compression is disabled */
    word    	    VMH_dbMapBlock;	/* Map block if file contains DB
					 * stuff */
    VMBlock 	    VMH_blockTable[LABEL_IN_STRUCT]; /* Block table itself */
} VMHeader;

#define VMH_BT_OFF  offsetof(VMHeader, VMH_blockTable)
#define VM_HEADER_ID	VMH_BT_OFF

/******************************************************************************
 *
 *	     Deal with byte-swapping from PC byte order.
 *
 *****************************************************************************/
#if defined(mc68000) || defined(sparc)
/*
 * Known architectures on which byte-swapping must be done:
 *	68000, sparc
 */
#define swapword(v)	((word)(((v) << 8) | (((v) >> 8) & 0xff)))
#define swapdword(v)	(((v) << 24) | (((v) & 0xff00) << 8) | \
			 (((v) >> 8) & 0xff00) | ((v) >> 24))
#define SWAP
#else
/*
 * None needed...
 */
#define swapword(v) ((word)(v))
#define swapdword(v) (v)
#endif

/******************************************************************************
 *
 * 	Structure to which a VMHandle actually points (native byteorder)
 *
 *****************************************************************************/
typedef struct {
    FileType   	    fd; 	/* Stream open to file */
    char    	    *name;	/* Name of open file */
    VMHeader	    *blkHdr;    /* Header data for file */
    union {
	VMFileHeader	v1;
	VMFileHeader2	v2;
    } 	    	    fileHdr;	/* Header for file itself */
    VMRelocRoutine  *reloc; 	/* Routine to relocate a block */
    int	    	    flags;  	/* Miscellaneous flags */
#define VM_READ_ONLY	0x00000001  /* Cannot allocate or anything like that */
#define VM_TEMP_FILE	0x00000002  /* File is temporary and should be removed
				     * on close */
#define VM_SHRINK_HDR	0x00000004  /* Header was allocated big when file was
				     * created and should be compressed before
				     * being written out */
#define VM_2_0	    	0x00000008  /* Set if file is a 2.0 VM file */
    int		    fsize;	/* Total size of file */

} VMFileRec, *VMFilePtr;

/******************************************************************************
 *
 *		      Library-internal functions
 *
 *****************************************************************************/
extern dword 	    VMFileAlloc(VMFilePtr file, word size);
extern void 	    VMFileFree(VMFilePtr file, dword pos, word size);
extern VMBlock 	    *VMAllocUnassigned(VMFilePtr file);
extern void 	    VMLinkNewBlocks(VMHeader *hdr, VMBlock *first, int num);
extern MemHandle    VMAllocAndRead(VMFilePtr file, dword pos, word size);
extern int  	    VMWriteBlock(VMFilePtr file, VMBlock *block);

#ifdef SWAP
extern void 	    VMSwapHeader(VMHeader *hdr, word size);
#endif /* SWAP */

#endif /* _VMINT_H_ */
