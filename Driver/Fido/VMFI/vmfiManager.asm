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

	$Id: manager.asm,v 1.1 97/12/02 11:37:26 gene Exp $
	$Revision: 1.1 $

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
include vm.def
include chunkarr.def
include localize.def
include char.def
	
;%%%% Geode include files

DefDriver Internal/fidoiDr.def
include vmfi.def

;%%%% source files

include	vmfiStrategy.asm
include	vmfiMain.asm
