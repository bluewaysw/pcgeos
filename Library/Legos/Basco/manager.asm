COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bw_hack.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/15/94		Initial version.

DESCRIPTION:
	hack to deal with getting DS = dgroup

	$Id: manager.asm,v 1.1 98/10/13 21:43:10 martin Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include geos.def
include resource.def
include stdapp.def
include localize.def

global FGETC:far
global FSEEK:far
global FEOF:far
EOF equ (-1)

BCHACK segment resource

SetDefaultConvention
	

setDSToDgroup	proc	far
	mov	ax, ds		; return old DS in ax
	segmov	ds, dgroup, dx
	ret
setDSToDgroup	endp
	public	setDSToDgroup


restoreDS	proc	far	oldDS:word
	.enter
	segmov	ds, oldDS, ax
	.leave
	ret
restoreDS	endp
	public restoreDS


	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		adv_ws
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	optimized version of adv_ws from bwb_int.c
CALLED BY:	global
PASS:		buffer and pointer to integer of position in buffer
RETURN:		integer pointer updated
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_adv_ws	proc	far	buf:fptr, pos:fptr
	uses	ds,es,si,di
	.enter
	lds	si, buf
	les	di, pos
	mov	cx, es:[di]	;  get position
	add	si, cx		;  ds:si = position in buffer
if DBCS_PCGEOS			;  need to add twice as much for DBCS
	add	si, cx
endif
myloop:	
	inc	cx		;  keep track of new position
if DBCS_PCGEOS
	lodsw
	tst	ax
	jz	done
	cmp	ax, C_SPACE
	je	myloop
	cmp	ax, C_TAB
	je	myloop
else
	lodsb			;  get next characeter
	tst	al		;  have we reached the end of the string?
	jz	done
	cmp	al, C_SPACE
	je	myloop
	cmp	al, C_TAB
	je	myloop
endif
done:
	dec	cx
	mov	es:[di], cx
	.leave
	ret
_adv_ws	endp
	public _adv_ws

ifdef DO_DBCS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSJisChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get a shift jis character

CALLED BY:	
PASS:		ax = next type bytes from text string
RETURN:		ax = shift jis charater
		carry set if shift jis character is 2 bytes long
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		algorithm taken from jon's scan.c from GOC

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SJIS_SB_END_1	equ 0x7e 
SJIS_SB_START_2 equ 0xa1
SJIS_SB_END_2	equ 0xdf
; C_HALFWIDTH_IDEOGRAPHIC_PERIOD	equ 0xff61
CheckForSingleByte	proc	near
		.enter
		cmp	al, SJIS_SB_END_2
		ja	haveSecondByte
		
		cmp	al, SJIS_SB_END_1
		jbe	noSecondByte
		cmp	al, SJIS_SB_START_2
		jb	haveSecondByte
noSecondByte:
		clc
		jmp	done
haveSecondByte:
		stc
done:
		.leave
		ret
CheckForSingleByte	endp
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BascoLocalDosToGeos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		since fgetc reads two bytes at a time, i am setting up
	a state machine that has two states, in one state we have no
	extra bytes that have been read from the file, this is the
	readFirst state, the other state is if we have read an extra
	byte from the state, that is the gotAscii state. from the
	readFirst state, if we continue to read two-byte charaters, we
	stay in that state, if we read a one-byte charater we toggle
	to the gotAscii state. from the got asciiState we stay in that
	state if we read a two-byte character, and toggle if we hit a
	one-byte character

	I changed fgetc to read 1 byte at a time, so this is much
	simpler now
			

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
fgets_dbcs	proc	far 	dst:fptr,
					maxSize:word,
					myfile:dword
		uses	ds, si, es, di, cx, dx, bx
		.enter
	;	loop through dealing with shisft jis crap

	; first, get the next two bytes from the file
		les	di, dst
readFirst:
		cmp	di, maxSize
		jae	done
		
		pushdw	myfile
		call	FGETC
		
		cmp	al, EOF
		je	done

		cmp	al, SJIS_SB_END_1
		jbe	gotAscii
		
		call	CheckForSingleByte
		jc	getDouble
		clr	ah
		jmp	checkHalfWidthKana
getDouble:
		push	ax
		pushdw	myfile
		call	FGETC
		pop	bx
		mov	ah, bl
	; check for halfwidth katakana
		xchg	al, ah
checkHalfWidthKana:
		cmp	ax, SJIS_SB_END_2
		ja	notHalfWidthKana

		add	ax, C_HALFWIDTH_IDEOGRAPHIC_PERIOD
		sub	ax, SJIS_SB_START_2
		stosw
		jmp	readFirst
notHalfWidthKana:
		xchg	al, ah
		
		clr	dx
		mov	bx, CODE_PAGE_SJIS
		call	LocalDosToGeosChar
		stosw
		jmp	readFirst
gotAscii:
		
		stosb
		tst	al
		jz	doneWithStore
		cmp	al, '\n'
		jz	doneWithAddedNull
		cmp	al, 1ah	; check for control z
		jz	doneWithAddedNull
		
		clr	al
		stosb

	; now we need to fseek back the number of extra characters we
	; read
		pushdw	myfile
		call	FEOF
		tst	ax
		jnz	done
		jmp	readFirst		
doneWithAddedNull:
		clr	ax
		stosw
doneWithStore:
		clr	al
		stosb
done:
		.leave
		ret
fgets_dbcs	endp

if 0
GetSJisChar	proc	near
		.enter

		cmp	al, SJIS_SB_END_2
		ja	haveSecondByte
		
		cmp	al, SJIS_SB_END_1
		jbe	noSecondByte
		cmp	al, SJIS_SB_START_2
		jb	haveSecondByte
noSecondByte:
		clc
		jmp	done
haveSecondByte:
	; check for halfwidth katakana
		cmp	ax, SJIS_SB_END_2
		ja	notHalfWidthKana

		add	ax, C_HALFWIDTH_IDEOGRAPHIC_PERIOD
		sub	ax, SJIS_SB_START_2
notHalfWidthKana:
		stc
done:
		.leave
		ret
GetSJisChar	endp

		
BascoLocalDosToGeos	proc	far 	dst:fptr,
					disk:word,
					defaultChar:word,
					maxOrNull:word,
					codePage:word,
					myfile:dword,
					maxSize:word
		uses	ds, si, es, di, cx, dx, bx
		.enter
	;	loop through dealing with shisft jis crap

	; first, get the next two bytes from the file
		les	di, dst
readFirst:
		clr	dx
		cmp	di, maxSize
		jae	done
		pushdw	myfile
		call	FGETC
readTwoBytes:
		call	GetSJisChar
		jnc	gotAsciiWithStore

		mov	bx, codePage
		clr	dx
		xchg	al, ah
		call	LocalDosToGeosChar
		stosw
		jmp	readFirst
gotAsciiWithStore:
		stosb
gotAscii:
		mov	dx, 1
		tst	al
		jz	doneWithStore
		cmp	al, '\n'
		jz	doneWithAddedNull
		
		clr	al
		stosb
haveAscii:
		cmp	ah, '\n'
		je	finish

		tst	ah
		jnz	keepGoing
finish:
		clr	dx
		mov	al, ah
		stosb
		jmp	doneWithAddedNull
keepGoing:
	; ah is the extra byte, save it
		mov	cl, ah
	; this is a state where we have read one byte too many
		pushdw	myfile
	; get the next two bytes
		call	FGETC
		mov	ch, ah
		mov	ah, al
		mov	al, cl
		call	GetSJisChar
		jnc	gotSecondAscii
	; in this case, we got a two byte character, and we still have
	; an extra byte out, so move the extra byte into ah and we are
	; back in the gotAscii state
		
		mov	bx, codePage
		clr	dx
		xchg	al, ah
		call	LocalDosToGeosChar
		stosw
		mov	ah, ch
		jmp	haveAscii
gotSecondAscii:
	;		mov	dx, 2
		stosb
	;		tst	al
	;	jz	doneWithStore
	;	cmp	al, '\n'
	;	jz	doneWithAddedNull
		
		clr	al
		stosb
		mov	al, ah
		mov	ah, ch	; restore extra character
		jmp	readTwoBytes
doneWithAddedNull:
		clr	ax
		stosw
doneWithStore:
		clr	al
		stosb
done:
	; now we need to fseek back the number of extra characters we
	; read
		tst	dx
		jz	reallyDone
		pushdw	myfile
		call	FEOF
		tst	ax
		jnz	reallyDone
		
		pushdw	myfile
		clr	ax
		negdw	axdx
		pushdw	axdx
		mov	ax, FILE_POS_RELATIVE
		push	ax
		call	FSEEK
reallyDone:
		.leave
		ret
BascoLocalDosToGeos	endp
endif
		
public fgets_dbcs
endif

BCHACK ends

