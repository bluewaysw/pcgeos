COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcPCF.asm

AUTHOR:		Christian Puscasiu, Apr 16, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT BigCalcProcessPCFParseEval Sets up the buffer for the parser and
				evaluator

    INT BigCalcProcessPCFEvalString feed a string and get the result on the
				FP stack

    INT PCFCallback

    INT BigCalcProcessPrintPCFResult Print the result of a fixed-args
				worksheet

    INT PreCannedFunctionInitFormula utility function to read in the
				generic formula of the PCF

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/16/92		Initial revision
	andres	10/29/96	Not needed for DOVE
	andres	11/18/96	Don't need this for PENELOPE

DESCRIPTION:
	Holds all of the PreCannedFunction stuff that is common to all
	PCFs

		

	$Id: bigcalcPCF.asm,v 1.1 97/04/04 14:37:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCFChooserChangeDecscription
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		*ds:si	= PCFChooserClass object
		ds:di	= PCFChooserClass instance data
		ds:bx	= PCFChooserClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= the item that has been selected
RETURN:		nothing 
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Changes the description when scrolling through different PCFs

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCFChooserChangeDecscription	method dynamic PCFChooserClass, 
					MSG_PCF_CHOOSER_CHANGE_DESCRIPTION
	uses	ax, cx, dx, bp
	.enter

	mov	dx, handle DescriptionResource

	;
	; multiply cx by two to get the cx-th entry in the table
	;
	shl	cx
	
	mov	bp, offset PCFDescriptionTable
	add	bp, cx

	mov	bp, cs:[bp]

	mov	si, ds:[di].PCFCI_description.offset
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	call	ObjCallInstanceNoLock

	.leave
	ret
PCFChooserChangeDecscription	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessPCFParseEval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the buffer for the parser and evaluator

CALLED BY:	FixedArgsPCFCalculate, VariableArgsPCFCalculate
PASS:		*ds:si	= BigCalcProcessClass object
		ds:di	= BigCalcProcessClass instance data
		ds:bx	= BigCalcProcessClass object (same as *ds:si)
		^lcx:dx	= the PCF
		bp	= handle to the string in es:bx
		es 	= dgroup
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBCS <MINIMUM_SCRATCH_BUFFER_SIZE	equ	1024			>
DBCS <MINIMUM_SCRATCH_BUFFER_SIZE	equ	2048			>

BigCalcProcessPCFParseEval	proc	near
	uses	ax, cx, dx, bp
	.enter

	;
	; Reallocate the current block to hold enough room for both the
	; parser and the evaluator. Each requires a minimum amount of
	; scratch space, and both the original expression and the scratch
	; space needs to reside in the same block.
	;
	; We force at least a minimum amount of scratch buffer space to
	; be made available, and we can make no assumptions about the
	; maximum formula size, as this routine evaluates the wonderfully
	; unbounded Sum/Average/Mean calculations.
	;
	push	cx, dx				; save PCF OD
	mov	bx, bp				; memory handle => BX
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	cmp	ax, MINIMUM_SCRATCH_BUFFER_SIZE
	jae	doubleIt
	mov	ax, MINIMUM_SCRATCH_BUFFER_SIZE
doubleIt:
	mov	di, ax				; DI = start of scratch space
	shl	ax, 1
	mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK
	call	MemReAlloc
	mov	ds, ax				; DS:0  = expression (formula)
	mov	es, ax				; ES:DI = scratch space

	;
	; evaluate parse the expression, and evaluate it
	;
	call	BigCalcProcessPCFEvalString	; carry = SET if error
	
	;
	; free the memory block (bx is the same)
	;
	pushf	
	call	MemFree
	popf

	;
	; send the result to the result field
	;
	pop	cx, dx				; restore PCF OD
	call	BigCalcProcessPrintPCFResult

	.leave
	ret
BigCalcProcessPCFParseEval	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessPCFEvalString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	feed a string and get the result on the FP stack

CALLED BY:	BigCalcProssPCFParseEval
PASS:		ds:0	= null-terminated string to evaluate
		es:di	= buffer that's used by the parser 
	
	!! es == ds because of a bug in ParseString right now !!
	CP 1/94:
	This is still the case.  Maybe ParseString is happy the way it
	is.

RETURN:		carry set on error
		    Nothing on the floating-point stack
		carry clear otherwise
		    Result of expression on float-stack
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcProcessPCFEvalString	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds,es
	parseArgs	local	ParserParameters
	evalArgs	local	EvalParameters
	.enter

	;
	; make ds:si point to the string to evaluate
	;
	clr	si

	;
	; save bp around the `lea`, save di - the beginning of the
	; buffer where the parsed data is going to be put into
	;
	push	bp, di

	;
	; es:di has to stay within the block
	;
	LocalPrevChar	esdi		; keep on char boundry

	clr	parseArgs.PP_common.CP_row
	clr	parseArgs.PP_common.CP_column
	clr	parseArgs.PP_common.CP_maxRow
	clr	parseArgs.PP_common.CP_maxColumn
if _FXIP
	mov	parseArgs.PP_common.CP_callback.segment, vseg PCFCallback
else
	mov	parseArgs.PP_common.CP_callback.segment, cs
endif
	mov	parseArgs.PP_common.CP_callback.offset, offset PCFCallback
SBCS <	mov	parseArgs.PP_common.CP_cellParams.offset, offset PCFCallback >
	mov	parseArgs.PP_parserBufferSize, di
	mov	parseArgs.PP_flags, mask PF_NUMBERS or \
				    mask PF_FUNCTIONS or \
				    mask PF_OPERATORS
	lea	bp, parseArgs

	;
	; restore es:di
	;
	LocalNextChar	esdi

	call	ParserParseString			; carry = set if error

	;
	; restore bp, point si to the beginning of parsed data
	;
	pop	bp, si
EC <	ERROR_C	UNEXPECTED_ERROR_FROM_PARSE_STRING			>
NEC <	jc	done							>
	;
	; make ds:si point at the parsed expression
	;
	segxchg	es, ds
	
	;
	; make es:di the base of the scratch buffer
	;
	clr	di

	;
	; save bp around the `lea`
	;
	push	bp

	clr	evalArgs.EP_common.CP_row
	clr	evalArgs.EP_common.CP_column
	clr	evalArgs.EP_common.CP_maxRow
	clr	evalArgs.EP_common.CP_maxColumn
if _FXIP
	mov	evalArgs.EP_common.CP_callback.segment, vseg PCFCallback
else
	mov	evalArgs.EP_common.CP_callback.segment,cs
endif
	mov	evalArgs.EP_common.CP_callback.offset, offset PCFCallback
	mov	evalArgs.EP_common.CP_cellParams.offset, offset PCFCallback
	clr	evalArgs.EP_flags
	lea	bp, evalArgs
	mov	cx, si
	dec	cx				; buffer size => CX

	;
	; Ask that the expression be evaluated, and look for any
	; errors after the evaluation
	;
	call	ParserEvalExpression		; result => fp stack
	pop	bp
	jc	done				; if error, return carry set
	test	es:[bx].ASE_type, mask ESAT_ERROR
	jz	done
	stc					; if error, return carry set
done:
	.leave
	ret
BigCalcProcessPCFEvalString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCFCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCFCallback	proc	far
	.enter

	;
	; no errors should occur
	;
	clc

	.leave
	ret
PCFCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessPrintPCFResult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the result of a fixed-args worksheet

CALLED BY:	
PASS:		^lcx:dx -- the PCF
		carry	-- set if error in evaluation
RETURN:		result on screen on the result field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/24/92		Initial version
	AS	9/ 8/96		removed call to ChangeToUpper for
				PENELOPE version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcProcessPrintPCFResult	proc	near
	class	PreCannedFunctionClass
	uses	ax,bx,cx,dx,si,di
	.enter

	;
	; ^lbx:si == PCF
	;
	movdw	bxsi, cxdx
	call	MemDerefDS			; PCF => *DS:SI
LONG	jc	evaluationError

	call	BigCalcProcessPreFloatDup
	call	FloatDup

	mov	di, ds:[si]
	add	di, ds:[di].PreCannedFunction_offset
	mov	ah, ds:[di].PCFI_resultFormat

	cmp	ah, PCFRF_GLOBAL_SETTINGS
	jne	checkDollarsAndCents

	push	si

	mov	bx, handle CustomizeBox
	mov	si, offset CustomizeBox
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CUST_BOX_GET_SETTINGS
	call	ObjMessage 
	mov	bx, cx

	pop	si

	jmp	convert

checkDollarsAndCents:
	cmp	ah, PCFRF_DOLLARS_AND_CENTS
	jne	checkInteger
	clr	ax
	mov	bx, 2 or (DECIMAL_PRECISION shl 8)
	jmp	convert

checkInteger:
EC<	cmp	ah, PCFRF_INTEGER		>
EC<	ERROR_NE NOT_A_CORRECT_PCFRF_TYPE	>
	clr	ax
	mov	bx, 0 or (DECIMAL_PRECISION shl 8)

convert:
	GetResourceSegmentNS	dgroup, es
	mov	di, offset textBuffer
	call	FloatFloatToAscii_StdFormat

if (NOT FALSE)
	jcxz	convertToUpper
displayResult:
endif

	;
	; display the result in the result field and set the send
	; button enabled
	;
	mov	dx, es
	mov	bp, di
	mov	ax, MSG_PCF_DISPLAY_PCF_RESULT
	call	ObjCallInstanceNoLock 

	mov	ax, MSG_PCF_SET_RESULT
	call	ObjCallInstanceNoLock 
done:
	.leave
	ret

if (NOT FALSE)
convertToUpper:
	call	BigCalcProcessConvertToUpper
	jmp	displayResult
endif

evaluationError:
	;
	; evaluation error occurred, so display ERROR string. Don't
	; change the display in the main Calculator window
	;
	mov	bx, handle EvalErrorString
	call	MemLock
	mov	es, ax
	mov	dx, ax				
	assume	es:DescriptionResource
	mov	bp, es:[EvalErrorString]
	assume	es:Nothing			; error string => DX:BP
	clr	cx				; it is NULL-terminated
	mov	ax, MSG_PCF_DISPLAY_PCF_RESULT
	call	ObjCallInstanceNoLock 
	call	MemUnlock			; unlock string resource
	jmp	done
BigCalcProcessPrintPCFResult	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreCannedFunctionInitFormula
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	utility function to read in the generic formula of the
		PCF 

CALLED BY:	Fixed/VariableArgsPCFInitInstanceData
PASS:		es:bx	= formula
		di	= offset to where the formula in the formula
			instance data points to
		ds	= block in which the string to which formula
			should be copied to (ds:GenericFAPCFFormula)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/29/92		Initial version
	witt	10/18/93	DBCS-ized string copy; reduced regs saved.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PreCannedFunctionInitFormula	proc	near
SBCS<	uses	ax,bx,cx,dx,si,di,bp,es,ds			>
DBCS<	uses	ax,si,di,es,ds					>
	.enter

	;
	; set up ds:si for the lodsb instruction
	;
	segxchg	ds, es
	mov	si, bx
	mov	si, ds:[si]

	;
	; source ds:si, destination es:di
	;
	mov	di, es:[di]
if DBCS_PCGEOS
	LocalCopyString		; copies NULL as well.
else
	lodsb

repeat:
	mov	es:[di], al
	inc	di
	lodsb
	tst	al
	jnz	repeat
endif
	.leave
	ret
PreCannedFunctionInitFormula	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreCannedFunctionSetResult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the result of the PCF in the main calculator
		display


CALLED BY:	
PASS:		*ds:si	= PreCannedFunctionClass object
		ds:di	= PreCannedFunctionClass instance data
		ds:bx	= PreCannedFunctionClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		nothing 
DESTROYED:	all

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PreCannedFunctionSetResult	method dynamic PreCannedFunctionClass, 
					MSG_PCF_SET_RESULT
	.enter

	call	BigCalcProcessPreFloatDup
	call	FloatDup

	segmov	es, ds
	add	di, offset PCFI_resultFloat
	call	FloatPopNumber

	mov	bx, handle 0
	clr	di
	mov	ax, MSG_BC_PROCESS_DISPLAY_CONSTANT_TOP_OF_STACK
	call	ObjMessage 

	.leave
	ret
PreCannedFunctionSetResult	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCFClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the PCF

CALLED BY:	MSG_PCF_CLOSE
PASS:		*ds:si	= PreCannedFunctionClass object
		ds:di	= PreCannedFunctionClass instance data
		ds:bx	= PreCannedFunctionClass object (same as *ds:si)
		es 	= segment of PreCannedFunctionClass
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Check the inifile whether there is a limit on how many PCFs
	there can be up.  This is important for low memory machines
	like PDAs.  If that category doesn't exist or the number is 
	xero, there exists no limit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	7/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCFClose	method dynamic PreCannedFunctionClass, 
					MSG_PCF_CLOSE
	uses	ax, cx, dx, bp
	.enter

	push	ds:[LMBH_handle], si

	; See if we limit the number of worksheets open at a time. If
	; the key is not present (or equal to zero), we just close the
	; dialog box. Otherwise, we always destroy it, as we assume
	; memory concerns are present.
	;
	mov	cx, cs
	mov	dx, offset numberwsString	;cx:dx <- key
	mov	ds, cx
	mov	si, offset configString		;ds:si <- category
	clr	bp				;assume we'll just close
	call	InitFileReadInteger
	jc	callHolder			;if no limit set, just close it
	tst	ax
	jz	callHolder			;if unlimited, just close it
	inc	bp				;..else destroy the dialog now

callHolder:
	mov	bx, handle BigCalcPCFHolder
	mov	si, offset BigCalcPCFHolder
	pop	cx, dx
	clr	di
	mov	ax, MSG_PCF_HOLDER_CLOSE_PCF
	call	ObjMessage

	.leave
	ret
PCFClose	endm

configString	char	"bigcalc",0
numberwsString	char	"numberWS",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCFResultDisplaySpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SpecBuild

CALLED BY:	
PASS:		*ds:si	= PCFResultDisplayClass object
		ds:di	= PCFResultDisplayClass instance data
		ds:bx	= PCFResultDisplayClass object (same as *ds:si)
		es 	= segment of PCFResultDisplayClass
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCFResultDisplaySpecBuild	method dynamic PCFResultDisplayClass, 
					MSG_SPEC_BUILD
	uses	ax, cx, dx, bp
	.enter

	call	BigCalcLEDDisplaySetColors

	mov	di, offset PCFResultDisplayClass
	mov	ax, MSG_SPEC_BUILD
	call	ObjCallSuperNoLock

	.leave
	ret
PCFResultDisplaySpecBuild	endm

;------------------------------------------------------------------------------
;	Table (order important)
;------------------------------------------------------------------------------
PCFDescriptionTable	word	\
\
	offset	PCFAverageDescription,
	offset	PCFCtermDescription,
	offset	PCFDblDeclBalanceDescription,
	offset	PCFFutureValueDescription,
	offset	PCFPaymentDescription,
	offset	PCFPresentValueDescription,
	offset	PCFRateDescription,
	offset	PCFStandardDeviationDescription,
	offset	PCFStraightLineDepDescription,
	offset	PCFSumDescription,
	offset	PCFSumOfYearDepDecription,
	offset	PCFTermDescrpition,
	offset	PCFVarianceDescription,
	offset	PCFSalesTaxDescription,
	offset	PCFSalesTotalDescription,
	offset	PCFProfitMarginDescription,
	offset	PCFMarkupCostDescription,
	offset	PCFMarkupProfitDescription,
	offset	PCFDiscountDescription,
	offset	PCFBreakEvenDescription,
	offset	PCFBreakevenProfitDescription,
	offset	PCFHomeLoanDescription,
	offset	PCFCarLoanDescription,
	offset	PCFCollegeDescription,
	offset	PCFSavingsGoalDescription,
	offset	PCFCarMilageDescription,
	offset	PCFCarLeaseDescription,
	offset	PCFLoanAmountDescription,
	offset	PCFLoanPmtDescription,
	offset	PCFLoanInterestDescription,
	offset	PCFHomeSaleDescription,
	offset	PCFHomePurLoanDescription
CheckHack	<(length PCFDescriptionTable) eq PreCannedFunctionID>

CalcCode	ends


