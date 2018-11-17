COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem cmyk module	
FILE:		cmykCluster.asm

AUTHOR:		Jim DeFrisco, Feb 27, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT ClusterMux		A multiplexor for the cluster dither
				routines, in mono
    INT DrawOptClustered	Draw a rectangle with draw mode GR_COPY and
				all bits in the draw mask set
    INT ClusterRightMask
    INT ClusterLeftMask
    INT DrawOptClusteredThin	Same as DrawOptClustered, optimized for
				one-word wide rect
    INT DrawSpecialClustered	Draw a rectangle with a special draw mask
				or draw mode clipping left and right
    INT SpecialRightMask	Same as ClusterMask routines, above, except
				these do	 draw masks and draw modes.
    INT SpecialMidMask		Same as ClusterMask routines, above, except
				these do	 draw masks and draw modes.
    INT SpecialLeftMask		Same as ClusterMask routines, above, except
				these do	 draw masks and draw modes.
    INT DrawSpecialClusteredThin DrawSpecialClustered, optimized for
				one-word wide rect
    INT ClusterDoMode		front end for modeRoutines
    INT ClusterCharMux		ClusterChar routine Distributor
    INT Cluster1In1Out		Low level routine to draw a character when
				the source is X bytes wide and the
				destination is Y bytes wide, the drawing
				mode in GR_COPY and the character is
				entirely visible.
    INT WriteChar1Byte		Low level routine to draw a character when
				the source is X bytes wide and the
				destination is Y bytes wide, the drawing
				mode in GR_COPY and the character is
				entirely visible.
    INT ModeRoutines		Execute draw mode specific action

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/27/92		Initial revision


DESCRIPTION:
		basic rectangle and text routines for CMYK module
		

	$Id: cmykCluster.asm,v 1.1 97/04/18 11:43:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClusterMux
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A multiplexor for the cluster dither routines, in mono

CALLED BY:	INTERNAL
		DrawSimpleRect
PASS:		see routines, below
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClusterMux	proc	near
		mov	ax, cs:[rectRoutine]		; see what we were
		cmp	ax, DRAW_SPECIAL_RECT
		LONG je	DrawSpecialClustered
		REAL_FALL_THRU DrawOptClustered
ClusterMux	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOptClustered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with draw mode GR_COPY and all bits in the
		draw mask set
CALLED BY:	INTERNAL
		ClusterMux
PASS:	dx - number of words covered by rectangle + 1
	zero flag - set if rect is one word wide
	cx - ditherMatrix index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 16) * 2
	bx - (right x position MOD 16) * 2
RETURN:	nothing	
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawOptClustered	proc	near

		; check for a one-word wide rectangle
	
		tst	dx				; if no middle words...
		LONG jz	DrawOptClusteredThin

		; setup masks

		mov	ax,cs:[si][leftMaskTable]	; get left mask
		mov	cs:[clLeftMask],ax
		mov	ax,cs:[bx][rightMaskTable]	; get right mask
		mov	cs:[clRightMask],ax

		InitDitherIndex				; setup bx and si
		jmp	blastStart


		; loop for each scan line of the rectangle
DOC_loop:
		NextDitherScan				; update si
		NextScan di
		tst	cs:[bm_scansNext]	; if off end of bitmap 
		LONG js	DOC_done		;  then bail		
blastStart:
		push	di				; save pointer

		; handle left word 

		call	ClusterLeftMask			; mask/write left word
		add	di, 2				; bump to next word

		; store middle words

		mov	cx, dx				; # of words affected
		dec	cx				; one less
		jcxz	doRightSide	
midLoop:
		NextDitherWord			; ax = word of ditherMatrix
		mov	es:[di], ax		; store yellow
		mov	bx, cs:[bm_bpMask]	; onto cyan
		mov	ax, cs:[cyanWord]
		mov	es:[di][bx], ax
		shl	bx, 1			; onto magenta
		mov	ax, cs:[magentaWord]
		mov	es:[di][bx], ax
		add	bx, cs:[bm_bpMask]	; onto black
		mov	ax, cs:[blackWord]
		mov	es:[di][bx], ax
		add	di, 2
		loop	midLoop

		; handle right word 
doRightSide:
		call	ClusterRightMask
		pop	di				; restore start of scan
		dec	bp				; loop to do all lines
		LONG jnz DOC_loop
DOC_done:
		ret

DrawOptClustered	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClusterMasking routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	CMYK drawing routines (copy mode)
		
PASS:		NextDitherWord invoked, so new dither works are setup in
		ax(yellow) and blackWord, cyanWord, magentaWord
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClusterRightMask proc	near

		push	dx
clRightMask	equ (this word) + 1
		mov	dx, 1234h		; set up mask
		jmp	clMaskCommon
ClusterRightMask endp

ClusterLeftMask proc	near

		push	dx
clLeftMask	equ (this word) + 1
		mov	dx, 1234h		; set up mask
clMaskCommon	label	near
		NextDitherWord
		and	ax, dx
		not	dx			; take inverse mask
		mov	cx, es:[di]
		and	cx, dx
		not	dx
		or	ax, cx
		mov	es:[di], ax
		mov	bx, cs:[bm_bpMask]	; go to cyan plane
		mov	ax, cs:[cyanWord]
		and	ax, dx
		not	dx			; take inverse mask
		mov	cx, es:[di][bx]
		and	cx, dx
		not	dx
		or	ax, cx
		mov	es:[di][bx], ax
		shl	bx, 1			; go to magenta plane
		mov	ax, cs:[magentaWord]
		and	ax, dx
		not	dx			; take inverse mask
		mov	cx, es:[di][bx]
		and	cx, dx
		not	dx
		or	ax, cx
		mov	es:[di][bx], ax
		add	bx, cs:[bm_bpMask]	; go to magenta plane
		mov	ax, cs:[blackWord]
		and	ax, dx
		not	dx			; take inverse mask
		mov	cx, es:[di][bx]
		and	cx, dx
		not	dx
		or	ax, cx
		mov	es:[di][bx], ax
		pop	dx
		ret
ClusterLeftMask endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOptClusteredThin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as DrawOptClustered, optimized for one-word wide rect

CALLED BY:	DrawOptClustered
PASS:		see above
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawOptClusteredThin proc	near

		; compute mask

		mov	ax, cs:[si][leftMaskTable]	; get left mask
		and	ax, cs:[bx][rightMaskTable]	; combine w/ right mask
		mov	cs:[clLeftMask], ax

		InitDitherIndex				; setup bx and si
		jmp	blastStart

DOCT_loop:
		NextDitherScan				; update si
		NextScan di
		tst	cs:[bm_scansNext]	; if off end of bitmap 
		js	DOCT_done		;  then bail		
blastStart:
		call	ClusterLeftMask			; store new dithers
		dec	bp
		jnz	DOCT_loop
DOCT_done:
		ret
DrawOptClusteredThin endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpecialClustered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with a special draw mask or draw mode clipping
		left and right

CALLED BY:	INTERNAL
		ClusterMux

PASS:
	dx - number of words covered by rectangle + 1
	zero flag - set if rect is one word wide
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 16) * 2
	bx - (right x position MOD 16) * 2

RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawSpecialClustered	proc		near

	dec	dx				; if no middle words, use 
	LONG js	DrawSpecialClusteredThin	;  short routine
	mov	cs:[DSC_middleCount], dx	; save middle count

	; compute masks

	mov	ax, cs:[si][leftMaskTable]	;get mask
	mov	cs:[sclLeftMask], ax
	mov	ax, cs:[bx][rightMaskTable]	;get mask
	mov	cs:[sclRightMask], ax

	InitDitherIndex				; init bx and si
	jmp	blastSpecialStart

DSC_loop:
	inc	cx
	NextDitherScan				; update si
	NextScan	di
	tst	cs:[bm_scansNext]	; if off end of bitmap 
	LONG js	DSC_done		;  then bail		

blastSpecialStart:
	and	cx, 7				; isolate low three bits
	push	cx				; save mask index
	mov	bx, cx				; bx = mask index
	mov	bl, {byte} cs:[bx][maskBuffer]	; get draw mask byte
	mov	bh, bl				;  make it a word
	mov	cs:[CDM_mask], bx		; save mask
	push	di

	; do left word

	call	SpecialLeftMask
	add	di, 2

	; draw middle words

DSC_middleCount	equ	(this word) + 1
	mov	cx, 1234h			; # words to store -- modified
	jcxz	DSC_right
DSC_midLoop:
	push	cx
	call	SpecialMidMask
	add	di, 2
	pop	cx
	loop	DSC_midLoop

	; handle right word specially
DSC_right:
	call	SpecialRightMask

	pop	di
	pop	cx				; restore mask index
	dec	bp				; loop to do all lines
	LONG jnz DSC_loop
DSC_done:
	ret

DrawSpecialClustered endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpecialMask routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as ClusterMask routines, above, except these do 	
		draw masks and draw modes.

CALLED BY:	SpecialCluster routines
PASS:		NextDitherWord invoked
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpecialRightMask proc	near

		push	dx
sclRightMask	equ (this word) + 1
		mov	dx, 1234h		; set up mask
		jmp	sclMaskCommon
SpecialRightMask endp

SpecialMidMask proc	near

		push	dx
		mov	dx, 0xffff		; set up mask
		jmp	sclMaskCommon
SpecialMidMask endp

SpecialLeftMask proc	near

		push	dx
sclLeftMask	equ (this word) + 1
		mov	dx, 1234h		; set up mask
sclMaskCommon	label	near
		NextDitherWord
		mov	cx, es:[di]
		call	ClusterDoMode
		mov	es:[di], ax
		mov	bx, cs:[bm_bpMask]	; go to cyan plane
		mov	ax, cs:[cyanWord]
		mov	cx, es:[di][bx]
		call	ClusterDoMode
		mov	es:[di][bx], ax
		shl	bx, 1			; go to magenta plane
		mov	ax, cs:[magentaWord]
		mov	cx, es:[di][bx]
		call	ClusterDoMode
		mov	es:[di][bx], ax
		add	bx, cs:[bm_bpMask]	; go to magenta plane
		mov	ax, cs:[blackWord]
		mov	cx, es:[di][bx]
		call	ClusterDoMode
		mov	es:[di][bx], ax
		pop	dx
		ret
SpecialLeftMask endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpecialClusteredThin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DrawSpecialClustered, optimized for one-word wide rect

CALLED BY:	DrawSpecialClustered
PASS:		see above
RETURN:		see above
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSpecialClusteredThin proc	near

	; compute left masks

	mov	ax, cs:[si][leftMaskTable]	; get left mask
	and	ax, cs:[bx][rightMaskTable]	; combine right mask
	mov	cs:[sclLeftMask], ax		; self-modify the code

	InitDitherIndex				; init bx and si
	jmp	blastSpecialStart

DSCT_loop:
	inc	cx
	NextDitherScan				; update si
	NextScan	di
	tst	cs:[bm_scansNext]	; if off end of bitmap 
	js	DSCT_done		;  then bail		

blastSpecialStart:
	and	cx, 7				; isolate low three bits
	push	cx				; save mask index
	mov	bx, cx				; bx = mask index
	mov	bl, {byte} cs:[bx][maskBuffer]	; get draw mask byte
	mov	bh, bl				;  make it a word
	mov	cs:[CDM_mask], bx		; save mask
	call	SpecialLeftMask			; mask/write word
	pop	cx				; restore mask index
	dec	bp				; loop to do all lines
	jnz	DSCT_loop
DSCT_done:
	ret
DrawSpecialClusteredThin endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClusterDoMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	front end for modeRoutines

CALLED BY:	DrawSpecialClustered
PASS:		ax	- ditherMatrix data
		dx	- mask for left/right/middle
		cx	- screen content
RETURN:		
DESTROYED:	ax,dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClusterDoMode	proc	near
		uses	si, dx
		.enter

CDM_mask	equ	(this word) + 2
		and	dx, 1234h
		mov	si, ax			; load data from ditherMatrix
		mov	ax, cx			; load screen content
		call	cs:[modeRoutine]	; apply mode
		.leave
		ret
ClusterDoMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClusterCharMux
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ClusterChar routine Distributor

CALLED BY:	VidPutString...
PASS:		see below
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		set up some dither stuff, and
		just call the right routine

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClusterCharMux	proc	near

		; init pointers to ditherMatrix

		mov	ax, cs:[clusterCharTable][bp]
		InitDitherIndex	bp
		jmp	ax
ClusterCharMux	endp

clusterCharTable label nptr
	dw	offset cmykcode:Cluster1In1Out	;load 1, draw 1
	dw	offset cmykcode:Cluster1In2Out	;load 1, draw 2
	dw	offset cmykcode:NullRoutine	;load 1, draw 3
	dw	offset cmykcode:NullRoutine	;load 1, draw 4

	dw	offset cmykcode:NullRoutine	;load 2, draw 1
	dw	offset cmykcode:Cluster2In2Out	;load 2, draw 2
	dw	offset cmykcode:Cluster2In3Out	;load 2, draw 3
	dw	offset cmykcode:NullRoutine	;load 2, draw 4

	dw	offset cmykcode:NullRoutine	;load 3, draw 1
	dw	offset cmykcode:NullRoutine	;load 3, draw 2
	dw	offset cmykcode:Cluster3In3Out	;load 3, draw 3
	dw	offset cmykcode:Cluster3In4Out	;load 3, draw 4

	dw	offset cmykcode:NullRoutine	;load 4, draw 1
	dw	offset cmykcode:NullRoutine	;load 4, draw 2
	dw	offset cmykcode:NullRoutine	;load 4, draw 3
	dw	offset cmykcode:Cluster4In4Out	;load 4, draw 4


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClusterXinYOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low level routine to draw a character when the source is
		X bytes wide and the destination is Y bytes wide, the drawing
		mode in GR_COPY and the character is entirely visible.

CALLED BY:	INTERNAL
		DrawVisibleChar

PASS: 		ds:si - character data
		es:di - screen position
		bx - pattern index
		cl - shift count
		ch - number of lines to draw
		on stack - ax
RETURN:		ax - popped off stack

DESTROYED:
	ch, dx, bp, si, di

REGISTER/STACK USAGE:
	Cluster1In1Out:
		al - mask
		ah - NOT mask
		dl - temporary
	Cluster1In2Out, Cluster2In2Out:
		ax - mask
		bp - NOT mask
		dx - temporary

PSEUDO CODE/STRATEGY:
	dest = (mask AND pattern) or (NOT mask AND screen)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

C1I1OC_loop:
	NextDitherScan bp
	NextScan di
	tst	cs:[bm_scansNext]	; if off end of bitmap
	js	C1I1O_done

Cluster1In1Out	proc		near
	lodsb				; al = mask
	ror	al, cl			; al = mask shifted correctly
	call	WriteChar1Byte		; just writing one byte of data
	dec	ch
	jnz	C1I1OC_loop
C1I1O_done label near
	pop	ax
	jmp	PSL_afterDraw

Cluster1In1Out	endp

WriteChar1Byte	proc	near
	push	cx, si			; save loop/shift count, char data ptr
	mov	ah, al
	not	ah			; ah = NOT mask
	mov	cx, ax			; save masks
	and	al, cs:ditherMatrix[bp]	; al = mask AND yellow
	and	ah, es:[di]		; ah = screen AND mask
	or	al, ah			; al = data to store
	mov	es:[di], al
	mov	ax, cx			; restore masks
	mov	si, cs:[cyanBase]	; onto cyan
	mov	bl, cs:[cyanIndex]	; get index too
	mov	dx, cs:[bm_bpMask]	; #bytes per data plane
	clr	bh
	and	al, cs:cyanDither[bx][si]
	xchg	bx, dx			; index to cyan plane, save cyanIndex
	and	ah, es:[bx][di]
	or	al, ah
	mov	es:[bx][di], al		; store cyan byte
	xchg	bx, dx			; restore regs
	shl	dx, 1			; index to magenta next time
	mov	ax, cx			; init masks again
	and	al, cs:magentaDither[bx][si]
	xchg	bx, dx
	and	ah, es:[bx][di]
	or	al, ah
	mov	es:[bx][di], al		; write magenta byte
	xchg	dx, bx
	mov	si, cs:[blackBase]
	mov	bl, cs:[blackIndex]
	add	dx, cs:[bm_bpMask]
	mov	ax, cx			; re-init masks
	and	al, cs:[bx][si]		; apply black dither
	mov	bx, dx			; restore pointer to black plane
	and	ah, es:[bx][di]
	or	al, ah
	mov	es:[bx][di], al		; store black byte
	pop	cx, si			; restore loop/shift counts
	BumpDitherIndex
	ret
WriteChar1Byte	endp

;-------------------------------

C1I2OC_loop:
	NextDitherScan bp
	NextScan di
	tst	cs:[bm_scansNext]	; if off end of bitmap
	js	C1I2O_done

Cluster1In2Out	proc		near
	lodsb				; ax = char data
	clr	ah
	ror	ax, cl			; ax = shifted char data
	call	WriteChar1Word
	dec	ch
	jnz	C1I2OC_loop
C1I2O_done label near
	pop	ax
	jmp	PSL_afterDraw

Cluster1In2Out	endp

WriteChar1Word	proc	near
	push	cx			; save shift/loop counts
	mov	dx, ax			; 
	NextDitherWord bp		; load up next dither words
	and	ax, dx			; apply mask to yellow word
	mov	cx, es:[di]		; get yellow plane data
	not	dx
	and	cx, dx			; clear out bits to fill
	not	dx
	or	ax, cx
	mov	es:[di], ax		; update yellow plane
	mov	bx, cs:[bm_bpMask]	; bump to cyan plane
	mov	ax, cs:[cyanWord]	; get next dither word
	and	ax, dx			; isolate bits of interest
	mov	cx, es:[bx][di]		; grab cyan plane data
	not	dx
	and	cx, dx			; clear out byts
	not	dx
	or	ax, cx
	mov	es:[bx][di], ax		; update cyan plane
	shl	bx, 1			; onto magenta plane
	mov	ax, cs:[magentaWord]
	and	ax, dx			; isolate bits of interest
	mov	cx, es:[bx][di]
	not	dx
	and	cx, dx
	not	dx
	or	ax, cx
	mov	es:[bx][di], ax		; update magenta plane
	add	bx, cs:[bm_bpMask]	; finally, onto black plane
	mov	ax, cs:[blackWord]	; get black dither
	and	ax, dx
	mov	cx, es:[bx][di]
	not	dx
	and	cx, dx
	or	ax, cx
	mov	es:[bx][di], ax		; update black plane
	pop	cx
	ret
WriteChar1Word	endp
;-------------------------------

C2I2OC_loop:
	NextDitherScan bp
	NextScan di
	tst	cs:[bm_scansNext]	; if off end of bitmap
	js	C2I2O_done

Cluster2In2Out	proc		near
	lodsw				; ax = character data
	ror	ax, cl			; ax = shifted char data
	call	WriteChar1Word		; write out the data
	dec	ch
	jnz	C2I2OC_loop
C2I2O_done label near
	pop	ax
	jmp	PSL_afterDraw

Cluster2In2Out	endp

;-------------------------------

C2I3OC_loop:
	NextDitherScan bp
	NextScan di
	tst	cs:[bm_scansNext]	; if off end of bitmap
	js	C2I3O_done

Cluster2In3Out	proc		near
	lodsb				; al = char data
	clr	ah
	ror	ax, cl			; ax = shifted char data
	push	ax			; save overflow bits (in ah)
	call	WriteChar1Byte		; write out the first one
	inc	di			; on to next byte in output buffer
	pop	dx			; restore overflow (now in dh)
	lodsb				; grab next char data byte
	clr	ah
	ror	ax, cl			; ax = shifted char data
	or	al, dh			; ax = complete char data (with extras)
	call	WriteChar1Word		; write out the data
	dec	di
	dec	ch
	jnz	C2I3OC_loop
C2I3O_done label near
	pop	ax
	jmp	PSL_afterDraw

Cluster2In3Out	endp

;-------------------------------

C3I3OC_loop:
	NextDitherScan bp
	NextScan di
	tst	cs:[bm_scansNext]	; if off end of bitmap
	js	C3I3O_done

Cluster3In3Out	proc		near
	lodsb				; al = char data
	clr	ah
	ror	ax, cl			; ax = shifted char data
	push	ax			; save shift out bits
	call	WriteChar1Byte		; write the first byte
	inc	di			; onto next buffer byte
	pop	dx			; restore overflow bits (in dh)
	lodsw				; ax = rest of char data
	ror	ax, cl			; ax = shifted char data
	or	al, dh			; combine extra bits 
	call	WriteChar1Word		; write out data
	dec	di
	dec	ch
	jnz	C3I3OC_loop
C3I3O_done label near
	pop	ax
	jmp	PSL_afterDraw

Cluster3In3Out	endp

;-------------------------------

C3I4OC_loop:
	NextDitherScan bp
	NextScan di
	tst	cs:[bm_scansNext]	; if off end of bitmap
	LONG js	C3I4O_done

Cluster3In4Out	proc		near
	lodsb				; al = char data
	clr	ah
	ror	ax, cl			; ax = shifted char data
	push	ax			; save shift out bits
	call	WriteChar1Byte		; write out first byte of data
	inc	di			;  and next output byte
	pop	dx			; restore overflow bits
	lodsb				; al = char data (byte 2)
	clr	ah
	ror	ax, cl			; ax = shifted char data
	or	al, dh			; combine old bits
	push	ax			; save overflow
	call	WriteChar1Byte
	inc	di
	pop	dx
	lodsb				; al = char data (byte 3)
	clr	ah
	ror	ax, cl			; ax = shifted char data
	or	al, dh			; combine old bits
	call	WriteChar1Word		; write out final word
	sub	di, 2
	dec	ch
	LONG jnz C3I4OC_loop
C3I4O_done label near
	pop	ax
	jmp	PSL_afterDraw

Cluster3In4Out	endp

;-------------------------------

C4I4OC_loop:
	NextDitherScan bp
	NextScan di
	tst	cs:[bm_scansNext]	; if off end of bitmap
	js	C4I4O_done

Cluster4In4Out	proc		near
	lodsb				; al = char data
	clr	ah
	ror	ax, cl			; ax = shifted char data
	push	ax			; save overflow bits
	call	WriteChar1Byte		; write first byte
	inc	di
	pop	dx			; restore overflow bits
	lodsb				; next char data byte
	clr	ah
	ror	ax, cl			; ax = shifted char data
	push	ax			; save overflow again
	or	al, dh			; combine old bits
	call	WriteChar1Byte
	inc	di
	pop	dx
	lodsw				; al = char data (bytes 3 and 4)
	ror	ax, cl			; ax = shifted char data
	or	al, dh			; combine old bits
	call	WriteChar1Word
	sub	di, 2
	dec	ch
	LONG jnz C4I4OC_loop
C4I4O_done label near
	pop	ax
	jmp	PSL_afterDraw

Cluster4In4Out	endp

		; we need this just for the label
		; we also need them to be unequal
DrawSpecialRect	proc	near
		ret
DrawSpecialRect	endp
DrawOptRect	proc	near
		ret
DrawOptRect	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ModeCLEAR, ModeCOPY, ModeNOP, ModeAND, ModeINVERT, ModeXOR,
		ModeSET, ModeOR

DESCRIPTION:	Execute draw mode specific action

CALLED BY:	INTERNAL
		SpecialOneWord, BlastSpecialRect

PASS:
	si - pattern (data)
	ax - screen
	dx - new bits AND draw mask

	where:	new bits = bits to write out (as in bits from a
			   bitmap).  For objects like rectangles,
			   where newBits=all 1s, dx will hold the
			   mask only.  Also: this mask is a final
			   mask, including any user-specified draw
			   mask.

RETURN:
	ax - destination (word to write out)

DESTROYED:
	dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Jim	02/89		Modified to do map mode right
-------------------------------------------------------------------------------@

;	the comments below use the following conventions (remember 
;	boolean algebra?...)
;		AND	^
;		OR	v
;		NOT	~

ModeRoutines	proc		near
		ForceRef	ModeRoutines
ModeCLEAR	label near	; (screen^~(data^mask))v(data^mask^resetColor
	not	dx
	and	ax, dx
	not	dx
	and	dx, cs:[resetColor]
	or	ax, dx
ModeNOP		label near
	ret

;-----------------

ModeCOPY	label  near	; (screen^~(data^mask))v(data^mask^pattern)
	not	dx
	and	ax, dx
	not	dx
	and	dx, si
	or	ax, dx
	ret

;-----------------

MA_orNotMask	word	

ModeAND		label  near	; (screen^((data^mask^pattern)v~(data^mask))
	not	dx
	mov	cs:[MA_orNotMask], dx
	not	dx
	and	dx, si
	or	dx, cs:[MA_orNotMask]
	and	ax, dx
	ret

;-----------------

ModeINVERT	label  near	; screenXOR(data^mask)
	xor	ax, dx
	ret

;-----------------

ModeXOR		label  near	; screenXOR(data^mask^pattern)
INVRSE <tst	cs:[inverseDriver]					>
INVRSE <jz	notInverse						>
INVRSE <not	si							>
	; Ok, this goes against style guidelines, but we need speed and
	; si back in its original form: duplicate three lines
	; and "ret" in the middle of this function.
INVRSE <and	dx, si							>
INVRSE <not	si							>
INVRSE <xor	ax, dx							>
INVRSE <ret								>
INVRSE <notInverse:							>
	and	dx, si
	xor	ax, dx
	ret

;-----------------

ModeSET		label  near	; (screen^~(data^mask))v(data^mask^setColor)
	not	dx
	and	ax, dx
	not	dx
	and	dx, cs:[setColor]
	or	ax, dx
	ret

;-----------------

ModeOR		label  near	; screen v (data^mask^pattern)
	and	dx, si
	or	ax, dx
	ret

ModeRoutines	endp
