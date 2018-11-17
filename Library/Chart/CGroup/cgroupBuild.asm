COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgroupBuild.asm

AUTHOR:		John Wedgwood, Oct  8, 1991

METHODS:
	Name			Description
	----			-----------
	BUILD			Build the Chart Group

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 8/91	Initial revision

DESCRIPTION:
	Code to generate and regenerate charts.

	$Id: cgroupBuild.asm,v 1.1 97/04/04 17:45:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Build and realize the chart. Mark the object block as
		dirty. 

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.

		bp	= BuildChangeFlags

RETURN:		al 	- ChartReturnType (CRT_OK if build was OK)

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/16/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupBuild	method	dynamic	ChartGroupClass, 
					MSG_CHART_OBJECT_BUILD
		uses	cx,dx,bp
		.enter

		ECCheckFlags	bp, BuildChangeFlags

	;
	; add whatever we have stored to the passed flags
	;

		ornf	ds:[di].CGI_buildChangeFlags, bp
		call	ObjMarkDirty

		mov	cl, mask COS_BUILD_INVALID
		call	CheckToUpdate
		jnc	doIt

	;
	; If we can't build now, the save the flags for later.
	;

		mov	al, CRT_OK
		jmp	done

doIt:
	;
	; Keep UI, etc from updating during build
	;

		push	bp
		mov	ax, MSG_META_SUSPEND
		call	UtilCallChartBody
		pop	bp

	;
	; Make sure the parameters block is OK
	;

		call	ChartGroupCheckData
		cmp	al, CRT_OK
		jne	endUpdate

	;
	; build numbers, if necessary
	;

		call	ChartGroupDuplicateNumbers

	;
	; Fetch the BuildChangeFlags and clear them for next time.
	;
		DerefChartObject ds, si, di
		clr	bp
		xchg	bp, ds:[di].CGI_buildChangeFlags

	;
	; If removing axes, make sure we clear the axis title flags
	;

		test	bp, mask BCF_AXIS_REMOVE
		jz	afterRemove

		andnf	ds:[di].CGI_groupFlags, not (mask CGF_X_AXIS_TITLE \
			or mask CGF_Y_AXIS_TITLE)
	
		mov	cx, mask CUUIF_GROUP_FLAGS
		call	UtilUpdateUI
		
afterRemove:
	;
	; If switching axes, then switch titles as well.
	;
		test	bp, mask BCF_AXIS_ROTATE
		jz	afterRotate

		call	ChartGroupSwitchTitles

afterRotate:
	;
	; Destroy the legend if this is a hi-low chart
	;
		
		DerefChartObject	ds, si, di
		cmp	ds:[di].CGI_type, CT_HIGH_LOW
		jne	afterLegend

		test	ds:[di].CGI_groupFlags, mask CGF_LEGEND
		jz	afterLegend

		andnf	ds:[di].CGI_groupFlags, not mask CGF_LEGEND \
				or mask CGF_LEGEND_VERTICAL
		
		lea	di, ds:[di].CGI_legend
		call	UtilDetachAndKill

afterLegend:
	;
	; get type/variation/flags
	;

		DerefChartObject ds, si, di
		mov	cl, ds:[di].CGI_type
		mov	ch, ds:[di].CGI_variation
		mov	dx, ds:[di].CGI_flags

		mov	ax, MSG_CHART_OBJECT_BUILD
		mov	di, offset ChartGroupClass
		call	ObjCallSuperNoLock

endUpdate:
	; Do the END UPDATE before UNSUSPEND, as this will cause
	; REALIZE to happen before we update the UI, which is
	; generally desirable.
		
		call	ChartGroupEndUpdate

		mov	ax, MSG_META_UNSUSPEND
		call	UtilCallChartBody
		mov	al, CRT_OK		; signal no error

done:
		.leave
		ret
ChartGroupBuild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupSwitchTitles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the orientation of the title objects.  We have
		to do this now, before we call ObjCompProcessChildren,
		since moving titles involves mucking with composite
		linkages, etc.

CALLED BY:	ChartGroupBuild

PASS:		*ds:si - ChartGroup

RETURN:		nothing 

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/26/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupSwitchTitles	proc near

		class	ChartGroupClass

		uses	bp

		.enter
	;
	; Fetch the old flags into BL and the new flags into BH
	;
		
		push	si			; chart group
		DerefChartObject ds, si, di
		mov	bl, ds:[di].CGI_groupFlags
		mov	bh, bl
		andnf	bh, not (mask CGF_X_AXIS_TITLE or \
				mask CGF_Y_AXIS_TITLE)

		test	bl, mask CGF_X_AXIS_TITLE
		jz	afterX

		ornf	bh, mask CGF_Y_AXIS_TITLE

		mov	ax, MSG_AXIS_GET_TITLE
		call	SendToXAxis
		mov	si, cx		; title

		mov	ax, MSG_TITLE_SET_ROTATION
		mov	cl, CORT_90_DEGREES
		call	ObjCallInstanceNoLock

		mov	ax, MSG_TITLE_SET_TYPE
		mov	cl, TT_Y_AXIS
		call	ObjCallInstanceNoLock
		
afterX:
		test	bl, mask CGF_Y_AXIS_TITLE
		jz	done

		ornf	bh, mask CGF_X_AXIS_TITLE

		mov	ax, MSG_AXIS_GET_TITLE
		call	SendToYAxis
		mov	si, cx

		mov	ax, MSG_TITLE_SET_ROTATION
		mov	cl, CORT_0_DEGREES
		call	ObjCallInstanceNoLock

		mov	ax, MSG_TITLE_SET_TYPE
		mov	cl, TT_X_AXIS
		call	ObjCallInstanceNoLock

done:
		pop	si
		DerefChartObject ds, si, di
		mov	ds:[di].CGI_groupFlags, bh
		
		mov	cx, mask CUUIF_GROUP_FLAGS
		call	UtilUpdateUI
		.leave
		ret
ChartGroupSwitchTitles	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupCheckData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that the chart data can be charted

CALLED BY:	ChartGroupBuild

PASS:		ds:di - ChartGroup object

RETURN:		al - ChartReturnType

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Make sure there's at least 1 series 
		(at least 2 series for scatter and Hi-Lo charts)

	Make sure at least 1 category.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupCheckData	proc near	
	uses	cx, es
	class	ChartGroupClass 
	.enter

	call	ChartGroupGetSeriesCount
	tst	cl
	jz	noSeries

	cmp	ds:[di].CGI_type, CT_SCATTER
	je	check2Series
	cmp	ds:[di].CGI_type, CT_HIGH_LOW
	jne	afterCheck2

check2Series:
	cmp	cl, 2
	jb	need2Series

afterCheck2:
	cmp	cl, MAX_SERIES_COUNT
	ja	tooManySeries

	call	ChartGroupGetCategoryCount
	jcxz	noCategories

	cmp	cx, MAX_CATEGORY_COUNT
	ja	tooManyCategories
	mov	al, CRT_OK
done:
	.leave
	ret

noCategories:
	mov	al, CRT_NO_CATEGORIES
	jmp	done

noSeries:
	mov	al, CRT_NO_SERIES
	jmp	done

need2Series:
	mov	al, CRT_NEED_2_SERIES
	jmp	done

tooManySeries:
	mov	al, CRT_TOO_MANY_SERIES
	jmp	done

tooManyCategories:
	mov	al, CRT_TOO_MANY_CATEGORIES
	jmp	done

ChartGroupCheckData	endp

