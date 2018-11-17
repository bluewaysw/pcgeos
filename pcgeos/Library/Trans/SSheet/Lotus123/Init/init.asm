
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 10/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial revision

DESCRIPTION:
		
	$Id: init.asm,v 1.1 97/04/07 11:41:55 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	TransLibraryEntry

SYNOPSIS:	Entry/initialization point for translation library

CALLED BY:	GLOBAL
		(Kernel calls upon loading library)

PASS:		di	- LibraryCallType enum
				LCT_ATTACH	- when first loaded
				LCT_NEW_CLIENT	- each time somebody wants us
				LCT_CLIENT_EXIT	- when the one who wants us
						  leaves
				LCT_DETACH	- when we should clean up and
						  die

RETURN:		carry	- clear if init went ok

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

-------------------------------------------------------------------------------@

if 0
TransLibraryEntry proc	far
	uses	bx, es
	.enter
	mov	bx, dgroup
	mov	es, bx
	cmp	di, LCT_ATTACH
	jnz	checkDetach
	mov	bx, 1
	call	ThreadAllocSem
	mov	ax, handle 0
	call	HandleModifyOwner
	mov	es:[threadSem], bx
	jmp	done
checkDetach:
	cmp	di, LCT_DETACH
	jnz	done
	mov	bx, es:[threadSem]
	call	ThreadFreeSem
done:
	.leave
	clc
	ret
TransLibraryEntry endp
endif
