COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Main
FILE:		mainGeoDex.asm
MAKE:		geodex.geo

AUTHOR:		Ted H. Kim, August 30, 1989

ROUTINES:
	Name			Description
	----			-----------
	RolodexHandleCR		Called when CR is hit in index field
	ModifyIndex		Display first name first and then the last name
	RolodexPrevious		Read in and display previous record
	RolodexNext		Read in and display next record
	RolodexNew		Bring in a blank record for creation
	RolodexNotes		Bring up the Notes Field edit dialog box
	SaveCurRecord		Save currently displayed record
	UpdateQuickDialMenu	Disable or enable the quick dial trigger
	HandleWarningBox	Puts up a warning box for blank index field
	UpdateLetterButton	Updates the letter button
	CompareRecord		Checks to see if a record is modified
	RolodexEnableDisableCalendarButton
				Enable or disable Calendar button
	RespondCalendarRequest	Responds to calendar's request for searching
	RolodexRequestSearch	Sends calendar with a text string to search for
	CallCalendar		Call calendar with given method
(PZ)	RolodexHandlePhoneticCR	Called when CR is hit in phonetic field
(PZ)	RolodexHandleZipCR	Called when CR is hit in zip field

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	8/30/89		Initial revision
	ted	3/92		Compete revamping for V2.0
	witt	1/94		DBCS conversion

DESCRIPTION:
	This file contains message handlers for all (but phone) icons
	on GeoDex.

	$Id: mainGeoDex.asm,v 1.1 97/04/04 15:50:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;------------------------------------------------------------------------------
;			Class definition
;------------------------------------------------------------------------------

idata	segment

	NotesDialogClass

	BlackBorderClass

	RolDocumentControlClass

idata	ends

ifdef GPC
udata	segment
; flag external operation
updateEntry	BooleanByte
udata	ends
endif

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexHandleCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when CR is hit in index field.

CALLED BY:	UI (= MSG_ROLODEX_CR )

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
		(* Don't modify address box if something there already. *)
		If Address field has text, cleanup and return.

		If Index field has NO text, cleanup and return.
		Call ModifyIndex to put first name first.
		Give focus and target to address field.
	PIZZA:	Just give focus and target to phonetic field.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexHandleCR	method	GeoDexClass, MSG_ROLODEX_CR 
if PZ_PCGEOS
	; give focus to the phonetic field

        mov     si, offset PhoneticField ; bx:si - OD of phonetic field
        GetResourceHandleNS     PhoneticField, bx
	
	mov	ax, MSG_GEN_MAKE_FOCUS	
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		

	; now give target to the address field also

	mov	ax, MSG_GEN_MAKE_TARGET	
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		
else
	mov	si, ds:FieldTable[TEFO_ADDR]	; bx:si - OD of text object
	GetResourceHandleNS	Interface, bx	
	call	GetTextInMemBlock	; returns cx - # chars or 0
					; returns ax - handle of text block
	jcxz	readIndex		; skip if empty empty

	mov	bx, ax			; bx - handle of text block
	call	MemFree			; delete it 
	jmp	quit			; and exit
readIndex:
	mov	si, ds:FieldTable[TEFO_INDEX]; bx:si - OD of text object
	GetResourceHandleNS	Interface, bx	
	call	GetTextInMemBlock	; returns cx - # chars or 0
					; returns ax - handle of text block
	jcxz	quit			; stop processing if empty

	push	ds			; save seg addr of core block
	push	ax			; save handle of text block
	mov	bx, ax			; bx - handle of text block
	call	MemLock			; open it up
	mov	ds, ax			; ds - seg address of text block
	clr	si			; ds:si - ptr to text string

	push	cx			; save number of chars in text block
	mov	ax, cx			; ax - number of bytes to allocate
SBCS <	add	ax, 3			; add three bytes: handle and null char>
DBCS <	shl	ax, 1			; ax - string size		>
DBCS <	add	ax, (size hptr) + (size wchar)	; handle + C_NULL
	mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or 0 ; HeapAllocFlags
	call	MemAlloc		; allocate the block
	mov	es, ax			; set up the segment
	mov	es:[0], bx		; store the block handle
	mov	di, 2			; es:di - ptr to the string
	pop	cx			; restore length of string

	call	ModifyIndex		; modify text string from index field
	pop	bx			; bx - handle of field string
	call	MemFree			; free it up
	pop	ds			; ds - seg address of core block
	LocalClrChar	es:[di]		; null terminate the text string

	mov	dx, es
	mov	bp, 2			; dx:bp - ptr to string to display 
	mov	si, TEFO_ADDR		; si - offset to address field handle
	call	DisplayTextFixupDSES	; set text string to text edit object 
	mov	bx, es:[0]		; bx - block handle 
	call	MemFree			; free it up

	; give focus to the address field

	mov	si, offset AddrField	; bx:si - OD of address field
	GetResourceHandleNS	AddrField, bx

	mov	ax, MSG_GEN_MAKE_FOCUS	
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		

	; now give target to the address field also

	mov	ax, MSG_GEN_MAKE_TARGET	
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		

	; mark address field user modified

	mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		
quit:
endif
	ret
RolodexHandleCR	endm

if not PZ_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModifyIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display first name first and then the last name.

CALLED BY:	RolodexHandleCR

PASS:		ds:si - ptr to source string
		es:di - ptr to destination 	

RETURN:		es:di - ptr to end of string (not NULL terminated)

DESTROYED:	ax, bx 

PSEUDO CODE/STRATEGY:
	Skip all leading spaces if there are any
	Skip til a comma is found
	Skip any spaces after the comma
	Copy the first name into destination buffer
	Copy the last name into destination buffer

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If someone types "Smith, John" in index field
	and hits carriage return, it will say "John Smith"
	in address field.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModifyIndex	proc	near
	clr	bx			; bx - offset to beg of text string

	; first, ignore all leading space characters
skipBlank1:
	LocalGetChar	ax, dssi	; get a char from index field
	LocalIsNull	ax		; is it end of text string?

	je	copyBoth		; if so, don't invert
	LocalCmpChar	ax, ' '		; space character?

	je	skipBlank1		; if so, check the next character
	LocalPrevChar	dssi		; go back one character	
	mov	bx, si			; bx - offset to beg of text string

	; now skip until comma
skipLast:
	LocalGetChar	ax, dssi	; get a char from index field
	LocalIsNull	ax		; is it end of text string?

	je	copyBoth		; if so, don't invert
	LocalCmpChar	ax, ','		; comma?

	jne	skipLast		; if not, check the next character

	; ignore all space characters after comma
skipBlank2:
	LocalGetChar	ax, dssi	; get a char from index field
	LocalIsNull	ax		; is it end of text string

	je	copyBoth		; if so, don't invert
	LocalCmpChar	ax, ' '		; space character?

	je	skipBlank2		; if so, check the next character

	; copy the text after comma into memory block first
copyFirst:
	LocalPutChar	esdi, ax	; write out the character to data block
	LocalGetChar	ax, dssi	; get the next character
	LocalIsNull	ax		; are we done?
	jne	copyFirst		; if not, continue...
	LocalLoadChar	ax, ' '		; put space b/w first and last name
	LocalPutChar	esdi, ax	; write it out

	mov	si, bx			; si - offset to beg of text string

	; now copy the text before comma into momory block
copyLast:
	LocalGetChar	ax, dssi	; get a character from first name
	LocalCmpChar	ax, ','		; is it comma?

	je	exit			; if so, exit
	LocalPutChar	esdi, ax	; if not, write it out
	jmp	short	copyLast	; continue...

	; there is no comma b/w first and last name, so don't invert
copyBoth:
	mov	si, bx			; si - ptr to the beg of text string
	LocalCopyNString 		; copy the entire string w/o changing

exit:
	ret
ModifyIndex	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexPrevious
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the current record in database file and displays
		the previous record on screen.

CALLED BY:	Kernel

PASS:		ds - segment of core block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di

PSEUDO CODE/STRATEGY:
	Saves the current record
	Gets the previous record
	Displays the new record

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexPrevious	method	GeoDexClass, MSG_ROLODEX_PREVIOUS
	call	SaveCurRecord		; save current record if necessary
	jc	exit			; exit if error
	tst	ds:[gmb.GMB_numMainTab]		; is database empty?
	je	empty			; if so, exit
	test	ds:[recStatus], mask RSF_WARNING ; was warning box up?
	jne	skip			; if so, skip
	call	FindPrevious		; get handle of previous record

	clr	ds:[curRecord]		; force redraw by setting different
	call	DisplayCurRecord	; display this record on the screen
	andnf	ds:[searchFlag], not mask SOF_NEW   ; clear search flag

	call	UpdateNameList		; update the name list
	call	EnableCopyRecord	; fix up some menu 
	clr	ds:[recStatus]
	jmp	short	quit
skip:
	andnf	ds:[recStatus], not mask RSF_WARNING ; clear warning flag
quit:
	call	DisableUndo		; no undoable action exists
exit:
	ret
empty:
	call	DisableCopyRecord	; fix up some menu
	mov	ds:[recStatus], mask RSF_EMPTY or mask RSF_NEW ; set flags
	jmp	short	quit
RolodexPrevious	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the current record in database file and displays
		the next record on screen.

CALLED BY:	Kernel

PASS:		ds - segment of core block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di

PSEUDO CODE/STRATEGY:
	Saves the current record
	Gets the next record
	Displays the new record

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexNext	method	GeoDexClass, MSG_ROLODEX_NEXT
	call	SaveCurRecord		; save current record if necessary
	jc	exit			; exit if error
	tst	ds:[gmb.GMB_numMainTab]		; is database empty?
	je	empty			; if so, exit
	test	ds:[recStatus], mask RSF_WARNING ; was warning box up?
	jne	skip			; if so, skip
	call	FindNext		; get handle of next record

	call	DisplayCurRecord	; display this record on the screen
	andnf	ds:[searchFlag], not mask SOF_NEW   ; clear search flag

	call	UpdateNameList		; update the name list
	call	EnableCopyRecord	; fix up some menu
	clr	ds:[recStatus]
	jmp	short	quit
skip:
	andnf	ds:[recStatus], not mask RSF_WARNING ; clear warning flag
quit:
	call	DisableUndo		; no undoable action exists
exit:
	ret
empty:
	call	DisableCopyRecord	; fix up some menu
	mov	ds:[recStatus], mask RSF_EMPTY or mask RSF_NEW ; set flags
	jmp	short	quit
RolodexNext	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexNew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the current record if changed and clears the screen
		for a new record.

CALLED BY:	Kernel

PASS:		ds - segment of core block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di

PSEUDO CODE/STRATEGY:
	Save currently displayed record
	Clear all the text edit fields
	Re-initialize some variables

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	There are two ways to initialize a record.  This routine is one
	of those paths.  ClearRecord calls InitRecord.  'gmb.GMB_curPhoneIndex'
	is changed here, for the case when the record is already blank.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexNew	method	GeoDexClass, MSG_ROLODEX_NEW
	call	SaveCurRecord		; save current record if necessary
	jc	quit			; exit if error
	test	ds:[recStatus], mask RSF_WARNING ; was warning box up?
	je	clear			; if not, skip
	tst	ax			; forcibly terminated?
	je	blank			; if so, skip
	cmp	ax, CANCEL		; was cancel button pressed? 
	je	blank			; if so, jump to set flags
	tst	ds:[curRecord]		; is this a new record?
	jne	quit			; if not, exit
	mov	ds:[undoAction], UNDO_NEW	; set undo flag
	jmp	short	quit		; and exit
clear:
	call	ClearRecord		; clear the record 
blank:
	call	FocusSortField		; give focus to index field
	mov	ds:[recStatus], mask RSF_NEW or mask RSF_EMPTY	; set flags
	mov	ds:[gmb.GMB_curPhoneIndex], 1	; phone type is 'HOME'
	clr	ds:[curRecord]		; current record is blank

	call	DisableCopyRecord	; fix up some menu 
	mov	ds:[undoAction], UNDO_NEW	; set undo flag

	cmp	ds:[displayStatus], CARD_VIEW	; card view only?
	je	quit			; if so, exit
	call	SetNewExclusive		; deselect the list entry
quit:
	andnf	ds:[searchFlag], not mask SOF_NEW   ; clear search flag
	call	DisableUndo		; no undoable action exists
	ret
RolodexNew	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexNewInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up new record dialog.

CALLED BY:	GLOBAL

PASS:		ds - segment of core block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/26/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef GPC

RolodexNewInitiate	method	GeoDexClass, MSG_ROLODEX_NEW_INITIATE
	;
	; save current record
	;
	call	SaveCurRecord
	LONG jc	done
	test	ds:[recStatus], mask RSF_WARNING
	jnz	done
	;
	; clear new dialog text fields
	;
	mov	cx, length newDialogFields
	clr	di
	GetResourceHandleNS	NewDialogResource, bx
clearLoop:
	push	di, cx
	mov	si, cs:newDialogFields[di]
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	clr	di
	call	ObjMessage
	pop	di, cx
	add	di, size lptr
	loop	clearLoop
	;
	; mark name field clean
	;
	GetResourceHandleNS	NewLastNameField, bx
	mov	si, offset NewLastNameField
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	clr	di
	call	ObjMessage
	;
	; disable Create button
	;
	GetResourceHandleNS	NewCreate, bx
	mov	si, offset NewCreate
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage
	;
	; give focus to name field
	;
	GetResourceHandleNS	NewLastNameField, bx
	mov	si, offset NewLastNameField
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	clr	di
	call	ObjMessage
	;
	; bring up dialog
	;
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GetResourceHandleNS	NewRecordDialog, bx
	mov	si, offset NewRecordDialog
	clr	di
	call	ObjMessage
done:
	andnf	ds:[recStatus], not mask RSF_WARNING
	ret
RolodexNewInitiate	endm

newDialogFields	lptr \
	offset	NewDialogResource:NewLastNameField,
	offset	NewDialogResource:NewAddrField,
	offset	NewDialogResource:NewStaticPhoneOneNumber,
	offset	NewDialogResource:NewStaticPhoneTwoNumber,
	offset	NewDialogResource:NewStaticPhoneThreeNumber,
	offset	NewDialogResource:NewStaticPhoneFourNumber,
	offset	NewDialogResource:NewStaticPhoneFiveNumber,
	offset	NewDialogResource:NewStaticPhoneSixNumber,
	offset	NewDialogResource:NewStaticPhoneSevenName,
	offset	NewDialogResource:NewStaticPhoneSevenNumber

mainEntryFields	lptr \
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

endif  ; GPC


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexNewCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save new record.

CALLED BY:	GLOBAL

PASS:		ds - segment of core block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/26/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef GPC

AddNewRecord	proc	near
	;
	; get ready to enter data
	;
	push	bp
	call	RolodexNew
	;
	; copy text fields to main record
	;
	mov	cx, length newDialogFields
.assert (length newDialogFields eq length mainEntryFields)
	clr	di
copyLoop:
	push	cx
	push	di
	GetResourceHandleNS	NewDialogResource, bx
	mov	si, cs:newDialogFields[di]
	clr	dx
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	di, mask MF_CALL
	call	ObjMessage			; ^hcx = text
	pop	di
	jcxz	noTextBlock
	push	di
	GetResourceHandleNS	Interface, bx
	mov	si, cs:mainEntryFields[di]
	mov	dx, cx
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_BLOCK
	mov	di, mask MF_CALL
	push	dx
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bx
	call	MemFree
	pop	di
noTextBlock:
	pop	cx
	add	di, size lptr
	loop	copyLoop
	;
	; allow new entries to be noticed
	;
	call	EnableRecords
	;
	; save it
	;
	call	SaveCurRecord
	pop	bp
	ret
AddNewRecord	endp

RolodexNewCreate	method	dynamic GeoDexClass, MSG_ROLODEX_NEW_CREATE
newNameHandle	local	word	; mem handle of name block
matchItem	local	word	; DB item of matching name
matchCurOffset	local	word	; offset in main table of matching entry
newEmailHandle	local	word	; mem handle of newly entered email
newEmailLength	local	word	; length of newly entered email w/null
mainTableOffset	local	word	; abs. offset of main table
endMainTableOffset local word	; abs. offset of end of main table
startMatchOffset local	word	; abs. offset in main table of 1st match entry
endMatchOffset	local	word	; abs. offset in main table of last match entry
	.enter

	call	getNewNameAndEmail
	LONG jc	addNewRecord			; no name, do normal handling
	;
	; check email, if bad, warn user and leave new entry dialog up
	;
	push	bp
	mov	bx, newEmailHandle
	call	MemLock
	clr	dx
	pushdw	axdx				; push param
	call	MAILPARSEADDRESSSTRING		; ax = addr block
	pop	bp
	mov	bx, ax
	push	ds
	call	MemLock
	mov	ds, ax
	mov	si, (size LMemBlockHeader)+4
	call	ChunkArrayGetCount
	clc					; in case none, no error
	jcxz	doneCheck			; allow zero, no name err
						;	will be obvious
	clr	ax
checkEmail:
	push	cx
	call	ChunkArrayElementToPtr		; ds:si = element
	pop	cx
	cmp	{word}ds:[di], 0x1f		; success code
	stc					; assume error
	jne	doneCheck
	inc	ax
	loop	checkEmail
	clc					; all addrs valid, no error
doneCheck:
	pop	ds
	pushf
	call	MemFree				; (preserves flags)
	popf
	jnc	emailAddrsOkay
	mov	ax, offset NewRecordBadEmailText
	mov	bx, ((CDT_ERROR shl offset CDBF_DIALOG_TYPE) or (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE))
	call	createDialogBox
	jmp	keepEditing
emailAddrsOkay:

	call	checkIfNameExists
	jnc	addNewRecord			; doesn't exist yet, add it
	;
	; already exists: check if doing external operation (i.e. from GPCMail)
	; or internal operation (i.e. user using New dialog)
	;
	tst	ds:[updateEntry]
	jnz	externalOperation		; ext operation, more checks
	;
	; internal operation, ask user if they really want to add another
	; entry with same name
	;
	mov	ax, offset NewEntryAlreadyExistsText
queryDialog:
	mov	bx, ((CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or (GIT_MULTIPLE_RESPONSE shl offset CDBF_INTERACTION_TYPE) or mask CDBF_DESTRUCTIVE_ACTION)
	call	createDialogBox
	cmp	ax, IC_YES
	je	addNewRecord			; user wants to add anyway
	jmp	keepEditing			; otherwise, keep editing

	;
	; operation from GPCMail: find all matching entries, then check if
	; any of those have email address matching new email address
	;
externalOperation:
	call	findAllMatchingNames		; locks main table
	;
	; loop through matching entries to see if any have matching email
	; names
	;	es = main table segment
	;
	mov	di, startMatchOffset
checkEntryLoop:
	mov	cx, es:[di].TE_item
	call	compareEmail
	jnc	checkNextEntry
	;
	; name and email match, just show entry
	;	es = main table segment
	;
	call	DBUnlock			; unlock main table
	jmp	showEntry

checkNextEntry:
	add	di, size TableEntry
	cmp	di, endMatchOffset
	jbe	checkEntryLoop
	call	DBUnlock			; unlock main table
	;
	; email doesn't match, check how many entries with same name:
	; - if only one, modify existing entry or continue editing
	; - if more than one, create new entry or continue editing
	;
	mov	ax, startMatchOffset
	cmp	ax, endMatchOffset
						; assume multiple entries match
	mov	ax, offset MultipleEntriesDiffEmailText
	jne	queryDialog			; yes multiple, ask user
	;
	; one matching name, email doesn't match: let user choose to modify
	; matching entry, or to continue editing
	;
	mov	ax, offset UpdateEmailAddrText
	mov	bx, ((CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or (GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE))
	call	createDialogBox
	cmp	ax, IC_YES
	jne	keepEditing			; no overwrite, keep editing
	;
	; modify matching entry with newly entered email
	;
	call	updateEntryWithNewEmail
	mov	cx, matchItem
	mov	di, matchCurOffset
	add	di, mainTableOffset		; make absolute offset
showEntry:
	call	showThisEntry			; display modified entry
	jmp	done

addNewRecord:
	call	AddNewRecord
	jc	done
	test	ds:[recStatus], mask RSF_WARNING
	jnz	done
	mov	cx, ds:[curRecord]		; display new record
	call	showCurEntry
done:
	andnf	ds:[recStatus], not mask RSF_WARNING
	mov	ds:[updateEntry], BB_FALSE
	call	closeNewRecordDialog
keepEditing:
	call	freeNewNameAndEmail
	.leave
	ret

;
; get newly entered name and newly entered email
; return: C set if no name
;
getNewNameAndEmail	label	near
	mov	si, offset NewLastNameField
	call	getTextBlock			; cx = block, ax = len
	mov	newNameHandle, cx
	mov	si, offset NewStaticPhoneSixNumber
	call	getTextBlock			; ^hcx = text, ax = len w/o 0
	mov	newEmailHandle, cx
	inc	ax
	mov	newEmailLength, ax
	tst_clc	newNameHandle
	jnz	gNNAE_done
	stc					; indicate no name
gNNAE_done:
	retn

;
; free newly entered name block and newly entered email block
;
freeNewNameAndEmail	label	near
	mov	bx, newEmailHandle
	tst	bx
	jz	noNewEmailBlock
	call	MemFree
noNewEmailBlock:
	mov	bx, newNameHandle
	tst	bx
	jz	noKeyBlock
	call	MemFree
noKeyBlock:
	retn

;
; close new record dialog
;
closeNewRecordDialog	label	near
	push	bp
	GetResourceHandleNS	NewDialogResource, bx
	mov	si, offset NewRecordDialog
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
	retn

;
; check if new record already exists
; returns: C set if found
;
checkIfNameExists	label	near
	mov	bx, newNameHandle
	call	MemLock
	mov	es, ax				; es:di = key to search
	clr	di
	call	CheckIfRecordExists		; cx = item, dx = curOffset
	mov	matchItem, cx
	mov	matchCurOffset, dx
	call	MemUnlock			; (preserves flags)
	retn

;
; find all matching names starting from known match
; return: es = main table segment
;
findAllMatchingNames	label	near
	;
	; search back from matching entry to see if there are more
	; matching entries
	;
	mov	di, ds:[gmb.GMB_mainTable]
	call	DBLockNO			; lock main table
	mov	di, es:[di]
	mov	mainTableOffset, di
	mov	ax, di				; get abs. end of main table
	add	ax, ds:[gmb.GMB_endOffset]
	mov	endMainTableOffset, ax
	add	di, matchCurOffset		; es:di = match item
	mov	startMatchOffset, di
fAMN_checkPrevEntry:
	sub	di, size TableEntry		; try previous one
	cmp	di, mainTableOffset
	jb	fAMN_gotFirstMatch		; reached beginning
	call	checkTEMatch
	jne	fAMN_gotFirstMatch
	mov	startMatchOffset, di		; found previous match
	jmp	fAMN_checkPrevEntry
fAMN_gotFirstMatch:
	;
	; search forward from matching entry to see if there are more
	; matching entries
	;	es = main table segment
	;
	mov	di, mainTableOffset
	add	di, matchCurOffset
	mov	endMatchOffset, di
fAMN_checkNextEntry:
	add	di, size TableEntry		; try next one
	cmp	di, endMainTableOffset
	jae	fAMN_gotLastMatch			; reached end
	call	checkTEMatch
	jne	fAMN_gotLastMatch
	mov	endMatchOffset, di		; found next match
	jmp	fAMN_checkNextEntry
fAMN_gotLastMatch:
	retn

;
; check if name entry matches
;	es:di = TableEntry
;	ds = dgroup
;
checkTEMatch	label	near
	push	es, di
	mov	di, es:[di].TE_item
	call	DBLockNO			; *es:di = DB_record
	mov	di, es:[di]
	add	di, size DB_Record		; es:di = name
	push	ds
	mov	bx, newNameHandle		; (non-zero)
	call	MemLock
	mov	ds, ax
	clr	si, cx
	call	LocalCmpStrings
	call	MemUnlock			; (preserves flags)
	pop	ds
	call	DBUnlock
	pop	es, di
	retn

;
; show entry
; pass: cx = DB item to show
;	di = absolute offset in main table of item to show
;
showThisEntry	label	near
	sub	di, mainTableOffset		; make relative offset
	mov	ds:[curOffset], di
showCurEntry	label	near
	mov	si, cx
	mov	ds:[curRecord], 0
	push	bp
	call	DisplayCurRecord
	andnf	ds:[searchFlag], not mask SOF_NEW
	call	UpdateNameList
	call	EnableCopyRecord
	pop	bp
	retn

;
; update existing record with new email
; pass: matchItem = matching entry
;	newEmailHandle = newly entered email
;	ds = dgroup
; return: C set if entry updated
;
updateEntryWithNewEmail	label	near
	mov	bx, newEmailHandle
	tst	bx
	jnz	uE_gotNewEmail
	retn					; exit with C clear

uE_gotNewEmail:
	mov	di, matchItem
	call	DBLockNO			; *es:di = matching entry
	mov	di, es:[di]
	mov	si, di				; si = DB_Record offset
	mov	cx, es:[di].DBR_noPhoneNo
	add	di, es:[di].DBR_toPhone
uE_phoneLoop:
	cmp	es:[di].PE_type, PTI_EMAIL
	je	uE_foundEmail
	add	di, es:[di].PE_length
	add	di, size PhoneEntry
	loop	uE_phoneLoop
	call	DBUnlock			; couldn't find PTI_EMAIL?!
	clc					; no change to entry
	retn

uE_foundEmail:
	add	di, size PhoneEntry		; es:di = email name
	mov	dx, di				; dx = email abs. offset
	mov	bx, es:[di-(size PhoneEntry)].PE_length	; bx = current length
	mov	cx, newEmailLength		; cx = new length
	cmp	cx, bx
	je	uE_copyEmail
	mov	di, matchItem			; di = DB item
	pushf
	sub	dx, si				; dx = rel off to insert/delete
	call	DBUnlock
	popf
	ja	uE_insertSpace
	sub	bx, cx				; bx = bytes to delete
	mov	cx, bx				; cx = bytes to delete
	call	DBDeleteAtNO
	jmp	uE_insertDelete

uE_insertSpace:
	sub	cx, bx				; cx = bytes to insert
	call	DBInsertAtNO
uE_insertDelete:
	call	DBLockNO			; rederef. item
	mov	di, es:[di]
	add	di, dx				; es:di = email abs. offset
uE_copyEmail:
	mov	bx, newEmailHandle
	call	MemLock
	push	ds
	mov	ds, ax				; ds:si = new email
	clr	si
	mov	ax, newEmailLength
	mov	es:[di-(size PhoneEntry)].PE_length, ax	; store new length
	LocalCopyString				; copy in new email addr.
	pop	ds
	call	DBDirty				; dirty update phone record
	call	DBUnlock			; unlock it
	call	MemUnlock			; unlock new email block
	stc					; indicate success
	retn

;
; get text block
;
getTextBlock	label	near
	GetResourceHandleNS	NewDialogResource, bx
	clr	dx
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	di, mask MF_CALL
	call	ObjMessage			; ^hcx = text
	retn

;
; pass: cx = record item to check
;	ds = dgroup
; return: carry set if match
; destroys: ax, bx, ds, si
;
compareEmail	label	near
	push	cx, es, di
	mov	bx, newEmailHandle
	tst_clc	bx
	jz	cE_done
	mov	di, cx
	call	DBLockNO
	mov	di, es:[di]			; *es:di = record
	mov	cx, es:[di].DBR_noPhoneNo	; cx = # phones
	add	di, es:[di].DBR_toPhone		; es:di = PhoneEntry
cE_phoneLoop:
	cmp	es:[di].PE_type, PTI_EMAIL
	jne	cE_checkNextPhone
	push	ds, di
	add	di, size PhoneEntry		; es:di = entry's email
	call	MemLock
	mov	ds, ax				; ds:si = new email
	clr	si, cx
	call	LocalCmpStrings
	call	MemUnlock			; unlock email (saves flags)
	pop	ds, di
	stc					; assume match
	je	cE_unlockDone
	clc					; else, no match
	jmp	cE_unlockDone

cE_checkNextPhone:
	add	di, es:[di].PE_length
	add	di, size PhoneEntry
	loop	cE_phoneLoop
cE_unlockDone:
	call	DBUnlock			; unlock data (preserves flags)
cE_done:
	pop	cx, es, di
	retn

;
; pass: ax = string chunk in TextResource
; bx = CustomDialogBoxFlags
; return: ax = InteractionCommand
;
createDialogBox	label	near
	push	bx, ds, si, bp
	push	ax, bx
	GetResourceHandleNS	TextResource, bx
	call	MemLock
	mov	ds, ax
	pop	si, bx
	mov	si, ds:[si]
	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customTriggers.segment, cs  ; only if needed
	mov	ss:[bp].SDP_customTriggers.offset, offset newEntryAlreadyExistsTriggerTable
	mov	ss:[bp].SDP_customFlags, bx
	mov	ss:[bp].SDP_customString.segment, ds
	mov	ss:[bp].SDP_customString.offset, si
	movdw	ss:[bp].SDP_stringArg1, 0
	movdw	ss:[bp].SDP_stringArg2, 0
	movdw	ss:[bp].SDP_helpContext, 0
	call	UserStandardDialog
	GetResourceHandleNS	TextResource, bx
	call	MemUnlock
	pop	bx, ds, si, bp
	retn

newEntryAlreadyExistsTriggerTable	label	StandardDialogResponseTriggerTable
	word 2		; num triggers
	StandardDialogResponseTriggerEntry <
		NewEntryWarningCreate,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		NewEntryWarningChange,
		IC_NO
	>

RolodexNewCreate	endm

RolodexNewCancel	method	dynamic GeoDexClass, MSG_ROLODEX_NEW_CANCEL
	mov	ds:[updateEntry], BB_FALSE
	ret
RolodexNewCancel	endm

endif  ; GPC


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexNotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up the Notes dialog box.

CALLED BY:	UI (=MSG_ROLODEX_NOTES)

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexNotes	method	GeoDexClass, MSG_ROLODEX_NOTES
	mov	si, offset NotesBox 	; bx:si - OD of Notes Box
	GetResourceHandleNS	NotesBox, bx	
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_FIXUP_DS	
	mov	dl, VUM_NOW		; do it right now
	call	ObjMessage		; make the window usable

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage		; display the window
	ret
RolodexNotes	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexSaveAfterNoteEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive this message when the close trigger on the
		notes dialog is pressed.  After the notes field has
		been edited, this routine will save the record to
		the database and then dismiss the dialog.

CALLED BY:	MSG_ROLODEX_SAVE_AFTER_NOTE_EDIT
PASS:		nothing
RETURN:		nothing
fDESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	5/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexSaveAfterNoteEdit	method NotesDialogClass, 
					MSG_ROLODEX_SAVE_AFTER_NOTE_EDIT

	push	ds, si
	GetResourceSegmentNS dgroup, ds
	call	SaveCurRecord
ifdef GPC
	call	UpdateNoteIcon
endif
	pop	ds, si

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	GOTO	ObjCallInstanceNoLock

RolodexSaveAfterNoteEdit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveCurRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves out the current record if changed or just created.

CALLED BY:	UTILITY

PASS:		ds - segment addr of core block
		curRecord - current record handle

RETURN:		carry set if error returned in MemAlloc

DESTROYED:	ax, bx, cx, dx, si, di, bp, es 

PSEUDO CODE/STRATEGY:
	If current record modified	{
		If this record has been created but not inserted {
			Update the record
			If index field modified	{
				Delete the old entry
			}
			And re-insert the new one
			exit
		}
		Else {
			Create a new record 
			Insert this record
			exit
		}
	}
	Else	exit
			
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveCurRecord	proc	far
	mov	di, ds:[undoItem]	; di - handle of record to be deleted
	tst	di			; was there any record to be deleted?
	je	undoNothing		; if not, skip
	call	NewDBFree		; delete it!
	clr	ds:[undoItem]		; nothing to delete
undoNothing:

	mov	cx, NUM_TEXT_EDIT_FIELDS+1  ; cx - number of fields to read in
	clr	di			; di - offset to FieldTable
	call	GetRecord		; if so, read in only changed fields

	tst	ds:[curRecord]		; was this record already inserted? 
	jne	setFlag			; if so, skip

	test	ds:[recStatus], mask RSF_EMPTY	; was it an empty record?
	jne	exit			; if it was, exit
setFlag:
	andnf	ds:[recStatus], not mask RSF_WARNING ; warning box was not on
	test	ds:[recStatus], mask RSF_SORT_EMPTY ; index field empty?
	jne	warningBox		; if so, put up a warning box

	mov	bx, NUM_TEXT_EDIT_FIELDS+1  ; cx - number of fields to compare

	clr	bp			; bp - offset into FieldTable
	call	CompareRecord		; is this record modified?
	LONG je	notModified		; if not, check to see if created

	tst	ds:[curRecord]		; new record?
	je	newRecord		; if so, skip to handle it
	clr	ax			; update everything
	call	UpdateRecord		; add the changes to database
	jc	error			; if carry set, exit

	test	ds:[recStatus], mask RSF_NEW	; new record?
	jne	insert			; if so, skip to insert

NPZ <	test	ds:[dirtyFields], mask DFF_INDEX ; is index field modified?>
PZ <	test	ds:[dirtyFields], mask DFF_INDEX or mask DFF_PHONETIC      >
PZ <					; is index/phonetic field modified?>

	LONG je	updateQuick		; if not, exit
delete:
	ornf	ds:[phoneFlag], mask PF_SAVE_RECORD  ; delete all phone entries
if _QUICK_DIAL
	call	DeleteQuickDial	; delete cur rec from quick dial tables
	jc	error			; exit if error
endif ;if _QUICK_DIAL

	call	DeleteFromMainTable	; delete the record from main table
	jmp	short	insert		; insert it back into quick table
newRecord:
	clr	ax			; update everything
	call	InitRecord		; create a new record and initialize
	jc	error			; if carry set, exit
insert:
	call	InsertRecord		; insert it into database
insert2:
if _QUICK_DIAL
	call	InsertAllQuickViewEntry	; insert it back into quick table
endif ;if _QUICK_DIAL

if _QUICK_DIAL
	call	UpdateMonikers		; update the monikers
	jc	error
	call	UpdateQuickDialMenu	; dis/enable the quick dial button
endif ;if _QUICK_DIAL
	andnf	ds:[phoneFlag], not mask PF_SAVE_RECORD ; clear save record flag
exit:
	clc				; exit with carry clear
error:
	ret

warningBox:
	mov	cx, NUM_TEXT_EDIT_FIELDS+1	; cx - number of fields
	clr	bp			; bp - offset to table of field hanldes
	call	FreeMemChunks	; delete all the memory blocks
	test	ds:[recStatus], mask RSF_FILE_SAVE ; called by FileSave?
	jne	error			; if so, exit (C clear)
	call	HandleWarningBox	; put up a warning box
	;
	; if index field empty, set focus to index field
	;
	test	ds:[recStatus], mask RSF_SORT_EMPTY
	jz	noFocusChange
	push	ax			; save InteractionCommand
	GetResourceHandleNS	LastNameField, bx
	mov	si, offset LastNameField
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	ax			; ax = InteractionCommand
noFocusChange:
	clc				; no mem error, returns AX = IC_*
	jmp	short	error		; quit
notModified:
	test	ds:[recStatus], mask RSF_NEW	; new record?
	jne	insert			; if so, insert it
	cmp	ds:[undoAction], UNDO_CHANGE	; record modified through udno?
	jge	delete			; if so, delete and re-insert it

	mov	cx, NUM_TEXT_EDIT_FIELDS+1	; cx - number of fields
	clr	bp			; bp - offset to table of field hanldes
	call	FreeMemChunks	; delete all the memory blocks
	jmp	exit
updateQuick:
	call	UpdateMain		; update the main table
	ornf	ds:[phoneFlag], mask PF_SAVE_RECORD  ; delete all phone entries
if _QUICK_DIAL
	call	DeleteQuickDial	; delete cur rec from quick dial tables
	jc	error			; exit if error
endif ;if _QUICK_DIAL
	jmp	insert2
SaveCurRecord	endp

if _QUICK_DIAL

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateQuickDialMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables or enables the quick dial button in card view or
		in browse view.

CALLED BY:	SaveCurRecord

PASS:		gmb.GMB_numFreqTab - number of entries in frequency table
		displayStatus - tells you which view is up

RETURN:		nothing

DESTROYED:	ax, bx, dx, si, di

PSEUDO CODE/STRATEGY:
	If there is a phone entry 
		enable QuickDial
	else	if card view up
		disable QuickDial

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateQuickDialMenu	proc	near
	mov	dx, ds:[gmb.GMB_numFreqTab]	; dx - number of entries in freq table
	add	dx, ds:[gmb.GMB_numHistTab]	; add number of entries in hist table 

	tst	dx			; are quick dial tables empty?
	je	disable			; if so, exit

	GetResourceHandleNS	QuickDial, bx
	mov	si, offset QuickDial	; bx:si - OD of quick dial button
	call	EnableObject		; enable this button
	jmp	short	exit
disable:
	GetResourceHandleNS	QuickDial, bx
	mov	si, offset QuickDial	; bx:si - OD of quick dial button
	call	DisableObject		; disable quick dial button
exit:
	ret
UpdateQuickDialMenu	endp

endif ;if _QUICK_DIAL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleWarningBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts up the warning box when index field is empty.

CALLED BY:	SaveCurRecord

PASS:		recStatus - various record flags

RETURN:		ax - OK or CANCEL depending on which option is chosen
		carry set if error found

DESTROYED:	ax, bx, cx, si, bp

PSEUDO CODE/STRATEGY:
	If not called by 'RolodexDelete'
		Put up the warning box
		If CANCEL
			Clear the reocrd
		Delele all the memory chunks
	Else exit

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleWarningBox	proc	near
	mov	ax, IC_YES		; assume YES
	test	ds:[recStatus], mask RSF_DELETE	; is this called by delete?
	jne	boxUp			; if so, don't put it up

	cmp	ds:[displayStatus], BROWSE_VIEW	; are we in browse mode?
	jne	skip			; if not, skip

	mov	bp, ERROR_IN_BROWSE_MODE; bp - error message flag
	call	DisplayErrorBox		; put up a warning box
	push	ax
	jmp	short	cancel

skip:
	mov	bp, ERROR_INDEX_FIELD	; bp - error message flag
	call	DisplayErrorBox		; put up a warning box
	ornf	ds:[recStatus], mask RSF_WARNING ; warning box is on
boxUp:
	push	ax			; save the return value
	cmp	ax, IC_NULL		; is DB terminated by the system?
	stc
	LONG	je	exit		; if so, exit
	cmp	ax, IC_YES		; is YES button pressed?
	jne	cancel			; if not, skip
	call	DisableUndo		; disable undo menu 
	jmp	quit
cancel:
	mov	di, ds:[curRecord]	; di - record handle to delete
	tst	di			;
	LONG	je	clear

EC <	cmp	ds:[undoAction], UNDO_CHANGE	; was undo done?	>
EC <	je	delete			; if so, don't do error check	>
EC <	tst	ds:[gmb.GMB_orgRecord]		; is phone number modified?	>
EC <	jne	delete			; if not, do error check	>	
EC <	tst	ds:[gmb.GMB_numMainTab]		; is database empty?		>
EC <	je	delete			; if so, skip			>
EC <									>
EC <	push	ax, bx, cx, dx, es, ds, bp, di, si			>
EC < 	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table	>
EC <	call	DBLockNO						>
EC <	mov	si, es:[di]		; si - points to beg of main table >
EC <	add	si, ds:[curOffset]					>
if DBCS_PCGEOS

EC <	push	{wchar} es:[si].TE_key[2]				>
EC <	push	{wchar} es:[si].TE_key[0]				>
EC <	mov	di, bx			; di - handle of DBBlock	>
EC <	call	DBLockNO						>
EC <	mov	di, es:[di]						>
EC <	add	di, size DB_Record	; es:di - ptr to index field	>
EC <	push	ax							>
EC <	mov	cx, {wchar} es:[di]	; cx - 1st character		>
EC <	mov	dx, {wchar} es:[di+2]	; bx - get the next character	>
EC <	call	DBUnlock						>
EC <	pop	ax			; retrive 1st char		>
EC <	pop	bx							>
EC <	cmp	cx, ax			; compare the 1st character	>
EC <	ERROR_NE  SORT_BUFFER_IS_NOT_CURRENT				>
EC <nextChar::								>
EC <	cmp	dx, bx			; compare the 2nd character	>
EC <	ERROR_NE  SORT_BUFFER_IS_NOT_CURRENT				>

else
EC <	mov	ax, es:[si].TE_key	; ax - 1st two letters of last name >
EC <	mov	bx, es:[si].TE_item	; bx - handle of DBBlock	>
EC <	call	DBUnlock						>
EC <	mov	di, bx			; di - handle of DBBlock	>
EC <	call	DBLockNO						>
EC <	mov	di, es:[di]						>
EC <	add	di, size DB_Record	; es:di - ptr to index field	>
EC <	push	ax							>
EC <	mov	al, es:[di]		; bh - 1st character		>
EC <	mov	bh, al			; bh - 1st character		>
EC <	mov	al, es:[di+1]		; bl - get the next character	>
EC <	mov	bl, al			; bl - 2nd character		>
EC <	pop	ax							>
EC <	call	DBUnlock						>
EC <	cmp	bh, ah			; compare the 1st character	>
EC <	je	nextChar		; if equal, check the next char	>
EC <	ERROR	SORT_BUFFER_IS_NOT_CURRENT				>
EC <nextChar:								>
EC <	cmp	bl, al			; compare the 2nd character	>
EC <	je	done			; if equal, no error		>
EC <	ERROR	SORT_BUFFER_IS_NOT_CURRENT				>
EC <done:								>
endif
EC <	pop	ax, bx, cx, dx, es, ds, bp, di, si			>
EC <delete:								>

	call	NewDBFree		; delete this record
	test	ds:[recStatus], mask RSF_NEW	; is this record inserted?
	jne	new			; if not, skip
if _QUICK_DIAL
	call	DeleteQuickDial	; delete cur rec from quick dial tables
	jc	exit			; exit if error

	call	UpdateMonikers		; update the monikers
	jc	exit			; exit if error
endif ;if _QUICK_DIAL

	call	DeleteFromMainTable	; delete the record from main table
new:
	clr	ds:[curRecord]		; no record to display
	call	DisableUndo		; no undoable action exists
clear:
	call	ClearRecord		; if CANCEL, clear the record
	mov	ds:[recStatus], mask RSF_NEW or mask RSF_EMPTY or \
		mask RSF_WARNING	; set flags
	call	DisableCopyRecord	; fix up some menu
quit:
	clc				; exit with carry clear
exit:
	pop	ax			; restore the return value
	ret
HandleWarningBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateLetterButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the letter button so it reflects the currently
		displayed record.

CALLED BY:	DisplayCurRecLow

PASS:		sortBuffer - index field text string of current record

RETURN:		curLetter - updated

DESTROYED:	ax, bx, cx, dx, si, di, bp

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	9/21/89		Initial version
	witt	1/22/94 	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateLetterButton	proc	far

	; first check to see if 'sortBuffer' is empty

SBCS<	mov	al, {char} ds:[sortBuffer]				>
DBCS<	mov	ax, {wchar} ds:[sortBuffer]				>
	LocalIsNull	ax		; is sortBuffer empty?
	je	exit			; if so, exit

	; copy the string into 'curLetter' after getting the lexical value

	clr	si			
	mov	cx, MAX_TAB_LETTER_LENGTH-1 ; cx - number of characters to copy
copyLoop:
SBCS <	mov	al, ds:sortBuffer[si]	; al - get a char from 'sortBuffer'>
DBCS <	mov	ax, {wchar} ds:sortBuffer[si]; ax - get a char

	LocalIsNull	ax		; end of string?
	je	done

if PZ_PCGEOS
	call	GetPizzaLexicalValue
	cmp	ax, C_FULLWIDTH_LATIN_CAPITAL_LETTER_A ; Is this alphabet?
	jne	skip
	mov	ax, 'A'			; clear high byte. -> 'A'
skip:
endif
	call	GetLexicalValue		; get lexical value of this character

SBCS <	mov	ds:curLetter[si], al	; save it in 'curLetter'	>
DBCS <	mov	{wchar} ds:curLetter[si], ax; save it in 'curLetter'	>
	LocalNextChar	dssi
	loop	copyLoop		; get next character

done:
	LocalClrChar	ds:curLetter[si] ; save null terminator in curLetter
	test	ds:[recStatus], mask RSF_FIND_LETTER ; called by FindLetter?
	jne	exit			; if so, exit

	; first clear the old letter tab that has been inverted

	mov	si, offset MyLetters	; bx:si - OD of MyLetters
	GetResourceHandleNS	MyLetters, bx	
	mov	ax, MSG_LETTERS_CLEAR	
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage		; invert the letter tab

	; now invert the new letter tab

	push	es
	call	SearchCharSetTable	; find out which letter to invert
	pop	es
	mov	dl, cl			; cl - letter tab index
	mov	cx, ds:[gmb.GMB_numMainTab]	; cx - num. of records in database
	mov	si, offset MyLetters	; bx:si - OD of MyLetters
	GetResourceHandleNS	MyLetters, bx	
	clr	bp			; bp - create a new gState 
	mov	ax, MSG_LETTERS_INVERT	
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage		; invert the letter tab
exit:
	ret
UpdateLetterButton	endp

ifdef GPC
UpdatePrevNext	proc	far
 	;
 	; update next status
	;
 	mov	ax, ds:[curOffset]
 	add	ax, size TableEntry
 	cmp	ax, ds:[gmb.GMB_endOffset]
 	mov	ax, MSG_GEN_SET_ENABLED
 	jb	gotNext
 	mov	ax, MSG_GEN_SET_NOT_ENABLED
gotNext:
 	mov	dl, VUM_NOW
 	GetResourceHandleNS	NextTrigger, bx
 	mov	si, offset NextTrigger
 	mov	di, mask MF_FIXUP_DS
 	call	ObjMessage
 	;
 	; update prev status
 	;
 	mov	ax, ds:[curOffset]
 	tst	ax
 	mov	ax, MSG_GEN_SET_ENABLED
 	jnz	gotPrev
 	mov	ax, MSG_GEN_SET_NOT_ENABLED
gotPrev:
 	mov	dl, VUM_NOW
 	GetResourceHandleNS	PreviousTrigger, bx
 	mov	si, offset PreviousTrigger
 	mov	di, mask MF_FIXUP_DS
 	call	ObjMessage
 	ret
UpdatePrevNext	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchCharSetTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the character set table to find out which letter 
		to invert.

CALLED BY:	UpdateLetterButton

PASS:		curLetter - letter tab string being searched

RETURN:		curCharSet - updated
		cl - letter tab index

DESTROYED:	bx, dx, si, di, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	THIS CODE ASSUMES THAT THE '*' IS ALWAYS PRESENT IN THE LAST
	CHARACTER SET.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchCharSetTable	proc	near	uses	ax
	.enter
	GetResourceHandleNS	TextResource, bx
	call	MemLock				; lock the block w/ char set
	mov	es, ax				; set up the segment
	mov	di, offset LetterTabCharSetTable
	mov	di, es:[di]			; dereference the handle

	; first, search the current character set

	call	SearchCharSet
	je	skip

	tst	ds:[charSetChanged]
	LONG	je	exit	
	call	ChangeCharSet
	clr	ds:[charSetChanged]		; clear the flag
	jmp	exit
skip:
	cmp	ds:[numCharSet], 1		; only one character set used?
	jne	next	 			; if not, search the next set

EC <	tst	ds:[starTabID]					>
EC <	ERROR_S	CHAR_NOT_FOUND_IN_CHAR_SET_TABLES		>
SBCS <	mov	ds:[curLetter], '*'				>
SBCS <	mov	ds:[curLetter+1], 0				>
DBCS <	mov	{wchar} ds:[curLetter], '*'			>
DBCS <	LocalClrChar	ds:[curLetter+2]			>
	mov	cx, ds:[starTabID]
next:
	; if not found, search the previous character set
	; but first clear any inverted letter tab 

	push	di
	mov	si, offset MyLetters		; bx:si - OD of Letters gadget 
	GetResourceHandleNS	MyLetters, bx
	mov	ax, MSG_LETTERS_CLEAR
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage			; clear inverted letter tab

	clr	cx				; create a gState
	mov	dl, ds:[curCharSet]		; dl - current char set index 
	mov	dh, C_WHITE			; dh - ColorIndex
	mov	si, offset MyLetters
	GetResourceHandleNS	MyLetters, bx	; OD of MyLetters
	mov	ax, MSG_DRAW_LETTER_TABS	
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage			; clear all letter tabs
	pop	di

	; now check the other character set
	; THIS CODE ASSUMES THAT MAXIMUM NUMBER OF CHAR SET IS TWO
CheckHack <MAX_LETTER_TAB_SETS eq 2>

	tst	ds:[curCharSet]			; is current char set 1st set? 
	jne	skip1				; if so, skip

	inc	ds:[curCharSet]			; curCharSet <- 1
	jmp	common1
skip1:
	clr	ds:[curCharSet]			; check the other set
common1:
	call	SearchCharSet
	jne	found

EC <	tst	ds:[starTabID]					>
EC <	ERROR_S	CHAR_NOT_FOUND_IN_CHAR_SET_TABLES		>
SBCS <	mov	ds:[curLetter], '*'				>
SBCS <	mov	ds:[curLetter+1], 0				>
DBCS <	mov	{wchar} ds:[curLetter], '*'			>
DBCS <	LocalClrChar	ds:[curLetter+2]			>
	mov	cx, ds:[starTabID]
found:
	push	cx
	clr	cx				; create a gState 
	mov	dl, ds:[curCharSet]		; dl - current character set
	mov	dh, C_RED			; dh - ColorIndex
	mov	si, offset MyLetters
	GetResourceHandleNS	MyLetters, bx	; OD of MyLetters
	mov	ax, MSG_DRAW_LETTER_TABS	
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage			; draw the new character set
	pop	cx
exit:
	GetResourceHandleNS	TextResource, bx
	call	MemUnlock			; unlock the block
	.leave
	ret
SearchCharSetTable	endp


ChangeCharSet	proc	near	uses	di
	.enter
CheckHack <MAX_LETTER_TAB_SETS eq 2>

	mov	si, offset MyLetters		; bx:si - OD of Letters gadget 
	GetResourceHandleNS	MyLetters, bx
	mov	ax, MSG_LETTERS_CLEAR
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage			; clear inverted letter tab

	clr	cx				; create a gState
	mov	dl, ds:[curCharSet]		; dl - current char set index 
	tst	dl 
	je	nextSet
	clr	dl
	jmp	draw
nextSet:
	mov	dl, 1
draw:
	mov	dh, C_WHITE			; dh - ColorIndex
	mov	si, offset MyLetters
	GetResourceHandleNS	MyLetters, bx	; OD of MyLetters
	mov	ax, MSG_DRAW_LETTER_TABS	
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage			; clear all letter tabs

	clr	cx				; create a gState 
	mov	dl, ds:[curCharSet]		; dl - current character set
	mov	dh, C_RED			; dh - ColorIndex
	mov	si, offset MyLetters
	GetResourceHandleNS	MyLetters, bx	; OD of MyLetters
	mov	ax, MSG_DRAW_LETTER_TABS	
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage			; draw the new character set

	.leave
	ret
ChangeCharSet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchCharSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for a given character in a given character set. 

CALLED BY:	SearchCharSetTable

PASS:		ds:[curCharSet] - current character set
		es:di - pointer to table of lptrs for character strings
		ds:curLetter - letter tab string to search for

RETURN:		zero flag set if the letter is not found
		zero flag cleared if the letter is found
		cl - index to character set for the character found
			(cl = 0 if not found, use ds:starTabID)
		ds:starTabID - index where wildcard "*" is located.
		ds:curLetter - updated
		ds:curLetterLen

DESTROYED:	ax, dx, si

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		es:di is usually passed as LetterTabCharSetTable.
		Does _not_ assume letter tabs are in order - A Good Thing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version
	witt	2/94		DBCS-ized, clean up for LocalXxx funcs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchCharSet	proc	near	uses	di

	curLetterID	local	word
	curLetterPtr	local	word
	letterFound	local	byte		; boolean flag
	.enter

	; initialize some variables

	mov	letterFound, FALSE
	clr	ds:[curLetterLen]
	mov	ds:[starTabID], -1		; not found in this set yet
	clr	cx				; cx - index into character set 
	clr	dh
	mov	dl, ds:[curCharSet]		; dx - index into CharSetTable 

	; locate the current character set

	shl	dx, 1				; multiply by two
	add	di, dx				; go to the correct CharSet
	mov	di, es:[di]			; chunk handle => di
	mov	di, es:[di]			; dereference the handle

	mov	si, offset ds:curLetter		; ds:si - "to match" buffer

	; now loop within the character set until we find a match
	;  (note: within loop si is preserved)
charLoop:
	push	di, cx
	shl	cx, 1				; di is array of nptrs (*2)
	add	di, cx				; go to the correct character
	mov	di, es:[di]			; chunk handle => di
	mov	di, es:[di]			; string in ES:DI

	; check to see if this is '*'

	LocalGetChar	ax, esdi, noAdvance
	LocalCmpChar	ax, '*'

	jne	notStar
	pop	cx				; cx - index into lptrs
	mov	ds:[starTabID], cx		; save the letter ID of '*'
	mov	ds:[curLetterLen], 1
	push	cx
notStar:
	; compare string in 'curLetter' buffer (ds:si) with the one in
	;  current character set (es:di)
						; strlen( es:di )
	call	LocalStringLength		; cx - length of string (w/o NULL)
	call	LocalCmpStringsNoCase		; compare the strings
	je	found				; if match, remember where.
next:
	pop	di, cx
	inc	cx				; next letter tab
	cmp	cx, MAX_NUM_OF_LETTER_TABS	; are we done? 
	jne	charLoop			; if not, check the next char
	jmp	finishUp

	; The first letters of the letter tab matches caller's string, so
	;  remember where the match is.  Continue searching for better match.
	;	cx = length, ds:si - callers "to match" string
found:
	mov	letterFound, TRUE
	inc	cx
	cmp	cx, ds:[curLetterLen]		; matches less than last time?
	jle	next				; Yes, don't remeber thie one.
	mov	ds:[curLetterLen], cx		; save len of latest match
	mov	curLetterPtr, di		; save ptr to latest match
	pop	cx
	mov	curLetterID, cx			; save letter ID
	push	cx				; continue search for..
	jmp	next				;  maybe better match!

	; If there was a match
finishUp:
	tst	letterFound
	jne	skip
	clr	ds:[curLetterLen]
skip:
	mov	cx, ds:[curLetterLen]
	tst	cx				; set flags as return value
	je	quit

	mov	di, curLetterPtr		; es:di - source buffer
	mov	si, offset ds:curLetter		; ds:si - dest buffer
copyLoop:
	LocalGetChar	ax, esdi		; best matching letter tab
	LocalPutChar	dssi, ax		;  to global buffer
	loop	copyLoop
	
	mov	cx, curLetterID
	tst	ds:[curLetterLen]		; set flags as return value
quit:
	.leave
	ret
SearchCharSet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if any of the text edit fields
		have been changed.

CALLED BY:	SaveCurRecord

PASS:		bx - number of text edit fields to check
		bp - offset into FieldTable (TEFO_xxx)

RETURN:		zero flag set if any of the text fields is modified
		zero flag cleared otherwise
		dirtyFields - tells which text edit field is modified

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	For each text edit field
		call MSG_VIS_TEXT_GET_USER_MODIFIED 
		if modified
			set a flag for this edit field
			update 'dirtyFields'
	Check the next text edit field

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/31/89	Initial version
	Ted	11/9/89		Returns 'dirtyFields'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareRecord	proc	far
	clr	ds:[dirtyFields]	; clear the flag
mainLoop:
	push	bx			; save number of fields to check for
	mov	si, ds:FieldTable[bp]	; si - offset to text field 

	; load BX with correct resource handle



	GetResourceHandleNS	Interface, bx

	cmp	bp, TEFO_NOTE		; is this note the field?
	jne	notNoteText		; if not, skip
	GetResourceHandleNS	WindowResource, bx
notNoteText:
	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	
	call	ObjMessage		; returns cx with status
	pop	bx			; restore number of fields to check
	tst	cx			; is it modified?
	jne	modified		; if so, set the flag for this field
next:
	add	bp, (size word)		; if not, 
	dec	bx			; update the pointers
	jnz	mainLoop		; check for next text field
ifdef GPC
	call	checkPhoneFields
endif

	tst	ds:[dirtyFields]	; if done, any text fields changed?
	ret				; return with the zero flag
modified:
	mov	cx, bx			; cx - number of fields to check for
	mov	ax, 1	
	shl	ax, cl			; ax - flag set for modified field
	or	ds:[dirtyFields], al	; update the flag for dirty fields
	jmp	next			; check the next text field

ifdef GPC
checkPhoneFields	label	near
	;
	; check dirty phone number (loop?!?, you loop!)
	;
	GetResourceHandleNS	Interface, bx
	mov	si, offset StaticPhoneOneNumber
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneTwoNumber
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneThreeNumber
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneFourNumber
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneFiveNumber
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneSixNumber
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneSevenNumber
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneSevenName
	call	checkPhoneField
	jc	phoneDirty

if _NDO2000			
	mov	si, offset StaticPhoneOneName
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneTwoName
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneThreeName
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneFourName
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneFiveName
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneSixName
	call	checkPhoneField
	jc	phoneDirty
	mov	si, offset StaticPhoneSevenName
	call	checkPhoneField
	jc	phoneDirty
endif
	retn

phoneDirty:
	ornf	ds:[dirtyFields], mask DFF_PHONE_NO
	retn

checkPhoneField	label	near
	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	tst_clc	cx
	jz	phoneClean
	stc
phoneClean:
	retn
endif
CompareRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexEnableDisableCalendarButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	En{Dis}ables calendar button.

CALLED BY:	(GLOBAL) MSG_META_NOTIFY_WITH_DATA_BLOCK	

PASS:		cx:dx - NotificationType 
		bp - handle of data block 

RETURN:		nothing

DESTROYED:	nothing	

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexEnableDisableCalendarButton	method	RolodexClass, 
				MSG_META_NOTIFY_WITH_DATA_BLOCK 	

	; check to make sure it is the right notification type

	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	quit
	cmp	dx, GWNT_SELECT_STATE_CHANGE
	jne	quit

	; up the reference count and lock the data block

	push	ax, cx, dx, bp, ds, si, es
	mov	bx, bp
	tst	bx
	je	exit		; don't do anything if no block handle	
	push	bx
	call	MemLock
	mov	es, ax		; es - NotifySelectStateChange

	; check to see if any text has been selected 

	mov	ax, MSG_GEN_SET_NOT_ENABLED 	; disable the trigger
	cmp	es:[NSSC_clipboardableSelection], FALSE
	je	common
	mov	ax, MSG_GEN_SET_ENABLED		; enable the trigger
common:
	; enable or disable the calendar button

	GetResourceHandleNS	CalendarTrigger, bx
	mov	si, offset CalendarTrigger	; OD => BX:SI
	mov	di, mask MF_FIXUP_DS
	mov	dl, VUM_NOW			; do it now
	call	ObjMessage

	; unlock the data block and decrement the reference count

	pop	bx
	call	MemUnlock
exit:
	; call super class

	pop	ax, cx, dx, bp, ds, si, es
quit:
	mov	di, offset RolodexClass
	call	ObjCallSuperNoLock
	ret
RolodexEnableDisableCalendarButton	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RespondCalendarRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Responds to calendar's request for searching.	

CALLED BY:	Calendar

PASS:		cx - length of string to search for
		dx - handle of data block that contains the string

RETURN:		Address Book will grab the focus

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

PSEUDO CODE/STRATEGY:
	Search the database for possible match
	Grab the focus
	If a match found 
		display the 1st record with the match
		if both view up 
			change moniker from "Lookup" to "Find Next"
			copy text string to filter field
			enable "Clear Search" button
		endif
	Endif
			
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RespondCalendarRequest	method	GeoDexClass, MSG_ROLODEX_REQUEST_SEARCH

	push	dx, cx

	; check to see if we are in INTRODUCTORY level

	GetResourceHandleNS	RolodexApp, bx
	mov	si, offset RolodexApp
	mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	; if INTRODUCTORY level, there is no search feature

ifndef GPC  ; allow to all levels to avoid problems where Address Book and
	; Calendar are at different levels
	cmp	dx, UIIL_INTRODUCTORY
	LONG	je	error		; just exit
endif

	;
	; Bring ourselves to the fore in a way that ensures nice transfer
	; of target & focus, and de-iconifies our primary, too.
	; 
	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	call	UserCallApplication
	
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	UserCallApplication

	cmp	ds:[displayStatus], DISABLED_VIEW	; is data file open?
	je	error3			; if not, put up an error box 

	call	SaveCurRecord		; update the record if necessary
	jc	error			; exit if error

	call	DisableUndo		; no undoable action exists

	tst	ds:[gmb.GMB_numMainTab]		; is data file empty?
	je	error2			; if so, skip

	test	ds:[recStatus], mask RSF_WARNING ; was warning box up?
	jne	error			; if so, exit

	ornf	ds:[searchFlag], mask SOF_NEW or \
			mask SOF_CAL_SEARCH	; clear the filter table flag
	pop	bx, cx

	; create the classed event

	call	MemLock				; lock the data block
	push	bx
	mov	dx, ax				; dx:bp - ptr to string
	clr	bp			
	clr	cx				; cx - null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_RECORD
	call	ObjMessage			; event handle => DI

	; bring up the search dialog box

	push	di
	GetResourceHandleNS	RolodexSearchControl, bx
	mov	si, offset RolodexSearchControl	; bx:si - OD of SearchControl
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; send it!!

	; send the event handle to the search controller

	pop	bp				; bp - event handle
	mov	ax, MSG_SRC_SEND_EVENT_TO_SEARCH_TEXT
	clr	di 
	call	ObjMessage			; send it!!

	; initiate forward search

	mov	ax, MSG_SRC_FIND_NEXT
	mov	di, mask MF_CALL
	call	ObjMessage			; send it!!

	andnf	ds:[searchFlag], not mask SOF_CAL_SEARCH 
	pop	bx
	call	MemUnlock			; unlock data block
exit:
	ret
error:
	add	sp, 4				; adjust stack pointer (cx,dx)
	jmp	short	exit
error2:
	mov	bp, ERROR_NO_RECORD		; bp - error message constant
	call	DisplayErrorBox			; put up an error dialog box
	jmp	short	error
error3:
	mov	bp, ERROR_NO_DATA_FILE		; bp - error msg number
	call	DisplayErrorBox			; put up an error dialog box 
	jmp	short	error
RespondCalendarRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexRequestSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends calendar with a text string to search for.

CALLED BY:	UI (= MSG_ROLODEX_CALL_CALENDAR ) 

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexRequestSearch	method	GeoDexClass, MSG_ROLODEX_CALL_CALENDAR

	; get the OD of text object with the target

	GetResourceHandleNS	RolodexPrimary, bx
	mov	si, offset RolodexPrimary	; bx:si - OD of GenPrimary
	mov	ax, MSG_META_GET_TARGET_AT_TARGET_LEVEL
	clr	cx				; leaf
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; returns OD in bx:si

	; get the selected text in a memory block

	mov	si, dx			; OD chunk => SI
	mov	bx, cx			; handle of OD => BX
	mov	ax, MSG_VIS_TEXT_GET_SELECTION_BLOCK
	clr	dx			; cx - return text in a global block
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	
	call	ObjMessage		; cx - handle of text block

	; send a search message to GeoPlanner

	mov	dx, cx			; dx - handle of text block
	mov	cx, ax			; cx - text string length 
	mov	ax, MSG_CALENDAR_REQUEST_SEARCH
	call	CallCalendar		; call calendar with string to search 
	jnc	exit			; exit if success!!

	; if GeoPlanner is not found, put up an error message and exit

	mov	bp, ERROR_NO_CALENDAR	; bp - error message constant
	call	DisplayErrorBox		
exit:
	ret
RolodexRequestSearch	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexSendEmail
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send email.

CALLED BY:	UI (= MSG_ROLODEX_CALL_EMAIL ) 

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/20/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef GPC
emailToken	GeodeToken <<'mail'>, MANUFACTURER_ID_GEOWORKS>

RolodexSendEmail	method	GeoDexClass, MSG_ROLODEX_CALL_EMAIL
	;
	; make sure we have email field
	;
	GetResourceHandleNS	StaticPhoneSixName, bx
	mov	si, offset StaticPhoneSixName
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	
	call	ObjMessage		; cx - handle of text block, ax = len
	LONG jcxz	done
	push	cx
	mov	bx, cx
	tst	ax
	LONG jz	doneFree
	push	ds
	call	MemLock
	mov	ds, ax
	clr	si
	GetResourceHandleNS	PhoneEmailDisplayString, bx
	call	MemLock
	mov	es, ax	
	mov	di, offset PhoneEmailDisplayString
	mov	di, es:[di]		; es:di == text in PhoneEmailDisplayString
	clr	cx
	call	LocalCmpStrings		; compare and make sure both strings are "email:"
	pop	ds
	pop	cx			; cx <- handle of StaticPhoneSixName text block
	pushf				; save LocalCmpStrings result
	GetResourceHandleNS	PhoneEmailDisplayString, bx
	call	MemUnlock
	mov	bx, cx	
	call	MemFree
	popf
	jne	done
	;
	; allocate IApp block
	;
	mov	ax, size InternetAppBlock + PHONE_NO_LENGTH+1	; include null
	mov	cx, ALLOC_DYNAMIC or (HAF_STANDARD_LOCK shl 8)
	mov	bx, handle ui
	call	MemAllocSetOwner	; bx = handle, ax = segment
	jc	done
	;
	; get email addr
	;
	push	bx
	mov	es, ax
	mov	es:[IAB_type], IADT_MAIL_TO
	mov	dx, ax			; dx:bp = URL buffer in IAB
	mov	bp, size InternetAppBlock
	GetResourceHandleNS	StaticPhoneSixNumber, bx
	mov	si, offset StaticPhoneSixNumber
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	
	call	ObjMessage		; cx = length
	pop	bx			; bx = IAB
	call	MemUnlock		; unlock IAB
	jcxz	doneFree
	;
	; call email app
	;
	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock	; dx = ALB
	jc	doneFree
	xchg	bx, dx			; bx = ALB, dx = IAB
	call	MemLock
	mov	es, ax
	mov	es:[ALB_extraData], dx	; store IAB in ALB
	call	MemUnlock
	segmov	es, cs, di
	mov	di, offset emailToken
	clr	ax
	call	IACPConnect		; bp = IACPConnection
	jc	error
	clr	cx
	call	IACPShutdown
done:
	ret

doneFree:
	call	MemFree
	jmp	short done

error:
	mov	bp, ERROR_NO_EMAIL
	call	DisplayErrorBox
	jmp	short done

RolodexSendEmail	endm
endif

RolodexTextEmptyChange	method	GeoDexClass, MSG_META_TEXT_EMPTY_STATUS_CHANGED
ifdef GPC
	GetResourceHandleNS	StaticPhoneSixNumber, ax
	cmp	cx, ax
	jne	done
	cmp	dx, offset StaticPhoneSixNumber
	jne	done
	;
	; enable or disable Email button based on email address
	;
	mov	ax, MSG_GEN_SET_ENABLED
	tst	bp
	jnz	gotState		; becoming non-empty
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; else, becoming empty
gotState:
	GetResourceHandleNS	EmailTrigger, bx
	mov	si, offset EmailTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
endif
	ret
RolodexTextEmptyChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexUpdateEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update (add/edit) entry.

CALLED BY:	EXTERNAL

PASS:		cx - handle of data block

RETURN:		Address Book will grab the focus

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

PSEUDO CODE/STRATEGY:
			
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/25/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef GPC
RolodexUpdateEntry	method	GeoDexClass, MSG_ROLODEX_UPDATE_ENTRY

	push	cx			; save data block

	;
	; Bring ourselves to the fore in a way that ensures nice transfer
	; of target & focus, and de-iconifies our primary, too.
	; 
	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	call	UserCallApplication
	
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	UserCallApplication

	cmp	ds:[displayStatus], DISABLED_VIEW	; is data file open?
	LONG je	error3			; if not, put up an error box 

	call	SaveCurRecord		; update the record if necessary
	LONG jc	error			; exit if error

	call	DisableUndo		; no undoable action exists

	test	ds:[recStatus], mask RSF_WARNING ; was warning box up?
	LONG jne	error			; if so, exit

	;
	; initiate new entry dialog box
	;
	call	GeodeGetProcessHandle
	mov	ax, MSG_ROLODEX_NEW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	; enter fields
	;
	pop	bx
	call	MemLock
	push	bx
	GetResourceHandleNS	AddrBox, bx
	mov	es, ax


	clr	di
addrFieldLoop:
	mov	ax, es:[di].RUEF_type
	cmp	ax, RUEFT_LAST_FIELD
	LONG je	doneFields

	mov	dx, es
	push	es, di
	lea	bp, es:[di].RUEF_data

	cmp	ax, RUEFT_LASTNAME
	LONG jz	isLastName
	cmp	ax, RUEFT_ADDRESS
	LONG jz	isAddress
	cmp	ax, RUEFT_EMAIL
	LONG jz	nextField	; don't do this rogue Email
	cmp	ax, RUEFT_EMAIL_KEY
	LONG ja	nextField	; don't know what this is!

	;
	; Must be a phone field of some sort
	;
	mov	si, offset PhoneNoField
	sub	ax, RUEFT_HOME_PHONE-1 ;; Convert to a PhoneTypeIndex

	;
	; We need to display the right record item
	;
	push	bx, cx, dx, es, si, di, bp
	push	ax
	; Force it to be modified
	or	ds:[phoneFieldDirty], mask GTSF_MODIFIED
	call	SaveCurPhone

	; Display the phone field we are about to modify
	pop	cx
	push	cx
	call	RolodexPhoneTo

if 0
	call	DBLockNO
	mov	di, es:[di]		; open up this record
	mov	bp, ds:[curRecord]	; bp - current record handle
	pop	cx
	push	cx
	call	DisplayPhoneNoField	; display phone field text string
	call	DBUnlock
endif

	pop	ax
	pop	bx, cx, dx, es, si, di, bp

	;
	; Now change that record item (just a text item)
	;
	or	ds:[phoneFieldDirty], mask GTSF_MODIFIED
;;	call	SaveCurPhone
	jmp	storeData

isLastName:
	mov	si, offset LastNameField
	jmp	storeData
isAddress:
	mov	si, offset AddrField
	jmp	storeData
storeData:
	;
	; try to put name in Last, First format (fields are clear,
	; so we can append)
	;
	mov	es, dx
	mov	di, bp
	mov	ax, C_NULL
	mov	cx, -1
	LocalFindChar
	LocalPrevChar	esdi		; point at last char
	mov	ax, C_SPACE
	neg	cx
	dec	cx			; # of characters in string
	std				; find last space (search backwards)
	LocalFindChar
	cld
	jne	notLastName		; no space found
	LocalNextChar	esdi		; point at last space
	mov	ax, C_NULL
	LocalPutChar	esdi, ax	; null-term first name, skip it
	push	dx, bp			; save first name
	movdw	dxbp, esdi		; point to last name
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	dx, SEGMENT_CS		; add separator
	mov	bp, offset commaSpace
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx, bp			; dx:bp = beginning of name
notLastName:
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	; mark text modified
	mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
	mov	cx, 1
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage


nextField:
	pop	es, di
	add	di, es:[di].RUEF_size
	add	di, size RolodexUpdateEntryField
	jmp	addrFieldLoop

doneFields:
	pop	bx				; free data block
	call	MemFree

exit:
	ret
error:
	pop	bx				; free data block
	call	MemFree
	jmp	short	exit
error3:
	mov	bp, ERROR_NO_DATA_FILE		; bp - error msg number
	call	DisplayErrorBox			; put up an error dialog box 
	jmp	short	error
RolodexUpdateEntry	endm

commaSpace	TCHAR	", ",0

endif

ifdef GPC ;;

RolodexUpdateEntry	method	GeoDexClass, MSG_ROLODEX_UPDATE_ENTRY

	push	cx			; save data block

	;
	; Bring ourselves to the fore in a way that ensures nice transfer
	; of target & focus, and de-iconifies our primary, too.
	; 
	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	call	UserCallApplication
	
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	UserCallApplication

	cmp	ds:[displayStatus], DISABLED_VIEW	; is data file open?
	LONG je	error3			; if not, put up an error box 

	call	SaveCurRecord		; update the record if necessary
	LONG jc	error			; exit if error

	call	DisableUndo		; no undoable action exists

	test	ds:[recStatus], mask RSF_WARNING ; was warning box up?
	LONG jne	error			; if so, exit
	;
	; initiate new entry dialog box
	;
	call	GeodeGetProcessHandle
	mov	ax, MSG_ROLODEX_NEW_INITIATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	;
	; enter fields into new entry dialog
	;
	pop	bx
	call	MemLock
	push	bx
	GetResourceHandleNS	NewRecordDialog, bx
	mov	es, ax
	clr	di
addrFieldLoop:
	mov	ax, es:[di].RUEF_type
	cmp	ax, RUEFT_LAST_FIELD
	LONG je	doneFields
	cmp	ax, RUEFT_EMAIL_KEY
	jne	notEmailKey
	mov	ds:[updateEntry], BB_TRUE
notEmailKey:
	mov	dx, es
	lea	bp, es:[di].RUEF_data
	push	es, di
	mov	cx, length updateEntryFieldTable
	segmov	es, cs, di
	mov	di, offset updateEntryFieldTable
	repne	scasw
	jne	nextField
	sub	di, offset updateEntryFieldTable
	mov	si, cs:[updateEntryTextObjTable][di-size(word)]
	cmp	si, offset NewLastNameField
	jne	notLastName
	;
	; try to put name in Last, First format (fields are clear,
	; so we can append)
	;
	mov	es, dx
	mov	di, bp
	mov	ax, C_NULL
	mov	cx, -1
	LocalFindChar
	LocalPrevChar	esdi		; point at last char
	mov	ax, C_SPACE
	neg	cx
	dec	cx			; # of characters in string
	std				; find last space (search backwards)
	LocalFindChar
	cld
	jne	notLastName		; no space found
	LocalNextChar	esdi		; point at last space
	mov	ax, C_NULL
	LocalPutChar	esdi, ax	; null-term first name, skip it
	push	dx, bp			; save first name
	movdw	dxbp, esdi		; point to last name
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	dx, SEGMENT_CS		; add separator
	mov	bp, offset commaSpace
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx, bp			; dx:bp = beginning of name
notLastName:
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
nextField:
	pop	es, di
	add	di, es:[di].RUEF_size
	add	di, size RolodexUpdateEntryField
	jmp	addrFieldLoop

doneFields:
	pop	bx				; free data block
	call	MemFree
	;
	; enable Create button
	;
	GetResourceHandleNS	NewCreate, bx
	mov	si, offset NewCreate
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:
	ret
error:
	pop	bx				; free data block
	call	MemFree
	jmp	short	exit
error3:
	mov	bp, ERROR_NO_DATA_FILE		; bp - error msg number
	call	DisplayErrorBox			; put up an error dialog box 
	jmp	short	error
RolodexUpdateEntry	endm

commaSpace	TCHAR	", ",0

updateEntryFieldTable	word \
	RUEFT_LASTNAME,
	RUEFT_ADDRESS,
	RUEFT_EMAIL,
	RUEFT_EMAIL_KEY,
	RUEFT_HOME_PHONE,
	RUEFT_WORK_PHONE,
	RUEFT_MOBILE_PHONE,
	RUEFT_FAX_PHONE,
	RUEFT_PAGER_PHONE

updateEntryTextObjTable	lptr \
	offset	NewDialogResource:NewLastNameField,
	offset	NewDialogResource:NewAddrField,
	offset	NewDialogResource:NewStaticPhoneSixNumber,
	offset	NewDialogResource:NewStaticPhoneSixNumber,
	offset	NewDialogResource:NewStaticPhoneOneNumber,
	offset	NewDialogResource:NewStaticPhoneTwoNumber,
	offset	NewDialogResource:NewStaticPhoneThreeNumber,
	offset	NewDialogResource:NewStaticPhoneFourNumber,
	offset	NewDialogResource:NewStaticPhoneFiveNumber

endif  ; GPC ;;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallCalendar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call calendar with the given method

CALLED BY:	(INTERNAL)

PASS: 		AX	= Message to send
		CX	= Text length
		DX	= Text block handle

RETURN:		carry set if calendar is found
		carry clear if there is no calendar app

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

calendarToken	GeodeToken	CALENDAR_TOKEN	; token for calendar lookups

CallCalendar	proc	near
	uses	es
	.enter

	push	ax, cx, dx		; save message & text params

	;
	; Create a launch block so IACP can launch the app if it's not
	; around yet.
	; 
	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock
	;
	; Set ALF_DESK_ACCESSORY to match our own.
	; 
	mov	bx, dx
	mov	ax, MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS
	call	UserCallApplication
	andnf	ax, mask ALF_DESK_ACCESSORY
	mov_tr	dx, ax
	call	MemLock
	mov	es, ax
	ornf	es:[ALB_launchFlags], dl
	call	MemUnlock
	;
	; Connect to all GeoPlanner apps currently functional
	; 
	segmov	es, cs
	mov	di, offset calendarToken
	mov	ax, IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE
				; connect to all servers, use app obj as client
				;  od.
	call	IACPConnect
	jc	error
	;
	; Initialize reference count for block to be the number of servers
	; to which we're connected so we can free the block when they're all
	; done.
	; 
	pop	bx			; bx <- text block
	mov	ax, cx			; # of connections => AX
	call	MemInitRefCount
	pop	ax, cx			; ax <- msg, cx <- text length
	mov	dx, bx
	;
	; Record message to send to them
	; 
	clr	bx, si			; any class acceptable
	mov	di, mask MF_RECORD
	call	ObjMessage
	
	push	di			; save handle
	;
	; Record completion message for nuking text block
	; 
	call	GeodeGetProcessHandle
	mov	ax, MSG_META_DEC_BLOCK_REF_COUNT
	clr	cx			; no block in cx (block is in dx)
	mov	di, mask MF_RECORD
	call	ObjMessage

	mov	cx, di			; cx <- completion msg
	pop	bx			; bx <- msg to send
	mov	dx, TO_PROCESS		; dx <- TravelOption
	mov	ax, IACPS_CLIENT	; ax <- side doing the send
	call	IACPSendMessage

	; That's it, we're done.  Shut down the connection we opened up, so
	; that GeoPlanner is allowed to exit.  -- Doug 2/93
	;
	clr	cx, dx			; shutting down the client
	call	IACPShutdown

	clc	
done:
	.leave
	ret

	; There was an error, so delete the text and return carry set
error:
	pop	bx
	call	MemFree
	add	sp, 4			; drop ax,cx
	stc
	jmp	done
CallCalendar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoDexDispatchEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To handle a synchronization problem with geoplanner,
		we need to make sure that the completion message going
		back to geoplanner gets put on our queue.
		(When there is a password on the document, the completion 
		message was going through, while the IACP message was being
		held up)

CALLED BY:	MSG_META_DISPATCH_EVENT
PASS:		*ds:si	= GeoDexClass object
		ds:di	= GeoDexClass instance data
		ds:bx	= GeoDexClass object (same as *ds:si)
		es 	= segment of GeoDexClass
		ax	= message #
		cx	= handle of event
		dx 	= MessageFlags to pass to ObjDispatchMessage

RETURN:		If MF_CALL specified:
			carry, ax, cx, dx, bp - return values
		Otherwise:
			ax, cx, dx, bp - destroyed
		(event freed)
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RB	7/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoDexDispatchEvent	method dynamic GeoDexClass, 
					MSG_META_DISPATCH_EVENT

	;
	; Should we hold up this message on the queue?	

	mov	bx, cx				; event handle
	call	ObjGetMessageInfo
	mov	cx, bx				; cx = event handle
	cmp	ax, MSG_META_DEC_BLOCK_REF_COUNT
	je	sendAgain

	;
	; Send to super
	; resend the event we were in the middle of delivering
	;

callSuper::
	mov	ax, MSG_META_DISPATCH_EVENT
	mov	di, offset GeoDexClass
	GOTO	ObjCallSuperNoLock

sendAgain:
	mov	ax, MSG_ROLODEX_DISPATCH_EVENT
	call	GeodeGetProcessHandle
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

GeoDexDispatchEvent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexDispatchEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine to use for synchronization purposes.
		We need to make sure that the completion routine
		sent from IACP happens after the initial routine is called.
		Therfore we use the routine to stick the message back

		in the queue.

CALLED BY:	MSG_GEODEX_DISPATCH_EVENT
PASS:		*ds:si	= GeoDexClass object
		ds:di	= GeoDexClass instance data
		ds:bx	= GeoDexClass object (same as *ds:si)
		es 	= segment of GeoDexClass
		ax	= message #
		cx	= handle of event
		dx 	= MessageFlags to pass to ObjDispatchMessage

RETURN:		If MF_CALL specified:
			carry, ax, cx, dx, bp - return values
		Otherwise:
			ax, cx, dx, bp - destroyed
		(event freed)
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RB	7/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexDispatchEvent	method dynamic GeoDexClass, 
					MSG_ROLODEX_DISPATCH_EVENT

		mov	ax, MSG_META_DISPATCH_EVENT
		mov	di, offset GeoDexClass
		GOTO	ObjCallSuperNoLock

RolodexDispatchEvent	endm


if PZ_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexHandlePhoneticCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when CR is hit in phonetic field.

CALLED BY:	UI (= MSG_ROLODEX_PHONETIC_CR )

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Just move focus and target to zip field.
	Codes are taken from RoloDexHandleCR


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	owa	7/26/93		Initial version


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexHandlePhoneticCR	method	GeoDexClass, MSG_ROLODEX_PHONETIC_CR 
	; give focus to the zip field

	GetResourceHandleNS	ZipField, bx
	mov	si, offset ZipField 	; bx:si - OD of zip field
	mov	ax, MSG_GEN_MAKE_FOCUS	
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		

	; now give target to the zip field also

	mov	ax, MSG_GEN_MAKE_TARGET	
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		

	; now move cursor at the end of the text

	mov	ax, MSG_VIS_TEXT_SELECT_END
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		
	ret
RolodexHandlePhoneticCR endm
endif


if PZ_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexHandleZipCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when CR is hit in zip field.

CALLED BY:	UI (= MSG_ROLODEX_ZIP_CR )

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Just move focus and target to address field.
	Codes are taken from RoloDexHandleCR


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	owa	7/26/93		Initial version


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexHandleZipCR	method	GeoDexClass, MSG_ROLODEX_ZIP_CR 
	; give focus to the address field

	GetResourceHandleNS	AddrField, bx
	mov	si, offset AddrField 	; bx:si - OD of address field
	mov	ax, MSG_GEN_MAKE_FOCUS	
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		

	; now give target to the address field also

	mov	ax, MSG_GEN_MAKE_TARGET	
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		

	; now move cursor at the end of the text

	mov	ax, MSG_VIS_TEXT_SELECT_END
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage		

	ret
RolodexHandleZipCR endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddrFieldGainedFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gained focus in AddrField, add name if empty.

CALLED BY:	UI

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
		copied from RolodexHandleCR

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/23/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef GPC
AddrFieldTextGainedFocusExcl	method	AddrFieldTextClass, MSG_META_GAINED_FOCUS_EXCL
addrFieldChunk	local	lptr	push	si
indexField	local	optr
	.enter
	;
	; let super handle
	;
	push	bp
	mov	di, offset AddrFieldTextClass
	call	ObjCallSuperNoLock
	pop	bp
	;
	; copy name from index field into address field
	;
	GetResourceHandleNS	LastNameField, bx
	mov	indexField.handle, bx
	mov	indexField.chunk, offset LastNameField
	cmp	bx, ds:[LMBH_handle]
	je	haveIndex
	GetResourceHandleNS	NewLastNameField, bx
	mov	indexField.handle, bx
	mov	indexField.chunk, offset NewLastNameField
	cmp	bx, ds:[LMBH_handle]
	LONG jne	quit
haveIndex:
	mov	bx, ds:[LMBH_handle]
	call	GetTextInMemBlock	; returns cx - # chars or 0
					; returns ax - handle of text block
	jcxz	readIndex		; skip if empty empty

	mov	bx, ax			; bx - handle of text block
	call	MemFree			; delete it 
	jmp	quit			; and exit
readIndex:
	movdw	bxsi, indexField
	call	GetTextInMemBlock	; returns cx - # chars or 0
					; returns ax - handle of text block
	jcxz	quit			; stop processing if empty

	push	ds			; save seg addr of core block
	push	ax			; save handle of text block
	mov	bx, ax			; bx - handle of text block
	call	MemLock			; open it up
	mov	ds, ax			; ds - seg address of text block
	clr	si			; ds:si - ptr to text string

	push	cx			; save number of chars in text block
	mov	ax, cx			; ax - number of bytes to allocate
SBCS <	add	ax, 3			; add three bytes: handle and null char>
DBCS <	shl	ax, 1			; ax - string size		>
DBCS <	add	ax, (size hptr) + (size wchar)	; handle + C_NULL
	mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or ALLOC_DYNAMIC
	call	MemAlloc		; allocate the block
	mov	es, ax			; set up the segment
	mov	es:[0], bx		; store the block handle
	mov	di, 2			; es:di - ptr to the string
	pop	cx			; restore length of string

	call	ModifyIndex		; modify text string from index field
	pop	bx			; bx - handle of field string
	call	MemFree			; free it up
	pop	ds			; ds - seg address of core block
	LocalClrChar	es:[di]		; null terminate the text string

	mov	si, addrFieldChunk
	mov	bx, indexField.handle
	push	bp
	mov	dx, es
	mov	bp, 2			; dx:bp - ptr to string to display 
	clr	cx				; null terminated string
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage			; display the text strings
	pop	bp
	push	bx
	mov	bx, es:[0]		; bx - block handle 
	call	MemFree			; free it up
	pop	bx

	; mark address field user modified

	mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		
quit:
	.leave
	ret
AddrFieldTextGainedFocusExcl	 endm
endif

MINIMUM_BORDER_WIDTH	= 30			; minimum black-border width
GREY_BORDER_MARGIN	= 5			; margin around UI draw in grey

BlackBorderVisDraw	method	BlackBorderClass, MSG_VIS_DRAW
	uses	ax, cx, bp, si
	.enter

	; Only draw the black border if we are running in the CUI
	;
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	LONG jne	done

	; Only draw the border if our bounds exceeds the bounds
	; of our child, and even then we must make sure we only
	; draw the black where required (likely just above & below).
	; We also assume our only child is centered within us,
	; making the calcaulations below simpler.
	;
	push	bp
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	clr	cx
	call	ObjCallInstanceNoLock
EC <	ERROR_C	UNEXPECTED_LACK_OF_CHILDREN				>
	push	si
	mov	ax, MSG_VIS_GET_SIZE
	movdw	bxsi, cxdx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	push	cx, dx				; save width, height of child
	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock		
	mov	bx, bp				; bounds = (ax,bx) to (cx,dx)
	pop	bp, si				; child's width, height = bp,si
	pop	di				; di = gstate
	push	ax
	mov	ax, C_BLACK
	call	GrSetAreaColor			; set the color now
	pop	ax

	; OK, start the calculations! Handle the height first
	;
	push	bp				; save child's width
	mov	bp, dx
	sub	bp, bx
	sub	bp, (GREY_BORDER_MARGIN * 2)
	sub	bp, si
	jbe	checkWidth
	cmp	bp, (MINIMUM_BORDER_WIDTH * 2) - (GREY_BORDER_MARGIN * 2)
	jb	checkWidth
	push	dx
	shr	bp, 1				; bp = border height
	mov	dx, bx
	add	dx, bp
	call	GrFillRect			; top border
	pop	dx
	push	bx
	mov	bx, dx
	sub	bx, bp
	call	GrFillRect			; bottom border
	pop	bx

	; Now deal with the width
	;
checkWidth:
	pop	bp				; restore child's width
	mov	si, cx
	sub	si, ax
	sub	si, (GREY_BORDER_MARGIN * 2)
	sub	si, bp
	jbe	done
	cmp	si, (MINIMUM_BORDER_WIDTH * 2) - (GREY_BORDER_MARGIN * 2)
	jb	done
	push	cx
	shr	si, 1				; si = border width
	mov	cx, ax
	add	cx, si
	call	GrFillRect			; left border
	pop	cx
	mov	ax, cx
	sub	ax, si
	call	GrFillRect			; right border
done:
	.leave
	mov	di, offset BlackBorderClass
	call	ObjCallSuperNoLock
	ret
BlackBorderVisDraw	endm

ifdef EXPORT
RolDocumentControlScanFeatureHints	method	dynamic	RolDocumentControlClass, MSG_GEN_CONTROL_SCAN_FEATURE_HINTS
	;
	; let superclass build out default features
	;
		mov	di, offset RolDocumentControlClass
		call	ObjCallSuperNoLock
	;
	; add EXPORT for all AUI levels
	;
		call	UserGetDefaultUILevel
		cmp	ax, UIIL_INTRODUCTORY
		je	done
		mov	es, dx
		mov	di, bp
		ornf	es:[di].GCSI_userAdded, mask GDCF_EXPORT
		ornf	es:[di].GCSI_appRequired, mask GDCF_EXPORT
		andnf	es:[di].GCSI_userRemoved, not mask GDCF_EXPORT
		andnf	es:[di].GCSI_appProhibited, not mask GDCF_EXPORT
done:
		ret
RolDocumentControlScanFeatureHints	endm
endif

CommonCode ends
