COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Main
FILE:		mainEdit.asm

AUTHOR:		Ted H. Kim, 6/25/92

ROUTINES:
	Name			Description
	----			-----------
	RolodexCopyRecord	Copy a record to clipboard file
	RolodexPasteRecord	Paste in a record from clipboard file
	RolodexNotifyNormalTransferItemChanged
				Enable or disable PasteRecord menu item
	RolodexDelete		Delete a record of data
	RolodexUndo		Undo whatever that needs to be undone
	RolodexClear		Clear the uninserted record
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial revision

DESCRIPTION:
	Contains message handlers for all edit menu items.
	The copy/paste routines use a cell format (spreadsheet).

	$Id: mainEdit.asm,v 1.1 97/04/04 15:50:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EditCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexCopyRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies an entire record of data to the clipboard file.

CALLED BY:	UI (=MSG_ROLODEX_COPY_RECORD)

PASS:		nothing

RETURN:		nothing (record copied into clipboard)
		
DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexCopyRecord	method	GeoDexClass, MSG_ROLODEX_COPY_RECORD
	RCR_SSMeta	local	SSMetaStruc
	.enter

	; check to see if current record is blank

	tst	ds:[curRecord]
	je	exit				; exit if blank

	push	bp
	call	SaveCurRecord			; so changes will be copied
	pop	bp

	; initialize the stack frame for copying a transfer item

	push	bp

	mov	dx, ss				; SSMetaStruc => dx:bp
	lea	bp, RCR_SSMeta
	mov	ax, 0
	mov	cx, ax				; ax:cx - source ID
	mov	bx, ax				; bx - TransferItemFlags
	call	SSMetaInitForCutCopy

	; set the transfer item size

	mov	ax, 1				; ax - number of rows
	mov	cx, GEODEX_NUM_FIELDS		; cx - number of columns
	call	SSMetaSetScrapSize		; unlock the header block
	pop	bp

	; create the transfer item

	call	InitFieldSize			; initialize 'fieldSize'
	mov	ds:[exportFlag], IE_CLIPBOARD	; this is a clipboard item
	clr	cx				; cx - current row number
	call	ExportRecord			; create a transfer item block
	call	ExportFieldName			; export field names 

	push	bp
	mov	dx, ss				; SSMetaStruc => dx:bp
	lea	bp, RCR_SSMeta
	call	SSMetaDoneWithCutCopy		; we are done
	pop	bp
exit:
	.leave
	ret
RolodexCopyRecord	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexPasteRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Paste in a record of data into GeoDex.

CALLED BY:	UI (=MSG_ROLODEX_PASTE_RECORD)

PASS:		nothing

RETURN:		nothing 

DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexPasteRecord	method	GeoDexClass, MSG_ROLODEX_PASTE_RECORD
	RPR_SSMeta	local	SSMetaStruc
	.enter

	; initialize the stack frame for pasting in a transfer item

	push	bp
	mov	dx, ss				; SSMetaStruc => dx:bp
	lea	bp, RPR_SSMeta
	clr	bx				; bx - TransferItemFlags
	call	SSMetaInitForPaste
	pop	bp

	call	PasteFromSSMeta

	; clean up the stack frame

	push	bp
	mov	dx, ss				; SSMetaStruc => dx:bp
	lea	bp, RPR_SSMeta			; SSMetaStruc => dx:bp
	call	SSMetaDoneWithPaste		; we are done pasting
	pop	bp

	.leave
	ret
RolodexPasteRecord	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteFromSSMeta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take a scrap and paste it into the database

CALLED BY:	(EXTERNAL) RolodexPasteRecord
PASS:		ss:bp	= inherited frame
		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PasteFromSSMeta	proc	far
	RPR_SSMeta	local	SSMetaStruc
	.enter	inherit far
	push	bp
	call	SaveCurRecord		; update the record if necessary
	pop	bp
	mov	ds:[undoAction], UNDO_NOTHING
	LONG	jc	quit		; exit if error

	test	ds:[recStatus], mask RSF_WARNING ; was warning box up?
	jne	done			; if so, exit

	; get number of fields in the transfer item

	mov	ax, RPR_SSMeta.SSMDAS_scrapRows	; ax - number of records
	mov	ds:[numRecords], ax		; save it
	mov	ax, RPR_SSMeta.SSMDAS_scrapCols	; ax - number of fields
	mov	ds:[numFields], ax 		; save it
	cmp	ax, GEODEX_NUM_FIELDS		; more than 10 fields?
	jle	okay				; if not, skip
	mov	ds:[numFields], GEODEX_NUM_FIELDS ; read in only 10 fields
okay:
	; make it point to the 1st entry in DAS_CELL array

	mov	RPR_SSMeta.SSMDAS_dataArraySpecifier, DAS_CELL	
	push	bp
	mov	dx, ss				; dx:bp - SSMetaStruc
	lea	bp, RPR_SSMeta
	call	SSMetaDataArrayResetEntryPointer		
	pop	bp	

	call	ImportMetaFile			; JUST DO IT!!

	; unlock DAS_CELL data array

	pushf
	push	bp
	mov	dx, ss				; dx:bp - SSMetaStruc
	lea	bp, RPR_SSMeta
	call	SSMetaDataArrayUnlock		
	pop	bp
	popf
	jc	done				; skip if no error		

	; check to see if there were any records w/ empty index fields
	; if there were, then display a DB with a warning message

	call	CheckEmptyIndex

	; update the index list and display current record

	push	bp
	mov	si, ds:[curRecord]
	clr	ds:[curRecord]			; so new one will display
	tst	si				
	je	exit
	call	DisplayCurRecord		; display this record
exit:
	andnf	ds:[searchFlag], not mask SOF_NEW  ; clear search flag
	call	UpdateNameList			; update SearchList
	pop	bp
	jmp	quit
done:
	andnf	ds:[recStatus], not mask RSF_WARNING ; clear warning flag
quit:
	call	DisableUndo			; no undoable action exists

	.leave
	ret
PasteFromSSMeta	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexNotifyNormalTransferItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables or disables Paste item depending on the availability
		of a transfer item on the clipboard

CALLED BY:	MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED

PASS:		ds - segment of stack, dgroup, thread etc.

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexNotifyNormalTransferItemChanged	method	GeoDexClass,
			MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED

	; check to see if there is a transfer item

	clr	ax				; ax - TransferItemFlags
	call	SSMetaSeeIfScrapPresent
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; assume there is not
	jc	skip				; if not, skip
	mov	ax, MSG_GEN_SET_ENABLED		; else, enable "Paste" item
skip:
	; now enable or disable Paste item accordingly
	
	GetResourceHandleNS	EditPasteRecord, bx
	mov	si, offset EditPasteRecord
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
RolodexNotifyNormalTransferItemChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the current record from database.

CALLED BY:	MSG_ROLODEX_DELETE

PASS:		ds - segment of core block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:
	Copy the data to a temporary block
	Lock the map block
		save the handle of temporary block
	Unlock the map block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	9/4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexDelete	method	GeoDexClass, MSG_ROLODEX_DELETE
ifdef GPC
	mov	bp, WARNING_CONFIRM_DELETE
	call	DisplayErrorBox
	cmp	ax, IC_YES
	jne	quit
endif
	test	ds:[recStatus], mask RSF_NEW	; new record?
	jne	skip			; if so, skip
	push	ds:[curRecord]		; save current record handle
	ornf	ds:[recStatus], mask RSF_DELETE	; set flag to indicate delete
	call	SaveCurRecord		; save current record if necessary
	jc	quit			; exit if error
	andnf	ds:[recStatus], not mask RSF_DELETE	; clear delete flag
	pop	ds:[undoItem]		; save handle of deleted record
skip:
	call	RolodexDeleteLow	; call the low level routine
	jnc	quit			; if no error, exit
	call	DisableUndo		; no undoable action exists
	clr	ds:[undoItem]		; no record to undo
quit:
	ret
RolodexDelete	endm

RolodexDeleteLow	proc	near
	test	ds:[recStatus], mask RSF_NEW	; new record?
	jne	empty				; if so, skip
	mov	ds:[undoAction], UNDO_DELETE	; undoable action is delete
;EC <	call	CheckCurRecord						>
	call	DeleteFromMainTable	; delete current record from main table
if _QUICK_DIAL
	call	DeleteQuickDial		; delete cur rec from quick dial tables
	jc	quit			; exit if error

	call	UpdateMonikers		; update the monikers
	jc	quit			; exit if error
endif ;if _QUICK_DIAL
	tst	ds:[gmb.GMB_numMainTab]		; is main table empty?
	jne	notEmpty		; if not, skip
	call	ClearRecord		; clear all the text fields
	mov	ds:[recStatus], mask RSF_NEW or mask RSF_EMPTY ; set flags
	call	EnableUndo		; enable undo menu
	clr	ds:[curRecord]
	jmp	exit
notEmpty:
	mov	dx, ds:[curOffset]	; dx - offset to current record
	cmp	dx, ds:[gmb.GMB_endOffset]	; did the last entry get deleted?
	jne	skip			; if not, skip
	sub	ds:[curOffset], size TableEntry	; point to new last entry
	mov	dx, ds:[curOffset]	; dx - offset to current record
skip:
	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table
	call	DBLockNO
	mov	di, es:[di]		; open up the main table
	add	di, dx			; points to 
	mov	si, es:[di].TE_item	; si - handle of next record
	call	DBUnlock		; unlock the data record

	call	DisplayCurRecord	; display the next record
	andnf	ds:[searchFlag], not mask SOF_NEW   ; clear search flag
	call	UpdateNameList		; update the name list
	call	EnableUndo		; enable undo menu 
	jmp	exit
empty:
	call	RolodexClear	
exit:
	clc				; exit with no error
if _QUICK_DIAL
quit:
endif ;if _QUICK_DIAL

	ret
RolodexDeleteLow	endp

if	0
if	ERROR_CHECK

CheckCurRecord	proc	near
	push	ax, bx, cx, dx, es, ds, bp, di, si			
 	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table	
	call	DBLockNO						
	mov	si, es:[di]		; si - points to beg of main table 
	add	si, ds:[curOffset]					
SBCS<	mov	ax, es:[si].TE_key	; ax - 1st two letters of last name >
DBCS<	PrintMessage <CheckCurRecord - Not DBCS converted>		    >
	mov	bx, es:[si].TE_item	; bx - handle of DBBlock	
	call	DBUnlock						
	mov	di, bx			; di - handle of DBBlock	
	call	DBLockNO						
	mov	di, es:[di]						
	add	di, size DB_Record	; es:di - ptr to index field	
	push	ax							
	mov	al, es:[di]		; bh - 1st character		
	mov	bh, al			; bh - 1st character		
	mov	al, es:[di+1]		; bl - get the next character	
	mov	bl, al			; bl - 2nd character		
	pop	ax							
	call	DBUnlock						
	cmp	bh, ah			; compare the 1st character	
	ERROR_NE SORT_BUFFER_IS_NOT_CURRENT				
	cmp	bl, al			; compare the 2nd character	
	ERROR_NE SORT_BUFFER_IS_NOT_CURRENT				
	pop	ax, bx, cx, dx, es, ds, bp, di, si			
	ret
CheckCurReocrd	endp

endif
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undoes any changes that were made to the current record
		or restores a record if it has been deleted.

CALLED BY:	MSG_ROLODEX_UNDO

PASS:		ds - segment of core block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es 

PSEUDO CODE/STRATEGY:
	Get the handle of deleted or modified record from map block
	If the changes can be recovered
		read in the record from the database
	else do nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If the user reads in a different record after he has made a change 
	a record, that modified record can not be recovered.

	At the beginning of each record changing routine
	(i.e. RolodexPrevious, RolodexNext, etc ...), it clears
	the DBM_undoItem in map block and actually deletes the old block
	so that no "Undo" function can be performed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	9/4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexUndo	method	GeoDexClass, MSG_ROLODEX_UNDO
	cmp	ds:[undoAction], UNDO_OLD  ; was last action old?
	jne	delete			; if not, skip
	mov	si, ds:[undoItem]	; si - record handle of old record
	call	DisplayCurRecord	; display this record
	andnf	ds:[searchFlag], not mask SOF_NEW   ; clear search flag
	clr	ds:[undoItem]
	mov	ds:[undoAction], UNDO_NEW	; last undoable action is new
	ornf	ds:[recStatus], mask RSF_NEW	
	call	DisableUndo		; disable undo menu 
	jmp	exit
delete:
	cmp	ds:[undoAction], UNDO_DELETE ; was last action delete?
	jne	undoAdd			; if not, skip
	mov	si, ds:[undoItem]	; si - handle of deleted record 
	call	DisplayCurRecord	; display deleted record 
	andnf	ds:[searchFlag], not mask SOF_NEW   ; clear search flag
	call	InsertRecord		; insert it back into main table
if _QUICK_DIAL
	call	InsertAllQuickViewEntry	; insert it back into quick table
endif ;if _QUICK_DIAL
	call	UpdateNameList		; update the name list
if _QUICK_DIAL
	call	UpdateMonikers		; update the monikers
	jc	exit			; exit if error
endif ;if _QUICK_DIAL
	clr	ds:[undoItem]		; no record to udno
	mov	ds:[undoAction], UNDO_ADD  ; last undoable action is add
	jmp	short	exit
undoAdd:
	mov	bx, NUM_TEXT_EDIT_FIELDS+1  ; cx - number of fields to compare
					; add one more for the note field
	clr	bp			; bp - offset into FieldTable
	call	CompareRecord		; has the record been modified?
	jne	modified		; if so, skip to handle it
	cmp	ds:[undoAction], UNDO_NOTHING  ; nothing to undo? 
	je	done			; if so, exit
	cmp	ds:[undoAction], UNDO_ADD  ; was last undoable action add?
	jne	restore			; if not, exit
	mov	si, ds:[curRecord]	; si - current record handle
	mov	ds:[undoItem], si	; save the handle
	call	RolodexDeleteLow	; delete this record
	jnc	exit
	call	DisableUndo		; no undoable action exists
	clr	ds:[undoItem]		; no record to undo
	jmp	short	exit
restore:
	mov	si, ds:[undoItem]	; si - handle of modified record
	mov	di, ds:[curRecord]
	mov	ds:[undoItem], di
	push	ds:[recStatus]		; save record status info
	call	DisplayCurRecord	; display old record
	andnf	ds:[searchFlag], not mask SOF_NEW   ; clear search flag
	pop	ds:[recStatus]		; restore status info
	andnf	ds:[recStatus], not mask RSF_UPDATE ; clear update flag
	cmp	ds:[undoAction], UNDO_RESTORE  ; last undoable action restore?
	jne	change			; if not, skip
	mov	ds:[undoAction], UNDO_CHANGE   ; assume last action is change
	jmp	short	exit
change:
	mov	ds:[undoAction], UNDO_RESTORE	; now last action is restore
exit:
	call	MarkMapDirty		; mark the map block dirty
done:
	ret
modified:
	cmp	ds:[undoAction], UNDO_NOTHING	; was there an undo action? 
	je	undoChange			; if none, skip
	cmp	ds:[undoAction], UNDO_DELETE	; set new undo action flag
	jne	skip
undoChange:
	mov	dx, ds:[curRecord]
	mov	ds:[gmb.GMB_orgRecord], dx		; save current record handle
	mov	ds:[undoAction], UNDO_CHANGE	; last action is now CHANGE
skip:
	test	ds:[recStatus], mask RSF_UPDATE	; has CopyPhone been called? 
	jne	update			; if so, skip

	mov	di, ds:[undoItem]	; di - handle of undone record
	tst	di			; is it blank?
	je	getRecord		; if so, skip
	call	NewDBFree		; delete this record
getRecord:
	mov	dx, ds:[curRecord]
	mov	ds:[undoItem], dx
	mov	cx, NUM_TEXT_EDIT_FIELDS+1   ; cx - number of fields to read in
					; add one for note field
	clr	di			; di - offset to FieldTable
	call	GetRecord		; read in all text edit fields
	clr	ax			; initialize all the text fields
	call	InitRecord		; create a new record and initialize
	jc	done			; if carry set, exit
	jmp	restore
update:
	clr	ax			; update everything
	call	UpdateRecord		; add the changes to database
	jc	done			; if carry set, exit
	jmp	restore

RolodexUndo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the contents of all text edit fields.

CALLED BY:	RolodexDeleteLow

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexClear	proc	near 
	test	ds:[recStatus], mask RSF_NEW	; is it an inserted record?
	je	exit			; if so, exit
	mov	di, ds:[undoItem]	; di - handle of record to be deleted
	tst	di			; was there any record to be deleted?
	je	begin			; if not, skip
	call	NewDBFree		; if so, delete it!
	clr	ds:[undoItem]		; nothing to delete
begin:
	mov	bx, NUM_TEXT_EDIT_FIELDS+1  ; cx - number of fields to compare
					; add one more for the note field
	clr	bp			; bp - offset into FieldTable
	call	CompareRecord		; has the record been modified?
	je	clearRecord		; if not, jump to clear record

	mov	cx, NUM_TEXT_EDIT_FIELDS+1  ; cx - number of fields to read in
					; add one for the note field
	clr	di			; di - offset to FieldTable
	call	GetRecord		; read in all text edit fields

	tst	ds:[curRecord]		; record data modified?
	jne	phone			; if so, skip to handle it

	test	ds:[recStatus], mask RSF_EMPTY	; is record empty?
	jne	done			; if so, exit

	clr	ax			; initialize all the text fields
	call	InitRecord		; create a new record and initialize
	jc	exit			; if carry set, exit
clearRecord:
	test	ds:[recStatus], mask RSF_EMPTY	; is record empty?
	jne	done			; if so, exit
setFlag:
	mov	dx, ds:[curRecord]	; dx - current record handle
	mov	ds:[undoItem], dx	; save it 
	clr	ds:[curRecord]		; blank record is displayed
	call	ClearRecord		; clear all the text fields
	mov	ds:[recStatus], mask RSF_NEW or mask RSF_EMPTY ; set flags
	mov	ds:[undoAction], UNDO_OLD  ; last undoable action is old
	call	EnableUndo		; enable undo menu 
exit:
	ret
phone:
	test	ds:[recStatus], mask RSF_EMPTY	; is record empty?
	je	update			; if not, skip to update
	mov	di, ds:[curRecord]	; di - current record handle
	call	NewDBFree		; delete this record
	clr	ds:[curRecord]
done:
	call	ClearRecord		; clear all the text fields
	mov	ds:[recStatus], mask RSF_NEW or mask RSF_EMPTY ; set flags
	call	DisableUndo		; disable undo menu
	jmp	exit
update:
	clr	ax			; update everything
	call	UpdateRecord		; add the changes to database
	jc	exit			; if carry set, exit
	jmp	short	setFlag		; jump to clear the record
RolodexClear	endp

EditCode ends
