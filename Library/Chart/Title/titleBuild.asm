COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		titleBuild.asm

AUTHOR:		John Wedgwood, Oct 21, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/21/91	Initial revision

DESCRIPTION:
	Build code for titles

	$Id: titleBuild.asm,v 1.1 97/04/04 17:47:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleSetRotation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the rotation for this title, and add it to the
		appropriate parent.

PASS:		*ds:si	= TitleClass object
		ds:di	= TitleClass instance data
		es	= Segment of TitleClass.
		cl	- rotation

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TitleSetRotation	method	dynamic	TitleClass, 
					MSG_TITLE_SET_ROTATION

		mov	ds:[di].TI_rotation, cl
		ret
TitleSetRotation	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleAddToComposite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add this title as a child to the appropriate
		composite, based on the title type

CALLED BY:	TitleSetType

PASS:		*ds:si - title
		cl - TitleType

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/27/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompTableEntry	struct
    CTE_composite	lptr
    CTE_position	word
CompTableEntry	ends

compTable	CompTableEntry \
    <TemplateChartGroup, CCO_FIRST or mask CCF_MARK_DIRTY>,
    <TemplateVertComp, CCO_LAST or mask CCF_MARK_DIRTY>,
    <TemplateHorizComp, CCO_FIRST or mask CCF_MARK_DIRTY>

TitleAddToComposite	proc near
		uses	si
		.enter

		mov	bl, cl
		clr	bh		; TitleType

		tst	ds:[di].COI_link.LP_next.handle
		jz	afterRemove

		mov	ax, MSG_CHART_OBJECT_REMOVE
		call	ObjCallInstanceNoLock
afterRemove:
		mov	dx, si			; title object

		shl	bx
		mov	si, cs:[compTable][bx].CTE_composite
		mov	bp, cs:[compTable][bx].CTE_position

		mov	ax, MSG_CHART_COMP_ADD_CHILD
		call	ObjCallInstanceNoLock 
		
		.leave
		ret
TitleAddToComposite	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleSetAxis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	store the axis' chunk handle in the instance data	

PASS:		*ds:si	= TitleClass object
		ds:di	= TitleClass instance data
		es	= segment of TitleClass
		*ds:cx  - axis object

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TitleSetAxis	method	dynamic	TitleClass, 
					MSG_TITLE_SET_AXIS
	mov	ds:[di].TI_axis, cx
	ret
TitleSetAxis	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	see if this title is no longer needed, and if so, nuke
		it. 

PASS:		*ds:si	= TitleClass object
		ds:di	= TitleClass instance data
		es	= segment of TitleClass
		bp 	- BuildChangeFlags

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TitleBuild	method	dynamic	TitleClass, 
					MSG_CHART_OBJECT_BUILD
	uses	ax,cx,dx,bp
	.enter

	;
	; See if we should kill ourselves
	;
	ECCheckFlags	bp, BuildChangeFlags
	test	bp, mask BCF_AXIS_REMOVE
	jz	callSuper


	;
	; Axes are going away -- is this an axis title?
	;
	tst	ds:[di].TI_axis
	jz	callSuper

	
	;
	; Yes!  the axis can be assumed to have already killed itself,
	; so kill ourself
	;

	; Detach this object

	mov	ax, MSG_CHART_OBJECT_REMOVE
	call	ObjCallInstanceNoLock

	; Free it

	.leave
	mov	ax, MSG_META_OBJ_FREE
	GOTO	ObjCallInstanceNoLock
	

callSuper:
	.leave
	mov	di, offset TitleClass
	GOTO	ObjCallSuperNoLock

TitleBuild	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleSetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the title type.  Figure out what text to use, if
		we don't already know.

PASS:		*ds:si	- TitleClass object
		ds:di	- TitleClass instance data
		es	- segment of TitleClass

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TitleSetType	method	dynamic	TitleClass, 
					MSG_TITLE_SET_TYPE
		mov	ds:[di].TI_type, cl

		call	TitleAddToComposite
		
		call	TitleSetText

		ret
TitleSetType	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleSetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the text to use for this title

CALLED BY:	TitleSetType

PASS:		ss:bp - inherited stack frame
		*ds:si - title object

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,ds,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TitleSetText	proc near

		class	TitleClass

titleText	local	CHART_TEXT_BUFFER_SIZE dup (byte)

		.enter
	;
	; If this title already has text, then done.
	;
		mov	ax, TEMP_TITLE_TEXT
		call	ObjVarFindData
		jc	done
		
	;
	; If a grobj already exists for this title, then don't bother
	;
		DerefChartObject ds, si, di
		tst	ds:[di].COI_grobj.handle
		jnz	done

	;
	; Set the text using the default
	;
		
		mov	bl, ds:[di].TI_type
		clr	bh
		ECCheckEtype	bl, TitleType
		call	cs:setText[bx]

		segmov	es, ss
		lea	di, ss:[titleText]
		LocalStrSize includeNull	; size in bytes

		push	cx		; size
		mov_tr	ax, cx
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		pop	cx


		push	ds, si		; title object
		mov	es, ax
		lea	si, ss:[titleText]
		clr	di
		segmov	ds, ss
		rep	movsb
		pop	ds, si		; title object

		call	MemUnlock
		mov	dx, bx		; mem handle
		mov	ax, TEMP_TITLE_TEXT
		mov	cx, size hptr
		call	ObjVarAddData
		mov	ds:[bx], dx	

done:
		.leave
		ret


setText	nptr	setChartTitleText,
		setXAxisTitleText,
		setYAxisTitleText

.assert (size setText eq TitleType)



setChartTitleText:

	;
	; Set the title text.  If the chart has series and category
	; titles, and the entry in the upper-left hand corner isn't
	; empty, then use that -- otherwise use the default "Chart
	; Title" text.
	;

		mov	ax, MSG_CHART_GROUP_GET_DATA_ATTRIBUTES
		call	UtilCallChartGroup

		and	al, mask CDA_HAS_SERIES_TITLES or \
			    mask CDA_HAS_CATEGORY_TITLES
		cmp	al, mask CDA_HAS_SERIES_TITLES or \
			    mask CDA_HAS_CATEGORY_TITLES
		jne	useDefaultText

		push	bp, si
		lea	bp, ss:[titleText]
		segmov	es, ss
		clr	cx, dx
		mov	si, offset TemplateChartGroup
		call	ChartGroupFormatDataEntry
		pop	bp, si

SBCS <		cmp	{byte} ss:[titleText], 0			>
DBCS <		cmp	{wchar} ss:[titleText], 0			>
		jz	useDefaultText

		retn

useDefaultText:
		mov	ax, offset ChartTitle

copyStringResource:
		lea	di, ss:[titleText]
		segmov	es, ss
		call	UtilCopyStringResource
		retn


setXAxisTitleText:
		mov	ax, offset XAxisTitle
		jmp	copyStringResource

setYAxisTitleText:
		mov	ax, offset YAxisTitle
		jmp	copyStringResource


TitleSetText	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleRelocate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Clear out the selection count on a read, because GrObj
		documents are always unselected when first read, and
		we're careful to keep chart objects from being
		discarded when they're selected

PASS:		*ds:si	- TitleClass object
		ds:di	- TitleClass instance data
		es	- segment of TitleClass
		dx 	- VMRelocType

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/23/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TitleRelocate	method	dynamic	TitleClass, 
					reloc

		cmp	dx, VMRT_RELOCATE_AFTER_READ
		jne	done

	;
	; Nuke this vardata, if it's around.
	;
		
		mov	ax, TEMP_TITLE_TEXT
		call	ObjVarDeleteData
done:
		mov	di, offset TitleClass
		call	ObjRelocOrUnRelocSuper
		ret
TitleRelocate	endm

