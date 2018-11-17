COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc		
FILE:		miscSearch.asm

AUTHOR:		Ted H. Kim, 1/8/90

ROUTINES:
	Name			Description
	----			-----------
	RolodexSearch		Searches the database for a word match
	SearchString		Searches a string for possible word match
	SearchDatabase		Lower level routine of FindMatch
	SearchRecord		Searches a database record for word match
	SearchForward		Called when "Find Next" is selected
	SearchBackward		Called when "Find Previous" is selected
	SearchPhone		Searches phone number entries 
	SelectMatchText		Show matching word selected in text object
	GetListMoniker		Creates a moniker for dynamic list entry
	FindRecord		Updates the card view according to browse view 
	UpdateNameList		Updates the browse view according to card view
	SetNewExclusive		Sets one of list entry as exclusive
	AddToNameList		Adds a new entry to browse view
	DeleteFromNameList	Deletes an entry from browse view
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	1/8/90		Initial revision
	witt	2/8/94		DBCS and adapted TableEntry offset calcs

DESCRIPTION:
	This file contains search routines.

	$Id: miscSearch.asm,v 1.1 97/04/04 15:50:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Search	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message handler for MSG_SEARCH

CALLED BY:	UI

PASS:		ds	- dgroup
		dx	- handle of block that contains SearchReplaceStruct

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si, bp

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexSearch	proc	far

	class	RolodexClass

	tst	ds:[gmb.GMB_numMainTab]		; is database empty?
	LONG	je	done		; if so, quit

	mov	ds:[searchHandle], dx	; save handle of SearchReplaceStruct
	mov	bx, ds:[searchHandle]
	call	MemLock			; lock SearchReplaceStruct
	mov	es, ax
	mov	al, es:[SRS_params]	; al - SearchOptions
	andnf	ds:[searchFlag], not mask SOF_BACKWARD_SEARCH ; assume forward
	test	al, mask SO_BACKWARD_SEARCH 	; find previous?
	je	notBackward		; if not, skip
	ornf	ds:[searchFlag], mask SOF_BACKWARD_SEARCH ; backward search
notBackward:
	call	MemUnlock

	call	SaveCurRecord		; update the record if necessary
	LONG	jc	quit		; exit if error

	call	DisableUndo		; no undoable action exists

	test	ds:[recStatus], mask RSF_WARNING	; was warning box up?
	je	noWarning		; if not, skip
	andnf	ds:[recStatus], not mask RSF_WARNING ; clear warning flag
	jmp	quit	
noWarning:
	; first clear all these flags

if PZ_PCGEOS
	andnf	ds:[searchFlag], not (mask SOF_NOTE_SEARCH or \
		mask SOF_ADDR_SEARCH or mask SOF_PHONE_SEARCH or\
		mask SOF_PHONETIC_SEARCH or mask SOF_ZIP_SEARCH)
else
	andnf	ds:[searchFlag], not (mask SOF_NOTE_SEARCH or \
		mask SOF_ADDR_SEARCH or mask SOF_PHONE_SEARCH )
endif
	; check to see if we are in BEGINNER level

	GetResourceHandleNS	RolodexApp, bx
	mov	si, offset RolodexApp
	mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			; dx=UIInterfaceLevel

	cmp	dx, UIIL_BEGINNING		; is it beginner level?
	jne	getOption			; skip if not beginner

	; if BEGINNER level, search all fields

if PZ_PCGEOS
	ornf	ds:[searchFlag], mask SOF_NOTE_SEARCH or \
		mask SOF_ADDR_SEARCH or mask SOF_PHONE_SEARCH or \
		mask SOF_PHONETIC_SEARCH or mask SOF_ZIP_SEARCH
else
	ornf	ds:[searchFlag], mask SOF_NOTE_SEARCH or \
		mask SOF_ADDR_SEARCH or mask SOF_PHONE_SEARCH
endif
	jmp	boxOff1
getOption:
	mov	si, offset SearchOptionList	; bx:si - OD of list entry	
	GetResourceHandleNS	SearchOptionList, bx 
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	
	call	ObjMessage			; get the state of check box 
	jc	boxOff1				; if off, skip
	or	ds:[searchFlag], ax		; box is on
boxOff1:

	; adjust our current search offset, based upon the direction of
	; the search. Otherwise, we will continue to find the same match

	mov	ax, (size TCHAR)
	test 	ds:[searchFlag], mask SOF_BACKWARD_SEARCH
	jz	adjustOffset
	neg	ax
adjustOffset:
	add	ds:[searchOffset], ax
	test	ds:[searchFlag], mask SOF_NEW	
	jne	search

	ornf	ds:[searchFlag], mask SOF_NEW 	; set flag to no match found
	clr	ds:[searchField]
	clr	ds:[searchOffset]
	test	ds:[searchFlag], mask SOF_BACKWARD_SEARCH ; find previous?
	je	search				; if not, skip
	mov	ds:[searchField], TEFO_NOTE	; search note field first
	mov	ds:[searchOffset], END_OF_FIELD
search:
	andnf	ds:[searchFlag], not mask SOF_MATCH_FOUND
	call	SearchDatabase			; search the database for match	
done:
	GetResourceSegmentNS	dgroup, ds	; ds - seg address of core block
	; match found or reached end?
	test	ds:[searchFlag], mask SOF_MATCH_FOUND or mask SOF_REACHED_END
	jne	quit				; if so, exit
	mov	bp, ERROR_NO_MATCH		; bp - error message number
	call	DisplayErrorBox			; put up a warning box
quit:
	ret
RolodexSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Searches for word match, creates a filter table, 
		and re-builds the name list accordingly.	

CALLED BY:	RolodexSearch

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	Skip white spaces in front of text string from FilterField
	For each record in database
		if there is a match, insert it into filtered database
	Next record
	Display the 1st record from filtered database
	Re-build the name list with filtered database

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchDatabase	proc	far
	andnf	ds:[searchFlag], not mask SOF_CUR_REC_ONE_MORE_TIME

	mov	si, offset RolodexApp		; bx:si - handle of GenApp
	GetResourceHandleNS	RolodexApp, bx 
	mov	ax, MSG_GEN_APPLICATION_HOLD_UP_INPUT	
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; ignore mouse presses

	mov	dx, ds:[curOffset]		; dx - offset into main table
	cmp	dx, ds:[gmb.GMB_endOffset]	; is this the last entry?
	jne	mainLoop			; if not, skip

	mov	dx, ds:[gmb.GMB_endOffset]
	sub	dx, size TableEntry		; go back one record
	mov	ds:[searchField], TEFO_NOTE	; start search in note field
	mov	ds:[searchOffset], END_OF_FIELD	; at zero offset
	test	ds:[searchFlag], mask SOF_BACKWARD_SEARCH ; Find Previous?
	jnz	mainLoop
	clr	dx				; if so, start at the beginning
	clr	ds:[searchField]		; start search in index field
	clr	ds:[searchOffset]		; at zero offset
mainLoop:
	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table
	call	DBLockNO
	mov	di, es:[di]			; open up the main table
	add	di, dx				; di - ptr to record to search
	mov	di, es:[di].TE_item		; si - handle of search record
	call	DBUnlock			; close it up
	call	SearchRecord			; search the record for match
	jc	next				; if not found, skip
	mov	ds:[curOffset], dx
	mov	si, di				; si - record handle to display
	push	cx				; save the length of search word
	ornf	ds:[searchFlag], mask SOF_MATCH_FOUND ; set search flags
	call	DisplayCurRecord		; display the 1st record
	call	UpdateNameList			; update the name list
	call	EnableCopyRecord		; fix up some menu
	pop	cx				; restore length of search word
	call	SelectMatchText			; show the search result
	jmp	exit
next:
	test	ds:[searchFlag], mask SOF_CUR_REC_ONE_MORE_TIME
	jne	exit

	test	ds:[searchFlag], mask SOF_BACKWARD_SEARCH ; find previous?
	je	findNext			; if not, skip

	tst	dx				; is this the 1st entry?
	jne	findPrev			; if not, find previous entry?

	push	bp
	mov	bp, ERROR_SEARCH_AT_BEG
	call	DisplayErrorBox
	pop	bp
	ornf	ds:[searchFlag], mask SOF_REACHED_END	; assume "no"
	cmp	ax, IC_YES
	jne	exit				; does not want to continue
	andnf	ds:[searchFlag], not mask SOF_REACHED_END	; not "no"

	mov	ax, ds:[curOffset]		; ax - offset into main table
	cmp	ax, ds:[gmb.GMB_endOffset]	; is this the last entry?
	je	exit				; if so, exit the loop

	mov	dx, ds:[gmb.GMB_endOffset]
findPrev:
	sub	dx, size TableEntry		; go back one record
	jmp	common
findNext:
	add	dx, size TableEntry 		; dx - offset to next record 
	cmp	ds:[gmb.GMB_endOffset], dx		; are we done?
	jne	common				; if not, continue

	push	bp
	mov	bp, ERROR_SEARCH_AT_END
	call	DisplayErrorBox
	pop	bp
	ornf	ds:[searchFlag], mask SOF_REACHED_END	; assume "no"
	cmp	ax, IC_YES
	jne	exit				; does not want to continue
	andnf	ds:[searchFlag], not mask SOF_REACHED_END	; not "no"

	mov	ax, ds:[curOffset]		; ax - offset into main table
	cmp	ax, ds:[gmb.GMB_endOffset]	; is this the last entry?
	je	exit				; if so, exit the loop

	clr	dx				; if match, go to the beginning
common:
	cmp	ds:[curOffset], dx		; are we done?
	LONG	jne	mainLoop		; exit if so

	ornf	ds:[searchFlag], mask SOF_CUR_REC_ONE_MORE_TIME
	jmp	mainLoop
exit:
	mov	si, offset RolodexApp		; bx:si - handle of GenApp
	GetResourceHandleNS	RolodexApp, bx 
	mov	ax, MSG_GEN_APPLICATION_RESUME_INPUT	
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; accept mouse presses
	ret
SearchDatabase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if "Find Next" or "Find Previous".

CALLED BY:	(INTERNAL) SearchDatabase

PASS:		searchFlag

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchRecord	proc	near
	test	ds:[searchFlag], mask SOF_BACKWARD_SEARCH ; find previous?
	jnz	backward		; if so, skip

	; search forward, and if we don't find anything, initialize
	; our search to start at the beginning of the next record

	call	SearchForward		; search forward
	jnc	done			; exit if match found
	clr	ds:[searchField]	; start search in index field
	clr	ds:[searchOffset]	; at zero offset
	jmp	notFound

	; search backwards, and if we don't find anything, initialize
	; our search to start at the end of the previous record
backward:
	call	SearchBackward		; search backward
	jnc	done			; exit if match found
	mov	ds:[searchField], TEFO_NOTE	; start search in note field
	mov	ds:[searchOffset], END_OF_FIELD	; and at end of field
notFound:
	stc				; not match found
done:
	ret
SearchRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchForward
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Searches the given record for possible word match.

CALLED BY:	SearchRecord()

PASS:		di - handle of record to search
		ds - dgroup segment

RETURN:		carry clear if there is a match
		carry set otherwise

DESTROYED:	ax, cx, si, es 

PSEUDO CODE/STRATEGY:
		Search (in order)
			Index
			Address
			Phones
			Notes

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/30/90		Initial version
	Don	4/ 8/95		Optimized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchForward	proc	near		uses bx, dx, di
	.enter

	call	DBLockNO
	mov	di, es:[di]			; open up record to search

	mov	bp, di				; save ptr to beg of data
if PZ_PCGEOS
	cmp	ds:[searchField], TEFO_PHONETIC	; last match in phonetic field?
	je	phonetic2			; if not, check phonetic fields
	cmp	ds:[searchField], TEFO_ZIP	; was last match in zip field?
	LONG 	je	zip2			; if not, check zip fields
endif
	cmp	ds:[searchField], TEFO_ADDR	; was last match in addr field?
	LONG	je	addr			; if not, check phone fields
	cmp	ds:[searchField], TEFO_NOTE	; was last match in notes field?
	LONG	je	notes			; if not, skip
	cmp	ds:[searchField], TEFO_INDEX	; was last match in index field?
	LONG	jne	phones			; if not, skip

	; search the index field for possible match

	add	di, size DB_Record		; es:di - string to be searched
	call	SearchForwardStub
	jnc	doneShort			; if found, we're done

if PZ_PCGEOS
	; search the phonetic field for possible match

	test	ds:[searchFlag], mask SOF_PHONETIC_SEARCH ; is check box on?
	je	zip				; if so, on to the next record
	mov	ds:[searchField], TEFO_PHONETIC
	clr	ds:[searchOffset]
phonetic2:
	test	ds:[searchFlag], mask SOF_PHONETIC_SEARCH ; is check box on?
	je	zip				; if so, on to the next record

	; check the field has data.

	LocalCmpChar	es:[di].DBR_phoneticSize, 0 ; is size  0?
	jz	zip
	mov	di, bp		 		; di - ptr to beg of data
	add	di, es:[di].DBR_toPhonetic	; di - ptr to phonetic string
	call	SearchForwardStub
	jnc	doneShort			; if found, we're done

	; search the zip field for possible match
zip:
	test	ds:[searchFlag], mask SOF_ZIP_SEARCH	; is check box on?
	je	addr0				; if so, on to the next record
	mov	ds:[searchField], TEFO_ZIP
	clr	ds:[searchOffset]
zip2:
	test	ds:[searchFlag], mask SOF_ZIP_SEARCH ; is check box on?
	je	addr0				; if so, on to the next record

	; check the field has data.

	mov	di, bp		 		; di - ptr to beg of data
	LocalCmpChar	es:[di].DBR_zipSize, 0	; is size  0?
	jz	addr0
	add	di, es:[di].DBR_toZip		; di - ptr to zip string
	call	SearchForwardStub
	jnc	doneShort			; if found, we're done
endif

	; search the address field for possible match
addr0::
	test	ds:[searchFlag], mask SOF_ADDR_SEARCH	; is check box on?
	je	phoneFields			; if so, on to the next record
	clr	ds:[searchOffset]
addr:
	mov	ds:[searchField], TEFO_ADDR
	test	ds:[searchFlag], mask SOF_ADDR_SEARCH	; is check box on?
	je	phoneFields			; if so, on to the next record
	mov	di, bp		 		; di - ptr to beg of data
if PZ_PCGEOS
	; check the field has data.
	LocalCmpChar	es:[di].DBR_addrSize, 0	; is size  0?
	jz	phoneFields
endif
	add	di, es:[di].DBR_toAddr		; di - ptr to address string
	call	SearchForwardStub
doneShort:
	jnc	done				; if found, we're done

	; search the phone fields for possible match
phoneFields:
	test	ds:[searchFlag], mask SOF_PHONE_SEARCH	; is check box on?
	je	noteField			; if so, on to the next record
	andnf	ds:[searchFlag], not mask SOF_MATCH_IN_PHONE
	mov	ds:[searchField], TEFO_PHONE_TYPE
	clr	ds:[searchOffset]
	jmp	common
phones:
	test	ds:[searchFlag], mask SOF_PHONE_SEARCH	; is check box on?
	je	noteField			; if so, on to the next record
	ornf	ds:[searchFlag], mask SOF_MATCH_IN_PHONE
common:
	call	SearchPhoneForward		; otherwise, search phone fields
	jnc	done				; if match, we're done

	; search the note field for possible match
noteField:
	test	ds:[searchFlag], mask SOF_NOTE_SEARCH	; search note field?
	stc
	je	done				; if not, then we've failed
	mov	ds:[searchField], TEFO_NOTE	; we are about to search
	clr	ds:[searchOffset]		; the notes field
notes:
	test	ds:[searchFlag], mask SOF_NOTE_SEARCH	; search note field?
	stc
	je	done				; if not, we're done

	mov	di, es:[bp].DBR_notes		; di - handle of notes block
	tst	di				; is there notes field?
	stc
	je	done				; if not, skip
	mov	ds:[searchField], TEFO_NOTE	; dx - offset to FieldTable
	push	es
	call	DBLockNO
	mov	di, es:[di]			; lock this block
	call	SearchForwardStub
	call	DBUnlock			; unlock the notes block
	pop	es
done:
	call	DBUnlock

	.leave
	ret
SearchForward	endp

SearchForwardStub	proc	near
	push	ax
	mov	ax, di				; es:ax - start of string
	add	di, ds:[searchOffset]		; es:di - offset into string
	LocalIsNull	es:[di] 		; NULL string or beyond string?
	stc					; assume this is so
	je	done
	call	SearchString			; search for a match	
done:
	pop	ax
	ret
SearchForwardStub	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchBackward
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Searches the given record for possible word match.

CALLED BY:	FindMatch

PASS:		di - handle of record to search

RETURN:		carry clear if there is a match
		carry set otherwise

DESTROYED:	ax, bx, cx, si, es 

PSEUDO CODE/STRATEGY:
		Search (in order)
			Notes
			Phones
			Address
			Index

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/30/90		Initial version
	Don	4/ 8/95		Optimized & search backwards in field

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchBackward	proc	near		uses  dx, di
	.enter

	call	DBLockNO
	mov	di, es:[di]			; open up record to search

	; search the index field for possible match

	mov	bp, di				; save ptr to beg of data
if PZ_PCGEOS
	cmp	ds:[searchField], TEFO_PHONETIC	; last match in phonetic field?
	LONG	je	phonetic		; if not, check phone fields
	cmp	ds:[searchField], TEFO_ZIP	; was last match in zip field?
	LONG	je	zip			; if not, check zip fields
endif
	cmp	ds:[searchField], TEFO_ADDR	; was last match in addr field?
	LONG	je	addr			; if not, check phone fields
	cmp	ds:[searchField], TEFO_INDEX	; was last match in index field?
	LONG	je	index			; if not, skip
	cmp	ds:[searchField], TEFO_PHONE_NO	; was last match in notes field?
	je	phones				; if not, skip
	cmp	ds:[searchField], TEFO_PHONE_TYPE ; last match in notes field?
	je	phones				; if not, skip

	; search the notes field for a possible match	

	test	ds:[searchFlag], mask SOF_NOTE_SEARCH	; search note field?
	je	phoneFields			; if not, skip
	mov	di, es:[bp].DBR_notes		; di - handle of notes block
	tst	di				; is there notes field?
	je	phoneFields			; if not, skip
	mov	ds:[searchField], TEFO_NOTE	; dx - offset to FieldTable

	push	es
	call	DBLockNO
	mov	di, es:[di]			; lock this block
	call	SearchBackwardStub
	call	DBUnlock			; unlock the notes block
	pop	es
	jnc	done				; done if a match is found

	; search the phone fields for possible match
phoneFields:
	test	ds:[searchFlag], mask SOF_PHONE_SEARCH	; search note field?
	je	addrField				; if not, skip
	andnf	ds:[searchFlag], not mask SOF_MATCH_IN_PHONE
	mov	ds:[searchField], TEFO_PHONE_NO	; backward, search # first
	mov	ds:[searchOffset], END_OF_FIELD
	jmp	common
phones:
	test	ds:[searchFlag], mask SOF_PHONE_SEARCH	; search note field?
	je	addrField				; if not, skip
	ornf	ds:[searchFlag], mask SOF_MATCH_IN_PHONE
common:
	call	SearchPhoneBackward
	jnc	done				; done if a match is found

	; search the address field for possible match
addrField:
	test	ds:[searchFlag], mask SOF_ADDR_SEARCH	; search note field?
NPZ <	je	indexField			; if not, skip		>
PZ <	je	zipField			; if not. skip		>
	mov	ds:[searchField], TEFO_ADDR
	mov	ds:[searchOffset], END_OF_FIELD
addr:
	test	ds:[searchFlag], mask SOF_ADDR_SEARCH	; search note field?
	je	indexField			; if not, skip
	mov	di, bp		 		; di - ptr to beg of data
	add	di, es:[di].DBR_toAddr		; di - ptr to address string
	call	SearchBackwardStub
	jnc	done				; if found, we're done

if PZ_PCGEOS
	; search the zip field for possible match
zipField:
	test	ds:[searchFlag], mask SOF_ZIP_SEARCH	; search zip field?
	je	phoneticField			; if not, skip
	mov	ds:[searchField], TEFO_ZIP
	clr	ds:[searchOffset]
zip:
	test	ds:[searchFlag], mask SOF_ZIP_SEARCH	; search zip field?
	je	phoneticField			; if not, skip

	mov	di, bp				; di - ptr to beg of data
	LocalCmpChar	es:[di].DBR_zipSize, 0	; is size  0?
	jz	phoneticField
	add	di, es:[di].DBR_toZip		; di - ptr to zip string
	call	SearchBackwardStub
	jnc	done				; if found, we're done

	; search the phonetic field for possible match
phoneticField:
	test	ds:[searchFlag], mask SOF_PHONETIC_SEARCH ; search phonetic?
	je	indexField			; if not, skip
	mov	ds:[searchField], TEFO_PHONETIC
	clr	ds:[searchOffset]
phonetic:
	test	ds:[searchFlag], mask SOF_PHONETIC_SEARCH ; search phonetic
	je	indexField				; if not, skip
	mov	di, bp				; di - ptr to beg of data
	LocalCmpChar	es:[di].DBR_phoneticSize, 0 ; is size  0?
	jz	indexField
	add	di, es:[di].DBR_toPhonetic	; di - ptr to phonetic string
	call	SearchBackwardStub
	jnc	done				; if found, we're done
endif

	; search the index field for possible match
indexField:
	clr	ds:[searchField]
	mov	ds:[searchOffset], END_OF_FIELD
index:
	mov	di, bp		 		; di - ptr to beg of data
	add	di, size DB_Record		; es:di - string to be searched
	call	SearchBackwardStub
	jnc	done				; if found, skip
done:
	call	DBUnlock

	.leave
	ret
SearchBackward	endp

SearchBackwardStub	proc	near
	push	ax
	LocalCmpChar	es:[di], C_NULL		; NULL string?
	stc					; assume this is so
	je	done
	cmp	ds:[searchOffset], -(size TCHAR); if we're at the start of
	stc					; ...of the current text string
	jz	done				; ...we're done (0-1 = start)
	mov	ax, di				; es:ax - start of string
	add	di, ds:[searchOffset]		; es:di - offset into string
	cmp	ds:[searchOffset], END_OF_FIELD	; search from very end?
	jne	doSearch			; ...nope
	mov	di, END_OF_FIELD		; ...yes, so set flag
doSearch:
	call	SearchString			; search for a match	
done:
	pop	ax
	ret
SearchBackwardStub	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchPhoneForward
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Searches all of the phone number entries for a possible match.

CALLED BY:	(INTERNAL) SearchForward

PASS:		ds	- dgroup
		es:bp	- DB_Record

RETURN:		carry clear if a match is found
		carry set if no match is found

DESTROYED:	ax, bx, cx, dx, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REGSITER USAGE:
		dx	- # of PhoneEntry records left to search
		es:bp	- current PhoneEntry

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version
	Don	4/95		Optimized, I hope

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchPhoneForward	proc	near
	.enter

	; some set-up work

	push	bp				; bp - ptr to beg of data
	mov	dx, es:[bp].DBR_noPhoneNo	; dx - # of phone entries
	add	bp, es:[bp].DBR_toPhone		; es:bp - first PhoneEntry

	; if we'd already found a match before, then go to the correct entry
	; we can't use a "loop" instruction here, as we need to keep the
	; number of entries left to be searched in DX.

	test	ds:[searchFlag], mask SOF_MATCH_IN_PHONE
	jz	mainLoop
ifdef GPC
	mov	cx, ds:[searchPhone]
	jcxz	mainLoop
miniLoop:
	tst	dx
	jz	notFound
	call	nextPhoneEntry
	loop	miniLoop
else
	mov	cl, ds:[curPhoneType]		; al - current phone type ID
miniLoop:
	cmp	cl, es:[bp].PE_type		; do phone type ID's match?
	je	mainLoop			; if so, start seaching
	call	nextPhoneEntry			; go to next or prev entry
	jnz	miniLoop
	jmp	notFound			; we're done - no match
endif

	; loop through all of the remaining phone numbers
mainLoop:
	push	dx				; save # of phone entries
	mov	dl, es:[bp].PE_type		; dl - phone # type ID

	; search through phone type first, unless we weren't there

	cmp	ds:[searchField], TEFO_PHONE_NO	; was last match in phone no?
	jz	phoneNo				; if so, skip
ifdef GPC
	;
	; only search user-defined type field
	;
	cmp	dl, INDEX_TO_STORE_FIRST_ADDED_PHONE_TYPE
	jne	afterPhoneType
endif
	mov	ds:[searchField], TEFO_PHONE_TYPE ; dx - offset to FieldTable
	mov	di, ds:[gmb.GMB_phoneTypeBlk]	; di - handle of phone block
	push	es				; save seg address of record
	call	DBLockNO			; lock phone type name block
	mov	di, es:[di]			; di - ptr to beg of data
	clr	dh
	shl	dx, 1			
	tst	dx				; is offset zero?
	jnz	nonZero				; if not, skip
	mov	dx, 2				; if so, adjust the offset
nonZero:
	add	di, dx				; di - ptr to offset 
	add	di, es:[di]
	sub	di, dx				; es:di - ptr to text string
	call	SearchForwardStub		; perform the search
	call	DBUnlock			; unlock phone type block
	pop	es				; restore seg address of record
	jnc	found				; if found, exit
afterPhoneType::

	; now search through the actual phone number

	mov	ds:[searchField], TEFO_PHONE_NO
	clr	ds:[searchOffset]
phoneNo:
	mov	di, bp				; di - ptr to beg of phone #
	tst	es:[di].PE_length		; is there a phone number? 
	je	next				; if not, skip
	add	di, size PhoneEntry		; di - ptr to phone # string
	call	SearchForwardStub		; perform the search
	jnc	found				; if found, exit

	; go to the next phone entry
next:
	mov	ds:[searchField], TEFO_PHONE_TYPE
	clr	ds:[searchOffset]
	pop	dx				; restore count
	call	nextPhoneEntry			; go to next PhoneEntry record
	jne	mainLoop

	; No match - we're outta here
notFound:
	pop	bp
	stc					; return with no match flag 
	jmp	exit

	; Hurrah - we found a match. Display it to the user
found:
	pop	dx				; dx - loop count
	pop	bp				; bp - ptr to beg record data 
	mov	ax, es:[bp].DBR_noPhoneNo	; ax - # of phone entries
	sub	ax, dx				; ax - phone number counter
ifdef GPC
	mov	ds:[searchPhone], ax
endif
	mov	es:[bp].DBR_phoneDisp, al	; display this phone number
	clc					; return with match flag set
exit:
	.leave
	ret

	; Go forward to the next phone entry
nextPhoneEntry:
SBCS<	add	bp, es:[bp].PE_length					>
DBCS<	push	di							>
DBCS<	mov	di, es:[bp].PE_length					>
DBCS<	shl	di, 1							>
DBCS<	add	bp, di							>
DBCS<	pop	di							>
	add	bp, (size PhoneEntry)		; es:bp - next PhoneEntry record
	dec	dx
	retn
SearchPhoneForward	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchPhoneBackward
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Searches all of the phone number entries for a possible match.

CALLED BY:	(INTERNAL) SearchBackward

PASS:		ds	- dgroup
		es:bp	- DB_Record

RETURN:		carry clear if a match is found
		carry set if no match is found

DESTROYED:	ax, bx, cx, dx, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REGSITER USAGE:
		dx	- # of PhoneEntry records left to search
		es:bp	- current PhoneEntry

		There are exceptions to the above at the beginning and end
		of the routine, so beware!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version
	Don	4/95		Implemented backwards search

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchPhoneBackward	proc	near
	.enter

	; some set-up work

	push	bp				; bp - ptr to beg of data
	mov	dx, es:[bp].DBR_noPhoneNo	; dx - # of phone entries
	add	bp, es:[bp].DBR_toPhone		; es:bp - first PhoneEntry

	; We are searching backward, so we need to point at the very last
	; entry. There is no simple way of finding this entry, other than
	; traipsing through the PhoneEntry records

	mov	cx, dx				; cx - total number of records
	dec	cx				; want to point at the last one
findLast:
SBCS<	add	bp, es:[bp].PE_length					>
DBCS<	mov	di, es:[bp].PE_length					>
DBCS<	shl	di, 1							>
DBCS<	add	bp, di							>
	add	bp, (size PhoneEntry)
	loop	findLast			; es:bp - last PhoneEntry

	; If we'd already found a match before, then go to the correct entry
	; we can't use a "loop" instruction here, as we need to keep the
	; number of entries left to be searched in DX.

	test	ds:[searchFlag], mask SOF_MATCH_IN_PHONE
	jz	mainLoop
ifdef GPC
	mov	cx, dx
	sub	cx, ds:[searchPhone]		; cx = number to skip from end
	cmp	cx, 1
	jl	notFound			; signed
	dec	cx
	jcxz	mainLoop
miniLoop:
	tst	dx
	jz	notFound
	call	prevPhoneEntry
	loop	miniLoop
else
	mov	cl, ds:[curPhoneType]		; al - current phone type ID
miniLoop:
	cmp	cl, es:[bp].PE_type		; do phone type ID's match?
	je	mainLoop			; if so, start seaching
	call	prevPhoneEntry			; go to prev PhoneEntry record
	jnz	miniLoop
	jmp	notFound			; we're done - no match
endif

	; loop through all of the remaining phone numbers
mainLoop:
	push	dx				; save # of phone entries
	cmp	ds:[searchField], TEFO_PHONE_TYPE ; if we were on the phone type
	je	phoneType			; ...start there first

	; search through the phone number

	mov	ds:[searchField], TEFO_PHONE_NO
	mov	di, bp				; di - ptr to beg of phone #
	tst	es:[di].PE_length		; is there a phone number? 
	je	donePhoneNo			; if not, skip
	add	di, size PhoneEntry		; di - ptr to phone # string
	call	SearchBackwardStub		; perform the search
	jnc	found				; if found, exit
donePhoneNo:
	mov	ds:[searchField], TEFO_PHONE_TYPE
	mov	ds:[searchOffset], END_OF_FIELD

	; now search through phone type
phoneType:
	mov	dl, es:[bp].PE_type		; dl - phone # type ID
ifdef GPC
	;
	; only search user-defined type field
	;
	cmp	dl, INDEX_TO_STORE_FIRST_ADDED_PHONE_TYPE
	jne	afterPhoneType
endif
	mov	di, ds:[gmb.GMB_phoneTypeBlk]	; di - handle of phone block
	push	es				; save seg address of record
	call	DBLockNO			; lock phone type name block
	mov	di, es:[di]			; di - ptr to beg of data
	clr	dh
	shl	dx, 1				; array of 'nptr's
	tst	dx				; is offset zero?
	jnz	nonZero				; if not, skip
	mov	dx, 2				; if so, adjust the offset
	; 2 if smallest offset in phone number block. [0] is handle (TEFO_xxx)
nonZero:
	add	di, dx				; di - ptr to offset 
	add	di, es:[di]
	sub	di, dx				; es:di - ptr to text string
	call	SearchBackwardStub		; perform the search
	call	DBUnlock			; unlock phone type block
	pop	es				; restore seg address of record
	jnc	found				; if found, exit
afterPhoneType::

	; go to the next phone entry

	mov	ds:[searchField], TEFO_PHONE_NO
	mov	ds:[searchOffset], END_OF_FIELD
	pop	dx				; restore count
	call	prevPhoneEntry			; go to prev PhoneEntry record
	jne	mainLoop

	; No match - we're outta here
notFound:
	pop	bp
	stc					; return with no match flag 
	jmp	exit

	; Hurrah - we found a match. Display it to the user
found:
	pop	ax				; ax - loop count
	pop	bp				; bp - ptr to beg record data 
	dec	ax
ifdef GPC
	mov	ds:[searchPhone], ax
endif
	mov	es:[bp].DBR_phoneDisp, al	; display this phone number
	clc					; return with match flag set
exit:
	.leave
	ret

	; Go back to the previous phone entry (trashes ax & di). What a mess...
prevPhoneEntry:
	mov	di, bp				; es:si - current offset
	mov	bp, sp
	mov	bp, ss:[bp+2]			; es:bp - start of DB_Record
	add	bp, es:[bp].DBR_toPhone		; es:bp - start of PhoneEntry's
	cmp	bp, di				; if already at start,
	je	foundPrev			; ...we're done with search
findPrevLoop:
	mov	ax, (size PhoneEntry)
	add	ax, es:[bp].PE_length		; ax - offset to next entry
DBCS<	add	ax, es:[bp].PE_length		; ax - offset to next entry >
	add	ax, bp				; ax - absolute offset
	cmp	ax, di				; same as current ??
	je	foundPrev			; yes! So BP holds previous
	mov_tr	bp, ax				; elss, es:bp - next PhoneEntry
	jmp	findPrevLoop
foundPrev:
	dec	dx
	retn
SearchPhoneBackward	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Searches for a word in a string 

CALLED BY:	UTILITY

PASS:		ds	- dgroup
		es:ax	- start of search string
		es:di	- current position in search string
			  (NOTE: if di = END_OF_FIELD, then need to
			   reset di to actual end of text)

RETURN:		carry clear if no match is found
		cx	- preserved
		- or -
		carry set if a match is found
		cx	- # of chars in match

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Doesn't handle words that start with wild card characters.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/8/90		Initial version
	Don	4/8/95		Added backwards searching

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchString	proc	near	uses	bx, dx, bp, di, si
	.enter

	; first, determine the length of the string

	xchg	ax, di			; ax <- current, di <- start
	call	LocalStringSize
	mov	dx, cx			; dx <- length of string
	mov	bp, di			; es:bp <- start of string to search
	mov	bx, di
	add	bx, cx
	LocalPrevChar	esbx		; es:bx <- end of string to search
	mov_tr	di, ax			; es:di <- current position in string
	cmp	di, END_OF_FIELD	; if not at very end of text
	jne	setupSearch		; ...we're fine
	mov	di, bx			; ...otherwise start at end

	; now see if we can find the string we are searching for
setupSearch:
	push	ds
	push	bx
	mov	bx, ds:[searchHandle]	; bx - SearchReplaceStruct block
	call	MemLock			; lock this block
	mov	ds, ax
	mov	si, offset SRS_searchString
	clr	cx			; ds:si <- NULL-terminated search string
	mov	al, ds:[SRS_params]	; al <- search options
	ornf	al, mask SO_IGNORE_CASE or \
		    mask SO_PARTIAL_WORD or \
		    mask SO_NO_WILDCARDS
	pop	bx
	test	al, mask SO_BACKWARD_SEARCH
	jz	doSearch
	mov	bx, bp			; end of search = start of string,
					; when we are searching backwards
doSearch:
DBCS <	shr	dx, 1			; dx - string length 		>
	call	TextSearchInString	; search for the string
	pop	ds
	jc	exit			; exit if not match
	sub	di, bp
	mov	ds:[searchOffset], di
	clc				; match is found
exit:
	mov	bx, ds:[searchHandle]	; bx - SearchReplaceStruct block
	call	MemUnlock		; unlock this block

	.leave
	ret
SearchString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectMatchText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the matching text selected.

CALLED BY:	SearchDatabase

PASS:		nothing		

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version
	Don	4/95		Don't give focus to text object with match, as
				it causes weird visual flashes when searching
			
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectMatchText	proc	near	uses	cx
	.enter

	; if we have a match in the Notes DB, we'd better display it

	cmp	ds:[searchField], TEFO_NOTE	; match found in note field?
	jne	notNotes			; if not, skip

	mov	si, offset NotesBox	 	; bx:si - OD of notes field
	GetResourceHandleNS	NotesBox, bx	
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; display the window

	; give the target to the NotesBox

	mov	ax, MSG_GEN_MAKE_TARGET
	mov	di, mask MF_FIXUP_DS		
	call	ObjMessage			
	jmp	common

	; give the target to the Primary 
notNotes:
	GetResourceHandleNS	RolodexPrimary, bx
	mov	si, offset RolodexPrimary	; bx:si - OD of GenPrimary
	mov	ax, MSG_GEN_MAKE_TARGET
	mov	di, mask MF_FIXUP_DS		
	call	ObjMessage			

	; give the target to the text object with a matched string
common:
	GetResourceHandleNS	Interface, bx	; bx:si - OD of primary
	mov	si, ds:[searchField]		; si - offset to FieldTable	
	cmp	si, TEFO_NOTE			; notes field?
	jne	common2				; if not, skip
	GetResourceHandleNS	WindowResource, bx; bx:si - OD of notes field
common2:
ifdef GPC
	cmp	si, TEFO_PHONE_TYPE
	jne	notPhoneType
	mov	si, ds:[searchPhone]
	shl	si, 1
	mov	si, cs:searchPhoneNameList[si]
	jmp	short gotField
notPhoneType:
	cmp	si, TEFO_PHONE_NO
	jne	notPhoneNo
	mov	si, ds:[searchPhone]
	shl	si, 1
	mov	si, cs:searchPhoneNumList[si]
	jmp	short gotField
notPhoneNo:
endif
	mov	si, ds:FieldTable[si]		; si - offset to text field
ifdef GPC
gotField:
	tst	si
	jz	exit
endif
	mov	di, mask MF_FIXUP_DS		
	mov	ax, MSG_GEN_MAKE_TARGET
	call	ObjMessage			; make it the target field

	mov	dx, cx				; dx <- length of string
	mov	cx, ds:[searchOffset]		; cx - start of selection
DBCS <	shr	cx				; cx <- length 		>
	add	dx, cx				; dx - end of selection
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL	
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage			; select the text
exit::
	.leave
	ret
SelectMatchText	endp

ifdef GPC
searchPhoneNameList	lptr \
	0,
	offset	Interface:StaticPhoneOneName,
	offset	Interface:StaticPhoneTwoName,
	offset	Interface:StaticPhoneThreeName,
	offset	Interface:StaticPhoneFourName,
	offset	Interface:StaticPhoneFiveName,
	offset	Interface:StaticPhoneSixName,
	offset	Interface:StaticPhoneSevenName

searchPhoneNumList	lptr \
	0,
	offset	Interface:StaticPhoneOneNumber,
	offset	Interface:StaticPhoneTwoNumber,
	offset	Interface:StaticPhoneThreeNumber,
	offset	Interface:StaticPhoneFourNumber,
	offset	Interface:StaticPhoneFiveNumber,
	offset	Interface:StaticPhoneSixNumber,
	offset	Interface:StaticPhoneSevenNumber
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the moniker for an entry from dynamic list. 

CALLED BY:	UI - MSG_ROLODEX_REQUEST_ENTRY_MONIKER

PASS:		bp - entry number that needs the moniker
		cx:dx - OD of the GenList entry
		ds - dgroup segment
		ds:searchFlag - tells you whether filter is on or off
		ds:numFilter - number of entries in filtered database
		ds:gmb.GMB_numMainTable - number of entries in database

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/30/90		Initial version
	Ted	4/1/91		Also handles import/export map lists
	witt	2/8/94		Better TableEntry size multiplies

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetListMoniker	proc	far
	class	RolodexClass

	cmp	bp, ds:[gmb.GMB_numMainTab]	; blank entry?
	LONG	jge	exit		; if so, exit

	tst	ds:[fileHandle]		; is file already closed?
	LONG	je	exit		; if so, just exit

	push	bp			; save entry index number
	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table
	call	DBLockNO			
	mov	di, es:[di]		; open up the main table
	TableEntryIndexToOffset  bp	; bp - TableEntry offset

;;;	add	di, bp			; di - pointer to selected entry
	mov	di, es:[di+bp].TE_item	; di - handle of data record 
	call	DBUnlock		; unlock tabel entry,
	call	DBLockNO		;  and lock the record itself!
	mov	di, es:[di]		; open up the data block
;	mov	dx, es:[di].DBR_indexSize	; dx - size of index field
ifdef GPC
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	checkNote
endif

if PZ_PCGEOS
	; if phonetic exists then display it, else display index
	mov	dx, es:[di].DBR_phoneticSize ; dx - size of phonetic field
	tst	dx			; see if phonetic field exists
	jnz	usePhonetic		; if so, use phonetic field
	add	di, size DB_Record	; di - pointer to index field
	jmp	display
usePhonetic:
	add	di, es:[di].DBR_toPhonetic ; es:di - ptr to phonetic field
display:
else
	add	di, size DB_Record	; di - pointer to index field
endif

	pop	bp
	GetResourceHandleNS	SearchList, bx
	mov	si, offset SearchList	; bx:si - OD of SearchList
	mov	cx, es
	mov	dx, di			; cx:dx - fptr to moniker text
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; copy the block in
finishMoniker::
	call	DBUnlock		; unlock DB_Record
exit:
	ret

ifdef GPC
	; es:di = DB_Record
	; (on stack) = item # of query
	; ds = dgroup
checkNote:
	push	ds				; save dgroup
	mov	dx, di				; es:dx = DB_Record
	tst	es:[di].DBR_notes		; any notes?
	pushf					; (2+)
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx				; default header
	call	MemAllocLMem			; bx = block
	mov	cl, GST_CHUNK
	call	GrCreateGString			; di = gstring, si = chunk
	popf					; (2-) Z set if no notes
	push	bx, si				; (6+) save gstring optr
	push	dx				; (1+) save DB_Record offset
	jz	addName
	mov	bx, handle TextResource
	call	MemLock
	mov	ds, ax
	mov	si, ds:[(offset TextResource:ListNoteIconMoniker)]
	clr	dx				; not bitmap callback
	call	GrDrawBitmapAtCP
	call	MemUnlock
addName:
	mov	dx, 16 + 2			; bitmap width + spacing
	clr	cx, bx, ax
	call	GrRelMoveTo
	pop	si				; (1) es:si = DB_Record
	add	si, size DB_Record		; es:si = name
	segmov	ds, es				; ds:si = name
	clr	cx				; null-terminated
	call	GrDrawTextAtCP
	call	GrEndGString
	mov	si, di				; si = gstring
	clr	di				; no gstate
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	pop	ax, cx				; (6-) ^lax:cx = gstring optr
	pop	ds				; (8-) restore dgroup
	pop	di				; restore item #
	push	ax				; (7+) save block handle again
	mov	dx, size ReplaceItemMonikerFrame
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].RIMF_source.high, ax
	mov	ss:[bp].RIMF_source.low, cx
	mov	ss:[bp].RIMF_sourceType, VMST_OPTR
	mov	ss:[bp].RIMF_dataType, VMDT_GSTRING
	mov	ss:[bp].RIMF_length, 0
	mov	ss:[bp].RIMF_width, 0
	mov	ss:[bp].RIMF_itemFlags, 0
	mov	ss:[bp].RIMF_item, di
	GetResourceHandleNS	SearchList, bx
	mov	si, offset SearchList		; bx:si - OD of SearchList
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size ReplaceItemMonikerFrame
	pop	bx				; (7-) free gstring block
	call	MemFree
	jmp	finishMoniker
endif
GetListMoniker	endm

ifdef GPC
;
; es: dgroup
; cx, dx = mouse position
;
SearchDynamicListStartSelect	method	SearchDynamicListClass, MSG_META_START_SELECT
		mov	es:[searchNoteIconHit], 0
		cmp	cx, 16+2		; check if click on note icon
		ja	done
		mov	es:[searchNoteIconHit], -1
done:
		mov	di, offset SearchDynamicListClass
		call	ObjCallSuperNoLock
		ret
SearchDynamicListStartSelect	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method handler for SearchList - this is the routine
		that gets called whenever an entry from SearchList is
		selected, de-selected, or even double-clicked upon.

CALLED BY:	UI - MSG_FIND_RECORD

PASS:		displayStatus - tells you which view is up
		cx - dynamic list entry selected

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	If deselected, exit
	Otherwise
		If both view up,
			display the selected entry in card view
		Else if card view up, exit
		     else if double clicked 
			     {	bring up both view
				and display this record  }
			  else exit

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Double clicking was not working as of 1/30/90.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindRecord	proc	far
	class	RolodexClass

	cmp	ax, MSG_ROLODEX_EXPAND_TO_BOTH_VIEW	; double clicked?
	jne	single				; if not, skip

	push	cx
	call	RolodexBoth			; bring up both view
	pop	cx
;still check nothing selected for double click
;;	jmp	display
single:
	tst	cx				; is nothing selected?
	LONG	js	quit			; if so, exit
display::
	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table
	call	DBLockNO			; lock the table 
	mov	di, es:[di]			; open up the main table
	TableEntryIndexToOffset  cx

	add	di, cx				; di - pointer to selected entry
	mov	si, es:[di].TE_item		; di - handle of data record 
	call	DBUnlock

	clr	cx
	cmp	si, ds:[curRecord]		; is the record displayed?
	jne	skip				; if so, exit

	push	si
	mov	si, offset LastNameField	; bx:si - OD of index field
	GetResourceHandleNS	LastNameField, bx
	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; returns cx with status
	pop	si
	tst	cx				; is it modified?
	LONG	je	exit			; if not, exit
skip:

EC< 	cmp	ds:[displayStatus], CARD_VIEW			>
EC<	jne	noError						>
EC<	ERROR	CANNOT_HAVE_LIST_ENTRY_SELECTED_IN_CARD_VIEW	>
EC<noError:							>

	andnf	ds:[recStatus], not mask RSF_WARNING	; clear warning flag

	; if there was an undoItem to be deleted inside "SaveCurRecord",
	; and this is the same as si, then si is no longer a valid handle
	; upon returning from "SaveCurRecord".  So we want to make sure
	; si is pointing to a valid handle.

	cmp	si, ds:[undoItem]	; will this DBBlock be deleted?
	jne	save			; if not, skip
	mov	si, ds:[curRecord]	; if so, si - cur record handle
save:
	push	cx, si
	call	SaveCurRecord		; save current record if necessary
	pop	cx, si
	LONG	jc	quit		; exit if error

	tst	cx			; was index field modified?
	je	noMod			; if not, skip
	push	si
	call	UpdateNameList		; set the new exclusive
	pop	si
noMod:
	cmp	ds:[displayStatus], BROWSE_VIEW	; are we in browse view?
	je	recDisp				; if so, skip

	test	ds:[recStatus], mask RSF_WARNING; was warning box up?
	je	recDisp				; if not, skip

	call	DisableUndo		; no undoable action exists
	mov	si, offset SearchList 		; bx:si - OD of SearchList 
	GetResourceHandleNS	SearchList, bx	
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	mov	di, mask MF_FIXUP_DS 		
	call	ObjMessage			; set new exclusive
	andnf	ds:[recStatus], not mask RSF_WARNING ; clear warning flag
	jmp	quit
recDisp:
	push	si
	call	DisableUndo		; no undoable action exists
	pop	si
	clr	ds:[recStatus]
	call	DisplayCurRecord		; and display this record
	andnf	ds:[searchFlag], not mask SOF_NEW   ; clear search flag

	cmp	ds:[displayStatus], CARD_VIEW	; card view only?
	je	exit				; if so, exit

	mov	si, offset SearchList 		; bx:si - OD of SearchList 
	GetResourceHandleNS	SearchList, bx	
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 	
	call	ObjMessage			; get the entry # of selected 
	cmp	ax, GIGS_NONE			; no entry has exclusive?
	jne	haveExcl			; if yes, skip
	tst	ds:[curOffset]			; is card view blank?
	je	exit				; if so, just exit
	clr	ds:[curOffset]			; if not, adjust the variable
	jmp	short	exit			; and then exit

haveExcl:
	TableEntryIndexToOffset  ax
	cmp	ax, ds:[curOffset]		; is it same as card view?
	je	exit				; if so, exit
	mov	ds:[curOffset], ax		; otherwise, get new curOffset
exit:
	call	EnableCopyRecord		; fix up some menu
ifdef GPC
	;
	; bring up note dialog if needed
	;
	tst	ds:[searchNoteIconHit]
	mov	ds:[searchNoteIconHit], 0
	jz	quit
	mov	di, ds:[curRecord]
	tst	di
	jz	quit
	call	DBLockNO
	mov	di, es:[di]
	tst	es:[di].DBR_notes
	call	DBUnlock			; (preserves flags)
	jz	quit				; no notes
	mov	ax, MSG_ROLODEX_NOTES
	call	GeodeGetProcessHandle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
endif
quit:
	ret
FindRecord	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateNameList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the dynamic list so it has the correct entry
		selected.	

CALLED BY:	UTILITY

PASS:		curOffset - offset of current record in main table

RETURN:		nothing

DESTROYED:	ax, bx, cx, bp, si, di

PSEUDO CODE/STRATEGY:
	Gets the entry number of selected entry
	If it is different from current record in card view
		change the name list
	Else exit

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateNameList	proc	far
	cmp	ds:[displayStatus], CARD_VIEW	; card view only?
	je	exit				; if so, exit
	mov	si, offset SearchList 		; bx:si - OD of SearchList 
	GetResourceHandleNS	SearchList, bx	
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 	
	call	ObjMessage			; get the entry # of selected 

	TableEntryIndexToOffset  ax
	cmp	ax, ds:[curOffset]		; is it same as card view?
	je	exit				; if so, exit
	call	SetNewExclusive			; if different, update it
exit:
	ret
UpdateNameList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNewExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the name list so it has the same entry as
		in card view selected.

CALLED BY:	UTILITY

PASS:		curOffset - offset of current record in main table

RETURN:		new entry selected

DESTROYED:	ax, bx, cx, bp, si, di

PSEUDO CODE/STRATEGY:
	Calls the method that sets new entry as exclusive.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNewExclusive	proc	far
	mov	si, offset SearchList	 	; bx:si - OD of SearchList 
	GetResourceHandleNS	SearchList, bx	

	clr	dx				; dx - not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED ; assume no selection
	mov	cx, ds:[curOffset]		; offset to the current record
	TableEntryOffsetToIndex  cx
	test	ds:[recStatus], mask RSF_EMPTY	; is record blank?
	jne	common				; if so, skip	
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION	
common:
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	ObjMessage			; make the selection
	ret
SetNewExclusive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddToNameList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the name of new record to the dynamic list. 

CALLED BY:	InsertRecord	

PASS:		curOffset - offset of current record in main table

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di 

PSEUDO CODE/STRATEGY:
	Calls the method that adds a new entry to dynamic list.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddToNameList	proc	far
	mov	cx, ds:[curOffset]	; cx - offset to one after cur record
	mov	dx, 1			; dx - number of entries to add
	TableEntryOffsetToIndex  cx
	mov	si, offset SearchList 	; bx:si - OD of SearchList 
	GetResourceHandleNS	SearchList, bx	
	mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS	
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage		; add the new entry
	ret
AddToNameList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteFromNameList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes an entry from dynamic list.

CALLED BY:	DeleteMain	

PASS:		curOffset - offset of current record in main table

RETURN:		nothing

DESTROYED:	ax, bx, cx, si, di

PSEUDO CODE/STRATEGY:
	Calls the method that deletes an entry from dynamic list.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteFromNameList	proc	far
	mov	cx, ds:[curOffset]	; cx - offset to one after cur record
	mov	dx, 1			; dx - number of items to delete
	TableEntryOffsetToIndex  cx
	mov	si, offset SearchList 	; bx:si - OD of SearchList 
	GetResourceHandleNS	SearchList, bx	
	mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS	
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage		; delete this entry
	ret
DeleteFromNameList	endp

Search	ends
