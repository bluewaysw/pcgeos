COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS	
MODULE:		Data Exchange Library
FILE:		dataxManager.asm

AUTHOR:		Robert Greenwalt, Nov  5, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 5/96   	Initial revision


DESCRIPTION:
		
	

	$Id: dataxManager.asm,v 1.1 97/04/04 17:54:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Include Files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include geos.def

;------------------------------------------------------------------------------
;  FULL_EXECUTE_IN_PLACE : Indicates that the table lib is going to
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

include ec.def
include geode.def
include heap.def
include	object.def
include	driver.def
include library.def
include lmem.def
include assert.def
include	sem.def

if FULL_EXECUTE_IN_PLACE
include Internal/xip.def
endif

include resource.def
include system.def
include timer.def
include file.def
include fileEnum.def
include char.def
include localize.def
include initfile.def
include	Internal/semInt.def
include thread.def
include Internal/fileInt.def
include Internal/fileStr.def

UseLib		ui.def

DefLib		datax.def

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	dataxConstants.def


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		 Global Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata	segment

geodeTable		hptr
geodeTableSegment	word
helperOptr		optr
timerFired		byte
lastReturnValue		word
intRefCount		word		; number of clients, currently
infoBlockSegment	word		; temp value, good while doing
					; DXOpenPipe


udata	ends

idata	segment

librarySem	Semaphore <1,0>		; initially NOT locked
openWaitSem	Semaphore <0,0>		; initially locked

idata	ends


DataXClassStructures	segment resource
	DataXApplicationClass
	DataXHelperClass
DataXClassStructures	ends

.wcheck
.rcheck
include dataxPipeAPI.asm
include datax.asm
include dataxAppl.asm
include	dataxUtils.asm
include dataxHelper.asm
include dataxBehaviors.asm
include dataxEC.asm
.norcheck
.nowcheck
