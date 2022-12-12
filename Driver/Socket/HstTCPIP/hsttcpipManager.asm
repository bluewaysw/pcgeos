COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

			GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		TCP/IP Driver	
FILE:		tcpipManager.asm

AUTHOR:		Jennifer Wu, Jul  5, 1994

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/ 5/94		Initial revision

DESCRIPTION:
	Manager file for TCP/IP driver.

	$Id: tcpipManager.asm,v 1.1 97/04/18 11:57:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------------------------------
;				System Includes
;---------------------------------------------------------------------------

include geos.def
include heap.def
include	geode.def

ifdef FULL_EXECUTE_IN_PLACE	
include	Internal/xip.def	; must be included *before* resource.def
endif
include Internal/interrup.def

include resource.def
include ec.def
include system.def

include library.def
include object.def
include timer.def
include timedate.def
include driver.def
include thread.def
include Internal/semInt.def
include sem.def
include Internal/heapInt.def
include Internal/im.def
include Internal/threadIn.def
include Internal/host.def

include file.def
include localize.def
include initfile.def
include chunkarr.def
include assert.def

include Objects/processC.def
include medium.def

;---------------------------------------------------------------------------
;				System Libraries
;---------------------------------------------------------------------------

UseLib	ui.def
UseLib	Objects/vTextC.def
UseLib	socket.def
UseLib	sac.def
UseLib	Internal/netutils.def
UseLib	Internal/socketInt.def
UseLib 	resolver.def

;---------------------------------------------------------------------------
;				Driver Declaration
;---------------------------------------------------------------------------

DefDriver Internal/ip.def	

;---------------------------------------------------------------------------
;				Internal def files
;---------------------------------------------------------------------------

include tcpip.def
include tcpipGlobal.def
include tcpipAddrCtrl.def
include dhcpConstant.def

;---------------------------------------------------------------------------
;				Compiled UI definitions
;---------------------------------------------------------------------------
include tcpipStrings.rdef
include tcpipAddrCtrl.rdef

;---------------------------------------------------------------------------
;				Code files
;---------------------------------------------------------------------------

include tcpipEntry.asm
include tcpipAddrCtrl.asm

