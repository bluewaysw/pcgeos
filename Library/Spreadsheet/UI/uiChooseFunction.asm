COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiChooseFunction.asm

AUTHOR:		Cheng, 7/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/92		Initial revision

DESCRIPTION:
		
	$Id: uiChooseFunction.asm,v 1.1 97/04/07 11:12:05 newdeal Exp $

-------------------------------------------------------------------------------@


;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSChooseFuncControlClass		;declare the class record
SpreadsheetClassStructures	ends

;---------------------------------------------------

ChooseFuncControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCFGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSChooseFuncControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSChooseFuncControlClass
		ax - the message

		cx:dx - GenControlBuildInfo structure to fill in

RETURN:		cx:dx - filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSCFGetInfo	method dynamic SSChooseFuncControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSCF_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSCFGetInfo	endm

SSCF_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	SSCF_IniFileKey,		; GCBI_initFileKey
	SSCF_gcnList,			; GCBI_gcnList
	length SSCF_gcnList,		; GCBI_gcnCount
	SSCF_notifyTypeList,		; GCBI_notificationList
	length SSCF_notifyTypeList,	; GCBI_notificationCount
	SSCFName,			; GCBI_controllerName

	handle SSChooseFuncControlUI,		; GCBI_dupBlock
	SSCF_childList,			; GCBI_childList
	length SSCF_childList,		; GCBI_childCount
	SSCF_featuresList,		; GCBI_featuresList
	length SSCF_featuresList,	; GCBI_featuresCount
	SSCF_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	SSCF_helpContext>		; GCBI_helpContext


if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif

SSCF_helpContext	char	"dbInsFunc", 0

SSCF_IniFileKey	char	"ssChooseFunc", 0

SSCF_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_NAME_CHANGE>

SSCF_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_NAME_CHANGE>

;---

SSCF_childList	GenControlChildInfo	\
	<offset ChooseFuncTop, mask SSCFF_CHOOSE or \
				mask SSCFF_FUNCTION_TYPE, 0>,
	<offset ChooseFuncBottom, mask SSCFF_DESCRIPTION or \
				mask SSCFF_ARGUMENT_LIST, 0>,
	<offset ChooseArgOption, mask SSCFF_PASTE_ARGUMENTS, mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSCF_featuresList	GenControlFeaturesInfo	\
	<offset ChooseFuncList, ChooseFuncName, 0>,
	<offset ChooseTypeList, ChooseTypeName, 0>,
	<offset ChooseArgOption, ArgOptionName, 0>,
	<offset ChooseArguments, ChooseArgName, 0>,
	<offset ChooseDescription, ChooseDescName, 0>

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCFUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSChooseFuncControl
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSChooseFuncControlClass
		ax - the message
RETURN:		none
DESTROYED:	ax, bx, cx, dx, bp, si (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSCFUpdateUI	method dynamic SSChooseFuncControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI

	mov	ax, ds:[di].SSCFCI_types	; ax <- FunctionType
	mov	bx, ss:[bp].GCUUIP_childBlock

	FALL_THRU	ForceUpdate
SSCFUpdateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI for the Choose Function controller

CALLED BY:	SSCFUpdateUI(), SSCFChangeType()
PASS:		bx - handle of child block
		*ds:si - controller
		ax - FunctionType to display
RETURN:		none
DESTROYED:	ax, cx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceUpdate		proc	far
	.enter

	push	si			; controller

	mov_tr	cx, ax			; FunctionType
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	si, offset ChooseTypeList
	call	SSCFObjMessageSend
	mov_tr	ax, cx			; FunctionType
	
	call	ParserGetNumberOfFunctions	; cx <- num functions

	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	si, offset ChooseFuncList		;^lbx:si <- OD of list
	call	SSCFObjMessageSend

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	cx, dx				;cx <- select 1st, not indeter
	call	SSCFObjMessageSend
	pop	si

	mov	ax, MSG_SSCF_CHANGE_FUNCTION
	mov	bx, ds:[LMBH_handle]		
	call	SSCFObjMessageSend

	.leave
	ret
ForceUpdate		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCFChooseFunc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "ChooseFunc" being pressed
CALLED BY:	MSG_SSCF_SORT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSChooseFuncControlClass
		ax - the message
RETURN:		
DESTROYED:	cx, dx, bp, bx, si, (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	7/92		Initial version
	witt	11/93/93	Added DBCS stack overflow check (paranoid)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSCFChooseFunc	method dynamic SSChooseFuncControlClass, \
						MSG_SSCF_CHOOSE_FUNCTION

	;
	; Release the focus (so the edit bar or whatever can get it)
	; (Don't do in Redwood, should avoid on all keyboard-only systems.)
	;
if not KEYBOARD_ONLY_UI
	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	call	ObjCallInstanceNoLock
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	GenCallApplication
endif

	push	ds:[di].SSCFCI_types
	push	si
	call	SSCGetChildBlockAndFeatures
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset ChooseFuncList	;^lbx:si <- OD of list
	call	SSCFObjMessageCall	; ax <- cur selection, carry if none
	pop	si
	pop	dx
	LONG jc	done				;branch if none selected

	sub	sp, MAX_FUNCTION_NAME_SIZE+MAX_FUNCTION_ARGS_SIZE
DBCS< EC<  call	ECCHECKSTACK			; paranoid	>	>
	segmov	es, ss
	mov	di, sp				;es:di <- buffer
	;
	; Get the function name
	;
	push	ax
	mov	cx, ax				;cx <- index
	mov	ax, dx				;ax <- FunctionType
	call	ParserGetFunctionMoniker	;cx <- length
	pop	ax
	;
	; Get the arguments if necessary
	;
	push	di
	add	di, cx				;es:di <- ptr past name
DBCS <	add	di, cx				;es:di <- ptr past name	>
	push	ax
	call	SSCGetChildBlockAndFeatures
	test	ax, mask SSCFF_PASTE_ARGUMENTS
	pop	ax
	jz	noArgs				;branch if no such feature
	push	ax, cx, dx, si
	mov	si, offset ChooseArgOption
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	SSCFObjMessageCall
	tst	ax				;any selected?
	pop	ax, cx, dx, si
	jnz	getArgs				;branch if none selected
noArgs:
	;
	; Not pasting arguments -- add "()" to the function name
	;	cx = length
	;
	mov	ax, '('
	LocalPutChar esdi, ax
	mov	ax, ')'
	LocalPutChar esdi, ax
	clr	ax				;ax <- NULL
	LocalPutChar esdi, ax			;NULL terminate
	add	cx, 2				;cx <- 2 more chars (w/o NULL)
afterArgs:
	pop	di
	;
	; allocate a block of memory for the string and copy the string over
	;
	pushdw	dssi
SBCS<	segmov	ds, es							>
DBCS<	segmov	ds, es, ax						>
	mov	si, di				;ds:si <- string
	mov	ax, cx				;ax <- # bytes
DBCS <	shl	ax, 1				;ax <- # bytes (DBCS)	>
	push	cx				;save string length
	mov	cx, mask HF_SWAPABLE or (mask HAF_LOCK shl 8)
	call	MemAlloc			;ax <- seg; bx <- handle
	mov	es, ax
	clr	di				;es:di <- dest
	pop	cx				;cx <- # of chars
	push	cx
	LocalCopyNString			;copy me jesus
	call	MemUnlock
	mov	dx, bx				;dx <- handle of string
	pop	cx				;cx <- length of string
	popdw	dssi				;*ds:si <- controller
	;
	; cx = length, dx = mem handle
	;
	mov	bp, 0x00ff			;bp.low <- offset; bp.high <- md
	mov	ax, MSG_SPREADSHEET_REPLACE_TEXT_SELECTION
	clr	bx, di
	call	GenControlOutputActionRegs

	add	sp, MAX_FUNCTION_NAME_SIZE+MAX_FUNCTION_ARGS_SIZE

done:
	ret


	;
	; Get the arguments for the function
	;    es:di - ptr to buffer
	;    cx - # chars so far (length)
	;    dx - FunctionType
	;    ax - index
	;
getArgs:
	push	cx
	mov	cx, ax				;cx <- index
	mov	ax, dx				;ax <- FunctionType
	call	ParserGetFunctionArgs		;cx <- length of args
	pop	ax				;ax <- length of function
	add	cx, ax				;cx <- length
	jmp	afterArgs
SSCFChooseFunc	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSCFRequestMoniker

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		cx:dx GenDynamicList OD
		bp - entry #

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SSCFRequestMoniker	method dynamic SSChooseFuncControlClass,
			MSG_SSCF_REQUEST_FUNCTION_MONIKER
	.enter
	sub	sp, MAX_FUNCTION_NAME_SIZE

	mov	bx, cx				; bx:si <- OD
	mov	si, dx

	;
	; get a copy of the name of the function into a buffer
	;
	mov	ax, ds:[di].SSCFCI_types	;ax <- FunctionType
	segmov	es, ss
	mov	di, sp				; es:di <- buffer
	call	ParserGetNumberOfFunctions	; cx <- num functions
	cmp	bp, cx				; is it a valid entry #?
	jae	done			
	mov	cx, bp
	call	ParserGetFunctionMoniker	; fill buffer with name
	;
	; send message to the list object
	;
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	cx, es
	mov	dx, di				; cx:dx <- printer name
	call	SSCFObjMessageSend		; call the list
done:
	add	sp, MAX_FUNCTION_NAME_SIZE
	.leave
	ret
SSCFRequestMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCFChangeType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the type of function displayed

CALLED BY:	MSG_SSCF_CHANGE_TYPE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSChooseFuncControlClass
		ax - the message

		cx - FunctionType to match

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSCFChangeType		method dynamic SSChooseFuncControlClass,
						MSG_SSCF_CHANGE_TYPE
	mov	ds:[di].SSCFCI_types, cx

	call	SSCGetChildBlockAndFeatures

	mov	ax, cx				;ax <- FunctionType
	GOTO	ForceUpdate
SSCFChangeType		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCFChangeFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the function that is selected

CALLED BY:	MSG_SSCF_CHANGE_FUNCTION
PASS:		*ds:si - instance data
		ds:di - *ds:si
		cx - index of the function in the list

		ax - message number (unused)
		es - seg addr of SSChooseFuncControlClass (unused)

RETURN:		none
DESTROYED:	bx, bp, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Under DBCS this routine takes 600 bytes of space,
		which is now allocated in global memory (witt, 12/93).
		If we can't allocate memory, return and let caller trip.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/27/92		Initial version
	witt	11/19/93	DBCS allocates memory for format buffer.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSCFChangeFunction		method dynamic SSChooseFuncControlClass,
						MSG_SSCF_CHANGE_FUNCTION
if DBCS_PCGEOS
	mov	bp, ds:[di].SSCFCI_types	;ax <- type(s) to match
	mov	dx, cx				;dx <- index

	mov	ax, MAX_FUNCTION_ARGS_SIZE+MAX_FUNCTION_NAME_SIZE
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	LONG jc	quit				;punt on error
	push	bx				;save handle
	mov	es, ax				;es:di <- ptr to buffer
	clr	di
	mov	cx, dx				;cx <- item #

	push	bp				;save type(s) to match
else
	sub	sp, MAX_FUNCTION_ARGS_SIZE+MAX_FUNCTION_NAME_SIZE
	mov	ax, ds:[di].SSCFCI_types	;ax <- type(s) to match
	mov	di, sp
	segmov	es, ss				;es:di <- ptr to buffer
	mov	dx, cx				;dx <- index

	push	ax				;save type(s) to match
endif
DBCS< EC< call	ECCheckStack		; should always be done? 	> >

	;
	;	ds:si - object handle
	;	es:di - buffer ptr
	;	dx    - index
	;	cx    - index
	;	ax,bp - trashed
	; DBCS< <on stack> - handle to buffer >
	;	<on stack> - type(s) to match
	;

	call	SSCGetChildBlockAndFeatures	; IN ds:si/ OUT ax,bx
	test	ax, mask SSCFF_PASTE_ARGUMENTS
	pop	ax				;get back type(s)
	jz	noArgs

	;
	; Get the argument name
	;
	push	ax, dx
	push	di				;save start of buffer
	call	ParserGetFunctionMoniker	;cx <- length (w/o NULL)
	push	cx
DBCS <	shl	cx, 1				;cx <- 2 bytes per (DBCS)>
	add	di, cx				;es:di <- ptr beyond name
	;
	; Get the arguments
	;
	mov	cx, dx				;cx <- index
	call	ParserGetFunctionArgs		;cx <- length of args
	pop	ax				;ax <- length of function name
	add	cx, ax				;cx <- length of both
	pop	di				;restore start of buffer 
	;
	; Set the text
	;
	push	si
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	si, offset ChooseArguments
	mov	dx, es
	mov	bp, di				;dx:bp <- ptr to text
	call	SSCFObjMessageCall
	pop	si
	pop	ax, dx				;restore type(s) & index
noArgs:
	;
	; Display the description if appropriate
	;
	push	ax
	call	SSCGetChildBlockAndFeatures
	test	ax, mask SSCFF_DESCRIPTION
	pop	ax
	jz	noDesc

DBCS<	clr	di				;es:di <- ptr to buffer	>
	mov	cx, dx				;cx <- index
	call	ParserGetFunctionDescription	;cx <- length
	mov	si, offset ChooseDescription
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, es
	mov	bp, di				;dx:bp <- ptr to text
	call	SSCFObjMessageCall
noDesc:

SBCS<	add	sp, MAX_FUNCTION_ARGS_SIZE+MAX_FUNCTION_NAME_SIZE	>
DBCS<	pop	bx							>
DBCS<	call	MemFree							>
DBCS <quit:								>
	ret
SSCFChangeFunction		endm


SSCFObjMessageSend	proc	near
	uses	di
	.enter
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SSCFObjMessageSend	endp

SSCFObjMessageCall	proc	near
	uses	di
	.enter
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	.leave
	ret
SSCFObjMessageCall	endp

ChooseFuncControlCode	ends
