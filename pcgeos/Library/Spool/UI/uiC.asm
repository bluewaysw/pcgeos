COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UI
FILE:		UIC.asm

AUTHOR:		Allen Schoonmaker, May 14, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	5/14/92		Initial revision


DESCRIPTION:
	This file contains C interface routines for the cell library routines

	$Id: uiC.asm,v 1.1 97/04/07 11:10:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Spool	segment	resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SpoolSetDocSize

C DECLARATION:	extern void *
			_far _pascal SpoolSetDocSize( Boolean open, \
						      PageSizeReport *psr );


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Schoon	5/14/92		Initial version

------------------------------------------------------------------------------@
SPOOLSETDOCSIZE	proc far	open:word, psr:fptr
				uses si, ds	
	.enter	

	mov 	cx, open
	cmp 	cx, FALSE	; is document closed?
	jz	doCall
	lds	si, psr	
doCall:
	call	SpoolSetDocSize

	.leave
	ret
SPOOLSETDOCSIZE	endp


C_Spool ends
	
	SetDefaultConvention





