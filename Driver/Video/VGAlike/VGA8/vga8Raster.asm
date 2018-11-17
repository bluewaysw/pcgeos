COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:		vga8Raster.asm

AUTHOR:		Jim DeFrisco, Oct  8, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/ 8/92		Initial revision

DESCRIPTION:

	$Id: vga8Raster.asm,v 1.1 97/04/18 11:42:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidSegment	Blt


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltSimpleLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	blt a single scan line 

CALLED BY:	INTERNAL

PASS:		bx	- first x point in simple region
		ax	- last x point in simple region
		d_x1	- left side of blt
		d_x2	- right side of blt
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		if source is to right of destination
		   mask left;
		   copy left byte;
		   mask = ff;
		   copy middle bytes
		   mask right;
		   copy right byte;
		else
		   do the same, but from right to left

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

NMEM <.assert		((offset writeWindow) +1) eq (offset readWindow) >



BltSimpleLine   proc near
                uses ds

                .enter
                mov     ss:[bltOffset], 0
                mov     ss:[bltOffsetSrc], 0

                mov     ds, ss:[readSegment]
                mov     bx, ss:[bmLeft]    
                mov     ax, ss:[bmRight]        

                ; calc pixels to move
                sub     ax,bx        
                mov     cx,ax              
                inc     cx                      ; cx = pixels to move

                ; table selection routine
                mov     ss:[bltFlag], 0

                ; set source start an check overflow
                sub     bx, ss:[d_x1]
                add     bx, ss:[d_x1src]
                NextScanSrc     si, bx
                add     ss:[bltOffsetSrc], bx

                cmp     si, ss:[lastWinPtrSrc]
                jb      noSrcSwitch
                cmp     cx, ss:[pixelsLeftSrc]
                jb      noSrcSwitch
                or      ss:[bltFlag],2          ; set source overflow flag

noSrcSwitch:
                ; set destination start an check overflow
                mov     bx, ss:[bmLeft]
                NextScan        di, bx
                add     ss:[bltOffset], bx

                cmp     di, ss:[lastWinPtr]
                jb      noDestSwitch
                cmp     cx, ss:[pixelsLeft]
                jb      noDestSwitch
                or      ss:[bltFlag],4          ; set dest overflow flag

noDestSwitch:
                ; same readWin and writeWin
                mov     ax, {word} ss:[writeWindow]   
                cmp     al,ah                       
                je      diffWindow
                or      ss:[bltFlag], 32        ; same window flag         

diffWindow:
                ; copy direction?
                mov     ax,ss:[d_x1]     
                cmp     ax,ss:[d_x1src]   
                jle     forwardDirection
                or      ss:[bltFlag],16         ; bachwards flag

forwardDirection:
                ; copy on same page ?
                mov     dx,ss:[curWinPageSrc]
                cmp     dx,ss:[curWinPage]    
                jne     diffPage
                or      ss:[bltFlag],8          ; same page flags

diffPage:
                ; call special routine
                mov     bl, ss:[bltFlag]
                clr     bh
                jmp     word ptr cs:[BltRouts][bx]

;---------------------------------------------------------------------------

bltEnd          label near

                ; switch page back
                mov     ax, ss:[bltOffset]
                PrevScan        di, ax
                mov     ax, ss:[bltOffsetSrc]
                PrevScanSrc     si, ax
                .leave
                ret

;---------------------------------------------------------------------------

Blt1OverBoth    label near

                push    di                      ; save dest offset
                push    cx

                mov     es, ss:[bltBufSeg]
                clr     di
                                                ; winPage already in dx
                mov     bl, ss:[readWindow]  
                call    SetWinPage    

                mov     cx, ss:[pixelsLeftSrc]
                rep movsb

                xchg    di, si
                call    MidScanNextWinSrc
                xchg    di, si

                pop     cx
                push    cx

                sub     cx, ss:[pixelsLeftSrc]
                jcxz    null1
                rep movsb
null1:
                pop     cx
                pop     di                             
                push    si
                mov     es, ss:[writeSegment]           

                mov     ds, ss:[bltBufSeg]
                clr     si

                mov     bl,ss:[writeWindow]
                mov     dx,ss:[curWinPage]         
                call    SetWinPage                 

                push    cx
                mov     cx, ss:[pixelsLeft]
                rep movsb

                call    MidScanNextWin
                pop     cx

                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx

                sub     cx, ss:[pixelsLeft]
                jcxz    null2
                rep movsb
null2:
                pop     si
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt1OverSrc     label near

                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx

                push    di     
                push    cx                          

                mov     es, ss:[bltBufSeg]
                clr     di

                mov     bl,ss:[readWindow]              ; page already in dx
                call    SetWinPage 

                mov     cx, ss:[pixelsLeftSrc]
                rep movsb
                xchg    di, si
                call    MidScanNextWinSrc
                xchg    di, si

                pop     cx
                push    cx

                sub     cx, ss:[pixelsLeftSrc]
                jcxz    null3
                rep movsb
null3:
                pop     cx                             
                pop     di
                push    si

                mov     es,ss:[writeSegment]          

                mov     ds, ss:[bltBufSeg]
                clr     si

                mov     bl,ss:[writeWindow]
                mov     dx, ss:[curWinPage]        
                call    SetWinPage              

                rep movsb
                pop     si
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt1OverDest    label near

                push    di
                push    cx     

                mov     es, ss:[bltBufSeg]
                clr     di

                mov     bl, ss:[readWindow]             ; page already in dx
                call    SetWinPage     

                rep movsb

                pop     cx      
                pop     di      
                push    si
                mov     es, ss:[writeSegment]           

                mov     ds, ss:[bltBufSeg]
                clr     si

                mov     bl, ss:[writeWindow]
                mov     dx, ss:[curWinPage]      
                call    SetWinPage         

                push    cx
                mov     cx, ss:[pixelsLeft]

                rep movsb
                call    MidScanNextWin

                pop     cx
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                sub     cx, ss:[pixelsLeft]
                jcxz    null4

                rep movsb
null4:
                pop     si
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt1Fast        label near

                push    di
                push    cx              

                mov     es, ss:[bltBufSeg]
                clr     di

                mov     bl,ss:[readWindow]              ; page already in dx
                call    SetWinPage                  

                rep movsb

                pop     cx                             
                pop     di                             
                push    si

                mov     es,ss:[writeSegment]         

                mov     ds, ss:[bltBufSeg]
                clr     si

                mov     bl,ss:[writeWindow]
                mov     dx,ss:[curWinPage]           
                call    SetWinPage             

                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                rep movsb
                pop     si
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt1FastLeftSt  label near
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                rep movsb
                jmp      bltEnd

;---------------------------------------------------------------------------

Blt1FastRightSt label near

                dec     cx
                add     di,cx
                add     si,cx
                inc     cx

                std
                rep movsb
                cld
                inc     di
                inc     si

                jmp     bltEnd

;---------------------------------------------------------------------------

Blt2OverSrcRS   label near

                std
                dec     cx
                add     di, cx
                add     si, cx
                inc     cx

                sub     cx, ss:[pixelsLeftSrc]

                push    ss:[pixelsLeftSrc]
                stc
                xchg    si,di
                call    SetNextWinSrc
                xchg    si,di
                jcxz    null5
                rep movsb
null5:
                pop     cx     
                stc
                xchg    si,di
                call    SetPrevWinSrc
                xchg    si,di
                rep movsb
                inc     si
                inc     di
                cld
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt2OverDestRS  label near

                std
                dec     cx
                add     di, cx
                add     si, cx
                inc     cx

                sub     cx, ss:[pixelsLeft]
                push    ss:[pixelsLeft]
                stc
                call    SetNextWin
                jcxz    null6
                rep movsb
null6:
                pop     cx
                stc
                call    SetPrevWin

                rep movsb
                inc     si
                inc     di
                cld
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt2OverBothRS  label near

                std
                dec     cx
                add     di, cx
                add     si, cx
                inc     cx
                push    cx

                mov     cx, ss:[pixelsLeft]
                cmp     cx, ss:[pixelsLeftSrc]
                jbe     obrs

                pop     cx
                sub     cx, ss:[pixelsLeft]
                push    ss:[pixelsLeft]
                stc
                call    SetNextWin
                stc
                xchg    si,di
                call    SetNextWinSrc
                xchg    si,di
                jcxz    null7
                rep movsb
null7:
                pop     cx

                push    ss:[pixelsLeftSrc]
                stc

                call    SetPrevWin
                sub     cx, ss:[pixelsLeftSrc]
                jcxz    null8
                rep movsb
null8:
                pop     cx
                stc
                xchg    si,di
                call    SetPrevWinSrc
                xchg    si,di
                rep movsb

                inc     si
                inc     di
                cld
                jmp     bltEnd

obrs:
                pop     cx
                sub     cx, ss:[pixelsLeftSrc]
                push    ss:[pixelsLeftSrc]

                stc
                call    SetNextWin
                stc
                xchg    si,di
                call    SetNextWinSrc
                xchg    si,di

                jcxz    null9
                rep movsb
null9:
                pop     cx

                push    ss:[pixelsLeft]
                stc
                xchg    si,di
                call    far ptr SetPrevWinSrc
                xchg    si,di

                sub     cx, ss:[pixelsLeft]
                jcxz    null10
                rep movsb
null10:
                pop     cx

                stc
                call    SetPrevWin
                rep movsb
                cld
                inc     si
                inc     di
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt2OverSrc     label near

                push    cx
                mov     cx, ss:[pixelsLeftSrc]
                rep movsb

                xchg    di,si
                call    MidScanNextWinSrc
                xchg    di,si
                
                pop     cx
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx

                sub     cx,ss:[pixelsLeftSrc]
                jcxz    loop11
                rep movsb
loop11:
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt2OverDest    label near

                push    cx
                mov     cx, ss:[pixelsLeft]
                rep movsb

                call   MidScanNextWin
    
                pop     cx
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                sub     cx,ss:[pixelsLeft]
                jcxz    loop12        
                rep movsb
loop12:
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt2OverBoth    label near
                push    cx
                mov     cx, ss:[pixelsLeft]
                cmp     cx, ss:[pixelsLeftSrc]
                jbe     ob

                mov     cx, ss:[pixelsLeftSrc]
                rep movsb
                xchg    si,di
                call    MidScanNextWinSrc
                xchg    si,di

                mov     cx, ss:[pixelsLeft]
                sub     cx, ss:[pixelsLeftSrc]
                jcxz    loop13
                rep movsb
loop13:
                call    MidScanNextWin
                pop     cx

                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx

                sub     cx, ss:[pixelsLeft]
                jcxz    loop14
                rep movsb
loop14:
                jmp     bltEnd
ob:
                rep movsb
                call    MidScanNextWin
                mov     cx, ss:[pixelsLeftSrc]
                sub     cx, ss:[pixelsLeft]
                jcxz    loop15
                rep movsb
loop15:
                xchg    si, di
                call    MidScanNextWinSrc
                xchg    si, di
                pop     cx

                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx

                sub     cx, ss:[pixelsLeftSrc]
                jcxz    loop16
                rep movsb
loop16:
                jmp   bltEnd

BltSimpleLine	endp

ifndef	IS_MEM

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetWinPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just set the current memory window

CALLED BY:	INTERNAL
PASS:		bl	- window to set
		dx	- which window to set
RETURN:		nothing
DESTROYED:	bx,dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetWinPage	proc	near
                or      dx, dx
                js      done
		clr	bh
		tst	ss:[modeInfo].VMI_winFunc.segment ; check for routine
		jz	useInterrupt
		call	ss:[modeInfo].VMI_winFunc	; set page
done:		
		ret

useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		int	VIDEO_BIOS
		jmp	done		
SetWinPage	endp

endif

VidEnds		Blt


VidSegment 	Bitmap


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColor8Scan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an 8-bit/pixel scan line of bitmap data

CALLED BY:	INTERNAL
		
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/26/92	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor8Scan	proc	near

		; calculate # bytes to fill in

		mov	bx, ss:[bmLeft]
                mov     cx, bx
                mov	ax, ss:[d_x1]		;
		add	si, bx			; 
		sub	si, ax			; ds:si -> pic bytes

                ; read line mask
                sub     cx, ax
                and     cx, 7                   ; calc mask offset

                mov     dh, ss:[lineMask]       ; real line mask
                ror     dh, cl                  ; shift line mask

		mov	cx, ss:[bmRight]	; compute #bytes to write
		sub	cx, bx			; #bytes-1
		inc	cx

                NextScan        di, bx          ; es:di -> dest byte

                cmp     di, ss:[lastWinPtr]
                jb      notPartial

                cmp     cx, ss:[pixelsLeft]
                jae     doPartial
notPartial:
                call    PutCol8ScanLow
done:
                mov     cx, ss:[bmRight]
                inc     cx
                PrevScan        di, cx
		ret

doPartial:
                push    cx
                mov     cx, ss:[pixelsLeft]
                call    PutCol8ScanLow
                call    MidScanNextWin
                pop     cx
                sub     cx, ss:[pixelsLeft]
                jcxz    null1
                call    PutCol8ScanLow
null1:
                jmp     done
                
PutColor8Scan	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PutCol8ScanLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an 8-bit/pixel scan line of bitmap data
                without jump over an page border

CALLED BY:	INTERNAL
		
PASS:           dh      - common byte mask
                cx      - count of pixels to put out
                ds:si   - source data to put out
                es:di   - destination in video memory

RETURN:         ds:si   - source data following
                es:di   - frame ptr of following byte
                dh      - mask shifted right

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
        ----    ----            -----------
	Jim	10/26/92	Initial version
        FR      08/29/97        made the low part
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutCol8ScanLow  proc    near

                ; check for line mask
                cmp     dh, 0FFh
                jnz     mapMask

		; check for a palette
		test	ss:[bmType], mask BMT_PALETTE	; test for palette
		jnz	mapPalette

		shr	cx, 1			; #words
		jnc	moveWords
		movsb
		jcxz	done
moveWords:
		rep	movsw
done:
                retn

mapMask:        test    ss:[bmType], mask BMT_PALETTE   ; test for palette
                jnz     mapPalMask

                test    dh, 080h
                jz      nopix1

                movsb                           ; get the first byte
                jmp     ok1                     ; write to frame buffer
nopix1:
                inc     si
ok1:
                rol     dh                      ; rotate line mask
                loop    mapMask

		jmp	done


mapPalette:
		; handle the case where there is a palette with the bitmap.
		; Read each byte, look it up in the table, then write that
		; corresponding byte out
		;
		lodsb				; get the first byte
		push	es			; map to palette
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es
		stosb				; write to frame buffer
		loop	mapPalette
		jmp	done

mapPalMask:
                test    dh, 080h
                jz      nopix2

		lodsb				; get the first byte
		push	es			; map to palette
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es
		stosb				; write to frame buffer
                jmp     ok2

nopix2:
                inc     si
ok2:
                rol     dh                      ; rotate line mask
                loop    mapPalMask
		jmp	done

PutCol8ScanLow  endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PutColor8ScanMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an 8-bit/pixel scan line of bitmap data

CALLED BY:	INTERNAL
		
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
        ----    ----            -----------
	Jim	10/26/92	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor8ScanMask	proc	near

		; calculate # bytes to fill in

		mov	bx, ss:[bmLeft]
		mov	ax, ss:[d_x1]		; 
		sub	bx, ax			; bx = index into pic data
		mov	dx, bx			; save index
		mov	cx, bx
		xchg	bx, si			; ds:bx -> mask data
		add	si, bx
		sub	bx, ss:[bmMaskSize]	; ds:si -> pic data
		shr	dx, 1
		shr	dx, 1
		shr	dx, 1			; bx = index into mask
		add	bx, dx			; ds:bx -> into mask data
		and	cl, 7
		mov	dh, 0x80		; test bit for mask data
		shr	dh, cl			; dh = starting mask bit
		mov	cx, ss:[bmRight]	; compute #bytes to write
		sub	cx, ss:[bmLeft]		; #bytes-1
		inc	cx
		mov	dl, ds:[bx]		; get first mask byte
                and     dl, ss:[lineMask]
                inc	bx

                mov     ax, ss:[bmLeft]
                NextScan        di, ax

                cmp     di, ss:[lastWinPtr]
                jb      notPartial

                cmp     cx, ss:[pixelsLeft]
                jae     doPartial

notPartial:
                call    PutCol8ScanMaskLow
done:
                mov     cx, ss:[bmRight]
                inc     cx
                PrevScan        di, cx
		ret

doPartial:
                push    cx
                mov     cx, ss:[pixelsLeft]
                call    PutCol8ScanMaskLow
                call    MidScanNextWin
                pop     cx
                sub     cx, ss:[pixelsLeft]
                jcxz    null1
                call    PutCol8ScanMaskLow
null1:
                jmp     done

PutColor8ScanMask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PutCol8ScanMaskLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Draw an 8-bit/pixel scan line of bitmap data with mask
                without jump over an page border

CALLED BY:	INTERNAL
		
PASS:           dh      - common byte mask
                cx      - count of pixels to put out
                ds:si   - source data to put out
                ds:bx   - mask data for scan line
                es:di   - destination in video memory

RETURN:         ds:si   - source data following
                ds:bx   - ptr to next mask byte
                es:di   - frame ptr of following byte
                dh      - mask shifted right

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
        ----    ----            -----------
	Jim	10/26/92	Initial version
        FR      08/29/97        made the low part
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutCol8ScanMaskLow      proc    near

		; check for a palette
		test	ss:[bmType], mask BMT_PALETTE	; test for palette
		jnz	mapPalette
pixLoop:
		lodsb
		test	dl, dh			; do this pixel ?
		jz	nextPixel
		mov	es:[di], al		; store it
nextPixel:
		inc	di
		shr	dh, 1			; move test bit down
		jc	reloadTester		;  until we need some more
haveTester:
		loop	pixLoop
done:
                ret

		; done with this mask byte, get next
reloadTester:
		mov	dl, ds:[bx]		; load next mask byte
                and     dl, ss:[lineMask]
                inc	bx
		mov	dh, 0x80
		jmp	haveTester

mapPalette:
		lodsb
		push	es, bx			; map to palette
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es, bx
		test	dl, dh			; do this pixel ?
		jz	paletteNextPixel
		mov	es:[di], al		; store it
paletteNextPixel:
		inc	di
		shr	dh, 1			; move test bit down
		jc	paletteReloadTester	;  until we need some more
paletteHaveTester:
		loop	mapPalette
		jmp	done

		; done with this mask byte, get next
paletteReloadTester:
		mov	dl, ds:[bx]		; load next mask byte
                and     dl, ss:[lineMask]
                inc	bx
		mov	dh, 0x80
		jmp	paletteHaveTester

PutCol8ScanMaskLow      endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColorScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a scan line's worth of system memory to screen

CALLED BY:	INTERNAL

PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PutColorScan	proc	near
		uses	bp
		.enter

		; calculate # bytes to fill in

		mov	bx, ss:[bmLeft]
		mov	bp, bx			; get # bits into image
		sub	bp, ss:[d_x1]		; get left coordinate
		mov	ax, ss:[bmRight]	; get right side to get #bytes
		mov	dx, bp			; save low bit
		shr	bp, 1			; bp = #bytes index
		add	si, bp			; index into bitmap

                NextScan        di, bx          ; add to screen offset too
                
		mov	bp, ax			; get right side in bp
		sub	bp, bx			; bp = # dest bytes to write -1
		inc	bp			; bp = #dest bytes to write

                mov     dh, ss:[lineMask]
                mov     cl, dl
                and     cl, 7
                rol     dh, cl

		mov	cl, 4			; shift amount

                cmp     di, ss:[lastWinPtr]
                jb      notPartial

                cmp     bp, ss:[pixelsLeft]
                jae     doPartial

                mov     ax, ss:[bmRight]
notPartial:
                call    PutColScanLow
done:
                ; go back to the start position
                mov     ax, ss:[bmRight]
                inc     ax
                PrevScan        di, ax

		.leave
		ret

doPartial:
                push    bp
                mov     bp, ss:[pixelsLeft]
                call    PutColScanLow
                call    MidScanNextWin
                pop     bp
                sub     bp, ss:[pixelsLeft]
                tst     bp
                jz      null1
                call    PutColScanLow
null1:
                jmp     done

PutColorScan	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PutColScanLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Draw an 4-bit/pixel scan line of bitmap data
                without jump over an page border

CALLED BY:	INTERNAL
		
PASS:           dh      - common byte mask
                bp      - count of pixels to put out
                ds:si   - source data to put out
                es:di   - destination in video memory

RETURN:         ds:si   - source data following
                es:di   - frame ptr of following byte
                dh      - mask shifted right

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                lineMask is currently not suppored

REVISION HISTORY:
	Name	Date		Description
        ----    ----            -----------
	Jim	10/26/92	Initial version
        FR      08/29/97        made the low part
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutColScanLow   proc    near

		; check for a palette
		test	ss:[bmType], mask BMT_PALETTE	; test for palette
		jnz	handlePalette

		; we're all setup.  See if we're taking pixels from front or
		; rear (check shift value)

		test	dl, 1			; see if starting odd or even
		jz	evenLoop

		; do first one specially

		lodsb
		and	al, 0xf
                rol     dh
                jnc     maskLoop1
                mov     [es:di], al
maskLoop1:
                inc     di
		dec	bp
		jz	done

		; specially, though.
evenLoop:
		lodsb				; get next byte
		mov	ah, al			; split them up
		shr	al, cl			; align stuff
		sub	bp, 2
		js	lastByte
		and	ax, 0x0f0f		; isolate pixels

                rol     dh
                jnc     maskLoop2
                mov     [es:di], al
maskLoop2:
                inc     di

                rol     dh
                jnc     maskLoop3
                mov     [es:di], ah
maskLoop3:
                inc     di
      		tst	bp			; if only one byte to do...
		jnz	evenLoop
done:
                ret

handlePalette:
		; we're all setup.  See if we're taking pixels from front or
		; rear (check shift value)

		test	dl, 1			; see if starting odd or even
		jz	paletteEvenLoop

		; do first one specially

		lodsb
		and	al, 0xf
		push	es
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es

                rol     dh
                jnc     maskLoop5
                mov     [es:di], al
maskLoop5:
                inc     di
		dec	bp
		jz	done

		; specially, though.
paletteEvenLoop:
		lodsb				; get next byte
		mov	ah, al			; split them up
		shr	al, cl			; align stuff
		and	ax, 0x0f0f		; isolate pixels
		push	es
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es
		sub	bp, 2
		js	lastByte

                rol     dh
                jnc     maskLoop6
                mov     [es:di], al
maskLoop6:
                inc     di
		xchg	ah,al
		push	es
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es

                rol     dh
                jnc     maskLoop7
                mov     [es:di], al               ; store pixel values
maskLoop7:
                inc     di
		tst	bp			; if only one byte to do...
		jnz	paletteEvenLoop
		jmp	done
                
		; odd number of bytes to do.  Last one here...
lastByte:
                rol     dh
                jnc     maskLoop4      
                mov     [es:di], al
maskLoop4:
                inc     di
		jmp	done

PutColScanLow   endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColorScanMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a scan line's worth of system memory to screen
		applying a bitmap mask

CALLED BY:	INTERNAL

PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PutColorScanMask	proc	near
		uses	bp
		.enter

		; calculate # bytes to fill in

		mov	ax, ss:[bmLeft]
		mov	bp, ax			; get # bits into image
		sub	bp, ss:[d_x1]		; get left coordinate
		mov	dx, bp			; save low bit
		mov	bx, bp			; save pixel index into bitmap
		sar	bp, 1			; compute index into pic data
		sar	bx, 1			; compute index into mask data
		sar	bx, 1
		sar	bx, 1
		add	bx, si			; ds:bx -> mask byte
		sub	bx, ss:[bmMaskSize]	; ds:si -> picture data
		add	si, bp			; ds:si -> into picture data

		mov	bp, ss:[bmRight]	; get right side in bp
		sub	bp, ax			; bp = # dest bytes to write -1
		inc	bp

		mov	cl, dl			; need index into mask byte
		mov	ch, 0x80		; form test bit for BM mask
		and	cl, 7
		shr	ch, cl			; ch = mask test bit
		mov	cl, 4			; cl = pic data shift amount

		; get first mask byte

		mov	dh, ds:[bx]		; dh = mask byte
                and     dh, ss:[lineMask]
                inc	bx			; get ready for next mask byte

                NextScan        di, ax          ; add to screen offset too
                
                cmp     di, ss:[lastWinPtr]
                jb      notPartial
                cmp     bp, ss:[pixelsLeft]
                jae     doPartial

notPartial:
                call    PutColScanMaskLow
done:
                ; go back to the start position
                mov     ax, ss:[bmRight]
                inc     ax
                PrevScan        di, ax

		.leave
		ret


doPartial:
                push    bp
                mov     bp, ss:[pixelsLeft]
                call    PutColScanMaskLow
                call    MidScanNextWin

		test	dl, 1			; see if starting odd or even
		jz	evenLoop
                dec     si
evenLoop:
                pop     bp
                sub     bp, ss:[pixelsLeft]
                tst     bp
                jz      null1
                call    PutColScanMaskLow
null1:
                jmp     done

PutColorScanMask endp

PutColScanMaskLow       proc    near
                
		; check for a palette
		test	ss:[bmType], mask BMT_PALETTE	; test for palette
		jnz	handlePalette

		; we're all setup.  See if we're taking pixels from front or
		; rear (check shift value)

		test	dl, 1			; see if starting odd or even
		jz	evenLoop

		; do first one specially

		lodsb
		test	dh, ch			; mask bit set ?
		jz	doneFirst
		and	al, 0xf
		mov	es:[di], al
doneFirst:
		inc	di
                xor     dl, 1 
		shr	ch, 1			; test next bit
                jnc     loop1
		mov	dh, ds:[bx]		; load next mask byte
                and     dh, ss:[lineMask]
                inc	bx
		mov	ch, 0x80		; reload test bit
loop1:
		dec	bp
		jz	done

		; specially, though.
evenLoop:
		lodsb				; get next byte
		mov	ah, al			; split them up
		shr	al, cl			; align stuff
		and	ax, 0x0f0f		; isolate pixels
		test	dh, ch			; check pixel
		jz	doSecond
		mov	es:[di], al
doSecond:
		inc	di
                xor     dl,1
		shr	ch, 1
		dec	bp			; one less to go
		jz	done
		test	dh, ch
		jz	nextPixel
		mov	es:[di], ah
nextPixel:
		inc	di
                xor     dl, 1 
		shr	ch, 1
		jc	reloadTester
haveTester:
		dec	bp
		jnz	evenLoop
done:
                ret

reloadTester:
		mov	dh, ds:[bx]		; get next mask byte
                and     dh, ss:[lineMask]
                inc	bx
		mov	ch, 0x80
		jmp	haveTester

handlePalette:
		; we're all setup.  See if we're taking pixels from front or
		; rear (check shift value)

		test	dl, 1			; see if starting odd or even
		jz	paletteEvenLoop

		; do first one specially

		lodsb
		test	dh, ch			; mask bit set ?
		jz	paletteDoneFirst
		and	al, 0xf
		push	es, bx			; save these
		les	bx, ss:[bmPalette]	; es:di -> palettw
		xlat	es:[bx]			; al = color value
		pop	es, bx			; restore
		mov	es:[di], al
paletteDoneFirst:
		inc	di
                xor     dl, 1
		shr	ch, 1			; test next bit
                jnc     loop2
		mov	dh, ds:[bx]		; load next mask byte
                and     dh, ss:[lineMask]
                inc	bx
		mov	ch, 0x80		; reload test bit
loop2:
		dec	bp
		jz	done

		; specially, though.
paletteEvenLoop:
		lodsb				; get next byte
		mov	ah, al			; split them up
		shr	al, cl			; align stuff
		and	ax, 0x0f0f		; isolate pixels
		test	dh, ch			; check pixel
		jz	paletteDoSecond
		push	es, bx
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es, bx
		mov	es:[di], al

paletteDoSecond:
		inc	di
                xor     dl, 1
		shr	ch, 1
		dec	bp			; one less to go
		jz	done
		test	dh, ch
		jz	paletteNextPixel
		mov	al, ah			; get second pixel value in al
		push	es, bx
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]			; look up palette value
		pop	es, bx
		mov	es:[di], al
paletteNextPixel:
		inc	di
                xor     dl, 1 
		shr	ch, 1
		jc	paletteReloadTester
paletteHaveTester:
		dec	bp
		jnz	paletteEvenLoop
		jmp	done

paletteReloadTester:
		mov	dh, ds:[bx]		; get next mask byte
                and     dh, ss:[lineMask]
                inc	bx
		mov	ch, 0x80
		jmp	paletteHaveTester

PutColScanMaskLow       endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillBWScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a scan line's worth of system memory to screen
		draws monochrome info as a mask, using current area color

CALLED BY:	INTERNAL

PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		set drawing color;
		mask left;
		shift and copy left byte;
		shift and copy middle bytes
		mask right;
		shift and copy right byte;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FillBWScan	proc	near

                clr     bh
                mov     ss:[bmFilled], 1        ; filled output
                mov     dl, ss:currentColor     ; dl = color to draw

fillPutCommon	label	near
		push	bp
                push    bx
		mov	bx, ss:[bmLeft]
		mov	ax, ss:[bmRight]

NMEM <          NextScanBoth    di, bx     >
MEM <           NextScan    di, bx     >

                ; calculate # bytes to fill in
                mov	bp, bx			; get #bits into image at start
		mov	cx, ss:[d_x1]		; get left coordinate
		sub	bp, cx			; bp = (bmLeft-x1)
		mov	bx, bp			; save low three bits of x indx

                ; adjust source

		mov	cl, 3
		sar	bp, cl			; compute byte index
		add	si, bp			; add bytes-to-left-side

                ; start bit

		mov	cx, bx
		and	cl, 7
		mov	dh, 0x80		; dh = test bit
		shr	dh, cl			;       properly aligned

		mov	bp, si			; ds:bp -> mask data
		sub	bp, ss:[bmMaskSize]	; ds:si -> picture data

                ; pixels to put out

                mov     cx, ss:[bmRight]
                sub     cx, ss:[bmLeft]
                inc     cx

                pop     bx

                cmp     di, ss:[lastWinPtr]
                jb      notPartial
 
                cmp     cx, ss:[pixelsLeft]
                jae     doPartial

notPartial:
		mov	ah, ss:lineMask		; draw mask to use
                tst     bh
                jz      noDrawMask1
                and     ah, [ds:bp]
                inc     bp
noDrawMask1:
		lodsb				; next data byte

                call    WriteMonoBytes

done:
                ; go back to the start position
                mov     ax, ss:[bmRight]
                inc     ax
NMEM<           PrevScanBoth        di, ax            >
MEM<            PrevScan        di, ax            >

		pop	bp
		ret

doPartial:
                push    cx

                mov     ah, ss:lineMask
                tst     bh
                jz      noDrawMask2
                and     ah, [ds:bp]
                inc     bp
noDrawMask2:
                lodsb
                mov     cx, ss:pixelsLeft
                
                call    WriteMonoBytes
                call    MidScanNextWin
                call    MidScanNextWinSrc
                pop     cx

                sub     cx, ss:pixelsLeft
                jcxz    null1
                call    WriteMonoBytes
null1:
                jmp     done

FillBWScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBWScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a b/w scan line of a monochrome bitmap

CALLED BY:	INTERNAL
		PutBitsSimple
PASS:		bitmap drawing vars setup by PutLineSetup
RETURN:		nothing
DESTROYED:	most everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutBWScan	proc	near

                clr     bh
                mov     ss:[bmFilled], 0        ; flag for b&w output
		jmp	fillPutCommon
PutBWScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                WriteMonoBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Write monochrome source bytes to the screen

CALLED BY:	INTERNAL
		PutBWScan
PASS:           al      - first byte to write
                ah      - first bitmap draw mask
		dh	- bit mask of bit to start with
		es:di	- frame buffer pointer
                bl      - color to use to draw
                cx      - pixels to put out
                dl      - 0 = no draw mask, FF = draw mask at ds:bp
RETURN:         bh      - 0x80
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteMonoBytes  proc    near

                test    ss:[bmFilled], 1
                jnz     filled

		and	al, ah		; apply bitmap mask
pixLoop:
                test    ah, dh          ; check next pixel
		jz	nextPixel

                clr     bl              ; C_BLACK
                test    al, dh          ; check if existing pixel is black
                                        ; or white
                jnz     black

                mov     bl, C_WHITE
black:
		mov	es:[di], bl	; store pixel color

nextPixel:
		inc	di		; next pixel
                ror     dh, 1           ; go until we hit a carry
                jnc     checkEnd

                lodsb
                                        ; read new draw mask
                test    bh, 1
                jz      checkEnd
                mov     ah, [ds:bp]
                and     ah, [ss:lineMask]
                inc     bp
checkEnd:
                and     al, ah
                dec     cx
                jnz     pixLoop
		ret

                ; draw the pixels in the selected color
filled:
		and	al, ah		; apply bitmap mask
pixLoop2:
		test	al, dh		; check next pixel
                jz      nextPixel2

		mov	bl, es:[di]
		call	ss:[modeRoutine]
		mov	es:[di], bl	; store pixel color
nextPixel2:
		inc	di		; next pixel
                ror     dh, 1           ; go until we hit a carry
                jnc     checkEnd2
                lodsb
                test    bh, 1
                jz      checkEnd2
                mov     ah, [ds:bp]
                and     ah, [ss:lineMask]
                inc     bp
                                        ; read new draw mask
checkEnd2:
                and     al, ah
                dec     cx
                jnz     pixLoop2
		ret

WriteMonoBytes  endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBWScanMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a monochrome bitmap with a store mask

CALLED BY:	see above
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutBWScanMask	proc	near

                mov     bh, 0FFh
                mov     ss:[bmFilled], 0        ; flag for b&w output
		jmp	fillPutCommon

PutBWScanMask	endp

NullBMScan	proc	near
		ret
NullBMScan	endp

VidEnds		Bitmap


NMEM <VidSegment	GetBits						>
MEM  <VidSegment	Misc						>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOneScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy one scan line of video buffer to system memory

CALLED BY:	INTERNAL
		VidGetBits

PASS:		ds:si	- address of start of scan line in frame buffer
		es:di	- pointer into sys memory where scan line to be stored
		cx	- # bytes left in buffer
		d_x1	- left side of source
		d_dx	- # source pixels
		shiftCount - # bits to shift

RETURN:		es:di	- pointer moved on past scan line info just stored
		cx	- # bytes left in buffer
			- set to -1 if not enough room to fit next scan (no
			  bytes are copied)

DESTROYED:	ax,bx,dx,si

PSEUDO CODE/STRATEGY:
		if (there's enough room to fit scan in buffer)
		   copy the scan out
		else
		   just return

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	GetOneScan
GetOneScan	proc	near
		uses	si, cx
		.enter

		; form full address, copy bytes

		cmp	cx, ss:[d_dx]		; get width to copy
		jb	noRoom
                mov     cx, ss:[d_x1]
                NextScanSrc     si, cx
		mov	cx, ss:[d_dx]
                cmp     si, ss:[lastWinPtrSrc]
                jb      notPartial
                cmp     cx, ss:[pixelsLeftSrc]
                jb      notPartial

                mov     cx, ss:[pixelsLeftSrc]
                rep movsb
                xchg    di, si
                call    MidScanNextWinSrc
                xchg    di, si
                mov     cx, ss:[d_dx]
                sub     cx, ss:[pixelsLeftSrc]
                jcxz    done
notPartial:
		rep	movsb
done:
                mov     cx, ss:[d_dx]
                add     cx, ss:[d_x1]
                PrevScanSrc     si, cx

done2:
		.leave
		ret

		; not enough room to copy scan line
noRoom:
		mov	cx, 0xffff
                jmp     done2
GetOneScan	endp

NMEM <VidEnds		GetBits						>
MEM <VidEnds		Misc						>

VidSegment	Bitmap


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ByteModeRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Various stub routines to implement mix modes

CALLED BY:	INTERNAL
		various low-level drawing routines
PASS:		dl - color
		bl - screen
RETURN:		bl - destination (byte to write out)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ByteModeRoutines	proc		near
	ForceRef ByteModeRoutines

ByteCLEAR	label near
		clr	bl
ByteNOP		label near
		ret
ByteCOPY	label  near
		mov	bl, dl
		ret
ByteAND		label  near		
		and	bl, dl
		ret
ByteINV		label  near
                push    cx
                clr     ch
                mov     cl, bl
                xchg    bx, cx
                mov     cl, ss:NOTtable[bx]
                xchg    bx, cx
                pop     cx
		ret
ByteXOR		label  near
		xor	bl, dl
		ret
ByteSET		label  near
		mov	bl, 0xff
		ret
ByteOR		label  near
		or	bl, dl
		ret
ByteModeRoutines	endp


ByteModeRout	label	 word
	nptr	ByteCLEAR
	nptr	ByteCOPY
	nptr	ByteNOP
	nptr	ByteAND
	nptr	ByteINV
	nptr	ByteXOR
	nptr	ByteSET
	nptr	ByteOR

VidEnds		Bitmap
