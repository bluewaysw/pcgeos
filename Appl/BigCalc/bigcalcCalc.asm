COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcCalc.asm

AUTHOR:		Christian Puscasiu, Feb 28, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT CalcInputFieldRecursiveFilter recursive part of filter

    INT BigCalcLEDDisplaySetColors will set it to a LED display with
				red/black on color or black/white on
				monochrome monitors

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	2/28/92		Initial revision


DESCRIPTION:
	
		

        $Id: bigcalcCalc.asm,v 1.1 97/04/04 14:37:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef USE_32BIT_REGS
.386
endif

ifdef NIKE_GERMAN
_NIKE_GERMAN = TRUE
else
_NIKE_GERMAN = FALSE
endif


udata	segment

DBCS<			even				>
SBCS<	textBuffer	char	100 dup (?) >
DBCS<	textBuffer	wchar	100 dup (?) >


SBCS<	listSeparator	char	1 dup(?)		>
DBCS<	listSeparator	wchar	1 dup(?)		>
udata	ends


COMMENT @%%%%%%%%%%%%%%%%%%%% NON-RESPONDER CODE %%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcInputFieldKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_KBD_CHAR check for filtering and shortcuts

CALLED BY:	
PASS:		*ds:si	= CalcInputFieldClass object
		ds:di	= CalcInputFieldClass instance data
		ds:bx	= CalcInputFieldClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= the ascii value of the chararcter
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState
		bp high	= scan code
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/22/92   	Initial version
	andres	9/24/96		Added a bunch of ifdefs and check for
				DEL key.  Beep on illegal keystrokes
	andres 10/02/96		Don't pass invalid keystrokes to
				superclass for PENELOPE.  This
				prevents the user from performing
				text object editing features, such as
				selecting text with SHIFT->ARROW, etc.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcInputFieldKbdChar	method dynamic CalcInputFieldClass, 
					MSG_META_KBD_CHAR

	; Ignore everything but a press.
	;
	test	dl, mask CF_RELEASE
	jz	hackHackHack
toSuper:
	mov	ax, MSG_META_KBD_CHAR
	mov	di, offset CalcInputFieldClass
	GOTO	ObjCallSuperNoLock

	; Total hack for numeric keypad. If we have an EXTENDED key
	; then we should generally ignore it, unless the character
	; is VC_NUMPAD_DIV or VC_NUMPAD_ENTER. If this code does not
	; exist, then things like SHIFT-INSERT (which should be a
	; paste) will be interpreted as VC_NUMPAD_0 by the keyboard
	; shortcuts below, which is highly unfortunate. -Don 11/17/93
hackHackHack:
	test	dl, mask CF_EXTENDED
	jz	checkShortcuts
SBCS<	cmp	cl, VC_NUMPAD_DIV				>
DBCS<	cmp	cx, C_SYS_NUMPAD_DIVIDE 			>
	je	checkShortcuts


SBCS<	cmp	cl, VC_NUMPAD_ENTER				>
DBCS<	cmp	cx, C_SYS_NUMPAD_ENTER				>
	jne	toSuper

	; Check all possible shortcuts
	;
checkShortcuts:
	push	ds, si
	segmov	ds, cs

if _SCIENTIFIC_REP	; if _SCIENTIFIC_REP = 0, then code will fall
			; through to rpn regardless of test result
			; - andres 9/24/96

	; Check the scientific keys (if available)
	;
	test	ss:[extensionState], mask EXT_SCIENTIFIC
	jz	rpn
endif

if _SCIENTIFIC_REP
	mov	ax, length scientificKbdShortcutTable
	mov	si, offset scientificKbdShortcutTable
	mov	di, offset scientificKbdShortcutObjs
	call	FlowCheckKbdShortcut
	jc	foundShortcut
endif ;if _SCIENTIFIC_REP

	; Check the SIN, COS & TAN keys (or inverse if available)
	;	
if _SCIENTIFIC_REP
	mov	ax, length inverseKbdShortcutTable
	mov	si, offset inverseKbdShortcutTable
	mov	di, offset inverseKbdShortcutObjs
	tst	ss:[inverse]
	jnz	checkFuncs
	mov	ax, length regularKbdShortcutTable
	mov	si, offset regularKbdShortcutTable
	mov	di, offset regularKbdShortcutObjs
checkFuncs:
	call	FlowCheckKbdShortcut
	jc	foundShortcut
endif ; if _SCIENTIFIC_REP

	; Check the RPN keys (if available)
if _SCIENTIFIC_REP
rpn:
endif
	mov	ax, length nonRpnKbdShortcutTable
	mov	si, offset nonRpnKbdShortcutTable
	mov	di, offset nonRpnKbdShortcutObjs

if _RPN_CAPABILITY	; No point in checking for RPN mode if program
			; has no RPN capability. - andres 9/24/96

	cmp	ss:[calculatorMode], CM_RPN
	jne	checkRPN
	mov	ax, length rpnKbdShortcutTable
	mov	si, offset rpnKbdShortcutTable
	mov	di, offset rpnKbdShortcutObjs
checkRPN:
endif

	call	FlowCheckKbdShortcut
	jc	foundShortcut

	; Check the common keys last, as we overload the 'e' key for
	; both the "EE" & "e" keys
	;
	mov	ax, length commonKbdShortcutTable
	mov	si, offset commonKbdShortcutTable
	mov	di, offset commonKbdShortcutObjs
	call	FlowCheckKbdShortcut
	jc	foundShortcut

	; Finally, check either of the Delete/Backspace key combinations
	;	
	mov	ax, length clrDelKbdShortcutTable
	mov	si, offset clrDelKbdShortcutTable
	mov	di, offset clrDelKbdShortcutObjs

	call	FlowCheckKbdShortcut
	jc	foundShortcut
	pop	ds, si

	jmp	toSuper

	; We've successfully matched a keyboard shortcut. Now envoke
	; the correct object
foundShortcut:
	mov	bx, si				; offset to match => BX
	shl	bx, 1				; make offset to optr
	pop	ds, si				; clean up stack
	mov	si, cs:[di][bx].chunk
	mov	bx, cs:[di][bx].handle
	clr	di
	mov	ax, MSG_GEN_ACTIVATE
	call	ObjMessage

	ret
CalcInputFieldKbdChar	endm


if DBCS_PCGEOS
;     Phy/Alt/Ctl/Shf
commonKbdShortcutTable	KeyboardShortcut \
	<0, 0, 0, 0,  C_DIGIT_ZERO>,				;0
	<0, 0, 0, 0,  C_DIGIT_ONE>,				;1
	<0, 0, 0, 0,  C_DIGIT_TWO>,				;2
	<0, 0, 0, 0,  C_DIGIT_THREE>,				;3
	<0, 0, 0, 0,  C_DIGIT_FOUR>,				;4
	<0, 0, 0, 0,  C_DIGIT_FIVE>,				;5
	<0, 0, 0, 0,  C_DIGIT_SIX>,				;6
	<0, 0, 0, 0,  C_DIGIT_SEVEN>,				;7
	<0, 0, 0, 0,  C_DIGIT_EIGHT>,				;8
	<0, 0, 0, 0,  C_DIGIT_NINE>,				;9
	<0, 0, 0, 1,  C_SYS_NUMPAD_0 and mask KS_CHAR>,		;0
	<0, 0, 0, 1,  C_SYS_NUMPAD_1 and mask KS_CHAR>,		;1
	<0, 0, 0, 1,  C_SYS_NUMPAD_2 and mask KS_CHAR>,		;2
	<0, 0, 0, 1,  C_SYS_NUMPAD_3 and mask KS_CHAR>,		;3
	<0, 0, 0, 1,  C_SYS_NUMPAD_4 and mask KS_CHAR>,		;4
	<0, 0, 0, 1,  C_SYS_NUMPAD_5 and mask KS_CHAR>,		;5
	<0, 0, 0, 1,  C_SYS_NUMPAD_6 and mask KS_CHAR>,		;6
	<0, 0, 0, 1,  C_SYS_NUMPAD_7 and mask KS_CHAR>,		;7
	<0, 0, 0, 1,  C_SYS_NUMPAD_8 and mask KS_CHAR>,		;8
	<0, 0, 0, 1,  C_SYS_NUMPAD_9 and mask KS_CHAR>,		;9
	<0, 0, 0, 0,  C_PERIOD>,				;point
	<0, 0, 0, 0,  C_SYS_NUMPAD_PERIOD and mask KS_CHAR>,	;point
if (NOT FALSE)
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_E>,			;EE
	<1, 0, 0, 1,  C_LATIN_SMALL_LETTER_E>,			;EE
endif
	<0, 0, 0, 0,  C_SLASH>,					;divide
	<1, 0, 0, 0,  C_ASTERISK>,				;times
	<1, 0, 0, 0,  C_HYPHEN_MINUS>,				;minus
	<1, 0, 0, 0,  C_PLUS_SIGN>,				;plus
	<1, 0, 0, 0,  C_SYS_NUMPAD_DIVIDE and mask KS_CHAR>,	;divide
	<1, 0, 0, 0,  C_SYS_NUMPAD_MULTIPLY and mask KS_CHAR>,	;times
	<1, 0, 0, 0,  C_SYS_NUMPAD_MINUS and mask KS_CHAR>,	;minus
	<1, 0, 0, 0,  C_SYS_NUMPAD_PLUS and mask KS_CHAR>,	;plus
if (NOT FALSE)
	<1, 0, 0, 0,  C_OPENING_PARENTHESIS>,			;left paren
	<1, 0, 0, 0,  C_CLOSING_PARENTHESIS>,			;right paren
	<0, 0, 1, 0,  C_DIGIT_ONE>,				;one over X
	<0, 0, 1, 0,  C_DIGIT_TWO>,				;square root
	<1, 0, 0, 0,  C_COMMERCIAL_AT>,				;square
	<1, 0, 0, 0,  C_QUOTATION_MARK>,			;square
endif
	<1, 0, 0, 0,  C_PERCENT_SIGN>,				;percent
	<1, 0, 1, 0,  C_HYPHEN_MINUS>,				;plus/minus
	<1, 0, 1, 0,  C_LATIN_SMALL_LETTER_M>,			;memory minus
	<0, 0, 0, 0,  C_LATIN_SMALL_LETTER_M>,			;memory plus
	<0, 0, 0, 0,  C_OPENING_SQUARE_BRACKET>,		;store
	<0, 0, 0, 0,  C_CLOSING_SQUARE_BRACKET>			;recall
else	; DBCS_PCGEOS
commonKbdShortcutTable	KeyboardShortcut \
	<0, 0, 0, 0, CS_BSW, C_ZERO>,				;0
	<0, 0, 0, 0, CS_BSW, C_ONE>,				;1
	<0, 0, 0, 0, CS_BSW, C_TWO>,				;2
	<0, 0, 0, 0, CS_BSW, C_THREE>,				;3
	<0, 0, 0, 0, CS_BSW, C_FOUR>,				;4
	<0, 0, 0, 0, CS_BSW, C_FIVE>,				;5
	<0, 0, 0, 0, CS_BSW, C_SIX>,				;6
	<0, 0, 0, 0, CS_BSW, C_SEVEN>,				;7
	<0, 0, 0, 0, CS_BSW, C_EIGHT>,				;8
	<0, 0, 0, 0, CS_BSW, C_NINE>,				;9
	<0, 0, 0, 1, (CS_CONTROL and 0xf), VC_NUMPAD_0>,	;0
	<0, 0, 0, 1, (CS_CONTROL and 0xf), VC_NUMPAD_1>,	;1
	<0, 0, 0, 1, (CS_CONTROL and 0xf), VC_NUMPAD_2>,	;2
	<0, 0, 0, 1, (CS_CONTROL and 0xf), VC_NUMPAD_3>,	;3
	<0, 0, 0, 1, (CS_CONTROL and 0xf), VC_NUMPAD_4>,	;4
	<0, 0, 0, 1, (CS_CONTROL and 0xf), VC_NUMPAD_5>,	;5
	<0, 0, 0, 1, (CS_CONTROL and 0xf), VC_NUMPAD_6>,	;6
	<0, 0, 0, 1, (CS_CONTROL and 0xf), VC_NUMPAD_7>,	;7
	<0, 0, 0, 1, (CS_CONTROL and 0xf), VC_NUMPAD_8>,	;8
	<0, 0, 0, 1, (CS_CONTROL and 0xf), VC_NUMPAD_9>,	;9
	<0, 0, 0, 0, CS_BSW, C_PERIOD>,				;point
	<0, 0, 0, 0, (CS_CONTROL and 0xf), VC_NUMPAD_PERIOD>,	;point
if (NOT FALSE)
	<1, 0, 0, 0, CS_BSW, C_SMALL_E>,			;EE
	<1, 0, 0, 1, CS_BSW, C_SMALL_E>,			;EE
endif
if _NIKE_GERMAN
	<0, 0, 0, 1, CS_BSW, C_SLASH>,				;divide
else
	<0, 0, 0, 0, CS_BSW, C_SLASH>,				;divide
endif
	<1, 0, 0, 0, CS_BSW, C_ASTERISK>,			;times
	<1, 0, 0, 0, CS_BSW, C_MINUS>,				;minus
	<1, 0, 0, 0, CS_BSW, C_PLUS>,				;plus
	<1, 0, 0, 0, (CS_CONTROL and 0xf), VC_NUMPAD_DIV>,	;divide
	<1, 0, 0, 0, (CS_CONTROL and 0xf), VC_NUMPAD_MULT>,	;times
	<1, 0, 0, 0, (CS_CONTROL and 0xf), VC_NUMPAD_MINUS>,	;minus
	<1, 0, 0, 0, (CS_CONTROL and 0xf), VC_NUMPAD_PLUS>,	;plus
if (NOT FALSE)
	<1, 0, 0, 0, CS_BSW, C_LEFT_PAREN>,			;left paren
	<1, 0, 0, 0, CS_BSW, C_RIGHT_PAREN>,			;right paren
	<0, 0, 1, 0, CS_BSW, C_ONE>,				;one over X
	<0, 0, 1, 0, CS_BSW, C_TWO>,				;square root
	<1, 0, 0, 0, CS_BSW, C_AT_SIGN>,			;square
	<1, 0, 0, 0, CS_BSW, C_AT_SIGN>,			;sqaure
endif
	<1, 0, 0, 0, CS_BSW, C_PERCENT>,			; percent
	<1, 0, 1, 0, CS_BSW, C_MINUS>,				;plus/minus
	<1, 0, 1, 0, CS_BSW, C_SMALL_M>,			;memory minus
	<0, 0, 0, 0, CS_BSW, C_SMALL_M>,			;memory plus
	<0, 0, 0, 0, CS_BSW, C_LEFT_BRACKET>,			;store
	<0, 0, 0, 0, CS_BSW, C_RIGHT_BRACKET>			;recall
endif	; else DBCS_PCGEOS

commonKbdShortcutObjs	optr \
			ButtonZero,
			ButtonOne,
			ButtonTwo,
			ButtonThree,
			ButtonFour,
			ButtonFive,
			ButtonSix,
			ButtonSeven,
			ButtonEight,
			ButtonNine,
			ButtonZero,
			ButtonOne,
			ButtonTwo,
			ButtonThree,
			ButtonFour,
			ButtonFive,
			ButtonSix,
			ButtonSeven,
			ButtonEight,
			ButtonNine,
			ButtonPoint,
			ButtonPoint,

if (NOT FALSE)
			ButtonEE,
			ButtonEE,
endif
			ButtonDivide,
			ButtonTimes,
			ButtonMinus,
			ButtonPlus,
			ButtonDivide,
			ButtonTimes,
			ButtonMinus,
			ButtonPlus,

if (NOT FALSE)
			ButtonLeftParen,
			ButtonRightParen,
			ButtonOneOver,
			ButtonSquareRoot,
			ButtonSquare,
			ButtonSquare,
endif
			ButtonPercent,
			ButtonPlusMinus,
			MemoryMinusButton,
			MemoryPlusButton,
			ButtonStore,
			ButtonRecall

.assert(length commonKbdShortcutTable eq length commonKbdShortcutObjs)

if _SCIENTIFIC_REP

if DBCS_PCGEOS
;     Phy/Alt/Ctl/Shf
scientificKbdShortcutTable	KeyboardShortcut \
	<1, 0, 1, 0,  C_LATIN_SMALL_LETTER_D>,			;degree
	<1, 0, 1, 0,  C_LATIN_SMALL_LETTER_R>,			;radian
	<1, 0, 1, 0,  C_LATIN_SMALL_LETTER_G>,			;gradian
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_I>,			;inverse
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_P>,			;PI
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_E>,			;E
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_N>,			;LN (base E)
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_L>,			;LOG (base 10)
	<1, 0, 0, 0,  C_EXCLAMATION_MARK>,			;factorial
	<1, 0, 0, 1,  C_LATIN_SMALL_LETTER_N>,			;e^x
	<1, 0, 0, 1,  C_LATIN_SMALL_LETTER_L>,			;10^x
	<1, 0, 0, 0,  C_SPACING_CIRCUMFLEX>			;y^x (^)
else
scientificKbdShortcutTable	KeyboardShortcut \
	<1, 0, 1, 0, CS_BSW, C_SMALL_D>,			;degree
	<1, 0, 1, 0, CS_BSW, C_SMALL_R>,			;radian
	<1, 0, 1, 0, CS_BSW, C_SMALL_G>,			;gradian
	<1, 0, 0, 0, CS_BSW, C_SMALL_I>,			;inverse
	<1, 0, 0, 0, CS_BSW, C_SMALL_P>,			;PI
	<1, 0, 0, 0, CS_BSW, C_SMALL_E>,			;E
	<1, 0, 0, 0, CS_BSW, C_SMALL_N>,			;LN (base E)
	<1, 0, 0, 0, CS_BSW, C_SMALL_L>,			;LOG (base 10)
	<1, 0, 0, 0, CS_BSW, C_EXCLAMATION>,			;factorial
	<1, 0, 0, 1, CS_BSW, C_SMALL_N>,			;e^x
	<1, 0, 0, 1, CS_BSW, C_SMALL_L>,			;10^x
	<1, 0, 0, 0, CS_BSW, C_ASCII_CIRCUMFLEX>		;y^x
endif


scientificKbdShortcutObjs	optr \
			DegreeItem,
			RadianItem,
			GradianItem,
			InverseBoolean,
			ButtonPi,
			ButtonE,
			ButtonLn,
			ButtonLog,
			ButtonFactorial,
			ButtonEToX,
			Button10ToX,
			ButtonYToX

.assert(length scientificKbdShortcutTable eq length scientificKbdShortcutObjs)


if DBCS_PCGEOS
regularKbdShortcutTable	KeyboardShortcut \
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_S>,			;sine
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_C>,			;cosine
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_T>			;tangent
else
regularKbdShortcutTable	KeyboardShortcut \
	<1, 0, 0, 0, CS_BSW, C_SMALL_S>,			;sine
	<1, 0, 0, 0, CS_BSW, C_SMALL_C>,			;cosine
	<1, 0, 0, 0, CS_BSW, C_SMALL_T>				;tangent
endif

regularKbdShortcutObjs	optr \
			ButtonSine,
			ButtonCosine,
			ButtonTangent

.assert(length regularKbdShortcutTable eq length regularKbdShortcutObjs)


if DBCS_PCGEOS
inverseKbdShortcutTable	KeyboardShortcut \
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_S>,			;arc sine
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_C>,			;arc cosine
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_T>			;arc tangent
else
inverseKbdShortcutTable	KeyboardShortcut \
	<1, 0, 0, 0, CS_BSW, C_SMALL_S>,			;arc sine
	<1, 0, 0, 0, CS_BSW, C_SMALL_C>,			;arc cosine
	<1, 0, 0, 0, CS_BSW, C_SMALL_T>				;arc tangent
endif

inverseKbdShortcutObjs	optr \
			ButtonArcSine,
			ButtonArcCosine,
			ButtonArcTangent

.assert(length inverseKbdShortcutTable eq length inverseKbdShortcutObjs)

endif ;if _SCIENTIFIC_REP

if _RPN_CAPABILITY 

if DBCS_PCGEOS
rpnKbdShortcutTable	KeyboardShortcut \
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_X>,			;Swap
	<1, 0, 0, 0,  C_LATIN_SMALL_LETTER_R>,			;Roll down
	<0, 0, 0, 0,  C_SYS_ENTER and mask KS_CHAR>,		;Enter
	<0, 0, 0, 0, (C_SYS_NUMPAD_ENTER and mask KS_CHAR) >	;Enter (NumPad)
else
rpnKbdShortcutTable	KeyboardShortcut \
	<1, 0, 0, 0, CS_BSW, C_SMALL_X>,			;Swap
	<1, 0, 0, 0, CS_BSW, C_SMALL_R>,			;Roll down
	<0, 0, 0, 0, CS_BSW, C_ENTER>,				;Enter
	<0, 0, 0, 0, (CS_CONTROL and 0xf), VC_NUMPAD_ENTER>	;Enter (NumPad)
endif ;if DBCS_PCGEOS

rpnKbdShortcutObjs	optr \
			ButtonSwap,
			ButtonRollDown,
			ButtonEnter,
			ButtonEnter

.assert(length rpnKbdShortcutTable eq length rpnKbdShortcutObjs)

endif ; if _RPN_CAPABILITY



if DBCS_PCGEOS
nonRpnKbdShortcutTable	KeyboardShortcut \
	<0, 0, 0, 0, C_EQUALS_SIGN>,				;=
	<0, 0, 0, 0,  C_SYS_ENTER and mask KS_CHAR>,		;Enter
	<0, 0, 0, 0, (C_SYS_NUMPAD_ENTER and mask KS_CHAR) >	;Enter (NumPad)
elseif _NIKE_GERMAN
nonRpnKbdShortcutTable	KeyboardShortcut \
	<0, 0, 0, 1, CS_BSW, C_EQUAL>,				;=
	<0, 0, 0, 0, CS_BSW, C_ENTER>,				;Enter
	<0, 0, 0, 0, (CS_CONTROL and 0xf), VC_NUMPAD_ENTER>	;Enter (NumPad)
else
nonRpnKbdShortcutTable	KeyboardShortcut \
	<0, 0, 0, 0, CS_BSW, C_EQUAL>,				;Enter
	<0, 0, 0, 0, CS_BSW, C_ENTER>,				;Enter
	<0, 0, 0, 0, (CS_CONTROL and 0xf), VC_NUMPAD_ENTER>	;Enter (NumPad)
endif

nonRpnKbdShortcutObjs	optr \
			ButtonEquals,
			ButtonEquals,
			ButtonEquals

.assert(length nonRpnKbdShortcutTable eq length nonRpnKbdShortcutObjs)


if DBCS_PCGEOS
clrDelKbdShortcutTable	KeyboardShortcut \
	<0, 0, 0, 0,  C_SYS_BACKSPACE and mask KS_CHAR>,	;delete
	<1, 0, 1, 0,  C_LATIN_SMALL_LETTER_C>			;clear

else
clrDelKbdShortcutTable	KeyboardShortcut \
	<0, 0, 0, 0, (CS_CONTROL and 0xf), VC_BACKSPACE>,	;delete
	<1, 0, 1, 0, CS_BSW, C_SMALL_C>				;clear
endif	; DBCS_GEOS

clrDelKbdShortcutObjs	optr \
			ButtonDelete,
			ButtonClear

if ((NOT FALSE) and (NOT FALSE))
.assert(length clrDelKbdShortcutTable eq length clrDelKbdShortcutObjs)
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CIFSpecNavigationQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the general conversion box is being displayed, and
		user tries to navigate to the keypad, skip it and go
		to the next object in the tab sequence.

CALLED BY:	MSG_SPEC_NAVIGATION_QUERY
PASS:		*ds:si	= CalcInputFieldClass object
		ds:di	= CalcInputFieldClass instance data
		ds:bx	= CalcInputFieldClass object (same as *ds:si)
		es 	= segment of CalcInputFieldClass
		ax	= message #
		^lcx:dx	= originator
		bp	= NavigateFlags
RETURN:		carry set if object to give focus to, with:
			^lcx:dx	= object which is replying
		else
			^lcx:dx = next object to query
		bp	= NavigateFlags (will be altered as message is
			  passed around)
		al	= set if the object is focusable via backtracking
			  (i.e. can take the focus if it is previous to the
			  originator in backwards navigation)
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andres	10/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @----------------------------------------------------------------------

MESSAGE:	InputFieldInternalKbdChar -- MSG_IF_INTERNAL_KBD_CHAR
						for InputFieldClass

DESCRIPTION:	Keyboard digit press message arrive here.
		Handles button "0" to button "9" and "." (decimal point)
		and "E" (exponent).
PASS:
	*ds:si - instance data
	es - segment of InputFieldClass

	ax - The message

	cx - buttonValue
	dx - 0 || CF_FIRST_PRESS
	bp - 0

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/18/93		Initial version
	EC	7/16/96		added checking for input length(Penelope)
	AS	8/26/96		displays the operator, if necessary
	AS	9/ 8/96		Draw double line if equal key was just
				hit
	andres	10/13/96	added lastOperation check
	andres	10/17/96	clear PFR_replaceOp
	andres	10/23/96	drop top FP stack number if necessary

------------------------------------------------------------------------------@
InputFieldInternalKbdChar	method dynamic	InputFieldClass,
						MSG_IF_INTERNAL_KBD_CHAR

	mov	ax, MSG_META_KBD_CHAR
	mov	di, offset InputFieldClass
if (NOT FALSE)
	GOTO	ObjCallSuperNoLock
else
	call	ObjCallSuperNoLock

done:
	BitClr	ss:[peneFlags], PFR_replaceOp
	BitClr	ss:[peneFlags], PFR_dontPrintToPaperTape
	ret

handleBackSpace:
	push	si
	mov	ax, MSG_CALC_IF_CHECK_OP_DONE_BIT
	GetResourceHandleNS	BigCalcNumberDisplay, bx
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	jnc	callSuper

	cmp	ss:[lastKeyHit], LKHT_CLEAR
	je	callSuper

	cmp	ss:[lastKeyHit], LKHT_BINARY_OPERATOR
	jne	noDup

	call	FloatDup

noDup:
	push	si
	mov	ax, MSG_CALC_IF_CLEAR_OP_DONE_BIT
	call	ObjMessage
	pop	si

	mov	ax, MSG_META_KBD_CHAR
	mov	di, offset InputFieldClass
	call	ObjCallSuperNoLock

	BitSet	ss:[peneFlags], PFR_drawDoubleLine
	mov	ss:[lastKeyHit], LKHT_OPERAND
	
	jmp	done

endif
InputFieldInternalKbdChar	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcCheckInputLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the length of input is valid

CALLED BY:	InputFieldInternalKbdChar
PASS:		nothing
RETURN:		set carry if length is too large
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
	* set the max length to be 12 initially
	* check if there's a ".", if so the max increase by one
	* check if there's a "-", if so the max increase by one	
	* check the length of input is valid by comparing to the max
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EC	7/15/96    	Initial version
	AS	8/19/96		Fixed to reject strings of 13 digits
	AS	8/21/96		Fixed bug that rejected the second
				operand if the first operand's length
				was the maximum.
	AS	3/21/96		Decreased max length by 1

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcInputFieldVisTextFilterViaBeforeAfter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	front-end to filter mechanism

CALLED BY:	
PASS:		*ds:si	= CalcInputFieldClass object
		ds:di	= CalcInputFieldClass instance data
		ds:bx	= CalcInputFieldClass object (same as *ds:si)
		ss 	= dgroup
		ax	= message #
		*ds:cx	= before string
		*ds:dx	= after string
		ss:bp	= VisReplaceParameters
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/18/92   	Initial version
	andres	9/25/96		Dont reset operationDone bit if 
				responding the the +/- key in PENELOPE
				version.  
	dhunter	9/11/00		Drop TOS after unary operation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcInputFieldVisTextFilterViaBeforeAfter method dynamic CalcInputFieldClass, 
					MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER
	uses	ax, cx, dx, bp
	.enter

	;
	; save the  pointer to the ReplaceParams
	;
	push	bp

	;
	; get the after string into ds:si
	;
	mov	si, dx
	mov	si, ds:[si]
	call	InputFieldCheckIfValidFPNumber
	
	;
	; retrive that pointer
	;	
	pop	bp

	LONG jc	makeBeep
	
	mov	si, offset BigCalcNumberDisplay
	mov	di, ds:[si]
	add	di, ds:[di].CalcInputField_offset

	test	ds:[di].CIFI_attributes, mask CIFA_inRecursion
	jnz	useOldCX

	mov	ds:[di].CIFI_replaceLength, cx

useOldCX:
	;
	; recover the object again
	;
	mov	si, offset BigCalcNumberDisplay
;;	BitClr	ds:[di].CIFI_attributes, CIFA_clear

if 0	; No longer required -dhunter 9/11/00
	test	ds:[di].CIFI_attributes, mask CIFA_inputDone
	jz	testDone

	BitClr	ds:[di].CIFI_attributes, CIFA_inputDone
	test	ds:[di].CIFI_attributes, mask CIFA_inRecursion
	jz	specialCase
	jmp	continuingNumber

testDone:
endif
	test	ds:[di].CIFI_attributes, mask CIFA_operationDone
	jz	continuingNumber
	
	test	ds:[di].CIFI_attributes, mask CIFA_inRecursion
LONG	jz	specialCase

	BitClr	ds:[di].CIFI_attributes, CIFA_operationDone

if _RPN_CAPABILITY
	;
	; In RPN mode, lift the stack (start a new number) if the
	; enter bit is clear.
	;
	cmp	ss:[calculatorMode], CM_RPN
	jne	checkUnary
	test	ds:[di].CIFI_attributes, mask CIFA_enter
	jz	newNumber
	BitClr	ds:[di].CIFI_attributes, CIFA_enter
	jmp	continuingNumber
endif
	;
	; Following a unary operation, drop TOS.  This allows the user
	; to replace the result of a unary operation and keeps the
	; operator stack in sync. -dhunter 9/11/2000
	;
checkUnary:
	test	ds:[di].CIFI_attributes, mask CIFA_unaryOpDone
	jz	newNumber

continuingNumber:

;;	BitClr	ds:[di].CIFI_attributes, CIFA_inputDone
	push	ax			; preserve input character, as code...
	call	FloatDepth
	cmp	ax, 2
	pop	ax			; ...below expects it in AL/AX
	jl	newNumber
	call	FloatDrop
	
newNumber:
	LocalIsNull	ax
	jz	numIsZero

	;
	; save the obj's block
	;

	push	ds
	
	mov	al, mask FAF_PUSH_RESULT
	mov	ds, dx
	mov	bp, offset textBuffer
	mov	si, bp
	mov	cx, NUMBER_NUM_CHARS
	call	FloatAsciiToFloat

	;
	; retrieve the obj's block
	;
	pop	ds
	mov	si, offset BigCalcNumberDisplay
	jmp	printNum

numIsZero:
	call	Float0
	mov	bp, offset textBuffer
if DBCS_PCGEOS
	mov	{wchar} ss:[bp], '0'
	mov	{wchar} ss:[bp+2], C_NULL
else
	mov	{char} ss:[bp], '0'
	mov	{char} ss:[bp][1], 0
endif
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	jmp	reject

makeBeep:
	;
	; show the user that we discarded his input
	;
	mov	ax, SST_NO_INPUT
; just temporily
;	call	UserStandardSound
	jmp	reject

printNum:
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	mov	di, ds:[si]
	add	di, ds:[di].CalcInputField_offset
	
	mov	cx, ds:[di].CIFI_replaceLength
	mov	dx, cx
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	call	ObjCallInstanceNoLock 

	jmp	reject

specialCase:
	call	CalcInputFieldRecursiveFilter

reject:
	;
	; we always reject the string (because the general user cannot
	; be trusted :).  He either entered an illegal character which
	; means, that we are just going to ignore the input.  Or we
	; check and make sure he entered a valid number.
	;
	stc

	.leave
	ret

CalcInputFieldVisTextFilterViaBeforeAfter	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcInputFieldRecursiveFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	recursive part of filter

CALLED BY:	
PASS:		ds	objectblock of the BigCalcNumberDisplay
		ss:bp	VisTextReplaceParameters
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcInputFieldRecursiveFilter	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	class	CalcInputFieldClass
	.enter

	BitSet	ds:[di].CIFI_attributes, CIFA_inRecursion

	movdw	ss:[bp].VTRP_range.VTR_start, 0
	movdw	ss:[bp].VTRP_range.VTR_end, TEXT_ADDRESS_PAST_END

	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	ObjCallInstanceNoLock 

	BitClr	ds:[di].CIFI_attributes, CIFA_inRecursion

	.leave
	ret
CalcInputFieldRecursiveFilter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcInputFieldSetYYYBit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the bit in question

CALLED BY:	
PASS:		*ds:si	= CalcInputFieldClass object
		ds:di	= CalcInputFieldClass instance data
		ds:bx	= CalcInputFieldClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/13/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcInputFieldSetOperationDoneBit	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_SET_OP_DONE_BIT
	.enter

	BitSet	ds:[di].CIFI_attributes, CIFA_operationDone

	.leave
	ret
CalcInputFieldSetOperationDoneBit	endm

if 0	; No longer required -dhunter 9/11/00
CalcInputFieldSetInputDoneBit	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_SET_INPUT_DONE_BIT
	.enter

	BitSet	ds:[di].CIFI_attributes, CIFA_inputDone

	.leave
	ret
CalcInputFieldSetInputDoneBit		endm
endif

CalcInputFieldSetEnterBit	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_SET_ENTER_BIT
	.enter

	BitSet	ds:[di].CIFI_attributes, CIFA_enter

	.leave
	ret
CalcInputFieldSetEnterBit	endm

if 0	; No longer required -dhunter 9/11/2000
CalcInputFieldSetClearBit	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_SET_CLEAR_BIT
	.enter

	BitSet	ds:[di].CIFI_attributes, CIFA_clear

	.leave
	ret
CalcInputFieldSetClearBit	endm
endif

CalcInputFieldSetUnaryOpDone	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_SET_UNARY_OP_DONE
	.enter

	BitSet	ds:[di].CIFI_attributes, CIFA_unaryOpDone

	.leave
	ret
CalcInputFieldSetUnaryOpDone	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcInputFieldClearYYYBit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clears the YYY bit

CALLED BY:	
PASS:		*ds:si	= CalcInputFieldClass object
		ds:di	= CalcInputFieldClass instance data
		ds:bx	= CalcInputFieldClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		clears the op done bit
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcInputFieldClearOpDoneBit	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_CLEAR_OP_DONE_BIT
	.enter

	BitClr	ds:[di].CIFI_attributes, CIFA_operationDone

	.leave
	ret
CalcInputFieldClearOpDoneBit	endm

if 0	; No longer required -dhunter 9/11/00
CalcInputFieldClearInputDoneBit	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_CLEAR_INPUT_DONE_BIT
	.enter

	BitClr	ds:[di].CIFI_attributes, CIFA_inputDone

	.leave
	ret
CalcInputFieldClearInputDoneBit	endm
endif

CalcInputFieldClearUnaryOpDone	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_CLEAR_UNARY_OP_DONE
	.enter

	BitClr	ds:[di].CIFI_attributes, CIFA_unaryOpDone

	.leave
	ret
CalcInputFieldClearUnaryOpDone	endm

CalcInputFieldClearEnterBit	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_CLEAR_ENTER_BIT
	.enter

	BitClr	ds:[di].CIFI_attributes, CIFA_enter

	.leave
	ret
CalcInputFieldClearEnterBit	endm

if 0	; No longer required -dhunter 9/11/00
CalcInputFieldClearClearBit	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_CLEAR_CLEAR_BIT
	.enter

	BitClr	ds:[di].CIFI_attributes, CIFA_clear

	.leave
	ret
CalcInputFieldClearClearBit	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcInputFieldCheckYYYBit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks the YYY bit

CALLED BY:	
PASS:		*ds:si	= CalcInputFieldClass object
		ds:di	= CalcInputFieldClass instance data
		ds:bx	= CalcInputFieldClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		carry set = bit set
		carry unset = bit unset
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 3/92   	Initial version
	dhunter	9/5/2000	Made smaller and faster

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcInputFieldCheckOpDoneBit	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_CHECK_OP_DONE_BIT

	test	ds:[di].CIFI_attributes, mask CIFA_operationDone
	; I'll only say it once: carry is cleared by test.
checkBitCommon	label far
	jz	notSet
	stc
notSet:
	ret
CalcInputFieldCheckOpDoneBit	endm

CalcInputFieldCheckEnterBit	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_CHECK_ENTER_BIT

	test	ds:[di].CIFI_attributes, mask CIFA_enter
	GOTO	checkBitCommon
CalcInputFieldCheckEnterBit	endm

if 0	; No longer required -dhunter 9/11/00
CalcInputFieldCheckClearBit	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_CHECK_CLEAR_BIT

	test	ds:[di].CIFI_attributes, mask CIFA_clear
	GOTO	checkBitCommon
CalcInputFieldCheckClearBit	endm
endif

CalcInputFieldCheckUnaryOpDone	method dynamic CalcInputFieldClass, 
					MSG_CALC_IF_CHECK_UNARY_OP_DONE

	test	ds:[di].CIFI_attributes, mask CIFA_unaryOpDone
	GOTO	checkBitCommon
CalcInputFieldCheckUnaryOpDone	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PaperRollCheckLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks how many numbers are on the papertape and
		deletes if it is too long

CALLED BY:	
PASS:		*ds:si	= PaperRollClass object
		ds:di	= PaperRollClass instance data
		ds:bx	= PaperRollClass object (same as *ds:si)
		es 	= segment of PaperRollClass
		ax	= message #
RETURN:		potentially shorter papertape
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if (NOT FALSE)
PaperRollCheckLength	method dynamic PaperRollClass, 
					MSG_PAPER_ROLL_CHECK_LENGTH
	uses	ax, cx, dx, bp
	.enter

	mov	bx, ds:[di].GTXI_text
	mov	bx, ds:[bx]
	ChunkSizePtr ds, bx, ax
SBCS<	cmp	ax, MAX_LENGTH_PAPER_ROLL				>
DBCS<	cmp	ax, MAX_LENGTH_PAPER_ROLL*(size wchar)			>
	jge	shrinkPaperRoll		; Chunk too big, shrink it.

done:
	mov	ax, MSG_VIS_TEXT_SELECT_END
	call	ObjCallInstanceNoLock

	.leave
	ret

shrinkPaperRoll:

	clr	cx
	mov	dx, MAX_LENGTH_PAPER_ROLL/4	; trim 25%
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	call	ObjCallInstanceNoLock 

	mov	ax, MSG_VIS_TEXT_DELETE_SELECTION
	call	ObjCallInstanceNoLock 
	
	jmp	done


PaperRollCheckLength	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PaperRollClearPaperRoll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clears the paperroll

CALLED BY:	
PASS:		*ds:si	= PaperRollClass object
		ds:di	= PaperRollClass instance data
		ds:bx	= PaperRollClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/13/92   	Initial version
	andres	9/24/96		removed linefeed at top of paper tape 
				after clear (in clearpapertapeText)
	andres	10/13/96	Set printToPaperTape

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if (NOT FALSE)
PaperRollClearPaperRoll	method dynamic PaperRollClass, 
					MSG_PAPER_ROLL_CLEAR_PAPERROLL
	.enter


	mov	dx, cs
	mov	bp, offset clearPapertapeText
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	.leave
	ret
PaperRollClearPaperRoll	endm
endif


COMMENT @----------------------------------------------------------------------

MESSAGE:	PaperRollKbdChar -- MSG_META_KBD_CHAR for PaperRollClass

DESCRIPTION:	Redirect keyboard characters to the input object

PASS:
	*ds:si - instance data
	es - segment of PaperRollClass

	ax - The message

	cx - character value
	dl - CharFlags
	dh - ShiftState
	bp low = ToggleState
	bp high = scan code

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/21/93		Initial version
------------------------------------------------------------------------------@
if (NOT FALSE)
PaperRollKbdChar	method dynamic	PaperRollClass, MSG_META_KBD_CHAR

	;
	; Don't do this weirdness on keyboard-only systems.   The papertape
	; is useless if you can't page it up and down.   9/ 2/93 cbh
	;
	push	ax
	call	FlowGetUIButtonFlags
	test	al, mask UIBF_KEYBOARD_ONLY
	pop	ax
	jnz	callSuper

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay

	push	ax, cx, dx, bp
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	clr	di
	call	ObjMessage
	pop	ax, cx, dx, bp

	clr	di
	GOTO	ObjMessage

callSuper:
	mov	di, offset PaperRollClass
	GOTO	ObjCallSuperNoLock

PaperRollKbdChar	endm

	LocalDefNLString  clearPapertapeText, <"0\\r",0>
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcInputFieldSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SPEC_BUILD for CalcInputField to get the LCD font
		in the appropriate color

CALLED BY:	
PASS:		*ds:si	= CalcInputFieldClass object
		ds:di	= CalcInputFieldClass instance data
		ds:bx	= CalcInputFieldClass object (same as *ds:si)
		es 	= segment of CalcInputFieldClass
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcInputFieldSpecBuild	method dynamic CalcInputFieldClass, 
					MSG_SPEC_BUILD
	uses	ax, cx, dx, bp
	.enter

	call	BigCalcLEDDisplaySetColors

	mov	di, offset CalcInputFieldClass
	mov	ax, MSG_SPEC_BUILD
	call	ObjCallSuperNoLock

	.leave
	ret
CalcInputFieldSpecBuild	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcLEDDisplaySetColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will set it to a LED display with red/black on color or
		black/white on monochrome monitors
CALLED BY:	
PASS:		*ds:si 	- a VisTextObject
		ds:di	- instance data of the object
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcLEDDisplaySetColors	proc	near
	class	GenTextClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	call	UserGetDisplayType
	
	and	ah, (DC_GRAY_1 shl offset DT_DISP_CLASS)

	jz	colorMonitor
	;
	; being here means that we have a b/w monitor, so we want to
	; set the background to white and the letters to black (which
	; means that we'll use the NumberMonochromeDisplayAttr)
	;
	mov	ax, VisTextDefaultCharAttr <
				0, 0, 0,
				C_BLACK, VTDS_18, VTDF_LED>
	mov	dx, offset WhiteWashColor

	jmp	setScreen


colorMonitor:
	;
	; being here means that we have a color monitor so we want to
	; set the color of the letters to light red and the background
	; to black (which menas we'll use the NumberColorDisplayAttr)
	;
	mov	ax, VisTextDefaultCharAttr <
			0, 0, 0,
			C_LIGHT_RED, VTDS_18, VTDF_LED>
	mov	dx, offset BlackWashColor


setScreen:
	push	ax				
	mov	cx, 2
	mov	ax, ATTR_GEN_TEXT_DEFAULT_CHAR_ATTR
	call	ObjVarAddData
	pop	ax
	mov	{word} ds:[bx], ax

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].VTI_charAttrRuns, ax
	ornf	ds:[di].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR

	mov	ax, HINT_TEXT_WASH_COLOR
	mov	cx, (size ColorQuad)
	call	ObjVarAddData
	mov	di, dx			;cs:di <- ptr to source ColorQuad
	mov	ax, cs:[di]
	mov	ds:[bx], ax
	mov	ax, cs:[di][2]
	mov	ds:[bx][2], ax
		CheckHack <(size ColorQuad) eq 4>

	.leave
	ret
BigCalcLEDDisplaySetColors	endp

WhiteWashColor	ColorQuad	<C_WHITE, CF_INDEX, 0, 0>

BlackWashColor	ColorQuad	<C_BLACK, CF_INDEX, 0, 0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcTriggerSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert any text monikers into a GString moniker with
		a preset font, size & text color.

CALLED BY:	System (MSG_SPEC_BUILD)

PASS:		ES 	= segment of CalcTriggerClass
		*DS:SI	= CalcTriggerClass object
		AX	= message
		BP	= SpecBuildFlags

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcTriggerSpecBuild	method dynamic	CalcTriggerClass, MSG_SPEC_BUILD

	;
	; Check to see if we have a moniker - if not, do nothing
	;
		mov	bx, ds:[di].GI_visMoniker
		tst	bx
		jz	callSuper
		call	CalcTriggerConvertMoniker
	;
	; Call our superclass
	;
callSuper:
		mov	di, offset CalcTriggerClass
		GOTO	ObjCallSuperNoLock
CalcTriggerSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcTriggerUseMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert any text monikers into a GString moniker with
		a preset font, size & text color.

CALLED BY:	System (MSG_GEN_USE_VIS_MONIKER)

PASS:		ES 	= segment of CalcTriggerClass
		*DS:SI	= CalcTriggerClass object
		DL	= VisUpdateMode
		CX	= Chunk handle of new moniker to use
		AX	= MSG_GEN_USE_VIS_MONIKER
		AX	= message

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcTriggerUseMoniker	method dynamic	CalcTriggerClass, \
					MSG_GEN_USE_VIS_MONIKER
	;
	; Convert the moniker and then call the the superclass
	;
		mov	bx, cx			; moniker chunk => BX
		call	CalcTriggerConvertMoniker
		mov	di, offset CalcTriggerClass
		GOTO	ObjCallSuperNoLock
CalcTriggerUseMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcBooleanSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert any text monikers into a GString moniker with
		a preset font, size & text color.

CALLED BY:	System (MSG_SPEC_BUILD)

PASS:		ES 	= segment of CalcBooleanClass
		*DS:SI	= CalcBooleanClass object
		AX	= message
		BP	= SpecBuildFlags

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcBooleanSpecBuild	method dynamic	CalcBooleanClass, MSG_SPEC_BUILD

	;
	; Check to see if we have a moniker - if not, do nothing
	;
		mov	bx, ds:[di].GI_visMoniker
		tst	bx
		jz	callSuper
		call	CalcTriggerConvertMoniker
	;
	; Call our superclass
	;
callSuper:
		mov	di, offset CalcBooleanClass
		GOTO	ObjCallSuperNoLock
CalcBooleanSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcTriggerConvertMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert any text monikers into a GString moniker with
		a preset font, size & text color.

CALLED BY:	CalcTriggerSpecBuild(), CalcTriggerUseMoniker()

PASS:		DS	= Segment in which moniker chunk is located
		BX	= VisMoniker chunk in same object block

RETURN:		DS	= Updated if moved

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

calcTriggerMonikerTemplate	label	byte
	VisMoniker <<0, 1, DAR_NORMAL, DC_COLOR_4>, 0>
	VisMonikerGString <0>
	OpSetFont <, <0,14>, FID_BERKELEY>
	OpSetTextColorIndex <, C_WHITE>
	byte	GR_DRAW_TEXT_CP

CALC_TRIGGER_MONIKER_TEMPLATE_SIZE = $ - (offset calcTriggerMonikerTemplate)

CalcTriggerConvertMoniker	proc	near
		uses	ax, cx, di, si, es
		.enter
	;
	; If moniker is not text (either a GString or a list), do nothing
	;
		mov	di, ds:[bx]
		test	ds:[di].VM_type, mask VMT_GSTRING or \
			                 mask VMT_MONIKER_LIST
		jnz	done
	;
	; OK, we have a text moniker. Create a GString moniker, using the
	; text already assigned for this object.
	;
		ChunkSizeHandle ds, bx, cx
		sub	cx, ((size VisMoniker) + (size VMT_mnemonicOffset)) + 1
		push	cx			; size of text (no NULL) => CX
		add	cx, (size ODTCP_len) + (size OpEndGString)
		mov	ax, bx
		add	cx, CALC_TRIGGER_MONIKER_TEMPLATE_SIZE
		call	LMemReAlloc
	;
	; Copy the size of the text, the moniker text itself, and then
	; end the GString appropriately
	;
		segmov	es, ds, ax
		mov	si, ds:[bx]
		mov	di, si
		add	si, (offset VM_data) + (offset VMT_text) ; src => DS:SI
		add	di, CALC_TRIGGER_MONIKER_TEMPLATE_SIZE
		pop	cx			; restore text string length
		mov	ax, cx
		stosw				; write ODTCP_LEN
		rep	movsb
		mov	al, GR_END_GSTRING
		stosb
	;
	; Finally, back up & copy the template into the new moniker
	;
		mov	di, es:[bx]		; destination => ES:DI
		segmov	ds, cs, ax
		mov	si, offset calcTriggerMonikerTemplate
		mov	cx, CALC_TRIGGER_MONIKER_TEMPLATE_SIZE
		rep	movsb
		segmov	ds, es, ax		; object/moniker segment => DS
done:
		.leave
		ret
CalcTriggerConvertMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CWLSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turns off worksheets items (removes them from the list)
		that have blank chunks.  Used during localization to
		turn off particular worksheets.

CALLED BY:	System (MSG_SPEC_BUILD)

PASS:		ES 	= segment of CalcWorksheetListClass
		*DS:SI	= CalcWorksheetListClass object
		AX	= message
		BP	= SpecBuildFlags

RETURN:		
DESTROYED:	AX, CX, DX, BP
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	12/05/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CWLSpecBuild	method dynamic CalcWorksheetListClass, 
					MSG_SPEC_BUILD

	;
	; Don't forget to call super!
	;
	mov	di, offset CalcWorksheetListClass
	call	ObjCallSuperNoLock

	;
	; Process each child with our callback routine
	;
	mov	bx, offset CalcWorksheetList_offset
	mov	di, offset GI_comp
ifdef USE_32BIT_REGS
	xor	eax, eax
	push	eax		; start at object 0 in composite
else
	clr	ax
	push	ax
	push	ax
endif
	mov	ax, offset GI_link	; offset to link part
	push	ax
	mov	ax, SEGMENT_CS
	push	ax
	mov	ax, offset WorksheetListBuildCB
	push	ax			; offset to callback
	call	ObjCompProcessChildren
	ret
CWLSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WorksheetListBuildCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called for each worksheet list item in the list.
		Sets the item not usable if the moniker is blank.

CALLED BY:	
PASS:		*ds:si - child
		*es:di - composite
		ax, cx, dx, bp - data

RETURN:		carry - set to end processing
		ax, cx, dx, bp - data to send to next child
DESTROY:	bx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	12/06/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WorksheetListBuildCB	proc	far
	class GenClass
	;
	; dereference the VisMoniker for this child
	;
	push	si
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset	; ds:si <- GenClass instance data
	mov	si, ds:[si].GI_visMoniker
	mov	si, ds:[si]		; ds:si <- VisMoniker data
	tst	ds:[si].VM_data.VMT_text
	pop	si
	jnz	done	

	;
	; set this object not usable
	;

	mov	ax, MSG_GEN_SET_NOT_USABLE	
	call	ObjCallInstanceNoLock

done:
	clc		; don't end processing -- go through all the items in the list
	ret
WorksheetListBuildCB	endp


CalcCode	ends

