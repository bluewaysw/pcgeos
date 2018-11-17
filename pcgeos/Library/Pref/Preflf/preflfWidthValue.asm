COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS	
MODULE:		
FILE:		preflfWidthValue.asm

AUTHOR:		Ian Porteous, Apr 28, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	4/28/94   	Initial revision


DESCRIPTION:
	
		

	$Id: preflfWidthValue.asm,v 1.1 97/04/05 01:29:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefWidthValueLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefWidthValueClass object
		ds:di	= PrefWidthValueClass instance data
		es	= Segment of PrefWidthValueClass.

		ss:bp   = GenOptionsParams

RETURN:		

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	4/28/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefWidthValueLoadOptions	method	dynamic	PrefWidthValueClass, 
					MSG_GEN_LOAD_OPTIONS
	.enter
	
	call	SysGetInkWidthAndHeight
	mov	cl, 8
	shr	ax, cl
	push	ds, si
	mov	cx, ss
	mov	ds, cx
	lea	si, ss:[bp].GOP_category
	lea	dx, ss:[bp].GOP_key
	call	InitFileReadInteger
	pop	ds, si

	mov	cx, ax
	mov	ax, MSG_PREF_VALUE_SET_ORIGINAL_VALUE
	clr	bp		; XXX: LOOK IN VARDATA FOR THIS
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefWidthValueLoadOptions	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefWidthValueSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save options

PASS:		*ds:si	= PrefWidthValueClass object
		ds:di	= PrefWidthValueClass instance data
		es	= Segment of PrefWidthValueClass.
		ss:bp 	= GenOptionsParams

RETURN:		

DESTROYED:	ax, dx, cx, dx, bp, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	4/28/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefWidthValueSaveOptions	method	dynamic	PrefWidthValueClass, 
					MSG_GEN_SAVE_OPTIONS
	.enter

	push	bp
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	ObjCallInstanceNoLock
	pop	bp

	mov	ax, dx				; use integer part

	mov	cx, ss
	mov	ds, cx
	lea	si, ss:[bp].GOP_category
	lea	dx, ss:[bp].GOP_key

	mov	bp, ax				; value to write
	call	InitFileWriteInteger

	;
	; change global value for ink width
	;
	mov	ah, al
	call	SysSetInkWidthAndHeight

	;
	; send notification of ink changes to GCNSLT_INK
	;
	mov	ax, MSG_NOTIFY_INK_REDISPLAY
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	si, GCNSLT_INK
	mov	di, mask GCNLSF_FORCE_QUEUE	
	call	GCNListRecordAndSend
	
	.leave
	ret
PrefWidthValueSaveOptions	endm
