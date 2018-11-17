COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (common code for several specific UIs)
FLE:		copenContent.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLContentClass		GenContent object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/89		Initial version
	Doug	11/90		Moved from cviewContent.asm to this file

DESCRIPTION:

	$Id: copenContent.asm,v 1.1 97/04/07 10:53:59 newdeal Exp $
-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLContentClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

 method	VisCallParentEnsureStack, OLContentClass, MSG_OL_VUP_MAKE_APPLYABLE


;
; NATIVE method handlers (those implemented in this file)
;
method	VupCreateGState, OLContentClass, MSG_VIS_VUP_CREATE_GSTATE

CommonUIClassStructures ends


;---------------------------------------------------

ViewBuild segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLContentInitialize --
		MSG_META_INITIALIZE for OLContentClass

DESCRIPTION:	Initializes a content object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_INITIALIZE

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/31/89		Initial version

------------------------------------------------------------------------------@

OLContentInitialize	method	OLContentClass, MSG_META_INITIALIZE
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	cl, ds:[di].GCI_attrs		;get attrs the cheating way
	pop	di
	mov	ds:[di].VCNI_attrs, cl		;store in VisContent

	mov	di, offset OLContentClass
	CallSuper	MSG_META_INITIALIZE

	;
	; Mark geometry as invalid
	;
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_WINDOW_INVALID
	clr	ch
	mov	dl, VUM_MANUAL
	call	VisMarkInvalid
	ret

OLContentInitialize	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLContentSpecBuild -- MSG_SPEC_BUILD for OLContentClass

DESCRIPTION:	Visibly build an OLContent object.  There is nothing really
	 to be done, since our VisContent object from which we are subclassed
	 will build a visual link to the view when it is opened.  However,
	 we can finish setting behavior flags for the content based on specific
	 UI needs here.

PASS:
	 *ds:si - instance data
	 es - segment of OLContentClass

	 ax - MSG_SPEC_BUILD
	 bp - SpecBuildFlags

RETURN:
	 nothing

DESTROYED:
	 ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	 Name	Date		Description
	 ----	----		-----------
	 Doug	9/89		Initial version

------------------------------------------------------------------------------@

OLContentSpecBuild	method	OLContentClass, MSG_SPEC_BUILD

	 ; Just in case the link hasn't already been set up, set it up
	 ; now, since VIS BUILD routines may need it.
	 ;
	 ; FETCH view to use
	 ;
	 mov	di, ds:[si]			;point to instance
	 add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	 mov	cx, ds:[di].VCNI_view.handle
	 mov	dx, ds:[di].VCNI_view.chunk
EC <	 tst	cx						>
EC <	 ERROR_Z	OL_ERROR					>
	 ;
	 ; Set visual upward-only link. DO NOT add as a visual child, just
	 ; set up a parent link only.
	 ;
	 or	dx, 1				;make it a parent link!
	 mov	ds:[di].VI_link.LP_next.handle, cx
	 mov	ds:[di].VI_link.LP_next.chunk, dx

	 ;
	 ; Initialize geometry.
	 ; 
	 FALL_THRU	OLContentScanGeometryHints

OLContentSpecBuild	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLContentScanGeometryHints -- 
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLContentClass

DESCRIPTION:	Scans for geometry hints.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SCAN_GEOMETRY_HINTS

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

OLContentScanGeometryHints	method static OLContentClass, \
				MSG_SPEC_SCAN_GEOMETRY_HINTS
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
	mov	di, ds:[si]			;must dereference for static
	add	di, ds:[di].Vis_offset		;   method!
	;
	; Make content objects be expand-to-fit. (I don't think I want this.
	; text objects, for instance, try to keep to keep their width, but
	; the view stays large anyway because of this)
	;
	or	ds:[di].VCI_geoDimensionAttrs, \
			mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT or \
			mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
	;
	; We will always be using normal geometry, so we don't need to 
	; invalidate anything but our margins.
	;
	or	ds:[di].VCI_geoAttrs, mask VCGA_ONLY_DRAWS_IN_MARGINS
	.leave
	ret
OLContentScanGeometryHints	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLContentSetView --
		MSG_META_CONTENT_SET_VIEW for OLContentClass

DESCRIPTION:	Sets the view for the content object.  Otherwise, we don't
		know what view we are the contents of.

PASS:		*ds:si 	- instance data
		 es     	- segment of VisContentClass
		 ax 	- MSG_META_CONTENT_SET_VIEW
		 cx:dx	- View that this object sits under

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	 Name	Date		Description
	 ----	----		-----------
	 Doug	11/89		Initial version

------------------------------------------------------------------------------@

OLContentSetView	method	OLContentClass, MSG_META_CONTENT_SET_VIEW
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	ds:[di].GCI_genView.handle, cx   ;set new generic view
	mov	ds:[di].GCI_genView.chunk, dx    ;set new generic view
	call	ObjMarkDirty			   ;make sure this happens
	
	; Then, take generic View which we are associated with, &
	; give ourselves a one-way link upward to it, so that GUP queries
	; get across (unless we already have a generic parent)
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GI_link.LP_next.handle
	jnz	haveParent

	call	GenSetUpwardLink
haveParent:
	
	;
	; Call superclass, to set View
	;
	mov	ax, MSG_META_CONTENT_SET_VIEW
	mov	di, offset OLContentClass
	CallSuper	MSG_META_CONTENT_SET_VIEW
	ret

OLContentSetView	endm

ViewBuild ends

;----------------

ViewUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLContentGupQuery -- MSG_SPEC_GUP_QUERY for OLContentClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLContentClass

	ax - MSG_SPEC_GUP_QUERY
	cx - Query type (GenQueryType or SpecGenQueryType)
	dx -?
	bp - OLBuildFlags
RETURN:
	carry - set if query acknowledged, clear if not
	bp - OLBuildFlags
	cx:dx - vis parent

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	WARNING: see OLMapGroup for up-to-date details

	if (query = SGQT_BUILD_INFO) {
	    visParent = this object;
	} else {
		send query to superclass (will send to generic parent)
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version

------------------------------------------------------------------------------@


OLContentGupQuery	method	OLContentClass, MSG_SPEC_GUP_QUERY
	cmp	cx, SGQT_BUILD_INFO		;can we answer this query?
	je	OLContentGUQ_answer			;skip if so...

if _DUI
	cmp	cx, SGQT_SET_KEYBOARD_TYPE
	je	setKeyboardType
endif

	;we can't answer this query: call super class to handle
	mov	di, offset OLContentClass
	GOTO	ObjCallSuperNoLock

OLContentGUQ_answer:
	mov	cx, ds:[LMBH_handle]		; Just return THIS object
	mov	dx, si
	stc					;return query acknowledged
	ret

if _DUI
setKeyboardType:
	;
	; pass query this from GenContent to GenView
	;
	call	VisCallParent			; return answer from parent
	ret
endif

OLContentGupQuery	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLContentTrackScrolling -- 
		MSG_META_CONTENT_TRACK_SCROLLING for OLContentClass

DESCRIPTION:	Content, for lack of anything better to do, punts the normalize
		to the first child.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_TRACK_SCROLLING

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/25/90		Initial version

------------------------------------------------------------------------------@

OLContentTrackScrolling	method OLContentClass, MSG_META_CONTENT_TRACK_SCROLLING

	; First, see if there is a target object.  If so, send events there.

	; This a reasonable thing to do for TRACK_SCROLLING, as this would be
	; the object that the user currently working with.
	
	; LARGE mouse events arriving here are implied mouse events in a
	; LARGE vis tree,  in which case the target is normally the active
	; layer -- also reasonable default behavior

	mov	bx, ds:[di].VCNI_targetExcl.FTVMC_OD.handle
	tst	bx
	jz	noTarget
	mov	si, ds:[di].VCNI_targetExcl.FTVMC_OD.chunk
	jmp	common

noTarget:
	; If not, send to first child so that things will work in simple,
	; one-child generic object models
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GI_comp.CP_firstChild.handle
	tst_clc	bx
	jz	callSuper
	mov	si, ds:[di].GI_comp.CP_firstChild.chunk
common:
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	stc
	ret

callSuper:
	mov	di, offset OLContentClass
	GOTO	ObjCallSuperNoLock

OLContentTrackScrolling	endm

ViewUncommon	ends
		

KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLContentFupKbdChar - MSG_META_FUP_KBD_CHAR handler for OLContentClass

DESCRIPTION:	This method is sent by child which 1) is the focused object
		and 2) has received a MSG_META_KBD_CHAR or MSG_META_FUP_KBD_CHAR
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

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLContentFupKbdChar	method dynamic	OLContentClass,
					MSG_META_FUP_KBD_CHAR
	;Don't handle state keys (shift, ctrl, etc).

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	sendUpFocusHierarchy		;let application deal with these

	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	sendUpFocusHierarchy		;skip if not press event...

if _KBD_NAVIGATION	;------------------------------------------------------
	push	es
						;set es:di = table of shortcuts
						;and matching methods
	mov	di, cs
	mov	es, di
	mov	di, offset cs:OLContentKbdBindings
	call	ConvertKeyToMethod
	pop	es
	jc	sendMethod			;skip if found...
endif	;----------------------------------------------------------------------

sendUpFocusHierarchy:
	;we don't care about this keyboard event. Forward it up the
	;focus hierarchy.

	mov	ax, MSG_META_FUP_KBD_CHAR
	call	VisCallParent			;must match what OLContent does
	ret

sendMethod:
	;found a shortcut: send method to self.

	call	ObjCallInstanceNoLock
done:
	ret
OLContentFupKbdChar	endm


			
if _KBD_NAVIGATION	;------------------------------------------------------

;Keyboard shortcut bindings for OLContentClass (do not separate tables)

OLContentKbdBindings	label	word
	word	length OLICShortcutList
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r



if DBCS_PCGEOS

OLICShortcutList	KeyboardShortcut \
		<0, 0, 0, 0, C_SYS_TAB and mask KS_CHAR>,	;NEXT FIELD
		<0, 0, 0, 1, C_SYS_TAB and mask KS_CHAR>,	;PREVIOUS FIELD
		<0, 0, 1, 0, C_SYS_TAB and mask KS_CHAR>,	;NEXT FIELD
		<0, 0, 1, 1, C_SYS_TAB and mask KS_CHAR>,	;PREVIOUS FIELD
		<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,
		<0, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;PREVIOUS FIELD
		<0, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;NEXT FIELD
		<0, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>	;PREVIOUS FIELD
else

OLICShortcutList	KeyboardShortcut \
		<0, 0, 0, 0, 0xf, VC_TAB>,	;NEXT FIELD
		<0, 0, 0, 1, 0xf, VC_TAB>,	;PREVIOUS FIELD
		<0, 0, 1, 0, 0xf, VC_TAB>,	;NEXT FIELD
		<0, 0, 1, 1, 0xf, VC_TAB>,	;PREVIOUS FIELD
		<0, 0, 0, 0, 0xf, VC_DOWN>,	;NEXT FIELD
		<0, 0, 0, 0, 0xf, VC_UP>,	;PREVIOUS FIELD
		<0, 0, 0, 0, 0xf, VC_RIGHT>,	;NEXT FIELD
		<0, 0, 0, 0, 0xf, VC_LEFT>	;PREVIOUS FIELD

endif

;OLICMethodList	label word
	word	MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	word	MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
	word	MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	word	MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
	word	MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	word	MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
	word	MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	word	MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD


endif	;KBD_NAVIGATION -------------------------------------------------------

KbdNavigation	ends


ViewCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLContentApplyDefaultFocus -- 
		MSG_META_CONTENT_APPLY_DEFAULT_FOCUS for OLContentClass

DESCRIPTION:	Applies the default focus to the last object with HINT_DEFAULT_
		FOCUS in the visible tree under the content.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_APPLY_DEFAULT_FOCUS

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
	chris	11/13/91		Initial Version

------------------------------------------------------------------------------@

OLContentApplyDefaultFocus	method dynamic	OLContentClass, \
				MSG_META_CONTENT_APPLY_DEFAULT_FOCUS
				
	mov	di, ds:[si]		;someone has focus, exit
	add	di, ds:[di].Vis_offset
	tst	ds:[di].VCNI_focusExcl.FTVMC_OD.handle
	jnz	exit
	
	mov	ax, MSG_GEN_START_BROADCAST_FOR_DEFAULT_FOCUS
	call	ObjCallInstanceNoLock
					;will reset cx, dx, bp before searching
	tst	cx			;did we find a hint?
	jz	10$			;skip if not answered...

	;there is an object which has the HINT_DEFAULT_FOCUS. Store its
	;OD and info about it (i.e. windowed or not)

	mov	bp, mask MAEF_GRAB or mask MAEF_FOCUS
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
	jmp	short exit

10$:	;there is no such object: must assign focus to first child in
	;navigation circuit (even if this specific UI does not support
	;"TABBING" navigation, it may support auto-navigation between text
	;objects, so find first text object)

;	mov	ax, MSG_GEN_NAVIGATE_TO_NEXT_FIELD
;	call	ObjCallInstanceNoLock
;we can't use this because if nothing in the content wants the focus, this will
;send up the MSG_GEN_NAVIGATE_TO_NEXT_FIELD to the VisParent, screwing up
;the focus in the parent window - brianc 5/20/92
	clr	bp			;forward navigation
	call	OLContentNavigateCommon	;if nothing within content gets it,
					;	just give up
exit:
	ret
	
OLContentApplyDefaultFocus	endm

ViewCommon ends

;----------------------

ViewUncommon segment resource
				

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLContentStartBroadcastForDefaultFocus --
			MSG_SPEC_START_BROADCAST_FOR_DEFAULT_FOCUS

DESCRIPTION:	The generic version of this method is sent when the specific
		UI opens a window, and wants to know if an object within the
		window has HINT_DEFAULT_FOCUS{_WIN}.

PASS:		*ds:si	= instance data for object

RETURN:		^lcx:dx	= object with hint (0:0 if none)
		bp	= info on that object (HGF_IS_WINDOW, etc)

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Eric	5/90		rewritten to use broadcast which scans entire
					window.

------------------------------------------------------------------------------@

OLContentStartBroadcastForDefaultFocus method dynamic OLContentClass, \
			MSG_SPEC_START_BROADCAST_FOR_DEFAULT_FOCUS

	;initialize view to nil, since we do not yet know of a default focus obj.
	clr	cx
	clr	dx
	clr	bp

	;send MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS to all visible
	;children which are FULLY_ENABLED. Returns last object in visible
	;tree which has HINT_DEFAULT_FOCUS{_WIN}.

	mov	ax, MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS
	mov	bx, offset OLBroadcastForDefaultFocus_callBack
					;pass offset to callback routine,
					;in Resident resource
	GOTO	OLResidentProcessVisChildren
OLContentStartBroadcastForDefaultFocus	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLContentNavigate - MSG_SPEC_NAVIGATION_QUERY handler
			for OLContentClass

DESCRIPTION:	This method is used to implement the keyboard navigation
		within-a-window mechanism. See method declaration for full
		details.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		^lcx:dx	= object which originated the navigation method
		bp	= NavigationFlags

RETURN:		ds, si	= same
		^lcx:dx	= replying object
		bp	= NavigationFlags (in reply)
		carry set if found the next/previous object we were seeking
		ax - destroyed

DESTROYED:	ax, bx, es, di

PSEUDO CODE/STRATEGY:
	OLContentClass handler:
	    Since we have received this method at this class level, we know
	    that if this object is subclassed by something in the specific UI,
	    it is something that is never focused, and so is excluded from
	    navigation (a GenInteraction which becomes an OLCtrlClass for
	    example). So all we need to do is forward this method to the
	    to first visible child, or next sibling (hints may affect
	    how next sibling is reached.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@
;SAVE BYTES: VisClass handler could return ContentOSITE flag by looking
;at VisTypeFlags (they line up... trust me!)

OLContentNavigate method dynamic OLContentClass, MSG_SPEC_NAVIGATION_QUERY

	;
	; Rudy doesn't allow navigating out of contents to other gadgets
	; that are siblings of the view -- the spec doesn't call for it
	; and it allows us to correctly handle stopping navigation at the
	; top or bottom of a content, rather than wrapping around.  -cbh
	;
	test	bp, mask NF_BACKTRACK_AFTER_TRAVELING
	jnz	navigate		;if going backwards, do normal navigate
					;  for now, we'll check for stuff
					;  after calling VisNavigateCommon
	test	bp, mask NF_SKIP_NODE
	jnz	answerQuery		;skipping node, the last visible child
					;  must be sending the query back up
					;  to us, we'll answer the query
					;  and later send it up to the view.
navigate:

	mov	bl, mask NCF_IS_COMPOSITE or mask NCF_IS_ROOT_NODE
					;pass flags: is composite, is
					;  root node, not focusable.
	mov	di, si			;if this object has generic part,
					;ok to scan it for hints.
	call	VisNavigateCommon

	mov	al, 0ffh		;return is focusable
	jmp	short exit
	
answerQuery:
	mov	cx, ds:[LMBH_handle]	;answer the query
	mov	dx, si
	stc


exit:

	ret
OLContentNavigate	endm

ViewUncommon	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLContentInitialNavigate -- 
		MSG_META_CONTENT_NAVIGATION_QUERY for OLContentClass

DESCRIPTION:	The view just got the focus, we'll figure out something to give
		the focus to.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_NAVIGATION_QUERY
		
		^lcx:dx	= object which originated this query
		bp	= NavigateFlags 

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
	chris	11/ 7/91		Initial Version

------------------------------------------------------------------------------@

OLContentInitialNavigate	method dynamic	OLContentClass, \
				MSG_META_CONTENT_NAVIGATION_QUERY
	;this window does not yet have a focused object. Find the first
	;object in the visible tree and place the focus on it.
	;(If the application wanted the navigation to start on some specific
	;object, the object would have HINT_MAKE_FOCUS.) Since this method
	;will be passed downwards by composite objects, turn off the SKIP flag.

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	ANDNF	bp, not (mask NF_SKIP_NODE)
	ORNF	bp, mask NF_INITIATE_QUERY
	
	;start a navigation query around the window.. It will loop
	
	;around the navigation circuit (visible tree) if necessary,
	;to find the NEXT/PREVIOUS object we are seeking.  

	push	si
	mov	ax, MSG_SPEC_NAVIGATE
	call	ObjCallInstanceNoLock
	pop	si
	
	;If the content answers, it means we need make the view navigate 
	;backwards or forwards.  Otherwise, give the focus to the object
	;that answered.   (Changed 12/ 9/92 cbh to just give up if no
	;navigation answered, to avoid infinite navigation in the view's
	;parent window if no other object wants the focus.)
	
;	jnc	makeViewNavigate	;nothing there, go upstairs
;	tst	cx	
;	jz	makeViewNavigate

	jnc	done			;nothing there, give up
	tst	cx	
	jz	done

	cmp	cx, ds:[LMBH_handle]	
	jne	giveFocusToObject
	cmp	dx, si
	je	short done

;	jne	giveFocusToObject
;	
;makeViewNavigate:
;	;for some reason, the query wasn't handled. We'll make the assumption
;	;that the we were trying to navigate forwards or backwards and tell
;	;the view to try navigating forwards or backwards again.  (Changed
;	;12/ 9/92 cbh to just give up if no navigation answered.)
;
;	mov	ax, MSG_GEN_NAVIGATE_TO_NEXT_FIELD	
;	test	bp, mask NF_BACKTRACK_AFTER_TRAVELING
;	jz	10$
;	mov	ax, MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD	
;10$:
;	GOTO	VisCallParent
	
giveFocusToObject:
	mov	bp, mask MAEF_GRAB or mask MAEF_FOCUS
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock

if (0)	; We'll deal with HINT_CONTENT_KEEP_FOCUS_VISIBLE in
	; OLContentMupAlterFTVMCExcl. - Joon (9/18/95)
	;
	; Scroll, if necessary, to get the object onscreen.  -cbh 12/16/92
	; Only if HINT_CONTENT_KEEP_FOCUS_VISIBLE set.  -cbh 1/31/93
	;
					; load real focus, not the one we
					;	tried to set - brianc 12/30/92

	mov	ax, HINT_CONTENT_KEEP_FOCUS_VISIBLE
	call	ObjVarFindData
	jnc	20$

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].VCNI_focusExcl.FTVMC_OD.handle	
	mov	dx, ds:[di].VCNI_focusExcl.FTVMC_OD.chunk
	call	EnsureObjectOnscreen
20$:

	;
	; Tell our view's parent window that we've been successful searching
	; for a content object to give the focus to.  If the OLWin encounters
	; another navigation query, it's probably new navigation, rather than
	; a problem with the content finding a focusable object.  -6/23/92 cbh
	; (Let's not implement this yet.)
	;

;	mov	ax, MSG_OL_WIN_FOUND_FOCUSABLE_CONTENT_OBJECT
;	call	SwapLockOLWin
endif

done:
	ret
OLContentInitialNavigate	endm


KbdNavigation	ends


ViewUncommon	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLContentNavigateToNext - MSG_SPEC_NAVIGATE_TO_NEXT
		OLContentNavigateToPrevious - MSG_SPEC_NAVIGATE_TO_PREVIOUS

DESCRIPTION:	This method is used to implement the keyboard navigation
		within-a-window mechanism. See method declaration for full
		details.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object

RETURN:		ds, si	= same

DESTROYED:	ax, bx, cx, dx, bp, es, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLContentNavigateToNextField	method dynamic	OLContentClass, \
					MSG_SPEC_NAVIGATE_TO_NEXT_FIELD
	clr	bp			;pass flags: navigate forwards
					;pass ds:di = VisSpec instance data
	GOTO	DoNavigate
	
OLContentNavigateToNextField	endm

OLContentNavigateToPreviousField	method dynamic	OLContentClass, \
					MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD
	mov	bp, mask NF_TRAVEL_CIRCUIT or mask NF_BACKTRACK_AFTER_TRAVELING
					;pass flags: we are trying to navigate
					;backards.
					;pass ds:di = VisSpec instance data
DoNavigate	label far
	push	ax
	call	OLContentNavigateCommon
	pop	ax
	jc	exit
	call	VisCallParent		;try parent view
exit:
	ret
OLContentNavigateToPreviousField	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLContentNavigateCommon

DESCRIPTION:	This procedure is used by MSG_SPEC_NAVIGATE_TO_NEXT_FIELD
		and MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD handlers.

CALLED BY:	OLContentNavigateToNextField
		OLContentNavigateToPreviousField

PASS:		*ds:si	= instance data for object
		ds:di	= VisSpec instance data
		bp	= NavigationFlags, to indicate whether navigating
				backwards or forwards, and whether navigating
				through menu bar or controls in window.

RETURN:		carry set if someone has the focus

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	11/91		initial version

------------------------------------------------------------------------------@

OLContentNavigateCommon	proc	far
	;get focused object within this window

	push	bp			;save forward/backward info
	call	OLContent_Deref_Load_FocusExcl_CXDX	

	ORNF	bp, mask NF_SKIP_NODE or mask NF_INITIATE_QUERY
					;pass flag: skip focused node,
					;find next focusable node
	mov	ax, cx			;is there a focused object?
	or	ax, dx
	jnz	sendNavQueryToOD	;skip if so...

	;this window does not yet have a focused object. Find the first
	;object in the visible tree and place the focus on it.
	;(If the application wanted the navigation to start on some specific
	;object, the object would have HINT_MAKE_FOCUS.) Since this method
	;will be passed downwards by composite objects, turn off the SKIP flag.

	mov	dx, si
	mov	cx, ds:[LMBH_handle]
	ANDNF	bp, not (mask NF_SKIP_NODE)
	
sendNavQueryToOD:
	;send a navigation query to the specified object. It will forward
	;the method around the navigation circuit (visible tree) if necessary,
	;to find the NEXT/PREVIOUS object we are seeking.

	push	si
	mov	ax, MSG_SPEC_NAVIGATE
	mov	bx, cx			;pass ^lcx:dx = object which will
	mov	si, dx			;start the navigation query.
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	;NOW finish up with specific checks according to the navigation
	;direction.  If not handled at all, we'll release the focus and
	;call the view.

	pop	ax
	jnc	releaseFocus		;nothing there, release
	tst	cx	
	jz	releaseFocus
	
answered:
	;If the content answered the query, it means we need to make the view
	;navigate forwards or backwards.  Release the current focus and
	;return carry clear.
	
	cmp	cx, ds:[LMBH_handle]
	jne	grabFocusExclIfNeeded
	cmp	dx, si
	jne	grabFocusExclIfNeeded
	
releaseFocus:
	call	OLContent_Deref_Load_FocusExcl_CXDX	
	tst	cx
	clc
	jz	done			;no previous focus, exit (carry clear)
	
	mov	bp, mask MAEF_FOCUS
	jmp	short alterFocusBelowThisNode

grabFocusExclIfNeeded:
	;
	; See if object that answered query hasn't changed.  Don't do anything
	; if so.  Otherwise, grab the focus for the object.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	cmp	cx, ds:[di].VCNI_focusExcl.FTVMC_OD.handle	
	jne	grabFocusExcl
	cmp	dx, ds:[di].VCNI_focusExcl.FTVMC_OD.chunk
	stc
	je	done			;done (carry set)

grabFocusExcl:
	mov	bp, mask MAEF_GRAB or mask MAEF_FOCUS
	stc

alterFocusBelowThisNode:
	pushf
	push	bp
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
	pop	bp

if (0)	; We'll deal with ensuring is onscreen in OLContentMupAlterFTVMCExcl.
	; - Joon (9/18/95)
	;
	; Scroll, if necessary, to get the object onscreen.  -cbh 12/16/92
	; (Not yet)
	;
	test	bp, mask MAEF_GRAB
	jz	noEnsure		; not if release - brianc 12/30/92
					; load real focus, not the one we
					;	tried to set - brianc 12/30/92
	call	OLContent_Deref_Load_FocusExcl_CXDX	
	call	EnsureObjectOnscreen
noEnsure:
endif

	popf
done:
	ret
OLContentNavigateCommon	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	EnsureObjectOnscreen

SYNOPSIS:	Ensures that an object is onscreen.

CALLED BY:	OLContentInitialNavigate

PASS:		*ds:si -- content
		^lcx:dx -- object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/16/92       	Initial version

------------------------------------------------------------------------------@

EnsureObjectOnscreen	proc	far		uses	si
	.enter
	tst	dx				;nothing here, exit
	LONG jz	exit

	push	si
	movdw	bxsi, cxdx
	
	mov	ax, MSG_VIS_GET_ATTRS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;returns attrs in cl
	test	cl, mask VA_REALIZED		;not realized, forget it
	jz	5$

	;
	; if focus item is a OLScrollableItem, use
	; MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE instead, this is specifically
	; for dynamic lists, which have view doc bounds for the virtual
	; items, hence MSG_VIS_GET_BOUNDS will not work - brianc 12/30/92
	;
	; XXX: If it is a OLScrollableItem, we probably don't need to do
	; anything, as the code in OLScrollList handles ensuring that the
	; item is visible.
	;
	; Okay, we must do nothing if the focus is a GenDynamicList or a
	; OLScrollableItem, as the list handles that.  We don't want to
	; MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE as the focus needn't be
	; visible.
	;
if 0
	mov	cx, segment OLScrollableItemClass
	mov	dx, offset OLScrollableItemClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jc	bail			; is OLScrollableItem, do nothing
	mov	cx, segment GenDynamicListClass
	mov	dx, offset GenDynamicListClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jnc	notScrollItem		; is not dynamic list, continue
					; else, do nothing
bail:
	pop	si
	jmp	short exit
else
	mov	cx, segment OLScrollableItemClass
	mov	dx, offset OLScrollableItemClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jnc	notScrollItem		; is not , continue
	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; ax = identifier
	mov	cx, ax			; cx = identifier
	push	si
	clr	bx, si
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	mov	di, mask MF_RECORD
	call	ObjMessage		; di = event
	pop	si
	mov	cx, di			; cx = event
	mov	ax, MSG_GEN_CALL_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	jmp	short exit
endif

notScrollItem:

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_GET_BOUNDS		;get object bounds
	call	ObjMessage			;bounds in ax/bp/cx/dx
	tst	si				;clear zero flag
5$:
	pop	si
	jz	exit				;nothing to bring onscreen...

	mov	bx, bp				;bx <- top

	sub	sp, size MakeRectVisibleParams
	mov	bp, sp
	clr	di
	mov	ss:[bp].MRVP_xFlags, di
	mov	ss:[bp].MRVP_yFlags, di
	mov	ss:[bp].MRVP_xMargin, di
	mov	ss:[bp].MRVP_yMargin, di
	mov	di, offset MRVP_bounds.RD_left
	call	StoreAxInDWord
	mov	ax, bx
	mov	di, offset MRVP_bounds.RD_top
	call	StoreAxInDWord
	mov	ax, cx
	mov	di, offset MRVP_bounds.RD_right
	call	StoreAxInDWord
	mov	ax, dx
	mov	di, offset MRVP_bounds.RD_bottom
	call	StoreAxInDWord

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].VCNI_view.handle
	mov	si, ds:[di].VCNI_view.chunk
	tst	si
	jz	10$
	mov	dx, size MakeRectVisibleParams
	mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT or \
		    mask MF_STACK
	call	ObjMessage
10$:
	add	sp, size MakeRectVisibleParams
exit:
	.leave
	ret
EnsureObjectOnscreen	endp


StoreAxInDWord	proc	near
	;
	; ss:[bp][di] -- offset to variable to store	
	; ax -- value to store
	; destroyed - ax
	;
	mov	ss:[bp][di].low, ax		;store the low word
	tst	ax				
	mov	ax, 0				;sign extend to high word
	jns	10$
	not	ax				
10$:
	mov	ss:[bp][di].high, ax
	ret
StoreAxInDWord	endp

			


COMMENT @----------------------------------------------------------------------

METHOD:		OLContentVupQuery -- 
		MSG_VIS_VUP_QUERY for OLContentClass

DESCRIPTION:	Handles vup queries.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_VUP_QUERY

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
	chris	12/11/91	Initial Version

------------------------------------------------------------------------------@

OLContentVupQuery	method dynamic	OLContentClass, MSG_VIS_VUP_QUERY
	cmp	cx, SVQT_QUERY_WIN_GROUP_FOR_FOCUS_EXCL
	jne	callSuper

	;This query is sent by a GenItemGroup which is inside this window
	;when it needs to know if it will get the FOCUS exclusive when
	;it requests it. It uses this info to optimize its redraws.
	;Also, gadgets use this query to find out which object has the focus,
	;to see if the gadget is permitted to grab the focus as the user
	;presses the mouse on that gadget.
	;
	;IF THIS ROUTINE MUST ERR, LEAN TOWARDS "FALSE". This will
	;cause excessive drawing in gadgets, which is better than no drawing!

	clr	bp			;assume FALSE
	call	OLContent_Deref_Load_FocusExcl_CXDX
	mov	ax, ds:[di].VCNI_focusExcl.FTVMC_flags
	test	ax, mask HGF_APP_EXCL
	jz	325$			;skip if not...
	mov	bp, TRUE
325$:
	stc
	ret
	
callSuper:
	mov	di, offset OLContentClass
	CallSuper	MSG_VIS_VUP_QUERY
	ret
OLContentVupQuery	endm


OLContent_Deref_Load_FocusExcl_CXDX	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].VCNI_focusExcl.FTVMC_OD.handle	
	mov	dx, ds:[di].VCNI_focusExcl.FTVMC_OD.chunk
	ret
OLContent_Deref_Load_FocusExcl_CXDX	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLContentMupAlterFTVMCExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle HINT_CONTENT_KEEP_FOCUS_VISIBLE

CALLED BY:	MSG_META_MUP_ALTER_FTVMC_EXCL
PASS:		*ds:si	= OLContentClass object
		ds:di	= OLContentClass instance data
		ds:bx	= OLContentClass object (same as *ds:si)
		es 	= segment of OLContentClass
		ax	= message #
		^lcx:dx	= object wishing to grab/release exlusive(s)
		bp	= MetaAlterFTVMCExclFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLContentMupAlterFTVMCExcl	method dynamic OLContentClass, 
					MSG_META_MUP_ALTER_FTVMC_EXCL
	push	bp	
	mov	di, offset OLContentClass
	call	ObjCallSuperNoLock
	pop	bp

	test	bp, mask MAEF_FOCUS
	jz	done
	test	bp, mask MAEF_GRAB
	jz	done

	; Scroll, if necessary, to get the object onscreen.  -cbh 12/16/92
	; Only if HINT_CONTENT_KEEP_FOCUS_VISIBLE set.  -cbh 1/31/93
	;
	mov	ax, HINT_CONTENT_KEEP_FOCUS_VISIBLE
	call	ObjVarFindData
	jnc	done

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	movdw	cxdx, ds:[di].VCNI_focusExcl.FTVMC_OD
	GOTO	EnsureObjectOnscreen
done:
	ret
OLContentMupAlterFTVMCExcl	endm


ViewUncommon ends

;------------------

ViewCommon segment resource





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	OLContentUpdateGeometry -- 
	MSG_VIS_UPDATE_GEOMETRY for OLContentClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	When the geometry changes, scrolls to keep the focus 
		visible.

PASS:		*ds:si 	- instance data of OLContentClass object
		ds:di	- OLContentClass instance data
		ds:bx	- OLContentClass object (same as *ds:si)
		es     	- segment of OLContentClass
		ax 	- MSG_VIS_UPDATE_GEOMETRY

RETURN:		
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/12/95	Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLContentUpdateGeometry	method dynamic	OLContentClass, \
				MSG_VIS_UPDATE_GEOMETRY
	.enter
	mov	di, offset OLContentClass
	call	ObjCallSuperNoLock

	; Scroll, if necessary, to get the object onscreen.  -cbh 12/16/92
	; Only if HINT_CONTENT_KEEP_FOCUS_VISIBLE set.  -cbh 1/31/93
	;
	mov	ax, HINT_CONTENT_KEEP_FOCUS_VISIBLE
	call	ObjVarFindData
	jnc	exit

;	This does nothing if nobody has the focus

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	movdw	cxdx, ds:[di].VCNI_focusExcl.FTVMC_OD
	call	EnsureObjectOnscreen
exit:
	.leave
	ret
OLContentUpdateGeometry	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLContentViewOriginChanged

DESCRIPTION:	Handles these messages by doing superclass stuff, then
		sending them on to the first child.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- message
		cx, dx, bp - arguments

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
	chris	3/11/92		Initial Version

------------------------------------------------------------------------------@

OLContentViewOriginChanged	method dynamic	OLContentClass, \
				MSG_META_CONTENT_VIEW_ORIGIN_CHANGED,
				MSG_META_CONTENT_VIEW_WIN_OPENED
	;
	; Call superclass first.
	;
	push	ax, cx, dx, bp
	mov	di, offset OLContentClass
	call	ObjCallSuperNoLock
	pop	ax, cx, dx, bp

	;
	; Large document layer, already sent to vis children by superclass,
	; don't send to first child.  -cbh 3/19/93
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCNI_attrs, mask VCNA_LARGE_DOCUMENT_MODEL	
	jnz	done
	call	VisCallFirstChild
done:

	;
	; if desired, make sure focus is visible
	;
	mov	ax, HINT_CONTENT_KEEP_FOCUS_VISIBLE
	call	ObjVarFindData
	jnc	noEnsure

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].VCNI_focusExcl.FTVMC_OD.handle	
	mov	dx, ds:[di].VCNI_focusExcl.FTVMC_OD.chunk
	call	EnsureObjectOnscreen
noEnsure:

	ret
OLContentViewOriginChanged	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLContentChange -- 
		MSG_SPEC_CHANGE for OLContentClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Comes from a "change" being pressed in Rudy.

PASS:		*ds:si 	- instance data
		es     	- segment of OLContentClass
		ax 	- MSG_SPEC_CHANGE

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
	chris	5/18/95         	Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



ViewCommon	ends


ViewUncommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLContentGetBuildFlags -- 
		MSG_VUP_GET_BUILD_FLAGS for OLContentClass

DESCRIPTION:	Returns build flags.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VUP_GET_BUILD_FLAGS

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
	chris	4/ 9/92		Initial Version

------------------------------------------------------------------------------@

OLContentGetBuildFlags	method dynamic	OLContentClass, \
				MSG_VUP_GET_BUILD_FLAGS
	;
	; The content is part of some other window.  Let's assume this is
	; done as the result of a SPEC_BUILD, and we can count on our Vis
	; parent link being established.
	;
	GOTO	VisCallParent

OLContentGetBuildFlags	endm

ViewUncommon ends
