COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver	
FILE:		monoCluster.asm

AUTHOR:		Jim DeFrisco, Feb 10, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT ClusterMux		A multiplexor for the cluster dither
				routines, in mono
    INT DrawOptClustered	Draw a rectangle with draw mode GR_COPY and
				all bits in the draw mask set
    INT DrawOptClusteredThin	Same as DrawOptClustered, optimized for
				one-word wide rect
    INT DrawSpecialClustered	Draw a rectangle with a special draw mask
				or draw mode clipping left and right
    INT DrawSpecialClusteredThin DrawSpecialClustered, optimized for
				one-word wide rect
    INT ClusterDoMode		front end for modeRoutines
    INT ClusterCharMux		ClusterChar routine Distributor
    INT Cluster1In1Out		Low level routine to draw a character when
				the source is X bytes wide and the
				destination is Y bytes wide, the drawing
				mode in GR_COPY and the character is
				entirely visible.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/10/92		Initial revision


DESCRIPTION:
	This routine implements some of the low-level drawing routines, 
	using a clustered order dither.
		

	$Id: monoCluster.asm,v 1.1 97/04/18 11:42:42 newdeal Exp $

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
EC <		cmp	di, 22			; size of HugeArrayBlock >
EC <		ERROR_B	VIDMEM_BAD_FRAME_BUFFER_PTR			>
		mov	ax, cs:[rectRoutine]		; see what we were
		cmp	ax, DRAW_SPECIAL_RECT
		LONG je	DrawSpecialClustered
		cmp	ax, DRAW_NOT_RECT
		LONG je	DrawNOTRect			; don't need spec vers
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

	; compute left masks

	mov	ax,cs:[si][leftMaskTable]	; get left mask
	mov	cs:[DOC_leftNewMask],ax
	not	ax
	mov	cs:[DOC_leftOldMask],ax

	; compute right masks

	mov	ax,cs:[bx][rightMaskTable]	; get right mask
	mov	cs:[DOC_rightNewMask],ax
	not	ax
	mov	cs:[DOC_rightOldMask],ax

	InitDitherIndex				; setup bx and si
	jmp	blastStart


DOC_loop:
	NextDitherScan				; update si
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	done
blastStart:
	push	di
	NextDitherWord				; ax = word of ditherMatrix

	; handle left word specially

DOC_leftNewMask	equ	(this word) + 1	
	and	ax, 1234h			; modified

	mov	cx, es:[di]			; get word
DOC_leftOldMask	equ	(this word) + 2
	and	cx, 1234h			; modified
	or	ax,cx
	stosw

	; draw middle words

	mov	cx, dx				; # of words affected
	dec	cx				; one less
	jcxz	doRightSide	
midLoop:
	NextDitherWord				; ax = word of ditherMatrix
	stosw
	loop	midLoop

	; handle right word specially
doRightSide:
	NextDitherWord
DOC_rightNewMask equ (this word) + 1
	and	ax, 1234h			; modified

	mov	cx, es:[di]			; get word
DOC_rightOldMask equ (this word) + 2
	and	cx, 1234h			; modified
	or	ax, cx
	stosw

	pop	di				; restore start of scan
	dec	bp				; loop to do all lines
	jnz	DOC_loop
done:
	ret

DrawOptClustered	endp


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
		mov	cs:[DOCT_newMask], ax
		not	ax
		mov	cs:[DOCT_oldMask], ax

		InitDitherIndex				; setup bx and si
		jmp	blastStart

DOCT_loop:
		NextDitherScan				; update si
		NextScan di
MEM <		tst	cs:[bm_scansNext]		; if off end of bitmap>
MEM <		js	done				; then bail	   >

blastStart:
		NextDitherWord				; ax = word to store

DOCT_newMask	equ	(this word) + 1	
		and	ax, 1234h			; modified

		mov	cx, es:[di]			; get word
DOCT_oldMask	equ	(this word) + 2
		and	cx, 1234h			; modified
		or	ax, cx
		mov	es:[di], ax
		dec	bp
done:
		jnz	DOCT_loop
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

	; compute left masks

	mov	ax, cs:[si][leftMaskTable]	;get mask
	mov	cs:[DSC_leftNewMask], ax

	; compute right masks

	mov	ax, cs:[bx][rightMaskTable]	;get mask
	mov	cs:[DSC_rightNewMask], ax

	InitDitherIndex				; init bx and si
	jmp	blastSpecialStart

DSC_loop:
	inc	cx
	NextDitherScan				; update si
	NextScan	di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	done

blastSpecialStart:
	and	cx, 7				; isolate low three bits
	push	cx				; save mask index
	xchg	cx, bx				; bx = mask index
	mov	bl, {byte} cs:[bx][maskBuffer]	; get draw mask byte
	mov	bh, bl				;  make it a word
	mov	cs:[CDM_mask], bx		; save mask
	mov	bx, cx				; restore bx
	push	di

	; handle left word specially

DSC_leftNewMask	equ	(this word) + 1
	mov	dx,1234h			; apply left-side mask
	mov	cx, es:[di]			; ax = screen
	NextDitherWord				; ax = next dither word
	call	ClusterDoMode			; ax = word to write
	stosw

	; draw middle words

DSC_middleCount	equ	(this word) + 1
	mov	cx, 1234h			; # words to store -- modified
	jcxz	DSC_noMiddle
DSC_midLoop:
	push	cx
	mov	dx, 0xffff			; dx = middle pattern
	mov	cx, es:[di]			; ax = screen
	NextDitherWord
	call	ClusterDoMode		; ax = word to write
	stosw
	pop	cx
	loop	DSC_midLoop
DSC_noMiddle:

	; handle right word specially

DSC_rightNewMask	equ	(this word) + 1
	mov	dx, 1234h			; apply right-side mask
	mov	cx, es:[di]			; ax = screen
	NextDitherWord
	call	ClusterDoMode			; ax = word to write
	stosw

	pop	di
	pop	cx				; restore mask index
	dec	bp				; loop to do all lines
	LONG jnz DSC_loop
done:
	ret

DrawSpecialClustered endp


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
	mov	cs:[DSCT_newMask], ax		; self-modify the code

	InitDitherIndex				; init bx and si
	jmp	blastSpecialStart

DSCT_loop:
	inc	cx
	NextDitherScan				; update si
	NextScan	di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	done

blastSpecialStart:
	and	cx, 7				; isolate low three bits
	push	cx				; save mask index
	xchg	cx, bx				; bx = mask index
	mov	bl, {byte} cs:[bx][maskBuffer]	; get draw mask byte
	mov	bh, bl				;  make it a word
	mov	cs:[CDM_mask], bx		; save mask
	mov	bx, cx				; restore bx

	; handle mask

DSCT_newMask	equ	(this word) + 1
	mov	dx, 1234h			; apply left-side mask
	mov	cx, es:[di]			; ax = screen
	NextDitherWord				; ax = next dither word
	call	ClusterDoMode			; ax = word to write
	mov	es:[di], ax			; store new value
	pop	cx				; restore mask index
	dec	bp				; loop to do all lines
	jnz	DSCT_loop
done:
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
		uses	si
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
	dw	offset Mono:Cluster1In1Out	;load 1, draw 1
	dw	offset Mono:Cluster1In2Out	;load 1, draw 2
	dw	offset Mono:NullRoutine		;load 1, draw 3
	dw	offset Mono:NullRoutine		;load 1, draw 4

	dw	offset Mono:NullRoutine		;load 2, draw 1
	dw	offset Mono:Cluster2In2Out	;load 2, draw 2
	dw	offset Mono:Cluster2In3Out	;load 2, draw 3
	dw	offset Mono:NullRoutine		;load 2, draw 4

	dw	offset Mono:NullRoutine		;load 3, draw 1
	dw	offset Mono:NullRoutine		;load 3, draw 2
	dw	offset Mono:Cluster3In3Out	;load 3, draw 3
	dw	offset Mono:Cluster3In4Out	;load 3, draw 4

	dw	offset Mono:NullRoutine		;load 4, draw 1
	dw	offset Mono:NullRoutine		;load 4, draw 2
	dw	offset Mono:NullRoutine		;load 4, draw 3
	dw	offset Mono:Cluster4In4Out	;load 4, draw 4


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
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	C1I1O_endCLoop

Cluster1In1Out	proc		near
	lodsb				;al = mask
	ror	al, cl			;al = mask shifted correctly
	mov	ah, al
	xchg	bp, si
	and	al, {byte} cs:[bx][si]	; al = mask AND pattern
	xchg	bp, si
	not	ah			;ah = NOT mask

	mov	dl, es:[di]		;dl = screen
	and	dl, ah			;dl = NOT mask AND screen
	or	al, dl			;al = data to store
	mov	es:[di], al
	dec	ch
	jz	C1I1O_endCLoop

	NextDitherScan bp
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	C1I1O_endCLoop

	lodsb				;al = mask
	ror	al, cl			;al = mask shifted correctly
	mov	ah, al
	xchg	bp, si
	and	al, {byte} cs:[bx][si]	; al = mask AND pattern
	xchg	bp, si
	not	ah			;ah = NOT mask

	mov	dl, es:[di]		;dl = screen
	and	dl, ah			;dl = NOT mask AND screen
	or	al, dl			;al = data to store
	mov	es:[di], al
	dec	ch
	LONG jnz C1I1OC_loop

C1I1O_endCLoop label near
	pop	ax
	jmp	PSL_afterDraw

Cluster1In1Out	endp

;-------------------------------

C1I2OC_loop:
	NextDitherScan bp
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	C1I2O_endCLoop

Cluster1In2Out	proc		near
	lodsb				; ax = char data
	clr	ah
	ror	ax, cl			; ax = shifted char data
	mov	dx, ax			; 
	not	dx			; dx = NOT char data
	xchg	bp, si
	and	ax, {word} cs:[bx][si]	; ax = dither applied to char data
	xchg	bp, si
	and	dx, es:[di]		; dx = screen and NOT char data
	or	ax, dx			; ax = final result
	mov	es:[di], ax
	dec	ch
	jz	C1I2O_endCLoop

	NextDitherScan bp
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	C1I2O_endCLoop

	lodsb				; ax = char data
	clr	ah
	ror	ax, cl			; ax = shifted char data
	mov	dx, ax
	not	dx			; dx = NOT char data
	xchg	bp, si
	and	ax, {word} cs:[bx][si]	; ax = dither applied to char data
	xchg	bp, si
	and	dx, es:[di]		; dx = screen and NOT char data
	or	ax, dx			; ax = final result
	mov	es:[di], ax
	dec	ch
	LONG jnz C1I2OC_loop

C1I2O_endCLoop label near
	pop	ax
	jmp	PSL_afterDraw

Cluster1In2Out	endp

;-------------------------------

C2I2OC_loop:
	NextDitherScan bp
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	C2I2O_endCLoop

Cluster2In2Out	proc		near
	lodsw				; ax = character data
	ror	ax, cl			; ax = shifted char data
	mov	dx, ax
	not	dx			; dx = NOT char data
	xchg	bp, si
	and	ax, {word} cs:[bx][si]	; ax = dither applied to char data
	xchg	bp, si
	and	dx, es:[di]		; dx = screen and NOT char data
	or	ax, dx			; ax = final result
	mov	es:[di], ax
	dec	ch
	jz	C2I2O_endCLoop

	NextDitherScan bp
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	C2I2O_endCLoop

	lodsw				; ax = char data
	ror	ax, cl			; ax = shifted char data
	mov	dx, ax
	not	dx			; bp = NOT char data
	xchg	bp, si
	and	ax, {word} cs:[bx][si]	; ax = dither applied to char data
	xchg	bp, si
	and	dx, es:[di]		; dx = screen and NOT char data
	or	ax, dx			; ax = final result
	mov	es:[di], ax
	dec	ch
	LONG jnz C2I2OC_loop

C2I2O_endCLoop label near
	pop	ax
	jmp	PSL_afterDraw

Cluster2In2Out	endp

;-------------------------------

C2I3OC_loop:
	NextDitherScan bp
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	C2I3O_endCLoop

Cluster2In3Out	proc		near
	lodsb				; al = char data
	clr	ah
	ror	ax, cl			; ax = shifted char data
	mov	dl, al
	not	dl			; dl = NOT char data
	xchg	bp, si
	and	al, {byte} cs:[bx][si]	; al = dither applied to char data
	xchg	bp, si
	BumpDitherIndex bx
	and	dl, es:[di]		; dl = screen and NOT char data
	or	al, dl			; al = final result
	stosb
	mov	dl,ah			; save extra bits
	lodsb				; al = char data (byte 2)
	clr	ah
	ror	ax, cl			; ax = shifted char data
	or	al, dl			; ax = complete char data (with extras)
	mov	dx, ax
	not	dx			; dx = NOT char data
	xchg	bp, si
	and	ax, {word} cs:[bx][si]	; ax = dither applied to char data
	xchg	bp, si
	and	dx, es:[di]		; dx = screen and NOT char data
	or	ax, dx			; ax = final result
	mov	es:[di], ax
	dec	di
	dec	ch
	jnz	C2I3OC_loop

C2I3O_endCLoop label near
	pop	ax
	jmp	PSL_afterDraw

Cluster2In3Out	endp

;-------------------------------

C3I3OC_loop:
	NextDitherScan bp
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	C3I3O_endCLoop

Cluster3In3Out	proc		near
	lodsb				; al = char data
	clr	ah
	ror	ax, cl			; ax = shifted char data
	mov	dl, al
	not	dl			; dl = NOT char data
	xchg	bp, si
	and	al, {byte} cs:[bx][si]	; al = dither applied to char data
	xchg	bp, si
	BumpDitherIndex bx
	and	dl, es:[di]		; dl = screen and NOT char data
	or	al, dl			; al = final result
	stosb
	mov	dl, ah			; dl = extra bits
	lodsw				; ax = rest of char data
	ror	ax, cl			; ax = shifted char data
	or	al, dl			; combine extra bits 
	mov	dx, ax
	not	dx			; dx = NOT char data
	xchg	bp, si
	and	ax, {word} cs:[bx][si]	; ax = dither applied to char data
	xchg	bp, si
	and	dx, es:[di]		; dx = screen AND NOT char data
	or	ax, dx			; ax = final result
	mov	es:[di], ax
	dec	di
	dec	ch
	jnz	C3I3OC_loop
C3I3O_endCLoop label near
	pop	ax
	jmp	PSL_afterDraw

Cluster3In3Out	endp

;-------------------------------

C3I4OC_loop:
	NextDitherScan bp
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	C3I4O_endCLoop

Cluster3In4Out	proc		near
	lodsb				; al = char data
	clr	ah
	ror	ax, cl			; ax = shifted char data
	mov	dl, al
	not	dl			; dl = NOT char data
	xchg	bp, si
	and	al, {byte} cs:[bx][si]	; al = dither applied to char data
	xchg	bp, si
	BumpDitherIndex bx
	and	dl, es:[di]		; dl = screen and NOT char data
	or	al, dl			; al = final result
	stosb
	mov	dl, ah			; dl = extra bits
	lodsb				; al = char data (byte 2)
	clr	ah
	ror	ax, cl			; ax = shifted char data
	or	al, dl			; combine old bits
	mov	dl, al			; 
	not	dl			; dl = NOT char data
	xchg	bp, si
	and	al, {byte} cs:[bx][si]	; al = dither applied to char data
	xchg	bp, si
	BumpDitherIndex bx
	and	dl, es:[di]		; dl = screen and NOT char data
	or	al, dl			; al = final result
	stosb
	mov	dl, ah			; dl = extra bits
	lodsb				; al = char data (byte 3)
	clr	ah
	ror	ax, cl			; ax = shifted char data
	or	al, dl			; combine old bits
	mov	dx, ax
	not	dx			; bp = NOT char data
	xchg	bp, si
	and	ax, {word} cs:[bx][si]	; ax = dither applied to char data
	xchg	bp, si
	and	dx, es:[di]		; dx = screen and NOT char data
	or	ax, dx			; ax = final result
	stosw
	sub	di, 4
	dec	ch
	LONG jnz C3I4OC_loop
C3I4O_endCLoop label near
	pop	ax
	jmp	PSL_afterDraw

Cluster3In4Out	endp

;-------------------------------

C4I4OC_loop:
	NextDitherScan bp
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap,	>
MEM <	js	C4I4O_endCLoop

Cluster4In4Out	proc		near
	lodsb				; al = char data
	clr	ah
	ror	ax, cl			; ax = shifted char data
	mov	dl, al
	not	dl			; dl = NOT char data
	xchg	bp, si
	and	al, {byte} cs:[bx][si]	; al = dither applied to char data
	xchg	bp, si
	BumpDitherIndex bx
	and	dl, es:[di]		; dl = screen and NOT char data
	or	al, dl			; al = final byte
	stosb
	mov	dl, ah			; dl = extra bits
	lodsb				; al = char data (byte 2)
	clr	ah
	ror	ax, cl			; ax = shifted char data
	or	al, dl			; combine old bits
	mov	dl, al
	not	dl			; dl = NOT char data
	xchg	bp, si
	and	al, {byte} cs:[bx][si]	; al = dither applied to char data
	xchg	bp, si
	BumpDitherIndex bx
	and	dl, es:[di]		; dl = screen and NOT char data
	or	al, dl			; al = final result
	stosb
	mov	dl, ah			; dl = extra bits
	lodsw				; al = char data (bytes 3 and 4)
	ror	ax, cl			; ax = shifted char data
	or	al, dl			; combine old bits
	mov	dx, ax	
	not	dx			; dx = NOT char data
	xchg	bp, si
	and	ax, {word} cs:[bx][si]	; ax = dither applied to char data
	xchg	bp, si
	and	dx, es:[di]		; dx = screen and NOT char data
	or	ax, dx			; ax = final result
	stosw
	sub	di, 4
	dec	ch
	LONG jnz C4I4OC_loop
C4I4O_endCLoop label near
	pop	ax
	jmp	PSL_afterDraw

Cluster4In4Out	endp

