COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Visual Geos
MODULE:		Component Object Library
FILE:		entec.asm

AUTHOR:		David Loftesness, Jun  1, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	DL	6/ 1/94   	Initial revision


DESCRIPTION:
	
		

	$Id: entEC.asm,v 1.1 98/03/06 17:56:49 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
; 




if 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the space we allocated wasn't scribbled into

CALLED BY:	
PASS:		*ds:si	= chunk
		ds:di	= element ptr
		ax	= size of element
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	8/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckElement	proc	far
	uses	ax, di, cx, es
	.enter
		call	ECCheckBounds
	;;
	;; Check to see that we haven't scribbled
	;;
		add	di, ax
		mov	cx, EC_EXTRA_CHUNK_SIZE
		sub	di, cx
		mov	ax, 0xCC
		segmov	es, ds
		repe	scasb
		ERROR_NE	-1
		
	.leave
	ret
ECCheckElement	endp


endif

ifdef DO_ERROR_CHECKING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckEntObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks that object is ent object and that the ent part
		has been grown out.

CALLED BY:	EXTERNAL
PASS:		ds:si	= EntClass object	
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckEntObject	proc	far
	class	GenClass
	uses	ax, bx, di, es
	.enter
	pushf
	call	SysGetECLevel
	test	ax, mask ECF_NORMAL
	jz	done

	mov	di, segment EntClass
	mov	es, di
	mov	di, offset EntClass
	call	ObjIsObjectInClass
	ERROR_NC ENT_OBJECT_NOT_VALID
	; This operation can only operation on EntClass objects.  
	; Make sure that the object is of one of the predefined EntClass 
	; or is a subclass thereof.

	mov	di, ds:[si]
	tst	ds:[di].Ent_offset

	ERROR_E	ENT_OBJECT_NOT_VALID
	; Ent part of object must be grown before this operation can occur.
	; Make sure that the object is an Ent object.
done::
	popf
	.leave
	ret
ECCheckEntObject	endp

endif
