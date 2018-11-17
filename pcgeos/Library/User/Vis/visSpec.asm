COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Spec
FILE:		visSpec.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/91		Initial version

DESCRIPTION:
	This file contains visual handlers that are needed for the specific
	UI implementation only.

	$Id: visSpec.asm,v 1.1 97/04/07 11:44:31 newdeal Exp $

	
	
	


****************************************************************************
Generic to Specific Visual World concepts & definitions
****************************************************************************

Generic/Specific object visual types
------------------------------------
	GS_USABLE		- Indicates if application allows generic
				  object to be used in interface.  All parent
				  objects must have this bit set in order
				  for the object to really be usable.

	VTF_IS_WIN_GROUP	- Set to indicate a WIN_GROUP

	Specific visual attributes stored in every visual object generated
	to implement the generic objects:

	VTF_USES_DUAL_BUILD	- Indicates specific UI creates non-WIN_GROUP
				  visual component(s) as well for this
				  object.  These components will become
				  realized if WIN_GROUP they are on is realized.

	Specific visual attributes for Generic Objects which the specific
	UI makes into visual WIN_GROUP's only:

	VSA_ATTACHED		- Indicates application & this object are
				  attached for use.  Cleared
				  to force down windows of application.

	VSA_REALIZABLE		- Indicates whether the specific UI wishes
				  for the WIN_GROUP portion (if object can
				  appear as a WIN_GROUP), may be realized.

Generic/Specific object visual states, changing/updating messages
----------------------------------------------------------------

	In order to make a WIN_GROUP come up on screen or go away,
	you used to use MSG_VIS_SET_ATTR to set/clear VA_VISIBLE.  This
	bit is now reserved for the VISIBLE world & should not be used
	directly by Specific UI code.  Instead,  You manipulate the bits
	GS_USABLE, SA_ATTACHED,& SA_REALIZABLE.  All three must be set
	before the object is made visible.  In addition, the bit
	SA_BRANCH_MINIMIZED may be set, which will prevent ANY objects
	having WIN_GROUP's below this point in the generic tree from
	being VISIBLE. These bits may be set using:

	For generic objects created by the specific UI (normally these
	messages are reserved for use by the application):

		GS_USABLE:	MSG_GEN_SET_USABLE,
				MSG_GEN_SET_NOT_USABLE

		VSA_ATTACHED, 
		VSA_REALIZABLE, 
		VSA_BRANCH_MINIMIZED:
				MSG_SPEC_SET_ATTR

	The above messages end up checking to see if all three bits are set,
	& that all generic parents are usable & that no generic parents
	have the BRANCH_MINIMIZED bit set.  If all of this is true,
	the object is marked as VISIBLE, else it is marked as not VISIBLE,
	& it is updated (based on the VisUpdateMode passed)


	Many GENERIC messages, such as MSG_GEN_SET_USABLE, accept VisUpdateMode
	flags in dl, & will perform the appropriate visual update once the 
	generic change has been made.
	

Specific Visual state MESSAGES
-----------------------------

	MSG_SPEC_BUILD_BRANCH
	MSG_SPEC_BUILD
	MSG_SPEC_GET_SPECIFIC_VIS_OBJECT
	MSG_SPEC_GET_VIS_PARENT
	MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD


****************************************************************************
How to write MSG_SPEC_BUILD_BRANCH, MSG_SPEC_BUILD, & other stuff
****************************************************************************

Overview
--------
	Generic trees are converted to visual by virtue of any sequence of 
	message calls which result in their being USABLE & VISIBLE. 
	This triggers a MSG_VIS_VUP_UPDATE_WIN_GROUP, which when
	executed travels up to the first object marked as a WIN GROUP,
	& proceeds to visually validate it:  It is

		1) Generic objects which are marked USABLE by the application, &
		determined by the specific UI to be visible are recursively sent
		MSG_SPEC_BUILD, which requests the object to add itself
		visually.  The specific UI makes this determination & performs
		the action.
	
		2) Geometric layout is performed for all managed objects.
	
		3) Windows are laid out according to the visible bounds
	
		4) The window images are redrawn.

MSG_SPEC_BUILD
----------------
	The result of the specific build is to create a visual tree out of
	the generic tree.  For each generic object in a branch headed by 
	a WIN_GROUP, a MSG_SPEC_BUILD_BRANCH message is sent to the object.
	The default handler for this is to send a MSG_SPEC_BUILD to the
	object, & then send a MSG_SPEC_BUILD_BRANCH to all of the object's
	generic children.  This message is rarely replaced.  The
	MSG_SPEC_BUILD is rather frequently replaced or augmented, though.

	Objects may rely on the default MSG_SPEC_BUILD for the following
	cases:

		* Generic object becomes sole visible object.
		  (VTF_SIMPLE_GEN_OBJ must be set)  NOTE that objects
		  that visually appear as different objects that their
		  generic object (dual build menus, a GenText in a View)
		  must respond to the MSG_SPEC_GET_SPECIFIC_VIS_OBJECT so that
		  THIS routine can place new objects created & added between
		  the correct visual children.

		* Generic object has NOT set VTF_USES_DUAL_BUILD

		* Object is to be placed visually on its generic parent,
		  or if not, object must respond to the MSG_SPEC_GET_VIS_PARENT
		  (for when the object knows it goes somewhere other than its
		  generic parent) or its generic parent should respond to
		  MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD (when the gen parent
		  knows under what visual object its child should be placed).

	If an object must replace this message in whole, it should do the
	following:

	0) If object is already specifically built, just return.  This
	check need NOT be performed for WIN_GROUP objects,
	since they will never be sent a MSG_SPEC_BUILD if they are already
	built.

	1) Visually construct any object(s) necessary to visually implement
	the generic object.  The visual object(s) should be added into the
	visible tree at the desired place.  The routine VisAddChildRelativeToGen
	which adds an object in the visual tree in the same place relative
	to the objects around it in the generic tree,   may prove quite useful 
	in your attempt to do this.

	2) You must invalidate any aspects of the visual objects you have
	added that are not up to date.  In addition, if your changes affect
	the visual parent (such as screwing up its geometry), you should
	invalidate any aspects of it that is wrong as well.  The routine
	VisMarkFullyInvalid may be useful to you.

	4) If you have created visual objects which are in a different
	WIN_GROUP than the generic object being built, you must send the
	visible objects created a MSG_VIS_VUP_UPDATE_WIN_GROUP, to ensure
	that they are updated.  You should pass along the VisUpdateMode
	portion of the VisBuildFlags passed to you, in dl, for this message,
	so that objects on other trees are updated as well, in the manner
	desired by the app writer.

	
Visual vs. Generic trees
------------------------
       
	First, some problems w/Generic -VS- Visual trees.  Basically, 
	they're not the same.  Therein lies the problems.  We have a 
	few basic variations:

		a) A generic object's visible portion may have a different
		visual parent than generic.

		b) "Dual build":  A generic object may have a visible portion
		that is created at a later point, normally visually building
		seperate visual object(s) other than itself (GenInteraction ->
		Button + Menu)  (Visible portion of generic object is
		marked w/ VTF_USES_DUAL_BUILD)


	Mechanisms used to solve these problems:

		1) Creation of MSG_SPEC_GET_VIS_PARENT, which allows an
		instance of a UI object to specify where its WIN_GROUP or
		non-WIN_GROUP portion of its visible implementation 
		generic object should be placed visually.  Or, MSG_SPEC_-
		DETERMINE_VIS_PARENT_FOR_CHILD (called by the default version
		of MSG_SPEC_GET_VIS_PARENT), which the generic parent of a
		UI object can use to return where that object gets placed
		visually.

		NOTE: if the flag VTF_CUSTOM_VIS_PARENT in the visible part of
		the generic object is NOT set, then the object need not respond
		to this message, & those interested should use the generic
		parent by default.  The routine VisGetVisParent handles this.

		2) Creation of MSG_SPEC_GET_SPECIFIC_VIS_OBJECT which will
		retrieve the specifically built top object for any generic object,
		given whether we're interested in the WIN_GROUP implementation
		or non-WIN_GROUP implementation (in order to cover dual-build)
		This does a few different things.  First, it allows us to see
		if the object is specifically built.  Second, it allows us to
		figure out where our generic siblings have attached themselves
		visually, so we can figure out where to add ourselves when
		made suddenly usable.

		NOTE: If the bit VTF_SIMPLE_GEN_OBJ
		in the visible part of the generic object IS set, then the
		object need not respond to this message, & those interested
		may assume that the visible portion of the generic object
		IS the visible object, & that the object is visually built
		if it is in a visual composite.  The routine
		VisGetSpecificVisObject handles this.


	Now, we can talk about top level visible state issues.  Problems
	to solve are:
	
	1) When a menu or dialog box, or even a display, is brought down,
	we want to be able to mark it as not in use, so that the block can
	be "compressed".  The problem is, that visual linkage must be unhooked
	across block boundaries:

			      |	     BLOCK A	  |    BLOCK B
			      |			  |
	                      |   GenInteraction <|> Gen children
		      	      |	   ~	     ~    | ~  ~  ~  ~
	           OLField   <|>   OLMenuWin ~   <|> Vis children
		 -------------|		     ~    |
		   OLDisplay <|>  OLMenuButton	  |
			      |			  |

	2) We want to redo as little as necessary to bring a menu or display
	back up (geometry, vis linkage)

	Visible states that might help to solve these problems (In order
	of a life cycle)

	GENERIC ONLY:
		* A generic branch starts out w/o any visible parts or
		  objects, or in a visible tree.  Block is not marked as in
		  use.
	
	VIS BUILT BUT NOT REALIZED:
		* It is then "SpecBuilt" in which visible master parts, visible
		  & new generic objects are created, & placed in a visual tree.
		* Block is marked as "In Use", since we may have visual links
		  across blocks.

	REALIZED:
		* Windows are realized in specifically built tree, causing the
		  WIN GROUP to be visible
		* Block is marked as "In Use".

	VIS UNBUILT:
		* First unrealized, then visual tree is broken down.  We
		  may keep around the visual parent to make it easier to
		  rebuild later.
		* Created generic & visual objects (within same block)
		  are left intact.  Any objects which should be trashed
		  if the block were discarded now should be marked as not
		  dirty (thinking of created generic objects here...)
		* Geometry values are left intact, with the assumption that
		  objects if brought back up will be placed in the same spot.
		  Wherever this logic is broken, the objects should be marked
		  as invalid.
		* Block is marked as "NOT In Use", since we may have no links
		  across blocks.

	VIS DEATH:
		* Beyond VIS STANDBY, created visual & generic objects are
		  destroyed, which should get us almost to Generic only level

	Life cycle:

	GENERIC ONLY
			VIS BUILT BUT NOT REALIZED
				REALIZED
			VIS BUILT BUT NOT REALIZED
				REALIZED
			VIS BUILT BUT NOT REALIZED
		VIS UNBUILT
			VIS BUILT BUT NOT REALIZED
				REALIZED
		VIS UNBUILT
	VIS DEATH

	Recursive messages that will cause a transition between the states:

	MSG_SPEC_BUILD 		-> VIS BUILT BUT NOT REALIZED
	MSG_VIS_OPEN			-> REALIZED
	MSG_VIS_CLOSE		-> VIS BUILT BUT NOT REALIZED
	MSG_SPEC_UNBUILD		-> VIS UNBUILT

	States for the WIN_GROUP:

		GS_USABLE	- if app says object is usable
		VA_VISIBLE	- if specific UI says object may be visible
		VA_ATTACHED	- normally set, is cleared to force down app
				  when quitting

		When ALL of these bits are set, the object will make the
	transition to REALIZED.  When any are cleared, the object will be
	brought to the UNBUILT stage.

	
POSSIBLE LIFE CYCLE FOR GENERIC TREE:

    GenAddGenChild			; WIN_GROUP added to generic tree
    GenSetUsable			; Set usable by application
	VisUpdateGenWinGroup		; Check for if we want visualizid
	    MSG_SPEC_BUILD_BRANCH	; FIRST, tree is specifically built
	        MSG_SPEC_BUILD	;	Individual object built
	    VisCompVupUpdateWinGroup	; THEN, we invoke a visual update
	    VisCompUpdateWinGroup	; & this reaches the update routine
		MSG_VIS_UPDATE_GEOMETRY	; THEN, geometry is updated
		MSG_VIS_OPEN			; & we realized all the windows.
		    MSG_VIS_OPEN_WIN
    VisCompExposed			; Window sys generates EXPOSURE
	VisCompDraw			; A redraw occurs
	    MSG_VIS_DRAW

    GenSetVisMoniker			; Suddenly, user changes a moniker
	VisCompVupUpdateWinGroup	; which does a visual update
	VisCompUpdateWinGroup		; & this reaches the update routine
		MSG_VIS_UPDATE_GEOMETRY	; THEN, window positions are updated
					; THEN, window positions & screen images
					; are updated
		MSG_VIS_UPDATE_WINDOWS_AND_IMAGE

    VisCompExposed			; Window sys generates EXPOSURE
	VisCompDraw			; A redraw occurs
	    MSG_VIS_DRAW
					; ...

    GenSetNotUsable			; App marks WIN_GROUP as not usable
	VisCompVupUpdateWinGroup	; which invokes a visual update
	VisCompUpdateWinGroup		; & this reaches the update routine
	    VisCompClose		; visual closure of tree occurs
		MSG_VIS_CLOSE	; 	ALL objects in tree are notified
		    MSG_VIS_CLOSE_WIN	; 	Individual windows are closed

    GenRemoveGenChild			; WIN_GROUP is removed from generic
					;	tree.

------------------------------------------------------------------------------@


idata	segment
	
    method VisCallParentEnsureStack, VisClass, MSG_SPEC_NAVIGATE_TO_NEXT_FIELD
    method VisCallParentEnsureStack, VisClass, MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD
    method VisCallParentEnsureStack, VisClass, MSG_SPEC_ACTIVATE_INTERACTION_DEFAULT
    method VisGotoParentTailRecurse, VisClass, MSG_SPEC_UPDATE_MENU_SEPARATORS
    method VisGotoParentTailRecurse, VisClass, MSG_SPEC_VUP_GET_WIN_SIZE_INFO

    method VisCallParentEnsureStack, VisClass, MSG_GEN_MAKE_APPLYABLE	
    method VisCallParentEnsureStack, VisClass, MSG_GEN_MAKE_NOT_APPLYABLE	

    method GenCallParentEnsureStack, VisClass, MSG_SPEC_GUP_QUERY


idata	ends

Build	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisSpecBuild -- MSG_SPEC_BUILD for VisClass

DESCRIPTION:	Default visual build message for Generic objects having
		a visible part.  VTF_IS_GEN must be set, or this routine
		will do nothing.

		MAY be used in cases where:

		* Generic object becomes sole visible object.
		  (SA_SIMPLE_GEN_OBJ must be set)  NOTE that objects
		  that visually appear as different objects that their
		  generic object (dual build menus, a GenText in a View)
		  must respond to the MSG_SPEC_GET_SPECIFIC_VIS_OBJECT so that
		  THIS routine can place new objects created & added between
		  the correct visual children.

		* Generic object has NOT set SA_USES_DUAL_BUILD

		* Object is to be placed visually on its generic parent,
		  or, if not, then SA_CUSTOM_VIS_PARENT must be set, & 
		  object must respond to the MSG_GEN_GET_VIS_PARENT.

	If an object must replace this message in whole, it should do the
	following:

	0) If object is already specifically built, just return.  This
	check need NOT be performed for the WIN_GROUP portion of 
	a WIN_GROUP object, since they will never be sent a
	MSG_SPEC_BUILD for the WIN_GROUP portion if is already built.


	1) Visually construct any object(s) necessary to visually implement
	the generic object.  The visual object(s) should be added into the
	visible tree at the desired place.  The routine VisAddChildRelativeToGen
	may prove quite useful in your attempt to do this.

	2) You must invalidate any aspects of the visual objects you have
	added that are not up to date.  In addition, if your changes affect
	the visual parent (such as screwing up its geometry), you should
	invalidate any aspects of it that is wrong as well.  The routine
	VisMarkFullyInvalid may be useful to you.

	3) If you have created visual objects which are in a different
	WIN_GROUP than the generic object being built, you must send the
	visible objects created a MSG_VIS_VUP_UPDATE_WIN_GROUP, to ensure
	that they are updated.  The field SBF_UPDATE_MODE passed in the 
	SpecBuildFlags indicates how this update should be done.

	4) If the generic portion of this object has a moniker handle,
	see if the moniker is actually a list of monikers. If so, choose
	the most appropriate moniker from the list and replace the list chunk
	with that single moniker. (use VisFindMoniker or GenFindMoniker)

PASS:
	*ds:si - instance data (vis part indirect through offset Vis_offset)
	es - segment of VisClass

	bp - SpecBuildFlags

	ax, bx	-- DON'T CARE (may safely be called using CallMod)


RETURN:
	ds - updated to point at segment of same block as on entry
	ax, cx, dx, bp - destroyed

DESTROYED:
	none (can be called via static binding)
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Doug	9/89		Revised to solve object on different vis tree
				than generic, etc.

------------------------------------------------------------------------------@


VisSpecBuild	method	static VisClass, MSG_SPEC_BUILD 	uses bx, si, di
	.enter

	Destroy	ax, bx			; test CallMod tolerance

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	LONG	jz VVB_Done

EC <					; Make sure IN generic composite   >
EC <					; (Default message requires it)    >
EC <	mov	bx, ds:[si]						>
EC <	add	bx, ds:[bx].Gen_offset					>
EC <	tst	ds:[bx].GI_link.LP_next.handle				>
EC <	ERROR_Z		UI_SPEC_BUILD_NOT_IN_GENERIC_TREE		>
EC <									>
EC <					; Make sure object DOESN'T	>
EC <					; require dual build, since this   >
EC <					; default message can't handle it. >
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	test	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD		>
EC <	ERROR_NZ	UI_SPEC_BUILD_DEFAULT_MSG_CANNOT_HANDLE_DUAL_BUILD >
EC <									>

	call	VisCheckIfSpecBuilt	; Make sure NOT vis built yet. Note
					; that we CAN do this check without
					; using VisGetSpecificVisObject, 
					; since the header specifically says
					; that this routine will only work
					; w/generic objects which are also
					; the visible object to be built.
	jc	VVB_Done		; if it is, quit.


	; VISUALLY BUILD this object.

EC <	mov	di, UI_MAXIMUM_THREAD_BORROW_STACK_SPACE_AMOUNT		>
EC <	call	ThreadBorrowStackSpace					>
EC <	push	di							>
	
					; set state based on SpecBuildFlags and
	call	VisSpecBuildSetEnabledState
					; GS_ENABLED
   
   
					; ASSUME that gen object will be
					; visual object when built.
	call	VisGetVisParent		; Fetch visible parent to use

EC <	tst	cx			; if no parent, quit		>
EC <	ERROR_Z	UI_SPEC_BUILD_NO_VIS_PARENT				>
EC <	push	bx							>
EC <	push	cx							>
EC <	push	dx							>
EC <	push	si							>
EC <	mov	bx, cx							>
EC <	mov	si, dx							>
EC <	call	ObjLockObjBlock		; lock the block		>
EC <	push	ds							>
EC <	mov	ds, ax							>
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <					; if parent is win group,	>
EC <					; OK if not built (FOR NOW)	>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP		>
EC <	jnz	VVB_e30							>
EC <	call	VisCheckIfSpecBuilt	; see if visually built		>
EC <	ERROR_NC	UI_VIS_PARENT_NOT_BUILT				>
EC <VVB_e30:								>
EC <	pop	ds							>
EC <	call	MemUnlock		; unlock block in any case	>
EC <	pop	si							>
EC <	pop	dx							>
EC <	pop	cx							>
EC <	pop	bx							>

					; *ds:si is generic object
	mov	ax, ds:[LMBH_handle]	; ^lax:bx is visual object (same)
	mov	bx, si
					; Call routine to add object
	call	VisAddChildRelativeToGen

	;now search this object's VisMonikerList for the moniker
	;which matches the DisplayType for this application, and replace
	;the list with that moniker.

	push	bp
	mov	bp, mask VMSF_REPLACE_LIST or mask VMSF_GSTRING \
		    or (VMS_ICON shl offset VMSF_STYLE)
					;return non-textual GString if any,
					;otherwise GString, otherwise
					;non-abbreviated text string.
	clc				;flag: use this object's list
	call	GenFindMoniker		;trashes ax, di, es,
					;may move ds segment
	pop	bp

EC <	pop	di							>
EC <	call	ThreadReturnStackSpace					>

	;
	; Check for position hints.  If there aren't any, we're done.  Otherwise
	; we'll mark this object as needing a NOTIFY_GEOMETRY_VALID so we can
	; always set the size then.
	;
	call	VisSpecCheckForPosHints
	jnc	VVB_Done		

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].VI_geoAttrs, mask VGA_NOTIFY_GEOMETRY_VALID
VVB_Done:
	.leave
	Destroy	ax, cx, dx, bp
	ret

VisSpecBuild	endm

		

COMMENT @----------------------------------------------------------------------

FUNCTION:	VisGetVisParent

DESCRIPTION:	Determine visual parent to use for visually building an object.
		If optimization flag is set for visual parent being generic
		parent, then the generic parent is returned without bothering
		to send out a message to figure out what to use.  If not,
		then the message is sent, to the same object, assuming that
		a subclass will respond with the correct visual parent to use.

CALLED BY:	EXTERNAL
		VisSpecBuild

PASS:
	*ds:si	- Generic object to get vis parent for
	bp	- SpecBuildFlags

RETURN:
	cx:dx	- visual object
	bp	- SpecBuildFlags	- If visible parent is within same WIN_GROUP
				  as object, this bit MAY be set, to speed
				  build up:
		  mask SBF_VIS_PARENT_WITHIN_SCOPE_OF_TREE_BUILD
	ds - updated to point at segment of same block as on entry

DESTROYED:
	Nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version
------------------------------------------------------------------------------@

VisGetVisParent	proc	far	uses ax, bx, di
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

	.enter

EC <	call	VisCheckVisAssumption				>

	push	bx
	push	si
	call	GenFindParent		; makes ^lbx:si = parent
	mov	cx, bx			; move to have ^lcx:dx = parent
	mov	dx, si
	pop	si
	pop	bx
					; If uses generic parent for vis,
					; just fetch Gen parent & return.
					

	mov	di, ds:[si]		
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_specAttrs, mask SA_CUSTOM_VIS_PARENT
	jz	CheckGenParent

;UseQuery:
	pushdw	cxdx			; save gen parent
	mov	ax, MSG_SPEC_GET_VIS_PARENT
	call	ObjCallInstanceNoLock
	popdw	axbx			; get gen parent in ^lax:bx
					; If responded to, branch, test for
					;	optimization
	jc	SeeIfGenParentIsVisParent
	movdw	cxdx, axbx		; Else use gen parent by default

CheckGenParent:
	;
	; If the object doesn't know where to go, the parent might.
	;
	test	bp, mask SBF_WIN_GROUP
	jnz	GenParentIsVisParent		;win group part, won't check out
						;  parent, (somewhat arbitrary)
	push	si
	call	GenSwapLockParent
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_specAttrs, mask SA_CUSTOM_VIS_PARENT_FOR_CHILD
	call	ObjSwapUnlock
	pop	si
	jz	GenParentIsVisParent

	pushdw	cxdx				; save gen parent
	mov	cx, ds:[LMBH_handle]		;pass ourselves
	mov	dx, si
	mov	ax, MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD
	call	GenCallParent			;and get from view
	popdw	axbx			; get gen parent in ^lax:bx
	jc	SeeIfGenParentIsVisParent
					; If responded to, branch, test for
					;	optimization
	movdw	cxdx, axbx		; ^lcx:dx <- gen parent

SeeIfGenParentIsVisParent:
	cmp	ax, cx
	jne	Done
	cmp	bx, dx
	jne	Done
					; If match, then set optimization flag
GenParentIsVisParent:
					; See if this object is a win group
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	Done			; if so, not adding within win group
					; Adding within win group
	or	bp, mask SBF_VIS_PARENT_WITHIN_SCOPE_OF_TREE_BUILD
Done:
	.leave
	ret

VisGetVisParent	endp



COMMENT @----------------------------------------------------------------------

METHOD:		VisUnbuild -- MSG_SPEC_UNBUILD for VisClass

DESCRIPTION:	Default visual unbuild message for Generic objects having
		a visible part.  VTF_IS_GEN must be set, or this routine
		will do nothing.

		MAY be used in cases where:

			VisGetSpecificVisObject	returns the correct visible
			object, which need only be visibly removed from
			its parent, & not destroyed.


	If an object must replace this message in whole, it should do the
	following:

	0) If object is already visibly unbuilt, just return.  This
	check need NOT be performed for the WIN_GROUP portion of 
	a WIN_GROUP object, since they will never be sent a
	MSG_SPEC_UNBUILD for the WIN_GROUP portion if is already unbuilt.

	1) Visually unconstruct any visual object(s) that have been created
	for the object (if a WIN_GROUP, then only the WIN_GROUP or
	non-WIN_GROUP portion as is specified.  This is typically done by
	just using MSG_VIS_REMOVE_CHILD, plus the removal of any created
	objects.

	2) You must invalidate any aspects of the visual objects left after
	the removal that are not up to date.  In addition, if your changes
	affect the visual parent (such as screwing up its geometry), you should
	invalidate any aspects of it that is wrong as well.

	3) If you have created visual objects which are in a different
	WIN_GROUP than the generic object being built, you must send the
	visible objects created a MSG_VIS_VUP_UPDATE_WIN_GROUP, to ensure
	that they are updated.  The field SBF_UPDATE_MODE passed in the 
	SpecBuildFlags indicates how this update should be done.

PASS:
	*ds:si - instance data (vis part indirect through offset Vis_offset)
	es - segment of VisClass
	ax - MSG_SPEC_UNBUILD
	
	bp - SpecBuildFlags

RETURN:
	nothing
	ax, cx, dx, bp - destroyed

DESTROYED:
	none (can be called via static binding)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

VisSpecUnbuild	method	dynamic VisClass, MSG_SPEC_UNBUILD
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
					; Handle separately if not a
					; generic object
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	UnbuildVisObject

	push	bp
	call	VisGetSpecificVisObject	; get visual object to remove
	pop	bp
	tst	cx			; if doesn't exist, done
	jz	Done			; else skip & close down

	push	si
	mov	bx, cx			; setup ^lbx:si as visible object
	mov	si, dx
	mov	dx, bp			; Get copy of update mode in dx

	call	ObjSwapLock		; *ds:si is visible object to unbuild

	call	VisRemove		; Call primitive routine to unbuild
					; 	this visual object
	call	ObjSwapUnlock		; restore *ds:si to be gen object
	pop	si

Done:
EC <	call	VisCheckOptFlags					>
	ret

UnbuildVisObject:
;	mov	dl, VUM_MANUAL		; update will happen at top node
	mov	dx, bp			; use update mode passed
	call	VisRemove		; For a plain visible object, just
					; close down & remove from vis tree.
	Destroy	ax, cx, dx, bp
	ret

VisSpecUnbuild	endm






COMMENT @----------------------------------------------------------------------

METHOD:		VisSpecSetUsable

DESCRIPTION:	Make visual changes necessary when an object is suddenly
		GS_USABLE.  For objects with dual build, do both parts.

PASS:
	*ds:si - instance data
	es - segment of VisClass
	ax - MSG_SPEC_SET_USABLE

	dl - VisUpdateMode

RETURN:
	nothing
	ax, cx, dx, bp - destroyed
	
DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@


VisSpecSetUsable	method	dynamic VisClass, MSG_SPEC_SET_USABLE
		
EC <	; Make sure that instance data is not hosed			>
EC <	call	ECCheckVisFlags						>
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>
EC <	call	VisCheckOptFlags					>

					; See if we're dealing with a win
					;	group here.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN			>
EC <	ERROR_Z	UI_EXPECTED_VIS_TYPE_VTF_IS_GEN				>

	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	HasWinGroup

;NoWinGroup:
	call	VisSetNonWinGroupUsable

EC <	call	VisCheckOptFlags					>
	Destroy	ax, cx, dx, bp
	ret


HasWinGroup:
					; If a WIN_GROUP marked as built but
					; not realized, then we need to nuke
					; the upward-only link, to make sure
					; that the object is placed on the
					; correct visible parent (can't use
					; any left-over value from when
					; set NOT_USABLE)
	test	ds:[di].VI_specAttrs, mask SA_TREE_BUILT_BUT_NOT_REALIZED
	jz	AfterBuiltFix
	and	ds:[di].VI_specAttrs, not mask SA_TREE_BUILT_BUT_NOT_REALIZED
					; Nuke the stored vis parent.
	clr	ax
	mov	ds:[di].VI_link.LP_next.handle, ax
	mov	ds:[di].VI_link.LP_next.chunk, ax
AfterBuiltFix:

					; But if one of these funny suckers,
					; need to do both parts
	test	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD
	jz	VMU_AfterNonWinGroup
					; Do non-WIN_GROUP part.
	call	VisSetNonWinGroupUsable

VMU_AfterNonWinGroup:
					; Do WIN_GROUP part
	push	dx				; save update mode
	call	QuickGenAppGetStateFar		; ax = ApplicationStates
	mov	cx, 0				; UpdateWindowFlags
	test	ax, mask AS_ATTACHING
	jz	haveAttachUWF
	ornf	cx, mask UWF_ATTACHING
haveAttachUWF:
	test	ax, mask AS_DETACHING
	jz	haveDetachUWF
	ornf	cx, mask UWF_DETACHING
haveDetachUWF:
	pop	dx				; dl = update mode
	call	VisCompUpdateWindow

	ret

VisSpecSetUsable	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	VisSetNonWinGroupUsable

DESCRIPTION:	Make visual changes necessary for non-WIN_GROUP portions
		of generic objects when they become GS_USABLE.

CALLED BY:	INTERNAL
		VisSetUsable

PASS:
	*ds:si - instance data

	dl - VisUpdateMode

RETURN:
	nothing
	
DESTROYED:
	ax, bx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@


VisSetNonWinGroupUsable	proc	near
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

	push	dx
	push	si

; IF our visible-parent-to-be is not VIS_BUILT, then we don't want to
; be either.  If it IS, we want to be, as well.
;
	push	dx			; PRESERVE update mode
	push	si			; & object chunk

	; Fetch the visual parent that this object should be attached to.

	clr	bp			; clear BuildFlags, not doing WIN_GROUP
	call	VisGetVisParent
	tst	cx			; IF NO PARENT,
	LONG	jz	VSNWGU_popQuit	; then quit out-doesn't need building

	; If the visual parent is built, then go ahead & build this one.
	mov	bx, cx
	mov	si, dx
	call	ObjSwapLock		; setup *ds:si as object

	call	VisCheckIfSpecBuilt	; see if visually built
	pushf				; preserve flags returned

	; FOR now, just get attributes (will change w/spec build/linkage
	; changes  (Changed to check GS_USABLE flag rather than VA_REALIZED
	; to decide whether to update this thing, to attempt to handle more
	; cases of an object getting set usable right before its parent is
	; opened.  -cbh 2/12/93)

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	al, ds:[di].VI_attrs	; get attributes

	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	5$			; not generic, branch
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jz	5$
	or	al, mask VA_REALIZED	; usable, treat as realized.
5$:

	popf
	call	ObjSwapUnlock		; restore our old object
	pop	si			; fetch chunk handle of object
	pop	dx			; RESTORE update mode

					; Carry set if parent is vis built
	jnc	VSNWGU_quit		; if parent not built, then we don't
					; need to build yet.

	; VISUALLY BUILD JUST NEW ADDED OBJECT

	push	ax
	push	dx			; preserve update mode
	clr	bp			; default flags to pass UPDATE_SPEC_BUILD
	clr	dh			; null out top byte for OR
	or	bp, dx			; set update flags

	clr	cx			; Allow optimized check.  Will not
					; look at this object because is not
					; yet specifically built, which is
					; good, because the FULLY_ENABLED bit
					; isn't set for it yet.  On the other
					; hand, the optimization saves time
					; by stopping at the first specifically
					; built object & grabbing its 
					; FULLY_ENABLED flag.
	call	GenCheckIfFullyEnabled	; see if fully enabled
	jnc	10$			; no, branch
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
10$:
	mov 	ax, MSG_SPEC_BUILD_BRANCH
	call	ObjCallInstanceNoLock	; Visibly build the new branch

	; NOW, get visible object that has been built, & update it.
	clr	bp			; not top
	call	VisGetSpecificVisObject	; get visual object to remove, in
					; 	cx:dx
	mov	bx, cx			; move to bx:si
	mov	si, dx
	pop	dx			; get update mode
	pop	ax

; THIS should not have to be done here, as the MSG_SPEC_BUILD handler
; is supposed to do this, if it is necessary.	- Doug 1/90
; (I think this is wrong, nothing sets geometry invalid for a new object
;  except for its initial invalid flags.  I think we've been getting lucky
;  that things work, and I need for geometry to start at the parent level
;  here rather than at the child.  -cbh 11/ 1/91)
;
	tst	si			; no object for some reason, exit
	jz	VSNWGU_quit		;    (cbh 11/18/91)
	
	push	dx, ax			; set the geometry invalid on parent
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_MANUAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_MARK_INVALID
	
	push	bx, si
	mov	bx, segment VisClass
	mov	si, offset VisClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	bx, si
	
	mov	cx, di
	mov	ax, MSG_VIS_CALL_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx, ax
	
	test	al, mask VA_REALIZED	; is parent realized?
	jz	VSNWGU_quit		; if not, we won't be, don't update.


					; Update the display that the object
					; is on.  Mark window as invalid to
					; make sure that a VIS_OPEN is done
					; on the branch.
	mov	cl, mask VOF_WINDOW_INVALID
	mov	ax, MSG_VIS_MARK_INVALID
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

VSNWGU_quit:
	pop	si
	pop	dx
	ret

VSNWGU_popQuit:
	pop	si
	pop	dx
	jmp	VSNWGU_quit

VisSetNonWinGroupUsable	endp




COMMENT @----------------------------------------------------------------------

METHOD:		VisSpecSetNotUsable

DESCRIPTION:	Make visual changes necessary when an object is suddenly
		no longer GS_USABLE.  Sends MSG_SPEC_SET_NOT_USABLE
		recursively down to ALL generic children marked as
		USABLE which are specifically grown, & visible shuts down
		and unbuilds at each level.

PASS:
	*ds:si - instance data
	es - segment of VisClass
	ax - MSG_SPEC_SET_NOT_USABLE

	dl - VisUpdateMode

RETURN:
	nothing
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@


VisSpecSetNotUsable	method	dynamic VisClass, MSG_SPEC_SET_NOT_USABLE
EC <	; Make sure that instance data is not hosed			>
EC <	call	ECCheckVisFlags						>
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>
EC <	call	VisCheckOptFlags					>

					; See if we're dealing with a win
					;	group here.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN			>
EC <	ERROR_Z	UI_EXPECTED_VIS_TYPE_VTF_IS_GEN				>
   
					; Finally, Visibly unbuild this
					; entire generic branch
	mov	ax, MSG_SPEC_UNBUILD_BRANCH
	clr	dh
	mov	bp, dx			; Copy VisUpdateMode to SpecBuildFlags
	GOTO	ObjCallInstanceNoLock

VisSpecSetNotUsable	endm


Build	ends

;
;---------------
;
		
VisUpdate	segment	resource
		


COMMENT @----------------------------------------------------------------------

METHOD:		VisSpecUpdateVisual

DESCRIPTION:	Default message to Visibly update a generic object.  
	This default message CAN NOT handle dual build cases, nor can it
	invalidate any visible objects from with the generic portion
	is not subclassed.  The SPECIFIC UI should replace this message to
	handle those cases.  The idea is to simply run the visual update
	code on each visual pieced generated from this generic object.

PASS:
	*ds:si - instance data
	es - segment of VisClass
	ax - MSG_SPEC_UPDATE_VISUAL

	dl - VisUpdateMode

RETURN:
	nothing
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@

VisSpecUpdateVisual	method	dynamic VisClass, MSG_SPEC_UPDATE_VISUAL
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>
EC <	call	VisCheckOptFlags					>
EC <					; Make sure object DOESN'T	>
EC <					; require dual build, since this >
EC <					; default message can't handle it.>
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN			>
EC <	ERROR_Z	UI_EXPECTED_VIS_TYPE_VTF_IS_GEN				>
EC <	test	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD		>
EC <	ERROR_NZ UI_SPEC_BUILD_BRANCH_DEFAULT_MSG_CANNOT_HANDLE_DUAL_BUILD >

					; Do visual update for simple object
;	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
;	call	ObjCallInstanceNoLock
	call	VisVupUpdateWinGroup	; call statically
	Destroy	ax, cx, dx, bp
	ret

VisSpecUpdateVisual	endm

VisUpdate	ends
;
;-------------------
;
VisOpenClose	segment resource
		

COMMENT @----------------------------------------------------------------------

METHOD:		VisSpecSetAttrs

DESCRIPTION:	Change specific flags stored in visible instance data for
		specific objects.

PASS:
	*ds:si - instance data (vis part indirect through offset Vis_offset)
	es - segment of VisClass

	ax 	- MSG_SPEC_SET_ATTRS
	cl 	- bits to set
	ch 	- bits to reset

	      The bits which may be changed:
			SA_ATTACHED
			SA_REALIZABLE
			SA_BRANCH_MINIMIZED
 		  
	dl 	- VisUpdateMode -  To be used for bringing up window,
		  or updating visible WIN_GROUPs OTHER than this
		  one which have objects removed from them as a result
		  of this window coming down.  If window is brought
		  down, it is always done immediately, so that the
		  branch may be visibly unlinked immediately.

	
RETURN:
	cx, dx, bp - preserved
	ax destroyed

DESTROYED:
	ax, bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
        If we never add any more attr bits, this could be simplified slightly.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/89		Initial version

------------------------------------------------------------------------------@

VisSpecSetAttrs	method	dynamic VisClass, MSG_SPEC_SET_ATTRS
			
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>

EC <	test	cl, not SpecAttrs					>
EC <	ERROR_NZ	UI_BAD_SET_SPEC_ATTR_FLAGS			>
EC <	test	ch, not SpecAttrs					>
EC <	ERROR_NZ	UI_BAD_SET_SPEC_ATTR_FLAGS			>

	push	cx
	mov	di, ds:[si]	       		; Point to instance data
	add	di, ds:[di].Vis_offset
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN			>
EC <	ERROR_Z	UI_EXPECTED_VIS_TYPE_VTF_IS_GEN				>

	mov	al, ds:[di].VI_specAttrs		; get OLD bits

	or	ds:[di].VI_specAttrs, cl		; SET bits
	not	ch				; get AND mask
	and	ds:[di].VI_specAttrs, ch		; RESET bits

	xor	al, ds:[di].VI_specAttrs		; get CHANGED bits

	test	al, mask SA_BRANCH_MINIMIZED	; change in branch minimization?
	pushf						; save result

	push	dx				; save VisUpdateMode
	call	QuickGenAppGetState		; ax = ApplicationStates
						; (better preserve dx!)
	mov	cx, 0				; UpdateWindowFlags
	test	ax, mask AS_DETACHING
	jz	haveDetachUWF
	ornf	cx, mask UWF_DETACHING
haveDetachUWF:
	test	ax, mask AS_ATTACHING
	jz	haveAttachUWF
	ornf	cx, mask UWF_ATTACHING
haveAttachUWF:
	pop	dx				; restore VisUpdateMode

	popf				; restore branch minimization change
	jz	VSSA_80			; skip if not

	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di

					; OTHERWISE, notify anyone in
					; window list.
					; Pass message requesting update
					; of any generic WIN_GROUP's
	push	dx				; save VisUpdateMode
	push	si				; save object
	clr	bx				; message for all entries
	clr	si
	mov	ax, MSG_META_UPDATE_WINDOW
					; Send this message to anything on
					; the window list.  This object having
					; the BRANCH_MINIMZED flag changed
					; may change the visibility of
					; some objects on the active list.
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	pop	si				; *ds:si = object
	push	cx				; save UpdateWindowFlags
	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_WINDOWS
	mov	ss:[bp].GCNLMP_block, 0
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, 0
	mov	ax, MSG_META_GCN_LIST_SEND
	push	si
	call	GeodeGetAppObject		; ^lbx:si = app object
	tst	bx				; any?
	jz	noAppObj
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
noAppObj:
	pop	si
	add	sp, size GCNListMessageParams
	pop	cx				; cx = UpdateWindowFlags
	pop	dx				; dl = VisUpdateMode`

	pop	di
	call	ThreadReturnStackSpace

VSSA_80:
	; cx = UpdateWindowFlags
	; dl = VisUpdateMode
						; Do update of generic 
						; 	WIN_GROUP
	call	VisCompUpdateWindow
	pop	cx
	Destroy	ax
	ret

VisSpecSetAttrs	endm

			
VisOpenClose	ends

;
;---------------
;
		
Build	segment	resource
			

COMMENT @----------------------------------------------------------------------

METHOD:		VisSpecBuildBranch -- MSG_SPEC_BUILD_BRANCH for VisClass

DESCRIPTION:	Default handler for Generic objects having visible parts
		to visibly build this object if it needs it,
		and to call all non-GROUP_WIN children, to get them build, too.
		VTF_IS_GEN must be set, or this routine will do nothing.

PASS:
	*ds:si - instance data
	es - segment of VisClass
	ax - MSG_SPEC_BUILD_BRANCH
	bp - SpecBuildFlags

RETURN:
	nothing
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@


VisSpecBuildBranch	method	dynamic VisClass, MSG_SPEC_BUILD_BRANCH
			
EC <	; Make sure that instance data is not hosed			>
EC <	call	ECCheckVisFlags						>
					; Quit if not a generic object.
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	done

	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di

	; It is possible that in the course of getting here the actions of
	; our subclass have made us enabled where before we were not enabled
	; Check for this case.

	and	bp, not mask SBF_VIS_PARENT_FULLY_ENABLED
	mov	cx, 1			; Cannot optimize here
	call	GenCheckIfFullyEnabled	; see if fully enabled
	jnc	5$			; no, branch
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
5$:

					; If doing WIN_GROUP, then we
					; can rely on fact that gen object
					; = vis object, & easily test to
					; see if the WIN_GROUP is already
					; specifically built or not, just 
					; using VisCheckIfSpecBuilt.
					;
					; If NOT doing a WIN_GROUP, we
					; can make this optimization, since
					; we don't know what object is
					; visually representing the gen object.
					; Instead of wasting time here,
					; objects should check for themselves
					; to see if they are already vis
					; built before undertaking visual
					; construction.
	test	bp, mask SBF_WIN_GROUP
	jz	visBuildNode

	call	VisCheckIfSpecBuilt	; check to see if this object
					; is already visually built
	jc	afterBuilt		; if so, skip build here


visBuildNode:
	
	; Make sure the fully-enabled bit is clear if this object is not
	; enabled.
	
	mov	di, ds:[si]		
	add	di, ds:[di].Gen_offset	
	test	ds:[di].GI_states, mask GS_ENABLED
	jnz	10$			; This object's enabled, branch
	and	bp, not mask SBF_VIS_PARENT_FULLY_ENABLED
10$:	

	; VISUALLY BUILD this object (pass flag in bp)
	push	bp
	mov	ax, MSG_SPEC_BUILD
	call	ObjCallInstanceNoLock
	pop	bp

afterBuilt:
					; If we've just specifically built
					; the top object in a win group,
					; then go on to do children
	test	bp, mask SBF_WIN_GROUP
	jnz	buildChildren

					; Otherwise, see if we should
					; send on down to children or not:

; Let's remove this comment & test below if this fatal error is never hit.
; I don't know why the code was in here, as the case should never happen.
;
; Old comment				; If object doesn't have a visible
; Old comment				; part, then we can't make any
; Old comment				; assumptions.  Go
; Old comment				; on to do generic children.
;
EC <	call	VisCheckIfVisGrown					>
EC <					; This should never happen	>
EC <	ERROR_NC	UI_VIS_UPDATE_SPEC_BUILD_BUT_VIS_NOT_GROWN	>

					; The test is this:  Is it a dual
					; build object?  If so, we're just
					; building the non-win group part,
					; so we can quit here.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD
	jnz	afterChildren

buildChildren:
	; Send on down through children
	;
	mov	ax, MSG_SPEC_BUILD_BRANCH
	and	bp, not mask SBF_WIN_GROUP	; not top object
	or	bp, mask SBF_TREE_BUILD		; but doing tree build.
	clr	dl				; to ALL children
	call   VisIfFlagSetCallGenChildren

afterChildren:

	pop	di
	call	ThreadReturnStackSpace

done:
	Destroy	ax, cx, dx, bp
	ret

VisSpecBuildBranch	endm




COMMENT @----------------------------------------------------------------------

METHOD:		VisSpecUnbuildBranch -- MSG_SPEC_UNBUILD_BRANCH for VisClass

DESCRIPTION:	Default handler for generic objects to unbuild the visible
		tree.  This message may be passed to visible-only branch as
		well, in which case the branch will be made non-visible &
		destroyed.   The generic branch must be not-usable before
		this routine may be called.

		PLEASE note that this message WILL traverse generic objects
		which are USABLE, have been specifically grown, but are
		NOT specifically built.  This is because it is possible that they
		have a child somewhere below which HAS been specifically built at
		some time, & we need to unbuild that object now.  (i.e. no
		optimizations regarding children allowed here if object
		already visibly unbuilt)

PASS:
	*ds:si - instance data
	es - segment of VisClass
	ax - MSG_SPEC_UNBUILD_BRANCH
	
	bp	- SpecBuildFlags
			SBF_WIN_GROUP not used
		        SBF_VIS_PARENT_UNBUILDING valid here

RETURN:
	nothing
	ax, cx, dx, bp - destroyed

DESTROYED:
	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


VisSpecUnbuildBranch	method	dynamic VisClass, MSG_SPEC_UNBUILD_BRANCH

	mov	bx, di
	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di
	mov	di, bx
					; Handle separately if not a
					; generic object
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	LONG	jz	UpdateUnbuildVisObject

EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	; don't do check if forced to unbuild dynamically		>
EC <	test	bp, mask SBF_VIS_PARENT_UNBUILDING			>
EC <	jnz	afterUsableCheck					>
EC <	push	cx							>
EC <	mov	cx, -1		; no optimized check			>
EC <	call	GenCheckIfFullyUsable					>
EC <	pop	cx							>
EC <	ERROR_C	UI_GENERIC_BRANCH_MUST_BE_NOT_USABLE_BEFORE_VISIBLY_UNGROWN >
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <afterUsableCheck:							>

	; First, make sure that object is visibly closed, i.e. NOT REALIZED.
	;
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	unrealizeWinGroup

;unrealizeNonWinGroup:
	call	VisSetNotRealized	; Visibly close any non-win group
					; visible branch which the specific
					; UI has set up in the visible
					; portion of this object. (IF it is
					; still REALIZED.) This is
					; for aesthetic reasons only, as 
					; the VIS_UNBUILD sent later will
					; do the same thing, PLUS visibly 
					; unbuild the object -- we want the
					; entire group to come down visually
					; at once, instead of from each leaf
					; upwards.  Note that this may not have
					; any effect, if the specific
					; implementation has visible objects
					; BESIDES this one on screen to 
					; represent the generic object.  This
					; is a better solution that the 
					; previous "unbuild this object, then
					; children", for that route resulted
					; in problems because the visible
					; linkage was chopped off before visibly
					; closing object (thereby killing
					; VUP queries)
	jmp	short afterUnrealized

unrealizeWinGroup:
	push	bp
	mov	dx, bp			; Pass VisUpdateMode in dx
	call	QuickGenAppGetStateFar		; ax = ApplicationStates
						; (better preserve dx!)
	mov	cx, 0				; UpdateWindowFlags
	test	ax, mask AS_DETACHING
	jz	haveUWF
	ornf	cx, mask UWF_DETACHING
haveUWF:
	call	VisCompUpdateWindow	; bring down visually
	pop	bp
					; Should no longer be visible
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	test	ds:[di].VI_attrs, mask VA_VISIBLE			>
EC <	ERROR_NZ	UI_STILL_VISIBLE_AFTER_VIS_UNBUILD		>
afterUnrealized:


	; NEXT, visibly unbuild the children, before visibly unbuilding THIS
	; object.  This is an attempt to do things in the reverse order of
	; the SPEC_BUILD, so that the visible linkage is destroyed from the
	; bottom up.

	call	VisUnbuildChildren	; Send on down through children

	; FINALLY, visibly unbuild this object itself.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jz	NonWinGroup		; branch if does NOT have a WIN_GROUP
					; If dual build
	test	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD
	jz	AfterNonWinGroupPart
					; OK, we're a generic object w/
					; dual-build.  Normally, we should
					; proceed to unbuild both non-win-group
					; & win-group parts.  If
					; SBF_VIS_PARENT_UNBUILDING is set,
					; however, we'll unbuild the win-group
					; only.  WHY?  Because the above flag
					; is only sent to visible children
					; of generic objects that have already
					; been BRANCH_SPEC_UNBUILDed.  Since
					; the visible parent of a dual-build
					; object is the vis parent of the win-
					; group portion,  it is the 
					; win-group portion that needs to
					; be unbuilt.  The button portion
					; may or may not have been sent a
					; similar message, but visible button
					; objects are not dual build, & at
					; least currently, not generic, so
					; that case would never end up at
					; this point in the code.  QED unbuild
					; win-group only.
					; 
	test	bp, mask SBF_VIS_PARENT_UNBUILDING
	jnz	AfterNonWinGroupPart

	; VISUALLY UNBUILD non-win group
	push	bp
	and	bp, not (mask SBF_WIN_GROUP)
	mov	ax, MSG_SPEC_UNBUILD
	call	ObjCallInstanceNoLock
	pop	bp

AfterNonWinGroupPart:
	; VISUALLY UNBUILD win group
	push	bp
	or	bp, mask SBF_WIN_GROUP
	mov	ax, MSG_SPEC_UNBUILD
	call	ObjCallInstanceNoLock
	pop	bp
	jmp	short AfterUnbuild

NonWinGroup:
	; VISUALLY UNBUILD non-win group
	push	bp
	and	bp, not (mask SBF_WIN_GROUP)
	mov	ax, MSG_SPEC_UNBUILD
	call	ObjCallInstanceNoLock
	pop	bp

AfterUnbuild:
					; Make sure this object no longer
					; is referenced anywhere. (particularly
					; the flow object grabs)

EC <	push	ax, cx, dx, bp						>
EC <	mov	cx, ds:[LMBH_handle]					>
EC <	mov	dx, si							>
EC <	mov	ax, MSG_VIS_VUP_EC_ENSURE_OD_NOT_REFERENCED		>
EC <	call	ObjCallInstanceNoLock					>
EC <	pop	ax, cx, dx, bp						>

done:

	pop	di
	call	ThreadReturnStackSpace

	Destroy	ax, cx, dx, bp
	ret


UpdateUnbuildVisObject:

;
;	We want to unbuild the visible children, not just destroy them.
;	atw - 8/5/93
;

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	AfterVisChildrenNotified

	or	bp, mask SBF_VIS_PARENT_UNBUILDING

; SBF_WIN_GROUP not used for UNBUILD_BRANCH message.
;	and	bp, not mask SBF_WIN_GROUP	; not top object

	mov	ax, MSG_SPEC_UNBUILD_BRANCH
	call	VisSendToChildren

AfterVisChildrenNotified:

	; To visually unbuild a visual object, it & all children have
	; to be completely destroyed.
	;
	mov	dx, bp			; pass update mode to use
	andnf	dx, mask SBF_UPDATE_MODE
	mov	ax, MSG_VIS_DESTROY
	call	ObjCallInstanceNoLock
	jmp	done

VisSpecUnbuildBranch	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisUnbuildChildren

		built.  The message stops traversal only for the following 
		reasons:

			1) Object is NOT_USABLE.  We may presume that every-
			thing below this branch has been visibly unbuilt.

			2) Object does not have specific instance data.  It
			could not possibly be specifically built, & the
			"specifically grown" rule says that it will have no
			generic children which are specifically grown.

		PLEASE note that this message WILL traverse objects which
		are USABLE, have been specifically grown, but are NOT visibly
		built.  This is because it is possible that they have a 
		child somewhere below which HAS been specifically built at some
		time, & we need to unbuild that object now.

		ALSO NOTE that if the object is a WIN_GROUP w/dual build,
		then the object is called twice, once with SBF_WIN_GROUP clear,
		& once with it set.  If the object is marked as a WIN_GROUP
		only, without DUAL_BUILD, it is called once only w/
		SBF_WIN_GROUP set.

CALLED BY:	INTERNAL

PASS:
	ax - message to pass
	*ds:si - instance
	bp	- SpecBuildFlags	(SBF_WIN_GROUP bit not used here)

RETURN:
	bp	- Unchanged

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

VisUnbuildChildren	proc	far	uses	bp
	class	GenClass
	.enter

	; If unbuilding only because visual parent is unbuilding (i.e. not
	; because we're being set NOT_USABLE), then continue this process
	; by asking only visible children to unbuild themselves.   Will
	; actually hit most generic child objects, since most gen objects
	; vis-build onto their generic parent, but there is a conceptual
	; difference here -- SBF_VIS_PARENT_UNBUILDING is a *visual* unbuild,
	; as opposed to the normal *generic* unbuild.
	;
	test	bp, mask SBF_VIS_PARENT_UNBUILDING
	jnz	afterGenChildren

	mov	di, ds:[si]		; make sure composite
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GI_comp.CP_firstChild.handle, 0
	je	afterGenChildren		;if not, exit

	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx,offset GI_link
	push	bx			;push offset to LinkPart
NOFXIP <	push	cs			;pass callback routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset UnbuildableCallBack
	push	bx

	mov	bx,offset Gen_offset
	mov	di,offset GI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
afterGenChildren:
	; At this point, all generic children will have visually unhooked
	; themselves from this object.   There is still one more issue
	; to deal with:  Any remaining visible children.  It is possible
	; that a generic object NOT in this generic branch has placed 
	; a child visually under this object.  In order to solve this little
	; problem, we'll send any remaining visible children a
	; MSG_SPEC_UNBUILD_BRANCH, with flag SBF_VIS_PARENT_UNBUILDING
	; set, so that they can communicate with their source generic
	; object, in order to remove the visible child before its parent's
	; visible part is destroyed, thereby resulting in bad linkage in
	; the child.  Non-generic objects will simply be destroyed.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	AfterVisChildrenNotified
	or	bp, mask SBF_VIS_PARENT_UNBUILDING

; SBF_WIN_GROUP not used for UNBUILD_BRANCH message.
;	and	bp, not mask SBF_WIN_GROUP	; not top object

	mov	ax, MSG_SPEC_UNBUILD_BRANCH
	call	VisSendToChildren

AfterVisChildrenNotified:
	.leave
	ret

VisUnbuildChildren	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	UnbuildableCallBack

DESCRIPTION:	

CALLED BY:	VisUnbuildChildren

PASS:
	*ds:si - child
	*es:di - composite
	bp 	- SpecBuildFlags

RETURN:
	carry - set to end processing

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/90		Initial version

------------------------------------------------------------------------------@

UnbuildableCallBack	proc	far
	class	VisClass

	; Make sure we don't send it to something not usable
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	pop	di
	jz	done			; If not usable, skip sending message

	call	GenCheckIfSpecGrown	; See if specifically grown
	jnc	done			; If not, doesn't need to un-spec build

					; Use ES version since *es:di is
					;	composite object
	push	bp			; Save SpecBuildFlags
					; Unbuild the branch at this child.
	mov	ax, MSG_SPEC_UNBUILD_BRANCH
	call	ObjCallInstanceNoLockES	; send it
	pop	bp
done:
	clc
	ret

UnbuildableCallBack	endp

			
Build	ends

;
;---------------
;
		
Navigation	segment	resource
			
			

COMMENT @----------------------------------------------------------------------

FUNCTION:	VisSpecNavigationQuery - 
		MSG_SPEC_NAVIGATION_QUERY handler for VisClass

DESCRIPTION:	This message is used to implement the keyboard navigation
		within-a-window mechanism. See message declaration for full
		details.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		^lcx:dx	= object which originated the navigation message
		bp	= NavigationFlags

RETURN:		ds, si	= same
		^lcx:dx	= replying object
		bp	= NavigationFlags (in reply)
		al	= NavigateCommonFlags
		ah destroyed
		carry set if found the next/previous object we were seeking

DESTROYED:	bx, es, di, ds, si

PSEUDO CODE/STRATEGY:
	VisClass handler:
	    Since we have received this message at this class level, we know
	    that this object is not a composite, and if is subclassed by
	    something in the specific UI, it is something that is never
	    focused, and so is excluded from navigation. So all we need
	    to do is forward this message to the next visible child.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

VisSpecNavigationQuery	method	dynamic VisClass, MSG_SPEC_NAVIGATION_QUERY
	;ERROR CHECKING is in VisNavigateCommon

	;call utility routine, passing flags to indicate that this is
	;a leaf node in visible tree, and that this object cannot
	;get the focus (although it may have siblings that do).
	;This routine will check the passed NavigationFlags and decide
	;what to respond.

	clr	bl			;pass flags: not root node,
					;not composite, not focusable.
	mov	di, si			;if this object has generic part,
					;ok to scan it for hints.
	call	VisNavigateCommon
	Destroy	ah
	ret
VisSpecNavigationQuery	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisNavigateCommonMsg -- 
		MSG_SPEC_NAVIGATE_COMMON for VisClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	C message version of VisNavigateCommon.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NAVIGATE_COMMON

		ss:bp -- NavigateCommonParams
		dx    -- size NavigateCommonParams

RETURN:		ss:bp -- NavigateCommonParams, with:
			    NCP_object -- set to final recipient of message
			    NCP_navFlags -- flags returned by final recipient
			    NCP_backtrackFlag -- set if object is focusable
						 via backtracking.
		carry set if found the next/previous object we were seeking
		ax, cx, dx - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	7/20/94         Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisNavigateCommonMsg	method dynamic	VisClass, \
				MSG_SPEC_NAVIGATE_COMMON
	.enter
	push	bp
	movdw	cxdx, ss:[bp].NCP_object
	mov	bl, ss:[bp].NCP_navCommonFlags
	mov	di, ss:[bp].NCP_genPart
	mov	bp, ss:[bp].NCP_navFlags
	call	VisNavigateCommon
	mov	bx, bp
	pop	bp
	mov	ss:[bp].NCP_navFlags, bx
	movdw	ss:[bp].NCP_object, cxdx
	mov	ss:[bp].NCP_backtrackFlag, al
	.leave
	ret
VisNavigateCommonMsg	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisSpecActivateObjectWithMnemonic

DESCRIPTION:	Figures out if the keyboard data passed matches the mnemonic
		for this object or one of its children.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_FIND_MNEMONIC
		
		same as MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code

RETURN:		carry set if match found
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/17/90		Initial version

------------------------------------------------------------------------------@

VisSpecActivateObjectWithMnemonic	method dynamic VisClass,
				MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC

	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	tryChildren			; not generic object, skip self

	push	cx
	clr	cx				; allow optimized approach, as
						; this is a "steady state"
						; scenerio.
	call	GenCheckIfFullyEnabled		 ;enabled?
	pop	cx
	jnc	tryChildren			 ;not enabled, don't check
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
   	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	tryChildren			 ;don't match on win groups
	
	call	VisCheckMnemonic		 ;see if mnemonic matches
	jnc	tryChildren			 ;doesn't match, branch
	
	mov	ax, MSG_GEN_ACTIVATE		 ;found match, activate
	call	ObjCallInstanceNoLock	
	stc					 ;say match found
	jmp	short exit
	
tryChildren:

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE	
	clc
	jz	exit				;not composite, exit no match

	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di
	mov	ax, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	di, OCCT_SAVE_PARAMS_TEST_ABORT
	call	VisCallCommon			;call children 'til match found
	pop	di
	call	ThreadReturnStackSpace
exit:
	Destroy	ax, cx, dx, bp
	ret
VisSpecActivateObjectWithMnemonic	endm

		
Navigation	ends

;
;---------------
;
		
VisCommon	segment	resource
			


COMMENT @----------------------------------------------------------------------

METHOD:		VisNotifyEnabled -- 
		MSG_SPEC_NOTIFY_ENABLED for VisClass

DESCRIPTION:	Notification that the tree above this object is now enabled.
		Adjust our fully-enabled flag, redraw, and call GenChildren
		if necessary.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_ENABLED
		dl	- VisUpdateMode
		dh	- NotifyEnabledFlags:
				mask NEF_STATE_CHANGING if this is the object
					getting its enabled state changed

RETURN:		ax, cx, dx, bp - destroyed


DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       	if (not the item that changed) and GS_ENABLED and not VA_FULLY_ENABLED
		send on to generic children
		redraw ourselves

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 8/90		Initial version

------------------------------------------------------------------------------@

VisSpecNotifyEnabled	method static VisClass, MSG_SPEC_NOTIFY_ENABLED \
			uses bx, si, di
	.enter
	Destroy	ax, bx, di, bx		
	;
	; We need to check the entire lineage before we visually enable an
	; object.  Previously, if we enabled an object that had a disabled
	; parent, it would incorrectly become visually enabled.  -cbh 9/ 6/90
	;
	mov	di, ds:[si]		;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN	
	jz	10$			; not generic, just look at vis flag
	
	mov	cx, -1			; No optimization, do full check, as
					; the state of the VA_FULLY_ENABLED
					; flag must be re-determined.
	call	GenCheckIfFullyEnabled	; see if we should be visually enabled
	jnc	exit			; no, exit now
10$:
	mov	di, ds:[si]		; point to instance
	add	di, ds:[di].Vis_offset	; ds:[di] -- VisInstance
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED	
	clc				; assume no state change necessary
	jnz	exit			; already fully enabled, exit now
	
	;
	; Object is changing state, and is now fully enabled.
	; Send this down to its children, and have it redraw itself.
	;
	or	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	call	HandleEnabledStateChange ; handle state change	

	;
	; New exciting code to give this object the focus if its wants the
	; default and the parent focus node has no focus.  -cbh 2/18/92
	; Newer, exciting code not to waste time if not realized. cbh 2/24/93
	;
	mov	di, ds:[si]		; get ptr to child instance data
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	dontGrabFocus		; not realized, skip this.

	mov	ax, MSG_VIS_FUP_QUERY_FOCUS_EXCL
	call	VisCallParentEnsureStack
	tst	cx			 ; anything returned?
	jnz	dontGrabFocus		 ; yes, don't bother grabbing focus
	clr	cx			 ; see if we want the focus
	mov	ax, MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS
	call	ObjCallInstanceNoLock
	tst	cx
	jz	dontGrabFocus		 ; apparently not, branch
	call	MetaGrabFocusExclLow	 ; else grab the focus
dontGrabFocus:

	stc				 ; say visual state changed
exit:
	Destroy	ax, cx, dx, bp
	.leave
	ret
VisSpecNotifyEnabled	endm

		


COMMENT @----------------------------------------------------------------------

METHOD:		VisSpecNotifyNotEnabled -- 
		MSG_SPEC_NOTIFY_NOT_ENABLED for VisClass

DESCRIPTION:	Notification that the tree above this object is now disabled.
		Adjust our fully-enabled flag, redraw, and call GenChildren
		if necessary.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_NOT_ENABLED
		dl	- VisUpdateMode
		dh	- NotifyEnabledFlags:
				mask NEF_STATE_CHANGING if this is the object
					getting its enabled state changed

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       	if (not the item that changed) and GS_ENABLED and VA_FULLY_ENABLED
		send on to generic children
		redraw ourselves

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 8/90		Initial version

------------------------------------------------------------------------------@

VisSpecNotifyNotEnabled	method static VisClass, MSG_SPEC_NOTIFY_NOT_ENABLED \
					uses bx, si, di
	.enter
	test	dh, mask NEF_STATE_CHANGING
	jnz	10$			; this object's changing, continue
	
	mov	di, ds:[si]		;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN	
	jz	10$			; not generic, just look at vis flag
	
	mov	di, ds:[si]		; point to instance
	add	di, ds:[di].Gen_offset	; ds:[di] -- GenInstance
	test	ds:[di].GI_states, mask GS_ENABLED
	jz	exit			; object is disabled, exit now
10$:	
	mov	di, ds:[si]		; point to instance
	add	di, ds:[di].Vis_offset	; ds:[di] -- VisInstance
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED	
	clc				; assume no change
	jz	exit			; already not fully enabled, exit now
	
	;
	; Object is changing state and is no longer fully enabled.
	; Send this down to its children, and have it redraw itself.
	;
	and	ds:[di].VI_attrs, not mask VA_FULLY_ENABLED
	call	HandleEnabledStateChange ; handle state change	
	stc				 ; say visual state changed
exit:
	Destroy	ax, cx, dx, bp
	.leave
	ret
VisSpecNotifyNotEnabled	endm

			


COMMENT @----------------------------------------------------------------------

ROUTINE:	HandleEnabledStateChange

SYNOPSIS:	Enabled state has changed, so lets send the notify message down
		to the children, and redraw ourselves.

CALLED BY:	VisNotifyEnabled, VisNotifyNotEnabled

PASS:		*ds:si -- object
		ax     -- spec notify message
		dl	- VisUpdateMode
		dh	- NotifyEnabledFlags:
				mask NEF_STATE_CHANGING if this is the object
					getting its enabled state changed

RETURN:		carry set if visual state changed

DESTROYED:	ax, bx, cx, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 8/90		Initial version

------------------------------------------------------------------------------@

HandleEnabledStateChange	proc	near
	class	VisClass

	mov	cl, mask DF_DONT_DRAW_CHILDREN	;we don't need to worry
						;   about children
	call	ShouldObjBeDrawn?	; is it appropriate to redraw?
	jnc	exit			; no, forget it
	
	;
	; Clear this flag for all children.
	;
	tst	dl			; do we need to invalidate stuff?
	js	exit			; no, get out
	cmp	dl, VUM_NOW	 	; if update now, draw the thing.
	je	drawNow

					; Otherwise, mark image as invalid
					; & update based on flags in dl
	mov	cl, mask VOF_IMAGE_INVALID
	mov	ax, MSG_VIS_MARK_INVALID
	mov	di, mask MF_FIXUP_DS
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage
	jmp	short exit

drawNow:
	;
	; Create a gstate and draw directory, instructing visComp objects
	; to avoid drawing their children.
	;
	mov	ax,MSG_VIS_VUP_CREATE_GSTATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage

EC <	; Should not be possible for this not to be answered		>
EC <	ERROR_NC	VIS_MSG_VIS_VUP_CREATE_GSTATE_NOT_ANSWERED	>

	push	bp			; Save the gstate handle
	mov	cl, mask DF_DONT_DRAW_CHILDREN
	mov	ax, MSG_VIS_DRAW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di			; Recover the gstate handle
	call	GrDestroyState		;   and destroy it
exit:
	ret
HandleEnabledStateChange	endp

			


COMMENT @----------------------------------------------------------------------

METHOD:		VisConvertDesiredSize -- 
		MSG_SPEC_CONVERT_DESIRED_SIZE_HINT for VisClass

DESCRIPTION:	Converts desired size arguments for this class.  For non-
		composite objects, we'll convert the SpecSizeSpec arguments,
		add any extra size that our specific part returns for us,
		and returns the sum.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_CONVERT_DESIRED_SIZE_HINT
		cx      - {SpecSizeSpec} desired width
		dx 	- {SpecSizeSpec} desired height
		bp	- {SpecSizeSpec} number of children (comps only)

RETURN:		cx, dx  - converted width, height
		ax, bp  - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/30/91		Initial version

------------------------------------------------------------------------------@

VisSpecConvertDesiredSizeHint method VisClass,
					MSG_SPEC_CONVERT_DESIRED_SIZE_HINT
	push	dx				;save desired height, width
	push	cx
	mov	ax, MSG_SPEC_GET_EXTRA_SIZE	;return any non-moniker space
	call	ObjCallInstanceNoLock		;  in cx, dx

	push	cx, dx				;what was I thinking	
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
 	call	ObjCallInstanceNoLock		;get a gstate to work with
	pop	cx, dx				;what was I thinking	
	mov	di, bp				;gstate in di
	pop	ax				;restore passed width in ax
	tst	ax				;is there one?
	jnz	10$				;yes, continue
	mov	cx, ax				;else don't return anything
	jmp	short 20$
10$:
	call	VisConvertSpecVisSize		;calc a real width in ax
	add	cx, ax				;add to extra size
20$:
	pop	ax				;restore passed height
	tst	ax				;is there one?
	jnz	30$				;yes, continue
	mov	dx, ax				;else don't return anything
	jmp	short 40$
30$:
	call	VisConvertSpecVisSize		;calc a real height in ax
	add	dx, ax				;add  to extra height
40$:
	call	GrDestroyState
	Destroy	ax, bp
	ret
VisSpecConvertDesiredSizeHint	endm


VisCommon	ends
;
;-------------------
;
VisUncommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisGetSpecAttrs -- 
		MSG_SPEC_GET_ATTRS for VisClass

DESCRIPTION:	Returns spec attributes.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_ATTRS

RETURN:		cl	- SpecAttrs
		ax, ch, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/10/91		Initial version

------------------------------------------------------------------------------@

VisSpecGetAttrs	method dynamic	VisClass, MSG_SPEC_GET_ATTRS
	Destroy	ax, cx, dx, bp
	mov	cl, ds:[di].VI_specAttrs
	ret
VisSpecGetAttrs	endm

VisUncommon	ends
;
;-------------------
;
VisUpdate	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisSpecUpdateVisMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message handler just checks to see if the size of the 
		moniker has changed. If so, it sets the image AND geometry 
		invalid. Otherwise, it sets just the image invalid.

CALLED BY:	GLOBAL
PASS:		dl - update mode
		cx - old width  (or NO_VIS_MONIKER if there was none)
		bp - old height (or NO_VIS_MONIKER if there was none)
		
RETURN:		ax, cx, dx, bp - destroyed
		
DESTROYED:	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisSpecUpdateVisMoniker	method	dynamic VisClass, MSG_SPEC_UPDATE_VIS_MONIKER
			
EC <	; Make sure that instance data is not hosed			>
EC <	call	ECCheckVisFlags						>
	;
	; If not yet specifically built, then moniker changing does not affect
	; us visually.
	;
	call	VisCheckIfSpecBuilt
	jnc	done

	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	fullInvalid			;not a gen object, just inval

	push	dx				;Save VisUpdateMode
	push	cx,bp				;Save old dimensions
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>

	push	es				;Save idata segment
	segmov	es,ds,di			;*ES:DI <- new vis moniker
	mov	di,ds:[si]
	add	di,ds:[di].Gen_offset		;Get vis moniker chunk
	mov	di,ds:[di].GI_visMoniker	;
	clr	bp				;
	clr	ax				;don't know text height
	call	VisGetMonikerSize		;Returns CX,DX as size
	mov	bp,dx				;CX,BP <- new dimensions
	pop	es				;Restore idata segment
	pop	ax,bx				;AX,BX <- old dimensions
	pop	dx				;Restore VisUpdateMode

;	COMPARE SIZES AND MARK OBJECT INVALID ACCORDINGLY

	cmp	ax,cx				;Test sizes. If any difference,
	jne	fullInvalid			; set geometry invalid. Else,
	cmp	bx,bp				; just set image invalid
	jne	fullInvalid
	mov	cl,mask VOF_IMAGE_INVALID	;CL <- what to mark invalid
	GOTO	VisMarkInvalid			; Mark object image as invalid

fullInvalid:
	call	VisMarkFullyInvalid		;Invalidate GEOMETRY and IMAGE
						; & do a visual update
						; (pass update mode in dl)
;	mov	ax,MSG_VIS_VUP_UPDATE_WIN_GROUP
;	call	ObjCallInstanceNoLock
	call	VisVupUpdateWinGroup		;call statically
done:
	Destroy	ax, cx, dx, bp
	ret

VisSpecUpdateVisMoniker	endm




COMMENT @----------------------------------------------------------------------

METHOD:		VisSpecUpdateKbdAccelerator -- 
		MSG_SPEC_UPDATE_KBD_ACCELERATOR for VisClass

DESCRIPTION:	Does visual fixup after accelerator changes.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UPDATE_KBD_ACCELERATOR
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
	chris	4/22/92		Initial Version

------------------------------------------------------------------------------@

VisSpecUpdateKbdAccelerator	method dynamic	VisClass, \
				MSG_SPEC_UPDATE_KBD_ACCELERATOR

	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
	call	VisMarkInvalid
	ret
VisSpecUpdateKbdAccelerator	endm

VisUpdate	ends
;
;-------------------
;
VisCommon	segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		VisSpecGupQueryVisParent


DESCRIPTION:	Queries for a certain kind of VisParent.

	This method forces specific building of object, & therefore shouldn't
	be done prior to setting up pre-specifically built hints, attributes,
	& for some objects, tree location.

WHO CAN USE:	Anyone

PASS:		*ds:si - object
		ax - MSG_SPEC_GUP_QUERY_VIS_PARENT

		cx	- SpecQueryVisParentType
		
RETURN:		carry	- Set if data found & returned, clear if no object
			  responded
		^lcx:dx	- object suitable to be this object's
			  visible parent
		ax, bp	- destroyed

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

VisSpecGupQueryVisParent	method	dynamic VisClass, 
				MSG_SPEC_GUP_QUERY_VIS_PARENT
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN			>
EC <	ERROR_Z	UI_GUP_QUERY_CALLED_ON_NON_GEN_OBJECT			>

   
	call	GenCallParentEnsureStack	; send to parent by default
	jc	exit			; query answered, exit
	clr	cx
	mov	dx, cx			; else make sure ^lcx:dx is zeroed
exit:
	ret

VisSpecGupQueryVisParent	endm

			
VisCommon	ends

;
;---------------
;
		
Navigation	segment	resource
			


COMMENT @----------------------------------------------------------------------

METHOD:		VisSpecNavigate -- 
		MSG_SPEC_NAVIGATE for VisClass

DESCRIPTION:	Handles navigation for most objects.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NAVIGATE
		bp	- NavigateFlags

RETURN:		carry set if answered,
			^lcx:dx - object responding to navigation
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	12/ 9/91		Initial Version

------------------------------------------------------------------------------@

VisSpecNavigate	method dynamic	VisClass, MSG_SPEC_NAVIGATE
	lastFocusableObj	local	optr
	originatorObj		local	optr
	navigateFlags		local	NavigateFlags
	
	mov	di, bp
	.enter
	mov	navigateFlags, di		;initialize local vars
	mov	originatorObj.chunk, si
	mov	bx, ds:[LMBH_handle]
	mov	originatorObj.handle, bx
	clr	lastFocusableObj.handle, lastFocusableObj.chunk
	
queryLoop:
	;
	; ^lbx:si is next object to query.   Query the object.
	;
	push	bx, si				;save destination object
	
	mov	cx, originatorObj.handle	;pass originator
	mov	dx, originatorObj.chunk
	push	bp
	mov	bp, navigateFlags		;pass navigate flags
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_SPEC_NAVIGATION_QUERY
	call	ObjMessage			;query the objects
	mov	di, bp
	pop	bp
	mov	navigateFlags, di		;return navigate flags here
	jc	matchFound			;found match, branch
	
	tst	cx				;anywhere to go next?
	jz	exit				;no, branch (carry clear)
	
	mov	si, dx				;^lbx:si <- next object to query
	mov	bx, cx
	
	pop	cx, dx				;restore object we queried
	tst	al				;last object focusable?
	jz	queryLoop			;nope, move on
	mov	lastFocusableObj.handle, cx	;else save as last focusable obj
	mov	lastFocusableObj.chunk, dx
	jmp	short queryLoop			;and loop to do another
	
matchFound:
	add	sp, 4				;unload stack stuff
	;
	; If we're going backwards, we'll return the last focusable object
	; *before* the one that matched.
	;
	test	navigateFlags, mask NF_BACKTRACK_AFTER_TRAVELING
	jz	exitMatch
	mov	cx, lastFocusableObj.handle
	mov	dx, lastFocusableObj.chunk
	
VSN_reachedPrevious label near		;THIS LABEL USED BY SHOWCALLS IN SWAT.
	ForceRef	VSN_reachedPrevious
	;this backtrack query has found the object which is considered
	;"previous" from the starting point.
	
EC <	nop					;make labels distinct   >
	
exitMatch:
	;
	; Let the object know it has won the navigation contest.  Left here
	; for the object's benefit, since it can't really sniff out if it is
	; the recipient of backwards navigation.
	;
	push	cx, dx
	mov	bx, cx
	mov	si, dx
	push	bp
	mov	bp, navigateFlags		;pass navigate flags
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_SPEC_NOTIFY_NAVIGATION_COMPLETE
	call	ObjMessage
	pop	bp
	pop	cx, dx
	stc					;signal a match
exit:
	mov	di, navigateFlags		;restore bp
	.leave
	mov	bp, di
	ret
VisSpecNavigate	endm


Navigation	ends

;
;---------------
;
		
VisUpdate	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisNotifyGeometryValid -- 
		MSG_VIS_NOTIFY_GEOMETRY_VALID for VisClass

DESCRIPTION:	Notifies the object that the geometry is valid.  If this
		handler is reached, we'll assume that there is some kind
		of position hint on the object and scan for it.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_NOTIFY_GEOMETRY_VALID

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
	chris	2/ 4/92		Initial Version

------------------------------------------------------------------------------@

VisNotifyGeometryValid	method dynamic	VisClass, MSG_VIS_NOTIFY_GEOMETRY_VALID

	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	exit				;not generic, exit
	call	VisSpecCheckForPosHints
	jnc	exit				;no position hints, exit

	mov	ax, MSG_VIS_POSITION_BRANCH
	call	ObjCallInstanceNoLock		;set a new position, and make
						;  sure we do children, too!
						;  6/21/93 cbh

	; This error checking dies in a few cases where we really don't want
	; it to die, even though it is not *exactly* kosher -- tony 12/14/92
if 0
if 	ERROR_CHECK
	;
	; Make sure the object's bounds are still within the parent's.
	;
	push	ax, cx, dx, bp, di
	mov	ax, MSG_VIS_GET_BOUNDS		
	call	VisCallParent			;parent bounds in ax,bp,cx,dx

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].VI_bounds.R_left, ax
	ERROR_B  UI_POSITION_HINT_FORCES_OBJECT_OUTSIDE_VIS_PARENT_BOUNDS
	cmp	ds:[di].VI_bounds.R_right, cx
	ERROR_A  UI_POSITION_HINT_FORCES_OBJECT_OUTSIDE_VIS_PARENT_BOUNDS
	cmp	ds:[di].VI_bounds.R_top, bp
	ERROR_B  UI_POSITION_HINT_FORCES_OBJECT_OUTSIDE_VIS_PARENT_BOUNDS
	cmp	ds:[di].VI_bounds.R_bottom, dx
	ERROR_A  UI_POSITION_HINT_FORCES_OBJECT_OUTSIDE_VIS_PARENT_BOUNDS
	pop	ax, cx, dx, bp, di
endif
endif

exit:
	ret
VisNotifyGeometryValid	endm


VisUpdate	ends
;
;-------------------
;
VisUpdate	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisRescanGeoAndUpdate -- 
		MSG_SPEC_RESCAN_GEO_AND_UPDATE for VisClass

DESCRIPTION:	Rescans geometry and performs a geometry update if needed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_RESCAN_GEO_AND_UPDATE
		cl	- VisOptFlags to mark invalid
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
	chris	2/ 5/92		Initial Version

------------------------------------------------------------------------------@

VisSpecRescanGeoAndUpdate	method dynamic	VisClass,
					MSG_SPEC_RESCAN_GEO_AND_UPDATE
	;
	; Reset size hint flag in specific UI.
	;
	mov	al, cl				 ;VisOptFlags
	mov	ah, dl				 ;VisUpdateMode
	push	ax				 ;save 'em
	mov	cx, mask VGA_NO_SIZE_HINTS shl 8 ;else clear this flag
	mov	dl, VUM_MANUAL			 ;update comes later
	mov	ax, MSG_VIS_SET_GEO_ATTRS
	call	ObjCallInstanceNoLock		 

	mov	ax, MSG_SPEC_SCAN_GEOMETRY_HINTS ;scan in generic instance
	call	ObjCallInstanceNoLock

	clr	bp				;get non-win-group first
	call	VisGetSpecificVisObject		;  in ^lcx:dx
	movdw	bxdi, cxdx
	mov	bp, mask SBF_WIN_GROUP		;now win-group
	call	VisGetSpecificVisObject		;  in ^lcx:dx
	cmpdw	bxsi, cxdx			;are they the same?
	pop	ax				;(VisOptFlags, VisUpdateMode)
	je	winGroup			;yes, do win group part

	push	cx, dx, ax			;save winGroup part
	movdw	cxdx, bxdi			;pass non winGroupPart
	call	UpdateSpecObject		;update stuff
	pop	cx, dx, ax
	
winGroup:
	call	UpdateSpecObject		;do win group part
	ret
VisSpecRescanGeoAndUpdate	endm





UpdateSpecObject	proc	near
	;
	; ^lcx:dx -- object, al -- VisOptFlags, ah -- VisUpdateMode
	;
	tst	dx				;nothing to do, exit
	jz	exit

	movdw	bxsi, cxdx
	mov	dl, ah				;VisUpdateMode
	mov	cl, al				;VisOptFlags
	mov	ax, MSG_VIS_MARK_INVALID
	mov	di, mask MF_CALL
	call	ObjMessage
exit:
	ret
UpdateSpecObject	endp

VisUpdate	ends
;
;-------------------
;
Build	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisResolveMonikerList -- 
		MSG_SPEC_RESOLVE_MONIKER_LIST for VisClass

DESCRIPTION:	Used by Generic UI to implement the MSG_GEN_REPLACE_VIS_MONIKER,
		MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER case where a moniker
		list is passed and the object is already built -- the specific
		UI must choose one of the monikers in the moniker list.

PASS:		*ds:si 	- instance data
		es     	- segment of VisClass
		ax 	- MSG_SPEC_RESOLVE_MONIKER_LIST

		cx	- chunk handle of moniker list, to be replaced by
				most appropriate moniker
				(IN SAME BLOCK AS THIS OBJECT)

RETURN:		most appropriate moniker choosen from moniker list and replaces
			passed moniker list chunk
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/1/92		Initial Version

------------------------------------------------------------------------------@

VisSpecResolveMonikerList	method dynamic	VisClass,
					MSG_SPEC_RESOLVE_MONIKER_LIST

	call	UserGetDisplayType	; ah = DisplayType
	call	UserLimitDisplayTypeToStandard
	mov	bh, ah			; bh = DisplayType
					; bp = VisMonikerSearchFlags
					; (we don't pass VMSF_REPLACE_LIST as
					;  we manually replace below)
	mov	bp, mask VMSF_GSTRING or \
			(VMS_ICON shl offset VMSF_STYLE)
					; return non-textual GString if any,
					; otherwise GString, otherwise
					; non-abbreviated text string.
	mov	di, cx			; *ds:di = VisMoniker or VisMonikerList
	call	VisFindMoniker		; ^lcx:dx = VisMoniker
	mov	ax, ds:[LMBH_handle]	; ax = object block handle
	sub	sp, CopyChunkOVerFrame
	mov	bp, sp
	mov	ss:[bp].CCOVF_source.handle, cx		; source =
							; found moniker
	mov	ss:[bp].CCOVF_source.chunk, dx
	mov	ss:[bp].CCOVF_dest.handle, ax		; dest = passed chunk
	mov	ss:[bp].CCOVF_dest.chunk, di
							; XXX don't mark dirty?
	mov	ss:[bp].CCOVF_copyFlags, CCM_OPTR shl offset CCF_MODE
	mov	dx, size CopyChunkOVerFrame
	call	UserHaveProcessCopyChunkOver
	add	sp, size CopyChunkOVerFrame
	ret
VisSpecResolveMonikerList	endm

Build ends

BuildUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisResolveTokenMoniker -- 
		MSG_SPEC_RESOLVE_TOKEN_MONIKER for VisClass

DESCRIPTION:	Used by Generic UI to implement MSG_GEN_REPLACE_VIS_MONIKER,
		MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER, and
		MSG_GEN_DYNAMIC_LIST_COPY_ITEM_MONIKER.  The specific UI
		chooses a moniker passed on the passed token chunk and replaces
		the chunk with the appropriate moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of VisClass
		ax 	- MSG_SPEC_RESOLVE_TOKEN_MONIKER

		cx	- chunk handle of GeodeToken, to be replaced by
				most appropriate moniker in Token Database's
				moniker list for the token
				(IN SAME BLOCK AS THIS OBJECT)

RETURN:		carry clear if successful (token found)
			passed chunk now contains most appropriate moniker
		carry set if unsuccessful (token not in Token Database)
			passed chunk unchanged!! -- DO NOT use for moniker
				as it is not a moniker chunk
		ax, cx, dx, si, bp - destroyed

ALLOWED TO DESTROY:	
		bx, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/27/92		Initial Version

------------------------------------------------------------------------------@

VisSpecResolveTokenMoniker	method dynamic	VisClass,
					MSG_SPEC_RESOLVE_TOKEN_MONIKER
	call	UserGetDisplayType		; ah = DisplayType
	mov	dh, ah				; dh = DisplayType
	mov	di, cx				; di = chunk
	mov	bx, ds:[di]			; deref. chunk
	mov	si, ({GeodeToken} ds:[bx]).GT_manufID
	mov	ax, {word} ({GeodeToken} ds:[bx]).GT_chars+0
	mov	bx, {word} ({GeodeToken} ds:[bx]).GT_chars+2
						; bp = VisMonikerSearchFlags
	mov	bp, mask VMSF_GSTRING or \
			(VMS_ICON shl offset VMSF_STYLE)
					; return non-textual GString if any,
					; otherwise GString, otherwise
					; non-abbreviated text string.
	call	TokenLookupMoniker		; cx/dx = dbase group/item
						; ax <- shared/local
						;  token DB file flag
	jc	done				; not found, exit with carry set
	push	ax

	mov	si, ds:[LMBH_handle]		; si = object block handle
	call	TokenLockTokenMoniker		; *ds:bx = moniker chunk
	mov	bx, ds:[bx]			; ds:bx = moniker chunk
	ChunkSizePtr	ds, bx, cx		; cx = moniker chunk size
EC <	test	cx, not mask CCF_SIZE					>
EC <	ERROR_NZ	UI_ERROR_CREATE_VIS_MONIKER_SOURCE_TOO_LARGE	>
	ornf	cx, mask CCF_DIRTY or (CCM_FPTR shl offset CCF_MODE)
	mov	dx, size CopyChunkOVerFrame
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].CCOVF_source.segment, ds	; source = token moniker
	mov	ss:[bp].CCOVF_source.offset, bx
	mov	ss:[bp].CCOVF_dest.handle, si		; dest = passed chunk
	mov	ss:[bp].CCOVF_dest.chunk, di
	mov	ss:[bp].CCOVF_copyFlags, cx
	call	UserHaveProcessCopyChunkOver
	add	sp, size CopyChunkOVerFrame

	pop	ax				; ax <- shared/local
						;  token DB flag
	call	TokenUnlockTokenMoniker		; release our grasp
	clc					; indicate success
done:
	ret
VisSpecResolveTokenMoniker	endm

BuildUncommon	ends
