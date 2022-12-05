COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC SDK
MODULE:		Sample Library -- Mandelbrot Set Library
FILE:		calcManager.asm

AUTHOR:		Paul DuBois, Aug 25, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/25/93   	Initial revision


DESCRIPTION:

	Manager file for the Calc module

	$Id: acManager.asm,v 1.1 97/04/07 10:43:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def		;standard structures, constants, macros

include geode.def		;Structures and routines for geodes --
				;contains decl for GeodeInfoQueue
				
include ec.def			;Standard error-checking macros and code

include mset.def		;mset structures, constants, and types
include ac.def			;declaration of exported routines

include acLine.asm		;line-based calculation algorithm
include ac48Bit.asm		;48-bit math routines
include ac16Bit.asm		;16-bit math routines
