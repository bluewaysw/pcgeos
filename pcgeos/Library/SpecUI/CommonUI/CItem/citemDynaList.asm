COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CItem (common code for specific UIs)
FILE:		citemDynaList.asm

METHODS:
 Name			Description
 ----			-----------

ROUTINES:
 Name			Description
 ----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial revision

DESCRIPTION:
	$Id: citemDynaList.asm,v 1.1 97/04/07 10:55:24 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------

OLDynaListClass:

Synopsis
--------

Declaration
-----------

OLDynaListClass	class	OLScrollListClass
	uses	GenDynamicListClass

;------------------------------------------------------------------------------
;	Methods
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;	Hints
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;	Constants & Structures
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;	Instance Data
;------------------------------------------------------------------------------

OLDynaListClass	endc

Methods declared
----------------

Methods inherited
-----------------


Additional documentation
------------------------

------------------------------------------------------------------------------@

CommonUIClassStructures segment resource

	OLDynaListClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends

;-----------------------

ItemBuild	segment	resource
ItemBuild	ends

ItemCommon	segment	resource
ItemCommon	ends

