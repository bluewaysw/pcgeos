COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc		
FILE:		miscUtils.asm

AUTHOR:		Ted H. Kim, 7/22/92

ROUTINES:
	Name			Description
	----			-----------
	MakeObjectUsable/MakeObjectNotUsable
				Make the passed object usable/not-usable
	ScanStrForNull		Scan a string for null terminator
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/22/89		Initial revision

DESCRIPTION:
	Contains utility routines for Misc module of GeoDex.

	$Id: miscUtils.asm,v 1.1 97/04/04 15:50:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MenuCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeObjectUsable/MakeObjectNotUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the passed object usable/not-usable

CALLED BY:	UTILITY

PASS:		bx:si - OD of the object to make usable/not-usable

RETURN:		nothing

DESTROYED:	ax, di, dx

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeObjectUsable	proc	far
	mov	ax, MSG_GEN_SET_USABLE	
	mov	di, mask MF_FIXUP_DS		
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE	; dl - do it right now
	call	ObjMessage			; make this object usable
	ret
MakeObjectUsable	endp

MakeObjectNotUsable	proc	far
	mov	ax, MSG_GEN_SET_NOT_USABLE	
	mov	di, mask MF_FIXUP_DS		
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE	; dl - do it right now
	call	ObjMessage			; make this object not usable
	ret
MakeObjectNotUsable	endp


if 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanStrForNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan the string for null terminator.  Returns size with NULL.

CALLED BY:	UTILITY

PASS:		es:di - string to scan

RETURN:		cx - number of bytes in the string (including null)
		es:di - points to the end of string 

DESTROYED:	ax

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The usage of this routine should be reduced.  There are
		now kernel calls to do its job.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanStrForNull	proc	far
	mov	cx, -1			; scan until null terminator
	LocalClrChar	ax		; ax - char to search for
	LocalFindChar			; search for terminating 0

	not	cx			; cx - total number of bytes
DBCS <	shl	cx, 1			; cx - total number of bytes	>
	ret
ScanStrForNull	endp
endif

MenuCode	ends
