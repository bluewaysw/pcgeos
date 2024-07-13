COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS (Network Extensions)
MODULE:		TELNET Library
FILE:		telnetManager.asm

AUTHOR:		Simon Auyeung, Jul 19, 1995

	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon		7/19/95   	Initial revision


DESCRIPTION:
	Manager file to collect all source codes
		

	$Id: telnetManager.asm,v 1.1 97/04/07 11:16:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; Define feature sets here
;
; _CLOSE_MEDIUM	= Ensure that whenver telnet connection is closed, the medium
; 		  is also closed. For example, if TCP uses PPP as the link
; 		  driver, the phone line will be cut off when telnet
; 		  connection is actively terminated. 
;

	_CLOSE_MEDIUM	equ	FALSE

;-----------------------------------------------------------------------------
;                          System Includes
;-----------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include library.def
include object.def
include timer.def
EC <	include sem.def							>
include assert.def
include sockmisc.def

include Internal/semInt.def
include Internal/heapInt.def

if	_CLOSE_MEDIUM
include	medium.def
endif	; _CLOSE_MEDIUM
;-----------------------------------------------------------------------------
;                          System Libraries
;-----------------------------------------------------------------------------
UseLib	ui.def
UseLib	socket.def

;-----------------------------------------------------------------------------
;                        Library Declaration
;-----------------------------------------------------------------------------
DefLib  telnet.def

;-----------------------------------------------------------------------------
;                         Internal def files
;-----------------------------------------------------------------------------

include	telnetConstant.def
include	telnetVariable.def
include telnetMacro.def

;-----------------------------------------------------------------------------
;                             Code files
;-----------------------------------------------------------------------------
	
include	telnetEC.asm
include telnetApi.asm
include	telnetConnection.asm
include telnetOption.asm
include telnetCommand.asm
include telnetParser.asm
include telnetUtils.asm
