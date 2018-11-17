COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet link driver
FILE:		ethercomOptions.asm

AUTHOR:		Todd Stumpf, July 8th, 1998

ROUTINES:

    INT EtherSetOptions		Set driver options
    INT EtherGetOptions		Retreive driver options

DESCRIPTION:

	Option routines common to all ethernet link drivers

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MovableCode		segment	resource

EtherSetOption		proc	far
		.enter
		.leave
		ret
EtherSetOption		endp

EtherGetOption		proc	far
		.enter
		.leave
		ret
EtherGetOption		endp

MovableCode		ends