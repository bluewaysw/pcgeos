COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Ruler
FILE:		rulerC.asm

AUTHOR:		Paul DuBois, Nov 15, 1993

ROUTINES:
	Name			Description
	----			-----------
RULERSCALEDOCTOWINCOORDS
RULERSCALEWINTODOCCOORDS
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/15/93   	Initial revision


DESCRIPTION:
	C stubs for the ruler library
		
	$Id: rulerC.asm,v 1.1 97/04/07 10:43:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerCCode			segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RULERSCALEDOCTOWINCOORDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	RULERSCALEDOCTOWINCOORDS

C DECLARATION:	extern void
		_far _pascal RulerScaleDocToWinCoords(
			VisRulerInstance _far*	pself,
			DWFixed _far*		point);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
RULERSCALEDOCTOWINCOORDS	proc	far	pself:fptr,
						point:fptr.DWFixed
	uses	ds, si

	.enter

		lds	si, point	;ds:[si] = *point
		movdwf	dxcxax, ds:[si], bx
		lds	si, pself	;ds:[si] = VisRuler instance

		call	RulerScaleDocToWinCoords

		lds	si, point
		movdwf	ds:[si], dxcxax

	.leave
	ret
RULERSCALEDOCTOWINCOORDS	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RULERSCALEWINTODOCCOORDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	RULERSCALEWINTODOCCOORDS

C DECLARATION:	extern void
		_far _pascal RulerScaleWinToDocCoords(
			VisRulerInstance _far*	pself,
			DWFixed _far*		point);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
RULERSCALEWINTODOCCOORDS	proc	far	pself:fptr,
						point:fptr.DWFixed
	;uses	cs,ds,es,si,di
	.enter

		lds	si, point	;ds:[si] = *point
		movdwf	dxcxax, ds:[si], bx
		lds	si, pself	;ds:[si] = VisRuler instance

		call	RulerScaleDocToWinCoords

		lds	si, point
		movdwf	ds:[si], dxcxax

	.leave
	ret
RULERSCALEWINTODOCCOORDS	endp
	SetDefaultConvention

ForceRef RULERSCALEDOCTOWINCOORDS
ForceRef RULERSCALEWINTODOCCOORDS

RulerCCode			ends
