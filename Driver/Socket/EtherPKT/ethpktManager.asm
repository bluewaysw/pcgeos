COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Edward Di Geronimo Jr. 2002.  All rights reserved.

PROJECT:	Native Ethernet Support
MODULE:		Ethernet packet driver
FILE:		ethpktManager.asm

AUTHOR:		Edward Di Geronimo Jr.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	2/24/02		Initial revision


DESCRIPTION:
	This is the ethernet driver for DOS packet drivers.

	$Id:$

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
;include Objects/processC.def
;include Internal/prodFeatures.def
include	Internal/interrup.def

UseLib	ui.def
;UseLib	sac.def
UseLib	Internal/netutils.def
UseLib	socket.def
include	Internal/socketInt.def

;include Internal/semInt.def
;include Internal/log.def
include	Internal/heapInt.def
include	Internal/ip.def
include	timer.def
include	Internal/im.def

UseLib	accpnt.def

;------------------------------------------------------------------------------
;			    Code
;------------------------------------------------------------------------------
		.ioenable
include	../EtherCom/ethercomConstant.def
include	../EtherCom/ethercomMacro.def
include	arp.def
include ethpktConstant.def

include ../EtherCom/ethercomVariable.def
include ethpktVariable.def

include	../EtherCom/ethercomUtil.asm
include	../EtherCom/ethercomStrategy.asm
include	../EtherCom/ethercomGetInfo.asm
include	../EtherCom/ethercomTransceive.asm
include	../EtherCom/ethercomLink.asm
include	../EtherCom/ethercomClient.asm
include	../EtherCom/ethercomOption.asm
include	../EtherCom/ethercomMedium.asm
include ../EtherCom/ethercomProcess.asm

include ethpktInit.asm
include	ethpktTransceive.asm
include	ethpktArp.asm
