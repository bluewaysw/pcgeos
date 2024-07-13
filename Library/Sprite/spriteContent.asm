COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		spriteContent.asm

AUTHOR:		Martin Turon, Nov 14, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/14/94   	Initial version


DESCRIPTION:
	Code for the global manager object of SpriteClass objects.
	Herein resides the core of the collision detection mechanism.	

	$Id: spriteContent.asm,v 1.1 98/07/06 19:04:30 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpriteContentTimerTick		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Each time the timer ticks, Tell everything to move itself

CALLED BY:	GLOBAL - MSG_TIMER_TICK

PASS:		*ds:si  = GameContent object
		ds:di 	= GameContent instance data
		cx:dx 	= tick count

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	6/24/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpriteContentTimerTick  method	dynamic	SpriteContentClass, 
					MSG_GAME_CONTENT_TIMER_TICK

	;
	; If we are minimized, don't do any work!
	;

		cmp	ds:[di].GCI_status, GS_MINIMIZED
		je	done

		mov	bp, ds:[di].GCI_gstate
		push	bp
		mov	di, offset SpriteContentClass
		call	ObjCallSuperNoLock
		pop	bp
	;
	; Move all child objects
	;

		mov	ax, MSG_SPRITE_UPDATE_POSITION
		call	VisSendToChildren	; tell all children to move it!
done:	
		ret

SpriteContentTimerTick		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpriteContentViewSizeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

CALLED BY:	GLOBAL

PASS:		*ds:si	= SpriteContentClass object
		ds:di	= SpriteContentClass instance data
		es 	= dgroup
		bp 	= handle of pane window
		cx 	= new window width, in document coords
		dx 	= new window height, in document coords

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VIEW_ORIGIN_X		= 256
VIEW_ORIGIN_Y		= 256

SpriteContentViewSizeChanged	method dynamic SpriteContentClass, 
					MSG_META_CONTENT_VIEW_SIZE_CHANGED

		.enter

		mov	di, ds:[di].GCI_gstate
		push	di
		mov	di, offset SpriteContentClass
		call	ObjCallSuperNoLock

		pop	di
		clr	ax, cx
		mov	dx, VIEW_ORIGIN_X
		mov	bx, VIEW_ORIGIN_Y	
		call	GrApplyTranslation

		.leave	
		ret

SpriteContentViewSizeChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpriteContentVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

CALLED BY:	GLOBAL
PASS:		*ds:si	= SpriteContentClass object
		ds:di	= SpriteContentClass instance data
		ds:bx	= SpriteContentClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cl	= DrawFlags
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	6/2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpriteContentVisDraw	method dynamic SpriteContentClass, 
					MSG_VIS_DRAW

		uses	cx, bp
		.enter
	;
	; If application just started, draw the title screen.
	; Otherwise, draw all the children.
	;
;		mov	bp, ds:[di].GCI_gstate
;		cmp	ds:[di].TCI_status, TGS_TITLE_SCREEN
;		jne	drawAll
;		call	SpriteContentDrawTitleScreen
;		jmp	exit
;drawAll:
		call	VisSendToChildren	; tell all children to move it!
exit:
		mov	di, offset SpriteContentClass
		.leave
		GOTO	ObjCallSuperNoLock

SpriteContentVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpriteProcessKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	For now, send to all children of the content.  Eventually, 
		have the content maintain some list of children to whom 
		keyboard events should be forwarded.

CALLED BY:	GLOBAL

PASS:		*ds:si	= SpriteProcessClass object
		ds:di	= SpriteProcessClass instance data
		ds:bx	= SpriteProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #

		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	6/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpriteContentKbdChar	method	SpriteContentClass, 
				MSG_META_KBD_CHAR
		.enter
		mov	ax, MSG_META_KBD_CHAR
		call	VisSendToChildren
		.leave
		ret

SpriteContentKbdChar	endm


;--------------------------------------------------------------------------
;		COLLISION DETECTION CODE
;--------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpriteContentUpdatePositionTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is sent by each sprite whenever their position
		has changed.  It logs the new position in the collision
		detection tables within the SpriteContentClass object.

CALLED BY:	MSG_SPRITE_CONTENT_UPDATE_POSITION_TABLE

PASS:		ds:di	 = SpriteContentClass instance data
		bp	 = detect id of object to update
		(cl, ch) = top-left table entry
		(dl, dh) = bottom-right table entry
		
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpriteContentUpdatePositionTable	method static SpriteContentClass, 
			 	MSG_SPRITE_CONTENT_UPDATE_POSITION_TABLE
		.enter

		xchg	ax, bp
		clr	ah			; clear flags (if any)
		xchg	ax, bp
	;
	; Dereference the chunk for each of the four tables, and update
	; the information at our offset (our detect id).
	;
		mov	si, ds:[di].SCI_leftColTable
		mov	si, ds:[si]
		mov	ds:[si+bp], cl

 		mov	si, ds:[di].SCI_topRowTable
		mov	si, ds:[si]
		mov	ds:[si+bp], ch

 		mov	si, ds:[di].SCI_rightColTable
		mov	si, ds:[si]
		mov	ds:[si+bp], dl

 		mov	si, ds:[di].SCI_bottomRowTable
		mov	si, ds:[si]
		mov	ds:[si+bp], dh

		.leave
		ret
SpriteContentUpdatePositionTable	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpriteContentDetectCollisions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes through the entire position table and checks for 
		any collisions that can be found.  A MSG_SPRITE_COLLISION
		is sent to the objects that request to be informed of 
		collisions.

CALLED BY:	MSG_SPRITE_CONTENT_DETECT_COLLISIONS
PASS:		*ds:si	= SpriteContentClass object
		ds:di	= SpriteContentClass instance data
		ds:bx	= SpriteContentClass object (same as *ds:si)
		es 	= segment of SpriteContentClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpriteContentDetectCollisions	method static SpriteContentClass, 
					MSG_SPRITE_CONTENT_DETECT_COLLISIONS
		.enter
	;
	; Setup register usage:
	; 	bx 	= current detect id we are working on
	; 	cx 	= number of sprite objects in detect table
	; 	ds:si 	= SpriteContentClass instance data
	; 
		mov	cx, ds:[di].SCI_tableSize
		segmov	es, ds, ax
		mov	si, di	      
		clr	bx
nextSprite:
	;
	; Check the left column value of the current sprite against all
	; remaining left column values.
	;
		mov	di, ds:[si].SCI_leftColTable
		mov	di, es:[di]
		add	di, bx
		mov	al, es:[di]
		call	SpriteContentQuickCollisionCheck
	;
	; Check the left  column value of the current sprite against all
	; remaining right column values.
	;
		mov	di, ds:[si].SCI_rightColTable
		mov	di, es:[di]
		add	di, bx
		push	di
		call	SpriteContentQuickCollisionCheck
		pop	di
	;
	; Check the right column value of the current sprite against all
	; remaining left column values if the current sprite is wide enough
	; to have different left and right column values.
	;
		mov	ah, al
		mov	al, es:[di]
		cmp	al, ah			; check if this object only
		je	next			; takes up one column...
		call	SpriteContentQuickCollisionCheck
	;
	; Check the right column value of the current sprite against all
	; remaining right column values.
	;
		mov	di, ds:[si].SCI_leftColTable
		mov	di, es:[di]
		add	di, bx
		call	SpriteContentQuickCollisionCheck
next:
		inc	bx
		dec	cx
		jg	nextSprite

		.leave
		ret
SpriteContentDetectCollisions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpriteContentQuickCollisionCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	INTERNAL - SpriteContentDetectCollisions
PASS:		ds:si	= SpriteContentClass instance data
		es:di	= offset into table to object we check collisions for
		bx	= detect id of object to check collisions for
		al	= value to search for
		cx	= length of table - detect id of other object
		
RETURN:		
DESTROYED:	ah, dx, di

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpriteContentQuickCollisionCheck	proc	near

		class	SpriteContentClass

		uses	cx		
		.enter

		inc	di			; skip first entry
myloop:	
		repne	scasb			; as fast as it gets...
		jcxz	done
	;
	; Okay, so we are in the same column as another object.
	; Now check if we are in the same row also.
	;
		push	di
		mov	dx, ds:[si].SCI_tableSize
		sub	dx, cx			; dx = detect id of object
						; whose column we are in
		mov	di, ds:[si].SCI_topRowTable
		mov	di, ds:[di]
		add	di, dx
		mov	ah, ds:[di]
 		cmp	al, ah
		je	sameSquare

		mov	di, ds:[si].SCI_bottomRowTable
		mov	di, ds:[di]
		add	di, dx
		mov	ah, ds:[di]
 		cmp	al, ah
		je	sameSquare
		pop	di
		
		jmp	myloop
done:	
		.leave
		ret

sameSquare:
	;
	; Well, now we need to scrutinize the collision a little bit.
	;	bx = detect id of caller
	;	dx = detect id of other object
	; Both are in the same region general region, but we need to do a
	; better (more time consuming) check to make sure.
	;
		call	SpriteContentDetectRadiusCollision
		jmp	done
SpriteContentQuickCollisionCheck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpriteContentDetectRadiusCollision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We lost a lot of info by the time we got this deep...
		Need terminology for both objects and:
		detectID1, dectectID2
		optr1, optr2

CALLED BY:	INTERNAL - SpriteContentQuickCollisionCheck

PASS:		ds:si	= SpriteContentClass instance data
		bx	= detect id of object to check collisions for
		dx	= detect id of other object in the same region

RETURN:		nothing
DESTROYED:	dx, di

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpriteContentDetectRadiusCollision	proc	near

		class	SpriteContentClass

callerChunk	local	lptr
otherChunk	local	lptr
		uses	ax, bx, cx, si
		.enter
	;
	; Pull the chunk handle for both objects in question out of the 
	; handle table.  Note that it is assumed that all sprite objects that
	; use collision detection are in the same resource as the
	; SpriteContentClass object that deals with them...
	;
		mov	di, ds:[si].SCI_handleTable
		mov	di, ds:[di]
		shl	bx			; convert bx to word offset
		mov	bx, ds:[di+bx]		; get chunk of object	
		mov	ss:[callerChunk], bx
		mov	bx, ds:[bx]			
		add	bx, ds:[bx].Vis_offset	; ds:bx = caller object

		shl	dx			; convert dx to word offset
		add	di, dx 
		mov	di, ds:[di]		; get chunk from handleTable
		mov	ss:[otherChunk], dx
		mov	di, ds:[di]		; dereference object
		add	di, ds:[di].Vis_offset	; ds:di = other object
		
	;
	; Now check if the two objects have detection circles that overlap:
	;   is the square of the distance between them minus the square of
	;   the radius of one of them less than the square of the radius of
	;   the other?  Or, as described with an expression:
	;   	(sqr(x1-x2) + sqr(y1-y2) - sqr(r2) < sqr(r1))
	;	
		mov	ax, ds:[bx].VI_bounds.R_left
		sub	ax, ds:[di].VI_bounds.R_left
		mul	ax
		mov_tr	cx, ax

		mov	ax, ds:[bx].VI_bounds.R_top
		sub	ax, ds:[di].VI_bounds.R_top
		mul	ax
		add	ax, cx
		sub	ax, ds:[di].SI_detectRadius
		cmp	ax, ds:[bx].SI_detectRadius
		jg	noCollision

	;
	; Well, for all intensive purposes, a collision has been detected.
	; Check if these two objects have the same SI_groupID.  If so, then
	; much time has been wasted, because there is no need to report
	; collisions between related objecrts.  Otherwise, send a message to
	; the object with the higher SI_groupID, as it is in charge. 
	;
		mov	cx, ds:[bx].SI_groupID
		cmp	cx, ds:[di].SI_groupID
		je	noCollision

		mov	cx, ds:[LMBH_handle]
		mov	dx, ss:[otherChunk]
		mov	si, ss:[callerChunk]
		jg	notifyOfCollision
		xchg	si, dx

notifyOfCollision:
		mov	ax, MSG_SPRITE_COLLISION
		call	ObjCallInstanceNoLock	
		
noCollision:	
		.leave
		ret
SpriteContentDetectRadiusCollision	endp




