COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem 	
FILE:		vidmemRaster.asm

AUTHOR:		Jim DeFrisco, Mar 19, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT BltSimpleLine		blt a single scan line (vertically)
    INT PutBWScan		Transfer a scan line's worth of system
				memory to screen
    INT FillBWScan		Transfer a scan line's worth of system
				memory to screen
    INT PutBWScanMask		Transfer a scan line's worth of system
				memory to screen
    INT NullBMScan		Transfer a scan line's worth of system
				memory to screen
    INT GetOneScan		Copy one scan line of video buffer to
				system memory
    INT ByteModeRoutines	Set of routines for implementing drawing
				mode on non-EGA compatible display modes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/19/92		Initial revision


DESCRIPTION:
	
		

	$Id: vidmemRaster.asm,v 1.1 97/04/18 11:42:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSegment	Blt

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltSimpleLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	blt a single scan line (vertically)

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
		mask left;
		copy left byte;
		mask = ff;
		copy middle bytes
		mask right;
		copy right byte;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

BltSimpleLine	proc		near
		ret
BltSimpleLine	endp


VidEnds		Blt


VidSegment	Bitmap


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBWScan
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
		dx	- index into pattern table
		ds:si	- pointer to bitmap data
		bp	- bitmap data segment
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
	Jim	01/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PutBWScan	proc	near
		ret
PutBWScan	endp

FillBWScan	proc	near
		ForceRef	FillBWScan
		ret
FillBWScan	endp

PutBWScanMask	proc	near
		ret
PutBWScanMask	endp

NullBMScan	proc	near
		ret
NullBMScan	endp

VidEnds		Bitmap

VidSegment	Misc

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOneScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy one scan line of video buffer to system memory

CALLED BY:	INTERNAL
		VidGetBits

PASS:           ds:si   - address of start of scan line in frame buffer
		es:di   - pointer into sys memory where scan line to be stored
		cx      - # bytes left in buffer
		d_x1    - left side of source
		d_dx    - # source pixels
		shiftCount - # bits to shift

RETURN:         es:di   - pointer moved on past scan line info just stored
												cx      - # bytes left in buffer
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
GetOneScan	proc		near
		ret
GetOneScan	endp

VidEnds		Misc

VidSegment	Bitmap

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ByteModeRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set of routines for implementing drawing mode on non-EGA
		compatible display modes

CALLED BY:	Bitmap drivers

PASS:		al = screen data
		dl = pattern
		ah = new bits AND mask

		where:	new bits = bits to write out (as in bits from a
				   bitmap).  For objects like rectangles,
				   where newBits=all 1s, ah will hold the
				   mask only.  Also: this mask is a final
				   mask, including any user-specified draw
				   mask.

RETURN:		al = byte to write

DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		see below for each mode

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	02/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;	the comments below use the following conventions (remember 
;	boolean algebra?...)
;		AND	^
;		OR	v
;		NOT	~




BMR_saveMask	byte	0
ByteModeRoutines	proc		near
	ForceRef	ByteModeRoutines
ByteCLEAR label	near		; (screen^~(data^mask))v(data^mask^resetColor)
	not	ah		;
	and	al, ah		;
	not	ah		;
	and	ah, byte ptr ss:[resetColor]
	or	al, ah		; 
ByteNOP	label	near		;
	ret
ByteCOPY label	near		; (screen^~(data^mask))v(data^mask^pattern)
	not	ah		;
	and	al, ah		;
	not	ah		;
	and	ah, dl		;
	or	al, ah		; 
	ret
ByteAND	label	near		; screen^((data^mask^pattern)v~(data^mask))
	not	ah		
	mov	cs:[BMR_saveMask], ah
	not	ah
	and	ah, dl
	or	ah, cs:[BMR_saveMask]
	and	al, ah
	ret
ByteINV	label	near		; screenXOR(data^mask) 
	xor	al, ah
	ret
ByteXOR	label	near		; screenXOR(data^mask^pattern)
INVRSE <tst	ss:[inverseDriver]					>
INVRSE <jz	notInverse						>
INVRSE <not	dl							>
	; Ok, this goes against style guidelines, but we need speed and
	; dl back in its original form: duplicate three lines
	; and "ret" in the middle of this function.
INVRSE <and	ah, dl							>
INVRSE <not	dl							>
INVRSE <xor	al, ah							>
INVRSE <ret								>
INVRSE <notInverse:							>
	and	ah, dl
	xor	al, ah
	ret
ByteSET	label	near		; (screen^~(data^mask))v(data^mask^setColor)
	not	ah		;
	and	al, ah		;
	not	ah		;
	and	ah, byte ptr ss:[setColor]
	or	al, dl
	ret
ByteOR	label	near		; screenv(data^mask^pattern) 
	and	ah, dl
	or	al, ah
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
