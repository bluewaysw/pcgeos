COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Common video driver
FILE:		vidcomRegion.asm

ROUTINES:
	Name			Description
	----			-----------
    GLB VidDrawRegion		Draw a filled region with the given drawing
				state
    INT TransRegCoord		Translate a parameterized region coordinate

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	2/16/89		Initial version

DESCRIPTION:
	This file contains output routines common to all video drivers.
	
	$Id: vidcomRegion.asm,v 1.1 97/04/18 11:41:54 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VidDrawRegion

DESCRIPTION:	Draw a filled region with the given drawing state

CALLED BY:	GLOBAL

PASS:
	ax - amount to offset region horiz to get document coords
	bx - amount to offset region vert to get document coords
	dx:cx - segment and offset to region definition
	ds - graphics state structure
	es - Window structure
	si - offset to CommonAttr structure
	ss:bp - coordinate translation paramters in this order:
		ss:bp+0 - AX
		ss:bp+2 - BX
		ss:bp+4 - CX
		ss:bp+6 - DX

RETURN:
	es - Window structure (may have moved)

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/16/89		Initial version
-------------------------------------------------------------------------------@


OP_MOV_AX_AX		=	0c08bh
OP_JMP_SHORT		=	0ebh

VDRGN_toDone:
	jmp	VDRGN_done

	TranslCoord2	ax, TC_ax1, TC_ax2
	TranslCoord2	bx, TC_bx1, TC_bx2
	TranslCoord2	cx, TC_cx1, TC_cx2
	TranslCoord2	dx, TC_dx1, TC_dx2

;---------------------------------

VidDrawRegion	proc	near

ifdef	LOGGING
	mov	cs:[curRegFlags], 0
endif

	mov	cs:[VDRGN_xOffset1],ax		;save offsets
	mov	cs:[VDRGN_xOffset2],ax
	mov	cs:[VDRGN_yOffset],bx

	mov	cs:[TRC_pointer],bp		;save paramter pointer

	; ds:di = region

	mov	bp,ds
	mov	ds,dx

	mov	cs:[d_x1],cx		;save region pointer temporarily
	mov	cs:[d_y1],dx

	mov	di,cx			;ds:di = bounds

	mov	ax,ds:[di].R_left
	mov	bx,ds:[di].R_top
	mov	cx,ds:[di].R_right
	mov	dx,ds:[di].R_bottom
	mov	ds,bp			;ds = GState

	TranslCoord1	ah, TC_ax1, TC_ax2
	TranslCoord1	bh, TC_bx1, TC_bx2
	TranslCoord1	ch, TC_cx1, TC_cx2
	TranslCoord1	dh, TC_dx1, TC_dx2

	mov	di,cs:[VDRGN_xOffset1]
	add	ax,di
	add	cx,di
	mov	di,cs:[VDRGN_yOffset]
	add	bx,di
	add	dx,di

	; do standard setup

	call	RectSetup
ifdef	LOGGING
	pushf
	jnc	noTrivial
	ornf	cs:[curRegFlags], mask RF_TRIVIAL_REJECT_FROM_RECT_SETUP
noTrivial:
	popf
endif
	jc	VDRGN_toDone
	mov	cs:[VDRGN_call],si
	mov	ax,OP_JMP_SHORT or ((VDRGN_checkTrivial-VDRGN_trivial-2) shl 8)
	cmp	si, offset DrawSimpleRect
	jnz	VDRGN_complex
	mov	ax,OP_MOV_AX_AX
VDRGN_complex:
	mov	cs:[VDRGN_trivial],ax

	mov	si,cs:[d_x1]
	add	si,size Rectangle	;skip bounds
	mov	ds,cs:[d_y1]		;ds:si = region

	; pointing at Y value, bx = top for this swath

VDRGN_y:
	lodsw			; get first y coord (top) in bx
	cmp	ax,EOREGREC	; done ?
	jz	VDRGN_done
	TranslCoord1	ah, TC_1, TC_2
	mov	bp, ax
VDRGN_s1	label	word
VDRGN_yOffset	=	VDRGN_s1 + 2
	add	bp, 1234h	; add vertical offset

VDRGN_leftOrEnder:
	lodsw			; get left or line ender
	cmp	ax, EOREGREC	;was it line ender
	jz	VDRGN_eoln	;branch if so
	TranslCoord1	ah, TC_3, TC_4
	mov	cx,ax		;store left in cx temporarily
	lodsw			;get right into ax temporarily
	TranslCoord1	ah, TC_5, TC_6
	xchg	ax, cx		;switch left and right into proper regs
VDRGN_s2	label	word
VDRGN_xOffset1	=	VDRGN_s2 + 1
	add	ax, 1234h	;add horizontal offset to left
VDRGN_s3	label	word
VDRGN_xOffset2	=	VDRGN_s3 + 2
	add	cx, 1234h	;add horizontal offset to right

VDRGN_trivial	label	word
	jmp	short VDRGN_checkTrivial	;selfModified

VDRGN_afterTrivial:
	push	bp

	sub	bp,bx			;bp = # lines
	inc	bp

	push	si

	mov	si,ax			;si = left

	push	bx

	mov	di,cx			;di = right

VDRGN_s4	label	word
VDRGN_call	=	VDRGN_s4 + 1
	mov	ax,1234h
	call	ax
MEM <	ReleaseHugeArray					>
	pop	bx
	pop	si
	pop	bp
	jmp	short VDRGN_leftOrEnder

;----------------------

	;past EOREGREC for line, move to next line

VDRGN_eoln:
	mov	bx,bp			;bx is new top
	inc	bx
	jmp	short VDRGN_y

;----------------------

	;at firstON or EOREGREC, reject line

VDRGN_rejectLine:
	SetBuffer	es, di
	lodsw
	cmp	ax,EOREGREC
	jnz	VDRGN_rejectLine
	jmp	short VDRGN_eoln

;----------------------

	;at end

VDRGN_done label near
	; changed 4/7/93 to make AutoTransfer the default
;CASIO <CasioAutoXferOff	; turn off auto-transfer	>
	pop	es
	pop	ds

NMEM <	cmp	cs:[xorHiddenFlag], 0				>
NMEM <	jz	afterXORRedraw					>
NMEM <	call	ShowXOR						>
NMEM <afterXORRedraw:						>
NMEM <	cmp	cs:[hiddenFlag],1	;was mouse erased	>
NMEM <	jne	VDRGN_noRedraw					>
NMEM <	call	CondShowPtr					>
NMEM <VDRGN_noRedraw:						>
	ret

;----------------------

	; special case of coordinate translation

	TranslCoord2	ax, TC_1, TC_2
	TranslCoord2	ax, TC_3, TC_4
	TranslCoord2	ax, TC_5, TC_6

;----------------------

	;
	; Trivial rejects
	; - if top of rect to draw is below bottom of mask rect then reject 
	;   rest of region
	; - if left of rect to draw is to right of mask right then reject
	;   rest of x1,x2 pairs on this line of region def
	; - if bottom of rect to draw is above top of mask rect then reject
	;   rest of x1,x2 pairs on this line of region def
	; - if right of rect to draw is to left of mask rect left then reject
	;   this rectangle
	;

VDRGN_checkTrivial:
	mov	es,cs:[PSL_saveWindow]

	cmp 	bx, es:W_maskRect.R_bottom
	jg	VDRGN_done

	cmp	ax, es:W_maskRect.R_right
	jg	VDRGN_rejectLine
	
	cmp	bp, es:W_maskRect.R_top
	jb	VDRGN_rejectLine

	SetBuffer	es, di

	jmp	VDRGN_afterTrivial

VidDrawRegion	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TransRegCoord

DESCRIPTION:	Translate a parameterized region coordinate

CALLED BY:	INTERNAL
		VidDrawRegion

PASS:
	ax - coordinate to translate

RETURN:
	ax - translated coordinate

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

TransRegCoord	proc	near

	; Need to be careful here. If we're passed EOREGREC, then we
	; must not access the paramaterized region data, as it could
	; very well not exist.
	;
	cmp	ax, EOREGREC
	je	done
	push	cx

TRC_s1	label	word
TRC_pointer	=	TRC_s1 + 1
	mov	di,1234h

	mov	ch,ah
	mov	cl,4
	shr	ch,cl
	mov	cl,ch
	and	cx,1110b		;bl = 4, 6, 8, a for AX, BX, CX, DX
	add	di,cx

	and	ah,00011111b		;mask off top three
	sub	ax,1000h		;make +/-
	add	ax,ss:[di][-4]

	pop	cx
done:
	ret
TransRegCoord	endp
