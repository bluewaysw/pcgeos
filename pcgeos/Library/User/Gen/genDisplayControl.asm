COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genDisplayControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenDisplayGroupClass		Base windows

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to implement the GenDisplayGroup class.

	$Id: genDisplayControl.asm,v 1.1 97/04/07 11:45:21 newdeal Exp $

------------------------------------------------------------------------------@

COMMENT `CLASS DESCRIPTION-----------------------------------------------------

			GenDisplayGroupClass

Synopsis
--------

GenDisplayGroupClass manages GenDisplay's.  It gives the user controls to
manipulate the Display's (new, hide, arrange, select).  By default, most
specific UI's will use an MDI (Multiple Document Interface) type approach
(which is similar to the Mac model).  In this model, the application's main
window has a large area on which the GenDisplay's are placed, and the
displays are clipped to that area.  The alternative is to just put the
displays on the field window.

Most specific UI's will generate some kind of "window" menu for the user
to manipulate the windows.

Most specific UI's will by default combine the menu controls of the selected
display with the menu controls of the (usually enclosing) main window.  The
alternative is to have menu controls on each display.

------------------------------------------------------------------------------`

UserClassStructures	segment resource

;Declare the class record

	GenDisplayGroupClass

UserClassStructures	ends

;---------------------------------------------------

BuildUncommon segment resource	;MSG_META_INITIALIZE is rarely sent.


COMMENT @----------------------------------------------------------------------

METHOD:		GenDisplayGroupInitialize

DESCRIPTION:	Initialize a display control object (this is used in cases
		where this generic object is Instantiated).

PASS:	*ds:si - instance data (for object in GenDisplayGroup class)
	es - segment of GenDisplayGroupClass

	ax - MSG_META_INITIALIZE

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		Initial version

------------------------------------------------------------------------------@

GenDisplayGroupInitialize	method	GenDisplayGroupClass, \
							MSG_META_INITIALIZE
	ORNF	ds:[di].GI_attrs, mask GA_TARGETABLE

	mov	di, offset GenDisplayGroupClass
	GOTO	ObjCallSuperNoLock

GenDisplayGroupInitialize	endm

BuildUncommon ends

;-----------------------

Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenDisplayGroupBuild

DESCRIPTION:	Return the correct specific class for an object

PASS:	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenDisplayGroupClass

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
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


GenDisplayGroupBuild	method	GenDisplayGroupClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_DISPLAY_CONTROL
	GOTO	GenQueryUICallSpecificUI
GenDisplayGroupBuild	endm

Build ends

;-----------------------

LessCommon	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplayGroupSetFullSized

DESCRIPTION:	We intercept these methods here to update our generic
		state data.

PASS:	*ds:si - instance data for object
	es - segment of GenDisplayGroupClass

	ax - MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/5/92		initial version

------------------------------------------------------------------------------@

GenDisplayGroupSetFullSized	method	GenDisplayGroupClass, \
					MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED
	;
	; If not full-size-able, ignore.
	;
	mov	ax, ATTR_GEN_DISPLAY_GROUP_NO_FULL_SIZED
	call	ObjVarFindData			; carry set if found
	jc	done				; cannot full-size, ignore

	mov	ax, ATTR_GEN_DISPLAY_GROUP_OVERLAPPING_STATE
	call	ObjVarDeleteData	; carry clear if data found and deleted
					;	(marks dirty if deleted)
	jc	done			; not found -> already full-sized

	clr	cx			; allow optimized check
	call	GenCheckIfFullyUsable	; if not fully usable, quit here
	jnc	done

	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED
	call	GenCallSpecIfGrown	; send on to spec UI if grown
done:
	ret
GenDisplayGroupSetFullSized	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplayGroupSetOverlapping

DESCRIPTION:	We intercept these methods here to update our generic
		state data.

PASS:	*ds:si - instance data for object
	es - segment of GenDisplayGroupClass

	ax - MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/5/92		initial version

------------------------------------------------------------------------------@

GenDisplayGroupSetOverlapping	method	GenDisplayGroupClass, \
					MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING
	;
	; If not overlapping-able, ignore.
	;
	mov	ax, ATTR_GEN_DISPLAY_GROUP_NO_OVERLAPPING
	call	ObjVarFindData			; carry set if found
	jc	done				; cannot overlapping, ignore

	mov	ax, ATTR_GEN_DISPLAY_GROUP_OVERLAPPING_STATE or \
						mask VDF_SAVE_TO_STATE
	call	ObjVarFindData		; carry set if found
	jc	done			; already overlapping, done
	clr	cx
	call	ObjVarAddData		; else, set overlapping flag
					;	(marks dirty)

	clr	cx			; allow optimized check
	call	GenCheckIfFullyUsable	; if not fully usable, quit here
	jnc	done

	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING
	call	GenCallSpecIfGrown	; send on to spec UI if grown
done:
	ret
GenDisplayGroupSetOverlapping	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplayGroupGetFullSized

DESCRIPTION:	Check if full-sized.

PASS:	*ds:si - instance data for object
	es - segment of GenDisplayGroupClass

	ax - MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED

RETURN:	carry set if full-sized

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/11/92		initial version

------------------------------------------------------------------------------@

GenDisplayGroupGetFullSized	method	GenDisplayGroupClass, \
					MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED

	mov	ax, ATTR_GEN_DISPLAY_GROUP_OVERLAPPING_STATE
	call	ObjVarFindData		; carry set if found (overlapping)
	cmc				; carry clear if overlapping
					; carry set if full-sized
	ret
GenDisplayGroupGetFullSized	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDisplayGroupTileDisplays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tile if allowed

CALLED BY:	MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS
PASS:		*ds:si	= GenDisplayGroupClass object
		ds:di	= GenDisplayGroupClass instance data
		ds:bx	= GenDisplayGroupClass object (same as *ds:si)
		es 	= segment of GenDisplayGroupClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/31/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenDisplayGroupTileDisplays	method dynamic GenDisplayGroupClass, 
					MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS
	;
	; If not overlapping-able, ignore.
	;
	mov	ax, ATTR_GEN_DISPLAY_GROUP_NO_OVERLAPPING
	call	ObjVarFindData			; carry set if found
	jc	done				; cannot overlapping, ignore

	clr	cx			; allow optimized check
	call	GenCheckIfFullyUsable	; if not fully usable, quit here
	jnc	done

	mov	ax, MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS
	GOTO	GenCallSpecIfGrown	; send on to spec UI if grown
done:
	ret
GenDisplayGroupTileDisplays	endm

LessCommon	ends
