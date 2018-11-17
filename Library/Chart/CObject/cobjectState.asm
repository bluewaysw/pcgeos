COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cobjectState.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/29/92   	Initial version.

DESCRIPTION:
	

	$Id: cobjectState.asm,v 1.1 97/04/04 17:46:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectSetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the state of this chart object

CALLED BY:	INTERNAL

PASS:		*ds:si - chart object
		cl - ChartObjectState flags to set
		ch - ChartObjectState flags to clear

RETURN:		nothing 

DESTROYED:	di

PSEUDO CODE/STRATEGY:	
	Called as both a METHOD and a PROCEDURE

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectSetState	method ChartObjectClass, 
					MSG_CHART_OBJECT_SET_STATE
	uses	cx
	class	ChartObjectClass

	.enter

	call	ObjMarkDirty

EC <	call	ECCheckChartObjectDSSI	>

	mov	di, ds:[si]

	; Don't allow setting of the UPDATING flag if already set, or
	; clearing it if already cleared

if ERROR_CHECK
	ECCheckFlags	cl, ChartObjectState
	ECCheckFlags	ch, ChartObjectState

	test	cl, mask COS_UPDATING
	jz	notSetting
	test	ds:[di].COI_state, mask COS_UPDATING
	ERROR_NZ	ILLEGAL_STATE
notSetting:
	test	ch, mask COS_UPDATING
	jz	ok
	test	ds:[di].COI_state, mask COS_UPDATING
	ERROR_Z		ILLEGAL_STATE
ok:
endif


	not	ch
	andnf	ds:[di].COI_state, ch
	ornf	ds:[di].COI_state, cl

	.leave
	ret
ChartObjectSetState	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectMarkInvalid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Mark the chart object (and possibly its parent)
		invalid.	

PASS:		*ds:si	= ChartObjectClass object
		ds:di	= ChartObjectClass instance data
		es	= Segment of ChartObjectClass.

		cl = ChartObjectState flags to set
		dx - nonzero if this is not the first child to be
		called. 

RETURN:		dx = nonzero

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectMarkInvalid	method	dynamic ChartObjectClass, 
					MSG_CHART_OBJECT_MARK_INVALID
	uses	ax, cx
	.enter

	mov	di, ds:[si]
	mov	al, ds:[di].COI_state	; save original state

	; only pass these bits

	push	cx
	clr	ch
EC <	test	cl, not (mask COS_BUILD_INVALID or \
			mask COS_IMAGE_INVALID or \
			mask COS_GEOMETRY_INVALID or \
			mask COS_IMAGE_PATH)			>

EC <	ERROR_NZ	ILLEGAL_FLAGS		>

	call	ChartObjectSetState
	pop	cx

	cmp	al, ds:[di].COI_state
	je	done

	; If the image-invalid flag is set, then clear it and set the
	; image-path flag instead (for the parent)

	test	cl, mask COS_IMAGE_INVALID
	jz	gotFlags
	and	cl, not mask COS_IMAGE_INVALID
	or	cl, mask COS_IMAGE_PATH
gotFlags:
	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	call	ChartObjectCallParent
done:
	.leave
	ret
ChartObjectMarkInvalid	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectMarkTreeInvalid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Mark a tree invalid

PASS:		*ds:si	= ChartObjectClass object
		ds:di	= ChartObjectClass instance data
		es	= Segment of ChartObjectClass.

RETURN:		dx - TRUE

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectMarkTreeInvalid	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_MARK_TREE_INVALID
	uses	cx
	.enter

	clr	ch
	call	ChartObjectSetState

	.leave
	ret
ChartObjectMarkTreeInvalid	endm

