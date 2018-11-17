COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgroupAttrs.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------
	SET_CHART_TYPE		Set the chart type and variation.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/18/91	Initial Revision  

DESCRIPTION:
	Code for changing the chart type.

	$Id: cgroupAttrs.asm,v 1.1 97/04/04 17:45:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupSetChartType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the chart type and variation

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.
		cl 	= ChartType
		ch 	= ChartVariation

RETURN:		nothing 

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/16/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupSetChartType	method	dynamic	ChartGroupClass, 
					MSG_CHART_GROUP_SET_CHART_TYPE
		uses	cx,dx,bp
		.enter
		

	;
	; Save the old chart type & variation
	;
		push	{word} ds:[di].CGI_type
		push	ds:[di].CGI_flags		
	;	
	; Set flags based on type/variation
	;
		call	ChartGroupResolveAttributes
		
	;
	; Figure out how the new type differs from the old
	;
		
		call	ChartGroupCalculateChanges
		
	;
	; Now, save the new type, and the change flags
	;
		
		mov	ds:[di].CGI_type, cl
		mov	ds:[di].CGI_variation, ch
		mov	ds:[di].CGI_flags, dx

	;
	; If we already have a data block, then make sure this chart
	; type change is legal.
	;
		tst	ds:[di].CGI_data
		jz	ok

		
	;
	; Since ChartGroupSetDataAttributes depends on the chart type,
	; call it again
	;
		call	ChartGroupSetDataAttributes


	;
	; Now, check that the data is valid for this type.
	;
		
		call	ChartGroupCheckData
		cmp	al, CRT_OK
		jne	bogus

ok:
		pop	ax, ax			; remove old flags, type
		ornf	ds:[di].CGI_buildChangeFlags, bp

done:

		mov	cx, CHART_UPDATE_ALL_UI
		call	UtilUpdateUI
		
		.leave
		ret
bogus:

	;
	; Chart type can't be changed, so change it back
	;
		pop	ds:[di].CGI_flags
		pop	{word}	ds:[di].CGI_type
		jmp	done
		
ChartGroupSetChartType	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupCalculateChanges
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine what differences the new/old types,
		variations, flags will cause

CALLED BY:	ChartGroupSetChartType

PASS:		cl - new type,
		ch - new variation,
		dx - new flags

		ds:di - ChartGroup
			 - instance data contains old
			   type/variation/flags 

RETURN:		bp - BuildChangeFlags

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupCalculateChanges	proc near
	class	ChartGroupClass 

	uses	cx, dx

	.enter

	clr	bp		; BuildChangeFlags

	mov	al, cl		; new type
	mov	ah, ds:[di].CGI_type

	cmp	al, ah
	je	afterTypeChange

	BitSet	bp, BCF_CHART_TYPE

	; Basically, there is a table of changes -- if the right
	; old/new combination is found in the table, then the offset
	; to that entry is used to locate the appropriate bit to set.
	; Since new/old combinations are identical to old/new, we
	; reverse the bits, and try again as well.

	; Look for the right combination in the table

	push	es
	segmov	es, cs
	call	LookupTableAndSetBP
	xchg	al, ah
	call	LookupTableAndSetBP
	pop	es

	jmp	done

afterTypeChange:
	cmp	ch, ds:[di].CGI_variation
	je	done
	BitSet	bp, BCF_CHART_VARIATION

	;
	; For chart variation changes, we use the ChartFlags to
	; determine which BuildChangeFlags to set
	;

	push	cx
	mov	ax, ds:[di].CGI_flags	; old flags
	mov	bx, mask CF_SINGLE_COLOR or mask CF_SERIES_TITLES or \
				mask CF_CATEGORY_TITLES or mask CF_VALUES
	mov	cx, mask BCF_CHART_VARIATION_ATTR
	call	SetBuildChangeFlagIfChartFlagChanged
	pop	cx

ifdef	SPIDER_CHART
	; 
	; For any variation of spider charts, nuke axis and series data
	;

	cmp	cl, CT_SPIDER
	jne	notSpider
	ornf	bp, mask BCF_CHART_VARIATION_ATTR
	ornf	bp, mask BCF_AXIS_REMOVE
notSpider:

endif	; SPIDER_CHART

	;
	; For *ANY* Variation change in the line or scatter charts,
	; nuke the series data
	;

	cmp	cl, CT_LINE
	je	nukeSeries
	cmp	cl, CT_SCATTER
	jne	done

nukeSeries:
	ornf	bp, mask BCF_CHART_VARIATION_ATTR

done:
	.leave
	ret
ChartGroupCalculateChanges	endp


ChartFlagChangeTableEntry	struct
	CFCTE_chartFlags	ChartFlags
	CFCTE_buildChangeFlags	BuildChangeFlags
ChartFlagChangeTableEntry	ends




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBuildChangeFlagIfChartFlagChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the ChartFlags changed, then set the appropriate 
		BuildChangeFlag

CALLED BY:	ChartGroupCalculateChanges

PASS:		ax - OLD ChartFlags
		bx - flag to check 
		cx - flag(s) to set in BP
		dx - NEW ChartFlags
		bp - old BuildChangeFlags

RETURN:		bp - updated BuildChangeFlags

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBuildChangeFlagIfChartFlagChanged	proc near
	.enter
	xor	ax, dx		; get diffs
	test	ax, bx		; see if the interesting bit changed
	jz	done
	or	bp, cx		; set the new bit in BP
done:
	.leave
	ret
SetBuildChangeFlagIfChartFlagChanged	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LookupTableAndSetBP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lookup the passed old/new combination in the table,
		and, if found, set the appropriate bit in the
		BuildChangeFlags. 

CALLED BY:	ChartGroupCalculateChanges

PASS:		ax - old/new (or new/old) combination
		bp - original BuildChangeFlags
		es = cs

RETURN:		bp - new BuildChangeFlags

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LookupTableAndSetBP	proc near
	uses	cx,di
	.enter

	mov	di, offset TypeChangeTable
	mov	cx, length TypeChangeTable
	repne	scasw
	jne	done

	; DI is pointing one word AFTER the word we want

	add	di, (offset FlagTable - offset TypeChangeTable - size word)
	or	bp, {word} cs:[di]
done:
	.leave
	ret
LookupTableAndSetBP	endp



TypeChangeEntry	struct
	TCE_first	ChartType
	TCE_second	ChartType
TypeChangeEntry	ends

ifdef	SPIDER_CHART
TypeChangeTable	TypeChangeEntry	\
	<CT_COLUMN,CT_BAR>,
	<CT_LINE, CT_BAR>,
	<CT_AREA, CT_BAR>,
	<CT_HIGH_LOW, CT_BAR>,

	<CT_BAR, CT_SCATTER>,
	<CT_COLUMN,CT_SCATTER>,
	<CT_LINE, CT_SCATTER>,
	<CT_AREA, CT_SCATTER>,
	<CT_HIGH_LOW, CT_SCATTER>,

	<CT_COLUMN,CT_PIE>,
	<CT_BAR, CT_PIE>,
	<CT_LINE, CT_PIE>,
	<CT_AREA, CT_PIE>,
	<CT_SCATTER, CT_PIE>,
	<CT_HIGH_LOW, CT_PIE>,

	<CT_COLUMN,CT_LINE>,
	<CT_BAR, CT_LINE>,
	<CT_AREA, CT_LINE>,
	<CT_PIE, CT_LINE>,

	<CT_COLUMN,CT_SCATTER>,
	<CT_BAR, CT_SCATTER>,
	<CT_AREA, CT_SCATTER>,
	<CT_PIE, CT_SCATTER>,

	<CT_COLUMN, CT_SPIDER>,
	<CT_BAR, CT_SPIDER>,
	<CT_LINE, CT_SPIDER>,
	<CT_AREA, CT_SPIDER>,
	<CT_SCATTER, CT_SPIDER>,
	<CT_HIGH_LOW, CT_SPIDER>,

	<CT_SPIDER, CT_COLUMN>,
	<CT_SPIDER, CT_BAR>,
	<CT_SPIDER, CT_LINE>,
	<CT_SPIDER, CT_AREA>,
	<CT_SPIDER, CT_SCATTER>,
	<CT_SPIDER, CT_PIE>,
	<CT_SPIDER, CT_HIGH_LOW>

FlagTable	BuildChangeFlags	\
	mask BCF_AXIS_ROTATE,
	mask BCF_AXIS_ROTATE,
	mask BCF_AXIS_ROTATE,
	mask BCF_AXIS_ROTATE,

	mask BCF_AXIS_REMOVE,	
	mask BCF_AXIS_REMOVE,	
	mask BCF_AXIS_REMOVE,	
	mask BCF_AXIS_REMOVE,	
	mask BCF_AXIS_REMOVE,	

	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,

	mask BCF_LEGEND_PICTURE,
	mask BCF_LEGEND_PICTURE,
	mask BCF_LEGEND_PICTURE,
	mask BCF_LEGEND_PICTURE,

	mask BCF_LEGEND_PICTURE,
	mask BCF_LEGEND_PICTURE,
	mask BCF_LEGEND_PICTURE,
	mask BCF_LEGEND_PICTURE,

	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,

	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE
.assert	(length FlagTable eq length TypeChangeTable)

else	; SPIDER_CHART

TypeChangeTable	TypeChangeEntry	\
	<CT_COLUMN,CT_BAR>,
	<CT_LINE, CT_BAR>,
	<CT_AREA, CT_BAR>,
	<CT_HIGH_LOW, CT_BAR>,

	<CT_BAR, CT_SCATTER>,
	<CT_COLUMN,CT_SCATTER>,
	<CT_LINE, CT_SCATTER>,
	<CT_AREA, CT_SCATTER>,
	<CT_HIGH_LOW, CT_SCATTER>,

	<CT_COLUMN,CT_PIE>,
	<CT_BAR, CT_PIE>,
	<CT_LINE, CT_PIE>,
	<CT_AREA, CT_PIE>,
	<CT_SCATTER, CT_PIE>,
	<CT_HIGH_LOW, CT_PIE>,

	<CT_COLUMN,CT_LINE>,
	<CT_BAR, CT_LINE>,
	<CT_AREA, CT_LINE>,
	<CT_PIE, CT_LINE>,

	<CT_COLUMN,CT_SCATTER>,
	<CT_BAR, CT_SCATTER>,
	<CT_AREA, CT_SCATTER>,
	<CT_PIE, CT_SCATTER>

FlagTable	BuildChangeFlags	\
	mask BCF_AXIS_ROTATE,
	mask BCF_AXIS_ROTATE,
	mask BCF_AXIS_ROTATE,
	mask BCF_AXIS_ROTATE,

	mask BCF_AXIS_REMOVE,	
	mask BCF_AXIS_REMOVE,	
	mask BCF_AXIS_REMOVE,	
	mask BCF_AXIS_REMOVE,	
	mask BCF_AXIS_REMOVE,	

	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,
	mask BCF_AXIS_REMOVE,

	mask BCF_LEGEND_PICTURE,
	mask BCF_LEGEND_PICTURE,
	mask BCF_LEGEND_PICTURE,
	mask BCF_LEGEND_PICTURE,

	mask BCF_LEGEND_PICTURE,
	mask BCF_LEGEND_PICTURE,
	mask BCF_LEGEND_PICTURE,
	mask BCF_LEGEND_PICTURE

.assert	(length FlagTable eq length TypeChangeTable)
endif	; SPIDER_CHART


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupCombineChartType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.
		cl, ch - ChartType, ChartVariation
		bp - TraverseFlag

RETURN:		cl, ch - ChartType, ChartVariation
		bp - TraverseFlag

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	If TraverseFlag is zero, then set cl and ch to this object's
	values.  Otherwise:

	If chart type is same
		if chart variation is same
			return CX unchanged, carry clear
		else
			set CH = -1, carry clear
	ELSE
		set CX = -1, set carry	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/30/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupCombineChartType	method	dynamic	ChartGroupClass, 
					MSG_CHART_GROUP_COMBINE_CHART_TYPE
	.enter
	call	UtilStartCombine

	push	di
	lea	si, ds:[di].CGI_type
	mov	di, offset TNB_type
	call	UtilCombineEtype
	pop	di

	lea	si, ds:[di].CGI_variation
	mov	di, offset TNB_variation
	call	UtilCombineEtype

	call	UtilEndCombine
	.leave
	ret
ChartGroupCombineChartType	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupSetGridFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.

		cl	= GridFlags that are set
		bp	- GridFlags that have changed

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupSetGridFlags	method	dynamic	ChartGroupClass, 
					MSG_CHART_GROUP_SET_GRID_FLAGS
	uses	ax,cx
	.enter
	lea	bx, ds:[di].CGI_gridFlags
	call	SetDataFromBoolean
	tst	al
	jz	done			; no change


	; Tell the series group that it needs to redraw itself

	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	mov	cl, mask COS_IMAGE_INVALID
	mov	si, offset TemplateSeriesGroup
	call	ObjCallInstanceNoLock

	;
	; Update the UI
	;

	mov	cx, mask CUUIF_GROUP_FLAGS
	call	UtilUpdateUI
done:
	.leave
	ret
ChartGroupSetGridFlags	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGetGridFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.

RETURN:		cl - grid flags

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupGetGridFlags	method	dynamic	ChartGroupClass, 
					MSG_CHART_GROUP_GET_GRID_FLAGS
	mov	cl, ds:[di].CGI_gridFlags
	ret
ChartGroupGetGridFlags	endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDataFromBoolean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set instance data in the chart group from an 8-bit non
		exclusive list

CALLED BY:

PASS:		ds:bx - address of attribute data to change
		cl - bits that are SET
		bp - bits that have CHANGED

RETURN:		cl - bits as they now are in the record
		Zero flag set if nothing changed
		al - bits that have changed

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	"or" in the bits that have become SET
	"and" out the bits that have become CLEAR

	return the differences

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDataFromBoolean	proc near	
	.enter
	mov	al, ds:[bx]		; original bits


	;
	; OR in the bits that have become SET
	;

	push	cx
	and	cx, bp
	or	ds:[bx], cl		; or-in the set bits


	;
	; AND out the bits that have become CLEAR
	;

	pop	cx
	not	cl
	and	cx, bp
	not	cl
	and	ds:[bx], cl

	;
	; Return the changes
	;

	xor	al, ds:[bx] 			; al - bits that are different

	.leave
	ret
SetDataFromBoolean	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupResolveAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some checking on the attributes, making sure all
		the right bits are set, etc.

CALLED BY:	many places

PASS:		ds:di - ChartGroup object
		cl - chart type
		ch - chart variation

RETURN:		ch - chart variation (if value passed was invalid)
		dx - new ChartFlags

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Force the variation to be legal for the chart type
	Force the flags to be legal for the chart type/variation.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/20/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupResolveAttributes	proc near	
	uses	ax, bx
	class	ChartGroupClass 

	.enter

	; Force variation to be legal

	mov	bl, cl
	clr	bh
	mov	ax, cs:MaxChartVariationTable[bx]
	cmp	al, ch
	jge	setFlags
	clr	ch		; if not legal, force to "standard"

setFlags:

	clr	dx		; No flags initially
	; 
	; Look up the table to use in the "meta" table

	mov	bx, cs:SetFlagsMetaTable[bx]	

	; Add chart variation to the table offset

	mov	al, ch
	clr	ah
	add	bx, ax

	; store new chart flags in DX

	mov	dx, cs:[bx]

	.leave
	ret
ChartGroupResolveAttributes	endp


;-----------------------------------------------------------------------------
; This table contains the maximum value for each of the chart types.
; It is a word because most of the other jump tables for ChartType are
; a word (allows type to be defined as etype,0,2).
;-----------------------------------------------------------------------------

ifdef	SPIDER_CHART 
MaxChartVariationTable word \
	ChartColumnVariation,
	ChartBarVariation,
	ChartLineVariation,
	ChartAreaVariation,
	ChartScatterVariation,
	ChartPieVariation,
	ChartHighLowVariation,
	ChartSpiderVariation

SetFlagsMetaTable	word \
	offset	SetFlagsColumnTable,
	offset	SetFlagsColumnTable,
	offset	SetFlagsLineTable,
	offset	SetFlagsAreaTable,
	offset	SetFlagsScatterTable,
	offset	SetFlagsPieTable,
	offset  SetFlagsHighLowTable,
	offset 	SetFlagsSpiderTable
else	;SPIDER_CHART
MaxChartVariationTable word \
	ChartColumnVariation,
	ChartBarVariation,
	ChartLineVariation,
	ChartAreaVariation,
	ChartScatterVariation,
	ChartPieVariation,
	ChartHighLowVariation

SetFlagsMetaTable	word \
	offset	SetFlagsColumnTable,
	offset	SetFlagsColumnTable,
	offset	SetFlagsLineTable,
	offset	SetFlagsAreaTable,
	offset	SetFlagsScatterTable,
	offset	SetFlagsPieTable,
	offset  SetFlagsHighLowTable
endif	;SPIDER_CHART

SetFlagsColumnTable	word \
	mask CF_CATEGORY_MARGIN,
	mask CF_CATEGORY_MARGIN,
	mask CF_CATEGORY_MARGIN or mask CF_STACKED,
	mask CF_CATEGORY_MARGIN or mask CF_FULL or mask CF_STACKED \
		or mask CF_PERCENT,
	mask CF_CATEGORY_MARGIN or mask CF_SINGLE_COLOR or mask CF_VALUES,
	mask CF_SINGLE_COLOR or mask CF_VALUES

SetFlagsLineTable	word \
	mask CF_LINES or mask CF_MARKERS,
	mask CF_LINES,
	mask CF_MARKERS,
	mask CF_MARKERS or mask CF_DROP_LINES

SetFlagsAreaTable	word \
	mask CF_STACKED,
	mask CF_STACKED or mask CF_FULL or mask CF_PERCENT,
	mask CF_STACKED or mask CF_DROP_LINES,
	mask CF_STACKED or mask CF_SERIES_TITLES

SetFlagsScatterTable	word \
	mask CF_LINES or mask CF_MARKERS,
	mask CF_LINES,
	mask CF_MARKERS

SetFlagsPieTable	word	\
	mask CF_ONE_SERIES_OBJECT_PER_CATEGORY or \
		mask CF_STACKED or mask CF_SINGLE_SERIES, 
	mask CF_ONE_SERIES_OBJECT_PER_CATEGORY or \
		mask CF_STACKED or mask CF_SINGLE_SERIES or \
		mask CF_CATEGORY_TITLES, 
	mask CF_ONE_SERIES_OBJECT_PER_CATEGORY or \
		mask CF_STACKED or mask CF_SINGLE_SERIES or \
		mask CF_SINGLE_COLOR or mask CF_CATEGORY_TITLES,
	mask CF_ONE_SERIES_OBJECT_PER_CATEGORY or \
		mask CF_STACKED or mask CF_SINGLE_SERIES, 
	mask CF_ONE_SERIES_OBJECT_PER_CATEGORY or \
		mask CF_STACKED or mask CF_SINGLE_SERIES, 
	mask CF_ONE_SERIES_OBJECT_PER_CATEGORY or \
		mask CF_STACKED or mask CF_SINGLE_SERIES or mask CF_FULL \
		or mask CF_PERCENT or mask CF_VALUES

SetFlagsHighLowTable	word	\
	mask CF_ONE_SERIES_OBJECT_PER_CATEGORY

ifdef	SPIDER_CHART
SetFlagsSpiderTable	word	\
	mask CF_LINES or mask CF_MARKERS,
	mask CF_LINES or mask CF_MARKERS or mask CF_CATEGORY_TITLES,
	mask CF_MARKERS or mask CF_CATEGORY_TITLES,
	mask CF_LINES or mask CF_CATEGORY_TITLES,
	mask CF_MARKERS,
	mask CF_LINES
endif	; SPIDER_CHART

.assert size SetFlagsColumnTable eq ChartColumnVariation, <wrong size>
.assert size SetFlagsLineTable eq ChartLineVariation, <wrong size>
.assert size SetFlagsAreaTable eq ChartAreaVariation, <wrong size>
.assert size SetFlagsScatterTable eq ChartScatterVariation, <wrong size>
.assert size SetFlagsPieTable eq ChartPieVariation, <wrong size>
.assert size SetFlagsHighLowTable eq ChartHighLowVariation, <wrong size>
ifdef	SPIDER_CHART
.assert size SetFlagsSpiderTable eq ChartSpiderVariation, <wrong size>
endif	; SPIDER_CHART
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupSetGroupFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set group flags

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.
		cl	= ChartGroupFlags to set
		ch 	- ChartGroupFlags to reset

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupSetGroupFlags	method	dynamic	ChartGroupClass, 
					MSG_CHART_GROUP_SET_GROUP_FLAGS
	uses	ax,cx,dx,bp
	.enter

	;
	; Fetch the old flags, or in the SET ones, AND out the CLEAR
	; ones. 
	;

	mov	al, ds:[di].CGI_groupFlags
	ornf	ds:[di].CGI_groupFlags, cl
	not	ch
	andnf	ds:[di].CGI_groupFlags, ch

	;
	; Now, get the NEW flags into CL, and make AL the diffs
	;

	mov	cl, ds:[di].CGI_groupFlags
	xor	al, cl

	tst	al
	jz	done				; nothing changed


	ornf	ds:[di].CGI_buildChangeFlags, mask BCF_GROUP_FLAGS

	; AL are the flags that have changed
	; Go through each flag.  If it hasn't changed, do nothing.  If
	; it becomes SET, then call the "set" routine.  If it becomes
	; CLEARED, then call the "clear" routine.

	clr	bx			; offset into SET or CLEAR table

startLoop:
	shl	al
	jnc	noChange

	; Call either the "bit cleared" or the "bit set" routine,
	; depending on the high bit of CL

	mov	dx, cs:GroupFlagSetTable[bx]
	shl	cl		
	jc	callRoutine
	mov	dx, cs:GroupFlagClearTable[bx]

callRoutine:

	;
	; Preserve SI around the call, and re-dereference the chart
	; group
	;

	push	si
	call	dx
	pop	si
	DerefChartObject ds, si, di
	jmp	next
noChange:
	shl	cl
next:
	add	bx, 2
	cmp	bx, size GroupFlagClearTable
	jl	startLoop


	mov	cx, mask CUUIF_GROUP_FLAGS
	call	UtilUpdateUI
done:
	.leave
	ret
ChartGroupSetGroupFlags	endm

GroupFlagSetTable	word 	\
	offset	CreateLegend,
	offset	CreateVerticalLegend,
	offset	CreateChartTitle,
	offset	CreateXAxisTitle,
	offset	CreateYAxisTitle

GroupFlagClearTable	word \
	offset	DestroyLegend,
	offset	CreateHorizontalLegend,
	offset	DestroyChartTitle,
	offset	DestroyXAxisTitle,
	offset	DestroyYAxisTitle




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateChartTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a title object for this chart

CALLED BY:	ChartGroupSetGroupFlags

PASS:		*ds:si - ChartGroup object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateChartTitle	proc near	
	uses	ax,cx,dx,bp

	.enter

	mov	al, TT_CHART_TITLE
	mov	cl, CORT_0_DEGREES
	call	UtilCreateTitleObject		; *ds:dx - title object

	.leave
	ret

CreateChartTitle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CreateXAxisTitle, DestroyXAxisTitle, 
	CreateYAxisTitle, DestroyYAxisTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create or destroy the appropriate title

CALLED BY:	ChartGroupSetGroupFlags

PASS:		ds - segment of chart objects

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyYAxisTitle	proc near	
	uses	ax
	.enter
	mov	ax, MSG_AXIS_DESTROY_TITLE
	call	SendToYAxis
	.leave
	ret
DestroyYAxisTitle	endp

DestroyXAxisTitle	proc near	
	uses	ax
	.enter
	mov	ax, MSG_AXIS_DESTROY_TITLE
	call	SendToXAxis
	.leave
	ret
DestroyXAxisTitle	endp

CreateYAxisTitle	proc near	
	uses	ax
	.enter
	mov	ax, MSG_AXIS_CREATE_TITLE
	call	SendToYAxis
	.leave
	ret
CreateYAxisTitle	endp

CreateXAxisTitle	proc near	
	uses	ax
	.enter
	mov	ax, MSG_AXIS_CREATE_TITLE
	call	SendToXAxis
	.leave
	ret
CreateXAxisTitle	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyChartTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the chart title object.  Remove it as my first
		child. 

CALLED BY:

PASS:		*ds:si -  ChartGroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyChartTitle	proc near	
	uses	cx
	.enter
	clr	cx
	call	ChartCompDestroyChild
	.leave
	ret
DestroyChartTitle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateLegend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a legend, assuming there currently is none.
		Don't allow legend creation for high-low charts

CALLED BY:	ChartGroupSetGroupFlags

PASS:		ds:di - ChartGroup
		*ds:si - ChartGroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateLegend	proc near
	class	ChartGroupClass
	.enter

	cmp	ds:[di].CGI_type, CT_HIGH_LOW
	je	done
	
	test	ds:[di].CGI_groupFlags, mask CGF_LEGEND_VERTICAL
	jz	horizontal

	;
	; Add it as the last child of the HorizComp.  
	;

	mov	cl, CCT_VERTICAL
	call	CreateLegendLow
	
	mov	bp, CCO_LAST
	mov	si, offset TemplateHorizComp
	mov	ax, MSG_CHART_COMP_ADD_CHILD
	call	ObjCallInstanceNoLock
	jmp	done


horizontal:
	mov	cl, CCT_HORIZONTAL
	call	CreateLegendLow

	;
	; Add it as last child of the chart group
	;

	mov	bp, CCO_LAST
	call	ChartCompAddChild

done:
	.leave
	ret
CreateLegend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateVerticalLegend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the horizontal legend a vertical one

CALLED BY:	ChartGroupSetGroupFlags

PASS:		ds:di - chart group

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateVerticalLegend	proc near
	.enter

	mov	cl, CCT_VERTICAL
	mov	bp, CCO_LAST
	mov	si, offset TemplateHorizComp
	call	ReAttachLegend

	.leave
	ret

CreateVerticalLegend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateHorizontalLegend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the horizontal legend a vertical one

CALLED BY:	ChartGroupSetGroupFlags

PASS:		ds:di - chart group

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateHorizontalLegend	proc near
	.enter
	mov	cl, CCT_HORIZONTAL
	mov	si, offset TemplateChartGroup
	call	ReAttachLegend

	.leave
	ret

CreateHorizontalLegend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReAttachLegend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach the legend from its current parent, and add it
		to the passed parent

CALLED BY:	CreateVerticalLegend, CreateHorizontalLegend

PASS:		cl - ChartCompType
		*ds:si - new parent
		ds:di - chartGroup

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReAttachLegend	proc near
	class	ChartGroupClass

	.enter

	mov	bx, si			; parent chunk handle
	mov	si, ds:[di].CGI_legend
	tst	si
	jz	createNew

	mov	ax, MSG_CHART_OBJECT_REMOVE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_CHART_COMP_SET_TYPE
	call	ObjCallInstanceNoLock

	mov	dx, si
	mov	si, bx			; parent
	mov	ax, MSG_CHART_COMP_ADD_CHILD
	mov	bp, CCO_LAST
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
createNew:
	call	CreateLegend
	jmp	done
ReAttachLegend	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyLegend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	destroy the current legend object

CALLED BY:	ChartGroupSetGroupFlags 

PASS:		ds:di - *ds:si - ChartGroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyLegend	proc near	
	uses	di,si
	class	ChartGroupClass 
	.enter
	lea	di, ds:[di].CGI_legend
	call	UtilDetachAndKill

	;
	; Send a BUILD to ourself, in the event that one of the only
	; objects that the user the user had selected has just been
	; destroyed, which would cause the group's selection count to
	; drop to zero, and would prevent the BUILD message from
	; coming from the controller.
	;

	mov	bp, mask BCF_GROUP_FLAGS
	mov	ax, MSG_CHART_OBJECT_BUILD
	call	ObjCallInstanceNoLock

	.leave
	ret
DestroyLegend	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateLegendLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a Legend object

CALLED BY:	CreateHorizontalLegendCommon, 
		CreateVerticalLegendCommon

PASS:		*ds:si - ChartGroup
		cl - ChartCompType of legend

RETURN:		*ds:dx - legend object

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	store chunk handle of legend in group's instance data

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateLegendLow	proc near	
	uses	ax,bx,di
	class	ChartGroupClass 
	.enter
	push	si			; chart group
	mov	di, offset LegendClass
	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate		; *ds:si - new legend object

	;
	; Set the COMP type as either horizontal or vertical
	;	cl = CompType

	mov	ax, MSG_CHART_COMP_SET_TYPE
	call	ObjCallInstanceNoLock


	mov	dx, si
	pop	si
	DerefChartObject ds, si, di
	mov	ds:[di].CGI_legend, dx
	.leave
	ret
CreateLegendLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTitleTextSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of the text contained in the text object
		pointed to by this chart object

CALLED BY:	ChartGroupCombineGroupFlags

PASS:		*ds:cx - ChartObject

RETURN:		ax - text size, including NULL

DESTROYED:	cx,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTitleTextSize	proc near
		uses	bx, cx, si, bp, di

		.enter

		mov	si, cx			; *ds:si - chart object
		
EC <		call	ECCheckChartObjectDSSI				>

		mov	ax, TEMP_TITLE_TEXT
		call	ObjVarFindData
		jnc	useGrObj

		mov	bx, ds:[bx]
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		jmp	done

useGrObj:
		mov	ax, MSG_CHART_OBJECT_GET_GROBJ_TEXT
		call	ObjCallInstanceNoLock 

		movdw	bxsi, cxdx
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; dx:ax <- size of text

		ECMakeSureZero	dx
		inc	ax			; return size
						; including NULL
DBCS <		shl	ax, 1			; # chars -> # bytes	>
done:
		.leave
		ret
GetTitleTextSize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTitleText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the text from the GrObject

CALLED BY:	ChartGroupCombineGroupFlags

PASS:		*ds:cx - title object
		es:bp - buffer 

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTitleText	proc near
		uses	bx, si, di, ds
		.enter

		mov	si, cx		; title object
		
EC <		call	ECCheckChartObjectDSSI				>
		
		mov	ax, TEMP_TITLE_TEXT
		call	ObjVarFindData
		jnc	useGrObj

		mov	bx, ds:[bx]
		call	MemLock
		mov	ds, ax
		clr	si
		mov	di, bp
		LocalCopyString
EC <		dec	di						>
EC <		EC_BOUNDS	es, di					>
		call	MemUnlock
		jmp	done

useGrObj:

		mov	ax, MSG_CHART_OBJECT_GET_GROBJ_TEXT
		call	ObjCallInstanceNoLock
		movdw	bxsi, cxdx
		mov	dx, es
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

done:
		.leave
		ret
GetTitleText	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupCombineGroupFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Combine the GROUP flags for sending to the controllers	

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.
		cx	- handle of notification block to update

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupCombineGroupFlags	method	dynamic	ChartGroupClass, 
					MSG_CHART_GROUP_COMBINE_GROUP_FLAGS
	uses	dx, bp
	.enter
	call	UtilStartCombine


	;
	; Get the title strings and stuff them in the GNB
	;

	test	ds:[di].CGI_groupFlags, mask CGF_CHART_TITLE
	jz	afterChartTitle

	tst	es:[GNB_chartTitleSize]
	jz	getChartTitle

	ornf	es:[GNB_notificationFlags], mask GNF_CHART_TITLE_DIFF
	jmp	afterChartTitle

getChartTitle:
	;
	; get the chart title text from the chart object and stuff
	; it in the GroupNotificationBlock.  Chart title is always the
	; first child of the chart group, if it exists (which is
	; determined by the CGF_CHART_TITLE flag.
	;

	clr	cx, dx
	call	ChartCompFindChild
EC <	ERROR_C OBJECT_NOT_FOUND				>

	call	GetTitleTextSize	; ax - text size
	
	mov	es:[GNB_chartTitleSize], ax

	call	reAlloc

	mov	bp, offset GNB_chartTitle
	call	GetTitleText

afterChartTitle:
	test	ds:[di].CGI_groupFlags, mask CGF_X_AXIS_TITLE
	jz	afterXAxisTitle

	tst	es:[GNB_xAxisTitleSize]
	jz	getXAxisTitle

	ornf	es:[GNB_notificationFlags], mask GNF_X_AXIS_TITLE_DIFF
	jmp	afterXAxisTitle

getXAxisTitle:

	clr	cx				; in case no X axis
	mov	ax, MSG_AXIS_GET_TITLE
	call	SendToXAxis
	jcxz	afterXAxisTitle

	call	GetTitleTextSize
	mov	es:[GNB_xAxisTitleSize], ax

	call	reAlloc

	mov	bp, offset GNB_chartTitle
	add	bp, es:[GNB_chartTitleSize]
	mov	es:[GNB_xAxisTitle], bp		; pointer to x-axis title
	call	GetTitleText

afterXAxisTitle:
	test	ds:[di].CGI_groupFlags, mask CGF_Y_AXIS_TITLE
	jz	afterYAxisTitle

	tst	es:[GNB_yAxisTitleSize]
	jz	getYAxisTitle

	ornf	es:[GNB_notificationFlags], mask GNF_Y_AXIS_TITLE_DIFF
	jmp	afterYAxisTitle

getYAxisTitle:
	clr	cx				; in case no Y axis
	mov	ax, MSG_AXIS_GET_TITLE
	call	SendToYAxis
	jcxz	afterYAxisTitle

	call	GetTitleTextSize	; ax - text size
	mov	es:[GNB_yAxisTitleSize], ax

	call	reAlloc

	; Store the y-axis title after the x-axis title.

	mov	bp, offset GNB_chartTitle
	add	bp, es:[GNB_chartTitleSize]
	add	bp, es:[GNB_xAxisTitleSize]
	mov	es:[GNB_yAxisTitle], bp		; store the nptr

	call	GetTitleText

afterYAxisTitle:

	push	di
	lea	si, ds:[di].CGI_gridFlags
	mov	di, offset GNB_gridFlags
	mov	bp, offset GNB_gridFlagDiffs
	call	UtilCombineFlags
	pop	di
	;
	; The chart type is useful for disabling axis titles and
	; legend stuff
	;
	push	di
	lea	si, ds:[di].CGI_type
	mov	di, offset GNB_type
	call	UtilCombineEtype
	pop	di

	lea	si, ds:[di].CGI_groupFlags
	mov	di, offset GNB_groupFlags
	mov	bp, offset GNB_groupFlagDiffs
	call	UtilCombineFlags

	call	UtilEndCombine

	.leave
	ret
;--------------------
reAlloc:
	mov	ax, size GroupNotificationBlock
	add	ax, es:[GNB_chartTitleSize]
	add	ax, es:[GNB_xAxisTitleSize]
	add	ax, es:[GNB_yAxisTitleSize]

	; Reallocate without destroying CX, and store the new address
	; in ES.

	push	cx
	mov	ch, mask HAF_ZERO_INIT
	call	MemReAlloc
	pop	cx
	mov	es, ax
	retn

ChartGroupCombineGroupFlags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupSetTitleText
		ChartGroupSetXAxisText
		ChartGroupSetYAxisText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the chart title given a block of text.

CALLED BY:	MSG_CHART_GROUP_SET_TITLE_TEXT
PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		ds:bx	= ChartGroupClass object (same as *ds:si)
		es 	= segment of ChartGroupClass
		ax	= message #
		cx	= block handle
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	8/13/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupSetTitleText	method dynamic ChartGroupClass, 
					MSG_CHART_GROUP_SET_TITLE_TEXT

		
EC <		test	ds:[di].CGI_groupFlags, mask CGF_CHART_TITLE	>
EC <		ERROR_Z TITLE_ERROR					>

		mov	bx, cx			; handle of text block
		clr	cx, dx
		call	ChartCompFindChild	; *ds:dx - title object
EC <		ERROR_C TITLE_ERROR					>

		call	SetTitleTextCommon
		
		ret
ChartGroupSetTitleText	endm

ChartGroupSetXAxisText	method dynamic ChartGroupClass, 
					MSG_CHART_GROUP_SET_X_AXIS_TEXT

EC <		test	ds:[di].CGI_groupFlags, mask CGF_X_AXIS_TITLE 	>
EC <		ERROR_Z TITLE_ERROR					>

		mov	bx, cx			; handle of text block
		mov	ax, MSG_AXIS_GET_TITLE
		call	SendToXAxis

		call	SetTitleTextCommon
		ret
ChartGroupSetXAxisText	endm

ChartGroupSetYAxisText	method dynamic ChartGroupClass, 
					MSG_CHART_GROUP_SET_Y_AXIS_TEXT

EC <		test	ds:[di].CGI_groupFlags, mask CGF_Y_AXIS_TITLE 	>
EC <		ERROR_Z TITLE_ERROR					>

		mov	bx, cx
		mov	ax, MSG_AXIS_GET_TITLE
		call	SendToYAxis

		call	SetTitleTextCommon
		ret

ChartGroupSetYAxisText	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTitleTextCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text for a title object.  Clear the block
		containing the text if it already exists.

CALLED BY:	ChartGroupSetTitleText, ChartGroupSetXAxisText,
		ChartGroupSetYAxisText

PASS:		*ds:cx - title object
		bx - handle of text block

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/26/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTitleTextCommon	proc near

		push	bx  		; text block
		
		mov	si, cx

	;
	; If the vardata already exists, then free the existing handle
	;
		
		mov	ax, TEMP_TITLE_TEXT
		call	ObjVarFindData
		jnc	addIt
		mov	bx, ds:[bx]
		call	MemFree
addIt:
		mov	cx, size hptr
		call	ObjVarAddData
		pop	ds:[bx]		; text block

		mov	ax, MSG_CHART_OBJECT_MARK_INVALID
		mov	cl, mask COS_IMAGE_INVALID
		call	ObjCallInstanceNoLock
		
		mov	cx, mask CUUIF_GROUP_FLAGS
		call	UtilUpdateUI
		ret
SetTitleTextCommon	endp


