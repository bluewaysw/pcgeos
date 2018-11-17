COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/User
FILE:		userFlowUtils.asm

ROUTINES:
	Name			Description
	----			-----------
; Utility routines for implementing HierarchicalGrab's, Focus/Target hierarchies
;
   EXT	FlowForceGrab
   EXT	FlowReleaseGrab
   EXT	FlowRequestGrab

   LOC	FlowGainedAppExcl
   LOC	FlowLostAppExcl
   LOC	FlowGainedSysExcl
   LOC	FlowLostSysExcl

   EXT	FlowUpdateHierarchicalGrab

   LOC	FlowGrabWithinLevel
   LOC	FlowReleaseWithinLevel
   EXT	FlowAlterHierarchicalGrab


   EXT	FlowGetTargetAtTargetLevel
   EXT	FlowDispatchSendOnOrDestroyClassedEvent
   EXT	FlowHandleFownOrTownClassedEvent

   EXT	MetaGrabFocusExclLow
   EXT	MetaReleaseFocusExclLow
   EXT	MetaGrabTargetExclLow
   EXT	MetaReleaseTargetExclLow
   EXT	MetaGrabModelExclLow
   EXT	MetaReleaseModelExclLow
   EXT	MetaReleaseFTExclLow

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

DESCRIPTION:
	This file contains a collection of utility routines, for use within
	objects to implement "flow"-like features.
	Routines placed in this file may not reference global UI variables.
	
	$Id: userFlowUtils.asm,v 1.1 97/04/07 11:45:49 newdeal Exp $

-------------------------------------------------------------------------------@

Resident segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	FlowForceGrab

DESCRIPTION:	Forces old grab out, & new grab in.

		Sends LOST_GRAB message to the old grab, GAINED_GRAB to the
		new, if message sending is specified, & the old grab has a
		different OD the the new.

		If the grab OD specified matches that already there, no
		messages are sent, & only the data word is updated.

		Data & OD is left intact while the old object receives
		the LOST_GRAB message.  The new data is stored before the
		new object recieves GAINED_GRAB.

CALLED BY:	GLOBAL

PASS:	*ds:si	- Object instance data
	ax = NULL for no messages to be sent, else:
	     ax+0 = "GAINED_GRAB" message to send to new object gaining grab
	     ax+1 = "LOST_GRAB" message to send to object losing grab
	bx	- offset to MasterPart holding BasicGrab structure (0 if
		  no master parts)
	di	- offset to BasicGrab structure
	cx:dx	- OD to match with
	bp	- Data to be place in BG_data field

RETURN:
	carry	- set if grab OD changed, & therefore methods were sent out
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
	Doug	6/89		Initial version
	Eric	2/90		cleanup, showcalls work.
------------------------------------------------------------------------------@


FlowForceGrab	proc	far	uses	di, bp
	.enter
EC <	call	ECCheckODCXDX						>
EC <	call	ECCheckFlowExcl						>

	push	bp			; save passed data
	call	FlowPointToField	; set *ds:di = instance data field,

	; Check to see if just forcing off grab
	;
	tst	cx
	jnz	nonNullGrab

	call	FlowReleaseLow		; Release current owner of grab
	pop	bp			; fix stack
	jmp	short FFG_done

nonNullGrab:

	; If object requesting grab already has it, just update the data
	; field.
	;
	cmp	cx, ds:[di].BG_OD.handle
	jne	notSameObject
	cmp	dx, ds:[di].BG_OD.chunk
	jne	notSameObject

	pop	ds:[di].BG_data
	jmp	short FFG_done

notSameObject:

	; If something currently has the grab, release it
	;
	tst	ds:[di].BG_OD.handle
	jz	justGrab
	call	FlowReleaseLow		; Release current owner of grab
	mov	di, bp
	call	FlowPointToField	; set *ds:di = instance data field,
justGrab:

	; Finally, grab for new owner
	;
	pop	bp
	call	FlowGrabLow		; Grab for new owner

FFG_done label near		; REQUIRED BY SHOWCALLS IN SWAT
	ForceRef	FFG_done

	.leave
	ret
FlowForceGrab	endp

;
;-----
;

FlowPointToField	proc	near
EC <	call	ECCheckLMemObject					>
EC <	cmp	di, MAX_INSTANCE_OFFSET					>
EC <	ERROR_A	FLOW_ERROR_BAD_INSTANCE_OFFSET				>
EC <	tst	bx							>
EC <	jnz	afterNoMasterCheck					>
EC <	cmp	di, size fptr	;can't point into MB_class		>
EC <	ERROR_B	FLOW_ERROR_BAD_INSTANCE_OFFSET				>
EC <afterNoMasterCheck:							>
	mov	bp, di		;save offset in bp
	mov	di, ds:[si]	;point to instance data for object
	tst	bx		;are we seeking a specific master part
				;(Vis_offset, Gen_offset, etc)
	jz	noMaster	;skip if not...

EC <	test	bx, 1		;make sure even			>
EC <	ERROR_NZ FLOW_ERROR_BAD_MASTER_OFFSET				>	
EC <	cmp	bx, size MetaInstance					>
EC <	ERROR_B FLOW_ERROR_BAD_MASTER_OFFSET				>	
EC <	cmp	bx, (size MetaInstance + (16 * size word))		>
EC <	ERROR_A	FLOW_ERROR_BAD_MASTER_OFFSET				>
	;push di fowards to the start of this master part in this
	;object's instance data

	add	di, ds:[di][bx]	; add in master offset

noMaster:
	add	di, bp		;push di forwards in instance data to point
				;to specific field.
EC <	push	cx, dx							>
EC <	mov	cx, ds:[di].BG_OD.handle				>
EC <	mov	dx, ds:[di].BG_OD.chunk					>
EC <	call	ECCheckLMemObject					>
EC <	pop	cx, dx							>
	ret
FlowPointToField	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FlowReleaseGrab

DESCRIPTION:	Releases grab for current OD, if it matches that passed.
		the object is sent a LOST_GRAB message (if specified), &
		then the OD & data word is zeroed out to indicate no 
		current grab.


CALLED BY:	GLOBAL

PASS:	*ds:si	- Object instance data
	ax = NULL for no message to be sent, else:
	     ax+0 = "GAINED_GRAB" message to send to new object gaining grab
	     ax+1 = "LOST_GRAB" message to send to object losing grab
	bx	- offset to MasterPart holding BasicGrab structure (0 if
		  no master parts)
	di	- offset to BasicGrab structure
	cx:dx	- OD to match with

RETURN:
	carry	- set if grab OD changed, & therefore methods were sent out
	ds - updated to point at segment of same block as on entry
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
	Eric	2/90		cleanup, showcalls work.
------------------------------------------------------------------------------@


FlowReleaseGrab	proc	far	uses	di, bp
	.enter
EC <	call	ECCheckODCXDX						>
EC <	call	ECCheckFlowExcl						>

	tst	cx			; if releasing for "nothing",
	jz	FRG_done		; exit w/carry clear

	; Make sure that the requesting object currently has the grab
	;
	call	FlowPointToField	;set *ds:di = instance data field,
				 	;returns bp = original di value
	cmp	cx, ds:[di].handle
	clc
	jne	FRG_done		;skip to end if not (CY=0)...
	cmp	dx, ds:[di].chunk
	clc
	jne	FRG_done		;skip to end if not (CY=0)...

	call	FlowReleaseLow

FRG_done label near			; REQUIRED BY SHOWCALLS IN SWAT
	ForceRef	FRG_done
	.leave
	ret
FlowReleaseGrab	endp

;
;---
;

FlowReleaseLow	proc	near	uses	ax
	.enter

EC <	; try to make sure we're pointing to a valid grab struc	>
EC <	push	cx, dx						>
EC <	mov	cx, ds:[di].HG_OD.handle			>
EC <	mov	dx, ds:[di].HG_OD.chunk				>
EC <	call	ECCheckODCXDX					>
EC <	pop	cx, dx						>

	tst	ds:[di].BG_OD.handle		; If nothing has grab, done.
	jz	done

	; Send "LOSS" message
	;
	tst	ax				; unless no mesage to send
	jz	afterMessageAndDeref

	inc	ax				;get "Loss" message to send
	call	FlowSendMessageToGrab

	; & clear out grab info, since no longer has grab.
	;
	mov	di, bp
	call	FlowPointToField	;set *ds:di = instance data field,

afterMessageAndDeref:
	clr	ax
	mov	ds:[di].BG_OD.handle, ax
	mov	ds:[di].BG_OD.chunk, ax
	mov	ds:[di].BG_data, ax

done:
	.leave
	ret
FlowReleaseLow	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FlowRequestGrab

DESCRIPTION:	Grants grab to OD passed if there is no grab active.  If
		the OD passed matches that in existance, the data word is
		updated & no message sent.

		Stores new data, & then sends GAINED_GRAB to any new OD.

CALLED BY:	GLOBAL

PASS:	*ds:si	- Object instance data
	ax = NULL for no message to be sent, else:
	     ax+0 = "GAINED_GRAB" message to send to new object gaining grab
	     ax+1 = "LOST_GRAB" message to send to object losing grab
	bx	- offset to MasterPart holding BasicGrab structure (0 if
		  no master parts)
	di	- offset to BasicGrab structure
	cx:dx	- OD of requesting object
	bp	- Data to be place in BG_data field

RETURN:
	carry	- set if grab OD changed, & therefore methods were sent out
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
	Doug	8/89		Initial version
	Eric	2/90		cleanup, showcalls work.
------------------------------------------------------------------------------@


FlowRequestGrab	proc	far	uses	di
	.enter
	tst	cx			; if nothing making request, just exit.
	jz	FRqG_done

EC <	call	ECCheckODCXDX						>
EC <	call	ECCheckFlowExcl						>

	push	bp			; save passed data on stack

	call	FlowPointToField	; set *ds:di = instance data field,
				 	; returns bp = original di value

	pop	bp			; get back passed data.  We won't need
					; the offset again.

	; If object requesting grab already has it, just update the data
	; field.
	;
	cmp	cx, ds:[di].BG_OD.handle
	jne	notSameObject
	cmp	dx, ds:[di].BG_OD.chunk
	jne	notSameObject

	mov	ds:[di].BG_data, bp
	jmp	short FRqG_done

notSameObject:

	; Check the Grab structure to see if the grab is already owned
	; by some other object.  If so, ignore request.
	;
	tst	ds:[di].BG_OD.handle
	jnz	FRqG_done

	call	FlowGrabLow

FRqG_done label near			; REQUIRED BY SHOWCALLS IN SWAT
	ForceRef	FRqG_done
	.leave
	ret

FlowRequestGrab	endp

;
;---
;

FlowGrabLow	proc	near
EC <	; try to make sure we're pointing to a valid grab struc	>
EC <	push	cx, dx						>
EC <	mov	cx, ds:[di].HG_OD.handle			>
EC <	mov	dx, ds:[di].HG_OD.chunk				>
EC <	call	ECCheckODCXDX					>
EC <	pop	cx, dx						>

	; Award grab to requesting object
	;
	mov	ds:[di].BG_OD.handle, cx
	mov	ds:[di].BG_OD.chunk, dx
	mov	ds:[di].BG_data, bp

	; Send "GAINED" message
	;
	call	FlowSendMessageToGrab

	ret
FlowGrabLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			FlowSendMessageToGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine -- sends a messages to the specified grab

CALLED BY:	INTERNAL
PASS:		ds:di	- pointer to Grab structure
		ax, cx, dx, bp	- message paramaters
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FlowSendMessageToGrab	proc	near	uses	bx, si, di, bp
	.enter

	; Send message to next object down in hierarchy.  Pass flags in bp.
	;
	tst	ax			; if no message, done
	jz	done
	mov	bx, ds:[di].BG_OD.handle
	tst	bx			; if no object, done
	jz	done

	mov	si, di
	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di
	mov	di, si

	mov	si, ds:[di].BG_OD.chunk
	mov	bp, ds:[di].BG_data
	mov	di, mask MF_FIXUP_DS
FSMTG_send label near			; REQUIRED BY showcalls -[he] IN SWAT
	ForceRef	FSMTG_send
	call	ObjMessage

	pop	di
	call	ThreadReturnStackSpace

done:
	.leave
	ret

FlowSendMessageToGrab	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	FlowGainedAppExcl

DESCRIPTION:	Sets the HGF_APP_EXCL bit, & sends the "GAINED_APP_EXCL
		message on to any current grab.

PASS:	*ds:si 	- instance data
	
	ax = NULL for no message to be sent, else:
	     "GAINED_APP_EXCL" message to send to any object having grab
		within node
	bx - offset to master instance
	di - offset to field of type "HierarchicalGrab" in instance data


RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version
	Eric	2/90		cleanup, showcalls work, DUAL GRAB stuff.

------------------------------------------------------------------------------@

FlowGainedAppExcl	proc	near	uses	di, bp
	.enter

EC <	call	ECCheckFlowExcl						>

	call	FlowPointToField	;set ds:di = Grab structure in instance

EC <	test	ds:[di].HG_flags, mask HGF_APP_EXCL		>
EC <	ERROR_NZ FLOW_ERROR_HIERARCHICAL_NODE_ALREADY_HAS_APP_EXCL	>

	; Set flag indicating this node has the exclusive, BEFORE
	; sending notification to the object having the grab below this node
	;
	ornf	ds:[di].HG_flags, mask HGF_APP_EXCL

	; Now inform object having the grab within this node, if any, that
	; it has it again.
	;

	call	FlowSendMessageToGrab

FGAE_done label near			; REQUIRED BY showcalls -[he] IN SWAT
	ForceRef	FGAE_done
	.leave
	ret

FlowGainedAppExcl	endp


;
;------
;

if	ERROR_CHECK
ECCheckFlowExcl	proc	near	uses	cx, dx, di, bp
	.enter

	call	ECCheckLMemObject

	cmp	di, MAX_INSTANCE_OFFSET
	ERROR_A	FLOW_ERROR_BAD_INSTANCE_OFFSET

	tst	bx			;this routine cannot be used
	jz	masterOK
	test	bx, 1
	ERROR_NZ	FLOW_ERROR_BAD_MASTER_OFFSET
	cmp	bx, size MetaInstance
	ERROR_B	FLOW_ERROR_BAD_MASTER_OFFSET
	cmp	bx, (size MetaInstance + (16 * size word))
	ERROR_A	FLOW_ERROR_BAD_MASTER_OFFSET
masterOK:

	; Check for bad HG structure
	;
	call	FlowPointToField	;set ds:di = Grab structure in instance
	mov	cx, ds:[di].HG_OD.handle
	mov	dx, ds:[di].HG_OD.chunk
	call	ECCheckODCXDX

	.leave
	ret
ECCheckFlowExcl	endp
endif



COMMENT @----------------------------------------------------------------------

ROUTINE:	FlowLostAppExcl

DESCRIPTION:	Sends the "LOST_APP_EXCL" on to any object having a grab
		here, & then clears the HGF_APP_EXCL bit for the node.

PASS:	*ds:si 	- instance data
	ax = NULL for no message to be sent, else:
	     "LOST_APP_EXCL" message to send to any object having grab
		within node
	bx - offset to master instance
	di - offset to field of type "HierarchicalGrab" in instance data

RETURN:
	ds - updated to point at segment of same block as on entry
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version
	Eric	2/90		cleanup, showcalls work, DUAL_GRAB stuff.

------------------------------------------------------------------------------@


FlowLostAppExcl	proc	near	uses	di, bp
	.enter

EC <	call	ECCheckFlowExcl						>

	call	FlowPointToField	;set ds:di = Grab structure in instance

EC <	test	ds:[di].HG_flags, mask HGF_APP_EXCL			>
EC <	ERROR_Z FLOW_ERROR_HIERARCHICAL_NODE_DOES_NOT_HAVE_APP_EXCL	>

	; Now inform object having the grab below this node, if any, that
	; it no longer has the grab
	;
	call	FlowSendMessageToGrab

	; Clear bit indicating this node doesn't have exclusive,
	; AFTER we've notified object having grab below this node.
	;
	mov	di, bp
	call	FlowPointToField	;set ds:di = Grab structure in instance
	andnf	ds:[di].HG_flags, not mask HGF_APP_EXCL

FLAE_done label near			;REQUIRED BY showcalls -[he] IN SWAT
	ForceRef	FLAE_done
	.leave
	ret
FlowLostAppExcl	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	FlowGainedSysExcl

DESCRIPTION:	Sets the HGF_SYS_EXCL bit, & sends the "GAINED_SYS_EXCL
		message on to any current grab.

PASS:	*ds:si 	- instance data
	ax = NULL for no message to be sent, else:
	     "GAINED_SYS_EXCL" message to send to any object having grab
		within node
	bx - offset to master instance
	di - offset to field of type "HierarchicalGrab" in instance data

RETURN:
	ds - updated to point at segment of same block as on entry
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version

------------------------------------------------------------------------------@

FlowGainedSysExcl	proc	near	uses	di, bp
	.enter
EC <	call	ECCheckFlowExcl						>

	call	FlowPointToField	;set ds:di = Grab structure in instance

EC <	test	ds:[di].HG_flags, mask HGF_APP_EXCL			>
EC <	ERROR_Z FLOW_ERROR_HIERARCHICAL_NODE_DOES_NOT_HAVE_APP_EXCL	>
EC <	test	ds:[di].HG_flags, mask HGF_SYS_EXCL			>
EC <	ERROR_NZ FLOW_ERROR_HIERARCHICAL_NODE_ALREADY_HAS_SYS_EXCL	>

	; Set flag indicating this node has the system exclusive, BEFORE
	; sending notification to the object having the grab below this node
	;
	ornf	ds:[di].HG_flags, mask HGF_SYS_EXCL

	call	FlowSendMessageToGrab

FGSE_done label near			;REQUIRED BY showcalls -[he] IN SWAT
	ForceRef	FGSE_done
	.leave
	ret
FlowGainedSysExcl	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	FlowLostSysExcl

DESCRIPTION:	Sends the "LOST_SYS_EXCL" on to any object having a grab
		here, & then clears the HGF_SYS_EXCL bit for the node.

PASS:	*ds:si 	- instance data
	ax = NULL for no message to be sent, else:
	     "LOST_SYS_EXCL" message to send to any object having grab
		within node
	bx - offset to master instance
	di - offset to field of type "HierarchicalGrab" in instance data

RETURN:
	ds - updated to point at segment of same block as on entry
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version

------------------------------------------------------------------------------@

FlowLostSysExcl	proc	near	uses	di, bp
	.enter
EC <	call	ECCheckFlowExcl						>

	call	FlowPointToField	;set ds:di = Grab structure in instance

EC <	test	ds:[di].HG_flags, mask HGF_SYS_EXCL			>
EC <	ERROR_Z FLOW_ERROR_HIERARCHICAL_NODE_DOES_NOT_HAVE_SYS_EXCL	>
EC <	test	ds:[di].HG_flags, mask HGF_APP_EXCL			>
EC <	ERROR_Z FLOW_ERROR_HIERARCHICAL_NODE_DOES_NOT_HAVE_APP_EXCL	>

	call	FlowSendMessageToGrab

	; Clear bit indicating this node doesn't have system exclusive,
	; AFTER we've notified grab below this node.
	;
	mov	di, bp
	call	FlowPointToField	;set ds:di = Grab structure in instance
	andnf	ds:[di].HG_flags, not mask HGF_SYS_EXCL

FLSE_done label near			;REQUIRED BY showcalls -[he] IN SWAT
	ForceRef	FLSE_done
	.leave
	ret
FlowLostSysExcl	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	FlowUpdateHierarchicalGrab

DESCRIPTION:	Update exclusive based on passed method

PASS:	*ds:si 	- instance data
	
	ax - "GAINED_APP_EXCL", "LOST_APP_EXCL", "GAINED_SYS_EXCL" or
	     "LOST_SYS_EXCL" message to be implemented

	bx - offset to master instance
	di - offset to field of type "HierarchicalGrab" in instance data

	bp = BASE method for level exclusive:
		bp+0 = "GAINED_APP_EXCL" method to send requesting object
			if it gains excl.
		bp+1 = "LOST_APP_EXCL" method to send when requesting object
			eventually loses the exclusive.
		bp+2 = "GAINED_SYS_EXCL" message which is sent out after the
			"GAINED" message, to the object that gains the exlcusive
			if the "HGF_SYS_EXCL" bit is set in this node.
		bp+3 = "LOST_SYS_EXCL" message which is sent out before the
			"LOST" message to any object losing the exclusive, if
			this node has the SYSTEM exclusive itself.

RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/92		Initial version

------------------------------------------------------------------------------@

FlowUpdateHierarchicalGrab	proc	far	uses	bp
	.enter
	push	ax		; save message to do
	sub	ax, bp		; get offset to correct routine in table below
EC <	cmp	ax, size flowUpdateTable				>
EC <	jb	ok							>
EC <	ERROR	FLOW_BAD_MESSAGE_COMBO_PASSED_TO_FlowUpdateHierarchicalGrab		>
EC <ok:									>
	shl	ax, 1
	mov	bp, ax
	pop	ax		; restore message to do
	call	cs:[flowUpdateTable][bp]
	.leave
	ret
FlowUpdateHierarchicalGrab	endp

flowUpdateTable nptr \
	offset FlowGainedAppExcl,
	offset FlowLostAppExcl,
	offset FlowGainedSysExcl,
	offset FlowLostSysExcl



COMMENT @----------------------------------------------------------------------

ROUTINE:	FlowAlterHierarchicalGrab

DESCRIPTION:	Called to perform a grab or release for a particular object
		within a hiearchical grab structure.
		
		If the existing grab requests a grab, the only action taken
		is to update the HGF_OTHER_INFO data field stored in the 
		grab.

		Any object losing exclusives or the grab will first receive
		the LOST_SYS_EXCL message, if it had the sys excl, then
		LOST_APP_EXCL, if it had that.   Gaining objects will recieve
		GAINED_APP_EXCL, if the node has the app exclusive, then
		GAINED_SYS_EXCL, if the node has the system exclusive.  In
		each case, the stored data is preserved until *after* any LOST
		message is sent, & is udpate *before* any GAINED message is
		sent.
	
PASS:	*ds:si 	- instance data

	ax = BASE method for level exclusive:
		ax+0 = "GAINED" method to send requesting object if it gains
		        excl.
		ax+1 = "LOST" method to send when requesting object eventually
			loses the exclusive.
		ax+2 = "GAINED_SYS_EXCL" message which is sent out after the
			"GAINED" message, to the object that gains the exlcusive
			if the "HGF_SYS_EXCL" bit is set in this node.
		ax+3 = "LOST_SYS_EXCL" message which is sent out before the
			"LOST" message to any object losing the exclusive, if
			this node has the SYSTEM exclusive itself.

	bx	- offset to master instance
	di	- offset to field of type "HierarchicalGrab" in instance data
	cx:dx	- OD of object to be given the the exclusive for below this
		  level
	bp	- HierarchicalGrabFlags:
			HGF_GRAB		- set to grab, clear to release
			HGF_OTHER_INFO		- data to store, if grabbing

RETURN: nothing
	ds - updated to point at segment of same block as on entry

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:


PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version
	Eric	2/90		cleanup, showcalls work, DUAL_GRAB and
				keyboard synchronization work.
	Doug	9/91		Merged FlowGrabWithinLevel &
				       FlowReleaseWithinLevel
	Doug	9/92		Split above cases back out internally, for
					clarity & debugging ease

------------------------------------------------------------------------------@

FlowAlterHierarchicalGrab	proc	far
EC <	call	ECCheckODCXDX						>
EC <	call	ECCheckFlowExcl						>
EC <	test	bp, not (mask HGF_GRAB or mask HGF_OTHER_INFO)		>
EC <	ERROR_NZ	FLOW_BAD_FLAGS_PASSED_TO_FlowAlterHierarchicalGrab	>

	test	bp, mask HGF_GRAB
	jnz	grab

	GOTO	FlowReleaseWithinLevel
grab:
	FALL_THRU	FlowGrabWithinLevel

FlowAlterHierarchicalGrab	endp


;-----------------------------------------------------------------------

FlowGrabWithinLevel	proc	far	uses	ax, cx, dx, di, bp
	.enter

EC <	cmp	cx, ds:[LMBH_handle]					>
EC <	jne	ok							>
EC <	cmp	dx, si							>
EC <	ERROR_Z	FLOW_HIERARCHICAL_GRAB_ERROR_CAN_NOT_GRAB_FROM_SELF	>
EC <ok:									>

					;Save params on stack for later use:
	push	ax			;save passed method value

	mov	ax, bp			;save passed flags in ax

	call	FlowPointToField	;set ds:di = Grab structure in instance

	test	ds:[di].HG_flags, mask HGF_APP_EXCL
	jnz	hasAppExclusive		;if so, branch to let new window
					;have focus...

fixStackUpdateAll:
	add	sp, 2			;nuke "method value" on stack

	; OTHERWISE, just store in exclusive spot so that this window will be
	; given the exclusive when the window is made active again.

	mov	ds:[di].HG_OD.handle, cx
	mov	ds:[di].HG_OD.chunk, dx
					; Update "other info"
	andnf	ds:[di].HG_flags, not (mask HGF_OTHER_INFO)
	andnf	ax, mask HGF_OTHER_INFO
	tst	cx			; If non-ZERO OD passed, set GRAB bit
	jz	afterGrabBitSet
	or	ax, mask HGF_GRAB	; show that grab exists
afterGrabBitSet:
	ornf	ds:[di].HG_flags, ax
	jmp	FGWL_done

;-----------------

hasAppExclusive:

	; See if OD is changing.  If not, just update data
	;
	cmp	cx, ds:[di].HG_OD.handle	; see if OD is different
	jne	somethingChanging
	cmp	dx, ds:[di].HG_OD.chunk
	je	fixStackUpdateAll

somethingChanging:

	test	ds:[di].HG_flags, mask HGF_SYS_EXCL

	mov	di, bp			; pass offset to field in di
	mov	bp, ax			; pass new HG_flags value in bp
	pop	ax

	; Release system exclusive from node temporarily, so grab below us
	; will get LOST_SYS message
	;
	pushf				; save "system" flag
	jz	afterLostSystem
	push	ax
	add	ax, 3			; get ax = LOST_SYS message
	call	FlowLostSysExcl	; downgrade old owner of exclusive
	pop	ax
afterLostSystem:

	; Release exclusive from node temporarily, so grab below us gets
	; LOST message
	;
	push	ax

	add	ax, 1			; get ax = LOST message
	call	FlowLostAppExcl		; release exclusive from old owner

	; Now, change the grab itself, (no messages for grab changes in
	; hierarchical exclusives at this time)

	clr	ax			; no messages
	and	bp, mask HGF_OTHER_INFO	; Prep data to store for new grab
	or	bp, mask HGF_GRAB
	call	FlowForceGrab

	pop	ax

	; Give exclusive back to the node, so that the grab gets a GAINED
	; message
	;
	call	FlowGainedAppExcl

	; Grant system-exclusive if in effect

	popf				; get "system" flag
	jz	FGWL_done
	add	ax, 2			; get ax = GAINED_SYS_EXCL message
	call	FlowGainedSysExcl

FGWL_done label near			; REQUIRED BY showcalls -[he] IN SWAT
	ForceRef	FGWL_done
	.leave
	ret

FlowGrabWithinLevel	endp

;-----------------------------------------------------------------------

FlowReleaseWithinLevel	proc	far	uses	ax, cx, dx, di, bp
	.enter

	call	FlowPointToField	;set ds:di = Grab structure in instance

	; FIRST, make sure that OD passed currently has the grab within
	; this level.  If not, then it has already been "released", & we
	; are all done.
	;
	cmp	cx, ds:[di].HG_OD.handle
	jne	FRWL_done
	cmp	dx, ds:[di].HG_OD.chunk
	jne	FRWL_done

	; NEXT, see if node has exclusive
	;
	test	ds:[di].HG_flags,  mask HGF_APP_EXCL
	jnz	hasAppExcl		; if so, branch to release
					; window focus

	; OTHERWISE, just clear exclusive,
	; without sending out LOST method, so that no window will be given the
	; exclusive when the window has focus again

;clearOutGrab:
	clr	ax
	mov	ds:[di].HG_OD.handle, ax
	mov	ds:[di].HG_OD.chunk, ax
	andnf	ds:[di].HG_flags, not (mask HGF_OTHER_INFO)
	jmp	FRWL_done

;-----------------

hasAppExcl:

	; Save bit indicating if had system-wide exclusive (so we can restore
	; flag later)
	;
	test	ds:[di].HG_flags, mask HGF_SYS_EXCL
	pushf				; save "system" flag

	mov	di, bp			; pass offset to field in di

	;This object has the HierachicalGrab for this level
	;(meaning among its siblings).

	; Release system exclusive from node temporarily, so grab below us
	; will get LOST_SYS message
	;
	jz	afterLostSystem
	push	ax
	add	ax, 3			; get ax = LOST_SYS message
	call	FlowLostSysExcl	; downgrade old owner of exclusive
	pop	ax
afterLostSystem:

	; Release exclusive from node temporarily, so grab below us gets
	; LOST message
	;
	add	ax, 1			; get ax = LOST message
	call	FlowLostAppExcl		; release exclusive from old owner

	call	FlowPointToField	; set ds:di = Grab structure in instance

	; Finally, release grab itself (no messages for grab changes in
	; hierarchical exclusives at this time)
	;
	clr	ax			; no messages.  NOTE deref optimization
	call	FlowReleaseLow		;	below if you change this!

	; Fixup node to have correct exclusives set
	;
	popf
	jz	afterSetSysFlag

	; OK to directly acess data here ONLY if ax=0 passed to FlowReleaseLow
	; above, as this results in no messages being sent, & eliminates the
	; need to dereference again.
	;
	ornf	ds:[di].HG_flags, mask HGF_SYS_EXCL

afterSetSysFlag:
					; restore exclusive bit, as node
					; still has exclusive
	ornf	ds:[di].HG_flags, mask HGF_APP_EXCL

FRWL_done label near			; REQUIRED BY showcalls -[he] IN SWAT
	.leave
	ret

FlowReleaseWithinLevel	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	FlowDispatchSendOnOrDestroyClassedEvent

DESCRIPTION:

PASS:	*ds:si 	- instance data

	ax - method to send on
	cx - handle of classed event.  If Class is null, event should be
	     sent directly on to optr in bx:bp
	dx - other data to send on

	bx:bp	- optr to send on to, if this object isn't of the class
		  required for the event to be handled.  If optr is null,
		  & event can't be delivered at current object, destroy event.

	di	- MessageFlags for data to send on  (MF_CALL also passed
		  on to ObjDispatchMessage, if used, in order to allow for
		  return data)

RETURN:	If no destination:
		carry returned clear.
	otherwise:
		carry is returned as per ObjMessage.
	If MF_CALL passed, & call completed:
		ax, cx, dx, bp hold return values

	If MF_FIXUP_DS passed:
		ds - updated to point at segment of same block as on entry

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

FlowDispatchSendOnOrDestroyClassedEvent	proc	far
EC <	call	ECCheckLMemObject					>
EC <	call	ECCheckStack						>

	push	ax, cx, si

	push	si			; save object chunk
	push	bx
	mov	bx, cx
	call	ObjGetMessageInfo
	pop	bx
	pop	ax			; restore object chunk here
	tst	cx			; make sure we've got a class to
					; test against.
	jnz	realTest		; if real class, do test

	; If class is null, see if we're at leaf or not
	;
	tst	bx
	jnz	sendOnOrDestroy		; if node, send on
	jmp	short dispatchEvent	; otherwise dispatch the event

realTest:				; ax = object chunk
	push	di, es
	mov	es, cx			; Get class ptr in es:di
	mov	di, si
	mov	si, ax			; *ds:si = this object
	call	ObjIsObjectInClass	; see if we're the destination
	pop	di, es
	jnc	sendOnOrDestroy

dispatchEvent:

	pop	ax, cx, si

	push	di

	; Note that we cannot call ThreadBorrowStackSpace here since the
	; encapsulated message could reference the stack (and does, when
	; dealing with page numbers in the text object)

	mov	bx, cx			; bx = handle of event
	mov	cx, ds:[LMBH_handle]	; send here, to this object
	call	MessageSetDestination
					; allow these MessageFlags
	and	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	MessageDispatch

	pop	di
	ret

sendOnOrDestroy:

	pop	ax, cx, si

	push	si
	mov	si, bp
	call	FlowMessageClassedEvent
	pop	si
	ret

FlowDispatchSendOnOrDestroyClassedEvent	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	FlowMessageClassedEvent

DESCRIPTION:	Special version of ObjMessage for when cx = handle
		of ClassedEvent; if destination is null, the ClassedEvent is
		freed.  Deals correctly w/IACP completion messages.

PASS:	ax - method to send on
	cx - handle of classed event to send on or be destroyed
	dx, bp - other data to send on

	bx:si	- optr to send on to, if this object isn't of the class
		  required for the event to be handled.  If zero, & can't
		  be delivered here, destroy event.

	di	- MessageFlags

RETURN:	If no destination:
		carry returned clear.
	otherwise:
		carry is returned as per ObjMessage.
	If MF_CALL passed, & call completed:
		ax, cx, dx, bp hold return values


DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

FlowMessageClassedEvent	proc	far
	tst	bx
	jz	destroyEvent
	GOTO	ObjMessage

destroyEvent:
	call	FlowDestroyMessageInMessage
	clc			; ClassedEvent not sent on
	ret

FlowMessageClassedEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlowDestroyMessageInMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys events recorded & placed in a message, as is 
		appropriate for the message in which the event appears.
		Deals correctly w/IACP completion messages.

CALLED BY:	INTERNAL
PASS:		ax		- message
		cx, dx, bp	- message data, of which cx is a recorded
				  message of some type.
RETURN:
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FlowDestroyMessageInMessage	proc	far
        ; HACK FOR IACP: If the event is MSG_META_DISPATCH_EVENT with bp
        ; set to 0xadeb, it's a message that *must* be dispatched, as it's
        ; the completion message for an IACP transaction. Just dispatch it,
        ; rather than destroy it.
	;
	cmp	ax, MSG_META_DISPATCH_EVENT
	jne	reallyNukeIt
	cmp	bp, 0xadeb
	jne	reallyNukeIt
	mov	bx, cx			; get message to dispatch in bx
	mov	di, dx			; get MessageFlags to use
	GOTO	MessageDispatch		; Dispatch it.

reallyNukeIt:
	FALL_THRU	FlowDestroyMessage

FlowDestroyMessageInMessage	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FlowDestroyMessage

DESCRIPTION:	Destroy a recorded classed event, taking care of
		destroying any events passed as arguments to it, 
		recursively if necessary.

		NOTE! Use FlowDestroyMessageInMessage if you have the
		data required to do so, as IACP completion
		messages will otherwise not be handled correctly.

CALLED BY:	INTERNAL
		FlowDestroyMessageInMessage

PASS:		cx	= handle of event to destroy

RETURN:		nothing

DESTROYED:	bx, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/28/92	Initial version

------------------------------------------------------------------------------@
FlowDestroyMessage	proc	far
	uses	es, si, ax
	.enter
	;
	; See if the thing is classed, and if so whether it's a subclass of
	; GenClass so we know we can check the message number for something
	; we can handle.
	; 
	mov	bx, cx
	call	ObjGetMessageInfo

checkClassLoop:
	jcxz	checkMeta		; not Gen or Vis, but might be meta
					;  message we can look at anyway

	cmp	cx, segment GenClass
	jne	checkVis
	cmp	si, offset GenClass
	je	isGen

checkVis:
	cmp	cx, segment VisClass
	jne	gotoSuper
	cmp	si, offset VisClass
	je	isVis

gotoSuper:
	mov	es, cx
	test	es:[si].Class_flags, mask CLASSF_VARIANT_CLASS
	jnz	checkMeta

	movdw	cxsi, es:[si].Class_superClass
	jmp	checkClassLoop

isGen:
	cmp	ax, MSG_GEN_SEND_TO_CHILDREN
	je	recurse
	cmp	ax, MSG_GEN_CALL_PARENT
	je	recurse
	cmp	ax, MSG_GEN_SEND_TO_PARENT
	je	recurse
	cmp	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	je	recurse
	cmp	ax, MSG_GEN_GUP_SEND_TO_OBJECT_OF_CLASS
	je	recurse
	cmp	ax, MSG_GEN_CALL_APPLICATION
	je	recurse
	cmp	ax, MSG_GEN_SEND_TO_PROCESS
	je	recurse
	cmp	ax, MSG_GEN_CALL_SYSTEM
	je	recurse	

isVis:
	cmp	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	je	recurse
	cmp	ax, MSG_VIS_VUP_SEND_TO_OBJECT_OF_CLASS
	je	recurse
	cmp	ax, MSG_VIS_VUP_CALL_WIN_GROUP
	je	recurse
	cmp	ax, MSG_VIS_VUP_SEND_TO_WIN_GROUP
	je	recurse
	cmp	ax, MSG_VIS_CALL_PARENT
	je	recurse
	cmp	ax, MSG_VIS_SEND_TO_PARENT
	je	recurse
	cmp	ax, MSG_VIS_SEND_TO_CHILDREN
	je	recurse

checkMeta:
	cmp	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	je	decDataBlockRefCount
	cmp	ax, MSG_NOTIFY_FILE_CHANGE
	je	decDataBlockRefCount
	cmp	ax, MSG_META_GCN_LIST_SEND
	je	gcnListSend
	cmp	ax, MSG_META_SEND_CLASSED_EVENT
	je	recurse
	cmp	ax, MSG_META_DISPATCH_EVENT
	je	recurse

justDestroy:
	call	ObjFreeMessage
done:
	.leave
	ret

decDataBlockRefCount:
	;
	; Before freeing a MSG_META_NOTIFY_WITH_DATA_BLOCK event, any
	; data block passed must have its reference count decremented,
	; or it will be left on the heap.
	; 
	mov	ax, offset FlowDecRefCountOfBlockInMessage
	jmp	short justDestroy

gcnListSend:
	;
	; Before freeing a MSG_META_GCN_LIST_SEND event, we must
	; fetch the GCNLMP_event out the GCNListMessageParams passed,
	; free it, & dec the ref count of any data block.
	;
	mov	ax, offset FlowDestroyEventInGCNListSendMessage
	jmp	short processMessageCommon

recurse:
	;
	; Call ourselves to "process" the message, telling it to destroy the
	; message we're passing. Nested message always in CX in these
	; messages.
	; 
	mov	ax, offset FlowDestroyMessageInMessage

processMessageCommon:
NOFXIP <	push	cs			;push call-back routine	>
FXIP <		mov	si, SEGMENT_CS					>
FXIP <		push	si						>
	push	ax
	clr	si		; flag:  destroy original event
	call	MessageProcess
	jmp	done

FlowDestroyMessage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlowDestroyEventInGCNListSendMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleans up GCNListMessageParams of MSG_META_GCN_LIST_SEND,
		by freeing the stored event & decrementing the ref count
		of any data block, in the exact manner of the kernel's
		default handler for MSG_META_GCN_LIST_SEND.  Note that
		we use ObjFreeMessage to do the freeing, & not
		FlowDestroyMessage, as events stored in GCNListMessageParams
		must *not* have nested events within -- the kernel doesn't,
		& can't deal with this situation.  So we just mimic the
		freeing action in ObjMetaGCNListSend.

CALLED BY:	INTERNAL
PASS:		ax		- message
		ss:bp		- GCNListMessageParams
RETURN:
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/30/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlowDestroyEventInGCNListSendMessage	proc	far
	; free up event
	;
	mov     bx, ss:[bp].GCNLMP_event
	call	ObjFreeMessage

	; free up reference to block, if any
	;
	mov     bx, ss:[bp].GCNLMP_block
	call	MemDecRefCount
	ret
FlowDestroyEventInGCNListSendMessage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlowDecRefCountOfBlockInMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement reference count of block handle in bp.  Used to
		assist in destroying MSG_META_NOTIFY_WITH_DATA_BLOCK and
		MSG_NOTIFY_FILE_CHANGE

CALLED BY:	INTERNAL
PASS:		ax		- message
		bp		- data block whose ref count needs to be
				  decremented
RETURN:
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/30/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlowDecRefCountOfBlockInMessage	proc	far
	mov	bx, bp
	call	MemDecRefCount
	ret
FlowDecRefCountOfBlockInMessage	endp


Resident ends

;----------

FlowCommon	segment resource



COMMENT @----------------------------------------------------------------------

ROUTINE:	FlowGetTargetAtTargetLevel

DESCRIPTION:

PASS:	*ds:si 	- instance data

	bx - offset to master instance

	cx - TargetLevel searching for

	di - offset to targetExcl field of type "HierarchicalGrab"
	     in instance data of object in *ds:si
	ax - TargetLevel of object in *ds:si

RETURN:
	If THIS object is the object being searched for:
		cx:dx - this object
		ax:bp - class of this object
	If not, & there is no target below this node:
		cx, dx, ax, bp - 0
	Otherwise, target below this node is called to handle
	ds - updated to point at segment of same block as on entry

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/90		Initial version

------------------------------------------------------------------------------@

FlowGetTargetAtTargetLevel	proc	far	uses bx, si, di, es
	.enter
EC <	call	ECCheckLMemObject					>
EC <	cmp	bx, (size MetaInstance + (16 * size word))		>
EC <	ERROR_A	FLOW_ERROR_BAD_MASTER_OFFSET				>
	cmp	cx, ax			; looking for target at this level?
	jne	levelNotFound

	clr	cx			; change request to LEAF, call MetaClass
atLeaf:
	mov	di, segment MetaClass
	mov	es, di
	mov	di, offset MetaClass
					; send method on to child target
	mov	ax, MSG_META_GET_TARGET_AT_TARGET_LEVEL
	call	ObjCallClassNoLock
	jmp	short done

levelNotFound:
	mov	dx, di			; keep offset to targetExcl in dx
	mov	di, ds:[si]
	add	di, ds:[di][bx]		; add in master offset
	add	di, dx			; ds:[di] now points at HG

	tst	ds:[di].HG_OD.handle	; see if we're at leaf (nothing below
	jz	atLeaf			; us)

;sendOnDown:
					; Send request on to target below this
	mov	bx, ds:[di].HG_OD.handle
	mov	si, ds:[di].HG_OD.chunk
					; send method on to child target
	mov	ax, MSG_META_GET_TARGET_AT_TARGET_LEVEL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
FlowGetTargetAtTargetLevel	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	MetaGrabFocusExclLow

SYNOPSIS:	Grabs or releases the indicated exclusive(s) for the object.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89	Initial version
	Doug	9/26/91		Re-wrote for new FTVMC model

------------------------------------------------------------------------------@

MetaGrabFocusExclLow	proc	far
	push	bp
	mov	bp, mask MAEF_GRAB or mask MAEF_FOCUS or mask MAEF_NOT_HERE
	GOTO	VisAlterFTVMCExclCommon, bp
MetaGrabFocusExclLow	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	MetaReleaseFocusExclLow

SYNOPSIS:	Grabs or releases the indicated exclusive(s) for the object.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89	Initial version
	Doug	9/26/91		Re-wrote for new FTVMC model

------------------------------------------------------------------------------@
MetaReleaseFocusExclLow	proc	far
	push	bp
	mov	bp, mask MAEF_FOCUS or mask MAEF_NOT_HERE
	GOTO	VisAlterFTVMCExclCommon, bp
MetaReleaseFocusExclLow	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	MetaGrabTargetExclLow

SYNOPSIS:	Grabs or releases the indicated exclusive(s) for the object.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89	Initial version
	Doug	9/26/91		Re-wrote for new FTVMC model

------------------------------------------------------------------------------@
MetaGrabTargetExclLow	proc	far
	class	GenClass
	push	bp
	mov	bp, mask MAEF_GRAB or mask MAEF_TARGET or mask MAEF_NOT_HERE
	GOTO	VisAlterFTVMCExclCommon, bp
MetaGrabTargetExclLow	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	MetaReleaseTargetExclLow

SYNOPSIS:	Grabs or releases the indicated exclusive(s) for the object.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89	Initial version
	Doug	9/26/91		Re-wrote for new FTVMC model

------------------------------------------------------------------------------@
MetaReleaseTargetExclLow	proc	far
	push	bp
	mov	bp, mask MAEF_TARGET or mask MAEF_NOT_HERE
	GOTO	VisAlterFTVMCExclCommon, bp
MetaReleaseTargetExclLow	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	MetaGrabModelExclLow

SYNOPSIS:	Grabs or releases the indicated exclusive(s) for the object.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89	Initial version
	Doug	9/26/91		Re-wrote for new FTVMC model

------------------------------------------------------------------------------@
MetaGrabModelExclLow	proc	far
	push	bp
	mov	bp, mask MAEF_GRAB or mask MAEF_MODEL or mask MAEF_NOT_HERE
	GOTO	VisAlterFTVMCExclCommon, bp
MetaGrabModelExclLow	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	MetaReleaseModelExclLow

SYNOPSIS:	Grabs or releases the indicated exclusive(s) for the object.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89	Initial version
	Doug	9/26/91		Re-wrote for new FTVMC model

------------------------------------------------------------------------------@
MetaReleaseModelExclLow	proc	far
	push	bp
	mov	bp, mask MAEF_MODEL or mask MAEF_NOT_HERE
	GOTO	VisAlterFTVMCExclCommon, bp
MetaReleaseModelExclLow	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	MetaReleaseFTExclLow

SYNOPSIS:	Grabs or releases the Focus & Target for the object.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89	Initial version
	Doug	9/26/91		Re-wrote for new FTVMC model
	Doug	2/8/93		Changed to release FT only (to avoid GUP)

------------------------------------------------------------------------------@
MetaReleaseFTExclLow	proc	far
	push	bp
	mov	bp, mask MAEF_FOCUS or mask MAEF_TARGET or \
		    mask MAEF_NOT_HERE
	FALL_THRU	VisAlterFTVMCExclCommon, bp
MetaReleaseFTExclLow	endp

VisAlterFTVMCExclCommon	proc	far	uses	ax, cx, dx, di
	.enter
	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
	call	ThreadReturnStackSpace
	.leave
	FALL_THRU_POP	bp
	ret
VisAlterFTVMCExclCommon	endp


FlowCommon	ends
