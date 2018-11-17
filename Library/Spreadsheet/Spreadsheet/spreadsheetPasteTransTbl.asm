
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetPasteTransTbl.asm

AUTHOR:		Cheng, 6/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial revision

DESCRIPTION:
	The translation table routines for the spreadsheet's paste code.

	A translation table is basically an array of TransTblEntry
	that is meant to track how tokens in a scrap have been translated.

	Purpose of a translation table
	------------------------------

	The paste code will search the translation table with the scrap's
	token to see if it can find a match.  From the matched entry,
	the new (translated) token can be gotten and used.

	The maximum of a translation table is:
	(65535-size TransTblEntry) / size TransTblEntry
	= (65535-4) / 4
	= 16382

	Register usage
	--------------
	cx	- old token
	dx	- new token
	bx	- trans table mem handle (possibly 0)
	ax	- size of the trans table
	es	- seg addr of the trans table

	$Id: spreadsheetPasteTransTbl.asm,v 1.1 97/04/07 11:14:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CutPasteCode	segment

;*******************************************************************************
;
;	BOOK KEEPING ROUTINES
;
;*******************************************************************************

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TransTblCleanUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Free the translation tables.

CALLED BY:	INTERNAL ()

PASS:		PasteStackFrame

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransTblCleanUp	proc	near	uses	bx
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	.enter	inherit near

	lea	bx, PSF_local.PSF_formatTransTbl
	call	TransTblCleanUpOne

	.leave
	ret
TransTblCleanUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TransTblCleanUpOne
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Free the given translation table and zero out its fields.

CALLED BY:	INTERNAL ()

PASS:		bx - offset from ss to the translation table

RETURN:		translation table freed and zeroed

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransTblCleanUpOne	proc	near	uses	ax
	.enter

EC<	cmp	ss:[bx].TT_sig, TRANS_TABLE_SIG >
EC<	ERROR_NE PASTE_BAD_TRANS_TABLE >

	mov	ax, bx			; save bx
	mov	bx, ss:[bx].TT_han
	tst	bx
	je	10$
	call	MemFree
10$:
	mov	bx, ax			; restore bx

	clr	ax
	mov	ss:[bx].TT_han, ax
	mov	ss:[bx].TT_size, ax
	.leave
	ret
TransTblCleanUpOne	endp


;*******************************************************************************
;
;	ENTRY CREATION ROUTINES
;
;*******************************************************************************

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TransTblAddEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Creates a new entry in the default translation table and
		stores the token mapping information.

CALLED BY:	INTERNAL ()

PASS:		cx - original token
		dx - new token
		bx - offset from ss to the translation table

RETURN:		translation table updated

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransTblAddEntry	proc	near	uses	ax,es,di
	.enter

	mov	ax, ss:[bx].TT_size
	tst	ax
	jne	checkTT

	mov	ss:[bx].TT_sig, TRANS_TABLE_SIG
	jmp	short doneCheck

checkTT:
EC<	cmp	ss:[bx].TT_sig, TRANS_TABLE_SIG >
EC<	ERROR_NE PASTE_BAD_TRANS_TABLE >

doneCheck:
	push	bx				; save trans tbl offset
	mov	bx, ss:[bx].TT_han

	push	cx				; save old token
	push	ax				; save offset

	add	ax, size TranslationTableEntry	; increase size
	push	ax				; save new size

	tst	bx				; any handle?
	jne	doRealloc			; branch if so

	mov	cx, (mask HAF_LOCK or mask HAF_ZERO_INIT or mask HAF_NO_ERR) shl 8 or mask HF_SWAPABLE
	call	MemAlloc
	mov	es, ax				; es <- seg addr
	mov	es:TTE_sig, TRANS_TABLE_ENTRY_SIG
	jmp	short 10$

doRealloc:
	mov	ch, mask HAF_LOCK or mask HAF_ZERO_INIT or mask HAF_NO_ERR
	call	MemReAlloc
	mov	es, ax				; es <- seg addr

10$:
EC<	cmp	es:TTE_sig, TRANS_TABLE_ENTRY_SIG >
EC<	ERROR_NE PASTE_BAD_TRANS_TABLE_ENTRY >

	pop	ax				; retrieve new size
	pop	di				; offset to new entry
	pop	cx				; retrieve old token

	mov	es:[di].TTE_srcToken, cx
	mov	es:[di].TTE_dstToken, dx

	;-----------------------------------------------------------------------
	; update trans tbl

	mov	di, bx				; di <- mem han
	pop	bx				; retrieve trans tbl offset

EC<	cmp	ss:[bx].TT_sig, TRANS_TABLE_SIG >
EC<	ERROR_NE PASTE_BAD_TRANS_TABLE >
	mov	ss:[bx].TT_han, di
	mov	ss:[bx].TT_size, ax

	.leave
	ret
TransTblAddEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TransTblAddFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Locates the translation table entry and store the flag.

CALLED BY:	INTERNAL ()

PASS:		cx - original token
		dx - flag to store
		bx - offset from ss to the translation table

RETURN:		translation table updated

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransTblAddFlag	proc	near	uses	ax,bx,es,di
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	.enter	inherit near

EC<	cmp	ss:[bx].TT_sig, TRANS_TABLE_SIG >
EC<	ERROR_NE PASTE_BAD_TRANS_TABLE >

	mov	ax, ss:[bx].TT_size
	mov	bx, ss:[bx].TT_han
	call	MemLock
	mov	es, ax
EC<	cmp	es:TTE_sig, TRANS_TABLE_ENTRY_SIG >
EC<	ERROR_NE PASTE_BAD_TRANS_TABLE_ENTRY >

	call	TransTblLocateEntry		; es:di <- entry
EC<	ERROR_C	PASTE_TRANS_TBL_CANT_LOCATE_ENTRY >

	mov	es:[di].TTE_action, dx
	call	MemUnlock

	.leave
	ret
TransTblAddFlag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TransTblModifyEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Modify a translation table entry.

CALLED BY:	INTERNAL ()

PASS:		cx - original token
		dx - new destination token
		bx - offset from ss to the translation table

RETURN:		translation table updated

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransTblModifyEntry	proc	near	uses	ax,bx,es,di
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	.enter	inherit near

EC<	cmp	ss:[bx].TT_sig, TRANS_TABLE_SIG >
EC<	ERROR_NE PASTE_BAD_TRANS_TABLE >

	mov	ax, ss:[bx].TT_size
	mov	bx, ss:[bx].TT_han
	call	MemLock
	mov	es, ax
EC<	cmp	es:TTE_sig, TRANS_TABLE_ENTRY_SIG >
EC<	ERROR_NE PASTE_BAD_TRANS_TABLE_ENTRY >

	call	TransTblLocateEntry		; es:di <- entry
EC<	ERROR_C	PASTE_TRANS_TBL_CANT_LOCATE_ENTRY >

	mov	es:[di].TTE_dstToken, dx
	call	MemUnlock

	.leave
	ret
TransTblModifyEntry	endp


;*******************************************************************************
;
;	SEARCH ROUTINES
;
;*******************************************************************************

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TransTblSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Given a token, searches the format translation table to
		see if there is a TransTblEntry that contains
		the token as TTE_originalToken.

CALLED BY:	INTERNAL ()

PASS:		PasteStackFrame
		bx - offset from ss to the translation table
		cx - original token

RETURN:		carry clear is match found
		    dx - new token
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransTblSearch	proc	near	uses	ax,bx,es
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	.enter	inherit near

EC<	cmp	ss:[bx].TT_sig, TRANS_TABLE_SIG >
EC<	ERROR_NE PASTE_BAD_TRANS_TABLE >

	mov	ax, ss:[bx].TT_size
	tst	ax
	stc
	je	done

	mov	bx, ss:[bx].TT_han
	call	MemLock
	mov	es, ax
EC<	cmp	es:TTE_sig, TRANS_TABLE_ENTRY_SIG >
EC<	ERROR_NE PASTE_BAD_TRANS_TABLE_ENTRY >
	call	TransTblMapEntry
	call	MemUnlock

done:
	.leave
	ret
TransTblSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TransTblGetFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Search for the given entry and retrieve the flag.

CALLED BY:	INTERNAL ()

PASS:		PasteStackFrame
		bx - offset from ss to the translation table
		cx - original token

RETURN:		dx - flag

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransTblGetFlag	proc	near	uses	ax,bx,es,di
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	.enter	inherit near

EC<	cmp	ss:[bx].TT_size, 0 >
EC<	ERROR_E	PASTE_TRANS_TBL_CANT_LOCATE_ENTRY >

	mov	ax, ss:[bx].TT_size
	mov	bx, ss:[bx].TT_han
	call	MemLock
	mov	es, ax
EC<	cmp	es:TTE_sig, TRANS_TABLE_ENTRY_SIG >
EC<	ERROR_NE PASTE_BAD_TRANS_TABLE_ENTRY >
	call	TransTblLocateEntry		; es:di <- entry
EC<	ERROR_C	PASTE_TRANS_TBL_CANT_LOCATE_ENTRY >

	mov	dx, es:[di].TTE_action
	call	MemUnlock

	.leave
	ret
TransTblGetFlag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TransTblMapEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Go through the current translation table and map an old token
		to a new token.

CALLED BY:	INTERNAL (TransTblSearch)

PASS:		cx - original token
		ax - size of trans table
		es - seg addr of trans table

RETURN:		carry clear if match found
		    dx - new token
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransTblMapEntry	proc	near	uses	ax,di
	.enter

	call	TransTblLocateEntry		; es:di <- entry
	jc	done				; branch if not found

	mov	dx, es:[di].TTE_dstToken	; grab token

done:
	.leave
	ret
TransTblMapEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TransTblLocateEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Go through the current translation table and map an old token
		to a new token.

CALLED BY:	INTERNAL (TransTblSearch)

PASS:		cx - original token
		ax - size of trans table
		es - seg addr of trans table

RETURN:		carry clear if match found
		    es:di - addr of trans table entry
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransTblLocateEntry	proc	near	uses	ax
	.enter

EC<	cmp	es:TTE_sig, TRANS_TABLE_ENTRY_SIG >
EC<	ERROR_NE PASTE_BAD_TRANS_TABLE_ENTRY >

	tst	ax
	je	notFound

	clr	di				; es:di <- first entry

locateLoop:
	cmp	cx, es:[di].TTE_srcToken	; match?
	je	found				; branch if so

	add	di, size TranslationTableEntry	; else next
	cmp	di, ax
	jb	locateLoop

notFound:
	stc					; signal not found
	jmp	short done

found:
	clc					; signal found

done:
	.leave
	ret
TransTblLocateEntry	endp

CutPasteCode	ends
