COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calculator Accessory -- LED Display
FILE:		calcDisplay.asm

AUTHOR:		Adam de Boor, Mar 15, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/15/90		Initial revision


DESCRIPTION:
	Object class to run the numeric display for the calculator. There
	is certain behaviour in the GenTextEdit class that we need to override,
	along with extra stuff (like clearing the display on the first
	keystroke) we need to handle.
		

	$Id: calcDisplay.asm,v 1.1 97/04/04 14:47:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	CalcDisplayClass	; Declare class record
idata	ends

Main		segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDCheckClearPending
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the display needs to be cleared before input is
		placed in the display, and clear it if so.

CALLED BY:	CalcDisplayCDKbdChar, CalcDisplayPaste
PASS:		ds:di	= CalcDisplayInstance
		*ds:si	= CalcDisplay object
RETURN:		ds:di	= possibly shifted CalcDisplayInstance
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/24/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDCheckClearPending proc near
		class	CalcDisplayClass
		.enter
		tst	ds:[di].CD_clearPending
		jz	done

		DoPush	cx, dx, bp
		
		;
		; Notify the engine that the display is being cleared so it can
		; deal with pending recalls and stuff like that.
		;
		push	si
		mov	bx, ds:[di].CD_engine.handle
		mov	si, ds:[di].CD_engine.chunk
		mov	ax, MSG_CE_CLEARING
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
		
		;
		; Now call ourselves to clear the display
		;
		mov	di, ds:[si]
		add	di, ds:[di].CalcDisplay_offset
		mov	ds:[di].CD_resetCount, CD_RESET_START

		mov	ax, MSG_CD_CLEAR
		call	ObjCallInstanceNoLock

		mov	di, ds:[si]
		add	di, ds:[di].CalcDisplay_offset
		mov	ds:[di].CD_resetCount, CD_RESET_START
		DoPopRV	cx, dx, bp
done:
		.leave
		ret
CDCheckClearPending endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplayCDKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special funky KBD_CHAR for CalcDisplayClass that handles
		the clearing of the display, etc.

CALLED BY:	MSG_CD_KBD_CHAR
PASS:		cx	= character value
		dl	= CharFlags
		*ds:si	= instance
		ds:di	= CalcDisplayInstance
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDisplayCDKbdChar method dynamic CalcDisplayClass, MSG_CD_KBD_CHAR
		.enter
	;
	; Clear the display if a clear is pending and the key is part of
	; a number (we only get here if the character is part of a number).
	;
		test	dl, mask CF_RELEASE
		jnz	transform		; only clear on press...

		call	CDCheckClearPending
transform:
	;
	; If trigger is for a decimal point, convert the character to the
	; current decimal point.
	;
		cmp	cx, (CS_BSW shl 8) or '.'
		jne	sendUpward
		mov	cl, es:[decimalPoint]
sendUpward:
		mov	ax, MSG_KBD_CHAR
		mov	di, offset CalcDisplayClass
		CallSuper	MSG_KBD_CHAR
		.leave
		ret
CalcDisplayCDKbdChar endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplayKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform special operations required by the calculator display
		when the user types something in it, including:
			- transforming numeric NUMPAD keystrokes into real
			  numbers to avoid shortcut processing in our superclass
			- sending ourselves a MSG_CD_CLEAR before forwarding
			  the keystroke if CD_clearPending is set.

CALLED BY:	MSG_KBD_CHAR
PASS:		*ds:si	= instance data
		ds:bx	= CalcDisplayBase
		ds:di	= CalcDisplayInstance
		es	= dgroup
		cx	= char value
		dl	= CharFlags
				CF_RELEASE - set if release
				CF_STATE - set if shift, ctrl, etc.
				CF_TEMP_ACCENT - set if accented char pending
		dh 	= ShiftState
		bp low 	= ToggleState (unused)
		bp high = scan code (unused)
				
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDisplayKbdChar method dynamic CalcDisplayClass, MSG_KBD_CHAR
		.enter
		call	CalcDisplayScanShortcuts
		jc	done
	
	;
	; If keystroke is funky UI mouse-button stuff, don't alter the reset
	; count, as this isn't a real keystroke.
	; 
		cmp	ch, CS_UI_FUNCS
		je	passItOn
	;
	; Signal that user has typed something and next C/CE should just CE.
	;
		mov	di, ds:[si]
		add	di, ds:[di].CalcDisplay_offset
		mov	ds:[di].CD_resetCount, CD_RESET_START
passItOn:
		mov	di, offset CalcDisplayClass
		CallSuper	MSG_KBD_CHAR
done:
		.leave
		ret
CalcDisplayKbdChar endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDCheckMaxLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure a keypress or transfer won't push the text past
		maxLength - 1

CALLED BY:	CalcDisplayFilterKbdChar, CalcDisplayFilterTransfer
PASS:		ds:bx	= CalcDisplayBase
		bp	= number of characters being inserted
		VTI_selectStart, VTI_selectEnd accurate
RETURN:		carry set if would go over
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDCheckMaxLength proc	near	uses bx, cx
		class	CalcDisplayClass
		.enter
	;
	; Figure current length of text.
	;
		add	bx, ds:[bx].Vis_offset
		mov	di, ds:[bx].VTI_text
		ChunkSizeHandle	ds, di, cx
		dec	cx	; null byte doesn't count
	;
	; Now figure the number of chars that'll get nuked by the insert
	;
EC <		tst	ds:[bx].VTI_selectEnd.high	;>
EC <		ERROR_NZ	SELECTION_TOO_LARGE	;>
EC <		tst	ds:[bx].VTI_selectStart.high	;>
EC <		ERROR_NZ	SELECTION_TOO_LARGE	;>
		mov	ax, ds:[bx].VTI_selectEnd.low
		sub	ax, ds:[bx].VTI_selectStart.low
		sub	cx, ax
	;
	; Adjust the total remaining by what we'll insert, and add one so we're
	; comparing against maxLength - 1.
	; 
		add	cx, bp
		mov	di, ds:[di]
		cmp	{char}ds:[di], '-'	;already negative?
		je	checkLength		;yes -- compare against
						; maxLength, not mL-1

		inc	cx			; so we compare against
						;  maxLength-1, effectively
checkLength:
	;
	; If maxLength is below what we just calculated (carry set), it's
	; no go.
	; 
		cmp	ds:[bx].VTI_maxLength, cx
		.leave
		ret
CDCheckMaxLength endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplayFilterKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Additional key filtering for a calc display.

CALLED BY:	MSG_VIS_TEXT_FILTER_CHAR_FROM_KBD
PASS:		*ds:si	= CalcDisplayBase
		ds:bx	= CalcDisplayBase
		ds:di	= CalcDisplayInstance
		cl 	= character being inserted
		es	= dgroup
RETURN:		cx	= 0 if character was handled, unchanged if it
			  should be inserted.
DESTROYED:	bp

PSEUDO CODE/STRATEGY:
		There are three things we have to watch for:
			- inserting an extra decimal point
			- inserting a minus sign
			- placing a number before a minus sign

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDisplayFilterKbdChar method dynamic CalcDisplayClass,
				MSG_VIS_TEXT_FILTER_CHAR_FROM_KBD
		.enter
	;------------------------------------------------------------
	; First, never allow a minus sign to be inserted except by
	; MSG_TEXT_REPLACE.
	;
		cmp	cl, '-'
		jne	checkBeforeMinus
nukeIt:
		clr	cx		; never allow - to come in
		jmp	done

	;------------------------------------------------------------
checkControlBeforeMinus:
		cmp	cl, ' '
		LONG jb	passItOn
		cmp	cl, 0x7f
		jb	10$
		jmp	passItOn

checkBeforeMinus:
	;
	; See if we're trying to insert something before a leading minus sign
	; in the display. This is verboten.
	;
		cmp	ch, CS_CONTROL
		je	checkControlBeforeMinus
10$:
	;
	; It's a real character, so make sure we're not maxed out. The
	; maxLength defined for the object is actually one more than we allow
	; the user to type, as we have to allow room for a negative sign at the
	; front.
	;
		mov	bp, 1			; adding 1 char
		call	CDCheckMaxLength
		jc	nukeIt

		DoPush	bx, ax
		mov	di, bx
		add	bx, ds:[bx].Vis_offset
EC <		tst	ds:[bx].VTI_selectStart.high	;>
EC <		ERROR_NZ	SELECTION_TOO_LARGE	;>
		mov	ax, ds:[bx].VTI_selectStart.low
		tst	ax
		jnz	popCheckDecimal	; Not at front, so can't go before
					;  a minus sign.

EC <		tst	ds:[bx].VTI_selectEnd.high	;>
EC <		ERROR_NZ	SELECTION_TOO_LARGE	;>
		or	ax, ds:[bx].VTI_selectEnd.low
		jnz	popCheckDecimal	; Selection exists, so any insertion
					;  will biff the minus sign
		add	di, ds:[di].Gen_offset
		mov	di, ds:[di].GTDI_text
		mov	di, ds:[di]
		cmp	{char}ds:[di], '-'
		jne	popCheckDecimal
		DoPopRV	bx, ax
jmpToNukeIt:
		jmp	nukeIt

popCheckDecimal:
		DoPopRV	bx, ax

	;------------------------------------------------------------
	; If the thing is a decimal point, make sure there's not already one
	; in the object.
	;
		cmp	cl, es:[decimalPoint]
		jne	passItOn
		
		add	bx, ds:[bx].Gen_offset
		mov	bx, ds:[bx].GTDI_text
		DoPush	cx, ax, es
		ChunkSizeHandle	ds, bx, cx
		jcxz	ok
		mov	al, es:[decimalPoint]
		mov	di, ds:[bx]
		segmov	es, ds
		repne	scasb
		jne	ok
	;
	; See if the decimal found lies w/in the selection. If so,
	; this insertion should biff the thing, so it's ok.
	;
		stc			; di is one beyond the '.'...
		sbb	di, ds:[bx]	; di <- offset into text
		clr	cx		; assume it's in the selection
		xchg	ax, di
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
EC <		tst	ds:[di].VTI_selectStart.high	;>
EC <		ERROR_NZ	SELECTION_TOO_LARGE	;>
EC <		tst	ds:[di].VTI_selectEnd.high	;>
EC <		ERROR_NZ	SELECTION_TOO_LARGE	;>
		cmp	ax, ds:[di].VTI_selectStart.low
		jb	bad		; => before selection
		cmp	ax, ds:[di].VTI_selectEnd.low
		jb	ok		; => w/in selection, so happy
bad:
		inc	cx		; signal badness by making sure cx
					;  is non-zero
ok:
		tst	cx
		DoPopRV	cx, ax, es
		jnz	jmpToNukeIt

passItOn:
	;
	; Give our superclass a crack at it.
	;
		mov	di, offset CalcDisplayClass
		mov	ax, MSG_VIS_TEXT_FILTER_CHAR_FROM_KBD
		CallSuper	MSG_VIS_TEXT_FILTER_CHAR_FROM_KBD
done:
		.leave
		ret
CalcDisplayFilterKbdChar		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplayFilterTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure a pending paste conforms to our rigid standards
		for input.

CALLED BY:	MSG_VIS_TEXT_FILTER_CHARS_FROM_TRANSFER
PASS:		*ds:si	= CalcDisplay object
		ds:di	= CalcDisplayInstance
		ds:bx	= CalcDisplayBase
		cx:dx	= buffer of chars
		bp	= count
		es	= dgroup
RETURN:		bp	= 0 to filter range
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDisplayFilterTransfer method dynamic CalcDisplayClass, 
			  	MSG_VIS_TEXT_FILTER_CHARS_FROM_TRANSFER
		.enter
	;
	; Setup registers for loop:
	;	ds:si	= buffer char
	;	cx	= chars left in transfer buffer
	;	ds:bx	= VisTextInstance
	;	es:di	= current text
	;	dx	= non-zero if decimal point seen in buffer
	;	ah	= localized decimal point
	;
		call	CDCheckMaxLength
		jc	error

		mov	ah, es:[decimalPoint]

		add	bx, ds:[bx].Vis_offset
		mov	si, dx
		segmov	es, ds
		mov	ds, cx
		mov	cx, bp
		mov	di, es:[bx].VTI_text
		mov	di, es:[di]
		clr	dx
		
		lodsb
	;
	; Check for leading minus. It's ok so long as we're inserting at
	; the front and there's not a minus there that'll stay there.
	;
		cmp	al, '-'
		jne	haveChar
		
EC <		tst	es:[bx].VTI_selectStart.high	;>
EC <		ERROR_NZ	SELECTION_TOO_LARGE	;>
		cmp	es:[bx].VTI_selectStart.low, 0
		jne	error

		cmp	di, -1		; if no text
		je	nextChar	;  check the whole buffer
		cmp	{char}es:[di], al
		jne	nextChar
EC <		tst	es:[bx].VTI_selectEnd.high	;>
EC <		ERROR_NZ	SELECTION_TOO_LARGE	;>
		cmp	es:[bx].VTI_selectEnd.low, 1
		jae	nextChar	; => '-' would be nuked by the paste, so
					;  it's ok.
error:
		clr	bp		; signal rejection of whole thing
		jmp	done		; and bail

checkLoop:
		lodsb
haveChar:
	;
	; Numeric?
	;
		cmp	al, '0'
		jb 	checkDecimal
		cmp	al, '9'
		ja	error
nextChar:
		loop	checkLoop
		jmp	done

checkDecimal:
	;
	; Check for decimal point in the pasted text.
	;
		cmp	al, ah
		jne	error		; anything other than 0-9 or . is
					;  bullshit

		xor	dx, -1		; flag presence and check for already
					;  having had one in this text. (can't
					;  use NOT b/c that doesn't affect the
					;  flags)
		jz	error		; already had one '.', thanks

		cmp	di, -1
		je	nextChar	; can't be a '.' in the existing text
					;  yet b/c there is no existing text
	;
	; Look for an already-existing decimal point in the text. If it's in
	; the current selection, it's ok.
	; 
		DoPush	di, cx
		ChunkSizePtr	es, di, cx
		
		repne	scasb
		xchg	ax, di
		DoPopRV	di, cx
		jne	nextChar
	;
	; There's a '.' in the text already. See if it'll get biffed by the
	; paste. If so, we're happy; if not, heads will roll.
	; 
		stc			; di was one beyond the '.'
		sbb	ax, di		; ax <- offset into the text
EC <		tst	es:[bx].VTI_selectStart.high	;>
EC <		ERROR_NZ	SELECTION_TOO_LARGE	;>
		cmp	ax, es:[bx].VTI_selectStart.low
		jb	error		; => before selection, so choke
EC <		tst	es:[bx].VTI_selectEnd.high	;>
EC <		ERROR_NZ	SELECTION_TOO_LARGE	;>
		cmp	ax, es:[bx].VTI_selectEnd.low
		jae	error		; => after selection, so die
		jmp	nextChar
done:
		.leave
		ret
CalcDisplayFilterTransfer endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplayScanShortcuts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the keyboard event maps to one of the shortcuts
		bound into the display.

CALLED BY:	CalcDisplayKbdChar
PASS:		*ds:si	= instance data
		ds:bx	= CalcDisplayBase
		ds:di	= CalcDisplayInstance
		cx	= char value
		dl	= CharFlags
				CF_RELEASE - set if release
				CF_STATE - set if shift, ctrl, etc.
				CF_TEMP_ACCENT - set if accented char pending
		dh 	= ShiftState
		bp low 	= ToggleState (unused)
		bp high = scan code (unused)
RETURN:		carry set if shortcut found and processed
DESTROYED:	di always, nothing else if shortcut not found, else
		ax, bx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDisplayScanShortcuts proc	near
		class	CalcDisplayClass
		.enter
	;
	; See if the character is one of the shortcuts defined for the display.
	;
		mov	di, ds:[di].CD_shortcuts
		tst	di
		jz	done		; no shortcuts defined
		;
		; Figure end of array for loop
		;
		mov	di, ds:[di]
		ChunkSizePtr	ds, di, ax
		add	ax, di
scanLoop:
		cmp	cx, ds:[di].CDS_char	; Character matches?
		je	haveShort
		add	di, size CDShortcut
		cmp	di, ax
		jb	scanLoop
		mov	ax, MSG_KBD_CHAR
		jmp	done

haveShort:
	;
	; Found a matching shortcut. We handle the thing by sending a
	; MSG_GEN_ACTIVATE to the trigger bound to the shortcut.
	;
		test	dl, mask CF_RELEASE	; Don't invoke shortcut on
		jnz	doneProcessed		;  release, thanks.
		mov	si, ds:[di].CDS_trigger.chunk
		mov	bx, ds:[di].CDS_trigger.handle
		mov	ax, MSG_GEN_ACTIVATE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
doneProcessed:
		stc
done:
		.leave
		ret
CalcDisplayScanShortcuts endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplayClearPending
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the display as needing clearing on the next input

CALLED BY:	MSG_CD_CLEAR_PENDING
PASS:		*ds:si	= instance data
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDisplayClearPending	method dynamic CalcDisplayClass, MSG_CD_CLEAR_PENDING
		.enter
		mov	ds:[di].CD_clearPending, BB_TRUE
		mov	ds:[di].CD_resetCount, CD_RESET_START	; some operation
							;  performed, so
							;  reset the resetCount
		.leave
		ret
CalcDisplayClearPending endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplayClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the display

CALLED BY:	MSG_CD_CLEAR
PASS:		*ds:si	= instance data
RETURN:		Nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nullString	char	0
CalcDisplayClear method	dynamic CalcDisplayClass, MSG_CD_CLEAR
		.enter
		mov	ds:[di].CD_clearPending, BB_FALSE
		dec	ds:[di].CD_resetCount
		jnz	clearDisplay

	;
	; Reset counter went to zero => C/CE hit twice w/o intervening operation
	; so tell the engine to reset itself.
	;
		mov	ds:[di].CD_resetCount, CD_RESET_START
		push	si
		mov	ax, MSG_CE_RESET
		mov	si, ds:[di].CD_engine.chunk
		mov	bx, ds:[di].CD_engine.handle
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si

clearDisplay:
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		mov	dx, cs
		mov	bp, offset nullString
		clr	cx		; Null-terminated
		call	ObjCallInstanceNoLock

		.leave
		ret
CalcDisplayClear endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplayRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the currently displayed value into a DDFixed

CALLED BY:	MSG_CD_READ
PASS:		*ds:si	= instance
		cx	= non-zero if display should clear itself on
			  next keystroke
		ds:bx	= CalcDisplayBase
		ds:di	= CalcDisplayInstance
		es	= dgroup
RETURN:		carry clear if the number is in error, else
		ax:cx:dx:bp = number read
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDisplayRead	method	dynamic CalcDisplayClass, MSG_CD_READ
temp		local	DDFixed
		.enter
	;
	; Set clearPending if told to
	;
		jcxz	noClearPending
		mov	ds:[di].CD_clearPending, BB_TRUE
		mov	ds:[di].CD_resetCount, CD_RESET_START	; some operation
							;  performed, so
							;  reset the resetCount
noClearPending:
	;
	; Call ourselves to get the text into a local chunk
	;
		add	bx, ds:[bx].Gen_offset
		mov	si, ds:[bx].GTDI_text
		ChunkSizeHandle	ds, si, cx
		jcxz	error
	;
	; Now convert to DDFixed
	;
		mov	al, es:[decimalPoint]
		segmov	es, ss, di
		lea	di, ss:[temp]
		mov	si, ds:[si]	; ds:si = string
		call	CalcAToF	; convert ds:si -> es:di
		jc	error		; overflow...
	;
	; Signal our happiness with the number
	;
		stc
		mov	ax, temp.DDF_frac.low
		mov	ss:[bp], ax	; Return bp = low fraction
		mov	dx, temp.DDF_frac.high
		mov	cx, temp.DDF_int.low
		mov	ax, temp.DDF_int.high
done:
		.leave
		ret
error:
		clc
		jmp	done
CalcDisplayRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplayWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format the fixed-point number at CX:DX and display it in
		ourselves.

CALLED BY:	MSG_CD_WRITE
PASS:		*ds:si	= instance
		cx:dx	= DDFixed to be displayed
		ds:bx	= CalcDisplayBase
		ds:di	= CalcDisplayInstance
		es	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDisplayWrite method	dynamic CalcDisplayClass, MSG_CD_WRITE
numBuf		local	MAX_NUM_LENGTH dup(char)
		.enter
	;
	; Convert the number to ascii in our local variable.
	;
		push	ds
		mov	bx, dx			; ds:bx = number to convert
		mov	dx, ds:[di].CD_precision
		mov	ds, cx
		mov	cx, dx			; cx = max precision for
						;  conversion
		mov	al, es:[decimalPoint]
		segmov	es,ss,di		; es:di = string storage
		lea	di, ss:[numBuf]
		call	CalcFToA
		pop	ds
	;
	; Now send ourselves a SET_TEXT method to put the string up.
	;
		push	bp
		mov	dx, ss
		lea	bp, numBuf		; dx:bp = text
		clr	cx			; cx = 0 => null-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL
		call	ObjCallInstanceNoLock
		pop	bp
		.leave
		ret
CalcDisplayWrite endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplaySetPrecision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the maximum number of decimal places to display

CALLED BY:	MSG_CD_SET_PRECISION
PASS:		*ds:si	= display instance
		ds:bx	= CalcDisplayBase
		ds:di	= CalcDisplayInstance
		cx	= precision to use
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDisplaySetPrecision method	dynamic CalcDisplayClass,
					MSG_CD_SET_PRECISION
		.enter
		mov	ds:[di].CD_precision, cx
		mov	ds:[di].CD_resetCount, CD_RESET_START
		.leave
		ret
CalcDisplaySetPrecision endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplayChangeSign
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert the sign of the currently-displayed number

CALLED BY:	MSG_CD_CHANGE_SIGN
PASS:		*ds:si	= display object
		ds:bx	= CalcDisplayBase
		ds:di	= CalcDisplayInstance
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
minusSign	char	'-'		; For inserting - at beginning
CalcDisplayChangeSign method	dynamic CalcDisplayClass, MSG_CD_CHANGE_SIGN
params		local	VisTextReplaceParameters
		.enter
	;
	; Fetch the current text so we can decide whether to add or remove
	; the sign.
	;
		add	bx, ds:[bx].Gen_offset
		mov	bx, ds:[bx].GTDI_text
		ChunkSizeHandle	ds, bx, cx
		dec	cx
		jz	done			; Do nothing on empty object

		mov	bx, ds:[bx]
	;
	; Don't change sign if display contains 0 (-0 generates an error)
	; or Error (looks funny).
	; XXX: This only handles the simple case where the display contains
	; only '0'. It won't handle obnoxious cases like '0.00000', but anyone
	; putting that in deserves to get an Error...
	; 
		cmp	{char}ds:[bx], 'E'
		je	done
		cmp	{char}ds:[bx], '0'
		jne	setParams
		dec	cx
		jz	done		; => only '0' so no sign change
setParams:
	;
	; Initialize params no matter what we're doing. Always changing position
	; 0 and want always to point to the minusSign given above.
	;
		mov	ss:[params].VTRP_textReference.TR_type, TRT_POINTER
		mov	ss:[params].VTRP_textReference.TR_ref.TRU_pointer.\
					TRP_pointer.segment, cs
		mov	ss:[params].VTRP_textReference.TR_ref.TRU_pointer.\
					TRP_pointer.offset, offset minusSign
		clr	ax
		mov	ss:[params].VTRP_insCount.high, ax
		clrdw	ss:[params].VTRP_range.VTR_start, ax
		clrdw	ss:[params].VTRP_range.VTR_end, ax

		mov	dx, 1		; dx = ins count (assume adding -)

		cmp	{char}ds:[bx], '-'
		jne	doReplace
		xchg	ax, dx		; Nope. delete char instead
doReplace:
		mov	ss:[params].VTRP_range.VTR_end.low, ax
		mov	ss:[params].VTRP_insCount.low, dx

		push	bp
		add	bp, offset params
		mov	ax, MSG_VIS_TEXT_REPLACE_NEW
		call	ObjCallInstanceNoLock
		pop	bp
		
done:
		.leave
		ret
CalcDisplayChangeSign		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplayPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field a MSG_PASTE so we can clear the display if necessary

CALLED BY:	MSG_PASTE
PASS:		ds:di	= CalcDisplayInstance
		*ds:si	= CalcDisplay object
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/24/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDisplayPaste method	dynamic CalcDisplayClass, MSG_PASTE
		.enter
		call	CDCheckClearPending
		
		mov	ax, MSG_PASTE
		mov	di, offset CalcDisplayClass
		CallSuper	MSG_PASTE
		.leave
		ret
CalcDisplayPaste endp

Main		ends
