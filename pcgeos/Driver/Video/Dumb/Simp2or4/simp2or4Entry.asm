COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Video
MODULE:		Simp2or4
FILE:		simp2or4Entry.asm

AUTHOR:		Eric Weber, Jan 29, 1997

ROUTINES:
	Name			Description
	----			-----------
    GLB Simp2or4Strategy	Strategy routine

    INT Simp2or4Init		Load the real video driver

    INT Simp2or4Exit		Unload the real video driver

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	1/29/97   	Initial revision


DESCRIPTION:
		
	

	$Id: simp2or4Entry.asm,v 1.1 97/04/18 11:43:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

curDepth	word
curGeode	hptr
curStrategy	fptr.far

delayCount	word	24000

strategySem	Semaphore


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4Strategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine

CALLED BY:	GLOBAL
PASS:		di	- VidFunction
		others depending on function
RETURN:		various depending on function
DESTROYED:	ax,bx,cx,dx,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		pass most functions through to real driver
		pass selected functions to local handlers

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	1/29/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Simp2or4Strategy	proc	far
		pushf
	;
	; When we do the mode switch, we need to be sure that there are
	; no threads in the old driver.  While a shared lock would work
	; for this, empirical tests have shown that there is almost no
	; overlap in video calls, so an exclusive lock works just as
	; well as the shared lock, but is much simpler.
	;
		PSem	cs, strategySem
	;
	; there are only three calls which interest us
	;
		cmp	di, DR_INIT
		je	doInit
		cmp	di, DR_EXIT
		je	doExit
		cmp	di, VID_ESC_CHANGE_VID_MODE
		je	doChangeMode
	;
	; everything else gets passed to the real driver
	;
		popf
		call	cs:[curStrategy]
done:
		VSem	cs, strategySem
		ret
doInit:
		popf
		call	Simp2or4Init
		jmp	done
doExit:
		popf
		call	Simp2or4Exit
		jmp	done
doChangeMode:
		popf
		call	Simp2or4ChangeVidMode
		jmp	done
Simp2or4Strategy	endp


idata	ends

VideoCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the real video driver

CALLED BY:	INTERNAL Simp2or4Strategy
PASS:		nothing
RETURN:		carry clear if successful
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/11/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Simp2or4Init	proc	far
		uses	ax, bx, cx, dx, bp, si, di, ds, es
		.enter
	;
	; Load the correct driver
	;
		segmov	ds, cs
		mov	si, offset driver4Name
		mov	ax, VIDEO_PROTO_MAJOR
		mov	bx, VIDEO_PROTO_MINOR
		call	GeodeUseDriver
		ERROR_C CANT_LOAD_VIDEO_SUBDRIVER
	;
	; Initialize dgroup
	;
		mov	ax, segment dgroup
		mov	es, ax
		mov	es:[curDepth], 4
		mov	es:[curGeode], bx
		call	GeodeInfoDriver
		movdw	es:[curStrategy], ds:[si].DIS_strategy, ax
done::
		.leave
		ret
Simp2or4Init	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2or4Exit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unload the real video driver

CALLED BY:	INTERNAL Simp2or4Strategy
PASS:		nothing
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/11/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Simp2or4Exit	proc	far
		.enter
	;
	; get the current driver
	;
		mov	ax, segment dgroup
		mov	es, ax
		mov	bx, es:[curGeode]
	;
	; unload the driver
	;
		tst	bx
		jz	done
		call	GeodeFreeDriver
done:
		.leave
		ret
Simp2or4Exit	endp

VideoCode	ends

