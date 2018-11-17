COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet link driver
FILE:		ethercomMedium.asm

AUTHOR:		Todd Stumpf, July 8th, 1998

ROUTINES:

    INT EtherCloseMedium
    INT EtherActivateMedium
    INT EtherConnectMediumRequest
    INT EtherSetMediumOption

DESCRIPTION:

	Option routines common to all ethernet link drivers

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MovableCode		segment	resource

EtherCloseMedium		proc	far
		.enter
		.leave
		ret
EtherCloseMedium		endp

EtherActivateMedium		proc	far
		.enter
		.leave
		ret
EtherActivateMedium		endp

EtherConnectMediumRequest	proc	far
		.enter
		.leave
		ret
EtherConnectMediumRequest	endp

EtherSetMediumOption		proc	far
		.enter
		.leave
		ret
EtherSetMediumOption		endp

MovableCode		ends
