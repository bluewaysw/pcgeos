COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/Text
FILE:		textUtils.asm

ROUTINES:

	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/91		Initial version

DESCRIPTION:

This file contains several utility routines.

	$Id: textUtils.asm,v 1.1 97/04/07 11:17:59 newdeal Exp $

------------------------------------------------------------------------------@

TextFixed segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	T_GetVMFile

DESCRIPTION:	Get the object's VM file

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object

RETURN:	bx - VM file

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/21/92		Initial version

------------------------------------------------------------------------------@
T_GetVMFile	proc	far
	class	VisTextClass

EC <	call	T_AssertIsVisText					>
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	bx, ds:[bx].VTI_vmFile
	tst	bx
	jnz	done

	push	ax
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo
	mov_tr	bx, ax
	pop	ax
done:
	ret

T_GetVMFile	endp

TextFixed	ends

Text segment resource
 
COMMENT @----------------------------------------------------------------------

FUNCTION:	T_GetSelectionFrame

DESCRIPTION:	Get the current selection into a stack frame

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ss:bp - VisTextRange to fill

RETURN:
	range - set

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/26/91		Initial version

------------------------------------------------------------------------------@
T_FarGetSelectionFrame	proc	far
	call	T_GetSelectionFrame
	ret
T_FarGetSelectionFrame	endp

T_GetSelectionFrame	proc	near	uses ax, bx, cx, dx
	class	VisTextClass
	.enter

EC <	call	T_AssertIsVisText					>

	call	TSL_SelectGetSelection		; dx.ax <- selection start
						; cx.bx <- selection end
	movdw	ss:[bp].VTR_start, dxax
	movdw	ss:[bp].VTR_end, cxbx

	.leave
	ret

T_GetSelectionFrame	endp
 
COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToTextOutput

DESCRIPTION:	Send a method to VTI_output.  Sent via the queue

CALLED BY:	INTERNAL

PASS:
	ax - method to send
	bp - data
	*ds:si - object

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version
	Chris	3/17/93		Added "IfNotSelf" versions.

------------------------------------------------------------------------------@
FarSendToTextOutputIfNotSelf	proc	far	uses	cx, dx
	.enter
EC <	call	ECCheckObject						>

	mov	cx, ds:[LMBH_handle]		;send OD in cx:dx
	mov	dx, si

	call	SendToTextOutputLowIfNotSelf
	.leave
	ret
FarSendToTextOutputIfNotSelf	endp



FarSendToTextOutput	proc	far
	call	SendToTextOutput
	ret
FarSendToTextOutput	endp




SendToTextOutput	proc	near		uses cx, dx
	class	VisTextClass
	.enter

EC <	call	ECCheckObject						>

	mov	cx, ds:[LMBH_handle]		;send OD in cx:dx
	mov	dx, si

	call	SendToTextOutputLow

	.leave
	ret

SendToTextOutput	endp

;---

SendToTextOutputLowIfNotSelf	proc	far
	class	VisTextClass
EC <	call	ECCheckObject						>

	push	cx
	mov	cx, ds:[LMBH_handle]
	cmp	cx, ds:[di].VTI_output.handle
	pop	cx
	jne	SendToTextOutputLow
	cmp	si, ds:[di].VTI_output.chunk
	jne	SendToTextOutputLow
	ret
SendToTextOutputLowIfNotSelf	endp

;---

SendToTextOutputLow	proc	far		uses bx, si, di
	class	VisTextClass
	.enter

EC <	call	ECCheckObject						>

	tstdw	ds:[di].VTI_output
	jz	done

	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	call	Text_DerefVis_DI
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jnz	generic

	; its a vis object, send the output ourself

	movdw	bxsi, ds:[di].VTI_output
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jmp	common

	; its a Gen object, use GenProcessAction

generic:
	pushdw	ds:[di].VTI_output
	mov	di, mask MF_FIXUP_DS
	call	GenProcessAction

common:

	pop	di
	call	ThreadReturnStackSpace

done:
	.leave
	ret

SendToTextOutputLow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	...

DESCRIPTION:	Bytes savers

------------------------------------------------------------------------------@
TextInstance	segment	resource

TextInstance_DerefVis_DI	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
TextInstance_DerefVis_DI	endp

TextInstance	ends

Text_DerefVis_DI	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
Text_DerefVis_DI	endp

Text_GState_DI	proc	near
	class	VisTextClass
	call	Text_DerefVis_DI
	mov	di, ds:[di].VTI_gstate
	ret
Text_GState_DI	endp

Text_DerefVis_SI	proc	near
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	ret
Text_DerefVis_SI	endp

;---

	; WARNING: The order that registers are pushed here must match the
	; structure PushAllFrame in tConstant.def

Text_PushAll	proc	near
	push	bp, es, di, si, dx, cx, bx, ax
	mov	bp, sp
	push	ss:[bp].PAF_ret		; push passed return address for return.
	mov	bp, ss:[bp].PAF_bp	; recover passed bp
	ret
Text_PushAll	endp

;-----

Text_PopAll_retf	proc	far
	call	Text_PopAll
	ret
Text_PopAll_retf	endp

Text_PopAll	proc	near
	mov	bp, sp
	pop	ss:[bp+2].PAF_ret	; pop return address into slot saved
					;  for it...
	pop	bp, es, di, si, dx, cx, bx, ax
	ret
Text_PopAll	endp

;-----

Text_ObjCallInstanceNoLock	proc	far
	call	ObjCallInstanceNoLock
	ret
Text_ObjCallInstanceNoLock	endp

Text_ObjCallInstanceNoLock_save_cxdxbp	proc	far	uses cx, dx, bp
	.enter
	call	Text_ObjCallInstanceNoLock
	.leave
	ret
Text_ObjCallInstanceNoLock_save_cxdxbp	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	T_AssertIsVisText

DESCRIPTION:	...

CALLED BY:	INTERNAL

PASS:

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/91		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK

T_AssertIsVisText	proc	far	uses di, es
	.enter
	pushf

	call	VisCheckVisAssumption
	mov	di, segment VisTextClass
	mov	es, di
	mov	di, offset VisTextClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_IS_NOT_A_VIS_TEXT

	popf
	.leave
	ret

T_AssertIsVisText	endp

;---

T_AssertIsVisLargeText	proc	far	uses di, es
	class	VisLargeTextClass
	.enter
	pushf

	call	VisCheckVisAssumption
	mov	di, segment VisLargeTextClass
	mov	es, di
	mov	di, offset VisLargeTextClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_IS_NOT_A_VIS_TEXT

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	ERROR_Z	VIS_TEXT_REQUIRES_LARGE_TEXT_OBJECT

	popf
	.leave
	ret

T_AssertIsVisLargeText	endp

endif

Text ends
