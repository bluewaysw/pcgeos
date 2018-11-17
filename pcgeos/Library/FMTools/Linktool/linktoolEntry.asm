COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		linktoolEntry.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/21/93   	Initial version.

DESCRIPTION:
	

	$Id: linktoolEntry.asm,v 1.1 97/04/04 18:01:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinktoolEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke the duplicated UI, if any

CALLED BY:	EXTERNAL

PASS:		di - LibraryCallType

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/21/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global LinktoolEntry:far

LinktoolEntry	proc far
		
		cmp	di, LCT_DETACH
		jne	done
		
		segmov	es, dgroup, ax
		movdw	bxsi, es:[linktoolUI]
		tst	bx
		jz	done
		
		call	UserDestroyDialog
		
done:
		clc
		ret
LinktoolEntry	endp

