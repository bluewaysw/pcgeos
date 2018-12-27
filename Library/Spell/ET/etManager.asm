COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spell Library
FILE:		thesManager.asm

AUTHOR:		Ty Johnson, 8/27/92

ROUTINES:
	Name			Description
	----			-----------
	None
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tyj	8/27/92		Initial revision


DESCRIPTION:

	$Id: etManager.asm,v 1.1 97/04/07 11:07:52 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;			Include Files
;----------------------------------------------------------------------------

include	geos.def
include	heap.def
include	geode.def
include	resource.def
include	ec.def
include lmem.def
include thread.def
include sem.def
include chunkarr.def
include initfile.def

include library.def
include file.def

include	object.def
include localize.def

include etConstant.def
include etVariable.def

include spellConstant.def

;ETCODE	segment	word public 'CODE'
ETCODE	segment	public 'CODE'
ifdef __BORLANDC__
global	_et_load:far
global	_et_close:far
global	_et:far
else
global 	et_load:far
global	et_close:far
global	et:far
endif
ETCODE	ends

ThesaurusCode segment resource 
	global ThesaurusGetMeanings:far
	global ThesaurusGetSynonyms:far
	global ThesaurusOpen:far
	global ThesaurusClose:far
	global ThesaurusCheckAvailable:far
ThesaurusCode ends

C_ThesaurusCode segment resource
	global THESAURUSGETMEANINGS:far
	global THESAURUSGETSYNONYMS:far
C_ThesaurusCode ends

global thesaurusSem:hptr

;----------------------------------------------------------------------------
;			Code for Thesaurus Process Class
;----------------------------------------------------------------------------

include		thes.asm
include		thesC.asm
