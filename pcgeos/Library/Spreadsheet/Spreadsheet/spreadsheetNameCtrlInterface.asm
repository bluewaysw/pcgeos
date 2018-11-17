COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 6/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial revision

DESCRIPTION:
		
	$Id: spreadsheetNameCtrlInterface.asm,v 1.1 97/04/07 11:14:18 newdeal Exp $

-------------------------------------------------------------------------------@

SpreadsheetNameCode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	NameInitNameList

DESCRIPTION:	This routine is necessarily here because there is no 2 way
		communication between the controller and the target spreadsheet.
		Ie. the controller cannot do an MF_CALL to the target to get
		the number of names.

CALLED BY:	INTERNAL (MSG_SPREADSHEET_INIT_NAME_LIST)

PASS:		cx:dx - controller OD

RETURN:		nothing

DESTROYED:	everything (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

NameInitDefineNameList	method	dynamic SpreadsheetClass,
			MSG_SPREADSHEET_INIT_NAME_LIST
	push	cx,dx
	mov	ax, MSG_SPREADSHEET_GET_NAME_COUNT
	call	ObjCallInstanceNoLock	; dx <- defined names, bp <- undef names

	pop	bx,si
	mov	cx, dx			; cx <- name count

	mov	ax, MSG_DNC_UPDATE_UI_WITH_NUM_NAMES
	clr	di
	call	ObjMessage
	ret
NameInitDefineNameList	endm

NameInitChooseNameList	method	dynamic SpreadsheetClass,
			MSG_SPREADSHEET_INIT_CHOOSE_NAME_LIST
	push	cx,dx
	mov	ax, MSG_SPREADSHEET_GET_NAME_COUNT
	call	ObjCallInstanceNoLock	; dx <- defined names, bp <- undef names

	pop	bx,si
	mov	cx, dx			; cx <- name count

	mov	ax, MSG_CNC_UPDATE_UI_WITH_NUM_NAMES
	clr	di
	call	ObjMessage
	ret
NameInitChooseNameList	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	NameRequestEntryMoniker

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_SPREADSHEET_NAME_REQUEST_ENTRY_MONIKER)

PASS:		cx:dx - OD of list containing the names
		bp - entry number of name to provide

RETURN:		nothing

DESTROYED:	everything (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

NameRequestEntryMoniker	method	dynamic SpreadsheetClass,
			MSG_SPREADSHEET_NAME_REQUEST_ENTRY_MONIKER
	mov	ax, bp			; ax <- entry number

	locals	local	SpreadsheetNameParameters

	.enter

	push	cx,dx			; save list OD
	;
	; get copy of name pointed to by cx:dx
	;
	mov	locals.SNP_listEntry, ax
	mov	locals.SNP_flags, mask NAF_NAME	; return text of name
	
	push	bp
	mov	ax, MSG_SPREADSHEET_GET_NAME_INFO
	mov	dx, ss
	lea	bp, locals		; dx:bp <- SpreadsheetNameParameters
	call	ObjCallInstanceNoLock
	pop	bp

	pop	bx,si			; bx:si <- list OD
	push	bp
	mov	cx, ss
	lea	dx, locals.SNP_text	; cx:dx <- name
	mov	bp, locals.SNP_listEntry; bp <- list entry
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL
	call	ObjMessage		; call the list
	pop	bp

	.leave
	ret
NameRequestEntryMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSingleSelectionIfAnyItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixes bug #31031.  Look it up.

CALLED BY:	NameRequestEntryMoniker

PASS:		^lbx:si = list OD
		^lcx:dx = spreadsheet

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetAddNameWithParamBlock

DESCRIPTION:	For the case when the SpreadsheetNameParameters cannot be
		passed on the stack, this routine is used.
		SpreadsheetNameParameters is passed in as a memory block.

CALLED BY:	INTERNAL (MSG_SPREADSHEET_ADD_NAME_WITH_PARAM_BLK)

PASS:		*ds:si	= Instance ptr
		ds:di	= Pointer to spreadsheet instance
		cx:dx - OD of controller
		bp - mem han of blk containing SpreadsheetNameParameters

RETURN:		mem block freed

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SpreadsheetAddNameWithParamBlock	method	SpreadsheetClass,
					MSG_SPREADSHEET_ADD_NAME_WITH_PARAM_BLK
	locals	local	SpreadsheetNameParameters
	mov	bx, bp			; bx <- mem han
	.enter

	push	bx			; save mem han
	push	cx,dx			; save controller OD

	;
	; copy SpreadsheetNameParameters onto the stack
	;
	call	MemLock
	push	ds,si
	mov	ds, ax
	clr	si
	segmov	es, ss, dx
	lea	di, locals
	mov	cx, size SpreadsheetNameParameters
	rep	movsb
	pop	ds,si

ifdef GPC
	lea	ax, locals
	call	MakeAbsolute
endif

	;
	; add name
	; pass dx:bp = SpreadsheetNameParameters
	;
	push	bp
	lea	bp, locals
	mov	ax, MSG_SPREADSHEET_ADD_NAME
	call	ObjCallInstanceNoLock	; cx <- entry number
					; dx <- # of defined names
					; bp <- # of undefined names
	pop	bp

	pop	bx,di			; bx:si <- controller OD
	cmp	cx, -1			; error?
	je	errorAddingName

	mov	ax, mask SNF_NAME_CHANGE 
	call	SSNC_SendNotification
	jmp	short done

errorAddingName:
	; dl = ParserScannerEvaluatorError
	
	mov	si, di
	mov	ax, MSG_DNC_NAME_OP_ERROR
	mov	dh, -1			; flag adding name
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	pop	bx			; retrieve mem han
	call	MemFree
	.leave
	ret
SpreadsheetAddNameWithParamBlock	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetChangeNameWithParamBlock

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_SPREADSHEET_CHANGE_NAME_WITH_PARAM_BLK)

PASS:		*ds:si	= Instance ptr
		ds:di	= Pointer to spreadsheet instance
		cx:dx - OD of controller
		bp - mem han of blk containing SpreadsheetNameParameters

RETURN:		mem block freed

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SpreadsheetChangeNameWithParamBlock	method	SpreadsheetClass,
				MSG_SPREADSHEET_CHANGE_NAME_WITH_PARAM_BLK
	locals	local	SpreadsheetNameParameters
	mov	bx, bp			; bx <- mem han
	.enter

	push	bx			; save mem han
	push	cx,dx			; save controller OD

	;
	; copy SpreadsheetNameParameters onto the stack
	;
	call	MemLock
	push	ds,si
	mov	ds, ax
	clr	si
	segmov	es, ss, dx
	lea	di, locals
	mov	cx, size SpreadsheetNameParameters
	rep	movsb
	pop	ds,si

ifdef GPC
	lea	ax, locals
	call	MakeAbsolute
endif

	;
	; add name
	; pass dx:bp = SpreadsheetNameParameters
	;
	push	bp
	lea	bp, locals
	mov	ax, MSG_SPREADSHEET_CHANGE_NAME
	call	ObjCallInstanceNoLock	; cx <- entry number
					; dx <- # of defined names or error
	mov	ax, bp			; ax <- # of undefined names
	pop	bp

	pop	bx,di			; bx:si <- controller OD
	cmp	cx, -1			; error?
	je	errorChangingName

	mov	ax, mask SNF_NAME_CHANGE or mask SNF_EDIT_BAR
	call	SSNC_SendNotification

	jmp	short done

errorChangingName:
	; dl = ParserScannerEvaluatorError

	mov	si, di
	mov	ax, MSG_DNC_NAME_OP_ERROR
	clr	dh			; flag changing name
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	pop	bx			; retrieve mem han
	call	MemFree
	.leave
	ret
SpreadsheetChangeNameWithParamBlock	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetUpdateNameDefinition

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_SPREADSHEET_NAME_UPDATE_DEFINITION)

PASS:		cx:dx - OD of name definition text object
		bp - entry number

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@


if FULL_EXECUTE_IN_PLACE
idata	segment
endif

	LocalDefNLString	nullString, 0

if FULL_EXECUTE_IN_PLACE
idata	ends
endif


SpreadsheetUpdateNameDefinition	method	SpreadsheetClass, \
				MSG_SPREADSHEET_NAME_UPDATE_DEFINITION
	locals	local	SpreadsheetNameParameters
	mov	ax, bp			; ax <- entry number
	.enter

	cmp	ax, -1
	je	noDefn

	push	cx,dx			; save OD

	mov	locals.SNP_listEntry, ax
	mov	locals.SNP_flags, mask NAF_DEFINITION	; return text of defn
	push	bp
	mov	ax, MSG_SPREADSHEET_GET_NAME_INFO
	mov	dx, ss
	lea	bp, locals		; dx:bp <- SpreadsheetNameParameters
	call	ObjCallInstanceNoLock
	pop	bp

	pop	bx, si			; retrieve text object OD
	;
	; pass dx:bp = string
	;
	push	bp
	mov	dx, ss
	lea	bp, locals.SNP_definition
setText:
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx			; specify null terminated
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	.leave
	ret

noDefn:
	push	bp
	mov	si, dx
FXIP<	mov	bp, ds				;save ds value		>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefDS			;ds = dgroup		>
FXIP<	mov	dx, ds				;dx = dgroup		>
FXIP<	mov	ds, bp				;restore ds value	>
	mov	bx, cx				;^lbx:si = text obj
NOFXIP<	mov	dx, cs							>
	mov	bp, offset nullString
	jmp	short setText
	
SpreadsheetUpdateNameDefinition	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetUpdateName

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_SPREADSHEET_NAME_UPDATE_NAME)

PASS:		cx:dx - OD of name definition text object
		bp - entry number

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SpreadsheetUpdateName	method	SpreadsheetClass, \
				MSG_SPREADSHEET_NAME_UPDATE_NAME
	locals	local	SpreadsheetNameParameters
	mov	ax, bp			; ax <- entry number
	.enter

	push	cx,dx			; save OD

	mov	locals.SNP_listEntry, ax
	mov	locals.SNP_flags, mask NAF_NAME	; return text of defn
	push	bp
	mov	ax, MSG_SPREADSHEET_GET_NAME_INFO
	mov	dx, ss
	lea	bp, locals		; dx:bp <- SpreadsheetNameParameters
	call	ObjCallInstanceNoLock
	pop	bp

	pop	bx, si			; retrieve text object OD
	;
	; pass dx:bp = string
	;
	push	bp
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	lea	bp, locals.SNP_text
	clr	cx			; specify null terminated
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	.leave
	ret
SpreadsheetUpdateName	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetDeleteNameWithListEntry

DESCRIPTION:	Delete a name given the list entry number.

CALLED BY:	INTERNAL (MSG_SPREADSHEET_DELETE_NAME_WITH_LIST_ENTRY)

PASS:		cx:dx - controller OD
		bp - list entry

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SpreadsheetDeleteNameWithListEntry	method	dynamic SpreadsheetClass,
			MSG_SPREADSHEET_DELETE_NAME_WITH_LIST_ENTRY
	mov	ax, bp
	locals	local	SpreadsheetNameParameters
	.enter

	mov	locals.SNP_listEntry, ax

	push	bp
	mov	ax, MSG_SPREADSHEET_DELETE_NAME
	mov	dx, ss
	lea	bp, locals
	call	ObjCallInstanceNoLock	; dx <- # def, bp <- # undef
	pop	bp

	mov	ax, mask SNF_NAME_CHANGE
	call	SSNC_SendNotification

	.leave
	ret
SpreadsheetDeleteNameWithListEntry	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetGetNameWithListEntry

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_SPREADSHEET_GET_NAME_WITH_LIST_ENTRY)

PASS:		cx - memory block containing SSDNCommand structure with these
		    fields filled in:
		    SSDNC_listEntry
		    SSDNC_controllerOD
		    SSDNC_msgToSendBack

RETURN:		SSDNC_msgToSendBack sent to SSDNC_controllerOD with
		    cx = SSDNCommand struct han
		SSDNC_dataBlk = handle of me block containing name

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version
	witt	11/93		DBCS-ized
-------------------------------------------------------------------------------@

SpreadsheetGetNameWithListEntry	method	dynamic SpreadsheetClass,
			MSG_SPREADSHEET_GET_NAME_WITH_LIST_ENTRY
	locals	local	SpreadsheetNameParameters
	.enter

	mov	bx, cx			; bx <- SSDNCommand han
	push	bx			; save handle
	call	MemLock
	mov	es, ax			; es:0 <- SSDNCommand
	mov	ax, es:SSDNC_listEntry

	mov	locals.SNP_listEntry, ax
	mov	locals.SNP_flags, mask NAF_NAME	; return text of defn
	push	bp
	mov	ax, MSG_SPREADSHEET_GET_NAME_INFO
	mov	dx, ss
	lea	bp, locals		; dx:bp <- SpreadsheetNameParameters
	call	ObjCallInstanceNoLock
	pop	bp

	;
	; allocate block
	; copy name
	;
	push	es			; save seg addr of SSDNCommand
SBCS<	mov	ax, MAX_NAME_LENGTH			>
DBCS<	mov	ax, MAX_NAME_LENGTH*(size wchar)	>
	mov	cx, mask HAF_LOCK shl 8
	call	MemAlloc
	push	bx			; save name blk han
	mov	es, ax
	clr	di

	segmov	ds, ss, si
	lea	si, locals.SNP_text

	LocalCopyString			; copy string and null

	pop	bx			; bx <- name blk han
	pop	es			; retrieve seg addr of SSDNCommand

	mov	es:SSDNC_dataBlk, bx	; store block handle
	mov	ax, es:SSDNC_msgToSendBack
	mov	cx, es:SSDNC_controllerOD.high
	mov	si, es:SSDNC_controllerOD.low

	pop	bx			; retrieve SSDNCommand han
	call	MemUnlock

	;
	; send message
	;
	xchg	cx, bx			; cx <- SSDNCommand han
	clr	di
	call	ObjMessage

	.leave
	ret
SpreadsheetGetNameWithListEntry	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSNC_SendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The name list has changed, send a notification to the
		name controllers.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	- spreadsheet instance 
		ax	- SpreadsheetNotifyFlags
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSNC_SendNotification		proc	near	
	uses 	si
	.enter

	mov	si, ds:[si]			
	add	si, ds:[si].Spreadsheet_offset 	; ds:si <- Spreadsheet instance
	call	SS_SendNotification

	.leave
	ret
SSNC_SendNotification		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeAbsolute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert cell reference to absolute, if needed

CALLED BY:	SpreadsheetAddNameWithParamBlock,
			SpreadsheetChangeNameWithParamBlock
PASS:		ss:ax - SpreadsheetNameParameters
		*ds:si	= spreadsheet
RETURN:		SNP_definition = converted to absolute if
			SNP_nameFlags = -1
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/11/91		Initial version
	brianc	1/20/99		adapted from ConvertToCellOrRange

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef GPC

MakeAbsoluteParams	union
    MAP_parseParams	SpreadsheetParserParameters <>
    MAP_evalParams	SpreadsheetEvalParameters <>
MakeAbsoluteParams	ends

MakeAbsolute	proc	near
	class	SpreadsheetClass
snpPtr		local	word	push	ax
params		local	MakeAbsoluteParams
parseBuffer	local	256 dup (TCHAR)
	uses	ax, bx, cx, dx, es, ds, si
	.enter
	;
	; Check if we need to do anything
	;
	mov	di, snpPtr
	cmp	ss:[di].SNP_nameFlags, -1
	jne	quit
	;
	; Initialize the frame
	;
	mov	ss:params.MAP_parseParams.SPP_text.segment, ss
	mov	ax, snpPtr
	add	ax, offset SNP_definition
	mov	ss:params.MAP_parseParams.SPP_text.offset,  ax
	mov	ss:params.MAP_parseParams.SPP_expression.segment, ss
	lea	ax, ss:parseBuffer
	mov	ss:params.MAP_parseParams.SPP_expression.offset, ax
	mov	ss:params.MAP_parseParams.SPP_exprLength, length parseBuffer
	mov	ss:params.MAP_parseParams.SPP_parserParams.PP_flags, mask PF_CELLS
	push	bp			; Save frame ptr
	lea	bp, ss:params		; ss:bp <- ptr to parameters
	mov	ax, MSG_SPREADSHEET_PARSE_EXPRESSION
	call	ObjCallInstanceNoLock	; Parse the expression
	pop	bp			; Restore frame ptr
	cmp	al, -1			; Check for an error
	jne	quit			; Quit on error
	;
	; The expression parsed, now we need to evaluate it.
	;
	mov	ss:params.MAP_evalParams.SEP_expression.segment, ss
	lea	ax, ss:parseBuffer
	mov	ss:params.MAP_evalParams.SEP_expression.offset, ax
	push	bp			; Save frame ptr
	lea	bp, ss:params		; ss:bp <- ptr to parameters
	mov	ax, MSG_SPREADSHEET_EVAL_EXPRESSION
	mov	cl, mask EF_KEEP_LAST_CELL
	call	ObjCallInstanceNoLock	; Evaluate the expression
	pop	bp			; Restore frame ptr
	cmp	al, -1			; Check for an error
	jne	quit			; Quit on error
	;
	; Make sure that the result is a range.
	;
	test	ss:params.CP_evalParams.SEP_result.ASE_type, mask ESAT_RANGE
	jz	quit			; nope, error
	mov	ax, ss:params.CP_evalParams.SEP_result.ASE_data.\
					ESAD_range.ERD_firstCell.CR_row
	mov	bx, ss:params.CP_evalParams.SEP_result.ASE_data.\
					ESAD_range.ERD_firstCell.CR_column
	mov	cx, ss:params.CP_evalParams.SEP_result.ASE_data.\
					ESAD_range.ERD_lastCell.CR_row
	mov	dx, ss:params.CP_evalParams.SEP_result.ASE_data.\
					ESAD_range.ERD_lastCell.CR_column
	andnf	ax, mask CRC_VALUE
	andnf	bx, mask CRC_VALUE
	andnf	cx, mask CRC_VALUE
	andnf	dx, mask CRC_VALUE
	segmov	es, ss
	mov	di, snpPtr
	add	di, offset SNP_definition
	cmp	ax, cx				; compare start/end row
	jne	storeRange
	cmp	bx, dx				; compare start/end column
	je	storeEnd
storeRange:
	call	storeCellRef
	LocalLoadChar	ax, C_COLON
	LocalPutChar	esdi, ax
storeEnd:
	mov	ax, cx
	mov	bx, dx
	call	storeCellRef
	LocalLoadChar	ax, C_NULL
	LocalPutChar	esdi, ax
quit:
	.leave
	ret

storeCellRef	label	near
	push	cx, dx
	push	ax				; save row
	LocalLoadChar	ax, '$'
	LocalPutChar	esdi, ax
	mov	ax, bx				; output column
	add	ax, 'A'
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, '$'
	LocalPutChar	esdi, ax
	pop	ax				; output row
	inc	ax				; row range is 1->N
	clr	dx, cx
	call	UtilHex32ToAscii
	add	di, cx
DBCS <	add	di, cx						>
	pop	cx, dx
	retn
MakeAbsolute	endp

endif

SpreadsheetNameCode	ends
