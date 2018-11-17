COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		stringCase.asm

AUTHOR:		Gene Anderson, Dec  6, 1990

ROUTINES:
	Name			Description
	----			-----------
  EXT	LocalUpcaseChar		Upcase a single character
  EXT	LocalDowncaseChar	Downcase a single character
  EXT	LocalUpcaseString	Upcase a buffer
  EXT	LocalDowncaseString	Downcase a buffer

  INT	ConvertString		Upcase or downcase a string

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	12/ 6/90	Initial revision

DESCRIPTION:
	Upcase / downcase routines

	$Id: stringCase.asm,v 1.1 97/04/05 01:16:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringMod	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalUpcaseChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upcase a single char
CALLED BY:	GLOBAL

PASS:		ax - character to upcase
RETURN:		ax - uppercase character

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/ 6/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalUpcaseChar	proc	far
SBCS <	uses	si							>
DBCS <	uses	bx							>
	.enter

if DBCS_PCGEOS
	call	UpcaseCharInt
else

EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>

	cmp	al, MIN_UPCASE
	jb	noMapping
	sub	al, MIN_UPCASE
	mov	si, ax
	andnf	si, 0x00ff
 	mov	al, cs:UpcaseTable[si]
noMapping:

endif

	.leave
	ret
LocalUpcaseChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalDowncaseChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Downcase a single character
CALLED BY:	GLOBAL

PASS:		ax - character to downcase
RETURN:		ax - downcase character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/ 6/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalDowncaseChar	proc	far
SBCS <	uses	si							>
DBCS <	uses	bx							>
	.enter

if DBCS_PCGEOS
	call	DowncaseCharInt
else

EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>

	cmp	al, MIN_DOWNCASE
	jb	noMapping
	sub	al, MIN_DOWNCASE
	mov	si, ax
	andnf	si, 0x00ff
 	mov	al, cs:DowncaseTable[si]
noMapping:

endif

	.leave
	ret
LocalDowncaseChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalUpcaseString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a string to uppercase.
CALLED BY:	GLOBAL

PASS:		ds:si - ptr to string
		cx - max # of chars to convert (or 0 for NULL terminated)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalUpcaseString	proc	far
	
if	FULL_EXECUTE_IN_PLACE
EC <	push	bx					>
EC <	mov	bx, ds					>
EC <	call	ECAssertValidFarPointerXIP		>
EC <	pop	bx					>
endif

if DBCS_PCGEOS
	push	bp
	mov	bp, offset UpcaseCharInt
	GOTO	ConvertString, bp
else
	push	ax, bx
	mov	bx, offset UpcaseTable		;bx <- ptr to conversion table
	mov	ah, MIN_UPCASE			;ah <- minimum value in table
	GOTO	ConvertString, bx, ax
endif
LocalUpcaseString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalDowncaseString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a string to lower case.
CALLED BY:	GLOBAL

PASS:		ds:si - ptr to string
		cx - max # of chars to convert (or 0 for NULL terminated)
RETURN:		none
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	LocalDowncaseString
LocalDowncaseString	proc	far

if	FULL_EXECUTE_IN_PLACE
EC <	push	bx					>
EC <	mov	bx, ds					>
EC <	call	ECAssertValidFarPointerXIP		>
EC <	pop	bx					>
endif

if DBCS_PCGEOS
	push	bp
	mov	bp, offset DowncaseCharInt
	FALL_THRU	ConvertString, bp
else
	push	ax, bx
	mov	bx, offset DowncaseTable	;bx <- ptr to conversion table
	mov	ah, MIN_DOWNCASE		;ah <- minimum value in table
	FALL_THRU	ConvertString, bx, ax
endif
LocalDowncaseString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a string using a conversion table.
CALLED BY:	LocalUpcaseString, LocalDowncaseString

PASS:	SBCS:
		cs:bx - ptr to conversion table
		ah - minimum mappable character
	DBCS:
		bp - offset of conversion routine

		cx - max # of chars to convert (or 0 for NULL terminated)
		ds:si - ptr to string
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertString	proc	far
SBCS <	uses	cx, si, di, es						>
DBCS <	uses	cx, si, di, es, ax, bx					>
	.enter

	segmov	es, ds				;both ds:si, es:di ptrs
	mov	di, si				;  to string
CS_loop:
	LocalGetChar	ax, dssi		;ax <- char of string
if DBCS_PCGEOS
	call	bp				;upcase/downcase char
else

SBCS <	cmp	al, ah				;see if mappable	>
	jb	noMap				;branch if not mappable
SBCS <	sub	al, ah				;move to start of table	>
SBCS <	xlat	cs:UpcaseTable			;convert byte		>
noMap:
endif
	LocalPutChar	esdi, ax		;store char of string
	LocalIsNull	ax			;reached NULL terminator?
	loopne	CS_loop				;loop until NULL or cx==0

	.leave
SBCS <	FALL_THRU_POP	bx, ax						>
DBCS <	FALL_THRU_POP	bp						>
	ret
ConvertString	endp

StringMod	ends
