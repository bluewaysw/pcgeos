
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		formatMain.asm

AUTHOR:		Cheng, 4/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/92		Initial revision

DESCRIPTION:
		
	$Id: formatMain.asm,v 1.1 97/04/05 01:23:38 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatGetFormatParams

DESCRIPTION:	Return the format token for the format corresponding to the
		list entry. The format's parameters will also be copied into
		a buffer.

CALLED BY:	EXTERNAL ()

PASS:		cx:dx - FloatCtrlInfoStruc with these fields filled in:
			FCIS_listEntryNum
			FCIS_fmtArrayHan
			FCIS_fmtArraySeg

RETURN:		FCIS_fmtToken
		FCIS_fmtParamsHan

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatGetFormatParams	proc	far	uses	ax,bx,cx,dx,ds,si,es,di
	.enter

	;-----------------------------------------------------------------------
	; cx <- list entry number
	; ds <- format array
	; es <- FormatParams

	push	cx,dx
	mov	es, cx
	mov	di, dx				; es:di <- FloatCtrlInfoStruc

	mov	ax, size FormatParams
	mov	cx, (mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8 or \
		mask HF_SHARABLE
	call	MemAlloc
	mov	es:[di].fmtParamsHan, bx
	mov	cx, es:[di].FCIS_listEntryNum	; cx <- list entry number
	mov	ds, es:[di].FCIS_fmtArraySeg	; ds <- format array
	mov	es, ax				; es <- FormatParams

	cmp	cx, NUM_PRE_DEF_FORMATS
	jb	preDef

	;-----------------------------------------------------------------------
	; user-defined format

	mov	si, size FormatArrayHeader

EC<	cmp	ds:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FLOAT_CONTROLLER_BAD_FORMAT_ARRAY >
EC<	mov	di, ds:FAH_formatArrayEnd >

	;
	; loop to locate entry
	;
locateLoop:
	cmp	ds:[si].FE_used, 0		; is entry used?
	je	next				; next if not

EC<	cmp	ds:[si].FE_used, -1 >		; check for legal flag
EC<	ERROR_NE FLOAT_CONTROLLER_BAD_FORMAT_ENTRY >
;EC<	cmp	ds:[si].FE_sig, FORMAT_ENTRY_SIG >
;EC<	ERROR_NE FLOAT_CONTROLLER_BAD_ENTRY_SIGNATURE >
	cmp	cx, ds:[si].FE_listEntryNumber
	je	found

next:
	add	si, size FormatEntry		; inc offset
EC<	cmp	si, di >			; error if offset exceeds end
EC<	ERROR_AE FLOAT_CONTROLLER_BAD_FORMAT_LIST >
	jmp	short locateLoop		; loop

found:
	;
	; copy FormatParams over
	; ds:si = FormatEntry
	;
	clr	di				; es:di <- FormatParams
	push	si				; save format token
	mov	cx, size FormatParams
	rep	movsb
	pop	cx				; retrieve format token
	jmp	done

preDef:
	;-----------------------------------------------------------------------
	; pre-defined format

	segmov	ds, cs, ax
	mov	ax, size FormatParams
	mul	cx				; ax <- 0 based offset

	mov	cx, ax
	or	cx, FORMAT_ID_PREDEF		; cx <- token

	add	ax, offset FormatPreDefTbl	; ax <- offset into lookup tbl
	mov	si, ax

	push	cx
	clr	di
	mov	cx, size FormatParams
	rep	movsb
	pop	cx

done:
	; cx = token

	pop	es,di				; es:di <- FloatCtrlInfoStruc
	mov	es:[di].FCIS_fmtToken, cx
	call	MemUnlock			; unlock FormatParams

	.leave
	ret
FloatFormatGetFormatParams	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatGetNumFormats

DESCRIPTION:	Given the handle of the format array, return the number
		of pre-defined and user-defined formats.

CALLED BY:	EXTERNAL ()

PASS:		cx:dx - FloatCtrlInfoStruc with these fields filled in:
			FCIS_fmtArraySeg

RETURN:		cx - number of pre-defined formats
		dx - number of user-defined formats

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatGetNumFormats	proc	far	uses	ds,si
	.enter

	mov	ds, cx
	mov	si, dx				; ds:si <- FloatCtrlInfoStruc
	mov	ds, ds:[si].FCIS_fmtArraySeg	; ds <- format array
EC<	cmp	ds:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FLOAT_CONTROLLER_BAD_FORMAT_ARRAY >

	mov	cx, NUM_PRE_DEF_FORMATS
	mov	dx, ds:FAH_numUserDefEntries

	.leave
	ret
FloatFormatGetNumFormats	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatAddEntry

DESCRIPTION:	Given the format array and a format entry, add the entry to the
		array.

CALLED BY:	EXTERNAL (FLOAT_FORMAT_ADD_ENTRY)

PASS:		cx - handle of format array
		dx - handle of a FormatParams structure

RETURN:		dx - new token

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatAddEntry	method	FLOAT_FORMAT_ADD_ENTRY
	mov	bx, dx
	call	MemLock
	mov	ds, ax				; ds:si <- FormatParams
	clr	si
	push	bx				; save handle of FormatParams

	mov	bx, cx
	call	MemLock
	mov	es, ax				; es <- format array
EC<	cmp	es:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FLOAT_CONTROLLER_BAD_FORMAT_ARRAY >

	;-----------------------------------------------------------------------
	; add the format entry
	; bx = handle of format array

	call	FloatFormatUseFreeFormatEntry	; es:di <- free entry

	mov	ax, es:FAH_numUserDefEntries	; assign list entry num
	add	ax, NUM_PRE_DEF_FORMATS
	mov	es:[di].FE_listEntryNumber, ax
	inc	es:FAH_numUserDefEntries
	mov	dx, di				; dx <- new token

	mov	cx, size FormatParams
	rep	movsb

	;-----------------------------------------------------------------------
	; clean up - unlock blocks

	call	MemUnlock		; unlock format array
	pop	bx
	call	MemUnlock		; unlock FormatParams

	ret
FloatFormatAddEntry	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatDeleteEntry

DESCRIPTION:	

CALLED BY:	EXTERNAL (FLOAT_FORMAT_DELETE_ENTRY)

PASS:		cx - handle of format array
		dx - format token to delete

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatDeleteEntry	method	FLOAT_FORMAT_DELETE_ENTRY
	mov	bx, cx
	call	MemLock
	mov	es, ax
EC<	cmp	es:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FLOAT_CONTROLLER_BAD_FORMAT_ARRAY >
	mov	di, dx				; es:di <- format entry to del

	;-----------------------------------------------------------------------
	; delete the format entry

	mov	es:[di].FE_used, 0
	call	FloatFormatDeleteFormatUpdateListEntries
	dec	es:FAH_numUserDefEntries	; dec count
EC<	ERROR_L FLOAT_CONTROLLER_ASSERTION_FAILED >

	mov	ax, es:[di].FE_listEntryNumber
	mov	cx, size FormatEntry

	mov	di, size FormatArrayHeader	; es:di <- first entry
updateLoop:
	cmp	es:[di].FE_used, 0
	je	next

EC<	call	ECCheckUsedEntry >
	cmp	ax, es:[di].FE_listEntryNumber
EC<	ERROR_E FLOAT_CONTROLLER_BAD_FORMAT_LIST >
	jg	next

	dec	es:[di].FE_listEntryNumber

next:
	add	di, cx			; next format entry
	cmp	di, dx			; done?
	jl	updateLoop
EC<	ERROR_G	FLOAT_CONTROLLER_ASSERTION_FAILED >

	call	MemUnlock			; unlock format array

	;-----------------------------------------------------------------------
	; tell target object to remove all references to the format token

	;-----------------------------------------------------------------------
	; update UI
	; purge dynamic list

	ret
FloatFormatDeleteEntry	endm
