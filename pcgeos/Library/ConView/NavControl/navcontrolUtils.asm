COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		navigation controller
FILE:		navcontrolUtils.asm

AUTHOR:		Jonathan Magasin, May 13, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/13/94   	Initial revision


DESCRIPTION:
	Useful routines for the content navigation 
	controller.
		

	$Id: navcontrolUtils.asm,v 1.1 97/04/04 17:49:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ContentNavControlCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUObjMessageCheckAndSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to a ui object of the NavControl
		provided the object has been built.
		
CALLED BY:	UTILITY
PASS: 		^lbx:si - OD of object
		ds - fixupable segment
		ax - message to send
		values for message (cx, dx, bp)
RETURN:		ds - fixed up
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		Send the passed message and parameters to
		the object so long as bx is not null.  If
		bx = null, then we're trying to send a 
		message to some ui object that isn't built
		yet (and may never be).  


KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUObjMessageCheckAndSend		proc	near
	uses	di
	.enter
	
	cmp	bx, NULL
	je	done
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
NCUObjMessageCheckAndSend		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUGetChildBlockAndFeaturesLocals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get child block and features for a controller into local vars
CALLED BY:	UTILITY

PASS:		*ds:si - controller
		ss:bp - inherited locals
RETURN:		ss:bp - inherited locals
			features - features that are on and interactable
			childBlock - handle of child block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUGetChildBlockAndFeaturesLocals	proc	near
	uses	ax, bx
CONTENT_NAV_LOCALS
	.enter	inherit
EC <	call	AssertIsNavController			>
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_childBlock
	mov	ss:childBlock, ax
	mov	ax, ds:[bx].TGCI_features
	test	ds:[bx].TGCI_interactableFlags, mask GCIF_NORMAL_UI
	jnz	setFeatures		
	clr	ax		
setFeatures:		
	mov	ss:features, ax

	.leave
	ret
NCUGetChildBlockAndFeaturesLocals	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUGetToolBlockAndToolFeaturesLocals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get tool block and tool features for a controller into
		local vars
CALLED BY:	UTILITY

PASS:		*ds:si - controller
		ss:bp - inherited locals
RETURN:		ss:bp - inherited locals
			toolFeatures - features that are on and interactable
			toolBlock - handle of child block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUGetToolBlockAndToolFeaturesLocals	proc	near
	uses	ax, bx
CONTENT_NAV_LOCALS
	.enter	inherit
EC <	call	AssertIsNavController			>
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_toolBlock
	mov	ss:toolBlock, ax
	mov	ax, ds:[bx].TGCI_toolboxFeatures
	test	ds:[bx].TGCI_interactableFlags, mask GCIF_TOOLBOX_UI
	jnz	setFeatures		
	clr	ax		
setFeatures:		
	mov	ss:toolFeatures, ax

	.leave
	ret
NCUGetToolBlockAndToolFeaturesLocals	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUStringCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	String copy utility for null-terminated strings.

CALLED BY:	GLOBAL
PASS:		ds:si - null-terminated source string
		es:di - destination

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUStringCopy	proc	far
	uses	cx,si,di
	.enter

	segxchg	ds,es
	xchg	si,di
	call	LocalStringSize
	inc	cx				; size w/ null
	segxchg	ds,es
	xchg	si,di
	rep	movsb				; Copy!

	.leave
	ret
NCUStringCopy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUSendToOutputStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the nav controller's
		output, the ContentGenView.  Parameters
		are placed on the stack.

CALLED BY:	UTILITY
PASS:		
	*ds:si - controller
	ax - message
	ss:bp - data
	dx - data size
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUSendToOutputStack	proc	near
	uses	bx, dx, di
	.enter
EC <	call	AssertIsNavController			>
	mov	bx, segment ContentGenViewClass
	mov	di, offset ContentGenViewClass	;bx:di <- class ptr
	call	GenControlSendToOutputStack

	.leave
	ret
NCUSendToOutputStack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUSendToOutputRegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message from the nav controller
		to the ContentGenView.

CALLED BY:	UTILITY
PASS:
	*ds:si - nav controller
	ax - message
	cx, dx, bp - data

RETURN:	nothing
DESTROYED: nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUSendToOutputRegs	proc	near
	uses	bx, di
	.enter
EC <	call	AssertIsNavController			>
	mov	bx, segment ContentGenViewClass
	mov	di, offset ContentGenViewClass	;bx:di <- class ptr
	call	GenControlSendToOutputRegs

	.leave
	ret
NCUSendToOutputRegs	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	AssertIsNavController

DESCRIPTION:	...

CALLED BY:	INTERNAL

PASS:

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/91		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK

AssertIsNavController	proc	near
	uses di, es
	.enter
	pushf

	call	VisCheckVisAssumption
	mov	di, segment ContentNavControlClass
	mov	es, di
	mov	di, offset ContentNavControlClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_IS_NOT_A_NAV_CONTROLLER

	popf
	.leave
	ret

AssertIsNavController	endp

endif

ContentNavControlCode	ends



