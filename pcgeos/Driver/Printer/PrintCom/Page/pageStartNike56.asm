COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		pageStartNike56.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------
	PrintStartPage	initialize the page-related variables, called once/page
			by EXTERNAL at start of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	11/94	initial version

DESCRIPTION:

	$Id: pageStartNike56.asm,v 1.1 97/04/18 11:51:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.
		cl	- Suppress form feed flag, C_FF is FF non-suppressed

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintStartPage	proc	far
	uses	ax,bx,cx,di,ds,es
	.enter
		
		; see if the spooler is in the suppress formfeed mode.
	cmp	cl,C_FF
	jne	suppressformfeed

		; start cursor out at top,left position
	call	PrintHomeCursor	;start out from home position.
	jc	exit

suppressformfeed:
	mov	es,bp
	call	PrWaitForMechanismLow	;make sure nothing is happening.

	mov	es:[PS_dWP_Specific].DWPS_returnCode,PDR_NO_RETURN
					;Initialize the return code

	mov	al,PJLP_update		;update the LPES
	call	PrintGetErrorsLow

	test	al,mask	PER_MPE		;isolate the paper present bit.
	jz	initYOffset	;if logically controlled paper, let 'er rip.

	call	PrintInsertPaper	;try to load a sheet from ASF.

	call	PrWaitForMechanismLow	;wait for the paper to get loaded.

        mov     al,PJLP_update          ;update the LPES
	call	PrintGetErrorsLow	;see what happened....
	test	al,mask PER_MPE or mask PER_JAM
	jz	initYOffset

		;PAPER JAM DIALOG BOX WILL GET CALLED
	mov	es:[PS_dWP_Specific].DWPS_returnCode,PDR_PAPER_JAM_OR_EMPTY
	jmp	exit

initYOffset:
		;init the y offset to 0.
	mov	es:[PS_dWP_Specific].DWPS_yOffset,0
	mov	es:[PS_dWP_Specific].DWPS_finishColor,0	;finish color print = 0

	; If we're printing in color...

	mov	al,es:[PS_printerType]
	andnf	al,mask PT_COLOR
	cmp	al,BMF_MONO
	je	exit

		;clear out magenta and cyan history buffer
	mov	es, es:[PS_dWP_Specific].DWPS_buffer2Segment
	clr	di
	mov	cx, PRINT_COLOR_HISTORY_BUFFER_SIZE / 2
	clr	ax
	rep	stosw
exit:
	.leave
	ret
PrintStartPage	endp
