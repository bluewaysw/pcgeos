COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UI	
FILE:		uiColor.asm

AUTHOR:		Steve Yegge, Jul 30, 1992

ROUTINES:
	Name			Description
	----			-----------
	ColorTriggerSetColors	sets any or all of the background colors
	ColorToolSetColors
	ColorListItemSetColors
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/92		Initial revision


DESCRIPTION:
	
	This file contains the method handlers for the color-gen-subclasses

	$Id: uiColor.asm,v 1.1 97/04/04 16:06:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColorObjectCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorTriggerSetColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_ICON_COLOR_TRIGGER_SET_COLORS handler

CALLED BY:	global

PASS:		*ds:si	= ColorTriggerClass object
		ch = on-color 1
		cl = on-color 2
		dh = off-color 1
		dl = off-color 2
		dx = which colors to set (ColorObjectColorsToSet record)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Changes the vardata and forces a redraw.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColorTriggerSetColors	method dynamic ColorTriggerClass, 
					MSG_ICON_COLOR_TRIGGER_SET_COLORS
	uses	ax, dx
	.enter

	;
	;  Get the new colors.
	;

	call	SetVarDataColor

	;
	;  Redraw.
	;
	
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	.leave
	ret
ColorTriggerSetColors	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorTriggerGetColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the vardata color pairs for the trigger.

CALLED BY:	MSG_ICON_COLOR_TRIGGER_GET_COLORS

PASS:		nothing

RETURN:		ch = on-color 1
		cl = on-color 2
		dh = off-color 1
		dl = off-color 2

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Get a pointer to the vardata, and return the colors.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColorTriggerGetColors	method dynamic ColorTriggerClass, 
					MSG_ICON_COLOR_TRIGGER_GET_COLORS
	uses	ax
	.enter

	;
	;  First get a pointer to the vardata
	;

	mov	ax, HINT_GADGET_BACKGROUND_COLORS
	call	ObjVarFindData				; returns ds:bx = data
	jnc	done					; carry set if success

	;
	;  return the colors in cx & dx
	;

	mov	ch, ds:[bx].BC_selectedColor1
	mov	cl, ds:[bx].BC_selectedColor2
	mov	dh, ds:[bx].BC_unselectedColor1
	mov	dl, ds:[bx].BC_unselectedColor2
done:
	.leave
	ret
ColorTriggerGetColors	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorListItemSetColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the background colors for the preview list-item.

CALLED BY:	MSG_ICON_COLOR_LIST_ITEM_SET_COLORS

PASS:		*ds:si	= ColorListItemClass object
		ch = on-color 1
		cl = on-color 2
		dh = off-color 1
		dl = off-color 2
		bp = which colors to set (ColorObjectColorsToSet record)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Changes the vardata and forces a redraw.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	Doesn't do anything, since we don't support changing the
	background colors of lists in our specific UI's so far.
	I'm leaving it in because I'm hopeful.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/92   	Initial version

DESCRIPTION:

	$Id: uiColor.asm,v 1.1 97/04/04 16:06:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColorListItemSetColors	method dynamic ColorListItemClass, 
					MSG_ICON_COLOR_LIST_ITEM_SET_COLORS
	uses	ax, dx
	.enter

	;
	;  Get new colors.
	;

	call	SetVarDataColor

	;
	;  Force redraw.
	;

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	.leave
	ret
ColorListItemSetColors	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetVarDataColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changes the vardata color associated with 
		HINT_GADGET_BACKGROUND_COLORS

CALLED BY:	internal

PASS:		*ds:si = object
		ch = on-color 1
		cl = on-color 2
		dh = off-color 1
		dl = off-color 2
		bp = which colors to set (ColorObjectColorsToSet record)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Move the colors in ch, cl, dh and dl into vardata if the
	corresponding flags are set in bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetVarDataColor	proc	near
	uses	ax, bx, si, bp
	.enter

	;
	;  First get a pointer to the vardata
	;

	mov	ax, HINT_GADGET_BACKGROUND_COLORS
	call	ObjVarFindData				; returns ds:bx = data
	jnc	done					; carry set if success

	;
	; Now set any applicable colors in the object
	;

	mov	si, bx
	test	bp, mask COCTS_ON_ONE			; set on-color 1?
	jz	onColor2
	mov	ds:[si].BC_selectedColor1, ch

onColor2:

	test	bp, mask COCTS_ON_TWO			; set on-color 2?
	jz	offColor1
	mov	ds:[si].BC_selectedColor2, cl

offColor1:
	
	test	bp, mask COCTS_OFF_ONE			; set off-color 1?
	jz	offColor2
	mov	ds:[si].BC_unselectedColor1, dh
	
offColor2:
	
	test	bp, mask COCTS_OFF_TWO			; set off-color 2?
	jz	done
	mov	ds:[si].BC_unselectedColor2, dl

done:

	.leave
	ret
SetVarDataColor	endp


ColorObjectCode	ends
