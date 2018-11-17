COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cpt.asm

AUTHOR:		Maryann Simmons, May 28, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/28/92		Initial revision


DESCRIPTION:
	
		

	$Id: cpt.asm,v 1.1 97/04/07 11:27:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
;	FILE	qck.asm
;
;        page    82, 130
;       title   CCITT compression routines
;
;	public	_GetBits, _PutBits, _rPutBits

;	public	bitmsktbl

;_DATA	segment	WORD	public	'DATA'
;_DATA	ends

;DGROUP	group	_DATA

;_TEXT	segment	byte public	'CODE'

;	assume	cs: _TEXT, ds:DGROUP


;idata	segment
;bitmsktbl:
;	dw	00000h
;	dw	08000h
;	dw	0c000h
;	dw	0e000h
;	dw	0f000h
;	dw	0f800h
;	dw	0fc00h
;	dw	0fe00h
;	dw	0ff00h

;
;	This is for CCITT compression
;

;cbitmsktbl:
;	dw	000h
;	dw	001h
;	dw	003h
;	dw	007h
;	dw	00fh
;	dw	01fh
;	dw	03fh
;	dw	07fh
;	dw	0ffh

;idata	ends

ExportCode	segment	resource
;
;	int	GetBits( LPSTR buf, int bitpos, int bitcnt )
;
;_GetBits	proc	far
;	push	bp
;	mov	bp,sp
;	push	ds
;	push	si
;	push	di
;
;	mov	bx,[bp+4]	; buffer addr offset
;	mov	ax,[bp+6]	; bitpos
;
;	mov	si,ax		; save bit pos in si
;	mov	cl,3
;	shr	ax,cl		; get byte offset
;	add	bx,ax		; starting addr
;	mov	ax,[bx]		; get 16 bit word
;	xchg	ah,al		; make left most bit is screen left most bit
;	mov	cx,si		; cx = bitposition
;	and	cx,0007h	; cl = byte offset of the bits
;	jz	getbits0	; if at byte boundary, then no shifting
;	shl	ax,cl
;getbits0:
;	lea	bx,bitmsktbl		;***MS_TEXT:bitmsktbl
;	mov	cx,[bp+8]	; get bit count
;	add	cx,cx
;	add	bx,cx		; bit msk position
;	and	ax,cs:[bx]
;	xchg	ah,al

;	pop	di
;	pop	si
;	pop	ds
;	mov	sp,bp
;	pop	bp
;	ret
;_GetBits	endp

src     equ     6[bp]
dst     equ     4[bp]
;
;    putbits( src, byte, bitpos, bitcnt )
;    char far *src,
;    char    byte;
;    int    bitpos,
;        bitcnt;
;
;
;_PutBits    proc    far
;    push    bp
;    mov    bp,sp
;    push    ds
;    push    es
;    push    si
;    push    di
;
;    mov    ah,[bp+0ah]    ; get byte
;    xor    al,al
;    mov    bx,[bp+0eh]    ; get bitcnt
;    add    bx,bx
;
;
;    The table is for CCITT bit mask table
;
;    add    bx,offset bitmsktbl		;cs:bitmsktbl
;    mov    si,cs:[bx]           ; get bitmsk
;    and    ax,si                ; into 
;
;    mov    cx,[bp+0ch]          ; get bitpos into cl
;    mov    di,cx                ; di = bitpos
;    and    cx,07h               ; setup the shift count
;
;    shr    ax,cl                ; shift the byte to bitpos
;    shr    si,cl                ; shift the bitmsk the same amount
;    mov    bx,di    
;    mov    cl,3
;    shr    bx,cl                ; get byte offset
;
;    mov    di,si                ; save si in di
;                               
;    lds    si, dword ptr src    ; get word from buffer
;    mov    dx,ax                ; save mask in dx
;    lodsw                       ; load word DS:[SI] to AX 
;    xchg   dx,ax                ; put word to DX and AX get mask back
;
;    xchg   dl,dh                ; make it same as screen alignment
;    not    di                   ; complement the mask
;    and    dx,di                ; clr the bits start from bitpos
;    or     ax,dx                ; put src bits in
;    xchg   al,ah                ; restore the memory order
;    mov    ds:[si],ax           ; put it back
;
;    pop    di
;    pop    si
;    pop     es
;    pop    ds
;    mov    sp,bp
;    pop    bp
;    ret
;_PutBits    endp


;
;       int rPutBits( LPSTR dst, BYTE byte, int bitpos, int bitcnt )
;
;
;
;_rPutBits	proc	near    ; NEAR call
;
;	push	bp
;	mov	bp,sp
;	push	ds
;	push	si
;	push	di
;
;       lds     si, dword ptr dst       ; point ds:si at the dst
;	mov	al,[bp+8]	; get byte
;	xor	ah,ah
;	mov	bx,[bp+11]	; get bitcnt
;	add	bx,bx
;
;	The table is for CCITT bit mask table
;
;	add	bx,offset cbitmsktbl	; cs:cbitmsktbl
;	mov	si,cs:[bx]	; get bitmsk
;	and	ax,si
;	mov	cx,[bp+9]	; get bitpos
;	mov	di,cx		; di = bitpos
;	and	cx,07h		; setup the shift count
;	shl	ax,cl		; shift the byte to bitpos
;	shl	si,cl		; shift the bitmsk the same amount
;	mov	bx,di	
;	mov	cl,3
;	shr	bx,cl		; get byte offset
;
;
;	add	bx,[bp+4]       ; get buffer offset
;	mov	dx,[bx]		; get word from dst
;
;	not	si		; complement the mask
;	and	dx,si		; clr the bits start from bitpos
;	or	ax,dx		; put src bits in
;	mov	[bx],ax		; put it back
;
;	pop	di
;	pop	si
;	pop	ds
;	mov	sp,bp
;	pop	bp
;	ret
;_rPutBits	endp

;
;	int	_NextWhite( src, startpos, totalbits )
;
;	char	*src		; bit buffer
;	int	startpos	; start bit position
;	int	totalbits	; number of bits in the src
;
;	return bit position at first white bitpos
;

_NextWhite	proc	far
	push	bp
	mov	bp,sp
	push	ds
	push	si
	push	di

        lds     si, dword ptr src       ; point ds:si at the src
	mov	ax,[bp+10]	        ; get start bit position
	mov	bx,[bp+12]	        ; get total bit count

	mov	dx,ax		; keep it in dx

	shr	ax,1
	shr	ax,1		; divide by 8 is byte offset of first byte
	shr	ax,1		; containing the first bit
	add	si, ax		; this is the byte offset of bit

	mov	cx, dx
	and	cl, 07h		; get the remainder

	mov	ch, 08h		; calc no of bit can be tested
	sub	ch, cl		; within a byte
	
	mov	ah,080h		; setup bit mask
	shr	ah,cl		; aligne the bit position

	mov	ch,ah		; setup mask
;
;	At this point
;
;	ch = bit mask
;	dx = current bit position
;	si = byte pointer
;
nxtwhite1:
	lodsb			; get the byte
nxtwhite2:
	mov	ah,al
	and	ah,ch
	jz	nxtwhite3	; the bit is not set, prepair return
	inc	dx		; update current bit position
	cmp	dx,bx		; bump the total bit count
	jz	nxtwhite3	; no more bit to count
	shr	ch,1		; shift bit mask
	jnz	nxtwhite2	;
	mov	ch, 080h
	jmp	nxtwhite1	
nxtwhite3:
	mov	ax,dx

	pop	di
	pop	si
	pop	ds
	pop	bp
	ret
_NextWhite	endp
	public	_NextWhite

;
;	int	_NextBlack( LPSTR src, startpos, totalbits )
;
;	char far*src		; bit buffer
;	int	startpos	; start bit position
;	int	totalbits	; number of bits in the src
;
;	return bit position at first black bitpos
;

_NextBlack	proc	far
	push	bp
	mov	bp,sp
	push	ds
	push	si
	push	di

        lds     si, dword ptr src       ; point ds:si at the src
	mov	ax,[bp+10]	        ; get start bit position
	mov	bx,[bp+12]	        ; get total bit count
        
	mov	dx,ax		; keep it in dx

	shr	ax,1
	shr	ax,1		; divide by 8 is byte offset of first byte
	shr	ax,1		; containing the first bit
	add	si, ax		; this is the byte offset of bit

	mov	cx, dx
	and	cl, 07h		; get the remainder

	mov	ch, 08h		; calc no of bit can be tested
	sub	ch, cl		; within a byte
	
	mov	ah,080h		; setup bit mask
	shr	ah,cl		; aligne the bit position

	mov	ch,ah		; setup mask
;
;	At this point
;
;	ch = bit mask
;	dx = current bit position
;	si = byte pointer
;
nxtblack1:
	lodsb			; get the byte
nxtblack2:
	mov	ah,al
	and	ah,ch
	jnz	nxtblack3	; the bit is set, prepair return
	inc	dx		; update current bit position
	cmp	dx,bx		; bump the total bit count
	jz	nxtblack3	; no more bit to count
	shr	ch,1		; shift bit mask
	jnz	nxtblack2	;
	mov	ch, 080h
	jmp	nxtblack1	
nxtblack3:
	mov	ax,dx

	pop	di
	pop	si
	pop	ds
	pop	bp
	ret	
_NextBlack	endp
	public	_NextBlack
;
;_TEXT	ends
;	end
ExportCode ends



