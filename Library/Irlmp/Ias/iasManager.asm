COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	Geoworks Confidential

PROJECT:	GEOS
MODULE:		IAS
FILE:		iasManager.asm

AUTHOR:		Chung Liu, May  2, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 2/95   	Initial revision


DESCRIPTION:
	Includes for IAS module.

	$Id: iasManager.asm,v 1.1 97/04/05 01:07:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include irlmpGeode.def

include iasVariable.def

include iasUtils.asm
include iasClientEvents.asm
include iasClientActions.asm
include iasIrlmp.asm
include iasCode.asm
include iasConfirm.asm
include iasServerEvents.asm
include iasServerActions.asm
include iasServerCallback.asm
include iasServerProcess.asm
include iasServerSend.asm


