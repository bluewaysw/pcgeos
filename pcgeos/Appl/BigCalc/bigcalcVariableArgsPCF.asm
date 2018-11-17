COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcVariablePCF.asm

AUTHOR:		Christian Puscasiu, May  6, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT VAItemFillInArgsCB	VAItemGroupFillInArgs callback function

    INT VariableArgsPCFGetNewItem instantiates an item object for the args
				list

    INT VAPCFSetResultFieldToUnknown Set a text field to hold the "uknown"
				result

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/ 6/92		Initial revision
	andres	10/29/96	Don't need this for DOVE
	andres	11/18/96	Don't need this for PENELOPE

DESCRIPTION:
	all functions relating to Variablae Args PCFS
		

	$Id: bigcalcVariableArgsPCF.asm,v 1.1 97/04/04 14:38:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%% DON'T NEED THIS FOR RESPONDER %%%%%%%%%%%%%%%%%%%%%%@


MAX_NUMBER_OF_VARIABLE_ARGUMENTS	equ	25

CalcCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VariableArgsPCFCalculate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calculates the PCF

CALLED BY:	
PASS:		*ds:si	= VariableArgsPCFClass object
		ds:di	= VariableArgsPCFClass instance data
		ds:bx	= VariableArgsPCFClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		result in reult field
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	sets up the formula from the information in the PCF and then
	lets it get evaluated by BigCalcProcessPCFParseEval

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VariableArgsPCFCalculate	method dynamic VariableArgsPCFClass, 
					MSG_PCF_CALCULATE
	uses	ax, cx, dx, bp
	.enter

	;
	; save the handle to itself
	;	
	mov	ax, ds:[LMBH_handle]
	push	ax, si

	push	si

	;
	; first check how much space we have so that we can allocate a
	; nice piece of memory for the parse-eval routine
	;
	mov	si, offset GenericVAPCFItemGroup
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	ObjCallInstanceNoLock

	pop	si
	mov	di, ds:[si]
	add	di, ds:[di].VariableArgsPCF_offset
	mov	ah, ds:[di].VAPI_minimumNumberArgs

	;
	; check wether we have enough numbers to calculate this function
	;
	cmp	dl, ah
	jb	makeBeep

	;
	; if the user has more than the maximum number of items he should
	; use the spreadsheet; we'll have to give him some kind of a warning
	;
	cmp	dx, MAX_NUMBER_OF_VARIABLE_ARGUMENTS
	ja	makeBeep

	;
	; if it has no children then don't do anything
	; PS: If the enable/disbale mecahnism works properly this
	; should never happen
	;
	tst	dl
	jz	makeBeep

	;
	; dl == # children which we have to use for the computation of
	; the space needed
	;
	mov	al, dl
	mov	ah, (NUMBER_DISPLAY_WIDTH + 3) ; +3 is for the comma
					       ; and extra space
	mul	ah

	;
	; add the space for the formula
	;
if DBCS_PCGEOS
	add	ax, 200
	shl	ax, 1			; byte count to allocate
else
	add	ax, 100
endif

	;
	; now we have enough space for the filled formula
	;
	mov	cx, ((mask HF_SHARABLE or mask HF_SWAPABLE) or \
		    ((mask HAF_LOCK) shl 8))
	call	MemAlloc
	jc	makeBeep			; if failed allocation, abort
	push	bx
	mov	es, ax

	;
	; set up the blank formula string in ds:bx and the completed
	; (with args) string will be put into es:bp
	;
	mov	bx, ds:[di].PCFI_formula
	mov	bx, ds:[bx]
if DBCS_PCGEOS
	jmp	lF2		; skip pre-decrement
else
	dec	bx
	mov	bp, -1
endif

loopFormula:
	LocalNextChar	dsbx
	LocalNextChar	esbp
DBCS<lF2:								>
	LocalIsNull	ds:[bx]
	je	callFiller
	LocalLoadChar	ax, ds:[bx]
SBCS<	mov	es:[bp], al						>
DBCS<	mov	es:[bp], ax						>
	jmp	loopFormula

callFiller:
	mov	cx, es
	mov	si, offset GenericVAPCFItemGroup
	mov	ax, MSG_VA_ITEM_GROUP_FILL_IN_ARGS
	call	ObjCallInstanceNoLock

	;
	; pass the memory handle that will need to be locked by the
	; parser 
	;
	pop	bx
	mov	bp, bx
	call	MemUnlock

	;
	; pass the handle of itself in cx:dx
	;
	pop	cx, dx

	call	BigCalcProcessPCFParseEval
	jmp	done

makeBeep:
	;
	; show the user that we discarded his input
	;
	pop	ax, ax
	mov	ax, SST_NO_INPUT
	call	UserStandardSound

done:
	.leave
	ret

VariableArgsPCFCalculate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VAItemGroupResetList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the lsit of args

CALLED BY:	
PASS:		*ds:si	= VAItemGroupClass object
		ds:di	= VAItemGroupClass data
		ds:bx	= VAItemGroupClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	06/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VAItemGroupResetList	method dynamic VAItemGroupClass, 
					MSG_VA_ITEM_GROUP_RESET_LIST
	uses	ax, cx, dx, bp
	.enter

	mov	si, offset GenericVAPCFResultNumber
	call	VAPCFSetResultFieldToUnknown

	mov	si, offset GenericVAPCFDeleteButton
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	ObjCallInstanceNoLock

	mov	si, offset GenericVAPCFButtonCalculate
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	ObjCallInstanceNoLock

allChildren:
	mov	si, offset GenericVAPCFItemGroup
	clr	cx
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock 

	jc	done

	mov	si, dx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjCallInstanceNoLock 

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	si, offset GenericVAPCFItemGroup
	mov	bp, mask CCF_MARK_DIRTY
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	ObjCallInstanceNoLock 

	mov	si, dx
	mov	ax, MSG_META_OBJ_FREE
	call	ObjCallInstanceNoLock 

	jmp	allChildren

done:
	.leave
	ret
VAItemGroupResetList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VAItemGroupFillInArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	builds up the formula from the args

CALLED BY:	
PASS:		*ds:si	= VAItemGroupClass object
		ds:di	= VAItemGroupClass instance data
		ds:bx	= VAItemGroupClass object (same as *ds:si)
		cx:bp 	= string for the args to be written to
		ax	= message #
RETURN:		cx:0	= complete string
		cx:bp	= string past the last token written
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VAItemGroupFillInArgs	method dynamic VAItemGroupClass, 
					MSG_VA_ITEM_GROUP_FILL_IN_ARGS
	uses	ax, cx, dx
	.enter

	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp

	;
	; do all children
	;
	clr	ax
	push	ax, ax

	mov	ax, offset VI_link
	push	ax

	;
	; callback routine is right around the corner
	;
	push	cs
	mov	ax, offset VAItemFillInArgsCB
	push	ax

	call	ObjCompProcessChildren

	;
	; delete the last comma, put in the right paren and the zero
	; at the end
	;
	mov	es, cx
if DBCS_PCGEOS
	mov	{wchar} es:[bp-2], ')'
	mov	{wchar} es:[bp], C_NULL
else
	dec	bp
	mov	{byte} es:[bp], ')'
	inc	bp
	mov	{byte} es:[bp],0
endif

	.leave
	ret
VAItemGroupFillInArgs	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VAItemFillInArgsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	VAItemGroupFillInArgs callback function
		Stores number (our VMT_text) and a comma at cx:bp.

CALLED BY:	VAItemGroupFillInArgs
PASS:		cx:bp	space to put the visMoniker and comma
		ds == cx
RETURN:		cx:bp	with bp, past last char written
DESTROYED:	es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/12/92		Initial version
	witt	10/27/93	Uses Localized list separator.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VAItemFillInArgsCB	proc	far
	uses	ax,bx,cx,dx,si,di,ds
	.enter

	;
	; save the MemBlock
	;
	push	cx, bp

	;
	; get the moniker of the item
	;
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	call	ObjCallInstanceNoLock
	
	;
	; get moniker into ds:si
	;
	mov	si, ax
	mov	si, ds:[si]
	add	si, offset VM_data + offset VMT_text

	;
	; copy ds:si to es:di
	;
	pop	es, di
	LocalCopyString			; does copy NULL

	;
	; insert the list separator (normally a comma)
	;
	call	LocalGetNumericFormat	; list separator => DX	
	mov_tr	ax, dx
DBCS <	mov	{wchar} es:[di-2], ax	; smash C_NULL with separator.	>
SBCS <	dec	di							>
SBCS <	stosb								>

	;
	; pass back bp
	;
	mov	bp, di

	;
	; continue all the way to the last child
	;
	clc

	.leave
	ret
VAItemFillInArgsCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VariableArgsPCFDisplayPCFResult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	displays the result 

CALLED BY:	
PASS:		*ds:si	= VariableArgsPCFClass object
		ds:di	= VariableArgsPCFClass instance data
		ds:bx	= VariableArgsPCFClass object (same as *ds:si)
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
VariableArgsPCFDisplayPCFResult	method dynamic VariableArgsPCFClass, 
					MSG_PCF_DISPLAY_PCF_RESULT
	uses	ax, cx, dx, bp
	.enter

	mov	si, offset GenericVAPCFResultNumber
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	.leave
	ret
VariableArgsPCFDisplayPCFResult	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VariableArgsPCFAddToList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adds args to the list

CALLED BY:	
PASS:		*ds:si	= VariableArgsPCFClass object
		ds:di	= VariableArgsPCFClass instance data
		ds:bx	= VariableArgsPCFClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	will not let you add more than MAX_NUMBER_OF_VARIABLE_ARGUMENTS entries

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VariableArgsPCFAddToList	method dynamic VariableArgsPCFClass, 
					MSG_VARIABLE_ARGS_PCF_ADD_TO_LIST
	uses	ax, cx, dx, bp
	.enter

	;
	; Keep track of the minimum number of arguments
	;
	mov	bl, ds:[di].VAPI_minimumNumberArgs

	;
	; check if field is empty
	;
	mov	si, offset GenericVAPCFInputNumber
	GetResourceSegmentNS	dgroup, es
	mov	dx, es
	mov	bp, offset textBuffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjCallInstanceNoLock 
LONG	jcxz	done

	;
	; Enable or disable the Calculate button, depending upon
	; whether or not a sufficient number of elements are available
	;
	mov	si, offset GenericVAPCFItemGroup
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	ObjCallInstanceNoLock 
	push	dx				; save the number of elements

	cmp	dl, bl				; sufficient number of args?
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; assume no
	jb	doIt				; ...good assumption
	mov	ax, MSG_GEN_SET_ENABLED		; else allow calculation
doIt:
	mov	si, offset GenericVAPCFButtonCalculate
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock 

	;
	; delete all of the text in the inputfield
	;
	mov	si, offset GenericVAPCFInputNumber
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	ObjCallInstanceNoLock 

	;
	; set the result field to "?" because the entries have been
	; altered 
	;
	mov	si, offset GenericVAPCFResultNumber
	call	VAPCFSetResultFieldToUnknown

	;
	; if we have too many entries, just beep
	;
	pop	dx			; number of elements => DX
	inc	dx
	cmp	dx, MAX_NUMBER_OF_VARIABLE_ARGUMENTS
	ja	makeBeep

	;
	; gets a unique identifier that the item will get
	;
	mov	si, offset GenericVAPCFItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_GET_UNIQUE_IDENTIFIER
	call	ObjCallInstanceNoLock 

	;
	; get a new item to put the text into
	;
	mov	bx, ds:[LMBH_handle]		; child's block => BX
	GetResourceSegmentNS	dgroup, es
	mov	cx, es
	mov	dx, offset textBuffer
	call	VariableArgsPCFGetNewItem

	;
	; make that item a child of the itemgroup
	;
	mov	si, offset GenericVAPCFItemGroup
	mov	bp, CCO_FIRST or mask CCF_MARK_DIRTY
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLock

	;
	; set the new child usable
	;
	mov	si, dx
	clr	di
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_USABLE
	call	ObjCallInstanceNoLock 

	mov	si, offset GenericVAPCFAddButton
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	ObjCallInstanceNoLock 
done:
	.leave
	ret

makeBeep:
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
	jmp	done
VariableArgsPCFAddToList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VariableArgsPCFGetNewItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	instantiates an item object for the args list

CALLED BY:	VariableArgsPCFAddToList
PASS:		ds	= points to an objectblock that might move
		bx	= handle to that object block
		cx:dx	= farptr to the moniker to be of the item
		ax	= identifier
RETURN:		cx:dx	= the new item with the moniker
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This is how the args are stored, as monikers of items in the
	list


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VariableArgsPCFGetNewItem	proc	near
	uses	ax,bx,si,di,bp
	.enter

	;
	; save the identifier of the new item
	;
	push	ax

	mov	ax, segment VAItemClass
	mov	es, ax
	mov	di, offset VAItemClass
	;bx	== handle of the PCF
	call	ObjInstantiate

	;
	; store the number as the moniker
	;
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	call	ObjCallInstanceNoLock 

	;
	; get the identifier
	;
	pop	cx

	;
	; set the new identifier
	;
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_GEN_ITEM_SET_IDENTIFIER
	call 	ObjCallInstanceNoLock 

	;
	; return the new item in cx:dx
	;
	mov	cx, bx
	mov	dx, si

	.leave
	ret
VariableArgsPCFGetNewItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VariableArgsPCFItemSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	en/disables the Delete button

CALLED BY:	
PASS:		*ds:si	= VariableArgsPCFClass object
		ds:di	= VariableArgsPCFClass instance data
		ds:bx	= VariableArgsPCFClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= current selection, or first selection in item 
			group, if more than one selection, or GIGS_NONE 
			of no selection
		bp 	= number of selections
		dl 	= GenItemGroupStateFlags
RETURN:		nothing 
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	en/disables the Delete button, depending on whether an item is
	selected


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/ 7/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VariableArgsPCFItemSelected	method dynamic VariableArgsPCFClass, 
					MSG_VARIABLE_ARGS_PCF_ITEM_SELECTED
	uses	ax, cx, dx, bp
	.enter

	;
	; si to the delete button
	;
	mov	si, offset GenericVAPCFDeleteButton

	cmp	cx, GIGS_NONE
	je	noSelection

	;
	; set the delete Button enabled
	;
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	callMSG

noSelection:
	;
	; set the delete button disabled
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED

callMSG:
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock 

	.leave
	ret
VariableArgsPCFItemSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VariableArgsPCFDeleteItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	deletes one of the args

CALLED BY:	
PASS:		*ds:si	= VariableArgsPCFClass object
		ds:di	= VariableArgsPCFClass instance data
		ds:bx	= VariableArgsPCFClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		the selected item in the VAPCFInputField
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/ 7/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VariableArgsPCFDeleteItem	method dynamic VariableArgsPCFClass, 
					MSG_VARIABLE_ARGS_PCF_DELETE_ITEM
	uses	ax, cx, dx, bp
	.enter

	;
	; set delete button disabled
	;
	mov	si, offset GenericVAPCFDeleteButton
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	ObjCallInstanceNoLock 

	;
	; ^lbx:si == Itemgroup
	;
	mov	si, offset GenericVAPCFItemGroup

	;
	; get the identifier of the selected item
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock 
	
	;
	; get optr of that item
	;
	mov	cx, ax
	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	call	ObjCallInstanceNoLock 

	;
	; don't do anything if we have no selection
	;
	cmp	ax, GIGS_NONE
	je	done

	;
	; make the item not usable
	;
	mov	bx, cx	
	mov	si, dx
	mov	di, mask MF_FIXUP_DS
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjMessage 

	;
	; put item into ^lcx:dx
	;
	mov	cx, bx
	mov	dx, si

	;
	; get the Itemgroup
	;
	mov	si, offset GenericVAPCFItemGroup

	;
	; remove item from the item group
	;
	mov	bp, mask CCF_MARK_DIRTY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	ObjCallInstanceNoLock 

	;
	; free the item's handle
	;
	mov	si, dx
	mov	ax, MSG_META_OBJ_FREE
	call	ObjCallInstanceNoLock 

	mov	si, offset GenericVAPCFResultNumber
	call	VAPCFSetResultFieldToUnknown

	mov	si, offset GenericVAPCFItemGroup
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	ObjCallInstanceNoLock 

	mov	si, offset GenericVariableArgsPCF
	mov	di, ds:[si]
	add	di, ds:[di].VariableArgsPCF_offset
	mov	dh, ds:[di].VAPI_minimumNumberArgs

	cmp	dl, dh
	jae	done

	mov	si, offset GenericVAPCFButtonCalculate
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
VariableArgsPCFDeleteItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VAPCFInputFieldVisTextFilterViaBeforeAfter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	front-emd to text filter

CALLED BY:	
PASS:		*ds:si	= VAPCFInputFieldClass object
		ds:di	= VAPCFInputFieldClass instance data
		ds:bx	= VAPCFInputFieldClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= handle to the before string
		dx	= handle to the after string
		ss:bp 	= VisTextReplaceParameters
RETURN:		carry set if after rejected
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VAPCFInputFieldVisTextFilterViaBeforeAfter method dynamic VAPCFInputFieldClass,
				MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER
	uses	ax, cx, dx, bp
	.enter

	;
	; get the after string into ds:si
	;
	mov	si, dx
	mov	si, ds:[si]
	call	InputFieldCheckIfValidFPNumber

	;
	; save the length in bx
	;
	mov	bx, cx

	jc	makeBeep

	;
	; carry means that there was no illegal charcater found so I
	; composed a legal fp number from the input given
	;
	LocalIsNull	ax
	jz	newStringIsEmpty

	;	
	; put the string into dx:bp
	;
	mov	dx, es

	;
	; use the string in dx:bp
	;
	mov	si, offset GenericVAPCFInputNumber
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock

	mov	cx, bx
	mov	dx, cx
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	call	ObjCallInstanceNoLock  

	;
	; set the add button enabled
	;
	mov	si, offset GenericVAPCFAddButton
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

	;
	; set the calculate button disabled because the user might be
	; confused of wether his just recently added number will be
	; used or not
	;
	mov	si, offset GenericVAPCFButtonCalculate
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
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
	mov	si, offset GenericVAPCFInputNumber
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	ObjCallInstanceNoLock

	mov	si, offset GenericVAPCFAddButton
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

	mov	si, offset GenericVAPCFButtonCalculate
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
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

VAPCFInputFieldVisTextFilterViaBeforeAfter	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VAPCFSetResultFieldToUnknown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a text field to hold the "uknown" result

CALLED BY:	INTERNAL

PASS:		*DS:SI	= GenText object

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/12/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBCS <unknownText	char	"?", 0					>
DBCS <unknownText	wchar	"?", 0					>

VAPCFSetResultFieldToUnknown	proc	near
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	dx, cs
		mov	bp, offset unknownText
		clr	cx			; NULL-terminated
		call	ObjCallInstanceNoLock 
		ret
VAPCFSetResultFieldToUnknown	endp

CalcCode	ends

