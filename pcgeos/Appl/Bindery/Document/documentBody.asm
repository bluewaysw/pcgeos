COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentBody.asm

ROUTINES:
	Name			Description
	----			-----------
    INT SendUpToDocument	Send a message upwards to the document

    INT MessageToBodysRuler	Send a message to the master page
				associcated with this grobj body

    INT GraphicsInSpaceCallback Determine if the given graphic object is in
				the space passed

    INT MakeContentEditable	Make the content editable

    INT BodyToAllTOCallback	Send message to object if it is a text
				object

METHODS:
	Name			Description
	----			-----------
    StudioGrObjBodyVupCallObjectOfClass  
				Call object in class

				MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
				StudioGrObjBodyClass

    StudioGrObjBodyNotification	Handle notification that a grobj object has
				changed

				MSG_GROBJ_ACTION_NOTIFICATION
				StudioGrObjBodyClass

    StudioGrObjBodySetDocBounds	Handle a message to this grobj layer to set
				the document bounds (ignore this since we
				set bounds differently)

				MSG_VIS_LAYER_SET_DOC_BOUNDS
				StudioGrObjBodyClass

    StudioMasterPageGrObjBodyVupCallObjectOfClass  
				Call object in class

				MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
				StudioMasterPageGrObjBodyClass

    StudioGrObjBodyDraw		Draw the body

				MSG_VIS_DRAW
				StudioGrObjBodyClass

    StudioGrObjBodyGetFlags	Get the StudioGrObjBodyFlags

				MSG_STUDIO_GROBJ_BODY_GET_FLAGS
				StudioGrObjBodyClass

    StudioGrObjBodyGraphicsInSpace  
				Determine if there are any graphics in the
				given space

				MSG_STUDIO_GROBJ_BODY_GRAPHICS_IN_SPACE
				StudioGrObjBodyClass

    StudioGrObjBodyGetObjectForSearchSpell  
				Get the next object for search/spell

				MSG_META_GET_OBJECT_FOR_SEARCH_SPELL
				StudioGrObjBodyClass

    StudioGrObjMasterPageBodyDisplayObjectForSearchSpell  
				Display this body

				MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL
				StudioMasterPageGrObjBodyClass

    StudioGrObjBodyDisplayObjectForSearchSpell  
				Display this body

				MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL
				StudioGrObjBodyClass

    StudioGrObjBodyClassAbortSearchSpellMessage  
				Handle "abort" search/spell by passing it
				to the article

				MSG_GB_ABORT_SEARCH_SPELL_MESSAGE
				StudioGrObjBodyClass

    StudioMasterPageGrObjBodySuspend  
				When a master page body is suspended we
				want to notify the document so that flow
				region recalculation is suspended

				MSG_META_SUSPEND
				StudioMasterPageGrObjBodyClass

    StudioMasterPageGrObjBodyUnsuspend  
				When a master page body is suspended we
				want to notify the document so that flow
				region recalculation is suspended

				MSG_META_UNSUSPEND
				StudioMasterPageGrObjBodyClass

    StudioGrObjBodySendToAllTextObjects  
				Send a message to all text objects

				MSG_STUDIO_GROBJ_BODY_SEND_TO_ALL_TEXT_OBJECTS
				StudioGrObjBodyClass

    StudioGrObjBodyFupKbdChar
				Don't call superclass, as we don't 
				want to support any keyboard shortcuts.

				MSG_META_FUP_KBD_CHAR
				StudioGrObjBodyClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the code for StudioGrObjBodyClass

	$Id: documentBody.asm,v 1.1 97/04/04 14:38:46 newdeal Exp $

------------------------------------------------------------------------------@

idata segment
	StudioGrObjBodyClass
	StudioMasterPageGrObjBodyClass
idata ends

DocCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjBodyVupCallObjectOfClass --
		MSG_VIS_VUP_CALL_OBJECT_OF_CLASS for StudioGrObjBodyClass

DESCRIPTION:	Call object in class

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjBodyClass

	ax - The message

	cx - message

RETURN:
	from message

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/16/92		Initial version

------------------------------------------------------------------------------@
StudioGrObjBodyVupCallObjectOfClass	method dynamic StudioGrObjBodyClass,
					MSG_VIS_VUP_CALL_OBJECT_OF_CLASS

	; do we have a vis parent -- if so then just do the usual stuff

	add	bx, ds:[bx].Vis_offset
	tst	ds:[bx].VI_link.LP_next.handle
	jnz	sendToSuper

	; if the message is destined for the document then help it along

	push	ax, cx, si
	mov	bx, cx
	call	ObjGetMessageInfo		;cx:si = class
	cmp	cx, segment GenDocumentClass
	jnz	10$
	cmp	si, offset GenDocumentClass
10$:
	pop	ax, cx, si

	jnz	sendToSuper

	push	ax, cx
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo			;ax = VM file
	mov_tr	cx, ax

	GetResourceHandleNS	StudioDocGroup, bx
	mov	si, offset StudioDocGroup
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DOC_BY_FILE
	mov	di, mask MF_CALL
	call	ObjMessage			;cx:dx = document
	movdw	bxsi, cxdx			;bx:si = document
	pop	ax, cx

	mov	di, mask MF_CALL
	GOTO	ObjMessage

sendToSuper:
	mov	di, offset StudioGrObjBodyClass
	GOTO	ObjCallSuperNoLock

StudioGrObjBodyVupCallObjectOfClass	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjBodyNotification -- MSG_STUDIO_GROBJ_BODY_NOTIFICATION
						for StudioGrObjBodyClass

DESCRIPTION:	Handle notification that a grobj object has changed

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjBodyClass

	ax - The message

	cx:dx  - grobj object
	bp - GrObjActionNotificationType

RETURN:
	bp - data depening on the type

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/16/92		Initial version

------------------------------------------------------------------------------@
StudioGrObjBodyNotification	method dynamic	StudioGrObjBodyClass,
					MSG_GROBJ_ACTION_NOTIFICATION

	tst	es:[suspendNotification]
	jnz	done

	; is this a master page ?

	clr	bx				;bx = paramter -- assume main
	push	di
	mov	di, offset StudioMasterPageGrObjBodyClass
	call	ObjIsObjectInClass
	pop	di
	jnc	notMasterPage
	mov	bx, ds:[LMBH_handle]
	call	VMMemBlockToVMBlock		;ax = block
	mov_tr	bx, ax
notMasterPage:

	mov	ax, MSG_STUDIO_DOCUMENT_GROBJ_PRE_WRAP_NOTIFICATION
	cmp	bp, GOANT_PRE_WRAP_CHANGE
	jz	gotMessage
	mov	ax, MSG_STUDIO_DOCUMENT_GROBJ_WRAP_NOTIFICATION
	cmp	bp, GOANT_WRAP_CHANGED
	jnz	done
gotMessage:

	mov	bp, bx				;bp = parameter
	ornf	ds:[di].SGOBI_flags, mask SGOBF_WRAP_AREA_NON_NULL
	call	SendUpToDocument
done:
	ret

StudioGrObjBodyNotification	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendUpToDocument

DESCRIPTION:	Send a message upwards to the document

CALLED BY:	INTERNAL

PASS:
	*ds:si - object in the vistree under the document

RETURN:
	none

DESTROYED:
	ax, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/19/92		Initial version

------------------------------------------------------------------------------@
SendUpToDocument	proc	far

	push	si
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si
	mov	cx, di
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock
	ret

SendUpToDocument	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjBodySetDocBounds -- MSG_VIS_LAYER_SET_DOC_BOUNDS
						for StudioGrObjBodyClass

DESCRIPTION:	Handle a message to this grobj layer to set the document
		bounds (ignore this since we set bounds differently)

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjBodyClass

	ax - The message

	ss:bp - RectDWord structure

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/12/92		Initial version

------------------------------------------------------------------------------@
StudioGrObjBodySetDocBounds	method dynamic	StudioGrObjBodyClass,
						MSG_VIS_LAYER_SET_DOC_BOUNDS
	ret

StudioGrObjBodySetDocBounds	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioMasterPageGrObjBodyVupCallObjectOfClass --
		MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
					for StudioMasterPageGrObjBodyClass

DESCRIPTION:	Call object in class

PASS:
	*ds:si - instance data
	es - segment of StudioMasterPageGrObjBodyClass

	ax - The message

	cx - message

RETURN:
	from message

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/16/92		Initial version

------------------------------------------------------------------------------@
StudioMasterPageGrObjBodyVupCallObjectOfClass	method dynamic \
					StudioMasterPageGrObjBodyClass,
					MSG_VIS_VUP_CALL_OBJECT_OF_CLASS

	; if the message is destined for the document then send in via the
	; main grobj body

	push	ax, cx, si
	mov	bx, cx
	call	ObjGetMessageInfo		;cx:si = class
	cmp	cx, segment GenDocumentClass
	jnz	10$
	cmp	si, offset GenDocumentClass
10$:
	pop	ax, cx, si

	jnz	notDocument

	push	ax
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo			;ax = VM file
	mov_tr	bx, ax
	mov	ax, ds:[di].SMPGOBI_mainGrobjBody	;ax = main body block
	call	VMVMBlockToMemBlock		;ax = memory block of main body
	mov_tr	bx, ax
	pop	ax

	mov	si, offset MainBody
	mov	di, mask MF_CALL
	GOTO	ObjMessage

notDocument:
	mov	di, offset StudioMasterPageGrObjBodyClass
	GOTO	ObjCallSuperNoLock

StudioMasterPageGrObjBodyVupCallObjectOfClass	endm

DocCommon ends

DocDrawScroll segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjBodyDraw -- MSG_VIS_DRAW for StudioGrObjBodyClass

DESCRIPTION:	Draw the body

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjBodyClass

	ax - The message

	cl - DrawFlags (DF_EXPOSED set if exposed), DF_PRINT
	bp - gstate

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/23/92		Initial version

------------------------------------------------------------------------------@
StudioGrObjBodyDraw	method dynamic	StudioGrObjBodyClass, MSG_VIS_DRAW

	test	cl, mask DF_PRINT
	jnz	skipAadornments

	mov	di, bp

	mov	ax, SDM_50 or mask SDM_INVERSE
	call	GrSetLineMask

	mov	ax, C_LIGHT_BLUE
	call	GrSetLineColor


	call	GrGetLineColorMap
	push	ax

	mov	al, CMT_CLOSEST
	call	GrSetLineColorMap

	mov	ax, MSG_VIS_RULER_DRAW_GRID
	call	MessageToBodysRuler

	mov	ax, C_LIGHT_RED
	call	GrSetLineColor

	mov	ax, MSG_VIS_RULER_DRAW_GUIDES
	call	MessageToBodysRuler

	pop	ax
	call	GrSetLineColorMap

	mov	ax, SDM_100
	call	GrSetLineMask

skipAadornments:
	mov	ax, MSG_VIS_DRAW
	mov	di, offset StudioGrObjBodyClass
	GOTO	ObjCallSuperNoLock

StudioGrObjBodyDraw	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	MessageToBodysRuler

DESCRIPTION:	Send a message to the master page associcated with this
		grobj body

CALLED BY:	INTERNAL

PASS:
	*ds:si - grobj body
	ax - message
	cx, dx, bp - data

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/23/92		Initial version

------------------------------------------------------------------------------@
MessageToBodysRuler	proc	near	uses bx, si, di, es
	.enter

	call	VisSwapLockParent		;*ds:si = content
	push	bx

	call	StudioGetDGroupES
	mov	di, offset StudioMasterPageContentClass
	call	ObjIsObjectInClass
	jc	masterPage
	call	MessageToRuler
	jmp	done

masterPage:
	call	MessageToMPRuler

done:
	pop	bx
	call	ObjSwapUnlock

	.leave
	ret

MessageToBodysRuler	endp

DocDrawScroll ends

DocPageCreDest segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjBodyGetFlags -- MSG_STUDIO_GROBJ_BODY_GET_FLAGS
							for StudioGrObjBodyClass

DESCRIPTION:	Get the StudioGrObjBodyFlags

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjBodyClass

	ax - The message

RETURN:
	ax - StudioGrObjBodyFlags

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/17/92		Initial version

------------------------------------------------------------------------------@
StudioGrObjBodyGetFlags	method dynamic	StudioGrObjBodyClass,
						MSG_STUDIO_GROBJ_BODY_GET_FLAGS
	mov	ax, ds:[di].SGOBI_flags
	ret

StudioGrObjBodyGetFlags	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjBodyGraphicsInSpace --
		MSG_STUDIO_GROBJ_BODY_GRAPHICS_IN_SPACE for StudioGrObjBodyClass

DESCRIPTION:	Determine if there are any graphics in the given space

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjBodyClass

	ax - The message

	ss:bp - StudioGrObjBodyGraphicsInSpaceParams

RETURN:
	carry - set if there are any graphics (other that flow regions)
		in the space

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/28/92		Initial version

------------------------------------------------------------------------------@
StudioGrObjBodyGraphicsInSpace	method dynamic	StudioGrObjBodyClass,
				MSG_STUDIO_GROBJ_BODY_GRAPHICS_IN_SPACE

	mov	bx, cs
	mov	di, offset GraphicsInSpaceCallback
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon

	ret

StudioGrObjBodyGraphicsInSpace	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	GraphicsInSpaceCallback

DESCRIPTION:	Determine if the given graphic object is in the space passed

CALLED BY:	INTERNAL

PASS:
	*ds:si - graphic object
	*es:di - body
	ss:bp - StudioGrObjBodyGraphicsInSpaceParams

RETURN:
	carry - set if graphic is in the space

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/28/92		Initial version

------------------------------------------------------------------------------@
GraphicsInSpaceCallback	proc	far

	; there are several classes that we don't want to look for

	GetResourceSegmentNS	dgroup, es
	mov	cx, length ignoreClassTable
	mov	bx, offset ignoreClassTable
ignoreLoop:
	mov	di, cs:[bx]
	call	ObjIsObjectInClass		;carry set if class matches
	cmc					;carry clear if class matches
	jnc	exit
	add	bx, size nptr
	loop	ignoreLoop


	mov	bx, bp

	; get the object's bounds

	sub	sp, size RectDWord
	mov	bp, sp
	mov	ax, MSG_GO_GET_DW_PARENT_BOUNDS
	call	ObjCallInstanceNoLock

	movdw	dxax, ss:[bx].SGBGISP_position
	cmpdw	dxax, ss:[bp].RD_bottom
	jae	outside
	adddw	dxax, ss:[bx].SGBGISP_size
	cmpdw	dxax, ss:[bp].RD_top
	jbe	outside

	stc
done:
	lahf
	add	sp, size RectDWord
	sahf
	mov	bp, bx
exit:
	ret

outside:
	clc
	jmp	done

GraphicsInSpaceCallback	endp

ignoreClassTable	nptr	\
	FlowRegionClass

DocPageCreDest ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjBodyGetObjectForSearchSpell --
		MSG_META_GET_OBJECT_FOR_SEARCH_SPELL for StudioGrObjBodyClass

DESCRIPTION:	Get the next object for search/spell

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjBodyClass

	ax - The message

	cx:dx - object that search/spell is currently in
	bp - GetSearchSpellObjectOption

RETURN:
	cx:dx - requested object (or 0 if none)

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/19/92		Initial version

------------------------------------------------------------------------------@
StudioGrObjBodyGetObjectForSearchSpell	method dynamic	StudioGrObjBodyClass,
					MSG_META_GET_OBJECT_FOR_SEARCH_SPELL

	test	bp, mask GSSOP_RELAYED_FLAG
	jz	sendToDocument

	and	bp, not mask GSSOP_RELAYED_FLAG
	mov	di, offset StudioGrObjBodyClass
	GOTO	ObjCallSuperNoLock

sendToDocument:

	; let the document take care of it

	call	SendUpToDocument
	ret

StudioGrObjBodyGetObjectForSearchSpell	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjMasterPageBodyDisplayObjectForSearchSpell --
		MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL
					for StudioGrObjMasterPageBodyClass

DESCRIPTION:	Display this body

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjMasterPageBodyClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/19/92		Initial version

------------------------------------------------------------------------------@
StudioGrObjMasterPageBodyDisplayObjectForSearchSpell	method dynamic	\
				StudioMasterPageGrObjBodyClass,
				MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL

	mov	cx, ds:[LMBH_handle]
	mov	ax, MSG_STUDIO_DOCUMENT_OPEN_MASTER_PAGE
	call	SendUpToDocument
	ret

StudioGrObjMasterPageBodyDisplayObjectForSearchSpell	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjBodyDisplayObjectForSearchSpell --
		MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL
					for StudioGrObjBodyClass

DESCRIPTION:	Display this body

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjBodyClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/19/92		Initial version

------------------------------------------------------------------------------@
StudioGrObjBodyDisplayObjectForSearchSpell	method dynamic	\
				StudioGrObjBodyClass,
				MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL

	call	MakeContentEditable
	ret

StudioGrObjBodyDisplayObjectForSearchSpell	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjBodyClassAbortSearchSpellMessage --
		MSG_GB_ABORT_SEARCH_SPELL_MESSAGE for StudioGrObjBodyClass

DESCRIPTION:	Handle "abort" search/spell by passing it to the article

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjBodyClass

	ax - The message

	cx - message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/15/92		Initial version

------------------------------------------------------------------------------@
StudioGrObjBodyClassAbortSearchSpellMessage	method dynamic	\
					StudioGrObjBodyClass,
					MSG_GB_ABORT_SEARCH_SPELL_MESSAGE

	push	cx, si
	mov	bx, cx
	call	ObjGetMessageInfo		;ax = message, cx:si = dest
	pop	cx, si

	cmp	ax, MSG_REPLACE_CURRENT
	jz	toSuper
	cmp	ax, MSG_REPLACE_ALL_OCCURRENCES_IN_SELECTION
	jz	toSuper

	push	cx, si
	mov	cx, es
	mov	si, offset StudioArticleClass
	call	MessageSetDestination
	pop	cx, si
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_TARGET
	call	GenCallApplication
	ret

toSuper:
	mov	ax, MSG_GB_ABORT_SEARCH_SPELL_MESSAGE
	mov	di, offset StudioGrObjBodyClass
	GOTO	ObjCallSuperNoLock

StudioGrObjBodyClassAbortSearchSpellMessage	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	MakeContentEditable

DESCRIPTION:	Make the content editable

CALLED BY:	INTERNAL

PASS:
	*ds:si - object in vis tree under a content

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/20/92		Initial version

------------------------------------------------------------------------------@
MakeContentEditable	proc	near

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	sendUpwardToDisplay

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	sendUpwardToDisplay

	mov	ax, MSG_GEN_BRING_TO_TOP
	call	sendUpwardToDisplay

	ret

;---

sendUpwardToDisplay:
	push	si
	mov	bx, segment GenDisplayClass
	mov	si, offset GenDisplayClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si
	mov	cx, di
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock
	retn

MakeContentEditable	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioMasterPageGrObjBodySuspend -- MSG_META_SUSPEND
					for StudioMasterPageGrObjBodyClass

DESCRIPTION:	When a master page body is suspended we want to notify
		the document so that flow region recalculation is suspended

PASS:
	*ds:si - instance data
	es - segment of StudioMasterPageGrObjBodyClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/22/93		Initial version

------------------------------------------------------------------------------@
StudioMasterPageGrObjBodySuspend	method dynamic	StudioMasterPageGrObjBodyClass,
						MSG_META_SUSPEND

	mov	di, offset StudioMasterPageGrObjBodyClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_STUDIO_DOCUMENT_MP_BODY_SUSPEND
	call	SendUpToDocument

	ret

StudioMasterPageGrObjBodySuspend	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioMasterPageGrObjBodyUnsuspend -- MSG_META_UNSUSPEND
					for StudioMasterPageGrObjBodyClass

DESCRIPTION:	When a master page body is suspended we want to notify
		the document so that flow region recalculation is suspended

PASS:
	*ds:si - instance data
	es - segment of StudioMasterPageGrObjBodyClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/22/93		Initial version

------------------------------------------------------------------------------@
StudioMasterPageGrObjBodyUnsuspend method dynamic StudioMasterPageGrObjBodyClass,
						MSG_META_UNSUSPEND

	push	ax
	mov	ax, MSG_STUDIO_DOCUMENT_MP_BODY_UNSUSPEND
	call	SendUpToDocument
	pop	ax

	mov	di, offset StudioMasterPageGrObjBodyClass
	GOTO	ObjCallSuperNoLock

StudioMasterPageGrObjBodyUnsuspend	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioGrObjBodyFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignore keypresses (except for delete, which was handled
		by MSG_META_KBD_CHAR which called this message).

CALLED BY:	MSG_META_FUP_KBD_CHAR
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioGrObjBodyClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioGrObjBodyFupKbdChar		method dynamic StudioGrObjBodyClass,
						MSG_META_FUP_KBD_CHAR
		ret
StudioGrObjBodyFupKbdChar		endm

DocSTUFF ends

DocMerge segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjBodySendToAllTextObjects --
		MSG_STUDIO_GROBJ_BODY_SEND_TO_ALL_TEXT_OBJECTS
					for StudioGrObjBodyClass

DESCRIPTION:	Send a message to all text objects

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjBodyClass

	ax - The message

	bp - text object

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 7/93		Initial version

------------------------------------------------------------------------------@
StudioGrObjBodySendToAllTextObjects	method dynamic	\
				StudioGrObjBodyClass,
				MSG_STUDIO_GROBJ_BODY_SEND_TO_ALL_TEXT_OBJECTS

	mov	bx, cs
	mov	di, offset BodyToAllTOCallback
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon

	ret

StudioGrObjBodySendToAllTextObjects	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	BodyToAllTOCallback

DESCRIPTION:	Send message to object if it is a text object 

CALLED BY:	INTERNAL

PASS:
	*ds:si - grobj object
	bp - message

RETURN:
	carry - clear

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 7/93		Initial version

------------------------------------------------------------------------------@
BodyToAllTOCallback	proc	far

	mov	di, segment TextGuardianClass
	mov	es, di
	mov	di, offset TextGuardianClass
	call	ObjIsObjectInClass
	jnc	done

	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	call	ObjCallInstanceNoLock			;cx:dx = ward
	mov	si, dx					;cx:si = object
	mov	bx, bp
	call	MessageSetDestination
	mov	di, mask MF_RECORD			;don't free
	call	MessageDispatch

done:
	clc
	ret

BodyToAllTOCallback	endp

DocMerge ends
