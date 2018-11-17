COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		importCommon.asm

AUTHOR:		Maryann Simmons, Jun  8, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT GraphicsImportCommon	perform import of a Pcx graphics file into
				a GString

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	6/ 8/92		Initial revision

DESCRIPTION:
	This file contains the common import routine for the Graphics
	Bitmap translation Libraries	
	
	$Id: importCommon.asm,v 1.1 97/04/07 11:28:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GraphicsImportCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform import of a Pcx graphics file into a GString

CALLED BY:	Translation Library

PASS:		ds:si  	- ImportFrame
		bx	- segment of translation library routine to call
		ax	- offset  of translation library routine to call

RETURN:		ax	- TransError error code( clear if no error)
		bx	- handle to block with error string if ax=TE_CUSTOM
		si	- Manufacturer ID
		dx:cx	- VMChain(cx = 0) containing transfer format

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		* create a temporary file to hold the DIB intermediate format
		
		* P the semaphore around the Pcx translation Library calls
		  in order to ensure sole access to the globals in the C code

		* Push any required  ImportOptions for the C call

		* Import the specified PCX File into the DIB format

		* V to release the semaphore

		* rewind the DIB file so the file pointer is at the beginning

		* convert the DIB file into a GString by calling the DIB 
		  translation library ImportDIB routine

		* delete the temporary file that holds the DIB format 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModeFlagsR	char 'r',0
ModeFlagsW	char 'w',0
	

GraphicsImportCommon	proc	far
	uses	di,bp,ds,es
	.enter

;First we import the file into the DIB "metafile" format
	sub	sp,FILE_LONGNAME_BUFFER_SIZE
	mov	di,sp			; will point to file buffer

	push	bx,ax			; save seg:offset of routine to call
	segmov	es,ss			; es:di => buffer to hold name 
	mov	ax,IMPEX_TEMP_NATIVE_FILE
	call	ImpexCreateTempFile	; es:di <= file buffer,bp<= file handle
	tst	ax			; ax will be clear if successful
	LONG jnz errorCreateTemp	; bx <= error String if ax = TE_CUSTOM

	call	TransLibraryThreadPSem  ; ensure sole access to globals
	pop	bx, ax			; routine to call
	push	bp			; DIB File Handle
;push arguments for Import => sourcefile,dibfile 
	mov	di,ds:[si].IF_transferVMFile
	mov	dx, (offset ModeFlagsR)
	ConvertFileHandleToStream ds:[si].IF_sourceFile,dx

	push	dx,cx			; PCX stream pointer(save to close)
	mov	ds,dx			; save PCX stream pointer in ds:si
	mov	si,cx			
	mov	dx, (offset ModeFlagsW)
	ConvertFileHandleToStream bp, dx
	push	dx,cx			; DIB stream pointer
	push	ds,si			; PCX stream pointer
	push	dx,cx			; DIB stream pointer
	call	GraphicsGetImportOptions; get any import options for the C call
	push	bx			; for ProcCallFixedOrMovable
	push	ax			; address of routine to call

	mov	ax, segment dgroup 	; fixup ds- must be dgroup for C call
	mov	ds,ax

	mov	ax, FP_DEFAULT_STACK_ELEMENTS
	mov	bl, FLOAT_STACK_GROW
	call	FloatInit
	call	PROCCALLFIXEDORMOVABLE_PASCAL ;may trash ax,bx,cx,dx
	call	FloatExit
	mov	si,ax			; save TransError
	call	FDCLOSE			; the stream for PCX file is on stack
	call	FDCLOSE			; the stream for DIB file is on stack

	call	TransLibraryThreadVSem	; release the semaphore
	mov	ax,si
	cmp	ax,TE_NO_ERROR		; check if the first half of the 
	jne	deleteDIBFile		; import was successful

	pop	bx
	push	bx			; save DIB Handle to delete
;Import from the DIB format to a GString
	mov	ax,IMPORT_CONVERT_TO_TRANSFER_ITEM 			
	mov	bp, handle dib		; bp is the handle of the xlat library
	call	ImpexImportFromMetafile ; dx:cx <= VM chain(invalid if there
					; was an error,ax = TransError Code
					; bx<=handle error text if ax=TE_CUSTOM
EC <	call	ECMemVerifyHeap
deleteDIBFile:
	pop	si			; DIB FileHandle
	mov	bp,sp			; points to file buffer
	push	ax,bx,cx,dx		; save returned values

	mov	bx, si
	segmov	ds,ss			; filename buffer is local
	mov	dx,bp			; ds:dx => file buffer
	mov	ax,IMPEX_TEMP_NATIVE_FILE
	call	ImpexDeleteTempFile

	pop	ax,bx,cx,dx		; get return values
done:
	add	sp,FILE_LONGNAME_BUFFER_SIZE
	mov	si, MANUFACTURER_ID_GEOWORKS
	.leave		
	ret
errorCreateTemp:			; couldn't create temp file
	add	sp,4			; restore stack pointer
	jmp	done

GraphicsImportCommon	endp


ImportCode	ends













