COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefInitFile.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 2/92   	Initial version.

DESCRIPTION:
	Routines for dealing with that wacky init file.

	$Id: prefInitFile.asm,v 1.1 97/04/04 17:50:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringListSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	"SAVE OPTIONS" -- if we're using strings or monikers.

CALLED BY:	PrefItemGroupSaveOptions

PASS:		*ds:si - PrefItemGroup
		ds:di - PrefItemGroup instance data

		ss:bx - GenOptionsParams

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,es,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringListSaveOptions	proc far
	class	PrefItemGroupClass

	mov	bx, bp

locals	local	PrefItemGroupStringVars
	.enter 

DBCS <	test	ds:[di].PIGI_initFileFlags, mask PIFF_NUMERIC_MONIKERS	>
DBCS <	jnz	numericMonikers						>

	; null-initialize the buffer in case the key wasn't originally
	; in the .INI file

SBCS <	mov	{char} locals.PIGSV_buffer, 0				>
DBCS <	mov	{wchar} locals.PIGSV_buffer, 0				>
	lea	ax, locals.PIGSV_buffer
	mov	locals.PIGSV_endPtr, ax

	test	ds:[di].PIGI_initFileFlags, mask PIFF_APPEND_TO_KEY
	jz	afterRead

	; put string from init file into buffer -- this is for the
	; case where there may be other things in the string than
	; those we place there via this object.

	push	ds, es, si, di, bp, bx
	mov	cx, ss
	mov	ds, cx
	mov	es, cx
	lea	dx, ss:[bx].GOP_key
	lea	si, ss:[bx].GOP_category
	lea	di, locals.PIGSV_buffer
	mov	bp, size PIGSV_buffer
	call	InitFileReadString

EC <	cmp	cx, PREF_ITEM_GROUP_STRING_BUFFER_SIZE	>
EC <	ERROR_AE OVERRAN_STRING_ITEM_BUFFER		>


	pop	ds, es, si, di, bp, bx
	add	locals.PIGSV_endPtr, cx		; # of bytes read

afterRead:

	;
	; copy the "extra" string section, if any
	;

	call	StringListCheckExtraStringSection

	;
	; Figure out which callback routine to use
	;

	mov	ax, offset PrefItemGroupSaveStringsCB	
	test	ds:[di].PIGI_initFileFlags, mask PIFF_USE_ITEM_STRINGS
	jnz	callIt

	mov	ax, offset PrefItemGroupSaveMonikersCB

callIt:
	call	PrefItemGroupProcessChildren


	; Now, write the string to the buffer

	mov	cx, ss
	mov	es, cx
	mov	ds, cx
	lea	si, ss:[bx].GOP_category
	lea	dx, ss:[bx].GOP_key
	lea	di, locals.PIGSV_buffer
	call	InitFileWriteString

DBCS <done:								>
	.leave
	ret

if DBCS_PCGEOS
numericMonikers:
	;
	; get selection
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	push	bp
	call	ObjCallInstanceNoLock		; ax = selection
	pop	bp
	cmp	ax, GIGS_NONE
	je	done
	mov	cx, ax				; cx = identifier
	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	push	bp
	call	ObjCallInstanceNoLock		; ^lcx:dx = item
	pop	bp
	jnc	done
	push	bp
	mov	bp, bx				; ss:bp = GenOptionsParams
	movdw	bxsi, cxdx
	call	ObjSwapLock			; *ds:si = item
	;
	; convert moniker to integer
	;
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	si, ds:[si].GI_visMoniker
	tst	si
	jz	donePop
	mov	si, ds:[si]
	add	si, offset VM_data+VMT_text	; ds:si = moniker
	call	UtilAsciiToHex32		; dx:ax = value
	jc	donePop
	tst	dx
	jnz	donePop
	call	ObjSwapUnlock
	;
	; write integer to .ini file
	;
	mov	cx, ss
	mov	es, cx
	mov	ds, cx
	lea	si, ss:[bp].GOP_category
	lea	dx, ss:[bp].GOP_key
	mov	bp, ax				; bp = value
	call	InitFileWriteInteger
donePop:
	pop	bp
	jmp	short done
endif

StringListSaveOptions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringListCheckExtraStringSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if there's an
		ATTR_PREF_ITEM_GROUP_EXTRA_STRING_SECTION to be dealt with

CALLED BY:	StringListSaveOptions

PASS:		*ds:si - PrefItemGroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringListCheckExtraStringSection	proc near
	uses	ax,bx

	.enter	inherit	StringListSaveOptions

	mov	ax, ATTR_PREF_ITEM_GROUP_EXTRA_STRING_SECTION
	call	ObjVarFindData		; ds:bx - extra string
	jnc	done
	call	CopyStringToBuffer
done:
	.leave
	ret
StringListCheckExtraStringSection	endp

	


COMMENT @----------------------------------------------------------------------

MESSAGE:	StringListLoadOptions

DESCRIPTION:	Load options from .ini file

PASS:
		*ds:si - instance data

		ss:bp - GenOptionsParams

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/30/92		Initial version  	

------------------------------------------------------------------------------@
StringListLoadOptions	proc near

	class	PrefItemGroupClass

locals	local	PrefItemGroupStringVars

	mov	bx, bp			; GenOptionsParams	
	.enter

if DBCS_PCGEOS
	mov	di, ds:[si]
	add	di, ds:[di].Pref_offset
	test	ds:[di].PIGI_initFileFlags, mask PIFF_NUMERIC_MONIKERS
	jnz	numericMonikers
endif

	; Read the init file string into the buffer

	push	bx, bp, ds, si			; item group
	mov	cx, ss
	mov	es, cx
	mov	ds, cx
	lea	si, ds:[bx].GOP_category
	lea	dx, ds:[bx].GOP_key
	lea	di, locals.PIGSV_buffer
	mov	bp, PREF_ITEM_GROUP_STRING_BUFFER_SIZE
	call	InitFileReadString
	pop	bx, bp, ds, si			; item group
	jc	checkQuery

DBCS <haveBuffer:							>
	mov	di, ds:[si]
	add	di, ds:[di].Pref_offset

	test	ds:[di].PIGI_initFileFlags, mask PIFF_USE_ITEM_STRINGS
	jnz	useStrings

	mov	ax, offset StringListLoadMonikersCB
	jmp	callIt

useStrings:
	mov	ax, offset StringListLoadStringsCB
callIt:
	call	PrefItemGroupProcessChildren

	; Set selections

	mov	cx, ss
	lea	dx, locals.PIGSV_selections
	push	bp
	mov	bp, locals.PIGSV_numSelections
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS
	call	ObjCallInstanceNoLock
	pop	bp
done:
	.leave
	ret

checkQuery:
	;
	; Key not in ini file. If we have to query the children anyway, zero
	; out the string buffer and go to the common code.
	; 
SBCS <	mov     {char}es:[di], 0                ; in case not in file	>
DBCS <	mov     {wchar}es:[di], 0                ; in case not in file	>
	mov	di, ds:[si]
	add	di, ds:[di].Pref_offset
	test	ds:[di].PIGI_initFileFlags, 
			mask PIFF_ABSENT_KEY_OVERRIDES_DEFAULTS
	jz	done
	jmp	useStrings

if DBCS_PCGEOS
numericMonikers:
	;
	; read integer
	;
	push	ds, si				; item group
	mov	cx, ss
	mov	es, cx
	mov	ds, cx
	lea	si, ds:[bx].GOP_category
	lea	dx, ds:[bx].GOP_key
	call	InitFileReadInteger		; ax = value
	pop	ds, si				; item group
	jc	checkQuery
	lea	di, locals.PIGSV_buffer
	clr	dx
	mov	cx, mask UHTAF_NULL_TERMINATE
.assert (PREF_ITEM_GROUP_STRING_BUFFER_SIZE gt UHTA_NO_NULL_TERM_BUFFER_SIZE)
	call	UtilHex32ToAscii
	jmp	short haveBuffer
endif

StringListLoadOptions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupProcessChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the children of a PrefItemGroup

CALLED BY:	StringListLoadOptions, StringListSaveOptions

PASS:		ax - callback routine
		ss:bp - PrefItemGroupVars
		*ds:si - PrefItemGroupClass object

RETURN:		nothing 

DESTROYED:	bx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefItemGroupProcessChildren	proc near
	class	PrefItemGroupClass
	uses	bx

	.enter	inherit StringListSaveOptions

	mov	locals.PIGSV_numSelections, 0

	clr	di
	push	di, di
	mov	di, offset GI_link
	push	di
	push	cs
	push	ax			; callback
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren

	.leave
	ret
PrefItemGroupProcessChildren	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupSaveStringsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this PrefStringItem object is selected, then add
		its string to the buffer (if not already there).  If
		it's not selected, then remove it.

CALLED BY:	StringListSaveOptions

PASS:		*ds:si - PrefStringItem
		*es:di - PrefItemGroup (parent)
		ss:bp	- PrefItemGroupStringVars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefItemGroupSaveStringsCB	proc far
	class	PrefStringItemClass

	.enter inherit StringListSaveOptions


	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset

	mov	bx, ds:[bx].PSII_initFileString
	tst	bx
	jz	done
	mov	bx, ds:[bx]

	call	AddOrRemoveStringBasedOnSelection

done:
	clc
	.leave
	ret
PrefItemGroupSaveStringsCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupSaveMonikersCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add the moniker for this item to the buffer if selected

CALLED BY:	StringListSaveOptions

PASS:		*ds:si - GenItem
		*es:di - PrefItemGroup
		ss:bp - local vars

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefItemGroupSaveMonikersCB	proc far

	class	GenItemClass


	.enter inherit StringListSaveOptions

	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset

	mov	bx, ds:[bx].GI_visMoniker
	tst	bx
	jz	done
	mov	bx, ds:[bx]
	add	bx, offset VM_data+VMT_text

	call	AddOrRemoveStringBasedOnSelection

done:
	clc
	.leave
	ret
PrefItemGroupSaveMonikersCB	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfItemSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if this GenItem is selected

CALLED BY:	PrefItemGroupSaveStringsCB, PrefItemGroupSaveMonikersCB

PASS:		*ds:si - item to check
		*es:di - item group (parent)

RETURN:		IF SELECTED - 
			carry flag set
		ELSE
			carry flag clear

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfItemSelected	proc near
	uses	bp,si,di
	.enter

	; Get identifier for this child -- fixup ES

	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
	call	ObjCallInstanceNoLockES

	; ask parent if child is selected

	mov	cx, ax			; item's identifier
	segxchg	ds, es
	mov	si, di
	mov	ax, MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED
	call	ObjCallInstanceNoLockES	; returns carry
	segxchg	ds, es

	.leave
	ret
CheckIfItemSelected	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringListLoadMonikersCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	see if the moniker for this item is in the buffer, and
		if so, select the item.

CALLED BY:	StringListLoadOptions

PASS:		*ds:si - GenItem
		ss:bp - PrefItemGroupStringVars

RETURN:		carry clear (always)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringListLoadMonikersCB	proc far

	.enter 	inherit	StringListLoadOptions

	push	bp
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	call	ObjCallInstanceNoLock
	pop	bp
	tst	ax
	jz	done
	
	mov	bx, ax
	mov	bx, ds:[bx]
	add	bx, offset VM_data.VMT_text

	call	SelectItemIfStringInBuffer
done:
	clc
	.leave
	ret
StringListLoadMonikersCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringListLoadStringsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add this item to the selections if its string is in
		the buffer.

CALLED BY:	StringListLoadOptions

PASS:		*ds:si - item to check

RETURN:		carry clear (always)

DESTROYED:	ax,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringListLoadStringsCB	proc far

	class	PrefStringItemClass

	.enter 	inherit StringListLoadOptions

EC <	push	es, di						>
EC <	segmov	es, <segment PrefStringItemClass>, di		>
EC <	mov	di, offset PrefStringItemClass			>
EC <	call	ObjIsObjectInClass				>
EC <	pop	es, di						>
EC <	ERROR_NC	CHILD_MUST_BE_PREF_STRING_ITEM		>

	push	bp
	add	bp, offset locals	; ss:bp <- vars
	mov	ax, MSG_PREF_STRING_ITEM_CHECK_IF_IN_INIT_FILE_KEY
	call	ObjCallInstanceNoLock
	pop	bp
	jnc	done

	call	SelectItem
done:
	clc
	.leave
	ret
StringListLoadStringsCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectItemIfStringInBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the child's initFileString (or moniker) is in
		the buffer.  If so, add child's identifier to list of
		selections. 

CALLED BY:	

PASS:		*ds:si - GenItem 
		ds:bx - string to check in buffer
		ss:bp - PrefItemGroupStringVars locals

RETURN:		carry set (in buffer), clear if not

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectItemIfStringInBuffer	proc near

	.enter	inherit	StringListLoadOptions

EC <	call	ECCheckAsciiStringDSBX	>

	call	CheckStringInBuffer
	jnc	done

	call	SelectItem
done:
	.leave
	ret

SelectItemIfStringInBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up to select this item, please.

CALLED BY:	(INTERNAL) SelectItemIfStringInBuffer, 
			   StringListLoadStringsCB
PASS:		*ds:si	= GenItem
		ss:bp	= inherited stack frame
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectItem	proc	near
	.enter	inherit	StringListLoadOptions
	push	bp
	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
	call	ObjCallInstanceNoLock
	pop	bp

	mov	di, locals.PIGSV_numSelections
	shl	di
	mov	locals.PIGSV_selections[di], ax
	shr	di
	inc	di

EC <	cmp	di, PREF_ITEM_GROUP_MAX_SELECTIONS		>
EC <	ERROR_GE TOO_MANY_SELECTIONS		>

	mov	locals.PIGSV_numSelections, di
	.leave
	ret
SelectItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddOrRemoveStringBasedOnSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add or remove the string to/from the buffer, based on
		the selection of the object

CALLED BY:

PASS:		*ds:si - object
		*es:di - object's parent
		ds:bx - string
		ss:bp - local vars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddOrRemoveStringBasedOnSelection	proc near

	.enter	inherit	StringListSaveOptions

EC <	call	ECCheckAsciiStringDSBX	>

	call	CheckIfItemSelected
	jnc	removeString
	
	call	CopyStringToBuffer
	jmp	done

removeString:

	call	RemoveStringFromBuffer
done:

	.leave
	ret
AddOrRemoveStringBasedOnSelection	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckStringInBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed string is in the buffer.  Make sure
		the match is exact.
CALLED BY:

PASS:		ds:bx - string to search for
		ss:bp - local vars

RETURN:		cx - length of search string (not including NULL)

		IF STRING IN BUFFER:
			ss:dx - address of string
			carry set
		ELSE
			carry clear

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	
	Get length of search string (CX)
	While (not at end of buffer) {
		compare (CX) chars of search string with buffer
		If equal:
			IF next character in buffer is CTRL_M, or NULL
				Exit, string found
		Go to next line in buffer
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckStringInBuffer	proc near
	uses	ds,es,si,di

	.enter	inherit StringListSaveOptions

	segmov	es, ds, di	
	mov	di, bx			; es:di - string to find
	clr	dx			; current buffer position

	; get length of search string in CX (not including NULL)

	call	LocalStringLength	; cx = length w/o null
	push	cx			; save length - return to caller

	; Make DS:SI point to start of buffer
	segmov	ds, ss, si
	lea	si, locals.PIGSV_buffer

startLoop:
	; First, check if buffer is empty (or at end of buffer)

SBCS <	cmp	{char} ds:[si], 0					>
DBCS <	cmp	{wchar} ds:[si], 0					>
	je	noMatch
	mov	dx, si			; save current string addr in
					; case we find a match

	push	cx, di
SBCS <	repe	cmpsb							>
DBCS <	repe	cmpsw							>
	pop	cx, di
	jne	gotoNextLineInBuffer

	; Possible match, if current character in buffer is NULL or
	; CR.

	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	match
SBCS <	LocalCmpChar	ax, VC_CTRL_M					>
DBCS <	LocalCmpChar	ax, C_CARRIAGE_RETURN				>
	je	match

	; Now, skip chars until LF or NULL

gotoNextLineInBuffer:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	noMatch
SBCS <	LocalCmpChar	ax, VC_LF					>
DBCS <	LocalCmpChar	ax, C_LINE_FEED					>
	je	startLoop
	jmp	gotoNextLineInBuffer
match:
	stc
	jmp	done

noMatch:
	clc
done:
	pop	cx			; length of search string
	.leave
	ret
CheckStringInBuffer	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyStringToBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the source string onto the stack buffer

CALLED BY:

PASS:		ds:bx - string
		ss:bp - local vars

RETURN:		nothing 

DESTROYED:	es,cx,di,ax

PSEUDO CODE/STRATEGY:	
	if (endPtr - PIGSV_buffer > 0)
		add newline
	endif
	stick string in buffer, null term.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyStringToBuffer	proc near
	uses	si, es, di, cx, ax

	.enter	inherit StringListSaveOptions

	; String might already be there!

	call	CheckStringInBuffer
	jc	done

	mov	si, bx
EC <	call	ECCheckAsciiString	>

	; See if we're at the start of the buffer, in which case,
	; don't insert a CR/LF pair

	segmov	es, ss
	lea	bx, locals.PIGSV_buffer
	mov	di, locals.PIGSV_endPtr
	cmp	di, bx
	je	startLoop		
DBCS <	LocalLoadChar	ax, C_CARRIAGE_RETURN				>
DBCS <	LocalPutChar	esdi, ax					>
DBCS <	LocalLoadChar	ax, C_LINE_FEED					>
DBCS <	LocalPutChar	esdi, ax					>
SBCS <	mov	ax, CRLF						>
SBCS <	stosw								>

	; Copy string until null char found.

startLoop:
	LocalCopyString

	; make di point to last char copied so subsequent copies will
	; overwrite null-term.

	LocalPrevChar	esdi

	; Store the new current offset

	mov	locals.PIGSV_endPtr, di

if ERROR_CHECK
	lea	ax, locals.PIGSV_buffer
	sub	di, ax
	cmp	di, PREF_ITEM_GROUP_STRING_BUFFER_SIZE
	ERROR_AE	OVERRAN_STRING_ITEM_BUFFER
endif

done:
	.leave
	ret
CopyStringToBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveStringFromBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the passed string from the stack buffer

CALLED BY:	PrefString

PASS:		ds:bx - string
		ss:bp - inherited local vars

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveStringFromBuffer	proc near

	uses	ds,es,si,di

	.enter	inherit StringListSaveOptions

EC <	call	ECCheckAsciiStringDSBX	>

	call	CheckStringInBuffer
	jnc	done			; that was easy!

	; cx - length of string to remove
	; ss:dx - address of string to remove

	; If string is at end of buffer, then we just stick a NULL at
	; the beginning of the string

	mov	si, ss
	mov	ds, si
	mov	es, si

	mov	di, dx				; es:di - string to nuke
DBCS <	shl	cx, 1				; # chars -> # bytes	>
	add	di, cx
SBCS <	cmp	{char} es:[di], 0					>
DBCS <	cmp	{wchar} es:[di], 0					>
	je	endOfBuffer

if DBCS_PCGEOS
EC <	cmp	{word} es:[di], C_CARRIAGE_RETURN			>
EC <	ERROR_NE ILLEGAL_CHARS_IN_BUFFER				>
EC <	cmp	{word} es:[di][2], C_LINE_FEED				>
EC <	ERROR_NE ILLEGAL_CHARS_IN_BUFFER				>
else
EC <	cmp	{word} es:[di], CRLF		>
EC <	ERROR_NE ILLEGAL_CHARS_IN_BUFFER	>
endif
	LocalNextChar	esdi
	LocalNextChar	esdi

	; SS:DI - first character AFTER string
	; SS:DX - beginning of string
	; subtract "endPtr" by length of string

	mov	si, locals.PIGSV_endPtr
	sub	locals.PIGSV_endPtr, cx		; (cx = # bytes from above)

	; The # chars to move is (endPtr - start +1)


	mov	cx, si
	sub	cx, di		
DBCS <	shr	cx, 1				; # bytes -> # chars	>
	inc	cx

EC <	cmp	cx, PREF_ITEM_GROUP_STRING_BUFFER_SIZE	>
EC <	ERROR_AE	OVERRAN_STRING_ITEM_BUFFER	>

	mov	si, di
	mov	di, dx
	LocalCopyNString			; mov'em
	
done:
	.leave
	ret

endOfBuffer:

	mov	di, dx			; start of string

	; If string is beginning of buffer, then just store a zero at
	; the pointer address otherwise nuke the preceding CR/LF pair
	; as well

	lea	bx, locals.PIGSV_buffer
	cmp	di, bx
	je	gotAddr
	LocalPrevChar	esdi
	LocalPrevChar	esdi
gotAddr:
SBCS <	mov	{char}es:[di], 0					>
DBCS <	mov	{wchar}es:[di], 0					>
	mov	locals.PIGSV_endPtr, di
	jmp	done

RemoveStringFromBuffer	endp

