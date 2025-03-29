COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Ascii Translation Library
FILE:		exportMain.asm

AUTHOR:		Jenny Greenwood, 2 September 1992

ROUTINES:
	Name			Description
	----			-----------
GLB	TransExport		Exports from transfer item to output file

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/2/92		Initial version

DESCRIPTION:
	This file contains the main interface to the export side of the 
	library
		

	$Id: exportMain.asm,v 1.1 97/04/07 11:40:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportCode	segment	resource

DBCS <	DBCS_OUTPUT_BUFF_SIZE	=	READ_WRITE_BLOCK_SIZE/2/2*5	>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Export from transfer item to final Ascii file

CALLED BY:	GLOBAL
PASS:		ds:si	- ExportFrame on stack
RETURN:		ax	- TransError (0 = no error)
		bx	- memory handle of error text if ax = TE_CUSTOM

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Store the output file handle.
	Lock down the TextTransferBlockHeader and get the handle of
	 the first VM block of the HugeArray which contains the text.
	Get the amount of text we need to export.
	Allocate a buffer to read into.
	Export the text to the output file.
	Free the buffer.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jenny	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransExport	proc	far	uses cx, dx, di, es

DBCS < handleJISbuffer	local	hptr					>
DBCS < segJISbuffer	local	sptr		; for DoExport		>
DBCS < dosCodePage	local	DosCodePage	; for text conversion	>
outputFile	local	hptr
vmFile		local	hptr
vmBlock		local	word
textArray	local	word
charsLeft	local	dword			; length to process
		.enter
EC <		cmp	ds:[si].EF_formatNumber, IDSF__last		>
EC <		LONG  jae  badFormatNumber 	; SYSTEM IN ERROR	>

if DBCS_PCGEOS
		mov	cx, CODE_PAGE_SJIS
		cmp	ds:[si].EF_formatNumber, IDSF_ASCII
		je	setCodePage
		mov	cx, CODE_PAGE_JIS	; only have two formats
setCodePage:
		mov	ss:[dosCodePage], cx
endif
	;
	; Store the output file handle.
	;
		mov	ax, ds:[si].EF_outputFile
		mov	ss:[outputFile], ax
	;
	; Lock down the TextTransferBlockHeader and get the handle of
	; the first VM block of the HugeArray which contains the text.
	;
		mov	bx, ds:[si].EF_transferVMFile
		mov	ss:[vmFile], bx
		mov	ax, ds:[si].EF_transferVMChain.high
		mov	ss:[vmBlock], ax
		push	bp			; save bp to access locals
		call	VMLock
		mov	es, ax
		mov	di, es:[TTBH_text].high
		call	VMUnlock
		pop	bp			; restore bp

		mov	ss:[textArray], di	; textArray <-
						; 	1st vm block handle
	;
	; Get the amount of text we need to export.
	;
		call	HugeArrayGetCount

		tstdw	dxax
		jz	done			; done if array empty
		movdw	ss:[charsLeft], dxax
	;
	; Allocate a buffer to read into.
	;
if DBCS_PCGEOS
		mov	ax, DBCS_OUTPUT_BUFF_SIZE
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	error2
		mov	ss:[handleJISbuffer], bx
		mov	ss:[segJISbuffer], ax
endif
		mov	ax, READ_WRITE_BLOCK_SIZE
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	error
		mov	es, ax			; es <- buffer segment
	;
	; Export the text to the output file.
	;
		call	DoExport
	;
	; Free the buffer.
	;
		call	MemFree
DBCS <		mov	bx, ss:[handleJISbuffer]
DBCS <		call	MemFree						>
done:
		.leave
		ret

EC < badFormatNumber:							>
EC <		mov	ax, TE_INVALID_FORMAT				>
EC <		jmp	done						>

error:
DBCS <		mov	bx, ss:[handleJISbuffer]			>
DBCS <		call	MemFree						>
DBCS < error2:								>
		mov	ax, TE_OUT_OF_MEMORY
		jmp	done

TransExport		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text from the HugeArray VM chain and export it.

CALLED BY:	TransExport
PASS:		es:0	- buffer
RETURN:		ax	- TransError (0 = no error)
DESTROYED:	cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Loop:

	Read text from the HugeArray into the buffer.
	Update dx:ax to be the position of the next element in the
	 HugeArray.
	Update the amount of text left to be read.
	Convert the buffer to DOS and write it to the output file.
	Loop if there's more text to be read.	

NOTES/COMMENTS:
	* The Text huge array is addressed in char/wchar units.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jenny	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Changed DBCS MAX_CHUNK_FROM_HA_LENGTH from /5 to /2 to fully 
; utilize buffers.  The number of chars obtained from the Huge Array 
; could double if all are Carriage Returns, becuase of the appending 
; of Line Feeds to each CR.  The max that this could expand to in the 
; output buffer is 2.5 * # of bytes when exporting to JIS:
;
;			source:   DB CR   (4 bytes)
;			dest  :   ESC $ B DB ESC ( J CR LF  (10 bytes)
;
; grisco 04/18/94

DBCS < MAX_CHUNK_FROM_HA_LENGTH  equ	(READ_WRITE_BLOCK_SIZE/2)/(size wchar) >
SBCS < MAX_CHUNK_FROM_HA_LENGTH  equ	READ_WRITE_BLOCK_SIZE/2		       >

DoExport	proc	near	uses	bx, ds, si

		.enter	inherit	TransExport

		clrdw	dxax			; start at the beginning
exportLoop:
	;
	; Read text from the HugeArray into the buffer.
	;
		pushdw	dxax			; save position
		mov	di, ss:[textArray]
		mov	bx, ss:[vmFile]
		call	HugeArrayLock		; ds:si <- ptr to text
						; ax <- # valid chars 
		mov	cx, ax
		cmp	cx, MAX_CHUNK_FROM_HA_LENGTH
		jbe	gotSize
		mov	cx, MAX_CHUNK_FROM_HA_LENGTH
gotSize:
		push	cx			; Save count
		clr	di
		LocalCopyNString		; Copy the data
		pop	cx			; Restore count

		call	HugeArrayUnlock		; Release the text
	;
	; Update dx:ax to be the position of the next element in the
	; HugeArray.
	;
		popdw	dxax			; restore position
		add	ax, cx
		adc	dx, 0
	;
	; Update the amount of text left to be read.
	;  (Change CX here since 'shl' alters flags.)
	;
		sub	ss:[charsLeft].low, cx
		sbb	ss:[charsLeft].high, 0
DBCS <		shl	cx, 1			; cx <- text size	>
		tstdw	ss:[charsLeft]
		clc
		jnz	gotFlag
		stc				; this block is last one.
gotFlag:
		pushf				; so can check later
						;  whether charsLeft is 0
	;
	; Convert the buffer to DOS and write it to the output file.
	;
		pushdw	dxax
DBCS <		mov	dx, ss:[segJISbuffer]	; pass extra buffer	>
DBCS <		mov	di, ss:[dosCodePage]	; how to xlate		>
DBCS <		call	ConvertDBCSBufferToJIS	; ds:dx <- buffer	>
DBCS < 		mov	ss:[dosCodePage], di	; new? DosCodePage	>
SBCS <		call	ConvertBufferToDos	; ds:dx <- buffer	>
DBCS < EC <	cmp	cx, DBCS_OUTPUT_BUFF_SIZE	; overrun?   >  >
DBCS < EC <	ERROR_A  0				; CRASH!     >  >
		clr	ax			; allow errors
		mov	bx, ss:[outputFile]
		call	FileWrite
		popdw	dxax			; retrieve offset of next read
		jc	error
	;
	; Loop if there's more text to be read.
	;
		popf
		jnz	exportLoop
		clr	ax			; ax <- TE_NO_ERROR
done:
		.leave
		ret
error:
		popf				; clear stack
		mov	ax, TE_FILE_WRITE
		jmp	done

DoExport	endp


if not DBCS_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertBufferToDos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a buffer from GEOS to DOS

CALLED BY:	DoExport
PASS:		es:0	- buffer
		cx	- size
		carry	- set if this is the last block

RETURN:		ds:dx	- buffer
		cx	- new size
DESTROYED:	flags, ax, si, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Let Kernel convert buffer first.
		Copy text to upper half of buffer
		Copy text to lower half of buffer, skipping all graphicals
			changing 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jenny	10/23/92	Initial version (cribbed from Tony's TEdit)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertBufferToDos	proc	near

		pushf				; save the carry
	;
	; convert to the GEOS character set, replacing all unknown characters
	; with '_' (this should never happen)
	;
		segmov	ds, es
		clr	si
		mov	ax, '_'			; replacement character
		call	LocalGeosToDos

	;
	; move the data to the end of the block
	;
		push	cx
		mov	di, READ_WRITE_BLOCK_SIZE/2	; es:di <- dest ptr
		rep	movsb
		pop	cx

		mov	si, READ_WRITE_BLOCK_SIZE/2	; source
		clr	di			; dest

fooLoop:
		lodsb				; get byte
		cmp	al, C_GRAPHIC		; don't export
						;  graphics chars
		jz	skip
		cmp	al, C_CR		; see if <LF>
		jnz	store			; add linefeeds
		stosb
		mov	al, C_LF
store:
		stosb				; else store byte
skip:
		loop	fooLoop			; loop while more bytes

	;
	; if this is the last block make sure that it ends in a CR-LF
	;
		popf
		jnc	done
		dec	di			; won't export the EOF
		cmp	{char} es:[di-1], C_LF
		jz	done
		mov	al, C_CR
		stosb
		mov	al, C_LF
		stosb
done:
		clr	dx			; ds:dx <- buffer
		mov	cx, di			; return new size
		ret

ConvertBufferToDos	endp
endif


if DBCS_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertDBCSBufferToJIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a buffer from DBCS GEOS to JIS DOS/J

CALLED BY:	DoExport
PASS:		es:0	- buffer
		dx:0	- output buffer (size<=READ_WRITE_BLOCK_SIZE/2/2*5)
		cx	- size (at most READ_WRITE_BLOCK_SIZE/2)
		di	- DosCodePage for char set translation
		carry	- set if this is the last block

RETURN:		ds:dx	- buffer (ds RETURN == dx PASS)
		cx	- new size
DESTROYED:	flags, ax, si, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Convert all Geos NewLines (C_CR) to CR+LF;
			remove graphical inserts.
		Let Kernel convert buffer.

COMMENTS/NOTES:
		* We perform local conversion first because all Unicode chars
		  are the same size.  JIS has character set mode shiftings and
		  variable length chars.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	3/11/94    	Initial version (cribbed from above code)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertDBCSBufferToJIS	proc	near
		uses	bx
		.enter

		pushf				; save the carry
		push	di			; save DosCodePage

	; Convert CR to CR+LF, remove graphical inserts.
	; Conversion done tail first, as the the string can grow.
	;
		segmov	ds, es, si		; ds:si <- src
		mov	si, cx
		LocalPrevChar	dssi		; offset now 0 base.
		mov	di, READ_WRITE_BLOCK_SIZE-(size wchar)	; es:di <- dest

		shr	cx, 1			; cx <- string length (src cntr)
		clr	bx			; bx - converted char counter
		std				; direction <- tail first
localConvertLoop:
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, C_GRAPHIC
		je	convertSkip
		LocalCmpChar	ax, C_CR
		jne	convertStore		; store ordinary chars.

		LocalLoadChar	ax, C_LF	; LF after CR
		LocalPutChar	esdi, ax	;  (stored backwards, remember?)
		inc	bx			; count CR
		LocalLoadChar	ax, C_CR
convertStore:
		LocalPutChar	esdi, ax
		inc	bx
convertSkip:
		loop	localConvertLoop
		cld
		LocalNextChar	esdi		; undo the last LocalPutChar

	; bx - converted string size
	; dx - segment of final destination (return) buffer
	; es:di - start of locally converted string
	; ds==es

	; convert to SJIS character set, replacing all unknown characters
	; with '_'.
	;
		mov	si, di			; ds:si <- Unicode ptr (src)
		mov	es, dx			; es:di <- SJIS buffer (dest)
		clr	di
		mov	cx, bx			; cx <- converted string length
		mov	ax, '_'			; replacement character

		pop	bx			; bx <- DosCodePage
		clr	dx			; dx <- disk handle
		call	LocalGeosToDos		; cx <- text size

	;
	; if this is the last block make sure that it ends in a CR-LF
	;
		popf
		jnc	done

		dec	cx			; won't export the SBCS EOF
		mov	di, cx			; es:di <- ptr last char
		cmp	{char} es:[di-(size char)], C_LF
		je	done

		mov	ax, (C_LF shl 8) or C_CR
		stosw				; two more SBCS chars..
		add	cx, 2*(size char)	; cx <- new text size
done:
		push	ds			; original U+ buffer
		segmov	ds, es, dx		; ds:dx <- buffer
		clr	dx
		pop	es			; return as passed
		mov	di, bx			; new?  DosCodePage

		.leave
		ret

ConvertDBCSBufferToJIS	endp
endif

ExportCode	ends
