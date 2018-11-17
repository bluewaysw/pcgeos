COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Preferences/PrefMgr
FILE:		prefmgrUtils.asm

AUTHOR:		Cheng, 1/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial revision

DESCRIPTION:
		
	$Id: prefmgrUtils.asm,v 1.1 97/04/04 16:27:25 newdeal Exp $

------------------------------------------------------------------------------@

if	ERROR_CHECK
CheckDSDgroup	proc	far
	uses	ax
	.enter

	mov	ax, ds
	cmp	ax, dgroup
	ERROR_NZ BAD_DS

	.leave
	ret
CheckDSDgroup	endp

CheckESDgroup	proc	far
	uses	ax
	.enter

	mov	ax, es
	cmp	ax, dgroup
	ERROR_NZ BAD_ES

	.leave
	ret
CheckESDgroup	endp
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	MyGetText

DESCRIPTION:	Get text from a text object into a mem block.

CALLED BY:	INTERNAL ()

PASS:		bx:si - text object

RETURN:		bx - mem handle -- BLOCK MUST BE FREED BY CALLER
		cx - number of characters retrieved (not including null term)

DESTROYED:	ax,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

------------------------------------------------------------------------------@

MyGetText	proc	far
	clr	dx
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	bx, cx			;memory handle => BX
	mov_tr	cx, ax

	; free the block if there is no text in it (backwards compatibility)

	tst	cx
	jnz	done
	call	MemFree
done:
	ret
MyGetText	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	SetText

DESCRIPTION:	Set text for a text object

CALLED BY:	INTERNAL ()

PASS:		bx:si - optr of text object
		dx:bp - fptr to null-term asci

RETURN:		

DESTROYED:	ax,cx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

------------------------------------------------------------------------------@
SetText	proc	far
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx			;specify null termination
	mov	di, mask MF_CALL
	GOTO	ObjMessage
SetText	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	MyInitiateInteraction

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		bx:si - interaction to initiaite

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

------------------------------------------------------------------------------@

MyInitiateInteraction	proc	far
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL
	GOTO	ObjMessage
MyInitiateInteraction	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ConfirmDialog

DESCRIPTION:	

CALLED BY:	INTERNAL (MtdHanMouseApply, MtdHanVideoApply)

PASS:		bx:si - OD of error string
		cx:dx - OD of argument string
		

RETURN:		carry clear if affirmative
		carry set otherwise

DESTROYED:	ax,bx,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version
	CDB	4/22/92		cleaned up.
------------------------------------------------------------------------------@
	
ConfirmDialog	proc	far
		uses	ax
		.enter

		clr	ax
		push	ax, ax		; SDOP_helpContext
		push	ax, ax		; SDOP_customTriggers
		push	ax, ax		; SDOP_stringArg2
		push	cx, dx		; SDOP_stringArg1
		push	bx, si		; SDOP_customString

	
		mov	ax, (CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)

		push	ax		; SDOP_customFlags

	CheckHack <size StandardDialogOptrParams eq 22>

		call	UserStandardDialogOptr

		cmp	ax, IC_YES	; clears carry if equal
		je	done
		stc
done:
		.leave
		ret
ConfirmDialog	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	DoError

DESCRIPTION:	Beeps and puts up error message in a summons.
		Written during transition to a localizable PrefMgr..

CALLED BY:	INTERNAL ()

PASS:		bx:si - resource handle, chunk handle of error string
		cx:dx - 1st string argmunet, if any (CTRL_A in text)
		ax:di - 2st string argmunet, if any (CTRL_B in text)

RETURN:		nothing

DESTROYED:	ax,dx,bp,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version
	Chris	1/ 2/91		Expanded to handle arguments

------------------------------------------------------------------------------@

DoError	proc	far
	push	bx
	push	ax, di
	mov	di, dx
	call	StringLock		;dx:bp <- string
	xchg	dx, di			;di:bp <- string & cx:dx <- arg #1
	pop	bx, si			;bx:si <- arg #2
	mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
		    (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	PrefMgrUserStandardDialog
	pop	bx
	call	MemUnlock
	ret
DoError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrUserStandardDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set up params and call UserStandardDialog

CALLED BY:	GLOBAL

PASS:		ax - CustomDialogBoxFlags
			(can't be GIT_MULTIPLE_RESPONSE)
		di:bp = error string
		cx:dx = arg 1
		bx:si = arg 2

RETURN:		ax = InteractionCommand response

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrUserStandardDialog	proc	far
EC <	push	ax							>
EC <	and	ax, mask CDBF_INTERACTION_TYPE				>
EC <	cmp	ax, GIT_MULTIPLE_RESPONSE shl offset CDBF_INTERACTION_TYPE >
EC <	pop	ax							>
EC <	ERROR_E	CANT_USE_THIS_FOR_GIT_MULTIPLE_RESPONSE			>

	; we must push 0 on the stack for SDP_helpContext

	push	bp, bp			;push dummy optr
	mov	bp, sp			;point at it
	mov	ss:[bp].segment, 0
	mov	bp, ss:[bp].offset

.assert (offset SDP_customTriggers eq offset SDP_stringArg2+4)
	push	ax		; don't care about SDP_customTriggers
	push	ax
.assert (offset SDP_stringArg2 eq offset SDP_stringArg1+4)
	push	bx		; save SDP_stringArg2 (bx:si)
	push	si
.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	push	cx		; save SDP_stringArg1 (cx:dx)
	push	dx
.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	push	di		; save SDP_customString (di:bp)
	push	bp
.assert (offset SDP_customString eq offset SDP_customFlags+2)
.assert (offset SDP_customFlags eq 0)
	push	ax		; save SDP_type, SDP_customFlags
				; params passed on stack
	call	UserStandardDialog
	ret
PrefMgrUserStandardDialog	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	StringLock

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		bx - resource handle
		si - chunk handle

RETURN:		dx:bp - string

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/90		Initial version

------------------------------------------------------------------------------@

StringLock	proc	far
	uses	ax, ds
	.enter

	call	MemLock		;ax,bx <- seg addr of resource
	mov	ds, ax
	xchg	dx, ax                          ;dx = segment of string
        mov	bp, ds:[si]                     ;deref string chunk

	.leave
	ret
StringLock	endp
