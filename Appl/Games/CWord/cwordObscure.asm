COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Cword
MODULE:		none
FILE:		cwordObscure.asm

AUTHOR:		Jennifer Lew, Jun  3, 1994

ROUTINES:
	Name			Description
	----			-----------
	CwordHandleError
	CwordPopUpDialogBox	Pops a dialog box.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/ 3/94   	Initial revision

DESCRIPTION:
	Very general routines that don't belong to any module
	go in this file.
		
	$Id: cwordObscure.asm,v 1.1 97/04/04 15:13:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CwordBoardBoundsCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordHandleError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle errors by displaying a dialog box telling of
		the error that occurred, then displaying the puzzle selector.

CALLED BY:	GLOBAL
PASS:		di	- offset of chunk containing string to print

RETURN:		CF	- set always to preserve the sense of ERROR

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordHandleError	proc	far
	uses	ax,bx,si,di,bp,es
	.enter

	mov	dx, ERR_N_RESTART
	call	CwordPopUpDialogBox

	; The file selector object should just come on to the screen.

	mov	bx, handle SelectorInteraction	; single-launchable
	mov	si, offset SelectorInteraction
	clr	di
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

	; Tell File Module that error has occurred.

	mov	bx, handle SelectorBox		; single-launchable
	mov	si, offset SelectorBox
	mov	di, mask MF_CALL
	mov	ax, MSG_CFB_NOTIFY_ERROR
	call	ObjMessage

	stc
	.leave
	ret
CwordHandleError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordPopUpDialogBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts up the desired dialog box with the desired string
		in it.

CALLED BY:	global	- Crossword project

PASS:		dx	- CustomDialogBoxFlags
		di	- chunk handle of message string

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordPopUpDialogBox	proc	far
	uses	ax,bx,bp,di,es
	.enter

	mov	bx, handle CwordStrings		; single-launchable
	call	MemLock
	
	mov	es, ax
	mov	di, es:[di]			; Get ptr to text string

	; Allocate parameters buffer
	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags, dx
	mov	ss:[bp].SDP_customString.segment, es
	mov	ss:[bp].SDP_customString.offset, di
	clr	ss:[bp].SDP_helpContext.segment
	call	UserStandardDialog

	; No need to deAllocate parameters because UserStandardDialog
	; does it for us.

	call	MemUnlock

	.leave
	ret
CwordPopUpDialogBox	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordPenInputControlInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The floating keyboard is coming up on screen so switch
		into keyboard mode

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordGenPenInputControlClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordPenInputControlInitiate	method dynamic CwordGenPenInputControlClass, 
						MSG_GEN_INTERACTION_INITIATE
	.enter

	push	ax,si
	mov	bx,handle Board
	mov	si,offset Board
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_CWORD_BOARD_SET_KEYBOARD_MODE
	call	ObjMessage
	pop	ax,si

	mov	di,offset CwordGenPenInputControlClass
	call	ObjCallSuperNoLock

	.leave
	ret
CwordPenInputControlInitiate		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordPenInputControlDismiss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the floating keyboard is leaving the screen so switch
		into pen mode.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordGenPenInputControlClass

		cx - InteractionCommand
RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordPenInputControlDismiss	method dynamic CwordGenPenInputControlClass, 
				MSG_VIS_CLOSE
	.enter

	push	ax,si
	mov	bx,handle Board
	mov	si,offset Board
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_CWORD_BOARD_SET_PEN_MODE
	call	ObjMessage
	pop	ax,si

	mov	di,offset CwordGenPenInputControlClass
	call	ObjCallSuperNoLock

	.leave
	ret
CwordPenInputControlDismiss		endm






CwordBoardBoundsCode	ends



