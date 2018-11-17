COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentUtils.asm

ROUTINES:
	Name				Description
	----				-----------
    INT CreateGrObj		Create a grobj object

    INT DP_ObjMessageNoFlags	Create a grobj object

    INT DP_ObjMessageFixupDS	Create a grobj object

    INT MoveGrObj		Move a grobj object

    INT DuplicateAndAttachData	Duplicate a block and attach it to the VM
				file (one routine for data blocks, the
				other for object blocks)

    INT AttachCommon		Duplicate a block and attach it to the VM
				file (one routine for data blocks, the
				other for object blocks)

    INT DuplicateAndAttachObj	Duplicate a block and attach it to the VM
				file (one routine for data blocks, the
				other for object blocks)

    INT DisplayError		Display an error dialog box

    INT ConfirmIfNeeded		Put up a confirmation dialog if needed

    INT ComplexQuery		Put up a confirmation dialog if needed

    INT MarkBusy		Mark the application as busy

    INT BusyCommon		Mark the application as busy

    INT MarkNotBusy		Mark the application as busy

    INT IgnoreUndoAndFlush	Start ignoring undo actions

    INT IgnoreUndoNoFlush	Start ignoring undo actions

    INT UndoCommon		Start ignoring undo actions

    INT AcceptUndo		Start ignoring undo actions

    INT GetAppFeatures		Get the features bits

    INT GetFileHandle		Get the file handle from the instance data

    INT LockMapBlockDS		Lock the map block to DS

    INT LockMapBlockES		Lock the map block to ES

    INT VMUnlockDS		...

    INT VMUnlockES		...

    INT VMDirtyDS		...

    INT VMDirtyES		...

    INT StudioGetDGroupDS	...

    INT StudioGetDGroupES	...

    INT MemBlockToVMBlockCX	Get the VM block handle for a memory block
				given that DS points to an lmem block in
				the file

    INT VMBlockToMemBlockRefDS	Get the memory handle for a VM block given
				that DS points to an lmem block in the file

    INT StudioVMBlockToMemBlock	Get the memory handle for a VM block in our
				document file

    INT SectionArrayEToP_ES	Dereference element in the section array

    INT DC_ObjMessageNoFlags	Dereference element in the section array

    INT DC_ObjMessage		Dereference element in the section array

    INT DS_ObjMessageNoFlags	Dereference element in the section array

    INT AssertIsStudioDocument	Assert the *ds:si is a StudioDocumentClass
				object

METHODS:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the document open/close related code for
	StudioDocumentClass

	$Id: documentUtils.asm,v 1.1 97/04/04 14:39:16 newdeal Exp $

------------------------------------------------------------------------------@

DocPageCreDest segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateGrObj

DESCRIPTION:	Create a grobj object

CALLED BY:	INTERNAL

PASS:
	ax - left
	bx - top
	cx - width
	dx - height
	pushed on stack:
		word - y position high word
		optr - body
		dword - class
		word - graphic style
		word - text style
		word - GrObjLocks for the object

RETURN:
	cx:dx - object created
	NOTE: DS *not* fixed-up

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
CreateGrObj	proc	far	yPosHigh:word, bodyobj:optr, oclass:fptr,
				graphicStyle:word, textStyle:word,
				locks:GrObjLocks
						uses ax, bx, si
createData	local	GrObjInitializeData
lineAttr	local	word
areaAttr	local	word
charAttr	local	word
paraAttr	local	word
	.enter

	; set up stack frame for MSG_GO_INITIALIZE

	mov	createData.GOID_position.PDF_x.DWF_int.high, 0
	mov	createData.GOID_position.PDF_x.DWF_int.low, ax
	mov	createData.GOID_position.PDF_x.DWF_frac, 0
	mov	ax, yPosHigh
	mov	createData.GOID_position.PDF_y.DWF_int.high, ax
	mov	createData.GOID_position.PDF_y.DWF_int.low, bx
	mov	createData.GOID_position.PDF_y.DWF_frac, 0
	mov	createData.GOID_width.WWF_int, cx
	mov	createData.GOID_width.WWF_frac, 0
	mov	createData.GOID_height.WWF_int, dx
	mov	createData.GOID_height.WWF_frac, 0

	; get the attributes for the style

	mov	cx, graphicStyle
	mov	ax, MSG_STUDIO_DOCUMENT_GET_GRAPHIC_TOKENS_FOR_STYLE
	call	queryUpwardToDoc
	mov	lineAttr, cx
	mov	areaAttr, dx

	mov	cx, textStyle
	cmp	cx, CA_NULL_ELEMENT
	jz	afterTextStyle
	mov	ax, MSG_STUDIO_DOCUMENT_GET_TEXT_TOKENS_FOR_STYLE
	call	queryUpwardToDoc
	mov	charAttr, cx
	mov	paraAttr, dx
afterTextStyle:

	; instantiate the object in a block managed by body

	movdw	bxsi, bodyobj
	movdw	cxdx,oclass,ax
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	push	di
	mov	di, mask MF_CALL
	call	ObjMessage			;cx:dx = new object
	pop	di

	; initialize new objects instance data

	movdw	bxsi, cxdx			;new object OD
	push	bp
	lea	bp, createData
	mov	ax, MSG_GO_INITIALIZE
	call	DP_ObjMessageNoFlags
	pop	bp

	; set attributes for new object

	mov	ax, MSG_GO_SET_GROBJ_LINE_TOKEN
	mov	cx, lineAttr
	call	DP_ObjMessageNoFlags
	mov	ax, MSG_GO_SET_GROBJ_AREA_TOKEN
	mov	cx, areaAttr
	call	DP_ObjMessageNoFlags

	cmp	textStyle, CA_NULL_ELEMENT
	jz	afterAttr

	push	bp
	sub	sp, size VisTextSetCharAttrByTokenParams
	mov	ax, sp
	push	paraAttr
	push	charAttr
	mov_tr	bp, ax
	clrdw	ss:[bp].VTSCABTP_range.VTR_start
	movdw	ss:[bp].VTSCABTP_range.VTR_end, TEXT_ADDRESS_PAST_END
	pop	ss:[bp].VTSCABTP_charAttr
	mov	ax, MSG_VIS_TEXT_SET_CHAR_ATTR_BY_TOKEN
	mov	dx, size VisTextSetCharAttrByTokenParams
	call	sendClassedStackEventToText
	pop	ss:[bp].VTSPABTP_paraAttr
	clrdw	ss:[bp].VTSPABTP_range.VTR_start
	movdw	ss:[bp].VTSPABTP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ax, MSG_VIS_TEXT_SET_PARA_ATTR_BY_TOKEN
	call	sendClassedStackEventToText
	add	sp, size VisTextSetCharAttrByTokenParams
	pop	bp

	; more special stuff for text objects

	mov	cl, mask TGF_ENFORCE_DESIRED_MIN_HEIGHT or \
		    mask TGF_ENFORCE_DESIRED_MAX_HEIGHT
	mov	dl, not mask TextGuardianFlags
	mov	ax, MSG_TG_SET_TEXT_GUARDIAN_FLAGS
	call	DP_ObjMessageFixupDS
	mov	ax, MSG_TG_CALC_DESIRED_MIN_HEIGHT
	call	DP_ObjMessageFixupDS
	mov	ax, MSG_TG_CALC_DESIRED_MAX_HEIGHT
	call	DP_ObjMessageFixupDS
afterAttr:

	mov	ax, MSG_GO_CHANGE_LOCKS
	mov	cx, locks
	clr	dx
	call	DP_ObjMessageNoFlags

	mov	ax, MSG_GO_NOTIFY_GROBJ_VALID
	call	DP_ObjMessageNoFlags

	; add the new object to the body

	push	bp
	movdw	cxdx, bxsi
	movdw	bxsi, bodyobj
	mov	ax, MSG_GB_ADD_GROBJ
	mov	bp, GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION ;add at end
	call	DP_ObjMessageNoFlags
	pop	bp

	.leave
	ret	@ArgSize

;---

sendClassedStackEventToText:
	push	dx, di
	mov	di, mask MF_STACK or mask MF_RECORD
	pushdw	bxsi
	mov	bx, segment VisTextClass
	mov	si, offset VisTextClass
	call	ObjMessage
	popdw	bxsi
	mov	cx, di
	mov	dx, TO_SELF
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	DP_ObjMessageNoFlags
	pop	dx, di
	retn

;---

	; ax = message, cx, dx = data

queryUpwardToDoc:
	push	bp
	mov	di, mask MF_RECORD
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	call	ObjMessage			;di = message
	mov	cx, di
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	movdw	bxsi, bodyobj
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp
	retn

CreateGrObj	endp

;---


DP_ObjMessageNoFlags	proc	near
	push	di
	clr	di
	call	ObjMessage
	pop	di
	ret
DP_ObjMessageNoFlags	endp

;---

DP_ObjMessageFixupDS	proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DP_ObjMessageFixupDS	endp

DocPageCreDest ends

DocPageSetup segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	MoveGrObj

DESCRIPTION:	Move a grobj object

CALLED BY:	INTERNAL

PASS:
	ax - left
	bx - top
	cx - width
	dx - height
	pushed on stack:
		optr - object
		word - y position high word

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
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
MoveGrObj	proc	far	grobjobj:optr, yPosHigh:word
					uses ax, bx, cx, dx, si, di
positionData	local	PointDWFixed
sizeData	local	PointWWFixed
	.enter

	mov	positionData.PDF_x.DWF_int.high, 0
	mov	positionData.PDF_x.DWF_int.low, ax
	mov	positionData.PDF_x.DWF_frac, 0
	mov	ax, yPosHigh
	mov	positionData.PDF_y.DWF_int.high, ax
	mov	positionData.PDF_y.DWF_int.low, bx
	mov	positionData.PDF_y.DWF_frac, 0

	mov	sizeData.PF_x.WWF_int, cx
	mov	sizeData.PF_x.WWF_frac, 0
	mov	sizeData.PF_y.WWF_int, dx
	mov	sizeData.PF_y.WWF_frac, 0

	movdw	bxsi, grobjobj
	push	bp
	lea	bp, positionData
	mov	ax, MSG_GO_SET_POSITION
	call	DPS_ObjMessageNoFlags
	pop	bp
	push	bp
	lea	bp, sizeData
	mov	ax, MSG_GO_SET_SIZE
	call	DPS_ObjMessageNoFlags
	pop	bp

	.leave
	ret	@ArgSize

MoveGrObj	endp

DocPageSetup	ends

DocCreate segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	DuplicateAndAttachData, DuplicateAndAttachObj

DESCRIPTION:	Duplicate a block and attach it to the VM file (one routine
		for data blocks, the other for object blocks)

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	bx - handle of block to duplicate

RETURN:
	ax - VM block handle of duplicated block
	bx - memory handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 9/92		Initial version

------------------------------------------------------------------------------@
DuplicateAndAttachData	proc	far
EC <	call	AssertIsStudioDocument					>

	call	GeodeDuplicateResource
	call	AttachCommon
	ret

DuplicateAndAttachData	endp

;---

AttachCommon	proc	near
	push	cx
	mov	cx, bx				;cx = new mem handle
	call	GetFileHandle			;bx = VM file handle
	clr	ax
	call	VMAttach			;ax = VM block
	mov	bx, cx				;bx = memory handle
	pop	cx
	ret
AttachCommon	endp

;---

DuplicateAndAttachObj	proc	far
EC <	call	AssertIsStudioDocument					>

	clr	ax				; have current geode own block
	mov	cx, -1				; copy running thread from
						;	template block
	call	ObjDuplicateResource
	call	AttachCommon
	push	bx
	call	GetFileHandle
	call	VMPreserveBlocksHandle
	pop	bx

	ret

DuplicateAndAttachObj	endp

DocCreate ends

DocSTUFF segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoStandardDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invoke UserStandardDialog 

CALLED BY:	INTERNAL
PASS:		ax - custom flags
		si - offset of string
		es:di - string arg 1 text
RETURN:		ax - InteractionCommand
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoStandardDialog		proc	far
		uses	ds, si, di, bp
		.enter

		sub	sp, (size StandardDialogParams)
		mov	bp, sp				;ss:bp <- params

		mov	ss:[bp].SDP_customFlags, ax
		mov	ss:[bp].SDP_stringArg1.segment, es
		mov	ss:[bp].SDP_stringArg1.offset, di

		mov	bx, handle StringsUI
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]			
		mov	ss:[bp].SDP_customString.segment, ds
		mov	ss:[bp].SDP_customString.offset, si

		clr	ax
		mov	ss:[bp].SDP_helpContext.segment, ax
		mov	ss:[bp].SDP_customTriggers.segment, ax
		mov	ss:[bp].SDP_stringArg2.segment, ax

		call	UserStandardDialog
		call	MemUnlock

		.leave
		ret
DoStandardDialog		endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DisplayError

DESCRIPTION:	Display an error dialog box

CALLED BY:	INTERNAL

PASS:
	ax - chunk of string (in StringsUI)

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
	Tony	6/19/92		Initial version

------------------------------------------------------------------------------@
DisplayError	proc	far	uses bx
	.enter

	clr	bx
	push	bx, bx			;helpContext
	push	bx, bx			;customTriggers
	push	bx, bx			;stringArg2
	push	bx, bx			;stringArg1
	mov	bx, handle StringsUI
	pushdw	bxax			;custom string
	mov	bx, CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION,0>
	push	bx			;flags
	call	UserStandardDialogOptr		; pass params on stack

	.leave
	ret

DisplayError	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DisplayQuestion

DESCRIPTION:	Display a question dialog box

CALLED BY:	INTERNAL

PASS:		si	- offset to string resource (question)
RETURN:		ax	- IC_YES or IC_NO
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/19/92		Initial version

------------------------------------------------------------------------------@
DisplayQuestion		proc	far	uses bx
	.enter

	clr	bx
	push	bx, bx			;helpContext
	push	bx, bx			;customTriggers
	push	bx, bx			;stringArg2
	push	bx, bx			;stringArg1
	mov	bx, handle StringsUI
	pushdw	bxsi			;custom string
	mov	bx, CustomDialogBoxFlags <0, CDT_QUESTION, GIT_AFFIRMATION, 0>

	push	bx			;flags
	call	UserStandardDialogOptr		; pass params on stack

	.leave
	ret

DisplayQuestion	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConfirmIfNeeded

DESCRIPTION:	Put up a confirmation dialog if needed

CALLED BY:	INTERNAL

PASS:
	ax - offset of string (in StringsUI)

RETURN:
	ax - InteractionCommand (IC_YES or other)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
ConfirmIfNeeded	proc	far	uses cx, dx, ds
	.enter

	call	StudioGetDGroupDS
	test	ds:[miscSettings], mask SMS_CONFIRM
	jnz	confirm
	mov	ax, IC_YES
	jmp	done

confirm:
	clr	cx
	mov	dx,
		 CustomDialogBoxFlags <0, CDT_NOTIFICATION, GIT_AFFIRMATION,0>
	call	ComplexQuery
done:
	.leave
	ret

ConfirmIfNeeded	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ComplexQuery

DESCRIPTION:	Put up a confirmation dialog if needed

CALLED BY:	INTERNAL

PASS:
	ax - offset of string (in StringsUI)
	cx - offset of response trigger table
	dx - flags

RETURN:
	ax - InteractionCommand (IC_YES or other)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
ComplexQuery	proc	far	uses bx
	.enter

	clr	bx
	push	bx, bx			;helpContext

	jcxz	noCustomTriggers
	pushdw	cscx
	jmp	common
noCustomTriggers:
	push	bx, bx			;customTriggers
common:
	push	bx, bx			;stringArg2
	push	bx, bx			;stringArg1
	mov	bx, handle StringsUI
	pushdw	bxax			;custom string
	push	dx			;flags
	call	UserStandardDialogOptr		; pass params on stack

	.leave
	ret

ComplexQuery	endp

;---

BookFileNotFoundQuery	proc	far
		push	cx, dx
		mov	cx, offset BookFileNotFoundTable
		mov	ax, offset BookFileNotFoundString
		mov	dx, CustomDialogBoxFlags \
			<0, CDT_QUESTION, GIT_MULTIPLE_RESPONSE,0>
		call	ComplexQuery
		pop	cx, dx
		ret
BookFileNotFoundQuery	endp

;---

EditWhichMasterPageTable	label	byte
	word	3
	StandardDialogResponseTriggerEntry	\
		<EditLeftMasterPageMoniker, IC_YES>,
		<EditRightMasterPageMoniker, IC_NO>,
		<CancelMoniker, IC_DISMISS>

BookFileNotFoundTable	label	byte
	word	2
	StandardDialogResponseTriggerEntry	\
		<NewBookMoniker, IC_YES>,
		<ResetBookMoniker, IC_DISMISS>

EditHeaderTitlePageTable	label	byte
	word	3
	StandardDialogResponseTriggerEntry	\
		<TitlePageMoniker, IC_YES>,
		<MainSectionMoniker, IC_NO>,
		<CancelMoniker, IC_DISMISS>

COMMENT @----------------------------------------------------------------------

FUNCTION:	MarkBusy

DESCRIPTION:	Mark the application as busy

CALLED BY:	INTERNAL

PASS:
	none

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
	Tony	12/28/92		Initial version

------------------------------------------------------------------------------@
MarkBusy	proc	far
	push	ax
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	FALL_THRU	BusyCommon, ax
MarkBusy	endp

;---

BusyCommon	proc	far

	push	cx, dx, bp
	call	UserCallApplication
	pop	cx, dx, bp

	FALL_THRU_POP	ax
	ret

BusyCommon	endp

;---

MarkNotBusy	proc	far
	push	ax
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	GOTO	BusyCommon, ax
MarkNotBusy	endp

DocSTUFF ends

DocCommon segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	IgnoreUndo

DESCRIPTION:	Start ignoring undo actions

CALLED BY:	INTERNAL

PASS:
	none

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
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
IgnoreUndoAndFlush	proc	far	uses ax, cx
	.enter
	mov	ax, MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS
	mov	cx, 1					;flush actions
	call	UndoCommon
	.leave
	ret
IgnoreUndoAndFlush	endp

IgnoreUndoNoFlush	proc	far	uses ax, cx
	.enter
	mov	ax, MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS
	clr	cx					;don't flush actions
	call	UndoCommon
	.leave
	ret
IgnoreUndoNoFlush	endp

UndoCommon	proc	near	uses bx
	.enter
	clr	bx
	call	GeodeGetProcessHandle
	call	DC_ObjMessageNoFlags
	.leave
	ret
UndoCommon	endp

;---

AcceptUndo	proc	far	uses ax
	.enter
	pushf
	mov	ax, MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS
	call	UndoCommon
	popf
	.leave
	ret
AcceptUndo	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetAppFeatures

DESCRIPTION:	Get the features bits

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	ax - StudioFeatures

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/26/92		Initial version

------------------------------------------------------------------------------@
GetAppFeatures	proc	far	uses cx, dx, bp
	.enter

	mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
	call	GenCallApplication		;ax = features

	.leave
	ret

GetAppFeatures	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetFileHandle

DESCRIPTION:	Get the file handle from the instance data

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

RETURN:
	bx - file handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 9/92		Initial version

------------------------------------------------------------------------------@
GetFileHandle	proc	far
	class	StudioDocumentClass

EC <	call	AssertIsStudioDocument					>
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	mov	bx, ds:[bx].GDI_fileHandle
	ret

GetFileHandle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LockMapBlockDS

DESCRIPTION:	Lock the map block to DS

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

RETURN:
	ds - map block (locked)

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 9/92		Initial version

------------------------------------------------------------------------------@
LockMapBlockDS	proc	far	uses ax, bx, bp
	.enter
EC <	call	AssertIsStudioDocument					>

	call	GetFileHandle
	call	VMGetMapBlock
	call	VMLock
	mov	ds, ax

	.leave
	ret

LockMapBlockDS	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LockMapBlockES

DESCRIPTION:	Lock the map block to ES

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

RETURN:
	ds - map block (locked)

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 9/92		Initial version

------------------------------------------------------------------------------@
LockMapBlockES	proc	far	uses ax, bx, bp
	.enter
EC <	call	AssertIsStudioDocument					>

	call	GetFileHandle
	call	VMGetMapBlock
	call	VMLock
	mov	es, ax

	.leave
	ret

LockMapBlockES	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMUnlockDS, VMUnlockES, VMDirtyDS, VMDirtyES

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
	Tony	9/13/92		Initial version

------------------------------------------------------------------------------@
VMUnlockDS	proc	far
	push	bp
	mov	bp, ds:[LMBH_handle]
	call	VMUnlock
	pop	bp
	ret

VMUnlockDS	endp

;---

VMUnlockES	proc	far
	push	bp
	mov	bp, es:[LMBH_handle]
	call	VMUnlock
	pop	bp
	ret

VMUnlockES	endp

;---

VMDirtyDS	proc	far
	push	bp
	mov	bp, ds:[LMBH_handle]
	call	VMDirty
	pop	bp
	ret

VMDirtyDS	endp

;---

VMDirtyES	proc	far
	push	bp
	mov	bp, es:[LMBH_handle]
	call	VMDirty
	pop	bp
	ret

VMDirtyES	endp

;---

StudioGetDGroupDS	proc	far
	push	bx
	clr	bx
	call	GeodeGetProcessHandle
	call	GeodeGetDGroupDS
	pop	bx
	ret
StudioGetDGroupDS	endp

;---

StudioGetDGroupES	proc	far
	push	bx
	clr	bx
	call	GeodeGetProcessHandle
	call	GeodeGetDGroupES
	pop	bx
	ret
StudioGetDGroupES	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	MemBlockToVMBlockCX

DESCRIPTION:	Get the VM block handle for a memory block given that DS
		points to an lmem block in the file

CALLED BY:	INTERNAL

PASS:
	cx - memory block handle

RETURN:
	cx - VM block handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
MemBlockToVMBlockCX	proc	far	uses ax
	.enter

	xchg	bx, cx				;bx = memory block, cx saves bx
	call	VMMemBlockToVMBlock		;ax = VM block, bx = file
	mov	bx, cx				;restore bx
	mov_tr	cx, ax				;cx = VM block

	.leave
	ret

MemBlockToVMBlockCX	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMBlockToMemBlockRefDS

DESCRIPTION:	Get the memory handle for a VM block given that DS points to
		an lmem block in the file

CALLED BY:	INTERNAL

PASS:
	ds - lmem block
	bx - VM block handle

RETURN:
	bx - memory handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
VMBlockToMemBlockRefDS	proc	far	uses ax
	.enter

	push	bx
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo			;ax = VM file
	mov_tr	bx, ax				;bx = file
	pop	ax				;ax = VM block

	call	VMVMBlockToMemBlock

	mov_tr	bx, ax

	.leave
	ret

VMBlockToMemBlockRefDS	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StudioVMBlockToMemBlock

DESCRIPTION:	Get the memory handle for a VM block in our document file

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	ax - VM block handle

RETURN:
	ax - memory handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
StudioVMBlockToMemBlock	proc	far	uses bx
	.enter
EC <	call	AssertIsStudioDocument					>

	call	GetFileHandle
	call	VMVMBlockToMemBlock

	.leave
	ret

StudioVMBlockToMemBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SectionArrayEToP_ES

DESCRIPTION:	Dereference element in the section array

CALLED BY:	INTERNAL

PASS:
	es - map block
	ax - section number

RETURN:
	es:di - section data
	cx - element size

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
SectionArrayEToP_ES	proc	far
	push	si
	segxchg	ds, es
	mov	si, offset SectionArray
	call	ChunkArrayElementToPtr
	segxchg	ds, es
	pop	si
	ret

SectionArrayEToP_ES	endp

;---

DC_ObjMessageNoFlags	proc	near	uses di
	.enter
	clr	di
	call	DC_ObjMessage
	.leave
	ret
DC_ObjMessageNoFlags	endp

;---

DC_ObjMessage	proc	near
	call	ObjMessage
	ret
DC_ObjMessage	endp

;-------

DocSTUFF segment resource

DS_ObjMessageNoFlags	proc	near
	push	di
	clr	di
	call	ObjMessage
	pop	di
	ret
DS_ObjMessageNoFlags	endp

DocSTUFF ends

;-------

;============================================================================
;	EC code
;============================================================================

COMMENT @----------------------------------------------------------------------

FUNCTION:	AssertIsStudioDocument

DESCRIPTION:	Assert the *ds:si is a StudioDocumentClass object

CALLED BY:	INTERNAL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 9/92		Initial version

------------------------------------------------------------------------------@
if	ERROR_CHECK

AssertIsStudioDocument	proc	far	uses di, es
	.enter
	pushf

	call	StudioGetDGroupES
	mov	di, offset StudioDocumentClass
	call	ObjIsObjectInClass
	ERROR_NC	OBJECT_NOT_A_STUDIO_DOCUMENT

	popf
	.leave
	ret
AssertIsStudioDocument	endp

endif

DocCommon ends
