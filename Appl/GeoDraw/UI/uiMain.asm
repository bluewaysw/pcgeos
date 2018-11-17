COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Draw/UI
FILE:		uiMain.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jon		21 mar 1993	initial revision

DESCRIPTION:
	$Id: uiMain.asm,v 1.2 98/07/20 19:31:54 joon Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata	segment

	SubclassedDuplicateControlClass
	SubclassedPasteInsideControlClass
	DrawImportControlClass
	DrawExportControlClass

idata	ends

InitCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDuplicateControlGenerateToolboxUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	DrawDuplicateControl method for MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI

Called by:	MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI

Pass:		*ds:si = DrawDuplicateControl object
		ds:di = DrawDuplicateControl instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 21, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDuplicateControlGenerateToolboxUI method dynamic SubclassedDuplicateControlClass,
				      MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI
	.enter

	call	EnsureEditControlBuilt

	mov	di, offset SubclassedDuplicateControlClass
	call	ObjCallSuperNoLock

	.leave
	ret
DrawDuplicateControlGenerateToolboxUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawPasteInsideControlGenerateToolboxUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	DrawPasteInsideControl method for MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI

Called by:	MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI

Pass:		*ds:si = DrawPasteInsideControl object
		ds:di = DrawPasteInsideControl instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 21, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawPasteInsideControlGenerateToolboxUI method dynamic SubclassedPasteInsideControlClass,
				      MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI
	.enter

	call	EnsureEditControlBuilt

	mov	di, offset SubclassedPasteInsideControlClass
	call	ObjCallSuperNoLock

	.leave
	ret
DrawPasteInsideControlGenerateToolboxUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureEditControlBuilt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Makes sure the edit control has been built out

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 21, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureEditControlBuilt	proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	;
	;  See if the controller has been built out yet
	;

	sub	sp, size TempGenControlInstance
	mov	di, sp

	mov	dx, size GetVarDataParams
	sub	sp, dx
	mov	bp, sp
	movdw	ss:[bp].GVDP_buffer, ssdi
	mov	ss:[bp].GVDP_bufferSize, size TempGenControlInstance
	mov	ss:[bp].GVDP_dataType, TEMP_GEN_CONTROL_INSTANCE

	GetResourceHandleNS	DrawEditControl, bx
	mov	si, offset DrawEditControl
	mov	ax, MSG_META_GET_VAR_DATA
	push	di				;save data ptr
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	di				;ss:[di] <- vardata

	;
	;  If couldn't return vardata, force build
	;
	cmp	ax, -1
	je	forceBuild

	;
	;  Check child block to determine whether it's built
	;
	tst	ss:[di].TGCI_childBlock
	jnz	clearStack

	;
	;  Force the Edit control to build
	;
forceBuild:

	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

clearStack:

	add	sp, size GetVarDataParams + size TempGenControlInstance

	.leave
	ret
EnsureEditControlBuilt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawImportControlNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Enable/disable DrawImportControl

Called by:	MSG_META_NOTIFY_WITH_DATA_BLOCK

Pass:		*ds:si	= DrawImportControlClass object
		ds:di	= DrawImportControlClass instance
		cx:dx	= NotificationType
		bp	- ^hNotifyTextChange
Return:		nothing
Destroyed:	ax, cx, dx, bp

Comments:	

Revision History:

	Name	    Date	Description
	----	-------------	-----------
	joon	July 20, 1998 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawImportControlNotifyWithDataBlock	method dynamic DrawImportControlClass, 
						MSG_META_NOTIFY_WITH_DATA_BLOCK
	cmp	dx, GWNT_DOCUMENT_CHANGE
	jne	callSuper
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper

	mov	ax, MSG_GEN_SET_ENABLED
	tst	bp
	jnz	ableIt
	mov	ax, MSG_GEN_SET_NOT_ENABLED
ableIt:
	push	cx, dx, bp
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp

callSuper:
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	di, offset DrawImportControlClass
	GOTO	ObjCallSuperNoLock

DrawImportControlNotifyWithDataBlock	endm

InitCode	ends



DocumentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawExportControlNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Enable/disable "Selected Objects" choice for export

Called by:	MSG_META_NOTIFY_WITH_DATA_BLOCK

Pass:		*ds:si	= DrawExportControlClass object
		ds:di	= DrawExportControlClass instance
		cx:dx	= NotificationType
		bp	= hptr for GrObjNotifySelectionStateChange
Return:		nothing
Destroyed:	ax, cx, dx, bp

Comments:	

Revision History:
	Name	Date		Description
	----	----		-----------
	Don	3/1/998 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawExportControlNotifyWithDataBlock	method dynamic DrawExportControlClass, 
					MSG_META_NOTIFY_WITH_DATA_BLOCK

	;
	; Check to see if this is the correct notification
	;
		cmp	dx, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE
		jne	callSuper
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	callSuper
	;
	; OK - enable/disable choice if objects are selected/not.
	;
		push	ax, cx, dx, bp, si, es
		mov	bx, bp
		call	MemLock
		mov	es, ax			; structure => ES:0
		mov	ax, MSG_GEN_SET_ENABLED
		tst	es:[GONSSC_selectionState].GSS_numSelected
		jnz	setState
		mov	ax, MSG_GEN_SET_NOT_ENABLED
setState:
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	si, offset ExportSelectedObjectsItem
		push	ax
		call	ObjCallInstanceNoLock
		pop	ax
	;
	; If we disable this GenItem, we also need to make sure it is
	; not selected, so we force the selection to the other item.
	;
		cmp	ax, MSG_GEN_SET_NOT_ENABLED
		jne	cleanUp
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	cx, MSG_GB_EXPORT
		clr	dx
		mov	si, offset DrawExportList
		call	ObjCallInstanceNoLock

cleanUp:
		call	MemUnlock
		pop	ax, cx, dx, bp, si, es
	;
	; We're done - call our superclass
	;
callSuper:
		mov	di, offset DrawExportControlClass
		GOTO	ObjCallSuperNoLock
DrawExportControlNotifyWithDataBlock	endm

DocumentCode	ends
