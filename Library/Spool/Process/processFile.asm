COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler
FILE:		processFile.asm

AUTHOR:		Don Reeves, April 29, 1991

ROUTINES:
	Name			Description
	----			-----------
	InitFilePort		do init for port
	ExitFilePort		do exit for port
	ErrorFilePort		do error handling for port
	FileErrorHandler	receive error from port driver
	VerifyFilePort		verify that the port accessible
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/26/90		Initial revision
	Don	4/29/91		Copied code from parallel

DESCRIPTION:
	This file contains the routines to initialize and close the file
	"port".
		

	$Id: processFile.asm,v 1.1 97/04/07 11:11:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFilePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the port and do special serial port initialization

CALLED BY:	INTERNAL
		InitPrinterPort

PASS:		curJob	- inherited stack frame

RETURN:		carry	= set if problem opening port
				ax = error type (PortErrors enum)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitFilePort proc	near
		uses	bx, di, cx, dx, ds, si
curJob		local	SpoolJobInfo
		.enter	inherit

		; copy the port address over to idata

		mov	ax, dgroup
		mov	ds, ax
		mov	ax, curJob.SJI_stream.offset	; move offset 
		mov	ds:[fileStrategy].offset, ax
		mov	ax, curJob.SJI_stream.segment	; move offset 
		mov	ds:[fileStrategy].segment, ax

		; open the file.  This involves creating the output file,
		; then calling the filestr driver to open it as a stream.

		push	ds
		call	FilePushDir
		segmov	ds, ss
		lea	dx, fileParams.FPP_path
		mov	bx, fileParams.FPP_diskHandle
		call	FileSetCurrentPath
		lea	dx, fileParams.FPP_fileName	; ds:dx -> filename
		mov	ah, FileCreateFlags <1,0,0,FILE_CREATE_TRUNCATE>
		mov	al, FileAccessFlags <FE_NONE,FA_WRITE_ONLY>
		clr	cx				; no FileAttrs 
		call	FileCreate			; 
		call	FilePopDir			; flags preserved
		pop	ds
		mov	fileParams.FPP_file, ax		; save file handle
		pushf
		push	ds, ax
		mov	dx, ax
		mov	bx, curJob.SJI_pstate
		call	MemLock				; point at PStat
		mov	ds, ax				; ds -> PState
		mov	ds:[PS_jobParams].JP_portInfo.PPI_params.PP_file.FPP_file, dx
		call	MemUnlock
		pop	ds, ax
		popf
		jc	fileError			;  oops, no go

		mov	bx, ax				; pass handle in bx
		mov	dx, SPOOL_FILE_BUFFER_SIZE
		mov	di, DR_STREAM_OPEN
		mov	ax, mask SOF_NOBLOCK
		push	bp			; spare this register
		call	curJob.SJI_stream	; open the port
		pop	bp			; restore frame pointer
		mov	fileParams.FPP_unit, bx	; save unit number for later
		jnc	filePortOK

		; some error in opening file.  Report it.
fileError:
		mov	cx, SERROR_CANNOT_OPEN_FILE
		mov	dx, curJob.SJI_qHan
		call	SpoolErrorBox		; signal problem

		mov	ax, PE_PORT_NOT_OPENED	; otherwise signal error type
		stc
		jmp	done

		; the port opened ok, so let's set up some error conditions
filePortOK:
		push	bp			; save frame pointer
		mov	di, DR_STREAM_SET_NOTIFY
		mov	ax, StreamNotifyType <0, SNE_ERROR, SNM_ROUTINE>
		mov	bx, fileParams.FPP_unit
		mov	cx, dgroup
		mov	dx, offset dgroup:StreamErrorHandler
		mov	bp, curJob.SJI_qHan	; value to pass in ax
		call	ds:[fileStrategy]	; call to driver
		pop	bp

		; now set the connection info for the printer driver

		mov	di, DR_PRINT_SET_STREAM
		mov	cx, fileParams.FPP_unit
		mov	si, curJob.SJI_info.JP_portInfo.PPI_type
		mov	dx, curJob.SJI_sHan	; pass stream handle
		mov	bx, curJob.SJI_pstate
		call	curJob.SJI_pDriver
		clc				; signal no problem
done:
		.leave
		ret
InitFilePort endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitFilePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the port 

CALLED BY:	INTERNAL
		ExitPrinterPort

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExitFilePort	proc	near
		uses	ax, bx, di
curJob		local	SpoolJobInfo
		.enter	inherit

		; close the stream (commits final writes)

		mov	bx, fileParams.FPP_unit
		mov	di, DR_STREAM_CLOSE
		mov	ax, STREAM_LINGER
		push	bp
		call	curJob.SJI_stream	; close the port
		pop	bp

		; close the file

		mov	al, FILE_NO_ERRORS	; can't pass 'em back anyway
		mov	bx, fileParams.FPP_file	; pass file handle
		call	FileClose

		.leave
		ret

ExitFilePort endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyFilePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the existance and operation of the port

CALLED BY:	INTERNAL
		SpoolVerifyPrinterPort

PASS:		portStrategy	- inherited local variable

RETURN:		carry		- SET if there is some problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		For now, do nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VerifyFilePort proc	near
portStrategy	local	fptr
		.enter	inherit

		; There is nothing to do. Just return carry clear
		;
		clc

		.leave
		ret
VerifyFilePort endp

PrintInit	ends



PrintError	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ErrorFilePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle parallel port errors

CALLED BY:	parallel driver, via PortDriverErrorHandler in idata

PASS:		ds	- segment of locked queue segment
		*ds:si	- pointer to queue that is affected
		dx	- error word (FileError)

RETURN:		carry	- set if print job should abort
		ds	- still points at PrintQueue (may have changed)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ErrorFilePort	proc	near
		uses	ax, bx, cx, di, es
		.enter	

		
		; flush the remaining data so filestr doesn't try to
		; write it when ExitFilePort closes the thing

		mov	di, ds:[si]
		les	di, ds:[di].QI_threadInfo
		
		mov	bx, es:[di].SJI_info.JP_portInfo.PPI_params.PP_file.FPP_unit
		push	si
		mov	si, di
		mov	ax, STREAM_DISCARD		; flush the data
		mov	di, DR_STREAM_CLOSE
		call	es:[si].SJI_stream		; signal the driver

		mov	cx, PERROR_FILE_SYSTEM_FULL
		cmp	dx, ERROR_SHORT_READ_WRITE
		je	haveError
		mov	cx, PERROR_FILE_SYSTEM_ERROR
haveError:
		pop	dx			; dx <- queue handle
		call	UnlockQueue
		call	SpoolErrorBox
		call	LockQueue

		stc					; set error flag
		.leave
		ret
ErrorFilePort	endp

PrintError	ends
