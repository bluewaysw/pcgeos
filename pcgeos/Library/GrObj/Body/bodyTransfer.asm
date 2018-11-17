COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj/Body
FILE:		bodyTransfer.asm

AUTHOR:		jon

METHODS:
	Name		
	----	
	GrObjBodyImport
	GrObjBodyExport

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/12/89		from Text/TextTrans/ttCreate.asm
	jon	may 1992	imported for grobj

DESCRIPTION:
	Transfer item creation stuff

	$Id: bodyTransfer.asm,v 1.2 98/03/24 21:44:59 gene Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyNotifyNormalTransferItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for
		MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED

Called by:	

Pass:		*ds:si = GrObjBody object

Return:		nothing

Destroyed:	ax, cx, dx, bp

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	23 dec 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyNotifyNormalTransferItemChanged	method dynamic	GrObjBodyClass,
			MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
	.enter

	;
	;  Give it to the edit grab if any
	;
	mov	di, mask MF_FIXUP_DS
	call	GrObjBodyMessageToEdit
	jnz	done

	call	GrObjBodyUpdateEditController

done:
	.leave
	ret
GrObjBodyNotifyNormalTransferItemChanged	endm

GrObjInitCode	ends

GrObjTransferCode segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateGrObjTransferFormatHeader

DESCRIPTION:	Create a transfer format header

CALLED BY:	INTERNAL

PASS:
	bx - vm file
	*ds:si - GrObjBody

RETURN:
	ax - vm block handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/29/91		Initial version

------------------------------------------------------------------------------@
CreateGrObjTransferFormatHeader	proc	near
				uses cx, dx, si, di, bp, es
	.enter

	;  total size = (size GrObjTransferBlockHeader) +
	;			((size dword) * #grobjs)
	;

	call	GrObjBodyGetNumCopyableGrObjs
	mov	bp, cx				;bp <- # selected
	shl	cx				
	shl	cx				
	add	cx, size GrObjTransferBlockHeader
	clr	ax				;no user id
	call	VMAlloc
	push	ax				;save block handle
	push	bp				;save # selected
	call	VMLock
	call	VMDirty
	mov	es, ax

	; zero out block and setup VMChain header

	clr	ax, di
	mov	cx, (size GrObjTransferBlockHeader) / 2
	rep stosw
	mov	es:[VMCT_meta].VMCL_next, VM_CHAIN_TREE
	mov	es:[VMCT_offset], offset GOTBH_areaAttrArray
	pop	es:[VMCT_count]			;= # selected
	add	es:[VMCT_count], ((size GrObjTransferBlockHeader) - \
				(offset GOTBH_areaAttrArray)) / (size dword)
	
	;    Store dimensions of selected objects in header
	;

	push	bp				;memory handle
	sub	sp,size RectDWord
	mov	bp,sp
	call	GrObjBodyGetBoundsOfSelectedGrObjs
	movdw	dxcx,ss:[bp].RD_right
	subdw	dxcx,ss:[bp].RD_left
	movdw	es:[GOTBH_size.PD_x],dxcx
	movdw	dxcx,ss:[bp].RD_bottom
	subdw	dxcx,ss:[bp].RD_top
	movdw	es:[GOTBH_size.PD_y],dxcx
	add	sp,size RectDWord
	pop	bp				;memory handle

	call	VMDirty
	call	VMUnlock

	pop	ax				;vm block handle

	.leave
	ret

CreateGrObjTransferFormatHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetNumCopyableGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns the number of copyable grobjs in the selection list

Pass:		*ds:si - GrObjBody

Return:		cx - number of copyable grobjs in the selection list

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 30, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetNumCopyableGrObjs	proc	near
	uses	ax, bx, di
	.enter

	mov	ax, MSG_GO_INC_CX_IF_COPYABLE
	clr	bx, cx
	mov	di,OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GrObjBodyProcessSelectedGrObjsCommon

	.leave
	ret
GrObjBodyGetNumCopyableGrObjs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CreateGrObjTransferStyleArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Allocates space for the xfer style arrays

Pass:		bx - vm file
		ax - vm block handle containing GrObjTransferBlockHeader

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateGrObjTransferStyleArrays	proc	near
	uses	ax, bp, es
	.enter

	call	VMLock
	call	VMDirty
	mov	es, ax

	call	CreateStyleArray
	mov	es:[GOTBH_styleArray].high, ax
	
	call	CreateAttrArray
	mov	es:[GOTBH_areaAttrArray].high, ax

	call	CreateAttrArray
	mov	es:[GOTBH_lineAttrArray].high, ax

	clr	ax
	clrdw	es:[GOTBH_charAttrRuns], ax
	clrdw	es:[GOTBH_paraAttrRuns], ax
	clrdw	es:[GOTBH_textStyleArray], ax
	clrdw	es:[GOTBH_textGraphicElements], ax

	call	MakeTransferFormatNotLMem

	call	VMDirty
	call	VMUnlock

	.leave
	ret
CreateGrObjTransferStyleArrays	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SetupGTP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Fills in the GrObjTransferParams necessary for cut/copy/paste

Pass:		bx - vm file
		ax - vm block handle containing GrObjTransferBlockHeader

		ss:bp - empty GrObjTransferParams

Return:		ss:bp - GrObjTransferParams with the following slots filled:
			GTP_ssp
			GTP_optBlock (cleared)
			GTP_textSSP.VTSSSP_treeBlock (= passed ax)
			GTP_curSlot

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupGTP	proc	far
	uses	ax, bx, cx, di, es
	.enter

	mov	ss:[bp].GTP_textSSP.VTSSSP_treeBlock, ax
	mov	ss:[bp].GTP_textSSP.VTSSSP_graphicTreeOffset,
						offset GOTBH_textGraphicsTree

	call	GrObjBodyLoadSSParams
	mov	di, bp					;ss:di <- SSP
	call	VMLock
	mov	es, ax

	xchg	di, bp					;ss:bp <- SSP
							;di <- mem handle

	mov	ss:[bp].GTP_curSlot, size GrObjTransferBlockHeader
	mov	ss:[bp].GTP_vmFile, bx

	mov	cx, VM_ELEMENT_ARRAY_CHUNK

	mov	ax, es:[GOTBH_styleArray].high
	mov	ss:[bp].GTP_ssp.SSP_xferStyleArray.SCD_vmBlockOrMemHandle, ax
	mov	ss:[bp].GTP_ssp.SSP_xferStyleArray.SCD_vmFile, bx
	mov	ss:[bp].GTP_ssp.SSP_xferStyleArray.SCD_chunk, cx
	
	mov	ax, es:[GOTBH_areaAttrArray].high
	mov	ss:[bp].GTP_ssp.SSP_xferAttrArrays[0].SCD_vmBlockOrMemHandle, ax
	mov	ss:[bp].GTP_ssp.SSP_xferAttrArrays[0].SCD_vmFile, bx
	mov	ss:[bp].GTP_ssp.SSP_xferAttrArrays[0].SCD_chunk, cx

	mov	ax, es:[GOTBH_lineAttrArray].high
	mov	ss:[bp].GTP_ssp.SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_vmBlockOrMemHandle, ax
	mov	ss:[bp].GTP_ssp.SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_vmFile, bx
	mov	ss:[bp].GTP_ssp.SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_chunk, cx

	;
	;  Now the text stuff
	;
	mov	ax, es:[GOTBH_textStyleArray].high
	mov	ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferStyleArray.SCD_vmBlockOrMemHandle, ax
	mov	ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferStyleArray.SCD_vmFile, bx
	mov	ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferStyleArray.SCD_chunk, cx
	
	mov	ax, es:[GOTBH_charAttrRuns].high
	mov	ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferAttrArrays[0].SCD_vmBlockOrMemHandle, ax
	mov	ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferAttrArrays[0].SCD_vmFile, bx
	mov	ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferAttrArrays[0].SCD_chunk, cx

	mov	ax, es:[GOTBH_paraAttrRuns].high
	mov	ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_vmBlockOrMemHandle, ax
	mov	ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_vmFile, bx
	mov	ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_chunk, cx

	mov	ax, es:[GOTBH_textGraphicElements].high
	mov	ss:[bp].GTP_textSSP.VTSSSP_graphicsElements, ax

	clr	ss:[bp].GTP_optBlock

	xchg	bp, di					;bp <- mem handle
							;ss:di <- SSP
	call	VMUnlock

	mov	bp, di					;ss:[bp] <- SSP
	

	.leave
	ret
SetupGTP	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyLoadSSParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Copies the StyleSheetParams for both GrObj and Text into
		the stack frame

Pass:		ss:[bp] - GrObjTransferParams with empty GTP_ssp
			  and GTP_textSSP

Return:		ss:[bp] - filled StyleSheetParams

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyLoadSSParams	proc	near
	uses	ax, cx, di
	.enter

	clr	cx					;fill in xfer stuff
	mov	ax, MSG_GOAM_LOAD_STYLE_SHEET_PARAMS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyMessageToGOAM

	add	bp, offset GTP_textSSP
	clr	cx					;fill in xfer stuff
	mov	ax, MSG_VIS_TEXT_LOAD_STYLE_SHEET_PARAMS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyMessageToGOAMText
	sub	bp, offset GTP_textSSP

	.leave
	ret
GrObjBodyLoadSSParams	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CreateAttrArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Allocates a block in the VM override file to store
		an attribute array.

Pass:		bx - VM file
		ax - element size (eg. size FullAreaAttrArray)

Return:		ax - block handle of attr array

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 10, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAttrArray	proc	near
	uses	bx, cx, bp, si, ds
	.enter

;	push	ax				;save element size
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx				;default header size
	call	VMAllocLMem			;ax <- block handle
;	pop	cx				;cx <- element size
	push	ax				;save block handle
	call	VMLock
	mov	ds, ax
	mov	al, mask OCF_DIRTY
;	mov	bx, cx				;bx <- element size
	clr	bx, cx, si			;default header, alloc chunk
	call	ElementArrayCreate
	call	VMUnlock
	pop	ax				;ax <- block handle
	.leave
	ret
CreateAttrArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CreateStyleArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Allocates a block in the VM override file to store
		a style array.

Pass:		bx - vm file

Return:		ax - block handle of style array

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 10, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateStyleArray	proc	near
	uses	bx, cx, bp, si, ds
	.enter

	mov	ax, LMEM_TYPE_GENERAL
	clr	cx				;default header size
	call	VMAllocLMem			;ax <- block handle
	push	ax				;save block handle
	call	VMLock
	call	VMDirty
	mov	ds, ax
	mov	al, mask OCF_DIRTY
	mov	bx, size GrObjStyleElement - size NameArrayElement
	clr	si				;alloc handle
	call	NameArrayCreate
	call	VMDirty
	call	VMUnlock
	pop	ax				;ax <- block handle
	.leave
	ret
CreateStyleArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyCreateGrObjTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_CREATE_GROBJ_TRANSFER_FORMAT

	Creates a VMChain necessary to recontruct the current selection

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance
		ss:bp - origin for generated transfer item

			- or -

			bp = 0 to use stored 

		cx - vm file

Return:		ax - new vm block handle

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateGrObjTransferFormat	method dynamic	GrObjBodyClass,
					MSG_GB_CREATE_GROBJ_TRANSFER_FORMAT
	uses	cx,dx,bp
	.enter

	mov	bx, cx					;bx <- vm file
	mov	dx, bp					;ss:dx <- origin

	call	CreateGrObjTransferFormatHeader
	push	ax					;save block handle

	call	CreateGrObjTransferStyleArrays
	sub	sp, size GrObjTransferParams
	mov	bp, sp
	call	SetupGTP

	;
	;  Copy the center of the selection so the grobjs can
	;  use it as their origin
	;
	push	ds, si,es			;body
	mov	cx, ss
	mov	ds, cx
	mov	es, cx
	mov	si, dx
	lea	di, ss:[bp].GTP_selectionCenterDOCUMENT
	mov	cx, size PointDWFixed / 2
	rep movsw
	pop	ds,si,es			;body

	;
	;	Have each selected grobj allocate its own block
	;	and add it into the list
	;
	mov	ax, MSG_GO_CREATE_TRANSFER
	clr	bx
	mov	di,OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GrObjBodyProcessSelectedGrObjsCommon

	mov	bx, ss:[bp].GTP_optBlock
	tst	bx
	jz	checkText
	call	MemFree
checkText:
	;
	;  Check to see if any text objects allocated xfer style arrays,
	;  and if so, save them to our transfer header.
	;
	mov	cx, ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferStyleArray.SCD_vmBlockOrMemHandle
	jcxz	freeFrame

	mov	bx, ss:[bp].GTP_vmFile
	mov	dx, ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferAttrArrays[0].SCD_vmBlockOrMemHandle
	mov	di, ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_vmBlockOrMemHandle
	mov	bp, ss:[bp].GTP_textSSP.VTSSSP_graphicsElements

	add	sp, size GrObjTransferParams
	pop	ax					;ax <- transfer header
							;      block
	push	ax
	push	bp
	call	VMLock
	call	VMDirty
	mov	es, ax
	pop	es:[GOTBH_textGraphicElements].high
	mov	es:[GOTBH_textStyleArray].high, cx
	mov	es:[GOTBH_charAttrRuns].high, dx
	mov	es:[GOTBH_paraAttrRuns].high, di

	call	MakeTransferFormatNotLMem

	call	VMDirty
	call	VMUnlock
	jmp	popAxDone

freeFrame:	
	add	sp, size GrObjTransferParams
popAxDone:
	pop	ax					;ax <- VM block handle
	.leave
	ret
GrObjBodyCreateGrObjTransferFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateGStringTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_CREATE_GSTRING_TRANSFER_FORMAT

	Creates a VMChain necessary to recontruct the current selection

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance
		ss:bp - origin for generated transfer item

		cx - VM file

Return:		ax - new vm block handle or 0 if no chain created
		cx,dx - width, height of gstring

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateGStringTransferFormat	method dynamic	GrObjBodyClass,
					MSG_GB_CREATE_GSTRING_TRANSFER_FORMAT

	uses	bp

	.enter

	;    Create gstring in vm file
	;

	mov	bx, cx
	mov_tr	ax,si					;body chunk
	mov	cl, GST_VMEM
	call	GrCreateGString
	push	si					;vm block handle
	mov_tr	si,ax					;body chunk

	;
	;  Set the bounds explicitly
	;

	mov	bx, bp					;ss:bx <- origin
	sub	sp, size RectDWFixed
	mov	bp, sp
	mov	ax, MSG_GB_GET_DWF_BOUNDS_OF_SELECTED_GROBJS
	call	ObjCallInstanceNoLock
	xchg	bx, bp					;ss:bx <- bounds
							;ss:bp <- origin
	subdwf	ss:[bx].RDWF_right, ss:[bp].PDF_x, ax
	rnddwf	ss:[bx].RDWF_right
	subdwf	ss:[bx].RDWF_left, ss:[bp].PDF_x, ax
	rnddwf	ss:[bx].RDWF_left
	subdwf	ss:[bx].RDWF_bottom, ss:[bp].PDF_y, ax
	rnddwf	ss:[bx].RDWF_bottom
	subdwf	ss:[bx].RDWF_top, ss:[bp].PDF_y, ax
	rnddwf	ss:[bx].RDWF_top

	mov	ax, ss:[bx].RDWF_left.DWF_int.low
	mov	cx, ss:[bx].RDWF_right.DWF_int.low
	mov	dx, ss:[bx].RDWF_bottom.DWF_int.low
	mov	bx, ss:[bx].RDWF_top.DWF_int.low
	add	sp, size RectDWFixed
	call	GrSetGStringBounds

	clr	ax
	negdwf	ss:[bp].PDF_x, ax
	negdwf	ss:[bp].PDF_y, ax

	;
	;  Do the big jump
	;
	movdw	dxcx, ss:[bp].PDF_x.DWF_int
	movdw	bxax, ss:[bp].PDF_y.DWF_int
	call	GrApplyTranslationDWord

	;
	;  And then the small one
	;
	mov	cx, ss:[bp].PDF_x.DWF_frac
	mov	ax, ss:[bp].PDF_y.DWF_frac
	clr	dx, bx
	negdwf	ss:[bp].PDF_x, dx			;restore the passed
	negdwf	ss:[bp].PDF_y, dx			;point to original val
	call	GrApplyTranslation

	;    Draw children in gstring
	;    Tell objects we are printing so that text objects
	;    and friends won't draw their selections
	;
	
	call	GrObjBodySetGrObjDrawFlagsForDraw

	ornf	dx, mask GODF_DRAW_OBJECTS_ONLY or \
			mask GODF_DRAW_SELECTED_OBJECTS_ONLY or \
			mask GODF_DRAW_WITH_INCREASED_RESOLUTION
	BitClr	dx, GODF_DRAW_QUICK_VIEW
	mov	cl,mask DF_PRINT
	mov	bp,di					;gstate
	mov	ax,MSG_GB_DRAW
	call	ObjCallInstanceNoLock

	call	GrEndGString

	mov	si, di					;si <- gstring
	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos

	clr	di, dx					;0 gstate, end cond.
	call	GrGetGStringBounds
	jc	badBounds
	sub	dx, bx					;dx <- height
	sub	cx, ax					;cx <- width
	mov_tr	ax, dx					;ax <- width

	;    Destroy and kill the gstring for now
	;    though we will eventually want to return it as a vm chain
	;
	mov	dl,GSKT_LEAVE_DATA
	call	GrDestroyGString

	mov_tr	dx, ax					;width
	pop	ax					;vm block handle

done:
	.leave
	ret

badBounds:
	mov	dl,GSKT_KILL_DATA
	call	GrDestroyGString
	add	sp,2					;useless vm block handle
	clr	ax
	jmp	done

GrObjBodyCreateGStringTransferFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyCut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_META_CLIPBOARD_CUT

Called by:	

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCut	method dynamic	GrObjBodyClass, MSG_META_CLIPBOARD_CUT

	.enter

	mov	ax, MSG_META_CLIPBOARD_COPY
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_DELETE
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyCut	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodySelectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_META_SELECT_ALL

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

Return:		nothing

Destroyed:	ax, dx

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySelectAll	method dynamic	GrObjBodyClass, MSG_META_SELECT_ALL

	.enter

	call	GBMarkBusy

	;
	;  Send in reverse order so that the selection code
	;  doesn't scan the entire child list each time
	;
	mov	ax, MSG_GO_BECOME_SELECTED
	mov	dl, HUM_NOW
	call	GrObjBodySendToChildrenInReverseOrder

	call	GBMarkNotBusy

	.leave
	ret
GrObjBodySelectAll	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_META_CLIPBOARD_COPY

Called by:	

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCopy	method dynamic	GrObjBodyClass, MSG_META_CLIPBOARD_COPY

	uses	bp

	.enter

	call	GBMarkBusy

	mov	ax, MSG_GO_DESELECT_IF_COPY_LOCK_SET
	call	GrObjBodySendToSelectedGrObjs

	sub	sp, size PointDWFixed
	mov	bp, sp
	mov	ax, MSG_GB_GET_CENTER_OF_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

	call	ClipboardGetClipboardFile	;bx <- VM file
	call	GenerateTransferItem		;ax <- VM block
	add	sp, size PointDWFixed
	clr	bp				;not RAW, not QUICK
	call	ClipboardRegisterItem

	call	GBMarkNotBusy

	call	GrObjBodyUpdateEditController

	.leave
	ret
GrObjBodyCopy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyClipboardPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_META_CLIPBOARD_PASTE

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyClipboardPaste	method dynamic	GrObjBodyClass, MSG_META_CLIPBOARD_PASTE

	.enter

	mov	cx,handle pasteString
	mov	dx,offset pasteString
	call	GrObjGlobalStartUndoChain

	;   Use standard call back which adds each pasted grobject
	;   to the body and selects it.
	;

	call	GrObjBodyClearPasteCallBack

	;    So that only the new objects will be selected
	;

	mov	ax, MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GB_PASTE
	call	ObjCallInstanceNoLock

	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjBodyClipboardPaste	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyQuickPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_PASTE_COMMON

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

		cx - ClipboardItemFlags (CIF_QUICK)

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyQuickPaste	method dynamic	GrObjBodyClass, MSG_GB_QUICK_PASTE

	uses	cx, dx
	.enter

	mov	cx,handle pasteString
	mov	dx,offset pasteString
	call	GrObjGlobalStartUndoChain

	mov	ax,MSG_GB_QUICK_PASTE_CALL_BACK
	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	call	GrObjBodySetPasteCallBack

	;    So that only the new objects will be selected
	;

	mov	ax, MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	call	ObjCallInstanceNoLock

	mov	ax, mask CIF_QUICK
	call	GrObjBodyPasteCommon

	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjBodyQuickPaste	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyQuickPasteCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
		
		^lcx:dx - newly pasted object
		
RETURN:		
		nothiing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyQuickPasteCallBack	method dynamic GrObjBodyClass, 
						MSG_GB_QUICK_PASTE_CALL_BACK
	uses	bp
	.enter

	; Add the new grobj
	;

	mov     bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax, MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjCallInstanceNoLock

	push	si					;body chunk
	movdw	bxsi,cxdx				;new object
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_AFTER_QUICK_PASTE
	call	ObjMessage
	pop	si					;body chunk

	clr	di				
	mov	bx, segment GrObjClass
	mov	es, bx
	mov	bx, offset GrObjClass
	mov	ax,MSG_GO_SEND_ANOTHER_TOOL_ACTIVATED
	call	GrObjBodySendMessageToFloaterIfCurrentBody
	
	.leave
	ret
GrObjBodyQuickPasteCallBack		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Paste objects in clipboard into document. This handler
		doesn't change ATTR_GB_PASTE_CALL_BACK vardata if 
		it exists.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		The caller must
		have explicity set or cleared ATTR_GB_PASTE_CALL_BACK 
		before calling this routine.

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPaste	method dynamic GrObjBodyClass, MSG_GB_PASTE
	uses	bp
	.enter

	clr	ax				;not quick

	sub	sp, size PointDWFixed
	mov	bp, sp
	call	GrObjBodyGetPastePoint
	call	GrObjBodyPasteCommon
	add	sp, size PointDWFixed

	.leave
	ret
GrObjBodyPaste		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCloneSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_CLONE_SELECTED_GROBJS

Called by:	

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCloneSelectedGrObjs	method dynamic	GrObjBodyClass,
				MSG_GB_CLONE_SELECTED_GROBJS
	uses	cx, bp

	.enter

	;
	;  Put some bogus value out there
	;
	clr	bp
	rept 	size PointDWFixed / 2
		push	bp
	endm
	mov	bp, sp

	call	ClipboardGetClipboardFile	;bx <- VM file
	mov	cx, bx
	mov	ax, MSG_GB_CREATE_GROBJ_TRANSFER_FORMAT
	call	ObjCallInstanceNoLock

	call	GrObjBodyClearPasteCallBack

	push	ax				;vm block handle
	mov	ax, MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	call	ObjCallInstanceNoLock
	pop	ax				;vm block handle

	call	GrObjBodyParseGrObjTransferItem
	add	sp, size PointDWFixed

	call	VMFree

	.leave
	ret
GrObjBodyCloneSelectedGrObjs	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDuplicateSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_DUPLICATE_SELECTED_GROBJS

Called by:	

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDuplicateSelectedGrObjs	method dynamic	GrObjBodyClass,
					MSG_GB_DUPLICATE_SELECTED_GROBJS
	uses	cx, bp

	.enter

	sub	sp, size PointDWFixed
	mov	bp, sp

	mov	ax, MSG_GB_GET_CENTER_OF_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

	;
	;  The origin could be any value, but we don't want to
	;  trash the body's instance data...
	;

	call	ClipboardGetClipboardFile	;bx <- VM file
	mov	cx, bx
	mov	ax, MSG_GB_CREATE_GROBJ_TRANSFER_FORMAT
	call	ObjCallInstanceNoLock

	call	GrObjBodyGetWinCenter

	call	GrObjBodyClearPasteCallBack

	push	ax				;vm block handle
	mov	ax, MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	call	ObjCallInstanceNoLock
	pop	ax				;vm block handle

	call	GrObjBodyParseGrObjTransferItem

	add	sp, size PointDWFixed

	call	VMFree

	.leave
	ret
GrObjBodyDuplicateSelectedGrObjs	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyCustomDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_CUSTOM_DUPLICATE_SELECTED_GROBJS

Called by:	

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

		ss:[bp] - GrObjBodyCustomDuplicateParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCustomDuplicateSelectedGrObjs	method dynamic	GrObjBodyClass,
				MSG_GB_CUSTOM_DUPLICATE_SELECTED_GROBJS
	uses	cx, dx, bp
	.enter

	;
	;  Make sure we have something to duplicate
	;
	call	GrObjBodyGetNumCopyableGrObjs
	tst	cx
	jnz	doIt
done:
	.leave
	ret

doIt:
	;
	; Generate an empty undo chain so that the Undo menu item gets
	; disabled.
	;
	call	GrObjGlobalStartUndoChainNoText
	call	GrObjGlobalEndUndoChain

	call	GrObjGlobalUndoIgnoreActions
	call	GBMarkBusy

	;
	;  Remember our initial values in a local copy of
	;	GrObjBodyCustomDuplicateParams
	;
	sub	sp, size GrObjBodyCustomDuplicateParams
	mov	di, sp
	push	ds, si, di				;save body,
							;local GBCDP
	mov	si, ss
	mov	ds, si
	mov	es, si
	mov	si, bp
CheckEvenSize	GrObjBodyCustomDuplicateParams
	mov	cx, size GrObjBodyCustomDuplicateParams / 2
	rep movsw

	pop	ds, si, di				;*ds:si <- body
							;ss:di <- local GBCDP

	call	ClipboardGetClipboardFile	;bx <- VM file
	mov	cx, bx
	mov	dx, bp					;ss:dx <- GBCDP

	;
	;  Create a transfer item with all the selected grobjs in it
	;
	sub	sp, size PointDWFixed
	mov	bp, sp
	clr	ax
	clrdwf	ss:[bp].PDF_x, ax
	clrdwf	ss:[bp].PDF_y, ax
	mov	ax, MSG_GB_CREATE_GROBJ_TRANSFER_FORMAT
	call	ObjCallInstanceNoLock
	add	sp, size PointDWFixed

	push	bx, ax					;save transfer item
							;for freeing later

	mov_tr	cx, ax					;cx <- transfer block

	;
	;  We want the duplicated grobjs to be the only ones selected,
	;  so remove everyone else from the selection list
	;
	mov	ax, MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	call	ObjCallInstanceNoLock

	;
	;  Setup the GrObjTransferParams for pasting
	;
	mov	ax, cx					;ax <- transfer block
	call	VMLock
	mov	es, ax
	mov_tr	ax, cx					;ax <- transfer block
	push	bp					;save mem handle

	mov	cx, es:[GOTBH_meta].VMCT_count
	sub	cx, ((size GrObjTransferBlockHeader) - \
				(offset GOTBH_areaAttrArray)) / (size dword)

	sub	sp, size GrObjTransferParams
	mov	bp, sp
	call	SetupGTP
	mov	bx, size GrObjTransferBlockHeader

	;
	;  Clear the point in the GrObjTransferParams
	;
	clr	ax
	clrdwf	ss:[bp].GTP_selectionCenterDOCUMENT.PDF_x, ax
	clrdwf	ss:[bp].GTP_selectionCenterDOCUMENT.PDF_y, ax

objLoop:
	;
	;  Create one of the grobjs
	;
	movdw	ss:[bp].GTP_id, es:[bx], ax
	mov	ax, MSG_GB_INSTANTIATE_GROBJ
	push	cx,bx					;save # children,ptr
	push	dx					;save GBCDP
	call	GrObjParseOneGrObj

	;
	; Add the new grobj. The grobj used to be added and drawn at
	; the same time later in the routine, but this prevent
	; rotated splines from calcing their bounds correctly. The
	; spline won't draw to the path unless it is realized which
	; won't happen until the guardian is added to the body
	;
	push	bp					;stack frame
	mov     bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax, MSG_GB_ADD_GROBJ
	call	ObjCallInstanceNoLock
	pop	bp					;stack frame

	;
	;  Customize the new grobj
	;
	pop	ax					;ss:ax <- GBCDP
	push	ax					;save GBCDP
	push	bp					;save GTP
	push	di, si					;save local GBCDP,
							; body chunk
	mov_tr	bp, ax					;ss:bp <- GBCDP
	push	bp					;save GBCDP

	movdw	bxsi, cxdx
	add	bp, offset GBCDP_move
	mov	ax, MSG_GO_MOVE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	add	bp, offset GBCDP_scale - offset GBCDP_move
	mov	ax, MSG_GO_SCALE_OBJECT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	add	bp, offset GBCDP_skew - offset GBCDP_scale
	mov	ax, MSG_GO_SKEW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	bp					;ss:[bp] <- GBCDP
	movwwf	cxdx, ss:[bp].GBCDP_rotation
	mov	al, ss:[bp].GBCDP_rotateAnchor
	mov_tr	bp, ax
	mov	ax, MSG_GO_ROTATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;  Send a message to the new grobj to kill itself if
	;  it ended up outside of the body's bounds
	;

	mov	ax, MSG_GO_CLEAR_IF_NOT_WITHIN_BODY_BOUNDS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	movdw	cxdx, bxsi

	pop	di, si					;di <- local GBCDP,
							;*ds:si <- body
	;
	;  If the object destroyed itself, don't draw it
	;

	jc	afterAddedToBody

	;
	; Add the new grobj
	;
	mov     bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax, MSG_GB_DRAW_GROBJ
	call	ObjCallInstanceNoLock

	;    Select the grobj but don't draw its handles because
	;    they might get trounced by other objects being duplicated
	;

	mov	al,HUM_MANUAL
	call	GrObjBodySendBecomeSelectedToChild

afterAddedToBody:
	
	pop	bp					;ss:bp <- GTP
	pop	dx					;ss:dx <- GBCDP
	pop	cx,bx					;cx <- # children,
							;bx <- ptr
	add	bx, size dword
	dec	cx
	LONG	jnz	objLoop

	;
	;  Increment the increments
	;
	mov	bx, dx					;ss:bx <- local GBCDP
	dec	ss:[di].GBCDP_repetitions
	LONG	jz	drawHandles

	addwwf	ss:[bx].GBCDP_rotation, ss:[di].GBCDP_rotation, ax
	addpdf	ss:[bx].GBCDP_move, ss:[di].GBCDP_move, ax
	addwwf	ss:[bx].GBCDP_skew.GOASD_degrees.GOSD_xDegrees, \
		ss:[di].GBCDP_skew.GOASD_degrees.GOSD_xDegrees, ax
	addwwf	ss:[bx].GBCDP_skew.GOASD_degrees.GOSD_yDegrees, \
		ss:[di].GBCDP_skew.GOASD_degrees.GOSD_yDegrees, ax

	push	bx
	movwwf	dxcx, ss:[bx].GBCDP_scale.GOASD_scale.GOSD_xScale
	movwwf	bxax, ss:[di].GBCDP_scale.GOASD_scale.GOSD_xScale
	call	GrMulWWFixed
	pop	bx
	movwwf	ss:[bx].GBCDP_scale.GOASD_scale.GOSD_xScale, dxcx
	
	push	bx
	movwwf	dxcx, ss:[bx].GBCDP_scale.GOASD_scale.GOSD_yScale
	movwwf	bxax, ss:[di].GBCDP_scale.GOASD_scale.GOSD_yScale
	call	GrMulWWFixed
	pop	bx
	movwwf	ss:[bx].GBCDP_scale.GOASD_scale.GOSD_yScale, dxcx

	mov	dx, bx					;ss:dx <- local GBCDP
	mov	cx, es:[GOTBH_meta].VMCT_count
	sub	cx, ((size GrObjTransferBlockHeader) - \
				(offset GOTBH_areaAttrArray)) / (size dword)
	mov	bx, size GrObjTransferBlockHeader
	jmp	objLoop


drawHandles:
	;    Draw the handles of all the newly created grobjects
	;

	push	bp,dx,di,ax				;stack frame
	mov	ax,MSG_GB_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	dx,bp					;gstate
	mov	ax,MSG_GO_DRAW_HANDLES
	call	GrObjBodySendToSelectedGrObjs
	mov	di,dx
	call	GrDestroyState
	pop	bp,dx,di,ax					;stack frame

	mov	bx, ss:[bp].GTP_optBlock
	tst	bx
	jz	freeFrame
	call	MemFree
freeFrame:
	add	sp, size GrObjTransferParams

	pop	bp
	call	VMUnlock

	;
	;  Free the "transfer" item
	;
	pop	bx, ax
	call	VMFree

	;
	; We must mark not busy BEFORE accepting undo, since the mark
	; not busy causes an unsuspend, which will unsuspend every
	; object in the selection list, which, in the case of
	; VisTextClass, causes multiple MSG_GEN_PROCESS_UNDO_END_CHAIN
	; messages to be sent, which were never balanced by
	; MSG_GEN_PROCESS_UNDO_START_CHAIN calls.
	;
	call	GBMarkNotBusy
	call	GrObjGlobalUndoAcceptActions
	add	sp, size GrObjBodyCustomDuplicateParams
	jmp	done
GrObjBodyCustomDuplicateSelectedGrObjs	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyPasteCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Common paste routine 

Called by:	GrObjBodyQuickPaste, GrObjBodyPaste

Pass:		*ds:si = GrObjBody object

		ax - ClipboardItemFlags (CIF_QUICK)
		ss:[bp] - origin for paste

		NOTE:******
		The caller must
		have explicity set or cleared ATTR_GB_PASTE_CALL_BACK 
		before calling this routine.

Return:		nothing

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPasteCommon	proc	far
	uses	ax, bx, cx, dx, bp, di

	.enter

	push	bp
	mov_tr	bp, ax
	call	ClipboardQueryItem
	tst	bp
	pop	bp
	jz	notifyDone			;if no formats, done


	mov	di,offset BigFourTransferItemFormatTable
	mov	dx,offset StandardPasteTransferItemFormatRoutineTable
	call	GrObjBodyCallTransferItemFormatRoutine
	jc	notifyDone			;jmp if format not found

	;    Draw the handles of all the newly pasted grobjects
	;

	push	ax					;vm block handle
	mov	ax,MSG_GB_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	dx,bp					;gstate
	mov	ax,MSG_GO_DRAW_HANDLES
	call	GrObjBodySendToSelectedGrObjs
	mov	di,dx
	call	GrDestroyState
	pop	ax					;vm block handle

notifyDone:
	call	ClipboardDoneWithItem

	.leave
	ret

GrObjBodyPasteCommon	endp

StandardPasteTransferItemFormatRoutineTable word \
	offset GrObjBodyParseGrObjTransferItem,
	offset GrObjBodyParseBitmapTransferItem,
	offset GrObjBodyPasteTextTransferItem,
	offset GrObjBodyParseGStringTransferItem


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyParseGrObjTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Does the "real" work of pasting a CIF_GROBJ format transfer,
		reading the item and creating the appropriate grobjs, then
		adding the new grobjs to the body.

Pass:		*ds:si = GrObjBody
		bx - VM file
		ax - VM block handle
		ss:[bp] - PDF origin to paste at

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 12, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyParseGrObjTransferItem	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	call	GBMarkBusy

	mov	dx, bp					;ss:dx <- PDF

	push	ax					;save block handle
	call	VMLock
	mov	es, ax
	pop	ax					;ax <- block handle
	push	bp					;save mem handle

	mov	cx, es:[GOTBH_meta].VMCT_count
	sub	cx, ((size GrObjTransferBlockHeader) - \
				(offset GOTBH_areaAttrArray)) / (size dword)

	sub	sp, size GrObjTransferParams
	mov	bp, sp
	call	SetupGTP
	mov	bx, size GrObjTransferBlockHeader

	;
	;  Copy the passed point into the GrObjTransferParams
	;

	push	cx, si, di, es, ds
	mov	cx, ss
	mov	ds, cx
	mov	es, cx
	mov	si, dx
	lea	di, ss:[bp].GTP_selectionCenterDOCUMENT
	mov	cx, size PointDWFixed / 2
	rep movsw
	pop	cx, si, di, es, ds

	jcxz	afterObjLoop

objLoop:
	movdw	ss:[bp].GTP_id, es:[bx], ax
	mov	ax, MSG_GB_INSTANTIATE_GROBJ
	jcxz	afterObjLoop
	push	cx					;save # children
	call	GrObjParseOneGrObj

	;    This adds the object to the body or something like that.
	;

	call	GrObjBodyCallPasteCallBack

	add	bx, size dword
	pop	cx					;cx <- # children
	loop	objLoop

afterObjLoop:
	mov	bx, ss:[bp].GTP_optBlock
	tst	bx
	jz	freeFrame
	call	MemFree
freeFrame:
	add	sp, size GrObjTransferParams

	pop	bp
	call	VMUnlock

	mov	ax,MSG_GB_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	dx,bp					;gstate
	mov	ax,MSG_GO_DRAW_HANDLES
	call	GrObjBodySendToSelectedGrObjs
	mov	di,dx
	call	GrDestroyState

	call	GBMarkNotBusy

	.leave
	ret
GrObjBodyParseGrObjTransferItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPasteTextTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Does the "real" work of pasting a CIF_TEXT format transfer.
		Creates a text object, adds it to the body and sends
		MSG_META_CLIPBOARD_PASTE to it.

Pass:		*ds:si = GrObjBody
		bx - VM file
		ax - VM block handle
		ss:[bp] - PointDWFixed - point to center object on
		cx - width or 0
		dx - height or 0

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	srs	Nov 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GROBJ_DEFAULT_TEXT_WIDTH = 5*72
GROBJ_DEFAULT_TEXT_HEIGHT = 2*72

GrObjBodyPasteTextTransferItem	proc	near
	uses	ax,cx,dx,bp,es,bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject				>

	;    Copy paste center to position in stack frame
	;

	push	bx, ax					;save item

	sub	sp,size GrObjInitializeData
	mov	di,sp					;init frame
	mov	bx,di					;init frame
	push	ds,si					;body segment,chunk
	mov	si,bp					;point frame
	mov	ax,ss
	mov	es,ax
	mov	ds,ax
	MoveConstantNumBytes <size PointDWFixed>
	pop	ds,si					;body segment,chunk
	tst	cx
	jnz	setDimensions
	jmp	getDefaultDimensions			;passed width

setDimensions:
	;    Set the dimensions and adjust the center position to
	;    be the upper left.
	;

	mov	ss:[bx].GOID_width.WWF_int,cx
	mov	ss:[bx].GOID_height.WWF_int,dx
	clr	ax
	mov	ss:[bx].GOID_width.WWF_frac,ax
	mov	ss:[bx].GOID_height.WWF_frac,ax
	shr	cx,1
	shr	dx,1
	sub	ss:[bx].GOID_position.PDF_x.DWF_int.low,cx
	sbb	ss:[bx].GOID_position.PDF_x.DWF_int.high,ax
	sub	ss:[bx].GOID_position.PDF_y.DWF_int.low,dx
	sbb	ss:[bx].GOID_position.PDF_y.DWF_int.high,ax
	mov	bp,bx					;init frame

	;   Instantiate and initialize the new text object
	;

	mov	cx,segment MultTextGuardianClass
	mov	dx, offset MultTextGuardianClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	;    The whole create operation will be undone by simply deleting
	;    so don't let anything else be added to the undo chain
	;

	call	GrObjGlobalUndoIgnoreActions

	push	si,dx					;body, child chunk
	movdw	bxsi,cxdx				;new child od
	mov	dx,size GrObjInitializeData
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_INITIALIZE
	call	ObjMessage

	pop	si,dx					;body, child chunk
	add	sp,size GrObjInitializeData

	;    Have text object handle paste itself
	;

	pop	ax, di					;ax <- vm file handle
							;di <- vm block handle
	push	bp
	sub	sp, size CommonTransferParams
	mov	bp, sp

	clrdw	ss:[bp].CTP_range.VTR_start
	movdw	ss:[bp].CTP_range.VTR_end, TEXT_ADDRESS_PAST_END
	clr	ss:[bp].CTP_pasteFrame			;what the hell is this?
	mov	ss:[bp].CTP_vmFile, ax
	mov	ss:[bp].CTP_vmBlock, di

	push	si					;body chunk
	mov	si,dx					;child chunk
	mov	di,mask MF_FIXUP_DS or mask MF_CALL	
	mov	ax,MSG_GOVG_GET_VIS_WARD_OD
	call	ObjMessage
	pushdw	bxsi					;guardian od
	movdw	bxsi,cxdx				;vis ward od
	mov	di,mask MF_FIXUP_DS
	mov	dx, size CommonTransferParams
	mov	ax,MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
	call	ObjMessage

	popdw	bxsi					;guardian od
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	call	ObjMessage
	movdw	cxdx,bxsi				;guardian od
	pop	si					;body chunk

	add	sp, size CommonTransferParams
	pop	bp

	call	GrObjGlobalUndoAcceptActions

	call	GrObjBodyCallPasteCallBack

	.leave
	ret

getDefaultDimensions:
	mov	cx,GROBJ_DEFAULT_TEXT_WIDTH
	mov	dx,GROBJ_DEFAULT_TEXT_HEIGHT
	jmp	setDimensions
GrObjBodyPasteTextTransferItem	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyParseGStringTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Does the "real" work of pasting a CIF_TEXT format transfer,
		reading the item and creating the appropriate grobj, then
		adding the new grobj to the body.

CALLED BY:	GrObjBodyPasteCommon

PASS:		
		*ds:si = GrObjBody
		bx - VM file
		ax - VM block handle
		ss:[bp] - PDF origin to paste at

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyParseGStringTransferItem		proc	near
	.enter

	call	GrObjBodyParseGString

	.leave
	ret
GrObjBodyParseGStringTransferItem		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyParseBitmapTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Does the "real" work of pasting a CIF_BITMAP format transfer,
		reading the item and creating the appropriate grobj, then
		adding the new grobj to the body.

CALLED BY:	GrObjBodyPasteCommon

PASS:		
		*ds:si = GrObjBody
		bx - VM file
		ax - VM block handle
		ss:[bp] - PDF center of paste

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyParseBitmapTransferItem		proc	near
	.enter

	call	GrObjBodyImportHugeBitmap

	.leave
	ret
GrObjBodyParseBitmapTransferItem		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetPastePoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns the interesting point for the GrObjBody if onscreen,
		otherwise returns the center of the window.

Pass:		*ds:si - GrObjBody
		ss:bp - PointDWFixed

Return:		if carry set:
			ss:[bp] - PointDWFixed interesting point
		if carry clear:
			ss:[bp] - center of the window

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RectDWordAndRectDWFixed	struct
	RDWARDWF_rectDWord	RectDWord
	RDWARDWF_rectDWFixed	RectDWFixed
RectDWordAndRectDWFixed	ends

GrObjBodyGetPastePoint	proc	far
	class	GrObjBodyClass

	uses	ax, di, si, ds, es
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	movpdf	ss:[bp], ds:[di].GBI_interestingPoint, ax
	mov	di, ds:[di].GBI_graphicsState
	tst	di
	stc
	jz	done

	push	ds, si					;save body
	sub	sp, size RectDWordAndRectDWFixed
	mov	si, sp
	segmov	ds, ss
	call	GrGetWinBoundsDWord
	movdw	ds:[si].RDWARDWF_rectDWFixed.RDWF_left.DWF_int, \
		ds:[si].RDWARDWF_rectDWord.RD_left, di
	movdw	ds:[si].RDWARDWF_rectDWFixed.RDWF_right.DWF_int, \
		ds:[si].RDWARDWF_rectDWord.RD_right, di
	movdw	ds:[si].RDWARDWF_rectDWFixed.RDWF_top.DWF_int, \
		ds:[si].RDWARDWF_rectDWord.RD_top, di
	movdw	ds:[si].RDWARDWF_rectDWFixed.RDWF_bottom.DWF_int, \
		ds:[si].RDWARDWF_rectDWord.RD_bottom, di
	clr	di
	mov	ds:[si].RDWARDWF_rectDWFixed.RDWF_left.DWF_frac, di
	mov	ds:[si].RDWARDWF_rectDWFixed.RDWF_right.DWF_frac, di
	mov	ds:[si].RDWARDWF_rectDWFixed.RDWF_top.DWF_frac, di
	mov	ds:[si].RDWARDWF_rectDWFixed.RDWF_bottom.DWF_frac, di
	add	si, offset RDWARDWF_rectDWFixed
	segmov	es, ss
	mov	di, bp
	call	GrObjGlobalIsPointDWFixedInsideRectDWFixed?

	lahf
	add	sp, size RectDWordAndRectDWFixed
	sahf
	pop	ds, si					;*ds:si <- body
	jc	done

	;
	;	The stored interesting point is not inside the win bounds,
	;	so we'll use the win center instead.
	;
	call	GrObjBodyGetWinCenter
	clc

done:
	.leave
	ret
GrObjBodyGetPastePoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendBecomeSelectedToChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GO_BECOME_SELECTED to the passed child.
		Always passed HUM_MANUAL

CALLED BY:	INTERNAL
		GrObjBodyParseGrObjTransferItem
		GrObjBodyCustomDuplicateSelectedGrObjs

PASS:		*ds:si - body
		^lcx:dx - child
		al - HandleUpdateMode
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendBecomeSelectedToChild		proc	far
	uses	ax,bx,dx,si,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	movdw	bxsi,cxdx				;guardian od
	mov	dl, al
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_BECOME_SELECTED
	call	ObjMessage

	.leave
	ret
GrObjBodySendBecomeSelectedToChild		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetWinCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns the center of the body's window.

Pass:		*ds:si - GrObjBody
		ss:bp - PointDWFixed (empty)

Return:		carry set if no window
		else
			ss:[bp] - center of the window

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetWinCenter	proc	far
	class	GrObjBodyClass

	uses	di, si, ds
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	mov	di, ds:[di].GBI_graphicsState
	tst	di
	stc
	jz	done

	sub	sp, size RectDWord
	mov	si, sp
	segmov	ds, ss
	call	GrGetWinBoundsDWord

	movdw	ss:[bp].PDF_x.DWF_int, ds:[si].RD_left, di
	movdw	ss:[bp].PDF_y.DWF_int, ds:[si].RD_top, di
	adddw	ss:[bp].PDF_x.DWF_int, ds:[si].RD_right, di
	adddw	ss:[bp].PDF_y.DWF_int, ds:[si].RD_bottom, di
	sardwf	ss:[bp].PDF_x
	sardwf	ss:[bp].PDF_y

	;    GrObjs with a .5 as part of the center tend to draw
	;    a little odd. For instance edges of rectangles rotated 45
	;    degrees get one pixel hitches in them. Rounding
	;    in the graphics system causes the hitches  .5 centers 
	;    will happen anyway with people moving objects around
	;    while zoomed in, but we don't have to contribute by
	;    supplying a .5 here. This helps out in duplication,
	;    pasting, creating polygons and creating stars.
	;

	clr	di
	mov	ss:[bp].PDF_x.DWF_frac, di
	mov	ss:[bp].PDF_y.DWF_frac, di


	add	sp, size RectDWord

	clc
done:
	.leave
	ret
GrObjBodyGetWinCenter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjParseOneGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates a single grobj (presumably from a transfer item)
		as indicated by the VM override file and the 32 bit identifier
		at ss:[bp].GTP_id.

Pass:		ss:[bp] - GrObjTransferParams
		*ds:si - parent (probably body or group)
		ax = parent class instantiate msg (eg MSG_GB_INSTANTIATE_GROBJ)
			method should expect cx:dx - class pointer

Return:		^lcx:dx = new grobj

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 12, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjParseOneGrObj	proc	far
	uses	ax, bx, di, si, es
	.enter

	push	ax				;save instantiate message

	mov	bx, ss:[bp].GTP_vmFile
	mov	ax, ss:[bp].GTP_id.high
	tst	ss:[bp].GTP_id.low
	jnz	readDB

	push	bp
	call	VMLock
	mov	es, ax

	cmp	es:[VMLAGOR_link].VMCL_next, VM_CHAIN_TREE
	mov	di, size VMChainTree
	je	gotOffset
	mov	di, offset VMLAGOR_relocation
gotOffset:
	call	GrObjReadEntryPointRelocation

	call	VMUnlock
	pop	bp
	add	di, size GrObjEntryPointRelocation
	jmp	relocClass

readDB:
	;
	;	The object is in a DB item
	;
	mov	di, ss:[bp].GTP_id.low
	call	DBLock
	mov	di, es:[di]

	call	GrObjReadEntryPointRelocation
	call	DBUnlock
	mov	di, size GrObjEntryPointRelocation

relocClass:
	mov	ss:[bp].GTP_curPos, di

	;
	;	^lcx:dx <- new grobj
	;
	pop	ax				;ax <- instantiate msg
	call	ObjCallInstanceNoLock

	mov	bx, cx				;bx <- grobj handle
	mov	si, dx				;si <- grobj chunk
	
	; Protect from stack overflow.
	mov	di, size GrObjTransferParams
	push	di				;popped by routine
	mov	di, 800				;number of bytes required
	call	GrObjBorrowStackSpaceWithData
	push	di				;save token for ReturnStack

	; Send replace message (could cause nasty recursion)
	mov	ax, MSG_GO_REPLACE_WITH_TRANSFER
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	
	pop	di
	call	GrObjReturnStackSpaceWithData

	.leave
	ret
GrObjParseOneGrObj	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjReadEntryPointRelocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This routine returns a class pointer from the passed
		GrObjReadEntryPointRelocation.

Pass:		es:di - GrObjEntryPointRelocation

Return:		cx:dx - class ptr

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 17, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjReadEntryPointRelocation	proc	far
	uses	ax, di, es
	.enter

	pushdw	esdi
	call	ObjRelocateEntryPoint	;dxax <- relocated class or 0

	mov	cx, dx
	jcxz	getGrObjClass
	mov_tr	dx, ax

done:
	.leave
	ret

	;
	;  We can't do the full relocation (the geode was probably freed),
	;  so we resort to the leaf grobj class
	;
getGrObjClass:
	mov	cx, es:[di].GOEPR_grObjEntryPoint
	sub	sp, size EntryPointRelocation
	mov	di, sp

if 0
CheckHack	<size EntryPointRelocation ge GEODE_NAME_SIZE>
	segmov	es, ss
	mov	ax, GGIT_PERM_NAME_ONLY
	clr	bx					;current geode
	call	GeodeGetInfo				;get grobj name
else
	mov	ss:[di+0], 'r' shl 8 or 'g'
	mov	ss:[di+2], 'b' shl 8 or 'o'
	mov	ss:[di+4], ' ' shl 8 or 'j'
	mov	ss:[di+6], ' ' shl 8 or ' '
endif

	mov	ss:[di].EPR_entryNumber, cx		;store entry point

	;
	;  Unrelocate the leaf grobj class
	;
	pushdw	ssdi
	call	ObjRelocateEntryPoint	;dxax <- relocated class or 0
	add	sp, size EntryPointRelocation

	mov	cx, dx
	mov_tr	dx, ax
	jmp	done
GrObjReadEntryPointRelocation	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenerateTransferItem

DESCRIPTION:	Generate a transfer item for the currently selected grobjs

PASS:
	*ds:si - GrObjBody
	ss:bp - origin for generated transfer item

	bx - VM file

RETURN:
	ax - VM block of transfer item (in clipboard's VM file)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	srs	2/93		Changed to handle rejected gstrings
------------------------------------------------------------------------------@
GenerateTransferItem	proc	far	uses bx, cx, dx, si, di, bp, es

	class	GrObjBodyClass
	.enter

	;
	;	Store the point in the body's instance data
	;
	push	si, ds					;body segment, chunk
	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	add	di, offset GBI_interestingPoint
	segmov	es, ds
	segmov	ds, ss
	mov	si, bp
	mov	cx, size PointDWFixed / 2
	rep movsw
	pop	si,ds					;body segment, chunk

	;    Allocate block for transfer item header and save
	;    vm block handle of header for return.
	;

	mov	cx, size ClipboardItemHeader
	clr	ax				;user ID?
	call	VMAlloc
	push	ax				;save block handle for return

	;    Initialize the header.
	;

	push	bp				;stack frame
	call	VMLock
	call	VMDirty
	mov	es, ax				;transfer item segment
	mov_tr	ax,bp				;vm mem handle for VMUnlock
	pop	bp				;stack frame
	push	ax				;vm mem handle for VMUnlock
	mov	es:[CIH_sourceID].chunk, si	;body chunk
	mov	ax,ds:[LMBH_handle]		;body handle
	mov	es:[CIH_sourceID].handle, ax	;body handle
	mov	es:[CIH_owner].chunk, si	;body chunk
	mov	es:[CIH_owner].handle, ax	;body handle
	clr	es:[CIH_formatCount]
	
	;    Copy scrap name to header
	;

	push	ds,si,bx			;body segment, chunk,
						;vm file handle
	mov	bx, handle unnamedGrObjString
	call	MemLock
	mov	ds, ax				;strings segment
assume	ds:Strings
	mov	si, ds:[unnamedGrObjString]	; ds:si = string
assume	ds:nothing
	ChunkSizePtr	ds, si, cx		; cx = length w/ NULL
	mov	di, offset CIH_name		;es:di = dest
CheckHack< (length unnamedGrObjString) le (length CIH_name) >	
	LocalCopyNString
	call	MemUnlock
	pop	ds,si,bx			;body segment, chunk,
						;vm file handle

	;    Create grobj format vm chain
	;

	mov	cx, bx					;vm file handle
	mov	ax, MSG_GB_CREATE_GROBJ_TRANSFER_FORMAT
	call	ObjCallInstanceNoLock			;ax <- vm block handle
	mov	es:[CIH_formats][0].CIFI_vmChain.high,ax
	clr	es:[CIH_formats][0].CIFI_vmChain.low
	mov	es:[CIH_formats][0].CIFI_format.CIFID_manufacturer, \
							MANUFACTURER_ID_GEOWORKS
	mov	es:[CIH_formats][0].CIFI_format.CIFID_type, CIF_GROBJ
	inc	es:[CIH_formatCount]

	;    Attempt to create GString format vm chain
	;

	mov	ax, MSG_GB_CREATE_GSTRING_TRANSFER_FORMAT
	call	ObjCallInstanceNoLock
	tst	ax				;vm block handle of vm chain
	jz	unlock
	mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].\
		CIFI_vmChain.high,ax
	mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].\
		CIFI_vmChain.low, 0
	mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].\
		CIFI_format.CIFID_manufacturer, MANUFACTURER_ID_GEOWORKS
	mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].\
		CIFI_format.CIFID_type, CIF_GRAPHICS_STRING
	inc	es:[CIH_formatCount]
	mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].CIFI_extra1,cx
	mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].CIFI_extra2,dx

unlock:
	pop	bp				;vm mem handle
	call	VMDirty
	call	VMUnlock

	pop	ax				;vm block handle

	.leave
	ret
GenerateTransferItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_META_DELETE

Called by:	

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 12, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDelete	method dynamic	GrObjBodyClass, MSG_META_DELETE
	uses	cx,dx,bp
	.enter

	call	GBMarkBusy

	mov	ax, MSG_GB_DELETE_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

	call	GBMarkNotBusy

	.leave
	ret
GrObjBodyDelete	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	MakeTransferFormatNotLMem

DESCRIPTION:	Convert blocks in a transfer format to not be lmem

CALLED BY:	INTERNAL

PASS:
	es - GrObjTransferBlockHeader
	bx - vm file

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
	Tony	1/24/92		Initial version

------------------------------------------------------------------------------@
MakeTransferFormatNotLMem	proc	near	uses ax, bx, cx, si, bp, ds
	.enter

	mov	si, offset GOTBH_firstLMem
	mov	cx, ((offset GOTBH_lastLMem) - (offset GOTBH_firstLMem)) \
						/ (size dword)
changeLoop:
	mov	ax, es:[si].high
	tst	ax
	jz	next
	call	VMLock					;bp = mem handle
	mov	ds, ax
	xchg	bx, bp					;bx <- mem handle
							;bp <- vm file
	mov	ax, (mask HF_LMEM) shl 8
	call	MemModifyFlags
	xchg	bx, bp					;bp <- mem handle
							;bx <- vm file
	clr	ds:[LMBH_handle]
	call	VMDirty
	call	VMUnlock
next:
	add	si, (size dword)
	loop	changeLoop

	.leave	
	ret

MakeTransferFormatNotLMem	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetPasteCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store od and message in vardata. The message will be
		send to the od for each object that is pasted.

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - GrObjBody
		^lcx:dx - od	
		ax - message

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetPasteCallBack		proc	far
	uses	bx
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	push	ax,cx				;message, handle
	mov	ax,ATTR_GB_PASTE_CALL_BACK
	mov	cx,size GrObjBodyPasteCallBackStruct
	call	ObjVarAddData
	pop	ax,cx				;message, handle
	
	mov	ds:[bx].GOBPCBS_message,ax
	movdw	ds:[bx].GOBPCBS_optr,cxdx

	.leave
	ret
GrObjBodySetPasteCallBack		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyClearPasteCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the ATTR_GB_PASTE_CALL_BACK vardata

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - GrObjBody

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyClearPasteCallBack		proc	far
	uses	ax
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	ax,ATTR_GB_PASTE_CALL_BACK
	call	ObjVarDeleteData

	.leave
	ret
GrObjBodyClearPasteCallBack		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCallPasteCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If there is not paste call back var data then
		send MSG_GB_STANDARD_PASTE_CALL_BACK to the body,
		otherwise send the stored message to the stored od

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - GrObjBody
		^lcx:dx - optr of newly pasted object

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCallPasteCallBack		proc	far
	uses	ax,bx,si,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	ax,ATTR_GB_PASTE_CALL_BACK
	call	ObjVarFindData
	jc	found

	mov	ax,MSG_GB_STANDARD_PASTE_CALL_BACK
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

found:
	mov	ax,ds:[bx].GOBPCBS_message

	mov	si,ds:[bx].GOBPCBS_optr.chunk
	mov	bx,ds:[bx].GOBPCBS_optr.handle
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	jmp	done


GrObjBodyCallPasteCallBack		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyStandardPasteCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The standard paste call back just adds the grobject
		to the body and selects it without drawing the handles.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		^lcx:dx - newly pasted grobject

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyStandardPasteCallBack	method dynamic GrObjBodyClass, 
						MSG_GB_STANDARD_PASTE_CALL_BACK
	uses	bp
	.enter

	; Add the new grobj
	;

	mov     bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax, MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjCallInstanceNoLock

	;    Select the grobj but don't draw its handles because
	;    they might get trounced by other objects being pasted in
	;

	mov	al,HUM_MANUAL
	call	GrObjBodySendBecomeSelectedToChild

	.leave
	ret
GrObjBodyStandardPasteCallBack		endm




GrObjTransferCode ends


