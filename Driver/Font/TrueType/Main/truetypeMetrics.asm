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

resultAXDX	local	dword

	.enter

	push	dx		; character code
	push	ds		; ptr to fontInfo
	mov	bx, 0		; segment offset 0
	push	bx
	push	es		; ptr to gstate
	push	bx		; segment offset 0
	push	cx		; GCM_info

	push 	ss		; pass ptr to result dword in ss
	lea	cx, resultAXDX
	push	cx

	segmov	ds, dgroup, cx
	call	TRUETYPE_CHAR_METRICS

	clc
	cmp	ax, 0
	jnc	ok
	stc
ok:
	mov	ax, {word} resultAXDX
	mov	dx, {word} resultAXDX+2

	.leave
	ret
TrueTypeCharMetrics	endp
