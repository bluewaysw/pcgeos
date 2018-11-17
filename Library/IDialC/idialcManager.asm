COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) MyTurn.com 2000.  All rights reserved.
	MYTURN.COM CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		Internet Dialup Shortcut
FILE:		idialcManager.asm

AUTHOR:		David Hunter, Oct 15, 2000

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/15/00   	Initial revision

DESCRIPTION:
		Include-o-rama

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------
;	Include files
;----------------------------

include geos.def
include geode.def
include resource.def
include lmem.def
include heap.def
include object.def
include ec.def
include graphics.def
include gstring.def
include timer.def
include thread.def

UseLib ui.def
UseLib socket.def
include sockmisc.def
include Internal/ppp.def
include medium.def

include Objects/iDialCC.def
include idialConstant.def

include idialControl.rdef

;----------------------------

include idialControl.asm

;----------------------------

end

