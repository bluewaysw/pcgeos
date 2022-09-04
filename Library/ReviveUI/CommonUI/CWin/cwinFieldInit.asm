COMMENT @--------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinFieldInit.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_INITIALIZE     Initialize a field object

    MTD MSG_GEN_LOAD_OPTIONS    load options for the specific UI

    MTD MSG_SPEC_BUILD          Visually build a field object

    INT FakeField               Check .ini file for fake field sizes to
				use.  If found, substitute here. If the
				continueSetup boolean equals true, we
				ignore any size.

    INT OLFieldEnsureExpressMenu 
				This procedure creates the ExpressMenu for
				the OLField if not done already.

    INT OLFieldEnsureWindowListDialog 
				This procedure creates the Window List
				Dialog for the OLField if not done already.

    INT OLFieldEnsureToolArea   This procedure creates the ToolArea for the
				OLField if not done already.

    MTD MSG_GEN_FIELD_CREATE_EXPRESS_MENU 
				Creates the default workspace menu.

    MTD MSG_GEN_FIELD_CREATE_SPECIFIC_WORKSPACE_SUBGROUP 
				Creates the UI specific portion of the
				Express menu

    INT BuildExpressMenuAppletList 
				Add applet list to express menu

    INT AddAppletToAppletList   Add a GenTrigger to the Applet List.

    INT BuildAppletListClassCallBack 
				Callback function for a class (class the
				student is in)

    INT BuildAppletListCoursewareCallBack 
				Callback function for courseware

    MTD MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM 
				Prevent screen lock button from being added
				if user does not have permission.

    MTD MSG_VIS_OPEN_WIN        Open the field window

    INT MaybeMoveField          See if we need to move the field, and if
				so, do so.

    INT OLFieldEnsureStickyMonitor 
				Install an input monitor to intercept
				sticky-key presses.

    MTD MSG_SPEC_UNBUILD        Remove input monitor.

    INT OLStickyRoutine         Process sticky keys.

    INT SendKeyboardEventGCN    send GCN notification for sticky state

    MTD MSG_OL_FIELD_SEND_KEYBOARD_EVENT_GCN 
				send out GCN notification

    INT OLAdjustContrast        Adjust contrast setting

    INT OLPowerOnOff            Turn the device Off (probably)

    MTD MSG_META_NOTIFY         handle changes in HWR input mode

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cwinField.asm


DESCRIPTION:

	$Id: cwinFieldInit.asm,v 1.38 97/04/02 03:28:20 joon Exp $

------------------------------------------------------------------------------@
Init	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldInitialize -- MSG_META_INITIALIZE for OLFieldClass

DESCRIPTION:	Initialize a field object

PASS:
	*ds:si - instance data (for object in OLField class)
	es - segment of OLFieldClass

	ax - MSG_*

	cx, dx, bp - ?

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
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


OLFieldInitialize	method	dynamic OLFieldClass, MSG_META_INITIALIZE

	CallMod	VisCompInitialize

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di is VisInstance

				; Mark this object as being a window & a group
	ORNF	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW or \
					mask VTF_IS_WIN_GROUP or \
					mask VTF_IS_INPUT_NODE
				; Mark as realizable (it is not yet attached)
	ORNF	ds:[di].VI_specAttrs, mask SA_REALIZABLE

				; Mark as NOT managed by parent
	ANDNF	ds:[di].VI_attrs, not mask VA_MANAGED
				; Children should NOT be geometrically
				;	managed.
	ORNF	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN

	ret

OLFieldInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	load options for the specific UI

PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		es	= dgroup

		ss:bp - GenOptionsParams

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

	Moved here from OLFieldInitialize, so that the call can be
made AFTER the GenFieldAttach handler is called.  This is
necessary because the GenField handler loads some options that the
specific UI uses. -chrisb 10/92.

 Also, see earlier comment from Doug:

These need to be called from here, as in most cases the info needed to
properly evaluate these preferences was not available at the time
these routines were called from the specific UI library init routine.

The reason is that the generic UI loads the specific UI, then builds
the initial screen, after which the DisplayType variable is
initialized, after which UserGetDisplayType, which these routines rely
on, may be used.	- doug 2/11/92


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLFieldLoadOptions	method	dynamic	OLFieldClass, MSG_GEN_LOAD_OPTIONS

	;
	; These routines will all get called whenever a new field is
	; being attached. (XXX: Assumes only one field can be attached
	; at a time.)

	segmov	ds, ss
	lea	si, ss:[bp].GOP_category

	call	SpecInitDefaultDisplayScheme	; Init defaultDisplayScheme
	call	SpecInitGadgetPreferences	; Init gadget preferences
	call	SpecInitWindowPreferences	; Init window preferences
	call	SpecInitDocumentControl
	call	SpecInitExpressPreferences
	call	SpecInitHelpPreferences
	ret
OLFieldLoadOptions	endm




COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldSpecBuild -- MSG_SPEC_BUILD for OLFieldClass

DESCRIPTION:	Visually build a field object

PASS:
	*ds:si - instance data (for object in OLField class)
	es - segment of OLFieldClass

	ax - MSG_SPEC_BUILD
	bp - SpecBuildFlags

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version

------------------------------------------------------------------------------@


OLFieldSpecBuild	method	dynamic OLFieldClass, MSG_SPEC_BUILD

EC<	call	VisCheckVisAssumption	; Make sure vis data exists >
				; If already vis built, quit.
	call	VisCheckIfSpecBuilt
	jnc	10$
	ret
10$:
				; Do visible BUILD
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
				; onto visible parent, as stored in instance
	mov	cx, ds:[di].GFI_visParent.handle
	mov	dx, ds:[di].GFI_visParent.chunk
	tst	cx
	jnz	HaveVisParent

	mov	cx, SQT_VIS_PARENT_FOR_FIELD
	mov	ax, MSG_SPEC_GUP_QUERY_VIS_PARENT
	call	GenCallParent
EC<	ERROR_NC	OL_ERROR				>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GFI_visParent.handle, cx
	mov	ds:[di].GFI_visParent.chunk, dx
	; NO NEED to mark dirty, as is cleared out at DETACH time
	; anyway.

HaveVisParent:
	mov	bx, cx
	mov	si, dx
				; Add this field object
	mov	cx, ds:[LMBH_handle]
	pop	dx
	push	dx
	mov	bp, CCO_LAST
	mov	ax, MSG_VIS_ADD_CHILD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

					; get size of screen window
	push	si
	mov	ax, MSG_VIS_GET_SIZE
	mov	bx, segment VisClass	;set to the base class that can handle 
	mov	si, offset VisClass	;  the message in ax
	mov	di, mask MF_RECORD 
	call	ObjMessage
	mov	cx, di		; Get handle to ClassedEvent in cx
	pop	si		; Get object 
	mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP
	call	VisCallParent
	
					; cx, dx = size of screen window
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance

					; Store new bounds data
	mov	ds:[di].VI_bounds.R_right, cx
	mov	ds:[di].VI_bounds.R_bottom, dx


if FAKE_SIZE_OPTIONS
	call	FakeField
endif
					; Mark window as not valid (At WG,
					; so don't need VisMarkInvalid)
	or	ds:[di].VI_optFlags, mask VOF_WINDOW_INVALID

if _CUA_STYLE	;---------------------------------------------------------------
	;
	; Now set the resize border sizes for windows in this field.
	push	ds
	mov	ax, segment idata
	mov	ds, ax
	;
	; Assume it's a non-CGA screen.
	mov	ax, CUAS_WIN_RESIZE_BORDER_SIZE
	mov	ds:[resizeBarHeight], ax
	mov	ds:[resizeBarWidth], ax

	mov	ax, CUAS_WIN_RESIZE_BORDER_TINY_SIZE
	call	OpenCheckIfCGA			; Using a CGA display?
	jnc	notCGA
	mov	ds:[resizeBarHeight], ax
notCGA:
	call	OpenCheckIfNarrow		; See if a narrow display
	jnc	notNarrow
	mov	ds:[resizeBarWidth], ax
notNarrow:
	pop	ds
endif		;---------------------------------------------------------------

	;now create the workspace menu, since applications will want to
	;displays its' menu button when they get the focus.
	;(only allow pinnable menus if not in strict-compatibility mode)

	call	FlowGetUIButtonFlags	;get args from geosec.ini file
	test	al, mask UIBF_SPECIFIC_UI_COMPATIBLE
	jnz	afterExpressMenu

	call	OLFieldEnsureExpressMenu

afterExpressMenu:

if EVENT_MENU
	call	OLFieldEnsureEventMenu
endif

PMAN <	call	OLFieldEnsureWindowListDialog				>

JEDI <	call	OLFieldEnsureStickyMonitor				>

if _JEDIMOTIF and SYNC_HWR_AND_KBD
	;
	; add ourselves to JGCNSLT_NOTIFY_HWR_INPUT_MODE_CHANGE so
	; we can detect HWR mode changes and update the physical kbd
	; state
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_HP
	mov	ax, JGCNSLT_NOTIFY_HWR_INPUT_MODE_CHANGE
	call	GCNListAdd
endif

	ret

OLFieldSpecBuild	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	FakeField

DESCRIPTION:	Check .ini file for fake field sizes to use.  If found,
		substitute here. If the continueSetup boolean equals true,
		we ignore any size.

CALLED BY:	INTERNAL
		OLFieldSpecBuild

PASS:		*ds:si	- field object
		ds:di	- field object
		cx, dx	- size of field so far

RETURN:		visible bounds - possibly altered
		*ds:si	- field object
		ds:di	- field object

DESTROYED:	nothing
------------------------------------------------------------------------------@
if FAKE_SIZE_OPTIONS
FakeField		proc	near	uses ax, bx, cx, dx, bp

	.enter

	mov	ax, cx			; move cur size to ax, bx
	mov	bx, dx

	push	ds, si

	mov	cx, cs
	mov	ds, cx

	mov	si, offset systemCategoryStr

	push	ax
	mov	dx, offset continueSetupStr
	clr	bp			;Clear "make tiny" flag
	call	InitFileReadBoolean
	jc	10$
	tst	ax
	jnz	afterSized		; if we're in SETUP, don't change size
10$:
	pop	ax			

	mov	si, offset screenSizeCategoryStr

	mov	dx, offset xFieldSizeStr
	call	InitFileReadInteger

	xchg	ax, bx

	mov	dx, offset yFieldSizeStr
	call	InitFileReadInteger

	xchg	ax, bx

	push	ax

afterSized:
	pop	ax

	pop	ds, si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].VI_bounds.R_right, ax
	mov	ds:[di].VI_bounds.R_bottom, bx

	.leave
	ret

FakeField		endp

systemCategoryStr	char	"system", 0
continueSetupStr	char	"continueSetup", 0

screenSizeCategoryStr	char	"ui", 0
xFieldSizeStr		char	"xFieldSize", 0
yFieldSizeStr		char	"yFieldSize", 0

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLFieldEnsureExpressMenu

DESCRIPTION:	This procedure creates the ExpressMenu for the OLField
		if not done already.

CALLED BY:	OLFieldSpecBuild

PASS:		ds:*si	- instance data

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OLFieldEnsureExpressMenu	proc	far
	;See if we have already created a  Express menu

	mov	di, ds:[si]
	mov	bp, di
	add	di, ds:[di].Vis_offset	;ds:di = SpecificInstance
	tst	ds:[di].OLFI_expressMenu
	jnz	done			;skip if so...

	add	bp, ds:[bp].Gen_offset
	test	ds:[bp].GFI_flags, mask GFF_NEEDS_WORKSPACE_MENU
	jz	done

	call	SpecGetExpressOptions	; ax = UIExpressOptions
	andnf	ax, mask UIEO_POSITION
	cmp	ax, UIEP_NONE shl offset UIEO_POSITION
	je	done

	call	OLFieldEnsureToolArea	;Get area to place express menu into
					;cx:dx = Generic parent for expressmenu

if APPLICATION_MENU

	call	OLFieldEnsureAppMenu

else	; not APPLICATION_MENU

	clr	bp			;pass CompChildFlags
	mov	ax, MSG_GEN_FIELD_CREATE_EXPRESS_MENU
	call	ObjCallInstanceNoLock

endif	; APPLICATION_MENU

if _REDMOTIF
	push	si, dx
	mov	si, dx			
	mov	ax, MSG_GEN_FIND_PARENT
	call	ObjCallInstanceNoLock
	mov	cx, dx
	pop	si, dx

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLFI_expressMenu2, dx	; store chunk handle of menu
	mov	ds:[di].OLFI_expressMenu, cx	; store chunk handle of eMenu2
else
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLFI_expressMenu, dx	; store chunk handle of menu
endif

if _NIKE
	mov	ax, MSG_OL_FIELD_UPDATE_KBD_STATUS_BUTTONS
	GOTO	ObjCallInstanceNoLock
endif

done:
	ret
OLFieldEnsureExpressMenu	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldEnsureEventMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ensure we have an event menu

CALLED BY:	INTERNAL
			OLFieldSpecBuild
PASS:		*ds:si = OLField
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if EVENT_MENU

OLFieldEnsureEventMenu	proc	near
	uses	si
	.enter
	;
	; if event menu already created or if we don't need one, done
	;
	mov	di, ds:[si]
	mov	bp, di
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLFI_eventMenu
	LONG jnz	done
	add	bp, ds:[bp].Gen_offset
	test	ds:[bp].GFI_flags, mask GFF_NEEDS_WORKSPACE_MENU
	LONG jz	done
	;
	; create event menu under its tool area
	;	*ds:si = OLField
	;
	push	si			; save field
	call	OLFieldEnsureEventToolArea ; ^lcx:dx = tool area for event menu
	mov	di, segment EventMenuClass
	mov	es, di			; es:di = class
	mov	di, offset EventMenuClass
	mov	bx, cx			; bx = block to allocate in
	call	GenInstantiateIgnoreDirty ; ^lbx:si = ^lcx:si = event menu
	xchg	dx, si			; ^lcx:dx = new event menu
	mov	bx, cx			; ^lbx:si = parent for object
	mov	ax, MSG_GEN_ADD_CHILD
	clr	bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	;
	; store event menu away
	;	^lcx:dx = event menu
	;
	pop	si			; *ds:si = field
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLFI_eventMenu, dx	; store chunk handle of menu
	;
	; add event menu to active list
	;	^lcx:dx = event menu
	;
	sub	sp, size GCNListParams
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST
	movdw	ss:[bp].GCNLP_optr, cxdx
	mov	dx, size GCNListParams
	mov	ax, MSG_META_GCN_LIST_ADD
	call	UserCallApplication
	add	sp, size GCNListParams
	;
	; set event menu usable
	;	^lcx:dx = event menu
	;
	movdw	bxsi, cxdx		; ^lbx:si = event menu
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	;
	; ugh, add HINT_EVENT_MENU, etc. to event list menu
	;
done:
	.leave
	ret
OLFieldEnsureEventMenu	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMEhUpdateEventList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make sure event menu button positions and draws correctly

CALLED BY:	MSG_EH_UPDATE_EVENT_LIST
PASS:		*ds:si	= EventMenuClass object
		ds:di	= EventMenuClass instance data
		ds:bx	= EventMenuClass object (same as *ds:si)
		es 	= segment of EventMenuClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMEhUpdateEventList	method dynamic EventMenuClass, 
					MSG_EH_UPDATE_EVENT_LIST
	;
	; call superclass for normal handling
	;
	mov	di, offset EventMenuClass
	call	ObjCallSuperNoLock
	;
	; notify the current focus primary of a change in the event menu
	; button in the title bar (size may change)
	;
	mov	bx, segment OLBaseWinClass
	mov	si, offset OLBaseWinClass
	mov	ax, MSG_OL_BASE_WIN_UPDATE_TOOL_AREAS
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	mov	cx, di				; cx = event
	;
	; send to model app to send to its focused primary
	;
	mov	bx, segment GenApplicationClass
	mov	si, offset GenApplicationClass
	mov	dx, TO_FOCUS
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	mov	cx, di				; cx = event
	;
	; send to system to send to model app
	;
	mov	dx, TO_MODEL
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	UserCallSystem
	.leave
	ret
EMEhUpdateEventList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMEhModifyEventMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	mark event menu as such

CALLED BY:	MSG_EH_MODIFY_EVENT_MENU
PASS:		*ds:si	= EventMenuClass object
		ds:di	= EventMenuClass instance data
		ds:bx	= EventMenuClass object (same as *ds:si)
		es 	= segment of EventMenuClass
		ax	= message #
		^lcx:dx = event menu
		bp 	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMEhModifyEventMenu	method dynamic EventMenuClass, 
					MSG_EH_MODIFY_EVENT_MENU

	test	bp, mask SBF_WIN_GROUP	; ignore win group changes
	jnz	done
	;
	; set some hints for the menu
	;
	movdw	bxsi, cxdx
	call	ObjSwapLock		; *ds:si = event menu
	push	bx
	mov	ax, HINT_EVENT_MENU
	clr	cx
	call	ObjVarAddData
	mov	ax, HINT_CAN_CLIP_MONIKER_HEIGHT
	call	ObjVarAddData
	mov	ax, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
	call	ObjVarAddData
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
	mov	cx, size word
	call	ObjVarAddData
	mov	{word}ds:[bx], 0
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
	call	ObjVarAddData
	mov	{word}ds:[bx], LAYER_PRIO_ON_TOP-1
	mov	ax, MSG_GEN_SET_KBD_ACCELERATOR
SBCS <	mov	cx, KeyboardShortcut<0, 0, 0, 0, 0xf, VC_F11>		>
DBCS <	mov	cx, KeyboardShortcut<0, 0, 0, 0, C_SYS_F11 and mask KS_CHAR>>
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock
	pop	bx
	call	ObjSwapUnlock
done:
	ret
EMEhModifyEventMenu	endm

endif	; EVENT_MENU


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLFieldEnsureWindowListDialog

DESCRIPTION:	This procedure creates the Window List Dialog for the OLField
		if not done already.

CALLED BY:	OLFieldSpecBuild

PASS:		ds:*si	- instance data

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version
	Joon	11/92		changed to create a Window List

------------------------------------------------------------------------------@

if _PM ;---------------------------------------------------------------------

OLFieldEnsureWindowListDialog	proc	far

	mov	di, ds:[si]
	mov	bp, di
	add	di, ds:[di].Vis_offset	;ds:di = SpecificInstance
	tst	ds:[di].OLFI_windowListDialog
	LONG	jnz	done		;skip if so...

	add	bp, ds:[bp].Gen_offset
	test	ds:[bp].GFI_flags, mask GFF_NEEDS_WORKSPACE_MENU
	LONG	jz	done

	; Before sending first message to Window List Dialog, make sure it is
	; marked as being run by the global UI thread.
	;
	mov	bx, handle ui
	call	ProcInfo
	mov	ax, bx
	mov	bx, handle WindowListResource
	call	MemModifyOtherInfo

	push	si			; save field chunk

	; Create it.
	;
	mov	cx, ds:[LMBH_handle]	; block to copy into
	clr	dx
	mov	bx, handle WinListDialog
	mov	si, offset WinListDialog
	mov	ax, MSG_GEN_COPY_TREE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	clr	bp		; no special CompChildFlags
	call	ObjMessage		; ^lcx:dx = window dialog
EC <	cmp	cx, ds:[LMBH_handle]					>
EC <	ERROR_NE	OL_ERROR					>

	; Replace all "OLTPT_FIELD" params in menu with the real field OD
	;
	mov	si, dx			; *ds:si = window dialog
	mov	bp, OLTPT_FIELD		; replace this constant
	mov	cx, ds:[LMBH_handle]	; ^cx:dx = field optr to replace with
	pop	dx
	push	dx			; save field chunk again
	mov	ax, MSG_GEN_BRANCH_REPLACE_OUTPUT_OPTR_CONSTANT
	call	ObjCallInstanceNoLock

ifdef WIZARDBA	;--------------------------------------------------------------
	call	UserGetDefaultUILevel
		CheckHack <UIIL_INTRODUCTORY eq 0>
	tst	ax
	jnz	notInEntryLevel
	;
	; We make the window list not resizable and not movable to match
	; entry level requirements.  (If you want to make changes here,
	; make sure you update the hints specified for the window list in
	; cspecCUAS.ui.)
	;
	mov	ax, HINT_INTERACTION_MAKE_RESIZABLE
	call	ObjVarDeleteData
	mov	ax, HINT_INTERACTION_MAXIMIZABLE
	call	ObjVarDeleteData
	mov	ax, HINT_NOT_MOVABLE
	clr	cx
	call	ObjVarAddData
notInEntryLevel:
endif		;--------------------------------------------------------------

	mov	cx, ds:[LMBH_handle]	; ^lcx:dx = window dialog
	mov	dx, si
	pop	si			; *ds:si = field

	; Setup Floating tool are to have a one-way upward link to field
	;
	call	GenAddChildUpwardLinkOnly
					; ^lcx:dx is new window dialog
	push	dx			; save window dialog chunk

	push	si			; save field chunk
	mov	si, dx			; *ds:si = window dialog
	;
	; get lptr of window list (1st child of dialog)
	;
	clr	cx
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock	; ^lcx:dx = window list
EC <	ERROR_C	OL_ERROR						>
EC <	cmp	cx, ds:[LMBH_handle]					>
EC <	ERROR_NE	OL_ERROR					>
	pop	si			; *ds:si = field

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
					; store chunk handle of window dialog
	mov	ds:[di].OLFI_windowListList, dx
	pop	ds:[di].OLFI_windowListDialog
ifdef WIZARDBA
	;
	; build the control panel now, so that we don't get ugly additions
	; to it when the user brings up the window list
	;
	push	si
	mov	si, ds:[di].OLFI_windowListDialog
	mov	cx, 1
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock	; ^lcx:dx = control panel

EC <	ERROR_C	OL_ERROR						>
EC <	cmp	cx, ds:[LMBH_handle]					>
EC <	ERROR_NE	OL_ERROR					>

EC <	push	es, di							>
EC <	mov	di, segment ExpressMenuControlClass			>
EC <	mov	es, di							>
EC <	mov	di, offset ExpressMenuControlClass			>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_C	OL_ERROR		; not ExpressMenuControl	>
EC <	pop	es, di							>

	push	dx			; save control panel chunk
	mov	si, dx
	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	call	ObjCallInstanceNoLock
	pop	dx			; *ds:dx = control panel
	pop	si			; *ds:si = OLField
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
					; store chunk handle of control panel
	mov	ds:[di].OLFI_windowListCtrlPnl, dx

endif
done:
	ret
OLFieldEnsureWindowListDialog	endp

endif ;---------------------------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLFieldEnsureToolArea

DESCRIPTION:	This procedure creates the ToolArea for the OLField
		if not done already.

CALLED BY:	OLFieldEnsureExpressMenu

PASS:		ds:*si	- instance data

RETURN:		^lcx:dx	- Tool area

DESTROYED:	ax, bx, di, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/18/92		initial version

------------------------------------------------------------------------------@

OLFieldEnsureToolArea	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = SpecificInstance
	mov	cx, ds:[LMBH_handle]
	mov	dx, ds:[di].OLFI_toolArea
	tst	dx
	jnz	done

	; Before sending first message to Tool Area, make sure it is marked
	; as being run by the global UI thread.
	;
	mov	bx, handle ui
	call	ProcInfo
	mov	ax, bx
	mov	bx, handle ExpressMenuResource
	call	MemModifyOtherInfo

	push	si

	; Create it.
	;
	mov	cx, ds:[LMBH_handle]	; block to copy into
	clr	dx
	mov	bx, handle FloatingToolArea
	mov	si, offset FloatingToolArea
	mov	ax, MSG_GEN_COPY_TREE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	clr	bp		; no special CompChildFlags
	call	ObjMessage

	pop	si

	; Setup Floating tool are to have a one-way upward link to field
	;
	call	GenAddChildUpwardLinkOnly
				; ^lcx:dx is new area
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = SpecificInstance
	mov	ds:[di].OLFI_toolArea, dx

	push	cx, dx, si

	; Get it up on screen (a queue delay later)
	;
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	pop	cx, dx, si

done:
	ret
OLFieldEnsureToolArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldEnsureEventToolArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ensure tool area for event menu

CALLED BY:	INTERNAL
			OLFieldEnsureEventMenu
PASS:		*ds:si = OLField
RETURN:		^lcx:dx = tool area for event menu
DESTROYED:	ax, bx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if EVENT_MENU

OLFieldEnsureEventToolArea	proc	near
	;
	; if event menu tool area already create, return it
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = SpecificInstance
	mov	cx, ds:[LMBH_handle]
	mov	dx, ds:[di].OLFI_eventToolArea
	tst	dx
	jnz	done
	;
	; create tool area for event menu
	;	*ds:si = OLField
	;
	push	si
	mov	cx, ds:[LMBH_handle]	; block to copy into
	clr	dx
	mov	bx, handle EventToolArea
	mov	si, offset EventToolArea
	mov	ax, MSG_GEN_COPY_TREE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	clr	bp			; no special CompChildFlags
	call	ObjMessage
	pop	si
	call	GenAddChildUpwardLinkOnly
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLFI_eventToolArea, dx
	push	cx, dx, si
	;
	; initiate tool area for event menu
	;	^lcx:dx = tool area for event menu
	;
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	cx, dx, si
done:
	ret
OLFieldEnsureEventToolArea	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldEnsureAppMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create application menu

CALLED BY:	OLFieldEnsureExpressMenu
PASS:		*ds:si	= OLFieldClass object
		^lcx:dx	= ToolAreaClass object
RETURN:		^lcx:dx	= application list menu
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/31/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if APPLICATION_MENU	;-----------------------------

OLFieldEnsureAppMenu	proc	near
	uses	ax,bx,si,di,bp,es
	.enter

	; setup menu

	segmov	es, <segment GenInteractionClass>, di
	mov	di, offset GenInteractionClass
	call	createChildObject		; *ds:si = child object

	push	ds:[LMBH_handle], si		; save app list menu optr

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GII_visibility, GIV_POPUP
	mov	ds:[di].GI_attrs, mask GA_KBD_SEARCH_PATH
	mov	ds:[di].GI_kbdAccelerator, KeyboardShortcut <0,0,0,0,0xf,VC_F7>

	mov	ax, HINT_AVOID_MENU_BAR
	clr	cx
	call	ObjVarAddData

	mov	ax, HINT_EXPRESS_MENU
	call	ObjVarAddData

	mov	ax, HINT_EVENT_MENU
	call	ObjVarAddData

	mov	ax, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
	call	ObjVarAddData

	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	cx, handle ExpressMenuColorMoniker
	mov	dx, offset ExpressMenuColorMoniker
	mov	bp, VUM_MANUAL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock

	; setup app list

	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; ^lcx:dx = menu

	segmov	es, <segment GenItemGroupClass>, di
	mov	di, offset GenItemGroupClass
	call	createChildObject		; *ds:si = child object

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GIGI_behaviorType, GIGBT_EXCLUSIVE
	mov	ds:[di].GIGI_selection, GIGS_NONE

	mov	ax, HINT_GADGET_BACKGROUND_COLORS
	mov	cx, size BackgroundColors
	call	ObjVarAddData
	mov	ds:[bx].BC_unselectedColor1, C_WHITE
	mov	ds:[bx].BC_unselectedColor2, C_WHITE
	mov	ds:[bx].BC_selectedColor1, C_DARK_GRAY
	mov	ds:[bx].BC_selectedColor2, C_DARK_GRAY

	mov	ax, HINT_DRAW_IN_BOX
	clr	cx
	call	ObjVarAddData

	mov	ax, HINT_DRAW_STYLE_FLAT
	call	ObjVarAddData

	mov	ax, HINT_ITEM_GROUP_SCROLLABLE
	call	ObjVarAddData

	push	cx, dx, si, ds:[LMBH_handle]
	segmov	es, ds
	mov	bx, si				; *es:bx = app list
	mov	cx, cs
	mov	dx, offset appListKey
	mov	ds, cx
	mov	si, offset appListCategory
	mov	di, SEGMENT_CS
	mov	ax, offset CreateApplicationListItem
	mov	bp, mask IFRF_READ_ALL
	call	InitFileEnumStringSection
	pop	cx, dx, si, bx

	call	MemDerefDS

	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	ObjCallInstanceNoLock
	cmp	dx, 6
	jb	10$
	mov	dx, 6
10$:
	mov	ax, HINT_INITIAL_SIZE
	mov	cx, size CompSizeHintArgs
	call	ObjVarAddData
	mov	ds:[bx].CSHA_count, dx
	mov	ds:[bx].CSHA_width, SpecWidth <SST_AVG_CHAR_WIDTHS, 30>
	mov	ax, 20
	mul	dx
	mov	ds:[bx].CSHA_height, ax

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock

	pop	cx, dx				; ^lcx:dx = app list menu

	.leave
	ret


createChildObject:
	;
	; ^lcx:dx = parent object
	; es:di = child to instantiate
	;
	mov	bx, cx
	call	GenInstantiateIgnoreDirty	; *ds:si = GenTrigger

	xchg	dx, si
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST
	call	ObjCallInstanceNoLock
	xchg	dx, si
	retn

OLFieldEnsureAppMenu	endp

appListCategory	char	"ui",0
appListKey	char	"appList",0

endif ; APPLICATION_MENU	;---------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateApplicationListItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and add an application list item

CALLED BY:	OLFieldEnsureAppMenu via InitFileEnumStringSection
PASS:		*es:bx	= ApplicationListClass object
		ds:si	= String section (null-terminated)
		dx	= Section #
		cx	= Length of section
RETURN:		carry clear
DESTROYED:	ax,cx,dx,di,si,bp,ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/31/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if APPLICATION_MENU	;--------------------

CreateApplicationListItem	proc	far
appList	local	optr		push	es:[LMBH_handle], bx
ident	local	word		push	dx
iconMkr	local	lptr		push	0
textMkr	local	lptr		push	0
token	local	GeodeToken
	.enter

EC <	segmov	es, ss							>

	mov	cx, ds:[si]
	mov	bx, ds:[si+2]
	add	si, 4
	call	UtilAsciiToHex32
	mov	si, ax
	mov	ax, cx
	LONG jc	done

	mov	{word}ss:[token].GT_chars, ax
	mov	{word}ss:[token].GT_chars+2, bx
	mov	ss:[token].GT_manufID, si

	mov	dl, DisplayType <DS_STANDARD, DAR_NORMAL, DC_COLOR_4>
	mov	cx, ss:[appList].handle
	clr	di
	push	VisMonikerSearchFlags <VMS_TEXT,0,0,0>
	push	0
	call	TokenLoadMoniker
	LONG jc	done

	mov	ss:[textMkr], di

	mov	dl, DisplayType <DS_STANDARD, DAR_NORMAL, DC_COLOR_4>
	mov	cx, ss:[appList].handle
	clr	di
	push	VisMonikerSearchFlags <VMS_ICON,0,0,1>
	push	0
	call	TokenLoadMoniker
	jc	useTextOnly

	mov	ss:[iconMkr], di

	mov	bx, ss:[appList].handle
	call	MemDerefDS
	mov	di, ds:[di]			; ds:di = VisMoniker
	test	ds:[di].VM_type, mask VMT_GSTRING
	jz	useTextOnly

	segmov	es, ds
	mov	di, ss:[textMkr]
	mov	di, es:[di]
	add	di, VM_data+VMT_text
	LocalStrLength includeNull

	push	cx
	add	cx, (size OpDrawText) + (size OpMoveTo)
	mov	bx, VM_data+VMGS_gstring
	mov	ax, ss:[iconMkr]
	call	LMemInsertAt
	pop	cx

	mov	di, ax
	mov	di, es:[di]
	add	di, VM_data+VMGS_gstring
	mov	es:[di].ODT_opcode, GR_DRAW_TEXT
	mov	es:[di].ODT_x1, 30
	mov	es:[di].ODT_y1, 4
	mov	es:[di].ODT_len, cx
	add	di, size OpDrawText

	mov	si, ss:[textMkr]
	mov	si, ds:[si]
	add	si, VM_data+VMT_text
	LocalCopyNString

	mov	es:[di].OMT_opcode, GR_MOVE_TO
	mov	es:[di].OMT_x1, 0
	mov	es:[di].OMT_y1, 0
	jmp	createItem

useTextOnly:
	mov	ax, ss:[textMkr]
	mov	ss:[iconMkr], ax

createItem:
	; Now create the item

	mov	bx, ss:[appList].handle
	call	MemDerefDS

	segmov	es, <segment AppListItemClass>, di
	mov	di, offset AppListItemClass
	call	GenInstantiateIgnoreDirty	; *ds:si = GenTrigger
	mov	bx, offset Gen_offset
	call	ObjInitializePart

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	segmov	ds:[di].GI_visMoniker, ss:[iconMkr], ax
	segmov	ds:[di].GII_identifier, ss:[ident], ax
	movdw	axbx, ss:[token].GT_chars
	movdw	ds:[di].ALII_token.GT_chars, axbx
	mov	ax, ss:[token].GT_manufID
	mov	ds:[di].ALII_token.GT_manufID, ax

	movdw	cxdx, ss:[appList]

	push	bp
	xchg	dx, si
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST
	call	ObjCallInstanceNoLock
	xchg	dx, si
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock
	pop	bp
done:
	mov	bx, ss:[appList].handle
	call	MemDerefES
	mov	bx, ss:[appList].offset
	clc

	.leave
	ret
CreateApplicationListItem	endp

endif ; APPLICATION_MENU	;------------


if _EXPRESS_MENU
COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldCreateExpressMenu

DESCRIPTION:	Creates the default workspace menu.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_GEN_FIELD_CREATE_EXPRESS_MENU

	cx:dx	- Generic object to place menu under (run by UI)
			(dx=0 if gen parent will be set later)
	bp	- CompChildFlags

RETURN:
	cx:dx	- OD of created Express Menu controller

	carry - ?
	ax, cx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
	Doug	4/90		Revised to merge workspace & app menus

------------------------------------------------------------------------------@

OLFieldCreateExpressMenu	method	dynamic OLFieldClass, \
				MSG_GEN_FIELD_CREATE_EXPRESS_MENU
	.enter

	; Before sending first message to Express menu, make sure it is marked
	; as being run by the global UI thread.
	;
	mov	bx, handle ui
	call	ProcInfo
	mov	ax, bx
	mov	bx, handle ExpressMenuResource
	call	MemModifyOtherInfo

				; Setup object to add menu to generically
				; cx = handle of block to create menu in
	push	si
	mov	bx, handle ExpressMenuResource
	mov	si, offset ExpressMenu
	mov	ax, MSG_GEN_COPY_TREE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
				; pass the CompChildFlags we got.
	call	ObjMessage

if	_NIKE
	; Replace all "OLTPT_FIELD" params in menu with the real field OD
	;
	mov	si, dx			; *ds:si = express menu
	mov	bp, OLTPT_FIELD		; replace this constant
	mov	cx, ds:[LMBH_handle]	; ^lcx:dx = field optr to replace with
	pop	dx
	push	dx			; save field chunk again

	push	cx, si
	mov	ax, MSG_GEN_BRANCH_REPLACE_OUTPUT_OPTR_CONSTANT
	call	ObjCallInstanceNoLock
	pop	cx, dx
endif

if	_REDMOTIF
	mov	si, dx

	; Replace all "OLTPT_WINDOW" params in menu with the menu OD,
	; rather than using the template ExpressMenu as the OD which had been 
	; done previously.  5/25/94 cbh
	;
	mov	si, dx			; *ds:si = window dialog
	push	cx, dx, bp, si
	mov	bp, OLTPT_WINDOW	; replace this constant
	mov	cx, ds:[LMBH_handle]	; ^cx:dx = menu optr to replace with
	mov	dx, si
	mov	ax, MSG_GEN_BRANCH_REPLACE_OUTPUT_OPTR_CONSTANT
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp, si

	; check if we should disable Spreadsheet and Draw from the menu
	;
	push	si, ds, cx, dx
	segmov	ds, cs, cx
	mov	si, offset uiCatString		;ds:si = category
	mov	dx, offset versionString	;cx:dx = key
	mov	ax, 0				;assume drawCalcVersion = false
	call	InitFileReadBoolean		;C clear if found, ax = value
	tst	ax
	pop	si, ds, cx, dx
	jnz	dontDisableDrawCalc

	push	bp, dx, si
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	mov	cx, 4				;Draw is 5th child
	call	ObjCallInstanceNoLock		;^lcx:dx <- Draw
	mov	ax, MSG_GEN_SET_NOT_USABLE	
	mov	si, dx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	pop	bp, dx, si
dontDisableDrawCalc:

	;
	; Pass the field optr to the LauncherInteraction.  5/25/94 cbh
	;
	pop	dx			; restore field optr
	push	dx			; push field chunk again
	mov	cx, ds:[LMBH_handle]	; ^lcx:dx = field
	mov	ax, MSG_LAUNCHER_SET_FIELD
	call	ObjCallInstanceNoLock

	;
	; Get to express menu 2, which is the real menu.
	;
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	mov	cx, 5			;child # of eMenu2 under eMenu
	call	ObjCallInstanceNoLock
endif
	pop	si
				; ^lcx:dx is new express menu
	;
	; if we have a defaultLauncher .ini flag, set hint on express menu
	; to create a "Return to <default launcher>" button
	;	*ds:si = OLField
	;	^lcx:dx = new expres menu
	;
	call	SpecGetExpressOptions	; ax = UIExpressOptions
	test	ax, mask UIEO_RETURN_TO_DEFAULT_LAUNCHER
	jz	afterLauncher
	push	cx, dx
	sub	sp, INI_CATEGORY_BUFFER_SIZE
	mov	dx, sp			; cx:dx = category buffer
	mov	cx, ss
	mov	ax, MSG_META_GET_INI_CATEGORY
	call	ObjCallInstanceNoLock
	push	ds
	mov	ds, cx
	mov	si, dx
	mov	cx, cs
	mov	dx, offset spuiDefaultLauncherKey
	clr	bp			; give us a buffer
	call	InitFileReadString	; bx = mem handle
	mov	di, cx			; di = size
	pop	ds
	lahf
	add	sp, INI_CATEGORY_BUFFER_SIZE
	sahf
	pop	cx, dx
	jc	afterLauncher		; if no default launcher, stop

	sub	sp, size AddVarDataParams
	mov	bp, sp
	call	MemLock
	mov	ss:[bp].AVDP_data.segment, ax
	mov	ss:[bp].AVDP_data.offset, 0
	inc	di			; di = size w/ null
DBCS <	shl	di, 1			; di <- # of bytes		>
	mov	ss:[bp].AVDP_dataSize, di
					; don't save to state
	mov	ss:[bp].AVDP_dataType, TEMP_EMC_HAS_RETURN_TO_DEFAULT_LAUNCHER
	push	bx, cx, dx
	movdw	bxsi, cxdx		; ^lbx:si = new express menu
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	pop	bx, cx, dx
	call	MemFree
	add	sp, size AddVarDataParams
afterLauncher:

	;
	; set features, using olExpressOptions
	;	^lcx:dx = new express menu
	;
	movdw	bxsi, cxdx		; ^lbx:si = new express menu
	call	SpecGetExpressOptions	; ax = UIExpressOptions
					; remove this non-ECMF bit
	andnf	ax, not mask UIEO_RETURN_TO_DEFAULT_LAUNCHER
.assert ((offset UIEO_DESK_ACCESSORY_LIST  - width UIEO_POSITION) eq offset EMCF_DESK_ACCESSORY_LIST)
.assert ((offset UIEO_GEOS_TASKS_LIST  - width UIEO_POSITION) eq offset EMCF_GEOS_TASKS_LIST)
.assert ((offset UIEO_MAIN_APPS_LIST  - width UIEO_POSITION) eq offset EMCF_MAIN_APPS_LIST)
.assert ((offset UIEO_OTHER_APPS_LIST  - width UIEO_POSITION) eq offset EMCF_OTHER_APPS_LIST)
.assert ((offset UIEO_CONTROL_PANEL  - width UIEO_POSITION) eq offset EMCF_CONTROL_PANEL)
.assert ((offset UIEO_DOS_TASKS_LIST  - width UIEO_POSITION) eq offset EMCF_DOS_TASKS_LIST)
.assert ((offset UIEO_EXIT_TO_DOS  - width UIEO_POSITION) eq offset EMCF_EXIT_TO_DOS)

ifdef WIZARDBA
	test	ax, mask UIEO_DESK_ACCESSORY_LIST
	jnz	notStudent

	;
	; Preserve the object block around this call, as it may move.
	;

	push	ds:[LMBH_handle]
	call	BuildExpressMenuAppletList
	pop	bx
	call	MemDerefDS
notStudent:
endif

	mov	cl, width UIEO_POSITION
	shr	ax, cl			; ax = ExpressMenuControlFeatures
	call	ObjSwapLock		; *ds:si = new express menu
	push	bx			; save old handle

	push	ax			; save ExpressMenuControlFeatures
	mov	ax, ATTR_GEN_CONTROL_REQUIRE_UI
	call	ObjVarFindData		; ds:bx = vardata
EC <	ERROR_NC	OL_ERROR					>
	pop	ax

	mov	{word} ds:[bx], ax	; ax = required features
	not	ax			; ax = prohibited features
	push	ax
	mov	ax, ATTR_GEN_CONTROL_PROHIBIT_UI
	call	ObjVarFindData		; ds:bx = vardata
EC <	ERROR_NC	OL_ERROR					>
	pop	{word} ds:[bx]

	;
	; build the thing now, so that we don't get ugly additions to control
	; panel, etc. when the user opens it
	;	*ds:si = new express menu control
	;
	push	dx			; save new express menu chunk
	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	call	ObjCallInstanceNoLock
	pop	dx

	pop	bx
	call	ObjSwapUnlock		; ^lbx:si = new express menu
	mov	cx, bx			; ^lcx:dx = new express menu
	.leave
	ret
OLFieldCreateExpressMenu	endm


spuiDefaultLauncherKey	char	'defaultLauncher',0

if _REDMOTIF
uiCatString	char	"ui",0
versionString	char	"drawCalcVersion",0
endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldCreateExpressSubGroup

DESCRIPTION:	Creates the UI specific portion of the Express menu

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_GEN_FIELD_CREATE_SPECIFIC_WORKSPACE_SUBGROUP

	cx:dx	- Generic object to place menu under (run by UI)
	bp	- CompChildFlags

RETURN:
	dx	- chunk handle of created subgroup

	carry - ?
	ax, cx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

if _OL_STYLE	;START of OPEN LOOK specific code -----------------------------

OLFieldCreateExpressSubGroup	method	dynamic OLFieldClass, MSG_GEN_FIELD_CREATE_SPECIFIC_WORKSPACE_SUBGROUP
				; Setup object to add menu to generically
	mov	bx, handle ExpressMenuResource
	mov	si, offset ExpressProperties
	mov	ax, MSG_GEN_COPY_TREE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage
				; return dx = chunk handle

OLFieldCreateExpressSubGroup	endm

endif		;END of OPEN LOOK specific code -------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildExpressMenuAppletList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add applet list to express menu

CALLED BY:	OLFieldCreateExpressMenu

PASS:		^lbx:si	= express menu

RETURN:		nothing

DESTROYED:	ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/14/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef WIZARDBA	;--------------------------------------------------------------

if 1
deskAccPathname	byte	"Desk Accessories",0
else
deskAccPathname	byte	"DESK_ACC.000",0
endif

BuildExpressMenuAppletList	proc	near
expressMenu	local	optr	push	bx, si
appletList	local	lptr
nameArray	local	fptr
arrayCount	local	word
	uses	ax,bx,cx,dx,si,di
	.enter
	;
	; Create a memory block to store list of Geos courseware applets.
	;
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	MemAllocLMem

	call	MemLock
	push	bx
	mov	ds, ax

	push	bx
	clr	ax, bx, cx, si
	call	NameArrayCreate
	mov	ax, si
	pop	bx

	;
	; Build a list of Geos courseware applets.
	;  ^lbx:ax = optr of nameArray
	;
	mov	cx, cs
	mov	dx, offset BuildAppletListClassCallBack
	call	IclasEnumClasses

	call	MemDerefDS

	call	ChunkArrayGetCount		; get number of applets.

if (0)
	tst	cx
	jnz	haveApplets

	;
	; If no applets, then hide the express menu button
	;
	push	ds
	mov	ax, segment olExpressOptions
	mov	ds, ax
	mov	ax, ds:[olExpressOptions]
	and	ax, not mask UIEO_POSITION
	.assert ((UIEP_NONE shl offset UIEO_POSITION) eq 0)
	mov	ds:[olExpressOptions], ax
	pop	ds

	;
	; Remove keyboard accelerator for Express Menu
	;
	mov	ax, MSG_GEN_SET_KBD_ACCELERATOR
	movdw	bxsi, ss:[expressMenu]
	clr	cx, dx, di
	push	bp
	call	ObjMessage
	pop	bp

	jmp	unlockNameArray			

haveApplets:
endif

	mov	ss:[arrayCount], cx
	;
	; Instantiate a GenInteraction to be the parent of our applet triggers.
	;
	push	si
	mov	di, segment GenInteractionClass
	mov	es, di
	mov	di, offset GenInteractionClass
	mov	bx, ss:[expressMenu].handle
	call	ObjInstantiate		; ^lbx:si = new interaction

	mov	ss:[appletList], si
	;
	; Set the path of the GenInteraction to be SP_APPLICATION/DESKTOP.
	;
	mov	ax, MSG_GEN_PATH_SET
	mov	cx, cs						
	mov	dx, offset deskAccPathname
if _FXIP
;	 Must copy string to stack on XIP systems.
	push	ds						
	mov	ds, cx						
	mov	cx, length deskAccPathname			
	call	SysCopyToStackDSDX				
	mov	cx, ds			; cx:dx = string	
	pop	ds						
endif	
	push	bp
	mov	bp, SP_APPLICATION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
FXIP <	call	SysRemoveFromStack				>	
	pop	si
	jc	unlockNameArray
	;
	; Add a trigger to our GenInteraction for each applet.
	;
	call	MemLock				; lock the Express Menu block
	push	bx
	mov	es, ax

	tst	ss:[arrayCount]
	jz	addToExpress

	clr	ax
	movdw	bxdx, ss:[expressMenu]		; ^lbx:dx = ExpressMenu

getElement:
	call	ChunkArrayElementToPtr

	push	si
	segxchg	ds, es				; es:di = NameArrayElement
	add	di, cx
	mov	{byte} es:[di], 0		; null terminate element
	sub	di, cx
	add	di, size RefElementHeader	; skip header of element
	mov	si, ss:[appletList]		; *ds:si=parent GenInteraction
	call	AddAppletToAppletList
	segxchg	ds, es
	pop	si

	inc	ax
	cmp	ax, ss:[arrayCount]
	jl	getElement

addToExpress:
	;
	; Add our GenInteraction as the app provided ui for the ExpressMenu.
	;
	segmov	ds, es
	mov	si, ss:[expressMenu].chunk
	mov	ax, ATTR_GEN_CONTROL_APP_UI
	mov	cx, size optr
	call	ObjVarAddData
	mov	cx, ds:[LMBH_handle]
	mov	dx, ss:[appletList]
	movdw	ds:[bx], cxdx

	pop	bx
	call	MemUnlock			; unlock Express Menu block
			
unlockNameArray:
	pop	bx
	call	MemUnlock
	call	MemFree
	jmp	done	
done:
	.leave
	ret
BuildExpressMenuAppletList	endp

endif		;--------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddAppletToAppletList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a GenTrigger to the Applet List.

CALLED BY:	
PASS:		^lbx:si = parent for item
		^lbx:dx	= express menu (output goes to express menu)
		ds	= express menu object block
		es:di = pointer to FileLongName

RETURN:		^lbx:si = new item

DESTROYED:	cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef WIZARDBA	;--------------------------------------------------------------

AddAppletToAppletList	proc	near
	uses	ax, bx, dx, bp, es
	.enter

	push	si			; save parent object chunk
	pushdw	esdi			; save name

	mov	di, segment GenTriggerClass
	mov	es, di
	mov	di, offset GenTriggerClass
	call	ObjInstantiate		; ^lbx:si = new trigger
	mov	di, dx			; ^lbx:di = express menu

	popdw	cxdx			; cxdx = null-terminated name
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_MANUAL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	cx, MSG_EMC_LAUNCH_APPLICATION
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	movdw	cxdx, bxdi		; destination is express menu
	call	ObjCallInstanceNoLock

	push	bp
	sub	sp, size AddVarDataParams + size optr
	mov	bp, sp
	mov	ss:[bp].AVDP_data.segment, ss
	mov	ax, bp
	add	ax, size AddVarDataParams
	mov	ss:[bp].AVDP_data.offset, ax
	mov	ss:[bp].AVDP_dataSize, size optr + size word
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_TRIGGER_ACTION_DATA
	mov	ss:[bp][(size AddVarDataParams)]+0, bx	; cx data
	mov	ss:[bp][(size AddVarDataParams)]+2, si	; dx data
	mov	{word} ss:[bp][(size AddVarDataParams)]+4, -1	; bp data
							; (force DA mode)
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	call	ObjCallInstanceNoLock
	add	sp, size AddVarDataParams + size optr
	pop	bp

	movdw	cxdx, bxsi		; ^lcx:dx = new trigger
	pop	si			; ^lbx:si = parent
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST		; not dirty
	call	ObjCallInstanceNoLock

	movdw	bxsi, cxdx		; ^lbx:si = new trigger
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock

	.leave
	ret
AddAppletToAppletList	endp

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildAppletListClassCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for a class (class the student is in)

CALLED BY:	IclasEnumClasses (callback)
PASS:		es:di	= item line for a class
		^lbx:ax	= name array
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/14/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef WIZARDBA	;--------------------------------------------------------------

BuildAppletListClassCallBack	proc	far

	;
	; skip over Class Long Name
	;
	push	ax
	mov	cx, -1
	mov	al, '^'
	repne	scasb
	;
	; null terminate target directory
	;	
	add	di, 14			; skip "CD T:\CLASSES"
	mov	si, di
	repne	scasb
	mov	{byte}es:[di-1], NULL
	pop	ax
	;
	; Enumerate courseware in class
	;
	segmov	ds, es			; ds:si = IclasPathStruct
	mov	cx, cs
	mov	dx, offset BuildAppletListCoursewareCallBack
	call	IclasEnumCourseware
	ret
BuildAppletListClassCallBack	endp

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildAppletListCoursewareCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for courseware

CALLED BY:	IclasEnumClasses (callback)
PASS:		es:di	= item line for courseware
		^lbx:ax	= name array
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/14/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef WIZARDBA	;--------------------------------------------------------------

appletMarker	char	"Desk Accessories\\"
APPLET_MARKER_LENGTH equ ($- offset appletMarker) / (size char)

BuildAppletListCoursewareCallBack	proc	far
	;
	; Search for end of line
	;
	push	ax, di
	mov	cx, -1
	mov	al, C_LF
	repne	scasb
	not	cx
	pop	di
	;
	; Search for applet marker.
	;
	segmov	ds, cs, si
	mov	si, offset appletMarker
	mov	dx, APPLET_MARKER_LENGTH	; length of appletMarker string
	call	SubSearchString
	pop	si				; bx:si = name array
	jc	done				; skip if not found
	;
	; Null terminate desk accessory name
	;
	add	di, APPLET_MARKER_LENGTH	; Skip to beginning of
						;  desk accessory name
	push	di
	mov	cx, size FileLongName
	mov	al, '^'
	repne	scasb
	mov	{byte} es:[di-1], C_NULL
	pop	di
	;
	; Add desk acessory to name array
	;
	call	MemDerefDS			; ds:si = name array
	clr	bx, cx
	call	NameArrayAdd
done:
	ret
BuildAppletListCoursewareCallBack	endp

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMCControlPanelCreateItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prevent screen lock button from being added if user does
		not have permission.

CALLED BY:	MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
PASS:		*ds:si	= EMCControlPanelClass object
		ds:di	= EMCControlPanelClass instance data
		ds:bx	= EMCControlPanelClass object (same as *ds:si)
		es 	= segment of EMCControlPanelClass
		ax	= message #
		ss:bp	= CreateExpressMenuControlItemParams
		dx	= size CreateExpressMenuControlItemParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef WIZARDBA	;--------------------------------------------------------------

EMCControlPanelCreateItem	method dynamic EMCControlPanelClass, 
					MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
	cmp	ss:[bp].CEMCIP_feature, CEMCIF_UTILITIES_PANEL
	jne	callSuper
	cmp	ss:[bp].CEMCIP_itemPriority, CEMCIP_SAVER_SCREEN_LOCK
	jne	callSuper

	call	IclasGetSecurityLockStatus
	jc	callSuper

	ret	; ignore request to create item

callSuper:
	mov	ax, MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
	mov	di, offset EMCControlPanelClass
	GOTO	ObjCallSuperNoLock	

EMCControlPanelCreateItem	endm

endif		;--------------------------------------------------------------

endif		; if _EXPRESS_MENU



COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldOpenWin -- MSG_VIS_OPEN_WIN for OLFieldClass

DESCRIPTION:	Open the field window

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_VIS_OPEN_WIN

	cx - ?
	dx - ?
	bp - window to make parent of this window

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

OLFieldOpenWin	method	dynamic OLFieldClass, MSG_VIS_OPEN_WIN
EC<	call	VisCheckVisAssumption	; Make sure vis data exists >

EC <	cmp	ds:[di].VCI_window, 0	; already have a window?	>
EC <	ERROR_NZ	OPEN_WIN_ON_OPEN_WINDOW				>

	push	si			; save chunk handle

					; Use same layer ID for
					; ALL field windows, regardless of who
					; owns the field.  (This so that UI &
					; Welcome rooms are all in the same 
					; layer)
	clr	bx			; Common ID of 0 should be fine.
	push	bx			; Push layer ID to use

					; Owning geode of any window must be
					; the one which should receive all
					; input directed to it.  For Fields,
					; this will always be the UI.
	call	GeodeGetProcessHandle

	push	bx			; push owner on stack

	push	bp			; push parent window to use

NOFXIP<	push	cs						>

FXIP <	push	bx						>
FXIP <	mov	bx, handle RegionResourceXIP			>
FXIP <	call	MemLock			; ax = segment		>
FXIP <	pop	bx						>
FXIP <	push	ax						>
	
	mov	ax, offset fieldRegion
	push	ax

	call	OpenGetLineBounds	; push parameters to region
	push	dx			; bottom
	push	cx			; right
	push	ax			; last two params aren't used, so 
	push	cx			;	just push whatever

	mov	bx, ds:[si]
if not _NO_FIELD_BACKGROUND
ife	TRANSPARENT_FIELDS
	mov	di, bx
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLFI_BGFile	;If file already opened, just branch
	jne	OFOW_BG
endif
endif
	mov	di, bx
	add	di, ds:[di].Gen_offset

if TRANSPARENT_FIELDS
	mov	ax, (mask WCF_TRANSPARENT shl 8) or C_BLACK
else

ifdef WIZARDBA	;--------------------------------------------------------------
	;If there is a default launcher, then set for WCF_PLAIN and
	;WCF_TRANSPARENT, since the launcher will always be a full-screen app
	;which fully obscures this field object. Eliminates a
	;full-screen redraw.	EDS 3/1/93

	mov	ax, ((mask WCF_PLAIN or mask WCF_TRANSPARENT) shl 8)

;TEMPORARY HACK - since GFF_HAS_DEFAULT_LAUNCHER is never set by anyone!
	jmp	OFOW_gotColor

	test	ds:[di].GFI_flags, mask GFF_HAS_DEFAULT_LAUNCHER
	jnz	OFOW_gotColor		;skip if has a default launcher...
endif		;--------------------------------------------------------------

if _JEDIMOTIF and 0
	;
	; Let splash screen stay up as long as possible.  (Removed
	; for Obiwan to allow the background to erase on the emulator
	; when the screen rotates).
	;
	mov	ax, (mask WCF_TRANSPARENT shl 8) or C_BLACK
else
	mov	ax, ((mask WCF_PLAIN or CMT_DITHER) shl 8) or C_BLACK
					; default to black (GEOS boots to
					;	black screen - we want avoid
					;	color changes here)
endif

if not _NO_FIELD_BACKGROUND
	test	ds:[di].GFI_flags, mask GFF_LOAD_BITMAP
	jz	OFOW_gotColor		; if not drawing bitmap, don't even
					;	use custom color
	CallMod	OpenBGFile
	jc	OFOW_noBG		; branch if none loaded
OFOW_BG:
	CallMod	GetBackgroundColorPict
	jmp	short OFOW_gotColor

OFOW_noBG:
	CallMod	GetBackgroundColorNoPict

OFOW_gotColor:
endif
endif
	mov	bp, si			; set up chunk of this object in bp
					; pass handle of video driver
	mov	di, ds:[LMBH_handle]	; pass obj descriptor of this object
	mov	cx, di
	mov	dx, bp

				; Open window BEHIND all others at this level
	mov	si, mask WPF_PLACE_BEHIND
	call	WinOpen

FXIP <	push	bx						>
FXIP <	mov	bx, handle RegionResourceXIP			>
FXIP <	call	MemUnlock					>
FXIP <	pop	bx						>
	
if FAKE_SIZE_OPTIONS
	call	MaybeMoveField
endif
	pop	si		; restore object chunk handle
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	mov	ds:[di].VCI_window, bx	; store window handle
	ret

OLFieldOpenWin	endm

if FAKE_SIZE_OPTIONS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaybeMoveField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we need to move the field, and if so, do so.

CALLED BY:	OLFieldOpenWin

PASS:		^hbx = window for field

RETURN:		nothing
DESTROYED:	nothing (field window possibly moved)

PSEUDO CODE/STRATEGY:

	If the PC demo has a hard-icon bar on the left or top,
	we have to move the field to make room for it.

	Note that the user must make sure the screen size and
	field size are correct in the INI file for this to work
	correctly (otherwise they'll get a clipped field).

	Note also that we can't just change the field's vis
	bounds -- they're reset to the window bounds when the
	thing is drawn onscreen.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	7/18/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MaybeMoveField	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds

		winBounds	local	Rectangle

		.enter
	;
	;  Get the current bounds on the window.
	;
		mov	di, bx		; ^hdi = window
		call	WinGetWinScreenBounds	; ax = left, cx = top
		mov	ss:winBounds.R_left, ax
		mov	ss:winBounds.R_top, bx
		mov	ss:winBounds.R_right, cx
		mov	ss:winBounds.R_bottom, dx
	;
	;  Check for a hard icon bar on the left.
	;
		mov	cx, cs
		mov	ds, cx
		mov	si, offset iconBarCategoryString
		mov	dx, offset leftIconBarString
		call	InitFileReadInteger	; ax = width
		jc	noLeft
	;
	;  Shift the field over by the width.
	;
		add	ss:winBounds.R_left, ax
		add	ss:winBounds.R_right, ax
noLeft:
	;
	;  Check for a hard icon bar on the top.
	;
		mov	dx, offset topIconBarString
		call	InitFileReadInteger	; ax = width
		jc	noTop
	;
	;  Shift the field down by the height.
	;
		add	ss:winBounds.R_right, ax
		add	ss:winBounds.R_bottom, ax
noTop:
	;
	;  Move the window.  The handle is still in di.
	;
		push	bp		; locals
		mov	bx, mask WPF_ABS; move in absolute screen coordinates
		push	bx		; put WinPassFlags on stack
		mov	ax, ss:winBounds.R_left
		mov	bx, ss:winBounds.R_top
		mov	cx, ss:winBounds.R_right
		mov	dx, ss:winBounds.R_bottom
		clr	bp, si		; associated region (none)
		call	WinResize
		pop	bp		; locals
done:
		.leave
		ret
MaybeMoveField	endp

iconBarCategoryString	char	"ui", C_NULL
leftIconBarString	char	"leftIconBarWidth", C_NULL
topIconBarString	char	"topIconBarHeight", C_NULL

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldEnsureStickyMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install an input monitor to intercept sticky-key presses.

CALLED BY:	OLFieldSpecBuild

PASS:		*ds:si = OLField object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _JEDIMOTIF	;--------------------------------------------------------------

OLFieldEnsureStickyMonitor	proc	near
		uses	ax,bx,cx,dx,ds
		.enter
	;
	;  If we already have the monitor, don't do it again...
	;
		segmov	ds, dgroup, bx
		test	ds:[stickyMonFlags], mask SMF_MONITOR_INSTALLED
		jnz	done

		mov	bx, offset olStickyMonitor
		mov	al, ML_OUTPUT-1
		mov	cx, segment OLStickyRoutine
		mov	dx, offset OLStickyRoutine
		call	ImAddMonitor
		ornf	ds:[stickyMonFlags], mask SMF_MONITOR_INSTALLED
done:
		.leave
		ret
OLFieldEnsureStickyMonitor	endp

endif	; _JEDIMOTIF ----------------------------------------------------------

Init	ends

if _JEDIMOTIF	;--------------------------------------------------------------

Unbuild	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldSpecUnbuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove input monitor.

CALLED BY:	MSG_SPEC_UNBUILD

PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		bp	= SpecBuildFlags

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFieldSpecUnbuild	method dynamic OLFieldClass, 
					MSG_SPEC_UNBUILD
		.enter
	;
	;  If there's no monitor installed, don't attempt to remove it.
	;
		push	ds
		segmov	ds, dgroup, bx
		test	ds:[stickyMonFlags], mask SMF_MONITOR_INSTALLED
		pop	ds
		jz	done
	;
	;  Remove ye olde input monitor.
	;
		push	ds
		mov	ds, bx
		mov	bx, offset olStickyMonitor	; ds:bx = monitor
		mov	al, mask MF_REMOVE_IMMEDIATE	; flags for remove
		call	ImRemoveMonitor
		andnf	ds:[stickyMonFlags], not mask SMF_MONITOR_INSTALLED
		pop	ds
done:
if SYNC_HWR_AND_KBD
	;
	; remove ourselves from JGCNSLT_NOTIFY_HWR_INPUT_MODE_CHANGE
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_HP
	mov	ax, JGCNSLT_NOTIFY_HWR_INPUT_MODE_CHANGE
	call	GCNListRemove
endif

	;
	;  Call superclass.
	;
		.leave
		mov	di, offset OLFieldClass
		GOTO	ObjCallSuperNoLock
OLFieldSpecUnbuild	endm

Unbuild	ends

idata	segment

olStickyMonitor	Monitor

idata	ends

StickyMonFlags	record
	SMF_MONITOR_INSTALLED:1
	:6
StickyMonFlags	end

OnOffFuncs	record
	OOF_ON:1			; on-off pressed
	OOF_CONTRAST:1			; contrast adjusted
	OOF_INVERT:1			; invert screen
	:5
OnOffFuncs	end

udata	segment
stickyState	ToggleState
stickyMonFlags	StickyMonFlags
onOffFuncs	OnOffFuncs
udata	ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLStickyRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process sticky keys.

CALLED BY:	im::ProcessUserInput

PASS:		al	= mask MF_DATA
		di	= event type
		MSG_META_KBD_CHAR:
			cx	= character value
			dl	= CharFlags
			dh	= ShiftState
			bp low	= ToggleState
			bp high = scan code
		MSG_IM_PTR_CHANGE:
			cx	= pointer X position
			dx	= pointer Y position
			bp<15>	= X-is-absolute flag
			bp<14>	= Y-is-absolute flag
			bp<0:13>= timestamp
		si	= event data
		ds 	= seg addr of monitor

RETURN:		al	= mask MF_DATA if event is to be passed through
			  0 if we've swallowed the event

DESTROYED:	ah, bx, ds, es (possibly)
		cx, dx, si, bp (if event swallowed)
		
PSEUDO CODE/STRATEGY:

	- caps lock key toggles itself
	- other sticky keys do the following:

		- toggle themselves

		- turn off if any key is pressed except
		  other sticky keys

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLStickyRoutine	proc	far
		uses	bx, cx, dx, si, di, bp, ds, es
		.enter
	;
	;  Monitor returning data?
	;
		test	al, mask MF_DATA
		LONG	jz	done
	;
	;  A keyboard event?
	;
		cmp	di, MSG_META_KBD_CHAR
		LONG	jne	done
	;
	;  The correct character set?
	;
		cmp	ch, CS_CONTROL
		je	isControl
	;
	;  The UI Function set?
	;
		cmp	ch, CS_UI_FUNCS
		je	LONG_isUI
	;
	;  What about BSW?
	;
		cmp	ch, CS_BSW			; regular Char?
		jne	LONG_lookForRelease
	;
	;  Look for '+','-', or '/' keys...
	;
		cmp	cl, C_PLUS
		je	LONG_adjustContrast
		cmp	cl, C_MINUS
		je	LONG_adjustContrast
		cmp	cl, C_SLASH
		je	LONG_invertScreen
LONG_lookForRelease:
		jmp	lookForRelease
LONG_isUI:
		jmp	isUI
LONG_adjustContrast:
		jmp	adjustContrast
LONG_invertScreen:
		jmp	invertScreen

isControl:
	;
	;  A first press?  (Even if it's a sticky key, we're
	;  not interested in it unless it's a first press).
	;
		test	dl, mask CF_FIRST_PRESS
		LONG	jz	done
	;
	;  A sticky key?
	;
		cmp	cl, VC_LCTRL
		je	fnKey
		cmp	cl, VC_RCTRL
		je	fnKey
		cmp	cl, VC_LALT
		je	altKey
		cmp	cl, VC_RALT
		je	altKey
		cmp	cl, VC_LSHIFT
		je	shiftKey
		cmp	cl, VC_RSHIFT
		je	shiftKey
		cmp	cl, VC_CAPSLOCK
		jne	turnOffKeys
	;
	;  Toggle the bit corresponding to this key in the
	;  stickyState record.  Can't use tables to shorten
	;  this code because VC_CTRL, VC_ALT, VC_SHIFT, etc.
	;  aren't sequential enumerations.
	;

	;
	;  FN, ALT, SHIFT:  toggle themselves but don't
	;  affect other sticky keys.
	;
capsKey::
		xor	ds:[stickyState], mask TS_CAPSLOCK
	;
	;  This screws up the PC emulator but it's necessary on
	;  the actual hardware.
	;
		andnf	ds:[stickyState], not mask TS_FNCTSTICK
		jmp	sendToGCN
fnKey:
		xor	ds:[stickyState], mask TS_FNCTSTICK
		jmp	sendToGCN
altKey:
		xor	ds:[stickyState], mask TS_ALTSTICK
		jmp	sendToGCN
shiftKey:
		xor	ds:[stickyState], mask TS_SHIFTSTICK
		jmp	sendToGCN

lookForRelease:
	;
	;  Only turn off the sticky keys on releases.
		test	dl, mask CF_RELEASE
		jz	done

turnOffKeys:
	;
	;  A non-sticky key was pressed:  turn off all the
	;  sticky keys except for the CAPS LOCK key.  If there
	;  is no change, don't redraw.
	;
		mov	cl, ds:[stickyState]
		andnf	ds:[stickyState], not (mask TS_SHIFTSTICK \
						or mask TS_ALTSTICK \
						or mask TS_FNCTSTICK)
		cmp	cl, ds:[stickyState]
		je	done			; skip notification
sendToGCN:
if SYNC_HWR_AND_KBD
	;
	; Tell HWR engine about new state
	;
		call	updateHWR
endif
	;
	;  Send notification to the sticky-key GCN list.
	;
		call	SendKeyboardEventGCN
done:
		.leave
		ret
isUI:
	;
	;  Sniff around for interesting key, and note down any changes
	;
		cmp	cl, UC_LOCK
		je	lockScreen	; => lock the screen

		cmp	cl, UC_ON
		jne	turnOffKeys	; => not ON/OFF

		test	dl, mask CF_RELEASE
		jnz	turnOff		; => OFF key

		test	dl, mask CF_REPEAT_PRESS
		jnz	gulpGulpGulp	; => repeated... who cares?
	;
	; Pressed - mark as down
	;
		ornf	ds:[onOffFuncs], mask OOF_ON	; mark as on
		jmp	gulpGulpGulp			; => nothing more to do

adjustContrast:
	;
	;  We might be adjusting contrast (and then again,
	;  we might not).  See if the ON-OFF key is held
	;  down.
	;

		test	ds:[onOffFuncs], mask OOF_ON
		jz	turnOffKeys		; ignore this one

							; ds -> dgroup
		call	OLAdjustContrast	; nothing destroyed

		jmp	short gulpGulpGulp
lockScreen:
	;
	;  Unless they release the Fn-ON key, we don't
	;  care.
	;
		test	dl, mask CF_RELEASE
		jz	gulpGulpGulp	; => we don't care

	;
	; Set the oneTimeLock boolean to TRUE if this was FN-ON.
	;
		push	ds				; save dgroup

		mov	cx, cs
		mov	ds, cx

		mov	si, offset lockCategory		; ds:si <- category
		mov	dx, offset lockKey		; cx:dx <- key
		mov	ax, TRUE			; oneTimeLock = TRUE
		call	InitFileWriteBoolean

		pop	ds				; restore dgroup

		mov	ds:[onOffFuncs], mask OOF_ON	; fake ON press
turnOff:
	;
	; Released ON key w/o any other presses - turn off device.
	;
							; ds -> dgroup
		call	OLPowerOnOff		; nothing destroyed
gulpGulpGulp:
	;
	;  Swallow that there key press....
		clr	al
		jmp	turnOffKeys

if SYNC_HWR_AND_KBD
updateHWR	label	near
		push	ax
		call	UserGetHWRLibraryHandle	; ax = handle
		tst	ax
		LONG jz	afterHWR
		mov_tr	bx, ax			; bx = library handle
		push	bx
		mov	ax, HWRR_BEGIN_INTERACTION
		call	ProcGetLibraryEntry	; bx:ax = entry point
		call	ProcCallFixedOrMovable	; ax = status
		pop	bx			; bx = library handle
		tst	ax
		LONG jnz	afterHWR	; couldn't init
		push	bx
		mov	ax, HWRR_GET_LOCKED_STATE
		call	ProcGetLibraryEntry	; bx:ax = entry point
		call	ProcCallFixedOrMovable	; ax = current HWRLockState
		pop	bx			; bx = library handle
		mov	dx, ax			; dx = current HWRLockState
		andnf	dx, mask HWRLS_CAP_LOCK	; dx = current cap state
		clr	cx
		test	ds:[stickyState], mask TS_CAPSLOCK
		jz	noCaps
		ornf	cx, mask HWRLS_CAP_LOCK	; cx = desired caps state
noCaps:
		xor	dx, cx
		jz	afterCaps		; already in desired state
		push	bx
		andnf	ax, not (mask HWRLS_CAP_LOCK)
		ornf	ax, cx			; set desired state
		;
		; ugh - if we are turning on CAPS locks, turn off EQN lock
		; and NUM lock (i.e. everything else) as the HWR engine treats
		; these as exclusives -- brianc 9/1/95
		;
		test	ax, mask HWRLS_CAP_LOCK
		jz	doIt
		mov	ax, mask HWRLS_CAP_LOCK	; turn everything else off
doIt:
		push	ax			; pass on stack
		mov	ax, HWRR_SET_LOCKED_STATE
		call	ProcGetLibraryEntry	; bx:ax = entry point
		call	ProcCallFixedOrMovable	; set new caps state
		pop	bx			; bx = library handle
afterCaps:
		push	bx
		mov	ax, HWRR_GET_TEMPORARY_SHIFT_STATE
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable	; al = HWRTemporaryShiftState
		pop	bx
		test	ds:[stickyState], mask TS_SHIFTSTICK
		jnz	shifted
		cmp	al, HWRTSS_DOWNCASE
		je	turnOffShift		; not in desired state
		cmp	al, HWRTSS_CASE
		jne	afterShift		; already in desired state
turnOffShift:
		mov	ax, 0			; turn off shift
		jmp	changeShift

shifted:
		cmp	al, HWRTSS_DOWNCASE
		je	afterShift		; already in desired state
		cmp	al, HWRTSS_CASE
		je	afterShift		; already in desired state
		mov	ax, -1			; turn on shift
changeShift:
		push	bx
		push	ax			; pass on stack
		mov	ax, HWRR_SET_SHIFT_STATE
		call	ProcGetLibraryEntry	; bx:ax = entry point
		call	ProcCallFixedOrMovable	; set new shift state
		pop	bx
afterShift:
		mov	ax, HWRR_END_INTERACTION
		call	ProcGetLibraryEntry	; bx:ax = entry point
		call	ProcCallFixedOrMovable	; end interaction
afterHWR:
		pop	ax
		retn
endif

invertScreen:
	;
	;  See if they've got the ON key mashed down...
		test	ds:[onOffFuncs], mask OOF_ON
		LONG jz	turnOffKeys	; => nope

	;
	;  See if this is the first time they've pressed
	;  the key...
		test	dl, mask CF_FIRST_PRESS
		LONG jz	done		; => nope

		ornf	ds:[onOffFuncs], mask OOF_INVERT

	;
	;  Tell video driver to invert the screen.
		push	ax, bx, si, ds

		mov	ax, GDDT_VIDEO
		call	GeodeGetDefaultDriver	; ax <- driver handle
		tst	ax				; have device?
		jz	doneInvert	; => Nope...

		mov_tr	bx, ax
		call	GeodeInfoDriver		; ds:si <- DriverInfoStruct

		mov	di, VID_ESC_INVERT_SCREEN
		call	ds:[si].DIS_strategy

doneInvert:
		pop	ax, bx, si, ds
		jmp	gulpGulpGulp

lockCategory	char	"ui",0
lockKey		char	"oneTimeLock",0

OLStickyRoutine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendKeyboardEventGCN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send GCN notification for sticky state

CALLED BY:	OLStickyRoutine
		OLFieldNotify
PASS:		ds = dgroup
RETURN:		nothing
DESTROYED:	bc, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendKeyboardEventGCN	proc	near
		push	ax			; do NOT gobble up key

		mov	ax, MSG_META_NOTIFY
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_KEYBOARD_EVENT
		clr	bx, si, bp
		mov	bl, ds:[stickyState]
		xchg	bx, bp
		mov	di, mask MF_RECORD
		call	ObjMessage		; ^hdi = classed event

		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_NOTIFY_KEYBOARD_EVENT
		mov	cx, di			; ^lcx = classed event
		clr	dx			; no extra data
		mov	bp, mask GCNLSF_FORCE_QUEUE
		call	GCNListSend 

		pop	ax			; restore key
		ret
SendKeyboardEventGCN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldSendKeyboardEventGCN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send out GCN notification

CALLED BY:	MSG_OL_FIELD_SEND_KEYBOARD_EVENT_GCN
PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		ds:bx	= OLFieldClass object (same as *ds:si)
		es 	= segment of OLFieldClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if SYNC_HWR_AND_KBD
OLFieldSendKeyboardEventGCN	method dynamic OLFieldClass, 
					MSG_OL_FIELD_SEND_KEYBOARD_EVENT_GCN
	mov	ax, segment dgroup
	mov	ds, ax
	call	SendKeyboardEventGCN
	ret
OLFieldSendKeyboardEventGCN	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAdjustContrast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust contrast setting

CALLED BY:	OLStickyRoutine
PASS:		ds	-> dgroup

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		Mark onOffFuncs

PSEUDO CODE/STRATEGY:
		indicate we did something with this on-off press
		Load the uC Driver
		  Send it a command
		Unload the uC Driver

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	2/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLAdjustContrast	proc	near
	uses	ax, bx, si, ds
	.enter
	;
	;  We are actually adjusting the contrast.  Do it man,
	;  just do it.
	;

		ornf	ds:[onOffFuncs], mask OOF_CONTRAST	; mark action

	;
	;  Load driver
	;
		segmov	ds, cs, si			; ds:si <- name
		mov	si, offset uCDriverName
		mov	ax, UC_PROTO_MAJOR
		mov	bx, UC_PROTO_MINOR

		call	GeodeUseDriver		; bx <- handle
		jc	done	; => Error


		call	GeodeInfoDriver		; ds:si <- DriverInfoStruct

	;
	;  Setup call to routine
	;

		mov	di, DR_UC_ADJUST_CONTRAST

		mov	ax, UCCA_INCREMENT_CONTRAST	; assume increase
		cmp	cl, C_PLUS
		je	calluCDriver	; => Actually increate

		mov	ax, UCCA_DECREMENT_CONTRAST	; assume increase

calluCDriver:
	;
	;  Actually call the driver
	;
						; ax <- uCContrastAdjustment
						; di <- uCDriverCommand
		call	ds:[si].DIS_strategy

	;
	;  Unload the driver
	;
		call	GeodeFreeDriver

done:
	.leave
	ret

NEC<	uCDriverName	char "uC Driver", 0			>
EC<	uCDriverName	char "EC uC Driver", 0			>

OLAdjustContrast	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPowerOnOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn the device Off (probably)

CALLED BY:	OLStickyRoutine
PASS:		ds	-> dgroup

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		Clears onOffFuncs

PSEUDO CODE/STRATEGY:
		See if we used the On-Off key to do anything else
		Call defaults power manager, telling
			them we have an on-off press

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	2/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPowerOnOff	proc	near
		uses	ax, bx, si, di, ds
		.enter
	;
	;  We've received an ON-OFF release.  If nothing happened
	;  between now and then, turn off the machine.
	;
		clr	al				; test & clear onOffFunc
		xchg	ds:[onOffFuncs], al

		test	al, mask OOF_ON
		jz	done			; => Bogus release on resume

		test	al, not (mask OOF_ON)
		jnz	done			; => already acted on ON-OFF
	;
	;  All looks good to turn off the machine.
	;  Tell Power Manager and let it figure out
	;  what to do next.
	;
		mov	ax, GDDT_POWER_MANAGEMENT
		call	GeodeGetDefaultDriver		; ax <- driver handle

		tst	ax				; have a driver?
		jz	done				; => no Power driver

		mov_tr	bx, ax				; bx <- driver handle
		call	GeodeInfoDriver			; ds:si <- DIS

		mov	bx, si				; ds:bx <- DIS

		mov	di, DR_POWER_ESC_COMMAND
		mov	si, POWER_ON_OFF_PRESS
		call	ds:[bx].DIS_strategy
done:
		.leave
		ret
OLPowerOnOff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle changes in HWR input mode

CALLED BY:	MSG_META_NOTIFY
PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		ds:bx	= OLFieldClass object (same as *ds:si)
		es 	= segment of OLFieldClass
		ax	= message #
		cx:dx - NotificationType
			cx - NT_manuf
			dx - NT_type
		bp - change specific data
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if SYNC_HWR_AND_KBD
OLFieldNotify	method dynamic OLFieldClass, MSG_META_NOTIFY
	cmp	cx, MANUFACTURER_ID_HP
	LONG jne	callSuper
	cmp	dx, JNT_HWR_INPUT_MODE_CHANGE
	LONG jne	callSuper
	;
	; update kbd state, if needed
	;	bp (high) = HWRTemporaryShiftState
	;	bp (low) = HWRLockState
	;
	mov	ax, GDDT_KEYBOARD
	call	GeodeGetDefaultDriver	; ax = keyboard driver handle
	tst	ax
	jz	done
	push	ds, si			; save OLField
	mov	bx, ax			; bx = kbd driver handle
	mov	ax, segment dgroup
	mov	ds, ax
	test	ds:[stickyState], mask TS_SHIFTSTICK
	pushf
	call	GeodeInfoDriver		; ds:si = driver info
	push	si
	mov	di, DR_KBD_GET_KBD_STATE
	call	ds:[si].DIS_strategy	; ah = ToggleState
	pop	si			; ds:si = DriverInfoStruct
	mov	al, ah			; al = current ToggleState
	andnf	al, mask TS_CAPSLOCK	; al = current caps state from kbd
	popf				; JNZ if TS_SHIFTSTICK
	jz	notShift
	ornf	al, mask TS_SHIFTSTICK
notShift:
	mov	cl, 0
	test	bp, mask HWRLS_CAP_LOCK
	jz	noCaps
	ornf	cl, mask TS_CAPSLOCK	; cx = desired caps state
noCaps:
	andnf	bp, 0xff00		; bp = HWRTemporaryShiftState
	cmp	bp, HWRTSS_DOWNCASE shl 8
	je	isShifted
	cmp	bp, HWRTSS_CASE shl 8
	jne	noShift
isShifted:
	ornf	cl, mask TS_SHIFTSTICK	; cx = desired shift state
noShift:
	xor	al, cl
	jz	afterCapShift		; already in desired state
	push	cx			; save desired shift states
	andnf	ah, not (mask TS_CAPSLOCK or mask TS_SHIFTSTICK)
	ornf	cl, ah			; stick in desired caps/shift state
	mov	ah, mask KSF_NEW_INDICATOR
	mov	di, DR_KBD_SET_KBD_STATE
	call	ds:[si].DIS_strategy
	mov	ax, segment dgroup
	mov	ds, ax
	pop	ax			; al = desired shift states
	andnf	ds:[stickyState], not (mask TS_CAPSLOCK or mask TS_SHIFTSTICK)
	ornf	ds:[stickyState], al
afterCapShift:
	pop	ds, si			; *ds:si = OLField
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_OL_FIELD_SEND_KEYBOARD_EVENT_GCN
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	done

callSuper:
	mov	di, offset OLFieldClass
	call	ObjCallSuperNoLock
done:
	ret
OLFieldNotify	endm
endif


Resident	ends

endif	; _JEDIMOTIF ----------------------------------------------------------
