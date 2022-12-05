COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		mainManager.asm

AUTHOR:		Chung Liu, Mar 15, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95   	Initial revision


DESCRIPTION:
	Includes for Main module
		

	$Id: mainManager.asm,v 1.1 97/04/05 01:08:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include irlmpGeode.def

include thread.def
include sem.def
include Internal/semInt.def

include mainConstant.def
include mainVariable.def

include mainLibrary.asm
include mainProcess.asm
include mainUtils.asm
