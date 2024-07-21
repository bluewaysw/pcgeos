COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Library
FILE:		manager.asm

AUTHOR:		Paul DuBois, Nov 29, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/29/94   	Initial revision

DESCRIPTION:
	First Fido read driver

	$Revision:   1.0  $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%% Standard include files

include	geos.def
include	geode.def
include	resource.def
include	ec.def
include assert.def
include	driver.def
include	heap.def
include file.def
include char.def
include	Internal/heapInt.def

;%%%% Geode include files

DefDriver Internal/fidoiDr.def
include tfi.def

;%%%% source files

include	tfiStrategy.asm
include	tfiMain.asm
