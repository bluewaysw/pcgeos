COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	GeoComm
MODULE:		Script
FILE:		scriptMain.asm

AUTHOR:		Dennis Chow, January 31, 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc      01/31/90        Initial revision.

DESCRIPTION:
	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

	$Id: scriptMain.asm,v 1.1 97/04/04 16:55:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScriptRunFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Start executing script file 

CALLED BY:      MSG_RUN_SCRIPT

PASS:           ds	- dgroup
		cx:dx  	- filename of script file
		bx:bp  	- display object

RETURN:         

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScriptRunFile	proc	far

EC <	call	ECCheckDS_dgroup					>

	cmp     ds:[termStatus], IN_SCRIPT	;see if already in a script
	LONG je exit				;skip if so...

EC <	cmp	ds:[scriptMode], SCRIPT_MODE_OFF			>
EC <	ERROR_NE TERM_ERROR						>

	mov	ds:[scriptDisp].handle, bx
	mov	ds:[scriptDisp].chunk, bp	;pass handle to text object 

	;try to load the script file into a FIXED block on the global heap
	mov	bp, cx				;bp:dx -> filename to load


	CallMod LoadFile			;and try to load macro file 

	LONG jc      openErr                         ;skip if error...


	;
	; convert script from DOS character set to GEOS character set
	;	cx = size of script
	;	ax = buffer segment
	;	bx = buffer handle
	;
if DBCS_PCGEOS
	;
	; allocate block for conversion
	;
	push	ds, es
	push	bx				; save BBS script handle
	push	cx				; save size
	mov	ds, ax				; ds:si = script
	clr	si
	mov	ax, cx
	shl	ax, 1
	shl	ax, 1				; size*4 for 5-to-2 expansion
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc			; ax = segment, bx = block
	mov	es, ax				; es:di = new buffer
	clr	di
	pop	cx				; cx = script size
	push	bx				; save GEOS script handle
	mov	ax, MAPPING_DEFAULT_CHAR
	clr	bx, dx
	call	LocalDosToGeos			; cx = GEOS script size
	pop	dx				; dx = GEOS script handle
	pop	bx				; bx = BBS script handle
	pushf					; save conversion result
	call	MemFree				; free BBS script buffer
	popf
	mov	bx, es				; bx = BBS script segment
	pop	ds, es
	mov	ax, 0				; assume general error
	jc	openErr				; conversion error
	mov	ax, bx				; ax = GEOS script segment
	mov	bx, dx				; bx = GEOS script handle
	shl	cx, 1				; # chars -> # bytes
	mov	di, cx
	push	es
	mov	es, ax
	mov	ax, CHAR_NULL
	stosw					; ensure null-terminated
	mov	ax, es				; ax = GEOS script segment
	pop	es
else
	push	ds, si, di, ax
	mov	ds, ax				; ds:si = script buffer
	clr	si
	mov	ax, MAPPING_DEFAULT_CHAR	; default character
	call	LocalDosToGeos
	pop	ds, si, di, ax
endif

	;reset our pointers to the start of the script file

EC <	call	ECCheckDS_dgroup					>
	mov	ds:[scriptSeg], ax 		;save buffer segment
	mov	ds:[scriptHandle], bx 		;save buffer handle
	mov	ds:[scriptSize], cx 		;save buffer size
	mov     ds:[scriptEnd], cx              ;point to end of script file

	mov	ds:[scriptMode], SCRIPT_MODE_EXEC

	;reset pointer to the beginning of the MATCH table.

	mov	dx, offset dgroup: matchTable	;reset ptr into tables
	mov	ds:[matchTableHead], dx

	;initialize triggers in the UI
	mov	si, offset ScriptUI:OpenMacTrigger
	call	DisableTrigger
	mov	si, offset ScriptUI:CloseScrTrigger
	call	DisableTrigger
	mov     si, offset ScriptUI:AbortScrTrigger
	call	EnableTrigger

	CallMod	DisableFileTransfer		;more UI updates

	GetResourceHandleNS	ScriptSummons, bx
	mov	si, offset ScriptSummons	;bring up display box
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	;notify the Serial thread that we are beginning to execute a script.
	;It will suspend input from the Stream Driver, until we reach our first
	;MATCH or PROMPT command. This will also cause input to be redirected
	;to the script code in the Serial thread.

	mov	ax, MSG_SERIAL_ENTER_SCRIPT_MODE
	mov	bx, ds:[threadHandle]		;get process handle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	mov	es, ds:[scriptSeg]		;point to start of script
	clr	di

	call	InterpretScriptFile		;interpret the script file
	jmp	short exit

openErr:
	cmp     ax, ERROR_SHARING_VIOLATION
	je	inUse

	mov     bp, ERR_SCRIPT_FILE_OPEN	;put up generic 'file open' err
	cmp     ax, FILE_SIZE_MAX		;is open err cause file too
	jb	dispErrorMessage		;	big?

	mov     bp, ERR_FILE_TOO_BIG            ;

dispErrorMessage:
	CallMod DisplayErrorMessage
exit:
	ret

inUse:
	mov	cx, bp				;cx:dx -> filename
	mov     bp, ERR_FILE_OPEN_SHARING_DENIED
	jmp	dispErrorMessage

ScriptRunFile	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScriptTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called by the Term thread when it times-out
		waiting for a match in the input stream, or when a PAUSE
		period ends.

CALLED BY:      TermTimeout (MSG_TIMEOUT)

PASS:           ds	= dgroup

RETURN:         

DESTROYED: 	?

PSEUDO CODE/STRATEGY:
		Set es:di to point to line after the prompt 
		reset MATCH variables

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScriptTimeout	proc	far
EC <	call	ECCheckDS_dgroup					>

	;first, let's make sure that we have not JUST received notification
	;from the serial thread that a match was found

	cmp	ds:[scriptMode], SCRIPT_MODE_EXEC
	je	done			;skip to end if so (we are already
					;in the process of handling the match)..

	;set our state variable

	mov	ds:[scriptMode], SCRIPT_MODE_EXEC

	;call the Serial thread, indicating that we should suspend further
	;input from the host, as we are about to begin execution again.

	mov	ax, MSG_SERIAL_ENTER_SCRIPT_SUSPEND_MODE
	mov	bx, ds:[threadHandle]		;get process handle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	;forget about old MATCH strings

	mov     dx, offset dgroup: matchTable	;reset match table
	mov     ds:[matchTableHead], dx

	;now begin execution of script, starting with the next line

	mov	es, ds:[scriptSeg]		;es:di->current line in
	mov	di, ds:[restartPtr]		;  macro file
	call	InterpretScriptFile		;restart script

done:
	ret
ScriptTimeout	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScriptAbort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       abort the current script

CALLED BY:      TermAbortScript

PASS:           
	
RETURN:         

DESTROYED: 

PSEUDO CODE/STRATEGY:
	if script in match mode,  
		stop the timer
	else stop the script

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScriptAbort	proc	far
NRSP <	mov     si, offset ScriptUI:AbortScrTrigger      ;disable abort trigger>
NRSP <	call    DisableTrigger						>

EC <	call	ECCheckDS_ES_dgroup					>

	;If we are in PROMPT or PAUSE mode, then there is a timer pending.
	;Kill it now.

	cmp	es:[scriptMode], SCRIPT_MODE_PROMPT
	je	stopTimer

	cmp	es:[scriptMode], SCRIPT_MODE_PAUSE
	jne	noTimer

stopTimer:
	mov	bx, es:[scriptTimerHandle]	;got a match, stop the timer
	mov	ax, es:[scriptTimerId]
	call	TimerStop

noTimer:
	mov	ds:[scriptMode], SCRIPT_MODE_EXEC ;reset match mode

	;force the Serial thread into SUSPEND mode, so it will hold up
	;further input.

	mov	ax, MSG_SERIAL_ENTER_SCRIPT_SUSPEND_MODE
	mov	bx, ds:[threadHandle]	;get process handle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage		;prevent deadlock!

	;now clean up some variables, and decide if we want to continue
	;executing script at the :ABORT label.

	mov     dx, offset dgroup: matchTable   ;clear match table
	mov     ds:[matchTableHead], dx

	call	PrintAbort			;print abort message

	mov	cx, ds:[scriptSize]		;does script have abort section?
	segmov	es, cs, di
	mov	di, offset abortLabel		;es:di-> label to search for
	push	ds				;save dgroup
	mov	ds, ds:[scriptSeg] 		;
	clr	si				;ds:si-> start of macro file
	call	LabelSearch			;
	pop	ds				;restore ds->dgroup
	jc	noAbort				;if no abort label, exit

	;continue executing script at the :ABORT label.

	mov	es, ds:[scriptSeg]	
	mov	di, si				;es:di->pointer into macro file
	call	InterpretScriptFile		;interpret the script file
	jmp	short exit

noAbort:
	;indicate the are DONE with the script, and force Serial thread into
	;NORMAL mode, so it will not do any more script work. (Will send
	;future input to FSM)

	call	ScriptCancelAndNotifySerialThread

	;free script block, update UI, etc.

	call	EndScript			;kill it

exit:
	ret
ScriptAbort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScriptNextLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Execute next line in script file

CALLED BY:      TermScriptNext

PASS:          	nothing 
	
RETURN:        	nothing 

DESTROYED: 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScriptNextLine	proc	far
EC <	call	ECCheckDS_dgroup					>

	cmp	ds:[scriptMode], SCRIPT_MODE_OFF ;if script done, exit
	je	exit

	mov	es, ds:[scriptSeg]
	mov	di, ds:[restartPtr]
	call	InterpretScriptFile		;interpret the script file

exit:
	ret
ScriptNextLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScriptReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Reset the script boxes.

CALLED BY:

PASS:

RETURN:                 -

DESTROYED:

PSEUDO CODE/STRATEGY:
	if geoComm was detached while a script was running then when
	reattaching the 'Run` button will be disabled and the 'Stop'
	button is enabled.  This is a problem since clicking on the
	stop button will try to abort a script thats not there and
	things puke.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	dennis  08/08/90        Initial version


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScriptReset     proc    far

;	GetResourceHandleNS	MacroFileBox, bx
;	mov	si, offset MacroFileBox
;	mov	cx, IC_DISMISS
;	mov     ax, MSG_GEN_GUP_INTERACTION_COMMAND
;	mov	di, mask MF_CALL or mask MF_FIXUP_DS
;	call	ObjMessage
	call	ResetScriptTriggers
	GetResourceHandleNS	ScriptSummons, bx

	mov     si, offset ScriptSummons        ;close the display box
	mov	cx, IC_DISMISS
	mov     ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
ScriptReset     endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ScriptFoundMatchContinueScript

DESCRIPTION:	This procedure is called by the Term thread when
		MSG_TERM_FOUND_MATCH_CONTINUE_SCRIPT has been sent from
		the Serial thread (term:1), when it encounters a MATCH
		in the input stream. It is telling us to continue executing
		the script, starting with an offset of CX into the script.

CALLED BY:	TermFoundMatchContinueScript

PASS:		ds	= dgroup
		cx	= offset to GOTO command in script.

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/90		initial version

------------------------------------------------------------------------------@

ScriptFoundMatchContinueScript	proc	far

EC <	call	ECCheckDS_dgroup					>

	;if we have already received the time-out notification, then ignore
	;this method.

	cmp	ds:[scriptMode], SCRIPT_MODE_PROMPT
	jne	done			;skip if not still in prompt mode...

	;now guarantee that we WILL NOT get a timeout method

	mov     bx, ds:[scriptTimerHandle] ;got a match, stop the timer
	mov     ax, ds:[scriptTimerId]
	call    TimerStop

	;now reset our state and script pointer, so that we continue to
	;execute the script, starting with the GOTO command which lies at
	;the end of the MATCH command which succeeded.

	mov	ds:[scriptMode], SCRIPT_MODE_EXEC

EC <	call	ECCheckDS_dgroup					>
	mov	ds:[restartPtr], cx	;set place to restart script

	CallMod	ScriptNextLine

done:
	ret
ScriptFoundMatchContinueScript	endp

