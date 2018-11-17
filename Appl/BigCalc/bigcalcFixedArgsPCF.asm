COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcFixedArgsPCF.asm

AUTHOR:		Christian Puscasiu, May  6, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT FixedArgsPCFGetSize	looks at the formula and decides how much
				space is need to allocate

    INT FixedArgsPCFFillInActualArg fills args into formula

    INT FixedArgsPCFGetAHthArgOfPCF returns the ASCII value of the ah-th
				entry

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/ 6/92		Initial revision
	andres	10/29/96	Don't need this for DOVE
	andres	11/18/96	Don't need this for PENLOPE

DESCRIPTION:
	utility stuff for FixedArgsPCF's
		

	$Id: bigcalcFixedArgsPCF.asm,v 1.1 97/04/04 14:38:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%% DON'T NEED THIS FOR RESPONDER %%%%%%%%%%%%%%%%%%%%%%@

CalcCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedArgsPCFCalculate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gets the args and computes the result

PSEUDO CODE/STRATEGY:
PASS:		*ds:si	= FixedArgsPCFClass object
		ds:di	= FixedArgsPCFClass instance data
		ds:bx	= FixedArgsPCFClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		result in the result field
DESTROYED:	nothing 
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVIION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedArgsPCFCalculate	method dynamic FixedArgsPCFClass, 
					MSG_PCF_CALCULATE
	uses	ax, cx, dx, bp
	.enter

	;
	; save the handle to the block
	;
	mov	ax, ds:[LMBH_handle]
	push	ax, si

	;
	; build out the string from the info in ds:di.PCFI_formula;
	; first find out how much space is needed
	;
	call	FixedArgsPCFGetSize
	;
	; allocate and lock a nice block of memory and lock it down
	; 
	mov	cx, mask HF_SHARABLE or mask HF_SWAPABLE
	call	MemAlloc

	;
	; save the handle
	;
	push	bx

	call	MemLock
	mov	es, ax

	;
	; set up the formula string in ds:bx and it will be copied
	; into es:bp
	;
	call	LocalGetNumericFormat		; list separator => DX	
	mov	bx, ds:[di].PCFI_formula
	mov	bx, ds:[bx]
if DBCS_PCGEOS
	jmp	lF2				; skip the pre-decrement stuff!
else
	dec	bx
	mov	bp, -1
endif

loopFormula:
	LocalNextChar	dsbx			; source
	LocalNextChar	esbp			; destination
DBCS<lF2:							>
	LocalCmpChar	ds:[bx], ','		; must convert list separator
	jne	checkArg			; ...to current system value
	LocalPutChar	dsbx, dx, noAdvance	; ...for parser to work!
checkArg:
	LocalCmpChar	ds:[bx], '$'
	je	callFiller
	LocalLoadChar	ax, ds:[bx]
SBCS<	mov	es:[bp], al		; store char		>
DBCS<	mov	es:[bp], ax					>
	LocalIsNull	ax		; Test char in register
	je	callParser
	jmp	loopFormula

callFiller:
	call	FixedArgsPCFFillInActualArg
	jmp	loopFormula

callParser:
	;
	; pass the memory handle that will need to be locked by the
	; parser 
	;
	pop	bx
	mov	bp, bx
	call	MemUnlock

	;
	; pass the handle to itself in cx:dx
	;
	pop	cx, dx

	call	BigCalcProcessPCFParseEval

	.leave
	ret
FixedArgsPCFCalculate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedArgsPCFGetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	looks at the formula and decides how much space is
		need to allocate

CALLED BY:	FixedArgsPCFCalculate
PASS:		*ds:[si]	- instance data of FixedArgsPCF
		ds:[di]		- same
RETURN:		ax		- size needed to be allocated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	ax <- (count '$' * (NUMBER_DISPLAY_WIDTH+3));
	ax += 100;			(* safety net *)
	if DBCS then ax *= 2;
	return ax.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedArgsPCFGetSize	proc	near
	class	FixedArgsPCFClass
	uses	bp
	.enter

	;
	; get the formula into ds:bp
	;
	mov	bp, ds:[di].PCFI_formula
	mov	bp, ds:[bp]

	;
	; set the counter to zero
	;
	clr	al

loopFormula:
	;
	; count the number of occurenceces of '$' in the formula in al
	;
	LocalIsNull	ds:[bp]
	je	computeAX
	LocalCmpChar	ds:[bp], '$'
	jne	nextChar
	inc	al				; '$' found, inc AL
nextChar:
	LocalNextChar	dsbp
	jmp	loopFormula
	
computeAX:
	;
	; every '$' can potentially require NUMBER_DISPLAY_WIDTH bytes
	; of space, plus a comm, plus a space
	;
SBCS <	mov	ah, (NUMBER_DISPLAY_WIDTH + 3)			>
DBCS <	mov	ah, (NUMBER_DISPLAY_WIDTH*2 + 3)		>
	mul	ah

	;
	; add some more space for the formula (and some security)
	;
SBCS<	add	ax, 100*(size char)				>
DBCS<	add	ax, 100*(size wchar)				>
DBCS<	shl	ax, 1		; ax <- byte count		>

	.leave
	ret
FixedArgsPCFGetSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedArgsPCFFillInActualArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fills args into formula

CALLED BY:	FixedArgsPCFCalculate, FixedArgsPCF
PASS:		*ds:si -- the PCF Obj
		ds:di -- its instance data
		es:bp -- space where to put the Arg into
		ds:bx -- the string that's being parsed
RETURN:		es:bp -- the string with the arg put there and bp
			updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedArgsPCFFillInActualArg	proc	near
	uses	ax,cx,dx,di,es,si
	.enter

	;
	; move over the $ 
	;
if DBCS_PCGEOS
	;	The code using Local macros won't be exactly like the
	;	original code since the original does math in AH.  The
	;	Local macros do math in AL or AX depending on byte size.
	;				--- brian witt

	LocalNextChar	dsbx
	LocalLoadChar	ax, ds:[bx]
	
EC <	LocalCmpChar	ax, '0'		>
EC <	jb	EC_bad			>
EC <	LocalCmpChar	ax, '9'		>
EC <	jna	EC_good			>
EC < EC_bad:				>
EC <	ERROR	$x_VARIABLE_IN_FORMULA_NOT_WELL_DEFINED	>
EC < EC_good:				>

	;
	; get the value from the Unicode
	;
	sub	ax, '0'
	mov	ah, al		; routine wants index in AH reg.
else
	inc	bx
	mov	ah, ds:[bx]
	
EC <	cmp	ah, '0'		>
EC <	jb	EC_bad		>
EC <	cmp	ah, '9'		>
EC <	ja	EC_bad		>
EC <	jmp	EC_good		>
EC < EC_bad:			>
EC <	ERROR	$x_VARIABLE_IN_FORMULA_NOT_WELL_DEFINED	>
EC < EC_good:			>

	;
	; get the value from the ASCII
	;
	sub	ah, '0'
endif
	call	FixedArgsPCFGetAHthArgOfPCF
	
	.leave
	ret
FixedArgsPCFFillInActualArg	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedArgsPCFGetAHthArgOfPCF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the ASCII value of the ah-th entry

CALLED BY:	FixedArgsPCFFillInActualArg
PASS:		ds:di	the instance data of the PCF
		ds:si	the PreCannedFunction
		es:bp	where to put the Ascii-value
		ah 	the line number
RETURN:		updated	es:bp
			with the AHth entry of the PCF
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedArgsPCFGetAHthArgOfPCF	proc	near
	
	uses	ax,bx,cx,dx,si,di,es
	class	PreCannedFunctionClass
	.enter

	;
	; save the object
	;
	push	si

	;
	; save the counter of the string
	;
	push	bp

	inc	ah
	mov	cl, ah
	clr	ch
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock

EC <	ERROR_C	THE_LINE_THAT_WE_WANTED_TO_ACCESS_DOESNT_EXIST	>

	;
	; get the CalcInputField of the line, which is the 2nd child of
	; the object we just got
	;
	mov	si, dx

	;
	; look for the 2nd child
	;
	mov	cx, 1
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock 

EC <	ERROR_C	THE_LINE_ISNT_RIGHT	>
	
	;
	; get the text out the FAPCFInputField's text-field
	;
	mov	bx, cx
	mov	si, dx

	;
	; retrieve the pointer and set up the text buffer
	;
	pop	bp
	mov	dx, es

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage

	tst	cx
	jnz	goodNumber

	;
	; one of the inputfields is empty so lets put a zero in there
	;
	mov	es, dx
SBCS<	mov	{char} es:[bp], '0'				>
DBCS<	mov	{wchar} es:[bp], '0'				>
	jmp	getObj

goodNumber:
	;
	; update bp to the current text position
	;
DBCS<	shl	cx, 1			; char count to byte offset	>
	add	bp, cx
	;
	; kind of a hack:
	; we have to decrement by one because when it returns to 
	; PCFCalculateFixedArgsPCF it gets incremented immediatly
	;
	LocalPrevChar	ssbp

getObj:
	;
	; retrieve the object
	;
	pop	si
SBCS<	mov	di, ds:[si].PreCannedFunction_offset	; UNUSED 	>

	.leave
	ret
FixedArgsPCFGetAHthArgOfPCF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedArgsPCFDisplayPCFResult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	displays PCF result

CALLED BY:	
PASS:		*ds:si	= FixedArgsPCFClass object
		ds:di	= FixedArgsPCFClass instance data
		ds:bx	= FixedArgsPCFClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		dx:bp	= farptr to the text that has to inserted
RETURN:		nothing 
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedArgsPCFDisplayPCFResult	method dynamic FixedArgsPCFClass, 
					MSG_PCF_DISPLAY_PCF_RESULT
	uses	ax, cx, dx, bp
	.enter

	mov	si, offset GenericFAPCFResultNumber
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	;
	; set the send button enabled
	;
;	mov	si, offset GenericFAPCFButtonSendCalc
;	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
;	mov	ax, MSG_GEN_SET_ENABLED
;	call	ObjCallInstanceNoLock 

	.leave
	ret
FixedArgsPCFDisplayPCFResult	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FAPCFInputFieldVisTextFilterViaBeforeAfter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	front-end to text filter

CALLED BY:	
PASS:		*ds:si	= FAPCFInputFieldClass object
		ds:di	= FAPCFInputFieldClass instance data
		ds:bx	= FAPCFInputFieldClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= handle to the before string
		dx	= handle to the after string
		ss:bp 	= VisTextReplaceParameters
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FAPCFInputFieldVisTextFilterViaBeforeAfter method dynamic FAPCFInputFieldClass,
					MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER
	uses	ax, cx, dx, bp
	.enter

	;
	; save itself
	;
	push	si

	;
	; get the after string into ds:si
	;
	mov	si, dx
	mov	si, ds:[si]
	call	InputFieldCheckIfValidFPNumber

	;
	; recover itself
	;
	pop	si

	jc	makeBeep

	;
	; save the length in bx
	;
	mov	bx, cx

	;	
	; save itelf & text
	;
	push	si, dx, bp

	;
	; set the result field to "?" because the entries have been
	; altered 
	;
	; HACK!!
	; I know that there is more space behind the dx:bp so I'll
	; just use that for updating the result field "?"
	;
	add	bp, 40
	; mov	cx, dgroup
	; mov	es, cx
	GetResourceSegmentNS	dgroup, es

if DBCS_PCGEOS
	mov	{wchar} es:[bp], '?'
	mov	{wchar} es:[bp]+2, 0
else
	mov	{char} es:[bp], '?'
	mov	{char} es:[bp][1], 0
endif
	mov	cx, 1
	mov	si, offset GenericFAPCFResultNumber
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	;
	; set the "Send to Calc" disabled, as there is no valid result
	;
;	mov	si, offset GenericFAPCFButtonSendCalc
;	mov	dl, VUM_NOW
;	mov	ax, MSG_GEN_SET_NOT_ENABLED
;	call	ObjCallInstanceNoLock 
	
	;
	; recover itself & text
	;
	pop	si, dx, bp

	;
	; carry means that there was no illegal charcater found so I
	; composed a legal fp number from the input given
	;
	mov	es, dx
	LocalIsNull	es:[bp]
	je	newStringIsEmpty

	;
	; use the string in dx:bp
	;
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	mov	cx, bx
	mov	dx, cx
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	call	ObjCallInstanceNoLock 

	jmp	reject

makeBeep:
	;
	; show the user that we discarded his input
	;
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
	jmp	reject

newStringIsEmpty:
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	ObjCallInstanceNoLock

reject:
	;
	; we always reject the string (because the general user cannot
	; be trusted :).  He either enerted an illegal character which
	; means, that we are just going to ignore the input.  Or we
	; check and make sure he entered a valid number.
	;
	stc

	.leave
	ret

FAPCFInputFieldVisTextFilterViaBeforeAfter	endm

CalcCode	ends
