COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetNameList.asm

AUTHOR:		John Wedgwood, Mar 22, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	3/22/91		Initial revision


DESCRIPTION:
	High level code which accesses and manipulates the name list.
	All these routines take ds:si pointing at the spreadsheet instance.
	
	If you are ever considering using the lower level routines, don't.
	Write another high level routine to do what you need.

	$Id: spreadsheetNameList.asm,v 1.1 97/04/07 11:14:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetNameCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameTokenFromText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the token for a name given the text of the name

CALLED BY:	PC_NameToToken
PASS:		ds:si	= Pointer to Spreadsheet instance
		es:di	= Pointer to the text
		cx	= Length of the text
RETURN:		carry set if the name was found
		ax	= The token
		cl	= NameFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameTokenFromTextFar	proc	far
	call	NameTokenFromText
	ret
NameTokenFromTextFar	endp

NameTokenFromText	proc	near
	uses	dx, bp, di, si, ds, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	push	es, di			; Save pointer to the name
	call	NameListLock		; es <- segment address of name block
					; bp <- Memory handle
	pop	ds, si			; Restore pointer to the name

	call	NameListFindByName	; es:di <- ptr to the name structure
					; dx <- defined entry #
	jnc	quit			; Branch if not found
	mov	ax, es:[di].NS_token	; ax <- token of found name
	mov	cl, es:[di].NS_flags	; cl <- name flags
quit:
	call	VMUnlock		; Unlock names, doesn't nuke flags
	.leave
	ret
NameTokenFromText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameAddUndefinedEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an undefined entry to the list of names

CALLED BY:	PC_NameToToken
PASS:		ds:si	= Pointer to Spreadsheet instance
		es:di	= Pointer to the name
		cx	= Length of the name
RETURN:		ax	= The token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The name had better not exist...

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameAddUndefinedEntryFar	proc	far
	call	NameAddUndefinedEntry
	ret
NameAddUndefinedEntryFar	endp

NameAddUndefinedEntry	proc	near
	uses	dx, bp, di, si, ds, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	push	es, di			; Save ptr to the name
	call	NameListLock		; es <- segment address of name block
					; bp <- memory handle
	pop	ds, si			; Restore ptr to the name

	call	NameListFindByName	; We expect that we won't find it
					; dx <- defined entry #
	;
	; If the name exists then the caller should not have called this routine.
	;
EC <	ERROR_C	NAME_SHOULD_NOT_ALREADY_EXIST	>
	;
	; es:di	= Pointer to the place to put it.
	; bp	= Memory handle
	; ds:si	= Pointer to the name
	; cx	= Length of the name
	;
	call	NameListGetNewToken	; ax <- new token
	call	NameListInsertEntry	; Insert a single entry

	;
	; The block is already dirty, and since we haven't unlocked it we
	; can set the flag without worrying about dirtying the block.
	;
	or	es:[di].NS_flags, mask NF_UNDEFINED
	inc	es:NH_undefinedCount	; One more undefined name

	call	VMUnlock		; Unlock names
	.leave
	ret
NameAddUndefinedEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameAddDefinedEntry	(Currently commented out)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an defined entry to the list of names

CALLED BY:	SpreadsheetAddName
PASS:		ds:si	= Pointer to Spreadsheet instance
		es:di	= Pointer to the name
		cx	= Length of the name
RETURN:		ax	= The token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The name had better not exist...

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	0
NameAddDefinedEntry	proc	near
	uses	dx, bp, di, si, ds, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	push	es, di			; Save ptr to the name
	call	NameListLock		; es <- segment address of name block
					; bp <- memory handle
	pop	ds, si			; ds:si <- pr to the name

	call	NameListFindByName	; We expect that we won't find it
					; dx <- defined entry #
EC <	ERROR_C	NAME_SHOULD_NOT_ALREADY_EXIST	>
	;
	; es:di	= Pointer to the place to put it.
	; bp	= Memory handle
	; ds:si	= Pointer to the name
	; cx	= Length of the name
	;
	call	NameListGetNewToken	; ax <- new token
	call	NameListInsertEntry	; Insert a single entry

	;
	; The block is already dirty, and since we haven't unlocked it we
	; can set the flag without worrying about dirtying the block.
	;
	inc	es:NH_definedCount	; One more defined name

	call	VMUnlock		; Unlock names
	.leave
	ret
NameAddDefinedEntry	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameTextFromToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a token to text

CALLED BY:	PC_FormatName
PASS:		ds:si	= Spreadsheet instance
		es:di	= Pointer to the place to put the name
		cx	= Token
		dx	= Max # of chars to write (length)
RETURN:		es:di	= Pointer past the inserted text
		dx	= # of characters written (length)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This routine searches both the defined and undefined name lists.
	Accept and return string lengths.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version
	witt	11/15/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameTextFromTokenFar	proc	far
	call	NameTextFromToken
	ret
NameTextFromTokenFar	endp
				
NameTextFromToken	proc	near
	uses	cx, bp, ds, si
	.enter
EC <	call	ECCheckInstancePtr		;>
	push	es, di			; Save destination

	call	NameListLock		; es <- segment address of name block
					; bp <- Memory handle
	push	dx			; Save max number of chars to write
	call	NameListFindByToken	; es:di <- ptr to the name structure
					; dx <- # of defined entries before this
	pop	dx			; Restore max number of chars to write
	jc	gotName			; Branch if found
	;
	; Temporary solution for a name not being found.
	;
	; This should never happen since a name that has dependents should
	; never be deleted.
	;
	; If it does then this is a bad thing and indicates corruption of
	; the name database in some manner.
	;
	; A fatal error is probably a reasonable result in the error-checking
	; version of the code, although since the name is already gone, it
	; may be very hard to determine just how it got removed.
	;
	ERROR	NAME_MUST_EXIST
gotName:
	segmov	ds, es			; ds:si <- ptr to the name
	mov	si, di
	add	si, size NameStruct

	mov	cx, es:[di].NS_length	; cx <- length of the name
	dec	cx			; Don't count the NULL
	pop	es, di			; Restore ptr to destination
	;
	; Copy the minimum of the length of the string and the number of
	; characters left in the buffer.
	;
	cmp	cx, dx
	jbe	writeString		; cx <- minimum
	mov	cx, dx
writeString:
	mov	dx, cx			; dx <- # of characters to write

	jcxz	afterWrite		; Branch if no space for writing
	LocalCopyNString		; Copy the name
afterWrite:

	call	VMUnlock		; Unlock names
	.leave
	ret
NameTextFromToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameFlagsFromToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the flags for a name given the token

CALLED BY:	SpreadsheetGetNameInfo
PASS:		ds:si	= Spreadsheet instance
		cx	= Token
RETURN:		cl	= NameFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameFlagsFromToken	proc	near
	uses	es, bp, di, dx
	.enter
EC <	call	ECCheckInstancePtr		;>
	call	NameListLock		; es <- segment address of name block
					; bp <- Memory handle
	call	NameListFindByToken	; es:di <- ptr to the name structure
					; dx <- # of defined entries before this
	jc	gotName			; Branch if found
	;
	; Temporary solution for a name not being found.
	;
	; This should never happen since a name that has dependents should
	; never be deleted.
	;
	; If it does then this is a bad thing and indicates corruption of
	; the name database in some manner.
	;
	; A fatal error is probably a reasonable result in the error-checking
	; version of the code, although since the name is already gone, it
	; may be very hard to determine just how it got removed.
	;
	ERROR	NAME_MUST_EXIST
gotName:
	mov	cl, es:[di].NS_flags
	
	call	VMUnlock		; Release the name list
	.leave
	ret
NameFlagsFromToken	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameLockDefinition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the definition of a name

CALLED BY:	PC_LockName
PASS:		ds:si	= Pointer to the spreadsheet instance
		cx	= Name token
RETURN:		ds:si	= Pointer to the name definition
		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NameLockDefinitionFar	proc	far
	call	NameLockDefinition
	ret
NameLockDefinitionFar	endp

NameLockDefinition	proc	near
	uses	bx, dx, es, di, bp
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; First check to see if that name is defined. If it's not then
	; we want to flag an error.
	;
	mov	ax, bp			; Save frame ptr into ax
	call	NameListLock		; es <- segment address of name block
					; bp <- block handle

	push	bp			; Save the block handle
	mov	bp, ax			; Restore the frame ptr

	call	NameListFindByToken	; es:di <- ptr to name entry
					; dx <- # of defined entries before
	;
	; If the name isn't found then that's a serious problem. That means
	; that we the name is referenced (in the formula that resulted in
	; calling this routine) but does not exist. That can only happen if
	; there was some horrible screwup like the dependency list code
	; losing dependencies...
	;
EC <	ERROR_NC	NAME_MUST_EXIST	; The name MUST be found	>
	test	es:[di].NS_flags, mask NF_UNDEFINED
	jnz	notDefined		; Branch if it is not defined
lockNameDef:
	mov	ax, NAME_ROW		; ax <- row of the cell
					; cx already holds the column
	SpreadsheetCellLock		; *es:di <- ptr to definition
EC <	ERROR_NC	NAME_MUST_EXIST	;>
	
	segmov	ds, es			; Need pointer in ds:si for return
	mov	si, ds:[di]
	add	si, CF_formula
	clc				; Signal: no error
quit:
	pop	bp			; Restore block handle
	call	VMUnlock		; Release the name-list block
	.leave
	ret

notDefined:
	;
	; The name is not defined... Normally we'd signal an error. If we are
	; generating dependencies then we really don't want to generate an
	; error since we aren't really using the value of the name.
	;
	test	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES
	jnz	lockNameDef		; Branch if we are making dependencies
	mov	al, PSEE_UNDEFINED_NAME
	stc				; Signal an error
	jmp	quit
NameLockDefinition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameCheckDefined
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a name is defined

CALLED BY:	PC_EmptyCell
PASS:		ds:si	= Spreadsheet instance
		ax,cx	= Row,Column of the name cell
RETURN:		carry set if the name is defined
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	0
NameCheckDefined	proc	near
	uses	dx, di, bp, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	call	NameListLock		; es <- segment address of name list
	call	NameListFindByToken	; es:di <- ptr to the structure
					; dx <- # of entries before
	;
	; The name must exist (otherwise we wouldn't have been able to remove
	; the last dependency associated with it.
	;
EC <	ERROR_NC NAME_DOES_NOT_EXIST	>
	
	test	es:[di].NS_flags, mask NF_UNDEFINED
	jnz	quit			; Branch if undefined (carry is clear)
	stc				; Signal: is defined
quit:
	call	VMUnlock		; Release the block
	.leave
	ret
NameCheckDefined	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameRemoveEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a name-list entry

CALLED BY:	PC_EmptyCell
PASS:		ds:si	= Spreadsheet instance
		cx	= Cell token
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameRemoveEntry	proc	near
	uses	dx, di, bp, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	call	NameListLock		; es <- segment address of name block
					; bp <- block handle
	call	NameListFindByToken	; es:di <- ptr to the structure
					; dx <- # of defined entries before
	;
	; The name must exist otherwise we wouldn't be trying to remove it.
	; 
EC <	ERROR_NC NAME_DOES_NOT_EXIST		>
	;
	; Remove the name entry.
	;
	call	NameListRemoveEntry	; Remove the name
	call	VMUnlock		; Unlock the name-list block
	.leave
	ret
NameRemoveEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameValidateString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function makes preliminary checks to see if a new
		name may be added to a spreadsheet's name-list.  Usually
		used in conjunction with NameCheckIfAlreadyUsed().

CALLED BY:	SpreadsheetValidateName, SpreadsheetAddName

PASS:		ds:si	= Spreadsheet class instance ptr
		ds:di	= Pointer to spreadsheet instance
		dx:bp	= Pointer to SpreadsheetNameParameters
				SNP_textLength
				SNP_text
RETURN:		if the name is acceptable:
		    carry clear
		    cx = 0
		else, if the name is NOT acceptable:
		    carry set
		    cx	= -1
		    dl	= ParserScannerEvaluatorError code
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NameValidateString	proc	near	uses	ax
	.enter

	call	NameCountNamesLeft	; ax <- # of names left
	tst	ax			; Check for no space left
	jz	errorNoNameSpace	; Branch if error

	tst	ss:[bp].SNP_textLength	; Check for no name text
	jz	zeroText		; Branch if name text is zero.

	clc				; everything's fine.
	clr	cx
	jmp	quit

zeroText:
	; Error: the text length is zero.
	mov	dl, PSEE_NO_NAME_GIVEN
	jmp	error

errorNoNameSpace:
	; Error: there is no more space for names.
	mov	dl, PSEE_NOT_ENOUGH_NAME_SPACE
error:
	mov	cx, -1
	stc				; set error flags.
quit:
	.leave
	ret
NameValidateString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameCheckIfAlreadyUsed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function checks to see if a name is already in
		a spreadsheet's name-list.

CALLED BY:	SpreadsheetValidateName

PASS:		ds:si	= Pointer to spreadsheet instance
		es:di	= Pointer to the text of the name
		cx	= Length of the name text

RETURN:		if the name was NOT found:
		    carry clear
		    cx = 0
		else, if the name WAS found:
		    carry set
		    cx	= -1
		    dl	= ParserScannerEvaluatorError code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	3/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NameCheckIfAlreadyUsed	proc	near	uses	di, si, bp, ds, es
	.enter

EC <	call	ECCheckInstancePtr		;>
	push	es, di			; Save name text ptr
	call	NameListLock		; es <- segment address of name list
					; bp <- memory block handle
	pop	ds, si			; ds:si <- ptr to the text

	call	NameListFindByName	; es:di <- ptr to the name
					; dx <- entry number
	call	VMUnlock		; Release the name list
	jnc	notUsed			; Branch if name doesn't exist

	;
	; The name already exists. Check if it's undefined...
	;
	test	es:[di].NS_flags, mask NF_UNDEFINED
	jz	nameDefined		; Branch if name is already defined

	;
	; The name is undefined, so signal that it is not being used.
	;
notUsed:
	clr	cx
	clc				; signal that the name is NOT already
					; used.
	jmp	quit
	
nameDefined:
	; The name already exists in the list.
	mov	cx, -1
	mov	dl, PSEE_NAME_ALREADY_DEFINED
	stc				; signal that the name is in use.

quit:
	.leave
	ret
NameCheckIfAlreadyUsed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameDefineEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Define a name entry.

CALLED BY:	SpreadsheetAddName
PASS:		ds:si	= Pointer to spreadsheet instance
		es:di	= Pointer to the text of the name
		cx	= Length of the name text
RETURN:		carry set if the name is already defined
		ax	= Token of the new name
		dx	= Entry number of new entry
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	;NameDefineEntryFar	proc	far
	;	call	NameDefineEntry
	;	ret
	;NameDefineEntryFar	endp

NameDefineEntry	proc	near
	uses	di, si, bp, ds, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	push	es, di			; Save name text ptr
	call	NameListLock		; es <- segment address of name list
					; bp <- memory block handle
	pop	ds, si			; ds:si <- ptr to the text
	call	NameListFindByName	; es:di <- ptr to the name
					; dx <- entry number
	jnc	addName			; Branch if name doesn't exist
	;
	; The name already exists. It may be undefined in which case our
	; job gets really easy.
	;
	test	es:[di].NS_flags, mask NF_UNDEFINED
	jz	errorNameDefined	; Branch if name is already defined
	;
	; Name is undefined, we need to just clear a bit and modify some
	; counters...
	;
	and	es:[di].NS_flags, not mask NF_UNDEFINED
	dec	es:NH_undefinedCount	; One less undefined name
	jmp	adjustCountGetToken	; Branch to quit

addName:
	;
	; Name is not defined we need to add a new structure.
	;
	call	NameListGetNewToken	; ax <- new token
	call	NameListInsertEntry	; Add the new entry at es:di

adjustCountGetToken:
	inc	es:NH_definedCount	; One more defined name
	mov	ax, es:[di].NS_token	; ax <- token of new name
	call	VMDirty			; Dirty the block
	clc				; Signal: no error

quit:
	call	VMUnlock		; Release the name list
	.leave
	ret

errorNameDefined:
	mov	ax, es:[di].NS_token
	stc				; Signal: name defined
	jmp	quit			; Branch to return the error
NameDefineEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameDefineEntryGivenToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Define a name given the text and the token.

CALLED BY:	SpreadsheetChangeName
PASS:		ds:si	= Spreadsheet instance
		ax	= Token for the name
RETURN:		dx	= List entry number of the name
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The name must exist, but must be marked undefined.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameDefineEntryGivenTokenFar	proc	far
	call	NameDefineEntryGivenToken
	ret
NameDefineEntryGivenTokenFar	endp

NameDefineEntryGivenToken	proc	near
	uses	cx, di, bp, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	call	NameListLock		; es <- segment address of name list
					; bp <- memory block handle
	;
	; Find out if a name with this token already exists.
	;
	mov	cx, ax			; cx <- token
	call	NameListFindByToken	; carry set if found
					; es:di <- ptr to name structure
					; dx <- Entry number
	;
	; The name must exist and should be undefined.
	;
EC <	ERROR_NC NAME_DOES_NOT_EXIST				>
	;
	; This code was removed because this routine is now being used
	; to define an undefined name (when pasting).
	;
;;;EC <	test	es:[di].NS_flags, mask NF_UNDEFINED		>
;;;EC <	ERROR_Z	NAME_SHOULD_BE_UNDEFINED			>
		
	test	es:[di].NS_flags, mask NF_UNDEFINED
	jz	quit			; Branch if already defined

	;
	; Mark the name as defined and up the number of defined entries.
	;
	and	es:[di].NS_flags, not mask NF_UNDEFINED
	dec	es:NH_undefinedCount	; One less undefined name
	inc	es:NH_definedCount	; One more defined name

	call	VMDirty			; Dirty the name list
quit:
	call	VMUnlock		; Release the name list
	.leave
	ret
NameDefineEntryGivenToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameGetListCounts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of defined and undefined entries in the
		name-list.

CALLED BY:	SpreadsheetAddName
PASS:		ds:si	= Spreadsheet instance
RETURN:		dx	= # of defined names
		bp	= # of undefined names
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameGetListCounts	proc	near
	uses	ax, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	call	NameListLock		; es <- seg addr of name list
					; bp <- memory handle
	mov	dx, es:NH_definedCount
	mov	ax, es:NH_undefinedCount

	call	VMUnlock		; Release the name-list
	
	mov	bp, ax			; Return count in ax
	.leave
	ret
NameGetListCounts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameMarkUndefined
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark a name-list entry as undefined

CALLED BY:	SpreadsheetDeleteName
PASS:		ds:si	= Spreadsheet instance
		cx	= Token of the name
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameMarkUndefined	proc	near
	uses	dx, di, bp, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	call	NameListLock		; es <- seg addr of name list
					; bp <- memory block handle
	call	NameListFindByToken	; es:di <- ptr to the entry
					; dx <- # of defined entries before
	or	es:[di].NS_flags, mask NF_UNDEFINED
	inc	es:NH_undefinedCount	; One more undefined name
	dec	es:NH_definedCount	; One less defined name
	
	call	VMDirty			; Dirty the name list
	call	VMUnlock		; Unlock the name list
	.leave
	ret
NameMarkUndefined	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameGetTokenFromEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the token of a given entry in the defined name list

CALLED BY:	NameReplaceWithEmptyDefinition
PASS:		ds:si	= Pointer to spreadsheet instance
		cx	= The entry number
RETURN:		cx	= The token number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameGetTokenFromEntry	proc	near
	uses	es, bp, di
	.enter
EC <	call	ECCheckInstancePtr		;>
	call	NameListLock		; es <- seg addr of name list
					; bp <- memory block handle
	call	NameListGetDefinedEntry	; es:di <- the entry

	mov	cx, es:[di].NS_token	; cx <- the token number
	call	VMUnlock		; Release the name list
	.leave
	ret
NameGetTokenFromEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameCountNamesLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count the number of names left in the name space

CALLED BY:	SpreadsheetAddName, PC_CheckNameSpace
PASS:		ds:si	= Spreadsheet instance
RETURN:		ax	= # of names that can be defined.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameCountNamesLeft	proc	far
	uses	es, bp
	.enter
EC <	call	ECCheckInstancePtr		;>
	call	NameListLock		; es <- seg addr of name list
					; bp <- memory block handle

	mov	ax, MAX_NAMES
	sub	ax, es:NH_definedCount
	sub	ax, es:NH_undefinedCount
EC <	ERROR_S	HOW_DID_WE_DEFINE_TOO_MANY_NAMES	>

	call	VMUnlock		; Release the name list
	.leave
	ret
NameCountNamesLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameRenameEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename a name-list entry.

CALLED BY:	SpreadsheetChangeName
PASS:		ds:si	= Spreadsheet instance
		ax	= Token
		es:di	= New name
		cx	= Length of new name
RETURN:		dx	= New list entry
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameRenameEntry	proc	near
	uses	di, si, bp, ds, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; First remove the old entry.
	;
	xchg	cx, ax			; cx <- token, ax <- name length
	call	NameRemoveEntry		; Remove the name-list entry
	xchg	cx, ax			; ax <- token, cx <- name length

	;
	; Now add an entry for the new name.
	;
	push	es, di			; Save name ptr
	call	NameListLock		; es <- segment address of name list
					; bp <- block handle
	pop	ds, si			; ds:si <- ptr to the name
	
	;
	; Find the name by the token. It should not exist.
	; es	= Segment address of the name list
	; ds:si	= Name
	; cx	= Length of the name
	; ax	= Token
	;
	call	NameListFindByName	; carry set if found
					; es:di <- place to put new structure
					; dx <- entry #
EC <	ERROR_C NAME_SHOULD_NOT_ALREADY_EXIST			>

	;
	; Insert the new entry.
	; es:di	= Place to insert
	; bp	= Block handle of name list
	; ds:si	= Name
	; cx	= Name length
	; ax	= Token to use
	;
	call	NameListInsertEntry	; Insert the new entry
	inc	es:NH_definedCount	; One more defined name

	;
	; Now dirty and release the block. The new entry has been added.
	;
	call	VMDirty			; Dirty the block
	call	VMUnlock		; Release the name list
	.leave
	ret
NameRenameEntry	endp

SpreadsheetNameCode	ends
