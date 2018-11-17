COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgroupState.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/29/92   	Initial version.

DESCRIPTION:
	

	$Id: cgroupState.asm,v 1.1 97/04/04 17:45:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupUnSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.

RETURN:		

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupUnSuspend	method	dynamic	ChartGroupClass, 
					MSG_META_UNSUSPEND
	.enter

	call	ChartGroupUpdate

	.leave
	ret
ChartGroupUnSuspend	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupMarkInvalid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.

		cl 	= ChartObjectState flags to set

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupMarkInvalid	method	dynamic	ChartGroupClass, 
					MSG_CHART_OBJECT_MARK_INVALID,
					MSG_CHART_OBJECT_MARK_TREE_INVALID
	uses	ax,cx,dx,bp
	.enter

	;
	; If image-invalid flag is set, then also set the image-path
	;

	test	cl, mask COS_IMAGE_INVALID
	jz	gotFlags
	or	cl, mask COS_IMAGE_PATH
gotFlags: 
	mov	di, offset ChartGroupClass
	call	ObjCallSuperNoLock

	call	ChartGroupUpdate
	.leave
	ret
ChartGroupMarkInvalid	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform whatever updates need to be performed

CALLED BY:	ChartGroupEndUpdate, ChartGroupMarkInvalid

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupUpdate	proc near
	class	ChartGroupClass 
	uses	ax,bx,cx,dx,di,si,bp
	.enter

EC <	call	ECCheckChartGroupDSSI		> 

	DerefChartObject ds, si, di

	mov	cl, ds:[di].COI_state
	test	cl, mask COS_BUILD_INVALID
	jz	afterBuild

	clr	bp
	xchg	bp, ds:[di].CGI_buildChangeFlags
	mov	ax, MSG_CHART_OBJECT_BUILD
	jmp	callIt

afterBuild:
	test	cl, mask COS_GEOMETRY_INVALID
	jz	afterGeometry

	mov	ax, MSG_CHART_OBJECT_RECALC_SIZE
	jmp	callIt

afterGeometry:
	test	cl, mask COS_IMAGE_PATH
	jz	done

	mov	ax, MSG_CHART_OBJECT_REALIZE
callIt:
	call	ObjCallInstanceNoLock
done:

	.leave
	ret
ChartGroupUpdate	endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckToUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we can perform an update

CALLED BY:

PASS:		*ds:si - ChartGroup
		cl - ChartObjectState flags to check.  If unable to do
		the update, then set the flag.

RETURN:		CARRY CLEAR if its ok to update
		CARRY SET if we should to it later

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckToUpdate	proc near
	uses	ax
	class	ChartGroupClass 
	.enter

EC <	call	ECCheckChartGroupDSSI		> 

	mov	ax, MSG_CHART_BODY_GET_SUSPEND_COUNT
	call	UtilCallChartBody
	mov	di, ds:[si] 

	tst	ax
	jnz	notOk

	test	ds:[di].COI_state, mask COS_UPDATING
	jz	ok

notOk:
	ornf	ds:[di].COI_state, cl
	stc
	jmp	done
ok:
	; clear the "invalid" flag, set the "updating" flag
	not	cl
	andnf	ds:[di].COI_state, cl
	ornf	ds:[di].COI_state, mask COS_UPDATING
	clc
done:
	.leave
	ret
CheckToUpdate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupEndUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish up an update and see if another one wants to be
		done. 

CALLED BY:

PASS:		*ds:si - ChartGroup

RETURN:		nothing 

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupEndUpdate	proc near
	class	ChartGroupClass 
	.enter

EC <	call	ECCheckChartGroupDSSI		> 

	mov	di, ds:[si]
	andnf	ds:[di].COI_state, not mask COS_UPDATING
	call	ChartGroupUpdate

	.leave
	ret
ChartGroupEndUpdate	endp

