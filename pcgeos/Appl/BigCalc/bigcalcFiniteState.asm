COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcFiniteState.asm

AUTHOR:		Christian Puscasiu, May 15, 1992

ROUTINES:
	Name			Description
	----			-----------
	InputFieldCheckIfValidFPNumber
				Checks if we are on our way to a valid fp
				number.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/15/92		Initial revision
	witt	10/15/93	DBCS-ized strings and such..

DESCRIPTION:
	contains a FiniteStateMachine that makes sure that a number is
	a valid fp number or makes it into one...
		

	$Id: bigcalcFiniteState.asm,v 1.1 97/04/04 14:38:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%% DON'T NEED THIS FOR RESPONDER %%%%%%%%%%%%%%%%%%%%%%@


CalcCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputFieldCheckIfValidFPNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks if we are on our way to a valid fp number

CALLED BY:	all the objects that are subclasses of GenText when
		they are in the routine that handles
		MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER 
PASS:		ds:si	-- farptr to the string
		ss:bp	-- VisTextReplaceParameters
RETURN:		cx	-- position of the cursor after replacement
		carry set use the old number
		carry non set 
		   dx:bp    farptr to what the user probably meant
		   al/ax    first char/wchar in dx:bp
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputFieldCheckIfValidFPNumber	proc	near
	uses	bx,si,di,ds
	.enter

	mov	cx, ss:[bp].VTRP_range.VTR_start.low
	add	cx, ss:[bp].VTRP_insCount.low

	;
	; cx is the char position the cursor should be on
	;
	push	cx

	;	
	; save initial si
	;
	mov	bp, si			; gunna return original si value.

	segmov	es, cs

SBCS<	clr	ah							>
nextChar:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	modifyString

	;
	; we have to check for e/E seperatly because they are not
	; inclduded in the LocalIsNumChar
	;
	LocalCmpChar	ax, 'e'
	je	nextChar
	LocalCmpChar	ax, 'E'
	je	nextChar

	;
	; this checks for the local conventions of what numbers can
	; look like
	;
	call	LocalIsNumChar
	jz	invalidChar
	jmp	nextChar

modifyString:
	;
	; If this code is reached I know that there are no illegal
	; characters in the string, so the user just hit two decimal
	; points or did something wrong (with the right chars) so I
	; have to fixup the string "by hand".  To do this I have to
	; put it into the textbuffer in dgroup:textBuffer so I can
	; manipulate the string
	;
	; retrive the string in ds:si
	;
	mov	si, bp

	;
	; set up es:di to be dgroup:textBuffer
	;
	GetResourceSegmentNS	dgroup, es
	mov	di, offset textBuffer

	call	FiniteStateMachineForLegalFPNumbers
	pop	cx
	jnc	keepCursorPosition
	inc	cx
keepCursorPosition:
	clc
	jmp	getLength

invalidChar:
	pop	ax
	stc
	jmp	done

getLength:
SBCS <	mov	ah, al							>

	mov	ds, dx
	mov	si, bp

allString:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	recoverAL

	LocalCmpChar	ax, 'e'
	je	checkE0

	LocalCmpChar	ax, 'E'
	jne	allString

checkE0:
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, '0'
	jne	recoverAL

	add	cx, 1			; inc char position

recoverAL:
SBCS<	mov	al, ah							>
DBCS<	mov	ax, ds:[bp]		; first char in string		>
	clc

done:
	.leave
	ret
InputFieldCheckIfValidFPNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FiniteStateMachineForLegalFPNumbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks whether the string is legal, via a FSM that is
		run bye the FiniteStateTable

CALLED BY:	InputFieldCheckIfValidFPNumber
PASS:		ds:si	string where the input comes from
		es:di	buffer space
RETURN:		dx:bp	how the string you should look like
		al	the first cahracter in dx:bp
		carry -	set if extra character inserted (such as
			a '0' in front of entered '.')
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FiniteStateMachineForLegalFPNumbers	proc	near
	uses 	bx,cx,si,di
	.enter 

	;
	; bp will point to the the beginning of the destination string
	; throughout the whole parse
	;
	mov	bp, di

	;
	; start at state 0
	;
	clr	cx
	call	StateHandler		; carry set if cursor needs increment

	pushf
	clr	ax
	LocalPutChar	esdi, ax	; terminate `could be' string.

	mov	dx, es
	LocalLoadChar	ax, es:[bp]	; return first char.
	popf

	.leave
	ret
FiniteStateMachineForLegalFPNumbers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StateHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will go through the states 

CALLED BY:	FiniteStateMachineForLegalFPNumbers
PASS:		cx	initial state
		ds:si	initial string
		es:di	final string
		bp == di
RETURN:		di	 past last token written
		carry -  set if extra char inserted (so we'll
			 know to increment the cursor position).
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StateHandler	proc	near
	uses	bx,cx,dx,bp,es
	.enter

	CheckHack <InputToken eq 5>
	CheckHack <size FiniteStateTableEntryStruct eq 4>

SBCS<	clr	ah						>
repeat:
	;
	; get the character at ds:si
	;
	LocalGetChar	ax, dssi

	;
	; are we done??
	;
	pushf					; save flag from prev call
	LocalIsNull	ax
	jz	done

	;
	; what category is the character
	;
	popf					; pop saved carry flag
	call	GetInputToken

	;
	; compute the offset into the table:
	; size FiniteStateTableEntryStruct(==4) *
	;	[{curState(==cx) * NumberInputToken(==5)} + curToken(==dx)]
	;
	mov	bx, cx
	shl	bx
	shl	bx
	add	bx, cx
	add	bx, dx

	shl	bx
	shl	bx
	
	clc
	call	cs:[FiniteStateTable][bx].FSTES_rule
	
	mov	cx, cs:[FiniteStateTable][bx].FSTES_destination
	jmp	repeat

done:
	popf					; pop carry from call
	.leave
	ret
StateHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcGetDecimalChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the character to use for the decimal separator

CALLED BY:	UTILITY
PASS:		none
RETURN:		cx - character for decimal separator (normally ".")
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcGetDecimalChar		proc	near
	.enter

	push	ax, bx, dx
	call	LocalGetNumericFormat		;cx <- decimal separator
	pop	ax, bx, dx

	.leave
	ret
CalcGetDecimalChar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetInputToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gets the token associated with the character

CALLED BY:	StateHandler
PASS:		al/ax	= ASCII/Unicode char to inspect.
RETURN:		al	unchanged
		dx	InputToken
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetInputToken	proc	near
	uses	cx
	.enter

	call	CalcGetDecimalChar	; decimal point -> cx
	;
	; is it the '0'
	;
	LocalCmpChar	ax, '0'
	je	zero

	;
	; is it the decimal point?
	;
SBCS<	cmp	al, cl	>
DBCS<	cmp	ax, cx	>
	je	decimal

	;
	; is it a sign?
	;
	LocalCmpChar	ax, '-'
	je	signChar

	LocalCmpChar	ax, '+'
	je	signChar

	;
	; is it 'e' or 'E'
	;
	LocalCmpChar	ax, 'e'
	je	exp

	LocalCmpChar	ax, 'E'
	je	exp

	;
	; if it's none of the above it is 0..9
	;
	mov	dx, IT_DIGIT
	jmp	done

zero:
	mov	dx, IT_ZERO
	jmp	done

exp:
	mov	dx, IT_EXP
	jmp	done

signChar:
	mov	dx, IT_SIGN
	jmp	done

decimal:
	mov	dx, IT_DECIMAL

done:
	.leave
	ret
GetInputToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Rule...functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	the following functions fulfill the simple rules of
		the FiniteStateMachine

CALLED BY:	StateHandler
PASS:		es:di	farptr to the string that is being created
		bp	points to the beginning of the string
RETURN:		es:di	updated
		carry set - if character inserted (so we know
			to update the cursor position)
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RuleAccept	proc	near
	.enter
	;
	; accepts the character 
	;
	LocalPutChar	esdi, ax
	.leave
	ret
RuleAccept	endp

RuleDiscard	proc	near
	.enter
	;
	; not do anything
	;
	.leave
	ret
RuleDiscard	endp

RuleAcceptPlus0	proc	near
	.enter
	;
	; accept the current char
	;
	LocalPutChar	esdi, ax

	;
	; add a zero at the end
	;
	LocalLoadChar	ax, '0'
	LocalPutChar	esdi, ax
	stc
	.leave
	ret
RuleAcceptPlus0	endp

RuleMakeZeroPoint	proc	near
	uses	cx
	.enter
	;
	; reset the string to "0."
	;
	mov	di, bp
	LocalLoadChar	ax, '0'
	LocalPutChar	esdi, ax
	call	CalcGetDecimalChar
SBCS<	mov	al, cl	>
DBCS<	mov	ax, cx	>
	LocalPutChar	esdi, ax
	stc
	.leave
	ret
RuleMakeZeroPoint	endp

RuleBack1Accept	proc	near
	.enter
	;
	; goes one back and then writes the char
	;
	LocalPrevChar	esdi
	LocalPutChar	esdi, ax
	.leave
	ret
RuleBack1Accept	endp

RuleBack1AcceptPlus0	proc	near
	.enter
	;
	; move one back, accept the char, add a '0'
	;
	LocalPrevChar	esdi
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, '0'
	LocalPutChar	esdi, ax
	stc
	.leave
	ret
RuleBack1AcceptPlus0	endp

RuleBack2AcceptInc2	proc	near
	.enter
	;
	; backspace 2, accept, increment again
	;
	LocalPrevChar	esdi
	LocalPrevChar	esdi
	LocalPutChar	esdi, ax	
	;LocalNextChar	esdi  <-- from stosb
	LocalNextChar	esdi
	.leave
	ret
RuleBack2AcceptInc2	endp

RuleMake1E0	proc	near
	.enter
	;
	;just make a "1E/e0" string from scratch
	;
SBCS<	mov	ah, al		; save whether it was upper or lower e	>
DBCS<	push	ax		; save whether it was upper or lower e	>
	mov	di, bp
	LocalLoadChar	ax, '1'
	LocalPutChar	esdi, ax
SBCS<	mov	al, ah	>
DBCS<	pop	ax							>
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, '0'
	LocalPutChar	esdi, ax	
	stc
	.leave
	ret
RuleMake1E0	endp

RuleBack1Plus1E0	proc	near
	.enter
	;
	; move one back, accept the char, add a '0'
	;
	LocalPrevChar	esdi
SBCS<	mov	ah, al		; save whether upper or lower E		>
DBCS<	push	ax		; save whether upper or lower E		>
	LocalLoadChar	ax, '1'
	LocalPutChar	esdi, ax
SBCS<	mov	al, ah							>
DBCS<	pop	ax							>
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, '0'
	LocalPutChar	esdi, ax
	.leave
	ret
RuleBack1Plus1E0	endp


;****************************************************************************
; This table basically is the finite state machine, it is organized in
; such a way that we have think of it this way:
;
;CurState	Token		destination	Rule
;
; and we actually display only the <destination, rule> pair, because
; we can calculate the offset into the table from curstate and token
;
;****************************************************************************

FiniteStateTable	FiniteStateTableEntryStruct\
	<1, RuleAccept>,		; state 0, token 0
	<2, RuleAccept>,		; state 0, token 1..9
	<8, RuleAcceptPlus0>,		; state 0, token +/-
	<4, RuleMake1E0>,		; state 0, token E/e
	<3, RuleMakeZeroPoint>,		; state 0, token '.'
	<1, RuleDiscard>,		; state 1, token 0
	<2, RuleBack1Accept>,		; state 1, token 1..9
	<8, RuleBack1Accept>,		; state 1, token +/-
	<4, RuleMake1E0>,		; state 1, token E/e
	<3, RuleAccept>,		; state 1, token '.'
	<2, RuleAccept>,		; state 2, token 0
	<2, RuleAccept>,		; state 2, token 1..9
	<2, RuleDiscard>,		; state 2, token +/-
	<4, RuleAcceptPlus0>,		; state 2, token E/e
	<3, RuleAccept>,		; state 2, token '.'
	<5, RuleAccept>,		; state 3, token 0
	<5, RuleAccept>,		; state 3, token 1..9
	<3, RuleDiscard>,		; state 3, token +/-
	<4, RuleAcceptPlus0>,		; state 3, token E/e
	<3, RuleDiscard>,		; state 3, token '.'
	<4, RuleDiscard>,		; state 4, token 0
	<6, RuleBack1Accept>,		; state 4, token 1..9
	<7, RuleBack1AcceptPlus0>,	; state 4, token +/-
	<4, RuleDiscard>,		; state 4, token E/e
	<4, RuleDiscard>,		; state 4, token '.'
	<5, RuleAccept>,		; state 5, token 0
	<5, RuleAccept>,		; state 5, token 1..9
	<5, RuleDiscard>,		; state 5, token +/-
	<4, RuleAcceptPlus0>,		; state 5, token E/e
	<5, RuleDiscard>,		; state 5, token '.'
	<9, RuleAccept>,		; state 6, token 0
	<9, RuleAccept>,		; state 6, token 1..9
	<6, RuleDiscard>,		; state 6, token +/-
	<6, RuleDiscard>,		; state 6, token E/e
	<6, RuleDiscard>,		; state 6, token '.'
	<7, RuleDiscard>,		; state 7, token 0
	<6, RuleBack1Accept>,		; state 7, token 1..9
	<7, RuleBack2AcceptInc2>,	; state 7, token +/-
	<7, RuleDiscard>,		; state 7, token E/e
	<7, RuleDiscard>,		; state 7, token '.'
	<8, RuleDiscard>,		; state 8, token 0
	<2, RuleBack1Accept>,		; state 8, token 1..9
	<8, RuleBack2AcceptInc2>,	; state 8, token +/-
	<4, RuleBack1Plus1E0>,		; state 8, token E/e
	<3, RuleAccept>,		; state 8, token '.'
	<10, RuleAccept>,		; state 9, token 0
	<10, RuleAccept>,		; state 9, token 1..9
	<9, RuleDiscard>,		; state 9, token +/-
	<9, RuleDiscard>,		; state 9, token E/e
	<9, RuleDiscard>,		; state 9, token '.'
	<10, RuleDiscard>,		; state 10,token 0
	<10, RuleDiscard>,		; state 10,token 1..9
	<10, RuleDiscard>,		; state 10,token +/-
	<10, RuleDiscard>,		; state 10,token E/e
	<10, RuleDiscard>		; state 10,token '.'


CalcCode	ends

