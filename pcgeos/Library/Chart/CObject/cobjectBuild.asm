COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cobjectBuild.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/24/92   	Initial version.

DESCRIPTION:
	

	$Id: cobjectBuild.asm,v 1.1 97/04/04 17:46:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If this object is newly built, then send a RECALC-SIZE
		to the ChartGroup.

PASS:		*ds:si	= ChartObjectClass object
		ds:di	= ChartObjectClass instance data
		es	= Segment of ChartObjectClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectBuild	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_BUILD
	uses	ax,cx
	.enter
	test	ds:[di].COI_state, mask COS_BUILT
	jnz	done

	; Built for the first time 

	ornf	ds:[di].COI_state, mask COS_BUILT
	mov	cl, mask COS_IMAGE_INVALID or mask COS_GEOMETRY_INVALID
	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	call	ObjCallInstanceNoLock
done:

	.leave
	ret
ChartObjectBuild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectRelocate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Clear out the selection count on a read, because GrObj
		documents are always unselected when first read, and
		we're careful to keep chart objects from being
		discarded when they're selected

PASS:		*ds:si	- ChartObjectClass object
		ds:di	- ChartObjectClass instance data
		es	- segment of ChartObjectClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/23/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectRelocate	method	dynamic	ChartObjectClass, 
					reloc

		cmp	dx, VMRT_RELOCATE_AFTER_READ
		jne	done
		clr	ds:[di].COI_selection
done:
		mov	di, offset ChartObjectClass
		call	ObjRelocOrUnRelocSuper
		ret
ChartObjectRelocate	endm

