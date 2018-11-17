COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Lights Out
MODULE:		Encryption
FILE:		saverCrypt.asm

AUTHOR:		Adam de Boor, Dec  8, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT SaverCryptCalculateSeed Calculate the 32-bit seed based on the key.

    GLB SaverCryptInit		Initialize encryption/decryption

    INT SaverCryptCreateKey	Create the 13-byte key for the machine from
				the arbitrary- sized key we've been given.

    INT SaverCryptInitRotor	Initialize one of the rotors to its most
				basic form: the numbers from 0 to
				SAVER_CRYPT_ROTOR_SIZE-1

    INT SaverCryptMangle1stAnd3dRotors Permute the contents of the 1st
				rotor, based on the key, and use it to set
				up the 3d rotor.

    GLB SaverCryptEncrypt	Encrypt a block of text using the given
				machine

    GLB SaverCryptDecrypt	This is actually the same function as
				SaverCryptEncrypt, apparently...

    GLB SaverCryptEnd		Finish with a crypt machine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 8/92	Initial revision


DESCRIPTION:
	Functions to implement a simple encryption machine.
		

	$Id: saverCrypt.asm,v 1.1 97/04/07 10:44:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SAVER_CRYPT_ROTOR_SIZE	equ	256	; NOTE: IF YOU CHANGE THIS FROM 256,
					;  YOU WILL HAVE TO REWRITE MUCH OF
					;  THIS CODE
SAVER_CRYPT_KEY_SIZE	equ	13

SaverCryptRotor	type	SAVER_CRYPT_ROTOR_SIZE dup(byte)

SaverCryptMachine struct
    SCM_t1	SaverCryptRotor
    SCM_t2	SaverCryptRotor
    SCM_t3	SaverCryptRotor
    SCM_deck	SaverCryptRotor
    SCM_key	byte	SAVER_CRYPT_KEY_SIZE dup(?)
    SCM_seed	dword
SaverCryptMachine ends
    

SaverCryptCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverCryptCalculateSeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the 32-bit seed based on the key.

CALLED BY:	(INTERNAL) SaverCryptInit
PASS:		ds:si	= key
RETURN:		dxax	= 32-bit seed
DESTROYED:	si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverCryptCalculateSeed proc	near
		uses	bx, di, bp
		.enter
		clr	bx
		mov	dx, 0x31fe	; magic number

		mov	cl, 5
SBCS <		clr	ah						>
charLoop:
SBCS <		lodsb							>
DBCS <		lodsw							>
		LocalIsNull	ax	; end of string?
		jz	done		; yes
	;
	; Multiply existing value by 33
	; 
		movdw	dibp, bxdx	; save current value for add
		rol	dx, cl		; *32, saving high 5 bits in low ones
		shl	bx, cl		; *32, making room for high 5 bits of
					;  dx
		mov	ch, dl
		andnf	ch, 0x1f	; ch <- high 5 bits of dx
		andnf	dl, not 0x1f	; nuke saved high 5 bits
		or	bl, ch		; shift high 5 bits into bx
		adddw	bxdx, dibp	; *32+1 = *33
	;
	; Add current character into the value.
	; 
		add	dx, ax
		adc	bx, 0
		jmp	charLoop		
done:
	;
	; Return ID in dxax
	; 
		mov_tr	ax, bx		; ax <- low word
		xchg	ax, dx		; dx <- high word, ax <- low word
		.leave
		ret
SaverCryptCalculateSeed endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverCryptInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize encryption/decryption

CALLED BY:	(GLOBAL)
PASS:		ds:si	= null-terminated key
RETURN:		carry set if unable to initialize
			bx	= destroyed
		carry clear ok:
			bx	= token to pass to SaverEncrypt or SaverDecrypt
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverCryptInit	proc	far
		uses	cx, dx, si, di, bp, ds, es
		.enter
	;
	; Allocate a locked block for the machine.
	; 
		mov	ax, size SaverCryptMachine
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		jc	done
		mov	es, ax
	;
	; Create the pseudo-random key and seed from the actual one.
	; 
		call	SaverCryptCreateKey
	;
	; Initialize the first rotor and the "deck", whatever that is.
	; 
		mov	di, offset SCM_t1
		call	SaverCryptInitRotor
		mov	di, offset SCM_deck
		call	SaverCryptInitRotor
	;
	; Now mangle it according to the key, setting up the 3d rotor at
	; the same time.
	; 
		call	SaverCryptMangle1stAnd3dRotors
	;
	; Initialize the second rotor based on the first:
	; for (i=0; i < ROTORSZ; i++) t2[t1[i] & MASK] = i;
	; 
		mov	si, offset SCM_t1
		mov	cx, SAVER_CRYPT_ROTOR_SIZE
		clr	dx, ax
t2Loop:
		lodsb			; al <- t1[i]
		mov	di, ax		; di <- t1[i] & MASK
		mov	ds:[SCM_t2][di], dl
		inc	dx
		loop	t2Loop
	;
	; Unlock the machine
	; 
		call	MemUnlock
		clc
done:
		.leave
		ret
SaverCryptInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverCryptCreateKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the 13-byte key for the machine from the arbitrary-
		sized key we've been given.

CALLED BY:	(INTERNAL) SaverCryptInit
PASS:		ds:si	= null-terminated key
		es	= SaverCryptMachine
RETURN:		es:[SCM_key] filled in
		es:[SCM_seed] = seed for filling in the wheels
		ds	= es
DESTROYED:	cx, si, di, dx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverCryptCreateKey proc	near
		uses	bx
		.enter
	;
	; Create a random number generator whose seed comes from the key.
	; We hash the key to a 32-bit number using the standard function
	; we seem to employ everywhere these days, then pass that to
	; SaverSeedRandom.
	; 
		call	SaverCryptCalculateSeed	; dxax <- seed
		clr	bx			; create new generator
		call	SaverSeedRandom
	;
	; Generate enough 1-byte random numbers to fill in the key.
	; 
		mov	cx, SAVER_CRYPT_KEY_SIZE
		mov	di, offset SCM_key
keyLoop:
		mov	dx, 256
		call	SaverRandom
		mov_tr	ax, dx
		stosb
		loop	keyLoop
	;
	; Nuke the random number generator.
	; 
		call	SaverEndRandom
	;
	; Now generate the seed for filling in the different wheels of the rotor
	; seed = 123;
	; for (i=0; i<13 ; i++)
	; 	seed = seed*buf[i] + i;
	; 
		segmov	ds, es
		mov	si, offset SCM_key
		mov	dx, 123
		clr	di
		mov	cx, SAVER_CRYPT_KEY_SIZE
		clr	ax, bp
seedLoop:
		lodsb
		push	cx, si
		clr	cx		; didx.cx <- multiplier
		mov_tr	bx, ax
		clr	ax, si		; sibx.ax <- multiplicand
		call	GrMulDWFixed	; dxcx.bx <- result

		add	cx, bp
		adc	dx, 0
		mov	di, dx		; didx <- seed = seed * buf[i] + i
		mov	dx, cx
		pop	cx, si

		inc	bp
		loop	seedLoop

		movdw	ds:[SCM_seed], didx
		.leave
		ret
SaverCryptCreateKey endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverCryptInitRotor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize one of the rotors to its most basic form: the
		numbers from 0 to SAVER_CRYPT_ROTOR_SIZE-1

CALLED BY:	(INTERNAL) SaverCryptInit
PASS:		es:di	= SaverCryptRotor to initialize
RETURN:		nothing
DESTROYED:	ax, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverCryptInitRotor proc near
		.enter
		clr	ax
		mov	cx, size SaverCryptRotor
initLoop:
		stosb
		inc	al
		loop	initLoop
		.leave
		ret
SaverCryptInitRotor endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverCryptMangle1stAnd3dRotors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Permute the contents of the 1st rotor, based on the key, and
		use it to set up the 3d rotor.

CALLED BY:	(INTERNAL) SaverCryptInit
PASS:		ds, es	= SaverCryptMachine
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		for(i=0;i<ROTORSZ;i++) {
			seed = 5*seed + buf[i%13];
			random = seed % 65521;
			k = ROTORSZ-1 - i;
			ic = (random&MASK)%(k+1);
			random >>= 8;
			temp = t1[k];
			t1[k] = t1[ic];
			t1[ic] = temp;
			if(t3[k]!=0) continue;
			ic = (random&MASK) % k;
			while(t3[ic]!=0) ic = (ic+1) % k;
			t3[k] = ic;
			t3[ic] = k;
		}

		Don't ask me why... This comes from a program whose only
		documentation reads as follows:

 *	A one-rotor machine designed along the lines of Enigma
 *	but considerably trivialized.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverCryptMangle1stAnd3dRotors proc near
		uses	bx
		.enter
		clr	bx		; bx <- i%13 during the loop
		mov	cx, SAVER_CRYPT_ROTOR_SIZE
deeLoop:
	;
	; seed = 5 * seed + buf[i%13]
	; 
		movdw	dxax, ds:[SCM_seed]
		shldw	dxax
		shldw	dxax
		adddw	dxax, ds:[SCM_seed]
		add	al, ds:[SCM_key][bx]
		adc	ah, 0
		add	dx, 0
		movdw	ds:[SCM_seed], dxax
	;
	; random = seed % 65521.  First clear the high bit of the seed,
	; to make sure the result fits in ax (thus preventing any nasty
	; divide-by-zero errors).
	;
		andnf	dh, 01111111b
		mov	si, 65521
		div	si		; dx <- random
	;
	; k = ROTORSZ-1 - i
	; 
		mov	di, cx		; di <- ROTORSZ-i
		dec	di		; k <- ROTORSZ-1-i
	;
	; ic = (random & MASK) % (k+1)
	;
		mov	si, dx
		mov_tr	ax, dx
		clr	ah
		clr	dx		; dxax <- random&MASK (aka low byte)
		div	cx		; dx <- random%(k+1)
		xchg	dx, si		; dx <- random, si <- ic
		
	;
	; temp = t1[k]; t1[k] = t1[ic]; t1[ic] = temp
	; 
		mov	al, ds:[SCM_t1][di]	; temp <- t1[k]
		xchg	ds:[SCM_t1][si], al	; t1[ic] <- t1[k]
		mov	ds:[SCM_t1][di], al	; t1[k] <- t1[ic]
	;
	; if (t3[k] != 0) continue
	; 
		tst	ds:[SCM_t3][di]
		jnz	endLoop
	;
	; ic = ((random>>8) & MASK) % k
	; 
		mov	al, dh
		clr	ah
		clr	dx
		div	di			; dx <- ((random>>8)&MASK)%k
t3Loop:
	;
	; while (t3[ic] != 0) ic = (ic+1) % k
	; 
		mov	si, dx			; ic <- that
		tst	ds:[SCM_t3][si]
		jz	setT3
		inc	dx
		cmp	dx, di
		jne	t3Loop
		clr	dx
		jmp	t3Loop
setT3:
	;
	; t3[k] = ic
	;
		mov	ds:[SCM_t3][di], dl
	;
	; t3[ic] = k
	;
		mov_tr	ax, di
		mov	ds:[SCM_t3][si], al
endLoop:
	;
	; i++
	; 
		inc	bx
		cmp	bx, SAVER_CRYPT_KEY_SIZE
		jne	next
		clr	bx		; %13
next:
		loop	deeLoop
		
		.leave
		ret
SaverCryptMangle1stAnd3dRotors endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverCryptEncrypt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encrypt a block of text using the given machine

CALLED BY:	(GLOBAL)
PASS:		bx	= token returned by SaverCryptInit
		ds:si	= text to encrypt
		cx	= # bytes
RETURN:		ds:si	= overwritten with encrypted bytes
DESTROYED:	ax
SIDE EFFECTS:	passed buffer is overwritten

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverCryptEncrypt proc	far
		uses	es, di, dx, si, cx, bp
		.enter
		call	MemLock
		mov	es, ax
		push	bx
		clr	bx, di
		jcxz	done
	; bx = n1, di = n2
SBCS <		clr	ax						>
theLoop:
SBCS <		lodsb							>
DBCS <		lodsw							>
	;
	; Index through the first rotor.
	; 
		add	ax, bx
		clr	ah
		mov	bp, ax
		mov	al, es:[SCM_t1][bp]	; al <- t1[(i+n1)&0xff]
	;
	; Now through the third rotor.
	; 
		add	ax, di
		clr	ah
		mov	bp, ax
		mov	al, es:[SCM_t3][bp]	; al <-t3[(t1[(i+n1)&0xff]+n2)7xff]
		
	;
	; Then through the second rotor.
	; 
		sub	ax, di
		clr	ah
		mov	bp, ax
		mov	al, es:[SCM_t2][bp]
	;
	; And one final subtraction.
	; 
		sub	ax, bx
		mov	ds:[si-1], al
	;
	; Advance rotor pointers.
	; 
		inc	bx
		and	bx, 0xff
		jnz	endLoop
		inc	di
		andnf	di, 0xff
endLoop:
		loop	theLoop
	;
	; Unlock the machine and return.
	; 
done:
		pop	bx
		call	MemUnlock
		.leave
		ret
SaverCryptEncrypt endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverCryptDecrypt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is actually the same function as SaverCryptEncrypt,
		apparently...

CALLED BY:	(GLOBAL)
PASS:		bx	= token returned by SaverCryptInit
		ds:si	= data to decrypt
		cx	= # bytes to decrypt
RETURN:		ds:si	= filled with cleartext
DESTROYED:	ax
SIDE EFFECTS:	passed buffer is overwritten

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverCryptDecrypt proc	far
		GOTO	SaverCryptEncrypt
SaverCryptDecrypt endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverCryptEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish with a crypt machine

CALLED BY:	(GLOBAL)
PASS:		bx	= token returned by SaverCryptInit
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	crypt machine is destroyed and should not be used again

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverCryptEnd	proc	far
		.enter
		call	MemFree
		.leave
		ret
SaverCryptEnd	endp


SaverCryptCode	ends
