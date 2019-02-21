COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:           vga24Raster.asm

AUTHOR:		Jim DeFrisco, Oct  8, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/ 8/92		Initial revision
        FR       9/15/97                24bit version        

DESCRIPTION:

        $Id: vga24Raster.asm $

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

                push    ax, dx
                mov     ax, bx
                mul     ss:[pixelBytes]
                NextScanSrc     si, ax
                add     ss:[bltOffsetSrc], ax
                pop     ax, dx

                cmp     si, ss:[lastWinPtrSrc]
                jb      noSrcSwitch
                cmp     cx, ss:[pixelsLeftSrc]
                jb      noSrcSwitch
                or      ss:[bltFlag],2          ; set source overflow flag

noSrcSwitch:
                ; set destination start an check overflow
                mov     bx, ss:[bmLeft]

                push    ax, dx
                mov     ax, bx
                mul     ss:[pixelBytes]
                NextScan        di, ax
                add     ss:[bltOffset], ax
                pop     ax, bx

                cmp     di, ss:[lastWinPtr]
                jb      noDestSwitch
                cmp     cx, ss:[pixelsLeft]
                jb      noDestSwitch
                or      ss:[bltFlag],4          ; set dest overflow flag

noDestSwitch:
                ; same readWin and writeWin
;                mov     ax, {word} ss:[writeWindow]   
;                cmp     al,ah                       
;                je      diffWindow
;                or      ss:[bltFlag], 32        ; same window flag         

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

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                bltEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       reset ptr and windows to initial settings

CALLED BY:	INTERNAL

PASS:           ss:[bltOffset]          - bytes moved in read window
                ss:[bltOffsetSrc]       - bytes moved in write window


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

bltEnd          label near

                ; switch page back
                mov     ax, ss:[bltOffset]
                PrevScan        di, ax
                mov     ax, ss:[bltOffsetSrc]
                PrevScanSrc     si, ax
                .leave
                ret

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Blt1OverBoth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       blt a single scan line with one windows for read and write
                from left to right with page switch in both windows

CALLED BY:	INTERNAL

PASS:           cx      - pixel to move
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Blt1OverBoth    label near

                push    di                      ; save dest offset
                push    cx

                mov     es, ss:[bltBufSeg]
                clr     di
                                                ; winPage already in dx
                mov     bl, ss:[readWindow]  
                call    SetWinPage    

                mov     cx, ss:[pixelsLeftSrc]
                jcxz    null0

loop0:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     si, ss:[pixelBytes]
                add     di, 3
                loop    loop0

null0:

                pop     cx
                push    cx

                sub     cx, ss:[pixelsLeftSrc]

                xchg    di, si
                call    GetSplitedPixel
                xchg    di, si

                xchg    al, bl
                mov     es:[di], ax
                mov     es:[di+2], bl
                add     di, 3

                jcxz    null1
loop1:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     si, ss:[pixelBytes]
                add     di, 3
                loop    loop1

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
                jcxz    null2

loop2:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, 3
                loop    loop2

null2:
                pop     cx

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     ss:[bltOffsetSrc], ax
                add     ss:[bltOffset], ax
                pop     ax, dx

                sub     cx, ss:[pixelsLeft]

                mov     ax, ds:[si]
                mov     bl, ds:[si+2]
                xchg    al, bl
                add     si, 3
                call    PutSplitedPixel
                jcxz    null3

loop3:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, 3
                loop    loop3

null3:
                pop     si
                jmp     bltEnd

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Blt1OverSrc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       blt a single scan line with one windows for read and write
                from left to right with page switch in the source window

CALLED BY:	INTERNAL

PASS:           cx      - pixel to move
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Blt1OverSrc     label near

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     ss:[bltOffsetSrc], ax
                add     ss:[bltOffset], ax
                pop     ax, dx

                push    di     
                push    cx                          

                mov     es, ss:[bltBufSeg]
                clr     di

                mov     bl,ss:[readWindow]              ; page already in dx
                call    SetWinPage 

                mov     cx, ss:[pixelsLeftSrc]
                jcxz    null4

loop4:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     si, ss:[pixelBytes]
                add     di, 3
                loop    loop4

null4:
                pop     cx
                push    cx

                sub     cx, ss:[pixelsLeftSrc]

                xchg    si, di
                call    GetSplitedPixel
                xchg    si, di

                xchg    al, bl
                mov     es:[di], ax
                mov     es:[di+2], bl
                add     di, 3

                jcxz    null5
loop5:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     si, ss:[pixelBytes]
                add     di, 3
                loop    loop5
null5:
                pop     cx                             
                pop     di
                push    si

                mov     es,ss:[writeSegment]          

                mov     ds, ss:[bltBufSeg]
                clr     si

                mov     bl,ss:[writeWindow]
                mov     dx, ss:[curWinPage]        
                call    SetWinPage              

loop6:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, 3
                loop    loop6

                pop     si
                jmp     bltEnd

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Blt1OverDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       blt a single scan line with one windows for read and write
                from left to right with page switch in the destination
                window

CALLED BY:	INTERNAL

PASS:           cx      - pixel to move
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Blt1OverDest    label near

                push    di
                push    cx     

                mov     es, ss:[bltBufSeg]
                clr     di
                mov     bl, ss:[readWindow]             ; page already in dx
                call    SetWinPage     

loop8:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     si, ss:[pixelBytes]
                add     di, 3
                loop    loop8

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
                jcxz    null9

loop9:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, 3
                loop    loop9

null9:

                pop     cx

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     ss:[bltOffsetSrc], ax
                add     ss:[bltOffset], ax
                pop     ax, dx

                sub     cx, ss:[pixelsLeft]

                mov     ax, ds:[si]
                mov     bl, ds:[si+2]
                xchg    al, bl
                add     si, 3
                call    PutSplitedPixel
                jcxz    null10

loop10:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, 3
                loop    loop10
null10:
                pop     si
                jmp     bltEnd

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Blt1Fast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       blt a single scan line with one windows for read and write
                from left to right with both frames completly on
                different windows

CALLED BY:	INTERNAL

PASS:           cx      - pixel to move
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Blt1Fast        label near

                push    di
                push    cx              

                mov     es, ss:[bltBufSeg]
                clr     di

                mov     bl,ss:[readWindow]              ; page already in dx
                call    SetWinPage                  

loop11:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     si, ss:[pixelBytes]
                add     di, 3
                loop    loop11

                pop     cx                             
                pop     di                             
                push    si

                mov     es,ss:[writeSegment]         

                mov     ds, ss:[bltBufSeg]
                clr     si

                mov     bl,ss:[writeWindow]
                mov     dx,ss:[curWinPage]           
                call    SetWinPage             

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     ss:[bltOffsetSrc], ax
                add     ss:[bltOffset], ax
                pop     ax, dx

loop12:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, 3
                loop    loop12
                pop     si
                jmp     bltEnd

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Blt1LeftSt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       blt a single scan line with one windows for read and write
                from left to right with both frames completly in the same
                window

CALLED BY:	INTERNAL

PASS:           cx      - pixel to move
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Blt1FastLeftSt  label near

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     ss:[bltOffsetSrc], ax
                add     ss:[bltOffset], ax
                pop     ax, dx

loop13:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop13

                jmp      bltEnd

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Blt1FastRightSt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       blt a single scan line with one windows for read and write
                from right to left with both frames completly in the same
                window

CALLED BY:	INTERNAL

PASS:           cx      - pixel to move
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Blt1FastRightSt label near

                dec     cx

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     di,ax
                add     si,ax
                pop     ax, dx
                inc     cx

loop14:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop14

                cld
                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]

                jmp     bltEnd

comment @

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Blt2OverSrcRS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       blt a single scan line with 2 windows for read and write
                from right to left with page switch in source window

CALLED BY:	INTERNAL

PASS:           cx      - pixel to move
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Blt2OverSrcRS   label near

                dec     cx

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     di, ax
                add     si, ax
                pop     ax, dx

                inc     cx

                sub     cx, ss:[pixelsLeftSrc]

                push    ss:[pixelsLeftSrc]
                push    ss:[restBytesSrc]
                stc
                xchg    si,di
                call    SetNextWinSrc
                xchg    si,di
                jcxz    null15

                pop     ax
                push    ax
                cmp     ax, 0
                jz      loop15

                dec     cx
                jcxz    null15

loop15:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop15
null15:
                pop     cx
                stc
                xchg    si,di
                call    GetSplitedPixelRS
                xchg    si,di

                xchg    al, bl
                mov     es:[di], ax
                mov     es:[di+2], bl
                add     di, ss:[pixelBytes]

                jcxz    null16
loop16:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop16

null16:
                add     si, ss:[pixelBytes]
                add     di, ss:[pixelBytes]

                jmp     bltEnd

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Blt2OverDestRS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       blt a single scan line with 2 windows for read and write
                from right to left with page switch in destination
                window

CALLED BY:	INTERNAL

PASS:           cx      - pixel to move
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Blt2OverDestRS  label near

                dec     cx

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     di, ax
                add     si, ax
                pop     ax, dx

                inc     cx

                sub     cx, ss:[pixelsLeft]
                push    ss:[pixelsLeft]
                push    ss:[restBytes]
                
                stc
                call    SetNextWin
                jcxz    null16

                pop     ax
                push    ax
                cmp     ax, 0
                jz      loop17
                dec     cx
                jcxz    null17

loop17:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop17
null17:
                pop     cx

                mov     ax, ds:[si]
                mov     bl, ds:[si+2]
                xchg    al, bl
                add     si, ss:[pixelBytes]

                call    PutSplitedPixelRS

                jcxz    null18

loop18:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop18

null18:
                add     si, ss:[pixelBytes]
                add     di, ss:[pixelBytes]
                jmp     bltEnd

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Blt2OverBothRS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       blt a single scan line with 2 windows for read and write
                from right to left with page switch in both windows

CALLED BY:	INTERNAL

PASS:           cx      - pixel to move
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Blt2OverBothRS  label near

                dec     cx

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     di, ax
                add     si, ax
                pop     ax, dx

                inc     cx
                push    cx

                mov     cx, ss:[pixelsLeft]
                cmp     cx, ss:[pixelsLeftSrc]
                jb      obrs
                je      equal

                pop     cx
                sub     cx, ss:[pixelsLeft]
                push    ss:[pixelsLeft]
                push    ss:[restBytes]
                stc
                call    SetNextWin
                stc
                xchg    si,di
                call    SetNextWinSrc
                xchg    si,di
                jcxz    null17
loop19:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop19
null19:
                pop     cx

                push    ss:[pixelsLeftSrc]
                push    ss:[restBytesSrc]
                sub     cx, ss:[pixelsLeftSrc]

                mov     ax, ds:[si]
                mov     bl, ds:[si+2]
                xchg    al, bl
                add     si, ss:[pixelBytes]

                call    PutSplitedPixelRS

                jcxz    null18
loop20:

                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop20
null20:
                pop     cx
                xchg    si,di
                call    GetSplitedPixelRS
                xchg    si,di

                xchg    al, bl
                mov     es:[di], ax
                mov     es:[di+2], bl
                add     di, ss:[pixelBytes]

                jcxz    null21
loop21:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop21
null21:
                add     si, ss:[pixelBytes]
                add     di, ss:[pixelBytes]

                cld
                jmp     bltEnd

obrs:
                pop     cx
                sub     cx, ss:[pixelsLeftSrc]
                push    ss:[pixelsLeftSrc]
                push    ss:[restBytesSrc]

                stc
                call    SetNextWin
                stc
                xchg    si,di
                call    SetNextWinSrc
                xchg    si,di

                jcxz    null22

loop22:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop22
null22:
                pop     cx

                push    ss:[pixelsLeft]
                push    ss:[restBytes]
                sub     cx, ss:[pixelsLeft]

                xchg    si,di
                call    GetSplitedPixelRS
                xchg    si,di

                xchg    al, bl
                mov     es:[di], ax
                mov     es:[di+2], bl
                add     di, ss:[pixelBytes]
                jcxz    null23

loop23:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop23

null23:
                pop     cx

                mov     ax, ds:[si]
                mov     bl, ds:[si+2]
                xchg    al, bl
                add     si, ss:[pixelBytes]

                call    PutSplitedPixelRS

                jcxz    null24

loop24:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop24

null24:
                add     si, ss:[pixelBytes]
                add     di, ss:[pixelBytes]

                jmp     bltEnd

equal:
                pop     cx
                sub     cx, ss:[pixelsLeftSrc]
                push    ss:[pixelsLeftSrc]
                push    ss:[restBytesSrc]

                stc
                call    SetNextWin
                stc
                xchg    si,di
                call    SetNextWinSrc
                xchg    si,di

                jcxz    null22b

loop22b:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop22b
null22b:
                pop     cx

                push    ss:[pixelsLeft]
                push    ss:[restBytes]
                sub     cx, ss:[pixelsLeft]
                
                push    cx
                xchg    si,di
                call    GetSplitedPixelRS
                xchg    si,di
                pop     cx

                call    PutSplitedPixelRS
                jcxz    null23b

loop23b:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                sub     di, ss:[pixelBytes]
                sub     si, ss:[pixelBytes]
                loop    loop23b

null23b:
                jmp     bltEnd

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Blt2OverSrc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       blt a single scan line with 2 windows for read and write
                from left to right with page switch in source window

CALLED BY:	INTERNAL

PASS:           cx      - pixel to move
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Blt2OverSrc     label near

                push    cx
                mov     cx, ss:[pixelsLeftSrc]
                jcxz    null25
loop25:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop25
null25:
                pop     cx

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     ss:[bltOffsetSrc], ax
                add     ss:[bltOffset], ax
                pop     ax, dx

                sub     cx,ss:[pixelsLeftSrc]

                xchg    di,si
                call    GetSplitedPixel
                xchg    di,si

                xchg    al, bl
                mov     es:[di], ax
                mov     es:[di+2], bl
                add     di, ss:[pixelBytes]

                jcxz    null26

loop26:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop26
null26:
                jmp     bltEnd

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Blt2OverDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       blt a single scan line with 2 windows for read and write
                from left to rightt with page switch in destination
                window

CALLED BY:	INTERNAL

PASS:           cx      - pixel to move
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Blt2OverDest    label near

                push    cx
                mov     cx, ss:[pixelsLeft]
                jcxz    null27
loop27:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop27
null27:
    
                pop     cx

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     ss:[bltOffsetSrc], ax
                add     ss:[bltOffset], ax
                pop     ax, dx
                
                sub     cx,ss:[pixelsLeft]

                mov     ax, ds:[si]
                mov     bl, ds:[si+2]
                xchg    al, bl
                add     si, ss:[pixelBytes]

                call    PutSplitedPixel

                jcxz    null28
loop28:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop28
         
null28:
                jmp     bltEnd

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Blt2OverBoth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       blt a single scan line with 2 windows for read and write
                from left to right with page switch in both windows

CALLED BY:	INTERNAL

PASS:           cx      - pixel to move
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        FR      9/97            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Blt2OverBoth    label near
                push    cx
                mov     cx, ss:[pixelsLeft]
                cmp     cx, ss:[pixelsLeftSrc]
                jz      equal2
                jb      ob

                mov     cx, ss:[pixelsLeftSrc]
                jcxz    null29
loop29:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop29
null29:

                mov     cx, ss:[pixelsLeft]
                sub     cx, ss:[pixelsLeftSrc]

                xchg    si,di
                call    GetSplitedPixel
                xchg    si,di

                xchg    al, bl
                mov     es:[di], ax
                mov     es:[di+2], bl
                add     di, ss:[pixelBytes]

                jcxz    null30

loop30:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop30

null30:
                pop     cx

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     ss:[bltOffsetSrc], ax
                add     ss:[bltOffset], ax
                pop     ax, dx

                sub     cx, ss:[pixelsLeft]

                mov     ax, ds:[si]
                mov     bl, ds:[si+2]
                xchg    al, bl
                add     si, ss:[pixelBytes]

                call    PutSplitedPixel

                jcxz    null31
loop31:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop31
null31:
                jmp     bltEnd

ob:
                jcxz    null32
loop32:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop32
null32:
                mov     cx, ss:[pixelsLeftSrc]
                sub     cx, ss:[pixelsLeft]

                mov     ax, ds:[si]
                mov     bl, ds:[si+2]
                xchg    al, bl
                add     si, ss:[pixelBytes]

                call    PutSplitedPixel

                jcxz    null33

loop33:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop33
null33:
                pop     cx

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                add     ss:[bltOffsetSrc], ax
                add     ss:[bltOffset], ax
                pop     ax, dx

                sub     cx, ss:[pixelsLeftSrc]

                xchg    si, di
                call    GetSplitedPixel
                xchg    si, di

                xchg    al, bl
                mov     es:[di], ax
                mov     es:[di+2], bl
                add     di, ss:[pixelBytes]

                jcxz    null34
loop34:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop34
null34:
                jmp     bltEnd

equal2:
                jcxz    null35
loop35:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop35
null35:
                pop     cx
                sub     cx, ss:[pixelsLeft]

                push    cx
                xchg    si, di
                call    GetSplitedPixel
                xchg    si, di
                pop     cx
                call    PutSplitedPixel

                jcxz    null36

loop36:
                mov     ax, ds:[si]
                mov     es:[di], ax
                mov     al, ds:[si+2]
                mov     es:[di+2], al

                add     di, ss:[pixelBytes]
                add     si, ss:[pixelBytes]
                loop    loop36
null36:
                jmp     bltEnd

BltSimpleLine	endp

PutSplitedPixelRS       proc    near

                PrevScan        di, ss:[pixelBytes]

                call    PutSplitedPixel

                PrevScan        di, ss:[pixelBytes]

                ret

PutSplitedPixelRS       endp

GetSplitedPixelRS       proc    near

                PrevScan        di, ss:[pixelBytes]

                call    GetSplitedPixel

                PrevScan        di, ss:[pixelBytes]

                ret

GetSplitedPixelRS       endp
@
BltSimpleLine	endp


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

                push    ax, dx
                mov     ax, bx
                mul     ss:[pixelBytes]
                NextScan        di, ax
                pop     ax, dx

                cmp     di, ss:[lastWinPtr]
                jb      notPartial

                cmp     cx, ss:[pixelsLeft]
                jae     doPartial

notPartial:
                lodsb
                mov     bl, al
                lodsw

                test    dh, dl
                je      noPix

                mov     es:[di+2], bl
                xchg    al, ah
                mov     es:[di], ax

noPix:
                add     di, ss:[pixelBytes]
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
                mov     ax, ss:[bmRight]
                inc     ax

                push    ax, dx
                mul     ss:[pixelBytes]
                PrevScan        di, ax
                pop     ax, dx

                retn                               

doPartial:
                push    cx   
                mov     cx,ss:[pixelsLeft]          
                jcxz    null1
partLoop1:
                lodsb
                mov     bl, al
                lodsw

                test    dh, dl
                je      partNoPix

                mov     es:[di+2], al
                xchg    al, ah
                mov     es:[di], ax

partNoPix:
                add     di, ss:[pixelBytes]

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
null1:

                pop     cx
                sub     cx,ss:[pixelsLeft]

                lodsb
                mov     bl, al
                lodsw
                xchg    al, ah
                xchg    al, bl

                test    dh, dl
                call    PutSplitedPixelMask

                shr     dh, 1
                jnc     partNxtPix2

                mov     dh, 080h
                pop     bx
                or      bx, bx
                js      partNoLnMsk2

                mov     dl, [bx]            
                and     dl, ss:[lineMask]
                inc     bx
partNoLnMsk2:        
                push    bx
partNxtPix2:

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

                push    ax, dx
                mov     ax, bx
                mul     ss:[pixelBytes]
                NextScan        di, ax          ; es:di -> dest byte
                pop     ax, dx

                cmp     di, ss:[lastWinPtr]
                jb      notPartial

                cmp     cx, ss:[pixelsLeft]
                jae     doPartial
notPartial:
                call    PutCol8ScanLow
done:
                mov     ax, ss:[bmRight]
                inc     ax
                push    ax, dx
                mul     ss:[pixelBytes]
                PrevScan        di, ax
                pop     ax, dx

		ret

doPartial:
                push    cx
                mov     cx, ss:[pixelsLeft]
                jcxz    null0

                call    PutCol8ScanLow
null0:
                pop     cx
                sub     cx, ss:[pixelsLeft]

		lodsb				; get the first byte

                push    ax, bx
                clr     ah
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah

                test    dh, 0x80
                call    PutSplitedPixelMask 
                pop     ax, bx
                rol     dh

                jcxz    null1
noSplit:
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

                push    ax, bx
                clr     ah
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah
                mov     es:[di+1], ax
                mov     es:[di], bl

                pop     ax, bx
                jmp     ok2

nopix2:
                inc     si
ok2:
                add     di, ss:[pixelBytes]
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

                push    ax, dx
                mul     ss:[pixelBytes]
                NextScan        di, ax
                pop     ax, dx

                cmp     di, ss:[lastWinPtr]
                jb      notPartial

                cmp     cx, ss:[pixelsLeft]
                jae     doPartial

notPartial:
                call    PutCol8ScanMaskLow
done:
                mov     ax, ss:[bmRight]
                inc     ax
                push    ax, dx
                mul     ss:[pixelBytes]
                PrevScan        di, ax
                pop     ax, dx

                ret

doPartial:
                push    cx
                mov     cx, ss:[pixelsLeft]
                jcxz    null0
                call    PutCol8ScanMaskLow
null0:
                pop     cx
                sub     cx, ss:[pixelsLeft]

		lodsb

                push    ax, bx
                clr     ah
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah

		test	dl, dh			; do this pixel ?
                call    PutSplitedPixelMask 

                pop     ax, bx

		shr	dh, 1			; move test bit down
                jnc     go

		mov	dl, ds:[bx]		; load next mask byte
                and     dl, ss:[lineMask]
                inc	bx
		mov	dh, 0x80
go:
                jcxz    null1
noSplit:
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

                push    ax, bx
                clr     ah
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah
                mov     es:[di+1], ax
                mov     es:[di], bl

                pop     ax, bx

paletteNextPixel:
                add     di, ss:[pixelBytes]
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

                push    ax, dx
                mov     ax, bx
                mul     ss:[pixelBytes]
                NextScan        di, ax          ; add to screen offset too
                pop     ax, dx

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
                mul     ss:[pixelBytes]

                PrevScan        di, ax

		.leave
		ret

doPartial:
                push    bp
                mov     bp, ss:[pixelsLeft]
                tst     bp
                jz      null0

                call    PutColScanLow

		test	dl, 1			; see if starting odd or even
                jz      null0
                dec     si
null0:
                pop     bp
                sub     bp, ss:[pixelsLeft]

                lodsb
                test    dl, 1
                jnz     noteven
                shr     al, cl
noteven:
                push    ax, bx
                clr     ah
                and     al, 00Fh
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah

                xchg    bx, bp
                test    dh, 0x80
                call    PutSplitedPixelMask
                xchg    bx, bp
                pop     ax, bx
                rol     dh
                xor     dl, 1

                tst     bp
                jz      null1

		test	dl, 1			; see if starting odd or even
                jz      noSplit
                dec     si
noSplit:
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

                push    ax, bx
                clr     ah
                and     al, 00Fh
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah
                mov     es:[di+1], ax
                mov     es:[di], bl

                pop     ax, bx

maskLoop5:
                add     di, ss:[pixelBytes]
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

                push    ax, bx
                clr     ah
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah
                mov     es:[di+1], ax
                mov     es:[di], bl

                pop     ax, bx

maskLoop6:
                add     di, ss:[pixelBytes]
                xor     dl, 1
		xchg	ah,al
                rol     dh
                jnc     maskLoop7

                push    ax, bx
                clr     ah
                and     al, 00Fh
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah
                mov     es:[di+1], ax
                mov     es:[di], bl

                pop     ax, bx

maskLoop7:
                add     di, ss:[pixelBytes]
                xor     dl, 1

		tst	bp			; if only one byte to do...
		jnz	paletteEvenLoop
		jmp	done
                
		; odd number of bytes to do.  Last one here...
lastByte:
                rol     dh
                jnc     maskLoop4      

                push    ax, bx
                clr     ah
                and     al, 00Fh
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah
                mov     es:[di+1], ax
                mov     es:[di], bl

                pop     ax, bx

maskLoop4:
                add     di, ss:[pixelBytes]
                xor     dl, 1
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

                push    ax, dx
                mul     ss:[pixelBytes]
                NextScan        di, ax          ; add to screen offset too
                pop     ax, dx

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
                mul     ss:[pixelBytes]

                PrevScan        di, ax

		.leave
		ret


doPartial:
                push    bp
                mov     bp, ss:[pixelsLeft]
                tst     bp
                jz      null0
                call    PutColScanMaskLow

		test	dl, 1			; see if starting odd or even
                jz      null0
                dec     si
null0:
                pop     bp
                sub     bp, ss:[pixelsLeft]

                lodsb
                test    dl, 1
                jnz     noteven
                shr     al, cl
noteven:
                push    ax, bx
                clr     ah
                and     al, 00Fh
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah

                test    dh, ch
                xchg    cx, bp
                call    PutSplitedPixelMask     
                xchg    cx, bp
                pop     ax, bx
                xor     dl, 1

		shr	ch, 1			; test next bit
                jnc     loop2
		mov	dh, ds:[bx]		; load next mask byte
                and     dh, ss:[lineMask]
                inc	bx
		mov	ch, 0x80		; reload test bit
loop2:
                tst     bp
                jz      null1

		test	dl, 1			; see if starting odd or even
                jz      noSplit
                dec     si
noSplit:
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

                push    ax, bx
                clr     ah
                and     al, 00Fh
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah
                mov     es:[di+1], ax
                mov     es:[di], bl

                pop     ax, bx

paletteDoneFirst:
                add     di, ss:[pixelBytes]
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

                push    ax, bx
                clr     ah
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah
                mov     es:[di+1], ax
                mov     es:[di], bl

                pop     ax, bx

paletteDoSecond:
                add     di, ss:[pixelBytes]

                xor     dl, 1
                shr     ch, 1
		dec	bp			; one less to go
		jz	done
		test	dh, ch
		jz	paletteNextPixel
		mov	al, ah			; get second pixel value in al

                push    ax, bx
                clr     ah
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                inc     bx
                inc     bx
                mov     bl, es:[bx]

                pop     es

                xchg    al, ah
                mov     es:[di+1], ax
                mov     es:[di], bl

                pop     ax, bx

paletteNextPixel:
                add     di, ss:[pixelBytes]
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

                push    ax, dx
                mov     ax, bx
                mul     ss:[pixelBytes]
                NextScanBoth    di, ax
                pop     ax, dx

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

doneend:
                ; go back to the start position
                mov     ax, ss:[bmRight]
                inc     ax
                mul     ss:[pixelBytes]

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
                jcxz    null0

                call    WriteMonoBytes
null0:
                pop     cx
                sub     cx, ss:pixelsLeft

                jcxz    over

		and	al, ah		; apply bitmap mask
		test	al, dh		; check next pixel
                jnz     start
                call    MidScanNextWin
                call    MidScanNextWinSrc
                jmp     done3

start:
                push    ax, bx
                test    ss:[bmFilled], 1
                jnz     filled

                clr     bx              ; C_BLACK
                test    al, dh          ; check if existing pixel is black
                                        ; or white
                jnz     black

                mov     bx, 0FFFFh
black:
                mov     ax, bx
                jmp     realstart
filled:
                mov     ax, es:[di]
                mov     bl, es:[di+2]
                xchg    al, bl
                xchg    bx, dx
                xchg    bx, ax
		call	ss:[modeRoutine]
                xchg    bx, ax
                xchg    bx, dx

realstart:
                cmp     ss:[restBytes], 0
                jz      over
                
                mov     es:[di], bl
                cmp     ss:[restBytes], 1
                jz      over

                mov     es:[di+1], ah
                cmp     ss:[restBytes], 2
                jz      over

                mov     es:[di+2], al
over:
                call    MidScanNextWin
                call    MidScanNextWinSrc

                jcxz    done2

                cmp     ss:[restBytes], 3
                jz      done

                cmp     ss:[restBytes], 2
                jz      left1

                cmp     ss:[restBytes], 1
                jz      left2

                mov     es:[di], bl
                inc     di
left2:          mov     es:[di], ah
                inc     di
left1:          mov     es:[di], al

done:
                pop     ax, bx
done3:
                mov     di, ss:[restBytesOver]
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
done2:
                jcxz    null1
noSplit:
                call    WriteMonoBytes
null1:
                jmp     doneend

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

                push    bx, dx
 
                clr     bx              ; C_BLACK
                clr     dl
                test    al, dh          ; check if existing pixel is black
                                        ; or white
                jnz     black

                mov     bx, 0FFFFh
                mov     dl, 0FFh
black:
                mov     es:[di], bx     ; store pixel color
                mov     es:[di+2], dl

                pop     bx, dx
nextPixel:
                add     di, ss:[pixelBytes]
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

                push    bx, dx
                mov     bx, es:[di]
                mov     dl, es:[di+2]
                xchg    bl, dl
		call	ss:[modeRoutine]
                xchg    bl, dl
                mov     es:[di], bx     ; store pixel color
                mov     es:[di+2], dl
                pop     bx, dx
nextPixel2:
                add     di, ss:[pixelBytes]
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

                push    ax, dx
                mov     ax, cx
                mul     ss:[pixelBytes]
                NextScanSrc     si, ax
                pop     ax, dx

		mov	cx, ss:[d_dx]
                cmp     si, ss:[lastWinPtrSrc]
                jb      notPartial
                cmp     cx, ss:[pixelsLeftSrc]
                jbe     notPartial

                mov     cx, ss:[pixelsLeftSrc]
                jcxz    split
getLoop1:
                lodsw
                mov     bl, al
                lodsb
                stosw
                mov     al, bl
                stosb
                add     si, ss:[pixelRestBytes]

                loop    getLoop1
split:
                mov     cx, ss:[d_dx]
                sub     cx, ss:[pixelsLeftSrc]

                jcxz    done

                xchg    di, si
                call    GetSplitedPixel
                xchg    di, si

                stosw
                xchg    al, bl
                stosb

                jcxz    done
notPartial:
                lodsw
                mov     bl, al
                lodsb
                stosw
                mov     al, bl
                stosb
                add     si, ss:[pixelRestBytes]

                loop    notPartial
done:
                cmp     si, 0
                jnz     done3

                xchg    di, si
                call    MidScanNextWinSrc
                xchg    di, si
done3:
                mov     cx, ss:[d_dx]
                add     cx, ss:[d_x1]
                
                push    ax, dx

                mov     ax, cx
                mul     ss:[pixelBytes]
                PrevScanSrc     si, ax
                pop     ax, dx

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
                clr     dl
ByteNOP		label near
		ret
ByteCOPY	label  near
                mov     bx, {word} ss:[currentColor].RGB_red
                mov     dl, ss:[currentColor].RGB_blue
		ret
ByteAND		label  near		
                and     bx, {word} ss:[currentColor].RGB_red
                and     dl, ss:[currentColor].RGB_blue
		ret
ByteINV		label  near
                xor     bx, 0FFFFh
                xor     dl, 0FFh
		ret
ByteXOR		label  near
                xor     bx, {word} ss:[currentColor].RGB_red
                xor     dl, ss:[currentColor].RGB_blue
		ret
ByteSET		label  near
                mov     bx, 0FFFFh
                mov     dl, 0FFh
		ret
ByteOR		label  near
                or      bx, {word} ss:[currentColor].RGB_red
                or      dl, ss:[currentColor].RGB_blue
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
