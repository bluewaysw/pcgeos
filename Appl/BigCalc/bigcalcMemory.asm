COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcMemory.asm

AUTHOR:		Christian Puscasiu, May 28, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT MemoryInputFieldSetOpDoneBit

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/28/92		Initial revision
	andres	11/25/96	Cleaned up for DOVE

DESCRIPTION:
	holds all functions that relate to the Memory functionality	
		

	$Id: bigcalcMemory.asm,v 1.1 97/04/04 14:38:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CalcCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemoryInputFieldLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a stored value from the .INI file

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= MemoryInputFieldClass object
		es 	= dgroup
		ax	= message #

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/12/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemoryInputFieldLoadOptions	method dynamic	MemoryInputFieldClass,
						MSG_META_LOAD_OPTIONS
		.enter
	;
	; Call our superclass first to load any/all data
	;
		mov	di, offset MemoryInputFieldClass
		call	ObjCallSuperNoLock
	;
	; If any text was loaded, then store the FP number away
	;
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		clr	dx
		call	ObjCallInstanceNoLock
		mov	bx, cx		
		mov_tr	cx, ax
		jcxz	done
	;
	; Convert the string int a FP number. If we can't parse
	; it, we don't care - that problem will be fixed if the
	; user attempts to edit the number.
	;
		mov	di, ds:[si]
		add	di, ds:[di].MemoryInputField_offset
		add	di, offset MIFI_fpMemory
		segmov	es, ds			; FP buffer => ES:DI
		call	MemLock
		mov	ds, ax
		clr	si			; source => DS:SI
		mov	al, mask FAF_STORE_NUMBER
		call	FloatAsciiToFloat
	;
	; Clean-up, we're done
	;
done:
		call	MemFree

		.leave
		ret
MemoryInputFieldLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemoryInputFieldSaveOptionsAndSendIC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a stored value from the .INI file

CALLED BY:	MSG_MEM_IF_SAVE_OPTIONS_AND_SEND_IC

PASS:		*ds:si	= MemoryInputFieldClass object
		es 	= dgroup
		ax	= message #
		cx	= InteractionCommand
		dx	= Chunk handle of parent

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/12/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemoryInputFieldSaveOptionsAndSendIC	method dynamic	MemoryInputFieldClass,
					MSG_MEM_IF_SAVE_OPTIONS_AND_SEND_IC
	;
	; Send the InteractionCommand up the tree
	;
		push	dx
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		call	ObjCallInstanceNoLock
	;
	; Save the options and boogie
	;
		mov	ax, MSG_META_SAVE_OPTIONS
		pop	si
		GOTO	ObjCallInstanceNoLock
MemoryInputFieldSaveOptionsAndSendIC	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeBackspaceOnNegDigitEqZero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If previous string was "-0" and current is "-", then
		a backspace was hit and we want the string to be "0" 

CALLED BY:	MemoryInputFieldVisTextFilterViaBeforeAfter()
PASS:		ds:si	= MemoryInputFieldClass instance data
		cx	= handle to before string
		dx	= handle to after string
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeBackspaceOnNegDigitEqZero	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Does old string eq "-0" ?
	;
	mov	si, cx				; handle to old string
	mov	si, ds:[si]
	LocalCmpChar	ds:[si], '-'
	jne	done
	inc	si
DBCS <	inc	si							>
	LocalCmpChar	ds:[si], '0'
	jne	done
	;
	; Does new string have length 1
	;
	mov	si, dx
	mov	si, ds:[si]
	inc	si
DBCS <	inc	si							>
	LocalCmpChar	ds:[si], C_NULL
	jne	done
	;
	; Replace "-" with "0"
	;
	LocalLoadChar	ax, '0'
	dec	si
DBCS <	dec	si							>
	LocalPutChar	dssi, ax
done:
	.leave
	ret
MakeBackspaceOnNegDigitEqZero	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemoryInputFieldVisTextFilterViaBeforeAfter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	front-end to filtering

CALLED BY:	
PASS:		*ds:si	= MemoryInputFieldClass object
		ds:di	= MemoryInputFieldClass instance data
		ds:bx	= MemoryInputFieldClass object (same as *ds:si)
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
	CP	5/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemoryInputFieldVisTextFilterViaBeforeAfter\
			method dynamic MemoryInputFieldClass,
					MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER
	uses	ax, cx, dx, bp
	.enter
	;
	; Check if backspace on "-" + single digit.  If so, make "0"
	;
	call	MakeBackspaceOnNegDigitEqZero
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
	; retrieve itstelf
	;
	pop	si

	jc	makeBeep

	;
	; carry means that there was no illegal charcater found so I
	; composed a legal fp number from the input given
	;
	tst	al
	jz	newStringIsEmpty

	;
	; use the string in dx:bp
	;
	push	si

	;
	; save the length of the replacement in bx
	;
	mov	bx, cx

	;
	; setting up es:di to where to write the float to
	;
	mov	di, ds:[si]
	add	di, ds:[di].MemoryInputField_offset
	add	di, offset MIFI_fpMemory
	segxchg	es, ds

	;
	; setting up string in dx:bp to ds:si
	;
	mov	si, bp
	mov	ds, dx
	mov	al, mask FAF_STORE_NUMBER
	mov	cx, NUMBER_DISPLAY_WIDTH
	call	FloatAsciiToFloat


	pop	si
	segmov	ds, es

	;
	; get the current position of the text into cx
	;
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	mov	cx, bx
	mov	dx, cx
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	call	ObjCallInstanceNoLock 

	mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
	mov	cx, 1				; mark object as modified
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
MemoryInputFieldVisTextFilterViaBeforeAfter	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemoryInputFieldGetFromCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gets the currnetly displayed fp number

CALLED BY:	
PASS:		*ds:si	= MemoryInputFieldClass object
		ds:di	= MemoryInputFieldClass instance data
		ds:bx	= MemoryInputFieldClass object (same as *ds:si)
		ax	= message #
RETURN:		the currently displayed number in the memory field
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/28/92   	Initial version
	AS	9/ 8/96		Disable displaying MS on paper tape
				for PENELOPE version
	AS	9/17/96		Sets the lastKeyHit variable

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemoryInputFieldGetFromCalc	method dynamic MemoryInputFieldClass, 
					MSG_IF_GET_FROM_CALC
	uses	ax, cx, dx, bp
	.enter


	call	BigCalcProcessPreFloatDup
	call	FloatDup

	segmov	es, ds
	GetResourceSegmentNS 	dgroup, ds
	add	di, offset MIFI_fpMemory
	call	FloatPopNumber

	;
	; save itself
	;
	push	si

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	segxchg	es, ds
	mov	dx, es
	mov	bp, offset textBuffer
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage 

	;
	; retrive the memory number obj
	;
	pop	si

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	; This is not an operation!  dhunter 9/11/00
;;	call	MemoryInputFieldSetOpDoneBit

	.leave
	ret
MemoryInputFieldGetFromCalc	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemoryInputFieldSendToCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		*ds:si	= MemoryInputFieldClass object
		ds:di	= MemoryInputFieldClass instance data
		ds:bx	= MemoryInputFieldClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		the memory number in the calculator display
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/28/92   	Initial version
	AS	9/17/96		Set the lastKeyHit variable and
				display operator if necessary

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemoryInputFieldSendToCalc	method dynamic MemoryInputFieldClass, 
					MSG_IF_SEND_TO_CALC
	uses	ax, cx, dx, bp
	.enter


	mov	si, di
	add	si, offset MIFI_fpMemory
	call	FloatPushNumber

;	call	InfixEngineCalcInputFieldCheckUnaryOpDone
;	jnc	goAhead

;	call	FloatDup

;goAhead:

	mov	bx, handle 0
	clr	di
	mov	ax, MSG_BC_PROCESS_DISPLAY_CONSTANT_TOP_OF_STACK
	call	ObjMessage 

	; This was already done by the above message. -dhunter 9/11/00
;;	call	MemoryInputFieldSetOpDoneBit

	.leave
	ret
MemoryInputFieldSendToCalc	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemoryInputFieldMemoryPlusMinus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adds/subtracts the current number to the active memory

CALLED BY:	
PASS:		*ds:si	= MemoryInputFieldClass object
		ds:di	= MemoryInputFieldClass instance data
		ds:bx	= MemoryInputFieldClass object (same as *ds:si)
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/ 3/92   	Initial version
	AS	9/ 8/96		Removed call to ChangeToUpper for
				PENELOPE version
	andres	10/29/96	No CustomizeBox in DOVE
	andres	11/19/96	Don't need this for Penelope

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemoryInputFieldMemoryPlusMinus	method dynamic MemoryInputFieldClass, 
					MSG_MEM_IF_MEMORY_PLUS,
					MSG_MEM_IF_MEMORY_MINUS
	uses	ax, cx, dx, bp
	.enter

	;
	; save the message in dx, as FloatDup will trash ax
	;
	mov	dx, ax

	call	BigCalcProcessPreFloatDup
	call	FloatDup

	mov	si, di
	add	si, offset MIFI_fpMemory
	GetResourceSegmentNS	dgroup, es
	call	FloatPushNumber

	cmp	dx, MSG_MEM_IF_MEMORY_PLUS
	jne	minus

	call	FloatAdd
	jmp	store

minus:
	call	FloatSub
	call	FloatNegate

store:
	;
	; we need the number once so we can store it in the
	; MIFI_fpMemory field and another time for the
	; FloatFloatToAscii_StdFormat
	;
	call	BigCalcProcessPreFloatDup
	call	FloatDup

	segxchg	es, ds
	mov	di, si
	call	FloatPopNumber
	segxchg	ds, es

	mov	bx, handle CustomizeBox
	mov	si, offset CustomizeBox
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CUST_BOX_GET_SETTINGS
	call	ObjMessage 
	mov	bx, cx

	mov	di, offset textBuffer
	call	FloatFloatToAscii_StdFormat
	jcxz	convertToUpper
displayResult:

	;
	; display the number in the "Active Memory" spot
	;
	mov	si, offset MemoryNumber0
	mov	dx, es
	mov	bp, di
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	; This is not an operation!!  dhunter 9/11/00
;;	call	MemoryInputFieldSetOpDoneBit

	.leave
	ret

convertToUpper:
	call	BigCalcProcessConvertToUpper
	jmp	displayResult

MemoryInputFieldMemoryPlusMinus	endm

if 0	; No longer required. -dhunter 9/11/00

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemoryInputFieldSetOpDoneBit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		nothing 
RETURN:		sets the operationDoneBit
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemoryInputFieldSetOpDoneBit	proc	near
	uses	ax,bx,si,di
	.enter
	
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	clr	di
	mov	ax, MSG_CALC_IF_SET_OP_DONE_BIT
	call	ObjMessage

	.leave
	ret
MemoryInputFieldSetOpDoneBit	endp
endif

if (0)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemoryInputFieldCurrencyLeftToRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	does the currency conversion from left to right

CALLED BY:	MSG_IF_CURRENCY_LEFT_TO_RIGHT
PASS:		*ds:si	= MemoryInputFieldClass object
		ds:di	= MemoryInputFieldClass instance data
		ds:bx	= MemoryInputFieldClass object (same as *ds:si)
		es 	= segment of MemoryInputFieldClass
		ax	= message #
RETURN:		the converted currency
DESTROYED:	nothing 
SIDE EFFECTS:	nothing 

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	7/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemoryInputFieldCurrencyLeftToRight	method dynamic MemoryInputFieldClass, 
					MSG_IF_CURRENCY_LEFT_TO_RIGHT
	uses	ax, cx, dx, bp
	.enter
DBCS<	ErrMessage < MemoryInputFIeldCurrencyLeftToRight not converted > >

	;
	; get the value from the left field and put it onto the fp
	; stack, then get value from the excahnge rate and the
	; multiply the two and put them into the right field
	;
	mov	bx, handle LeftAmount
	mov	si, offset LeftAmount
	GetResourceSegmentNS	dgroup, es
	mov	dx, es
	mov	bp, offset textBuffer
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage

	;
	; field was empty so this makes no sense, so just don't do
	; anything
	;
	tst	cx
	jz	done

	;
	; push on stack
	;
	mov	al, mask FAF_PUSH_RESULT
	GetResourceSegmentNS	dgroup, ds
	mov	si, offset textBuffer
	mov	cx, NUMBER_DISPLAY_WIDTH
	call	FloatAsciiToFloat

	;
	; get and push exchange rate
	;
	call	GetAndPushExchangeRateOnFPStack

	call	FloatMultiply

	clr	ax
	GetResourceSegmentNS	dgroup, es
	mov	di, offset textBuffer
	mov	bl, 2
	mov	bh, DECIMAL_PRECISION
	call	FloatFloatToAscii_StdFormat

	;
	; display in right field
	;
	mov	bx, handle RightAmount
	mov	si, offset RightAmount
	movdw	dxbp, esdi
	clr	di
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjMessage 
done:
	.leave
	ret
MemoryInputFieldCurrencyLeftToRight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemoryInputFieldCurrencyRightToLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	does the currency conversion from right to left

CALLED BY:	MSG_IF_CURRENCY_RIGHT_TO_LEFT
PASS:		*ds:si	= MemoryInputFieldClass object
		ds:di	= MemoryInputFieldClass instance data
		ds:bx	= MemoryInputFieldClass object (same as *ds:si)
		es 	= segment of MemoryInputFieldClass
		ax	= message #
RETURN:		the converted currency
DESTROYED:	nothing 
SIDE EFFECTS:	nothing 

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	7/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemoryInputFieldCurrencyRightToLeft	method dynamic MemoryInputFieldClass, 
					MSG_IF_CURRENCY_RIGHT_TO_LEFT
	uses	ax, cx, dx, bp
	.enter
DBCS<	ErrMessage < MemoryInputFieldCurrencyRightToLeft not converted > >

	;
	; get the value from the left field and put it onto the fp
	; stack, then get value from the excahnge rate and the
	; multiply the two and put them into the right field
	;
	mov	bx, handle RightAmount
	mov	si, offset RightAmount
	GetResourceSegmentNS	dgroup, es
	mov	dx, es
	mov	bp, offset textBuffer
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage

	;
	; field was empty so this makes no sense, so just don't do
	; anything
	;
	tst	cx
	jz	done

	;
	; push on stack
	;
	mov	al, mask FAF_PUSH_RESULT
	GetResourceSegmentNS	dgroup, ds
	mov	si, offset textBuffer
	mov	cx, NUMBER_DISPLAY_WIDTH
	call	FloatAsciiToFloat

	;
	; get and push exchange rate
	;
	call	GetAndPushExchangeRateOnFPStack

	call	FloatDivide

	clr	ax
	GetResourceSegmentNS	dgroup, es
	mov	bl, 2
	mov	bh, DECIMAL_PRECISION
	call	FloatFloatToAscii_StdFormat

	;
	; display in left field
	;
	mov	bx, handle LeftAmount
	mov	si, offset LeftAmount
	movdw	dxbp, esdi
	clr	di
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjMessage 
done:
	.leave
	ret
MemoryInputFieldCurrencyRightToLeft	endm
endif

CalcCode	ends
