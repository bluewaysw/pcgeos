COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Navigation Library
MODULE:		Navigate Controller
FILE:		navcontrolUtils.asm

AUTHOR:		Alvin Cham, Sep 27, 1994

ROUTINES:
	Name			Description
	----			-----------

    	NCObjMessageCheckAndSend
    	    	    	    	- send a message to UI object 

    	NCGetChildBlockAndFeaturesLocals
    	    	    	    	- get child block and features for the
    	    	    	    	controller into locals

    	NCGetToolBlockAndToolFeaturesLocals
    	    	    	    	- get tool block and tool features for
    	    	    	    	the controller into locals
    
    	NCSendToOutput	    	- send a notification to controller's
    	    	    	    	output

    	NCStringCopy	    	- string copy

    	AssertIsNavController	- assert for NavigateControlClass object
    	    	    	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/27/94   	Initial revision


DESCRIPTION:
	This file includes some utilies procedures for the navgate
    	controller class.

	$Id: navcontrolUtils.asm,v 1.1 97/04/05 01:24:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NavigateControlCode 	segment	    resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCObjMessageCheckAndSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to a UI object of the
    	    	NavigateController provided that the object has been
    	    	built. 
    
CALLED BY:	UTILITY
PASS:		^lbx:si	= OD of object
    	    	ds  	= fixupable segment
    	    	ax  	= message to send
    	    	values for message (cx, dx, bp)
RETURN:		ds - fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Send the passed message and parameteres to the object
    	    	so long as 'bx' is not null.  If 'bx' is null, then
    	    	we're trying to send a message to some UI object that
    	    	hasn't been built yet.  

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCObjMessageCheckAndSend	proc	near
	uses	di
	.enter

    	cmp 	bx, NULL
    	je  	done
    	mov 	di, mask MF_FIXUP_DS
    	call	ObjMessage

done:
	.leave
	ret
NCObjMessageCheckAndSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGetChildBlockAndFeaturesLocals
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
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGetChildBlockAndFeaturesLocals	proc	near
	uses	ax, bx
NAVIGATION_LOCALS
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
NCGetChildBlockAndFeaturesLocals	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGetToolBlockAndToolFeaturesLocals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get tool block and tool features for a controller into
		local vars
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
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGetToolBlockAndToolFeaturesLocals	proc	near
	uses	ax, bx
NAVIGATION_LOCALS
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
NCGetToolBlockAndToolFeaturesLocals	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCSendToOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the nav controller's output.
    	    	with a block of data

CALLED BY:	UTILITY
PASS:		*ds:si	= a NavigateControlClass object
    	    	cx  	= type of data, either a block of data or a word
    	    	bp  	= data (either a block or a word)
    	    	dx  	= notificationType
    	    	
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCSendToOutput	proc	near
class	NavigateControlClass
	uses	ax,bx,cx,di,si
	.enter 
EC  <	call	AssertIsNavController	    	    	>
    	mov 	di, ds:[si]
    	add 	di, ds:[di].NavigateControl_offset
    	movdw	bxsi, ds:[di].GCI_output
    	mov 	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
    	cmp 	cx, NSTOT_BLOCK
    	je  	withBlock
    	mov 	ax, MSG_META_NOTIFY
withBlock:    	
    	mov 	cx, MANUFACTURER_ID_GEOWORKS	; manufactureID
    	mov 	di, mask MF_CALL or mask MF_FIXUP_DS
    	call	ObjMessage

	.leave
	ret
NCSendToOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCStringCopy
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
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCStringCopy	proc	far
	uses	cx,si,di
	.enter

	segxchg	ds,es
	xchg	si,di
	call	LocalStringSize
	inc	cx				; size w/ null
	segxchg	ds,es
	xchg	si,di
	rep	movsb				; copy!

	.leave
	ret
NCStringCopy	endp



;---------------------------------------------------------------------------
;   Error check code below
;---------------------------------------------------------------------------

if  	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AssertIsNavController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	Internal
PASS:			
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		(1) Test if *ds:si = a NavigateControlClass object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AssertIsNavController	proc	near
	uses	di,es
	.enter

    	pushf

;   	call	VisCheckVisAssumption
    	mov 	di, segment NavigateControlClass
    	mov 	es, di
    	mov 	di, offset NavigateControlClass
    	call	ObjIsObjectInClass
    	ERROR_NC    OBJECT_IS_NOT_A_NAV_CONTROLLER

    	popf
	.leave
	ret
AssertIsNavController	endp

endif






NavigateControlCode 	ends
