COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet Driver
FILE:		fontInternalPCL4.asm

AUTHOR:		Gene Anderson, Apr 16, 1990
		Dave Durran, Apr 16, 1991

ROUTINES:
	Name			Description
	----			-----------
EXT	IsFontInPrinter		See if font currently in printer.
INT	AddFontEntry		Add entry for new font in printer.

EXT	LockFontInfo		Lock font manager info block.
EXT	UnlockFontInfo		Unlock font manager info block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/16/90		Initial revision
	Dave	4/16/91		New Initial revision
	Dave	1/92		Moved from Laserdwn

DESCRIPTION:
	Internal routines for soft-font manager.

	$Id: fontInternalPCL4.asm,v 1.1 97/04/18 11:49:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsFontInPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if font is already in printer
CALLED BY:	FontAddFace

PASS:		ds - addr. of the LMem structure.
		cx - # of fonts in printer
RETURN:		carry clear:
		    ds:si - ptr to SoftFontEntry
		    FDI_sfontSeg, and FDI_sfontOff loaded with SFE pointer.
		else:
		    font is not in printer
DESTROYED:	none (si if font not in printer)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsFontInPrinter	proc	near
	uses	ax, bx, cx, dx, di, es
curJob	local	FontDriverInfo
	.enter	inherit

	jcxz	exitFontNotFound		;branch if no fonts in printer

		;load up the test element.
	mov	es, curJob.FDI_pstate		;es <- seg addr of PState
		;first the font ID.
	mov	bx,es:[PS_curFont].FE_fontID	;get PCGEOS ID.
	mov	ds:[HPFI_testFontEntry].TFE_fontID,bx ;store in test ele.
		;next load the style
	mov	bx, es:[PS_asciiStyle]		;bx <- PrintTextStyles
	and	bx, not(mask TS_UNDERLINE)	;do not count underline as
						;a font parameter.
	mov	ds:[HPFI_testFontEntry].TFE_style,bx ;store in the test ele.
		;next pointsize.
	mov	bx, es:[PS_curFont].FE_size	;bx <- pointsize
	mov	ds:[HPFI_testFontEntry].TFE_pointsize,bx ;store in the test ele.
		;next, trackKerning..
	mov	ax,es:PS_curOptFont.OFE_trackKern ;+load the track kern value.
	mov	dh,al				;+set up for the Next call
	mov	al,ah				;+
	cbw					;+
	xchg	dx,ax				;+
	call	PointsToPCL			;+convert to dots.
	mov	ds:[HPFI_testFontEntry].TFE_optFontEntry.OFE_trackKern,ax 

		;load the PState opt font info.
	mov	al,es:[PS_curOptFont].OFE_fontWidth
	mov	ds:[HPFI_testFontEntry].TFE_optFontEntry.OFE_fontWidth,al
	mov	al,es:[PS_curOptFont].OFE_fontWeight
	mov	ds:[HPFI_testFontEntry].TFE_optFontEntry.OFE_fontWeight,al 
	mov	al,es:[PS_curOptFont].OFE_color.RGB_red
	mov	ds:[HPFI_testFontEntry].TFE_optFontEntry.OFE_color.RGB_red,al
	mov	al,es:[PS_curOptFont].OFE_color.RGB_green
	mov	ds:[HPFI_testFontEntry].TFE_optFontEntry.OFE_color.RGB_green,al
	mov	al,es:[PS_curOptFont].OFE_color.RGB_blue
	mov	ds:[HPFI_testFontEntry].TFE_optFontEntry.OFE_color.RGB_blue,al
	mov	ax,es:[PS_curOptFont].OFE_spacePad
	mov	ds:[HPFI_testFontEntry].TFE_optFontEntry.OFE_spacePad,ax

		;test all the font entries for the specified parameters.
	push	es
	segmov	es,ds,si
	mov	si,ds:HPFI_fontEntries		;get the handle of the chunkarr
	mov	di,offset CompareFontEntries	;load call back routine
	mov	bx,cs				
	call	ChunkArrayEnum
	pop	es
	jc	exitFontFound			;if all the entries were tested
						; and no match exit with 
						; carry set.

exitFontNotFound:
	stc					;indicate not found

done:
	.leave
	ret

exitFontFound:
	mov	curJob.FDI_sfontSeg,ds
	mov	curJob.FDI_sfontOff,dx
	mov	si,dx				;get deref'ed element addr.
	clc					;indicate font found
	jmp	done

IsFontInPrinter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddFontEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add font in printer entry for a font, mark as on current page.
CALLED BY:	FontAddFace

PASS: 		ds - seg addr of font info block
		curJob.FDI_pstate - seg addr of PState
		ax - HP font ID of font
RETURN:		ds - (new) seg addr of font info block
		si - (new) offset for soft font info block.
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddFontEntry	proc	near
	uses	bx, cx, dx, es
curJob	local	FontDriverInfo
	.enter	inherit

	push	ax				;save font ID
	mov	si, ds:HPFI_fontEntries		;si <- chunk arr handle
	call	ChunkArrayAppend		;new font entry, init space
	mov	curJob.FDI_sfontSeg,ds
	mov	curJob.FDI_sfontOff,di

	inc	ds:HPFI_numFonts		;one more font in printer

	mov	si, di				;ds:si <- ptr to element

	;
	; Initialize the font entry. It has already been
	; zero'd, so we just need stuff in the text attributes
	; and set the flags appropriately.
	;
	mov	es, curJob.FDI_pstate		;es <- seg addr of PState
	mov	ax, es:PS_curFont.FE_size	;<- pointsize
	mov	ds:[si].SFE_pointsize, ax
	mov	ax, es:PS_asciiStyle	; <- PrintTextStyles
	and	ax, not(mask TS_UNDERLINE)	;do not count underline as
						;a font parameter.
	mov	ds:[si].SFE_style, ax
	mov	ds:[si].SFE_orientation,HPO_PORTRAIT ;FORCE PORTRAIT FOR NOW!
	clr	ds:[si].SFE_numChars		;<- no characters yet
	ornf	ds:[si].SFE_flags, mask SFF_ON_PAGE ;<- mark as on current page
	mov {word} ds:[si].SFE_size, HP_FONT_SIZE ;<- store size in printer
	pop	ds:[si].SFE_fontTag		;<- set HP font ID
	mov	ax, es:PS_curFont.FE_fontID ;GEOS font ID.
	mov	ds:[si].SFE_fontID, ax
	mov	ax,es:PS_curOptFont.OFE_trackKern		;+load the track kern value.
	mov	dh,al				;+set up for the Next call
	mov	al,ah				;+
	cbw					;+
	xchg	dx,ax				;+
	call	PointsToPCL			;+convert to dots.
	mov	ds:[si].SFE_optFontEntry.OFE_trackKern,ax	
		;add the opt font info in from the PState.
	mov	al,es:[PS_curOptFont].OFE_color.RGB_red
	mov	ds:[si].[SFE_optFontEntry].OFE_color.RGB_red,al
	mov	al,es:[PS_curOptFont].OFE_color.RGB_green
	mov	ds:[si].[SFE_optFontEntry].OFE_color.RGB_green,al
	mov	al,es:[PS_curOptFont].OFE_color.RGB_blue
	mov	ds:[si].[SFE_optFontEntry].OFE_color.RGB_blue,al
	mov	al,es:[PS_curOptFont].OFE_fontWeight
	mov	ds:[si].[SFE_optFontEntry].OFE_fontWeight,al
	mov	al,es:[PS_curOptFont].OFE_fontWidth
	mov	ds:[si].[SFE_optFontEntry].OFE_fontWidth,al
	mov	ax,es:[PS_curOptFont].OFE_spacePad
	mov	ds:[si].[SFE_optFontEntry].OFE_spacePad,ax

	.leave
	ret
AddFontEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareFontEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	called to compare the test font entry against ds:di
CALLED BY:	INTERNAL: IsFontInPrinter ChunkArrayEnum callback

PASS:		ds:di	element to compare
		es:	segment of the array (=ds)
RETURN:		carry set if font found.
DESTROYED:	none (not even flags)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dave	9/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareFontEntries	proc	far
	mov	dx,di				;save the offset of this ele.
	mov	si,offset HPFI_testFontEntry	;get address of the test.
	mov	cx,(size TestFontEntry) shr 1	;get size of entry in words.
if ((size TestFontEntry) and 1)
	cmpsb
	jnz	exitNotThisOne
endif
	repz cmpsw				;compare the structures.
	jnz	exitNotThisOne

		;if here, then this is it.
	stc
	jmp	exit

exitNotThisOne:
	clc

exit:	
	ret
CompareFontEntries	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockFontInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the soft-font manager block
CALLED BY:	INTERNAL: FontStartPage, FontAddFace, FontAddChars,
			  FontCompactHeap

PASS:		curJob.FDI_pstate - PState segment
RETURN:		*ds:si - ptr to font list (if any)
		cx - # of soft fonts in use
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockFontInfo	proc	near
	uses	ax, bx
curJob	local	FontDriverInfo
	.enter	inherit

	mov	ds, curJob.FDI_pstate				;ds <- seg addr of PState
	mov	bx, ds:PS_expansionInfo		;bx <- handle of manager blk
	call	MemLock
	mov	ds, ax				;ds <- seg addr of info block
	mov	cx, ds:HPFI_numFonts		;cx <- # of soft fonts
	mov	si, ds:HPFI_fontEntries		;si <- font chunk handle

	.leave
	ret
LockFontInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockFontInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the soft-font manager block.
CALLED BY:	INTERNAL: FontStartPage, FontAddFace, FontAddChar,
			  FontCompactHeap

PASS:		curJob.FDI_pstate - PState segment
RETURN:		none
DESTROYED:	none (not even flags)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnlockFontInfo	proc	near
	uses	bx, ds
curJob	local	FontDriverInfo
	.enter	inherit

	pushf
	mov	ds, curJob.FDI_pstate				;ds <- seg addr of PState
	mov	bx, ds:PS_expansionInfo		;bx <- handle of manager blk
	call	MemUnlock
	popf

	.leave
	ret
UnlockFontInfo	endp
