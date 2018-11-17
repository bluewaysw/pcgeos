COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoCalc
MODULE:		UI
FILE:		uiGeoCalcDisplayGroup.asm

AUTHOR:		Andrew Wilson, Dec  7, 1992
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 7/92		Initial revision

DESCRIPTION:
	Implements a subclass of GenDisplayGroup that does not grab the 
	focus in noKbd mode, except in certain rare circumstances.	

	$Id: uiGeoCalcDisplayGroup.asm,v 1.1 97/04/04 15:48:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcClassStructures	segment	resource
	GeoCalcDisplayGroupClass
GeoCalcClassStructures	ends

Document	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDisplayGroupResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add/remove the HINT_DEFAULT_FOCUS depending upon whether or
		not we have a keyboard installed.

CALLED BY:	GLOBAL
PASS:		stuff from caller
RETURN:		stuff from superclass
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDisplayGroupResolveVariantSuperclass	method GeoCalcDisplayGroupClass,
				MSG_META_RESOLVE_VARIANT_SUPERCLASS

	;
	; Assume that we are not focusable, when we first come up.
	;
	clr	ds:[di].GCDGI_focusable

	mov	di, offset GeoCalcDisplayGroupClass
	GOTO	ObjCallSuperNoLock

GeoCalcDisplayGroupResolveVariantSuperclass	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDisplayGroupGrabFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We intercept this message if there is no keyboard.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDisplayGroupGrabFocusExcl	method	GeoCalcDisplayGroupClass,
						MSG_META_GRAB_FOCUS_EXCL
	;
	; If the current tool is not the GrObj text tool, do extra checks.
	; The DisplayGroup object will only be focusable if the current tool
	; is the GrObj text tool.
	;
	mov	di, ds:[si]
	add	di, ds:[di].GeoCalcDisplayGroup_offset
	tst	ds:[di].GCDGI_focusable
	jnz	getFocus

	;
	; See if if the edit bar has the focus or not -- if so, just exit
	;
	push	si
	mov	ax, MSG_SSEBC_GET_FLAGS
	GetResourceHandleNS GCEditBarControl, bx
	mov	si, offset GCEditBarControl	;^lbx:si <- OD of display ctrl
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	test	cl, mask SSEBCF_IS_FOCUS	;is edit bar focus?
	jnz	exit				;exit if so...

	;
	; Either the tool is the GrObj text tool or the edit bar doesn't
	; have the focus.  Allow the focus change to happen...
	;
getFocus:
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, offset GeoCalcDisplayGroupClass
	GOTO	ObjCallSuperNoLock

exit:
	ret
GeoCalcDisplayGroupGrabFocusExcl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDisplayGroupSetFocusable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the display group focusable or not. This only matters
		if there is no keyboard.

CALLED BY:	GLOBAL
PASS:		cx - non-zero if we are focusable.
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDisplayGroupSetFocusable	method GeoCalcDisplayGroupClass,
				MSG_GEOCALC_DISPLAY_GROUP_SET_FOCUSABLE
	.enter
	mov	ds:[di].GCDGI_focusable, cx
	.leave
	ret
GeoCalcDisplayGroupSetFocusable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDisplayGroupTileDisplays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If either of the displays has locked rows and columns,
		warn the user and unlock them.

CALLED BY:	GLOBAL
PASS:		
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/10/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Document	ends
