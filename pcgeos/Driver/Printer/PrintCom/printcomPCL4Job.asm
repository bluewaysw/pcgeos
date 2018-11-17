
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		printcomPCL4Job.asm

AUTHOR:		Dave Durran, 8 March 1990

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job
	PrintEndJob		Cleanup done at end of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision from laserdwnSetup.asm
	Dave	5/92		Parsed into Job directory


DESCRIPTION:
	This file contains various setup routines needed by most PCL print 
	drivers.
		

	$Id: printcomPCL4Job.asm,v 1.1 97/04/18 11:50:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Job/jobStartPCL.asm
include	Job/jobEndPCL4.asm
include	Job/jobPaperPCL.asm
include	Job/jobPaperInfo.asm
include	Job/jobCopiesPCL4.asm
include	Job/Custom/customPPDSToPCL.asm
include	Job/Custom/customPJLToPCL.asm
include	Job/Custom/customLJ4PCL.asm
include	Job/Custom/customIBMPJLToPCL.asm
include	Job/Custom/customTotalResetPCL.asm
