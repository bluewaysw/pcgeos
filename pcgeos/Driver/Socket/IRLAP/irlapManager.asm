COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		irlapManager.asm

AUTHOR:		Cody Kwok, Mar 24, 1994

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	3/24/94   	Initial revision


DESCRIPTION:
	Manager file for IRLAP driver.
		

	$Id: irlapManager.asm,v 1.1 97/04/18 11:56:56 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;-----------------------------------------------------------------------------
;                            System Includes
;-----------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include system.def
include Internal/interrup.def

include object.def
include timer.def
include timedate.def
include driver.def
include	assert.def
include thread.def
include Internal/semInt.def
include sem.def
include Internal/heapInt.def
include	initfile.def
include medium.def
include	Internal/prodFeatures.def

UseDriver Internal/streamDr.def
UseDriver Internal/serialDr.def

;-----------------------------------------------------------------------------
;                            System Libraries
;-----------------------------------------------------------------------------

UseLib  ui.def
ife	NO_PREFERENCES_APPLICATION
UseLib	config.def
endif
UseLib	Objects/vTextC.def
UseLib	Objects/winC.def
UseLib	Objects/genC.def
UseLib	Objects/inputC.def
UseLib	sac.def
UseLib	Internal/netutils.def

UseLib	socket.def
UseLib	Internal/socketInt.def

; -----------------------------------------------------------------------------
;                          Driver Declaration
; -----------------------------------------------------------------------------

DefDriver	Internal/irlapDr.def

; -----------------------------------------------------------------------------
;                           Internal def files
; -----------------------------------------------------------------------------
include irlap.def
include irlapInt.def
include irlapMacro.def

if _SOCKET_INTERFACE

include	irlapAddressControl.def

endif ;_SOCKET_INTERFACE

; -----------------------------------------------------------------------------
;                             Compiled UI file
; -----------------------------------------------------------------------------

if _SOCKET_INTERFACE

include	irlap.rdef
include	irlapAddressControl.rdef

endif ;_SOCKET_INTERFACE

ife	NO_PREFERENCES_APPLICATION
include	irlapPrefControl.rdef
endif

; -----------------------------------------------------------------------------
;                               Code files
; -----------------------------------------------------------------------------

include irlapEvent.asm
include irlapTables.asm
include irlapInitExit.asm
include irlapDiscovery.asm
include irlapActions.asm
include irlapConnect.asm
include irlapPXfer.asm
include irlapSXfer.asm
include irlapSniff.asm
include	irlapXchg.asm
include irlapUtil.asm
include irlapEC.asm
include irlap.asm

if _SOCKET_INTERFACE

include	irlapSocket.asm

endif ;_SOCKET_INTERFACE

include	irlapStrings.asm
include	irlapControl.asm

if _SOCKET_INTERFACE

include	irlapAddressControl.asm

endif ;_SOCKET_INTERFACE

include	irlapPrefControl.asm
