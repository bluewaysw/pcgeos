COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	NTaker
MODULE:		Document
FILE:		documentText.asm

AUTHOR:		Andrew Wilson, Oct 28, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/28/92		Initial revision

DESCRIPTION:
	This file contains routines to implement the NTakerText object

	$Id: documentText.asm,v 1.1 97/04/04 16:17:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerTextRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalcs the size of the text object

CALLED BY:	GLOBAL
PASS:		*ds:si - NTakerText object
		cx, dx - RecalcSizeArgs
RETURN:		cx - width
		dx - height
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerTextRecalcSize	method	NTakerTextClass, MSG_VIS_RECALC_SIZE
	.enter
	mov	ax, DEFAULT_TEXT_MIN_WIDTH
	cmp	cx, ax				;Is the passed width too small?
	jae	5$				; no, branch
	mov	cx, ax				; else use the min width
5$:
	push	cx,bp				; save width
	mov	dx, -1				; Cache the computed height.
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT	;
	call	ObjCallInstanceNoLock		;
	pop	cx,bp				; restore width
	call	GetWidthAndHeightFromParentContent

	.leave
	ret
NTakerTextRecalcSize	endp

GetWidthAndHeightFromParentContent	proc	near
	class	VisContentClass

	call	VisFindParent			; get parent content 
EC <	tst	si							>
EC <	ERROR_Z	-1							>
EC <	cmp	bx, ds:[LMBH_handle]					>
EC <	ERROR_NZ	-1						>
	mov	di, ds:[si]			; point to instance
	add	di, ds:[di].VisContent_offset	; ds:[di] -- VisInstance
	cmp	dx, ds:[di].VCNI_viewHeight	; see if smaller than view ht
	jae	10$				; it's not, we're done
	mov	dx, ds:[di].VCNI_viewHeight	; else size as big as view
10$:
	test	cx, mask RSA_CHOOSE_OWN_SIZE	; see if desired width passed
	jz	exit				; no, branch
	mov	cx, ds:[di].VCNI_viewWidth	; else start with content width
exit:
	ret
GetWidthAndHeightFromParentContent	endp

NTakerTextHeightNotify	method	dynamic NTakerTextClass, 
			MSG_VIS_TEXT_HEIGHT_NOTIFY
	;
	; Special code for text in views.  If the currently stored text height
	; if smaller than the height of the view, we need only make sure that
	; the height passed in here is smaller than or equal to the current 
	; height (we keep the text object expanded to the height of the view
	; if it is smaller, so we can click anywhere in it.) If the currently
	; stored text height is bigger than the height of the view, the height
	; passed should match exactly.
	;
	; Changed 8/21/90 cbh:
	;	dx <- max (new height, view height)
	;	if dx <> ax, set new height to dx
	;
	mov_tr	ax, dx				;AX <- new height
	call	VisGetSize			;DX <- cur height
	call	EnsureHeightLargerThanView

	cmp	dx, ax				; matches current height?
	je	exit				; yes, nothing to do

	mov_tr	dx, ax				; DX <- new height	
	call	VisSetSize			;resize ourselves
	call	UpdateContentSize

exit:
	ret
NTakerTextHeightNotify	endm
EnsureHeightLargerThanView	proc	near
	class	VisContentClass
	push	si
	call	VisFindParent			; get parent content in same blk
	mov	di, ds:[si]			; point to instance
	pop	si
	add	di, ds:[di].Vis_offset		; ds:[di] -- VisInstance
	cmp	ax, ds:[di].VCNI_viewHeight	; make sure at least view height
	jae	10$				; 
	mov	ax, ds:[di].VCNI_viewHeight	;
10$:
	ret
EnsureHeightLargerThanView	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateContentSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the size of the content

CALLED BY:	GLOBAL
PASS:		dx - new height of content
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateContentSize	proc	near
	class	VisContentClass

	call	VisFindParent			;find content
	tst	bx
	jz	exit
EC <	cmp	bx, ds:[LMBH_handle]					>
EC <	ERROR_NZ	-1						>
	call	VisSetSize			;resize the parent
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	movdw	bxsi, ds:[di].VCNI_view
	tst	si				;no window, get out
	jz	exit
	clr	di				;don't sweat ds fix-up
	call	GenViewSetSimpleBounds
exit:
	ret
UpdateContentSize	endp


NTakerTextNavigate	method NTakerTextClass, MSG_SPEC_NAVIGATION_QUERY

	mov	bl, mask NCF_IS_FOCUSABLE ;indicate that node is focusable

	;call utility routine, passing flags to indicate that this is
	;a leaf node in visible tree, and whether or not this object can
	;get the focus. This routine will check the passed NavigationFlags
	;and decide what to respond.

	clr	di				;no generic part
	call	VisNavigateCommon
	ret
NTakerTextNavigate	endm





DocumentCode	ends

