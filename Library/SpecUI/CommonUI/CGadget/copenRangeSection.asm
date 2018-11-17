COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991.  All rights reserved.

PROJECT:	PC GEOS
MODULE:		OpenLook/Gadget
FILE:		openRangeSection.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLRangeSectionClass	Open look range Section

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/91		Started V2.0

DESCRIPTION:
	This file implements the Open Look range Section object.


	$Id: copenRangeSection.asm,v 1.1 97/04/07 10:54:19 newdeal Exp $
	
-------------------------------------------------------------------------------@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------

OLRangeSectionClass:

Synopsis
--------


	NOTE: The section between "Declaration" and "Methods declared" is
	      copied into ollib.def by "pmake def"

Declaration
-----------

OLRangeSectionClass	class	OLRangeClass
	uses	GenRangeSectionClass
		
;-----------------------------------------------------------------------
;	Instance data
;-----------------------------------------------------------------------


OLRangeSectionClass	endc
		

Methods declared
----------------

Methods inherited
-----------------

Additional documentation
------------------------

------------------------------------------------------------------------------@

CommonUIClassStructures segment resource

	OLRangeSectionClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends



