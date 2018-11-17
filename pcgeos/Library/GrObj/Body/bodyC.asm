COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/GrObj/Body
FILE:		bodyC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	5/8/92		Initial version

DESCRIPTION:
	This file contains C interface routines for the GrObjBody

	$Id: bodyC.asm,v 1.1 97/04/04 18:07:54 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Code	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrObjBodyProcessAllGrObjsInDrawOrderCommon

		Send message to all children of body in order of the
		draw list.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		NOTE!  This is a limited version of the assembly
		routine.  This routine deals with sending a message to
		all the children ONLY, while the assembly version can
		deal with callback routines as well.
	
C DECLARATION:	extern void
		_far _pascal GrObjBodyProcessAllGrObjsInDrawOrderCommon(
			optr grobjBody,
			ObjCompCallType callType,
			Message message,
			word cx_param, dx_param, bp_param,
			word *ax_return, *cx_return, *dx_return, *bp_return)
			
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	2/5/92		Initial version
	
------------------------------------------------------------------------------@
GROBJBODYPROCESSALLGROBJSINDRAWORDERCOMMON proc	far grobjBody:optr,
					   callType:word,
					   message:word,
					   cx_param:word,
					   dx_param:word,
					   bp_param:word,
					   ax_return:fptr,
					   cx_return:fptr,
					   dx_return:fptr,
					   bp_return:fptr
	uses	es, ds, di, si
	.enter

	movdw	bxsi, grobjBody
	call	MemDerefDS		; *ds:si <-instance data of graphic body

	clr	bx
	mov	di, callType		; di <- ObjCompCallType
	mov	ax, message		; ax - message to send to children
	mov	cx, cx_param		; cx, dx, bp - parameters to message
	mov	dx, dx_param

	push	bp			; save local variable pointer
	mov	bp, bp_param

	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon
		
	mov	bx, bp
	pop	bp
	push	bx			; save bp's return value

	; Put return values into the right places.
	mov	bx, ax_return.high
	mov	ds, bx
	mov	bx, ax_return.low
	mov	ds:[bx], ax
	
	mov	bx, cx_return.high
	mov	ds, bx
	mov	bx, cx_return.low
	mov	ds:[bx], cx
	
	mov	bx, dx_return.high
	mov	ds, bx
	mov	bx, dx_return.low
	mov	ds:[bx], dx
	
	mov	bx, bp_return.high
	mov	ds, bx
	mov	bx, bp_return.low
	pop	ax			; recover bp's return value
	mov	ds:[bx], ax
	
	.leave
	ret

GROBJBODYPROCESSALLGROBJSINDRAWORDERCOMMON endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrObjBodyProcessSelectedGrObjsCommon

		Send message to all children of body that are in the
		selected list.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		NOTE!  This is a limited version of the assembly
		routine.  This routine only deals with sending a message to
		the children, while the assembly version can
		deal with callback routines as well.

		Unlike ObjCompProcessChildren, you don't get to
		pass nice OCCT flags in di to this routine. you get the
		equivalent of di = OCCT_SAVE_PARAMS_DONT_TEST_ABORT.
	
C DECLARATION:	extern void
		_far _pascal GrObjBodyProcessSelectedGrObjsCommon(
			optr grobjBody,
			Message message,
			word cx_param, dx_param, bp_param,
			word *ax_return, *cx_return, *dx_return, *bp_return)
			
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	5/13/92		Initial version
	
------------------------------------------------------------------------------@
GROBJBODYPROCESSSELECTEDGROBJSCOMMON	proc	far grobjBody:optr,
					message:word,
					cx_param:word,
					dx_param:word,
					bp_param:word,
					ax_return:fptr,
					cx_return:fptr,
					dx_return:fptr,
					bp_return:fptr
	uses	es, ds, di, si
	.enter

	movdw	bxsi, grobjBody
	call	MemDerefDS		; *ds:si <-instance data of graphic body

	clr	bx
	mov	di, OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	mov	ax, message		; ax - message to send to children
	mov	cx, cx_param		; cx, dx, bp - parameters to message
	mov	dx, dx_param

	push	bp			; save local variable pointer
	mov	bp, bp_param

	call	GrObjBodyProcessSelectedGrObjsCommon
		
	mov	bx, bp
	pop	bp
	push	bx			; save bp's return value

	; Put return values into the right places.
	mov	bx, ax_return.high
	mov	ds, bx
	mov	bx, ax_return.low
	mov	ds:[bx], ax
	
	mov	bx, cx_return.high
	mov	ds, bx
	mov	bx, cx_return.low
	mov	ds:[bx], cx
	
	mov	bx, dx_return.high
	mov	ds, bx
	mov	bx, dx_return.low
	mov	ds:[bx], dx
	
	mov	bx, bp_return.high
	mov	ds, bx
	mov	bx, bp_return.low
	pop	ax			; recover bp's return value
	mov	ds:[bx], ax
	
	.leave
	ret
GROBJBODYPROCESSSELECTEDGROBJSCOMMON endp


GROBJBODYPROCESSSELECTEDGROBJSCOMMONPASSFLAG	proc	far grobjBody:optr,
					message:word,
					cx_param:word,
					dx_param:word,
					bp_param:word,
					flag:ObjCompCallType,
					ax_return:fptr,
					cx_return:fptr,
					dx_return:fptr,
					bp_return:fptr
	uses	es, ds, di, si
	.enter

	movdw	bxsi, grobjBody
	call	MemDerefDS		; *ds:si <-instance data of graphic body

	clr	bx
	mov	di, flag
	mov	ax, message		; ax - message to send to children
	mov	cx, cx_param		; cx, dx, bp - parameters to message
	mov	dx, dx_param

	push	bp			; save local variable pointer
	mov	bp, bp_param

	call	GrObjBodyProcessSelectedGrObjsCommon
		
	mov	bx, bp
	pop	bp
	push	bx			; save bp's return value

	; Put return values into the right places.
	mov	bx, ax_return.high
	mov	ds, bx
	mov	bx, ax_return.low
	mov	ds:[bx], ax
	
	mov	bx, cx_return.high
	mov	ds, bx
	mov	bx, cx_return.low
	mov	ds:[bx], cx
	
	mov	bx, dx_return.high
	mov	ds, bx
	mov	bx, dx_return.low
	mov	ds:[bx], dx
	
	mov	bx, bp_return.high
	mov	ds, bx
	mov	bx, bp_return.low
	pop	ax			; recover bp's return value
	mov	ds:[bx], ax
	
	.leave
	ret
GROBJBODYPROCESSSELECTEDGROBJSCOMMONPASSFLAG endp


C_Code	ends

	SetDefaultConvention

