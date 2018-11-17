COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Database		
FILE:		dbDisplay.asm

AUTHOR:		Ted H. Kim, March 3, 1992

ROUTINES:
	Name			Description
	----			-----------
	DisplayCurRecord	Top level routine for displaying a record
	DisplayIndexField	Displays the text string for index field
	DisplayAddrField	Displays the text string for address field
	DisplayNoteField	Displays the text in Notes field
	DisplayPhoneType	Displays phone number type name
	DisplayPhoneNoField	Displays phone number
	DisplayPhoneticField	Displays the text for phonetic field (pizza)
	DisplayZipField		Displays the text for zip field (pizza)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision

DESCRIPTION:
	Contains all the routines used in displaying a record in GeoDex.

	$Id: dbDisplay.asm,v 1.1 97/04/04 15:49:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayCurRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the contents of current record on screen.

CALLED BY:	UTILITY

PASS:		ds - segment of core block
		si - current record handle

RETURN:		nothing

DESTROYED:	ax, cx, dx, si, di, bp	

PSEUDO CODE/STRATEGY:
	Read in index field text string into core block
	Clear all of the text edit fields
	Display all the text strings on screen
	Give focus to index field
	Update the letter tab

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/4/89		Initial version
	Don	4/20/95		Optimized to re-draw as little as possible

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayCurRecord	proc	far

	tst	si
	LONG jz	exit

ifdef GPC
	call	EnableRecords
endif

	; copy the contents of index field into 'sortBuffer'

	cmp	ds:[curRecord], si	; if we're already on this record
	LONG je	sameRecord		; ...just clean things up a bit
	push	si			; save current record handle
	mov	ds:[curRecord], si	; si - current record handle
	call	GetLastName		

	; now clear all text objects

	mov	cx, NUM_TEXT_EDIT_FIELDS+1	; cx - number of text fields
	clr	si			; si - offset to table of field handles 
	call	ClearTextFields		; clear the text edit fields
	pop	di			; restore current record handle

	; now display all text strings in text objects 

	push	di
	andnf	ds:[recStatus], not mask RSF_NEW ; clear new record flag
	call	DBLockNO
	mov	di, es:[di]		; open up this record
	call	DisplayIndexField	; display index field text string
	call	DisplayAddrField	; display address field text string
	call	DisplayNoteField	; display notes if there are any
PZ <	call	DisplayPhoneticField	; display phonetic field text string >
PZ <	call	DisplayZipField		; display zip field text string	>
ifdef GPC
	call	DisplayAllPhoneNumbers
	call	DisplayNoteIcon
endif

	; perform these updates now so the screen won't flash when
	; displaying the same record but a different phone number

	push	di
	cmp	ds:[displayStatus], BROWSE_VIEW ; browse view?
	je	skipFocus		; if so, skip
	call	FocusSortField		; set focus to index field
skipFocus:
	call	UpdateLetterButton	; update the letter tab
	; update Prev/Next state
ifdef GPC
	call	UpdatePrevNext
endif
	pop	di
	pop	bp			; bp - current record handle

	; display the correct phone number
dispPhoneNo:
	mov	cl, es:[di].DBR_phoneDisp
	clr	ch			; cx - current phone number counter
ifdef GPC
	;I'm not sure what the old code was trying to do.
	cmp	cx, es:[di].DBR_noPhoneNo
else
	cmp     es:[di].DBR_noPhoneNo, MAX_PHONE_NO_RECORD ; 8 phone entries?
endif
	jne     common			; if not max, display desired number
	mov     cx, 1			; otherwise, always show the 2nd entry
common:
	mov	ds:[gmb.GMB_curPhoneIndex], cx ; save it 
	call	DisplayPhoneNoField	; display phone number
donePhoneNo:
	call	DBUnlock

	; set the RSF_EMPTY flag, if record really is empty

	andnf	ds:[recStatus], not mask RSF_EMPTY 	; assume not blank
	test	ds:[recStatus], mask RSF_SORT_EMPTY	; is index empty?
	jz	exit					; ...if not, exit
	test	ds:[recStatus], mask RSF_ADDR_EMPTY	; is addr empty?
	jz	exit					; ...if not, exit
	test	ds:[recStatus], mask RSF_PHONE_NO_EMPTY	; is phone # emtpy?
	jz	exit					; ...if not, exit
	ornf	ds:[recStatus], mask RSF_EMPTY		; ...if so, we're blank
exit:
	clr	ds:[phoneFlag]		; clear various phone flags
	ret

	; we're already displaying this record, so just clean things up.
	; Unfortunately, because Ted was a dork, we need to do a lot of
	; work to just update the phone field, but that's life.
sameRecord:
	call	ClearTextFieldsSelection
	mov	di, si
	call	DBLockNO
	mov	di, es:[di]		; open up this record
	mov	cl, es:[di].DBR_phoneDisp
	clr	ch
	cmp	cx, ds:[gmb.GMB_curPhoneIndex]	; show same phone number ??
	je	donePhoneNo
	push	si, di
	mov	cx, 2			; cx - # of text fields to clear 
	mov	si, TEFO_PHONE_TYPE	; si - offset to phone type name field
	call	ClearTextFields		; clear both phone fields
	pop	bp, di
	jmp	dispPhoneNo
DisplayCurRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayIndexField 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the text string for the index field. 

CALLED BY:	DisplayCurRecord

PASS:		ds - segment of core block 
		es:di - points to record data to display

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, bp, es	

PSEUDO CODE/STRATEGY:
	Calculate the offset to the index field text string
	Display it
	Clear the dirty bit

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayIndexField	proc	near	uses	di
	.enter

	mov	cx, es:[di].DBR_indexSize  ; cx - length of index field
	add	di, size DB_Record	; di - ptr to index field
	mov	bp, di			; bp - points to beg of text string
	tst	cx			; is index field empty?
	je	exit			; if so, exit
	andnf	ds:[recStatus], not mask RSF_SORT_EMPTY	; clear flag
	mov	dx, es			; dx:bp - points to string to display
	mov	si, TEFO_INDEX		; si - offset to index field
	call	DisplayTextFixupDS	; display index field text string
exit:
	.leave			
	ret
DisplayIndexField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayAddrField 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the text string for the address field. 

CALLED BY:	DisplayCurRecord

PASS:		ds - segment of core block 
		es:di - points to record data to display

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, bp, es	

PSEUDO CODE/STRATEGY:
	Calculate the offset to the address field text string
	Display it
	Clear the dirty bit

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayAddrField	proc	near	uses	di
	.enter

	mov	cx, es:[di].DBR_addrSize ; cx - length of address field
	add	di, es:[di].DBR_toAddr	; di - ptr to address field string
	mov	bp, di			; bp - points to beg of text string
	tst	cx			; is address field empty?
	je	exit			; if so, exit
	andnf	ds:[recStatus], not mask RSF_ADDR_EMPTY	;
	mov	dx, es			; dx:bp - points to string to display

	mov	si, TEFO_ADDR		; si - offset to address field
	call	DisplayTextFixupDS	; display address field text string

	mov     si, offset AddrField    ; bx:si - OD of address field
	GetResourceHandleNS     AddrField, bx
	clr	dx			; dx - end of selection
	clr	cx			; cx - start of selection
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		; select the text
exit:
	.leave
	ret
DisplayAddrField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayNoteField 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the text string for the notes field. 

CALLED BY:	DisplayCurRecord

PASS:		es:di - points to record data to display

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si 

PSEUDO CODE/STRATEGY:
	Sends MSG_VIS_TEXT_REPLACE_ALL_PTR to the targer object

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayNoteField	proc	near	uses	es, di
	.enter

	mov	di, es:[di].DBR_notes	; is there notes data block?
	tst	di			 
	je	exit			; if not, exit

	call	DBLockNO		; open up this data block
	mov	bp, es:[di]
	push	es
	mov	dx, es			; dx:bp - ptr to string
	clr     cx			; string is null terminated
	mov     si, offset NoteText	; bx:si - OD of text object
	GetResourceHandleNS     NoteText, bx   
	mov     ax, MSG_VIS_TEXT_REPLACE_ALL_PTR   
	mov     di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call    ObjMessage              ; display the text string
	pop	es
	call	DBUnlock		; unlock the data block

	mov     si, offset NoteText   	; bx:si - OD of notes field
	GetResourceHandleNS     NoteText, bx
	clr	dx			; dx - end of selection
	clr	cx			; cx - start of selection
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		; select the text
exit:
	.leave
	ret
DisplayNoteField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayPhoneType 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays phone number name type field text string.

CALLED BY:	UTILITY

PASS:		ds:gmb.GMB_phoneTypeBlk - phone number type name data block
		ds:curPhoneType - index of type name to display

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, es, bp

PSEUDO CODE/STRATEGY:
	Open up phone type name data block
	Get pointer to the phone type name to display
		Add DBItem base address to offset of string.
	Display it
	Clear the dirty bit

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	* DisplayTextFixupDS assumes string C_NULL terminated (it zeros CX),
		so we're lazy about string size/length.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version
	witt	1/24/94  	DBCS-ized.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayPhoneType	proc	far
	mov	di, ds:[gmb.GMB_phoneTypeBlk]	; di - handle of data block
	call	DBLockNO
	mov	di, es:[di]		; di - ptr to beg. of record data
	mov	si, di			; save the pointer in si 
	mov	dl, ds:[curPhoneType]	; dl - current phone # type ID
	clr	dh
	shl	dx, 1			; array of 'nptr's
	tst	dx			; is offset zero?
	jne	nonZero			; if not, skip
	mov	dx, 1*(size word)	; if so, adjust the offset
nonZero:
	add	si, dx			; si - ptr to offset 
	add	di, es:[si]		; es:di - ptr to text string
	movdw	dxbp, esdi		; dx:bp - points to string to display

;;	; get number of chars in this string
;;	StringSize call commented out since DisplayTextFixupDS assumes
;;	NULL terminated strings. (witt, 1/21/94)
;;	call	LocalStringSize		; cx - total number of bytes

	mov	si, TEFO_PHONE_TYPE	; si - offset to phone type field
	call	DisplayTextFixupDS	; display this text string
	call	DBUnlock
	ret
DisplayPhoneType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayPhoneNoField 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays both phone type name and phone number. 

CALLED BY:	DisplayCurRecord

PASS:		es:di - pointer to beg. of record data
		cl - phone number counter
		bp - record handle of database block

RETURN:		nothing

DESTROYED:	bx, cx, dx, es, si, di 

PSEUDO CODE/STRATEGY:
	Get the offset to the current phone entry
	Display the phone type name
	Display the phone number

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	DisplayTextFixupDS assumes string C_NULL terminated, so the DBCS
	version is lazy about string size/length.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version
	witt	1/21/94  	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayPhoneNoField	proc	far
	cmp	es:[di].DBR_noPhoneNo, MAX_PHONE_NO_RECORD ; too many phone #'s?
	jne	enable				; if so, disable down button
	
	cmp	cl, MAX_PHONE_NO_RECORD-1	; last phone entry?
	jne	disable				; if not, skip
	mov	si, offset ScrollDownTrigger	; bx:si - OD of down button
	GetResourceHandleNS	ScrollDownTrigger, bx	
	push	di
	call	DisableObjectFixupDSES		; disable phone down button
	mov	si, offset ScrollUpTrigger	; bx:si - OD of down button
	call	EnableObjectFixupDSES		; enable phone up button
	pop	di
	jmp	short	start
disable:
	cmp	cl, 1				; 1st phone entry?
	jne	enable				; if not, skip

	mov	si, offset ScrollUpTrigger	; bx:si - OD of down button
	GetResourceHandleNS	ScrollUpTrigger, bx	
	push	di
	call	DisableObjectFixupDSES		; disable phone down button
	mov	si, offset ScrollDownTrigger	; bx:si - OD of down button
	call	EnableObjectFixupDSES		; enable phone down button
	pop	di
	jmp	short	start
enable:
	push	di
	mov	si, offset ScrollUpTrigger	; bx:si - OD of down button
	GetResourceHandleNS	ScrollUpTrigger, bx	
	call	EnableObjectFixupDSES		; disable phone down button
	mov	si, offset ScrollDownTrigger	; bx:si - OD of down button
	call	EnableObjectFixupDSES		; disable phone down button
	pop	di
start:
	mov	es:[di].DBR_phoneDisp, cl	; save new phone counter
	add	di, es:[di].DBR_toPhone	; di - pointer to phone entries
	tst	cl			; is this a blank phone type?
	je	blank			; if so, skip
mainLoop:
if DBCS_PCGEOS
	mov	dx, es:[di].PE_length	; advance record ptr
	shl	dx, 1			; size of phone number string
	add	di, dx
else
	add	di, es:[di].PE_length	; add the length of phone string
endif
	add	di, size PhoneEntry	; di - pointer to the next phone entry
	loop	mainLoop		; continue

blank:
	mov	dl, es:[di].PE_type	; dl - phone number name type ID number
	mov	ds:[curPhoneType], dl	; save it
	push	di, es			; save the record handle of data block
	call	DisplayPhoneType	; display the phone type name
	pop	di, es			; record handle of database block
	mov	cx, es:[di].PE_length	; cx - size of phone number
	tst	cx			; no phone number?
	je	exit			; if not, exit	

	mov	bp, di			; bp - points to beg of text string
	add	bp, size PhoneEntry	; bp - points to phone # to display
	andnf	ds:[recStatus], not mask RSF_PHONE_NO_EMPTY ; phone # not emtpy
	mov	dx, es			; dx:bp - points to string to display
	mov	si, TEFO_PHONE_NO	; si - offset to phone number field
	call	DisplayTextFixupDS	; display index field text string
exit:
	ret
DisplayPhoneNoField	endp


if PZ_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayPhoneticField 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the text string for the phonetic field. 

CALLED BY:	DisplayCurRecord

PASS:		ds - segment of core block 
		es:di - points to record data to display

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, bp, es	

PSEUDO CODE/STRATEGY:
	Calculate the offset to the phonetic field text string
	Display it
	Clear the dirty bit

	Copied from DisplayIndexField

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	owa	7/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayPhoneticField	proc	near	
	uses	di
	.enter

	mov	cx, es:[di].DBR_phoneticSize  ; cx - size of index field
	add	di, es:[di].DBR_toPhonetic ; di - ptr to Phonetic field
	mov	bp, di			; bp - points to beg of text string
	tst	cx			; is phonetic field empty?
	je	exit			; if so, exit
	andnf	ds:[recStatus], not mask RSF_PHONETIC_EMPTY  ; clear flag
	mov	dx, es			; dx:bp - points to string to display
	mov	si, TEFO_PHONETIC	; si - offset to phonetic field
	call	DisplayTextFixupDS	; display phonetic field text string
exit:
	.leave			
	ret
DisplayPhoneticField	endp
endif


if PZ_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayZipField 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the text string for the zip field. 

CALLED BY:	DisplayCurRecord

PASS:		ds - segment of core block 
		es:di - points to record data to display

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, bp, es	

PSEUDO CODE/STRATEGY:
	Calculate the offset to the phonetic field text string
	Display it
	Clear the dirty bit

	Copied from DiaplayIndexField

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	owa	7/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayZipField	proc	near	
	uses	di
	.enter

	mov	cx, es:[di].DBR_zipSize  ; cx - size of zip field
	add	di, es:[di].DBR_toZip ; di - ptr to Phonetic field
	mov	bp, di			; bp - points to beg of text string
	tst	cx			; is zip field empty?
	je	exit			; if so, exit
	andnf	ds:[recStatus], not mask RSF_ZIP_EMPTY	; clear flag
	mov	dx, es			; dx:bp - points to string to display
	mov	si, TEFO_ZIP		; si - offset to zip field
	call	DisplayTextFixupDS	; display zip field text string
exit:
	.leave			
	ret
DisplayZipField	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayAllPhoneNumbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays all phone numbers!

CALLED BY:	DisplayCurRecord

PASS:		ds - segment of core block 
		es:di - points to record data to display

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/26/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef GPC
DisplayAllPhoneNumbers	proc	near	
	uses	di
	.enter
	call	ClearAllPhones	
	;
	; display numbers in order they appear in record
	;
	mov	cx, es:[di].DBR_noPhoneNo
	add	di, es:[di].DBR_toPhone
	cmp	cx, length displayPhoneNumList
	jbe	gotNumPhones
	mov	cx, length displayPhoneNumList
gotNumPhones:
	clr	bp				; counters
displayPhoneLoop:
	mov	al, es:[di].PE_type
	GetResourceHandleNS	Interface, bx
	mov	si, cs:displayPhoneNameList[bp]
	call	ShowPhoneName
	mov	si, cs:displayPhoneNumList[bp]
	call	ShowPhoneNumber
	add	bp, size lptr
	mov	dx, es:[di].PE_length
DBCS <	shl	dx, 1						>
	add	di, dx
	add	di, size PhoneEntry
	loop	displayPhoneLoop
	.leave			
	ret
DisplayAllPhoneNumbers	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowPhoneName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level display of a single phone numbers.

CALLED BY:	DisplayAllPhoneNumbers

PASS:		ds - segment of core block 
		al - PhoneTypeIndex

RETURN:		nothing

DESTROYED:	ax, bx, dx, si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1999/1/26	Initial version
	martin	1999/12/9	Split out and documented parameters
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShowPhoneName	proc	near	
	uses	cx, bp, di, es			; save counters   [cx, bp]
	.enter					; save PhoneEntry [es:di]
	push	si				; save text object
	mov	di, ds:[gmb.GMB_phoneTypeBlk]
	call	DBLockNO
	mov	di, es:[di]			; es:di = phone names
	mov	si, di
	clr	dx
	mov	dl, al				; dx = phone type index
	shl	dx, 1				; word table
	tst	dx
	jne	nonZero
	mov	dx, size word			; else just use first one
nonZero:
	add	si, dx				; es:si = name offset
	add	di, es:[si]			; es:di = name
	cmp	{TCHAR}es:[di], C_NULL
	je	clearName
	;
	; if standard phone name, use display string
	;	es:di = phone name from entry
	;	^lbx:(on stack) = text object
	;	bp = table offset
	;
	mov	si, cs:standardPhoneNameStrings[bp]
	tst	si
	jz	notStandard
	push	bx, ds
	GetResourceHandleNS	TextResource, bx
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]		; ds:si = standard string
	clr	cx
	call	LocalCmpStrings
	call	MemUnlock		; preserves flags
	pop	bx, ds
	jne	notStandard
	GetResourceHandleNS	TextResource, dx
	mov	bp, cs:displayPhoneNameStrings[bp]
	tst	bp
	jz	notStandard
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	jmp	short setPhoneName

notStandard:
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	movdw	dxbp, esdi
setPhoneName:
	clr	cx
finishPhoneName:
	pop	si				; ^lbx:si = text object
	mov	di, mask MF_CALL
	call	ObjMessage
	call	DBUnlock
	.leave
	retn
clearName:
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	jmp	short finishPhoneName
ShowPhoneName	endp

		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowPhoneNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level display of a single phone numbers.

CALLED BY:	DisplayAllPhoneNumbers

PASS:		es:di - points to PhoneEntry

RETURN:		nothing

DESTROYED:	ax, bx, dx, si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1999/1/26	Initial version
	martin	1999/12/9	Split out and documented parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShowPhoneNumber	proc	near	
	uses 	cx, bp, di			; save counters, record
	.enter					; cx, bp = counters, di = rec
	tst	es:[di].PE_length
	jz	clearPhone
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, es
	mov	bp, di
	add	bp, size PhoneEntry		; dx:bp = phone number
	clr	cx
finishPhoneNumber:
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave	
	retn
clearPhone:
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	jmp	short finishPhoneNumber
ShowPhoneNumber	endp

		
displayPhoneNumList	lptr \
	offset	Interface:StaticPhoneBlankNumber,
	offset	Interface:StaticPhoneOneNumber,
	offset	Interface:StaticPhoneTwoNumber,
	offset	Interface:StaticPhoneThreeNumber,
	offset	Interface:StaticPhoneFourNumber,
	offset	Interface:StaticPhoneFiveNumber,
	offset	Interface:StaticPhoneSixNumber,
	offset	Interface:StaticPhoneSevenNumber

;must follow previous list
displayPhoneNameList	lptr \
	offset	Interface:StaticPhoneBlankName,
	offset	Interface:StaticPhoneOneName,
	offset	Interface:StaticPhoneTwoName,
	offset	Interface:StaticPhoneThreeName,
	offset	Interface:StaticPhoneFourName,
	offset	Interface:StaticPhoneFiveName,
	offset	Interface:StaticPhoneSixName,
	offset	Interface:StaticPhoneSevenName

.assert (length displayPhoneNumList) eq (length displayPhoneNameList)

standardPhoneNameStrings	lptr \
	0,
	offset	TextResource:PhoneHomeString,
	offset	TextResource:PhoneWorkString,
	offset	TextResource:PhoneCarString,
	offset	TextResource:PhoneFaxString,
	offset	TextResource:PhonePagerString,
	offset	TextResource:EmailString,
	0

displayPhoneNameStrings	lptr \
	0,
	offset	TextResource:PhoneHomeDisplayString,
	offset	TextResource:PhoneWorkDisplayString,
	offset	TextResource:PhoneCarDisplayString,
	offset	TextResource:PhoneFaxDisplayString,
	offset	TextResource:PhonePagerDisplayString,
	offset	TextResource:PhoneEmailDisplayString,
	0

.assert (length standardPhoneNameStrings) eq (length displayPhoneNameStrings)
.assert (length standardPhoneNameStrings) eq (length displayPhoneNameList)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearAllPhones
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loops through all phone numbers and names and erases
		outdated display.

CALLED BY:	DisplayAllPhoneNumbers

PASS:		ds - segment of core block 
		al - PhoneTypeIndex

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1999/1/26	Initial version
	martin	1999/12/9	Split out and documented parameters
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearAllPhones	proc	near
	;
	; clear all fields
	;
	uses	di
	.enter
	mov	cx, length displayPhoneNumList + length displayPhoneNameList
	GetResourceHandleNS	Interface, bx
	clr	bp
clearLoop:
	mov	si, cs:displayPhoneNumList[bp]
	push	cx, bp
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	cx, bp
	add	bp, size lptr
	loop	clearLoop
	.leave
	retn
ClearAllPhones	endp
	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayNoteIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays note icon

CALLED BY:	DisplayCurRecord

PASS:		ds - segment of core block 
		es:di - points to record data to display

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/8/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayNoteIcon	proc	near
		uses	di
		.enter
		call	UserGetDefaultUILevel
		cmp	ax, UIIL_INTRODUCTORY
		je	noNotes
		mov	cx, offset NoteIconMoniker	; assume notes exist
		tst	es:[di].DBR_notes
		jnz	haveState
noNotes:
		mov	cx, offset NoNoteIconMoniker
haveState:
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	dl, VUM_NOW
		GetResourceHandleNS     NoteIcon, bx
		mov	si, offset NoteIcon
		mov	di, mask MF_CALL
		call	ObjMessage
		.leave
		ret
DisplayNoteIcon	endp

UpdateNoteIcon	proc	far
		mov	di, ds:[curRecord]
		tst	di
		jz	done
		call	DBLockNO
		mov	di, es:[di]
		call	DisplayNoteIcon
		call	DBUnlock
	;
	; update search list
	;
		call	ReDrawBrowseList
done:
		ret
UpdateNoteIcon	endp

idata	segment
	NoteIconGlyphClass
idata	ends

NoteIconGlyphStartSelect	method	NoteIconGlyphClass, MSG_META_START_SELECT
		call	UserGetDefaultUILevel
		cmp	ax, UIIL_INTRODUCTORY
		je	done
	;
	; set DS for DBLockNO
	;
		GetResourceSegmentNS dgroup, ds
		mov	di, ds:[curRecord]
		tst	di
		jz	done
		call	DBLockNO
		mov	di, es:[di]
		tst	es:[di].DBR_notes
		call	DBUnlock		; (preserves flags)
		jz	done			; only if there are notes
		mov	ax, MSG_ROLODEX_NOTES
		call	GeodeGetProcessHandle
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		ret
NoteIconGlyphStartSelect	endm

endif  ; GPC

CommonCode	ends
