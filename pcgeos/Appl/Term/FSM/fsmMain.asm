COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		FSM
FILE:		fsmMain.asm

AUTHOR:		Dennis Chow, September 8, 1989

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc       9/ 8/89        Initial revision.

DESCRIPTION:
	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

	$Id: fsmMain.asm,v 1.1 97/04/04 16:56:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSMCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Terminal strings added to an existing FSM

CALLED BY:	External 

PASS:		si	- extra data to pass routine
		ds	- dgroup
		
RETURN:		C	- set if FSM not created

		C	- clear if FSM created
		bx	- FSM handle 
		ax	- FSM segment

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 9/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FSMCreate	proc	far
	mov	ax, size FSMBlockHeader		;initial size of block
	mov	cx, ALLOC_DYNAMIC_NO_ERR
	call 	MemAlloc			;get memory for the machine
	call	FSMInit				;set up machine specifics
	ret
FSMCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSMParseDesc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Terminal strings to add to an existing FSM

CALLED BY:	External 

PASS:		ds:si	- buffer containing description file
		cx	- length of description (# bytes)
		es	- dgroup
	
		
RETURN:		ax	- 0 on success, error code on failure
		bx	- FSM segment

DESTROYED:	bp, dx

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 9/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FSMParseDesc	proc	far
	push	cx, ds				;save FSM token and buffer size
;	mov	ds, es:[fsmBlockSeg]
	mov	bx, es:[fsmBlockHandle]
	call	MemLock
	mov	ds, ax				;put fsmBlock segment
	mov	bx, es:[fsmBlockHandle]
	mov	ax, LMEM_TYPE_GENERAL		;set lmem heap type
	mov	dx, size FSMBlockHeader		;set size of appl info

	mov	cx, INIT_FSM_SIZE		;set initial heap size
	push	si, di, bp
	mov	si, INIT_FSM_STATES
	clr	di
	clr	bp
	call	LMemInitHeap
	pop	si, di, bp

	mov	es:[fsmBlockSeg], ds
	clr	al				;no flags
	mov	cx, ACTION_BLOCK_SIZE		;get memory for action block
	call	LMemAlloc			;	
	mov	es:[fsmBlockSeg], ds		;segment may have changed
	clr	di 				;store handle to action block
	mov	ds:[di].FSM_actionHandle, ax	;  at correct offset into FSM
	mov	bp, ax
	mov	bp, ds:[bp]			;set default function values
	mov	ds:[bp].FD_internalFunc, NO_FUNC
	mov	ds:[bp].FD_externalFunc, NO_FUNC
	clr	es:[curACoffset]		;action block empty
	
	mov	es:[maxACsize], ACTION_BLOCK_SIZE - (ACTION_DESC_SIZE * 2)
	mov	cx, INIT_LOCAL_STATE_SIZE	;get memory for ground state
	call	LMemAlloc
	mov	es:[fsmBlockSeg], ds		;segment may have changed
	mov	ds:[di].FSM_groundHandle, ax	;store the handle in FSM block
	mov	ds:[di].FSM_curHandle, ax	;current state is ground state
	mov	bp, ax				;copy ground state handle
	mov	bp, ds:[bp]			;dereference handle and store
	InitStateHeader	ds, bp
	;
	; Alloc saved state chunk
	;
	mov	cx, INIT_SAVED_STATE_SIZE
	clr	al				; no object flags
	call	LMemAlloc			; carry set if error
						; ax <- handle of chunk
						; ds <- sptr of same block
EC <	ERROR_C	TERM_ERROR			; can't alloc chunk	>
	mov	es:[fsmBlockSeg], ds
	mov	ds:[di].FSM_savedStateHandle, ax
	mov	bp, ax				; bp <- handle of saved state
						; chunk  
	mov	bp, ds:[bp]			; deref chunk
	ResetSavedStateHeader	ds, bp
	;
	; Reset the flags for FSM
	;
	clr	ds:[0].FSM_status		; no flag for init FSM
	mov	bx, es:[fsmBlockSeg]
	pop	cx, ds				;restore file size and junk
	call	FSMAugmentDesc
	mov	bx, es:[fsmBlockHandle]		;unlock fsmblock
	call	MemUnlock
	call	FSMParseStrInit			;init FSMParseString vars

	ret
FSMParseDesc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSMAugmentDesc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Terminal strings added to an existing FSM

CALLED BY:	External: TermSetVt100 
		Internal: FSMParseString 

PASS:		ds:si	- buffer for additional strings to be parsed
		es	- dgroup
		cx	- length of buffer (# bytes)
		bx	- FSM machine token	
RETURN:		---

DESTROYED:	---

PSEUDO CODE/STRATEGY:
	while buffer not empty (
	
		curToken = GetNextToken(buffer)		;8 bit value
		if (curToken not last token in sequence){ 
			SearchTable(curTable, curToken)	
			if match  
				SetNextState()
			else	
				CreateNextState()
		}
		else {
			SetUpActionDesc()
	}				

KNOWN BUGS/SIDE EFFECTS/IDEAS:
			

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 9/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FSMAugmentDesc	proc	far
	mov	es:[fileHead], si	;set ptr to start of buffer to parse
	add	cx, si			
	mov	es:[fileEnd], cx	;set ptr to end of buffer
	call	StripHeader		;strip RCS header 
	call 	ProcessFlags		;process boolean flags
	mov	es:[fileHead], si	;reset head ptr	
FAD_getToken:
	mov	es:[addToken], TRUE	;reset token flag
	mov	es:[reuseAD], FALSE	;don't reuse action desc
	call	GetToken		;get token
	jc	FAD_ret			;if done with buffer exit
	jz	FAD_addFunc		;if at end of string,set up action word
	cmp	es:[addToken], FALSE	;should token be skipped?
	je	FAD_getToken		;yes, no
	call	SearchCurTable		;search if token already in table
	jnc	FAD_notFound		;if not found, add to table
	call	DoTokenAction		;else go to next state	
	jmp	FAD_getToken		; 	and get next token
FAD_notFound:
	call	SetNextState		;add token to table
	jmp	FAD_getToken		; 	and get next token
FAD_addFunc:
	call	SetExternalFunc
	jmp	FAD_getToken
FAD_ret:
	ret
FSMAugmentDesc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSMParseString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use the passed machine to parse the characters in the passed	
		buffer, executing whatever action they dictate.

CALLED BY:	Serial Thread
		
PASS:		ds:si	- address of buffer containing input characters
		cx	- length of buffer (# bytes)
		es	- dgroup

		(characters are in BBS code page)

RETURN:		cx	- number of unprocessed chars in buffer (THIS WILL
			ALWAYS BE 0, AS THE FSM IS SYNCHRONOUS)

DESTROYED:	---

PSEUDO CODE/STRATEGY:
	while buffer not empty (
		curToken = GetNextToken(buffer)		;8 bit value
		SearchTable(curTable, curToken)	
		if match  {
			if (action word == STATE)
				SetNextState()
			else	
				UpdateScreenBuf		;copy screen chars
				UpdateScreen 
				FSMCallAction();
		}
		else
			current state = ground state
			stick charcter(s) not recognized  in callBackBuffer
	}				


	The FSM is given a buffer full of chars, we want to strip from
	this buffer all valid terminal sequences and just pass the
	unrecognized stuff to the screen object.  The majority of chars
	will be unrecognized so want to make the stripping of the buffer
	as fast as possible.  We're going to copy all chars into the
	buffer and we execute a function we back up that many chara
	into our buffer to "erase" that sequence.


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 9/29/89	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FSMParseString	proc	far
	jcxz	done


if DBCS_PCGEOS	;-------------------------------------------------------------

if EXTRA_EC	;=============================================================
	call	ECMemVerifyHeap						>
	push	ax, cx, si, di
	tst	ds:[crapPtr]
	jnz	haveStart
wrapAround:
	mov	ax, offset crapBuf
	mov	ds:[crapPtr], ax
haveStart:
	mov	di, ds:[crapPtr]
	mov	ax, di
	add	ax, cx
	cmp	ax, ((offset crapBuf) + AUX_BUF_SIZE)
	jae	wrapAround
	rep	movsb				; append to crapBuf
	mov	ds:[crapPtr], di
	pop	ax, cx, si, di
endif	;=====================================================================

charsSaved	local	word
saveOffset	local	word
	.enter

if	not _TELNET
EC <	call	ECCheckRunBySerialThread				>
endif
EC <	call	ECCheckDS_ES_dgroup					>
	mov	charsSaved, 0
	;
	; prepend any saved chars
	;
	mov	ax, cx			; ax = # incoming bytes
	mov	cx, ds:[numFSMUnconvertedBytes]
	jcxz	noneSaved		; no previously unconverted bytes
	push	si
	mov	si, offset fsmUnconvertedBytesBuf ; es:si = unconverted bytes
	mov	di, offset convertBuf2
	rep	movsb			; copy saved bytes
	pop	si			; ds:si = incoming bytes
	mov	cx, ax			; cx = # incoming bytes
	rep	movsb			; tack on new incoming bytes
	mov	si, offset convertBuf2		; ds:si = joined bytes
	add	ax, ds:[numFSMUnconvertedBytes]	; ax = total # bytes
EC <	cmp	cx, AUX_BUF_SIZE					>
EC <	WARNING_A	BUFFER_OVERFLOW					>
noneSaved:
	mov	cx, ax			; cx = # incoming bytes
	;
	; convert from BBS code page to GEOS char set
	;	ds:si = BBS code page chars
	;	cx = # BBS code page chars
	;	ds = es = dgroup
	;
	mov	saveOffset, si			; initialize offset of chars
	add	saveOffset, cx			;	to save
	mov	ds:[numFSMUnconvertedBytes], 0
convertTop:
	push	cx			; save # BBS code page chars
	mov	bx, ds:[bbsRecvCP]	; bx = BBS code page
	mov	ax, MAPPING_DEFAULT_CHAR
	mov	di, offset convertBuf		; es:di = conversion buffer
	clr	dx
	call	LocalDosToGeos		; cx = # GEOS chars
	pop	dx			; dx = # BBS code page chars
	jnc	convertOK
	cmp	al, DTGSS_CHARACTER_INCOMPLETE
	je	convertInc
	;
	; other conversion error, throw away any unconverted bytes and
	; start afresh with next bunch of input, hopefully we'll sync up
	; again
	;
PrintMessage <FSMParseString: improve this if converted count is returned?>
EC <	WARNING	FSM_CONVERSION_ERROR					>
	mov	ds:[numFSMUnconvertedBytes], 0
PrintMessage <FSMParseString: report conversion error?>
doneJMP:
	jmp	FPS_exit

convertInc:
PrintMessage <FSMParseString: improve this if converted count is returned?>
	;
	; handle character incomplete - try again with one less character
	; in input buffer
	;	ds:si = BBS code page chars
	;	dx = # BBS code page chars
	;
	inc	charsSaved		; one more char to save
	dec	saveOffset		; back up save char pointer
	mov	cx, dx			; cx = # BBS code page chars
	dec	cx
	jcxz	doneJMP
	jmp	convertTop

convertOK:
if EXTRA_EC	;=============================================================
EC <	call	ECCheckDS_ES_dgroup					>
	push	ax, cx, si, di
	mov	si, di			; ds:si = converted text
	tst	ds:[crapPtr]
	jnz	haveStart
wrapAround:
	mov	ax, offset crapBuf
	mov	ds:[crapPtr], ax
haveStart:
	mov	di, ds:[crapPtr]
	mov	ax, di
	add	ax, cx
	add	ax, cx
	cmp	ax, ((offset crapBuf) + AUX_BUF_SIZE)
	jae	wrapAround
	rep	movsw				; append to crapBuf
	mov	ds:[crapPtr], di
	pop	ax, cx, si, di
endif	;=====================================================================
	;
	; pass stuff to FSM
	;	convertBuf = GEOS chars buffer
	;	cx = # GEOS chars
	;	ds = es = dgroup
	;	bx = updated BBS code page
	;
EC <	call	ECCheckDS_ES_dgroup					>
EC <	cmp	cx, AUX_BUF_SIZE	; size of convertBuf		>
EC <	ERROR_A	BUFFER_OVERFLOW						>
	mov	ds:[bbsRecvCP], bx	; update for JIS
	mov	si, di			; ds:si = converted chars (pass to FSM)

if EXTRA_EC
	call	ECMemVerifyHeap						>
endif
else	; NOT DBCS ----------------------------------------------------------

if	not _TELNET
EC <	call	ECCheckRunBySerialThread				>
endif
EC <	call	ECCheckDS_ES_dgroup					>

	;
	; convert from BBS code page to GEOS code page
	;
	;
	; (frequently only get one character at a time and it doesn't need
	;  conversion, so do a little check here to save some work)
	;
if INPUT_OUTPUT_MAPPING
	call	InputMapBuffer
endif
	cmp	cx, 1			; only one character?
	jne	notOne			; nope, no optimization
	cmp	{byte} ds:[si], MIN_MAP_CHAR	; needs mapping?
	jb	afterMapping		; nope, skip localization nonsense
notOne:
	mov	bx, ds:[bbsCP]			; bx = source code page
	mov	ax, MAPPING_DEFAULT_CHAR
	call	LocalCodePageToGeos
afterMapping:

endif	; SBCS ---------------------------------------------------------------

	mov	es:[fileHead], si	;set ptr to start of buffer to parse
DBCS <	shl	cx, 1			;# chars -> # bytes		>
	add	cx, si			;	
	mov	es:[fileEnd], cx	;set ptr to end of buffer
	mov	es:[unParseStart], si	;store beginning of unparsed sequence
	mov	es:[unParseBufHead], si	;ptr to where to insert into buffer
	mov	ax, 0	
	mov	es:[unParseNum], ax	;clear number of unknown chars
	mov	es:[unParseBufNum], ax	;reset total num of chars in buf
	mov	es:[numParseChars], ax	;reset length of parse chars
	mov	bx, es:[fsmBlockHandle]	;bx holds FSM token 
	call	MemLock
	mov	bx, ax			;
	mov	es:[fsmLocked], TRUE	;

DBCS <	push	bp			; save locals pointer		>
DBCS<	cmp	si, es:[fileEnd]					>
DBCS <	je	FPS_ret			; nothing to do			>
FPS_loop:				;
SBCS <	mov	al, ds:[si]		;get TOKEN			>
DBCS <	mov	ax, ds:[si]		;get TOKEN			>
	push	ds			;save file segment
DBCS <	tst	ah							>
DBCS <	jnz	FPS_notFound		;store as unparsed		>
;I thought this might be needed, but no -- brianc 2/24/94
;	tst	al			;handle nulls
;	LONG jz	FPS_null
	call	CheckFSMState		;see if we should resest some fsm flags
	call	SearchCurTable		;is token in table
	jnc	FPS_notFound		;  no, reset to ground state 
	cmp	es:[inParse], FALSE	;  yes, is this start of parse sequence
	jne	FPS_inParse		;  nope	
	mov	es:[inParse], TRUE	;  yep
	clr	es:[numParseChars]	;  initialize count of parsed chars

FPS_inParse:
	inc	es:[numParseChars]	
	call	DoTokenAction		;  yes, goto next state or call func
	jc	FPS_next		;    if called state goto next state
	mov	ax, es:[numParseChars]	;    else called func, advance ptr 
DBCS <	shl	ax, 1			; char offet -> byte offset	>
	add	es:[unParseStart], ax	;   	past term sequence
	jmp	FPS_resetParse		;

;I thought this might be needed, but no -- brianc 2/24/94
;FPS_null:
;	tst	es:[unParseNum]		;any pending unparsed chars?
;	jz	40$
;	push	si
;	call	StoreUnParsedChars
;	call	UpdateScreen
;	pop	si
;40$:
;	inc	es:[unParseStart]	; skip null
;DBCS <	inc	es:[unParseStart]					>
;	jmp	FPS_next

FPS_notFound:				
	inc	es:[unParseNum]		;increment count of chars to copy
	cmp	es:[inParse], TRUE	;were we in a parse sequence?
	jne	FPS_reset		;nope, 
	mov	ax, es:[numParseChars]	;add the failed term sequence
	add	es:[unParseNum], ax	;   to the unparsed buffer

FPS_resetParse:
	mov	es:[inParse], FALSE	;no longer in parse sequence
	clr	es:[numParseChars]	;   reset # of accepted parse chars

FPS_reset:				;reset FSM	
	mov	ds, bx			;ds -> FSM segment
	clr	bp			;
	mov	ax, ds:[bp].FSM_groundHandle	;set current to ground state
	mov	ds:[bp].FSM_curHandle, ax
	clr	es:[argNum]		;reset argument count

FPS_next:
	pop	ds			;restore file segment
	inc	si			;if not end of file 
DBCS <	inc	si							>
	cmp	si, es:[fileEnd]	;	get next token
	LONG jl	FPS_loop

FPS_ret:
	call	StoreUnParsedChars	;
	tst	es:[unParseBufNum]	;if buf empty exit
	jle	FPS_done
	;
	; If there is international showing, save it.
	;
RSP <	mov	ax, MSG_SCR_SAVE_INTL_CHAR				>
RSP <	call	FSMSendScreenObjNoFixup					>
	call	UpdateScreen		
RSP <	mov	ax, MSG_SCR_RESTORE_INTL_CHAR				>
RSP <	call	FSMSendScreenObjNoFixup					>

FPS_done:
	mov	bx, es:[fsmBlockHandle]	;bx holds FSM token 
	call	MemUnlock
	mov	es:[fsmLocked], FALSE

if DBCS_PCGEOS	;--------------------------------------------------------------
	pop	bp			; restore locals pointer
FPS_exit:
	mov	cx, charsSaved		; any chars to save?
	jcxz	exit			; nope
EC <	cmp	cx, length fsmUnconvertedBytesBuf			>
EC <	ERROR_A	-1							>
	mov	si, saveOffset		; ds:si = chars to save
	mov	di, offset fsmUnconvertedBytesBuf	; es:di = save dest
	mov	ds:[numFSMUnconvertedBytes], cx
	rep	movsb			; copy chars to save
exit:
if EXTRA_EC
	call	ECMemVerifyHeap
endif
endif	;----------------------------------------------------------------------

	clr	cx			;see header for explanation

DBCS <	.leave								>
	
done:	
	ret
FSMParseString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSMDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys FSM

CALLED BY:	TermDetach		

PASS:		cx	- LMem handle to free

	
RETURN:		nothing	
		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/23/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSMDestroy	proc	far
	mov	bx, cx
	call	MemFree
	ret
FSMDestroy	endp

