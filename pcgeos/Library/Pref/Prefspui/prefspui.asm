COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Prefspui
FILE:		prefspui.asm

AUTHOR:		Tony Requist, Sep 12, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	9/12/94		Initial revision
	dlitwin	9/27/94		made a manager file


DESCRIPTION:
	inlcudes all file for the Prefspui module

	$Id: prefspui.asm,v 1.1 97/04/05 01:42:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;------------------------------------------------------------------------------
;	Common GEODE stuff
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	library.def

include object.def
include	graphics.def
include gstring.def
include	win.def

include char.def
include initfile.def
include fileEnum.def

UseLib Objects/vTextC.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include prefspui.def
include prefspuiMacro.def
include prefspui.rdef

;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------

idata segment

idata ends

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------
 
PrefSpuiCode	segment resource

include	prefspuiDialog.asm
include prefspuiDynamicList.asm
include psDescriptiveDL.asm

PrefSpuiCode	ends
