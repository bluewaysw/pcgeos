COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefText.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/26/92   	Initial version.

DESCRIPTION:
	

	$Id: prefText.asm,v 1.1 97/04/04 17:50:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTextLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Load options and store value in original field

PASS:		*ds:si	= PrefTextClass object
		ds:di	= PrefTextClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTextLoadOptions	method	dynamic	PrefTextClass, 
					MSG_META_LOAD_OPTIONS
	.enter
	mov	di, offset PrefTextClass
	call	ObjCallSuperNoLock

	; Ask the text to give us its data

	call	GetTextChunk		; *ds:cx - chunk of text

	mov	di, ds:[si]
	add	di, ds:[di].Pref_offset
	mov	ds:[di].PTI_originalText, cx

	.leave
	ret
PrefTextLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTextHasStateChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefTextClass object
		ds:di	= PrefTextClass instance data
		es	= dgroup

RETURN:		IF STATE CHANGED:
			carry set
		ELSE
			carry clear

DESTROYED:	ax,cx,dx,bp 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTextHasStateChanged	method	dynamic	PrefTextClass, 
					MSG_PREF_HAS_STATE_CHANGED
	.enter

	mov	di, ds:[di].PTI_originalText

	call	GetTextChunk

	segmov	es, ds
	mov	si, cx
	push	cx				; save chunk returned

	mov	si, ds:[si]
	mov	di, ds:[di]

	clr	cx			; null-terminated strings
	call	LocalCmpStrings
	je	noChange		; carry is clear
	stc
noChange:	

	pop	ax			; free up the text block
	pushf
	call	LMemFree
	popf
	.leave
	ret
PrefTextHasStateChanged	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTextReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Reset the text

PASS:		*ds:si	= PrefTextClass object
		ds:di	= PrefTextClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTextReset	method	dynamic	PrefTextClass, 
						MSG_GEN_RESET
		
		mov	bp, ds:[di].PTI_originalText
		tst	bp
		jz	bail
		
		mov	dx, ds:[LMBH_handle]
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR	
		GOTO	ObjCallInstanceNoLock

bail:
		ret
PrefTextReset	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Procedure to get the text object's text into a chunk

CALLED BY:	PrefTextHasStateChanged, PrefTextLoadOptions

PASS:		*ds:si - text object

RETURN:		*ds:cx - text chunk

DESTROYED:	ax,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextChunk	proc near
	.enter
	
	mov	dx, ds:[LMBH_handle]
	clr	bp
	mov	ax, MSG_VIS_TEXT_GET_ALL_OPTR
	call	ObjCallInstanceNoLock

	.leave
	ret
GetTextChunk	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTextSendStatusMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the initfile category of the target object, if
		any. 

PASS:		*ds:si	= PrefTextClass object
		ds:di	= PrefTextClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTextSendStatusMsg	method	dynamic	PrefTextClass, 
					MSG_GEN_TEXT_SEND_STATUS_MSG,
					MSG_GEN_APPLY

		mov	di, offset PrefTextClass
		call	ObjCallSuperNoLock

		mov	ax, ATTR_PREF_TEXT_INIT_FILE_CATEGORY_TARGET
		call	ObjVarFindData
		jnc	done

		push	ds:[bx]		; target object

	;
	; Get the text.  Have the text object allocate a block.
	;
		
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		clr	dx
		call	ObjCallInstanceNoLock
		mov	bx, cx
		call	MemLock
		mov_tr	cx, ax			; cx:dx - fptr to string
		clr	dx

		pop	si			; target object
		mov	ax, MSG_PREF_SET_INIT_FILE_CATEGORY
		call	ObjCallInstanceNoLock

		call	MemFree
done:
		.leave
		ret
PrefTextSendStatusMsg	endm

