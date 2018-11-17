COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genBooleanGroup.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenBooleanGroupClass	BooleanGroup object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial version

DESCRIPTION:
	This file contains routines to implement the BooleanGroup class

	$Id: genBooleanGroup.asm,v 1.1 97/04/07 11:45:07 newdeal Exp $

------------------------------------------------------------------------------@

; see documentation in /staff/pcgeos/Library/User/Doc/GenBooleanGroup.doc
	
UserClassStructures	segment resource

; Declare the class record

	GenBooleanGroupClass


UserClassStructures	ends

;---------------------------------------------------

Build segment resource




COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenBooleanGroupClass

DESCRIPTION:	Return the correct specific class for an object

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx - master offset of variant class to build

RETURN: cx:dx - class for specific UI part of object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es
REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

GenBooleanGroupBuild	method	GenBooleanGroupClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_BOOLEAN_GROUP
	GOTO	GenQueryUICallSpecificUI

GenBooleanGroupBuild	endm


Build	ends

;
;---------------
;
		
BuildUncommon	segment	resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupReplaceParams

DESCRIPTION:	Replaces any generic instance data paramaters that match
		BranchReplaceParamType

PASS: 		*ds:si - instance data
		es - segment of MetaClass
	
		ax - MSG_GEN_BRANCH_REPLACE_PARAMS
	
		dx	- size BranchReplaceParams structure
		ss:bp	- offset to BranchReplaceParams


RETURN:		nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


GenBooleanGroupReplaceParams	method	GenBooleanGroupClass, \
					MSG_GEN_BRANCH_REPLACE_PARAMS
	cmp	ss:[bp].BRP_type, BRPT_OUTPUT_OPTR	; Replacing output OD?
	je	replaceOD		; 	branch if so
	jmp	short done

replaceOD:
					; Replace action OD if matches
					;	search OD

	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_DESTINATION
	mov	bx, offset GBGI_destination
	call	GenReplaceMatchingDWord
done:
	mov	ax, MSG_GEN_BRANCH_REPLACE_PARAMS
	mov	di, offset GenBooleanGroupClass
	GOTO	ObjCallSuperNoLock

GenBooleanGroupReplaceParams	endm


BuildUncommon ends

ItemCommon segment resource




COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupSetGroupState -- 
		MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE for GenBooleanGroupClass

DESCRIPTION:	Sets a single selection.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
		cx -- booleans to select
		dx -- booleans to set indeterminate

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupSetGroupState	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE

	mov	bx, offset GBGI_selectedBooleans
	push	cx, dx
	call	GenGetDWord			;old indeterminates in cx, 
						;old selections in dx
	mov	ax, cx				;now in ax and bp, respectively
	mov	bp, dx
	pop	cx, dx

	xchg	cx, dx				;new indeterminates in cx,
						;    selections in dx
	call	GenSetDWord			;set instance data
	
	xor	dx, bp				;changed selections in cx
	xor	cx, ax				;changed indeterminates in bp
	or	cx, dx				;anything changed now in cx
	tst	cx				;no changes, exit
	jz	exit

	call	UpdateBooleanObject
exit:
	;
	; Clear the modified flags for everyone.
	;
	clr	cx
	mov	bx, offset GBGI_modifiedBooleans
	call	GenSetWord			;clear modified state
	Destroy	ax, cx, dx, bp
	ret
GenBooleanGroupSetGroupState	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupSetGroupModifiedState -- 
		MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE for 
		GenBooleanGroupClass

DESCRIPTION:	Sets the group modified state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE

		cx	- booleans to mark as modified
		dx	- booleans to mark as not modified

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
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupSetGroupModifiedState	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE

	push	cx
	mov	ax, cx				;save set value in ax
	mov	cx, ds:[di].GBGI_modifiedBooleans
	or	cx, ax
	not	dx
	and	cx, dx
	mov	bx, offset GBGI_modifiedBooleans
	call	GenSetWord
	pop	cx
	jnc	exit				;no change, exit
	tst	cx
	jz	exit				;no modified bits set, exit
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	call	ObjCallInstanceNoLock
exit:
	ret

GenBooleanGroupSetGroupModifiedState	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupGetSelectedBooleans -- 
		MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS for 
			GenBooleanGroupClass

DESCRIPTION:	Returns selected booleans.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS

RETURN:		ax -- booleans that are selected
		carry set if none selected
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupGetSelectedBooleans	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS

	mov	ax, ds:[di].GBGI_selectedBooleans
	tst	ax
	clc					;assume non-zero, clear carry
	jnz	exit
	stc					;zero, set carry
exit:
	Destroy	cx, dx, bp
	ret
GenBooleanGroupGetSelectedBooleans	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupGetIndeterminateBooleans -- 
		MSG_GEN_BOOLEAN_GROUP_GET_INDETERMINATE_BOOLEANS for 
			GenBooleanGroupClass

DESCRIPTION:	Returns indeterminate booleans.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_GET_INDETERMINATE_BOOLEANS

RETURN:		ax -- indeterminate booleans
		carry set if none indeterminate
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupGetIndeterminateBooleans	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_GET_INDETERMINATE_BOOLEANS

	mov	ax, ds:[di].GBGI_indeterminateBooleans
	Destroy	cx, dx, bp
	ret
GenBooleanGroupGetIndeterminateBooleans	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupGetModifiedBooleans -- 
		MSG_GEN_BOOLEAN_GROUP_GET_MODIFIED_BOOLEANS for 
			GenBooleanGroupClass

DESCRIPTION:	Returns modified booleans.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_GET_MODIFIED_BOOLEANS

RETURN:		ax, 	- modified booleans
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupGetModifiedBooleans	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_GET_MODIFIED_BOOLEANS

	mov	ax, ds:[di].GBGI_modifiedBooleans
	Destroy	cx, dx, bp
	ret
GenBooleanGroupGetModifiedBooleans	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupSendStatusMsg -- 
		MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG for GenBooleanGroupClass

DESCRIPTION:	Sends off the status message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG
		cx	- bits to send as modified

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
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupSendStatusMsg	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG

	mov	ax, ATTR_GEN_BOOLEAN_GROUP_STATUS_MSG
	call	ObjVarFindData		; ds:bx = data, if found
	jnc	exit
	mov	ax, ds:[bx]		; else, fetch message
	clr	di			; don't close window!
	call	GenBooleanSendMsg
exit:
	ret
GenBooleanGroupSendStatusMsg	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupApply -- 
		MSG_GEN_APPLY for GenBooleanGroupClass

DESCRIPTION:	Sends apply message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_APPLY

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
	chris	2/25/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupApply	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_APPLY
	;
	; In general, we only apply if the boolean group is modified.
	;
	mov	ax, ds:[di].GBGI_applyMsg
	mov	cx, ds:[di].GBGI_modifiedBooleans
	tst	cx					;nothing modified, exit
	jnz	sendMsg

	;
	; Failing that, we still will send an apply message if a certain
	; attribute is set.
	;
	push	ax
	mov	ax, ATTR_GEN_SEND_APPLY_MSG_ON_APPLY_EVEN_IF_NOT_MODIFIED
	call	ObjVarFindData				;does this exist?
	pop	ax
	jc	sendMsg					;yes, send anyway
	ret
sendMsg:
	;
	; Send the apply message.
	;
	mov	di, si				;set di non-zero to allow
						; closing of windows
	call 	GenBooleanSendMsg
	;
	; Clear the modified flags.
	;
	call	IC_DerefGenDI
	clr	ds:[di].GBGI_modifiedBooleans
	ret

GenBooleanGroupApply	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	GenBooleanSendMsg

SYNOPSIS:	Sends out a notification for the GenBooleanGroup.

CALLED BY:	GenBooleanGroupSendStatusMsg, GenBooleanGroupApply

PASS:		*ds:si -- object
		ax     -- message to send
		cx     -- booleans to mark as modified
		di     -- non-zero to close window if so marked in GenAttrs

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/25/92		Initial version

------------------------------------------------------------------------------@

GenBooleanSendMsg	proc	far
	class	GenBooleanGroupClass

	tst	ax
	jz	exit			; no message, exit
	mov	bp, cx			; modified flags in bp

	mov	bx, offset GBGI_destination
	call	GenGetDWord		; destination in ^lcx:dx
	push	cx, dx			; push them for GenProcessAction

	mov	bx, offset GBGI_selectedBooleans
	call	GenGetDWord		; indeters in cx, selecteds in dx
	xchg	cx, dx			; indeters in dx, selecteds in cx
					; modifieds in bp

	tst	di			; di = 0, don't check GenAttrs
	jz	10$
	call	GenProcessGenAttrsBeforeAction
10$:
	mov	di, mask MF_FIXUP_DS
	call	GenProcessAction	; send the message
	call	GenProcessGenAttrsAfterAction
exit:
	Destroy	ax, cx, dx, bp
	ret
GenBooleanSendMsg	endp







COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupGetBooleanOptr -- 
		MSG_GEN_BOOLEAN_GROUP_GET_BOOLEAN_OPTR for GenBooleanGroupClass

DESCRIPTION:	Returns the optr for an boolean.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_GET_BOOLEAN_OPTR

		cx	- identifier

RETURN:		carry set if boolean found
		^lcx:dx - optr of boolean, or null if not found
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupGetBooleanOptr	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_GET_BOOLEAN_OPTR

	mov	bp, cx			;keep identifier in bp
	clr	cx			;start with null OD in ^lcx:dx
	mov	dx, cx	

	push	cx			;start with initial child
	push	cx			

	mov	di, offset GI_link
	push	di			;push offset to LinkPart

NOFXIP <	push	cs			;push call-back routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
		
	mov	bx, offset FindChildIdentifier
	push	bx
	mov	bx, offset Gen_offset		; Use the generic linkage
	mov	di, offset GI_comp
	call	ObjCompProcessChildren		; Go process the children
						;(DO NOT use GOTO!)
	Destroy	ax, bp
	ret
GenBooleanGroupGetBooleanOptr	endm
	   


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindChildIdentifier

DESCRIPTION:	Callback routine to find child with given identifier

CALLED BY:	GLOBAL

PASS:
	*ds:si - child
	*es:di - composite
	cx:dx  - should be null coming in 
	bp - identifier to search for

RETURN:
	cx:dx - optr if found, still zero if not

DESTROYED:
	bx, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

FindChildIdentifier	proc	far
	class	GenBooleanClass
	
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	cmp	bp, ds:[bx].GBI_identifier
	clc
	jne	exit			;skip if does not match...

;found:	;return carry set, indicating that we found the item
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	stc
exit:
	ret
FindChildIdentifier	endp



COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupSetBooleanState -- 
		MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE for GenBooleanGroupClass

DESCRIPTION:	Sets an individual boolean state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE

		cx -- identifier 
		dx -- non-zero if selected, or "true"

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupSetBooleanState	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE

	mov	bx, offset GBGI_selectedBooleans
	push	cx				;save passed ID
	call	SetBooleanState
	jnc	exit

	mov	cx, ax				;pass identifier to spec UI
	call	UpdateBooleanObject
exit:
	;
	; Clear the modified flag for the passed identifier.
	;
	mov	bx, offset GBGI_modifiedBooleans
	call	BooleanGetWord			;clear modified state
	pop	ax				;restore passed identifier
	not	ax
	and	cx, ax				;clear identifier's bit
	call	GenSetWord			
	Destroy	ax, cx, dx, bp
	ret
GenBooleanGroupSetBooleanState	endm


;------------------------------------------------------------






COMMENT @----------------------------------------------------------------------

ROUTINE:	SetBooleanState

SYNOPSIS:	Sets a bit in a word of state.

CALLED BY:	GenBooleanGroupSetBooleanState, 
		GenBooleanGroupSetBooleanModifiedState

PASS:		*ds:si -- GenBoolean
		bx -- offset in GenInstance to word to change
		cx -- bit to change
		dx -- non-zero to set, zero to clear

RETURN:		carry set if anything changed
		cx -- new value set
		ax -- item identifier

DESTROYED:	cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 1/93       	Initial version

------------------------------------------------------------------------------@

SetBooleanState	proc	near
	mov	ax, cx				;move identifier to ax
	call	BooleanGetWord			;gets state in cx
	tst	dx
	jz	deselectBoolean
	or	cx, ax				;select, or with identifier
	jmp	short finish
	
deselectBoolean:
	push	ax
	not	ax				;deselect, and with ~identifier
	and	cx, ax
	pop	ax
finish:
	call	GenSetWord			;set new state, if any
	ret
SetBooleanState	endp

BooleanGetWord	proc	far
	class	GenClass
	push	si
	mov	si, ds:[si]		; point at instance
	add	si, ds:[si].Gen_offset	; get offset to Gen master part
	mov	cx, ds:[si][bx]
	pop	si
	ret
BooleanGetWord	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateBooleanObject

SYNOPSIS:	Calls specific incarnation to update itself.

CALLED BY:	utility

PASS:		*ds:si -- GenBooleanGroup object
		cx    -- booleans to update

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/27/92		Initial version

------------------------------------------------------------------------------@

UpdateBooleanObject	proc	near
	mov	ax, MSG_SPEC_UPDATE_SPECIFIC_OBJECT
	call	GenCallSpecIfGrown
	ret
UpdateBooleanObject	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupSetBooleanIndeterminateState -- 
		MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_INDETERMINATE_STATE 
		for GenBooleanGroupClass

DESCRIPTION:	Sets an individual boolean state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_INDETERMINATE_STATE

		cx -- identifier 
		dx -- non-zero if indeterminate

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupSetBooleanIndeterminateState method dynamic GenBooleanGroupClass,
		 MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_INDETERMINATE_STATE

	mov	bx, offset GBGI_indeterminateBooleans
	push	cx				;save passed ID
	call	SetBooleanState
	jnc	exit

	;
	; This all added 2/ 9/93 cbh so that setting indeterminate state 
	; updates correctly.
	;
	mov	cx, ax				;pass identifier to spec UI
	call	UpdateBooleanObject
exit:
	;
	; Clear the modified flag for the passed identifier.
	;
	mov	bx, offset GBGI_modifiedBooleans
	call	BooleanGetWord			;clear modified state
	pop	ax				;restore passed identifier
	not	ax
	and	cx, ax				;clear identifier's bit
	call	GenSetWord			
	Destroy	ax, cx, dx, bp
	ret

GenBooleanGroupSetBooleanIndeterminateState	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupSetBooleanModifiedState -- 
		MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_MODIFIED_STATE 
		for GenBooleanGroupClass

DESCRIPTION:	Sets an individual boolean state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_MODIFIED_STATE

		cx -- identifier 
		dx -- non-zero if modified

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupSetBooleanModifiedState	method dynamic	GenBooleanGroupClass, \
			MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_MODIFIED_STATE

	mov	bx, offset GBGI_modifiedBooleans
	call	SetBooleanState
	jnc	exit

	;
	; Code added 2/ 1/93 cbh to make the dialog box applyable.
	;
	tst	cx
	jz	exit
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	call	ObjCallInstanceNoLock
exit:
	ret

GenBooleanGroupSetBooleanModifiedState	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupIsBooleanSelected -- 
		MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED for GenBooleanGroupClass

DESCRIPTION:	Returns whether boolean is selected.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED

		cx -- identifier of boolean to check on

RETURN:		carry set if boolean is selected
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupIsBooleanSelected	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	and	cx, ds:[di].GBGI_selectedBooleans

IsBooleanSelected	label	far
	jz	exit
	stc
exit:
	Destroy	ax, cx, dx, bp
	ret
GenBooleanGroupIsBooleanSelected	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupIsBooleanIndeterminate -- 
		MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_INDETERMINATE for GenBooleanGroupClass

DESCRIPTION:	Returns whether boolean is indeterminate.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_INDETERMINATE

		cx -- identifier of boolean to check on

RETURN:		carry set if boolean is indeterminate
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupIsBooleanIndeterminate	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_INDETERMINATE

	and	cx, ds:[di].GBGI_indeterminateBooleans
	GOTO	IsBooleanSelected

GenBooleanGroupIsBooleanIndeterminate	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupIsBooleanModified -- 
		MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_MODIFIED for GenBooleanGroupClass

DESCRIPTION:	Returns whether boolean is modified.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_MODIFIED

		cx -- identifier of boolean to check on

RETURN:		carry set if boolean is modified
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupIsBooleanModified	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_MODIFIED

	and	cx, ds:[di].GBGI_modifiedBooleans
	GOTO	IsBooleanSelected

GenBooleanGroupIsBooleanModified	endm







COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupGetDestination -- 
		MSG_GEN_BOOLEAN_GROUP_GET_DESTINATION for GenBooleanGroupClass

DESCRIPTION:	Returns the destination.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_GET_DESTINATION

RETURN:		^lcx:dx - destination
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupGetDestination	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_GET_DESTINATION

	mov	bx, offset GBGI_destination
	call	GenGetDWord
	Destroy	ax, bp
	ret
GenBooleanGroupGetDestination	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupSetDestination -- 
		MSG_GEN_BOOLEAN_GROUP_SET_DESTINATION for GenBooleanGroupClass

DESCRIPTION:	Sets a new destination.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_SET_DESTINATION

		^lcx:dx - destination

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
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupSetDestination	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_SET_DESTINATION
	mov	bx, offset GBGI_destination
	call	GenSetDWord
	Destroy	ax, cx, dx, bp
	ret
GenBooleanGroupSetDestination	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupGetApplyMsg -- 
		MSG_GEN_BOOLEAN_GROUP_GET_APPLY_MSG for GenBooleanGroupClass

DESCRIPTION:	Returns apply message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_GET_APPLY_MSG

RETURN:		ax 	- current apply message
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupGetApplyMsg	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_GET_APPLY_MSG

	mov	ax, ds:[di].GBGI_applyMsg
	Destroy	cx, dx, bp
	ret
GenBooleanGroupGetApplyMsg	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupSetApplyMsg -- 
		MSG_GEN_BOOLEAN_GROUP_SET_APPLY_MSG for GenBooleanGroupClass

DESCRIPTION:	Sets a new apply message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_SET_APPLY_MSG

		cx	- new apply message

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
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupSetApplyMsg	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_SET_APPLY_MSG
	mov	bx, offset GBGI_applyMsg
	call	GenSetWord
	Destroy	ax, cx, dx, bp
	ret
GenBooleanGroupSetApplyMsg	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanGroupMakeBooleanVisible -- 
		MSG_GEN_BOOLEAN_GROUP_MAKE_BOOLEAN_VISIBLE for 
		GenBooleanGroupClass

DESCRIPTION:	Ensures that the passed boolean is visible.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BOOLEAN_GROUP_MAKE_BOOLEAN_VISIBLE
		cx	- boolean

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
	chris	4/23/92		Initial Version

------------------------------------------------------------------------------@

GenBooleanGroupMakeBooleanVisible	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_BOOLEAN_GROUP_MAKE_BOOLEAN_VISIBLE
	;
	; Specific UI object can only deal with GenItemGroup messages.
	;
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	call	GenCallSpecIfGrown
	ret
GenBooleanGroupMakeBooleanVisible	endm


ItemCommon ends

IniFile segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:  GenBooleanGroupLoadOptions -- MSG_GEN_LOAD_OPTIONS for GenBooleanGroupClass

DESCRIPTION:	Load options from .ini file

PASS:
	*ds:si - instance data
	es - segment of GenBooleanGroupClass

	ax - The message

	ss:bp - GenOptionsParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
GenBooleanGroupLoadOptions	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_LOAD_OPTIONS

	mov	dx, ds:[di].GBGI_selectedBooleans	;dx = current

	mov	ax, ATTR_GEN_BOOLEAN_GROUP_INIT_FILE_BOOLEAN
	call	ObjVarFindData			;carry set for boolean
	call	GenOptGetInteger		;ax = value
	mov_tr	cx, ax				;cx = data
	jc	done

	xor	dx, cx				;dx = modified booleans
	jz	done

	push	dx				;save modified booleans
	clr	dx				;no indeterminates
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjCallInstanceNoLock

	pop	cx				;cx = modified booleans
	push	cx				;save modified booleans
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
	call	ObjCallInstanceNoLock
	pop	cx				;cx = modified booleans
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_APPLY
	call	ObjCallInstanceNoLock
done:
	ret

GenBooleanGroupLoadOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenBooleanGroupSaveOptions -- MSG_GEN_SAVE_OPTIONS for GenBooleanGroupClass

DESCRIPTION:	Save our options

PASS:
	*ds:si - instance data
	es - segment of GenBooleanGroupClass

	ax - The message

	ss:bp - GenOptionsParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
GenBooleanGroupSaveOptions	method dynamic	GenBooleanGroupClass, \
				MSG_GEN_SAVE_OPTIONS

	push	bp				; GenOptionsParams
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	ObjCallInstanceNoLock		;ax = value
	pop	bp				; GenOptionsParams

	push	ax
	mov	ax, ATTR_GEN_BOOLEAN_GROUP_INIT_FILE_BOOLEAN
	call	ObjVarFindData
	pop	ax
	call	GenOptWriteInteger
	ret
GenBooleanGroupSaveOptions	endm


IniFile ends
