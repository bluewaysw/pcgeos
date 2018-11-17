COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseManager.asm

AUTHOR:		John Wedgwood, Jan 16, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/16/91	Initial revision

DESCRIPTION:
	The big include file for the parser library.

	$Id: parseManager.asm,v 1.1 97/04/05 01:27:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include library.def
include lmem.def
include	dbase.def
include heap.def

;------------------------------------------------------------------------------
;  FULL_EXECUTE_IN_PLACE : Indicates that the parse lib is going to
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
include system.def
include	Internal/heapInt.def
include	Internal/xip.def
endif

include resource.def
UseLib	cell.def
UseLib	ui.def
UseLib	math.def
DefLib	parse.def

include	geode.def

include ec.def
include char.def
include timedate.def		; for the NOW function
include	localize.def

include parseMacros.def
include parseConstants.def

; Code Resources

include parseVariables.asm	; Variables and tables.

if	ERROR_CHECK
include parseEC.asm		; Error checking code
else
; add this to non-ec code to keep resources consistant
ECCode segment resource
ECCode ends
endif

include parseStrings.rdef	; Strings used by the parser.
include parseMain.asm		; Library entry.
include parseScanner.asm	; Scanner routines.

	;
	; This next group is all in the ParserCode resource
	;
include parseParse.asm		; Parser routines.
include parseWrite.asm		; Routines to write parser tokens to a buffer

	;
	; This next group is all in the EvalCode resource
	;
include parseEval.asm		; Evaluation routines.
include parseFunctionUtils.asm	; Utility routines for the built-in functions.
include parseFunctListArgs.asm	; Functions that take a list of args
include parseFunctFixedArgs.asm	; Functions that take a fixed (0 or more) # args
include parseFunctSingleArgs.asm ; Functions that take a single arg
include parseFunctStrBoolArgs.asm ; Functions that take strings,or boolean fctns
include parseDateTime.asm	; Implementation of built-in functions.
include parseStack.asm		; Implementation of built-in functions.
include parseOperators.asm	; Implementation of operators.

include parseDepend.asm		; Implementation of dependencies.

include parseFormat.asm		; Formatting routines.
include parseError.asm		; Error message routines.
include	parseC.asm		; C stubs for the library.
