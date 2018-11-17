COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Cell Library
FILE:		cellManager.asm

AUTHOR:		John Wedgwood, Dec  5, 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/ 5/90	Initial revision

DESCRIPTION:
	

	$Id: cellManager.asm,v 1.1 97/04/04 17:44:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include ec.def
include library.def
include lmem.def
include chunkarr.def
include vm.def
include system.def
include	dbase.def
include heap.def


;------------------------------------------------------------------------------
;  FULL_EXECUTE_IN_PLACE : Indicates that the cell lib is going to
;       be used in a system where all geodes (or most, at any rate)
;       are to be executed out of ROM.  
;------------------------------------------------------------------------------
ifndef FULL_EXECUTE_IN_PLACE
        FULL_EXECUTE_IN_PLACE           equ     FALSE
endif

;------------------------------------------------------------------------------
;  The .GP file only understands defined/not defined;
;  it can not deal with expression evaluation.
;  Thus, for the TRUE/FALSE conditionals, we define
;  GP symbols that _only_ get defined when the
;  condition is true.
;-----------------------------------------------------------------------------
if      FULL_EXECUTE_IN_PLACE
        GP_FULL_EXECUTE_IN_PLACE        equ     TRUE
endif

if FULL_EXECUTE_IN_PLACE
include	Internal/heapInt.def
include	Internal/xip.def
endif
include resource.def

DefLib	cell.def

include	geode.def

include cellConstants.def
include cellMacros.def

; Code resources

if ERROR_CHECK
include cellEC.asm		; Error checking code
endif

include cellMain.asm		; Library entry.
include cellCell.asm		; Cell manipulation.
include cellRow.asm		; Row manipulation.
include cellRange.asm		; Range functions.

include cellUtils.asm		; Utilities for insert/delete and sorting.
include cellInsertDelete.asm	; Insert/delete functions.
include cellSort.asm		; Sorting functions.
include cellFlags.asm		; ColumnFlags functions

include cellC.asm
