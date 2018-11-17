COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Dial		
FILE:		dialUtils.asm

AUTHOR:		Ted H. Kim, March 4, 1992

ROUTINES:
	Name			Description
	----			-----------
	FocusPhoneField		Gives the focus to PhoneField
	EnableObjectFixupDSES	Enable the passed object
	DisableObjectFixupDSES	Disable the passed object
	AddPhoneTypeName	Adds a new phone type name to the table
	GetPhoneTypeID		Gets the phone number type name ID number
	InsertPhoneEntry	Copies in a new phone number and phone type
	DeletePhoneEntry	Delete the phone entry from the record
	ClearPhoneObjects	Clears the phone entry fields in GCM rolodex
	MemAllocErrBox		Puts up a memory allocation error dialog box 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision

DESCRIPTION:
	Contains various utility routines for Dial module.	

	$Id: dialUtils.asm,v 1.1 97/04/04 15:49:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FocusPhoneField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends MSG_GEN_MAKE_FOCUS to PhoneField

CALLED BY:	UTILITY

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
FocusPhoneField	proc	far
	mov	si, offset PhoneNoField	; bx:si - OD of phone number field
	GetResourceHandleNS	PhoneNoField, bx
	mov	ax, MSG_GEN_MAKE_FOCUS	
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage		; set focus to phone number field
	ret
FocusPhoneField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableObjectFixupDSES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends MSG_GEN_SET_ENABLED to passed object

CALLED BY:	UTILITY

PASS:		bx:si - OD of object

RETURN:		nothing

DESTROYED:	ax, dx, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableObjectFixupDSES	proc	far
	mov	ax, MSG_GEN_SET_ENABLED	
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES 
	mov	dl, VUM_NOW		; update it right now
	call	ObjMessage		; enable the passed object
	ret
EnableObjectFixupDSES	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableObjectFixupDSES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends MSG_GEN_SET_NOT_ENABLED to passed object

CALLED BY:	UTILITY

PASS:		bx:si - OD of object

RETURN:		nothing

DESTROYED:	ax, dx, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableObjectFixupDSES	proc	far
	mov	ax, MSG_GEN_SET_NOT_ENABLED	
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES 
	mov	dl, VUM_NOW		; update it right now
	call	ObjMessage		; disable the passed object
	ret
DisableObjectFixupDSES	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPhoneTypeName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a new phone number type name to the name table.

CALLED BY:	UpdatePhone

PASS:		gmb.GMB_phoneTypeBlk - handle of phone number type name block
		fieldHandles, fieldLengths - handle and length of mem blks

RETURN:		dx - count of phone type names

DESTROYED:	ax, bx, cx, es, si, di

PSEUDO CODE/STRATEGY:
	Resize the data block
		Since the name does not exist yet, the block is extended
		by the name phone number type's string size.
	Copy the string 
	Update the offset and new size info
	Delete the memory block 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	* Assumes replacing empty phone type name entry.
	* Loop could use offsets instead of indexing.



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version
	witt	1/31/93 	DBCS-ized, code touchup

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddPhoneTypeName	proc	far

	; lock the phone type name block

	mov	di, ds:[gmb.GMB_phoneTypeBlk]	; di - phone type name data block
	call	DBLockNO
	mov	si, es:[di]		; di - points to beg. of phone table
	mov	cx, es:[si].PEI_size	; cx - current table size
	add	cx, ds:fieldLengths[TEFO_PHONE_TYPE]	; cx - new table size 
DBCS<	add	cx, ds:fieldLengths[TEFO_PHONE_TYPE]	; cx - new table size >
	call	DBUnlock

	;    Display a warning when the block grows large.  DBItems like
	;	to be less than 8K in size.
	;
EC <	cmp	cx, 4000					>
EC <	WARNING_A  PHONE_TYPE_BLOCK_BEYOND_4000_BYTES		>

	; resize the phone type name block

	mov	di, ds:[gmb.GMB_phoneTypeBlk]	; di - phone type name data block
	call	DBReAllocNO		; resize the phone name table block
	call	DBLockNO
	mov	di, es:[di]		; open it up

	mov	si, di
	mov	ax, ds:[gmb.GMB_totalPhoneNames]; ax - number of phone # type names
	shl	ax, 1
	add	si, ax			; es:si - offset new phone type offset

	mov	dx, es:[di]		; dx - offset to new name
	mov	es:[si], dx		; store string offset
	mov	cx, ds:fieldLengths[TEFO_PHONE_TYPE]   ; cx - size phone type
DBCS<	shl	cx, 1			; cx - string size		>
	add	es:[di], cx		; update the size info
	add	di, dx			; di - pointer to a new string name

	; lock the memory block that contains new phone type name

	mov	bx, ds:fieldHandles[TEFO_PHONE_TYPE]; bx - phone type field
	push	ds			; save segment address of core block
	call	MemLock			; lock block so we can get segment addr
EC <	ERROR_C	MEMORY_BLOCK_DISCARDED					>
	mov	ds, ax			; ds - segment of temp text block
	clr	si			; ds:si - points to start of string
	rep	movsb			; cx still has string size.

	call	MemFree			; delete temporary text block 
	pop	ds			; restore seg address of core block
	clr	ds:fieldHandles[TEFO_PHONE_TYPE]; clear handle of phone type
	call	DBUnlock

	mov	dx, ds:[gmb.GMB_totalPhoneNames]; dx - total number of phone # types 
	inc	ds:[gmb.GMB_totalPhoneNames]	; update it
	ret
AddPhoneTypeName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPhoneTypeID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the phone number type name ID number.  Answers the
		question of whether or not the phone type currently displayed
		is already in our phone type table.

CALLED BY:	UpdatePhone

PASS:		ds - dgroup
			gmb.GMB_phoneTypeBlk - handle of phone type name block

RETURN:		dx - phone number type name ID number (PTI_xxx)
		   - zero if no match is found

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:
	Lock the memory block with phone type name
	Lock the phone number type name table
	Search for a match.
		Table is terminated by a 0 value.
	If not found, exit with zero
	If found, exit with PhoneTypeIndex.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version
	witt 	2/1/94		DBCS-ized and simplified

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPhoneTypeID	proc	far
CheckHack <PTI_HOME ge 1>		; first enum of PhoneTypeIndex >= 1.
	push	ds			; save segment address of core block
	mov	di, ds:[gmb.GMB_phoneTypeBlk]	; di - phone type name data block
	mov	bx, ds:fieldHandles[TEFO_PHONE_TYPE]
	call	MemLock			; lock block so we can get segment addr
EC <	ERROR_C	MEMORY_BLOCK_DISCARDED					>

	; lock the phone type name block

	call	DBLockNO
	mov	ds, ax			; ds - segment temp phone type string
	mov	di, es:[di]		; es:di -> PhoneTypeNameItem ptr
	mov	bp, di			; bp - base addr of PhoneType chunk
	clr	si			; ds:si - source string (always)

if _NDO2000
	mov	dx, PTI_BLANK
	mov	ax, ds:[si]
	tst	ax			; bail on null blocks w/ blank field 
	jz	exit
endif
	
	mov	dx, PTI_HOME*(size word) ; dx - initial phone number type ID
		
	; locate the string within the phone number type name block
mainLoop:
	mov	di, bp			; es:di - points to 1st phone type offset
	mov	bx, bp
	add	bx, dx			; bx - ptr to string offset
	add	di, es:[bx]		; es:di - destination
	cmp	di, bp			; are we end of table? (NULL ptr)
	je	searchUnsuccesful	; yep, return to caller.

	; compare the string in mem block with the one in phone type block 

	clr	cx			; strings are null terminated
	call	LocalCmpStringsNoCase
	je	exit			; if match, exit with DX set
	add	dx, (size word)
	jmp	mainLoop		; check the next name

searchUnsuccesful:
	clr	dx			; dx - ID zero for there was no match
					; (fall thru to exit)
exit:
	call	DBUnlock		;  Unlock PhoneTypeBlk. dx = phone type
	pop	ds			; restore segment address of core block
	mov	bx, ds:fieldHandles[TEFO_PHONE_TYPE]
	call	MemUnlock		; destroy temporary text block 

	shr	dx, 1			; is it one of pre-defined names?
					; (convert DX from word offset to index)
	jz	quit			; if not (ie, DX was 0), skip

	call	MemFree			; delete known phone type text
	clr	ds:fieldHandles[TEFO_PHONE_TYPE]   ; we already have type name
quit:
	ret
GetPhoneTypeID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertPhoneEntry 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies in a new phone number and phone type 

CALLED BY:	UpdatePhone

PASS:		dl - phone number type name ID number

RETURN:		nothing

DESTROYED:	bx, cx, dx, es, si di

PSEUDO CODE/STRATEGY:
	Open up the record
	Get offset to the end of record
	Make room for a new phone entry
	Save phone number length and type
	Copy in the phone number
	Close up the record
	Insert this number into quick dial tables

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertPhoneEntry	proc	far

	; lock the current record entry
	
	push	dx				; save phone number type ID #
	mov	di, ds:[curRecord]		; di - current record handle
	call	DBLockNO
	mov	si, es:[di]			
	mov	cx, ds:[gmb.GMB_curPhoneIndex]	; assume not a new phone type
	tst	cx				; was this a blank phone field?
	jne	skip				; if not, skip
	mov	cx, es:[si].DBR_noPhoneNo	; cx - total no of phone no.
	mov	ds:[gmb.GMB_curPhoneIndex], cx	; new phone count
skip:
	inc	es:[si].DBR_noPhoneNo		; increment the counter 
	mov	dx, si				; dx - ptr to beg of record

	add	si, es:[si].DBR_toPhone		;si - ptr to beg of phone entry
mainLoop:
	; go to the end of the phone entries

if DBCS_PCGEOS
	mov	ax, es:[si].PE_length		; advance record ptr
	shl	ax, 1				; ax - record size
	add	si, ax
else
	add	si, es:[si].PE_length
endif
	add	si, size PhoneEntry		; si - ptr to next phone entry
	loop	mainLoop			; continue

	mov	cx, ds:fieldLengths[TEFO_PHONE_NO] ; cx - size phone # field
DBCS<	shl	cx, 1				; cx - size phone # field    >
	add	cx, size PhoneEntry		; cx - add size of phone entry 
	xchg	si, dx			
	sub	dx, si				; dx - offset to insert at
	call	DBUnlock

	; make room for one more phone entry
	;	cx = size of new entry

	mov	di, ds:[curRecord]		; di - current record handle
	call	DBInsertAtNO			; make room for new phone entry

	; copy the new phone entry info into the record entry

	call	DBLockNO	
	mov	si, es:[di]			; open up this record again
	add	si, dx				; si - ptr to place to insert
	mov	cx, ds:fieldLengths[TEFO_PHONE_NO]  ; cx - len phone # field 
	mov	es:[si].PE_length, cx		; save the length (incl C_NULL)

	pop	ax				; restore phone type name ID #
	mov	es:[si].PE_type, al		; save the phone ID #
	clr	es:[si].PE_count		; no phone calls made yet
	call	DBUnlock

	; copy the phone number into the record entry

						; is phone number field empty?
	jcxz	exit				; empty.. exit
	add	dx, size PhoneEntry		; dx - ptr to place to insert at
	push	ax				; save phone number type ID #
	mov	bp, TEFO_PHONE_NO		; bp - offset to offset table
	call	MoveStringToDatabase		; copy the phone number 
	pop	ax				; restore phone number type ID #
exit:
	ret
InsertPhoneEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeletePhoneEntry 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the phone entry (telephone number) from the record.

CALLED BY:	UpdatePhone, InsertPhone

PASS:		curRecord - current record handle
		gmb.GMB_curPhoneIndex - phone number counter
		dl - phone number type name ID number

RETURN:		nothing

DESTROYED:	ax, bx, cx, es, si, di

PSEUDO CODE/STRATEGY:
	Open up this record
	Get the offset to the phone entry to be deleted
	Delete the phone entry
	Delete the phone entry from frequency list
	Delete the phone entry from history list

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeletePhoneEntry	proc	far
	push	dx			; save phone number type ID #
	tst	ds:[gmb.GMB_curPhoneIndex]	; was this a blank phone field?
	LONG je	exit			; if so, return

	; lock the current record entry

	mov	di, ds:[curRecord]	; di - current record handle
	mov	cx, ds:[gmb.GMB_curPhoneIndex]	; cx - phone number counter
	call	DBLockNO
	mov	si, es:[di]		
	mov	dx, si			; dx - ptr to beg of record
	cmp	cx, es:[si].DBR_noPhoneNo
	jz	exit			; don't delete past last entry
	tst	es:[si].DBR_noPhoneNo	; if # of phone number entry is zero, 
	je	dontDec			; don't decrement
	dec	es:[si].DBR_noPhoneNo	; one less phone number entry
dontDec:
	mov	ax, es:[si].DBR_noPhoneNo	; ax - # of phone no entries
	cmp	al, es:[si].DBR_phoneDisp	; is DBR_phoneDisp too big?
	jg	notUpdate			; if not, skip
	tst	al				; # of phone no entry zero?
	je	dontDec2			; if so, don't decrement
	dec	al				; if not, decrement 
dontDec2:
	mov	es:[si].DBR_phoneDisp, al	; new value for phoneDisp
notUpdate:
	add	si, es:[si].DBR_toPhone	; si - ptr to phone entries

	; locate the phone entry you are trying to delete
	;	Skip ahead 'cx' phone entries
mainLoop:
if DBCS_PCGEOS
	mov	ax, es:[si].PE_length
	shl	ax, 1			; ax - string size
	add	si, ax			; es:si - ptr to next phone entry
else
	add	si, es:[si].PE_length
endif
	add	si, size PhoneEntry	; es:si - ptr to the next phone entry
	loop	mainLoop		; continue

	mov	cx, size PhoneEntry	; cx - size of a phone entry

	; al - phone type ID # of currently displayed phone entry

	mov	al, ds:[curPhoneType]

	; ah - phone type ID # of phone entry to be deleted

	mov	ah, es:[si].PE_type

	cmp	ah, al			; are they the same?
	jne	notEqual		; if not, skip
	pop	ax			; al - phone type ID # of new entry
	mov	ds:[curPhoneType], al	; update the curPhoneType
	push	ax			; fixup the stack
notEqual:
	mov	bx, es:[si].PE_length	; bx - length of phone #
DBCS<	add	cx, bx						>
	add	cx, bx			; cx - size of phone entry + phone #
	xchg	si, dx
	sub	dx, si			; dx - offset to place to delete
	call	DBUnlock

	; delete this phone entry from the record entry
	;	cx = record size

	mov	di, ds:[curRecord]	; di - current record handle
	call	DBDeleteAtNO		; delete the old entry
exit:
	pop	dx			; restore phone type name ID #
	ret
DeletePhoneEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemAllocErrBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts up an error dialog box when MemAlloc returns with carry
		set

CALLED BY:	UTILITY

PASS:		nothing

RETURN:		carry is always set

DESTROYED:	ax, bx, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemAllocErrBox	proc	far	uses	bp
	.enter

	mov	bp, ERROR_NO_MEMORY		; bp - error message number
	call	DisplayErrorBox			; put up a warning box
	stc					; return with carry set

	.leave
	ret
MemAllocErrBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SavePhoneStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves out current area code, assumed area code, and  the
		long distance prefix number.

CALLED BY:	RolodexApplyDialOptions

PASS:		nothing

RETURN:		bp - -1 if any of dial option stuff is modified

DESTROYED:	ax, bx, cx, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/22/90		Initial version
	witt	3/ 8/94 	Lots of code cleanup!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SavePhoneStuff	proc	near

	;  1.  Check the Long Distance Prefix

	mov	si, offset PrefixField		; bx:si - OD of prefix field
	GetResourceHandleNS	PrefixField, bx
	mov	dx, offset gmb.GMB_prefix
	call	grabIfChanged

	push	ax				; update modification flag

	;  2.  Check the Current Area Code

	mov	si, offset CurrentAreaCodeField	; bx:si - OD of area code field
	GetResourceHandleNS	CurrentAreaCodeField, bx
	mov	dx, offset gmb.GMB_curAreaCode
	call	grabIfChanged

	pop	bp
	or	ax, bp				; update modification flag
	push	ax

	;  3.  Check the Assumed Area Code

	mov	si, offset AssumedAreaCodeField	; bx:si - OD of area code field
	GetResourceHandleNS	AssumedAreaCodeField, bx
	mov	dx, offset gmb.GMB_assumedAreaCode
	call	grabIfChanged

	pop	bp
	or	bp, ax				; bp <- modified flag

	ret

;--------------------------------------------------------------------
;
;    PASS:	bx:si	- OD of text object to inspect
;		ds:dx	- ptr to text buffer to store into
;    RETURN:	ax	- 0 if not modified, -1 if modified
;    DESTORY:	cx, dx, di
;    NOTES:	Buffer only changed if text object modified.
;
grabIfChanged:
	push 	dx

	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage			; get dirty/clean status 

	pop	bp				; ds:bp <- ptr text buffer
						; cx != 0 if dirty
	mov	ax, cx				; if cx == 0, makes ax == 0
	jcxz	grabDone			; if text is not modified, done

	; if modified, copy the new string into map block (ds:bp)

;;	If field is empty, vistext object will store a NULL (witt, Mar94)
;;	LocalClrChar	ds:[bp]			; assume empty string

	mov	dx, ds				; DX:BP <- ptr to dest for text
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			; read in text to pointer passed
						; NULL terminates string
						; ax <- string length (w/out NULL)
	; mark the text object as not modified

	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED	
	mov	di, mask MF_FIXUP_DS 	
	call	ObjMessage			; clear the dirty bit
	mov	ax, -1				; say "modified"

grabDone:
	retn

SavePhoneStuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexApplyDialOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the map block with new dialing options.

CALLED BY:	MSG_ROLODEX_APPLY_DIAL_OPTIONS

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	12/8		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexApplyDialOptions	proc	far

	class	RolodexClass

	; send MSG_GEN_APPLY to all objects except the text objects 
	; We only want to dirty the map block if the text has
	; been modified.  We will send MSG_GEN_APPLY to each text
	; object after we check the modified states to determine
	; which to save (if any are saved, then we'll mark the map
	; block dirty).

	mov	si, offset PhoneListOption	; bx:si - OD of object
	GetResourceHandleNS	PhoneListOption, bx
	mov	ax, MSG_GEN_APPLY
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage

	mov	si, offset DialingOptions	; bx:si - OD of object
	GetResourceHandleNS	DialingOptions, bx
	mov	ax, MSG_GEN_APPLY
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage

if _QUICK_DIAL
	mov	si, offset PhoneOptions		; bx:si - OD of dialog box
	GetResourceHandleNS	PhoneOptions, bx
	mov	ax, MSG_GEN_MAKE_NOT_APPLYABLE
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage
endif

	; read in prefix and area codes if they are modified 

	call	SavePhoneStuff
	tst	bp				; are they changed?
	je	exit				; if not, skip

        call    MarkMapDirty                    ; mark the file dirty

	; At least one of the text objects has been modified.
	; Tell each to apply its changes (if needed) and reset 
	; their modified status.

	mov	si, offset PrefixField		; bx:si - OD of object
	GetResourceHandleNS	PrefixField, bx
	mov	ax, MSG_GEN_APPLY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	si, offset CurrentAreaCodeField	; bx:si - OD of object
	GetResourceHandleNS	CurrentAreaCodeField, bx
	mov	ax, MSG_GEN_APPLY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	si, offset AssumedAreaCodeField	; bx:si - OD of object
	GetResourceHandleNS	AssumedAreaCodeField, bx
	mov	ax, MSG_GEN_APPLY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:
	ret
RolodexApplyDialOptions	endp

CommonCode	ends
