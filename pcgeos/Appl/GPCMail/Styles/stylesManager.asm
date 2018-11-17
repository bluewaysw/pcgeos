COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1999 -- All Rights Reserved

PROJECT:	Mail
FILE:		stylesManager.asm

AUTHOR:		Gene Anderson

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/24/99		Initial revision

DESCRIPTION:

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include stdapp.def
include Objects/vTextC.def
include stylesStyles.def

global PROCESSRICHTAG:far
global PROCESSHTMLTAG:far
global PROCESSHTMLCHAR:far
global STYLESTACKINIT:far
global STYLESTACKFREE:far
global PROCESSURLSTART:far
global PROCESSURLEND:far
global PARSETIMEZONE:far

SetGeosConvention

include stylesStyles.asm
include stylesStack.asm
include parseTimezone.asm

SetDefaultConvention
