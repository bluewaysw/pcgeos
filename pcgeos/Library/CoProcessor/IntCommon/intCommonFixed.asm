COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		intCommonFixed.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/20/92		Initial version.

DESCRIPTION:
	fixed code stuff

	$Id: intCommonFixed.asm,v 1.1 97/04/04 17:48:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


FixedCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Overflow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	deal with interface between hardware and software stack

CALLED BY:	Math Library

PASS:
		di = how much to overflow
		cx = number of spaces to skip (< 0)
RETURN:

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Overflow	proc	far
myfloat	local	FloatNum
	uses	ds, es, si
	.enter
	; check for an overflow

	; if the stack size looks like its going go get too big
	; we must swap out as many elements as we will overflow by,
	; because the damn chip has only as fstp for 80 bit numbers
	; so I do this funny thing to go down and get all the
	; bottom elements and push them onto the software stack
	; and then fix up the stack pointer

	mov	es, ax				; es <- stack segment
	segmov	ds, ss, si
	lea	si, myfloat
	fincstp
	push	di
	neg	cx
	jz	loop1
loop0:
	fdecstp
	dec	di
	loop	loop0

loop1:	
	fdecstp
	fdecstp
	fstp	myfloat
	fwait
	call	FloatPushNumber
	jc	error
	dec	di
	jg	loop1	
	pop	cx
	dec	cx
	jz	done
loop2:
	fincstp
	loop	loop2
done:
	.leave	
	ret
error:
	stc
	jmp	done
Intel80X87Overflow	endp
	public	Intel80X87Overflow

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Underflow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	take top of software stack and put it in bottom of hardware

CALLED BY:	Math Library

PASS:		
		di = amount of underflow
		cx = number of elements to skip

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
Intel80X87Underflow	proc	far
myfloatz	local	FloatNum
	uses	es, di,si,ds, ax, cx
	.enter
	neg	di
	mov	si, di
	mov	ds, ax
	segmov	es, ss, ax
	mov_tr	ax, cx
	mov	cx, di
	dec	cx
	lea	di, ss:[myfloatz]
	tst	cx
	jz	cont1
	; first, go down to the correct level of the hardware stack
loop1:
	fdecstp
	loop	loop1
cont1:
	; now start popping off numbers off the software stack and
	; onto the hardware stack
	mov	cx, si
	sub	cx, ax
loop2:
	call	FloatPopNumber
	jc	done
	fld	myfloatz
	fincstp
	fincstp
	loop	loop2
	fdecstp

	tst_clc	ax
	jz	done
	mov_tr	cx, ax
loop3:
	fincstp
	loop	loop3
done:
	.leave
	ret
Intel80X87Underflow	endp
	public	Intel80X87Underflow

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize the chip

CALLED BY:	GLOBAL

PASS:		ax = stack size to allocate

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Init	proc	far
	sub	ax, INTEL_STACK_SIZE 
	call	FloatInit
	call	FloatHardwareInit
	ret
Intel80X87Init	endp
	public	Intel80X87Init

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Exit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clean up the software stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global INTEL80X87EXIT:far
INTEL80X87EXIT	proc	far
	FALL_THRU	Intel80X87Exit
INTEL80X87EXIT	endp

Intel80X87Exit	proc	far
	call	FloatExit
	call	FloatHardwareExit
	ret
Intel80X87Exit	endp
	public	Intel80X87Exit


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87DoFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set up flags from the status word of coprocessor

CALLED BY:	GLOBAL

PASS:		ax = status word of coprocessor

RETURN:		flags set apporpriately

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/26/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87DoFlags	proc	far
	.enter
	sahf
	je	equal
	jb	lessThan
;greaterthan
	mov	ax, 2
	cmp	ax, 1		
	jmp	done
lessThan:
	mov	ax, 1
	cmp	ax, 2
	jmp	done
equal:
	clr	ax
	tst	ax
done:
	.leave
	ret
Intel80X87DoFlags	endp


if ERROR_CHECK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Check2Args
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	makes sure there are 2 args on the stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Check2Args	proc	far
	uses	ax
	.enter
	pushf
	call	FloatGetStackDepth
	cmp	ax, 2
	ERROR_L	INSUFFICIENT_ARGUMENTS_ON_STACK
	popf
	.leave
	ret
Intel80X87Check2Args	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Check1Arg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	makes sure there are 2 args on the stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Check1Arg	proc	far
	uses	ax
	.enter
	pushf
	call	FloatGetStackDepth
	cmp	ax, 1
	ERROR_L	INSUFFICIENT_ARGUMENTS_ON_STACK
	popf
	.leave
	ret
Intel80X87Check1Arg	endp
endif

FixedCode	ends






