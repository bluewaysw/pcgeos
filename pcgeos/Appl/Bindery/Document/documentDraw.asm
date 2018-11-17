COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentDraw.asm

ROUTINES:
	Name			Description
	----			-----------
    INT ApplyTransY		Draw the document

    INT DrawMasterPages		Draw the master pages

    INT DrawMasterCallback	Callback to draw a master page

METHODS:
	Name			Description
	----			-----------
    StudioDocumentDraw		Draw the document

				MSG_VIS_DRAW
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the section related code for StudioDocumentClass

	$Id: documentDraw.asm,v 1.1 97/04/04 14:38:41 newdeal Exp $

------------------------------------------------------------------------------@

DocDrawScroll segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentDraw -- MSG_VIS_DRAW for StudioDocumentClass

DESCRIPTION:	Draw the document

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	cl - DrawFlags (DF_EXPOSED set if exposed), DF_PRINT
	bp - gstate

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/18/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentDraw	method dynamic	StudioDocumentClass, MSG_VIS_DRAW
					uses cx, es
	mov	di, bp				;di = gstate
flags		local	word	\
		push	cx
bounds		local	RectDWord
sectionPos	local	dword
vmfile		local	hptr
	ForceRef flags
	ForceRef sectionPos
	.enter

	call	GetFileHandle
	mov	vmfile, bx

	call	LockMapBlockES

	push	si, ds
	segmov	ds, ss
	lea	si, bounds
	call	GrGetMaskBoundsDWord
	pop	si, ds
	LONG jc	drawGrid

	test	flags.low, mask DF_PRINT
	LONG jnz doMasterPages

	; *** Draw the page border ***

	cmp	es:MBH_displayMode, VLTDM_PAGE
	LONG jnz afterMasterPages

	mov	ax, C_BLACK
	call	GrSetAreaColor
	mov	ax, SDM_50
	call	GrSetAreaMask

	; draw top if needed

	tst	bounds.RD_top.high
	jns	afterTop

	mov	ax, bounds.RD_left.low
	mov	bx, -PAGE_BORDER_SIZE
	mov	cx, bounds.RD_right.low
	clr	dx
	call	fillRect	
afterTop:

	; draw bottom if needed

	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	push	ds:[bx].SDI_size.PD_x.low
	mov	ax, ds:[bx].SDI_size.PD_y.low
	mov	bx, ds:[bx].SDI_size.PD_y.high	;bxax = height
	jledw	bounds.RD_bottom, bxax, afterBottom

	pushdw	bxax				;save translation
	call	ApplyTransY
	mov	ax, bounds.RD_left.low
	mov	bx, 0
	mov	cx, bounds.RD_right.low
	mov	dx, PAGE_BORDER_SIZE
	call	fillRect
	popdw	bxax
	call	negTransY
afterBottom:

	; translate for left/right

	movdw	bxax, bounds.RD_top
	call	ApplyTransY

	; draw left if needed

	cmp	bounds.RD_left.low, 0
	jge	afterLeft

	mov	ax, -PAGE_BORDER_SIZE
	clr	cx
	call	fillRectLR
afterLeft:

	; draw right if needed

	pop	cx					;cx = doc right
	cmp	bounds.RD_right.low, cx
	jle	afterRight

	mov	ax, cx
	add	cx, PAGE_BORDER_SIZE
	call	fillRectLR
afterRight:

	movdw	bxax, bounds.RD_top
	call	negTransY

	mov	ax, SDM_100
	call	GrSetAreaMask

	; *** Draw the master page(s) ***

	; To draw the master pages we need to know what master pages are
	; visible.  We do this by enumerating through the section table

doMasterPages:
	call	DrawMasterPages
afterMasterPages:

	; *** Draw everything else ***

	mov	ax, es:MBH_displayMode
	clc					; indicate mask not NULL

drawGrid:

	call	VMUnlockES

	mov	cl, flags.low

	.leave

	jc	done
	mov	di, bp

	test	cl, mask DF_PRINT
	jnz	drawAllArticles
	cmp	ax, VLTDM_PAGE
	jnz	textOnly

drawAllArticles:
	mov	ax, MSG_VIS_DRAW
	mov	di, offset StudioDocumentClass
	GOTO	ObjCallSuperNoLock

	; we are in a mode other than PAGE, so we want to draw the target
	; article only.

textOnly:
	call	LockMapBlockES
	mov	bp, di
	mov	ax, MSG_VIS_DRAW
	mov	di, mask MF_RECORD
	call	ObjMessage
	call	SendToFirstArticle
	call	VMUnlockES
done:
	ret

;---

fillRectLR:
	clr	bx
	mov	dx, bounds.RD_bottom.low
	sub	dx, bounds.RD_top.low
fillRect:
	call	GrFillRect
	retn

negTransY:
	negdw	bxax
	call	ApplyTransY
	retn

StudioDocumentDraw	endm

;---

ApplyTransY	proc	near	uses cx, dx
	.enter
	clrdw	dxcx
	call	GrApplyTranslationDWord
	.leave
	ret
ApplyTransY	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawMasterPages

DESCRIPTION:	Draw the master pages

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es - locked map block
	ss:bp - inherited RectDWord
	di - gstate

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
DrawMasterPages	proc	near	uses si, di, ds, es
	.enter inherit StudioDocumentDraw

	clrdw	sectionPos
	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset DrawMasterCallback
	call	ChunkArrayEnum

	.leave
	ret

DrawMasterPages	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawMasterCallback

DESCRIPTION:	Callback to draw a master page

CALLED BY:	INTERNAL

PASS:
	ds:di - SectionArrayElement
	ss:bp - inherited variables

RETURN:
	carry - set to end

DESTROYED:
	bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
DrawMasterCallback	proc	far
	.enter inherit DrawMasterPages

	; determine if this section is visible

	mov	ax, ds:[di].SAE_numPages
	mul	ds:MBH_pageSize.XYS_height		;dxax = section height
	adddw	dxax, sectionPos
	jgdw	dxax, bounds.RD_top, 10$
	jmp	next
10$:

	; this section is visible, compute the visible pages

	movdw	dxax, bounds.RD_top
	subdw	dxax, sectionPos
	tst	dx
	jns	notBefore
	clrdw	dxax
notBefore:

	; dxax = relative window top

	div	ds:MBH_pageSize.XYS_height		;ax = first page visible
	mov_tr	cx, ax					;cx = first

	movdw	dxax, bounds.RD_bottom
	subdw	dxax, sectionPos			;dxax = relative bottom
	stc
	LONG js	done
	div	ds:MBH_pageSize.XYS_height		;ax = last page visible
	xchg	ax, cx					;ax = first, cx = last
	sub	cx, ax
	inc	cx					;cx = page count
	mov	dx, ds:[di].SAE_numPages
	sub	dx, ax
	cmp	cx, dx
	jbe	20$
	mov	cx, dx
20$:

	; ax = first page to draw, cx = # pages, ds:di = SectionArrayElement

drawLoop:
	push	ax, cx, di

	; determine the correct master page

	push	ax
	clr	dx
	div	ds:[di].SAE_numMasterPages		;dx = master page
	mov	bx, dx
	shl	bx
	mov	ax, ds:[di][bx].SAE_masterPages
	mov	bx, vmfile
	call	VMVMBlockToMemBlock
	mov_tr	cx, ax					;save master page block
	pop	ax

	; translate the gstate to the correct place

	push	ax					;save page num
	mov	si, di					;dssi = section array el
	mul	ds:MBH_pageSize.XYS_height		;dxax = page pos
	adddw	dxax, sectionPos
	mov	bx, dx					;bxax = pos
	mov	di, ss:[bp]				;di = gstate
	call	ApplyTransY				;translate down
	pop	dx					;dx = page num
	pushdw	bxax

	; draw the page seperator

	test	flags.low, mask DF_PRINT
	LONG jnz noSeperator

	; print the section name and relative page number if desired

	call	StudioGetDGroupES
	test	es:miscSettings, mask SMS_DISPLAY_SECTION_AND_PAGE
	LONG jz	noDisplaySectionName

	push	cx, si, di, bp, ds

	; compute page number (ds:si = section, dx = page number in section)

	push	si, di
	segmov	es, ds					;es = map block
	mov	di, si
	mov	si, offset SectionArray
	call	ChunkArrayPtrToElement			;ax = section number
	call	ChunkArrayElementToPtr			;cx = size
	pop	si, di
	call	GetUserPageNumber			;dx = user page number

	push	dx					;save page number
	push	cx					;save element size
	mov	ax, SECTION_NAME_COLOR
	call	GrSetTextColor
	mov	dx, SECTION_NAME_SIZE
	clr	ax
	mov	cx, SECTION_NAME_FONT
	call	GrSetFont

	pop	cx					;cx = element size
	add	si, size SectionArrayElement
	sub	cx, size SectionArrayElement
	mov	ax, SECTION_NAME_POS_X
	mov	bx, SECTION_NAME_POS_Y
	call	GrDrawText

	segmov	ds, cs
	mov	si, offset sepString
	clr	cx
	call	GrDrawTextAtCP

	pop	ax
	clr	dx				;dxax = page #
	sub	sp, 10
	segmov	es, ss
	mov	bp, sp
	push	di
	mov	di, bp
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii
	segmov	ds, es
	mov	si, di
	pop	di
	call	GrDrawTextAtCP
	add	sp, 10

	pop	cx, si, di, bp, ds
noDisplaySectionName:

	push	cx
	mov	ax, C_BLACK
	call	GrSetLineColor
	clrdw	dxax				;use zero line width for speed
	call	GrSetLineWidth
	clr	ax
	clr	bx
	mov	cx, ds:MBH_pageSize.XYS_width
	dec	cx
	mov	dx, ds:MBH_pageSize.XYS_height
	dec	dx
	call	GrDrawRect
	pop	cx

noSeperator:

	; draw the master page

	push	di, bp
	mov	bx, cx
	mov	si, offset MasterPageBody
	mov	cl, mask DF_PRINT
	mov	bp, di
	mov	ax, MSG_VIS_DRAW
	clr	di
	call	ObjMessage
	pop	di, bp

	popdw	bxax
	negdw	bxax
	call	ApplyTransY

	pop	ax, cx, di
	inc	ax
	dec	cx
	LONG jnz drawLoop

next:
	mov	ax, ds:[di].SAE_numPages
	mul	ds:MBH_pageSize.XYS_height		;dxax = section height
	adddw	sectionPos, dxax
	cmpdw	sectionPos, bounds.RD_bottom, ax	;carry clear if "jae"
	cmc
done:
	.leave
	ret

DrawMasterCallback	endp

SBCS <sepString	char	" - ", 0					>
DBCS <sepString	wchar	" - ", 0					>

DocDrawScroll ends
