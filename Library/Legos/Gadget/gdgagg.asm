COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gdgagg.asm

AUTHOR:		Martin Turon, Sep 27, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/27/95   	Initial version


DESCRIPTION:
	Some code to contain list components.


	$Id: gdgagg.asm,v 1.1 98/03/11 04:31:07 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Used for intercepting MSG_SPEC_CONVERT_DESIRED_SIZE_HINT on the
; dynamic list placed in the interaction.
;
MyGenInteractionClass		class	GenInteractionClass
MyGenInteractionClass		endc

idata	segment
	GadgetAggClass
	MyGenInteractionClass
idata	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjCallContentNoLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		*ds:si	= GadgetAggClass object
		ax	= message

RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjCallContentNoLock	proc	far

		class	GadgetAggClass

		uses	di, si
		.enter

		mov	di, ds:[si]			; deref handle
		add	di, ds:[di].Gadget_offset
		mov	si, ds:[di].GAI_contentObj.chunk
		call	ObjCallInstanceNoLock

		.leave
		ret
ObjCallContentNoLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetAggResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the system of our association to GenInteraction

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetAggClass object
		ds:di	= GadgetAggClass instance data
		ds:bx	= GadgetAggClass object (same as *ds:si)
		es 	= segment of GadgetAggClass
		ax	= message #

RETURN:		cx:dx	= superclass to use
DESTROYED:	

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetAggResolveVariantSuperclass	method dynamic GadgetAggClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
	.enter

	cmp	cx, Gadget_offset
	je	returnSuper

	mov	di, offset GadgetAggClass
	call	ObjCallSuperNoLock
done:
	.leave
	ret

returnSuper:
	mov	cx, segment MyGenInteractionClass
	mov	dx, offset MyGenInteractionClass
	jmp	done

GadgetAggResolveVariantSuperclass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GagdetAggInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Instantiates an instance of GAI_contentClass to be contained
		as a child.

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GenAggClass object
		ds:di	= GenAggClass instance data
		ds:bx	= GenAggClass object (same as *ds:si)
		es 	= segment of GenAggClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GagdetAggInitialize	method dynamic GadgetAggClass, 
					MSG_ENT_INITIALIZE
		.enter
	;
	; Let superclass go first
	;
		mov	di, offset GadgetAggClass
		call	ObjCallSuperNoLock
	;
	; Create an instance of the *real* object that makes up this
	; gadget's behavior.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gadget_offset
		movdw	esdi, ds:[di].GAI_contentClass	
		mov	bx, ds:[LMBH_handle]
		push	si
		call	ObjInstantiate

	;
	; Save our child.  We provide the abstraction layer to
	; map our child's information to general gadget properties
	; such as left, top, height, width (simply by being an interaction
	; that contains them.)
	;
		pop	di
		mov	di, ds:[di]
		add	di, ds:[di].Gadget_offset
		movdw	ds:[di].GAI_contentObj, bxsi

		.leave		
		ret
GagdetAggInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyGenInteractionSpecConvertDesiredSizeHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't allow superclass to add space to FIXED_SIZE hints

CALLED BY:	MSG_SPEC_CONVERT_DESIRED_SIZE_HINT
PASS:		*ds:si	= MyGenInteractionClass object
		ds:di	= MyGenInteractionClass instance data
		ds:bx	= MyGenInteractionClass object (same as *ds:si)
		es 	= segment of MyGenInteractionClass
		ax	= message #
		cx	-- {SpecSizeSpec} desired width
		dx   	-- {SpecSizeSpec} desired height
RETURN:		cx, dx	-- converted width, height
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/12/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyGenInteractionSpecConvertDesiredSizeHint	method dynamic MyGenInteractionClass,
					MSG_SPEC_CONVERT_DESIRED_SIZE_HINT
		.enter
	;
	; This page intentionally left blank.
	;
	; Don't allow superclass to add space to our desired size.
		
		.leave
		Destroy	ax, bp
		ret
MyGenInteractionSpecConvertDesiredSizeHint	endm
