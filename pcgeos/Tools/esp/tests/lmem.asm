COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Esp Test Suite
FILE:		lmem.asm

AUTHOR:		Adam de Boor, Sep  4, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/ 4/89		Initial revision


DESCRIPTION:
	This is a test file designed to test the LMem support in Esp
		

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
;	Types of lmem blocks
;
LMemTypes	etype	word, 0, 1
LMEM_TYPE_WINDOW	enum 	LMemTypes
LMEM_TYPE_OBJ_BLOCK	enum	LMemTypes
LMEM_TYPE_GSTATE	enum	LMemTypes
LMEM_TYPE_FONT_BLK	enum	LMemTypes
LMEM_TYPE_STATE_BLOCK	enum	LMemTypes
LMEM_TYPE_GENERAL	enum	LMemTypes
LMEM_TYPE_ILLEGAL	enum	LMemTypes


;
; Structure at the beginning of every local-memory block.
;

LocalMemoryFlags	record
	LMF_HAS_FLAGS	:1	;True if block is has a flags block
	LMF_IN_RESOURCE	:1	;True if block is just loaded from resource
	LMF_DETACHABLE	:1	;True if block is detachable
	LMF_HAS_STATE	:1	;True if block has an associated state block
	LMF_DUPLICATED	:1	;True if block created by ObjDuplicateBlock
	LMF_IN_RELOCATION:1	;True if block is being relocated (used only
				;in the EC version -- defeats error checking)
	LMF_FREEING_BLOCK:1	;Used by METHOD_FREE_DUPLICATE and
	LMF_READY_TO_FREE:1	;METHOD_REMOVE_BLOCK
			:8
LocalMemoryFlags	end

LMemBlockHeader	struc
    LMBH_handle		hptr		; handle to this block.
    LMBH_offset		word			; offset to handle table.
    LMBH_flags		LocalMemoryFlags
    LMBH_lmemType	LMemTypes		; type of the block.
    LMBH_blockSize	word			; size of the block.
    LMBH_nHandles	word			; # of handles allocated.
    LMBH_freeList	word			; pointer to first free block.
    LMBH_totalFree	word			; sum of sizes of free blocks.
LMemBlockHeader	ends


Interface	segment	lmem LMEM_TYPE_GENERAL

otherdata	word	3 dup(3)

firstChunk	chunk	3 dup(word)
		word	1, 2, 3
firstChunk	endc

ptrToFirstC	lptr	firstChunk

secondChunk	chunk	char
		dc	"So long, mom! I'm off to drop the bomb!"
secondChunk	endc

optrToSecondC	optr	secondChunk

Interface	ends

biff		segment resource
whee		optr	firstChunk
biff		ends
