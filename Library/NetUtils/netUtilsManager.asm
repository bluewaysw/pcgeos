COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Serial/IR Communcation project
MODULE:		Utilities
FILE:		netUtilsManager.asm

AUTHOR:		Steve Jang, Apr 15, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/15/94   	Initial revision


DESCRIPTION:
	Utilities routines for net library and drivers.
		

	$Id: netUtilsManager.asm,v 1.1 97/04/05 01:25:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include stdapp.def
include library.def
include	assert.def

DefLib	sac.def
DefLib	Internal/netutils.def

include	geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include lmem.def
include	Internal/heapInt.def
include	thread.def
include	sem.def
include timer.def

include queue.def
include hugelmem.def

include queue.asm
include queueEC.asm
include hugelmem.asm
include hugelmemEC.asm

include address.asm

include random.asm
include hugelmemC.asm

HugeLMemCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetUtilsEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	entry point for netutils lib

CALLED BY:	GLOBAL (kernel geode code)
PASS:		di	- LibraryCallType
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetUtilsEntry	proc	far
		.enter
		cmp	di, LCT_ATTACH
		jne	done
		call	NetInitRandom
done:
		clc
		.leave
		ret
NetUtilsEntry	endp

HugeLMemCode		ends

ForceRef	NetUtilsEntry	

	
