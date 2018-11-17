COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1999 -- All Rights Reserved

PROJECT:	GeoSafari
FILE:		safari.asm

AUTHOR:		Gene Anderson

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/3/99		Initial revision

DESCRIPTION:
	Code for IndicatorClass, SpacerClass

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include ec.def
include timer.def
include heap.def

UseLib	safari.def

include safariConstant.def
include safariGeode.def

include safari.rdef

InitCode	segment	resource

SafariEntry	proc	far
	clc
	ret
SafariEntry	endp

InitCode	ends
