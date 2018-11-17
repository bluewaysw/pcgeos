COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spooler	
FILE:		processLabel.asm

AUTHOR:		Jim DeFrisco, Aug 11, 1993

ROUTINES:
	Name			Description
	----			-----------
    INT InitLabelVariables	Initialize any label variables

    INT GetLabelPageTranslation Calculate the translation betwen successive
				labels on a page

    INT CalcLabelPageCenteringUpright 
				Calculate any centering of the block of
				labels on the page

    INT CalcLabelPageCenteringRotated 
				Calculate any centering of the block of
				labels on the page

    INT CalcScaledGutterWidth	Calculate the scaled gutter width

    INT GetLabelMarginsLow	Figure out how to translate a page to get
				to the first label. (any centering we are
				performing on the labels)

    INT CalcLabelSheetSize	Calculate (guesstimate) the dimensions of
				the paper on which the labels are mounted

    INT CalcLabelSheetSizeLow	Calculate the printable area covered by the
				labels

    INT PrintGraphicsLabels	Print out a single page in graphics mode

    INT CheckForGStringDone	Done with the string ?


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/11/93		Initial revision


DESCRIPTION:
	Code to deal with laying out labels and thumbnail prints onto
	a piece of paper.
		
	Here are the details of label printing (Label Conventions):

		* We assume the labels are centered on the page.
		  Since we are not currently passed the size of the
		  paper on which the labels are mounted, we assume
		  the dimensions are that of the default page. However,
		  labels are assumed to start in the upper-left corner
		  of the paper if the paper is tractor-fed.

		* We assume that there is a gutter between each
		  label, if there is any difference between the
		  default page width & columns * label width.
		  We assume this gutter size is LABEL_GUTTER_SIZE.

		* We scale the document to fit onto the label, and
		  unlike the normal scale-to-fit code, we *include*
		  the document margins in the calculation of the
		  scale factor. This means we won't print to the
		  edges of the label, which should be a desirable
		  feature.

		* We center the document on the label (since we
		  scale uniformly in each direction, there is usually
		  some leftover in one dimmension)

	$Id: processLabel.asm,v 1.1 97/04/07 11:11:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintLabel	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitLabelVariables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize any label variables

CALLED BY:	INTERNAL
		InitPrinterDriver
PASS:		curJob	- SpoolJobInfo
		dx	- PageLayoutLabel
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE_EUROPE
LABEL_GUTTER_SIZE	equ	0		; no gutters on Europe labels
else
LABEL_GUTTER_SIZE	equ	9		; 72/8
endif

InitLabelVariables	proc	far
		uses	ax, cx, dx, ds, si
curJob		local	SpoolJobInfo
		.enter inherit
	
		; Extract the # of columns & rows

		mov	ax, dx
		and	ax, mask PLL_COLUMNS
		mov	cl, offset PLL_COLUMNS
		shr	ax, cl
		mov	curJob.SJI_labelColumns, al

		mov	ax, dx
		and	ax, mask PLL_ROWS
		mov	cl, offset PLL_ROWS
		shr	ax, cl
		mov	curJob.SJI_labelRows, al

		; Calculate the gutter size, by seeing if there is any
		; difference between the cols*width and the default page
		; width

		clr	cx			; assume zero horizontal gutter
		cmp	curJob.SJI_labelColumns, 1
		je	haveGutter
		sub	sp, size PageSizeReport
		segmov	ds, ss, si
		mov	si, sp
		call	SpoolGetDefaultPageSizeInfo
		mov	ax, ds:[si].PSR_width.low
		add	sp, size PageSizeReport
		mov	cx, ax
		mov	dl, curJob.SJI_labelColumns
		clr	dh
		mov	ax, paperInfo.PSR_width.low
		mul	dx
		sub	cx, ax			; if > zero, we have a gutter
		mov	cx, 0			; assume no gutter
		jle	haveGutter
		mov	cx, LABEL_GUTTER_SIZE
haveGutter:
		mov	curJob.SJI_gutterWidth, cx

		.leave
		ret
InitLabelVariables	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLabelPageTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the translation betwen successive labels on a page

CALLED BY:	INTERNAL
		CalcDocOrientation
PASS:		curJob	- SpoolJobInfo
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Get translation in *document* coordinates

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetLabelPageTranslation		proc	far
		uses	ax, bx, cx, dx
curJob		local	SpoolJobInfo	; all we need to process this job
		.enter inherit

		; calculate the adjusted width =
		;	docWidth * actual scale factor / final scale factor

		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
		LONG	jz	done
		movwwf	dxcx, curJob.SJI_xScaleFactor
		movwwf	bxax, curJob.SJI_finalScaleFactor
		call	GrUDivWWFixed
		mov	bx, curJob.SJI_info.JP_docSizeInfo.PSR_width.low
		clr	ax
		call	GrMulWWFixed
		movwwf	ss:curJob.SJI_adjustedWidth, dxcx

		; calculate the adjusted height =
		;	docHeight * actual scale factor / final scale factor

		movwwf	dxcx, curJob.SJI_yScaleFactor
		movwwf	bxax, curJob.SJI_finalScaleFactor
		call	GrUDivWWFixed
		mov	bx, curJob.SJI_info.JP_docSizeInfo.PSR_height.low
		clr	ax
		call	GrMulWWFixed
		movwwf	ss:curJob.SJI_adjustedHeight, dxcx

		; check to see if we rotated the document.  If so, we do 
		; this a bit differently

		mov	ax, curJob.SJI_defMatrix.TM_e21.WWF_int
		or	ax, curJob.SJI_defMatrix.TM_e21.WWF_frac
		jnz	rotatedDoc

		; To move from one column to another:
		;	X-trans = adjusted width + gutter
		;	Y-trans = 0

		movwwf	bxax, curJob.SJI_adjustedWidth
		add	bx, curJob.SJI_scaledGutter
		movwwf	curJob.SJI_labelColX, bxax
		clrwwf	curJob.SJI_labelColY

		; To move from one row to aother:
		;	X-trans = -((columns-1) * (adjusted width + gutter))
		;	Y-trans = adjusted height

		mov	dl, curJob.SJI_labelColumns
		clr	dh
		dec	dx
		clr	cx
		call	GrMulWWFixed
		negwwf	dxcx
		movwwf	curJob.SJI_labelRowX, dxcx
		movwwf	curJob.SJI_labelRowY, curJob.SJI_adjustedHeight, ax
done:
		.leave
		ret

		; Document has been rotated to fit on the label better.  
		; We want to fill the labels from the top of the page
		; towards the bottom, but for convenience we fill from
		; right towards left across the page. Maybe someday we'll
		; go the other direction :)
rotatedDoc:
		; To move from one column to another:
		;	X-trans = 0
		;	Y-trans = -(adjusted height + gutter)

		clrwwf	curJob.SJI_labelColX
		movwwf	bxax, curJob.SJI_adjustedHeight
		add	bx, curJob.SJI_scaledGutter
		negwwf	bxax
		movwwf	curJob.SJI_labelColY, bxax

		; To move from one row to another
		;	X-trans = adjusted width
		;	Y-trans = (adjusted height + gutter) * (# cols - 1)

		mov	dl, curJob.SJI_labelColumns
		clr	dh
		dec	dx
		neg	dx
		clr	cx
		call	GrMulWWFixed
		movwwf	curJob.SJI_labelRowY, dxcx
		movwwf	curJob.SJI_labelRowX, curJob.SJI_adjustedWidth, ax
		jmp	done		
GetLabelPageTranslation		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLabelPageCenteringUpright
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate any centering of the block of labels on the page

CALLED BY:	INTERNAL
		ScaleToFit
PASS:		curJob	- SpoolJobInfo
		dx.cx	- X scale factor
		di	- current X translation (for centering)
		si	- current Y translation (for centering)
RETURN:		di	- updated X translation
		si	- updated Y translation
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcLabelPageCenteringUpright	proc	far
		uses	ax, bx, cx, dx
curJob		local	SpoolJobInfo
		.enter	inherit
	
		; Calculate the scaled gutter width

		movwwf	bxax, dxcx
		call	CalcScaledGutterWidth

		; Calculate the difference between the default page
		; size & the block of labels, divide both differences
		; in half, and then add those values into the current
		; translation values

		call	GetLabelMarginsLow
		add	di, dx
		add	si, bx

		; We then need to *subtract* the margins, as that
		; is what the caller expects

		sub	di, paperInfo.PSR_margins.PCMP_left
		sub	si, paperInfo.PSR_margins.PCMP_top

		.leave
		ret
CalcLabelPageCenteringUpright	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLabelPageCenteringRotated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate any centering of the block of labels on the page

CALLED BY:	INTERNAL
		ScaleToFit
PASS:		curJob	- SpoolJobInfo
		bx.ax	- Y scale factor
		di	- current X translation (for centering)
		si	- current Y translation (for centering)
RETURN:		di	- updated X translation
		si	- updated Y translation
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Note that a -90 degree rotation has been applied, so
		the sign of the Y translations is inverted.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcLabelPageCenteringRotated	proc	far
		uses	ax, bx, cx, dx
curJob		local	SpoolJobInfo
		.enter	inherit
	
		; Calculate the scaled gutter width

		call	CalcScaledGutterWidth

		; Calculate the difference between the default page
		; size & the block of labels, divide both differences
		; in half, and then add those values into the current
		; translation values

		call	GetLabelMarginsLow
		add	di, bx
		sub	si, dx

		; We then need to *subtract* the margins, as that
		; is what the caller expects.

		sub	di, paperInfo.PSR_margins.PCMP_left
		add	si, paperInfo.PSR_margins.PCMP_top

		.leave
		ret
CalcLabelPageCenteringRotated	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcScaledGutterWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the scaled gutter width

CALLED BY:	INTERNAL
		CalcLabelPageCenteringUpright, CalcLabelPageCenteringRotated
PASS:		curJob	- SpoolJobInfo
		bx.ax	- scale factor
RETURN:		nothing
DESTROYS:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		sets curJob.SJI_scaledGutter

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcScaledGutterWidth	proc	near
curJob		local	SpoolJobInfo
		.enter	inherit
	
		; Divide gutter by scale factor, as the value will
		; later be scaled by the GState

		mov	dx, ss:[curJob].SJI_gutterWidth
		clr	cx
		call	GrUDivWWFixed
		rndwwf	dxcx
		mov	ss:[curJob].SJI_scaledGutter, dx

		.leave
		ret
CalcScaledGutterWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLabelMarginsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out how to translate a page to get to the first label.
		(any centering we are performing on the labels)

CALLED BY:	INTERNAL
		GetLabelMarginsWWFixed, GetLabelMarginsScaledDWord
PASS:		curJob		- inherited stack frame
RETURN:		dx		- X translation
		bx		- Y translation
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (not tractor fed)
			calculate translations for centering
		else
			return zero
		endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetLabelMarginsLow	proc	near
		uses	ax, cx, di, si, ds
curJob		local	SpoolJobInfo
		.enter	inherit

		; If we're in tractor feed, no centering
		
		mov	bx, curJob.SJI_pstate	; grab pstate handle
		call	MemLock			; ax -> PState
		mov	ds, ax
		test	ds:[PS_paperInput], mask PIO_TRACTOR
		call	MemUnlock		; (flags preserved)
		mov	bx, 0
		mov	dx, 0
		jnz	done

		; Else calculate the centering marGet the margins

		call	GetLabelMarginsRealLow
done:
		.leave
		ret
GetLabelMarginsLow		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLabelMarginsRealLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out how to translate a page to get to the first label.
		(any centering we are performing on the labels)

CALLED BY:	INTERNAL
		GetLabelMarginsWWFixed, GetLabelMarginsScaledDWord
PASS:		curJob		- inherited stack frame
RETURN:		dx		- X translation
		bx		- Y translation
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (not tractor fed)
			Get height of block of labels
			Subtract from default paper height.
			Divide in half
			Get width of block of labels
			Subtract from default paper width.
			Divide in half
			Return result.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetLabelMarginsRealLow	proc	near
		uses	di, si, ds
curJob		local	SpoolJobInfo
		.enter	inherit


		; Grab the default page size

		sub	sp, size PageSizeReport
		segmov	ds, ss, si
		mov	si, sp				; ds:si -> scratch
		call	SpoolGetDefaultPageSizeInfo
		mov	di, ds:[si].PSR_height.low	; si = default height
		mov	si, ds:[si].PSR_width.low	; si = default width
		add	sp, size PageSizeReport

		; Grab the printable width & height of the labels, and then
		; calculate the centering
		
		call	CalcLabelSheetSizeLow		; bx -> width
							; dx -> height
		sub	si, bx				; si = width difference
		sar	si, 1				; divide in half
		sub	di, dx				; di = height difference
		sar	di, 1				; divide in half
		mov	dx, si				; X margin
		mov	bx, di				; Y margin
done::
		.leave
		ret
GetLabelMarginsRealLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLabelSheetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate (guesstimate) the dimensions of the paper
		on which the labels are mounted

CALLED BY:	INTERNAL
		InitPrinterDriver
PASS:		inherited spooler variables
RETURN:		ax	- paper width
		si	- paper height
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		See assumptions above under "Label Conventions"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcLabelSheetSize	proc	far
		uses	bx, cx, dx, ds, di
curJob		local	SpoolJobInfo
		.enter	inherit

		; Query for the default page size. We'll use this later
		; to see how close we are to the calculated paper size

		segmov	ds, ss, si
		sub	sp, size PageSizeReport
		mov	si, sp				; ds:si -> PageSizeRep
		call	SpoolGetDefaultPageSizeInfo
		mov	di, ds:[si].PSR_width.low	; get def width
		mov	si, ds:[si].PSR_height.low	; get def height
		add	sp, size PageSizeReport

		; Calculate the width of the page, including any gutters
		; between the labels.

		call	CalcLabelSheetSizeLow
		mov	ax, di				; ax x si -> default
							; bx x dx -> actual
							; (w/o margins)

		; Determine if the we're close to the default paper size.
		; If we're close to that, use it instead of the calculated
		; size, as labels ususally come on normally-sized paper,
		; and we don't want to confuse any "intelligent" printers
		; with non-standard paper sizes.

		sub	di, bx				; if too wide, use
		js	customPaperSize			; ...calculated values
		jz	checkHeight			; if equal, check height
		sub	di, paperInfo.PSR_margins.PCMP_left
		sub	di, paperInfo.PSR_margins.PCMP_right
		js	checkHeight
		cmp	di, 90				; if within 1.25"
		jg	customPaperSize
checkHeight:
		mov	di, si
		sub	di, dx				; if too tall, use
		js	customPaperSize			; ...calculated values
		jz	done				; if equal, we're done
		sub	di, paperInfo.PSR_margins.PCMP_top
		sub	di, paperInfo.PSR_margins.PCMP_bottom
		js	done
		cmp	di, 90				; if within 1.25"
		jg	customPaperSize
done:
		.leave
		ret

		; We have a custom paper size.  We need to include any
		; centering margins.  Unfortunately, we don't yet know if
		; we are operating in tractor-feed mode yet, so we assume that
		; we are not.
customPaperSize:
		mov	ax, bx				; ax <- label width
		mov	si, dx				; si <- label height
		call	GetLabelMarginsRealLow
		add	ax, dx				; add left margin
		add	ax, dx				; add right margin
		add	si, bx				; add top margin
		add	si, bx				; add bottom margin
		jmp	done
CalcLabelSheetSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLabelSheetSizeLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the printable area covered by the labels

CALLED BY:	INTERNAL

PASS:		inherited spooler variables

RETURN:		BX	= Total width (including gutters)
		DX	= Total height (including gutters)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcLabelSheetSizeLow	proc	near
		uses	ax, cx
curJob		local	SpoolJobInfo
		.enter	inherit
	
		; Calculate the width of the page, including any gutters
		; between the labels.

		mov	cl, curJob.SJI_labelColumns
		clr	ch			; cx = # of columns
		mov	ax, paperInfo.PSR_width.low
		mul	cx
		mov_tr	dx, ax
		mov	ax, curJob.SJI_gutterWidth
		dec	cl			; (columns - 1) gutters
		mul	cl			; ...between labels
		add	ax, dx
		push	ax			; save width
		
		; Calculate the height of the page

		mov	cl, curJob.SJI_labelRows
		clr	ch			; cx = # of rows
		mov	ax, paperInfo.PSR_height.low
		mul	cx
		mov_tr	dx, ax				; dx = total height
		pop	bx				; bx = total width

		.leave
		ret
CalcLabelSheetSizeLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGraphicsLabels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print out a single page in graphics mode

CALLED BY:	INTERNAL
		DoGraphicsPrinting

PASS:		inherits stack frame

RETURN:		ax	- code returned from DrawString

DESTROYED:	just about everything

PSEUDO CODE/STRATEGY:
		handle the printing of a single page (of paper, not a page
		of the document)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGraphicsLabels proc	far
curJob		local	SpoolJobInfo
		.enter	inherit

		; starting with a fresh transformation matrix, so apply 
		; our stuff to fit output to the printer resolution

		mov     di, curJob.SJI_bmWinHan         ; get win handle in di
		movwwf	dxcx, curJob.SJI_pXscale	; set up xscale factor
		movwwf	bxax, curJob.SJI_pYscale	; set up yscale factor
		mov     si, WIF_DONT_INVALIDATE         ; don't force a redraw
		call    WinApplyScale                   ; 

		; set the default transformation matrix.  This was determined
		; by CalcDocOrientation, and handles the automatic rotation
		; of documents to fit on the paper better.

		mov     di, curJob.SJI_bmWinHan         ; get win handle in di
		segmov	ds, ss, si
		lea	si, curJob.SJI_defMatrix	; set it from here
		mov     cx, WIF_DONT_INVALIDATE         ; don't force a redraw
		call	WinApplyTransform		; set the TMatrix

		; the code from here on down is responsible for the printing
		; of a single PAPER page (as opposed to just a DOCUMENT page).
		; That means we have to deal with tiling multiple doc pages
		; over the paper.
		; let the printer know we're starting a page

if _NONSPOOL    ;--------------------------------------------------------------
		push	ds
		mov	bx, curJob.SJI_pstate
		call	MemLock
		mov	ds, ax
		test	ds:[PS_paperInput], mask PIO_MANUAL
		call	MemUnlock			; (preserves flags)
		pop	ds
		jz	startPage			; no, auto-fed paper
checkPaper::
		mov	di, DR_PRINT_ESC_WAIT_FOR_MECH	; wait for print engine
		mov	bx, curJob.SJI_pstate
		call	curJob.SJI_pDriver

		mov	di, DR_PRINT_ESC_GET_ERRORS	; set the code
		mov	al, PJLP_noupdate
		call	curJob.SJI_pDriver		; call the driver
		test	al, mask PER_MPE		; paper present?
		jnz	askForPaper
startPage:
		call	ProcessStartPage

                ; This should load a sheet of paper, and now we will test for
                ; errors on the load.

		call	GetPrinterReturnCode
		cmp	ax, PDR_PAPER_JAM_OR_EMPTY	; jammed or empty?
		jne	startSwathes			; if not, let er rip...
askForPaper:
		call	NonSpoolPaperFeedBox
		cmp	ax, IC_OK
		je	startPage			; start page
		jmp	shutdownHere			; else shutdown

else    ; not _NONSPOOL -------------------------------------------------------

		call	ProcessStartPage
		jnc	startSwathes			;  check for errors
		mov	ax, GSRT_FAULT			; make like something
		jmp	doneDocPage			;  bad happened

endif           ; _NONSPOOL ---------------------------------------------------

		; set whatever page-bound variables we need to
startSwathes:
		movdw	curJob.SJI_curScan, 0		; start at top of page

		; This loop draws the page over and over into each swath, 
		; and sends the swath off to be printed.
swathLoop:
		; must reset SJI_labelfPos for each swath, or else we'll
		; be printing the wrong pages if we are printing more than
		; one copy

		movdw	curJob.SJI_labelfPos, curJob.SJI_fPos, ax

		; we need to save this transformation, so that we know what
		; to apply when we do the follow-on swaths.

		lea	si, curJob.SJI_oldMatrix	; ds:si->buffer space
		call	GetOurTransformation		; get old TMatrix

		; re-initialize the bitmap

		mov	di, curJob.SJI_gstate		; get string handle
		call	GrClearBitmap			; di = bitmap gstate

		; the file is already open, associate it with a graphics
		; string handle

		mov	cx, GST_STREAM		; type of gstring it is
		mov	bx, curJob.SJI_fHan	; bx gets file handle
		call	GrLoadGString		; si = string handle
		mov	curJob.SJI_gstring, si	; store the handle

		; save the numCopies flag, since we trash it inside the loop

		mov	al, curJob.SJI_numCopies
		push	ax

		; We print across, then down, so handle the y loop on the 
		; outside and the xloop on the inside.

		mov	cl, curJob.SJI_labelRows	; init y loop variable
		mov	curJob.SJI_curRow, cl
tileInY:
		; next we implement the loop to tile across.  Like the y loop
		; we need to keep track of the current TM

		mov	cl, curJob.SJI_labelColumns	; init #pages across
		mov	curJob.SJI_curColumn, cl
tileInX:
		call	BumpPhysPageNumber
		mov	di, curJob.SJI_gstate		; get state handle
		call	GrSaveState

if	_DEBUG
		; For debugging purposes, draw the outline of the label

		clr	ax
		clr	bx
		mov	cx, curJob.SJI_info.JP_docSizeInfo.PSR_width.low
		mov	dx, curJob.SJI_info.JP_docSizeInfo.PSR_height.low
		call	GrDrawRect
endif

		; Now draw the page

		clr	ax				; no parameters
		clr	bx				;  draw at (0,0)
		mov	dx, mask GSC_NEW_PAGE		; stop at end of page
		mov	si, curJob.SJI_gstring		; get string handle
		call	GrDrawGString			; draw the string

		call	GrRestoreState
		push	dx, cx				; save GSRetType & data

		; if we are printing un-collated copies, print another one.

		test	curJob.SJI_info.JP_spoolOpts, mask SO_COLLATE
		jnz	skipNewPage			;  no copies
		dec	curJob.SJI_numCopies		; one less copy to do
		jle	skipNewPage
		call	PositionGStringFile
		jmp	nextLabel

		; skip over the NEW_PAGE, and get the copy count for the next
		; page.  And record the new start position in the file.  If 
		; the end of the string is after the NEW_PAGE, treat it like
		; an end-swath condition
skipNewPage:
		mov	ax, 1				; not GSRT_COMPLETE
		cmp	dx, GSRT_NEW_PAGE		; skip NEW_PAGE only
		je	skipOne				;  if GSRT_NEW_PAGE
		pop	dx, cx				; else fixup stack
		jmp	checkCollated			;  and we're done
skipOne:
		mov	al, GSSPT_SKIP_1
		call	GrSetGStringPos

		; record the current file position, so we can set it at the
		; end of the page.

		mov	al, FILE_POS_RELATIVE
		mov	bx, curJob.SJI_fHan		; fetch file handle
		clr	cx, dx
		call	FilePos				; set to start o page
		movdw	curJob.SJI_labelfPos, dxax	; save file position
		
		; more un-collated copies work.  Reset the numCopies and 
		; update the filePos

		test	curJob.SJI_info.JP_spoolOpts, mask SO_COLLATE
		jnz	nextLabel			;  no copies
		push	ds
		mov	bx, curJob.SJI_pstate
		call	MemLock				; grab #copies from 
		mov	ds, ax				;  JobParams in pstate
		mov	al,ds:[PS_jobParams].JP_numCopies
		mov	curJob.SJI_numCopies, al	; for uncollated cops
		call	MemUnlock
		pop	ds

		; handle printing the next page to the right for tiled output
		; the xloop is on the inside, so do that one first
nextLabel:
		sub	curJob.SJI_curColumn, 1		; one less page to do
		jle	nextPassAcross			; finished this swoosh

		; still have more to do across a swoosh (this is a technical
		; term describing one pass of "pages" across the document ;)

		movwwf	dxcx, curJob.SJI_labelColX	; translate to next 
		movwwf	bxax, curJob.SJI_labelColY	;  column
		mov	di, curJob.SJI_bmWinHan		; get window handle
		mov	si, WIF_DONT_INVALIDATE
		call	WinApplyTranslation		; apply old one
		pop	dx, cx				; restore GSRetType
		mov	al, 0
		call	CheckForGStringDone
		jc	checkCollated
		jmp	tileInX

nextPassAcross:
		sub	curJob.SJI_curRow, 1		; one less page to do
		jle	swathDonePushed

		; still have more swooshes to do 

		mov	di, curJob.SJI_bmWinHan		; get window handle
		mov	si, WIF_DONT_INVALIDATE
		movwwf	dxcx, curJob.SJI_labelRowX	; translate down/left
		movwwf	bxax, curJob.SJI_labelRowY
		call	WinApplyTranslation		; DONT_INVAL still ok
		pop	dx, cx				; restore GSRetType/dat
		mov	al, 1				; signal tileInY action
		call	CheckForGStringDone
		jc	checkCollated
tileInYShort:
		jmp	tileInY
		
		; done with one set of pages, check to see if we need to do
		; another set
checkCollated:
		test	curJob.SJI_info.JP_spoolOpts, mask SO_COLLATE
		jz	swathDone			;  nope, quit
		dec	curJob.SJI_numCopies 		; one less to do
		jle	swathDone			;  done with all copies

		; doing another copy.  Reset the file position back to the 
		; beginning of the file and go at it.

		clrdw	curJob.SJI_labelfPos
		mov	si, curJob.SJI_gstring		; si = string handle
		call	PositionGStringFile
		tst	al				; check flag set above
		jnz	tileInYShort
		jmp	tileInX

		; DONE WITH A SWATH
		; this swath is done, destroy the string so we can start it
		; up again.  
swathDone:
		push	dx, cx				; re-save return codes 
swathDonePushed:
		mov	si, curJob.SJI_gstring		; get string handle
		mov	dl, GSKT_LEAVE_DATA		; don't kill the data
		call	GrDestroyGString		; si = string handle

		; OK, it's built out, so send it on down to be printed

if _NONSPOOL    ;--------------------------------------------------------------

                call    SpoolLockPrintJob               ; set the semaphore.

                ; OK, it's built out, so send it on down to be printed

                mov     dx, curJob.SJI_bmFileHan        ; pass huge arr handle
                mov     cx, curJob.SJI_bmHan
                mov     bx, curJob.SJI_pstate           ; pass the pstate
                mov     di, DR_PRINT_SWATH              ; the big one
                call    curJob.SJI_pDriver              ; print it
                LONG jc ejectPaper

                call    SpoolUnlockPrintJob             ; reset the semaphore.

                ; General check Error handling goes here.
                ; Make sure things are still ok after printing a swath.

                call    SpoolProcessErrors
                LONG jc exitErr                         ; catastophic error?
                cmp     ax,GSRT_FAULT                   ; fault?
                LONG je ejectPaper                      ; yes - eject paper

else    ; not _NONSPOOL -------------------------------------------------------

		mov	dx, curJob.SJI_bmFileHan	; pass huge arr handle
		mov	cx, curJob.SJI_bmHan		
		mov	bx, curJob.SJI_pstate		; pass the pstate
		mov	di, DR_PRINT_SWATH		; the big one
		call	curJob.SJI_pDriver		; print it
		LONG jc	exitErr

endif           ; _NONSPOOL ---------------------------------------------------


		; see if we have more to print, update all the nice vars
		movdw	dxbx, curJob.SJI_curScan	; get current position
		add	bx, curJob.SJI_swathH		; calc new position
		adc	dx, 0
		movdw	curJob.SJI_curScan, dxbx	; update position
		cmpdw	dxbx, curJob.SJI_pageH		; done ?
		pop	ax, cx				; restore GSRetType,data
		LONG	jae	donePage		;  yes, time to reset
		push	ax, cx				; save GSRetType & data
		subdw	dxbx, curJob.SJI_pageH		; see if getting close
		negdw	dxbx
		tst	dx				; if still large
		jnz	applyTranslation
		cmp	bx, curJob.SJI_swathH		; < 1 swath left ?
		jae	applyTranslation		;  no, continue
		mov	di, curJob.SJI_gstate		; pass bitmap handle
		call	GrClearBitmap
 
 		; since we are on the last swath, make sure that the
 		; bitmap height field in the Huge bitmap reflects how
 		; much we are actually going to send to the print driver.
 
		mov	dx, bx				; save word of height
		call	AdjustBitmapHeight

		; apply proper window translation to draw the next piece
applyTranslation:
		segmov	ds, ss, si			; ds -> stack
		mov	di, curJob.SJI_bmWinHan		; window handle
		mov	cx, WIF_DONT_INVALIDATE
		call	WinSetNullTransform		; set things back
		mov	si, cx				; si get INVAL flag
		mov	bx, curJob.SJI_swathH		; translate this much
		neg	bx				; bx.ax = y translation
		clr	ax
		clr	cx				; dx.cx = x translation
		clr	dx
		call	WinApplyTranslation		; DONT_INVAL still ok
		mov	cx, WIF_DONT_INVALIDATE
		lea	si, curJob.SJI_oldMatrix	; ds:si->buffer space
		call	WinApplyTransform		; apply old one

		; set the file position back to start of the page (paper)

		call	ResetFilePosition		; set to start o page

		; check queue info to see if we need to quit

		call	CheckForErrors			; check flag in q info
		pop	ax, cx				; restre GSRetType,data
		jc	abortDoc			;  yes, abort the job
		cmp	ax, GSRT_FAULT			; something bad ?
		je	donePage			;  yes, die
		pop	bx				; restore numCopies
		mov	curJob.SJI_numCopies, bl
		jmp	swathLoop			;  else print nxt swath

		; printing interrupted
abortDoc:
		mov	ax, GSRT_FAULT			; fake completion

		; done with the current page, so tell the printer driver
donePage:
		pop	bx				; restore numCopies

		; record new file pos

		push	ax, cx
		mov	al, FILE_POS_START
		mov	bx, curJob.SJI_fHan		; fetch file handle
		movdw	cxdx, curJob.SJI_labelfPos	; ...and position
		call	FilePos				; set to start of page
		movdw	curJob.SJI_fPos, dxax
		pop 	ax, cx

		mov	bx, cx
		call	ProcessEndPage

 		; since we are on the last swath, make sure that the
 		; bitmap height field in the Huge bitmap reflects how
 		; much we are actually going to send to the print driver.
 
		pushf					; save carry
		mov	dx, curJob.SJI_swathH		; get swath height
		call	AdjustBitmapHeight
		popf					; restore carry status

if _NONSPOOL    ;--------------------------------------------------------------
checkEndReturnCode:
		jc	shutdownHere
		cmp	ax, GSRT_FAULT			; done ?
		je	doneDocPage			;  yes, all done
		push	ax				; save GSRet code.
		call	GetPrinterReturnCode		; get returns.
		cmp	ax, PDR_NO_RETURN
		pop	ax				; get back GSRet code.
		je	doneDocPage
		mov	cx, PERROR_PAPER_MISFEED	; set jammed error code
		clr	dx
		call	SpoolErrorBox			; he can only answer OK
		TestUserStandardDialogResponses\
		SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
		cmp	ax, IC_OK			; if affirmative
		jne	shutdownHere			; if not OK, quit...
							; if OK, try again...
		mov	di, DR_PRINT_END_PAGE		; spit the paper out
		mov	bx, curJob.SJI_pstate		; pass the pstate
		call	curJob.SJI_pDriver
		mov	ax, GSRT_COMPLETE		; dumy GString ret code
		jmp	checkEndReturnCode

else	; not _NONSPOOL -------------------------------------------------------

		jnc	doneDocPage

endif           ; _NONSPOOL ---------------------------------------------------

shutdownHere:
		mov	ax, GSRT_FAULT			; there's a problem


		; All done with this piece of paper.  Mission accomplished.
doneDocPage:
		mov	di, curJob.SJI_bmWinHan		; get window handle
		mov	cx, WIF_DONT_INVALIDATE		; never inval the window
		call	WinSetNullTransform		; set it back
		.leave
		ret

if _NONSPOOL    ;--------------------------------------------------------------
ejectPaper:
                mov     di, DR_PRINT_END_PAGE           ; spit the paper out
                mov     bx, curJob.SJI_pstate           ; pass the pstate
                call    curJob.SJI_pDriver

                call    GetPrinterReturnCode            ; get returns.
                cmp     ax, PDR_NO_RETURN
                je      exitErr

                mov     cx, PERROR_PAPER_MISFEED        ; set jammed error code
                clr     dx
                call    SpoolErrorBox                   ; can only answer OK
                TestUserStandardDialogResponses \
		SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
                cmp     ax, IC_OK                       ; if affirmative
                je      ejectPaper                      ; if OK, try again...
endif           ; _NONSPOOL ---------------------------------------------------

		; there was an error in printing.  just exit
exitErr:
		pop	ax, ax, ax			; restore stack
		jmp	shutdownHere
PrintGraphicsLabels endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForGStringDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Done with the string ?

CALLED BY:	INTERNAL
		PrintGraphicsLabels
PASS:		nothing
RETURN:		carry	- set if at end of gstring
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForGStringDone	proc	near
		uses	cx, ax, si, di
curJob		local	SpoolJobInfo
		.enter	inherit
		clr	cx
		mov	si, curJob.SJI_gstring		; get string handle
		mov	di, curJob.SJI_gstate		; get state handle
		call	GrGetGStringElement
		jcxz	atEnd
		cmp	al, GR_END_GSTRING
		je	atEnd
		clc
done:
		.leave
		ret

atEnd:
		stc					; signal finished
		jmp	done
CheckForGStringDone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionGStringFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-position a file-based GString

CALLED BY:	INTERNAL
		PrintGraphicsLabels

PASS:		curJob	- SpoolJobInfo
		si	- GString handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionGStringFile	proc	near
curJob		local	SpoolJobInfo
		uses	ax, bx, cx, dx
		.enter	inherit

		; Notify the GString code to not use the cached data,
		; through this hack of resetting the current position.
		; We do this to prevent the playing of the next element
		; (GR_NEW_PAGE), which would be rather counter-productive.

		mov	al, GSSPT_BEGINNING
		call	GrSetGStringPos

		; Reset the file's position

		mov	al, FILE_POS_START
		mov	bx, curJob.SJI_fHan		; fetch file handle
		movdw	cxdx, curJob.SJI_labelfPos	; ..and position
		call	FilePos

		.leave
		ret
PositionGStringFile	endp

PrintLabel	ends
