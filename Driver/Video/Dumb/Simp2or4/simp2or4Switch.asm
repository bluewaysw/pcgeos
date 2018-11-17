COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Video
MODULE:		simp2or4
FILE:		simp2or4Switch.asm

AUTHOR:		Eric Weber, Feb 11, 1997

ROUTINES:
	Name			Description
	----			-----------
    INT Simp2or4ChangeVidMode	Switch from 2bit to 4bit or vice versa

    INT Simp2or4ParseDisplayMode
				Store the desired color depth in dgroup

    INT TimerDelay		Busy wait until the next tick has passed

    INT Simp2or4ScreenOff	Turn the LCD off

    INT Simp2or4ScreenOn	Turn the LCD back on

    INT Simp2or4SetHardwareMode	Change the video mode in hardware

    INT Simp2or4PackBits	Change from 4 bits/pixel to 2 bits/pixel

    INT Simp2or4UnpackBits	Change from 2 bits/pixel to 4 bits/pixel

    INT Simp2or4UnloadDriver	Unload the current video driver

    INT Simp2or4LoadDriver	Load the appropriate video driver

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/11/97   	Initial revision


DESCRIPTION:
		
	

	$Id: simp2or4Switch.asm,v 1.1 97/04/18 11:43:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VideoCode	segment resource

driver2Name	char	"simp2bit.geo",0
driver4Name	char	"simp4bit.geo",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4ChangeVidMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch from 2bit to 4bit or vice versa

CALLED BY:	INTERNAL Simp2or4Strategy
PASS:		ax	- DisplayMode
RETURN:		carry	- set if mode not supported
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/11/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Simp2or4ChangeVidMode	proc	far
		uses	bx, cx, dx, bp, si, di, ds, es
		.enter
		mov	dx, segment dgroup
		mov	es, dx
	;
	; everything but DM_definition must be 0 (no change), or 1 (default)
	;
		test	al, 10100010b
		stc
		jnz	done
	;
	; Not everything in here is hardware-specific, but enough of it
	; is that we just don't do anything for unknown hardware.
	;
		clc
	;
	; return the current mode
	;
done:
		pushf
		call	Simp2or4NotifyPowerDriver	; ax = mode
		popf
		
		.leave
		ret
Simp2or4ChangeVidMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4ParseDisplayMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the desired color depth in dgroup

CALLED BY:	INTERNAL Simp2or4ChangeVidMode
PASS:		ax	- DisplayMode
		es	- dgroup
RETURN:		carry set if we need to change modes
		dx	- offset of routine to repack video memory
		si	- offset of new driver name (in VideoCode)
DESTROYED:	nothing
SIDE EFFECTS:	sets es:[curDepth]

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/11/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Simp2or4ParseDisplayMode	proc	near
		uses	ax,bx,cx,di,bp
		.enter
	;
	; see what we are supposed to do
	;
		cmp	al, DMD_NO_CHANGE shl offset DM_definition
		je	done
		cmp	al, DMD_HIGH shl offset DM_definition
		je	toHigh
		cmp	al, DMD_DEFAULT shl offset DM_definition
		je	toLow
EC <		cmp	al, (DMD_TOGGLE shl offset DM_definition) and mask DM_definition 	>
EC <		ERROR_NE INVALID_DISPLAY_MODE_DEFINITION		>
	;
	; toggle between 2 and 4
	;
		cmp	es:[curDepth], 4
		jne	toHigh
	;
	; switch to 2-bit mode
	;
toLow:
		mov	ax, 2
		mov	dx, offset Simp2or4PackBits
		mov	si, offset driver2Name
		jmp	checkMode
	;
	; switch to 4-bit mode
	;
toHigh:
		mov	ax, 4
		mov	dx, offset Simp2or4UnpackBits
		mov	si, offset driver4Name
		jmp	checkMode
	;
	; are we already in the desired mode?
	;
checkMode:
		cmp	ax, es:[curDepth]
		je	done
		mov	es:[curDepth], ax
		stc
done:
		.leave
		ret
Simp2or4ParseDisplayMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerDelay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Busy wait until the next tick has passed

CALLED BY:	INTERNAL Simp2or4ScreenOff, Simp2orScreenOn,
			 Simp2or4SetHardwareMode
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This macro is necessary because of an interesting quirk in the
	E3G hardware.  If we issue the screen-related IO instructions
	too quickly, the LCD will become confused and pixel 0,0 will
	end up in the middle of the display.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/13/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerDelay	proc	near
		push	bx, cx, ds
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	cx, ds:[delayCount]
top:
		mov	ax, ds:[delayCount]
		loop	top
		pop	bx, cx, ds
		ret
TimerDelay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4ScreenOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn the LCD off

CALLED BY:	INTERNAL Simp2or4ChangeVidMode
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/13/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Simp2or4ScreenOff	proc	near
		uses	ax, cx, dx
		.enter

		.leave
		ret
Simp2or4ScreenOff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4ScreenOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn the LCD back on

CALLED BY:	INTERNAL Simp2or4ChangeVidMode
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/13/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Simp2or4ScreenOn	proc	near
	uses	ax, cx, dx
	.enter
	.leave
	ret
Simp2or4ScreenOn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4SetHardwareMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the video mode in hardware

CALLED BY:	INTERNAL Simp2or4ChangeVidMode
PASS:		es	- dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/13/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Simp2or4SetHardwareMode	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; set the hardware mode
	; For the E3G, the modes are:
	;	00 - 1 bit/pixel
	;	01 - 2 bits/pixel
	;	10 - 4 bits/pixel
	;
doMode::
		mov	dx, IO_DCMODER
		mov	bx, es:[curDepth]
		shr	bl
		INT_OFF
		in	al, dx
		and	al, 11111100b
		or	al, bl
		out	dx, al
		INT_ON
		call	TimerDelay
	;
	; And don't forget to set the virtual screen width.
	;
		mov	ax, SCREEN_BYTE_WIDTH
		cmp	es:[curDepth], 4
		je	putWidth
		shr	ax
putWidth:
		mov	dx, IO_DCHVSWR
		out	dx, ax
		call	TimerDelay
		
	.leave
	ret
Simp2or4SetHardwareMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4PackBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change from 4 bits/pixel to 2 bits/pixel

CALLED BY:	INTERNAL Simp2or4ChangeVidMode
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The E3G video memory is arranged in a big-endian fasion, even
	though the 386 core likes to access memory in a little-endian
	way.  So we implicitly swap bytes as part of packing the bits.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/11/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; ax: -edc-a98-654-210 -> 6521eda9--------
WordToByte macro
		shl	ax				; edc-a98-654-210-
		mov	bx, ax
		and	ax, 1100000011000000b		; ed------65------
		shl	bx
		shl	bx				; c-a98-654-210---
		and	bx, 0011000000110000b		; --a9------21----
		or	ax, bx				; eda9----6521----
		shr	al, 4				; eda9--------6521
		or	al, ah				; --------eda96521
endm

Simp2or4PackBits	proc	near
		uses	ax, bx, cx, dx, bp, si, di, ds, es
		.enter
	;
	; set up pointers to vidmem
	;
		mov	ax, SCREEN_BUFFER	; segment of video buffer
		mov	ds, ax
		mov	es, ax
		clr	si, di
	;
	; compute number of interations to perform
	; (4 pixels per word, 2 words per iteration)
	; we must have an integral number of dwords in each row
	;
		CheckHack <(SCREEN_PIXEL_WIDTH and 7) eq 0>
		mov	cx, SCREEN_PIXEL_WIDTH*SCREEN_HEIGHT/8
	;
	; convert two words to one word and write it back
	;
top:
		lodsw
		WordToByte		; al = high byte
		mov	dh, al
		lodsw
		WordToByte		; al = low byte
		mov	ah, dh		; ax = combined word
		stosw
		loop	top		
bottom::
		.leave
		ret
Simp2or4PackBits	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4UnpackBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change from 2 bits/pixel to 4 bits/pixel

CALLED BY:	INTERNAL Simp2or4ChangeVidMode
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	


PSEUDO CODE/STRATEGY:
	Again, we need to keep the reversed byte ordering in mind.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/11/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
; ax: --------76543210 -> -76--54--32--10-
ByteToWord	macro
	mov	ah, al
	shr	al, 4		
	and	ax, 0000111100001111b
	xlatb	cs:
	xchg	ah, al
	xlatb	cs:
endm

; output     input
ByteToWordTable	byte \
00000000b,  ; 00 00
00000010b,  ; 00 01
00001101b,  ; 00 10
00001111b,  ; 00 11
00100000b,  ; 01 00
00100010b,  ; 01 01
00101101b,  ; 01 10
00101111b,  ; 01 11
11010000b,  ; 10 00
11010010b,  ; 10 01
11011101b,  ; 10 10
11011111b,  ; 10 11
11110000b,  ; 11 00
11110010b,  ; 11 01
11111101b,  ; 11 10
11111111b   ; 11 11

Simp2or4UnpackBits	proc	near
		uses	ax, bx, cx, dx, bp, si, di, ds, es
		.enter
	;
	; compute number of interations to perform
	; (4 pixels per byte, 2 bytes per iteration)
	; we must have an integral number of words in each row
	;
		CheckHack <(SCREEN_PIXEL_WIDTH and 7) eq 0>
		mov	cx, (SCREEN_PIXEL_WIDTH*SCREEN_HEIGHT)/8
	;
	; set up pointers to vidmem
	; we will be interating backward - reading from the end of
	; the 2 bit bufer and writing to the end of the 4 bit buffer
	;
		mov	ax, SCREEN_BUFFER	; segment of video buffer
		mov	ds, ax
		mov	es, ax
		mov	di, (SCREEN_PIXEL_WIDTH*SCREEN_HEIGHT)/2-2
		mov	si, (SCREEN_PIXEL_WIDTH*SCREEN_HEIGHT)/4-2
		std
	;
	; When we read a word, we read four pixels.  The left two pixels
	; go into al, and the right two pixels into ah.  Since we are
	; scanning from right to left, we output the right pixels first.
	;
		mov	bx, offset ByteToWordTable
top:
		lodsw			; read four pixels
		mov	dh, ah		; save left two pixels
		ByteToWord		; expand right two pixels
		stosw
		mov	al, dh		; restore left two pixels
		ByteToWord		; expand left two pixels
		stosw
		loop	top
	;
	; clean up
	;
bottom::
		cld
		.leave
		ret
Simp2or4UnpackBits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4UnloadDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unload the current video driver

CALLED BY:	INTERNAL Simp2or4ChangeVidMode
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/15/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Simp2or4UnloadDriver	proc	near
		uses	bx, di
		.enter
	;
	; Stop using the display.
	;
	; This will allow the driver to exit without switching to text mode
	; or clearing the display.
	;
		mov	bx, es:[curGeode]
		tst	bx
		jz	done
		mov	di, VID_ESC_UNSET_DEVICE
		call	es:[curStrategy]
	;
	; now it's safe to unload
	;
		call	GeodeFreeDriver
done:
		.leave
		ret
Simp2or4UnloadDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4LoadDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the appropriate video driver

CALLED BY:	INTERNAL Simp2or4ChangeVidMode
PASS:		cs:si	- name of driver to load
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/15/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Simp2or4LoadDriver	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; switch to video directory
	;
		call	FilePushDir
		mov	ax, SP_VIDEO_DRIVERS
		call	FileSetStandardPath
	;
	; load the new driver
	;
		segmov	ds, cs
		mov	ax, VIDEO_PROTO_MAJOR
		mov	bx, VIDEO_PROTO_MINOR
		push	es
		call	GeodeUseDriver
		pop	es
		ERROR_C CANT_LOAD_VIDEO_SUBDRIVER
		mov	es:[curGeode], bx
		call	FilePopDir
	;
	; get the strategy
	;
		call	GeodeInfoDriver		; ds:si = DriverInfoStruct
		movdw	es:[curStrategy], ds:[si].DIS_strategy, ax
	;
	; set the device
	;
setdev::
		mov	bx, handle VideoDevices
		call	MemLock
		mov	ds, ax
		mov_tr	dx, ax
		mov	si, offset Simp2or4String
		mov	si, ds:[si]
		mov	di, DRE_SET_DEVICE
		call	es:[curStrategy]
		call	MemUnlock
	.leave
	ret
Simp2or4LoadDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4NotifyPowerDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the power driver what mode we are in

CALLED BY:	Simp2or4ChangeVidMode
PASS:		es	- dgroup
RETURN:		ax	- active DisplayMode
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	3/09/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Simp2or4NotifyPowerDriver	proc	near
		uses	bx,cx,dx,si,di,bp,ds
		.enter
	;
	; Find the power driver
	;
		mov	ax, GDDT_POWER_MANAGEMENT
		call	GeodeGetDefaultDriver		; ax = driver han
		mov	bx, ax
		call	GeodeInfoDriver			; ds:si = info
		pushdw	ds:[si].DIS_strategy
		mov	bp, sp
	;
	; Compute the current mode
	;
		mov	cx, es:[curDepth]
		shl	cx, offset DM_definition - 1	; convert to DMD
		or	cx, (DMC_DEFAULT shl offset DM_color) or \
			    (DMO_DEFAULT shl offset DM_orientation) or \
			    DMR_DEFAULT
	;
	; Notify the driver
	;
		push	cx
		mov	di, DR_POWER_ESC_COMMAND
		mov	si, POWER_ESC_NOTIFY_VIDEO_MODE_CHANGE
		call	{fptr}ss:[bp]
		pop	ax
		add	sp, size fptr
				
		.leave
		ret
Simp2or4NotifyPowerDriver	endp


VideoCode	ends


if 0

WordToByte3	macro
	; preload bx with blah1
	xlat	cs
	xchg	al, ah
	xlat	cs
	and	ax, 1111000000001111b		
	or	al, ah
endm


endif
