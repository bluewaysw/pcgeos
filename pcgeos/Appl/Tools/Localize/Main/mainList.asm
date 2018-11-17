COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit	/Main
FILE:		mainList.asm

AUTHOR:		Cassie Hartzong, Feb 16, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	2/16/93		Initial revision


DESCRIPTION:
	code to implement the mnemonic list	

	$Id: mainList.asm,v 1.1 97/04/04 17:13:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata	segment
    	ResEditValueClass
    	ResEditMnemonicTextClass
idata	ends


MainListCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditValueIncrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the next mnemonic

CALLED BY:	GLOBAL (MSG_GEN_VALUE_INCREMENT)

PASS:		*DS:SI	= ResEditValueClass object
		DS:DI	= ResEditValueClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditValueIncrement	method dynamic	ResEditValueClass, 
					MSG_GEN_VALUE_INCREMENT
		mov	dx, MC_FORWARD
		GOTO	ResEditValueChange
ResEditValueIncrement	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditValueDecrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the previous mnemonic

CALLED BY:	GLOBAL (MSG_GEN_VALUE_DECREMENT)

PASS:		*DS:SI	= ResEditValueClass object
		DS:DI	= ResEditValueClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditValueDecrement		method dynamic	ResEditValueClass,
					MSG_GEN_VALUE_DECREMENT

	mov	dx, MC_BACKWARD
	FALL_THRU	ResEditValueChange
ResEditValueDecrement	endm

ResEditValueChange	proc	far

	push	si
	GetResourceSegmentNS	ResEditDocumentClass, es
	mov	bx, es
	mov	si, offset ResEditDocumentClass
	mov	di, mask MF_RECORD
	mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_MNEMONIC
	call	ObjMessage
	mov	cx, di
	pop	si

	mov	bx, ds:[LMBH_handle]
	mov	dx, TO_OBJ_BLOCK_OUTPUT
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	clr	di
	GOTO	ObjMessage

ResEditValueChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditValueGetValueText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text for this object, which is always NULL

CALLED BY:	GLOBAL (MSG_GEN_VALUE_GET_VALUE_TEXT)

PASS:		*DS:SI	= ResEditValueClass object
		DS:DI	= ResEditValueClassInstance
		CX:DX	= Buffer to fill
		BP	= GenValueType

RETURN:		CX:DX	= Filled buffer

DESTROYED:	AX, DI, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		cassie	2/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditValueGetValueText	method dynamic	ResEditValueClass,
					MSG_GEN_VALUE_GET_VALUE_TEXT
	.enter

	; Return the shortest string possible, which I
	; will assume is a space followed by a NULL.
	; Returning a NULL string is useless for size determination
	;
	mov	es, cx
	mov	di, dx
if DBCS_PCGEOS
	mov	ax, C_SPACE	; space followed by NULL
	stosw
	clr	ax
	stosw
else
	mov	ax, ' '		; space followed by NULL
	stosw
endif

	.leave
	ret
ResEditValueGetValueText	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MnemonicTextKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept keyboard chars to do some special things.

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditMnemonicTextClass
		ax - the message
		cl - character		(Chars or VChar)
		ch - CharacterSet	(CS_BSW or CS_CONTROL)
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	If Del or Backspace, delete all text, change mnemonic to NIL.
	If whitespace (except blank), ignore.
	Otherwise, process as normal.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MnemonicTextKbdChar		method dynamic ResEditMnemonicTextClass,
						MSG_META_KBD_CHAR
	test	dl, mask CF_FIRST_PRESS
	jz	passOn

if not DBCS_PCGEOS
	cmp	ch, CS_CONTROL
	jne	passOn
endif
	
SBCS<	cmp	cl, VC_BACKSPACE				>
DBCS<	cmp	cx, C_SYS_BACKSPACE				>
	je	deleteAll

SBCS<	cmp	cl, VC_DEL					>
DBCS<	cmp	cx, C_DELETE					>
	je	deleteAll

SBCS<	cmp	cl, VC_TAB					>
DBCS<	cmp	cx, C_SYS_TAB					>
	je	done

SBCS<	cmp	cl, VC_ENTER					>
DBCS<	cmp	cx, C_SYS_ENTER					>
	je	done

SBCS<	cmp	cl, VC_LF					>
DBCS<	cmp	cx, C_LF					>
	je	done

passOn:
	mov	di, offset ResEditMnemonicTextClass	
	call	ObjCallSuperNoLock
done:
	ret

deleteAll:
	push	si
	GetResourceSegmentNS	ResEditDocumentClass, es
	mov	bx, es
	mov	si, offset ResEditDocumentClass
	mov	di, mask MF_RECORD
	mov	ax, MSG_RESEDIT_DOCUMENT_DELETE_MNEMONIC
	call	ObjMessage
	mov	cx, di
	pop	si

	mov	bx, ds:[LMBH_handle]
	mov	dx, TO_OBJ_BLOCK_OUTPUT
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	clr	di
	GOTO	ObjMessage

MnemonicTextKbdChar		endm

MainListCode	ends
