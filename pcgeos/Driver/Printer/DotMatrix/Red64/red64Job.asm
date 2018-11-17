
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		red64Job.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job
	PrintEndJob		Cleanup done at end of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	11/92		Initial revision 


DESCRIPTION:
	This file contains various job control routines needed by 
	the Canon Redwood printer drivers.
		

	$Id: red64Job.asm,v 1.1 97/04/18 11:55:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Job/jobStartRedwood.asm
include	Job/jobEndRedwood.asm
include	Job/jobPaperPathRedwood.asm
include	Job/jobPaperInfo.asm
include	Job/jobPaperInfoRedwood.asm
