COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		titleRealize.asm

AUTHOR:		John Wedgwood, Oct 21, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/21/91	Initial revision

DESCRIPTION:
	Realizing code for titles.

	$Id: titleRealize.asm,v 1.1 97/04/04 17:47:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartMiscCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a GrObj for this title

PASS:		*ds:si	= TitleClass object
		ds:di	= TitleClass instance data

RETURN:		nothing

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TitleRealize	method dynamic	TitleClass, MSG_CHART_OBJECT_REALIZE

		uses	ax,cx,dx

ctp		local	CreateTextParams

		.enter


		mov	ax, TEMP_TITLE_TEXT
		call	ObjVarFindData
		mov	ax, 0
		jnc	afterLock

		mov	bx, ds:[bx]
		call	MemLock
afterLock:
		mov	ss:[ctp].CTP_text.segment, ax
		clr	ss:[ctp].CTP_text.offset

		movP	ss:[ctp].CTP_common.CGOP_position,	\
				ds:[di].COI_position, ax

		movP	ss:[ctp].CTP_common.CGOP_size,	\
				ds:[di].COI_size, ax	

		mov	ss:[ctp].CTP_common.CGOP_locks,
				STANDARD_CHART_GROBJ_LOCKS

	;
	; If we have text in our vardata,
	; then force it to be copied into the text object.
	;

		mov	al, mask CTF_CENTERED
		tst	ss:[ctp].CTP_text.segment
		jnz	gotTextFlags
		ornf	al, mask CTF_SET_ON_CREATE

gotTextFlags:
		mov	ss:[ctp].CTP_flags, al
	
		clr	ax
		cmp	ds:[di].TI_rotation, CORT_0_DEGREES
		je	gotFlags
		ornf	ax, mask CGOF_ROTATED
gotFlags:
		mov	ss:[ctp].CTP_common.CGOP_flags, ax

		push	bp
		lea	bp, ss:[ctp]
		call	ChartObjectCreateOrUpdateMultText
		pop	bp

	;
	; Nuke the vardata.  If it was there, then delete the memory
	; block, which will be in BX (from above).
	;
		mov	ax, TEMP_TITLE_TEXT
		call	ObjVarDeleteData
		jc	done
		call	MemFree

done:
		.leave
		mov	di, offset TitleClass
		GOTO	ObjCallSuperNoLock 
TitleRealize	endm


ChartMiscCode	ends
