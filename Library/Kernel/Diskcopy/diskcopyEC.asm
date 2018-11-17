COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Diskcopy
FILE:		diskcopyEC.asm

AUTHOR:		Cheng, 10/89

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial revision

DESCRIPTION:
		
	$Id: diskcopyEC.asm,v 1.1 97/04/05 01:18:15 newdeal Exp $

-------------------------------------------------------------------------------@

DiskcopyModule segment resource

IF	ERROR_CHECK	; entire file contains error checking code *************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DCCheckESDGroup

DESCRIPTION:	Check to see that ES = kdata seg

CALLED BY:	INTERNAL (error checking code)

PASS:		es

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

-------------------------------------------------------------------------------@

DCCheckESDGroup	proc	near
	push	ax, bx
	mov	ax, dgroup
	mov	bx, es
	cmp	ax, bx
	ERROR_NZ	DISKCOPY_BAD_ES
	pop	ax, bx
	ret
DCCheckESDGroup	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DCCheckValidDrive

DESCRIPTION:	Checks to see that the drive number is valid

CALLED BY:	INTERNAL (error checking code)

PASS:		dl - 0 based drive number

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

-------------------------------------------------------------------------------@

DCCheckValidDrive	proc	near
	push	ax
	mov	al, dl
	call	DriveGetStatusFar
	ERROR_C	DISKCOPY_INVALID_DRIVE
	test	ah, mask DS_MEDIA_REMOVABLE
	ERROR_Z	DISKCOPY_INVALID_DRIVE
	pop	ax
	ret
DCCheckValidDrive	endp

ENDIF			;*******************************************************

DiskcopyModule ends
