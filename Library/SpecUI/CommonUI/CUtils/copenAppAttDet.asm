COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Open
FILE:		copenAppAttDet.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLApplicationClass	Open look Application class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenApplication.asm

DESCRIPTION:

	$Id: copenAppAttDet.asm,v 1.1 97/04/07 10:54:47 newdeal Exp $

------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLApplicationClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

	OLAppTaskItemClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

	method	VupCreateGState, OLApplicationClass, MSG_VIS_VUP_CREATE_GSTATE

CommonUIClassStructures ends

;---------------------------------------------------

AppAttach segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLAppInitialize -- MSG_META_INITIALIZE for OLAppClass

DESCRIPTION:	-

PASS:
	*ds:si - instance data
	es - segment of OLAppClass

	ax - The method

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version

------------------------------------------------------------------------------@

OLAppInitialize	method dynamic	OLApplicationClass, MSG_META_INITIALIZE

	; Do superclass initialization first
	;
	mov	di, offset OLApplicationClass
	CallSuper	MSG_META_INITIALIZE

	; Set THIS object as the input object for the overall geode.
	;
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	WinGeodeSetInputObj

	call	OLAppUpdateGeodeWinFlags; Update this geode's GeodeWinFlags to
					; reflect current app attrs

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	; Allow application, as a whole, to be "realizable"

	ORNF	ds:[di].VI_specAttrs, mask SA_REALIZABLE

	; Turn off geometry

	ANDNF	ds:[di].VI_attrs, not (mask VA_MANAGED)
	ORNF	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN

	; Set default units

	mov	ds:[di].OLAI_units, AMT_DEFAULT


	; GRAB stuff should be set here.


	; Init exclusives to have exclusive "within application", since this
	; is the application itself
	;
	ornf	ds:[di].VCNI_focusExcl.FTVMC_flags, mask HGF_APP_EXCL or \
					mask MAEF_OD_IS_WINDOW
	ornf	ds:[di].VCNI_targetExcl.FTVMC_flags, mask HGF_APP_EXCL
	ornf	ds:[di].OLAI_modelExcl.FTVMC_flags, mask HGF_APP_EXCL

					; Objects requesting grab will
					; always be windows.

	; Get default field window (presume only one), where most all windows 
	; of the app will be placed.
	;
	mov	cx, GUQT_FIELD
	mov	ax, MSG_SPEC_GUP_QUERY
	call	ObjCallInstanceNoLock
EC <	xchg	bx, bp							>
EC <	call	ECCheckWindowHandle					>
EC <	xchg	bx, bp							>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLAI_fieldWin, bp

	; Get default screen window (presume only one), where all system modal
	; dialogs should be placed.  Store away for future reference, in 
	; particular, to speed up search to see if this app has any system
	; modal dialogs up on screen.
	;
	mov	cx, GUQT_SCREEN
	mov	ax, MSG_SPEC_GUP_QUERY
	call	ObjCallInstanceNoLock
EC <	xchg	bx, bp							>
EC <	call	ECCheckWindowHandle					>
EC <	xchg	bx, bp							>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLAI_screenWin, bp

	; store our handle as the UI data

	mov	ax, handle 0
	clr	bx
	call	GeodeSetUIData

	ret

OLAppInitialize	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLAppUpdateGeodeWinFlags

DESCRIPTION:	Update GeodeWinFlags stored in geode variable space, where the
		window system can get access to them.  Basically just a
		straight update from the attributes in this object's instance
		data, as set by the developer.

CALLED BY:	INTERNAL
		OLAppInitialize

PASS:		*ds:si	- GenApplication object

RETURN:		nothing

DESTROYED:	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Initial version
------------------------------------------------------------------------------@

OLAppUpdateGeodeWinFlags	proc	far	uses	ax, di, cx, dx
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	clr	ax
	test	ds:[di].GI_attrs, mask GA_TARGETABLE
	jz	10$
	ornf	ax, mask GWF_TARGETABLE
10$:
	test	ds:[di].GAI_states, mask AS_FOCUSABLE
	jz	20$
	ornf	ax, mask GWF_FOCUSABLE
20$:
	test	ds:[di].GAI_states, mask AS_MODELABLE
	jz	30$
	ornf	ax, mask GWF_MODELABLE
30$:
	; Now figure out whether this app should get the FULL_SCREEN exclusive.
	; If a desk accessory, or not interactable, or not running in
	; transparent mode, then no.
	;
	test	ds:[di].GAI_states, mask AS_NOT_USER_INTERACTABLE
	jnz	notFullScreen
	test	ds:[di].GAI_launchFlags, mask ALF_DESK_ACCESSORY
	jnz	notFullScreen

	push	ax
	call	UserGetLaunchModel	;ax = UILaunchModel
	cmp	ax, UILM_TRANSPARENT
	pop	ax
	jne	notFullScreen

	; If the app doesn't run below a GenField object, don't request the
	; FULL_SCREEN exclusive.
	;
	push	ax
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	cx, segment GenFieldClass
	mov	dx, offset GenFieldClass
	call	GenCallParent
	pop	ax
	jnc	notFullScreen

	ornf	ax, mask GWF_FULL_SCREEN

notFullScreen:
	call	GeodeGetProcessHandle		; bx <- process handle
	call	WinGeodeSetFlags
	.leave
	ret
OLAppUpdateGeodeWinFlags	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationAttach -- MSG_META_ATTACH for
					   OLApplicationClass

DESCRIPTION:	Start up an open look application

PASS:
	*ds:si - instance data
	es - segment of OlApplicationClass

	ax - MSG_META_ATTACH

	cx, dx, bp	- ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	attach application to UI system object;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

OLApplicationAttach	method dynamic	OLApplicationClass, MSG_META_ATTACH
	; clear out various variables to cope with being resurrected after the
	; user has quit us.

	clr	ax
	mov	ds:[di].OLAI_busyCount, ax
	mov	ds:[di].OLAI_holdUpInputCount, ax
	mov	ds:[di].OLAI_ignoreInputCount, ax
	mov	ds:[di].OLAI_completelyBusyCount, al

	; similarly for the GeodeWinFlags, which were zeroed when we detached

	call	OLAppUpdateGeodeWinFlags

	; If there's an ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY present, we
	; must be coming back from state (real state, not a transparent
	; detach), so honor it & come back at the same place.  If not,
	; raise it to ON_TOP if we're a DA.
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
	call	ObjVarFindData
	jc	doneWithLayerPrio
	call	OLAppRaiseLayerPrioIfDeskAccessory
doneWithLayerPrio:

	; Do spec build & visual update
					; Mark display as Attached only.
					; If specific objects want themselves
					; to be visible when the ensuing
					; update happens, they should subclass
					; this method & or in the
					; SA_REALIZABLE bit before calling
					; this superclass method.
					; Note that if any generic parent
					; is MINIMIZED, then the specific UI
					; may set a bit which prevents
					; the children (such as this one)
					; from actually being made visible.

	mov	cl, mask SA_ATTACHED
	clr	ch
					; Do visual update. If attached,
					; usable & visible, it will come up
					; on screen.
	mov	dl, VUM_NOW
	mov	ax, MSG_SPEC_SET_ATTRS
	call	ObjCallInstanceNoLock

	ret

OLApplicationAttach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationSetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of a change in generic state relating to
		focusability etc.

CALLED BY:	MSG_GEN_APPLICATION_SET_STATE
PASS:		*ds:si	= GenApplication object
		ds:di	= OLApplicationInstance
		cx	= ApplicationStates just set
		dx	= ApplicationStates just cleared
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationSetState method dynamic OLApplicationClass, 
		      		MSG_GEN_APPLICATION_SET_STATE
	.enter
	;
	; First let the window system know our change in status, so when we
	; release the focus, the system knows to try and give it to someone
	; else that isn't us..
	; 
	call	OLAppUpdateGeodeWinFlags
	;
	; Only thing to worry about here are the focus and model hierarchies.
	; 
	clr	bp
	test	dx, mask AS_FOCUSABLE
	jz	checkModel
	test	cx, mask AS_FOCUSABLE
	jnz	checkModel		; => actually remaining as focus, but
					;  being overzealous, or something
	ornf	bp, mask MAEF_FOCUS

checkModel:
	test	dx, mask AS_MODELABLE
	jz	checkChanges
	test	cx, mask AS_MODELABLE
	jnz	checkChanges		; => actually remaining as model, but
					;  being overzealous, or something
	ornf	bp, mask MAEF_MODEL

checkChanges:
	tst	bp
	jz	done
	
	;
	; Something to release. Do it, but perform the release one level up,
	; rather than biffing the stuff stored at this level.
	;
	call	OLAppReleaseSomething
done:
	.leave
	ret
OLApplicationSetState endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAppReleaseSomething
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release one of three grabs and ensure our parent has something
		active for the focus and target grabs.

CALLED BY:	(INTERNAL) OLApplicationSetState, OLApplicationGenSetAttrs
PASS:		*ds:si	= GenApplication object
		bp	= MetaAlterFTVMCExclFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	grab is released in parent node, and visible parent is asked
     		to ensure someone has the silly thing.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/22/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLAppReleaseSomething proc	near
	.enter
	ornf	bp, mask MAEF_NOT_HERE
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	ObjCallInstanceNoLock
	
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	VisCallParent
	.leave
	ret
OLAppReleaseSomething endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationGenSetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hack to allow an app to be non-targetable and have it affect
		things.

CALLED BY:	MSG_GEN_SET_ATTRS
PASS:		*ds:si	= GenApplication object
		ds:di	= OLApplicationInstance
		cl	= GenAttrs to set
		ch	= GenAttrs to clear
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/22/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationGenSetAttrs method dynamic OLApplicationClass, MSG_GEN_SET_ATTRS
	.enter
	call	OLAppUpdateGeodeWinFlags
	
	test	ch, mask GA_TARGETABLE
	jz	done
	test	cl, mask GA_TARGETABLE
	jnz	done
	
	mov	bp, mask MAEF_NOT_HERE or mask MAEF_TARGET
	call	OLAppReleaseSomething
done:
	.leave
	ret
OLApplicationGenSetAttrs endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLAppSpecBuildBranch

DESCRIPTION:	Intercept default handler to prevent children of app from
		being spec-built, as there's no reason for this ever to need
		to happen.

PASS:	*ds:si - instance data (vis part indirect through offset Vis_offset)
	es - segment of OLApplicationClass

	ax - MSG_SPEC_BUILD_BRANCH

	bp	- SpecBuildFlags

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/92		Initial version

------------------------------------------------------------------------------@


OLAppSpecBuildBranch	method	OLApplicationClass, MSG_SPEC_BUILD_BRANCH
	mov	ax, MSG_SPEC_BUILD
	GOTO	ObjCallInstanceNoLock
OLAppSpecBuildBranch	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLAppSpecBuild

DESCRIPTION:	Sets up visual parent for app (field or screen object)

PASS:
	*ds:si - instance data (vis part indirect through offset Vis_offset)
	es - segment of OLApplicationClass

	ax - MSG_SPEC_BUILD

	bp	- SpecBuildFlags

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

------------------------------------------------------------------------------@


OLAppSpecBuild	method	OLApplicationClass, MSG_SPEC_BUILD

	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset
	tst	ds:[di].VI_link.LP_next.handle	;If parent was already set up,
	LONG	jne exit			; don't re-init it


	; Determine what visual object application should reside on
	; (use for base windows)

	mov	cx, SQT_VIS_PARENT_FOR_APPLICATION
	mov	ax, MSG_SPEC_GUP_QUERY_VIS_PARENT
	call	GenCallParent
EC<	ERROR_NC	OL_QUERY_NOT_ANSWERED			>

	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset
	mov	ds:[di].VCNI_window, bp		; Store window that this app
						; will run on for session.

	push	cx, dx

	push	si
	mov	cx, GUQT_FIELD
	mov	ax, MSG_SPEC_GUP_QUERY
	call	ObjCallInstanceNoLock
EC <	tst	cx							>
EC <	ERROR_Z	OL_CANT_GET_SCREEN_SIZE					>
EC <	tst	dx							>
EC <	ERROR_Z	OL_CANT_GET_SCREEN_SIZE					>
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_VIS_GET_SIZE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
EC <	tst	cx							>
EC <	ERROR_Z	OL_CANT_GET_SCREEN_SIZE					>
EC <	tst	dx							>
EC <	ERROR_Z	OL_CANT_GET_SCREEN_SIZE					>
	pop	si

	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset
	mov	ds:[di].VI_bounds.R_right, cx	; Store returned size of field
	mov	ds:[di].VI_bounds.R_bottom, dx	; window, for children that
						; may need reasonable bounds
						; here.
	; Indicate these bounds are valid
	and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or \
					  mask VOF_GEO_UPDATE_PATH)
	pop	cx, dx

	;
	; Set visual upward-only link. DO NOT add as a visual child, just
	; set up a parent link only.
	;
	push	dx
	or	dx, LP_IS_PARENT			;make it a parent link!
	mov	ds:[di].VI_link.LP_next.handle, cx
	mov	ds:[di].VI_link.LP_next.chunk, dx
	pop	dx

	; Set the visual parent object we've just determined as the "parent"
	; object for the overall geode, through which focus/target will be
	; gained.
	;
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	call	WinGeodeSetParentObj

	; Create a GenItem to represent this application in the GenField's
	; ApplicationMenu. (Will have a null icon until the GenPrimary
	; is vis-built and the default moniker is copied into this block.
	; Later, the application can choose to update the moniker for this
	; GenItem object.)
	; (only allow if not in strict-compatibility mode)

	call	FlowGetUIButtonFlags	;get args from geosec.ini file
	test	al, mask UIBF_SPECIFIC_UI_COMPATIBLE
	jnz	noLawsuit

;addAppMenuListEntry:

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLAI_appMenuItems
	LONG	jnz afterAppMenuListEntry		;skip if so...

	; Before adding, making sure user's allowed to interact with it
	;
					; If not interactable, or detaching,
					; this app shouldn't be on the list.
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_DETACHING or \
					mask AS_NOT_USER_INTERACTABLE
        jnz     afterAppMenuListEntry

	; See if we actually are on a GenFieldClass object  (The UI app
	; sits under a GenScreenClass object)
	;
	mov	cx, segment GenFieldClass
	mov	dx, offset GenFieldClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	GenCallParent
	jnc	afterAppMenuListEntry	;if not, don't create blcok
						;that we'd have to get rid of

					;Add this application to our field's
					;window list
	push	si
	call	GenFindParent		;Pass ^lcx:dx as field to list our
					;app as running under
	mov	cx, bx
	mov	dx, si
	pop	si

					;Add this app to this field's list
	mov	ax, MSG_OL_APPLICATION_ADD_TO_FIELD_TASK_LIST
	call	ObjCallInstanceNoLock

afterAppMenuListEntry:

noLawsuit:

exit:
if DYNAMIC_SCREEN_RESIZING
	;
	; add our self to dynamic screen size change notification
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	push	bx
	mov	bx, cx
EC <	call	ECCheckMemHandle				>
	pop	bx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_HOST_NOTIFICATIONS
	call	GCNListAdd
endif
	ret

OLAppSpecBuild	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinVisUnbuild -- MSG_SPEC_UNBUILD
		for OLMenuedWinClass

DESCRIPTION:	Visibly unbuilds & destroys a menued window

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_SPEC_UNBUILD

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, ds, es, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@
if DYNAMIC_SCREEN_RESIZING
OLAppSpecUnbuild	method dynamic OLApplicationClass,
						MSG_SPEC_UNBUILD

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_HOST_NOTIFICATIONS
	call	GCNListRemove

	mov	di, offset OLApplicationClass
	GOTO	ObjCallSuperNoLock

OLAppSpecUnbuild	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfDefaultLauncherForField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	CheckIfDefaultLauncherForField

CALLED BY:	OLApplicationGEOSTasksListItemCreated

PASS:		*ds:si = OLApplicationClass object

RETURN:		carry clear if this app is default launcher for parent field

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfDefaultLauncherForField	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
getVarDataParams	local	GetVarDataParams
fieldGeodeToken		local	GeodeToken
ourGeodeToken		local	GeodeToken
	.enter

	;
	; if Express Menu isn't showing "Return to <default launcher>",
	; then say we aren't the default launcher so that an item will
	; be added to GEOS tasks list
	;
	call	SpecGetExpressOptions		; ax = UIExpressOptions
	test	ax, mask UIEO_RETURN_TO_DEFAULT_LAUNCHER
	jz	isntDefaultLauncher

	call	GenFindParent			; ^lbx:si = parent
	mov	getVarDataParams.GVDP_buffer.segment, ss
	lea	ax, fieldGeodeToken 
	mov	getVarDataParams.GVDP_buffer.offset, ax
	mov	getVarDataParams.GVDP_bufferSize, size GeodeToken
	mov	getVarDataParams.GVDP_dataType, \
				TEMP_GEN_FIELD_DEFAULT_LAUNCHER_ID
	mov	dx, size GetVarDataParams
	mov	ax, MSG_META_GET_VAR_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	push	bp
	lea	bp, getVarDataParams
	call	ObjMessage			; ax = -1 if not found
	pop	bp
	cmp	ax, size GeodeToken
	jne	isntDefaultLauncher
	mov	bx, ds:[LMBH_handle]
	call	MemOwner			; bx = geode
	segmov	es, ss
	lea	di, ourGeodeToken
	mov	ax, GGIT_TOKEN_ID
	call	GeodeGetInfo			; es:di = our GeodeToken
	push	ds
	segmov	ds, ss				; ds:si = field GeodeToken
	lea	si, fieldGeodeToken
	mov	cx, size GeodeToken/2
	repe cmpsw
	pop	ds
	je	done				; carry clear
isntDefaultLauncher:
	stc
done:
	.leave
	ret
CheckIfDefaultLauncherForField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationAddToFieldTaskList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	List this application on the applications running list of the
		field past.  MSG_META_NOTIFY_TASK_SELECTED is sent to these
		entries whenever the user selects them.

CALLED BY:	MSG_OL_APPLICATION_ADD_TO_FIELD_TASK_LIST
PASS:		*ds:si	= instance data
		^lcx:dx	= field to add entry to
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLApplicationAddToFieldTaskList	method dynamic	OLApplicationClass, \
				MSG_OL_APPLICATION_ADD_TO_FIELD_TASK_LIST

	; Specify an "OLAppItemClass" object to be created
	;	^lcx:dx = field where entries should be added
	;
	sub	sp, size CreateExpressMenuControlItemParams
	mov	bp, sp
	mov	ss:[bp].CEMCIP_feature, CEMCIF_GEOS_TASKS_LIST
	mov	ss:[bp].CEMCIP_class.segment, segment OLAppTaskItemClass
	mov	ss:[bp].CEMCIP_class.offset, offset OLAppTaskItemClass
	mov	ss:[bp].CEMCIP_itemPriority, CEMCIP_STANDARD_PRIORITY
	mov	ss:[bp].CEMCIP_responseMessage, MSG_OL_APPLICATION_GEOS_TASKS_LIST_ITEM_CREATED
	mov	ax, ds:[LMBH_handle]
						; send response back here
	mov	ss:[bp].CEMCIP_responseDestination.handle, ax
	mov	ss:[bp].CEMCIP_responseDestination.chunk, si
	mov	ss:[bp].CEMCIP_field.handle, cx
	mov	ss:[bp].CEMCIP_field.chunk, dx
	mov	dx, size CreateExpressMenuControlItemParams
	mov	ax, MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage			; di = event handle
	mov	cx, di				; cx = event handle
	clr	dx				; no extra data block
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_EXPRESS_MENU_OBJECTS
	clr	bp				; no cached event
	call	GCNListSend			; send to all EMCs
	add	sp, size CreateExpressMenuControlItemParams

	; THEN, add ourselves to the GCNSLT_EXPRESS_MENU_CHANGE system
	; notification list so we can create a GEOS tasks lists trigger for
	; ourselves in any new Express Menu Control objects that come along
	
	mov	cx, ds:[LMBH_handle]		; ^lcx:dx = OLApplication
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
	call	GCNListAdd
	ret

OLApplicationAddToFieldTaskList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationGEOSTasksListItemCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	New GEOS tasks list item created

CALLED BY:	MSG_OL_APPLICATION_GEOS_TASKS_LIST_ITEM_CREATED
PASS:		*ds:si	= instance data
		ss:bp = CreateExpressMenuControlItemResponseParams
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationGEOSTasksListItemCreated	method	dynamic	OLApplicationClass,
				MSG_OL_APPLICATION_GEOS_TASKS_LIST_ITEM_CREATED

						; save optrs for later
	pushdw	ss:[bp].CEMCIRP_expressMenuControl
	pushdw	ss:[bp].CEMCIRP_newItem

	; Set object usable
	;
	push	si

	;
	; if we are default launcher, don't set item usable, but still create
	; it, as we need to be able to set no-exclusive in the GEOS tasks list
	; when this app is active
	;
	call	CheckIfDefaultLauncherForField
	jnc	afterUsable	; yes, skip usable

	movdw	bxsi, ss:[bp].CEMCIRP_newItem
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS		; no MF_CALL!
	call	ObjMessage
afterUsable:
	pop	bp				; *ds:bp = OLApplication

	; Save away optr of object just created
	;	*ds:bp = OLApplication
	;
	mov	di, ds:[bp]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLAI_appMenuItems
	tst	si
	jnz	haveArray
	mov	bx, size CreateExpressMenuControlItemResponseParams
	mov	cx, 0				; no extra header space
	mov	si, 0				; allocate new chunk
	mov	al, mask OCF_IGNORE_DIRTY
	call	ChunkArrayCreate
	mov	di, ds:[bp]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLAI_appMenuItems, si	; save new chunk array
haveArray:
	call	ChunkArrayAppend		; ds:di = new entry
	popdw	ds:[di].CEMCIRP_newItem
	popdw	ds:[di].CEMCIRP_expressMenuControl

	; Set moniker of Task Entry to be a copy of the app moniker.
	;	*ds:bp = OLApplication
	;
	mov	di, ds:[bp]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[LMBH_handle]
	mov	dx, ds:[di].GI_visMoniker
	mov	ax, MSG_GEN_APPLICATION_SET_TASK_ENTRY_MONIKER
	mov	si, bp				; *ds:si = OLApplication
	call	ObjCallInstanceNoLock

	; & update the entry's status
	;
	mov	ax, MSG_META_GET_TARGET_EXCL
	call	GenCallParent			; ^lcx:dx = target app
	cmp	cx, ds:[LMBH_handle]
	mov	cx, FALSE			; assume not target
	jne	haveTargetState
	cmp	dx, si
	jne	haveTargetState
	mov	cx, TRUE			; IS target!
haveTargetState:
	mov	ax,  MSG_OL_APP_UPDATE_TASK_ENTRY
	call	ObjCallInstanceNoLock
	ret
OLApplicationGEOSTasksListItemCreated	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationOpenWin -- 
		MSG_VIS_OPEN_WIN for OLApplicationClass

DESCRIPTION:	Opens a window for this object.  Basically we subclass and
		duplicate the content behavior here so we can avoid invalidating
		the parent window (it's not desirable).

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_OPEN_WIN
		bp	- 0

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
	chris	12/15/92         	Initial Version

------------------------------------------------------------------------------@

OLApplicationOpenWin	method dynamic	OLApplicationClass, \
				MSG_VIS_OPEN_WIN
	mov	ax, ds:[di].VCNI_window		; fetch window to use
	mov	ds:[di].VCI_window, ax		; store window handle here

	; Set up this object, on opened window, as the implied grab
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, ds:[di].VCNI_window	; get window
	mov	ax, MSG_META_IMPLIED_WIN_CHANGE
	call	ObjCallInstanceNoLock
	Destroy	ax, cx, dx, bp
	ret
OLApplicationOpenWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationOpenComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ensure that modal window, if any, is given focus/target

CALLED BY:	MSG_GEN_APPLICATION_OPEN_COMPLETE

PASS:		*ds:si	= OLApplicationClass object
		ds:di	= OLApplicationClass instance data
		es 	= segment of OLApplicationClass
		ax	= MSG_GEN_APPLICATION_OPEN_COMPLETE

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/8/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationOpenComplete	method	dynamic	OLApplicationClass,
					MSG_GEN_APPLICATION_OPEN_COMPLETE

	;
	; find sys-modal or app-modal window
	;
	call	AppFindTopSysModalWin	; First check for a system modal window
	tst	cx
	jnz	haveWindow
	mov	cl, WIN_PRIO_MODAL	; Look for MODAL priority windows
	call	AppFindTopWinOfPriority	; Then check for an app-modal window
haveWindow:
	jcxz	done			; no modal window
	;
	; give focus/target to modal window
	;
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	ret
OLApplicationOpenComplete	endm

AppAttach	ends

;----------------------






;-------------------------------

AppDetach segment resource





COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationCloseWin -- 
		MSG_VIS_CLOSE_WIN for OLApplicationClass

DESCRIPTION:	Closes the application.  Subclassed here to avoid invalidation.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_CLOSE_WIN

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
	chris	2/24/93         Initial Version

------------------------------------------------------------------------------@

OLApplicationCloseWin	method dynamic	OLApplicationClass, \
				MSG_VIS_CLOSE_WIN

	;	
	; Code copied from VisContent's superclass.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].VCI_window, 0		;NULL out window handle here

	; Then null out the implied grab, this object, since it no longer
	; has a window associated with it.
	;
	clr	cx
	clr	dx
	clr	bp
	mov	ax, MSG_META_IMPLIED_WIN_CHANGE
	GOTO	ObjCallInstanceNoLock

OLApplicationCloseWin	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NukeUserDoDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nukes the passed UserDoDialog

CALLED BY:	OLApplicationRemoveAllBlockingDialogs via ChunkArrayEnum
PASS:		ds:di - ptr to optr of dialog box
RETURN:		carry clear
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NukeUserDoDialog	proc	far
	.enter
	movdw	bxsi, ds:[di]
	mov	ax, MSG_GEN_INTERACTION_RELEASE_BLOCKED_THREAD_WITH_RESPONSE
	mov	cx, IC_NULL
	call	ObjMessageCallFixupDS
	
	mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	mov	cx, IC_DISMISS
	call	ObjMessageCallFixupDS
	clc
	.leave
	ret
NukeUserDoDialog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationCheckIfRunningUserDoDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if a UserDoDialog is onscreen

CALLED BY:	GLOBAL
PASS:		*ds:si - OLApp
RETURN:		ax - non-zero if UserDoDialogs exist
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 5/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationCheckIfRunningUserDoDialog	method	OLApplicationClass,
			MSG_GEN_APPLICATION_CHECK_IF_RUNNING_USER_DO_DIALOG
	.enter
	call	Get_GAGCNLT_USER_DO_DIALOGS_List
	mov	ax, 0			;Don't change to "clr"!
	jnc	exit			;Exit if no GCNList
	call	ChunkArrayGetCount
	mov_tr	ax, cx			;AX <- non-zero if items on list
exit:
	.leave
	ret
OLApplicationCheckIfRunningUserDoDialog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Get_GAGCNLT_USER_DO_DIALOGS_List
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the chunk array of items on the GAGCNLT_USER_DO_DIALOGS
		GCN list

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		carry set if list found
		*ds:si - GCNList
DESTROYED:	ax, bx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 5/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Get_GAGCNLT_USER_DO_DIALOGS_List	proc	near
	.enter
	mov	ax, TEMP_META_GCN	;
	call	ObjVarFindData		;
	jnc	exit			;If no GCN lists, exit
	
	mov	di, ds:[bx].TMGCND_listOfLists
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GAGCNLT_USER_DO_DIALOGS
	clc				;Don't create list
	call	GCNListFindListInBlock
exit:
	.leave
	ret
Get_GAGCNLT_USER_DO_DIALOGS_List	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationDetachPending

DESCRIPTION:	Notification that the application is about to be detached.

PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass

	ax - MSG_GEN_APPLICATION_DETACH_PENDING

	cx, dx, bp	- ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/90		Initial version

------------------------------------------------------------------------------@


OLApplicationDetachPending	method dynamic	OLApplicationClass, \
					MSG_GEN_APPLICATION_DETACH_PENDING

	
	; Remove any standard dialog app modal dialog box that may be up &
	; running, & all UserDoDialogs  
	;
	call	OLApplicationRemoveAllBlockingDialogs

	;kill our GEOS task list entries
	;
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	si
	xchg	si, ds:[di].OLAI_appMenuItems
	tst	si
	jz	next			;skip if none...

	mov	bx, cs
	mov	di, offset OLADP_callback
	call	ChunkArrayEnum

next:

	; remove ourselves from the GCNSLT_EXPRESS_MENU_CHANGE system
	; notification list
	
	pop	si		; *ds:si = OLApplication


	mov	cx, ds:[LMBH_handle]		; ^lcx:dx = OLApplication
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
	call	GCNListRemove

				; Start ignoring input for this application,
				; forever... (i.e. don't let any more mouse
				; or kbd data in here as long as the app is
				; still in the system)
				;
				; QUESTION:  What do we do about input directed
				; at a non-UserDoDialog modal dialog box?  Does
				; it matter?  Say, what if he hits a trigger
				; that puts up another window, half-way through
				; detach?   Hmmm...

	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	call	ObjCallInstanceNoLock

	; Stuff GeodeWinFlags w/NOT focusable, targetable, or modelable any
	; more, i.e. make it impossible for the Field to decide that we're
	; the "best choice" to give the focus/target to, & prevent us from
	; getting the focus/target if we're clicked in.
	;
	clr	ax
	call	GeodeGetProcessHandle
	call	WinGeodeSetFlags

	; Release focus, target, model exclusives & have GenField figure out
	; which app these should now move on to.
	;
	mov	ax, MSG_GEN_LOWER_TO_BOTTOM
	GOTO	ObjCallInstanceNoLock


OLApplicationDetachPending	endm

;
; pass:		*ds:si = chunk array
;		ds:di = CreateExpressMenuControlItemResponseParams
; return:	carry clear to continue enumeration
;
OLADP_callback	proc	far
	movdw	cxdx, ds:[di].CEMCIRP_newItem
	movdw	bxsi, ds:[di].CEMCIRP_expressMenuControl
	mov	ax, MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM
	mov	bp, VUM_NOW
	mov	di, mask MF_FIXUP_DS		; no MF_CALL!
	call	ObjMessage
	clc
	ret
OLADP_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendFoamNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends out the passed notification to the 
		GAGCNLT_FOAM_NOTIFICATIONS GCN list

CALLED BY:	GLOBAL
PASS:		dx - GeoWorksNotificationType
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationLostFullScreenExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Intercept notification that we're about to be hidden from
		the user, effectively thrown into the app cache, where we'll
		either be transparently detached or called back to the
		front, that is, unless we have stated that we can't be
		detached this way.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_LOST_FULL_SCREEN_EXCL

		nothing

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationLostFullScreenExcl	method dynamic	OLApplicationClass,
				MSG_META_LOST_FULL_SCREEN_EXCL

	; Take down any thread-blocking dialogs, so that we can receive
	; IACP messages requesting that we come back up.  Also keeps us
	; from keeping code blocks locked, & gives the user a consistent
	; interface w/regards to these dialogs being dismissed -- they
	; are already dismissed on transparent detach, now they are
	; dismissed anytime the app is switched away from.
	;
	FALL_THRU	OLApplicationRemoveAllBlockingDialogs

OLApplicationLostFullScreenExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationRemoveAllBlockingDialogs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take down all thread-blocking dialogs from the screen,
		forcing return values of IC_NULL in all of them.  This
		is done at DETACH, & also on Zoomer when full-screen apps
		are switched away from (so that they can respond to IACP
		messages such as requesting that they come back to the top,
		as well as letting their code finish & return to idle,
		keep blocks from being permanently locked)

CALLED BY:	INTERNAL
		OLApplicationDetachPending
PASS:		*ds:si	- OLApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/93		Split out from OLApplicationDetachPending
	chrisb  2/94		made this a method
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLApplicationRemoveAllBlockingDialogs	method OLApplicationClass,
			MSG_GEN_APPLICATION_REMOVE_ALL_BLOCKING_DIALOGS

	; Remove any standard dialog app modal dialog box that may be up &
	; running
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	push	ds:[di].OLAI_stdDialogs
nukeStdDialogLoop:
	pop	bx
	tst	bx
	jz	nukeUserDoDialogs
	mov	di, ds:[bx]
	push	ds:[di].OLASD_next		; save next
	mov	dx, bx				; pass data in DX
	mov	cx, IC_NULL			; and response in CX
	mov	ax, MSG_OL_APP_DO_DIALOG_RESPONSE
	call	ObjCallInstanceNoLock
	jmp	nukeStdDialogLoop

nukeUserDoDialogs:

;	Nuke all dialogs on the GAGCNLT_USER_DO_DIALOGS gcn list.

	push	si
	call	Get_GAGCNLT_USER_DO_DIALOGS_List
	jnc	noDialogs

	clr	ax
	mov	bx, cs
	mov	di, offset NukeUserDoDialog
	call	ChunkArrayEnum

noDialogs:
	pop	si

afterUserDoDialogsDown:

	ret
OLApplicationRemoveAllBlockingDialogs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationTransparentDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Deal specially with anything extra that needs to be done
		for a transparent detach

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_TRANSPARENT_DETACH

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationTransparentDetach	method dynamic	OLApplicationClass,
					MSG_META_TRANSPARENT_DETACH
	; We're being transparently detached.  We are either up on screen
	; being used as a desk accessory (& thereby a decision was made 
	; somewhere along the way that this would be allowed), or we're
	; in the background, being "app-cached".  When we come back, we'll
	; come back from state, but want to come back as a desk acessory,
	; not where we were.  To ensure this, nuke the one reference to
	; being in an app-cached state, a STD custom layer priority.  If
	; we aren't in an app-cached state, or don't have a funny priority,
	; aren't a desk accessory, etc., this doesn't matter, as the
	; desired value will just be set for us on the next attach.  We
	; *don't* do this if actually being detached, such as exiting to
	; DOS & restoring, so we will be correctly remembered as being in
	; a "cached" state, & not at the forefront of the screen.  -- Doug 4/93
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
	call	ObjVarDeleteData

if LIMITED_HEAPSPACE
	;
	; Disabling the express menu to avoid transparent detach problems.
	; Is enabled again in final shutdown.
	;
	mov	ax, MSG_GEN_FIELD_DISABLE_EXPRESS_MENU
	call	GenCallParent
endif
	ret
OLApplicationTransparentDetach	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationDetach -- MSG_META_DETACH for
					   OLApplicationClass

DESCRIPTION:	Start up an open look application

PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass

	ax - MSG_META_DETACH

	cx, dx, bp	- ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		Initial version

------------------------------------------------------------------------------@


OLApplicationDetach	method dynamic	OLApplicationClass, MSG_META_DETACH

	mov	di, offset OLApplicationClass
	CallSuper	MSG_META_DETACH

	clr	cl
	mov	ch, mask SA_ATTACHED	; no longer attached
	mov	ax, MSG_SPEC_SET_ATTRS
	mov	dl, VUM_NOW		; update mode
	call	ObjCallInstanceNoLock

;freed when geode exits
;	call	AppFreeGCNListBlock

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_HOST_NOTIFICATIONS
	call	GCNListRemove

	ret

OLApplicationDetach	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle F3 by quitting or shutting down (if UILM_TRANSPARENT)

CALLED BY:	MSG_OL_APPLICATION_QUIT

PASS:		*ds:si	= OLApplicationClass object
		ds:di	= OLApplicationClass instance data
		es 	= segment of OLApplicationClass
		ax	= MSG_OL_APPLICATION_QUIT

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/30/92  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationQuit	method	dynamic	OLApplicationClass,
							MSG_OL_APPLICATION_QUIT

	; Just quit if standard launch mode.
	;
	call	UserGetLaunchModel	;ax = UILaunchModel
	cmp	ax, UILM_TRANSPARENT
	jne	quit

	call	UserGetLaunchOptions
	test	ax, mask UILO_CLOSABLE_APPS
	jz	moveToBack
quit:
	mov	ax, MSG_META_QUIT
	GOTO	ObjCallInstanceNoLock

moveToBack:
	;
	; If this is a DA running ON_TOP, drop the priority to standard,
	; so we can hide in back as with other apps in the app cache.
	;
	call	OLAppLowerLayerPrioIfDeskAccessory

	; Now lower to bottom to force focus/target change
	;
	mov	bx, ds:[LMBH_handle]
	mov     ax, MSG_GEN_LOWER_TO_BOTTOM
	mov     di, mask MF_FORCE_QUEUE
	GOTO    ObjMessage

OLApplicationQuit	endm


AppDetach ends
