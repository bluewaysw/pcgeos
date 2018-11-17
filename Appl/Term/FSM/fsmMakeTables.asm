COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		FSM
FILE:		makeTables.asm

AUTHOR:		Dennis Chow, September 18, 1989

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc       9/18/89        Initial revision.

DESCRIPTION:
	Internally callable routines for this module.

	$Id: fsmMakeTables.asm,v 1.1 97/04/04 16:56:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; THE BACKTRACKING MECHANISM FOR PARSING ESCAPE CODES:
;
; <Background>
;	There are functions mapped incorrectly when there are escape
;	codes having absolute digit value and there is also a wildcard
;	digit character in another escape sequence. The wildcard
;	digit characters are forcefully inserted into the character
;	table whereas absolute digit character, like any another
;	character, will not inserted into the table if it is already
;	there. During parsing, the token is searched from top of table
;	for the first match So, the order of escape codes makes a
;	difference. For example,
;
;	\E[%i%d;%i%dH	26
;	\E[4h		37
;
;	In this case, '4' in the second sequence will not be
;	entered. It will use the next state that first sequence
;	generates (the one containing %d and ';'). So, \E5h will be
;	mapped to 37 because '5' can be found in wildcard digit
;	character table. 'h' can also be found in the next state.
;
;	\E[4h		37
;	\E[%i%d;%i%dH	26
;
;	In this order, '4' is entered first and then wildcard
;	character will insert 0-9 characters. So, \E[4;1H will never
;	be reached because \E[4 already leads to another path. ';'
;	will cause a mismismatch.
;
; <SOLUTION>
;	(1) One solution is to produce a deterministic finite state
;	machine. However, it demands much memory. The memory
;	requirement can go exponetial to the number of termcap
;	entries. This should be most elegant solution and fastest in
;	performance. 
;
;	*(2) To improve this non-deterministic finite state
;	machine. there is a backtracking mechanism once a sequence of
;	input escape sequence is not found in the current path. It
;	backtracks to try out the next possible match. Conceptually,
;	it is like tree search.
;
;	Each state has a character table containing characters to
;	match by this state. When we find a match, we check to see if
;	there is any more matches in the rest of the character
;	table. If so, save-state mode is set and we push the current
;	state. By pushing state, it means saving the SavedStateDesc
;	which contains the pointer to second match, current state and
;	token. We then update the pointer to remember this state as
;	the starting point for backtracking. For the subsequent
;	characters, if there is a match, we continue push states. When
;	there is a mismatch in save-state mode, we get the state for
;	backtracking and retry matching characters in another path.
;
;	Given the above termcap entry order, when we parse '4', we
;	push state and remember there is an alternate path. If we have
;	'h' afterwards, we execute the function and delete all saved
;	states. If a ';' is followed, it mismatches and
;	backtracks. So, it reloads the state and try the path of
;	second escape code. It matches and parsing continues from
;	there. 
;
; 	While in save-state mode, if there is more than 1 match in
; 	character table, it recursively performs the search. 
;
; <RESTRICTION>
;	All the escape codes containing wildcard digit characters must
;	be at the end of the termcap file. The idea is to allow those
;	with absolute digit to enter to a state's character table
;	first.
;
; For information about data structures, please refer to
; fsmConstant.def
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchCurTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a special search in the current table during
		parsing input string  

CALLED BY:	FSMParseString
PASS:		bx	- FSM machine token	
		ds:si	- character buffer
		es	- dgroup	
		al	- current token
		ax	- current token (for DBCS only)

RETURN:		C	- clear if token not found
			- set   if token found
		cx	- # number of bytes till end of table
		dx	- # of chars in table
		bx:di	- 1 char past the matched token in char token

DESTROYED:	(ax, bx, ->DoTokenFunction)
SIDE EFFECTS:	
	If it is doing backtracking, dgroup::numParseChars will be reduced by
	1. 

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/18/89        Initial version
	simon	4/22/95    	Added backtracking mechanism

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchCurTable	proc	near
		uses	es, si
		.enter
	;
	; Get the pointer to the start of character buffer
	;
		mov	es, bx		; es -> FSM segment
retryStart:
		clr	di		; es:di-> FSMBlockHeader
		mov	di, es:[di].FSM_curHandle
redoSearch:
		mov	di, es:[di]	; di -> nptr of current state
		mov	si, di		; si -> nptr of current state
	;
	; Get # characters in this state
	;
		mov	cl, es:[di]	; cl -> # char in state
		clr	ch
		mov	dx, cx		; dx -> # char in state
		add	di, CHAR_TABLE_OFFSET
					; di -> start of char table
		cmp	{byte} es:[di], CHAR_WILD
		jne	scan		; any wild card char?
					; (inserted when %c is parsed
					; in termcap)
		inc	di		; force the match
		clr	cx		; indicate end of table
		jmp	returnMatch
scan:
	;
	; Search for a match in character table and push state if necessary.
	;
		call	SearchCharTable	; carry clr if not found
					; if found,
					; cx <- #bytes till EOT
					; esdi <- 1 byte past match
		jnc	noMatch
returnMatch:
		stc			; indcate token found
		jmp	exit
noMatch:
		call	Backtrack	; carry set if need to reprocess
					; current token
		jc	noRetry
	;
	; Check FSM state before retry. Important!!!
	;
		push	es, cx
		GetResourceSegmentNS	dgroup, es
		call	CheckFSMState	; cx <- destroyed		
		pop	es, cx
		jmp	retryStart
noRetry:
		clc			; indicate token not found
exit:
		.leave
		ret
SearchCurTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchCharTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the character table for matching token

CALLED BY:	FSMAugmentDesc
PASS:		al	= token (character to match)
		cx	= # bytes to search
		es:di	= starting point of search in table
RETURN:		cx	= # bytes till the end of table
		es:di	= byte past the match if MATCH
			= byte past the end of table if MISMATCH
		carry clear	= token not found
		carry set 	= token found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Search the table for match;
	if (match) {
		Search the rest of table for next match;
		if (match-again) {
			PushState;
		}
		Return match parameters info;
	} else {
		Return mismatch parameters info;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	4/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchCharTable	proc	near
		bytesLeft	local	word	; store #bytes till end of
						; table 
		pastMatchPtr	local	nptr	; store ptr past match or EOT
		.enter
EC <		Assert_okForRepScasb					>
	;
	; Search through the table for match
	;
		repne	scasb		; ZF clear if not match
		jne	noMatch
		mov	ss:[bytesLeft], cx
		mov	ss:[pastMatchPtr], di
		jcxz 	checkForSavedState
	;
	; Search for the next match
	;
	; Reason: There is limitation in parsing termcap file that all
	; escape codes containing absolute numbers must preceed those
	; with wildcard characters (%c, %d...). They are entered in
	; the character table first and later by the wildcard
	; characters. (See HandleDecParam). Now we try to see if the
	; absolute escape code matches. If so, we proceed with it,
	; otherwise, we want to backtrack and compare from this state
	; again with the next match of the token.	-Simon 4/22/95
	;
	; It reset saved state when:
	; * one match found and it's already past the end of table OR
	; * one match found and there is no more match in the table
	;
		repne	scasb
		jne	noNextMatch
		call	PushState
match:	
		stc			; indicate token found
		mov	cx, ss:[bytesLeft]
					; restore params to return
		mov	di, ss:[pastMatchPtr]
		jmp	exit
noMatch:
		clc			; indicate token not found
exit:
		.leave
		ret
	
noNextMatch:

		
checkForSavedState:
	;
	; We found a match already. But we need to see if we are in
	; save-state mode. If so, we push this state also for backtracking
	;
		BitTest	es:[0].FSM_status, FSMSF_SAVE_STATE
		jz	match		; flag not set, no need to save state
		call	PushState	; need to save state
		jmp	match
SearchCharTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Backtrack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Backtrack to last matching state

CALLED BY:	SearchCurTable
PASS:		es = bx	= FSM token (segment)
		ds	= termcap buffer segment
RETURN:		carry clear	= new state set, needs reprocessing current
				token 
		carry set	= no new state set, no need to reprocess
				current token
DESTROYED:	nothing
SIDE EFFECTS:
	es:[0].FSM_curHandle	= new state if match
	Saved states may be popped off.

PSEUDO CODE/STRATEGY:
	It backtracks to revert to the last state where there is unvisited
	branch for parsing. The whole point of having saved state is to
	provide a way to backtrack if search of external function or a match
	does not occur. 

	nodePtr = Get the saved state header node pointer;
	if (!nodePtr) {			// no saved state, no need to
					// reprocess current token
		return FALSE;
	}
	return BacktrackFindMatch(nodePtr);	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	4/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Backtrack	proc	near
		uses	ax, di
		.enter
EC <		Assert_segment	es					>
EC <		Assert_segment	bx					>
	;
	; Get the pointer to entry saved state
	;
		mov	di, es:[0].FSM_savedStateHandle
		mov	di, es:[di]		; di <- savedState block
		tst	es:[di].SSH_numEntries	; any saved state?
		jz	noMatch
	;
	; Do the searching and set to the right state
	;
		mov	al, es:[di].SSH_retryEntry
		call	BacktrackFindMatch	; carry set if found matched
						; state  
		jmp	exit			; propagate results back
noMatch:
		stc				; indiate no saved state
exit:
		.leave
		ret
Backtrack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BacktrackFindMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Backtrack to last matching state

CALLED BY:	Backtrack, BacktrackNextSavedState
PASS:		es:di	= SavedStateHeader
		al	= entry # to start seearching
RETURN:		carry clear	= new state set, needs reprocessing current
				token 
		carry set	= no new state set, no need to reprocess
				current token
DESTROYED:	nothing
SIDE EFFECTS:
	es:[0].FSM_curHandle	= new state if match
	Saved states may be popped off.

PSEUDO CODE/STRATEGY:
	It backtracks to revert to the last state where there is unvisited
	branch for parsing. The whole point of having saved state is to
	provide a way to backtrack if search of external function or a match
	does not occur. 

	currentNode = Pointer-to-node;
	Match = TRUE;

	// Assume the node has reached the end of table
	Set current state to node's state pointed by Pointer-to-node;
	Get bytes till end of table;
	//
	// In the second pass to topLoop, the node should be all unparsed
	//
 topLoop:
	Get token to process;
	Get Params ready for DoTokenAction;
	call DoTokenAction;
	// current state already set
	Search through the rest of table for current token;
	Update the bytes till end of table in SavedStateDesc;
	if (end-of-table) {
		Find link to previous Pointer-to-node and update
		saved state header;
		if (can't find previous) {
			ResetSavedState
		}
		return TRUE;
	} else {
		Update pointer to next saved state desc;
		currentNode = this new node;
		Find a match in unparsed node;
		if (match) {
			Update remaining chars to character buffer;
			Update the state of saved state desc;
			Find the second match;
			if (second-match) {
				if (!BacktrackFindMatch(currentNode)) {
					Match = FALSE;
				}
			}
		} else {
			ResetSavedState
			return FALSE;
		}
		GOTO topLoop
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	4/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BacktrackFindMatch	proc	near
		savedStateHdrPtr local	word	push	di
						; nptr to savedStateHdrPtr
		termcapBufPtr	local	word	push	si
		savedStatePtr	local	nptr	; nptr to current saved state
		entry		local	word 	; current entry # in saved
						; state table
		firstEntry	local	word	; nptr to first saved state
						; entry to process 
		uses	ds, ax, bx, cx, dx, si, di
		.enter
	
	;
	; Get the state backtrack init params
	;
		mov	si, di			; si <- saved state hdr
		segmov	ds, es, bx		; ds <- FSM token
		clr	ah
		add	di, offset SSH_states	; di <- begin of saved states
						; array
		mov	ss:[entry], ax		; save entry#
		mov	ss:[firstEntry], ax
		CheckHack	<size SavedStateDesc eq 4>
						; entry# to begin backtracking
		shl	ax
		shl	ax			; offset within saved state
						; table 
		add	di, ax			; di <- saved state entry to
						; get 
		segmov	es:[0].FSM_curHandle, es:[di].SSD_state, ax
	;
	; Get character and bytes till end of table
	;
		mov	ss:[savedStatePtr], di
	
loopStateTop:
EC <		call	ECCheckSavedStateHeader				>
		mov	di, ss:[savedStatePtr]
		mov 	al, es:[di].SSD_char	; current token
		mov	cl, es:[di].SSD_searchChar
						; cl <- bytes till end of table
		call	BacktrackGetCharOffset	; cx destroyed
						; di<-nptr to byte after match 
						; dx<-# bytes in table
	;
	; Process character!!
	;
		push	di, cx, es, bp, ax
		GetResourceSegmentNS	dgroup, es
		push	cx
		call	CheckFSMState		; cx destroyed
		pop	cx
		call	DoTokenAction		; carry set if next state
						; carry clr if called func
		pop	di, cx, es, bp, ax
	;
	; Search for the second match of character and update bytes till end
	; of table in SavedStateDesc.
	;
		repne	scasb
		mov	di, ss:[savedStatePtr]
		mov	es:[di].SSD_searchChar, cl
	;
	; Check if any more saved state to process
	;
		call	BacktrackIsEOT		; carry clear if EOT
						; ax<-# saved states
		jnc	endOfTable
	;
	; More saved state to process
	;
		call	BacktrackNextSavedState	; carry set if no next state
						; to process
		jc	exit
		jmp	loopStateTop
endOfTable:
	;
	; No more states to process
	;
		call	BacktrackHandleEOT	; ax, di destroyed
		clc				; indicate match
exit:
		.leave
		ret
BacktrackFindMatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BacktrackGetCharOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the offset in the character table

CALLED BY:	BacktrackFindMatch
PASS:		es	= FSM token
		cl	= bytes till end of table

RETURN:		di	= if match, nptr to byte after match
		dx	= # characters in table
		cx	= bytes till end of table
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get the offset in character table from current state

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BacktrackGetCharOffset	proc	near
		.enter
		mov	di, es:[0].FSM_curHandle; di <- new state
		clr	ch
		mov	di, es:[di]		; di <- nptr to new state
		mov	dl, es:[di].SH_numEntries
		clr	dh			; dx <- # entries in table
		add	di, CHAR_TABLE_OFFSET	; di <- nptr to begin of char
						; table 
	;
	; Calc offset to character table entry from this parsed node
	;
		add	di, dx			; di <- past end of table
		sub	di, cx			; di <- 1 byte past target
						; match 
		.leave
		ret
BacktrackGetCharOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BacktrackNextSavedState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare the next saved state to process

CALLED BY:	BacktrackFindMatch
PASS:		ss:bp	= inherited stack
		ds:si	= fptr to SavedStateHeader
		es:di	= fptr to current SavedStateDesc
RETURN:		carry set	= no next state to process
			SavedStateHeader is reset.
DESTROYED:	nothing
SIDE EFFECTS:	
	ss:[entry] is incremented.
	ss:[savedStatePtr] updated to next SavedStateDesc
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BacktrackNextSavedState	proc	near
		uses	ax, bx, cx, dx, si, di
		.enter	inherit BacktrackFindMatch
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
	;
	; Update pointer to next state
	;
		add	di, size SavedStateDesc
		inc	ss:[entry]		; update current entry #
		mov	ss:[savedStatePtr], di	; save current entry nptr
	;
	; Find out if the character is in current state
	;
		push	di
		mov	al, es:[di].SSD_char	; al <- char to process
		mov	di, es:[0].FSM_curHandle; di <- lptr of next state
		mov	di, es:[di]		; di <-nptr to next state
		mov	cl, es:[di]		
		clr	ch			; cx <- # char
		add	di, CHAR_TABLE_OFFSET	; di <- start of char table
		cmp	{byte}es:[di], CHAR_WILD; any wild car char?
		je	foundWildChar		; inserted when %c termcap
						; entry. Carry clear
	;
	; Do the searching for first match
	;
		repne	scasb			; Find the first match
		mov	dx, di			; dx <- begin of next search
		pop	di			; di <- nptr to current saved
						; state entry
		mov	es:[di].SSD_searchChar, cl 
		jne	noMatch
	;
	; Check for second match
	;
		mov	di, dx			; restore begin of next search
		repne	scasb			; Find the second match
		jne	noSecondMatch
	;
	; Recursively call for match
	;
EC <		WARNING TERM_MORE_THAN_TWO_MATCHES_IN_BACKTRACK_STATE 	>
		mov	di, si			; di<-nptr to SavedStateHeader
		mov	ax, ss:[entry]
		call	BacktrackFindMatch	; carry set if no next state
						; to process
		jc	noMatch
		
noSecondMatch:
		clc				; indicate there's next state
		jmp	exit
	
noMatch:
	;
	; No next state to process
	;
		ResetSavedStateHeader	ds, si
		stc				; indicate there's no next
						; state 
exit:
		.leave
		ret
foundWildChar:
		pop	di			; restore stack
		jmp	exit			; carry should be clear
BacktrackNextSavedState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BacktrackIsEOT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if this is the end of saved state table

CALLED BY:	BacktrackFindMatch
PASS:		ss:bp	= inherited stack
		ds:si	= SavedStateHeader
RETURN:		ax	= # of saved state
		carry clear	= reached end of saved state table
DESTROYED:	nothing
SIDE EFFECTS:	
	ss:[entry] will be incremented.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BacktrackIsEOT	proc	near
		uses bx
		.enter	inherit BacktrackFindMatch
EC <		Assert_fptr	dssi					>
	;
	; entry # is zero based. We increment entry# to see if it equals
	; table size.
	;
		mov	bx, ss:[entry]
		inc	bx		; next entry#
		mov	al, ds:[si].SSH_numEntries
		clr	ah
		cmp	bx, ax		; anymore entry? (EOT?)
	;
	; Carry CLEAR if reached end of saved state table
	;
		.leave
		ret
BacktrackIsEOT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BacktrackHandleEOT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for previous entry in saved state which has
		untraversed paths for its character

CALLED BY:	BacktrackFindMatch
PASS:		ds:si	= fptr to SavedStateHeader
		es:di	= fptr to entry beginning search (it searches down
			the stack, i.e., back previous characters)
		ss:bp	= inherited statck
RETURN:		nothing
DESTROYED:	ax, di
SIDE EFFECTS:	
	SavedStateHeader is reset when there is no more state to retry.

PSEUDO CODE/STRATEGY:
		Find link to previous Pointer-to-node and update
		saved state header;
		if (can't find previous) {
			ResetSavedState
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	4/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BacktrackHandleEOT	proc	near
		.enter	inherit BacktrackFindMatch
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
	
		mov	ax, ss:[firstEntry]	; get starting entry#
searchLoop:
	;
	; Check if it has more untraversed path on its char
	;
		tst	es:[di].SSD_searchChar	; any bytes till EOT?
		jz	checkPrevious		; yes, move forward
	;
	; If this state still has more character to parse, set it to next
	; retry. 
	;
		mov	ds:[si].SSH_retryEntry, al
		segmov ds:[si].SSD_state, es:[0].FSM_curHandle, ax
		jmp	exit
checkPrevious:
	;
	; Check to see if the entry is already the top
	;
		tst	ax			; top entry? (entry 0 is top)
		jz	reset			; no need to do anything
	;
	; Update pointer to previous state
	;
		sub	di, size SavedStateDesc
		dec	ax			; update entry #
		jmp	searchLoop
reset:
	;
	; Reset SavedStateHeader since there's no more state to retry
	;
		ResetSavedStateHeader	ds, si
exit:
		.leave
		ret
BacktrackHandleEOT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PushState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the state info for backtracking of a token

CALLED BY:	SearchCharTable
PASS:		es	= segment of FSM token
		cl	= # chars left in table unmatched
		al	= current token (character to parse)
	
RETURN:		carry set if saved state table is full
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get the stack chunk;
	if (state stack is full) {
		Return error;
	} else {
		Push the state;
		Increment the saved state count;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	4/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PushState	proc	near
		uses	bx, bp
		.enter
	;
	; Get the stack chunk
	;
		mov	bp, es:[0].FSM_savedStateHandle
		mov	bp, es:[bp]		; es:bp <- beginning of chunk
	;
	; Test if we have reached max saved state
	;
		mov	bl, es:[bp].SSH_numEntries
		cmp	bl, es:[bp].SSH_maxEntries
						; saved state table full?
		jge	error
	;
	; Get pointer to new entry
	;
		push	bp			; save character
		add	bp, offset SSH_states
CheckHack	<size SavedStateDesc eq 4>
		clr	bh
		shl	bx
		shl	bx			; offset within saved state
						; table 
		add	bp, bx			; bp <- nptr to new entry
	;
	; Assign saved state info
	;
		segmov	es:[bp].SSD_state, es:[0].FSM_curHandle, bx
		mov	es:[bp].SSD_char, al
		mov	es:[bp].SSD_searchChar, cl		
	;
	; Increment the entry count
	;
		pop	bp			; bp <- beginning of saved
						; state block  
		jcxz	succeed
	;
	; Set this state to be the one to backtrack first and retry. That
	; means if the match doesn't succeed, it'll backtrack up to this
	; state and retry with the rest of the matches.
	;
		segmov	es:[bp].SSH_retryEntry, es:[bp].SSH_numEntries, bl
						; # is zero bassed
succeed:
		inc	es:[bp].SSH_numEntries  ; update counter
	;
	; In save state mode, so push state there after
	;
		BitSet	es:[0].FSM_status, FSMSF_SAVE_STATE
		clc				; indicate success
exit:
		.leave
		ret
error:
EC <		WARNING TERM_SAVED_STATE_TABLE_FULL			>
		stc
		jmp	exit
PushState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetSavedState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the saved state

CALLED BY:	DoTokenFunction
PASS:		ds	= FSM token
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	4/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetSavedState	proc	near
		uses	di
		.enter
	;
	; Get pointer to saved state header
	;
		mov	di, ds:[0].FSM_savedStateHandle
		mov	di, ds:[di]		; di <- begin of saved state
						; blk 
		ResetSavedStateHeader	ds, di
		
		.leave
		ret
ResetSavedState	endp

if	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSavedStateHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the saved state header

CALLED BY:	GLOBAL
PASS:		es	= FSM token (FSM segment)
RETURN:		nothing
DESTROYED:	nothing (flags destroyed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckSavedStateHeader	proc	near
		uses	ax, di
		.enter
	;
	; Get the pointer to saved state header first
	;
		mov	di, es:[0].FSM_savedStateHandle
		mov	di, es:[di]		; di<-nptr to SavedStateHeader
	;
	; Check the max entries number
	;
		cmp	es:[di].SSH_maxEntries, INIT_NUM_SAVED_STATES
						; max# entries messed up?
		ERROR_NE TERM_INVALID_SAVED_STATE_HEADER
	;
	; Verify this:
	;	SSH_maxEntries >= SSH_numEntries > SSH_retryEntry
	;
		mov	al, es:[di].SSH_maxEntries
		cmp	al, es:[di].SSH_numEntries
		jge	checkRetryEntry
		ERROR	TERM_INVALID_SAVED_STATE_HEADER
	
checkRetryEntry:
		mov	al, es:[di].SSH_numEntries
		cmp	al, es:[di].SSH_retryEntry
		jg	headerOK
		ERROR	TERM_INVALID_SAVED_STATE_HEADER
headerOK:
		.leave
		ret
ECCheckSavedStateHeader	endp

endif	; if ERROR_CHECK
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddTokenToTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a token to the state's character table

CALLED BY:	SetExternalFunc, SetNextState, SetInternalFunc

PASS:		al	- current token
		es	- dgroup
		bx	- FSM machine token
		ds	- character buffer	

RETURN:		---

DESTROYED:	bp, di

PSEUDO CODE/STRATEGY:
		get the current state	
		check size
		if not enough room
			make room (realloc) the state
		add token
			shift functions down 
			add token to character table	
			update the size

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
AddTokenToTable	proc	near	
	push	ds, si, cx			;don't trash buffer pointer	
	mov	ds, bx				;get FSM segment
	clr	bp				;
	mov	si, ds:[bp].FSM_curHandle	;get current handle
	mov	si, ds:[si]			;dereference the handle
	mov	di, si				;copy pointer to start of chunk
	mov	cl, ds:[di]			;get the cur size of the table
	tst	cl				;is the table empty?
	jz	ATT_add				;yes, add token
	inc	di
	mov	ch, ds:[di]			;get the max size of the table
	cmp	cl, ch				;is there room for token
	jl	ATT_ok				;yes	
						;no, make room, Realloc chunk
	push	ax				;save the token
	mov	al, ch				;current size = 
	mov	ch, TABLE_ENTRY_SIZE		;max entry * entry size
	mul	ch
	mov	cx, ax 	
	add	cx, EXPAND_STATE_SIZE		;add this many more bytes
	mov	ax, ds:[bp].FSM_curHandle	;get handle of current state
	call	LMemReAlloc			;  and resize the chunk	
	mov	es:[fsmBlockSeg], ds		;LMem heap may have moved
	mov	bx, ds				;  store new fsm segment 	
	mov	si, ds:[bp].FSM_curHandle	;dereference the handle
	mov	si, ds:[si]			;	again
	mov	di, si				;copy pointer to local chunk
	inc	di
	add	{byte} ds:[di], ADD_TABLE_ENTRIES	;update max # of entries
	pop	ax				;restore the token
ATT_ok:
	push	es, si
	segmov	es, ds, cx			;make ds point to es
	
	clr	ch
	mov	cl, ds:[si]			;get number of entries to move
	add	si, CHAR_TABLE_OFFSET		;offset to start of table
	add	si, cx				;offset to end of char table		
	shl	cl, 1				;offset into function table
	add	si, cx				;es:si -> end of function table
	mov	di, si				;es:di -> end of function table
	dec	si				;es:si -> last byte in table
	std					;set direction flag
	rep	movsb
	cld					;clear direction flag
	pop	es, si
ATT_add:					;add the token to the table
	mov	di, si				;
	add	di, CHAR_TABLE_OFFSET		;get to start of table entries
	clr	ch
	mov	cl, ds:[si]
	add	di, cx				;offset to end of table
	mov	{byte} ds:[di], al		; and stick it in 
	inc	{byte} ds:[si]		;increment num entries
ATT_ret:
	pop	ds, si, cx			;restore this segs and regs
	ret
AddTokenToTable	endp
 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreActionWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the action word into the current table

CALLED BY:	SetExternalFunc, SetInternalFunc, HandleDecParam

PASS:		bx	- FSM machine token	
		es	- dgroup	
		dx	- action word to store	

RETURN:		---

DESTROYED:	di, bp

PSEUDO CODE/STRATEGY:
		get the current state and
		offset to last entry in action table
		store the action word  (ptr to an action descriptor)
		if the least significant bit is 0	- handle to next state
			           	        1	- ptr to descriptor	
KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
StoreActionWord	proc	near	
	push	ds, cx				;don't trash buffer pointer	
	mov	ds, bx				;get FSM segment
	clr	bp				;
	clr	ch
	mov	di, ds:[bp].FSM_curHandle	;get current handle
	mov	di, ds:[di]			;dereference the handle
	mov	cl, ds:[di]			;get the cur size of the table
	add	di, CHAR_TABLE_OFFSET		;beginning of char table
	add	di, cx				;offset to last entry in char
	;
	; char table size is always 1 more than that in func table. So we
	; need to subtract 1 to get to the last entry of func table where we
	; store the function.
	;
	dec	cl
	shl	cl, 1				;get offset into func table,						;each func table entry is 2						;byte wide
	add	di, cx				;point to last entry in func
						;table 
	mov	ds:[di], dx			;store the action word
	pop	ds, cx
	ret
StoreActionWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNextState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Token not in table, so add the token and set up next state	

CALLED BY:	FSMAugmentDesc

PASS:		bx	- FSM machine token	
		al	- current token		
		ds:si	- termcap buffer
		es	- dgroup	

RETURN:		---

DESTROYED:	cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		add token to table
		create a new state 
		set action word of token to point to new state
		set curState to state just created
		 

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNextState	proc	near
	push	ds
	call	AddTokenToTable
	call	MakeNewState
	mov	dx, ax				; 
	call	StoreActionWord			;store handle to next state
	clr	bp
	mov     ds:[bp].FSM_curHandle, ax       ;current state is next state
	pop	ds
	ret
SetNextState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeNewState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make an empty state

CALLED BY:	CreateNextState, HandleDecParam

PASS:		bx	- FSM machine token	
		es	- dgroup	
			

RETURN:		ax	- LMem chunk handle
		bx 	- FSM machine token	
		ds	- fsm segment

DESTROYED:	cx, bp

PSEUDO CODE/STRATEGY:
		Allocate an LMem chunk and 
		initialize the num entry and max entries field

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/22/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
MakeNewState	proc	near	
	mov	ds, bx				;ds -> FSM segment
	mov	cx, INIT_LOCAL_STATE_SIZE       ;set size of new chunk
	clr	al				;no heap flags
	call    LMemAlloc 			;get memory for new state
	mov	es:[fsmBlockSeg], ds		;fsm segment may have changed
	mov	bx, ds				;  (so update variables)	
	mov	bp, ax				;copy the state handle
	mov     bp, ds:[bp]                     ;dereference handle and store
	InitStateHeader	ds, bp
	;
	; Make sure the character table for the state doesn't begin with
	; CHAR_WILD, as SearchCurTable looks at that before looking to
	; see if the current number of entries is 0. The problem is when
	; building up the state machine, if the first char happens to be
	; CHAR_WILD when the state is actually empty, FSMAugmentDesc thinks
	; the entry exists and executes the function, running off into
	; nowhere (especially if the application thread has placed termStatus
	; ON_LINE)...
	;
	mov	{char}ds:[bp+CHAR_TABLE_OFFSET], 0; make sure this
						;  doesn't hold CHAR_WILD, as
						;  that can really screw us up
						;  when building things up
	ret
MakeNewState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoTokenAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the token's action word, either go to next state or call function

CALLED BY:	FSMAugmentDesc, FSMParseString

PASS:		al	- current token	
		bx	- FSM machine token	
		cx	- number of bytes till end of table
		dx	- number of entries in table
		ds	- termcap buffer segment
		es	- dgroup
		bx:di	- one past the matched character entry 

RETURN:		C	- set   if set next state
		 	- clear if called function

DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
	token may be next state (low bit 0) or 
	offset into actionChunk (low bit 1)
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoTokenAction	proc	near
	push	es
	call	GetActionWord
	test	cx, AD_FLAG		;is it the next state or a desc?
	jz	DTA_nextState		;it's an LMemHandle (state)
	and	cx, CLEAR_AD_FLAG	;its an action descriptor
	pop	es
	cmp	es:[termStatus], OFF_LINE	; if off line skip calling
	je	10$				; screen object
	call	DoTokenFunction		;process it
10$:
	jmp	short DTA_ret
DTA_nextState:
	clr	di			;current state is token's next state
	mov     es:[di].FSM_curHandle, cx       
	stc				;signal gone to next state
	pop	es
DTA_ret:
	ret
DoTokenAction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetActionWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get action word of a state table entry

CALLED BY:	DoTokenAction, HandleDecParam

PASS:		al	- current token	
		bx	- FSM machine token/segment
		cx	- number of bytes till end of table
		dx	- number of entries in table
		ds	- termcap buffer segment
		bx:di	- one past the matched character entry 


RETURN:		cx	- action word for that entry
		es	- fsm segment

DESTROYED:	di, dx	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/03/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
GetActionWord	proc	near	
	mov	es, bx
	add	di, cx			;go to start of action table
	sub	dl, cl			;get table entry of token
	dec	dl			;	(entry 1 is offset 0)	
	shl	dl, 1			;calculate offset in action table
					;  (dh already nuked out)
	add	di, dx			;point to the action word
	mov	cx, es:[di]		;  and fetch it
	ret
GetActionWord	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoTokenFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	process action descriptor

CALLED BY:	DoTokenAction

PASS:		al	- current token	
		bx	- FSM machine token	
		cx	- action descriptor (holds offset into action chunk)
		es	- dgroup
	
RETURN:		C	- set   if set next state
		 	- clear if called function

DESTROYED:	---

PSEUDO CODE/STRATEGY:

	**** when building the finite state tables this routine will 
		never be called ***

	- get the action descriptor

	If INTERNAL function
		call (function)
		set next state to be current state

	If EXTERNAL function				
		ProcCallMod (function) ** CAN'T USE CALL MOD **
		set up arguments		
		set next state to be ground state

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	FSMFunction table may not be built up correctly for modules
	other than Screen Module.  

	Could move the check for unparesed characters to section right
	before we cal an EXTERNAL function.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
DoTokenFunction	proc	near	
	uses	ds, si, di, ax, bx, bp
	.enter
RSP <	push	cx, dx, si			; save them, don't trash>
	;
	; In Responder, we want to reduce the number of messages of saving
	; and restoring international character. Therefore, we only do so if
	; necessary. That means we only save and restore international
	; characters (by sending MSG_SCR_SAVE/RESTORE_INTL_CHAR) only if the
	; screen needs to be updatd via UpdateScreen or "ext" VT100 escape
	; functions. Otherwise, if it only performs internal function, like
	; converting number string to actual number, it doesn't save and
	; restore international character at all.
	;
	; The way to tell if we have saved an international is by pushing 0
	; or -1 on stack
	;	0: intl char not saved. -1: has intl char saved
	;
	; So, we don't end up saving international character twice or not
	; restoring the character after saving.
	; 
RSP <	clr	dx							>
RSP <	push	dx							>
	tst	es:[unParseNum]			;before calling function
	jle	DTF_callFunc			;empty out the 'callback' bufer
	;
	; In Responder, we need to indicate we save an int'l character
	;
RSP <	pop	dx				; restore stack		>
RSP <	mov	dx, -1				; use message		>
RSP <	push	dx				; re-insert signal	>
RSP <	call	FSMSaveIntlChar						>
	GetResourceSegmentNS	dgroup, ds
	call	StoreUnParsedChars
	call	UpdateScreen			;update screen before call func
DTF_callFunc:
	mov	ds, bx				;get FSM segment
	clr	di				;	
	mov	bp, ds:[di].FSM_actionHandle	;
	mov	bp, ds:[bp]			;ds:bp ->action chunk
	add	bp, cx				;offset to desired descriptor
	push	ds:[bp].FD_nextState		;get the next state and save it
	cmp	ds:[bp].FD_internalFunc, NO_FUNC;call an internal func ?
	je	DTF_ext				;nope
DTF_int:
	call	ds:[bp].FD_internalFunc		;yep

	cmp	ds:[bp].FD_externalFunc, NO_FUNC;call an external function?
	jne	DTF_ext				;yes
	clr	di				;no, pt to FSM header
RSP <	pop	ds:[di].FSM_curHandle		;set the next state	>
RSP <	pop	cx				; cx = Intlchar signal	>
RSP <	jcxz	noIntlCharSaved						>
RSP <	call	FSMRestoreIntlChar					>
RSP < noIntlCharSaved:							>
	stc					;set internal func flag
	jmp	short DTF_ret
DTF_ext:
	;
	; Check the stack to see if we have saved int'l character already
	;
RSP <	mov	si, sp							>
RSP <	inc	si							>
RSP <	inc	si				; ss:si = IntlChar signal>
RSP <	tst	{word}ss:[si]			; don't save if already saved>
RSP <	jnz	intlCharSaved						>
RSP <	mov	{word} ss:[si], -1					>
RSP <	call	FSMSaveIntlChar						>
RSP < intlCharSaved:							>
	call	ResetSavedState			; reset saved state
	call	LoadArgs			;EXTERNAL-load the arguments
	
	
	mov	ax, ds:[bp].FD_externalFunc	;load method

	
if EXTRA_EC	;=============================================================
	push	di, es
	GetResourceSegmentNS	dgroup, es, ax
	tst	es:[funcPtr]
	jnz	haveStart
wrapAround:
	mov	di, offset funcBuf
	mov	es:[funcPtr], di
haveStart:
	mov	di, es:[funcPtr]
	cmp	di, ((offset funcBuf) + 100)
	jae	wrapAround
	stosw
	mov	es:[funcPtr], di
	pop	di, es
endif	;=====================================================================
	mov	bx, es:[termuiHandle]
	CallScreenObj
	xor	di, di				;clears C flag and DI
RSP <	pop	ds:[di].FSM_curHandle		;set the next state	>
RSP <	pop	cx				;  cx = IntlChar signal	>
RSP <	jcxz	DTF_ret				; jmp if needn't restore>
RSP <	call	FSMRestoreIntlChar					>
RSP <	clc					; return success	>
DTF_ret:
NRSP <	pop	ds:[di].FSM_curHandle		;set the next state	>
RSP <	pop	cx, dx, si			; restore them		>
	.leave
	ret
DoTokenFunction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the registers with required arguments

CALLED BY:	DoTokenFunction

PASS:		bx	- FSM machine token	
		es	- dgroup	
		ds:bp	- action descriptor

RETURN:		cx, dx	- set with arguments for function
		ax	- (Responder only) number of arguments for function 

DESTROYED:	---

PSEUDO CODE/STRATEGY:
		first - fourth 	arg	ch, cl, dh, dl

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Can't put arguments in ax, bx cause CallMod trashes these 
		registers.  Can only use cx, and dx to pass args to function
		If assume that cx, dx are byte sized then can get four
		arguments

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/26/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadArgs	proc	near
	
	push	bp, si, bx
	add	bp, offset AD_argumentDesc	;offset to our arg descriptor
	mov	si, offset argArray	;es:si-> arg array
	clr	bh				;byte sized args

	mov	bl, ds:[bp]			;get argument index
	cmp	bl , ARG_NOT_USED		;is the argument valid	
	je	LA_check2nd			;no, 
	mov	ch, es:[si+bx]			;get argument value
	add	ch, ds:[bp+1]			;and adjust it
LA_check2nd:
	add	bp, 2				;point to next argument field
	mov	bl, ds:[bp]
	cmp	bl, ARG_NOT_USED
	je	LA_ret
	mov	cl, es:[si+bx]			;get argument
	add	cl, ds:[bp+1]			;and adjust it
LA_ret:
	pop	bp, si, bx
	ret
LoadArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set up a pointer to action descriptor stored in action chunk

CALLED BY:	FSMAugmentDesc, HandleIncrementParam

PASS:		bx		- FSM machine token	
		bx:[curHandle]	- handle to current state
		es		- dgroup
		es:[fileEnd]	- points to end of buffer
		es:[fileHead]	- points to place to read from buffer
		ds		- buffer segment

RETURN:		AL	token to parse
		C	set if done parsing buffer
		Z	set if token is last in current terminal sequence 

DESTROYED:	al, si

PSEUDO CODE/STRATEGY:
		if (curToken is '/' junk)
			Process the escaped chars
		if (curToken is '%' junk)
			UpdateACSize()
			Expand the parameters 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		** all the subsequent routines have to update fileHead **

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetToken	proc	near	
	mov	si, es:[fileHead]		;get ptr to place to read
	cmp	si, es:[fileEnd]		;are we at end of file	
	jge	GT_fileDone
	mov	al, ds:[si]			;get token
	call	CheckToken			;sets return flags for
	mov	es:[curToken], al		;store current token
	inc	si				;point to next token
	mov	es:[fileHead], si		;update file ptr
	cmp	{byte} ds:[si], END_OF_SEQ	;set C if at end of sequence 
	clc					;not at end of file	
	jmp	short GT_ret			;	FSMAugment 
GT_fileDone:
	stc					;flag that file done
GT_ret:						;FSMAugment looks at C and Z
	ret					;	flag
GetToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check If token is part of escaped character e.g. '\' or '^'

CALLED BY:	GetToken

PASS:		al		- token to check
		ds:*si		- token to check
		es		- dgroup	
		bx		- FSM token

RETURN:		es:[fileHead]	- points to place to read from next  
		es:[curToken]	- token to process	
		al		- token to process	
		ds:si		- points to next token to process

DESTROYED:	cl

PSEUDO CODE/STRATEGY:

		If token is '^' make next character a control char
		if token is '/' then process the following escaped chars
		if token is '%' then update up argument descriptors

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckToken	proc	near	
	cmp	al, "^"				;is it a control char
	je	CT_ctrl				;
	cmp	al, "\\"			;is it escape sequence	
	je	CT_esc
	cmp	al, "%"				;is it parameter flag
	je	CT_param
	jmp	short CT_ret			;done checking
CT_ctrl:
	inc	si				;yes, get the next char	
	mov	al, ds:[si]			;and make it a ctrl char
	and	al, CTRL_MASK			
	jmp	short CT_ret	
CT_esc:
	call	HandleEscape			;handle escaped characters
	jmp	short CT_ret
CT_param:
	call	HandleParam
CT_ret:
	ret
CheckToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process Escaped characters	

CALLED BY:	CheckToken

PASS:		bx		- FSM machine token	
		ds:si		- points to beginning of escape sequence

RETURN:		al		- token to process
		ah		- ffh	(if invalid escape sequence)
			  	  0	(if token valid)	
		es		- dgroup
		es:[inputBase]	- set to current number format	

DESTROYED:	cl

PSEUDO CODE/STRATEGY:
Convert	the following escape sequence to their ascii value

    \b	    	    Backspace 		(ASCII 8)
    \e or \E	    Escape 		(ASCII 27, decimal)
    \f		    Formfeed		(ASCII 10)	
    \n	    	    Newline 		(ASCII 10)
    \r	    	    Carriage return 	(ASCII 13)
    \t		    Tab			(ASCII 9)	
    \\	    	    Backslash itself
    \x<n>   	    Character whose value is <n>, base 16
    \<n>    	    Character whose value is <n>, base 8
    \[...\] 	    Characters in the range given between the brackets. The
    	    	    range is specified in standard UNIX character range form,
    	    	    i.e. a character by itself indicates just that character;
		    a string like 0-9 indicates the characters from 0 to 9,
		    inclusive; a ^ at the start of the class causes a match
		    for all characters not in the range. If - is to be
		    included, it should be the first character in the class.

    \%		    Following argument to be used in CASE function
			d	A string of digits. First non-digit ends
				argument.
			c	A hex value

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Since I'm comparing around 10 characters perhaps i should
		try to make some type of table coversion?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
HandleEscape	proc	near
	inc	si
	mov	al, ds:[si]			;get character to convert
	cmp	al, "e"				;check for escape
	je	HE_esc
	cmp	al, "E"				;check for Escape
	je	HE_esc
	cmp	al, "n"				;check for newline
	je	HE_n
	cmp	al, "r"				;check for carriage return
	je	HE_r
	cmp	al, "t"				;check for tab
	je	HE_t
	cmp	al, "b"				;check for backspace
	je	HE_bs
	cmp	al, "f"				;check for form feed
	je	HE_f
	cmp	al, "x"				;check for hex value
	je	HE_x
	cmp	al, "%"
	je	HE_param	
	mov	es:[inputBase], OCTAL		;set octal number base
	mov	cl, al				;(pass token to check)	
	push	ax, bx				;save char and FSM tokens
	CallMod	CheckIfNum	
	pop	ax, bx
	jc	HE_error
	call	ConvOctalNumber
	mov	es:[inputBase], DECIMAL		;reset number base back to dec
	mov	al, dl				;pass octal value
	jmp	short HE_done
HE_esc:
	mov	al, CHAR_ESC 
	jmp	short HE_done	
HE_n:
	mov	al, CHAR_NL
	jmp	short HE_done
HE_r:
	mov	al, CHAR_CR
	jmp	short HE_done
HE_t:
	mov	al, CHAR_TAB
	jmp	short HE_done
HE_bs:
	mov	al, CHAR_BS
	jmp	short HE_done
HE_f:
	mov	al, CHAR_FF
	jmp	short HE_done
HE_x:
	mov	es:[inputBase], HEX	;set input number format
	call	SetInternalFunc		;tell FSM to process number 
	jmp	short HE_done
HE_param:
	inc	si
	mov	al, ds:[si]		;get number format
	cmp	al, "d"			;if not decimal then error
	jne	HE_error
	mov	es:[inputBase], DECIMAL	;set input format to decimal	
	call	SetCaseFunc
	jmp	short HE_done
HE_error:
	mov	ah, 0ffh		;signal error
	jmp	short HE_ret		;leave SI pointing at error char

HE_done:
	clr	ah			;signal token okay
HE_ret:
	ret
HandleEscape	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleParam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle parameter specification in description file	

CALLED BY:	CheckToken

PASS:		bx		- FSM machine token	
		ds:*si		- token to check
		al		- token to check
		es		- dgroup	
		

RETURN:		al		- next token to process
		ds:si		- points to this token

DESTROYED:	---

PSEUDO CODE/STRATEGY:
		%d	- A string of digits.  First non-digit ends argument 
			  (setup up internal function to convert Ascii numbers
				to hex value)
		%c	- a single character whose value is stored as argument

		%+x	- add x to value, then do %	

		%i	- decrement the value by one 	

		%r	- reverse order of next two parameters

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
HandleParam	proc	near	
	cmp	es:[initAD], TRUE		;arg desc initialized?
	je	HP_ok				;yes 
	call	InitArgDesc			;no
HP_ok:
	inc	si				
	mov	al, ds:[si]			;get paramter type
	cmp	al, "c"				;is it a charater
	je	HP_c				;no, flag error
	cmp	al, "d"				;is it decimal format
	je	HP_d				;yes, do it
	cmp	al, "i"
	je	HP_i
	cmp	al, "+"
	je	HP_offset
	jmp	short HP_error			;error no match
HP_c:
	call	HandleCharParam
	jmp	short HP_done
HP_d:
	call	HandleDecParam
	jmp	short HP_done
HP_i:
	call	HandleIncrementParam		;processed '%i'
	jmp	short HP_done
HP_offset:
	call	HandleOffset			;process '%+x'
HP_done:
	mov	es:[addToken], FALSE		;set flag that token 
						;shouldn't be added to table
HP_error:
HP_ret:
	ret
HandleParam	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleCharParam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a character parameter

CALLED BY:	HandleParam

PASS:		bx		- FSM machine token	
		ds:*si		- token to check
		es		- dgroup	
		
RETURN:		---

DESTROYED:	---

PSEUDO CODE/STRATEGY:
		Set a state that matches any token 
			set internal function to store the next token value.  
			(increment argument index)
		creates a new state
		sets next state to be this new state
		
	****	To indicate that this state maps all tokens either have
		a wildcard token (*) or make size of table entries 255.
		Have to modify SearchCurTable to do the right thing, 
	**** 	Another hack in the code is to handle the string 
		'cm=%+ %+ :'in the /etc/termcap file.
		Currently the way the parser works is I get a token
		then I check to see if the token needs to be processed
		(i.e. escape or control chars need to be converted), if
		the token is part of a paramter string then I process
		that parameter string and return the next character
		as the character to be processed.  So if '%dm' was a
		sequence and the token '%' was passed to CheckToken()
		then the parser would process '%d' invisibly and return
		'm' as the token to handle next.  The parser would
		notice that 'm' was the end of the sequence and set
		up for an external function to be called.  Well with
		%+ %+ which I expanded in my termcap file to be 
		'%+ %c%+ %c' When my CheckToken routine is passed the
		first '%' I'll process all four arguments before 
		returning.  Well the problem is that when handling
		the '%c' I add a '*' to the table, create a new state,
		and set the next state to be this new state that I
		created.  To make a long story longer, I don't correctly
		detect end of sequence when you have a %sequnce as the
		last token in the sequence.  My hack is that when i know
		 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		We needlessly create states that won't be used.
		For example, the sequence %c%c.  When processing
		the first '%c' we create a state that will be used 
		to process the next '%c'.  When processing the second
		'%c' we also create another state, this state won't
		be used and is a waste.  If we know that we won't
		ever get more than (2) %c is a row then can set
		flags not to create the extra states.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
HandleCharParam	proc	near	
	push	ds, si				;save ptr into char buffer
	mov	al, CHAR_WILD			;add wildcard character
	call	AddTokenToTable
	mov	dx, es:[curACoffset]		;  get ptr to action descriptor
	or	dx, AD_FLAG			;  flag that its a func desc
	call	StoreActionWord			;  and store it in state table 

	mov	ds, bx				;now fill in action block
	clr	bp				
	mov	bp, ds:[bp].FSM_actionHandle	;ds:bp -> LMem handle
	mov	bp, ds:[bp]			;ds:bp -> Lmem chunk	
	mov	si, es:[curACoffset]		;  (store ptr to curent AD)
	add	bp, si				;ds:bp -> current action desc
	mov	cx, offset cs:GetChar		;point to get char routine
	mov	ds:[bp].FD_internalFunc, cx  	;set internal func ptr
	call	MakeNewState			
	clr	bp 				;  (FSM block may have moved)
	mov	bp, ds:[bp].FSM_actionHandle	;  (So dereference it again)
	mov	bp, ds:[bp]
	add	bp, si
	mov	ds:[bp].FD_nextState, ax	;store next state for this func
	clr	si
	mov	ds:[si].FSM_curHandle, ax	;current state is next state

	cmp	es:[initAD], TRUE		;is the argument descriptor
	je	HCP_ADok			;	initialized?	
	call	InitArgDesc			;no
HCP_ADok:
	mov	si, es:[argNum]			;update the argument descriptor
	mov	bp, offset argumentDesc	;calculate index into arg struct
	shl	si, 1				;
	mov	cx, es:[argNum]			;store the argument number
	mov	{byte} es:[bp+si], cl		;
	inc	es:[argNum]			;increment argument count
	mov	es:[reuseAD], TRUE		;if this is last token want
	mov	dl, INTERNAL			;  to reuse this action desc
	call	UpdateACSize			;point to next action desc
	pop	ds, si				;restore file ptr
	ret
HandleCharParam	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	store the current token in the argument array

CALLED BY:	DoTokenFunction

PASS:		bx	- FSM machine token	
		es	- dgroup	
		al	- token	

RETURN:		

DESTROYED:	---

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/06/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetChar	proc	near
	mov	di, offset argArray	
	add	di, es:[argNum]		;index into argument array 
	mov	{byte} es:[di], al	;and store current token
	inc	es:[argNum]
	ret
GetChar	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleDecParam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle decimal parameter


PASS:		bx	- FSM machine token	
		ds:si	- file buffer	
		es	- dgroup	
		dl	- function type

RETURN:		---

DESTROYED:	dl

PSEUDO CODE/STRATEGY:
		Create a new state
		Two Ways :

	1)	Have all tokens map to a common internal function
		Internal function checks 
			if character is a number		
				CalcNumber
			Else
				Create a new state
				make new state cur state
	2)
		Add entries 0-9 to this table
			make action word point to internal function : CalcNumber
		any non-digit gets added to this table just like normal

	To properly handle '%d' we create two state, first state is a first
	digit state.  It only has entries for 0-9.  The action word for these
	tokens is to go to another state that has also has tokens 0-9.
	The action words for these tokens is to call CalcNumber routine.
	Non-digits would be handled in this second state.

	If tokens 0-9 already in table then don't try to add them again,
	just go to their next state.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Is it okay to increment argument index here?
	We're adding ten token sequentially.  Is this slow ? cauz we're
	shifting all the time?  Do something smarter like add the ten
	char tokens to the table first then add the ten action words ?

	** could expand this to HandleNumParam, so could be used to
	process octal, and hex numbers, LATER **


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
HandleDecParam	proc	near	
	push	ds, si				;save file ptr
	;
	; Enter 0-9 into character table if the wildcard digits have not been
	; entered. 
	;
HDP_topLoop:
	;
	; Test if wildcard digit has been entered in this state. If so, skip.
	;
	mov	ds, bx
	mov	bp, ds:[0].FSM_curHandle	; bp <- lptr of current state
	mov	bp, ds:[bp]			; dsbp<-fptr to state chunk
	cmp	ds:[bp].SH_wildcardDigitAction, NULL_ACTION
	LONG jne	HDP_alreadyInserted	; already there, skip!
	mov	al, "0"
HDP_notFound:
	mov	cx, 10				;create entries to get first #
	mov	dx, es:[curACoffset]		;store ptr to internal function
	mov	ds:[bp].SH_wildcardDigitAction, dx
						; offset to action table
	or	dx, AD_FLAG			;
HDP_loop:
	call	AddTokenToTable			;add tokens 0-9 to tabke
	call	StoreActionWord			;store func desc to calc # routine 
	inc	al
	loop	HDP_loop			;
	
	mov	ds, bx				;now update the function
						;descriptor 
	clr	bp				; beginning
	mov	bp, ds:[bp].FSM_actionHandle	;ds:bp -> LMem handle
	mov	bp, ds:[bp]			;ds:bp -> Lmem chunk	
	mov	si, es:[curACoffset]		;  (store ptr to curent AD)
	add	bp, si				;ds:bp -> current action desc
	mov	cx, offset cs:CalcNumber	;
	mov	ds:[bp].FD_internalFunc, cx  	;flag internal func called
	mov	es:[reuseAD], TRUE		;if this is last token want
	mov	dl, INTERNAL			;to reuse it
	call	UpdateACSize			;point to next action desc
	cmp	es:[secondState],TRUE		;now fill in the next state
	je	HDP_secondPass			;the next state for the first state
	call	MakeNewState			;points to a new state 
	clr	bp 				;  (FSM block may have moved)
						;ignore FUNCTION TYPE	
	mov	bp, ds:[bp].FSM_actionHandle	;  (So dereference it again)
	mov	bp, ds:[bp]
	add	bp, si
	mov	ds:[bp].FD_nextState, ax	;
	clr	si				;new state is the current state.
	mov	ds:[si].FSM_curHandle, ax	;
	mov	es:[secondState],TRUE		;set flag to process next state
	jmp	HDP_topLoop
HDP_secondPass:					;the next state for the second
	mov	es:[secondState], FALSE		;reset flag
	clr	si
	mov	ax, ds:[si].FSM_curHandle	;current state is next state
	mov	ds:[bp].FD_nextState, ax	;for the internal functions
HDP_skip:
						;Do argument descriptor stuff
	cmp	es:[initAD], TRUE		;is the argument descriptor
	je	HDP_ADok			;	initialized?	
	call	InitArgDesc			;no
HDP_ADok:
	mov	si, es:[argNum]			;update the argument descriptor
	mov	bp, offset argumentDesc	;calculate index into arg struct
	shl	si, 1				;
	mov	cx, es:[argNum]			;store the argument number
	mov	{byte} es:[bp+si], cl		;
	inc	es:[argNum]			;increment argument count
	pop	ds, si				;restore file ptr
	ret

HDP_alreadyInserted:
	;
	; The wildcard digits 0-9 has already been inserted. Now we move to
	; that next state. Since %d means 1 or more digits, it actually
	; points the next state which also has 0-9 wildcard digits.Since it
	; recursively points to itself, we want to set this as the next
	; state. 
	;
	mov	bp, ds:[bp].SH_wildcardDigitAction
						; bp <- offset to action table
EC <	push	bp							>
EC <	and	bp, AD_FLAG						>
EC <	ERROR_NZ -1				; action stored should be pure offset to action table>
EC <	pop	bp							>
	mov	di, ds:[0].FSM_actionHandle	; di <- action table lptr
	mov	di, ds:[di]			; di <- begin of action table
	add	di, bp				; di <- action table of
						; wildcard digit
	segmov	ds:[0].FSM_curHandle, ds:[di].FD_nextState, bp
						; update the current state
	jmp	HDP_skip
HandleDecParam	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update offset field of argument descriptor

CALLED BY:	HandleParam

PASS:		bx		- FSM machine token	
		ds:*si+1	- token to check
		es		- dgroup	

RETURN:		---

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/31/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
HandleOffset	proc	near	
	inc	si
	mov	al, ds:[si]			;get offset amount
	cmp	al, "\\"
	jne	HO_char
	inc	si				;point to octal #
	call	ConvOctalNumber
	jmp	short HO_ret
HO_char:
	mov	dl, al				;move token 
HO_ret:
	call	UpdateArgOffset
	ret
HandleOffset	endp

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleIncrementParam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the argument adjust field

CALLED BY:	HandleParam

PASS:		bx	- FSM machine token	
		es	- dgroup	

RETURN:		---

DESTROYED:	bp, cx

PSEUDO CODE/STRATEGY:
		Set the current argument's adjust field to decrement one.	

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
HandleIncrementParam	proc	near	
	mov	dl, 1
	call	UpdateArgOffset
	ret
HandleIncrementParam	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateArgOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		bx	- FSM machine token	
		es	- dgroup	
		dl	- amount to set the argument offset to
	

RETURN:		

DESTROYED:	bp, cx

PSEUDO CODE/STRATEGY:
				

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/01/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
UpdateArgOffset	proc	near	
	push	si
	mov	si, es:[argNum]			;get argument #
	mov	bp, offset argumentDesc	;calculate index into arg struct
	shl	si, 1				; si<-the right argument
	inc	si				;point to adjust field
						;(constant)  
	neg	dl				;negate the offset
	mov	{byte} es:[bp+si], dl		;
	pop	si
	ret
UpdateArgOffset	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calculate binary value of ascii string

CALLED BY:	FSMCreate

PASS:		bx	- FSM machine token	
		es	- dgroup	
		al	- token to convert

RETURN:		---

DESTROYED:	---

PSEUDO CODE/STRATEGY:
		If inNumFlag is FALSE (weren't previously in internal routine)
			inNumFlag = TRUE
			get new index to store number
			clear out number counter
			convert token passed
		Else
			convert token passed
			

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This function is just like ConvertDecNumber
		should merge them, do it LATER ? :=) 
		* only handles decimals *	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
CalcNumber	proc	near	
EC <  	cmp     es:[argNum], MAX_EMULATION_ARG                          >
EC <  	ERROR_AE TERM_MAX_EMULATION_ARGUMENT_EXCEEDED                   >
	cmp	es:[inNumFlag], TRUE	
	je	CN_ok
	mov	es:[inNumFlag], TRUE	;set up function junk
	mov	di, offset argArray	
	add	di, es:[argNum]		;index into array to store number	
	mov	{byte} es:[di], 0	;and clear it
CN_ok:
	mov	ch, al			;save the token
	mov	di, offset argArray
	add	di, es:[argNum]
	mov	al, es:[di]
	mov	cl, DECIMAL_BASE	
	mul	cl			;shift number over
	sub	ch, "0"			;get tokens numeric value
	add	al, ch			;add it to the number	
	mov	{byte} es:[di], al	;stuff in new value	
CN_ret:
	ret
CalcNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetExternalFunc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set function to call for current token entry

CALLED BY:	FSMAugmentDesc

PASS:		ds:si	- points to function to call	
		al	- current token
		es	- dgroup
		bx	- FSM machine token

RETURN:		ds:si	- beginning of next line

DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
		add current token to table
		get function to call
		set the function to call
		set next state to ground state
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		When dealing with terminal sequences that use parameters
		may on occasion add bogus tokens to a table that will
		never be reached.  For example, cm='\EY%+ %c%+ %c	1'
		When finishing processing the last %c, we point to a new
		table.  When SetExternalFunc gets called, we're pointing
		to a bogus table, and we'll shove bogus tokens into it,
		but we don't care cause all we want to do is set the
		the previous AD up correctly.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
SetExternalFunc	proc	near
	push	ds, es				;save buffer segment

	call	AddTokenToTable			;store token
	mov	dx, es:[curACoffset]		;store ptr to action descriptor
	or	dx, AD_FLAG			;
	call	StoreActionWord			;

	call	SkipWhiteSpace
	mov	ds, bx				;ds -> FSM segment
	clr	bp				
	push	ds:[bp].FSM_groundHandle	;save the ground state
	mov	bp, ds:[bp].FSM_actionHandle	;ds:[bp] -> LMem handle
	mov	bp, ds:[bp]			;ds:[bp] -> Lmem chunk	
	cmp	es:[reuseAD], TRUE		;hack: reuse previous AD?
	jne	10$				;nope
	call	ReusePrevAD
10$:
	add	bp, es:[curACoffset]		;ds:[bp] -> current action desc
	pop	ds:[bp].FD_nextState		;next state for func
						; 	is ground state
	cmp	es:[initAD], TRUE		;arg descriptor initialized?
	je	SEF_ADok			;yes 
	call	InitArgDesc			;no, default to no arguments
SEF_ADok:					;copy the arg desc into 
	call	CopyArgDesc			;  into the action desc
	mov	es:[inputBase], DECIMAL		;functions are in decimal
	call	GetFunction			; cx = method to call
	mov	ds:[bp].FD_externalFunc, cx	;store method number
	mov	dl, EXTERNAL
	call	UpdateACSize			;point to next AD in chunk

	mov	es:[initAD], FALSE		;action descriptor not initialized
	clr	es:[argNum]			;nuke the argument count
	clr	bp
	mov	cx, ds:[bp].FSM_groundHandle	;set the current state
	mov	ds:[bp].FSM_curHandle, cx	;	to be ground state
SEF_ret:
	pop	ds, es
	ret
SetExternalFunc	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyArgDesc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the argument structure into the action descriptor

CALLED BY:	SetExternalFunc

PASS:		bx	- FSM machine token	
		es	- dgroup	
		ds	- FSM segment
		ds:bp	- top of our current action descriptor

RETURN:		---

DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
CopyArgDesc	proc	near	
	push	es, ds, si
	mov	di, bp 					;di top of action desc
	add	di, offset AD_argumentDesc		;ds:di -> arg descriptor
	mov	si, ds					;swap es, ds
	segmov	ds, es, cx				
	mov	es, si
	mov     si, offset argumentDesc                 ;es:si -> idata arg
							;  array
	mov     cx, size argumentDesc                   ;ds:si -> idata array
EC <	Assert_okForRepMovsb                                            >
	shr     cx                                      ;cx <- #words to copy
	rep	movsw					;es:di -> action desc
	pop	es, ds, si
	ret
CopyArgDesc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitArgDesc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize the argument descriptor

CALLED BY:	SetExternalFunc

PASS:		es		- dgroup	

RETURN:		es:[initAD]	- set TRUE

DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:
		Get current AD		
		Set all registers to be not used	
		set all arguments to be not adjusted

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Should I use a 'stos' in the IAD_loop to make it faster

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
InitArgDesc	proc	near	
	mov	di, offset argumentDesc	;get ptr to structure

	mov	cx, MAX_EMULATION_ARG
IAD_loop:
	mov	{byte} es:[di], ARG_NOT_USED	;flag register not used
	inc	di	
	mov	{byte} es:[di], NO_ADJUST	;set argument adjust value	
	inc	di
	loop	IAD_loop
IAD_ret:
	mov	es:[initAD], TRUE
	ret
InitArgDesc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateACSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the number of action descriptors

CALLED BY:	SetExternalFunction, HandleParameter

PASS:		bx	- FSM machine token	
		es	- dgroup
		dl	- function type	 (INTERNAL, EXTERNAL)		
		ds	- FSM segment

RETURN:		ds 	- FSM segment

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		if not enough room for another AD
			realloc the action chunk
			update the max AD count
		update the size info for the descriptor just
			allocated either function or action descriptor.

		The program will always assume that es:[curACoffset]
		reflects ptr to space for action/function  descriptor
		Wheneve the action chunk is updated, we check
		to ensure that there's room for another action/function
		descriptor.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
UpdateACSize	proc	near	
	push	si, bp
	mov	ds, bx				;get FSM segment
	clr	si
	mov	cx, es:[curACoffset]		;get current size of Action chunk
	cmp	cx, es:[maxACsize]		;is there room for another AD
	jl	CrAD_ok
	mov	ax, ACTION_DESC_SIZE		;calculate size of AD table
	shl	ax, 1
	add	ax, EXPAND_ACTION_SIZE		;increase table by this much
	add	cx, ax
	mov	ax, ds:[si].FSM_actionHandle	;get the action handle
	call	LMemReAlloc			;  resize this chunk
	mov	es:[fsmBlockSeg], ds		;LMem heap may have moved
	mov	bx, ds				;	so update copies
	add	es:[maxACsize], EXPAND_ACTION_SIZE
						;update the new max size
CrAD_ok:
	cmp	dl, EXTERNAL
	je	CrAD_ext			
	mov	cx,  FUNC_DESC_SIZE		;internal function
	jmp	short CrAD_ret
CrAD_ext:
	mov	cx,  ACTION_DESC_SIZE		;external function
CrAD_ret:
	add	es:[curACoffset], cx		;point to next desc in chunk
	mov	bp, ds:[si].FSM_actionHandle
	mov	bp, ds:[bp]			;dereference block handle	
	add	bp, es:[curACoffset]		;offset to current chunk
	mov	ds:[bp].FD_internalFunc, NO_FUNC;default no internal funcs
	mov	ds:[bp].FD_externalFunc, NO_FUNC;default no external funcs
	pop	si, bp
	ret
UpdateACSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetInternalFunc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the action word to point to an internal func


CALLED BY:	HandleEscape, HandleParam 

PASS:		bx	- FSM machine token	

RETURN:		---

DESTROYED:	---

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
SetInternalFunc	proc	near	
;
;	*** STUB ***
;
	ret
SetInternalFunc	endp
 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCaseFunc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set function descriptor to handle a CASE argument

CALLED BY:	HandleEscape

PASS:		bx	- FSM machine token	
		es	- dgroup	
		ds:si	- pointing into termcap buffer
		al	- token just read ('d')

RETURN:		---

DESTROYED:	---

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetCaseFunc	proc	near	
;
;	*** STUB ***
;
	ret
SetCaseFunc	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipWhiteSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	advance pointer past all the non printable chars  	

CALLED BY:	FSMAugmentDesc	

PASS:		es	- dgroup
		ds:si	- white space to skip

RETURN:		ds:si	- points to first non Printable char

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Everything below a space is considered unprintable.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		May not have to update [fileHead]


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
SkipWhiteSpace	proc	near	
SWS_loop:
	cmp	{byte} ds:[si], CHAR_SPACE	;if char have value > space
	jg	SWS_ret				;assume its printable
	inc	si
	jmp	short SWS_loop
SWS_ret:
	ret
SkipWhiteSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get function to call from termcap buffer 

CALLED BY:	SetExternalFunc

PASS:		bx		- FSM machine token	
		es		- dgroup	
		ds		- FSM segment
		ds:bp		- top of our current action descriptor
		es:[termSeg]	- segment of terminal buffer 
		termSeg:si	- points at function specifier

RETURN:		cx	- function to call (method #)
		ds:si	- points to beginning of next line

DESTROYED:	---

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		** should use string search routine to match funtion names

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
GetFunction	proc	near	
	push	ds
	mov	ds, es:[termSeg]
	push	bx				;save FSM token
	CallMod	ConvertDecNumber		;ds:si -> beginning of function
	pop	bx
	cmp	ax, ERROR_FLAG			;get function index to call
	mov	cx, 0				; hack - in case of error,
						;	use bell function?
						; (preserve flags)
						; (brianc 10/1/90)
	je	GF_exit
	shl	ax, 1				;calculate offset into table
	cmp	ax, FSM_FUNCTION_TABLE_SIZE	; if non-existent func,
	WARNING_AE TERM_FUNCTION_NOT_SUPPORTED
	jae	GF_exit				; bail
	mov	di, offset FSMFunctionTable 	;get the function to call	
	add	di, ax				;offset into the table
GF_eoln:
	inc	si				;check for eoln
	cmp	{byte} ds:[si], CHAR_NL
	je	GF_ret
	jmp	short GF_eoln						
GF_ret:
	inc 	si				;advance file ptr pass newline
	mov	es:[fileHead], si		;es:si -> start of next sequence
	mov	cx, cs:[di]			; return method number
GF_exit:
	pop	ds
	ret
GetFunction	endp

	;
	; This table is important in figuring what index escape codes map to.
	; Beware of the conditional compilation messing up with number
	; seqeunce.
	;
FSMFunctionTable	label	word
	dw	MSG_SCR_SOUND_BELL		;func 	0	
	dw	MSG_SCR_CURSOR_LEFT		;func 	1	
	dw	MSG_SCR_TAB			;func 	2	
	dw	MSG_SCR_CURSOR_DOWN_OR_SCROLL	;func 	3	
	dw	MSG_SCR_CR			;func 	4	
	dw	MSG_SCR_SCROLL_DOWN		;func 	5	
	dw	MSG_SCR_UP_ARROW		;func 	6	
	dw	MSG_SCR_DOWN_ARROW		;func 	7	
	dw	MSG_SCR_RIGHT_ARROW		;func 	8	
	dw	MSG_SCR_LEFT_ARROW		;func 	9	
	dw	MSG_SCR_FUNC_1		;func 	10
	dw	MSG_SCR_FUNC_2		;func 	11
	dw	MSG_SCR_FUNC_3		;func 	12
	dw	MSG_SCR_FUNC_4		;func 	13
	dw	MSG_SCR_CLEAR_HOME_CURSOR	;func 	14
	dw	MSG_SCR_APPLICATION_KEYPAD	;func 	15
	dw	MSG_SCR_NUMERIC_KEYPAD		;func 	16
	dw	MSG_SCR_CURSOR_UP_UNCONSTRAINED	;func 	17
	dw	MSG_SCR_CURSOR_RIGHT		;func 	18
	dw	MSG_SCR_HOME_CURSOR		;func	19
	dw	MSG_SCR_CLEAR_TO_END_DISP	;func	20
	dw	MSG_SCR_CLEAR_TO_END_LINE	;func	21
	dw	MSG_SCR_NORMAL_MODE		;func	22
	dw	MSG_SCR_SAVE_CURSOR		;func	23
	dw	MSG_SCR_RESTORE_CURSOR	;func	24
	dw	MSG_SCR_CHANGE_SCROLLREG	;func	25
	dw	MSG_SCR_REL_CURSOR_MOVE	;func	26
	dw	MSG_SCR_BOLD_ON		;func	27
	dw	MSG_SCR_UNDERSCORE_ON	;func	28
	dw	MSG_SCR_BLINK_ON		;func	29
	dw	MSG_SCR_REV_ON		;func	30
	dw	MSG_SCR_INS_LINE		;func	31	
	dw	MSG_SCR_BACK_TAB		;func	32
	dw	MSG_SCR_DEL_LINE		;func	33
	dw	MSG_SCR_DEL_CHAR		;func	34
	dw	MSG_SCR_INS_CHAR		;func	35
	dw	MSG_SCR_GO_STATUS_COL	;func	36
	dw	MSG_SCR_ENTER_INS_MODE	;func	37
	dw	MSG_SCR_EXIT_INS_MODE	;func	38
	dw	MSG_SCR_SCROLL_UP		;func	39
	dw	MSG_SCR_TERM_INIT		;func	40
	dw	MSG_SCR_SANE_RESET		;func	41
	dw	MSG_SCR_GRAPHICS_ON		;func	42
	dw	MSG_SCR_SET_ROW		;func	43
	dw	MSG_SCR_SET_COL		;func	44
	dw	MSG_SCR_UNDERSCORE_OFF	;func	45
	dw	MSG_SCR_REV_OFF		;func	46
	dw	MSG_SCR_SET_TAB		;func	47
	dw	MSG_SCR_CLEAR_TAB		;func	48
	dw	MSG_SCR_VISUAL_BELL		;func	49
	dw	MSG_SCR_CURSOR_DOWN_OR_SCROLL_N	;func	50
	dw	MSG_SCR_CURSOR_LEFT_N	;func	51
	dw	MSG_SCR_CURSOR_RIGHT_N	;func	52
	dw	MSG_SCR_CURSOR_UP_N_UNCONSTRAINED	;func	53
	dw	MSG_SCR_CURSOR_OFF		;func	54
	dw	MSG_SCR_CURSOR_ON		;func	55
	dw	MSG_SCR_IGNORE_ESC_SEQ		;func	56
	dw	MSG_SCR_RESPOND_WHAT_ARE_YOU	;func	57
	dw	MSG_SCR_RESET_SCROLLREG		;func	58
	dw	MSG_SCR_RENEW_GRAPHICS_ON	;func	59
	dw	MSG_SCR_RENEW_SCROLL_REG_BOTTOM ;func	60
if	_CHAR_SET
	dw	MSG_SCR_SELECT_G0		;func	61
	dw	MSG_SCR_SELECT_G1		;func	62
	dw	MSG_SCR_G0_SELECT_USASCII	;func	63
	dw	MSG_SCR_G0_SELECT_GRAPHICS	;func	64
	dw	MSG_SCR_G1_SELECT_USASCII	;func	65
	dw	MSG_SCR_G1_SELECT_GRAPHICS	;func	66
else
	dw	MSG_SCR_IGNORE_ESC_SEQ		;func	61
	dw	MSG_SCR_IGNORE_ESC_SEQ		;func	62
	dw	MSG_SCR_IGNORE_ESC_SEQ		;func	63
	dw	MSG_SCR_IGNORE_ESC_SEQ		;func	64
	dw	MSG_SCR_IGNORE_ESC_SEQ		;func	65
	dw	MSG_SCR_IGNORE_ESC_SEQ		;func	66
endif
	dw	MSG_SCR_RESPOND_CURSOR_POSITION	;func	67
	dw	MSG_SCR_RESPOND_STATUS		;func	68
	dw	MSG_SCR_CLEAR_TO_BEG_LINE	;func	69
	dw	MSG_SCR_CLEAR_TO_BEG_DISP	;func	70
	dw	MSG_SCR_CLEAR_LINE		;func	71
	dw	MSG_SCR_CURSOR_DOWN		;func	72
	dw	MSG_SCR_CURSOR_UP_OR_SCROLL	;func	73
	dw	MSG_SCR_CURSOR_DOWN_N		;func	74
	dw	MSG_SCR_CURSOR_UP		;func	75
	dw	MSG_SCR_CURSOR_UP_N		;func	76
	dw	MSG_SCR_NEXT_LINE		;func	77
	dw	MSG_SCR_RESET_MODE		;func	78
	dw	MSG_SCR_SET_MODE		;func	79
	dw	MSG_SCR_LF			;func	80

FSM_FUNCTION_TABLE_SIZE	equ ($-(offset FSMFunctionTable))


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertOctalNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts octal ascii number to a hex value

CALLED BY:	GetFunction

PASS:		ds:si	- beginning of string
		

RETURN:		dl	- binary value of octal number
		si	- pointing to end of octal number 

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		For each character			
		get value curChar - "0"
		multiply current number by 10
		add in value

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
ConvOctalNumber	proc	near	
	mov	cl, 2
	clr	dh
	mov	dl, ds:[si] 			;get first octal number
	sub	dl, '0'				;convert to binary value
HO_oct:
	inc	si
	mov	al, ds:[si] 			;get number
	sub	al, '0'
	shl	dl, 1				;shift over octal digit
	shl	dl, 1				;
	shl	dl, 1				;
	add	dl, al
	loop	HO_oct
	cmp	dl, 128				;termcap entry said it send
	jne	HO_ret				;\200, but actually sent NULLs
	mov	dl, CHAR_NULL
HO_ret:
	ret
ConvOctalNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSMInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize the FSM variables

CALLED BY:	FSMCreate

PASS:		ax	- FSM segment
		es	- dgroup	

RETURN:		---

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
FSMInit	proc	near	
	mov	cl, FALSE
	mov	es:[initAD], cl			;action descriptor uninitialized
	mov	es:[inNumFlag], cl		;not in an internal routine
	mov	es:[secondState], cl		;second state flag is reset
	mov	es:[inParse], cl		;not in parsed state

	clr	cx
	mov	es:[curACoffset], cx		;clear ptr into action chunk 
	mov	es:[argNum], cx			;no arguments stored
	mov	es:[inputBase], DECIMAL
	ret
FSMInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFSMState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check the fsm state

CALLED BY:	FSMParseString, SearchCurTable

PASS:		al	- current token 
		es	- dgroup	
		ds:si	- points at token

RETURN:		---

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
	if we were in an internal function (like to calculate numbers 
	then we want to turn off this flag at the
	next non-digit character).  So we'll do that here.

		Check if we were in one of our internal routines 
		update argument index accordingly

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/26/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
CheckFSMState	proc	near	
	cmp	es:[inNumFlag], FALSE		;were we in an internal func?
	je	CS_ret				;nope,
	mov	cl, al				;get token to check	
	push	ax, bx				;save char and FSM tokens
	CallMod	CheckIfNum			;is this token numeric?
	pop	ax, bx
	jnc	CS_ret				;yes, pass to internal func
	mov	es:[inNumFlag], FALSE		;no, reset flag
	cmp     es:[argNum], MAX_EMULATION_ARG  ;don't increase arg when max
	jae     CS_ret                          ;  is reached
	inc	es:[argNum]			;advance argument index
CS_ret:
	ret
CheckFSMState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreUnParsedChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy unrecognized chars into call back buffer

CALLED BY:	FSMParseString

PASS:		bx			- FSM machine token	
		es			- dgroup	
		ds			- char buffer segment (dgroup)
		es:[unParseNum]		- number of chars to copy
		es:[unParseStart]	- ptr to where to copy from
		es:[unParseBufHead]	- ptr to where to copy to

RETURN:		es:[unParseStart]	- pts to first char after sequence
		es:[unParseBufHead]	- pts to after the copied sequence

DESTROYED:	dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Depend on fact that ds, es same cause buffer is in dgroup

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
StoreUnParsedChars	proc	near	
EC <	call	ECCheckDS_ES_dgroup					>
	push	ds, si, cx
	mov	cx, es:[unParseNum]		;if no chars to copy exit
	jcxz	SUPC_ret
	add	es:[unParseBufNum], cx		;update # chars in buffer
	mov	si, es:[unParseStart]		;ds:si-> ptr to src
if EXTRA_EC	;=============================================================
EC <	call	ECCheckDS_ES_dgroup					>
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
	add	ax, cx
	cmp	ax, ((offset crapBuf) + AUX_BUF_SIZE)
	jae	wrapAround
	rep	movsw				; append to crapBuf
	mov	ds:[crapPtr], di
	pop	ax, cx, si, di
endif	;=====================================================================
	mov	di, es:[unParseBufHead]		;es:di-> ptr to dest
	cmp	si, di
	jne	SUPC_rep			;if src != dest do the copy 
	add	si, es:[unParseNum]		;else just skip the copy
DBCS <	add	si, es:[unParseNum]		;char offset -> byte offset>
	add	di, es:[unParseNum]		;	and advance the ptrs	
DBCS <	add	di, es:[unParseNum]		;char offset -> byte offset>
	jmp	short SUPC_update		;	past the chars
SUPC_rep:
	push	es
	segmov	es, ds, dx			;es->packet buffer
SBCS <	rep	movsb				;copy the characters	>
DBCS <	rep	movsw				;copy the characters	>
	pop	es				;restore es to dgroup
SUPC_update:
	mov	es:[unParseStart], si		;update src pointer	
	mov	es:[unParseBufHead], di		;update dest pointer
	clr	es:[unParseNum]			;clear num of chars to copy into buf
SUPC_ret:
	pop	ds, si, cx
	ret
StoreUnParsedChars	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass the unrecognized chars to the screen object 

CALLED BY:	FSMParseString, DoTokenFunction

PASS:		ds, es	- dgroup
		ds:[fileHead]	= offset to start of buffer in [auxBuf].
		ds:[unParseBufNum] = number of characters to display

		THIS IS OLD:
			bx	- FSM machine token	
			al	- current character token
			ds:bp	- current action description

RETURN:		ds, es, ax, bx, cx = same
		ds:[fileHead]	= advanced past buffer of chars
		ds:[unParseBufNum] = 0

DESTROYED:	dx, bp, si, di

PSEUDO CODE/STRATEGY:
		If no chars to print then don't call screen object

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/29/89	Initial version
	Eric	9/24/90		Since we are sending a method to another
				thread, it is a bad idea to pass a pointer
				into [auxBuf]. I will send on stack or in
				a block on the heap instead.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateScreen	proc	near	
EC <	call	ECCheckDS_ES_dgroup					>

	push	ds, ax, bx, cx

	;decide whether to pass characters on the stack, or using a
	;block on the global heap

	mov	si, es:[fileHead]	;set ds:si = start of buffer of chars
	mov	dx, es:[unParseBufNum]	;pass #chars in buffer

	;
	; Don't ever pass 0 characters on to the rest of the app,
	; as there is lots of code that assumes a non-0 length
	; buffer.
	;
	tst	dx
	jz	finishUp

	cmp	dx, MAX_NUM_CHARS_PASSED_ON_STACK
	jg	passAsBlock

passOnStack:
	ForceRef passOnStack

	;we can pass this data on the stack (ObjMessage will transfer data
	;to other thread's stack)
	;	ds:si	= buffer of characters
	;	dx	= size of buffer

EC <	mov	ax, 0xED		;place a dummy char on stack	>
EC <	push	ax							>

	;
	; For reason why these EC code of stack data ID is disabled, see
	; comments in ScreenData::readFromStack
	;
if ERROR_CHECK
	push	es:[fsmStackDataID]	;push ID # for this method
	inc	es:[fsmStackDataID]	;prepare for next
endif
	

	mov	cx, dx			;set cx = number of characters
DBCS <	shl	dx, 1			;# chars -> # bytes		>
	sub	sp, dx			;make room for data on stack
	segmov	es, ss, bx		;set es:di = destination on stack
	mov	di, sp
	mov	bp, sp			;must pass ss:bp = data on stack
SBCS <	rep	movsb			;move data to stack		>
DBCS <	rep	movsw			;move data to stack		>

	;pass dx = number of bytes passed on stack
	;pass cx = 0 (meaning data passed on stack)
	;pass ss:bp = data on stack

EC <	tst	cx							>
EC <	ERROR_NZ TERM_ERROR						>
	;
	; For reason why these EC code of stack data ID is disabled, see
	; comments in ScreenData::readFromStack
	;
EC <	add	dx, 2			;allow room for ID		>

	;
	; Responder: scrDisplaySem semaphore is needed for prevent messing
	; with local echo of international characters
	;
NRSP <	mov	ax, MSG_SCR_DATA					>
RSP <	mov	ax, MSG_SCR_DISPLAY_DATA_FROM_REMOTE			>
	mov	bx, ds:[termuiHandle]	;set ^lbx:si = screen object
	mov	si, offset screenObject

if	_MODEM_STATUS
	mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
else
	mov	di, mask MF_CALL or mask MF_STACK
endif
	call	ObjMessage		;DOES NOT TRASH DX!
	add	sp, dx			;clean up stack

EC <	pop	ax			;make sure stack is lined up again>
EC <	cmp	ax, 0xED						>
EC <	ERROR_NE TERM_ERROR						>
	
	segmov	es, ds, ax		;restore es = ds (may have changed)
	jmp	short finishUp

passAsBlock:
	;we have too many characters to pass on the stack; stuff them into
	;a block on the global heap. This block will later be freed when
	;the characters are read out of it.
	;	ds:si	= buffer of characters
	;	dx	= size of buffer (# chars)

	mov	ax, dx			;pass ax = size of block to allocate
DBCS <	shl	ax, 1			;# chars -> # bytes		>
	mov	cx, ((mask HAF_LOCK or mask HAF_NO_ERR) shl 8) or \
					mask HF_SWAPABLE
					;allocate a swappable block and lock it
	call	MemAlloc		;returns bx = handle, ax = segment
	mov	es, ax			;set es:di = block
	clr	di
	mov	cx, dx			;cx = number of chars to copy
SBCS <	rep	movsb			;move data to block		>
DBCS <	rep	movsw			;move data to block		>
	call	MemUnlock		;unlock block so can move on heap

DBCS <	shl	dx, 1			;# chars -> # bytes		>

	;pass dx = number of bytes passed in block
	;pass cx = handle of block

	mov	cx, bx			;set cx = handle

NRSP <	mov	ax, MSG_SCR_DATA					>
RSP <	mov	ax, MSG_SCR_DISPLAY_DATA_FROM_REMOTE			>
	mov	bx, ds:[termuiHandle]	;set ^lbx:si = screen object
	mov	si, offset screenObject
	
if	not _TELNET
if	_MODEM_STATUS
	;
	; When we send modem command, it can echo back. At this point,
	; TermClass is waiting for serial thread's response. So, we don't
	; want to block here and use FORCE_QUEUE instead. However, we don't
	; want to have allocate so many data blocks and force queue before
	; ScreenClass can consume. So, we want to keep it a call to
	; ScreenData after connection.
 	;
	BitTest	ds:[statusFlags], TSF_SERIAL_MAY_BLOCK
	jnz	callDataDisplay
	mov	di, mask MF_FORCE_QUEUE
	jmp	sendDataDisplay
callDataDisplay:
endif	; _MODEM_STATUS
endif	; !_TELNET
	
  	mov	di, mask MF_CALL
sendDataDisplay::
	call	ObjMessage		;DOES NOT TRASH DX!
	segmov	es, ds, ax		;restore es = ds (may have changed)

finishUp:
	mov	cx, es:[unParseBufNum]
DBCS <	shl	cx, 1			;char offset -> byte offset	>
	add	es:[fileHead], cx	;advance file ptr
	clr	es:[unParseBufNum]
	pop	ds, ax, bx, cx
	ret
UpdateScreen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSMParseStrInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init variables used for parsing strings


CALLED BY:	FSMParseDesc

PASS:		es	- dgroup	

RETURN:		---

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/26/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
FSMParseStrInit proc	near	
	uses	ax, cx, di
	.enter
	mov	es:[fsmLocked], FALSE		;initially fsm block not locked
	mov	es:[inNumFlag], FALSE		;initially not parsing num
	clr	es:[argNum]
	;
	; Initialize argArray to zeros
	;
	CheckHack <DEFAULT_ARGARRAY_ARG_VALUE eq 0>
	clr	al				; default arg value is zero
	mov	cx, size argArray
	mov	di, offset argArray
	rep	stosb				; zero off argArray
	.leave
	ret
FSMParseStrInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReusePrevAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	reuse the previous action desc


CALLED BY:	SetExternalFunc

PASS:		es	- dgroup	

RETURN:		---

DESTROYED:	

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
ReusePrevAD proc	near	
	sub	es:[curACoffset], FUNC_DESC_SIZE
	ret
ReusePrevAD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the termcap file for boolean flags to set


CALLED BY:	FSMAugmentDesc

PASS:		bx		- FSM machine token	
		bx:curHandle	- handle to current state
		es		- dgroup
		es:[fileEnd]	- points to end of buffer
		es:[fileHead]	- points to place to read from buffer
		ds		- buffer segment

RETURN:		---

DESTROYED:	

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/29/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
ProcessFlags proc	near	
	push	bx				;save fsmToken
	call	InitFlags
	call	GetFlags
	pop	bx
	ret
ProcessFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the termcap file for boolean flags to set


CALLED BY:	FSMAugmentDesc

PASS:		bx		- FSM machine token	
		bx:curHandle	- handle to current state
		es		- dgroup
		es:[fileEnd]	- points to end of buffer
		es:[fileHead]	- points to place to read from buffer
		ds		- buffer segment

RETURN:		---

DESTROYED:	

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/29/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
GetFlags proc	near	
	cmp	{byte}ds:[si], START_FLAG	;set boolean flags?
	jne	exit				;nope
getFlag:
	inc	si				;point to start of flag
	mov	ax, ds:[si]			;get flag to scan for
	xchg	ah, al
	mov	cx, FSMFlagTableEnd-FSMFlagTable;get length of table
	push	es
	segmov	es, cs				; es:di = flag table
	mov	di, offset FSMFlagTable
	repne	scasw				;scan for boolean flag
	pop	es
	jz	next				;flag not found
						;di points one past found entry
						;  so get offset from start of  
						;  table of entry
	sub	di, offset FSMFlagTable+(FLAG_SIZE*2)	
						;  start of table		
	add	di, offset FSMFlagMethodTable
	mov	dh, TRUE
	mov	ax, cs:[di]			; ax = method for flag found
	push	si
	mov	bx, es:[termuiHandle]
	CallScreenObj
	pop	si
next:
	add	si, FLAG_SIZE 
	cmp	{byte}ds:[si], START_FLAG
	je	getFlag
getEOLN:
	cmp	{byte} ds:[si], CHAR_LF
	je	eoln
	inc	si
	jmp	short getEOLN
eoln:
	inc	si			;inc past eoln
exit:
	ret
GetFlags	endp

FSMFlagMethodTable	label	word
	dw	MSG_SCR_SET_XN		
FSMFlagMethodTableEnd	label	word

FSMFlagTable	label	word
	dw	"xn"
FSMFlagTableEnd	label 	word


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset terminal flags in screen object

CALLED BY:	ProcessFlags

PASS:		es		- dgroup

RETURN:		---

DESTROYED:	

PSEUDO CODE/STRATEGY:
	Set all the flags to FALSE

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/29/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
InitFlags proc	near	
						;get size of table
	mov	cx, (FSMFlagMethodTableEnd-FSMFlagMethodTable)/2
	mov	dh, FALSE			;set default value
	mov	di, offset FSMFlagMethodTable
resetNext:
	push	si, di
	mov	ax, cs:[di]			; ax = method
	mov	bx, es:[termuiHandle]
	CallScreenObj
	pop	si, di
	add	di, 2				;go to next method to set
	loop	resetNext
	ret
InitFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StripHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset terminal flags in screen object

CALLED BY:	ProcessFlags

PASS:		es		- dgroup
		ds:si		- termcap buffer
RETURN:		---

DESTROYED:	

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This is lame I only check if the comment exists on the very first	
	line and if so then I ignore it.  Why don't I check for the comment
	at the start of every line?, because I'm a lazy dork

	Didn't use scasb, cause didn't want to save es and di somewhere,
	besides this isn't used much

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/29/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
StripHeader proc	near	
	cmp	{byte}ds:[si], COMMENT_FLAG
	jne	exit
getEOLN:
	inc	si
	cmp	{byte}ds:[si], CHAR_LF
	je	eoln	
	jmp	short getEOLN
eoln:
	inc	si				;advance past eoln
exit:
	ret
StripHeader	endp
