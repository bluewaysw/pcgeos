COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetMethodFocus.asm

AUTHOR:		John Wedgwood, Sep  4, 1991

METHODS:
	Name			Description
	----			-----------
MSG_META_GAINED_FOCUS_EXCL	gain focus handler
MSG_META_LOST_FOCUS_EXCL	lost focus handler
MSG_META_GAINED_TARGET_EXCL	gain target handler
MSG_META_LOST_TARGET_EXCL	lost target handler
MSG_META_GRAB_TARGET_EXCL	grab target handler

	InvertSelection		Invert selected cell and range
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 9/ 4/91	Initial revision

DESCRIPTION:
	Routines for recording when the spreadsheet gains/loses the focus.

	$Id: spreadsheetMethodFocus.asm,v 1.1 97/04/07 11:13:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGainedSysFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the spreadsheet to indicate that it has gained the
		SYSTEM focus exclusive.

CALLED BY:	via MSG_META_GAINED_SYS_FOCUS_EXCL
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		es	= Class segment
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGainedSysFocusExcl	method	SpreadsheetClass,
				MSG_META_GAINED_SYS_FOCUS_EXCL

	;
	; Let our superclass do its thing
	;
	mov	di, offset SpreadsheetClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Spreadsheet_offset
	mov	si, di
	ornf	ds:[si].SSI_flags, mask SF_IS_SYS_FOCUS
	test	ds:[si].SSI_flags, mask SF_IS_SYS_TARGET
	jnz	done				;branch if already target
	call	InvertSelection
done:
	;
	; Tell the rulers about the change.
	;
	mov	ax, MSG_SPREADSHEET_RULER_SET_FLAGS
	mov	dx, mask SRF_SSHEET_IS_FOCUS
	call	SendToRuler

	ret
SpreadsheetGainedSysFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGainedFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls SendTextFocusNotification to broadcast that spread-
		sheet object has gained the focus.

CALLED BY:	MSG_META_GAINED_FOCUS_EXCL
PASS:		*ds:si	= SpreadsheetClass object
		ds:di	= SpreadsheetClass instance data
		ds:bx	= SpreadsheetClass object (same as *ds:si)
		es 	= segment of SpreadsheetClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	HL	6/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGainedFocusExcl	method dynamic SpreadsheetClass, 
					MSG_META_GAINED_FOCUS_EXCL

	;
	; Let our superclass do its thing
	;
	mov	di, offset SpreadsheetClass
	call	ObjCallSuperNoLock

	mov	bp, mask TFF_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	call	SendTextFocusNotification

	ret
SpreadsheetGainedFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetLostSysFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the spreadsheet to indicate that it has lost the
		SYSTEM focus exclusive.

CALLED BY:	via MSG_META_LOST_SYS_FOCUS_EXCL
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		es	= Class segment
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetLostSysFocusExcl	method	SpreadsheetClass,
				MSG_META_LOST_SYS_FOCUS_EXCL

	push	si				; chunk handle
	mov	si, di
	andnf	ds:[si].SSI_flags, not mask SF_IS_SYS_FOCUS
	test	ds:[si].SSI_flags, mask SF_IS_SYS_TARGET
	jnz	done				;branch if still target
	call	InvertSelection
done:
	;
	; Tell the rulers about the change.
	;
	mov	ax, MSG_SPREADSHEET_RULER_SET_FLAGS
	mov	dx, (mask SRF_SSHEET_IS_FOCUS shl 8)
	call	SendToRuler
	;
	; Let our superclass do its thing
	;
	pop	si
	mov	ax, MSG_META_LOST_SYS_FOCUS_EXCL
	mov	di, offset SpreadsheetClass
	GOTO	ObjCallSuperNoLock
SpreadsheetLostSysFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetLostFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls SendTextFocusNotification to broadcast that spread-
		sheet object has lost the focus.

CALLED BY:	MSG_META_LOST_FOCUS_EXCL
PASS:		*ds:si	= SpreadsheetClass object
		ds:di	= SpreadsheetClass instance data
		ds:bx	= SpreadsheetClass object (same as *ds:si)
		es 	= segment of SpreadsheetClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	HL	6/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetLostFocusExcl	method dynamic SpreadsheetClass, 
					MSG_META_LOST_FOCUS_EXCL

	clr	bp
	call	SendTextFocusNotification

	;
	; Let our superclass do its thing
	;
	mov	ax, MSG_META_LOST_FOCUS_EXCL
	mov	di, offset SpreadsheetClass
	GOTO	ObjCallSuperNoLock
SpreadsheetLostFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendTextFocusNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the GWNT_EDITABLE_TEXT_OBJECT_HAS_FOCUS notification.

CALLED BY:	MSG_META_GAINED_FOCUS_EXCL handler
		MSG_META_LOST_FOCUS_EXCL handler

PASS:		bp	= TextFocusFlags to send out

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	code snarfed from procedure of same name in /s/p/Library/Text/
	TextSelect/tslMethodFocus.asm		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	HL	6/ 2/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendTextFocusNotification	proc	near

	;
	; Record event to send to ink controller.
	;
	mov	ax, MSG_META_NOTIFY
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	mov	di, mask MF_RECORD
	call	ObjMessage

	mov	ax, mask GCNLSF_SET_STATUS
	test	bp, mask  TFF_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	jnz	10$
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
10$:
	;
	; Send it to the appropriate gcn list.
	;
	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_NOTIFY_FOCUS_TEXT_OBJECT
	clr	ss:[bp].GCNLMP_block
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, ax

	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, dx

	ret
SendTextFocusNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert the entire selection
CALLED BY:	SpreadsheetLostFocusExcl(), SpreadsheetGainedFocusExcl()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InvertSelection	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; If we're in engine mode, don't invert the selection
	;
	test	ds:[si].SSI_attributes, mask SA_ENGINE_MODE
	jnz	done

	call	CreateGStateFar

	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column
	call	InvertActiveVisibleCellFar	;unactivate current cell
	call	InvertSelectedVisibleCellFar	;invert to allow rectangle
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	bp, ds:[si].SSI_selected.CR_end.CR_row
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column
	call	InvertSelectedVisibleRangeFar	;deselect range

	call	DestroyGStateFar
done:

	.leave
	ret
InvertSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle gained APP target exclusive
CALLED BY:	MSG_META_GAINED_TARGET_EXCL

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetGainedTargetExcl	method dynamic SpreadsheetClass, \
						MSG_META_GAINED_TARGET_EXCL
	mov	si, di				;ds:si <- ptr to instance data
	ornf	ds:[si].SSI_flags, mask SF_IS_APP_TARGET
	;
	; Force all UI to update
	;
	mov	ax, SNFLAGS_DOCUMENT_CHANGED
	call	SS_SendNotification
	;
	; disable paragraph attributes (besides Justification)
	;
	test	ds:[si].SSI_attributes, mask SA_ENGINE_MODE
	jnz	noPara
	call	SS_SendNullParaAttrNotification
noPara:
	;
	; The the rulers about the change
	;
	mov	ax, MSG_SPREADSHEET_RULER_SET_FLAGS
	mov	dx, mask SRF_SSHEET_IS_TARGET
	call	SendToRuler
	ret
SpreadsheetGainedTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle loss of APP target exclusive
CALLED BY:	MSG_META_LOST_TARGET_EXCL

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetLostTargetExcl	method dynamic SpreadsheetClass, \
						MSG_META_LOST_TARGET_EXCL
	mov	si, di				;ds:si <- ptr to instance data
	andnf	ds:[si].SSI_flags, not (mask SF_IS_APP_TARGET)
	;
	; Force all UI to update
	;
	clr	ax				;ax <- force update
	call	SS_SendNotification
	;
	; Tell the rulers about the change
	;
	mov	ax, MSG_SPREADSHEET_RULER_SET_FLAGS
	mov	dx, (mask SRF_SSHEET_IS_TARGET shl 8)
	call	SendToRuler
	ret
SpreadsheetLostTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGrabTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle 'grab target' if we're supposed to
CALLED BY:	MSG_META_GRAB_TARGET_EXCL

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetGrabTargetExcl	method dynamic SpreadsheetClass, \
						MSG_META_GRAB_TARGET_EXCL
	;
	; If we aren't targetable, don't grab the target
	;
	test	ds:[di].SSI_attributes, mask SA_TARGETABLE
	jz	done
	mov	di, offset SpreadsheetClass
	call	ObjCallSuperNoLock
done:
	ret
SpreadsheetGrabTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGainedSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handling gaining the SYSTEM target exclusive

CALLED BY:	MSG_META_GAINED_TARGET_EXCL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGainedSysTargetExcl		method dynamic SpreadsheetClass,
						MSG_META_GAINED_SYS_TARGET_EXCL
	mov	si, di				;ds:si <- ptr to spreadsheet
	ornf	ds:[si].SSI_flags, mask SF_IS_SYS_TARGET
	;
	; If we don't already have the focus, invert the selection
	;
	test	ds:[si].SSI_flags, mask SF_IS_SYS_FOCUS
	jnz	done				;branch if already focus
	call	InvertSelection
done:
	ret
SpreadsheetGainedSysTargetExcl		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetLostSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle losing the SYSTEM target exclusive

CALLED BY:	MSG_META_LOST_TARGET_EXCL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetLostSysTargetExcl		method dynamic SpreadsheetClass,
						MSG_META_LOST_SYS_TARGET_EXCL
	mov	si, di				;ds:si <- ptr to spreadsheet
	andnf	ds:[si].SSI_flags, not (mask SF_IS_SYS_TARGET)
	;
	; If we don't have the focus, either, invert the selection
	;
	test	ds:[si].SSI_flags, mask SF_IS_SYS_FOCUS
	jnz	done				;branch if still focus
	call	InvertSelection
done:
	ret
SpreadsheetLostSysTargetExcl		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetLostGadgetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle loss of gadget exclusive...

CALLED BY:	MSG_VIS_LOST_GADGET_EXCL

PASS:		ds:*si - ptr to instance data
		ds:di - ptr to instance data
		es - segment of SpreadsheetClass
		ax = MSG_VIS_LOST_GADGET_EXCL.

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: This message is send a lot when you are receiving mouse events.
	This is why it is in the DrawCode resource -- DrawCode isn't used
	(much, if at all) when the spreadsheet is in engine mode, and neither
	is this.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetLostGadgetExcl	method	SpreadsheetClass,
							MSG_VIS_LOST_GADGET_EXCL
	andnf	ds:[di].SSI_flags, not (mask SF_HAVE_GRAB)
	call	VisReleaseMouse
	ret
SpreadsheetLostGadgetExcl	endm

CommonCode	ends
