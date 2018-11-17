COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Tiramisu
MODULE:		Fax
FILE:		faxprintCommon.asm

AUTHOR:		Andy Chiu, Feb  7, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/ 7/94   	Initial revision
	jdashe	11/2/94		Snarfed for tiramisu


DESCRIPTION:
	Common routines that are used at different places in the
	fax printer driver.	
		
	$Id: faxprintCommon.asm,v 1.1 97/04/18 11:53:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                DoDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Puts up a standard dialog

CALLED BY:      GLOBAL
PASS:           si - chunk handle of string
                ax - CustomDialogBoxFlags
RETURN:         ax - InteractionCommand
DESTROYED:      nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        atw     11/11/93        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoDialog        proc    near
                uses    bp
                .enter
                
                sub     sp, size StandardDialogOptrParams
                mov     bp, sp
                mov     ss:[bp].SDOP_customFlags, ax
                mov     ss:[bp].SDOP_customString.handle, handle StringBlock
                mov     ss:[bp].SDOP_customString.chunk, si
                clrdw   ss:[bp].SDOP_stringArg1
                clrdw   ss:[bp].SDOP_stringArg2
                clrdw   ss:[bp].SDOP_customTriggers
                clrdw   ss:[bp].SDOP_helpContext
                call    UserStandardDialogOptr
                
                .leave
                ret
DoDialog        endp

