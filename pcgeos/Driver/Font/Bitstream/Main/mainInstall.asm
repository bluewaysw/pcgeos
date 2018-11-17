COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainInstall.asm

AUTHOR:		Brian Chin

FUNCTIONS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/6/93		Initial version.

DESCRIPTION:
	This file contains the GEOS Bitstream Font Driver escape
	function handler.

	$Id: mainInstall.asm,v 1.1 97/04/18 11:45:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamInstallInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize for font installation purposes, i.e. bypass
		font manager, etc.

CALLED BY:	BitstreamStrategy

PASS:		bx = font file handle
		dx = font header buffer handle (locked)
		si = size of font header buffer
		ax = BitstreamFontProtocol
		cx = BitstreamFontProcessor

RETURN:		carry clear if successful
		carry set otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We could leave the BitstreamGlobals block locked until
		InstallExit.
		^^^
		We must leave BitstreamGlobals locked as if it moves when
		we re-lock it for each character, internal far pointers in
		the BitstreamGlobals structure will be wrong - brianc 3/14/94

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitstreamInstallInit	proc	far

	uses	ax, bx, cx, dx, si, ds, es, bp

	push	di
	mov	di, FONT_C_CODE_STACK_SPACE
	call	ThreadBorrowStackSpace
	push	di

fontProto	local	BitstreamFontProtocol	push	ax
fontProc	local	BitstreamFontProcessor	push	cx
fontBufSize	local	word			push	si
ufeSpecs	local	UFEStruct
gspecs		local	SpecsType
gbuff		local	BuffType
orusPerEm	local	word

	.enter

	;
	; grab semaphore to exclude normal usage while we do font
	; installation, released in BitstreamInstallExit
	;
	segmov	ds, dgroup, ax
	PSem	ds, bitstreamSem
	mov	ds:[installFlag], TRUE
	;
	; save font file handle for sp_load_char_data
	;
	mov	ds:[installFontFileHandle], bx

	mov	ax, es:[SFFH_ORUsPerEm]	; ax = ORUsPerEm
	xchg	al, ah			; byte-swap
	mov	orusPerEm, ax

if STATIC_GLOBALS
else
	;
	; allocate global variable buffer
	;
	mov	ax, size BitstreamGlobals
	mov	cx, ALLOC_DYNAMIC_LOCK
	mov	bx, handle 0		; owned by driver
	call	MemAllocSetOwner	; bx = handle, ax = segment
	LONG jc	exit			; couldn't allocate memory
	mov	ds:[installGlobalsHandle], bx
	mov	ds:[sp_global_ptr].segment, ax
	mov	ds:[sp_global_ptr].offset, 0
endif

	;
	; allocate character generation buffer for sp_load_char_data
	;
	mov	bx, dx		; bx = font header buffer handle (locked)
	call	MemDerefES
	mov	ax, es:[SFFH_minCharBufSize]
	xchg	al, ah		; byte-swap
	mov	cx, ALLOC_DYNAMIC_LOCK
	mov	bx, handle 0	; owned by driver
	call	MemAllocSetOwner	; bx = handle, ax = segment
	LONG jc	done
	mov	ds:[installCharGenBufferHandle], bx

if PROC_TRUETYPE
	;
	; if PROC_TRUE_TYPE, free memory allocated by malloc
	; in previous non-install usage
	;	ds = dgroup
	;	es = font header
	;
	cmp	ds:[lastFontInstID].BFIID_processor, PROC_TRUE_TYPE
	jne	noRelease
	push	es			; save font header
	call	FreeSaveMalloc			; release previous mallocs
	pop	es			; es = font header
	;
	; must also kill lastFontInstID, so that calls to
	; EnsureGlobalsAndHeader will mismatch lastFontInstID and
	; cause TrueType processor to be reset
	;
	mov	ds:[lastFontInstID].BFIID_fontAttrs.FCA_fontID, -1
noRelease:
endif
if PROC_TYPE1
	;
	; if PROC_TYPE_1, tr_unload_font(font_ptr)
	;
	cmp	ds:[lastFontInstID].BFIID_processor, PROC_TYPE_1
	jne	noT1Free
	mov	ax, ds:[font_ptr].segment
	tst	ax
	jz	noT1Free
	push	es
	push	ax
	push	ds:[font_ptr].offset
	call	tr_unload_font
	mov	ds:[font_ptr].segment, 0
	pop	es
noT1Free:
endif
	;
	; fi_reset(BitstreamFontProtocol charmap_protocol,
	;		BitstreamFontProcessor f_type)
	;	ds = dgroup
	;	es = font header
	;
	push	es			; save font header
	push	fontProto
	push	fontProc
	call	fi_reset
	pop	es			; es:di = font header
	clr	di
if PROC_TRUETYPE
	;
	; if PROC_TRUE_TYPE, tt_load_font(fontHandle)
	;
	cmp	fontProc, PROC_TRUE_TYPE
	jne	notTrueType
	push	es
	clr	ax
	push	ax			; pass 32-bit version of file handle
	push	ds:[installFontFileHandle]
	call	tt_load_font
	pop	es
	tst	ax
	stc					; assume error
	LONG jz	done				; ax = 0 = FALSE, error
notTrueType:
endif
if PROC_TYPE1
	;
	; if PROC_TYPE_1, tr_load_font(&font_ptr)
	;	ds = dgroup
	;
	cmp	fontProc, PROC_TYPE_1
	jne	notType1
	mov	bx, ds:[installFontFileHandle]
	clr	cx, dx
	mov	al, FILE_POS_START
	call	FilePos
	push	ds
	mov	ax, offset font_ptr
	push	ax
	call	tr_load_font
	tst	ax
	stc					; assume error
	LONG jz	done				; ax = 0 = FALSE, error
	;
	; pass font_ptr in gbuff.BT_org
	;
	mov	es, ds:[font_ptr].segment
	mov	di, ds:[font_ptr].offset
notType1:
endif
	;
	; fi_set_specs(UFEStruct *specs)
	;	ds = dgroup
	;	es:di = font buffer
	;
	; gbuff.org = font_buffer
	mov	gbuff.BT_org.segment, es
	mov	gbuff.BT_org.offset, di
	; gbuff.no_bytes = fontbuf_size
	mov	bx, fontBufSize
	mov	gbuff.BT_noBytes.high, 0
	mov	gbuff.BT_noBytes.low, bx
	; gspecs.pfont = &gbuff
	mov	gspecs.ST_pfont.segment, ss
	lea	ax, gbuff
	mov	gspecs.ST_pfont.offset, ax

	mov	ax, orusPerEm		; ax = ORUsPerEm
if PROC_TYPE1
	cmp	fontProc, PROC_TYPE_1
	je	afterMatrix		; Type1 uses Matrix (not WWFixed)
endif
	; gspecs.xxmult = WWFixed (ORUsPerEm)
	mov	({WWFixed}gspecs.ST_xxmult).WWF_int, ax
	mov	({WWFixed}gspecs.ST_xxmult).WWF_frac, 0
	; gspecs.xymult = 0
	movdw	gspecs.ST_xymult, 0
	; gspecs.xoffset = rotation x offset
	movdw	gspecs.ST_xoffset, 0
	; gspecs.yxmult = 0
	movdw	gspecs.ST_yxmult, 0
	; gspecs.yymult = WWFixed (ORUsPerEm)
	mov	({WWFixed}gspecs.ST_yymult).WWF_int, ax
	mov	({WWFixed}gspecs.ST_yymult).WWF_frac, 0
	; gspecs.yoffset = 0
	movdw	gspecs.ST_yoffset, 0
if PROC_TYPE1
afterMatrix:
endif
	; gspecs.flags = MODE_2D
	clr	gspecs.ST_flags.high
	mov	gspecs.ST_flags.low, SOM_2D
	; gspecs.out_info = 0
	clrdw	gspecs.ST_outInfo
	; ufeSpecs.Font.org = font_buffer
	mov	ufeSpecs.UFES_font.BT_org.segment, es
	mov	ufeSpecs.UFES_font.BT_org.offset, di
	; ufeSpecs.Font.no_bytes = fontbuf_size
	mov	ufeSpecs.UFES_font.BT_noBytes.high, 0
	mov	ufeSpecs.UFES_font.BT_noBytes.low, bx
if PROC_TYPE1
;only Type1 uses Matrix
	segmov	es, ss				; es = Matrix segment
	mov	cx, ax				; cx = ORUsPerEm
	; ufeSpecs.Matrix[0] = (real)(WWFixed)ORUsPerEm
	call	FloatWordToFloat
	lea	di, ufeSpecs.UFES_matrix+0*(size BitstreamIEEE64)
	call	FloatGeos80ToIEEE64
	; ufeSpecs.Matrix[1] = 0
	clr	ax
	call	FloatWordToFloat
	lea	di, ufeSpecs.UFES_matrix+1*(size BitstreamIEEE64)
	call	FloatGeos80ToIEEE64
	; ufeSpecs.Matrix[2] = 0
	clr	ax
	call	FloatWordToFloat
	lea	di, ufeSpecs.UFES_matrix+2*(size BitstreamIEEE64)
	call	FloatGeos80ToIEEE64
	; ufeSpecs.Matrix[3] = (real)(WWFixed)ORUsPerEm
	mov	ax, cx
	call	FloatWordToFloat
	lea	di, ufeSpecs.UFES_matrix+3*(size BitstreamIEEE64)
	call	FloatGeos80ToIEEE64
	; ufeSpecs.Matrix[4] = 0
	clr	ax
	call	FloatWordToFloat
	lea	di, ufeSpecs.UFES_matrix+4*(size BitstreamIEEE64)
	call	FloatGeos80ToIEEE64
	; ufeSpecs.Matrix[5] = 0
	clr	ax
	call	FloatWordToFloat
	lea	di, ufeSpecs.UFES_matrix+5*(size BitstreamIEEE64)
	call	FloatGeos80ToIEEE64
endif
	; ufeSpecs.Gen_specs = &gspecs
	lea	ax, gspecs
	mov	ufeSpecs.UFES_genSpecs.segment, ss
	mov	ufeSpecs.UFES_genSpecs.offset, ax
	; fi_set_specs(&ufeSpecs)
	push	ss
	lea	ax, ufeSpecs
	push	ax
	call	fi_set_specs			; ax = TRUE/FALSE
	tst_clc	ax
	jnz	done				; TRUE, carry clear
	stc					; else, indicate error (ax=0)
done:
;must leave locked - brianc 3/14/94
;	mov	bx, ds:[installGlobalsHandle]
;	call	MemUnlock	; (presrves flags)
;EC <	mov	ds:[sp_global_ptr].segment, 0xa000			>
exit:

	.leave

	pop	di
	call	ThreadReturnStackSpace
	pop	di

	ret
BitstreamInstallInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamInstallExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleanup for font installation purposes, i.e. bypass
		font manager, etc.

CALLED BY:	BitstreamStrategy

PASS:		cx = BitstreamFontProcessor

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitstreamInstallExit	proc	far
	uses	ax, bx, cx, dx, ds, es
	.enter

	segmov	ds, dgroup, ax

if PROC_TRUETYPE or PROC_TYPE1
	;
	; if PROC_TRUE_TYPE, free memory allocated with malloc()
	;
if PROC_TRUETYPE
	cmp	cx, PROC_TRUE_TYPE
	jne	noFree
endif
if PROC_TRUETYPE
	cmp	cx, PROC_TYPE_1
	jne	noFree
endif
	call	FreeSaveMalloc
noFree:
endif
	;
	; clear font file handle for sp_load_char_data
	;
	mov	ds:[installFontFileHandle], 0
	;
	; free FIXED character generation buffer
	;
	mov	bx, 0
	xchg	bx, ds:[installCharGenBufferHandle]
	tst	bx
	jz	charGenFreed
	call	MemFree
charGenFreed:
if STATIC_GLOBALS
else
	;
	; free globals buffer
	;
	mov	bx, 0
	xchg	bx, ds:[installGlobalsHandle]
	tst	bx
	jz	globalsFreed
	call	MemFree
	mov	ds:[sp_global_ptr].segment, 0
globalsFreed:
endif
	;
	; release semaphore to allow normal usage
	;
	mov	ds:[installFlag], FALSE
	VSem	ds, bitstreamSem

	.leave
	ret
BitstreamInstallExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamInstallGetCharBBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get bounding box of character for font installation
		purposes, i.e. bypass font manager, etc.

CALLED BY:	BitstreamStrategy

PASS:		cx = character

RETURN:		carry clear if sucessful
			ax, bx, cx, dx = bounding box
			bp:si = char width
		carry set otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitstreamInstallGetCharBBox	proc	far
	uses	ds, es

	push	di
	mov	di, FONT_C_CODE_STACK_SPACE
	call	ThreadBorrowStackSpace
	push	di

character		local	word	push	cx
boundBox		local	BoundBox

	.enter

	segmov	ds, dgroup, ax
;must leave locked - brianc 3/14/94
;	mov	bx, ds:[installGlobalsHandle]
;	call	MemLock
;	mov	ds:[sp_global_ptr].segment, ax
;	mov	ds:[sp_global_ptr].offset, 0

	;
	; Boolean fi_get_char_bbox(void *char_id, BoundBox *boundBox);
	;
	push	ss
	lea	ax, character
	push	ax
	push	ss
	lea	ax, boundBox
	push	ax
	call	fi_get_char_bbox
	tst	ax
	jz	done		; ax=0=FALSE=want carry set
	push	ss
	lea	ax, character
	push	ax
	call	fi_get_char_width	; ax = width
	mov	si, ax
	mov	di, dx
	stc			; want carry clear
	mov	ax, boundBox.BB_xmin.high	; left
	mov	bx, boundBox.BB_ymax.high	; top
	mov	cx, boundBox.BB_xmax.high	; right
	mov	dx, boundBox.BB_ymin.high	; bottom
done:
	cmc

;must leave locked - brianc 3/14/94
;	push	bx
;	mov	bx, ds:[installGlobalsHandle]
;	call	MemUnlock
;	pop	bx
;EC <	mov	ds:[sp_global_ptr].segment, 0xa000			>

	.leave

	pop	bp			; bp = stack space token
	xchg	bp, di			; di = stack token, bp = width.high
	call	ThreadReturnStackSpace	; (preserves flags)
	pop	di

	ret
BitstreamInstallGetCharBBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamInstallGetPairKern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get pair kerning info for font installation
		purposes, i.e. bypass font manager, etc.

CALLED BY:	BitstreamStrategy

PASS:		ax = character 1 (Bitstream direct index)
		dx = character 2 (Bitstream direct index)

RETURN:		dx.ax = pair kerning (or 0 if none)

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/28/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitstreamInstallGetPairKern	proc	far
	uses	ds, es, bp

	push	di
	mov	di, FONT_C_CODE_STACK_SPACE
	call	ThreadBorrowStackSpace
	push	di

	.enter

	push	ax
	segmov	ds, dgroup, ax
;must leave locked - brianc 3/14/94
;	mov	bx, ds:[installGlobalsHandle]
;	call	MemLock
;	mov	ds:[sp_global_ptr].segment, ax
;	mov	ds:[sp_global_ptr].offset, 0
	pop	ax

	;
	; Boolean sp_get_pair_kern(char_index1, char_index2);
	;
	push	ax
	push	dx
	call	sp_get_pair_kern	; dx.ax = WWFixed em units

;must leave locked - brianc 3/14/94
;	mov	bx, ds:[installGlobalsHandle]
;	call	MemUnlock
;EC <	mov	ds:[sp_global_ptr].segment, 0xa000			>

	.leave

	pop	di
	call	ThreadReturnStackSpace	; (preserves flags)
	pop	di

	ret
BitstreamInstallGetPairKern	endp
