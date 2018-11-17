COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		spooltdManager.asm

AUTHOR:		Adam de Boor, Oct 26, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/26/94	Initial revision


DESCRIPTION:
	
		

	$Id: spooltdManager.asm,v 1.1 97/04/18 11:40:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include		stdapp.def
include		Internal/prodFeatures.def
include		assert.def
include		gcnlist.def
include		initfile.def
include		medium.def
UseLib		mailbox.def
UseLib		Internal/mboxInt.def
UseLib		spool.def
UseLib		Internal/spoolInt.def
DefDriver	Internal/mbTrnsDr.def
include		Mailbox/spooltd.def
include		Mailbox/filedd.def
include		Internal/heapInt.def


include		spooltdConstant.def
include		spooltdVariable.def
include		spooltd.rdef

include		spooltdAddress.asm
include		spooltdMedium.asm
include		spooltdMisc.asm
include		spooltdTransmit.asm
include		spooltdEntry.asm
