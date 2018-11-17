COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen (generic object portion of generic UI)
FILE:		genDisplay.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenDisplayClass		A window which lives inside a GenDisplayGroup.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to implement the GenDisplay class.

	$Id: genDisplay.asm,v 1.1 97/04/07 11:44:48 newdeal Exp $

------------------------------------------------------------------------------@

COMMENT `CLASS DESCRIPTION-----------------------------------------------------

			GenDisplayClass

Synopsis
--------

GenDisplayClass provides base windows.

------------------------------------------------------------------------------`

UserClassStructures	segment resource

;Declare the class record

	GenDisplayClass

UserClassStructures	ends

;---------------------------------------------------

BuildUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenDisplayInitialize

DESCRIPTION:	Initialize a display object (this is used in cases where this
		generic object is Instantiated).

PASS:	*ds:si - instance data (for object in GenDisplay class)
	es - segment of GenDisplayClass
	ax - MSG_META_INITIALIZE

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version

------------------------------------------------------------------------------@

GenDisplayInitialize	method	GenDisplayClass, MSG_META_INITIALIZE

	;By default, set to user dismissable
	ORNF	ds:[di].GDI_attributes, mask GDA_USER_DISMISSABLE

	; & targetable
	ORNF	ds:[di].GI_attrs, mask GA_TARGETABLE

	mov	di, offset GenDisplayClass
	GOTO	ObjCallSuperNoLock

GenDisplayInitialize	endm

BuildUncommon	ends

;
;---------------
;
		
Build	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenDisplayBuild

DESCRIPTION:	Return the correct specific class for an object

PASS:	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenClass

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


GenDisplayBuild	method GenDisplayClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_DISPLAY
	GOTO	GenQueryUICallSpecificUI
GenDisplayBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDisplaySetUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add GenDisplay to application's GAGCNLT_WINDOW list, as
		GenDisplays are defined to be on-screen if set usable.
		This normally happens in the specific UI, but if the
		display is not fully usable, the specific won't get called,
		so we need to do it here.

CALLED BY:	MSG_GEN_SET_USABLE

PASS:		*ds:si	= GenDisplayClass object
		ds:di	= GenDisplayClass instance data
		es 	= segment of GenDisplayClass
		ax	= MSG_GEN_SET_USABLE

		dl	= VisUpdateMode

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/25/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenDisplaySetUsable	method	dynamic	GenDisplayClass, MSG_GEN_SET_USABLE
	;
	; add to application's GAGCNLT_WINDOWS list
	;
	push	ax, dx, si			; save message, VUM, obj
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_WINDOWS or \
						mask GCNLTF_SAVE_TO_STATE
	mov	ax, MSG_META_GCN_LIST_ADD
	clr	bx				; use current thread
	call	GeodeGetAppObject		; ^lbx:si = app object
	tst	bx				; any?
	jz	noAppObj
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
noAppObj:
	add	sp, size GCNListParams
	pop	ax, dx, si			; restore message, VUM, obj
	;
	; then call superclass for normal handling
	;
	mov	di, offset GenDisplayClass
	GOTO	ObjCallSuperNoLock

GenDisplaySetUsable	endm

Build ends

;--------

LessCommon segment resource



GenDisplayDummy	method	GenDisplayClass, MSG_GEN_GUP_INTERACTION_COMMAND
	stc
	ret			; Do NOTHING but stop GUP.
GenDisplayDummy endm

LessCommon	ends

;
;---------------
;
		
WindowFiddle	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplaySetMaximized

DESCRIPTION:	Maximize the GenDisplay.  Tells GenDisplayGroup to maximize
		all GenDisplays (full-sized mode).

PASS:	*ds:si	= instance data for object
	es - segment of GenDisplayClass

	ax - MSG_GEN_DISPLAY_SET_MAXIMIZED

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

GenDisplaySetMaximized	method	GenDisplayClass, MSG_GEN_DISPLAY_SET_MAXIMIZED
	;
	; Check if parent GenDisplayGroup is already maximized
	;
EC <	call	EnsureParentIsDisplayControl				>
	mov	ax, MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED
	call	GenCallParent		; carry set if maximized
	jc	done			;skip if already maximized...
	;
	; Else, tell parent GenDisplayGroup to maximize (go into full-sized
	; mode).  No state saving or state checking at GenDisplay level.
	; DisplayControl handles if not full-size-able.
	;
	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED
	call	GenCallParent
done:
	ret
GenDisplaySetMaximized	endm

if ERROR_CHECK
EnsureParentIsDisplayControl	proc	far
	push	si				; save GenDisplay chunk
	call	GenSwapLockParent		; *ds:si = parent
						; bx = GenDisplay handle
	ERROR_NC	UI_GEN_DISPLAY_PARENT_NOT_GEN_DISPLAY_GROUP
	push	es, di
	mov	di, segment GenDisplayGroupClass
	mov	es, di
	mov	di, offset GenDisplayGroupClass
	call	ObjIsObjectInClass
	pop	es, di
	ERROR_NC	UI_GEN_DISPLAY_PARENT_NOT_GEN_DISPLAY_GROUP
	call	ObjSwapUnlock
	pop	si
	ret
EnsureParentIsDisplayControl	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplaySetNotMaximized

DESCRIPTION:	Unmaximize the GenDisplay.  Tells GenDisplayGroup to
		unmaximize all GenDisplays (overlapping mode).

PASS:	*ds:si	= instance data for object
	es - segment of GenDisplayClass

	ax - MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED

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

GenDisplaySetNotMaximized	method	GenDisplayClass, \
					MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED
	;
	; Check if parent GenDisplayGroup is already unmaximized
	;
EC <	call	EnsureParentIsDisplayControl				>
	mov	ax, MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED
	call	GenCallParent		; carry set if maximized
	jnc	done			; skip if already unmaximized
	;
	; Then, tell parent GenDisplayGroup to unmaximize (go into
	; overlapping mode).  No state saving or state checking at GenDisplay
	; level.  DisplayControl handles if not overlapping-able.
	;
	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING
	call	GenCallParent
done:
	ret
GenDisplaySetNotMaximized	endm

WindowFiddle	ends

;
;---------------
;
		
LessCommon	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplayGetMaximized

DESCRIPTION:	Get maximized mode of GenDisplay.  Checks full-sized/
		overlapping mode of GenDisplayGroup.

PASS:	*ds:si	= instance data for object
	es - segment of GenDisplayClass

	ax - MSG_GEN_DISPLAY_GET_MAXIMIZED

RETURN:	carry set if maximized

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/5/92		initial version

------------------------------------------------------------------------------@

GenDisplayGetMaximized	method	GenDisplayClass, MSG_GEN_DISPLAY_GET_MAXIMIZED
	;
	; Check mode of parent GenDisplayGroup
	;
EC <	call	EnsureParentIsDisplayControl				>
	mov	ax, MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED
	call	GenCallParent		; carry set if maximized
	ret
GenDisplayGetMaximized	endm

LessCommon	ends

;
;---------------
;
		
WindowFiddle	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplayInternalSetFullSized

DESCRIPTION:	Sent from the GenDisplayGroup when it is made full-sized.

PASS:	*ds:si	= instance data for object
	es - segment of GenDisplayClass

	ax - MSG_GEN_DISPLAY_INTERNAL_SET_FULL_SIZED

	dl - VisUpdateMode

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/6/92		initial version

------------------------------------------------------------------------------@

GenDisplayInternalSetFullSized	method	GenDisplayClass,
					MSG_GEN_DISPLAY_INTERNAL_SET_FULL_SIZED
	;
	; Let spui handle if built.  Do nothing if not built.  Correct state
	; will be used when built.  Display Control won't send this if it is
	; not full-size-able.
	;
	clr	cx				; allow optimized check
	call	GenCheckIfFullyUsable		; if not fully usable, bail
	jnc	done
	call	GenCallSpecIfGrown		; let spui do the actual work
done:
	ret
GenDisplayInternalSetFullSized	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplayInternalSetOverlapping

DESCRIPTION:	Sent from the GenDisplayGroup when it is made overlapping.

PASS:	*ds:si	= instance data for object
	es - segment of GenDisplayClass

	ax - MSG_GEN_DISPLAY_INTERNAL_SET_OVERLAPPING

	dl - VisUpdateMode

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/6/92		initial version

------------------------------------------------------------------------------@

GenDisplayInternalSetOverlapping	method	GenDisplayClass, \
				MSG_GEN_DISPLAY_INTERNAL_SET_OVERLAPPING
	;
	; Let spui handle if built.  Do nothing if not built.  Correct state
	; will be used when built.  DisplayControl won't send this if it is
	; not overlapping-able
	;
	clr	cx				; allow optimized check
	call	GenCheckIfFullyUsable		; if not fully usable, bail
	jnc	done
	call	GenCallSpecIfGrown		; let spui do the actual work
done:
	ret
GenDisplayInternalSetOverlapping	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplaySetMinimized

DESCRIPTION:	Minimize the GenDisplay.

PASS:	*ds:si	= instance data for object
	es - segment of GenDisplayClass

	ax - MSG_GEN_DISPLAY_SET_MINIMIZED

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

GenDisplaySetMinimized	method	GenDisplayClass, MSG_GEN_DISPLAY_SET_MINIMIZED
	;
	; If not minimizable, ignore.
	;
	mov	ax, ATTR_GEN_DISPLAY_NOT_MINIMIZABLE
	call	ObjVarFindData			; carry set if found
	jc	done				; cannot minimize, ignore
	;
	; Check if already minimized, if not set minimized flag and let
	; spui minimize.
	;
	mov	ax, ATTR_GEN_DISPLAY_MINIMIZED_STATE or mask VDF_SAVE_TO_STATE
	call	ObjVarFindData			; carry set if found
	jc	done				; already minimized
	clr	cx
	call	ObjVarAddData			; else, add minimized flag

	clr	cx				; allow optimized check
	call	GenCheckIfFullyUsable		; if not fully usable, bail
	jnc	done

	mov	ax, MSG_GEN_DISPLAY_SET_MINIMIZED
	call	GenCallSpecIfGrown		; let spui do the actual work
done:
	ret
GenDisplaySetMinimized	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplaySetNotMinimized

DESCRIPTION:	Unminimize the GenDisplay.

PASS:	*ds:si	= instance data for object
	es - segment of GenDisplayClass

	ax - MSG_GEN_DISPLAY_SET_NOT_MINIMIZED

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

GenDisplaySetNotMinimized	method	GenDisplayClass, \
					MSG_GEN_DISPLAY_SET_NOT_MINIMIZED
	;
	; If not restorable, ignore.
	;
	mov	ax, ATTR_GEN_DISPLAY_NOT_RESTORABLE
	call	ObjVarFindData			; carry set if found
	jc	done				; cannot restore, ignore
	;
	; Check if already not minimized, if not, clear minimized flag and let
	; spui unminimized.
	;
	mov	ax, ATTR_GEN_DISPLAY_MINIMIZED_STATE
	call	ObjVarDeleteData	; carry clear if found and deleted
					;	(marks dirty if deleted)
	jc	done			; not found -> already unminimized

	clr	cx				; allow optimized check
	call	GenCheckIfFullyUsable	; if not fully usable, bail
	jnc	done

	mov	ax, MSG_GEN_DISPLAY_SET_NOT_MINIMIZED
	call	GenCallSpecIfGrown	; let spui do the actual work
done:
	ret
GenDisplaySetNotMinimized	endm

WindowFiddle	ends

;
;---------------
;
		
GetUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplayGetMinimized

DESCRIPTION:	Get minimized mode of GenDisplay.

PASS:	*ds:si	= instance data for object
	es - segment of GenDisplayClass

	ax - MSG_GEN_DISPLAY_GET_MINIMIZED

RETURN:	carry set if minimized

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/5/92		initial version

------------------------------------------------------------------------------@

GenDisplayGetMinimized	method	GenDisplayClass, MSG_GEN_DISPLAY_GET_MINIMIZED
	;
	; Check minimized-mode storage attr
	;
	mov	ax, ATTR_GEN_DISPLAY_MINIMIZED_STATE
	call	ObjVarFindData		; carry set if found
	ret
GenDisplayGetMinimized	endm

GetUncommon	ends

;
;---------------
;
		
BuildUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplaySetAttrs

DESCRIPTION:	Set GenDisplayAttrs.

PASS:	*ds:si - instance data for object
	es - segment of GenDisplayClass

	ax - MSG_GEN_DISPLAY_SET_ATTRS

	cl - GenDisplayAttrs

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/16/92		initial version

------------------------------------------------------------------------------@

GenDisplaySetAttrs	method	GenDisplayClass, MSG_GEN_DISPLAY_SET_ATTRS
EC <	test	cl, not mask GenDisplayAttrs				>
EC <	ERROR_NZ	UI_GEN_DISPLAY_BAD_ATTRS			>

	mov	bx, offset GDI_attributes
	GOTO	GenSetByte
GenDisplaySetAttrs	endm

BuildUncommon	ends

;
;---------------
;
		
GetUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDisplayGetAttrs

DESCRIPTION:	Get GenDisplayAttrs.

PASS:	*ds:si - instance data for object
	es - segment of GenDisplayGroupClass

	ax - MSG_GEN_DISPLAY_GET_ATTRS

RETURN:	cl - GenDisplayAttrs

ALLOWED TO DESTROY:
	ax, ch, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/16/92		initial version

------------------------------------------------------------------------------@

GenDisplayGetAttrs	method	GenDisplayClass, MSG_GEN_DISPLAY_GET_ATTRS
	mov	cl, ds:[di].GDI_attributes
	ret
GenDisplayGetAttrs	endm

GetUncommon ends
