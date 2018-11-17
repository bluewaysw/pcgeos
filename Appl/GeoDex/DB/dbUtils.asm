COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Database		
FILE:		dbUtils.asm

AUTHOR:		Ted H. Kim, March 3, 1992

ROUTINES:
	Name			Description
	----			-----------
	FindPrevious		Gets handle of previous record in database
	FindPrevEntry		Find prev. entry using localizable letter tabs
	FindPrevTabLetterWithEntry	Find prev. letter tab with entry
	FindLast		Gets handle of last record in database
	FindNext		Gets handle of next record in database
	FindNextEntry		Find next entry using localizable letter tabs
	FindNextTabLetterWithEntry	Find next letter tab with entry
	GetEntryFromMainTable	Given the offset, get handle of record entry
	CmpCurAndPrevLetter	Compares strings in 'curLetter' and 'prevLetter'
	GetTabLetterStrOfCurRec	Returns the tab letter string for current tab
	FindFirst		Gets handle of the first record in database
	MarkMapDirty		Marks the map block dirty
	RolodexVMFileDirty	Called when you want to mark the document dirty
	CheckForNonAlpha	Checks to see if a character is non-alpha or not
	MoveStringToDatabase	Copy text string from data block to database
	FreeMemChunks		Frees any unneccesary memory chunks
	GetLastName		Reads in the index field into sortBuffer
	DisplayTextFixupDSES, DisplayTextFixupDS
				Sends MSG_VIS_TEXT_REPLACE_ALL_PTR to a text obj
	DBLockNO		Calls DBLock with proper file and group handle
	DBGetMapNO		Calls DBGetMap with proper file and group handle
	DBLockMapNO		Calls DBLockMap with proper file & group handle
	DBAllocNO		Calls DBAlloc with proper file and group handle
	DBReAllocNO		Calls DBReAlloc with proper file & group handle
	DBGroupAllocNO		Calls DBGroupAlloc w/ proper file & group handle
	DBInsertAtNO		Calls DBInsertAt with proper file & group handle
	DBFreeNO		Calls DBFree with proper file & group handle
	DBDeleteAtNO		Calls DBDeleteAt with proper file & group handle
	
	ResortDataFile		Resort GeoDex file
	CompareEntries		Compare two record entries
	SwapEntries		Swap two record entries within "gmb.GMB_mainTable"
	CompareUsingSortOptionNoCase
				Compares two strings using sorting option
	GetSortOption		Update "gmb.GMB_sortOption" flag

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision

DESCRIPTION:
	Contains various utility routines used in database module.	
	NO = "No Override", a fall-back to code from Geos 1.x days.

	$Id: dbUtils.asm,v 1.1 97/04/04 15:49:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPrevious
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the record handle of previous record.

CALLED BY:	RolodexPrevious

PASS:		ds - segment of core block
		curRecord - handle of current record

RETURN:		si - handle of previous record chunk

DESTROYED:	ax, bx, cx, dx, es, si, di

PSEUDO CODE/STRATEGY:
	Is this the 1st entry?
	If so, get the last entry in table
	Otherwise, get the previous entry in table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	8/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindPrevious	proc	near
	tst	ds:[curOffset]		; is this the first record?
	je	last			; if so, get the last entry 

	; check to see if current record is blank

	tst	ds:[curRecord]		
	je	blank			; if so, skip to handle it

	call	FindPrevEntry		; otherwise, find previous entry
	jmp	exit
blank:
	mov	dx, ds:[curOffset]	; if not, skip
	sub	dx, TableEntry		; adjust the offset
	mov	ds:[curOffset], dx	; update curOffset variable	

	call	GetEntryFromMainTable	; si - returns handle of record
	jmp	exit
last:
	mov	di, ds:[gmb.GMB_mainTable]	; di - handle for main table
	call	FindLast		; find the handle of last record
exit:
	ret
FindPrevious	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPrevEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the previous entry taking into consideration the fact 
		that there might be more that one tabs for one letter
		of alphabet. (i.e. 'M' and 'MC' are separate tabs)

CALLED BY:	(INTERNAL) FindPrevious

PASS:		nothing

RETURN:		si - handle of previous entry
		curOffset - updated

DESTROYED:	ax, bx, cx, dx, di, es

SIDE EFFECTS:
	none

PSEUDO CODE/STRATEGY:

	In GeoDex 2.0, you can have more than one letter tabs to represent
	a single alphabet.  For example, if you want to sort all names that
	start with 'MC' (as in 'McDonald') separate from 'M', you can create
	a separate tab for this string, resulting in two tabs for letter 'M'.
	Any entries that start with 'MC' will get sorted into 'MC' tab and
	any other entries that start with 'M' into 'M'.  I will call 'MC'
	to be a subset of letter tab 'M'.  And 'M' the main set.
	Please keep this in mind when reading the following PSEUDO CODE.

	Get the tab letter string of current record
	Save the tab letter string in 'prevLetter'
	Get the tab letter string of the previous recored
	Compare this string with the one in 'prevLetter'

	If these strings match, that means both current record
		and the previous record belong to the same tab.
		So current record is the previous entry to be displayed. 

	If they don't match,
		Compare the 1st letter of 'prevLetter' and 'curLetter'

		If no match, that means the previous record belongs to a tab
			letter that is not a subset of the current record
			tab letter.  So find a previous letter tab that has
			an entry belonging to it.

		If match, that means the tab letter that previous record 
			belongs to is a subset of the current one.
			We have possibly more entries that belong to the
	 		current letter tab further above in the gmb.GMB_mainTable.
			For example, one can have entries stored in the
			following order in gmb.GMB_mainTable: 'Mabellina', 'McDonald',
			'Muster', where both 'Mabellina' and 'Muster' must
			belong to the letter tab 'M' whereas 'McDonald' 
			belongs to letter tab 'MC'.  When these entries are
			being displayed, all of the entries in tab 'MC' must
			be displayed before the ones in 'M'.
			Hence, we have to keep checking the previous entries
			until one of the folloing conditions is met:

			1. End of database - this means that there are no more
			entries that belong to the main set, i.e. 'M'.  So
			find the 1st entry in the subset ('MC') and display it.
			2. Beginning of a new main set, i.e. any letter 
			other than 'M' - this means same as the case 1 above
			do the same thing.
			3. Entry that belongs to the main set (i.e., 'M')
			Display this record.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	8/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindPrevEntry	proc	near

        curRec		local   word	; current DB item
	curRecOffset	local	word	; current entry offset into 'gmb.GMB_mainTable'
	prevRec		local	word	; previous DB item
	prevRecOffset	local	word	; previous entry offset into 'gmb.GMB_mainTable'
	curRecID	local	word	; tab letter ID of current record

	.enter

	; get the tab letter string of the current record

	mov	di, ds:[curRecord]
	call	GetTabLetterStrOfCurRec	; returns string in 'curLetter'
	mov	curRecID, cx		; cx - tab letter ID

	; check to see if current record is the 1st entry in 'gmb.GMB_mainTable'

	mov	dx, ds:[curOffset]	

	; even if this is the 1st entry in data file we can't just grab
	; the last entry as the previous entry because of some subset entries
	; might be store after the current one in gmb.GMB_mainTable

	tst	dx			; 1st entry?
	je	search			; if so, jump to handle it

	sub	dx, size TableEntry 	

	; copy 'curLetter' to 'prevLetter'

	segmov	es, ds
	mov	si, offset curLetter
	mov	di, offset prevLetter
	mov	cx, ds:[curLetterLen]	; cx - number of chars to copy

	LocalCopyNString

	; get the handle of the previous record 

	call	GetEntryFromMainTable	; si - handle of previous entry
	mov	curRec, si		; save it
	mov	curRecOffset, dx	; save offset into gmb.GMB_mainTable

	; get the tab letter string of the previous record

	mov	di, si
	call	GetTabLetterStrOfCurRec

	; now compare 'curLetter' with 'prevLetter'
	; if they match, that means previous entry belongs 
	; to the same letter tab as the current entry

	call	CmpCurAndPrevLetter
	je	done			; exit if equal

	; if they don't match, check to see if the letter tab of previous
	; record is a subset of the current record letter tab.  (for example,
	; 'MC' is a subset of 'M')

	LocalGetChar	ax, ds:curLetter[0], NO_ADVANCE
	LocalCmpChar	ax, ds:prevLetter[0]
	jne	search			; if not subset, then find the next
					; tab letter with an entry

	; subset, so do the right thing (please refer to PSEUDO CODE above)

	mov	dx, curRecOffset
prevRecord:
	; check to see if it is the 1st entry in data file

	tst	dx
	je	search			; if so, jump to handle it 

	sub	dx, size TableEntry 	; go back one entry
	mov	prevRecOffset, dx

	call	GetEntryFromMainTable	; si - handle of previous entry
	mov	prevRec, si		; save the handle

	; get the tab letter string of this record

	mov	di, si
	call	GetTabLetterStrOfCurRec

	; compare 'curLetter' with 'prevLetter'

	call	CmpCurAndPrevLetter
	je	exit

	; if they don't match, check to see if the letter tab of previous
	; record is a subset of the current record letter tab.  (for example,
	; 'MC' is a subset of 'M')

	LocalGetChar	ax, ds:curLetter[0], NO_ADVANCE
	LocalCmpChar	ax, ds:prevLetter[0]
	jne	search			; if not subset, then find previous
					; tab letter with an entry
	mov	dx, prevRecOffset
	jmp	prevRecord

	; find a letter tab that has an entry belonging to it
search:
	mov	dx, curRecID
	mov	al, ds:[curCharSet]
	push	ax
	call	FindPrevTabLetterWithEntry
	pop	ax
	mov	ds:[charSetChanged], FALSE
	cmp	al, ds:[curCharSet]
	je	quit
	mov	ds:[charSetChanged], TRUE
	jmp	quit

	; the next entry found belongs to the main set of letter tab ('M')
done:
	mov	si, curRec
	mov	dx, curRecOffset
	jmp	common

	; the next entry found belongs to the subset of letter tab ('MC')
exit:
	mov	si, prevRec
	mov	dx, prevRecOffset
common:
	mov	ds:[curOffset], dx
quit:
	.leave
	ret
FindPrevEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPrevTabLetterWithEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the handle of entry which belongs to previous letter tab. 

CALLED BY:	(INTERNAL) FindPrevEntry

PASS:		dx - letter tab index (offset into character set)
		ds - dgroup
	
RETURN:		si - handle of previous entry

DESTROYED:	ax, cx, dx, di, es

SIDE EFFECTS:
	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	8/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindPrevTabLetterWithEntry	proc	near
	
	curRec		local	word
	curRecOffset	local	word

	.enter
	mov	al, ds:[curCharSet]

	; loop the character set until we find a letter tab with an entry 
letterLoop:
	dec	dx
	jns	continue			; if not, skip

	; check the next character set

	cmp	ds:[numCharSet], 1		; is there only one char set?
	je	findFirst			; if so, get the 1st entry

	; figure out what the next character set number 

	tst	ds:[curCharSet]			; character set number one? 
	jne	setTwo				; if not, search set one
	inc	ds:[curCharSet]			; must be set one, search two
	jmp	common
setTwo:
	clr	ds:[curCharSet]			; search the 1st character set
common:
	mov	dx, MAX_NUM_OF_LETTER_TABS-1	; re-initialized letter tab ID

	; check to see if this character set has been searched before

	cmp	al, ds:[curCharSet]	
	je	findFirst			; if so, get the 1st entry 

	; check to see if given letter tab has any entries under it
continue:
	call	FindEntryInCurTab		; si - handle if an entry found
	tst	si				; is there an entry?
	jne	findLast			; if yes, exit
	jmp	letterLoop			; if no, keep searching

	; the next entry to be displayed is the first entry in the datafile 
findFirst:
	clr	dx
	call	GetEntryFromMainTable		; get handle of the 1st record

	; now we have to find the last entry that belongs to this letter tab 
findLast:
	mov	ds:[curRecord], si
	mov	dx, ds:[curOffset]
	mov	curRecOffset, dx
	mov	di, si
	call	GetTabLetterStrOfCurRec		; returns string in 'curLetter'

	; copy 'curLetter' to 'prevLetter'

	segmov	es, ds
	mov	si, offset curLetter
	mov	di, offset prevLetter
	mov	cx, ds:[curLetterLen]		; cx - number of chars to copy
	LocalCopyNString

	; keep calling 'FindNextEntry' until we find the last entry
nextRec:
	call	FindNextEntry
	mov	curRec, si

	; get the tab letter string of this record

	mov	di, si
	call	GetTabLetterStrOfCurRec

	; now check to see if this entry belongs to the current letter tab

	call	CmpCurAndPrevLetter	
	je	next			; skip if equal

	; we have found the last entry in the current tab

	mov	si, ds:[curRecord]
	mov	dx, curRecOffset
	mov	ds:[curOffset], dx
	jmp	exit

	; continue to grab the next entry until we find the last entry
next:
	mov	si, curRec
	mov	ds:[curRecord], si
	mov	dx, ds:[curOffset]
	mov	curRecOffset, dx
	jmp	nextRec
exit:
	.leave
	ret
FindPrevTabLetterWithEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the handle of the last record in database file.

CALLED BY:	(INTERNAL) FindPrevious

PASS:		ds - segment of core block
		di - handle of main (or filter) table

RETURN:		si - handle of last record chunk

DESTROYED:	dx, si, di, es 	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	8/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindLast	proc	near
	call	DBLockNO
	mov	si, es:[di]		; open up the main table
	add	si, ds:[gmb.GMB_endOffset]	; si - ptr to end of main table
	sub	si, size TableEntry	; si - ptr to the last record 
	mov	si, es:[si].TE_item	; si - item number of last entry
	mov	dx, ds:[gmb.GMB_endOffset]	; dx - offset to end of main table
	sub	dx, size TableEntry	; dx - offset to the last record
	mov	ds:[curOffset], dx	; update the current record offset
	call	DBUnlock
	ret
FindLast	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the handle of next record.

CALLED BY:	RolodexNext

PASS:		ds - segment of core block
		curRecord - handle of current record

RETURN:		si - handle of next record chunk

DESTROYED:	ax, bx, cx, dx, si, di, es, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNext	proc	near

	; check to see if current record is pointing to the one past
	; the last entry in data file

	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table
	mov	dx, ds:[gmb.GMB_endOffset]	; dx - offset to last record
	cmp	dx, ds:[curOffset]	
	je	firstRec		; jump to get the 1st entry 

	test	ds:[recStatus], mask RSF_EMPTY	; empty record?
	jne	empty			; skip if so

	; find the next entry taking into consideration the fact 
	; that one might have more that one tabs for one letter
	; of alphabet. (i.e. 'M' and 'MC')

	call	FindNextEntry
	jmp	exit

	; if empty, find the record with 'curOffset' as offset into 'gmb.GMB_mainTable'
empty:
	mov	dx, ds:[curOffset]	
	jmp	getIt

	; get the 1st entry in data file
firstRec:
	clr	dx			; dx - offset into 'gmb.GMB_mainTable'
	mov	ds:[curOffset], dx	; update curOffset variable
getIt:
	call	GetEntryFromMainTable	; returns si - handle
exit:
	ret
FindNext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNextEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next entry taking into consideration the fact 
		that there might be more that one tabs for one letter
		of alphabet. (i.e. 'M' and 'MC' are separate tabs)

CALLED BY:	(INTERNAL) FindNext

PASS:		nothing

RETURN:		si - handle of next entry
		curOffset - updated

DESTROYED:	ax, bx, cx, dx, di, es

SIDE EFFECTS:
	none

PSEUDO CODE/STRATEGY:

	In GeoDex 2.0, you can have more than one letter tabs to represent
	a single alphabet.  For example, if you want to sort all names that
	start with 'MC' (as in 'McDonald') separate from 'M', you can create
	a separate tab for this string, resulting in two tabs for letter 'M'.
	Any entries that start with 'MC' will get sorted into 'MC' tab and
	any other entries that start with 'M' into 'M'.  I will call 'MC'
	to be a subset of letter tab 'M'.  And 'M' the main set.
	Please keep this in mind when reading the following PSEUDO CODE.

	Get the tab letter string of current record
	Save the tab letter string in 'prevLetter'
	Get the tab letter string of the next recored
	Compare this string with the one in 'prevLetter'

	If these strings match, that means both current record
		and the next record belong to the same tab.
		So current record is the next entry to be displayed. 

	If they don't match,
		Compare the 1st letter of 'prevLetter' and 'curLetter'

		If no match, that means the next record belongs to a tab
			letter that is not a subset of the current record
			tab letter.  So find a next letter tab that has
			an entry belonging to it.

		If match, that means the tab letter that next record belongs
			to is a subset of the current one.
			We have possibly more entries that belong to the
	 		current letter tab further down in the gmb.GMB_mainTable.
			For example, one can have entries stored in the
			following order in gmb.GMB_mainTable: 'Mabellina', 'McDonald',
			'Muster', where both 'Mabellina' and 'Muster' must
			belong to the letter tab 'M' whereas 'McDonald' 
			belongs to letter tab 'MC'.  When these entries are
			being displayed, all of the entries in tab 'M' must
			be displayed before the ones in 'MC'.
			Hence, we have to keep checking the next entries until
			one of the folloing conditions is met:

			1. End of database - this means that there are no more
			entries that belong to the main set, i.e. 'M'.  So
			find the 1st entry in the subset ('MC') and display it.
			2. Beginning of a new main set, i.e. any letter 
			other than 'M' - this means same as the case 1 above
			do the same thing.
			3. Entry that belongs to the main set (i.e., 'M')
			Display this record.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	8/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNextEntry	proc	near

        curRec		local   word	; current DB item
	curRecOffset	local	word	; current entry offset into 'gmb.GMB_mainTable'
	nextRec		local	word	; next DB item
	nextRecOffset	local	word	; next entry offset into 'gmb.GMB_mainTable'
	curRecID	local	word	; tab letter ID of current record

	.enter

	; get the tab letter string of the current record

	mov	di, ds:[curRecord]
	call	GetTabLetterStrOfCurRec	; returns string in 'curLetter'
	mov	curRecID, cx		; cx - tab letter ID

	; check to see if current record is the last entry in 'gmb.GMB_mainTable'

	mov	dx, ds:[curOffset]	
	add	dx, size TableEntry 	

	; even if this is the last entry in data file we can't just grab
	; the first entry as the next entry because of some subset entries
	; might be store ahead of the current one in gmb.GMB_mainTable

	cmp	dx, ds:[gmb.GMB_endOffset]	; last entry?
	je	search			; if so, jump to handle it

	; copy 'curLetter' to 'prevLetter'

	segmov	es, ds
	mov	si, offset ds:curLetter
	mov	di, offset ds:prevLetter
	mov	cx, ds:[curLetterLen]	; cx - number of chars to copy
	LocalCopyNString

	; get the handle of the next record 

	call	GetEntryFromMainTable	; si - handle of next entry
	mov	curRec, si		; save it
	mov	curRecOffset, dx	; save offset into gmb.GMB_mainTable

	; get the tab letter string of the next record

	mov	di, si			; di <- curRec
	call	GetTabLetterStrOfCurRec

	; now compare 'curLetter' with 'prevLetter'
	; if they match, that means the next entry belongs 
	; to the same letter tab as the current entry

	call	CmpCurAndPrevLetter
	je	done			; exit if equal

	; if they don't match, check to see if the letter tab of the next
	; record is a subset of the current record letter tab.  (for example,
	; 'MC' is a subset of 'M')

	LocalGetChar	ax, ds:curLetter[0], NO_ADVANCE
	LocalCmpChar	ax, ds:prevLetter[0]
	jne	search			; if not subset, then find the next
					; tab letter with an entry

	; subset, so do the right thing (please refer to PSEUDO CODE above)

	mov	dx, curRecOffset
nextRecord:
	add	dx, size TableEntry 	; go forward one entry
	mov	nextRecOffset, dx

	; check to see if it is the last entry in data file

	cmp	dx, ds:[gmb.GMB_endOffset]	
	je	search			; if so, jump to handle it 

	call	GetEntryFromMainTable	; si - handle of next entry
	mov	nextRec, si		; save the handle

	; get the tab letter string of this record

	mov	di, si
	call	GetTabLetterStrOfCurRec

	; compare 'curLetter' with 'prevLetter'

	call	CmpCurAndPrevLetter
	je	exit

	; if they don't match, check to see if the letter tab of the next
	; record is a subset of the current record letter tab.  (for example,
	; 'MC' is a subset of 'M')

	LocalGetChar	ax, ds:curLetter[0], NO_ADVANCE
	LocalCmpChar	ax, ds:prevLetter[0]
	jne	search			; if not subset, then find the next
					; tab letter with an entry
	mov	dx, nextRecOffset
	jmp	nextRecord

	; find a letter tab that has an entry belonging to it
search:
	mov	dx, curRecID
	mov	al, ds:[curCharSet]
	push	ax
	call	FindNextTabLetterWithEntry
	pop	ax
	mov	ds:[charSetChanged], FALSE
	cmp	al, ds:[curCharSet]
	je	quit
	mov	ds:[charSetChanged], TRUE
	jmp	quit

	; the next entry found belongs to the main set of letter tab ('M')
done:
	mov	si, curRec
	mov	dx, curRecOffset
	jmp	common

	; the next entry found belongs to the subset of letter tab ('MC')
exit:
	mov	si, nextRec
	mov	dx, nextRecOffset
common:
	mov	ds:[curOffset], dx
quit:
	.leave
	ret
FindNextEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNextTabLetterWithEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the handle of entry which belongs to the next letter tab. 

CALLED BY:	(INTERNAL) FindNextEntry

PASS:		dx - letter tab index (offset into character set)

RETURN:		si - handle of next entry

DESTROYED:	ax, cx, dx, di, es

SIDE EFFECTS:
	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	8/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNextTabLetterWithEntry	proc	near
	mov	al, ds:[curCharSet]

	; loop the character set until we find a letter tab with an entry 
letterLoop:
	inc	dx
	cmp	dx, MAX_NUM_OF_LETTER_TABS-1	; end of character set? 
	jne	continue			; if not, skip

	; check the next character set

	cmp	ds:[numCharSet], 1		; is there only one char set?
	je	findFirst			; if so, get the 1st entry

	; figure out what the next character set number 

	tst	ds:[curCharSet]			; character set number one? 
	jne	setTwo				; if not, search set one
	inc	ds:[curCharSet]			; must be set one, search two
	jmp	common
setTwo:
	clr	ds:[curCharSet]			; search the 1st character set
common:
	clr	dx				; re-initialized letter tab ID

	; check to see if this character set has been searched before

	cmp	al, ds:[curCharSet]	
	je	findFirst			; if so, get the 1st entry 

	; check to see if given letter tab has any entries under it
continue:
	call	FindEntryInCurTab		; si - handle if an entry found
	tst	si				; is there an entry?
	jne	exit				; if yes, exit
	jmp	letterLoop			; if no, keep searching

	; the next entry to be displayed is the first entry in the datafile 
findFirst:
	clr	dx
	mov	ds:[curOffset], dx		; update curOffset
	call	GetEntryFromMainTable		; get handle of the 1st record
exit:
	ret
FindNextTabLetterWithEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetEntryFromMainTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the offset into gmb.GMB_mainTable get the handle of the entry.

CALLED BY:	(INTERNAL) 

PASS:		dx - offset into 'gmb.GMB_mainTable'

RETURN:		si - handle of the entry

DESTROYED:	di, es

SIDE EFFECTS:
	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	8/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetEntryFromMainTable	proc	near
	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table
	call	DBLockNO
	mov	si, es:[di]		; open up the main table
	add	si, dx			; go forward one entry
	mov	si, es:[si].TE_item 	; ax - 1st two chars of last name
	call	DBUnlock
	ret
GetEntryFromMainTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CmpCurAndPrevLetter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the string in 'curLetter' with the one in 'prevLetter'

CALLED BY:	(INTERNAL) FindNextEntry

PASS:		curLetterLen - number of chars to compare

RETURN:		flags set accordingly

DESTROYED:	cx, si, di, es

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	8/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CmpCurAndPrevLetter	proc	near
	push	cx
	segmov	es, ds
	mov	si, offset curLetter	; ds:si - string one
	mov	di, offset prevLetter	; es:di - string two
	mov	cx, ds:[curLetterLen]	; cx - number of chars to compare
	call	LocalCmpStringsNoCase	; compare these two strings
	pop	dx
	ret
CmpCurAndPrevLetter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTabLetterStrOfCurRec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the tab letter string of current record.

CALLED BY:	(INTERNAL) FindNextEntry

PASS:		di - handle of current record

RETURN:		curLetter - tab letter string
		curLetterLen - char count of tab letter string
		cx - tab letter index

DESTROYED:	ax, bx, si, di, es 

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	8/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTabLetterStrOfCurRec	proc	near	uses	dx
	.enter

	; copy the index field of the current entry to 'curLetter' buffer

	call	DBLockNO
	mov	di, es:[di]
	add	di, size DB_Record	; es:di - ptr to index field
	mov	cx, MAX_TAB_LETTER_LENGTH-1	; cx - max chars to examine
	mov	si, offset ds:curLetter
copyLoop:
	LocalGetChar	ax, esdi, noAdvance ; ax - character to convert
	LocalIsNull	ax		; Is this null?
	je	exitLoop

if PZ_PCGEOS
	call	GetPizzaLexicalValueNear ; ax <- pizza lexical value
	cmp	ax, C_FULLWIDTH_LATIN_CAPITAL_LETTER_A
	jne	skip
	mov	ax, 'A'
skip:
endif
	call	GetLexicalValue		; get lexical value of this character
if DBCS_PCGEOS
	mov	{wchar} ds:[si], ax
else
	mov	{char} ds:[si], al
endif
	LocalNextChar	esdi			
	LocalNextChar	dssi
	loop	copyLoop		; get the next character

exitLoop:
	LocalClrChar	ds:[si] 	; null terminate the buffer
	call	DBUnlock

	; search for this tab letter string within the character set

	GetResourceHandleNS	TextResource, bx
	call	MemLock				; lock the block w/ char set
	mov	es, ax				; set up the segment
	mov	di, offset LetterTabCharSetTable
	mov	di, es:[di]			; dereference the handle
	call	SearchCharSet			; search for this string
	call	MemUnlock			; unlock it

	.leave
	ret
GetTabLetterStrOfCurRec	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFirst
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the handle of the 1st record in database file.

CALLED BY:	FindNext

PASS:		di - handle of main (or filter) table

RETURN:		si - handle of the 1st record chunk

DESTROYED:	di, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	8/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindFirst	proc	far
	call	DBLockNO
	mov	si, es:[di]		; open up the main table
	mov	si, es:[si].TE_item	; si - handle of the first record
	call	DBUnlock		; close it up
	mov	ds:[curOffset], 0	; update current record offset
	ret
FindFirst	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkMapDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Marks the map block dirty.

CALLED BY:	UTILITY

PASS:		ds - dgroup
			fileHandle - handle for DB rolodex file.
RETURN:		nothing

DESTROYED:	es, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	5/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkMapDirty	proc	far
	call	DBLockMapNO		; lock the map block
	call	DBDirty			; mark it dirty
	call	DBUnlock		; unlock the map block
	ret
MarkMapDirty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexVMFileDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with the current document being marked dirty

CALLED BY:	MSG_META_VM_FILE_DIRTY (from VM code in the kernel)

PASS:		DS	= dgroup
		CX	= our file handle open to the document file

RETURN:		Nothing

DESTROYED:	AX, BX, SI, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RolodexVMFileDirty	proc	far

	class	RolodexClass

	; Pass this on to the application document control
	
	GetResourceHandleNS	RolAppDocControl, bx
	mov	si, offset RolAppDocControl
	mov	ax, MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE
	clr	di
	call	ObjMessage
	ret
RolodexVMFileDirty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexTextDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when any of the text objects becomes dirty.

CALLED BY:	MSG_META_TEXT_USER_MODIFIED	

PASS:		cx:dx - OD of text object being dirtied (????)

RETURN:		nothing

DESTROYED:	ax, bx, cx, si, di 	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	I assume cx:dx to be OD of text object being dirtied.
	This might be an incorrect assumption.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexTextDirty	proc	far

	class	RolodexClass
	
	mov	ax, ds:[fileHandle]	; ax - current file handle
	tst	ax
	jz	exit			; exit if no file is open

ifdef GPC
	;
	; if Name field in New dialog, enable create trigger
	;
	GetResourceHandleNS	NewDialogResource, bx
	cmp	cx, bx
	jne	notNew
	cmp	dx, offset NewLastNameField
	jne	notNew
	mov	si, offset NewDialogResource:NewCreate
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage
	jmp	short exit

notNew:
endif

	; check to see if this is prefix field in phone options DB

	GetResourceHandleNS	PrefixField, bx
	cmp	cx, bx
	jne	dirty			; jump to mark the file dirty

	cmp	dx, offset PrefixField
	je	exit			; if PrefixField, just exit

	; check to see if this is current area code field in phone options DB

	cmp	dx, offset CurrentAreaCodeField
	je	exit			; if CurrentAreaCodeField, just exit

	; check to see if this is assumed area code field in phone options DB

	cmp	dx, offset AssumedAreaCodeField
	je	exit			; if AssumedAreaCodeField, just exit
dirty:
	call	MarkMapDirty		; mark the VM file dirty
	test	ds:[recStatus], mask RSF_NEW    ; new record?
	jne	exit			; if so, exit
	call	EnableUndo		; enable undo menu
exit:
	ret
RolodexTextDirty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForNonAlpha
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if a given character is a non-alphabet or not.
		SBCS:  Checks ah, the first of a character pair.
		DBCS:  Checks ax since chars take whole register.

CALLED BY:	UTILITY

PASS:		if DBCS_PCGEOS
			ax - character to check
		else
			ah - character to check

RETURN:		carry set if a non-alphabetic character	
		carry clear if an alphabet

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForNonAlpha	proc	far

if DBCS_PCGEOS
if PZ_PCGEOS
	cmp	ax, C_FULLWIDTH_LATIN_CAPITAL_LETTER_A	;alphabetic?
	je	alpha			; if so, skip
	call	LocalIsKana		; is the character a kana?
	jnz	alpha			; if so, skip

	stc				; non-{alphabet, kana} character
	ret
alpha:
	clc				; alphabet, kana character
	ret
else
	;****  DBCS GENERAL  ***********
	call	LocalIsAlpha		; ax - the character to compare
	jz	Non_Alpha		; is the character an alphabet?
endif
else
	;****  SBCS GENERAL  ***********
	push	ax
	mov	al, ah			; al - the character to compare
	clr	ah
	call	LocalIsAlpha		; is the character an alphaber?
	pop	ax
	jz	Non_Alpha		; if not, skip
endif

if not PZ_PCGEOS

	clc				; alphabet character
	ret
Non_Alpha:
	stc				; non-alphabet character
	ret
endif

CheckForNonAlpha	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveStringToDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the text string from temporary data block to database.

CALLED BY:	UTILITY

PASS:		dx - offset to destination
		bp - offset to fieldHandles (TEFO_xxx)
		cx - string length (char count, including C_NULL)
		ds - dgroup
			ds:fieldHandles[bp]

RETURN:		nothing

PSEUDEO-CODE:
		Trims leading white space from string before storing.
		It seems OK to *always* copy 'cx' chars, even if there
			are leading spaces.

DESTROYED:	ax, bx, cx, es, di, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/13/89	Initial version
	witt	1/22/94 	DBCS-ized. Uses LocalIsSpace()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MoveStringToDatabase	proc	near
	mov	bx, ds:fieldHandles[bp] ; bx - handle to index block
	tst	bx			; is it an empty field?
	jz	exit			; if so, exit 

	mov	di, ds:[curRecord]	; di - current record handle
	call	DBLockNO		; open up the record again
	mov	di, es:[di]
	add	di, dx			; di - offset to place insert
	push	ds
	call	MemLock			; lock block so we can get segment addr
EC <	ERROR_C	MEMORY_BLOCK_DISCARDED					>
	mov	ds, ax			; ds - segment of temp text block
	clr	si			; si - points to start of string

	cmp	bp, TEFO_INDEX 		; is it index field?
	jne	copyString		; if not, copy string verbatim
skipSpaceLoop:
if DBCS_PCGEOS
	LocalGetChar	ax, dssi, NO_ADVANCE
	LocalIsNull	ax
	je	copyString		; oh well, just copy a NULL string.
	call	LocalIsSpace
	jz	copyString		; go copy from here to end..
else
	cmp	{char} ds:[si], ' '	; space character?
	je	next			; if so, check the next character

	cmp	{char} ds:[si], C_TAB	; tab?
	jne	copyString		; if not, skip
next:
endif
	LocalNextChar	dssi		; check the next character
	jmp	skipSpaceLoop

copyString:
	LocalCopyNString 		; copy string from temp blk to data blk
	call	MemFree			; destroy temporary text block 
	pop	ds
	clr	ds:fieldHandles[bp]	; clear the handle
	call	DBUnlock		; close it up
exit:
	ret
MoveStringToDatabase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeMemChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes any unneccesary memory blocks. 

CALLED BY:	UTILITY

PASS:		cx - number of handles to check for
		bp - offset to FieldTable (TEFO_xxx)

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
	For each entry in FieldTable
		Get the handle to memory block
		Delete it if not zero
	Check the next entry

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	9/26		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeMemChunks	proc	near
mainLoop:	
	mov	bx, ds:fieldHandles[bp] ; bx - handle of text block
	tst	bx			; is it an empty field?
	jz	empty			; skip if empty
	call	MemFree			; destroy the memory block
	clr	ds:fieldHandles[bp]	; clear handle of text block
empty:	
	add	bp, (size nptr)		; bp - points to the next entry
	loop	mainLoop		; check the next field
	ret
FreeMemChunks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLastName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the contents of index field into 'sortBuffer'.

CALLED BY:	UTILITY

PASS:		si - db item of current record

RETURN:		ds:sortBuffer - constains the sort field

DESTROYED:	cx, es, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The "index" string is stored right after the DB_Record.
	Currently (Feb 94), Pizza LastNameField is labeled "Phonetic"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	9/4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLastName	proc	far
	push	si			; save current record handle
	LocalClrChar  ds:[sortBuffer]	; null terminate the buffer
	mov	di, si			; di - current record handle
	call	DBLockNO		; open up current record
	mov	si, es:[di]		; si - ptr to beg of record data
	mov	cx, es:[si].DBR_indexSize  ; cx - length of index field
	tst	cx			; is index field empty?
	je	unlock			; empty: unlockand return.

	add	si, size DB_Record	; si - ptr to index field

 	push	es, ds
 	segmov	ds, es			; ds - source block
 	pop	es			; es - destination block
 	push	es
	mov	di, offset sortBuffer	; di - offset to dest. buffer
	rep	movsb			; move data
	pop	es, ds			; restore segment registers
unlock:
	call	DBUnlock
	pop	si			; restore current record handle
	ret
GetLastName	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayTextFixupDSES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends MSG_VIS_TEXT_REPLACE_ALL_PTR to a text object.
		Displays the C_NULL terminate string at dx:bp.

CALLED BY:	UTILITY

PASS:		si - offset into FieldTable
		dx:bp - points to string to display (NULL terminated)

RETURN:		nothing

DESTROYED:	ax, bx, cx, si, di 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not PZ_PCGEOS
DisplayTextFixupDSES	proc	far
	clr	cx				; null terminated string
	mov	si, ds:FieldTable[si]
	GetResourceHandleNS	Interface, bx	; bx:si - optr of text object
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage			; display the text strings
	ret
DisplayTextFixupDSES	endp
endif

DisplayTextFixupDS	proc	far
	clr	cx				; null terminated string
	mov	si, ds:FieldTable[si]
	GetResourceHandleNS	Interface, bx	; bx:si - optr of text object
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; display the text strings
	ret
DisplayTextFixupDS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBLockNO 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBLock with no overrides.

CALLED BY:	UTILITY

PASS:		ds - dgroup
		di - db item to lock

RETURN:		es:*di = pointer to database item

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBLockNO	proc	far	uses	ax, bx
	.enter
	mov	bx, ds:[fileHandle]	; bx - database file handle
	mov	ax, ds:[groupHandle]	; ax - group handle
	call	DBLock
	.leave
	ret
DBLockNO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBSetMapNO 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBSetMap with no overrides.

CALLED BY:	UTILITY

PASS:		ds - dgroup

RETURN:		same as DBSetMap

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBSetMapNO	proc	far	uses	ax, bx
	.enter
	mov	bx, ds:[fileHandle]	; bx - database file handle
	mov	ax, ds:[groupHandle]	; ax - group handle
	call	DBSetMap
	.leave
	ret
DBSetMapNO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGetMapNO 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBGetMap with no overrides.

CALLED BY:	UTILITY

PASS:		ds - dgroup

RETURN:		ax - group
		dx - item

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBGetMapNO	proc	far	uses	bx
	.enter
	mov	bx, ds:[fileHandle]	; bx - database file handle
	call	DBGetMap
	.leave
	ret
DBGetMapNO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBLockMapNO 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBLockMap with no overrides.

CALLED BY:	UTILITY

PASS:		ds - dgroup

RETURN:		es:*di = pointer to the map item
		di = 0 if there is no map.

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBLockMapNO	proc	far	uses	ax, bx
	.enter
	mov	bx, ds:[fileHandle]	; bx - database file handle
	call	DBLockMap
	.leave
	ret
DBLockMapNO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBAllocNO 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBAlloc with no overrides.

CALLED BY:	UTILITY

PASS:		ds - dgroup
		cx - size of chunk to allocate

RETURN:		same as DBAlloc

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBAllocNO	proc	far	uses	ax, bx
	.enter
	mov	bx, ds:[fileHandle]	; bx - database file handle
	mov	ax, ds:[groupHandle]	; ax - group handle
	call	DBAlloc
	.leave
	ret
DBAllocNO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBReAllocNO 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBReAlloc with no overrides.

CALLED BY:	UTILITY

PASS:		ds - dgroup

RETURN:		Same as DBReAlloc

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBReAllocNO	proc	far	uses	ax, bx
	.enter
	mov	bx, ds:[fileHandle]	; bx - database file handle
	mov	ax, ds:[groupHandle]	; ax - group handle
	call	DBReAlloc
	.leave
	ret
DBReAllocNO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGroupAllocNO 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBGroupAlloc with no overrides.

CALLED BY:	UTILITY

PASS:		ds - dgroup

RETURN:		ax - group

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBGroupAllocNO	proc	far	uses	bx
	.enter
	mov	bx, ds:[fileHandle]	; bx - database file handle
	call	DBGroupAlloc
	.leave
	ret
DBGroupAllocNO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBInsertAtNO 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBInsertAt with no overrides (Geos 1.x anachranism).

CALLED BY:	UTILITY

PASS:		ds - dgroup
		di = item.	(Offset into group block).
		dx = offset to insert at.
		cx = # of bytes to insert.

RETURN:		ds = segment address of same item-block that was passed in.
		es = segment address of same item-block that was passed in.
		     (unchanged if it was not pointing at an item block).

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBInsertAtNO	proc	far	uses	ax, bx
	.enter
	mov	bx, ds:[fileHandle]	; bx - database file handle
	mov	ax, ds:[groupHandle]	; ax - group handle
	call	DBInsertAt
	.leave
	ret
DBInsertAtNO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBFreeNO 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBFree with no overrides.

CALLED BY:	UTILITY

PASS:		ds - dgroup

RETURN:		Same as DBFreeNO

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBFreeNO	proc	far	uses	ax, bx
	.enter
	mov	bx, ds:[fileHandle]	; bx - database file handle
	mov	ax, ds:[groupHandle]	; ax - group handle
	call	DBFree
	.leave
	ret
DBFreeNO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBDeleteAtNO 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBDeleteAt with no overrides.

CALLED BY:	UTILITY

PASS:		ds - dgroup
		cx - byte size to delete
		di - record handle

RETURN:		Same as DBDeleteAt

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBDeleteAtNO	proc	far	uses	ax, bx
	.enter
	mov	bx, ds:[fileHandle]	; bx - database file handle
	mov	ax, ds:[groupHandle]	; ax - group handle
	call	DBDeleteAt
	.leave
	ret
DBDeleteAtNO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResortDataFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resort the GeoDex database file using insertion sort.

CALLED BY:	(GLOBAL) MSG_ROLODEX_RESORT

PASS:		cx - identifier of item selected

RETURN:		file resorted

DESTROYED:	ax, bx, cx, dx, si, di, bp

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResortDataFile	proc	far

	class	RolodexClass
	
	push	cx				; save selection
	call	SaveCurRecord			; save a possibly new record
	pop	cx				; restore selection

	; check to see which item is selected

	mov	al, ds:[gmb.GMB_sortOption]	; al - current sort option
	tst	cx
	jne	skip				; skip if item one selected

	; check to see if we need to resort the data file

	test	al, mask SF_DONT_IGNORE_SPACE
	LONG	jne	exit			; no need to resort	
	jmp	resort
skip:
	; check to see if we need to resort the data file

	test	al, mask SF_IGNORE_SPACE
	jne	exit				; no need to resort	
resort:
	; put up a warning message

	mov	bp, ERROR_RESORT_WARNING	; bp - RolodexErrorValue
	call	DisplayErrorBox			

	cmp	ax, IC_YES			; continue?
	je	continue			; if so, skip
	call	SetSortOption			; if no, reset the option
	jmp	exit
continue:
	call	GetSortOption			; update gmb.GMB_sortOption flag
	call	MarkMapDirty			; mark the file dirty

	mov	di, ds:[gmb.GMB_mainTable]
	call	DBLockNO			; lock gmb.GMB_mainTable
	mov	di, es:[di]

	mov	ax, ds:[gmb.GMB_numMainTab]
	sub	ax, ds:[gmb.GMB_numNonAlpha]	; ax - number of recs to resort

	cmp	ax, 1				; one or less number of entry?
	jle	nonAlpha			; then no need to resort

	clr	dx				; dx - beginning offset
	mov	bx, ds:[gmb.GMB_offsetToNonAlpha]	; bx - ending offset
	call	ResortDatabase			; resort alphabet records
nonAlpha:
	mov	ax, ds:[gmb.GMB_numNonAlpha]	; ax - number of non-alpha recs
	cmp	al, 1				; one or less ?
	jle	done				; if so, no need to resort

	mov	dx, ds:[gmb.GMB_offsetToNonAlpha]	; dx - beginning offset
	mov	bx, ds:[gmb.GMB_endOffset]		; bx - ending offset
	call	ResortDatabase			; resort non-alpha records
done:
	call	DBDirty				; mark gmb.GMB_mainTable dirty
	call	DBUnlock
	call	GetSortOption			; update gmb.GMB_sortOption flag

	clr	ds:[curOffset]
	call	ReDrawBrowseList		; redraw index list

	; display the first record in data file

	
	mov	di, ds:[gmb.GMB_mainTable]
	call	DBLockNO
	mov	di, es:[di]
	add	di, ds:[curOffset]
	mov	si, es:[di].TE_item
	call	DBUnlock
	call	DisplayCurRecord
exit:
	ret
ResortDataFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReDrawBrowseList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-initialize the index list for GeoDex after sorting.

CALLED BY:	(GLOBAL)

PASS:		displayStatus - current view mode

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReDrawBrowseList	proc	far
	cmp	ds:[displayStatus], CARD_VIEW	; card view only?
	je	done				; if so, exit

	; redraw the index list

	mov	si, offset SearchList 		; bx:si - OD of SearchList 
	GetResourceHandleNS	SearchList, bx	
	mov	cx, ds:[gmb.GMB_numMainTab]		; cx - # of entries in database
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	ObjMessage			; redraw the dynamic list

	; select the 1st entry in the index list

	clr	dx				; dx - no indeterminate
	mov	cx, ds:[curOffset]		; cx - entry # to select 
	TableEntryOffsetToIndex	cx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	ObjMessage			; make the selection
done:
	ret
ReDrawBrowseList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResortDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resort part of data file.

CALLED BY:	ResortDataFile

PASS:		dx - beginning offset into gmb.GMB_mainTable
		bx - ending offset into gmb.GMB_mainTable

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx 

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	2/26/93		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResortDatabase	proc	near		uses	di
	.enter

	sub	bx, dx
	add	di, dx
	mov	bp, di			; bp - ptr to beginning of gmb.GMB_mainTable
	clr	dx
outerLoop:
	add	dx, size TableEntry
	cmp	bx, dx			; are we done?
	je	exit			; exit if so

	; keep this partial list in order 

	push	dx
	mov	di, bp			; es:di - ptr to beg. of gmb.GMB_mainTable 
	add	di, dx			; es:di - last entry
	mov	si, di
	sub	si, size TableEntry	; es:si - entry before last one

	; compare the last two entries in the list
	; if last entry > second to last entry, then list is in order
compare:
	call	CompareEntries		
	jae	noSwap			

	; otherwise, swap these two entries and then keep comparing 

	call	SwapEntries		; swap two entries

	; shrink the list by one entry

	sub	si, size TableEntry	; es:si - entry before the last one	
	sub	di, size TableEntry	; es:di - last entry
	sub	dx, size TableEntry	
	jne	compare
noSwap:
	pop	dx			; make the list one entry bigger
	jmp	outerLoop
exit:
	.leave
	ret
ResortDatabase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the index field strings of two record entries.

CALLED BY:	(INTERNAL) ResortDatabase

PASS:		es:di - pointer to entry1 to compare
		es:si - pointer to entry2 to compare

RETURN:		results of compare

DESTROYED:	ax, cx	

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
	PIZZA version: sort keys are three; 1) the lexical value of the first
	word in index field, 2) 2) whole index field and 3) phonetic field.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareEntries	proc	near
	uses	bx, dx, si, di, ds, es, bp	
	.enter

	mov	di, es:[di].TE_item	; de-reference entries to compare
	mov	si, es:[si].TE_item

	; lock the last entry

	call	DBLockNO
	mov	di, es:[di]
if PZ_PCGEOS
	push	di				; save ptr to 1st record
endif
	add	di, size DB_Record		; es:di - ptr to index field
	push	es, di				; save 1st index ptr

	; lock the second to last entry

	mov	di, si				; di - handle of DB block
	call	DBLockNO
	mov	di, es:[di]
if PZ_PCGEOS
	mov	cx, di				; save ptr to 2nd record
endif
	add	di, size DB_Record		; es:di - ptr to index field

if PZ_PCGEOS
	; check the first char as a key
	mov	bp, ds				; save dgroup seg
	pop	ds, si				; ds:si - 1st index ptr 
	push	cx				; save ptr to 2nd record

	LocalGetChar ax, dssi, noAdvance	; ax <- ds:si
	call	GetPizzaLexicalValue		;
	mov_tr	cx, ax				; cx <- pizza lexical value
	LocalGetChar ax, esdi, noAdvance	; ax <- es:di
	call	GetPizzaLexicalValue		; ax <- pizza lexical value
	cmp	cx, ax				; Are keys same?
	jne	clean2				; no, clean up stack
endif
	clr	cx				; strings are null terminated

	; check to see which sorting option is selected
if PZ_PCGEOS
	push	ds
	mov	ds, bp				;ds=dgroup temporarily
endif
	test	ds:[gmb.GMB_sortOption], mask SF_IGNORE_SPACE 
if PZ_PCGEOS
	pop	ds				; ds:si - ptr to last entry
else
	pop	ds, si				; ds:si - ptr to last entry 
endif
	jz	space				; spaces count.

	call	LocalCmpStringsNoSpaceCase	; spaces don't count.
if PZ_PCGEOS
	jmp	check2
else
	jmp	clean
endif

space:
	call	LocalCmpStringsNoCase		; spaces count!
if PZ_PCGEOS
check2:
	jne	clean2				; if diff, clean up stacks

	; keys and indexes are the same, so we have to check phonetic field
	pop	di				; restore ptr to record
	add	di, es:[di].DBR_toPhonetic	; es:di - ptr to 1st phon
	pop	si				; restore ptr to record
	add	si, es:[si].DBR_toPhonetic	; ds:si - ptr to 2nd phon

	; check to see which sorting option is selected
	push	ds
	mov	ds, bp
	test	ds:[gmb.GMB_sortOption], mask SF_IGNORE_SPACE
	pop	ds

	je space2
	call	LocalCmpStringsNoSpaceCase
	jmp	clean
space2:
	call	LocalCmpStringsNoCase
	jmp	clean
clean2:
	pop	si, di				; just clean up stack
endif

	; do some clean up, but preserve flags.
clean:
	pushf
	call	DBUnlock			; unlock second to last entry
	segmov	es, ds
	call	DBUnlock			; unlock last entry
	popf

	.leave
	ret
CompareEntries	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap two entries in "gmb.GMB_mainTable".

CALLED BY:	(INTERNAL) ResortDatabase

PASS:		es:di - pointer to entry1
		es:si - pointer to entry2

RETURN:		entry1 and entry2 swapped

DESTROYED:	ax

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision
	witt	2/94		Added flexible DBCS exchange code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapEntries	proc	near

if (size TableEntry) eq 4
	push	bx

	; swap key field of TableEntry

	mov	ax, es:[di].TE_key
	mov	bx, es:[si].TE_key
	mov	es:[di].TE_key, bx
	mov	es:[si].TE_key, ax

	; swap item field of TableEntry

	mov	ax, es:[di].TE_item
	mov	bx, es:[si].TE_item
	mov	es:[di].TE_item, bx
	mov	es:[si].TE_item, ax

	pop	bx
else
	push	si, di, cx
	mov	cx, (size TableEntry)
xchgLoop:
	mov	al, es:[di]
	xchg	al, es:[si]
	stosb				; es:[di] <- al, di++
	inc	si
	loop	xchgLoop
	pop	si, di, cx
endif
	ret
SwapEntries	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareUsingSortOptionNoCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two strings using sort option.

CALLED BY:	CompareKeys, CompareName, ComparePhoneticName

PASS:		ds:si - ptr to string #1
		es:di - ptr to string #2
		cx - maximum # of chars to compare (0 for NULL-terminated)

RETURN:		flags - Below/Equal(je)/Above.
			if string1 =  string2 : if (z)
			if string1 != string2 : if !(z)
			if string1 >  string2 : if !(c|z)
			if string1 <  string2 : if (c)
			if string1 >= string2 : if !(c)
			if string1 <= string2 : if (c|z)

DESTROYED:	none	

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareUsingSortOptionNoCase	proc	near

	; check to see which sorting option is selected

	test	ds:[gmb.GMB_sortOption], mask SF_IGNORE_SPACE 
	je	space				

	call	LocalCmpStringsNoSpaceCase
	jmp	exit
space:
	call	LocalCmpStringsNoCase
exit:
	ret
CompareUsingSortOptionNoCase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSortOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the sorting option from sort option DB.

CALLED BY:	(INTERNAL) ResortDatabase

PASS:		nothing

RETURN:		gmb.GMB_sortOption - updated

DESTROYED:	ax, bx, cx, dx, bp, di

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSortOption	proc	near

	; assume "Ignore space and punctuation" option

	mov	cl, mask SF_IGNORE_SPACE

	; check to see which sorting option is selected

	push	cx
	GetResourceHandleNS	SortOptionList, bx
	mov	si, offset SortOptionList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx

	; "Don't ignore space and punctuation" option set?

	tst	ax				
	jne	exit				; if so, skip
	mov	cl, mask SF_DONT_IGNORE_SPACE	; set the right flag
exit:
	mov	ds:[gmb.GMB_sortOption], cl	; update gmb.GMB_sortOption
	ret
GetSortOption	endp


if PZ_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPhoneticName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the contents of phonetic field into 'sortPhoneticBuf'.

CALLED BY:	UTILITY

PASS:		si - handle of current record

RETURN:		sortPhoneticBuf - constains the sort field

DESTROYED:	cx, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none.almost copied from GetLastName()

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	owa	9/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPhoneticName	proc	far
	push	si			; save current record handle
	mov	di, si			; di - current record handle
	call	DBLockNO		; open up current record
	mov	si, es:[di]		; si - ptr to beg of record data
	mov	cx, es:[si].DBR_phoneticSize  ; cx - length of index field
	tst	cx			; is phonetic field empty?
	je	emptyIndex		; if so, skip to handle it
	add	si, es:[si].DBR_toPhonetic; si - ptr to phonetic field
	push	es, ds
	segmov	ds, es			; ds - source block
	pop	es			; es - destination block
	push	es
	mov	di, offset sortPhoneticBuf; di - offset to dest. buffer
	rep	movsb			; move data
	pop	es, ds			; restore segment registers
unlock:
	call	DBUnlock
	pop	si			; restore current record handle
	ret
emptyIndex:
	LocalClrChar	ds:[sortPhoneticBuf]
					; null terminate the buffer
	jmp	short 	unlock		; skip to unlock 
GetPhoneticName	endp
endif


if PZ_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPizzaLexicalValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get Pizza Lexical Value according to letterTabType

CALLED BY:	Global

PASS:		ax - a character

RETURN:		ax - a pizza lexical value (letter tab)

DESTROYED:	nothing

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	owa	 9/92		Initial revision
	grisco	 6/10/94	Rewrote w/table encoding

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlphaToTabEntry	struct
	ATTE_lastInRange	word
	ATTE_tabValue		word
AlphaToTabEntry	ends

alphaToTabTable	AlphaToTabEntry	\
<0x40,				C_ASTERISK				>,
<C_LATIN_CAPITAL_LETTER_Z,	C_FULLWIDTH_LATIN_CAPITAL_LETTER_A	>,
<0x60,				C_ASTERISK				>,
<C_LATIN_SMALL_LETTER_Z,	C_FULLWIDTH_LATIN_CAPITAL_LETTER_A	>,
<0x3040,			C_ASTERISK				>,
<C_HIRAGANA_LETTER_O,		C_HIRAGANA_LETTER_A			>,
<C_HIRAGANA_LETTER_GO,		C_HIRAGANA_LETTER_KA			>,
<C_HIRAGANA_LETTER_ZO,		C_HIRAGANA_LETTER_SA			>,
<C_HIRAGANA_LETTER_DO,		C_HIRAGANA_LETTER_TA			>,
<C_HIRAGANA_LETTER_NO,		C_HIRAGANA_LETTER_NA			>,
<C_HIRAGANA_LETTER_PO,		C_HIRAGANA_LETTER_HA			>,
<C_HIRAGANA_LETTER_MO,		C_HIRAGANA_LETTER_MA			>,
<C_HIRAGANA_LETTER_YO,		C_HIRAGANA_LETTER_YA			>,
<C_HIRAGANA_LETTER_RO,		C_HIRAGANA_LETTER_RA			>,
<C_HIRAGANA_LETTER_N,		C_HIRAGANA_LETTER_WA			>,
<0x30A0,			C_ASTERISK				>,
<C_KATAKANA_LETTER_O,		C_HIRAGANA_LETTER_A			>,
<C_KATAKANA_LETTER_GO,		C_HIRAGANA_LETTER_KA			>,
<C_KATAKANA_LETTER_ZO,		C_HIRAGANA_LETTER_SA			>,
<C_KATAKANA_LETTER_DO,		C_HIRAGANA_LETTER_TA			>,
<C_KATAKANA_LETTER_NO,		C_HIRAGANA_LETTER_NA			>,
<C_KATAKANA_LETTER_PO,		C_HIRAGANA_LETTER_HA			>,
<C_KATAKANA_LETTER_MO,		C_HIRAGANA_LETTER_MA			>,
<C_KATAKANA_LETTER_YO,		C_HIRAGANA_LETTER_YA			>,
<C_KATAKANA_LETTER_RO,		C_HIRAGANA_LETTER_RA			>,
<C_KATAKANA_LETTER_N,		C_HIRAGANA_LETTER_WA			>,
<C_FULLWIDTH_COMMERCIAL_AT,	C_ASTERISK				>,
<C_FULLWIDTH_LATIN_CAPITAL_LETTER_Z,	C_FULLWIDTH_LATIN_CAPITAL_LETTER_A>,
<C_FULLWIDTH_SPACING_GRAVE, 		C_ASTERISK			>,
<C_FULLWIDTH_LATIN_SMALL_LETTER_Z,	C_FULLWIDTH_LATIN_CAPITAL_LETTER_A>,
<0xFF65,				C_ASTERISK			>,
<C_HALFWIDTH_KATAKANA_LETTER_WO,	C_HIRAGANA_LETTER_WA		>,
<C_HALFWIDTH_KATAKANA_LETTER_SMALL_O, 	C_HIRAGANA_LETTER_A		>,
<C_HALFWIDTH_KATAKANA_LETTER_SMALL_YO,	C_HIRAGANA_LETTER_YA		>,
<C_HALFWIDTH_KATAKANA_LETTER_SMALL_TU,	C_HIRAGANA_LETTER_TA		>,
<C_HALFWIDTH_KATAKANA_HIRAGANA_PROLONGED_SOUND_MARK, C_ASTERISK		>,
<C_HALFWIDTH_KATAKANA_LETTER_O,		C_HIRAGANA_LETTER_A		>,
<C_HALFWIDTH_KATAKANA_LETTER_KO,	C_HIRAGANA_LETTER_KA		>,
<C_HALFWIDTH_KATAKANA_LETTER_SO,	C_HIRAGANA_LETTER_SA		>,
<C_HALFWIDTH_KATAKANA_LETTER_TO,	C_HIRAGANA_LETTER_TA		>,
<C_HALFWIDTH_KATAKANA_LETTER_NO,	C_HIRAGANA_LETTER_NA		>,
<C_HALFWIDTH_KATAKANA_LETTER_HO,	C_HIRAGANA_LETTER_HA		>,
<C_HALFWIDTH_KATAKANA_LETTER_MO,	C_HIRAGANA_LETTER_MA		>,
<C_HALFWIDTH_KATAKANA_LETTER_YO,	C_HIRAGANA_LETTER_YA		>,
<C_HALFWIDTH_KATAKANA_LETTER_RO,	C_HIRAGANA_LETTER_RA		>,
<C_HALFWIDTH_KATAKANA_LETTER_N,		C_HIRAGANA_LETTER_WA		>,
<0xFFFF,				C_ASTERISK			>

GetPizzaLexicalValue	 proc	far
	call	GetPizzaLexicalValueNear
	ret
GetPizzaLexicalValue	 endp

GetPizzaLexicalValueNear	 proc	near
	uses si
	.enter

	clr	si				;beginning of table
searchLoop:
	cmp	ax, cs:alphaToTabTable[si].ATTE_lastInRange
	jbe	foundTab			;it's in this range
	add	si, size AlphaToTabEntry	;next range
	jmp	searchLoop
foundTab:
	mov	ax, cs:alphaToTabTable[si].ATTE_tabValue

	.leave
	ret
GetPizzaLexicalValueNear	 endp
endif

CommonCode	ends
