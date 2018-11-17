Comment @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit/Document
FILE:		documentMnemonic.asm

AUTHOR:		Cassie Hartzog, Jan  8, 1993

ROUTINES:
	Name			Description
	----			-----------

EXT	DocumentEnableMnemonicList
				MSG_RESEDIT_DOCUMENT_ENABLE_MNEMONIC_LIST
				Current chunk has changed to a text moniker,
				reinitialize and enable the mnemonic list.

EXT	DocumentDisableMnemonicList
				MSG_RESEDIT_DOCUMENT_DISABLE_MNEMONIC_LIST
				Current chunk is changing, disable the list
				and make the NIL item visible.

EXT	DocumentDeleteMnemonic	MSG_RESEDIT_DOCUMENT_DELETE_MNEMONIC
				User has hit delete or backspace in
				MnemonicText.  Set the new mnemonic to NIL.

EXT	DocumentMnemonicTextChanged	
				MSG_RESEDIT_DOCUMENT_MNEMONIC_TEXT_CHANGED
				The user has edited the mnemonic text, update
				the document instance data to reflect this.

EXT	DocumentChangeMnemonic	MSG_RESEDIT_DOCUMENT_CHANGE_MNEMONIC
				The user has changed the mnemonic, update
				the document instance data to reflect this.

EXT	DocumentGetMnemonic	MSG_RESEDIT_DOCUMENT_GET_MNEMONIC
				A new item is being displayed, get its
				moniker.

INT	DocumentChangeMnemonicLow
				Set the underline in the text, update
				MnemonicText.

EXT	DocumentUserModifiedText	MSG_META_TEXT_USER_MODIFIED
				User has modified the text.  Update the
				mnemonic list.

EXT	DocumentUserModifiedEditText
				MSG_RESEDIT_DOCUMENT_USER_MODIFIED_TEXT
				EditText has been modified by the user, and
				the mnemonic character has changed.

INT	DocumentReplaceMnemonicText
				The mnemonic has changed.  Put the new
				mnemonic in the MnemonicText.

EXT	GetMnemonicCount	The chunk has been edited, so there is a new
				number of chars to be used in the mnemonic
				list. Calculate the number of possible
				mnemonic chars.  Includes ESC, NIL.

EXT	GetMnemonicPosition	Given the value of the VMT_mnemonicOffset
				field from a moniker, return the position
				that mnemonic will have in the MnemonicList.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	1/ 8/93		Initial revision


DESCRIPTION:
	Code for detecting, displaying, editing mnemonics.

	$Id: documentMnemonic.asm,v 1.1 97/04/04 17:14:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentMnemCode	segment	resource

;---

DocMnem_ObjMessage_send		proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	GOTO	DocMnem_ObjMessage_common, di
DocMnem_ObjMessage_send		endp

DocMnem_ObjMessage_call		proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	DocMnem_ObjMessage_common, di
DocMnem_ObjMessage_call		endp

DocMnem_ObjMessage_common	proc	near
	call	ObjMessage
	FALL_THRU_POP	di
	ret	
DocMnem_ObjMessage_common	endp

;---


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentEnableMnemonicList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A new text moniker is being edited, setup the 
		mnemonic list appropriately.

CALLED BY:	MSG_RESEDIT_DOCUMENT_ENABLE_MNEMONIC_LIST

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentEnableMnemonicList		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_ENABLE_MNEMONIC_LIST
	uses	bp
	.enter

EC <	cmp	ds:[di].REDI_chunkType, mask CT_TEXT or mask CT_MONIKER >
EC <	jne	done							>

	; enable the list and text objects
	;
	call	GetDisplayHandle
	mov	si, offset MnemonicList
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_ENABLED
	call	DocMnem_ObjMessage_send

	mov	si, offset MnemonicText
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_ENABLED
	call	DocMnem_ObjMessage_send

	; put the correct mnemonic in the text object
	;
	call	DocumentReplaceMnemonicText

EC<done:								>
	.leave
	ret
DocumentEnableMnemonicList		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentDisableMnemonicList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A new text moniker is being edited, setup the 
		mnemonic list appropriately.

CALLED BY:	MSG_RESEDIT_DOCUMENT_DISABLE_MNEMONIC_LIST

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString	NilText, <'NIL', 0>
LocalDefNLString	EscText, <'ESC', 0>
DocumentDisableMnemonicList		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_DISABLE_MNEMONIC_LIST
	uses	bp
	.enter

	call	GetDisplayHandle

	mov	dx, cs
	mov	bp, offset NilText
	mov	si, offset MnemonicText
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	DocMnem_ObjMessage_send

	mov	si, offset MnemonicText
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	DocMnem_ObjMessage_send

	mov	si, offset MnemonicList
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	DocMnem_ObjMessage_send

	.leave
	ret
DocumentDisableMnemonicList		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentDeleteMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has hit delete or backspace in MnemonicText.
		Set the new mnemonic to NIL.

CALLED BY:	MSG_RESEDIT_DOCUMENT_DELETE_MNEMONIC
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentDeleteMnemonic		method dynamic ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_DELETE_MNEMONIC

	clr	ds:[di].REDI_mnemonicChar	; no char
	mov	dl, MP_NIL			; set mnemonic to NIL
	cmp	ds:[di].REDI_mnemonicType, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	okay
	dec	ds:[di].REDI_mnemonicCount	; one less position now
okay:
	mov	ds:[di].REDI_mnemonicType, VMO_NO_MNEMONIC
	call	DocumentChangeMnemonicLow

	ret
DocumentDeleteMnemonic		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentMnemonicTextChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user has modified the mnemonic text.  Find and 
		underline the appropriate character in the text.

CALLED BY:	MSG_RESEDIT_DOCUMENT_MNEMONIC_TEXT_CHANGED
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentMnemonicTextChanged		method ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_MNEMONIC_TEXT_CHANGED

	push	si

	; create a buffer to hold text
	;
SBCS <	sub	sp, 4							>
DBCS <	sub	sp, 8							>
	mov	bp, sp
	mov	dx, ss

	; retrieve the text and truncate it to one character
	;
	call	GetDisplayHandle
	mov	si, offset MnemonicText
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	DocMnem_ObjMessage_call		; cx <- string length

	mov	dl, cl				; dl <- string length
SBCS <	mov	cl, ss:[bp]			; cl <- the first char	>
DBCS <	mov	cx, ss:[bp]			; cx <- the first char	>
	cmp	dl, 3				; long enough for '(*)' ?
	jne	neverMind
SBCS <	cmp	{byte}ss:[bp], '('					>
DBCS <	cmp	{word}ss:[bp], C_OPENING_PARENTHESIS			>
	jne	neverMind
SBCS <	cmp	{byte}ss:[bp+2], ')'					>
DBCS <	cmp	{word}ss:[bp+4], C_CLOSING_PARENTHESIS			>
	je	editMnemonicAfterText

neverMind:
SBCS <	add	sp, 4							>
DBCS <	add	sp, 8							>
	tst	dl 				; no char?
	mov	dh, VMO_NO_MNEMONIC		; dh <- type of NIL
	jz	haveOffset			; change to NIL (pos 0)

;; dl = string length (only in dbcs: fixme comment)
;; cx = the character

	; find the character's position in EditText
	;
SBCS <	mov	dl, cl							>
DBCS <	mov	dx, cx							>
SBCS <	mov	ds:[di].REDI_mnemonicChar, dl	; save the char		>
DBCS <	mov	ds:[di].REDI_mnemonicChar, dx	; save the char		>
	movdw	bxsi, ds:[di].REDI_editText
	mov	ax, MSG_RESEDIT_TEXT_FIND_CHARACTER
	call	DocMnem_ObjMessage_call		; cx <- offset to char
	cmp	cx, -1
	je	addMnemonicAfterText
			
	; if offset > 255 in EC, act as if VMO_NO_MNEMONIC
	;
if DBCS_PCGEOS
EC<	mov	dh, VMO_NO_MNEMONIC	; used dh to store high byte of char >
					; assume no mnemonic
endif
EC<	clr	dl			; mov dl, MP_NIL	>
EC<	tst	ch						>
EC<	jnz	haveOffset					>
	mov	dh, cl				; cl <- offset is type
	mov	dl, cl
	add	dl, MP_FIRST_TEXT_CHAR		; dl <- new position

haveOffset::
	; call DocChangeMnemonicLow to update display and save changes
	;
	mov	ds:[di].REDI_mnemonicType, dh	; save new type
	pop	si
	call	DocumentChangeMnemonicLow
	
	ret

editMnemonicAfterText:
if DBCS_PCGEOS
	mov	dx, ss:[bp+2]
	mov	ds:[di].REDI_mnemonicChar, dx	; save the char
	add	sp, 8
else
	mov	dl, ss:[bp+1]
	mov	ds:[di].REDI_mnemonicChar, dl
	add	sp, 4
endif

addMnemonicAfterText:
	mov	dh, VMO_MNEMONIC_NOT_IN_MKR_TEXT	; this is the type

	; if current mnemonic is after text, don't need to change anything
	;
	mov	dl, ds:[di].REDI_mnemonicPos
	cmp	ds:[di].REDI_mnemonicType, VMO_MNEMONIC_NOT_IN_MKR_TEXT	
	je	haveOffset

	; else up the mnemonic count, change the type
	;
	mov	dl, ds:[di].REDI_mnemonicCount	; dl <- new pos
	inc	ds:[di].REDI_mnemonicCount 
	jmp	haveOffset	
	
DocumentMnemonicTextChanged		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentChangeMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user has changed the mnemonic via the ResEditValue
		gadget.  Need to underline the corresponding character
		in the moniker text and update MnemonicText.

CALLED BY:	ResEditValueChange
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		dx - MnemonicChange (direction of mnemonic's movement in text)

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentChangeMnemonic		method dynamic ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_CHANGE_MNEMONIC

	; If the mnemonic position is 0, can't move back any more,
	; but can move forward.
	;
	mov	cl, ds:[di].REDI_mnemonicPos
	mov	bl, cl
	tst	cl
	jnz	notFirst
	cmp	dl, MC_BACKWARD
	LONG	je	done
	inc	bl
	jmp	haveNewPos

notFirst:
	; If the mnemonic position = mnemonic count, can't move 
	; forward any more, but can move backward
	;
	inc	cl				;count from 1, not zero
	cmp	cl, ds:[di].REDI_mnemonicCount
	jne	notLast
	dec	cl
	cmp	dl, MC_FORWARD
	LONG	je	done
	;
	; if moving backward from last position, and last position is
	; a mnemonic not in text, want to delete that position 
	; and change type back to normal mnemonic.
	;
	cmp	ds:[di].REDI_mnemonicType, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	notLast
	dec	bl				;bl <- new position
	dec	ds:[di].REDI_mnemonicCount	;one less position now
	jmp	haveNewPos

notLast:
	; If this not the first or last mnemonic, can move in either direction
	;
	dec	cl				;count from 0 again
	inc	bl				;assume forward movement
	cmp	dl, MC_FORWARD
	je	haveNewPos
	sub	bl, 2				;nope, it's backward
	
haveNewPos:
	;
	; Now that we know the new position, set the type correctly.
	; Since it is impossible to move forward to a mnemonic which
	; is not in the text (since that position doesn't exist unless
	; it is the current position), if the position is >= MP_FIRST_TEXT_CHAR
	; the mnemonic char is in the text.
	; 
	mov	dl, bl				;dl <- new position
	mov	dh, bl
	sub	dh, MP_FIRST_TEXT_CHAR		;dh <- offset of char
	cmp	bl, MP_FIRST_TEXT_CHAR		;is it in a text char position?
	jae	getNewChar			;yes, get the new char

	mov	dh, VMO_NO_MNEMONIC		;no, assume no mnemonic
	cmp	bl, MP_NIL			;is it NIL position?
	je	haveNewType			;yes, save type
	mov	dh, VMO_CANCEL			;else it must be ESC position
	jmp	haveNewType
	
getNewChar:
	;
	; Get the new char from the text object
	;
	push	si
	mov	cl, dh				; cl <- offset of char
	mov	ax, MSG_RESEDIT_TEXT_GET_CHARACTER
	movdw	bxsi, ds:[di].REDI_editText
	call	DocMnem_ObjMessage_call		; cl (cx) <- mnemonic character
SBCS <	mov	ds:[di].REDI_mnemonicChar, cl				>
DBCS <	mov	ds:[di].REDI_mnemonicChar, cx				>
	pop	si

if ERROR_CHECK
DBCS <	cmp	cx, -1							>
DBCS <	ERROR_E RESEDIT_IS_ODD			;FIXME: stupid error name	>
endif

haveNewType:
	mov	ds:[di].REDI_mnemonicType, dh
	call	DocumentChangeMnemonicLow

done:
	ret

DocumentChangeMnemonic		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentChangeMnemonicLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the underline in the text, update MnemonicText.

CALLED BY:	DocumentChangeMnemonic, DocumentMnemonicTextChanged,
		DocumentDeleteMnemonic
	
PASS:		*ds:si	- document
		dl	- new mnemonic position	
		ds:di.REDI_mnemonicCount, ds:di.REDI_mnemonicType updated

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentChangeMnemonicLow		proc	near
	.enter

EC<	call	AssertIsResEditDocument			>
	push	si

	; put the new mnemonic in MnemonicText gadget
	;
	DerefDoc
	xchg	dl, ds:[di].REDI_mnemonicPos	;dl <- old position
	call	DocumentReplaceMnemonicText	;update mnemonic display

	;
	; since ESC & NIL are positions 0 and 1, don't need to
	; clear the underline for the old mnemonic character if dl < 2
	;
	mov	bl, ds:[di].REDI_mnemonicType
	cmp	dl, 2
	jb	noClear

	push	bx
	movdw	bxsi, ds:[di].REDI_editText
	mov	ax, MSG_RESEDIT_TEXT_CLEAR_UNDERLINE
	call	DocMnem_ObjMessage_call
	pop	bx

noClear:
	;
	; and no need to set the underline if the new mnemonic's 
	; list position is 0 (NIL) or 1 (ESC), or if it comes
	; after the text moniker (displayed in list only)
	;
	mov	cl, ds:[di].REDI_mnemonicPos
	clr	ch
	cmp	cl, MP_FIRST_TEXT_CHAR			;is it NIL or ESC?
	jb	noUnderline

	cmp	bl, VMO_MNEMONIC_NOT_IN_MKR_TEXT	;mnemonic not in text?
	jne	setUnderline				;nope, it is in text

	mov	bh, ds:[di].REDI_mnemonicCount	;position of mnemonic after
	dec	bh				; text is count -1
	cmp	cl, bh				;is new mnemonic in last pos?
	je	noUnderline			;yes, don't set underline

setUnderline:
	sub	cl, MP_FIRST_TEXT_CHAR		;subtract ESC, NIL
	movdw	bxsi, ds:[di].REDI_editText
	mov	ax, MSG_RESEDIT_TEXT_SET_UNDERLINE
	call	DocMnem_ObjMessage_send

noUnderline:
	GetResourceHandleNS	EditUndo, bx
	mov	si, offset EditUndo
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	si

	mov	ax, MSG_RESEDIT_DOCUMENT_SAVE_CHUNK
	call	ObjCallInstanceNoLock

;	call	SetEditMenuState

	.leave
	ret
DocumentChangeMnemonicLow		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentUserModifiedText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has modified the text, update the mnemonic list.

CALLED BY:	UI - MSG_META_TEXT_USER_MODIFIED

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClass
		ax - the message
		^lcx:dx	- text object

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,ds,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentUserModifiedText	method dynamic ResEditDocumentClass,
						MSG_META_TEXT_USER_MODIFIED

	; If the text object that has been modified is the MnemonicText 
	; object, the mnemonic character has changed.  
	;
	call	GetDisplayHandle		; ^lbx <- MainDisplay
	mov	ax, offset MnemonicText		
	cmpdw	bxax, cxdx
	jne	notMnemonicText
	GOTO	DocumentMnemonicTextChanged

notMnemonicText:
	ret

DocumentUserModifiedText		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentUserModifiedEditText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EditText has been modified by the user, and the 
		mnemonic character has changed.

CALLED BY:	MSG_RESEDIT_DOCUMENT_USER_MODIFIED_TEXT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cl - offset of new mnemonic character
		   -or- VMO_NO_MNEMONIC if none
		dl - mnemonic char (DBCS: dx)

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This message is sent by EditText after it has been altered
	in some way.  Keyboard character, cut/copy/paste, search and
	replace, undo.

	In each of these cases, if there is a mnemonic character, 
	it can be deleted or it can move, but no new mnemonic character
	can be inserted.  

	Thus the mnemonic char can go from a legitimate ascii char
	to 0, if the mnemonic was deleted.
XXX:
	What if old mnemonic was not in text, and the mnemonic char
	does appear in the replace text?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/31/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentUserModifiedEditText	method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_USER_MODIFIED_TEXT

	push	si

	; if not a text moniker, we don't need to deal with mnemonics
	;
	cmp	ds:[di].REDI_chunkType, mask CT_TEXT or mask CT_MONIKER 
	jne	done	

	; Get the new mnemonic pos and mnemonic type from the offset
	; of the mnemonic char, if there is one.
	;
	mov	bl, cl				; bl <- offset
	add	bl, MP_FIRST_TEXT_CHAR		; bl <- pos. in mnemonic list
	mov	bh, cl				; bh <- mnemonic type (offset)
	cmp	bh, VMO_NO_MNEMONIC
	jne	storeNewPos			; yes
	mov	bl, MP_NIL			; bl <- NIL position

storeNewPos:
	mov	ds:[di].REDI_mnemonicPos, bl
	mov	ds:[di].REDI_mnemonicType, bh
		
	; Now that the new Pos and Type are set, get the 
	; number of mnemonic positions.
	;
	call	GetMnemonicCount		;cx <- count
	mov	ds:[di].REDI_mnemonicCount, cl
EC <	tst	ch				>
EC <	ERROR_NZ TOO_MANY_MNEMONIC_ITEMS	>

	; get the new mnemonic character, if there is a mnemonic
	;
	cmp	bh, VMO_NO_MNEMONIC
	je	replaceMnemonic

	; If the mnemonic character has changed, save the new char
	; and replace what's now in MnemonicText with the new char.
	;
SBCS <	cmp	dl, ds:[di].REDI_mnemonicChar				>
DBCS <	cmp	dx, ds:[di].REDI_mnemonicChar				>
	je	done
SBCS <	mov	ds:[di].REDI_mnemonicChar, dl				>
DBCS <	mov	ds:[di].REDI_mnemonicChar, dx				>
replaceMnemonic:
	call	DocumentReplaceMnemonicText

done:
	pop	si

	mov	ax, MSG_RESEDIT_DOCUMENT_SAVE_CHUNK
	call	ObjCallInstanceNoLock

;	call	SetEditMenuState		; enable the undo trigger
	GetResourceHandleNS	EditUndo, bx
	mov	si, offset EditUndo
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	ret
DocumentUserModifiedEditText		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentReplaceMnemonicText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The mnemonic has changed.  Put the new mnemonic in 
		the MnemonicText.		

CALLED BY:	DocumentChangeMnemonicLow, DocumentUserModifiedText,
		DocumentEnableMnemonicList

PASS: 		ds:di - ResEditDocumentInstance, with all
			REDI_mnemonic fields set for the new mnemonic

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This does not support DBCS.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentReplaceMnemonicText	proc near
	uses	bx,cx,dx,si,bp
	.enter

	mov	dl, ds:[di].REDI_mnemonicPos

	; create a buffer to hold the mnemonic text
	;
SBCS <	sub	sp, 4							>
DBCS <	sub	sp, 8							>
	mov	bp, sp 				;ss:bp <- mnemonic buffer

CheckHack <MP_ESC gt MP_NIL>

	cmp	dl, MP_ESC
	ja	setText
	je	setEsc
setNil::
        mov     dx, cs
        mov     bp, offset NilText
        jmp     replace

setEsc:					
        mov     dx, cs
        mov     bp, offset EscText
        jmp     replace

setText:
	; Put the char in the buffer that is passed to VIS_TEXT_REPLACE_ALL
	; 
	mov	dx, ss				;dx:bp <- new mnemonic text
SBCS <	mov	cl, ds:[di].REDI_mnemonicChar				>
DBCS <	mov	cx, ds:[di].REDI_mnemonicChar				>
	cmp	ds:[di].REDI_mnemonicType, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	je	afterText
SBCS <	mov     {byte}ss:[bp], cl					>
DBCS <	mov     {word}ss:[bp], cx					>
SBCS <	clr     {byte}ss:[bp+1]						>
DBCS <	clr     {word}ss:[bp+2]						>

replace:
EC<	mov	bx, ds:[LMBH_handle]				>
EC<	call	ECCheckMemHandle				>

	clr	cx				;text is null-terminated
	mov	bx, ds:[di].GDI_display
	mov	si, offset MnemonicText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	DocMnem_ObjMessage_call

SBCS <	add	sp, 4							>
DBCS <	add	sp, 8							>
	.leave
	ret

afterText:
	; Mnemonic comes after text, draw it in parentheses
	;
if DBCS_PCGEOS
	mov     {word}ss:[bp], C_OPENING_PARENTHESIS
	mov     {word}ss:[bp+2], cx
	mov     {word}ss:[bp+4], C_CLOSING_PARENTHESIS
	clr     {word}ss:[bp+6]
else
	mov     {byte}ss:[bp], '('
	mov     {byte}ss:[bp+1], cl
	mov     {byte}ss:[bp+2], ')'
	clr     {byte}ss:[bp+3]
endif
	jmp	replace


DocumentReplaceMnemonicText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMnemonicCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The chunk has been edited, so there is a new number
		of chars to be used in the mnemonic list. Calculate the
		number of possible mnemonic chars.  Includes ESC, NIL.

CALLED BY:	(EXTERNAL) DocumentUserModifiedText, InitializeEditText

PASS:		*ds:si	- document
		ds:di	- document

RETURN:		cl	- new count 
			
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The count is taken from the EditText object, not what
	is in the database.  Thus, when the current chunk changes,
	the text must be set before this routine is called.
	(It is set in InitializeEditText.)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMnemonicCount	proc	far
	uses	ax,bx,si
	.enter

	clr	cl					;assume none
	DerefDoc
EC <	cmp	ds:[di].REDI_chunkType, mask CT_TEXT or mask CT_MONIKER >
EC <	jne	done							>

	movdw	bxsi, ds:[di].REDI_editText
	mov	ax, MSG_RESEDIT_TEXT_GET_SIZE
	call	DocMnem_ObjMessage_call			;cx <- # chars, not
							; counting null

	;
	; Only VMO_CANCEL - 1 characters can be displayed in the list,
	; since if the offset of the character = VMO_CANCEL, it will
	; be interpreted as VMO_CANCEL, and not an offset.
	; Add in the two special mnemonics, ESC & NIL, and the max
	; value is (VMO_CANCEL - 1) + 2.
	;
	add	cx, 2
	tst	ch
	jz	okay
	mov	cx, (VMO_CANCEL + 1)
CheckHack <VMO_CANCEL eq 0xfd>

okay:
	cmp	ds:[di].REDI_mnemonicType, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	je	notInMkr

done:
	.leave
	ret

notInMkr:
	inc	cl
	jmp	done
GetMnemonicCount		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMnemonicPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the value of the VMT_mnemonicOffset field
		from a moniker, return the position that mnemonic
		will have in the MnemonicList.

CALLED BY:	(EXTERN) InitializeMnemonicList, ResEditTextDraw

PASS:		al	- VMT_mnemonicOffset
		cl	- count of mnemonic characters

RETURN:		al	- position

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMnemonicPosition		proc	far
	.enter

CheckHack <MP_NIL eq 0>
CheckHack <MP_ESC eq 1>
CheckHack <MP_FIRST_TEXT_CHAR eq 2>

	mov	ah, al
	clr	al
	cmp	ah, VMO_NO_MNEMONIC
	je	done

	inc	al
	cmp	ah, VMO_CANCEL
	je	done

	cmp	ah, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	je	notInMkr
	add	ah, 2				;add in NIL & ESC positions
	mov	al, ah

done:
	.leave
	ret

notInMkr:
	; if not in moniker, subtract 1 from # chars (because count from 0)
	;
	mov	al, cl
	dec	al
	jmp	done


GetMnemonicPosition		endp


DocumentMnemCode	ends


;--------------------------------------------------------------------------
;		code for Keyboard Shortcut UI and stuff
;--------------------------------------------------------------------------


DocumentMnemCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentEnableKbdShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A new text moniker is being edited, setup the 
		keyboard shortuct UI appropriately.

CALLED BY:	MSG_RESEDIT_DOCUMENT_ENABLE_KBD_SHORTCUT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentEnableKbdShortcut		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_ENABLE_KBD_SHORTCUT
	uses	bp
	.enter

	mov	ax, ds:[di].REDI_kbdShortcut
;	call	CheckIfEditableShortcut		; is it editable?
;	jc	done				; no 

	; put the correct mnemonic in the text object
	;
	call	DocumentReplaceKbdShortcut

	; enable the list and text objects
	;
	call	GetDisplayHandle
	mov	si, offset ShortcutGroup
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_ENABLED
	call	DocMnem_ObjMessage_send

	.leave
	ret
DocumentEnableKbdShortcut		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentDisableKbdShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A new chunk has become current, and it is not a text
		moniker, so does not have a shortcut.
		
CALLED BY:	MSG_RESEDIT_DOCUMENT_DISABLE_KBD_SHORTCUT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentDisableKbdShortcut		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_DISABLE_KBD_SHORTCUT
	uses	bp
	.enter

	call	GetDisplayHandle
	mov	si, offset ShortcutGroup
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	DocMnem_ObjMessage_send

	.leave
	ret
DocumentDisableKbdShortcut		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentReplaceKbdShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update shortcut UI with new KeyboardShortcut.

CALLED BY:	
PASS:		*ds:si	- document
		ds:di	- document
		ax	- KeyboardShortcut
RETURN:		nothing
DESTROYED:	bx,cx,dx,bp

PSEUDO CODE/STRATEGY:
KeyboardShortcut	record
    KS_PHYSICAL:1		;TRUE: match key, not character
    KS_ALT:1			;TRUE: <ALT> must be pressed
    KS_CTRL:1			;TRUE: <CTRL> must be pressed
    KS_SHIFT:1			;TRUE: <SHIFT> must be pressed
SBCS:
    KS_CHAR_SET:4		;lower four bits of CharacterSet
    KS_CHAR	Chars:8		;character itself (Char or VChar)
DBCS:
    KS_CHAR	Chars:12	;bits 0-11 of Chars
KeyboardShorcut	end

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentReplaceKbdShortcut		proc	near
	uses	si
	.enter

if not DBCS_PCGEOS
	; in DBCS, KS_CHAR_SET does not exist; it's all one character set.
	;
EC <	mov	bx, ax						>
EC <	andnf	bx, mask KS_CHAR_SET				>
EC <	tst	bx						>
EC <	ERROR_NZ	RESEDIT_INTERNAL_LOGIC_ERROR		>
endif
	tst	ax
	jz	noShortcut

	;
	; Set the Shortcut character
	; 
	push	ax
SBCS <	sub	sp, 2				; space for a char and a null>
DBCS <	sub	sp, 4							>
	mov	bp, sp
	mov	dx, ss				; dx:bp <- text buffer
ifdef DBCS_PCGEOS
	andnf	ax, 0x0fff	; the flags are not part of the character
	mov	ss:[bp], ax
	mov	{word}ss:[bp+2], 0
else
	mov	ss:[bp], al
	mov	{byte}ss:[bp+1], 0
endif
	mov	cx, 1				; cx <- string length

	push	si
	call	GetDisplayHandle
	mov	si, offset ShortcutText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	DocMnem_ObjMessage_call
	pop	si
SBCS <	add	sp, 2							>
DBCS <	add	sp, 4							>

	pop	dx
	andnf	dx, 0xf000			; dx <- modifiers that are on
	mov	cx, dx				; cx <- booleans to set "True"
	not	dx				
	andnf	dx, 0xf000			; dx <-modifiers to set "false"

	push	si
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	si, offset ShortcutModifiers
	call	DocMnem_ObjMessage_send
	pop	si

	mov	ax, MSG_GEN_SET_ENABLED
	call	DocumentSetShortcutState

	mov	si, offset ShortcutItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
done:
	clr	dx				; none are indeterminate
	call	DocMnem_ObjMessage_send

	.leave
	ret

noShortcut:
	; remove text, turn off modifiers, disable UI,
	; select "No Shortcut" item
	;
	push	si
	call	DocumentSetNoShortcut
	pop	si
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	DocumentSetShortcutState
	mov	si, offset ShortcutItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	cx				; select item 0 
	jmp	done
	
DocumentReplaceKbdShortcut		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentApplyNewShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has changed the keyboard shortcut.  Need to update
		the translation element to reflect the changes.

CALLED BY:	MSG_RESEDIT_DOCUMENT_APPLY_NEW_SHORTCUT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)
		cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentApplyNewShortcut		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_APPLY_NEW_SHORTCUT

	; get the new KeyboardShortcut
	;
	call	DocumentGetKbdShortcut		; ax <- KeyboardShortcut
	DerefDoc
	mov	ds:[di].REDI_kbdShortcut, ax
	mov	dx, ax

	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	tst	dx
	jnz	haveShortcut

	push	dx, si
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	DocumentSetShortcutState
	pop	dx, si
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	cx

haveShortcut:
	push	dx, si
	call	GetDisplayHandle
	mov	si, offset ShortcutItemGroup
	clr	dx				; none are indeterminate
	call	DocMnem_ObjMessage_send
	pop	ax, si

	; Transform shortcut into text string.  
	;
	sub	sp, SHORTCUT_BUFFER_SIZE
	mov	di, sp
	mov	dx, di				; dx <- offset of buffer
	segmov	es, ss

	call	ShortcutToAscii			; cx <- string length w/NULL

	; allocate or reallocate a trans item for it
	;
	push	ds:[LMBH_handle], si		; save document OD
	DerefDoc
	mov	bp, di

	push	cx, dx				; save shortcut length, offset

	push	ax				; save shortcut
	call	GetFileHandle			;^hbx <- file handle
	mov	ax, ds:[bp].REDI_resourceGroup
	mov	dx, ds:[bp].REDI_origItem
	mov	di, ds:[bp].REDI_transItem
DBCS <	shl	cx, 1				;cx <- string size w/NULL	>
	call	AllocNewTransItem		;cx <- new item

	push	ax				;save group number
	push	cx				;save item number
	mov	ax, ds:[bp].REDI_curChunk
	call	DerefElement			;ds:di <- element
	pop	ds:[di].RAE_data.RAD_transItem	;store new transItem
	pop	ax				;restore group
	pop	ds:[di].RAE_data.RAD_kbdShortcut ;store the shortcut

	call	DBDirty_DS
	mov	di, ds:[di].RAE_data.RAD_transItem ; di <- transItem
	call	DBUnlock_DS
	pop	cx, si				; restore buffer length, offset

	; copy the shortcut text to the item
	;
	call	DBLock
	mov	di, es:[di]			;es:di <- destination
	segmov	ds, ss, ax			;ds:si <- source buffer
	LocalCopyNString
	call	DBDirty
	call	DBUnlock

	pop	bx, si				;^lbx:si <- document
	add	sp, SHORTCUT_BUFFER_SIZE	;free the buffer

	; Clear the old and draw the new shortcut
	;
	call	MemDerefDS
	DerefDoc
	mov	ax, ds:[di].REDI_curChunk
	call	DocumentInvalidateChunk

	ret
DocumentApplyNewShortcut		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentGetKbdShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the actual keyboard shortcut from ShortcutGroup.

CALLED BY:	INTERNAL - DocumentApplyNewShortcut
PASS:		*ds:si - instance data
		ds:di - *ds:si

RETURN:		ax - KeyboardShortcut
DESTROYED:	bx,cx,dx,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentGetKbdShortcut	proc 	near
	uses	si
	.enter

	call	GetDisplayHandle
	mov	si, offset ShortcutModifiers
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	DocMnem_ObjMessage_call		; ax <- Modifers which are on
	
	; get the actual shortcut character from ShortcutText
	;
	push	ax
SBCS <	sub	sp, SHORTCUT_BUFFER_LENGTH				>
DBCS <	sub	sp, SHORTCUT_BUFFER_LENGTH*2				>
	mov	bp, sp
	mov	dx, ss				; dx:bp <- text buffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	si, offset ShortcutText
	call	DocMnem_ObjMessage_call		; cx <- text length
EC <	cmp	cx, 1				>
EC <	ERROR_A RESEDIT_INTERNAL_LOGIC_ERROR 	>

	; save the character in the low byte of KeyboardCharacter
	; use the low 12 bits if DBCS
	;
SBCS <	mov	{byte}cl, ss:[bp]					>
DBCS <	mov	{word}cx, ss:[bp]					>
DBCS <	andnf	cx, 0x0fff						>
SBCS <	add	sp, SHORTCUT_BUFFER_LENGTH				>
DBCS <	add	sp, SHORTCUT_BUFFER_LENGTH*2				>
	pop	ax				; ah <- modifiers
SBCS <	mov	al, cl							>
DBCS <	ornf	ax, cx				; ax <- KeyboardShortcut>
	
	; CharacterSet is CS_BSW, so we leave KS_CHAR_SET = 0
	;
if not DBCS_PCGEOS
CheckHack <CS_BSW eq 0>
endif
	; If there is no shortcut character, turn off all modifiers
	;
SBCS <	tst	al							>
DBCS <	tst	cx				; character extends beyond al >
	jnz	done
	clr	cx				; don't set any booleans TRUE
	clr	dx				; indeterminate
	mov	si, offset ShortcutModifiers
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	DocMnem_ObjMessage_send
	clr	ax				; no keyboard shortcut

done:
	.leave
	ret
DocumentGetKbdShortcut		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentToggleShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggle shortcut ui

CALLED BY:	MSG_RESEDIT_DOCUMENT_TOGGLE_SHORTCUT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cx -- current or first selection, or 
		      GIGS_NONE if no selection
		bp -- number of selections
		dl -- GenItemGroupStateFlags
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentToggleShortcut		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_TOGGLE_SHORTCUT

	test	dl, mask GIGSF_MODIFIED
	jz	done

	cmp	cx, 0
	je	noShortcut
	mov	ax, MSG_GEN_SET_ENABLED
	call	DocumentSetShortcutState
done:	
	ret

noShortcut:
	push	si, si
	call	DocumentSetNoShortcut
	pop	si
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	DocumentSetShortcutState
	pop	si

	mov	ax, MSG_RESEDIT_DOCUMENT_APPLY_NEW_SHORTCUT
	GOTO	ObjCallInstanceNoLock

DocumentToggleShortcut		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSetNoShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the shortcut UI to show that there is no shortcut.

CALLED BY:	INTERNAL
PASS:		*ds:si - document
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSetNoShortcut		proc	near

	clr	cx				; don't set any booleans TRUE
	clr	dx				; indeterminate
	call	GetDisplayHandle
	mov	si, offset ShortcutModifiers
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	DocMnem_ObjMessage_send
	
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	si, offset ShortcutText		; delete the shortcut char
	call	DocMnem_ObjMessage_send

	ret
DocumentSetNoShortcut		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSetShortcutState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the shortcut UI to show that there is no shortcut.

CALLED BY:	INTERNAL
PASS:		ax - MSG_GEN_SET_ENABLED or _NOT_ENABLED
		*ds:si - document
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSetShortcutState		proc	near

	push	ax
	call	GetDisplayHandle
	mov	si, offset ShortcutModifiers
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	DocMnem_ObjMessage_send
	pop	ax
	
	mov	si, offset ShortcutText
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	DocMnem_ObjMessage_send

	ret
DocumentSetShortcutState		endp


DocumentMnemCode	ends

