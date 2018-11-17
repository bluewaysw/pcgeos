COMMENT @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 All Rights Reserved

PROJECT:	Peanut command
MODULE:		Pellet
FILE:		amateurPellet.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	PelletStart		Start a new pellet
	PelletMove		update an existing pellet's position

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/29/91		Initial Revision

	$Id: amateurPellet.asm,v 1.1 97/04/04 15:11:57 newdeal Exp $

---------------------------------------------------------------------------@



COMMENT @-------------------------------------------------------------------
		PelletStart		
----------------------------------------------------------------------------

SYNOPSIS:	Set up a pellet's instance data
CALLED BY:	AmateurButtonPressed	

PASS:		ss:bp - PelletParams

RETURN:		nothing

DESTROYED:	just about everything
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@

PelletStart	method  dynamic AmateurPelletClass, MSG_MOVE_START
	uses	ax,cx,dx,bp
	.enter

	clr	ds:[di].API_step
	mov	ax, ss:[bp].BP_color
	mov	ds:[di].API_color, ax

	mov	ax, ss:[bp].BP_start.P_x
	mov	bx, ss:[bp].BP_start.P_y
	mov	cx, ss:[bp].BP_end.P_x
	mov	dx, ss:[bp].BP_end.P_y

	cmp	cx, 2			; if x-position < 2, adjust slightly
	jg	20$
	mov	cx, 3
20$:
	mov	ds:[di].MOI_end.P_x, cx
	mov	ds:[di].MOI_end.P_y, dx

	sub	cx, ax
	sub	dx, bx

	mov	ds:[di].MOI_deltas.P_x, cx	
	mov	ds:[di].MOI_deltas.P_y, dx

	mov	ds:[di].MOI_curPos.PF_x.WWF_int, ax
	mov	ds:[di].MOI_curPos.PF_y.WWF_int, bx

	abs	cx
	abs	dx
	
	mov	bx, cx
	add	bx, dx		; ax = sum of x & y lengths, which makes
				; a good enough proportional distance
				; divide by 32 for speed

	tst	bx
	jz	zeroDist

	mov	dx, bx		; sum of deltas (unsigned)

	
	mov	cl, 5
	shr	bx, cl

	; Calculate the x and y increments.  
	; X-increment is deltaX/"distance"
	; Y-increment is deltaY/"distance"

	tst	bx
	jz	zeroDist

	push	dx		; sum of deltas

	mov	ax, ds:[di].MOI_deltas.P_x
	call	Divide
	movwwf	ds:[di].MOI_incr.PF_x, dxax

	mov	ax, ds:[di].MOI_deltas.P_y
	call	Divide
	movwwf	ds:[di].MOI_incr.PF_y, dxax

	; Now, add increments.  Divide sum of deltas by sum of
	; increments to figure out how many "steps" to take

	mov	bx, dx
	abs	bx
	mov	ax, ds:[di].MOI_incr.PF_x.WWF_int
	abs	ax

	add	bx, ax

	pop	ax		; sum of deltas (unsigned)
	clr	dx

	div	bx
	mov	ds:[di].API_numSteps, ax

done:	
	.leave
	ret				

zeroDist:
	mov	ds:[di].API_numSteps, 1
	jmp	done

PelletStart	endm





COMMENT @-------------------------------------------------------------------
		PelletMove		
----------------------------------------------------------------------------

SYNOPSIS:	This method is called for each pellet movement
CALLED BY:	
PASS:		*ds:si - pellet object 

RETURN:		carry set iff pellet is done moving
		cx = x position
		dx = y position

DESTROYED:	cx, dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@

PelletMove  	proc 	near
	uses	ax, bp
	class	AmateurPelletClass
	.enter 

	mov	di, ds:[si]		; deref instance data

	; erase old dot

	mov	cx, ds:[di].MOI_curPos.PF_x.WWF_int
	mov	dx, ds:[di].MOI_curPos.PF_y.WWF_int

	call	GetBackgroundColor
	call	DrawDot

	; calculate new position

	addwwf	ds:[di].MOI_curPos.PF_x, ds:[di].MOI_incr.PF_x, ax
	addwwf	ds:[di].MOI_curPos.PF_y, ds:[di].MOI_incr.PF_y, ax

	mov	ax, ds:[di].API_step
	inc	ax
	mov	ds:[di].API_step, ax
	cmp	ax, ds:[di].API_numSteps
	jl	continue
	
	; Pellet is "done" -- return X and Y positions, set the carry.

	mov	cx, ds:[di].MOI_end.P_x
	mov	dx, ds:[di].MOI_end.P_y
	stc				
	jmp	done

continue:
	; pellet keeps going -- draw the new position

	mov	cx, ds:[di].MOI_curPos.PF_x.WWF_int
	mov	dx, ds:[di].MOI_curPos.PF_y.WWF_int
	mov	ax, ds:[di].API_color		; draw new pellet
	call	DrawDot
	clc
done:
	.leave
	ret

PelletMove	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Divide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Divide (signed) AX by (signed) BX, return wwfixed DX.AX

CALLED BY:

PASS:		ax, bx - numbers to divide 

RETURN:		dx.ax = ax/bx

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dividing by zero returns zero.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Divide	proc near	
	uses	cx
	.enter

	clr	cl		; sign bit
	tst	ax
	jns	axPos
	neg	ax
	not	cl
axPos:
	tst	bx
	jns	bxPos
	jz	zero
	neg	bx
	not	cl
bxPos:
	; First, divide dx:ax by bx.  Integer portion will be in AX,
	; remainder in DX

	clr	dx
	div	bx			
	push	ax			;; save integer portion

	; Now, divide remainder * 65536 by BX.  Result (AX) is
	; fractional amount.

	clr	ax			
	div	bx			
	pop	dx			;; restore integer portion

	tst	cl
	jns	done

	negwwf	dxax
done:
	.leave
	ret
zero:
	clrwwf	dxax
	jmp	done

Divide	endp

