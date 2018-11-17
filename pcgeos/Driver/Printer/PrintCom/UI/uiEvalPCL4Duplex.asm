
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		uiEvalPCL4Duplex.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/27/92		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the PCL 4
	print driver UI support

	$Id: uiEvalPCL4Duplex.asm,v 1.1 97/04/18 11:50:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintEvalDuplex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

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
PrintEvalDuplex	proc	near
	push	bx,cx,si	;save the handle of the options box stuff.
	call	PrintEvalSimplex	;do the rest of the normal stuff.
	pop	bx,cx,si		;handle saved above

        tst     cx              ;see if we really do anything here.
        jz      exit            ;if not, just exit.
        cmp     bx,PRINT_UI_EVAL_ROUTINE ;see if eval or stuff...
        jne     stuffUI         ;if stuff routine, skip.
		;get the data for the gen list of outputs.
	mov	bx,cx
	push	si
	mov	si,offset Pcl4DuplexList
	call	PrintGetListExclData
	pop	si
	mov	es:[si].[JP_printerData].[PUID_paperOutput],al
        jmp     exit
stuffUI:
        clr     ch
        mov     cl,es:[si].[JP_printerData].[PUID_paperOutput]
        mov     si,offset Pcl4DuplexList
        mov     bx,dx           ;handle of the options list tree.
        clr     dx                      ;set to determinate
        mov     ax,MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
        mov     di,mask MF_CALL
        call    ObjMessage
exit:
	ret
PrintEvalDuplex	endp

