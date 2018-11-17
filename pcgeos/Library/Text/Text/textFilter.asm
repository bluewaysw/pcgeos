COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Text
FILE:		textFilter.asm

ROUTINES:
	Name			Description
	----			-----------
   	BufferFiltered
	CharacterFiltered?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

DESCRIPTION:
	This file contains routines to load a GEODE and execute it.

	$Id: textFilter.asm,v 1.1 97/04/07 11:18:05 newdeal Exp $

------------------------------------------------------------------------------@

TextFilter segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	FilterReplacement

DESCRIPTION:	Handle filtering of the replacement text

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ss:bp - VisTextReplaceParameters

RETURN:
	carry - set to reject

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 8/92		Initial version

------------------------------------------------------------------------------@
FilterReplacement	proc	far	uses di
	class	VisTextClass
	.enter

	; first do normal filter

	mov	di, offset FilterCallback
	call	TS_EnumTextReference
	jc	done

	; now look for an extended filter

	call	ExtendedFilterBuffer
done:
	.leave
	ret

FilterReplacement	endp

TextFilter_DerefVis_DI	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
TextFilter_DerefVis_DI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TF_CheckIfCharFiltered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a character should be filtered

CALLED BY:	GLOBAL
PASS:		ax - char
		*ds:si - VisText object
RETURN:		carry set if filtered
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TF_CheckIfCharFiltered	proc	far		uses	cx
	.enter
	mov	cx, ax
	call	FilterCallback
	.leave
	ret
TF_CheckIfCharFiltered	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FilterCallback

DESCRIPTION:	Filter a character

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	SBCS:
		cl - character
	DBCS:
		cx - character

RETURN:
	SBCS:
		cl - character, perhaps upcased
	DBCS:
		cx - character, perhaps upcased
	carry - set to filter

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 8/92		Initial version

------------------------------------------------------------------------------@
FilterCallback	proc	near	uses ax, bx, dx, di, bp
	class	VisTextClass
	.enter
	
	call	TextFilter_DerefVis_DI

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Filter out graphics if we don't have storage for them.
;	 5/20/93 -jw

	LocalCmpChar cx, C_GRAPHIC
	jne	5$
	
	;
	; The character is a graphic, check for being able to store them.
	;
	test	ds:[di].VTI_storageFlags, mask VTSF_GRAPHICS
	jz	filtered		; Branch if graphics are not supported
	
	;
	; The character is a graphic, and we do support graphics in this 
	; object, so we just keep going...
	;
	
5$:

;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	; filter space if needed

	mov	bl, ds:[di].VTI_filters
	test	bl, mask VTF_NO_SPACES		;are we allowing spaces?
	jz	10$				;yes, branch

;	HACK - we want to let tabs/CRs through here, so if CX is less than
;	the smallest space char, then let the character through

SBCS <	LocalCmpChar	cx, C_THINSPACE					>
DBCS <	LocalCmpChar	cx, C_THIN_SPACE				>
	jb	10$
	mov	ax, cx				;AX <- character
	call	LocalIsSpace
	jnz	filtered			;If space, filter it...
	
10$:
	test	bl, mask VTF_UPCASE_CHARS	;are we upcasing?
	jz	20$
	call	UpcaseChar			;else convert to uppercase
20$:

	; test for illegal chracters for this type of object

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	notSmall
	
	;
	; Check to make sure that column-breaks aren't allowed.
	;
	push	bx
	and	bl, mask VTF_FILTER_CLASS	; bl <- filter-class
	cmp	bl, VTFC_ALLOW_COLUMN_BREAKS	; Check for allowing c-breaks
	pop	bx
	je	notSmall			; Branch if allowing c-breaks

	LocalCmpChar cx, C_COLUMN_BREAK
	jz	filtered
notSmall:
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jz	notOneLine
	LocalCmpChar cx, C_CR
	mov	ax, MSG_META_TEXT_CR_FILTERED	;assume CR, set up filter msg
	jz	tabOrCR				;CR, send filter msg
notOneLine:

	LocalCmpChar cx, C_TAB			;see if tab
	jne	checkCharInClass		;branch if not
	test	bl, mask VTF_NO_TABS		;allowing tabs?
	jz	checkVardataFilter		;yes, don't filter them at all
	mov	ax, MSG_META_TEXT_TAB_FILTERED	;else check if filtering

tabOrCR:
	call	ObjCallInstanceNoLock
filtered:
	stc
	jmp	exit				;and exit

checkCharInClass:

	; Go through all the class filter and see if the character belongs.

	and	bl, mask VTF_FILTER_CLASS	;get class bits only
EC <	cmp	bl, VisTextFilterClass				>
EC <	ERROR_AE BAD_VIS_TEXT_FILTER					>
	tst	bl				;any class being used?
	jz	checkVardataFilter		;no, branch
ifdef	GPC_DOS_LONG_NAME
	;
	; Special-case: if VTFC_FILENAME, reject here any chars that are
	; legal GEOS filename chars but not legal DOS long filename chars.
	;
	; We could have changed the TextFilterGroups character grouping
	; instead of adding a special-case here.  We could have removed ',',
	; ';', '=', '[' and ']' from the TFG_OTHER_NON_DOS group and then
	; expand the TFG_PLUS group to include these character, and then add
	; the TFG_OTHER_NON_DOS bit to the bits used by VTFC_FILENAMES.
	; However, doing a special-case here seems to be easier to
	; understand, at the expense of some bytes.
	;
	; --- ayuen 10/14/99
	;
	cmp	bl, VTFC_FILENAMES
	jne	afterFilename
	push	bx
	mov	bx, offset nonDosLongNameChars
	call	CharInList?			;ZF set if found
	pop	bx
	je	filtered
afterFilename:
endif	; GPC_DOS_LONG_NAME
	cmp	bl, VTFC_ALLOW_COLUMN_BREAKS	;including characters?
	je	checkVardataFilter		;yes, branch

if DBCS_PCGEOS
	;
	; if allowing full-width digits, do so now
	; (check if full-width digit first, so we increase chances of not
	;  having to check vardata)
	;
	call	IsFullWidthNumeric?
	jne	noFullWidthDigits
	push	ax, bx
	mov	ax, ATTR_VIS_TEXT_ALLOW_FULLWIDTH_DIGITS
	call	ObjVarFindData
	pop	ax, bx
	jc	checkVardataFilter		;allow fullwidth digit
noFullWidthDigits:
endif

	clr	bh				;make bx
	shl	bx				;double for word offset
	mov	ax, cs:[bx].filterGroupFlags-2	;get flags from table

	; Flags now in ax.  We'll shift them out, one by one, and call the
	; appropriate filter routine for those bits that are set.

	mov	bx, offset filterGroupRoutines

filterLoop:
	rcr	ax				;rotate a flag into carry
	jnc	90$				;not filtering this, branch
	call	{word} cs:[bx]			;else call the filter routine
	je	filtered			;character found, exit
90$:
	add	bx, size nptr			;point to next routine
	cmp	bx, offset eFilterGroupRoutines ;see if past end of table
	jbe	filterLoop			;nope, do another bit

checkVardataFilter:
	mov	ax, ATTR_VIS_TEXT_CUSTOM_FILTER	;Exit if no custom filter
	call	ObjVarFindData
	jnc	notFiltered
	mov	bx, ds:[bx]		;BX <- chunk handle of filters
	mov	bx, ds:[bx]		;DS:BX <- ptr to array of filters
	ChunkSizePtr	ds, bx, dx		
.assert	size VisTextCustomFilterData eq 4
	shr	dx
	shr	dx			;DX <- # items in table.
	jz	notFiltered		;If no items, exit (no filter)
SBCS <	clr	ch							>
loopTop:
EC <	mov	ax, ds:[bx].VTCFD_startOfRange				>
EC <	cmp	ax, ds:[bx].VTCFD_endOfRange				>
EC <	ERROR_A	CUSTOM_FILTER_START_RANGE_IS_AFTER_END_RANGE		>
	cmp	cx, ds:[bx].VTCFD_startOfRange
	jb	next
	cmp	cx, ds:[bx].VTCFD_endOfRange
	ja	next
	stc	
	jmp	exit
next:
	add	bx, size VisTextCustomFilterData
	dec	dx
	jnz	loopTop
notFiltered:
	clc
exit:
	.leave
	ret
FilterCallback	endp

ifdef	GPC_DOS_LONG_NAME
nonDosLongNameChars	TCHAR	C_QUOTE, C_SLASH, C_LESS_THAN, C_GREATER_THAN,
				C_VERTICAL_BAR, -1
endif	; GPC_DOS_LONG_NAME

TextFilterGroups record

	; This are hacks, typically used alone, for filters that don't work
	; under my original category scheme.  The list grows...

	TFG_NON_DOS_CHARS:1	;characters not found in DOS char set.
	TFG_NON_DATE:1,		;used alone with TFC_DATE for simplicity
	TFG_NON_TIME:1,		;ditto
	TFG_NON_FLOAT_DECIMAL:1,   ;uses the IS_NUM_CHARS localization thing.
				   ;   because the decimal point varies.
	TFG_NON_ASCII:1		;anything not in normal ascii range

	; These are exclusive.  No char appears in two groups.  Well behaved
	; filters use these.  Read from TFG_ALPHA up to understand the groupings

	TFG_EXTENDED_NON_ALPHA:1  ;other chars out of the normal ascii range
	TFG_OTHER_NON_EXTENDED:1, ;other ascii chars not covered
	TFG_OTHER_NON_DOS:1,	  ;other chars not allowed by DOS
	TFG_MINUS:1,		  ;minus
	TFG_PLUS:1,		  ;plus
	TFG_WILDCARDS:1,	  ;search characters
	TFG_COLON_BS:1,		  ;colon or backslash
	TFG_PERIOD:1, 		  ;period
	TFG_NUMERIC:1, 		  ;the numeric characters
	TFG_E:1,		  ;the letter 'E', broken out to allow E's in
				  ;  floating point numbers
	TFG_ALPHA:1		  ;the alpha characters, including extendeds,
				  ;  except for the letter 'E'
end

filterGroupFlags	label	TextFilterGroups

; Don't reorganize these without changing the constants appropriately.



; Chars not allowed by VTFC_ALPHA

	dw  mask TFG_NUMERIC or mask TFG_PERIOD    or mask TFG_WILDCARDS or \
	    mask TFG_PLUS    or mask TFG_MINUS     or mask TFG_OTHER_NON_DOS or\
	    mask TFG_OTHER_NON_EXTENDED		   or mask TFG_COLON_BS  or \
	    mask TFG_EXTENDED_NON_ALPHA

; Chars not allowed by VTFC_NUMERIC

	dw  mask TFG_ALPHA   or mask TFG_E	or mask TFG_WILDCARDS or \
	    mask TFG_PLUS    or mask TFG_MINUS  or mask TFG_OTHER_NON_DOS   or \
	    mask TFG_OTHER_NON_EXTENDED	        or mask TFG_COLON_BS  or \
	    mask TFG_EXTENDED_NON_ALPHA		or \
	    mask TFG_PERIOD

; Chars not allowed by VTFC_SIGNED_NUMERIC

	dw  mask TFG_ALPHA    or mask TFG_E 	or mask TFG_PERIOD  or \
	    mask TFG_PLUS or \
	    mask TFG_WILDCARDS or \
	    mask TFG_OTHER_NON_DOS  or mask TFG_OTHER_NON_EXTENDED   or \
	    mask TFG_EXTENDED_NON_ALPHA or mask TFG_COLON_BS

; Chars not allowed by VTFC_SIGNED_DECIMAL

	dw  mask TFG_NON_FLOAT_DECIMAL or mask TFG_E

; Chars not allowed by VTFC_FLOAT_DECIMAL

	dw  mask TFG_NON_FLOAT_DECIMAL 

; Chars not allowed by VTFC_ALPHA_NUMERIC

	dw  mask TFG_PERIOD    or mask TFG_WILDCARDS or \
	    mask TFG_OTHER_NON_EXTENDED     or \
	    mask TFG_PLUS      or mask TFG_MINUS  or mask TFG_OTHER_NON_DOS or \
	    mask TFG_COLON_BS  or mask TFG_EXTENDED_NON_ALPHA

; Chars not allowed by VTFC_FILENAMES

	dw  mask TFG_WILDCARDS or mask TFG_COLON_BS

; Chars not allowed by VTFC_DOS_FILENAMES

	dw  mask TFG_WILDCARDS 		or mask TFG_COLON_BS or \
	    mask TFG_OTHER_NON_DOS 	or \
	    mask TFG_PLUS  		or mask TFG_NON_DOS_CHARS

; Chars not allowed by VTFC_DOS_PATH

if PZ_PCGEOS
	dw  mask TFG_WILDCARDS or mask TFG_OTHER_NON_DOS or \
	    mask TFG_PLUS      or \
	    mask TFG_NON_DOS_CHARS
else
	dw  mask TFG_WILDCARDS or mask TFG_OTHER_NON_DOS or \
	    mask TFG_PLUS      or mask TFG_EXTENDED_NON_ALPHA or \
	    mask TFG_NON_DOS_CHARS
endif


; Chars not allowed by VTFC_DATE 

	dw  mask TFG_NON_DATE

; Chars not allowed by VTFC_TIME 

	dw  mask TFG_NON_TIME


; Chars not allowed by VTFC_DASHED_ALPHA_NUMERIC

	dw  mask TFG_PERIOD    or mask TFG_WILDCARDS or \
	    mask TFG_OTHER_NON_EXTENDED     or \
	    mask TFG_PLUS      or mask TFG_OTHER_NON_DOS   or \
	    mask TFG_COLON_BS  or mask TFG_EXTENDED_NON_ALPHA


; Chars not allowed by VTFC_NORMAL_ASCII

	dw  mask TFG_NON_ASCII


; Chars not allowed by VTFC_DOS_VOLUME_NAMES

if PZ_PCGEOS

	dw  mask TFG_WILDCARDS 		or mask TFG_COLON_BS or \
	    mask TFG_OTHER_NON_DOS 	or \
	    mask TFG_PLUS or \
	    mask TFG_PERIOD or mask TFG_NON_DOS_CHARS

else

	dw  mask TFG_WILDCARDS 		or mask TFG_COLON_BS or \
	    mask TFG_OTHER_NON_DOS 	or \
	    mask TFG_PLUS  or mask TFG_EXTENDED_NON_ALPHA or \
	    mask TFG_PERIOD or mask TFG_NON_DOS_CHARS
endif


; Chars not allowed by VTFC_DOS_CHARACTER_SET

	dw  mask TFG_NON_DOS_CHARS

; Chars not allowed by VTFC_ALLOW_COLUMN_BREAKS

	dw	0			; not used

; Chars not allowed by VTFC_ALL_NUMERIC

	dw  mask TFG_ALPHA   or mask TFG_E	or mask TFG_WILDCARDS or \
	    mask TFG_PLUS    or mask TFG_MINUS  or mask TFG_OTHER_NON_DOS   or \
	    mask TFG_OTHER_NON_EXTENDED	        or mask TFG_COLON_BS  or \
	    mask TFG_EXTENDED_NON_ALPHA		or \
	    mask TFG_PERIOD

; Chars not allowed by VTFC_ALL_ALPHA_NUMERIC

	dw  mask TFG_PERIOD    or mask TFG_WILDCARDS or \
	    mask TFG_OTHER_NON_EXTENDED     or \
	    mask TFG_PLUS      or mask TFG_MINUS  or mask TFG_OTHER_NON_DOS or \
	    mask TFG_COLON_BS  or mask TFG_EXTENDED_NON_ALPHA

;-------------------------------------------


filterGroupRoutines		label	word
	dw 	offset IsAlpha?			;keep in order of bits in
	dw	offset IsE?			;  TextFilterGroups!
	dw	offset IsNumeric?		
	dw	offset IsPeriod?
	dw	offset IsColonOrBackslash?
	dw	offset IsWildcard?
	dw	offset IsPlus?
	dw	offset IsMinus?
	dw	offset IsOtherNonDos?
	dw	offset IsOtherNonExtended?
	dw	offset IsExtendedNonAlpha?
	dw	offset IsNonAscii?
	dw	offset IsNonFloatDecimal?
	dw	offset IsNonTime?
	dw	offset IsNonDate?
	dw	offset IsNonDosChar?
eFilterGroupRoutines		label	char



COMMENT @----------------------------------------------------------------------

ROUTINE:	IsAlpha?, etc.

SYNOPSIS:	Text filter routines.  Filters out a class of characters.

CALLED BY:	CharacterFiltered? through a vector

PASS:		cx  -- character in question

RETURN:		zero flag SET if character in the class of characters

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 6/90		Initial version

------------------------------------------------------------------------------@
IsAlpha?	proc	near
	uses	ax, di
	.enter

	LocalCmpChar cx, 'E'			;allow 'E's.  If we don't want
	je	exitNoMatch			;  them, we'll filter them
	LocalCmpChar cx, 'e'			;  using TFG_E.
	je	exitNoMatch

SBCS <	clr	ax							>
SBCS <	mov	al, cl							>
DBCS <	mov	ax, cx							>
	call	LocalIsAlpha
	jz	exitNoMatch			;not alpha char, exit no match

	clr	al				;force zero flag on
	jmp	short exit			;and branch

exitNoMatch:
	LocalIsNull ax				;force zero flag off
exit:
	.leave
	ret
IsAlpha?	endp

;-----------------------------------------------------------------------------

IsE?	proc	near
	LocalCmpChar cx, 'E'
	je	exit	
	LocalCmpChar cx, 'e'
exit:
	ret
IsE?	endp

;-----------------------------------------------------------------------------

IsNumeric?	proc	near
	LocalCmpChar cx, '0'			;below numeric, branch
	jb	exitNoMatch
	LocalCmpChar cx, '9'			;above numeric, branch
	ja	exitNoMatch
SBCS <	test	cl, 0				;else force zero flag on >
DBCS <	test	cx, 0				;else force zero flag on >
	jmp	short exit			;and exit

exitNoMatch:
SBCS <	tst	cl				;force zero flag off	>
DBCS <	tst	cx				;force zero flag off	>
exit:
	ret
IsNumeric?	endp

if DBCS_PCGEOS
IsFullWidthNumeric?	proc	near
	LocalCmpChar cx, C_FULLWIDTH_DIGIT_ZERO	;below numeric, branch
	jb	exitNoMatch
	LocalCmpChar cx, C_FULLWIDTH_DIGIT_NINE	;above numeric, branch
	ja	exitNoMatch
	test	cx, 0				;else force zero flag on
	jmp	short exit			;and exit

exitNoMatch:
	tst	cx				;force zero flag off
exit:
	ret
IsFullWidthNumeric?	endp
endif

;-----------------------------------------------------------------------------
IsPeriod?	proc	near
	LocalCmpChar cx, '.'
	ret
IsPeriod?	endp

;-----------------------------------------------------------------------------

IsColonOrBackslash?	proc	near
	LocalCmpChar cx, C_BACKSLASH
	je	exit
	LocalCmpChar cx, ':'
exit:
	ret
IsColonOrBackslash?	endp

;-----------------------------------------------------------------------------

IsWildcard?	proc	near
	LocalCmpChar cx, '*'
	je	exit
	LocalCmpChar cx, '?'
exit:
	ret
IsWildcard?	endp

;-----------------------------------------------------------------------------
IsPlus?		proc	near
	LocalCmpChar cx, '+'
	ret
IsPlus?		endp

;-----------------------------------------------------------------------------
IsMinus?	proc	near
	LocalCmpChar cx, '-'
	ret
IsMinus?	endp

;-----------------------------------------------------------------------------

IsNonAscii?	proc	near
	LocalCmpChar cx, ' '			;below a space?
	jb	exitMatch			;yes, filter all of these
	LocalCmpChar cx, '~'			;above a tilde?
	ja	exitMatch			;yes, filter all of these
SBCS <	tst	cl				;clear zero flag for no match>
DBCS <	tst	cx				;clear zero flag for no match>
	jmp	short exit			;and exit
exitMatch:
	clr	al				;set zero flag for match
exit:
	ret
IsNonAscii?	endp

;-----------------------------------------------------------------------------

IsOtherNonDos?	proc	near
	push	bx
	mov	bx, offset nonDosChars		;point to our list
	call	CharInList?			;see if we have a match
	pop	bx
	ret
IsOtherNonDos?	endp

if DBCS_PCGEOS
nonDosChars	wchar	"\",/;<=>[\]|", 0xffff	;sorted, with 0xffff at end
else
nonDosChars	db	"\",/;<=>[\]|", 0ffh	;sorted, with 0ffh at end
endif

;-----------------------------------------------------------------------------
IsOtherNonExtended?	proc	near
	push	bx
	mov	bx, offset otherChars		 ;point to our list
	call	CharInList?			 ;see if we have a match
	pop	bx
	ret
IsOtherNonExtended?	endp

if DBCS_PCGEOS
otherChars	wchar	"!#$%&\'()@^_`{}~", 0xffff ;sorted, with 0xffff at end
else
otherChars	db	"!#$%&\'()@^_`{}~", 0ffh ;sorted, with 0ffh at end
endif

;-----------------------------------------------------------------------------
IsExtendedNonAlpha?	proc	near
	uses	ax, di
	.enter

	LocalCmpChar cx, ' '			;below a space?
	jb	exitMatch			;yes, filter all of these

SBCS <	clr	ax							>
SBCS <	mov	al, cl				;move char to al	>
DBCS <	mov	ax, cx							>
	call	LocalIsAlpha
	jnz	exit				;no match, exit with z clear

	LocalCmpChar cx, '~'			;above a tilde?
	ja	exitMatch			;yes, filter all of these
SBCS <	tst	cl				;clear zero flag for no match>
DBCS <	tst	cx				;clear zero flag for no match>
	jmp	short exit			;and exit
exitMatch:
	clr	al				;set zero flag for match
exit:
	.leave
	ret
IsExtendedNonAlpha? endp

;-----------------------------------------------------------------------------

IsNonDate?	proc	near

SBCS <		uses	ax, di						>
DBCS <		uses	ax						>
	.enter

SBCS <	clr	ax							>
SBCS <	mov	al, cl							>
DBCS <	mov	ax, cx							>
	call	LocalIsDateChar			;zero flag cleared if a date
						;  char, hence set if NonDate
	.leave					;  which is what we want.
	ret

IsNonDate?	endp

;-----------------------------------------------------------------------------

IsNonTime?	proc	near

SBCS <		uses	ax, di						>
DBCS <		uses	ax						>
	.enter

SBCS < 	clr	ax							>
SBCS <	mov	al, cl							>
DBCS <	mov	ax, cx							>
	call	LocalIsTimeChar			;zero flag cleared if a time
						;   char, hence set if NonTime
	.leave					;   which is what we want.
	ret

IsNonTime?	endp

;-----------------------------------------------------------------------------


IsNonFloatDecimal?	proc	near
SBCS <		uses	ax, di						>
DBCS <		uses	ax						>
	.enter

	LocalCmpChar cx, 'E'			;allow 'E's.  If we don't want>
	je	exitNoMatch			;  them, we'll filter them
	LocalCmpChar cx, 'e'			;  using TFG_E.
	je	exitNoMatch

SBCS <	clr	ax							>
SBCS <	mov	al, cl							>
DBCS <	mov	ax, cx							>
	call	LocalIsNumChar			;zero flag cleared if a num
	jmp	short exit			;  char, hence set if NonNum
						;  which is what we want.
exitNoMatch:
SBCS <	tst	cl				;force zero flag off	>
DBCS <	tst	cx				;force zero flag off	>
exit:
	.leave
	ret

IsNonFloatDecimal?	endp

;-----------------------------------------------------------------------------

IsNonDosChar?		proc	near
SBCS <	uses	ax, di							>
DBCS <	uses	ax, bx, dx						>
	.enter

SBCS <	clr	ax							>
SBCS <	mov	al, cl							>
DBCS <	mov	ax, cx							>
DBCS <	clr	bx, dx			;bx <- cur code page, dx <- cur disk>
	call	LocalIsDosChar

	.leave
	ret

IsNonDosChar?		endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	CharInList?

SYNOPSIS:	Sees if the passed character matches a char in the passed list.

CALLED BY:	IsNonDos?, IsOther?

PASS:	SBCS:
		cl    -- character
	DBCS:
		cx    -- character
		cs:bx -- points to start of ascii-sorted, 0ffh terminated list

RETURN:		zero flag SET if match found, CLEAR otherwise

DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 7/90		Initial version

------------------------------------------------------------------------------@
CharInList?	proc	near
SBCS <	cmp	cl, cs:[bx]			;compare to char in list>
DBCS <	cmp	cx, cs:[bx]			;compare to char in list>
	je	exitMatch			;matches, exit with a match
	jb	exitNoMatch			;if smaller, exit no match
	LocalNextChar cxbx			;next char
	jmp	short CharInList?		;loop to do another

exitNoMatch:
SBCS <	tst	cl				;force zero flag off	>
DBCS <	tst	cx				;force zero flag off	>
	jmp	short exit			;and exit

exitMatch:
	clr	bx				;force zero flag on
exit:
	ret
CharInList?	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	UpcaseChar

SYNOPSIS:	Converts character to uppercase if a lowercase alpha.

CALLED BY:	FilterCallback

PASS:		*ds:si -- text object
		cl -- character

RETURN:		cl -- possibly changed to uppercase

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/14/92		Initial version

------------------------------------------------------------------------------@

UpcaseChar	proc	near
SBCS <	uses	ax, di							>
DBCS <	uses	ax							>
	.enter

	LocalCmpChar cx, 'a'			;not in a-z, exit
	jb	exit
	LocalCmpChar cx, 'z'
	ja	exit
SBCS <	clr	ax							>
SBCS <	mov	al, cl							>
DBCS <	mov	ax, cx							>
	call	LocalUpcaseChar
SBCS <	mov	cl, al							>
DBCS <	mov	cx, ax							>
exit:
	.leave
	ret
UpcaseChar	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ExtendedFilterBuffer

DESCRIPTION:	Determine if a given buffer is filtered (using extended
		filters)

CALLED BY:	FilterReplacement

PASS:
	*ds:si - text object
	ss:bp - VisTextReplaceParameters

RETURN:
	carry - set to reject buffer

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 8/92		Initial version

------------------------------------------------------------------------------@
ExtendedFilterBuffer	proc	far	uses ax, bx, cx, dx, di, bp
	class	VisTextClass
	.enter

	mov	ax, ATTR_VIS_TEXT_EXTENDED_FILTER
	call	ObjVarFindData
	LONG jnc done

	mov	al, ds:[bx]			;al = VisTextExtendedFilterType

	cmp	al, VTEFT_REPLACE_PARAMS
	jnz	notReplaceParams

	; filter by sending VisTextReplaceParameters out (a painful way to
	; filter, but easy for us :)

	mov	ax, MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS
	call	ObjCallInstanceNoLock
	jmp	done

notReplaceParams:
	cmp	al, VTEFT_CHARACTER_LEVELER_LEVEL
	jnz	notCharacterLevel

	; filter by sending a message character by character

	mov	di, offset CallFilterCallback
	call	TS_EnumTextReference
	jmp	done

notCharacterLevel:
EC <	cmp	al, VTEFT_BEFORE_AFTER					>
EC <	ERROR_NZ BAD_VIS_TEXT_FILTER					>

	; filter by creating a before and an after string and sending out
	; a message with both

	call	TextFilter_DerefVis_DI
EC <	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE		>
EC <	ERROR_NZ VIS_TEXT_REQUIRES_SMALL_TEXT_OBJECT			>

	; make a copy of the text chunk

	mov	bx, ds:[di].VTI_text
	push	bx				;save original chunk
	mov	bx, ds:[bx]
	ChunkSizePtr	ds, bx, cx
	clr	ax
	call	LMemAlloc			;ax = temp chunk
	mov	dx, ax				;dx = temp chunk
	push	si, ds, es
	segmov	es, ds
	call	TextFilter_DerefVis_DI
	xchg	ax, ds:[di].VTI_text		;store temp chunk as text
	mov	di, dx
	mov	di, ds:[di]			;es:di = dest
	mov_tr	si, ax
	mov	si, ds:[si]			;ds:si = source
	rep movsb
	pop	si, ds, es

	; do the replacement in the temp chunk

	call	TS_ReplaceRange

	; call the message to filter

	pop	cx				;cx = original chunk
	mov	dx, cx
	call	TextFilter_DerefVis_DI
	xchg	dx, ds:[di].VTI_text		;dx = new chunk
	push	dx

	mov	ax, MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER
	call	ObjCallInstanceNoLock
	pop	ax
	pushf					;save filter result
	call	LMemFree
	popf

done:
	.leave
	ret

ExtendedFilterBuffer	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CallFilterCallback

DESCRIPTION:	Filter on a character by character level

CALLED BY:	FilterBuffer (via TS_EnumTextReference)

PASS:
	*ds:si - text object
	cl - character

RETURN:
	cl - possibly new character
	carry - set to filter

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 8/92		Initial version

------------------------------------------------------------------------------@
CallFilterCallback      proc    near    uses ax, dx, bp
        .enter

        mov     ax, MSG_VIS_TEXT_FILTER_VIA_CHARACTER
        call    ObjCallInstanceNoLock
        tst_clc cx
        jnz     done
        stc
done:

        .leave
        ret

CallFilterCallback      endp

TextFilter	ends
