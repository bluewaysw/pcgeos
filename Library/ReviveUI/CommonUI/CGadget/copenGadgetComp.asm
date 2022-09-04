COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/Open (gadgets)
FILE:		copenGadgetComp.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLGadgetCompClass	Open look button

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

DESCRIPTION:

	$Id: copenGadgetComp.asm,v 2.29 96/02/11 14:32:17 brianc Exp $
------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLGadgetCompClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

;this class handles these methods using utility routines in other files.

	method VupCreateGState, OLGadgetCompClass, MSG_VIS_VUP_CREATE_GSTATE
	method OLGadgetVupQuery, OLGadgetCompClass, MSG_VIS_VUP_QUERY
	
;	method	VisCallParent, OLGadgetCompClass, MSG_VIS_VUP_RELEASE_ALL_MENUS
	method	VisCallParent, OLGadgetCompClass, MSG_VIS_VUP_RELEASE_MENU_FOCUS
	method	VisCallParent, OLGadgetCompClass, MSG_OL_VUP_MAKE_APPLYABLE
	
	method	VisSendToChildren, OLGadgetCompClass, MSG_OL_MAKE_APPLYABLE
	method	VisSendToChildren, OLGadgetCompClass, MSG_OL_MAKE_NOT_APPLYABLE
if INDENT_BOXED_CHILDREN
	method	VisCallParent, OLGadgetCompClass, MSG_SPEC_VUP_ADD_GADGET_AREA_LEFT_MARGIN
endif

CommonUIClassStructures ends

;---------------------------------------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLGadgetCompGupQuery -- MSG_SPEC_GUP_QUERY for OLGadgetCompClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLGadgetCompClass

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

	see OLMapGroup for details

	if (query = SGQT_BUILD_INFO) {
		;Is below a control area: if is a menu or a GenTrigger which
		;want to be moved into a GenFile-type object, then send query
		;to parent to see if such a beast exists. Return if somebody
		;above wants to grab this object. Otherwise, is a plain
		;GenTrigger which should stay in this OLCtrl object.
	    if (MENUABLE) or (HINT_FILE or HINT_EDIT) {
		MSG_SPEC_GUP_QUERY(vis parent, SGQT_BUILD_INFO);
		if (visParent != NULL) {
		    return(stuff from parent)
		}
	    }
	    ;Nothing above grabbed object, or object is plain GenTrigger.
	    ;Place inside this OLCtrl object.
	    TOP_MENU = 0;
	    SUB_MENU = 0;
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


OLGadgetCompGupQuery	method	OLGadgetCompClass, MSG_SPEC_GUP_QUERY
	cmp	cx, SGQT_BUILD_INFO		;can we answer this query?
	je	OLGadgetCompGUQ_answer			;skip if so...

	;we can't answer this query: call super class to handle
	mov	di, offset OLGadgetCompClass
	GOTO	ObjCallSuperNoLock

OLGadgetCompGUQ_answer:
EC <	call	VisCheckVisAssumption					>

	test	bp, mask OLBF_MENUABLE
	jz	noPromote

;;promote: ;send query to generic parent to see if it wants to grab object
	push	bp				;save OLBuildFlags in case
						;we ignore parent
	call	GenCallParent
	pop	di				;di = original OLBuildFlags

	mov	bx, bp
	and	bx, mask OLBF_REPLY
	cmp	bx, OLBR_TOP_MENU shl offset OLBF_REPLY
	jz	done
	cmp	bx, OLBR_SUB_MENU shl offset OLBF_REPLY
	jz	done

	mov	bp, di				;return original OLBuildFlags

noPromote: ;use this OLGadgetCompClass object as visible parent
	mov	cx, ds:[LMBH_handle]
	mov	dx, si

done:
	stc					;return query acknowledged
	FALL_THRU	CommonFunctionalFarRet

OLGadgetCompGupQuery	endm

CommonFunctionalFarRet	proc	far
	ret
CommonFunctionalFarRet	endp

CommonFunctional	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLGadgetCompFupKbdChar - MSG_META_FUP_KBD_CHAR handler for OLGadgetCompClass

DESCRIPTION:	This method is sent by child which 1) is the focused object
		and 2) has received a MSG_META_KBD_CHAR or MSG_META_FUP_KBD_CHAR
		which is does not care about. Since we also don't care
		about the character, we forward this method up to the
		parent in the focus hierarchy.

		At this class level, we are assuming the parent in the
		focus hierarchy is the visible parent.

PASS:		*ds:si	= instance data for object
		cx = character value
		dl = CharFlags
		dh = ShiftState
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

OLGadgetCompFupKbdChar	method	OLGadgetCompClass, MSG_META_FUP_KBD_CHAR
	GOTO	VisCallParent
OLGadgetCompFupKbdChar	endm

KbdNavigation	ends


CommonFunctional	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLGadgetCompBroadcastForDefaultFocus --
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS handler.

DESCRIPTION:	This broadcast method is used to find the object within a window
		which has HINT_DEFAULT_FOCUS{_WIN}. We handle here so that
		the broadcast can be propogated into GenGadgets which are
		inside a window.

PASS:		*ds:si	= instance data for object

RETURN:		^lcx:dx	= OD of object with hint
		carry set if broadcast handled

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLGadgetCompBroadcastForDefaultFocus	method	OLGadgetCompClass, \
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS

	;send MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS to all visible
	;children which are FULLY_ENABLED. Returns OD of last object in visible
	;tree which has HINT_DEFAULT_FOCUS{_WIN}.

	mov	bx, offset OLBroadcastForDefaultFocus_callBack
					;pass offset to callback routine,
					;in Resident resource
	GOTO	OLResidentProcessVisChildren
OLGadgetCompBroadcastForDefaultFocus	endm

CommonFunctional ends


InstanceObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLGadgetCompGetBuildFlags -- 
		MSG_VUP_GET_BUILD_FLAGS for OLGadgetCompClass

DESCRIPTION:	Returns build flags.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VUP_GET_BUILD_FLAGS

RETURN:		cx	- OLBuildFlags
		ax, dx, bp - destroyed

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

OLGadgetCompGetBuildFlags	method dynamic	OLGadgetCompClass, \
				MSG_VUP_GET_BUILD_FLAGS
	;
	; The gadget is part of some other window.  Let's assume this is
	; done as the result of a SPEC_BUILD, and we can count on our Vis
	; parent link being established.
	;
	GOTO	VisCallParent

OLGadgetCompGetBuildFlags	endm

InstanceObscure ends
