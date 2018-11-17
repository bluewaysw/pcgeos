COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		NetWare Driver
FILE:		netware.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version
	Eric	8/92		Ported to 2.0, of course

DESCRIPTION:
	This library allows PC/GEOS applications to access the Network
	facilities such as messaging, semaphores, print queues, user account
	info, file info, etc.

RCS STAMP:
	$Id: standalone.asm,v 1.1 97/04/18 11:48:50 newdeal Exp $

------------------------------------------------------------------------------@

_NetDriver		= 1	;the mice drivers do this, so we will too. :)

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------
;
; Common include files
;
include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include lmem.def
include system.def
include drive.def
include disk.def
include driver.def
include localize.def
include initfile.def
include thread.def
include timer.def		;for TimerStart, etc.
include Internal/fileInt.def	;for FileInt21

DefDriver Internal/netDr.def

UseLib	net.def

;-----------------------------------------------------------------------------
;	Include .def files		
;-----------------------------------------------------------------------------
 
include standalone.def

;-----------------------------------------------------------------------------
;	Include code		
;-----------------------------------------------------------------------------
 

include standaloneResident.asm
include standaloneUser.asm
