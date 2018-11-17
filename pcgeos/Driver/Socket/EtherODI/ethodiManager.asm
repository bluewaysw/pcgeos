COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Native Ethernet Support
MODULE:		ODI Ethernet driver
FILE:		ethodiManager.asm

AUTHOR:		Todd Stumpf

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/30/98		Initial revision


DESCRIPTION:
	This is the ethernet driver for the Novell ODI 16-bit
	interface.

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
include ethodiConstant.def

include ../EtherCom/ethercomVariable.def
include ethodiVariable.def

include	../EtherCom/ethercomUtil.asm
include	../EtherCom/ethercomStrategy.asm
include	../EtherCom/ethercomGetInfo.asm
include	../EtherCom/ethercomTransceive.asm
include	../EtherCom/ethercomLink.asm
include	../EtherCom/ethercomClient.asm
include	../EtherCom/ethercomOption.asm
include	../EtherCom/ethercomMedium.asm
include ../EtherCom/ethercomProcess.asm

include ethodiInit.asm
include ethodiProtocol.asm
include	ethodiTransceive.asm
include	ethodiArp.asm
