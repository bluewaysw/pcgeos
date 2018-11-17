
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		postscript print driver
FILE:		psbText.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/11/91		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the laserjet
	print driver ascii text support

	$Id: psbTextRes.asm,v 1.1 97/04/18 11:52:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


; These are a bunch of routines that need to exist but don't do anything for
; this driver

PrintGetLineSpacing	proc	near
		clc
		ret
PrintGetLineSpacing	endp

PrintGetStyles	proc	near
		clc
		ret
PrintGetStyles	endp

