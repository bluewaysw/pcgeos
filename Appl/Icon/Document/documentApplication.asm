COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Icon Editor
FILE:		documentApplication.asm

AUTHOR:		Steve Yegge, Mar 23, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/23/93	Initial revision

DESCRIPTION:

	Implementation of IconApplicationClass

	$Id: documentApplication.asm,v 1.1 97/04/04 16:06:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconApplicationNewModel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by document when it gains the model.

CALLED BY:	MSG_ICON_APPLICATION_NEW_MODEL

PASS:		*ds:si	= IconApplicationClass object
		ds:di	= IconApplicationClass instance data
		^lcx:dx = optr of the bitmap object in the document that
		now has the model.

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconApplicationNewModel	method dynamic IconApplicationClass, 
					MSG_ICON_APPLICATION_NEW_MODEL
		uses	ax, cx, dx, bp
		.enter
	;
	;  Store the passed bitmap object optr.
	;
		mov	ds:[di].IAI_curBitmap.handle, cx
		mov	ds:[di].IAI_curBitmap.chunk, dx
		
		.leave
		ret
IconApplicationNewModel	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IASendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a classed event down a heirarchy.

CALLED BY:	MSG_META_SEND_CLASSED_EVENT

PASS:		*ds:si	= IconApplicationClass object
		ds:di	= IconApplicationClass instance data
		dx	= TravelOption
		cx	= handle of classed event

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IASendClassedEvent	method dynamic IconApplicationClass, 
					MSG_META_SEND_CLASSED_EVENT
	;
	;  See if it's the TravelOption we handle.
	;
		cmp	dx, TO_BITMAP
		jne	passItUp
	;
	;  It is.  Send it on its way, or biff the message if no current
	;  bitmap.
	;
		mov	bx, ds:[di].IAI_curBitmap.handle
		mov	si, ds:[di].IAI_curBitmap.chunk
		tst	bx
		jz	destroyIt
		mov	di, mask MF_FIXUP_DS
		GOTO	ObjMessage
destroyIt:
	;
	;  No current bitmap, so biff the message.
	;
		mov	bx, cx
		call	ObjFreeMessage
		ret
passItUp:
	;
	;  Not our travel option, so let the superclass deal with it.
	;
		mov	di, offset IconApplicationClass
		GOTO	ObjCallSuperNoLock
IASendClassedEvent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IAGetBitmapOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns optr of the bitmap in the document with the model.

CALLED BY:	MSG_ICON_APPLICATION_GET_BITMAP_OPTR
PASS:		*ds:si	= IconApplicationClass object
		ds:di	= IconApplicationClass instance data
		ds:bx	= IconApplicationClass object (same as *ds:si)
		es 	= segment of IconApplicationClass
		ax	= message #

RETURN:		^lcx:dx = bitmap
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	   3/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IAGetBitmapOptr	method dynamic IconApplicationClass, 
				MSG_ICON_APPLICATION_GET_BITMAP_OPTR
	;
	;  Just return the bitmap and quit.
	;
		mov	cx, ds:[di].IAI_curBitmap.handle
		mov	dx, ds:[di].IAI_curBitmap.chunk
		
		ret
IAGetBitmapOptr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconAppGetImageBitSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns pixel view size.

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ax	= ImageBitSize

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/14/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconAppGetImageBitSize	proc	far
		uses	bx,cx,dx,si,di,bp
		.enter

		GetResourceHandleNS	FatbitImageSizeGroup, bx
		mov	si, offset	FatbitImageSizeGroup
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage	; ax = selection

		clr	ah

		.leave
		ret
IconAppGetImageBitSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconInstallToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install tokens.

CALLED BY:	MSG_GEN_PROCESS_INSTALL_TOKEN

PASS:		*ds:si	= IconProcessClass object
		ds:di	= IconProcessClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconInstallToken	method dynamic IconProcessClass, 
					MSG_GEN_PROCESS_INSTALL_TOKEN
		.enter
	;
	;  Call our superclass to get the ball rolling...
	;
		mov	di, offset IconProcessClass
		call	ObjCallSuperNoLock
	;
	;  Install datafile token.
	;
		mov	ax, ('I') or ('D' shl 8)	; ax:bx:si = token used
		mov	bx, ('O') or ('C' shl 8)	;  for datafile
		mov	si, MANUFACTURER_ID_GEOWORKS
		call	TokenGetTokenInfo		; is it there yet?
		jnc	done
		
		mov	cx, handle IconDatafileMonikerList
		mov	dx, offset IconDatafileMonikerList
		clr	bp			; list is in data resource...
		call	TokenDefineToken	; add icon to token database
done:		
		.leave
		ret
IconInstallToken	endm


CommonCode	ends
