COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpUtils.asm

AUTHOR:		Gene Anderson, Oct 23, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/23/92		Initial revision


DESCRIPTION:
	Utility routines for the Help controller

	$Id: helpUtils.asm,v 1.1 97/04/07 11:47:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HUReportError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Report an error in a suitably annoying fashion

CALLED BY:	UTILITY
PASS:		ss:bp - inherited locals
		di - chunk of error
		*ds:si - help controller
RETURN:		ds fixed up
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	NOTE: argument 1 (if any) is replaced with the filename
	NOTE: argument 2 (if any) is replaced with the context name
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Multiple errors in the same file are not reported
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HUReportError		proc	near
	uses	di, si, bx, ax, cx
	class	HelpControlClass
HELP_LOCALS
	.enter	inherit

	;
	; No additional checking if this isn't status help
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].HelpControl_offset
	cmp	ds:[bx].HCI_helpType, HT_STATUS_HELP
	jne	noErrorFile			;branch if not status help
	;
	; See if we've had an error before
	;
	mov	ax, TEMP_HELP_ERROR_FILENAME
	call	ObjVarFindData
	jnc	noErrorFile			;branch if no previous error
	;
	; See if the this is the same file
	;
	push	si, di, es
	segmov	es, ss
	lea	di, ss:filename			;es:di <- filename of error
	mov	si, bx				;ds:si <- previous filename
	clr	cx				;cx <- NULL-terminated
	call	LocalCmpStrings
	pop	si, di, es
	LONG je	sameFileQuit			;branch if same file
noErrorFile:
	;
	; Save the file for next time if this
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].HelpControl_offset
	cmp	ds:[bx].HCI_helpType, HT_STATUS_HELP
	jne	noSaveFile
	push	si, di, es, ds
	segmov	es, ss
	lea	di, ss:filename			;es:di <- filename of error
	call	LocalStringSize			;cx <- size of string (w/o NULL)
	LocalNextChar escx			;cx <- one more for NULL
	call	ObjVarAddData
	mov	si, bx				;ds:si <- ptr to dest
	segxchg	ds, es				;es:di <- ptr to dest
	xchg	si, di				;ds:si <- ptr to source
	rep	movsb				;
	pop	si, di, es, ds
noSaveFile:
	;
	; Put up the error
	;	*ds:si = HelpControl
	;	di = error chunk
	;

	;
	; remove ourselves from ALWAYS_INTERACTABLE list during error
	; reporting
	;
	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	AddRemoveInteractable
	
	push	ds:[OLMBH_header].LMBH_handle
	push	si
	mov	si, di				;si <- chunk of error
	mov	bx, handle HelpControlStrings
	call	MemLock
	mov	ds, ax

	sub	sp, (size StandardDialogParams)
	mov	di, sp				;ss:di <- params
	mov	ss:[di].SDP_customFlags,
			(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE) or \
			mask CDBF_SYSTEM_MODAL
	lea	ax, ss:filename			;ss:ax <- filename
	movdw	ss:[di].SDP_stringArg1, ssax
	lea	ax, ss:context			;ss:ax <- context
	movdw	ss:[di].SDP_stringArg2, ssax
	mov	ax, ds:[si]			;ds:ax <- ptr to error message
	movdw	ss:[di].SDP_customString, dsax
	clr	ss:[di].SDP_helpContext.segment
	call	UserStandardDialog

	call	MemUnlock
	pop	si
	call	MemDerefStackDS			;*ds:si = HelpControl

	;
	; re-add ourselves to ALWAYS_INTERACTABLE list
	;
	mov	ax, MSG_META_GCN_LIST_ADD
	call	AddRemoveInteractable

	;
	; check if dialog, is so we'll be restoring focus to ourselves
	; (a hack to get the system help object the focus after an error
	; dialog) - brianc 2/22/93
	;	*ds:si = HelpControl
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	cmp	ds:[bx].GII_visibility, GIV_DIALOG
	jne	sameFileQuit			;not dialog
	push	dx, bp				;save regs not otherwise saved
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock		;restore focus here
	pop	dx, bp

sameFileQuit:

	.leave
	ret

;
; pass:		*ds:si = help control
;		ax = add/remove message
; return:	nothing
; destroyed:	ax, bx, cx, dx
;
AddRemoveInteractable	label	near
	push	di, bp, si
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	bx, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, bx
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_ALWAYS_INTERACTABLE_WINDOWS
	clr	bx
	call	GeodeGetAppObject		; ^lbx:si = app obj
	tst	bx
	jz	addRemoved
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
addRemoved:
	add	sp, size GCNListParams
	pop	di, bp, si
	retn

HUReportError		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HUObjMessageSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to an object

CALLED BY:	UTILITY
PASS: 		^lbx:si - OD of object
		ds - fixupable segment
		ax - message to send
		values for message (cx, dx, bp)
RETURN:		ds - fixed up
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HUObjMessageSend		proc	near
	uses	di
	.enter

	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
HUObjMessageSend		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HUGetChildBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get child block and features for a controller
CALLED BY:	UTILITY

PASS:		*ds:si - controller
RETURN:		ax - features
		bx - handle of child block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGetChildBlockAndFeatures	proc	near
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
HUGetChildBlockAndFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HUGetChildBlockAndFeaturesLocals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get child block and features for a controller into local vars
CALLED BY:	UTILITY

PASS:		*ds:si - controller
		ss:bp - inherited locals
RETURN:		ss:bp - inherited locals
			features - features that are on
			childBlock - handle of child block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGetChildBlockAndFeaturesLocals	proc	near
	uses	ax, bx
HELP_LOCALS
	.enter	inherit
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_features
	mov	ss:features, ax
	mov	ax, ds:[bx].TGCI_childBlock
	mov	ss:childBlock, ax

	.leave
	ret
HUGetChildBlockAndFeaturesLocals	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HUDisableFeature
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a feature not enabled

CALLED BY:	UTILITY
PASS:		^lbx:di - OD of child
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HUDisableFeature		proc	near
	uses	ax, cx, dx, bp, si, di
	.enter

	mov	si, di				;^lbx:si <- OD of feature
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
HUDisableFeature		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HUEnableFeature
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a feature enabled

CALLED BY:	UTILITY
PASS:		^lbx:di - OD of child
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HUEnableFeature		proc	near
	uses	ax, cx, dx, bp, si, di
	.enter

	mov	si, di				;^lbx:si <- OD of feature
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_ENABLED
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
HUEnableFeature		endp

HelpControlCode ends
