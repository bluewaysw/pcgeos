COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcBuildPCF.asm

AUTHOR:		Christian Puscasiu, Apr 29, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT BigCalcCheckNumberOfPCFs checkes whether there is a limit on the
				number of open PCFs.

    GLB BigCalcDestroyPCF	Destroys a form

    INT BigCalcProcessBuildPCF	actually builds the PCF

    INT BigCalcProcessCheckPCFExists checks whether a particular PCF exists
				already

    INT BigCalcProcessBuildNewPCF Builds the new template from the
				information in the DataResource

    INT BigCalcProcessBuildFixedArgsPCF duplicates the resource in which
				the blank PCF is

    INT BigCalcProcessBuildVariableArgsPCF

    EXT BigCalcLockDataResource Lock the DataResource block, and ensure all
				localization aspects are dealt with.

    INT UseMetricUnits		Change from miles/gallons to
				kilometers/liters.

    INT UseLocalCurrencySymbol	Do a string substitution for the $

    INT InsertNewSymbol		Do a search and replace of a character with
				a string

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/29/92		Initial revision
	andres	10/29/96	Don't need this for DOVE
	andres	11/18/96	Don't need this for PENELOPE

DESCRIPTION:
	this file contains all the code to build out new PCF's
		

	$Id: bigcalcBuildPCF.asm,v 1.1 97/04/04 14:37:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%% DON'T NEED THIS FOR RESPONDER %%%%%%%%%%%%%%%%%%%%%%@

ProcessCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCFChooserGetNewPCFFromList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is to get the ID from the FunctionChooser

CALLED BY:	
PASS:		*ds:si	= PCFChooserClass object
		ds:di	= PCFChooserClass instance data
		ds:bx	= PCFChooserClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCFChooserNewPCFFromList	method dynamic PCFChooserClass, 
					MSG_PCF_CHOOSER_NEW_PCF_FROM_LIST
	uses	ax, cx, dx, bp
	.enter

	;
	; see if we are over the allowable limit of PCFs
	;
	call	BigCalcCheckNumberOfPCFs

	;
	; get the PreCannedFunctionID
	;
	mov	si, ds:[di].PCFCI_chooserList.offset
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock 

	push	ax

	;
	; dismiss the Interaction
	;
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjCallInstanceNoLock 

	pop	cx
	
	call	BigCalcProcessBuildPCF

	.leave
	ret
PCFChooserNewPCFFromList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcCheckNumberOfPCFs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checkes whether there is a limit on the number of open
		PCFs.  

CALLED BY:	
PASS:		nothing 
RETURN:		carry set if too many PCFs are about to be set
		carry unset if it is safe to open another PCF
DESTROYED:	nothing
SIDE EFFECTS:	If will close the one opened the longest time ago if
		the user is to go over the limit

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	7/ 8/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcCheckNumberOfPCFs	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	push	ds:[LMBH_handle]

	;
	; find the maximum allowable number of PCFs (if any)
	;
	mov	cx, cs
	mov	dx, offset numberWSString	;cx:dx <- key
	mov	ds, cx
	mov	si, offset confString		;ds:si <- category

	call	InitFileReadInteger

	pop	bx
	call	MemDerefDS

	;
	; if the category doesn't exist in the .ini file
	; then the we can open as many as we want
	;
	jc	okToOpenNew
	tst	ax
	jz	okToOpenNew

	;
	; ax cobtains the # of children, so we want to see wether
	; that's over the limit
	;
	push	ax
	mov	bx, handle BigCalcPCFHolder
	mov	si, offset BigCalcPCFHolder
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	ObjMessage

	pop	ax
	cmp	ax, dx
	jg	okToOpenNew

	;
	; we need to close the last recently opened
	;
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjMessage
	call	BigCalcDestroyPCF

okToOpenNew:
	.leave
	ret
BigCalcCheckNumberOfPCFs	endp

confString	char	"bigcalc",0
numberWSString	char	"numberWS",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcDestroyPCF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys a form

CALLED BY:	GLOBAL

PASS: 		CX:DX	= OD of form to be destroys

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		We can't use MSG_GEN_DESTROY_AND_FREE_BLOCK, as we
		are displayed non-modal windows that have Window
		menus that reside in a separate block.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/11/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcDestroyPCF	proc	near
		.enter

if 0
		; Remove this child from the tree
		;
		mov	ax, MSG_GEN_REMOVE
		movdw	bxsi, cxdx
		mov	dl, VUM_NOW
		mov	bp, mask CCF_MARK_DIRTY
		clr	di
		call	ObjMessage

		; Destroy the object block itself
		;
		mov	ax, MSG_META_BLOCK_FREE
		clr	di
		call	ObjMessage
else
		mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
		movdw	bxsi, cxdx
		clr	di
		call	ObjMessage	
endif
		.leave
		ret
BigCalcDestroyPCF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessBuildPCF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	actually builds the PCF

CALLED BY:	BigCalcProcesNewPCFFromList, BigCalcProcessNewPCF
PASS:		cx	-- PreCannedFunctionID == Item#
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcProcessBuildPCF	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	;
	; first I have to check wether the new PCF isn't already built
	; out, so I will just bring it to the top
	;
	call	BigCalcProcessCheckPCFExists
	jc	done

	;
	; build the PCF
	;	
	shl	cx
	mov	di, offset PCFDataTable
	add	di, cx
	mov	dx, cs:[di]

	push	dx

	call	BigCalcProcessBuildNewPCF
	movdw	cxdx, bxsi

	;
	; ^lcx:dx is the optr of the new PCF
	;
	mov	bx, handle BigCalcPCFHolder
	mov	si, offset BigCalcPCFHolder
	clr	di
	mov	bp, CCO_LAST or mask CCF_DIRTY
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjMessage

	movdw	bxsi, cxdx

	;
	; set the newly added child usable
	;
	clr	di
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_USABLE
	call	ObjMessage

	pop	dx
	clr	di
	mov	ax, MSG_PCF_INIT_INST_DATA
	call	ObjMessage 

	clr	di
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage 

done:
	;
	; after the PCF has been brought to live the focus will be put
	; into the first field
	;
	clr	di
	mov	ax, MSG_PCF_MAKE_FOCUS
	call	ObjMessage

	.leave
	ret
BigCalcProcessBuildPCF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessCheckPCFExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks whether a particular PCF exists already

CALLED BY:	
PASS:		cx = PreCannedFunctionID == Item#
RETURN:		cx:dx = PCF that has been brought up
		carry set if the PCF was found
		carry unset if not
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcProcessCheckPCFExists	proc	near
	uses	ax,di,bp
	.enter

	mov	bx, handle BigCalcPCFHolder
	mov	si, offset BigCalcPCFHolder
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_PCF_HOLDER_BRING_PCF_TO_TOP
	call	ObjMessage 

	movdw	bxsi, cxdx

	.leave
	ret
BigCalcProcessCheckPCFExists	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessBuildNewPCF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Builds the new template from the information in
		the DataResource

CALLED BY:	BigCalcProcessBuildPCF
PASS:		dx	== chunk handle to the data
RETURN:		cx:dx	== optr to the new PCF
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcProcessBuildNewPCF	proc	near
	uses	ax,cx,dx,di,bp
	.enter

	call	BigCalcLockDataResource

	;
	; dereference the chunck handle
	;
	mov	bp, dx
	mov	bp, es:[bp]

	;
	; get the first byte of info
	;
	mov	al, es:[bp]	
	clr	ah
	shl	ax
	mov	di, ax

	call	MemUnlock

	;
	; call the appropriate function according to the PCFTType which 
	; is the first thing in the record in es:[bp]
	;
	call	cs:[BuildPCFTable][di]

	.leave
	ret
BigCalcProcessBuildNewPCF	endp

BuildPCFTable	word	\
\
	offset	BigCalcProcessBuildVariableArgsPCF,
	offset	BigCalcProcessBuildFixedArgsPCF


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessBuildFixedArgsPCF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	duplicates the resource in which the blank PCF is

CALLED BY:	BigCalcProcessBuildNewPCF
PASS:		nothing 
RETURN:		^lbx:si the new PCF
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcProcessBuildFixedArgsPCF	proc	near
	uses	ax,cx
	.enter

	mov	bx, handle FixedArgsPCFTemplateResource
	mov	si, offset GenericFixedArgsPCF
	mov	ax, -1
	mov	cx, -1
	call	ObjDuplicateResource

	.leave
	ret
BigCalcProcessBuildFixedArgsPCF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcProcessBuildVariableArgsPCF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		^lbx:si	the new PCF
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcProcessBuildVariableArgsPCF	proc	near
	uses	ax,cx
	.enter

	mov	bx, handle VariableArgsPCFTemplateResource
	mov	si, offset GenericVariableArgsPCF
	mov	ax, -1
	mov	cx, -1
	call	ObjDuplicateResource

	.leave
	ret
BigCalcProcessBuildVariableArgsPCF	endp

;----------------------------------------------------------------------------
;	Table (order important)
;----------------------------------------------------------------------------
PCFDataTable	word	\
	offset	AveragePCFData,
	offset	CtermPCFData,
	offset	DblDeclBalancePCFData,
	offset	FutureValuePCFData,
	offset	PaymentPCFData,
	offset	PresentValuePCFData,
	offset	RatePCFData,
	offset	StandardDeviationPCFData,
	offset	StraightLineDepPCFData,
	offset	SumPCFData,
	offset	SumOfYearDepPCFData,
	offset	TermPCFData,
	offset	VariancePCFData,
	offset	SalesTaxPCFData,
	offset	SalesTotalPCFData,
	offset	ProfitMarginPCFData,
	offset	MarkupCostPCFData,
	offset	MarkupProfitPCFData,
	offset	DiscountPCFData,
	offset	BreakEvenPCFData,
	offset	BreakevenProfitPCFData,
	offset	HomeLoanPCFData,
	offset	CarLoanPCFData,
	offset	CollegePCFData,
	offset	SavingsGoalPCFData,
	offset	CarMilagePCFData,
	offset	CarLeasePCFData,
	offset	LoanAmountPCFData,
	offset	LoanPmtPCFData,
	offset	LoanInterestPCFData,
	offset	HomeSalePCFData,
	offset	HomePurLoanPCFData
CheckHack	<(length PCFDataTable) eq PreCannedFunctionID>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcLockDataResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the DataResource block, and ensure all localization
		aspects are dealt with.

CALLED BY:	EXTERNAL

PASS:		Nothing

RETURN:		AX	= DataResource segment
		BX	= DataResource handle
		ES	= DataResource segment

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcLockDataResource	proc	far
		uses	di
		.enter
	;
	; Lock down the block. If the block has been discarded,
	; we'll need to make all of our localization changes.
	;
		mov	bx, handle DataResource
		call	MemLock
		mov	es, ax
		assume	es:DataResource
		mov	di, es:[Discarded]
		cmp	{byte} es:[di], BB_FALSE
		assume	es:Nothing
		je	done
	;				
	; We need to setup the right strings for the worksheets.  There,
	; the currency symbol, gallons and miles need to be localized.
	; First check the measurement system and change miles/gallons if 
	; we want to do metric.
	;
		push	ax, bx, cx, dx, si, ds
		mov	ds, ax
		call	LocalGetMeasurementType	; if metric, make it so
		cmp	al, MEASURE_METRIC	; check for metric...
		jne	doCurrency		;  no, handle currency symbol
	;
	; change miles to kilometers and gallons to liters.
	;
		call	UseMetricUnits
	;
	; Handle using a different currency type.  If it's $, we're OK.
	;
doCurrency:
		call	UseLocalCurrencySymbol
		pop	ax, bx, cx, dx, si, ds
		assume	es:DataResource
		mov	di, es:[Discarded]
		mov	{byte} es:[di], BB_FALSE
		assume	es:Nothing
done:
		.leave
		ret
BigCalcLockDataResource	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UseMetricUnits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change from miles/gallons to kilometers/liters.

CALLED BY:	INTERNAL
		BigCalcLockDataResource

PASS:		DS, ES	= DataResource segment

RETURN:		DS, ES	= DataResource segment (may have moved)

DESTROYED:	AX, CX, DI, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UseMetricUnits	proc	near
		.enter

		; change the "miles" string first

		mov	si, offset DataResource:MetricMiles
		mov	di, es:[si]			; es:di -> 
		call	LocalStringSize			; cx = string size
		add	cx, 2				; 2 more for poss DBCS
		mov	ax, offset MilesText
		call	LMemReAlloc			; resize chunk
		mov	si, ds:[si]			; ds:si -> source
		mov	di, ax
		mov	di, es:[di]			; es:di -> dest
		sub	cx, 2
		rep	movsb				; copy the string over
		clr	ax
		stosw					; store DBCS NULL

		; now change the "gallons" string.

		mov	si, offset MetricGallons	; ax = chunk handle
		mov	di, es:[si]			; es:di -> 
		call	LocalStringSize			; cx = string size
		add	cx, 2				; 2 more for poss DBCS
		mov	ax, offset GallonsText
		call	LMemReAlloc			; resize chunk
		mov	si, ds:[si]			; ds:si -> source
		mov	di, ax
		mov	di, es:[di]			; es:di -> dest
		sub	cx, 2
		rep	movsb				; copy the string over
		clr	ax
		stosw					; store DBCS NULL

		.leave
		ret
UseMetricUnits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UseLocalCurrencySymbol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a string substitution for the $

CALLED BY:	INTERNAL
		BigCalcLockDataResource

PASS:		DS, ES	= DataResource segment

RETURN:		DS, ES	= DataResource segment (updated)

DESTROYED:	AX, BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	9/28/93		Initial version
	witt	11/12/93	DBCS-zied for wider buffer; sizes not lengths

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UseLocalCurrencySymbol		proc	far
curStringSize	local	word
newStringSize	local	word
currencySize	local	word
SBCS< currencyBuffer	local	CURRENCY_SYMBOL_LENGTH dup (char)	>
DBCS< currencyBuffer	local	CURRENCY_SYMBOL_LENGTH dup (word)	>
		.enter
		ForceRef curStringSize
		ForceRef newStringSize

		; get the current currency symbol.

		segmov	es, ss, di
		lea	di, ss:currencyBuffer	
		call	LocalGetCurrencyFormat	; es:di -> null-term string
		call	LocalStringSize		; cx = string size
		mov	ss:currencySize, cx

		; now that we have the string, lock down the resource and 
		; replace the string.

		segmov	es, ds, ax
		mov	ax, 1			; looking for a hex 1

		mov	si, offset DataResource:DollarText
		call	InsertNewSymbol		;  replace char in each string
		mov	si, offset DataResource:DollarYearText
		call	InsertNewSymbol
		mov	si, offset DataResource:DollarMonthText
		call	InsertNewSymbol
		mov	si, offset DataResource:DollarUnitText
		call	InsertNewSymbol
		 
		.leave
		ret
UseLocalCurrencySymbol		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertNewSymbol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a search and replace of a character with a string

CALLED BY:	INTERNAL
		UseLocalCurrencySymbol

PASS:		ds	- locked resource with strings to replace
		es == ds
		si	- chunk handle of string to replace
		ax	- character to search for (unused)
		inherited local vars from UseLocalCurrencySymbol
RETURN:		nothing

DESTROYED:	CX, DI, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	9/28/93		Initial version
	witt	11/12/93	DBCS-ized, uses size instead of length

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertNewSymbol	proc	near
		uses	ax
		.enter inherit UseLocalCurrencySymbol

		mov	di, ds:[si]		; es:di -> text
		call	LocalStringSize		; get current size
		mov	curStringSize, cx	; save current size
		add	cx, currencySize	; add in new string size
		mov	newStringSize, cx	; save new string size
		add	cx, 2			; add in enuf for DBCS nullterm
		mov	ax, si			; ax = chunk handle
		call	LMemReAlloc		; resize the chunk

		; now that the chunk is bigger, find the replacement char
		; and nudge the rest of the existing string down a bit.

		mov	di, ds:[si]		; es:di -> string
		mov	si, di			; ds:si -> string
		mov	ax, 1			; find \\\1 in UI resource
		LocalFindChar			; es:di -> after char
		push	di
		push	si			; save initial offset
		add	si, curStringSize		; point to end of new string
		add	si, currencySize	; length of both minus escape
		LocalPrevChar dssi
		mov	{word} ds:[si], 0	; store DBCS null at end
		xchg	di, si			; si = after escape position
		LocalPrevChar esdi		; di = destination
		pop	ax			; ax = initial position
		sub	ax, si			; -(# bytes past esc)
		add	ax, curStringSize	; # bytes to copy at string end
		mov	cx, ax
		add	si, cx			; copy from end of string
		LocalPrevChar dssi
		std
		rep	movsb
		cld
		pop	di
		LocalPrevChar esdi
		segmov	ds, ss, si
		lea	si, currencyBuffer
		mov	cx, currencySize
		rep	movsb
		segmov	ds, es, di		; restore DS

		.leave
		ret
InsertNewSymbol	endp

ProcessCode	ends
