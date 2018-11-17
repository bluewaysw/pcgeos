COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cobjectMultiple.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/19/92   	Initial version.

DESCRIPTION:
	

	$Id: cobjectMultiple.asm,v 1.1 97/04/04 17:46:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectMultipleClearAllGrObjes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Nuke all the grobjes for this object

PASS:		*ds:si	= ChartObjectMultipleClass object
		ds:di	= ChartObjectMultipleClass instance data
		es	= Segment of ChartObjectMultipleClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectMultipleClearAllGrObjes method dynamic ChartObjectMultipleClass, 
					MSG_CHART_OBJECT_CLEAR_ALL_GROBJES
	uses	ax,cx
	.enter

	mov	cx, COMT_FIRST_ARRAY
	call	ChartObjectFreeGrObjArray

	mov	cx, COMT_SECOND_ARRAY
	call	ChartObjectFreeGrObjArray

	.leave
	mov	di, offset ChartObjectMultipleClass
	GOTO	ObjCallSuperNoLock 
ChartObjectMultipleClearAllGrObjes	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectFreeGrObjArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free an array of GrObjs in this chart object

CALLED BY:	EXTERNAL, ChartObjectMultipleClearAllGrObjes

PASS:		*ds:si - chart object 
		cx - ChartObjectMultipleType

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectFreeGrObjArray	proc far
	uses	ax,bx,cx,dx,di,si
	class	ChartObjectClass
	.enter

EC <	call	ECCheckChartObjectDSSI	>


	mov	di, ds:[si]	; deref the chart object

	ornf	ds:[di].COI_state, mask COS_UPDATING
	push	si

	; COI_grobj should be null

EC <	tst	ds:[di].COI_grobj.chunk				>
EC <	ERROR_NZ GROBJ_FIELD_FOR_MULTIPLE_OBJECT_NOT_NULL	>



	mov	bx, cx		; ChartObjectMultipleType
	clr	si
	xchg	si, ds:[di][bx]

	tst	si
	jz	done

	mov	bx, cs
	mov	di, offset FreeGrObjCB
	call	ChunkArrayEnum
	mov	ax, si
	call	LMemFree

done:
	pop	si
	mov	di, ds:[si]
	andnf	ds:[di].COI_state, not mask COS_UPDATING
	.leave
	ret
ChartObjectFreeGrObjArray	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeGrObjCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the GrObject at ds:di

CALLED BY:	ChartObjectFreeGrObjArray

PASS:		ds:di - optr of grobject

RETURN:		nothing 

DESTROYED:	bx,si

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeGrObjCB	proc far
	mov	bx, ds:[di].handle
	mov	si, ds:[di].chunk
	call	UtilClearGrObj
	ret
FreeGrObjCB	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectMultipleGetGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current grobj from one of the elements in the
		array. If element not found, then an array element
		will be added.

CALLED BY:

PASS:		*ds:si - ChartObjectMultipleClass object
		cx - ChartObjectMultipleType
		dx - element number in array to use

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectMultipleGetGrObj	proc far
		uses	cx,dx,di
		class	ChartObjectClass
		.enter

		call	ChartObjectMultipleFindGrObjByNumber

		DerefChartObject ds, si, di 
		movOD	ds:[di].COI_grobj, cxdx

		.leave
		ret
ChartObjectMultipleGetGrObj	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectMultipleFindGrObjByNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the OD of a grobj for this chart object

CALLED BY:	ChartObjectMultipleGetGrObj

PASS:		*ds:si - ChartObjectMultipleClass object
		cx - ChartObjectMultipleType
		dx - element number in array to use

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectMultipleFindGrObjByNumber	proc far
		uses	ax,di,si
		.enter

EC <		call	ECCheckChartObjectDSSI	>

		call	GetElementOffset
		jc	append
done:
		movOD	cxdx, ds:[di]
		.leave
		ret

append:

	;
	; Add one to the array.  We should always be just one element
	; low when we get here, so this should work, since everything
	; generally goes in sequence.
	;
		
		
		call	ChunkArrayAppend
		clrdw	ds:[di]
		jmp	done

ChartObjectMultipleFindGrObjByNumber	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetElementOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the offset to an element in the specified array

CALLED BY:	ChartObjectMultipleGetGrObj,
		ChartObjectMultipleSetGrObj. 

PASS:		*ds:si - Chart Object
		cx - ChartObjectMultipleType
		dx - element number

RETURN:		ds:di - offset to current array element
		*ds:si - chunk array
		CARRY SET if element not available

DESTROYED:	nothing 
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers to it.

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetElementOffset	proc near
	uses	ax,bx,cx,dx,bp
	class	ChartObjectMultipleClass

	.enter

	mov	bp, si			; object's chunk

	call	GetGrObjArray

	tst	si
	jnz	gotArray

	; Array not found, create it.

	push	cx			; ChartObjectMultipleType
	mov	bx, size optr
	clr	cx, si, ax
	call	ChunkArrayCreate
	pop	bx			; ChartObjectMultipleType

	mov	di, ds:[bp]		; deref object chunk
	mov	ds:[di][bx], si		; store array lptr
	xchg	si, bp
	call	ObjMarkDirty
	xchg	si, bp

gotArray:

	mov	ax, dx
	call	ChunkArrayElementToPtr

	.leave
	ret
GetElementOffset	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectMultipleSetGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the OD of the current grobj in the array

CALLED BY:	Any ChartObjectMultipleClass object

PASS:		*ds:si - ChartObjectMultipleClass object
		cx - ChartObjectArrayType
		dx - element # at which to store

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	
	Add grobj to end of array

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectMultipleSetGrObj	proc far
	uses	di,si
	class	ChartObjectMultipleClass

	.enter

EC <	call	ECCheckChartObjectDSSI	>

	call	ObjMarkDirty
	DerefChartObject ds, si, di

	pushdw	ds:[di].COI_grobj
	clrdw	ds:[di].COI_grobj		; nuke it so we can keep
						; things orderly

	call	GetElementOffset
EC <	ERROR_C	INVALID_ELEMENT_NUMBER		>

	popdw	ds:[di]

	.leave
	ret
ChartObjectMultipleSetGrObj	endp



if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckChartObjectMultipleDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		*ds:si - an object (ostensibly) of ChartObjectMultipleClass

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckChartObjectMultipleDSSI	proc near
	uses	es,di
	.enter
	pushf
	segmov	es, <segment ChartObjectMultipleClass>, di
	mov	di, offset ChartObjectMultipleClass
	call	ObjIsObjectInClass
	ERROR_NC DS_SI_WRONG_CLASS
	popf

	.leave
	ret
ECCheckChartObjectMultipleDSSI	endp
ForceRef ECCheckChartObjectMultipleDSSI

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectMultipleRelocate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartObjectMultipleClass object
		ds:di	= ChartObjectMultipleClass instance data
		es	= Segment of ChartObjectMultipleClass.

		ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE

		cx - handle of block containing relocation
		dx - VMRelocType:
			VMRT_UNRELOCATE_BEFORE_WRITE
			VMRT_RELOCATE_AFTER_READ
			VMRT_RELOCATE_AFTER_WRITE
		bp - data to pass to ObjRelocOrUnRelocSuper

RETURN:		carry clear

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectMultipleRelocate	method	dynamic	ChartObjectMultipleClass, reloc

	mov	cx, COMT_FIRST_ARRAY
	call	ChartObjectRelocOrUnRelocArray

	mov	cx, COMT_SECOND_ARRAY
	call	ChartObjectRelocOrUnRelocArray

	mov	di, offset ChartObjectMultipleClass
	call	ObjRelocOrUnRelocSuper
	ret
ChartObjectMultipleRelocate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectRelocOrUnRelocArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	relocate or unrelocate an array of ODs

CALLED BY:

PASS:		ax - MSG_RELOCATE or MSG_UNRELOCATE
		*ds:si - chart object
		cx - ChartObjectMultipleType

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectRelocOrUnRelocArray	proc far
	uses	ax,bx,cx,di
	.enter

	mov	bx, cs
	cmp	ax, MSG_META_RELOCATE
	je	relocate

	mov	di, offset UnRelocateCB
	jmp	callIt
relocate:
	mov	di, offset RelocateCB
callIt:
	call	EnumCommon
	; enumerate the array without checking the class

	.leave
	ret
ChartObjectRelocOrUnRelocArray	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectArrayEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate an array of grobjes

CALLED BY:	UTILITY

PASS:		*ds:si - ChartObjectMultipleClass object
		cx - ChartObjectMultipleType
		bx:di - callback routine for ChunkArrayEnum
		( callback routine *must* in the same code segment as this
			routine for XIP system. So you don't need to pass
			bx in this case.)
RETURN:		ax,cx,dx,bp,es - from callback routine

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	WILL NOT create array if none exists.
	The relocation routines call EnumCommon, bypassing call to
	ECCheckChartObjectDSSI, because the class pointer will have
	been unrelocated at that point.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectArrayEnum	proc far

EC <	call	ECCheckChartObjectDSSI	>

	FALL_THRU	EnumCommon

ChartObjectArrayEnum	endp


EnumCommon	proc	far
	uses	bx, si

	.enter
	call	GetGrObjArray		; *ds:si - grobj array
	tst	si
	jz	done
FXIP<	mov	bx, cs			; callback must in the same segment >
	call	ChunkArrayEnum

done:
	.leave
	ret
EnumCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RelocateCB, UnRelocateCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to relocate/unrelocate an OD

CALLED BY:	ChartObjectMultipleRelocate

PASS:		ds:di - address at which to do the dirty deed.

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RelocateCB	proc far

	.enter
	mov	al, RELOC_HANDLE
	mov	cx, ds:[di].handle
	mov	bx, ds:[LMBH_handle]
	call	ObjDoRelocation
	mov	ds:[di].handle, cx

	.leave
	ret
RelocateCB	endp

UnRelocateCB	proc far

	.enter
	mov	al, RELOC_HANDLE
	mov	cx, ds:[di].handle
	mov	bx, ds:[LMBH_handle]
	call	ObjDoUnRelocation
	mov	ds:[di].handle, cx

	.leave
	ret
UnRelocateCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectRemoveExtraGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke the grobjes that belong to extra elements of the
		array. 

CALLED BY:

PASS:		*ds:si - Chart Object
		cx - ChartObjectMultipleType
		dx - number of elements that should be in array

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectRemoveExtraGrObjs	proc far
	uses	ax,bx,cx,dx,di,si
	.enter

EC <	call	ECCheckChartObjectDSSI	>

	; If DX is passed as zero, nuke the array entirely!
	tst	dx
	jnz	noNukes
	call	ChartObjectFreeGrObjArray
	jmp	done

noNukes:	
	push	cx
	mov	cx, mask COS_UPDATING
	call	ChartObjectSetState
	pop	cx

	push	si

	call	GetGrObjArray			; *ds:si - grobj array
	tst	si
	jz	afterFree

	; If there are already less than this many elements, then
	; bail. 

	call	ChunkArrayGetCount
	cmp	cx, dx
	jle	afterFree

	mov	bx, cs
	mov	di, offset FreeGrObjCB
	mov	ax, dx				; element # to start
						; at
	mov	cx, -1				; process all
	push	ax, cx
	call	ChunkArrayEnumRange
	pop	ax, cx
	call	ChunkArrayDeleteRange

afterFree:
	pop	si				; object chunk handle
	mov	cx, (mask COS_UPDATING) shl 8
	call	ChartObjectSetState

done:
	.leave
	ret
ChartObjectRemoveExtraGrObjs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetGrObjArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the chunk array of this grobj

CALLED BY:	ChartObjectRemoveExtraGrObjs, GetElementOffset, EnumCommon

PASS:		*ds:si - chart object
		cx - ChartObjectMultipleType

RETURN:		*ds:si - chunk handle of array (0 if none)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGrObjArray	proc near
	uses	bx
	.enter

	mov	bx, cx		; ChartObjectMultipleType
	mov	si, ds:[si]
	mov	si, ds:[si][bx]

	.leave
	ret
GetGrObjArray	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectMultipleSendToGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ChartObjectMultipleClass object
		ds:di	- ChartObjectMultipleClass instance data
		es	- segment of ChartObjectMultipleClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectMultipleSendToGrObj	method	dynamic	ChartObjectMultipleClass, 
					MSG_CHART_OBJECT_SEND_TO_GROBJ
	uses	ax,cx,dx,bp
	.enter
	mov_tr	ax, cx
	mov	cx, COMT_PICTURE
NOFXIP<	mov	bx, cs							>
	mov	di, offset ChartObjectMultipleSendToGrObjCB
	call	ChartObjectArrayEnum

	mov	cx, COMT_TEXT
	call	ChartObjectArrayEnum



	.leave
	mov	di, offset ChartObjectMultipleClass
	GOTO	ObjCallSuperNoLock
ChartObjectMultipleSendToGrObj	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectMultipleSendToGrObjCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to this grobj

CALLED BY:	ChartObjectMultipleSendToGrObj via ChunkArrayEnum

PASS:		ax - message to send

RETURN:		carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectMultipleSendToGrObjCB	proc far

	mov	bx, ds:[di].handle
	mov	si, ds:[di].offset
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	clc
	ret
ChartObjectMultipleSendToGrObjCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectMultipleClearGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke one of the grobjes for this chart object

CALLED BY:	ColumnBarRealizeCommonCB

PASS:		*ds:si - ChartObjectMultipleClass object
		cx - ChartObjectMultipleType
		dx - element number in array

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/13/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectMultipleClearGrObj	proc far

		class	ChartObjectMultipleClass
		
		uses	bx,di,si
		
		.enter

	;
	; Fetch the grobj from the array
	;
		
		call	ChartObjectMultipleGetGrObj


	;
	; clear it out, and nuke the grobj
	;
		
		DerefChartObject ds, si, di

		push	si
		movOD	bxsi, ds:[di].COI_grobj
		clrdw	ds:[di].COI_grobj
		call	UtilClearGrObj
		pop	si

	;
	; Store the NULL OD back in the array.
	;
		
		call	ChartObjectMultipleSetGrObj
		
		.leave
		ret
ChartObjectMultipleClearGrObj	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectMultipleGetTopGrObjPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the last element in the text array, or the last
		element in the picture array if text array doesn't exist.

PASS:		*ds:si	- ChartObjectMultipleClass object
		ds:di	- ChartObjectMultipleClass instance data
		es	- segment of ChartObjecMultipleClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0
ChartObjectMultipleGetTopGrObjPosition method dynamic ChartObjectMultipleClass, 
					MSG_CHART_OBJECT_GET_TOP_GROBJ_POSITION

;; This class doesn't have a handler, since the only subclasses of
;; this class are AxisClass and ColumnClass, and for AxisClass, we
;; want to use the value of COI_grobj, and whenever there's a Column
;; object, there's always an axis object, so we can just use the axis
;; object's top.
		
ChartObjectMultipleGetTopGrObjPosition	endm

endif



