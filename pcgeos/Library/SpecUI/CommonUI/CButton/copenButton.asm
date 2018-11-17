COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (gadgets code common to all specific UIs)
FILE:		copenButton.asm (common portion of button code)

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLButtonClass		Open look button

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	7/89		additional commenting, restructuring
	Clayton	10/89		Made changes to make settings, etc. a subclass
	Eric	2/90		Moved B&W and Color-specific draw routines
				to copenButtonBW.asm and copenButtonColor.asm
				Plus an incredible amount of cleanup work.

DESCRIPTION:

	$Id: copenButton.asm,v 1.1 97/04/07 10:55:02 newdeal Exp $

------------------------------------------------------------------------------@


	******************************************************************
	* DO NOT INCLUDE OR ADD CODE TO THIS FILE, IT IS OFFICIALLY DEAD *
	******************************************************************

	;
	; This file has been broken out into:
	;	copenButtonClass.asm
	;	copenButtonCommon.asm
	;	copenButtonBuild.asm
	;
