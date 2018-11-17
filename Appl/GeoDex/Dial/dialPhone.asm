COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Dial		
FILE:		dialPhone.asm

AUTHOR:		Ted H. Kim, 10/17/89

ROUTINES:
	Name			Description
	----			-----------
	CreatePhoneTypeTable	Creates phone number type name table
	RolodexDial		Dial the number or put up phone list DB
	RolodexDialFromPhoneList 
				Dials the number selected from phone list
	InitiateConfirmBox	Brings up confirm phone number DB
	CopyPhoneNumberIntoMemBlock 
				Copy phone number string into a mem blk
	RolodexDialCurrentNumber 
				Dial the phone number
	DisplayPhoneList	Bring up the phone number list DB
	UpdatePhoneEntryInRecord 
				Update the current record if modified 
	CheckForNoPhoneEntry	Check to see if there are any phone entries
	MakePhoneListBoxObjectsNotUsable 
				Make all objects in phone list DB not usable	
	AddIndexFieldToPhoneListBox
				Add index field to the phone number list DB
	AddPhoneNumberToPhoneListBox
				Add phone number string to the phone number DB
	DrawPhoneMonikers	Update the moniker in phone button
	RolodexPhoneDown	Handles down icon in phone fields
	RolodexPhoneUp		Handles up icon in phone fields
	SaveCurPhone		Saves currently displayed phone fields
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	10/17/89	Initial revision
	ted	3/92		Complete restructuring for 2.0
	witt	1/25/94 	Removed evil code that wrote to code segment

DESCRIPTION:
	Contains routines for displaying phone numbers.

	$Id: dialPhone.asm,v 1.1 97/04/04 15:49:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreatePhoneTypeTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates phone number type name table.  The default names
		are copied, and blanks stored for the rest.

CALLED BY:	FileInitialize

PASS:		ds - segment address of core block

RETURN:		dgroup:gmb.GMB_phoneTypeBlk <- handle of phone number type name block

DESTROYED:	cx, di, es

PSEUDO CODE/STRATEGY:
	Allocate a new block to hold the phone type names.
		Determine size of strings and overhead pointers.
	Copy predefined phone type names into this data block
		The user definable phone types get NULL ptrs.
	Initiailize some phone variables
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/30/89	Initial version
	Ted	12/5/90		Reads in text chunks of phone names 
	witt	1/24/94 	Overhaul and DBCS-ized (A Good Thing (tm))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreatePhoneTypeTable	proc	far
	push	ds, es

	;
	;	Walk through the default strings and determine total size.
	;
	GetResourceHandleNS	PhoneHomeString, bx
	push	bx				; save handle
	call	MemLock				; lock the block
	mov	es, ax				; set up the segment
	mov	dx, (size PhoneTypeNameItem)+(size word)	; base size

	mov	di, offset PhoneHomeString	; chunk handle
	call	derefStringSize
	add	dx, cx

	mov	di, offset PhoneWorkString
	call	derefStringSize		
	add	dx, cx

	mov	di, offset PhoneCarString
	call	derefStringSize
	add	dx, cx

	mov	di, offset PhoneFaxString
	call	derefStringSize
	add	dx, cx		

	mov	di, offset PhonePagerString
	call	derefStringSize
	add	dx, cx		

	mov	di, offset EmailString
	call	derefStringSize
	add	cx, dx				; cx <- total size.
	push	es				; save string segment

	;
	;	Now allocate the phone type name block
	;
	call	DBAllocNO			; allocate a new block
	mov	ds:[gmb.GMB_phoneTypeBlk], di		; save the handle of new block
	call	DBLockNO

	mov	di, es:[di]		; es:di <- destination (phone block)
	mov	dx, di

	;	Zero the _whole_ DBItem.
CheckHack < NULL eq 0 >
	mov	bx, cx			; save size
	clr	ax			; zero the memory
	shr	cx, 1			; word count
	rep	stosw			; zero me!
	mov	cx, bx			; restore byte size of DBItem
	
	pop	ds		; ds <- default phone type string segment
	mov	di, dx			; es:di -> base of DBItem

	;
	;	Store pointers to default strings.
	;
	;	cx	- byte size of whole DBItem
	;	dx	- base addr of PhoneType DBItem
	;	es:[di] - pointer to string
	;	es:bx   - where string is stored.
	;
	mov	es:[di].PEI_size, cx	; store chunk size

	lea	bx, es:[di].PEI_offsets		; es:bx <- store ptr to string
	add	di, offset PEI_stringHeap	; ds:si <- next string on heap

	;	The first string (string 0) is null.
	mov	es:[bx], offset PEI_stringHeap
	mov	{word} es:[di], 0	; always clear a word (compatible)
	add	bx, (size word)		; advance pointer
	add	di, (size word)		; advance string placement

	mov	si, offset ds:PhoneHomeString	; chunk handle
	call	derefCopyString

	mov	si, offset ds:PhoneWorkString
	call	derefCopyString		

	mov	si, offset ds:PhoneCarString
	call	derefCopyString

	mov	si, offset ds:PhoneFaxString
	call	derefCopyString

	mov	si, offset ds:PhonePagerString
	call	derefCopyString

	mov	si, offset ds:EmailString
	call	derefCopyString

	; The remaining string pointers are NULL from the `movsw' above.

	;
	;	Unlock and cleanup
	;
	call	DBUnlock			; free "ES" (phone type names)
	pop	bx				; retrieve Strings handle
	call	MemUnlock			; unlock the block (DS)

	pop	ds, es

	;
	; initialize some variables
	;
	mov	ds:[gmb.GMB_totalPhoneNames], INDEX_TO_STORE_FIRST_ADDED_PHONE_TYPE
	mov	ds:[gmb.GMB_curPhoneIndex], 1		; display HOME initially
	call	MarkMapDirty			; mark the map block dirty
	ret

; -------------------------------------------------
;	PASS:	ds:si	- chunk handle
;		es:di	- string dest
;		es:[bx]	- where to store ptr to start of string
;		dx	- base address of DBItem
;	RETURN:	ax, si, di - trashed
;		es:bx	- advanced (by nptr)
;
derefCopyString:
	mov	ax, di				; compute relative offset
	sub	ax, dx
	mov	es:[bx], ax			; store start of string
	add	bx, (size word)			; advance str pointer
	mov	si, ds:[si]			; dereference the handle
	LocalCopyString				; copy the null terminator
	retn

; -------------------------------------------------
;	PASS:	es:di	- chunk handle
;	RETURN:	cx	- string size including C_NULL
;		di	- past end of string
;		ax	- trashed
;
derefStringSize:
	mov	di, es:[di]			; dereference the handle
	LocalStrSize	IncludeNull		; how many bytes
	retn

CreatePhoneTypeTable	endp

Init	ends


DialCode	segment	resource

	PhoneTable		label		word

	word	offset	PhoneNumberListOne
	word	offset	PhoneNumberListTwo
	word	offset	PhoneNumberListThree
	word	offset	PhoneNumberListFour
	word	offset	PhoneNumberListFive
	word	offset	PhoneNumberListSix
	word	offset	PhoneNumberListSeven

	PhoneNameTable		label		word

	word	offset	PhoneNameOne
	word	offset	PhoneNameTwo
	word	offset	PhoneNameThree
	word	offset	PhoneNameFour
	word	offset	PhoneNameFive
	word	offset	PhoneNameSix
	word	offset	PhoneNameSeven

	PhoneNoTable		label		word

	word	offset	PhoneNumberOne
	word	offset	PhoneNumberTwo
	word	offset	PhoneNumberThree
	word	offset	PhoneNumberFour
	word	offset	PhoneNumberFive
	word	offset	PhoneNumberSix
	word	offset	PhoneNumberSeven



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a phone call.  Message handler when the user clicks
		on the "Dial" button.

CALLED BY:	(GLOBAL) MSG_ROLODEX_AUTO_DIAL

PASS:		ds - dgroup
			serialHandle
			phoneFlag
			recStatus
			curRecord
			fieldHandles[TEFO_PHONE_NO]
			gmb.GMB_curPhoneIndex
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexDial	proc	far

	class	RolodexClass

	; first check to see if the serial driver has been loaded

	tst	ds:[serialHandle]		
	jne	noError				; if so, skip 

	; if not, put up an error message and quit

	mov	bp, ERROR_NO_SERIAL_DRIVER	
	call	DisplayErrorBox			
	jmp	exit
noError:
	; check to see if 'confirm before dialing' option is set

	andnf	ds:[phoneFlag], not mask PF_CONFIRM ; clear confirm box flag
	mov	si, offset DialingOptions	; bx:si - OD of GenItemGroup
	GetResourceHandleNS	DialingOptions, bx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED	
	mov	cx, mask DOF_CONFIRM		; cx - identifier
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	
	call	ObjMessage			
	jnc	noConfirm			; if turned off, skip

	; check to see if we are to dial currently display number

	ornf	ds:[phoneFlag], mask PF_CONFIRM ; set confirm box flag 
noConfirm:
	mov	si, offset PhoneListOption	; bx:si - OD of GenItem
	GetResourceHandleNS	PhoneListOption, bx
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	
	call	ObjMessage			; ax - identifier 

	tst	ax				
	je	phoneList	; skip if display phone list option is set

	; update the current record if any phone entry has been changed
blank:
	call	UpdatePhoneEntryInRecord
	jc	exit				; exit if error

	; exit if the current phone number field is empty

	test	ds:[recStatus], mask RSF_PHONE_NO_EMPTY	
	jne	exit		

	; open up the current record entry

	mov	di, ds:[curRecord]	
	tst	di
	jne	notBlank

	; if current record is blank, locate the phone number string

	mov	bx, ds:fieldHandles[TEFO_PHONE_NO]
	tst	bx
	je	exit
	call	MemLock			; lock the block with phone number
	mov	es, ax
	clr	di			; es:di - ptr to phone number string
	mov	ax, ds:fieldLengths[TEFO_PHONE_NO]	; ax - size of string
DBCS <	shl	ax, 1				; ax - size of string	>
	jmp	bringUpBox
notBlank:
	mov	cx, ds:[gmb.GMB_curPhoneIndex]
	call	DBLockNO
	mov	di, es:[di]		
	add	di, es:[di].DBR_toPhone		; es:di - ptr to phone entries
	tst	cx
	je	found
miniLoop:
if DBCS_PCGEOS
	mov	ax, es:[di].PE_length
	shl	ax, 1				; ax - string size
	add	di, ax				; advance ptr
else
	add	di, es:[di].PE_length
endif
	add	di, size PhoneEntry
	loop	miniLoop			; check the next entry
found:
	mov	ax, es:[di].PE_length	
DBCS<	shl	ax, 1				; ax - string size	>

bringUpBox:
	; es:di - pointer to the PhoneEntry 
	; ax - size of phone number string

	call	InitiateConfirmBox		; bring up confirm DB	
	jmp	exit
phoneList:
	tst	ds:[curRecord]			; check to see if a blank rec
	je	blank				; if so, go back up
	call	DisplayPhoneList		; bring up the phone list DB	
exit:
	ret
RolodexDial	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexDialFromPhoneList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message handler when the user selects a phone number from
		the phone number list dialog box.

CALLED BY:	(GLOBAL) MSG_ROLODEX_DIAL_FROM_PHONE_LIST

PASS:		cx - indicates which phone number button is selected

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexDialFromPhoneList	proc	far

	class	RolodexClass

	; open up the current record entry

	mov	di, ds:[curRecord]	
	call	DBLockNO
	mov	di, es:[di]		
	add	di, es:[di].DBR_toPhone		; es:di - ptr to phone entries

	; find the phone number entry was clicked upon
miniLoop:
	tst	es:[di].PE_length		; is there a phone number?
	je	next				; if not, check next

	tst	cx				; have we found it? 
	je	skip				; if so, skip

if DBCS_PCGEOS
	mov	ax, es:[di].PE_length
	shl	ax, 1				; ax - phone entry size
	add	di, ax				; advance ptr
else
	add	di, es:[di].PE_length
endif
	add	di, size PhoneEntry
	dec	cx				; are we done yet?
	jns	miniLoop			; if not, continue
	jmp	skip				; if so, display this number
next:
if DBCS_PCGEOS
	mov	ax, es:[di].PE_length
	shl	ax, 1				; ax - phone entry size
	add	di, ax				; advance ptr
else
	add	di, es:[di].PE_length
endif
	add	di, size PhoneEntry
	jmp	short	miniLoop		; check the next entry
skip:
	mov	ax, es:[di].PE_length		

	; es:di - pointer to the PhoneEntry 
	; ax - length of phone number string

	call	InitiateConfirmBox
	ret
RolodexDialFromPhoneList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitiateConfirmBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the confirm phone number dialog box.

CALLED BY:	(INTERNAL) RolodexDial, RolodexDialFromPhoneList

PASS:		es:di - ptr to PhoneEntry
		ax - string length of the phone number

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

	IMPORTANT: es:di points to a string in a locked DB block,
	which will be return unlocked in this routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision
	witt	1/94		DBCS-ized, ax = length

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitiateConfirmBox	proc	near

	; copy the phone number string into a memory block

	tst	ds:[curRecord]			; was curent record blank?
	je	blank				; if so, skip
	mov	ds:fieldLengths[TEFO_PHONE_NO], ax	; save the size of string
	add	di, size PhoneEntry		; es:di - ptr to phone number
	call	CopyPhoneNumberIntoMemBlock
	call	DBUnlock			; unlock the passed block
	jmp	common
blank:
	mov	bx, ds:fieldHandles[TEFO_PHONE_NO]	; unlock the data block
	call	MemUnlock
common:
	; check to see if 'confirm before dialing' option is set

	test	ds:[phoneFlag], mask PF_CONFIRM 
	jne	confirm				; if turned on, skip
	call	RolodexDialCurrentNumber	; dial the number
	jmp	exit
confirm:
	; add any prefix or area code numbers if necessary

	call	GetPhoneNumber		
	mov	dx, ds:[phoneNoBlk]		; dx - seg addr of phone block
	mov	di, ds:[phoneOffset]
	LocalPrevChar	esdi
	mov	es, dx

	LocalClrChar	es:[di]			; null terminate the string

	; place the phone number into the confirm dialog box 

	clr	bp				; dx:bp - ptr to string
	clr	cx				; cx - string null terminated
	mov	si, offset ConfirmEditBox 	; bx:si - OD of text object
	GetResourceHandleNS	ConfirmEditBox, bx	
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; display the phone number

	; bring up the confirm dialog box

	mov	si, offset ConfirmBox		; bx:si - OD of dialogue box
	GetResourceHandleNS	ConfirmBox, bx 
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; make the dialogue box appear
exit:
	ret
InitiateConfirmBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyPhoneNumberIntoMemBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the phone number string into a memory block.

CALLED BY:	(INTERNAL) InitiateConfirmBox	

PASS:		es:di - string to copy
		ax - phone string length

RETURN:		fieldHandles[TEFO_PHONE_NO] - new mem handle

DESTROYED:	ax, bx, cx, di, si 

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyPhoneNumberIntoMemBlock	proc	near	uses	es, ds
	.enter

	; allocate a new data block

	push	es, di
	mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or 0 ; HeapAllocFlags
DBCS<	shl	ax, 1				; ax - string size	>
	call	MemAlloc			; allocate the block
	mov	ds:fieldHandles[TEFO_PHONE_NO], bx	; save the handle

	; copy the phone number string into a memory block

	mov	cx, ds:fieldLengths[TEFO_PHONE_NO]	; cx - # of chars to copy
	mov	es, ax				
	clr	di				; es:di - destination
	pop	ds, si				; ds:si - source string
	LocalCopyNString			; copy the string
	call	MemUnlock

	.leave
	ret
CopyPhoneNumberIntoMemBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexDialCurrentNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dial the phone number that's passed in or dial the number
		from the confirm box.

CALLED BY:	(GLOBAL) MSG_ROLODEX_DIAL_CUR_NUMBER
		(INTERNAL) InitiateConfirmBox

RETURN:		fieldHandles[TEFO_PHONE_NO] - mem block with phone number

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexDialCurrentNumber	proc	far
	
	class	RolodexClass

	; check to see if 'confirm before dialing' option is set

	test	ds:[phoneFlag], mask PF_CONFIRM 
	je	dial				; if turned off, skip

	; read in the phone number to dial from confirm dialog box
	; just in case the user has modified it

	GetResourceHandleNS	ConfirmEditBox, bx
	mov	si, offset ConfirmEditBox	; bx:di - OD of text object 
	call	GetTextInMemBlock		; read in phone number 

	; ax - handle of memory block created
	; cx - number of bytes in this memory block

	tst	cx				; no text?
	je	done				; exit then

	mov	ds:[phoneHandle], ax		; save the handle
DBCS <	shl	cx				; # of bytes in string	>
	mov	ds:[phoneOffset], cx		; save # of bytes in string

	; terminate the string with carriage return

	mov	bx, ax				; bx - handle of data block
	call	MemLock				
	mov	es, ax
	mov	di, cx				; es:di - ptr to end of data

SBCS<	mov	{char} es:[di], C_CR		; terminate the string w/ CR	>
DBCS<	mov	{wchar} es:[di], C_CR		; terminate the string w/ CR	>

	call	MemUnlock			
	LocalNextChar	ds:[phoneOffset]
dial:
	call	OpenComPort		; try opening com port 
	jc	done			; exit if error
	call	DialUp			; call this number
	jc	done			; skip if error

	test	ds:[recStatus], mask RSF_NEW	; is this record inserted?
	jne	done			; if not, exit

	mov	bx, ds:[curRecord]	; bx - current record handle
	mov	cl, ds:[curPhoneType]	; cl - phone number type name ID #
if _QUICK_DIAL
	call	UpdatePhoneCount	; update the phone call count

	; update the frequency and history tables

	ornf	ds:[phoneFlag], mask PF_AUTO_DIAL ; called form auto dial 
	call	UpdateFreqTable		; update quick dial tables
	jc	done			; exit if error
	mov	cl, ds:[curPhoneType]	; cl - phone number type name ID #
	call	UpdateHistTable
	jc	done			; exit if error
	call	UpdateMonikers		; update monikers on quick dial window
endif ;if _QUICK_DIAL
	andnf	ds:[phoneFlag], not mask PF_AUTO_DIAL ; clear auto dial flag
done:
	mov	bx, ds:fieldHandles[TEFO_PHONE_NO]	; bx - handle of text data block
	tst	bx			; no mem block to delete?
	je	exit			; if none, exit
	call	MemFree			; delete it
	clr	ds:fieldHandles[TEFO_PHONE_NO]	; clear the handle in table
exit:
	ret
RolodexDialCurrentNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayPhoneList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the phone number list DB.

CALLED BY:	RolodexDial

PASS:		ds - dgroup
			curRecord

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayPhoneList	proc	near	
	.enter

	; update the current record if any phone entry has been changed

	call	UpdatePhoneEntryInRecord
	LONG	jc	exit			; exit if error

	; check to see if current record has any phone number to dial

	call	CheckForNoPhoneEntry		
	LONG	jc	exit			; exit if no phone entry

	; initially mark all phone list box objects not usable

	call	MakePhoneListBoxObjectsNotUsable

	; add the index field of current record to phone list box

	call	AddIndexFieldToPhoneListBox

	; lock the current record entry

	mov	di, ds:[curRecord]	
	call	DBLockNO
	mov	di, es:[di]
	clr	bp			
	mov	cx, es:[di].DBR_noPhoneNo
	mov	bx, es:[di].DBR_toPhone		; get offset to string
	add	di, bx
miniLoop:
	; bp - offset into PhoneTable
	; cx - number of phone entries left
	; bx - offset to current phone entry from beginning of record 
	; es:di - pointer to the current phone entry

	tst	es:[di].PE_length		; skip this entry if empty
	je	next			

	; first make the objects inside phone list box usable

	push	bx, di
	mov	si, cs:PhoneTable[bp]		
	GetResourceHandleNS	WindowResource, bx 
	mov	ax, MSG_GEN_SET_USABLE	
	mov	di, mask MF_FIXUP_DS		
	mov	dl, VUM_NOW			; dl - do it right now
	call	ObjMessage			; make this object usable
	pop	bx, di

	; if not empty add the phone number to the phone list box

	call	AddPhoneNumberToPhoneListBox
	mov	al, es:[di].PE_type		; al - phone type name ID
	mov	dx, es:[di].PE_length		; dx - # of bytes in phone no.
	call	DBUnlock

	; now add phone type name to the phone list box

	call	DrawPhoneMonikers	

	; lock the current record entry again 

	mov	di, ds:[curRecord]	
	call	DBLockNO
	mov	di, es:[di]

	; figure out the pointer to the next phone entry

	add	di, bx	
	add	di, dx
DBCS<	add	di, dx			; add size to di		>
	add	bx, dx
DBCS<	add	bx, dx			; point past this phone number string>
	add	bp, 2
next:
	add	di, size PhoneEntry
	add	bx, size PhoneEntry
	loop	miniLoop			; check the next phone entry
	call	DBUnlock		

	; mark phone list box usable

	mov	si, offset PhoneNumberListBox 
	GetResourceHandleNS	PhoneNumberListBox, bx 
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_FIXUP_DS
	mov	dl, VUM_NOW		; do it right now
	call	ObjMessage		; make the window usable

	; bring up the phone list box

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS	; di - set flags 
	call	ObjMessage		; display the window
exit:
	.leave
	ret
DisplayPhoneList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePhoneEntryInRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the current record if the phone number entry has
		been changed.

CALLED BY:	(INTERNAL) DisplayPhoneList

PASS:		ds - dgroup
			ds:recStatus
			ds:fieldHandles[TEFO_PHONE_NO]

RETURN:		carry set if there was an error 
		carry clear otherwise

DESTROYED:	ax, bx, cx, dx, si, di 

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10.92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePhoneEntryInRecord	proc	near

	; read in text from phone number text field

	mov	cx, 1			
	mov	di, TEFO_PHONE_NO	
	call	GetRecord		

	; exit if the current phone number field is empty

	test	ds:[recStatus], mask RSF_PHONE_NO_EMPTY	
	jne	exit		

	; Is it a new record?

	test	ds:[recStatus], mask RSF_NEW	
	je	saveRecord

	; Save phone part if this is a new record 

	clr	ds:[phoneFieldDirty]
	call	SaveCurPhone		; save current phone number
	jc	exit			; if carry set, exit	
	jmp	doneSaving

saveRecord:
	; if new phone number has been entered and this isn't a new record
	; then update the phone number entry in this record

	call	SaveCurRecord		
	jc	error			

	; exit if the index field was not left blank
doneSaving:
	test	ds:[recStatus], mask RSF_WARNING 
	je	exit			

	andnf	ds:[recStatus], not mask RSF_WARNING ; clear warning flag
error:
	; delete the memory block that holds phone number string

	mov	bx, ds:fieldHandles[TEFO_PHONE_NO]	
	tst	bx				; no mem block to delete?
	je	quit				; if none, exit
	call	MemFree			
	clr	ds:fieldHandles[TEFO_PHONE_NO]	; clear the handle in table
quit:
	stc					; carry set if error
	jmp	done
exit:
	clc					; carry clear if no error
done:
	ret
UpdatePhoneEntryInRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForNoPhoneEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if there are phone numbers for the current	
		record.

CALLED BY:	(INTERNAL) DisplayPhoneList

PASS:		nothing

RETURN:		carry set there are no phone numbers
		carry clear otherwise

DESTROYED:	ax, bx, cx, dx, si, di, bp	

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForNoPhoneEntry	proc	near
	mov	di, ds:[curRecord]	; di - handle of cur record
	tst	di			; a blank record?
	je	quit			; if so, exit			

	; check to see if there any phone entries with phone numbers

	call	DBLockNO
	mov	di, es:[di]		
	mov	cx, es:[di].DBR_noPhoneNo
	add	di, es:[di].DBR_toPhone
next:
	tst	es:[di].PE_length	; is this an empty phone entry?
	jne	unlock			; if not, exit
	add	di, size PhoneEntry	
	loop	next			; check the next entry
	call	DBUnlock		

	; there is no phone number to dial, put up a message

	mov	bp, ERROR_NO_PHONE_ENTRY
	call	DisplayErrorBox		
quit:
	stc
	jmp	exit			
unlock:
	call	DBUnlock		
	clc
exit:
	ret
CheckForNoPhoneEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakePhoneListBoxObjectsNotUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set all of objects inside phone number list box not usable

CALLED BY:	(INTERNAL) DisplayPhoneList

PASS:		PhoneTable - table of offsets to objects

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakePhoneListBoxObjectsNotUsable	proc	near

	; initially mark all objects inside phone list box not usable

	mov	cx, MAX_PHONE_NO_RECORD-2 ; cx - # of objects to mark not usable
next:
	mov	bp, cx			
	shl	bp, 1			; bp - index into PhoneTable
	mov	si, cs:PhoneTable[bp]	; bx:si - OD of dialog box
	GetResourceHandleNS	WindowResource, bx 
	mov	ax, MSG_GEN_SET_NOT_USABLE	
	mov	di, mask MF_FIXUP_DS		
	mov	dl, VUM_NOW			; dl - do it right now
	call	ObjMessage			; make this object not usable
	dec	cx 			; are we done?
	jns	next			; if not, continue
	ret
MakePhoneListBoxObjectsNotUsable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddIndexFieldToPhoneListBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add index field string to the phone number list box.

CALLED BY:	(INTERNAL) DisplayPhoneList

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, es

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddIndexFieldToPhoneListBox	proc	near

	; open up the current record entry

	mov	di, ds:[curRecord]	
	call	DBLockNO
	mov	di, es:[di]		
	add	di, size DB_Record	; es:di - index field

	; add index field text string to the phone list box

	mov	si, offset NameDisplay	; bx:si - OD of text object
	GetResourceHandleNS	NameDisplay, bx 

	; display the string

	mov	dx, es
	mov	bp, di			; dx:bp - string to display
	clr	cx			; the string is null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS 
	call	ObjMessage		; add the text string to text object
	call	DBUnlock
	ret
AddIndexFieldToPhoneListBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPhoneNumberToPhoneListBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add phone number string to the phone number list DB.

CALLED BY:	(INTERNAL) DisplayPhoneList

PASS:		bp - offset into PhoneNoTable
		es:di - points to PhoneEntry

RETURN:		nothing

DESTROYED:	ax, dx, si	

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddPhoneNumberToPhoneListBox	proc	near	uses	bx, cx, bp, di
	.enter

	; bx:si - OD of phone number object inside phone list box 

	mov	si, cs:PhoneNoTable[bp] 
	GetResourceHandleNS	WindowResource, bx 

	; display the phone number inside the phone list box

	add	di, size PhoneEntry	
	mov	bp, di			
	mov	dx, es			; dx:bp - ptr to string to display
	clr	cx			; the string is null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		; add text stirng to phone list box

	.leave
	ret
AddPhoneNumberToPhoneListBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawPhoneMonikers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new moniker for a GenTrigger.

CALLED BY:	(INTERNAL) RolodexDial	

PASS:		al - current phone type name ID

RETURN:		nothing

DESTROYED:	ax, si, di, es

PSEUDO CODE/STRATEGY:
	Locate the string to be used as a moniker
	Allocate a data block
	Initialize some variables
	Copy the index field text string 
	Copy the phone number type name field text string
	Create a chunk for this string inside UI block
	Set the moniker for the button

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawPhoneMonikers 	proc	near	uses	bx, cx, dx, bp, ds
	.enter

	; find the phone type name string to display

	mov	di, ds:[gmb.GMB_phoneTypeBlk]
	call	DBLockNO
	push	es
	mov	di, es:[di]		
	mov	si, di			; save the pointer in si 

	; using phone type ID, figure out where the string is

	mov	dl, al			; dl - current phone # type ID
	clr	dh
	shl	dx, 1			
	tst	dx			
	jne	nonZero			
	mov	dx, 2		
nonZero:
	add	si, dx			; si - ptr to offset 
	add	di, es:[si]		; es:di - ptr to phone type string

	; get the number of bytes in phone type name string 
	call	LocalStringSize
	mov	dx, cx			; dx - number of bytes (w/out C_NULL)

	mov	si, cs:PhoneNameTable[bp] 
	GetResourceHandleNS	WindowResource, bx 

	; bx:si - OD of phone type name object inside phone list box 
	; es:di - ptr to phone type name string to be copied into the moniker
	; dx - number of bytes to copy (w/out C_NULL)

	push	bx, si
	push	es, di	

	; allocate a new data block

	mov	ax, PHONE_MONIKER_SIZE		; ax - size of data block
	mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or 0 ; HeapAllocFlags
	call	MemAlloc			; allocate the block
	mov	es, ax				; set up the segment
	mov	es:[0], bx			; store the block handle
	mov	di, 2				; ES:DI starts the string

	; fill the 1st ten chars of data block with space s

	mov	cx, 10				
	mov	si, di
	LocalLoadChar	ax, ' '			; store ax ' '
mainLoop:
	LocalPutChar	essi, ax

	loop	mainLoop
	LocalClrChar	es:[si]			; and null terminate it

	pop	ds, si				; ds:si - source string
	mov	cx, dx				; cx - # of bytes to copy
	rep	movsb				; copy the name

	pop	bx, si				; bx:si - OD of dialog box

	; replace the text of visMoniker with this new string

	mov	di, 2
	mov	cx, es
	mov	dx, di				; cx:dx - ptr to the string 
	mov	bp, VUM_MANUAL			; bp - update mode
 	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES 
	call	ObjMessage
	mov	bx, es:[0]			; put block handle in BX
	call	MemFree				; free it up

	; unlock phone type name block

	pop	es
	call	DBUnlock

	.leave
	ret
DrawPhoneMonikers	endp

DialCode	ends

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexPhoneDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called when down arrow to the left of phone
		fields is pressed.

CALLED BY:	MSG_ROLODEX_PHONE_DOWN

PASS:		ds - segment of core block
		cx = 0 if scroll down button is pressed
		cx = GenTextStatusFlags if MSG_GEN_APPLY

RETURN:		both gmb.GMB_curPhoneIndex and curPhoneType updated		

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

PSEUDO CODE/STRATEGY:
	Save out currently display phone number if modified
	Clear phone fields
	Get the next phone number
		When cycling through, we show only one blank phone type.
		A blank record has only the default count of phone types
		plus one blank.
	Display the next phone number and type name

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexPhoneDown	proc	far

	class	RolodexClass		; class definition


	; first save the current phone number if it is modified

	mov	ds:[phoneFieldDirty], cx
	call	SaveCurPhone		; save current phone number
	jc	done			; if carry set, exit

	; clear the phone number and type fields

	mov	cx, 2			; cx - # of text fields to clear 
	mov	si, TEFO_PHONE_TYPE	; si - offset to phone type name field
	call	ClearTextFields 	; clear both phone fields
	mov	di, ds:[curRecord]
	tst	di			; blank record?
	je	blank			; if so, skip 

	; lock the current record entry

	call	DBLockNO
	mov	di, es:[di]		
	mov	cx, ds:[gmb.GMB_curPhoneIndex]	; cx - current phone counter
	test	ds:[phoneFlag], mask PF_DONT_INC_CUR_PHONE_INDEX 
	jne	clearFlag		; skip if a phone # has been deleted

	;
	;	Determine index of phone type to show next
	;	cx = current 'gmb.GMB_curPhoneIndex'
	;
	cmp	es:[di].DBR_noPhoneNo, MAX_PHONE_NO_RECORD ; enough phone #'s?
	je	disable			; if so, disable an arrow button.
	inc	cx			; if not, increment phone counter
	cmp	cx, es:[di].DBR_noPhoneNo  ; was this last phone number? 
	jb	displayPhone		; if not, skip
firstPhone:
	clr	cx			; if so, display 1st phone #

	; display the phone number
displayPhone:
	mov	ds:[gmb.GMB_curPhoneIndex], cx	; save the phone number counter
	mov	bp, ds:[curRecord]	; bp - current record handle
	call	DisplayPhoneNoField	; display this phone number
	call	DBUnlock

	andnf	ds:[recStatus], not mask RSF_EMPTY  ; assume not a blank record
exit:
	call	FocusPhoneField		; give focus to phone number edit field
done:
	ret				; exit

clearFlag:
	andnf	ds:[phoneFlag], not mask PF_DONT_INC_CUR_PHONE_INDEX ; clear flag
	cmp	cx, es:[di].DBR_noPhoneNo  ; was this last phone number? 
	je	firstPhone		; if not, skip
	jmp	short	displayPhone	; display the phone number & type

; ---------------------------------------------------------
;	The record is blank, use default counts for cycling.
;	One empty phone name type is shown.
;
blank:
	mov	cx, ds:[gmb.GMB_curPhoneIndex]	; cx - phone number counter
	inc	cx			; get the next phone number
	cmp	cx, NUM_DEFAULT_PHONE_TYPES	; was this the last phone #?
	jne	increment		; if not, skip
	clr	cx			; if so, display the 1st phone #
increment:
	mov	ds:[gmb.GMB_curPhoneIndex], cx	; save the phone number counter
	inc	cx			
	mov	ds:[curPhoneType], cl	; save the current phone type ID
	call	DisplayPhoneType	; display the phone number & type
	jmp	exit			; quit

; ---------------------------------------------------------
;	Local routine to disable the correct arrow button
;	If at an extreme (either first or last), disable the
;	UP or DOWN arrow, respectively.  If user is in the
;	middle, no arrows are disabled.
;
disable:
	cmp	cx, MAX_PHONE_NO_RECORD-1
	jne	enable?

	; maximum number of phone entries, disable the down button

	mov	si, offset ScrollDownTrigger	; bx:si - OD of down button
	GetResourceHandleNS	ScrollDownTrigger, bx	
	push	di
	call	DisableObjectFixupDSES		; disable phone down button
	pop	di
	jmp	displayPhone

enable?:
	cmp	cx, 1
	jne	skip		

	; enable the up button

	mov	si, offset ScrollUpTrigger	; bx:si - OD of up button
	GetResourceHandleNS	ScrollUpTrigger, bx	
	push	di
	call	EnableObjectFixupDSES		; disable phone up button
	pop	di
skip:
	inc	cx
	jmp	displayPhone

RolodexPhoneDown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexPhoneTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called to set the current active item

CALLED BY:	UPDATE

PASS:		ds - segment of core block
		cx = item number

RETURN:		both gmb.GMB_curPhoneIndex and curPhoneType updated		

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	4/8/2002	Created.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexPhoneTo	proc	far
	; Don't do anything for non-default types
	cmp	cx, NUM_DEFAULT_PHONE_TYPES
	jae	done

	push	cx
	; first save the current phone number if it is modified
	call	SaveCurPhone		; save current phone number
	jc	done			; if carry set, exit

	; clear the phone number and type fields
	mov	cx, 2			; cx - # of text fields to clear 
	mov	si, TEFO_PHONE_TYPE	; si - offset to phone type name field
	call	ClearTextFields 	; clear both phone fields
	mov	di, ds:[curRecord]
	tst	di			; blank record?
	je	done			; if so, skip 

	; lock the current record entry

	call	DBLockNO
	mov	di, es:[di]		
	pop	cx

	;
	;	Determine index of phone type to show next
	;	cx = current 'gmb.GMB_curPhoneIndex'
	;
	cmp	cx, es:[di].DBR_noPhoneNo  ; was this last phone number? 
	jb	displayPhone		; if not, skip
firstPhone:
	clr	cx			; if so, display 1st phone #

	; display the phone number
displayPhone:
	mov	ds:[gmb.GMB_curPhoneIndex], cx	; save the phone number counter
	mov	bp, ds:[curRecord]	; bp - current record handle
	call	DisplayPhoneNoField	; display this phone number
	call	DBUnlock

	andnf	ds:[recStatus], not mask RSF_EMPTY  ; assume not a blank record
exit:
	call	FocusPhoneField		; give focus to phone number edit field
done:
	ret				; exit
RolodexPhoneTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexPhoneUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called when up arrow to the left of phone
		fields is pressed.

CALLED BY:	MSG_ROLODEX_PHONE_UP

PASS:		ds - segment of core block

RETURN:		both gmb.GMB_curPhoneIndex and curPhoneType updated		

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

PSEUDO CODE/STRATEGY:
	Save out currently display phone number if modified
	Clear phone fields
	Get the previous phone number
		If 'phoneCount' wraps, use DBR_noPhoneNo as next.
	Display this phone number and type name

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexPhoneUp	proc	far	
	class	RolodexClass		; class definition

	; first save the current phone number if it is modified

	clr	ds:[phoneFieldDirty]
	call	SaveCurPhone		; save current phone number
	jc	done			; if carry set, exit

	; clear the phone number and type fields

	mov	cx, 2			; cx - # of text fields to clear 
	mov	si, TEFO_PHONE_TYPE	; si - offset to phone type name field
	call	ClearTextFields		; clear both phone fields
	mov	di, ds:[curRecord]	; restore record handle
	tst	di			; has this record not been created?
	je	blank			; if not, skip to handle it

	; lock the current record entry

	call	DBLockNO
	mov	di, es:[di]		; open up the current record
	cmp	es:[di].DBR_noPhoneNo, MAX_PHONE_NO_RECORD  ; enough phone #'s?
	je	disable			; if so, disable down button

	dec	ds:[gmb.GMB_curPhoneIndex]	; update the phone number counter
	jns	notFirst		; skip if it was not the 1st phone entry
	mov	ax, es:[di].DBR_noPhoneNo ; ax - total # of phone type names	
	dec	ax
	mov	ds:[gmb.GMB_curPhoneIndex], ax	; get the last phone entry  
notFirst:

	; display the phone number

	mov	cx, ds:[gmb.GMB_curPhoneIndex]	; cx - new phone number counter
	mov	bp, ds:[curRecord]	; bp - current record handle
	call	DisplayPhoneNoField	; display the phone number
	call	DBUnlock

	andnf	ds:[recStatus], not mask RSF_EMPTY  ; assume not a blank record
exit:
	andnf	ds:[phoneFlag], not mask PF_DONT_INC_CUR_PHONE_INDEX ; clear flag

	call	FocusPhoneField		; give focus to phone number edit field
done:
	ret

; ---------------------------------------------------------
;	The record is blank, use default counts for cycling.
;	One empty phone type is shown.
;
blank:
	dec	ds:[gmb.GMB_curPhoneIndex]		; update phone number counter
	jns	decrement		; skip if it wasn't the 1st phone #
	mov	ax, NUM_DEFAULT_PHONE_TYPES-1
					; ax - total number of phone type names	
	mov	ds:[gmb.GMB_curPhoneIndex], ax	; get the last phone entry  
decrement:
	mov	cx, ds:[gmb.GMB_curPhoneIndex]	; cx - phone number counter
	inc	cx			
	mov	ds:[curPhoneType], cl	; save the current phone type ID 
	call	DisplayPhoneType	; display this phone number
	jmp	exit

; ---------------------------------------------------------
;	Local routine to disable the correct arrow button
;	If at an extreme (either first or last), disable the
;	UP or DOWN arrow, respectively.  If user is in the
;	middle, no arrows are disabled.
;
disable:
	cmp	ds:[gmb.GMB_curPhoneIndex], 1
	jne	enable?

	; maximum number of phone entries, disable the up button

	mov	si, offset ScrollUpTrigger	; bx:si - OD of up button
	GetResourceHandleNS	ScrollUpTrigger, bx	
	push	di
	call	DisableObjectFixupDSES		; disable phone up button
	pop	di
	jmp	short	notFirst
enable?:
	cmp	ds:[gmb.GMB_curPhoneIndex], MAX_PHONE_NO_RECORD-1
	jne	skip

	; enable the down button

	mov	si, offset ScrollDownTrigger	; bx:si - OD of down button
	GetResourceHandleNS	ScrollDownTrigger, bx	
	push	di
	call	EnableObjectFixupDSES		; enable phone down button
	pop	di
skip:
	dec	ds:[gmb.GMB_curPhoneIndex]
	jmp	short notFirst
RolodexPhoneUp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveCurPhone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the current phone type name and number if necessary.

CALLED BY:	RolodexPhoneDown, RolodexPhoneUp

PASS:		recStatus - various record flags

RETURN:		di - record handle updated
		carry set if error

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

PSEUDO CODE/STRATEGY:
	Read in phone fields
	If modified	{
		If created but not yet inserted  {
			Update the record
		}
		If not created {
			Create a new record
		}
	}
	Else	{ delete all memory chunks	} 

	Exit

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveCurPhone	proc	far
	tst	ds:[curRecord]		; is current record blank?
	jne	savePhone		; if not, skip 

	; delete an undoItem if undo was performed

	mov	di, ds:[undoItem]	; did an undo operation get performed?
	tst	di			
	je	savePhone		; if not, skip
	call	NewDBFree		; if so, delete this DB item
	clr	ds:[undoItem]
	call	DisableUndo		; disable undo menu
savePhone:
	; read phone field text strings into memory blocks 

	mov	cx, 2			; cx - number of fields to read in
	mov	di, TEFO_PHONE_TYPE	; di - offset to FieldTable
	call	GetRecord		; read in phone fields

	; check to see if phone fields have been modified

	mov	bx, 2			; bx - number of fields to compare
	mov	bp, TEFO_PHONE_TYPE	; bp - offset into FieldTable
	call	CompareRecord		; any of them modified?
	jne	dirty			; if not, skip 

	; if the phone number field is edited and the user hits
	; carriage return, then the text object is no longer 
	; marked as modified.  However we still need to read in the number

	mov	bx, ds:[phoneFieldDirty]
	test	bl, mask GTSF_MODIFIED
	je	delete
	ornf	ds:[dirtyFields], mask DFF_PHONE_NO
dirty:
	call	MarkMapDirty		; mark the map block dirty
	tst	ds:[curRecord]		; is it new record?
	je	newRecord1		; if so, skip

	test	ds:[recStatus], mask RSF_UPDATE	; has CopyPhone been called?
	jne	update			; if so, skip

	mov	di, ds:[undoItem]	; was undo operation performed? 
	tst	di			
	je	freeMem			; if not, skip
	call	NewDBFree		; if so, delete this DB item
freeMem:
	mov	cx, 2			; cx - number of fields
	mov	bp, TEFO_PHONE_TYPE	; bp - offset to table of field handles
	call	FreeMemChunks	 	; delete any unnecessary mem chunks

	mov	di, ds:[curRecord]
	mov	ds:[undoItem], di	; save the current record handle 
	cmp	ds:[undoAction], UNDO_CHANGE  ; has cur record been changed?
	jge	change			; if so, skip
	mov	ds:[gmb.GMB_orgRecord], di
change:
	mov	ds:[undoAction], UNDO_CHANGE	; set the change flag

	mov	cx, NUM_TEXT_EDIT_FIELDS+1	; cx - # fields to read in
					; add one for the note field
	clr	di			; di - offset to FieldTable
	call	GetRecord		; read in phone fields

	clr	ax
	jmp	short	newRecord2
update:
	mov	ax, -1			; flag - update only phone fields
	call	UpdateRecord		; update the record		
	jmp	short	exit		; exit

newRecord1:
	mov	ax, -1			; flag - init. only phone fields
newRecord2:
	call	InitRecord		; create a new record and initialize
exit:
	ret

delete:
	mov	cx, 2			; cx - number of fields
	mov	bp, TEFO_PHONE_TYPE	; bp - offset to table of field hanldes
	call	FreeMemChunks	 	; delete any unnecessary mem chunks
	clc				; return with no error
	jmp	short	exit
SaveCurPhone	endp

CommonCode	ends



