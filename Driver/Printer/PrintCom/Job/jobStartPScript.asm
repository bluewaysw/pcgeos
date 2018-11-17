
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Printer Driver
FILE:		jobStartPScript.asm

AUTHOR:		Jim DeFrisco, 25 Feb 1991

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/91		Initial revision
	Dave	4/93		Parsed out of pscriptSetup.asm


DESCRIPTION:
		

	$Id: jobStartPScript.asm,v 1.1 97/04/18 11:51:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do pre-job initialization

CALLED BY:	GLOBAL

PASS:		bp	- segment of locked PState
		
RETURN:		carry	- set if some communication problem or if file
			  creation error.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		create the PostScript output file (if one is not supplied);
		create default option block for translation library.
		set various options from the JobParameters block;
		write out the header;
		write out the pscript driver prolog;


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PrintStartJob	proc	far
		uses	ax, bx, cx, dx, si, di, es, ds
		.enter

		; Before we do anything, we need to load the EPS library.
		; Since it's a translation library, we can't load it 
		; implicitly.  Bummer.  
		; We'll have to save away a handle to it so that we can 
		; call functions there, so use the PS_bandHeight variable
		; in the PState, since it's unused for PostScript.  

		mov	es, bp			; es -> PState

		; init some stuff in the PState while we are here

		mov	bx, es:[PS_deviceInfo]	;get the device specific info.
		call	MemLock
		mov	ds, ax			;segment into ds.
		mov	al, ds:PI_type		;get the printer smarts field.
		mov	ah, ds:PI_smarts	;get the printer smarts field.
		mov 	{word} es:[PS_printerType],ax	;set both in PState.
	        mov     ax,ds:PI_customEntry    ;get address of custom routine.
		call	MemUnlock

		; see if we are going to the file, if so, no custom init.
		cmp	es:[PS_jobParams].[JP_portInfo].[PPI_type],PPT_FILE
		je	useStandard

        	test    ax,ax           ;see if a custom routine exists.
        	je      useStandard     ;if not, skip to use standard init.
        	jmp     ax              ;else jmp to the custom routine.
                                        ;(It had better jump back here to
                                        ;somwhere in this routine or else
                                        ;things will get ugly on return).

useStandard:
        	clc                             ;start off with no problems

BeginInit       label   near
        	LONG jc	done		;pass errors out.

		;load the paper path variables from the Job Parameters block

        	mov     ah,es:[PS_jobParams].[JP_printerData].[PUID_paperOutput]
        	mov     al,es:[PS_jobParams].[JP_printerData].[PUID_paperInput]
        	call    PrintSetPaperPath

		; initialize some other info in the PState

		clr	ax
		mov	es:[PS_cursorPos].P_x, ax	; set to 0,0 text
		mov	es:[PS_cursorPos].P_y, ax
		mov	es:[PS_epsLibrary], ax		; in case load fails
		mov	es:[PS_expansionInfo], ax	; in case load fails

		call	FilePushDir
		mov	ax, SP_IMPORT_EXPORT_DRIVERS
		call	FileSetStandardPath
		segmov	ds, cs, si
		mov	si, offset epsFileName
		clr	ax, bx			; protocol don't matter
		call	GeodeUseLibrary
		call	FilePopDir		; saves flags
EC <		ERROR_C	PSCRIPT_CANT_LOAD_EPS_LIBRARY			>
NEC <		LONG jc	transError					>
		mov	es:[PS_epsLibrary], bx	; save driver handle here

		; first get the default options for PostScript output, then
		; set the options as specified by the passed JobParameters
		; block

		push	es
		clr	dx			; get default option block
		mov	ax, TR_GET_EXPORT_OPTIONS
		call	CallEPSLibrary
		mov	es:[PS_expansionInfo], dx ; save block handle
		mov	bx, dx			; want to lock this
		call	MemLock	
		mov	es, ax			; es -> options block
		pop	ds			; ds -> JobParameters

		; not exporting to eps file

		andnf	es:[PSEO_flags], not mask PSEF_EPS_FILE

		; next, we create a memory block to store the stream 
		; port number and port strategy, so the eps library
		; can send the data directly to the port.

		mov	si, offset PS_jobParams	; ds:si -> JobParameters
		call	CreatePostScriptBlock

		; copy #pages, #copies, ...

		mov	ax, ds:[si].JP_numPages
		mov	es:[GEO_pages], ax	; save #pages
		mov	al, ds:[si].JP_numCopies
		clr	ah

		; if #copies is more than one, set it back to zero in the
		; JobParameters that we're passed, unless we're collating.

		cmp	ax, 1			; more than one copy ?
		jbe	copiesOK
		mov	ds:[si].JP_numCopies, 1	; assume not collated.
		test	ds:[si].JP_spoolOpts, mask SO_COLLATE ; collate output?
		jz	copiesOK		; all done, set #copies
		mov	ds:[si].JP_numCopies, al ; let spooler do it
		mov	ax, 1			; don't let PostScript do it
copiesOK:
		mov	es:[GEO_copies], ax	; save #copies
		movdw	dxax, ds:[si].JP_docSizeInfo.PSR_height
		movdw	es:[GEO_docH], dxax	; save doc height
		movdw	dxax, ds:[si].JP_docSizeInfo.PSR_width
		movdw	es:[GEO_docW], dxax	; save doc width
		test	ds:[si].JP_spoolOpts, mask SO_COLLATE ; collate output?
		jz	copyStrings
		or	es:[GEO_flags], mask GEF_COLLATE ; set collate option

		; copy some strings over..
copyStrings:
		push	si			; save offsets
		mov	di, offset GEO_appName	; copy parent app name
		add	si, offset JP_parent	
		mov	cx, length GEO_appName	; copy this many chars
		rep	movsb
		pop	si
		mov	di, offset GEO_docName	; copy parent app name
		add	si, offset JP_documentName	
		mov	cx, length GEO_docName	; copy this many chars
		rep	movsb

		; lock down the device info resource, and pull out the
		; character set type info so that the translation library
		; can know which set of fonts we should map to.

		push	bx, ds			; save registers
		mov	ds, bp			; ds -> locked PState
		mov	bx, ds:[PS_deviceInfo]	; get handle to info
		push	bx
		call	MemLock
		mov	ds, ax			; ds -> device info
		mov	bx, ds:[PI_hiRes]	; font and level info after
						;  hi res graphics struct
		add	bx, size GraphicsProperties ; ds:bx -> PSInfoStruct
		mov	ax, ds:[bx].PSIS_fonts	; get font info
		mov	es:[PSEO_fonts], ax	; save it
		mov	ax, ds:[bx].PSIS_level	; get font info
		mov	es:[PSEO_level], ax	; save for xlation lib
		pop	bx
		call	MemUnlock		; release the device resource
		pop	bx, ds			; restore regs

		mov	di, es:[GEO_hFile]	; this is where file handle is
		call	MemUnlock		; unlock the options block

		; now that we have all the options set up, write out the
		; standard PostScript header.

		mov	dx, bx			; setup opt blk handle for 
		mov	ax, TR_EXPORT_HEADER
		mov	ds, bp			; ds -> PState
		mov	bx, ds:[PS_epsLibrary]	; get library handle
		call	CallEPSLibrary		; write out the header
		tst	ax			; check for errors
		jnz	transError		; some error w/translation lib
		clc				; no problems

		; now that the standard header is out, write out our own
		; special functions.

		call	AppendToProlog
done:
		.leave
		ret

		; there was some error in the translation library.  ax holds
		; one of the TransError enum values.
transError:
		stc				;indicate error condition
		jmp	done

PrintStartJob	endp
