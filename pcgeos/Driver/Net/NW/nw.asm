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
	$Id: nw.asm,v 1.1 97/04/18 11:48:40 newdeal Exp $

------------------------------------------------------------------------------@

_NetDriver		= 1	;the mice drivers do this, so we will too. :)

NETWARE		= TRUE		;this is used in the ../Common directory.

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
include Objects/processC.def	;for ProcessClass

DefDriver Internal/netDr.def
DefDriver Internal/fsDriver.def	;for map drive call


UseDriver	Internal/mfsDr.def	;for DR_MFS_REOPEN_MEGAFILE
UseDriver	Internal/netware.def	;for DR_NETWARE_MAP_DISK

include Internal/heapInt.def	;for SGIT_HANDLE_TABLE_SEGMENT
include	Internal/netware.def

UseLib	net.def

;-----------------------------------------------------------------------------
;	Our own include .def files		
;-----------------------------------------------------------------------------
 
include	nwMacros.def
include nwConstant.def


;------------------------------------------------------------------------------
;		Code Modules
;------------------------------------------------------------------------------

include		nwResident.asm	;resident code, including Strategy routine,
				;and some facilities for calling into NetWare.

include		nwInit.asm	;init code: GetIPXEntryPoint, etc.

include	nwUserInfo.asm	;code for workstation and user info

if NW_TEXT_MESSAGES
  include	nwTextMessage.asm
endif

if NW_SEMAPHORES
   include 	nwSimpleSem.asm

   include	nwSemHigh.asm	;high-level semaphore code
   include	nwSemLow.asm	;low-level semaphore code
   include	nwSem.asm	;NetWare-specific semaphore code
endif

include	nwSocket.asm
; 

if NW_SOCKETS
  include	nwIpx.asm	;routines to access IPX (network-level packet
				;transmission facilities).
  include	nwHecb.asm	;NLHugeECB-related routines
endif


include		nwPrint.asm	; printing
include		nwServer.asm
include		nwBindery.asm	; generic bindery services

include		nwUtils.asm	; misc utilities
include		nwDir.asm	; directory services
