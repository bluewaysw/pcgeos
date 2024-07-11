COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		entvis.asm

AUTHOR:		Ronald Braunstein, Jun 17, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	6/17/96   	Initial revision


DESCRIPTION:
	Code for EntVisClass
		

	$Id: entVis.asm,v 1.1 98/03/06 17:55:24 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




;
; Make the property table for EntVis here.
;
makePropEntry entvis, visible, LT_TYPE_INTEGER, PDT_SEND_MESSAGE, \
	<PD_message MSG_ENT_VIS_GET_VISIBLE>, PDT_SEND_MESSAGE, \
	<PD_message MSG_ENT_VIS_SET_VISIBLE>
makePropEntry entvis, enabled, LT_TYPE_INTEGER, PDT_SEND_MESSAGE, \
	<PD_message MSG_ENT_VIS_GET_ENABLED>, PDT_SEND_MESSAGE, \
	<PD_message MSG_ENT_VIS_SET_ENABLED>

compMkPropTable	EntVisProperty, entvis, visible, enabled
compMkActTable	entvis




COMMENT @###################################################################

Code for EntVisClass follows.

###########################################################################@

;
; Define standard routines for EntVis.
; Once we create a macro that Ent can use to generate
; these routines, we can take out this code.  Note, however,
; that we need an empty action table since the macro will
; blindly spit out entvisActionTable.  Or perhaps we could make
; the macro smart enough not to generate the action table if no
; actions are specified.
;

EntVisGetProperty	method dynamic EntVisClass, MSG_ENT_GET_PROPERTY
		uses	es, bp
		.enter
		segmov	es, cs
		mov	bx, offset entvisPropertyTable
		mov	di, offset EntVisClass
		mov	ax, segment dgroup
		call	EntUtilGetProperty
		.leave
		ret
EntVisGetProperty	endp

EntVisSetProperty	method dynamic EntVisClass, MSG_ENT_SET_PROPERTY
		uses	es, bp
		.enter
		segmov	es, cs
		mov	bx, offset entvisPropertyTable
		mov	di, offset EntVisClass
		mov	ax, segment dgroup
		call	EntUtilSetProperty
		.leave
		ret
EntVisSetProperty	endp

EntVisResolveProperty	method dynamic EntVisClass, MSG_ENT_RESOLVE_PROPERTY
		uses	es, bp
		.enter
		segmov	es, cs
		mov	bx, offset entvisPropertyTable
		mov	di, offset EntVisClass
		mov	ax, segment dgroup
		call	EntResolvePropertyCommon
		.leave
		ret
EntVisResolveProperty	endp

EntVisGPNAD	method dynamic EntVisClass, MSG_ENT_GET_PROPERTY_NAME_AND_DATA
		uses	ax, cx, dx, bp
		.enter
		mov	cx, cs
		mov	bx, offset entvisPropertyTable
		mov	di, offset EntVisClass
		call	EntGetPropNameAndDataCommon
		.leave
		ret
EntVisGPNAD	endp

EntVisResolveAction	method dynamic EntVisClass, MSG_ENT_RESOLVE_ACTION
		.enter
		mov	bx, offset entvisActionTable
		segmov	es, cs
		mov	di, offset EntVisClass
		mov	ax, segment dgroup
		call	EntResolveActionCommon
		.leave
		ret
EntVisResolveAction	endp


EntVisDoAction		method dynamic EntVisClass, MSG_ENT_DO_ACTION,
						    MSG_ENT_CHECK_ACTION
		.enter
		segmov	es, cs
		mov	bx, offset entvisActionTable
		mov	di, offset EntVisClass
		mov	ax, segment dgroup
		call	EntUtilDoAction
		.leave
		ret
EntVisDoAction		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntVisEntSetParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted so that we can set ourselves invisible
		while our  parent is set.

CALLED BY:	MSG_ENT_SET_PARENT
PASS:		*ds:si	= EntVisClass object
		ds:di	= EntVisClass instance data
		ds:bx	= EntVisClass object (same as *ds:si)
		es 	= segment of EntVisClass
		ax	= message #
		cx:dx	= optr of new parent

RETURN:		ax	= 0 if parent was set
			  non-zero if parent was not set
DESTROYED:	whatever superclass destroys
SIDE EFFECTS:
		The set invis/vis stuff used to be done by EntClass.
		A drawback of doing it here is that if the child and
		parent can't hook up (see superclass' check), we'll
		still be committed to the invis/vis biz.  But this
		seems like a minor, unlikely problem.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 6/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntVisEntSetParent	method dynamic EntVisClass, 
					MSG_ENT_SET_PARENT
		.enter
	;
	; Make ourself invisible if necessary.
	;
		test	ds:[di].EI_flags, mask EF_VISIBLE
		pushf
		jz	callSuper
		mov	ax, MSG_ENT_VIS_HIDE
		call	ObjCallInstanceNoLock
	;
	; Have the superclass do its thing.
	;
		mov	ax, MSG_ENT_SET_PARENT
callSuper:
		mov	di, offset EntVisClass
		call	ObjCallSuperNoLock	; ax <- result

	;
	; Set ourselves visible again if we hid ourselves earlier.
	;
		popf
		jz	skipShow
		push	ax			; save result
		mov	ax, MSG_ENT_VIS_SHOW
		call	ObjCallInstanceNoLock
		pop	ax
skipShow:

		.leave
		ret
EntVisEntSetParent	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntVisShow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the object usable in the Gen or Vis world.
		This will also update the "visible" property of the component.

CALLED BY:	MSG_ENT_VIS_SHOW, MSG_ENT_VIS_HIDE
PASS:		*ds:si	= EntVisClass object
		ds:di	= EntVisClass instance data
		ds:bx	= EntVisClass object (same as *ds:si)
		es	= segment of EntVisClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntVisShow method dynamic EntVisClass, MSG_ENT_VIS_SHOW,
				       MSG_ENT_VIS_HIDE
	uses	ax, cx, dx, bp
		.enter
		.assert MSG_ENT_VIS_HIDE eq MSG_ENT_VIS_SHOW +1

		sub	ax, MSG_ENT_VIS_SHOW		;0 = show, 1 = hide
		tst	ax
		jz	setVisible
		BitClr	ds:[di].EI_flags, EF_VISIBLE
		jmp	callMaster
setVisible:
		BitSet	ds:[di].EI_flags, EF_VISIBLE
callMaster:
	;
	; Determine if this is a vis or gen object
	;
		add	ax, MSG_GEN_SET_USABLE
		mov	cl, ds:[di].EI_state
		test	cl, mask ES_IS_GEN
		jnz	genSetUsable

		test	cl, mask ES_IS_VIS
		jz	done
	;
	; Send it a vis message to make it viewable
	;
		mov	cx, ( mask VA_MANAGED or mask VA_DRAWABLE or mask VA_DETECTABLE or mask VA_FULLY_ENABLED)
		cmp	ax, MSG_GEN_SET_USABLE
		je	changeVisState
setNotVisible::
		mov	ch, cl
		clr	cl
changeVisState:
		mov	ax, MSG_VIS_SET_ATTRS
		
	;
	; Send it a gen message to make it viewable
	;
genSetUsable:
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	di, offset EntClass
		call	ObjCallSuperNoLock
done:		
	.leave
	ret
EntVisShow endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntVisGetVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the visible property

CALLED BY:	MSG_ENT_VIS_GET_VISIBLE
PASS:		*ds:si	= EntVisClass object
		ds:di	= EntVisClass instance data
		ds:bx	= EntVisClass object (same as *ds:si)
		es 	= segment of EntVisClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntVisGetVisible	method dynamic EntVisClass, MSG_ENT_VIS_GET_VISIBLE
		uses	es, di
		.enter
		.assert mask EF_VISIBLE eq 1

		mov	al, ds:[di].EI_flags
		
	; make sure we have the property before getting its value
		test	ds:[di].EI_state, mask ES_IS_VIS or mask ES_IS_GEN
		les	di, ss:[bp].GPA_compDataPtr
		jz	error
		
		and	ax, mask EF_VISIBLE
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
done:
	.leave
	ret
error:
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_UNKNOWN_PROPERTY
		jmp	done
EntVisGetVisible	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntVisSetVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the visible property for ent class

CALLED BY:	MSG_ENT_VIS_SET_VISIBLE
PASS:		*ds:si	= EntVisClass object
		ds:di	= EntVisClass instance data
		ds:bx	= EntVisClass object (same as *ds:si)
		es 	= segment of EntVisClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntVisSetVisible	method dynamic EntVisClass, MSG_ENT_VIS_SET_VISIBLE
	uses	es, bx, cx
	.enter
	les	bx, ss:[bp].SPA_compDataPtr
	mov	cx, es:[bx].CD_data.LD_integer
	mov	ax, MSG_ENT_VIS_HIDE
	jcxz	callSelfAndDone
	mov	ax, MSG_ENT_VIS_SHOW
callSelfAndDone:
	call	ObjCallInstanceNoLock
	.leave
	ret
EntVisSetVisible	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntVisGetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the enabled property

CALLED BY:	MSG_ENT_VIS_GET_ENABLED
PASS:		*ds:si	= EntVisClass object
		ds:di	= EntVisClass instance data
		ds:bx	= EntvisClass object (same as *ds:si)
		es 	= segment of EntVisClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 5/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntVisGetEnabled	method dynamic EntVisClass, MSG_ENT_VIS_GET_ENABLED
		.enter

		mov	ax, MSG_GEN_GET_ENABLED
		call	ObjCallInstanceNoLock
		mov	ax, 0			; don't nuke flags
		adc	ax, 0			; set to 1 on carry

		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
		
		.leave
		ret
EntVisGetEnabled	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntVisSetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the enabled property for ent class

CALLED BY:	MSG_ENT_VIS_SET_ENABLED
PASS:		*ds:si	= EntVisClass object
		ds:di	= EntVisClass instance data
		ds:bx	= EntVisClass object (same as *ds:si)
		es 	= segment of EntVisClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntVisSetEnabled	method dynamic EntVisClass, MSG_ENT_VIS_SET_ENABLED
	uses	es, bx
	.enter
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	les	bx, ss:[bp].SPA_compDataPtr
	test	ds:[di].EI_state, mask ES_IS_GEN
	; FIXME, should return different error message
	jz	typeError
	mov	cx, es:[bx].CD_data.LD_integer
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	callSelfAndDone
	mov	ax, MSG_GEN_SET_ENABLED
callSelfAndDone:
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
typeError:
	mov	es:[bx].CD_type, LT_TYPE_ERROR
	mov	es:[bx].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
	jmp	done
EntVisSetEnabled	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntVisMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup some instance data so we can be correctly added to a tree
		Of course, this assumes we are gen ...

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= EntVisClass object
		ds:di	= EntVisClass instance data
		ds:bx	= EntVisClass object (same as *ds:si)
		es 	= segment of EntVisClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	6/17/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntVisMetaInitialize	method dynamic EntVisClass, 
					MSG_META_INITIALIZE
		.enter


	; For now, assume all EntClass components are based on Gen. (yuck)
	; Need to set this info in META_INITIALIZE rather than
	; ENT_INITIALIZE so that SET_PARENT will do the right thing.	
	; FIXME - this really should go away.
	;
		BitSet	ds:[di].EI_state, ES_IS_GEN

		mov	di, offset EntVisClass
		call	ObjCallSuperNoLock

		.leave
		ret
EntVisMetaInitialize	endm


