COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec (common code for several specific ui's)
FILE:		cspecInteraction.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildInteraction	Convert a generic interaction group to the OL
				equivalent
   INT	OLMapGroup		Return class for the Open Look equivalent of a
				GenInteraction, GenSummons or GenProperties
   INT	OLMapGroupUseParent	Set object's gen parent as the vis parent
   INT	AllocMapChunk		Allocate a OLMapGroupData storage

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Eric	7/89		Motif extensions, more documentation

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic interaction group.

	$Id: cspecInteraction.asm,v 1.2 98/03/11 05:58:22 joon Exp $

------------------------------------------------------------------------------@

Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildInteraction

DESCRIPTION:	Return the specific UI class for a GenInteraction

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data
	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx, dx, bp - ?

RETURN:
	cx:dx - class (cx = 0 for no conversion)

DESTROYED:
	ax, bx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

OLBuildInteraction	proc	far

	;Use the standard mapping routine, with OLDialogWin being the class
	;to use for independently displayable stuff.

	mov	dx, offset OLDialogWinClass
	FALL_THRU	OLMapGroup

OLBuildInteraction	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMapGroup

DESCRIPTION:	Return class for the Open Look equivalent of a
		GenInteraction

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data for object to convert
	dx - offset of class to use if the object is to be converted to some
	     type of independent window

RETURN:
	cx:dx - class (cx = 0 for no conversion)
	variable data storage allocated for object with an OLMapGroupData
	structure stored in it

DESTROYED:
	ax, bx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	; Map a GenInteraction to the correct OpenLook class.  Passed is the
	; object and the class to use if the object is to be converted to some
	; type of independent window.

	; Allocate a temporary chunk to save our results for SPEC_BUILD

	ch = LMemAllocTempChunk( size(OLMapGroupData) );

	; Set up OLBuildFlags for generic->specific building of the
	; GenInteraction

	buildFlags = 0;

	; If GIV_POPUP, set OLBF_MENUABLE

	if (visibility = GIV_POPUP) {
	    buildFlags |= OLBF_MENUABLE;
	}

	; Scan the hints to get various information:
	;	HINT_SEEK_MENU_BAR ->	Set OLBF_SEEK_MENU_BAR
	;	HINT_AVOID_MENU_BAR ->	Set OLBF_AVOID_MENU_BAR
	;	HINT_FILE_MENU	->	Set OLBT_FILE << OLBF_TARGET
	;	HINT_IS_FILE_MENU->	Set OLBF_IS_FILE_MENU << OLBF_TARGET
	;	HINT_IS_EXPRESS_MENU->	Set OLBT_IS_EXPRESS_MENU << OLBF_TARGET
	;					OLBR_TOP_MENU << OLBF_REPLY
	;	HINT_IS_HELP_MENU->	Set OLBT_IS_HELP_MENU << OLBF_TARGET
	;	HINT_PRINT_MENU	->	Set OLBT_PRINT << OLBF_TARGET
	;	HINT_WINDOW_MENU->	Set OLBT_WINDOW << OLBF_TARGET
	;	HINT_SYS_MENU	->	Set OLBT_SYS_MENU << OLBF_TARGET
	;					OLBF_TOP_MENU << OLBF_REPLY
	;	HINT_SEEK_REPLY_BAR->	Set OLBF_SEEK_REPLY_BAR

	ObjVarScanData(OLMapInitHints);

	;MOTIF/CUA: if OLBT_SYS_MENU, then skip this query. VisParent
	;field will be set to generic parent, which is GenPrimary.

	; Do a generic upward query to get parent info.  In return, we get
	; an optr to the visParent (or 0 if this thing was not placed)
	; and we get OLBuildFlags with information about where in the
	; menu tree we can be.

	ch.flags, ch.visParent = MSG_GEN_GUP_QUERY(SGQT_BUILD_INFO);

	; If no visParent returned then use generic parent

	if (visParent == 0) {
	    ch.visParent = object->parent;
	}

	; If HINT_MAKE_REPLY_BAR, use OLReplyBarClass

	if (HINT_MAKE_REPLY_BAR) {
	    return(OLReplyBarClass);
	}

	; If the application wants a dialog, then then make it the class
	; passed.

	if (GIV_DIALOG) {
	    return(classForWin);
	}

	; If the application has specified a control group and it is under a
	; menu, become a dialog.

	If (GIV_CONTROL_GROUP and (OLBR_TOP_MENU or OLBR_SUB_MENU)) {
	    return(classForWin);
	}

	;If we can turn into a menu or sub-menu then become a MenuWin

	if (OLBR_TOP_MENU and GIV_POPUP) {
	    return(OLMenuWinClass);
	}
	if (OLBR_SUB_MENU and GIV_SUB_GROUP) {
	    return(OLMenuItemGroupClass);
	}
	if (OLBR_SUB_MENU and GIV_POPUP) {
	    if (_SUB_MENU) {
	        return(OLMenuWinClass);
	    } else {
	        return(OLMenuItemGroupClass);
	    }
	}
	return(OLCtrlClass);

	----------------------

	Handling of MSG_GEN_GUP_QUERY(SGQT_BUILD_INFO):

		Pass:	cx - query type (SGQT_BUILD_INFO)
			bp - OLBuildFlags
		Return:	cx:dx - vis parent for group
			bp - OLBuildFlags

X denotes documetation verified (sort of:) - brianc 12/18

X	OLCtrlClass:
		;Is below a control area: if is a menu or a GenTrigger which
		;want to be moved into a GenFile-type object, then send query
		;to gen parent to see if such a beast exists. Return if
		;somebody above wants to grab this object. Otherwise, is a
		;plain GenTrigger which should stay in this OLCtrl object.

	    if (not a win group) {
	        if (OLBF_MENUABLE) or (HINT_{WINDOW,FILE,IS_FILE_MENU,PRINT}) {
		    MSG_GEN_GUP_QUERY(gen parent, SGQT_BUILD_INFO);
		    if (visParent != NULL) {
			return(stuff from parent)
		    }
		}
	    }
	    ;Nothing above grabbed object, or object is plain GenTrigger.
	    ;Place inside this OLCtrl object.
	    TOP_MENU = 0;
	    SUB_MENU = 0;
	    visParent = this object;

X	OLGadgetComp:
		;Is below a control area: if is a menu or a GenTrigger which
		;want to be moved into a GenFile-type object, then send query
		;to gen parent to see if such a beast exists. Return if
		;somebody above wants to grab this object. Otherwise, is a
		;plain GenTrigger which should stay in this OLCtrl object.
	    if (MENUABLE) or (HINT_{WINDOW,FILE,IS_FILE_MENU,PRINT}) {
		MSG_GEN_GUP_QUERY(gen parent, SGQT_BUILD_INFO);
		if (visParent != NULL) {
		    return(stuff from parent)
		}
	    }
	    ;Nothing above grabbed object, or object is plain GenTrigger.
	    ;Place inside this OLCtrl object.
	    TOP_MENU = 0;
	    SUB_MENU = 0;
	    visParent = this object;

X	OLMenuWinClass:
		;Is below a menu: indicate should be a sub-menu.
	    TOP_MENU = 0;
	    SUB_MENU = 1;
	    visParent = this object;

(too horrible to verify)
	OLMenuedWinClass:
		;Is below a window with a menu bar or trigger bar. Note that
		;if this window has GenFile or GenEdit type objects, then
		;the menu bar will already have been created.
		;(The important thing is we don't want GenTriggers with
		;HINT_FILE, etc, forcing the creation of a menu bar just to
		;find that there is no GenFile-type object to grab the Trigger.
		;OpenLook: all GenTriggers go into menu bar.

	    if (MENUABLE or HINT_SEEK_MENU_BAR or
					(OL and not HINT_AVOID_MENU_BAR) )
		and (menu not created yet) {
			create menu
	    }

	    if (menu bar has been created) and (not HINT_AVOID_MENU_BAR) {
	        MSG_GEN_GUP_QUERY(menu bar, SGQT_BUILD_INFO);
		if (menu bar returned TOP_MENU or SUB_MENU true) {
	    	    return(stuff from menu bar)
		}

	    if (CUA/Motif or HINT_AVOID_MENU_BAR) {
		;We know is GenTrigger
		if (trigger bar not created yet) {
		    create trigger bar
		}
	        MSG_GEN_GUP_QUERY(trigger bar, SGQT_BUILD_INFO);
		if (trigger bar returned TOP_TRIGGER) {
		    return(stuff from trigger bar)
		}
	    }
	    ;return NULL so that GenParent will be used as visParent.
	    TOP_MENU = 0;
	    SUB_MENU = 0;
	    visParent = NULL;

X	OLMenuBarClass (via MSG_BAR_BUILD_INFO):
		;is below a window which has a menu bar: if is seeking
		;specific menu, send on to that menu. Otherwise, if is
		;menu window or OpenLook trigger, place in this menu bar.
		;Otherwise return NO.
	    if (OLBF_MENU_IN_DISPLAY) {
		ensure trigger bar;
		return (trigger bar, OLBR_TOP_MENU);
	    }
	    if (OLBT_BUTTON_FOR_DISPLAY) {
		ensure MDIWindowMenu;
		return (MDIWindowList, OLBR_SUB_MENU);
	    }
	    if (OLBT_WINDOW) {
		ensure MDIWindowMenu;
		return (MDIWindowMenu, OLBR_SUB_MENU);
	    }
	    if (OLBT_FILE) {
		ensure file menu;
		ensure file menu file group;
		return (file menu file group, OLBR_SUB_MENU);
	    }
	    if (OLBT_PRINT) {
		ensure file menu;
		ensure file menu print group;
		return (file menu print group, OLBR_SUB_MENU);
	    }
	    if (OLBF_MENUABLE) {
		return (this object, OLBR_TOP_MENU);
	    } else {
		return UNANSWERED -- let caller (GenPrimary) handle;
	    }

X	OLTriggerBarClass (via MSG_BAR_BUILD_INFO):
		;is below a window which has a trigger bar, and must be
		;a GenTrigger: place it here.
	    TOP_MENU = 0;
	    SUB_MENU = 0;
	    TOP_TRIGGER = 1;
	    visParent = this object;

X	OLMenuItemGroupClass:
		;is below a sub-menu; Tell group it can become a sub-menu,
		;and that it is inside a sub-menu.
	    TOP_MENU = 0;
	    SUB_MENU = 1;
	    visParent = this object;

X	OLDisplayWinClass:
		;is below a display window: then this group could become a
		;menu on this object or could be combined into a primary
		;above.  (GenDisplayGroup must exist above GenDisplay)

	    if (HINT_WINDOW) {
		   ;seeking Window menu, let parent (GenDisplayGroup) handle
		   ;it
		GenCallParent;
		if ((no answer) or (returns visParent = none)) {
		    CallSuper;
		} else {
		    return info;
		}
	    } else {
		if (MENUABLE and OLDWF_NEVER_ADOPT_MENUS) {
		    ;keep menus in GenDisplay
		    CallSuper;
		} else {
		    ;push menus to GenDisplayGroup when GenDisplay gains
		    ;target
		    if (!OLDWF_ALWAYS_ADOPT_MENUS) {
		        Set OLBF_ALWAYS_ADOPT;
		    }
		    GenCallParent;
		    if ((no answer) or (returns visParent = none)) {
		        CallSuper;
		    } else {
			;flag mondo adoption occuring
			Set OLBF_ABOVE_DISP_CTRL;
		    }
		}
	    }

X	OLDisplayGroupClass:
	    if (BUTTON_FOR_DISPLAY) {
		/* This is a GenItem on its way to find the GenList
		 * in the MDIWindowMenu, below the GenPrimary. Send the query
		 * to our parent (GenPrimary) */
		MSG_GEN_GUP_QUERY(genParent, SGQT_BUILD_INFO);
		if visParent != null then {
		    keep handle of GenItemGroup for DC, so can notify it as
			the GenDisplays fight over the TARGET_EXCL.
		    set the ODs of the GenTriggers and the GenItemGroup in the
			MDIWindowMenu, so all events come to this DC object.
		    return handle of GenItemGroup as visParent for new GenItem.
		}
	    } else {
		    ;let parent GenPrimary handle (we only accept
		    ;BUTTON_FOR_DISPLAY)
		GenCallParent;
	    }

X	OLContentClass:
	    TOP_MENU = 0;
	    SUB_MENU = 0;
	    visParent = this object;

X	OLApplicationClass:
	    TOP_MENU = 1;
	    SUB_MENU = 0;
	    visParent = none;

X	OLFieldClass:
	    TOP_MENU = 1;
	    SUB_MENU = 0;
	    visParent = this object;


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

OLMapGroup	proc	far
	class	OLCtrlClass

	;ch = LMemAllocTempChunk( size(OLMapGroupData) );

	push	dx				;save class passed
	call	AllocMapChunk

	;buildFlags = 0;

	clr	dx				;init OLBuildFlags to FALSE

	;if (visibility = GIV_POPUP) {
	;    buildFlags |= OLBF_MENUABLE;
	;}

	mov	di, ds:[si]			;ds:di = instance
	add	di, ds:[di].Gen_offset		;ds:di = GenInstance
	cmp	ds:[di].GII_visibility, GIV_POPUP
	jne	OMG_notPopup
	ornf	dx, mask OLBF_MENUABLE		;GIV_POPUP --> OLBF_MENUABLE
OMG_notPopup:

	;ObjVarScanData(OLMapInitHints);

	call	ScanMapGroupHintHandlers	;returns dx = OLBuildFlags

	;if HINT_SYS_MENU or HINT_IS_EXPRESS_MENU, we must skip this query...
	;(See how the hint handler sets up the query results for us.)

	clr	cx				;default: no visible parent
	mov	ax, dx				;and return ax as OLBuildFlags
	mov	bx, dx
	ANDNF	bx, mask OLBF_TARGET

	test	dx, mask OLBF_AVOID_MENU_BAR
	jnz	OMG_saveQueryResults		;avoiding menu bar, skip to
						;  avoid looking for menu bar

	cmp	bx, OLBT_SYS_MENU shl offset OLBF_TARGET ;is this a system menu?
	jz	OMG_saveQueryResults		;skip if so...

	cmp	bx, OLBT_IS_EXPRESS_MENU shl offset OLBF_TARGET
	jz	OMG_saveQueryResults		;skip if so...

	cmp	bx, (OLBT_IS_POPUP_LIST) shl offset OLBF_TARGET
	je	OMG_saveQueryResults		;skip if popup menu...

	;
	; If a GIA_NOT_USER_INITIATABLE GIV_DIALOG, don't query as vis parent
	; is not needed as there is no button (vis parent for win-group is
	; determined seperately).  This also avoids building OLTriggerBar
	; for those GIA_NOT_USER_INITIATABLE GIV_DIALOGs under a GenPrimary.
	; - brianc 5/7/92
	; GIV_POPUP interactions should act the same way, to match
	; what they do in SPEC_BUILD  -cct 1/10/95
	;
	mov	di, ds:[si]			;ds:di = instance
	add	di, ds:[di].Gen_offset		;ds:di = GenInstance
	cmp	ds:[di].GII_visibility, GIV_POPUP
	je	testInitiator
	cmp	ds:[di].GII_visibility, GIV_DIALOG
	jne	notDialog
testInitiator::
	test	ds:[di].GII_attrs, mask GIA_NOT_USER_INITIATABLE or \
				mask GIA_INITIATED_VIA_USER_DO_DIALOG
	jnz	OMG_saveQueryResults
notDialog:

	;ch.queryFlags, ch.visParent = MSG_GEN_GUP_QUERY(SGQT_BUILD_INFO);

	mov	ax, MSG_GEN_GUP_QUERY
	mov	cx, SGQT_BUILD_INFO
	mov	bp, dx				;pass OLBuildFlags in bp
	call	GenCallParent
	mov	ax, bp				;ax = OLBuildFlags
	jnc	OMG_queryNotAnswered

	;carry - clear if query not responded to

OMG_saveQueryResults:
	call	FindMapChunk			;ds:bx = OLMapGroupDataEntry
	mov	ds:[bx].OLMGDE_flags, ax
	mov	ds:[bx].OLMGDE_visParent.handle, cx
	mov	ds:[bx].OLMGDE_visParent.chunk, dx

	; if (visParent == 0) {
	;    ch.visParent = object->parent;
	; }

	tst	cx
	jnz	OMG_vpNotNull
	call	OLMapGroupUseParent
OMG_vpNotNull:

	pop	dx

	; ax = build flags, dx = offset of class passed
	; *ds:si = object

	;if (HINT_MAKE_REPLY_BAR) {
	;    return(OLReplyBarClass);
	;}

	push	ax				;save build flags
	mov	ax, HINT_MAKE_REPLY_BAR
	call	ObjVarFindData
	pop	ax				;restore build flags
	jnc	notReplyBar
	mov	dx, offset OLReplyBarClass	;use reply bar class
	jmp	short OMG_returnDXClass

notReplyBar:

	mov	di, ds:[si]			;ds:di = instance
	add	di, ds:[di].Gen_offset		;ds:di = GenInstance

	; ax = build flags, dx = offset of class passed
	; *ds:si = object, ds:di = GenInteaction instance

	;if (GIV_DIALOG) {
	;    return(classForWin);
	;}

	cmp	ds:[di].GII_visibility, GIV_DIALOG
	je	OMG_returnDXClass

	;if (GIV_POPOUT) {
	;    return(OLPopoutClass);
	;}

	cmp	ds:[di].GII_visibility, GIV_POPOUT
	jne	notPopout
	mov	dx, offset OLPopoutClass
	jmp	short OMG_returnDXClass

notPopout:

	;If (GIV_CONTROL_GROUP and (OLBR_TOP_MENU or OLBR_SUB_MENU)) {
	;    return(classForWin);
	;}

	mov	cx, ax
	andnf	cx, mask OLBF_REPLY
	cmp	ds:[di].GII_visibility, GIV_CONTROL_GROUP
	jne	notControlGroup
	cmp	cx, OLBR_TOP_MENU shl offset OLBF_REPLY
	je	OMG_returnDXClass
	cmp	cx, OLBR_SUB_MENU shl offset OLBF_REPLY
	je	OMG_returnDXClass
notControlGroup:

	;If we can turn into a menu or sub-menu then become a MenuWin

	;if (OLBR_TOP_MENU and GIV_POPUP) {
	;    return(OLMenuWinClass);
	;}
	;if (OLBR_SUB_MENU and GIV_SUB_GROUP) {
	;    return(OLMenuItemGroupClass);
	;}
	;if (OLBR_SUB_MENU and GIV_POPUP) {
	;    if (_SUB_MENU) {
	;        return(OLMenuWinClass);
	;    } else {
	;        return(OLMenuItemGroupClass);
	;    }
	;}
	;return(OLCtrlClass);

	mov	dx, offset OLMenuWinClass		;assume menu
	cmp	cx, OLBR_TOP_MENU shl offset OLBF_REPLY	;in menu bar?
	jne	OMG_notTopMenu				;no
	cmp	ds:[di].GII_visibility, GIV_POPUP	;menu in menu bar?
	je	OMG_returnDXClass			;yes, return top menu
OMG_notTopMenu:

	mov	dx, offset OLMenuItemGroupClass		;assume menu item group
	cmp	cx, OLBR_SUB_MENU shl offset OLBF_REPLY	;in menu?
	jne	OMG_returnCtrl				;no, return OLCtrlClass
	cmp	ds:[di].GII_visibility, GIV_SUB_GROUP	;menu sub-group?
	je	OMG_returnDXClass			;yes, return menu group

if _SUB_MENUS	;--------------------------------------------------------------
	;if SUB_MENUS are allowed in this specific UI, and GIV_POPUP requests
	;it, become a sub-menu

	cmp	ds:[di].GII_visibility, GIV_POPUP
	jne	OMG_returnCtrl
	mov	dx, offset OLMenuWinClass
endif		;--------------------------------------------------------------

OMG_returnDXClass:
	;return cx:dx as Class pointer
	mov	cx, segment CommonUIClassStructures
	ret				; <-- RETURN HERE

OMG_queryNotAnswered:
	; if the query was not answered then this is a dual build object
	; that has no button part -- return 0 for vis parent and passed class
	; for the class to be

	call	FindMapChunk			;ds:bx = OLMapGroupDataEntry
	clr	ax
	mov	ds:[bx].OLMGDE_visParent.handle, ax
	mov	ds:[bx].OLMGDE_visParent.chunk, ax
	pop	dx
	jmp	short OMG_returnDXClass

OMG_returnCtrl:
	mov	dx, offset OLCtrlClass
	jmp	short OMG_returnDXClass

OLMapGroup	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ScanMapGroupHintHandlers

DESCRIPTION:	Scan MapGroupHintHandlers table

CALLED BY:	INTERNAL
		OLMapGroup, OLButtonGetVisParent

PASS:
	*ds:si	- object to scan
	dx	- OLBuildFlags, if any, to pass through to handlers

RETURN:
	dx	- OLBuildFlags updated per hints

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/91		Initial version
------------------------------------------------------------------------------@

ScanMapGroupHintHandlers	proc	near
	uses	ax, di, es
	.enter
	mov	di, cs
	mov	es, di
	mov	di, offset cs:MapGroupHintHandlers
	mov	ax, length (cs:MapGroupHintHandlers)
	call	ObjVarScanData			;returns dx = OLBuildFlags
	.leave
	ret
ScanMapGroupHintHandlers	endp


; This table of hint handling routines is used by ScanMapGroupHintHandlers

MapGroupHintHandlers	VarDataHandler \
	<HINT_SEEK_MENU_BAR,offset MapGroupHintSeekMenuBar>,
	<HINT_AVOID_MENU_BAR,offset MapGroupHintAvoidMenuBar>,
	<HINT_IS_EXPRESS_MENU,offset MapGroupHintIsExpressMenu>,
	<HINT_SYS_MENU,offset MapGroupHintSysMenu>,
	<HINT_SEEK_REPLY_BAR,offset MapGroupHintSeekReplyBar>,
	<HINT_IS_POPUP_LIST,offset MapGroupHintPopupList>,
	<HINT_CUSTOM_SYS_MENU,offset MapGroupHintCustomSysMenu>


COMMENT @----------------------------------------------------------------------

FUNCTION:	MapGroupHintMenuable
		MapGroupHintSubGroup
		MapGroupHintSeekMenuBar
		MapGroupHintAvoidMenuBar
		MapGroupFileMenu
		MapGroupPrintMenu
		MapGroupEditMenu
		MapGroupWindowMenu
		MapGroupSysMenu (Motif only)
		MapGroupSeekReplyBar

DESCRIPTION:	Handle a HINT_... for OLMapGroup

CALLED BY:	GLOBAL

PASS:
	dx - OLBuildFlags

RETURN:
	dx - OLBuildFlags (updated to reflect this hint)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	Eric	10/89		Added HINT_SYS_MENU, HINT_SEEK, HINT_AVOID

------------------------------------------------------------------------------@

	; passes flags in dl

MapGroupHintSeekMenuBar	proc	far
	or	dx, mask OLBF_SEEK_MENU_BAR
	ret
MapGroupHintSeekMenuBar	endp

MapGroupHintAvoidMenuBar	proc	far
	or	dx, mask OLBF_AVOID_MENU_BAR
EC <	test	dx, mask OLBF_REPLY					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_REPLIES			>
	ORNF	dx, OLBR_TOP_MENU shl offset OLBF_REPLY
	ret
MapGroupHintAvoidMenuBar	endp

MapGroupHintIsExpressMenu	proc	far
EC <	test	dx, mask OLBF_TARGET					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_TARGETS			>
	ORNF	dx, OLBT_IS_EXPRESS_MENU shl offset OLBF_TARGET
EC <	test	dx, mask OLBF_REPLY					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_REPLIES			>
	ORNF	dx, OLBR_TOP_MENU shl offset OLBF_REPLY
	ret
MapGroupHintIsExpressMenu	endp

MapGroupHintSysMenu	proc	far
EC <	test	dx, mask OLBF_TARGET					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_TARGETS			>
	ORNF	dx, OLBT_SYS_MENU shl offset OLBF_TARGET
EC <	test	dx, mask OLBF_REPLY					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_REPLIES			>
	ORNF	dx, OLBR_TOP_MENU shl offset OLBF_REPLY
	ret
MapGroupHintSysMenu	endp

MapGroupHintSeekReplyBar	proc	far
EC <	test	dx, mask OLBF_TARGET					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_TARGETS			>
	ornf	dx, OLBT_FOR_REPLY_BAR shl offset OLBF_TARGET
	ret
MapGroupHintSeekReplyBar	endp

MapGroupHintPopupList	proc	far
EC <	test	dx, mask OLBF_TARGET					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_TARGETS			>
	ORNF	dx, (OLBT_IS_POPUP_LIST) shl offset OLBF_TARGET
EC <	test	dx, mask OLBF_REPLY					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_REPLIES			>
	ORNF	dx, OLBR_TOP_MENU shl offset OLBF_REPLY
	ret
MapGroupHintPopupList	endp

MapGroupHintCustomSysMenu	proc	far
EC <	test	dx, mask OLBF_TARGET					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_TARGETS			>
ISU <	ORNF	dx, OLBT_SYS_MENU shl offset OLBF_TARGET
EC <	test	dx, mask OLBF_REPLY					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_REPLIES			>
ISU <	ORNF	dx, OLBR_TOP_MENU shl offset OLBF_REPLY
	ret
MapGroupHintCustomSysMenu	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMapGroupUseParent

DESCRIPTION:	Set object's gen parent as the vis parent

CALLED BY:	OLMapGroup

PASS:
	*ds:si - object
	variable data storage - OLMapGroupData

RETURN:
	OLMWD_visParent - set

DESTROYED:
	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@


OLMapGroupUseParent	proc	near
	class	OLCtrlClass
	
	uses	si
	.enter
	mov	di, si				;save object chunk
	call	GenFindParent			;returns bx:si
	push	si
	push	bx
	mov	si, di				;*ds:si = object
	call	FindMapChunk			;ds:bx = OLMapGroupDataEntry
	pop	ds:[bx].OLMGDE_visParent.handle
	pop	ds:[bx].OLMGDE_visParent.chunk
	.leave
	ret

OLMapGroupUseParent	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	AllocMapChunk

DESCRIPTION:	Allocate a temporary OLMapGroupData chunk

CALLED BY:	OLMapGroup, OLBuildPrimary

PASS:
	*ds:si - object

RETURN:
	variable data storage allocated for OLMapGroupDataEntry

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@


AllocMapChunk	proc	near
	class	OLCtrlClass
	
	uses	ax, cx
	.enter
	mov	ax, MAP_GROUP_DATA
	mov	cx, size OLMapGroupDataEntry
	call	ObjVarAddData
	.leave
	ret

AllocMapChunk	endp

;
; pass:
;	*ds:si = object
; return:
;	ds:bx = OLMapGroupDataEntry
;
FindMapChunk	proc	near
	push	ax
	mov	ax, MAP_GROUP_DATA
	call	ObjVarFindData			;ds:bx = OLMapGroupDataEntry
EC <	ERROR_NC	OL_BUILD_CANT_FIND_MAP_GROUP_DATA		>
	pop	ax
	ret
FindMapChunk	endp

Build ends
