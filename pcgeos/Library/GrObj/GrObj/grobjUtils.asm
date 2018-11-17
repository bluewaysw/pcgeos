COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		objectUtils.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			Description
	----			-----------
GrObjGrabMouse		
GrObjReleaseMouse		
GrObjChangeTempStateBits
GrObjCanMove?
GrObjCanResize?
GrObjCanRotate?
GrObjCanSkew?
GrObjCanTransformed?
GrObjCanGeomtry?
GrObjCanGeomtryAndValid?
GrObjCanEdit?
GrObjCanDrawHandles?
GrObjCreateGrObjClassedEvent


INT	GrObjAllocLMemBlock		Alloc an lmem block in vm file



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89	Initial revision


DESCRIPTION:
	Utililty routines for graphic class 
		

	$Id: grobjUtils.asm,v 1.1 97/04/04 18:07:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



PointerImages	segment lmem LMEM_TYPE_GENERAL

ptrCreate chunk
	PointerDef <
	16,				; PD_width
	16,				; PD_height
	7,				; PD_hotX
	7				; PD_hotY
>
	byte	00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b

	byte	00000001b, 00000000b,
		00000001b, 00000000b,
		00000001b, 00000000b,
		00000001b, 00000000b,
		00000001b, 00000000b,
		00000001b, 00000000b,
		00000001b, 00000000b,
		11111110b, 11111110b,
		00000001b, 00000000b,
		00000001b, 00000000b,
		00000001b, 00000000b,
		00000001b, 00000000b,
		00000001b, 00000000b,
		00000001b, 00000000b,
		00000001b, 00000000b,
		00000000b, 00000000b

ptrCreate endc

ptrTextEdit  chunk
	PointerDef <
	16,				; PD_width
	16,				; PD_height
	5,				; PD_hotX
	8				; PD_hotY
>
	byte	00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b

	byte	00000000b, 00000000b,
		01110001b, 11000000b,
		00001010b, 00000000b,
		00000100b, 00000000b,
		00000100b, 00000000b,
		00000100b, 00000000b,
		00000100b, 00000000b,
		00000100b, 00000000b,
		00000100b, 00000000b,
		00000100b, 00000000b,
		00000100b, 00000000b,
		00000100b, 00000000b,
		00000100b, 00000000b,
		00000100b, 00000000b,
		00001010b, 00000000b,
		01110001b, 11000000b

ptrTextEdit  endc

ptrTextCreate  chunk
	PointerDef <
	16,				; PD_width
	16,				; PD_height
	7,				; PD_hotX
	8				; PD_hotY
>
	byte	00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b

	byte	00000000b, 00000000b,
		00011100b, 01110000b,
		00000010b, 10000000b,
		00000001b, 00000000b,
		10000001b, 00000010b,
		10000001b, 00000010b,
		10000001b, 00000010b,
		01000001b, 00000100b,
		00111111b, 11111000b,
		01000001b, 00000100b,
		10000001b, 00000010b,
		10000001b, 00000010b,
		10000001b, 00000010b,
		00000001b, 00000000b,
		00000010b, 10000000b,
		00011100b, 01110000b

ptrTextCreate  endc

ptrRotateTool	chunk
	PointerDef <
	16,				; PD_width
	16,				; PD_height
	0,				; PD_hotX
	4				; PD_hotY
>
	byte	00001100b, 00000000b,
		00011100b, 00000000b,
		00111111b, 00000000b,
		01111111b, 11000000b,
		11111111b, 11110000b,
		01111111b, 11111000b,
		00111111b, 11111100b,
		00011100b, 11111110b,
		00001100b, 00111110b,
		00000000b, 00111111b,
		00000000b, 00011111b,
		00000000b, 00011111b,
		00000000b, 00011111b,
		00000000b, 00011111b,
		00000000b, 00000000b,
		00000000b, 00000000b

	byte	00001100b, 00000000b,
		00010100b, 00000000b,
		00100111b, 00000000b,
		01000000b, 11000000b,
		10000000b, 00110000b,
		01000000b, 00001000b,
		00100111b, 00000100b,
		00010100b, 11000010b,
		00001100b, 00100010b,
		00000000b, 00100001b,
		00000000b, 00010001b,
		00000000b, 00010001b,
		00000000b, 00010001b,
		00000000b, 00011111b,
		00000000b, 00000000b,
		00000000b, 00000000b

ptrRotateTool	endc


ptrZoom	chunk
	PointerDef <
	16,				; PD_width
	16,				; PD_height
	6,				; PD_hotX
	6				; PD_hotY
>
	byte	00000000b, 00000000b,
		00000000b, 00000000b,
		00000111b, 00000000b,
		00011000b, 11000000b,
		00010000b, 01000000b,
		00100000b, 00100000b,
		00100000b, 00100000b,
		00100000b, 00100000b,
		00010000b, 01000000b,
		00011000b, 11100000b,
		00000111b, 01110000b,
		00000000b, 00111000b,
		00000000b, 00011100b,
		00000000b, 00001100b,
		00000000b, 00000000b,
		00000000b, 00000000b

	byte	00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000010b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b

ptrZoom	endc

ptrMove	chunk
	PointerDef <
	16,				; PD_width
	16,				; PD_height
	7,				; PD_hotX
	7				; PD_hotY
>
	byte	00000001b, 00000000b,
		00000011b, 10000000b,
		00000111b, 11000000b,
		00001111b, 11100000b,
		00011111b, 11110000b,
		00111011b, 10111000b,
		01111111b, 11111100b,
		11111111b, 11111110b,
		01111111b, 11111100b,
		00111011b, 10111000b,
		00011111b, 11110000b,
		00001111b, 11100000b,
		00000111b, 11000000b,
		00000011b, 10000000b,
		00000001b, 00000000b,
		00000000b, 00000000b

	byte	00000001b, 00000000b,
		00000010b, 10000000b,
		00000100b, 01000000b,
		00001000b, 00100000b,
		00011110b, 11110000b,
		00101010b, 10101000b,
		01001110b, 11100100b,
		10000000b, 00000010b,
		01001110b, 11100100b,
		00101010b, 10101000b,
		00011110b, 11110000b,
		00001000b, 00100000b,
		00000100b, 01000000b,
		00000010b, 10000000b,
		00000001b, 00000000b,
		00000000b, 00000000b

ptrMove	endc

ptrResize	chunk
	PointerDef <
	16,			; PD_width
	16,			; PD_height
	6,			; PD_hotX
	6			; PD_hotY
>

	byte	11111101b, 11111000b,
		11111101b, 11111000b,
		11111000b, 11111000b,
		11111101b, 11111000b,
		11111111b, 11111000b,
		11011111b, 11011000b,
		00001111b, 10000000b,
		11011111b, 11011000b,
		11111111b, 11111000b,
		11111101b, 11111000b,
		11111000b, 11111000b,
		11111101b, 11111000b,
		11111101b, 11111000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b

	byte	11111101b, 11111000b,
		10000101b, 00001000b,
		10001000b, 10001000b,
		10000101b, 00001000b,
		10100010b, 00101000b,
		11010000b, 01011000b,
		00001000b, 10000000b,
		11010000b, 01011000b,
		10100010b, 00101000b,
		10000101b, 00001000b,
		10001000b, 10001000b,
		10000101b, 00001000b,
		11111101b, 11111000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b
ptrResize	endc

if 1	
ptrRotate	chunk
	PointerDef <
	16,			; PD_width
	16,			; PD_height
	6,			; PD_hotX
	6			; PD_hotY
>

	byte	11111101b, 11111000b,
		11111101b, 11111000b,
		11111000b, 11111000b,
		11111101b, 11111000b,
		11111111b, 11111000b,
		11011111b, 11011000b,
		00001111b, 10000000b,
		11011111b, 11011000b,
		11111111b, 11111000b,
		11111101b, 11111000b,
		11111000b, 11111000b,
		11111101b, 11111000b,
		11111101b, 11111000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b

	byte	11111101b, 11111000b,
		10000101b, 00001000b,
		10001000b, 10001000b,
		10000101b, 00001000b,
		10100010b, 00101000b,
		11010000b, 01011000b,
		00001000b, 10000000b,
		11010000b, 01011000b,
		10100010b, 00101000b,
		10000101b, 00001000b,
		10001000b, 10001000b,
		10000101b, 00001000b,
		11111101b, 11111000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b
ptrRotate	endc

else

ptrRotate	chunk
	PointerDef <
	16,				; PD_width
	16,				; PD_height
	0,				; PD_hotX
	4				; PD_hotY
>
	byte	00001100b, 00000000b,
		00011100b, 00000000b,
		00111111b, 00000000b,
		01111111b, 11000000b,
		11111111b, 11110000b,
		01111111b, 11111000b,
		00111111b, 11111000b,
		00011100b, 11111100b,
		00001100b, 01111100b,
		00000000b, 01111100b,
		00000001b, 11111111b,
		00000001b, 11111111b,
		00000000b, 11111110b,
		00000000b, 01111100b,
		00000000b, 00111000b,
		00000000b, 00010000b

	byte	00001100b, 00000000b,
		00010100b, 00000000b,
		00100111b, 00000000b,
		01000000b, 11000000b,
		10000000b, 00110000b,
		01000000b, 00001000b,
		00100111b, 00001000b,
		00010100b, 11000100b,
		00001100b, 01000100b,
		00000000b, 01000100b,
		00000001b, 11000111b,
		00000001b, 00000001b,
		00000000b, 10000010b,
		00000000b, 01000100b,
		00000000b, 00101000b,
		00000000b, 00010000b

ptrRotate	endc

endif

PointerImages	ends











GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjChangeTempStateBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set and reset some temp state bits. We use the in use count
		to protect this bits and their associated data from being
		discarded. So, if we have any bits set and after the reset
		there are no bits set, then dec the in use cont. If we have
		no bits set and we set some then inc the use count.

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object
		cl - bits to set
		ch - bits to reset

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjChangeTempStateBits		proc	far
	uses	cx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>
EC <	push	cx						>
EC <	and	cl, not mask GrObjTempModes			>
EC <	ERROR_NZ	GROBJ_BAD_GROBJ_TEMP_MODES_PARAM	>
EC <	and	ch, not mask GrObjTempModes			>
EC <	ERROR_NZ	GROBJ_BAD_GROBJ_TEMP_MODES_PARAM	>
EC <	pop	cx						>

	GrObjDeref	di,ds,si
	
	;    If we are not reseting any bits, or we have no bits to
	;    reset then jump to setting.
	;

	tst	ch					;reseting any bits?
	jz	set
	tst	ds:[di].GOI_tempState			;any bits to reset?
	jz	set

	;    Reset those bits. If the result are all the bits cleared
	;    then dec the interactible count.
	;

	not	ch	
	and	ds:[di].GOI_tempState,ch
	jnz	set
	call	ObjDecInteractibleCount
set:
	;    If we are not setting any bits then bail
	;

	tst	cl					;setting any bits?
	jz	done


	;    Set those bits. If there were no bits set originally then
	;    inc the interactible count
	;

	mov	ch,ds:[di].GOI_tempState	
	or	ds:[di].GOI_tempState,cl
	tst	ch					;original bits
	jnz	done
	call	ObjIncInteractibleCount

done:
	.leave
	ret
GrObjChangeTempStateBits		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanDrawHandles?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can draw its selection handles.

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can draw its selection handles

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanDrawHandles?		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	done

	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	done

	tst_clc	ds:[di].GOI_normalTransform
	jz	done

	test	ds:[di].GOI_locks,mask GOL_SELECT 	;implied clc
	jnz	done
	
	test	ds:[di].GOI_attrFlags, mask GOAF_INSTRUCTION
	jnz	checkIfInstructionsVisible

success:
	stc
done:
	.leave
	ret

checkIfInstructionsVisible:
    	;
	; Check if instructions (annotations) are visible.  If they are not
	; visible, then they are not selectable.  We query the body for this
	; information.
	;
	push	ax
	call	GrObjGetDrawFlagsFromBody
	test	ax, mask GODF_DRAW_INSTRUCTIONS		; Carry clear
	pop	ax
	jz	done					; invisible => fail
	jmp	success					; visible => stc

GrObjCanDrawHandles?		endp

GrObjDrawCode	ends


GrObjAlmostRequiredCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanEdit?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can be edited

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can be edited

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanEdit?		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	done

	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	done

	tst_clc	ds:[di].GOI_normalTransform
	jz	done

	test	ds:[di].GOI_locks,mask GOL_EDIT
	jnz	done

	test	ds:[di].GOI_locks,mask GOL_SHOW
	jnz	done

	stc

done:
	.leave
	ret

GrObjCanEdit?		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanGeometry?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can do any kind of geometry
		like move, resize, etc.

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can do geometry

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanGeometry?		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	done

	tst_clc	ds:[di].GOI_normalTransform
	jz	done

	stc

done:
	.leave
	ret
GrObjCanGeometry?		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanResize?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can be resized

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can be resized

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanResize?		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_RESIZE
	jnz	done

	test	ds:[di].GOI_optFlags,mask GOOF_IN_GROUP
	jnz	done

	call	GrObjCanGeometry?

done:
	.leave
	ret

GrObjCanResize?		endp

GrObjAlmostRequiredCode	ends

GrObjRequiredExtInteractive2Code	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCreateGrObjClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encapsulate a classed event for the GrObj

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		ax - message
		di - 0 or MF_STACK if data on stack
		cx,dx,bp - other data

RETURN:		
		cx - event handle

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCreateGrObjClassedEvent		proc	far
	uses	bx,di,si
	.enter

	mov	bx, segment GrObjClass
	mov	si, offset GrObjClass
	ornf	di,mask MF_RECORD
	call	ObjMessage
	mov	cx,di

	.leave
	ret
GrObjCreateGrObjClassedEvent		endp

GrObjRequiredExtInteractive2Code	ends

GrObjExtInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCopyChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a chunk into a newly created chunk

CALLED BY:	INTERNAL

PASS:		
		*ds:ax - chunk to copy
		es - segment to copy chunk to

RETURN:		
		ax - new chunk
		ds,es - possibly moved (ES, only if the same as DS)

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		WARNING: May cause block to move and/or chunk to move
		within block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCopyChunk		proc	far
	uses	bx,cx,di,si
	.enter

	;    Do nothing if no chunk
	;

	tst	ax
	jz	done

	;    Create new chunk, always marking it dirty
	;

	mov	si,ax					;source chunk handle
	call	ObjGetFlags
	ChunkSizeHandle	ds,si,cx
	segxchg	ds,es					;es <- source segment
							;ds <- dest segment
	push	es:[LMBH_handle]			;source handle
	ornf	al, mask OCF_DIRTY
	call	LMemAlloc	
	pop	bx					;source handle
	call	MemDerefES				;source segment

	;    Copy chunk
	;

	mov	di,ax					;dest chunk
	mov	di,ds:[di]				;dest offset
	segxchg	ds,es					;ds <- source segment
							;es <- dest segment
	mov	si,ds:[si]				;source offset
	MoveBytes	cx,cx

done:
	.leave
	ret
GrObjCopyChunk		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanMove?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can be moved

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can be moved

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanMove?		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_MOVE
	jnz	done

	call	GrObjCanGeometry?

done:
	.leave
	ret

GrObjCanMove?		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanRotate?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can be rotated

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can be rotated

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanRotate?		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_ROTATE
	jnz	done

	call	GrObjCanGeometry?

done:
	.leave
	ret

GrObjCanRotate?		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanSkew?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can be skewed

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can be skewed

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanSkew?		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_SKEW
	jnz	done

	call	GrObjCanGeometry?

done:
	.leave
	ret

GrObjCanSkew?		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanTransform?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can be transformed

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can be transformed

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanTransform?		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	call	GrObjCanGeometry?

	.leave
	ret

GrObjCanTransform?		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanGeometryAndValid?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can do any kind of geometry
		like move, resize, and it is grobj valid

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can do geometry

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanGeometryAndValid?		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	done

	call	GrObjCanGeometry?

done:
	.leave
	ret

GrObjCanGeometryAndValid?		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGrabMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to body to grab the grobj mouse

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object grabbing mouse

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/91	Initial version
	jon	17 mar 1992	turned into method

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGrabMouse	method dynamic GrObjClass, MSG_GO_GRAB_MOUSE
	uses	cx,dx
	.enter

	;    GrObjs inside groups are not allowed to grab the mouse
	;

EC <	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP		>
EC <	ERROR_NZ	OBJECTS_IN_GROUP_MAY_NOT_GRAB_MOUSE		>

	;    Send message to body
	;

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	ax,MSG_GB_GIVE_ME_MOUSE_EVENTS
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToBody

	.leave
	ret
GrObjGrabMouse		endm

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjReleaseMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to body to release the grobj mouse

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object grabbing mouse

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/91	Initial version
	jon	17 mar 1992	turned into method
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjReleaseMouse	method dynamic GrObjClass, MSG_GO_RELEASE_MOUSE
	uses	ax,cx,dx, di
	.enter

	;    GrObjs inside groups will never have mouse grab, so
	;    skip sending message to body
	;

	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP			
	jnz	done

	;    Send message to body
	;

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	ax,MSG_GB_DONT_GIVE_ME_MOUSE_EVENTS
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToBody

done:
	.leave
	ret
GrObjReleaseMouse		endm

GrObjExtInteractiveCode	ends
