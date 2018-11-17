COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefPortItem.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/24/94   	Initial version.

DESCRIPTION:
	

	$Id: prefPortItem.asm,v 1.1 97/04/04 17:50:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPortItemInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefPortItemClass object
		ds:di	- PrefPortItemClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/24/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
parallelDriver	char	"parallel.geo",0
NEC <serialDriver	char	"serial.geo",0>
EC <serialDriver	char	"serialec.geo",0>

PrefPortItemInit	method	dynamic	PrefPortItemClass, 
					MSG_PREF_INIT

		mov	di, offset PrefPortItemClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].PrefPortItem_offset	
		mov	ds:[di].PPII_status, TRUE	; assume enabled

	;
	; Allow for more types down the road
	;
		mov	al, ds:[di].PPII_type
		cmp	al, PrefPortItemType
		jae	done

		push	ds, si			; object
		cmp	al, PPIT_PARALLEL
		mov	si, offset parallelDriver
		je	gotDriver
		mov	si, offset serialDriver
gotDriver:
		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		segmov	ds, cs
		clr	ax, bx
		call	GeodeUseDriver
		pop	ds, si			; object
		
		call	FilePopDir
		jc	done

		push	ds, di, si
		call	GeodeInfoDriver
		mov	di, DR_STREAM_GET_DEVICE_MAP
		call	ds:[si].DIS_strategy
		pop	ds, di, si

		call	CheckMousePort
		
		test	ds:[di].PPII_portMask, ax
		mov	ax, MSG_GEN_SET_ENABLED
		jnz	sendMessage
		inc	ax
		.assert MSG_GEN_SET_NOT_ENABLED eq MSG_GEN_SET_ENABLED+1
		mov	ds:[di].PPII_status, FALSE	; not enabled
sendMessage:
		mov	dl, VUM_MANUAL
		call	ObjCallInstanceNoLock

		mov	ax, MSG_PREF_PORT_ITEM_FREE_DRIVER
		mov	cx, bx			; driver handle
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		
		ret
PrefPortItemInit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckMousePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this port item is for a serial port that's NOT the
		mouse port, then disable the port that the mouse is on.
		Also check the "secondMouse" category, so that this
		will work on pen-based systems that support a mouse
		(i.e. Bullet)

CALLED BY:	PrefPortItemInit

PASS:		ds:di - PrefPortItemInstance
		ax - SerialDeviceMap

RETURN:		ax - new SerialDeviceMap

DESTROYED:	cx,dx,bp,si

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/27/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
secondMouseCatString		char	"secondMouse", 0
mouseCatString			char	"mouse", 0
portKeyString			char	"port", 0

serialMapTable	label	word
	word	not mask SDM_COM1
	word	not mask SDM_COM2
	word	not mask SDM_COM3
	word	not mask SDM_COM4

CheckMousePort	proc near

		class	PrefPortItemClass
		
		uses	ds, si, bx
		.enter
		mov_tr	bp, ax		; SerialDeviceMap

		cmp	ds:[di].PPII_type, PPIT_SERIAL
		jne	done

		mov	si, offset mouseCatString
		call	checkMousePort

		mov	si, offset secondMouseCatString
		call	checkMousePort

		
done:
		mov_tr	ax, bp		; SerialDeviceMap

		.leave
		ret

;;--------------------
checkMousePort:
	; si - offset of category string
		
		mov	cx, cs
		mov	ds, cx
		mov	dx, offset portKeyString
		call	InitFileReadInteger		; get the port #
		jc	cmpDone

		mov_tr	bx, ax				
		shl	bx, 1
		and	bp, cs:[serialMapTable-2][bx]
cmpDone:
		retn

CheckMousePort	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPortItemFreeDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Free the thing

PASS:		*ds:si	- PrefPortItemClass object
		ds:di	- PrefPortItemClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/24/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefPortItemFreeDriver	method	dynamic	PrefPortItemClass, 
					MSG_PREF_PORT_ITEM_FREE_DRIVER
		mov	bx, cx
		call	GeodeFreeLibrary
		ret
PrefPortItemFreeDriver	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPortItemGetStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefPortItemClass object
		ds:di	- PrefPortItemClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/27/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefPortItemGetStatus	method	dynamic	PrefPortItemClass, 
					MSG_PREF_PORT_ITEM_GET_STATUS

		mov	al, ds:[di].PPII_status
		cbw
		ret
PrefPortItemGetStatus	endm

