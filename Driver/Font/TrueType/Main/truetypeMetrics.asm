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
	JK	09/02/24	width and weight implement

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TrueTypeCharMetrics	proc	far
	uses	bx, cx, si, di, ds

resultDXAX	local	dword

	.enter

	mov		si, cx
	push	dx		; pass character code
	push	cx		; pass GCM_info

	mov		cx, es:GS_fontAttr.FCA_fontID
	call	FontDrFindFontInfo
	push	ds		; pass ptr to FontInfo
	push	di
	
	clr		ah		                   
	mov		al, es:GS_fontAttr.FCA_textStyle
	mov		bx, ODF_HEADER
	call	FontDrFindOutlineData
	push	ds		; pass ptr to OutlineEntry
	push	di
	push	ax		; pass stylesToImplement

	clr		al
	movwbf	dxah, es:GS_fontAttr.FCA_pointsize
	push	dx		; pass point size
	push 	ax

	clr		ch
	mov		cl, es:GS_fontAttr.FCA_width
	push	cx		; pass width
	mov		cl, es:GS_fontAttr.FCA_weight
	push	cx		; pass wieght

	push 	ss		; pass ptr to result dword in ss
	lea		cx, resultDXAX
	push	cx

	segmov	ds, dgroup, cx
	push	ds:variableHandle
	call	TRUETYPE_CHAR_METRICS

	mov		ax, {word} resultDXAX
	mov		dx, {word} resultDXAX+2

	test 	si, GCMI_ROUNDED
	jnz		roundToInt
	rndwwbf dxax
done:
	clc
	.leave
	ret

roundToInt:
	rndwwf 	dxax
	jmp		done

TrueTypeCharMetrics	endp
