COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		streamCEntry.asm

AUTHOR:		Adam de Boor, Aug 31, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	8/31/95		Initial revision


DESCRIPTION:
	Library entry point for the thing.
		

	$Id: streamCEntry.asm,v 1.1 97/04/07 11:15:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamCStream	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamCEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/31/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	StreamCEntry:far
StreamCEntry	proc	far
		uses	bx, ax, ds
		.enter
		call	SCULoadDGroupDS
		cmp	di, LCT_ATTACH
		je	attach
		cmp	di, LCT_DETACH
		je	detach
done:
		clc
		.leave
		ret

attach:
		mov	bx, 1
		call	ThreadAllocSem
		mov	ax, handle 0
		call	HandleModifyOwner
		mov	ds:[scCallbackSem], bx
		jmp	done

detach:
		mov	bx, ds:[scCallbackSem]
		call	ThreadFreeSem
		jmp	done
StreamCEntry	endp

StreamCStream	ends
