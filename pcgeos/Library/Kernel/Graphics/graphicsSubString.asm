
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Graphics
FILE:		graphicsSubString.asm

AUTHOR:		Jim DeFrisco, 31 January 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/91		Initial revision


DESCRIPTION:
	These routines implement the substring capability in the graphics
	string code.
		

	$Id: graphicsSubString.asm,v 1.1 97/04/05 01:12:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; THE REST OF THIS FILE IS IF(0)'d OUT.  THE CODE IS FOR SUPPORT FOR SUBSTRINGS
; WHICH SHOULD BE ADDED IN RELEASE 2.
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (0)			; put in substrings later...

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrBeginSubString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the definition of a substring

CALLED BY:	GLOBAL

PASS:		di	- handle of parent graphics string
		bx	- desired substring ID

RETURN:		bx	- substring ID, may have changed if collision with
			  previously defined substring

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Current design allows only one open substring definition per
		graphics string.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrBeginSubString proc	far
		ret
GrBeginSubString endp

;--------	special cases

		; trying to create a sub-string. Check to see if handle passed
		; is a valid GSTRING handle...then alloc new chunk
GBS_substring:
EC <		cmp	ds:[di].HGS_handleSig, SIG_GSTRING ; valid han? >
EC <		ERROR_NZ GRAPHICS_BAD_GSTRING_HANDLE			>
EC <		cmp	ds:[di].HGS_hSubStr, 0	; have sub-string ? 	>
EC <		ERROR_NZ GRAPHICS_BAD_GSTRING_NESTING			>

		; lock GString structure, alloc a new chunk for substring

		push	bx			; save possible substring handle
		mov	bx, ds:[di].HGS_hGStruct	; get handle to gstring struct
		segmov	es, ds			; es -> kernel data
		call	NearLockDS		; ds <- seg addr of gstring
		clr	cx			; init to empty chunk
		call	LMemAlloc		; alloc substring chunk
EC <		call	ECLMemValidateHeap	; check it out, baby	>
		mov	es:[di].HGS_hSubStr, ax	; store here too
		call	MemUnlock		; unlock gstring block
		pop	cx			; restore old substring handle

		; write the BEGIN_SUB_STRING opcode out to the open string.

		test	es:[di].HGS_flags, mask GSF_READ_ONLY ; don't write in
		jnz	GBS_readOnly		;   this case
		mov	bx, ax			; store lmem handle
		mov	al, GR_BEGIN_SUB_STRING	; store new string code
		mov	cl, 3			; opcode plus handle
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; write it out
		jmp	GBS_done		; all done

		; for read-only blocks, add to reloc chunk
GBS_readOnly:
		mov	si, ax			; si = new substring handle
		call	NearLockDS		; lock GState structure block
		mov	ax, si			; restore new handle
		mov	si, ds:[si]		; get pointer to chunk
		mov	dx, cx			; save old chunk handle
		mov	cx, ds:[si]		; get old reloc count
		inc	word ptr ds:[si]	; bump count
		shl	cx, 1			; 4 words per
		shl	cx, 1			;  reloc entry
		add	cx, 6			; +2 (count), +4 (new entry)
		call	LMemReAlloc
		sub	cx, 4			; cx = offset to reloc entry
		add	si, cx			; ds:si -> reloc entry
		mov	ds:[si], dx		; save old handle
		mov	ds:[si+2], ax		; save new handle
		call	MemUnlock		; release block
		jmp	GBS_done		; all done

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrEndSubString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Terminate the definition of a graphics substring

CALLED BY:	GLOBAL

PASS:		di	- handle to parent graphics string

RETURN:		bx	- substring ID

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrEndSubString	proc	far
		ret
GrEndSubString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawSubString, GrDrawSubStringAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a graphics string

CALLED BY:	GLOBAL

PASS:		di	- gstate handle of target draw space

		ax	- parameter 0			(GrDrawSubStringAtCP)
		bx	- parameter 1			(GrDrawSubStringAtCP)
		cx	- parameter 2			(GrDrawSubStringAtCP)
		dx	- parameter 3			(GrDrawSubStringAtCP)
		     -- OR --
		ax	- x coordinate to draw string  	(GrDrawSubString)
     		bx	- y coordinate to draw string  	(GrDrawSubString)
		cx	- parameter 0			(GrDrawSubString)
		dx	- parameter 1			(GrDrawSubString)

		si	- substring ID
		bp	- parent gstring handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Interpret the drawing opcodes in the string, until a string
		terminator is encountered.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawSubString	proc	far
		ret
GrDrawSubString	endp

GrDrawSubStringAtCP proc	far
		ret
GrDrawSubStringAtCP endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RelocSubstring
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relocate a substring handle

CALLED BY:	INTERNAL
		GrDrawGStringAtCP, GrDrawGString, GrPlayStringAtCP, GrPlayString

PASS:		di	- handle to target gstring
		si	- old substring handle

RETURN:		carry	- set on some error (invalid substring handle)
		si	- new substring handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		lock substring block;
		do lookup for new handle;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


RelocSubstring	proc	near
		uses	ax,bx,cx,di			; save some regs
		.enter
		mov	bx, ds:[di].HGS_hGStruct		; get block handle
		call	NearLockDS			; lock the block
		mov	di, si				; save substring han
		mov	si, ds:[GSS_hReloc]		; get handle to reloc
EC <		call	ECLMemValidateHandle		; make sure handle ok >
		mov	si, ds:[si]			; get ptr to reloc
		mov	cx, ds:[si]			; get reloc item count
		add	si, 2				; bump pointer to first
		tst	cx				; if no items...
		jz	panic				;  something is fishy

		; loop past all reloc entries, look for this one
relocLoop:
		cmp	di, ds:[si]			; is this the one ?
		je	foundReloc			;  yes, deal with it
		add	si, 4				;  no, round again
		dec	cx
		jnz	relocLoop

		; oh, oh.  something very wrong is happening...
panic:
EC <		ERROR	GRAPHICS_BAD_SUBSTRING_HANDLE	; totally hosed	>
		stc					; signal error
		jmp	exit

		; found reloc entry, do relocation
foundReloc:
		mov	si, ds:[si+2]			; get new handle
EC <		call	ECLMemValidateHandle		; make sure handle ok >
		clc					; no error
exit:
		.leave
		ret
RelocSubstring	endp

endif
