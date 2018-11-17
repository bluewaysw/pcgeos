COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		The GrObj
FILE:		grobjUI.asm

ROUTINES:
	Name			Description
	----			-----------

METHODS:
	Name:			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	1 apr 1992	initial revision

DESCRIPTION:

	$Id: grobjUI.asm,v 1.1 97/04/04 18:07:24 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjSendUINotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_SEND_UI_NOTIFICATION

Called by:	

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		cx - GrObjUINotificationTypes

Return:		nothing

Destroyed:	ax

Comments:	
		WARNING: This method is not dynamic, so the passed 
		parameters are more limited and you must be careful
		what you destroy.

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSendUINotification	method 	GrObjClass, MSG_GO_SEND_UI_NOTIFICATION
	uses	di
	.enter

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	done

	test	ds:[di].GOI_tempState, mask GOTM_EDITED
	jnz	send

	test	ds:[di].GOI_tempState, mask GOTM_SELECTED
	jz	done

send:
	mov	ax, MSG_GB_UPDATE_UI_CONTROLLERS
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody	
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

done:
	.leave
	ret
GrObjSendUINotification	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOptSendUINotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send ui notification for the object taking into account
		the GrObjMessageOptimizationFlags

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - grobject
		cx - GrObjUINotificationTypes

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			opt bit not set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOptSendUINotification		proc	far
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_msgOptFlags, mask GOMOF_SEND_UI_NOTIFICATION
	jnz	send

	call	GrObjSendUINotification

done:
	.leave
	ret

send:
	push	ax
	mov	ax,MSG_GO_SEND_UI_NOTIFICATION
	call	ObjCallInstanceNoLock
	pop	ax
	jmp	done

GrObjOptSendUINotification		endp


GrObjInitCode	ends

GrObjRequiredExtInteractive2Code segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjCombineGradientNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_COMBINE_GRADIENT_NOTIFICATION_DATA

Called by:	

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		
		^hcx = GrObjNotifyGradientChange struct

Return:		carry set if all relevant diff bits are set at the end
		of this routine

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCombineGradientNotificationData	method dynamic	GrObjClass,
				MSG_GO_COMBINE_GRADIENT_NOTIFICATION_DATA
	uses	cx,dx,bp

	.enter

	mov	bx, cx					;bx <- struc handle

	;
	;	cx <- gradient attr token
	;
	mov	ax, MSG_GO_GET_GROBJ_AREA_TOKEN
	call	ObjCallInstanceNoLock

	;
	;	Get the attrs from the token
	;
	sub	sp, size GrObjFullAreaAttrElement
	mov	bp, sp
	mov	ax, MSG_GOAM_GET_FULL_AREA_ATTR_ELEMENT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	GrObjMessageToGOAM
	jnc	errorFreeFrame

	cmp	ss:[bp].GOBAAE_aaeType, GOAAET_GRADIENT
	jne	errorFreeFrame

	call	MemLock
	jc	errorFreeFrame
	mov	es, ax

	;
	;	If we're the first grobj to get this, then
	;	just fill the passed frame with our attrs...
	;
	test	es:[GONGAC_diffs], mask GGAD_FIRST_RECIPIENT
	jz	notFirst

	;
	;	copy attrs into passed block
	;
	mov	al, ss:[bp].GOGAAE_type
	mov	es:[GONGAC_type], al

	mov	al, ss:[bp].GOGAAE_endR
	mov	es:[GONGAC_endR], al

	mov	al, ss:[bp].GOGAAE_endG
	mov	es:[GONGAC_endG], al

	mov	al, ss:[bp].GOGAAE_endB
	mov	es:[GONGAC_endB], al

	mov	ax, ss:[bp].GOGAAE_numIntervals
	mov	es:[GONGAC_numIntervals], ax

	clr	es:[GONGAC_diffs]

unlockBlock:

	call	MemUnlock

freeFrame:
	lahf
	add	sp, size GrObjFullAreaAttrElement
	sahf

	.leave
	ret

errorFreeFrame:
	clc
	jmp	freeFrame

notFirst:
	clr	ax

	mov	cl, es:[GONGAC_endR]
	cmp	cl, ss:[bp].GOGAAE_endR
	jne	multipleColors

	mov	cl, es:[GONGAC_endG]
	cmp	cl, ss:[bp].GOGAAE_endG
	jne	multipleColors

	mov	cl, es:[GONGAC_endB]
	cmp	cl, ss:[bp].GOGAAE_endB
	je	checkType

multipleColors:
	BitSet	ax, GGAD_MULTIPLE_END_COLORS

checkType:
	mov	cl, es:[GONGAC_type]
	cmp	cl, ss:[bp].GOGAAE_type
	je	checkIntervals

	BitSet	ax, GGAD_MULTIPLE_TYPES

checkIntervals:
	mov	cx, es:[GONGAC_numIntervals]
	cmp	cx, ss:[bp].GOGAAE_numIntervals
	je	checkAllDiffs

	BitSet	ax, GGAD_MULTIPLE_INTERVALS

checkAllDiffs:
	;
	;	See if all the diff bits are set; if so, return
	;	carry set (FIRST_RECIPIENT is guaranteed 0)
	;

	or	es:[GONGAC_diffs], al
	mov	al, es:[GONGAC_diffs]

	andnf	ax, mask GGAD_MULTIPLE_END_COLORS or mask GGAD_MULTIPLE_TYPES \
			or mask GGAD_MULTIPLE_INTERVALS
	cmp	ax, mask GGAD_MULTIPLE_END_COLORS or mask GGAD_MULTIPLE_TYPES \
			or mask GGAD_MULTIPLE_INTERVALS
	stc
	jz	unlockBlock
	clc
	jmp	unlockBlock
GrObjCombineGradientNotificationData	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjCombineAreaNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_COMBINE_AREA_NOTIFICATION_DATA

Called by:	

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		^hcx = GrObjNotifyAreaAttrChange struct

Return:		carry set if all relevant diff bits are set at the end
		of this routine

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCombineAreaNotificationData	method dynamic	GrObjClass, MSG_GO_COMBINE_AREA_NOTIFICATION_DATA
	uses	cx,dx,bp

	.enter

	mov	bx, cx					;bx <- struc handle

	;
	;	cx <- area attr token
	;
	mov	ax, MSG_GO_GET_GROBJ_AREA_TOKEN
	call	ObjCallInstanceNoLock

	;
	;	Get the attrs from the token
	;
	sub	sp, size GrObjFullAreaAttrElement
	mov	bp, sp
	mov	ax, MSG_GOAM_GET_FULL_AREA_ATTR_ELEMENT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	GrObjMessageToGOAM
	jnc	freeFrame
	call	MemLock
	jc	errorFreeFrame
	mov	es, ax

	;
	;	If we're the first grobj to get this, then
	;	just fill the passed frame with our attrs...
	;
	test	es:GNAAC_areaAttrDiffs, mask GOBAAD_FIRST_RECIPIENT
	jz	notFirst

	;
	;	copy attrs into passed block
	;


	push	ds, si
	mov	cx, size GrObjBaseAreaAttrElement/2
	segmov	ds, ss
	mov	si, bp
	clr	di				;clear carry
CheckEvenSize GrObjBaseAreaAttrElement
	rep	movsw
	mov	es:GNAAC_areaAttrDiffs, cx	;clear diffs
	pop	ds, si

unlockBlock:

	call	MemUnlock

freeFrame:
	lahf
	add	sp, size GrObjFullAreaAttrElement
	sahf

	.leave
	ret

errorFreeFrame:
	clc
	jmp	freeFrame

notFirst:

	;
	; Set up the call to GrObjDiffBaseAreaAttrs
	;
	mov	dx, es
	segmov	ds, ss
	clr	di
	mov	si, bp
	push	bx
	mov	bx, offset GNAAC_areaAttrDiffs
	call	GrObjDiffBaseAreaAttrs
	pop	bx
	jmp	unlockBlock
GrObjCombineAreaNotificationData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjDiffBaseAreaAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		ds:si - GrObjBaseAreaAttrElement #1
		es:di - GrObjBaseAreaAttrElement #2
		dx:bx - GrObjBaseAreaAttrDiffs

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDiffBaseAreaAttrs	proc	far

	uses	ax, cx

	.enter

	clr	ax					;initial diffs

	mov	cl, es:[di].GOBAAE_r
	cmp	cl, ds:[si].GOBAAE_r
	jne	multipleColors

	mov	cl, es:[di].GOBAAE_g
	cmp	cl, ds:[si].GOBAAE_g
	jne	multipleColors

	mov	cl, es:[di].GOBAAE_b
	cmp	cl, ds:[si].GOBAAE_b
	je	checkBackground

multipleColors:
	BitSet	ax, GOBAAD_MULTIPLE_COLORS

checkBackground:
	mov	cl, es:[di].GOBAAE_backR
	cmp	cl, ds:[si].GOBAAE_backR
	jne	multipleBGColors

	mov	cl, es:[di].GOBAAE_backG
	cmp	cl, ds:[si].GOBAAE_backG
	jne	multipleBGColors

	mov	cl, es:[di].GOBAAE_backB
	cmp	cl, ds:[si].GOBAAE_backB
	je	checkMask

multipleBGColors:
	BitSet	ax, GOBAAD_MULTIPLE_BACKGROUND_COLORS

checkMask:
	mov	cl, es:[di].GOBAAE_mask
	cmp	cl, ds:[si].GOBAAE_mask
	je	checkElementType

	BitSet	ax, GOBAAD_MULTIPLE_MASKS

checkElementType:
	mov	cl, es:[di].GOBAAE_aaeType
	cmp	cl, ds:[si].GOBAAE_aaeType
	je	checkGradientStuff

	BitSet	ax, GOBAAD_MULTIPLE_ELEMENT_TYPES

	;
	;  If either type is GOAAET_GRADIENT, then we have to set all the
	;  GOBAAD_MULTIPLE_GRADIENT_* bits
	;

	cmp	cl, GOAAET_GRADIENT
	je	setGradientDiffs
	cmp	ds:[si].GOBAAE_aaeType, GOAAET_GRADIENT
	jne	checkDrawMode

setGradientDiffs:
	ornf	ax, mask GOBAAD_MULTIPLE_GRADIENT_END_COLORS or \
		mask GOBAAD_MULTIPLE_GRADIENT_TYPES or \
		mask GOBAAD_MULTIPLE_GRADIENT_INTERVALS

	jmp	checkDrawMode

checkGradientStuff:

	cmp	cl, GOAAET_GRADIENT
	jne	checkDrawMode

	;
	; They're both gradients, so diff their gradient stuff
	;
	mov	cl, es:[di].GOGAAE_endR
	cmp	cl, ds:[si].GOGAAE_endR
	jne	multipleGradientColors

	mov	cl, es:[di].GOGAAE_endG
	cmp	cl, ds:[si].GOGAAE_endG
	jne	multipleGradientColors

	mov	cl, es:[di].GOGAAE_endB
	cmp	cl, ds:[si].GOGAAE_endB
	je	checkGradientType

multipleGradientColors:
	BitSet	ax, GOBAAD_MULTIPLE_GRADIENT_END_COLORS

checkGradientType:
	mov	cl, es:[di].GOGAAE_type
	cmp	cl, ds:[si].GOGAAE_type
	je	checkGradientIntervals

	BitSet	ax, GOBAAD_MULTIPLE_GRADIENT_TYPES

checkGradientIntervals:
	mov	cx, es:[di].GOGAAE_numIntervals
	cmp	cx, ds:[si].GOGAAE_numIntervals
	je	checkDrawMode

	BitSet	ax, GOBAAD_MULTIPLE_GRADIENT_INTERVALS

checkDrawMode:
	mov	cl, es:[di].GOBAAE_drawMode
	cmp	cl, ds:[si].GOBAAE_drawMode
	je	checkPattern

	BitSet	ax, GOBAAD_MULTIPLE_DRAW_MODES

checkPattern:
	mov	cx, {word}es:[di].GOBAAE_pattern
	cmp	cx, {word}ds:[si].GOBAAE_pattern
	je	checkInfo

	BitSet	ax, GOBAAD_MULTIPLE_PATTERNS

checkInfo:
	mov	cl, es:[di].GOBAAE_areaInfo
	cmp	cl, ds:[si].GOBAAE_areaInfo
	je	checkAllDiffs

	BitSet	ax, GOBAAD_MULTIPLE_INFOS

checkAllDiffs:
	;
	;	See if all the diff bits are set; if so, return
	;	carry set (FIRST_RECIPIENT is guaranteed 0)
	;

	push	ds			;save ds
	mov	ds, dx			;ds <- diffs
	or	ds:[bx], ax
	mov	ax, ds:[bx]
	pop	ds			;restore ds

	;
	;  We don't care about the gradient stuff, really, since it's only
	;  relevant when describing styles, not when updating
	;
	andnf	ax, mask GOBAAD_MULTIPLE_COLORS \
			or mask GOBAAD_MULTIPLE_MASKS \
			or mask GOBAAD_MULTIPLE_INFOS \
			or mask GOBAAD_MULTIPLE_PATTERNS \
			or mask GOBAAD_MULTIPLE_BACKGROUND_COLORS \
			or mask GOBAAD_MULTIPLE_DRAW_MODES \
			or mask GOBAAD_MULTIPLE_ELEMENT_TYPES

	cmp	ax, mask GOBAAD_MULTIPLE_COLORS \
			or mask GOBAAD_MULTIPLE_MASKS \
			or mask GOBAAD_MULTIPLE_INFOS \
			or mask GOBAAD_MULTIPLE_PATTERNS \
			or mask GOBAAD_MULTIPLE_BACKGROUND_COLORS \
			or mask GOBAAD_MULTIPLE_DRAW_MODES \
			or mask GOBAAD_MULTIPLE_ELEMENT_TYPES
	stc
	jz	done
	clc
done:
	.leave
	ret
GrObjDiffBaseAreaAttrs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjCombineLineNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_COMBINE_LINE_NOTIFICATION_DATA

Called by:	

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		^hcx = GrObjNotifyLineAttrChange struct

Return:		carry set if all relevant diff bits are set at the end
		of this routine

Destroyed:	bx

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCombineLineNotificationData	method dynamic	GrObjClass, MSG_GO_COMBINE_LINE_NOTIFICATION_DATA
	uses	ax,cx,bp

	.enter

	mov	bx, cx					;bx <- struc handle

	;
	;	cx <- Line attr token
	;
	mov	ax, MSG_GO_GET_GROBJ_LINE_TOKEN
	call	ObjCallInstanceNoLock

	;
	;	Get the attrs from the token
	;
	sub	sp, size GrObjFullLineAttrElement
	mov	bp, sp
	mov	ax, MSG_GOAM_GET_FULL_LINE_ATTR_ELEMENT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	GrObjMessageToGOAM
	jnc	errorFreeFrame
	call	MemLock
	jc	errorFreeFrame
	mov	es, ax

	;
	;	If we're the first grobj to get this, then
	;	just fill the passed frame with our attrs...
	;
	test	es:GNLAC_lineAttrDiffs, mask GOBLAD_FIRST_RECIPIENT
	jz	notFirst

	;
	;	copy attrs into passed block
	;


	push	ds, si
	mov	cx, size GrObjBaseLineAttrElement/2
	segmov	ds, ss
	mov	si, bp
	clr	di				;clear carry
CheckEvenSize GrObjBaseLineAttrElement
	rep	movsw
	mov	es:GNLAC_lineAttrDiffs, cx	;clear diffs
	pop	ds, si

unlockBlock:

	call	MemUnlock

freeFrame:
	lahf
	add	sp, size GrObjFullLineAttrElement
	sahf

	.leave
	ret

errorFreeFrame:
	clc
	jmp	freeFrame

notFirst:


	;
	; Set up the call to GrObjDiffBaseLineAttrs
	;
	mov	dx, es
	segmov	ds, ss
	clr	di
	mov	si, bp
	push	bx
	mov	bx, offset GNLAC_lineAttrDiffs
	call	GrObjDiffBaseLineAttrs
	pop	bx
	jmp	unlockBlock
GrObjCombineLineNotificationData	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjDiffBaseLineAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		ds:si - GrObjFullLineAttrElement #1
		es:di - GrObjFullLineAttrElement #2
		dx:bx - GrObjLineAttrDiffs

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDiffBaseLineAttrs	proc	far

	uses	ax, cx

	.enter

	clr	ax					;initial diffs

	mov	cl, es:[di].GOBLAE_r
	cmp	cl, ds:[si].GOBLAE_r
	jne	multipleColors

	mov	cl, es:[di].GOBLAE_g
	cmp	cl, ds:[si].GOBLAE_g
	jne	multipleColors

	mov	cl, es:[di].GOBLAE_b
	cmp	cl, ds:[si].GOBLAE_b
	je	checkMask

multipleColors:
	BitSet	ax, GOBLAD_MULTIPLE_COLORS

checkMask:
	mov	cl, es:[di].GOBLAE_mask
	cmp	cl, ds:[si].GOBLAE_mask
	je	checkArowheadAngle

	BitSet	ax, GOBLAD_MULTIPLE_MASKS

checkArowheadAngle:
	mov	cl, es:[di].GOBLAE_arrowheadAngle
	cmp	cl, ds:[si].GOBLAE_arrowheadAngle
	je	checkArowheadLength

	BitSet	ax, GOBLAD_MULTIPLE_ARROWHEAD_ANGLES

checkArowheadLength:
	mov	cl, es:[di].GOBLAE_arrowheadLength
	cmp	cl, ds:[si].GOBLAE_arrowheadLength
	je	checkArowheadOnStart

	BitSet	ax, GOBLAD_MULTIPLE_ARROWHEAD_LENGTHS

checkArowheadOnStart:
	mov	cl, es:[di].GOBLAE_lineInfo
	xor	cl, ds:[si].GOBLAE_lineInfo
	test	cl, mask GOLAIR_ARROWHEAD_ON_START
	jz	checkArowheadOnEnd

	BitSet	ax, GOBLAD_ARROWHEAD_ON_START

checkArowheadOnEnd:
	mov	cl, es:[di].GOBLAE_lineInfo
	xor	cl, ds:[si].GOBLAE_lineInfo
	test	cl, mask GOLAIR_ARROWHEAD_ON_END
	jz	checkArrowheadFilled

	BitSet	ax, GOBLAD_ARROWHEAD_ON_END

checkArrowheadFilled:
	mov	cl, es:[di].GOBLAE_lineInfo
	xor	cl, ds:[si].GOBLAE_lineInfo
	test	cl, mask GOLAIR_ARROWHEAD_FILLED
	jz	checkArrowheadFillType

	BitSet	ax, GOBLAD_ARROWHEAD_FILLED

checkArrowheadFillType:
	test	cl, mask GOLAIR_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES
	jz	checkElementType

	BitSet	ax, GOBLAD_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES

checkElementType:
	mov	cl, es:[di].GOBLAE_laeType
	cmp	cl, ds:[si].GOBLAE_laeType
	je	checkWidth

	BitSet	ax, GOBLAD_MULTIPLE_ELEMENT_TYPES

checkWidth:
	mov	cx, es:[di].GOBLAE_width.WWF_int
	cmp	cx, ds:[si].GOBLAE_width.WWF_int
	jne	multipleWidths

	mov	cx, es:[di].GOBLAE_width.WWF_frac
	cmp	cx, ds:[si].GOBLAE_width.WWF_frac
	je	checkStyle

multipleWidths:
	BitSet	ax, GOBLAD_MULTIPLE_WIDTHS


checkStyle:
	mov	cl, es:[di].GOBLAE_style
	cmp	cl, ds:[si].GOBLAE_style
	je	checkAllDiffs

	BitSet	ax, GOBLAD_MULTIPLE_STYLES

checkAllDiffs:
	;
	;	See if all the diff bits are set; if so, return
	;	carry set (FIRST_RECIPIENT is guaranteed 0)
	;
	push	ds			;save ds
	mov	ds, dx			;ds <- diffs
	or	ds:[bx], ax
	mov	ax, ds:[bx]
	pop	ds			;restore ds

	andnf	ax, 	mask GOBLAD_MULTIPLE_COLORS or \
			mask GOBLAD_MULTIPLE_MASKS or \
			mask GOBLAD_MULTIPLE_WIDTHS or \
			mask GOBLAD_MULTIPLE_STYLES or \
			mask GOBLAD_MULTIPLE_ELEMENT_TYPES or \
			mask GOBLAD_MULTIPLE_ARROWHEAD_ANGLES or \
			mask GOBLAD_MULTIPLE_ARROWHEAD_LENGTHS or \
			mask GOBLAD_ARROWHEAD_ON_START or \
			mask GOBLAD_ARROWHEAD_ON_END or \
			mask GOBLAD_ARROWHEAD_FILLED
			

	cmp	ax, 	mask GOBLAD_MULTIPLE_COLORS or \
			mask GOBLAD_MULTIPLE_MASKS or \
			mask GOBLAD_MULTIPLE_WIDTHS or \
			mask GOBLAD_MULTIPLE_STYLES or \
			mask GOBLAD_MULTIPLE_ELEMENT_TYPES or \
			mask GOBLAD_MULTIPLE_ARROWHEAD_ANGLES or \
			mask GOBLAD_MULTIPLE_ARROWHEAD_LENGTHS or \
			mask GOBLAD_ARROWHEAD_ON_START or \
			mask GOBLAD_ARROWHEAD_ON_END or \
			mask GOBLAD_ARROWHEAD_FILLED
	stc
	jz	done
	clc
done:
	.leave
	ret
GrObjDiffBaseLineAttrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjCombineSelectionStateNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA

Called by:	

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		^hcx = GrObjNotifySelectionStateChange struct

Return:		carry clear to continue processing.

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCombineSelectionStateNotificationData	method dynamic	GrObjClass,
			MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA

	uses	bp

	.enter

	mov	bx, cx
	call	MemLock
	jc	clcDone
	GrObjDeref	di,ds,si
	mov	es, ax
	tst	es:[GONSSC_selectionState].GSS_numSelected
	mov	bp, ds:[si]
	jz	imFirst

	;
	;	Do the grobj flags diff
	;
	mov	ax, ds:[di].GOI_attrFlags
	xor	ax, es:[GONSSC_selectionState].GSS_grObjFlags
	or	es:[GONSSC_grObjFlagsDiffs], ax

	;
	;	Compare the locks to the existing ones
	;
	mov	ax, ds:[di].GOI_locks
	xor	ax, es:[GONSSC_selectionState].GSS_locks
	or	es:[GONSSC_locksDiffs], ax

	;
	;	Check class of this object vs. class in notif. block
	;
	mov	ax, es:[GONSSC_selectionState].GSS_classSelected.offset
	cmp	ax, ds:[bp].offset
	jne	multipleClasses
	mov	ax, es:[GONSSC_selectionState].GSS_classSelected.segment
	cmp	ax, ds:[bp].segment
	je	unlock

multipleClasses:
	BitSet	es:[GONSSC_selectionStateDiffs], GSSD_MULTIPLE_CLASSES
unlock:
	call	MemUnlock
clcDone:
	clc				;this thing'll probably never
					;abort with all the various diff
					;bits, so I don't bother to check
	.leave
	ret

imFirst:
	movdw	es:[GONSSC_selectionState].GSS_classSelected, ds:[bp], ax
	mov	ax, ds:[di].GOI_locks
	mov	es:[GONSSC_selectionState].GSS_locks, ax
	mov	ax, ds:[di].GOI_attrFlags
	mov	es:[GONSSC_selectionState].GSS_grObjFlags, ax
	clr	ax
	mov	es:[GONSSC_selectionStateDiffs], al
	mov	es:[GONSSC_grObjFlagsDiffs], ax
	mov	es:[GONSSC_locksDiffs], ax

	;
	;	Get the number of selected grobjs
	;
	;	We do it this way (calling the body) instead of
	;	incrementing the counter each time so that we
	;	can abort the combine event if multiple classes are
	;	selected.
	;
	mov	ax, MSG_GB_GET_NUM_SELECTED_GROBJS
	mov	di, mask MF_CALL
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>
	mov	es:[GONSSC_selectionState].GSS_numSelected, bp
	jmp	unlock
GrObjCombineSelectionStateNotificationData	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenStyleNotify

DESCRIPTION:	Generate a notificiation structure

CALLED BY:	TA_SendNotification

PASS:
	*ds:si - instance data
	^hcx - NotifyStyleChange struct

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91	Initial version

------------------------------------------------------------------------------@
GrObjCombineStyleNotificationData	method dynamic	GrObjClass,
			MSG_GO_COMBINE_STYLE_NOTIFICATION_DATA

areaAttr		local	GrObjFullAreaAttrElement
lineAttr		local	GrObjFullLineAttrElement
localSCD		local	StyleChunkDesc

	.enter

	;
	;  Lock the notification block
	;
	mov	bx, cx
	call	MemLock
	LONG jc	done
	mov	es, ax					;es <- notif block

	push	cx					;save block handle
							;for later unlocking

	;
	;  areaAttr <- attrs from element token
	;
	push	bp					;save local ptr
	lea	bp, areaAttr
	mov	cx, ds:[di].GOI_areaAttrToken
	mov	dx, ds:[di].GOI_lineAttrToken
	mov	ax, MSG_GOAM_GET_FULL_AREA_ATTR_ELEMENT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM

	cmp	es:[NSC_styleToken], CA_NULL_ELEMENT
	je	imFirst

	pop	bp					;ss:bp <- locals

	;
	;   See if this grobj's attrs match the first grobj's
	;

	cmp	cx, es:NSC_attrTokens[0 * (size word)]
	jne	different

	cmp	dx, es:NSC_attrTokens[1 * (size word)]
	je	unlock					;carry clear to cont.

different:
	;
	;  OK, we found a different style; we need to mark this update
	;  as indeterminate, and prohibit redefines
	;
	mov	es:[NSC_indeterminate], 0xff
	clr	es:[NSC_canRedefine]

	;
	;  If canReturnToBase style is already set, then there's nothing
	;  we (or any other grobj) can add to the update.
	;
	tst	es:[NSC_canReturnToBase]
	stc						;carry set to halt
	jnz	unlock

	;
	;  If this grobj can return to it's base style, we want to set
	;  that flag
	;
	call	GrObjTestCanReturnToBaseStyle
	or	al, ah
	mov	es:[NSC_canReturnToBase], al

	;
	;  If we can't return to base, then we have to keep processing
	;
	jz	unlock
	stc

unlock:
	pop	bx
	call	MemUnlock	

done:
	.leave
	ret

imFirst:
	;
	;  Store our area attribute token away
	;
	mov	es:NSC_attrTokens[0], cx

	;
	;  generate checksum for area attrs
	;
	push	ds, si					;save grobj ptr
	segmov	ds, ss					;ds:si <- areaAttr
	mov	si, bp
	mov	cx, size GrObjFullAreaAttrElement
	call	StyleSheetGenerateChecksum		;dxax <- checksum
	pop	ds, si					;*ds:si <- grobj
	pop	bp					;bp <- local ptr

	movdw	<es:NSC_attrChecksums[0*(size dword)]>, dxax

	;
	;  localSCD <- StyleChunkDesc
	;
	push	bp					;save local ptr
	lea	bp, localSCD
	call	GetSCD
	mov	bx, bp					;ss:bx <- localSCD
	pop	bp					;bp <- local ptr

	mov	ax, areaAttr.GOFAAE_base.GOBAAE_styleElement.SSEH_style
	mov	es:[NSC_styleToken], ax

	;
	;  ax <- element size
	;  bx <- used index
	;  cx <- used tool index
	;  dx <- number of styles
	;
	mov	di, offset NSC_style			;es:di <- buffer
	call	StyleSheetGetStyle

	mov	es:[NSC_styleSize], ax
	mov	es:[NSC_usedIndex], bx
	mov	es:[NSC_usedToolIndex], cx

	GrObjDeref	di,ds,si
	mov	cx, ds:[di].GOI_lineAttrToken
	mov	es:NSC_attrTokens[1 * (size word)], cx

	;
	;  lineAttr <- attrs from element token
	;
	push	bp					;save local ptr
	lea	bp, lineAttr
	mov	ax, MSG_GOAM_GET_FULL_LINE_ATTR_ELEMENT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM

	;
	;  generate checksum for line attrs
	;
	push	ds, si					;save grobj ptr
	segmov	ds, ss					;ds:si <- areaAttr
	mov	si, bp
	mov	cx, size GrObjFullLineAttrElement
	call	StyleSheetGenerateChecksum		;dxax <- checksum
	pop	ds, si					;*ds:si <- grobj
	pop	bp					;bp <- local ptr

	movdw	<es:NSC_attrChecksums[1*(size dword)]>, dxax

	call	StyleSheetGetNotifyCounter
	mov	es:[NSC_styleCounter], ax

	;
	;  We're first, so no indeterminacy
	;
	clr	es:[NSC_indeterminate]

	;
	;  If our style isn't its own base style, then we can redefine
	;  the style, and return to the base style
	;
	call	GrObjTestCanReturnToBaseStyle
	or	al, ah
	mov	es:[NSC_canRedefine], al
	mov	es:[NSC_canReturnToBase], al

	clc						;keep goin'
	jmp	unlock
GrObjCombineStyleNotificationData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTestCanReturnToBaseStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Tests whether a style is it's own base style

Pass:		*ds:si - grobj
		ss:[bp] - GrObjBaseAreaAttrElement
			  (I think a GrObjLineAreaAttrElement might work, too)

Return:		ax - nonzero if style can return to base

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 30, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTestCanReturnToBaseStyle	proc	near
	class	GrObjClass
	uses	cx, dx, di

	.enter	inherit GrObjCombineStyleNotificationData

	;
	;  Suck out the style element
	;
	mov	cx, ss:[areaAttr].GOFAAE_base.GOBAAE_styleElement.SSEH_style

	;
	;  Get the area and line elements for the style
	;
	mov	ax, MSG_GOAM_GET_AREA_AND_LINE_TOKENS_FROM_STYLE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM

	;
	;  Compare 'em to our tokens
	;
	GrObjDeref	di, ds, si

	sub	ax, ds:[di].GOI_areaAttrToken
	sub	dx, ds:[di].GOI_lineAttrToken
	or	ax, dx

	.leave
	ret
GrObjTestCanReturnToBaseStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GrObjGetStyleArray

DESCRIPTION:	Load a StyleChunkDesc with a pointer to the style sheet info

CALLED BY:	INTERNAL

PASS:
	*ds:si - goam
	ss:bp - StyleChunkDesc to fill

RETURN:
	carry - set if styles exist
	ss:bp - filled

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/27/91		Initial version

------------------------------------------------------------------------------@
GetSCD	proc	near	uses ax, bx, cx, di
	class	GrObjClass
	.enter

	mov	ss:[bp].SCD_chunk, 0

	mov	ax, MSG_GOAM_GET_STYLE_ARRAY
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM
	jnc	done

	call	GrObjGlobalGetVMFile

	; cx = chunk, bx = file

	mov	ss:[bp].SCD_vmFile, bx
	mov	ss:[bp].SCD_vmBlockOrMemHandle, cx
	mov	ss:[bp].SCD_chunk, VM_ELEMENT_ARRAY_CHUNK
	stc
done:
	.leave
	ret

GetSCD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjCombineSelectionStateNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA

Called by:	

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		^hcx = NotifyStyleSheetChange struct

Return:		carry set if relevant diff bit(s) are all set

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCombineStyleSheetNotificationData	method dynamic	GrObjClass,
			MSG_GO_COMBINE_STYLE_SHEET_NOTIFICATION_DATA

	uses	ax, bp

	.enter

	sub	sp, size StyleChunkDesc
	mov	bp, sp
	call	GetSCD

	mov	bx, cx

	call	MemLock
	jc	adjustSpDone

	mov	es, ax

	mov	ax, ss:[bp].SCD_vmFile
	mov	es:[NSSHC_styleArray].SCD_vmFile, ax

	mov	ax, ss:[bp].SCD_chunk
	mov	es:[NSSHC_styleArray].SCD_chunk, ax

	mov	ax, ss:[bp].SCD_vmBlockOrMemHandle
	mov	es:[NSSHC_styleArray].SCD_vmBlockOrMemHandle, ax

	call	StyleSheetGetNotifyCounter
	mov	es:[NSSHC_counter], ax

	push	bx
	mov	bx, bp
	call	StyleSheetGetStyleCounts
	mov	es:[NSSHC_styleCount], ax
	mov	es:[NSSHC_toolStyleCount], bx
	pop	bx


	call	MemUnlock

adjustSpDone:
	add	sp, size StyleChunkDesc
	stc

	.leave
	ret
GrObjCombineStyleSheetNotificationData	endm





GrObjRequiredExtInteractive2Code ends
