COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Network Library
FILE:		net.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

DESCRIPTION:
	This library allows PC/GEOS applications to access the Network
	facilities such as messaging, semaphores, print queues, user account
	info, file info, etc.

RCS STAMP:
	$Id: net.asm,v 1.1 97/04/05 01:25:06 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------
_Library		= 1

;Standard include files

include	geos.def
include geode.def
include ec.def
include geoworks.def
include	library.def
ifdef FULL_EXECUTE_IN_PLACE
include Internal/xip.def
endif
include resource.def
include object.def
include	graphics.def
include gstring.def
include	win.def
include heap.def
include lmem.def
include timer.def
include timedate.def
include	system.def
include	file.def
include	fileEnum.def
include	vm.def
include chunkarr.def
include hugearr.def
include thread.def
include initfile.def
include Internal/geodeStr.def	;for GeodeForEach
include Internal/log.def	;for LogWrite[Init]Entry

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Drivers used
;------------------------------------------------------------------------------
;Include common definitions for all PC/GEOS Network Drivers

UseDriver Internal/netDr.def

;------------------------------------------------------------------------------
;			Library we're defining
;------------------------------------------------------------------------------

DefLib	net.def

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
include netConstant.def
include netVariable.def 

if FULL_EXECUTE_IN_PLACE
global	NetRegisterDomainXIP:far
global	NetUnregisterDomainXIP:far
endif


;------------------------------------------------------------------------------
;		Code Modules
;------------------------------------------------------------------------------

include		init.asm	;specialized method handlers for
				;NetProcessClass, to handle initialization.

include		netUserInfo.asm	;workstation and user information

if NL_TEXT_MESSAGES
  include	alert.asm	;code to display alert messages from
				;the system console.
endif

if NL_SEMAPHORES
  include	semaphore.asm	;network-based semaphore facilities.
endif

if NL_SOCKETS
  include	netSocket.asm	;code to open and close sockets
  include	hecb.asm	;code relating to HugeECB structures
  include	msg.asm		;NetObjMessage-related routines
endif

include		netServer.asm	
include		netC.asm	; C stubs for library		
include 	netPrint.asm	; network printing
include		netMessaging.asm ; messaging
include		netUtils.asm	; common utilities
include		netEnum.asm	; network resource enumeration utilities.
include		netObject.asm
include		netDir.asm	; network directory services.

if ERROR_CHECK
include		netEC.asm	; error-checking code
endif

NetProcStrings	segment	resource
NetProcStrings	ends

;------------------------------------------------------------------------------




