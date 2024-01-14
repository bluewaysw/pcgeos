COMMENT @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinFieldOther.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_GEN_FIELD_ORDER_GEN_APPLICATION_LIST
				Look through windows on field, & rearrange
				our list of apps into the order that the
				appear on screen, top application first.

    INT FieldOrderCallBack

    MTD MSG_VIS_CLOSE           This routine closes any opened BG files.

    MTD MSG_GEN_FIELD_ABOUT_TO_DETACH_COMPLETE
				clobber express menu and tool area

    GLB CloseBGFile             Closes any active BG file

    MTD MSG_META_DETACH         Pass the detach on to the express menu, if
				any, so it can shut down gracefully.

    MTD MSG_GEN_FIELD_APP_NO_LONGER_EXITING
				Message sent by an app indicating that it
				has aborted quit.

    MTD MSG_META_KBD_CHAR       Field handler for MSG_META_KBD_CHAR.
				Passes event on to the current focus
				object, unless there is none, in which case
				send on to the superclass for default
				handling

    MTD MSG_META_FUP_KBD_CHAR   This method is sent by child which 1) is
				the focused object and 2) has received a
				MSG_META_FUP_KBD_CHAR which is does not
				care about. Since we also don't care about
				the character, we forward this method up to
				the parent in the focus hierarchy.

				At this class level, the parent in the
				focus hierarchy is either the generic
				parent (if this is a Display) or
				GenApplication object.

    MTD MSG_OL_FIELD_UPDATE_KBD_STATUS_BUTTONS
				Update the keyboard status buttons:
				CapsLock, NumLock, Ins/Over

    MTD MSG_OL_FIELD_TOGGLE_KBD_STATUS_BUTTON
				Toggle one of the keyboard status buttons

    GLB OLFieldDrawBG           Draws the background of the field.

    GLB GetBackgroundColorFromFile
				Gets the background color from the .ini
				file.

    GLB GetBackgroundColorNoPict
				Returns background washout (grey) color in
				AX

    GLB GetBackgroundColorPict  Returns background washout (grey) color in
				AX

    MTD MSG_GEN_FIELD_RESET_BG  This routine looks for a new bitmap file,
				and loads it if possible, after closing any
				old BM file

    INT OpenBGFile              This routine loads the bitmap file whose
				name is in the bitmap key in the ui
				category in the geos.ini file and stores
				the handle of this block in the instance
				data of the passed object

    MTD MSG_OL_FIELD_NAVIGATE_TO_NEXT_APP
				navigate to next navigatable app

    MTD MSG_OL_FIELD_NAVIGATE_TO_NEXT_APP
				navigate to next navigatable app

    MTD MSG_GEN_FIELD_ABOUT_TO_CLOSE
				Called when app field is about to close.
				In Redwood, we'll try to ensure that
				geoWrite is at the front.

    MTD MSG_META_QUERY_SAVE_DOCUMENTS
				Tells the application with the full screen
				exclusive to save its documents.

    MTD MSG_LAUNCHER_SET_FIELD  Sets the field optr.

    INT LaunchApplication       Launches app given the token

    MTD MSG_META_LOST_SYS_FOCUS_EXCL
				Losing system focus excl.  Stuck in here so
				that express menus go away if they've lost
				the system focus.

    MTD MSG_LAUNCH_THREAD_LAUNCH_APPLICATION
				Runs an application given its token

    GLB MyCreateDefaultLaunchBlock
				Create an AppLaunchBlock one can pass to
				IACPConnect presuming the following
				defaults: - IACP will locate the app, given
				its token - initial directory should be
				SP_DOCUMENT - no initial data file -
				application will determine generic parent
				for itself - no one to notify in event of
				an error - no extra data

    MTD MSG_LAUNCHER_LAUNCH_WRITE
				Launches GeoWrite

    MTD MSG_LAUNCHER_LAUNCH_TYPE
				Launches GeoWrite

    MTD MSG_LAUNCHER_LAUNCH_GEODEX
				Launches GeoWrite

    MTD MSG_LAUNCHER_LAUNCH_BIGCALC
				Launches GeoWrite

    MTD MSG_LAUNCHER_LAUNCH_PLANNER
				Launches GeoWrite

    MTD MSG_LAUNCHER_LAUNCH_SCRAPBOOK
				Launches GeoWrite

    MTD MSG_LAUNCHER_LAUNCH_GEOMANAGER
				Launches GeoWrite

    MTD MSG_LAUNCHER_LAUNCH_GEOCALC
				Launches GeoWrite

    MTD MSG_LAUNCHER_LAUNCH_DRAW
				Launches GeoWrite

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cwinField.asm


DESCRIPTION:

	$Id: cwinFieldOther.asm,v 1.5 98/07/20 13:05:41 joon Exp $

-----------------------------------------------------------------------------@

include Internal/fileInt.def


CommonUIClassStructures segment resource

	OLFieldClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

	ToolAreaClass		0

if (TOOL_AREA_IS_TASK_BAR or WINDOW_LIST_ACTIVE)
	WindowListDialogClass	mask CLASSF_DISCARD_ON_SAVE
	WindowListListClass	mask CLASSF_DISCARD_ON_SAVE
endif

if TOOL_AREA_IS_TASK_BAR
	TaskBarListClass	mask CLASSF_DISCARD_ON_SAVE
	SysTrayInteractionClass	mask CLASSF_DISCARD_ON_SAVE
endif

if EVENT_MENU
	EventMenuClass		mask CLASSF_DISCARD_ON_SAVE
endif

CommonUIClassStructures ends


;---------------------------------------------------


Exit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldOrderGenApplicationList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Look through windows on field, & rearrange our list of
		apps into the order that the appear on screen, top application
		first.

CALLED BY:	GenFieldShutdownApps

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_FIELD_ORDER_GEN_APPLICATION_LIST


RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLFieldOrderGenApplicationList	method dynamic	OLFieldClass,
					MSG_GEN_FIELD_ORDER_GEN_APPLICATION_LIST

	; Run through all the windows on this field, locating focusable
	; application objects for each one of standard priority. The ordering
	; of the windows gives us the order in which the application objects
	; should be.
	;
	mov	di, ds:[di].VCI_window		; di <- parent window
	mov	bp, si				; Get *ds:bp = GenField for
						; callback
	call	FieldCreateAppArrayFromWindows
	push	si

	; *ds:si is now a chunk array of application object optrs in the
	; order in which they should be. Use this ordering to adjust the one
	; stored with the field so all the focusable apps are in the order
	; dictated by the array, and everything else comes after.
	;

	mov	bx, cs
	mov	di, offset FieldOrderCallBack
	mov	ax, CCO_FIRST		; first thing in array becomes first
					;  in GenField's array...
	call	ChunkArrayEnum

	pop	ax
	call	LMemFree
	ret
OLFieldOrderGenApplicationList	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	FieldOrderCallBack

DESCRIPTION:

CALLED BY:	INTERNAL

PASS:		*ds:si	- chunk array
		*ds:bp	- GenField object
		ds:di	- element to process
		ax - CompChildFlags for this element

RETURN:		carry clear to continue
		ax - CompChildFlags for next element

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@

FieldOrderCallBack	proc	far	uses	bp
	.enter

	mov	si, bp			; *ds:si <- GenField
	mov_tr	bp, ax			; bp <- CompChildFlags
	push	bp
	movdw	cxdx, ({optr}ds:[di])
	mov	ax, MSG_GEN_FIELD_MOVE_GEN_APPLICATION
	call	ObjCallInstanceNoLock

	pop	ax
	inc	ax			; next app goes after this one

done:
	clc
	.leave
	ret
FieldOrderCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine closes any opened BG files.

CALLED BY:	GLOBAL
PASS:		standard object junk (*ds:si, ds:bx, ds:di, etc).
RETURN:		nada
DESTROYED:	various important but undocumented things

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFieldVisClose	method	dynamic OLFieldClass, MSG_VIS_CLOSE

	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_RELEASE_TARGET_EXCL
	call	ObjCallInstanceNoLock

	mov	bp, mask MAEF_FULL_SCREEN or mask MAEF_NOT_HERE
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_CLOSE
	mov	di, offset OLFieldClass
	CallSuper	MSG_VIS_CLOSE

ife	TRANSPARENT_FIELDS
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLFI_BGFile		;BX <- VM file handle
	jz	afterBG
	CallMod	CloseBGFile
afterBG:
endif

	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	UserCallSystem
	ret

OLFieldVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldAboutToDetachComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clobber express menu and tool area

CALLED BY:	MSG_GEN_FIELD_ABOUT_TO_DETACH_COMPLETE

PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		es 	= segment of OLFieldClass
		ax	= MSG_GEN_FIELD_ABOUT_TO_DETACH_COMPLETE

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/6/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFieldAboutToDetachComplete	method	dynamic	OLFieldClass,
					MSG_GEN_FIELD_ABOUT_TO_DETACH_COMPLETE
	;
	; clobber express menu/tool area
	;
	clr	ax
	xchg	ax, ds:[di].OLFI_expressMenu
	tst	ax
	jz	noExpressMenu
	call	clobber
noExpressMenu:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	ax
	xchg	ax, ds:[di].OLFI_toolArea

if TOOL_AREA_IS_TASK_BAR
	;
	; if TaskBar == on
	;
	push	ds					; save ds
	segmov	ds, dgroup				; load dgroup
	test	ds:[taskBarPrefs], mask TBF_ENABLED	; test if TBF_ENABLED is set
	pop	ds					; restore ds
	jz	hasNoTaskbar				; skip if no taskbar

	clr	ds:[di].OLFI_systemTray
hasNoTaskbar:

	tst	ax
	jz	noSystemTray
	call	clobber

noSystemTray:
endif

if EVENT_MENU
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	ax
	xchg	ax, ds:[di].OLFI_eventMenu
	tst	ax
	jz	noEventMenu
	call	clobber
noEventMenu:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	ax
	xchg	ax, ds:[di].OLFI_eventToolArea
	tst	ax
	jz	noToolArea2
	call	clobber
noToolArea2:
endif

if TOOL_AREA_IS_TASK_BAR or WINDOW_LIST_ACTIVE
	;
	; if TaskBar == on
	;
	; push	ds
	; segmov	ds, dgroup
	; tst	ds:[taskBarEnabled] ; if taskbar == on, ZF == 1
	; pop	ds
	; jz	noWindowListDialog ; if ZF==0 skip the following code

	;
	; clobber window list dialog
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	ax
	xchg	ax, ds:[di].OLFI_windowListDialog
	tst	ax
	jz	noWindowListDialog
	call	clobber

noWindowListDialog:
endif
	ret

;
; pass:
;	*ds:si = OLField
;	*ds:ax = object to remove
;
clobber:
	;
	; remove from windows list
	;
	push	si				; save OLField chunk
	push	ax				; save object chunk
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLP_optr.chunk, ax
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_WINDOWS
	mov	ax, MSG_META_GCN_LIST_REMOVE
	clr	bx				; use current thread
	call	GeodeGetAppObject		; ^lbx:si = app object
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size GCNListParams
	;
	; free object
	;
	pop	si			; *ds:si = object to clobber
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_NOW
	clr	bp
	call	ObjCallInstanceNoLock
	pop	si				; restore *ds:si = OLField
	retn
OLFieldAboutToDetachComplete	endm

ife	TRANSPARENT_FIELDS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseBGFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes any active BG file

CALLED BY:	GLOBAL
PASS: 		ds:di - OLFieldInstance data
RETURN:		nada
DESTROYED:	various important but undocumented things

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseBGFile	proc	far
	clr	bx
	xchg	bx, ds:[di].OLFI_BGFile		;BX <- VM file handle
	call	VMGetMapBlock
	call	VMLock				;Lock the VM block
	push	es
	mov	es, ax				;DS <- VM block handle
	cmp	es:[FBGMB_type], FBGFT_STANDARD_GSTRING
	jne	10$				;If GString, destroy gstring

						; handle.
	push	si
	clr	dx
	xchg	dx, ds:[di].OLFI_BGData		;Get GString handle in DX
	mov	si, dx				;SI <- GString handle
	clr	di				;DI <- no GState
	mov	dl, GSKT_LEAVE_DATA		;
	call	GrDestroyGString
	pop	si
10$:
	pop	es
	call	VMUnlock			;Unlock the map block
	mov	al, FILE_NO_ERRORS
	call	VMClose				;Close the file
	ret
CloseBGFile	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass the detach on to the express menu, if any, so it can
		shut down gracefully.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= OLField object
		ds:di	= OLFieldInstance
		cx	= ack ID
		^ldx:bp	= ack OD
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFieldDetach	method dynamic OLFieldClass, MSG_META_DETACH
		.enter
	;
	; Prepare for delayed detach.
	;
		call	ObjInitDetach
	;
	; If no express menu for this field, just pass the message to our
	; superclass.
	;
		mov	di, ds:[si]
		add	di, ds:[di].OLField_offset
		tst	ds:[di].OLFI_expressMenu
		jz	passItUp
	;
	; We'll be sending a MSG_META_DETACH to the express menu, so record
	; an ACK as needing to come in before we finish detaching.
	;
		push	ax, cx, dx, bp, si
		call	ObjIncDetach
	;
	; Send the MSG_META_DETACH to the express menu.
	;
		mov	dx, ds:[LMBH_handle]
		mov	bp, si
		mov	di, ds:[si]
		add	di, ds:[di].OLField_offset
		mov	si, ds:[di].OLFI_expressMenu
		mov	bx, dx
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		pop	ax, cx, dx, bp, si

passItUp:
if TOOL_AREA_IS_TASK_BAR
	;
	; if TaskBar == on
	;
		push	ds					; save ds
		segmov	ds, dgroup				; load dgroup
		test	ds:[taskBarPrefs], mask TBF_ENABLED	; test if TBF_ENABLED is set
		pop	ds					; restore ds
		jz	reallyPassItUp				; skip if no taskbar

	;
	; Check for system tray, and send it a detach
	;
		mov	di, ds:[si]
		add	di, ds:[di].OLField_offset
		tst	ds:[di].OLFI_systemTray
		jz	reallyPassItUp
	;
	; We'll be sending a MSG_META_DETACH to the system tray, so record
	; an ACK as needing to come in before we finish detaching.
	;
		push	ax, cx, dx, bp, si
		call	ObjIncDetach
	;
	; Send the MSG_META_DETACH to the system tray.
	;
		mov	dx, ds:[LMBH_handle]
		mov	bp, si
		mov	di, ds:[si]
		add	di, ds:[di].OLField_offset
		mov	si, ds:[di].OLFI_systemTray
		mov	bx, dx
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		pop	ax, cx, dx, bp, si

reallyPassItUp:
endif
	;
	; Let our superclass know.
	;
		mov	di, offset OLFieldClass
		call	ObjCallSuperNoLock
	;
	; And allow the detach complete, now that that's done.
	;
		call	ObjEnableDetach
		.leave
		ret
OLFieldDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldExitToDOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle ISUI version of "Exit To DOS" - "Shut Down..."

CALLED BY:	MSG_GEN_FIELD_EXIT_TO_DOS
PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		ds:bx	= OLFieldClass object (same as *ds:si)
		es 	= segment of OLFieldClass
		ax	= message #
RETURN:		carry set if handled "Exit To DOS"
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/26/02   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _ISUI
OLFieldExitToDOS	method dynamic OLFieldClass,
					MSG_GEN_FIELD_EXIT_TO_DOS
	mov	bx, handle ExitDialog
	mov	si, offset ExitDialog
EC <	push	ds:[LMBH_handle]					>
	call	UserCreateDialog
EC <	pop	ax							>
EC <	xchg	ax, bx							>
EC <	call	MemDerefDS						>
EC <	xchg	ax, bx							>
	tst	bx
	jz	done

	;
	; see if we're running under Windows
	;
	call	CheckForWindows
	jnc	notUnderWindows

	;
	; disable shutting down computer and rebooting when
	; running under Windows
	;
	push	si
	mov	si, offset ExitComputer
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_MANUAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, offset ExitReboot
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_MANUAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

notUnderWindows:
EC <	push	ds:[LMBH_handle]				>
	call	UserDoDialog
EC <	pop	di						>
EC <	xchg	bx, di						>
EC <	call	MemDerefDS					>
EC <	xchg	bx, di						>
	cmp	ax, IC_OK
	jne	destroyDialog

	push	si
	mov	si, offset ExitTypeList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	cmp	ax, SST_CLEAN
	je	shutdown
	cmp	ax, SST_CLEAN_REBOOT
	je	shutdown
	cmp	ax, SST_POWER_OFF
	jne	destroyDialog
shutdown:
	push	bx, si
	clr	cx, dx, bp
	call	SysShutdown
	pop	bx, si

destroyDialog:
	call	UserDestroyDialog
	stc			;carry <- set to indicate "Exit To DOS" handled
done:
	ret
OLFieldExitToDOS	endm

CheckForWindows	proc	near
		uses	ax, bx, cx, dx, bp, si, di, ds, es
		.enter

	;
	; copied from InitFSD:
	;
		mov	ax, MSDOS_GET_VERSION shl 8	; al = 0 so we know if
							;  DOS is < 2.0...
		call	FileInt21
	;
	; See if we're running in a Windows NT box...
	;
		cmp	ax, 5
		jne	notNT
		mov	ax, 3306h	;  DOS 5+ - GET TRUE VERSION
		call	FileInt21
		int	21h
		cmp	bx, 3205h 	; WINNT will always return ver 5.50
		jne	notNT
isWin:
		stc
done:
		.leave
		ret

	;
	; DOS version 6 or before is OK
	;
notNT:
;;		cmp	al, 6
;;		ja	isWin
;;		clc

	; Ed's improved code for determining the presence of Windows
		mov ax, 0x160A
		call SysLockBIOS
		int 0x2F
		call SysUnlockBIOS
		tst ax
		jz isWin
		clc

		jmp done
CheckForWindows	endp

endif ; _ISUI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldAppNoLongerExiting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message sent by an app indicating that it has aborted quit.

CALLED BY:	MSG_GEN_FIELD_APP_NO_LONGER_EXITING
PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		ds:bx	= OLFieldClass object (same as *ds:si)
		es 	= segment of OLFieldClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFieldAppNoLongerExiting	method dynamic OLFieldClass,
					MSG_GEN_FIELD_APP_NO_LONGER_EXITING
	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GFI_flags, mask GFF_QUIT_ON_CLOSE
	jz	done

	andnf	ds:[bx].GFI_flags, not mask GFF_QUIT_ON_CLOSE

	;
	; Notify all existing apps under this field that quit was aborted.
	;
	mov	bp, ds:[bx].GFI_genApplications
	tst	bp
	jz	done			; no genApps
	mov	bp, ds:[bp]
	inc	bp
	jz	done			; no genApps
	dec	bp
	jz	done			; no genApps
	ChunkSizePtr	ds, bp, cx	; cx = size
	shr	cx
	shr	cx			; cx = number of genApps
	jcxz	done			; no genApps

genAppLoop:
	push	cx, bp
	movdw	bxsi, ds:[bp]
	mov	ax, MSG_GEN_APPLICATION_FIELD_QUIT_ABORTED
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	cx, bp
	add	bp, size optr
	loop	genAppLoop
done:
	ret
OLFieldAppNoLongerExiting	endm

Exit	ends

;------------------

KbdNavigation	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Field handler for MSG_META_KBD_CHAR.  Passes event on to the
		current focus object, unless there is none, in which case
		send on to the superclass for default handling

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_KBD_CHAR
		cx - character value
			SBCS: ch = CharacterSet, cl = Chars
			DBCS: cx = Chars
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	9/923		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLFieldKbdChar	method dynamic	OLFieldClass, MSG_META_KBD_CHAR

	mov	bx, ds:[di].OLFI_focusExcl.FTVMC_OD.handle
	tst	bx
	jz	callSuper
	mov	si, ds:[di].OLFI_focusExcl.FTVMC_OD.chunk
	clr	di
	GOTO	ObjMessage

callSuper:
	mov	di, offset OLFieldClass
	GOTO	ObjCallSuperNoLock

OLFieldKbdChar	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLFieldFupKbdChar - MSG_META_FUP_KBD_CHAR handler for
		OLFieldClass

DESCRIPTION:	This method is sent by child which 1) is the focused object
		and 2) has received a MSG_META_FUP_KBD_CHAR
		which is does not care about. Since we also don't care
		about the character, we forward this method up to the
		parent in the focus hierarchy.

		At this class level, the parent in the focus hierarchy is
		either the generic parent (if this is a Display) or
		GenApplication object.

PASS:		*ds:si	= instance data for object
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if handled

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/21/92		initial version

------------------------------------------------------------------------------@

OLFieldFupKbdChar	method dynamic	OLFieldClass, MSG_META_FUP_KBD_CHAR

	;Don't handle state keys (shift, ctrl, etc).

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	callSuper			;let super handle

	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	callSuper			;let super handle

	;
	; If .ini flag says not to process kbd accelerators, don't
	;
	call	UserGetKbdAcceleratorMode	; Z set if off
	jz	callSuper			; skip all shortcuts

	push	si				;save our handle
	mov	si, ds:[di].OLFI_expressMenu
	tst	si				;is there one?
	clc					;assume not, let super handle
	jz	10$				;no, branch
if _ISUI or _MOTIF
	;
	; toggle express, if express key
	;
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_LWIN			>
DBCS <	cmp	cx, C_SYS_LWIN						>
	je	8$
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_RWIN			>
DBCS <	cmp	cx, C_SYS_RWIN						>
	jne	9$
8$:
	pop	si				;*ds:si = field
	mov	ax, MSG_OL_FIELD_TOGGLE_EXPRESS_MENU
	call	ObjCallInstanceNoLock
	stc					;indicate handled
	jmp	done

9$:
endif
	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_FIND_KBD_ACCELERATOR
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
10$:
	pop	si
	jc	done

if EVENT_MENU
	push	si				;save our handle
	mov	si, ds:[di].OLFI_eventMenu
	tst	si				;is there one?
	clc					;assume not, let super handle
	jz	15$				;no, branch
	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_FIND_KBD_ACCELERATOR
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
15$:
	pop	si
	jc	done
endif

if TOOL_AREA_IS_TASK_BAR or WINDOW_LIST_ACTIVE
	;
	; if TaskBar == on
	;
	; push	ds
	; segmov	ds, dgroup
	; tst	ds:[taskBarEnabled] ; if taskbar == on, ZF == 1
	; pop	ds
	; jz	callSuper ; if ZF==0 skip the following code

	push	si				;save our handle
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GFI_flags, mask GFF_QUIT_ON_CLOSE or mask GFF_DETACHING
	jnz	20$				;carry is clear
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLFI_windowListDialog
	tst	si				;is there one?
	clc					;assume not, let super handle
	jz	20$				;no, branch
	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_FIND_KBD_ACCELERATOR
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
20$:
	pop	si
	jc	done
endif

callSuper:
	mov	di, offset OLFieldClass
	call	ObjCallSuperNoLock
done:
	ret
OLFieldFupKbdChar	endm

KbdNavigation ends

;----------------------------
ife	TRANSPARENT_FIELDS

FieldBGDraw	segment	resource

if not _NO_FIELD_BACKGROUND


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldDrawBG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the background of the field.

CALLED BY:	GLOBAL
PASS:		*ds:si - field object
		di - gstate to draw to

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLFieldDrawBG	proc	far
	scrWidth	local	word
	scrHeight	local	word
	BGWidth		local	word
	BGHeight	local	word
	xoff		local	word
	yoff		local	word
	flags		local	FieldBGFlags
	gstate		local	hptr.GState
	notinvert	local	byte
	bltSrcX		local	word
	bltSrcY		local	word
	haveBltSource	local	word
	.enter
	push	ds, si
EC <	call	ECCheckObject						>
	mov	gstate, di			;Save the gstate
	call	VisGetBounds
	mov	scrWidth,cx
	mov	scrHeight,dx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	dl, ds:[di].OLFI_BGFlags	;DL <- flags
EC <	test	dl, not mask FieldBGFlags				>
EC <	ERROR_NZ OL_FIELD_BAD_BG_FLAGS					>
	mov	flags, dl
	mov	bx, ds:[di].OLFI_BGFile		;BX <- handle of BG file
	mov	si, ds:[di].OLFI_BGData		;SI <- extra data
						; (GString handle)

;	COPY GSTRING INFORMATION OUT OF MAP BLOCK

	call	VMGetMapBlock
	mov	dx, bp				;DX <- offset to locals
	call	VMLock
	xchg	dx, bp				;DX <- mem handle
						;BP <- ptr to locals
	mov	ds, ax
EC <	cmp	ds:[FBGMB_type], FBGFT_STANDARD_GSTRING			>
EC <	ERROR_NZ OL_FIELD_BAD_BG_FILE_TYPE				>
	mov	ax, ds:[FBGMB_width]
	mov	BGWidth, ax
	mov	ax, ds:[FBGMB_height]
	mov	BGHeight, ax
	mov	ax, ds:[FBGMB_xOffset]
	neg	ax
	mov	xoff, ax
	mov	ax, ds:[FBGMB_yOffset]
	neg	ax
	mov	yoff, ax
	xchg	dx, bp				;DX <- ptr to locals
						;BP <- mem handle
	call	VMUnlock
	mov	bp, dx				;BP <- ptr to locals
	cmp	flags, FBGDA_CENTER shl offset FBGF_DRAW_ATTR
	jne	afterCenter

;	ADJUST DRAWING POSITION IF CENTERED CHOSEN

	mov	ax, scrHeight			;
	sub	ax, BGHeight			;
	js	afterSetY			;Branch if taller than screen
	shr	ax, 1				;
	add	yoff, ax			;

afterSetY:

	mov	ax, scrWidth			;
	sub	ax, BGWidth			;
	js	afterCenter			;Branch if wider than screen
	shr	ax, 1				;
	add	xoff, ax			;

afterCenter:
	pop	ds, cx
	mov	di, gstate
	call	InvertColorIfPatternDrawOnBlackBackground
	;  ax - 0, ok to invert the background pattern color.
	;       1, not ok to invert the color
	mov	notinvert, al
;	DRAW THE GRAPHIC

	mov	haveBltSource, FALSE

	mov	bx, yoff			;
	mov	ax, BGWidth			;Adjust width and height here
	add	scrWidth, ax			; to allow tiling all the way
	mov	ax, BGHeight			; to the right and left edges
	add	scrHeight, ax
resetXLoop:
	mov	ax, xoff			;
drawLoop:
	tst	haveBltSource
	jz	drawIt
	;
	; if dest in not in mask, can't blt
	;
	call	checkBMInRect
	jnz	drawIt
	; blt it
	push	ax, bx, si
	mov	si, BGHeight
	push	si
	mov	si, BLTM_COPY
	push	si
	movdw	cxdx, axbx			; cx, dx = dest
	sub	cx, xoff
	sub	dx, yoff
	mov	ax, bltSrcX			; ax, bx = src
	mov	bx, bltSrcY
	sub	ax, xoff
	sub	bx, yoff
	mov	si, BGWidth
	call	GrBitBlt
	pop	ax, bx, si
	jmp	short doneDraw

drawIt:
	call	GrSaveState
	clr	dx
	; If the background is black and the
	; background pattern is black and white, invert the pattern color.
	tst	notinvert
	jnz	notInvert
	push	ax
	mov	al, MM_INVERT
	call	GrSetMixMode
	pop	ax
notInvert:
	call	GrDrawGString
	call	GrRestoreState
EC <	cmp	dx, GSRT_COMPLETE					>
EC <	ERROR_NE OL_ERROR						>
	push	ax				;Restore y pos
	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos
	pop	ax				;Restore x pos
	;
	; check if what we just drew can be used as blt source
	;
	call	checkBMInRect
	jnz	doneDraw
	mov	haveBltSource, TRUE
	mov	bltSrcX, ax
	mov	bltSrcY, bx
doneDraw:
	cmp	flags, FBGDA_TILE shl offset FBGF_DRAW_ATTR
	jnz	exit				;If not tiled, branch to leave.

	add	ax, BGWidth
	cmp	ax, scrWidth			;
	LONG jb	drawLoop
	add	bx, BGHeight			;
	cmp	bx, scrHeight			;
	LONG jb	resetXLoop			;
exit:
	.leave
	ret

;
; Z set if BM at ax, bx is in mask rect
; Z clr otherwise
;
checkBMInRect	label	near
	push	ax, bx
	sub	ax, xoff
	sub	bx, yoff
	movdw	cxdx, axbx
	add	cx, BGWidth
	add	dx, BGHeight
	call	GrTestRectInMask
	cmp	al, TRRT_IN
	pop	ax, bx
	retn

OLFieldDrawBG	endp

;
; Check the following conditions in order, quit and bail if any one
; condition fails:
; 1) The background color is black, quit if not
; 2) Draw pattern has only the following two gstring commands
;    (ignore offset, address, size):
;
;    Graphics String:
;    OFFSET   OPCODE
;    ------   ------
;    0x002a   GR_FILL_BITMAP_CP -- ^h20704:002dh, width=128, height=128, BMF_MONO, BMC_PACKBITS
;    0x07d1   GR_END_GSTRING
;
; 3) GRFillBitmap is BMF_MONO.
;
; The assumption is that a typical fixed, non-color, background pattern
; contains only two gstring commands and is black and white.
;
; If the above is all true, then invert the color.
;
; PASS:		di	- GState handle
;		si	- handle of GString to draw
;			  (as returned by GrLoadString)
;		ax,bx	- x,y coordinate at which to draw
;		dx	- control flags  (record of type GSControl):
;		*ds:cx - field object
;
InvertColorIfPatternDrawOnBlackBackground proc near
notInvertible		local	byte
	uses	bx, cx, dx, si, di
	.enter

	push	di, si
	; clear local variable
	lea	di, notInvertible
	mov	{byte}ss:[di], 1
	; get current color info
	mov	di, cx
	mov	di, ds:[di]
	add	di, ds:[di].Vis_offset
	mov	di,ds:[di].VCI_window		;DI <- the window handle
	mov	si, WIT_COLOR
	call	WinGetInfo
	pop	di, si
	; al - color index C_BLACK (0x0) to C_WHITE (0xf)
	; ah - WCF_TRANSPARENT if none, WIN_RGB if RGB colors
	;     low bits are color map mode
	cmp	al, C_BLACK
	jne	bail

	; di	- GState handle or 0
	; si	- handle of GString to draw
	mov	bx, cs				; callback segment
	mov	cx, offset CheckPatternCallback ; callback offset
	mov	dx, mask GSC_OUTPUT		; stop on outputs
	; dx	- control flags  (record of type GSControl):
	; bx:cx	- vfptr to callback routine
	clr	di
	call	GrCreateState			; create parsing state
	call	GrSaveState
	push	bp
	lea	bp, notInvertible
	mov	{byte}ss:[bp], 0		; assume invertable
	call	GrParseGString
	pop	bp
	call	GrRestoreState
	call	GrDestroyState

	; reset to the beginning of the gstring
	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos
bail:
	clr	ax
	mov	al, notInvertible
	.leave
	ret
InvertColorIfPatternDrawOnBlackBackground endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckPatternCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for parsing g-string elements

CALLED BY:	GrParseGString

PASS:		ds:si	- pointer to gstring element
		(byte)ss:bx	 - byge flag to be raised if pattern not
	                           good to be inverted.

RETURN:		ax	- true if finished
		ds	- as passed

DESTROYED:	cx,dx,si,di

PSEUDO CODE/STRATEGY:
	Raise the no-no flag when we see a non-fill-bitmap gstring command.
	And raise the no-no flag if it's a color pattern.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	edwin	10/08/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckPatternCallback	proc	far

	cmp	{byte}ds:[si], GR_FILL_BITMAP_CP
	jne	raiseFlag

	mov	di, bx
	add	si, size OpDrawBitmap	; skip to beginning of actual bitmap
	cmp	ds:[si].B_type, BMF_MONO shl offset BMT_FORMAT
	je	continue

raiseFlag:
	cmp	{byte}ss:[bx], 1
	jne	set
	mov	ax, 0xffff	; it's already an invalid picutre, quit
	ret
set:
	mov	{byte}ss:[bx], 1

continue:
	; continue scanning
	clr	ax
	ret

CheckPatternCallback	endp



endif	; not _NO_FIELD_BACKGROUND

FieldBGDraw	ends


FieldBG	segment resource

if not _NO_FIELD_BACKGROUND


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBackgroundColorFromFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the background color from the .ini file.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		carry set if couldn't find color in .ini file
		      else carry clear, AL = BG color
DESTROYED:	nada

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
backgroundColorKey	char	BACKGROUND_COLOR_KEY,0
GetBackgroundColorFromFile	proc	near
	uses	cx, dx, si, ds
	.enter
	mov	cx, cs
	mov	ds, cx
	mov	si, offset backgroundCategory
	mov	dx, offset backgroundColorKey
if DBCS_PCGEOS
	clr	bp
	call	InitFileReadString
	jc	exit			;Exit if key not found in .ini file

	call	MemLock
	mov	ds, ax
	clr	si
	call	UtilAsciiToHex32	;dx:ax = value
	pushf
	call	MemFree
	popf
	jc	exit
	tst	dx			;illegal value?
	stc
	jnz	exit
else
	call	InitFileReadInteger
	jc	exit			;Exit if key not found in .ini file
endif

	cmp	ax, Color		;Clears carry if value out of range
	cmc				;Switches carry (so carry is set if
					; the value was out of range)
exit:
	.leave
	ret
GetBackgroundColorFromFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBackgroundColorPict, GetBackgroundColorNoPict
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns background washout (grey) color in AX

CALLED BY:	GLOBAL
PASS:		*ds:si - Field instance
RETURN:		ax - Window color param
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	8/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBackgroundColorNoPict	proc	far
	uses	es
	.enter

	mov	ax, segment dgroup		; Make sure es is dgroup
	mov	es, ax
	;
	; If not drawing picture, wash with grey pattern on B/W screen.
	;
	test	es:[moCS_flags], mask CSF_BW
	mov	al, C_BW_GREY			;assume B/W: get "color"
						;which B&W driver will draw
						;as 50% pattern.
	jnz	exit			;Branch if B&W system
	call	GetBackgroundColorFromFile
	jnc	exit			;Branch if color specified in .ini file
	;
	; OpenLook: grab "light/dark" color scheme from Field object
	;
OLS <	mov	al, es:[moCS_dsDarkColor]				>
	;
	; CUA/Motif: grab color value from color scheme variables in idata
	;
CUAS <	mov	al, es:[moCS_screenBG]					>
exit:
	mov	ah, mask WCF_PLAIN or CMT_DITHER

	.leave
	ret
GetBackgroundColorNoPict	endp


GetBackgroundColorPict		proc	far	uses es
	.enter
	mov	ax, segment dgroup		;Make sure es is dgroup
	mov	es, ax
	mov	al, C_WHITE
	test	es:[moCS_flags], mask CSF_BW
	jnz	exit			;Branch if B&W  (don't read
					; color from file, just use
					; white).

	call	GetBackgroundColorFromFile
	jnc	exit			;Branch if color specified in .ini file
80$:
	;If drawing picture, do not wash with grey pattern on B/W screen, but
	; instead wash with a solid (e.g. white) pattern

	;OpenLook: grab "light/dark" color scheme from Field object
OLS <	mov	al, es:[moCS_dsLightColor]				>
	;CUA/Motif: grab color value from color scheme variables in idata
CUAS <	mov	al, es:[moCS_screenBG]					>
exit:
	mov	ah, CMT_CLOSEST or mask CMM_ON_BLACK
	.leave
	ret

GetBackgroundColorPict	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldResetBG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine looks for a new bitmap file, and loads it if
		possible, after closing any old BM file

CALLED BY:	GLOBAL
PASS:		*ds:si - Field object
RETURN:		nada
DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFieldResetBG	method	dynamic OLFieldClass, MSG_GEN_FIELD_RESET_BG

	tst	ds:[di].OLFI_BGFile		;BX <- VM file handle
 	je	nofile

	CallMod	CloseBGFile
nofile:
	call	OpenBGFile			;Load the new BG file
	jc	OLFNB_error			;If none open, branch
	call	GetBackgroundColorPict		;Get appropriate gray color
	jmp	short OLFNB_exit

OLFNB_error:					;Make washout color be gray
	call	GetBackgroundColorNoPict	;Get appropriate gray color

OLFNB_exit:
	push	si
	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset		;Get ptr to vis instance data
	mov	di,ds:[di].VCI_window		;DI <- the window handle
	mov	si, WIT_COLOR
	call	WinSetInfo
	pop	si
	call	VisGetBounds
	clr	bp				;Rectangular region
	mov	si,bp
if (1)
	call	WinInvalTree			;Invalidate the entire tree
						; so other windows that draw
						; background can also redraw
						; (NewDesk).
else
	call	WinInvalReg			;Invalidate the region so the
endif						; bitmap will redraw
	ret
OLFieldResetBG	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenBGFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine loads the bitmap file whose name is in the bitmap
		key in the ui category in the geos.ini file and stores the
		handle of this block in the instance data of the passed object

CALLED BY:	OLFieldOpenWin, OLFieldResetBG

PASS:		*ds:si - field object
RETURN: 	carry - set if couldn't load bitmap (ax/bx are invalid)
DESTROYED:	cx,dx,di,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Changes the CWD

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/15/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString backgroundDir <BACKGROUND_DIR,0>
backgroundCategory	char	BACKGROUND_CATEGORY,0
backgroundKey		char	BACKGROUND_NAME_KEY,0
attrKey			char	BACKGROUND_ATTR_KEY,0
;	Either "Tiled", "Centered" or "None" are appropriate here

OpenBGFile	proc	far
	uses	es

	attrStr	local	2 dup (TCHAR)

	.enter
	push	bp

EC <	call	ECCheckObject						>
	;
	; GET BACKGROUND ATTRIBUTES
	;
	push	ds,si				;Save ptr to object
	mov	cx,cs				;CX,DS <- segment of
	mov	ds,cx				; backgroundCategory/Key
	mov	si, offset backgroundCategory	;DS:SI <- category ASCIIZ str
	mov	dx, offset attrKey		;
	segmov	es, ss, di			;ES:DI <- ptr to dest for chars
	lea	di, attrStr			;
SBCS <	mov	bp,INITFILE_DOWNCASE_CHARS or 2	;Only get first char+null>
DBCS <	mov	bp,INITFILE_DOWNCASE_CHARS or (2 * size TCHAR)	;Space for 1st>
DBCS <								; char + null>
	call	InitFileReadString		;
	pop	ds, si				;Restore and save ptr to object
	push	ds, si				;
	mov	al, FBGDA_CENTER shl offset FBGF_DRAW_ATTR
	jc	5$				;Branch if string not found
	mov	al, FBGDA_TILE shl offset FBGF_DRAW_ATTR
	cmp	{byte} es:[di], 't'		;If tiling wanted, branch
	je	5$				;
	mov	al, FBGDA_CENTER shl offset FBGF_DRAW_ATTR
	cmp	{byte} es:[di], 'c'		;If centered wanted, branch
	je	5$				;
	mov	al, FBGDA_UPPER_LEFT shl offset FBGF_DRAW_ATTR
5$:						;
	mov	di, ds:[si]			;
	add	di, ds:[di].Vis_offset		;
	mov	ds:[di].OLFI_BGFlags, al

	;
	; GET FILENAME OF BACKGROUND FILE
	;
	mov	cx, cs				;CX,DS <- segment of keys
	mov	ds, cx
	mov	si, offset backgroundCategory	;DS:SI <- category ASCIIZ str
	mov	dx, offset backgroundKey	;CX:DX <- key ASCIIZ str
	clr	bp				;Alloc space for entry
	call	InitFileReadString		;Returns carry clear if found,
						; and BX is handle of filename
	LONG jc	exit				;Exit if none found

	;
	; TRY TO OPEN FILENAME
	;

	;
	; Set the CWD to the "backgrnd" directory under PUBDATA
	;

	mov	bp, bx			;BP <- mem handle of filename
	mov	bx, SP_PUBLIC_DATA
	segmov	ds, cs
	mov	dx, offset backgroundDir
	call	FileSetCurrentPath
	jc	freeAndError

	mov	bx, bp
	call	MemLock				;Lock file name
	mov	ds,ax				;DS:DX <- ptr to file name
	clr	dx
SBCS <	cmp	{char} ds:[0], 0	;null-terminator only?		>
DBCS <	cmp	{wchar} ds:[0], 0	;null-terminator only?		>
					;(should check earlier, but regs are
					;	too grody)
	stc				;assume so
	je	freeAndError		;if so, fake an error


	mov	ax, (VMO_OPEN shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE or mask VMAF_FORCE_READ_ONLY
	clr	cx
	call	VMOpen			;Try to open background file
freeAndError:
	pushf				;Save error flag
	xchg	bx, bp
	call	MemFree			;Free up pathname
	xchg	bx, bp			;BX <- VM file handle
	popf				;Restore error flag
	LONG jc	exit			;If we can't open the file, branch

;	DO SANITY CHECKING ON BG FILE DATA

	sub	sp, size GeodeToken
	mov	di, sp
	segmov	es, ss
	mov	cx, size GeodeToken
	mov	ax, FEA_TOKEN
	call	FileGetHandleExtAttributes
	mov	bp, di
	cmp	{word} ss:[bp].GT_chars[0], 'BK'
	jne	10$
	cmp	{word} ss:[bp].GT_chars[2], 'GD'
	jne	10$
	CheckHack <size ProtocolNumber le size GeodeToken
	mov	ax, FEA_PROTOCOL
	call	FileGetHandleExtAttributes
	cmp	ss:[bp].PN_major, BG_PROTO_MAJOR
	jne	10$
	cmp	ss:[bp].PN_minor, BG_PROTO_MINOR
	jb	10$
	cmp	bp, bp
10$:
	lea	sp, ss:[bp+size GeodeToken];Nuke stack frame
	jne	closeandexit

	call	VMGetMapBlock		;Get the map block
	call	VMLock			;Lock the map block
	mov	ds, ax			;
	mov	si, ds:[FBGMB_data]	;Get extra word of data (first block of
					; GString)
	cmp	ds:[FBGMB_type], FBGFT_STANDARD_GSTRING
EC <	ERROR_NZ OL_FIELD_BAD_BG_FILE_TYPE				>
	call	VMUnlock		;Unlock the map block (flags not
					; changed)
	jne	closeandexit		;If we don't understand this format,
					; exit

;	CREATE A GRAPHICS STRING OUT OF THE DATA

	mov	cl, GST_VMEM		;
	call	GrLoadGString		;
	xchg	si, ax			;AX <- handle of GString
	pop	ds, si

;	SAVE INFORMATION IN INSTANCE DATA

	mov	di, ds:[si]		;Get ptr to spec data
	add	di, ds:[di].Vis_offset	;
	mov	ds:[di].OLFI_BGFile, bx	;Save file handle
	mov	ds:[di].OLFI_BGData, ax	;Save GString handle
	clc				;Signify no error
	jmp	nopopexit		;
closeandexit:
	mov	al, FILE_NO_ERRORS
	call	VMClose			;
	stc				;
exit:
	pop	ds,si			;Restore object block addr
nopopexit:
	pop	bp
	.leave
	ret
OpenBGFile	endp

endif	; not _NO_FIELD_BACKGROUND

FieldBG	ends
endif

KbdNavigation	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldNavigateToNextApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	navigate to next navigatable app

CALLED BY:	MSG_OL_FIELD_NAVIGATE_TO_NEXT_APP

PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		es 	= segment of OLFieldClass
		ax	= MSG_OL_FIELD_NAVIGATE_TO_NEXT_APP

		if (not _ISUI)
		    ^lcx:dx	= current app
		    ^hbp = event to dispatch when app to navigate to is found

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/5/93  	Initial version
	joon	3/14/93		PM version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if (not _ISUI)	;--------------------------------------------------------------

OLFieldNavigateToNextApp	method	dynamic	OLFieldClass,
					MSG_OL_FIELD_NAVIGATE_TO_NEXT_APP

;we do not do this as ordering screws up with the Desk Accessory layer,
;instead we move to the front of the GFI_genApplications list any GenApp
;that gains the focus excl - brianc 1/5/92
if 0
	;
	; first, order all apps based on window layering
	; (sorts GFI_genApplications)
	;
	push	cx, dx, bp		; save current app, event
	mov	ax, MSG_GEN_FIELD_ORDER_GEN_APPLICATION_LIST
	call	ObjCallInstanceNoLock
	pop	di, dx, bp		; restore current app (^ldi:dx), event
else
	mov	di, cx			; ^ldi:dx = current app
endif
	;
	; then traverse the list, looking for the current app, return the
	; next navigatable one
	;	^ldi:dx = current app
	;
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	si, ds:[si].GFI_genApplications
	tst	si
	jz	done			; no genApps
	mov	si, ds:[si]
	inc	si
	jz	done			; no genApps
	dec	si
	jz	done			; no genApps
	ChunkSizePtr	ds, si, cx	; cx = size
	shr	cx
	shr	cx			; cx = number of genApps
	jcxz	done			; no genApps
	push	bp			; save passed event
	clr	ax			; no first app, yet
genAppLoop:
	;
	; always take care of getting first app
	;	^lax:bp = first app (ax=0 if not found yet)
	;	^ldi:dx = current app (di=0 to return this app)
	;
	tst	ax
	jnz	haveFirstOne
	mov	ax, ({optr} ds:[si]).handle
	mov	bp, ({optr} ds:[si]).chunk
haveFirstOne:
	;
	; if we just want to return this one, do so
	;
	tst	di
	jz	useThisOne
	;
	; else, compare
	;
	cmp	di, ({optr} ds:[si]).handle
	jne	continue
	cmp	dx, ({optr} ds:[si]).chunk
	jne	continue
	;
	; found current app, set di=0 to return next one
	;
	clr	di
continue:
	add	si, size optr
	loop	genAppLoop
	movdw	bxsi, axbp			; no next app found, use first
	jmp	short tryNavigateToApp

useThisOne:
	mov	bx, ({optr} ds:[si]).handle
	mov	si, ({optr} ds:[si]).chunk
tryNavigateToApp:
	;
	; app may not be focusable or interactible, so "try" to navigate
	; to it, if not possible, will advance to next app
	;	^lbx:si = app to try to navigate to
	;
	pop	bp				; bp = passed event
	mov	ax, MSG_OL_APP_TRY_NAVIGATE_TO_APP
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
done:
	ret
OLFieldNavigateToNextApp	endm

else	; ISUI ---------------------------------------------------------------

;
; ISUI just selects the next item in the window list.
;
OLFieldNavigateToNextApp	method	dynamic	OLFieldClass,
					MSG_OL_FIELD_NAVIGATE_TO_NEXT_APP
	;
	; Get current selection
	;
	mov	si, ds:[di].OLFI_windowListList
	tst	si
	jz	done

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock
	jc	done

	mov	bx, si				; *ds:bx = item group
	mov_tr	si, ax				; *ds:si = item

	;
	; Send notification to the next entry (which will provide
	; behavior of relaying notification to window)
	;
	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	call	GenCallNextSibling
	jc	done				; done if message handled

	;
	; Next entry was not found, so we go to the first entry in the list.
	;
	mov	si, bx				; *ds:si = item group

	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	clr	cx				; find first child
	call	ObjCallInstanceNoLock
	jc	done				; abort if child not found

	mov	si, dx
	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	GOTO	ObjCallInstanceNoLock
done:
	ret
OLFieldNavigateToNextApp	endm

endif	; if (not _ISUI) -----------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldQuerySaveDocuments --
		MSG_META_QUERY_SAVE_DOCUMENTS for OLFieldClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Tells the application with the full screen exclusive
		to save its documents.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_QUERY_SAVE_DOCUMENTS
		cx	- ClassedEvent to dispatch when documents saved

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/25/94         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if VOLATILE_SYSTEM_STATE

OLFieldQuerySaveDocuments	method dynamic	OLFieldClass, \
				MSG_META_QUERY_SAVE_DOCUMENTS
	.enter
	movdw	bxsi, ds:[di].OLFI_fullScreenExcl.FTVMC_OD
	tst	si
	jz	exit
	clr	di
	call	ObjMessage
exit:
	.leave
	ret
OLFieldQuerySaveDocuments	endm

endif

KbdNavigation	ends
