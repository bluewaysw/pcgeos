
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		uiEval1ASFOnlySymbol.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	7/93		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the 1 bin ASF
	+manual feed print driver UI support
	this file MUST have the common eval routines included in another file

	$Id: uiEval1ASFOnlySymbol.asm,v 1.1 97/04/18 11:50:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintEvalOptionsUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
	called to evaluate the data passed in the object tree.

CALLED BY:

PASS:
;       PASS:           bp      = PState segment
;                       cx      = Handle of the duplicated generic tree
;                                 displayed in the main print dialog box.
;                       dx      = Handle of the duplicated generic tree
;                                 displayed in the options dialog box
;                       es:si      = Segment holding JobParameters structure
;                       ax      = Handle of JobParameters block


RETURN:
        nothing

DESTROYED:
        ax, bx, cx, si, di, es, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/92           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PrintEvalASF1BinOnly	proc	near
        tst     dx              ;see if we really do anything here.
        jz      exit            ;if not, just exit.
        cmp     bx,PRINT_UI_EVAL_ROUTINE ;see if eval or stuff...
        jne     stuffUI         ;if stuff routine, skip.
	push	si
	mov	si,offset OptionsASF1BinOnlyResource:ASF1BinOnlyInputList
	call	PrintEvalASFCommon
	pop	si
        mov     es:[si].[JP_printerData].[PUID_paperInput],al
	push	si
	mov	si,offset OptionsASF1BinOnlyResource:ASF1BinOnlySymbolList
	call	PrintEvalASFCommon
	pop	si
        mov     es:[si].[JP_printerData].[PUID_symbolSet],ax
        mov     es:[si].[JP_printerData].[PUID_countryCode],PCC_USA
        jmp     exit
stuffUI:
        clr     ch
        mov     cl,es:[si].[JP_printerData].[PUID_paperInput]
        push    si              ;save offset into JobParameters.
        mov     si,offset OptionsASF1BinOnlyResource:ASF1BinOnlyInputList
        call    PrintStuffCommon
        pop     si
        mov     cx,es:[si].[JP_printerData].[PUID_symbolSet]
        mov     si,offset OptionsASF1BinOnlyResource:ASF1BinOnlySymbolList
        call    PrintStuffCommon
exit:
	ret
PrintEvalASF1BinOnly	endp	

