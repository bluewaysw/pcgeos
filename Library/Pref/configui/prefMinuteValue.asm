COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		preflfMinuteValue.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/21/93   	Initial version.

DESCRIPTION:
	

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConfigUICode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMinuteValueLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefMinuteValueClass object
		ds:di	= PrefMinuteValueClass instance data
		es	= Segment of PrefMinuteValueClass.

		ss:bp   = GenOptionsParams

RETURN:		

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	Load from .INI file, convert from seconds to minutes

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMinuteValueLoadOptions	method	dynamic	PrefMinuteValueClass, 
					MSG_GEN_LOAD_OPTIONS
	.enter

	push	ds, si
	mov	cx, ss
	mov	ds, cx
	lea	si, ss:[bp].GOP_category
	lea	dx, ss:[bp].GOP_key
	call	InitFileReadInteger
	pop	ds, si
	jc	done

	; convert seconds to minutes

	mov	bl, 60
	div	bl

	mov	cx, ax
	mov	ax, MSG_PREF_VALUE_SET_ORIGINAL_VALUE
	clr	bp		; XXX: LOOK IN VARDATA FOR THIS
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
PrefMinuteValueLoadOptions	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMinuteValueSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save options

PASS:		*ds:si	= PrefMinuteValueClass object
		ds:di	= PrefMinuteValueClass instance data
		es	= Segment of PrefMinuteValueClass.
		ss:bp 	= GenOptionsParams

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMinuteValueSaveOptions	method	dynamic	PrefMinuteValueClass, 
					MSG_GEN_SAVE_OPTIONS
	.enter

	; Convert minutes to seconds

	push	bp
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	ObjCallInstanceNoLock
	pop	bp

	mov	ax, dx			; use integer part
	mov	bl, 60
	mul	bl

	mov	cx, ss
	mov	ds, cx
	lea	si, ss:[bp].GOP_category
	lea	dx, ss:[bp].GOP_key

	mov_tr	bp, ax				; value to write
	call	InitFileWriteInteger

	.leave
	ret
PrefMinuteValueSaveOptions	endm

ConfigUICode	ends
