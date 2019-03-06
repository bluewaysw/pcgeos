COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:           vga16Raster.asm

AUTHOR:		Jim DeFrisco, Oct  8, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/ 8/92		Initial revision
        FR       9/ 1/97                16bit version        

DESCRIPTION:

	$Id: vga8Raster.asm,v 1.2 96/08/05 03:51:49 canavese Exp $

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
                shl     bx, 1                   ; pixel = 2 byte  
                NextScanSrc     si, bx
                add     ss:[bltOffsetSrc], bx
                shr     bx, 1

                cmp     si, ss:[lastWinPtrSrc]
                jb      noSrcSwitch
                cmp     cx, ss:[pixelsLeftSrc]
                jb      noSrcSwitch
                or      ss:[bltFlag],2          ; set source overflow flag

noSrcSwitch:
                ; set destination start an check overflow
                mov     bx, ss:[bmLeft]
                shl     bx, 1
                NextScan        di, bx
                add     ss:[bltOffset], bx
                shr     bx, 1

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
                rep movsw

                xchg    di, si
                call    MidScanNextWinSrc
                xchg    di, si

                pop     cx
                push    cx

                sub     cx, ss:[pixelsLeftSrc]
                jcxz    null1
                rep movsw
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
                rep movsw

                call    MidScanNextWin
                pop     cx

                shl     cx, 1                   ; 1 pixel = 2 bytes
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                shr     cx, 1

                sub     cx, ss:[pixelsLeft]
                jcxz    null2
                rep movsw
null2:
                pop     si
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt1OverSrc     label near

                shl     cx, 1                   ; 1 pixel = 2 bytes
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                shr     cx, 1

                push    di     
                push    cx                          

                mov     es, ss:[bltBufSeg]
                clr     di

                mov     bl,ss:[readWindow]              ; page already in dx
                call    SetWinPage 

                mov     cx, ss:[pixelsLeftSrc]
                rep movsw
                xchg    di, si
                call    MidScanNextWinSrc
                xchg    di, si

                pop     cx
                push    cx

                sub     cx, ss:[pixelsLeftSrc]
                jcxz    null3
                rep movsw
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

                rep movsw
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

                rep movsw

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

                rep movsw
                call    MidScanNextWin

                pop     cx
                shl     cx, 1                   ; 1 pixel = 2 bytes
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                shr     cx, 1
                sub     cx, ss:[pixelsLeft]
                jcxz    null4

                rep movsw
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

                rep movsw

                pop     cx                             
                pop     di                             
                push    si

                mov     es,ss:[writeSegment]         

                mov     ds, ss:[bltBufSeg]
                clr     si

                mov     bl,ss:[writeWindow]
                mov     dx,ss:[curWinPage]           
                call    SetWinPage             

                shl     cx, 1                   ; 1 pixlel = 2 bytes
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                shr     cx, 1

                rep movsw
                pop     si
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt1FastLeftSt  label near
                shl     cx, 1                   ; 1 pixel = 2 bytes
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                shr     cx, 1
                rep movsw
                jmp      bltEnd

;---------------------------------------------------------------------------

Blt1FastRightSt label near

                dec     cx
                shl     cx, 1                   ; 1 pixel = 2 bytes
                add     di,cx
                add     si,cx
                shr     cx, 1
                inc     cx

                std
                rep movsw
                cld
                inc     di
                inc     si
                inc     di
                inc     si

                jmp     bltEnd

;---------------------------------------------------------------------------

Blt2OverSrcRS   label near

                std
                dec     cx
                shl     cx, 1                   ; 1 pixel = 2 bytes
                add     di, cx
                add     si, cx
                shr     cx, 1
                inc     cx

                sub     cx, ss:[pixelsLeftSrc]

                push    ss:[pixelsLeftSrc]
                stc
                xchg    si,di
                call    SetNextWinSrc
                xchg    si,di
                jcxz    null5
                rep movsw
null5:
                pop     cx     
                stc
                xchg    si,di
                call    SetPrevWinSrc
                xchg    si,di
                rep movsw

                inc     si                      ; 1 pixel = 2 bytes
                inc     di
                inc     si
                inc     di

                cld
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt2OverDestRS  label near

                std
                dec     cx
                shl     cx, 1                   ; 1 pixel = 2 bytes
                add     di, cx
                add     si, cx
                shr     cx, 1
                inc     cx

                sub     cx, ss:[pixelsLeft]
                push    ss:[pixelsLeft]
                stc
                call    SetNextWin
                jcxz    null6
                rep movsw
null6:
                pop     cx
                stc
                call    SetPrevWin

                rep movsw
                inc     si                      ; 1 pixel = 2 bytes
                inc     di
                inc     si
                inc     di
                cld
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt2OverBothRS  label near

                std
                dec     cx
                shl     cx, 1                   ; 1 pixel = 2 bytes
                add     di, cx
                add     si, cx
                shr     cx, 1
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
                rep movsw
null7:
                pop     cx

                push    ss:[pixelsLeftSrc]
                stc

                call    SetPrevWin
                sub     cx, ss:[pixelsLeftSrc]
                jcxz    null8
                rep movsw
null8:
                pop     cx
                stc
                xchg    si,di
                call    SetPrevWinSrc
                xchg    si,di
                rep movsw

                inc     si                      ; 1 pixel = 2 bytes
                inc     di
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
                rep movsw
null9:
                pop     cx

                push    ss:[pixelsLeft]
                stc
                xchg    si,di
                call    far ptr SetPrevWinSrc
                xchg    si,di

                sub     cx, ss:[pixelsLeft]
                jcxz    null10
                rep movsw
null10:
                pop     cx

                stc
                call    SetPrevWin
                rep movsw
                cld

                inc     si                      ; 1 pixel = 2 bytes
                inc     di
                inc     si
                inc     di

                jmp     bltEnd

;---------------------------------------------------------------------------

Blt2OverSrc     label near

                push    cx
                mov     cx, ss:[pixelsLeftSrc]
                rep movsw

                xchg    di,si
                call    MidScanNextWinSrc
                xchg    di,si
                
                pop     cx
                shl     cx, 1                   ; 1 pixel = 2 bytes
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                shr     cx, 1

                sub     cx,ss:[pixelsLeftSrc]
                jcxz    loop11
                rep movsw
loop11:
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt2OverDest    label near

                push    cx
                mov     cx, ss:[pixelsLeft]
                rep movsw

                call   MidScanNextWin
    
                pop     cx
                shl     cx, 1                   ; 1 pixel = 2 bytes
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                shr     cx, 1
                sub     cx,ss:[pixelsLeft]
                jcxz    loop12        
                rep movsw
loop12:
                jmp     bltEnd

;---------------------------------------------------------------------------

Blt2OverBoth    label near
                push    cx
                mov     cx, ss:[pixelsLeft]
                cmp     cx, ss:[pixelsLeftSrc]
                jbe     ob

                mov     cx, ss:[pixelsLeftSrc]
                rep movsw
                xchg    si,di
                call    MidScanNextWinSrc
                xchg    si,di

                mov     cx, ss:[pixelsLeft]
                sub     cx, ss:[pixelsLeftSrc]
                jcxz    loop13
                rep movsw
loop13:
                call    MidScanNextWin
                pop     cx

                shl     cx, 1                   ; 1 pixel = 2 bytes
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                shr     cx, 1

                sub     cx, ss:[pixelsLeft]
                jcxz    loop14
                rep movsw
loop14:
                jmp     bltEnd
ob:
                rep movsw
                call    MidScanNextWin
                mov     cx, ss:[pixelsLeftSrc]
                sub     cx, ss:[pixelsLeft]
                jcxz    loop15
                rep movsw
loop15:
                xchg    si, di
                call    MidScanNextWinSrc
                xchg    si, di
                pop     cx

                shl     cx, 1                   ; 1 pixel = 2 bytes
                add     ss:[bltOffsetSrc], cx
                add     ss:[bltOffset], cx
                shr     cx, 1

                sub     cx, ss:[pixelsLeftSrc]
                jcxz    loop16
                rep movsw
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

PutColor24Scan  proc    near

                mov     bx, ss:[bmLeft]           
                mov     ax, ss:[d_x1]     
                sub     bx, ax     
                mov     cx, bx

                add     si, bx
                add     si, bx
                add     si, bx

                mov     dl, 0FFh
                mov     bx, 0FFFFh

Color24Common   label   near

                ; dl - mask of bitmap
                ; bx - index to mask
                ; cx - offset from left

                push    bx

                ; read mask byte
                and     dl,ss:[lineMask]

                ; mask for testing mask
                and     cl,007h                     
                mov     dh,080h                     
                shr     dh,cl                       

                ; count of pixel per scan
                mov     cx,ss:[bmRight]      
                sub     cx,ss:[bmLeft]       
                inc     cx       

                mov     bx,ss:[bmLeft]      
                shl     bx, 1

                NextScan        di, bx

                cmp     di, ss:[lastWinPtr]
                jb      notPartial

                cmp     cx, ss:[pixelsLeft]
                jae     doPartial

notPartial:
                lodsb                   
                mov     bh, al
                lodsw
                test    dh,dl            
                je      noPix       

                mov     bl, ah
                shr     bx, 1
                shr     bx, 1
                shr     bx, 1

                shl     al, 1
                rcl     bh, 1
                shl     al, 1
                rcl     bh, 1

                and     al, 0E0h
                and     bl, 01Fh
                or      bl, al

                mov     es:[di], bx

noPix:
                inc     di
                inc     di
                shr     dh, 1                  

                jnc     nextPix      
                mov     dh, 080h

                pop     bx
                or      bx, bx

                js      noLineMask

                mov     dl, [bx]                    
                and     dl, ss:[lineMask]
                inc     bx                         
noLineMask:
                push    bx

nextPix:
                loop    notPartial                    

done:
                pop     bx
                mov     cx, ss:[bmRight]
                inc     cx
                shl     cx
                PrevScan        di, cx

                retn                               

doPartial:
                push    cx   
                mov     cx,ss:[pixelsLeft]          

partLoop1:
                lodsb                  
                mov     bh, al
                lodsw
                test    dh,dl            
                jz      partNoPix          

                mov     bl, ah
                shr     bx, 1
                shr     bx, 1
                shr     bx, 1

                shl     al, 1
                rcl     bh, 1
                shl     al, 1
                rcl     bh, 1

                and     al, 0E0h
                and     bl, 01Fh
                or      bl, al
                mov     es:[di], bx

partNoPix:
                inc     di
                inc     di                

                shr     dh, 1
                jnc     partNxtPix                

                mov     dh, 080h
                pop     ax
                pop     bx
                or      bx, bx
                js      partNoLnMsk

                mov     dl, [bx]            
                and     dl, ss:[lineMask]
                inc     bx
partNoLnMsk:        
                push    bx
                push    ax
partNxtPix:
                loop    partLoop1

                call    MidScanNextWin     

                pop     cx
                sub     cx,ss:[pixelsLeft]

                jcxz    done

                jmp     notPartial                  

PutColor24Scan  endp

PutColor24ScanMask      proc    near

                mov     bx, ss:[bmLeft]
                mov     ax, ss:[d_x1]        
                sub     bx, ax               
                mov     dx, bx           
                mov     cx, bx          

                xchg    si, bx        

                add     si, bx      
                add     si, dx
                add     si, dx

                sub     bx, ss:[bmMaskSize]              

                ; override mask pixel
                shr     dx, 1            
                shr     dx, 1
                shr     dx, 1                          

                add     bx, dx                  

                ; mask for testing mask
                and     cl, 007h             
                mov     dh, 080h                
                shr     dh, cl               

                ; read mask byte
                mov     dl, ds:[bx]                    
                inc     bx                          
                jmp     Color24Common

PutColor24ScanMask      endp

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

                shl     bx, 1
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
                shl     cx, 1
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

mapPalette:
                test    dh, 080h
                jz      nopix2

		lodsb				; get the first byte

                push    ax
                clr     ah
		push	es

                mov     bx, segment transPalette
                mov     es, bx
                mov     bx, offset transPalette

                shl     ax, 1
                add     bx, ax

                mov     ax, [es:bx]
		pop	es
                mov     [es:di], ax

                pop     ax
                jmp     ok2

nopix2:
                inc     si
ok2:
                inc     di
                inc     di
                rol     dh                      ; rotate line mask

		loop	mapPalette
                ret

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
                shl     ax, 1
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
                shl     cx, 1
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

mapPalette:
		lodsb
		test	dl, dh			; do this pixel ?
		jz	paletteNextPixel

                push    ax
                clr     ah
                push    es, bx

                mov     bx, segment transPalette
                mov     es, bx
                mov     bx, offset transPalette

                shl     ax, 1
                add     bx, ax

                mov     ax, [es:bx]
                pop     es, bx
                mov     [es:di], ax

                pop     ax

paletteNextPixel:
		inc	di
                inc     di
		shr	dh, 1			; move test bit down
		jc	paletteReloadTester	;  until we need some more
paletteHaveTester:
		loop	mapPalette
                ret

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

                shl     bx, 1
                NextScan        di, bx          ; add to screen offset too
                shr     bx,1

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
                shl     ax, 1
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

		; we're all setup.  See if we're taking pixels from front or
		; rear (check shift value)

		test	dl, 1			; see if starting odd or even
		jz	paletteEvenLoop

		; do first one specially
		lodsb

                rol     dh
                jnc     maskLoop5

                push    ax
                clr     ah
		and	al, 0xf
		push	es

                mov     bx, segment transPalette
                mov     es, bx
                mov     bx, offset transPalette

                shl     ax, 1
                add     bx, ax

                mov     ax, [es:bx]
		pop	es
                mov     [es:di], ax

                pop     ax

maskLoop5:
                inc     di
                inc     di
		dec	bp
		jz	done

		; specially, though.
paletteEvenLoop:
		lodsb				; get next byte
		mov	ah, al			; split them up
		shr	al, cl			; align stuff
		and	ax, 0x0f0f		; isolate pixels

                sub     bp, 2
                js      lastByte

                rol     dh
                jnc     maskLoop6

                push    ax
                clr     ah
		push	es

                mov     bx, segment transPalette
                mov     es, bx
                mov     bx, offset transPalette

                shl     ax, 1
                add     bx, ax

                mov     ax, [es:bx]
		pop	es
                mov     [es:di], ax

                pop     ax

maskLoop6:
                inc     di
                inc     di
		xchg	ah,al
                rol     dh
                jnc     maskLoop7

                push    ax
                clr     ah
		and	al, 0xf
		push	es

                mov     bx, segment transPalette
                mov     es, bx
                mov     bx, offset transPalette

                shl     ax, 1
                add     bx, ax

                mov     ax, [es:bx]
		pop	es
                mov     [es:di], ax

                pop     ax

maskLoop7:
                inc     di
                inc     di

		tst	bp			; if only one byte to do...
		jnz	paletteEvenLoop
		jmp	done
                
		; odd number of bytes to do.  Last one here...
lastByte:
                rol     dh
                jnc     maskLoop4      

                push    ax
                clr     ah
		and	al, 0xf
		push	es

                mov     bx, segment transPalette
                mov     es, bx
                mov     bx, offset transPalette

                shl     ax, 1
                add     bx, ax

                mov     ax, [es:bx]
		pop	es
                mov     [es:di], ax

                pop     ax

maskLoop4:
                inc     di
                inc     di
done:
                ret


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

                shl     ax, 1
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
                shl     ax, 1
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
                
		; we're all setup.  See if we're taking pixels from front or
		; rear (check shift value)

		test	dl, 1			; see if starting odd or even
		jz	paletteEvenLoop

		; do first one specially

		lodsb
		test	dh, ch			; mask bit set ?
		jz	paletteDoneFirst

                push    ax
                clr     ah
                and     al, 00Fh
                push    es, bx

                mov     bx, segment transPalette
                mov     es, bx
                mov     bx, offset transPalette

                shl     ax, 1
                add     bx, ax

                mov     ax, [es:bx]
                pop     es, bx
                mov     [es:di], ax
                pop     ax

paletteDoneFirst:
		inc	di
                inc     di
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

                push    ax
                clr     ah
                push    es, bx

                mov     bx, segment transPalette
                mov     es, bx
                mov     bx, offset transPalette

                shl     ax, 1
                add     bx, ax

                mov     ax, [es:bx]
                pop     es, bx 
                mov     [es:di], ax

                pop     ax

paletteDoSecond:
		inc	di
                inc     di

                xor     dl, 1
                shr     ch, 1
		dec	bp			; one less to go
		jz	done
		test	dh, ch
		jz	paletteNextPixel
		mov	al, ah			; get second pixel value in al

                push    ax
                clr     ah
                push    es, bx

                mov     bx, segment transPalette
                mov     es, bx
                mov     bx, offset transPalette

                shl     ax, 1
                add     bx, ax

                mov     ax, [es:bx]
                pop     es, bx
                mov     [es:di], ax

                pop     ax

paletteNextPixel:
		inc	di
                inc     di
                xor     dl, 1
		shr	ch, 1
		jc	paletteReloadTester
paletteHaveTester:
		dec	bp
		jnz	paletteEvenLoop
done:
                ret

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

fillPutCommon	label	near
                
		push	bp
                push    bx
		mov	bx, ss:[bmLeft]
		mov	ax, ss:[bmRight]

                shl     bx, 1
                NextScanBoth    di, bx
                shr     bx, 1

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
                shl     ax, 1
                PrevScanBoth        di, ax
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

                push    bx
                clr     bx              ; C_BLACK
                test    al, dh          ; check if existing pixel is black
                                        ; or white
                jnz     black

                mov     bx, 0FFFFh
black:
                mov     es:[di], bx     ; store pixel color

                pop     bx
nextPixel:
		inc	di		; next pixel
                inc     di
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

                push    bx
                mov     bx, es:[di]
		call	ss:[modeRoutine]
                mov     es:[di], bx     ; store pixel color
                pop     bx
nextPixel2:
		inc	di		; next pixel
                inc     di
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
                mov     ax, ss:[d_dx]
                shl     ax
                add     ax, ss:[d_dx]

                cmp     cx, ax           ; get width to copy
                LONG jb      noRoom
                mov     cx, ss:[d_x1]
                shl     cx
                NextScanSrc     si, cx
		mov	cx, ss:[d_dx]
                cmp     si, ss:[lastWinPtrSrc]
                jb      notPartial
                cmp     cx, ss:[pixelsLeftSrc]
                jb      notPartial

                mov     cx, ss:[pixelsLeftSrc]

getLoop1:
                lodsw

                mov     bx, ax
                mov     al, ah
                shl     al
                and     al, 0F8h
                stosb

                mov     ax, bx
                shr     ax
                shr     ax
                and     al, 0F8h
                stosb

                mov     al, bl
                shl     al
                shl     al
                shl     al
                stosb

                loop    getLoop1

                xchg    di, si
                call    MidScanNextWinSrc
                xchg    di, si
                mov     cx, ss:[d_dx]
                sub     cx, ss:[pixelsLeftSrc]
                jcxz    done
notPartial:
                lodsw

                mov     bx, ax
                mov     al, ah
                shl     al
                and     al, 0F8h
                stosb

                mov     ax, bx
                shr     ax
                shr     ax
                and     al, 0F8h
                stosb

                mov     al, bl
                shl     al
                shl     al
                shl     al
                stosb

                loop    notPartial
done:
                mov     cx, ss:[d_dx]
                add     cx, ss:[d_x1]
                shl     cx, 1
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
                clr     bx
ByteNOP		label near
		ret
ByteCOPY	label  near
                mov     bx, ss:[currentColor]
		ret
ByteAND		label  near		
                and     bx, ss:[currentColor]
		ret
ByteINV		label  near
                xor     bx, 07FFFh
		ret
ByteXOR		label  near
                xor     bx, ss:[currentColor]
		ret
ByteSET		label  near
                mov     bx, 07FFFh
		ret
ByteOR		label  near
                or      bx, ss:[currentColor]
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
