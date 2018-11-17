COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		GeoDraw
FILE:		uiTemplate.asm

AUTHOR:		Joon Song, Nov 11, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	11/11/98   	Initial revision


DESCRIPTION:
		
	

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Design Assistant header constants
;
ASST_HEADER_TEXT_SETTINGS_OFFSET	equ	0
ASST_HEADER_TEXT_DRAW_SHADOW_OFFSET	equ	ASST_HEADER_TEXT_SETTINGS_OFFSET + size OpDrawBitmapOptr + size OpSetTextAttr
SHADOW_OFFSET				equ	2
idata	segment
	DrawTemplateWizardClass
	DrawTemplateImageClass
	DrawTemplateFieldTextClass
idata	ends

;----

DocOpenClose	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateWizardInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize and start template wizard

CALLED BY:	MSG_DRAW_TEMPLATE_WIZARD_INITIALIZE

PASS:		*ds:si	= DrawTemplateWizardClass object
		ds:di	= DrawTemplateWizardClass instance data
		ds:bx	= DrawTemplateWizardClass object (same as *ds:si)
		es 	= segment of DrawTemplateWizardClass
		ax	= message #
		^lcx:dx	= DrawDocumentClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/06/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateWizardInitialize	method dynamic DrawTemplateWizardClass, 
					MSG_DRAW_TEMPLATE_WIZARD_INITIALIZE
	clr	ds:[di].DTWI_state
	mov	ds:[di].DTWI_tagNum, -1
	movdw	ds:[di].DTWI_document, cxdx

	; Add ourselves to GCN list to get MSG_META_DETACH
	sub	sp, size GCNListParams
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_optr.offset, si
	mov	dx, size GCNListParams
	mov	ax, MSG_META_GCN_LIST_ADD
	call	GenCallApplication
	add	sp, size GCNListParams

	; Allocate chunk array for ReplacementTextItem's.

	push	si
	clr	al			; no ObjChunkFlags
	mov	bx, size ReplacementTextItem
	clr	cx			; default ChunkArrayHeader
	clr	si			; alloc new chunk
	call	ChunkArrayCreate
	mov	ax, si			; *ds:ax = chunk array
	pop	si

	mov	di, ds:[si]
	add	di, ds:[di].DrawTemplateWizard_offset
	mov	ds:[di].DTWI_textArray, ax

	; Apply custom settings to our wizard header bitmap
	push	si, di
	mov	si, offset TemplateWizardHeaderMoniker
	mov	si, ds:[si]		; ds:si <- wizard header moniker
	lea	si, ds:[si].VM_data.VMGS_gstring	; ds:si <- gstring
	push	si
	add	si, ASST_HEADER_TEXT_SETTINGS_OFFSET

	; font size of text
	mov	di, offset wizardHeaderFontSize
	mov	di, ds:[di]	
	call	LocalAsciiToFixed	; dx:ax <- font size (WWFixed)
	mov	ds:[si].OSTA_attr.TA_size.WBF_int, dx
	mov	ds:[si].OSTA_attr.TA_size.WBF_frac, ah

	; kerning value of text
	mov	di, offset wizardHeaderKerning
	mov	di, ds:[di]
	call	LocalAsciiToFixed	; dx:ax <- kerning value
	mov	ds:[si].OSTA_attr.TA_trackKern, dx

	; Y coordinate of text
	pop	si
	add	si, ASST_HEADER_TEXT_DRAW_SHADOW_OFFSET
	mov	di, offset wizardHeaderY	
	mov	di, ds:[di]
	call	LocalAsciiToFixed	; dx:ax <- Y coordinate
	add	dx, SHADOW_OFFSET
	mov	ds:[si].ODTO_y1, dx
	add	si, size OpDrawTextOptr + size OpSetTextColor
	sub	dx, SHADOW_OFFSET
	mov	ds:[si].ODTO_y1, dx
	pop	si, di

	; Reset the title

	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	cx, ds:[LMBH_handle]
	mov	dx, offset TemplateWizardDialogMoniker
	mov	bp, VUM_MANUAL
	call	ObjCallInstanceNoLock

	; Finally, start searching for tags.

	mov	ax, MSG_DRAW_TEMPLATE_WIZARD_FIND_NEXT_TAG
	GOTO	ObjCallInstanceNoLock

DrawTemplateWizardInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateWizardFindNextTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find next tag

CALLED BY:	MSG_DRAW_TEMPLATE_WIZARD_FIND_NEXT_TAG

PASS:		*ds:si	= DrawTemplateWizardClass object
		ds:di	= DrawTemplateWizardClass instance data
		ds:bx	= DrawTemplateWizardClass object (same as *ds:si)
		es 	= segment of DrawTemplateWizardClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/06/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateWizardFindNextTag	method dynamic DrawTemplateWizardClass, 
					MSG_DRAW_TEMPLATE_WIZARD_FIND_NEXT_TAG
	; Start searching for template tags.

	ornf	ds:[di].DTWI_state, mask DTWS_SEARCHING
	inc	ds:[di].DTWI_tagNum

	clr	ax				; no replaceString
	clr	dx				; no SearchOptions
	call	AllocSearchReplaceStructBlock	; ^hbx = SearchReplaceStruct

	mov	ax, MSG_SEARCH
	mov	dx, bx
	clr	bx, di
	call	RecordAndSendToAppTarget

	; Get the selected text so we can parse the tags

	mov	ax, MSG_VIS_TEXT_RETURN_SELECTION_BLOCK
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, MSG_DRAW_TEMPLATE_WIZARD_PARSE_TAGS
	mov	bx, segment VisTextClass
	mov	di, offset VisTextClass
	call	RecordAndSendToAppTarget

	ret
DrawTemplateWizardFindNextTag	endm

; Pass:		*ds:si	= DrawTemplateWizardClass object
;		ax	= message to record
;		bx:di	= destination of message
;		cx,dx,bp= data to pass with message
; Return:	???
; Destroyed:	everything except *ds:si
;
RecordAndSendToAppTarget	proc	near
	class	DrawTemplateWizardClass

	push	si
	mov	si, di
	mov	di, mask MF_RECORD
	call	ObjMessage		; di = record message
	pop	si

	push	si
	mov	si, ds:[si]
	add	si, ds:[si].DrawTemplateWizard_offset
	mov	bx, ds:[si].DTWI_document.handle
	mov	si, ds:[si].DTWI_document.offset
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	cx, di
	mov	dx, TO_APP_TARGET
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	ret
RecordAndSendToAppTarget	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateWizardReplaceTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace current tag and continue template wizard

CALLED BY:	MSG_DRAW_TEMPLATE_WIZARD_REPLACE_TAG

PASS:		*ds:si	= DrawTemplateWizardClass object
		ds:di	= DrawTemplateWizardClass instance data
		ds:bx	= DrawTemplateWizardClass object
		es 	= segment of DrawTemplateWizardClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	11/11/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateWizardReplaceTag method dynamic DrawTemplateWizardClass, 
				MSG_DRAW_TEMPLATE_WIZARD_REPLACE_TAG
	; ignore request to replace current tag if we are searching.

	test	ds:[di].DTWI_state, mask DTWS_SEARCHING
	LONG jnz done

	; replace tag only if we're replacing

	test	ds:[di].DTWI_state, mask DTWS_REPLACING
	jnz	replace

	; otherwise just save the current dataType and replacement text

	push	si
	mov	ax, ds:[di].DTWI_tagNum
	mov	si, ds:[di].DTWI_textArray
	mov	dl, ds:[di].DTWI_dataType
	call	ChunkArrayElementToPtr
	jnc	10$
	call	ChunkArrayAppend
10$:	pop	si

	mov	ds:[di].RTI_dataType, dl
	mov	dx, ds:[di].RTI_dataBlock

	push	si
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	si, offset TemplateWizardFieldText
	call	ObjCallInstanceNoLock
	pop	si

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].DrawTemplateWizard_offset
	mov	ax, ds:[di].DTWI_tagNum
	mov	si, ds:[di].DTWI_textArray
	call	ChunkArrayElementToPtr
	mov	ds:[di].RTI_dataBlock, cx
	pop	si

	; save user info

	call	DrawTemplateWizardSaveUserInfo

	; if we're finished, tben reset tag number and start replacing tags

	mov	di, ds:[si]
	add	di, ds:[di].DrawTemplateWizard_offset
	test	ds:[di].DTWI_state, mask DTWS_FINISHED
	jz	nextTag

	andnf	ds:[di].DTWI_state, not mask DTWS_FINISHED
	ornf	ds:[di].DTWI_state, mask DTWS_REPLACING
	mov	ds:[di].DTWI_tagNum, -1

	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	call	UserCallApplication
	jmp	nextTag

replace:
	; create SearchReplaceStruct and copy replacement string into it.

	push	si
	mov	ax, ds:[di].DTWI_tagNum
	mov	si, ds:[di].DTWI_textArray
	call	ChunkArrayElementToPtr		; ds:di = string, cx = size
	pop	si

	push	ds, si
	mov	bx, ds:[di].RTI_dataBlock
	call	MemLock
	push	bx

	mov	es, ax
	clr	di
	LocalStrSize includeNull		; cx = string size

	mov	ax, cx				; ax = replace string size
	clr	dx				; no SearchOptions
	call	AllocSearchReplaceStructBlock	; ^hbx = SearchReplaceStruct
	mov	dx, bx				; ^hdx = SearchReplaceStruct

	call	MemLock				; lock SearchReplaceStruct
	segmov	ds, es
	clr	si
	mov	es, ax
	mov	di, (size SearchReplaceStruct) + \
		    (size templateWizardSearchString)
	mov	es:[SRS_replaceSize], cx	; save replace size
	rep	movsb				; copy SRS_replaceString
	call	MemUnlock			; unlock SearchReplaceStruct

	pop	bx
	call	MemUnlock			; unlock replacement text block
	pop	ds, si

	; replace currently selected tag with replacement text

	mov	ax, MSG_REPLACE_CURRENT
	clr	bx, di
	call	RecordAndSendToAppTarget

nextTag:
	; continue search and replace of template tags

	mov	ax, MSG_DRAW_TEMPLATE_WIZARD_FIND_NEXT_TAG
	GOTO	ObjCallInstanceNoLock
done:
	ret
DrawTemplateWizardReplaceTag	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateWizardSaveUserInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save user info to .ini file

CALLED BY:	DrawTemplateWizardReplaceTag
PASS:		*ds:si	= DrawTemplateWizardClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/17/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateWizardSaveUserInfo	proc	near
	class	DrawTemplateWizardClass
	uses	ax,bx,cx,dx,si,di,bp,ds,es
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].DrawTemplateWizard_offset

	mov	ax, ds:[di].DTWI_tagNum
	mov	si, ds:[di].DTWI_textArray
	call	ChunkArrayElementToPtr
	jc	done

	mov	al, ds:[di].RTI_dataType
	mov	bx, ds:[di].RTI_dataBlock

	mov	dx, offset userinfoNameKey
	cmp	al, DTWDT_USER_NAME
	je	saveInfo

	mov	dx, offset userinfoAddressKey
	cmp	al, DTWDT_USER_ADDRESS
	je	saveInfo

	mov	dx, offset userinfoPhoneKey
	cmp	al, DTWDT_USER_PHONE
	je	saveInfo

	mov	dx, offset userinfoEmailKey
	cmp	al, DTWDT_USER_EMAIL
	jne	done

saveInfo:
	call	MemLock
	mov	es, ax
	clr	di
	LocalStrSize includeNull
	mov	bp, cx			; bp = data size
	clr	di			; es:di = buffer
	mov	cx, cs			; cx:dx = key
	mov	ds, cx			; ds:si = category
	mov	si, offset userinfoCategory
	call	InitFileWriteData
	call	MemUnlock
done:
	.leave
	ret
DrawTemplateWizardSaveUserInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateWizardTagNotFound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End template wizard

CALLED BY:	MSG_DRAW_TEMPLATE_WIZARD_TAG_NOT_FOUND

PASS:		*ds:si	= DrawTemplateWizardClass object
		ds:di	= DrawTemplateWizardClass instance data
		ds:bx	= DrawTemplateWizardClass object
		es 	= segment of DrawTemplateWizardClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	11/12/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateWizardTagNotFound	method dynamic DrawTemplateWizardClass, 
					MSG_DRAW_TEMPLATE_WIZARD_TAG_NOT_FOUND
	; Close template wizard dialog when no more template tags.

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS		
	call	ObjCallInstanceNoLock

	;
	; We suspended all of the windows earlier, so now we
	; need to clean things up
	;
	GetResourceHandleNS DrawPrimary, bx
	mov	si, offset DrawPrimary
	mov	ax, MSG_VIS_QUERY_WINDOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; cx = window
	mov	di, cx			; first Window
	call	DrawUnSuspendWindowTree
	ret
DrawTemplateWizardTagNotFound	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateWizardInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End template wizard

CALLED BY:	MSG_GEN_GUP_INTERACTION_COMMAND

PASS:		*ds:si	= DrawTemplateWizardClass object
		ds:di	= DrawTemplateWizardClass instance data
		ds:bx	= DrawTemplateWizardClass object (same as *ds:si)
		es 	= segment of DrawTemplateWizardClass
		ax	= message #
		cx	= InteractionCommand
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/06/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateWizardInteractionCommand method dynamic DrawTemplateWizardClass, 
					MSG_GEN_GUP_INTERACTION_COMMAND
	push	cx
	mov	di, offset DrawTemplateWizardClass
	call	ObjCallSuperNoLock
	pop	cx

	cmp	cx, IC_DISMISS
	jne	done

	; Dismissed dialog - now clean up.

	; Remove ourselves to GCN list to get MSG_META_DETACH
	call	RemoveFromActiveList

	push	si
	mov	ax, MSG_DRAW_TEMPLATE_IMAGE_CLOSE_IMAGE_FILE
	mov	si, offset TemplateWizardDocumentImage
	call	ObjCallInstanceNoLock
	pop	si

	mov	di, ds:[si]
	add	di, ds:[di].DrawTemplateWizard_offset
	test	ds:[di].DTWI_state, mask DTWS_REPLACING
	jz	destroy

	; we were replacing, so we should accept input again

	mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
	call	UserCallApplication

destroy:
	; finally, destroy and free dialog

	mov	di, ds:[si]
	add	di, ds:[di].DrawTemplateWizard_offset
	test	ds:[di].DTWI_state, mask DTWS_DESTROYING
	jnz	done
	mov	al, ds:[di].DTWI_state
	andnf	al, mask DTWS_DETACHING		; perserve only this
	ornf	al, mask DTWS_DESTROYING	; set this
	mov	ds:[di].DTWI_state, al

	mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
	GOTO	ObjCallInstanceNoLock
done:
	ret
DrawTemplateWizardInteractionCommand	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteTemplateWiardDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel template wizard and close document

CALLED BY:	MSG_META_DETACH

PASS:		*ds:si	= DrawTemplateWizardClass object
		ds:di	= DrawTemplateWizardClass instance data
		ds:bx	= DrawTemplateWizardClass object (same as *ds:si)
		es 	= segment of DrawTemplateWizardClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/06/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveFromActiveList	proc	near
	sub	sp, size GCNListParams
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_optr.offset, si
	mov	dx, size GCNListParams
	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	GenCallApplication
	add	sp, size GCNListParams
	ret
RemoveFromActiveList	endp

DrawTemplateWizardDetach	method	dynamic	DrawTemplateWizardClass,
						MSG_META_DETACH
	ornf	ds:[di].DTWI_state, mask DTWS_DETACHING
	push	ax, cx, dx, bp
	;	
	; Remove ourselves to GCN list to get MSG_META_DETACH
	;
	call	RemoveFromActiveList
	;
	; close ourselves
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock
	mov	ax, MSG_DRAW_TEMPLATE_WIZARD_CANCEL_AND_CLOSE
	call	ObjCallInstanceNoLock
	;
	; let superclass finish ack
	;
	pop	ax, cx, dx, bp
	mov	di, offset DrawTemplateWizardClass
	call	ObjCallSuperNoLock
	ret
DrawTemplateWizardDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateWizardCancelAndClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel template wizard and close document

CALLED BY:	MSG_DRAW_TEMPLATE_WIZARD_CANCEL_AND_CLOSE

PASS:		*ds:si	= DrawTemplateWizardClass object
		ds:di	= DrawTemplateWizardClass instance data
		ds:bx	= DrawTemplateWizardClass object (same as *ds:si)
		es 	= segment of DrawTemplateWizardClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/06/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateWizardCancelAndClose method dynamic DrawTemplateWizardClass, 
				MSG_DRAW_TEMPLATE_WIZARD_CANCEL_AND_CLOSE

	;	
	; Remove ourselves to GCN list to get MSG_META_DETACH
	;
	call	RemoveFromActiveList

	mov	di, ds:[si]
	add	di, ds:[di].DrawTemplateWizard_offset
	test	ds:[di].DTWI_state, mask DTWS_DETACHING
	jnz	done
	call	DetermineToCloseDocOrExitApp
	clr	bp
	push	ax
	call	RecordAndSendToAppTarget
	pop	ax
	cmp	ax, MSG_GEN_DOCUMENT_CLOSE
	je	close

	push	si
	GetResourceHandleNS DrawPrimary, bx
	mov	si, offset DrawPrimary
	mov	ax, MSG_VIS_QUERY_WINDOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; cx = window
	mov	di, cx			; first Window
	call	DrawSuspendWindowTree
	pop	si

close:
	mov	bx, segment GenDocumentClass
	mov	di, offset GenDocumentClass
	mov	ax, MSG_DRAW_DOCUMENT_UNSUSPEND_WIN_UPDATE
	call	RecordAndSendToAppTarget
done:
	ret
DrawTemplateWizardCancelAndClose endm

;
; If there is more than one document opened (more than the template
; document), then close the template document, otherwise exit the app.
; Pass: nothing
; Return: ax - MSG_GEN_DOCUMENT_CLOSE or MSG_META_QUIT
;         bx:di - segment:offset of either
;                   GenDocumentClass or GenApplicationClass
;
DetermineToCloseDocOrExitApp	proc	near
	class	DrawTemplateWizardClass
	uses	si, cx, dx, bp
	.enter

	call	DidAppLaunchDesignAssistent
	jc	DAlauchedBefore
	GetResourceHandleNS	DrawDisplayGroupObj, bx
	mov	si, offset DrawDisplayGroupObj
	mov	ax, MSG_GEN_COUNT_CHILDREN
	mov	di, mask MF_CALL		; both on UI thread
	call	ObjMessage	; dx - children count
	mov	ax, MSG_META_QUIT
	mov	bx, segment GenApplicationClass		
	mov	di, offset GenApplicationClass
	cmp	dx, 1
	je	exit
DAlauchedBefore:
	mov	ax, MSG_GEN_DOCUMENT_CLOSE
	mov	bx, segment GenDocumentClass
	mov	di, offset GenDocumentClass
exit:
	.leave
	ret
DetermineToCloseDocOrExitApp	endp

;
;  Pass:  nothing
;
DidAppLaunchDesignAssistent	proc	near
	uses	ax, di, si, bx, cx, dx, bp
	.enter
	GetResourceHandleNS	DrawDocumentControlObj, bx
	mov	si, offset DrawDocumentControlObj
	mov	ax, MSG_DRAW_DOCUMENT_CONTROL_LAUNCHED_DA
	mov	di, mask MF_CALL		; both on UI thread
	call	ObjMessage	; cx - 1 if launched Design Assistent before.
	jcxz	never
	stc
	jmp	quit
never:
	clc
quit:
	.leave
	ret
DidAppLaunchDesignAssistent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateWizardUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo and return to previous template wizard item.

CALLED BY:	MSG_DRAW_TEMPLATE_WIZARD_UNDO

PASS:		*ds:si	= DrawTemplateWizardClass object
		ds:di	= DrawTemplateWizardClass instance data
		ds:bx	= DrawTemplateWizardClass object
		es 	= segment of DrawTemplateWizardClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	11/13/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateWizardUndo	method dynamic DrawTemplateWizardClass, 
				MSG_DRAW_TEMPLATE_WIZARD_UNDO
	test	ds:[di].DTWI_state, mask DTWS_REPLACING
	jnz	done

	push	si
	mov	ax, ds:[di].DTWI_tagNum
	mov	si, ds:[di].DTWI_textArray
	mov	dl, ds:[di].DTWI_dataType
	call	ChunkArrayElementToPtr
	jnc	10$
	call	ChunkArrayAppend
10$:	pop	si

	mov	ds:[di].RTI_dataType, dl
	mov	dx, ds:[di].RTI_dataBlock

	push	si
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	si, offset TemplateWizardFieldText
	call	ObjCallInstanceNoLock
	pop	si

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].DrawTemplateWizard_offset
	mov	ax, ds:[di].DTWI_tagNum
	mov	si, ds:[di].DTWI_textArray
	call	ChunkArrayElementToPtr
	mov	ds:[di].RTI_dataBlock, cx
	pop	si

	; save user info

	call	DrawTemplateWizardSaveUserInfo


	; Find the previous template field.

	mov	di, ds:[si]
	add	di, ds:[di].DrawTemplateWizard_offset
	andnf	ds:[di].DTWI_state, not mask DTWS_FINISHED
	ornf	ds:[di].DTWI_state, mask DTWS_SEARCHING
	dec	ds:[di].DTWI_tagNum

	clr	ax				; no replaceString
	mov	dl, mask SO_BACKWARD_SEARCH	; SearchOptions
	call	AllocSearchReplaceStructBlock	; ^hbx = SearchReplaceStruct

	mov	ax, MSG_SEARCH
	mov	dx, bx
	clr	bx, di
	call	RecordAndSendToAppTarget

	; Get the selected text so we can parse the tags

	mov	ax, MSG_VIS_TEXT_RETURN_SELECTION_BLOCK
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, MSG_DRAW_TEMPLATE_WIZARD_PARSE_TAGS
	mov	bx, segment VisTextClass
	mov	di, offset VisTextClass
	call	RecordAndSendToAppTarget
done:
	ret
DrawTemplateWizardUndo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateWizardDateSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle date selection by user

CALLED BY:	MSG_DRAW_TEMPLATE_WIZARD_DATE_SELECTED

PASS:		*ds:si	= DrawTemplateWizardClass object
		ds:di	= DrawTemplateWizardClass instance data
		ds:bx	= DrawTemplateWizardClass object (same as *ds:si)
		es 	= segment of DrawTemplateWizardClass
		ax	= message #
		cx	= current selection
		bp	= number of selections
		dl	= GenItemGroupStateFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/16/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateWizardDateSelected	method dynamic DrawTemplateWizardClass, 
					MSG_DRAW_TEMPLATE_WIZARD_DATE_SELECTED
dateTimeBuffer	local	DATE_TIME_BUFFER_SIZE dup (Chars)
	.enter

	push	cx, bp
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	si, offset TemplateWizardFieldText
	call	ObjCallInstanceNoLock
	pop	si, bp

	cmp	si, DTF_END_DATE_FORMATS
	jae	done

	call	TimerGetDateAndTime

	segmov	es, ss
	lea	di, ss:[dateTimeBuffer]
	call	LocalFormatDateTime

	push	bp
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	lea	bp, ss:[dateTimeBuffer]
	clr	cx
	mov	si, offset TemplateWizardFieldText
	call	ObjCallInstanceNoLock
	pop	bp	
done:
	.leave
	ret
DrawTemplateWizardDateSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateWizardFieldTextStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle Field Text object status message

CALLED BY:	MSG_DRAW_TEMPLATE_WIZARD_FIELD_TEXT_STATUS

PASS:		*ds:si	= DrawTemplateWizardClass object
		ds:di	= DrawTemplateWizardClass instance data
		ds:bx	= DrawTemplateWizardClass object (same as *ds:si)
		es 	= segment of DrawTemplateWizardClass
		ax	= message #
		bp	= GenTextStateFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/16/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateWizardFieldTextStatus method dynamic DrawTemplateWizardClass, 
				MSG_DRAW_TEMPLATE_WIZARD_FIELD_TEXT_STATUS
	test	bp, mask GTSF_MODIFIED
	jz	done

	cmp	ds:[di].DTWI_dataType, DTWDT_DATE
	jne	done

	; Date text has been changed by the user.  Select "User text" item.

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, DTF_END_DATE_FORMATS
	clr	dx
	mov	si, offset TemplateWizardDateGroup
	GOTO	ObjCallInstanceNoLock
done:
	ret
DrawTemplateWizardFieldTextStatus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateWizardParseTags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse template tag

CALLED BY:	MSG_DRAW_TEMPLATE_WIZARD_PARSE_TAGS

PASS:		*ds:si	= DrawTemplateWizardClass object
		ds:di	= DrawTemplateWizardClass instance data
		ds:bx	= DrawTemplateWizardClass object
		es 	= segment of DrawTemplateWizardClass
		ax	= message #
		cx	= block containing instruction text (must be freed)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	11/13/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateWizardParseTags	method dynamic DrawTemplateWizardClass, 
					MSG_DRAW_TEMPLATE_WIZARD_PARSE_TAGS
	mov	bx, cx

	; If we weren't searching then just bail

	test	ds:[di].DTWI_state, mask DTWS_SEARCHING
	jnz	continue

	GOTO	MemFree

emptyString:
	mov	ax, MSG_DRAW_TEMPLATE_WIZARD_TAG_NOT_FOUND
	call	ObjCallInstanceNoLock
	GOTO	MemFree

continue:

	;  If the search result is empty, quit too.

	push	es, di
	call	MemLock
	mov	es, ax
	clr	di
	LocalGetChar ax, esdi
	LocalCmpChar ax, C_NULL
	pop	es, di
	je	emptyString
	call	MemUnlock

	; Reset DrawTemplateWizardState to normal

	andnf	ds:[di].DTWI_state, not mask DTWS_SEARCHING
	mov	ds:[di].DTWI_dataType, DTWDT_TEXT

	; Check if we're finished and just replacing tags

	test	ds:[di].DTWI_state, mask DTWS_REPLACING
	jz	parsing

	call	MemFree

	mov	ax, MSG_DRAW_TEMPLATE_WIZARD_REPLACE_TAG
	GOTO	ObjCallInstanceNoLock

parsing:
	; Set the UI group not usable so we minimize the flashing.

	push	si
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	si, offset TemplateWizardUIGroup
	call	ObjCallInstanceNoLock

	; Make sure the DateGroup is not usable.

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	si, offset TemplateWizardDateGroup
	call	ObjCallInstanceNoLock

	; And the FieldText is usable and cleared of any text.

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	mov	si, offset TemplateWizardFieldText
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	ObjCallInstanceNoLock

	; Make sure we have a single line FieldText.

	mov	ax, HINT_FIXED_SIZE
	call	ObjVarDeleteData

	mov	ax, MSG_GEN_TEXT_SET_ATTRS
	mov	cx, mask GTA_INIT_SCROLLING shl 8 or mask GTA_SINGLE_LINE_TEXT
	call	ObjCallInstanceNoLock

	; Set the default moniker for "Next Step" trigger.

	mov	ax, MSG_GEN_GET_VIS_MONIKER
	mov	si, offset WizardHackGlyph
	call	ObjCallInstanceNoLock		; get combined text + bitmap
	push	ax				; ...moniker and use it!
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	mov	si, offset TemplateWizardNextTrigger
	call	ObjCallInstanceNoLock		; current moniker => AX
	pop	cx
	cmp	ax, cx
	je	doneNext
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock		; OK, reset the moniker
doneNext:
	pop	si

	; Set the "Prev Step" trigger enabled/disabled.

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].DrawTemplateWizard_offset
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	tst	ds:[di].DTWI_tagNum
	jle	setPrev
	mov	ax, MSG_GEN_SET_ENABLED
setPrev:
	mov	dl, VUM_MANUAL
	mov	si, offset TemplateWizardPrevTrigger
	call	ObjCallInstanceNoLock
	pop	si

	; Restore previous replacement text if any

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].DrawTemplateWizard_offset
	mov	ax, ds:[di].DTWI_tagNum
	mov	si, ds:[di].DTWI_textArray
	call	ChunkArrayElementToPtr
	pop	si
	jc	parseTags

	push	si
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_BLOCK
	clr	cx
	mov	dx, ds:[di].RTI_dataBlock
	mov	si, offset TemplateWizardFieldText
	call	ObjCallInstanceNoLock
	pop	si

parseTags:
	; Parse tags

	call	MemLock
	push	bx

	mov	es, ax
	clr	di
scanString:
	LocalGetChar ax, esdi
	LocalCmpChar ax, C_NULL
	LONG je	finishedParsing
	LocalCmpChar ax, C_SLASH
	jne	scanString

checkImg::
DBCS <	cmp	{word}es:[di], 'i'					>
DBCS <	jne	checkDescText						>
DBCS <	cmp	{word}es:[di+2], 'm'					>
SBCS <	cmp	{word}es:[di], 'im'					>
	jne	checkDescText

	call	ProcessImageTag
	jmp	scanString

checkDescText:
DBCS <	cmp	{word}es:[di], 'd'					>
DBCS <	jne	checkFieldText						>
DBCS <	cmp	{word}es:[di+2], 'e'					>
SBCS <	cmp	{word}es:[di], 'de'					>
	jne	checkFieldText

	call	ProcessDescriptionTextTag
	jmp	scanString

checkFieldText:
DBCS <	cmp	{word}es:[di], 'f'					>
DBCS <	jne	checkNoFieldText					>
DBCS <	cmp	{word}es:[di+2], 'n'					>
SBCS <	cmp	{word}es:[di], 'fn'					>
	jne	checkNoFieldText

	call	ProcessFieldTextTag
	jmp	scanString

checkNoFieldText:
DBCS <	cmp	{word}es:[di], 'n'					>
DBCS <	jne	checkFieldTextWidth					>
DBCS <	cmp	{word}es:[di+2], 'f'					>
SBCS <	cmp	{word}es:[di], 'nf'					>
	jne	checkFieldTextWidth

	call	ProcessNoFieldTextTag
	jmp	scanString

checkFieldTextWidth:
DBCS <	cmp	{word}es:[di], 'f'					>
DBCS <	jne	checkFieldTextHeight					>
DBCS <	cmp	{word}es:[di+2], 'w'					>
SBCS <	cmp	{word}es:[di], 'fw'					>
	jne	checkFieldTextHeight

	call	ProcessFieldTextWidthTag
	jmp	scanString

checkFieldTextHeight:
DBCS <	cmp	{word}es:[di], 'f'					>
DBCS <	jne	checkDate						>
DBCS <	cmp	{word}es:[di+2], 'h'					>
SBCS <	cmp	{word}es:[di], 'fh'					>
	jne	checkDate

	call	ProcessFieldTextHeightTag
	jmp	scanString
		
checkDate:
DBCS <	cmp	{word}es:[di], 'd'					>
DBCS <	jne	checkTitle						>
DBCS <	cmp	{word}es:[di+2], 'a'					>
SBCS <	cmp	{word}es:[di], 'da'					>
	jne	checkTitle

	call	ProcessDateTag
	jmp	scanString

checkTitle:
DBCS <	cmp	{word}es:[di], 't'					>
DBCS <	jne	checkUserName						>
DBCS <	cmp	{word}es:[di+2], 'i'					>
SBCS <	cmp	{word}es:[di], 'ti'					>
	jne	checkUserName

	call	ProcessTitleTag
	jmp	scanString

checkUserName:
DBCS <	cmp	{word}es:[di], 'u'					>
DBCS <	jne	checkUserAddress					>
DBCS <	cmp	{word}es:[di+2], 'n'					>
SBCS <	cmp	{word}es:[di], 'un'					>
	jne	checkUserAddress

	call	ProcessUserNameTag
	jmp	scanString

checkUserAddress:
DBCS <	cmp	{word}es:[di], 'u'					>
DBCS <	jne	checkUserPhone						>
DBCS <	cmp	{word}es:[di+2], 'a'					>
SBCS <	cmp	{word}es:[di], 'ua'					>
	jne	checkUserPhone

	call	ProcessUserAddressTag
	jmp	scanString

checkUserPhone:
DBCS <	cmp	{word}es:[di], 'u'					>
DBCS <	jne	checkUserEmail						>
DBCS <	cmp	{word}es:[di+2], 'p'					>
SBCS <	cmp	{word}es:[di], 'up'					>
	jne	checkUserEmail

	call	ProcessUserPhoneTag
	jmp	scanString

checkUserEmail:
DBCS <	cmp	{word}es:[di], 'u'					>
DBCS <	jne	checkFinish						>
DBCS <	cmp	{word}es:[di+2], 'e'					>
SBCS <	cmp	{word}es:[di], 'ue'					>
	jne	checkFinish

	call	ProcessUserEmailTag
	jmp	scanString

checkFinish:
DBCS <	cmp	{word}es:[di], 'f'					>
DBCS <	jne	unknownTag						>
DBCS <	cmp	{word}es:[di+2], 'i'					>
SBCS <	cmp	{word}es:[di], 'fi'					>
	jne	unknownTag

	call	ProcessFinishTag
	jmp	scanString

unknownTag:
EC <	WARNING	-1							>
	jmp	scanString

finishedParsing:
	pop	bx
	call	MemFree

	push	si
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	si, offset TemplateWizardUIGroup
	call	ObjCallInstanceNoLock
	pop	si

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GOTO	ObjCallInstanceNoLock

DrawTemplateWizardParseTags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessImageTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process image tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/04/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessImageTag	proc	near
imageFile	local	PathName
	uses	ax,bx,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 'i'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'm'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'im'					>
SBCS <	ERROR_NE -1							>
endif

	; read the image filename into our buffer

	mov	cx, ss
	lea	dx, ss:[imageFile]
	mov	ax, length imageFile
	call	GetDoubleQuoteString	; cx:dx = filename

	; load GIF image

	push	bp
	mov	ax, MSG_DRAW_TEMPLATE_IMAGE_OPEN_IMAGE_FILE
	mov	cx, ss
	lea	dx, ss:[imageFile]
	mov	si, offset TemplateWizardDocumentImage
	call	ObjCallInstanceNoLock
	pop	bp
		
	.leave
	ret
ProcessImageTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessDescriptionTextTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process description text tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/07/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessDescriptionTextTag	proc	near
	uses	ax,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 'd'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'e'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'de'					>
SBCS <	ERROR_NE -1							>
endif

	call	GetDoubleQuoteStringLength
	mov	ax, cx
	jc	done

	sub	sp, ax				; allocate buffer on stack

	movdw	cxdx, sssp
	call	GetDoubleQuoteString		; cx:dx = description text

	; Update description text

	push	ax
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bp, dx
	mov	dx, cx				; dx:bp = description text
	clr	cx				; cx = null terminated
	mov	si, offset TemplateWizardDescriptionText
	call	ObjCallInstanceNoLock
	pop	ax

	add	sp, ax				; return stack space
done:
	.leave
	ret
ProcessDescriptionTextTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessFieldTextTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process field text tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/06/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessFieldTextTag	proc	near
fieldText	local	PathName		; big buffer for text
	uses	ax,bx,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 'f'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'n'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'fn'					>
SBCS <	ERROR_NE -1							>
endif

	mov	cx, ss
	lea	dx, ss:[fieldText]
	mov	ax, length fieldText
	call	GetDoubleQuoteString		; cx:dx = field text

	; Update field text

	push	bp
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_DELAYED_VIA_APP_QUEUE
	mov	si, offset TemplateWizardFieldText
	call	ObjCallInstanceNoLock
	pop	bp

	.leave
	ret
ProcessFieldTextTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessNoFieldTextTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process "no" field text tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/06/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessNoFieldTextTag	proc	near
	uses	ax,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 'n'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'f'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'nf'					>
SBCS <	ERROR_NE -1							>
endif
	LocalNextChar	esdi
	LocalNextChar	esdi

	; Set field text not usable

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	si, offset TemplateWizardFieldText
	call	ObjCallInstanceNoLock

	; Guess we should move the focus to the 'Next' trigger.

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	si, offset TemplateWizardNextTrigger
	call	ObjCallInstanceNoLock

	.leave
	ret
ProcessNoFieldTextTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessFieldTextWidthTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process text width tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/06/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessFieldTextWidthTag	proc	near
textWidth	local	PathName
	uses	ax,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 'f'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'w'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'fw'					>
SBCS <	ERROR_NE -1							>
endif

	mov	cx, ss
	lea	dx, ss:[textWidth]
	mov	ax, length textWidth
	call	GetDoubleQuoteString		; cx:dx = text width

	push	ds
	movdw	dssi, cxdx
	call	UtilAsciiToHex32
	pop	ds
	WARNING_C -1
	jc	done

	; Update field text width

	mov	dx, ax

	mov	ax, HINT_FIXED_SIZE
	mov	si, offset TemplateWizardFieldText
	call	ObjVarFindData
	jc	setWidth

	mov	cx, size GadgetSizeHintArgs
	call	ObjVarAddData

setWidth:
	ornf	dx, SpecWidth <SST_AVG_CHAR_WIDTHS, 0>
	mov	ds:[bx].GSHA_width, dx
done:
	.leave
	ret
ProcessFieldTextWidthTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessTextHeightTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process text height tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/06/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessFieldTextHeightTag	proc	near
textHeight	local	PathName
	uses	ax,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 'f'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'h'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'fh'					>
SBCS <	ERROR_NE -1							>
endif
	mov	cx, ss
	lea	dx, ss:[textHeight]
	mov	ax, length textHeight
	call	GetDoubleQuoteString		; cx:dx = text height

	push	ds
	movdw	dssi, cxdx
	call	UtilAsciiToHex32
	pop	ds
	WARNING_C -1
	jc	done

	; Update field text height

	mov	dx, ax
	cmp	dx, 1
	jle	done

	mov	ax, HINT_FIXED_SIZE
	mov	si, offset TemplateWizardFieldText
	call	ObjVarFindData
	jc	setHeight

	mov	cx, size GadgetSizeHintArgs
	call	ObjVarAddData

setHeight:
	ornf	dx, SpecHeight <SST_LINES_OF_TEXT, 0>
	mov	ds:[bx].GSHA_height, dx

	mov	ax, MSG_GEN_TEXT_SET_ATTRS	; multi-line, init-scrolling
	mov	cx, mask GTA_SINGLE_LINE_TEXT shl 8 or mask GTA_INIT_SCROLLING
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
ProcessFieldTextHeightTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessDateTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process date tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/06/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessDateTag	proc	near
dateTimeBuffer	local	DATE_TIME_BUFFER_SIZE dup (Chars)
	class	DrawTemplateWizardClass
	uses	ax,bx,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 'd'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'a'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'da'					>
SBCS <	ERROR_NE -1							>
endif
	LocalNextChar	esdi
	LocalNextChar	esdi

	mov	si, ds:[si]
	add	si, ds:[si].DrawTemplateWizard_offset
	mov	ds:[si].DTWI_dataType, DTWDT_DATE

	push	es, di
	segmov	es, ss
	lea	di, ss:[dateTimeBuffer]

	call	TimerGetDateAndTime

	push	ax, bx, cx
	mov	si, DTF_LONG
	call	LocalFormatDateTime
	mov	si, offset TemplateWizardDateLong
	call	setDateVisMoniker
	pop	ax, bx, cx

	push	ax, bx, cx
	mov	si, DTF_LONG_NO_WEEKDAY
	call	LocalFormatDateTime
	mov	si, offset TemplateWizardDateLongNoWeekday
	call	setDateVisMoniker
	pop	ax, bx, cx

	push	ax, bx, cx
	mov	si, DTF_LONG_NO_WEEKDAY_CONDENSED
	call	LocalFormatDateTime
	mov	si, offset TemplateWizardDateLongNoWeekdayCondensed
	call	setDateVisMoniker
	pop	ax, bx, cx

	mov	si, DTF_SHORT
	call	LocalFormatDateTime
	mov	si, offset TemplateWizardDateShort
	call	setDateVisMoniker

	push	bp
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset TemplateWizardDateGroup
	call	ObjCallInstanceNoLock	
	cmp	ax, DTF_END_DATE_FORMATS
	je	usable			; skip apply if user entered text

	mov	ax, MSG_GEN_APPLY
	call	ObjCallInstanceNoLock
usable:
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjCallInstanceNoLock
	pop	bp
	pop	es, di

	.leave
	ret

setDateVisMoniker:
	push	bp
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	cx, ss
	lea	dx, ss:[dateTimeBuffer]
	mov	bp, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjCallInstanceNoLock
	pop	bp
	retn

ProcessDateTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessTitleTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process title tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/06/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessTitleTag	proc	near
titleText	local	PathName		; big buffer for text
	uses	ax,bx,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 't'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'i'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'ti'					>
SBCS <	ERROR_NE -1							>
endif

	mov	cx, ss
	lea	dx, ss:[titleText]
	mov	ax, length titleText
	call	GetDoubleQuoteString		; cx:dx = title text

	; Update title text

	push	bp
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_DELAYED_VIA_APP_QUEUE
	mov	si, offset TemplateWizardDialog
	call	ObjCallInstanceNoLock
	pop	bp

	.leave
	ret
ProcessTitleTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessUserNameTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process user name tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/17/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

userinfoCategory	char	USER_INFO_CATEGORY,0
userinfoNameKey		char	USER_INFO_NAME_KEY,0
userinfoAddressKey	char	USER_INFO_ADDRESS_KEY,0
userinfoPhoneKey	char	USER_INFO_HOME_PHONE_KEY,0
userinfoEmailKey	char	USER_INFO_EMAIL_ADDRESS_KEY,0

ProcessUserNameTag	proc	near
	class	DrawTemplateWizardClass
	uses	ax,bx,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 'u'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'n'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'un'					>
SBCS <	ERROR_NE -1							>
endif
	LocalNextChar	esdi
	LocalNextChar	esdi

	mov	si, ds:[si]
	add	si, ds:[si].DrawTemplateWizard_offset
	mov	ds:[si].DTWI_dataType, DTWDT_USER_NAME

	push	ds
	mov	cx, cs
	mov	dx, offset userinfoNameKey
	mov	ds, cx
	mov	si, offset userinfoCategory
	clr	bp
	call	InitFileReadData	; bx = data block
	pop	ds
	jc	done

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_BLOCK
	mov	dx, bx
	clr	cx
	mov	si, offset TemplateWizardFieldText
	call	ObjCallInstanceNoLock

	call	MemFree
done:
	.leave
	ret
ProcessUserNameTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessUserAddressTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process user address tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/17/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessUserAddressTag	proc	near
	class	DrawTemplateWizardClass
	uses	ax,bx,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 'u'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'a'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'ua'					>
SBCS <	ERROR_NE -1							>
endif
	LocalNextChar	esdi
	LocalNextChar	esdi

	mov	si, ds:[si]
	add	si, ds:[si].DrawTemplateWizard_offset
	mov	ds:[si].DTWI_dataType, DTWDT_USER_ADDRESS

	push	ds
	mov	cx, cs
	mov	dx, offset userinfoAddressKey
	mov	ds, cx
	mov	si, offset userinfoCategory
	clr	bp
	call	InitFileReadData	; bx = data block
	pop	ds
	jc	done

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_BLOCK
	mov	dx, bx
	clr	cx
	mov	si, offset TemplateWizardFieldText
	call	ObjCallInstanceNoLock

	call	MemFree
done:
	.leave
	ret
ProcessUserAddressTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessUserPhoneTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process user name tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/17/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessUserPhoneTag	proc	near
	class	DrawTemplateWizardClass
	uses	ax,bx,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 'u'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'p'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'up'					>
SBCS <	ERROR_NE -1							>
endif
	LocalNextChar	esdi
	LocalNextChar	esdi

	mov	si, ds:[si]
	add	si, ds:[si].DrawTemplateWizard_offset
	mov	ds:[si].DTWI_dataType, DTWDT_USER_PHONE

	push	ds
	mov	cx, cs
	mov	dx, offset userinfoPhoneKey
	mov	ds, cx
	mov	si, offset userinfoCategory
	clr	bp
	call	InitFileReadData	; bx = data block
	pop	ds
	jc	done

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_BLOCK
	mov	dx, bx
	clr	cx
	mov	si, offset TemplateWizardFieldText
	call	ObjCallInstanceNoLock

	call	MemFree
done:
	.leave
	ret
ProcessUserPhoneTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessUserEmailTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process user email tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/17/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessUserEmailTag	proc	near
	class	DrawTemplateWizardClass
	uses	ax,bx,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 'u'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'e'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'ue'					>
SBCS <	ERROR_NE -1							>
endif
	LocalNextChar	esdi
	LocalNextChar	esdi

	mov	si, ds:[si]
	add	si, ds:[si].DrawTemplateWizard_offset
	mov	ds:[si].DTWI_dataType, DTWDT_USER_EMAIL

	push	ds
	mov	cx, cs
	mov	dx, offset userinfoEmailKey
	mov	ds, cx
	mov	si, offset userinfoCategory
	clr	bp
	call	InitFileReadData	; bx = data block
	pop	ds
	jc	done

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_BLOCK
	mov	dx, bx
	clr	cx
	mov	si, offset TemplateWizardFieldText
	call	ObjCallInstanceNoLock

	call	MemFree
done:
	.leave
	ret
ProcessUserEmailTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessFinishTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process finish tag

CALLED BY:	DrawTemplateWizardParseTags
PASS:		*ds:si	= DrawTemplateWizardClass object
		es:di	= tag text
RETURN:		es:di	= char after end of tag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/17/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessFinishTag	proc	near
	class	DrawTemplateWizardClass
	uses	ax,bx,cx,dx,si,bp
	.enter

if ERROR_CHECK
DBCS <	cmp	{word}es:[di], 'f'					>
DBCS <	ERROR_NE -1							>
DBCS <	cmp	{word}es:[di+2], 'i'					>
DBCS <	ERROR_NE -1							>
SBCS <	cmp	{word}es:[di], 'fi'					>
SBCS <	ERROR_NE -1							>
endif
	LocalNextChar	esdi
	LocalNextChar	esdi

	mov	si, ds:[si]
	add	si, ds:[si].DrawTemplateWizard_offset
	ornf	ds:[si].DTWI_state, mask DTWS_FINISHED

	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	cx, offset TemplateWizardFinishMoniker
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	si, offset TemplateWizardNextTrigger
	call	ObjCallInstanceNoLock

	.leave
	ret
ProcessFinishTag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDoubleQuoteString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get string inside double quote (and null terminate it).

CALLED BY:	INTERNAL
PASS:		es:di	= text string
		cx:dx	= buffer to store double quote string (without quotes)
		ax	= length of buffer
RETURN:		es:di	= text following double quote string
		cx:dx	= buffer filled with double quote string
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/04/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDoubleQuoteString	proc	near
	uses	ax,cx,dx,si,ds,es
	.enter

	segmov	ds, es
	mov	si, di			; ds:si = text string
	movdw	esdi, cxdx		; es:di = buffer for dbl quote string
	mov	cx, ax			; cx = length of buffer

findQuote:
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, C_QUOTE
	je	copyString
	LocalCmpChar	ax, C_NULL
	jne	findQuote
	stc				; error
	jmp	done

copyString:
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, C_BACKSLASH
	je	copyNextChar
	LocalCmpChar	ax, C_QUOTE
	je	endString
	LocalCmpChar	ax, C_NULL
	jne	copyChar
	stc				; error
	jmp	done

copyNextChar:
	LocalGetChar	ax, dssi
SBCS <	LocalCmpChar	ax, C_SMALL_R					>
DBCS <	LocalCmpChar	ax, C_LATIN_SMALL_LETTER_R			>
	jne	copyChar
	mov	ax, C_CR
copyChar:
	LocalPutChar	esdi, ax
	dec	cx
	jnz	copyString
	stc				; error
	jmp	done

endString:
	mov	ax, C_NULL
	LocalPutChar	esdi, ax
	mov	di, si			; di = text following dbl quote string
	clc				; no errors
done:
	.leave
	ret
GetDoubleQuoteString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDoubleQuoteStringLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get length of string inside double quote (including null)

CALLED BY:	INTERNAL
PASS:		es:di	= text string
RETURN:		cx	= length of double quote string including null
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/17/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDoubleQuoteStringLength	proc	near
	uses	ax,si,ds
	.enter

	segmov	ds, es
	mov	si, di			; ds:si = text string
	clr	cx

findQuote:
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, C_QUOTE
	je	countString
	LocalCmpChar	ax, C_NULL
	jne	findQuote
	stc				; error
	jmp	done

countString:
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, C_BACKSLASH
	je	countNextChar
	LocalCmpChar	ax, C_NULL
	jne	countChar
error:
	stc				; error
	jmp	done

countNextChar:
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, C_NULL	; verify next character is not NULL
	je	error
	LocalLoadChar	ax, C_SPACE	; ensure we don't stop counting just
					; because the character after a
					; backslash is a quote -Don 1/25/00
countChar:
	inc	cx
	LocalCmpChar	ax, C_QUOTE
	jne	countString
done:
	.leave
	ret
GetDoubleQuoteStringLength	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocSearchReplaceStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate SearchReplaceStruct block

CALLED BY:	INTERNAL
PASS:		*ds:si	= SRS_replyObject
		ax	= size of SRS_replaceString (0 if just searching)
		dl	= SearchOptions
RETURN:		bx	= ^hSearchReplaceStruct (not locked)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/06/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

templateWizardSearchString	Chars	\
    C_GUILLEDBLLEFT, WC_MATCH_MULTIPLE_CHARS, WC_MATCH_MULTIPLE_CHARS,
    C_GUILLEDBLRIGHT, C_NULL

AllocSearchReplaceStructBlock	proc	near
	uses	ax,cx,si,di,ds,es
	.enter

	add	ax, (size SearchReplaceStruct) + \
		    (size templateWizardSearchString)
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	es, ax
	mov	es:[SRS_searchSize], length templateWizardSearchString
	mov	es:[SRS_replaceSize], 0
	mov	es:[SRS_params], dl
	mov	di, ds:[LMBH_handle]
	movdw	es:[SRS_replyObject], disi
	mov	es:[SRS_replyMsg], MSG_DRAW_TEMPLATE_WIZARD_TAG_NOT_FOUND
	segmov	ds, cs
	mov	si, offset templateWizardSearchString
	mov	di, offset SRS_searchString
	mov	cx, size templateWizardSearchString
	rep	movsb
	call	MemUnlock

	.leave
	ret
AllocSearchReplaceStructBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateImageVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the background for the template wizard

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= DrawTemplateWizardClass object
		ds:di	= DrawTemplateWizardClass instance data
		ds:bx	= DrawTemplateWizardClass object (same as *ds:si)
		es 	= segment of DrawTemplateWizardClass
		ax	= message #
		cl	= DrawFlags
		^hbp	= GState
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/02/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateWizardVisDraw	method dynamic DrawTemplateWizardClass, 
					MSG_VIS_DRAW
	;
	; Draw the background at the top of the screen
	;
		push	ax, cx, bp
		mov	ax, 26 or (CF_RGB shl 8)
		mov	bx, 26 or (114 shl 8)
		mov	di, bp
		call	GrSetAreaColor
		call	VisGetBounds
		mov	dx, 81+5		; height of bitmap + border
		call	GrFillRect
	;
	; Call our superclass to finish stuff up
	;
		pop	ax, cx, bp
		mov	di ,offset DrawTemplateWizardClass
		GOTO	ObjCallSuperNoLock
DrawTemplateWizardVisDraw	endm


;===========================================================================
;		DrawTemplateImageClass
;===========================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateImageSetImagePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the path where we will find the images

CALLED BY:	MSG_DRAW_TEMPLATE_IMAGE_SET_IMAGE_PATH

PASS:		*ds:si	= DrawTemplateImageClass object
		ds:di	= DrawTemplateImageClass instance data
		ds:bx	= DrawTemplateImageClass object (same as *ds:si)
		es 	= segment of DrawTemplateImageClass
		ax	= message #
		cx:dx	= fptr to path buffer
		bp	= disk handle
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/02/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateImageSetImagePath	method dynamic DrawTemplateImageClass, 
				MSG_DRAW_TEMPLATE_IMAGE_SET_IMAGE_PATH
		.enter
	;
	; Just copy the data in
	;
		mov	ds:[di].DTI_pathDisk, bp
		segmov	es, ds, ax
		add	di, offset DTI_pathBuffer
		movdw	dssi, cxdx
		mov	cx, (size DTI_pathBuffer)
		rep	movsb

		.leave
		ret
DrawTemplateImageSetImagePath	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateImageOpenImageFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open template image file

CALLED BY:	MSG_DRAW_TEMPLATE_IMAGE_OPEN_IMAGE_FILE

PASS:		*ds:si	= DrawTemplateImageClass object
		ds:di	= DrawTemplateImageClass instance data
		ds:bx	= DrawTemplateImageClass object (same as *ds:si)
		es 	= segment of DrawTemplateImageClass
		ax	= message #
		cx:dx	= fptr to image file name
RETURN:		carry set if error
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/02/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateImageOpenImageFile	method dynamic DrawTemplateImageClass, 
				MSG_DRAW_TEMPLATE_IMAGE_OPEN_IMAGE_FILE
	call	FilePushDir
		
	push	cx, dx
	mov	bx, ds:[di].DTI_pathDisk
	lea	dx, ds:[di].DTI_pathBuffer	; path => DS:DX
	call	FileSetCurrentPath
		
	mov	ax, MSG_DRAW_TEMPLATE_IMAGE_CLOSE_IMAGE_FILE
	call	ObjCallInstanceNoLock
	pop	cx, dx
		
	push	ds
	mov	ds, cx
	mov	al, FILE_ACCESS_R or FILE_DENY_W
	call	FileOpen
	mov	bx, ax			; bx <- file handle
	pop	ds
	WARNING_C -1	
	jc	done

	push	bx
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	ConvertGifToBitmap
	jc	closeFile

	push	ds
	movdw	bxax, cxdx
	call	VMLock
	mov	ds, ax
	mov	ax, ds:[HugeArrayDirectory].B_width
	mov	bx, ds:[HugeArrayDirectory].B_height
	call	VMUnlock
	pop	ds

	mov	di, ds:[si]
	add	di, ds:[di].DrawTemplateImage_offset
	movdw	ds:[di].DTI_bitmap, cxdx
	movdw	ds:[di].DTI_bitmapSize, bxax

	push	ax
	mov	ax, MSG_VIS_GET_SIZE
	call	ObjCallInstanceNoLock
	pop	ax

	cmpdw	axbx, cxdx
	jne	resize

	mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
	call	ObjCallInstanceNoLock
	jmp	closeFile

resize:
	mov	ax, MSG_VIS_MARK_INVALID
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjCallInstanceNoLock

closeFile:
	pop	bx
	clr	ax
	call	FileClose
done:
	call	FilePopDir
	ret
DrawTemplateImageOpenImageFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateImageCloseImageFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close template image file

CALLED BY:	MSG_DRAW_TEMPLATE_IMAGE_CLOSE_IMAGE_FILE

PASS:		*ds:si	= DrawTemplateImageClass object
		ds:di	= DrawTemplateImageClass instance data
		ds:bx	= DrawTemplateImageClass object (same as *ds:si)
		es 	= segment of DrawTemplateImageClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/02/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateImageCloseImageFile method dynamic DrawTemplateImageClass, 
				MSG_DRAW_TEMPLATE_IMAGE_CLOSE_IMAGE_FILE
	clrdw	bxax
	xchgdw	bxax, ds:[di].DTI_bitmap
	tst	bx
	jz	done
	clr	bp
	call	VMFreeVMChain
done:
	ret
DrawTemplateImageCloseImageFile endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateImageRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalc size

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		*ds:si	= DrawTemplateImageClass object
		ds:di	= DrawTemplateImageClass instance data
		ds:bx	= DrawTemplateImageClass object (same as *ds:si)
		es 	= segment of DrawTemplateImageClass
		ax	= message #
		cx	= RecalcSizeArgs -- suggested width for object
		dx	= RecalcSizeArgs -- suggested height
RETURN:		cx	= width to use
		dx	= height to use
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/04/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateImageRecalcSize	method dynamic DrawTemplateImageClass, 
					MSG_VIS_RECALC_SIZE
	mov	cx, ds:[di].DTI_bitmapSize.P_x
	mov	dx, ds:[di].DTI_bitmapSize.P_y
	ret
DrawTemplateImageRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateImageVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw template image (thumbnail)

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= DrawTemplateImageClass object
		ds:di	= DrawTemplateImageClass instance data
		ds:bx	= DrawTemplateImageClass object (same as *ds:si)
		es 	= segment of DrawTemplateImageClass
		ax	= message #
		cl	= DrawFlags
		^hbp	= GState
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/02/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateImageVisDraw	method dynamic DrawTemplateImageClass, 
					MSG_VIS_DRAW
	movdw	dxcx, ds:[di].DTI_bitmap
	tst	dx
	jz	done

	push	cx, dx
	call	VisGetBounds
	pop	cx, dx

	mov	di, bp
	call	GrDrawHugeBitmap
done:		
	ret
DrawTemplateImageVisDraw	endm

;===========================================================================
;		DrawTemplateFieldTextClass
;===========================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTemplateFieldTextSetModifiedState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set modified state

CALLED BY:	MSG_GEN_TEXT_SET_MODIFIED_STATE

PASS:		*ds:si	= DrawTemplateFieldTextClass object
		ds:di	= DrawTemplateFieldTextClass instance data
		ds:bx	= DrawTemplateFieldTextClass object (same as *ds:si)
		es 	= segment of DrawTemplateFieldTextClass
		ax	= message #
		cx	= non-zero to mark modified, zero to mark not modified
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/16/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTemplateFieldTextSetModifiedState	method dynamic \
		DrawTemplateFieldTextClass, MSG_GEN_TEXT_SET_MODIFIED_STATE
	push	cx
	mov	di, offset DrawTemplateFieldTextClass
	call	ObjCallSuperNoLock
	pop	cx
	jcxz	done

	clr	ax
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	al, ds:[di].GTXI_stateFlags
	mov	bp, ax

	mov	ax, MSG_DRAW_TEMPLATE_WIZARD_FIELD_TEXT_STATUS
	mov	si, offset TemplateWizardDialog
	GOTO	ObjCallInstanceNoLock
done:
	ret
DrawTemplateFieldTextSetModifiedState	endm		

DocOpenClose	ends
