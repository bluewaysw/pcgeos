COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefDriveList.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/30/92   	Initial version.

DESCRIPTION:
	

	$Id: prefDriveList.asm,v 1.1 97/04/05 01:37:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDriveListSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefDriveListClass object
		ds:di	= PrefDriveListClass instance data
		es	= Segment of PrefDriveListClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDriveListSpecBuild	method	dynamic	PrefDriveListClass, 
					MSG_SPEC_BUILD

	mov	di, offset PrefDriveListClass
	call	ObjCallSuperNoLock

	; Enumerate the drives

	clr	al				; current drive #
	mov	cx, DRIVE_MAX_DRIVES		; number of drives
startLoop:
	call	DriveGetStatus
	jc	next

	; al - drive number
	call	DoDriveLetterCommon
next:
	inc	al
	loop	startLoop

	;
	; Now do a MSG_META_LOAD_OPTIONS, since the first one arrived
	; before we were spec built, so it didn't do us much good.
	;
	mov	ax, MSG_META_LOAD_OPTIONS
	call	ObjCallInstanceNoLock

	ret
PrefDriveListSpecBuild	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	DoDriveLetterCommon		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a "DriveLetter" object 

CALLED BY:

PASS:		al - drive number
		*ds:si - PrefDriveList object

RETURN:		nothing 

DESTROYED:	bx,dx,di,bp 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 1/92   	Copied from desktop

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoDriveLetterCommon	proc	near

	uses	ax,cx,si

	.enter
	;
	; add appropriate drive icon to format drive list
	;
	clr	ah
	push	ax	 			; drive number

	push	si 				; item group's chunk
						; handle

	segmov	es, <segment DriveLetterClass>, di
	mov	di, offset DriveLetterClass
	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate
	mov	dx, si				; new object
	mov	cx, bx				; handle
	pop	si

	; Now add the child

	mov	bp, CCO_LAST
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLock

	; set child usable

	mov	ax, MSG_GEN_SET_USABLE
	mov	si, dx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

	pop	bp				; drive number
	mov	ax, MSG_DRIVE_LETTER_SET_DRIVE
	call	ObjCallInstanceNoLock 		; preserves bp = drive letter
						; ax = GenItem identifier
	.leave
	ret
DoDriveLetterCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveLetterSetDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set moniker for this drive letter

CALLED BY:	MSG_DRIVE_LETTER_SET_DRIVE

PASS:		usual object stuff

		bp - drive number
		cx - TRUE to set mnemonic
		     FALSE (0) to not set mnemonic

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveLetterSetDrive	method	dynamic DriveLetterClass,
					MSG_DRIVE_LETTER_SET_DRIVE

	mov	ax, bp				; al = drive number
	call	DriveGetDefaultMedia		; ah = media
	mov	ds:[di].GII_identifier, ax	; store drive/media for list
						;  to send out

	segmov	es, ss, di
	sub	sp, size VolumeName
	mov	di, sp

	push	di
   	mov	cx, size VolumeName
	call	DriveGetName

EC <	ERROR_C	DRIVE_LETTER_FATAL_ERROR				>

	mov	{word} es:[di], ':'

	pop	di

	mov	cx, es
	mov	dx, di
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

	add	sp, size VolumeName

	ret
DriveLetterSetDrive	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveLetterGetDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get drive number for this drive letter

CALLED BY:	MSG_DRIVE_LETTER_GET_DRIVE

PASS:		usual object stuff

RETURN:		bp - drive number

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveLetterGetDrive	method	dynamic DriveLetterClass,
					MSG_DRIVE_LETTER_GET_DRIVE
	mov	ax, ds:[di].GII_identifier	; al = drive, ah = media
	clr	ah
	mov	bp, ax				; bp = drive number
	ret
DriveLetterGetDrive	endm
