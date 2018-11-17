COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisAttrs.asm

AUTHOR:		John Wedgwood, Oct  8, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 8/91	Initial revision

DESCRIPTION:
	Attribute methods for axisClass

	$Id: axisAttrs.asm,v 1.1 97/04/04 17:45:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisSendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Send this message DIRECTLY to MetaClass

PASS:		*ds:si	- AxisClass object
		ds:di	- AxisClass instance data
		es	- segment of AxisClass

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisSendClassedEvent	method	dynamic	AxisClass, 
					MSG_META_SEND_CLASSED_EVENT

	segmov	es, <segment MetaClass>, di
	mov	di, offset MetaClass
	call	ObjCallClassNoLock
	ret
AxisSendClassedEvent	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisSetAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Change the axis attributes

PASS:		*ds:si	= AxisClass object
		ds:di	= AxisClass instance data
		es	= Segment of AxisClass.
		
		cl - bits to set
		ch - bits to clear

RETURN:		cl - old attributes

DESTROYED:	ch

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisSetAttributes	method	dynamic	AxisClass, 
					MSG_AXIS_SET_ATTRIBUTES
	uses	ax
	.enter

	ECCheckFlags	cl, AxisAttributes
	ECCheckFlags	ch, AxisAttributes

	mov	al, ds:[di].AI_attr
	ornf	ds:[di].AI_attr, cl
	not	ch
	andnf	ds:[di].AI_attr, ch
	mov	cl, al
	.leave
	ret
AxisSetAttributes	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisCombineNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Combine notification data

PASS:		*ds:si	= AxisClass object
		ds:di	= AxisClass instance data
		es	= Segment of AxisClass.
		cx	= handle of notification data block
				(AxisNotifyBlock)		

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisCombineNotificationData	method	dynamic	AxisClass, 
					MSG_AXIS_COMBINE_NOTIFICATION_DATA
	uses	bp
	.enter
	call	UtilStartCombine
	push	di
	lea	si, ds:[di].AI_attr
	mov	di, offset ANB_attr
	mov	bp, offset ANB_attrDiffs
	call	UtilCombineFlags
	pop	di

	;
	; Determine whether to set X or Y axis tick attrs
	;

	lea	si, ds:[di].AI_tickAttr
	test	ds:[di].AI_attr, mask AA_VERTICAL
	jnz	vertical

	;
	; X-axis:
	;

	mov	al, mask CCF_FOUND_X_AXIS
	mov	di, offset ANB_xAxisTickAttr
	mov	bp, offset ANB_xAxisTickAttrDiffs
	jmp	common


vertical:
	mov	al, mask CCF_FOUND_Y_AXIS
	mov	di, offset ANB_yAxisTickAttr
	mov	bp, offset ANB_yAxisTickAttrDiffs

common:

	;
	; combine the flags, checking for the first axis of this
	; orientation. 
	;

	test	es:[CNBH_flags], al
	jz	firstOne

	mov	al, ds:[si]
	xor	al, es:[di]
	or	es:[bp], al
	jmp	done

firstOne:
	; copy source flags directly to destination

	mov	al, ds:[si]
	mov	es:[di], al
	mov	{byte} es:[bp], 0
done:
	call	UtilEndCombine
	.leave
	ret

AxisCombineNotificationData	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisSetTickAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set 'em -- being careful to distinguish between X and
		Y axis

PASS:		*ds:si	= AxisClass object
		ds:di	= AxisClass instance data
		es	= Segment of AxisClass.

		cl	= AxisTickAttributes to SET
		ch	= AxisTickAttributes to CLEAR
		dx 	- nonzero for Y-AXIS, zero for X AXIS
		
RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisSetTickAttributes	method	dynamic	AxisClass, 
					MSG_AXIS_SET_TICK_ATTRIBUTES
	uses	ax,cx
	.enter

	;
	; See if this message is for this axis
	;

	test	ds:[di].AI_attr, mask AA_VERTICAL
	jz	xAxis

	
	;
	; This is the Y-axis, so only take this message if DX is
	; nonzero. 
	;

	tst	dx
	jz	done
	jmp	setFlags


xAxis:
	tst	dx
	jnz	done


setFlags:
	call	AxisSetTickAttributesCommon

done:
	.leave
	ret
AxisSetTickAttributes	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisSetTickAttributesCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to set the tick attributes for this
		axis. 

CALLED BY:	AxisSetTickAttributes

PASS:		*ds:si - axis object
		ds:di - AxisClass instance data
		cl - AxisTickAttributes to set
		ch - AxisTickAttributes to clear

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/25/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisSetTickAttributesCommon	proc near
	uses	ax,cx

	class	AxisClass 

	.enter

	ECCheckFlags	cl, AxisTickAttributes
	ECCheckFlags	ch, AxisTickAttributes


	mov	al, ds:[di].AI_tickAttr		; old attributes

	or	ds:[di].AI_tickAttr, cl		; or-in the set bits
	not	ch
	and	ds:[di].AI_tickAttr, ch

	cmp	ds:[di].AI_tickAttr, al
	je	done

 	mov	cl, mask COS_IMAGE_INVALID or mask COS_GEOMETRY_INVALID
 	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
 	call	ObjCallInstanceNoLock

	mov	cx, mask CUUIF_AXIS
	call	UtilUpdateUI
done:
	.leave
	ret
AxisSetTickAttributesCommon	endp

