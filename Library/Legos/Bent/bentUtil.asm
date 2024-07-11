COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:        PC/GEOS
MODULE:         LEGOS - UI Builder
FILE:		bentutil.asm

AUTHOR:		Martin Turon, Feb 13, 1995

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	2/13/95   	Initial version

DESCRIPTION:
	Utility functions used by bent written in assembly.  Most routines
	in this file were written because access to a certain system
	facility was difficult or impossible in C.
		
	$Id: bentUtil.asm,v 1.2 98/03/11 15:44:08 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def
include assert.def
include	Legos/ent.def

BentAsmUtilsResource	segment	resource

global BENTPROCESSPROPERTYARRAYELEMENT:far
global BENTFILTERPOSTPROCESSELEMENTS:far
global BENT_CLIPBOARDFREEITEM:far
global BENT_VISTESTPOINTINBOUNDS:far
global SETDSTODGROUP:far
global RESTOREDS:far

SETDSTODGROUP	proc	far
	mov	ax, ds		; return old DS in ax
	segmov	ds, dgroup, dx
	ret
SETDSTODGROUP	endp

RESTOREDS	proc	far	oldDS:word
	.enter
	segmov	ds, oldDS, ax
	.leave
	ret
RESTOREDS	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BENTPROCESSPROPERTYARRAYELEMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuffs the property name of the given name array element
		into the first argument of the given event, and dispatches
		that event. 

CALLED BY:	MSG_BENT_ENUM_PROPERTIES

PASS:		element:fptr	= pointer to current element
		enumData:fptr	= event to send for this property
		ax		= element size

RETURN:		carry clear
		ax, cx, dx, bp, es - data to pass to next

DESTROYED:	bx, si, di

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	2/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
BENTPROCESSPROPERTYARRAYELEMENT	proc	far	element:fptr,
							event:fptr

		property	local	30 dup (TCHAR)
		callbackData	local	fptr

		uses	bx, cx, di, si, ds, es
		.enter
	;
	; Because name arrays suck so bad, and provide no way to have the
	; element name be null-terminated, it is very difficult to use the
	; name of the element in C...  Luckily the assembly version of
	; ChunkArrayEnum passes the element size in ax.  What follows is the
	; painful extraction of the property name from the given element.
	; We copy the property name into a local buffer on the stack frame,
	; and null-terminate it. 
	; 
		lds	si, element
		cmp	ds:[si].REH_refCount.WAAH_high, EA_FREE_ELEMENT
		je	done			; skip free elements

		mov	cx, size NameArrayElement + size ComponentData
		xchg	ax, cx
		sub	cx, ax			; length of property name
		add	si, ax			; pointer to property name
		segmov	es, ss
		lea	di, property
		push	di
DBCS <		shr	cx						>
		
EC <		cmp	cx, 30  					>
EC <		ERROR_AE -1						>
		LocalCopyNString
		clr	{TCHAR}es:[di]
		pop	di
	;
	; Now stuff a pointer to the copied property name into callbackData,
	; and pass the offset of callbackData to the callback of
	; MessageProcess.  Our callback routine will extract the pointer to
	; the copied property name and pass it as the first argument to the
	; encapsulated event.
	;
		mov	cx, event.low
		movdw	ss:[callbackData], esdi	; put property name on stack
		lea	di, ss:[callbackData]

		push	bp
		mov	bx, cx			; ^hbx = ClassedEvent
		mov	ax, offset BentEnumPropertyDispatchCallback
		pushdw	csax			; cs:ax = callback routine
		call	MessageProcess		; process event
		pop	bp
done:
		clr	ax			; process all elements
		.leave
		ret
BENTPROCESSPROPERTYARRAYELEMENT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BENTMIGRATEPOSTPROCESSPROPERTIES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move properties that we know we want to post-process (e.g.
		complex) to the postProcessArray

CALLED BY:	MSG_BENT_ENUM_PROPERTIES
PASS:		element:fptr		= pointer to current element
		postProcessArray:optr 	= optr to post-process name array
		si 			= chunk of array we're enumerating
		ax 			= size of element
RETURN:		carry clear
		cx, dx, bp, es - data to pass to next
		ax nonzero to stop
DESTROYED:
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
myAssertAscii	macro	expr, len

		_ParseDWordArg <expr>, drl, drh, regargs, <myAssertAscii>
		
		PreserveAndGetIntoReg	ds, %drh
		PreserveAndGetIntoReg	si, %drl
		CheckAsciiString
		RestoreReg		si, %drl
		RestoreReg		ds, %drh
endm

BENTFILTERPOSTPROCESSELEMENTS	proc	far	element:fptr,
						postProcessArray:optr
		.enter
	;
	; check if element is of LT_TYPE_COMPLEX
	;
		mov	cx, ax			; cx = size of element
		lds	di, element
		call	ChunkArrayPtrToElement	; ax = #, for later use
		cmp	ds:[di].NAE_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
		je	done
		lea	di, ds:[di].NAE_data
		cmp	ds:[di].CD_type, LT_TYPE_COMPLEX
		je	migrate
	; go ahead and migrate out errors so Parse_CompInit doesn't choke
		cmp 	ds:[di].CD_type, LT_TYPE_ERROR
		je	migrate
done:
		clr	ax
		.leave
		ret
migrate:
	;
	; if so, add to postProcessArray and remove from propArray
	;
		push	ax, si		; count, array
	Assert	handle	ds:LMBH_handle
		push	ds:LMBH_handle
		mov	dx, ds
		mov	ax, di			; dx:ax = pointer to data
		add	di, size ComponentData	
		segmov	es, ds			; es:di = pointer to name
		sub	cx, size NameArrayElement + size ComponentData
						; cx = length of name
	Assert	g cx, 0
	;	myAssertAscii esdi, cx
ifndef DO_DBCS
		Assert	ascii esdi, cx
endif
		movdw	bxsi, ss:[postProcessArray]
	Assert	optr bxsi
		call	MemDerefDS		; ds:si = postArray
		clr	bx			; size, flags
DBCS <		shr	cx			; adjust size to length	> 
		call	NameArrayAdd
		pop	bx
		call	MemDerefDS
	; EC segment will choke on a bad ES because NameArrayAdd invalids
	; ES without updating it
EC <		segmov	es, ds						>
		pop	ax, si		; count, array
		
		call	ElementArrayDelete
		jmp	done

BENTFILTERPOSTPROCESSELEMENTS	endp

	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BentEnumPropertyDispatchCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuffs the given pointer to the property name into the
		first argument of the passed in message.  If the message
		isn't stack based, the pointer is passed in cx:dx.

CALLED BY:	INTERNAL - BentSendEventWithPropertyArg via MessageProcess
PASS:		Same as ObjMessage 
		di		= offset into stack where 
				  fptr to name of property can be found
		carry		= set if event has stack data

RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di, bp, ds, es

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BentEnumPropertyDispatchCallback	proc	far
		.enter
		jc	stuffStack
		movdw	cxdx, ss:[di]
		jmp	dispatch
stuffStack:
		push	ax
		movdw	ss:[bp], ss:[di], ax
		pop	ax
dispatch:
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		.leave
		GOTO	ObjMessage
BentEnumPropertyDispatchCallback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BENT_CLIPBOARDFREEITEM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for Bent_ClipboardFreeItem

CALLED BY:	GLOBAL

C DECLARATION:	extern void _far _pascal
		    Bent_ClipboardFreeItem(dword item);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
BENT_CLIPBOARDFREEITEM	proc	far	item:dword
	;uses	cs,ds,es,si,di
	.enter
		movdw	bxax, ss:[item]
		call	ClipboardFreeItem
	.leave
	ret
BENT_CLIPBOARDFREEITEM	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BENT_VISTESTPOINTINBOUNDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for VisTestPointInBounds

CALLED BY:	INTERNAL

PASS:		optr	comp
		int	x
		int	y

RETURN:		Boolean	inBounds

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	3/2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
BENT_VISTESTPOINTINBOUNDS	proc	far	comp:optr, x:sword, y:sword
	uses	bx, cx, dx, si, ds
	.enter
	movdw	bxsi, comp
	call	ObjLockObjBlock
	mov	ds, ax
	mov	cx, x
	mov	dx, y
	call	VisTestPointInBounds
	call	MemUnlock
	mov	ax, 0 			; clear ax without affecting flags
	jnc	done
	dec	ax
done:
	.leave
	ret
BENT_VISTESTPOINTINBOUNDS	endp
	SetDefaultConvention


BentAsmUtilsResource	ends
