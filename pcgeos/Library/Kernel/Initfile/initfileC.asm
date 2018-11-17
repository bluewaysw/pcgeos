COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Initfile
FILE:		initfileC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the geode routines

	$Id: initfileC.asm,v 1.1 97/04/05 01:18:07 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_System	segment resource

if FULL_EXECUTE_IN_PLACE
C_System	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileWriteData

C DECLARATION:	extern void
		    _far _pascal InitFileWriteData(const char _far *category,
						const char _far *key,
						const void _far *buffer,
						word bufSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEWRITEDATA	proc	far	category:fptr.char, key:fptr.char,
					buffer:fptr, bufSize:word
				uses si, di, ds, es
	.enter

	lds	si, category
	les	di, buffer
	mov	cx, key.segment
	mov	dx, key.offset
	push	bp
	mov	bp, bufSize
	call	InitFileWriteData
	pop	bp

	.leave
	ret

INITFILEWRITEDATA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileWriteString

C DECLARATION:	extern void
		    _far _pascal InitFileWriteString(const char _far *category,
						const char _far *key,
						const char _far *pstr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEWRITESTRING	proc	far	category:fptr.char, key:fptr.char,
					pstr:fptr.char
				uses si, di, ds, es
	.enter

	lds	si, category
	les	di, pstr
	mov	cx, key.segment
	mov	dx, key.offset
	call	InitFileWriteString

	.leave
	ret

INITFILEWRITESTRING	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileWriteInteger

C DECLARATION:	extern void
		    _far _pascal InitFileWriteInteger(const char _far *category,
						const char _far *key,
						word value);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEWRITEINTEGER	proc	far	category:fptr.char, key:fptr.char,
					value:word
				uses si, ds
	.enter

	lds	si, category
	mov	cx, key.segment
	mov	dx, key.offset
	push	bp
	mov	bp, value
	call	InitFileWriteInteger
	pop	bp

	.leave
	ret

INITFILEWRITEINTEGER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileWriteBoolean

C DECLARATION:	extern void
		    _far _pascal InitFileWriteBoolean(const char _far *category,
						const char _far *key,
						Boolean bool);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEWRITEBOOLEAN	proc	far	category:fptr.char, key:fptr.char,
					bool:word
				uses si, ds
	.enter

	lds	si, category
	mov	cx, key.segment
	mov	dx, key.offset
	mov	ax, bool
	call	InitFileWriteBoolean

	.leave
	ret

INITFILEWRITEBOOLEAN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileWriteStringSection

C DECLARATION:	extern void
		    _far _pascal InitFileWriteStringSection(
						const char _far *category,
						const char _far *key,
						const char _far *string);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/91		Initial version

------------------------------------------------------------------------------@
INITFILEWRITESTRINGSECTION	proc	far	category:fptr.char,
						key:fptr.char, string:fptr.char
				uses di, si, ds, es
	.enter

	lds	si, category
	les	di, string
	mov	cx, key.segment
	mov	dx, key.offset
	call	InitFileWriteStringSection

	.leave
	ret

INITFILEWRITESTRINGSECTION	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileBlockCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to read/write a block of stuff

CALLED BY:	INTERNAL
PASS:		cs:ax	= callback routine
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileBlockCommon proc	near	category:fptr.char, key:fptr.char,
					block:fptr.hptr, flags:word,
					dataSize:fptr.word,
					:fptr		; caller's return
							;  address
		uses	ds, si
		.enter
	;
	; Load up the registers.
	;
		lds	si, category
		mov	cx, key.segment
		mov	dx, key.offset
		push	bp
		mov	ax, ss:[bp+2]	; ax <- our return address
		mov	bp, flags
EC <		test	bp, mask IFRF_SIZE				>
EC <		ERROR_NZ	INIT_FILE_BLOCK_ROUTINES_SHOULD_NOT_HAVE_A_SIZE_PASSED_IN_FLAGS_WORD >
	;
	; Call back to our caller
	; 
		call	ax
		pop	bp
	;
	; Store the handle in the buffer provided
	; 
		lds	si, block
		mov	ds:[si], bx
	;
	; Store the entry size in the buffer provided
	; 
		lds	si, dataSize
		mov	ds:[si], cx
	;
	; Return non-zero if carry came back set.
	; 
		mov	ax, 0
		jnc	done
		dec	ax
done:
		.leave
		inc	sp		; discard our return address
		inc	sp
	;
	; Return to our caller's caller
	; 
		retf	@ArgSize-4	; don't include caller's retaddr
InitFileBlockCommon endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileBufferCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to read/write a buffer of stuff

CALLED BY:	INTERNAL
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileBufferCommon proc	near	category:fptr.char, key:fptr.char,
		     			buffer:fptr, flagsAndBufSize:word,
					dataSize:fptr.word,
					:fptr		; caller's return
							;  address segment
		uses	ds, si, es, di
		.enter
	;
	; Load up the registers.
	;
		lds	si, category
		les	di, ss:[buffer]
		mov	cx, key.segment
		mov	dx, key.offset
		push	bp
		mov	ax, ss:[bp+2]		; ax <- our return address
		mov	bp, flagsAndBufSize
	;
	; Call back to our caller
	; 
		call	ax
		pop	bp
	;
	; Store the entry size in the buffer provided
	; 
		lds	si, dataSize
		mov	ds:[si], cx
	;
	; Return non-zero if carry came back set.
	; 
		mov	ax, 0
		jnc	done
		dec	ax
done:
		.leave
		inc	sp		; discard our return address
		inc	sp
	;
	; Return to our caller's caller
	; 
		retf	@ArgSize-4	; don't include caller's retaddr...
InitFileBufferCommon endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileReadDataBuffer

C DECLARATION:	extern Boolean	/* true if error */
		    _far _pascal InitFileReadDataBuffer(
					const char _far *category,
					const char _far *key,
					void _far *buffer, word bufSize,
					word _far *dataSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEREADDATABUFFER	proc	far
	call	InitFileBufferCommon
	call	InitFileReadData
	retn				; return to InitFileBufferCommon
INITFILEREADDATABUFFER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileReadDataBlock

C DECLARATION:	extern Boolean	/* true if error */
		    _far _pascal InitFileReadDataBlock(
					const char _far *category,
					const char _far *key,
					MemHandle _far *block,
					word _far *dataSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
zero	word	0
INITFILEREADDATABLOCK	proc	far
	;
	; One too few arguments passed -- there's neither buffer size nor need
	; to pass conversion flags in this case, so we need to insert a fake
	; flags word between "block" and "dataSize" to be able to use the common
	; code...
	; 
	pop	ax, dx,	bx, cx		; ax:dx <- dataSize
					; bx:cx <- return address
	push	cs:[zero], ax, dx, bx, cx; push flags to indicate allocation
					 ; required, dataSize, return address
	call	InitFileBlockCommon
	call	InitFileReadData
	retn				; return to InitFileBlockCommon
INITFILEREADDATABLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileReadStringBuffer

C DECLARATION:	extern Boolean	/* true if error */
		    _far _pascal InitFileReadStringBuffer(
					const char _far *category,
					const char _far *key,
					char _far *pstr, word flagsAndBufSize,
					word _far *dataSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEREADSTRINGBUFFER	proc	far
	call	InitFileBufferCommon
	call	InitFileReadString
	retn				; return to InitFileBufferCommon
INITFILEREADSTRINGBUFFER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileReadStringBlock

C DECLARATION:	extern Boolean	/* true if error */
		    _far _pascal InitFileReadStringBlock(
					const char _far *category,
					const char _far *key,
					MemHandle _far *block,
					word flags, word _far *dataSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEREADSTRINGBLOCK	proc	far
	call	InitFileBlockCommon
	call	InitFileReadString
	retn				; return to InitFileBlockCommon
INITFILEREADSTRINGBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileReadStringSectionBuffer

C DECLARATION:	extern Boolean	/* true if error */
		    _far _pascal InitFileReadStringSectionBuffer(
					const char _far *category,
					const char _far *key,
					word section,
					char _far *pstr, word flagsAndBufSize,
					word _far *dataSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEREADSTRINGSECTIONBUFFER	proc	far	category:fptr.char,
						key:fptr.char, section:word,
						pstr:fptr.char,
						flagsAndBufSize:word,
						dataSize:fptr.word
		on_stack	retf
	clc			; XXX: WE HAVE NO LOCAL VARIABLES, SO PROLOGUE
				;  WILL NOT DO ANYTHING TO THE CARRY
				uses si, di, ds, es
stringSectionCommon label near
	.enter

		on_stack	ds es di si bp retf

	; carry is set if it's a block operation

	lds	si, category
	les	di, pstr
	mov	cx, key.segment
	mov	dx, key.offset
	mov	ax, section
	push	bp

		on_stack	bp ds es di si bp retf

	mov	bp, flagsAndBufSize
	jc	isBlock
	call	InitFileReadStringSection
	pop	bp

	on_stack	ds es di si bp retf

stringSectionDone:
	lds	si, dataSize
	mov	ds:[si], cx

	mov	ax, 0
	jnc	done
	dec	ax
done:
	.leave

		on_stack	retf

	ret

isBlock:
	;
	; Reading into a block, so ensure the size is 0 (to force allocation)
	; 
		on_stack	bp ds es di si bp retf

	andnf	bp, not mask IFRF_SIZE
	call	InitFileReadStringSection
	pop	bp

		on_stack	ds es di si bp retf
	;
	; Now store the returned handle in the buffer provided.
	; 
	mov	es:[di], bx
	jmp	stringSectionDone
INITFILEREADSTRINGSECTIONBUFFER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileReadStringSectionBlock

C DECLARATION:	extern Boolean	/* true if error */
		    _far _pascal InitFileReadStringSectionBlock(
					const char _far *category,
					const char _far *key,
					word section,
					MemHandle _far *block,
					word flags, word _far *dataSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEREADSTRINGSECTIONBLOCK	proc
	stc
	jmp	stringSectionCommon
INITFILEREADSTRINGSECTIONBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileEnumStringSection

C DECLARATION:	extern Boolean	/* true if error */
		    _far _pascal InitFileEnumStringSection(
			const char _far *category,
			const char _far *key,
			word flags,
			Boolean (*callback) (const char *stringSection,
					     word sectionNumber,
					     void *enumData)
			void _far *enumData);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/92		Initial version

------------------------------------------------------------------------------@
INITFILEENUMSTRINGSECTION	proc	far	category:fptr.char,
						key:fptr.char,
						flags:word,
						callback:fptr.far,
						enumData:fptr
	uses		di, si, ds, es
	ForceRef	callback
	ForceRef	enumData
	.enter

	; Set everything up for the enumeration
	;
	segmov	es, ds				; keep DS to pass to callback
	mov	bx, bp				; stack frame => SS:BX
	lds	si, category
	movdw	cxdx, key
	mov	bp, flags
	mov	di, cs				; callback => DI:AX
	mov	ax, offset _INITFILEENUMSTRINGSECTION_callback
	call	InitFileEnumStringSection
	
	; NOTE: THE TRASHING OF BP WORKS BECAUSE WE HAVE NO LOCAL VARIABLES.
	; Esp OPTIMIZES THIS CASE SO THE .leave DOESN'T REQUIRE BP

	; Set up the return values
	;
	mov	ax, 0				; assume no error (FALSE => AX)
	jnc	done				; jump if correct assumption
	dec	ax				; else TRUE => AX
done:
	.leave
	ret
INITFILEENUMSTRINGSECTION	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	_INITFILEENUMSTRINGSECTION_callback

DESCRIPTION:	Callback routine for InitFileEnumStringSection

CALLED BY:	InitFileEnumStringSection (via INITFILEENUMSTRINGSECTION)

PASS:		DS:SI	= String section
		DX	= String section number
		ES	= DS passed to INITFILEENUMSTRINGSECTION
		SS:BX	= Stack frame

RETURN:		Carry	= Set to end enumeration

DESTROYED:	AX, CX, DX, DI, SI, BP, DS

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/92		Initial version

------------------------------------------------------------------------------@
_INITFILEENUMSTRINGSECTION_callback	proc	far
	uses	bx
	.enter	inherit	INITFILEENUMSTRINGSECTION
	mov	bp, bx				; stack frame => SS:BP

	; Push arguments to the real callback
	;
	push	ds, si				; string section
	push	dx				; string section number
	pushdw	enumData			; passed data

	; Now perform the callback
	;
	segmov	ds, es				; restore DS to original
	movdw	bxax, callback
	call	ProcCallFixedOrMovable

	; Now return the carry correctly
	;
	tst	ax				; clears carry (assume continue)
	jz	done				; jump if assumption OK
	stc					; else stop enumeration
done:
	.leave
	ret
_INITFILEENUMSTRINGSECTION_callback	endp

if DBCS_PCGEOS

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileReadAllInteger

C DECLARATION:	extern Boolean	/* true if error */
		    _far _pascal InitFileReadAllInteger(
			const char _far *category,
			const char _far *key,
			Boolean (*callback) (word integerValue,
					     void *enumData)
			void _far *enumData);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/19/94		Initial version

------------------------------------------------------------------------------@
INITFILEREADALLINTEGER	proc	far	category:fptr.char,
						key:fptr.char,
						callback:fptr.far,
						enumData:fptr
	uses		di, si, ds, es
	ForceRef	callback
	ForceRef	enumData
	.enter

	; Set everything up for the enumeration
	;
	segmov	es, ds				; keep DS to pass to callback
	mov	bx, bp				; stack frame => SS:BX
	lds	si, category
	movdw	cxdx, key
	mov	di, cs				; callback => DI:AX
	mov	ax, offset _INITFILEREALALLINTEGER_callback
	call	InitFileReadAllInteger
	
	; Set up the return values
	;
	mov	ax, 0				; assume no error (FALSE => AX)
	jnc	done				; jump if correct assumption
	dec	ax				; else TRUE => AX
done:
	.leave
	ret
INITFILEREADALLINTEGER	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	_INITFILEREALALLINTEGER_callback

DESCRIPTION:	Callback routine for InitFileReadAllInteger

CALLED BY:	InitFileReadAllInteger (via INITFILEREADALLINTEGER)

PASS:		AX	= integer
		ES	= DS passed to INITFILEREADALLINTEGER
		SS:BX	= Stack frame

RETURN:		Carry	= Set to end enumeration

DESTROYED:	AX, CX, DX, DI, SI, BP, DS

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/19/94		Initial version

------------------------------------------------------------------------------@
_INITFILEREALALLINTEGER_callback	proc	far
	uses	bx
	.enter	inherit	INITFILEREADALLINTEGER
	mov	bp, bx				; stack frame => SS:BP

	; Push arguments to the real callback
	;
	push	ax				; integer
	pushdw	enumData			; passed data

	; Now perform the callback
	;
	segmov	ds, es				; restore DS to original
	movdw	bxax, callback
	call	ProcCallFixedOrMovable

	; Now return the carry correctly
	;
	tst	ax				; clears carry (assume continue)
	jz	done				; jump if assumption OK
	stc					; else stop enumeration
done:
	.leave
	ret
_INITFILEREALALLINTEGER_callback	endp

endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileReadInteger

C DECLARATION:	extern Boolean	/* true if error */
		    _far _pascal InitFileReadInteger(const char _far *category,
				const char _far *key, word _far *i);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEREADINTEGER	proc	far	category:fptr.char, key:fptr.char,
					i:fptr.word
				uses si, ds
	clc
CInitFileGetCommon	label	far
	.enter

	lds	si, i
	mov	ax, ds:[si]			; ax <- original value of i/bool

	lds	si, category
	mov	cx, key.segment
	mov	dx, key.offset
	jc	boolean
	call	InitFileReadInteger
	jmp	common
boolean:
	call	InitFileReadBoolean
common:

	lds	si, i
	mov	ds:[si], ax

	mov	ax, 0
	jnc	done
	dec	ax
done:
	.leave
	ret

INITFILEREADINTEGER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileReadBoolean

C DECLARATION:	extern Boolean	/* true if error */
		    _far _pascal InitFileReadBoolean(const char _far *category,
				const char _far *key, Boolean _far *bool);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEREADBOOLEAN	proc	far
	stc
	jmp	CInitFileGetCommon

INITFILEREADBOOLEAN	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_System	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileGetTimeLastModified

C DECLARATION:	extern dword
			_far _pascal InitFileGetTimeLastModified();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEGETTIMELASTMODIFIED	proc	far

	call	InitFileGetTimeLastModified
	mov_trash	ax, dx
	mov	dx, cx
	ret

INITFILEGETTIMELASTMODIFIED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileSave

C DECLARATION:	extern Boolean
			_far _pascal InitFileSave();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILESAVE	proc	far

	call	InitFileSave
	FALL_THRU	CIFReturnError

INITFILESAVE	endp

CIFReturnError	proc	far
	mov	ax, 0
	jnc	done
	dec	ax
done:
	ret
CIFReturnError	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileRevert

C DECLARATION:	extern Boolean
			_far _pascal InitFileRevert();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEREVERT	proc	far

	call	InitFileRevert
	GOTO	CIFReturnError

INITFILEREVERT	endp

if FULL_EXECUTE_IN_PLACE
C_System	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileDeleteStringSection

C DECLARATION:	extern void
		    _far _pascal InitFileDeleteStringSection(
						const char _far *category,
						const char _far *key,
						word stringNum);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/91		Initial version

------------------------------------------------------------------------------@
INITFILEDELETESTRINGSECTION	proc	far	category:fptr.char,
						key:fptr.char, stringNum:word
				uses si, ds
	.enter

	lds	si, category
	mov	cx, key.segment
	mov	dx, key.offset
	mov	ax, stringNum
	call	InitFileDeleteStringSection

	.leave
	ret

INITFILEDELETESTRINGSECTION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileDeleteEntry

C DECLARATION:	extern void
		    _far _pascal InitFileDeleteEntry(const char _far *category,
						const char _far *key);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEDELETEENTRY	proc	far	category:fptr.far, key:fptr.far
				uses si, ds
	.enter

	lds	si, category
	mov	cx, key.segment
	mov	dx, key.offset
	call	InitFileDeleteEntry

	.leave
	ret

INITFILEDELETEENTRY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileDeleteCategory

C DECLARATION:	extern void
		    _far _pascal InitFileDeleteCategory(const char _far
								*category);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEDELETECATEGORY	proc	far
        C_GetOneDWordArg        bx, ax,   cx,dx ;bx = seg, ax = offset

	push	si, ds
	mov	ds, bx
	mov_trash	si, ax
	call	InitFileDeleteCategory
	pop	si, ds

	ret

INITFILEDELETECATEGORY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileMakeCanonicKeyCategory

C DECLARATION:	extern void
	    _far _pascal InitFileMakeCanonicKeyCategory(char *keyCat,
							const TCHAR *src);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
INITFILEMAKECANONICKEYCATEGORY	proc	far	keyCat:fptr.char,
						src:fptr.TCHAR
	uses si, di, ds
	.enter

	lds	si, keyCat
	les	di, src	
	call	InitFileMakeCanonicKeyCategory

	.leave
	ret
	
INITFILEMAKECANONICKEYCATEGORY	endp


if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_System	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	InitFileGrab

C DECLARATION:	extern word
		    _far _pascal InitFileGrab(MemHandle mem,
					FileHandle fh,
					word bufSize); 

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb	10/93		Initial version

------------------------------------------------------------------------------@
INITFILEGRAB	proc	far	mem:hptr, fh:hptr, bufSize:word

		.enter
		mov	ax, ss:[mem]
		mov	bx, ss:[fh]
		mov	cx, ss:[bufSize]
		call	InitFileGrab
		mov	ax, 0
		jnc	done
		dec	ax
done:		
		.leave
		ret

INITFILEGRAB	endp


C_System	ends

	SetDefaultConvention
