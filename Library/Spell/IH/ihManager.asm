COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spell Library
FILE:		ihManager.asm

AUTHOR:		Ty Johnson, 8/27/92

ROUTINES:
	Name			Description
	----			-----------
	None
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tyj	10/28/92	Initial revision


DESCRIPTION:

	$Id: ihManager.asm,v 1.1 97/04/07 11:08:25 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;			Include Files
;----------------------------------------------------------------------------

include	geos.def
include	heap.def
include	geode.def

;------------------------------------------------------------------------------
;  FULL_EXECUTE_IN_PLACE : Indicates that the spell lib is going to
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
include	Internal/xip.def
endif
include	resource.def
include	ec.def
include lmem.def
include thread.def
include sem.def
include	localize.def
include	Internal/threadIn.def
include initfile.def
include library.def
include file.def

include	object.def

include ihConstants.def
include ihVariables.def

UseLib ui.def
UseLib Objects/vTextC.def		;For HyphenationPoints structure

HyphenCode segment resource 
	global HyphenOpen:far
	global HyphenClose:far
	global Hyphenate:far
HyphenCode ends

;IHCODE	segment	word public 'CODE'
IHCODE	segment	public 'CODE'
ifdef __BORLANDC__
;global	_IHhyp:far
;IHhyp equ _IHhyp
;IHhyp is pascal routine
global IHHYP:far
IHhyp equ IHHYP
else
global	IHhyp:far
endif
IHCODE	ends

;STDLIB	segment	word public 'CODE'
STDLIB	segment	public 'CODE'
ifdef __BORLANDC__
;global	_SLcnv:far
;SLcnv equ _SLcnv
;SLcnv is pascal routine
global SLCNV:far
SLcnv equ SLCNV
else
global	SLcnv:far
endif
STDLIB	ends
global hyphenSem:hptr

;----------------------------------------------------------------------------
;			Code for Thesaurus Process Class
;----------------------------------------------------------------------------

include		ihCalls.asm






