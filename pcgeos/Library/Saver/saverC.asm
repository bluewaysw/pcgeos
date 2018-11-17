COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		the saver library
FILE:		saverC.asm

AUTHOR:		Jeremy Dashe, Apr  8, 1993

ROUTINES:
	Name				Description
	----				-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/93		Initial revision

DESCRIPTION:
	This file contains C stubs for the saver library.
	
	$Id: saverC.asm,v 1.1 97/04/07 10:44:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetGeosConvention

SaverUtilsCode		segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverCreateLaunchBlock

C DECLARATION:	extern MemHandle _pascal
  		SaverCreateLaunchBlock(DiskHandle disk, char *saverPath);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	We need to pass in a "segment that can be fixed up" in ds, so
	we grab our dgroup and pass that in.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/8/93		Initial version

------------------------------------------------------------------------------@
SAVERCREATELAUNCHBLOCK	proc	far	disk:hptr, saverPath:fptr
	uses	ds
	.enter

	; We need to pass in a "segment that can be fixed up" in ds, so
	; we'll grab our dgroup and pass that in.

	call	GeodeGetProcessHandle		; bx <- process handle
	call	GeodeGetDGroupDS		; ds <- dgroup's segment

	mov	cx, ss:saverPath.high		; cx:dx <- path to saver
	mov	dx, ss:saverPath.low
	mov	bp, ss:disk			; bp <- disk handle on
						; which saver is located

	call	SaverCreateLaunchBlock
	
	.leave
	ret

SAVERCREATELAUNCHBLOCK	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverDuplicateALB

C DECLARATION:	extern MemHandle _pascal
		SaverDuplicateALB(MemHandle blockToDuplicate);  		

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/8/93		Initial version

------------------------------------------------------------------------------@
SAVERDUPLICATEALB	proc	far	blockToDuplicate:hptr
	.enter

	mov	bx, ss:blockToDuplicate
	call	SaverDuplicateALB		; bx <- new handle

	mov	ax, bx				; ax <- new handle
		
	.leave
	ret
SAVERDUPLICATEALB	endp

SaverUtilsCode		ends


SaverRandomCode		segment resource
COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverSeedRandom

C DECLARATION:	extern RandomToken
	        _pascal SaverSeedRandom(dword seed, RandomToken rng);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/8/93		Initial version

------------------------------------------------------------------------------@
SAVERSEEDRANDOM	proc	far	seed:dword, rng:word
	.enter

	mov	dx, ss:seed.high	; dx:ax <- initial seed
	mov	ax, ss:seed.low
	
	mov	bx, ss:rng		; bx <- generator to change

	call	SaverSeedRandom		; bx <- token to pass to SaverRandom
	
	mov	ax, bx			; ax <- token to pass to SaverRandom 	

	.leave
	ret
SAVERSEEDRANDOM	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverRandom

C DECLARATION:	extern word
		_pascal SaverRandom(word maxValue, RandomToken rng);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/8/93		Initial version

------------------------------------------------------------------------------@
SAVERRANDOM	proc	far	maxValue:word, rng:word
	.enter

	mov	dx, ss:maxValue		; dx <- max for returned value
	mov	bx, ss:rng		; bx <- token for random
					; number generator
	call	SaverRandom

	mov	ax, dx			; return number between 0 and
					; max - 1 

	.leave
	ret
SAVERRANDOM	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverEndRandom

C DECLARATION:	extern word
		_pascal SaverEndRandom(RandomToken rng)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/8/93		Initial version

------------------------------------------------------------------------------@
SAVERENDRANDOM	proc	far	rng:word
	.enter

	mov	bx, ss:rng		; bx <- token for random
					; number generator
	call	SaverEndRandom

	.leave
	ret
SAVERENDRANDOM	endp

SaverRandomCode		ends


SaverCryptCode		segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverCryptInit

		Returns a 0 if unable to initialize, a viable token
		otherwise.
		
C DECLARATION:	extern EncryptionMachineToken
		_pascal SaverCryptInit(char *key);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/8/93		Initial version

------------------------------------------------------------------------------@
SAVERCRYPTINIT	proc	far	key:fptr
	.enter

	lds	si, ss:key		; ds:si <- null-terminated key
	
	call	SaverCryptInit		; bx <- encryption machine token

	mov	ax, 0			; DOESN'T BIFF FLAGS.
	jnc	done 			; jump if unable to initialize

	mov	ax, bx			; returns the encryption
					; machine token.	
done:
	.leave
	ret
SAVERCRYPTINIT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverCryptEncrypt

C DECLARATION:	extern void
    		_pascal SaverCryptEncrypt(char *textToEncrypt,
	  			          word numChars,
			      		  EncryptionMachineToken emt);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/8/93		Initial version

------------------------------------------------------------------------------@
SAVERCRYPTENCRYPT	proc	far	textToEncrypt:fptr,
					numChars:word,
					emt:word
	uses	ds, si
	.enter

	lds	si, ss:textToEncrypt	; ds:si <- text to encrypt
	mov	cx, ss:numChars
	mov	bx, ss:emt
	
	call	SaverCryptEncrypt	; do the encryption

	.leave
	ret
SAVERCRYPTENCRYPT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverCryptDecrypt

C DECLARATION:	extern void _pascal
  		SaverCryptDecrypt(char *textToDecrypt,
				  word numChars,
			      	  EncryptionMachineToken emt);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/8/93		Initial version

------------------------------------------------------------------------------@
SAVERCRYPTDECRYPT	proc	far	textToDecrypt:fptr,
					numChars:word,
					emt:word
	uses	ds, si
	.enter

	lds	si, ss:textToDecrypt	; ds:si <- text to decrypt
	mov	cx, ss:numChars
	mov	bx, ss:emt
	
	call	SaverCryptEncrypt	; do the decryption

	.leave
	ret
SAVERCRYPTDECRYPT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverCryptEnd

C DECLARATION:	extern void _pascal
		SaverCryptEnd(EncryptionMachineToken emt);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/8/93		Initial version

------------------------------------------------------------------------------@
SAVERCRYPTEND	proc	far	emt:word
	.enter

	mov	bx, ss:emt
	
	call	SaverCryptEnd	

	.leave
	ret
SAVERCRYPTEND	endp

SaverCryptCode		ends


SaverVectorCode		segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverVectorInit

C DECLARATION:	extern void _pascal
		SaverVectorInit(SaverVector *saverVector,
			    	SaverVectorReflectType svrt,
			    	word minVal,
			    	word maxVal,
			    	byte deltaMax,
			    	byte deltaBase,
			    	RandomToken rng);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/9/93		Initial version

------------------------------------------------------------------------------@
SAVERVECTORINIT	proc	far	saverVector:fptr, svrt:word,
				minVal:word, maxVal:word,
				deltaMax:word, deltaBase:word,
				rng:word
	uses	es, si, di
	.enter

	les	di, ss:saverVector
	mov	ax, ss:svrt
	mov	cx, ss:minVal
	mov	dx, ss:maxVal
	mov	bh, ss:deltaBase.low
	mov	bl, ss:deltaMax.low
	mov	si, ss:rng

	call	SaverVectorInit

	.leave
	ret
SAVERVECTORINIT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverVectorUpdate

C DECLARATION:	extern  Boolean _pascal
		SaverVectorUpdate(SaverVector *saverVector,
			      	  RandomToken rng,
			      	  word *newPoint);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/9/93		Initial version

------------------------------------------------------------------------------@
SAVERVECTORUPDATE proc	far	saverVector:fptr, rng:word,
		  		newPoint:fptr
	uses	ds, si
	.enter

	lds	si, ss:saverVector
	mov	bx, ss:rng
	call	SaverVectorUpdate

	; Load the newPoint with the... new point.
	lds	si, ss:newPoint		; DOESN'T BIFF FLAGS.
	mov	ds:[si], ax		; DOESN'T BIFF FLAGS.

	mov	ax, 0			; DOESN'T BIFF FLAGS.
	jnc	done			; jump if vector delta DIDN'T change

	mov	ax, TRUE		; signal: delta changed.

done:
	.leave
	ret
SAVERVECTORUPDATE	endp

SaverVectorCode		ends


SaverFadeCode		segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverFadePatternFade

C DECLARATION:	extern void _pascal
  		SaverFadePatternFade(sword top,
				     sword left,
				     sword bottom,
				     sword right,
				     MemHandle gstate,
				     SaverFadeSpeed fadeSpeed);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/9/93		Initial version

------------------------------------------------------------------------------@
SAVERFADEPATTERNFADE	proc	far	top:word, left:word,
					bottom:word, right:word,
					gstate:hptr, fadeSpeed:word
	uses	di, si
	.enter

	mov	di, ss:gstate
	mov	ax, ss:left
	mov	bx, ss:top
	mov	cx, ss:right
	mov	dx, ss:bottom
	mov	si, ss:fadeSpeed

	call	SaverFadePatternFade

	.leave
	ret
SAVERFADEPATTERNFADE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverFadeWipe

C DECLARATION:	extern void _pascal
  		SaverFadeWipe(sword top,
			      sword left,
			      sword bottom,
			      sword right,
			      MemHandle gstate,
			      SaverFadeSpeed fadeSpeed,
			      SaverWipeTypes fadeWipe);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/9/93		Initial version

------------------------------------------------------------------------------@
SAVERFADEWIPE	proc	far	top:word, left:word,
				bottom:word, right:word,
				gstate:hptr, fadeSpeed:word,
				fadeWipe:word
	uses	di, si, bp
	.enter

	mov	di, ss:gstate
	mov	ax, ss:left
	mov	bx, ss:top
	mov	cx, ss:right
	mov	dx, ss:bottom
	mov	si, ss:fadeSpeed
	mov	bp, ss:fadeWipe

	call	SaverFadeWipe

	.leave
	ret
SAVERFADEWIPE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverDrawBGBitmap

C DECLARATION:	extern void _pascal
		SaverDrawBGBitmap(MemHandle gstate,
			      	  word width,
			      	  word height,
			      	  SaverBitmapMode saverBitmapMode,
			      	  FileHandle fileHandle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/9/93		Initial version

------------------------------------------------------------------------------@
SAVERDRAWBGBITMAP	proc	far	gstte:word, wdth:word,
					height:word, saverBitmapMode:word,
					fileHandle:word	
	uses	di
	.enter

	mov	di, ss:gstte
	mov	ax, ss:saverBitmapMode
	mov	cx, ss:wdth
	mov	dx, ss:height
	mov	bx, ss:fileHandle
		
	call	SaverDrawBGBitmap

	.leave
	ret
SAVERDRAWBGBITMAP	endp

SaverFadeCode		ends


SaverAppCode		segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SaverApplicationGetOptions
  		
C DECLARATION:	extern void _pascal
		SaverApplicationGetOptions(SAOptionTable *saoTable,
				       	   optr saverApplicationObject);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/9/93		Initial version

------------------------------------------------------------------------------@
SAVERAPPLICATIONGETOPTIONS proc	far	saoTable:fptr,
			   		saverApplicationObject:optr
	uses	ds, si, es
	.enter

	mov	bx, ss:saverApplicationObject.handle	; ds:si <- address
	call	MemDerefDS				; of object
	mov	si, ss:saverApplicationObject.offset

	les	bx, ss:saoTable			; es:bx <- SAOptionTable

	call	SaverApplicationGetOptions

	.leave
	ret
SAVERAPPLICATIONGETOPTIONS	endp

SaverAppCode		ends


SetDefaultConvention
