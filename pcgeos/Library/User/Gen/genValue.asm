COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		GenValue.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenValueClass		Value object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/92		Initial version

DESCRIPTION:
	This file contains routines to implement the value class


	$Id: genValue.asm,v 1.1 97/04/07 11:45:34 newdeal Exp $

------------------------------------------------------------------------------@
	
UserClassStructures	segment resource

; Declare the class record

	GenValueClass

UserClassStructures	ends

;---------------------------------------------------

Build segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenValueBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenValueClass

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

GenValueBuild	method	GenValueClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_VALUE
	GOTO	GenQueryUICallSpecificUI

GenValueBuild	endm

Build ends


		
BuildUncommon	segment	resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenValueReplaceParams

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


GenValueReplaceParams	method	GenValueClass, \
					MSG_GEN_BRANCH_REPLACE_PARAMS
	cmp	ss:[bp].BRP_type, BRPT_OUTPUT_OPTR	; Replacing output OD?
	je	replaceOD		; 	branch if so
	jmp	short done

replaceOD:
					; Replace action OD if matches
					;	search OD

	mov	ax, MSG_GEN_VALUE_SET_DESTINATION
	mov	bx, offset GVLI_destination
	call	GenReplaceMatchingDWord
done:
	mov	ax, MSG_GEN_BRANCH_REPLACE_PARAMS
	mov	di, offset GenValueClass
	GOTO	ObjCallSuperNoLock

GenValueReplaceParams	endm


BuildUncommon ends

Value	segment	resource




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetIntegerValue -- 
		MSG_GEN_VALUE_SET_INTEGER_VALUE for GenValueClass

DESCRIPTION:	Sets an integer value for the range.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_INTEGER_VALUE

		cx	- integer value to set
		bp	- indeterminate flag

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetIntegerValue	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SET_INTEGER_VALUE

	mov	ax, MSG_GEN_VALUE_SET_VALUE
	mov	dx, cx				;set up as a WWFixed in dx.cx
	clr	cx
	FALL_THRU	GenValueSetValue

GenValueSetIntegerValue	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetValue -- 
		MSG_GEN_VALUE_SET_VALUE for GenValueClass

DESCRIPTION:	Sets a new value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_VALUE

		dx.cx 	- WWFixed value to set.
		bp	- indeterminate flag

RETURN:		carry set if value or indeterminate state changed
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetValue	method GenValueClass, MSG_GEN_VALUE_SET_VALUE
	call	KeepInRange			;adjust for mins and maxes

	clr	di
	mov	bx, offset GVLI_value
	xchg	cx, dx				;pass in cx.dx
	call	GenSetDWord			;set the thing
	jnc	10$
	inc	di
10$:	
	clr	cx				;clear out of date flag
	mov	dl, mask GVSF_OUT_OF_DATE
	mov	bx, offset GVLI_stateFlags
	call	GenSetBitInByte
	jnc	15$
	inc	di
15$:
	mov	cx, bp				;set indeterminate state
	mov	bx, offset GVLI_stateFlags
	mov	dl, mask GVSF_INDETERMINATE
	call	GenSetBitInByte
	jnc	20$
	inc	di
20$:
	clr	cx				;clear modified state
	mov	bx, offset GVLI_stateFlags
	mov	dl, mask GVSF_MODIFIED
	call	GenSetBitInByte

	push	di
	;
	; After setting instance data, always update the specific object
	; regardless of a generic state change (there may have been a textual
	; state change anyway).
	;			
	call	GenCallSpecIfGrown		
	pop	di
	or	di, di				;see if anything changed
	jz	exit				;no, exit (C=0)
	stc					;else return carry set
exit:	
	ret
GenValueSetValue	endm






COMMENT @----------------------------------------------------------------------

METHOD:		GenValueGetValue -- 
		MSG_GEN_VALUE_GET_VALUE for GenValueClass

DESCRIPTION:	Returns a value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_VALUE

RETURN:		dx.cx	- value
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/29/92		Initial Version

------------------------------------------------------------------------------@

GenValueGetValue	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_GET_VALUE

	call	GenCallSpecIfGrown		;make sure up-to-date

	call	Value_DerefGenDI
	movdw	dxcx, ds:[di].GVLI_value
	Destroy	ax, bp
	ret
GenValueGetValue	endm






COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetMinimum -- 
		MSG_GEN_VALUE_SET_MINIMUM for GenValueClass

DESCRIPTION:	Sets the minimum value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_MINIMUM
		dx.cx	- new minimum

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetMinimum	method dynamic	GenValueClass, MSG_GEN_VALUE_SET_MINIMUM
	mov	bx, offset GVLI_minimum

SetMinMax		label 	far
	xchg	cx, dx				;make cx:dx
	call	GenSetDWord			;set the thing
	jnc	exit				;no change, exit

RedoValueForMinMax	label	far
	push	ax				;save message
	call	Value_DerefGenDI	
	movdw	dxcx, ds:[di].GVLI_value	;get current value
	call	KeepInRange			;keep in bounds

	mov	bp, {word} ds:[di].GVLI_stateFlags	
	push	bp				;save current modified flag
	and	bp, mask GVSF_INDETERMINATE	;pass non-zero if indeterminate

	mov	ax, MSG_GEN_VALUE_SET_VALUE	;reset it
	call	ObjCallInstanceNoLock

	call	Value_DerefGenDI
	pop	ax
	mov	ds:[di].GVLI_stateFlags, al	;restore modified flag

	pop	ax				;restore message
	call	GenCallSpecIfGrown		;allow specific object to resize

exit:
	ret
GenValueSetMinimum	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	KeepInRange

SYNOPSIS:	Keep within minimum and maximum.

CALLED BY:	GenValueSetValue, GenValueSetMinimum

PASS:		ds:di - GenInstance of range object
		dx.cx - value to keep in range

RETURN:		dx.cx - value updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/22/89	Initial version

------------------------------------------------------------------------------@

KeepInRange	proc	near		uses	ax, bx
	class	GenValueClass

	.enter
	;	
	; Limit to maximum - range length.
	; 
	movdw	bxax, ds:[di].GVLI_maximum
	pushdw	dxcx
	call	GenValueGetRangeLength			;dx.cx <- range length
	subdw	bxax, dxcx				;subtract from maximum
	popdw	dxcx

	jledw	dxcx, bxax, 20$				;below max, branch
	movdw	dxcx, bxax				;else substitute max
20$:
	;
	; Limit to minimum as well.  (If pageLength > max-min, we'll settle
	; for the minimum. -cbh 9/14/92
	;
	jgedw	dxcx, ds:[di].GVLI_minimum, 10$		;see if above min
	movdw	dxcx, ds:[di].GVLI_minimum
10$:
	.leave
	ret
KeepInRange	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetMaximum -- 
		MSG_GEN_VALUE_SET_MAXIMUM for GenValueClass

DESCRIPTION:	Sets the maximum value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_MAXIMUM
		dx.cx	- new maximum

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetMaximum	method dynamic	GenValueClass, MSG_GEN_VALUE_SET_MAXIMUM
	mov	bx, offset GVLI_maximum
	GOTO	SetMinMax

GenValueSetMaximum	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenValueGetMinimum -- 
		MSG_GEN_VALUE_GET_MINIMUM for GenValueClass

DESCRIPTION:	Returns minimum.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_MINIMUM

RETURN:		dx.cx	- minimum
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueGetMinimum	method dynamic	GenValueClass, MSG_GEN_VALUE_GET_MINIMUM
	movdw	dxcx, ds:[di].GVLI_minimum
	ret
GenValueGetMinimum	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenValueGetMaximum -- 
		MSG_GEN_VALUE_GET_MAXIMUM for GenValueClass

DESCRIPTION:	Returns maximum.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_MAXIMUM

RETURN:		dx.cx	- maximum
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueGetMaximum	method dynamic	GenValueClass, MSG_GEN_VALUE_GET_MAXIMUM
	movdw	dxcx, ds:[di].GVLI_maximum
	ret
GenValueGetMaximum	endm






COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetIncrement -- 
		MSG_GEN_VALUE_SET_INCREMENT for GenValueClass

DESCRIPTION:	Sets a new increment.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_INCREMENT
		dx.cx	- new increment

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetIncrement	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SET_INCREMENT

	pushdw	cxdx
	mov	bx, offset GVLI_increment
	xchg	cx, dx				;make cx:dx
	call	GenSetDWord			;set the thing
	popdw	cxdx
	GOTO	GenCallSpecIfGrown

GenValueSetIncrement	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueGetIncrement -- 
		MSG_GEN_VALUE_GET_INCREMENT for GenValueClass

DESCRIPTION:	Returns increment

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_INCREMENT

RETURN:		dx.cx	- increment
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueGetIncrement method dynamic GenValueClass, MSG_GEN_VALUE_GET_INCREMENT
	movdw	dxcx, ds:[di].GVLI_increment
	ret
GenValueGetIncrement	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetIndeterminateState -- 
		MSG_GEN_VALUE_SET_INDETERMINATE_STATE for GenValueClass

DESCRIPTION:	Sets the indeterminate state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_INDETERMINATE_STATE
		
		cx	- non-zero to set the value indeterminate

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetIndeterminateState	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SET_INDETERMINATE_STATE

	mov	dl, mask GVSF_INDETERMINATE
	mov	bx, offset GVLI_stateFlags
	call	GenSetBitInByte
	jnc	exit

	mov	ax, MSG_GEN_VALUE_SET_VALUE	;assume args don't matter
	call	GenCallSpecIfGrown
exit:
	Destroy	ax, cx, dx, bp
	ret
GenValueSetIndeterminateState	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenValueIsIndeterminate -- 
		MSG_GEN_VALUE_IS_INDETERMINATE for GenValueClass

DESCRIPTION:	Returns whether value is indeterminate.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_IS_INDETERMINATE

RETURN:		carry set if value is modified.
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueIsIndeterminate	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_IS_INDETERMINATE

	test	ds:[di].GVLI_stateFlags, mask GVSF_INDETERMINATE
	jz	exit			;not modified, exit, carry clear
	stc	
exit:
	Destroy	ax, cx, dx, bp
	ret
GenValueIsIndeterminate	endm







COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetModifiedState -- 
		MSG_GEN_VALUE_SET_MODIFIED_STATE for GenValueClass

DESCRIPTION:	

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_MODIFIED_STATE

		cx	- non-zero to mark modified, zero to mark not modified.

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetModifiedState	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SET_MODIFIED_STATE

	push	cx
	mov	dl, mask GVSF_MODIFIED
	mov	bx, offset GVLI_stateFlags
	call	GenSetBitInByte
	pop	cx
 	jnc	exit				;no change, exit
 	tst	cx
 	jz	exit				;not setting modified, exit
 
 	;	
 	; Make the summons this object is in applyable.  -cbh 8/27/92
 	;
 	mov	ax, MSG_GEN_MAKE_APPLYABLE
 	call	ObjCallInstanceNoLock
exit:
	Destroy	ax, cx, dx, bp
	ret

GenValueSetModifiedState	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetOutOfDate -- 
		MSG_GEN_VALUE_SET_OUT_OF_DATE for GenValueClass

DESCRIPTION:	Sets the GenValue out of date.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_OUT_OF_DATE

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetOutOfDate	method dynamic	GenValueClass, \
			MSG_GEN_VALUE_SET_OUT_OF_DATE

	push	cx
	mov	cx, si				;set in all cases
	mov	dl, mask GVSF_OUT_OF_DATE
	mov	bx, offset GVLI_stateFlags
	call	GenSetBitInByte
	pop	cx
	Destroy	ax, cx, dx, bp
	ret

GenValueSetOutOfDate	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueIsModified -- 
		MSG_GEN_VALUE_IS_MODIFIED for GenValueClass

DESCRIPTION:	Returns whether value is modified.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_IS_MODIFIED

RETURN:		carry set if value is modified.
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueIsModified	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_IS_MODIFIED

	test	ds:[di].GVLI_stateFlags, mask GVSF_MODIFIED
	jz	exit				;not modified, exit, carry clear
	stc	
exit:
	Destroy	ax, cx, dx, bp
	ret
GenValueIsModified	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSendStatusMsg -- 
		MSG_GEN_VALUE_SEND_STATUS_MSG for GenValueClass

DESCRIPTION:	Sends off the status message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SEND_STATUS_MSG

		cx	- non-zero if GIGSF_MODIFIED bit should be passed set
			  in status message

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueSendStatusMsg	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SEND_STATUS_MSG

	mov	ax, ATTR_GEN_VALUE_STATUS_MSG
	call	ObjVarFindData		; ds:bx = data, if found
	jnc	exit			; no message, exit
	mov	ax, ds:[bx]		; else, fetch message

	tst	cx			; check for changed flag passed
	jz	10$			; no, branch
	mov	ch, mask GVSF_MODIFIED	; else pass modified
10$:
	mov	cl, ds:[di].GVLI_stateFlags
	andnf	cl, not mask GVSF_MODIFIED
	ornf	cl, ch			; use other flags plus modified passed
					;   flag passed
	GOTO	GenValueSendMsg
exit:	
	ret

GenValueSendStatusMsg	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	GenValueSendMsg

SYNOPSIS:	Sends a message to the destination, with usual arguments.

CALLED BY:	GenValueSendStatusMsg, GenValueApply

PASS:		*ds:si -- object
		ax     -- message to send
		cl     -- GenValueStateFlags

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/28/92		Initial version

------------------------------------------------------------------------------@

GenValueSendMsg	proc	far
	class	GenValueClass

	tst	ax			; no message, exit
	jz	exit
	mov	bp, cx			; state flags in bp low now

	call	Value_DerefGenDI	
	pushdw	ds:[di].GVLI_destination ; push them for GenProcessAction
	movdw	dxcx, ds:[di].GVLI_value ; pass value in dx.cx

	call	GenProcessGenAttrsBeforeAction
	mov	di, mask MF_FIXUP_DS
	call	GenProcessAction	; send the message
	call	GenProcessGenAttrsAfterAction
exit:
	Destroy	ax, cx, dx, bp
	ret
GenValueSendMsg	endp





COMMENT @----------------------------------------------------------------------

METHOD:		GenValueApply -- 
		MSG_GEN_APPLY for GenValueClass

DESCRIPTION:	Handles applies.

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueApply	method dynamic	GenValueClass, MSG_GEN_APPLY
	call	GenCallSpecIfGrown			;get up to date
	;	
	; in general, only send out apply if modified.
	;
	call	Value_DerefGenDI
	mov	ax, ds:[di].GVLI_applyMsg
	mov	cl, ds:[di].GVLI_stateFlags
	test	cl, mask GVSF_MODIFIED			;modified?
	jnz	sendMsg					;yes, send message

	;
	; Not modified, will still send apply message if dougarized hint is
	; present...
	;
	push	ax
	mov	ax, ATTR_GEN_SEND_APPLY_MSG_ON_APPLY_EVEN_IF_NOT_MODIFIED
	call	ObjVarFindData				;does this exist?
	pop	ax
	jc	sendMsg					;yes, send anyway
	ret
sendMsg:
	;
	; Send out the apply message
	;
	call	GenValueSendMsg
	;
	; Clear the modified bit.
	;
	call	Value_DerefGenDI	
	and	ds:[di].GVLI_stateFlags, not mask GVSF_MODIFIED
	ret

GenValueApply	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueGetDestination -- 
		MSG_GEN_VALUE_GET_DESTINATION for GenValueClass

DESCRIPTION:	Returns the destination.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_DESTINATION

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueGetDestination	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_GET_DESTINATION
	mov	bx, offset GVLI_destination
	call	GenGetDWord
	Destroy	ax, bp
	ret
GenValueGetDestination	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetDestination -- 
		MSG_GEN_VALUE_SET_DESTINATION for GenValueClass

DESCRIPTION:	Sets a new destination.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_DESTINATION

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetDestination	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SET_DESTINATION
	mov	bx, offset GVLI_destination
	GOTO	GenSetDWord
GenValueSetDestination	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenValueGetApplyMsg -- 
		MSG_GEN_VALUE_GET_APPLY_MSG for GenValueClass

DESCRIPTION:	Returns apply message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_APPLY_MSG

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueGetApplyMsg	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_GET_APPLY_MSG
	mov	ax, ds:[di].GVLI_applyMsg
	Destroy	cx, dx, bp
	ret
GenValueGetApplyMsg	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetApplyMsg -- 
		MSG_GEN_VALUE_SET_APPLY_MSG for GenValueClass

DESCRIPTION:	Sets a new apply message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_APPLY_MSG

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetApplyMsg	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SET_APPLY_MSG
	mov	bx, offset GVLI_applyMsg
	GOTO	GenSetWord
GenValueSetApplyMsg	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetDisplayFormat -- 
		MSG_GEN_VALUE_SET_DISPLAY_FORMAT for GenValueClass

DESCRIPTION:	Sets a new display format.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_DISPLAY_FORMAT
		cl	- GenValueDisplayFormat

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetDisplayFormat	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SET_DISPLAY_FORMAT

	mov	bx, offset GVLI_displayFormat	
	call	GenSetByte			;set the byte
	jnc	exit				;no change, exit

	;
	; Sending a SET_MAXIMUM to the specific UI will ensure things are the
	; size we need.
	;
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM	
	call	GenCallSpecIfGrown		

	;
	; Sending a SET_VALUE to the specific UI will ensure things are 
	; redisplayed correctly.  -cbh 1/20/93
	;
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	call	GenCallSpecIfGrown		
exit:
	ret
GenValueSetDisplayFormat	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueGetDisplayFormat -- 
		MSG_GEN_VALUE_GET_DISPLAY_FORMAT for GenValueClass

DESCRIPTION:	Gets the current display format.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_DISPLAY_FORMAT

RETURN:		al 	- display format
		ah, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueGetDisplayFormat	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_GET_DISPLAY_FORMAT

	mov	al, ds:[di].GVLI_displayFormat
	ret
GenValueGetDisplayFormat	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenValueGetValueRatio -- 
		MSG_GEN_VALUE_GET_VALUE_RATIO for GenValueClass

DESCRIPTION:	Returns a ratio of the desired value to the length of the 
		allowed size.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_VALUE_RATIO
		bp	- GenValueType

RETURN:		dx.cx 	- ratio
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	7/ 9/92		Initial Version

------------------------------------------------------------------------------@

GenValueGetValueRatio	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_GET_VALUE_RATIO

	call	GetValueRange			;bx.ax <- value range
	pushdw	bxax
	mov	bx, di				;genInstance in ds:bx
	call	GetValueFromChoice		;dx.ax <- value

	;
	; We express ratios of values within the min and max range as
	; relative to the minimum (i.e. minimum = 0).  Let's make things
	; relative in the appropriate places.
	;
	cmp	bp, GVT_RANGE_LENGTH		;don't make these relative
	je	5$
	cmp	bp, GVT_INCREMENT
	je	5$
	cmp	bp, GVT_LONG
	je	5$

	negdw	dxax				;subtract minimum from value
	mov	bp, GVT_MINIMUM			;
	call	AddAppropriateValue		;
	negdw	dxax				;

	tst	dx				;result negative, zero it
	jns	5$
	clrdw	dxax				
5$:
	mov	di, bx				;GenInstance in ds:di
	mov	cx, ax				;dx.cx <- value

	popdw	bxax				;restore range 
	tstdw	bxax				;range non-zero, divide
	jnz	10$
	clrdw	dxcx				;else return zero
	jmp	short exit
10$:
	call	GrUDivWWFixed			;result in dx.cx
exit:	
	ret
GenValueGetValueRatio	endm






COMMENT @----------------------------------------------------------------------

ROUTINE:	GetValueRange

SYNOPSIS:	Returns range of values (maximum - minimum, anyway.)  For
		GVT_VALUE_AS_RATIO_OF_AVAILABLE_RANGE, returns maximum - 
		minimum - range.

CALLED BY:	GenValueGetValueRatio, GenValueSetValueFromRatio

PASS:		*ds:si -- GenValue
		ds:di  -- GenInstance
		bp     -- GenValueType we want get the ratio of

RETURN:		bx.ax  -- value range
		bp     -- updated to GVC_VALUE from GVC_VALUE_AS_RATIO_OF_-
				AVAILABLE_RANGE if it was set to the former.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/ 9/92		Initial version

------------------------------------------------------------------------------@

GetValueRange	proc	near			uses	dx, cx
	class	GenValueClass
	.enter
	movdw	bxax, ds:[di].GVLI_maximum	;get current maximum
	subdw	bxax, ds:[di].GVLI_minimum	;subtract minimum
	js	returnZero			;negative, return zero

	cmp	bp, GVT_VALUE_AS_RATIO_OF_AVAILABLE_RANGE		
						;getting value relative to 
						;  scrollable area?
	jne	exit				;no, done
	pushdw	dxcx
	call	GenValueGetRangeLength		;dx.cx <- range length
	subdw	bxax, dxcx			;subtract range length
	popdw	dxcx
	mov	bp, GVT_VALUE			;reset to value now
	jmp	short exit

returnZero:
	clrdw	bxax				;else clear things
exit:
	.leave
	ret
GetValueRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GVGetDecimalPlaces
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the ATTR_GEN_VALUE_DECIMAL_PLACES attribute for the
		object, if it's present.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= GenValue object
RETURN:		carry set if found attribute:
			cx	= decimal places
		carry clear if not found:
			cx	= unchanged
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GVGetDecimalPlaces proc	near
	class	GenValueClass
	uses	ax, bx
	.enter
	mov	ax, ATTR_GEN_VALUE_DECIMAL_PLACES
	call	ObjVarFindData
	jnc	20$
	mov	cx, ds:[bx]
20$:
	.leave
	ret
GVGetDecimalPlaces endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenValueGetValueText -- 
		MSG_GEN_VALUE_GET_VALUE_TEXT for GenValueClass

DESCRIPTION:	Converts value text.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_VALUE_TEXT
		cx:dx	- buffer to hold text
		bp	- GenValueTextChoice

RETURN:		cx:dx	- buffer, filled in
		ax, bp  - destroyed
	
ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenValueGetValueText	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_GET_VALUE_TEXT
	uses	cx, dx
	.enter
	mov	bx, di				;ds:bx <- GenInstance
	movdw	esdi, cxdx			;es:di <- buffer
	call	GetValueFromChoice		;dx.ax <- value

	mov	bl, ds:[bx].GVLI_displayFormat
	cmp	bl, GVDF_DECIMAL
	ja	distance			;go do distance/pct, if need be
	
	mov	cx, 0				;assume integer => no fraction
	jne	25$
	
	mov	cx, 3				;for the moment, always use 3

	;
	; Get decimal places specified in hint, if any.   For V2.1 -cbh 1/12/94
	;
	call	GVGetDecimalPlaces
25$:
	call	LocalFixedToAscii		;convert it
	jmp	short exit

	; We're in distance mode. If we are tiny & not very-squished
	; (i.e. tiny & not CGA), then use the default display format
	; (and not the points format, which is longest)
distance:
	cmp	bl, GVDF_PERCENTAGE
	je	doPercentage

	push	ax
	cmp	bp, GVT_LONG			;were we doing a long value?
	jne	30$				;no, branch
	call	UserGetDisplayType		;ah <- DisplayType
	mov	al, ah
	andnf	al, mask DT_DISP_SIZE
	cmp	al, DS_TINY shl offset DT_DISP_SIZE
	jne	27$
	andnf	ah, mask DT_DISP_ASPECT_RATIO
	cmp	ah, DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO
	jne	30$
27$:
	mov	bl, GVDF_POINTS			;else make sure we can do points
30$:
	mov	ax, MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE
	call	GenCallApplication		;al = MeasurementType
	mov	bh, al
	pop	ax
	sub	bl, GVDF_POINTS - DU_POINTS	;get into DistanceMode

	;
	; Get decimal places specified in hint, if any.   For V2.1 -cbh 1/12/94
	;
	clr	cx				; assume none
	call	GVGetDecimalPlaces
	xchg	bx, cx				;cl <- DistanceMode
						;ch <- MeasurementType
						;bx <- # decimal places
	jnc	40$				; (bx = 0 => no distance flags,
						;  which is what we want)
	cmp	bx, mask LDF_DECIMAL_PLACES	;limit to 7
	jbe	35$
	mov	bx, mask LDF_DECIMAL_PLACES
35$:
	or	bx, mask LDF_PASSING_DECIMAL_PLACES
40$:
	call	LocalDistanceToAscii		;do distance
exit:
	.leave
	ret

doPercentage:
	mov	cx, ax
	jcxz	checkPctDecimals		; => no fraction, so default to
						;  no decimals
	mov	cx, 3
checkPctDecimals:
	call	GVGetDecimalPlaces
	; format the beastie, please
	call	LocalFixedToAscii
	
	;
	; Now need to tack on the appropriate percentage string. First get
	; to the end of the result.
	;
	clr	ax
	mov	cx, GEN_VALUE_MAX_TEXT_LEN
	LocalFindChar
	LocalPrevChar	esdi
	;
	; Lock down the string block
	; 
	mov	bx, handle Strings
	call	MemLock
	mov	ds, ax
	assume	ds:Strings
	;
	; Find the start and size of the percentage sign.
	; 
	mov	si, ds:[genValuePercentSign]
	ChunkSizePtr	ds, si, cx
	;
	; Copy the thing in (assume it's in the proper format :)
	;
	rep	movsb
	;
	; Release the string block and get the heck out.
	; 
	call	MemUnlock
	assume	ds:nothing
	jmp	exit
	
	
GenValueGetValueText	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	GetValueFromChoice

SYNOPSIS:	Gets the current value based on the desired choice.

CALLED BY:	GenValueGetValueText, GenValueGetValueRatio

PASS:		ds:bx  -- GenInstance
		bp     -- GenValueType

RETURN:		dx.ax  -- value

DESTROYED:	cx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/ 9/92		Initial version

------------------------------------------------------------------------------@

GetValueFromChoice	proc	near
	class	GenValueClass

	;
	; Long value (in terms of digits), call special routine.
	;
	cmp	bp, GVT_LONG			;choosing a long value?
	jne	10$
	call	GetLongestValue			;yes, dx.ax <- longest number
	ret
10$:
	;	
	; Range length, call special routine.
	;
	cmp	bp, GVT_RANGE_LENGTH
	jne	20$
	call	GenValueGetRangeLength		;dx.cx <- range length
	mov	ax, cx				;now in dx.ax
	ret
20$:
	;	
	; Range end, call range length routine and add current value.
	;
	push	bp
	cmp	bp, GVT_RANGE_END
	jne	30$
	call	GenValueGetRangeLength		;dx.cx <- range length
	mov	ax, cx				;now in dx.ax
	clr	bp				;want to add current value
	jmp	short addValue			;branch to do so
30$:
	;
	; Is GVT_VALUE, GVT_MINIMUM, GVT_MAXIMUM, or GVT_INCREMENT:
	; pull value out of instance data.
	;
	clr	dx
	mov	ax, dx
addValue:
	call	AddAppropriateValue
	pop	bp
	ret
GetValueFromChoice	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	AddAppropriateValue

SYNOPSIS:	Adds a designated value to the current value.

CALLED BY:	GenValueGetValueRatio, GenValueSetValueFromRatio

PASS:		*ds:si -- GenValue
		dx.ax  -- current value
		bp     -- GenValueType

RETURN:		dx.ax  -- current value, updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/16/92		Initial version

------------------------------------------------------------------------------@

AddAppropriateValue	proc	near
	class	GenValueClass

	push	bx
	mov	bx, ds:[si]			
	add	bx, ds:[bx].Gen_offset
	shl	bp, 1				;make into a dword offset
	shl	bp, 1
	add	bx, bp				;at to instance data offset
	adddw	dxax, ds:[bx].GVLI_value	;will choose correct value
	pop	bx
	ret
AddAppropriateValue	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	GetLongestValue

SYNOPSIS:	Returns the longest (text-wise) value between the minimum and
		the maximum.

CALLED BY:	GenValueGetValueText

PASS:		*ds:si -- GenValue

RETURN:		dx.ax -- value expected to create the longest text string

DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:
	Since we can't really be sure how big the negative sign is textually
	compared to the digits, we'll play it safe and ignore it during 
	comparisons between the minimum and maximum, then add the sign back in.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 4/92		Initial version

------------------------------------------------------------------------------@

GetLongestValue	proc	near		uses	bx, bp, di
	class	GenValueClass
	.enter
	clr	bx				;no negatives yet
	call	Value_DerefGenDI
	movdw	dxax, ds:[di].GVLI_minimum	;get absolute of minimum
	tst	dx
	jns	10$
	negdw	dxax
	dec	bx				;found a negative
10$:
	movdw	bpcx, ds:[di].GVLI_maximum	;get absolute of maximum
	tst	bp
	jns	20$
	negdw	bpcx
	dec	bx				;found a negative
20$:
	cmpdw	dxax, bpcx			;take the bigger of the two
	jae	30$
	movdw	dxax, bpcx
30$:
	tst	bx				;something was negative, add
	jz	40$				;  sign back in no matter what
	negdw	dxax
40$:
	;
	; If we're displaying fractions, we'll have to replace the
	; big number we've got with one that is guaranteed to display a
	; large fraction.  After all, if 150 is the maximum we better be able
	; to display 149.999.
	;
	tst	ds:[di].GVLI_displayFormat	;doing integers?
	jz	50$				;no, branch
	mov	ax, 36408			;else replace fraction with
						;  something like, say, .556.
50$:
	.leave
	ret
GetLongestValue	endp






COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetValueFromRatio -- 
		MSG_GEN_VALUE_SET_VALUE_FROM_RATIO for GenValueClass

DESCRIPTION:	Sets a value from a ratio.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_VALUE_FROM_RATIO
		dx.cx	- WWFixed ratio
		bp	- GenValueType

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
	chris	7/ 9/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetValueFromRatio	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SET_VALUE_FROM_RATIO
	push	si, di				;instance instance data stuff
	call	GetValueRange			;bx.ax <- value range
	clr	si				;now si.bx.ax
	mov	di, si				;ratio now di.dx.cx
	call	GrMulDWFixed		        ;multiply them, result in cx.bx
	pop	si, di

	movdw	dxax,cxbx			;now in dx.ax
	;
	; We express ratios of values within the min and max range as
	; relative to the minimum (i.e. minimum = 0).  Let's make things
	; relative in the appropriate places.
	;
	cmp	bp, GVT_RANGE_LENGTH		;don't make these relative
	je	5$
	cmp	bp, GVT_INCREMENT
	je	5$
	cmp	bp, GVT_LONG
	je	5$

	push	bp				;add minimum to value
	mov	bp, GVT_MINIMUM			;
	call	AddAppropriateValue		;
	pop	bp
5$:
	mov	cx, ax				;now in dx.cx
	
	shl	bp, 1				;make into a dword offset
	shl	bp, 1
	add	di, bp				;add to instance data offset
	GOTO	SetValue

GenValueSetValueFromRatio	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetValueFromText -- 
		MSG_GEN_VALUE_SET_VALUE_FROM_TEXT for GenValueClass

DESCRIPTION:	Sets a value given the text representation passed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_VALUE_FROM_TEXT

		cx:dx	- null-terminated text
		(cx:dx *cannot* be pointing into the movable XIP code resource.)
		bp	- GenValueType

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
	chris	5/29/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetValueFromText	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SET_VALUE_FROM_TEXT
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr (cx:dx) passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	pushdw	dsdi
	mov	bl, ds:[di].GVLI_displayFormat
	cmp	bl, GVDF_DECIMAL		
	movdw	dsdi, cxdx			;es:di <- buffer
	ja	distance			;converting distance, branch

	call	LocalAsciiToFixed		;convert to fixed, in dx.ax
	jmp	short convertFinished

distance:
	mov	ax, MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE
	call	GenCallApplication		;al = MeasurementType
	mov	ch, al
	mov	cl, bl
	sub	cl, GVDF_POINTS - DU_POINTS	;get into DistanceMode
	call	LocalDistanceFromAscii		;convert to fixed, in dx.ax

convertFinished:
	popdw	dsdi

	shl	bp, 1				;make into a dword offset
	shl	bp, 1
	add	di, bp				;at to instance data offset
	mov	cx, ax				;now in dx.cx
	GOTO	SetValue


GenValueSetValueFromText	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenValueIncrementDecrement -- 
		MSG_GEN_VALUE_INCREMENT for GenValueClass
		MSG_GEN_VALUE_DECREMENT for GenValueClass

DESCRIPTION:	Increments the value.
		Decrements the value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_INCREMENT
			  MSG_GEN_VALUE_DECREMENT

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
	chris	5/29/92		Initial Version

------------------------------------------------------------------------------@

GenValueIncrementDecrement	method dynamic	GenValueClass,
				MSG_GEN_VALUE_INCREMENT,
				MSG_GEN_VALUE_DECREMENT
	push	ax
	call	GenCallSpecIfGrown		;update from text if needed
	call	GetIncrement			;dxcx <- decent increment
	pop	ax

	cmp	ax, MSG_GEN_VALUE_INCREMENT
	je	addValue
	negdw	dxcx				;negate it

addValue:
	call	Value_DerefGenDI
	adddw	dxcx, ds:[di].GVLI_value	;add value to it

	push	ax
	mov	ax, HINT_VALUE_WRAP
	call	ObjVarFindData
	pop	ax
	jnc	setValue

	movdw	bxbp, dxcx
	call	KeepInRange
	cmpdw	bxbp, dxcx
	je	setValue	

  CheckHack <MSG_GEN_VALUE_SET_VALUE_TO_MINIMUM eq MSG_GEN_VALUE_INCREMENT+2>
  CheckHack <MSG_GEN_VALUE_SET_VALUE_TO_MAXIMUM eq MSG_GEN_VALUE_DECREMENT+2>

	inc	ax
	inc	ax
	jmp	callNoLock

setValue:
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	clr	bp				;set not indeterminate

callNoLock:
	GOTO	ObjCallInstanceNoLock

GenValueIncrementDecrement	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenValueAddRangeLength -- 
		MSG_GEN_VALUE_ADD_RANGE_LENGTH for GenValueClass

DESCRIPTION:	Increments the value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_ADD_RANGE_LENGTH

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
	chris	5/29/92		Initial Version

------------------------------------------------------------------------------@

GenValueAddRangeLength	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_ADD_RANGE_LENGTH

	call	GenCallSpecIfGrown		;update from text if needed

	call	GenValueGetRangeLength		;dxcx <- decent increment

AddValueAndSet	label	far
	call	Value_DerefGenDI
	adddw	dxcx, ds:[di].GVLI_value	;add value to it

SetValue	label	far
	clr	bp				;set not indeterminate
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	GOTO	ObjCallInstanceNoLock

GenValueAddRangeLength	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSubtractRangeLength -- 
		MSG_GEN_VALUE_SUBTRACT_RANGE_LENGTH for GenValueClass

DESCRIPTION:	Subtracts the range length from the value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SUBTRACT_RANGE_LENGTH

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
	chris	5/29/92		Initial Version

------------------------------------------------------------------------------@

GenValueSubtractRangeLength	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SUBTRACT_RANGE_LENGTH

	call	GenCallSpecIfGrown		;update specific if needed

	call	GenValueGetRangeLength		;dxcx <- decent increment
	negdw	dxcx				;negate it
	GOTO 	AddValueAndSet

GenValueSubtractRangeLength	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetValueToMinimum -- 
		MSG_GEN_VALUE_SET_VALUE_TO_MINIMUM for GenValueClass

DESCRIPTION:	Sets value to minimum.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_VALUE_TO_MINIMUM

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
	chris	5/29/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetValueToMinimum	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SET_VALUE_TO_MINIMUM

	movdw	dxcx, ds:[di].GVLI_minimum
	GOTO	SetValue

GenValueSetValueToMinimum	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetValueToMaximum -- 
		MSG_GEN_VALUE_SET_VALUE_TO_MAXIMUM for GenValueClass

DESCRIPTION:	Sets value to maximum.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_VALUE_TO_MAXIMUM

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
	chris	5/29/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetValueToMaximum	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SET_VALUE_TO_MAXIMUM

	movdw	dxcx, ds:[di].GVLI_maximum
	GOTO	SetValue

GenValueSetValueToMaximum	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetIncrement

SYNOPSIS:	Chooses an appropriate US or metric increment and stores it in 
		vardata.

CALLED BY:	GenValueSetIncrement, GenValueBuild

PASS:		*ds:si -- GenValue object

RETURN:		dxcx -- value

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 3/92		Initial version
	Don	3/12/99		Fixed up the metric detection

------------------------------------------------------------------------------@
GetIncrement	proc	near
	class	GenValueClass

	call	Value_DerefGenDI		
	movdw	dxcx, ds:[di].GVLI_increment	;assume doing normal increment

	mov	al, ds:[di].GVLI_displayFormat
	cmp	al, GVDF_CENTIMETERS
	je	goMetric
	cmp	al, GVDF_MILLIMETERS
	je	goMetric
	cmp	al, GVDF_INCHES_OR_CENTIMETERS
	je	checkSettings
	cmp	al, GVDF_POINTS_OR_MILLIMETERS
	jne	exit

checkSettings:
	mov	ax, MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE
	call	GenCallApplication		;al = MeasurementType
	tst	al				;US measurement, we're done
	jz	exit

goMetric:
	mov	ax, ATTR_GEN_VALUE_METRIC_INCREMENT
	call	ObjVarFindData			;do we have a metric increment?
	jnc	roundCurrentIncrement		;no, go round our current one
	movdw	dxcx, ds:[bx]			;else get the value out of 
	jmp	short exit			;   instance data

roundCurrentIncrement:
	call	RoundIncrementForMetric		;round the increment
exit:
	ret
GetIncrement	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	RoundIncrementForMetric

SYNOPSIS:	Rounds increment to a reasonable metric value.

CALLED BY:	GenRangeIncrement, GenRangeDecrement

PASS:		*ds:si
		dx.cx -- increment, in points

RETURN:		dx.cx -- increment, rounded

DESTROYED:	ax, bx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 3/92		Initial version

------------------------------------------------------------------------------@

RoundIncrementForMetric	proc	near
	clr	bx				;start at beginning

checkInBetween:
	cmp	bx, offset lastMetricIncTableEntry - offset metricIncTable
	je	done				;at end of table, done

	cmpdw	dxcx, cs:metricIncTable[bx]	;less than value?	
	jb	inBetween			;yes, we're done
	add	bx, size WWFixed		;else move to next entry
	jmp	short checkInBetween

inBetween:
	;
	; At this point, we're pointing at an item larger than ourselves.
	; See if we're actually closer to the previous item:
	;
	; X is closer to A than B if:
	;	2X < B + A, or 2X - B - A < 0.
	;
	tst	bx				;pointing at first item?
	jz	done				;yes, no more to do

	movdw	bpax, dxcx
	adddw	bpax, dxcx			;double our value
	subdw	bpax, cs:metricIncTable[bx]	;subtract B, A
	subdw	bpax, <cs:metricIncTable[bx-size WWFixed]>
	jns	done				;closer to B, done
	sub	bx, size WWFixed		;else use previous entry
done:
	movdw	dxcx, cs:metricIncTable[bx]	;return table entry
	ret
RoundIncrementForMetric	endp

metricIncTable	label	WWFixed
	WWFixed <18577, 0>			;.1 mm	    0.28346 pts
	WWFixed <46443, 0>			;.25 mm	    0.70866 
	WWFixed <27349, 1>			;.5 mm	    1.41732 
	WWFixed	<54700, 2>			;1 mm	    2.83465 
	WWFixed <05676, 7>			;.2.5 mm    7.08661
	WWFixed <11353, 14>			;.5 cm	   14.17323
	WWFixed <22706, 28>			;1 cm	   28.34646
	WWFixed <56763, 70>			;2.5 cm	   70.86614
	WWFixed <47991, 141>			;5 cm	  141.73229
lastMetricIncTableEntry	label	WWFixed
	WWFixed <30446, 283>			;10 cm	  283.46458

Value_DerefGenDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	ret
Value_DerefGenDI	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueSetRangeLength -- 
		MSG_GEN_VALUE_SET_RANGE_LENGTH for GenValueClass

DESCRIPTION:	Sets a range length.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_RANGE_LENGTH
		dx.cx	- range

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
	chris	7/ 9/92		Initial Version

------------------------------------------------------------------------------@

GenValueSetRangeLength	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_SET_RANGE_LENGTH

	push	cx, ax
	mov	cx, 4				;size of vardata
	mov	ax, HINT_VALUE_DISPLAYS_RANGE
	call	ObjVarAddData
	pop	cx, ax
	mov	ds:[bx].low, cx
	mov	ds:[bx].high, dx		;store new range length

	call	GenCallSpecIfGrown		;allows spec-UI to resize

	GOTO	RedoValueForMinMax		;keeps in range, redraws

GenValueSetRangeLength	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenValueGetRangeLength -- 
		MSG_GEN_VALUE_GET_RANGE_LENGTH for GenValueClass

DESCRIPTION:	Returns the range length.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_RANGE_LENGTH

RETURN:		dx.cx   - range length

ALLOWED TO DESTROY:	
		nothing (can be called directly)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	7/ 9/92		Initial Version

------------------------------------------------------------------------------@

GenValueGetRangeLength	method GenValueClass, MSG_GEN_VALUE_GET_RANGE_LENGTH
	uses	bx, ax
	.enter
	clr	cx				;assume no range length
	mov	dx, cx
	mov	ax, HINT_VALUE_DISPLAYS_RANGE
	call	ObjVarFindData
	jnc	exit				;vardata not present, branch
	mov	cx, ds:[bx].low
	mov	dx, ds:[bx].high		;get range length
exit:
	.leave
	ret
GenValueGetRangeLength	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenValueGetTextFilter -- 
		MSG_GEN_VALUE_GET_TEXT_FILTER for GenValueClass

DESCRIPTION:	Returns text filter to use.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_TEXT_FILTER

RETURN:		al	- VisTextFilters
		ah, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	6/ 1/92		Initial Version

------------------------------------------------------------------------------@

GenValueGetTextFilter	method dynamic	GenValueClass, \
				MSG_GEN_VALUE_GET_TEXT_FILTER
	call	Value_DerefGenDI
	mov	ah, ds:[di].GVLI_displayFormat
	mov	al, VTFC_SIGNED_NUMERIC or mask VTF_NO_SPACES \
					or mask VTF_NO_TABS
	tst	ah
		CheckHack <GVDF_INTEGER eq 0>
	jz	exit				;integer format, exit
	mov	al, VTFC_SIGNED_DECIMAL or mask VTF_NO_SPACES \
					or mask VTF_NO_TABS
	cmp	ah, GVDF_DECIMAL
	je	exit				;decimal format, exit
	mov	al, mask VTF_NO_TABS		;else allow everything but tabs
exit:
	ret
GenValueGetTextFilter	endm

Value 	ends


Build	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenValueFindViewRanges -- 
		MSG_GEN_FIND_VIEW_RANGES for GenValueClass

DESCRIPTION:	Finds view ranges.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_FIND_VIEW_RANGES
		
		cl -- RequestedViewArea, if any, so far, for horizontal range
		dx -- chunk handle of horizontal range, if any
		ch -- RequestedViewArea, if any, so far, for vertical range
		bp -- chunk handle of vertical range, if any
		
RETURN:		cl -- RequestedViewArea, update if horiz scrollbar found at 
				or under this object
		dx -- chunk handle of horizontal range, if any
		ch -- RequestedViewArea, update if vertical scrollbar found
				at or under this object.
		bp -- chunk handle of vertical range, if any
		ax, bp	- destroyed


DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       if cx = 0 and HINT_RANGE_X_SCROLLER
       		cx = any range area hint
       if dx = 0 and HINT_RANGE_Y_SCROLLER
       		dx = any range area hint

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 9/91		Initial version

------------------------------------------------------------------------------@

GenValueFindViewRanges	method GenValueClass, MSG_GEN_FIND_VIEW_RANGES
	push	bp
	clr	bp				;assume not a scrollbar
	mov	di, cs
	mov	es, di
	mov	di, offset cs:ScrollerHints
	mov	ax, length (cs:ScrollerHints)
	call	ObjVarScanData			;bp -- any scrollbar hint
	mov	ax, bp				;now in ax
	pop	bp
	
	tst	dx				;is there a horiz scrollbar yet?
	jnz	10$				;yes, branch
	cmp	ax, HINT_VALUE_X_SCROLLER	;will this be a horiz scrollbar?
	jne	10$				;no, branch
	
	mov	dx, si				;else return our handle
	call	GetUnambiguousViewAreaRequest	;get a positioning hint, if any
	mov	cl, bl				;and return in cl
	jmp	short exit			;and we're done
10$:
	tst	bp				;a vert scrollbar yet?
	jnz	exit				;yes, branch
	cmp	ax, HINT_VALUE_Y_SCROLLER	;will this be a vert scrollbar?
	jne	exit				;no, branch
	
	mov	bp, si				;else return our handle
	call	GetUnambiguousViewAreaRequest	;get a positioning hint, if any
	mov	ch, bl				;and return in ch
exit:
	ret
GenValueFindViewRanges	endm

			
ScrollerHints	VarDataHandler \
 <HINT_VALUE_X_SCROLLER, offset ReturnHint>,
 <HINT_VALUE_Y_SCROLLER, offset ReturnHint>
 
ReturnHint	proc	far
	mov	bp, ax
	ret
ReturnHint	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenValueQueryViewArea -- 
		MSG_GEN_QUERY_VIEW_AREA for GenValueClass

DESCRIPTION:	Returns any preference for where to be put under a GenView.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_QUERY_VIEW_AREA

RETURN:		cl 	- RequestedViewArea: area request, if any

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/10/91		Initial version

------------------------------------------------------------------------------@

GenValueQueryViewArea	method GenValueClass, MSG_GEN_QUERY_VIEW_AREA
	mov	di, offset GenValueClass
	call	ObjCallSuperNoLock		;try superclass first
	
	cmp	cl, RVA_NO_AREA_CHOICE		;any choice made yet?
	jne	exit				;yes, exit
	
	clr	bp				;assume not a scrollbar
	mov	di, cs
	mov	es, di
	mov	di, offset cs:ScrollerHints
	mov	ax, length (cs:ScrollerHints)
	call	ObjVarScanData			;bp -- any scrollbar hint
	
	cmp	bp, HINT_VALUE_X_SCROLLER	;will this be a horiz scrollbar?
	jne	10$				;no, branch
	mov	cl, RVA_X_SCROLLER_AREA		;else return our positional
						;   preference
	jmp	short exit
10$:
	cmp	bp, HINT_VALUE_Y_SCROLLER	;a vert scroller?
	jne	exit				;no, we have no other ideas
	mov	cl, RVA_Y_SCROLLER_AREA		;else return our positional
						;   preference
exit:
	ret
GenValueQueryViewArea	endm



Build	ends

;
;---------------
;

IniFile segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenValueLoadOptions -- MSG_GEN_LOAD_OPTIONS for GenValueClass

DESCRIPTION:	Load options from .ini file

PASS:
	*ds:si - instance data
	es - segment of GenValueClass

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
GenValueLoadOptions	method dynamic	GenValueClass, MSG_GEN_LOAD_OPTIONS

SBCS<	curValue	local	GEN_VALUE_MAX_TEXT_LEN dup (char)	>
DBCS<	curValue	local	GEN_VALUE_MAX_TEXT_LEN dup (wchar)	>
	mov	di, bp

	.enter
	push	bp
	pushdw	dssi
        segmov  ds, ss
        lea     si, ss:[di].GOP_category
        mov     cx, ss
        lea     dx, ss:[di].GOP_key
	segmov	es, cx

	lea	di, curValue
	mov	bp, mask IFRF_SIZE
        call    InitFileReadString		;string in es:di
	popdw	dssi
	jc	exit				;didn't work, exit

	movdw	cxdx, esdi
	mov	bp, GVT_VALUE
	mov	ax, MSG_GEN_VALUE_SET_VALUE_FROM_TEXT
	call	ObjCallInstanceNoLock


	mov	cx, si				;set non-zero
	mov	ax, MSG_GEN_VALUE_SET_MODIFIED_STATE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_APPLY
	call	ObjCallInstanceNoLock
exit:
	pop	bp
	.leave
	ret
GenValueLoadOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenValueSaveOptions -- MSG_GEN_SAVE_OPTIONS for GenValueClass

DESCRIPTION:	Save our options

PASS:
	*ds:si - instance data
	es - segment of GenValueClass

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
GenValueSaveOptions	method dynamic	GenValueClass, MSG_GEN_SAVE_OPTIONS

SBCS<	curValue	local	GEN_VALUE_MAX_TEXT_LEN dup (char)	>
DBCS<	curValue	local	GEN_VALUE_MAX_TEXT_LEN dup (wchar)	>

	mov	di, bp
	.enter
	mov	cx, ss
	lea	dx, curValue
	push	bp
	push	dx
	mov	bp, GVT_VALUE
	mov	ax, MSG_GEN_VALUE_GET_VALUE_TEXT
	call	ObjCallInstanceNoLock		;value text in es:di

        segmov  ds, ss
        lea     si, ss:[di].GOP_category
        mov     cx, ss
        lea     dx, ss:[di].GOP_key
        mov     bp, ax                          ;bp = value
	mov	es, cx
	pop	di
        call    InitFileWriteString
	pop	bp
	.leave
	ret
GenValueSaveOptions	endm

IniFile ends







