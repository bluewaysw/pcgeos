COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Init
FILE:		mainInit.asm

AUTHOR:		Steve Scholl

ROUTINES:
	Name			Description
	----			-----------
	DrawOpenApplication	Do intialization for PC/GEOS write
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	2/9/92		Initial revision

DESCRIPTION:
		
	$Id: mainInit.asm,v 1.1 97/04/04 15:51:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MainInit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InstallTokens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Install document token and call super class to install
		application token

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DrawProcessClass

RETURN:		
		nothing
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InstallTokens	method dynamic DrawProcessClass, MSG_GEN_PROCESS_INSTALL_TOKEN
	.enter
	;
	; Call our superclass to install application icon
	;
	mov	di, offset DrawProcessClass
	call	ObjCallSuperNoLock

	mov	ax, ('D') or ('D' shl 8)	; ax:bx:si = token used for
	mov	bx, ('A') or ('T' shl 8)	;	datafile
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	TokenGetTokenInfo		; is it there yet?
	jnc	done				; yes, do nothing
	mov	cx, handle DatafileMonikerList	; cx:dx = OD of moniker list
	mov	dx, offset DatafileMonikerList
	clr	bp				; moniker list is in data
						;  resource and so is already
						;  relocated
	call	TokenDefineToken		; add icon to token database
done:

	Destroy ax,cx,dx,bp

	.leave
	ret
InstallTokens		endm

ifdef GPC_XXX  ; leave at 100% since text is rare and GrObj will default
	         ; text to Sans 14 on TV
DrawProcessOpenApplication	method dynamic	DrawProcessClass,
					MSG_GEN_PROCESS_OPEN_APPLICATION
	;
	; Call our superclass to get the ball rolling...
	;
	mov	di, offset DrawProcessClass
	call	ObjCallSuperNoLock
	;
	; set View to 125% if TV
	;
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	call	UserCallApplication
	and	ah, mask DT_DISP_ASPECT_RATIO
	cmp	ah, DAR_TV shl offset DT_DISP_ASPECT_RATIO
	jne	notTV
	GetResourceHandleNS	DrawViewControl, bx
	mov	si, offset DrawViewControl
	mov	dx, 125			; 125%
	mov	ax, MSG_GVC_SET_SCALE
	clr	di
	call	ObjMessage
notTV:
	ret
DrawProcessOpenApplication	endm
endif

MainInit	ends

