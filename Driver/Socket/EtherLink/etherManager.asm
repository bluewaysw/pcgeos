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

	$Id: loopbackManager.asm,v 1.7 95/04/11 16:29:35 adam Exp $

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

include Internal/semInt.def
include Internal/log.def
include	Internal/heapInt.def

include	etherConstant.def
include	etherPrefCtrl.def
include	etherAddrCtrl.def
include	ether.rdef
;------------------------------------------------------------------------------
;			    Code
;------------------------------------------------------------------------------

include ether.asm
include etherUtil.asm
include	etherAddrCtrl.asm
include	etherPrefCtrl.asm





