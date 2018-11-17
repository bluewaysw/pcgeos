
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		uiEvalPCL4Simplex.asm

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

	$Id: uiEvalPCL4Simplex.asm,v 1.1 97/04/18 11:50:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintEvalSimplex
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
PrintEvalSimplex	proc	near
        tst     dx              ;see if we really do anything here.
        jz      exit            ;if not, just exit.
        cmp     bx,PRINT_UI_EVAL_ROUTINE ;see if eval or stuff...
        jne     stuffUI         ;if stuff routine, skip.
		;get the data for the gen list of outputs.
	mov	bx,dx
	push	si
	mov	si,offset Pcl4InputList
	call	PrintGetListExclData
	pop	si
	mov	es:[si].[JP_printerData].[PUID_paperInput],al

		;get the data from the memory range genrange.
	push	si
	mov	si,offset Pcl4MemRange
	call	PrintGetValueValue
	pop	si
	mov	cl,ch			;get fraction to right for BBFixed
	mov	ch,dl			;OK now cx is BBFixed format.
	mov	es:[si].[JP_printerData].[PUID_amountMemory],cx

		;get the data from the init or not genrange.
	push	si
	mov	si,offset Pcl4InitList
	call	PrintGetListExclData
	pop	si
	mov	es:[si].[JP_printerData].[PUID_initMemory],al

		;get the data from the Symbol set list.
	push	si
	mov	si,offset Pcl4SymbolList
	call	PrintGetListExclData
	pop	si
	mov	es:[si].[JP_printerData].[PUID_symbolSet],ax
        mov     es:[si].[JP_printerData].[PUID_countryCode],PCC_USA
        mov     es:[si].[JP_printerData].[PUID_paperOutput],OB_OUTPUTBIN1
        jmp     exit
stuffUI:
	push	ax,bx,dx,si,di,bp
	mov	bx,dx			;mov handle to bx
	clr	dx			;init the hi word.
	mov	bp,dx			;and set determinate while here....
	mov	cx,es:[si].[JP_printerData].[PUID_amountMemory]
	xchg	ch,dl			;convert to WWFixed
	xchg	cl,ch
        mov     si,offset Pcl4MemRange
	mov	ax,MSG_GEN_VALUE_SET_VALUE
	call	PrintObjMessageCall
	pop	ax,bx,dx,si,di,bp
        clr     ch
        mov     cl,es:[si].[JP_printerData].[PUID_initMemory]
        push    si              ;save offset into JobParameters.
        mov     si,offset Pcl4InitList
        call    PrintStuffCommon
        pop     si
        clr     ch
        mov     cl,es:[si].[JP_printerData].[PUID_paperInput]
        push    si              ;save offset into JobParameters.
        mov     si,offset Pcl4InputList
        call    PrintStuffCommon
        pop     si
        mov     cx,es:[si].[JP_printerData].[PUID_symbolSet]
        mov     si,offset Pcl4SymbolList
        call    PrintStuffCommon
exit:
	ret
PrintEvalSimplex	endp


		;Common routines for the evaluation routines.

PrintGetListExclData	proc	near
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	GOTO	PrintObjMessageCall
PrintGetListExclData	endp

PrintGetValueValue	proc	near
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	FALL_THRU	PrintObjMessageCall
PrintGetValueValue	endp
	

PrintObjMessageCall	proc	near
	mov	di,mask MF_CALL
	call	ObjMessage
	ret
PrintObjMessageCall	endp

PrintStuffCommon        proc    near
        uses    ax,bx,dx,di
        .enter
        mov     bx,dx           ;handle of the options list tree.
        clr     dx                      ;set to determinate
        mov     ax,MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
        mov     di,mask MF_CALL
        call    ObjMessage
        .leave
        ret
PrintStuffCommon        endp
