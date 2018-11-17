COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		printcomCanonBJCJob.asm

AUTHOR:		Joon Song, 9 Jan 1999

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job
	PrintEndJob		Cleanup done at end of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Joon	1/99		Initial revision from printcomEpsonJob.asm


DESCRIPTION:
	This file contains various job control routines needed by some Canon
	BJC printer drivers.
		

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Job/jobStartCanonBJC.asm
include	Job/jobEndCanonBJC.asm
include Job/jobPaperPathNoASFControl.asm
include	Job/jobPaperInfo.asm
include Job/jobResetPrinterAndWait.asm
