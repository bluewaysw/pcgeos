COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcBuildFixedArgsPCF.asm

AUTHOR:		Christian Puscasiu, Apr 29, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT FixedArgsPCFInitDLLines creates the lines of a blank PCF

    INT FixedArgsPCFBuildAndAddLine aux function to build up the lines

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/29/92		Initial revision
	andres	10/29/96	Don't need this for DOVE
	andres	11/18/96	Don't need this for PENELOPE

DESCRIPTION:
	has the routines to build the FixedArgsPCF's
		


	$Id: bigcalcBuildFixedArgsPCF.asm,v 1.1 97/04/04 14:37:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CalcCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedArgsPCFInitInstData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initializes the instance data of the PCF

CALLED BY:	
PASS:		*ds:si	= FixedArgsPCFClass object
		ds:di	= FixedArgsPCFClass instance data
		ds:bx	= FixedArgsPCFClass object (same as *ds:si)
		ax	= message #
		dx	= chunk handle to the init data
RETURN:		al	= # args in the PCF
		bp	= points past the last thing read
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedArgsPCFInitInstData	method dynamic FixedArgsPCFClass, 
					MSG_PCF_INIT_INST_DATA
	uses cx, dx
	.enter

	;
	; lock the data
	;
	call	BigCalcLockDataResource

	;
	; derefernce the chunk handle
	;
	mov	bp, dx
	mov	bp, es:[bp]

	;
	; first thing is the type which we know is PCFT_FIXED_ARGS
	;
	mov	ds:[di].PCFI_type, PCFT_FIXED_ARGS
	inc	bp

	;
	; then the output format
	;
	mov	al, es:[bp]
	inc	bp
	mov	ds:[di].PCFI_resultFormat, al

	mov	ax, es:[bp]
	add	bp, 2
	mov	ds:[di].PCFI_ID, ax

	;
	; then is the formula
	;
	mov	bx, es:[bp]
EC <	ChunkSizeHandle es, bx, di					>
EC <	cmp	di, MAX_LENGTH_FORMULA_STRING				>
EC <	ERROR_AE FORMULA_STRING_TOO_LONG				>
	add	bp, 2
	mov	di, offset GenericFAPCFFormula
	call	PreCannedFunctionInitFormula

	;
	; save pointer to init data
	;
	push	bp

	; now the moniker, dereference the chunk handle of the moniker
	; and put the far ptr in cx:dx
	;
	mov	cx, es
	mov	bp, es:[bp]
	mov	dx, es:[bp]

	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	call	ObjCallInstanceNoLock
	
	; restore bp
	pop	bp
	inc	bp
	inc	bp

	;
	; get the number of argumnets
	;
	mov	dl, es:[bp]
	inc	bp

	; save number of lines and obj
	push	dx, si

	;
	; get the text & saving bp
	;
	push	bp
	mov	bp, es:[bp]
	mov	bp, es:[bp]	

	mov	si, offset GenericFAPCFResultText
	mov	dx, es
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	pop	bp
	inc	bp
	inc	bp

	; recover number of lines and obj
	pop	dx, si

	;
	; recover object
	;
	mov	di, ds:[si]
	add	di, ds:[di].FixedArgsPCF_offset

	mov	ds:[di].FAPI_numberArgs, dl
	clr	dh
	call	FixedArgsPCFInitDLLines

	push	bp

	;
	; last but not least we'll initialize the notes to the
	; template
	;
	mov	bp, es:[bp]
	mov	bp, es:[bp]
	mov	dx, es
	clr	cx
	mov	si, offset GenericFAPCFNotes
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	pop	bp
	inc	bp
	inc	bp

	mov	bx, handle DataResource
	call	MemUnlock

	.leave
	ret
FixedArgsPCFInitInstData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedArgsPCFInitDLLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	creates the lines of a blank PCF

CALLED BY:	es 	= locked DataResource
		ax	= message #
		es:bp	= pointer to init data
		dl	= # of lines
		dh	= 0
RETURN:		es:bp	past the last line info
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedArgsPCFInitDLLines	proc	near
	uses	ax, cx, dx
	.enter

EC<	tst	dl	>
EC<	ERROR_Z	NO_CHILDREN_IE_SHOULDNT_BE_HERE	>

	mov	cx, dx
repeat:

	push	bp	

	;
	; set up function call
	;
	mov	bp, es:[bp]

	call	FixedArgsPCFBuildAndAddLine

	pop	bp
	add	bp, 2

	inc	ch
	cmp	ch, cl
	jne	repeat

	.leave
	ret
FixedArgsPCFInitDLLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedArgsPCFBuildAndAddLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	aux function to build up the lines

CALLED BY:	FixedArgsPCFInitDLLines
PASS:		*ds:si	= FixedArgsPCFClass object
		ds:di	= FixedArgsPCFClass instance data
		*es:bp	= FixedArgsLineStruct
		ch	= the line number
		cl	= number of total lines
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedArgsPCFBuildAndAddLine	proc	near
	uses	ax,cx,dx,si,di,bp
	.enter

	;
	; save the ptr to the chunk of info we need for the line
	;
	push	bp, cx

	mov	bx, handle GenericLine
	mov	si, offset GenericLine
	mov	cx, ds:[LMBH_handle]
	mov	dx, offset GenericFixedArgsPCF
	mov	bp, 1 or mask CCF_MARK_DIRTY
	mov	di, mask MF_FIXUP_DS ; or mask MF_FIXUP_ES
	mov	ax, MSG_GEN_COPY_TREE
	call	ObjMessage 

	;
	; get the second child, which is the new line that was just created
	;
	mov	si, dx
	mov	cx, 1
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLockES

	;
	; set the new line usable
	;
	mov	si, dx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_GEN_SET_USABLE
	call	ObjCallInstanceNoLockES 

	;
	; get the line's children so we can set the default texts in them
	;
	mov	cx, 2		; find third child
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLockES 

	; chunk handle to the wealth of info
	pop	bp, cx

	;
	; save the 3rd child (= Units display) on stack
	;
	push	dx

	; chunk handle to the wealth of info
	push	bp, cx

	mov	cx, 1		; find second child
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLockES 

	; chunk handle to the wealth of info
	pop	bp, cx

	;
	; save the 2nd child (= InputField) on stack
	;
	push	dx

	; chunk handle to the wealth of info
	push	bp

	clr	cx		; find first child
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLockES 

	mov	si, dx

	;
	; retrieve the ptr to the data
	;
	pop	di

	mov	di, es:[di]
	mov	bp, es:[di].FALS_description
	mov	bp, es:[bp]

	mov	dx, es

	push	dx, di

	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLockES

	sub	sp, size AddVarDataParams
	mov	bp, sp

	mov	ss:[bp].AVDP_data.segment, cs
	mov	ss:[bp].AVDP_data.offset, offset LocalFilter
	mov	ss:[bp].AVDP_dataSize, size LocalFilter
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_TEXT_EXTENDED_FILTER 
	mov	dx, size AddVarDataParams
	mov	ax, MSG_META_ADD_VAR_DATA
	call	ObjCallInstanceNoLockES

	add	sp, size AddVarDataParams

	pop	dx, di

	pop	si

	push	dx, di

	clr	cx
	mov	bp, es:[di].FALS_defaultValue
	mov	bp, es:[bp]
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLockES

	pop	dx, di

	pop	si

	clr	cx
	mov	bp, es:[di].FALS_unit
	mov	bp, es:[bp]
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLockES 	

	.leave
	ret
FixedArgsPCFBuildAndAddLine	endp

LocalFilter	byte	VTEFT_BEFORE_AFTER


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedArgsPCFMakeFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gives the focus to the top field of the PCF

CALLED BY:	MSG_PCF_MAKE_FOCUS
PASS:		*ds:si	= FixedArgsPCFClass object
		ds:di	= FixedArgsPCFClass instance data
		ds:bx	= FixedArgsPCFClass object (same as *ds:si)
		es 	= segment of FixedArgsPCFClass
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 
SIDE EFFECTS:	the first input field will get the focus

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	7/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedArgsPCFMakeFocus	method dynamic FixedArgsPCFClass, 
					MSG_PCF_MAKE_FOCUS
	uses	ax, cx, dx, bp
	.enter

	;
	; find the 2nd child of the second child of the PCF to give it
	; the focus to
	;
	mov	cx, 1
	clr	di
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	GetResourceSegmentNS	dgroup, es
	call	ObjCallInstanceNoLockES

	mov	si, dx
	mov	cx, 1
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLockES

	;
	; give the focus to that field
	;
	mov	si, dx
	clr	di
	mov	ax, MSG_GEN_MAKE_FOCUS
	call	ObjCallInstanceNoLockES

	.leave
	ret
FixedArgsPCFMakeFocus	endm


CalcCode	ends
