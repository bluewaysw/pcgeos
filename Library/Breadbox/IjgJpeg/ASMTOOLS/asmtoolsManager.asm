COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        Copyright (c) GlobalPC 1999 -- All Rights Reserved

PROJECT:        IJGJPEG library
FILE:           asmtoolsManager.asm

AUTHOR:         Brian Chin, Nov 17, 1999

ROUTINES:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        brianc  11/17/99        Initial revision

DESCRIPTION:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;============================================================================
;       INCLUDES
;============================================================================

include stdapp.def
include product.def
include Internal/heapInt.def

                SetGeosConvention

global _jmp_to_error_handler:far

ErrorHandlerContext	struct
	EHC_ss	word
	EHC_ds	word
	EHC_es	word
	EHC_di	word
	EHC_si	word
	EHC_cs	word
	EHC_ip	word
	EHC_sp	word
	EHC_bp	word
	EHC_stackBot	word
ErrorHandlerContext	ends

RCI_infoFrame	struct
    RCIIF_retAddr	fptr.far
    RCIIF_handle	hptr
    RCIIF_checkSum	word
RCI_infoFrame	ends

; This constant is stored in RCIIF_checkSum by a non-error-checking kernel.
RCIIF_CHECKSUM_CONSTANT	equ	0adebh

FOMFrame	struct
    FOMF_retf	fptr.far
    FOMF_spAdj	word
FOMFrame	ends

idata segment

	SetDefaultConvention

_jmp_to_error_handler	proc far	errorContext:word
		uses	es
		.enter
		mov	bx, errorContext
		tst	bx
	LONG	jz	done
		call	MemLock
		tst	ax
		jz	done
		mov	es, ax
		mov	ax, ss
		cmp	ax, es:[EHC_ss]
		jne	unlockDone	; wrong stack
		cmp	sp, es:[EHC_sp]
		jae	unlockDone	; call stack gone
	;
	; unwind resource call frames
	;  (higher memory)
	;  ss:TPD_stackBot -> end of RCI_infoFrame (8b) or FOMFrame (6b)
	;  ss:TPD_stackBot-(6 or 8) -> start of RCI_infoFrame or FOMFrame
	;  ss:TPD_stackBot-(6 or 8)-(6 or 8) -> next RCI_infoFrame/FOMFrame
	;  ...
	;  (lower memory)
	;
		push	bx			; save EHC handle
		mov	bx, ss:[TPD_stackBot]
checkFrame:
		sub	bx, size RCI_infoFrame
if ERROR_CHECK
		call	JTEHCalcRCIChecksum
else
		cmp	ss:[bx].RCIIF_checkSum, RCIIF_CHECKSUM_CONSTANT
endif
		jne	notRCIIF
		push	bx		; save TPD_stackBot offset
		mov	bx, ss:[bx].RCIIF_handle
		call	MemUnlock
		pop	bx		; restore TPD_stackBot offset
		jmp	nextFrame

notRCIIF:
		add	bx, (size RCI_infoFrame)-(size FOMFrame)
nextFrame:
		cmp	bx, es:[EHC_stackBot]	; finished unwinding?
		jne	checkFrame
		mov	ss:[TPD_stackBot], bx	; restore TPD_stackBot
		pop	bx			; restore EHC handle

		mov	bp, es:[EHC_sp]	; SP to return to caller
		mov	ax, es:[EHC_ip]
		mov	ss:[bp], ax	; return off
		mov	ax, es:[EHC_cs]
		mov	ss:[bp]+2, ax	; return seg
		mov	ds, es:[EHC_ds]
		mov	di, es:[EHC_di]
		mov	si, es:[EHC_si]
		mov	ax, es:[EHC_bp]	; caller's BP
		mov	es, es:[EHC_es]
		call	MemUnlock
		mov	sp, bp
		mov	bp, ax
		mov	ax, -1		; return from error
		ret			; return to set_error_handler caller

unlockDone:
		call	MemUnlock
done:
		.leave
		ret
_jmp_to_error_handler	endp

if ERROR_CHECK

; For an EC kernel, RCIIF_checkSum contains a checksum of the other fields
; in the frame structure.  That should make an excellent test for
; distinguishing a RCI_infoFrame from a FOMFrame.  For an NC kernel,
; RCIIF_checkSum contains RCIIF_CHECKSUM_CONSTANT, and this routine isn't
; needed.  The code was stolen from ECCalcRCIChecksum. -dhunter 8/16/2000

JTEHCalcRCIChecksum proc near
	mov	ax, ss:[bx].RCIIF_handle
	add	ax, ss:[bx].RCIIF_retAddr.offset
	add	ax, ss:[bx].RCIIF_retAddr.segment
	add	ax, 'jw'			; Don't allow zero to work
	cmp	ax, ss:[bx].RCIIF_checkSum
	ret
JTEHCalcRCIChecksum endp

endif

	SetGeosConvention

idata ends
