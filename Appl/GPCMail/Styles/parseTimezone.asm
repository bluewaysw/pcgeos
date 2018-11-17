COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1999 -- All Rights Reserved

PROJECT:	Mail
FILE:		parseTimezone

AUTHOR:		Gene Anderson

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/12/99		Initial revision

DESCRIPTION:

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AsmCode	segment resource

tzutStr TCHAR "UT", 0
tzgmtStr TCHAR "GMT", 0
tzestStr TCHAR "EST", 0
tzedtStr TCHAR "EDT", 0
tzcstStr TCHAR "CST", 0
tzcdtStr TCHAR "CDT", 0
tzmstStr TCHAR "MST", 0
tzmdtStr TCHAR "MDT", 0
tzpstStr TCHAR "PST", 0
tzpdtStr TCHAR "PDT", 0
tzzStr TCHAR "Z", 0
tzaStr TCHAR "A", 0
tzmStr TCHAR "M", 0
tznStr TCHAR "N", 0
tzyStr TCHAR "Y", 0

tzoffsetTab sword \
    0,     ; UT
    0,     ; GMT
    -5*60, ; EST
    -4*60, ; EDT
    -6*60, ; CST
    -5*60, ; CDT
    -7*60, ; MST
    -6*60, ; MDT
    -8*60, ; PST
    -7*60, ; PDT
    0,     ; Z = UT
    -1,    ; A
    -12,   ; M
    1,     ; N
    12     ; Y

tzstrTab nptr.TCHAR \
    tzutStr,
    tzgmtStr,
    tzestStr,
    tzedtStr,
    tzcstStr,
    tzcdtStr,
    tzmstStr,
    tzmdtStr,
    tzpstStr,
    tzpdtStr,
    tzzStr,
    tzaStr,
    tzmStr,
    tznStr,
    tzyStr

CheckHack <length tzoffsetTab eq length tzstrTab>

ParseTimezoneStr	proc	near
		uses	es, di
		.enter

		segmov	es, cs, di
		mov	cx, length tzstrTab
		clr	di
strLoop:
		push	cx, di
		mov	di, cs:tzstrTab[di]		;es:di <- ptr to string
		clr	cx				;cx <- NULL-terminated
		call	LocalCmpStringsNoCase
		pop	cx, di
		je	foundStr			;branch if match
	;
	; loop to next string
	;
		add	di, (size nptr)
		loop	strLoop
		clr	di				;di <- use GMT
foundStr:
		mov	ax, cs:tzoffsetTab[di]		;ax <- offset

		.leave
		ret
ParseTimezoneStr	endp

GetNumChar		proc	near
		LocalGetChar ax, dssi			;ax <- char
SBCS <		clr	ah				;>
		sub	ax, '0'				;ax <- convert
		jc	retZero				;branch if borrow
		cmp	al, 9				;non digit?
		jbe	done				;branch if digit
retZero:
		clr	ax
done:
		ret
GetNumChar		endp

ParseTimezoneNum	proc	near
	;
	; HhMm = H*600 + h*60 + M*10 + m
	;
		call	GetNumChar			;ax <- number
		mov	bx, 600
		mul	bx				;ax <- number *600
		mov	cx, ax				;cx <- offset GMT
		call	GetNumChar			;al <- number
		mov	bl, 60
		mul	bl				;ax <- number*60
		add	cx, ax				;cx <- offset GMT
		call	GetNumChar
		mov	bl, 10
		mul	bl				;ax <- number*10
		add	cx, ax				;cx <- offset GMT
		call	GetNumChar
		add	ax, cx				;ax <- offset GMT
		ret
ParseTimezoneNum	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseTimezone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	parse a timezone

CALLED BY:	FilterMailStyles() (C routine)

PASS:		str - ptr to timezone string
RETURN:		ax - offset of timezone to GMT
DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:	
 
  From RFC822:
 
      zone        =  "UT"  / "GMT"                ; Universal Time
                                                  ; North American : UT
                  /  "EST" / "EDT"                ;  Eastern:  - 5/ - 4
                  /  "CST" / "CDT"                ;  Central:  - 6/ - 5
                  /  "MST" / "MDT"                ;  Mountain: - 7/ - 6
                  /  "PST" / "PDT"                ;  Pacific:  - 8/ - 7
                  /  1ALPHA                       ; Military: Z = UT;
                                                  ;  A:-1; (J not used)
                                                  ;  M:-12; N:+1; Y:+12
                  / ( ("+" / "-") 4DIGIT )        ; Local differential
                                                  ;  hours+min. (HHMM)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/12/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PARSETIMEZONE	proc	far   dateStr:fptr.TCHAR
		uses	ds, si
		.enter

		lds	si, ss:dateStr			;ds:si <- string

		LocalGetChar ax, dssi, NO_ADVANCE
		call	LocalIsAlpha
		jnz	isStr
		LocalCmpChar ax, '+'
		je	isPlus
		LocalCmpChar ax, '-'
		je	isMinus
isNum:
		call	ParseTimezoneNum

done:
		.leave
		ret

	;
	; <string>: look it up in the table
	;
isStr:
		call	ParseTimezoneStr
		jmp	done

	;
	; +HHMM: consume +, parse num
	;
isPlus:
		LocalGetChar ax, dssi
		jmp	isNum

	;
	; -HHMM: consume -, parse num, negate
	;
isMinus:
		LocalGetChar ax, dssi			;consume -
		call	ParseTimezoneNum		;ax <- HHMM
		neg	ax				;ax <- -HHMM
		jmp	done
PARSETIMEZONE	endp

AsmCode ends
