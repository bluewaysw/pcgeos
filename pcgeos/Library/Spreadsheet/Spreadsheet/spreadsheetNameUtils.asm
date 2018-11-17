COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetNameUtils.asm

AUTHOR:		John Wedgwood, Apr  3, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 4/ 3/91	Initial revision

DESCRIPTION:
	Utility routines which should only be called from the name-list code.
	(See spreadsheetNameList.asm)
	
	$Id: spreadsheetNameUtils.asm,v 1.1 97/04/07 11:14:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetNameCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameListLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the block which holds the name list

CALLED BY:	
PASS:		ds:si	= Spreadsheet instance
RETURN:		es	= segment address of the name block
		bp	= memory handle of the same block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameListLock	proc	near
	class	SpreadsheetClass
	uses	ax, bx, di
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; Load up the file handle before we do anything else.
	;
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	mov	ax, ds:[si].SSI_nameArray	; ax <- VM handle of array
	call	VMLock				; ax <- seg addr
						; bp <- mem handle
	mov	es, ax				; es <- seg addr
	.leave
	ret
NameListLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameListFindByName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the name list for a given name

CALLED BY:	
PASS:		es	= segment address of the name list
		ds:si	= Pointer to the name to find
		cx	= Length of the name
RETURN:		carry set if the name was found
		es:di	= Pointer to the NameStruct for the name,
			  or pointer to the place to put the new name.
		dx	= The # of defined entries encountered before this one
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This routine searches both the defined and undefined name lists.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Extra register needed in DBCS... (sigh)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameListFindByName	proc	near
SBCS <	uses	bx, cx					>
DBCS <	uses	ax, bx, cx				>
	.enter
	clr	dx			; No defined entries found yet.

	mov	bx, cx			; bx <- length of the name

	mov	di, size NameHeader	; es:di <- ptr to first entry

	mov	cx, es:NH_definedCount	; cx <- total # of entries
	add	cx, es:NH_undefinedCount
	jcxz	notFound		; Branch if not found
searchLoop:
	push	di, cx, bx		; Save offset, count, length
	mov	cx, bx			; cx <- length of string in ds:si

	mov	bx, es:[di].NS_length	; bx <- length of the string
	dec	bx			; Don't count the NULL

	add	di, size NameStruct	; es:di <- ptr to the string

	call	CompareStringsNoCase	; Compare the strings
	pop	di, cx, bx		; Restore offset, count, length
	jbe	foundPosition		; Branch if position has been located
	;
	; Check to see if that entry was defined
	;
	test	es:[di].NS_flags, mask NF_UNDEFINED
	jnz	notDefined		; Branch if not defined
	inc	dx			; One more defined entry found
notDefined:
if DBCS_PCGEOS
	mov	ax, es:[di].NS_length	; ax <- string length (incl C_NULL)
	shl	ax, 1			; ax <- string size (incl C_NULL)
	add	di, ax			; Skip the text
else
	add	di, es:[di].NS_length	; Skip the text
endif
	add	di, size NameStruct	; Skip the structure
	loop	searchLoop		; Loop to check next string
	;
	; The string was not found
	;
	jmp	notFound		; Branch to set stuff up for return
foundPosition:
	jne	notFound		; Branch if position is OK, but strings
					;    don't match
	stc				; Signal we found it
quit:
	.leave
	ret

notFound:
	clc				; Signal: not found
	jmp	quit
NameListFindByName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameListFindByToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a name structure given a token

CALLED BY:	
PASS:		es	= segment address of the name block
		cx	= Token to find
RETURN:		carry set if the name was found
		es:di	= Pointer to the NameStruct
		dx	= # of defined entries before the entry
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This routine searches both the defined and undefined name lists.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameListFindByToken	proc	near
SBCS<	uses	bx, cx						>
DBCS<	uses	ax, bx, cx						>
	.enter
	clr	dx			; None yet...

	mov	bx, cx			; bx <- token to find

	mov	di, size NameHeader	; es:di <- ptr to first entry

	mov	cx, es:NH_definedCount	; cx <- total # of entries
	add	cx, es:NH_undefinedCount
	jcxz	notFound		; Branch if not found
searchLoop:
	cmp	bx, es:[di].NS_token	; Check for same toke
	je	foundPosition		; Branch if same
	
	;
	; Check to see if that entry was defined
	;
	test	es:[di].NS_flags, mask NF_UNDEFINED
	jnz	notDefined		; Branch if not defined
	inc	dx			; One more defined entry found
notDefined:

if DBCS_PCGEOS
	mov	ax, es:[di].NS_length
	shl	ax, 1			; ax <- string size w/C_NULL
	add	di, ax			; Skip the text
else
	add	di, es:[di].NS_length	; Skip the text
endif
	add	di, size NameStruct	; Skip the structure
	loop	searchLoop		; Loop to check next string

notFound:
	clc				; Signal: not found
	jmp	quit			; Quit

foundPosition:
	stc				; Signal we found it
quit:
	.leave
	ret
NameListFindByToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameListGetDefinedEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to a given defined-name entry

CALLED BY:	
PASS:		es	= segment address of the name list
		cx	= the defined name entry to get
RETURN:		es:di	= Pointer to the defined name entry
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameListGetDefinedEntry	proc	near
SBCS <	uses	cx						>
DBCS <	uses	ax, cx						>
	.enter
	;
	; Check for the caller requesting an entry beyond the end of the
	; current list of names.
	;
EC <	cmp	cx, es:NH_definedCount		>
EC <	ERROR_AE REQUESTED_ENTRY_IS_TOO_LARGE	>
	
	mov	di, size NameHeader	; es:di <- ptr to first entry
searchLoop:
	test	es:[di].NS_flags, mask NF_UNDEFINED
	jnz	nextEntry		; Branch if undefined
	jcxz	done			; Quit if found the entry we want
	dec	cx			; One less entry to search through
nextEntry:
if DBCS_PCGEOS
	mov	ax, es:[di].NS_length
	shl	ax, 1			; ax <- string size w/C_NULL
	add	di, ax			; Skip the name
else
	add	di, es:[di].NS_length	; Skip the name
endif
	add	di, size NameStruct	; Skip the structure
	jmp	searchLoop		; Loop to find the next one
done:
	.leave
	ret
NameListGetDefinedEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameListRemoveEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a name structure from the name list

CALLED BY:	
PASS:		es:di	= Pointer to structure to remove
		bp	= Memory handle for the block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Shortens vm block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameListRemoveEntry	proc	near
	uses	ax, bx, cx, dx, ds, si, di
	.enter
	mov	al, es:[di].NS_flags	; al <- flags for this name

	mov	cx, es:[di].NS_length	; cx <- length of the name
DBCS<	shl	cx, 1			; cx <- name size		>
	add	cx, size NameStruct	; cx <- # of bytes to delete
	mov	dx, es:NH_blockSize	; dx <- size of the block
	segmov	ds, es			; need both seg-registers in same place
	;
	; OK...
	; es:di	= Pointer to the place to delete the bytes
	; cx	= # of bytes to delete
	; dx	= Size of the block
	;
	push	cx			; Save # of bytes to nuke
	mov	si, di
	add	si, cx			; ds:si <- ptr to source
	sub	dx, si			; dx <- # of bytes to move
	mov	cx, dx			; cx <- # of bytes to move
	
	jcxz	skipMove		; Branch if nothing to delete
	rep	movsb			; Shift the data
skipMove:
	pop	cx			; Restore # of bytes to nuke
	
	sub	es:NH_blockSize, cx	; Update the size of the block
	
	mov	bx, bp			; bx <- memory handle
	
	push	ax			; Save name flags
	mov	ax, es:NH_blockSize	; ax <- new size for block
	mov	ch, mask HAF_NO_ERR	; No errors please
	call	MemReAlloc		; Resize the block
	mov	es, ax			; Reset the segment address
	pop	ax			; Restore name flags
	;
	; We either decrement the definedCount or the undefinedCount
	; depending on which type of name we removed.
	;
	mov	di, offset NH_definedCount
	test	al, mask NF_UNDEFINED
	jz	decCounter		; Branch if defined name
	mov	di, offset NH_undefinedCount
decCounter:
	dec	{word} es:[di]		; One less name of this type

	call	VMDirty			; Dirty the block
	.leave
	ret
NameListRemoveEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameListInsertEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a name entry where caller wants it.  Pushes everything
		else down to make space.

CALLED BY:	
PASS:		es:di	= Pointer to the place to put the name entry
		bp	= Memory handle of the name-list block
		ds:si	= The text of the name
		cx	= The length of the text of the name
		ax	= Token to use
RETURN:		es:di	= Pointer to name structure
		(Note: es may change since the block is be re-alloc'd)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	new vmblock size = size vmblock + size NameStruct + text size
	MemReAlloc( vmblock, new vmblock size ).

	dest = last byte of vmblock
	counter = last byte - (size NameStruct + text size)
	if( counter > 0 )	(* some entries already exist *)
		memory copy tail first:	new vmblock size (src)
					original size (dest)
					coutner (byte count).
	set node flags = 0
	set token = Token
	set length = Length
	set text = Text + C_NULL.

	VMDirty( vmblock )
	return.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The caller is responsible for setting any flags and for increasing
	the definedCount or the undefinedCount depending on what type of
	name it is. This routine only creates the empty name structure.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version
	witt	11/18/93	DBCS-ized and pseudo-coded

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameListInsertEntry	proc	near
	uses	ax, bx, cx, dx, di, si
	.enter
	mov	dx, cx			; Want size in dx
	inc	dx			; Account for the NULL now
DBCS<	shl	dx, 1			; dx <- string size		>

	mov	cx, es:NH_blockSize	; cx <- new total size
	add	cx, size NameStruct	; Need space for the structure
	add	cx, dx			; Need space for the name
	mov	es:NH_blockSize, cx	; Save the new block size
	
	push	cx, ax			; Save new block size, token
	mov	ax, cx			; ax <- size to allocate to
	mov	ch, mask HAF_NO_ERR	; No errors please...
	mov	bx, bp			; bx <- memory handle
	call	MemReAlloc		; Make the block bigger (nukes cx)
	mov	es, ax			; Fix up the segment address
	pop	cx, ax			; Restore new block size, token
	;
	; ax	= Token number
	; cx	= New size of the block
	; dx	= Size of the string (with NULL)
	; es:di	= Pointer to the place to insert (relocated name entry)
	;

	push	ds, si, di, dx, bx
	segmov	ds, es			; Need segment registers in same block
	add	dx, size NameStruct	; dx <- total # of bytes to insert

	mov	bx, di			; bx <- position to insert at

	mov	di, cx			; es:di <- ptr past end of block
	dec	di			; es:di <- ptr to last byte of block
	
	mov	si, di			; si <- dest - # to insert
	sub	si, dx

	mov	cx, si			; cx <- # of bytes to move
	sub	cx, bx
	inc	cx			; zero diff => just move C_NULL

	jcxz	skipMove		; Do nothing if we have nothing to move
	std				; Move backwards
	rep	movsb			; Move the bytes
	cld				; Reset direction flag
skipMove:
	pop	ds, si, di, dx, bx
	;
	; OK, now we've inserted the new structure.
	; We need to copy the text of the name in and set the flags and
	; the token for the new name.
	;
	mov	es:[di].NS_flags, 0	; Initialize all flags to 0
	
	mov	es:[di].NS_token, ax	; Save token for the name
	
DBCS<	shr	dx, 1			; dx <- text length		>
	mov	es:[di].NS_length, dx	; Save the length of the string
	
	add	di, size NameStruct	; es:di <- place to put the string
	mov	cx, dx			; cx <- # of bytes to move
	dec	cx			; No NULL to move
	LocalCopyNString		; Copy the text of the name
SBCS<	clr	al			; Need to store a NULL		>
DBCS<	clr	ax			; Need to store a NULL		>
	LocalPutChar	esdi, ax	; Save the NULL
	
	call	VMDirty			; Dirty the VM block
	.leave
	ret
NameListInsertEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameListGetNewToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a new token to use

CALLED BY:	NameAddUndefinedEntry, NameAddDefinedEntry, NameDefineEntry
PASS:		es	= Segment address of the name-list
RETURN:		ax	= Next token to use
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameListGetNewToken	proc	near
	mov	ax, es:NH_nextToken	; ax <- token to use
	inc	es:NH_nextToken		; Move to next token
	ret
NameListGetNewToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameListCleanupUndefinedEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove all undefined entries that are not referenced.

CALLED BY:	SpreadsheetAllocFormulaCell
PASS:		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Foreach undefined entry w/ no dependencies
	    remove the entry

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/13/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameListCleanupUndefinedEntries	proc	near
SBCS <	uses	cx, di, bp, es					>
DBCS <	uses	ax, cx, di, bp, es				>
	.enter
	;
	; Lock down the block and start marching through it.
	;
	call	NameListLock			; es <- name list segment
						; bp <- name list handle
	mov	di, size NameHeader		; di <- offset to list
	mov	cx, es:NH_undefinedCount	; cx <- # of undefined

nameLoop:
	;
	; ds:si	= Spreadsheet instance
	; es:di	= Current name
	; es:0	= NameHeader
	; cx	= Number of undefined entries left to process
	; bp	= Block handle of name list
	;
	jcxz	quitUnlock			; Branch if none undefined
	
	;
	; Process the next name
	;
	test	es:[di].NS_flags, mask NF_UNDEFINED
	jz	nextEntry
	
	dec	cx				; One less entry next time
	
	;
	; It's an undefined name, check to see if it has any dependents
	;
	call	CheckForDependentsAndRemoveIfNone
	jc	nameLoop			; Loop if we did remove it
	
	;
	; We didn't remove it. This means that we need to skip over the entry.
	; Had we removed it, the following entry would have moved backwards
	; to land right at es:di, so we don't advance the pointer in that case.
	;

nextEntry:
if DBCS_PCGEOS
	mov	ax, es:[di].NS_length
	shl	ax, 1				; ax <- string size
	add	di, ax				; Skip the text
else
	add	di, es:[di].NS_length		; Skip the text
endif
	add	di, size NameStruct		; Skip the structure
	jmp	nameLoop			; Loop to process next entry

quitUnlock:
	call	VMUnlock			; Release the block
	.leave
	ret
NameListCleanupUndefinedEntries	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForDependentsAndRemoveIfNone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for an undefined name entry having dependents and if
		it has none, remove the entry.

CALLED BY:	NameListCleanupUndefinedEntries
PASS:		ds:si	= Spreadsheet instance
		es:di	= NameList entry
RETURN:		carry set if we did remove the entry
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This code assumes that removing an entry will not cause the name-list
	to move around on the heap. This seems safe, since the list can only
	get smaller.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/13/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForDependentsAndRemoveIfNone	proc	near
	uses	ax, cx, di, es
	.enter
	;
	; Lock the cell down.
	;
	mov	ax, NAME_ROW		; ax <- row of the cell
	mov	cx, es:[di].NS_token	; cx <- column of the cell
	SpreadsheetCellLock		; *es:di <- ptr to definition
EC <	ERROR_NC	NAME_MUST_EXIST	>

	;
	; Check to see if it has any dependents.
	;
	mov	di, es:[di]		; es:di <- cell
	tst	es:[di].CC_dependencies.segment
	jnz	unlockHasDependents
	
	;
	; The cell has no dependents, we need to nuke it.
	;
	SpreadsheetCellUnlock		; Release the cell
	call	NameRemoveEntry		; See 'ya

	stc				; Signal: we did remove it
quit:
	.leave
	ret

unlockHasDependents:
	;
	; The cell has dependents, we can't remove it.
	;
	SpreadsheetCellUnlock		; Release the cell
	clc				; Signal: did not delete
	jmp	quit

CheckForDependentsAndRemoveIfNone	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareStringsNoCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two strings without regard to case

CALLED BY:	NameFindByName
PASS:		ds:si	= Pointer to one string
		cx	= Length of that string
		es:di	= Pointer to the other string
		bx	= Length of the other string
RETURN:		flags set for compare of (ds:si vs es:di)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/91	Initial version
	witt	11/15/93	DBCS-ized (lengths are good)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareStringsNoCase	proc	near
if DBCS_PCGEOS
	uses	cx, bp
	.enter
	mov	bp, cx			; bp <- length of first string
	cmp	cx, bx			; Want to use the smallest length
	jbe	compare			; Branch if cx is smaller
	mov	cx, bx			; cx <- smallest length
compare:
	call	LocalCmpStringsNoCase	; sets flags only.
	jne	done			; something not same..

	;
	; The strings are the same... Unless they are of different lengths.
	; In that case the smaller string is less than the largest string.
	; We can just basically compare the length of the first string to
	; the length of the second.
	;
	cmp	bp, bx			; Compare the lengths
done:
	.leave
	ret

else
	uses	ax, cx, dx, si, di, bp
	.enter
	mov	bp, cx			; bp <- length of first string
	clr	ah, dh			; clear high bytes for LocalUpcaseChar

	cmp	cx, bx			; Want to use the smallest length
	jbe	compare			; Branch if cx is smaller
	mov	cx, bx			; cx <- smallest length
compare:
	;
	; Do the comparison, after upcasing both chars.
	;
	lodsb
	call	LocalUpcaseChar
	mov	dl, al			; dl <- char from ds:si, upcased
	mov	al, es:[di]
	inc	di			; es:di <- next char
	call	LocalUpcaseChar		; al <- char from es:di, upcased
	cmp	dl, al
	jne	done			; Branch if different
	loop	compare

	;
	; The strings are the same... Unless they are of different lengths.
	; In that case the smaller string is less than the largest string.
	; We can just basically compare the length of the first string to
	; the length of the second.
	;
	cmp	bp, bx			; Compare the lengths
done:
	.leave
	ret
endif

CompareStringsNoCase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetCellNukeDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the dependency list for a given cell.

CALLED BY:	Utility
PASS:		ds:si	= Spreadsheet instance
		es:di	= Pointer to the cell
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	You had better have a really good reason for calling this routine.

	I highly recommend that you do the following after calling
	this routine:
		
		- Zero out the cells CC_dependencies.segment field
		- Dirty the cell

	Neither of these is done here. It is left up to the discretion
	of the caller to do this.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetCellNukeDependencies	proc	far
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, es, di
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	mov	cx, es:[di].CC_dependencies.segment
	mov	dx, es:[di].CC_dependencies.offset

nukeLoop:
	;
	; cx.dx = Current block in the dependency list chain.
	;
	jcxz	quit			; Branch if no more dependency blocks

	mov	ax, cx			; ax.di <- current block
	mov	di, dx

	push	ax, di			; Save current block
	call	DBLock			; *es:di <- this block
	mov	di, es:[di]		; es:di <- this block
	
	;
	; es:di = Ptr to current block
	; bx	= File handle
	;
	; cx.dx <- group/item to the next block
	;
	mov	cx, es:[di].DLH_next.segment
	mov	dx, es:[di].DLH_next.segment
	
	call	DBUnlock		; Release current entry
	pop	ax, di			; Restore current entry group/item
	
	call	DBFree			; Free the current item
	
	jmp	nukeLoop		; Loop to process next block
quit:
	.leave
	ret
SpreadsheetCellNukeDependencies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetCreateEmptyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an empty cell with no dependencies

CALLED BY:	NameCallback via callbackHandlers
PASS:		ds:si	= Pointer to spreadsheet instance
		ax	= Row of cell to create
		cx	= Column of cell to create
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Create an empty cell with nothing but a dependency list.
	Dies if it can't create the cell.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetCreateEmptyCell	proc	far
	uses	bx
	.enter
EC <	call	ECCheckInstancePtr		;>

	clr	bx				;bx <- use default attrs
	call	AllocEmptyCell

	.leave
	ret
SpreadsheetCreateEmptyCell	endp


SpreadsheetNameCode	ends
