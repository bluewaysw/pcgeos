COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		tmpref.asm

AUTHOR:		Adam de Boor, Dec  3, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 3/92		Initial revision


DESCRIPTION:
	Driver-specific preferences for TaskMAX driver.
		

	$Id: tmpref.asm,v 1.1 97/04/18 11:58:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include geode.def
include lmem.def
include object.def
include graphics.def
include gstring.def
UseLib	ui.def

include	vmdef.def
UseLib config.def

ATTRIBUTES	equ	PREFVM_ATTRIBUTES

include	tmpref.rdef

DefVMBlock	MapBlock
PrefVMMapBlock	<RootObject>
EndVMBlock	MapBlock
