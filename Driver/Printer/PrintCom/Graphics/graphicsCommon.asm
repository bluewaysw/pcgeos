COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common print routines
FILE:		graphicsCommon.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	3/90	initial version

DESCRIPTION:

	$Id: graphicsCommon.asm,v 1.1 97/04/18 11:51:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadSwathHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes a HugeArray bitmap and loads it's bitmap header into
		the PState

CALLED BY:	PrintSwath

PASS:		es	- pointer to locked PState
		dx.cx	- VM file and block handle for HugeArray bitmap

RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		save the VM file handle
		lock the VM block;
		copy the header into into the PState;
		unlock the block;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadSwathHeader	proc	near
		uses	bx, di, ds, es, bp
		.enter

		mov	es:[PS_bitmap].segment, dx ; store bitmap file and
		mov	es:[PS_bitmap].offset, cx  ;   block handle
		mov	bx, dx			; bx = file handle
		mov	ax, cx			; ax = dir block handle
		call	VMLock			; lock the HugeArray dir block
		mov	ds, ax			; ds -> HugeArray dir block
		mov	bx, size HugeArrayDirectory ; skip past dir header
		mov	ax, ds:[bx].B_width	; copy the elements
		mov	es:[PS_swath].B_width, ax
		mov	ax, ds:[bx].B_height
		mov	es:[PS_swath].B_height, ax
		mov	al, ds:[bx].B_type
		mov	es:[PS_swath].B_type, al
		mov	es:[PS_swath].B_compact, BMC_UNCOMPACTED
		call	VMUnlock		; release the VM block

		.leave
		ret
LoadSwathHeader	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefFirstScanline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get pointer to first scan line of HugeBitmap

CALLED BY:	PrintSwath
PASS:		es	- pointer to locked PState block
RETURN:		ds:si	- pointer to first scan line of the bitmap
				adjusted for color number.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just use HugeArrayLock

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		stores the offset in the PState, for use later

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 3/92		Initial version
	Dave	3/92		Initial version mods

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefFirstScanline	proc	near
	uses	ax, dx, bx, di, cx
	.enter
		
	clr	ax
	mov	es:[PS_curScanNumber], ax	; save for later
	mov	es:[PS_newScanNumber], ax	; save for later
	mov	es:[PS_firstBlockScanNumber], ax	; init the block start
	clr	dx				; accessing scan line
	mov	bx, es:[PS_bitmap].segment	; load up VM file and
	mov	di, es:[PS_bitmap].offset	; block handle
	call	HugeArrayLock
	mov	es:[PS_curScanOffset],si	; save the beginning of the
						; current scanline.
	dec	ax				; run to zero remaining instead
						; of one.
	mov	es:[PS_lastBlockScanNumber],ax	;set up last scanline

	.leave
	ret
DerefFirstScanline	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefAScanline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get pointer to a scan line of Locked HugeBitmap

CALLED BY:	PrintSwath
PASS:		es	- pointer to locked PState block
		PS_newScanNumber - scanline (element) number to deref.
RETURN:		ds:si	- pointer to a scan line of the bitmap
				adjusted for color number.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just use HugeArrayLock

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		stores the offset in the PState, for use later

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/92		Initial version 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefAScanline	proc	near
	uses	dx, bx, di, cx
	.enter
		
	mov	ax,es:[PS_newScanNumber]
	cmp	ax,es:[PS_firstBlockScanNumber]	;see if the desired scan is
	jb	newBlock			;currently dereferenced HAB
	cmp	ax,es:[PS_lastBlockScanNumber]	
	jbe	haveBlock

newBlock:
                ;must be in another block, dereference it.
	mov	si,es:[PS_curScanOffset]	;get index for current scan
        call    HugeArrayUnlock                 ;unlock the curent block.
                ;ax should hold the current scan line # to deref.
	mov	es:[PS_curScanNumber], ax	; save for later
	clr	dx				; accessing scan line
	mov	bx, es:[PS_bitmap].segment	; load up VM file and
	mov	di, es:[PS_bitmap].offset	; block handle
	call	HugeArrayLock
EC <    or      ax,ax                                                   >
EC <    ERROR_Z DEREFERENCING_OFF_END_OF_BITMAP                         >
	dec	cx
	dec	ax				;get the end of the current
	add	ax,es:[PS_curScanNumber]	;block.
	mov	es:[PS_lastBlockScanNumber],ax
	mov	ax,es:[PS_curScanNumber]	;get the beginning of current
	sub	ax,cx				;block.
	mov	es:[PS_firstBlockScanNumber],ax
	jmp	haveScan

haveBlock:
	mov	si,es:[PS_curScanOffset]
	mov	bx,ax				;get the difference.
        sub     bx,es:[PS_curScanNumber]	;bx now is the number of
						;scanlines to move for the next
						;scanline.
	jz	haveScan
	mov	es:[PS_curScanNumber], ax	; save new scan number.
        mov     ax,es:[PS_bandBWidth]           ;get the byte width of 1 color.

	mov     cl,es:[PS_swath].[B_type]       ;see if its a color bitmap.
        and     cl,mask BM_FORMAT
        cmp     cl,BMF_MONO                     ;Monochrome?
	je	haveBWidth			;if so, then no adjustment.
	cmp	cl,BMF_4BIT			;Same goes for 4,8,24 bits
	je	haveBWidth
	cmp	cl,BMF_8BIT
	je	haveBWidth
	cmp	cl,BMF_24BIT
	je	haveBWidth

		;assume 4 planes passed (even in 3CMY)
	shl     ax,2                            ;now of all 4 colors.
EC<	cmp	cl,BMF_4CMYK					>
EC<	je	haveBWidth					>
EC<	cmp	cl,BMF_3CMY					>
EC<	ERROR_NE INVALID_MODE					>

haveBWidth:
        mul     bx                              ;x scanline difference above.
        add     si,ax                           ;point at the beginning of the
						;new scanline.
haveScan:
	mov	es:[PS_curScanOffset],si	; save the beginning of the
						; current scanline.

	mov	cx,es:[PS_curColorNumber]	;set up the offset to CMYK col
	jcxz	exit
addLoop:
	add	si,es:[PS_bandBWidth]
	loop	addLoop				;add that # of widths
	clc
exit:	
	.leave
	ret
DerefAScanline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrLoadPstateVars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Take the device info table and load the bandHeight, and byteColumn
	locations in the PSTATE.

CALLED BY:
	Internal

PASS:
	es	- Segment of PSTATE

RETURN:
	cx	- number of integral bands in this swath.
	dx	- number of scanlines left over

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version
	Dave	03/92		Added swath geometry calculation to end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrLoadPstateVars	proc	near
	uses	ax, ds, si, bx
	.enter
	mov	bx,es:[PS_deviceInfo]	;handle for this printer resource.
	push	bx		;save printer resource handle.
	call	MemLock	;
	mov	ds,ax		;get segment address of print resource.
	mov	al,es:[PS_mode]	;get the mode for this document.
EC<	cmp	al,PM_GRAPHICS_HI_RES	;see if its a graphic mode.>
EC<	ERROR_A	INVALID_MODE					>
	clr	ah		;set up for index.
	mov	si,ax		;into index reg.
	mov	si,ds:[PI_firstMode][si] ;get index for table of info for this
					;mode.
EC<	tst	si		;see if feature not supported.	>
EC<	ERROR_Z	FEATURE_NOT_SUPPORTED				>
	clr	ah
	mov	al,ds:[si][GP_bandHeight] ;get the size of the print data for
	mov	es:[PS_bandHeight],ax
	mov	al,ds:[si][GP_buffHeight] ;get the size of the band buffer
	mov	es:[PS_buffHeight],ax
	mov	al,ds:[si][GP_interleaveFactor] ;get the  number of
						; interleaves
	mov	es:[PS_interleaveFactor],ax
	pop	bx
	call	MemUnlock	;unlock the printer info resource.

                ; get width, and calculate byte width of bitmap
        mov     ax, es:[PS_swath].B_width
	mov	bx, ax			;assume 8-bit bitmap
	mov     cl,es:[PS_swath].[B_type]       ;see what kind of bitmap.
        and     cl,mask BM_FORMAT
        cmp     cl,BMF_8BIT             ;8-bit or 24-bit?
	je	noRounding		;if so, then don't round.
	cmp	cl,BMF_24BIT
	je	noRounding
	cmp	cl,BMF_4BIT		;4-bit rounds by nibbles
	jne	not4bit
	inc	ax			; round up to next byte boundary
	and	al, 0xfe
	jmp	noRounding
not4bit:				;all other formats:
        add     ax, 7                   ; round up to next byte boundary
        and     al, 0xf8
noRounding:
        mov     es:[PS_bandWidth], ax   ; load the dot width.
	cmp	cl,BMF_8BIT		;8-bit:
	je	setBWidth		; byte width = dot width
	cmp	cl,BMF_24BIT		;24-bit:
	jne	not24bit
	mov	cx, ax			; byte width = 3 * dot width
	add	ax, ax
	add	ax, cx
	jmp	setBWidth
not24bit:
	cmp	cl,BMF_4BIT		;4-bit:
	jne	mustBeOneBit
	shr	ax, 1			; byte width = dot width / 2
	jmp	setBWidth
mustBeOneBit:				;all other formats are 1-bit:
        mov     cl, 3                   ; divide by 8....
        shr     ax, cl                  ; to obtain the byte width.
setBWidth:
        mov     es:[PS_bandBWidth], ax

                ; calculate the #bands
        mov     ax,es:[PS_swath].B_height ; get the height of bitmap.
        clr     dx                      ; dx:ax = divisor
        div     es:[PS_bandHeight]      ;get number of bands in this
        mov     cx,ax                   ;swath for counter.
                                                ; dx has remainder of division
                                                ; this is the #scans
	.leave
	ret
PrLoadPstateVars	endp


