COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		exportCommon.asm

AUTHOR:		Maryann Simmons, Jun  8, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB GraphicsExportCommon	perform export of a GString into PCX file
				format

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	6/ 8/92		Initial revision

DESCRIPTION:
	 This file contains the common export routine for the Graphics Bitmap
	translation libraries.  	
		

	$Id: exportCommon.asm,v 1.1 97/04/07 11:28:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportCode	segment  resource

;--------------------------------------------------------------------------------
;	Constants and structures
;--------------------------------------------------------------------------------

ExportCommonInfo	struct
	ECI_DibFilename	char  FILE_LONGNAME_BUFFER_SIZE dup(?)
	ECI_DibStream	fptr
	ECI_DibFile	hptr
	ECI_destStream  fptr
	ECI_metaInfo	ExportMetaInfo
ExportCommonInfo	ends

ModeFlagsR	char	'r',0
ModeFlagsW	char	'w+',0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GraphicsExportCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform export of a GString into PCX file format

CALLED BY:	GLOBAL

PASS:		ds:si	- ExportFrame		
		bx	- segment of translation library export routine to call
		ax	- offset  of translation library export routine to call
		cx	- number of bytes required for export options

RETURN:		ax	- TransError error code, zero if no error
		bx 	- handle to error string,if ax = TE_CUSTOM
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		*create a temp file to hold the DIB intermediate format

		*lock the EF_exportOptions block and extract the Bit Count
		  Also push any additional format options for the C call

		*convert the Gstring passed in the VM Chain into the DIB
		 metafile format by calling the DIB translation Library

		*P the semaphore around the  translation library call
		 to provide sole access to globals
							 		
		*call Export* to export the resulting DIB File into a 
		 specified format  

		*release the semaphore

		*delete the temporary file

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		* Initially, the DIB filehandle is converted into a stream
		 pointer and pushed onto the stack with the rest of the arguments
		 for the impending C export call. The DIB FileHandle is then
		 passed to the Impex routine which will call the DIB library
		 export routine. The DIB Library will then open and later close
		 a stream for the DIB. It must do this because Impex deals only 
		 in PCGEOS FileHandles, not streams.

		 **The two streams exist simultaneously, but, this will work
		 because the second one is closed before the first is ever
		 accessed.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsExportCommon	proc	far
	uses	cx,dx,si,di,bp,ds,es
	locals	local	ExportCommonInfo
	.enter

	mov	di, ds:[si].EF_clipboardFormat
	mov	locals.ECI_metaInfo.EMI_clipboardFormat, di

	mov	di, ds:[si].EF_manufacturerID
	mov	locals.ECI_metaInfo.EMI_manufacturerID, di

	push	bp			; save to access locals
	push	bx,ax			;segment offset of routine
	push	bp			; save to access locals

	;open a tempFile to hold the DIB format
	;
	lea	di,locals.ECI_DibFilename
	segmov	es,ss			;this routine expects es:di buffer
	mov	ax,IMPEX_TEMP_NATIVE_FILE
	call	ImpexCreateTempFile 	;es:di = file name,bp=file handle
	mov	bx,bp
	pop	bp
	tst	ax			;ax = error if not clear
	jnz	errorCreateTemp		;bx = error string if ax = TE_CUSTOM

	mov	locals.ECI_DibFile,bx
	pop	bx,ax
	mov	di,cx

	mov	dx,(offset ModeFlagsR)
	ConvertFileHandleToStream locals.ECI_DibFile, dx 
	movdw	locals.ECI_DibStream,dxcx; DIB stream
	push	dx,cx			; destination = outputFile
	mov	dx, (offset ModeFlagsW)
	ConvertFileHandleToStream ds:[si].EF_outputFile, dx
	movdw	locals.ECI_destStream,dxcx
	push	dx,cx

	sub	sp,di			;set up stack pointer
	mov	cx,bp			;save locals
	mov	bp,sp			;ss:[bp] points to where to put options
	push	di			;save numbytes  

	mov	di,ds:[si].EF_transferVMFile
	mov	dx,ds:[si].EF_transferVMChain.high

	call	GraphicsGetExportOptions;returns si = bitcount
	mov	bp,cx			;restore locals
	pop	cx			;get num bytes pushed in case of error
	jc	errorExportOptions	;couldnt get options

	push	bx			;routine segment and offset
	push	ax
	push	cx			;save num bytes pushed
	clr	cx			;dx:cx = VMChain

	segmov	ds,ss			; ds:si points to ExportMetaInfo Struct
	mov	locals.ECI_metaInfo.EMI_bitCount, si
	lea	si,locals.ECI_metaInfo
;call DIB library to export,calling Impex routine
	mov	bp,locals.ECI_DibFile
 	mov	bx,handle dib		;bx:handle of DIB translation library
	mov	ax,EXPORT_CONVERT_TO_DIB_METAFILE
	call	ImpexExportToMetafile	;Export DIB file to specified format
	tst	ax			;clear if no error,else TransError
	pop	cx			;numbytes pushed
	jnz	errorDIBFile
;call Export routine to export DIB file
	call	TransLibraryThreadPSem	;make sure have sole access to globals

	mov	dx,segment dgroup	;fixup ds for C call
	mov	ds,dx

	mov	ax, FP_DEFAULT_STACK_ELEMENTS	;num stack elements
	mov	bl,FLOAT_STACK_GROW
	call	FloatInit
	call	PROCCALLFIXEDORMOVABLE_PASCAL
	call	FloatExit		;this will call the  export routine 

	call	TransLibraryThreadVSem	;free the semaphore

deleteDIBFile:				;clean up
	pop	bp
	push	ax,bx			;save TransError code

	mov	bx,locals.ECI_DibFile	;get DIB file handle
	lea	dx,locals.ECI_DibFilename	;file buffer
	mov	ax,IMPEX_TEMP_NATIVE_FILE
	segmov	ds,ss			;file buffer is a local
	call	ImpexDeleteTempFile	;delete the DIB file

	pushdw	locals.ECI_DibStream
	call	FDCLOSE
	pushdw	locals.ECI_destStream
	call	FDCLOSE
	pop	ax,bx			;restore TransError code
done:
	.leave
	ret

errorCreateTemp:			;couldn't create temp file
	add	sp,6
	jmp	done

errorDIBFile:
	add	sp,12			;fixup	sp
	add	sp,cx
	jmp	deleteDIBFile
errorExportOptions:
	add	sp,8			;fixup sp
	add	sp,cx
	mov	ax,TE_EXPORT_ERROR
	jmp	deleteDIBFile
	
GraphicsExportCommon	endp


ExportCode	ends


