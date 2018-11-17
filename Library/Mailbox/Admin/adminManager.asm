COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Administrative File Management
FILE:		adminManager.asm

AUTHOR:		Adam de Boor, Apr 14, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/94		Initial revision


DESCRIPTION:
	Administrative file management
		

	$Id: adminManager.asm,v 1.1 97/04/05 01:20:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	mailboxGeode.def

include system.def
include	initfile.def
UseDriver	Internal/mbTrnsDr.def
UseDriver	Internal/mbDataDr.def
include Internal/semInt.def
include	fileEnum.def

include	adminConstant.def
include	adminVariable.def

include	adminInit.asm
include adminCode.asm
include adminC.asm
