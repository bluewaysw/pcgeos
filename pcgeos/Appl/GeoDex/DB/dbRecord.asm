COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoDex/Database
FILE:		dbRecord.asm

AUTHOR:		Ted H. Kim

ROUTINES:
	Name			Description
	----			-----------
	BinarySearch		Performs binary search on main table
	CompareKeys		Compares the key field of two records
	CompareName		Compares the index field of two records
	DeleteFromMainTable	Remove a record from the main table
	InsertRecord		Insert a new record into the database file
	InitRecord		Reads in text strings from text objects
	InitPhone               Initializes phone entries
	CopyPhone               Copies old phone numbers into new record
	GetRecord		Gets text strings into several temp blocks
        InsertIntoMainTable	Inserts new record into main table
	FindLetter		Finds and displays the record for a given tab
	FindEntryInCurTab	Finds record handle for a given letter tab ID 
	ClearRecord		Clears all of the text edit fields 
	ClearTextFields		Clears given number of text edit fields
	ComparePhoneticName	Compares the phonetic field of two records
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	8/29/89		Initial revision
	ted	3/3/92		Complete restructuring for 2.0
	witt	2/7/94		Added sort mangling for Pizza/J

DESCRIPTION:

	This file contains various record level routines for managing database.

	The term "sort mangling" refers to changing the first letter of
	the 'sortBuffer' and each key to perform comparisons.  For instance,
	if you wanted the letters to appear in reverse order, you would
	write a routine that does:
		if( chr is alpha), chr = 'Z' - toupper(chr).
	This mangled value is then feed to the LocalCompareStringNoCase
	function.  Since the mangled letter is used only for comparisions,
	the 'toupper' trick above will work.  Only the first char needs
	mangling.
	    *****  To sure the letter tabs follow this order  *****


	$Id: dbRecord.asm,v 1.1 97/04/04 15:49:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BinarySearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs binary search on main table.  Returns a matching
		TableEntry pointer that points into the card database.

****************************************************************************
Here is an overview of how GeoDex (Pizza) sorts its entries:

A is the entry to be inserted.  L[] is the array of existing entries.

1.
--
To decide if A is < or > than L[x], GeoDex first compares the tabs
under which A and L[x] lie.  The tabs are ordered as such:

A
KA
SA
TA
NA
HA
MA
YA
RA
WA
Roman A	- any index beginning with Roman chars
*	- anything else, including all Kanji & punctuation

For example, index fields beginning with the following chars would
fall under the 'SA' tab and would be considered equal by the previous 
KeyCompare:  {hiragana sa,si,su,se,so; katakana sa, si, su, se,so, 
and katakana halfwidth sa, si, su, se, so}.

2.
--
If A and L[x] fall under the same tab, then GeoDex compares the index 
fields (SJIS order), treating halfwidth and fullwidth characters as 
the same.  For example, halfwidth si would be greater than fullwidth 
sa, but halfwidth si and fullwidth si would be considered equal.
Using SJIS order, all hiragana characters that fall under the 'SA' 
tab will come before any of the katakana half or fullwidth characters.
Only the first two chars of the index fields are compared.

3.
--
If the index fields of A and L[x] are found to be equal in (2), then 
the last check is of the Phonetic Fields.  This check follows the 
same rules as the index compare (SJIS order, no difference between 
halfwidth and fullwidth), but the full length of these fields are 
compared.

4.
--
If the phonetic fields are equal, then A is found to be less than 
L[x] and will be inserted directly before L[x].

5.
--
For non-Pizza, The tabs are the letters A-Z and each record is
mapped to one of these tabs.  Each TableEntry contains the tab
(so we don't have to lock the entire DBRecord for the initial
check).  If the tabs are equal, then the entire Index fields
are compared (ascii order).
****************************************************************************

CALLED BY:	UTILITY

PASS:		ds - dgroup
		ds:sortBuffer - key
		cx - number of entries in table
		es:si - points to the beginning of table to search for

		if PZ_PCGEOS (GEOS/J)
			ds:phoneticBuf - 2nd key

RETURN:		es:si - offset into the table to insert or delete
		dx - offset to the end of table
		carry set if es:si is equal to the key in sortBuffer

DESTROYED:	bx, cx, di

PSEUDO CODE/STRATEGY:
	size = number of entries * (size TableEntry)
	bottom = size + top
loop1:
	middle =  (size / 2) + top
	while top != middle
		compare passed key to table key
		if greater
compare:
			if middle = bottom exit
			else middle = middle + (size TableEntry)
			     top = middle
			     if top = bottom exit
			     else go to loop1
		if less
loop3:		
			if middle = top exit
			else middle = middle - (size TableEntry)
			     bottom = middle
			     if top = bottom exit
			     else go to loop1
		if equal
			compare secondary key
			if greater go to compare
			if less go to lopp3
			if equal, exit


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/29/89		Initial version
	Ted	9/19/89		Now comparsions are done in upper cases
	Ted	3/28/90		The 1st two letters of index are already in CAPS
	witt	2/3/94		Works with 6 byte DBCS TableEntry size
	witt	2/7/94		Pizza specific sort mangling

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BinarySearch	proc	near

	top		local	word	; ptr to top of current search area
	middle		local	word	; ptr to middle of current search area
	bottom		local	word	; ptr to bottom of current search area
	endPtr		local	word	; ptr to the end of 'gmb.GMB_mainTable'
	
	.enter

	; initialize local variables

	mov	top, si			; save pointer to top entry  
	mov	middle, si		; initially middle = top
	TableEntryIndexToOffset  cx	; cx - size
	add	si, cx			; si - points to the bottom of table

	; the difference between 'bottom' and 'endPtr' is that 'endPtr' 
	; is pointing to the end of table all the time, whereas 'bottom'
	; moves around as we keep halving the size of area to be searched.

	mov	endPtr, si			
	mov	bottom, si		

	tst_clc	cx			; empty table?
	LONG	je	exit		; exit if so
mainLoop:
	; calculate 'middle' where middle =  (size / 2) + top.
	;	cx = record offset

	mov	si, top
	shr	cx, 1				; divided in half
	TableEntryOffsetMask	cx ; make sure the result be in multiples of 4
	add	si, cx		; si - middle

	cmp	si, endPtr	; is middle = end?
	jne	compare		; if not, skip

	; because I eliminate the middle entry from the search list 
	; on the next iteration, it is possible that the new list will
	; contain only one item and have size value (= bottom - top) of
	; sizeof(TableRecord).
	; In this case, new middle value will be pointing at bottom,
	; which is illegal.  So following adjustment is necessary.

	sub	si, cx		; restore middle value

	; compare the middle entry. if greater,
	; check bottom half of the table.  if less, top half 
compare:
	mov	middle, si		; we have new value for 'middle'
	call	CompareKeys		; compare the key fields
	je	equal			; if equal, check entire index field
	ja	greater

	; search the top half of the table
less:					
	mov	si, middle
	cmp	si, top			; middle = top?
	je	specialCase		; if so, exit

	; we don't have to include the entry pointed to by 'middle'
	; in this search because it has already been compared

	sub	si, size TableEntry	
	mov	bottom, si		; si - new bottom
	cmp	top, si			; is bottom >= top?
	jae	specialCase		; if so, exit 
	jmp	mainLoop		; if not, continue...

	; search the bottom half of the table
greater:
	mov	si, middle
	cmp	si, bottom		; is middle = bottom?
	je	specialCase		; if so, exit

	; we don't have to include the entry pointed to by 'middle'
	; in this search because it has already been compared

	add	si, size TableEntry	
	mov	top, si			; si - new top
	mov	di, bottom
	cmp	top, di			; bottom >= top?
	jae	specialCase		; if so, exit
	sub 	di, top			; di = bottom - top
	mov	cx, di			; cx = new size
	jmp	mainLoop		; continue searching

	; primary key fields match, now compare the entire index field
equal:
	mov	bx, ds:[curRecord]	; bx - current record handle
	cmp	bx, es:[si].TE_item	; compare DB item handles 
	je	exit			; if equal, exit

	; compare the entire index field

	call	CompareName

PZ <	jnz	endCompare		; if not equal, go ahead	>
PZ <	call	ComparePhoneticName	; compare phonetic fields	>
PZ <endCompare:								>

	ja	greater			; if greater, check bottom half
	jb	less			; if less, check top half
	stc				; flag equality
	jmp	exit

	; since the entry pointed to by "middle" gets eliminated
	; on the next iteration from the current search area,
	; it is possible that the record being compared can be less
	; than "middle"(which no longer is in the list) but greater 
	; than the last item in the new search list. (This is assuming
	; the case where the top half of the table is selected
	; for the next iteration of search.)  In this case,
	; the pointer has to be pushed down one entry and point 
	; to previous "middle", so the deletion or insertion can
	; be performed properly.

	; most likely there will be only one entry in the current 
	; search area.  What we are trying to do here is to figure
	; out whether the offset to insert at and delete from is 
	; the current one or the one entry after

specialCase:
	cmp	si, endPtr		; is it pointing to the last entry?
	je	exit			; if so, exit (carry clear)

	call	CompareKeys		; compare the key fields
	jb	exitNotEqual		; if less, no need for adjustment
	ja	adjust			; if greater, adjust the offset

	mov	bx, ds:[curRecord]	; bx - current record item number
	cmp	bx, es:[si].TE_item	; compare the item numbers 
	je	exit			; if equal, exit
	call	CompareName		; compare the sort fields

PZ <	jnz	endCompare2		; if not equal, go ahead	>
PZ <	call	ComparePhoneticName	; compare the phonetic fields	>
PZ <endCompare2:							>

	jb 	exitNotEqual		; if not greater, no need for adjustment
	ja	adjust			; if greater, adjust the offset
	stc				; flag equal (XXX: will this ever?)
	jmp	exit
adjust:
	add	si, size TableEntry	; move the pointer to next entry

exitNotEqual:
	clc				; flag es:si != sortBuffer
exit:
	mov	dx, endPtr

	.leave
	ret
BinarySearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareKeys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two key strings using localization driver.

CALLED BY:	BinarySearch, FindEntryInCurTab

PASS:		es:si - pointer to TableEntry with key string2 to compare
		ds:sortBuffer - pointer to key string1 to compare
		ds:curLetterLen - char count for string comparison
		ds - dgroup

RETURN:		flags set with the results of compare (Less,Equal,Greater)

DESTROYED:	nothing

STRATEGIES/A.S.N.:
		Compare characters in key (doesn't require MemLock).
		If equal, call CompareName for complete index string
			comparison (needs MemLock).
		Return results of compare.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Changes ds:keyBuffer.
	ds:sortBuffer should be sort mangled.  This routine handles
		any sort mangling for the record.  Restores when done.
		In case of Pizza, first letters in sortBuffer is mangled.
		(e.g. C_HIRAGANA_LETTER_I -> C_HIRAGANA_LETTER_A)
	For this routine, when is 'curLetterLen' greater than 2?  There
		is warning because DBCS section has not been converted.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/11/91		Initial version
	witt	2/7/94		DBCS conversion

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareKeys	proc	near
	uses	ax, cx, si, di, es
	.enter

	cmp	ds:[curLetterLen], (length TE_key)  ; two or less letters?
	jg	long			; if not, skip

if DBCS_PCGEOS
	mov	ax, {wchar} es:[si].TE_key[0]	; first wchar
	mov	{wchar} ds:[keyBuffer], ax
	mov	ax, {wchar} es:[si].TE_key[2]	; second wchar
	mov	{wchar} ds:[keyBuffer][2], ax
else
	mov	ax, es:[si].TE_key	; ax - key string2
	mov	ds:[keyBuffer], ah
	mov	ds:[keyBuffer+1], al	; store it in a temp buffer
endif

	segmov	es, ds
	mov	si, offset sortBuffer	; ds:si - ptr to key string1
	mov	di, offset keyBuffer	; es:di - ptr to key string2
	mov	cx, ds:[curLetterLen]	; cx - # of chars to compare

if PZ_PCGEOS
	mov	ax, {wchar} ds:[si]
	call    GetPizzaLexicalValueNear
	cmp     ax, {wchar} es:[di]     ; compare Tabs	
else
	call	CompareUsingSortOptionNoCase	; compare the strings
endif
	jmp	done			; exit with flags set

long:
DBCS <	WARNING  COMPARE_KEYS_LONG					>
	mov	di, es:[si].TE_item	
	call	DBLockNO		; lock this record chunk
	mov	di, es:[di]		; di - offset to record data
	add	di, size DB_Record	; es:di - ptr to index field
	mov	si, offset sortBuffer	; ds:si - ptr to sort buffer
	mov	cx, ds:[curLetterLen]	; cx - # of chars to compare
	call	CompareUsingSortOptionNoCase	; compare two strings
	pushf				; save flags
	call	DBUnlock		; unlock this block
	popf				; restore flags
done:
	.leave
	ret
CompareKeys	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares the sort fields of two records that have same
		first two characters.

CALLED BY:	BinarySearch, LinearSearch

PASS:		es:si - points to the entry in main table to be compared 
		sortBuffer - contains sort field of record to compare

RETURN:		zero flag and carry flag are set to reflect the result
		of comparison

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		ds:sortBuffer should be sort mangled.  This routine handles
		any sort mangling for the record.  Restores when done.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	9/6/89		Initial version
	Ted	9/19/89		Now handles lower and upper cases
	witt	2/7/94		Pizza specific sort mangling

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareName	proc	near	uses	ax, cx, si, di, es, bp
	.enter
	mov	di, es:[si].TE_item	; di - item number
	call	DBLockNO		; lock this record chunk
	mov	di, es:[di]		; di - offset to record data
	add	di, size DB_Record	; es:di - ptr to index field
	mov	si, offset sortBuffer	; ds:si - ptr to 'sortBuffer'

	clr	cx			; strings are null terminated
	call	CompareUsingSortOptionNoCase	; compare two strings

	call	DBUnlock		; (preserves flags)
	.leave
	ret
CompareName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteFromMainTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the current record from main table.

CALLED BY:	UTILITY

PASS:		ds - segment of core block
		curRecord - record handle to delete
		sortBuffer - index field text of current record

RETURN:		gmb.GMB_numMainTab is updated		
		the record item itself continues to live, just not in the
			main table

DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
	Locate the record handle from main table
	Move the data below this entry up four bytes
	Decrement the counter for main table

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	8/29/89		Initial version
	ted	12/4/89		Added checks for non-alphabetical record

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteFromMainTable	proc	far

	; do some extra work if we have the index name list up

	cmp	ds:[displayStatus], CARD_VIEW	; is car view only?
	je	skip			; if so, skip
	call	DeleteFromNameList	; delete from name list
skip:
	mov	dx, ds:[curOffset]	; dx - offset to record to delete 
	mov	cx, size TableEntry	; cx - size of table entry
	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table
	call	DBLockNO
	mov	si, es:[di]		; es:si - points to beg of main table
	add	si, dx
	mov	ax, es:[si].TE_key	; ax - 1st two letters of last name
	call	DBUnlock

	; delete this entry from the main table

	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table
	call	DBDeleteAtNO		; delete this record entry

	; update proper number of entry variables

	call	CheckForNonAlpha	; was this non-alphabetic record?
	jnc	alpha			; if not, skip
	dec	ds:[gmb.GMB_numNonAlpha]	; update number of non-alpha records 
	jmp	short	exit
alpha:
	sub	ds:[gmb.GMB_offsetToNonAlpha], size TableEntry	; update offset
exit:
	dec	ds:[gmb.GMB_numMainTab]		; decrement the main table counter

	call	MarkMapDirty		; mark the map block dirty

	tst	ds:[gmb.GMB_numMainTab]		; is database empty?
	jne	quit			; if not, skip

	; if the database is empty, disable some menus   
	
	GetResourceHandleNS	MenuResource, bx  
	mov	si, offset EditCopyRecord ; bx:si - OD of copy record menu
	call	DisableObject		; disable copy record menu 
	mov	si, offset RolPrintControl ; bx:si - OD of print menu
	call	DisableObject		; disable print menu
	mov	si, offset SortOptions	; bx:si - OD of Sorting Options menu
	call	DisableObject		; disable sort options menu 


quit:
	sub	ds:[gmb.GMB_endOffset], size TableEntry	; update GMB_endOffset
EC <	mov	cx, ds:[gmb.GMB_numMainTab]	; cx - # of entries in table>
EC <	TableEntryIndexToOffset  cx					>
EC <	cmp	cx, ds:[gmb.GMB_endOffset]	; this should be equal	>
EC <	ERROR_NE  CORRUPTED_DATA_FILE					>
	ret
DeleteFromMainTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inserts current record into database file. 

CALLED BY:	UTILITY

PASS:		ds - segment of core block
			curRecord, gmb.GMB_curPhoneIndex, displayStatus
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/7/89		Initial version
	ted	12/5/89		Doesn't create the new record

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertRecord	proc	far
	mov	di, ds:[curRecord]	; di - current record handle
	call	DBLockNO
	mov	di, es:[di]		; open it
	mov	dx, ds:[gmb.GMB_curPhoneIndex]	; dx - current phone number counter 
	mov	es:[di].DBR_phoneDisp, dl	; save it 
EC <	cmp	es:[di].DBR_noPhoneNo, dx			>
EC <	ERROR_LE  IN_INSERT_RECORD_WITH_PHONE_COUNT		>

	call	DBUnlock		; close it

	mov	si, ds:[curRecord]	; si - current record handle
	call	GetLastName		; read in index field into sortBuffer
PZ <	call	GetPhoneticName		; read phonetic into sortPhoneticBuf>
	call	InsertIntoMainTable	; insert record into main table
	cmp	ds:[displayStatus], CARD_VIEW	; is card view up?
	je	exit			; if so, skip
	call	AddToNameList		; insert the name to name list
exit:
	andnf	ds:[recStatus], not mask RSF_NEW ; clear flag
	ret
InsertRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new record entry and initialize it.
		
CALLED BY:	UTILITY

PASS:		ds - segment of core block
		ax - flag to indicate whether to (0) copy everything
		     or (-1) just phone fields

RETURN:		dx - handle of data block
		cx - size of data block
		carry set if error

DESTROYED:	ax, bx, si, di, bp, es 	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitRecord	proc	far

	; allocate a new DB block

	push	ax			; save the flag
	mov	cx, size DB_Record	; cx - size of a new record
	call	DBAllocNO		; allocate a new data record
	mov	ds:[curRecord], di	; save the handle 
	call	DBLockNO		; lock it
	mov	si, es:[di]		; di - pointer to beg. of record data

	; initialize the header 

	clr	es:[si].DBR_notes
	mov	es:[si].DBR_noPhoneNo, NUM_DEFAULT_PHONE_TYPES
	mov	es:[si].DBR_toAddr, size DB_Record
	mov	es:[si].DBR_toPhone, size DB_Record
PZ <	mov	es:[si].DBR_toPhonetic, size DB_Record		>
PZ <	mov	es:[si].DBR_toZip, size DB_Record		>
	clr	es:[si].DBR_indexSize
	clr	es:[si].DBR_addrSize
PZ <	clr	es:[si].DBR_phoneticSize			>
PZ <	clr	es:[si].DBR_zipSize				>
	mov	dx, ds:[gmb.GMB_curPhoneIndex]
	mov	es:[si].DBR_phoneDisp, dl
	call	DBUnlock

	; if this is called by "UNDO" routine, then we need to copy
	; all the phone numbers into this new record.  So that when
	; this old record is deleted or modified again, we can still
	; reproduce all of the phone numbers from old record.

	cmp	ds:[undoAction], UNDO_CHANGE	; was undo pressed?
	jl	noUndo			; if not, skip
	tst	ds:[undoItem]
	jz	noUndo			; can't undo if there's no undo
	call	CopyPhone		; if so, copy over all phone numbers
	jmp	copy			; copy the rest of fields
noUndo:
	call	InitPhone		; initialize the phone # part of record
copy:
	pop	ax			; restore the flag
	tst	ax			; should only phone fields updated?
	js	phone			; if so, skip

	; copy the text strings into DB block

	call	UpdateIndex		; update index field 
	call	UpdateAddr		; update addres field 
	call	UpdateNotes		; update the notes field
PZ <	call	UpdatePhonetic		; update phonetic field		>
PZ <	call	UpdateZip		; update zip field		>

phone:
	test	ds:[dirtyFields], DFF_PHONE	  ; phone field modified?
	je	exit			; if not, exit
	call	UpdatePhone		; update phone number field 
	jmp	short	quit
exit:
	clc
quit:
	ret
InitRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPhone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes phone number entries in a record. Builds
		"NUM_DEFAULT_PHONE_TYPES" phones, all blank.

CALLED BY:	InitRecord

PASS:		curRecord - current record handle

RETURN:		nothing

DESTROYED:	cx, dx, si, di, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	* The index field has not been stored,ie, routine assumes it can
		use memory right after the DB_Record structure.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitPhone	proc	near

	mov	cx, (size PhoneEntry)*NUM_DEFAULT_PHONE_TYPES
					; cx - size of "default" phone entries

	mov	di, ds:[curRecord]	; di - current record handle
	mov	dx, size DB_Record	; dx - offset to insert at
	call	DBInsertAtNO		; make room for phone numbers
	call	DBLockNO		; lock it
	mov	si, es:[di]		; si - pointer to beg. of record data
	add	si, size DB_Record	; si - pointer to beg. of phone #'s
	clr	dx			; initial phone type ID is 1 (really)
clearPhoneLoop:
	inc	dl			; dl <- increment the phone type ID
	clr	es:[si].PE_count	; no calls made yet 
	mov	es:[si].PE_type, dl	; save phone number type
	mov	es:[si].PE_length, 0 	; no phone number 
	add	si, size PhoneEntry	; go to the next entry
	cmp	dl, NUM_DEFAULT_PHONE_TYPES	; are we done initializing?
	jne	clearPhoneLoop		; if not, continue

	call	DBUnlock		; if so, exit
	ret
InitPhone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyPhone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the phone number entries into a new record.   

CALLED BY:	InitRecord

PASS:		ds - dgroup
		ds:[undoItem] - handle of undo record item

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di

PSEUDO CODE/STRATEGY:
	Calculate how many bytes need to be copied
	Make room for the string
	Copy the string into current record

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/8/89		Initial version
	witt	1/21/94  	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyPhone	proc	near
	push	ds			; save seg. address of core block
	mov	di, ds:[undoItem]	; save the record handle in si
	clr	ax			; ax - length of all phone numbers
	clr	bx			; bx - length of all PhoneEntries
	call	DBLockNO
	mov	di, es:[di]		; open up this record
	mov	cx, es:[di].DBR_noPhoneNo	; cx - total phone entries
	add	di, es:[di].DBR_toPhone	; di - pointer to beg. phone entry

moveForwardLoop:
if DBCS_PCGEOS
	mov	dx, es:[di].PE_length
	shl	dx, 1			; dx - phone number size
	add	ax, dx			; ax - total phone number size
	add	di, dx			; di - total record size
else
	add	ax, es:[di].PE_length	; ax - total phone number sizes
	add	di, es:[di].PE_length
endif
	add	bx, size PhoneEntry	; bx - total phone entry length 
	add	di, size PhoneEntry	; di - pointer to the next entry
	loop	moveForwardLoop		; continue...
	call	DBUnlock

	mov	cx, ax
	add	cx, bx			; cx - total number of bytes to add
	mov	di, ds:[curRecord]	; di - handle of record to insert
	mov	dx, size DB_Record	; dx - offset to insert at
	call	DBInsertAtNO		; make room for phone entries

	mov	di, ds:[undoItem]	; di - handle of undone record
	call	DBLockNO
	mov	si, es:[di]		; open it up again
	mov	dx, es:[si].DBR_noPhoneNo ; dx - total number of phone entries
	add	si, es:[si].DBR_toPhone	; si - pointer to beg. of phone entries
	mov	di, ds:[curRecord]	; di - handle of current record
	mov	bx, ds:[fileHandle]	; bx - database file handle
	mov	ax, ds:[groupHandle]	; ax - group handle
	segmov	ds, es			; ds:si - source string
	call	DBLock
	mov	di, es:[di]		; open up current record
	mov	es:[di].DBR_noPhoneNo, dx ; save new total # of phone entries
	add	di, es:[di].DBR_toPhone	; es:di - destination
DBCS<EC< test	cx, 1			; is size odd?		> >
DBCS<EC< ERROR_NZ   SIZE_OF_PHONE_NO_IS_NOT_EVEN		> >
	rep	movsb			; copy the phone entries
	call	DBUnlock
	segmov	es, ds
	call	DBUnlock		; close up records
	pop	ds			; restore seg. address of core block
	ornf	ds:[recStatus], mask RSF_UPDATE	; set update flag
	ret
CopyPhone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads in all the text strings into temporary buffers.

CALLED BY:	UTILITY

PASS:		ds - segment of core block
		cx - number of fields to read in
		di - offset to FieldTable (TEFO_xxx)

RETURN:		ds:fieldHandles - table of handles to data blocks
		ds:fieldLengths - table of lengths for each string

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	Clear empty flags, cuz there is probably something to save.
	For each text edit field 
		read in each text string into a temporary buffer
		if the text field empty
			set the appropriate flag
		else
			save the handle to this buffer
			save the number of chars in each field
	Next field

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If the text field is empty, zero is stored as block handle.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	9/4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRecord	proc	far

	; assume not empty
	; clear field flags - assume none of the text fields is empty
	andnf	ds:[recStatus], not mask RSF_PHONE_NO_EMPTY and \
				not mask RSF_PHONE_EMPTY and \
				not mask RSF_EMPTY
	cmp	cx, 2			; read in phone fields only?
	jg	allFields		; if not, skip

if PZ_PCGEOS
	ornf	ds:[recStatus], mask RSF_SORT_EMPTY or \
				mask RSF_ADDR_EMPTY or \
				mask RSF_NOTE_EMPTY or \
				mask RSF_PHONETIC_EMPTY	or \
				mask RSF_ZIP_EMPTY
else
	ornf	ds:[recStatus], mask RSF_SORT_EMPTY or \
				mask RSF_ADDR_EMPTY or \
				mask RSF_NOTE_EMPTY
endif
	jmp	fieldLoop

allFields:
if PZ_PCGEOS
	andnf	ds:[recStatus], not mask RSF_SORT_EMPTY and \
				not mask RSF_ADDR_EMPTY and \
				not mask RSF_NOTE_EMPTY and \
				not mask RSF_ZIP_EMPTY and \
				not mask RSF_PHONETIC_EMPTY

else
	andnf	ds:[recStatus], not mask RSF_SORT_EMPTY and \
				not mask RSF_ADDR_EMPTY and \
				not mask RSF_NOTE_EMPTY
endif

fieldLoop:	
	push	cx			; save # of text edit fields to examine
	GetResourceHandleNS	Interface, bx   ; get handle of UI block
	cmp	di, TEFO_NOTE		; are we doing NoteText field?	
	jne	notNoteField		; if not, skip
	GetResourceHandleNS	WindowResource, bx   ; get handle of menu block
notNoteField:
	mov	si, ds:FieldTable[di]	; bx:si - OD of text edit object
	call	GetTextInMemBlock	; returns cx - # chars or 0
					; returns ax - handle of mem block
ifdef GPC
	;
	; ignore empty record instructions placed into text fields
	;
	jcxz	textEmpty
	push	ax, cx, di
	mov	ax, MSG_VIS_TEXT_GET_STATE
	mov	di, mask MF_CALL
	call	ObjMessage
	test	cl, mask VTS_EDITABLE
	jnz	textOkay
	pop	bx, cx, di
	call	MemFree			; free invalid text block
	clr	ax, cx			; indicate no text
	jmp	short textEmpty

textOkay:
	pop	ax, cx, di
textEmpty:
endif
	mov	bx, ds:fieldHandles[di] ; bx - handle of text block
	tst	bx			; is there an old text block to delete?
	je	skip			; if not, skip
	call	MemFree			; if so, delete it
	clr	ds:fieldHandles[di]	; clear the handle
skip:
	pop	bx			; bx - # of text edit fields left
	jcxz	empty			; is this field empty? (len==0)

	mov	ds:fieldHandles[di], ax ; save handle of text block

	; cx - number of chars in buffer

	inc	cx			; add one for null terminator
next:
	mov	ds:fieldLengths[di], cx	; save length of string
	add	di, (size nptr)		; di - points to the next field offset
	mov	cx, bx			; cx - # of fields left to examine
	loop	fieldLoop		; on to the next field
	jmp	short	setFlags	; jump to set flags

empty:
	; set the approriate RSF_****_EMPTY flag
	clr	ds:fieldHandles[di]	; clear the handle
	mov	ax, 1		
	mov	cx, bx			; cx - # of fields left to examine
	shl	ax, cl			; ax - mask RSF_****_EMPTY
	or	ds:[recStatus], ax	; set the empty flag for this field
	clr	cx			; cx - length of string 
	jmp	next
	
setFlags:
	test	ds:[recStatus], mask RSF_SORT_EMPTY ; is index empty?
	je	exit			; if not, exit
	test	ds:[recStatus], mask RSF_ADDR_EMPTY ; is addr empty?
	je	exit			; if not, exit
	test	ds:[recStatus], mask RSF_NOTE_EMPTY ; is note empty?
	je	exit			; if not, exit
	test	ds:[recStatus], mask RSF_PHONE_NO_EMPTY ; is phone # emtpy?
	je	exit			; if not, exit
PZ <	test	ds:[recStatus], mask RSF_PHONETIC_EMPTY ; is phonetic emtpy?>
PZ <	je	exit			; if not, exit			>
PZ <	test	ds:[recStatus], mask RSF_ZIP_EMPTY ; is zip emtpy?	>
PZ <	je	exit			; if not, exit			>
	ornf	ds:[recStatus], mask RSF_EMPTY	; if so, record is blank
exit:
	ret
GetRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertIntoMainTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inserts the new record into main table.

CALLED BY:	(INTERNAL) InsertRecord, SaveCurRecord

PASS:		ds - segment addr of core block
		curRecord - handle of new record

RETURN:		gmb.GMB_numMainTab updated

DESTROYED:	ax, bx, cx, dx, es, si, di

PSEUDO CODE/STRATEGY:
	Locate a place to insert the new record
	Move down all the entries below it
	If first char of letter tab is non-alpha, incr non-alpha counter.
	Insert the new record

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/7/89		Initial version
	ted	12/5/89		Added checks for non-alphabetical records
	witt	2/1/94		DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertIntoMainTable	proc	far
DBCS< PrintMessage <InsertIntoMainTable - Adapt for letter pairs> >
if not PZ_PCGEOS
	; since sortBuffer is not the same as Index field on pizza version
	; we can't error check like this.
EC <	mov	di, ds:[curRecord]					>
EC <	call	DBLockNO						>
EC <	mov	di, es:[di]						>
EC <	mov	cx, es:[di].DBR_indexSize				>
EC <	add	di, size DB_Record		; es:di - index field	>
EC <	mov	si, offset sortBuffer		; ds:si - sort buffer	>
EC <	repe	cmpsb							>
EC <	call	DBUnlock						>
EC <	jcxz	noError				; if reached end, then OK >
EC <	ERROR	SORT_BUFFER_IS_NOT_CURRENT				>
EC <noError:								>
endif

	call	FindSortBufInMainTable	; dx <- insertion point w/in main table

	mov	cx, size TableEntry	; cx - number of bytes to move

	; make room for one new entry in 'gmb.GMB_mainTable'

	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of table
	call	DBInsertAtNO		; creates 'cx' bytes

	; store the key and DB handle in 'gmb.GMB_mainTable'

	call	DBLockNO
	mov	si, es:[di]		; open up this data block
	add	si, dx			; si - place to insert the new record
	mov	di, ds:[curRecord]	; di - handle of new record
	mov	es:[si].TE_item, di	; store the new item number
SBCS <	mov	es:[si].TE_key, ax 	; store the first two letters	>
if DBCS_PCGEOS
PZ  <	mov	es:[si].TE_key[0], ax	; store the first letter	>
NPZ <	mov	cx, ds:sortBuffer[0]					>
NPZ <	mov	es:[si].TE_key[0], cx					>
endif
if DBCS_PCGEOS
	mov	cx, ds:sortBuffer[2]
	mov	es:[si].TE_key[2], cx	; store the second letter
	clr	es:[si].TE_unused	; zero unused element
endif
	call	DBUnlock	

	; update number of entry variables
	;	ah/ax = first char in index field

	mov	ds:[curOffset], dx	; is new rec inserted after cur. rec?
	call	CheckForNonAlpha	; was this an alphabetical record?
	jnc	alpha2			; if so, skip
	inc	ds:[gmb.GMB_numNonAlpha]	; update number of non-alpha
	jmp	updateDB
alpha2:
	add	ds:[gmb.GMB_offsetToNonAlpha], (size TableEntry)  ; update offset

updateDB:
	inc	ds:[gmb.GMB_numMainTab]		; increment main table counter
	call	MarkMapDirty			; mark the map block dirty
	cmp	ds:[gmb.GMB_numMainTab], 1	; one entry in database?
	jne	done				; if not, skip

	; if the database was empty before this new entry was inserted
	; enable 'CopyRecord', 'Print', 'Sorting Options' menu.

	GetResourceHandleNS	MenuResource, bx 
	mov	si, offset EditCopyRecord ; bx:si - OD of copy record menu
	call	EnableObject		; enable copy record menu 
	mov	si, offset RolPrintControl ; bx:si - OD of print menu
	call	EnableObject		; enable print menu
	mov	si, offset SortOptions	; bx:si - OD of Sorting Options menu
	call	EnableObject		; enable sort options menu 


done:
	add	ds:[gmb.GMB_endOffset], size TableEntry	; update the ptr to end

EC <	mov	cx, ds:[gmb.GMB_numMainTab]	; cx - # of entries in table>
EC <	TableEntryIndexToOffset  cx					>
EC <	cmp	cx, ds:[gmb.GMB_endOffset]	; this must be equal	>
EC <	ERROR_NE CORRUPTED_DATA_FILE	; if not, send up a flag	>

	ret

InsertIntoMainTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindSortBufInMainTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to find the record whose index field is in
		ds:[sortBuffer]

CALLED BY:	(EXTERNAL) InsertIntoMainTable
PASS:		ds	= dgroup
		sortBuffer	= index for which to search
RETURN:		carry set if found record with identical index field
		carry clear if found insertion point
		dx	= offset into table of found record/insertion point
		cx	= handle of item at that offset
		ax	= key (first two letters of index)
DESTROYED:	di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindSortBufInMainTable proc	far
	.enter
	; 1st two letters of index field is the key field of main table

	mov	di, ds:[gmb.GMB_mainTable]	; di - handle for main table
	call	DBLockNO		; open up the main table
SBCS <	mov	ah, ds:[sortBuffer]	; ax - key to search with	>
SBCS <	mov	al, ds:[sortBuffer+1]					>
DBCS <	mov	ax, {wchar} ds:[sortBuffer]	; one char for DBCS	>
if PZ_PCGEOS
	call    GetPizzaLexicalValueNear ; change key character to alphabet
endif
	; update 'curLetterLen'

if DBCS_PCGEOS
	mov	ds:[curLetterLen], 1	; always 1 in DBCS
else
	mov	ds:[curLetterLen], 2	; assume there are two letters
	tst	al			; second letter exists?
	jne	twoLetter		; if so, skip
	mov	ds:[curLetterLen], 1	; there is only one letter in key
twoLetter:
endif
	mov	si, es:[di]		; es:si - offset to the data
	mov	dx, si		
	push	dx			; save the offset to beg of main table
	mov	cx, ds:[gmb.GMB_numMainTab]	; cx - # records in main table

	; don't have to search if the table is empty

	jcxz	skipSearch		; if main table is empty, skip search

	; figure out which area to search, non-alphabet or alphabet

	add	dx, ds:[gmb.GMB_endOffset] ; dx - offset to end of main table
	call	CheckForNonAlpha	; is this record alphabetical?
	jnc	alpha1			; if so, skip

	add	si, ds:[gmb.GMB_offsetToNonAlpha] ; offset to non-alpha
	mov	cx, ds:[gmb.GMB_numNonAlpha]	; cx - # of non-alpha records
	jmp	search

alpha1:
	sub	cx, ds:[gmb.GMB_numNonAlpha]	; cx - # alphabetical records
search:					; perform the binary search 
	call	BinarySearch		; returns es:si - ptr to insert

	; insert this entry into the database
skipSearch:
	pop	dx			; dx - beg of table
	mov	cx, es:[si].TE_item
	pushf
	sub	si, dx			; si - place to insert
	mov	dx, si			; dx - offset to place to insert
	call	DBUnlock
	popf
	.leave
	ret
FindSortBufInMainTable endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfRecordExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to find the record with passed index field

CALLED BY:	(EXTERNAL) InsertIntoMainTable
PASS:		ds	= dgroup
		es:di	= index
RETURN:		carry set if found record with identical index field
		carry clear if found insertion point
		dx	= offset into table of found record/insertion point
		cx	= handle of item at that offset
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/6/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef GPC
CheckIfRecordExists	proc	far
	uses	ax, bx, si, es, di, bp
	.enter
	;
	; set up curLetterLen and sortBuffer
	;
	call	LocalStringLength
	push	ds:[curLetterLen]	; save this
	mov	ds:[curLetterLen], cx
	push	ds			; save dgroup
	segxchg	ds, es
	mov	si, di			; ds:si = passed search key
	mov	di, offset sortBuffer	; es:di = sortBuffer
	LocalCopyString
	pop	ds			; ds = dgroup
	;
	; access database
	;
	mov	di, ds:[gmb.GMB_mainTable]	; di - handle for main table
	call	DBLockNO		; open up the main table
	mov	si, es:[di]		; es:si - offset to the data
	mov	dx, si		
	push	dx			; save the offset to beg of main table
	mov	cx, ds:[gmb.GMB_numMainTab]	; cx - # records in main table
	jcxz	skipSearch		; if main table is empty, skip search
	;
	; figure out which area to search, non-alphabet or alphabet
	;
	mov	ah, ds:[sortBuffer]
	call	CheckForNonAlpha	; is this record alphabetical?
	jnc	alpha1			; if so, skip
	add	si, ds:[gmb.GMB_offsetToNonAlpha] ; offset to non-alpha
	mov	cx, ds:[gmb.GMB_numNonAlpha]	; cx - # of non-alpha records
	jmp	search

alpha1:
	sub	cx, ds:[gmb.GMB_numNonAlpha]	; cx - # alphabetical records
search:					; perform the binary search 
	push	ds:[curRecord]
	mov	ds:[curRecord], 0	; make sure to search everything
	call	BinarySearch		; returns es:si - ptr to insert
	pop	ds:[curRecord]
	;
	; return search results
	;
skipSearch:
	pop	dx			; dx - beg of table
	mov	cx, es:[si].TE_item
	pushf
	sub	si, dx			; si - place to insert
	mov	dx, si			; dx - offset to place to insert
	call	DBUnlock
	popf
	pop	ds:[curLetterLen]	; restore this
	.leave
	ret
CheckIfRecordExists	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLetter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the handle of the first record in sorted order
		whose first letter in the last name field corresponds
		to the given letter and displays it.

CALLED BY:	(GLOBAL)

PASS:		ds - segment of core block
		dl - letter tab ID 

RETURN:		nothing 

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

PSEUDO CODE/STRATEGY:
		Updates the current record, if modified

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Depends on FindEntryInCurTab to determine "sorted ordering."

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindLetter	proc	far

	class	RolodexClass	

	; update the currently display record if it is modified

	push	dx
	call	SaveCurRecord		
	pop	dx

	test	ds:[recStatus], mask RSF_WARNING ; was warning box up?
	je	start			; if not, skip

	; If the record is not blank and index field is empty, a warning box
	; should have been put up by 'SaveCurRecord'.  If the user click on YES,
	; then exit this routine,  thereby giving the user one more chance
	; to enter data into idnex field.  Otherwise, continue.

	cmp	ax, IC_YES		; was YES selected?
	je	exit			; if so, exit
start:
	tst	ds:[gmb.GMB_numMainTab]		; is database empty?
	je	empty			; if so, skip

	; get the handle of record that should be displayed

	call	FindEntryInCurTab
	tst	si			; no records with this letter tab?
	je	noneFound		; skip if no record

	; display this record

	clr	ds:[recStatus]		; clear all record flags
	ornf	ds:[recStatus], mask RSF_FIND_LETTER
	call	DisplayCurRecord	
	andnf	ds:[searchFlag], not mask SOF_NEW   
	andnf	ds:[recStatus], not mask RSF_FIND_LETTER

	; update the index list if it is enabled 

	cmp	ds:[displayStatus], CARD_VIEW	; is card view only?
	je	skip			; if so, skip
	call	UpdateNameList		; update the name list
skip:
	call	EnableCopyRecord	; enable 'CopyRecord' menu 
	clr	ds:[recStatus]		; clear all record flags
	jmp	quit			; and exit

	; no record to display, just clear the record fields 
noneFound:
ifdef GPC
noRecordCommon	label	far
endif
	call	ClearRecord		; clear text fields
	mov	ds:[recStatus], mask RSF_EMPTY or mask RSF_NEW ; set flags
	clr	ds:[curRecord]		; current record is blank

	cmp	ds:[displayStatus], CARD_VIEW	; is card view only?
	je	empty			; if so, skip
	call	SetNewExclusive		; update the name list
empty:		; do some housekeeping before exiting 
	call	DisableCopyRecord	; disable 'CopyRecord' menu
	call	FocusSortField		; give focus to index field
quit:
	clr	ds:[undoItem]		; no undoable action exists
exit:
	call	DisableUndo		; disable 'undo' menu
	clr	ds:[ignoreInput]	; accept mouse presses
	ret
FindLetter	endm

ifdef GPC
SimulateNoRecord	proc	far
	jmp	noRecordCommon
SimulateNoRecord	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindEntryInCurTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the letter tab ID, it returns the handle of record
		that starts with this letter.  Possible that no letter is
		found, as user could have clicked on a blank.

CALLED BY:	FindLetter, FindNextTabLetterWithEntry,
		FindPrevTabLetterWithEntry

PASS:		dl - letter tab ID (0-based)

RETURN:		si - handle of record that should be displayed 
		si = 0 if no entry under this letter tab

DESTROYED:	bx, cx, si, di, es

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		This routine determines the "search order", if any.
		Uses CompareKeys for equal/not-equal compare.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	6/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindEntryInCurTab	proc	near	uses	ax, dx, bp
	.enter

	; first get the letter tab string for the current tab 

	mov	si, offset MyLetters	; bx:si - OD of MyLetters
	GetResourceHandleNS	MyLetters, bx	
	mov	ax, MSG_LETTERS_GET_TAB_LETTER	
	mov	di, mask MF_FIXUP_DS or mask MF_CALL	
	call	ObjMessage		; inspect string on letter tab.
					; 'sortBuffer' has tab string;
					; 'curLetterLen' has string length.

	tst	ds:[gmb.GMB_numMainTab]		; is database empty?
	je	notFound		; if so, skip

	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table
	call	DBLockNO
	mov	si, es:[di]		; open up the main table

	cmp	ds:[curLetterLen], 1	; tab with only one letter?
	jne	alphabet		; if not, skip
	jb	notFound		; don't search empty letter tabs.

	; if the tab letter string starts with a space character (or NULL)
	; then it is a blank tab.  Just ignore it.

	; WHEN LOCALIZING THESE TABS, MAKE SURE THAT TAB LETTER
	; STRINGS DON'T START WITH A SPACE CHARACTER ted - 3/23/93

	LocalGetChar	ax, ds:[sortBuffer], NO_ADVANCE
	LocalIsNull	ax		; NULL or space => empty
	je	notFound
	LocalCmpChar	ax, ' '
	je	notFound

	LocalCmpChar	ax, '*' 	; is it '*'?  (wildcard)
	jne	alphabet		; if not, skip

	; the current entry is the "wildcard" entry

	mov	cx, ds:[gmb.GMB_offsetToNonAlpha]  ; cx - offset to 1st non-alpha
	mov	ds:[curOffset], cx	; save the offset
	tst	ds:[gmb.GMB_numNonAlpha]; are there any records under '*'?
	je	notFound		; if none, skip

	add	si, cx			; si - ptr to 1st non-alpha entry
	mov	si, es:[si].TE_item	; si - record handle
	jmp	exit			; display this record

alphabet:
	mov	cx, ds:[gmb.GMB_numMainTab]	; cx - number of records in main table
	sub	cx, ds:[gmb.GMB_numNonAlpha]	; cx - # of alphabetical entries

	; search the gmb.GMB_mainTable to find the handle of record that matches
	; the given letter tab string

	push	si			; save the ptr to the beg of main table
	push	ds:[curRecord]
	clr	ds:[curRecord]

PZ <	; We have to clear sortPhoneticBuf since LetterTab does not	>
PZ <	; have phonetic field.						>
PZ <	mov	di, offset sortPhoneticBuf				>
PZ <	LocalClrChar	ds:[di]		; clr sortPhoneticBuf		>

	call	BinarySearch		; letter tabs always in ASCII order
					; es:si - ptr to the entry found
	pop	ds:[curRecord]
	pop	bp			; bp - ptr to the beg. of main table

	; update the variable 'curOffset'

	mov	cx, si			; cx - ptr to the current record 
	sub	cx, bp			; cx - offset to current record 
	mov	ds:[curOffset], cx	; save the offset

	cmp	si, dx			; is it the last entry?
	je	notFound		; if so, no match

	; make sure we have found the right entry

	call	CompareKeys
	mov	si, es:[si].TE_item	; si - record handle (assume OK)
	je	exit			; skip if record with this lettter
notFound:
	clr	si			; no record found  :-(
exit:
	call	DBUnlock		; close main table

	.leave
	ret
FindEntryInCurTab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears all the text edit fields and display 'HOME' for
		phone number type name.

CALLED BY:	UTILITY

PASS:		ds - segment addr of core block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	Clear all of the text edit fields
	Display phone type name as "HOME"
	Set the flag

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Setting the initial gmb.GMB_curPhoneIndex and curPhoneType is very touche!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	9/21/89		Initial version
	witt	1/31/94 	Use symbolc constants instead of numbers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearRecord	proc	far
	mov	cx, NUM_TEXT_EDIT_FIELDS+1  ; cx - number text fields to clear
	clr	si			; si - points to table of field handles 
	mov	ds:[curPhoneType], PTI_HOME
	mov	ds:[gmb.GMB_curPhoneIndex], 1
	call	ClearTextFields		; clear all the text edit fields

	call	DisplayPhoneType	; display phone number type name

	; enable phone number scroll icons

	mov	si, offset ScrollUpTrigger	; bx:si - OD of down button
	GetResourceHandleNS	ScrollUpTrigger, bx
	call	EnableObject	; enable phone up button
	mov	si, offset ScrollDownTrigger	; bx:si - OD of down button
	call	EnableObject			; enable phone down button
	ornf	ds:[recStatus], mask RSF_EMPTY	; set the record empty flag

ifdef GPC
	call	ClearPhoneNumbers
	call	DisableRecords
endif

	ret
ClearRecord	endp

ifdef GPC
ClearPhoneNumbers	proc	near
	uses	ax, bx, cx, dx, si, di, bp
	.enter
	;
	; clear number field
	;
	mov	cx, length clearPhoneNumFields
	clr	di
	GetResourceHandleNS	Interface, bx
clearLoop:
	push	di, cx
	mov	si, cs:clearPhoneNumFields[di]
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di, cx
	add	di, size lptr
	loop	clearLoop
	;
	; set default phone names
	;
	mov	cx, length clearPhoneNameFields
	clr	di
	GetResourceHandleNS	Interface, bx
setLoop:
	push	di, cx
	mov	si, cs:clearPhoneNameFields[di]
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	GetResourceHandleNS	TextResource, dx
	mov	bp, cs:clearPhoneNameStrings[di]
	clr	cx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di, cx
	add	di, size lptr
	loop	setLoop
	.leave
	ret
ClearPhoneNumbers	endp

clearPhoneNumFields	lptr \
	offset	Interface:StaticPhoneOneNumber,
	offset	Interface:StaticPhoneTwoNumber,
	offset	Interface:StaticPhoneThreeNumber,
	offset	Interface:StaticPhoneFourNumber,
	offset	Interface:StaticPhoneFiveNumber,
	offset	Interface:StaticPhoneSixNumber,
	offset	Interface:StaticPhoneSevenNumber,
	offset	Interface:StaticPhoneSevenName

clearPhoneNameFields	lptr \
	offset	Interface:StaticPhoneOneName,
	offset	Interface:StaticPhoneTwoName,
	offset	Interface:StaticPhoneThreeName,
	offset	Interface:StaticPhoneFourName,
	offset	Interface:StaticPhoneFiveName,
	offset	Interface:StaticPhoneSixName

clearPhoneNameStrings	lptr \
	offset	TextResource:PhoneHomeDisplayString,
	offset	TextResource:PhoneWorkDisplayString,
	offset	TextResource:PhoneCarDisplayString,
	offset	TextResource:PhoneFaxDisplayString,
	offset	TextResource:PhonePagerDisplayString,
	offset	TextResource:PhoneEmailDisplayString

.assert (length clearPhoneNameFields) eq (length clearPhoneNameStrings)
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearTextFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears all of the text edit fields.

CALLED BY:	UTILITY

PASS:		ds - segment addr of core block
		cx - number of edit fields to clear
		si - offset into FieldTable (word aligned)

RETURN:		recStatus set accordingly

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	For each text edit field
		Display empty text string
		Clear the dirty bit
		Set the corresponding flag
		Advance SI to next text string ptr
	Next text edit field

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearTextFields		proc	far
ifdef GPC
	tst	si
	jnz	leavePhoneNumbers
	call	ClearPhoneNumbers
leavePhoneNumbers:
endif
mainLoop:
	push	cx			; cx - number of text fields to clear
	mov	dx, ds			
	mov	bp, offset noText	; dx:bp - points to string to display
	push	si			; save offset to FieldTable
	clr	cx			; string is null terminated

	; load BX with the correct resource handle

	GetResourceHandleNS	Interface, bx
	cmp	si, TEFO_NOTE		; is this notes field?
	jne	notNotes		; if not, skip
	GetResourceHandleNS	WindowResource, bx

notNotes:
	mov	si, ds:FieldTable[si]	; bx:si - OD of text object
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; display the text string
	pop	si			; restore offset to FieldTable
	add	si, (size nptr)		; update to the next text edit field
	pop	cx			; restore number of fields 

	; set the RSF_***_EMPTY flag

	mov	ax, 1
	shl	ax, cl			; ax - mask RSF_***_EMPTY
	or	ds:[recStatus], ax	; set the corresponding flag
	loop	mainLoop		; continue if not done
	ret
ClearTextFields		endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearTextFieldsSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears selection in all text edit fields.

CALLED BY:	UTILITY

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearTextFieldsSelection		proc	far	uses	di, si
	.enter

	; loop through all of the text fields, clearing the selection in each

	clr	si
	mov	cx, NUM_TEXT_EDIT_FIELDS + 1

	; clear selection in a single text object
clearLoop:
	push	cx, si
	GetResourceHandleNS     Interface, bx   
	cmp	si, 4			; is this notes field?
	jne	notNotes		; if not, skip
	GetResourceHandleNS     WindowResource, bx   
notNotes:
	mov     si, ds:FieldTable[si]   ; bx:si - OD of text object
	mov     ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	clr	cx, dx
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage              ; display the text string
	pop	cx, si
	add	si, 2			; update to the next text edit field
	loop	clearLoop

	.leave
	ret
ClearTextFieldsSelection	endp	


if PZ_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComparePhoneticName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares the sort fields of two records that have same
		index fields.

CALLED BY:	BinarySearch

PASS:		es:si - points to the entry in main table to be compared 
		sortPhoneticBuf - contains sort field of record to compare

RETURN:		zero flag and carry flag are set to reflect the result
		of comparison

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none. Copied from CompareName()

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	owa	9/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComparePhoneticName	proc	near	uses	ax, cx, si, di, es, bp
	.enter
	mov	di, es:[si].TE_item	; di - item number
	call	DBLockNO		; lock this record chunk
	mov	di, es:[di]		; di - offset to record data
	mov	cx, es:[di].DBR_phoneticSize ; cx - size of phonetic
	add	di, es:[di].DBR_toPhonetic; es:di - ptr to index field
	mov	si, offset sortPhoneticBuf; ds:si - ptr to 'sortPhoneticBuf'

	tst	cx			; Is phonetic field in item NULL?
	jnz	doCompare		; if not, do compare
	clc				; assume ds:si >= es:di

	cmp	{wchar} ds:[si], 0	; is sortPhoneticBuf null?

	jmp	done			; ok, ZF is set
doCompare:
	clr	cx			; strings are null terminated
	call	CompareUsingSortOptionNoCase	; compare two strings
done:
	pushf				; save flags

	call	DBUnlock		; unlock this block
	popf				; restore flags

	.leave
	ret
ComparePhoneticName	endp
endif

ifdef GPC
EnableRecords	proc	far
	uses	ax, bx, cx, dx, bp, di, si
	.enter
	mov	dx, mask VTS_SELECTABLE or mask VTS_EDITABLE	; turn on
	call	ModifyFields
	.leave
	ret
EnableRecords	endp

DisableRecords	proc	far
	uses	ax, bx, cx, dx, bp, di, si
	.enter
	;
	; if there is no letter tab selected, don't say "No entries"
	;
	GetResourceHandleNS	MyLetters, bx
	mov	si, offset MyLetters
	mov	ax, MSG_LETTERS_GET_LETTER
	mov	di, mask MF_CALL
	call	ObjMessage			; cx = letter
	cmp	cx, -1
	je	noNoRecord
	GetResourceHandleNS	LastNameField, bx
	mov	si, offset LastNameField
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	GetResourceHandleNS	NoRecordString, dx
	mov	bp, offset NoRecordString
	clr	cx, di
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	clr	di
	call	ObjMessage
noNoRecord:
	GetResourceHandleNS	AddrField, bx
	mov	si, offset AddrField
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	GetResourceHandleNS	NoRecordInstruction, dx
	mov	bp, offset NoRecordInstruction
	clr	cx, di
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	clr	di
	call	ObjMessage
	mov	dx, (mask VTS_SELECTABLE or mask VTS_EDITABLE) shl 8 ; turn off
	call	ModifyFields
	.leave
	ret
DisableRecords	endp

ModifyFields	proc	near
	mov	cx, length disableEntryFields
	GetResourceHandleNS	Interface, bx
	clr	bp
fieldsLoop:
	mov	si, cs:disableEntryFields[bp]
	push	cx, dx, bp
	mov	ax, MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
	mov	cx, dx
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	cx, dx, bp
	add	bp, size lptr
	loop	fieldsLoop
	ret
ModifyFields	endp

disableEntryFields	lptr \
	offset	Interface:LastNameField,
	offset	Interface:AddrField,
	offset	Interface:StaticPhoneOneNumber,
	offset	Interface:StaticPhoneTwoNumber,
	offset	Interface:StaticPhoneThreeNumber,
	offset	Interface:StaticPhoneFourNumber,
	offset	Interface:StaticPhoneFiveNumber,
	offset	Interface:StaticPhoneSixNumber,
	offset	Interface:StaticPhoneSevenName,
	offset	Interface:StaticPhoneSevenNumber
endif

CommonCode	ends
