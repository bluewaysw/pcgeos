
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		uiEval1ASF.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/92		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the 1 bin ASF
	+tractor and manual feed print driver UI support

	$Id: uiEval1ASF.asm,v 1.1 97/04/18 11:50:39 newdeal Exp $

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
        Dave    01/92           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



PrintEvalASF1Bin	proc	near
        tst     dx              ;see if we really do anything here.
        jz      exit            ;if not, just exit.
        cmp     bx,PRINT_UI_EVAL_ROUTINE ;see if eval or stuff...
        jne     stuffUI         ;if stuff routine, skip.
	push	si
	mov	si,offset OptionsASF1BinResource:ASF1BinInputList
	push	bx,cx,dx,bp,di
	mov	bx,dx		;handle of the options list tree.
        mov     ax,MSG_GEN_ITEM_GROUP_GET_SELECTION
        mov     di,mask MF_CALL
        call    ObjMessage
	pop	bx,cx,dx,bp,di
	pop	si
        mov     es:[si].[JP_printerData].[PUID_paperInput],al
        mov     es:[si].[JP_printerData].[PUID_countryCode],PCC_USA
        mov     es:[si].[JP_printerData].[PUID_symbolSet],PSS_IBM437
        jmp     exit
stuffUI:
        clr     ch
        mov     cl,es:[si].[JP_printerData].[PUID_paperInput]
        mov     si,offset OptionsASF1BinResource:ASF1BinInputList
        push    ax,bx,dx,di
        mov     bx,dx           ;handle of the options list tree.
        clr     dx                      ;set to determinate
        mov     ax,MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
        mov     di,mask MF_CALL
        call    ObjMessage
        pop     ax,bx,dx,di
exit:
	ret
PrintEvalASF1Bin	endp	

