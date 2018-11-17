COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetInit.asm

AUTHOR:		Gene Anderson, Feb 27, 1991

ROUTINES:
Name				Description
----				-----------
MSG_SPREADSHEET_READ_CACHED_DATA  Force reading of cached data
MSG_SPREADSHEET_WRITE_CACHED_DATA Force writing of cached data
MSG_SPREADSHEET_ATTACH_UI	Attach UI to spreadsheet object
MSG_SPREADSHEET_ATTACH_FILE	Attach (new) file to spreadsheet object

MSG_VIS_OPEN			Handle visual initialization of spreadsheet
MSG_VIS_CLOSE			Handle visual closing down of spreadsheet

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/27/91		Initial revision

DESCRIPTION:
	Initialization and rarely used routines for SpreadsheetClass

	$Id: spreadsheetInit.asm,v 1.1 97/04/07 11:13:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


InitCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the spreadsheet object
CALLED BY:	MSG_META_INITIALIZE

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
	eca	11/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetInitialize	method dynamic SpreadsheetClass, \
						MSG_META_INITIALIZE
	;
	; Let our superclass do its thing
	;
	mov	di, offset SpreadsheetClass
	call	ObjCallSuperNoLock
	;
	; Initialze our part
	;
	mov	si, ds:[si]
	add	si, ds:[si].Spreadsheet_offset
	ornf	ds:[si].SSI_attributes, mask SA_TARGETABLE
	ret
SpreadsheetInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle visual initialization of Spreadsheet object
CALLED BY:	MSG_VIS_OPEN

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
	eca	7/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetVisOpen	method dynamic SpreadsheetClass, \
						MSG_VIS_OPEN
	;
	; Let our superclass do its thing
	;
	mov	di, offset SpreadsheetClass
	call	ObjCallSuperNoLock

	mov	si, ds:[si]
	add	si, ds:[si].Spreadsheet_offset
	;
	; Any GState already made?
	;
	tst	ds:[si].SSI_gstate
	jz	noGState
	;
	; Destroy the old GState, and re-up the reference count
	;
	call	DestroyGStateFar
	call	CreateGStateFar
noGState:
	call	CreateGStateFar

	;
	; Make the spreadsheet the focus
	;
	call	SpreadsheetGrabFocus

	ret
SpreadsheetVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle visual  closing of Spreadsheet object
CALLED BY:	MSG_VIS_CLOSE

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
	eca	7/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetVisClose	method dynamic SpreadsheetClass, \
						MSG_VIS_CLOSE
	push	si
	mov	si, di				;ds:si <- ptr to Spreadsheet
	;
	; Destroy our cached GState
	;
	call	DestroyGStateFar
	;
	; Free the cached calculation lists.
	;
	clr	bx
	xchg	bx, ds:[si].SSI_ancestorList	;bx <- handle; mem <- NULL
	tst	bx				;any ancestor list?
	jz	skipAncestorFree		;branch if no ancestor list
	call	MemFree				;free the ancestor list
skipAncestorFree:

	clr	bx
	xchg	bx, ds:[si].SSI_childList	;bx <- handle; mem <- NULL
	tst	bx				;any child list?
	jz	skipChildFree			;branch if no child list
	call	MemFree				;free the child list
skipChildFree:

	clr	bx
	xchg	bx, ds:[si].SSI_finalList	;bx <- handle; mem <- NULL
	tst	bx				;any final list?
	jz	skipFinalFree			;branch if no final list
	call	MemFree				;free the final list
skipFinalFree:
	;
	; Let our superclass do its thing (last)
	;
	pop	si
	mov	di, offset SpreadsheetClass
	GOTO	ObjCallSuperNoLock
SpreadsheetVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine for initializing a spreadsheet file
CALLED BY:	EXTERNAL

PASS:		ss:bp - ptr to SpreadsheetInitFileData
RETURN:		ax - VM handle of spreadsheet map
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Does not require a spreadsheet object, only a VM file
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetInitFile	proc	far
	uses	bx, cx, dx, si, di, bp, es
	class	SpreadsheetClass

	.enter

	mov	bx, ss:[bp].SIFD_file		;bx <- VM file handle
	push	ss:[bp].SIFD_numRows
	push	ss:[bp].SIFD_numCols

	call	InitHeaderBlock			;spreadsheet file header
	pop	cx				;cx <- # of columns
	pop	dx				;dx <- # of rows
	push	ax				;save VM handle of map

	push	es
	segmov	es, cs
	mov	di, offset defaultCellAttrs	;es:di <- ptr to default style
FXIP<	push	cx							>
FXIP<	mov	cx, size CellAttrs		;cx = size of data to copy  >
FXIP<	call	SysCopyToStackESDI		;es:di = data on stack	>
	call	StyleArrayInit			;style token array
FXIP<	call	SysRemoveFromStack		;release stack space	>
FXIP<	pop	cx							>
	pop	es
	mov	es:SMB_styleArray, ax
	call	NameInit			;names
	mov	es:SMB_nameArray, ax
	call	FloatFormatInit		;number formats
	mov	es:SMB_formatArray, ax
	call	RowColArrayInit			;row/column arrays
	mov	es:SMB_rowArray, ax
	;
	; Mark the map block as dirty since we have changed it
	;
	call	VMDirty				;dirty the block
	call	VMUnlock			;unlock the block

	pop	ax				;ax <- VM handle of map

	.leave
	ret
SpreadsheetInitFile	endp

defaultCellAttrs	CellAttrs <
	<>,
	<<C_BLACK,CF_INDEX,0,0>,SDM_100>,
	<<C_WHITE,CF_INDEX,0,0>,SDM_100>,
	SPREADSHEET_DEFAULT_FONT,
	SPREADSHEET_DEFAULT_POINTSIZE*8,
	,
	,
	<<C_BLACK,CF_INDEX,0,0>,SDM_100>,
	J_GENERAL,
	FORMAT_ID_FIXED,
	<0,0>,			;track kerning
	FW_NORMAL,		;font weight
	FWI_MEDIUM,		;font width
	0
>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitHeaderBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the spreadsheet's header block
CALLED BY:	SpreadsheetInitDocument()

PASS:		bx - VM file handle
		ss:bp - ptr to SpreadsheetInitFileData
RETURN:		ax - VM handle of header block
		bp - VM memory handle of header block
		es - seg addr of header block
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitHeaderBlock	proc	near
	uses	di
	class	SpreadsheetClass
	.enter

	;
	; Zero out the array of block handles in the header block.
	;
	clr	ax				;ax <- no user ID
	mov	cx, size SpreadsheetMapBlock	;cx <- size of the block
	call	VMAlloc				;allocate a block
	push	ax				;save VM handle
	push	bp				;save frame ptr
	call	VMLock
	mov	es, ax				;es <- seg addr of block

	clr	di
	clr	al				;al <- byte to store
	rep	stosb				;Zero out the entire block
	mov	cx, bp				;cx <- VM memory handle
	pop	bp				;ss:bp <- params
	;
	; Store spreadsheet options
	;
	mov	ax, ss:[bp].SIFD_drawFlags
	mov	es:SMB_drawFlags, ax		;store SpreadsheetDrawFlags
	;
	; Set the bounds
	;
EC <	cmp	ss:[bp].SIFD_numRows, LARGEST_ROW+1>
EC <	ERROR_A	TOO_MANY_SSHEET_ROWS		;>
EC <	cmp	ss:[bp].SIFD_numCols, LARGEST_COLUMN+1>
EC <	ERROR_A	TOO_MANY_SSHEET_COLUMNS		;>
	mov	ax, ROW_HEIGHT_DEFAULT		;ax <- default row height
	mul	ss:[bp].SIFD_numRows		;dx:ax <- height of ssheet
	movdw	es:SMB_bounds.RD_bottom, dxax
	mov	ax, COLUMN_WIDTH_DEFAULT	;ax <- default column width
	mul	ss:[bp].SIFD_numCols		;dx:ax <- width of ssheet
	movdw	es:SMB_bounds.RD_right, dxax
	;
	; Initialize special parts of header block
	;
	mov	es:SMB_header.CR_start.CR_row, -1
	mov	es:SMB_footer.CR_start.CR_row, -1
	mov	bp, cx				;bp <- VM memory handle
	pop	ax				;ax <- VM handle of map

	.leave
	ret
InitHeaderBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetReadCachedData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force reading of data cached in the spreadsheet object.
CALLED BY:	MSG_SPREADSHEET_READ_CACHED_DATA

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		dx - VM file handle
		cx - VM handle of map block

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetReadCachedData	method dynamic SpreadsheetClass, \
						MSG_SPREADSHEET_READ_CACHED_DATA
	uses	ax, cx, dx, bp, di, si, es
	.enter

	mov	ax, si
	mov	si, di				;ds:si <- ptr to instance data

	mov	ds:[si].SSI_chunk, ax		;save our chunk handle
	mov	ds:[si].SSI_cellParams.CFP_file, dx
	mov	bx, dx				;bx <- VM file handle
	mov	ds:[si].SSI_cellParams.CFP_flags, 0

	mov	ax, cx				;ax <- VM handle of map
	mov	ds:[si].SSI_mapBlock, ax
	call	VMLock
	mov	es, ax				;es <- seg addr of map

	;
	; ds:si = Pointer to the spreadsheet instance
	; es:0 = Pointer to the map block
	;

	;
	; Copy the various special VM block handles
	;
	mov	ax, es:SMB_styleArray
	mov	ds:[si].SSI_styleArray, ax
	mov	ax, es:SMB_rowArray
	mov	ds:[si].SSI_rowArray, ax
	mov	ax, es:SMB_formatArray
	mov	ds:[si].SSI_formatArray, ax
	mov	ax, es:SMB_nameArray
	mov	ds:[si].SSI_nameArray, ax
	;
	; Copy the various flags.
	;
	mov	ax, es:SMB_drawFlags
	mov	ds:[si].SSI_drawFlags, ax
	mov	ax, es:SMB_flags	; Get these flags for saving later
	mov	ds:[si].SSI_flags, ax	;save the new flags
	;
	; Copy the header and footer rectangles.
	;
	segxchg	ds, es			; ds <- ptr to map item
					; es <- ptr to instance data
	mov	di, si			; ds:si <- ptr to map item

	push	di
	lea	di, es:[di].SSI_header	; es:di <- ptr to header in spreadsheet
	mov	si, offset SMB_header	; ds:si <- ptr to header in map item

	mov	cx, 2 * (size CellRange)
	rep	movsb			; Copy over the header/footer
	pop	di

	;
	; Copy the circularity counter and the convergence value.
	;
	push	di
	mov	ax, ds:SMB_circCount
	mov	es:[di].SSI_circCount, ax
	
	mov	cx, size FloatNum	; cx <- # of bytes to copy
	mov	si, offset SMB_converge
	lea	di, es:[di].SSI_converge
	rep	movsb			; Copy the convergence value
	pop	di
	;
	; Now copy the row-blocks.
	;
	push	di
	lea	di, es:[di].SSI_cellParams.CFP_rowBlocks
	mov	si, offset SMB_rowGroups
	mov	cx, (size RowBlockList)/(size word)
	rep	movsw
CheckHack <((size RowBlockList) and 1) eq 0>
	pop	di
	;
	; Finally, copy the bounds
	;
	lea	di, es:[di].SSI_bounds
	mov	si, offset SMB_bounds
	mov	cx, (size RectDWord)/(size word)
	rep	movsw
CheckHack <((size RectDWord) and 1) eq 0>

	call	VMUnlock

	.leave
	ret
SpreadsheetReadCachedData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetWriteCachedData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force writing of data cached in the spreadsheet object
CALLED BY:	MSG_SPREADSHEET_WRITE_CACHED_DATA

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		dx - VM file handle
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetWriteCachedData	method dynamic SpreadsheetClass, \
					MSG_SPREADSHEET_WRITE_CACHED_DATA
	mov	si, di				;ds:si <- instance ptr

	mov	ds:[si].SSI_cellParams.CFP_file, dx
	mov	bx, dx				;bx <- VM file handle
	;
	; Clear the dirty bit and copy the data out.
	;
	and	ds:[si].SSI_cellParams.CFP_flags, not mask CFPF_DIRTY

	mov	ax, ds:[si].SSI_mapBlock
	call	VMLock
	mov	es, ax
	;
	; ds:si = Pointer to spreadsheet instance
	; es:0 = Pointer to map item.
	;
	mov	ax, ds:[si].SSI_flags	; Copy over the flags
	mov	es:SMB_flags, ax
	
	mov	ax, ds:[si].SSI_drawFlags
	mov	es:SMB_drawFlags, ax

	;
	; Copy the header and footer rectangles.
	;
	push	si			; Save offsets
	lea	si, ds:[si].SSI_header	; ds:si <- ptr to header in spreadsheet
	mov	di, offset SMB_header	; es:di <- ptr to header in map item
	mov	cx, 2 * (size CellRange)
	rep	movsb			; Copy over the header/footer
	pop	si			; Restore offsets

	;
	; Copy over the row-blocks.
	;
	push	si			; Save offsets
	mov	di, offset SMB_rowGroups
	lea	si, ds:[si].SSI_cellParams.CFP_rowBlocks
	mov	cx, (size RowBlockList)/(size word)
	rep	movsw			; Copy the data
CheckHack <((size RowBlockList) and 1) eq 0>
	pop	si			; Restore offsets
	;
	; Copy the bounds
	;
	push	si
	mov	di, offset SMB_bounds
	lea	si, ds:[si].SSI_bounds
	mov	cx, (size RectDWord)/(size word)
	rep	movsw
CheckHack <((size RectDWord) and 1) eq 0>
	pop	si
	
	;
	; Copy the circularity counter.
	;
	mov	ax, ds:[si].SSI_circCount
	mov	es:SMB_circCount, ax

	;
	; Copy the convergence value.
	;
	mov	di, offset SMB_converge
	lea	si, ds:[si].SSI_converge
	mov	cx, size FloatNum
	rep	movsb			; Copy the data

	call	VMDirty			; Dirty the map item
	call	VMUnlock		; Unlock the map item

	ret
SpreadsheetWriteCachedData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetAttachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach UI, non-visual data to spreadsheet object
CALLED BY:	MSG_SPREADSHEET_ATTACH_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		cx - handle of SpreadsheetSetupData block
		dx - VM file handle

RETURN:		none
DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetAttachUI	method dynamic SpreadsheetClass, \
						MSG_SPREADSHEET_ATTACH_UI

	mov	ds:[di].SSI_cellParams.CFP_file, dx
	mov	bx, cx				;bx <- handle of setup block
	;
	; Copy setup data into object
	;
	call	MemLock				;lock me jesus

	mov	es, ax				;es <- seg addr of data
	movdw	cxdx, es:[SSD_chartBody]
	movdw	ds:[di].SSI_chartBody, cxdx

	call	MemFree				;free me jesus

	; Send a message to the chart body so it will notify us when
	; charts become deleted
if _CHARTS
	
	mov	bx, cx
	mov	cx, ds:[LMBH_handle]		; ^lcx:dx - spreadsheet
	xchg	si, dx				; ^lbx:si - chart body

	mov	ax, MSG_CHART_BODY_ATTACH
	mov	bp, MSG_SPREADSHEET_DELETE_CHART
	clr	di
	call	ObjMessage
endif

	ret
SpreadsheetAttachUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetAttachFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach a (new) file to the spreadsheet
CALLED BY:	MSG_SPREADSHEET_ATTACH_FILE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		dx - VM file handle
		cx - VM handle of map block
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetAttachFile	method dynamic SpreadsheetClass, \
						MSG_SPREADSHEET_ATTACH_FILE
	mov	ds:[di].SSI_cellParams.CFP_file, dx
	mov	ds:[di].SSI_mapBlock, cx
	ret
SpreadsheetAttachFile	endm

InitCode	ends
