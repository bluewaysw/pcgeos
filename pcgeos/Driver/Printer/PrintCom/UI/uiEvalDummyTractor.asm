
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		uiEvalDummyTractor.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/93		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the 1 path tractor
	dummy JP loading routine.

	$Id: uiEvalDummyTractor.asm,v 1.1 97/04/18 11:50:42 newdeal Exp $

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
	Hand stuff the JobParameters block for later.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    05/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



PrintEvalDummyASF	proc	near
        tst     dx              ;see if we really do anything here.
        jz      exit            ;if not, just exit.
        cmp     bx,PRINT_UI_EVAL_ROUTINE ;see if eval or stuff...
        jne     exit		;if stuff routine, skip.
        mov     es:[si].[JP_printerData].[PUID_paperInput], TF_TRACTOR1 shl \
(offset PIO_TRACTOR)
        mov     es:[si].[JP_printerData].[PUID_paperOutput],NULL
        mov     es:[si].[JP_printerData].[PUID_countryCode],PCC_USA
        mov     es:[si].[JP_printerData].[PUID_symbolSet],PSS_IBM437
exit:
	ret
PrintEvalDummyASF	endp	

