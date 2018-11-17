COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainOutline.asm

AUTHOR:		Brian Chin

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
EXT	sp_open_outline		output character
EXT	sp_start_new_char	output character
EXT	sp_start_contour	output character
EXT	sp_curve_to		output character
EXT	sp_line_to		output character
EXT	sp_close_contout	output character
EXT	sp_close_outline	output character

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/12/93	Initial version.

DESCRIPTION:
	This file contains GEOS Bitstream Font Driver routines.

	$Id: mainOutline.asm,v 1.1 97/04/18 11:45:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


	SetGeosConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sp_open_outline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	begin outline output

CALLED BY:	Bitstream C code

PASS:		sp_open_outline(fix31 x_set_width, fix31 y_set_width,
				fix31 xmin, fix31 xmax,
				fix31 ymin, fix31 ymax)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
sp_open_outline	proc	far	x_set_width:WWFixed, y_set_width:WWFixed,
				xmin1:WWFixed, xmax1:WWFixed,
				ymin1:WWFixed, ymax1:WWFixed
ForceRef x_set_width
ForceRef y_set_width

	uses	ds, si, es, di

tMatrix	local	TMatrix

	.enter

	segmov	es, dgroup, ax

	;
	; handle GEN_IN_REGION
	;
	tst	es:[outputInfo].OI_forceRegion
	jz	notForceRegion
	mov	ax, es:[outputInfo].OI_heightX
	add	ax, es:[outputInfo].OI_scriptX
	add	ax, es:[outputInfo].OI_penPos.P_x
	mov	es:[outputInfo].OI_charXOffset, ax
	movwbf	axbh, es:[outputInfo].OI_heightY
	rndwbf	axbh
	add	ax, es:[outputInfo].OI_scriptY
	add	ax, es:[outputInfo].OI_penPos.P_y
	mov	es:[outputInfo].OI_charYOffset, ax
	jmp	done

notForceRegion:
	mov	di, es:[outputInfo].OI_gstateHan
	;
	; save current gstate so we can mess with transformation
	;
	test	es:[outputInfo].OI_pathFlags, mask FGPF_SAVE_STATE
	jz	noSaveState
	call	GrSaveState
noSaveState:
	;
	; Emit a comment with the width and bounding box information.
	; We pass it in the order of the Postscript setcachedevice
	; command arguments: width(x),widht(y),ll(x),ll(y),ur(x),ur(y)
	;
	movwwf	dxax, ymax1
	rndwwf	dxax
	push	dx
	movwwf	dxax, xmax1
	rndwwf	dxax
	push	dx
	movwwf	dxax, ymin1
	rndwwf	dxax
	push	dx
	movwwf	dxax, xmin1
	rndwwf	dxax
	push	dx				; bounds
	clr	cx
	push	cx				; width(y)
	movwwf	dxax, x_set_width
	rndwwf	dxax
	push	dx				; width(x)
	mov	cx, (size word)*6
	mov	si, sp
	segmov	ds, ss				; ds:si = data on stack
	call	GrComment
	add	sp, cx				; restore stack
	;
	; here's the sequence of operation we should need to perform
	; on an arbitrary point in the font outline
	;	1) Transform by font TransMatrix
	;	2) Flip on X-axis (scale by -1 in Y)
	;	3) Translate by font height
	;	4) Translate by current position
	;	5) Transform by current matrix
	;
	; Remember that since the order of matrix multiplication is
	; extremely important, we must perform these transformations
	; in reverse order. Step 5 is, of course, already in the GState.
	; Step 1 is passed to fi_set_specs.
	;
	call	GrGetCurPos			; (ax, bx) <- current position
	mov	dx, ax				; dx.cx <- x translation
	clr	ax, cx				; bx.ax <- y translation
	call	GrApplyTranslation
	;
	; we only perform steps 2 & 3 if the POSTSCRIPT flag wasn't passed
	;
	test	es:[outputInfo].OI_pathFlags, mask FGPF_POSTSCRIPT
	jnz	notPostscript
	;
	; we need the font height in terms of the graphics system space,
	; not the outline data space, so we transform it first
	;
	call	GrGetFont			; dx.ah <- pointsize
	mov	ch, ah
	clr	cl				; dx.cx <- ptsize
	clr	ax				; bx.ax <- grid size
	mov	bx, es:[outputInfo].OI_fontMetrics.BOEM_ORUsPerEm
	call	GrUDivWWFixed			; dx.cx <- ptsize / grid
			; account for height of font by adding accent & ascent
	mov	bx, es:[outputInfo].OI_fontMetrics.BOEM_accent
	add	bx, es:[outputInfo].OI_fontMetrics.BOEM_ascent
	clr	ax				; bx.ax <- Y translation
	call	GrMulWWFixed
	movdw	bxax, dxcx			; bx.ax <- y translation
	clrdw	dxcx				; dx.cx <- x translation
	call	GrApplyTranslation
	;
	mov	dx, 1				; x transform is 1.0 (no change)
	mov	bx, dx
	neg	bx				; y transform is -1.0 (flip)
	clr	cx, ax				;	fractional parts zero
	call	GrApplyScale	
notPostscript:
	;
	; apply font matrix
	;
	mov	bx, es:[outputInfo].OI_fontMetrics.BOEM_ORUsPerEm
	clr	ax
	movwwf	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11
	call	GrUDivWWFixed
	movwwf	tMatrix.TM_11, dxcx
	movwwf	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_12
	call	GrUDivWWFixed
	movwwf	tMatrix.TM_12, dxcx
	movwwf	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22
	call	GrUDivWWFixed
	movwwf	tMatrix.TM_22, dxcx
	movwwf	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_21
	call	GrUDivWWFixed
	movwwf	tMatrix.TM_21, dxcx
	movdw	tMatrix.TM_31.DWF_int, 0
	mov	tMatrix.TM_31.DWF_frac, 0
	mov	ax, es:[outputInfo].OI_fontInstance.BFIID_scriptY
	cwd
	mov	tMatrix.TM_32.DWF_int.high, dx
	mov	tMatrix.TM_32.DWF_int.low, ax
	mov	tMatrix.TM_32.DWF_frac, 0
	movdw	tMatrix.TM_xInv.DDF_int, 0
	movdw	tMatrix.TM_xInv.DDF_frac, 0
	movdw	tMatrix.TM_yInv.DDF_int, 0
	movdw	tMatrix.TM_yInv.DDF_frac, 0
	mov	tMatrix.TM_flags, 0
	segmov	ds, ss
	lea	si, tMatrix
	call	GrApplyTransform
done:
	.leave
	ret
sp_open_outline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sp_start_new_char
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	outline output

CALLED BY:	Bitstream C code

PASS:		sp_start_new_char()

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
sp_start_new_char	proc	far

;	uses	ds, es, si, di
;
;	.enter
;
;	segmov	es, dgroup, ax
;	mov	di, es:[outputInfo].OI_gstateHan
;
;	.leave
	ret
sp_start_new_char	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sp_start_contour
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	outline output

CALLED BY:	Bitstream C code

PASS:		sp_start_contour(fix31 x, fix31 y, boolean outside)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
sp_start_contour	proc	far	x1:WWFixed, y1:WWFixed,
					outside:BooleanWord
ForceRef outside

	uses	ds, es, si, di

	.enter

	segmov	ds, dgroup, ax
	;
	; handle GEN_IN_REGION
	;
	tst	ds:[outputInfo].OI_forceRegion
	jz	notForceRegion
	mov	es, ds:[outputInfo].OI_regionSeg
	mov	cx, ds:[outputInfo].OI_charXOffset
	clr	ax
	addwwf	cxax, x1
	rndwwf	cxax
	mov	dx, ds:[outputInfo].OI_charYOffset
	clr	bx
	addwwf	dxbx, y1
	rndwwf	dxbx
	call	GrRegionPathMovePen
	mov	ds:[outputInfo].OI_regionSeg, es
	jmp	short done

notForceRegion:
	mov	di, ds:[outputInfo].OI_gstateHan

	movwwf	axcx, x1
	rndwwf	axcx
	movwwf	bxdx, y1
	rndwwf	bxdx
	call	GrMoveTo

done:
	.leave
	ret
sp_start_contour	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sp_curve_to
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	outline output

CALLED BY:	Bitstream C code

PASS:		sp_curve_to(fix31 x1, fix31 y1,
				fix31 x2, fix31 y2,
				fix31 x3, fix31 y3)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
sp_curve_to	proc	far	xCurve:WWFixed, yCurve:WWFixed,
				x2:WWFixed, y2:WWFixed,
				x3:WWFixed, y3:WWFixed

	uses	ds, es, si, di

regBez	local	RegionBezier

	.enter

	segmov	ds, dgroup, ax
	;
	; handle GEN_IN_REGION
	;
	tst	ds:[outputInfo].OI_forceRegion
	LONG jz	notForceRegion
	mov	es, ds:[outputInfo].OI_regionSeg
	mov	ax, ds:[outputInfo].OI_charXOffset
	mov	dx, ax
	clr	bx
	addwwf	axbx, xCurve
	rndwwf	axbx
	mov	regBez.RB_p1.P_x, ax
	mov	ax, dx
	clr	bx
	addwwf	axbx, x2
	rndwwf	axbx
	mov	regBez.RB_p2.P_x, ax
	mov	ax, dx
	clr	bx
	addwwf	axbx, x3
	rndwwf	axbx
	mov	regBez.RB_p3.P_x, ax
	mov	ax, ds:[outputInfo].OI_charYOffset
	mov	dx, ax
	clr	bx
	addwwf	axbx, yCurve
	rndwwf	axbx
	mov	regBez.RB_p1.P_y, ax
	mov	ax, dx
	clr	bx
	addwwf	axbx, y2
	rndwwf	axbx
	mov	regBez.RB_p2.P_y, ax
	mov	ax, dx
	clr	bx
	addwwf	axbx, y3
	rndwwf	axbx
	mov	regBez.RB_p3.P_y, ax
	segmov	ds, ss
	lea	di, regBez
	clr	bp
	mov	cx, REC_BEZIER_STACK
	call	GrRegionPathAddBezierAtCP
	mov	ds:[outputInfo].OI_regionSeg, es
	jmp	done

notForceRegion:
	mov	di, ds:[outputInfo].OI_gstateHan

	movwwf	bxax, y3
	rndwwf	bxax
	push	bx
	movwwf	bxax, x3
	rndwwf	bxax
	push	bx
	movwwf	bxax, y2
	rndwwf	bxax
	push	bx
	movwwf	bxax, x2
	rndwwf	bxax
	push	bx
	movwwf	bxax, yCurve
	rndwwf	bxax
	push	bx
	movwwf	bxax, xCurve
	rndwwf	bxax
	push	bx
	segmov	ds, ss				; ds:si = three points
	mov	si, sp
	call	GrDrawCurveTo
	add	sp, 6*(size word)

done:
	.leave
	ret
sp_curve_to	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sp_line_to
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	outline output

CALLED BY:	Bitstream C code

PASS:		sp_line_to(fix31 x, fix31 y)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
sp_line_to	proc	far	xLine:WWFixed, yLine:WWFixed

	uses	ds, es, di

	.enter

	segmov	ds, dgroup, ax
	;
	; handle GEN_IN_REGION
	;
	tst	ds:[outputInfo].OI_forceRegion
	jz	notForceRegion
	mov	es, ds:[outputInfo].OI_regionSeg
	mov	cx, ds:[outputInfo].OI_charXOffset
	clr	ax
	addwwf	cxax, xLine
	rndwwf	cxax
	mov	dx, ds:[outputInfo].OI_charYOffset
	clr	bx
	addwwf	dxbx, yLine
	rndwwf	dxbx
	call	GrRegionPathAddLineAtCP
	mov	ds:[outputInfo].OI_regionSeg, es
	jmp	short done

notForceRegion:
	mov	di, ds:[outputInfo].OI_gstateHan

	movwwf	cxax, xLine
	rndwwf	cxax
	movwwf	dxbx, yLine
	rndwwf	dxbx
	call	GrDrawLineTo

done:
	.leave
	ret
sp_line_to	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sp_close_contour
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	outline output

CALLED BY:	Bitstream C code

PASS:		sp_close_contour()

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
sp_close_contour	proc	far

;	uses	es, di
;
;	.enter
;
;	segmov	es, dgroup, ax
;	mov	di, es:[outputInfo].OI_gstateHan
;
;	.leave
	ret
sp_close_contour	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sp_close_outline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	outline output

CALLED BY:	Bitstream C code

PASS:		sp_close_outline()

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
sp_close_outline	proc	far

	uses	es, di

	.enter

	segmov	es, dgroup, ax
	;
	; handle GEN_IN_REGION
	;
	tst	es:[outputInfo].OI_forceRegion
	jnz	noRestoreState
	;
	; restore GState if needed
	;
	test	es:[outputInfo].OI_pathFlags, mask FGPF_SAVE_STATE
	jz	noRestoreState
	mov	di, es:[outputInfo].OI_gstateHan
	call	GrRestoreState
noRestoreState:

	.leave
	ret
sp_close_outline	endp

	SetDefaultConvention
