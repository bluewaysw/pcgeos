COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoFile
FILE:		Manager.asm

AUTHOR:		Anna Lijphart, Dec 1, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	12/1/92		Initial revision

DESCRIPTION:
	This file contains globals and includes for the titled buttons

	$Id: docasmManager.asm,v 1.1 97/04/04 15:53:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include stdapp.def

include gfButton.def

global DesignModeLRSCMoniker: chunk
global DataEntryModeLRSCMoniker: chunk
global SingleRecordLayoutLRSCMoniker: chunk
global MultiRecordLayoutLRSCMoniker: chunk
global CreateNewFieldSCMoniker: chunk
global DesignModeLRSMMoniker: chunk
global DataEntryModeLRSMMoniker: chunk
global SingleRecordLayoutLRSMMoniker: chunk
global MultiRecordLayoutLRSMMoniker: chunk
global CreateNewFieldSMMoniker: chunk
global DesignModeLRSCGAMoniker: chunk
global DataEntryModeLRSCGAMoniker: chunk
global SingleRecordLayoutLRSCGAMoniker: chunk
global MultiRecordLayoutLRSCGAMoniker: chunk
global CreateNewFieldSCGAMoniker: chunk

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include docButtn.asm
