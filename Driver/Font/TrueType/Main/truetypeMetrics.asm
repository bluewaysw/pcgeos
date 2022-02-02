COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MetricsMod
FILE:		truetypeMetrics.asm

AUTHOR:		Falk Rehwagen, Jan  29, 2021

ROUTINES:
	Name			Description
	----			-----------
EXT	TrueTypeCharMetrics	Return character metric information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	29/ 1/21	Initial revision

DESCRIPTION:
	Routines for generating character metrics.

	$Id: truetypeMetrics.asm,v 1.1 97/04/18 11:45:29 bluewaysw Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrueTypeCharMetrics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return character metrics information in document coords.
CALLED BY:	DR_FONT_CHAR_METRICS - TrueTypeStrategy

PASS:		ds - seg addr of font info block
		es - seg addr of GState
			es:GS_fontAttr - font attributes
		dx - character to get metrics of
		cx - info to return (GCM_info)
RETURN:		if GCMI_ROUNDED set:
			dx - information (rounded)
		else:
			dx.ah - information (WBFixed)
		carry - set if error (eg. data / font not available)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	29/ 1/21	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TrueTypeCharMetrics	proc	far
	uses	bx, cx, si, di, ds
	.enter

	.leave
	ret
TrueTypeCharMetrics	endp
