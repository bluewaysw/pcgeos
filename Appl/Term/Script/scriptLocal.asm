COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Script
FILE:		scriptLocal.asm

AUTHOR:		Dennis Chow, January 31, 1990

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc      01/31/90        Initial revision.

DESCRIPTION:
	Internally callable routines for this module.
	No routines inside this file should be called from outside this
	module.
    INT InterpretScriptFile	run the script file

    INT DoCommand		execute next macro command

    INT CheckCommentLabel	ignore comments in script file

    INT GotoNextLine		goto next line

    INT SkipSpaces		skip spaces and tabs in macro file

    INT SkipWhiteSpace		skip spaces and tabs in macro file

    INT CheckCommand		If the command is valid return address of
				command routine

    INT CheckPossibleCommand	If the command is valid return address of
				command routine

    INT DoBell			make a beep noise

    INT DoClear			Clear the script display

    INT DoComm			Set the baud, data and stop bits, and
				parity

    INT DoDial			dial the phone

    INT DoEcho			turn echo on or off

    INT DoEnd			end of script file

    INT DoError			set error flag

    INT DoGoto			goto another line in the script file

    INT DoMatch			add a match string to the match table

    INT DoPause			Suspend the program for a small amount of
				time

    INT DoPort			Set the comm port

    INT DoPrint			print string directly to the screen

    INT DoPrompt		wait for matched character or timeout

    INT DoPulse			set error flag

    INT DoTone			set error flag

    INT SetDialList		set error flag

    INT DoSend			send string out the com port

    INT DoStart			set error flag

    INT DoTerm			set terminal type to use

    INT StringMatch		match the string against the table of valid
				strings

    INT DispErrMessage		display an error message then abort the
				script

    INT StringCheck		Check that the string is bounded by quotes
				(")

    INT StringLength		Get length of the string

    INT LabelSearch		Search the macro file for a label

    INT WordCmp			check if two words match

    INT StringCopyAndConvert	Copy one string to another and convert from
				GEOS->BBS

    INT ConvCharExp		convert character expressions to actual
				character value

    INT ConvNumString		Convert numeric string to hex value

    INT EndScript		Do tasks associated with finishing a script
				file

    INT SetTimer		Set timer to wake up the program

    INT SetDataList		Set entry in data bits list

    INT SetParityList		Set entry in parity list

    INT SetStopList		Set entry in stop bits list

    INT SetDuplexList		Set entry in duplex list

    INT EnableTrigger		enable ScriptUI trigger

    INT DisableTrigger		enable ScriptUI trigger

    INT ScriptAttemptBranchToAbortSection See if this script has an "ABORT"
				section.

    INT PrintAbort		See if this script has an "ABORT" section.

    INT NullTerminateWord	Null terminate the current word

    INT ConvUpperCase		Check that word pointed to by es:di is in
				upper case

    INT ResetScriptTriggers

    INT ScriptCancelAndNotifySerialThread This procedure is called when an
				END command is reached in the script,
				Cancel is pressed, or an error is
				encountered.

	$Id: scriptLocal.asm,v 1.1 97/04/04 16:55:58 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InterpretScriptFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       run the script file 

CALLED BY:      ScriptRunFile

PASS:         	es:di	- current line in script file
		ds	- dgroup
	
RETURN: 	C	- clear if done with script file        
			- set if still in script mode (i.e. SCRIPT_MODE_PROMPT)

DESTROYED: 	es, di

PSEUDO CODE/STRATEGY:
	Should we check if there's an END before the end of the file?

	InterpretScriptFile {
	    if SCRIPT_MODE_OFF {
		EndScript
		return CF=0.
	    } else {
		if SCRIPT_MODE_PROMPT or SCRIPT_MODE_PAUSE {
		    send MSG_SCRIPT_NEXT to [termProcHandle] via queue.
		}
		return CF=1.
	    }
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InterpretScriptFile	proc	near
EC <	call	ECCheckDS_dgroup					>

	call	DoCommand
	cmp	ds:[scriptMode], SCRIPT_MODE_OFF
					;already done?
	je	done			;skip if so...

	cmp	ds:[scriptMode], SCRIPT_MODE_PROMPT
					;waiting for a match?
	je	continue		;skip if so...

	cmp	ds:[scriptMode], SCRIPT_MODE_PAUSE
					;waiting for PAUSE to complete?
	je	continue		;skip if so...

	;ready to process next line of script: send a method to ourself,
	;via the queue so that we allow other events to be handled first.

	mov	ds:[restartPtr], di	;set pointer to next line

	mov	ax, MSG_TERM_SCRIPT_EXECUTE_NEXT_LINE
					;send method to process next lne
	mov	bx, ds:[termProcHandle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

continue:
	stc				;flag script not done
	jmp	short exit

done:
if ERROR_CHECK
	cmp	ds:[scriptMode], SCRIPT_MODE_OFF
	ERROR_NE TERM_ERROR

;IN_SCRIPT is set, but there is a EXIT_SCRIPT_MODE sitting in term:2's
;queue - brianc 2/28/94
;	cmp	ds:[termStatus], IN_SCRIPT
;	ERROR_E TERM_ERROR
99$:
endif


	clc
exit:
	ret
InterpretScriptFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       execute next macro command

CALLED BY:      ScriptRunFile

PASS:         	ds	- dgroup
		es:di	- current line in script file
RETURN:         

DESTROYED: 

PSEUDO CODE/STRATEGY:
		skip labels
		skip comments

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoCommand	proc	near
EC <	call	ECCheckDS_dgroup					>

	call	SkipWhiteSpace

	LocalGetChar	ax, esdi, NO_ADVANCE	;get first char

;added 10/31/90 because I want to go to sleep. -Eric
	LocalIsNull	ax
	jz	done				;skip if reached end of script..
	cmp	di, ds:[scriptEnd]		;if at at end of file
	jge	done				;then end the script...
;end of added code. Let's go to NYC and mug dennis.

	call	CheckCommentLabel		;ignore comments 
	jc	DoCommand			;	and labels
						;call appropriate routine

	call	CheckCommand			;check command is valid 
	jc	error				;exit if token bogus 

	mov	bl, {byte} cs:[si]		;get routine number
	clr	bh
	shl	bx, 1				;calc table offset
	add	bx, offset MacroRoutTable
	mov	cx, cs:[bx]			;get routine offset
	call	cx				;call macro routine
	cmp	di, ds:[scriptEnd]		;if at at end of file
	jb	exit				;then flag that script done
	jmp	short done

error:
	call	PrintAbort			;we are out of here!

done:	;set scriptMode = SCRIPT_MODE_OFF, and notify serial thread
	;that the script has ended.

	call	ScriptCancelAndNotifySerialThread

	;free script block, reset UI, etc.

	call	EndScript			;kill it

exit:
	ret
DoCommand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCommentLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       ignore comments in script file

CALLED BY:      DoCommand

PASS:         	es:di		- current line of script file
		ds		- dgroup
		al		- first char in the line

RETURN: 	C		- set if line is a comment

DESTROYED: 	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckCommentLabel	proc	near
EC <	call	ECCheckDS_dgroup					>

	LocalCmpChar	ax, COMMENT_FLAG	;is this a comment
	je	skip				;yes
	LocalCmpChar	ax, LABEL_FLAG		;is it a label
	je	skip				;no
	LocalCmpChar	ax, CHAR_CR		;skip blank lines
	je	skip
	jmp	short noSkip
skip:
	call	GotoNextLine			;yep, goto next line
	stc
	jmp	short exit
noSkip:
	clc	
exit:
	ret
CheckCommentLabel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GotoNextLine		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       goto next line

CALLED BY:      DoCommand, DoBell, DoComm, DoDial, ...

PASS:         	es:di		- current line of script file

RETURN: 	es:di		- next line in script file

DESTROYED: 	ax	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GotoNextLine	proc	near
	LocalLoadChar	ax, CHAR_LF		;
	mov	cx, LINE_LENGTH			;set max length of line
	LocalFindChar				;goto end of line
	ret
GotoNextLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipSpaces		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       skip spaces and tabs in macro file

CALLED BY:      DoCommand, DoBell, DoComm, DoDial,...

PASS:         	es:di		- current line of script file

RETURN: 	es:di		- pointing to macro text

DESTROYED: 	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SkipSpaces	proc	near
SBCS <	cmp	{byte} es:[di], CHAR_SPACE				>
DBCS <	cmp	{wchar} es:[di], CHAR_SPACE				>
	je	skip
SBCS <	cmp	{byte} es:[di], CHAR_TAB				>
DBCS <	cmp	{wchar} es:[di], CHAR_TAB				>
	je	skip
	jmp	gotText
skip:
	LocalNextChar	esdi
	jmp	short SkipSpaces
gotText:
	ret
SkipSpaces	endp

SkipWhiteSpace	proc	near
SBCS <	cmp	{byte} es:[di], CHAR_SPACE				>
DBCS <	cmp	{wchar} es:[di], CHAR_SPACE				>
	je	skip
SBCS <	cmp	{byte} es:[di], CHAR_TAB				>
DBCS <	cmp	{wchar} es:[di], CHAR_TAB				>
	je	skip
SBCS <	cmp	{byte} es:[di], CHAR_CR					>
DBCS <	cmp	{wchar} es:[di], CHAR_CR				>
	je	skip
SBCS <	cmp	{byte} es:[di], CHAR_LF					>
DBCS <	cmp	{wchar} es:[di], CHAR_LF				>
	jne	gotText
skip:
	LocalNextChar	esdi
	jmp	short SkipWhiteSpace
gotText:
	ret
SkipWhiteSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		String/Macro Tables	

The table format is 

<string_expression><null terminator><#bytes to next string><string data>

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MacroTable	label	byte
if DBCS_PCGEOS
	wchar	"BELL",		CHAR_NULL
		db	2, BELL_PRIM
	wchar	"CLEAR",	CHAR_NULL
		db	2, CLEAR_PRIM
	wchar	"COMM",		CHAR_NULL
		db	2, COMM_PRIM
	wchar	"DIAL",		CHAR_NULL
		db	2, DIAL_PRIM
	wchar	"ECHO",		CHAR_NULL
		db	2, ECHO_PRIM
	wchar	"END",		CHAR_NULL
		db	2, END_PRIM
	wchar	"ERROR",	CHAR_NULL
		db	2, ERROR_PRIM
	wchar	"GOTO",		CHAR_NULL
		db	2, GOTO_PRIM
	wchar	"MATCH",	CHAR_NULL
		db	2, MATCH_PRIM
	wchar	"PAUSE",	CHAR_NULL
		db	2, PAUSE_PRIM
	wchar	"PORT",		CHAR_NULL
		db	2, PORT_PRIM
	wchar	"PRINT",	CHAR_NULL
		db	2, PRINT_PRIM
	wchar	"PROMPT",	CHAR_NULL
		db	2, PROMPT_PRIM
	wchar	"PULSE",	CHAR_NULL
		db	2, PULSE_PRIM
	wchar	"SEND",		CHAR_NULL
		db	2, SEND_PRIM
	wchar	"START",	CHAR_NULL
		db	2, START_PRIM
	wchar	"TERM",		CHAR_NULL
		db	2, TERM_PRIM
	wchar	"TONE",		CHAR_NULL
		db	2, TONE_PRIM
else
	db	"BELL",		CHAR_NULL, 2, BELL_PRIM
	db	"CLEAR",	CHAR_NULL, 2, CLEAR_PRIM
	db	"COMM",		CHAR_NULL, 2, COMM_PRIM
	db	"DIAL",		CHAR_NULL, 2, DIAL_PRIM
	db	"ECHO",		CHAR_NULL, 2, ECHO_PRIM
	db	"END",		CHAR_NULL, 2, END_PRIM
	db	"ERROR",	CHAR_NULL, 2, ERROR_PRIM
	db	"GOTO",		CHAR_NULL, 2, GOTO_PRIM
	db	"MATCH",	CHAR_NULL, 2, MATCH_PRIM
	db	"PAUSE",	CHAR_NULL, 2, PAUSE_PRIM
	db	"PORT",		CHAR_NULL, 2, PORT_PRIM
	db	"PRINT",	CHAR_NULL, 2, PRINT_PRIM
	db	"PROMPT",	CHAR_NULL, 2, PROMPT_PRIM
	db	"PULSE",	CHAR_NULL, 2, PULSE_PRIM
	db	"SEND",		CHAR_NULL, 2, SEND_PRIM
	db	"START",	CHAR_NULL, 2, START_PRIM
	db	"TERM",		CHAR_NULL, 2, TERM_PRIM
	db	"TONE",		CHAR_NULL, 2, TONE_PRIM
endif
MacroTableEnd	label	byte

MAX_MACRO_LENGTH = 6		; set to length longest valid macro command

MacroRoutTable	label	word
	dw	offset	DoBell
	dw	offset	DoClear
	dw	offset	DoComm
	dw	offset	DoDial
	dw	offset	DoEcho
	dw	offset	DoEnd
	dw	offset	DoError
	dw	offset	DoGoto
	dw	offset	DoMatch
	dw	offset	DoPause
	dw	offset	DoPort
	dw	offset	DoPrint
	dw	offset	DoPrompt
	dw	offset	DoPulse
	dw	offset	DoSend
	dw	offset	DoStart
	dw	offset	DoTerm
	dw	offset	DoTone

;
; data bits
;
DataTable	label	byte
if DBCS_PCGEOS
	wchar	"5",	CHAR_NULL
		db	2, FIVE_DATA_BITS
	wchar	"6",	CHAR_NULL
		db	2, SIX_DATA_BITS
	wchar	"7",	CHAR_NULL
		db	2, SEVEN_DATA_BITS
	wchar	"8",	CHAR_NULL
		db	2, EIGHT_DATA_BITS
else
	db	"5",	CHAR_NULL, 2, FIVE_DATA_BITS
	db	"6",	CHAR_NULL, 2, SIX_DATA_BITS
	db	"7",	CHAR_NULL, 2, SEVEN_DATA_BITS
	db	"8",	CHAR_NULL, 2, EIGHT_DATA_BITS
endif
DataTableEnd	label	byte


;
; baud rate
;
BaudTable	label	byte
if DBCS_PCGEOS
	wchar	"300", 	CHAR_NULL 
	db	3
	dw	SB_300
	wchar	"1200", CHAR_NULL
	db	3
	dw	SB_1200
	wchar	"2400", CHAR_NULL
	db	3
	dw	SB_2400
	wchar	"4800", CHAR_NULL
	db	3
	dw	SB_4800
	wchar	"9600", CHAR_NULL
	db	3
	dw	SB_9600
	wchar	"19200",CHAR_NULL
	db	3
	dw	SB_19200
else
	db	"300", 	CHAR_NULL, 3
	dw	SB_300
	db	"1200", CHAR_NULL, 3
	dw	SB_1200
	db	"2400", CHAR_NULL, 3
	dw	SB_2400
	db	"4800", CHAR_NULL, 3
	dw	SB_4800
	db	"9600", CHAR_NULL, 3
	dw	SB_9600
	db	"19200",CHAR_NULL, 3
	dw	SB_19200
endif
BaudTableEnd	label	byte

;
; parity
;
ParityTable	label	byte
if DBCS_PCGEOS
	wchar	"N",	CHAR_NULL
		db	2, NO_PARITY
	wchar	"E",	CHAR_NULL
		db	2, EVEN_PARITY
	wchar	"O",	CHAR_NULL
		db	2, ODD_PARITY
	wchar	"S",	CHAR_NULL
		db	2, SPACE_PARITY
	wchar	"M",	CHAR_NULL
		db	2, MARK_PARITY
else
	db	"N",	CHAR_NULL, 2, NO_PARITY
	db	"E",	CHAR_NULL, 2, EVEN_PARITY
	db	"O",	CHAR_NULL, 2, ODD_PARITY
	db	"S",	CHAR_NULL, 2, SPACE_PARITY
	db	"M",	CHAR_NULL, 2, MARK_PARITY
endif
ParityTableEnd	label	byte

;
; stop bits
;
StopTable	label	byte
if DBCS_PCGEOS
	wchar	"1",	CHAR_NULL
		db	2, ONE_STOP
	wchar	"1.5",	CHAR_NULL
		db	2, ONE_HALF_STOP
	wchar	"2",	CHAR_NULL
		db	2, TWO_STOP
else
	db	"1",	CHAR_NULL, 2, ONE_STOP
	db	"1.5",	CHAR_NULL, 2, ONE_HALF_STOP
	db	"2",	CHAR_NULL, 2, TWO_STOP
endif
StopTableEnd	label	byte

;
; duplex
;
DuplexTable	label	byte
if DBCS_PCGEOS
	wchar	"HALF",	CHAR_NULL
		db	2, TRUE
	wchar	"FULL",	CHAR_NULL
		db	2, FALSE
else
	db	"HALF",	CHAR_NULL, 2, TRUE
	db	"FULL",	CHAR_NULL, 2, FALSE
endif
DuplexTableEnd	label	byte

;
; com port
;
PortTable	label	byte
if DBCS_PCGEOS
	wchar	"1", 	CHAR_NULL
	db	3	
	dw	SERIAL_COM1
	wchar	"2", 	CHAR_NULL
	db	3	
	dw	SERIAL_COM2
	wchar	"3", 	CHAR_NULL
	db	3	
	dw	SERIAL_COM3
	wchar	"4", 	CHAR_NULL
	db	3	
	dw	SERIAL_COM4
else
	db	"1", 	CHAR_NULL, 3	
	dw	SERIAL_COM1
	db	"2", 	CHAR_NULL, 3	
	dw	SERIAL_COM2
	db	"3", 	CHAR_NULL, 3	
	dw	SERIAL_COM3
	db	"4", 	CHAR_NULL, 3	
	dw	SERIAL_COM4
endif
PortTableEnd	label 	byte

;
; this table must match up with TermEntries (in Utils/utilsMain.asm),
;	termcapTable (Main/mainVariable.def), Terminals (termConstant.def)
;
TermTable	label 	byte
if DBCS_PCGEOS
	wchar	"TTY", 		CHAR_NULL
		db	2, TTY
	wchar	"VT52", 	CHAR_NULL
		db	2, VT52
	wchar	"VT100", 	CHAR_NULL
		db	2, VT100
	wchar	"WYSE50", 	CHAR_NULL
		db	2, WYSE50
	wchar	"ANSI", 	CHAR_NULL
		db	2, ANSI
	wchar	"IBM3101", 	CHAR_NULL
		db	2, IBM3101
	wchar	"TVI950", 	CHAR_NULL
		db	2, TVI950
else
	db	"TTY", 		CHAR_NULL, 2, TTY
	db	"VT52", 	CHAR_NULL, 2, VT52
	db	"VT100", 	CHAR_NULL, 2, VT100
	db	"WYSE50", 	CHAR_NULL, 2, WYSE50
	db	"ANSI", 	CHAR_NULL, 2, ANSI
	db	"IBM3101", 	CHAR_NULL, 2, IBM3101
	db	"TVI950", 	CHAR_NULL, 2, TVI950
endif
TermTableEnd	label 	byte

CharTable	label	byte
if DBCS_PCGEOS
	wchar	"CR",	CHAR_NULL
		db	3
		wchar	CHAR_CR
	wchar	"BELL",	CHAR_NULL
		db	3
		wchar	CHAR_BELL
	wchar	"LF",	CHAR_NULL
		db	3
		wchar	CHAR_LF
	wchar	"NULL",	CHAR_NULL
		db	3
		wchar	CHAR_NULL
	wchar	"TAB",	CHAR_NULL
		db	3
		wchar	CHAR_TAB
else
	db	"CR",	CHAR_NULL, 2, CHAR_CR
	db	"BELL",	CHAR_NULL, 2, CHAR_BELL
	db	"LF",	CHAR_NULL, 2, CHAR_LF
	db	"NULL",	CHAR_NULL, 2, CHAR_NULL
	db	"TAB",	CHAR_NULL, 2, CHAR_TAB
endif
CharTableEnd	label 	byte

dialPrefix	db	"ATD"
SBCS <gotoCmd		db	"GOTO "					>
DBCS <gotoCmd		wchar	"GOTO "					>
SBCS <gotoCmd2	db	"goto "		;let's prevent some problems here>
DBCS <gotoCmd2	wchar	"goto "		;let's prevent some problems here>

SBCS <nullStr		db	CHAR_NULL				>
DBCS <nullStr		wchar	CHAR_NULL				>

SBCS <abortLabel	db	"ABORT "				>
DBCS <abortLabel	wchar	"ABORT "				>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCommand		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       If the command is valid return address of command routine

CALLED BY:      DoCommand

PASS:         	es:di		- current line in script file
		ds		- dgroup

RETURN:         C		- set if command not valid

		C		- clear if command okay
		es:di		- points past matched token
		ds:si		- points at routine number to call

DESTROYED: 	bp

PSEUDO CODE/STRATEGY:
		Check if substring (macro) is in search string (macro table).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckCommand	proc	near
	call	SkipSpaces			;skip white space

	mov	si, offset MacroTable		;cs:si -> macroTable
	mov	cx, offset MacroTableEnd	;cs:cx -> end of table

	call	ConvUpperCase			;make command string uppercase

	mov	dx, CHAR_NULL			;alternate word delimiter
	call	StringMatch
	jnc	exit				;skip if found match (cy=0)...

	;this is an illegal macro command. Shove a null-terminator onto the
	;end of it so we can print it in the error dialog box.

	call	NullTerminateWord

	mov     bp, ERR_UNDEF_MACRO
	call	CheckPossibleCommand		;does it contains ONLY printable
	jz	okay				;chars? skip if so...

	;this string is absolute garbage. Don't try to display it.

	mov	bp, ERR_BAD_SCRIPT_MACRO	; generic macro error string

okay:
	call	DispErrMessage
	call	GotoNextLine			;bogus macro, skip it
	stc

exit:
	ret
CheckCommand	endp

; pass:
;	cx:dx = null-term'ed bad command string
; return:
;	C clear if okay

CheckPossibleCommand	proc	near
	uses	ds, si, cx
	.enter
	mov	ds, cx
	mov	si, dx
	mov	cx, MAX_MACRO_LENGTH
checkLoop:
	lodsb
	tst	al				; clears carry flag
	jz	done
	cmp	al, ' '				; don't allow if
	jb	done				;	below a space
						; (JB = JC -- carry set)
	loop	checkLoop
done:
	.leave
	ret
CheckPossibleCommand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoBell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       make a beep noise

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         es:di	- start of next in script file

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoBell	proc	near
	call	GotoNextLine			;bell has no arguments skip to
						;	next line
	push	di				;save ptr to script file
	mov	ax, MSG_SCR_SOUND_BELL	;make bell sound
	mov	bx, ds:[termuiHandle]		;
	CallScreenObj				;call screen object
	pop	di				;
exit:
	ret
DoBell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Clear the script display

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         es:di	- start of next in script file

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   3/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoClear	proc	near
EC <	call	ECCheckDS_dgroup					>

	push	di				;cx = #chars
	clr	cx 				;pass null terminated string
	mov	bx, ds:[scriptDisp].handle
	mov	si, ds:[scriptDisp].chunk
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR		;	
	mov	dx, cs				;
	mov	bp, offset nullStr		;dx:bp->null string
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di				;
	call	GotoNextLine			;skip to the next line
	ret
DoClear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoComm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set the baud, data and stop bits, and parity

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         es:di	- start of next in script file

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoComm	proc	near
	call	SkipSpaces
checkBaud:
	mov	si, offset BaudTable		;cs:si->macroTable
	mov	cx, offset BaudTableEnd		;get length of table
	mov	dx, CHAR_DASH			;alternate word delimiter
	call	StringMatch
	jnc	setBaud

	mov	bp, ERR_UNDEF_BAUD
	jmp	error				;bail on error

setBaud:
	mov	cx, cs:[si]			;get and set the baud rate
	push	di				;save ptr into macro file
	CallMod	SetBaudList
	pop	di

checkData:
	LocalNextChar	esdi			;skip past '-' delimeter
	mov	si, offset DataTable		;cs:si->macroTable
	mov	cx, offset DataTableEnd		;get length of table
	mov	dx, CHAR_DASH			;alternate word delimiter
	call	StringMatch
	jnc	setData

	mov     bp, ERR_UNDEF_DATA
	jmp	error				;bail on error

setData:
	mov	cl, cs:[si]
	mov	ch, mask SF_LENGTH
	call	SetDataList

checkParity:
	LocalNextChar	esdi			;skip to parity
	mov	si, offset ParityTable		;cs:si->table of valid paritys
	mov	cx, offset ParityTableEnd	;get length of table
	mov	dx, CHAR_DASH			;alternate word delimiter
	call	StringMatch
	jnc	setParity

	mov     bp, ERR_UNDEF_PARITY
	jmp	error				;bail on error

setParity:
	mov	cl, cs:[si]			;get parity value
	mov	ch, mask SF_PARITY
	call	SetParityList

checkStop:
	LocalNextChar	esdi			;skip to stop bit value
	mov	si, offset StopTable		;cs:si->stop bit table
	mov	cx, offset StopTableEnd		;get length of table
	mov	dx, CHAR_DASH			;alternate word delimiter
	call	StringMatch
	jnc	setStop

	mov     bp, ERR_UNDEF_STOP
	jmp	short error			;bail on error

setStop:
	mov	cl, cs:[si]			;get stop bit value
	mov	ch, mask SF_EXTRA_STOP
	call	SetStopList

checkDuplex:
	LocalNextChar	esdi			;skip to stop bit value
	mov	si, offset DuplexTable		;cs:si->stop bit table
	mov	cx, offset DuplexTableEnd	;get length of table
	mov	dx, CHAR_DASH			;alternate word delimiter
	call	StringMatch
	jnc	setDuplex

	mov     bp, ERR_UNDEF_DUPLEX
	jmp	short error			;bail on error

setDuplex:
	mov	cl, cs:[si]			;get duplex value
	mov	ds:[halfDuplex], cl
	call	SetDuplexList
done:
	;
	; Send a message to the dialog to apply all the changes
	;
	push	ax, cx, dx, bp, di
	mov	ax, MSG_GEN_APPLY
	GetResourceHandleNS	ProtocolBox, bx
	mov	si, offset ProtocolBox
	clr	di
	call	ObjMessage
	pop	ax, cx, dx, bp, di
	jmp	short	exit			;done	
error:
	call	NullTerminateWord
	call	DispErrMessage
exit:
	call	GotoNextLine
	ret
DoComm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       dial the phone

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         es:di	- start of next in script file

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoDial	proc	near
	call	SkipSpaces			;skip white space

if _SCRIPT_VARIABLE   ;------------------------------------------------------
	push	es, di				; preserve script pointer.
	call	DialVariableCheck		; if variable is not a var,
	jnc	dial_check_string		; then go do standard string
						; check. 

	mov	dx, es				; set target
	mov	bp, di		
	call	GetDialVariable			; is a properly formatted
						; variable.  Now call
						; GetDialVariable to get the
						; string to print out
						; (dial).

	jmp	continue_dialing		; skip over string check
dial_check_string:    
endif ; _SCRIPT_VARIABLE ----------------------------------------------------

	call	StringCheck			;if string malformed
	LONG jnz	exit				;	bail out

if _SCRIPT_VARIABLE
continue_dialing:				; label used by variables
						; that can be dialed
endif ; _SCRIPT_VARIABLE

EC <	call	ECCheckDS_dgroup					>

	mov	ds:[systemErr], FALSE		;reset system error flag
	mov	dx, cx				;save length of phone #
	push	es
	segmov	es, cs, cx
	mov	si, offset dialPrefix		;es:si->string to send
	mov	cx, DIAL_PREFIX_LEN
	CallMod	SendBuffer
	pop	es				;restore es->macro file
	tst	ds:[systemErr]
	jnz	error

	mov	cx, dx				;restore phone # length
	push	cx				;save string length
	tst	ds:[toneDial]	
	jz	pulse

	mov	cl, CHAR_TONE	
	jmp	20$

pulse:
	mov	cl, CHAR_PULSE
20$:
	CallMod	SendChar
	pop	cx				;restore string length
if DBCS_PCGEOS	;-------------------------------------------------------------
	;
	; convert phone number for GEOS Unicode to SBCS via stack buffer
	;	es:di = GEOS phone #
	;	cx = length
	;
	push	es, di				; save script
	mov	dx, ds				; save dgroup
	segmov	ds, es, ax			; ds:si = GEOS phone #
	mov	si, di
	sub	sp, cx
	segmov	es, ss, ax			; es:di = SBCS phone # (stack)
	mov	di, sp
	push	cx, di				; save len, SBCS buffer offset
convertLoop:
	lodsw					; do GEOS -> SBCS conversion
	stosb
	loop	convertLoop
	pop	cx, si				; cx = length, es:si = SBCS
	mov	ds, dx				; ds = dgroup
else	;---------------------------------------------------------------------
	mov	si, di				;es:si->phone # in macro file
endif	;---------------------------------------------------------------------
	CallMod	SendBuffer			;dial the phone number
if DBCS_PCGEOS	;-------------------------------------------------------------
	add	sp, cx				; free stack buffer
	pop	es, di				; es:di = script
endif	;---------------------------------------------------------------------
	mov	cl, CHAR_CR
	CallMod	SendChar
	jmp	short exit

error:
	mov	ds:[systemErr], FALSE
exit:
if _SCRIPT_VARIABLE	;----------------------------------------------------
	pop	es, di		; restore script pointer
endif ; SCRIPT_VARIABLE ;----------------------------------------------------

	call	GotoNextLine
	ret
DoDial	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoEcho
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       turn echo on or off

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         es:di	- start of next in script file

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoEcho	proc	near
exit:
	call	GotoNextLine
	ret
DoEcho	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       end of script file

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:		ds	- dgroup
		es:di	- next line in script file

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoEnd	proc	near

EC <	call	ECCheckDS_dgroup					>

	;indicate that we are no longer processing a script,
	;and send a method to the serial thread, so that it will
	;send all future input to the FSM, first flushing the
	;rest of the characters from auxBuf into the FSM, and then grabbing
	;more chars from the Stream Driver into auxBuf.
	;As these characters come in, we will scan them for the match.
	;When we have read them all, that thread will remain idle until the
	;Stream Driver notifies it that more characters have arrived.

	push	di
	call	ScriptCancelAndNotifySerialThread

	;free script block, reset UI, etc.

	call	EndScript			;kill it
	pop	di

	;now, we return to DoCommand and InterpretScriptFile.

	call	GotoNextLine		;point to next line
	ret
DoEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       set error flag

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoError	proc	near
exit:
	call	GotoNextLine
	ret
DoError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoGoto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       goto another line in the script file

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoGoto	proc	near

EC <	call	ECCheckDS_dgroup					>

	call	SkipSpaces
	cmp	{byte} es:[di], CHAR_CR
	je	noLabel
	mov	cx, ds:[scriptSize]		;pass size of script file
	push	ds
	segmov	ds, es, ax	
	clr	si				;ds:si->start of macro file
	call	LabelSearch
	pop	ds
	jnc	gotoLabel
labelErr:
	call	NullTerminateWord
	mov	bp, ERR_UNDEF_LABEL
	jmp	90$
noLabel:
	mov	bp, ERR_NO_LABEL
90$:
	call	DispErrMessage
	jmp	short exit
gotoLabel:
	mov	di, si				;es:di->cur line in macro file
exit:
	call	GotoNextLine
	ret
DoGoto	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       add a match string to the match table

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

		(script file is in GEOS character set)

RETURN:         

DESTROYED: 

PSEUDO CODE/STRATEGY:
		Add match string to match table
		Append match string with ptr #

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Table is limited size don't allow more than ten match strings
		of fifteen chars each
		Should we flag if they overflow the match table?
		*** Can only MATCH white space terminated tokens

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MATCH_TABLE_END	= (offset dgroup:matchTable)+MATCH_TABLE_SIZE
MATCH_TABLE_LAST_LEGAL_EOS = MATCH_TABLE_END - MATCH_DATA_BYTES - 2

DoMatch	proc	near

EC <	call	ECCheckDS_dgroup					>

	call	SkipSpaces			;skip spaces after "MATCH"

	call	StringCheck			;make sure string is legal,
						;set es:di = start of string
						;sets cx = length of string
	jnz	exit				;skip if not legal...

	;first make sure that there is room in the match table to store this
	;string:

	mov	si, ds:[matchTableHead]		;set ds:si = end of match table

	mov	ax, si
	add	ax, cx				;ds:ax -> where NULL will go
DBCS <	add	ax, cx				;char offset -> byte offset>
	cmp	ax, MATCH_TABLE_LAST_LEGAL_EOS	;past legal end?

	mov	bp, ERR_MATCH_TABLE_FULL	;assume so
	jg	dispErr				;skip if so...

	;now copy this string into the match table

	mov	dh, CHAR_DBL_QUOTE
	call	StringCopyAndConvert		;copy string into match table
						;	AND GEOS->BBS convert
						;DBCS: no conversion
	LocalNextChar	dssi			;move past the null terminator
						;in destination string

	;now write the value 2 into the match table: this indicates how many
	;bytes to skip to the next match table entry.

	mov	{byte} ds:[si], MATCH_DATA_BYTES+1 
	inc	si				;point to string info section

	;in the source string, move past the closing quote, and any white space

	LocalNextChar	esdi			;move past the closing quote (")
	call	SkipSpaces			;error if no GOTO

SBCS <	cmp	{byte} es:[di], CHAR_CR		;must not be at end of line!>
DBCS <	cmp	{wchar} es:[di], CHAR_CR	;must not be at end of line!>
	je	gotoErr				;skip to error if so...

	;now see if we have reached the "GOTO" string on the input line.

	mov	cx, si				;store ptr to info section

	push	ds, di
	segmov	ds, cs, ax			;ds = cs, using ax register
	mov	si, offset gotoCmd 		;check that there is a GOTO cmd
	call	WordCmp				;ds:si -> "GOTO " string
	pop	ds, di				;restore ds -> dgroup
	jnc	storePtr			;skip if no error...

	;now check for lower-case version

	push	ds, di
	segmov	ds, cs, ax			;ds = cx, using ax register
	mov	si, offset gotoCmd2 		;check that there is a GOTO cmd
	call	WordCmp				;ds:si -> "GOTO " string
	pop	ds, di				;restore ds -> dgroup
	jnc	storePtr			;skip if no error...

gotoErr:
	mov	bp, ERR_NO_GOTO

dispErr:
	call	DispErrMessage
	jmp	short exit

storePtr:
	;store the address of the GOTO command in the match table

	call	SkipSpaces			;skip to the label
						;(not necessary)

	mov	si, cx				;restore ptr to info section
	mov	ds:[si], di			;store ptr to label to goto
	add	si, 2				;advance table ptr past label
	mov	ds:[matchTableHead], si		;set ptr to next entry in table
exit:
	call	GotoNextLine
	ret
DoMatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPause
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Suspend the program for a small amount of time

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:		ds	- dgroup
		es:di	- next line in script file

DESTROYED: 

PSEUDO CODE/STRATEGY:
	The argument is in 1/60ths of a second.  So to pause for
	1 second, use 'PAUSE 60'  If no argument, assume pause for
	one second.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/06/90	Initial version
	eric	9/90		added ScriptContinue code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoPause	proc	near

EC <	call	ECCheckDS_dgroup					>

	;first set up the timer. Will return carry set if parse error

	call	SetTimer
	jc	done

	;next, indicate that we are in PAUSE mode (i.e. script execution
	;is suspended, but characters can still come from host and be
	;printed on screen)

	mov	ds:[scriptMode], SCRIPT_MODE_PAUSE	;flag in pause mode

	;now, send a method to the serial thread, so that it will flush the
	;rest of the characters from auxBuf into the FSM, and then grab
	;more chars from the Stream Driver into auxBuf.
	;As these characters come in, we will scan them for the match.
	;When we have read them all, that thread will remain idle until the
	;Stream Driver notifies it that more characters have arrived.

	push	di
	mov	ax, MSG_SERIAL_ENTER_SCRIPT_PAUSE_MODE
	mov	bx, ds:[threadHandle]	;get serial thread handle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage		;prevent deadlock
	pop	di

done:
	ret
DoPause	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set the comm port

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/05/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoPort	proc	near

EC <	call	ECCheckDS_dgroup					>

	call	SkipSpaces
	mov	si, offset PortTable		;cs:si->macroTable
	mov	cx, offset PortTableEnd		;get length of table
	mov	dx, CHAR_NULL			;alternate word delimiter
	call	StringMatch
	jnc	setPort
	call	NullTerminateWord
	mov	bp, ERR_UNDEF_PORT
	call	DispErrMessage
	jmp	short done
setPort:
	mov	cx, cs:[si]			;get port #
	push	di				;save ptr into macro file
	push	cx				; save port number
	;
	; The best thing is probably to disable all codes of Script module in
	; Responder.
	;
NRSP <	CallMod	TermSetPort						>
	pop	ax				; restore port number
	pop	di	
	jcxz	error				;check if com port error
	mov	cx, ax				; cx = port number
	push	di				;save ptr into script file
	CallMod	SetPortList
	pop	di
	jmp	short exit

error:
	call	ScriptAttemptBranchToAbortSection ;if abort section 
	jnc	done				  ;continue script...

	;set scriptMode = SCRIPT_MODE_OFF, and notify serial thread
	;that the script has aborted.

	call	ScriptCancelAndNotifySerialThread
	jmp	short done

exit:
	call	GotoNextLine			;goto next line in macro file

done:
	ret
DoPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       print string directly to the screen

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

		(script file is in GEOS character set)

RETURN:         

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoPrint	proc	near

EC <	call	ECCheckDS_dgroup					>

	call	SkipSpaces			;skip white space
	cmp	{byte} es:[di], CHAR_CR
	je	charErr
	cmp	{byte} es:[di], CHAR_DBL_QUOTE	;is there a string exp?
	jne	convChar			;nope, check for chars
	call	StringCheck
	jnz	error				;	bail
	mov	dx, es
	mov	bp, di				;dx:bp->ascii string
	add	di, cx				;es:di->points at end of string
DBCS <	add	di, cx				;char offset -> byte offset>
printChar:
	LocalNextChar	esdi			;es:di->points past end 
						;	of string
	push	di				;cx = #chars
	mov	bx, ds:[scriptDisp].handle
	mov	si, ds:[scriptDisp].chunk
	mov	ax, MSG_VIS_TEXT_APPEND
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
checkChar:
	call	SkipSpaces			;check if any other chars
	cmp	{byte} es:[di], CHAR_COMMA	;nope
	jne	exit
	LocalNextChar	esdi			;es:di->character expression
	call	SkipSpaces			;skip to the character exp
convChar:
	call	ConvCharExp			;convert the char expression
	jc	charErr
	mov	cx, 1				;cs:si->char value
	mov	dx, cs			
	mov	bp, si				;dx:bp->char to write
	jmp	short printChar
charErr:
	call	NullTerminateWord
	mov	bp, ERR_UNDEF_CHAR
	call	DispErrMessage
exit:
	call	GotoNextLine
error:
	ret
DoPrint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPrompt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       wait for matched character or timeout

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:		ds	- dgroup
		es:di	- next line in script file

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version
	eric	9/90		added ScriptContinue

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoPrompt	proc	near

EC <	call	ECCheckDS_dgroup					>

	;first set up the timer. Will return carry set if parse error

	call	SetTimer
	jc	done

	;next, indicate that we are in MATCH mode (script execution is
	;suspended, and we monitor the input coming from the host)

	mov	ds:[scriptMode], SCRIPT_MODE_PROMPT	;flag in match mode

	;now, send a method to the serial thread, so that it will flush the
	;rest of the characters from auxBuf into the FSM, and then grab
	;more chars from the Stream Driver into auxBuf.
	;As these characters come in, we will scan them for the match.
	;When we have read them all, that thread will remain idle until the
	;Stream Driver notifies it that more characters have arrived.

	push	di
	mov	ax, MSG_SERIAL_ENTER_SCRIPT_PROMPT_MODE
	mov	bx, ds:[threadHandle]		;get driver handle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	di

done:
	ret
DoPrompt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPulse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       set error flag

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	** should have code to flag the toneDial state in the Dialog boxes

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoPulse	proc	near
	mov	cx, TRUE
	call	SetDialList
	call	GotoNextLine
	ret
DoPulse	endp

DoTone	proc	near
	mov	cx, FALSE
	call	SetDialList
	call	GotoNextLine
	ret
DoTone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDialList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       set error flag

CALLED BY:      DoCommand

PASS:         	ax	- method to send
		ds	- droup
		es:di	- pointer into macro file
		cx	- TRUE for Tone, FALSE for Pulse

RETURN:         

DESTROYED: 	ax, bx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   3/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetDialList	proc	near
EC <	call	ECCheckDS_dgroup					>

	push	di				;save macro file pointer
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION	;set the entry
	clr	dx
	GetResourceHandleNS	ModemUI, bx
	mov	si, offset ModemUI:ModemDial
	mov     di, mask MF_CALL
	call    ObjMessage
	pop	di
	ret
SetDialList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       send string out the com port

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

		(script file is in GEOS character set)

RETURN:         

DESTROYED: 

PSEUDO CODE/STRATEGY:
	the syntax is :	SEND <string expression>[,character_expression]
	these strings are all recognized
	SEND    CR
	SEND    "+++"
	SEND    "---",CR

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/06/90	Initial version
	eric	10/16/96	Added variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoSend	proc	near
	call	SkipSpaces
	cmp	{byte} es:[di], CHAR_CR
	LONG je	charErr

if _SCRIPT_VARIABLE
	cmp	{byte} es:[di], CHAR_DOLLAR	; better check to see if
						; DBCS version loword is
						; same.
	jne	string_check_do_send
	call	VariableCheck			; Check to see if variable.
	jnc	string_check_do_send		; If string is not formatted
						; as a variable, send it
						; through to the string
						; check.
	push	ds				; Save segment to script
	mov	bx, segment dgroup
	mov	ds, bx				; set dgroup
	CallMod	BufferedSendBuffer
	pop	ds				; Restore script segment.
	jc	error

	mov	si, di				; return to original
						; position
	mov	cx, dx				; return to original length
						; (of varaible $text$)
	segmov	es, ds				; restore segment of
						; variable. 
	mov	bx, segment dgroup
	mov	ds, bx				; restore dgroup

	jmp	continue_process_do_send
string_check_do_send:
endif	; _SCRIPT_VARIABLE

	cmp	{byte} es:[di], CHAR_DBL_QUOTE	;is there a string exp?
	jne	convChar			;nope, check for chars


	call	StringCheck			;if string malformed
	LONG jnz	error				;	bail
	mov	ss:[systemErr], FALSE		;reset error flag
	mov	si, di				;es:si->string to send
;;	CallMod	SendBuffer			;
;;echo locally in half-duplex mode
;one line only, so this will be synchronously sent - brianc 2/28/94
	call	BufferedSendBuffer
	jc	error				; if error, stop

if _SCRIPT_VARIABLE
continue_process_do_send:
endif ; _SCRIPT_VARIABLE

	add	si, cx				; es:si = points past string
						;	sent
DBCS<	add	si, cx				; char offset -> byte offset>




EC <	call	ECCheckDS_dgroup					>

	tst	ds:[systemErr]
	jnz	error
	mov	di, si				;es->di points to end of string
	LocalNextChar	esdi			;	just sent
checkChar:
	call	SkipSpaces			;check if any other chars
	cmp	{byte} es:[di], CHAR_COMMA	;nope
	jne	exit
	LocalNextChar	esdi			;es:di->character expression
convChar:
	call	ConvCharExp			;convert the char expression
	jc	charErr
if DBCS_PCGEOS	;-------------------------------------------------------------
	;
	; go into single byte mode
	;
	call	SendSingleByteEscape
endif	;----------------------------------------------------------------------
	mov	cl, al				;pass char to send
	; (characters sent are in BBS code page)
	CallMod	SendChar
	;
	; if in half-duplex mode, echo character locally
	;
	cmp	ds:[halfDuplex], TRUE		; half-duplex?
	jne	checkChar			; nope
if DBCS_PCGEOS	;-------------------------------------------------------------
	push	di
	cmp	ds:[bbsRecvCP], CODE_PAGE_JIS_DB
	jne	noStartEscape
	push	cx
	mov	bp, offset singleByteEscape	; to single byte
	mov	cx, 3				; 3 bytes in escape
	call	sendEscape
	pop	cx
noStartEscape:
	mov	ax, MSG_READ_CHAR
	mov	bx, ds:[threadHandle]
	mov	di, mask MF_FORCE_QUEUE		; queue it up
	call	ObjMessage
	cmp	ds:[bbsRecvCP], CODE_PAGE_JIS_DB
	jne	noEndEscape
	push	cx
	mov	bp, offset doubleByteEscape	; back to double byte
	mov	cx, 5				; 3 bytes + null word
	call	sendEscape
	pop	cx
noEndEscape:
	pop	di
else	;---------------------------------------------------------------------
	push	di
	mov	ax, MSG_READ_CHAR
	mov	bx, ds:[threadHandle]
	mov	di, mask MF_FORCE_QUEUE		; queue it up
	call	ObjMessage
	pop	di
endif	;---------------------------------------------------------------------
	jmp	short checkChar
charErr:
	call	NullTerminateWord
	mov	bp, ERR_UNDEF_CHAR
	call	DispErrMessage
error:
	mov	ds:[systemErr], FALSE		;reset error flag
exit:
	call	GotoNextLine
	ret

if DBCS_PCGEOS	;-------------------------------------------------------------
sendEscape	label	near
	mov	ax, MSG_READ_BUFFER
	mov	dx, ds
	mov	bx, ds:[threadHandle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	retn
endif	;---------------------------------------------------------------------
DoSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       set error flag

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoStart	proc	near
exit:
	call	GotoNextLine
	ret
DoStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoTerm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       set terminal type to use

CALLED BY:      DoCommand

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/05/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoTerm	proc	near
	call	SkipSpaces
	mov	si, offset TermTable		;cs:si->macroTable
	mov	cx, offset TermTableEnd		;get end of table
	mov	dx, CHAR_NULL			;alternate word delimiter
	call	StringMatch
	jnc	setTerm
	call	NullTerminateWord
	mov	bp, ERR_UNDEF_TERM
	call	DispErrMessage
	jmp	short exit
setTerm:
	mov	cl, cs:[si]			;get termtype
	mov	ds:[termType], cl
	CallMod	SetTermList			;
exit:
	call	GotoNextLine
	ret
DoTerm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       match the string against the table of valid strings 

CALLED BY:      DoComm, DoTerm, DoPort, ...

PASS:         	es:di	- sub string
		cs:si	- search string
		cx	- length of search string
		dx	- alternate word delimiter

RETURN:        	C	- clear if string found	
		si	- points past the sub string	
		di	- points past the match in the search string

		C	- set if string not found

DESTROYED: 	bp

PSEUDO CODE/STRATEGY:
		check the string against a table of valid strings
		The table is stored in our code segment,
			pass a ptr to the table and do the search

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/05/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringMatch	proc	near
	uses	ds, bx
	.enter
	segmov	ds, cs, ax
	CallMod	TableSearch
	.leave	
	ret
StringMatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DispErrMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       display an error message then abort the script

CALLED BY:      CheckCommand, DoComm, DoTerm, DoPause, ...

PASS:         	ds	- dgroup
		es:di	- current line in macro file
		bp	- number of error string to display

RETURN:        	

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DispErrMessage	proc	near
	push	di
	CallMod DisplayErrorMessage
	pop	di

	call	ScriptAttemptBranchToAbortSection ;if abort section 
	jnc	done				  ;continue script...

EC <	call	ECCheckDS_dgroup					>

	;set scriptMode = SCRIPT_MODE_OFF, and notify serial thread
	;that the script has aborted.

	call	ScriptCancelAndNotifySerialThread

	;free script block, reset UI, etc.

	call	EndScript			;kill it

done:
	ret
DispErrMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Check that the string is bounded by quotes (")

CALLED BY:      DoDial, DoSend

PASS:         	ds	- dgroup
		es:di	- start of quoted string

RETURN:        	Z	- set if string okay
		di	- points to first char inside the quote
		cx	- length of string

		Z 	- clear if string illegal
				error message already posted
			
DESTROYED: 	al, bx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringCheck	proc	near
	mov	bx, di				;save ptr to start of string
	LocalLoadChar	ax, CHAR_DBL_QUOTE
SBCS <	cmp	es:[di], al			;string must be bounded by '"'>
DBCS <	cmp	es:[di], ax			;string must be bounded by '"'>
	jne	strErr				;

	LocalNextChar	esdi			;skip past the '"'
	mov	dx, di				;save ptr to start of string

	call	StringLength			;calls GotoNextLine (!!!)
						;returns cx = number of chars
						;to end of line
						;does not trash al

	LocalFindChar				;search for ending quote
	jnz	strErr				;skip if cannot find it...

	LocalPrevChar	esdi			;point to end of string	
	mov	cx, di				;
	mov	di, dx				;get ptr to start of str
	sub	cx, di				;calc string length
DBCS <	shr	cx, 1				;# bytes -> # chars	>
	cmp	al, al				; set Z flag for return
	jmp	short exit			;	

strErr:						;
	;we have encountered an error in the string: shove a "0" null-terminator
	;into the end of the string, so that we can print it in the error DB.

	mov	di, bx				;set ptr to start of dorked
	call	NullTerminateWord		;	string

	push	ds, si
	mov	ds, cx				;set ds:si = string
	mov	si, dx
SBCS <	cmp	{byte} ds:[si], 0		;null-string?		>
DBCS <	cmp	{wchar} ds:[si], 0		;null-string?		>
	pop	ds, si

	mov	bp, ERR_UNDEF_STR		;assume is UNDEF string
	jne	haveErr				;skip if have a string...

	mov	bp, ERR_MISSING_STR		;else, missing string error

haveErr:
	call	DispErrMessage
	cmp	bp, 0				; clears Z flag
exit:
	ret
StringCheck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Get length of the string 

CALLED BY:      DoPrint 

PASS:         	ds	- dgroup
		es:di	- start of quoted string
		dx	- junk

RETURN:        	cx	- length of string

DESTROYED: 	al

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   6/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringLength	proc	near
	push	ax, di				;save ptr into macro file	
	call	GotoNextLine			;find end of line
	mov	cx, di				;
	pop	ax, di				;get length between end and
	sub	cx, di				;  start of line
DBCS <	shr	cx, 1				;# bytes -> # chars	>
	ret
StringLength	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LabelSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Search the macro file for a label

CALLED BY:      DoGoto

PASS:         	es:di	- label to search for
		ds:si	- file to search
		cx	- size of file

RETURN:        	C	- clear if label found
		ds:si	- points to line of the label

		C	- set if label not found

	
DESTROYED: 	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/07/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LabelSearch	proc	near
SBCS <	cmp	{byte}ds:[si], LABEL_FLAG	;is this line a label	>
DBCS <	cmp	{wchar}ds:[si], LABEL_FLAG	;is this line a label	>
	jne	skip				;nope, skip it
	LocalNextChar	dssi			;else point to label
	call	WordCmp				;  and if labels match
	jnc	exit				;  then exit
skip:
	LocalNextChar	dssi
SBCS <	cmp	{byte}ds:[si], CHAR_LF		;skip to next line	>
DBCS <	cmp	{wchar}ds:[si], CHAR_LF		;skip to next line	>
	jne	skip
	LocalNextChar	dssi			;skip past the LF
	cmp	si, cx				;if not at end of file
	jb	LabelSearch			;  continue
notfound:
	stc					;else flag label not found
	jmp	short exit
exit:
	ret
LabelSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WordCmp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       check if two words match

CALLED BY:      LabelSearch

PASS:         	es:di	- string to match (white space terminated)
		ds:si	- string to check against (white space terminated)

RETURN:        	C	- set if string don't match
		es:di	- points past the string
		ds:si 	- points past the string
	
DESTROYED: 	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/07/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WordCmp	proc	near
	mov	bx, di				;save ptr to start of label
cmpChar:
	LocalGetChar	ax, esdi, NO_ADVANCE	;get the char to compare
	LocalCmpChar	ax, CHAR_SPACE		;if first string done
	je	last				;check if second string done	
	LocalCmpChar	ax, CHAR_CR		;
	je	last				;
	LocalCmpChar	ax, CHAR_TAB		;
	je	last				;
	LocalCmpChar	ax, CHAR_NULL		;
	je	last				;
SBCS <	cmp	al, ds:[si]			;if chars not equal then>
DBCS <	cmp	ax, ds:[si]			;if chars not equal then>
	jne	notEqual			;	words not equal
	LocalNextChar	esdi				;check next char
	LocalNextChar	dssi				;
	jmp	short cmpChar			;
last:
	LocalGetChar	ax, dssi, NO_ADVANCE
	LocalCmpChar	ax, CHAR_SPACE		;if second string done
	je	equal				;then two strings are equal
	LocalCmpChar	ax, CHAR_CR		;
	je	equal				;
	LocalCmpChar	ax, CHAR_TAB		;
	je	equal				;
	LocalCmpChar	ax, CHAR_NULL		;
	je	equal				;
notEqual:					;else they don't match
	stc
	jmp	short exit
equal:
	clc
exit:
	mov	di, bx				;restore ptr to start of label
	ret
WordCmp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringCopyAndConvert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Copy one string to another and convert from GEOS->BBS
		DBCS: no conversion

CALLED BY:      DoMatch

PASS:         	es:di	- string to copy
				(GEOS code page)
		ds:si	- string to copy to
		dh	- alternate word delimeter
		cx	- number of characters to copy, not including null-term.
			Null term will be written to destination string.
			(pass 0 to copy string until reach space, tab, or CR;
			will then write null-terminator).
		ds - dgroup (match table in dgroup)

RETURN:        	es:di	- points to the terminating character in the source
			string (if was copying CX chars, points to char after
			the CX char.)
		ds:si	- points to the null-termination in the dest string.

DESTROYED: 	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringCopyAndConvert	proc	near

EC <	call	ECCheckDS_dgroup					>

	mov	bx, cx				;get flag if should check for
						;	end of string
copyChar:
	LocalGetChar	ax, esdi, NO_ADVANCE	;get character

	tst	bx				;test for end of string?
	jnz	doCopy

SBCS <	cmp	al, dh				;check for alt word delimiter>
DBCS <	cmp	ax, dx				;check for alt word delimiter>
	je	exit				;skip if found it...
	LocalCmpChar	ax, CHAR_SPACE
	je	exit	
	LocalCmpChar	ax, CHAR_TAB
	je	exit	
	LocalCmpChar	ax, CHAR_CR
	je	exit	
	LocalCmpChar	ax, CHAR_NULL
	je	exit	

doCopy:
	;
	; convert character to BBS code page, if needed
	;	(do per character as it is easiest this way -- not that slow
	;	 as few characters will need to be converted)
	; DBCS: no conversion, convert when comparing with input as we cannot
	; easily deal with storing the info about JIS code page mode that is
	; needed to match correctly
	;
if not DBCS_PCGEOS
	cmp	al, MIN_MAP_CHAR		; need to convert?
	jb	noConv				; nope
	push	bx, cx				; save flag, pointer
	mov	bx, MAPPING_DEFAULT_CHAR
	mov	cx, ds:[bbsCP]			; bx = destination code page
	call	LocalGeosToCodePageChar		; al = converted char
if INPUT_OUTPUT_MAPPING
	call	OutputMapChar
endif
	pop	bx, cx				; restore flag, pointer
noConv:
endif
	LocalPutChar	dssi, ax, NO_ADVANCE
	LocalNextChar	dssi
	LocalNextChar	esdi
	loop	copyChar

exit:
SBCS <	mov	{byte} ds:[si], CHAR_NULL	;null terminate the string>
DBCS <	mov	{wchar} ds:[si], CHAR_NULL	;null terminate the string>
	ret
StringCopyAndConvert	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvCharExp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       convert character expressions to actual character value

CALLED BY:      DoSend, DoPrint

PASS:         	es:di	- character expression to convert

RETURN:        	AL	- charater value	 
		C	- clear if character expression okay	
		es:di	- points past char expression

		C	- set if character expression invalid 	
		es:di	- points at dorked char exp
		
		
DESTROYED: 	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvCharExp	proc	near
	call	SkipSpaces
SBCS< 	cmp	{byte}es:[di], CHAR_CTRL				>
DBCS< 	cmp	{wchar}es:[di], CHAR_CTRL				>
	jne	notCtrl
	LocalNextChar	esdi			;get past the '^' char
	LocalGetChar	ax, esdi, NO_ADVANCE	;get the ctrl char
SBCS <	and	al, CTRL_MASK						>
DBCS <	and	ax, CTRL_MASK						>
	LocalNextChar	esdi			;move past the ctrl char
	clc					;clear error flag
	jmp	short exit
notCtrl:
	mov	si, offset CharTable		;cs:si->macroTable
	mov	cx, offset CharTableEnd		;get length of table
	mov	dx, CHAR_COMMA			;alternate word delimiter
	call	StringMatch
	jc	exit
	LocalGetChar	ax, cssi, NO_ADVANCE	;get char to send	>
exit:
	ret
ConvCharExp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvNumString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Convert numeric string to hex value

CALLED BY:      DoPause, DoPrompt

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         C	- clear if number okay	
			- set if number dorked (error message displayed)

DESTROYED: 

PSEUDO CODE/STRATEGY:
		The argument is in 1/60ths of a second.  So to pause for
		1 second, use 'PAUSE 60'  If no argument, assume pause for
		one second.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		If input comes in when the program is sleeping then 
		you lose data.

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvNumString	proc	near
	call	SkipSpaces			;check for arguments
SBCS <	cmp	{byte} es:[di], CHAR_CR					>
DBCS <	cmp	{wchar} es:[di], CHAR_CR				>
	je	default
	mov	ds:[inputBase], DECIMAL		;flag this is decimal #
	mov	dx, es				;save macro file segment
	segmov	es, ds, ax			;es->dgroup
	mov	ds, dx				;ds->macro file
	mov	si, di
SBCS <	CallMod	ConvertDecNumber					>
DBCS <	CallMod	ConvertDecNumberDBCS					>
	mov	dx, es				;save ptr to dgroup
	segmov	es, ds, cx			;es->macro file
	mov	ds, dx				;ds-> dgroup
	cmp	ax, ERROR_FLAG
	jne	okay
	call	NullTerminateWord		;	string
	mov	bp, ERR_UNDEF_NUM		;numeric error
	call	DispErrMessage
	stc
	jmp	short exit
default:
	mov	ax, ONE_SECOND
okay:
	clc
exit:
	ret
ConvNumString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndScript
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Do tasks associated with finishing a script file

CALLED BY:      ScriptTimeout, ScriptRunFile

PASS:         	ds	- dgroup

RETURN:
	

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EndScript	proc	near

	;first free the script file block

EC <	call	ECCheckDS_dgroup					>
	mov	bx, ds:[scriptHandle]	;free up script buffer block 
	tst	bx
	jz	exit			;skip if already did this work...

	call	MemFree
	clr	ds:[scriptHandle]

	;update the UI

	call	ResetScriptTriggers

	;redirect input to the screen (if the Serial thread has not already
	;done this)

	CallMod	SetScreenInput

EC <	call	ECCheckDS_dgroup					>

	cmp	ds:[serialPort], NO_PORT ;if no port opened then
	je	exit			 ;don't enable file

	CallMod	EnableFileTransfer	;transfer junk

exit:
	ret
EndScript	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTimer		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set timer to wake up the program

CALLED BY:      DoPrompt, DoPause

PASS:         	es:di	- current line in script file
		ds	- dgroup

RETURN:         carry set if parse error

DESTROYED: 	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:

	Name    Date            Description
	----    --------	-----------
	dennis   2/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetTimer	proc	near

EC <	call	ECCheckDS_dgroup					>

	call	ConvNumString			;get amount to wait
	jc	exit				;if error bug out

	mov	cx, ax 				;else set timer length
	mov	ax, TIMER_EVENT_ONE_SHOT	;  and start the timer
	mov	bx, ds:[termProcHandle]		;get our process handle
	mov	dx, MSG_TIMEOUT		;
	call	TimerStart			;

	mov	ds:[scriptTimerId], ax		;store timer info 
	mov	ds:[scriptTimerHandle], bx		;
	call	GotoNextLine

	mov	ds:[restartPtr], di		;save ptr to next line 
	clc					;no error

exit:                                           ;and wait for timer or a match
	ret
SetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDataList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set entry in data bits list 

CALLED BY:      DoComm

PASS:         	es	- dgroup
		cx	- data bits to use
		di	- pointer into macro file

RETURN:		
			
DESTROYED: 

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/21/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetDataList	proc	near
EC <	call	ECCheckDS_dgroup					>

	push	cx, di
	GetResourceHandleNS	DataList, bx
	mov	si, offset DataList
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, di
	ret
SetDataList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetParityList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set entry in parity list 

CALLED BY:      DoComm

PASS:         	es	- dgroup
		cx	- data bits to use
		di	- pointer into macro file

RETURN:		
			
DESTROYED: 

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/21/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetParityList	proc	near
EC <	call	ECCheckDS_dgroup					>

	push	cx, di
	clr	dx
	GetResourceHandleNS	ParityList, bx
	mov	si, offset ParityList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, di
	ret
SetParityList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetStopList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set entry in stop bits list 

CALLED BY:      DoComm

PASS:         	ds	- dgroup
		cx	- stop bits to use
		cs:si	- pointing at stop bit value
		di	- pointer into macro file

RETURN:		
			
DESTROYED: 

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/21/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetStopList	proc	near
EC <	call	ECCheckDS_dgroup					>

	push	cx, di
	mov	dx, SBO_ONE			;assume 1 bit
	cmp	cl, ONE_STOP
	je	setList
	sub	si, 3
SBCS <	cmp	{byte} cs:[si], '5'		;was it 1.5 stop bits?	>
DBCS <	cmp	{wchar} cs:[si], '5'		;was it 1.5 stop bits?	>
	je	doOneHalf
	mov	dx, SBO_TWO			;2 bits
	jmp	short setList
doOneHalf:
	mov	dx, SBO_ONEANDHALF		;1.5 bits
	jmp	short setList
setList:
	mov	cx, dx				;cx = identifier
	clr	dx
	GetResourceHandleNS	StopList, bx
	mov	si, offset StopList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, di
	ret
SetStopList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDuplexList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set entry in duplex list 

CALLED BY:      DoComm

PASS:         	es	- dgroup
		cl	- TRUE (use half duplex)
		di	- pointer into macro file

RETURN:		
			
DESTROYED: 

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/21/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetDuplexList	proc	near
EC <	call	ECCheckDS_dgroup					>

	push	cx, di
	mov	al, cl
	cbw
	mov	cx, ax
	GetResourceHandleNS	EchoList, bx
	mov	si, offset EchoList
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, di
	ret
SetDuplexList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       enable ScriptUI trigger

CALLED BY:      InitScript, EndScript 

PASS:         	ds	- dgroup
		si	- offset to ScriptUI obj to disable

RETURN:		
			
DESTROYED: 

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis  03/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnableTrigger	proc	near
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	GetResourceHandleNS	ScriptUI, bx
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
EnableTrigger	endp

DisableTrigger	proc	near
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	GetResourceHandleNS	ScriptUI, bx
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
DisableTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScriptAttemptBranchToAbortSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this script has an "ABORT" section.

CALLED BY:	DoPort, DispErrMessage

PASS:         	ds	- dgroup

RETURN:		C	-	clear if there is an abort section
				ES:DI	- current line in script file
		C	- set if there is no abort section in script	
			
DESTROYED: 

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis  06/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScriptAttemptBranchToAbortSection	proc	near

EC <	call	ECCheckDS_dgroup					>

	cmp     ds:[scriptMode], SCRIPT_MODE_PROMPT
	je      stopTimer

	cmp     ds:[scriptMode], SCRIPT_MODE_PAUSE
	jne     noTimer

stopTimer:
	mov     bx, ds:[scriptTimerHandle]	;got a match, stop the timer
	mov     ax, ds:[scriptTimerId]
	call	TimerStop

	mov     ds:[scriptMode], SCRIPT_MODE_EXEC ;reset match mode

noTimer:
	mov     dx, offset dgroup: matchTable   ;clear match table
	mov     ds:[matchTableHead], dx         ;

	call    PrintAbort                      ;print abort message

	mov     cx, ds:[scriptSize]             ;does script have abort section?
	segmov  es, cs, di
	mov     di, offset abortLabel           ;es:di-> label to search for
	push    ds                              ;save dgroup
	mov     ds, ds:[scriptSeg]              ;
	clr     si                              ;ds:si-> start of macro file
	call    LabelSearch                     ;
	pop     ds                              ;restore ds->dgroup
	jc      exit                         	;if no abort label, exit

	mov     es, ds:[scriptSeg]
	mov     di, si                          ;es:di->pointer into macro file
	clc					;clear flag cauz abort section

exit:
	ret
ScriptAttemptBranchToAbortSection	endp


;print abort string

PrintAbort	proc	near

EC <	call	ECCheckDS_dgroup					>

	GetResourceHandleNS	scriptAbortString, bx
	push	bx
	call	MemLock		; ax = string segment
	push	ds
	mov	dx, ax
	mov	ds, ax
	mov	si, offset scriptAbortString
	mov	bp, ds:[si]			; dx:bp = abort string
	pop	ds
	clr	cx				; null-terminated
	mov	bx, ds:[scriptDisp].handle
	mov     si, ds:[scriptDisp].chunk
	mov     ax, MSG_VIS_TEXT_APPEND
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx
	call	MemUnlock			; unlock string block
	ret
PrintAbort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NullTerminateWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Null terminate the current word

CALLED BY:    	CheckCommand, DoComm 

PASS:   	es:di		- ptr to "white space" terminated word   	

RETURN:		es:di		- ptr to null-terminated word
		cx:dx		- ptr to same null-terminated word
			
DESTROYED: 	al

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Since we're inserting a NULL we may screw up further processing
	of the macro file, but since this routine is called before we
	display an error message the macro file isn't processed anymore
	anyway.

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis  07/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NullTerminateWord	proc	near
	uses	di
	.enter
topLoop:
	LocalGetChar	ax, esdi, NO_ADVANCE	;
	LocalCmpChar	ax, CHAR_SPACE		;if first string done
	je      done				;check if second string done
	LocalCmpChar	ax, CHAR_CR		;
	je      done                           	;
	LocalCmpChar	ax, CHAR_TAB		;
	je	done
	LocalCmpChar	ax, CHAR_DASH		;
	je      done                           	;
	LocalCmpChar	ax, CHAR_COMMA		;
	je      done                           	;
	LocalNextChar	esdi
	jmp	short topLoop
done:
SBCS <	mov	{byte} es:[di], CHAR_NULL				>
DBCS <	mov	{wchar} es:[di], CHAR_NULL				>
	.leave					;restore di to start of string
	mov	cx, es				;cx:dx-> null-terminated
	mov	dx, di				;	string too
	ret
NullTerminateWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvUpperCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Check that word pointed to by es:di is in upper case

CALLED BY:    	CheckCommand 

PASS:   	es:di		- ptr to "white space" terminated word   	

RETURN:		es:di		- ptr to word in uppercase
			
DESTROYED: 	al

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis  07/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvUpperCase	proc	near
	uses	di
	.enter
topLoop:
	LocalGetChar	ax, esdi, NO_ADVANCE	;

	;if we have reached end of file, bail. Checks should have been made
	;earlier, after skipping white space.

EC <	LocalIsNull	ax						>
EC <	ERROR_Z	TERM_ERROR						>

	LocalCmpChar	ax, CHAR_SPACE		;if first string done
	je      done				;check if second string done
	LocalCmpChar	ax, CHAR_CR		;
	je      done                            ;
	LocalCmpChar	ax, CHAR_TAB		;
	je	done
if 0
	LocalCmpChar	ax, 'a'			;is the char a lower case char
	jb	next				;
	LocalCmpChar	ax, 'z'			;
	ja	next
SBCS <	sub	al, 'a' - 'A'			;convert letter to upper case>
DBCS <	sub	ax, 'a' - 'A'			;convert letter to upper case>
else
SBCS <	clr	ah							>
	call	LocalUpcaseChar
endif
	LocalPutChar	esdi, ax, NO_ADVANCE
next:
	LocalNextChar	esdi
	jmp	short topLoop
done:
	.leave
	ret
ConvUpperCase	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitScriptTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       

CALLED BY:    	InitScript 

PASS:   	

RETURN:	
			
DESTROYED: 	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis  08/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResetScriptTriggers	proc	near
	mov	si, offset ScriptUI:OpenMacTrigger ;enable run macro trigger
	call	EnableTrigger
						;enable close display trigger
	mov	si, offset ScriptUI:CloseScrTrigger
	call	EnableTrigger
	mov     si, offset ScriptUI:AbortScrTrigger ;disable abort trigger
	call    DisableTrigger
	ret
ResetScriptTriggers	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ScriptCancelAndNotifySerialThread

DESCRIPTION:	This procedure is called when an END command is reached
		in the script, Cancel is pressed, or an error is encountered.

CALLED BY:	DispErrMessage, DoPort, DoCommand, DoEnd, ScriptAbort

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/90		initial version

------------------------------------------------------------------------------@

ScriptCancelAndNotifySerialThread	proc	near

	;indicate that we are no longer processing a script,

	mov	ds:[scriptMode], SCRIPT_MODE_OFF

	;now, send a method to the serial thread, so that it will
	;send all future input to the FSM, first flushing the
	;rest of the characters from auxBuf into the FSM, and then grabbing
	;more chars from the Stream Driver into auxBuf.

	mov	ax, MSG_SERIAL_EXIT_SCRIPT_MODE
	mov	bx, ds:[threadHandle]		;get serial thread handle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
ScriptCancelAndNotifySerialThread	endp



if _SCRIPT_VARIABLE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VariableCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks target string to see if it is a variable.  If so,
calls user handled message to output variable to port.

CALLED BY:	(INTERNAL) DoSend
PASS:		ds	- dgroup
		es:di	- start of $'d string
RETURN:		carry set if variable
			es:si - points to user specified variable (to print
				out)
			cx - length of var to output string
			di - offset to first char inside variable string
				(in script file)
			dx - length of variable string.
		carry clear if not a variable (resets vars to previous)
			es:di - points to first char inside variable string
				(in script file)

DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VariableCheck	proc	near
	uses	ax,bx,bp
	.enter
	mov	bx, di			; store pointer to string start

	LocalLoadChar	ax, CHAR_DOLLAR
SBCS <	cmp	es:[di], al		;variable must be bounded by '$'>
DBCS <	cmp	es:[di], ax		;variable must be bounded by '$'>
	jne	notVar	
	
	LocalNextChar	esdi		; skip past the '$'
	mov	dx, di	

	LocalFindChar	esdi		; skip to delmiting '$'
	jnz	notVar	

	LocalPrevChar	esdi		; point to end of variable
	
	; now to compute the variable string length
	mov	cx, di
	mov	di, dx	; get pointer to start of variable
	sub	cx, di	; get variable string length
DBCS <	shr	cx, 1	; # bytes -> # chars	>

	push	cx, bx	; store length and offset to start of variable
	; set up vars for call to get variable
	mov	bp, cx	; set up length
	mov	cx, es	; segment
	mov	dx, di	; offset

	; Now call user handled routine to get pointer and length of string
	; to output in place of the variable.  Note: this routine should
	; avoid destroying variables.
	;
	; The routine should set the pointer to the string at es:si, 
	; char length to cx.

	CallMod	GetVariable	; grab the variable

after_get_var:
	tst	bp	; check to see if var declared (size > 0)
	pop	ax, bx	; restore length and offset to start of variable
			; (doesn't affect zero flag). 
	jz	errVarNotDeclared

	; variable exists, now set return values
	segmov	ds, es	; set to segment of variable
	mov	di, bx	; set to beginning of variable
	
	mov	es, cx	; set to segment of text to output
	mov	si, dx	; set to offset of text to output
	mov	cx, bp	; set to length of text to output

	mov	dx, ax	; store length of variable


	stc		; set carry (proper variable)

exit_variable_check:

	.leave
	ret

notVar:			; not a variable, so leave
	mov	di, bx	; restore pointer to start of string
	clc		; clear carry
	jmp	exit_variable_check	; leave procedure

errVarNotDeclared:	; Variable not declared
	; ***Set error handler here***
	mov	di, bx	; restore pointer to start of string
	clc		; clear carry
	jmp	exit_variable_check	; leave procedure


VariableCheck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DialVariableCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if properly formatted variable.  If so, user 
should call user defined variable routine (GetDialVariable) and returns that 
string with its length. 

CALLED BY:	DoDial
PASS:		ds	- dgroup
		es:di	- start of variable string
RETURN:	
	if variable:
		C	- set if string okay
		es:di	- pointer to variable name
		cx	- length of variable string

	if not variable:
		C 	- clear if not dial variable
		es:di	- pointer to start of string
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DialVariableCheck	proc	near
	uses	ax,bx,dx,si
	.enter

	mov	bx, di	; preserve start of string

	LocalLoadChar	ax, CHAR_DOLLAR
SBCS <	cmp	es:[di], al		;variable must be bounded by '$'>
DBCS <	cmp	es:[di], ax		;variable must be bounded by '$'>
	jne	notDialVar	
	
	LocalNextChar	esdi	; skip past '$'
	mov	dx, di
	LocalFindChar	esdi	; skip to delimiting '$'
	jnz	notDialVar
	LocalPrevChar	esdi	; point to end of variable

	; now to compute the variable string length
	mov	cx, di
	mov	di, dx	; get pointer to start of variable
	sub	cx, di	; get variable string length
DBCS <	shr	cx, 1	; # bytes -> # chars	>
	stc	; is a variable, set carry
	jmp	exit_dial_var_check

notDialVar:
	mov	di, bx	; restore start of string
	clc	; not a variable, clear carry
	
exit_dial_var_check:
	.leave
	ret
DialVariableCheck	endp

endif ; _SCRIPT_VARIABLE




