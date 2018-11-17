COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		printcomNoTextNoRaw.asm

AUTHOR:		Dave Durran

ROUTINES:

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	10/94		Initial version from parsed routines


DESCRIPTION:

	$Id: printcomNoTextNoRaw.asm,v 1.1 97/04/18 11:51:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PrintStyleRun   proc    far
PrintText   label    far
PrintRaw	label	far
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

