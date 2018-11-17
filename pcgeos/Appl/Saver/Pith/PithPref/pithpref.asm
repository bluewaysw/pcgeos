COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pithpref.asm

AUTHOR:		Gene Anderson, Jun  3, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/ 3/93		Initial revision


DESCRIPTION:
	Saver-specific preferences for Pith & Moan

	$Id: pithpref.asm,v 1.1 97/04/04 16:48:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; include the standard suspects
include geos.def
include geode.def
include lmem.def
include object.def
include graphics.def
include gstring.def
UseLib	ui.def

include	vmdef.def		; contains macros that allow us to create a
				;  VM file in this way.
UseLib config.def		; Most objects we use come from here
UseLib saver.def		; Might need some of the constants from
				;  here, though we can't use objects from here.

;
; Define the VMAttributes used for the file.
;
ATTRIBUTES	equ	PREFVM_ATTRIBUTES

;
; Include constants from Qix, the saver, for use in our objects.
;
include ../pith.def

;
; Now the object tree.
; 
include	pithpref.rdef

;
; Define the map block for the VM file, which Preferences will use to get
; to the root of the tree we hold.
; 
DefVMBlock	MapBlock
PrefVMMapBlock	<RootObject>
EndVMBlock	MapBlock
