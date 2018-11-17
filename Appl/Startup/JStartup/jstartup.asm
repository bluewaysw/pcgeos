COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Jedi
MODULE:		startup
FILE:		jstartup.asm

AUTHOR:		Steve Yegge


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	long ago	initial revision

DESCRIPTION:
		

	$Id: jstartup.asm,v 1.1 97/04/04 16:53:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		General stuff
;-----------------------------------------------------------------------------
include geos.def

;------------------------------------------------------------------------------
;  FULL_EXECUTE_IN_PLACE : Indicates that the jstart appl is going to
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

;----------------------------------------------------------------------
; Defining USE_CITY_LIST will include a list of cities on the
; time/date screen with which you can set a local city
;----------------------------------------------------------------------

ifdef	USE_CITY_LIST
	_CITY_LIST			equ	TRUE
else
	_CITY_LIST			equ	FALSE
endif

if _CITY_LIST
	GP_CITY_LIST			equ	TRUE
endif


if FULL_EXECUTE_IN_PLACE
include Internal/xip.def
endif

include	stdapp.def
include initfile.def
include timedate.def
include localize.def
include	system.def
include	assert.def
include	Internal/interrup.def


;-----------------------------------------------------------------------------
;		Mouse-dependent stuff
;-----------------------------------------------------------------------------

include	Objects/winC.def
include Objects/inputC.def
include Internal/mouseDr.def
include Internal/videoDr.def
include timer.def
include	timedate.def

;-----------------------------------------------------------------------------
;		Libraries used
;-----------------------------------------------------------------------------

UseLib	Internal/Jedi/jlib.def
UseLib	Objects/gadgets.def
UseLib	Objects/vTextC.def
if _CITY_LIST
UseLib	Internal/Jedi/jwtime.def
endif

;-----------------------------------------------------------------------------
;		Local include files
;-----------------------------------------------------------------------------

include	jstartup.def
include jstartup.rdef


;-----------------------------------------------------------------------------
;		included code
;-----------------------------------------------------------------------------

JStartUpClassStructures	segment	resource
	JSProcessClass	mask CLASSF_NEVER_SAVED
	JSApplicationClass
	JSPrimaryClass
if _CITY_LIST
	MnemonicInteractionClass
   	JSCityListClass
endif
JStartUpClassStructures	ends

include jsWelcome.asm

Code	segment	resource

include jsProcess.asm
include jsPrimary.asm


Code	ends
