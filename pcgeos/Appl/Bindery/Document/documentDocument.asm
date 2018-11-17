COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentDocument.asm

ROUTINES:
	Name			Description
	----			-----------
    GLB LocalizeNameArray	This routine localizes the name array

    GLB LocalizeNameArrayElement 
				Localizes a name array element.

    INT GetDefaultWidthHeight	Initialize a newly created document file

    INT SendPageSizeToView	Send the current page size to the view

    INT SendDocumentSizeToView	Send the current document size to the
				content

    INT ReallySendDocumentSizeToView 
				Do the actual work of sending the document
				size to the view

    INT SetViewSize		Send the size of a view

    INT SuspendDocument		Suspend the document, its articles and its
				body

    INT UnsuspendDocument	Unsuspend the document, its articles and
				its body

METHODS:
	Name			Description
	----			-----------
    StudioDocumentInitializeDocumentFile  
				Initialize a newly created document file

				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE
				StudioDocumentClass

    StudioDocumentSetDocBounds	Intercept notification when the article (in
				galley or draft mode) is telling the view
				how big it is

				MSG_VIS_CONTENT_SET_DOC_BOUNDS
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the document open/close related code for
	StudioDocumentClass

	$Id: documentDocument.asm,v 1.1 97/04/04 14:39:33 newdeal Exp $

------------------------------------------------------------------------------@

idata segment
	StudioDocumentClass
idata ends

DocCreate segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalizeNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine localizes the name array

CALLED BY:	GLOBAL
PASS:		AX - VM handle
		DX - chunk handle of name array in VM block
		*ds:si - StudioDocument object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalizeNameArray	proc	near	uses	ax, bx, cx, dx, bp, di, si, ds, es
	.enter

;	Lock down the block containing the NameArray.

	call	GetFileHandle
	call	VMLock
	mov	ds, ax
	mov	si, dx			;*DS:SI <- NameArray

	mov	bx, cs
	mov	di, offset LocalizeNameArrayElement
	call	ChunkArrayEnum

;	Mark the block dirty (since we've changed the data) and unlock it

	call	VMDirty
	call	VMUnlock
	.leave
	ret
LocalizeNameArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalizeNameArrayElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Localizes a name array element.

CALLED BY:	GLOBAL
PASS:		ds:di - element in a NameArray
		ax - size of element
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
	Each element in a localizable NameArray has an lptr to a string as
	the last word in the element.

	We copy the data out of that chunk into the end of the element.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalizeNameArrayElement	proc	far
	.enter

;	Get the size of the data we'll be copying in.

	mov	bx, ax
	mov	bx, ds:[bx][di][-(size lptr)]	;BX <- chunk handle of string
EC <	xchg	si, bx							>
EC <	call	ECLMemValidateHandle					>
EC <	xchg	si, bx							>

	mov	bx, ds:[bx]		;DS:BX <- ptr to string
	ChunkSizePtr	ds, bx, cx
	dec	cx			;CX <- size of string w/o null	
DBCS <  dec	cx							>

;	Resize this element to fit the data

     	add	cx, ax
	sub	cx, size lptr		;CX <- new size of element
	push	ax			;Save old size of element
	call	ChunkArrayPtrToElement	;AX <- element number
	
	call	ChunkArrayElementResize	;Resize the element
	call	ChunkArrayElementToPtr	;Get ptr to element again
	pop	ax			;Restore old size of the element

;	Get a ptr into the element, and copy the data over

	add	di, ax
	sub	di, size lptr		;DS:DI <- ptr to part of element that
					; holds the chunk handle of the string
					; to copy in.
	segmov	es, ds			;ES:DI <- ptr to dest for copy
	mov	si, ds:[di]		;*DS:SI <- string to copy in
	mov	si, ds:[si]		;DS:SI <- string to copy in
	ChunkSizePtr	ds, si, cx
	dec	cx			;CX <- size of string w/o null
DBCS <	dec	cx							>
	rep	movsb			;Copy the data over.
	clc				;Continue enumeration
	.leave
	ret
LocalizeNameArrayElement	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentInitializeDocumentFile --
		MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE for StudioDocumentClass

DESCRIPTION:	Initialize a newly created document file

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

RETURN:
	carry - set if error

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 9/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentInitializeDocumentFile	method dynamic	StudioDocumentClass,
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE

	call	IgnoreUndoAndFlush

	; Set cx non-zero if we're using metric

	mov	ax, MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE
	call	GenCallApplication		;al = units
	clr	cx
	cmp	al, MEASURE_US
	jz	gotUnits
	inc	cx
gotUnits:

	; Duplicate map block and attach

	mov	bx, handle MapBlockTemp
	call	DuplicateAndAttachData		;ax = VM block
	mov	dx, offset SectionArray
	call	LocalizeNameArray

	call	GetFileHandle
	call	VMSetMapBlock

	call	VMLock
	mov	es, ax				;es = map block

	call	GetNowAsTimeStamp
	mov	es:[MBH_revisionStamp].FDAT_date, ax
	mov	es:[MBH_revisionStamp].FDAT_time, bx

	push	si, ds
	segmov	ds, es
	mov	si, offset SectionArray
	clr	ax
	push	cx
	call	ChunkArrayElementToPtr

	; set page size

	call	GetDefaultWidthHeight		;cx, dx = size
	mov	ds:MBH_pageSize.XYS_width, cx
	mov	ds:MBH_pageSize.XYS_height, dx
	pop	cx

	; adjust map block for metric

	jcxz	notMetricMapBlock
	mov	ds:[di].SAE_columnSpacing, METRIC_DEFAULT_COLUMN_SPACING
	mov	ds:[di].SAE_leftMargin, METRIC_DEFAULT_DOCUMENT_LEFT_MARGIN
	mov	ds:[di].SAE_topMargin, METRIC_DEFAULT_DOCUMENT_TOP_MARGIN
	mov	ds:[di].SAE_rightMargin, METRIC_DEFAULT_DOCUMENT_RIGHT_MARGIN
	mov	ds:[di].SAE_bottomMargin, METRIC_DEFAULT_DOCUMENT_BOTTOM_MARGIN
notMetricMapBlock:
	pop	si, ds

	; Duplicate attribute blocks and attach and fill in map block

	mov	bx, handle CharAttrElementTemp
	call	DuplicateAndAttachData		;ax = vm block
	mov	es:MBH_charAttrElements, ax

	mov	bx, handle ParaAttrElementUSTemp
	jcxz	noMetricParaAttr
	mov	bx, handle ParaAttrElementMetricTemp
noMetricParaAttr:
	call	DuplicateAndAttachData		;ax = vm block
	mov	es:MBH_paraAttrElements, ax

	mov	bx, handle GraphicElementTemp
	call	DuplicateAndAttachData		;ax = vm block
	mov	es:MBH_graphicElements, ax

	mov	bx, handle TypeElementTemp
	call	DuplicateAndAttachData		;ax = vm block
	mov	es:MBH_typeElements, ax

	mov	bx, handle NameElementTemp
	call	DuplicateAndAttachData		;ax = vm block
	mov	es:MBH_nameElements, ax

	mov	bx, handle TextStyleTemp
	call	DuplicateAndAttachData		;ax = vm block
	mov	es:MBH_textStyles, ax
	mov	dx, offset TextStyleArray
	call	LocalizeNameArray

	mov	bx, handle LineAttrElementTemp
	call	DuplicateAndAttachData		;ax = vm block
	mov	es:MBH_lineAttrElements, ax

	mov	bx, handle AreaAttrElementTemp
	call	DuplicateAndAttachData		;ax = vm block
	mov	es:MBH_areaAttrElements, ax

	mov	bx, handle GraphicStyleTemp
	call	DuplicateAndAttachData		;ax = vm block
	mov	es:MBH_graphicStyles, ax
	mov	dx, offset GraphicStyleArray
	call	LocalizeNameArray


	; Duplicate GrObj block and attach, initialize body and attr manager

	mov	bx, handle BodyRulerTempUI
	call	DuplicateAndAttachObj		;ax = vm handle, bx = mem handle
	mov	es:MBH_grobjBlock, ax

	push	si, bp

	; Initialize the bounds of the body

	sub	sp, size RectDWord
	mov	bp, sp
	push	bx				;save mem handle
	call	GetDefaultWidthHeight		;cx, dx = size
	mov	ss:[bp].RD_right.low, cx
	clr	ax
	mov	ss:[bp].RD_right.high, ax
	clrdw	ss:[bp].RD_bottom, ax
	clrdw	ss:[bp].RD_left, ax
	clrdw	ss:[bp].RD_top, ax
	mov	ax, MSG_GB_SET_BOUNDS
	pop	bx
	mov	si, offset MainBody
	clr	di
	call	ObjMessage
	add	sp, size RectDWord

	; Initialize the attribute arrays in the attribute manager

	sub	sp, size GrObjAttributeManagerArrayDesc
	mov	bp, sp
	mov	ax, es:MBH_lineAttrElements
	mov	ss:[bp].GOAMAD_lineAttrArrayHandle, ax
	mov	ss:[bp].GOAMAD_lineDefaultElement, LINE_ATTR_HOTSPOT
	mov	ax, es:MBH_areaAttrElements
	mov	ss:[bp].GOAMAD_areaAttrArrayHandle, ax
	mov	ss:[bp].GOAMAD_areaDefaultElement, AREA_ATTR_HOTSPOT
	mov	ax, es:MBH_graphicStyles
	mov	ss:[bp].GOAMAD_grObjStyleArrayHandle, ax
	mov	ax, es:MBH_charAttrElements
	mov	ss:[bp].GOAMAD_charAttrArrayHandle, ax
	mov	ss:[bp].GOAMAD_charDefaultElement, CHAR_ATTR_NORMAL
	mov	ax, es:MBH_paraAttrElements
	mov	ss:[bp].GOAMAD_paraAttrArrayHandle, ax
	mov	ss:[bp].GOAMAD_paraDefaultElement, PARA_ATTR_NORMAL
	mov	ax, es:MBH_typeElements
	mov	ss:[bp].GOAMAD_typeArrayHandle, ax
	mov	ss:[bp].GOAMAD_typeDefaultElement, TYPE_ATTR_NORMAL
	mov	ax, es:MBH_graphicElements
	mov	ss:[bp].GOAMAD_graphicArrayHandle, ax
	mov	ax, es:MBH_nameElements
	mov	ss:[bp].GOAMAD_nameArrayHandle, ax
	mov	ax, es:MBH_textStyles
	mov	ss:[bp].GOAMAD_textStyleArrayHandle, ax
	mov	ax, MSG_GOAM_ATTACH_AND_CREATE_ARRAYS
	mov	si, offset AttributeManager
	clr	di
	call	ObjMessage
	add	sp, size GrObjAttributeManagerArrayDesc
	pop	si, bp

	; Create a new article

	push	es:[LMBH_handle]
	mov	bx, handle MainArticleName
	call	MemLock
	mov	es, ax
	mov	di, offset MainArticleName
	mov	di, es:[di]
	call	CreateNewArticle
	call	MemUnlock
	pop	bx
	call	MemDerefES

	; Intialize the new section

	clr	ax
	call	InitNewSection

	call	VMDirty
	call	VMUnlock

	call	AcceptUndo

	clc
	ret

StudioDocumentInitializeDocumentFile	endm

GetDefaultWidthHeight	proc	near
	uses	ds, si
	.enter

	sub	sp, size PageSizeReport
	segmov	ds, ss
	mov	si, sp				;ds:si <- PageSizeReport
	call	SpoolGetDefaultPageSizeInfo
	mov	cx, ds:[si].PSR_width.low
	mov	dx, ds:[si].PSR_height.low
	add	sp, size PageSizeReport

	.leave
	ret
GetDefaultWidthHeight	endp

DocCreate ends

DocManipCommon segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendPageSizeToView

DESCRIPTION:	Send the current page size to the view

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es - map block (locked)

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
SendPageSizeToView	proc	far	uses ax, bx, cx, dx, si, di
params		local	AddVarDataParams
pageSize	local	XYSize
	class	StudioDocumentClass
	.enter

EC <	call	AssertIsStudioDocument					>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].SDI_pageHeight
	mov	pageSize.XYS_height, ax
	mov	ax, ds:[di].SDI_size.PD_x.low
	mov	pageSize.XYS_width, ax

	lea	ax, pageSize
	movdw	params.AVDP_data, ssax
	mov	params.AVDP_dataSize, size XYSize
	mov	params.AVDP_dataType, ATTR_GEN_VIEW_PAGE_SIZE \
				      or mask VDF_SAVE_TO_STATE

	mov	bx, ds:[di].GDI_display
	mov	si, offset MainView
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	mov	di, mask MF_STACK or mask MF_CALL
	push	bp
	lea	bp, params
	call	ObjMessage
	pop	bp

	.leave
	ret

SendPageSizeToView	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendDocumentSizeToView

DESCRIPTION:	Send the current document size to the content

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es - map block (locked)

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
SendDocumentSizeToView	proc	far	uses ax, bx, di
	class	StudioDocumentClass
	.enter

EC <	call	AssertIsStudioDocument					>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].SDI_suspendCount
	jnz	suspended

	test	ds:[di].SDI_state, mask SDS_SUSPENDED_FOR_APPENDING_REGIONS
	jnz	suspended

EC <	test	ds:[di].SDI_state, mask SDS_SEND_SIZE_PENDING		>
EC <	ERROR_NZ SEND_SIZE_LOGIC_ERROR					>

	call	ReallySendDocumentSizeToView

done:
	.leave
	ret

suspended:
	ornf	ds:[di].SDI_state, mask SDS_SEND_SIZE_PENDING
	jmp	done

SendDocumentSizeToView	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ReallySendDocumentSizeToView
DESCRIPTION:	Do the actual work of sending the document size to the view

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es - map block (locked)

RETURN:
	none

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/17/92		Initial version

------------------------------------------------------------------------------@
ReallySendDocumentSizeToView	proc	far uses cx, dx, di
	class	StudioDocumentClass
	.enter

EC <	call	AssertIsStudioDocument					>

	; if we're not in page mode then bail

	cmp	es:MBH_displayMode, VLTDM_PAGE
	jnz	done

	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock

	mov_tr	bx, ax
	mov	ax, offset MainBody		;bxax = body

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GDI_display
	mov	dx, offset MainView		;cxdx = display

	call	SetViewSize			;dxcx = width, bxax = height

	; copy the size into our instance data

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	ds:[di].SDI_size.PD_x, dxcx
	movdw	ds:[di].SDI_size.PD_y, bxax

done:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, es:MBH_pageSize.XYS_height
	mov	ds:[di].SDI_pageHeight, ax

	.leave
	ret

ReallySendDocumentSizeToView	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetViewSize

DESCRIPTION:	Send the size of a view

CALLED BY:	INTERNAL

PASS:
	bxax - grobj body
	cxdx - display

RETURN:
	dxcx - width (without margins)
	bxax - height (without margins)

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
SetViewSize	proc	far	uses si, di, bp
	.enter

	sub	sp, size RectDWord
	mov	bp, sp

	mov_tr	si, ax
	mov	ax, MSG_GB_GET_BOUNDS
	clr	di
	call	ObjMessage

	; add in page margins

	pushdw	ss:[bp].RD_right		;width
	pushdw	ss:[bp].RD_bottom		;height
	subdw	ss:[bp].RD_left, PAGE_BORDER_SIZE
	subdw	ss:[bp].RD_top, PAGE_BORDER_SIZE
	adddw	ss:[bp].RD_right, PAGE_BORDER_SIZE
	adddw	ss:[bp].RD_bottom, PAGE_BORDER_SIZE

	movdw	bxsi, cxdx			;bxsi = view
	mov	ax, MSG_GEN_VIEW_SET_DOC_BOUNDS
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	mov	dx, size RectDWord
	call	ObjMessage

	popdw	bxax				;bxax = height
	popdw	dxcx				;dxcx = width

	add	sp, size RectDWord

	.leave
	ret

SetViewSize	endp

DocManipCommon ends

DocPageCreDest segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	SuspendDocument

DESCRIPTION:	Suspend the document, its articles and its body

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es - map block (locked)

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
	Tony	6/17/92		Initial version

------------------------------------------------------------------------------@
SuspendDocument	proc	far	uses ax, bx, cx, dx, si, di, bp
	class	StudioDocumentClass
	.enter
EC <	call	AssertIsStudioDocument					>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	inc	ds:[di].SDI_suspendCount
	cmp	ds:[di].SDI_suspendCount, 1
	jnz	done

	mov	ax, MSG_META_SUSPEND
	mov	di, mask MF_RECORD
	call	SendToAllArticles

	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock
	mov_tr	bx, ax
	mov	si, offset MainBody
	mov	ax, MSG_META_SUSPEND
	clr	di
	call	ObjMessage

done:
	.leave
	ret

SuspendDocument	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UnsuspendDocument

DESCRIPTION:	Unsuspend the document, its articles and its body

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es - map block (locked)

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
	Tony	6/17/92		Initial version

------------------------------------------------------------------------------@
UnsuspendDocument	proc	far	uses ax, bx, cx, dx, si, di, bp
	class	StudioDocumentClass
	.enter
EC <	call	AssertIsStudioDocument					>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	dec	ds:[di].SDI_suspendCount
	jnz	done

	test	ds:[di].SDI_state, mask SDS_SUSPENDED_FOR_APPENDING_REGIONS
	jnz	noSendSize
	test	ds:[di].SDI_state, mask SDS_SEND_SIZE_PENDING
	jz	noSendSize
	andnf	ds:[di].SDI_state, not mask SDS_SEND_SIZE_PENDING
	call	ReallySendDocumentSizeToView
noSendSize:

	mov	ax, MSG_META_UNSUSPEND
	mov	di, mask MF_RECORD
	call	SendToAllArticles

	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock
	mov_tr	bx, ax
	mov	si, offset MainBody
	mov	ax, MSG_META_UNSUSPEND
	clr	di
	call	ObjMessage

done:
	.leave
	ret

UnsuspendDocument	endp

DocPageCreDest ends

DocCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentSetDocBounds -- MSG_VIS_CONTENT_SET_DOC_BOUNDS
						for StudioDocumentClass

DESCRIPTION:	Intercept notification when the article (in galley or
		draft mode) is telling the view how big it is 

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	bp - RectDWord

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/ 6/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentSetDocBounds	method dynamic	StudioDocumentClass,
					MSG_VIS_CONTENT_SET_DOC_BOUNDS

	movdw	cxbx, ss:[bp].RD_right
	movdw	ds:[di].SDI_size.PD_x, cxbx
	movdw	cxbx, ss:[bp].RD_bottom
	movdw	ds:[di].SDI_size.PD_y, cxbx

	mov	di, offset StudioDocumentClass
	GOTO	ObjCallSuperNoLock

StudioDocumentSetDocBounds	endm

DocCommon ends
