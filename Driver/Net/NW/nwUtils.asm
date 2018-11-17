COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nwUtils.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/92   	Initial version.

DESCRIPTION:
	

	$Id: nwUtils.asm,v 1.1 97/04/18 11:48:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetWareCommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyMemCmp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		ds:si 	= first pointer
		es:di 	= second pointer
		cx	= length to compare

RETURN:		ax	= difference of chars, 0 if equal

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyMemCmp	proc	near
	uses	ds,es,si,di,cx
	.enter
	clr 	ax
	jcxz	exit
	repe	cmpsb
	mov	al, es:[di][-1]
	sub	al, ds:[si][-1]
	cbw
exit:
	.leave
	ret
MyMemCmp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                MyStrCmp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       compares 2 strings

CALLED BY:      GLOBAL
PASS:           es:di - string 1
                ds:si - string 2

RETURN:         ax - 0 if match, else difference in chars
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        ISR     3/11/92         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyStrCmp  proc    far
        uses    cx,ds,es,si,di
        .enter
        push    di
        mov     cx, -1
        clr     ax                      ;
        repne   scasb                   ;
        not     cx                      ;CX <- # chars in str 1 (w/null)
        pop     di
        repe    cmpsb
        jz      exit                    ;If match, exit (with ax=0)
        mov     al, es:[di][-1]         ;Else, return difference of chars
        sub     al, ds:[si][-1]         ;
        cbw                             ;
exit:
        .leave
        ret
MyStrCmp  endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareFreeRRBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the mem block at ES.  The handle is at ES:0

CALLED BY:	INTERNAL

PASS:		es - segment to free

RETURN:		nothing 

DESTROYED:	es, flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareFreeRRBuffers	proc far
	uses	bx
	.enter
	pushf
	mov	bx, es:[NRR_handle]
	call	MemFree
	popf
	.leave
	ret
NetWareFreeRRBuffers	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareCopyNTString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy a null-terminated string, including the NULL

CALLED BY:	INTERNAL

PASS:		ds:si - source
		es:di - dest

RETURN:		cx - number of bytes, including NULL
		ds:si, es:di - point AFTER null

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareCopyNTString	proc near
		uses	ax
		.enter
		clr	cx
startLoop:
		lodsb
		stosb
		inc	cx
		tst	al
		jnz	startLoop
		.leave
		ret
NetWareCopyNTString	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareCopyStringButNotNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string, but don't copy the NULL terminator

CALLED BY:	INTERNAL

PASS:		ds:si  - source
		es:di - dest

RETURN:		cx - # of bytes copied
		ds:si - points at NULL
		es:di - points after last char copied

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareCopyStringButNotNull	proc near
	uses	ax
	.enter

	clr	cx
copyLoop:
	lodsb
	tst	al
	jz	endCopy
	inc	cx
	stosb
	jmp	copyLoop
endCopy:

	.leave
	ret
NetWareCopyStringButNotNull	endp


NetWareCommonCode	ends
