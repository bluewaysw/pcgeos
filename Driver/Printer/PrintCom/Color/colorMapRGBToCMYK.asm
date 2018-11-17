
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		color Print Drivers
FILE:		colorMapRGBToCMYK.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision
	Dave	5/92		Parsed from printcomEpsonColor.asm


DESCRIPTION:
		
	$Id: colorMapRGBToCMYK.asm,v 1.1 97/04/18 11:51:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrMapRGBtoCMYKIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take an RGB value and a CMYK palette, return color table index
		for ribbon type dot-matrix printers.

CALLED BY:	PrintSetColor

PASS:
		al	- R component to match
		bl	- G component to match
		bh	- B component to match

RETURN:		cx	- index


DESTROYED:	si

PSEUDO CODE/STRATEGY:
		Do the 3d distance calculation for each entry in the palette
		and record the closest one.  For efficiency sake, we use a
		simplified distance formula:
			dist = (delta-R + delta-G + delta-B +
				 max (delta-R,delta-G,delta-B)) / 2
		Also, since we don't need the exact distance (only for 
		comparisons), we don't do the final divide-by-2.  whoopie.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version
	Dave	3/92		Pirated version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
PrMapRGBtoCMYKIndex	proc	near
		uses	si,di,dx,ds
red	local	word
green	local	word
blue	local	word
		.enter

		clr	cx			; ch = curr index, cl=max index
		;special case for all three values being equal (shades of 
		;gray). we just print these as black.
		cmp	al,bl
		jne	startCheck
		cmp	al,bh
		je	done			; return 0 index (black)
startCheck:
		segmov	ds,cs,di		;get segment of the Palette.
		mov	si, offset RibbonPalette	;offset of same.
		mov	dh, ((offset endRibbonPalette-offset RibbonPalette) / 3)
		clr	ah			; make into a word
		mov	red, ax
		mov	al, bl			; get green
		mov	green, ax
		mov	al, bh			; get blue
		mov	blue, ax
		mov	di, 0xffff		; initialize di = max distance
		clr	ah

		;  loop through all the values
checkLoop:
		lodsb				; get r component
		sub	ax, red			; calc delta-R
		jns	redPos			; absolute value, of course
		neg	ax
redPos:
		mov	bx, ax			; start accumulation
		mov	dl, al			; save in case max
		lodsb				; next component
		sub	ax, green		; calc delta-G
		jns	greenPos		; absolute value, of course
		neg	ax
greenPos:
		add	bx, ax			; add it to accumulation
		cmp	al, dl			; check for largest component
		jb	skip2nd			;  no, skip this one
		mov	dl, al			;  yes, store for later
skip2nd:
		lodsb				; get b component
		sub	ax, blue		; calc delta-B
		jns	bluePos 		; absolute value, of course
		neg	ax
bluePos:
		add	bx, ax			; bump distance calc
		cmp	al, dl			; check for largest again
		jb	skip3rd			;  nope, continue
		mov	dl, al			;  yep, save it
skip3rd:
		mov	al, dl
		add	bx, ax			; add max

		; done with this entry, check if closer than one we saved

		cmp	bx, di			; check current vs max
		jae	nextOne			;  no, check next entry
		mov	di, bx			;  yes, save value
		mov	cl, ch			;  and save index too
nextOne:
		inc	ch			; on to next index
		jz	done
		cmp	ch, dh 			; check vs #entries
		jbe	checkLoop		; one to next entry

		; all done, get index for closest one and lookup RGB
done:
						; return index here
		clr	ch			; make index a word
		.leave
		ret
PrMapRGBtoCMYKIndex	endp
		;CURRENTLY TWEAKED WITH A STAR XB-2420 4-color RIBBON
RibbonPalette	label	byte
	byte	0,0,0		;black
	byte	170,47,212	;magenta
	byte	47,47,212	;cyan
	byte	47,0,170	;purple
	byte	212,212,47	;yellow
	byte	170,0,0		;red
	byte	0,200,0		;green

;	byte	0,0,0		;black
;	byte	170,0,170	;magenta
;	byte	85,85,255	;cyan
;	byte	255,85,255	;violet
;	byte	255,255,85	;yellow
;	byte	170,0,0		;red
;	byte	0,170,0		;green
endRibbonPalette	label	byte
