
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		EGA screen driver
FILE:		Kernel/Screen/EGA/chars.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
   EXT	VidPutString	Draw a plaintext character string
   EXT	VidPutChar	Draw a plaintext character to the screen
   INT	LowPutChar	Draw a plaintext character to the screen
   INT	BlastChar	Draw a small plaintext character FAST
   INT	BlastMedChar	Draw a medium sized plaintext character FAST
   INT	BlastBigChar	Draw a big plaintext character FAST

	
REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	6/88	initial version


DESCRIPTION:
	This is the source for the EGA screen driver character drawing 
	routines.  This file is included in the file Kernel/Screen/ega.asm
		
	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/usr/pcgeos/Spec/video).  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidPutString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw s string of characters

CALLED BY:	EXTERNAL

PASS:		ax	- x position to start draw
		bx	- y position to start draw
		es:si	- pointer to string
		ds	- points to locked window structure

RETURN:		nothing

DESTROYED:	ax-di,es

PSEUDO CODE/STRATEGY:
		build out as much info as possible outside loop on character;
		loop calling lowputchar

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		windows doesn't write strings a chara at a time, they do it 
		a byte of screen memory at a time, and build out the parts of
		characters that will fall in that byte before the write.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

VidPutString	proc	far
	push	bp				; save frame pointer
	mov	cs:d_saveWinPtr, ds		; save ptr to window struc
	mov	cs:d_saveES, es			; save away extra segment

;	set up the EGA registers with color in set/reset reg, enable all planes
	mov	bp, ax				; save x position
	mov	dx, GR_CONTROL			; dx -> EGA control port
	mov	ax, WR_MODE_0			; set to write mode 0
	out	dx, ax
	mov	ax, EN_SR_ALL			; enable all bit planes
	out	dx, ax				;  in the enable set/reset reg
	mov	ah, byte ptr ds:[wTextClr]	; get color of char
	dec	al				;  and store to set/reset reg
	out	dx, ax				; set up pixel value for char
	clr	ah				; use EGA function SET
	mov	al, DATA_ROT			; set up index to data/rot reg
	out	dx, ax				; write to graphics control reg
	mov	ax, bp				; restore x position

;	extract some font info
	segmov	es, ds				; es -> locked window struc
	mov	ds, es:[wFontSeg]		; get segment addr of font info
	mov	cx, ds:[fChHeight]		; get font height
	add	cx, bx				;  calc y2
	dec	cx				;  bottom = +(height-1)

;	do clip check to see if all of char is in one clip region
	cmp	bx, es:[wClipLo]		; see if in bounds on top
	jl	VPS10				;  no, do full clip check
	cmp	cx, es:[wClipHi]		; check bottom 
	jle	VPS20				;  no, do full clip check
VPS10:
	call	SetClipPtr			;  no, set up right record
	cmp	bx, es:[wClipLo]		; see if in bounds on top
	jl	VPSnoFast			;  no, do full clip check
	cmp	cx, es:[wClipHi]		; check bottom 
	jle	VPS20
	jmp	short VPSnoFast			;  no, do full clip check

;	calc index to start of scan line
VPS20:
	sal	bx, 1				; bx = ypos * 2
	sal	bx, 1				; bx = ypos * 4
	sal	bx, 1				; bx = ypos * 8
	sal	bx, 1				; bx = ypos * 16
	mov	di, bx				; di = ypos * 16 
	sal	bx, 1				; bx = ypos * 32
	sal	bx, 1				; bx = ypos * 64
	add	di, bx				; di = ptr to start of scan
	mov	cs:d_framePtr, di		; save pointer into frame buf
	jmp	short VPStart

VPSloop:
	push	si				; save string pointer
	clr	bh
	shl	bx, 1				; *2 for index into word table
	mov	cx, ds:[bx+FONT_HDR_SIZE-(32*2)+2] ; get bit offset to next char
	mov	bx, ds:[bx+FONT_HDR_SIZE-(32*2)] ; get bit offset to this char
	sub	cx, bx				; calc char width
	mov	si, bx 				; si <- bit index
	mov	bh, cl				; save character width
	add	cx, ax				; calc next char position
	push	cx				; save it for next time thru 
	dec	cx				; cl <- low byte of right x pos
	shr	si, 1				; compute byte index
	shr	si, 1
	shr	si, 1
	add	si, ds:[fDataPtr]		; add in base data address
	mov	es, cs:d_saveWinPtr		; reload window struc ptr

	call	LowPutChar

	pop	ax				; restore next char position
	pop	si				; restore string pointer
	inc	si
	mov	di, cs:d_framePtr		; es:di -> start of scan line
VPStart:
	mov	es, cs:d_saveES			; restore extra seg address
	mov	bl, es:[si]			; get character to draw
	or	bl, bl				; see if NULL terminator
	jnz	VPSloop
	jmp	short VPSend

;	loop for character string not contained in one clip scan region
VPSnoFast:

VPSend:
	mov	ds, cs:d_saveWinPtr		; restore ds
	pop	bp				; restore frame pointer
	ret
VidPutString	endp
	public	VidPutString


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidPutChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a solid character to the screen (no pattern allowed)

CALLED BY:	EXTERNAL

PASS:		ax 	- x position to draw char
		bx 	- y position to draw char
		dl 	- character to draw
		ds	- points to locked window structure

		NOTE: This routine assumes that the font buffer is locked and
		      that the segment address of the buffer is in the window
		      structure

RETURN:		ax - x position of next char to draw
		dx - height of characters
		bx - unchanged

DESTROYED:	cx,si,di,es

PSEUDO CODE/STRATEGY:
		calc left/right for character draw from ax, char width;
		for each scan in character (top to bottom)
		   get region for this scan line;
		   calc newx1, newx2 for this scan line;
		   for each byte in line to draw
		      write out (position mask AND char data)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine won't handle characters > 256 scan lines high
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

VidPutChar	proc	far

	push	bp				; save stack frame pointer
	mov	cs:d_saveWinPtr, ds		; save ptr to window struc
	push	bx				; save y position

;	save away character to draw
	clr	dh				; force to word
	shl	dx, 1				; will use it for word index
	push	dx

;	set up the EGA registers with color in set/reset reg, enable all planes
	mov	bp, ax				; save x position
	mov	dx, GR_CONTROL			; dx -> EGA control port
	mov	ax, WR_MODE_0			; set to write mode 0
	out	dx, ax
	mov	ax, EN_SR_ALL			; enable all bit planes
	out	dx, ax				;  in the enable set/reset reg
	mov	ah, byte ptr ds:[wTextClr]	; get color of char
	dec	al				;  and store to set/reset reg
	out	dx, ax				; set up pixel value for char
	clr	ah				; use EGA function SET
	mov	al, DATA_ROT			; set up index to data/rot reg
	out	dx, ax				; write to graphics control reg
	mov	ax, bp				; restore x position

	segmov	es, ds				; es -> locked window struc
	mov	ds, es:[wFontSeg]		; get segment addr of font info
	mov	cx, ds:[fChHeight]		; get font height
	add	cx, bx				;  calc y2
	dec	cx				;  bottom = +(height-1)
	segmov	ds, es

;	do clip check to see if all of char is in one clip region
	cmp	bx, ds:[wClipLo]		; see if in bounds on top
	jl	VPC10				;  no, do full clip check
	cmp	cx, ds:[wClipHi]		; check bottom 
	jle	VPC20				;  no, do full clip check
VPC10:
	call	SetClipPtr			;  no, set up right record
	cmp	bx, ds:[wClipLo]		; see if in bounds on top
	jl	VPC50				;  no, do full clip check
	cmp	cx, ds:[wClipHi]		; check bottom 
	jg	VPC50				;  no, do full clip check

;	calc index to start of scan line
VPC20:
	mov	ds, es:[wFontSeg]		; restore font segment
	sal	bx, 1				; bx = ypos * 2
	sal	bx, 1				; bx = ypos * 4
	sal	bx, 1				; bx = ypos * 8
	sal	bx, 1				; bx = ypos * 16
	mov	di, bx				; di = ypos * 16 
	sal	bx, 1				; bx = ypos * 32
	sal	bx, 1				; bx = ypos * 64
	add	di, bx				; di = ypos * 80

	pop	bx				; restore character
	mov	cx, ds:[bx+FONT_HDR_SIZE-(32*2)+2] ; get bit offset to next char
	mov	bx, ds:[bx+FONT_HDR_SIZE-(32*2)] ; get bit offset to this char
	sub	cx, bx				; calc char width
	mov	si, bx 				; si <- bit index
	mov	bh, cl				; save character width
	add	cx, ax				; calc next char position
	push	cx				; save it for return value
	dec	cx				; cl <- low byte of right x pos
	shr	si, 1				; compute byte index
	shr	si, 1
	shr	si, 1
	add	si, ds:[fDataPtr]		; add in base data address

;	character is not clipped vertically, call fast routine
	call	LowPutChar
	jmp	short VPCdone

;	more intensive clipping routine
VPC50:
	pop	bx				;   and restore saved character 
	push	ax				;   and push bogus next x value
						;   ...to make the stack happy

VPCdone:
	mov	dx, ds:[fChHeight]		; return char height too
	pop	ax				; restore next char position
	pop	bx				; restore y position
	mov	ds, cs:d_saveWinPtr		; restore data seg
	pop	bp				; restore frame pointer
	ret
VidPutChar	endp
	public	VidPutChar


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LowPutChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a solid character to the screen (no pattern allowed)

CALLED BY:	INTERNAL

PASS:		ax 	- x position to draw char
		bl 	- low byte of bit index onto character data
		bh	- character width
		cx	- right side of character (x position)
		si	- index to character data
		di 	- index to start of scan line in frame buffer
		es	- segment address of locked window struc
		ds	- segment address of font info

		NOTE: This routine assumes that the font buffer is locked and
		      that the segment address of the buffer is in the window
		      structure

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,es

PSEUDO CODE/STRATEGY:
		if(character is completely visible)
		   BLAST IT!
		else
		   use the slower routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

LowPutChar	proc	near

;	see if character is completely visible.  If so, use fastest routine
	mov	bp, es:[wClipPtr]		; get ptr to region scan
LPC05:
	inc	bp				; bump to first on/off point
	inc	bp
	mov	dx, word ptr es:[bp]		; get on point
	cmp	dx,  EOREGREC			; check for NULL scan region
	je	LPCend				;  if NULL, quit
	cmp	ax, dx				; check on point
	jg	LPC10				;  ok so far, check right side
	cmp	cx, dx				; if both less, char not seen
	jl	LPCend				;  yep, all done
	cmp	cx, es:[bp+2]			; see if strange clipping
	jge	LPC50				;  yes, use strange clip rout
	jmp	short LPC20			;  nope, use clipped routine
LPC10:
	inc	bp				; bump source ptr
	inc	bp
	mov	dx, es:[bp]			; load off point
	cmp	cx, dx				; check off point
	jl	LPC15				;  ok, continue with blasting
	cmp	ax, dx				;  see if partially in
	jge	LPC05				;   no, try next on/off pair
	mov	dx, ax				; set up right value to use
	jmp	short LPC20			;   yes, use clipped routine

;	set up some values for BlastChar
LPC15:
	mov	bp, ax				; get x position 
	shr	bp, 1				;  /8 for scan line index
	shr	bp, 1
	shr	bp, 1
	add	di, bp				; form full frame buf index
	mov	ah, bl				; set up bit index
	mov	ch, bh				; set up char width

;	load up some constants
	mov	dx, frame_buf			; get frame buffer address
	mov	es, dx				; set up es-> frame buffer
	mov	dx, GR_CONTROL			; dx <- EGA graphics cntrl reg
	mov	bp, ds:[fSetWidth]		; bp <- # bytes/bitstream

;	character is completely visible, blast the character
LPCGoBlast:
	jmp	BlastChar			; FULL SPEED AHEAD !!!

;	character is clipped on left or right, use a different routine
LPC20:
	shr	dx, 1				;  /8 for scan line index
	shr	dx, 1
	shr	dx, 1
	add	di, dx				; form full frame buf index
	jmp	ClipChar			; almost full speed.

;	character is clipped in a strange way, use yet another routine
;	(strange means that the character is wider than a clip region it 
;	 is in and may even lie in more than one clip region)
LPC50:

;	all done
LPCend:
	ret
LowPutChar	endp
	public	LowPutChar


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an unclipped plain-text character to the screen

CALLED BY:	INTERNAL

PASS:		al 	- low byte of x position to draw char
		ah 	- low byte of bit index onto character data
		cl	- low byte of right side of character (x position)
		ch	- character width
		dx	- address of EGA control port
		bp	- bit offset into font data stream
		ds:si	- pointer into font data
		es:di	- pointer into frame buffer

RETURN:		nothing

DESTROYED:

PSEUDO CODE/STRATEGY:
		calc left and right masks;
		determine which routine to use (small,med,large)
		if (NOT small)
		   jump to appropriate routine;
		else
		   if(writing one byte)
		      if(shifting left)
			 use 1-byte-write-shift-left loop;
		      else
			 use 1-byte-write-shift-right loop;
		   else
		      if(shifting left)
			 use 2-byte-write-shift-left loop;
		      else
			 use 2-byte-write-shift-right loop;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

BlastChar	proc	near

;	calculate left and right side masks, and relative shift
	clr	bh
	mov	bl, cl			; get right pos
	and	bl, 7			; only interested in low three bits
	mov	cl, cs:[bx][rMaskTab]	; get mask
	and	al, 7			; al <- left side (lo 3 bits)
	mov	bl, al			; get left side pos
	mov	bh, cs:[bx][lMaskTab]	; get left mask
	xchg	bl, cl			; bx <- masks, cl <- left screen bit
	add	al, ch			; al <- right screen bit +1
	dec	al			;  need one less

;	calculate rightmost data and screen bit positions and relative shift
	and	ah, 7			; isolate low 3 bits of data index
	add	ch, ah			; ch <- rightmost data bit + 1
	dec	ch			;  but need oine less
	sub	cl, ah			; cl <- relative shift amount
	or	ch, al			; combine right bits for single compare

;	use different routine optimized for different sizes
;	if (rightmost_databit < 16) and (rightmost_screenbit < 16)
;	   use 1-word-write
;	else if (righmost_databit < 32) and (rightmost_screenbit < 32)
;	   use 2-word-write
;	else
;	   use monster-write

	cmp	ch, 16			; if 16 bits or less, we can use 1 word
	jl	BC10			;  ok, use one-word-write
BC03:
	cmp	ch, 32			; if 32 or less, we can use 2 words
	jge	BC05
	jmp	near ptr BlastMedChar	;  ok, use two-word-write
BC05:
	jmp	near ptr BlastBigChar	; this is a monster char, special rout

;	ok, we finally got it set, so blast the char data up
BCLoop1:
BC10:
	mov	ch, byte ptr ds:[fChHeight] ; loop count
	cmp	al, 8			; see if we need to write only one byte
	jae	BC50			;  no, continue
	dec	bp			; one word less to bump: using lodsw
	dec	bp
	and	bh, bl			; get entire mask in bh
	or	cl, cl			; see if we're shifting left or right
	jns	BC20			;  shifting right, continue

;	shifting left, writing one byte
	neg	cl			; calc shift amount

BC15:
	lodsw				; get the word in
	xchg	al, ah			; get order right
	shl	ax, cl			; shift em
	and	ah, bh			; only writing one byte
	mov	al, BITMASK		; set right register to write to
	out	dx, ax			; write out the mask
	or	es:[di], al		; write out color
	add	si, bp			; bump to next bit stream
	add	di, BWID_SCR		; other pointer to next scan line
	dec	ch			; one less scan to do
	jnz	BC15			
	ret				; this returns to LowPutChar caller

;	shifting right, writing one byte
BC20:
	lodsw				; get font data
	xchg	al, ah			; get them lined up right
	shr	ax, cl			; align data to screen
	and	ah, bh			; mask bits outside char definition
	mov	al, BITMASK		; set right register to write to
	out	dx, ax			; write out the mask
	or	es:[di], al		; write out color
	add	si, bp			; bump pointer to next bitstream
	add	di, BWID_SCR		; other pointer to next scan line
	dec	ch			; one less scan to do
	jnz	BC20			
	ret				; this returns to LowPutChar caller

BCLoop2:
;	 writing out 2 bytes
BC50:
	or	cl, cl			; see if we're shifting left or right
	jns	BC70			;  shifting right, continue

;	shifting left, writing two bytes
	mov	cs:BC61[2], bp		; SELF MODIFYING CODE (frees up a reg)
	mov	bp, bx			; put masks in bp
	neg	cl			; calc shift amount
	mov	al, BITMASK		; set right register to write to
BC60:
	mov	bx, ds:[si]		; get font data
	xchg	bl, bh			; get order right
	shl	bx, cl			; shift em
	and	bx, bp			; writing two bytes
	mov	ah, bh			; save second byte
	out	dx, ax			; write out the mask
	or	es:[di], al		; write out byte 1
	inc	di
	mov	ah, bl			; restore second byte
	out	dx, ax			; write out the mask
	or	es:[di], al		; write out byte 2
BC61	label	word
	add	si, 1234h		; bump pointer to next bitstream
	add	di, BWID_SCR-1		; other pointer to next scan line
	dec	ch			; one less scan to do
	jnz	BC60			
	ret				; this returns to LowPutChar caller

;	shifting right, writing two bytes
BC70:
	mov	cs:BC73[2], bp		; SELF MODIFYING CODE (frees up a reg)
	mov	bp, bx			; put masks in bp
	mov	al, BITMASK		; set right register to write to
BC72:
	mov	bx, ds:[si]		; get font data
	xchg	bl, bh			; get order right
	shr	bx, cl			; shift em
	and	bx, bp			; writing whole word
	mov	ah, bh			; write out left byte
	out	dx, ax			; write out the mask
	or	es:[di], al		; write out byte 1
	inc	di
	mov	ah, bl			; write out second byte
	out	dx, ax			; write out the mask
	or	es:[di], al		; write out byte 1
BC73	label	word
	add	si, 1234h		; bump pointer to next bitstream
	add	di, BWID_SCR-1		; other pointer to next scan line
	dec	ch			; one less scan to do
	jnz	BC72			
	ret				; this returns to LowPutChar caller
BlastChar	endp
	public	BlastChar, BCLoop1, BCLoop2



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastMedChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	INTERNAL

PASS:		al	- rightmost screen bit
		bh	- left side mask
		bl	- right side mask
		cl	- char data shift count (relative, -7 to 7)
		dx	- EGA i/o port
		ds:si	- pointer into font data
		es:di	- pointer into screen
		bp	- #bytes / bitstream

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		see BlastChar

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

BlastMedChar	proc	near
	mov	ah, byte ptr ds:[fChHeight]
	mov	byte ptr cs:chHeight, ah
	mov	ch, al			; ch <- rightmost screen bit 
	mov	al, BITMASK		; set up index register
	neg	cl			; see if we're shifting left or right
	jz	BMC01			;  special case zero shift
	js	BMC05			;  shifting right, continue
	jmp	BMC50			;  shifting left, continue
BMC01:
	mov	cl, ah			; init loop count
	jmp	BMC80

;	shifting right
;	if we're shifting right, we have a minimum of 3 bytes to write
BMC05:
	mov	cs:BMCsi1[2], bp	; SELF MODIFYING CODE
	add	cl, 7			; calculate relative jump
	sal	cl, 1			;  *4 (size of two shift instructions)
	sal	cl, 1
	mov	cs:BMCjmp1+1, cl	; SELF MODIFYING CODE
	mov	cs:BMCsE1+1, 0		; make it a NULL jump
	cmp	ch, 24			;  to free up another reg
	jge	BMC10
	mov	cs:BMCsE1+1, (BMC30-BMCwr4_1)
BMC10:
	mov	cx, ds:[si]		; get next word of font data
	xchg	cl, ch			; get order right
	mov	bp, cx			; save left word
	mov	cx, ds:[si+2]		; get next word
	xchg	cl, ch

BMCjmp1	label	byte
	jmp	short BMCshiftEnd1	; jump into shift stream
	shr	bp, 1			; shift em 7 times
	rcr	cx, 1
	shr	bp, 1			; shift em 6 times
	rcr	cx, 1
	shr	bp, 1			; shift em 5 times
	rcr	cx, 1
	shr	bp, 1			; shift em 4 times
	rcr	cx, 1
	shr	bp, 1			; shift em 3 times
	rcr	cx, 1
	shr	bp, 1			; shift em 2 times
	rcr	cx, 1
	shr	bp, 1			; shift em 1 time
	rcr	cx, 1
BMCshiftEnd1:
BMCsE1	label	byte

	jmp	short	BMC30		; THIS IS MODIFIED ABOVE
BMCwr4_1:
	and	cl, bl			; write out the fourth byte
	mov	ah, cl			; put byte where out wants it
	out	dx, ax			; write out the mask
	or	byte ptr es:[di+3], al	; read/write ega latches
	dw	0a9h			; opcode for test ax, IMM (skips over
BMC30:					;			   next instr)
	and	ch, bl			; third byte is right one
BMC32:
	mov	ah, ch			; get third byte where out wants it
	out	dx, ax			; write out the mask
	or	byte ptr es:[di+2], al	; read/write ega latches
	mov	cx, bp			; now do right word
	mov	ah, cl			; do second byte (not masked)
	out	dx, ax
	or	byte ptr es:[di+1], al	; read/write ega latches
	mov	ah, ch			; do left side byte
	and	ah, bh			;  so mask it
	out	dx, ax
	or	byte ptr es:[di], al	; read/write ega latches
	add	di, BWID_SCR		; other pointer to next scan line

BMCsi1	label	word
	add	si, 1234h		; bump pointer to next bitstream
	dec	byte ptr cs:chHeight	; one less scan to do
	jnz	BMC10			
	ret				; this returns to LowPutChar caller

;	shifting right
;	if we're shifting right, we have a minimum of 2 bytes to write
BMC50:
	mov	cs:BMCsi2[2], bp	; SELF MODIFYING CODE
	neg	cl
	add	cl, 7
	sal	cl, 1			;  *4 (size of two shift instructions)
	sal	cl, 1
	mov	cs:BMCjmp2+1, cl	; SELF MODIFYING CODE
	mov	cs:BMCsE2+1, 0		; assume NULL jmp (4 byte write)
	cmp	ch, 24			;  to free up another reg
	jge	BMC60
	cmp	ch, 16			; see if only a twobyte write
	jge	BMC55			;  no, three bytes
	mov	cs:BMCsE2+1, (BMC70-BMCwr4_2)
	jmp	short BMC60
BMC55:
	mov	cs:BMCsE2+1, (BMC65-BMCwr4_2)
BMC60:
	mov	cx, ds:[si]		; get next word of font data
	xchg	cl, ch			; get order right
	mov	bp, cx			; save left word
	mov	cx, ds:[si+2]		; get next word
	xchg	cl, ch

BMCjmp2	label	byte
	jmp	short BMCshiftEnd2	; dive into shift stream
	shl	cx, 1			; shift em 7 times
	rcl	bp, 1
	shl	cx, 1			; shift em 6 times
	rcl	bp, 1
	shl	cx, 1			; shift em 5 times
	rcl	bp, 1
	shl	cx, 1			; shift em 4 times
	rcl	bp, 1
	shl	cx, 1			; shift em 3 times
	rcl	bp, 1
	shl	cx, 1			; shift em 2 times
	rcl	bp, 1
	shl	cx, 1			; shift em 1 time
	rcl	bp, 1
BMCshiftEnd2:
BMCsE2	label	byte

	jmp	short	BMC70		; THIS IS MODIFIED ABOVE
BMCwr4_2:
	and	cl, bl			; write out the fourth byte
	mov	ah, cl			; put byte where out wants it
	out	dx, ax			; write out the mask
	or	byte ptr es:[di+3], al	; read/write ega latches
	dw	0a9h			; opcode for test ax, IMM (skips over
BMC65:					;			   next instr)
	and	ch, bl			; third byte is right one
BMC67:
	mov	ah, ch			; get third byte in position
	out	dx, ax			; write out mask
	or	byte ptr es:[di+2], al	; read/write ega latches
	mov	cx, bp			; get right two bytes
	jmp	short BMC72
BMC70:
	mov	cx, bp			; get left bytes
	and	cl, bl			; second byte is right one
BMC72:
	mov	ah, cl			; write out second byte
	out	dx, ax			; write out mask
	or	byte ptr es:[di+1], al	; read/write ega latches
	mov	ah, ch			; write out left byte
	and	ah, bh			; we know this one is masked
	out	dx,ax			; write out masks
	or	byte ptr es:[di], al	; read/write ega latches
	add	di, BWID_SCR		; other pointer to next scan line

BMCsi2	label	word
	add	si, 1234h		; bump pointer to next bitstream
	dec	byte ptr cs:chHeight	; one less scan to do
	jnz	BMC60			; branch out of range
	ret				; this returns to LowPutChar caller


;	ZERO SHIFT
;	if we're not shifting, we have a minimum of 3 bytes to write
BMC80:
	cmp	ch, 24			; see if writing three 
	jl	BMC85			;  yes, jump
	mov	ah, ds:[si+3]
	and	ah, bl			; write out the fourth byte
	out	dx, ax			; write out the mask
	or	byte ptr es:[di+3], al	; read/write ega latches
	mov	ah, ds:[si+2]
	out	dx, ax
	or	byte ptr es:[di+2], al	; read/write ega latches
	jmp	short BMC87		; finish last two writes
BMC85:				
	mov	ah, ds:[si+2]		; get third data byte
	and	ah, bl			; third byte is right one
	out	dx, ax			; write out mask
	or	byte ptr es:[di+2], al	; read/write ega latches
BMC87:
	mov	ah, ds:[si+1]
	out	dx, ax
	or	byte ptr es:[di+1], al	; read/write ega latches
	mov	ah, ds:[si]
	and	ah, bh
	out	dx, ax
	or	byte ptr es:[di], al	; read/write ega latches
	add	di, BWID_SCR		; other pointer to next scan line
	add	si, bp			; bump pointer to next bitstream
	dec	cl			; one less scan to do
	jnz	BMC80			; branch out of range
	ret				; this returns to LowPutChar caller
BlastMedChar	endp
	public	BlastMedChar


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastBigChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL

PASS:		arg	- description

RETURN:		ret	- description

DESTROYED:	reg	- description

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

BlastBigChar	proc	near

BBCexit:
	ret				; return to LowPutChar caller
BlastBigChar	endp
	public	BlastBigChar



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a clipped plain-text character to the screen

CALLED BY:	INTERNAL

PASS:		al 	- low byte of x position to draw char
		ah 	- low byte of bit index onto character data
		cl	- low byte of right side of character (x position)
		ch	- character width
		dx	- address of EGA control port
		bp	- bit offset into font data stream
		ds:si	- pointer into font data
		es:di	- pointer into frame buffer

RETURN:		nothing

DESTROYED:

PSEUDO CODE/STRATEGY:
		calc left and right masks;
		determine which routine to use (small,med,large)
		if (NOT small)
		   jump to appropriate routine;
		else
		   if(writing one byte)
		      if(shifting left)
			 use 1-byte-write-shift-left loop;
		      else
			 use 1-byte-write-shift-right loop;
		   else
		      if(shifting left)
			 use 2-byte-write-shift-left loop;
		      else
			 use 2-byte-write-shift-right loop;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

ClipChar	proc	near
	ret
ClipChar	endp
	public	ClipChar

