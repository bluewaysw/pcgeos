COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit
FILE:		documentKeyboard.asm

AUTHOR:		Cassie Hartzong, Mar  2, 1993

ROUTINES:
	Name			Description
	----			-----------
EXT	DocumentKbdChar		MSG_META_KBD_CHAR

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	3/ 2/93		Initial revision


DESCRIPTION:
	

	$Id: documentKeyboard.asm,v 1.1 97/04/04 17:14:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
    ResEditDisplayClass
idata	ends

DocumentListCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDisplayClass
		ax - the message
		cx - 
		^hbp - gstate
RETURN:		^hbp - gstate
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, dx, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayVisDraw		method dynamic ResEditDisplayClass,
						MSG_VIS_DRAW
	push	bp

	; hold up input
	;
	push	ax,cx,bp,si		; save message, parameters, chunk
	GetResourceHandleNS	ResEditApp, bx
	mov	si, offset ResEditApp
	mov	ax, MSG_GEN_APPLICATION_HOLD_UP_INPUT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax,cx,bp,si

	; call super to do the drawing
	;
	mov	di, offset ResEditDisplayClass
	call	ObjCallSuperNoLock

	; resume input
	;
	GetResourceHandleNS	ResEditApp, bx
	mov	si, offset ResEditApp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_APPLICATION_RESUME_INPUT
	call	ObjMessage

	pop	bp

	ret
DisplayVisDraw		endm



;-------------------------------------------------------------------------
;  ResEditDocument shortcut handlers.
;-------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocKbdPrevChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the previous chunk, wrapping if at the first chunk.

CALLED BY:		
PASS:		*ds:si	- document
RETURN:		nothing
DESTROYED:	cx, di	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocKbdPrevChunk		method dynamic	ResEditDocumentClass, 
				MSG_RESEDIT_DOCUMENT_KBD_PREV_CHUNK

	tst	ds:[di].REDI_numChunks
	jz	done
	mov	cx, ds:[di].REDI_curChunk
	tst	cx
	jnz	change
	mov	cx, ds:[di].REDI_numChunks
change:
	dec	cx
	call	DocKbdChangeChunkCommon
done:
	ret

DocKbdPrevChunk		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocKbdNextChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the next chunk, wrapping if at the last chunk.

CALLED BY:		
PASS:		*ds:si	- document
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocKbdNextChunk		method dynamic	ResEditDocumentClass, 
				MSG_RESEDIT_DOCUMENT_KBD_NEXT_CHUNK

	tst	ds:[di].REDI_numChunks
	jz	done
	mov	cx, ds:[di].REDI_curChunk
	inc	cx
	cmp	cx, ds:[di].REDI_numChunks
	jne	change
	clr	cx
change:
	call	DocKbdChangeChunkCommon
done:
	ret
DocKbdNextChunk		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocKbdChangeChunkCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common change chunk code.

CALLED BY:	DocKbdNextChunk, DocKbdPrevChunk	
PASS:		*ds:si	- document
		ds:di	- document
		cx	- chunk to change to
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,si,di	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocKbdChangeChunkCommon		proc	near

	push	cx
	call	DocumentChangeChunk
	pop	cx

	; update the chunk list to reflect the change
	;
	call	GetDisplayHandle
	mov	si, offset ChunkList
	clr	dx			; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call 	ObjMessage
	ret
DocKbdChangeChunkCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocKbdPrevResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the previous resource, wrapping if at first resource.

CALLED BY:		
PASS:		*ds:si	- document
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocKbdPrevResource		method dynamic	ResEditDocumentClass, 
				MSG_RESEDIT_DOCUMENT_KBD_PREV_RESOURCE

	mov	cx, ds:[di].REDI_curResource
	tst	cx
	jnz	change
	mov	cx, ds:[di].REDI_mapResources
change:
	dec	cx
	call	DocKbdChangeResourceCommon
	ret
DocKbdPrevResource		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocKbdNextResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the next resource, wrapping if at last resource.

CALLED BY:		
PASS:		*ds:si	- document
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocKbdNextResource		method dynamic	ResEditDocumentClass, 
				MSG_RESEDIT_DOCUMENT_KBD_NEXT_RESOURCE

	mov	cx, ds:[di].REDI_curResource
	inc	cx
	cmp	cx, ds:[di].REDI_mapResources
	jne	change
	clr	cx
change:
	call	DocKbdChangeResourceCommon
	ret
DocKbdNextResource		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocKbdChangeResourceCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common change resource code.

CALLED BY:	DocKbdNextResource, DocKbdPrevResource	
PASS:		*ds:si	- document
		ds:di	- document
		cx	- resource to change to
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,si,di	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocKbdChangeResourceCommon		proc	near

	clr	dx
	call	DocumentChangeResourceAndChunk
	ret

DocKbdChangeResourceCommon		endp


DocumentListCode	ends

