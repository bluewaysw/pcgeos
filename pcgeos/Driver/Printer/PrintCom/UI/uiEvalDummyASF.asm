
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		uiEvalDummyASF.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/93		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the 1 bin ASF
	dummy JP loading routine.

	$Id: uiEvalDummyASF.asm,v 1.1 97/04/18 11:50:39 newdeal Exp $

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
        Dave    04/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



PrintEvalDummyASF	proc	near
        tst     dx              ;see if we really do anything here.
        jz      exit            ;if not, just exit.
        cmp     bx,PRINT_UI_EVAL_ROUTINE ;see if eval or stuff...
        jne     exit		;if stuff routine, skip.
        mov     es:[si].[JP_printerData].[PUID_paperInput], ASF_TRAY1 shl \
(offset PIO_ASF)
        mov     es:[si].[JP_printerData].[PUID_paperOutput],NULL
        mov     es:[si].[JP_printerData].[PUID_countryCode],PCC_USA
        mov     es:[si].[JP_printerData].[PUID_symbolSet],PSS_IBM437
exit:
	ret
PrintEvalDummyASF	endp	

