
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		customHostIntegration.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/93		Initial revision
	Falk	2015		it calls the PS 2 PDF lib that jh wrote to drop to DOS and
						use the ghost converter


DESCRIPTION:
		

	$Id: customHostIntegration.asm,v 1.1 97/04/18 11:50:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ps2pdf	segment library

global CONVERTTOPDF:far

ps2pdf	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEnterHostIntegration/PrintExitHostIntegration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do pre-job initialization

CALLED BY:	INTERNAL jumped to from PrintStartJob/PrintEndJob

PASS:		es	- segment of locked PState
		
RETURN:		carry	- set if some communication problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EC  < fileStreamDr	char	"filestre.geo",0 >
NEC < fileStreamDr	char	"filestr.geo",0  >


PrintEnterHostIntegration	proc	near

	; this setup is based on PPT_NOTHING (custom port)
	; we will create a temp file internally but will use
	; PPI_params.PP_file to hold the stream parameters

	;
	; Create temp file output stream to hold ps file going
	; to be converted to pdf in the end.
	;

		push	ds
		call	FilePushDir

	;
	; CD to the Waste Basket directory.
	;
		mov	ax, SP_SPOOL
		call	FileSetStandardPath

	;
	; Create the temp file
	;
		mov	ah, mask FCF_NATIVE
		mov	al, FILE_DENY_W or FILE_ACCESS_W
		mov	cx, FILE_ATTR_NORMAL
		
		segmov	ds, es, dx
		lea	dx, es:[PS_jobParams].[JP_portInfo].PPI_params.PP_file.FPP_path ; ds:dx = file path
						       ; buffer 

		mov {char}ds:[PS_jobParams].[JP_portInfo].PPI_params.PP_file.FPP_path, 0

		call	FileCreateTempFile	; ax = file handle
		jc	error
	;
	; The file path for the created file was stuffed into
	; CTLDA_destFilePath by FileCreateTempFile. We need to stuff the 
	; disk handle (StandardPath) into CTLDA_destDiskHandle.
	;
		mov	es:[PS_jobParams].[JP_portInfo].PPI_params.PP_file.FPP_file, ax		; save file handle

	;
	;	load stream driver for file
	;
		push	ds, si, ax
		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
 		segmov	ds, cs
		mov	si, offset fileStreamDr		; ds:si -> port driver
		clr ax, bx						; version doesn't matter
		call	GeodeUseDriver
 		call	FilePopDir
		pop	ds, si, ax
		jc	error

		mov	es:[PS_bufHan], bx

		call	GeodeInfoDriver		; get pointer to info block
		mov     bx, ds:[si].DIS_strategy.offset
		mov     si, ds:[si].DIS_strategy.segment
		mov	es:[PS_streamStrategy].offset, bx ; set up pointer
		mov	es:[PS_streamStrategy].segment, si 

	; resolve driver strategy routine

	; 
	; Temp ps file created successful, create output stream now
	;
		mov	bx, ax				; pass handle in bx
		mov	dx, 1024
		mov	di, DR_STREAM_OPEN
		mov	ax, mask SOF_NOBLOCK
		push	bp			; spare this register
		
		call	es:[PS_streamStrategy]	; open the port
		
		pop	bp			; restore frame pointer
		mov es:[PS_jobParams].[JP_portInfo].PPI_params.PP_file.FPP_unit, bx
		mov es:[PS_streamToken], bx
									; save unit number for later
		jc	error


		call	FilePopDir			; flags preserved
		pop	ds

		jmp	BeginInit

error:
		call	FilePopDir			; flags preserved
		pop	ds


		jmp	BeginInit

PrintEnterHostIntegration	endp

PrintExitHostIntegration    proc    near

	; close the stream (commits final writes)

		mov bx, es:[PS_jobParams].[JP_portInfo].PPI_params.PP_file.FPP_unit
		mov	di, DR_STREAM_CLOSE
		mov	ax, STREAM_LINGER
		push	bp
		call	es:[PS_streamStrategy]	; open the port
		pop	bp

	; close the file

		mov	al, FILE_NO_ERRORS	; can't pass 'em back anyway
		mov	bx, es:[PS_jobParams].[JP_portInfo].PPI_params.PP_file.FPP_file
		call	FileClose

	; convert to pdf
		
		lea	dx, es:[PS_jobParams].[JP_portInfo].PPI_params.PP_file.FPP_path
						       ; buffer 
		push	es
		push	dx
		
		call	CONVERTTOPDF

	; trigger host side print of the pdf
		

	; delete temp file

	; delete pdf file

	; unload stream driver


        jmp     EndExit
PrintExitHostIntegration    endp
