COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		utilsGrObj.asm

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
	CDB	2/18/92   	Initial version.

DESCRIPTION:
	

	$Id: utilsGrObj.asm,v 1.1 97/04/04 17:47:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilClearGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a grobj -- nuke its delete lock before deleting
		it, so it'll pay attention!

CALLED BY:	EXTERNAL

PASS:		^lbx:si - optr of grobj (if bx=0 -- do nothing)
		ds - segment of an object block that needs to be 
		fixed up

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilClearGrObj	proc far
	uses	ax,cx,dx,di
	.enter

		tst	bx
		jz	done
		
	;
	; Tell this grobj that it's invalid so that it won't try to
	; update the UI.  XXX: This means the grobj won't invalidate
	; itself as its dying, but this should be OK, since the chart
	; group should invalidate itself any moment now.  Also, this
	; means that the grobj won't send out its action notification.
	;

		mov	ax, MSG_GO_NOTIFY_GROBJ_INVALID
		call	ObjMessageFixupDS

	;
	; We don't ever want to hear from this grobj again.  I'm not
	; sure if we need to do this, since the above message should
	; turn off notification -- this may be left over from an
	; earlier version or something.
	;

		clr	cx
		mov	ax, MSG_GO_SET_ACTION_NOTIFICATION_OUTPUT
		call	ObjMessageFixupDS

	;
	; Make sure the grobj won't try to prevent us from destroying
	; it. 
	;

		mov	ax, MSG_GO_CHANGE_LOCKS
		clr	cx
		mov	dx, mask GOL_DELETE
		call	ObjMessageFixupDS

		mov	ax, MSG_GO_CLEAR
		call	ObjMessageFixupDS
done:
		.leave
		ret
UtilClearGrObj	endp

ObjMessageFixupDS	proc	far
		mov	di, mask MF_FIXUP_DS
		GOTO	ObjMessage
ObjMessageFixupDS	endp


