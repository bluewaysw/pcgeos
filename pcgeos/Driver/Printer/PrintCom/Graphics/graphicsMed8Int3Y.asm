
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		graphicsMed8Int3Y.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision
	Dave	3/92		moved from epson9


DESCRIPTION:

	$Id: graphicsMed8Int3Y.asm,v 1.1 97/04/18 11:51:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintMediumBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Prints a Medium resolution band. (3 interleaves)
	Specialized routine for the Epson 9-pin printers Medium mode.
	Loads a 12 bit high band of the desired width from the input
	bitmap data.  The data is rotated properly for the FX type 9
	pin printers.  It is assumed that the graphic print routine is
	using a 8-pin mode .

CALLED BY:
	PrPrintABand

PASS:
	ds:si	=	pointer into bitmap data
			(has to be locked huge array block)
	es	=	segment of PState

RETURN:
	ds:si	=	Adjusted to point at the next scan line data in
			Huge Array.

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/20/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrPrintMediumBand	proc	near
	uses	ax,bx,cx,dx,di
curBand	local	BandVariables
	.enter
	mov     ax,es:[PS_newScanNumber] ;set the band start for this band.
        mov     curBand.BV_bandStart,ax

firstPass:
		;do first pass.... $AA mask top set of 4 lines ...
	call	PrLoadBandBuffer	;fill the bandBuffer
	call	PrScanBandBuffer	;determine live print width.
	mov	cx,dx
	jcxz	firstPassColors		;if no data, try next color
	mov	si,offset pr_codes_SetMedGraphics
	call	PrSendGraphicControlCode ;send the graphics code for this pass
	jc	exit
	call	PrRotate4LinesZeroBottom
	jc	exit
firstPassColors:
        call    SetNextCMYK
        mov     cx,es:[PS_curColorNumber]       ;see if the color is the first.
	jcxz    secondPassEntry
        mov     ax,curBand.BV_bandStart
        mov     es:[PS_newScanNumber],ax ;set back to start of band
        jmp     firstPass                   ;do the next color.

secondPassEntry:
	mov	ax,curBand.BV_bandStart
	add	ax,2			;set two lines down.
	mov	curBand.BV_bandStart,ax
	mov	es:[PS_newScanNumber],ax
	call	Pr1ScanlineFeed		;advance 1 scanline
	jc	exit

secondPass:
		;do second pass.... $55 mask bottom set of 4 lines....
	call	PrLoadBandBuffer	;fill the bandBuffer
	call	PrScanBandBuffer	;determine live print width.
	mov	cx,dx
	jcxz	secondPassColors		;if no data, try next color
	mov	si,offset pr_codes_SetMedGraphics
	call	PrSendGraphicControlCode ;send the graphics code for this pass
	jc	exit
	call	PrRotate4LinesZeroTop
	jc	exit
secondPassColors:
        call    SetNextCMYK
        mov     cx,es:[PS_curColorNumber]       ;see if the color is the first.
	jcxz    thirdPassEntry
        mov     ax,curBand.BV_bandStart
        mov     es:[PS_newScanNumber],ax ;set back to start of band
        jmp     secondPass                   ;do the next color.

thirdPassEntry:
	mov	ax,curBand.BV_bandStart		;set one line up.
	dec	ax
	mov	curBand.BV_bandStart,ax
	mov	es:[PS_newScanNumber],ax
	call	Pr1ScanlineFeed		;advance 1 scanline
	jc	exit
thirdPass:
		;do third pass.... $AA mask  middle set of 4 lines ...
	call	PrLoadBandBuffer	;fill the bandBuffer
	call	PrScanBandBuffer	;determine live print width.
	mov	cx,dx
	jcxz	thirdPassColors		;if no data, try next color
	mov	si,offset pr_codes_SetMedGraphics
	call	PrSendGraphicControlCode ;send the graphics code for this pass
	jc	exit
	call	PrRotate4LinesZeroBottom
	jc	exit
thirdPassColors:
        call    SetNextCMYK
        mov     cx,es:[PS_curColorNumber]       ;see if the color is the first.
	jcxz    done
        mov     ax,curBand.BV_bandStart
        mov     es:[PS_newScanNumber],ax ;set back to start of band
        jmp     thirdPass                   ;do the next color.

done:
	dec	es:[PS_newScanNumber]	;correct for the scan being (end of
					;middle + 3 = 1 too far for top of next
					;buffer)
	call	Pr1ScanlineFeed		;advance 1 scanline
exit:
	.leave
	ret
PrPrintMediumBand	endp
