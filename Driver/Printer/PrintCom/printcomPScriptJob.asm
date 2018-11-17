
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Printer Driver
FILE:		printcomPScriptJob.asm

AUTHOR:		Jim DeFrisco, 25 Feb 1991

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job
	PrintEndJob		Cleanup done at end of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/91		Initial revision
	Dave	4/93		Parsed up to conform to general print driver
				architecture
	Falk	2015		Added new host PS to PDF printer

DESCRIPTION:
	This file contains various job setup routines.
		

	$Id: printcomPScriptJob.asm,v 1.1 97/04/18 11:51:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DBCS_PCGEOS
NEC <epsFileName	wchar	"eps.geo",0	>
EC  <epsFileName	wchar	"epsec.geo",0	>
else
NEC <epsFileName	char	"eps.geo",0	>
EC  <epsFileName	char	"epsec.geo",0	>
endif

include Job/jobPaperInfo.asm    ; getprintarea
include Job/jobPaperPathNoASFControl.asm
include Job/jobStartPScript.asm
include Job/jobEndPScript.asm
include Job/Custom/customLJ4PScript.asm
include Job/Custom/customIBM4019PScript.asm
include Job/Custom/customHostIntegration.asm	
									; fr - ps 2 pdf code and host call


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendToProlog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the printer-specific prolog

CALLED BY:	INTERNAL
		PrintStartJob

PASS:		bp	- pstate segment
		di	- file handle to write to

RETURN:		carry	- set if some error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		get a pointer into the device info table, and write out
		some additional prolog, if needed.

		additionally, check for a file called "pscript.pat" in the
		system directory and copy it at this time as well.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AppendToProlog	proc	near
		uses	ax, si, di, bx, ds
		.enter
		
		; lock down the device info resource

		mov	ds, bp			; ds -> locked PState
		mov	bx, ds:[PS_deviceInfo]	; get handle to info
		push	bx
		call	MemLock
		mov	ds, ax			; ds -> device info
		mov	bx, ds:[PI_hiRes]	; font and level info after
						;  hi res graphics struct
		add	bx, size GraphicsProperties ; ds:bx -> PSInfoStruct

		; ds:bx -> PostScript info

		mov	cx, ds:[bx].PSIS_plen	; get length of prolog
		clc				; just in case there is none
		jcxz	doneProlog		;  nothing to write

		; call eps library to append info to the file or port

		mov	si, ds:[bx].PSIS_prolog	; ds:si -> pointer to text
						; di = file handle
						; cx = # of bytes to write
		mov	ax, TR_EXPORT_RAW
		mov	es, bp
		mov	bx, es:[PS_epsLibrary]	; get library handle
		call	CallEPSLibrary		; write out the header

		; finished with whatever prolog there was.  Unlock the block
doneProlog:
		pop	bx
		call	MemUnlock		; release the device resource
		jc	done

		; check to see if there is a patch file on disk.  Change to
		; the SYSTEM directory (for 1.2 -- this should probably change
		; to be the printer driver directory for 2.0) and check for 
		; the file.  If it is there, copy it over.

		call	FilePushDir		; save current directory
		mov	ax, SP_SYSTEM		; go to standard directory
;		mov	ax, SP_PRINTER_DRIVERS 	; use this for 2.0
		call	FileSetStandardPath	; go there
		segmov	ds, cs, dx
		mov	dx, offset cs:patchfile	; ds:dx -> file name
		mov	al, FILE_ACCESS_R or FILE_DENY_NONE
		call	FileOpen		; if fails open, assume absent
		cmc				; want clear if no patch file
		jnc	noPatchFile		; finished with this
		mov	si, ax			; si = source handle
		mov	bx, ax			; get file size
		call	FileSize		; ax=file size

		; it should be very small (less than a few K), so allocate
		; a block to read into.

		push	ax			; save file size
		mov	cx, ALLOC_DYNAMIC_LOCK	; lock the file
		call	MemAlloc		; alloc the block
		pop	cx			; restore file size
		push	bx			; save handle
		mov	ds, ax			; ds -> block
		clr	dx			; read file into ds:dx
		mov	bx, si			; get source file handle
		mov	al, FILE_NO_ERRORS	; shouldn't be any trouble here
		call	FileRead
		mov	bx, di			; set up destination file
		clr	al			; handle errors
		call	FileWrite
		pop	bx			; nuke the block we allocated
		pushf				; save flags
		call	MemFree
		mov	bx, si			; close source file
		mov	al, FILE_NO_ERRORS	; should be OK for source file
		call	FileClose
		popf				; restore carry status

		; have file.  copy it. ax = source file handle

noPatchFile:
		pushf				; save carry status
		call	FilePopDir		; restore directory
		popf
done:
		.leave
		ret

AppendToProlog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreatePostScriptBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a memory block to store port information

CALLED BY:	
PASS:		bp	- sptr to locked PState
		es	- ptr to locked options block
		ds:si	- ptr to JobParameters block

RETURN: 	ax	- memory handle of EPSExportLowStreamStruct

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	12/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef PRINT_TO_FILE
fileName	char	"myfile",0
endif

CreatePostScriptBlock	proc	near
		uses	bx,cx,ds
	.enter
	push	es
ifdef PRINT_TO_FILE
		push	cx, dx, ds
		mov	dx, SEGMENT_CS
		mov	ds, dx
		mov	dx, offset fileName
		mov	ah, mask FCF_NATIVE or FILE_CREATE_TRUNCATE  
		mov	al, FILE_ACCESS_RW or FILE_DENY_RW 
		clr	cx
		call	FileCreate
		ERROR_C	-1
		pop	cx, dx, ds
else
	mov	ax, size EPSExportLowStreamStruct
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	ds, ax			; ds - address of locked block
	mov	es, bp
	mov	ax, es:[PS_streamToken]
	mov	ds:[ESPELSS_token], ax
	movdw	ds:[ESPELSS_strategy], es:[PS_streamStrategy], ax
	mov	ax, bx			; ax - returned value
	call	MemUnlock
endif
	pop	es
	mov	es:[GEO_hFile], ax	; save file handle

	.leave
	ret
CreatePostScriptBlock	endp

SBCS <	patchfile	char	"devpatch.ps", 0			>
DBCS <	patchfile	wchar	"devpatch.ps", 0			>
