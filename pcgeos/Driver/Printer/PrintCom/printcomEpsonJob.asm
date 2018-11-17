
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		printcomEpsonJob.asm

AUTHOR:		Dave Durran, 8 Sept 1991

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job
	PrintEndJob		Cleanup done at end of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	3/92		Initial revision from epson24Setup.asm
	 Dave	5/92		Parsed up in Job directory.


DESCRIPTION:
	This file contains various job control routines needed by most epson
	printer drivers.
		

	$Id: printcomEpsonJob.asm,v 1.1 97/04/18 11:50:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Job/jobStartDefeatPaperout.asm
include	Job/jobEndDotMatrix.asm
include	Job/jobPaperPathASFControl.asm
include	Job/jobPaperInfo.asm
include Job/jobResetPrinterAndWait.asm
