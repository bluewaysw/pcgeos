COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	GeoComm
MODULE:		Serial
FILE:		serialScript.asm

AUTHOR:		Eric E. Del Sesto, October 1990

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc      9/6/89		Initial revision.
	eric	9/90		documentation update

DESCRIPTION:
	This file contains code which is run by the Serial thread when
	it is in script mode. Eventually, this script code will become an
	object which is run by the Serial thread. Until then, let's make
	sure that we keep our instance data separated from everyone elses,
	and that the calls into and out of these routines are clearly marked.

	$Id: serialScript.asm,v 1.1 97/04/04 16:55:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialEnterScriptMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method is sent by the Term thread when the user asks
		that a specific script be executed.

CALLED BY:	MSG_SERIAL_ENTER_SCRIPT_MODE

PASS:		ds	- dgroup		

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eric	10/90		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialEnterScriptMode	method	SerialReaderClass, \
					MSG_SERIAL_ENTER_SCRIPT_MODE

EC <	call	ECCheckDS_dgroup					>

	;make sure that we are in the "NORMAL" state: normal terminal
	;emulation or file xfer.

EC <	cmp	ds:[serialThreadMode], STM_NORMAL			>
EC <	ERROR_NE TERM_ERROR						>

	;now initialize some variables we will use while scanning input

	mov	ds:[restartFlag], FALSE		;initialize restart flag
	mov	ds:[inputLineTooLong], FALSE	;initialize flag

	mov	dx, offset dgroup:inputLine 
	mov	ds:[inputHead], dx

	;now redirect input to the script code in this thread
	;(This work used to be done by the Term thread. Doing it here
	;is more synchronous.)

	mov	ax, offset ScriptInput
	GetResourceHandleNS Serial, bx

	PSem	ds, inputDirectionSem	;block if Thread 0 is in the middle
					;of dorking with variables

	mov	ds:[termStatus], IN_SCRIPT
	mov	ds:[routineOffset], ax
	mov	ds:[routineHandle], bx
	VSem	ds, inputDirectionSem	;block if Thread 0 is in the middle

	;misc work

if EC_TRACE_BUFFER
	push	ax, di, cx, es

	segmov	es, ds
	mov	di, offset dgroup:dorkBuffer
	mov	ds:[dorkPtr], di
	mov	cx, SIZE_DORK_BUFFER
	clr	ax
	rep	stosb

	pop	ax, di, cx, es
endif

	FALL_THRU SerialEnterScriptSuspendMode
SerialEnterScriptMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialEnterScriptSuspendMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure is called in the following cases:

		1) the Term object begins to execute a script, and sends
		us a MSG_SERIAL_ENTER_SCRIPT_MODE method.

		2) we exit PROMPT mode, due to timeout. The Term object will
		send us MSG_SERIAL_ENTER_SCRIPT_SUSPEND_MODE.

		3) we exit PROMPT mode, due to finding a match in the input
		stream. We will be called directly by XXXXXXXXXXXX.

		4) we exit PAUSE mode, due to timeout. The Term object will
		send us MSG_SERIAL_ENTER_SCRIPT_SUSPEND_MODE.

		in all of these cases, we are moving to the SUSPEND state
		on the GeoComm Serial Thread state diagram.

CALLED BY:	see above.

PASS:		ds	- dgroup		

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eric	10/90		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialEnterScriptSuspendMode	method	SerialReaderClass, \
					MSG_SERIAL_ENTER_SCRIPT_SUSPEND_MODE

EC <	call	ECCheckDS_dgroup					>

	;we can't assert that we are not already in SUSPEND mode here,
	;because we may have just found a match, placing us in SUSPEND mode,
	;and then the Term object gets a timeout from the same PROMPT period.

	mov	ds:[serialThreadMode], STM_SCRIPT_SUSPEND
	ret
SerialEnterScriptSuspendMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialExitScriptMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	MSG_SERIAL_EXIT_SCRIPT_MODE

SYNOPSIS:	This method is sent by the Term thread when it encounters
		and END statement or error in the script, or when the
		user cancels the script.

PASS:		ds	- dgroup		

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eric	10/90		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialExitScriptMode	method	SerialReaderClass, \
					MSG_SERIAL_EXIT_SCRIPT_MODE
EC <	call	ECCheckDS_dgroup					>

	;we cannot assert anything here, since we might be in any mode.

	mov	ds:[serialThreadMode], STM_NORMAL

	;send all future input to the FSM

	mov	ax, offset FSMParseString
	mov	bx, ds:[fsmResHandle]

	PSem	ds, inputDirectionSem	;block if Thread 1 is in the middle
					;of dorking with variables

	mov	ds:[termStatus], ON_LINE
	mov	ds:[routineOffset], ax
	mov	ds:[routineHandle], bx
	VSem	ds, inputDirectionSem

	;now re-establish the flow of characters from the host: first
	;empty the auxBuffer of any unprocessed characters, then ask the
	;Stream Driver if it has any more.

	call	SerialFinishReadingData
	ret
SerialExitScriptMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialEnterScriptPromptMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	MSG_SERIAL_ENTER_SCRIPT_PROMPT_MODE

SYNOPSIS:	This method procedure is called when the Term thread
		encounters a PROMPT command in the script. We enter the
		PROMPT mode, scanning the input stream for a match.

PASS:		ds	- dgroup		

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eric	10/90		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialEnterScriptPromptMode	method	SerialReaderClass, \
					MSG_SERIAL_ENTER_SCRIPT_PROMPT_MODE

EC <	call	ECCheckDS_dgroup					>

	;make sure that we are not getting screwy orders

EC <	cmp	ds:[serialThreadMode], STM_SCRIPT_PROMPT		>
EC <	ERROR_E TERM_ERROR						>

	mov	ds:[serialThreadMode], STM_SCRIPT_PROMPT

	;now re-establish the flow of characters from the host: first
	;empty the auxBuffer of any unprocessed characters, then ask the
	;Stream Driver if it has any more.

	call	SerialFinishReadingData
	ret
SerialEnterScriptPromptMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialEnterScriptPauseMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	MSG_SERIAL_ENTER_SCRIPT_PAUSE_MODE

SYNOPSIS:	This method procedure is called when the Term thread
		encounters a PAUSE command in the script.

PASS:		ds	- dgroup		

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eric	10/90		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialEnterScriptPauseMode	method	SerialReaderClass, \
					MSG_SERIAL_ENTER_SCRIPT_PAUSE_MODE

EC <	call	ECCheckDS_dgroup					>

	;make sure we are not getting screwy orders

EC <	cmp	ds:[serialThreadMode], STM_SCRIPT_PAUSE			>
EC <	ERROR_E TERM_ERROR						>

	mov	ds:[serialThreadMode], STM_SCRIPT_PAUSE

	;now re-establish the flow of characters from the host: first
	;empty the auxBuffer of any unprocessed characters, then ask the
	;Stream Driver if it has any more.

	call	SerialFinishReadingData
	ret
SerialEnterScriptPauseMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScriptInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       This procedure is called when SerialReadData has received
		a buffer of characters from the Stream Driver, and we are
		in SCRIPT mode.

CALLED BY:      SerialReadData (Serial/serialMain.asm)

PASS:		ds, es	- dgroup
		es:[auxBuf]	= buffer of unprocessed characters (may also
				contain some older processed characters,
				if we suspended input, and are now allowing
				input to continue)
		es:[auxHead]	= pointer to start of unprocessed chars in auxBf
		es:[auxNumChars]	= number of unprocessed chars in auxBuf

		if the last line we scanned from auxBuf to inputLine was
		incomplete (no CR), then:

		ds:[inputLine]	= the beginning of that line
		ds:[inputHead]	= pointer to tail of line in buffer (can append
				to line using this pointer)

		if the last line we scanned from auxBuf into inputLine
		was too long to fit into inputLine, then:

		ds:[inputLine]	= the most recently scanned portion of the 
				long line (we scan it in 128 byte chunks;
				we don't look for matches after the first chunk)

		ds:[inputHead]	= don't care
		ds:[inputLineTooLong] = TRUE

		(characters in BBS code page)

RETURN:		ds, es		= dgroup
		cx		= number of unprocessed chars in [auxBuf]
				(this will be the same as auxNumChars on exit)

		if [inputLineTooLong] was TRUE on entry to this routine:
			if we reached the end of the line (found CR):

				ds:[inputLineTooLong] = FALSE

			else, we simply scanned another 128-byte chunk of the
			long line.

				ds:[inputLineTooLong] = TRUE

		else, if the line we scanned from auxBuf to inputLine was
		incomplete (no CR), then:

		ds:[inputLine]	= the beginning of that line
		ds:[inputHead]	= pointer to tail of line in buffer (can append
				to line using this pointer)
		ds:[lineTooLong] = FALSE

DESTROYED: 

PSEUDO CODE/STRATEGY:
	We have a buffer full of characters and want to allow the
	script routines to check if the input matches any of its MATCH strings.
	We want to pass the input off to the FSM as fast as we can so that
	the screen is updated and appears synchronous with the progress of the
	macro script.  


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/08/90	Initial version
	eric	9/90		doc update (so sue me!)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScriptInput	proc	far
EC <	call	ECCheckDS_ES_dgroup					>
EC <	call	ECCheckRunBySerialThread				>

	;first save info on the input buffer (auxBuffer), so that we can
	;update as we go

	mov	si, es:[auxHead]	;point to start of unprocessed chars
	mov	cx, es:[auxNumChars]	;get number of unprocessed chars

	;check current script mode

	cmp	es:[serialThreadMode], STM_SCRIPT_PROMPT ;looking for a match?
	je	getLine				;skip if so...

	;we are in STM_SCRIPT_PROMPT or STM_SCRIPT_NORMAL mode: allow input
	;to flow straight through to the FSM.

	clr	es:[auxNumChars]	;indicate buffer has been processed.
	jmp	doFSM

getLine:
	;while we have unprocessed characters in [auxBuf]:
	;copy up to one line of input from [auxBuf] to the remaining space
	;in [inputLine].
	;
	;Pass:		ds:si		= pointer to characters in [auxBuf]
	;		es:[auxHead]	= pointer to characters in [auxBuf]
	;		es:[auxNumChars]= number of unprocessed chars remaining
	;
	;		es:[inputLine]	= may contain 1/2 of last line from last
	;				read of auxBuf.
	;		es:[inputLineTooLong] = TRUE if we are in the process
	;				if scanning a very long input line.
	;
	;Returns:	ds:si		= same (for use by FSM...)
	;		es:[auxHead]	= updated (moved past processed chars)
	;		es:[auxNumChars]= updated (does not count processed ch.)
	;
	;		es:[inputLine]	= may contain 1/2 of last line from this
	;				auxBuf read.
	;		es:[checkInputLineForMatch] = TRUE if we should compare
	;				the [inputLine] buffer against the
	;				match table.
	;		es:[resetInput]	= TRUE if we should throw out
	;				the [inputLine] buffer contents
	;				(after match search if any).
	;		es:[inputLineTooLong] = updated to FALSE, if reached
	;				end of long line.

	call	GetInput

haveInputLine:
	ForceRef haveInputLine

EC <	call	ECCheckDS_ES_dgroup					>

	push	ds, si, cx		;save pointer to auxBuf

	;first see if we want to compare [inputLine] to the match table.

	tst	es:[checkInputLineForMatch]
	jz	checkForResetInput	;skip if not...

checkForMatch:
	;now compare [inputLine] to the list of match strings in matchTable
	;If finds a match, with set restartScript = TRUE, which means that
	;we want to suspend input scanning RIGHT WHERE WE ARE, in auxBuf.
	;(It will also set resetInput = TRUE, so that the rest of the line
	;is not searched for matches.)

if EC_TRACE_BUFFER
	call	CopyToDorkBuffer
endif

	call	CheckInput		;may return bx = offset into script

	mov	es:[checkInputLineForMatch], FALSE

checkForResetInput:
	;see if we want to reset our pointer into [inputLine]. (If buffer
	;contains only a portion of a line, we will pass it onto the FSM
	;now, and will keep the chars in [inputLine], so that we can append
	;to the end of the buffer when more chars arrive.

	tst	es:[resetInput]
	jz	afterResetInput		;skip if have incomplete line...

	;reset to the beginning of the [inputLine] buffer

	mov	dx, offset dgroup:inputLine 
	mov	es:[inputHead], dx

	mov	es:[resetInput], FALSE

if ERROR_CHECK
	mov	cx, MAX_LINE_CHARS
	mov	di, dx
	mov	al, 0
	rep stosb
endif

afterResetInput:
	pop	ds, si, cx

doFSM:	;now allow the FSM to process this data from auxBuf
	;pass:	ds:si	= pointer to characters (in auxBuf)
	;	cx	= number of characters to process

	push	bx			;save offset to GOTO
	CallMod	FSMParseString
	pop	cx

	tst	es:[restartFlag]	;did we find a match?
	jnz	restartScriptUsingGOTO	;skip if so...

	;on to the next line of input, in auxBuf.

	tst	es:[auxNumChars]	;are there any left?
	jnz	getLine			;loop if so...
	jz	exit			;skip if not...

restartScriptUsingGOTO:
	;we found a match: hold up serial input while we are executing,
	;to allow script to set up next MATCH, etc. When script reaches
	;a PAUSE, PROMPT, or END command, it will call this routine
	;(ScriptInput) again, to process the rest of auxBuf. If auxBuf
	;is empty, it will call SerialContinueInput, to allow more data
	;from the Stream Driver to be brought into auxBuf.
	;pass:	cx = offset to GOTO command in script.

	clr	es:[restartFlag]	;reset flag for next time

	call	SerialRestartScriptUsingGoto

	;now exit, leaving auxHead and auxNumChars as info about where
	;to continue when reach PROMPT or PAUSE command.

exit:	;exit with cx=number of unprocessed chars

	mov	cx, ds:[auxNumChars]
	ret
ScriptInput	endp

if EC_TRACE_BUFFER
;pass:	ds:si	= pointer to characters (in auxBuf)
;	cx	= number of characters to process

CopyToDorkBuffer	proc	near
	push	ax, cx, si, di, es, ds

	mov	si, offset dgroup:inputLine	;ds:si = inputLine
	mov	cx, 16				;just 4 for now

	segmov	es, ds
	mov	di, ds:[dorkPtr]	;set es:di = pointer into buffer
	rep movsb
	mov	ds:[dorkPtr], di

	pop	ax, cx, si, di, es, ds
	ret
CopyToDorkBuffer	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetInput		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy up to one line of characters from the
		"auxBuf" (buffers raw data from serial driver) into
		the remaining space in "inputBuffer" (holds a complete line,
		if possible), so that we can compare this line (as it
		gets build, character by character) against our match strings.

CALLED BY:      ScriptInput

PASS:		ds, es		= dgroup
		ds:[auxHead]	= pointer to chars inside auxBuf. We move this
				pointer forwards after we grab a line from
				the auxBuf.
		ds:[auxNumChars] = number of chars remaining in auxBuf.

		ds:[inputLineTooLong] = TRUE if we are in the process of
				scanning a very long input line.

		if the last call to this routine left the beginning of a line
		in the [inputLine] buffer, then:

		ds:[inputLine]	= the beginning of that line
		ds:[inputHead]	= pointer to tail of line in buffer (can append
				to line using this pointer)

RETURN:		ds, es		= same (dgroup)
		ds:si		= pointer to start of processed chars in
				[auxBuf]
		cx		= number of processed chars in [auxBuf],
				starting with ds:si. This info is used by the
				FSM to determine what to process.

		ds:[auxHead]	- moved forwards in auxBuf
		ds:[auxNumChars] - number of remaining chars in auxBuf
		
		ds:[inputLineTooLong] = updated to FALSE if reached end of
				very long line.

		if we are leaving with a full line in the [inputLine] buffer:

		es:[resetInput]	- TRUE if [inputLine] buffer contains a full
				line, ending in a CR and then null-terminated.

		otherwise: we return info so can later append to the buffer

		ds:[inputLine]	= the beginning of line
		ds:[inputHead]	= pointer to tail of line in buffer (can append
				to line using this pointer)

DESTROYED: 	

PSEUDO CODE/STRATEGY:
	cx = minimum of (num chars in [auxBuf], num unused bytes in [inputLine])
	scan forwards cx characters in auxBuf, starting at [auxBuf+auxHead],
	    to find end of line (CR).
	if found {
	    /* we have reached the end of a line */
	    append line to [inputLine] buffer.
	    resetInput = TRUE
	    if inputLineTooLong = FALSE {
		/* we have reached the end of a typical line */
		checkInputLineForMatch = TRUE
	    } else {
		/* have reached end of very long line */
		inputLineTooLong = FALSE
	    }
	} else {
	    append CX bytes of auxBuf to inputBuf
	    if cx = num unused bytes in [inputLine] {
		/* we have filled up inputLine with chars. *\
		resetInput = TRUE
		if inputLineTooLong = FALSE {
		    /* we have read the beginning of a very long line */
		    inputLineTooLong = TRUE
		    checkInputLineForMatch = TRUE
		}
	    } else {
		/* we have appended to the end of [inputLine] */
		checkInputLineForMatch = TRUE
	    }   
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	there are no bugs!

REVISION HISTORY:

	Name    Date            Description
	----    --------	-----------
	dennis   2/14/90	Initial version
	eric	9/90		full rewrite. Nice try, Dennis.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetInput	proc	near
if ERROR_CHECK
	call	ECCheckDS_ES_dgroup
	mov	es:[inputLineSafety], INPUT_LINE_BUFFER_SAFETY_BYTE

	tst	es:[resetInput]
	ERROR_NZ TERM_ERROR

	tst	es:[checkInputLineForMatch]
	ERROR_NZ TERM_ERROR
endif

	;see how much room is left in the [inputLine] buffer

	clr	bl			;flag: we have not filled [inputLine]

	mov	ax, offset dgroup:inputLine	;get offset to start of buffer
	add	ax, MAX_LINE_CHARS-1		;get to end of buffer (allow for
						;fact that we will add a null-
						;terminator at end of buffer)

	sub	ax, es:[inputHead]		;find number of unused bytes

	;set es:di = unprocessed characters in [auxBuf]
	;set cx = number of unprocessed characters in [auxBuf]

	mov	cx, es:[auxNumChars]
	mov	di, es:[auxHead]
	mov	si, di			;set ds:si = [auxBuf]
	push	si			;save pointer for later use by FSM

	;IMPORTANT: to prevent buffer overflows...
	;set cx = MIN (num chars in auxBuf, num unused bytes in inputLine buf)

	cmp	cx, ax
	jle	10$			;skip if auxBuf string is short...

	;only copy as many characters as we can safely append to the
	;[inputLine] buffer, then force the line to be evaluated, as if
	;it were a complete line from the host. YES, this means that
	;the match string may not be found, because we are effectively
	;breaking the line in two pieces.

	mov	cx, ax			;set cx = remaining room in inputLine
	mov	bl, TRUE		;flag: we will completely fill up
					;the [inputLine] buffer, IF we do
					;not reach a CR in time.

10$:	;scan es:di for CR (find end of a line)

	mov	al, CHAR_CR		;search input buffer for line of text
	repne	scasb

	pushf
	mov	cx, di			;determine how far we searched
	sub	cx, si			;whether successful or not
	popf

	jnz	noEOL			;skip if did not find CR in
					;entire line (just copy the line,
					;will append more text to it later
					;when we receive more chars)...

	;we found a CR somewhere in the line, and we know that the line
	;is short enough to be copied to (or appended to) [inputLine].

	mov	es:[resetInput], TRUE	;flag end of input line

	tst	es:[inputLineTooLong]
	jnz	20$			;skip if so...

	mov	es:[checkInputLineForMatch], TRUE
	jmp	short copyInput

20$:	;we have been scanning a line which is too long, and have just found
	;the ending CR. Do not check this portion of the line for a match;
	;just reset our flag.

	mov	es:[inputLineTooLong], FALSE
	jmp	short copyInput


noEOL:	;we did not find a CR in the amount of [auxBuf] that we can safely
	;read into [inputLine].

	tst	bl			;will we fill up [inputLine]?
	jnz	filledInputLineBuffer

	;we are about to append a few more chars to [inputLine]. Make sure
	;that we check the new [inputLine] against the match table,
	;so that we don't miss match strings like "login:".

	mov	es:[checkInputLineForMatch], TRUE
	jmp	short copyInput		;skip to copy chars...

filledInputLineBuffer:
	;we will fill [inputLine] to the very end.

	mov	es:[resetInput], TRUE

	tst	es:[inputLineTooLong]	;are we in the middle of a long line?
	jnz	copyInput		;skip if so...

	;we have just read the beginning of what looks like a very long line.
	;Check this portion of the line for a match.

	mov	es:[inputLineTooLong], TRUE
	mov	es:[checkInputLineForMatch], TRUE

copyInput:
	;copy from [auxBuf+auxHead] to [inputLine+inputHead].

	mov	si, es:[auxHead]	;set ds:si = [auxBuf+auxHead]
	mov	di, es:[inputHead]	;set es:di = [inputLine+inputHead]

	mov	dx, cx			;save # chars we will copy
	rep	movsb			;move data until cx=0

	;move the pointers forward past processed data

	mov	es:[auxHead], si	;advance head ptr
	sub	es:[auxNumChars], dx	;update # chars processed
	mov	es:[inputHead], di	;advance head ptr

	mov	{byte} es:[di], CHAR_NULL ;null terminate the input line

	mov	cx, dx			;return cx = number of processed chars
	pop	si			;return ds:si = start of processed
					;data in [auxBuf]
if ERROR_CHECK
	cmp	es:[inputLineSafety], INPUT_LINE_BUFFER_SAFETY_BYTE
	ERROR_NE TERM_ERROR_INPUT_LINE_BUFFER_OVERFLOW_OH_SHIT
endif

	ret
GetInput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Check input for a match in the match table

CALLED BY:      ScriptInput

PASS:         	es	- dgroup

RETURN:		
			
DESTROYED: 

PSEUDO CODE/STRATEGY:
		Check the input line against the match table

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckInput	proc	near

EC <	call	ECCheckES_dgroup					>

	call	CheckMatch			;check for a match
	jc	done				;if no match, dork with input

foundMatch:
	ForceRef foundMatch

	;we found a match! grab pointer to the "GOTO foo" command which
	;was stored with the match string. DO NOT store this directly
	;into the [restartPtr] variable, as we might get a race condition
	;with the Term thread.

	add	si, MATCH_INFO_OFFSET	;get to match info
	mov	bx, ds:[si]		;bx = offset in script where
					;the GOTO command is.

	mov	es:[restartFlag], TRUE	;indicate that we want to
					;restart script elsewhere
	mov	es:[resetInput], TRUE	;and that this line should not
					;be compared for matches again.
done:
	ret
CheckInput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Check the input line for a match against the match table

CALLED BY:      ScriptTimeout, ScriptInput

PASS:		ds	- dsgroup
		es	- dgroup

RETURN:

DESTROYED: 	ax, bx, cx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/09/90	Initial version
	eric	9/90		updated comments

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckMatch	proc	near

EC <	call	ECCheckDS_ES_dgroup					>

	;set ds:si = start of match table. If empty, then abort...

	mov	si, offset dgroup:matchTable	;ds:si -> string to search for
	cmp	si, es:[matchTableHead]		;(if match table empty then
	je	notFound			;	no match)	

if DBCS_PCGEOS	;-------------------------------------------------------------
	;
	; convert input from BBS code page to GEOS code page so we can compare
	; with GEOS code page match strings
	;
EC <	call	ECCheckRunBySerialThread				>
EC <	call	ECCheckDS_ES_dgroup					>
	push	si
	mov	si, offset inputLine		; ds:si = input
	mov	cx, ds:[inputHead]
	sub	cx, si				; cx = # bytes in input
	mov	di, offset convertBuf2		; es:di = convert buffer
	mov	ax, MAPPING_DEFAULT_CHAR
	mov	bx, ds:[bbsRecvCP]
	clr	dx
	call	LocalDosToGeos			; cx = # GEOS chars
	pop	si
	jnc	noErr
	cmp	al, DTGSS_CHARACTER_INCOMPLETE
	je	notFound			; don't even bother comparing
	WARNING	SCRIPT_MATCH_CONVERSION_ERROR
	jmp	short notFound

noErr:
	shl	cx, 1				; # chars -> # bytes
	add	di, cx				; es:di = past last GEOS char
	mov	{wchar} es:[di], CHAR_NULL	; null-terminate
endif	;---------------------------------------------------------------------

strcmp:
SBCS <	mov	di, offset dgroup:inputLine	;es:di->searched string	>
DBCS <	mov	di, offset convertBuf2					>
SBCS <	mov	cx, es:[inputHead]					>
SBCS <	sub	cx, di				;pass size of input (# bytes)>
SBCS <	mov	dl, CHAR_NULL			;pass alt word delimter	>
DBCS <	mov	dx, CHAR_NULL			;pass alt word delimter	>
	call	StringSearch
	jnc	found				;matched the string

getNext:
	inc	si
DBCS <	inc	si							>
SBCS <	cmp	{byte} ds:[si], CHAR_NULL				>
DBCS <	cmp	{wchar} ds:[si], CHAR_NULL				>
	jne	getNext				;go to end of search word

	inc	si
DBCS <	inc	si							>
	clr	bx
	mov	bl, ds:[si]			;get offset to next word
	add	si, bx				;offset to next word	
	cmp	si, ds:[matchTableHead]		;if not at end of table 
	jne	strcmp				;  search for next token

notFound:
	stc					;flag token not found
	jmp	short exit

found:
exit:
	ret
CheckMatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringSearch		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Check if one string is inside another

CALLED BY:      CheckMatch

PASS:         	es:di		- searched string (NOT null terminated)
					(input)
					(SBCS: in BBS code page)
					(DBCS: in GEOS code page)
		ds:si		- pattern to search for   (Null terminated)
					(match table)
					(SBCS: in BBS code page)
					(DBCS: in GEOS code page)
		cx		- size of searched string (es:di) (# bytes)
SBCS <		dl		- word delimeter			>
DBCS <		dx		- word delimeter			>

RETURN:         C		- set if string not found

		C		- clear if string found
		es:di		- points one past where the string was found
					(SBCS only -- not used)
		ds:si		- points one past end of sub string

DESTROYED: 	bp
		di (DBCS)

PSEUDO CODE/STRATEGY:
		Check if substring (macro) is in search string (macro table).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringSearch	proc	far
	uses	cx
	.enter
	add	cx, di				;es:cx = past end of string
						;	to be searched
	mov	bp, si				;save ptr to start of word
nextSub:
SBCS <	mov	al, ds:[si]			;get char of substring	>
DBCS <	mov	ax, ds:[si]			;get char of substring	>
SBCS <	cmp	al, dl				;is substring done	>
DBCS <	cmp	ax, dx				;is substring done	>
	je	done
SBCS <	cmp	al, CHAR_CR						>
DBCS <	cmp	ax, CHAR_CR						>
	je	done
nextSearch:
SBCS <	cmp	al, es:[di]			;do chars match 	>
DBCS <	cmp	ax, es:[di]			;do chars match 	>
	jne	next				;no, 
	inc	di				;adv search sting ptr
DBCS <	inc	di							>
	inc	si				;adv sub string ptr
DBCS <	inc	si							>
	jmp	short nextSub
next:
	cmp	si, bp				;are we inside a comparison
	je	10$				;nope, 
	sub	si, bp				;yes
	sub	di, si				;  reset search string
	mov	si, bp				;  reset sub string
SBCS <	mov	al, ds:[si]			;  get char of substring>
DBCS <	mov	ax, ds:[si]			;  get char of substring>
10$:
	inc	di				;next char of search string
DBCS <	inc	di							>
;	cmp	{byte} es:[di], CHAR_NULL	; is search string done
;this fix allows nulls in string to search (inputLine)
	cmp	di, cx				; at end of search string?
	jne	nextSearch			; nope
	stc
	jmp	short exit
done:
	clc
exit:
	.leave
	ret
StringSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialRestartScriptUsingGoto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Restart script after a PROMPT command

CALLED BY:      ScriptTimeout, ScriptInput

PASS:         	ds, es	- dgroup
		cx	= offset to GOTO command at end of MATCH line
			in script.

RETURN:

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	eric	10/90		nice try, Dennis.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialRestartScriptUsingGoto	proc	far

EC <	call	ECCheckDS_dgroup					>

	;reset pointer to beginning of MATCH table, ready for next list

	push	cx			;save offset to GOTO command
	mov     dx, offset dgroup:matchTable	;reset match table
	mov     ds:[matchTableHead], dx

	;now reset to the SCRIPT_SUSPEND state, so that we hold-up any
	;future input.

	call	SerialEnterScriptSuspendMode

	;now call the Term thread, indicating that it can proceed with script,
	;starting with the GOTO command. Note: if the TIMEOUT method gets to
	;the Term thread first, it will safely ignore this method.

	pop	cx			;pass cx = offset to GOTO command
	mov	ax, MSG_TERM_FOUND_MATCH_CONTINUE_SCRIPT
	mov	bx, ds:[termProcHandle]
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

EC <	call	ECCheckDS_dgroup					>

	segmov	es, ds, bx			;reset es->dgroup
	ret
SerialRestartScriptUsingGoto	endp

