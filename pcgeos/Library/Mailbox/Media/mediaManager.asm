COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Transport Medium Tracking
FILE:		mediaManager.asm

AUTHOR:		Adam de Boor, Apr 11, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/11/94		Initial revision


DESCRIPTION:
	Functions and structures for tracking the status of transport media
		
	There are two maps maintained by this module (each map is in its own
	lmem VM block): one follows the existence and connectedness of
	transmission media, while the other tracks which transport drivers
	are capable of using any unit of a particular transport medium.
	
	The existence/connectedness of media is tracked by a single
	chunk array of variable-sized MediaStatusElement structures. Each
	element is for a single medium/unit number pair. Any data passed for
	MMUT_MEM_BLOCK are copied to the end of the MediaStatusElement (at
	MSE_unitData) and the block is freed. Likewise with the 16 bit number
	for MMUT_INT. This map is reinitialized each time the system boots.
	
	The media -> transport map consists of a chunk array and an element
	array. The chunk array holds variable-sized elements of type
	MediaTransportMediaElement. The element array stores the individual
	transport driver tokens uniquely. This structure allows the building
	of a list of all possible transports, based on whether media they
	use have ever been seen by the system. This map is persistent
	across reboots. Note that the map does not involve unit numbers
	in any way.

	$Id: mediaManager.asm,v 1.1 97/04/05 01:20:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	mailboxGeode.def

UseDriver	Internal/mbTrnsDr.def

include	mediaConstant.def

include mediaInit.asm
include	mediaStatus.asm
include mediaTransport.asm
include mediaC.asm
