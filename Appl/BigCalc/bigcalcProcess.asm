COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcProcess.asm

AUTHOR:		Christian Puscasiu, Feb 27, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT BigCalcProcessCheckForWorksheets Will enable or disable the option
				to have worksheets in the Customize menu.
				In case the worksheets are on they will be
				switched of if the .ini file wants to not
				display them

    INT BigCalcProcessLocalize	Handle localizing stuff based on system
				settings

    INT BigCalcProcessSetEngineOffset sets the math engine

    INT BigCalcProcessBringUpAllDescriptions brings up the descriptions of
				the worksheets

    INT BigCalcProcessDisplayLineOnPaperTape displays a line on the
				papertape

    INT BigCalcProcessSetUsable sets the object that's passed in bx:si
				usable

    INT BigCalcProcessSetNotUsable sets the object in bx:si not usable

    INT BigCalcProcessMoveButtonsUp moves C/CE and <- button up when small
				configuration of the calculator is
				requested

    INT BigCalcProcessMoveButtonsDown moves C/CE and <- button down when
				small configuration is left

    INT BigCalcProcessPreFloatDup utility function for proper fp
				calculation

    INT BigCalcProcessConvertToUpper makes the e into E in scientific
				notation

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	2/27/92		Initial revision


DESCRIPTION:
	Implements the BigCalcProcessClass
		
	$Id: bigcalcProcess.asm,v 1.1 97/04/04 14:38:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


udata	segment
	restoringFromState	byte	(FALSE)
udata	ends

idata	segment
	extensionState		ExtensionType		mask EXT_MATH
	calculatorMode		CalculatorMode		CM_INFIX
	inverse			BooleanByte		BB_FALSE
idata	ends



ProcessCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initializes the stack 

CALLED BY:	opening thread
PASS:		*ds:si	= BigCalcProcessClass object
		ds:di	= BigCalcProcessClass instance data
		ds:bx	= BigCalcProcessClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/ 3/92		Initial version
	andres	10/ 7/96	Made separate handler for PENELOPE
				version
	andres	10/26/96	Don't need to check for worksheets in
				DOVE

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcProcessOpenApplication	method dynamic BigCalcProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
	uses	ax, cx, dx, bp
	.enter

	;
	; Only check .INI flag for worksheets if not restoring from state
	;
	test	cx, mask AAF_RESTORING_FROM_STATE
	jnz	doLocalization
	call	BigCalcProcessCheckForAvailableFeatures

doLocalization:

	call	BigCalcProcessLocalize

	;
	; let the right things happen automatically
	;
	mov	di, offset BigCalcProcessClass
	call	ObjCallSuperNoLock


	;
	; set the default engine
	;

	call	BigCalcProcessSetEngineOffset

	;
	; get me a nice chunck of Memory for my floating point stack
	;
	mov	ax, FP_STACK_LENGTH
	mov	bl, FLOAT_STACK_WRAP
	call	FloatInit
	call	Float0

	;
	; get a handle for the operator stack
	; Use clear all to initialize instance data and set the various
	; operation state bits
	;
	mov	bx, handle BigCalcInfixEngine
	mov	si, offset BigCalcInfixEngine
	clr	di
	mov	ax, MSG_CE_CLEAR_ALL
	call	ObjMessage

;;;	call	SetConvertCurrencyMenuItems	; set exchange rate menu items.

	cmp	ss:[restoringFromState], TRUE
	je	done

	mov	bx, handle OptionsMenu
	mov	si, offset OptionsMenu
	clr	di
	mov	ax, MSG_META_LOAD_OPTIONS
	call	ObjMessage 
	call	BigCalcProcessBringUpAllDescriptions

done:

	.leave
	ret
BigCalcProcessOpenApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessCheckForAvailableFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make available various features based upon .INI settings

CALLED BY:	BigCalcProcessOpenApplication
PASS:		nothing 
RETURN:		nothing 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		- check for paper roll option
		- check for worksheets option

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	12/10/92    	Initial version
	andres	10/29/96	Don't need this for DOVE
	Don	2/7/99		Tweaked for GPC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

configureString	char	"bigcalc", 0
worksheetString	char	"worksheets", 0
paperrollString	char	"papertape", 0

BigCalcProcessCheckForAvailableFeatures	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; Read the worksheets value from the .INI file.
	; Default behavior is that worksheets are available
	;
		segmov	ds, cs, cx
		mov	si, offset configureString	;ds:si <- category
		mov	dx, offset paperrollString	;cx:dx <- key
		mov	ax, FALSE
		call	InitFileReadBoolean
		push	ax
		mov	dx, offset worksheetString	;cx:dx <- key
		mov	ax, TRUE
		call	InitFileReadBoolean
		tst	ax
		jnz	checkPaperRoll
	;
	; Turn off both the options UI and the actual worksheets
	;
		mov	bx, handle WorksheetsGroup
		mov	si, offset WorksheetsGroup
		call	BigCalcProcessSetNotUsable
		mov	ax, MSG_BC_PROCESS_CHANGE_WORKSHEETS_STATE
		call	GeodeGetProcessHandle
		mov	cx, FALSE
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; OK, now do the same for the paper roll (aka paper tape)
	; Default behavior is that the paper roll is *not* available
	;
checkPaperRoll:
		pop	ax			; restore .INI setting
		tst	ax
		jz	done
	;
	; Turn on both the options UI and the actual paper roll
	;
		mov	bx, handle PaperRollGroup
		mov	si, offset PaperRollGroup
		call	BigCalcProcessSetUsable
		mov	ax, MSG_BC_PROCESS_CHANGE_PAPER_ROLL_STATE
		call	GeodeGetProcessHandle
		mov	cx, TRUE
		mov	di, mask MF_CALL
		call	ObjMessage
done:
		.leave
		ret
BigCalcProcessCheckForAvailableFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessLocalize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle localizing stuff based on system settings

CALLED BY:	BigCalcProcessOpenApplication()
PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcProcessLocalize		proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds,es
	.enter

	;
	; Get the numeric format and see if it is what we expect
	;
	call	LocalGetNumericFormat		;cx <- decimal point
						;dx <- list separator
	;segmov	ds, dgroup, ax
	GetResourceSegmentNS	dgroup, ds
SBCS<	mov	ds:[listSeparator], dl
DBCS<	mov	ds:[listSeparator], dx

	cmp	cx, '.'				;U.S. default?
	je	done
	;
	; The decimal separator is different.  The ATTR_GEN_TRIGGER_ACTION_DATA
	; for the "." key is the data for MSG_META_KBD_CHAR, in the order:
	;	cx = character value
	;	dl = CharFlags
	;	dh = ShiftState
	;	bp low = ToggleState
	;	bp high = scan code
	; We unnecessarily use the same registers here because they are handy.
	;
	clr	bp
	push	bp, cx				;<- NULL, char
	mov	dx, mask CF_FIRST_PRESS
	push	bp				;<- bp.low, bp.high
	push	dx				;<- CharFlags, ShiftState
	push	cx				;<- char value
	mov	dx, sp
	sub	sp, (size AddVarDataParams)
	mov	bp, sp				;ss:bp <- AddVarDataParams
	movdw	ss:[bp].AVDP_data, ssdx		;ptr to data
	mov	ss:[bp].AVDP_dataSize, 3*(size word)
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_TRIGGER_ACTION_DATA
	mov	ax, MSG_META_ADD_VAR_DATA
	call	callPointTrigger
	add	sp, (size AddVarDataParams)+3*(size word)
	;
	; Set the moniker to the same character, which is on the stack
	;
	movdw	cxdx, sssp			;cx:dx <- ptr to text
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_DELAYED_VIA_APP_QUEUE
	call	callPointTrigger
	pop	bp, cx
done:

	.leave
	ret

callPointTrigger:
	mov	di, mask MF_CALL
	mov	bx, handle ButtonPoint
	mov	si, offset ButtonPoint		;^lbx:si <- OD of trigger
	call	ObjMessage
	retn
BigCalcProcessLocalize		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessSetEngineOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the math engine

CALLED BY:	BigCalcProcessOpenApplication
PASS:		ES	= DGroup
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcProcessSetEngineOffset	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	bx, handle ModeItemGroup
	mov	si, offset ModeItemGroup
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage 

	cmp	ax, CM_RPN
if _RPN_CAPABILITY
	mov	ax, offset BigCalcRPNEngine
endif
	je	setEngine
	mov	ax, offset BigCalcInfixEngine
setEngine:
	mov	ss:[engineOffset], ax

	.leave
	ret
BigCalcProcessSetEngineOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessBringUpAllDescriptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	brings up the descriptions of the worksheets

CALLED BY:	BigCalcProcessOpenApplication
PASS:		nothing 
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


BigCalcProcessBringUpAllDescriptions	proc	near
	uses	ax,cx,dx,bp
	.enter

	mov	bx, handle SalesChooser
	mov	si, offset SalesChooser
	clr	di
	mov	cx, PCFID_SALES_TAX
	mov	ax, MSG_PCF_CHOOSER_CHANGE_DESCRIPTION
	call	ObjMessage 

	mov	bx, handle SSheetChooser
	mov	si, offset SSheetChooser
	clr	di
	mov	cx, PCFID_CTERM
	call	ObjMessage 	

if _STATISTICAL_FORMS
	mov	bx, handle StatsChooser
	mov	si, offset StatsChooser
	clr	di
	mov	cx, PCFID_SUM
	call	ObjMessage 	
endif ;if _STATISTICAL_FORMS

	mov	bx, handle ConsumerChooser
	mov	si, offset ConsumerChooser
	clr	di
	mov	cx, PCFID_CAR_MILAGE
	call	ObjMessage 	

	.leave
	ret
BigCalcProcessBringUpAllDescriptions	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessRestoreFromState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	restores from state

CALLED BY:	
PASS:		*ds:si	= BigCalcProcessClass object
		ds:di	= BigCalcProcessClass instance data
		ds:bx	= BigCalcProcessClass object (same as *ds:si)
		es 	= segment of BigCalcProcessClass
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if (NOT FALSE)
BigCalcProcessRestoreFromState	method dynamic BigCalcProcessClass, 
					MSG_GEN_PROCESS_RESTORE_FROM_STATE
	uses	ax, cx, dx, bp
	.enter

	push	ds
	mov	bx, bp
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[0]
	mov	ss:[extensionState], ax
	mov	ax, ds:[2]
	mov	ss:[calculatorMode], ax
	mov	al, ds:[4]
	mov	ss:[inverse], al
	call	MemUnlock
	mov	ss:[restoringFromState], TRUE
	pop	ds
		
	mov	ax, MSG_GEN_PROCESS_RESTORE_FROM_STATE
	mov	di, offset BigCalcProcessClass
	call	ObjCallSuperNoLock

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	bp, offset textBuffer
	mov	dx, ss
SBCS<	mov	{char} ss:[bp], '0'				>
DBCS<	mov	{wchar} ss:[bp], '0'				>
	mov	cx, 1
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjMessage 

	.leave
	ret
BigCalcProcessRestoreFromState	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	XX will save the state at some point...

CALLED BY:	
PASS:		*ds:si	= BigCalcProcessClass object
		ds:di	= BigCalcProcessClass instance data
		ds:bx	= BigCalcProcessClass object (same as *ds:si)
		ax	= message #
RETURN:		cx	= handle of extra state block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if (NOT FALSE)
BigCalcProcessCloseApplication	method dynamic BigCalcProcessClass, 
				MSG_GEN_PROCESS_CLOSE_APPLICATION

	;
	; free the floating point stack
	;
	call	FloatExit

	;
	; Save out some extra state
	;
	mov	ax, 5
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc			; handle => BX,
						; segment => AX

	mov	ds, ax
	mov	ax, ss:[extensionState]
	mov	ds:[0], ax
	mov	ax, ss:[calculatorMode]
	mov	ds:[2], ax
	mov	al, ss:[inverse]
	mov	ds:[4], al
	call	MemUnlock
	mov	cx, bx				; extra state block => CX

	ret
BigCalcProcessCloseApplication	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BCPButtonZzzPressed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when the 000 button is pressed in the DOVE
		version of the calculator.  Fakes three '0' button
		presses.

CALLED BY:	MSG_BCP_BUTTON_ZZZ_PRESSED
PASS:		*ds:si	= BigCalcProcessClass object
		ds:di	= BigCalcProcessClass instance data
		ds:bx	= BigCalcProcessClass object (same as *ds:si)
		es 	= segment of BigCalcProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andres	10/30/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessOperation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sends the opertaion to the approprite engine (RPN/Infix)

CALLED BY:	various trigegrs on the calculator
PASS:		*ds:si	= BigCalcProcessClass object
		ds:di	= BigCalcProcessClass instance data
		ds:bx	= BigCalcProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	looks at the global variable and determines from there where
	the arithmetic message will be sent

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/17/92   	Initial version
	EC	5/24/96		Added display requirements for different 
				operators [Penelope]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if (NOT FALSE)
BigCalcProcessOperation	method dynamic BigCalcProcessClass, 
					MSG_BC_PROCESS_CLEAR_ALL,
					MSG_BC_PROCESS_PLUS,
					MSG_BC_PROCESS_Y_TO_X,
					MSG_BC_PROCESS_MINUS,
					MSG_BC_PROCESS_ONE_OVER,
					MSG_BC_PROCESS_TIMES,
					MSG_BC_PROCESS_SQUARE,
					MSG_BC_PROCESS_DIVIDE,
					MSG_BC_PROCESS_SQUARE_ROOT,
					MSG_BC_PROCESS_ENTER,
					MSG_BC_PROCESS_PERCENT,
					MSG_BC_PROCESS_PLUSMINUS,
					MSG_BC_PROCESS_INVERSE,
					MSG_BC_PROCESS_SINE,
					MSG_BC_PROCESS_COSINE,
					MSG_BC_PROCESS_TANGENT,
					MSG_BC_PROCESS_LN,
					MSG_BC_PROCESS_LOG,
					MSG_BC_PROCESS_PI,
					MSG_BC_PROCESS_E,
					MSG_BC_PROCESS_FACTORIAL,
					MSG_BC_PROCESS_ARC_SINE,
					MSG_BC_PROCESS_ARC_COSINE,
					MSG_BC_PROCESS_ARC_TANGENT,
					MSG_BC_PROCESS_E_TO_X,
					MSG_BC_PROCESS_TEN_TO_X,
					MSG_BC_PROCESS_PI_OVER_TWO,
					MSG_BC_PROCESS_LEFT_PAREN,
					MSG_BC_PROCESS_RIGHT_PAREN,
					MSG_BC_PROCESS_SWAP,
					MSG_BC_PROCESS_ROLL_DOWN,
				MSG_BC_PROCESS_DISPLAY_CONSTANT_TOP_OF_STACK,
					MSG_BC_PROCESS_CONVERT
	uses	ax

	.enter

	;
	; save message
	;
	push	ax,cx

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay

if 0	; This logic has been moved to
	; CalcInputFieldVisTextFilterViaBeforeAfter. -dhunter 9/11/00
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_CHECK_ENTER_BIT
	call	ObjMessage

	jnc	doOperation

	call	BigCalcProcessPreFloatDup
	call	FloatDup

doOperation:
endif
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_CLEAR_ENTER_BIT
	call	ObjMessage

	;
	; retrieve message
	;
	pop	ax,cx

	;
	;	HACK!!!!!!!
	;
	; the ordering of all the MSG_BC_PROCESS_operation is the exact
	; the same as the MSG_CE_opertion so the ax we want is achieved
	; by the add down below
	;


	add	ax, MSG_CE_PLUS - MSG_BC_PROCESS_PLUS
	mov	bx, handle CalcResource
	mov	si, ss:[engineOffset]
	clr	di
	call	ObjMessage

	; plus-minus should not close out an operation

	cmp	ax, MSG_CE_PLUSMINUS
	LONG	jz	done

if (NOT FALSE)
	call	BigCalcProcessDisplayLineOnPaperTape
endif
	call	CEDisplayTopOfStack
if (NOT FALSE)
	call	CEDisplayOnPaperTapeWithDXBP
endif

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_SET_OP_DONE_BIT
	call	ObjMessage
done:
	.leave
	ret
BigCalcProcessOperation	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessDisplayLineOnPaperTape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	displays a line on the papertape

CALLED BY:	
PASS:		nothing 
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


BigCalcProcessDisplayLineOnPaperTape	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	bx, handle CalcResource
	mov	si, offset BigCalcPaperRoll

	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_GET_USABLE
	call	ObjMessage 

	jnc	done
	mov	dx, bx
	mov	bp, offset PaperRollLine
	clr	cx, di
	mov	ax, MSG_VIS_TEXT_APPEND_OPTR
	call	ObjMessage

	clr	di
	mov	ax, MSG_PAPER_ROLL_CHECK_LENGTH
	call	ObjMessage   

done:
	.leave
	ret
BigCalcProcessDisplayLineOnPaperTape	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clears the math engine

CALLED BY:	
PASS:		*ds:si	= BigCalcProcessClass object
		ds:di	= BigCalcProcessClass instance data
		ds:bx	= BigCalcProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/14/92   	Initial version
	andres	9/24/96		Fix to always display 0 in digital
				display
	andres	9/30/96		Set firstDigitOfNewOperand flag
	andres	10/17/96	clear PFR_replaceOp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcProcessClear	method dynamic BigCalcProcessClass, 
					MSG_BC_PROCESS_CLEAR
	uses	ax, cx, dx, bp
	.enter

	mov	bx, handle CalcResource
	GetResourceSegmentNS	dgroup, es	
	mov	si, ss:[engineOffset]


	clr	di
	mov	ax, MSG_CE_CLEAR
	call	ObjMessage


	.leave
	ret
BigCalcProcessClear	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessChangeMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	changes the calculator mode

CALLED BY:	
PASS:		ds,es	= dgroup
		cx	= CalculatorMode to switch to
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RPN_CAPABILITY

BigCalcProcessChangeMode	method dynamic BigCalcProcessClass, 
					MSG_BC_PROCESS_CHANGE_MODE
	uses	ax, cx, dx, bp
	.enter

	mov	ss:[calculatorMode], cx

	mov	ax, MSG_CE_SET_RPN_MODE
	cmp	cx, CM_RPN
	je	setMode
	mov	ax, MSG_CE_SET_INFIX_MODE
setMode:
	mov	bx, handle CalcResource
	mov	si, ss:[engineOffset]
;	mov	si, offset BigCalcInfixEngine
	clr	di
	call	ObjMessage

	; Tell the application object that a user option has changed
	;
	call	BigCalcNotifyOptionsChange

	.leave
	ret
BigCalcProcessChangeMode	endm

endif ;if _RPN_CAPABILITY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessUpdateNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	updates the number in the display according to the setting
		in the Customize box 

CALLED BY:	MSG_BC_PROCESS_UPDATE_NUMBER
PASS:		*ds:si	= BigCalcProcessClass object
		ds:di	= BigCalcProcessClass instance data
		ds:bx	= BigCalcProcessClass object (same as *ds:si)
		es 	= segment of BigCalcProcessClass
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcProcessUpdateNumber	method dynamic BigCalcProcessClass, 
					MSG_BC_PROCESS_UPDATE_NUMBER
		.enter
	;
	; Reset the display
	;
		call	CEDisplayTopOfStack
	;
	; Tell the application object that a user option has changed
	;
		call	BigCalcNotifyOptionsChange

		.leave
		ret
BigCalcProcessUpdateNumber	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessChangeExtensionsState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the state of the various extensions (Math, Scientific)

CALLED BY:	UI

PASS:		ds,es	= dgroup
		cx	= ExtensionType

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/7/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcProcessChangeExtensionsState	method dynamic BigCalcProcessClass, 
					MSG_BC_PROCESS_CHANGE_EXTENSIONS_STATE
		uses	ax, bx, dx, di, si
		.enter
	;
	; First check to see what to do about the math extensions
	;
		cmp	cx, ds:[extensionState]
		pushf				; save results - used later!
		mov	ds:[extensionState], cx
		mov	ax, offset BigCalcProcessSetNotUsable
		test	cx, mask EXT_MATH
		jz	setMathState
		mov	ax, offset BigCalcProcessSetUsable
setMathState:
		mov	bx, handle CalcResource
		mov	si, offset CalcResource:ButtonOneOver
		call	ax
		mov	si, offset CalcResource:ButtonPercent
		call	ax
		mov	si, offset CalcResource:ButtonSquare
		call	ax
		mov	si, offset CalcResource:ButtonSquareRoot
		call	ax
	;
	; Need to be careful here, since the parens share the
	; same keypad space as two keys in RPN mode. So..., if
	; we are in RPN mode, we don't change anything.
	;
		cmp	ds:[calculatorMode], CM_RPN
		je	checkScientific
		mov	si, offset CalcResource:ButtonLeftParen
		call	ax
		mov	si, offset CalcResource:ButtonRightParen
		call	ax
	;
	; Now check to see what to do about the scientific extensions
	;
checkScientific:
if _SCIENTIFIC_REP
		mov	ax, offset BigCalcProcessSetNotUsable
		test	cx, mask EXT_SCIENTIFIC
		jz	setScientificState
		mov	ax, offset BigCalcProcessSetUsable
setScientificState:
		mov	bx, handle ExtensionResource
		mov	si, offset ExtensionResource:DegreeItemGroup
		call	ax
		mov	si, offset ExtensionResource:SciKeyPad
		call	ax
endif
	;
	; Queue a message to reset the geometry, but *only* if
	; we are moving to a reduced set of extensions (i.e. from
	; scientific down to math, or from math down to none).
	; Luckily, detecting this is easy, based upon a comparison
	; with the original extension state. We only bother to do
	; this to avoid screen flashing on starting up when something
	; other than the default configuration (minimal) has been selected
	; by the user.
	;
		popf				; if moving to a higher level
		jae	doNotify		; ...of extensions, skip reset
		mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	bx, handle BigCalcPrimary
		mov	si, offset BigCalcPrimary
		mov	di, mask MF_FORCE_QUEUE or \
			    mask MF_CHECK_DUPLICATE
		call	ObjMessage
	;
	; Tell the application object that a user option has changed
	;
doNotify:
		call	BigCalcNotifyOptionsChange

		.leave
		ret
BigCalcProcessChangeExtensionsState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessChangeWorksheetsState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the state (on/off) of the worksheets

CALLED BY:	UI

PASS:		ds,es	= dgroup
		cx	= Boolean (TRUE = on, FALSE = off)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/7/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcProcessChangeWorksheetsState	method dynamic BigCalcProcessClass, 
					MSG_BC_PROCESS_CHANGE_WORKSHEETS_STATE
		uses	ax, bx, dx, di, si
		.enter
	;
	; Set usable or not the set of worksheets
	;
		mov	ax, offset BigCalcProcessSetNotUsable
		tst	cx
		jz	setState
		mov	ax, offset BigCalcProcessSetUsable
setState:
		mov	bx, handle BigCalcBottomRowInteraction
		mov	si, offset BigCalcBottomRowInteraction
		call	ax
		mov	si, offset BigCalcBottomRowSeparator
		call	ax
	;
	; Queue a message to reset the geometry
	;
		mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	bx, handle BigCalcPrimary
		mov	si, offset BigCalcPrimary
		mov	di, mask MF_FORCE_QUEUE or \
			    mask MF_CHECK_DUPLICATE
		call	ObjMessage
	;
	; Tell the application object that a user option has changed
	;
		call	BigCalcNotifyOptionsChange
		
		.leave
		ret
BigCalcProcessChangeWorksheetsState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessChangePaperRollState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the state (on/off) of the paper roll

CALLED BY:	UI

PASS:		ds,es	= dgroup
		cx	= Boolean (TRUE = on, FALSE = off)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/7/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcProcessChangePaperRollState	method dynamic BigCalcProcessClass, 
					MSG_BC_PROCESS_CHANGE_PAPER_ROLL_STATE
		uses	ax, bx, dx, di, si
		.enter
	;
	; Set usable or not the paper roll & the trigger
	; that clears the contents of the roll
	;
		mov	ax, offset BigCalcProcessSetNotUsable
		tst	cx
		jz	setState
		mov	ax, offset BigCalcProcessSetUsable
setState:
		mov	bx, handle BigCalcPaperRoll
		mov	si, offset BigCalcPaperRoll
		call	ax
		mov	bx, handle ClearPaperRollButton
		mov	si, offset ClearPaperRollButton
		call	ax
	;
	; Queue a message to reset the geometry
	;
		mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	bx, handle BigCalcPrimary
		mov	si, offset BigCalcPrimary
		mov	di, mask MF_FORCE_QUEUE or \
			    mask MF_CHECK_DUPLICATE
		call	ObjMessage
	;
	; Tell the application object that a user option has changed
	;
		call	BigCalcNotifyOptionsChange

		.leave
		ret
BigCalcProcessChangePaperRollState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessSetUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the object that's passed in bx:si usable


CALLED BY:	
PASS:		bx -- handle of the object
		si -- offset of the object
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcProcessSetUsable	proc	near
	uses	ax,cx,dx,di,bp
	.enter

	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	ax, MSG_GEN_SET_USABLE
	clr	di
	call	ObjMessage

	.leave
	ret
BigCalcProcessSetUsable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessSetNotUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the object in bx:si not usable

CALLED BY:	
PASS:		bx:si object
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcProcessSetNotUsable	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	ax, MSG_GEN_SET_NOT_USABLE
	clr	di
	call	ObjMessage

	.leave
	ret
BigCalcProcessSetNotUsable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcNotifyOptionsChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the application object of a user-option change

CALLED BY:	Various

PASS:		Nothing

RETURN:		Nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/7/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcNotifyOptionsChange	proc	near
	uses	ax, bx, di, si
	.enter

	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	GetResourceHandleNS BigCalculatorAppObj, bx
	mov	si, offset BigCalculatorAppObj
	clr	di
	call	ObjMessage

	.leave
	ret
BigCalcNotifyOptionsChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CustBoxGetSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gets the settings

CALLED BY:	
PASS:		*ds:si	= CustBoxClass object
		ds:di	= CustBoxClass instance data
		ds:bx	= CustBoxClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		ax, cx (=bx) to be used for FloatFloatToAsciiStd_Format
		    cl	= MAX_DISPLAYABLE_LENGTH
		    ch	= DECIMAL_PRECISION
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/12/92   	Initial version
	AS	8/29/96		Added code for PENELOPE version that
				interperts 0 fixed decimals as round
				to nearest integer, and adds the
				"don't use fixed decimals"
				functionality
	andres	10/29/96	Don't need this for DOVE

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CustBoxGetSettings	method dynamic CustBoxClass, 
					MSG_CUST_BOX_GET_SETTINGS
	uses	dx, bp
	.enter


	;
	; get the # of digits after decimal point to put them in bl
	;
	mov	si, offset DecimalPlacesRange
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	ObjCallInstanceNoLock 		; decimal places -> dx

	mov	bl, dl


	mov	bh, DECIMAL_PRECISION
	push	bx

	mov	si, offset NotationItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock 

	cmp	ax, DU_SCIENTIFIC
	je	sciNotation

	clr	ax
	jmp	convert

sciNotation:
	mov	ax, mask FFAF_SCIENTIFIC

convert:
	;
	; get the fp# from the stack (and pop it)
	;
	pop	cx		; # of digits

	tst	cl
	jnz	notZeroDigits
	mov	cl, MAX_DISPLAYABLE_LENGTH
	ornf	ax, mask FFAF_NO_TRAIL_ZEROS
notZeroDigits:

	.leave
	ret
CustBoxGetSettings	endm



COMMENT @%%%%%%%%% RESPONDER/NON-RESPONDER COMMON CODE %%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessPreFloatDup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	utility function for proper fp calculation

CALLED BY:	global
PASS:		nothing 
RETURN:		fp stack unchanged if not empty
		zero on top if empty
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcProcessPreFloatDup	proc	far
	uses	ax,dx
	.enter

	call	FloatDepth
	tst	ax
	jnz	done

	call	Float0

done:
	.leave
	ret
BigCalcProcessPreFloatDup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessConvertToUpper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	makes the e into E in scientific notation

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if (NOT FALSE)

BigCalcProcessConvertToUpper	proc	far
	uses	ds,si
	.enter

	segmov	ds, es
	mov	si, di
	call	LocalUpcaseString

	.leave
	ret
BigCalcProcessConvertToUpper	endp

endif

ProcessCode	ends

