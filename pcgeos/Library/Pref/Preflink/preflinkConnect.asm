COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		preflinkConnect.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/28/92   	Initial version.

DESCRIPTION:
	

	$Id: preflinkConnect.asm,v 1.1 97/04/05 01:28:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLinkConnectItemGroupLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefLinkConnectItemGroupClass object
		ds:di	= PrefLinkConnectItemGroupClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefLinkConnectItemGroupLoadOptions	method	dynamic	PrefLinkConnectItemGroupClass, 
					MSG_META_LOAD_OPTIONS
	.enter

	clr	bx
	call	GetRFSDHandle
	jnc	notConnected

	mov	di, DR_RFS_GET_STATUS
	call	CallRFSD

	mov	cx, TRUE
	cmp	ax, RFS_DISCONNECTED
	je	notConnected
	cmp	ax, RFS_DISCONNECTING
	jne	sendIt
notConnected:
	mov	cx, FALSE
sendIt:
	mov	ax, MSG_PREF_ITEM_GROUP_SET_ORIGINAL_SELECTION
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefLinkConnectItemGroupLoadOptions	endm

