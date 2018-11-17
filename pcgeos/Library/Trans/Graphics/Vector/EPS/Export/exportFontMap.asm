
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		Export/exportFontMap.asm

AUTHOR:		Jim DeFrisco, 15 April 1991

ROUTINES:
	Name			Description
	----			-----------
	CalcFontDiff		return a number giving the relative distance
				between two fontIDs

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/15/91		Initial revision


DESCRIPTION:
	This routine implements a font-mapping algorithm that returns the 
	difference between two fontIDs
		

	$Id: exportFontMap.asm,v 1.1 97/04/07 11:25:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontMapping	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcFontDiff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the difference between two fontIDs

CALLED BY:	GLOBAL

PASS:		ax	- fontID desired
		bx	- fontID to test against

RETURN:		cl	- "distance" between the two.  (FontMap enum)
			   The smaller the number, the closer the typefaces.  
			   This result should be treated as an unsigned byte.
			   Special values:

			  	FM_EXACT    (0x00) - exact match
			  	FM_DONT_USE (0xff) - do not sub test fontID

DESTROYED:	ch

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		FM_DONT_USE is returned under two circumstances:
			* The fonts are in different families
			* There is no mapping rules for the family
			  ( this is true, currently, for ORNAMENT, SYMBOL
			   and MONO fonts)

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


NO_MAPPING_TABLE	equ	0xffff
ANY_MAPPING_OK		equ	0xfffe

FID_MAKER_BITS		equ	0xf0		; hi byte of fontID
FID_FAMILY_BITS	equ	0x0e		; hi byte of fontID

CalcFontDiff	proc	far
		uses	ax, bx, si
		.enter

		; remove the manufacturer codes

		and	ah, not FID_MAKER_BITS
		and	bh, not FID_MAKER_BITS

		; see if they are the same

		mov	cx, ax
		sub	cx, bx
		jcxz	done			; all done, exact match

		; see if they are in the same family

		mov	ch, ah 
		mov	cl, bh
		and	ch, FID_FAMILY_BITS	; isolate family bits
		and	cl, FID_FAMILY_BITS	; isolate family bits
		cmp	ch, cl			; if not the same, quit
		je	sameFamily		; not the same familty, quit

		; not same family, so we don't want to map them.  A slight
		; modification, however.  If one of the families is MONO, then
		; modify the return value to be slightly better than 
		; FM_DONT_USE.  The effect will be to map fonts that have no
		; good mapping to a MONO font.

		cmp	ch, FG_MONO shr 8	; see if 1st matches mono
		je	haveMono
		cmp	cl, FG_MONO shr 8
		jne	badFamily		; neither, return error
haveMono:
		mov	cl, FM_DONT_USE-1
		jmp	done
		
		; same family, calculate difference
sameFamily:
		clr	ch			; only need one of the fams
		and	bh, 1			; isolate 9-bits of faceID
		and	ah, 1
		mov	si, cx			; use as table index

		; make sure there is a mapping table for this family
		; NO_MAPPING_TABLE is found for fonts like ornament and symbol
		; fonts, where it really doesn't make sense to map between
		; fonts in these families.
		; ANY_MAPPING_OK is found (currently) only for MONO spaced 
		; fonts.  The idea is that it really doesn't matter which two
		; fonts we map between here.

		cmp	cs:[familyTable][si], NO_MAPPING_TABLE
		je	badFamily
		cmp	cs:[familyTable][si], ANY_MAPPING_OK
		je	notExactButOK

		; make sure we're not hanging off the end of the table

		cmp	ax, cs:[numMappings][si]
		ja	badFamily
		cmp	bx, cs:[numMappings][si]
		ja	badFamily

		; do the mapping, man
		; At this point, we know that the font is not an exact match.
		; After this next sequence of instructions, we'll end up with
		; a font difference between 1 and 0xfd (about)

		mov	si, cs:[familyTable][si] ; get pointer
		mov	cx, ax			; cx = first faceID
		push	ds
		push	bx
		mov	bx, handle FontMapping	; lock resource
		call	MemLock			; lock it down
		mov	ds, ax
		mov	ax, cx			; restore first faceID
		pop	bx
		mov	cl, ds:[si][bx]		; get font magic number
		mov	bx, ax			; setup second faceID
		sub	cl, ds:[si][bx]		; calc magic number diff
		jns	haveAnswer
		neg	cl			; return absolute value
haveAnswer:
		inc	cl			; one more, so we can reserve
						;  zero for exact matches
		mov	bx, handle FontMapping
		call	MemUnlock
		pop	ds			; restore segreg
done:
		.leave
		ret

		; different family
badFamily:
		mov	cl, FM_DONT_USE
		jmp	done

		; not exact font, but any mapping for MONO is ok.
notExactButOK:
		mov	cl, 1			; return code that is not
		jmp	done			; FM_EXACT, but is OK
CalcFontDiff	endp

familyTable	label	nptr.byte
		nptr	serifTable
		nptr	sansTable
		nptr	scriptTable
		nptr	NO_MAPPING_TABLE ; no mapping for ORNAMENT
		nptr	NO_MAPPING_TABLE ; no mapping for SYMBOL
		nptr	ANY_MAPPING_OK   ; any mapping OK for MONO

numMappings	label	word
		word	NUM_AFTER_SERIF	; constant set in fontID.def
		word	NUM_AFTER_SANS - NUM_AFTER_SERIF
		word	NUM_AFTER_SCRIPT - NUM_AFTER_SANS
		word	0 		; no mapping for ORNAMENT
		word	0 		; no mapping for SYMBOL
		word	0   		; no mapping for MONO

FontMapping	ends
