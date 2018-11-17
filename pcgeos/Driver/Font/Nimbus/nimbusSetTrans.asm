COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nimbusSetTrans.asm

AUTHOR:		Gene Anderson, May 27, 1990

ROUTINES:
	Name			Description
	----			-----------
	SetTrans		Set transformations for font.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/27/90		Initial revision

DESCRIPTION:
	Assembly version of set_trans.c

	$Id: nimbusSetTrans.asm,v 1.1 97/04/18 11:45:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set transformation, default hints for a font.
CALLED BY:	CalcRoutines()

PASS:		es:di - ptr to CharGenData
		ds - seg addr of outline data.
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetTrans	proc	near
	uses	ax, bx, cx, dx
	.enter

	;
	;/* so ... which coords depend on x or y or both? */
	;
	clr	bl
	tst	es:[di].CGD_matrix.FM_11.WWF_frac
	jz	no_x
	mov	bl, 3
	tst	es:[di].CGD_matrix.FM_21.WWF_frac
	jz	no_x
	mov	bl, 6
no_x:
	tst	es:[di].CGD_matrix.FM_12.WWF_frac
	jz	no_y
	inc	bl
	tst	es:[di].CGD_matrix.FM_22.WWF_frac
	jz	no_y
	inc	bl
no_y:
	clr	bh				;bx <- trans
	;
	;/* trans == 0 says that both X and Y depend only on <y> */
	;/* trans == 4 says that both X and Y depend only on <x> */
	;/* Those two are degenerate ... so quit if you get them */
	;
	;/* leave some bread crumbs for hint processing */
	;
	clr	ax
	mov	es:[di].CGD_x_scl, ax
	mov	es:[di].CGD_y_scl, ax
	mov	si, bx
	clr	bh
	mov	bl, cs:x_scl_vec[si]
	cmp	bl, -1
	je	no_x_scl
	mov	ax, es:[di][bx].WWF_frac
	mov	es:[di].CGD_x_scl, ax
no_x_scl:
	mov	bl, cs:y_scl_vec[si]
	cmp	bl, -1
	je	no_y_scl
	mov	ax, es:[di][bx].WWF_frac
	mov	es:[di].CGD_y_scl, ax
no_y_scl:
	;
	;/* will we be using the reference lines? */
	;
	mov	dx, es:[di].CGD_y_scl		;y <- y_scl
	tst	dx				;if (y_scl)
	jz	noRefLines
	mov	ax, ds:NFH_nimbus.NFH_h_height
	call	Scale2
	mov	es:[di].CGD_reflines[0], ax	;reflines[0] = scale(h_height...
	mov	ax, ds:NFH_nimbus.NFH_ascender
	call	Scale2
	mov	es:[di].CGD_reflines[2], ax	;reflines[1] = scale(ascender...
	mov	ax, ds:NFH_nimbus.NFH_x_height
	call	Scale2
	mov	es:[di].CGD_reflines[4], ax	;reflines[2] = scale(x_height...
	clr	es:[di].CGD_reflines[6], ax	;reflines[3] = 0 (baseline)
	mov	ax, ds:NFH_nimbus.NFH_descender
	call	Scale2
	mov	es:[di].CGD_reflines[8], ax	;reflines[4] = scale(descent...
noRefLines:
	;
	;/* we're ok ... set the function and return OK */
	;
	shl	si, 1
	mov	ax, cs:trans_vec[si]
	mov	es:[di].CGD_trans_fn, ax	;trans_fn = trans_vec[trans];

	.leave
	ret
SetTrans	endp

trans_vec	label	word
	word	offset NullTrans
	word	offset Trans1
	word	offset Trans2
	word	offset Trans3
	word	offset NullTrans
	word	offset Trans5
	word	offset Trans6
	word	offset Trans7
	word	offset Trans8

x_scl_vec	label	byte
	byte	-1				;0
	byte	offset CGD_matrix.FM_12		;1
	byte	-1				;2
	byte	offset CGD_matrix.FM_11		;3
	byte	-1				;4
	byte	offset CGD_matrix.FM_11		;5
	byte	-1				;6
	byte	offset CGD_matrix.FM_12		;7
	byte	-1				;8
y_scl_vec	label	byte
	byte	-1				;0
	byte	offset CGD_matrix.FM_21		;1
	byte	offset CGD_matrix.FM_21		;2
	byte	offset CGD_matrix.FM_22		;3
	byte	-1				;4
	byte	-1				;5
	byte	offset CGD_matrix.FM_22		;6
	byte	-1				;7
	byte	-1				;8


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Scale2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply number and scale result to correct units.
CALLED BY:	UTILITY

PASS:		ax - outline coordinate -- a simple integer
		dx - scale factor -- numerator of 32768-based fraction
RETURN:		ax - result
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	do 16x16 signed multiply and keep all 32 bits of result
	result is in sub_pixels -- numerator of 16-based fraction
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sp	1989		Initial version
	eca	5/27/90		No C-grossness

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Scale2	proc	near
	uses	dx
	.enter

	;SIGNED multiply of the shorts, 32 bit result
	imul	dx
	; add 1024 as a long to effect round to nearest sub_pixel
	add	ax, 1024
	adc	dx, 0
	; long right shift by 3
	ror	dx, 1
	rcr	ax, 1
	ror	dx, 1
	rcr	ax, 1
	ror	dx, 1
	rcr	ax, 1
	; long right shift by 8 (using byte registers)
	mov	al, ah
	mov	ah, dl
	; fortunately <dh> will be zero and result is in <ax>

	.leave
	ret
Scale2	endp
