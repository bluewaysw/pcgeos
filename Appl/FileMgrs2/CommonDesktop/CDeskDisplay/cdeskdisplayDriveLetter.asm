COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		deskdisplayDriveLetter.asm

AUTHOR:		Adam de Boor, Jan 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/30/92		Initial revision


DESCRIPTION:
	Implementation of DriveLetterClass
		

	$Id: cdeskdisplayDriveLetter.asm,v 1.1 97/04/04 15:02:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PseudoResident segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveLetterSetDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set drive letter for this drive letter

CALLED BY:	MSG_DRIVE_LETTER_SET_DRIVE

PASS:		usual object stuff
		bp - drive letter
		cx - TRUE to set mnemonic
		     FALSE (0) to not set mnemonic

RETURN:		ax = GenItem identifier

DESTROYED:	

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
	mov	si, ds:[di].GI_visMoniker
	mov	di, ds:[si]
EC <		; must be a text moniker				>
EC <		CheckHack <DC_TEXT eq 0>				>
EC <	test	ds:[di].VM_type, mask VMT_MONIKER_LIST or \
   				mask VMT_GSTRING			>
EC <	ERROR_NZ	DESKTOP_FATAL_ERROR				>
EC <		; must currently be just a colon			>
EC <	cmp	{word}ds:[di].VM_data.VMT_text[0], ':'			>
EC <	ERROR_NE	DESKTOP_FATAL_ERROR				>

	;
	; If told to set mnemonic, set it to the first letter of the name.
	; XXX: assumes drives are unique in their first letters
	;
	jcxz	mnemonicDone
	mov	ds:[di].VM_data.VMT_mnemonicOffset, 0
mnemonicDone:
	;
	; as we are going to change the moniker manually, clear out the
	; optimized cached width - brianc 3/9/93
	;
	mov	ds:[di].VM_width, 0

	;
	; Figure the number of bytes in the drive's name, excluding the null.
	; 
   	clr	cx
	call	DriveGetName
;EC <	tst	cx							>
;EC <	ERROR_Z	DRIVE_TOOL_BOUND_TO_INVALID_DRIVE			>
   	jcxz	exit			;If the drive is going away, just exit

	dec	cx			; don't need null, as it's already
					;  there
DBCS <	dec	cx							>
	;
	; Insert that many bytes before the colon.
	; 
	mov	bx, offset VM_data.VMT_text
	xchg	ax, si
	call	LMemInsertAt

	;
	; Fetch the name of the drive itself from the kernel. We pass the
	; reduced count in CX so it doesn't overwrite the colon already there...
	;
	xchg	ax, si
	add	bx, ds:[si]
	mov	di, bx
	segmov	es, ds			; es <- VM_data.VMT_text
	call	DriveGetName
exit:
	ret
DriveLetterSetDrive	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveLetterGetDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get drive letter for this drive letter

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

;
; DriveListClass
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveListGetDriveOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find drive's optr

CALLED BY:	MSG_DRIVE_LIST_GET_DRIVE_OPTR

PASS:		*ds:si	= class object
		ds:di	= class instance data
		es 	= segment of class
		ax	= message #

		cl	= drive #

RETURN:		^lcx:dx	= drive optr (or null)

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/15/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveListGetDriveOptr	method	dynamic	DriveListClass,
						MSG_DRIVE_LIST_GET_DRIVE_OPTR

	mov	al, cl			;keep drive # in al
	clr	cx			;start with null OD in ^lcx:dx
	mov	dx, cx	

	push	cx			;start with initial child
	push	cx			

	mov	di, offset GI_link
	push	di			;push offset to LinkPart

	mov	bx, SEGMENT_CS		;push call-back routine
	push	bx
	mov	bx, offset FindChildIdentifier
	push	bx
	mov	bx, offset Gen_offset		; Use the generic linkage
	mov	di, offset GI_comp
	call	ObjCompProcessChildren		; Go process the children
						;(DO NOT use GOTO!)
	ret
DriveListGetDriveOptr	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindChildIdentifier

DESCRIPTION:	Callback routine to find child with given identifier

CALLED BY:	GLOBAL

PASS:
	*ds:si - child
	*es:di - composite
	cx:dx  - should be null coming in 
	al - identifier to search for

RETURN:
	cx:dx - optr if found, still zero if not

DESTROYED:
	bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

FindChildIdentifier	proc	far
	class	GenItemClass
	
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	cmp	al, ds:[bx].GII_identifier.low	; low byte is drive #
	clc
	jne	exit			;skip if does not match...

;found:	;return carry set, indicating that we found the item
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	stc
exit:
	ret
FindChildIdentifier	endp

PseudoResident	ends
