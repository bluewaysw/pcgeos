COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genClassCommon.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenClass		Gen UI object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of genClass.asm

DESCRIPTION:
	This file contains routines to implement the Gen class

	$Id: genClassCommon.asm,v 1.1 97/04/07 11:45:37 newdeal Exp $

------------------------------------------------------------------------------@
Common	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	MSG_GEN_ACTIVATE_INTERACTION_DEFAULT
		MSG_GEN_NAVIGATE_TO_NEXT_FIELD
		MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
		MSG_GEN_NAVIGATION_QUERY

DESCRIPTION:	This GenClass handlers simply convert the above
		GEN methods into their SPEC counterparts, and sends the
		method back to this object. This is in anticipation that
		the SPEC method will climb the visible tree (see visClass.asm).

PASS:	*ds:si	= instance data for object

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

GenGenActivateInteractionDefault	method	GenClass, \
				MSG_GEN_ACTIVATE_INTERACTION_DEFAULT
	mov	ax, MSG_SPEC_ACTIVATE_INTERACTION_DEFAULT
	GOTO	ObjCallInstanceNoLock
GenGenActivateInteractionDefault	endm


GenGenBroadcastForDefaultFocus	method	GenClass, \
				MSG_GEN_START_BROADCAST_FOR_DEFAULT_FOCUS
	mov	ax, MSG_SPEC_START_BROADCAST_FOR_DEFAULT_FOCUS
	GOTO	ObjCallInstanceNoLock
GenGenBroadcastForDefaultFocus	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenSetUsable -- MSG_GEN_SET_USABLE

DESCRIPTION:	A general-purpose methods for setting objects as "USABLE".
		Objects which are not USABLE will not appear as part of the
		interface for an application.  Objects may be set USABLE only
		after they are attached to the system-wide generic tree, at
		which point the object becomes part of the interface for the
		application.  If the window on which the object lies is
		realized, the object will be visually built & updated.

		This is a very high-level function, for ALL generic objects
		except GenApplication, GenField, & GenSystem.  The latter
		three are controlled at the highest level using MSG_META_ATTACH
		& MSG_META_DETACH (MSG_GEN_SET_USABLE should NOT be sent
		to those objects, unless you are implementing MSG_META_ATTACH
		for them)

 This method DOES force the specific building of the object, but ONLY in the
 case that all generic parents up the tree are also marked as USABLE.

WHO CAN USE:	Application, Specific UI only for gen objects it creates.


PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_SET_USABLE
	dl - VisUpdateMode

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/89		Initial version
	Doug	6/89		Merged w/visible update

------------------------------------------------------------------------------@


GenGenSetUsable	method	GenClass, MSG_GEN_SET_USABLE
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>

if	ERROR_CHECK
				; Test to make sure that this object
				; is generically attached to something
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GI_link.LP_next.handle
					; If link is 0, then it is not.
	ERROR_Z	UI_ERROR_CAN_NOT_SET_USABLE_IF_NOT_IN_GEN_COMPOSITE
endif
				; If already usable, quit
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jnz	GGSU_90

				; Show state change
	mov	bx, mask GS_USABLE
	call	SetStateCommon

				; IF this object is now fully USABLE, then
				; send specific method on to notify
				; of this change in circumstances.

	mov	cx, -1		; no optimizations
	call	GenCheckIfFullyUsable
	jnc	GGSU_90

				; IF object is going from NOT_USABLE to
				; FULLY USABLE, first shrink back to just
				; generic instance data, to make sure we're
				; not carrying forward any specific or visible
				; data from this point on.
	call	GenSpecShrinkBranch

				; Call visible method to make usable.
				; This WILL force a specific building of
				; the object, & therefore a GenSpecGrowParents
				; call, which will keep consistent our
				; concept of keeping strings of USABLE,
				; specifically grown branches, in order to
				; cut down the work in the above
				; GenSpecShrinkBranch.

				; If specific UI allows, the object will
				; come up on screen.

	mov	ax, MSG_SPEC_SET_USABLE
	GOTO	ObjCallInstanceNoLock

GGSU_90:
	ret

GenGenSetUsable	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenSetNotUsable -- MSG_GEN_SET_NOT_USABLE

DESCRIPTION:	Set object as being not usable.  If hooked into generic tree
		that is visualized, will have to be visually unbuilt & updated

		This is a very high-level function, for ALL generic objects
		except GenApplication, GenField, & GenSystem.  The latter
		three are controlled at the highest level using MSG_META_ATTACH
		& MSG_META_DETACH (MSG_GEN_SET_NOT_USABLE should NOT be sent
		to those objects, unless you are implementing part of
		MSG_META_DETACH for them)

 This method DOES force the specific building of the object, but ONLY in the
 case that the object & all generic parents up the tree were marked as
 USABLE before this method call (i.e. the object was FULLY USABLE).

WHO CAN USE:	Application, Specific UI only for gen objects it creates.
		The single exception is for the Application object, which
		the specific UI controls with this routine

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_SET_NOT_USABLE
	dl - VisUpdateMode (VUM_MANUAL NOT ALLOWED)

 VUM_MANUAL has been outlawed with a FATAL_ERROR for the same reason that there
 is a warning in MSG_GEN_UPDATE_VISUAL about needing to send a
 MSG_GEN_UPDATE_VISUAL to EVERY generic object you've marked as needing
 visual updating via VUM_MANUAL.  The problem is this:
 An application should make no assumption
 about the visual construction of a generic tree; in other words, if you
 mark two triggers as IMAGE_INVALID, you shouldn't assume that you can
 just update the display that they are on, since the buttons may visually
 be placed on some window other than the display.  This problem is solved
 by having the MSG_GEN_UPDATE_VISUAL, since the specific UI can implement
 this method by invalidating all visual aspects of the object wherever
 (as in whatever window they're in) they may be.  Whew!

 So, how does this relate to VUM_MANUAL & MSG_GEN_SET_NOT_USABLE?  Well,
 when an object is marked not usable, it is visually torn down, & may actually
 have the visible instance data discarded.  In this state,
 MSG_GEN_UPDATE_VISUAL does nothing, since the object isn't specifically built.
 
 How to get around this?  I'd recommend using one of the
 VUM_DELAYED_VIA_??_QUEUE modes for these calls, if you're trying to avoid
 flickering of your display in bringing down UI components.  Note that
 calling multiple MSG_GEN_SET_NOT_USABLE's w/ a DELAYED update mode only
 generates one method which goes through the queue to perform the udpate later.
 
RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/89		Initial version
	Doug	6/89		Merged w/visible update

------------------------------------------------------------------------------@


GenGenSetNotUsable	method	GenClass, MSG_GEN_SET_NOT_USABLE
EC <	cmp	dl, VUM_MANUAL						>
EC <	ERROR_Z	UI_VUM_MANUAL_NOT_ALLOWED_FOR_GEN_SET_NOT_USABLE	>

EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>

				; If already unusable, quit
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jz	GGSNU_90

				; Fetch flag which will indicate if object
				; was fully USABLE at the time of its being
				; set NOT_USABLE.
	mov	cx, -1		; no optimizations
	call	GenCheckIfFullyUsable
	pushf			; save that flag


				; Show state change
	mov	bx, mask GS_USABLE shl 8
	call	SetStateCommon

	popf			; Get flag saying whether was fully usable
				; before or not.
	jnc	GGSNU_90	; If was not fully usable before, then we don't
				; need to send out notification of loss
				; of USABILITY.

	call	GenCheckIfSpecGrown
	jnc	GGSNU_90	; if not grown yet, don't bother unbuilding

				; Send visible method to make sure this thing
				; is shut down visually.  Will do visual
				; "unbuild", closing windows, etc.  Will use
				; visual update mode passed on visual parent
	mov	ax, MSG_SPEC_SET_NOT_USABLE
	GOTO	ObjCallInstanceNoLock


GGSNU_90:
	ret

GenGenSetNotUsable	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenGenUpdateVisual -- MSG_GEN_UPDATE_VISUAL

DESCRIPTION:	Performs a visual update on the generic object (which updates
		the WIN_GROUP on which it visual appears -- may be more than
		one WIN_GROUP)

 This method is guaranteed NOT to force the specific building of any object.

WHO CAN USE:	Application, Specific UI only for gen objects it creates.


PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_UPDATE_VISUAL
	dl - VisUpdateMode

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/89		Initial version

------------------------------------------------------------------------------@


GenGenUpdateVisual	method	GenClass, MSG_GEN_UPDATE_VISUAL
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>

	call	GenCheckIfSpecGrown
	jnc	done
				; Call visible method to do this operation.
				; Specific UI should replace if needs 
				; special attention.

	mov	ax, MSG_SPEC_UPDATE_VISUAL
	GOTO	ObjCallInstanceNoLock
done:
	ret

GenGenUpdateVisual	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenGenSetEnabled
METHOD:		GenGenSetNotEnabled
					 GenClass

		These are the method versions of UserSetEnabled, etc.  They
	are invoked automatically if the state has been changed for an
	object (via UserSetEnabled, etc.) when the object block containing
	the object is loaded in.  These methods may be called directly,
	though they will force in the object block if it is not already in.
	Generally, you should use the UserSet* versions when possible.

		Changing the active flag changes whether or not the user
	may interact & with & use the object.  In the case of a GenTrigger,
	making it inactive will prevent it from being triggered, & will
	typically also prevent it from being depressed.

 This method is guaranteed NOT to force the specific building of any object.

WHO CAN USE:	Application, Specific UI

DESCRIPTION:	Mark a generic object as ...

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_SET_ENABLED/MSG_GEN_SET_NOT_ENABLED

	dl - VisUpdateMode

RETURN: nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Doug	6/89		More doc.

------------------------------------------------------------------------------@

GenGenSetEnabled	method	GenClass, MSG_GEN_SET_ENABLED
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>

				; If already enabled, quit
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_ENABLED
	jnz	GGSE_90

	mov	ax, MSG_GEN_NOTIFY_ENABLED
	mov	bx, mask GS_ENABLED
	GOTO	EnableCommon

GGSE_90:
	ret

GenGenSetEnabled	endm

GenGenSetNotEnabled	method	GenClass, MSG_GEN_SET_NOT_ENABLED
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>

				; If already NOT enabled, quit
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_ENABLED
	jz	GGSNE_90

	mov	ax, MSG_GEN_NOTIFY_NOT_ENABLED
	mov	bx, mask GS_ENABLED shl 8
	GOTO	EnableCommon

GGSNE_90:
	ret

GenGenSetNotEnabled	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	EnableCommon

DESCRIPTION:	

 This method is guaranteed NOT to force the specific building of any object.

CALLED BY:	INTERNAL

PASS:
	*ds:si	- object
	dl 	- VisUpdateMode
	ax	- specific method to send to children to update their fully
		  enabled state

RETURN:	
	nothing

DESTROYED:
	ax, bx, cx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	?		?

------------------------------------------------------------------------------@


EnableCommon	proc	far
	class	GenClass		; Tell Esp we're a friend of GenClass
					; so we can play with instance data

EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>
	;
	; Set the enabled state.
	;
	call	SetStateCommon
					; if not fully usable, quit here
	clr	cx			; Allow optimizations, as this is a
					; steady state scenerio, at least
					; as far as usability is concerned.
	call	GenCheckIfFullyUsable
	jnc	exit
					; See if specifically built yet
	call	GenCheckIfSpecGrown
	jnc	exit			; if not, quit here
	
	;
	; Send a notify method to ourselves, which will typically trickle
	; down through the generic children, updating the VA_FULLY_ENABLED
	; bit and drawing accordingly.  Specific UI's should subclass those
	; methods.
	;
	mov	dh, mask NEF_STATE_CHANGING
	jmp	ObjGotoInstanceTailRecurse	; send to ourselves
						; This works since the
						; message handlers goto here
exit:
	ret

EnableCommon	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenNotifyEnabled

DESCRIPTION:	Figures out whether it should calculate the visual fully-
		invalid bit for this object.  Does not force building of
		specific parts.

		Note:  This handler sends a MSG_SPEC_NOTIFY method to
		itself, then recurses on the children.  Objects can depend
		on the parent being disabled first.
		
PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_NOTIFY_ENABLED

 		dl -- update mode
		dh -- NotifyEnabledFlags

RETURN:		carry set if visual state changed

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/11/90		Initial version

------------------------------------------------------------------------------@

GenNotifyEnabled	method GenClass, MSG_GEN_NOTIFY_ENABLED
	mov	cx, MSG_SPEC_NOTIFY_ENABLED
	GOTO	NotifyEnabledCommon
GenNotifyEnabled	endm
			
GenNotifyNotEnabled	method GenClass, MSG_GEN_NOTIFY_NOT_ENABLED
	mov	cx, MSG_SPEC_NOTIFY_NOT_ENABLED
	FALL_THRU NotifyEnabledCommon
GenNotifyNotEnabled	endm
			
			
NotifyEnabledCommon		proc	far
	class	GenClass

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jz	exit			;skip if usable...
	
	mov	di, ds:[si]		; Specifically built yet?
	tst	ds:[di].Vis_offset
	je	exit			; if not, quit here.

	mov	di, 700
	call	ThreadBorrowStackSpace
	push	di
					; Send to specific UI
	push	ax, dx
	mov	ax, cx			; Send specific method
	call	ObjCallInstanceNoLock
	DoPop	dx, ax
	jnc	done			; nothing much happened, exit
	
	and	dh, not mask NEF_STATE_CHANGING
	call	GenSendToChildren	; try sending to the children
	stc				; something interesting did happen
done:
	lahf
	pop	di
	call	ThreadReturnStackSpace
	sahf

exit:
	ret
NotifyEnabledCommon		endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetAndCalcCommon

DESCRIPTION:	

 This method is guaranteed NOT to force the specific building of any object.

CALLED BY:	INTERNAL

PASS:
	*ds:si	- object
	dl 	- VisUpdateMode
	ax	= METHOD

RETURN:

DESTROYED:	?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		A gift from doug. I added doc.

------------------------------------------------------------------------------@


if	(0)		; not used
;SetAndCalcCommon	proc	far
;	class	GenClass		; Tell Esp we're a friend of GenClass
;					; so we can play with instance data
;
;EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
;EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>
;
;				; First set state
;	call	SetStateCommon
;
;				; if not fully usable, quit here
;	clr	cx		; Allow optimized check.
;	call	GenCheckIfFullyUsable
;	jnc	SACC_quit
;				; See if specifically built yet
;	call	GenCheckIfSpecGrown
;	jnc	SACC_quit	; if not, quit here
;
;				; Send to specific UI
;	push	dx
;	mov	di, offset GenClass
;	call	ObjCallSuperNoLock
;	pop	dx
;	jc	SACC_quit	; if processed, we're all done, quit.
;
;;DefaultVisibleHandlingHere:
;
;SACC_quit:
;	ret
;
;SetAndCalcCommon	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetStateCommon

DESCRIPTION:	Common code for methods that change GI_states.  Set state
		based on set & reset flags passed.

 This method is guaranteed NOT to force the specific building of any object.

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	bl - bits to set
	bh - bits to reset

RETURN:

DESTROYED:
	bx, cx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

SetStateCommon	proc	near
	class	GenClass		; Tell Esp we're a friend of GenClass
					; so we can play with instance data

EC <	call	GenCheckGenAssumption	; Make sure gen data exists	>

	push	ax
	push	dx

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	mov	al, ds:[di].GI_states
	or	al, bl
	not	bh
	and	al, bh
	mov	ds:[di].GI_states, al

	;and mark dirty

	call	ObjMarkDirty

	pop	dx
	pop	ax
	ret

SetStateCommon	endp



COMMENT @----------------------------------------------------------------------

METHOD:		GenGenGetVisMoniker

DESCRIPTION:	Get a moniker from a generic object. Returns the chunk handle
		of the current visual moniker in use.

 This method is guaranteed NOT to force the specific building of any object.

WHO CAN USE:	Application, Specific UI

PASS:
	*ds:si - instance data
	es - segment of GenClass
	ax - MSG_GEN_GET_VIS_MONIKER

RETURN: ax - chunk handle of visMoniker

ALLOWED_TO_DESTROY:
	cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@


GenGenGetVisMoniker	method	GenClass, MSG_GEN_GET_VIS_MONIKER
EC <	call	GenCheckGenAssumption	; Make sure gen data exists	>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		; ds:di = GenInstance
	mov	ax, ds:[di].GI_visMoniker
	ret

GenGenGetVisMoniker	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenUseVisMoniker

DESCRIPTION:	Set a moniker for a generic object.  The chunk handle in
		the generic instance data is replaced with the new chunk
		handle.  Since it is only a chunk handle, the moniker must
		be in the same block as the object. NOTE! THE PASSED CHUNK MUST
		*NOT* BE A MONIKER LIST!

 This method is guaranteed NOT to force the specific building of any object.

WHO CAN USE:	Application, Specific UI

PASS:
	*ds:si - instance data
	es - segment of GenClass
	ax - MSG_GEN_USE_VIS_MONIKER

	cx - chunk handle of moniker to use (in same block as object)
	dl - VisUpdateMode

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

GenGenUseVisMoniker	method	GenClass, MSG_GEN_USE_VIS_MONIKER
EC <	call	GenCheckGenAssumption	; Make sure gen data exists	>

	; mark chunk as dirty

	call	ObjMarkDirty

	push	dx				;Save VisUpdateMode
	push	es				;Save idata segment
	push	cx				;Save new moniker chunk handle
	call	GenCheckIfSpecGrown
	jnc	common				;Returns carry if spec built
	segmov	es,ds,di			;ES <- object segment
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		; ds:di = GenInstance
	mov	di, ds:[di].GI_visMoniker	; *es:di <- vis moniker
	clr	bp				;No passed gstate
	clr	ax				;don't know text height
	call	VisGetMonikerSize		;Returns CX,DX <- width/height
	mov	bp,dx				;CX,BP <- width,height
common:
	mov	di,ds:[si]
	add	di,ds:[di].Gen_offset
	pop	ds:[di].GI_visMoniker		;Set new vis Moniker chunk
	pop	es				;Restore idata segment
	pop	dx				;Restore VisUpdateMode
	call	UpdateMoniker

; If anyone can ever remember why this was done, we'll add it back in :)
;
;	stc					; Return carry set (we handled
;						; this method)
	ret


GenGenUseVisMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If passed object is SpecBuilt, sends the SPEC_UPDATE_VIS_MONIKER
		method to object's superclass.

 This method is guaranteed NOT to force the specific building of any object.

CALLED BY:	GLOBAL
PASS:		dl - VisUpdateMode
		cx - width of old moniker (If vis built)
		bp - height of old moniker (If vis built)
		*DS:SI - gen object
		ES - segment of GenClass

RETURN:		nothing 

DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateMoniker	proc	near
	class	GenClass
					; See if this object has been
					; specifically built yet.  If not,
					; skip calling
					; specific UI & invalidation stuff -
					; this object can't be seen yet.

	mov	di, 1200
	call	ThreadBorrowStackSpace
	push	di

	call	GenCheckIfSpecGrown
	jnc	notbuilt		; Returns carry if visually built

	;
	; if new moniker is moniker list and if object is usable, resolve
	; moniker list
	;	*ds:si = object
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GI_visMoniker	; *ds:bx = VisMoniker
	tst	bx
	jz	spuiUpdate
	mov	ax, bx				; *ds:ax = VisMoniker

	mov	bx, ds:[bx]			; ds:bx = VisMoniker
	test	ds:[bx].VM_type, mask VMT_MONIKER_LIST	; moniker list?
	jz	spuiUpdate			; no, exit (carry clear)
	push	cx
	clr	cx				; allow optimized check, as
						; this is a steady-state
						; scenerio where usability is
						; concerned.
	call	GenCheckIfFullyUsable		; carry set if fully usable
	pop	cx
	jnc	notbuilt			; not usable, exit
						; (moniker list will be
						;  resolved when object built)
	push	cx, dx, bp			; save params
	mov	cx, ax				; *ds:cx = moniker list
	mov	ax, MSG_SPEC_RESOLVE_MONIKER_LIST
	call	ObjCallInstanceNoLock		; resolve in-place, if needed
						;	and spui desires
	pop	cx, dx, bp

;allow moniker lists past this point, specific UI dictates whether this is
;legal or not (e.g. GenApplication needs this) - brianc 4/3/92
;EC <	push	es							>
;EC <	segmov	es, ds, di						>
;EC <	mov	di,ds:[si]						>
;EC <	add	di,ds:[di].Gen_offset					>
;EC <	mov	di,ds:[di].GI_visMoniker				>
;EC <	call	CheckVisMoniker		;make sure is not moniker list! >
;EC <	pop	es							>

	; let out superclass (the specific UI) have a crack at it (update 
	; image/geometry.
spuiUpdate:
	mov	ax,MSG_SPEC_UPDATE_VIS_MONIKER
	mov	di,offset GenClass
	call	ObjCallSuperNoLock
notbuilt:

	pop	di
	call	ThreadReturnStackSpace

	ret
UpdateMoniker	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenCreateVisMoniker -- 
		MSG_GEN_CREATE_VIS_MONIKER for GenClass

DESCRIPTION:	Creates a vis moniker chunk in the object's resource block
		from various sources. For XIP'ed geode, if the CVMF_sourceType
		is VMST_FPTR, the fptr in CVMF_source must not point into
		the movable XIP code segment.

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_CREATE_VIS_MONIKER
		
		ss:bp	- CreateVisMonikerFrame
				CreateVisMonikerFrame	struct
					CVMF_source	dword
					CVMF_sourceType	VisMonikerSourceType
					CVMF_dataType	VisMonikerDataType
					CVMF_length	word
					CVMF_width	word
					CVMF_height	word
					CVMF_flags	CreateVisMonikerFlags
				CreateVisMonikerFrame	ends
		dx	- size CreateVisMonikerFrame

RETURN:		ax - chunk handle of new vis moniker
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@
GenCreateVisMoniker	method	dynamic	GenClass, MSG_GEN_CREATE_VIS_MONIKER
EC <	cmp	ss:[bp].CVMF_dataType, VMDT_TOKEN			>
EC <	ERROR_E	UI_ERROR_CREATE_VIS_MONIKER_CANNOT_USE_VMDT_TOKEN	>

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		cmp	ss:[bp].CVMF_sourceType, VMST_FPTR		>
EC <		jne	xipSafe						>
EC <		cmp	ss:[bp].CVMF_dataType, VMDT_NULL		>
EC <		je	xipSafe						>
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ss:[bp].CVMF_source			>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
EC < xipSafe:								>
endif
		
	clr	ax			; create new chunk
	call	VisCreateMonikerChunk	; no error possible b/c no VMDT_TOKEN
EC <	ERROR_C	UI_ERROR_CREATE_VIS_MONIKER_CANNOT_USE_VMDT_TOKEN	>
	ret
GenCreateVisMoniker	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenReplaceVisMoniker -- 
		MSG_GEN_REPLACE_VIS_MONIKER for GenClass

DESCRIPTION:	Replace object's current vis moniker. For XIP'ed geodes, if the
		RVMF_sourceType is VMST_FPTR, the fptr in RVMF_source must not
		point into the movable XIP code segment.

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_REPLACE_VIS_MONIKER
		
		ss:bp	- ReplaceVisMonikerFrame
				ReplaceVisMonikerFrame	struct
					RVMF_source	dword
					RVMF_sourceType	VisMonikerSourceType
					RVMF_dataType	VisMonikerDataType
					RVMF_length	word
					RVMF_width	word
					RVMF_height	word
					RVMF_updateMode	VisUpdateMode
				ReplaceVisMonikerFrame	ends
		dx	- size ReplaceVisMonikerFrame

RETURN:		ax - chunk handle of vis moniker
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@
GenReplaceVisMoniker	method	dynamic	GenClass, MSG_GEN_REPLACE_VIS_MONIKER

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		cmp	ss:[bp].RVMF_sourceType, VMST_FPTR		>
EC <		jne	xipSafe						>
EC <		cmp	ss:[bp].RVMF_dataType, VMDT_NULL		>
EC <		je	xipSafe						>
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ss:[bp].RVMF_source			>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
EC < xipSafe:								>
endif
		
	call	ObjMarkDirty
	;
	; handle freeing of current vis moniker
	;
	mov	dl, ss:[bp].RVMF_updateMode	; dl = VisUpdateMode
	cmp	ss:[bp].RVMF_dataType, VMDT_NULL
	jne	normalCreate
	;
	; free current moniker
	;	dl = VisUpdateMode
	;
freeCurrentMoniker:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GI_visMoniker	; get current moniker
	jcxz	done				; no current moniker, done
	push	cx				; else, save current moniker
	clr	cx
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	call	ObjCallInstanceNoLock		; set no moniker
	pop	ax
	call	ObjFreeChunk			; free old moniker
	jmp	short done

normalCreate:
	push	dx				; save VisUpdateMode
	call	ReplaceVisMonikerGetSize	; (bx, di) = (width, height)
	push	bx, di				; save for later
	;
	; we now pass ReplaceVisMonikerFrame as CreateVisMonikerFrame
	;	ss:bp = ReplaceVisMonikerFrame
	;
.assert (offset RVMF_source eq offset CVMF_source)
.assert (offset RVMF_sourceType eq offset CVMF_sourceType)
.assert (offset RVMF_dataType eq offset CVMF_dataType)
.assert (offset RVMF_length eq offset CVMF_length)
.assert (offset RVMF_width eq offset CVMF_width)
.assert (offset RVMF_height eq offset CVMF_height)
.assert (offset RVMF_updateMode eq offset CVMF_flags)
.assert (size ReplaceVisMonikerFrame eq size CreateVisMonikerFrame)
.assert (size RVMF_updateMode eq size CVMF_flags)
	mov	ss:[bp].CVMF_flags, mask CVMF_DIRTY	; mark new chunk dirty
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GI_visMoniker	; replace current vis moniker
	push	ax				; save for later
	call	VisCreateMonikerChunk		; ax = vis moniker chunk
	pop	bx				; bx = previous vis moniker
	pop	cx, bp				; (cx, bp) = (width, height)
	pop	dx				; dl = VisUpdateMode
	jc	freeCurrentMoniker		; VMDT_TOKEN and token not
						;	found, free current
						;	moniker (b/c it is now
						;	bogus)
	tst	bx				; any previous vis moniker?
	jz	setNewMoniker			; no, use new moniker
	;
	; replace existing moniker, update
	;	ax = vis moniker chunk
	;	cx, bp = old moniker's dimensions
	;	dl = VisUpdateMode
	;
	call	UpdateMoniker			; else, update
	jmp	short done
	;
	; moniker didn't exist previously, just set the new moniker
	;	ax = new moniker chunk
	;	dl = VisUpdateMode
	;
setNewMoniker:
	;
	; mirror this object's OCF_IGNORE_DIRTY flag in the new moniker chunk
	; (it is also marked as OCF_DIRTY and ~OCF_IGNORE_DIRTY by
	;  VisCreateMonikerChunk)
	;	*ds:ax = new vis moniker chunk
	;
	push	ax				; save new moniker chunk
	mov	cx, ax				; cx = new moniker chunk
	mov	ax, si				; *ds:ax = this object
	call	ObjGetFlags			; al = flags, ah = 0
	test	al, mask OCF_IGNORE_DIRTY	; ignore-dirty?
	jz	notIgnoreDirty
	mov	ax, cx				; *ds:ax = moniker chunk
	mov	bx, mask OCF_IGNORE_DIRTY	; set this, clear nothing
	call	ObjSetFlags
notIgnoreDirty:
	mov	ax, MSG_GEN_USE_VIS_MONIKER	; does update
	call	ObjCallInstanceNoLock
	pop	ax				; return new moniker chunk
done:
	ret
GenReplaceVisMoniker	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenReplaceVisMonikerOptr -- 
		MSG_GEN_REPLACE_VIS_MONIKER_OPTR for GenClass

DESCRIPTION:	Replace object's current vis moniker with VisMoniker referenced
		by optr.

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		
		^lcx:dx	- source VisMoniker
		bp	- VisUpdateMode

RETURN:		ax - chunk handle of vis moniker
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@
GenReplaceVisMonikerOptr	method	dynamic	GenClass, \
					MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	ax, bp				; al = VisUpdateMode
	sub	sp, size ReplaceVisMonikerFrame
	mov	bp, sp
	mov	ss:[bp].RVMF_updateMode, al
	mov	ss:[bp].RVMF_source.handle, cx
	mov	ss:[bp].RVMF_source.chunk, dx
	mov	ss:[bp].RVMF_sourceType, VMST_OPTR
	mov	ss:[bp].RVMF_dataType, VMDT_VIS_MONIKER
	mov	dx, size ReplaceVisMonikerFrame
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	call	ObjCallInstanceNoLock
	add	sp, size ReplaceVisMonikerFrame
	ret
GenReplaceVisMonikerOptr	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenReplaceVisMonikerText -- 
		MSG_GEN_REPLACE_VIS_MONIKER_TEXT for GenClass

DESCRIPTION:	Replace object's current vis moniker with VisMoniker referenced
		by fptr. 

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		
		cx:dx	- ptr to null-terminated string
		(cx:dx *cannot* be pointing into the movable XIP code resource.)
		bp	- VisUpdateMode

RETURN:		ax - chunk handle of vis moniker
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@
GenReplaceVisMonikerText	method	dynamic	GenClass, \
				MSG_GEN_REPLACE_VIS_MONIKER_TEXT
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	mov	ax, bp				; al = VisUpdateMode
	sub	sp, size ReplaceVisMonikerFrame
	mov	bp, sp
	mov	ss:[bp].RVMF_updateMode, al
	mov	ss:[bp].RVMF_source.segment, cx
	mov	ss:[bp].RVMF_source.offset, dx
	mov	ss:[bp].RVMF_sourceType, VMST_FPTR
	mov	ss:[bp].RVMF_dataType, VMDT_TEXT
	mov	ss:[bp].RVMF_length, 0
	mov	dx, size ReplaceVisMonikerFrame
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	call	ObjCallInstanceNoLock
	add	sp, size ReplaceVisMonikerFrame
	ret
GenReplaceVisMonikerText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceVisMonikerGetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get size of current moniker, if any.

CALLED BY:	INTERNAL
			GenReplaceVisMoniker
PASS:		*ds:si - object
RETURN:		bx, di - width, height
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/29/90		Initial version
	brianc	3/23/92		tweaked for new MSG_GEN_REPLACE_VIS_MONIKER

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceVisMonikerGetSize	proc	near
	class	GenClass

	uses	ax, cx, dx, es, bp
	.enter

	clr	cx
	clr	dx
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	mov	bx, ds:[bx].GI_visMoniker
	tst	bx				; no vis moniker, use 0, 0
	jz	done
	mov	ax, bx				; *ds:ax = VisMoniker
	mov	bx, ds:[bx]			; ds:bx = VisMoniker
	test	ds:[bx].VM_type, mask VMT_MONIKER_LIST
	jnz	done				; moniker list, use 0, 0
	mov	cx, ds:[bx].VM_width		; cx = width
	test	ds:[bx].VM_type, mask VMT_GSTRING	; gstring?
	jz	done				; no, just use width
	mov	dx, ({VisMonikerGString} ds:[bx].VM_data).VMGS_height
	call	GenCheckIfSpecGrown		; if not built, use cached size
	jnc	done
	segmov	es, ds, di			; *es:di = VisMoniker
	mov	di, ax
	clr	bp				; no passed GState
	clr	ax				; text  height unknown
	call	VisGetMonikerSize		; (cx, dx) = (w, h)
done:
	mov	bx, cx				; bx = width
	mov	di, dx				; di = height
	.leave
	ret
ReplaceVisMonikerGetSize	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenDrawMoniker -- 
		MSG_GEN_DRAW_MONIKER for GenClass

DESCRIPTION:	Draws a moniker.  Assembly language types should use the
		library routine GenDrawMoniker for speed.

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_DRAW_MONIKER
		ss:bp   - GenMonikerMessageFrame
		dx	- size GenMonikerMessageFrame

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/5/91		Initial version

------------------------------------------------------------------------------@
GenGenDrawMoniker	method dynamic	GenClass, MSG_GEN_DRAW_MONIKER
	CheckHack <GMMF_yInset eq DMA_yInset>
	CheckHack <GMMF_xInset eq DMA_xInset>
	CheckHack <GMMF_xMaximum eq DMA_xMaximum>
	CheckHack <GMMF_yMaximum eq DMA_yMaximum>
	CheckHack <GMMF_gState eq DMA_gState>
	CheckHack <GMMF_textHeight eq DMA_textHeight>
	
	mov	cl, ss:[bp].GMMF_monikerFlags	; moniker flags in cx
	call	GenDrawMoniker
	Destroy	ax, cx, dx, bp
	ret
GenGenDrawMoniker	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenGetMonikerPos -- 
		MSG_GEN_GET_MONIKER_POS for GenClass

DESCRIPTION:	Gets the position where the moniker would be drawn.

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_GET_MONIKER_POS
		ss:bp   - GenMonikerMessageFrame
		dx	- size GenMonikerMessageFrame

RETURN:		ax, bp - x and y origin for moniker
		cx, dx - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/5/91		Initial version

------------------------------------------------------------------------------@

GenGenGetMonikerPos	method dynamic	GenClass, MSG_GEN_GET_MONIKER_POS
	CheckHack <GMMF_yInset eq DMA_yInset>
	CheckHack <GMMF_xInset eq DMA_xInset>
	CheckHack <GMMF_xMaximum eq DMA_xMaximum>
	CheckHack <GMMF_yMaximum eq DMA_yMaximum>
	CheckHack <GMMF_gState eq DMA_gState>
	CheckHack <GMMF_textHeight eq DMA_textHeight>
	
	
	mov	cl, ss:[bp].GMMF_monikerFlags	; moniker flags in cx
	call	GenGetMonikerPos		; ax, bx = position
	mov	bp, bx				; ax, bp = position
	Destroy	cx, dx
	ret
GenGenGetMonikerPos	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenGetMonikerSize -- 
		MSG_GEN_GET_MONIKER_SIZE for GenClass

DESCRIPTION:	Gets the size of the moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_GET_MONIKER_SIZE
		
		dx	- height of system text, if known, else pass 0
				(allows speed optimization)
		bp	- gstate to use

RETURN:		cx - width of moniker
		dx - height of moniker
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/5/91		Initial version

------------------------------------------------------------------------------@
GenGenGetMonikerSize	method dynamic	GenClass, MSG_GEN_GET_MONIKER_SIZE
	mov	ax, dx				; height of system text
	call	GenGetMonikerSize		; returns cx, dx - size
	Destroy	ax, bp
	ret
GenGenGetMonikerSize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenFindMoniker -- 
		MSG_GEN_FIND_MONIKER for GenClass

DESCRIPTION:	Find the specified moniker (or most approriate moniker) in
		this object's VisMonikerList, and optionally copy the Moniker
		into this generic object's block, OR replace the VisMonikerList
		with the moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_FIND_MONIKER
		
		dx - non-zero to use GenApplication's MonikerList
		bp - VisMonikerSearchFlags (see visClass.asm)
			flags indicating what type of moniker to find
			in the VisMonikerList, and what to do with
			the Moniker when it is found.
		cx - handle of destination block (if bp contains
			VMSF_COPY_CHUNK command)

RETURN:		^lcx:dx - VisMoniker (^lcx:dx = NIL if none)
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/5/91		Initial version

------------------------------------------------------------------------------@
GenGenFindMoniker	method dynamic	GenClass, MSG_GEN_FIND_MONIKER
	tst	dx
	jz	dontUseAppMonikerList		; zero -> carry clear
	stc					; else, use app moniker list
dontUseAppMonikerList:
	call	GenFindMoniker			; ^lcx:dx - VisMoniker
	Destroy	ax, bp
	ret
GenGenFindMoniker	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenFindKbdAccelerator

DESCRIPTION:	Figures out if the keyboard data passed matches the keyboard
		moniker for this object or one of its children.

PASS:	*ds:si 	- instance data
	es     	- segment of GenClass
	ax 	- MSG_GEN_FIND_KBD_ACCELERATOR

	same as MSG_META_KBD_CHAR:
		cl - Character		(Chars or VChar)
		ch - CharacterSet	(CS_BSW or CS_CONTROL)
		dl - CharFlags
		dh - ShiftState		(left from conversion)
		bp low - ToggleState
		bp high - scan code

RETURN:	carry set if accelerator found and dealt with

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/12/90		Initial version

------------------------------------------------------------------------------@

GenFindKbdAccelerator	method GenClass, MSG_GEN_FIND_KBD_ACCELERATOR

	; Before we go testing the ENABLED bit, let's make sure the application
	; (or controller, as the case may be) has it set correctly.
	;
	call	ObjIncInteractibleCount

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GI_states, mask GS_USABLE
	jz	exit				;get out if not usable,carry clr

	; Call superclass before checking enabled bit.  Allows specific UI to
	; beep or do something if accelerator matches a disabled object.
	;	
	mov	di, offset GenClass		;check for specific UI methods
	push	cx, dx, bp
	call	ObjCallSuperNoLock		;   first
	pop	cx, dx, bp
	jc	exit				;something found, exit
	
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_ENABLED
	jz	exit				;get out if disabled, carry clr

	call	GenCheckKbdAccelerator		;check kbd accelerator
	jnc	tryChildren			;nothing found, exit

	;
	; Found the shortcut.  Send a MSG_GEN_ACTIVATE to ourselves.  Force
	; to queue, at front, just to help decrease the stack depth in this
	; situation.
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_GEN_ACTIVATE
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage	

	stc					;say match found
	jmp	short exit
	
tryChildren:
	mov	ax, MSG_GEN_FIND_KBD_ACCELERATOR
	call	CallChildrenWithSearchBitSet	;call any children
exit:
	; Match "inc" at top of routine
	;
	call	ObjDecInteractibleCount
	Destroy	ax, cx, dx, bp
	ret
GenFindKbdAccelerator	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	CallChildrenWithSearchBitSet

SYNOPSIS:	Calls any child that has GA_KBD_SEARCH_PATH bit set.

CALLED BY:	GenFindKbdAccelerator, GenFindMnemonic

PASS:		*ds:si -- parent
		ax     -- method to call children with
		same as MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code

RETURN:		carry set if search successful
		ax, cx, dx, bp - unchanged

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/17/90		Initial version

------------------------------------------------------------------------------@

CallChildrenWithSearchBitSet	proc	near
	class	GenClass
	
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx,offset GI_link
	push	bx			;push offset to LinkPart

NOFXIP <	push	cs			;push call-back routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>

	mov	bx,offset GenCallChildIfPathSet
	push	bx

	mov	bx,offset Gen_offset
	mov	di,offset GI_comp
	call	ObjCompProcessChildren	
	ret
CallChildrenWithSearchBitSet	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	GenCallChildIfPathSet

SYNOPSIS:	Calls the child if the kbd accelerator path bit is set.

CALLED BY:	GenFindKbdAccelerator

PASS:		*ds:si     -- child
		ax	   -- method to call
		same as MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code

RETURN:		carry set if through
		ax, cx, dx, bp - unchanged

DESTROYED:	di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/13/90		Initial version

------------------------------------------------------------------------------@

GenCallChildIfPathSet	proc	far
	class	GenClass
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GI_attrs, mask GA_KBD_SEARCH_PATH
	jz	10$				;path bit not set, ignore
	push	ax, cx, dx, bp
	call	ObjCallInstanceNoLock		;else send a method
	pop	ax, cx, dx, bp
						;carry set if something found
10$:
	ret
GenCallChildIfPathSet	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenGetKbdAccelerator

DESCRIPTION:	Returns current KbdAccelerator.

PASS:	*ds:si 	- instance data
	es     	- segment of GenClass
	ax 	- MSG_GEN_GET_KBD_ACCELERATOR

RETURN:	cx	- KeyboardShortcut

ALLOWED_TO_DESTROY:
	ax, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/17/90		Initial version

------------------------------------------------------------------------------@

GenGetKbdAccelerator	method GenClass, MSG_GEN_GET_KBD_ACCELERATOR
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	cx, ds:[di].GI_kbdAccelerator	;return keyboard accelerator	
	Destroy	ax, dx, bp
	ret
GenGetKbdAccelerator	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenSetKbdAccelerator

DESCRIPTION:	Sets a new keyboard accelerator. 

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_SET_KBD_ACCELERATOR
		
		cx	- KeyboardShortcut, or zero if removing moniker.
		dl	- UpdateMode

RETURN:		nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/17/90		Initial version

------------------------------------------------------------------------------@

GenSetKbdAccelerator	method GenClass, MSG_GEN_SET_KBD_ACCELERATOR
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	ds:[di].GI_kbdAccelerator, cx	;store new kbdAccelerator.
	tst	cx				;zeroing the field?
	jz	exit				;yes, exit
	
	push	dx				;save update mode
	mov	ax, MSG_GEN_SET_KBD_MKR_PATH	;else set path bits upward.
	call	ObjCallInstanceNoLock
	pop	dx				;restore UpdateMode
	;
	; Update things if necessary.
	;
	call	GenCheckIfSpecGrown		;don't update if not grown
	jnc	exit
	
EC<	call	VisCheckVisAssumption					>
	mov	bx, ds:[LMBH_handle]		;assume normal, set up bx
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD	
	jz	update				;start update if normal object
		
	push	dx				;save update mode
	clr	bp				;don't get the win group object
	CallMod	VisGetSpecificVisObject 	;returns vis object in ^lcx:dx
	mov	bx, cx			
	mov	si, dx				;now in ^lbx:si
	pop	dx				;restore update flag

update:
	mov	ax, MSG_SPEC_UPDATE_KBD_ACCELERATOR
	clr	di
	call	ObjMessage
exit:
	Destroy	ax, cx, dx, bp
	ret
GenSetKbdAccelerator	endm

		


COMMENT @----------------------------------------------------------------------

METHOD:		GenSetInitialSize -- 
		MSG_GEN_SET_INITIAL_SIZE for GenClass

DESCRIPTION:	Sets a new initial size for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_SET_INITIAL_SIZE
		
		ss:bp   - SetSizeArgs: new desired size, update mode
		dx      - size SetSizeArgs

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      	Stupid version, will not create a new hint!!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/91		Initial version

------------------------------------------------------------------------------@

GenSetInitialSize	method GenClass, MSG_GEN_SET_INITIAL_SIZE
	mov	di, HINT_INITIAL_SIZE
	call	ChangeSizeHint
	Destroy 	ax, cx, dx, bp
	ret
GenSetInitialSize	endm
	
			


COMMENT @----------------------------------------------------------------------

METHOD:		GenSetMinimumSize -- 
		MSG_GEN_SET_MINIMUM_SIZE for GenClass

DESCRIPTION:	Sets a new minimum size for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_SET_MINIMUM_SIZE
		
		ss:bp   - SetSizeArgs: new desired size, update mode
		dx      - size SetSizeArgs

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      	Stupid version, will not create a new hint!!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/91		Minimum version

------------------------------------------------------------------------------@

GenSetMinimumSize	method GenClass, MSG_GEN_SET_MINIMUM_SIZE
	mov	di, HINT_MINIMUM_SIZE
	
FinishSetSize	label	far
	call	ChangeSizeHint			 ;scan for the puppy
						 ;update mode now in dx
	call	VisCheckIfSpecBuilt		 ;if not visually built
	jnc	exit				 ;then no update needed

	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	ax, MSG_SPEC_RESCAN_GEO_AND_UPDATE
	GOTO	ObjCallInstanceNoLock
exit:
	Destroy 	ax, cx, dx, bp
	ret
GenSetMinimumSize	endm
	
	



COMMENT @----------------------------------------------------------------------

ROUTINE:	ChangeSizeHint

SYNOPSIS:	Changes the specified size hint.

CALLED BY:	GenSetInitialSize, FinishSetSize

PASS:		*ds:si -- object
		di     -- hint
		ss:bp  -- CompSizeHintArgs or GadgetSizeHintArgs
		dx     -- size CompSizeHintArgs or GadgetSizeHintArgs

RETURN:		dl     -- VisUpdateMode

DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/10/91		Initial version
	Doug	11/91		Updated for ObjVar changes
	Chris	3/11/92		Changed to nuke any data if no args

------------------------------------------------------------------------------@

ChangeSizeHint	proc	near
	;
	; Get width in ax, height in cx, child count in bp.
	;
	mov	ax, ss:[bp].SSA_width		; get the width
	mov	cx, ss:[bp].SSA_height		; and height
	mov	dl, ss:[bp].SSA_updateMode	; save update mode
	mov	bp, ss:[bp].SSA_count		; else get number of children

	mov	bx, ax				; check width and height
	or	bx, cx				; is anything specified?
	jnz	10$				; yes, go add vardata
	mov	ax, di
	call	ObjVarDeleteData		; else delete any vardata
	jmp	short exit
10$:
	push	ax, cx				; save arguments
	mov	ax, di
	ornf	ax, mask VDF_SAVE_TO_STATE	; make this permanent

	; If 1 or more children, need CompSizeHintArgs, else
	; GadgetSizeHintArgs will do fine

	mov	cx, size GadgetSizeHintArgs
	tst	ss:[bp].SSA_count
	jz	20$
	add	cx, size CompSizeHintArgs - size GadgetSizeHintArgs
20$:
	call	ObjVarAddData			; ds:bx is ptr to extra data
	pop	ax, cx				; restore arguments

	;
	; Store new data
	;
	mov	({GadgetSizeHintArgs} ds:[bx]).GSHA_width, ax
	mov	({GadgetSizeHintArgs} ds:[bx]).GSHA_height, cx
	tst	bp
	jz	exit
	mov	({CompSizeHintArgs} ds:[bx]).CSHA_count, bp
exit:
	; Return update mode
	ret
ChangeSizeHint	endp






COMMENT @----------------------------------------------------------------------

METHOD:		GenSetWinPosition -- 
		MSG_GEN_SET_WIN_POSITION for GenClass

DESCRIPTION:	Sets a new window position.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_SET_WIN_POSITION

		dl = VisUpdateMode
		dh = WinPositionType (WPS_AT_RATIO, etc)
		cx = X position (SpecWinSizeSpec)
		bp = Y position (SpecWinSizeSpec)

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/21/93         	Initial Version

------------------------------------------------------------------------------@
BASE_HINT	equ	HINT_KEEP_INITIALLY_ONSCREEN

GenSetWinPosition	method dynamic	GenClass, MSG_GEN_SET_WIN_POSITION
EC <	cmp	dh, WinPositionType					>
EC <	ERROR_AE  UI_BAD_WIN_POSITION_TYPE				>

	mov	di, (HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT - BASE_HINT) or \
		   ((HINT_POSITION_WINDOW_AT_MOUSE - BASE_HINT) shl 8)
	mov	bx, offset positionHintTable
	GOTO	HandleWinGeometryChange

GenSetWinPosition	endm


;Assure hint ordering, proximity to BASE_HINT...

CheckHack <((HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT - BASE_HINT) lt 255)>
CheckHack <((HINT_POSITION_WINDOW_AT_MOUSE - BASE_HINT) lt 255)>

CheckHack <(HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT lt HINT_STAGGER_WINDOW)>
CheckHack <(HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT lt HINT_CENTER_WINDOW)>
CheckHack <(HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT lt HINT_TILE_WINDOW)>
CheckHack <(HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT lt HINT_POSITION_WINDOW_AT_MOUSE)>
CheckHack <(HINT_POSITION_WINDOW_AT_MOUSE gt HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT)>
CheckHack <(HINT_POSITION_WINDOW_AT_MOUSE gt HINT_TILE_WINDOW)>
CheckHack <(HINT_POSITION_WINDOW_AT_MOUSE gt HINT_CENTER_WINDOW)>
CheckHack <(HINT_POSITION_WINDOW_AT_MOUSE gt HINT_STAGGER_WINDOW)>

positionHintTable	word \
		HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT or mask VDF_EXTRA_DATA,
		HINT_STAGGER_WINDOW,
		HINT_CENTER_WINDOW,
		HINT_TILE_WINDOW,
		HINT_POSITION_WINDOW_AT_MOUSE,
		0,
		0
.assert length positionHintTable eq WinPositionType


COMMENT @----------------------------------------------------------------------

METHOD:		GenSetWinSize -- 
		MSG_GEN_SET_WIN_SIZE for GenClass

DESCRIPTION:	Sets a new window size

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_SET_WIN_SIZE

		dl = VisUpdateMode
		dh = WinSizeType (WST_AS_DESIRED, etc)
		cx = X position (SpecWinSizeSpec), if applicable
		bp = Y position (SpecWinSizeSpec), if applicable

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/21/93         	Initial Version

------------------------------------------------------------------------------@

GenSetWinSize	method dynamic	GenClass, MSG_GEN_SET_WIN_SIZE
EC <	cmp	dh, WinSizeType						>
EC <	ERROR_AE  UI_BAD_WIN_SIZE_TYPE					>

	mov	di, (HINT_EXTEND_WINDOW_TO_BOTTOM_RIGHT - BASE_HINT) or \
		   ((HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD - BASE_HINT) shl 8)

	mov	bx, offset sizeHintTable
	GOTO	HandleWinGeometryChange

GenSetWinSize	endm



;Assure hint ordering, proximity to BASE_HINT...

CheckHack <((HINT_EXTEND_WINDOW_TO_BOTTOM_RIGHT - BASE_HINT) lt 255)>
CheckHack <((HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD - BASE_HINT) lt 255)>

CheckHack <(HINT_EXTEND_WINDOW_TO_BOTTOM_RIGHT lt HINT_EXTEND_WINDOW_NEAR_BOTTOM_RIGHT)>
CheckHack <(HINT_EXTEND_WINDOW_TO_BOTTOM_RIGHT lt HINT_SIZE_WINDOW_AS_DESIRED)>
CheckHack <(HINT_EXTEND_WINDOW_TO_BOTTOM_RIGHT lt HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT)>
CheckHack <(HINT_EXTEND_WINDOW_TO_BOTTOM_RIGHT lt HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD)>
CheckHack <(HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD gt HINT_EXTEND_WINDOW_TO_BOTTOM_RIGHT)>
CheckHack <(HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD gt HINT_SIZE_WINDOW_AS_DESIRED)>
CheckHack <(HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD gt HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT)>
CheckHack <(HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD gt HINT_EXTEND_WINDOW_NEAR_BOTTOM_RIGHT)>

sizeHintTable	word \
		HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT or mask VDF_EXTRA_DATA,
		HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD or mask VDF_EXTRA_DATA,
		HINT_SIZE_WINDOW_AS_DESIRED,
		HINT_EXTEND_WINDOW_TO_BOTTOM_RIGHT,
		HINT_EXTEND_WINDOW_NEAR_BOTTOM_RIGHT
.assert length sizeHintTable eq WinSizeType
	

COMMENT @----------------------------------------------------------------------

METHOD:		GenSetWinConstrain -- 
		MSG_GEN_SET_WIN_CONSTRAIN for GenClass

DESCRIPTION:	Sets a new window constrain

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_SET_WIN_CONSTRAIN

		dl = VisUpdateMode
		dh = WinConstrainType (WST_AS_DESIRED, etc)
		cx = X position (SpecWinSizeSpec), if applicable
		bp = Y position (SpecWinSizeSpec), if applicable

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/21/93         	Initial Version

------------------------------------------------------------------------------@

GenSetWinConstrain	method dynamic	GenClass, MSG_GEN_SET_WIN_CONSTRAIN
EC <	cmp	dh, WinConstrainType					>
EC <	ERROR_AE	UI_BAD_WIN_CONSTRAIN_TYPE			>

	mov	di, (HINT_KEEP_PARTIALLY_ONSCREEN - BASE_HINT) or \
		   ((HINT_DONT_KEEP_PARTIALLY_ONSCREEN - BASE_HINT) shl 8)

	mov	bx, offset constrainHintTable
	GOTO	HandleWinGeometryChange

GenSetWinConstrain	endm


;Assure hint ordering, proximity to BASE_HINT...

CheckHack <((HINT_KEEP_PARTIALLY_ONSCREEN - BASE_HINT) lt 255)>
CheckHack <((HINT_DONT_KEEP_PARTIALLY_ONSCREEN - BASE_HINT) lt 255)>

CheckHack <(HINT_KEEP_PARTIALLY_ONSCREEN lt HINT_DONT_KEEP_PARTIALLY_ONSCREEN)>
CheckHack <(HINT_KEEP_PARTIALLY_ONSCREEN lt HINT_KEEP_ENTIRELY_ONSCREEN)>
CheckHack <(HINT_KEEP_PARTIALLY_ONSCREEN lt HINT_KEEP_ENTIRELY_ONSCREEN_WITH_MARGIN)>
CheckHack <(HINT_DONT_KEEP_PARTIALLY_ONSCREEN gt HINT_KEEP_PARTIALLY_ONSCREEN)>
CheckHack <(HINT_DONT_KEEP_PARTIALLY_ONSCREEN gt HINT_KEEP_PARTIALLY_ONSCREEN)>
CheckHack <(HINT_DONT_KEEP_PARTIALLY_ONSCREEN gt HINT_KEEP_ENTIRELY_ONSCREEN_WITH_MARGIN)>

constrainHintTable	word \
		HINT_DONT_KEEP_PARTIALLY_ONSCREEN,
		HINT_KEEP_PARTIALLY_ONSCREEN,
		HINT_KEEP_ENTIRELY_ONSCREEN,
		HINT_KEEP_ENTIRELY_ONSCREEN_WITH_MARGIN
.assert length constrainHintTable eq WinConstrainType
	
			



COMMENT @----------------------------------------------------------------------

ROUTINE:	HandleWinGeometryChange

SYNOPSIS:	Handles a changing the win geometry attributes in some way.
		Sets the appropriate hint, and passes this message off to
		the superclass if built.   Also nukes old hints in the same
		class as the one being added.

CALLED BY:	GenSetWinPosition, GetSetWinSize, GenSetWinConstrain

PASS:		*ds:si -- object
		ax -- message
		bx -- pointer to word-length hint table
		dl -- VisUpdateMode
		dh -- index into hint table
		cx, bp -- arguments, if any.

		di low -- first hint in table of range of hints to nuke,
			  offset from BASE_HINT...
		di high -- last hint in table of range of hints to nuke,
			   offset from BASE_HINT...
		
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/21/93       	Initial version

------------------------------------------------------------------------------@

HandleWinGeometryChange	proc	far
	call	NukeOldHints			;nuke old, related hints

	push	es, ax, cx, dx, bp		


	shl	dh, 1				
	add	bl, dh
	adc	bh, 0
	mov	ax, cs:[bx]			;get hint name from table
	tst	ax				;No hint? Then we're done.
	jz	20$

	push	cx				;x argument

	ornf	ax, mask VDF_SAVE_TO_STATE	;make this permanent

	; If VDF_EXTRA_DATA is set, we'll pass arguments, otherwise none.

	clr	cx
	test	ax, mask VDF_EXTRA_DATA
	jz	10$
	mov	cx, size SpecWinSizePair	
10$:
	pop	dx				;x argument
	call	ObjVarAddData			;ds:bx is ptr to extra data
	tst	cx				;was there data?
	jz	20$				;no, branch
	mov	({SpecWinSizePair} ds:[bx]).SWSP_x, dx
	mov	({SpecWinSizePair} ds:[bx]).SWSP_y, bp
20$:
	pop	es, ax, cx, dx, bp		

	; Call superclass, but only if already grown. 

	call	GenCallSpecIfGrown		
	ret

HandleWinGeometryChange	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	NukeOldHints

SYNOPSIS:	Nukes old hints in the class of the one being added.

CALLED BY:	HandleWinGeometryChange

PASS:		*ds:si -- object
		di low -- first hint in range to nuke, offset from BASE_HINT
		di high --last hint in range to nuke, offset from BASE_HINT

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/29/93       	Initial version

------------------------------------------------------------------------------@

NukeOldHints	proc	near		uses	cx, dx, bp
	.enter
	mov	cx, di
	clr	dx
	mov	dl, ch

	clr	ch
	add	cx, BASE_HINT			;cx <- first hint to nuke
	add	dx, BASE_HINT			;dx <- last hint to nuke
	clr	bp				;nuke hints, regardless of state
	call	ObjVarDeleteDataRange
	.leave
	ret
NukeOldHints	endp






COMMENT @----------------------------------------------------------------------

METHOD:		GenSetMaximumSize -- 
		MSG_GEN_SET_MAXIMUM_SIZE for GenClass

DESCRIPTION:	Sets a new maximum size for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_SET_MAXIMUM_SIZE
		
		ss:bp   - SetSizeArgs: new desired size, update mode
		dx      - size SetSizeArgs

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      	Stupid version, will not create a new hint!!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/91		Maximum version

------------------------------------------------------------------------------@

GenSetMaximumSize	method GenClass, MSG_GEN_SET_MAXIMUM_SIZE
	mov	di, HINT_MAXIMUM_SIZE
	GOTO	FinishSetSize
GenSetMaximumSize	endm
	


COMMENT @----------------------------------------------------------------------

METHOD:		GenSetFixedSize -- 
		MSG_GEN_SET_FIXED_SIZE for GenClass

DESCRIPTION:	Sets a new fixed size for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_SET_FIXED_SIZE
		
		ss:bp   - SetSizeArgs: new desired size, update mode
		dx      - size SetSizeArgs

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      	Stupid version, will not create a new hint!!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/91		Fixed version

------------------------------------------------------------------------------@

GenSetFixedSize	method GenClass, MSG_GEN_SET_FIXED_SIZE
	mov	di, HINT_FIXED_SIZE
	GOTO	FinishSetSize
GenSetFixedSize	endm
	
	
		


COMMENT @----------------------------------------------------------------------

METHOD:		GenGetInitialSize -- 
		MSG_GEN_GET_INITIAL_SIZE for GenClass

DESCRIPTION:	Gets a new initial size for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_GET_INITIAL_SIZE
		
RETURN:		cx      - initial width, or zero if none
		dx      - initial height, or zero if none
		bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      	Stupid version, will not create a new hint!!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/91		Initial version

------------------------------------------------------------------------------@

GenGetInitialSize	method GenClass, MSG_GEN_GET_INITIAL_SIZE
	mov	di, offset cs:OpenGet
	mov	ax, length (cs:OpenGet)

FinishGetSize	label	far
	mov	cx, cs
	mov	es, cx
	clr	cx				;assume none
	clr	dx
	clr	bp
	call	ObjVarScanData			;stuff in new arguments
	Destroy 	ax
	ret
GenGetInitialSize	endm
	
			
OpenGet	VarDataHandler \
	<HINT_INITIAL_SIZE, offset GetArgs>
	
GetArgs	proc	far
	VarDataSizePtr	ds, bx, cx		; get size into cx
	cmp	cx, size GadgetSizeHintArgs
	je	10$					
	mov	ax, ({CompSizeHintArgs} ds:[bx]).CSHA_count
10$:
	mov	cx, ({CompSizeHintArgs} ds:[bx]).CSHA_width
	mov	dx, ({CompSizeHintArgs} ds:[bx]).CSHA_height
	ret
GetArgs	endp

		
		


COMMENT @----------------------------------------------------------------------

METHOD:		GenGetMinimumSize -- 
		MSG_GEN_GET_MINIMUM_SIZE for GenClass

DESCRIPTION:	Gets a new minimum size for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_GET_MINIMUM_SIZE
		
RETURN:		cx      - minimum width, or zero if none
		dx      - minimum height, or zero if none
		ax, bp  - destroyed
		
RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      	Stupid version, will not create a new hint!!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/91		Minimum version

------------------------------------------------------------------------------@

GenGetMinimumSize	method GenClass, MSG_GEN_GET_MINIMUM_SIZE
	mov	di, offset cs:MinimumGet
	mov	ax, length (cs:MinimumGet)
	GOTO	FinishGetSize
GenGetMinimumSize	endm
	
			
MinimumGet	VarDataHandler \
	<HINT_MINIMUM_SIZE, offset GetArgs>
	


COMMENT @----------------------------------------------------------------------

METHOD:		GenGetMaximumSize -- 
		MSG_GEN_GET_MAXIMUM_SIZE for GenClass

DESCRIPTION:	Gets a new maximum size for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_GET_MAXIMUM_SIZE
		
RETURN:		cx      - maximum width, or zero if none
		dx      - maximum height, or zero if none
		ax, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      	Stupid version, will not create a new hint!!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/91		Maximum version

------------------------------------------------------------------------------@

GenGetMaximumSize	method GenClass, MSG_GEN_GET_MAXIMUM_SIZE
	mov	di, offset cs:MaximumGet
	mov	ax, length (cs:MaximumGet)
	GOTO	FinishGetSize
GenGetMaximumSize	endm
	
MaximumGet	VarDataHandler \
	<HINT_MAXIMUM_SIZE, offset GetArgs>
	


COMMENT @----------------------------------------------------------------------

METHOD:		GenGetFixedSize -- 
		MSG_GEN_GET_FIXED_SIZE for GenClass

DESCRIPTION:	Gets a new fixed size for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_GET_FIXED_SIZE
		
RETURN:		cx      - fixed width, or zero if none
		dx      - fixed height, or zero if none
		ax, bp  - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      	Stupid version, will not create a new hint!!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/91		Fixed version

------------------------------------------------------------------------------@

GenGetFixedSize	method GenClass, MSG_GEN_GET_FIXED_SIZE
	mov	di, offset cs:FixedGet
	mov	ax, length (cs:FixedGet)
	GOTO	FinishGetSize
GenGetFixedSize	endm
	
FixedGet	VarDataHandler \
	<HINT_FIXED_SIZE, offset GetArgs>


COMMENT @----------------------------------------------------------------------

METHOD:		GenResetToInitialSize -- 
		MSG_GEN_RESET_TO_INITIAL_SIZE for GenClass

DESCRIPTION:	Resets an object's geometry as if were coming up for the first
		time again.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_RESET_TO_INITIAL_SIZE
		
		dl	- VisUpdateMode

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/29/91		Initial version

------------------------------------------------------------------------------@

GenResetToInitialSize	method dynamic	GenClass, MSG_GEN_RESET_TO_INITIAL_SIZE
	call	VisCheckIfSpecBuilt		;if not visually built
	jnc	exit				;then exit
	
	mov	ax, MSG_VIS_RESET_TO_INITIAL_SIZE
	mov	di, offset GenClass		;else send to specific UI
	GOTO	ObjCallSuperNoLock
exit:
	Destroy	ax, cx, dx, bp
	ret
	
GenResetToInitialSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenGenSetAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the GenAttrs for this object.

CALLED BY:	MSG_GEN_SET_ATTRS

PASS:		*ds:si - generic object
		es - segment of GenClass
		ax - MSG_GEN_SET_ATTRS

		cl - GenAttrs to set
		ch - GenAttrs to clear

RETURN:		nothing

ALLOWED TO DESTROYED:	
		ax, bx, cx, dp
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenGenSetAttributes	method	GenClass, MSG_GEN_SET_ATTRS
EC <	test	ds:[di].GI_states, mask GS_USABLE			>
EC <	ERROR_NZ	UI_GEN_CANT_SET_GEN_ATTRIBUTES_WHEN_USABLE	>
	not	ch
	andnf	ds:[di].GI_attrs, ch	; clear bits
	ornf	ds:[di].GI_attrs, cl	; set bits
	Destroy	ax, bx, cx, bp
	ret
GenGenSetAttributes	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenGenGetAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the GenAttrs for this object.

CALLED BY:	MSG_GEN_GET_ATTRIBUTES

PASS:		*ds:si - generic object
		es - segment of GenClass
		ax - MSG_GEN_GET_ATTRIBUTES

RETURN:		cl - GenAttrs

ALLOWED TO DESTROYED:	
		ax, bx, ch, dp
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenGenGetAttributes	method	GenClass, MSG_GEN_GET_ATTRIBUTES
	mov	cl, ds:[di].GI_attrs
	Destroy	ax, bx, ch, bp
	ret
GenGenGetAttributes	endm



COMMENT @----------------------------------------------------------------------

MESSAGE:	GenOutputAction -- MSG_GEN_OUTPUT_ACTION for GenClass

DESCRIPTION:	Send the specified message to the specified destination

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - The message

	if cx != 0 {
		cx:dx	- optr to dispatch event to.
		bp	- Event to dispatch.  Stored destination is ignored.
	} else {
		dx	- TravelOption to use with MSG_META_SEND_CLASSED_EVENT,
			  which will be called on this object with the passed
			  ClassedEvent as a parameter.
		bp	- ClasssedEvent.  The class stored will be overwritten
			  if an ATTR_GEN_DESTINATION_CLASS is found on the object,
			  with the class stored in that attribute.
	}

RETURN:
	nothing

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/11/91	Initial version
	Doug	1/27/92		2nd pass

------------------------------------------------------------------------------@
GenOutputAction	method dynamic	GenClass, MSG_GEN_OUTPUT_ACTION

	; this travels via the target chain which needs much more stack
	; space in the EC version

EC <	mov	di, 1200						>
NEC <	mov	di, 800							>
	call	ThreadBorrowStackSpace
	push	di

	tst	cx
	jnz	sendToObject
	tst	dx
	jz	freeEvent		; if TO_NULL, free the event and exit.

	mov	ax, ATTR_GEN_DESTINATION_CLASS	; get attribute to look for
	call	ObjVarFindData
	jnc	haveClassedEvent

	push	si
	; Fetch class to override with
	;
EC <	push	es, di							>
EC <	les	di, ds:[bx].DCA_class					>
EC <	call	ECCheckClass						>
EC <	pop	es, di							>

	mov	cx, ds:[bx].DCA_class.segment
	mov	si, ds:[bx].DCA_class.offset

	mov	bx, bp
	push	cx, si
	call	ObjGetMessageInfo		; get ax = message
	pop	cx, si
	call	MessageSetDestination		; store back new class to use
	pop	si

haveClassedEvent:
	; bp = ClassedEvent
	; dx = TravelOption
	;
	mov	ax, ATTR_GEN_OUTPUT_TRAVEL_START
	call	ObjVarFindData

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	cx, bp			; get ClassedEvent in cx
	jc	sendClassedEventToOtherObject

	call	ObjCallInstanceNoLock
	jmp	short done

sendClassedEventToOtherObject:
	mov	si, ds:[bx].chunk	; ^lbx:si <- start of event's travel
	mov	bx, ds:[bx].handle
	mov	di, mask MF_FIXUP_DS	; we don't insist on a call, but...
	call	ObjMessage
	jmp	done

sendToObject:
	mov	bx, bp			; bx = event
	mov	si, dx			; get cx:si = passed optr
	call	MessageSetDestination
	clr	di			; no flags
	call	MessageDispatch
done:
	pop	di
	call	ThreadReturnStackSpace
	ret
	
freeEvent:
	mov	bx, bp
	call	ObjFreeMessage
	jmp	done
GenOutputAction	endm






COMMENT @----------------------------------------------------------------------

METHOD:		GenAddGeometryHint -- 
		MSG_GEN_ADD_GEOMETRY_HINT for GenClass

DESCRIPTION:	Adds a geometry hint to an object, updating geometry as
		necessary.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ADD_GEOMETRY_HINT

		cx	- hint in question
		dl	- VisUpdateMode
		bp	- argument to hint if applicable

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 5/92		Initial Version

------------------------------------------------------------------------------@

GenAddGeometryHint	method dynamic	GenClass, MSG_GEN_ADD_GEOMETRY_HINT
	mov	ax, cx				; hint in ax
	clr	cx				; assume normal hint
	call	HintRequiresOneWordData
	jnc	addData				; don't need data, branch
	mov	cx, 2
addData:
	call	ObjVarAddData			; ds:bx is ptr to extra data
	tst	cx				; no hint data, please do not
	jz	rescanGeo			;   store any. (7/27/92 cbh)
	mov	{word} ds:[bx], bp		; store the data.
rescanGeo:
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
	mov	ax, MSG_SPEC_RESCAN_GEO_AND_UPDATE
	GOTO	ObjCallInstanceNoLock
GenAddGeometryHint	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenRemoveGeometryHint -- 
		MSG_GEN_REMOVE_GEOMETRY_HINT for GenClass

DESCRIPTION:	Removes a geometry hint, updating geometry if needed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_REMOVE_GEOMETRY_HINT

		cx	- hint to remove
		dl	- VisUpdateMode
RETURN:		
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 5/92		Initial Version

------------------------------------------------------------------------------@

GenRemoveGeometryHint	method dynamic	GenClass, MSG_GEN_REMOVE_GEOMETRY_HINT
	mov	ax, cx
	call	ObjVarDeleteData

	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
	mov	ax, MSG_SPEC_RESCAN_GEO_AND_UPDATE
	GOTO	ObjCallInstanceNoLock
GenRemoveGeometryHint	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	HintRequiresOneWordData

SYNOPSIS:	Returns carry set if hint needs one word of data.

CALLED BY:	GenAddGeometryHint

PASS:		ax -- message

RETURN:		carry set if message needs one word of data.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 5/92		Initial version
	Reza	12/8/94		Added checks for ATTR_GEN_POSITION_*
------------------------------------------------------------------------------@

HintRequiresOneWordData	proc	near
	cmp	ax, HINT_CUSTOM_CHILD_SPACING	; requires 1 word data
	je	needsWord
	cmp	ax, ATTR_GEN_POSITION_X
	je	needsWord
	cmp	ax, ATTR_GEN_POSITION_Y
	je	needsWord
	cmp	ax, HINT_WRAP_AFTER_CHILD_COUNT
	clc					; assume don't need word
	jne	exit
needsWord:
	stc
exit:
	ret
HintRequiresOneWordData	endp





COMMENT @----------------------------------------------------------------------

METHOD:		GenFindMatchingText -- 
		MSG_GEN_FIND_OBJECT_WITH_TEXT_MONIKER for GenClass

DESCRIPTION:	Returns an object in the generic tree whose moniker matches
		the passed text. 

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_FIND_OBJECT_WITH_TEXT_MONIKER
		cx:dx	- null terminated text to match
		(cx:dx *cannot* be pointing into the movable XIP code resource.)
		bp	- non-zero if we should only match on children

RETURN:		carry set if object found, with:
			^lcx:dx -- optr of object
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/19/92		Initial Version
	JDM	93.06.25	Preservation of ds as needed.

------------------------------------------------------------------------------@

GenFindTextMoniker	method dynamic	GenClass, 
			MSG_GEN_FIND_OBJECT_WITH_TEXT_MONIKER
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr (cx:dx) passed in valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	;
	; First, let's see if this thing matches ourselves.
	;
	push	ds, si				;save important data
	test	bp, mask GFOWMF_SKIP_THIS_NODE	;see if we should check here
	jnz	callChildren			;no, branch now

	mov	di, ds:[di].GI_visMoniker	;get moniker chunk
	tst	di	
	jz	callChildren			;no chunk, call children

	segmov	es, ds				;text in *es:di
	mov	di, es:[di]
	test	es:[di].VM_type, mask VMT_GSTRING		
	jnz	callChildren			;moniker is a gstring, branch
	add	di, VM_data + VMT_text		;point at the data
	cmp	{char} es:[di], 0
	jz	callChildren
	mov	si, dx				;ds:si <- text to match
	mov	ds, cx
check:
	cmp	{char} ds:[si], 0		;are we done?
	jz	match				;yes, branch
	cmpsb					;compare bytes
	jne	callChildren			;total failure, try children
	jmp	short check			;else try another character

match:
	test	bp, mask GFOWMF_EXACT_MATCH	;do we need an exact match?
	jz	10$				;no, branch
	cmp	{char} es:[di], 0		;is the other text null term'ed?
	jnz	callChildren			;nope, weren't same length, 
						;   call children

10$:						;else we really have a match.
	pop	ds, dx				;restore saved information.
	mov	cx, es:[LMBH_handle]		;return ourselves in ^lcx:dx
	stc					;say found match
	ret

callChildren:
	pop	ds, si				;restore important info
	clr	bx				;initial child (first
	push	bx				; child of
	push	bx				; composite)
	mov	bx, offset GI_link		;Pass offset to LinkPart
	push	bx
	clr	bx				;Use standard function
	push	bx
	mov	bx, OCCT_DONT_SAVE_PARAMS_TEST_ABORT
	push	bx
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp

	mov	ax, MSG_GEN_FIND_OBJECT_WITH_TEXT_MONIKER	
	clr	bp				;do check on self
	call	ObjCompProcessChildren		;must use a call (no GOTO) since
						;parameters are passed on stack
	ret

GenFindTextMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFindObjectWithTextMonikerC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GEN_FIND_OBJECT_WITH_TEXT_MONIKER for GenClass
		Returns an object in the generic tree whose moniker matches
		the passed text. 

CALLED BY:	MSG_GEN_FIND_OBJECT_WITH_TEXT_MONIKER_C
PASS:		*ds:si	= GenClass object
		ds:di	= GenClass instance data
		ds:bx	= GenClass object (same as *ds:si)
		es 	= segment of GenClass
		ax	= message #
		cx:dx	= null terminated text to match
		(cx:dx *cannot* be pointing into the movable XIP code resource.)
		bp	= non-zero if we should only match on children
RETURN:		carry set if object found, with:
			^lcx:dx -- optr of object
		carry clear otherwise
			^lcx:dx -- NullOptr
DESTROYED:	ax, bp, bx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFindObjectWithTextMonikerC	method dynamic GenClass, 
					MSG_GEN_FIND_OBJECT_WITH_TEXT_MONIKER_C
	mov	ax, MSG_GEN_FIND_OBJECT_WITH_TEXT_MONIKER
	call	ObjCallInstanceNoLock
	jc	done
	mov	cx, 0			; clear optr, preserving flags
	mov	dx, 0
done:
	ret
GenFindObjectWithTextMonikerC	endm

Common ends
