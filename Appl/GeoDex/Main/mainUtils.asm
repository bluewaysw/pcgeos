COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoDex/Main		
FILE:		mainUtils.asm

AUTHOR:		Ted H. Kim, March 4, 1992

ROUTINES:
	Name			Description
	----			-----------
	FocusSortField		Give the focus to the index field
	ClearTextField		Clear a text edit field
	TextTooLarge		Put up too much text in text field error msg
	DisplayErrorBox		Display a generic GeoDex error dialog box
	NewDBFree		Delete the notes field DB item if one exists
	GetTextInMemBlock	Read in text into a memory block
	GetTextInMemBlockNoFixup	
				Same as above but diff'nt flags for ObjMessage
	GetTextInPointer	Read in text into the pointer passed
	EnableObject		Enable an object
	DisableObject		Disable an object
	EnableCopyRecord 	Enable Copy Record menu
	DisableCopyRecord 	Disable Copy Record menu
	EnableUndo		Enable undo menu
	DisableUndo		Disable undo menu
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision

DESCRIPTION:
	Contains various utility routines for Main module.	

	$Id: mainUtils.asm,v 1.1 97/04/04 15:50:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FocusSortField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gives the focus to the index field.

CALLED BY:	UTILITY

PASS:		ds - dgroup

RETURN:		nothing

DESTROYED:	ax, bx, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FocusSortField	proc	far
ifdef GPC
	tst	ds:[openApp]		; still opening?
	jnz	done			; yes, don't futz with focus
endif
	mov	si, offset LastNameField ; bx:si - OD of text object
	GetResourceHandleNS	LastNameField, bx	
	mov	ax, MSG_GEN_MAKE_FOCUS	
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage		; set focus to the sort field
done::
	ret
FocusSortField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears a text edit field. 

CALLED BY:	UTILITY

PASS:		bx:si - OD of text object to clear
		ds - segment address of core block

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	6/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearTextField	proc	far
	mov	dx, ds			
	mov	bp, offset noText	; dx:bp - points to string to display
	clr	cx			; cx - string is null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	; ax - method number
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; clear the text edit field
	ret
ClearTextField	endp

if	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextTooLarge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts up an error dialog box with a message that there is
		too much text in a text object.

CALLED BY:	MSG_TEXT_OBJECT_GETTING_TOO_LARGE, MSG_TEXT_OBJECT_TOO_LARGE

PASS:		nothing

RETURN:		nothing

DESTROYED:	bx, bp, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextTooLarge	proc	far

	class	GeoDexClass

	mov	bp, ERROR_TEXT_TOO_LARGE	; bp - error constant
	call	DisplayErrorBox			; put up the error box
	ret
TextTooLarge	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayErrorBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display generic GeoDex error box

CALLED BY:	GLOBAL

PASS:		DS, ES	= DGroup
		BP	= RolodexErrorValue

RETURN:		carry set if the dialog box terminated by system exit

DESTROYED:	BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	1/3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef GPC
;always continue editing
customTriggerTable	label	StandardDialogResponseTriggerTable
	word	1			; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		CustomYes,			; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
else
customTriggerTable	label	StandardDialogResponseTriggerTable
	word	2			; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		CustomYes,			; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		CustomNo,
		IC_NO
	>
endif

DisplayErrorBox	proc	far
	uses	cx, dx, bp, ds
	.enter

	; lock the block that contains the error strings
	
	GetResourceHandleNS	ErrorArray, bx	; Interface handle to BX
	call	MemLock				; lock the block
	mov	ds, ax				; set up the segment
	mov	si, offset ErrorArray		; handle of error messages 
	mov	si, ds:[si]			; dereference the handle

EC <	cmp	bp, ERROR_LAST						>
EC <	ERROR_GE	DISPLAY_ERROR_BAD_ERROR_VALUE			>

	; assume notification type and error dialog box

	mov	ax, ((CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
		(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE))

	; search string not found message?

	cmp	bp, ERROR_NO_MATCH	
	jne	checkResort		; if not, skip

	mov	ax, ((CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE) or \
		(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE))
	jmp	common
checkResort:
ifdef GPC
	cmp	bp, WARNING_CONFIRM_DELETE
	je	affirmation
endif
	; resort warning message?

	cmp	bp, ERROR_RESORT_WARNING	
	jne	checkSearch		; if not, skip
affirmation::
	mov	ax, ((CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
		(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE))
	jmp	common

checkSearch:
	cmp	bp, ERROR_SEARCH_AT_END
	je	searchErr
	cmp	bp, ERROR_SEARCH_AT_BEG
	jne	checkIndex
searchErr:
	mov	ax, ((CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
		(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE))
	jmp	common

checkIndex:
	; index field empty error message?

	cmp	bp, ERROR_INDEX_FIELD
	jne	common

	; if so, provide custom monikers for the triggers

	mov	ax, ((CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
		(GIT_MULTIPLE_RESPONSE shl offset CDBF_INTERACTION_TYPE))

	shl	bp, 1				; multiply by two
	add	si, bp				; go to the correct messages
	mov	bp, ds:[si]			; text handle => BP
	mov	bx, ds:[bp]			; error string in DS:BX

	; set up the stack with correct parameters

	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customTriggers.segment, cs
	mov	ss:[bp].SDP_customTriggers.offset, offset customTriggerTable
	jmp	custom
common:
	shl	bp, 1				; multiply by two
	add	si, bp				; go to the correct messages
	mov	bp, ds:[si]			; text handle => BP
	mov	bx, ds:[bp]			; error string in DS:BX

	; set up the stack with correct parameters

	sub	sp, size StandardDialogParams
	mov	bp, sp
	clr	ss:[bp].SDP_customTriggers.segment
	clr	ss:[bp].SDP_customTriggers.offset
custom:
	mov	ss:[bp].SDP_customFlags, ax
	mov	ss:[bp].SDP_customString.segment, ds
	mov	ss:[bp].SDP_customString.offset, bx
	mov	ss:[bp].SDP_stringArg1.segment, cx
	mov	ss:[bp].SDP_stringArg2.offset, dx
	clr	ss:[bp].SDP_helpContext.segment

	; no string arg2 nor custom triggers
						; pass params on stack
	call	UserStandardDialog		; put up the dialog box

	clc					; assume normal termination
	cmp	ax, IC_NULL			; abnormally terminated?
	jne	done				; if not, skip
	stc					; if so, set carry flag
done:
	pushf					; save the carry flag
	GetResourceHandleNS	ErrorArray, bx	; Interface handle to BX
	call	MemUnlock			; unlock the block
	popf					; restore the carry flag

	.leave
	ret
DisplayErrorBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NewDBFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the Notes field DBItem before deleting the main
		record DBItem.

CALLED BY:	UTILITY

PASS:		di - DB Item to delete

RETURN:		nothing

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NewDBFree	proc	far		uses	es
	.enter

	push	di			; save the record handle
	call	DBLockNO		; open up this data block
	mov	di, es:[di]
	mov	di, es:[di].DBR_notes	; di - handle of notes data block
	call	DBUnlock
	tst	di			; no notes block?
	je	exit			; if not, exit
	call	DBFreeNO		; if so, delete it!
exit:
	pop	di			; restore the record handle 
	call	DBFreeNO		; delete it!

	.leave
	ret
NewDBFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextInMemBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the text string from a text object in a memory block

CALLED BY:	UTILITY

PASS:		bx:si - OD of text object

RETURN:		ax - handle of memory block
		cx - number of characters (length)

DESTROYED:	bx, si

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version
	witt	3/94		Call common with VIS_TEXT_GET_ALL_BLOCK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextInMemBlock	proc	far
	mov	ax, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	GetTextCommon
GetTextInMemBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextInMemBlockNoFixup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the text string from a text object in a memory block.
		Same as the routine above but ObjMessage is called with
		different flags .

CALLED BY:	UTILITY

PASS:		bx:si - OD of text object

RETURN:		ax - handle of memory block
		cx - number of characters (string length)

DESTROYED:	bx, si

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version
	witt	3/94		Call common with VIS_TEXT_GET_ALL_BLOCK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextInMemBlockNoFixup	proc	far
	mov	ax, mask MF_CALL
	FALL_THRU  GetTextCommon
GetTextInMemBlockNoFixup	endp

;-------------------------------------------------------------
;
;   PASS:	ax - ObjMessage MethodFlags
;		bx:si - OD of text object
;   RETURN:	ax - handle of memory block
;		cx - string length
;   DESTORYED:	none
;
GetTextCommon	proc	far
	push	bp, di, dx
	clr	dx				; allocate new mem block
	mov	di, ax				; di <- MethodFlags

	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	call	ObjMessage
	xchg	ax, cx				; cx <- number of characters
						; ax <- chunk's block handle
	pop	bp, di, dx
	ret
GetTextCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextInPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the text string from a text object to a seg:offset

CALLED BY:	SavePhoneStuff (UTILITY)

PASS:		bx:si - OD of text object
		cx:dx - ptr to text buffer

RETURN:		ax - handle of memory block
		cx - number of characters

DESTROYED:	bx, si

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
;;  Calls to GetTextInPointer are now in-lined.  I don't think this routine's
;;	documentation actually matches register reality.
;;				-- witt, March 1994.
GetTextInPointer	proc	far	uses	bp, di, dx
	.enter

	sub	sp, size VisTextGetTextRangeParameters
	mov	bp, sp				; ss:bp <- stack frame
	
	; Set up parameters for general routine

	mov	ss:[bp].VTGTRP_range.VTR_start.low,  0
	mov	ss:[bp].VTGTRP_range.VTR_start.high, 0
	
	mov	ss:[bp].VTGTRP_range.VTR_end.low,  TEXT_ADDRESS_PAST_END_LOW
	mov	ss:[bp].VTGTRP_range.VTR_end.high, TEXT_ADDRESS_PAST_END_HIGH
	mov	ss:[bp].VTGTRP_textReference.TR_type, TRT_POINTER
	mov	ss:[bp].VTGTRP_textReference.TR_ref.TRU_pointer.TRP_pointer.segment, cx
	mov	ss:[bp].VTGTRP_textReference.TR_ref.TRU_pointer.TRP_pointer.offset, dx
	clr	ss:[bp].VTGTRP_flags 		; no flag
	
	mov	dx, size VisTextGetTextRangeParameters
	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS \
			or mask MF_FIXUP_ES or mask MF_STACK
	call	ObjMessage		; read in text to pointer passed

;;#	ERROR	0		; is size really in CX ? (witt)
;;#				; doc sez length returned in dx.ax !

	; Restore the stack and quit.
	
	add	sp, size VisTextGetTextRangeParameters

	.leave
	ret
GetTextInPointer	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableObject/DisableObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/Disable an object

CALLED BY:	UTILITY

PASS:		bx:si - OD of object to enable/disable

RETURN:		nothing

DESTROYED:	ax, di, dx

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableObject	proc	far
	mov	ax, MSG_GEN_SET_ENABLED	
	mov	di, mask MF_FIXUP_DS
	mov	dl, VUM_NOW		; update it right now
	call	ObjMessage		; enable the object
	ret
EnableObject	endp

DisableObject	proc	far
	mov	ax, MSG_GEN_SET_NOT_ENABLED	
	mov	di, mask MF_FIXUP_DS
	mov	dl, VUM_NOW		; update it right now
	call	ObjMessage		; disable the object
	ret
DisableObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Enable{Disable}CopyRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable and disable some edit menu items.

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
EnableCopyRecord	proc	far
	GetResourceHandleNS	MenuResource, bx	
	mov	si, offset EditCopyRecord ; si - offset to copy record menu
	call	EnableObject		; enable copy record menu 
ifdef GPC
	;
	; delete record is modified at the same time
	;
	GetResourceHandleNS	MenuResource, bx	
	mov	si, offset EditDeleteRecord ; si - offset to delete record menu
	call	EnableObject		; enable delete record menu
	;
	; so is Notes button
	;
	GetResourceHandleNS	NotesTrigger, bx	
	mov	si, offset NotesTrigger ; si - offset to notes trigger
	call	EnableObject		; enable notes trigger
endif
	ret
EnableCopyRecord	endp

DisableCopyRecord	proc	far
	GetResourceHandleNS	MenuResource, bx	
	mov	si, offset EditCopyRecord ; si - offset to copy record menu
	call	DisableObject		; disable copy record menu 
ifdef GPC
	;
	; delete record is modified at the same time
	;
	GetResourceHandleNS	MenuResource, bx	
	mov	si, offset EditDeleteRecord ; si - offset to delete record menu
	call	DisableObject		; disable delete record menu 
	;
	; so is Notes button
	;
	GetResourceHandleNS	NotesTrigger, bx	
	mov	si, offset NotesTrigger ; si - offset to notes trigger
	call	DisableObject		; disable notes trigger
	;
	; also, close Notes DB
	;
	GetResourceHandleNS	NotesBox, bx	
	mov	si, offset NotesBox ; si - offset to notes DB
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		; disable the object
endif
	ret
DisableCopyRecord	endp

EnableUndo	proc	far
	GetResourceHandleNS	MenuResource, bx	
	mov	si, offset EditUndo	; si - offset to undo menu
	call	EnableObject		; enable undo menu 
	ret
EnableUndo	endp
	
DisableUndo	proc	far
	mov	ds:[undoAction], UNDO_NOTHING
	GetResourceHandleNS	MenuResource, bx	
	mov	si, offset EditUndo	; si - offset to undo menu
	call	DisableObject		; disable undo menu 
	ret
DisableUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLexicalValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a character, gets the lexical value of this character
		and converts it into uppercase.

CALLED BY:	

PASS:		if DBCS_PCGEOS
			ax - character
		else
			al - character
RETURN:		if DBCS_PCGEOS
			ax - updated 
			     if ax is LATIN1 then lexical value 
			     else unchanged
		else
			al - updated 

DESTROYED:	ah

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	8/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLexicalValue	proc	near
	uses	cx, dx

	.enter

if DBCS_PCGEOS
	tst	ah			; is this Latin1?
PZ <	jnz	checkKana		; if not, do DBCS thing		>
NPZ <	jnz	exit							>

else
	clr	ah
endif
	call	LocalLexicalValueNoCase	; get the lexical value of this char
	mov	cx, ax			; cx <- lexical value for char

	mov	ax, 'A'
	call	LocalLexicalValueNoCase
	mov	dx, ax			; dx <- lexical value for 'A'

	mov	ax, 'Z'
	call	LocalLexicalValueNoCase	; dx <- lexical value for 'Z'

	cmp	cx, dx			; is it an alphabet character?
	jb	notAlpha		; if not, skip
	cmp	cx, ax
	jbe	alpha
notAlpha:
	LocalLoadChar	ax, '*'		; the current letter is '*'
	jmp	exit

alpha:
	mov	ax, cx			; al <- lexical value for char
	sub	ax, dx			; convert lexical value to 'A'-based
	add	ax, 'A'			; convert lexical value to ASCII value
exit:
	.leave
	ret

if PZ_PCGEOS
checkKana:	; ok, ax is not LATIN_1
	
	cmp	ax, C_HIRAGANA_LETTER_SMALL_A	; Is this kana or katakana?
	jl	asterisk			; if not, asterisk
	cmp	ax, C_HIRAGANA_VOICED_ITERATION_MARK ; Is this kana
	jle	exit				; if so, done
	cmp	ax, C_KATAKANA_VOICED_ITERATION_MARK ; Is this katakana?
	jle	exit				; if so, do done
	cmp	ax, C_HALFWIDTH_IDEOGRAPHIC_PERIOD ; is this half katakana?
	jl	asterisk			; if not, asterisk
	cmp	ax, C_HALFWIDTH_KATAKANA_VOICED_ITERATION_MARK
	jle	exit				; yes, half kana.

asterisk:
	mov	ax, '*'
	jmp exit
endif
GetLexicalValue	endp
CommonCode	ends
