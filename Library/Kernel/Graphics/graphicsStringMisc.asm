COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Klib Graphics
FILE:		graphicsStringMisc.asm 

AUTHOR:		Jim DeFrisco, 5 April 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/5/90		Initial revision


DESCRIPTION:
	Various gstring related functions
		

	$Id: graphicsStringMisc.asm,v 1.1 97/04/05 01:12:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsString	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write an escape element to a graphics string

CALLED BY:	GLOBAL

PASS:		di	- handle to a graphics string
		ax	- escape code of element
		cx	- size of element to write
		ds:si	- far pointer to element data

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Write out a packet that looks like:
			byte	content		description
			----	-------		-----------
			0	0xff		escape indicator
			1-2	ax		escape code
			2-3	cx		size of escape data
			3-n	buff -> ds:si	escape data

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrEscape	proc	far
		mov	ss:[TPD_callVector].segment, cx
		mov	ss:[TPD_dataBX], handle GrEscapeReal
		mov	ss:[TPD_dataAX], offset GrEscapeReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrEscape	endp
CopyStackCodeXIP	ends

else

GrEscape	proc	far
		FALL_THRU	GrEscapeReal
GrEscape	endp

endif

GrEscapeReal	proc	far
		uses	ax, bx, cx, dx, di, si, ds, es
		.enter

		; make sure we have a gstring, then write out the opcode

		mov	dx, ax			; save code
		mov	bx, di			; lock the gstate block
		call	MemLock
		mov	es, ax			; ds -> gstate block
		mov	di, es:[GS_gstring]	; get gstring handle
		tst	di			; if zero, exit
		jz	done			; not a gstring, exit

		push	bx			; save gstate handle
		mov	al, GR_ESCAPE
		mov	bx, dx			; set up escape code
		mov	dx, cx			; set up size of escape data
		mov	cl, size OpEscape - 1	; 4 bytes to store
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes		; store the bytes

		; now write out the data part

		mov	cx, dx			; restore count
		mov	ax, (GSSC_FLUSH	shl 8) or 0xff	; can flush the first
		call	GSStore			; store the data part
		pop	bx			; restore gstate handle

		; all done, restore regs and leave
done:
		mov	di, bx				; restore gstate han
		call	MemUnlock
		.leave
		ret
GrEscapeReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a label element to a graphics string

CALLED BY:	GLOBAL

PASS:		di	- handle to a graphics string
		ax	- label value

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Write out a packet that looks like:
			byte	content		description
			----	-------		-----------
			0	GR_LABEL	label opcode
			1-2	ax		label value

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrLabel		proc	far
		uses	dx, bx, ax, es, cx
		.enter

		; make sure we have a gstring, then write out the opcode

		mov	dx, ax			; save code
		mov	bx, di			; lock the gstate block
		call	MemLock
		mov	es, ax			; es -> gstate block
		mov	di, es:[GS_gstring]	; get gstring handle
		tst	di			; if zero, exit
		jz	done			; not a gstring, exit

		push	bx			; save gstate handle
		mov	al, GR_LABEL
		mov	bx, dx			; set up escape code
		mov	cl, size OpLabel - 1	; 2 bytes to store
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; store the bytes
		pop	bx			; restore gstate handle

		; all done, restore regs and leave
done:
		mov	di, bx				; restore gstate han
		call	MemUnlock
		.leave
		ret
GrLabel		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrComment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a comment out to a graphics string

CALLED BY:	GLOBAL

PASS:		di	- gstring handle 
		ds:si	- pointer to comment data
		cx	- size of data

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrComment	proc	far
		mov	ss:[TPD_callVector].segment, cx
		mov	ss:[TPD_dataBX], handle GrCommentReal
		mov	ss:[TPD_dataAX], offset GrCommentReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrComment	endp
CopyStackCodeXIP	ends

else

GrComment	proc	far
		FALL_THRU	GrCommentReal
GrComment	endp

endif

GrCommentReal	proc	far
		uses	ax, bx, cx, es
		.enter
		
		; make sure we have a gstring, then write out the opcode

		mov	bx, di			; lock the gstate block
		call	MemLock
		mov	es, ax			; ds -> gstate block
		mov	di, es:[GS_gstring]	; get gstring handle
		call	MemUnlock
		tst	di			; if zero, exit
		jz	done			; not a gstring, exit

		; write out the opcode and size

		push	bx			; save gstate handle
		mov	al, GR_COMMENT
		mov	bx, cx
		mov	cl, size OpComment - 1	; #bytes of data to store
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes		; store opcode and size

		; restore size and write out data

		mov	cx, bx
		mov	ax, (GSSC_FLUSH shl 8) or 0xff	; 
		call	GSStore			; store comment data
		pop	bx			; restore gstate handle

done:
		mov	di, bx			; restore gstate handle
		.leave
		ret
GrCommentReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrNewPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End the current page (usually with a form feed).

CALLED BY:	GLOBAL

PASS:		di	- gstate or gstring handle
		al	- PageEndCommand

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (writing to a path)
		    ignore
		else if (writing to gstring)
		    store GR_NEW_PAGE code;
		else
		    invalidate the whole window;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		When printing, this will cause a new GState to be created,
		so all current GState settings will be lost.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrNewPage	proc	far
		uses 	ax, bx, cx, es
		.enter

		; if gstate, invalidate the whole window, else store the
		; gstring code.

EC <		cmp	al, PageEndCommand				>
EC <		ERROR_AE GRAPHICS_ILLEGAL_PAGE_END_COMMAND		>
		mov	cl, al				; PageEndCommand
		mov	bx, di				; get gstate handle in
		call	MemLock				; get gstate
		mov	es, ax				; es -> gstate

		; check for graphics string (the EC code is delayed
		; until after the path check, as there is always a
		; saved GState when defining a path)

		test	es:[GS_pathFlags], mask PF_DEFINING_PATH
		jnz	resetState
EC <		tst	es:[GS_saveStateLink]				>
EC <		ERROR_NZ GRAPHICS_UNBALANCED_SAVE_RESTORE_STATE		>
		mov	di, es:[GS_gstring]		; get gstring handle
		tst	di				; if non-NULL, write it
		jnz	gsegNewPage

		; it's not a gstring, invalidate the window
resetState:
		mov	di, bx				; recover gstate han
		call	MemUnlock			; release GState
;		call	GrSetDefaultState		; reset GState

		.leave
		ret

		; writing to graphics string, handle it
gsegNewPage:
		mov	al, GR_NEW_PAGE			; write out opcode
		mov	ah, cl				; PageEndCommand
		mov	cx, 1 or (GSSC_FLUSH shl 8)
		call	GSStoreBytes
		jmp	resetState
GrNewPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrNullOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store a NOP to a graphics string

CALLED BY:	GLOBAL

PASS:		di	- gstate or gstring handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrNullOp	proc	far
		uses 	ax, bx, cx, ds
		.enter

		; make sure we have a gstring, then write out the opcode

		mov	bx, di			; lock the gstate block
		call	MemLock
		mov	ds, ax			; ds -> gstate block
		mov	di, ds:[GS_gstring]	; get gstring handle
		tst	di			; if zero, exit
		jz	done			; not a gstring, exit

		mov	al, GR_NULL_OP
		mov	cx, 0 or (GSSC_FLUSH shl 8)
		call	GSStoreBytes
done:
		mov	di, bx			; restore gstate handle
		call	MemUnlock		; release the gstate block
		.leave
		ret
GrNullOp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetGStringBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store a GR_SET_STRING_BOUNDS opcode to a graphics string

CALLED BY:	GLOBAL

PASS:		di	- gstate or gstring handle
		ax	- left side bound
		bx	- top side bound
		cx	- right side bound
		dx	- bottom side bound

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrSetGStringBounds proc	far
		uses 	ax, bx, cx, dx, si, bp, ds
		.enter

		; make sure we have a gstring, then write out the opcode

		mov	si, ax			; save params
		mov	bp, bx
		mov	bx, di			; lock the gstate block
		call	MemLock
		mov	ds, ax			; ds -> gstate block
		mov	di, ds:[GS_gstring]	; get gstring handle
		tst	di			; if zero, exit
		jz	done			; not a gstring, exit

		push	dx			; set up block with parms
		push	cx
		push	bp
		push	si
		segmov	ds, ss, si		; set ds:si -> block
		mov	si, sp
		mov	cx, 8
		mov	ax, GR_SET_GSTRING_BOUNDS or (GSSC_FLUSH shl 8)
		call	GSStore
		add	sp, cx			; restore stack
done:
		mov	di, bx			; restore gstate handle
		call	MemUnlock		; unlock the gstate
		.leave
		ret
GrSetGStringBounds endp

GraphicsString	ends

