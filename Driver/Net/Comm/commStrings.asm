COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Comm Driver
FILE:		CommStrings.asm

AUTHOR:		In Sik Rhee, Oct 21, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/21/92		Initial revision


DESCRIPTION:
	string resource for Comm Driver
		

	$Id: commStrings.asm,v 1.1 97/04/18 11:48:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitExitCode	segment	resource

commDomainName	char	"COMM",0

domainNameTable		nptr.char \
	com1name,
	com2name,
	com3name,
	com4name,
	com5name,
	com6name,
	com7name,
	com8name

com1name 	char	"COM1",0
com2name 	char	"COM2",0
com3name 	char	"COM3",0
com4name 	char	"COM4",0
com5name 	char	"COM5",0
com6name 	char	"COM6",0
com7name 	char	"COM7",0
com8name 	char	"COM8",0

InitExitCode	ends

