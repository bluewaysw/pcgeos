COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Vis
FILE:		visCompGeometry.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	VisCompClass		General purpose Visible composite object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/89		Initial version

DESCRIPTION:
	This file contains routines to implement the geometry manager
	messages in VisCompClass.
	
	$Id: visCompGeometry.asm,v 1.1 97/04/07 11:44:26 newdeal Exp $

-------------------------------------------------------------------------------@

VisUpdate segment resource




COMMENT @----------------------------------------------------------------------

METHOD:		VisCompRecalcSizeHandler -- 
		MSG_VIS_RECALC_SIZE for VisCompClass

DESCRIPTION:	Handles recalc size for composites.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RECALC_SIZE
		cx, dx  - size suggestions

RETURN:		cx, dx  - size to use
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/30/92		Initial Version

------------------------------------------------------------------------------@

VisCompRecalcSizeHandler	method dynamic	VisCompClass, \
				MSG_VIS_RECALC_SIZE
	clr		bp
	FALL_THRU	VisCompRecalcSize

VisCompRecalcSizeHandler	endm


		

COMMENT @----------------------------------------------------------------------

METHOD:	 	VisCompRecalcSize

DESCRIPTION:	Calculates the size of objects, using geometry manager.

PASS:
	*ds:si - instance data (ds:di is NOT valid!)
	cx -- 	one of several bits of info for width:
			   mask RSA_CHOOSE_OWN_SIZE -- choose your width
			   width -- use this value if at all possible,
			        to fill up a composite widthwise
		
	dx -- 	same info, for height
	bp --   VisCompSpacingMarginsInfo

	ax, bx	-- DON'T CARE (may safely be called using CallMod)

RETURN:	cx --   width it wants to be
	dx --   height it wants to be
	ds -- updated to point at segment of same block as on entry
	ax, bp -- destroyed

ALLOWED TO DESTROY:
	nothing
	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:
       Get the spacing for the composite
       call SwapIfVertical to normalize passed dimensions as if horiz comp
       if length margins smaller than passed length, or desired length
            subtract length margins from passed length
       if GEO_EXPAND_WIDTH_TO_FIT set for composite 
            initialize returnWidth to passedWidth
       else 
            initialize returnWidth to zero
       endif
       if HAS_MIN_SIZE
       	    MSG_GET_MINIMUM_SIZE (minWidth, minLength)
       	    returnWidth = max (returnWidth, minWidth)
	    passedLength = max (passedLength, minLength)
       endif
       initialize returnLength to zero
       initialize centerOffset to returnLength / 2
       
       FIRST PASS:
       child = firstChunk(composite)
       while (child <> NIL)
           if child is to be included in geometry
	      resize child with desired length and passed width
	      add child's length and lengthSpacing to returnLength
	      
	      if wrapping and (passedLength < child's new length)
	          passedLength = child's new length
		  
	      if WJ_CENTER
	      	  Do some neat centering stuff, diagrammed in DoDesiredResize
	      endif
	   endif 
	   child = nextChild(child)
       end  {while}
       
       if passed desired length
           call resize hints message on child
	   if WJ_CENTER
	       	do some checking of centerOffset
	   if returnLength changed, use it and repeat first pass again
	      
       if passed and return widths differ
           repeat pass 1 with passedWidth = returnWidth
	   
       lineWidth = returnWidth	   
      
       if not wrapping and not passed desired length
           extraLength = length - returnLength
       
       longestLine = 0
       returnLength = -lengthSpacing
       
       SECOND PASS:
       child = firstChunk(composite)
       while (child <> NIL)
           if child is to be included in geometry
	       oldLength = curren length of child
	       
	       tempLength = max(0, extraLength+oldLength) 
	       tempWidth = lineWidth
	       RESIZE (child, tempLength, tempWidth
		   
	       if child's new length > lineWidth
	           repeat pass 1 with child's new length as passedLength
		   
	       extraLength = oldLength - child's new length + extraLength
	       add child's new length and lengthSpacing to returnLength
	       
	       if wrapping
	           if returnLength > length passed
		       add lineWidth and widthSpacing to returnWidth
		       returnLength = child's new length
		       
	       if returnLength > longestLine
	           longestLine = returnLength
	   endif       
	   child = nextChild(child)
       endwhile
       
       ; recalc which length to pass back
       if wrapping
           returnLength = longestLine
           else if returnLength < passedLength
             if not expanding to fit
	        returnLength = passedLength
       else if we can chop the length
           returnLength = passedLength
       endif
       
       ; determine which width
       if not passed desired width, and we can chop width
           returnWidth = passedWidth
	   
       add margins back into returnWidth and length and return them

KNOWN BUGS/SIDE EFFECTS/IDEAS:
      Definitely doesn't work if you have resizable (read: pane) objects in
      a wrapping structure.  We'll, actually it does work, but you can't
      change the size of the pane from what is desired.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/13/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@


GenericJustifications	etype	byte
	GJ_BEGIN_JUSTIFIED		enum	GenericJustifications
	GJ_END_JUSTIFIED		enum	GenericJustifications
	GJ_CENTERED			enum	GenericJustifications
	GJ_FULL_JUSTIFIED		enum	GenericJustifications
	
CheckHack	<GJ_BEGIN_JUSTIFIED eq WJ_LEFT_JUSTIFY_CHILDREN>
CheckHack	<GJ_BEGIN_JUSTIFIED eq HJ_TOP_JUSTIFY_CHILDREN>
CheckHack	<GJ_END_JUSTIFIED eq WJ_RIGHT_JUSTIFY_CHILDREN>
CheckHack	<GJ_END_JUSTIFIED eq HJ_BOTTOM_JUSTIFY_CHILDREN>
CheckHack	<GJ_CENTERED eq WJ_CENTER_CHILDREN_HORIZONTALLY>
CheckHack	<GJ_CENTERED eq HJ_CENTER_CHILDREN_VERTICALLY>
CheckHack	<GJ_FULL_JUSTIFIED eq WJ_FULL_JUSTIFY_CHILDREN_HORIZONTALLY>
CheckHack	<GJ_FULL_JUSTIFIED eq HJ_FULL_JUSTIFY_CHILDREN_VERTICALLY>
	
DimensionAttrs	record		;non-directional versions of GeoDimensionAttrs
	:4
	DA_JUSTIFICATION  GenericJustifications:2
	DA_EXPAND_TO_FIT_PARENT:1
	DA_DIVIDE_SPACE_EQUALLY:1
DimensionAttrs	end

CheckHack  <(mask DA_JUSTIFICATION) eq (mask VCGDA_WIDTH_JUSTIFICATION shr 4)>
CheckHack	<mask DA_EXPAND_TO_FIT_PARENT eq \
		 (mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT shr 4)>
CheckHack	<mask DA_DIVIDE_SPACE_EQUALLY eq \
		 (mask VCGDA_DIVIDE_WIDTH_EQUALLY shr 4)>
CheckHack	<mask DA_JUSTIFICATION eq (mask VCGDA_HEIGHT_JUSTIFICATION)>
CheckHack	<mask DA_EXPAND_TO_FIT_PARENT eq \
		 (mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT)>
CheckHack	<mask DA_DIVIDE_SPACE_EQUALLY eq \
		 (mask VCGDA_DIVIDE_HEIGHT_EQUALLY)>
		
		
VCG_localVars	struct
    VCG_childHandle	word			;keep handle of current child
    VCG_compHandle	word			;keep composite handle
    VCG_longestLine	word			;keeps longest line for wraps
    VCG_passedWidth	word			;may need later
    VCG_lengthSpacing	word			;length spacing
    VCG_widthSpacing	word			;width spacing
    VCG_returnWidth	word			;return width
    VCG_minWidth	word			;minimum width of composite
    VCG_minLength	word			;minimum length of composite
    VCG_numPasses	byte			;count first passes
    VCG_lengthJust	GenericJustifications 	;justification along length
    VCG_widthJust	GenericJustifications 	;justification along width
    VCG_lengthAttrs	DimensionAttrs		;other length attributes
    VCG_widthAttrs	DimensionAttrs		;other width attributes
    VCG_wrapCount	word			;# of children before wrapping
    VCG_childCount	word			;current child count
    
    VCG_lineWidth	word			;temporary data that needs
    VCG_centerOffset	word			;to be stored after we're done
    VCG_secondWidth	word			;via a MSG_VIS_COMP_SAVE_TEMP_
    						;GEO_DATA.
    VCG_spacingStuff	word			;keep spacing, margins stuff 
						;  here
    VCG_lengthToPassKids  word			;value to pass kids on first
						;  pass of pass 1, usually
						;  RSA_CHOOSE_OWN_SIZE.
    VCG_passedLength	word			;length being used in pass 2
    align	word
VCG_localVars	ends
		
geoVarsDi	equ	<ss:[di - size VCG_localVars]>
		
	
VisCompRecalcSize	proc	far
	class	VisCompClass
	geoVars	local	VCG_localVars
	uses	bx, si, di, es
	.enter	inherit
	
EC <	tst	cx				;see if desired passed       >
EC <	jns	tryDx				;nope, branch                >
EC <	test	cx, not mask RSA_CHOOSE_OWN_SIZE ;see if any other bits set   >
EC <	ERROR_NZ  UI_BAD_CHOOSE_OWN_SIZE  ;if so, error	     >
EC < tryDx:
EC <	tst	dx				;see if desired passed       >
EC <	jns	doneCheckingArgs		;nope, branch                >
EC <	test	dx, not mask RSA_CHOOSE_OWN_SIZE	;see if any other bits set   >
EC <	ERROR_NZ  UI_BAD_CHOOSE_OWN_SIZE        ;if so, error	     >
EC < doneCheckingArgs:
   
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN
	jz	managing			;managing, branch to resize

	; if not managing then ->
	;	if (!EXPAND_TO_FIT) -> return current size
	;	if (mask RSA_CHOOSE_OWN_SIZE) -> return currentSize
	;		else return passed size

	mov	ax,cx				;ax,bx = passed size
	mov	bx,dx
	call	VisGetSize			;cx,dx = current size

	test	ds:[di].VCI_geoDimensionAttrs, \
			mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT
	jz	returnCurrentX
	
	test	ax, mask RSA_CHOOSE_OWN_SIZE
	jnz	returnCurrentX
	and	ax, not mask RSA_CHOOSE_OWN_SIZE
	mov	cx,ax
returnCurrentX:

	test	ds:[di].VCI_geoDimensionAttrs, \
			mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
	jz	returnExit
	
	test	bx, mask RSA_CHOOSE_OWN_SIZE
	jnz	returnExit
	and	bx, not mask RSA_CHOOSE_OWN_SIZE
	mov	dx,bx
returnExit:
	jmp	VCCS_exit			;and exit
	
managing:
EC <	test	ds:[di].VCI_geoAttrs, mask VCGA_ONE_PASS_OPTIMIZATION >
EC <	jz 	notDoingOnePass			;branch if not		>
EC <	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP or \
				      mask VCGA_WRAP_AFTER_CHILD_COUNT  >
EC <	ERROR_NZ  UI_CANT_WRAP_AND_DO_ONE_PASS	;say error		>
EC < notDoingOnePass:

	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di

	mov	di, bp				;di <- spacingMarginArgs   
   	mov	bp, sp				;keep pointer to local vars
	sub	sp, size VCG_localVars		;make room for them
	mov	geoVars.VCG_compHandle, si	;save handle of composite	
	mov	geoVars.VCG_spacingStuff, di	;keep spacing stuff here
	
	;
	; Set up local justification vars.
	; 
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	call	GetDimensionAttrs		;length flags in al, width ah
	mov	{word} geoVars.VCG_lengthAttrs,ax  ;store here
	and	ax, (mask DA_JUSTIFICATION shl 8) or mask DA_JUSTIFICATION
	shr	ax, 1				;offset DA_JUSTIFICATION
	shr	ax, 1
	mov	{word} geoVars.VCG_lengthJust,ax   ;store justif. only here

	;
	; If the composite is set full justified along the "width" of the 
	; composite, we'll substitute begin-justified, since there's nothing
	; really to do in that direction.  -cbh 6/21/92 (Used to fatal error.)
	;	
	cmp	ah, GJ_FULL_JUSTIFIED					
	jne	notFullJustifiedAlongWidth
	mov	ah, GJ_BEGIN_JUSTIFIED
notFullJustifiedAlongWidth:
 
; 	We allow this now -- we just don't pass the full width to the children
;	to use if we wrap.  -cbh 4/ 6/92
;EC <	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP >
;EC <	jz	notWrapping			;not wrapping, branch	 >
;EC <	test	geoVars.VCG_widthAttrs, mask DA_EXPAND_TO_FIT_PARENT or \
;				    mask DA_CAN_TRUNCATE_TO_FIT_PARENT   >
;EC <	ERROR_NZ  UI_CANT_EXPAND_OR_CHOP_WIDTH_IF_WRAPPING		>
;EC < notWrapping:						        >
   
	call	SwapIfVerticalDS		;switch cx,dx if vertical
	push	cx				;save length
	push	bp				;save local vars ptr
	mov	bx, dx				;put width in bx
	;	
	; Get the composite's minimum size, if it has a minimum.
	;
	mov	geoVars.VCG_minWidth, 0		;assume no minimum width
	mov	geoVars.VCG_minLength, 0	;or length
	test	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE
	jz	getSpacing			;no minimum size, branch
	mov	ax, MSG_VIS_COMP_GET_MINIMUM_SIZE	
	push	bp				;  cx <- min width 
	call	ObjCallInstanceNoLock		;  dx <- min height
EC <	call	EndMinSize			;for showcalls -g	>
	pop	bp
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	call	SwapIfVerticalDS		;minimum length in cx
						;minimum width in dx
	mov	geoVars.VCG_minWidth, dx	;save min width
	mov	geoVars.VCG_minLength, cx	;and min length
	
getSpacing:
	push	bp
	mov	cx, geoVars.VCG_spacingStuff
	call	GetVisCompSpacing		;returns spacing in cx, dx
EC <	call	EndSpacing			;for showcalls -g	>
	pop	bp
	mov	geoVars.VCG_lengthSpacing, cx	;save
	mov	geoVars.VCG_widthSpacing, dx	;
	
	;
	; Adjust passed width and length for margins, subtracting the 
	; margins from what is passed.
	;
	mov	dx, geoVars.VCG_spacingStuff
	call	GetVisCompMarginsAndAdjust
EC <	call	EndMargins			;for showcalls -g	>
	add	cx, ax				;total length spacing in cx
	add	dx, bp				;total width spacing in dx
	pop	di				;restore local vars ptr in di
	pop	bp				;restore length
   
	push	cx, dx				;save length, width spacing 
		
	push	di				;save local vars ptr again
	;
	; Subtract length margins (in cx), as long as they're larger than the
	; passed length and the passed length isn't mask RSA_CHOOSE_OWN_SIZE.
	;
	sub	geoVarsDi.VCG_minLength, cx	;subtract from min length
	jns	minLengthAdjusted		;result positive, branch
	clr	geoVarsDi.VCG_minLength
	
minLengthAdjusted:
	xchg	cx, bp				;margins in bp, passed in cx
	tst	cx				;passing desired length?
	js	doneWithLength			;yes, branch
	push	cx				;save width
	cmp	bp, cx				;compare margins to passed len
	pop	cx				;restore width
	jae	minimalLength			;can't handle margins, branch
	sub	cx, bp				;else subtract margins
	jmp	short doneWithLength		;and branch
	
minimalLength:
	inc	cx				;minimal length
	
doneWithLength:
	;
	; Subtract width margins (in dx), as long as they're larger than the
	; passed width and the passed width isn't mask RSA_CHOOSE_OWN_SIZE.
	;
	sub	geoVarsDi.VCG_minWidth, dx	;subtract from minimum length
	jns	minWidthAdjusted		;result positive, branch
	clr	geoVarsDi.VCG_minWidth		;else zero min width
	
minWidthAdjusted:
	xchg	dx, bx				;margins in bx, passed in dx
	tst	dx				;passing desired width?
	js	doneWithWidth			;yes, branch
	push	dx				;save width
	cmp	bx, dx				;compare margins to passed width
	pop	dx				;restore width
	jae	minimalWidth			;can't handle margins, branch
	sub	dx, bx				;else subtract margins
	jmp	doneWithWidth			;and branch
	
minimalWidth:
	inc	dx				;minimal width
	
doneWithWidth:
	pop	bp				;ptr to instance vars
	mov	geoVars.VCG_passedWidth, dx  	;save the true passed width

;checkForWrapCount:
	push	cx, dx
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCI_geoAttrs, mask VCGA_WRAP_AFTER_CHILD_COUNT	
	jz	continueOnwardInOurQuestForGeometricalNirvana
	push	bp
	mov	ax, MSG_VIS_COMP_GET_WRAP_COUNT
	call	ObjCallInstanceNoLock
	pop	bp
	mov	geoVars.VCG_wrapCount, cx	;save wrap count
	
continueOnwardInOurQuestForGeometricalNirvana	label	near
	;
	; Set up parameter to use on first pass, usually RSA_CHOOSE_OWN_SIZE
	;
	push	es			;ES <- segment of class structure
	call	SetupLengthToPassKids		
	pop	es			;ES <- segment of class structure

	pop	cx, dx
	
;	FALL_THRU  DoVisCompGeometry		;start doing the real work
						;(can't do a FALL_THRU here;
						; things are on the stack!)


COMMENT @----------------------------------------------------------------------

ROUTINE:	DoVisCompGeometry 	- 1/2 way through VisCompRecalcSize

SYNOPSIS:	Main routine for doing geometry.

CALLED BY:	Noone.    This is simply a continuation of the
		VisCompRecalcSize routine, being a stopping point for
		documentation.

PASS:		*ds:si -- handle of composite object
		cx -- geometry manager defined composite length, minus margins
		dx -- geometry manager defined composite width, minus margins
		ss:bp -- pointer to geometry local variables, as described
			 in VisCompRecalcSize, with VCG_passedWidth, 
			 VCG_lengthSpacing, VCG_widthSpacing, VCG_compHandle
			 all initialized.
			 
RETURN:		cx -- width to make the composite
		dx -- height to make the composite

DESTROYED:	ax, bx, si, di, ds, es

PSEUDO CODE/STRATEGY:
       		See VisCompRecalcSize

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 1/89		Split out from VisCompRecalcSize
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

DoVisCompGeometry	label far
	ForceRef	DoVisCompGeometry

	clr	geoVars.VCG_numPasses		;no first passes yet
;	clr	geoVars.VCG_lineWidth		;try clearing this 2/11/93 cbh
	;
	; we'll keep returnLength in ax, returnWidth in bx
	;
	; Start off with zero widths before and after the center.  If the
	; total doesn't add up to the minimum width at the end, we'll divide
	; up the extra.
	;
	clr	geoVars.VCG_centerOffset
	clr	geoVars.VCG_secondWidth
	
	;
	; It seems like passing a width to a wrapping composite is a bad idea,
	; since expand-to-fit the width for the children ought to just expand
	; to fit a single line, not the entire width passed in (or the thing
	; grows forever).   We'll assume that a passed width is not useful
	; information, and let the children choose the width.    (We're going
	; to change this so that all non expand-width-to-fit composites avoid
	; using the passed width, since any child underneath the composite
	; should be kept from expanding more than the composite really wants
	; to.  Of course, the composite itself can always have expand-to-fit 
	; on it. Also, we won't zero the passed width, we'll use CHOOSE_OWN_-
	; SIZE.  -cbh 6/ 9/92)  (Code added back to not allow *any* wrappable
	; composites from using the passed width, since that wreaks havoc when
	; combined with expand-to-fit.  6/21/92 cbh)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
	jnz	dontUsePassedWidth

	test	geoVars.VCG_widthAttrs, mask DA_EXPAND_TO_FIT_PARENT
	jnz	anotherFirstPass		;expanding, branch

	call	CmpPassedWidthToCurrent		;passed smaller width, use it
	jbe	anotherFirstPass		; 

dontUsePassedWidth:
	mov	dx, mask RSA_CHOOSE_OWN_SIZE	;else use desired size

anotherFirstPass:
	;
	; Initialize variables for first pass:
	; 	returnLength = 0
	; 	returnWidth = 0
	;
	clr	bx				;assume we use minimum needed
	test	geoVars.VCG_widthAttrs, mask DA_EXPAND_TO_FIT_PARENT
						;expand to passed width?
	jz	startPass1			;no, branch
	tst	dx				;passed width is desired?
	js	startPass1			;yes, start with zero
	mov	bx, dx				;else start with passed width
	
startPass1:
	;Allowing children to wrap?  Then never introduce the minWidth this
	;early -- the line width will get set to this, forcing the composite
	;to be at least lineWidth * number of lines wide.  -9/ 4/92 cbh

	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
	jnz	nowDoPass1
	
	cmp	bx, geoVars.VCG_minWidth	;start with minimum width
	jae	nowDoPass1			;   (if there is one)
	mov	bx, geoVars.VCG_minWidth	
	
nowDoPass1:
	mov	ax, geoVars.VCG_lengthSpacing   ;retLen = -length spacing
	;
	; Change to allow at least one complete child spacing on each side
	; for include-ends-in-child-spacing.  We do this by starting with
	; length spacing rather than -(length spacing).  -cbh 2/15/92
	; 
	test	ds:[di].VCI_geoAttrs, mask VCGA_INCLUDE_ENDS_IN_CHILD_SPACING
	jnz	twoExtraSpaces
	neg	ax
twoExtraSpaces:

	; set up for traversal of children

	mov	geoVars.VCG_returnWidth,bx

	clr	bx				; initial child (first
	push	bx				; child of
	push	bx				; composite)
	mov	bx,offset VI_link		;pass offset to LinkPart
	push	bx
NOFXIP <	push	cs			;pass callback routine 	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset DoDesiredResize
	push	bx				;pass callback routine (seg)

	call	SaveTempGeoData			;save centering info 
						;  beforehand..  -cbh 2/ 3/92
	mov	bx,offset Vis_offset		;pass offset to master part
	mov	di,offset VCI_comp		;pass offset to composite
	call	ObjCompProcessChildren

EC <	push	ax							>
EC <	segmov	es, NULL_SEGMENT, ax		;cuz es is not fixed up	>
EC <	pop	ax							>

	push	cx				;assume we won't loop, save
						;passed length
	mov	bx, geoVars.VCG_returnWidth
	cmp	geoVars.VCG_widthJust, GJ_CENTERED
	jne	saveReturnWidth	     		;not centering, branch
	
	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset
	call	AdjustCenterToPassedWidth	;if centering, make some
						;adjustments
saveReturnWidth:	
	;
	; Save returnWidth as the line width, in case we're done with pass 1.
	; (Only if larger than line width.  We're trying to set the line width
	; when forced out of pass 2, and to use that line width after that.
	; -cbh 2/11/93)
	; 
	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset
;	cmp	geoVars.VCG_lineWidth, bx
;	jae	doneWithLineWidth
	mov	geoVars.VCG_lineWidth, bx	;store line width
;doneWithLineWidth:

	test	ds:[di].VCI_geoAttrs, mask VCGA_ONE_PASS_OPTIMIZATION
	LONG	jnz	DVCG_finishUp		;if one pass only, branch
	; 
	; We need to see here if the children needed a bigger width than 
	; what was passed.  If that is so then we need to repeat the first
	; pass in case the new width affects anybody's lengths.  If the
	; first pass had a desired width, then we use it now as the passed
	; width and repeat the process.
	;
	; New hack for centering:  try a second pass with the passed width
	; again.   After one pass, we've got the center offset, which affects
	; how much space is used to the right of center.  If things wrap to the
	; right of center, we've got a chance to keep the passed width.
	;
        ;-------------- Bug fix: need to ALWAYS do two passes if centering
    
	cmp	geoVars.VCG_widthJust, GJ_CENTERED
	jne	newWidth		;not centering, use new width
	tst	geoVars.VCG_numPasses	;see if already made second pass
	jnz	newWidth		;yes, use new width
	inc	geoVars.VCG_numPasses	;else bump the number of passes
	clr	geoVars.VCG_secondWidth	;clear second width, but we'll
						;keep first width so objects
						;know to get smaller
	pop	cx			;get this back off the stack
	jmp	anotherFirstPass	;and try another pass with passed width
	
newWidth:
	cmp	dx, bx	       		;compare passed & summed width
	jz	endPass1	       	;they match, we're done
	
	pop	cx			;else get this back off the stack
	mov	dx, bx	       		;use summed width
	LONG	jl anotherFirstPass	;if passed width smaller or desired,
					;  loop (desired appears negative here)
	push	cx			;push to match pop
	
endPass1:
	; 
	; Second pass coming up here to reconcile the sum of the children's 
	; desired lengths with what the caller wanted.  If the caller wanted
	; a desired length, our work is done.  Otherwise, we will go through
	; the children in the priority list and offer to resize them to their
	; current size plus the extraLength (which could be negative).  We
	; pass on to the next child the extraLength that was not used.
	;
	; Register usage:  ax is returnLength, bx is returnWidth, cx is
	; length passed, dx is extraLength.  bp is child's handle,
	; si is child's pointer, di is composite's pointer.
	;
	;
	; If desired length was passed, there's no extra length.  Also if
	; we're wrapping.  (I think we can still do extra length even if we
	; can wrap.  Wrapped lines still might want to use the space available.
	; - cbh 4/24/92)
	;
	clr	dx				;assume desired length
;	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
;	jnz	skipExtraLenCalc		;yes, no extra length
	push	cx				;save passed len w/out opt resz
	tst	cx				;if desired length
	jns    	checkMinLength			;not desired, calc extra len
	
;noExtraLen:
	mov	cx, ax				;pretend return len = passed
	
checkMinLength:
	;
	; Now, make sure passed length (calced length if desired passed) is
	; at least over the minimum length.
	;
	cmp	cx, geoVars.VCG_minLength	;see if below minimum
	jae	calcExtraLen			;no, branch
	mov	cx, geoVars.VCG_minLength	;else use the minimum length
	
calcExtraLen:
	mov	geoVars.VCG_passedLength, cx	;let's save this
	;
	; Calculate the extra length needed.
	;
        mov	dx, cx				;extraLength = length
	pop	cx				;restore real passed length
	sub	dx, ax				;  - returnLength
	
;skipExtraLenCalc:
	;
	; If we`re not expanding to fit, then we're not going to query the 
	; children for any extra space that's available.  Hopefully this won't
	; bring the system to its knees, but I think this is a good idea. As
	; it was before, children of non-expand-to-fit composites would 
	; basically force the composite to take any and all extra space in the
	; window.  -cbh 6/ 9/92
	;
	test	geoVars.VCG_lengthAttrs, mask DA_EXPAND_TO_FIT_PARENT
	jnz	dontShrinkThingsIfWrapping	;we are expanding, branch
	tst	dx
	js	dontShrinkThingsIfWrapping	;negative extra space, branch
	clr	dx				;else forget about extra space

dontShrinkThingsIfWrapping:
	;
	; We'll check the code so that in wrapping situations, we will expand
	; to fill a line if our calc'ed length is smaller than the passed
	; length, but we will *not* squish things to fit in the passed length.
	; We'll just wrap.
	;
;	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
;	jz	doneWithWrapCheckForExtra
;	tst	dx
;	jns	doneWithWrapCheckForExtra
;	clr	dx
;
;doneWithWrapCheckForExtra:

	;
	; Clear this; it's used to keep tracking of the widest line in wrapping 
	; situations.
	;
	clr	geoVars.VCG_longestLine
	
	;
	; If no return length (no children were around), we'll return zero
	; for the length if not expand-to-fit, one if expand-to-fit, on the
	; assumption that we'll eventually have some size.  (We can't be 
	; returning zero on the first pass and non-zero later, because it will
	; screw up the amount of spacing accounted for -- we don't add spacing
	; after zero-length items anymore. -cbh 2/18/92)
	;
	tst	ax				;no return length?
	jz	zeroLength			;nope, exit
	jns	noKeepGoing			;non negative, keep going

zeroLength:
	clr	ax				;zero length
	test	geoVars.VCG_lengthAttrs, mask DA_EXPAND_TO_FIT_PARENT
	jz	DVCG_finishUp			;not expanding, branch
	inc	ax				;else return a little bit.
	jmp	short DVCG_finishUp		;branch to finish
	
noKeepGoing:
	;
	; Initialize return length.  We will add final sizes of the children
	; to this and it will be our final length.
	;
	mov	ax, geoVars.VCG_lengthSpacing   ;length=  -lengthSpacing
	;
	; Change to allow at least one complete child spacing on each side
	; for include-ends-in-child-spacing.  We do this by starting with
	; length spacing rather than -(length spacing).  -cbh 2/15/92
	; 
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCI_geoAttrs, mask VCGA_INCLUDE_ENDS_IN_CHILD_SPACING
	jnz	twoExtraSpaces2
	neg	ax
twoExtraSpaces2:

	;	
	; Now, traverse the priority list, trying to add (or subtract) space
	; from children, and summing the final length.   Wrapping may
	; also happen here.  If we're a wrapping composite, we traverse 
	; the display list instead because we need to go in the order drawn
	; to recalc when to wrap.  It is assumed that there is no extra
	; length in wrapping situations.  We may also wrap after an initial
	; number of children here, by forcing a new passed length.
	;

	; set up for traversal of children

	;
	; Changed 10/19/92 cbh to zero the return width before pass 2, and
	; let the return width be decided by the largest of the widths passed
	; back.  The children will still be passed lineWidth to use the width
	; calculated in pass1, if possible.  This allows children to shrink
	; their widths in pass 2, if needed, and possibly to have that 
	; reflected in the parent width.  (Don't use minWidth for wrapping 
	; stuff. We'll add it at the end.  -cbh 10/23/92  Special case city.)
	;
	; (Changed again to for composites that are width-centering, as the 
	; width is made up of a calculated left-of-center and right-of-center,
	; which needs to be passed to every child here or we'll end up with
	; an incorrect total width.  -cbh 11/11/92)
	;
	
	cmp	geoVars.VCG_widthJust, GJ_CENTERED ;centering object?
	je	noInitialMinWidth		;yes, use current width.
	clr	bx
	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
	jnz	noInitialMinWidth
	mov	bx, geoVars.VCG_minWidth
noInitialMinWidth:

	mov	geoVars.VCG_returnWidth,bx

	clr	geoVars.VCG_childCount

	clr	bx				;initial child (first
	push	bx				;    child of
	push	bx				;    composite)
	mov	bx,offset VI_link		;pass offset to LinkPart
	push	bx
NOFXIP <	push	cs			;pass callback routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset DoFinalResize
	push	bx				;pass callback routine (seg)

	call	SaveTempGeoData			;save centering info 
						;  beforehand..  -cbh 2/ 3/92
	mov	bx,offset Vis_offset		;pass offset to master part
	mov	di,offset VCI_comp		;pass offset to composite
	call	ObjCompProcessChildren

EC <	push	ax							>
EC <	segmov	es, NULL_SEGMENT, ax		;cuz es is not fixed up	>
EC <	pop	ax							>

	pushf					;save carry flag
	mov	di,ds:[si]			;ds:di = instance
	add	di,ds:[di].Vis_offset		;ds:di = VisCompInstance
	mov	bx, geoVars.VCG_returnWidth	;restore return width
	popf					;restore it
	jnc	DVCG_finishUp			;everything fine, branch
	;
	; One of the children somehow managed to wider than the width 
	; calculated for the composite in pass 1.  This can happen if the
	; child was asked to have a shorter length, and compensated for it
	; by having a larger width (i.e. menus that are forced to not wrap).
	;
	pop	cx				;pop off passed length
	jmp	startPass1			;re-do pass 1
	
DVCG_finishUp label near
	;
	; Figure out which length to pass back.  
	;	If wrapping after a child count, definitely use widest line
	;		(rather than desired length)
	;	If desired length passed, use calc'ed length.
	;       If we're wrapping
	;               If we can expand to fit, return passed length
	;               Use length of widest line as calculated...
	;
	;	If calc'ed length is longer than passed length
	;		If we can chop the length, use passed length.
	;		Otherwise, use calc'ed length.
	;	else if calc'ed length is shorter than passed length
	;		If we can expand to fit, return passed length
	;		If not, use calc'ed length.
	;
	; At this point (all sizes minus margins at this point):	
	;	ax --		   		calced length
	;	bx --		   		calced width
	;	geoVars.VCG_passedWidth	-	passed width
	;	pushed on stack:   		passed length (top of stack)
	;					width margins
	;					length margins
	;
	pop	cx				;pop off passed length
	
	test	ds:[di].VCI_geoAttrs, mask VCGA_WRAP_AFTER_CHILD_COUNT
	jnz	useLongestLine			;doing after child count,
						;  definitely need line length
	tst	cx				;using desired length?
	js	useCalcedLength			;if so, go use calc'ed length
	
	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP 
	jz	nonWrapping		;no, branch
	;
	; Wrapping -- if expand to fit, use passed length, otherwise use
	; longest line before wrapping.  (Not if the longest line is longer
	; than the passed length!  I wonder when all the bugs will be gone.
	; -cbh 12/11/92)
	;
	cmp	geoVars.VCG_longestLine, cx
	jg	useLongestLine

	test	geoVars.VCG_lengthAttrs, mask DA_EXPAND_TO_FIT_PARENT
	jnz		usePassedLength		;yes, use passed length
	
useLongestLine:
	mov	ax, geoVars.VCG_longestLine     ;use this calculated
	
nonWrapping:	
	tst	cx				;double-check for desired passed
	js	calcedLongerThanPassed		;desired, use calced (9/ 4/92)

	cmp	ax, cx				;is calc'ed length longer?
	ja	calcedLongerThanPassed		;yes, branch 
	;
	; Calc'ed length shorter than passed length
	;
	test	geoVars.VCG_lengthAttrs, mask DA_EXPAND_TO_FIT_PARENT
	jnz	usePassedLength			;yes, use passed length

;Nuking truncate to fit.  -cbh 9/29/92
;	jmp	short useCalcedLength		;always use calced (CBH 10/28)
;
calcedLongerThanPassed:
;	test	geoVars.VCG_lengthAttrs, mask DA_CAN_TRUNCATE_TO_FIT_PARENT
;	jnz	usePassedLength			;if either set, use passed len
;
useCalcedLength:
	mov	cx, ax				;else return calc'ed length
	
usePassedLength:
	cmp	cx, geoVars.VCG_minLength	;make sure at least minimum len
	jae	setReturnWidth			;over the minimum, branch
	mov	cx, geoVars.VCG_minLength	;else return the minimum
	
setReturnWidth:
	;
	; If chopping the width, returned passed here.  (If we expanded to
	; fit, then we started with the passed width as our returned somewhere
	; above).
	;
	mov	dx, geoVars.VCG_passedWidth   	;get the width passed

;	test	geoVars.VCG_widthAttrs, mask DA_CAN_TRUNCATE_TO_FIT_PARENT
;	jz	useCalcedWidth			;not chop or exp, return calced
;	tst	dx			        ;desired?
;	jns	usePassedWidth	        	;no, use the passed width
;

	;
	; Alas, if we're no longer using initializing our return width as
	; the passed width for our second pass when expanding width to fit,
	; we'll just have to take care of that now.  -cbh 10/19/92
	;
	test	geoVars.VCG_widthAttrs, mask DA_EXPAND_TO_FIT_PARENT
	jz	useCalcedWidth			;not expanding, return calc'ed
	cmp	dx, bx				;passed smaller than calced?
	jbe	useCalcedWidth			;yes, passed calced then.
	tst	dx				;passed desired?
	jns	usePassedWidth			;no, use passed width

useCalcedWidth:	
	mov	dx, bx				;return calc'ed width
	
usePassedWidth:
	;
	; If the width being returned is zero, and we're expand-to-fit, we'll
	; return one on the assumption that we'll eventually have a width.  It
	; is now a bad thing to return zero size sometimes and non-zero other
	; times, since it impacts the spacing used.  -cbh 2/18/92
	;
	tst	dx
	jnz	widthIsFine
	test	geoVars.VCG_widthAttrs, mask DA_EXPAND_TO_FIT_PARENT
	jz	widthIsFine			;can't expand, branch
	inc	dx				;else use a non-zero width

widthIsFine:
	;
	; Make sure at least as big as minWidth, we may not have started 
	; with it.  -cbh 10/23/92
	;
	cmp	dx, geoVars.VCG_minWidth	;start with minimum width
	jae	biggerThanMinWidth
	mov	dx, geoVars.VCG_minWidth
biggerThanMinWidth:

	;
	; Add the margins back in to the final dimensions.
	;
	DoPop	bx, ax				;ax holds length margins,
						;bx holds width margins
	add	dx, bx				;and add to return width
	add	cx, ax				;to return length
	call	SwapIfVerticalDS		;switch args
	;
	; If we need to, we'll save some geometry information for the 
	; MSG_VIS_POSITION_BRANCH.
	;
	call	SaveTempGeoData			;save the data	
	mov     sp, bp				;unload local vars

	pop	di
	call	ThreadReturnStackSpace
   
VCCS_exit label near
	.leave
	ret
VisCompRecalcSize	endp
	
if ERROR_CHECK
StartGeometry	proc	near
	ret				;Get size entry for showcalls -g
StartGeometry	endp
	
EndGeometry	proc	near
	ret				;Get size exit for showcalls -g
EndGeometry	endp
	
StartRecalcSize	proc	near
	ret				;Get size entry for showcalls -g
StartRecalcSize	endp
	
EndRecalcSize	proc	near
	ret				;Get size exit for showcalls -g
EndRecalcSize	endp
	
EndCenter	proc	near
	ret				;Get center for showcalls -g
EndCenter	endp
		
EndSpacing	proc	near
	ret				;Get spacing for showcalls -g
EndSpacing	endp
	
EndMargins	proc	near
	ret				;Get spacing for showcalls -g
EndMargins	endp
	
EndMinSize	proc 	near		;Get min size for showcalls -g
	ret
EndMinSize	endp
		
endif
	





COMMENT @----------------------------------------------------------------------

ROUTINE:	CmpPassedWidthToCurrent

SYNOPSIS:	Figures out if width passed to composite is larger than the
		composite's current width.

CALLED BY:	DoVisCompGeometry

PASS:		ds:di -- composite's vis instance
		dx -- width passed

RETURN:		flags set for comparing dx with current width

DESTROYED:	es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/19/92	Initial version

------------------------------------------------------------------------------@

CmpPassedWidthToCurrent	proc	near	uses	si, cx
	.enter
	segmov	es, ds
	mov	si, di				;es:di, ds:si <- VisInstance
	call	GetWidth
	cmp	dx, cx
	;
	; Destroy es, but with something that ec +segment won't choke on
	; Simply returning es as the passed value of ds is bad, because
	; it won't be fixed up later since our caller doesn't use es -- eca
	;
EC <	mov	cx, NULL_SEGMENT		;>
EC <	mov	es, cx				;>

	.leave
	ret
CmpPassedWidthToCurrent	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupLengthToPassKids

SYNOPSIS:	Sets up length to initially pass kids.  Usually RSA_CHOOSE_-
		OWN_SIZE, but can be forced to a value passed on what's 
		being passed in if VCGDA_DIVIDE_HORIZONTAL_SPACE_EQUALLY
		is set.

CALLED BY:	VisCompRecalcSize

PASS:		*ds:si -- composite
		cx     -- length being passed to comp, as viewed in a 
			  horizontal composite

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/29/92		Initial version

------------------------------------------------------------------------------@

SetupLengthToPassKids	proc	near
	class	VisCompClass		
	geoVars	local	VCG_localVars
	.enter	inherit
	mov	geoVars.VCG_lengthToPassKids, mask RSA_CHOOSE_OWN_SIZE
	test	geoVars.VCG_lengthAttrs, mask DA_DIVIDE_SPACE_EQUALLY
	jz	exit
	tst	cx				;passed desired, branch!
	js	exit				;  -cbh 11/ 7/92

	;
	; Setup number of manageable children and space needed between them.
	;
	push	cx, dx
	mov	dx, geoVars.VCG_lengthSpacing	;start with -lengthSpacing
	neg	dx
	clr	ax				;child count

	clr	bx				;initial child (first
	push	bx				;    child of
	push	bx				;    composite)
	mov	bx,offset VI_link		;pass offset to LinkPart
	push	bx
NOFXIP <	push	cs			;pass callback routine (seg)	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset CountManagedChildren
	push	bx				;pass callback routine (seg)

	segmov	es, ds				;make sure es is legal to keep
						;  EC stuff running...

	mov	bx,offset Vis_offset		;pass offset to master part
	mov	di,offset VCI_comp		;pass offset to composite
	call	ObjCompProcessChildren
	
	sub	cx, dx				;subtract spacing needed
	jns	10$
	clr	cx				;negative, pass zero
10$:

	;	
	; Amount to pass children is simply (available length / numChildren).
	;
	xchg	cx, ax				;avail length
	clr	dx				;in dx.ax
	tst	cx				;no kids, give up.
	jz	giveUp
	div	cx				;result in cx
	mov	geoVars.VCG_lengthToPassKids, ax
giveUp:
	pop	cx, dx
exit:
	.leave
	ret
SetupLengthToPassKids	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	CountManagedChildren

SYNOPSIS:	Counts children that are managed.  Also keeps a count of
		how much space will be needed between children.

CALLED BY:	SetupLengthToPassKids

PASS:		*ds:si -- child
		ax -- child count
		dx -- length spacing total

RETURN:		ax, dx -- updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/29/92		Initial version

------------------------------------------------------------------------------@

CountManagedChildren	proc	far
	class	VisClass		
	geoVars	local	VCG_localVars
	.enter	inherit
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_MANAGED
	jz	exit				;not managed, exit
	inc	ax				;else bump child count
	add	dx, geoVars.VCG_lengthSpacing	;and length spacing
exit:	
	clc					;continue
	.leave
	ret
CountManagedChildren	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	GetVisCompSpacing

SYNOPSIS:	Returns this vis comp's spacing in the fastest way possible.

CALLED BY:	VisCompRecalcSize

PASS:		*ds:si -- vis comp
		cx  -- VisCompMarginSpacingInfo

RETURN:		cx -- child spacing
		dx -- child wrap spacing

DESTROYED:	ax, bx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/30/92		Initial version

------------------------------------------------------------------------------@

GetVisCompSpacing	proc	near
	class	VisCompClass		
	test	cx, mask VCSMI_USE_THIS_INFO
	jz	sendMessage				;no info passed, branch
	and	cx, mask VCSMI_CHILD_SPACING		;else yank out spacing
	mov	dx, cx					;use as wrap spacing

if	0	;ERROR_CHECK
	push	bx
	push	cx, dx
	mov	ax, MSG_VIS_COMP_GET_CHILD_SPACING
	call	ObjCallInstanceNoLock
	mov	ax, cx
	mov	bx, dx
	pop	cx, dx
	cmp	ax, cx
	ERROR_NE	-1
	cmp	bx, dx
	ERROR_NE	-1
	pop	bx
endif
	jmp	short exit				;and exit

sendMessage:
	mov	ax, MSG_VIS_COMP_GET_CHILD_SPACING	;get child spacing
	call	ObjCallInstanceNoLock
exit:
	ret
GetVisCompSpacing	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	GetVisCompMarginsAndAdjust

SYNOPSIS:	Gets margins in the fastest way, and adjusts for orientation.

CALLED BY:	VisCompRecalcSize

PASS:		*ds:si -- composite
		dx  -- VisCompMarginSpacingInfo

RETURN:		ax, bp, cx, dx -- L/R/T/B margins, adjusted for orientation

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/30/92		Initial version

------------------------------------------------------------------------------@

GetVisCompMarginsAndAdjust	proc	near	uses	bx
	class	VisCompClass		
	.enter
	test	dx, mask VCSMI_USE_THIS_INFO
	jz	sendMessage			;no info passed, branch

	mov	cl, 3				;our shift amount

	shr	dx, cl				;shift bottom margin over
	mov	bx, dx				;copy to bx
	and	dx, 7				;mask off all but bottom 3 bits

	shr	bx, cl				;shift right margin over
	mov	bp, bx				;copy to bp
	and	bx, 7				;mask off all but bottom 3 bits

	shr	bp, cl				;shift top margin over
	mov	ax, bp				;copy to ax
	and	bp, 7				;mask off all but bottom 3 bits
	shr	ax, cl				;shift bottom margin over
	and	ax, 7				;mask off all but bottom 3 bits

	mov	cx, bx				;right margin in cx

if	0		;ERROR_CHECK
	push	bx
	push	ax, bp, cx, dx
	mov	ax, MSG_VIS_COMP_GET_MARGINS
	call	ObjCallInstanceNoLock
	pop	bx				;dx
	cmp	bx, dx
	ERROR_NE	-1
	pop	bx
	cmp	bx, cx
	ERROR_NE	-1
	pop	bx
	cmp	bx, bp
	ERROR_NE	-1
	pop	bx
	cmp	bx, ax
	ERROR_NE	-1
	pop	bx
endif

	jmp	short finish

sendMessage:
	mov	ax, MSG_VIS_COMP_GET_MARGINS
	call	ObjCallInstanceNoLock		;margins in ax/bp/cx/dx
finish:
	call	AdjustMarginsToOrientation	;get comp margins in ax,bp,cx,dx
	.leave
	ret
GetVisCompMarginsAndAdjust	endp

	


COMMENT @----------------------------------------------------------------------

ROUTINE:	SaveTempGeoData

SYNOPSIS:	Saves temporary data.

CALLED BY:	DoVisCompGeometry, DoDesiredResize

PASS:		*ds:si -- composite
		ss:bp  -- GeoVars

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/16/91		Initial version

------------------------------------------------------------------------------@

SaveTempGeoData	proc	near		
	class	VisCompClass		
	geoVars	local	VCG_localVars
	.enter	inherit
	
	push	ax, cx, dx, bp
	mov	cx, geoVars.VCG_lineWidth	   ;assume temp vars needed
	mov	dx, geoVars.VCG_centerOffset
	mov	ax, geoVars.VCG_secondWidth
	
	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
        jnz	checkCenter			   ;wrapping, branch
	cmp	geoVars.VCG_widthJust, GJ_END_JUSTIFIED
	je	checkIfSaveNeeded		   ;end justified, branch
	mov	cx, -1				   ;else we don't need this.
	
checkCenter:
	cmp	geoVars.VCG_widthJust, GJ_CENTERED ;centering object?
	je	checkIfSaveNeeded		   ;yes, branch
	cmp	cx, -1				   ;is there anything to do?
	je	skipSave			   ;no, skip this
	mov	dx, -1				   ;else we don't need these
	mov	ax, dx

checkIfSaveNeeded:
	push	bp
	mov	bp, ax				   ;second width in bp
	call	VisCompSaveTempGeoData
	pop	bp
skipSave:
	pop	ax, cx, dx, bp
	.leave
	ret
SaveTempGeoData	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	GetDimensionAttrs

SYNOPSIS:	Returns dimension attributes, according to orientation.

CALLED BY:	VisCompRecalcSize, VisCompPosition

PASS:		ds:di -- VisInstance composite

RETURN:		al -- dimension, along length of parent
		ah -- dimension, along width of parent

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 8/91		Initial version

------------------------------------------------------------------------------@

GetDimensionAttrs	proc	near
	class	VisCompClass
   	;
	; Set up justification variables to be oriented with the composite.
	;
	mov	al, ds:[di].VCI_geoDimensionAttrs	;get attrs
	mov	ah, al					;in ah too
	shr	al, 1					;width flags in al
	shr	al, 1
	shr	al, 1
	shr	al, 1
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	10$
	xchg	al, ah					;switch flags
10$:
EC <	and	al, DimensionAttrs			;show only legal bits>
EC <	and	ah, DimensionAttrs			;show only legal bits>
	ret
GetDimensionAttrs	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	DoDesiredResize

DESCRIPTION:	Do the desired resize pass for each object.

CALLED BY:	ObjCompProcessChildren -- callback routine

PASS:
		*ds:si - child
		*es:di - parent
		ax - return length
		cx - passed length
		dx - passed width
		bp - stack frame variables (see VisCompRecalcSize)

RETURN: 
		carry set if getting out of loop, clear otherwise...
		ax, dx, updated as appropriate

DESTROYED:
		bx, di

REGISTER/STACK USAGE:
		bx -- returnWidth

PSEUDO CODE/STRATEGY:
       		see VisCompRecalcSize

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

DoDesiredResize	proc	far
	class	VisCompClass		
	geoVars	local	VCG_localVars
	.enter	inherit

EC <	call	CheckForDamagedES		;Make sure *es still obj block >
	mov	di, es:[di]			;point to child vis instance
	add	di, es:[di].Vis_offset
	mov	geoVars.VCG_childHandle, si	;save handle of child
	mov	bx, geoVars.VCG_returnWidth	;set up returnWidth
	mov	si, ds:[si]			;point at child's instance data
	add	si, ds:[si].Vis_offset		; ds:si = VisInstance
EC <	call	CheckValidChild			;make sure child is there >
	test	ds:[si].VI_attrs, mask VA_MANAGED
	LONG	jz	DDR_doneWithChild	;no, branch
	;
	; Try to resize child using the width passed in and whatever length
	; it desires (unless overridden by a special space-dividing hint).
	;
     	push	cx, dx				  ;save the length, width
	push	ax				  ;save returnLen
	mov	si, geoVars.VCG_childHandle 	  ;si points to child handle
	mov	cx, geoVars.VCG_lengthToPassKids  ;let child choose, usually
	;
	; Make width an optional resize, so that objects that would prefer
	; not to be this big don't have to be.  (Looks like useless code to
	; me.  -cbh 12/11/92)
	;
;	tst	dx				;if desired, don't set bit
;	js	dontPassOptional
;
;dontPassOptional:
	call	ResizeChild			;resize the child
	pop	ax				;restore returnLength
	; 
	; Child's best length in cx, width in dx.
	; returnLength = child's best length + spacing
	;
        add	ax, cx				;add desired length to total
	;
	; Change to not add spacing if the child had no length. -cbh 2/ 6/92
	;
	tst	cx				;
	jz	noSpacing
	add	ax, geoVars.VCG_lengthSpacing   ;and spacing between children
noSpacing:
	;
	; Do a quick check to make sure that the length of the composite
	; is larger than the length of this child.  If not,
	; replace the length.   (If one of the high bits is set for some
	; flag, the right thing happens.)   (Commented out, 11/30/92 cbh.
	; This causes problems in wrapping within wrapping situations, as
	; the length being returned by the child is long, but may be shorter
	; later, so why force the thing to be large?)
	;
;	mov	di, geoVars.VCG_compHandle
;	mov	di, es:[di]			;point to instance
;	add	di, es:[di].Vis_offset		;ds:[di] -- VisInstance
;	test	es:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
;	jz	dontReplaceLength		;no, don't do this
;	mov	si, sp				;si points to stack
;	mov	si, ss:[si]+2			;get passed length from stack
;	cmp	cx, si				;compare with length of child
;	jbe	dontReplaceLength		;passed length OK, branch
;	mov	si, sp				;else make length = child's
;	mov	ss:[si]+2, cx			;and use child+margins
;
;dontReplaceLength:
	;
	; Calculate returnWidth and centerOffset.  If we're not centering, 
	; returnWidth is the maximum of returnWidth and the child's width.
	; If we're doing centering, then one has to keep the maximum of the
	; space before the middle and the space after the middle.  Any changes
	; in the sum of these should be reflected in the overall width that
	; we pass to all the children.
	;
	cmp	geoVars.VCG_widthJust, GJ_CENTERED ;centering?
	jne	notCentering	                   ;no branch
	mov	si, geoVars.VCG_childHandle  	  ;put child handle in si
	mov	si, ds:[si]			  ;point to instance
	add	si, ds:[si].Vis_offset		  ;ds:[di] -- VisInstance
	test	ds:[si].VI_geoAttrs, mask VGA_DONT_CENTER ;child override?
	jnz	notCentering		  	  ;yes, skip for this child
	push	dx				  ;save child's width
	push	ax				  ;save return length
	mov	si, geoVars.VCG_childHandle  	  ;put child handle in si
	push	bp
	mov	bp, geoVars.VCG_compHandle	  ;save comp handle on stack
	push	bp

	push	es:[LMBH_handle]
	call	VisSendCenter			  ;get the child's center
	pop	di
	xchg	bx, di
	call	MemDerefES
	xchg	bx, di

EC <	call	EndCenter			  ;for showcalls -g	>
EC <	call	TestGetCenter			  ;look for good values >
	;
	; Take the left, right, top and bottom in cx, dx, ax, and bp, and
	; leave the amount before our composite's center in cx and the amount
	; after our composite's center in dx.
	;
	pop	di				  ;restore comp handle
	mov	di, es:[di]			  ;point to instance
	add	di, es:[di].Vis_offset		  ;ds:[di] -- VisInstance
	test	es:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jnz	centerReturned			    ;it is, done
	mov	cx, ax				  ;leave amount before center
	mov	dx, bp				  ;and amount after center
	
centerReturned:				  
	pop	bp				  ;restore local vars pointer
	pop	ax				  ;restore return length
	
	cmp	cx, geoVars.VCG_centerOffset  	  ;compare to max offset
	jbe	checkSecondWidth		  ;branch if smaller
	mov	geoVars.VCG_centerOffset, cx  	  ;else store new center off
	
checkSecondWidth:
	cmp	dx, geoVars.VCG_secondWidth       ;see if 2nd width is bigger
	jbe	checkOverall		  	  ;no, branch
	mov	geoVars.VCG_secondWidth, dx       ;else store new value
	
checkOverall:
	mov	dx, geoVars.VCG_centerOffset      ;add centers; see if sum
	add	dx, geoVars.VCG_secondWidth       ;  affects overall width
	
	cmp	bx, dx				  ;return width greater?
	ja	keepCurrentWidth		  ;yes, branch
	mov	bx, dx				  ;else use child's width
	
keepCurrentWidth:
	pop	dx				  ;restore child's width, still
						  ;  should check if child's
						  ;  width exceeds passed
if	1
	;
	; If we need to, we'll save some geometry information for the 
	; MSG_VIS_POSITION_BRANCH.
	;
	push	bx
	push	ds:[LMBH_handle]
	push	si
	mov	si, geoVars.VCG_compHandle  	  ;
	segmov	ds, es				  ;comp in *ds:si
	call	SaveTempGeoData			  ;save the data	
	pop	si
	pop	bx
	call	MemDerefDS
	pop	bx
endif

notCentering:
	cmp	bx, dx				  ;child's width greater?
	ja	childNotGreater		  	  ;no, branch
	mov	bx, dx				  ;else use it
	
childNotGreater:
	pop	dx				  ;restore passed width
	pop	cx				  ;restore passed length
	
DDR_doneWithChild label near	
	mov	si, geoVars.VCG_childHandle  	  ;point to child's instance
	mov	geoVars.VCG_returnWidth, bx	  ;save return width
	clc
	.leave
	ret

DoDesiredResize	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	DoFinalResize

DESCRIPTION:	Do the final resize pass for each object.

CALLED BY:	ObjCompProcessChildren -- callback routine

PASS:
	*ds:si - child
	*es:di - parent
	ax - return length
	cx - passed length
	dx - extra length
	ss:bp - geoVars

RETURN: ax, cx, dx, geoVars -- updated appropriately

DESTROYED:
	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       see VisCompRecalcSize

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

DoFinalResize	proc	far
	class	VisCompClass		
	geoVars	local	VCG_localVars
	.enter	inherit

EC <	call	CheckForDamagedES	; Make sure *es still object block >
	mov	bx, geoVars.VCG_returnWidth
	mov	geoVars.VCG_childHandle, si

tryChildAgain:	
	mov	si, ds:[si]			;point at child's instance data
	add	si, ds:[si].Vis_offset		; ds:si = VisInstance
	mov	di, es:[di]
	add	di, es:[di].Vis_offset
	test	ds:[si].VI_attrs, mask VA_MANAGED
	jz	DDR_doneWithChild		;not managed, skip
	
;doChild:
	inc	geoVars.VCG_childCount
	;
	; Get the current length of the child, for comparison purposes when
	; we resize it.  If there is no extra length at this point, we can
	; save time by skipping the resize function altogether.  Also, we
	; can check here if the child responds to resizes and save some time.
	;
	push	cx, dx				;save passed & extra len
	push	bp
	mov	bp, cx
	call	GetLength			;get oldLength in cx  
;	mov	si, bp				;passed length in si(not needed)
	pop	bp
	;
	; Send Resize to child with the width we got earlier, and the length 
	; plus the extra.   Take the difference between the old length of
	; the child and what it got resized to here and subtract from 
	; extraLength.
	;
	push	ax, cx				;save returnLength, oldLength
	add	cx, dx				;add extraLength to oldLength 

	;
	; Keep track of whether we're going to pass a length to the child
	; that is equal to or greater than the overall passed width for the
	; composite.  If this is true, we'll know we can't play any games
	; to make sure the child isn't being forced to wrap in a weird way.
	; -cbh 2/ 6/93
	;
	cmp	cx, geoVars.VCG_passedLength	;child passed vs. parent passed
	pushf					;save result

	tst	cx
	jns	lengthPositive			;greater than zero, branch
	clr	cx				;else keep > 0
	inc	cx
	
lengthPositive:
	;
	; Use passedLength as the lengthToPassKids.  This seems to fix the
	; problem where only the first item group in toolbars wrap properly.
	; - Joon (7/20/94)
	;
	push	geoVars.VCG_passedLength
	pop	geoVars.VCG_lengthToPassKids

	mov	si, geoVars.VCG_childHandle 	;(reset handle of child)
	mov	dx, geoVars.VCG_lineWidth 	;return width, without margins 
	call	ResizeChild			;resize the child
	popf
	pop	si				;restore oldLength in si
	pop	di				;restore returnLength in di

	lahf					;flags in ah
	xchg	ax, di				;now in di high, retLen in ax
	
	cmp	dx, geoVars.VCG_lineWidth  	;was child wider?
	jbe	childWidthOK			;no, avoid extreme nastiness

	;	
	; Width returned by the child is more than we had expected.  Perhaps
	; the child wrapped as a result of a small width that we passed it.
	; Before we commit to this new width, if we're a wrapping composite,
	; lets try putting the child on a line by itself where it has a better
	; chance of creating pleasant geometry than if we scrunch it up.
	; Of course, if it's the first object on the line, there's no point to
	; doing this.   -cbh 1/27/93
	;
	call	CheckIfShouldWrapEarly		;should we wrap and try again?
	jnc	abortAndTryANewWidth		;no, branch

	mov	si, cx				;child's return length
	pop	cx, dx				;restore passed & extra len
	sub	si, cx				;si <- passed length - child
	neg	si				;  length - return length
	sub	si, ax
	cmp	si, dx				;doesn't match extra length,
						;  we'll try just using the end
						;  of the line, branch
	jne	noWrap
						;else try wrapping, and using
						;  the whole second line.
	add	si, ax				;use the entire line as extra

	call	BumpReturnWidth			;wrap the line width
	clr	ax				;no returnLength
noWrap:
	mov	dx, si				;set extra length
	mov	si, geoVars.VCG_childHandle
	mov	di, geoVars.VCG_compHandle
	dec	geoVars.VCG_childCount		;don't count child twice
	jmp	short tryChildAgain		;and start all over again
						;}
abortAndTryANewWidth:
	mov	geoVars.VCG_passedWidth, dx  	;store new passed width
;	mov	geoVars.VCG_lineWidth, dx	;and line width, in case we wrap
	mov	bx, dx				;start with this width pass 1 
	pop	cx				;else pop off extra length
	pop	cx				;pop off passed length
	stc
	jmp	short abortPass2		;need to go back to pass 1

childWidthOK:
	;
	; New code to update the return width as we go, rather than starting
	; out pass 2 with the returnWidth from pass 1.  This is to allow 
	; to tell when child widths have *shrunk* in the second pass, and to
	; possibly use that information to return a smaller width ourselves.
	; -cbh 10/19/92
	;
	cmp	dx, bx				;larger than return width?
	jbe	smallerThanReturnWidth
	mov	bx, dx				;yes, store new return width.
smallerThanReturnWidth:

	pop	dx				;restore extra length
	sub	dx, cx				;subtract child's new length
	add	dx, si				;add back oldLength
 	mov	si, geoVars.VCG_childHandle  	;child handle back in si
	mov	si, ds:[si]			;pointer to child instance
	add	si, ds:[si].Vis_offset		; ds:si = VisInstance
	;
	; With extraLength updated, add new length of child to returnLength
	;
	add	ax, cx				;add child's len to returnLen
	;
	; Change to not add spacing if the child had no length. -cbh 2/ 6/92
	;
	tst	cx				;
	jz	noSpacing
	add	ax, geoVars.VCG_lengthSpacing   ;and add length spacing
noSpacing:

	pop	si				;restore length passed in si 
	;
	; Time to deal with wrapping.  If the returnLength exceeds the passed
	; length, we wrap.  The width gets doubled and the child that went 
	; over is is put at the left edge of the second line.
	;
	mov	di, geoVars.VCG_compHandle
	mov	di, es:[di]			
	add	di, es:[di].Vis_offset
	test	es:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
	jz	notWrapping			;no, branch
	
	;
	; New, exciting code to wrap children after a certain child count.
	; (Changed to not try to wrap within the passed length at all when
	; wrapping after a child count.  Brute force is the name of the game
	; here. -cbh 11/ 6/92)
	;
	test	es:[di].VCI_geoAttrs, mask VCGA_WRAP_AFTER_CHILD_COUNT
	jz	checkWrapNeeded
	push	di
	mov	di, geoVars.VCG_childCount
	cmp	di, geoVars.VCG_wrapCount	;time to do wrapping?
	pop	di
	jb	notWrapping			;before the first wrap, don't
						;  worry about passed length.
	jne	checkWrapNeeded			;past wrap count, branch
	mov	si, ax				;else force the passed length
						;  so as to wrap (next time)
checkWrapNeeded:
	;
	; Changed to signed comparison on 9/13/92.  The problem is, we start
	; out with a negative total length (-childSpacing in fact).  If the
	; first child is of zero length, no spacing will be added in and
	; the total spacing will still be negative, but we certainly shouldn't
	; wrap.
	;
	tst	si				;desired passed length, no wrap
	js	notWrapping			;  (9/13/92)

	cmp	ax, si				;returnLength > length passed?
	jle	notWrapping			;no, branch (9/13/92)

	call	BumpReturnWidth			;wrap the line
	mov	ax, cx				 ;returnLength = current child

	;
	; For wrapping, when we reset the returnLength, we need to include
	; one left end spacing if it is enabled and one inter-child spacing.
	; This'll allow wrapping on the next line correctly.
	;
	; This matches the actual placement code which provides left end
	; spacing for wrapped children.
	;
	; Fixes fail case:
	;	three children (107 each), spacing (5), parent space (224)
	;	first child fits 5(left end)+107(width)+5(spacing) < 224
	;	second child wraps 5+107+5+107+5 = 229 > 224
	;	if we don't add spacing:
	;	 third child fits 107(returnLength)+107(new one)+5 = 219 < 224
	;	if we correctly add left end spacing and inter-child spacing:
	;	 third child wraps 5(left end)+107(returnLength)+
	;			5(inter-child)+107(new one)+5=229>224
	;
	; - brianc 7/8/95
	;
	; Actually, not quite. If there is no end spacing, then we
	; don't need to do anything, as the inter-child spacing
	; will be properly handled when the next child is processed.
	; But, if end-spacing is included, then we need to account
	; for the both the left- & right-end spacing now, which
	; is why Brian's original fix worked. -Don 4/8/99
	;
	test	es:[di].VCI_geoAttrs, mask VCGA_INCLUDE_ENDS_IN_CHILD_SPACING
	jz	notWrapping
	add	ax, geoVars.VCG_lengthSpacing	;left-end spacing
	add	ax, geoVars.VCG_lengthSpacing	;right- spacing
	
notWrapping:
	; 
	; Keep track of the widest line.  Save the current returnLength
	; if bigger than any line we've had so far.
	;
	cmp	ax, geoVars.VCG_longestLine 	 ;see if currently bigger
	jb	notLongest			 ;no, branch
	mov	geoVars.VCG_longestLine, ax 	 ;else use the new value
	
notLongest:
	mov	cx, si				 ;put length passed back in cx
	
;doneWithChild:
	clc
	
abortPass2:
	mov	si, geoVars.VCG_childHandle
	mov	geoVars.VCG_returnWidth,bx
	.leave
	ret

DoFinalResize	endp


BumpReturnWidth		proc	near
	;
	; Pass:   bx -- current return width
	; Return: bx -- updated
	;
	class	VisCompClass		
	geoVars	local	VCG_localVars
	.enter	inherit
	;
	; Code added to go along with new stuff to start with a zero passed
	; width and calculate the returnWidth as we go along.   If we need to
	; wrap and haven't arrived at the lineWidth yet, we better use the
	; whole thing, as the position stuff depends on the constant lineWidth
	; for every line. -cbh 11/ 7/92
	;
	cmp	bx, geoVars.VCG_lineWidth
	jae	reasonableFirstLineWidth
	mov	bx, geoVars.VCG_lineWidth
reasonableFirstLineWidth:
	;
	; We're, wrapping, we'll add a line width and put this object on the
	; next line.  
	add	bx, geoVars.VCG_lineWidth 	;else returnWidth += lineWidth
	add	bx, geoVars.VCG_widthSpacing	;  + widthSpacing
	.leave
	ret
BumpReturnWidth		endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfShouldWrapEarly

SYNOPSIS:	This unfortunate routine checks to see if:
			a) the parent is wrappable
			b) the child whose width went crazy was being passed a 
			   smaller length than the parent was, meaning that
			   other objects are squeezing the child.

		If these things are true, we'll return that the composite
		should consider wrapping before and/or after this child.
		This gets called when a child's suddenly exceeds the line
		width calculated earlier, which often happens if wrappable
		children get squished, but it's much better to try to put
		the child on a line bny itself than to forced to wrap in the
		width direction.

CALLED BY:	DoFinalResize

PASS:		ss:bp -- GeoVars
		di high -- flags from compare of child to parent passed lengths

RETURN:		carry set if we should force the composite to wrap

DESTROYED:	cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/26/93       	Initial version

------------------------------------------------------------------------------@

CheckIfShouldWrapEarly	proc	near		uses 	si, ax
	class	VisCompClass		
	geoVars	local	VCG_localVars
	.enter	inherit

	mov	ax, di
	sahf					;restore flags
						;(cmp childPLen, parentPLen)
	clc					;assume exiting
	jge	exit				;child passed larger or equal 
						;  value, not getting squeezed,
						;  let child wrap itself (if
						;  that's what it's doing)
;checkParentWrappable:
	mov	di, geoVars.VCG_compHandle
	mov	di, es:[di]			
	add	di, es:[di].Vis_offset
	test	es:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
	jz	exit			;parent not wrappable, exit (c=0)

	stc
exit:
	.leave
	ret
CheckIfShouldWrapEarly	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resizes the child.

CALLED BY:	GeoResize

PASS:		cx, dx -- args to pass to MSG_VIS_RECALC_SIZE
		es:[di] -- visible instance data of composite
		*ds:si -- child's handle
		ss:bp  -- local vars for VisCompGetSize

RETURN:		cx, dx -- size child used

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		if SA_USE_VIS_RECALC_SIZE
			goto ReturnCurrentSize
		endif
		if not VOF_GEOMETRY_INVALID
		   if VCGA_NEVER_DIFFERENT_THAN_CURRENT
			go to ReturnCurrentSize
		   elif currentSize = passedSize (with flags cleared)
			go to ReturnCurrentSize
		   elif (passedSize > currentSize) and 
			    VCGA_NEVER_LARGER_THAN_CURRENT
			go to ReturnCurrentSize
		   endif
		endif
		call MSG_VIS_RECALC_SIZE
		goto DoResize

	ReturnCurrentSize:
		if VTF_IS_COMPOSITE
			call VisCompRecalcSize
		else
			call  VisRecalcSize

	DoResize:
		if GOF_USE_VIS_RESIZE
			call VisSetSize
	        else
			call MSG_VIS_SET_SIZE
		endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 6/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ResizeChild	proc	near
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.
	geoVars	local	VCG_localVars
	.enter	inherit
	
	push	es:[LMBH_handle]	; save handle of es object block
EC <	call	CheckForDamagedES	; Make sure *es still object block >
	call	SwapIfVerticalES	; swap dimensions if vertical
EC <	call	StartRecalcSize		; for showcalls -g		   >
EC <	call	CheckValidGetSize	; make sure reasonable             >
   
	call	VisRecalcSizeAndInvalIfNeeded	; do an optimized size calc
EC <	call	CheckValidResize	;make sure reasonable   >
	call	VisSetSize		; resize it
	
	pop	di			; get handle in di
	xchg	bx, di
	call	MemDerefES		; deref handle to es
	xchg	bx, di

	mov	di, geoVars.VCG_compHandle	;restore composite handle
	mov	di, es:[di]			;point to instance
	add	di, es:[di].Vis_offset		;es:di - VisInstance
EC <	call	EndRecalcSize			;for showcalls -g	>
	call	SwapIfVerticalES		;swap back if vertical
	
	.leave
	ret			
ResizeChild	endp
	
	
	


COMMENT @----------------------------------------------------------------------

ROUTINE:	AdjustCenterToPassedWidth

SYNOPSIS:	Makes any center adjustments, if necessary.  If the passed
		width is larger than what we've calculated, and we're 
		centering, we need to add reasonable amounts to each side
		of the center line to add up to the accumulated width.
		(If the accumulated width is bigger, it's because it was passed
		and we're doing EXPAND_TO_FIT, hence the routine name)
		The simple case is to add the same amount to each side. 
		However, if this object is a child of another object centering
		its children, we need to keep our center in line with its
		center.

CALLED BY:	DoVisCompGeometry

PASS:		ds:di  --  vis instance of composite
		*ds:si -- handle of composite
		ss:bp  -- geoVars
		bx     -- accumulated width 

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:
        leftover = accumulatedWidth - (centerOffset+secondWidth)
	if (MSG_VIS_COMP_GET_GEO_ATTRS (parent) & JF_WCENTER)
	   and parent's orientation is the same as this object's
		parentLeft, parentRight = MSG_VIS_GET_CENTER (parent) -
					  parent's top/bottom margins - 
					  child's top/bottom margins
			
		availLeft = parentLeft - centerOffset
		availRight = parentRight - secondWidth
		
		if leftOver > 0 and availLeft > 0 
		    if leftover < availLeft
			centerOffset = centerOffset + leftOver
			leftOver = 0
		    else
		    	centerOffset = centerOffset + availLeft
			leftOver = leftOver - availLeft
			
		if leftOver > 0 and availRight > 0
		    if leftover < availRight
			secondWidth = secondWidth + leftOver
		    else
		    	secondWidth = secondWidth + availRight
	else
	    if numPasses > 0
		centerOffset = centerOffset + 1/2 (leftOver)
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/28/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

AdjustCenterToPassedWidth	proc	near
	class	VisCompClass		
	geoVars	local	VCG_localVars
	.enter	inherit

	push	bp, ax, bx, cx, dx	      	;save width passed
	sub	bx, geoVars.VCG_centerOffset   	;see how much we need to
	sub	bx, geoVars.VCG_secondWidth    	;   add (leftOver)
	LONG	jbe	exit			;everything adds up, branch
	push	bp
	call	VisGetParentGeometry
	pop	bp
	mov	al, cl				;put geo flags in al
	and	al, mask VCGA_ORIENT_CHILDREN_VERTICALLY	
						;check parent's orientation
	;
	; Parent's VCGA_ORIENT_CHILDREN_VERTICALLY bit in al.  We'll make sure
	; it matches our object's bit.  If it doesn't, we'll center evenly.
	; If the parent isn't centering in the opposite direction of its
	; orientation, we'll also centerEvenly.  (We'll do this correctly now.
	; Things only worked with vertical child and parent before. -2/3/92 cbh)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ah, al				;parent orientation here too
	xor	ah, ds:[di].VCI_geoAttrs	;either both on or both off?
	and	ah, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jnz	centerEvenly			;nope, do simple center
	tst	al				;was parent vertical?
	jz	5$				;no, branch
	and	ch, mask VCGDA_WIDTH_JUSTIFICATION  ;vert, see if centering width
	cmp	ch, WJ_CENTER_CHILDREN_HORIZONTALLY shl \
			offset VCGDA_WIDTH_JUSTIFICATION
	jmp	short 7$
5$:
	and	ch, mask VCGDA_HEIGHT_JUSTIFICATION  ;horiz, see if centering ht
	cmp	ch, HJ_CENTER_CHILDREN_VERTICALLY shl \
				offset VCGDA_HEIGHT_JUSTIFICATION
7$:
	je	centerToParent			;parent is centering, branch
	
centerEvenly:
	tst	geoVars.VCG_numPasses		;see if doing first pass
	LONG	jz	exit			;yes, let's put off adding extra
	mov	cx, bx				;save leftOver in cx
	shr	bx, 1				;halve leftOver in bx
	sub	cx, bx				;remainder of leftOver in cx
	add	geoVars.VCG_centerOffset, bx
	add	geoVars.VCG_secondWidth, cx
	jmp	short exit			;and exit
	
centerToParent:
	;
	; We're going to do centering based on our parent.  This requires us
	; to have ALWAYS_RECALC_SIZE set and ONLY_RECALC_SIZE_IF_INVALID clear
	; in order for this to work properly, so we'll force those now.
	; -cbh 3/10/93
	;
	or	ds:[di].VI_geoAttrs, mask VGA_ALWAYS_RECALC_SIZE
	and	ds:[di].VI_geoAttrs, not mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID

	test	cl, mask VCGA_ORIENT_CHILDREN_VERTICALLY	;see if parent vertical
	pushf					;save result
	mov	ax, MSG_VIS_COMP_GET_MARGINS
	push	bp
	call	VisCallParent			;get parent's margins
	mov	di, bp				;bottom margin in di
	pop	bp
	popf					;restore parent's vertical flag
	jz	10$				;parent not vertical, branch
	xchg	ax, di				
	xchg	cx, dx
10$:						;comp width margins now in
						;   di, dx
	push	dx				;save parent width end margin
	push	di				;save parent width begin margin
	pushf
	push	bp				;local vars ptr
	call	VisGetParentCenter
	mov	di, bp				;keep bottom in di
	pop	bp				;local vars ptr
	popf
	jnz	subtractMargins			;vertical, branch
	mov	cx, ax				;else put width center in cx
	mov	dx, di				;portion after center in dx
	
subtractMargins:
	pop	ax				;get parent's width begin margin
	sub	cx, ax				;parentLeft -= parent begMargin
	pop	ax				;get parent's width end margin
	sub	dx, ax				;parentRight -= parent endMargin
	push	dx				;save parentRight
	push	cx				;and parentLeft
	push	bp				;local vars ptr
	mov	ax, MSG_VIS_COMP_GET_MARGINS
	call	ObjCallInstanceNoLock		
	call	AdjustMarginsToOrientation	;get child margins, ax/bp/cx/dx
	mov	ax, bp				;keep width-begin margin in ax
	pop	bp				;local vars ptr
	;
	; Create availLeft by subtracting top margin from parentLeft, and
	; subtracting centerOffset from it.  Then add it to the centerOffset.
	;
	pop	di				;restore parentLeft
	push	dx				;save child's width-end margin
	mov	dx, ax				;width-begin margin in dx
	cmp	dx, di				;if margin bigger, don't negate
	ja	tryRightMargin
	
	neg	dx				;subtract from margin
	add	dx, di				;  and leave in cx
	
	sub	dx, geoVars.VCG_centerOffset   ;cx now availLeft
	jb	tryRightMargin        		;exit if no extra before center
	cmp	bx, dx				;leftover < extraAvail?
	ja	addAvailLeft			;no, branch
	mov	dx, bx				;else we'll add leftOver
	
addAvailLeft:
	add	geoVars.VCG_centerOffset, dx    ;add to center offet
	sub	bx, dx				;less left over now.
	
tryRightMargin:
	;
	; Create availRight by subtracting bottom margin from parentRight
	; and subtracting secondWidth from it.  Then add it (or leftOver
	; amount, whichever is smaller) to secondWidth.  Take the remaining
	; leftOver and carry it over to calculations of the first side.
	;
	pop	dx				;restore end-margin
	pop	di				;restore parentRight
	mov	cx, dx				;end margin in cx
	cmp	cx, di				;if margin > parentRight,
	ja	exit				;then nothing to add
	
	neg 	cx				;subtract from margin
	add	cx, di				;  and leave in cx
	sub	cx, geoVars.VCG_secondWidth     ;cx now availRight
	jb	exit	         		;exit if no extra after center
	cmp	bx, cx				;leftover < extraAvail?
	ja	addAvailRight			;no, branch
	mov	cx, bx				;else we'll add leftOver
	
addAvailRight:
	add	geoVars.VCG_secondWidth, cx     ;add to second width
	
exit:
	DoPop	dx, cx, bx, ax, bp
	.leave
	ret
AdjustCenterToPassedWidth	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	AdjustMarginsToOrientation

SYNOPSIS:	Returns orientation-specific margins.

CALLED BY:	AdjustCenterToPassedWidth, VisCompRecalcSize

PASS:		*ds:si -- object

RETURN:		ax -- begin margin along length of composite
		bp -- begin margin along width
		cx -- end margin along length
		dx -- end margin along width

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/17/91		Initial version

------------------------------------------------------------------------------@

AdjustMarginsToOrientation	proc	near
	class	VisCompClass

	push	di	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY	
	jz	20$
	xchg	ax, bp				
	xchg	cx, dx
20$:			
	pop	di			
	ret
AdjustMarginsToOrientation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapIfVerticalDS, SwapIfVerticalES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swaps x and y if a vertical composite.   GeoResize works
		in lengths and widths, rather than x and y values.  When
		getting or setting size data of children, as well as dealing
		with the outside world, the parameters have to be switched
		for the routine to work for vertical composites.

CALLED BY:	GeoResize

PASS:		cx, dx	-- dimensions of visual object 
		ds:[di] -- visible instance data of composite (SwapIfVerticalDS)
		es:[di] -- visible instance data of composite (SwapIfVerticalES)

RETURN:		cx, dx  -- swapped if composite is vertical

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/24/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SwapIfVerticalDS	proc	near
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	notVertical			    ;no, exit	
	xchg	cx, dx				    ;else switch dimensions
	
notVertical:
	ret
	
SwapIfVerticalDS	endp


SwapIfVerticalES	proc	near
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

	test	es:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	notVertical   			    ;no, exit	
	xchg	cx, dx				    ;else switch dimensions
	
notVertical:
	ret
	
SwapIfVerticalES	endp


	
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets length of child, adjusting for orientation of composite.

CALLED BY:	INTERNAL

PASS:		ds:si -- pointer to visible instance data of child
		es:di -- pointer to visible instance data of composite
		
RETURN:		cx    -- Return value.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
       		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/24/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
GetLength	proc near
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

	mov	cx, ds:[si].VI_bounds.R_right	      ;assume horiz composite
	sub	cx, ds:[si].VI_bounds.R_left
	test	es:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	useLeftRight				     	;no, branch
	mov	cx, ds:[si].VI_bounds.R_bottom
	sub	cx, ds:[si].VI_bounds.R_top
	
useLeftRight:
	ret
	
GetLength	endp
	
	
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets width of child, adjusting for orientation of composite.

CALLED BY:	INTERNAL

PASS:		ds:si -- pointer to visible instance data of child
		es:di -- pointer to visible instance data of composite
		
RETURN:		cx    -- Return value.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
       		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/24/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
GetWidth	proc near
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

	mov	cx, ds:[si].VI_bounds.R_bottom      	;assume horiz composite
	sub	cx, ds:[si].VI_bounds.R_top
	test	es:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	useTopBottom			     	;no, branch
	mov	cx, ds:[si].VI_bounds.R_right
	sub	cx, ds:[si].VI_bounds.R_left
	
useTopBottom:
	ret
	
GetWidth	endp
	
	
	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the right edge of an object.   Makes an adjustment if
		it's a VERTICAL object.  Expected to be performed on 
		composites.   If the composite is a window, we return zero
		rather than the window's offset to its parent window.

CALLED BY:	GeoMove

PASS:		es:di -- ptr to visible instance data of
			 the object to get the right edge of

RETURN:		cx -- the right edge

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/30/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
GetRight	proc	near
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

	mov	cx, es:[di].VI_bounds.R_right		;assume horizontal
	test	es:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	useRight				;no, branch
	mov	cx, es:[di].VI_bounds.R_bottom		;else get bottom
	
useRight:
	ret
	
GetRight	endp

	


COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckValidChild

SYNOPSIS:	Error checking routine when doing child geometry.

CALLED BY:	DoDesiredResize
       
PASS:		ss:bp -- geoVars
		ds:si -- child handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK

CheckValidChild		proc	near
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.
	geoVars	local	VCG_localVars
	.enter	inherit

	push	ax				;save this
	mov	ax, geoVars.VCG_childHandle  	;put handle in bp
	call	ECLMemExists			;see if handle exists
	jnc	DWIC1				;branch if so
	ERROR	UI_RESIZE_BAD_CHILD_HANDLE	;else signal error
DWIC1:
	pop	ax				;restore
	.leave
	ret
CheckValidChild		endp

endif


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompGetSpacing -- 
		MSG_VIS_COMP_GET_CHILD_SPACING for VisCompClass

DESCRIPTION:	Returns spacing for the object.  This default message
	returns zero spacing and margins.  Subclass this message to create
	margins and spacing for your composite.

PASS:	
	*ds:si - instance data
	es - segment of VisCompClass
	di - MSG_GET_SPACING

RETURN:	
	cx -- spacing between children
        dx -- spacing between wrapped lines of children
	ax, bp -- destroyed

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/13/89		Initial version

------------------------------------------------------------------------------@


VisCompGetSpacing	method	VisCompClass, MSG_VIS_COMP_GET_CHILD_SPACING
	mov	cx, VIS_COMP_DEFAULT_SPACING
	mov	dx, cx
	Destroy	ax, bp
        ret
VisCompGetSpacing	endm

			


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompVisCompGetMargins -- 
		MSG_VIS_COMP_GET_MARGINS for VisCompClass

DESCRIPTION:	Returns margins for the composite.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_COMP_GET_MARGINS

RETURN:		ax 	- left margin
		bp	- top margin
		cx	- right margin
		dx	- bottom margin

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/15/91		Initial version

------------------------------------------------------------------------------@

VisCompVisCompGetMargins	method VisCompClass, \
				MSG_VIS_COMP_GET_MARGINS
	clr	ax
	mov	bp, ax
	mov	cx, ax
	mov	dx, ax
	ret
VisCompVisCompGetMargins	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TestGetCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Error check routines for GetCenter

CALLED BY:	GeoResize, GeoMove, CalcLineStartAndSpacing

PASS:		cx, dx, ax, bp -- amounts of space left, right, above and
			below center

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 6/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


if	ERROR_CHECK
	
TestGetCenter	proc	near
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

	cmp	cx, MAX_COORD/2
	ERROR_A	UI_GEOMETRY_SIZE_LEFT_OF_CENTER_TOO_LARGE
	cmp	dx, MAX_COORD/2
	ERROR_A	UI_GEOMETRY_SIZE_RIGHT_OF_CENTER_TOO_LARGE
	cmp	ax, MAX_COORD/2
	ERROR_A	UI_GEOMETRY_SIZE_ABOVE_CENTER_TOO_LARGE
	cmp	bp, MAX_COORD/2
	ERROR_A	UI_GEOMETRY_SIZE_BELOW_CENTER_TOO_LARGE
	ret
TestGetCenter	endp

endif
	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckValidResize, CheckValidGetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Error checking routine for GetSize and Resize messages.
		Should be at the beginning of anyone's message.

CALLED BY:	resize messages

PASS:		ds:*si -- instance
		normal GetSize or Resize parameters

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 8/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK
	

CheckValidGetSize	proc	near
	push	cx, dx     						
	and 	cx, not mask RSA_CHOOSE_OWN_SIZE 
	and	dx, not mask RSA_CHOOSE_OWN_SIZE 
	cmp	cx, MAX_COORD			;make sure width OK     
	ERROR_A	UI_GEOMETRY_SUGGESTED_WIDTH_TOO_LARGE
	cmp	dx, MAX_COORD			;make sure length OK    
	ERROR_A	UI_GEOMETRY_SUGGESTED_HEIGHT_TOO_LARGE
 	DoPop	dx, cx		       				        
	ret
	
CheckValidGetSize	endp
	
	
CheckValidResize	proc	near
 	cmp	cx, MAX_COORD			;make sure width OK     
	ERROR_A	UI_GEOMETRY_WIDTH_TOO_LARGE
 	cmp	dx, MAX_COORD			;make sure length OK    
	ERROR_A UI_GEOMETRY_HEIGHT_TOO_LARGE
	ret
	
CheckValidResize	endp

endif



COMMENT @----------------------------------------------------------------------

METHOD:		VisCompPositionMethod -- 
		MSG_VIS_POSITION_BRANCH for VisCompClass

DESCRIPTION:	Sets positions for children of a composite.  Value passed in
		is the origin to use for the composite.  If not a window,
		will move the composite to that location.  (Windows are done
		with a MSG_VIS_POSITION_BRANCH of 0,0 and a MSG_VIS_SET_POSITION, with a position
		which will position the window.

PASS:
	*ds:si - instance data
	es - segment of VisCompClass
	di - MSG_VIS_POSITION_BRANCH
	cx - left edge
	dx - top edge

RETURN: 
	nothing
	ax, cx, dx, bp -- destroyed

DESTROYED:
	bx, si, di, es

PSEUDO CODE/STRATEGY:
        set the object's bounds (move it)
	if it's a window
		DoPositionGeometry (0,0)
	elif not managing children
		cx, dx = relative change from object's old origin
		call DoMove on each child to move it as well
	else
		DoPositionGeometry (cx, dx)
       
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/13/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

VisCompPositionMethod	method	VisCompClass, MSG_VIS_POSITION_BRANCH	
	clr	bp				;no special margins, centering
	FALL_THRU	VisCompPosition

VisCompPositionMethod	endm

COMMENT @----------------------------------------------------------------------

METHOD:		VisCompPosition

DESCRIPTION:	Sets positions for children of a composite.  Value passed in
		is the origin to use for the composite.  If not a window,
		will move the composite to that location.  (Windows are done
		with a MSG_VIS_POSITION_BRANCH of 0,0 and a MSG_VIS_SET_-
		POSITION, with a position which will position the window.

PASS:
	*ds:si - instance data

	cx - left edge
	dx - top edge
	bp --   VisCompSpacingMarginsInfo

RETURN: 
	nothing
	ax, cx, dx, bp -- destroyed

DESTROYED:
	bx, si, di, es

PSEUDO CODE/STRATEGY:
        set the object's bounds (move it)
	if it's a window
		DoPositionGeometry (0,0)
	elif not managing children
		cx, dx = relative change from object's old origin
		call DoMove on each child to move it as well
	else
		DoPositionGeometry (cx, dx)
       
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/13/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@


VisCompPosition		proc	far
	class	VisCompClass

	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di

	push	bp				;save passed bp
	mov	di, ds:[si]			;Can be called statically!
	add	di, ds:[di].Vis_offset
	push	ds:[di].VI_bounds.R_left	;save current left
	push	ds:[di].VI_bounds.R_top		;and top
	push	cx				;save new left
	push	dx				;and new top
	call	VisSetPosition			;call move directly
	pop	ax				;restore new top
	pop	bp				;and new left
	pop	dx				;and old top
	pop	cx				;and old left
	
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW or mask VTF_IS_PORTAL
	jz	notWindow			;not a window, branch
	clr	cx				;else let's use zero origin
	clr	dx				;  for child placement
	test	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN
	jz	position			;managing children, go position

	pop	bp				;throw away passed bp
	jmp	done
	
notWindow:	
	test	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN
	jz	managing			;managing children, branch
	
	;
	; If we're here, it's because we're a non-window, non-portal, non-
	; managing, George Bush kind of useless nothing.  Seriously, in this
	; case we will move the children over to follow the parent's movement
	; from its old position.  People may not like this; we'll wait until
	; then.
	;
	sub	bp, cx				;subtract old left from new
	sub	ax, dx				;subtract old top from new

	; set up for traversal of children

	clr	bx				; initial child (first
	push	bx				; child of
	push	bx				; composite)
	mov	bx,offset VI_link		;pass offset to LinkPart
	push	bx
NOFXIP <	push	cs			;pass callback routine (seg)	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset DoMove
	push	bx				;pass callback routine (seg)

	mov	bx,offset Vis_offset		;pass offset to master part
	mov	di,offset VCI_comp		;pass offset to composite
	call	ObjCompProcessChildren
	pop	bp				;throw away passed bp
	jmp	done

managing:
	mov	dx, ax				;restore new top
	mov	cx, bp				;and left
position:
	pop	bp				;restore passed bp
	call	DoPositionGeometry
done:

	pop	di
	call	ThreadReturnStackSpace

	ret
	
VisCompPosition	endp
	
		


COMMENT @----------------------------------------------------------------------

ROUTINE:	DoPositionGeometry

SYNOPSIS:	Positions children.

CALLED BY:	VisCompPosition

PASS:		
	*ds:si - instance data
	es - segment of VisCompClass
	di - MSG_VIS_POSITION_BRANCH
	cx - left edge
	dx - top edge

RETURN:		
	nothing

DESTROYED:	
	ax, bx, cx, dx, bp, si, di, ds, es

PSEUDO CODE/STRATEGY:
       get left and top from object bounds
       SwapIfVertical (left, top) to normalize composite
       get the spacing of the composite
       add left margin to left, top margin to top
       subtract right margin and bottom margin from bounds
       
       child = firstChunk(comp)
       if child <> NIL
         repeat
           CalcLineStartAndSpacing to set curLength, childSpacing, centerOffset
	   if we are including child in geometry
	       if wrapping
	            if curLength + child's length > right edge of composite
		        add line width and width spacing to curWidth
			CalcLineStartAndSpacing
	       endif
	       if WJ_CENTER
		    tempCenter = MSG_VIS_GET_CENTER(child)
		    tempTop = curWidth + centerOffset - tempCenter
	       else if WJ_BOTTOM
		    tempTop = lineWidth + curWidth - width of child
	       else
		    tempTop = curWidth
	       endif
	       SwapIfVertical (curLength, tempTop)
	       POSITION child (curLength, tempTop) 
	       SwapIfVertical (curLength, tempTop)
	       add length of child and childSpacing to curLength
	  child = nextChunk(child)
	until child = NULL
      restore real bounds of composite

REGISTER USAGE:
	 	cx - curLength
		dx - curWidth
		bx - childSpacing
		ax - scratch

KNOWN BUGS/SIDE EFFECTS/IDEAS:
      
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 5/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@
VCP_localVars	struct
    VCP_child			optr
    VCP_compHandle		word		;handle of composite
    VCP_passedLeft		word		;passed left
    VCP_lengthSpacing		word		;length spacing
    VCP_widthSpacing		word		;width spacing
    VCP_calcLineChild		word		;child handle for CalcLineA...
    VCP_childSpacing		word
    VCP_lengthJust	GenericJustifications 	;justification along length
    VCP_widthJust	GenericJustifications 	;justification along width
    VCP_lengthAttrs	DimensionAttrs		;other length attributes
    VCP_widthAttrs	DimensionAttrs		;other width attributes
    
    VCP_lineWidth		word		;temporary values gotten via
    VCP_centerOffset		word		;  MSG_VIS_COMP_RESTORE_TEMP_
    VCP_secondWidth		word		;  GEO_DATA.
    VCP_spacingStuff		word		;spacing, margins passed in bp
    VCP_childCount		word		;child count, used in DoSpacing
    VCP_wrapCount		word		;wrap count
    VCP_fractionalSpacing	word		;fractional spacing, for full
						;  justification
    VCP_fractionalPosition	word		;fractional child position, for
						;  full justification
    
VCP_localVars	ends
		
posVarsDi	equ	<ss:[di - size VCP_localVars]>


DoPositionGeometry	proc	near
	mov	di, bp				;di <- spacing, margin stuff
	posVars	local	VCP_localVars
	.enter
	class	VisCompClass		

	mov	posVars.VCP_spacingStuff, di	;store passed margin stuff

	;					
	; Set up justification vars, before we forget...
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	call	GetDimensionAttrs		;length flags in al, width ah
	mov	{word} posVars.VCP_lengthAttrs,ax  ;store here
	and	ax, (mask DA_JUSTIFICATION shl 8) or mask DA_JUSTIFICATION
	shr	ax, 1				;offset DA_JUSTIFICATION
	shr	ax, 1
	mov	{word} posVars.VCP_lengthJust,ax   ;store justif. only here
	
	;
	; If we need to, we'll retrieve some geometry information left over
	; from the MSG_VIS_RECALC_SIZE.
	;
	cmp	posVars.VCP_widthJust, GJ_CENTERED ;centering object?
	je	getTempVars			   ;yes, get temp vars
	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
        jnz	getTempVars			   ;wrapping, get temp vars
	cmp	posVars.VCP_widthJust, GJ_END_JUSTIFIED
	jne	afterTempVars			;not bottom justified, skip
	
getTempVars:
	push	cx, dx
	push	bp
	call	VisCompRestoreTempGeoData	;temp vars in cx, dx, bp
	mov	ax, bp				;second width now in ax
	pop	bp
EC <	mov	di, ds:[si]						   >
EC <	add	di, ds:[di].Vis_offset					   >
EC <	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP   >
EC <    jnz	EC10				   ;wrap, need cx          >
EC <	cmp	posVars.VCP_widthJust, GJ_END_JUSTIFIED			   >
EC <	jne	EC15				;not bottom justified, skip>
EC <EC10:								   >
EC <	cmp	cx, -1							   >
EC <	ERROR_E	UI_CANT_DO_CUSTOM_RECALC_SIZE_AND_DO_SPECIAL_JUSTIFICATION  >
EC <EC15:							           >
EC <	cmp	posVars.VCP_widthJust, GJ_CENTERED ;centering object?	   >
EC <	jne	EC30				   ;no, don't need dx, bp  >
EC <	cmp	dx, -1							   >
EC <	ERROR_E	UI_CANT_DO_CUSTOM_RECALC_SIZE_AND_DO_SPECIAL_JUSTIFICATION  >
EC <	cmp	ax, -1							   >
EC <	ERROR_E	UI_CANT_DO_CUSTOM_RECALC_SIZE_AND_DO_SPECIAL_JUSTIFICATION  >
EC <EC30:								   >
   	mov	posVars.VCP_lineWidth, cx	;store line width, if any
   	mov	posVars.VCP_centerOffset, dx	;store center offset, if any
   	mov	posVars.VCP_secondWidth, ax	;store second width, if any
	pop	cx, dx
   	
afterTempVars:
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	push	ds:[di].VI_bounds.R_left	;save current left
	
	mov	posVars.VCP_compHandle, si	; save composite handle
	mov	di, ds:[si]			; point at instance data
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW or mask VTF_IS_PORTAL
	jz	useOrigin			; if so, don't store the offset
						;     from the window
	push	ds:[di].VI_bounds.R_left   	; save current left
	push	ds:[di].VI_bounds.R_top		; and top
	clr	cx				; coords relative to window
	clr	dx
	
useOrigin:
	call	VisSetPosition				; set position for use later
	
	test	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN
	LONG	jnz	done			;yes, go do calculations

	push	ds:[di].VI_bounds.R_bottom
	push	ds:[di].VI_bounds.R_right
	;
	; Make adjustments to passed x and y, and the length and width of
	; the composite, according to what the margins are.
	;
	mov	cx, ds:[di].VI_bounds.R_left	;put left in bp
	mov	dx, ds:[di].VI_bounds.R_top    	;put top in bx
	call	SwapIfVerticalDS		;correct orientation
	push	bp				;save bp
	push	dx				;save passed width start
	push	cx				;save passed length start
	push	bp				;save bp again
	mov	cx, posVars.VCP_spacingStuff
	call	GetVisCompSpacing
   	pop	di				;restore pointer to locals
	mov	posVarsDi.VCP_lengthSpacing, cx ;save spacing
	mov	posVarsDi.VCP_widthSpacing, dx  ;save width spacing

	mov	dx, posVarsDi.VCP_spacingStuff
	call	GetVisCompMarginsAndAdjust	
	pop	di				;restore length start
	add	di, ax				;add length's begin margin
	pop	ax				;restore width start
	add	ax, bp				;add width's begin margin
	
	push	di				;save passed left
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	call	SwapIfVerticalDS		;switch end margins if vertical
	sub	ds:[di].VI_bounds.R_right, cx	;subtract from right
	sub	ds:[di].VI_bounds.R_bottom, dx	;and bottom
	pop	cx				;restore passed left to cx
	mov	dx, ax				;new passed top in dx
	
	pop	bp				;restore local vars
	mov	posVars.VCP_passedLeft, cx	;keep passed left here
						; (different in a window)
	;
	; Get wrap count, if any.  We may need it.
	;
	push	cx, dx
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCI_geoAttrs, mask VCGA_WRAP_AFTER_CHILD_COUNT	
	jz	noWrapCount
	push	bp
	mov	ax, MSG_VIS_COMP_GET_WRAP_COUNT
	call	ObjCallInstanceNoLock
	pop	bp
	mov	posVars.VCP_wrapCount, cx	;save wrap count
noWrapCount:
	pop	cx, dx

	; set up for traversal of children

	mov	posVars.VCP_childSpacing,bx
	clr	posVars.VCP_fractionalPosition	;no fractional position yet

	clr	bx				; initial child (first
	push	bx				; child of
	push	bx				; composite)

	mov	posVars.VCP_child.handle, bx	;"at first child"

	mov	bx,offset VI_link		;pass offset to LinkPart
	push	bx
NOFXIP <	push	cs			;pass callback routine (seg)	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset DoAddSize
	push	bx				;pass callback routine (seg)

	mov	bx,offset Vis_offset		;pass offset to master part
	mov	di,offset VCI_comp		;pass offset to composite
	call	ObjCompProcessChildren


	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset
	pop	ds:[di].VI_bounds.R_right	;restore this
	pop	ds:[di].VI_bounds.R_bottom      ;restore this
done:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW or mask VTF_IS_PORTAL
	jz	exit			; not a window, branch
	pop	dx			; restore old top
	pop	cx			; and old left

	call	VisSetPosition			; set correct bounds
exit:	
	.leave
	ret
DoPositionGeometry	endp

	
	
	


COMMENT @----------------------------------------------------------------------

ROUTINE:	MoveChild

SYNOPSIS:	Performs the moving of a child.

CALLED BY:	VisCompPosition

PASS:		es:di - composite's vis instance
		ds:si  - handle of child
		cx, dx - left, top to use

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/22/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

MoveChild	proc	near
	posVars	local	VCP_localVars
	
	.enter	inherit
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

EC <	call	CheckForDamagedES	; Make sure *es still object block >
	call	SwapIfVerticalES	; switch cx, dx if necessary

	push	es:[LMBH_handle]	; save handle of es object block
	call	VisSendPositionAndInvalIfNeeded		; do an optimized move
	
	pop	di			; get handle in di
	xchg	bx, di
	call	MemDerefES		; deref handle to es
	mov	bx, di			; restore bx

	mov	di, posVars.VCP_compHandle      ;restore comp data ptr
	mov	di, es:[di]
	add	di, es:[di].Vis_offset		; ds:di = VisInstance
	.leave
	ret

MoveChild	endp


		


COMMENT @----------------------------------------------------------------------

FUNCTION:	DoAddSize

DESCRIPTION:	Add in another child's size

CALLED BY:	ObjCompProcessChildren -- callback

PASS:
	*ds:si - child
	*es:di - parent
	bp     - local variables (posVars) (see VisCompPosition)
	
	cx - curLength
	dx - curWidth
	posVars.VCP_childSpacing - childSpacing

RETURN:
	carry set if getting out of loop, clear if ok
	
DESTROYED:
	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

DoAddSize	proc	far
	posVars	local	VCP_localVars
	
	.enter	inherit
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

EC <	call	CheckForDamagedES	; Make sure *es still object block >
	mov	posVars.VCP_child.chunk, si	;save handle to child
	;
	; Traverse children, adding their length to the curLength, wrapping
	; if necessary.
	;
	cmp	posVars.VCP_child.handle,0
	mov	bx,ds:[LMBH_handle]
	mov	posVars.VCP_child.handle,bx
	mov	bx, posVars.VCP_childSpacing
	jnz	dontCalcSpacing
	call	CalcLineStartAndSpacing		;setup left edge initially
	mov	posVars.VCP_childCount, 0	;re-init the child count
	clr	posVars.VCP_fractionalPosition	;no fractional position yet

dontCalcSpacing:
	mov	si, ds:[si]			;point to child instance
	add	si, ds:[si].Vis_offset		;ds:si = VisInstance

	test	ds:[si].VI_attrs, mask VA_MANAGED ;managing this child, are we?
	LONG	jz	done		 	;no, exit
	
	push	di				;save handle of composite
	mov	di, es:[di]			;point to parent instance
	add	di, es:[di].Vis_offset		;es:di = VisInstance
	;
	; Test for a wrapping situation.  See if the next child will make
	; the line too long.  If so, reset the left margin and increase our
	; width.
	;
	test	es:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
        jz	skipWrap			;not wrapping, branch
	push	cx				;save current length
	mov	ax, cx				;get curLength in ax
	call	GetLength			;get child's length in cx
	add	ax, cx				;and add to curLength
	
	call	GetRight			;get right edge of composite
	cmp	ax, cx				;have we gone over?
	pop	cx				;restore cx while we find out
	jbe	skipWrap			;no, branch
	;
	; Wrap to next line
	;
	add	dx, posVars.VCP_lineWidth         ;add line width to curWidth
	add	dx, posVars.VCP_widthSpacing 	  ;and width spacing
	mov	cx, posVars.VCP_passedLeft	  ;get passed left edge
	clr	posVars.VCP_fractionalPosition	  ;no fractional position yet
	pop	di				  ;restore comp handle
	push	di				  ;save it again
	call	CalcLineStartAndSpacing		  ;reset to left edge

skipWrap:
	pop	di				  ;restore comp handle
	mov	di, es:[di]			  ;point to parent instance
	add	di, es:[di].Vis_offset		  ;es:di = VisInstance
	
	push	dx, cx				  ;save curWidth and curLength
	;
	; Do any operations needed to justify the child's position in the
	; width direction.  
	;
	cmp	posVars.VCP_widthJust, GJ_END_JUSTIFIED
	jne	notBottomJust		    	    ;not end-just, branch
	call	GetWidth			    ;width of child in cx
	add   	dx, posVars.VCP_lineWidth           ;add line width to curWidth
	sub	dx, cx				    ;and subtract child width
	
notBottomJust:
	;
	; If we're centering the object in the width direction, we need
	; to take the curWidth, add to it the offset to the overall
	; center as calculated in CalcLineStartAndSpacing, and subtract
	; the offset to the current child.
	;
	cmp	posVars.VCP_widthJust, GJ_CENTERED ;centering object?
	jne	notCentering	                   ;no, branch
	test	ds:[si].VI_geoAttrs, mask VGA_DONT_CENTER
	jnz	notCentering		           ;child don't want to, branch
       	push	dx				   ;save curWidth, we'll need it
	mov	si, posVars.VCP_child.chunk     ;put child handle in si
	
	push	bp
	push	es:[LMBH_handle]
	call	VisSendCenter			;get the child's center
	pop	di
	xchg	bx, di
	call	MemDerefES
	xchg	bx,di
EC <	call	TestGetCenter			;make sure reasonable 	>
	mov	dx, ax				;put top center in dx
	pop	bp
	mov	di, posVars.VCP_compHandle 	;restore comp data ptr
	mov	di, es:[di]
	add	di, es:[di].Vis_offset		; ds:di = VisInstance
   
	call	SwapIfVerticalES		;center along width of 
						;    composite in dx now
	mov	ax, dx		    		;put in ax for the moment
	pop	dx				;get curWidth
	add	dx, posVars.VCP_centerOffset    ;add off to overall center
	sub	dx, ax				;subtract offset to child cent
	
notCentering:
	mov	si, posVars.VCP_child.chunk  ;pass handle to child
	pop	cx				;restore length position
	push	cx				;save it again
	call	MoveChild			; move the child
	DoPop	cx, dx				;restore curWidth and curLength
	mov	si, ds:[si]			;and point to child
	add	si, ds:[si].Vis_offset		; ds:si = VisInstance
	;
	; Update curLength to reflect the length of the child.
	;
	mov	ax, cx				;ax holds curLength
	call	GetLength			;get length of child in cx
	tst	cx	
	pushf
	add	cx, ax				;add to curLength
	;
	; New change: only add spacing if the child had any size at all.
	; 2/ 6/92 cbh   (Also, new changes for fractional position.  -12/16/92
	;
	popf					;did child have zero length?
	jz	done				;yes, skip
	mov	si, posVars.VCP_fractionalSpacing
	add	posVars.VCP_fractionalPosition, si
	adc	cx, bx				;else add spacing btw children

	; Hack to better handle little fractional errors.  -12/16/92

	cmp	posVars.VCP_fractionalPosition, 0fffdh
	jbe	done
	clr	posVars.VCP_fractionalPosition
	inc	cx
done:
	;
	; Go to the next child and loop.
	;
	mov	si, posVars.VCP_child.chunk	;reset these
	mov	posVars.VCP_childSpacing, bx
	clc					;always OK
	.leave
	ret

DoAddSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLineStartAndSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up curLength.  May need to do a pass through the 
		children on the line about to be done to see how long
		the children are for center, right, and full justification.

CALLED BY:	INTERNAL

PASS:		*es:di -- handle of parent composite
		cx    -- offset to left edge of composite
		ss:bp -- point to top of local variables

RETURN:		cx -- initial position of first child in line, lengthwise
		bx -- space between children

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
       if WJ_CENTER or not LJ_LEFT
;           centerOffset = tempLength = 0
	    tempLength = 0
	   if useSpacingAtEndsOfComposite
	   	numSpaces = 1;   /* we want 2 + (numChildren - 1) space areas */
	   else
	   	numSpaces = -1;  /* we want 0 + (numChildren - 1) space areas */
	   endif
	   subtract length spacing from left edge
	   repeat
	       if we include child in geometry
		   if right edge of comp > tempLength + child length + len spc
		       tempLength = tempLength + childLength + length spacing
		       add child length to minLength
		       increment numSpaces
		   else
		       if can chop length
		           return (curLength=0, childSpacing=lengthSpacing)
		       else
		           exit loop
		       endif
		   endif
	       child = nextChunk(child)
	   until child = NIL
       endif
       
       if LJ_RIGHT or LJ_CENTER
           curLength = length(composite) - tempLength
	   if LJ_CENTER
	       divide curLength by 2
       else
           curLength = 0
           if LJ_FULL and numSpaces
	       childSpacing = (right(comp) - passedLeft + 1) / numSpaces
	   else 
	       childSpacing = lengthSpacing
	   endif
       endif
       add left to curLength
       if useSpacingAtEndsOfComposite
       	   add childSpacing to curLength
       endif
       return (curLength, childSpacing, centerOffset)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/25/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CalcLineStartAndSpacing	proc	near	uses di, si, dx
posVars	local	VCP_localVars
	.enter	inherit
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

EC <	call	CheckForDamagedES	; Make sure *es still object block >
	mov	si,di				;si = comp handle
	mov	di,es:[di]
	add	di,es:[di].Vis_offset
	; 
	; If the object is not left justified, or if we're doing special
	; width centering, we need to make a pass through the line.
	;
	push	cx					   ;save comp left edge
	cmp	posVars.VCP_lengthJust, GJ_BEGIN_JUSTIFIED ;if left justifying,
	je	endCalcLoop	      		           ;  no loop necessary
	;
	; Now we loop through the children, summing their lengths until
	; they fill a line.  If we're doing width centering, we will query
	; each child for the offset to its center and keep the maximum offset.
	;
	; Register usage:   ax is min length, bx is scratch, si is ptr to
	; child we're looking at, bp is child handle, dl holds the number of
	; spaces in between children.  cx holds tempLength to see where the 
	; line overflows.
	;
	clr	ax				  ;sum of child lengths
;	mov	posVars.VCP_centerOffset, ax      ;start with no center offset
	clr	dx				  ;initial # of spaces between 
	dec	dx				  ;   children
	test	es:[di].VCI_geoAttrs, mask VCGA_INCLUDE_ENDS_IN_CHILD_SPACING
	jz	10$				  ;no spacing on ends, branch
	add	dx, 2				  ;else 2 more spaces
;
;This was wrong.  It would always fall through to 10$ and subtract one length
;spacing.  If including ends in child spacing, we need to *add* one spacing
;to account for the spacing to the left of the first child.  We subtract for
;the case where we don't include ends in child spacing.
;
;This caused a bug where the geometry algorithm would wrap the children
;(thus increasing the height of the composite), but the positioning algorithm
;wouldn't wrap the children).
;
;-- brianc 5/18/95
;
	;
	; account for initial spacing if including ends in child spacing
	;
	add	cx, posVars.VCP_lengthSpacing     ;subtract length spacing
	jmp	short 11$

10$:
	;	
	; Get left edge of composite (already in cx), minus one spacing
	;
	sub	cx, posVars.VCP_lengthSpacing     ;subtract length spacing
11$:
	clr	posVars.VCP_fractionalPosition	  ;no fractional position yet

	; set up for traversal of children

	push	ds				;swap ds and es
	push	es
	pop	ds
	pop	es

	push	posVars.VCP_child.handle	;save this, will get zeroed
	clr	bx				;initial child (first
	mov	posVars.VCP_childCount, bx	;init child count

	push	bx				;child of
	push	bx				;composite)
	mov	bx,offset VI_link		;pass offset to LinkPart
	push	bx
NOFXIP <	push	cs			;pass callback routine (seg)	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset DoSpacing
	push	bx				;pass callback routine (seg)

	mov	bx,offset Vis_offset		;pass offset to master part
	mov	di,offset VCI_comp		;pass offset to composite
	call	ObjCompProcessChildren
	pop	posVars.VCP_child.handle	;restore this

	push	ds				;swap ds and es
	push	es
	pop	ds
	pop	es
	
	;
	; We're overflowing.  Check to see if we're chopping the length,
	; and do a normal left justify if so.
	;
	mov	di,es:[si]
	add	di,es:[di].Vis_offset
;	test	posVars.VCP_lengthAttrs, mask DA_CAN_TRUNCATE_TO_FIT_PARENT
;	jz	endCalcLoop			;not set, do normal exit
;	clr	cx				;else left justify
;	jmp 	short normalSpacing		;and go do normal spacing
;
endCalcLoop:
	; 
	; Now we need to return left margin in cx and spacing between 
	; children in bx.
	;
	; If right justified, subtract tempLength from composite length
	; to see where to start putting the menus.
	;
	cmp	posVars.VCP_lengthJust, GJ_END_JUSTIFIED
	je	doRightCenter			;end justified, branch
	cmp	posVars.VCP_lengthJust, GJ_CENTERED
	je	doRightCenter			;centering, branch
	clr	cx				;else left justify
	jmp	short checkFull			;on to the next thing
	
doRightCenter:
	mov	bx, cx				;put tempLength in bx
	call	GetRight			;returns length in cx
	sub	cx, bx				;subtract temp length
	cmp	posVars.VCP_lengthJust, GJ_CENTERED
	jne	normalSpacing			;not centering, branch
	shr	cx, 1				;else divide by 2
	
checkFull:
	;
	; If we're fully justifying, we need to figure out how much to space
	; the children.
	;
	cmp	posVars.VCP_lengthJust, GJ_FULL_JUSTIFIED
	jne	normalSpacing			  ;not full justifying, branch
	tst	dl				  ;any child spaces?
	jz	normalSpacing		          ;no, doesn't matter
	push	cx				  ;else save left edge
	call	GetRight			  ;length of comp in cx 
	sub	cx, posVars.VCP_passedLeft	  ;subtract passed left
	sub	cx, ax				  ;subtract min length
	mov	ax, cx				  ;put in ax for divide
	mov	bl, dl				  ;put num spaces in bx
	clr	bh
	
	clr	dx				  ;clear high word
	push	ax				  ;save amount of space divided
	tst	ax				  ;see if space to divide up is
	jns	divideSpacing			  ;   negative
	neg	ax				  ;if so, make positive
	
divideSpacing:
	mov	cx, ax				  ;total spacing now in dx.cx
	mov	ax, bx
	clr	bx				  ;divisor in bx.ax
	call	GrUDivWWFixed			  ;result in dx.cx
	pop	bx				  ;restore original space amount
	tst	bx				  ;see if was negative
	jns	endDivide			  ;no, we're done
	negdw	dxcx				  ;else make result negative
	
endDivide:
	mov	bx, dx				  ;return in bx
	mov	posVars.VCP_fractionalSpacing, cx ;save fractional spacing
	pop	cx				  ;restore left edge
	jmp	short done			  ;branch
	
normalSpacing:
	mov	bx, posVars.VCP_lengthSpacing     ;normal spacing
	clr	posVars.VCP_fractionalSpacing	  ;clear fraction
	
done:
	pop	dx				  ;also add in comp left edge
	add	cx, dx
	test	es:[di].VCI_geoAttrs, mask VCGA_INCLUDE_ENDS_IN_CHILD_SPACING
	jz	exit				  ;no spacing on ends, branch
	add	cx, bx				  ;else add child spacing
						  ;  to initial position
exit:
	.leave
	ret
CalcLineStartAndSpacing	endp
	

COMMENT @----------------------------------------------------------------------

FUNCTION:	DoSpacing

DESCRIPTION:	Do the spacing pass for CalcLineStartAndSpacing

CALLED BY:	ObjCompProcessChildren -- callback routine

PASS:
	*ds:si - child
	*es:di - parent
	posVars.VCP_child.handle -- 0 if we do child in any circumstances
				       non-zero, handle and chunk must match 
				       ds:si (we're basically skipping starting
				       at some child other than the first)
	ax -- minimum child length total (without spacing)
	dl -- number of spaces between children
	cx -- tempLength, the current right edge (to calculate overflow)
	
RETURN:
	carry set if getting out of loop, clear if OK

DESTROYED:
	bx, di

REGISTER/STACK USAGE:

SEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

DoSpacing	proc	far
posVars	local	VCP_localVars
	.enter	inherit
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

EC <	call	CheckForDamagedES	; Make sure *es still object block >
	;
	; This is being called by CalcLineStartAndSpacing, which wants to
	; start at a certain child.  It does this by setting VCP_child to
	; the one we want to start with.  If *ds:si doesn't match, we exit,
	; going on to the next child.  Otherwise we set handle to zero to
	; do the rest of the children and process the child.
	;
	cmp	posVars.VCP_child.handle,0		;doing all children?
	jz	doThisChild				;yes, continue
	cmp	si, posVars.VCP_child.chunk		;else must match ds:si
	jnz	skipToNextChild				;nope, exit
	mov	bx,ds:[LMBH_handle]			;also must match handle
	cmp	bx, posVars.VCP_child.handle
	jnz	skipToNextChild				;nope, exit
	mov	posVars.VCP_child.handle,0		;do all other children
	
doThisChild:
	mov	bx, posVars.VCP_childSpacing
	mov	di, es:[di]
	add	di, es:[di].Vis_offset
	mov	posVars.VCP_calcLineChild,si		;point to child again
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset		 	;ds:si = VisInstance
	test	ds:[si].VI_attrs, mask VA_MANAGED
	jz	doNextChild				;no, branch

	inc	posVars.VCP_childCount			;bump child count
	; 
	; Add length of child to tempLength, to see if we're at the end of 
	; the line.
	;
	push	cx				;save current temp length
	mov	bx, cx				;put tempLength in bx
	call	GetLength		        ;get length of child in cx
	add	bx, cx				;add child's length
	;
	; Change to not add spacing if the child had no length. -cbh 2/ 6/92
	;
	tst	cx				;
	jz	noSpacing
	add	bx, posVars.VCP_lengthSpacing	;add spacing
noSpacing:
	call	GetRight			;right edge of comp in cx
	cmp	bx, cx				;tempLength > comp length?
	pop	cx				;assume so, get old tempLen
	jbe	checkForcedWrap			;no, branch
	stc
	jmp	short doneWithChildren		;exit, no more children to do

checkForcedWrap:
	;
	; If there was a wrap count, we'll need to use it.
	;
	test	es:[di].VCI_geoAttrs, mask VCGA_WRAP_AFTER_CHILD_COUNT
	jz	addChildLength
	push	cx
	mov	cx, posVars.VCP_wrapCount	;get the wrap count
	cmp	cx, posVars.VCP_childCount	;see if equals child count
	pop	cx
	stc					;assume done
	jl	doneWithChildren		;past wrap count, quit (don't
						;  use a jbe here!)

addChildLength:
	mov	cx, bx				;use new tempLength
	;
	; Add length of child to minLength.  Increment child spaces.
	;
	mov	si, posVars.VCP_calcLineChild	;point to child again
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset		; ds:si = VisInstance
	call	GetLength			;get child length in cx
	;
	; Change to not add spacing if the child had no length. -cbh 2/ 6/92
	; We also won't increment the number of spaces.
	;
	tst	cx				;
	jz	noSpacing2
	add	ax, cx				;and add to min length
	inc	dx				;increment number of spaces
noSpacing2:
	mov	cx, bx				;restore cx
	
doNextChild:
	clc
	
doneWithChildren:
	mov	si, posVars.VCP_calcLineChild	;point to child again
	mov	posVars.VCP_childSpacing, bx
	.leave
	ret

skipToNextChild:
	clc
	.leave
	ret

DoSpacing	endp

		
		

COMMENT @----------------------------------------------------------------------

FUNCTION:	DoMove

DESCRIPTION:	Move a child the given amount

CALLED BY:	ObjCompProcessChildren -- callback routine

PASS:
	*ds:si - child
	*es:di - parent
	bp - X change
	ax - Y change

RETURN:
	carry cleared (we always do all the children)

DESTROYED:
	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

DoMove	proc	far
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

	mov	di, ds:[si]			;else point to instance data
	add	di, ds:[di].Vis_offset		; ds:si = VisInstance

	mov	cx, ds:[di].VI_bounds.R_left	;get left edge
	add	cx, bp				;add offset
	mov	dx, ds:[di].VI_bounds.R_top	;get top
	add	dx, ax				;add offset
	call	VisSendPositionAndInvalIfNeeded			;move the child
	clc
	ret

DoMove	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisCompSetGeometry -- MSG_VIS_COMP_SET_GEO_ATTRS for VisCompClass

DESCRIPTION:	Sets geometry and justification flags.

PASS:		*ds:si 	- instance data
		es     	- segment of VisCompClass
		di 	- MSG_VIS_COMP_SET_GEO_ATTRS

		cl	- geoAttrs to set
		ch	- geoDimensionAttrs to set
		dl	- geoAttrs to clear
		dh	- geoDimensionAttrs to clear
		
RETURN:		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       		Does geometry and justification flags at the same time.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 5/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@


VisCompSetGeometry	method	VisCompClass, MSG_VIS_COMP_SET_GEO_ATTRS
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	or	{word} ds:[di].VCI_geoAttrs, cx	;set bits
	not	dx
	and	{word} ds:[di].VCI_geoAttrs, dx	;clear bits
	Destroy	ax, cx, dx, bp
	ret
VisCompSetGeometry	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompGetGeometry -- 
		MSG_VIS_COMP_GET_GEO_ATTRS for VisCompClass

DESCRIPTION:	Gets the geometry and justification flags.

PASS:		*ds:si 	- instance data
		es     	- segment of VisCompClass
		di 	- MSG_VIS_COMP_GET_GEO_ATTRS

RETURN:		cl -- geometry attributes
		ch -- geometry dimension attributes
		ax, dx, bp -- destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 5/89		Initial version

------------------------------------------------------------------------------@


VisCompGetGeometry	method	VisCompClass, MSG_VIS_COMP_GET_GEO_ATTRS
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	mov	cx, {word} ds:[di].VCI_geoAttrs
	Destroy	ax, dx, bp
	ret
VisCompGetGeometry	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisCompGetCenter -- 
		MSG_VIS_GET_CENTER for VisCompClass

DESCRIPTION:	Returns the center of the object.

PASS:		*ds:si 	- instance data
		es     	- segment of VisCompClass

RETURN:		cx 	- minimum amount needed left of center
		dx	- minimum amount needed right of center
		ax 	- minimum amount needed above center
		bp      - minimum amount needed below center
		ds - updated to point at segment of same block as on entry

DESTROYED:	bx, si, di, es
		
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       	if not centering
	    call superclass (returns width/2,width/2,height/2,height/2)
	else
	    if vertical
	    	return (centerOffset+topMargin, secondWidth+bottomMargin,
			height/2, height/2)
	    else
	    	return (width/2, width/2, centerOffset+topMargin, 
			secondWidth+bottomMargin)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/15/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

VisCompGetCenter	method static VisCompClass, MSG_VIS_GET_CENTER
	uses	bx, di
	.enter

	;
	; New code to return zeroes if the object's size is negative.  This
	; is necessary due to ILLEGAL sizes stuffed in by OLWin's  on
	; startup.  We'll just pretend that negative values are preserved
	; for random initialization stuff.  Sigh.  -cbh 11/ 6/92
	;
	call	VisGetSize
	tst	cx
	js	5$
	tst	dx
5$:
	mov	cx, 0
	mov	dx, cx
	mov	ax, dx
	mov	bp, ax
	LONG	js	exit

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP or \
				      mask VCGA_CUSTOM_MANAGE_CHILDREN
	jnz	useNormalCenter			;wrapping, use normal center
						; (also if not managing! -cbh
						;  11/11/92)
	
	mov	al, ds:[di].VCI_geoDimensionAttrs
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	horizontal			;horizontal, branch
	and	al, mask VCGDA_WIDTH_JUSTIFICATION
	cmp	al, WJ_CENTER_CHILDREN_HORIZONTALLY shl \
				offset VCGDA_WIDTH_JUSTIFICATION
	jmp	short 10$
	
horizontal:
	and	al, mask VCGDA_HEIGHT_JUSTIFICATION
	cmp	al, HJ_CENTER_CHILDREN_VERTICALLY shl \
				offset VCGDA_HEIGHT_JUSTIFICATION
10$:
	je	useCalcedCenter			;centering, branch
	
useNormalCenter:
	call	VisGetCenter			;else do normal center
	jmp	short exit
	
useCalcedCenter:
	mov	ax, MSG_VIS_COMP_GET_MARGINS
	call	ObjCallInstanceNoLock		;dl <- top margin
	call	AdjustMarginsToOrientation	;get margins
	xchg	dx, bp				;top margin in dx,
						;  bottom margin in bp, to
						;  make code work. -cbh 11/ 4/92
	push	dx				;save top margin
	call	VisGetSize			;get size in cx, dx
	mov	ax, dx			        ;height in ax
						;width in cx
						;bottom margin in bp
	;
	; Get centerOffset and secondWidth via a method.  We will need to
	; be flexible here if the information hasn't been set up yet, and
	; return zeroes, because this message can be sent from DoDesiredResize,
	; long before the center is ready.
	;
	push	ax, cx, bp
	call	VisCompRestoreTempGeoData	;get temp data:
						;centerOffset in dx
	mov	di, bp				;second width in di
;EC <	cmp	dx, -1							>
;EC <	ERROR_E	UI_CANT_DO_CUSTOM_RECALC_SIZE_AND_DO_SPECIAL_JUSTIFICATION  >
;EC <	cmp	di, -1							    >
;EC <	ERROR_E	UI_CANT_DO_CUSTOM_RECALC_SIZE_AND_DO_SPECIAL_JUSTIFICATION  >
    	tst	dx
	jns	11$
	clr	dx
11$:
	tst	di
	jns	12$
	clr	di
12$:
	pop	ax, cx, bp
	
	push	dx				;save offset to center
	push	bp				;save bottom margin 
	push	di				;and second part after center
	
	mov	bp, ax				;height in ax and bp
	mov	dx, cx				;width in cx and dx
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jnz	vertical			;vertical, branch
	
;horizontal:
	shr	cx, 1				;halve the height
	sub	dx, cx				;right = width - left of center
	pop	ax				;restore second offset
	pop	bp				;restore bottom margin
	add	bp, ax				;add to second offset, in bp
	pop	ax				;restore center offset
	pop	bx				;restore top margin
	add	ax, bx				;add top margin to center offset
	jmp	short exit
	
vertical:
	shr	ax, 1				;halve the height
	sub	bp, ax				;bottom = height - top
	pop	dx				;restore second width
	pop	bx				;restore bottom margin
	add	dx, bx				;add bottom margin to 2nd width
	pop	cx				;restore center offset
	pop	bx				;restore top margin
	add	cx, bx				;add top margin to center offset
exit:
	.leave
	ret
VisCompGetCenter	endm





COMMENT @----------------------------------------------------------------------

METHOD:		VisCompGetMinSize -- 
		MSG_VIS_COMP_GET_MINIMUM_SIZE for VisCompClass

DESCRIPTION:	Returns minimum size for the composite.

PASS:		*ds:si 	- instance data
		es     	- segment of VisCompClass
		ax 	- MSG_VIS_COMP_GET_MINIMUM_SIZE

RETURN:		cx 	- minimum length
		dx	- minimum width
		ax, bp 	- destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 1/89	Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

VisCompGetMinSize	method	VisCompClass, MSG_VIS_COMP_GET_MINIMUM_SIZE
	clr	cx
	clr	dx
	Destroy	ax, bp
	ret
VisCompGetMinSize	endm



		


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompSaveTempGeoData -- 

DESCRIPTION:	Default routine for saving temporary data for the geometry
		manager.  This only handles the case of a generic VisComp.
		You must subclass this message to save/restore geometry data
		if your VisComp is not generic.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		cx	- lineWidth (or -1 if nothing)
		dx	- centerOffset (or -1 if nothing)
		bp 	- secondWidth (or -1 if nothing)		

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/16/91		Initial version

------------------------------------------------------------------------------@

VisCompSaveTempGeoData	proc	near
	uses	ax, bx
	.enter

	;
	; Create a ATTR_VIS_GEOMETRY_DATA with the appropriate arguments,
	; and save it.
	;
	push	cx
	mov	ax, ATTR_VIS_GEOMETRY_DATA or mask VDF_SAVE_TO_STATE
	mov	cx, size VarGeoData
	call	ObjVarAddData
	pop	cx
	mov	({VarGeoData} ds:[bx]).VGD_lineWidth, cx
	mov	({VarGeoData} ds:[bx]).VGD_centerOffset, dx
	mov	({VarGeoData} ds:[bx]).VGD_secondWidth, bp
	.leave
	ret
VisCompSaveTempGeoData	endp

		


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompRestoreTempGeoData -- 

DESCRIPTION:	Routine for saving restoring data for the geometry
		manager. 

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass

RETURN:		cx	- lineWidth (or -1 if nothing)
		dx	- centerOffset (or -1 if nothing)
		bp 	- secondWidth (or -1 if nothing)
		ax - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/16/91		Initial version

------------------------------------------------------------------------------@

VisCompRestoreTempGeoData	proc	near
EC <	mov	cx, -1				;assume not generic, can't  >
EC <	mov	dx, cx				;  handle here		    >
EC <	mov	bp, cx							    >

	mov	ax, ATTR_VIS_GEOMETRY_DATA
	call	ObjVarFindData
	jnc	done
	mov	cx, ds:[bx].VGD_lineWidth
	mov	dx, ds:[bx].VGD_centerOffset
	mov	bp, ds:[bx].VGD_secondWidth
done:	
	ret
VisCompRestoreTempGeoData	endp


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompAddRectToUpdateRegion -- 
		MSG_VIS_ADD_RECT_TO_UPDATE_REGION for OLCtrlClass

DESCRIPTION:	Notifies control that its bounds changed.  We will try to
		do just enough to get the old and new borders redrawn, if
		the composite doesn't draw between its children, by splitting
		the message into four separate messages to invalidate the top,
		left, bottom, and right margins of the composite.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_BOUNDS_CHANGED
		
		ss:bp	- Rectangle: old bounds
		cl	- VisAddRectParams

RETURN:		nothing
		ax, cx, dx, bp - destroyed

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/30/91		Initial version

------------------------------------------------------------------------------@

VisCompAddRectToUpdateRegion	method static	VisCompClass, \
				MSG_VIS_ADD_RECT_TO_UPDATE_REGION

	uses	bx, di, es			;to conform to static reqts
	.enter
	test	ss:[bp].VARP_flags, mask VARF_ONLY_REDRAW_MARGINS
	jz	callSuper		; not ourselves, don't split
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCI_geoAttrs, mask VCGA_ONLY_DRAWS_IN_MARGINS
	jnz	splitIntoFourParts	; if this is set, we can split.
	
callSuper:
	mov	di, segment VisCompClass ;send to superclass if we can't do this
	mov	es, di
	mov	di, offset VisCompClass
	CallSuper	MSG_VIS_ADD_RECT_TO_UPDATE_REGION
	jmp	short exit
	
splitIntoFourParts:
	;
	; Turn this flag off when passing ourselves this message again, so we 
	; won't infinitely split the data into four messages.
	;
	and	ss:[bp].VARP_flags, not mask VARF_ONLY_REDRAW_MARGINS
	
	push	es, bp			;we'll get the margins first.
	mov	ax, MSG_VIS_COMP_GET_MARGINS
	call	ObjCallInstanceNoLock
	mov	bx, bp
	pop	es, bp
	push	dx			;save margins
	push	cx
	push	bx
	;
	; Left margin area:  ax = left, bx = top, cx = left + lMargin, 
	; dx = bottom.  
	;
	mov	cx, ss:[bp].VARP_bounds.R_left	;cx <- left
	add	ax, cx				;ax <- left + leftMargin.
	xchg	ax, cx				;swap
	mov	bx, ss:[bp].VARP_bounds.R_top
	mov	dx, ss:[bp].VARP_bounds.R_bottom
	mov	di, {word} ss:[bp].VARP_flags
	call	VisInvalOldBounds
	;
	; Top margin area:  ax = left, bx = top, cx = right
	; dx = top + tMargin.
	;
	pop	dx				;restore topMargin
	add	dx, bx				;dx <- top + topMargin
	mov	cx, ss:[bp].VARP_bounds.R_right
	mov	di, {word} ss:[bp].VARP_flags
	call	VisInvalOldBounds
	;
	; Right margin area:  ax = right - rMargin, bx = top, 
	; cx = right, dx = bottom.
	;
	pop	ax				;restore rightMargin
	neg	ax
	add	ax, cx				;ax <- right - rMargin
	mov	dx, ss:[bp].VARP_bounds.R_bottom
	mov	di, {word} ss:[bp].VARP_flags
	call	VisInvalOldBounds
	;
	; Bottom margin area:  ax = left, bx = bottom - bMargin, cx = right,
	; dx = bottom.  
	;
	pop	bx				;restore bottomMargin
	neg 	bx
	add	bx, dx				;bx <- bottom - bottomMargin
	mov	ax, ss:[bp].VARP_bounds.R_left
	mov	di, {word} ss:[bp].VARP_flags
	call	VisInvalOldBounds
exit:
	.leave
	ret
VisCompAddRectToUpdateRegion	endm

VisUpdate ends

