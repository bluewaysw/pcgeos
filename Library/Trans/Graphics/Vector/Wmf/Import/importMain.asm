COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		importMain.asm

AUTHOR:		Maryann Simmons, Jul 13, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/13/92		Initial revision


DESCRIPTION:
	
		

	$Id: importMain.asm,v 1.1 97/04/07 11:24:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Code
;----------------------------------------------------------------------------

include importWMF.asm


ImportCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportVectorConvertToTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine converts the passed WMF metafile to a VMChain
		transfer item.	

CALLED BY:	GLOBAL( Impex )
PASS:		BP	- handle of WMF metafile
		DI	- handle of VM File 
RETURN:		
		DX:CX	- created transfer Item
		AX	- TransError
		BX	- mem handle with text error string if AX = TE_CUSTOM
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportVectorConvertToTransferItem	proc	far
	.enter
	mov	bx,bp
	call	ImportWMF
	.leave
	ret
ImportVectorConvertToTransferItem	endp



public	ImportVectorConvertToTransferItem

ImportCode	ends
