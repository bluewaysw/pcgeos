COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genInteraction.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenInteractionClass Interaction object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/89		Initial version

DESCRIPTION:
	This file contains routines to implement the Interaction class

	$Id: genInteraction.asm,v 1.1 97/04/07 11:45:17 newdeal Exp $

-------------------------------------------------------------------------------@

;see /s/p/M/U/D/GenInteraction for documentation

UserClassStructures	segment resource

; Declare the class record

	GenInteractionClass

UserClassStructures	ends

;---------------------------------------------------

Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenInteractionInitialize

DESCRIPTION:	Initialize object

PASS:
	*ds:si - instance data
	es - segment of GenInteractionClass
	ax - MSG_META_INITIALIZE

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	NOTE:  THIS ROUTINE ASSUME THAT THE OBJECT HAS JUST BEEN CREATED
	AND HAS INSTANCE DATA OF ALL 0'S FOR THE VIS PORTION

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/91		Initial version

------------------------------------------------------------------------------@

GenInteractionInitialize	method static	GenInteractionClass,
							MSG_META_INITIALIZE

	mov	di, offset GenInteractionClass
	call	ObjCallSuperNoLock
	;
	; Initialize to match .cpp and .esp defaults
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset

	mov	ds:[di].GII_type, GIT_ORGANIZATIONAL
	mov	ds:[di].GII_visibility, GIV_SUB_GROUP
	ret

GenInteractionInitialize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenInteractionBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for
					    GenInteractionClass

DESCRIPTION:	Return the correct specific class for an object

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenInteractionClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx - master offset of variant class to build

RETURN: cx:dx - class for specific UI part of object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@


GenInteractionBuild	method	GenInteractionClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS

EC <	test	ds:[di].GII_attrs, mask GIA_MODAL 			>
EC <	jz	10$							>
EC <	test	ds:[di].GII_attrs, mask GIA_SYS_MODAL			>
EC <	ERROR_NZ	INTERACTION_CANNOT_BE_MODAL_AND_SYS_MODAL	>
EC <10$:	
	;Get specific UI segment in ax.  Also makes sure that our parent
	;	 composite is built out.

	mov	ax,SPIR_BUILD_INTERACTION_GROUP
	GOTO	GenQueryUICallSpecificUI

GenInteractionBuild	endm

Build	ends

;
;---------------
;
		
GetUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenInteractionGetType -- MSG_GEN_INTERACTION_GET_TYPE for
					    GenInteractionClass

DESCRIPTION:	Returns the GenInteractionType enum from the instance data

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenInteractionClass

	ax - MSG_GEN_INTERACTION_GET_TYPE

RETURN: cl - GenInteractionType

ALLOWED TO DESTROY:
	ax, ch, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/17/91	Initial version

------------------------------------------------------------------------------@
GenInteractionGetType	method	dynamic GenInteractionClass,
						MSG_GEN_INTERACTION_GET_TYPE
	mov	cl, ds:[di].GII_type
	ret
GenInteractionGetType	endp

GetUncommon	ends

;
;---------------
;
		
BuildUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenInteractionSetType -- MSG_GEN_INTERACTION_SET_TYPE for
					    GenInteractionClass

DESCRIPTION:	Sets the GenInteractionType enum in the instance data

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenInteractionClass

	ax - MSG_GEN_INTERACTION_GET_TYPE
	cl - GenInteractionType to set

RETURN: nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/17/91	Initial version

------------------------------------------------------------------------------@
GenInteractionSetType	method	dynamic GenInteractionClass,
						MSG_GEN_INTERACTION_SET_TYPE
;setting the type while not usable won't have effect unless not built yet
;PrintMessage <BRIAN: Need to fix EC code here>
;;;EC <	call	GenEnsureNotUsable						>
	mov	bx, offset GII_type
	call	GenSetByte
	ret
GenInteractionSetType	endp

BuildUncommon	ends

;
;---------------
;
		
GetUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenInteractionGetVisibility --
		MSG_GEN_INTERACTION_GET_VISIBILITY for GenInteractionClass

DESCRIPTION:	Returns the GenInteractionVisibility enum from the instance data

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenInteractionClass

	ax - MSG_GEN_INTERACTION_GET_VISIBILITY

RETURN: cl - GenInteractionVisibility

ALLOWED TO DESTROY:
	ax, ch, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/17/91	Initial version

------------------------------------------------------------------------------@
GenInteractionGetVisibility	method	dynamic GenInteractionClass,
					MSG_GEN_INTERACTION_GET_VISIBILITY
	mov	cl, ds:[di].GII_visibility
	ret
GenInteractionGetVisibility	endp

GetUncommon	ends

;
;---------------
;
		
Build	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenInteractionSetVisibility --
		MSG_GEN_INTERACTION_SET_VISIBILITY for GenInteractionClass

DESCRIPTION:	Sets the GenInteractionVisibility enum in the instance data

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenInteractionClass

	ax - MSG_GEN_INTERACTION_GET_VISIBILITY
	cl - GenInteractionVisibility to set

RETURN: nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/17/91	Initial version

------------------------------------------------------------------------------@
GenInteractionSetVisibility	method	dynamic GenInteractionClass,
					MSG_GEN_INTERACTION_SET_VISIBILITY
;setting the type while not usable won't have effect unless not built yet
;PrintMessage <BRIAN: Need to fix EC code here>
;;;EC <	call	GenEnsureNotUsable						>
	mov	bx, offset GII_visibility
	call	GenSetByte
	ret
GenInteractionSetVisibility	endp

Build	ends

;
;---------------
;
		
GetUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenInteractionGetAttrs --
		MSG_GEN_INTERACTION_GET_ATTRS for GenInteractionClass

DESCRIPTION:	Gets the GenInteractionAttrs record in the instance data

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenInteractionClass

	ax - MSG_GEN_INTERACTION_GET_ATTRS

RETURN: cl - current GenInteractionAttrs

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/17/91	Initial version

------------------------------------------------------------------------------@
GenInteractionGetAttrs	method	dynamic GenInteractionClass,
						MSG_GEN_INTERACTION_GET_ATTRS
	mov	cl, ds:[di].GII_attrs
	Destroy	ax, ch, dx, bp
	ret
GenInteractionGetAttrs	endp

GetUncommon	ends

;
;---------------
;
		
Build	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenInteractionSetAttrs --
		MSG_GEN_INTERACTION_SET_ATTRS for GenInteractionClass

DESCRIPTION:	Sets the GenInteractionAttrs record in the instance data

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenInteractionClass

	ax - MSG_GEN_INTERACTION_SET_ATTRS
	cl - GenInteractionAttrs to set
	ch - GenInteractionAttrs to clear

RETURN: nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/17/91	Initial version

------------------------------------------------------------------------------@
GenInteractionSetAttrs	method	dynamic GenInteractionClass,
						MSG_GEN_INTERACTION_SET_ATTRS
;setting the type while not usable won't have effect unless not built yet
;PrintMessage <BRIAN: Need to fix EC code here>
;;;EC <	call	GenEnsureNotUsable						>
	mov	al, ds:[di].GII_attrs		; get current attrs
	not	ch
	andnf	al, ch				; clear bits first
	ornf	al, cl				; then set bits
	mov_tr	cl, al				; cl = bits
	mov	bx, offset GII_attrs
	call	GenSetByte
	ret
GenInteractionSetAttrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenInteractionDisableDiscarding
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keeps the dialog from being discarded until it has come 
		onscreen and has closed again.

CALLED BY:	GLOBAL
PASS:		*ds:si - GenInteraction object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenInteractionDisableDiscarding	method dynamic GenInteractionClass,
				MSG_GEN_INTERACTION_DISABLE_DISCARDING
	.enter
EC <	mov	ax, HINT_INTERACTION_DISCARD_WHEN_CLOSED		>
EC <	call	ObjVarFindData						>
EC <	ERROR_NC	NOT_A_DISCARDABLE_OBJECT			>


;	Check to be sure that all the children lie in the same block
;	with this parent.

EC <	mov	cx, ds:[LMBH_handle]					>
EC <	call	EnsureObjAndChildrenInThisBlock				>


	mov	ax, TEMP_INTERACTION_DISCARD_INFO
	call	ObjVarFindData
	jc	setInUse
	mov	cx, size GenInteractionDiscardInfo
	call	ObjVarAddData
setInUse:
	mov	ds:[bx].GIDI_inUse, -1
	.leave
	ret
GenInteractionDisableDiscarding	endp

if	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureObjAndChildrenInThisBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureObjAndChildrenInThisBlock	proc	far
	class	GenClass
	.enter
	cmp	cx, ds:[LMBH_handle]
	ERROR_NZ	ALL_CHILDREN_OF_DISCARDABLE_DIALOG_MUST_BE_IN_THE_SAME_RESOURCE

	clr	bx
	push	bx, bx			;Start at 0th (first) child
	mov	bx, offset GI_link
	push	bx
	mov	bx, offset EnsureObjAndChildrenInThisBlock
	pushdw	csbx
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	mov	cx, ds:[LMBH_handle]
	call	ObjCompProcessChildren
	clc
	.leave
	ret
EnsureObjAndChildrenInThisBlock	endp

endif

Build ends
