
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	(MSG_SPREADSHEET_...)
	GET_FORMAT_COUNT
	ADD_FORMAT
	DELETE_FORMAT
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision

DESCRIPTION:
	Formats exist in 2 arrays.  The pre-defined formats sit in
	a lookup table in dgroup and the user is not allowed to modify
	them in any way.  The user may create new formats based on the
	pre-defined formats and these will be saved in a VM block.

	Information on the VM block is saved in the spreadsheet's instance
	data. The format array in the VM block is a block that is a
	multiple of (size FormatEntry) in length.  Each FormatEntry
	element is either used or not (FE_used field).

	Whenever information is requested via SpreadsheetGetFormatInfo,
	the list entry number is stored in the FormatEntry for future
	reference (SpreadsheetGetFormatToken).  This preserves the integrity
	of the list entry number and FormatEntry correspondence.

		
	$Id: spreadsheetFormatMethods.asm,v 1.1 97/04/07 11:14:03 newdeal Exp $

-------------------------------------------------------------------------------@


SpreadsheetFormatCode	segment resource

if 0
COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetGetFormatCount

DESCRIPTION:	Return the count of the number of pre-defined and
		user-defined format entries.

CALLED BY:	INTERNAL (MSG_SPREADSHEET_GET_FORMAT_COUNT)

PASS:		ds:di - ptr to spreadsheet instance

RETURN:		cx - number of pre-defined formats
		dx - number of user-defined formats

DESTROYED:	everything

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

SpreadsheetGetFormatCount	method	dynamic SpreadsheetClass,
				MSG_SPREADSHEET_GET_FORMAT_COUNT
	mov	cx, NUM_PRE_DEF_FORMATS

	mov	ax, ds:[di].SSI_formatArray
	mov	bx, ds:[di].SSI_cellParams.CFP_file
	call	VMLock

	mov	es, ax
EC<	cmp	es:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FORMAT_BAD_FORMAT_ARRAY >
	mov	dx, es:FAH_numUserDefEntries
	call	VMUnlock
	ret
SpreadsheetGetFormatCount	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetGetFormatInfo

DESCRIPTION:	Return the format token for the format corresponding to
		the list entry. The format's parameters will also
		be copied into a buffer.

CALLED BY:	INTERNAL (MSG_SPREADSHEET_GET_FORMAT_INFO)

PASS:		cx - list entry number for which the moniker should be returned
		dx:bp - buffer to store FormatParams

RETURN:		cx - format token
		dx:bp - buffer containing FormatParams

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	If the list entry number falls into the user-defined category,
	we will store the list entry number in the format entry once an
	association has been determined.  This will allow
	SpreadsheetChangeFormat and SpreadsheetDeleteFormat to work
	on the correct entry given the list entry number.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

SpreadsheetGetFormatInfo	method	dynamic SpreadsheetClass,
				MSG_SPREADSHEET_GET_FORMAT_INFO
	mov	es, dx

	cmp	cx, NUM_PRE_DEF_FORMATS
	jb	preDef

	;-----------------------------------------------------------------------
	; user-defined format

	mov	si, di				; ds:si <- instance data
	mov	ax, ds:[si].SSI_formatArray
	mov	bx, ds:[si].SSI_cellParams.CFP_file

	push	bp				; save offset to buffer
	call	VMLock
	pop	bx				; bx <- offset to buffer
	mov	ds, ax				; ds:si <- first format entry
	mov	si, size FormatArrayHeader

EC<	cmp	ds:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FORMAT_BAD_FORMAT_ARRAY >
EC<	mov	di, ds:FAH_formatArrayEnd >

	;
	; loop to locate entry
	;
locateLoop:
	cmp	ds:[si].FE_used, 0		; is entry used?
	je	next				; next if not

EC<	cmp	ds:[si].FE_used, -1 >		; check for legal flag
EC<	ERROR_NE FORMAT_BAD_FORMAT_ENTRY >
EC<	cmp	ds:[si].FE_sig, FORMAT_ENTRY_SIG >
EC<	ERROR_NE FORMAT_BAD_ENTRY_SIGNATURE >
	cmp	cx, ds:[si].FE_listEntryNumber
	je	found

next:
	add	si, size FormatEntry		; inc offset
EC<	cmp	si, di >			; error if offset exceeds end
EC<	ERROR_AE FORMAT_BAD_FORMAT_LIST >
	jmp	short locateLoop		; loop

found:
	;
	; copy FormatParams over
	; ds:si = FormatEntry
	;
	mov	di, bx				; di <- offset to buffer
	push	si				; save format token
	mov	cx, size FormatParams
	rep	movsb
	pop	cx				; retrieve format token
	call	VMDirty
	call	VMUnlock
	mov	bp, bx				; bp <- offset to buffer
	jmp	done

preDef:
	;-----------------------------------------------------------------------
	; pre-defined format

NOFXIP<	segmov	ds, dgroup, ax						>
FXIP<	mov_tr	ax, bx				; save bx value		>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefDS			; ds = dgroup		>
FXIP<	mov_tr	bx, ax				; restore bx		>
	mov	ax, size FormatParams
	mul	cx				; ax <- 0 based offset

	mov	cx, ax
	or	cx, FORMAT_ID_PREDEF		; cx <- token

	add	ax, offset FormatPreDefTbl	; ax <- offset into lookup tbl
	mov	si, ax

	push	cx
	mov	di, bp
	mov	cx, size FormatParams
	rep	movsb
	pop	cx
	mov	dx, es				; dx was destroyed by "mul"

done:
	ret
SpreadsheetGetFormatInfo	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetGetFormatToken

DESCRIPTION:	Returns the format token that was assigned to the list entry
		number.

		This is useful for applications (eg. GeoCalc) that do not
		save the format token returned by SpreadsheetGetFormatInfo.

		The routine that returns a list entry number given a token
		is SpreadsheetGetListEntryWithToken.

		NOTE:
		-----
		As written, this routine does not deal with pre-defined
		formats. This is because the only routines that call this
		in GeoCalc currently are the Editing and Deleting routines,
		and these operations aren't allowed on pre-defined formats.

CALLED BY:	INTERNAL ()

PASS:		cx - list entry number

RETURN:		cx - format token

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

SpreadsheetGetFormatToken	method	dynamic SpreadsheetClass,
				MSG_SPREADSHEET_GET_FORMAT_TOKEN

	push	cx
	mov	cx, size FormatArrayHeader
	call	SpreadsheetLockFormatEntry	; es:di <- format entry
						; bp <- VM mem handle
						; ds:si <- instance data
						; dx <- offset to end of array
	pop	cx				; retrieve list entry number
	mov	bx, size FormatEntry

locLoop:
	cmp	es:[di].FE_used, 0		; is entry in use?
	je	next				; next entry if not

EC<	call	ECCheckUsedEntry >
	cmp	cx, es:[di].FE_listEntryNumber	; match?
	je	found

next:
	add	di, bx				; else next entry
EC<	cmp	di, dx >			; error if past end
EC<	ERROR_GE FORMAT_BAD_FORMAT_LIST >
	jmp	short locLoop

found:
	call	VMUnlock
	mov	cx, di				; cx <- format token
	ret
SpreadsheetGetFormatToken	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetGetFormatTokenWithParams

DESCRIPTION:	Locates a format entry given the format params.

		* NOTE *
		Only the user-defined format table is searched.

CALLED BY:	INTERNAL (MSG_SPREADSHEET_GET_FORMAT_TOKEN_WITH_PARAMS)

PASS:		dx:bp - address of format params

RETURN:		cx - format token of format entry containing the format params
		     SPREADSHEET_FORMAT_NAME_NOT_FOUND if not found

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

SpreadsheetGetFormatTokenWithParams	method	dynamic SpreadsheetClass,
				MSG_SPREADSHEET_GET_FORMAT_TOKEN_WITH_PARAMS

	;-----------------------------------------------------------------------
	; search user-defined format array
	; dx:bp = params

	push	dx,bp				; save address of name
	mov	cx, size FormatArrayHeader
	call	SpreadsheetLockFormatEntry	; es:di <- format entry
						; bp <- VM mem handle
						; ds:si <- instance data
						; dx <- offset to end of array
	pop	ds,si				; retrieve address of name

	mov	bx, size FormatEntry
locLoop:
	cmp	es:[di].FE_used, 0		; is entry in use?
	je	next				; next entry if not

EC<	call	ECCheckUsedEntry >
	call	DoParamsMatch?
	jnc	foundInUserDef

next:
	add	di, bx				; else next entry
	cmp	di, dx				; end of array?
	jl	locLoop				; loop if not
EC<	ERROR_G FORMAT_ASSERTION_FAILED >

	mov	di, SPREADSHEET_FORMAT_NAME_NOT_FOUND	; indicate no match

foundInUserDef:
	call	VMUnlock

	mov	cx, di				; cx <- format token / error
	ret
SpreadsheetGetFormatTokenWithParams	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoParamsMatch?

DESCRIPTION:	Checks to see if there is a match between the 2 format
		parameters (the FloatFloatToAsciiParams).

CALLED BY:	INTERNAL (SpreadsheetGetFormatTokenWithParams)

PASS:		ds:si - params
		es:di - FormatParams structure

RETURN:		carry clear if match, set otherwise

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

-------------------------------------------------------------------------------@

DoParamsMatch?	proc	near	uses	di,si,cx
	.enter

;	add	di, offset FP_params		; assume offset is 0

	mov	cx, size FloatFloatToAsciiParams
	repe	cmpsb

	clc					; assume match
	je	done				; branch if assumption correct
	stc
done:
	.leave
	ret
DoParamsMatch?	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetGetFormatTokenWithName

DESCRIPTION:	Locates a format entry given the name.

		NOTE:
		It is up to the user of the spreadsheet library to ensure
		uniqueness.  The Spreadsheet library does not require it.
		All it does is search for the first name that matches, so
		if name uniqueness is important to you, perform a check with
		this routine before calling MSG_SPREADSHEET_ADD_FORMAT.

CALLED BY:	INTERNAL (MSG_SPREADSHEET_GET_FORMAT_TOKEN_WITH_NAME)

PASS:		dx:bp - address of null-terminated name

RETURN:		cx - format token of format entry containing name
		     SPREADSHEET_FORMAT_NAME_NOT_FOUND if not found

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

SpreadsheetGetFormatTokenWithName	method	dynamic SpreadsheetClass,
				MSG_SPREADSHEET_GET_FORMAT_TOKEN_WITH_NAME

	push	ds,di				; save spreadsheet instance

	;-----------------------------------------------------------------------
	; search pre-defined format table

	mov	ds, dx				; ds:si <- name
	mov	si, bp
NOFXIP<	segmov	es, dgroup, ax						>
FXIP<	mov_tr	ax, bx				; save bx value		>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefES			; es = dgroup		>
FXIP<	mov_tr	bx, ax				; restore bx		>
	mov	di, offset FormatPreDefTbl

	mov	bx, size FormatParams		; bx <- bytes to next entry
	mov	dx, offset FormatPreDefTblEnd	; dx <- end of table
locPreDefLoop:
	call	DoesNameMatch?
	jc	nextPreDef

	;
	; found in pre-def table
	;
	pop	ax				; rid stuff on stack
	pop	ax
	or	di, FORMAT_ID_PREDEF		; indicate origin
	clc					; indicate success
	jmp	short done

nextPreDef:
	add	di, bx				; di <- offset to next entry
	cmp	di, dx				; at end yet?
	jl	locPreDefLoop			; loop if not
EC<	ERROR_G FORMAT_ASSERTION_FAILED >

	mov	dx, ds
	mov	bp, si
	pop	ds,di				; retrieve spreadsheet instance

	;-----------------------------------------------------------------------
	; search user-defined format array
	; dx:bp = name

	push	dx,bp				; save address of name
	mov	cx, size FormatArrayHeader
	call	SpreadsheetLockFormatEntry	; es:di <- format entry
						; bp <- VM mem handle
						; ds:si <- instance data
						; dx <- offset to end of array
	pop	ds,si				; retrieve address of name

	mov	bx, size FormatEntry
locLoop:
	cmp	es:[di].FE_used, 0		; is entry in use?
	je	next				; next entry if not

EC<	call	ECCheckUsedEntry >
	call	DoesNameMatch?
	jnc	foundInUserDef

next:
	add	di, bx				; else next entry
	cmp	di, dx				; end of array?
	jl	locLoop				; loop if not
EC<	ERROR_G FORMAT_ASSERTION_FAILED >

	mov	di, SPREADSHEET_FORMAT_NAME_NOT_FOUND	; indicate no match

foundInUserDef:
	call	VMUnlock

done:
	mov	cx, di				; cx <- format token / error
	ret
SpreadsheetGetFormatTokenWithName	endm	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SpreadsheetIsFormatTheSame?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Checks to see if the FormatParams for the given token
		match the FormatParams that are passed.

CALLED BY:	INTERNAL (PasteHandleFormatConflicts)

PASS:		cx - user def FormatParams
		dx:bp - FormatParams

RETURN:		cx - SPREADSHEET_FORMAT_PARAMS_MATCH /
		     SPREADSHEET_FORMAT_PARAMS_DONT_MATCH

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetIsFormatTheSame?	method	dynamic SpreadsheetClass,
				MSG_SPREADSHEET_IS_FORMAT_THE_SAME

	push	dx,bp				; save address of params
	call	SpreadsheetLockFormatEntry	; es:di <- format entry
						; bp <- VM mem handle
						; ds:si <- instance data
						; dx <- offset to end of array
	pop	ds,si				; retrieve address of name

	add	di, offset FE_params
	mov	cx, size FormatParams
	repe	cmpsb
	tst	cx

	call	VMUnlock			; unlock format entry

	mov	cx, SPREADSHEET_FORMAT_PARAMS_MATCH
	je	done
	mov	cx, SPREADSHEET_FORMAT_PARAMS_DONT_MATCH

done:
	ret
SpreadsheetIsFormatTheSame?	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoesNameMatch?

DESCRIPTION:	

CALLED BY:	INTERNAL (SpreadsheetGetFormatTokenWithName)

PASS:		ds:si - null terminated name1
		es:di - FormatParams structure

RETURN:		carry clear if match, set otherwise

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

DoesNameMatch?	proc	near	uses	di,si
	.enter

	add	di, offset FP_formatName
matchLoop:
	mov	al, ds:[si]
	cmpsb
	jne	noMatch

	tst	al
	jne	matchLoop

	clc
	jmp	short done

noMatch:
	stc

done:
	.leave
	ret
DoesNameMatch?	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetAddFormat

DESCRIPTION:	Add the given format to the format array.

CALLED BY:	INTERNAL (MSG_SPREADSHEET_ADD_FORMAT)

PASS:		dx:bp - ptr to a FormatParams structure
		*ds:si - instance ptr
		ds:di - ptr to spreadsheet instance

RETURN:		cx - SpreadsheetFormatError
		if cx = SPREADSHEET_FORMAT_NO_ERROR
		    dx - token

DESTROYED:	everything

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

SpreadsheetAddFormat	method	dynamic SpreadsheetClass,
			MSG_SPREADSHEET_ADD_FORMAT
	mov	si, di			; ds:si <- instance data
	mov	bx, bp			; bx <- offset
	call	SpreadsheetLockFreeFormatEntry
					; es:di <- address of FormatEntry
					; (di = token), bp - mem handle
					; cx <- error code
	jc	done

	;
	; allocation successful
	;

	mov	ax, es:FAH_numUserDefEntries	; assign list entry num
	add	ax, NUM_PRE_DEF_FORMATS
	mov	es:[di].FE_listEntryNumber, ax

	inc	es:FAH_numUserDefEntries
	mov	es:[di].FE_used, -1	; mark entry as used
	mov	ds, dx			; ds:si <- FormatParams
	mov	si, bx
	mov	cx, size FormatParams
	mov	dx, di			; dx <- new token
	rep	movsb

	call	VMDirty
	call	VMUnlock
	mov	cx, SPREADSHEET_FORMAT_NO_ERROR
done:
	ret
SpreadsheetAddFormat	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetChangeFormat

DESCRIPTION:	Replaces the parameters of the given format.

CALLED BY:	INTERNAL (MSG_SPREADSHEET_CHANGE_FORMAT)

PASS:		cx - format token of format to delete
		dx:bp - ptr to a FormatParams structure
		*ds:si - instance ptr
		ds:di - ptr to spreadsheet instance

RETURN:		cx - 0 if successful
		     -1 otherwise

DESTROYED:	everything

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

SpreadsheetChangeFormat	method	dynamic SpreadsheetClass,
			MSG_SPREADSHEET_CHANGE_FORMAT

	push	dx,bp
	call	SpreadsheetLockFormatEntry	; es:di <- format entry
						; bp <- VM mem handle
	pop	ds,si
	mov	cx, size FormatParams
	rep	movsb

	call	VMDirty
	call	VMUnlock
	ret
SpreadsheetChangeFormat	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetDeleteFormat

DESCRIPTION:	Deletes the given format from the format array.

CALLED BY:	INTERNAL (MSG_SPREADSHEET_DELETE_FORMAT)

PASS:		cx - format token to delete
		*ds:si - instance ptr
		ds:di - ptr to spreadsheet instance

RETURN:		nothing

DESTROYED:	everything

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	zero out the FE_used field in the format entry
	update the list entry numbers
	decrement the FAH_numUserDefEntries in the format array
	for all styles that use the format,
		replace the format with FORMAT_ID_GENERAL

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

SpreadsheetDeleteFormat	method dynamic SpreadsheetClass,
			MSG_SPREADSHEET_DELETE_FORMAT

	;-----------------------------------------------------------------------
	; free format entry

	call	SpreadsheetLockFormatEntry	; es:di <- format entry
						; bp <- VM mem handle
						; ds:si <- instance ptr
	mov	es:[di].FE_used, 0

	call	SpreadsheetDeleteFormatUpdateListEntries	; dest ax,cx

	dec	es:FAH_numUserDefEntries	; dec count
EC<	ERROR_L	FORMAT_ASSERTION_FAILED >

	call	VMDirty
	call	VMUnlock
	;
	; Remove all references to this format by replacing them with
	; the general format.
	;
	mov	ax, di				;ax <- format token to replace
	mov	dx, FORMAT_ID_GENERAL		;dx <- format token replacement
	call	StyleReplaceNumFormat
	ret
SpreadsheetDeleteFormat	endm


;*******************************************************************************
;	UTILITY ROUTINES
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetGetListEntryWithToken

DESCRIPTION:	Return the list entry number given the format token.
		If the format entry is user-defined, it must have been
		added by SpreadsheetAddFormat.

		SpreadsheetGetFormatToken performs the reverse function
		by returning a token given the list entry number.

CALLED BY:	INTERNAL ()

PASS:		cx - format token
		ds:si - spreadsheet instance

RETURN:		cx - list entry number

DESTROYED:	ax,bx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

SpreadsheetGetListEntryWithToken	proc	far	uses	es,di,bp
	.enter
	test	cx, FORMAT_ID_PREDEF
	je	userDef

	mov	ax, cx
	and	ax, not FORMAT_ID_PREDEF	; ax <- offset into table
	clr	dx
	mov	cx, size FormatParams
	div	cx
EC<	tst	dx >
EC<	ERROR_NE FORMAT_ASSERTION_FAILED >

	mov	cx, ax				; cx <- list entry
	jmp	short done

userDef:
	mov	di, si				; ds:di <- spreadsheet instance
	call	SpreadsheetLockFormatEntry	; es:di <- format entry
						; bp <- VM mem handle
						; ds:si <- instance data
						; dx <- offset to end of array
	mov	cx, es:[di].FE_listEntryNumber
	call	VMUnlock

done:
	.leave
	ret
SpreadsheetGetListEntryWithToken	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetLockFreeFormatEntry

DESCRIPTION:	Tries to locate a free FormatEntry.  If none is
		found, resize the format array to create one.

		Caller must unlock the VM block if this routine is
		successful.

CALLED BY:	INTERNAL (SpreadsheetAddFormat)

PASS:		ds:si - pointer to Spreadsheet instance data

RETURN:		carry clear if successful
		    es:di - address of FormatEntry (di = format token)
		    bp - mem handle
		carry set otherwise
		    cx - SpreadsheetFormatError
			SPREADSHEET_FORMAT_TOO_MANY_FORMATS
			SPREADSHEET_FORMAT_CANNOT_ALLOC

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

SpreadsheetLockFreeFormatEntry	proc	near	uses	bx,dx
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_formatArray	; bx <- VM handle
	mov	bx, ds:[si].SSI_cellParams.CFP_file	; bx <- VM file handle
	call	VMLock			; bp <- mem handle

	mov	es, ax			; es:di <- first format entry
EC<	cmp	es:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FORMAT_BAD_FORMAT_ARRAY >

	mov	di, size FormatArrayHeader
	mov	cx, size FormatEntry
	mov	dx, es:FAH_formatArrayEnd	; dx <- end

searchLoop:
	cmp	es:[di].FE_used, 0	; free?
	je	done			; branch if so

EC<	call	ECCheckUsedEntry >
	add	di, cx			; di <- addr of next boolean
	cmp	di, dx			; past end?
	jb	searchLoop		; loop if not

	;
	; all entries taken, expansion needed
	;
	cmp	es:FAH_numUserDefEntries, MAX_FORMATS
	je	tooManyFormats

	mov	ax, dx			; ax <- current size in bytes
	add	ax, cx			; inc ax by size of entry
	push	ax			; save end of array
	mov	ch, mask HAF_LOCK
	xchg	bx, bp
	call	MemReAlloc
	mov	bp, bx
	pop	di			; retrieve end of array
	mov	cx, SPREADSHEET_FORMAT_CANNOT_ALLOC
	jc	error

	mov	es, ax
	mov	es:FAH_formatArrayEnd, di
	sub	di, size FormatEntry	; di <- offset to empty entry

EC<	mov	es:[di].FE_sig, FORMAT_ENTRY_SIG >
	clc

done:
	.leave
	ret

tooManyFormats:
	mov	cx, SPREADSHEET_FORMAT_TOO_MANY_FORMATS
error:
	call	VMUnlock
	stc
	jmp	short done
SpreadsheetLockFreeFormatEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetLockFormatEntry

DESCRIPTION:	Lock and return the format entry with the given token.
		The token must belong to a user-defined format.

		Caller must unlock the VM block.

CALLED BY:	INTERNAL (SpreadsheetGetFormatToken,
			  SpreadsheetChangeFormat,
			  SpreadsheetDeleteFormat)

PASS:		cx - format token
		ds:di - ptr to spreadsheet instance

RETURN:		es:di - address of FormatEntry (di = format token)
		bp - mem handle
		ds:si - instance ptr
		dx - offset to end of format array

DESTROYED:	ax,bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

SpreadsheetLockFormatEntryFar	proc	far
	call	SpreadsheetLockFormatEntry
	ret
SpreadsheetLockFormatEntryFar	endp

SpreadsheetLockFormatEntry	proc	near
	class	SpreadsheetClass

EC<	test	cx, FORMAT_ID_PREDEF >
EC<	ERROR_NE	FORMAT_BAD_USER_DEF_TOKEN >

	mov	si, di				; ds:si <- instance data
EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_formatArray
	mov	bx, ds:[si].SSI_cellParams.CFP_file	; bx <- VM file handle
	call	VMLock

	mov	es, ax				; es:di <- format entry
	mov	di, cx
	mov	dx, es:FAH_formatArrayEnd

EC<	cmp	es:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FORMAT_BAD_FORMAT_ARRAY >
EC<	cmp	es:[di].FE_used, 0 >		; valid content?
EC<	je	ok >				; branch if so
EC<	cmp	es:[di].FE_used, -1 >		; valid content?
EC<	ERROR_NE FORMAT_BAD_FORMAT_ENTRY >	; error if not
EC< ok: >

	ret
SpreadsheetLockFormatEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetDeleteFormatUpdateListEntries

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		es:0 - format array
		es:di - deleted format entry
		dx - offset to end of array

RETURN:		

DESTROYED:	ax,cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	ax <- list entry number of deleted entry
	for all format entries
	    if list entry number > ax
		dec list entry number

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

SpreadsheetDeleteFormatUpdateListEntries	proc	near	uses	di
	.enter
EC<	cmp	es:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FORMAT_BAD_FORMAT_ARRAY >

	mov	ax, es:[di].FE_listEntryNumber
	mov	cx, size FormatEntry

	mov	di, size FormatArrayHeader
updateLoop:
	cmp	es:[di].FE_used, 0
	je	next

EC<	call	ECCheckUsedEntry >
	cmp	ax, es:[di].FE_listEntryNumber
EC<	ERROR_E FORMAT_BAD_FORMAT_LIST >
	jg	next

	dec	es:[di].FE_listEntryNumber

next:
	add	di, cx			; next format entry
	cmp	di, dx			; done?
	jl	updateLoop
EC<	ERROR_G	FORMAT_ASSERTION_FAILED >
	.leave
	ret
SpreadsheetDeleteFormatUpdateListEntries	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ECCheckUsedEntry

DESCRIPTION:	Check to see that the format entry is good.

CALLED BY:	INTERNAL ()

PASS:		es:di - format entry

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

if	ERROR_CHECK

ECCheckUsedEntry	proc	near
	cmp	es:FAH_signature, FORMAT_ARRAY_HDR_SIG
	ERROR_NE FORMAT_BAD_FORMAT_ARRAY

	cmp	es:[di].FE_used, -1
	ERROR_NE FORMAT_BAD_FORMAT_ENTRY

	cmp	es:[di].FE_sig, FORMAT_ENTRY_SIG
	ERROR_NE FORMAT_BAD_ENTRY_SIGNATURE
	ret
ECCheckUsedEntry	endp

endif

endif

SpreadsheetFormatCode	ends
