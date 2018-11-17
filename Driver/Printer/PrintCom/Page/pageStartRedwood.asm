
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		pageStartRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------
	PrintStartPage	initialize the page-related variables, called once/page
			by EXTERNAL at start of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	9/93	initial version

DESCRIPTION:

	$Id: pageStartRedwood.asm,v 1.1 97/04/18 11:51:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.
		cl	- Suppress form feed flag, C_FF is FF non-suppressed

RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/90		Initial version
	Dave	3/94		Incorporated Ted Kawanabe logic

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintStartPage	proc	far
	uses	ds,es,dx
	.enter
		
		; see if the spooler is in the suppress formfeed mode.
	cmp	cl,C_FF
	jne	suppressformfeed

		; start cursor out at top,left position
	call	PrintHomeCursor	;start out from home position.
	jc	exit

suppressformfeed:
	mov	es,bp

	mov	es:[PS_redwoodSpecific].RS_returnCode,PDR_NO_RETURN
					;Initialize the return code

	mov	al,PJLP_update		;update the LPES
	call	PrintGetErrors

	test	al,mask	PER_MPE		;isolate the logical paper bit.
	jz	initYOffset	;if logically controlled paper, let 'er rip.

	test	al,mask PER_ASF		;isolate the ASF present bit.
	jz	initYOffset		;if ASF absent, then ready to go.....

	test	al,mask PER_PES		;isolate the physical present bit.
	jz	initYOffset		;if paper loaded, then ready to go.....

        mov     si,offset pr_codes_SetASF ;ASF present, and PES = 1
        call    SendCodeOut			;try to load the paper....

	call	PrintWaitForMechanism	;wait for the paper to get loaded.

        mov     al,PJLP_update          ;update the LPES
	call	PrintGetErrors		;see what happened....
	test	al,mask PER_MPE or mask PER_JAM
	jz	initYOffset

paperJamDialog:

	;PAPER JAM DIALOG BOX WILL GET CALLED
	mov	es:[PS_redwoodSpecific].RS_returnCode,PDR_PAPER_JAM_OR_EMPTY
	jmp	exit

initYOffset:
			;init the y offset to 0.
	mov	es:[PS_redwoodSpecific].RS_yOffset,0

exit:
	.leave
	ret
PrintStartPage	endp
