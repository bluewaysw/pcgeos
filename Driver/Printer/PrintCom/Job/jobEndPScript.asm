
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Printer Driver
FILE:		jobEndPScript.asm

AUTHOR:		Jim DeFrisco, 25 Feb 1991

ROUTINES:
	Name			Description
	----			-----------
	PrintEndJob		Cleanup done at end of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/91		Initial revision
	Dave	4/93		Parsed from pscriptSetup.asm


DESCRIPTION:
		

	$Id: jobEndPScript.asm,v 1.1 97/04/18 11:51:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do post-job cleanup

CALLED BY:	GLOBAL

PASS:		bp	- segment of locked PState
		
RETURN:		carry	- set if some error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out the trailer;
		send the file to the printer;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintEndJob	proc	far
		uses	ax,bx,cx,dx,ds,si,di,es
		.enter
		
		mov	es, bp			; ds -> PState
		tst	es:[PS_epsLibrary]	; if library not loaded...
		jz	cleanUp			; ...clean up and get out
		mov	dx, es:[PS_expansionInfo] ; get block handle
		mov	bx, dx
		call	MemLock
		mov	ds, ax
		mov	di, ds:[GEO_hFile]	; get options block handle
		call	MemUnlock
		mov	ax, TR_EXPORT_TRAILER
		mov	bx, es:[PS_epsLibrary]
		call	CallEPSLibrary

		; free the Mem block that has stream port and strategy
ifdef PRINT_TO_FILE
		Mov	bx, di
		mov	ax, FILE_NO_ERRORS
		call	FileClose
else		
		mov	bx, di			; set up file handle in bx
		call	MemFree
endif
		mov	bx, es:[PS_expansionInfo] ; free options block
		call	MemFree

		; the last thing we need to do is release the EPS library

		mov	bx, es:[PS_epsLibrary]
		call	GeodeFreeDriver

		; Actually the LAST thing is to do any custom mop up.
cleanUp:
	        mov     bx,es:PS_deviceInfo     ;get the device specific info.
       		call    MemLock
       		mov     ds,ax                   ;segment into ds.
       		mov     ax,ds:PI_customExit     ;get address of custom routine.
       		call    MemUnlock

                ; see if we are going to the file, if so, no custom exit.
                cmp     es:[PS_jobParams].[JP_portInfo].[PPI_type],PPT_FILE
                je      useStandard

        	test    ax,ax                   ;see if a custom routine exists.
        	je      useStandard             ;if not, to use standard exit.
        	jmp     ax                      ;else jmp to the custom routine.
                                        ;(It had better jump back here to
                                        ;somwhere in this routine or else
                                        ;things will get ugly on return).

useStandard:
        	; clear out any styles left over

        	call    PrintClearStyles
        	clc                     ; no problems
EndExit         label   near

		.leave
		ret
PrintEndJob	endp

