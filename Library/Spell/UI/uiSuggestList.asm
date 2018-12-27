COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Spell
MODULE:		UI
FILE:		uiSuggestList.asm

AUTHOR:		Andrew Wilson, Sep 30, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/30/92		Initial revision

DESCRIPTION:
	Contains code to implement the suggest list.

	$Id: uiSuggestList.asm,v 1.1 97/04/07 11:08:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpellClassStructures	segment	resource
	SuggestListClass	
SpellClassStructures	ends

SpellControlCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallSpellControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the passed message to the spell control

CALLED BY:	GLOBAL
PASS:		message args
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallSpellControl	proc	near
	.enter
	push	si
	mov	bx, segment SpellControlClass
	mov	si, offset SpellControlClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di		;CX <- handle of classed event
	pop	si

	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	GenCallParent
	.leave
	ret
CallSpellControl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SuggestListSelectEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user has clicked on one of the suggestions. Replace the 
		text in the text object with this text.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SuggestListSelectEntry	method	dynamic SuggestListClass,
					MSG_SUGGEST_LIST_SELECT_ENTRY
	bufHandle	local	hptr	\
		push	ds:[di].SLI_icBuff
	sourceString	local	SPELL_MAX_WORD_LENGTH	dup (char)
	altString	local	SPELL_MAX_WORD_LENGTH	dup (char)
	.enter

 	;
 	; REDWOOD
 	;
 	push	bx, si, di, bp
 	call	ObjBlockGetOutput
 	mov	di, mask MF_CALL or mask MF_FIXUP_DS
 	mov	ax, MSG_GEN_CONTROL_GET_NORMAL_FEATURES
 	call	ObjMessage 
 	pop	bx, si, di, bp
 
 	test	ax, mask SF_REPLACE_ALL or mask SF_REPLACE_CURRENT
 	jz	exit
	tst	bufHandle
	jz	exit

;	FIND OUT WHICH ELEMENT IS SELECTED

	push	bp			;Save ptr to locals
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock
	mov_tr	cx, ax			;put selection in cx
	pop	bp


;	GET THE UNKNOWN WORD FROM THE DISPLAY OBJECT

					;CX <- entry number selected (0-n)
	push	bp, cx
	mov	dx, ss
	lea	bp, sourceString
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	si, offset SpellUnknownText
	call	ObjCallInstanceNoLock
	pop	bp, ax
	tst	sourceString[0]
	jz	exit

;	GET THE SUGGESTED WORD IN "altString"

	push	ds, bx
	mov	cx, ss
	mov	ds, cx
	mov	es, cx
	lea	si, sourceString		;DS:SI <- unknown word
						; (must be passed to retrieve
						; any stripped punctuation).
	lea	di, altString			;ES:DI <- ptr to put word
	mov	bx, bufHandle
	call	ICGetAlternate
	pop	ds, bx
	tst	altString[0]
	jnz	setText
exit:
	.leave
	ret

;	SET THE TEXT IN THE REPLACEMENT TEXT AREA
setText:
	push	bp
	lea	cx, altString		;SS:CX <- null-term'd replace string
	mov	dx, size VisTextReplaceParameters
	sub	sp, dx
	mov	bp, sp			;SS:BP <- VisTextReplaceParameters

	clrdw	ss:[bp].VTRP_range.VTR_start
	movdw	ss:[bp].VTRP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTRP_insCount.high, INSERT_COMPUTE_TEXT_LENGTH
	movdw	ss:[bp].VTRP_pointerReference, sscx
	mov	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
	mov	ss:[bp].VTRP_flags, mask VTRF_USER_MODIFICATION
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	mov	si, offset SpellReplaceText
	call	ObjCallInstanceNoLock
	add	sp, size VisTextReplaceParameters

	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	call	ObjCallInstanceNoLock
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock
	pop	bp
	jmp	exit
SuggestListSelectEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SuggestListGetSuggestion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the method sent from the alternate spelling dynamic
		list when it wants a moniker.

CALLED BY:	GLOBAL
PASS:		cx:dx <- list to send reply to
		bp - index of alternate requested
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SuggestListGetSuggestion	method	dynamic SuggestListClass,
				MSG_SUGGEST_LIST_GET_SUGGESTION

	entryNum	local	word		\
			push	bp
	replyObj	local	optr		\
			push	cx, dx
	sourceString	local	SPELL_MAX_WORD_LENGTH	dup (char)
	altString	local	SPELL_MAX_WORD_LENGTH	dup (char)
	monikerFrame	local	ReplaceItemMonikerFrame

	.enter
	mov	bx, ds:[di].SLI_icBuff

	tst	bx
	jz	noAlternates	;Nothing there, branch.  10/20/93 cbh

	call	ICGetNumAlts
	tst	ax
	jz	noAlternates	;Branch if we have alternates

	push	bp
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	segmov	dx, ss
	lea	bp, sourceString	;sourceString <- text in unknownWord
					; display
	mov	si, offset SpellUnknownText
	call	ObjCallInstanceNoLock
	pop	bp

	mov	si, ss
	mov	ds, si
	mov	es, si
	lea	si, sourceString	;DS:SI <- ptr to unknown word 
	lea	di, altString		;ES:DI <- ptr to dest for alt string
	mov	ax, entryNum
	call	ICGetAlternate
	clr	cx			;enable the item
common:

	movdw	monikerFrame.RIMF_source, esdi
	mov	ax, entryNum
	mov	monikerFrame.RIMF_item, ax
	mov	monikerFrame.RIMF_itemFlags, cx
	mov	monikerFrame.RIMF_sourceType, VMST_FPTR
	mov	monikerFrame.RIMF_dataType, VMDT_TEXT
	mov	monikerFrame.RIMF_length, 0
	
	push	bp
	movdw	bxsi, replyObj
	lea	bp, monikerFrame
	mov	dx, size monikerFrame
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	pop	bp

	.leave
	ret

noAlternates:

;	WE HAVE NO ALTERNATES, SO JUST PUT UP "No Suggestions Found"

	mov	bx, handle Strings
	call	MemLock	;Lock localizable string resource
	mov	ds, ax			;DS:SI <- offset to string to display
	mov	si, ds:[SpellNoSuggestionsString]
	segmov	es, ss			;ES:DI <- ptr to dest to display string
	lea	di, altString		;
	ChunkSizePtr	ds, si, cx	;CX <- # bytes in string
	push	di
	rep	movsb			;Copy over string
	pop	di
	call	MemUnlock		;Unlock localizable strings resource
	mov	cx, mask RIMF_NOT_ENABLED	;don't enable the item
	jmp	common			;
SuggestListGetSuggestion	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SuggestListReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the dynamic list (sets the # items to 0, and clears 
		out the cached info).

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SuggestListReset	method	SuggestListClass, MSG_SUGGEST_LIST_RESET
ifdef GPC_SPELL
	mov	bx, ds:[LMBH_handle]
	movdw	ds:[di].GIGI_destination, bxsi
endif
	clr	ds:[di].SLI_icBuff

	mov	ax,MSG_GEN_DYNAMIC_LIST_INITIALIZE
	clr	cx
ifdef GPC_SPELL
	call	ObjCallInstanceNoLock
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_SUGGEST_LIST_GENERATE_SUGGESTIONS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	cx, dx			;Select the first item in the list
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	mov	ax, MSG_SUGGEST_LIST_SELECT_ENTRY
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage
else
	GOTO	ObjCallInstanceNoLock
endif
SuggestListReset	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SuggestListVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does special stuff for when the list comes on-screen

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifndef GPC_SPELL
SuggestListVisOpen	method	SuggestListClass, MSG_VIS_OPEN
	mov	bx, ds:[LMBH_handle]
	movdw	ds:[di].GIGI_destination, bxsi
	mov	di, offset SuggestListClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_SUGGEST_LIST_GENERATE_SUGGESTIONS
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	GOTO	ObjMessage
SuggestListVisOpen	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SuggestListGenerateSuggestions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suggest spellings in the box.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SuggestListGenerateSuggestions	method	SuggestListClass, 
				MSG_SUGGEST_LIST_GENERATE_SUGGESTIONS
	.enter

;	Ignore this if we are disabled.

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_ENABLED
	je	alreadyHaveSuggestionsShort

;	Don't suggest if we already have suggestions.

	mov	di, ds:[si]		;
	add	di, ds:[di].SuggestList_offset
	tst	ds:[di].SLI_icBuff
	jz	markBusy
alreadyHaveSuggestionsShort:
	jmp	alreadyHaveSuggestions
markBusy:
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	UserCallApplication

	mov	ax, MSG_SC_GET_IC_BUFF
	call	CallSpellControl
	mov	di, ds:[si]
	add	di, ds:[di].SuggestList_offset
	mov	ds:[di].SLI_icBuff, ax

EC <	tst	ax							>
EC <	ERROR_Z	CONTROLLER_OBJECT_INTERNAL_ERROR			>

   	mov_tr	bx, ax			;BX <- ICBuff
	;
	; Grab exclusive access to ICBuff to avoid getting into situation
	; where one thread is doing ICCheckWord while another is looping
	; over the alternates in SuggestListGenerateSuggestions.  Much
	; confusion in the C code would ensue otherwise.  It'd be better
	; to synchronize things at a higher level, but there are too many
	; holes in the communication between the spell control and the
	; target object.  If SuggestListGenerateSuggestions blocks, we can
	; get an empty suggestion list, but this is harmless - brianc 10/28/94
	;
	call	HandleP
	mov	ax, ST_CORRECT
	call	ICSetTask

;	Get alternates

	push	bx
	push	ds, si
FXIP <	clr	si							>
FXIP <	push	si							>
FXIP <	segmov	ds, ss, si						>
FXIP <	mov	si, sp			;ds:si = ptr to null str	>
NOFXIP<	segmov	ds, cs							>
NOFXIP<	mov	si, offset nullString					>
5$:
	call	ICSpl			;Keep looping until we have all the
					; alternates
	cmp	ax, IC_RET_FOUND	;As long as we find alternates, branch
	jz	5$			; to get more
FXIP <	pop	si			;restore the stack		>
	pop	ds, si
	pop	bx
	call	HandleV

	call	ICGetNumAlts
	mov_tr	cx, ax
	jcxz	noItems
initList:
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	ObjCallInstanceNoLock

;
;	If we are in the separate box, select one of the items, and set the
;	box modified so the "Use This Suggestion" trigger will be enabled.
;
	mov	ax, MSG_GEN_CONTROL_GET_NORMAL_FEATURES
	call	CallSpellControl
EC <	test	ax, mask SF_SUGGESTIONS					>
EC <	ERROR_Z	CONTROLLER_OBJECT_INTERNAL_ERROR			>
	test	ax, mask SF_SIMPLE_MODAL_BOX	
	jz	exit

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	cx			;Select the first item in the list
	clr	dx
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	cl, -1			;CX <- non-zero to make modified
	call	ObjCallInstanceNoLock

exit:
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	UserCallApplication
alreadyHaveSuggestions:
	.leave
	ret
noItems:

	mov	ax, MSG_GEN_CONTROL_GET_NORMAL_FEATURES
	call	CallSpellControl
EC <	test	ax, mask SF_SUGGESTIONS					>
EC <	ERROR_Z	CONTROLLER_OBJECT_INTERNAL_ERROR			>

	test	ax, mask SF_SIMPLE_MODAL_BOX
	jnz	informUser

if KEYBOARD_ONLY_UI
	;
	; No items in popup list, let's dismiss the menu after we're done.
	; 10/20/93 cbh
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	VisCallParent	;terrible, but let's see..
endif

	mov	cx, 1
	jmp	initList

informUser:

;	There were no items in the standalone box - notify the user and close
;	the box

	mov	ax, (CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	mov	bx, offset SpellExplicitNoSuggestionsString
	call	SpellPutupBox

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	GenCallParent
	jmp	exit
SuggestListGenerateSuggestions	endp
	
SBCS <nullString	char	0					>
DBCS <nullString	wchar	0					>

SpellControlCode	ends
