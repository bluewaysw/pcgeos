COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		clockLocationList.asm

AUTHOR:		Adam de Boor, Mar  8, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/ 8/92		Initial revision


DESCRIPTION:
	Special subclass to put beautiful monitor around the list items in
	the clock-location list.
		

	$Id: clockLocationList.asm,v 1.1 97/04/04 14:50:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include	clock.def
include Internal/grWinInt.def

idata	segment
	ClockLocationListClass
idata	ends

LocationListCode	segment	resource

CLLRegion	struct
    CLLR_color	Color
    CLLR_mask	SystemDrawMask
    CLLR_region	nptr.Rectangle
CLLRegion	ends

CLLRegionSet	struct
    CLLRS_margins	Rectangle
    CLLRS_numRegions	word
    CLLRS_regions	label	CLLRegion
CLLRegionSet	ends

;==============================================================================
;
;			    Color Regions
;
;==============================================================================
;
; Region definitions, lower-right corner is (param_2, param_3)
;

ltCyanRegion	Rectangle	<0, 0, PARAM_2, PARAM_3>
	word	-1,
			EOREGREC		; nothing till onscreen
	word	0,
			2, PARAM_2-2,
			EOREGREC
	word	1,
			1, 1,
			PARAM_2-1, PARAM_2-1,
			EOREGREC
	word	5,
			0, 0,
			EOREGREC
	word	PARAM_3-13,
			0, 0,
			PARAM_2-6, PARAM_2-6,
			EOREGREC
	word	PARAM_3-12,
			0, 0,
			PARAM_2-7, PARAM_2-7,
			EOREGREC
	word	PARAM_3-11,
			0, 0,
			8, PARAM_2-8,
			EOREGREC
	word	PARAM_3-8,
			0, 0,
			EOREGREC
	word	PARAM_3-4,
			EOREGREC
	word	PARAM_3-3,
			24, 24,
			EOREGREC
	word	PARAM_3-2,
			16, 23,
			EOREGREC
	word	PARAM_3-1,
			15, 15,
			EOREGREC
	word	PARAM_3-0,
			14, 14,
			EOREGREC
	word	EOREGREC

dkCyanRegion	Rectangle	<0, 0, PARAM_2, PARAM_3>
	word	0,
			EOREGREC		; nothing till onscreen
	word	1,
			2, PARAM_2-2,
			EOREGREC
	word	3,
			1, PARAM_2-1,
			EOREGREC
	word	4,
			1, 7,
			PARAM_2-7, PARAM_2-1,
			EOREGREC
	word	5,
			1, 6,
			PARAM_2-6, PARAM_2-1,
			EOREGREC
	word	PARAM_3-13,
			1, 5,
			PARAM_2-5, PARAM_2-1,
			EOREGREC
	word	PARAM_3-12,
			1, 6,
			PARAM_2-6, PARAM_2-1,
			EOREGREC
	word	PARAM_3-11,
			1, 7,
			PARAM_2-7, PARAM_2-1,
			EOREGREC
	word	PARAM_3-10,
			1, PARAM_2-1,
			EOREGREC
	word	PARAM_3-8,
			1, 8,
			11, 12,
			15, 16,
			19, PARAM_2-11,
			PARAM_2-8, PARAM_2-1,
			EOREGREC
	word	PARAM_3-7,
			2, PARAM_2-2,
			EOREGREC
	word	PARAM_3-5,
			EOREGREC
	word	PARAM_3-4,
			28, PARAM_2-26,
			EOREGREC
	word	PARAM_3-3,
			25, PARAM_2-25,
			EOREGREC
	word	PARAM_3-2,
			24, PARAM_2-24,
			EOREGREC
	word	PARAM_3-1,
			16, PARAM_2-16,
			EOREGREC
	word	EOREGREC

blackRegion	Rectangle	<0, 0, PARAM_2, PARAM_3>
	word	1,
			EOREGREC		; nothing till onscreen
	word	3,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	4,
			8, PARAM_2-8,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	5,
			7, PARAM_2-7,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	6,
			6, PARAM_2-6,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-15,
			6, 8,
			PARAM_2-8, PARAM_2-7,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-13,
			6, PARAM_2-7,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-12,
			7, PARAM_2-8,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-10,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-8,
			9, 10,
			13, 14,
			17, 18,
			PARAM_2-10, PARAM_2-9,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-7,
			1, 1,
			PARAM_2-1, PARAM_2-1,
			EOREGREC
	word	PARAM_3-6,
			2, PARAM_2-2,
			EOREGREC
	word	PARAM_3-4,
			25, 25,
			PARAM_2-25, PARAM_2-25,
			EOREGREC
	word	PARAM_3-3,
			PARAM_2-24, PARAM_2-24,
			EOREGREC
	word	PARAM_3-2,
			PARAM_2-23, PARAM_2-16,
			EOREGREC
	word	PARAM_3-1,
			PARAM_2-15, PARAM_2-15,
			EOREGREC
	word	PARAM_3-0,
			15, PARAM_2-14,
			EOREGREC
	word	EOREGREC

dkGreyRegion	Rectangle	<0, 0, PARAM_2, PARAM_3>
	word	PARAM_3-6,
			EOREGREC		; nothing till onscreen
	word	PARAM_3-5,
			26, PARAM_2-26,
			EOREGREC
	word	PARAM_3-4,
			26, 27,
			EOREGREC
	word	EOREGREC
			
colorRegionSet	CLLRegionSet	<
	<
		9,		; left margin
		7,		; top margin
		9,		; right margin
		14		; bottom margin
	>,
	length colorRegionList
>
colorRegionList	CLLRegion	\
	<C_CYAN, SDM_100, dkCyanRegion>,
	<C_LIGHT_CYAN, SDM_100, ltCyanRegion>,
	<C_BLACK, SDM_100, blackRegion>,
	<C_DARK_GREY, SDM_100, dkGreyRegion>

;==============================================================================
;
;			Standard Mono Regions
;
;==============================================================================
smBlackRegion	Rectangle	<0, 0, PARAM_2, PARAM_3>
	word	-1,
			EOREGREC
	word	0, 
			2, PARAM_2-2,
			EOREGREC
	word	1,
			1, 1,
			PARAM_2-1, PARAM_2-1,
			EOREGREC
	word	4,
			0, 0,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	5,
			0, 0,
			8, PARAM_2-8,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	6,
			0, 0,
			7, PARAM_2-7,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	7,
			0, 0,
			6, PARAM_2-6,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-14,
			0, 0,
			6, 8,
			PARAM_2-8, PARAM_2-6,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-13,
			0, 0,
			6, PARAM_2-6,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-12,
			0, 0,
			7, PARAM_2-7,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-11,
			0, 0,
			8, PARAM_2-8,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-10,
			0, 0,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-8,
			0, 0,
			9, 10,
			13, 14,
			17, 18,
			PARAM_2-11, PARAM_2-10,
			PARAM_2-0, PARAM_2-0,
			EOREGREC
	word	PARAM_3-7,
			1, 1,
			PARAM_2-1, PARAM_2-1,
			EOREGREC
	word	PARAM_3-6, 
			2, PARAM_2-2,
			EOREGREC
	word	PARAM_3-5,
			23, PARAM_2-25,
			EOREGREC
	word	PARAM_3-4,
			23, 25,
			PARAM_2-25, PARAM_2-25,
			EOREGREC
	word	PARAM_3-3,
			22, 22,
			PARAM_2-24, PARAM_2-24,
			EOREGREC
	word	PARAM_3-2,
			14, 21,
			PARAM_2-23, PARAM_2-16,
			EOREGREC
	word	PARAM_3-1,
			13, 13,
			PARAM_2-15, PARAM_2-15,
			EOREGREC
	word	PARAM_3-0,
			12, PARAM_2-14,
			EOREGREC
	word	EOREGREC

smWhiteRegion	Rectangle	<0, 0, PARAM_2, PARAM_3>
	word	0,
			EOREGREC
	word	1,
			2, PARAM_2-2,
			EOREGREC
	word	4,
			1, PARAM_2-1,
			EOREGREC
	word	5,
			1, 7,
			PARAM_2-7, PARAM_2-1,
			EOREGREC
	word	6,
			1, 6,
			PARAM_2-6, PARAM_2-1,
			EOREGREC
	word	PARAM_3-13,
			1, 5,
			PARAM_2-5, PARAM_2-1,
			EOREGREC
	word	PARAM_3-12,
			1, 6,
			PARAM_2-6, PARAM_2-1,
			EOREGREC
	word	PARAM_3-11,
			1, 7,
			PARAM_2-7, PARAM_2-1,
			EOREGREC
	word	PARAM_3-10,
			1, PARAM_2-1,
			EOREGREC
	word	PARAM_3-8,
			1, 8,
			11, 12,
			15, 16,
			19, PARAM_2-12,
			PARAM_2-9, PARAM_2-1,
			EOREGREC
	word	PARAM_3-7,
			2, PARAM_2-2,
			EOREGREC
	word	PARAM_3-5,
			EOREGREC
	word	PARAM_3-4,
			26, PARAM_2-26,
			EOREGREC
	word	PARAM_3-3,
			23, PARAM_2-25,
			EOREGREC
	word	PARAM_3-2,
			22, PARAM_2-24,
			EOREGREC
	word	PARAM_3-1,
			14, PARAM_2-16,
			EOREGREC
	word	EOREGREC

sm50BlackRegion	Rectangle	<0, 0, PARAM_2, PARAM_3>
	word	1,
			EOREGREC
	word	2,
			3, PARAM_2-1,
			EOREGREC
	word	4,
			2, PARAM_2-1,
			EOREGREC
	word	5,
			2, 7,
			PARAM_2-6, PARAM_2-1,
			EOREGREC
	word	6,
			2, 6,
			PARAM_2-5, PARAM_2-1,
			EOREGREC
	word	PARAM_3-13,
			2, 5,
			PARAM_2-4, PARAM_2-1,
			EOREGREC
	word	PARAM_3-12,
			2, 6,
			PARAM_2-5, PARAM_2-1,
			EOREGREC
	word	PARAM_3-11,
			2, 6,
			PARAM_2-6, PARAM_2-1,
			EOREGREC
	word	PARAM_3-10,
			2, 7,
			PARAM_2-7, PARAM_2-1,
			EOREGREC
	word	PARAM_3-8,
			2, 8,
			11, 12,
			15, 16,
			19, PARAM_2-12,
			PARAM_2-9, PARAM_2-1,
			EOREGREC
	word	PARAM_3-7,
			2, PARAM_2-2,
			EOREGREC
	word	PARAM_3-5,
			EOREGREC
	word	PARAM_3-4,
			26, PARAM_2-26,
			EOREGREC
	word	PARAM_3-3,
			25, PARAM_2-25,
			EOREGREC
	word	PARAM_3-2,
			24, PARAM_2-24,
			EOREGREC
	word	PARAM_3-1,
			23, PARAM_2-16,
			EOREGREC
	word	EOREGREC

monoRegionSet	CLLRegionSet	<
	<
		9,		; left margin
		8,		; top margin
		9,		; right margin
		14		; bottom margin
	>,
	length monoRegionList
>
monoRegionList	CLLRegion	\
	<C_BLACK, SDM_100, smBlackRegion>,
	<C_WHITE, SDM_100, smWhiteRegion>,
	<C_BLACK, SDM_50, sm50BlackRegion>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CLLGetMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the margins for our lovely regions.

CALLED BY:	MSG_VIS_COMP_GET_MARGINS
PASS:		*ds:si	= ClockLocationList object
RETURN:		ax	= left margin
		bp	= top margin
		cx	= right margin
		dx	= bottom margin
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CLLGetMargins	method dynamic ClockLocationListClass, MSG_VIS_COMP_GET_MARGINS
		.enter
		mov	bx, ds:[di].CLLI_regionSet
		mov	ax, cs:[bx].CLLRS_margins.R_left
		mov	bp, cs:[bx].CLLRS_margins.R_top
		mov	cx, cs:[bx].CLLRS_margins.R_right
		mov	dx, cs:[bx].CLLRS_margins.R_bottom
		.leave
		ret
CLLGetMargins	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CLLGetSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return simple spacing requirements w/o margins or anything
		funky like that.

CALLED BY:	MSG_VIS_COMP_GET_CHILD_SPACING
PASS:		*ds:si	= ClockLocationList object
RETURN:		cx	= spacing between children
		dx	= spacing between lines of wrapping children
DESTROYED:	

PSEUDO CODE/STRATEGY:
		return 0 for everything, as we want it all packed tight.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CLLGetSpacing 	method dynamic ClockLocationListClass, 
				MSG_VIS_COMP_GET_CHILD_SPACING
		.enter
		clr	cx, dx
		.leave
		ret
CLLGetSpacing	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CLLDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw ourselves and our kids.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= ClockLocationList object
		bp	= gstate to use
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CLLDraw		method dynamic ClockLocationListClass, MSG_VIS_DRAW
		.enter
	;
	; Draw our children first.
	; 
		push	bp
		mov	di, offset ClockLocationListClass
		call	ObjCallSuperNoLock
	;
	; Now draw ourselves.
	; 
		pop	di
		call	VisGetBounds
		sub	cx, ax
		sub	dx, bx
		
		mov	bp, ds:[si]
		add	bp, ds:[bp].ClockLocationList_offset
		mov	si, ds:[bp].CLLI_regionSet
		segmov	ds, cs
		
		mov	bp, ds:[si].CLLRS_numRegions
		add	si, offset CLLRS_regions
regionLoop:
	;
	; Set the area color first.
	; 
		push	ax
		mov	ah, CF_INDEX
		mov	al, ds:[si].CLLR_color
		call	GrSetAreaColor
	;
	; Then the area mask.
	; 
		mov	al, ds:[si].CLLR_mask
		call	GrSetAreaMask
		pop	ax
	;
	; Now draw the region itself, anchored at our upper-left corner.
	; 
		push	si
		mov	si, ds:[si].CLLR_region
		call	GrDrawRegion
		pop	si
		add	si, size CLLRegion
		dec	bp
		jnz	regionLoop
	;
	; Make sure draw mask is back to 100, so we don't confuse other things
	; 
		mov	al, SDM_100
		call	GrSetAreaMask
		.leave
		ret
CLLDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CLLBypassSPUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Obtain behaviour from VisCompClass, rather than what the
		specific UI wants to do, for various geometry-related
		messages

CALLED BY:	MSG_VIS_RECALC_SIZE, MSG_VIS_POSITION_BRANCH
PASS:		*ds:si	= our object
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CLLBypassSPUI	method dynamic ClockLocationListClass, MSG_VIS_RECALC_SIZE,
					MSG_VIS_POSITION_BRANCH
		segmov	es, <segment VisCompClass>, di
		mov	di, offset VisCompClass
		GOTO	ObjCallClassNoLock
CLLBypassSPUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CLLSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mess with the Vis flags to be sure we get all the calls we
		need.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= ClockLocationList object
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CLLSpecBuild	method dynamic ClockLocationListClass, MSG_SPEC_BUILD
		.enter
	;
	; Do normal build stuff.
	; 
		mov	di, offset ClockLocationListClass
		call	ObjCallSuperNoLock
	;
	; Now figure the region set we want to use.
	; 
		call	UserGetDisplayType	; ah <- display type
		mov	al, ah
		andnf	al, mask DT_DISP_CLASS
		
		mov	bx, offset colorRegionSet
			CheckHack <DC_COLOR_4 gt DC_COLOR_2 and \
				   DC_COLOR_8 gt DC_COLOR_2 and \
				   DC_CF_RGB gt DC_COLOR_2>
		cmp	al, DC_COLOR_2 shl offset DT_DISP_CLASS
		jae	haveSet
		
		mov	bx, offset monoRegionSet
haveSet:
		mov	di, ds:[si]
		add	di, ds:[di].ClockLocationList_offset
		mov	ds:[di].CLLI_regionSet, bx

		.leave
		ret
CLLSpecBuild	endm
LocationListCode	ends

