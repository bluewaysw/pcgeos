
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		printcomCapslJob.asm

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
		

	$Id: printcomCapslJob.asm,v 1.1 97/04/18 11:51:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Job/jobStartCapsl.asm
include	Job/jobCopiesCapsl.asm
include	Job/jobEndDummy.asm
include	Job/jobPaperCapsl.asm
include	Job/jobPaperInfo.asm
