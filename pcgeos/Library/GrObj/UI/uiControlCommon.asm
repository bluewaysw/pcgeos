COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiControlCommon.asm

AUTHOR:		Jon Witort

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 feb 1992   	Initial version.

DESCRIPTION:
	Common routines for Ruler controllers

	$Id: uiControlCommon.asm,v 1.1 97/04/04 18:05:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CopyDupInfoCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Copies GenControlBuildInfo frame from source to dest

Pass:		cs:si = source GenControlDupIndo frame
		cx:dx = dest

Return:		nothing

Destroyed:	cx, di, es, ds

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 23, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyDupInfoCommon	proc	near
	mov	es, cx
	mov	di, dx
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo / 2
	rep movsw
	if ((size GenControlBuildInfo AND 1) eq 1)
		movsb
	endif
	ret
CopyDupInfoCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

DESCRIPTION:	Update the controller UI based on the number of selected
		GrObj's

PASS:
	*ds:si - instance data of controller
	ss:bp - GenControlUpdateUIParams
	si - object chunk within ss:[bp].GCUUIP_childBlock to get
	     enabled/disabled based the conditions
	cx - number of selected GrObj's required to enable UI
	ax - feature to check in features

RETURN: nothing

DESTROYED:
	bx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if (# selected grobjs >= passed number), then enable passed optr

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	25 feb 1992	Initial version
------------------------------------------------------------------------------@
GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet	proc	near

	uses	dx
	.enter

	clr	dx
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	.leave
	ret
GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

DESCRIPTION:	Update the controller UI based on the number of selected
		GrObj's

PASS:
	*ds:si - instance data of controller
	ss:bp - GenControlUpdateUIParams
	si - object chunk within ss:[bp].GCUUIP_toolBlock to get
	     enabled/disabled based the conditions
	cx - number of selected GrObj's required to enable UI
	ax - feature to check in toolbox features

RETURN: nothing

DESTROYED:
	bx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if (# selected grobjs >= passed number), then enable passed optr

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	25 feb 1992	Initial version
------------------------------------------------------------------------------@
GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet	proc	near
	uses	dx
	.enter

	clr	dx
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSetAndLocksClear

	.leave
	ret
GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjControlUpdateUIBasedOnSelectionFlagsAndFeatureSet

DESCRIPTION:	Update the controller UI based on the number of selected
		GrObj's

PASS:
	ss:bp - GenControlUpdateUIParams
	si - object chunk within ss:[bp].GCUUIP_childBlock to get
	     enabled/disabled based the conditions
	cl - GrObjSelectionStateFlags which must be set to enable UI
	ax - feature to check in features

RETURN: nothing

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if (# selected grobjs >= passed number), then enable passed optr

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	25 feb 1992	Initial version
------------------------------------------------------------------------------@
GrObjControlUpdateUIBasedOnSelectionFlagsAndFeatureSet	proc	near

	uses	ax, bx, dx, di, es
	.enter

	test	ss:[bp].GCUUIP_features, ax
	jz	done

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	jc	done
	mov	es, ax
	mov	ax, MSG_GEN_SET_ENABLED			;assume ungroupable
	test	es:[GONSSC_selectionState].GSS_flags, cl
	jnz	unlock
	mov	ax, MSG_GEN_SET_NOT_ENABLED
unlock:
	call	MemUnlock
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
GrObjControlUpdateUIBasedOnSelectionFlagsAndFeatureSet	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjControlUpdateToolBasedOnSelectionFlagsAndToolboxFeatureSet

DESCRIPTION:	Update the controller toolbox UI based on whether
		any of the passed GrObjSelectionStateFlags are set
	
PASS:
	ss:bp - GenControlUpdateUIParams
	si - object chunk within ss:[bp].GCUUIP_toolBlock to get
	     enabled/disabled based on the number of selected GrObj's
	cl - GrObjSelectionStateFlags which must be set to enable UI
	ax - feature to check in features

RETURN: nothing

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if (# selected grobjs >= passed number), then enable passed optr

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	25 feb 1992	Initial version
------------------------------------------------------------------------------@
GrObjControlUpdateToolBasedOnSelectionFlagsAndToolboxFeatureSet	proc	near

	uses	ax, bx, dx, di, es
	.enter

	test	ss:[bp].GCUUIP_toolboxFeatures, ax
	jz	done

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	jc	done
	mov	es, ax
	mov	ax, MSG_GEN_SET_ENABLED			;assume ungroupable
	test	es:[GONSSC_selectionState].GSS_flags, cl
	jnz	unlock
	mov	ax, MSG_GEN_SET_NOT_ENABLED
unlock:
	call	MemUnlock
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
GrObjControlUpdateToolBasedOnSelectionFlagsAndToolboxFeatureSet	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear

DESCRIPTION:	Update the controller UI based on the number of selected
		GrObj's and any passed locks

PASS:
	ss:bp - GenControlUpdateUIParams
	si - object chunk within ss:[bp].GCUUIP_childBlock to get
	     enabled/disabled based on the conditions
	cx - number of selected GrObj's required to enable UI
	ax - feature to check 
	dx - GrObjLocks that must be clear or indeterminate to enable UI

RETURN: nothing

DESTROYED:
	bx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if ((# selected grobjs >= passed number) AND
	   all passed locks are either clear or indeterminate)
		then enable passed optr

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	25 feb 1992	Initial version
------------------------------------------------------------------------------@
GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear	proc	near

	uses	ax, bx, cx, dx, di, es
	.enter

	test	ss:[bp].GCUUIP_features, ax
	jz	done

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	jc	done
	mov	es, ax
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	cmp	es:[GONSSC_selectionState].GSS_numSelected, cx
	jb	unlock
	mov	cx, es:[GONSSC_locksDiffs]
	not	cx
	and	cx, es:[GONSSC_selectionState].GSS_locks
	test	dx, cx
	jnz	unlock
	mov	ax, MSG_GEN_SET_ENABLED
unlock:
	call	MemUnlock
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSetAndLocksClear

DESCRIPTION:	Update the controller UI based on the number of selected
		GrObj's and any passed locks

PASS:
	ss:bp - GenControlUpdateUIParams
	si - object chunk within ss:[bp].GCUUIP_toolBlock to get
	     enabled/disabled based on the conditions
	cx - number of selected GrObj's required to enable UI
	ax - feature to check 
	dx - GrObjLocks that must be clear or indeterminate to enable UI

RETURN: nothing

DESTROYED:
	bx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if ((# selected grobjs >= passed number) AND
	   all passed locks are either clear or indeterminate)
		then enable passed optr

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	25 feb 1992	Initial version
------------------------------------------------------------------------------@
GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSetAndLocksClear	proc	near

	uses	ax, bx, cx, dx, di, es
	.enter

	test	ss:[bp].GCUUIP_toolboxFeatures, ax
	jz	done

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	jc	done
	mov	es, ax
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	cmp	es:[GONSSC_selectionState].GSS_numSelected, cx
	jb	unlock
	mov	cx, es:[GONSSC_locksDiffs]
	not	cx
	and	cx, es:[GONSSC_selectionState].GSS_locks
	test	dx, cx
	jnz	unlock
	mov	ax, MSG_GEN_SET_ENABLED
unlock:
	call	MemUnlock
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSetAndLocksClear endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	GrObjControlUpdateUIBasedOnPasteInsideSelectedAndFeatureSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the controller UI based on whether or not there
		are paste inside objects selected

PASS:
	ss:bp - GenControlUpdateUIParams
	si - object chunk within ss:[bp].GCUUIP_childBlock to get
	     enabled/disabled based on the conditions

	ax - child feature to check 

RETURN: nothing

DESTROYED:
	bx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if ((# selected grobjs >= passed number) AND
	   all passed locks are either clear or indeterminate)
		then enable passed optr

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjControlUpdateUIBasedOnPasteInsideSelectedAndFeatureSet	proc	near
	uses	ax, bx, dx, di, es
	.enter

	test	ss:[bp].GCUUIP_features, ax
	jz	done

	mov	bx, ss:[bp].GCUUIP_dataBlock

	call	MemLock
	jc	done
	mov	es, ax
	mov	ax, es:[GONSSC_selectionState].GSS_grObjFlags
	or	ax, es:[GONSSC_grObjFlagsDiffs]
	call	MemUnlock

	test	ax, mask GOAF_HAS_PASTE_INSIDE_CHILDREN
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jz	haveEnabledDisabled
	mov	ax, MSG_GEN_SET_ENABLED
haveEnabledDisabled:
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
GrObjControlUpdateUIBasedOnPasteInsideSelectedAndFeatureSet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	GrObjControlUpdateToolBasedOnPasteInsideSelectedAndFeatureSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the controller UI based on whether or not there
		are paste inside objects selected

PASS:
	ss:bp - GenControlUpdateUIParams
	si - object chunk within ss:[bp].GCUUIP_childBlock to get
	     enabled/disabled based on the conditions

	ax - child feature to check 

RETURN: nothing

DESTROYED:
	bx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if ((# selected grobjs >= passed number) AND
	   all passed locks are either clear or indeterminate)
		then enable passed optr

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjControlUpdateToolBasedOnPasteInsideSelectedAndFeatureSet	proc	near
	uses	ax, bx, dx, di, es
	.enter

	test	ss:[bp].GCUUIP_toolboxFeatures, ax
	jz	done

	mov	bx, ss:[bp].GCUUIP_dataBlock

	call	MemLock
	jc	done
	mov	es, ax
	mov	ax, es:[GONSSC_selectionState].GSS_grObjFlags
	or	ax, es:[GONSSC_grObjFlagsDiffs]
	call	MemUnlock

	test	ax, mask GOAF_HAS_PASTE_INSIDE_CHILDREN
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jz	haveEnabledDisabled
	mov	ax, MSG_GEN_SET_ENABLED
haveEnabledDisabled:
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
GrObjControlUpdateToolBasedOnPasteInsideSelectedAndFeatureSet	endp

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChildBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the data block where the children live, and the
		feature bits for the normal UI

CALLED BY:

PASS:		*ds:si - GenControl object

RETURN:		bx - child block
		ax - features

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	15 nov 92	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChildBlockAndFeatures	proc near	
	.enter

	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock

	.leave
	ret
GetChildBlockAndFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetToolBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the data block where the toolbox children live,
		and the	feature bits for the toolbox UI

CALLED BY:

PASS:		*ds:si - GenControl object

RETURN:		bx - toolbox block
		ax - toolbox features

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	15 nov 92	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetToolBlockAndFeatures	proc	near
	.enter

	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_toolboxFeatures
	mov	bx, ds:[bx].TGCI_toolBlock

	.leave
	ret
GetToolBlockAndFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjControlOutputActionRegsToBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This si a common routine to output an action of
		GrObjBodyClass type

Pass:		*ds:si - controller
		ax - message for body
		cx,dx,bp - message data

Return:		nothing

Destroyed:	bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul  2, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjControlOutputActionRegsToBody	proc	far
	.enter

	mov	bx, segment GrObjBodyClass
	mov	di, offset GrObjBodyClass
	call	GenControlOutputActionRegs

	.leave
	ret
GrObjControlOutputActionRegsToBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjControlOutputActionRegsToGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This si a common routine to output an action of
		GrObjClass type

Pass:		*ds:si - controller
		ax - message for GrObjs
		cx,dx,bp - message data

Return:		nothing

Destroyed:	bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul  2, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjControlOutputActionRegsToGrObjs	proc	far
	.enter

	mov	bx, segment GrObjClass
	mov	di, offset GrObjClass
	call	GenControlOutputActionRegs

	.leave
	ret
GrObjControlOutputActionRegsToGrObjs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjControlOutputActionStackToBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This si a common routine to output an action of
		GrObjBodyClass type

Pass:		*ds:si - controller
		ax - message for body
		cx,dx,bp - message data

Return:		nothing

Destroyed:	bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul  2, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjControlOutputActionStackToBody	proc	far
	.enter

	mov	bx, segment GrObjBodyClass
	mov	di, offset GrObjBodyClass
	call	GenControlOutputActionStack

	.leave
	ret
GrObjControlOutputActionStackToBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjControlOutputActionStackToGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This si a common routine to output an action of
		GrObjClass type

Pass:		*ds:si - controller
		ax - message for GrObjs
		cx,dx,bp - message data

Return:		nothing

Destroyed:	bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul  2, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjControlOutputActionStackToGrObjs	proc	far
	.enter

	mov	bx, segment GrObjClass
	mov	di, offset GrObjClass
	call	GenControlOutputActionStack

	.leave
	ret
GrObjControlOutputActionStackToGrObjs	endp

GrObjUIControllerActionCode	ends
