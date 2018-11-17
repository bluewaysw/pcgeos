COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Serial/IR Communicqation project
MODULE:		loopback driver for socket lib
FILE:		loopbackManager.asm

AUTHOR:		Steve Jang

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/8/94		Initial revision


DESCRIPTION:
	This driver loops back packets to socket library

	$Id: loopbackManager.asm,v 1.1 97/04/18 11:57:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			    Include Files
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include	geode.def
include	resource.def
include	ec.def
include thread.def
include sem.def
include timer.def
include driver.def
include system.def
include medium.def
include assert.def
include Objects/processC.def
include Internal/prodFeatures.def

UseLib	ui.def
ife	NO_PREFERENCES_APPLICATION
UseLib	config.def
endif
UseLib	sac.def
UseLib	Internal/netutils.def
UseLib	Internal/socketInt.def
DefDriver Internal/loopbackDr.def

include Internal/semInt.def
include Internal/log.def
include	Internal/heapInt.def

include	loopbackConstant.def
include	loopbackPrefCtrl.def
include	loopbackAddrCtrl.def
include	loopback.rdef
;------------------------------------------------------------------------------
;			    Code
;------------------------------------------------------------------------------

include loopback.asm
include loopbackUtil.asm
include	loopbackAddrCtrl.asm
include	loopbackPrefCtrl.asm





