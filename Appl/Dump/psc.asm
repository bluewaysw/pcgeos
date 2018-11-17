COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) erkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Screen Dumps -- PostScript Common Code
FILE:		psc.asm

AUTHOR:		Adam de Boor, Jan 17, 1990

ROUTINES:
	Name			Description
	----			-----------
	PSCPreFreeze		Fetch the strings we need from the UI before
				the screen freezes and deadlock results.
	PSCPrintf2		Print a formatted string with two possible
				parameters.
	PSCSlice		Write a slice out to the file.
	PSCPutChar		Write a character to the inherited file buffer
	PSCFlush		Flush the inherited file buffer
	PSCPrologue		Produce a standard prologue with header comments
				needed by EPS (does not take centering of
				image by FPS module into account, but does
				handle rotation)
	PSCFormatInt		Convert a 16-bit unsigned integer to ascii
				in a passed buffer.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/17/90		Initial revision


DESCRIPTION:
	Common postscript code required by both full-page and encapsulated
	postscript output.
		

	$Id: psc.asm,v 1.2 98/02/23 19:35:07 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	dump.def
include	file.def
;include	event.def

; NEW

include psc.def
include Objects/vTextC.def

MAX_LINE	equ	70		; Longest a line of image data may be
MAX_RUN		equ	129		; Longest a run of pixels may be

idata	segment

widthText	char	10 dup(0)	; Buffer for formatting width
heightText	char	10 dup(0)	; Buffer for formatting height
iwidthText	char	6 dup(0)	; Buffer for formatting image width
iheightText	char	6 dup(0)	; Buffer for formatting image height
bboxWidth	char	6 dup(0)	; Buffer for bounding box width
bboxHeight	char	6 dup(0)	; Buffer for bounding box height
docTitle	char	MAX_LENGTH_IMAGE_NAME+1 dup(0)	; Buffer for text from ImageName
					;  object
DBCS< docTitleDBCS	wchar	MAX_LENGTH_IMAGE_NAME+1 dup(0)	; DBCS version of Image Name  >

idata	ends

PSC	segment	resource

;------------------------------------------------------------------------------
;
;			 POSTSCRIPT SNIPPETS
;
;------------------------------------------------------------------------------
;
; We always list the EPS version, even if producing a full-page version, as it
; is necessary for EPS, and doesn't hurt for FPS.
;
stdHeader	char	'\
%%!PS-Adobe-2.0 EPSF-2.0\n\
%%%%BoundingBox: 0 0 %1 %2\n\
%%%%Creator: dump.geo\n\
%%%%DocumentFonts: \n', 0

stdHeaderTheSequel	char	'\
%%%%Title: %1\n\
%%%%EndComments\n\
\n\
64 dict begin	%% It is recommended that we have our own dictionary...\n',0

;
; Decoder for run-length encoding.
;
rlestring	char	'\
% Screen pixels are run-length encoded exactly as received from the kernel,\n\
% decoded by the procedure readrlestring, which returns a single packet of\n\
% pixels and translated to whatever format is appropriate for the type of\n\
% image being displayed (4-color, 4-bit greyscale, etc.) by some other\n\
% procedure that comes after readrlestring.\n\
\n\
/rlestr1 1 string def % single-element string for reading initial packet byte\n\
/rlestr 129 string def\n\
/readrlestring {\n\
  currentfile rlestr1 readhexstring pop  0 get\n\
  dup 127 le {\n\
    currentfile rlestr 0\n\
    4 3 roll 		% stack now (file rlestr 0 #)\n\
    1 add 		% # is string index and we need length\n\
    getinterval\n\
    readhexstring\n\
    pop			% discard eof status\n\
  } {\n\
    257 exch sub 	% figure number of repetitions\n\
    dup			% save for after the loop\n\
    currentfile rlestr1 readhexstring	% read the byte to duplicate\n\
    pop			% discard eof status\n\
    0 get		% fetch the byte from rlestr1\n\
    exch 		% bring count to the top\n\
    0 exch		% push initial loop value under count\n\
    1 exch		% push increment value under count\n\
    1 sub		% set terminate value. count is 1-origin, though\n\
    { rlestr exch 2 index put } % given index, fetch byte and store in rlestr\n\
    for\n\
    pop 		% discard replicated byte. original count still there\n\
    rlestr exch 0 exch getinterval\n\
 } ifelse\n\
} bind def\n'

;============================================================
; Prologues for the different formats we support
;============================================================

;
; File prologue for 4-bit greyscale images. Requires only a single buffer for
; unpacking a packet of bytes. EGA pixels are mapped to greyscale according to
; the normal formula (.57 green, .37 red and .18 blue, or thereabout) and ranked
; according to the results. The pixelToGrey array encodes this mapping given
; the indices used in the EGA screen.
;
greyPrologueStr	char	'\
/pixelToGreyMap [0 1 5 7 2 3 9 11 4 6 12 13 8 10 14 15] def\n\
/pixelToGrey {\n\
dup\n\
{\n\
    dup			% duplicate double-pixel\n\
    -4 bitshift 	% bring left-most pixel into low nibble\n\
    pixelToGreyMap exch get % map to proper greyscale using pixelToGreyMap\n\
    4 bitshift		% shift back up to high nibble\n\
    exch 15 and		% fetch double-pixel again and extract low nibble\n\
    pixelToGreyMap exch get	% map it to proper greyscale\n\
    or			% merge with high nibble greyscale\n\
    exch		% place under array we were passed\n\
} forall\n\
dup length 1 sub -1 0 {exch dup 4 2 roll exch put} for\n\
} bind def\n'

;
; Prologue and image command for 3-color, full-color images. Each packet is
; decoded once and stored, the individual procedures for the red, green and
; blue components translate that stored string using a different map and
; return the result (using 4-bit RGB)
;
threeColorPrologueStr	char	'\
/redMap [0 0 0 0 10 10 10 10 5 5 5 5 15 15 15 15] def\n\
/greenMap [0 0 10 10 0 0 5 10 5 5 15 15 5 5 15 15] def\n\
/blueMap [0 10 0 10 0 10 0 10 5 15 5 15 5 15 5 15] def\n\
/mapPixels {\n\
dup\n\
{\n\
    dup			% duplicate double-pixel\n\
    -4 bitshift 	% bring left-most pixel into low nibble\n\
    curMap exch get 	% map to proper value using current map\n\
    4 bitshift		% shift back up to high nibble\n\
    exch 15 and		% fetch double-pixel again and extract low nibble\n\
    curMap exch get	% map it to proper value\n\
    or			% merge with high nibble value\n\
    exch		% place under array we were passed\n\
} forall\n\
dup length 1 sub -1 0 {exch dup 4 2 roll exch put} for\n\
} bind def\n\
/greenStr 129 string def /blueStr 129 string def\n'

;
; Prologue and image command for 4-color, full-color images. Each packet is
; decoded once and stored, the individual procedures for the cyan, magenta,
; yellow and black components translate that stored string using a different
; map and return the result (using 4-bit CMYK)
;
fourColorPrologueStr	char	'\
/cyanMap [0 15 10 12 0 11 0 0 0 15 8 9 0 6 0 0] def\n\
/magentaMap [0 6 0 0 12 15 9 0 0 0 0 0 11 9 0 0] def\n\
/yellowMap [0 0 13 4 12 0 15 0 0 0 15 0 6 0 15 0] def\n\
/blackMap [15 0 0 0 4 0 4 6 12 0 0 0 0 0 0 0] def\n\
/mapPixels {\n\
dup\n\
{\n\
    dup			% duplicate double-pixel\n\
    -4 bitshift 	% bring left-most pixel into low nibble\n\
    curMap exch get 	% map to proper value using current map\n\
    4 bitshift		% shift back up to high nibble\n\
    exch 15 and		% fetch double-pixel again and extract low nibble\n\
    curMap exch get	% map it to proper value\n\
    or			% merge with high nibble value\n\
    exch		% place under array we were passed\n\
} forall\n\
dup length 1 sub -1 0 {exch dup 4 2 roll exch put} for\n\
} bind def\n\
/magentaStr 129 string def /yellowStr 129 string def /blackStr 129 string def\n'

;============================================================
; Image commands for the different formats we support
;============================================================

monoImageCmd	char	'\
%1 %2 1\n\
[ %1 0 0 -%2 0 %2 ]\n\
{ readrlestring }\n\
image\n', 0


greyImageCmd	char	'\
%1 %2 4\n\
[ %1 0 0 -%2 0 %2 ]\n\
{ readrlestring pixelToGrey }\n\
image\n', 0


threeColorImageCmd	char	'\
%1 %2 4\n\
[ %1 0 0 -%2 0 %2 ]\n\
{ readrlestring\n\
  dup greenStr copy /greenPacket exch def\n\
  dup blueStr copy /bluePacket exch def\n\
  /curMap redMap def mapPixels }\n\
{ /curMap greenMap def greenPacket mapPixels }\n\
{ /curMap blueMap def bluePacket mapPixels }\n\
true 3 colorimage\n', 0

fourColorImageCmd	char	'\
%1 %2 4\n\
[ %1 0 0 -%2 0 %2 ]\n\
{ readrlestring\n\
  dup magentaStr copy /magentaPacket exch def\n\
  dup yellowStr copy /yellowPacket exch def\n\
  dup blackStr copy /blackPacket exch def\n\
  /curMap cyanMap def mapPixels }\n\
{ /curMap magentaMap def magentaPacket mapPixels }\n\
{ /curMap yellowMap def yellowPacket mapPixels }\n\
{ /curMap blackMap def blackPacket mapPixels }\n\
true 4 colorimage\n', 0

;============================================================
;			  COLOR SCHEME TABLE
;============================================================
ColorSchemeTable	struct
    CST_prologue	nptr		; Extra prologue string
    CST_prologueLen	word		; Length of same
    CST_image		nptr		; Image command
ColorSchemeTable	ends

colorSchemes	ColorSchemeTable <	; PSCS_GREY
    greyPrologueStr, length greyPrologueStr, greyImageCmd
>, <					; PSCS_RGB
    threeColorPrologueStr, length threeColorPrologueStr, threeColorImageCmd
>, <					; PSCS_CMYK
    fourColorPrologueStr, length fourColorPrologueStr, fourColorImageCmd
>

;============================================================
; Orientation set-up strings for different paper sizes.
; %1 is the user-specified width string, %2 is the user-specified height.
;============================================================
pageSetup	char	'\
%%EndProlog\n\
%%Page: 1 1\n'

pageSizeDef		char \
'/width %1 def /height %2 def\n', 0

fpsPortraitSetup	char '\
width %1 sub 2 div height %2 sub 2 div translate\n\
%1 %2 scale\n', 0

fpsLandscapeSetup	char '\
width %2 sub 2 div %2 add height %1 sub 2 div translate\n\
90 rotate\n\
%1 %2 scale\n',0

epsPortraitSetup	char '\
%1 %2 scale\n', 0

epsLandscapeSetup	char '\
90 rotate\n\
%1 %2 scale\n',0

SetupTable	struct
    ST_epsPortrait	nptr
    ST_epsLandscape	nptr
    ST_fpsPortrait	nptr
    ST_fpsLandscape	nptr
SetupTable	ends

setupStrings	SetupTable	<
	epsPortraitSetup, epsLandscapeSetup,
	fpsPortraitSetup, fpsLandscapeSetup
>

;------------------------------------------------------------------------------
;
;			   BUFFERED OUTPUT
;
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCWriteBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the PSCBuffer out to its file.

CALLED BY:	PSCPutChar, PSCFlush
PASS:		cx	= number of bytes to write
		PSCBuffer as first local variable of inherited stack frame
RETURN:		carry set on error
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCWriteBuffer	proc	near	uses bx, dx, ds
buffer		local	PSCBuffer
		.enter	inherit
		segmov	ds, ss, bx
		mov	bx, buffer.PB_file
		lea	dx, buffer.PB_data
		clr	al
		call	FileWrite
		mov	buffer.PB_ptr, 0
		.leave
		ret
PSCWriteBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCPutChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a single character to the current file.

CALLED BY:	INTERNAL
PASS:		al	= character to write
		PSCBuffer as first local variable for calling function
RETURN:		carry set if an error occurred
DESTROYED:	al

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCPutChar	proc	near	uses di
buffer		local	PSCBuffer
		.enter	inherit
		mov	di, buffer.PB_ptr
		mov	buffer.PB_data[di], al
		inc	di
		mov	buffer.PB_ptr, di
		cmp	di, size (buffer.PB_data)
		clc
		jl	done
		push	cx
		mov	cx, di
		call	PSCWriteBuffer
		pop	cx
done:
		.leave
		ret
PSCPutChar	endp
 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCFlush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flush any remaining characters in the buffer out to the file

CALLED BY:	INTERNAL
PASS:		PSCBuffer as first local variable for calling function
RETURN:		carry set if an error occurred
DESTROYED:	al

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCFlush	proc	near	uses cx
buffer		local	PSCBuffer
		.enter	inherit
		clc
		mov	cx, buffer.PB_ptr
		jcxz	done
		call	PSCWriteBuffer
done:
		.leave
		ret
PSCFlush	endp

	
if 0	; flagged as unused -- ardeb 9/4/91

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCWriteString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a string to the output file using a buffer inherited
		from our caller.

CALLED BY:	PSCPrologue, EXTERNAL
PASS:		cs:si	= null-terminated string to be written
		PSCBuffer as first local variable of caller's stack frame
RETURN:		carry on error
DESTROYED:	ax, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCWriteString	proc	near
buffer		local	PSCBuffer
		.enter	inherit
writeLoop:
		lodsb	cs:
		tst	al
		jz	done
		call	PSCPutChar
		jmp	writeLoop
done:
		.leave
		ret
PSCWriteString	endp
endif

;------------------------------------------------------------------------------
;
;			   FORMATTED OUTPUT
;
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCPrintf2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a string out to the file, inserting arg1 for all
		occurrences of %1 and arg2 for all occurrences of %2

CALLED BY:	PSCPrologue
PASS:		bp	= file handle
		cs:di	= string to print
		on stack (pushed in reverse order):
			arg1	= offset in dgroup of buffer holding
				  null-terminated string for %1
			arg2	= offset in dgroup of buffer holding
				  null-terminated string for %2
RETURN:		carry set if couldn't write it all
		args popped
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCPrintf2	proc	near	uses si		arg1:word, arg2:word
buffer		local	PSCBuffer
		.enter
		mov	ax, ss:[bp]
		mov	buffer.PB_file, ax
		mov	buffer.PB_ptr, 0
charLoopTop:
		mov	si, di
charLoop:
		lodsb	cs:		; Fetch next char
		tst	al		; Null terminator?
		jz	done
		cmp	al, '%'		; Format escape?
		je	special
putchar:
		call	PSCPutChar
		jmp	charLoop
done:		
		;
		; String written -- flush the buffer to disk.
		;
		call	PSCFlush
		.leave
		ret	@ArgSize	; pop args on the way out
special:
		;
		; Extract the formatting code from the string and act on
		; it. '1' => insert arg1, '2' => insert arg2, '%' => write
		; a single '%'
		;
		lodsb	cs:
		cmp	al, '%'
		je	putchar		; Double % => write single %
		mov	di, arg1
		cmp	al, '1'
		je	haveStr
EC <		cmp	al, '2'						>
EC <		ERROR_NE	UNKNOWN_PRINTF2_CODE			>
		mov	di, arg2
haveStr:
		xchg	si, di		; ds:si = string to write, di saves
					;  our position in formatting string.
specialLoop:
		lodsb
		tst	al
		jz	charLoopTop	; => end of string, so discard si
					;  and pick up the other string where
					;  we left off.
		call	PSCPutChar
		jmp	specialLoop
PSCPrintf2	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCFormatInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an integer to ASCII in a buffer.

CALLED BY:	INTERNAL/EXTERNAL
PASS:		dx	= number to convert
		es:di	= buffer in which to store the result
RETURN:		buffer filled with null-terminated string
		es:di	= after null terminator
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		The digits are gotten by repeatedly dividing the number
		by 10 and pushing the remainder onto the stack. This leaves
		us with the most significant digit on the top of the stack
		when we reach a quotient of 0.
		
		From there, we can just pop the digits off the stack, convert
		them to ascii and store them away.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCFormatInt	proc	near	uses cx, bx
		.enter
		mov	bx, 10
		clr	cx
		mov	ax, dx	; dividend is dx:ax...
divLoop:
		clr	dx	; Make sure high word is clear
		div	bx	; ax <- quotient, dx <- remainder
		push	dx	; the remainder makes up the next digit.
		inc	cx
		tst	ax	; Was number < 10?
		jnz	divLoop	; Nope -- more digits to get
cvtLoop:
		pop	ax	; Fetch next digit of lesser significance
		add	al, '0'	; Convert to ascii
		stosb
		loop	cvtLoop
		clr	al	; null-terminate
		stosb
		.leave
		ret
PSCFormatInt	endp

;------------------------------------------------------------------------------
;
;			   PROLOGUE PIECES
;
;------------------------------------------------------------------------------


if 0	; flagged as unused -- ardeb 9/4/91
;
; Table of powers of ten indexed by the number of converted digits.
;
powersOfTen	word	1, 10, 100, 1000, 10000, 10000


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCCvtInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a string to an integer until a non-integer character
		is found.

CALLED BY:	PSCAToWWFixed
PASS:		ds:si	= string to convert
RETURN:		bh	= number of characters converted
		bl	= terminating character
		ds:si	= address of al + 1
		ax	= result
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCCvtInt	proc	near	uses cx
		.enter
		clr	ax
		mov	bh, al		; No digits converted yet
		mov	cx, 10		; For multiplication
intLoop:
		xchg	ax, bx
		lodsb
		xchg	ax, bx
		cmp	bl, '0'
		jb	doneInt
		cmp	bl, '9'
		ja	doneInt
		inc	bh		; Another digit converted
		sub	bl, '0'		; Convert to binary
		mul	cx		; Make room for new digit
		add	al, bl
		adc	ah, 0
		jmp	intLoop
doneInt:
		.leave
		ret
PSCCvtInt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCAToWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a floating-point number (w/o exponent) to a WWFixed

CALLED BY:	PSCPrologue
PASS:		ds:si	= string to convert
		es:di	= WWFixed in which to store the result.
RETURN:		
DESTROYED:	si

PSEUDO CODE/STRATEGY:
		To make this reasonably fast, we first convert the integer
		portion and store it away in the normal manner.
		
		We then convert the fractional portion in the same way, keeping
		track of the number of digits so converted. When done, we choose
		the power of 10 that corresponds to the number of digits (we
		keep a table of the powers...) and use GrUDivWWFixed to divide
		what we've got by that power, obtaining a number that is all
		fraction, which we stuff in the fractional part of the result.
		If the number of converted digits is 5 (no more will fit in a
		word), we will need to divide the result by 10 again to obtain
		the true value (we can't represent 100,000 in a WWFixed).

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCAToWWFixed	proc	near	uses cx, dx, ax, bx
		.enter
		mov	es:[di].WWF_frac, 0	; in case no fraction
		call	PSCCvtInt
		mov	es:[di].WWF_int, ax
		cmp	bl, '.'
		jne	done			; not end on '.' => no fraction
		call	PSCCvtInt
		push	bx			; Save count in case it's > 5
		mov	dx, ax			; dx = integer part
		clr	cx			; cx = fraction of divisor (0)
		mov	ax, cx			; ax = fraction of dividend (0)
		mov	bl, bh			; bx = index in powersOfTen
		mov	bh, al			; ...
		shl	bx			; ...
		mov	bx, cs:powersOfTen[bx]	; bx = integer of divisor
		call	GrUDivWWFixed
		pop	bx			; Was divisor too big to fit
		cmp	bh, 5			;  in a word?
		jl	haveFrac		; >= 5 is yes
		mov	bx, 10			; Perform extra divide (if #
		call	GrUDivWWFixed		;  digits > 5, we've lost
						;  precision anyway...
haveFrac:
		mov	es:[di].WWF_frac, cx
done:
		.leave
		ret
PSCAToWWFixed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCFloatToUnits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a string in floating-point notation signifying
		inches into a string in decimal signifying PostScript
		default-coordinate units (1/72 of an inch)

CALLED BY:	PSCPrologue
PASS:		ds:si	= floating-point string
		es:di	= decimal string
RETURN:		nothing
DESTROYED:	si, di

PSEUDO CODE/STRATEGY:
		Convert the floating-point string to WWFixed
		Multiply it by 72 to get the number of units
		Convert the integer portion of the result back to ascii

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
seventyTwo	WWFixed	<0,72>
PSCFloatToUnits	proc	near
temp		local	WWFixed
		.enter
		push	es, di
		segmov	es, ss, di
		lea	di, temp
		call	PSCAToWWFixed
		push	ds
		segmov	ds, cs, si
		lea	si, seventyTwo
		call	GrMulWWFixedPtr
		pop	ds
		pop	es, di
		call	PSCFormatInt
		.leave
		ret
PSCFloatToUnits endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCStartImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put out the image/colorimage command to print the bitmap

CALLED BY:	PSCPrologue
PASS:		cx	= image width
		dx	= image height
		si	= bitmap format
		ds	= dgroup
		bp	= file handle
		bx	= 0 for EPS, 4 for FPS (indexes setupStrings)
RETURN:		carry set if couldn't write the string.
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCStartImage	proc	near
		.enter
	;
	; Define the paper width and height, in case they're needed by the
	; setup string.
	; 
		push	dx
		mov	dx, ds:[procVars].DI_psPageHeight
		mov	di, offset iheightText
		push	di
		call	PSCFormatInt
		
		mov	dx, ds:[procVars].DI_psPageWidth
		mov	di, offset iwidthText
		push	di
		call	PSCFormatInt
		mov	di, offset pageSizeDef
		call	PSCPrintf2
		pop	dx
		;
		; Put out the proper commands to setup the orientation and
		; scaling of the image.
		;
		tst	ds:procVars.DI_psRotate?
		jz	10$
		add	bx, 2
10$:
		mov	di, {nptr.char}cs:setupStrings[bx]
		mov	ax, offset heightText
		push	ax
		mov	ax, offset widthText
		push	ax
		call	PSCPrintf2
		;
		; Convert the image height to ascii and push it to pass to
		; PSCPrintf2
		;
		mov	di, offset iheightText
		push	di
		call	PSCFormatInt
		;
		; Convert the image width to ascii and push it to pass to
		; PSCPrintf2
		;
		mov	di, offset iwidthText
		push	di
		mov	dx, cx
		call	PSCFormatInt
		;
		; Figure which image snippet to use:
		;	BMF_MONO	monoImageCmd
		;	BMF_4BIT	use DI_psColorScheme as index into
		;			colorSchemes to get CST_image
		;
		mov	di, offset monoImageCmd
		cmp	si, BMF_MONO
		je	haveStr
		cmp	si, BMF_4BIT
		jne	choke
		mov	di, ds:procVars.DI_psColorScheme
		mov	di, cs:colorSchemes[di].CST_image
haveStr:
		call	PSCPrintf2
done:
		.leave
		ret
choke:
		add	sp, 2*(size word)		;clean up stack
		stc
		jmp	done
PSCStartImage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCFormatImageDim
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format one of the image dimensions into a floating-point
		string (in points)

CALLED BY:	PSCPreFreeze
PASS:		ax	= dimension to format (points * 8, so low 3 bits are
			  fraction)
		ds:di	= buffer in which to place the result
RETURN:		ds:di	= after null-terminator
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dimFracStrings	nptr.char	dimFrac_0, dimFrac_125, dimFrac_25,
				dimFrac_375, dimFrac_5, dimFrac_625,
				dimFrac_75, dimFrac_875
dimFrac_0	char	0
dimFrac_125	char	'.125', 0
dimFrac_25	char	'.25', 0
dimFrac_375	char	'.375', 0
dimFrac_5	char	'.5', 0
dimFrac_625	char	'.625', 0
dimFrac_75	char	'.75', 0
dimFrac_875	char	'.875', 0
PSCFormatImageDim proc	near
		uses	es, dx, si
		.enter
		segmov	es, ds		; es:di <- buffer
		mov	si, ax		; save for fraction
	;
	; Truncate the dimension by shifting right 3 bits to right-justify
	; the integer, then format it into the buffer.
	; 
		shr	ax
		shr	ax
		shr	ax
		mov_trash	dx, ax
		call	PSCFormatInt

		dec	di		; es:di <- null terminator
	;
	; Now use the fraction to index into the table and copy the proper
	; string at the end of the buffer, including its null-terminator
	; 
		andnf	si, 0x7
		shl	si
		mov	si, cs:[dimFracStrings][si]
copyFrac:
		lodsb	cs:
		stosb
		tst	al
		jnz	copyFrac
		.leave
		ret
PSCFormatImageDim endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCPreFreeze
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the strings from the various text objects in which
		the user can type them.

CALLED BY:	DumpPreFreeze
PASS:		ds	= dgroup
RETURN:		carry set if either the width or the height is empty
		widthText, heightText filled from their objects
		docTitle filled from ImageName or empty (0 at the front)
DESTROYED:	bx, si, cx, dx, ax, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCPreFreeze	proc	far
		.enter

GetText		macro	sourceObj, destBuf
		mov	bx, handle sourceObj
		mov	si, offset sourceObj
		mov	dx, ds
		mov	bp, offset destBuf
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	di, mask MF_CALL
		call	ObjMessage
		endm

		mov	di, offset widthText
		mov	ax, ds:[procVars].DI_psImageWidth
		call	PSCFormatImageDim
		
		mov	di, offset heightText
		mov	ax, ds:[procVars].DI_psImageHeight
		call	PSCFormatImageDim

		;
		; Fetch the title from the text object. If none there, use
		; the file name.
		;
		mov	{char} ds:docTitle[0], 0
if DBCS_PCGEOS
		push	es
		GetText	ImageName, docTitleDBCS	; strlen -> cx
						; dx:bp = text ptr
		;
		;  Pass a Unicode length that does include NULL.
		;  This means the converted string will be null terminated
		;
		mov	si, bp			; ds:si = Unicode buffer
		segmov	es, ds, ax
		mov	di, offset docTitle	; es:di = DOS char buffer
		clr	ax, bx, dx
		inc	cx			; count that NULL
		call	LocalGeosToDos		; strlen(DOS) w/NULL -> cx
		pop	es
else
		GetText	ImageName, docTitle
endif

	;
	; Fetch paper size from the paper size list.
	;
		sub	sp, size PageSizeReport
		mov	dx, ss
		mov	bp, sp
		mov	bx, handle PaperControl
		mov	si, offset PaperControl
		mov	ax, MSG_PZC_GET_PAGE_SIZE
		mov	di, mask MF_CALL
		call	ObjMessage

		mov	cx, ss:[bp].PSR_width.low
		mov	ds:[procVars].DI_psPageWidth, cx
		mov	dx, ss:[bp].PSR_height.low
		mov	ds:[procVars].DI_psPageHeight, dx
		add	sp, size PageSizeReport
		clc
		.leave
		ret
PSCPreFreeze	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCPrologue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Produce the standard file prologue, including the required
		image command

CALLED BY:	EXTERNAL
PASS:		bx	= PSTypes
		cx	= image width (pixels)
		dx	= image height (pixels)
		si	= image format (BMFormat)
		bp	= file handle
RETURN:		carry if couldn't write the whole header
DESTROYED:	lots of neat things

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCPrologue	proc	near	uses bx
		.enter
		push	bx, cx, dx, si

		;
		; Convert final width to units, storing the result in bboxWidth
		; or bboxHeight, depending on whether the image is being
		; rotated. 
		;
		mov	ax, ds:[procVars].DI_psImageWidth
		mov	di, offset bboxWidth
		tst	ds:procVars.DI_psRotate?
		jz	10$
		mov	di, offset bboxHeight
10$:
		add	ax, 7		; round up
		andnf	ax, not 7
		call	PSCFormatImageDim

		;
		; Convert final height to units, storing the result in
		; bboxHeight or bboxWidth, depending on whether the image is
		; being rotated.
		;
		mov	ax, ds:[procVars].DI_psImageHeight
		mov	si, offset heightText
		mov	di, offset bboxHeight
		tst	ds:procVars.DI_psRotate?
		jz	20$
		mov	di, offset bboxWidth
20$:
		add	ax, 7
		andnf	ax, not 7
		call	PSCFormatImageDim
		;
		; Print the version string and the bounding box.
		;
		mov	ax, offset bboxHeight
		push	ax
		mov	ax, offset bboxWidth
		push	ax
		mov	di, offset stdHeader
		call	PSCPrintf2
		;
		; Give the thing a title and start our dictionary
		;
		mov	ax, offset docTitle
		push	ax
		push	ax
		mov	di, offset stdHeaderTheSequel
		call	PSCPrintf2
		;
		; Spew the standard run-length decoder.
		;
		push	ds
		mov	bx, bp
		segmov	ds, cs, dx
		mov	dx, offset rlestring
		mov	cx, size rlestring
		clr	al
		call	FileWrite
		pop	ds
		jc	popErrorSI_DX_CX_BX
		;
		; Spew any additional code required by the output format before
		; the start of the page.
		;
		pop	si		; Recover bitmap format
		push	ds
		mov	di, ds:procVars.DI_psColorScheme
		segmov	ds, cs, dx
		cmp	si, BMF_MONO
		je	headerWritten
;XXX: DEAL WITH > 4 BITS HERE
		mov	dx, cs:colorSchemes[di].CST_prologue
		mov	cx, cs:colorSchemes[di].CST_prologueLen
		clr	al
		call	FileWrite
		jc	40$
headerWritten:
		;
		; Finish the prologue and start the page.
		;
		mov	dx, offset pageSetup
		mov	cx, size pageSetup
		clr	al
		call	FileWrite
40$:
		pop	ds
		jc	popErrorDX_CX_BX
		
		;
		; Now produce the proper image command to start the whole thing
		; off.
		;
		pop	dx		; image height
		pop	cx		; image width
		pop	bx		; extra index for setupStrings
		
		call	PSCStartImage
done:
		.leave
		ret
error:
		stc
		jmp	done
popErrorSI_DX_CX_BX:
		pop	si
popErrorDX_CX_BX:
		pop	bx, cx, dx
		jmp	error
PSCPrologue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCOutByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spew a byte to the output file as two hex digits, dealing
		with wrapping lines at a resonable point.

CALLED BY:	PSCSlice, PSCFlushNonRun
PASS:		al	= byte to write
		PSCBuffer as first local variable of current stack frame
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCOutByte	proc	near
buffer		local	PSCBuffer
lineCount	local	word
		.enter	inherit
		mov	ah, al
		shr	al
		shr	al
		shr	al
		shr	al
		add	al, '0'
		cmp	al, '9'
		jle	notHex
		add	al, 'A' - ('9' + 1)
notHex:
		push	ax
		call	PSCPutChar
		pop	ax
		mov	al, ah
		andnf	al, 0xf 
		add	al, '0'
		cmp	al, '9'
		jle	notHex2
		add	al, 'A' - ('9' + 1)
notHex2:
		call	PSCPutChar
		sub	lineCount, 2
		ja	noNL
		mov	al, '\n'
		call	PSCPutChar
		mov	lineCount, MAX_LINE
noNL:
		.leave
		ret
PSCOutByte	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCFlushNonRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flush any pending non-run packet to the file

CALLED BY:	PSCSlice
PASS:		bh	= count of non-run bytes in current packet
		ds:dx	= start of non-run packet
RETURN:		bh	= new non-run count (> 0 if bh was too large on input;
			  note the size can only be off by one since we can
			  only add two bytes [for a run of only two matching
			  bytes] to the packet at a time)
		ds:dx	= adjusted to start of packet if bh non-zero
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCFlushNonRun	proc	near	uses si, cx
		.enter	inherit PSCSlice
		tst	bh
		jz	done
		mov	si, dx
		mov	al, bh		; Transfer count to AL for writing
		clr	cx		; Need in CX as well for looping
		mov	cl, al
		
		clr	bh		; Assume packet small enough
		dec	al		; By definition, reduce the count by 1
		jns	smallEnough	; => not 128, so we're ok.
		dec	cx
		dec	ax		; bring w/in range (one-byte
					;  instruction when use ax)...
		inc	bh		; Indicate extra byte hanging around
smallEnough:
		call	PSCOutByte	; Ship off the count byte
flushLoop:
		lodsb
		xor	al, ss:[invert]
		call	PSCOutByte
		loop	flushLoop
		tst	bh
		jz	done
		mov	dx, si		; Point dx to the start of the new
					;  packet
done:
		.leave
		ret
PSCFlushNonRun	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a single bitmap slice out to the file

CALLED BY:	DumpScreen
PASS:		bp	= file handle
		si	= bitmap block handle
		cx	= size of bitmap (bytes)
RETURN:		Carry set on error
		Block is *not* freed.
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:

	while (count > 0) {
	    count--;
	    match = *bp++;
	    matchCount = 1;

	    count matches until find non-matching or hit matchCount of 129;

	    if (matchCount > 2) {
		/*
		 * worthwhile repeating. Flush previous non-run, if any.
		 */
		if (nonrunCount != 0) {
		    write non-run packet, subtracting 1 from initial
		     count byte.
		}
		nonrunCount = 0
		output 257 - matchCount and match byte
	    } else {
		/*
		 * Merge unmatching data into existing non-run packet unless
		 * it won't fit.
		 */
		if (nonrunCount + matchCount > 128) {
		    /*
		     * Flush previous non-run
		     */
		    write non-run packet, subtracting 1 from initial
		     count byte.
		    nonrunCount = matchCount
		} else {
		    nonrunCount += matchCount
		}
	    }
	}
	if (nonrunCount != 0) {
	    flush pending non-run
	}

	register assignments:
		ds:si	= bp
		ah	= match
		cx	= count
		bl	= matchCount
		bh	= nonrunCount
		dx	= start of non-run

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCSlice	proc	near	uses ds, dx
buffer		local	PSCBuffer
lineCount	local	word
invert		local	byte
		.enter
		mov	ax, ss:[bp]
		mov	buffer.PB_file, ax
		mov	buffer.PB_ptr, 0
		mov	lineCount, MAX_LINE	; Initialize for PSCOutByte
		push	si			; Save block handle for free
		mov	bx, si
		call	MemLock
		mov	ds, ax
	;
	; Figure whether we need to invert the data we get from
	; the bitmap (required only for monochrome bitmaps)
	;
		CheckHack <BMF_MONO eq 0>
		clr	ax
		test	ds:[B_type], mask BMT_FORMAT
		jnz	setInvert
		dec	ax
setInvert:
		mov	ss:[invert], al
		mov	si, size Bitmap
		sub	cx, size Bitmap
		clr	bx			; initialize non-run
						;  count
byteLoop:
		lodsb				; Fetch next byte
		xor	al, ss:[invert]
		mov	ah, al			; Save it for comparison
		clr	bl			; Initialize run counter
matchLoop:
		inc	bl			; Another byte matched
		dec	cx			;  and consumed
		jcxz	endMatchLoop
		cmp	bl, MAX_RUN		; Hit bounds of run?
		je	endMatchLoop		; Oui.
		lodsb				; Non. See if next byte matches
		xor	al, ss:[invert]
		cmp	ah, al
		je	matchLoop
		mov	al, ah			; Need repeated byte in al...
		dec	si			; Don't skip non-match
endMatchLoop:
		cmp	bl, 2			; Worth repeating?
		jbe	dontBother
		push	ax
		call	PSCFlushNonRun		; Flush any pending non-run
		pop	ax
		xchg	al, bl			; Preserve repeated byte and
		clr	ah			;  get count into ax
		sub	ax, 257			; Figure repeat count byte
		neg	ax			; Operands in wrong order...
		call	PSCOutByte		; Print repeat count
		mov	al, bl			; Recover repeated byte
		call	PSCOutByte		;  and ship it off too
endLoop:
		jcxz	done			; Out of bytes?
		jmp	byteLoop		; Back into the fray
dontBother:
		;
		; Add the non-matching bytes into any current non-run packet.
		; If this is the start of one (bh [nonrunCount] is 0), we need
		; to record the start address of the packet for later flushing.
		;
		tst	bh
		jnz	alreadyStarted
		mov	dx, si
		sub	dl, bl			; Point back at start of non-
		sbb	dh, 0			;  matching range.
alreadyStarted:
		add	bh, bl			; Increase the length of the
						;  packet
		jno	endLoop			; => < 128, so we're still ok
		call	PSCFlushNonRun		; Flush the run. If bh > 128,
						;  this will take care of it.
		jmp	endLoop			; Test for finish...
done:
		;
		; Flush any pending non-run packet and free the block, 
		; signalling our success by returning with the carry clear.
		;
		call	PSCFlushNonRun
		mov	al, '\n'
		call	PSCPutChar
		call	PSCFlush
		pop	si			; Recover block handle
		mov	bx, si
		call	MemUnlock
		clc
		.leave
		ret
PSCSlice	endp

;
; Universal epilogue -- just add the Trailer comment (required) and pop our
; dictionary off the stack.
;
pscEpilogue	char '\
%%Trailer\n\
end\n'


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCEpilogue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish whatever we started here.

CALLED BY:	EXTERNAL
PASS:		bp	= file handle
RETURN:		carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCEpilogue	proc	near	uses ds, dx, cx
		.enter
		mov	bx, bp
		segmov	ds, cs, dx
		mov	dx, offset pscEpilogue
		mov	cx, size pscEpilogue
		clr	al
		call	FileWrite
		.leave
		ret
PSCEpilogue	endp

PSC		ends
