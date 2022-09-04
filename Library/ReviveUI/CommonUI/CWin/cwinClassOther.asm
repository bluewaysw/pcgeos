COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinClassOther.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_VIS_CLOSE           This procedure is called when the UI is
				closing this windowed object's window. If
				this window has unique state data (has been
				moved or resized, or has a staggered slot
				#) then we save some state data in the
				vardata so that this state can be restored
				when the window is re-opened.

    INT OpenWinCheckMenuState   This procedure is called when the UI is
				closing this windowed object's window. If
				this window has unique state data (has been
				moved or resized, or has a staggered slot
				#) then we save some state data in the
				vardata so that this state can be restored
				when the window is re-opened.

    INT OpenWinFreeStaggeredSlot 
				This procedure releases a window's
				staggered slot, IF the specific ui or
				application has indicated that this
				window's position should not persist
				between appearances.

    INT OpenWinPrepForReOpen    This procedure updates a windowed object's
				instance data in the expectation that the
				object will be re-opened soon. "Soon" means
				before the ObjectBlock is compacted or the
				application is shut-down. In one of those
				cases, the object will carry the info we
				need - see OpenWinSaveState.

    INT OpenWinDetaching        This procedure updates a windowed object's
				instance data in the expectation that the
				object will be re-opened soon. "Soon" means
				before the ObjectBlock is compacted or the
				application is shut-down. In one of those
				cases, the object will carry the info we
				need - see OpenWinSaveState.

    INT OpenWinSaveState        This saves this window's current
				positioning, sizing, and staggering state.

    INT OpenWinUpdateModalStatus 
				If current object is a modal window, notify
				app, & system, if necessary, that something
				about the window has changed
				(open/close/priority change)

    MTD MSG_GEN_LOWER_TO_BOTTOM This function lowers the window to the
				bottom of its window priority group, & and
				if using a point & click kbd focus model, &
				then releases the focus & target, if the
				window has it, and requests the app to pick
				new focus/target windows.

    INT AvoidMenuOverlap        Moves menu to try to avoid a menu overlap,
				in one direction.

    MTD MSG_VIS_VUP_RELEASE_MENU_FOCUS 
				This forces us to exit menu navigation, if
				in progress.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cwinClass.asm

DESCRIPTION:

	$Id: cwinClassOther.asm,v 1.13 96/06/05 18:19:24 kho Exp $

------------------------------------------------------------------------------@

WinOther	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinVisClose -- MSG_VIS_CLOSE for OLWinClass

DESCRIPTION:	This procedure is called when the UI is closing this windowed
		object's window. If this window has unique state data
		(has been moved or resized, or has a staggered slot #) then
		we save some state data in the vardata so that this state
		can be restored when the window is re-opened.

PASS:
	*ds:si - instance data
RETURN:
	cl - ?
	ch - ?
	dx - ?
	bp - ?

DESTROYED:
	ax, bx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
	Eric	11/89		Split off into routine, Updated state-saving

------------------------------------------------------------------------------@

OpenWinVisClose	method dynamic	OLWinClass, MSG_VIS_CLOSE
	mov	di, 1200
	call	ThreadBorrowStackSpace
	push	di

if _CUA_STYLE	;--------------------------------------------------------------
	; if the system menu is on our active list then remove it
	;
	call	WinOther_DerefVisSpec_DI
	mov	bx, ds:[di].OLWI_sysMenu	;*ds:si = system menu
	tst	bx
	jz	noSystemMenu

if not _REDMOTIF ;----------------------- Not needed for Redwood project
	test	ds:[di].OLWI_menuState, mask OWA_SYS_MENU_IS_CLOSE_BUTTON
	jnz	noSystemMenu

	call	ObjSwapLock
	push	bx, si
	mov	si, offset StandardWindowMenu
				;remove hint indicating REALIZABLE
				; & nuke entry on window list
	call	OLWinTakeOffWindowList
	pop	bx, si
	call	ObjSwapUnlock
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

noSystemMenu:
endif		;--------------------------------------------------------------

if _RUDY; -------------------------------------------------------------------
	;
	; See if this is the indicator window. If so, clear the global
	; indicatorPrimaryWindow.
	;
	push	es
	call	WinOther_DerefVisSpec_DI
	mov	bx, handle dgroup
	call	MemDerefES			; es <- dgroup

	mov	ax, es:[indicatorPrimaryWindow]
	cmp	ds:[di].VCI_window, ax
	jne	notIndicator

	;
	; Get exclusive access
	;
	PSem	es, indicatorWindowMutex
	;
	; Making the global zero is not good enough, because
	; OLAppEnsureIndicatorCorrect will try to find the window
	; handle again.
	;
	mov	es:[indicatorPrimaryWindow], \
			RUDY_INDICATOR_WINDOW_ALREADY_CLOSED	; -1
	VSem	es, indicatorWindowMutex
	
notIndicator:
	pop	es

endif	; RUDY	--------------------------------------------------------------

	;release the FOCUS and TARGET exclusives, so our parent
	;(GenDisplayGroup or OLField) will grab the keyboard grab for itself,
	;to ensure that application-global shortcuts still work. Releasing these
	;exclusives here instead of in the UN_BUILD handler is fine because
	;the INITIATE_INTERACTION handler for windows grabs these exclusives.
	;Do this after calling superclass to close window only to avoid
	;unecessary gadget drawing.
	;
	mov	ax, MSG_META_RELEASE_FT_EXCL
	call	ObjCallInstanceNoLock

					; If window is grabbed, force release
	mov	cx, TRUE		;(even if is menu in stay-up mode)
	mov	ax, MSG_OL_WIN_END_GRAB
	call	WinOther_ObjCallInstanceNoLock

	;Even though OpenWinEndGrab (called above) takes the GADGET exclusive,
	;it only does so if there is no menu in stay-up-mode. Since we know
	;this window is closing, we want to grab the GADGET exclusive
	;in ANY case. This will close menus which were held open by the user,
	;or opened as this window is closing.

	clr	cx			;grab active exclusive semaphore:
	clr	dx			;will notify menu and force it to
					;close up toute suite.
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	call	WinOther_ObjCallInstanceNoLock

	; ALWAYS try to release any pre-passive grab that this window
	; has going, because it has just become too dang hard to know whether
	; or not one was added somewhere along the line -- for UNIV_ENTER,
	; navigation, etc.  Even OpenWinEndGrab (called above) appears also to
	; add this window back onto the pre-passive grab list.  -- Doug
	; 
	call	VisRemoveButtonPrePassive

	;call superclass (OLCtrlClass) for default handling
	;
	mov	ax, MSG_VIS_CLOSE
	call	WinOther_ObjCallSuperNoLock_OLWinClass

	;if this is a menu window, update the "NEVER_SAVE_STATE" attribute
	;according to whether menu is pinned. (CUA: sets TRUE always)
	;
	call	OpenWinCheckMenuState	;updates OLWI_winPosSizeFlags

	;if this window DOES NOT PERSIST, release its staggered slot # it is
	;has one. This will affect both the instance data for the object
	;and the data that might be saved.  (Primaries
	;keep their slot until they exit now. -cbh 6/29/90)
	;
	call	WinOther_DerefVisSpec_DI
CUAS <	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW			>
OLS <	cmp	ds:[di].OLWI_type, OLWT_BASE_WINDOW			>
    	je	prepForReOpen			;primaries release slot on exit
CUAS <	cmp	ds:[di].OLWI_type, MOWT_WINDOW_ICON			>
OLS <	cmp	ds:[di].OLWI_type, OLWT_WINDOW_ICON			>
    	je	prepForReOpen			;icons release slot on exit
	call	OpenWinFreeStaggeredSlot	
prepForReOpen:
	;now update this object's data in case it is re-opened soon
	;(i.e. meaning the object is not consulted for data)
	call	OpenWinPrepForReOpen
	pop	di
	call	ThreadReturnStackSpace
if _RUDY
	clr	ax
	call	RudyRememberIfHelpIsUp
	;
	; When a window closes, call a message to make sure the
	; Indicator floats or sinks correctly.  -- kho, 9/25/95
	; Re-enabled. -- kho, 1/25/96
	;
	mov	ax, MSG_OL_APP_ENSURE_INDICATOR_CORRECT
	call	UserCallApplication
endif	; _RUDY
		
	ret
OpenWinVisClose	endp


;See if this OLWinClass object is a menu, submenu, system menu, popup menu...
;Will have to come back to this when popup menus can migrate from UI to UI.

OpenWinCheckMenuState	proc	near
	class	OLWinClass
	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	done			;skip if not menu or submenu...

	;default: DO NOT SAVE STATE

	ORNF	ds:[di].OLWI_winPosSizeFlags, mask WPSF_NEVER_SAVE_STATE

	;only place on active list if is pinned AND is not popup
	;or window menu. (PINNED menu implies MENUS_PINNABLE, so no need
	;for ifdef here).

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jz	done			;skip if not pinned...

	mov	ax, si			;set *ds:ax = object
	call	ObjGetFlags		;did this object come from a
	test	al, mask OCF_IN_RESOURCE ;resource block?
	jz	done			;skip if not (was created by
					;specific UI - kill it...
	ANDNF	ds:[di].OLWI_winPosSizeFlags, not (mask WPSF_NEVER_SAVE_STATE)

done:
	ret
OpenWinCheckMenuState	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinFreeStaggeredSlot

DESCRIPTION:	This procedure releases a window's staggered slot, IF the
		specific ui or application has indicated that this window's
		position should not persist between appearances.

CALLED BY:	OpenWinCloseWin, OLWinIconSnapToSlot

PASS:		ds:*si	- instance data

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version

------------------------------------------------------------------------------@

	.assert	(offset WPSS_STAGGERED_SLOT) eq 8

OpenWinFreeStaggeredSlot	proc	far
	class	OLWinClass

	;first: does this window even have a staggered slot?

	call	WinOther_DerefVisSpec_DI
	mov	dl, byte ptr ds:[di].OLWI_winPosSizeState+1
					;(HIGH BYTE ONLY)

	ANDNF	dl, mask WPSS_STAGGERED_SLOT shr 8
					;only keep slot # (including ICON flag)

	test	dl, mask SSPR_SLOT	;test for slot # (ignore ICON flag)
	jz	done			;skip if not STAGGERED...

;NOTE: ignores PERSIST flag now. 5/90
;	;if this window PERSISTS, don't release the slot
;
;	test	ds:[di].OLWI_winPosSizeFlags, mask WPSF_PERSIST
;	jnz	done

	ANDNF	byte ptr ds:[di].OLWI_winPosSizeState+1, not (mask SSPR_SLOT)
					;keep SSPR_ICON flag

					;pass dl = slot #
	mov	cx, SVQT_FREE_STAGGER_SLOT
	call	WinOther_VisCallParent_VUP_QUERY

done:
	ret
OpenWinFreeStaggeredSlot	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinPrepForReOpen

DESCRIPTION:	This procedure updates a windowed object's instance data
		in the expectation that the object will be re-opened soon.
		"Soon" means before the ObjectBlock is compacted or
		the application is shut-down. In one of those cases, the
		object will carry the info we need - see OpenWinSaveState.

CALLED BY:	OpenWinCloseWin

PASS:		ds:*si	- object

RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:
	if window DOES NOT PERSIST between appearances
	  and it has MOVED or RESIZED then
		set its position and size INVALID, so will be recalculated
		when the window next opens.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version

------------------------------------------------------------------------------@

OpenWinPrepForReOpen	proc	near
	class	OLWinClass
	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_winPosSizeFlags, mask WPSF_PERSIST
	jnz	done			;skip if does...

	test	ds:[di].OLWI_winPosSizeState, mask WPSS_HAS_MOVED_OR_RESIZED
	jz	done

	ORNF	ds:[di].OLWI_winPosSizeState, mask WPSS_POSITION_INVALID \
			or mask WPSS_SIZE_INVALID

	;
	; Reset the window's geometry here -- it won't happen anywhere else,
	; apparently, and will sometimes die with WIN_POSITION_OR_SIZE_INVALID
	; _AFTER_UPDATE when coming back up (OpenWinOpenWin for a WPT_CENTER
	; window can't resolve the position unless the size gets resolved 
	; first.)  -cbh 1/19/93
	;
	call	UpdateWinPosSize
done:
	ret
OpenWinPrepForReOpen	endp

WinOther	ends
WinOther	segment resource


OpenWinDetaching	proc	far
	;
	; If the window is already detached, then do nothing.  This
	; can happen if a GenDisplay is destroyed while the
	; application is detaching (OLDisplayDestroyAndFreeBlock)
	;

	test	ds:[di].VI_specAttrs, mask SA_ATTACHED 
	jz	exit

EC <	;Make sure we are actually detaching				>
EC <	mov	ax, MSG_GEN_APPLICATION_GET_STATE			>
EC <	call	UserCallApplication	; ax = ApplicationStates	>
EC <	test	ax, mask AS_DETACHING					>
EC <	ERROR_Z	OL_ERROR						>

   	; if this is an icon, we'll definitely save its data
	
	call	WinOther_DerefVisSpec_DI
CUAS <	cmp	ds:[di].OLWI_type, MOWT_WINDOW_ICON			>
OLS <	cmp	ds:[di].OLWI_type, OLWT_WINDOW_ICON			>
    	je	notMaximized		; (carry clear if branch)
	
	;
	; if this object will not be saved then do not save...
	;	if ( (OCF_DIRTY = 0) and (OCF_IN_RESOURCE = 0) )
	;	or ( (OCF_IGNORE_DIRTY = 1) and (OCF_IN_RESOURCE = 0) )

	mov	ax, si
	call	ObjGetFlags		;al = flags
	test	al, mask OCF_DIRTY or mask OCF_IN_RESOURCE
	jz	removeFromWindowList

	xor	al, mask OCF_IGNORE_DIRTY
	test	al, mask OCF_IGNORE_DIRTY or mask OCF_IN_RESOURCE
	jz	removeFromWindowList

	;if this window is MAXIMIZED, restore its REAL position, size,
	;and state data so we can save on window list. When window is
	;re-attached, the MAXIMIZED flag will still be set, causing
	;us to MAXIMIZE the window again.

	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jz	notMaximized		; (carry clear if branch)

	call	OpenWinSwapState	;restore REAL position, size, and
					;state information from instance data
					;does not trash cx or di

	ANDNF	ds:[di].OLWI_specState, not (mask OLWSS_MAXIMIZED)
					;indicate that visible data not longer
					;reflects maximized state - next time
					;window is opened, the fact that
					;GEN_MAXIMIZED it TRUE and this is
					;false will cause OpenWinGenSetMaximized
					;to maximize again.

	stc				;indicate that we did a OpenWinSwapState

notMaximized:
	;now determine if there is any positioning or sizing-type state
	;data that we want to have next time this window is opened.
	;If so, save this data in vardata

	; Let's set this flag so it will request a new slot later.  Probably
	; totally not what Eric had in mind, but...  -cbh 7/ 3/90

	; carry set if we did a OpenWinSwapState, carry clear if we did NOT

	pushf				; save OpenWinSwapState flag

	call	WinOther_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_winPosSizeState, mask WPSS_HAS_RESTARTED
	
	call	OpenWinSaveState	;ensures that window list entries for
					;	OLWinIcon gets removed

	popf				; restore OpenWinSwapState flag
	jnc	done			; no need to restore

	call	OpenWinSwapState	; else swap again to restore so that
					;	children windows can get
					;	parent position and size
					;	correctly

	jmp	short done

removeFromWindowList:
	;NOTE: In some cases (as with the document control) the object may
	;	have already been removed from the window list.

	call	OLWinTakeOffWindowList

done:
	clr	cl
	mov	ch, mask SA_ATTACHED	; no longer attached
	mov	ax, MSG_SPEC_SET_ATTRS
	mov	dl, VUM_NOW		; update mode
	call	ObjCallInstanceNoLock
exit:
	ret
OpenWinDetaching	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinSaveState

DESCRIPTION:	This saves this window's current positioning, sizing,
		and staggering state.

CALLED BY:	OpenWinDetaching

PASS:		*ds:si	- object
			may be OLWinIcon, if so will save info to associated
			GenPrimary and remove OLWinIcon from active list

RETURN:		*ds:si = same

DESTROYED:	ax, bx, cx, dx, di, bp, es

PSEUDO CODE/STRATEGY:
	FIRST see if we have state data to save for window:
	if window has been moved or resized by user or application:
	    Save position, size, and slot # in vardata, because if
	      window is detached, we want it to appear the same when
	      re-attached. *** THIS IS REGARDLESS OF PERSIST FLAG ***

	if window HAS NOT STATE DATA and IN NOT SA_REALIZABLE {
	    remove its OD from the window list

	} else {
	    if window HAS STATE DATA {
		save info to vardata
	    }
	}
	    
	Remember, PERSIST mainly affects what we do to the state data still
	in the object - for the next time it appears.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version

------------------------------------------------------------------------------@

OpenWinSaveStateFlags	record
	OWSSF_NOT_VISIBLE:1
OpenWinSaveStateFlags	end

OpenWinSaveState	proc	near
	class	OLWinClass

	;does this object request that state NEVER be saved? This is used
	;by OLWinIconClass to make sure that its OLWinClass part does not
	;attempt to save state data. (OLMenuedWinClass handles state saving
	;for icon objects)

	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_winPosSizeFlags, mask WPSF_NEVER_SAVE_STATE
	jnz	removeFromList		;skip if so...

	mov	ax, mask OWSSF_NOT_VISIBLE
					;default: is not visible

	test	ds:[di].VI_specAttrs, mask SA_REALIZABLE
	jz	notVisible		;skip if is not realizable...

	;window is visible now. If is a menu and NOT pinned, assume is not
	;currently visible.

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	10$			;skip if not a menu...
	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jz	notVisible		;if menu and not pinned, do not save
					;on window list...

10$:
	ANDNF	ax, not (mask OWSSF_NOT_VISIBLE) ;set flag: window IS visible

notVisible:
	;if this is a GenPrimary or GenDisplay which is currently minimized,
	;we DO want to add this object to the window list, so that it gets
	;a MSG_META_UPDATE_WINDOW later on, and re-builds its icon.

	test	ds:[di].OLWI_specState, mask OLWSS_MINIMIZED
	jz	afterMiniCheck		;skip if not minimized...

	;hack: GenPrimary is minimized, so is not visible on the screen. But
	;we want to get MSG_META_UPDATE_WINDOW when the system restarts, so
	;save this object on the window list. When the MSG_META_UPDATE_WINDOW
	;arrives, this object will realize it is MINIMIZED, and will create
	;a new icon object, which will grab its state data from this
	;GenPrimary's TEMP_GEN_SAVE_ICON_INFO vardata.

	ANDNF	ax, not (mask OWSSF_NOT_VISIBLE) ;set flag: window IS visible
	jmp	short saveState		;skip if currently minimized...

afterMiniCheck:
	;If object has state data, then store this data

	test	ds:[di].OLWI_winPosSizeState, \
		        mask WPSS_HAS_MOVED_OR_RESIZED \
		    or (mask SSPR_SLOT shl offset WPSS_STAGGERED_SLOT)
	jnz	saveState		;skip if so...

	;OK: no state data. If object is visible by specific UI standards
	;then keep its OD on the window list so will be re-attached later.

	;Unless it is a temporarily-created window whose state information
	;would be saved to another object for re-creation at startup.  In
	;these cases, remove the window from window list.

	push	ax
	mov	ax, TEMP_OL_WIN_SAVE_INFO_OBJECT
	call	ObjVarFindData		;carry set if found
	pop	ax
	jc	removeFromList

	test	ax, mask OWSSF_NOT_VISIBLE
	LONG jz	done			;skip if is visible so...

removeFromList:
	;ds:[di] = Vis instance of OLWinClass

	;window is not SA_REALIZABLE - must have been closed, and DOES NOT
	;have unique state data. Remove from window list so will not be
	;displayed if application is restarted.

	; Remove HINT_INITIATED from object, & then remove from
	; active list unless someone else wants to keep it on.
	call	OLWinTakeOffWindowList
	jmp	done

saveState:
	;save object's state data
	;	*ds:si = object (may be OLWinIcon)
	;	ds:di = Vis instance
	;	ax = OWSSF_NOT_VISIBLE flag

	;now save GenSaveWinInfo args on stack

	push	ds:[di].OLWI_winPosSizeState
	push	ds:[di].VI_bounds.R_bottom
	push	ds:[di].VI_bounds.R_right
	push	ds:[di].VI_bounds.R_top
	push	ds:[di].VI_bounds.R_left

	mov	bp, sp			;set ss:bp = structure on stack
	
	;if this window has not moved or resized, set the position and size
	;INVALID, so will be recalculated when is ATTACHED

	test	ds:[di].OLWI_winPosSizeState, mask WPSS_HAS_MOVED_OR_RESIZED
	jnz	hasMovedOrResized

	ORNF	ss:[bp].GSWI_winPosSizeState, mask WPSS_POSITION_INVALID \
			or mask WPSS_SIZE_INVALID
	jmp	saveToList

hasMovedOrResized:

	;
	; If the window is not resizable, any size information is probably
	; useless -- it can either be built back out based on the children
	; or based on the size hints in the window, but we shouldn't keep
	; the ratio of the screen around.  All that does is cause windows
	; to be abnormally large when switching from a large video screen
	; to a small one.  We'll mark the size invalid, and nuke the pixel
	; values stored within.  -cbh 2/ 1/93  (Commented out 2/10/93 cbh.
	; I'm pretty sure this isn't a good thing.)
	;
;	test	ds:[di].OLWI_attrs, mask OWA_RESIZABLE
;	jnz	convertPixels
;	ORNF	ss:[bp].GSWI_winPosSizeState, mask WPSS_SIZE_INVALID
;
;convertPixels:

	;convert the pixel boundaries of this windowed object into
	;a ratio of the parent window
	;	ss:bp = GenSaveWindowInfo structure on stack

	call	ConvertPixelBoundsToSpecWinSizePairs

saveToList:
	;now save window info and ensure that it is on window list

	;	*ds:si = OLWinClass
	;	ss:bp = GenSaveWindowInfo
	;	ax = OWSSF_NOT_VISIBLE flag
	;
	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_WIN_ICON
	LONG	jnz	saveIconInfo

	push	ax			; save OWSSF_NOT_VISIBLE
	mov	ax, TEMP_OL_WIN_SAVE_INFO_OBJECT
	call	ObjVarFindData
	pop	ax			; ax = OWSSF_NOT_VISIBLE
	jc	saveCustomInfo

	; save info for non-OLWinIcon and non-custom object:
	;	set HINT_INITIATED if not OWSSF_NOT_VISIBLE
	;	save GenSaveWindowInfo
	;	add to active list
	;	ax = OWSSF_NOT_VISIBLE flag

	test	ax, mask OWSSF_NOT_VISIBLE
					; hint to indicate REALIZABLE
	mov	ax, HINT_INITIATED or mask VDF_SAVE_TO_STATE
	jz	visible			; is visible, add HINT_INITIATED
	call	ObjVarDeleteData	; not visible, delete HINT_INITIATED
	jmp	short afterVarData

visible:
	clr	cx
	call	ObjVarAddData
afterVarData:

	mov	ax, TEMP_GEN_SAVE_WINDOW_INFO or mask VDF_SAVE_TO_STATE
	mov	cx, size GenSaveWindowInfo
	call	ObjVarAddData		; ds:bx = GenSaveWindowInfo
	mov	ax, ss:[bp].GSWI_winPosition.SWSP_x
	mov	ds:[bx].GSWI_winPosition.SWSP_x, ax
	mov	ax, ss:[bp].GSWI_winPosition.SWSP_y
	mov	ds:[bx].GSWI_winPosition.SWSP_y, ax
	mov	ax, ss:[bp].GSWI_winSize.SWSP_x
	mov	ds:[bx].GSWI_winSize.SWSP_x, ax
	mov	ax, ss:[bp].GSWI_winSize.SWSP_y
	mov	ds:[bx].GSWI_winSize.SWSP_y, ax
	mov	ax, ss:[bp].GSWI_winPosSizeState
	mov	ds:[bx].GSWI_winPosSizeState, ax

	;
	; New code to set size = RSA_CHOOSE_OWN_SIZE if it's invalid.  We 
	; really don't want them to be used at all (the window will expand to 
	; fit these bounds, even though they're invalid).  -cbh   (Nah,
	; nuke it.  It causes windows with position or size hints to not use
	; those hints when coming up the second time.  -cbh 3/29/93)

;	test	ds:[bx].GSWI_winPosSizeState, mask WPSS_SIZE_INVALID
;	jz	posSizeValid

	; Nuke the size params, change to RSA_CHOOSE_OWN_SIZE. -cbh 2/ 2/93

;	and	ds:[bx].GSWI_winPosSizeState, not \
;				(mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT \
;				or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD)

;	mov	ds:[bx].GSWI_winSize.SWSP_x, mask RSA_CHOOSE_OWN_SIZE
;	mov	ds:[bx].GSWI_winSize.SWSP_y, mask RSA_CHOOSE_OWN_SIZE

;posSizeValid:

	; add to window list

	call	OpenWinEnsureOnWindowList
	jmp	finishSave

saveCustomInfo:

	;save info for TEMP_OL_WIN_SAVE_INFO_OBJECT
	;	save GenSaveWindowInfo to associated object
	;	remove this OLWin from active list
	;		ss:bp = GenSaveWindowInfo
	;		*ds:si = OLWin instance
	;		ds:bx = ptr to optr of associated object
	;		ax = OWSSF_NOT_VISIBLE flag

	; add specified vardata if not visible, if any
	push	si				; save OLWin chunk handle
	mov	cx, ds:[bx].SIOS_tag
	mov	dx, ds:[bx].SIOS_hiddenTag
	mov	si, ds:[bx].SIOS_object.chunk	; ^lbx:si = associated object
	mov	bx, ds:[bx].SIOS_object.handle
	test	ax, mask OWSSF_NOT_VISIBLE
	jz	customIsVisible
	tst	dx
	jz	customIsVisible			; no vardata for not-visible
	push	bp, cx				; save GSWI_ offset, tag
	sub	sp, size AddVarDataParams
	mov	bp, sp
	mov	ss:[bp].AVDP_data.segment, 0	; no extra data
	mov	ss:[bp].AVDP_data.offset, 0
	mov	ss:[bp].AVDP_dataSize, 0	; no extra data
	mov	ss:[bp].AVDP_dataType, dx
	mov	dx, size AddVarDataParams
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size AddVarDataParams
	pop	bp, cx				; bp = GWSI_ offset, cx = tag
customIsVisible:
	; set up params for common code
	movdw	axdi, bxsi			; ^lax:di = associated object
	pop	si				; *ds:si = OLWin
	jmp	short saveInfoCommon

saveIconInfo:

	;save info for OLWinIcon
	;	save GenSaveWindowInfo to associated GenPrimary
	;	remove OLWinIcon from active list
	;		ss:bp = GenSaveWindowInfo
	;		*ds:si = OLWinIcon instance
	;		ds:di = OLWinIcon instance

.warn -private
EC <	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_WIN_ICON		>
EC <	ERROR_Z	OL_ERROR						>
	mov	ax, ds:[di].OLWII_window.handle	; ^lax:di = GenPrimary
	mov	di, ds:[di].OLWII_window.chunk
EC <	tst	di							>
EC <	ERROR_Z	OL_ERROR						>
.warn @private
	mov	cx, TEMP_GEN_SAVE_ICON_INFO or mask VDF_SAVE_TO_STATE

saveInfoCommon:

	;save info for OLWinIcon or TEMP_OL_WIN_SAVE_INFO_OBJECT
	;	save GenSaveWindowInfo to associated object
	;	remove this OLWin from active list
	;		ss:bp = GenSaveWindowInfo
	;		*ds:si = OLWin instance
	;		^lax:di = object to save info to
	;		cx = VarData to save info with

	mov	bx, bp				; ss:bx = GenSaveWindowInfo
	mov	dx, size AddVarDataParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].AVDP_data.segment, ss
	mov	ss:[bp].AVDP_data.offset, bx
	mov	ss:[bp].AVDP_dataSize, size GenSaveWindowInfo
	mov	ss:[bp].AVDP_dataType, cx
	push	si
	mov	bx, ax				; ^lbx:si = object to save to
	mov	si, di
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	pop	si
	add	sp, size AddVarDataParams

	call	OLWinTakeOffWindowList		; remove OLWinIcon from list

finishSave:
	add	sp, size GenSaveWindowInfo
done:
	ret
OpenWinSaveState	endp


WinOther	ends
WinOther	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinUpdateModalStatus

DESCRIPTION:	If current object is a modal window, notify app, & system,
		if necessary, that something about the window has changed
		(open/close/priority change)

CALLED BY:	INTERNAL
		OpenWinBringToTop

PASS:		*ds:si	- OLWinClass object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@

OpenWinUpdateModalStatus	proc	far
	class	OLPopupWinClass

	; First, check to see if really of OLPopupWinClass
	;
	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	jz	done

EC <	push	es, di							>
EC <	mov	di, segment OLPopupWinClass				>
EC <	mov	es, di 							>
EC <	mov	di, offset OLPopupWinClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR					>
EC <	pop	es, di							>

	test	ds:[di].OLPWI_flags, mask OLPWF_SYS_MODAL
	jnz	sysModal
	test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL
	jnz	appModal
done:
	ret

sysModal:
	; Let system know there's been a change in the window hierarchy
	; possibly affecting system modality.
	;
	mov	ax, MSG_GEN_SYSTEM_NOTIFY_SYS_MODAL_WIN_CHANGE
	call	UserCallSystem
appModal:
	mov	ax, MSG_GEN_APPLICATION_NOTIFY_MODAL_WIN_CHANGE
	GOTO	GenCallApplication
OpenWinUpdateModalStatus	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinLowerToBottom -- MSG_GEN_LOWER_TO_BOTTOM

DESCRIPTION:	This function lowers the window to the bottom of its window
		priority group, & and if using a point & click kbd focus
		model, & then releases the focus & target, if the window has it,
		and requests the app to pick new focus/target windows.

PASS:		*ds:si 	- instance data

RETURN:		nothing

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/90		Initial version

------------------------------------------------------------------------------@

OpenWinLowerToBottom	method dynamic	OLWinClass, MSG_GEN_LOWER_TO_BOTTOM
	;if this window is not opened then abort: the user or application
	;caused the window to close before this method arrived via the queue.

	call	VisQueryWindow
	tst	di
	jz	setGenState		; Skip if window not opened...

	push	di			; save window handle

	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_RELEASE_TARGET_EXCL
	call	ObjCallInstanceNoLock

	pop	di			;Restore window handle

	;Lower window to top of window group

	mov	ax, mask WPF_PLACE_BEHIND
	clr	dx			; Leave LayerID unchanged
	call	WinChangePriority

	; If this is a modal window, notify app object, & sys object if
	; SYS_MODAL, that one of these types of windows has either opened,
	; closed, or changed in priority.
	;
	call	OpenWinUpdateModalStatus

	; Ensure Focus & Target within the application
	;
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	GenCallApplication

setGenState:
					; Lower the window list entry to
					; the bottom, to reflect new/desired
					; position in window hierarchy.
					; (If no window list entry, window
					; isn't up & nothing will be done)
	mov	ax, MSG_GEN_APPLICATION_LOWER_WINDOW_TO_BOTTOM
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	GenCallApplication
if _RUDY
	;
	; When a window is lowered to bottom, call a message to make
	; sure the Indicator floats or sinks correctly.
	; -- kho, 2/6/96
	;
	mov	ax, MSG_OL_APP_ENSURE_INDICATOR_CORRECT
	call	UserCallApplication
endif
	ret
OpenWinLowerToBottom	endp


WinOther	ends
WinOther	segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	AvoidMenuOverlap

SYNOPSIS:	Moves menu to try to avoid a menu overlap, in one direction.

CALLED BY:	OpenWinCheckMenuWinVisibilityConstraints

PASS:		*ds:si -- menu button
		*ds:di -- menu
if _JEDIMOTIF
		bh     -- non-zero if opening down/right instead of up/left
		bl     -- AMO_VERTICAL if checking vertical values
else
		bx     -- AMO_VERTICAL if checking vertical values
endif
		cx     -- non-zero if opening a menu or submenu to the right,
				and should try opening below rather than left
				if right doesn't work.

RETURN:		carry set if we had to move a horizontal menu below the button,
			or a vertical menu to the right of a button, in which
			case we probably should bring it onscreen again and
			make sure it's still not overlapping.

DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:

	Assume checking horizontally -- if bx set, will access Y instance data
	overlap = menuLeft - screenMenuButtonRight - 1
	if overlap negative
	   if menuWidth > screenMenuButtonLeft  (Can't fit to left of button)
		menuTop = buttonBottom (Move underneath button instead)
	   else
	        (Move menu completely left of menu button)
	   	newMenuLeft = menuLeft - (menuWidth + menuButtonWidth + overlap)
	   endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/20/93       	Initial version

------------------------------------------------------------------------------@
AMO_VERTICAL	=	offset R_top - offset R_left

AvoidMenuOverlap	proc	far
	uses	si, di, cx
	.enter

	push	di			; save menu handle

	tst	cx			; submenu?
	pushf				; save whether a submenu
	mov	bp, ds:[di]		; ds:bp -- menu vis instance
	add	bp, ds:[bp].Vis_offset
	
	call	WinOther_DerefVisSpec_DI; ds:di -- menu button vis instance
	mov	dx, bx			; save vertical flag in dx

	;
	; Get left and top of menu button, in screen coordinates.
	;
	mov	ax, ds:[di].VI_bounds.R_left
	mov	bx, ds:[di].VI_bounds.R_top
	push	di

	call	VisQueryWindow		; di = window handle
	tst	di			; no window, get out.
	LONG	jz	popDiFlagsSiExit
EC <	push	bx							>
EC <	mov	bx, di							>
EC <	call	ECCheckWindowHandle	; ensure good window		>
EC <	pop	bx							>
	call	WinTransform		; set (ax, bx) = screen coordinates

	push	ax, si
	mov	si, WIT_PARENT_WIN
	call	WinGetInfo
	mov_tr	di, ax
	pop	ax, si
	call	WinUntransform	; and make parent-relative

	pop	di			; ds:di = menu button
	xchgdw	cxdx, axbx		; menu button origin in cx, dx
					; vertical flag in bx
if _JEDIMOTIF
	tst	bl			; vertical?
else
	tst	bx			; vertical?
endif
	jz	10$
	xchg	cx, dx			; switch cx and dx if vertical.  cx is
					;  left if doing X, top if doing Y.
10$:
	;
	; Assume checking horizontally -- if bx set, will access Y instance.
	; If checking vertical overlaps, make appropriate translations of
	; comments in quotes from "left" to top, "top" to left, "width" to
	; height, etc.  -cbh
	;
	; For those who don't know what the hell is happening (me), he's
	; relying on the fact that VI_bounds are left, top, right, bottom
	; in that order.  If we're horizontal (bx=0), grabbing R_left and
	; R_right will get the left & right.  If we're vertical, we shift
	; our instance pointer by 2, so grabbing the left & right actually
	; grabs the top & bottom.  -stevey 8/25/94
	;
CheckHack	<size Rectangle eq 8	>
CheckHack	<offset R_left eq 0	>
CheckHack	<offset R_top eq 2	>
CheckHack	<offset R_right eq 4	>
CheckHack	<offset R_bottom eq 6	>

if _JEDIMOTIF
	push	bx
	mov	bh, 0			  ; bx - AMO_VERTICAL
	add	bp, bx			  ; adjust to our orientation for
	add	di, bx			  ;   grabbing bounds instance data
	pop	bx
else
	add	bp, bx			  ; adjust to our orientation for
	add	di, bx			  ;   grabbing bounds instance data
endif
	;
	; Calculate overlap, if any:
	;	overlap = menuLeft - screenMenuButtonRight - 1
	;
if _JEDIMOTIF
	;
	; JEDI stuff, by default, goes in the opposite direction
	;
	tst	bh					;down/right
	jnz	downRight
	mov	ax, cx					;menu button left
	sub	ax, ds:[bp].VI_bounds.R_left		;menu left
	inc	ax					;overlap (2 pixels)
	inc	ax
	sub	ax, ds:[bp].VI_bounds.R_right		;sub menu width
	add	ax, ds:[bp].VI_bounds.R_left
	LONG jns	popFlagsSiExit
	dec	ax					;undo overlap
	dec	ax
	jmp	overlapCommon

downRight:
endif
	mov	ax, ds:[bp].VI_bounds.R_left		;menu left
	sub	ax, cx					;menu button left
CUA <	inc	ax			;deal with CUA/PM one-pixel overlap >
PMAN <	inc	ax			;deal with CUA/PM one-pixel overlap >
MO <	inc	ax			;allow one-pixel overlap now 2/3/93 >
JEDI <	inc	ax			;2 pixels			>

	sub	ax, ds:[di].VI_bounds.R_right		;subtract button width
	add	ax, ds:[di].VI_bounds.R_left
	LONG jns	popFlagsSiExit	;no overlap, done (pop si and flags)

MO <	dec	ax			;undo one-pixel overlap now.	   >
JEDI <	dec	ax			;2 pixels			>

overlapCommon::
	;
	; If the menu can't fit to the "left" of the menu button, we'll
	; position it "below" the button instead.  
	;
	popf
	jz	checkCantFitToLeft	;not submenu, try to put to "left" 
	tst	bx			;submenu, see if doing X overlaps
	jnz	checkCantFitToLeft	;checking Y, branch
	;
	; Submenu, overlapping, and checking the X direction, we'll also go
	; straight to positioning "below" the button.  
	;
MO <	add	ax, 6			;Motif submenus get some latitude:   >
MO <	LONG jns	popSiExit	;  Not overlapping much, exit	     >
	jmp	short moveMenuBelow	
checkCantFitToLeft:
if _JEDIMOTIF
	;
	; try "right", by default
	;
	tst	bh
	jnz	tryLeft
	push	si
	mov	si, ds:[bp].VI_bounds.R_right	; menu "width"
	sub	si, ds:[bp].VI_bounds.R_left
	add	si, ds:[di].VI_bounds.R_right	; menu button "width"
	sub	si, ds:[di].VI_bounds.R_left
	add	si, cx				; menu button "left"
	cmp	si, 241				; yes, yes...
	pop	si
	jle	moveMenuToRightSide
	jmp	short moveMenuBelow

tryLeft:
endif
	push	si				; menu button handle
	mov	si, ds:[bp].VI_bounds.R_right	; menu "width"
	sub	si, ds:[bp].VI_bounds.R_left
	cmp	si, cx				; "wider" than button's
						;   "left" edge?
	pop	si				; menu button handle
	jle	moveMenuToLeftSide		; no, branch

moveMenuBelow::
	;
	; Menu can't fit on "left" or "right" side: move
	; "below" the button.
	;
	mov	cx, ds:[bp].VI_bounds.R_left	; current menu "left" edge
if _JEDIMOTIF
	;
	; move "above" for JEDI, by default
	;
	tst	bh				; opening down/right?
	jnz	moveBelow			; yes, move below
	tst	bl
	jz	115$				; doing horiz, go do vert
	sub	bp, AMO_VERTICAL		; vert, do horiz
	jmp	short 117$
115$:
	add	bp, AMO_VERTICAL
117$:
	sub	dx, ds:[bp].VI_bounds.R_right
	add	dx, ds:[bp].VI_bounds.R_left
	jmp	short belowCommon

moveBelow:
endif
	tst	bx
	jz	15$				; doing horiz, go do vert
	sub	di, AMO_VERTICAL		; vert, do horiz
	jmp	short 17$
15$:
	add	di, AMO_VERTICAL
17$:
	add	dx, ds:[di].VI_bounds.R_right
	sub	dx, ds:[di].VI_bounds.R_left	; get bottom of button

belowCommon::
if _JEDIMOTIF
	tst	bl	
else
	tst	bx	
endif
	jz	20$				; was doing vert, branch
	xchg	cx, dx
20$:	
	pop	si
EC <	call	ECCheckLMemObject					>
	call	VisSetPosition			; position the menu
	stc					; we want to know we did	
						;  this.
	jmp	short exit

if _JEDIMOTIF
moveMenuToRightSide:
	add	cx, ds:[di].VI_bounds.R_right	; add menu button "width"
	sub	cx, ds:[di].VI_bounds.R_left	;	to get to button right
	sub	cx, ds:[bp].VI_bounds.R_left	; get relative move
	dec	cx				; 1-pixel overlap to indicate
						;	non-optimal position
	jmp	short moveRelative
endif

moveMenuToLeftSide:
	;
	; Position menu to "left" side of menu button.	
	;

	; first add the "width" of the menu to the overlap

	add	ax, ds:[bp].VI_bounds.R_right
	sub	ax, ds:[bp].VI_bounds.R_left

	;
	; now add the "width" of the menu button (quicker than 
	; translating the "top" coordinate to screen coordinates)
	;
	add	ax, ds:[di].VI_bounds.R_right
	sub	ax, ds:[di].VI_bounds.R_left
if _JEDIMOTIF
	dec	ax			;only 1-pixel to show non-optimal pos.
else
CUA <	sub	ax, 2			;encourage one-pixel overlap        >
PMAN <	dec	ax						    	    >
endif

	;
	;  Now move the menu.
	;
	neg	ax			;make total negative
	mov	cx, ax
moveRelative::
	clr	dx			;clear in the other direction
if _JEDIMOTIF
	tst	bl
else
	tst	bx
endif
	jz	30$
	xchg	cx, dx			;vertical, apply to Y position
30$:
if _JEDIMOTIF
	push	bx
	mov	bh, 0			;bx - AMO_VERTICAL
	sub	bp, bx			;remove our vertical bias
	pop	bx
else
	sub	bp, bx			;remove our vertical bias
endif
	add	cx, ds:[bp].VI_bounds.R_left
	add	dx, ds:[bp].VI_bounds.R_top  

	pop	si			;set *ds:si = menu window
EC <	call	ECCheckLMemObject					>
	call	VisSetPosition		;move window to (cx, dx)
	clc				;everything normal
	jmp	short exit

popDiFlagsSiExit:
	pop	di			;dump di

popFlagsSiExit:
	popf				;dump flags

popSiExit:
	pop	si			;restore...
	clc				;nothing weird happened
exit:
	.leave
	ret
AvoidMenuOverlap	endp


WinOther	ends
WinOther	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinReleaseMenuFocus -- 
		MSG_VIS_VUP_RELEASE_MENU_FOCUS for OLWinClass

DESCRIPTION:	This forces us to exit menu navigation, if in progress.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_VUP_RELEASE_MENU_FOCUS

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/90		Initial version

------------------------------------------------------------------------------@

OLWinReleaseMenuFocus method dynamic OLWinClass,
				   MSG_VIS_VUP_RELEASE_MENU_FOCUS
	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED
	jz	exit				;don't have focus, exit

	;we are exiting the menu bar. We know that the focused object is
	;a menu button or menu window: force it to release the focus, so that
	;our window code will restore the focus to the previous owner, before
	;all of this menu navigation started. 4/23/90 EDS.

	push	si
	call	WinOther_DerefVisSpec_DI
	mov	si, ds:[di].OLWI_focusExcl.FTVMC_OD.chunk
	mov	bx, ds:[di].OLWI_focusExcl.FTVMC_OD.handle
	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	;
	; End the pre-passive grab set up so we could release the menu focus on
	; ANY mouse click.  -cbh 10/22/90
	;
	call	VisRemoveButtonPrePassive		
	
exit:
	ret
OLWinReleaseMenuFocus	endm



WinOther	ends
