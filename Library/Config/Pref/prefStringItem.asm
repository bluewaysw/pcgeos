COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefStringItem.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 1/92   	Initial version.

DESCRIPTION:
	

	$Id: prefStringItem.asm,v 1.1 97/04/04 17:50:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefStringItemSetInitFileString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefStringItemClass object
		ds:di	= PrefStringItemClass instance data
		es	= Segment of PrefStringItemClass.
		cx:dx	= string to set

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefStringItemSetInitFileString	method	dynamic	PrefStringItemClass, 
				MSG_PREF_STRING_ITEM_SET_INIT_FILE_STRING
	uses	ax,cx,dx,bp
	.enter

	push	si		; object chunk handle

	; Free the current chunk

	mov	si, ds:[di].PSII_initFileString
	tst	si
	jz	afterFree
	mov	ax, si
	call	LMemFree
afterFree:

	; Get length, including null terminator (.ini strings are SBCS)

	mov	es, cx
	mov	di, dx
	mov	cx, -1
	clr	al
	repne	scasb
	not	cx	

	; allocate new chunk & copy string (convert to DBCS for DBCS)

DBCS <	shl	cx, 1		; # SBCS chars -> # bytes		>
	clr	al
	call	LMemAlloc
	mov	di, ax		; new chunk handle
	mov	di, ds:[di]
	mov	si, dx		; source
	segxchg	ds, es
SBCS <	rep	movsb							>
DBCS <	clr	ah							>
DBCS <copyLoop:								>
DBCS <	lodsb								>
DBCS <	stosw								>
DBCS <	loop	copyLoop						>
	segxchg	ds, es

	; Now, deref and store init file string

	pop	si
	mov	di, ds:[si]
	add	di, ds:[di].Pref_offset
	mov	ds:[di].PSII_initFileString, ax
	

	.leave
	ret
PrefStringItemSetInitFileString	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefStringItemCheckIfInInitFileKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the string bound to this PrefStringItem is in the
		string stored under the appropriate init file key.

CALLED BY:	MSG_PREF_STRING_ITEM_CHECK_IF_IN_INIT_FILE_KEY
PASS:		*ds:si	= PrefStringItem object
		ds:di	= PrefStringItemInstance
		ss:bp	= PrefItemGroupStringVars
RETURN:		carry set if it's there
		carry clear if it's not
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefStringItemCheckIfInInitFileKey method dynamic PrefStringItemClass,
				MSG_PREF_STRING_ITEM_CHECK_IF_IN_INIT_FILE_KEY
locals	local	PrefItemGroupStringVars
	uses	bp
	.enter	inherit
	sub	bp, offset locals	; point back to frame so we don't have
					;  to change CheckStringInBuffer and
					;  all its callers -- ardeb 4/9/93
	mov	bx, ds:[di].PSII_initFileString
	tst	bx
	jz	done
	mov	bx, ds:[bx]
	call	CheckStringInBuffer
done:
	.leave
	ret
PrefStringItemCheckIfInInitFileKey endm


