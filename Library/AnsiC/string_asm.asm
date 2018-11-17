COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	AnsiC
FILE:		string_asm.asm

AUTHOR:		Andrew Wilson, Aug 23, 1991

ROUTINES:
	Name			Description
	----			-----------
	strlen			Get the length of the passed string
	strchr			Return ptr to first occurrence of char in
					passed string
	strrchr			Return ptr to last occurrence of char in
					passed string
	strpos			Return offset in TCHARS to first occurrence of char in
					passed string
	strrpos			Return offset in TCHARS to last occurrence of char in
					passed string
	strcpy			Copy second string onto first string
	strncpy			Copy up to N characters from second string onto
					first string 
					(output not necessarily null terminated)
	strcmp			Compare equality of strings
	strncmp			Compare equality of strings up to N chars
	strcat			Copy second string after first string
	strncat			Copy up to N bytes from second string onto
					first string
	strspn			Get # chars from start of first string that
					exist in second string
	strcspn			Get # chars from start of first string that
					do not exist in second string
	strpbrk			Return ptr (into first string) to the first
					char from second string that is found
					in first string
	strrpbrk		Return ptr (into first string) to the last
					char from second string that is found
					in first string
	strstr			Return ptr (into first string) to the first
					occurrence of the second string 
					(excluding its final null) in
					the first string


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/23/91		Initial version
	jenny	30/9/91		Added strstr
	schoon 	6/3/92		Updated to near ANSI C standards

DESCRIPTION:
	Assembly versions of ANSI C string routines.

	$Id: string_asm.asm,v 1.1 97/04/04 17:42:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include ansicGeode.def

STRINGCODE	segment	word	public	'CODE'
.model	medium, pascal
if	ERROR_CHECK
ECCheckBoundsESDI	proc	near
	segxchg	es, ds
	xchg	si, di
	call	ECCheckBounds
	xchg	si, di
	segxchg	es, ds
	ret
ECCheckBoundsESDI	endp
ECCheckBoundsESDIMinusOne	proc	near
	pushf	
	push	di
	dec	di
	call	ECCheckBoundsESDI
	pop	di
	popf
	ret
ECCheckBoundsESDIMinusOne	endp
ECCheckBoundsMinusOne		proc	near
	pushf
	push	si
	dec	si
	call	ECCheckBounds
	pop	si
	popf
	ret
ECCheckBoundsMinusOne		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strlen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strlen


C DECLARATION	word strlen(TCHAR far *str);
		(For XIP system, *str can be pointing to the XIP movable
			code resource.)

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global  STRLEN:far
STRLEN  proc    far     strPtr:fptr
				uses	es, di
	.enter
	les	di, strPtr
EC <	call	ECCheckBoundsESDI					>
	mov	cx, -1
SBCS <	clr	al >
DBCS <	clr	ax >
SBCS <	repne	scasb >
DBCS <  repne	scasw >
	not	cx
	dec	cx			;Nuke count of null terminator
	xchg	ax, cx
	.leave
	ret
STRLEN  endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strchr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strchr

C DECLARATION	TCHAR far * strchr(TCHAR *str1, word c);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strchr:far
strchr	proc	far	str1:fptr, theC:word
				uses	es, di
	.enter
	les	di, str1
EC <	call	ECCheckBoundsESDI					>
	mov	cx, -1
SBCS <	clr	al >
DBCS <	clr	ax >
SBCS <	repne	scasb >
DBCS <  repne	scasw >
	not	cx			;CX <- # chars including null
	mov	di, str1.offset
	mov	ax, theC
SBCS <	repne	scasb	>		;Look for the character
DBCS <	repne	scasw	>
	jne	notFound		;If not found, branch
	dec	di
DBCS <	dec	di >
	mov	dx, es			;DX:AX <- ptr to char found
	xchg	ax, di
exit:
	.leave
	ret
notFound:
	clr	dx			;If char not found, return NULL
	clr	ax			
	jmp	exit
strchr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strrchr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strrchr

C DECLARATION	TCHAR far * strrchr(TCHAR *str1, word c);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strrchr:far
strrchr	proc	far	str1:fptr, theC:word
				uses	es, di
	.enter
	les	di, str1
	mov	cx, -1
SBCS <	clr	al >
DBCS <	clr	ax >
SBCS <	repne	scasb >
DBCS <	repne	scasw >
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx			;CX <- # chars including null
	dec	di			;DI <- ptr to null char
DBCS <	dec	di >
	mov	ax, theC
	std
SBCS <	repne	scasb >			;Look for the character
DBCS <	repne	scasw >
	cld
	jne	notFound		;If not found, branch
	inc	di
DBCS <	inc	di >
	mov	dx, es			;DX:AX <- ptr to char found
	xchg	ax, di
exit:
	.leave
	ret
notFound:
	clr	dx			;If char not found, return NULL
	clr	ax			
	jmp	exit
strrchr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strpos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strpos

C DECLARATION	word strpos(TCHAR *str1, word c);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strpos:far
strpos	proc	far	str1:fptr, theC:word
				uses	es, di
	.enter
	les	di, str1
	mov	cx, -1
SBCS <	clr	al >
DBCS <	clr	ax >
SBCS <	repne	scasb >
DBCS <	repne	scasw >
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx			;CX <- # chars including null
	mov	di, str1.offset
	mov	ax, theC
SBCS <	repne	scasb	>		;Look for the character
DBCS <	repne	scasw	>
	mov	ax, -1
	jne	exit			;If not found, branch
	dec	di
DBCS <  dec	di >
	sub	di, str1.offset
	xchg	ax, di			;AX <- offset to char in string
DBCS <	shr	ax >
exit:
	.leave
	ret
strpos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strrpos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strrpos

C DECLARATION	word strrpos(TCHAR *str1, word c);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strrpos:far
strrpos	proc	far	str1:fptr, theC:word
				uses	es, di
	.enter
	les	di, str1
	mov	cx, -1
	clr	ax
SBCS <	repne	scasb >
DBCS <	repne	scasw >
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx			;CX <- # chars including null
	dec	di			;DI <- ptr to null char
DBCS <	dec	di >
	mov	ax, theC
	std
SBCS <	repne	scasb	>		;Look for the character
DBCS <	repne	scasw	>
	cld
	mov	ax, -1
	jne	exit			;If not found, branch
	inc	di
DBCS <	inc	di >
	sub	di, str1.offset
	xchg	ax, di			;AX <- offset to char in string
DBCS <	shr	ax >
exit:
	.leave
	ret
strrpos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcpy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strcpy

C DECLARATION	TCHAR far  * strcpy(TCHAR far *dest, TCHAR far *source);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strcpy:far
strcpy	proc	far	destPtr:fptr, sourcePtr:fptr
				uses	ds, es, di, si
	.enter
	les	di, sourcePtr	;ES:DI <- ptr to src string
	mov	ds, sourcePtr.segment
	mov	si, di		;DS:SI <- ptr to src string

	mov	cx, -1
	clr	ax
SBCS <	repne	scasb >
DBCS <	repne	scasw >
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx		;CX <- # chars (+ null) in src string

	les	di, destPtr	;ES:DI <- ptr to dest for string
	mov	dx, es		;DX:AX <- ptr to dest for string
	mov	ax, di

SBCS <	shr	cx, 1 >
SBCS <	jnc	10$ >
SBCS <	movsb >
SBCS < 10$: >
	rep	movsw
EC <	call	ECCheckBoundsESDIMinusOne				>
	.leave
	ret
strcpy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strncpy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strncpy

C DECLARATION	TCHAR far  * strcpy(TCHAR far *dest, TCHAR far *source, word len);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strncpy:far
strncpy	proc	far	destPtr:fptr, sourcePtr:fptr, len:word
				uses	ds, es, di, si
	.enter

	lds	si, sourcePtr	;DS:SI <- ptr to src string
	les	di, destPtr	;ES:DI <- ptr to dest string
	mov	cx, len
	jcxz	exit
5$:
SBCS <	lodsb >
DBCS <	lodsw >
SBCS <	tst	al >
DBCS <	tst	ax >
	jz	10$
SBCS <	stosb >
DBCS <	stosw >
	loop	5$
exit:
	.leave
	ret
10$:
SBCS <	rep	stosb	>	;Null pad the dest string
DBCS <	rep	stosw 	>
EC <	call	ECCheckBoundsMinusOne					>
EC <	call	ECCheckBoundsESDIMinusOne				>
	jmp	exit
strncpy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcmp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strcmp

C DECLARATION	word strcmp(word far *str1, word far *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strcmp:far
strcmp	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str1		;ES:DI <- ptr to str1
	lds	si, str2		;DS:SI <- ptr to str 2
	mov	cx, -1
	clr	ax			;
SBCS <	repne	scasb	>		;
DBCS <	repne	scasw >
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx			;CX <- # chars in str 1 (w/null)

	mov	di, str1.offset		;ES:DI <- ptr to str1
SBCS <	repe	cmpsb >
DBCS <	repe	cmpsw >
EC <	call	ECCheckBoundsMinusOne					>
	jz	exit			;If match, exit (with ax=0)
SBCS <	mov	al, es:[di][-1] >	;Else, return difference of chars>
DBCS <	mov	ax, es:[di][-2] >
SBCS <	sub	al, ds:[si][-1] >	;
DBCS <	sub	ax, ds:[si][-2] >
SBCS <	cbw	>			;
exit:
	.leave
	ret
strcmp	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strncmp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strncmp

C DECLARATION	word strncmp(word far *str1, word far *str2, word len);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strncmp:far
strncmp	proc	far	str1:fptr, str2:fptr, len:word
				uses	ds, es, di, si
	.enter
	clr	ax			;
	mov	cx, len			;
	jcxz	exit			;If string is empty, return that they
					; are equal.
	les	di, str1		;ES:DI <- ptr to str1
SBCS <	repne	scasb	>		;Get length of string
DBCS <	repne	scasw	>
EC <	call	ECCheckBoundsESDIMinusOne				>
	neg	cx
	add	cx, len			;CX <- min (len, strlen(str1)+1);
	lds	si, str2		;DS:SI <- ptr to str 2	
	mov	di, str1.offset		;ES:DI <- ptr to str1
SBCS <	repe	cmpsb >
DBCS <	repe	cmpsw >
EC <	call	ECCheckBoundsMinusOne					>
SBCS <	mov	al, es:[di][-1]	>	;Return difference of chars
DBCS <  mov	ax, es:[di][-2] >
SBCS <	sub	al, ds:[si][-1]	>	;
DBCS <	sub	ax, ds:[si][-2] >
SBCS <	cbw	>			;
exit:
	.leave
	ret
strncmp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strcat

C DECLARATION	VOID * strcat(TCHAR far *str1, TCHAR far *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strcat:far
strcat	proc	far	str1:fptr, str2:fptr
				uses	es, ds, di, si
	.enter
	les	di, str2		;
	lds	si, str2		;

;	GET LENGTH OF SECOND STRING

	clr	ax
	mov	cx, -1
SBCS <	repne	scasb >
DBCS <	repne	scasw >
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx			;CX <- # chars in second string + null

;	SCAN TO END OF FIRST (DEST) STRING

	mov	dx, cx			;DX <- size of second string
	les	di, str1		;ES:DI <- ptr to str1
	mov	cx, -1			;
SBCS <	repne	scasb	>		;ES:DI <- ptr past null
DBCS <	repne	scasw >
	dec	di			;ES:DI <- ptr to null byte of string
DBCS <	dec	di >
EC <	call	ECCheckBoundsESDI					>
	mov	cx, dx			;CX <- size of second string

;	COPY SECOND STRING ONTO END OF FIRST STRING

SBCS <	shr	cx, 1 >
SBCS <	jnc	10$ >
SBCS <	movsb >
SBCS <10$: >
	rep	movsw
EC <	call	ECCheckBoundsESDIMinusOne				>
EC <	call	ECCheckBoundsMinusOne				>
	mov	dx, es
	mov	ax, str1.offset
	.leave
	ret
strcat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strncat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strncat

C DECLARATION	VOID * strncat(TCHAR far *str1, TCHAR far *str2, word len);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		Name is in caps so routine can be published now that it's
		fixed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strncat_old:far
;
; Exported as a place holder for the old, buggy strncat.
;
strncat_old	proc	far
	REAL_FALL_THRU	STRNCAT
endp

global	STRNCAT:far
STRNCAT	proc	far	str1:fptr, str2:fptr, len:word
				uses	es, ds, di, si
	.enter
	les	di, str1		;ES:DI <- ptr to str1
	mov	cx, -1
SBCS <	clr	al >
DBCS <	clr	ax >
SBCS <	repne	scasb >
DBCS <	repne 	scasw >
	dec	di			;ES:DI <- ptr to null-terminator for
DBCS <	dec	di >
					; str1
	mov	cx, len			;
	jcxz	exit			;If string is empty, just exit
	lds	si, str2
loopTop:
SBCS <	lodsb >
DBCS <	lodsw >
SBCS <	tst	al >
DBCS <	tst 	ax >
	jz	10$
SBCS <	stosb	 >
DBCS <	stosw >
	loop	loopTop
SBCS <	clr	al>
DBCS <	clr	ax >
10$:
EC <	call	ECCheckBoundsMinusOne					>
EC <	call	ECCheckBoundsESDI					>
SBCS <	stosb >
DBCS <	stosw >
exit:
	mov	dx, es
	mov	ax, str1.offset
	.leave
	ret
STRNCAT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcspn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strcspn

C DECLARATION	word strcspn(TCHAR *str1, TCHAR *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strcspn:far
strcspn	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str2	;ES:DI <- ptr to str2	
	lds	si, str1	;DS:SI <- ptr to str1
	mov	cx, -1		;CX <- # chars in str2 not counting null
SBCS <	clr	al >
DBCS <	clr	ax >
SBCS <	repne	scasb >
DBCS <	repne	scasw >
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx
	dec	cx
	mov	bx, cx
	mov	dx,-1
loopTop:
	inc	dx		;DX <- # chars at start of str1 that aren't in
				; str2
SBCS <	lodsb	>		;AL <- next char in str1
DBCS <	lodsw 	>
SBCS <	tst	al >
DBCS <	tst	ax >
	jz	exit
	mov	cx, bx		;CX <- # chars in string
	mov	di, str2.offset	;ES:DI <- ptr to str2
	jcxz	loopTop
SBCS <	repne	scasb >
DBCS <	repne	scasw >
	jnz	loopTop		;If char not found, branch


exit:
EC <	call	ECCheckBoundsMinusOne					>
	xchg	ax, dx		;AX <- # chars at start of str1 that do not lie
				; in str2
	.leave
	ret
strcspn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strspn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strspn

C DECLARATION	word strspn(TCHAR *str1, TCHAR *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strspn:far
strspn	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str2	;ES:DI <- ptr to str2	
	lds	si, str1	;DS:SI <- ptr to str1
	mov	cx, -1		;CX <- # chars in str2 not counting null
	clr	ax
SBCS <	repne	scasb >
DBCS <	repne	scasw >
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx
	dec	cx
	jcxz	exit		;Exit if str2 is null

	mov	bx, cx		;BX <- strlen(str2)
	mov	dx, -1
loopTop:
	inc	dx		;DX <- # chars at start of str1 that are in
				; str2
SBCS <	lodsb	>		;AL <- next char in str1
DBCS <	lodsw >
SBCS <	tst	al >		;Exit if at end of str1
DBCS <	tst	ax >
	jz	99$		;
	mov	cx, bx		;CX <- # chars in string
	mov	di, str2.offset	;ES:DI <- ptr to str2
SBCS <	repne	scasb	>	;
DBCS <	repne	scasw	>
	jz	loopTop		;If char found, branch

99$:
EC <	call	ECCheckBoundsMinusOne				>
	xchg	ax, dx		;AX <- # chars at start of str1 that lie
				; in str2
exit:
	.leave
	ret
strspn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strpbrk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strpbrk

C DECLARATION	TCHAR *strpbrk(TCHAR *str1, TCHAR *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strpbrk:far
strpbrk	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str2	;ES:DI <- ptr to str2	
	lds	si, str1	;DS:SI <- ptr to str1
	mov	cx, -1		;CX <- # chars in str2 not counting null
	clr	ax
SBCS <	repne	scasb >
DBCS <	repne	scasw >
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx
	dec	cx
	jcxz	notFound	;Exit if str2 is null

	mov	bx, cx		;BX <- strlen(str2)
loopTop:
SBCS <	lodsb	>		;AL <- next char in str1
DBCS <	lodsw >
SBCS <	tst	al	>	;Exit if at end of str1
DBCS <	tst	ax >
	jz	checkNotFound		;
	mov	cx, bx		;CX <- # chars in str2
	mov	di, str2.offset	;ES:DI <- ptr to str2
SBCS <	repne	scasb	>	;
DBCS <	repne	scasw >
	jnz	loopTop		;If char not found, branch
	dec	si
DBCS <	dec	si >
EC <	call	ECCheckBounds						>
	movdw	dxax, dssi	;DX:AX <- ptr to char in string1 
exit:
	.leave
	ret
checkNotFound:
EC <	call	ECCheckBoundsMinusOne					>
notFound:
	clrdw	dxax
	jmp	exit
strpbrk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strrpbrk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strrpbrk

C DECLARATION	TCHAR *strrpbrk(TCHAR *str1, TCHAR *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strrpbrk:far
strrpbrk	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str1
	mov	cx, -1
	clr	ax
SBCS <	repne	scasb >
DBCS <	repne	scasw >
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx
	dec	cx
	jcxz	notFound	;if str1 is null, exit
	mov	dx, cx		;DX <- strlen(str1)

	mov	ds, str1.segment
	mov	si, di
SBCS <	sub	si, 2	>	;DS:SI <- ptr to last char in str1
DBCS <	sub	si, 4 >

	les	di, str2	;ES:DI <- ptr to str2
	mov	cx, -1		;CX <- strlen(str2)
	clr	ax		;
SBCS <	repne	scasb	>	;
DBCS <	repne	scasw >
	not	cx		;
EC <	call	ECCheckBoundsESDIMinusOne				>
	dec	cx		;

	jcxz	notFound	;Exit if str2 is null

	mov	bx, cx		;BX <- strlen(str2)
loopTop:
;
;	DS:SI <- ptr to next char in str1
;	BX <- # chars in str2
;	DX <- # chars left to check in str1
;
	std
SBCS <	lodsb	>		;AL <- next char in str1
DBCS <	lodsw >
	cld
	mov	cx, bx		;CX <- # chars in str2
	mov	di, str2.offset	;ES:DI <- ptr to str2
SBCS <	repne	scasb	>	; 
DBCS <	repne	scasw >
	jz	found		;If char found, branch

	dec	dx		;Dec # chars to check in str1
	jnz	loopTop

notFound:
	clr	dx		;Return NULL
	mov	ax, dx
	jmp	exit
found:
	inc	si
DBCS <	inc	si >
	movdw	dxax, dssi		;DX:AX <- ptr to char in string1 
exit:
	.leave
	ret
strrpbrk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strstr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strstr

C DECLARATION	TCHAR far * strstr(TCHAR *str1, TCHAR *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	30/9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strstr:far
strstr	proc	far	str1:fptr, str2:fptr 
	uses	ds, es, di, si

	.enter
	les	di, str1		;ES:DI <- ptr to str1
	mov	cx, -1
SBCS <	clr	al>
DBCS <	clr	ax >
SBCS <	repne	scasb >
DBCS <	repne	scasw >
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx
	mov	bx, cx			;BX <- # chars in str1 (w/ null)

	les	di, str2		;ES:DI <- ptr to str2
	mov	cx, -1
SBCS <	clr	al >
DBCS <	clr	ax >
SBCS <	repne	scasb >
DBCS <	repne	scasw >
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx			;CX <- # chars in str2 (w/ null)
	sub	bx, cx			;BX <- length diff. betw. str1 & str2
	jl	notFound		;If str1 is shorter than str2, branch
	dec	cx
	mov	ax, cx			;AX <- # chars in str2 (without null)

	mov	dx, str2.offset		;DX <- str2.offset
	mov	di, dx			;ES:DI <- ptr to str2
	lds	si, str1		;DS:SI <- ptr to str1
	mov	bp, si			;BP <- str1.offset
cmpStrings:
SBCS <	repe	cmpsb >
DBCS <	repe	cmpsw >
	jne	notSameChar		;If not same char, branch
	mov	dx, ds			;DX:AX <- ptr to string found
	mov	ax, bp			;
	jmp	exit
notSameChar:
	inc	bp			;Increment offset into str1
DBCS <	inc	bp >
	mov	si, bp			;DS:SI <- next str1 char to start with
	mov	di, dx			;ES:DI <- ptr to str2
	mov	cx, ax			;CX <- # of chars in str2
	dec	bx			;Decrement length diff. betw. str2
					;	and what remains of str1
	jge	cmpStrings		;If str2 is not longer, branch
notFound:
	clrdw	dxax			;If string not found, return NULL
exit:
	.leave
	ret
strstr	endp

STRINGCODE	ends


;
; For DBCS, SBCS versions
;
ifdef DO_DBCS

STRINGCODESBCS	segment	byte	public	'CODE'
.model	medium, pascal

if	ERROR_CHECK
ECCheckBoundsESDISBCS	proc	near
	segxchg	es, ds
	xchg	si, di
	call	ECCheckBounds
	xchg	si, di
	segxchg	es, ds
	ret
ECCheckBoundsESDISBCS	endp
ECCheckBoundsESDIMinusOneSBCS	proc	near
	pushf	
	push	di
	dec	di
	call	ECCheckBoundsESDISBCS
	pop	di
	popf
	ret
ECCheckBoundsESDIMinusOneSBCS	endp
ECCheckBoundsMinusOneSBCS		proc	near
	pushf
	push	si
	dec	si
	call	ECCheckBounds
	pop	si
	popf
	ret
ECCheckBoundsMinusOneSBCS		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strlensbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strlensbcs


C DECLARATION	word strlensbcs(char far *str);
		(For XIP system, *str can be pointing to the XIP movable
			code resource.)

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global  STRLENSBCS:far
STRLENSBCS  proc    far     strPtr:fptr
				uses	es, di
	.enter
	les	di, strPtr
EC <	call	ECCheckBoundsESDISBCS					>
	mov	cx, -1
	clr	al
	repne	scasb
	not	cx
	dec	cx			;Nuke count of null terminator
	xchg	ax, cx
	.leave
	ret
STRLENSBCS  endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strchrsbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strchrsbcs

C DECLARATION	char far * strchrsbcs(char *str1, word c);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strchrsbcs:far
strchrsbcs	proc	far	str1:fptr, theC:word
				uses	es, di
	.enter
	les	di, str1
EC <	call	ECCheckBoundsESDISBCS					>
	mov	cx, -1
	clr	al
	repne	scasb
	not	cx			;CX <- # chars including null
	mov	di, str1.offset
	mov	ax, theC
	repne	scasb			;Look for the character
	jne	notFound		;If not found, branch
	dec	di
	mov	dx, es			;DX:AX <- ptr to char found
	xchg	ax, di
exit:
	.leave
	ret
notFound:
	clr	dx			;If char not found, return NULL
	clr	ax			
	jmp	exit
strchrsbcs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strrchrsbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strrchrsbcs

C DECLARATION	char far * strrchrsbcs(char *str1, word c);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strrchrsbcs:far
strrchrsbcs	proc	far	str1:fptr, theC:word
				uses	es, di
	.enter
	les	di, str1
	mov	cx, -1
	clr	al 
	repne	scasb 
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	not	cx			;CX <- # chars including null
	dec	di			;DI <- ptr to null char
	mov	ax, theC
	std
	repne	scasb 			;Look for the character
	cld
	jne	notFound		;If not found, branch
	inc	di
	mov	dx, es			;DX:AX <- ptr to char found
	xchg	ax, di
exit:
	.leave
	ret
notFound:
	clr	dx			;If char not found, return NULL
	clr	ax			
	jmp	exit
strrchrsbcs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strpos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strpos

C DECLARATION	word strpos(char *str1, word c);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strpossbcs:far
strpossbcs	proc	far	str1:fptr, theC:word
				uses	es, di
	.enter
	les	di, str1
	mov	cx, -1
	clr	al 
	repne	scasb 
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	not	cx			;CX <- # chars including null
	mov	di, str1.offset
	mov	ax, theC
	repne	scasb			;Look for the character
	mov	ax, -1
	jne	exit			;If not found, branch
	dec	di
	sub	di, str1.offset
	xchg	ax, di			;AX <- offset to char in string
exit:
	.leave
	ret
strpossbcs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strrpossbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strrpossbcs

C DECLARATION	word strrpossbcs(char *str1, word c);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strrpossbcs:far
strrpossbcs	proc	far	str1:fptr, theC:word
				uses	es, di
	.enter
	les	di, str1
	mov	cx, -1
	clr	ax
	repne	scasb 
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	not	cx			;CX <- # chars including null
	dec	di			;DI <- ptr to null char
	mov	ax, theC
	std
	repne	scasb			;Look for the character
	cld
	mov	ax, -1
	jne	exit			;If not found, branch
	inc	di
	sub	di, str1.offset
	xchg	ax, di			;AX <- offset to char in string
exit:
	.leave
	ret
strrpossbcs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcpysbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strcpysbcs

C DECLARATION	char far  * strcpysbcs(char far *dest, char far *source);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strcpysbcs:far
strcpysbcs	proc	far	destPtr:fptr, sourcePtr:fptr
				uses	ds, es, di, si
	.enter
	les	di, sourcePtr	;ES:DI <- ptr to src string
	mov	ds, sourcePtr.segment
	mov	si, di		;DS:SI <- ptr to src string

	mov	cx, -1
	clr	ax
	repne	scasb 
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	not	cx		;CX <- # chars (+ null) in src string

	les	di, destPtr	;ES:DI <- ptr to dest for string
	mov	dx, es		;DX:AX <- ptr to dest for string
	mov	ax, di

	shr	cx, 1 
	jnc	10$ 
	movsb 
10$: 
	rep	movsw
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	.leave
	ret
strcpysbcs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strncpysbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strncpysbcs

C DECLARATION	char far  * strcpysbcs(char far *dest, char far *source, word len);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strncpysbcs:far
strncpysbcs	proc	far	destPtr:fptr, sourcePtr:fptr, len:word
				uses	ds, es, di, si
	.enter

	lds	si, sourcePtr	;DS:SI <- ptr to src string
	les	di, destPtr	;ES:DI <- ptr to dest string
	mov	cx, len
	jcxz	exit
5$:
	lodsb 
	tst	al 
	jz	10$
	stosb 
	loop	5$
exit:
	.leave
	ret
10$:
	rep	stosb		;Null pad the dest string
EC <	call	ECCheckBoundsMinusOneSBCS					>
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	jmp	exit
strncpysbcs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcmpsbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strcmpsbcs

C DECLARATION	word strcmpsbcs(word far *str1, word far *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strcmpsbcs:far
strcmpsbcs	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str1		;ES:DI <- ptr to str1
	lds	si, str2		;DS:SI <- ptr to str 2
	mov	cx, -1
	clr	ax			;
	repne	scasb			;
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	not	cx			;CX <- # chars in str 1 (w/null)

	mov	di, str1.offset		;ES:DI <- ptr to str1
	repe	cmpsb 
EC <	call	ECCheckBoundsMinusOneSBCS					>
	jz	exit			;If match, exit (with ax=0)
	mov	al, es:[di][-1] 	;Else, return difference of chars>
	sub	al, ds:[si][-1] 	;
	cbw				;
exit:
	.leave
	ret
strcmpsbcs	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strncmpsbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strncmpsbcs

C DECLARATION	word strncmpsbcs(word far *str1, word far *str2, word len);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strncmpsbcs:far
strncmpsbcs	proc	far	str1:fptr, str2:fptr, len:word
				uses	ds, es, di, si
	.enter
	clr	ax			;
	mov	cx, len			;
	jcxz	exit			;If string is empty, return that they
					; are equal.
	les	di, str1		;ES:DI <- ptr to str1
	repne	scasb			;Get length of string
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	neg	cx
	add	cx, len			;CX <- min (len, strlen(str1)+1);
	lds	si, str2		;DS:SI <- ptr to str 2	
	mov	di, str1.offset		;ES:DI <- ptr to str1
	repe	cmpsb 
EC <	call	ECCheckBoundsMinusOneSBCS					>
	mov	al, es:[di][-1]		;Return difference of chars
	sub	al, ds:[si][-1]		;
	cbw				;
exit:
	.leave
	ret
strncmpsbcs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcatsbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strcatsbcs

C DECLARATION	VOID * strcatsbcs(char far *str1, char far *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strcatsbcs:far
strcatsbcs	proc	far	str1:fptr, str2:fptr
				uses	es, ds, di, si
	.enter
	les	di, str2		;
	lds	si, str2		;

;	GET LENGTH OF SECOND STRING

	clr	ax
	mov	cx, -1
	repne	scasb 
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	not	cx			;CX <- # chars in second string + null

;	SCAN TO END OF FIRST (DEST) STRING

	mov	dx, cx			;DX <- size of second string
	les	di, str1		;ES:DI <- ptr to str1
	mov	cx, -1			;
	repne	scasb			;ES:DI <- ptr past null
	dec	di			;ES:DI <- ptr to null byte of string
EC <	call	ECCheckBoundsESDISBCS					>
	mov	cx, dx			;CX <- size of second string

;	COPY SECOND STRING ONTO END OF FIRST STRING

	shr	cx, 1 
	jnc	10$ 
	movsb 
10$: 
	rep	movsw
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
EC <	call	ECCheckBoundsMinusOneSBCS				>
	mov	dx, es
	mov	ax, str1.offset
	.leave
	ret
strcatsbcs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strncatsbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strncatsbcs

C DECLARATION	VOID * strncatsbcs(char far *str1, char far *str2, word len);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		Name is in caps so routine can be published now that it's
		fixed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	STRNCATSBCS:far
STRNCATSBCS	proc	far	str1:fptr, str2:fptr, len:word
				uses	es, ds, di, si
	.enter
	les	di, str1		;ES:DI <- ptr to str1
	mov	cx, -1
	clr	al 
	repne	scasb 
	dec	di			;ES:DI <- ptr to null-terminator for
					; str1
	mov	cx, len			;
	jcxz	exit			;If string is empty, just exit
	lds	si, str2
loopTop:
	lodsb 
	tst	al 
	jz	10$
	stosb	 
	loop	loopTop
	clr	al
10$:
EC <	call	ECCheckBoundsMinusOneSBCS					>
EC <	call	ECCheckBoundsESDISBCS					>
	stosb 
exit:
	mov	dx, es
	mov	ax, str1.offset
	.leave
	ret
STRNCATSBCS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcspnsbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strcspnsbcs

C DECLARATION	word strcspnsbcs(char *str1, char *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strcspnsbcs:far
strcspnsbcs	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str2	;ES:DI <- ptr to str2	
	lds	si, str1	;DS:SI <- ptr to str1
	mov	cx, -1		;CX <- # chars in str2 not counting null
	clr	al 
	repne	scasb 
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	not	cx
	dec	cx
	mov	bx, cx
	mov	dx,-1
loopTop:
	inc	dx		;DX <- # chars at start of str1 that aren't in
				; str2
	lodsb			;AL <- next char in str1
	tst	al 
	jz	exit
	mov	cx, bx		;CX <- # chars in string
	mov	di, str2.offset	;ES:DI <- ptr to str2
	jcxz	loopTop
	repne	scasb 
	jnz	loopTop		;If char not found, branch


exit:
EC <	call	ECCheckBoundsMinusOneSBCS					>
	xchg	ax, dx		;AX <- # chars at start of str1 that do not lie
				; in str2
	.leave
	ret
strcspnsbcs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strspnsbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strspnsbcs

C DECLARATION	word strspn(char *str1, char *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strspnsbcs:far
strspnsbcs	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str2	;ES:DI <- ptr to str2	
	lds	si, str1	;DS:SI <- ptr to str1
	mov	cx, -1		;CX <- # chars in str2 not counting null
	clr	ax
	repne	scasb 
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	not	cx
	dec	cx
	jcxz	exit		;Exit if str2 is null

	mov	bx, cx		;BX <- strlen(str2)
	mov	dx, -1
loopTop:
	inc	dx		;DX <- # chars at start of str1 that are in
				; str2
	lodsb			;AL <- next char in str1
	tst	al 		;Exit if at end of str1
	jz	99$		;
	mov	cx, bx		;CX <- # chars in string
	mov	di, str2.offset	;ES:DI <- ptr to str2
	repne	scasb		;
	jz	loopTop		;If char found, branch

99$:
EC <	call	ECCheckBoundsMinusOneSBCS				>
	xchg	ax, dx		;AX <- # chars at start of str1 that lie
				; in str2
exit:
	.leave
	ret
strspnsbcs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strpbrksbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strpbrk

C DECLARATION	char *strpbrksbcs(char *str1, char *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strpbrksbcs:far
strpbrksbcs	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str2	;ES:DI <- ptr to str2	
	lds	si, str1	;DS:SI <- ptr to str1
	mov	cx, -1		;CX <- # chars in str2 not counting null
	clr	ax
	repne	scasb 
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	not	cx
	dec	cx
	jcxz	notFound	;Exit if str2 is null

	mov	bx, cx		;BX <- strlen(str2)
loopTop:
	lodsb			;AL <- next char in str1
	tst	al		;Exit if at end of str1
	jz	checkNotFound		;
	mov	cx, bx		;CX <- # chars in str2
	mov	di, str2.offset	;ES:DI <- ptr to str2
	repne	scasb		;
	jnz	loopTop		;If char not found, branch
	dec	si
EC <	call	ECCheckBounds						>
	movdw	dxax, dssi	;DX:AX <- ptr to char in string1 
exit:
	.leave
	ret
checkNotFound:
EC <	call	ECCheckBoundsMinusOneSBCS					>
notFound:
	clrdw	dxax
	jmp	exit
strpbrksbcs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strrpbrksbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strrpbrksbcs

C DECLARATION	char *strrpbrksbcs(char *str1, char *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strrpbrksbcs:far
strrpbrksbcs	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str1
	mov	cx, -1
	clr	ax
	repne	scasb 
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	not	cx
	dec	cx
	jcxz	notFound	;if str1 is null, exit
	mov	dx, cx		;DX <- strlen(str1)

	mov	ds, str1.segment
	mov	si, di
	sub	si, 2		;DS:SI <- ptr to last char in str1

	les	di, str2	;ES:DI <- ptr to str2
	mov	cx, -1		;CX <- strlen(str2)
	clr	ax		;
	repne	scasb		;
	not	cx		;
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	dec	cx		;

	jcxz	notFound	;Exit if str2 is null

	mov	bx, cx		;BX <- strlen(str2)
loopTop:
;
;	DS:SI <- ptr to next char in str1
;	BX <- # chars in str2
;	DX <- # chars left to check in str1
;
	std
	lodsb			;AL <- next char in str1
	cld
	mov	cx, bx		;CX <- # chars in str2
	mov	di, str2.offset	;ES:DI <- ptr to str2
	repne	scasb		; 
	jz	found		;If char found, branch

	dec	dx		;Dec # chars to check in str1
	jnz	loopTop

notFound:
	clr	dx		;Return NULL
	mov	ax, dx
	jmp	exit
found:
	inc	si
	inc	si 
	movdw	dxax, dssi		;DX:AX <- ptr to char in string1 
exit:
	.leave
	ret
strrpbrksbcs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strstrsbcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strstrsbcs

C DECLARATION	char far * strstrsbcs(char *str1, char *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	30/9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strstrsbcs:far
strstrsbcs	proc	far	str1:fptr, str2:fptr 
	uses	ds, es, di, si

	.enter
	les	di, str1		;ES:DI <- ptr to str1
	mov	cx, -1
	clr	al
	repne	scasb 
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	not	cx
	mov	bx, cx			;BX <- # chars in str1 (w/ null)

	les	di, str2		;ES:DI <- ptr to str2
	mov	cx, -1
	clr	al 
	repne	scasb 
EC <	call	ECCheckBoundsESDIMinusOneSBCS				>
	not	cx			;CX <- # chars in str2 (w/ null)
	sub	bx, cx			;BX <- length diff. betw. str1 & str2
	jl	notFound		;If str1 is shorter than str2, branch
	dec	cx
	mov	ax, cx			;AX <- # chars in str2 (without null)

	mov	dx, str2.offset		;DX <- str2.offset
	mov	di, dx			;ES:DI <- ptr to str2
	lds	si, str1		;DS:SI <- ptr to str1
	mov	bp, si			;BP <- str1.offset
cmpStrings:
	repe	cmpsb 
	jne	notSameChar		;If not same char, branch
	mov	dx, ds			;DX:AX <- ptr to string found
	mov	ax, bp			;
	jmp	exit
notSameChar:
	inc	bp			;Increment offset into str1
	mov	si, bp			;DS:SI <- next str1 char to start with
	mov	di, dx			;ES:DI <- ptr to str2
	mov	cx, ax			;CX <- # of chars in str2
	dec	bx			;Decrement length diff. betw. str2
					;	and what remains of str1
	jge	cmpStrings		;If str2 is not longer, branch
notFound:
	clrdw	dxax			;If string not found, return NULL
exit:
	.leave
	ret
strstrsbcs	endp

STRINGCODESBCS	ends

endif







