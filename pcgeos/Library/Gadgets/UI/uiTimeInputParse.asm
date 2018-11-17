COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Jedi
MODULE:		Gadgets Library
FILE:		uiTimeInputParse.asm

AUTHOR:		Jacob A. Gabrielson, Jan 24, 1995

ROUTINES:
	Name			Description
	----			-----------
    INT TimeInputParseString    Parse a time string, completing it if
				needed.

    INT TimeParseCallParser     Find the proper transition for the current
				input, and take it, if found.

    INT TPInsertSelf            Insert the character under scrutiny into
				the output string.

    INT TPInsertSep             Insert the system date/time separator.

    INT TPInsertSepSelf         Insert <SEP> then curChar.

    INT TPInsertZero            Insert a zero.

    INT TPInsertZeroSelf        Name says it all.

    INT TPInsertZeroSep         Name says it all.

    INT TPInsertSepZeroSelf     Name says it all.

    INT TPInsertZeroAMPM        Insert "0" plus "am" or "pm", depending on
				what curChar is.

    INT TPInsertZeroZeroAMPM    Name says it all.

    INT TPInsertSepZeroZeroAMPM Name says it all.

    INT TPDoNothing             Do nothing.

    INT TimeParseIsSep          See if curChar is a valid time separator.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/24/95   	Initial revision


DESCRIPTION:
	These are a bunch of routines to parse times the Jedi Way.
	It's not super-localizable, but this is what the ERS wants.
	I did use the localization macros anyway, though, because
	they're convenient.


	$Id: uiTimeInputParse.asm,v 1.1 97/04/04 17:59:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TimeParseInput		record
; Represents all the legal things the user can type in.

	:2
	TPI_NEG_SIGN:1=0
	TPI_M:1=0
	TPI_AP:1=0
	TPI_SEP:1=0
	TPI_9:1=0
	TPI_8:1=0
	TPI_7:1=0
	TPI_6:1=0
	TPI_5:1=0
	TPI_4:1=0
	TPI_3:1=0
	TPI_2:1=0
	TPI_1:1=0
	TPI_0:1=0

TimeParseInput		end

TPI_ILLEGAL	equ	0

.assert (offset TPI_0) eq 0			; code relies on this fact
.assert (offset TPI_1) eq 1			; etc...

T0	equ	(mask TPI_0)
T1	equ	(mask TPI_1)
T2	equ	(mask TPI_2)
T3	equ	(mask TPI_3)
T4	equ	(mask TPI_4)
T5	equ	(mask TPI_5)
T6	equ	(mask TPI_6)
T7	equ	(mask TPI_7)
T8	equ	(mask TPI_8)
T9	equ	(mask TPI_9)
SEP	equ	(mask TPI_SEP)
AP	equ	(mask TPI_AP)
EM	equ	(mask TPI_M)
NEG_SIGN equ    (mask TPI_NEG_SIGN)

T0_TO_3	equ	(T0 or T1 or T2 or T3)
T0_TO_5	equ	(T0 or T1 or T2 or T3 or T4 or T5)
T0_TO_9	equ	(T0 or T1 or T2 or T3 or T4 or T5 or T6 or T7 or T8 or T9)
T3_TO_9	equ	(T3 or T4 or T5 or T6 or T7 or T8 or T9)
T6_TO_9	equ	(T6 or T7 or T8 or T9)

ANY_INPUT	equ	0xffff

TimeParseTransition	struct
; Represents an edge in the timeMachine state machine.

	TPT_input	TimeParseInput			TPI_ILLEGAL
	; Digits this transition should be taken on.

	TPT_state	nptr.TimeParseTransition	NULL
	; State to move into.

	TPT_function	nptr.near			NULL
	; Function to call when moving to state TPT_state.

TimeParseTransition	ends

CommonCode	segment resource

;--------------------------------
;	Parse time of day
;--------------------------------

; No text has been entered yet.
tmEmpty			TimeParseTransition \
	<T0 or T1,	tm0To1,		TPInsertSelf>,
	<T2,		tm2,		TPInsertSelf>,
	<T3_TO_9,	tm2Chars,	TPInsertSelf>,
	<TPI_ILLEGAL,	NULL,		NULL>

; The text is: "[01]".
tm0To1			TimeParseTransition \
	<T0_TO_9,	tm2Chars,	TPInsertSelf>,
	<SEP,		tmSep,		TPInsertSep>,
	<AP,		tmNeedM,	TPInsertSelf>,
	<TPI_ILLEGAL,	NULL,		NULL>

; "2".
tm2			TimeParseTransition \
	<T0_TO_3,	tm2Chars,	TPInsertSelf>,
	<T4 or T5,	tm3Chars,	TPInsertSepSelf>,
	<T6_TO_9,	tm4Chars,	TPInsertSepZeroSelf>,
	<SEP,		tmSep,		TPInsertSep>,
	<AP,		tmNeedM,	TPInsertSelf>,
	<TPI_ILLEGAL,	NULL,		NULL>

; "[3-9]" or "[0-2][0-3]" or "[0-1][0-9]".
tm2Chars		TimeParseTransition \
	<T0_TO_5,	tm3Chars,	TPInsertSepSelf>,
	<T6_TO_9,	tm4Chars,	TPInsertSepZeroSelf>,
	<SEP,		tmSep,		TPInsertSep>,
	<AP,		tmNeedM,	TPInsertSelf>,
	<TPI_ILLEGAL,	NULL,		NULL>

; Anything from tm2 followed by a separator, or "[01]<SEP>".
tmSep			TimeParseTransition \
	<T0_TO_5,	tm3Chars,	TPInsertSelf>,
	<T6_TO_9,	tm4Chars,	TPInsertZeroSelf>,
	<AP,		tmNeedM,	TPInsertSelf>,
	<TPI_ILLEGAL,	NULL,		NULL>

; Anything from tmSep plus "[0-5]".
tm3Chars		TimeParseTransition \
	<T0_TO_9,	tm4Chars,	TPInsertSelf>,
	<AP,		tmNeedM,	TPInsertSelf>,
	<TPI_ILLEGAL,	NULL,		NULL>

; The time is complete, unless we're in AM/PM mode, in which case
; the AM/PM has yet to be added. The user has to be able to backspace
; over the darn "m", though, without it being re-expanded.  Sigh.
tm4Chars		TimeParseTransition \
	<AP,		tmNeedM,	TPInsertSelf>,
	<TPI_ILLEGAL,	NULL,		NULL>

; A stupid state where there's a trailing "a" but no "m".
tmNeedM			TimeParseTransition \
	<EM,		tmAPComplete,	TPInsertSelf>,
	<TPI_ILLEGAL,	NULL,		NULL>

; The time is complete (in AM/PM mode).  Accept "M" in this state
; because otherwise some weird cases won't work.  But don't print it!
tmAPComplete		TimeParseTransition \
	<EM,		tmAPComplete,	TPDoNothing>,
	<TPI_ILLEGAL,	NULL,		NULL>	; nothing is legal

;--------------------------------
;	Parse time of day, with much relaxed rules
;--------------------------------

tmrStart		TimeParseTransition \
	<SEP,		tmrStart,	TPInsertSep>,
	<T0_TO_9,	tmrStart,	TPInsertSelf>,
	<AP,		tmrStart,	TPInsertSelf>,
	<EM,		tmrStart,	TPInsertSelf>,
	<TPI_ILLEGAL,	NULL,		NULL>

;--------------------------------
;	Parse time interval
;--------------------------------

iStart			TimeParseTransition \
	<T0_TO_9,	iStart,		TPInsertSelf>,
	<SEP,		iSep,		TPInsertSep>,
	<TPI_ILLEGAL,	NULL,		NULL>

iSep			TimeParseTransition \
	<T0_TO_9,	iSep,		TPInsertSelf>,
	<TPI_ILLEGAL,	NULL,		NULL>

;--------------------------------
;	Parse time offset
;--------------------------------

; No text has been entered yet.
oStart			TimeParseTransition \
	<NEG_SIGN,	oValStart,	TPInsertSelf>
		; A hack to save bytes.  We use the transition entries in
		; oValStart as the tail of the oStart table.
		.assert	$ eq oValStart

; "-".
oValStart		TimeParseTransition \
	<T0 or T1,	o0To1,		TPInsertSelf>,
	<T2,		o2,		TPInsertSelf>,
	<T3_TO_9,	o2Chars,	TPInsertSelf>,
	<TPI_ILLEGAL,	NULL,		NULL>

; The text is: "\-?[01]".
o0To1			TimeParseTransition \
	<T0_TO_9,	o2Chars,	TPInsertSelf>,
	<SEP,		oSep,		TPInsertSep>,
	<TPI_ILLEGAL,	NULL,		NULL>

; "\-?2".
o2			TimeParseTransition \
	<T0_TO_3,	o2Chars,	TPInsertSelf>,
	<T4 or T5,	o3Chars,	TPInsertSepSelf>,
	<T6_TO_9,	oComplete,	TPInsertSepZeroSelf>,
	<SEP,		oSep,		TPInsertSep>,
	<TPI_ILLEGAL,	NULL,		NULL>

; "\-?[3-9]" or "\-?2[0-3]" or "\-?[0-1][0-9]".
o2Chars			TimeParseTransition \
	<T0_TO_5,	o3Chars,	TPInsertSepSelf>,
	<T6_TO_9,	oComplete,	TPInsertSepZeroSelf>,
	<SEP,		oSep,		TPInsertSep>,
	<TPI_ILLEGAL,	NULL,		NULL>

; Anything valid followed by a separator.
oSep			TimeParseTransition \
	<T0_TO_5,	o3Chars,	TPInsertSelf>,
	<T6_TO_9,	oComplete,	TPInsertZeroSelf>,
	<TPI_ILLEGAL,	NULL,		NULL>

; Anything from oSep plus "[0-5]".
o3Chars			TimeParseTransition \
	<T0_TO_9,	oComplete,	TPInsertSelf>
		; A hack to save bytes.  We use the only transition entry in
		; oComplete to mark the end of the o3Chars table.
		.assert	$ eq oComplete

; The time offset is complete.
oComplete		TimeParseTransition \
	<TPI_ILLEGAL,	NULL,		NULL>	; nothing is legal

;--------------------------------
;	Parse dates
;--------------------------------

if 0
dStart			TimeParseTransition \
	<T0_TO_9,	d1Char,		TPDoNothing>,
	<TPI_ILLEGAL,	NULL,		NULL>

d1Char			TimeParseTransition \
	<T0_TO_9,	d2Chars,	TPDoNothing>,
	<SEP,		d1Sep,		TPDoNothing>,
	<TPI_ILLEGAL,	NULL,		NULL>

d2Chars			TimeParseTransition \
	<SEP,		d1Sep,		TPDoNothing>,
	<TPI_ILLEGAL,	NULL,		NULL>

d1Sep			TimeParseTransition \
	<T0_TO_9,	d3Chars,	TPDoNothing>,
	<TPI_ILLEGAL,	NULL,		NULL>

d3Chars			TimeParseTransition \
	<T0_TO_9,	d4Chars,	TPDoNothing>,
	<SEP,		d2Sep,		TPDoNothing>,
	<TPI_ILLEGAL,	NULL,		NULL>

d4Chars			TimeParseTransition \
	<SEP,		d2Sep,		TPDoNothing>,
	<TPI_ILLEGAL,	NULL,		NULL>

d2Sep			TimeParseTransition \
	<T0_TO_9,	d5Chars,	TPDoNothing>,
	<TPI_ILLEGAL,	NULL,		NULL>

d5Chars			TimeParseTransition \
	<T0_TO_9,	d6Chars,	TPDoNothing>,
	<TPI_ILLEGAL,	NULL,		NULL>

d6Chars			TimeParseTransition \
	<TPI_ILLEGAL,	NULL,		NULL>

;--------------------------------
;	Parse dates with relaxed rules
;--------------------------------

drStart			TimeParseTransition \
	<ANY_INPUT,	drStart,	TPDoNothing>,
	<TPI_ILLEGAL,	NULL,		NULL>

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimeInputParseString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a time string, completing it if needed.

CALLED BY:	(INTERNAL) DITVisTextFilterViaBeforeAfter,
		TITVisTextFilterViaBeforeAfter
PASS:		ds:si	= string to check (null-terminated)
		es:di	= buffer to fill in with new string
		al	= non-zero if "[apm]" legal
		bx	= offset to start state (nptr.TimeParseTransition)
		dx	= TimeInputType to use
RETURN:		carry set if string in ds:si is no good
			es:di = a string which you should ignore
		carry clear if string in ds:si is valid
			es:di = a string which should now go in the
				text object (null-terminated)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimeInputParseString	proc	near
		uses	ax, bx, cx, dx, di, si
ampmMode	local	BooleanByte
	; non-zero if "[apm]" legal
curChar		local	TCHAR
	; character under scrutiny
state		local	nptr.TimeParseTransition
	; keeps track of which node of the state machine we're in
		.enter

		Assert	fptr esdi
		Assert	fptr dssi

	;
	; Set up am/pm flag.
	;
		mov	ss:ampmMode, al

	;
	; Set up start state.
	;
		mov	ss:state, bx

	;
	; Parse all characters of the input string, one at a time.
	;
parseLoop:		
		LocalGetChar ax, dssi
		clr	ah			; this is annoying!
		LocalIsNull ax			; hit end of string?
		jz	parseOK
SBCS <		mov	ss:curChar, al					>
DBCS <		mov	ss:curChar, ax					>
	;
	; Call parse routine to verify that character is okay.
	;
		call	TimeParseCallParser	; carry set if ds:si is illegal
		jc	parseBad
		jmp	parseLoop
		
	;
	; The string in ds:si parsed okay.  The version to actually
	; put in the text object, though, is in es:di.  We need to
	; null-terminate it.
	;
parseOK:
		LocalClrChar	es:[di]
		clc				; signal good string

parseBad:
		
		.leave
		ret
TimeInputParseString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimeParseCallParser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the proper transition for the current input,
		and take it, if found.

CALLED BY:	(INTERNAL) TimeInputParseString
PASS:		ss:bp	= inherited stack frame
		ax	= character under scrutiny
RETURN:		carry set if ds:si is a bad string
		carry clear if it's okay so far
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimeParseCallParser	proc	near
		uses	ax, bx, cx
		.enter	inherit TimeInputParseString
	;
	; Is it a digit?  
	;
		call	LocalIsDigit
	LONG_EC	jz	notDigit

	;
	; Convert ASCII digit to number (taken from UtilHex32BlahBlah).
	;
SBCS <		sub	al, '0'			; turn into a number	>
SBCS <		clr	ah						>
DBCS <		sub	ax, '0'			; turn into a number	>
		Assert	be ax 9			; ensure we have a digit
	;
	; Convert number into 1 shl'd the proper amount.  E.g. 1 -> 010b.
	; 2 -> 0100b.
	;
		mov	cl, al
		mov	ax, 1
		shl	ax, cl			; ax <- TimeParseInput (really)

	;
	; Search for appropriate transition.
	;
searchForTransition:		
		mov	bx, ss:state
searchLoop:
	;
	; If TPT_state is NULL, then that means the current digit is
	; illegal, because no transition matched it.
	;
		tst_clc	cs:[bx].TPT_state
		jz	illegalChar		; carry will be reversed
		test	ax, cs:[bx].TPT_input
		jnz	transitionFound
		add	bx, size TimeParseTransition
		jmp	searchLoop

	;
	; The transition has been found.  Take it.
	;
transitionFound:
		call	cs:[bx].TPT_function	; call action function
		mov	cx, cs:[bx].TPT_state
		mov	ss:state, cx		; state <- new state
		stc				; carry will be reversed

illegalChar:
		cmc

		.leave
		ret
	;
	; If it's not a digit, then it might be the time separator.
	;
notDigit:

	;
	; If we're in a TimeOffset mode, the negitive sign is legal
	; and is not used as a separator.
	; Check to see if it's a negitve sign.  
	;
		cmp	dx, TIT_TIME_OFFSET
		jnz	checkIsSeparator

		mov_tr	cx, ax			; cx <- passed character
		cmp	cx, C_MINUS
		mov	ax, NEG_SIGN
		je	searchForTransition
		mov_tr	ax, cx			; ax <- passed character

checkIsSeparator:
		call	TimeParseIsSep		; z set if SEP
		mov	ax, SEP			; assume it is SEP
	LONG_EC	je	searchForTransition

	;
	; If it's not the separator, then it could only be "[apm]".
	; See if that's even legal.
	;
		tst_clc	ss:ampmMode
		jz	illegalChar

	;
	; Since it's not the separator, the only other possibility is that
	; it might be "a" or "p" or "m".
	;
SBCS <		mov	al, curChar					>
SBCS <		clr	ah						>
DBCS <		mov	ax, curChar					>
		call	LocalDowncaseChar	; ax <- downcased
SBCS <		mov	curChar, al		; always insert upcase	>
DBCS <		mov	curChar, ax		; always insert upcase	>
		mov	bx, ax
		LocalCmpChar bx, C_SMALL_A
		mov	ax, AP
	LONG_EC	je	searchForTransition
		LocalCmpChar bx, C_SMALL_P
	LONG_EC	je	searchForTransition
		LocalCmpChar bx, C_SMALL_M
		mov	ax, EM
	LONG_EC	je	searchForTransition
	;
	; It's not an "a", "p" or "m", so it must be invalid.
	;
		clc				; carry will be reversed
		jmp	illegalChar
TimeParseCallParser	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TPInsertSelf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert the character under scrutiny into the output
		string.

CALLED BY:	(INTERNAL) TPInsertSepSelf, TPInsertSepZeroSelf,
		TPInsertZeroSelf
PASS:		ss:bp	= inherited stack frame
		es:di	= pointer to next char to insert over in
			  output string
RETURN:		es:di	= updated to point at new end-of-string
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TPInsertSelf	proc	near
		uses	ax
		.enter	inherit TimeInputParseString

		LocalGetChar ax, ss:curChar, NO_ADVANCE
		LocalPutChar esdi, ax

		.leave
		ret
TPInsertSelf	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TPInsertSep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert the system date/time separator.

CALLED BY:	(INTERNAL) TPInsertSepSelf, TPInsertSepZeroSelf,
		TPInsertSepZeroZeroAMPM
PASS:		see TPInsertSelf
RETURN:		see TPInsertSelf
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TPInsertSep	proc	near
		uses	ax
		.enter inherit TimeInputParseString

		call	GetSystemTimeSeparator	; ax <- time separartor
		LocalPutChar esdi, ax
		
		.leave
		ret
TPInsertSep	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TPInsertSepSelf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert <SEP> then curChar.

CALLED BY:	(INTERNAL)
PASS:		see TPInsertSelf
RETURN:		see TPInsertSelf
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TPInsertSepSelf	proc	near
		.enter inherit TimeInputParseString

		call	TPInsertSep
		call	TPInsertSelf
		
		.leave
		ret
TPInsertSepSelf	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TPInsertZero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a zero.

CALLED BY:	(INTERNAL) TPInsertSepZeroSelf, TPInsertZeroAMPM,
		TPInsertZeroSelf, TPInsertZeroZeroAMPM
PASS:		see TPInsertSelf
RETURN:		see TPInsertSelf
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TPInsertZero	proc	near
		uses	ax
		.enter inherit TimeInputParseString

SBCS <		clr	ax						>
SBCS <		mov	al, '0'						>
DBCS <		mov	ax, '0'						>
		LocalPutChar esdi, ax

		.leave
		ret
TPInsertZero	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TPInsertZeroSelf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Name says it all.

CALLED BY:	(INTERNAL)
PASS:		see TPInsertSelf
RETURN:		see TPInsertSelf
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TPInsertZeroSelf	proc	near
		.enter inherit TimeInputParseString

		call	TPInsertZero
		call	TPInsertSelf
		
		.leave
		ret
TPInsertZeroSelf	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TPInsertSepZeroSelf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Name says it all.

CALLED BY:	(INTERNAL)
PASS:		see TPInsertSelf
RETURN:		see TPInsertSelf
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TPInsertSepZeroSelf	proc	near
		.enter inherit TimeInputParseString

		call	TPInsertSep
		call	TPInsertZero
		call	TPInsertSelf

		.leave
		ret
TPInsertSepZeroSelf	endp
if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TPInsertZeroAMPM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert "0" plus "am" or "pm", depending on what
		curChar is.

CALLED BY:	(INTERNAL) TPInsertZeroZeroAMPM
PASS:		see TPInsertSelf
RETURN:		see TPInsertSelf
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TPInsertZeroAMPM	proc	near
		uses	ax
		.enter inherit TimeInputParseString 

		call	TPInsertZero

	;
	; Insert curChar, then an "M".
	;
SBCS <		mov	al, ss:curChar					>
DBCS <		mov	ax, ss:curChar					>
		LocalPutChar esdi, ax
SBCS <		mov	al, C_SMALL_M					>
DBCS <		mov	ax, C_SMALL_M					>
		LocalPutChar esdi, ax

		.leave
		ret
TPInsertZeroAMPM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TPInsertZeroZeroAMPM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Name says it all.

CALLED BY:	(INTERNAL) TPInsertSepZeroZeroAMPM
PASS:		see TPInsertSelf
RETURN:		see TPInsertSelf
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TPInsertZeroZeroAMPM	proc	near
		.enter inherit TimeInputParseString

		call	TPInsertZero
		call	TPInsertZeroAMPM
		
		.leave
		ret
TPInsertZeroZeroAMPM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TPInsertSepZeroZeroAMPM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Name says it all.

CALLED BY:	(INTERNAL)
PASS:		see TPInsertSelf
RETURN:		see TPInsertSelf
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TPInsertSepZeroZeroAMPM	proc	near
		.enter inherit TimeInputParseString

		call	TPInsertSep
		call	TPInsertZeroZeroAMPM
		
		.leave
		ret
TPInsertSepZeroZeroAMPM	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TPDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing.

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TPDoNothing	proc	near
		.enter
		.leave
		ret
TPDoNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimeParseIsSep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if curChar is a valid time separator.

CALLED BY:	(INTERNAL) TimeParseCallParser
PASS:		ss:bp	= inherit stack frame
RETURN:		z clear if it's a valid separator
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimeParseIsSep	proc	near
		uses	ax, bx, cx
		.enter inherit TimeInputParseString

SBCS <		mov	al, ss:curChar					>
DBCS <		mov	ax, ss:curChar					>

	;
	; Compare curChar to all the possible time separators.
	;
		mov	cx, size timeSeparators
compareToAll:
		dec	cx
DBCS <		dec	cx						>
		mov	bx, cx
SBCS <		cmp	al, cs:[timeSeparators][bx]			>
DBCS <		cmp	ax, cs:[timeSeparators][bx]			>
	;
	; Exit the loop if we've found that it is a time separator.
	;
		je	exit
	;
	; Exit if that was the last possible time separator.
	;
		jcxz	exit
		jmp	compareToAll

exit:
		.leave
		ret
TimeParseIsSep	endp

timeSeparators		TCHAR \
			C_SLASH,
			C_MINUS,
			C_COMMA,
			C_PERIOD,
			C_COLON,
			C_SEMICOLON

CommonCode	ends
