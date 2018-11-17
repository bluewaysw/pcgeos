COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		graphicBodyPriorityList.asm

AUTHOR:		Steve Scholl, May 3, 1991


ROUTINES (intended for calling from outside priority list code):
	Name			
	----			
    GrObjBodyPriorityListCreate
    GrObjBodyPriorityListDestroy
    GrObjBodyPriorityListReset 
				 
    GrObjBodyPriorityListGetNumElements  
    GrObjBodyPriorityListGetElement  	
    GrObjBodyPriorityListInit		
    GrObjBodyGetPriorityListOD

    PriorityListCreate		Creates chunks for priority list
    PriorityListDestroy		Destroys chunks of the  priority list
    PriorityListInit		Intializes priority list data structures
    PriorityListReset		Resets list to have zero elements
INT PriorityListInsert		Insert element into priority list
INT PriorityListInsertAt	Insert element into list at specific position
    PriorityListGetPLPoint	Return PL_point
    PriorityListGetMethod	Returns PL_message
    PriorityListGetNumElements 	Returns PL_numElements
    PriorityListGetInstructions	Returns PL_instructions
    PriorityListGetClass	Returns PL_class
    PriorityListGetElement 	Returns OD, priority and other from element

ROUTINES (NOT intended for calling from outside priority list code):
	Name			Description
	----			-----------
INT PriorityListFindLoc		Return element # to insert at
INT PriorityListFindPriorityCallBack  
INT PriorityListAppend		Append element to priority list
INT PriorityListInsertIndexAt	Insert element at index number 
INT PriorityListTrim		Trim list down to max elements


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	5/3/91		Initial revision


DESCRIPTION:
	

	$Id: bodyPriorityList.asm,v 1.1 97/04/04 18:08:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjRequiredInteractiveCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGRUPPriorityListReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the graphic body's priority list to have zero elements

PASS:		
		*ds:si - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		GBI_priorityList changed
			PL_numElements = 0
			PL_list = no elements			

DESTROYED:	
		nothing
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGRUPPriorityListReset method dynamic GrObjBodyClass, \
					MSG_GB_PRIORITY_LIST_RESET
	.enter

	call	GrObjBodyPriorityListReset

	.leave
	ret
GrObjBodyGRUPPriorityListReset		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGRUPPriorityListGetNumElements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of elements in the list

PASS:		
		*ds:si - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		GBI_priorityList changed
			PL_numElements = 0
			PL_list = no elements			

DESTROYED:	
		nothing
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGRUPPriorityListGetNumElements method dynamic GrObjBodyClass, \
				MSG_GB_PRIORITY_LIST_GET_NUM_ELEMENTS
	.enter

	call	GrObjBodyPriorityListGetNumElements

	.leave
	ret
GrObjBodyGRUPPriorityListGetNumElements		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGRUPPriorityListGetElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return element info

PASS:		
		*ds:si - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cx - element # (0 is first element)

RETURN:		
		stc - element doesn't exist
		clc  - element exists
			cx:dx - optr
			al - priority
			ah - other data

DESTROYED:	
		nothing
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGRUPPriorityListGetElement method dynamic GrObjBodyClass, \
				MSG_GB_PRIORITY_LIST_GET_ELEMENT
	.enter

	call	GrObjBodyPriorityListGetElement

	.leave
	ret
GrObjBodyGRUPPriorityListGetElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGRUPPriorityListInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return element info

PASS:		
		*ds:si - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cx:dx - fptr to PLInit

RETURN:		
		GBI_priorityList - changed	

DESTROYED:	
		nothing
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGRUPPriorityListInit method dynamic GrObjBodyClass, 
				MSG_GB_PRIORITY_LIST_INIT
	.enter

if FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	segmov	bx, cx						>
EC<	mov	si, dx						>
EC<	call	ECAssertValidFarPointerXIP			>
EC<	pop	bx, si						>
endif

	mov	es,cx
	mov	di,dx
	call	GrObjBodyPriorityListInit

	.leave
	ret
GrObjBodyGRUPPriorityListInit		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPriorityListCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a priority list and its internal chunks. Store
		the main chunk handle in the graphic body instance data.

CALLED BY:	INTERNAL
		GrObjBodyOpenSetUp

PASS:		
		*ds:si - instance data of body

RETURN:		
		ds - updated if moved
		GBI_priorityList
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: may cause chunks to move within block 
		and block to move on heap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPriorityListCreate		proc	far
	uses	ax,bx,si
	class	GrObjBodyClass
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx,ds:[LMBH_handle]
	call	PriorityListCreate
	
	call	MemDerefDS

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	mov	ds:[si].GBI_priorityList,ax

	.leave
	ret
GrObjBodyPriorityListCreate		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPriorityListDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the priority list and any chunks it may 
		have allocated 

CALLED BY:	INTERNAL
		GrObjBodyFinalObjFree

PASS:		*ds:si - GrObjBody

RETURN:		
		nothing

DESTROYED:	
		di

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPriorityListDestroy		proc	far	uses si
	class	GrObjBodyClass
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset	
	mov	di,ds:[di].GBI_priorityList	
	tst	di
	jz	done

	mov	bx,ds:[LMBH_handle]
	mov	si,di
	call	PriorityListDestroy

done:
	.leave
	ret
GrObjBodyPriorityListDestroy		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPriorityListReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the graphic body's priority list to have zero elements

PASS:		
		*ds:si - instance data of object

RETURN:		
		GBI_priorityList changed
			PL_numElements = 0
			PL_list = no elements			

		ds - updated if moved

DESTROYED:	
		nothing
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: may cause chunks to move within block 
		and block to move on heap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPriorityListReset		proc	far
	uses	bx,di
	class	GrObjBodyClass
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

    	call	GrObjBodyGetPriorityListOD
	call	PriorityListReset
	call	MemDerefDS

	.leave
	ret
GrObjBodyPriorityListReset		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPriorityListGetNumElements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of elements in the list.

PASS:		
		*ds:si - instance data of graphic body

RETURN:		
		cx - PL_numElements
		ds - updated if moved

DESTROYED:	
		nothing
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: may cause chunks to move within block 
		and block to move on heap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPriorityListGetNumElements		proc	far
	uses	bx,di
	class	GrObjBodyClass
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

    	call	GrObjBodyGetPriorityListOD
	call	PriorityListGetNumElements
	call	MemDerefDS

	.leave
	ret
GrObjBodyPriorityListGetNumElements		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPriorityListGetElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return element info

PASS:		
		*ds:si - instance data of graphic body

		cx - element # (0 is first element)

RETURN:		
		stc - element doesn't exist
		clc  - element exists
			cx:dx - optr
			al - priority
			ah - other data

		ds - updated if moved

DESTROYED:	
		nothing
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: may cause chunks to move within block 
		and block to move on heap

		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPriorityListGetElement		proc	far
	uses	bx,di
	class	GrObjBodyClass
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

    	call	GrObjBodyGetPriorityListOD
	call	PriorityListGetElement

	.leave
	ret
GrObjBodyPriorityListGetElement		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPriorityListInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return element info

PASS:		
		*ds:si - instance data of graphic body

		es:di - fptr to PLInit

RETURN:		
		GBI_priorityList - changed	

		ds - updated if moved

DESTROYED:	
		nothing
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: may cause chunks to move within block 
		and block to move on heap

		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPriorityListInit		proc	far
	uses	bx,di,si
	class	GrObjBodyClass
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	push	di				;offset PLInit
    	call	GrObjBodyGetPriorityListOD
	pop	si				;offset PLInit
	call	PriorityListInit

	.leave
	ret
GrObjBodyPriorityListInit		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetPriorityListOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the OD for the graphic body's priority list.
		Create the priority list if it does not exists

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - GrObjBody

RETURN:		
		bx:di - PriorityList 
		ds - updated if moved
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: may cause chunks to move within block 
		and block to move on heap

		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			Priority list exists

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetPriorityListOD		proc	near
	class	GrObjBodyClass
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx,ds:[LMBH_handle]

getChunk:
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset	
	mov	di,ds:[di].GBI_priorityList	
	tst	di
	jz	create

	.leave
	ret

create:
	call	GrObjBodyPriorityListCreate
	jmp	getChunk

GrObjBodyGetPriorityListOD		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create chunks for priority list

CALLED BY:	INTERNAL

PASS:		
		bx - handle of block to use
RETURN:		
		ax - lmem handle of PriorityList

DESTROYED:	
		ds - not updated if block moved

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListCreate		proc	far
	uses	cx,di,ds,si
	.enter

	push	bx					;block handle
	call	ObjLockObjBlock

	;    Allocate chunk to hold priority list struct
	;

	mov	ds,ax					;block segment
	mov	al,mask OCF_IGNORE_DIRTY		;ObjChunkFlags
	mov	cx,size PriorityList
	call	LMemAlloc
	push	ax					;list struct lmem 

	;    Allocate chunk array to hold Priority List Elements
	;

	mov	bx,size PriorityListElement
	mov	al,mask OCF_IGNORE_DIRTY		;ObjChunkFlags
	clr	cx
	mov	si, cx
	call	ChunkArrayCreate
	pop	bx					;list struct lmem
	mov	di,ds:[bx]				;deref list struct
	mov	ds:[di].PL_list,si			;array lmem
	mov	ax,bx					;list struct lmem

	pop	bx					;block handle
	call	MemUnlock

	.leave
	ret
PriorityListCreate		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy chunks of the priority list

CALLED BY:	INTERNAL

PASS:		
		bx:si - optr of priority list
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
	srs	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListDestroy		proc	far
	uses	ax,di,ds
	.enter

	call	ObjLockObjBlock
	mov	ds,ax

	mov	di,ds:[si]
	mov	ax,ds:[di].PL_list
	jz	10$
	call	LMemFree
10$:
	mov	ax,si
	call	LMemFree

	call	MemUnlock

	.leave
	ret
PriorityListDestroy		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize data in priority list

CALLED BY:	INTERNAL
		
PASS:		
		es:si - PLInit
		bx:di - optr to PriorityList

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
	srs	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListInit		proc	far
	uses	ax,cx,ds,di,si
	.enter

	;    Lock priority list and deref lmem

	call	ObjLockObjBlock
	mov	ds,ax
	mov	di,ds:[di]

	xchg	di,si				;di <- PLI offset
						;si <- PL offset

	;    Set method, max elements, instructions and numElements 
	;

	mov	ax,es:[di].PLI_message
	mov	ds:[si].PL_message,ax
	mov	ax,es:[di].PLI_maxElements
	mov	ds:[si].PL_maxElements,ax
	mov	al,es:[di].PLI_instructions
	mov	ds:[si].PL_instructions,al
	mov	ax,es:[di].PLI_class.segment
	mov	ds:[si].PL_class.segment,ax
	mov	ax,es:[di].PLI_class.offset
	mov	ds:[si].PL_class.offset,ax
	clr	ds:[si].PL_numElements

	;    Empty chunk array
	;

	mov	ax,si				;PL offset
	mov	si,ds:[si].PL_list
	call	ChunkArrayZero

	;    Copy PLI_point to PL_point
	;

	segxchg	es,ds
	add	di,offset PLI_point
	mov	si,ax				;PL offset
	add	si,offset PL_point
	mov	cx,(size PointDWFixed) / 2
	xchg	di,si
	rep	movsw

	call	MemUnlock			;PriorityList

	.leave
	ret
PriorityListInit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset list to no elements

CALLED BY:	INTERNAL
		
PASS:		
		bx:di - optr to PriorityList

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
	srs	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListReset		proc	far
	uses	ax,ds,si
	.enter

	;    Lock priority list and deref lmem

	call	ObjLockObjBlock
	mov	ds,ax	
	mov	si,di				;PriorityList chunk handle
	mov	si,ds:[si]

	;    Empty chunk array
	;

	clr	ds:[si].PL_numElements
	mov	si,ds:[si].PL_list
	call	ChunkArrayZero

	call	MemUnlock			;PriorityList

	.leave
	ret
PriorityListReset		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert an element into the PriorityList

CALLED BY:	INTERNAL

PASS:		
		bx:di - optr of PriorityList
		cx:dx - optr to insert
		al - priority
		ah - other data
		
RETURN:		
		stc - element was inserted
		clc - element was not inserted - element number invalid

DESTROYED:	
		ds and es not updated if priority list block resizes

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListInsert		proc	far
	uses 	ax,ds
	.enter

	push	bx					;PL handle
	push	ax					;priority, and data
	call	ObjLockObjBlock
	mov	ds,ax

	pop	ax 					;priority and data
	mov	bx,ax					;priority and data
	call	PriorityListFindLoc
	jnc	append					;jmp if not found

	;    Insert new element at element index returned from FindLoc
	;

	call	PriorityListInsertAtIndex

done:
	pop	bx
	call	MemUnlock

	.leave
	ret

append:
	call	PriorityListAppend
	jmp	short done


PriorityListInsert		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListGetPLPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return value in PL_point

CALLED BY:	INTERNAL

PASS:		
		bx:di - optr of PriorityList
		ss:bp - PointDWFixed - empty
RETURN:		
		ss:bp - PointDWFixed - full

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListGetPLPoint		proc	far
	uses	ax,es,di
	.enter

	call	ObjLockObjBlock
	mov	es,ax

	mov	di,es:[di]
	MovDWF	ss:[bp].PDF_x, es:[di].PL_point.PDF_x, ax
	MovDWF	ss:[bp].PDF_y, es:[di].PL_point.PDF_y, ax

	call	MemUnlock

	.leave
	ret
PriorityListGetPLPoint		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListGetMethod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return PL_message

CALLED BY:	INTERNAL

PASS:		
		bx:di - optr of priority list
RETURN:		
		ax - method
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListGetMethod		proc	far
	uses	es,di
	.enter

	call	ObjLockObjBlock
	mov	es,ax

	mov	di,es:[di]
	mov	ax,es:[di].PL_message

	call	MemUnlock

	.leave
	ret
PriorityListGetMethod		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListGetNumElements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return PL_numElements

CALLED BY:	INTERNAL

PASS:		
		bx:di - optr of priority list
RETURN:		
		cx - numElements
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListGetNumElements		proc	far
	uses	es,di,ax
	.enter

	call	ObjLockObjBlock
	mov	es,ax

	mov	di,es:[di]
	mov	cx,es:[di].PL_numElements

	call	MemUnlock

	.leave
	ret
PriorityListGetNumElements		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListGetInstructions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return PL_instructions

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		bx:di - optr of priority list
RETURN:		
		al - instructions
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListGetInstructions		proc	far
	uses	es,di,cx
	.enter

	mov	ch,ah					;don't destroy

	call	ObjLockObjBlock
	mov	es,ax

	mov	di,es:[di]
	mov	al,es:[di].PL_instructions

	call	MemUnlock

	mov	ah,ch					;don't destroy

	.leave
	ret
PriorityListGetInstructions		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return PL_class

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		bx:di - optr of priority list
RETURN:		
		cx:dx - class

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListGetClass		proc	far
	uses	es,di,ax
	.enter

	call	ObjLockObjBlock
	mov	es,ax

	mov	di,es:[di]
	mov	cx,es:[di].PL_class.segment
	mov	dx,es:[di].PL_class.offset

	call	MemUnlock

	.leave
	ret
PriorityListGetClass		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListGetElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return element specified in list

CALLED BY:	INTERNAL

PASS:		
		bx:di - optr of priority list
		cx - element number (0 = first)
RETURN:		
		stc - element doesn't exist
		clc  - element exists
			cx:dx - optr
			al - priority
			ah - other data

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListGetElement		proc	far
	uses	ds,di,si
	.enter

	;    Lock Priority list block
	;

	call	ObjLockObjBlock
	mov	ds,ax

	;    Convert element number to pointer, jumping to unlock if
	;    element doesn't exist

	mov	di,ds:[di]
	mov	si,ds:[di].PL_list
	mov	ax,cx					;element number
	call	ChunkArrayElementToPtr
	jc	unlock					;jmp if not found

	;    Retrieve data from element and signal element found
	;

	mov	cx,ds:[di].PLE_od.handle
	mov	dx,ds:[di].PLE_od.chunk
	mov	al,ds:[di].PLE_priority
	mov	ah,ds:[di].PLE_other
	clc
unlock:
	call	MemUnlock

	.leave
	ret
PriorityListGetElement		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Routines below this point are not intended to be called from
	outside the priority list code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListFindLoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return element # to insert at, or flag need to append
		element to array

CALLED BY:	INTERNAL
		PriorityListInsert

PASS:		
		*ds:di - PriorityList
		al - priority

RETURN:		
		stc		
			ax - element number
		clc 
			need to append
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListFindLoc		proc	near
	uses	bx,dx,di,si
	.enter

	;    Get the offset of the first element in the list that has
	;    the same priority or lower. 
	;
	
	mov	si,ds:[di]				;deref PL
	mov	si,ds:[si].PL_list
	mov	bx,cs					;seg of call back
	mov 	di, offset PriorityListFindPriorityCallBack
	call	ChunkArrayEnum				;jmp if not found
	jnc	done

	;    Convert offset returned from Enum to element number
	;

	mov	di,dx					;element offset
	call	ChunkArrayPtrToElement
	stc

done:
	.leave
	ret
PriorityListFindLoc		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListFindPriorityCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call back routine for ChunkArrayEnum to find the
		first element in the array that has a priority less
		than the passed priority
		

CALLED BY:	INTERNAL
		ChunkArrayEnum

PASS:		
		*ds:si - array
		ds:di - element
		al - priority

RETURN:		
		stc - found
			dx - element offset
		clc - not found

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListFindPriorityCallBack		proc	far
	.enter

	cmp	al, ds:[di].PLE_priority
	ja	found

	clc
done:
	.leave
	ret

found:
	mov	dx,di			;offset of element
	stc
	jmp	short done



PriorityListFindPriorityCallBack		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListAppend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append PLE to end of priority list

CALLED BY:	INTERNAL
		PriorityListInsert
		
PASS:		
		*ds:di - PriorityList
		bl - priority 
		bh - data
		cx:dx - optr

RETURN:		
		ds - updated if moved
		stc - element was inserted
		clc - element was not inserted - element number invalid

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListAppend		proc	near
	uses	ax,si
	.enter

	;    If the array list is not full then append element
	;    to the end
	;

	mov	si,ds:[di]				;deref PL
	mov	ax,ds:[si].PL_numElements
	cmp	ax,ds:[si].PL_maxElements

	;    Bail if array is already full. Implied clc if jump
	;    taken provides return flag
	;

	jae	done					

	;    Append element to end of list and put ptr to it in ds:di
	;

	push	di					;PL chunk
	mov	si,ds:[si].PL_list
	call	ChunkArrayAppend

	;    Stuff data in new element
	;

	mov	ds:[di].PLE_priority,bl
	mov	ds:[di].PLE_other,bh
	mov	ds:[di].PLE_od.handle,cx
	mov	ds:[di].PLE_od.chunk,dx

	;    Increment count of elements
	;

	pop 	di					;PL chunk
	mov	si,ds:[di]				;deref PL
	inc	ds:[si].PL_numElements

	stc						;flag as inserted

done:
	.leave
	ret
PriorityListAppend		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListInsertAtIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert PLE element at index number

CALLED BY:	INTERNAL
		PriorityListInsert
		PriorityListInsertAt

PASS:		
		*ds:di - PriorityList
		ax - number
		bl - priority 
		bh - data
		cx:dx - optr

RETURN:		
		ds - updated if moved

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Currently always returns inserted or fatal errors

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListInsertAtIndex		proc	near
	uses	si
	.enter

	;    Create new array element and point ds:di at it
	;

	push	di					;PL chunk
	mov	si,ds:[di]				;deref PL
	mov	si,ds:[si].PL_list
	call	ChunkArrayElementToPtr
EC <	ERROR_C	INVALID_PRIORITY_LIST_INDEX		>
	call	ChunkArrayInsertAt

	;    Stuff data in new element
	;

	mov	ds:[di].PLE_priority,bl
	mov	ds:[di].PLE_other,bh
	mov	ds:[di].PLE_od.handle,cx
	mov	ds:[di].PLE_od.chunk,dx

	;    Increment count and trim list if necessary
	;

	pop 	di					;PL chunk
	mov	si,ds:[di]				;deref PL
	inc	ds:[si].PL_numElements
	call	PriorityListTrim

	stc						;flag as inserted

	.leave
	ret
PriorityListInsertAtIndex		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PriorityListTrim
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Trims list back to max elements if necessary.

CALLED BY:	INTERNAL
		PriorityListInsertAtIndex

PASS:		
		*ds:di - PriorityList

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
	srs	4/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PriorityListTrim		proc	near
	uses	ax,si
	.enter

	;    Check the number of elements. If it is
	;    more than the max elements, then jump to delete
	;    the last element
	;

	mov	si,ds:[di]			;deref PL
	mov	ax,ds:[si].PL_numElements
	cmp	ax,ds:[si].PL_maxElements
	ja	trimLast

done:
	.leave
	ret


trimLast:
	;    Trim the last element from the PL_list
	;

	dec	ds:[si].PL_numElements
	dec	ax				;# to delete
	mov	si,ds:[si].PL_list
	call	ChunkArrayElementToPtr
	call	ChunkArrayDelete
	jmp	short done

PriorityListTrim		endp



GrObjRequiredInteractiveCode ends
