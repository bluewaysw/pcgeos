COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiControl.asm

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
	CDB	1/ 2/92	Initial version.

DESCRIPTION:
	Common procedures for UI controllers

	$Id: uiControl.asm,v 1.1 97/04/07 11:09:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyDupInfoCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the controller's DupInfo table

CALLED BY:

PASS:		cx:dx - location to copy table to
		ds:si - source of table

RETURN:		nothing 

DESTROYED:	cx,ds,si,es,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyDupInfoCommon	proc far
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep	movsb
	ret
CopyDupInfoCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendListSetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		cx - list data to set.
		^lbx:si - list object to set

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/27/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendListSetExcl	proc	near	
	uses	ax, cx,dx,bp
	.enter
	clr	dx		; no indeterminates
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjMessageSend
	.leave
	ret

SendListSetExcl	endp


ObjMessageSend	proc	near	
	uses di
	.enter
	clr	di
	call	ObjMessage
	.leave
	ret
ObjMessageSend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessageCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to an object that may not exist

CALLED BY:

PASS:		ax,cx,dx,bp - message data
		^lbx:si - object to send to

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMessageCheck	proc near
	uses	ax,bx,cx,dx,di,si,bp,ds
	.enter
	tst	bx
	jz	done

	push	ax
	call	ObjLockObjBlock
	mov	ds, ax
	pop	ax

	call	CheckChunkHandle
	jz	unlock
	call	ObjCallInstanceNoLock
unlock:
	call	MemUnlock
done:
	.leave
	ret
ObjMessageCheck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckChunkHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine whether the chunk handle is valid.
		This makes all the same checks as the EC code, but is
		designed to be used to abort an operation when the
		handle isn't valid.  This is simpler than adding tons
		of checks higher up.

CALLED BY:	ObjMessageCheck

PASS:		*ds:si - handle to check

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	See if beyond the end of the handle table.
	See if it points to zero
	See if it points to -1
	See if the size of the thing is zero

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/26/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckChunkHandle	proc near
		uses	ax,si
		.enter

		mov	ax, ds:[LMBH_nHandles]
		shl	ax
		sub	si, ds:[LMBH_offset]
		cmp	si, ax
		ja	invalid

		add	si, ds:[LMBH_offset]
		mov	si, ds:[si]
		tst	si
		jz	invalid
		cmp	si, -1
		je	invalid

	;
	; The chunk may have been resized to zero...
	;

		ChunkSizePtr	ds, si, ax
		tst	ax
		jz	invalid

		clc
done:
		.leave
		ret
invalid:
		stc
		jmp	done
CheckChunkHandle	endp
