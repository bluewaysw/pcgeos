COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		manager.asm

AUTHOR:		Roy Goldman, Mar  3, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 3/ 3/95   	Initial revision


DESCRIPTION:
	Hack to fix scrolling problem
		
	$Id: manager.asm,v 1.1 97/12/02 14:57:19 gene Exp $
	$Revision: 1.1 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;Standard include files


include	geos.def
include geode.def
include ec.def

include	library.def
include geode.def

include resource.def

include object.def
include	graphics.def
include gstring.def
include	win.def
include heap.def
include lmem.def
include timer.def
include timedate.def
include	system.def
include	file.def
include	fileEnum.def
include	vm.def
include	chunkarr.def
include thread.def
include	sem.def
include ec.def
include assert.def
include localize.def
UseLib	ui.def

include objects/vtextc.def


;------------------------------------------------------------------------------
; Here comes the code...
;------------------------------------------------------------------------------

ifdef DO_DBCS
ifndef CODE_PAGE_SJIS
CODE_PAGE_SJIS equ 932
endif
MAINSAVE_TEXT 	segment public "CODE" byte
_GandalfLocalGeosToDos	proc	far	buf:fptr, dst:fptr
		uses	ds, es, di, si, cx, dx, bx
		.enter
		lds	si, buf
		les	di, dst
		clr	dx
		mov	bx, CODE_PAGE_SJIS
		mov	ax, '_'
		clr	cx
		call	LocalGeosToDos
		mov	ax, cx
		.leave
		ret
_GandalfLocalGeosToDos	endp
		public _GandalfLocalGeosToDos
MAINSAVE_TEXT	ends
endif

		
EditCode segment resource

.wcheck
.rcheck


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ETVisTextShowSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_VIS_TEXT_SHOW_SELECTION
PASS:		*ds:si	= EditorTextClass object
		ds:di	= EditorTextClass instance data
		ds:bx	= EditorTextClass object (same as *ds:si)
		es 	= segment of EditorTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 3/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetGeosConvention

public ETVISTEXTSHOWSELECTION

ETVISTEXTSHOWSELECTION	proc	far pself:fptr, oself:optr, msg:word,
	                        args: VisTextShowSelectionArgs

	uses	ds, si, bp, di
	.enter		

	mov	ds, ss:[pself].high
	mov	si, ss:[oself].low
	
	mov	ax, ss:[msg]

	mov	di, segment VisTextClass     	   
	mov	es, di
	mov	di, offset VisTextClass

	push	bp
	lea	bp, ss:[args]
	
	call 	ObjCallClassNoLock

	pop	bp

	.leave
	ret

ETVISTEXTSHOWSELECTION	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunMainMessageDispatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	try to dispatch messages on queue from RunMainLoop

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GandalfMessageDispatch	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
if 0
		mov	di, 4096
		call	ThreadBorrowStackSpace
		push	di
endif
dispatchLoop:
		clr	bx
		call	GeodeInfoQueue
		tst	ax
		jz	done
		mov	di, mask MF_CALL
		call	QueueGetMessage
		mov_tr	bx, ax
		and	di, not mask MF_RECORD
		call	MessageDispatch
		loop	dispatchLoop
done:
if 0
		pop	di
		call	ThreadReturnStackSpace
endif
		.leave
		ret
GandalfMessageDispatch	endp
	public GandalfMessageDispatch
		
EditCode	ends



