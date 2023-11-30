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

	$Id: cwinFieldInit.asm,v 1.3 98/03/18 01:35:10 joon Exp $

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

ISU <	call	OLFieldEnsureWindowListDialog				>
MO  <	call	OLFieldEnsureWindowListDialog				>

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

	clr	bp			;pass CompChildFlags
	mov	ax, MSG_GEN_FIELD_CREATE_EXPRESS_MENU
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLFI_expressMenu, dx	; store chunk handle of menu
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

;if _ISUI ;--------------------------------------------------------------------

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
done:
	ret
OLFieldEnsureWindowListDialog	endp

;endif ;---------------------------------------------------------------------


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
	LONG jnz	done

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
if EXTENDIBLE_SYSTEM_TRAY
if _ISUI
	;
	; Find the system tray. Since it's copied during via COPY_TREE, we
	; don't know the chunk handle. This code is dependent on the order
	; of the children, so if anything gets changed in the
	; ExpressMenuResource...
	;
	push	cx, dx
	push	si
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	mov	cx, 1	; object SysTray is 2nd child of ToolArea
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
NEC <	jc	cantFindSysTray						>
EC <	ERROR_C	OL_ERROR_CANT_FIND_SYSTRAY_OBJECT			>
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	mov	bx, cx
	mov	si, dx
	mov	cx, 0	; object SysTrayExpress is 1st child of SysTray
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	; EC - Ensure the object we found is actually an ExpressMenuControl
NEC <	jc	cantFindSysTray						>
EC <	ERROR_C OL_ERROR_CANT_FIND_SYSTRAY_OBJECT			>
EC <	mov	si, dx							>
EC <	push	es							>
EC <	mov	di, segment ExpressMenuControlClass			>
EC <	mov	es, di							>
EC <	mov	di, offset ExpressMenuControlClass			>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC OL_ERROR_CANT_FIND_SYSTRAY_OBJECT			>
EC <	pop	es							>
	pop	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLFI_systemTray, dx
NEC < cantFindSysTray:							>
	pop	cx, dx
elseif _MOTIF
	;
	; Find the system tray. Since it's copied during the COPY_TREE, we
	; don't know the chunk handle. So, we've got to find it. This code
	; is entirely dependant on the order of the children, so if anything
	; gets changed in ExpressMenuResource, this code has to be changed too
	;
	push	cx, dx
	push	si
	; Creating floating systray
	mov	cx, ds:[LMBH_handle]	; block to copy into
	clr	dx
	mov	bx, handle FloatingSysTray
	mov	si, offset FloatingSysTray
	mov	ax, MSG_GEN_COPY_TREE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	clr	bp		; no special CompChildFlags
	call	ObjMessage

	pop	si
	push	si
	call	GenAddChildUpwardLinkOnly
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLFI_floatingSystemTray, dx
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	mov	cx, 1	; object SysTray is 2nd child of FloatingSysTray
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
NEC <	jc	cantFindSysTray						>
EC <	ERROR_C	OL_ERROR_CANT_FIND_SYSTRAY_OBJECT			>
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	mov	bx, cx
	mov	si, dx
	mov	cx, 0	; object SysTrayExpress is 1st child of SysTray
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
EC <	ERROR_C OL_ERROR_CANT_FIND_SYSTRAY_OBJECT			>
NEC <	jc	cantFindSysTray						>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLFI_systemTray, dx
	mov	bx, ds:[LMBH_handle]
	mov	si, ds:[di].OLFI_floatingSystemTray
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
NEC < cantFindSysTray:							>
	pop	cx, dx
else
	.err < SysTray init code not written for this SPUI >
endif
endif

	; Get it up on screen (a queue delay later)
	;
	mov	bx, cx
	mov	si, dx
if TOOL_AREA_IS_TASK_BAR
	; init position
	mov	ax, MSG_TOOL_AREA_INIT_POSITION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
endif
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

	test	ax, mask UIEO_DOCUMENTS_LIST
	pushf				; save documents list flag
	mov	cl, width UIEO_POSITION
	shr	ax, cl			; ax = ExpressMenuControlFeatures
	popf				; restore documents list flag
	jz	10$
	ornf	ax, mask EMCF_DOCUMENTS_LIST
10$:
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
	mov	ax, ((mask WCF_PLAIN or CMT_DITHER) shl 8) or C_BLACK
					; default to black (GEOS boots to
					;	black screen - we want avoid
					;	color changes here)

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

Init	ends
