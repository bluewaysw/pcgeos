COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	Spell Check library
FILE:		spell.asm

AUTHOR:		Andrew Wilson, Feb  4, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 4/91		Initial revision

DESCRIPTION:
	This contains the externally callable routines for the spell library.

	$Id: spell.asm,v 1.1 97/04/07 11:05:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpellInit segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Standard library entry routine:
;
;	Value passed to LibraryEntry routine:
;	PASS:		di	= LibraryCallType
;				LCT_ATTACH	= library just loaded
;				LCT_NEW_CLIENT	= client of the library just
;						  loaded
;				LCT_CLIENT_EXIT	= client of the library is
;						  going away
;				LCT_DETACH	= library is about to be
;						  unloaded
;		cx	= handle of client geode, if LCT_NEW_CLIENT or
;			  LCT_CLIENT_EXIT
;	RETURN:		carry set on error
;
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version
	tyj	9/17/92		added thesaurus stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellEntry	proc	far
	mov	ax, segment idata
	mov	es, ax
	cmp	di, LCT_ATTACH
	jne	3$


;	IF ATTACH, ALLOCATE SEMAPHORES

	; first the spell semaphore

	mov	bx, 1
	call	ThreadAllocSem

	mov	ax, handle 0
	mov	es:[spellLibHandle], ax
	call	HandleModifyOwner
	mov	es:[spellSem], bx

	; then the thesaurus semaphore

	mov	bx, 1
	call	ThreadAllocSem

	mov	ax, handle 0
	call	HandleModifyOwner
	mov	es:[thesaurusSem], bx
	
	; and the hyphenation semaphore

	mov	bx, 1
	call	ThreadAllocSem

	mov	ax, handle 0
	call	HandleModifyOwner
	mov	es:[hyphenSem], bx

	; tell the text library about ourselves

	mov	bx, handle 0
	call	TextSetSpellLibrary
	
	mov	ax, enum Hyphenate
	call	ProcGetLibraryEntry
	pushdw	bxax
	call	TEXTSETHYPHENATIONCALL
	jmp	cleanExit

3$:
	cmp	di, LCT_DETACH						
	jne	cleanExit

;	Tell the text library that we are going away

	push	es			; C can trash es?

	clrdw	bxax
	call	TextSetSpellLibrary
	pushdw	bxax
	call	TEXTSETHYPHENATIONCALL

	call	ThesaurusClose	;Exit from the thesaurus library.
	call	HyphenClose	;Note: Thes & Hyphen open themselves now.

;	Don't do this call on the spell thread, as this may be from a dirty
;	shutdown, and if so, we don't want to have to start a thread, etc.

	;call	ICGEOSplExit	;Exit from the spell check library.

;	IF DETACH, FREE SEMAPHORES

	pop	es

	mov	bx, es:[spellSem]
	call	ThreadFreeSem
	mov	bx, es:[thesaurusSem]
	call	ThreadFreeSem
	mov	bx, es:[hyphenSem]
	call	ThreadFreeSem
cleanExit:
	clc
	ret
SpellEntry	endp
ForceRef	SpellEntry

SpellInit ends

;---
SpellCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates, initializes, and returns an ICBuff structure.
		This must be called once for every desired language.
		

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		BX <- handle of ICBuff structure
		AX <- error code
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICInit	proc	far		uses	cx, dx, di, si, bp, ds, es
	.enter
	mov	ax, segment idata
	mov	ds, ax
	mov	ax, size ICBuff
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or mask HAF_ZERO_INIT shl 8
	mov	bx, handle 0
	call	MemAllocSetOwner
	mov	ax, IC_RET_NOMEM
	jc	exit
	mov	ax, MSG_SPELL_THREAD_INIT_IC_BUFF
	call	CallSpellThread
	cmp	ax, IC_RET_OK			;
	jnz	doFree
EC  <	inc	ds:[referenceCount]					>
exit:
	.leave
	ret
doFree:
	call	MemLock
	mov	es, ax
	mov	ax, IC_RET_NO_USER_DICT
	test	es:[ICB_initFlags], mask SIF_USER_DICT_ERR
	jnz	10$
	mov	ax, IC_RET_NOMEM
	test	es:[ICB_initFlags], mask SIF_ALLOC_ERR
	jnz	10$
	mov	ax, IC_RET_NO_OPEN
	test	es:[ICB_initFlags], mask SIF_OPEN_ERR
	jnz	10$
	mov	ax, IC_RET_ERR
10$:
	call	ICStopCheck			;Nuke spell thread
	call	MemFree				;If couldn't init, exit
	jmp	exit
ICInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Terminates this applications interaction with the spell check
		library (frees its ICBuff)

CALLED BY:	GLOBAL
PASS:		bx - icbuff
RETURN:		ax - SpellErrors
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICExit	proc	far	uses	bx, cx, dx, di, si, bp, ds, es
	.enter

;	Exit/cleanup the data associated with the IC buff
;	NOTE: This causes the thread to exit

	mov	ax, MSG_SPELL_THREAD_EXIT_IC_BUFF
	call	SendToSpellThread

EC <	mov	ax, segment idata				>
EC <	mov	ds, ax						>
EC <	dec	ds:[referenceCount]				>
EC <	ERROR_S	APPLICATION_CALLED_ICEXIT_WITHOUT_CALLING_ICINIT>

	mov	ax, IC_RET_OK
	.leave
	ret
ICExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICFreeUserDict
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called (floppy user dicts) when the spell checker goes
		away.  Used to ensure it frees its user dictionary.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax - SpellErrors
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	4/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOPPY_BASED_USER_DICT

ICFreeUserDict	proc	far	uses	bx, cx, dx, di, si, bp, ds, es
	.enter

	mov	ax, MSG_SPELL_THREAD_FREE_USER_DICT
	call	SendToSpellThread
	mov	ax, IC_RET_OK
	.leave
	ret
ICFreeUserDict	endp

endif


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSourceStringLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine returns the length of the string pointed to by
		ds:si.

CALLED BY:	GLOBAL
PASS:		ds:si - ptr to string
RETURN:		cx - size of string (including null terminator)
DESTROYED:	al
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSourceStringLength	proc	near
	push	es, di
	segmov	es, ds
	mov	di, si
	mov	cx, -1
	clr	al
	repne	scasb
	not	cx
	pop	es, di
	ret
GetSourceStringLength	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICCnv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine to convert string in GEOS character set at ds:si
		to string at es:di

CALLED BY:	GLOBAL
PASS:		ds:si <- null-terminated string to convert
		es:di <- ptr to dest for converted string
		ax <- DEC_TO_PC or PC_TO_DEC
RETURN:		cx - size of string (not including null terminator)
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICCnv	proc	far		uses	ax, si, di

	.enter

;	Just copy the string over for now...

	call	GetSourceStringLength

	push	cx
	shr	cx, 1
	jnc	10$
	movsb  
10$:
	rep	movsw
	pop	cx
	.leave
	ret
ICCnv	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICGetAlternate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns an alternate spelling.

CALLED BY:	GLOBAL
PASS:		es:di <- ptr to store alternate spelling
		bx <- handle of ICBuff
		ax <- index of alternate spelling entry we desire (0 <- 1st
		   	 entry)
      		ds:si <- source string to get alternates for

RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICGetAlternate	proc	far	uses	ax, bx, cx, dx, bp, di, si, es, ds
if DBCS_PCGEOS
sbcsBuf		local	SPELL_MAX_WORD_LENGTH dup (char)
fullWidthFlag	local	word
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ds	 					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	pushdw	esdi
	push	bp
	push	ss
	lea	di, sbcsBuf
	push	di
	pushdw	dssi
	push	bx
	push	ax
	mov	ax, {wchar} ds:[si]
	mov	fullWidthFlag, ax
;if ICGEOGetAlternate actually used the source string, we'd need to convert
;it to SBCS from DBCS (see CallCSpell) - brianc 4/25/94
	;call	ICGEOGetAlternate
	pop	bp
	popdw	esdi
	segmov	ds, ss
	lea	si, sbcsBuf
	clr	ah
	push	di
copyLoop:
	lodsb
	stosw
	tst	al
	jnz	copyLoop
	pop	di
	;
	; convert alternate to full-width, if needed
	;	es:di = dest buffer (DBCS'ed SBCS)
	;
	mov	ax, fullWidthFlag
	cmp	ax, C_FULLWIDTH_EXCLAMATION_MARK
	jb	notFullWidth
	cmp	ax, C_FULLWIDTH_SPACING_TILDE
	ja	notFullWidth
	segmov	ds, es				; ds:si = es:di
	mov	si, di
fullWidthLoop:
	lodsw
	tst	ax
	jz	notFullWidth
	add	ax, (C_FULLWIDTH_EXCLAMATION_MARK-C_EXCLAMATION_MARK)
	stosw
	jmp	fullWidthLoop

notFullWidth:
else
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ds	 					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	pushdw	esdi
	pushdw	dssi
	push	bx
	push	ax
	;call	ICGEOGetAlternate
endif
	.leave
	ret
ICGetAlternate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICCheckWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the passed word

CALLED BY:	GLOBAL
PASS:		DS:SI - word to spell check
		CX - ICBuff
RETURN:		AX - SpellResult
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICCheckWord	proc	far
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
	mov	bx, cx
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
	push	bx
	clr	cx			;Clear SpellCheckFlags
	call	SpellCheckWord
	pop	bx
	call	HandleV
	.leave
	ret
ICCheckWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIsPunct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the passed word is word-breaking punctuation.

CALLED BY:	GLOBAL
PASS:		al - char to test
RETURN:		carry set if is punctuation
DESTROYED:	nada

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIsPunct	proc	near	uses	es, di, cx
	.enter
	push	ax
	mov	cx, bx
	call	ICGetLanguage
	segmov	es, cs
	mov	di, offset punctTab
	mov	cx, length punctTab
	cmp	al, SL_ENGLISH
	jne	10$
	mov	di, offset englishPunctTab
	mov	cx, length englishPunctTab + length punctTab
10$:
	pop	ax
	LocalFindChar
	stc
	jz	exit		;If match found, branch to break word
	clc
exit:
	.leave
	ret
CheckIsPunct	endp

;	ONLY WANT TO BREAK WORDS ON HARD-HYPHENS FOR ENGLISH!

if DBCS_PCGEOS
englishPunctTab	wchar	C_NON_BREAKING_HYPHEN, C_EN_DASH, C_EM_DASH,
			C_HYPHEN_MINUS
punctTab	wchar	C_SLASH, C_HORIZONTAL_ELLIPSIS
else
englishPunctTab	char	C_NONBRKHYPHEN, C_ENDASH, C_EMDASH, C_MINUS
punctTab	char	C_SLASH, C_ELLIPSIS
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckPunctSubWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This breaks up the passed word into sub words along the
		imbedded punctuation lines, and spell checks each subword
		(This way, we accept words like "him/her" and "two-year-old").

CALLED BY:	GLOBAL
PASS:		ds:si - ptr to word to check
		bx - handle of ICBuff
		cx - recursive level
RETURN:		ax - SpellResult
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckPunctSubWords	proc	near	uses	cx, si
SBCS <	wordBuf		local	SPELL_MAX_WORD_LENGTH dup (char)	>
DBCS <	wordBuf		local	SPELL_MAX_WORD_LENGTH dup (wchar)	>
	.enter
nextWord:
SBCS <	cmp	{byte} ds:[si], 0	;If at end of source string, exit >
DBCS <	cmp	{wchar} ds:[si], 0	;If at end of source string, exit >
	mov	ax, IC_RET_PRE_PROC
	je	exit
	push	cx
	mov	cx, bx
	call	ICResetSpellCheck
	pop	cx
	push	es
	segmov	es, ss
	lea	di, wordBuf		;ES:DI <- ptr to but sub-string
charLoop:
	LocalGetChar ax, dssi		;Get next character from source string.
	LocalIsNull ax
	jnz	10$
	LocalPrevChar dssi
	jmp	checkWord
10$:
	call	CheckIsPunct
	jc	checkWord		;If is punct, branch

	LocalPutChar esdi, ax
	jmp	charLoop
checkWord:
	LocalClrChar ax
	LocalPutChar esdi, ax
	pop	es
SBCS <	cmp	{byte} wordBuf, 0	;If null word, don't verify, just >
DBCS <	cmp	{wchar} wordBuf, 0	;If null word, don't verify, just >
	jz	nextWord		; branch (treat multiple punctuation as
					; a single word break)
	push	ds, si
	segmov	ds, ss
	lea	si, wordBuf
	call	ICSpl
	pop	ds, si

;	IF THIS WORD CHECKED OUT OK, BRANCH TO CHECK NEXT WORD

	cmp	ax, IC_RET_FOUND
	je	nextWord
	cmp	ax, IC_RET_PRE_PROC
	je	nextWord
	cmp	ax, IC_RET_IGNORED
	je	nextWord
exit:
	.leave
	ret
CheckPunctSubWords	endp


SpellCheckFlags	record
	SCF_NUKED_LEADING_APOSTROPHE:1
	SCF_NUKED_POSSESSIVE:1
	:14
SpellCheckFlags	end


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckPossessive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spell checks the passed word without the trailing possessive.

CALLED BY:	GLOBAL
PASS:		ds:si - ptr to word to check
		bx - handle of ICBuff
		es - segment of locked ICBuff
		cx - SpellCheckFlags
RETURN:		ax - SpellResult

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	NOTE: This sets a bit in CX that causes the ICBuff *not* to be
 	      reset, as we want the possessive to get parsed off.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckPossessive	proc	near	uses	ds, si
SBCS <	wordBuf		local	SPELL_MAX_WORD_LENGTH dup (char)	>
DBCS <	wordBuf		local	SPELL_MAX_WORD_LENGTH dup (wchar)	>
	.enter
	push	es, cx			;Save spell check flags
	mov	cx, bx
	call	ICGetTextOffsets
	dec	cx			;CX <- (# chars in string)-2 (w/o 's).
	segmov	es, ss
	lea	di, wordBuf
	LocalCopyNString
	LocalClrChar ax
	LocalPutChar esdi, ax
	pop	es, cx			;Restore spell check flags
	segmov	ds, ss
	ornf	cx, mask SCF_NUKED_POSSESSIVE
	lea	si, wordBuf
	call	SpellCheckWord
	andnf	cx, not mask SCF_NUKED_POSSESSIVE
	.leave
	ret
CheckPossessive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellCheckWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spell checks the passed word - is called recursively

CALLED BY:	GLOBAL
PASS:		ds:si - ptr to word to check
		bx - handle of ICBuff
		cx - SpellCheckFlags
RETURN:		ax - SpellResult
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellCheckWord	proc	near		uses	di, dx
	.enter

;	CALL THE SPELL CHECK LIBRARY TO SEE IF THE WORD IS OK

	mov	ax, ST_VERIFY
	call	ICSetTask
	call	ICSpl
	cmp	ax, IC_RET_ALTERNATE
	je	10$
	cmp	ax, IC_RET_NOT_FOUND
	jne	exit
10$:

;	DO SPECIAL CHECK FOR ENGLISH-LANGUAGE POSSESSIVES

	call	ICGetLanguage
	cmp	al, SL_ENGLISH
	jne	noPoss
	push	cx
	mov	cx, bx
	call	ICGetTextOffsets
	mov	di, cx
DBCS <	shl	di, 1							>
	pop	cx
	add	di, si			;DS:DI <- ptr to last char in word
	LocalPrevChar dsdi
	cmp	di, si
	jbe	noPoss			;If no room for possessive, branch
SBCS <	cmp	{byte} ds:[di], C_SNG_QUOTE				>
DBCS <	cmp	{wchar} ds:[di], C_APOSTROPHE_QUOTE			>
	jz	isApos
SBCS <	cmp	{byte} ds:[di], C_QUOTESNGRIGHT				>
DBCS <	cmp	{wchar} ds:[di], C_SINGLE_COMMA_QUOTATION_MARK	>
	jnz	noPoss
isApos:
	LocalNextChar dsdi
SBCS <	cmp	{byte} ds:[di], 's'					>
DBCS <	cmp	{wchar} ds:[di], 's'					>
	jz	isPoss
SBCS <	cmp	{byte} ds:[di], 'S'					>
DBCS <	cmp	{wchar} ds:[di], 'S'					>
	jnz	noPoss
isPoss:
	test	cx, mask SCF_NUKED_POSSESSIVE	;If already nuked possessive,
	jnz	pastPoss			; branch
	call	CheckPossessive
	jmp	resetExit
pastPoss:
	clr	cx
	jmp	resetExit
noPoss:

;	CHECK FOR EMBEDDED PUNCTUATION. IF ANY FOUND, BREAK UP THE WORDS AT
;	THE EMBEDDED PUNCTUATION POINTS AND RE-SUBMIT THEM TO THE SPELL
;	LIBRARY

	push	ax
	call	ICCheckForEmbeddedPunctuation
	tst	ax
	pop	ax
	jz	exit			;Exit if no embedded punctuation
	call	CheckPunctSubWords
resetExit:
	tst	cx		;If this is not the outer level of the
	jnz	exit		; recursion, then branch.

;	WE HAVE TRIED TO PARTIALLY VERIFY THE WORD. IF WE COULD NOT VERIFY THE
;	WORD IN PARTS, RE-VERIFY THE WHOLE WORD, SO WE CAN MORE EASILY GET
;	ALTERNATES, AND SO THE ICBUFF FIELDS WILL BE SET UP CORRECTLY.

	cmp	ax, IC_RET_FOUND
	je	exit

	cmp	ax, IC_RET_PRE_PROC
	je	exit
	
	cmp	ax, IC_RET_IGNORED
	je	exit

recheckEntireWord:
	mov	cx, bx
	call	ICResetSpellCheck	;This to get rid of any stray 
					; "duplicate word" errors.
	mov	ax, ST_VERIFY
	call	ICSetTask
	call	ICSpl
exit:
	.leave
	ret
SpellCheckWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICSpl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Standard entry point for the spell check library.

CALLED BY:	GLOBAL
PASS:		BX <- ICBuff structure (returned by ICInit)
		DS:SI <- ptr to null terminated string.
RETURN:		AX <- error code
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICSpl	proc	far	uses	dx, bp
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
	movdw	dxbp, dssi		
	mov	ax, MSG_SPELL_THREAD_SPELL
	call	CallSpellThread
	.leave
	ret
ICSpl	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICStopCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Denotes that an active spell check as been stopped, so we
		kill the spell thread

CALLED BY:	GLOBAL
PASS:		bx - ICBuff
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICStopCheck	proc	far	uses	ax, bx, cx, dx, bp, di, ds
	.enter

;	If there is a spell thread, then kill it.

	call	MemLock
	mov	ds, ax
	clr	ax
	xchg	ax, ds:[ICB_spellThread]
	call	MemUnlock
	tst	ax
	jz	exit
	mov_tr	bx, ax			;BX <- handle of spell thread

;	This has to be a MF_CALL, to ensure that the queue is cleared on
;	the other thread before freeing.

	mov	ax, MSG_META_DETACH
	clr	dx, bp
	mov	di, mask MF_CALL
	call	ObjMessage
exit:
	.leave
	ret
ICStopCheck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICGetNumAlts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the # alternate spellings in the passed ICBuff.

CALLED BY:	GLOBAL
PASS:		bx <- handle of ICBuff
RETURN:		ax <- # alternate spellings
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICGetNumAlts	proc	far	uses	ds
	.enter
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[ICB_numAlts]
	call	MemUnlock
	.leave
	ret
ICGetNumAlts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICSetTask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called to set the task for the passed
		ICBuff.

CALLED BY:	GLOBAL
PASS:		bx <- ICBuff
		ax <- SpellTask
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICSetTask	proc	far	uses	ds, ax
	.enter
	push	ax
	call	MemLock
	mov	ds, ax
	pop	ds:[ICB_task]
	call	MemUnlock
	.leave
	ret
ICSetTask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICCheckForEmbeddedPunctuation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if there is imbedded punctuation in the word.

CALLED BY:	GLOBAL
PASS:		BX <- handle of ICBuff
RETURN:		AX <- non-zero if imbedded punctuation
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICCheckForEmbeddedPunctuation	proc	far	uses	es, cx, di
	.enter
	call	MemLock
	mov	es, ax
	mov	cx, offset ICB_endMaps - offset ICB_maps
	mov	di, offset ICB_slashMap
	clr	ax
SBCS <	repe	scasb							>
DBCS <	repe	scasw							>
	jz	10$
	mov	ax, -1
10$:
	call	MemUnlock
	.leave
	ret
ICCheckForEmbeddedPunctuation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICGetTextOffsets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the offsets into the text string that was passed to ICSpl
		where the spell-checked word actually began/ended.

CALLED BY:	GLOBAL
PASS:		CX <- handle of ICBuff
RETURN:		AX <- ICB_lside value
		CX <- ICB_rside value
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICGetTextOffsets	proc	far	uses	ds
	.enter
	mov	bx, cx
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[ICB_lside]
	mov	cx, ds:[ICB_rside]
	call	MemUnlock
	.leave
	ret
ICGetTextOffsets	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICGetLanguage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current language.

CALLED BY:	GLOBAL
PASS:		bx - handle of ICBuff
RETURN:		al - language
DESTROYED:	ah
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICGetLanguage	proc	far		uses	ds
	.enter
	call	MemLock
	mov	ds, ax
	mov	al, ds:[ICB_language]
	call	MemUnlock
	.leave
	ret
ICGetLanguage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICGetErrorFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current error flags.

CALLED BY:	GLOBAL
PASS:		cx - handle of ICBuff
RETURN:		ax - SpellErrorFlagsHigh
		cx - SpellErrorFlags
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICGetErrorFlags	proc	far		uses	ds
	.enter
	mov	bx, cx
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[ICB_errorFlagsHigh]
	mov	cx, ds:[ICB_errorFlags]
	call	MemUnlock
	.leave
	ret
ICGetErrorFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICResetSpellCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the double-word stuff.

CALLED BY:	GLOBAL
PASS:		cx - handle of ICBuff
RETURN:		nothing
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICResetSpellCheck	proc	far		uses	ds, ax
	.enter
	mov	bx, cx
	call	MemLock
	mov	ds, ax
	mov	ds:[ICB_prevWord][0], 0
	call	MemUnlock
	.leave
	ret
ICResetSpellCheck	endp

SpellCode	ends

IPCODE	segment	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICAddUser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the passed string to the user dictionary.

CALLED BY:	GLOBAL
PASS:		*ds:si - string to add to the dictionary
		bx - handle of ICBuff
RETURN:		ax - SpellResult (0 if no error)
		dx - UserResult
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICAddUser	proc	far	uses	bp
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif

	movdw	dxbp, dssi
	mov	ax, MSG_SPELL_THREAD_ADD_TO_USER_DICTIONARY
	call	CallSpellThreadFar
	.leave
	ret 
ICAddUser	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICDeleteUser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the passed string to the user dictionary.

CALLED BY:	GLOBAL
PASS:		*ds:si - string to add to the dictionary
		bx - handle of ICBuff
RETURN:		ax - SpellResult
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICDeleteUser	proc	far	uses	dx, bp
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
	movdw	dxbp, dssi
	mov	ax, MSG_SPELL_THREAD_REMOVE_FROM_USER_DICTIONARY
	call	CallSpellThreadFar
	.leave
	ret 
ICDeleteUser	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICBuildUserList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the passed string to the user dictionary.

CALLED BY:	GLOBAL
PASS:		bx - handle of ICBuff
RETURN:		bx - handle of info for user dictionary (or 0)
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICBuildUserList	proc	far	uses	ax, dx
	.enter
	mov	ax, MSG_SPELL_THREAD_BUILD_USER_LIST
	call	CallSpellThreadFar
	mov_tr	bx, ax				;BX <- handle of user info
	.leave
	ret 
ICBuildUserList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICUpdateUser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the call to update the user dictionary on disk.

CALLED BY:	GLOBAL
PASS:		bx - handle of ICBuff
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICUpdateUser	proc	far	uses	ax, ds, dx
	.enter
	mov	ax, segment idata
	mov	ds, ax
	tst	ds:[userDictIsDirty]	;If the user dict is not dirty, exit
	jz	exit
	mov	ax, MSG_SPELL_THREAD_UPDATE_USER_DICTIONARY

	;use CallSpellThreadFar instead to force the PrefMgr thread to
	;wait until the spell thread has finished updating the dictionary
	;file.
	;call	SendToSpellThreadFar
	call	CallSpellThreadFar
exit:
	.leave
	ret
ICUpdateUser	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICIgnore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignores the passed text string.

CALLED BY:	GLOBAL
PASS:		ds:si <- string to ignore
		bx - handle of ICBuff
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICIgnore	proc	far	uses	ax, dx, bp
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
	movdw	dxbp, dssi
	mov	ax, MSG_SPELL_THREAD_IGNORE_WORD
	call	CallSpellThreadFar
	.leave
	ret
ICIgnore	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICResetIgnore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the contents of the ignore buffer.

CALLED BY:	GLOBAL
PASS:		bx - handle of ICBuff
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICResetIgnore	proc	far	uses	ax, dx
	.enter
	mov	ax, MSG_SPELL_THREAD_RESET_IGNORE_LIST
	call	SendToSpellThreadFar
	.leave
	ret
ICResetIgnore	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICGetAnagrams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find anagrams for the passed word

CALLED BY:	GLOBAL
PASS:		DS:SI - word to spell check
		BX - ICBuff
		CX - minimum length of anagrams
RETURN:		AX - SpellResult
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICGetAnagrams	proc	far
	.enter

if NO_ANAGRAM_WILDCARD_IN_SPELL_LIBRARY

   EC <	ERROR	ANAGRAMS_AND_WILDCARDS_NOT_SUPPORTED			>

else

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	push	bx							>
EC <	mov	bx, ds							>
EC <	call	ECAssertValidFarPointerXIP				>
EC <	pop	bx							>
endif

	push	ds
	call	MemLock
	mov	ds, ax
	mov	ds:[ICB_subsetAnagram], cx
	call	MemUnlock
	pop	ds

	mov	ax, ST_ANAGRAM
	call	ICSetTask
	call	ICSpl
endif

	.leave
	ret
ICGetAnagrams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICGetWildcards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find wildcards for the passed word

CALLED BY:	GLOBAL
PASS:		DS:SI - word to spell check
		BX - ICBuff
RETURN:		AX - SpellResult
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICGetWildcards	proc	far
	.enter

if NO_ANAGRAM_WILDCARD_IN_SPELL_LIBRARY

   EC <	ERROR	ANAGRAMS_AND_WILDCARDS_NOT_SUPPORTED			>

else

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	push	bx							>
EC <	mov	bx, ds							>
EC <	call	ECAssertValidFarPointerXIP				>
EC <	pop	bx							>
endif

	mov	ax, ST_WILDCARD
	call	ICSetTask
	call	ICSpl
endif

	.leave
	ret
ICGetWildcards	endp

IPCODE	ends
