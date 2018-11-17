COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		
FILE:		prefmgrMtdHan.asm

AUTHOR:		Cheng, 1/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial revision

DESCRIPTION:
	Method handlers for the preference manager.
		
	$Id: prefmgrMtdHan.asm,v 1.1 97/04/04 16:27:14 newdeal Exp $

------------------------------------------------------------------------------@

if not _SIMPLE

COMMENT @----------------------------------------------------------------------

FUNCTION:	PNDVisOpen

DESCRIPTION:	Intercept MSG_VIS_OPEN to allow setting us to set
		the contents of the various summons.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

------------------------------------------------------------------------------@
PNDVisOpen	method	PrefNotifyDialogClass, MSG_VIS_OPEN
	mov	bx, offset PNDI_openHandler
	call	PNDCallHandler

	mov	di, offset PrefNotifyDialogClass
	GOTO	ObjCallSuperNoLock
PNDVisOpen	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	MtdHanVisClose

DESCRIPTION:	Intercept MSG_VIS_CLOSE to allow setting us to set
		the contents of the various summons.

CALLED BY:	INTERNAL (MSG_VIS_CLOSE)

PASS:		

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

------------------------------------------------------------------------------@

PNDVisClose	method	PrefNotifyDialogClass, MSG_VIS_CLOSE
	mov	bx, offset PNDI_closeHandler
	call	PNDCallHandler

	mov	di, offset PrefNotifyDialogClass
	GOTO	ObjCallSuperNoLock
PNDVisClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PNDCallHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call one of the handler routines bound into a NotifySummons

CALLED BY:	PNDVisOpen, PNDVisClose
PASS:		ds:di	= PrefNotifyDialogInstance
		bx	= offset in ds:[di] at which fptr to the routine
			  is stored.

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/21/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PNDCallHandler	proc	near	uses ax, cx, dx, si, bp, es
		.enter
		tst	ds:[di+bx].segment
		jz	done
		push	ds:[LMBH_handle]
		mov	ax, ds:[di+bx].offset
		mov	bx, ds:[di+bx].segment
		mov	cx, dgroup
		mov	ds, cx
		mov	es, cx
		call	ProcCallFixedOrMovable
		pop	bx
		call	MemDerefDS
done:
		.leave
		ret
PNDCallHandler	endp


endif	; not _SIMPLE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrFreeLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the library whose handle is passed in CX

CALLED BY:	MSG_PREF_MGR_FREE_LIBRARY
PASS:		ds	= dgroup
		cx	= handle of library to free
		^ldx:bp = ACK od
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrFreeLibrary method dynamic PrefMgrClass, MSG_PREF_MGR_FREE_LIBRARY
	mov	bx, cx
	call	GeodeFreeLibrary
	tst	dx
	jz	done
	
	call	GeodeGetProcessHandle
	clr	si			; ^lbx:si <- us

	xchg	bx, dx			; ^lbx:si <- destination of ACK
	xchg	si, bp			; ^ldx:bp <- we who are sending it
	mov	ax, MSG_META_ACK
	clr	di
	call	ObjMessage
done:
	ret
PrefMgrFreeLibrary endm
