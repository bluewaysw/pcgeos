COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextTransfer
FILE:		ttCreate.asm

AUTHOR:		Tony Requist, 3/12/90

METHODS:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/12/89		Initial revision

DESCRIPTION:
	Transfer item creation stuff

	$Id: ttCreate.asm,v 1.1 97/04/07 11:19:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextTransfer segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateTransferFormatHeader

DESCRIPTION:	Create a transfer format header

CALLED BY:	INTERNAL

PASS:
	bx - VM file handle

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
CreateTransferFormatHeader	proc	near uses cx, dx, si, di, bp, ds, es
	.enter

	; allocate an block to hold the header

	mov	cx, size TextTransferBlockHeader
	clr	ax				;no user id
	call	VMAlloc
	push	ax				;save block handle
	call	VMLock
	call	VMDirty
	mov	ds, ax				;ds = block
	mov	es, ax

	; zero out block and setup VMChain header

	clr	ax
	clr	di
	mov	cx, (size TextTransferBlockHeader) / 2
	rep stosw
	mov	ds:[VMCT_meta].VMCL_next, VM_CHAIN_TREE
	mov	ds:[VMCT_offset], offset TTBH_text
	mov	ds:[VMCT_count], ((size TextTransferBlockHeader) - \
					(offset TTBH_firstVM)) / (size dword)

	call	VMDirty
	call	VMUnlock

	pop	ax				;ax = vm block handle

	.leave
	ret

CreateTransferFormatHeader	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextCreateTransferFormat --
			MSG_VIS_TEXT_CREATE_TRANSFER_FORMAT for VisTextClass

DESCRIPTION:	Create a text transfer format for a range of text

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The method

	dx - size CommonTransferParams (if called remotely)
	ss:bp - CommonTransferParams

RETURN:
	ax - block handle of newly created transfer block

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version

------------------------------------------------------------------------------@

VisTextCreateTransferFormat	proc	far
	class	VisTextClass
					; MSG_VIS_TEXT_CREATE_TRANSFER_FORMAT

getParams	local	VisTextGetTextRangeParameters
header		local	word
storageFlags	local	VisTextStorageFlags
vmMemHandle	local	hptr
optBlock	local	hptr

	push	bp
	mov	bx, size CommonTransferParams
	push	bx
	call	SwitchStackWithData

	.enter

	clr	optBlock

	mov	al, ds:[di].VTI_storageFlags
	mov	storageFlags, al

	mov	di, ss:[bp]			;ss:di = CommonTransferParams
	push	bp
	lea	bp, ss:[di].CTP_range
	clr	bx				;no context
	call	TA_GetTextRange
	pop	bp


	;
	; Get the range limit from the ini file.  
	;
	call	GetTextTransferRangeLimit	;axbx = rangelimit
	jc	ok				;no limit in ini file?
	;
	; Ok let's see if the transfer is larger then our limit.  If
	; it is, then let's warn the user that the range has been
	; reduced. 
	;
	subdw	axbx, ss:[di].CTP_range.VTR_end
	adddw	axbx, ss:[di].CTP_range.VTR_start;
	tst	ax
	jns	ok
	;
	; the selected range is too large, we need to reduce it.
	;
	adddw	ss:[di].CTP_range.VTR_end, axbx	; reduce the size of
						; the selection
	call	WarnUserRangeChanged

	;
	; change the selection to the new range that we plan on
	; copying.  This is important if we are doing a cut, since we
	; don't want to delete what we did not want to copy.
	;
	push	bp, cx, dx
	mov	dx, size VisTextRange
	sub	sp, dx
	mov	bp, sp
	movdw	ss:[bp].VTR_start, ss:[di].CTP_range.VTR_start, ax
	movdw	ss:[bp].VTR_end, ss:[di].CTP_range.VTR_end, ax
	
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
	add	sp, size VisTextRange
	pop	bp, cx, dx

ok:
	; first copy the text into a huge array

	mov	ax, ss:[di].CTP_vmFile
	mov	getParams.VTGTRP_textReference.TR_ref.\
					TRU_hugeArray.TRHA_file, ax
	mov	getParams.VTGTRP_textReference.TR_type, TRT_HUGE_ARRAY
	movdw	getParams.VTGTRP_range.VTR_start, ss:[di].CTP_range.VTR_start, ax
	movdw	getParams.VTGTRP_range.VTR_end, ss:[di].CTP_range.VTR_end, ax
	mov	getParams.VTGTRP_flags, mask VTGTRF_ALLOCATE \
					or mask VTGTRF_ALLOCATE_ALWAYS
	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE
	push	bp
	lea	bp, getParams
	call	ObjCallInstanceNoLock		;cx = huge array
	pop	bp

	; Added 8/26/99 by Tony for browser
	mov	ax, ATTR_VIS_TEXT_ALLOW_CROSS_SECTION_COPY
	call	ObjVarFindData
	jnc	noCrossSection
	push	cx
	mov	ax, ss:[di].CTP_vmFile		; file
	call	FilterSectionBreakFromHugeArray
	pop	cx
noCrossSection:

	; create a block "format header" block

	mov	bx, ss:[di].CTP_vmFile
	call	CreateTransferFormatHeader	;ax = block handle
	mov	header, ax

	; *** create needed structures ***

	push	bp
	call	VMLock
	mov	dx, bp
	pop	bp
	mov	vmMemHandle, dx
	mov	es, ax
	mov	es:TTBH_text.high, cx

	; temporarily fool the text object into thinking that it is attached
	; to the file in which we want to create the transfer format

	call	exchangeVMFile

	; create attribute stuff

	mov	cl, storageFlags
	test	cl, mask VTSF_STYLES
	jz	noStyles
	mov	bh, 1
	call	TA_CreateStyleArray
	mov	es:TTBH_styles.high, bx
noStyles:

	; first create char and para structures (they both have to exist
	; before we can actually copy any information to either)

	test	cl, mask VTSF_MULTIPLE_PARA_ATTRS
	jz	noParaAttr
	mov	bx, TAT_PARA_ATTRS or (TRUE shl 8)
	call	TA_CreateRunAndElementArrays	;ax = runs, bx = elements
	mov	es:TTBH_paraAttrRuns.high, ax
	mov	es:TTBH_paraAttrElements.high, bx
noParaAttr:

	test	cl, mask VTSF_MULTIPLE_CHAR_ATTRS
	jz	noCharAttr
	mov	bx, TAT_CHAR_ATTRS or (TRUE shl 8)
	call	TA_CreateRunAndElementArrays	;ax = runs, bx = elements
	mov	es:TTBH_charAttrRuns.high, ax
	mov	es:TTBH_charAttrElements.high, bx
noCharAttr:

	; hook the text object back to its real file

	call	exchangeVMFile

	; now copy over the character attribute information

						;ax already is runs
	test	cl, mask VTSF_MULTIPLE_CHAR_ATTRS
	jz	noCharAttr2
	mov	bx, offset VTI_charAttrRuns
	call	callCopyRun
noCharAttr2:

	; now copy over the para attr information

	test	cl, mask VTSF_MULTIPLE_PARA_ATTRS
	jz	noParaAttr2
	mov	ax, es:TTBH_paraAttrRuns.high
	mov	bx, offset VTI_paraAttrRuns
	call	callCopyRun
noParaAttr2:

	; copy over type information

	test	cl, mask VTSF_TYPES
	jz	noTypes

	call	exchangeVMFile
	mov	bh, 1				;create name array in vm block
	call	TA_CreateNameArray		;bx <- vm block of name array
	mov	es:TTBH_names.high, bx 
	mov	bx, TAT_TYPES or (TRUE shl 8)
	call	TA_CreateRunAndElementArrays	;ax = runs, bx = elements
	call	exchangeVMFile
	mov	es:TTBH_typeRuns.high, ax
	mov	es:TTBH_typeElements.high, bx
	mov	bx, OFFSET_FOR_TYPE_RUNS
	call	callCopyRun
noTypes:

	; copy over graphic information

	test	cl, mask VTSF_GRAPHICS
	jz	noGraphics
	mov	bx, TAT_GRAPHICS or (TRUE shl 8)
	call	exchangeVMFile
	call	TA_CreateRunAndElementArrays	;ax = runs, bx = elements
	call	exchangeVMFile
	mov	es:TTBH_graphicRuns.high, ax
	mov	es:TTBH_graphicElements.high, bx
	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
	call	callCopyRun
noGraphics:

	; convert blocks to be not lmem where needed

	push	bp
	mov	bp, ss:[bp]
	mov	bx, ss:[bp].CTP_vmFile
	call	MakeTransferFormatNotLMem
	pop	bp

	push	bp
	mov	bp, vmMemHandle
	call	VMDirty
	call	VMUnlock
	pop	bp

	mov	bx, optBlock
	tst	bx
	jz	noOptBlock
	call	MemFree
noOptBlock:

	mov	ax, header

	.leave

	pop	di
	add	sp, size CommonTransferParams
	call	ThreadReturnStackSpace
	pop	bp

	ret

;---

exchangeVMFile:
	push	bx, bp
	mov	bp, ss:[bp]
	mov	bx, ss:[bp].CTP_vmFile
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	xchg	bx, ds:[di].VTI_vmFile
	mov	ss:[bp].CTP_vmFile, bx
	pop	bx, bp
	retn

;---

	; ax = runs, bx = run offset

callCopyRun:
	push	cx, bp

	mov_tr	cx, ax					;cx = dest run
	mov	dx, optBlock
	mov	di, vmMemHandle
	mov	bp, ss:[bp]
	mov	ax, ss:[bp].CTP_vmFile
	lea	bp, ss:[bp].CTP_range
	call	TA_CopyRunToTransfer

	pop	cx, bp
	mov	optBlock, dx
	mov	bx, vmMemHandle
	call	MemDerefES
	retn

VisTextCreateTransferFormat	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilterSectionBreakFromHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Filter The section breaks from a huge array

CALLED BY:	EXTERNAL
PASS:		ax = VX file
		cx = VM array
RETURN:		none
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	8/26/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilterSectionBreakFromHugeArray	proc	near	uses bx, dx, si, di, bp, ds, es
	.enter

	mov	bx, ax
	mov	di, cx
	clrdw	dxax
	call	HugeArrayLock			; ds:si = data

blockLoop:
	mov	cx, ax
searchLoop:
	lodsb
	cmp	al, C_SECTION_BREAK
	jnz	notSB
	mov	{byte} ds:[si]-1, C_CR
	call	HugeArrayDirty
notSB:
	loop	searchLoop

	dec	si
	call	HugeArrayNext
	tst_clc	ax
	jnz	blockLoop

	call	HugeArrayUnlock

	.leave
	ret

FilterSectionBreakFromHugeArray endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextTransferRangeLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the maximum range allowed in a text transfer.
		Looks in the ini file under the [text] category
		for transferLimit.  The size of the transfer limit
		is specified in K

CALLED BY:	VisTextCreateTransferFormat
PASS:		nothing
RETURN:		if limit if found 
			carry clear
			axbx	= dword range limit
		else
			carry set
DESTROYED:	if carry set ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
textCategory	char	"text",0
limitKey	char	"transferLimit",0

GetTextTransferRangeLimit	proc	near
	uses	ds,si,cx,dx
	.enter

	segmov	ds, cs			;DS:SI <- category string
	mov	si, offset textCategory
	mov	cx, cs
	mov	dx, offset limitKey	;CX:DX <- key string
	call	InitFileReadInteger
	jc	exit

	mov	cx, 10			;multiply by 1024
	mov_tr 	bx, ax
	clr 	ax

multiplyLoop:
	shl	bx, 1
	rcl	ax, 1
	loop	multiplyLoop
	; 
	; carry should be clear from the rcl	
	;
exit:
	.leave
	ret
GetTextTransferRangeLimit	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WarnUserRangeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog bos to warn the user that the range of
		the text transfer has changed.

CALLED BY:	VisTextCreateTransferFormat	
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WarnUserRangeChanged	proc	near
	uses	cx, dx
	.enter
	mov	cx, handle TextTransStrings
	mov	dx, offset TransferSizeWarning
	call	TT_DoWarningDialog
	.leave
	ret
	
WarnUserRangeChanged	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MakeTransferFormatNotLMem

DESCRIPTION:	Convert blocks in a transfer format to not be lmem

CALLED BY:	INTERNAL

PASS:
	bx - VM file handle
	es - TextTransferBlockHeader

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
MakeTransferFormatNotLMem	proc	near	uses ax, cx, si, bp, ds
	.enter

	mov	si, offset TTBH_charAttrElements
	mov	cx, ((offset TTBH_lastLMem) - (offset TTBH_firstLMem)) \
						/ (size dword)
changeLoop:
	mov	ax, es:[si].high
	tst	ax
	jz	next
	call	VMLock				;bp = mem handle
	mov	ds, ax
	push	bx
	mov	bx, bp
	mov	ax, (mask HF_LMEM) shl 8
	call	MemModifyFlags
	pop	bx
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
		TT_DoWarningDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog bos to warn the user that the range of
		the text transfer has changed.

CALLED BY:	External
PASS:		^lcx:dx - warning string
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TT_DoWarningDialog	proc	far
	uses bp, ds, si
	.enter
		
	sub	sp, (size StandardDialogOptrParams)
	mov	bp, sp			;ss:bp <- ptr to params
	mov	ss:[bp].SDOP_customFlags,
			CDT_WARNING shl (offset CDBF_DIALOG_TYPE) or \
	 		GIT_NOTIFICATION shl (offset CDBF_INTERACTION_TYPE)
	clr	ax
	mov	ss:[bp].SDOP_stringArg1.handle, ax
	mov	ss:[bp].SDOP_stringArg1.chunk, ax
	mov	ss:[bp].SDOP_stringArg2.handle, ax
	mov	ss:[bp].SDOP_stringArg2.chunk, ax
	mov	ss:[bp].SDOP_helpContext.handle, ax
	mov	ss:[bp].SDOP_helpContext.chunk, ax
	mov	ss:[bp].SDOP_customString.handle, cx
	mov	ss:[bp].SDOP_customString.chunk, dx
	call	UserStandardDialogOptr

	.leave
	ret
	
TT_DoWarningDialog		endp
	
TextTransfer ends

