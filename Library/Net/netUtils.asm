COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		netUtils.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
*	NetCallDriver		Calls appropriate network driver
*	GetDomainFromDomainString  	get domain name
	FindDomain		
	MatchDomain
*	strlen			
*	strcpy
*	strcmp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

DESCRIPTION:
	

	$Id: netUtils.asm,v 1.1 97/04/05 01:25:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetCommonCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetCallDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a call to the specific network driver.  This
		routine MUST handle the case of a driver not being
		found gracefully.

CALLED BY:	INTERNAL

PASS:		ds:si - Netware domain name (*HACK* not needed YET)
		di - NetDriverFunction

RETURN:		values returned by net driver

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetCallDriver	proc far
	uses	es
	.enter

	;
	; Lock the block containing the domain names
	;

	
	push	ax, bx, cx, dx, si, di, ds, bp

	segmov	es, <segment dgroup>, ax
	mov	bx, es:[lmemBlockHandle]
	call	MemLockShared
	mov	ds, ax

	;
	; Look for the passed name
	;

	mov	si, es:[domainArray]		; *ds:si - chunkarray
	mov	cx, es
	mov	dx, offset defaultDomainName
	mov	bx, cs
	mov	di, offset cs:MatchDomain
	clr	bp
	push	es
	call	ChunkArrayEnum
	pop	es
EC <	WARNING_NC	WARNING_INVALID_DOMAIN	>

	jnc	afterCopy
	mov	ax, bp
	call	ChunkArrayElementToPtr
EC <	call	ECCheckESDGroup	>
	PSem	es, driverSem
	movdw	es:[driver], ds:[di].DS_strategy, bx
	stc

afterCopy:
	mov	bx, es:[lmemBlockHandle]
	call	MemUnlockShared
	pop	ax,bx,cx,dx,si,di,ds,bp
	jnc	noDriver		; no driver was found, so bail

EC <	call	ECCheckESDGroup	>
	call	es:[driver]
	segmov	es, dgroup, di

   	pushf
	VSem	es, driverSem
	popf	
done:
	.leave
	ret
noDriver:
	stc
	mov	ax, NET_ERROR_DRIVER_NOT_FOUND
	jmp	done
NetCallDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find Domain name in chunkarray

CALLED BY:	NetUnregisterDomain
PASS:		ds:si - domain name
RETURN:		ax - -1 if not found, otherwise index #
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindDomain	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	mov	cx, ds
	mov	dx, si				; cx:dx - domain name
	segmov	es, dgroup, ax
	mov	bx, es:[lmemBlockHandle]
	mov	si, es:[domainArray]
	call	MemLockShared
	push	bx
	mov	ds, ax				; *ds:si - chunkarray
	mov	bx, cs
	mov	di, offset cs:MatchDomain
	clr	bp
	call	ChunkArrayEnum
	jc 	found
; not found.
	mov	ax, -1
	stc
	jmp	exit
found:
	mov	ax, bp
	clc	
exit:
	pop	bx
	call	MemUnlockShared			;preserves flags
	.leave
	ret
FindDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MatchDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	match domain name with chunkarray element domain name
		(domain string eg: "/NETWARE:/DRIVEC")
		domain name is then "NETWARE"
CALLED BY:	ChunkArrayEnum
PASS:		cx:dx - name1
		ds:[di].domainName - name2 (chunkarray element)
		bp - index #
RETURN:		carry set if names match
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MatchDomain	proc	far
	uses    es,di
	.enter
	mov	si,di
	add 	si,offset DS_domainName		; ds:si - chunkarray name
	segmov	es,ss,di
	sub	sp, NL_MAX_DOMAIN_NAME_LENGTH+2	; use stack for buffer
	mov	di,sp				; es:di - buffer for string
	call	GetDomainFromDomainString	; es:di - filled
	call	strcmp
	add	sp, NL_MAX_DOMAIN_NAME_LENGTH+2	; restore stack
	clc
	tst	ax
	jz	match
	inc	bp
	jmp	exit	
match:	stc
exit:	.leave
	ret
MatchDomain	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDomainFromDomainString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	parse domain string to retrieve domain name
		("/BERKELEY:/GO_BEARS/INSIK" returns
		 "BERKELEY")

CALLED BY:	INTERNAL
PASS:		cx:dx - domain string
		es:di - dest buffer 
RETURN:		dest buffer filled with domain string, null added
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	11/ 6/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDomainFromDomainString	proc	far
	uses	ax,cx,dx,ds,si,di
	.enter
	segxchg	es,cx
	xchg	di,dx
;Skip any slashes at the start of the domain name
	cmp	{byte} es:[di], '/'
	jnz	doCopy
	inc	di
doCopy:
	mov	al, ':'
	call	CopyUntilCharOrNull
	.leave
	ret
GetDomainFromDomainString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyUntilCharOrNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy string until character or null

CALLED BY:	
PASS:		al - char to seek
		es:di - src
		cx:dx - dest
		
RETURN:		es:di - dest
DESTROYED:	ax,cx,ds,si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	11/10/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyUntilCharOrNull	proc	near


	;
	; See how long the string is
	;

	push	cx, dx			; dest			
	mov	si, di
	mov	ah, al
	mov	cx, -1
	segmov	ds,es			; ds:si = es:di = src

startLoop:
	lodsb
	cmp	al, ah
	je	endOfString
	tst	al
	loopnz	startLoop

endOfString:
	not	cx			; string length
	dec	cx			; # chars till end

	;
	; Now copy it
	;

	mov	si, di			; ds:si - src

	cmp	cx, NL_MAX_DOMAIN_NAME_LENGTH
EC <	ERROR_A NL_ERROR_DOMAIN_NAME_TOO_LONG>

	pop	es,di			; dest
	shr	cx, 1
	jnc	5$
	movsb
5$:	rep	movsw			; strcpy
	mov	{byte} es:[di], 0	; add null
	ret
CopyUntilCharOrNull	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strlen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gets length of null-terminated string

CALLED BY:	GLOBAL
PASS:		ds:si - string
RETURN:		cx - length
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
strlen	proc	far
	uses	ax,es,di
	.enter
	segmov	es,ds,cx		;es:di - src
	mov	di,si
	mov	cx, -1 
	clr	al
	repne	scasb
	not	cx			;# of chars + null
	.leave
	ret
strlen	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strncpy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copies a string given its size

CALLED BY:	GLOBAL
PASS:		ds:si - src
		es:di - dest
		cx - size
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	es:di must have space to fit ds:si string
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
strncpy	proc	far
	uses	cx,si,di
	.enter
	shr	cx, 1
	jnc	5$
	movsb
5$:	rep	movsw			;strcpy
	.leave
	ret
strncpy	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcmp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compares 2 strings

CALLED BY:	GLOBAL
PASS:		es:di - string 1
		ds:si - string 2

RETURN:		ax - 0 if match, else difference in chars
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
strcmp	proc	far	
	uses	cx,ds,es,si,di
	.enter
	push	di
	mov	cx, -1
	clr	ax			;
	repne	scasb			;
	not	cx			;CX <- # chars in str 1 (w/null)
	pop	di
	repe	cmpsb
	jz	exit			;If match, exit (with ax=0)
	mov	al, es:[di][-1]		;Else, return difference of chars
	sub	al, ds:[si][-1]		;
	cbw				;
exit:
	.leave
	ret
strcmp	endp

NetCommonCode	ends
