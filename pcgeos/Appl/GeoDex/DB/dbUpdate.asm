COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Database		
FILE:		dbUpdate.asm

AUTHOR:		Ted H. Kim, March 3, 1992

ROUTINES:
	Name			Description
	----			-----------
	UpdateMain		Updates the main table
	UpdateIndex		Updates index field of record in database
	UpdateAddr		Updates address field of record in database
	UpdateNotes		Updates the Notes field
	UpdateRecord		Updates the changes to current record
	UpdatePhone		Updates phone fields
	UpdatePhonetic		Updates phonetic fields (pizza)
	UpdateZip		Updates zip fields (pizza)
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision

DESCRIPTION:
	Contains routines used to update an existing record in database.

	$Id: dbUpdate.asm,v 1.1 97/04/04 15:49:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateMain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the main table so as to make sure that correct 
		record handle is stored.

CALLED BY:	SaveCurRecord

PASS:		curRecord - current record handle

RETURN:		nothing

DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
	Open up main table
	Mark the table dirty
	Save the record handle
	Unlock main table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateMain	proc	near
	mov	dx, ds:[curOffset]	; dx - offset to record to update 
	mov	cx, ds:[curRecord]	; cx - current record handle
	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table
	call	DBLockNO
	call	DBDirty			; mark the main table dirty
	mov	di, es:[di]		; di - points to beg of main table
	add	di, dx
	mov	es:[di].TE_item, cx	; update the record handle
	call	DBUnlock
	ret
UpdateMain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update or copy the text string for index field.  The index
		field is stored immediately after the DB_record header.

CALLED BY:	InitRecord, UpdateRecord

PASS:		ds:curRecord - current record handle
		ds:fieldHandles, ds:fieldLengths - data block handle and size

RETURN:		index field in database updated

DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
	Lock the current record
	Delete the old index field text string
		string size in DBR_indexSize.
	Insert the new index field text string
		string length in fieldLengths[TEFO_INDEX].
	Unlock the record

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateIndex 	proc	near
	mov	di, ds:[curRecord]	; di - current record handle
	call	DBLockNO
	mov	si, es:[di]		; open it
	mov	cx, es:[si].DBR_indexSize ; cx - size of old index field
	sub	es:[si].DBR_toAddr, cx	; update offset to address field
	sub	es:[si].DBR_toPhone, cx	; update offset to phone field
PZ <	sub	es:[si].DBR_toPhonetic, cx ; update offset to phonetic field>
PZ <	sub	es:[si].DBR_toZip, cx	; update offset to zip field	>

	mov	dx, size DB_Record	; dx - offset to index field
	call	DBUnlock
	mov	di, ds:[curRecord]	; di - current record handle
	tst	cx			; was index field empty?
	je	empty			; if so, skip
	call	DBDeleteAtNO		; delete the old text string
empty:
	call	DBLockNO		; open up the record again
	mov	si, es:[di]
	mov	cx, ds:fieldLengths[TEFO_INDEX] ; cx - length index field string 
DBCS<	shl	cx, 1			   ; cx - size index field str	>
	mov	es:[si].DBR_indexSize, cx  ; save the size information
	add	es:[si].DBR_toAddr, cx	; update offset to address field
	add	es:[si].DBR_toPhone, cx	; update offset to phone field
PZ <	add	es:[si].DBR_toPhonetic, cx ; update offset to phonetic field>
PZ <	add	es:[si].DBR_toZip, cx	; update offset to zip field	>

	call	DBUnlock
	mov	di, ds:[curRecord]	; di - current record handle
	call	DBInsertAtNO		; make room for new text string 
	mov	bp, TEFO_INDEX		; bp - offset to fieldHandles
DBCS<	shr	cx, 1			; cx - length index field	>
	call	MoveStringToDatabase	; copy the new text string in
	ret
UpdateIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update or copy the text string for address field.

CALLED BY:	InitRecord, UpdateRecord

PASS:		curRecord - current record handle
		fieldHandles, fieldLengths - data block handle and size

RETURN:		address field in database updated

DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
	Lock the current record
	Delete the old address field text string
	Insert the new address field text string
	Unlock the record

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateAddr	proc	near
	mov	di, ds:[curRecord]	; di - current record handle
	call	DBLockNO		; open it
	mov	si, es:[di]
	mov	cx, es:[si].DBR_addrSize  ; cx - size of old addr field
PZ <	sub	es:[si].DBR_toPhonetic, cx ;update offset to phonetic fields>
PZ <	sub	es:[si].DBR_toZip, cx	; update the offset to zip fields>

	sub	es:[si].DBR_toPhone, cx	; update the offset to phone fields
	mov	dx, es:[si].DBR_toAddr 	; dx - offset to address field
	call	DBUnlock
	mov	di, ds:[curRecord]	; di - current record handle 
	tst	cx			; was address field empty?
	je	empty			; if so, skip
	call	DBDeleteAtNO		; delete the old text string
empty:
	call	DBLockNO		; open up the record again
	mov	si, es:[di]
	mov	cx, ds:fieldLengths[TEFO_ADDR] ; cx - length addr field string 
DBCS<	shl	cx, 1			  ; cx - size address field string   >
	mov	es:[si].DBR_addrSize, cx  ; save new address string size 
PZ <	add	es:[si].DBR_toPhonetic, cx; update offset to phonetic fields>
PZ <	add	es:[si].DBR_toZip, cx	;update the offset to zip fields>
	add	es:[si].DBR_toPhone, cx	; update the offset to phone fields
	call	DBUnlock
	mov	di, ds:[curRecord]	; open up the record again
	call	DBInsertAtNO		; make room for the text string 
	mov	bp, TEFO_ADDR		; bp - offset to fieldHandles
DBCS<	shr	cx, 1			; cx - string length		>
	call	MoveStringToDatabase	; copy the new text string in
	ret
UpdateAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateNotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update or copy the text string for notes field.

CALLED BY:	InitRecord, UpdateRecord

PASS:		ds:curRecord - current record handle
		ds:fieldLengths[TEFO_NOTES], ds:fieldHandles[TEFO_NOTES]

RETURN:		Notes field in database DB_Record updated

DESTROYED:	ax, bx, cx, dx, bp, si, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	* The previous note is not deleted; it's space is not reclaimed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateNotes	proc	near
	mov	cx, ds:fieldLengths[TEFO_NOTE]	; length (incl C_NULL)
	clr	bp			; assume there is no text
	jcxz	storeNoteHandle		; no text in text field, done.

DBCS<	shl	cx, 1			; cx - note field size (w/C_NULL)  >
	mov	bx, ds:fieldHandles[TEFO_NOTE] ; bx - handle of mem block
	push	ds
	push	bx			; save the handle
	call	MemLock			; lock the global mem block
	call	DBAllocNO		; allocate a database block
	mov	bp, di			; save the block handle in bp
	call	DBLockNO		; lock this new data block
	mov	di, es:[di]		; destination
	mov	ds, ax			; ds - note field text segment
	clr	si			; ds:si - source
	rep	movsb			; copy the text string
	call	DBUnlock
	pop	bx			; restore handle of mem block
	call	MemFree			; delete this mem block
	pop	ds

storeNoteHandle:
	clr	ds:fieldHandles[TEFO_NOTE]	; clear the handle table
	mov	di, ds:[curRecord]	; di - current record handle
	call	DBLockNO		; open it
	mov	si, es:[di]
	mov	es:[si].DBR_notes, bp	; update the offset to note field
	call	DBUnlock		; close it
	ret
UpdateNotes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates an already existing record.

CALLED BY:	SaveCurRecord, SaveCurPhone

PASS:		curRecord - current record handle
		ax - flag to indicate whether to update everything (0)
		     or just phone fields (-1)

RETURN:		record updated
		carry flag set if error

DESTROYED:	ax, bx, cx, dx, es, bp, si, di

PSEUDO CODE/STRATEGY:
	Save which phone number is being displayed
	If update phone fields only
		Goto phone
	If index field modified
		Update index field
	If address field modified
		Update address field
	If phonetic field modified
		Update phonetic field
	If zip field modified
		Update zip field
phone:
	If phone fields modified
		Update phone fields
	exit

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateRecord	proc	far
	push	ax			; save the flag
	mov	di, ds:[curRecord]	; di - handle of record to update
	call	DBLockNO
	call	DBDirty			; mark it dirty
	mov	di, es:[di]		; open up the current record
					; es:di -> DB_Record
	mov	dx, ds:[gmb.GMB_curPhoneIndex]	; dx - current phone number counter 
	mov	es:[di].DBR_phoneDisp, dl	; save it 
	call	DBUnlock		; close it
	pop	ax			; restore the flag
	tst	ax			; update only phone fields?
	js	phone			; if so, skip

	; update the index field if it is modified

	test	ds:[dirtyFields], mask DFF_INDEX  ; index field modified?
	je	address			; if not, skip
	call	UpdateIndex		; update the index field
address:
	; update the address field if it is modified

	test	ds:[dirtyFields], mask DFF_ADDR	  ; addr field modified?
NPZ <	je	notes			; if not, skip		>
PZ <	je	phonetic		; if not, skip		>
	call	UpdateAddr		; update the address field

if PZ_PCGEOS
phonetic:
	; update the phonetic field if it is modified

	test	ds:[dirtyFields], mask DFF_PHONETIC  ; phonetic field modified?
	je	zip			; if not, 
	call	UpdatePhonetic		; update the phonetic field

zip:
	; update the zip field if it is modified

	test	ds:[dirtyFields], mask DFF_ZIP ; zip field modified?
	je	notes			; if not, skip
	call	UpdateZip		; update the zip field
endif
	; update the note field if it is modified
notes:
	test	ds:[dirtyFields], mask DFF_NOTE	  ; note field modified?
	je	phone			; if not, skip
	call	UpdateNotes		; update the note field

	; update the phone fields if they are modified
phone:
	test	ds:[dirtyFields], DFF_PHONE  ; phone field modified?
	je	exit			; if not, exit
	call	UpdatePhone		; update phone fields
	jc	quit			; if error, quit
exit:
	call	MarkMapDirty		; mark the map block dirty
	clc
quit:
	ret				; done
UpdateRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePhone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add any changes to phone fields to the record in database.

CALLED BY:	InitRecord, UpdateRecord

PASS:		fieldHandles - memory block handles of phone fields
		gmb.GMB_curPhoneIndex - phone number counter 

RETURN:		carry set if error

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

PSEUDO CODE/STRATEGY:
	Exit if it was a blank phone field
	Otherwise
		Delete the old phone entry
		Get the phone number type name ID number of new phone entry
		Insert the new phone entry

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePhone	proc	near
ifdef GPC
	call	updateAllPhoneFields
	clr	bx
	xchg	bx, ds:fieldHandles[TEFO_PHONE_NO]
	tst	bx
	jz	noPhoneNo
	call	MemFree
noPhoneNo:
	clr	bx
	xchg	bx, ds:fieldHandles[TEFO_PHONE_TYPE]
	tst	bx
	jz	noPhoneType
	call	MemFree
noPhoneType:
	clc				; no error
	ret
else
	tst	ds:fieldHandles[TEFO_PHONE_TYPE] ; is phone type name empty?
	jne	notEmpty		; if not, skip
	tst	ds:fieldHandles[TEFO_PHONE_NO]	; is phone number field emtpy?
	jne	phoneTypeBlank		; if not, skip
	tst	ds:[gmb.GMB_curPhoneIndex]	; was this a blank phone field?
	je	noError			; if so, exit

	; This is the case when someone deletes a phone entry by backspacing
	; everything in phone number field and phone number type name field

	ornf	ds:[phoneFlag], mask PF_DONT_INC_CUR_PHONE_INDEX ; set a flag
	jmp	short	notNew		; skip
notEmpty:
	call	GetPhoneTypeID		; get phone number type name ID
	tst	dx			; is it one of pre-defined names?
	jne	notNew			; if so, skip

	cmp	ds:[gmb.GMB_totalPhoneNames], MAX_NEW_PHONE_TYPE_NAME
	je	errorBox
	call	AddPhoneTypeName	; if not, new name should be added
notNew:
	call	DeletePhoneEntry	; delete this phone entry from record
	test	ds:[phoneFlag], mask PF_DONT_INC_CUR_PHONE_INDEX 
					; was both phone # and type deleted?
	jne	noError			; if so, exit
	call	InsertPhoneEntry	; add a new phone entry
noError:
	clc
exit:
	ret				; exit

phoneTypeBlank:
	clr	dx			; phone number type name ID is 0 
	jmp	notNew			; skip to delete

errorBox:
	mov	bp, ERROR_TOO_MANY_NAME	; bp - error message number
	call	DisplayErrorBox		; put up a warning box
	jmp	exit
endif


	
	
ifdef GPC
	
updateAllPhoneFields	label	near
	;
	; loop over phone numbers and save if dirty
	;
	mov	cx, length savePhoneNumList
	GetResourceHandleNS	Interface, bx
	clr	bp				; counter
	mov	dx, 1				; entry index (0 is blank)
savePhoneLoop:
	mov	si, cs:savePhoneNumList[bp]
	push	cx, bp, dx

if not _NDO2000
	;
	; if user defined field, check if dirty phone name
	;
	cmp	si, offset Interface:StaticPhoneSevenNumber
	jne	notUserField
	push	si
	mov	si, offset Interface:StaticPhoneSevenName
	call	NearVisTextGetDirt
	pop	si
	tst	cx
	jnz	forceSave

notUserField:
endif

	;
	; check if phone number dirty
	;
	call	NearVisTextGetDirt
if not _NDO2000
	jcxz	saveNextPhone
else
	tst	cx
	jnz	forceSave
	jmp	checkTypeDirty

continueSave:			
endif
	;
	; save some globals that we use
	;
forceSave:
	push	ds:[gmb.GMB_curPhoneIndex]	; (1)
	push	ds:fieldHandles[TEFO_PHONE_NO]	; (2)
	push	ds:fieldLengths[TEFO_PHONE_NO]	; (3)
	push	ds:fieldHandles[TEFO_PHONE_TYPE]	; (4)
	push	ds:fieldLengths[TEFO_PHONE_TYPE]	; (5)
	;
	; insert blank entries to bridge gap to new entry position, if needed
	;
	push	si
	mov	di, ds:[curRecord]
	call	DBLockNO
checkGap:
	mov	si, es:[di]
	cmp	dx, es:[si].DBR_noPhoneNo
	jb	noGap
	mov	ax, es:[si].DBR_noPhoneNo
	mov	ds:[gmb.GMB_curPhoneIndex], ax
	mov	ds:fieldLengths[TEFO_PHONE_NO], 0	; empty entry
	mov	ds:fieldHandles[TEFO_PHONE_NO], 0
	push	bx, dx, di
	mov	dl, 0				; no type name
	call	InsertPhoneEntry
	pop	bx, dx, di
	jmp	short checkGap

noGap:
	call	DBUnlock
	pop	si
	;
	; get phone type of entry at this position
	; (we want to skip DX entries as first entry is blank one)
	;
NDO2000<jmp	userPhoneField						>

	cmp	dx, INDEX_TO_STORE_FIRST_ADDED_PHONE_TYPE-1
	je	userPhoneField
	clr	ax				; in case noPhoneEntry:
	mov	cx, dx				; cx = entry to find
	mov	di, ds:[curRecord]
	call	DBLockNO
	mov	di, es:[di]
	cmp	cx, es:[di].DBR_noPhoneNo
	jae	noPhoneEntry
	add	di, es:[di].DBR_toPhone
findTypeLoop:
	mov	ax, es:[di].PE_length
DBCS <	shl	ax, 1						>
	add	di, ax
	add	di, size PhoneEntry
	loop	findTypeLoop
	mov	al, es:[di].PE_type		; al = phone type
	call	DBUnlock
noPhoneEntry:
	;
	; delete old entry at this position
	;
havePhoneType:
	mov	ds:[gmb.GMB_curPhoneIndex], dx
	push	ax				; save phone type
	push	bx, si				; save text obj
	call	DeletePhoneEntry		; (preserves dx)
	pop	bx, si				; ^lbx:si = text obj
	;
	; get new text for entry, if any
	;
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; cx = block, ax = length
	pop	dx				; dx = phone type
	jcxz	savePhonePop			; no number, leave deleted
	;
	; add new entry
	; (must still have gmb.GMB_curPhoneIndex] set to insert
	;  to right place)
	;
	mov	ds:fieldHandles[TEFO_PHONE_NO], cx
	inc	ax				; include NULL
	mov	ds:fieldLengths[TEFO_PHONE_NO], ax
	push	bx				; save text object block
	call	InsertPhoneEntry		; deletes fieldHandles[]
	pop	bx				; ^hbx = text object block
savePhonePop:
	pop	ds:fieldLengths[TEFO_PHONE_TYPE]	; (5)
	pop	ds:fieldHandles[TEFO_PHONE_TYPE]	; (4)
	pop	ds:fieldLengths[TEFO_PHONE_NO]	; (3)
	pop	ds:fieldHandles[TEFO_PHONE_NO]	; (2)
	pop	ds:[gmb.GMB_curPhoneIndex]	; (1)

saveNextPhone:
	
	pop	cx, bp, dx
	add	bp, size lptr			; next text object
	inc	dx				; next position
	loop	savePhoneLoop
	retn

userPhoneField:
	push	dx, bx, si			; save entry position, text
	push	si
if _NDO2000			
 	mov	si, cs:savePhoneTypeList[bp]
else
	mov	si, offset Interface:StaticPhoneSevenName
endif
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx
	mov	di, mask MF_CALL
	call	ObjMessage			; cx = block, ax = length
	pop	si
	mov	ds:fieldHandles[TEFO_PHONE_TYPE], cx
	inc	ax
	mov	ds:fieldLengths[TEFO_PHONE_TYPE], ax
	call	GetPhoneTypeID
	tst	dx				; already defined?
	jnz	returnPhoneType			; yes, use it
	cmp	ds:[gmb.GMB_totalPhoneNames], MAX_NEW_PHONE_TYPE_NAME
	je	errorBox
	call	AddPhoneTypeName		; dx = new phone type
returnPhoneType:
	mov	ax, dx				; ax = phone type
	pop	dx, bx, si			; entry position, tex obj
	jmp	havePhoneType

errorBox:
	mov	bp, ERROR_TOO_MANY_NAME	; bp - error message number
	call	DisplayErrorBox		; put up a warning box
	jmp	savePhonePop

if _NDO2000
checkTypeDirty:	
	;
	; check if phone type dirty
	;
	pop	cx, bp, dx
	mov	si, cs:savePhoneTypeList[bp]
	push	cx, bp, dx
	call	NearVisTextGetDirt
	jcxz	saveNextPhone
	pop	cx, bp, dx
	mov	si, cs:savePhoneNumList[bp]
	push	cx, bp, dx
	call	NearVisTextGetDirt
	jmp	continueSave
endif
endif

	
UpdatePhone	endp

ifdef GPC
savePhoneNumList	lptr \
	offset	Interface:StaticPhoneOneNumber,
	offset	Interface:StaticPhoneTwoNumber,
	offset	Interface:StaticPhoneThreeNumber,
	offset	Interface:StaticPhoneFourNumber,
	offset	Interface:StaticPhoneFiveNumber,
	offset	Interface:StaticPhoneSixNumber,
	offset	Interface:StaticPhoneSevenNumber
endif

if _NDO2000
savePhoneTypeList	lptr \
	offset	Interface:StaticPhoneOneName,
	offset	Interface:StaticPhoneTwoName,
	offset	Interface:StaticPhoneThreeName,
	offset	Interface:StaticPhoneFourName,
	offset	Interface:StaticPhoneFiveName,
	offset	Interface:StaticPhoneSixName,
	offset	Interface:StaticPhoneSevenName
endif

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NearVisTextGetDirt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get any changes to the given phone name index
		since the last dirty.

CALLED BY:	UpdatePhone

PASS:		bx:si	= vis text to get from

RETURN:		cx	= 0 if not dirty

DESTROYED:	ax, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	2000/2/2	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NearVisTextGetDirt	proc	near
	uses	dx
	.enter				; save entry index
	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	mov	di, mask MF_CALL
	call	ObjMessage		; cx != 0 if dirty
	.leave				; dx = entry index
	ret
NearVisTextGetDirt	endp	

		

if PZ_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePhonetic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update or copy the text string for phonetic field.

CALLED BY:	InitRecord, UpdateRecord

PASS:		curRecord - current record handle
		fieldHandles, fieldLengths - data block handle and size

RETURN:		phonetic field in database updated

DESTROYED:	ax, bx, cx, dx, si, di, es, bp

PSEUDO CODE/STRATEGY:
	Lock the current record
	Delete the old phonetic field text string
	Insert the new phonetic field text string
	Unlock the record

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	owa	7/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePhonetic	proc	near
	mov	di, ds:[curRecord]	; di - current record handle
	call	DBLockNO		; open it
	mov	si, es:[di]
	mov	cx, es:[si].DBR_phoneticSize ;cx - length of old phonetic field
	sub	es:[si].DBR_toZip, cx	; update the offset to zip fields
	sub	es:[si].DBR_toPhone, cx	; update the offset to phone fields
	mov	dx, es:[si].DBR_toPhonetic ; dx - offset to phonetic field
	call	DBUnlock
	mov	di, ds:[curRecord]	; di - current record handle 
	tst	cx			; was address field empty?
	je	empty			; if so, skip
	call	DBDeleteAtNO		; delete the old text string
empty:
	call	DBLockNO		; open up the record again
	mov	si, es:[di]
	mov	cx, ds:fieldLengths[TEFO_PHONETIC]
	shl	cx, 1			; cx - size address field string 
	mov	es:[si].DBR_phoneticSize, cx  ; save new address string length
	add	es:[si].DBR_toZip, cx	;update the offset to zip fields
	add	es:[si].DBR_toPhone, cx	; update the offset to phone fields
	call	DBUnlock
	mov	di, ds:[curRecord]	; open up the record again
	call	DBInsertAtNO		; make room for the text string 
	mov	bp, TEFO_PHONETIC	; bp - offset to fieldHandles
	shr	cx, 1			; cx - string length
	call	MoveStringToDatabase	; copy the new text string in
	ret
UpdatePhonetic	endp

endif


if PZ_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateZip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update or copy the text string for zip field.

CALLED BY:	InitRecord, UpdateRecord

PASS:		curRecord - current record handle
		fieldHandles, fieldLengths - data block handle and size

RETURN:		zip field in database updated

DESTROYED:	ax, bx, cx, dx, si, di, es, bp

PSEUDO CODE/STRATEGY:
	Lock the current record
	Delete the old address field text string
	Insert the new address field text string
	Unlock the record

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	owa	7/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateZip	proc	near
	mov	di, ds:[curRecord]	; di - current record handle
	call	DBLockNO		; open it
	mov	si, es:[di]
	mov	cx, es:[si].DBR_zipSize ; cx - length of old zip field
	sub	es:[si].DBR_toPhone, cx	; update the offset to phone fields
	mov	dx, es:[si].DBR_toZip	; dx - offset to zip field
	call	DBUnlock
	mov	di, ds:[curRecord]	; di - current record handle 
	tst	cx			; was address field empty?
	je	empty			; if so, skip
	call	DBDeleteAtNO		; delete the old text string
empty:
	call	DBLockNO		; open up the record again
	mov	si, es:[di]
	mov	cx, ds:fieldLengths[TEFO_ZIP]
	shl	cx, 1			; cx - size address field string 
	mov	es:[si].DBR_zipSize, cx ; save new address string length
	add	es:[si].DBR_toPhone, cx	; update the offset to phone fields
	call	DBUnlock
	mov	di, ds:[curRecord]	; open up the record again
	call	DBInsertAtNO		; make room for the text string 
	mov	bp, TEFO_ZIP		; bp - offset to fieldHandles
	shr	cx, 1			; cx - string length
	call	MoveStringToDatabase	; copy the new text string in
	ret
UpdateZip	endp
endif

CommonCode	ends
