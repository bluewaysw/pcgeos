COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:        PC GEOS
MODULE:         Brother NIKE 56-jet print driver
FILE:           nike56Escapes.asm

AUTHOR:         Dave Durran

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94          Initial revision


DESCRIPTION:
        This file contains the ESCAPE routines:

	PrintProcessErrors

        $Id: nike56Errors.asm,v 1.1 97/04/18 11:55:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintProcessErrors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       process errors from the Printer BIOS calls

CALLED BY:      PRINT ESCAPE CALL

PASS:		bp      - PState segment
		dx:si	- pointer to SpoolJobInfo structure

RETURN:		carry set - catastrophic quit,
			no endpage call : AX = GSRT_FAULT on exit
		carry clear - check ax
			ax      - flag to quit or keep going after carry clr.
				GSRT_COMPLETE = OK do another swath
				GSRT_FAULT = quit, ejecting the paper.

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
		Directly have the printer cap the printhead, and wait for the 
		mechanism to stop.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    08/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintProcessErrors	proc	far
	mov	ax, GSRT_COMPLETE
	clc
	ret
PrintProcessErrors	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintErrorBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine puts up a the appropriate GenSummons and waits
		for the OK button to be pressed.

CALLED BY:	INTERNAL

PASS:		cx	- PrinterError enum

RETURN:		ax - InteractionCommand response from dialog trigger

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Use UserStandardDialog to put up a message and get a 
		response

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		dave	1/95		Pilfered from the Spooler code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintErrorBox	proc	near
		uses	bx, cx, dx, si, di, bp, ds
		.enter

		; first set up all the current strings in the resource segment
		; Need:
		; ax - CustomDialogBoxFlags.
		; di:bp - error message string.
		; cx:dx - First string argument.
		; bx:si - Second string argument.
		; StandardDialogParams
		;	SDP_type
		;	SDP_customFlags
		;	SDP_customString
		;	SDP_stringArg1
		;	SDP_stringArg2
		;	SDP_customTriggers (if GIT_MULTIPLE_RESPONSE)

		mov	si, cx				; so we can addr things

                ; lock down the segment with all the error message strings
		; then set SDP_type and SDP_customFlags

		mov	bx,handle customStringsUI	; get handle to resource
		push	bx				; save the handle
		call	MemLock				; lock the sucker
		mov	ds, ax				; ds -> resource
		mov	ax, cs:errTypesAndFlags[si]	; get flags in al,ah

		; set up stack frame for StandardDialogParams structure

		sub	sp, size StandardDialogParams
		mov	bp, sp				; ss:bp = params
		mov	ss:[bp].SDP_customFlags, ax

		; set up fptr to resource triggers (only used if
		; GIT_MULTIPLE_REPONSE)

		mov	bx, cs:errResponseTriggers[si]	; trigger list offset
EC <		andnf	ax, mask CDBF_INTERACTION_TYPE			>
EC <		cmp	ax, GIT_MULTIPLE_RESPONSE shl offset CDBF_INTERACTION_TYPE >
EC <		jne	notCustom					>
EC <		tst	bx						>
EC <		ERROR_Z	PRINT_ERROR_BOX_BAD_ERROR_TABLE_ENTRY		>
EC <notCustom:								>

		mov	ss:[bp].SDP_customTriggers.offset, bx
		mov	ss:[bp].SDP_customTriggers.segment, cs

		; set up the offsets to the right chunks
		mov	bx, cs:errMessageStringsNoArgs[si]
		mov	ax, ds:[bx]			; error string offset
		mov	ss:[bp].SDP_customString.offset, ax
		clr	ax
		mov	ss:[bp].SDP_stringArg1.offset, ax	; no args
		mov	ss:[bp].SDP_stringArg2.offset, ax

		; setup all the segments

		mov	ax, ds
		mov	ss:[bp].SDP_customString.segment, ax
		mov	ss:[bp].SDP_stringArg1.segment, ax
		mov	ss:[bp].SDP_stringArg2.segment, ax
		clr	ss:[bp].SDP_helpContext.segment

		; all done, now just call the thing

							; pass params on stack
		call	UserStandardDialog		; put up the DB
							; return value in ax
		cmp	ax, IC_NULL			; if null, make it
		jne	unlockResource			;  DISMISS
		mov	ax, IC_DISMISS

                ; since we're all done, release the resource block
unlockResource:
                pop     bx                              ; restore handle
                call    MemUnlock
		.leave
		ret

		; there was no queue, so use different strings, that don't
		; require any arguments
PrintErrorBox	endp


;----------------------------------------------------------------------------
;	Dialog box data and pointers follow.
;----------------------------------------------------------------------------


		; The first two parameters to UserStandardDialog.
		; These are loaded into al/ah.
errTypesAndFlags	label	word

				; CPMSG_TIMEOUT
	word CustomDialogBoxFlags <1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>

				; CPMSG_PAPER_JAM
	word CustomDialogBoxFlags <1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>

				; CPMSG_INSERT_PAPER
	word CustomDialogBoxFlags <1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>

				; CPMSG_PAPER_RUN_OUT
	word CustomDialogBoxFlags <1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>

				; CPMSG_SOME_ERROR
	word CustomDialogBoxFlags <1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>

				; CPMSG_FATAL_ERROR
	word CustomDialogBoxFlags <1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>

				; CPMSG_CHANGE_CARTRIDGE
	word CustomDialogBoxFlags <1,CDT_NOTIFICATION,GIT_MULTIPLE_RESPONSE,0>

				; CPMSG_ERROR_HOMING
	word CustomDialogBoxFlags <1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>


errOKCancelResponseTriggers	label	StandardDialogResponseTriggerTable
	word	2
	StandardDialogResponseTriggerEntry <
		ErrOKTriggerMoniker,
		IC_OK
	>
	StandardDialogResponseTriggerEntry <
		ErrCancelTriggerMoniker,
		IC_DISMISS
	>

errOKAsCancelResponseTriggers	label	StandardDialogResponseTriggerTable
	word	1
	StandardDialogResponseTriggerEntry <
		ErrOKTriggerMoniker,
		IC_DISMISS
	>

		; These are the response trigger lists to be used
		; with UserStandardDialog (used with GIT_MULTIPLE_RESPONSE).
errResponseTriggers	label	word
	word offset errOKAsCancelResponseTriggers	;CPMSG_TIMEOUT
	word offset errOKAsCancelResponseTriggers	;CPMSG_PAPER_JAM
	word offset errOKCancelResponseTriggers		;CPMSG_INSERT_PAPER
	word offset errOKAsCancelResponseTriggers	;CPMSG_PAPER_RUN_OUT
	word offset errOKCancelResponseTriggers		;CPMSG_SOME_ERROR
	word offset errOKAsCancelResponseTriggers	;CPMSG_FATAL_ERROR
	word offset errOKAsCancelResponseTriggers	;CPMSG_CHANGE_CARTRIDGE
	word offset errOKAsCancelResponseTriggers	;CPMSG_ERROR_HOMING


		; These are offsets to the error message strings to be used
		; with UserStandardDialog when there are no arguments to be had
errMessageStringsNoArgs	label	word
	nptr offset customStringsUI:TimeoutText		;CPMSG_TIMEOUT
	nptr offset customStringsUI:PaperJamText	;CPMSG_PAPER_JAM
	nptr offset customStringsUI:InsertPaperText	;CPMSG_INSERT_PAPER
	nptr offset customStringsUI:PaperRunOutText	;CPMSG_PAPER_RUN_OUT
	nptr offset customStringsUI:SomeErrorText	;CPMSG_SOME_ERROR
	nptr offset customStringsUI:FatalErrorText	;CPMSG_FATAL_ERROR
	nptr offset customStringsUI:ChangeCartridgeText	;CPMSG_CHANGE_CARTRIDGE
	nptr offset customStringsUI:ErrorHomingText	;CPMSG_ERROR_HOMING
