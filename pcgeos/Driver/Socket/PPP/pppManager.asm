COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
			
			GEOWORKS CONFIDENTIAL

PROJECT:	Socket
MODULE:		PPP Driver
FILE:		pppManager.asm

AUTHOR:		Jennifer Wu, Apr 19, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	4/19/95		Initial revision

DESCRIPTION:
	Include directives for PPP driver.	

	$Id: pppManager.asm,v 1.9 97/01/20 19:53:40 cthomas Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------------------------------
;			System Includes
;---------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def

include resource.def
include system.def
include object.def
include timer.def
include	timedate.def
include driver.def
include thread.def
include sem.def

include	sysstats.def
include file.def
include localize.def
include initfile.def
include medium.def

include gcnlist.def
include geoworks.def
include Objects/metaC.def

include ec.def
include assert.def

include Internal/im.def
include Objects/processC.def
include Internal/heapInt.def
include Internal/login.def

ifidn	PRODUCT, <RESPONDER>
include Internal/Resp/eci_oem.def
endif	; RESPONDER

ifidn	PRODUCT, <PENELOPE>
include library.def
include Internal/Penelope/pad.def
endif	; PENELOPE

;---------------------------------------------------------------------------
;			System Libraries
;---------------------------------------------------------------------------

UseLib	ui.def
UseLib	Objects/vTextC.def
UseLib	sac.def
UseLib	Internal/netutils.def
UseLib	Internal/socketInt.def
UseLib  accpnt.def

ifidn	PRODUCT, <RESPONDER>
UseLib	foam.def
UseLib 	Internal/Resp/vp.def
include Internal/Resp/vpmisc.def
UseLib	security.def
UseLib	contlog.def
endif	; RESPONDER

;---------------------------------------------------------------------------
;			Driver Declaration
;---------------------------------------------------------------------------

DefDriver Internal/socketDr.def

UseDriver Internal/serialDr.def
UseDriver Internal/modemDr.def 

;---------------------------------------------------------------------------
;			Internal .def files
;---------------------------------------------------------------------------

include ppp.def
include pppAddrCtrl.def
include pppGlobal.def

;---------------------------------------------------------------------------
;			Compiled UI definitions
;---------------------------------------------------------------------------

include pppStrings.rdef				
include pppAddrCtrl.rdef			

;---------------------------------------------------------------------------
;			Code files
;---------------------------------------------------------------------------

include pppMain.asm
include pppUtils.asm 
include pppAddrCtrl.asm
