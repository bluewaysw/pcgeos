COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainEscape.asm

AUTHOR:		Brian Chin

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
EXT	BitstremFontEscape	Handle any escape functions passed to this
				font driver.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/30/93		Initial version.

DESCRIPTION:
	This file contains the GEOS Bitstream Font Driver escape
	function handler.

	$Id: mainEscape.asm,v 1.1 97/04/18 11:45:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamFontEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle all of the driver escape functions that have been
		passed to the Bitstream font driver.

CALLED BY:	BitstreamStrategy.

PASS:		DI	= Escape function.

RETURN:		DI	= 0 iff escape function not supported
			  Otherwise, unchanged

DESTROYED:	Escape function dependent

PSEUDO CODE/STRATEGY:

CHECKS:		None.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitstreamFontEscape	proc	far
	; Pass off the call to FontCallEscape to handle.
	call	FontCallEscape
	ret
BitstreamFontEscape	endp

;-----------------------------------------------------------------------------
;	Escape function stubs (must be in same segment)
;-----------------------------------------------------------------------------

BitstreamInstallInitStub	proc	near
	call	BitstreamInstallInit
	ret
BitstreamInstallInitStub	endp

BitstreamInstallExitStub	proc	near
	call	BitstreamInstallExit
	ret
BitstreamInstallExitStub	endp

BitstreamInstallGetCharBBoxStub	proc	near
	call	BitstreamInstallGetCharBBox
	ret
BitstreamInstallGetCharBBoxStub	endp

BitstreamInstallGetPairKernStub	proc	near
	call	BitstreamInstallGetPairKern
	ret
BitstreamInstallGetPairKernStub	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Escape Function Table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DefEscapeTable	5

DefEscape	FontQueryEscape,	DRV_ESC_QUERY_ESC
DefEscape	BitstreamInstallInitStub,	FONT_ESC_BITSTREAM_INSTALL_INIT
DefEscape	BitstreamInstallExitStub,	FONT_ESC_BITSTREAM_INSTALL_EXIT
DefEscape	BitstreamInstallGetCharBBoxStub,	FONT_ESC_BITSTREAM_INSTALL_GET_CHAR_BBOX
DefEscape	BitstreamInstallGetPairKernStub,	FONT_ESC_BITSTREAM_INSTALL_GET_PAIR_KERN
