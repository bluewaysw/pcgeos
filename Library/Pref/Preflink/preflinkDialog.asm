COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		preflinkDialog.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/26/92   	Initial version.

DESCRIPTION:
	

	$Id: preflinkDialog.asm,v 1.1 97/04/05 01:28:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLinkDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If anything changed, shutdown the RFSD.  If the thing
		is actually ON, then restart it again.

PASS:		*ds:si	= PrefLinkDialogClass object
		ds:di	= PrefLinkDialogClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	Call superclass FIRST so that options are saved before running
	rfsd.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefLinkDialogApply	method	dynamic	PrefLinkDialogClass, 
					MSG_GEN_APPLY
	.enter
	mov	di, offset PrefLinkDialogClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_PREF_HAS_STATE_CHANGED
	call	ObjCallInstanceNoLock
	jnc	done

	clr	bx
	mov	di, DR_RFS_GET_STATUS
	call	CallRFSD

	cmp	ax, RFS_DISCONNECTED
	je	notConnected
	cmp	ax, RFS_DISCONNECTING
	je	notConnected

; here, we were previously connected, see if we turned off.
	mov	ax, MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED
	mov	cx, TRUE
	mov	si, offset LinkConnectItemGroup
	call	ObjCallInstanceNoLock
	jnc	turnOff
; here, we are ON+ON.. see if settings changed
	mov	ax, MSG_PREF_HAS_STATE_CHANGED
	mov	si, offset LinkSettingsGroup
	call	ObjCallInstanceNoLock
	jnc	done
	call	CloseConnection
	call	OpenConnection
turnOff:
	call	CloseConnection
	jmp	done
notConnected:
	mov	ax, MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED
	mov	cx, TRUE
	mov	si, offset LinkConnectItemGroup
	call	ObjCallInstanceNoLock
; if stayed off, no action
	jnc	done
; here, we were turned on from off...
	call	OpenConnection
done:
	.leave
	ret
PrefLinkDialogApply	endm


EC <	driverName	char	"rfsdec.geo",0	>
NEC <	driverName	char	"rfsd.geo",0	>

driverPermName char "rfsd    "	; Must be 8 chars



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the RFSD's connection to the outside world.

CALLED BY:	PrefLinkDialogApply

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di,bp,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseConnection	proc near
	.enter

	clr	bx
	mov	di, DR_RFS_CLOSE_CONNECTION
	call	CallRFSD

	.leave
	ret
CloseConnection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the connection -- if RFSD is not loaded, then
		load it.

CALLED BY:	PrefLinkDialogApply

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di,bp,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenConnection	proc near
	uses	ds,si
	.enter

	call	GetRFSDHandle
	jc	alreadyLoaded

	; rfsd not loaded -- load it now.

	mov	ax, SP_FILE_SYSTEM_DRIVERS
	call	FileSetStandardPath
	segmov	ds, cs, si
	mov	si, offset driverName
	clr	ax, bx
	call	GeodeUseDriver
	jmp	done	
alreadyLoaded:
	call	GeodeInfoDriver
	; Now, open it up.
	mov	di, DR_RFS_OPEN_CONNECTION
	call	ds:[si].DIS_strategy
done:
	.leave
	ret

OpenConnection	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRFSDHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the geode handle of the RFSD, if it's in memory

CALLED BY:

PASS:		if geode found
			carry set
			bx - geode handle
		else
			carry clear

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRFSDHandle	proc near
	uses	es,di,ax,cx,dx
	.enter

	segmov	es, cs
	mov	di, offset driverPermName
	mov	ax, size driverPermName
	clr	cx
	clr	dx			; ?
	call	GeodeFind
	.leave
	ret
GetRFSDHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRFSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call the RFSD

CALLED BY:	internal

PASS:		bx - RFSD handle
		di - FSFunction or RFSFunction to call

RETURN:		values returned by function called

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallRFSD	proc near
	uses	bx, ds, si
	.enter
	tst	bx
	jnz	gotHandle
	call	GetRFSDHandle
	jnc	done
gotHandle:
	call	GeodeInfoDriver
	call	ds:[si].DIS_strategy
done:
	.leave
	ret
CallRFSD	endp
