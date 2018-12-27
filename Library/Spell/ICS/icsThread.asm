COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Spell
MODULE:		ICS
FILE:		icsThread.asm

AUTHOR:		Andrew Wilson, Aug 12, 1992
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Initial revision

DESCRIPTION:
	This file contains code to implement the extra thread.	

	$Id: icsThread.asm,v 1.1 97/04/07 11:05:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallCSpell	macro	routine, retRegs

	local	copyLoop

if DBCS_PCGEOS	;-------------------------------------------------------------

    ifidn <retRegs>, <NONE>
	uses	ax, bx, cx, dx, ds, si, es, di
    endif
    ifidn <retRegs>, <ax>
	uses	bx, cx, dx, ds, si, es, di
    endif
    ifidn <retRegs>, <axdx>
	uses	bx, cx, ds, si, es, di
    endif

	.enter

	mov	bx, cx			; bx = ICBuff
	movdw	esdi, dxbp		; es:di = string
	call	LocalStringLength	; cx = length w/o null
	inc	cx			; include null
	sub	sp, cx
	segmov	es, ss			; es:di = stack buffer
	mov	di, sp
	movdw	dssi, dxbp
	mov	dx, cx			; save length
copyLoop:
	lodsw
	;
	; convert alternate apostrophe
	;
	cmp	ax, C_SINGLE_COMMA_QUOTATION_MARK
	jne	notApos
	mov	ax, C_APOSTROPHE_QUOTE
notApos:
	;
	; convert fullwidth
	;
	cmp	ax, C_FULLWIDTH_EXCLAMATION_MARK
	jb	notFullwidth
	cmp	ax, C_FULLWIDTH_SPACING_TILDE
	ja	notFullwidth
	sub	ax, (C_FULLWIDTH_EXCLAMATION_MARK-C_EXCLAMATION_MARK)
notFullwidth:
	tst	ah
	WARNING_NZ	SPELL_CHECKING_WORD_WITH_DBCS_CHAR
	stosb
	loop	copyLoop
	push	dx			; save length
	push	ss			; pass stack string pointer
	mov	ax, sp
	add	ax, 4			; (skip pass saved registers)
	push	ax
	push	bx			; pass ICBuff
	call	routine
	pop	bx			; bx = stack buffer size
	add	sp, bx			; free stack buffer

	.leave

else	;---------------------------------------------------------------------

	.enter
	pushdw	dxbp
	push	cx
	call	routine
	.leave

endif	;---------------------------------------------------------------------

endm

SpellCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHandleOfSpellThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the handle of the spell thread from the passed ICBuff

CALLED BY:	GLOBAL
PASS:		bx - handle of ICBuff
RETURN:		bx - handle of spell thread
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHandleOfSpellThread	proc	near	uses	ds, ax
	.enter
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[ICB_spellThread]
	tst	ax
	jz	createThread
exit:
	call	MemUnlock
	mov_tr	bx, ax
	.leave
	ret

createThread:

;	Create a thread to handle spell events

	push	es, ds, cx, dx, bp, di

	mov	bp, SPELL_THREAD_STACK_SIZE	;
	mov	cx, segment SpellThreadClass	;CX:DX <- ptr to class of 
	mov	dx, offset SpellThreadClass	; thread we are creating

	segmov	ds, ss				;DS <- updateable segment

	mov	ax, segment ProcessClass	;ES:DI <- class we are calling
	mov	es, ax
	mov	di, offset ProcessClass
	
	mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
	call	ObjCallClassNoLock
EC <	ERROR_C	COULD_NOT_CREATE_SPELL_THREAD				>
	pop	es, ds, cx, dx, bp, di

	mov	ds:[ICB_spellThread], ax
	jmp	exit

GetHandleOfSpellThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallSpellThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the spell thread associated with this 
		ICBuff. This only creates the thread if it doesn't already
		exist.

CALLED BY:	GLOBAL
PASS:		ax - message
		bx - handle of ICBuff
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallSpellThread	proc	near	uses	di
	.enter
	mov	di, mask MF_CALL
	call	ObjMessageSpellThreadCommon
	.leave
	ret
CallSpellThread	endp

ObjMessageSpellThreadCommon	proc	near	uses	bx, cx, bp
	.enter
	mov	cx, bx
	call	GetHandleOfSpellThread	;BX <- handle of thread to send
					; message to
	call	ObjMessage
	.leave
	ret
ObjMessageSpellThreadCommon	endp

CallSpellThreadFar	proc	far
	call	CallSpellThread
	ret
CallSpellThreadFar	endp

SendToSpellThreadFar	proc	far
	call	SendToSpellThread
	ret
SendToSpellThreadFar	endp

SendToSpellThread	proc	near	uses	di
	.enter
	clr	di
	call	ObjMessageSpellThreadCommon
	.leave
	ret
SendToSpellThread	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellThreadInitICBuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the IC Buff

CALLED BY:	GLOBAL
PASS:		cx - ICBuff
RETURN:		ax - error code
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellThreadInitICBuff	method	SpellThreadClass,
					MSG_SPELL_THREAD_INIT_IC_BUFF
	.enter
	push	cx
	call	ICGEOSplInitICBuff	;Returns error code in AX	
	.leave
	ret
SpellThreadInitICBuff	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellThreadExitICBuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exits the IC Buff

CALLED BY:	GLOBAL
PASS:		cx - ICBuff
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellThreadExitICBuff	method	SpellThreadClass,
					MSG_SPELL_THREAD_EXIT_IC_BUFF
	push	cx
	push	cx
	call	ICGEOSplExitICBuff
	pop	bx
	call	MemFree			;Free up the IC buff


;	Kill the spell thread	

	mov	ax, TGIT_THREAD_HANDLE	;Get the current thread handle
	clr	bx
	call	ThreadGetInfo
	mov_tr	bx, ax

	mov	ax, MSG_META_DETACH
	clr	dx, bp
	clr	di
	GOTO	ObjMessage
SpellThreadExitICBuff	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellThreadFreeUserDict
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees the user dictionary. (Currently
		only used in Redwood)

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	4/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOPPY_BASED_USER_DICT
SpellThreadFreeUserDict	method	SpellThreadClass, \
				MSG_SPELL_THREAD_FREE_USER_DICT
	call	ICGEOSplExit
	ret

SpellThreadFreeUserDict	endm
endif

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellThreadGetAlternate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets an alternate

CALLED BY:	GLOBAL
PASS:		cx - ICBuff
		ss:bp - ICGetAlternateParams
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellThreadGetAlternate	method	SpellThreadClass,
					MSG_SPELL_THREAD_GET_ALTERNATE
	.enter
	pushdw	ss:[bp].ICGAP_dest
	pushdw	ss:[bp].ICGAP_srcString
	push	cx
	push	ss:[bp].ICGAP_index
	call	ICGEOGetAlternate
DBCS <PrintMessage <fix for DBCS>>
	.leave
	ret
SpellThreadGetAlternate	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellThreadSpell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the ICGEOSpl entry point

CALLED BY:	GLOBAL
PASS:		cx - ICBuff
		dx:bp - ptr to null-terminated string
RETURN:		ax - error code
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellThreadSpell	method	SpellThreadClass,
					MSG_SPELL_THREAD_SPELL
	CallCSpell	ICGEOSpl, ax
	ret
SpellThreadSpell	endm


SpellCode	ends

IPCODE	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellThreadAddToUserDictionary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a word to the user dictionary

CALLED BY:	GLOBAL
PASS:		cx - ICBuff
		dx:bp - ptr to null-terminated string
RETURN:		ax - error code
		dx - status
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellThreadAddToUserDictionary	method	SpellThreadClass,
					MSG_SPELL_THREAD_ADD_TO_USER_DICTIONARY
	CallCSpell	IPGEOAddUser, axdx
	ret
SpellThreadAddToUserDictionary	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellThreadRemoveFromUserDictionary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes a word from the user dictionary

CALLED BY:	GLOBAL
PASS:		cx - ICBuff
		dx:bp - ptr to null-terminated string
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellThreadRemoveFromUserDictionary	method	SpellThreadClass,
				MSG_SPELL_THREAD_REMOVE_FROM_USER_DICTIONARY
	CallCSpell	IPGEODeleteUser, ax
	ret
SpellThreadRemoveFromUserDictionary	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellThreadUpdateUserDictionary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the user dictionary to disk if dirty

CALLED BY:	GLOBAL
PASS:		cx - ICBuff
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellThreadUpdateUserDictionary	method	SpellThreadClass,
				MSG_SPELL_THREAD_UPDATE_USER_DICTIONARY
	.enter
	push	cx
	call	UpdateUserDictionary
	.leave
	ret
SpellThreadUpdateUserDictionary	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellThreadBuildUserList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Builds a list of words

CALLED BY:	GLOBAL
PASS:		cx - ICBuff
RETURN:		ax - handle of data
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellThreadBuildUserList	method	SpellThreadClass,
				MSG_SPELL_THREAD_BUILD_USER_LIST
	.enter
	push	cx
	call	IPGEOBuildUserList
	.leave
	ret
SpellThreadBuildUserList	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellThreadResetIgnoreList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the ignore list

CALLED BY:	GLOBAL
PASS:		cx - ICBuff
RETURN:		nothing
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellThreadResetIgnoreList	method	SpellThreadClass,
				MSG_SPELL_THREAD_RESET_IGNORE_LIST
	.enter
	push	cx
	call	ICResetIgnoreUserDict
	.leave
	ret
SpellThreadResetIgnoreList	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellThreadIgnoreWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignores a word

CALLED BY:	GLOBAL
PASS:		cx - ICBuff
		dx.bp - null terminated string
RETURN:		nothing
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellThreadIgnoreWord	method	SpellThreadClass,
				MSG_SPELL_THREAD_IGNORE_WORD
	CallCSpell	ICGEOIgnoreString, NONE
	ret
SpellThreadIgnoreWord	endm

IPCODE	ends
