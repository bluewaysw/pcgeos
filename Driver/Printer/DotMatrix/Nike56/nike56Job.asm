
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Brother NIKE 56-jet Drivers
FILE:		nike56Job.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job
	PrintEndJob		Cleanup done at end of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	10/94		Initial revision 


DESCRIPTION:
	This file contains various job control routines needed by 
	the Brother NIKE printer drivers.
		

	$Id: nike56Job.asm,v 1.1 97/04/18 11:55:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Job/jobStartNike.asm
include	Job/jobEndNike.asm
include	Job/jobPaperPathNike.asm
include	Job/jobPaperInfo.asm
include	Job/jobPaperInfoNike.asm
