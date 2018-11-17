COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		The GrObj
FILE:		bodyUI.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/16/91	Initial Revision 
	jon	30 mar 1992	stole from chart

DESCRIPTION:

	$Id: bodyUI.asm,v 1.1 97/04/04 18:07:52 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUpdateUIControllers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query each of the selected charts for their
		attributes, and update the UI appropriately.

CALLED BY:

PASS:		*ds:si - GrObjBody
		ds:di - GrObjBody
		cx - GrObjUINotificationTypes (record)

			GOUINT_STYLE
			GOUINT_AREA
			GOUINT_LINE
			GOUINT_GROBJ_SELECT
			GOUINT_STYLE_SHEET
			GOUINT_SELECT
		
RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jon	1 apr 92 (really)	Initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUpdateUIControllers	method dynamic GrObjBodyClass,
				MSG_GB_UPDATE_UI_CONTROLLERS

	uses	cx,dx,bp
	.enter

	;
	; Check the open bit (kinda weak...)
	;
	test	ds:[di].GBI_fileStatus, mask GOFS_OPEN
	jz	done

	;
	; Only want to notify if we're the target
	;
	test	ds:[di].GBI_fileStatus, mask GOFS_TARGETED
	jz	done

	tst	ds:[di].GBI_suspendCount
	jz	updateNow

	rept	offset GBUO_UI_NOTIFY
	shl	cx
	endm
	or	ds:[di].GBI_unsuspendOps, cx

done:
	.leave
	ret

updateNow:

	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di

	;
	;	Handle the GOUINT_SELECT within the body
	;
	test	cx, mask GOUINT_SELECT
	jz	checkStyle

	call	GrObjBodyUpdateEditController
	BitClr	cx, GOUINT_SELECT

checkStyle:
	;
	;	If either line or area are to be updated, we also want
	;	to do style...
	;
	test	cx, mask GOUINT_AREA or mask GOUINT_LINE
	jz	afterStyle
	BitSet	cx, GOUINT_STYLE
afterStyle:
	mov	bp, offset GrObjNotificationTable

startLoop:
	; push the next bit off the face of the earth
	shl	cx, 1
	jnc	nextOne

	push	cx

	; Send the event to the chart objects that will combine the
	; notification data. 

	mov	ax, cs:[bp].GONTE_message
	tst	ax
	jz	updateController
	mov	bx, cs:[bp].GONTE_size
	mov	cx, cs:[bp].GONTE_initialFlags
	mov	di, cs:[bp].GONTE_initialFlagsOffset
	call	GrObjBodySendCombineEventToSelectedGrObjsAndEditGrab
	jc	popNextOne

	cmp	ax, MSG_GO_COMBINE_AREA_NOTIFICATION_DATA
	je	checkGradient
	
	; Now, update the UI controller

updateController:
	mov	cx, cs:[bp].GONTE_gcnListType
	mov	dx, cs:[bp].GONTE_notificationType
	call	GrObjGlobalUpdateControllerLow

popNextOne:
	pop	cx

nextOne:
	jcxz	updateDone
	add	bp, size GrObjNotificationTableEntry
	cmp	bp, offset GrObjNotificationTableEnd
	jne	startLoop

updateDone:
	pop	di
	call	ThreadReturnStackSpace
	jmp	done

checkGradient:
	push	ax, es
	call	MemLock
	mov	es, ax
	test	es:[GNAAC_areaAttrDiffs], mask GOBAAD_MULTIPLE_ELEMENT_TYPES
	pushf
	cmp	es:[GNAAC_areaAttr].GOBAAE_aaeType, GOAAET_GRADIENT
	call	MemUnlock
	je	popUpdateExtended
	popf
	pop	ax, es
	jz	sendBlankExtended
	jmp	updateExtended

popUpdateExtended:
	popf
	pop	ax, es
	;
	;  OK, one of our grobjies had a funky area element type, so
	;  we want to do a gradient update, too.
	;
updateExtended:
	push	ax
	mov	ax, MSG_GB_UPDATE_EXTENDED_AREA_ATTR_CONTROLLERS
	call	ObjCallInstanceNoLock
	pop	ax
	jmp	updateController

sendBlankExtended:

	push	ax
	mov	ax, MSG_GB_UPDATE_EXTENDED_AREA_ATTR_CONTROLLERS_WITH_DEFAULTS
	call	ObjCallInstanceNoLock
	pop	ax
	jmp	updateController
GrObjBodyUpdateUIControllers	endm

GrObjNotificationTable	GrObjNotificationTableEntry \
\
	<MSG_GO_COMBINE_STYLE_NOTIFICATION_DATA,
	 size NotifyStyleChange,
	 CA_NULL_ELEMENT,
	 offset NSC_styleToken,
	 GAGCNLT_APP_TARGET_NOTIFY_STYLE_GROBJ_CHANGE,
	 GWNT_STYLE_CHANGE>,

	<MSG_GO_COMBINE_AREA_NOTIFICATION_DATA,
	 size GrObjNotifyAreaAttrChange,
	 mask GOBAAD_FIRST_RECIPIENT,
	 offset GNAAC_areaAttrDiffs,
	 GAGCNLT_APP_TARGET_NOTIFY_GROBJ_AREA_ATTR_CHANGE,
	 GWNT_GROBJ_AREA_ATTR_CHANGE>,

	<MSG_GO_COMBINE_LINE_NOTIFICATION_DATA,
	 size GrObjNotifyLineAttrChange,
	 mask GOBLAD_FIRST_RECIPIENT,
	 offset GNLAC_lineAttrDiffs,
	 GAGCNLT_APP_TARGET_NOTIFY_GROBJ_LINE_ATTR_CHANGE,
	 GWNT_GROBJ_LINE_ATTR_CHANGE>,

	<MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA,
	 size GrObjNotifySelectionStateChange,
	 0,
	 offset GONSSC_selectionState + offset GSS_numSelected,
	 GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE,
	 GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>,

	<MSG_GO_COMBINE_STYLE_SHEET_NOTIFICATION_DATA,
	 size NotifyStyleSheetChange,
	 0,
	 offset NSSHC_counter,
	 GAGCNLT_APP_TARGET_NOTIFY_STYLE_SHEET_GROBJ_CHANGE,
	 GWNT_STYLE_SHEET_CHANGE>

GrObjNotificationTableEnd	label	word


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUpdateExtendedAreaAttrControllers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_UPDATE_EXTENDED_AREA_ATTR_CONTROLLERS

Called by:	

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUpdateExtendedAreaAttrControllers	method dynamic	GrObjBodyClass,
				MSG_GB_UPDATE_EXTENDED_AREA_ATTR_CONTROLLERS
	uses	cx, dx

	.enter

	mov	ax, MSG_GO_COMBINE_GRADIENT_NOTIFICATION_DATA
	mov	bx, size GrObjNotifyGradientAttrChange 
	mov	cx, mask GOBAAD_FIRST_RECIPIENT
	mov	di, offset GONGAC_diffs
	call	GrObjBodySendCombineEventToSelectedGrObjsAndEditGrab
	jc	done

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_GRADIENT_ATTR_CHANGE
	mov	dx, GWNT_GROBJ_GRADIENT_ATTR_CHANGE
	call	GrObjGlobalUpdateControllerLow

done:
	.leave
	ret
GrObjBodyUpdateExtendedAreaAttrControllers	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	GrObjBodyUpdateExtendedAreaAttrControllersWithDefaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_UPDATE_EXTENDED_AREA_ATTR_CONTROLLERS_WITH_DEFAULTS

Called by:	

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUpdateExtendedAreaAttrControllersWithDefaults	method dynamic	GrObjBodyClass, MSG_GB_UPDATE_EXTENDED_AREA_ATTR_CONTROLLERS_WITH_DEFAULTS

	uses	cx, dx
	.enter

	mov	bx, size GrObjNotifyGradientAttrChange 
	call	GrObjGlobalAllocNotifyBlock
	jc	done

	call	MemLock
	jc	done
	mov	es, ax
	mov	es:[GONGAC_type], GOGT_NONE
	mov	es:[GONGAC_endR], 0
	mov	es:[GONGAC_endG], 0
	mov	es:[GONGAC_endB], 0
	mov	es:[GONGAC_numIntervals], DEFAULT_NUMBER_OF_GRADIENT_INTERVALS
	clr	es:[GONGAC_diffs]
	call	MemUnlock

	push	cx, dx
	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_GRADIENT_ATTR_CHANGE
	mov	dx, GWNT_GROBJ_GRADIENT_ATTR_CHANGE
	call	GrObjGlobalUpdateControllerLow
	pop	cx, dx

done:
	.leave
	ret
GrObjBodyUpdateExtendedAreaAttrControllersWithDefaults	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyGenerateTextNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_GENERATE_TEXT_NOTIFY

		Sends a MSG_VIS_TEXT_GENERATE_NOTIFY with the passed
		structure to each of the selected GrObjText's, then
		forces the update

Called by:	

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

		ss:[bp] - VisTextGenerateNotifyParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGenerateTextNotify	method dynamic	GrObjBodyClass,
				MSG_GB_GENERATE_TEXT_NOTIFY
	.enter

	;
	; Check the open bit (kinda weak...)
	;
	test	ds:[di].GBI_fileStatus, mask GOFS_OPEN
	jz	done

	;
	; Only want to notify if we're the target
	;
	test	ds:[di].GBI_fileStatus, mask GOFS_TARGETED
	jz	done

	;
	; Need to check suspend bit
	;
	;		I'll add this later - steve
	;

	tst	ds:[di].GBI_suspendCount
	jz	updateNow

	mov	ax, ss:[bp].VTGNP_notificationTypes
	or	ds:[di].GBI_textUnsuspendOps, ax

done:
	.leave
	ret

updateNow:
	;
	;  Check to see if the edit is a text guardian
	;
	push	cx, dx, bp
	mov	cx, segment TextGuardianClass
	mov	dx, offset TextGuardianClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyMessageToEdit
	pop	cx, dx, bp
	jz	sendToSelected				;if no edit, send
	jnc	checkInit

	;
	;  Edit exists and is text guardian
	;
	mov	ss:[bp].VTGNP_sendFlags, mask VTNSF_SEND_AFTER_GENERATION or \
				 mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS or \
				mask VTNSF_RELAYED_TO_LIKE_TEXT_OBJECTS
	BitSet	ss:[bp].VTGNP_notificationTypes, VTNF_SELECT_STATE
	mov	ax, MSG_TG_GENERATE_TEXT_NOTIFY
	clr	di
	call	GrObjBodyMessageToEdit
	jmp	done

sendToSelected:
	;
	;  Indicate that the body is relaying the message to all of its
	;  selected text objects, then do it.
	;
	mov	ss:[bp].VTGNP_sendFlags, \
				 mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS or \
				mask VTNSF_RELAYED_TO_LIKE_TEXT_OBJECTS
	call	GrObjBodySendGenerateNotifyToSelectedGrObjTexts

checkInit:
	;
	;  If no text objects received the message, then we want the
	;  GOAM text to fill them in.
	;
	;  In either case, we want the GOAM text to update the app GCN lists
	;  with a non-null status.
	;
	mov	ax, mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS or \
		    mask VTNSF_RELAYED_TO_LIKE_TEXT_OBJECTS or \
		    mask VTNSF_STRUCTURE_INITIALIZED or \
		    mask VTNSF_SEND_ONLY

	test	ss:[bp].VTGNP_sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jnz	sendToGOAMText

	mov	ax, mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS or \
		    mask VTNSF_RELAYED_TO_LIKE_TEXT_OBJECTS or \
		    mask VTNSF_SEND_AFTER_GENERATION
sendToGOAMText:
	mov	ss:[bp].VTGNP_sendFlags, ax

	;
	;  Send the notification.
	;
	mov	ax, MSG_VIS_TEXT_GENERATE_NOTIFY
	clr	di
	call	GrObjBodyMessageToGOAMText
	jmp	done
GrObjBodyGenerateTextNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodySubstTextAttrToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_SUBST_TEXT_ATTR_TOKEN

		Sends a MSG_VIS_TEXT_SUBST_ATTR_TOKEN with the passed
		structure to each of the body's grobj texts.

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

		ss:[bp] - VisTextSubstAttrTokenParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySubstTextAttrToken	method dynamic	GrObjBodyClass,
				MSG_GB_SUBST_TEXT_ATTR_TOKEN
	.enter

	tst	ss:[bp].VTSATP_relayedToLikeTextObjects
	jz	sendToGOAM

	mov	ax, MSG_VIS_TEXT_SUBST_ATTR_TOKEN
	call	GrObjBodySendToGrObjTexts

done:
	.leave
	ret

sendToGOAM:
	mov	ax, MSG_GOAM_SUBST_TEXT_ATTR_TOKEN
	clr	di
	call	GrObjBodyMessageToGOAM
	jmp	done
GrObjBodySubstTextAttrToken	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyRecalcForTextAttrChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_RECALC_FOR_TEXT_ATTR_CHANGE

		Sends a MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE
		to each of the body's grobj texts.

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

		cx - nonzero if relayed to all text objects

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyRecalcForTextAttrChange	method dynamic	GrObjBodyClass,
				MSG_GB_RECALC_FOR_TEXT_ATTR_CHANGE
	uses	cx
	.enter

	jcxz	sendToGOAM

	mov	ax, MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE
	call	GrObjBodySendToGrObjTexts

done:
	.leave
	ret

sendToGOAM:
	mov	ax, MSG_GOAM_RECALC_FOR_TEXT_ATTR_CHANGE
	clr	di
	call	GrObjBodyMessageToGOAM
	jmp	done
GrObjBodyRecalcForTextAttrChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUpdateInstructionControllers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the controllers related to the body's instruction
		attributes

CALLED BY:

PASS:		*ds:si - GrObjBody
		ds:di - GrObjBody
		
RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jon	10 sep 1992		Initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUpdateInstructionControllers	method dynamic GrObjBodyClass,
				MSG_GB_UPDATE_INSTRUCTION_CONTROLLERS

	clr	bx
	test	ds:[di].GBI_fileStatus, mask GOFS_TARGETED
	jz	sendNotification
	
	mov	bx, size GrObjBodyNotifyInstructionFlags
	call	GrObjGlobalAllocNotifyBlock
	jc	done
	call	MemLock
	jc	done
	mov	es, ax
	mov	ax, ds:[di].GBI_drawFlags
	mov	es:[GBNIF_flags], ax
	mov	al, ds:[di].GBI_desiredHandleSize
	mov	es:[GBNIF_handleSize], al
	call	MemUnlock

sendNotification:
	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_INSTRUCTION_FLAGS_CHANGE
	mov	dx, GWNT_GROBJ_BODY_INSTRUCTION_FLAGS_CHANGE
	call	GrObjGlobalUpdateControllerLow

done:
	.leave
	ret
GrObjBodyUpdateInstructionControllers	endm



GrObjInitCode	ends

GrObjRequiredInteractiveCode segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUpdateEditController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sends out a GWNT_SELECT_STATE_CHANGE type notification
		depending on the state of the clipboard, etc.

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul  5, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUpdateEditController	proc	far
	uses	ax, bx, cx, dx, bp, es
	.enter

	;
	;  Make sure there's no edit grab that's taken over the edit menu
	;
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	tst	ds:[di].GBI_targetExcl.HG_OD.handle
	jnz	done

	clr	bp					;not quick
	call	GrObjTestSupportedTransferFormats
	mov	cx, 0					;assume not supported
	jnc	getNumSelected
	dec	cx

getNumSelected:
	mov	ax, MSG_GB_GET_NUM_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

	;
	;  Assume no grobjs, which means no selecting, no copying,
	;  and no deleting
	;
	clr	dx

	tst	bp
	jz	allocBlock

	;
	;  Check allowable locks
	;

	mov	ax, MSG_GO_COMBINE_LOCKS
	clr	bx
	mov	di,OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GrObjBodyProcessSelectedGrObjsCommon

allocBlock:
	mov	bx, size NotifySelectStateChange
	call	GrObjGlobalAllocNotifyBlock
	jc	done
	call	MemLock
	mov	es, ax
	mov	es:[NSSC_selectionType], SDT_GRAPHICS
	mov	es:[NSSC_selectAllAvailable], BB_TRUE

if 0	; This code is correct, but it uncovers a bug where if you select
	; everything, then delete it all, then undo the delete, select all
	; won't re-highlight, 'cause the edit controller's not being updated
	; on an undo. so i'd rather keep hings the way they are...
	;

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	tst	ds:[di].GBI_childCount
	jnz	checkCopy
	mov	es:[NSSC_selectAllAvailable], BB_FALSE

checkCopy:
endif
	mov	es:[NSSC_clipboardableSelection], BB_TRUE
	test	dx, mask GOL_COPY		;is something selectable?
	jnz	checkDelete
	mov	es:[NSSC_clipboardableSelection], BB_FALSE

checkDelete:
	mov	es:[NSSC_deleteableSelection], BB_TRUE
	test	dx, mask GOL_DELETE		;is something selectable?
	jnz	setPasteable
	mov	es:[NSSC_deleteableSelection], BB_FALSE
setPasteable:
	mov	es:[NSSC_pasteable], cl
	call	MemUnlock

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
	mov	dx, GWNT_SELECT_STATE_CHANGE
	call	GrObjGlobalUpdateControllerLow
done:
	.leave
	ret
GrObjBodyUpdateEditController	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjTestSupportedTransferFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Tests for "pasteable" formats on the clipboard

Pass:		bp - ClipboardItemFlags (CIF_QUICK)

Return:		carry set if pasteable format exists
			^lcx:dx - owner
		carry clear if no pasteable format exists
			cx,dx - trashed

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTestSupportedTransferFormats	proc	far
	uses	ax, bx, bp
	.enter

	call	ClipboardQueryItem
	tst_clc	bp
	jz	doneWithTransfer

	push	cx, dx				;save owner OD
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GROBJ
	call	ClipboardTestItemFormat
	jnc	cmcSupported

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT
	call	ClipboardTestItemFormat
	jnc	cmcSupported

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_BITMAP
	call	ClipboardTestItemFormat
	jnc	cmcSupported

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GRAPHICS_STRING
	call	ClipboardTestItemFormat

cmcSupported:
	cmc
	pop	cx, dx				;^lcx:dx <- owner

doneWithTransfer:
	pushf
	call	ClipboardDoneWithItem
	popf

	.leave
	ret
GrObjTestSupportedTransferFormats	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	GrObjBodySendCombineEventToSelectedGrObjsAndEditGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the event to the chart group

CALLED BY:

PASS:		ax - message to send to selected grobjs
		bx - size of notification block
		*ds:si - GrObjBody object

		di = offset within notification block to set flags
		cx = initial flags to set in notification block

RETURN:		carry if no memory available, else

		bx = notification block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendCombineEventToSelectedGrObjsAndEditGrab	proc far
	uses	ax,cx,bp,es
	.enter

	call	GrObjGlobalAllocNotifyBlock
	jc	done
	
	;
	;	Set any initial flags
	;
	push	ax				;save message
	call	MemLock
	jc	done
	mov	es, ax
	mov	es:[di], cx
	call	MemUnlock
	pop	ax				;ax <- message

	mov	cx, bx				;cx <- notify block

	call	GrObjBodyGetNumSelectedGrObjs
	tst	bp
	jz	sendToEdit

	call	GrObjBodySendToSelectedGrObjsTestAbort

clcDone:
	clc
done:
	.leave
	ret

sendToEdit:
	;
	;	See if the edit grab is around
	;
	mov	di,mask MF_FIXUP_DS
	call	GrObjBodyMessageToEdit
	jnz	clcDone
	
	;
	;	If not, send the message to the attribute manager
	;
	call	GrObjBodyMessageToGOAM
	jmp	clcDone


GrObjBodySendCombineEventToSelectedGrObjsAndEditGrab	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyGenerateSplineNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_GENERATE_SPLINE_NOTIFY

		Sends a MSG_SPLINE_GENERATE_NOTIFY with the passed
		structure to each of the selected GrObjSpline's, then
		forces the update

Called by:	

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

		ss:[bp] - VisSplineGenerateNotifyParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGenerateSplineNotify	method dynamic	GrObjBodyClass,
				MSG_GB_GENERATE_SPLINE_NOTIFY
	.enter

	;
	; Check the open bit (kinda weak...)
	;
	test	ds:[di].GBI_fileStatus, mask GOFS_OPEN
	jz	done

	;
	; Only want to notify if we're the target
	;
	test	ds:[di].GBI_fileStatus, mask GOFS_TARGETED
	jz	done

	;
	; Need to check suspend bit
	;
	;		I'll add this later - steve
	;

	;
	;  Check to see if the edit is a spline guardian
	;
	push	cx, dx, bp
	mov	cx, segment SplineGuardianClass
	mov	dx, offset SplineGuardianClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyMessageToEdit
	pop	cx, dx, bp
	jz	sendToSelected				;if no edit, send
	jnc	done

	;
	;  Edit exists and is spline guardian
	;
	ornf	ss:[bp].SGNP_sendFlags, mask SNSF_UPDATE_APP_TARGET_GCN_LISTS or mask SNSF_RELAYED_TO_LIKE_OBJECTS or mask SNSF_SEND_AFTER_GENERATION
	mov	ax, MSG_SG_GENERATE_SPLINE_NOTIFY
	clr	di
	call	GrObjBodyMessageToEdit
	jmp	done

sendToSelected:
	;
	;  Indicate that the body is relaying the message to all of its
	;  selected spline objects.  Have them generate the
	;  notification, but don't send anything yet...
	;

	BitSet	ss:[bp].SGNP_sendFlags, SNSF_RELAYED_TO_LIKE_OBJECTS
	andnf	ss:[bp].SGNP_sendFlags, not \
			(mask SNSF_SEND_AFTER_GENERATION or \
			mask SNSF_SEND_ONLY)
	mov	ax, MSG_SPLINE_GENERATE_NOTIFY
	call	GrObjBodySendToSelectedGrObjSplines


	test	ss:[bp].SGNP_sendFlags, mask SNSF_STRUCTURE_INITIALIZED
	jz	noSplinesSelected

	;
	; Otherwise, have the first selected spline do a send-only:
	;

	andnf	ss:[bp].SGNP_sendFlags, not (mask SNSF_NULL_STATUS or \
					      mask SNSF_SEND_AFTER_GENERATION)
	ornf	ss:[bp].SGNP_sendFlags, mask SNSF_SEND_ONLY or \
					 mask SNSF_UPDATE_APP_TARGET_GCN_LISTS
	;
	;  Send the notification.
	;
	clr	di
	call	GrObjBodySendToFirstSelectedGrObjSpline

done:
	.leave
	ret

	; this won't work, but the idea is there...

noSplinesSelected:
	
	;
	; SERIOUS HACK!!! There are no splines, so notify all the
	; controllers.  We rely (heavily) on the fact that if we 
	; set the right bits, the message we send to SplineClass won't
	; try to access any instance data. -chrisb
	;
	; *ds:si is currently pointing to the GrObjBody -- hope this
	; works... 
	;

	andnf	ss:[bp].SGNP_sendFlags, not (mask SNSF_STRUCTURE_INITIALIZED \
			or mask SNSF_SEND_AFTER_GENERATION)
	ornf	ss:[bp].SGNP_sendFlags, mask SNSF_NULL_STATUS or \
			mask SNSF_SEND_ONLY
	segmov	es, <segment VisSplineClass>, di
	mov	di, offset VisSplineClass
	mov	ax, MSG_SPLINE_GENERATE_NOTIFY
	call	ObjCallClassNoLock
	jmp	done


GrObjBodyGenerateSplineNotify	endm


GrObjRequiredInteractiveCode ends
