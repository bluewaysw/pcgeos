COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		printcomNoText.asm

AUTHOR:		Dave Durran

ROUTINES:

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/92		Initial version from parsed routines


DESCRIPTION:

	$Id: printcomNoText.asm,v 1.1 97/04/18 11:50:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Text/textPrintRaw.asm

PrintStyleRun   proc    far
PrintText   label    far
PrintSetFont   label    far
PrintGetLineSpacing   label    far
PrintSetLineSpacing   label    far
	clc
	ret
PrintStyleRun   endp
PrintSetSymbolSet	proc	near
PrintLoadSymbolSet	label	near
	clc
	ret
PrintSetSymbolSet	endp

