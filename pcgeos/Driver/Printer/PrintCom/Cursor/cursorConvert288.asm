
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Diconix 9-pin print driver
FILE:		cursorConvert288.asm

AUTHOR:		Dave Durran, 20	November 91

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/22/91	Initial revision from epson9Cursor


DESCRIPTION:
	This file contains most of the code to implement the diconix 9-pin
	print driver cursor movement support

	$Id: cursorConvert288.asm,v 1.1 97/04/18 11:49:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrConvertToDriverCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
	convert a value passed in 1/72" units in dx.ax to 1/288" units in dx

CALLED BY:

PASS:
        dx.ax   =       WWFixed value to convert.

RETURN:
	dx	=	value in 1/288" units

DESTROYED:
        nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    02/90           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrConvertToDriverCoordinates	proc    near
	shl	ax,1		;x2
	rcl	dx,1
	shl	ax,1		;x4 = 1/288"
	rcl	dx,1
	ret
PrConvertToDriverCoordinates	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrConvertFromDriverCoordinates	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
	convert a value passed in 1/288" units in dx to 1/72" units in dx.ax

CALLED BY:

PASS:
	dx	=	value in 1/288" units

RETURN:
        dx.ax   =       WWFixed value in 1/72nd " units

DESTROYED:
        nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    02/90           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrConvertFromDriverCoordinates	proc    near
	clr	ax		;get the fraction to zero.
	sar	dx,1
	rcr	ax,1
	sar	dx,1
	rcr	ax,1
	ret
PrConvertFromDriverCoordinates	endp
