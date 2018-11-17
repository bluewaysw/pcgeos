COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetPasteNames.asm

AUTHOR:		Cheng, 6/91

ROUTINES:
	Name			Description
	----			-----------
	PasteHandleNameConflicts
	PasteBuildTranslationTable
	PasteNameTransTblAddEntry
	PasteInitNameBuffers
	PasteResolveConflict
	PasteNameConflictQueryUser
	PasteNameNotifyDB *
	PasteCallUserStandardDialog
	PasteAddNameDefinitions
	PasteNameUpdateDef
	PasteNameUpdateDefCallback
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial revision

DESCRIPTION:
		
PSEUDO-CODE:
	
CODE FOR PASTING NAMES
----------------------

	;
	; build the translation table
	;
	for all the NameListEntries
	    call NameDefineEntry
	    if there is no conflict
		add entry to the translation table
	    else
		get user to choose between the definitions
		if the user chooses the spreadsheet's definition then
		    new token = spreadsheet token
		else ; user chooses scrap's definition
		   generate a unique name
		   new token = token gotten from NameDefineEntry
		endif
	    endif
	end for

	backup the name data chain

	;
	; fix up name tokens in the definitions
	;
	for all entries in the name data chain
	    call ParserForeachReference to enumerate tokens
	    if the token is a name then
		translate the name
	    endif
	end for

	;
	; add the definitions
	;
	for all the entries in the definitions
	    initialize a PCT_vars stack frame
	    call FormulaCellParseText ?
	end for

	;
	; paste the cells
	;
	...

CODE FOR DETERMINING IF 2 DEFINITIONS ARE THE SAME
--------------------------------------------------

There is a Catch-22 situation here.  I cannot tell if 2 definitions are the
same if I don't have a translation table.  On the other hand, I cannot build
a translation table if I cannot tell if 2 definitions are the same.

This dilemma is solved by doing the following:

	1) If the scrap is coming from the same document that we are pasting
	into, there is no conflict.  No resolution work needs to be done.

	2) If the scrap comes from a document other than the current one, and
	a name conflicts, we don't inspect the definitions.  Instead, we put up
	a box asking the user to choose between the defintions, ie.

		The name "foo" is already defined in this spreadsheet.
		Which definition of "foo" should be used?

			Spreadsheet		Scrap

In effect, we avoid the problem.

NOTES:

CONFLICT RESOLUTION
-------------------

Since the user can choose between a scrap's definition and the existing
definition on conflict, it is possible that some definitions in the name data
chain in the scrap are unused.  Question is, what do we do with these unused
definitions.

First, the text for the name will not be added since the user selected the
existing name in the document.  So the translation table will contain

	token to use = token of existing name

But what is important is that a mapping is already set up, ie.

	old token -> token of existing name

So, what is needed is some way to tell whether or not a definition should be
added.  This is necessary because when we go through to add the definitions,
we don't want to be redefining any names.

We do this by keeping a flag with each translation table entry.

ADDING THE DEFINITIONS
----------------------

When the translation table is built, the definitions are ready to be added.
The name data chain in the scrap is first backed up because we will be modifying
the entry contents.  We do the following:

	for each NameListEntry
	    with the original token, get the translation
	    if the name is new then
		enumerate the formula tokens
		if the token is a name then
		    get the translation
		    substitute the token with the translation
		    add the name definition
		endif
	    else ; translation is to a name that already exists
		do nothing
	    endif
	end for

TO DO:
	* get NameDefineEntry to return the token of the existing name in
	  the event of conflict
	
	DONE * change the translation table code to take another flag
	
	DONE SOME OTHER WAY * backup the name data chain

	DONE * translate the name tokens

	$Id: spreadsheetPasteName.asm,v 1.1 97/04/07 11:14:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CutPasteCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteHandleNameConflicts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION	Prepare the names for pasting, by obtaining new tokens
		and resolving any conflicts.

CALLED BY:	INTERNAL (PasteProcessCells)

PASS:		PasteStackFrame
		ds:si - Spreadsheet instance

RETURN:		carry set if serious error
		    PSEE_NOT_ENOUGH_NAME_SPACE
		carry clear otherwise

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	traverse name data chain
	for each entry
	retryLoop:
	    if name is unique then {
		; no problem
		add the name
		new token <- result of name addition
	    } else if name not unique but definition matches exactly {
		; no problem
		new token <- token of match
	    } else {
	        ; hassle time
	        ask user - use new name definition or choose a new name
	        if user chooses 'use new name' then {
		    new token <- new format
	        } else {
		    get new name
		    goto retryLoop
	        }
	    }
	
	Implementation notes:
	---------------------
	We will use the PSF_cellEntry buffer as the work space.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PasteHandleNameConflicts	proc	near	
		uses	ax,bx,cx,dx,es,di
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
		.enter	inherit near

	;
	; Set up to read data from the NAME data-stream
	;
		mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_NAME
		mov	dx, ss
		push	bp
		lea	bp, SSM_local
		call	SSMetaDataArrayResetEntryPointer
		pop	bp

	;
	; Process each entry and build a translation table which tells
	; how to convert from each name in the scrap to a name in the
	; spreadsheet.
	;
		call	NameCountNamesLeft	; ax <- # of names left
processNextEntry:
	;
	; Get the next name entry, quitting the loop if there are no
	; more entries.
	;
		call	PasteRetrieveEntry	; cx <- size of entry
		jc	transTblBuilt		; Branch if no more entries

	;
	; Get a pointer the the buffer to pass to PasteBuildTranslationTable.
	; Let it add a translation entry appropriate for this name.
	;
		segmov	es, ss, di
		lea	di, PSF_local.PSF_cellBuf
		
	;
	; Add an entry to the translation table, checking to make sure
	; that there is enough name-space to hold the scraps.
	;
	; es:di	= Pointer to the NameListEntry
	; cx	= Size of the NameListEntry
	; ax	= Amount of available name space
	;
		call	PasteBuildTranslationTable
		jc	exit			; Branch on error
		
	;
	; Loop to process the next entry
	;
		jmp	short processNextEntry

;-----------------------

transTblBuilt:
	;
	; If there was any data in the NAME stream, then we will have
	; left an entry locked (the last one we examined). We need to
	; unlock this entry so that it doesn't hang around forever.
	;
		call	PasteUnlockSSMetaDataArrayIfEntriesPresent
		
	;
	; The translation table was successfully built and we have enough
	; name space. If there are new names that need creating, we do it
	; now so that we will have tokens to use when updating the formulas
	; and pasting.
	;
		call	PasteCreateNewNames
		push	ax
	;
	; Run through the table, and for each new name that needs to
	; be added we need to fix up the name definition so that any
	; names they might reference are updated to be names in the
	; destination.
	;
	; Having fixed up the definitions we add new name cells to the
	; spreadsheet for each of the new names.
	;
		call	PasteAddNameDefinitions

	;
	; notify for new names, if needed
	;
		pop	ax
		tst	ax
		jz	noNotify
		mov	ax, mask SNF_NAME_CHANGE
		call	SS_SendNotification
noNotify:

	;
	; Clearing the carry indicates that we successfully handled
	; all of the names in the scrap and that the paste can continue.
	;
		clc
	
exit:
	;
	; Carry should be set here if there was any error that would mean
	; the paste cannot be completed successfully.
	;
		.leave
		ret
PasteHandleNameConflicts	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteBuildTranslationTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	PasteBuildTranslationTable

CALLED BY:	INTERNAL ()

PASS:		ds:si	- spreadsheet instance
		es:di	- DataBlockEntry containing NameListEntry
		ax	- Amount of name space that is left

RETURN:		carry set if there was an error serious enough to abort
		    dl - error code (PSEE_NOT_ENOUGH_NAME_SPACE)
		carry clear otherwise
		    ax - Decremented if we will need name space for this entry
		
DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	There are seven cases that need our attention. For all of these 
	we will need to create translation table entries indicating what
	needs to be done in order to get a correct name reference in the
	destination. This may be as simple as changing from one token
	to another, or it may be as complex as defining an entirely new
	name.
	    Source	      Dest					Action
	    ------	      ----					------
	    Defined Name      Defined Name, same definition		1
	    Defined Name      Defined Name, different definition	1/4
	    Defined Name      Undefined name, but referenced		2
	    Defined Name      Undefined name, not even referenced	3

	    Undefined Name    Defined Name				1
	    Undefined Name    Undefined name, but referenced		1
	    Undefined Name    Undefined name, not even referenced	5

	Actions to take when correcting the names.
	    1) Translate to new name
	    2) Add definition for the name
	    3) Create new name entry, Add definition for the name
	    4) Generate new name
	    5) Create new undefined-name entry

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteBuildTranslationTable	proc	near
		uses	bx, cx
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
		.enter	inherit near
	;
	; Save the amount of available name space. We'll be updating this later.
	;
		push	ax
	
	;
	; Quick check for the NameListEntry containing a defined or undefined
	; name.
	;
		mov	ax, offset cs:FigureNameTranslationSrcDefined
		
		test	es:[di].NLE_flags, mask NF_UNDEFINED
		jz	gotHandler
		
		mov	ax, offset cs:FigureNameTranslationSrcUndefined
gotHandler:
		call	ax			; Call the handler
		
	;
	; On stack:	Amount of name space
	; carry set if we will be allocating a name for this entry
	; ax	= TTE_action
	; cx	= TTE_dstToken
	;
	; Add an entry to the translation table.
	;
		pushf
		mov	bx, es:[di].NLE_token	; bx <- src token
		call	NameTranslationAddTransTblEntry
		popf

	;
	; Update the amount of available name space and if it goes negative
	; then return that there isn't enough name space.
	;
		pop	ax
		jnc	nameSpaceLeft
		dec	ax			; One less name available
		clc				; Assume space is left
		jns	nameSpaceLeft		; Branch if there is space
		
	;
	; There isn't any more name space left... sigh. Notify the caller
	; of this fact.
		mov	dl, PSEE_NOT_ENOUGH_NAME_SPACE
		stc

nameSpaceLeft:

		.leave
		ret
PasteBuildTranslationTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureNameTranslationSrcDefined
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the appropriate translation given that the name
		was defined in the source spreadsheet.

CALLED BY:	PasteBuildTranslationTable
PASS:		ds:si	= Spreadsheet instance
		es:di	= NameListEntry from source
RETURN:		carry set if we will be allocating a name later
		ax	= TranslationTableAction
		cx	= Destination Token (if we aren't adding a name later)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This is the set of operations we will need to handle.
	    Source	      Dest					Action
	    ------	      ----					------
	    Defined Name      Defined Name, same definition		1
	    Defined Name      Defined Name, different definition	1/4
	    Defined Name      Undefined name, but referenced		2
	    Defined Name      Undefined name, not even referenced	3

	Actions to take when correcting the names.
	    1) Translate to new name
	    2) Add definition for the name
	    3) Create new name entry, Add definition for the name
	    4) Generate new name

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureNameTranslationSrcDefined	proc	near
		.enter	inherit	PasteBuildTranslationTable
	;
	; Check to see if the name is defined in the destination. If so
	; we may need to do some special work.
	;
		mov	ax, offset cs:FigureNameTranslationDefinedInBoth
		
		call	IsNameDefinedInDest	; carry set if defined in dest
		jc	gotHandler

		mov	ax, offset cs:FigureNameTranslationDefinedInSrcNotInDest

gotHandler:
	;
	; Let the handler do the work...
	;
		call	ax
	;
	; Carry set if we will be allocating a name later
	; ax	= TranslationTableAction
	; cx	= Destination Token
	;
		.leave
		ret
FigureNameTranslationSrcDefined	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureNameTranslationDefinedInBoth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the appropriate translation for a name that is defined
		in both the source and destination spreadsheets.

CALLED BY:	FigureNameTranslationSrcDefined
PASS:		ds:si	= Spreadsheet instance
		es:di	= NameListEntry
		ss:bp	= Inheritable stack frame
RETURN:		carry set if we will be allocating a name
		ax	= TranslationTableAction
		cx	= Destination token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This is the set of operations we will need to handle.
	    Source	      Dest					Action
	    ------	      ----					------
	    Defined Name      Defined Name, same definition		1
	    Defined Name      Defined Name, different definition	1/4

	Actions to take when correcting the names.
	    1) Translate to new name
	    4) Generate new name

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureNameTranslationDefinedInBoth	proc	near
		uses	dx
		.enter	inherit	FigureNameTranslationSrcDefined
	;
	; Compare the definition for the name-list entry with the
	; definition in the destination spreadsheet. We know that both
	; of these are defined so we shouldn't require any extra checking
	; here.
	;
		push	di			; Save NameListEntry pointer
		mov	cx, es:[di].NLE_textLength
		add	di, size NameListEntry
		call	NameTokenFromTextFar	; carry set if found
						; ax <- token
						; cl <- NameFlags
EC <		ERROR_NC NAME_MUST_EXIST					>
EC <		test	cl, mask NF_UNDEFINED				>
EC <		ERROR_NZ NAME_SHOULD_BE_DEFINED				>
		pop	di			; Restore NameListEntry pointer

	;
	; OK, we have the token for the name in the destination, but we
	; don't have the definition yet...
	;
		push	di, si, ds
		mov	cx, ax
		call	NameLockDefinitionFar	; ds:si <- ptr to definition
						; carry set on error, al = code
	;
	; The only possible error is that the name is not defined.
	;
EC <		ERROR_C	NAME_SHOULD_BE_DEFINED				>
	
	;
	; es:di	= NameListEntry for source
	; ds:si	= Name definition in destination
	; cx	= Token for destination
	;
	; Get a pointer to the source definition and compare the things.
	;
		push	cx			; Save possible dstToken
		mov	cx, es:[di].NLE_defLength
if DBCS_PCGEOS
		mov	ax, es:[di].NLE_textLength
		shl	ax, 1			; ax <- text size
		add	di, ax			; di <- point after string
else
		add	di, es:[di].NLE_textLength
endif
		add	di, size NameListEntry
		repe	cmpsb			; Equal?

	;
	; Unlock the definition so we don't forget to do it later...
	;
		push	es			; Save NameListEntry segment
		pushf				; Save "same def" flag (Z)
		segmov	es, ds			; es <- seg of definition
		SpreadsheetCellUnlock		; Release the definition
		popf				; Restore "same def" flag (Z)
		pop	es			; Restore NameListEntry segment

	;
	; Restore various things (token, pointers, etc) and do the right thing
	;
		pop	cx			; Restore possible dstToken
		pop	di, si, ds
		je	sameDefinition

queryUserWhichDefToUse::
	;
	; The definitions differ. We need to ask the user what they want to do.
	;	es:di = conflicting NameListEntry (name *not* NULL terminated)
	;
		push	cx, si			; Save possible dstToken
		push	ds, es, di
		mov	cx, es:[di].NLE_textLength
		inc	cx			; room for null
		sub	sp, cx
DBCS <		sub	sp, cx						>
		segmov	ds, es
		mov	si, di
		add	si, size NameListEntry	; ds:si = name to copy
		segmov	es, ss			; name buffer on stack
		mov	di, sp
		mov	dx, sp
		push	cx			; save stack buffer size
		dec	cx			; cx = length w/o null
		LocalCopyNString
		LocalClrChar	ax
		LocalPutChar	esdi, ax	; null terminate
		mov	cx, ss			; cx:dx <- ptr to name
		mov	si, offset PasteResolveNameConflictStr
		call	PasteConflictQueryUser
		pop	cx			; cx = stack buffer size
		lahf				; save flags
DBCS <		shl	cx, 1			; # chars -> # bytes	>
		add	sp, cx			; free stack buffer
		sahf				; restore flags
		pop	ds, es, di
		pop	cx, si			; Restore possible dstToken

	;
	; carry is set if the user wants to use the definition in the
	; destination, clear to use the definition in the scrap.
	;
		jnc	useDestDef

useSrcDef::
	;
	; The user wants to use the definition in the source. This will
	; require us to generate a new name later on. It also means that
	; we will be using some name space.
	;
	; There is no reason to return a dstToken since this token will
	; be created when we generate the new name.
	;
		mov	ax, TTA_GENERATE_NAME	; Generate new name
		stc				; Using name space

quit:
		.leave
		ret


sameDefinition:
	;
	; The names have the same definition, we may be able to just
	; translate from the srcToken to the dstToken without doing
	; anything special.
	;
	; There are a few special cases here. If the definition of the
	; name contains a name reference, then even though the definitions
	; match there is no guarantee that they are the same. Name references
	; are just tokens and right now we have no way of knowing if these
	; tokens refer to the same names without going through a ton of
	; work.
	;
	; If the source and destination spreadsheet are the same then we
	; are set, we can just translate from the old to the new (same
	; name actually...)
	;
		tst	PSF_local.PSF_sourceEqualsDest
		jnz	justTranslate

	;
	; The source spreadsheet is not the destination spreadsheet. We need
	; to check to see if the definition contains any name references. If
	; it doesn't, then we can just translate. Otherwise we need to query
	; the user about which definition to use.
	;
		call	CheckDefContainsNameRefs
		jc	queryUserWhichDefToUse

justTranslate:
	;
	; The definitions are the same and contain no name references (or the
	; two names are from the same spreadsheet). This means that we can just
	; translate from the old name to the new one.
	;
		mov	ax, TTA_TRANSLATE	; Just translate
		; cx already holds the dstToken
		clc				; Not using name space
		jmp	quit


useDestDef:
	;
	; The names have different definition, but the user wants to use
	; the one in the destination. This means we can just translate to
	; the destination token.
	;
		mov	ax, TTA_TRANSLATE	; Just translate
		; cx already holds the dstToken
		clc				; Not using name space
		jmp	quit
		
FigureNameTranslationDefinedInBoth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDefContainsNameRefs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the definition of the source name contains
		any name references.

CALLED BY:	FigureNameTranslationDefinedInBoth
PASS:		ds:si	= Spreadsheet instance
		es:di	= NameListEntry
RETURN:		carry set if the definition contains name references
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckDefContainsNameRefs	proc	near
		uses	cx, dx, di, bp
		.enter
	;
	; Set up for a call to process the references. We need some sort
	; of flag that the callback can set. We use bp.
	;
if DBCS_PCGEOS
		mov	cx, es:[di].NLE_textLength
		shl	cx, 1			; cx <- text size
		add	di, cx			; di <- after text string
else
		add	di, es:[di].NLE_textLength
endif
		add	di, size NameListEntry
		
		mov	cx, SEGMENT_CS
		mov	dx, offset cs:CheckContainsNamesCallback
		
		clr	bp			; No name references (yet)
		call	ParserForeachReference

	;
	; bp is non-zero if there are any name references.
	;
		tst	bp			; Clears the carry
		jz	quit			; Branch if no name references
		
		stc				; Signal: references names
quit:
		.leave
		ret
CheckDefContainsNameRefs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckContainsNamesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if an expression contains name references.

CALLED BY:	CheckDefContainsNameRefs via ParserForeachReference
PASS:		al	= Type of reference (PARSER_TOKEN_NAME/CELL)
RETURN:		bp	= Non-zero if it was a name reference
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckContainsNamesCallback	proc	far
		cmp	al, PARSER_TOKEN_NAME
		jne	quit
		
		mov	bp, -1			; signal: name reference found
quit:
		ret
CheckContainsNamesCallback	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureNameTranslationDefinedInSrcNotInDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the appropriate translation for a name that is defined
		in the source spreadsheet but not in the destination.

CALLED BY:	FigureNameTranslationSrcDefined
PASS:		ds:si	= Spreadsheet instance
		es:di	= NameListEntry for source
		ss:bp	= Inheritable stack frame
RETURN:		carry set if we will be allocating a name
		ax	= TranslationTableAction
		cx	= Destination token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This is the set of operations we will need to handle.
	    Source	      Dest					Action
	    ------	      ----					------
	    Defined Name      Undefined name, but referenced		2
	    Defined Name      Undefined name, not even referenced	3

	Actions to take when correcting the names.
	    2) Add definition for the name
	    3) Create new name entry, Add definition for the name

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureNameTranslationDefinedInSrcNotInDest	proc	near
		.enter
	;
	; Check to see if the name exists at all. If it does then we'll
	; just need to add a definition. Otherwise we'll need to add an
	; entire new name entry.
	;
		push	di			; Save NameListEntry pointer
		mov	cx, es:[di].NLE_textLength
		add	di, size NameListEntry
		call	NameTokenFromTextFar	; carry set if found
						; ax <- token
						; cl <- NameFlags
		pop	di			; Restore NameListEntry pointer
		jnc	notEvenReferenced	; Branch if it doesn't exist

	;
	; The name does exist, and it really should be undefined.
	;
EC <		test	cl, mask NF_UNDEFINED				>
EC <		ERROR_Z	NAME_SHOULD_BE_UNDEFINED			>

	;
	; The name does exist and is undefined. We need to create a new
	; definition for this name. This does not require any name space
	;
		mov	cx, ax			; cx <- Destination token
		mov	ax, TTA_ADD_SRC_DEFINITION
		clc				; Not allocating a new name

quit:
		.leave
		ret


notEvenReferenced:
	;
	; The name does not exist at all (not even undefined but referenced).
	; We'll need to add an entire new name entry for this one.
	;
		mov	ax, TTA_ADD_SRC_NAME_AND_DEF
		stc				; Allocating a new name
		jmp	quit
		
FigureNameTranslationDefinedInSrcNotInDest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureNameTranslationSrcUndefined
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the appropriate translation given that the name
		was not defined in the source spreadsheet.

CALLED BY:	PasteBuildTranslationTable
PASS:		ds:si	= Spreadsheet instance
		es:di	= NameListEntry from source
RETURN:		carry set if we will be allocating a name later
		ax	= TranslationTableAction
		cx	= Destination Token (if we aren't adding a name later)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	    Source	      Dest					Action
	    ------	      ----					------
	    Undefined Name    Defined Name				1
	    Undefined Name    Undefined name, but referenced		1
	    Undefined Name    Undefined name, not even referenced	5

	Actions to take when correcting the names.
	    1) Translate to new name
	    5) Create new undefined-name entry

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureNameTranslationSrcUndefined	proc	near
		.enter	inherit	PasteBuildTranslationTable
	;
	; Check to see if the name exists in the destination.
	;
		call	DoesNameExistInDest	; carry set if it exists
						; ax <- token
						; cl <- NameFlags
		jc	doTranslation

	;
	; The name doesn't even exist. We will need to allocate an undefined
	; name later on.
	;
		mov	ax, TTA_CREATE_UNDEFINED
		stc				; We will use name space

quit:
	;
	; Carry set if we will be allocating a name later
	; ax	= TranslationTableAction
	; cx	= Destination Token
	;
		.leave
		ret


doTranslation:
	;
	; Either the name is defined in the destination, or it is undefined
	; but referenced. Either way, it does exist and we want to translate
	; the old name reference to this new name.
	;
		mov	cx, ax			; cx <- dst token
		mov	ax, TTA_TRANSLATE	; ax <- action
		clc				; Not using name space
		jmp	quit
		
FigureNameTranslationSrcUndefined	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsNameDefinedInDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a name is defined in the destination

CALLED BY:	FigureNameTranslationSrcDefined
PASS:		ds:si	= Spreadsheet instance
		es:di	= NameListEntry
RETURN:		carry set if defined in destination
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsNameDefinedInDest	proc	near
		uses	ax, cl
		.enter
	;
	; First check to see if it exists. If it doesn't, then there's no
	; way that it could be considered to be defined.
	;
		call	DoesNameExistInDest	; carry set if it exists
						; ax <- Token
						; cl <- NameFlags
		jnc	quit			; Branch if it doesn't

	;
	; The name exists, the flags will tell us if the thing is defined.
	;
		test	cl, mask NF_UNDEFINED	; clears the carry
		jnz	quit			; Branch if undefined

	;
	; It exists and is defined...
	;
		stc

quit:
		.leave
		ret
IsNameDefinedInDest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoesNameExistInDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the name exists in the destination.

CALLED BY:	FigureNameTranslationSrcUndefined, IsNameDefinedInDest
PASS:		es:di	= NameListEntry
		ds:si	= Spreadsheet instance
RETURN:		carry set if it exists
		ax	= Token
		cl	= NameFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoesNameExistInDest	proc	near
		uses	di
		.enter
	;
	; Basically look up the thing and get all that fine information
	; from the existing name-list code.
	;
		mov	cx, es:[di].NLE_textLength
		add	di, size NameListEntry
		call	NameTokenFromTextFar	; carry set if found
						; ax <- token
						; cl <- NameFlags
		.leave
		ret
DoesNameExistInDest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameTranslationAddTransTblEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an entry to the translation table.

CALLED BY:	PasteBuildTranslationTable
PASS:		ds:si	= Spreadsheet instance
		ax	= TranslationTableAction
		bx	= Source token
		cx	= Destination token
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameTranslationAddTransTblEntry	proc	near
		uses	bx, cx, dx
		.enter	inherit	PasteBuildTranslationTable
	;
	; Sadly the translation code is not built to handle doing this in
	; one operation, so we do it in two...
	;
		mov	dx, cx			; dx <- destination token
		mov	cx, bx			; cx <- source token
		lea	bx, PSF_local.PSF_nameTransTbl
		call	TransTblAddEntry	; Add the entry

		; cx already holds the source token
		; bx already holds offset to translation table info on stack
		mov	dx, ax			; dx <- "flag" (action, actually)
		call	TransTblAddFlag		; Set the action
		.leave
		ret
NameTranslationAddTransTblEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteConflictQueryUser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

CALLED BY:	FigureNameTranslationDefinedInBoth, PasteHandleFormatConflict

PASS:		cx:dx - addr of the existing name that there is a conflict with
		^hsi  - chunk containing error message

RETURN:		carry clear to use existing name
		carry set to use name in scrap

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteConflictQueryUser	proc	near	uses	ax,bx,ds,si,di,bp
	.enter

	mov	bx, handle CutPasteStrings
	call	MemLock
	mov	ds, ax
;	mov	si, offset PasteResolveNameConflictStr
	mov	si, ds:[si]
	mov	di, ds			; di:bp <- string
	mov	bp, si

	mov	ax, mask CDBF_SYSTEM_MODAL or \
		(CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
		(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
	call	PasteCallUserStandardDialog

	cmp	ax, IC_YES		; YES response?
	clc				; assume so
	je	done			; branch if assumption correct

	stc				; else flag NO

done:
	mov	bx, handle CutPasteStrings
	call	MemUnlock

	.leave
	ret
PasteConflictQueryUser	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteNameNotifyDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Put up an notification message for the name pasting code.

CALLED BY:	INTERNAL (PasteResolveConflict)

PASS:		si - chunk handle
		cx:dx if relevant
		bx:ax if relevant

RETURN:		nothing

DESTROYED:	si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _PROTECT_CELL
PasteNameNotifyDB	proc	far
else
PasteNameNotifyDB	proc	near
endif
	uses	ax,bx,ds,di,bp
	.enter

	push	bx,ax
	mov	bx, handle CutPasteStrings
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]
	mov	di, ds
	mov	bp, si
	pop	bx,si

	mov	ax, mask CDBF_SYSTEM_MODAL or \
		(CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE) or \
		(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	PasteCallUserStandardDialog

	mov	bx, handle CutPasteStrings
	call	MemUnlock

	.leave
	ret
PasteNameNotifyDB	endp

;
; pass:
;	ax - CustomDialogBoxFlags
;	di:bp = error string
;	cx:dx = arg 1
;	bx:si = arg 2
; returns:
;	ax = InteractionCommand response
; destroys:
;	nothing
ifdef GPC
PasteCallUserStandardDialog	proc	far
else
PasteCallUserStandardDialog	proc	near
endif

	; we must push 0 on the stack for SDP_helpContext

	push	bp, bp			;push dummy optr
	mov	bp, sp			;point at it
	mov	ss:[bp].segment, 0
	mov	bp, ss:[bp].offset

.assert (offset SDP_customTriggers eq offset SDP_stringArg2+4)
	push	ax		; don't care about SDP_customTriggers
	push	ax
.assert (offset SDP_stringArg2 eq offset SDP_stringArg1+4)
	push	bx		; save SDP_stringArg2 (bx:si)
	push	si
.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	push	cx		; save SDP_stringArg1 (cx:dx)
	push	dx
.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	push	di		; save SDP_customString (di:bp)
	push	bp
.assert (offset SDP_customString eq offset SDP_customFlags+2)
.assert (offset SDP_customFlags eq 0)
	push	ax		; save SDP_type, SDP_customFlags
	call	UserStandardDialog
	ret
PasteCallUserStandardDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteCreateNewNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create any new names so that we have tokens we can use
		for fixing up the name definitions before we paste them.

CALLED BY:	PasteHandleNameConflicts
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Inheritable stack frame
RETURN:		ax = count of new names
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PasteCreateNewNames	proc	near
		uses	bx,cx,dx
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
		.enter	inherit near

		mov	PSF_local.PSF_newNameCount, 0
	;
	; Reset the pointer so we can process the names yet again.
	;
		mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_NAME
		mov	dx, ss
		push	bp
		lea	bp, SSM_local
		call	SSMetaDataArrayResetEntryPointer
		pop	bp

	;
	; Loop through the entries adding names or definitions where necessary.
	; 
processNextEntry:
		call	PasteRetrieveEntry
		jc	done			; Branch if no more entries

	;
	; cx = size of the DataBlockEntry
	; es:di buffer filled with the data block entry
	;
		call	PasteCreateNameIfRequired
		jmp	processNextEntry

done:
	;
	; If there was any data in the NAME stream, then we will have
	; left an entry locked (the last one we examined). We need to
	; unlock this entry so that it doesn't hang around forever.
	;
		call	PasteUnlockSSMetaDataArrayIfEntriesPresent
		
		clc				; Indicate no error (why?)
		mov	ax, PSF_local.PSF_newNameCount
	
		.leave
		ret
PasteCreateNewNames	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteCreateNameIfRequired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a name if it's required by the translation table.

CALLED BY:	PasteCreateNewNames
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Inheritable
		es:di	= NameListEntry
		cx	= Size of the entry (ignored)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version
	witt	11/15/93	DBCS-ized; cx internally is length

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PasteCreateNameIfRequired	proc	near
		uses	ax, bx, cx, dx, es, di
		.enter	inherit	PasteCreateNewNames
	;
	; Get the action ("flag") associated with this entry and see if we
	; need to create a new name. If we do, we'll be resetting the
	; destination token.
	;
		mov	cx, es:[di].NLE_token
		lea	bx, PSF_local.PSF_nameTransTbl
		call	TransTblGetFlag		; dx <- action
		
		mov	bx, cx			; Preserve the old token
		
		mov	cx, es:[di].NLE_textLength
		add	di, size NameListEntry	; es:di <- ptr to the name

	;
	; In all these cases we create an undefined name, so we can patch
	; the definition and then add the right definition later. The cases
	; where we want to add a new name are:
	;	TTA_ADD_SRC_NAME_AND_DEF
	;	TTA_GENERATE_NAME
	;	TTA_CREATE_UNDEFINED
	;
		cmp	dx, TTA_ADD_SRC_NAME_AND_DEF
		je	addUndefinedNameAndUpdate
		cmp	dx, TTA_CREATE_UNDEFINED
		je	addUndefinedNameAndUpdate
		
		cmp	dx, TTA_GENERATE_NAME
		jne	quit
	;
	; We need to generate an entirely new name. Oh joy.
	;
		call	GenerateUniqueName	; es:di <- ptr to name
						; cx <- length of name

addUndefinedNameAndUpdate:
	;
	; Add an undefined name and update the TranslationTable so that
	; it contains the destination token to use.
	;
	; ds:si	= Spreadsheet instance
	; es:di	= Pointer to the name to add
	; cx	= Length of the name string
	; bx	= Old token
	;
		inc	PSF_local.PSF_newNameCount
		call	NameAddUndefinedEntryFar ; ax <- token
		call	CreateNameCellInstance	; Make an empty name cell

	;
	; Modify the translation table entry to have this destination token
	; ax	= Dst token
	; bx	= Src token
	;
		mov	cx, bx			; bx <- src token
		mov	dx, ax			; dx <- dst token
		lea	bx, PSF_local.PSF_nameTransTbl
		call	TransTblModifyEntry	; Update the entry

quit:
		.leave
		ret
PasteCreateNameIfRequired	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateUniqueName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a unique name to use.

CALLED BY:	PasteCreateNameIfRequired
PASS:		ds:si	= Spreadsheet instance
		es:di	= Pointer to string to start with
		cx	= Length of string
		ss:bp	= Inheritable stack frame
RETURN:		es:di	= New name, guaranteed to be unique
		cx	= Length of this name
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version
	witt	11/15/93	DBCS-ized, cx = length.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateUniqueName	proc	near
		uses	ax
		.enter	inherit PasteCreateNameIfRequired
tryAgain:
	;
	; Try to generate a unique name.
	; es:di	= Pointer to the name
	; cx	= Length of the name
	; ss:bp	= Stack frame
	;
		push	es, di, cx
		
	;
	; Copy the old name to the PSF_newNameBuf and pass a pointer to this
	; buffer off to ConflictGenerateNewName letting it generate the
	; new name for us.
	;
		push	ds, si			; Save spreadsheet instance
		segmov	ds, es, si		; ds:si <- source
		mov	si, di
		segmov	es, ss, di		; es:di <- dest
		lea	di, PSF_local.PSF_newNameBuf
		LocalCopyNString		; Copy the string
		LocalClrChar	ax
		LocalPutChar	esdi, ax
		pop	ds, si			; Restore spreadsheet instance
		
		mov	PSF_local.PSF_maxNameLength, MAX_NAME_LENGTH
		
		lea	di, PSF_local.PSF_newNameBuf
		call	ConflictGenerateNewName	; Nukes ax, dx, di
						; cx <- new string length
	;
	; Check to see if this new name is defined. If not, then we're set.
	; If it is, we'll need to try generating a name again.
	;
		lea	di, PSF_local.PSF_newNameBuf
	;
	; es:di	= Pointer to the name
	; cx	= Length of the name
	; ds:si	= Spreadsheet
	; ss:bp	= Stack frame
	;
		push	cx			; Save length of name
		call	NameTokenFromTextFar	; carry set if found
						; ax <- Token
						; cl <- NameFlags
		pop	cx			; Restore length of name
		jnc	generatedNameIsOK	; Branch if it doesn't exist

	;
	; The generated name is not OK, we try again.
	;
		pop	es, di, cx		; Restore pointer, length
		jmp	tryAgain		; Try one more time


generatedNameIsOK:
	;
	; The generated name is OK.
	; es:di	= Pointer to the new name
	; cx	= Length of the new name
	; On stack:
	;	Far pointer to old name, Length of old name
	;
		pop	ax, ax, ax		; Restore stack
		.leave
		ret
GenerateUniqueName	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteAddNameDefinitions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Fixup the definitions for all of the names in the scrap
		and for all the entries in the scrap that need to be added
		to the destination spreadsheet, add new names and/or definitions

CALLED BY:	INTERNAL (PasteHandleNameConflicts)

PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Inheritable stack frame

RETURN:		carry set on error

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	for each NameListEntry
	    with the original token, get the translation
	    if the name is new then
		enumerate the formula tokens
		if the token is a name then
		    get the translation
		    substitute the token with the translation
		    add the name definition
		endif
	    else ; translation is to a name that already exists
		do nothing
	    endif
	end for

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PasteAddNameDefinitions	proc	near
		uses	bx,cx,dx
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
		.enter	inherit near

	;
	; Reset the pointer so we can process the names yet again.
	;
		mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_NAME
		mov	dx, ss
		push	bp
		lea	bp, SSM_local
		call	SSMetaDataArrayResetEntryPointer
		pop	bp

	;
	; Loop through the entries adding names or definitions where necessary.
	; 
processNextEntry:
		call	PasteRetrieveEntry
		jc	done			; Branch if no more entries

	;
	; cx = size of the DataBlockEntry
	; es:di buffer filled with the data block entry
	;
		call	PasteNameUpdateDef
		jmp	processNextEntry

done:
	;
	; If there was any data in the NAME stream, then we will have
	; left an entry locked (the last one we examined). We need to
	; unlock this entry so that it doesn't hang around forever.
	;
		call	PasteUnlockSSMetaDataArrayIfEntriesPresent
		clc				; Indicate no error (why?)
	
		.leave
		ret
PasteAddNameDefinitions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteNameUpdateDef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Called upon to add the definition for a name if necessary.

CALLED BY:	INTERNAL (PasteAddNameDefinitions)

PASS:		PasteStackFrame buffer filled with the data block entry
		es:di	= NameListEntry

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

PasteNameUpdateDef	proc	near
		uses	bx,cx,dx
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
		.enter	inherit near

	;
	; Figure out what we want to do with this entry and then do it.
	;
		mov	cx, es:[di].NLE_token
		lea	bx, PSF_local.PSF_nameTransTbl
		call	TransTblGetFlag		; dx <- Action
		mov	bx, dx			; bx <- Action
		
		call	cs:NameUpdateTable[bx]	; Call the handler

		.leave
		ret

NameUpdateTable		word	\
	offset cs:NameUpdateTranslate,		; TTA_TRANSLATE
	offset cs:NameUpdateAddSrcDef,		; TTA_ADD_SRC_DEFINITION
	offset cs:NameUpdateAddSrcDef,		; TTA_ADD_SRC_NAME_AND_DEF
	offset cs:NameUpdateAddSrcDef,		; TTA_GENERATE_NAME
	offset cs:NameUpdateCreateUndefined	; TTA_CREATE_UNDEFINED
		
PasteNameUpdateDef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameUpdateTranslate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a name by translating the src token to the dest token.

CALLED BY:	PasteNameUpdateDef
PASS:		ds:si	= Spreadsheet instance
		es:di	= NameListEntry
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The implication here is that the source name is not being added
	to the destination, instead we are mapping the source name to
	some name that already existed in the destination.
	
	This turns out to be pretty easy... We don't do anything.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameUpdateTranslate	proc	near
		ret
NameUpdateTranslate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameUpdateAddSrcDef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a name by adding a definition for the name.

CALLED BY:	PasteNameUpdateDef
PASS:		ds:si	= Spreadsheet instance
		es:di	= NameListEntry
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	There are a few situations where this code works.

    TTA_ADD_SRC_DEFINITION
	If the name existed in the source, but was undefined but referenced
	in the destination, then we need to set the definition for the
	destination token to the definition for the source.

    TTA_ADD_SRC_NAME_AND_DEF
	If the name existed in the source and didn't exist at all in the
	destination, then an undefined name would have been added already
	in PasteCreateNameIfRequired, so the situation is the same as
	it was for TTA_ADD_SRC_DEFINITION.

    TTA_GENERATE_NAME
	If a new name was generated then it would have been generated as
	an undefined name in PasteCreateNameIfRequired, so once again the
	situation is the same.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameUpdateAddSrcDef	proc	near
		.enter	inherit	PasteNameUpdateDef
	;
	; Patch the definition for the name.
	;
		call	PatchUpDefinition	; Fix up definition
		
	;
	; Save the definition with the name cell associated with dstToken.
	;
	; ds:si	= Spreadsheet instance
	; es:di	= NameListEntry
	;
		call	SaveNameDefinition	; Save definition for srcToken
		.leave
		ret
NameUpdateAddSrcDef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatchUpDefinition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Patch up the definition by translating all name
		definitions appropriately.

CALLED BY:	NameUpdateAddSrcDef
PASS:		ds:si	= Spreadsheet instance
		es:di	= NameListEntry
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Foreach name reference in the name definition
	    - Map to the new name

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PatchUpDefinition	proc	near
		uses	di, cx, dx
		.enter	inherit	PasteNameUpdateDef
	;
	; Set up for a call to process the references.
	;
if DBCS_PCGEOS
		mov	cx, es:[di].NLE_textLength
		shl	cx, 1			; cx <- text size
		add	di, cx			; di <- point past text
else
		add	di, es:[di].NLE_textLength
endif
		add	di, size NameListEntry	; es:di <- ptr to definition
		
		mov	cx, SEGMENT_CS			; cx:dx <- callback
		mov	dx, offset cs:PatchUpDefCallback
		
		call	ParserForeachReference
		.leave
		ret
PatchUpDefinition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatchUpDefCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Patch up a name reference.

CALLED BY:	PatchUpDefinition via ParserForeachReference
PASS:		es:di	= Pointer to the reference
		al	= Reference type
		ds:si	= Spreadsheet instance
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PatchUpDefCallback	proc	far
		uses	bx, cx, dx
		.enter	inherit	PatchUpDefinition
		cmp	al, PARSER_TOKEN_NAME
		jne	quit
	;
	; It's a name reference, translate the old to the new.
	;
		lea	bx, PSF_local.PSF_nameTransTbl
		mov	cx, es:[di].PTND_name
		call	TransTblSearch		; carry clear if found
						; dx <- new token
EC <		ERROR_C	PASTE_TRANS_TBL_CANT_LOCATE_ENTRY		>
		
	;
	; Save the new name reference.
	;
		mov	es:[di].PTND_name, dx
quit:
		.leave
		ret
PatchUpDefCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNameDefinition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the definition of the name with the dstToken.

CALLED BY:	NameUpdateAddSrcDef
PASS:		ds:si	= Spreadsheet instance
		es:di	= NameListEntry
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	We can guarantee that the name whose definition we are saving
	is marked as 'undefined'. We wouldn't be overwriting the definition
	of an existing name. This means we don't need to remove dependencies
	we can just save the cell formula and add appropriate dependencies.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNameDefinition	proc	near
		class	SpreadsheetClass
		uses	ax, bx, cx, dx, bp, di, es
		.enter	inherit	NameUpdateAddSrcDef
	;
	; Map the old token to the new token so we know which cell to save to.
	;
		lea	bx, PSF_local.PSF_nameTransTbl
		mov	cx, es:[di].NLE_token
		call	TransTblSearch		; carry clear if found
						; dx <- new token

	;
	; Allocate the stack frame and initialize it for SaveCellFormula
	;
		sub	sp, size PCT_vars
		mov	bp, sp

		call	SpreadsheetInitCommonParamsFar
		
	;
	; Save our own cell, since the common routine sets it to the
	; active cell.
	;
		mov	ss:[bp].PCTV_row, NAME_ROW
		mov	ss:[bp].PCTV_column, dx
		mov	ss:[bp].CP_row, NAME_ROW
		mov	ss:[bp].CP_column, dx

	;
	; Copy the definition into the stack frame
	;
		mov	cx, es:[di].NLE_defLength
		
		push	ds, si			; Save instance ptr
		
		segmov	ds, es, si		; ds:si <- ptr to source
		mov	si, di
if DBCS_PCGEOS
		mov	ax, ds:[si].NLE_textLength
		shl	ax, 1			; # chars -> # bytes
		add	si, ax
else
		add	si, ds:[si].NLE_textLength
endif
		add	si, size NameListEntry

		segmov	es, ss, di		; es:di <- ptr to dest
		lea	di, ss:[bp].PCTV_parseBuffer
		
		rep	movsb			; Copy the definition (bytes)

		pop	ds, si			; Restore instance ptr
		
	;
	; ds:si	= Spreadsheet instance
	; es:di	= Pointer *past* the parsed formula
	; ss:bp	= Stack frame, initialized
	; dx	= Token
	;
		mov	al, CT_FORMULA		; al <- cell type
		call	SaveCellFormulaFar	; Save the name cell definition
	;
	; Set up the dependencies so things will get updated right.
	;
		clr	dx			; Signal: Add dependencies
		call	AddRemoveCellDependenciesFar

	;
	; Mark the name as defined, if it wasn't already.
	;
		mov	ax, ss:[bp].CP_column	; ax <- token
		call	NameDefineEntryGivenTokenFar ; Nukes dx

	;
	; Restore the stack and hope for the best.
	;
		add	sp, size PCT_vars

	;
	; Recalculate the dependents of the name, but do it without drawing.
	;
		mov	cx, ax			; cx <- column (token)
		mov	ax, NAME_ROW		; ax <- row
		
		push	ds:[si].SSI_flags	; Save old flags
		ornf	ds:[si].SSI_flags, mask SF_SUPPRESS_REDRAW
		call	RecalcDependents	; Recalc name dependents
		pop	ds:[si].SSI_flags	; Restore old flags
		.leave
		ret
SaveNameDefinition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameUpdateCreateUndefined
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a name when the source was undefined and the dest
		didn't exist at all.

CALLED BY:	PasteNameUpdateDef
PASS:		ds:si	= Spreadsheet instance
		es:di	= NameListEntry
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
	Since the undefined name was created in PasteCreateNameIfRequired
	we don't need to do anything here.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameUpdateCreateUndefined	proc	near
		ret
NameUpdateCreateUndefined	endp

CutPasteCode	ends
