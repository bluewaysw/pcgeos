COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC/GEOS
MODULE:		Network messaging library
FILE:		socketManager.asm

AUTHOR:		Eric Weber, Mar 14, 1994
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/14/94   	Initial revision


DESCRIPTION:
	Manager file for socket library
		

	$Id: socketManager.asm,v 1.1 97/04/07 10:46:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;-----------------------------------------------------------------------------
;			   System Includes
;-----------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include system.def
include library.def
include driver.def
include sem.def
include object.def
include timer.def
include timedate.def
include assert.def
include initfile.def
include thread.def
include medium.def

include Internal/semInt.def
include Internal/heapInt.def

;-----------------------------------------------------------------------------
;			   System Libraries
;-----------------------------------------------------------------------------
UseLib	ui.def
UseLib	Internal/netutils.def
UseDriver Internal/socketDr.def
;-----------------------------------------------------------------------------
;			 Library Declaration
;-----------------------------------------------------------------------------
DefLib	socket.def
DefLib  Internal/socketInt.def

;-----------------------------------------------------------------------------
;			  Internal def files
;-----------------------------------------------------------------------------
include socketConstant.def
include socketMacro.def

;-----------------------------------------------------------------------------
;			      Code files
;-----------------------------------------------------------------------------
include socketApi.asm
include socketConnection.asm
include socketControl.asm
include socketError.asm
include socketLink.asm
include socketMisc.asm
include socketPacket.asm
include socketStrategy.asm
include socketLoad.asm
include	socketCApi.asm
