COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           spriteMain.asm

AUTHOR:         Martin Turon, Nov  8, 1994

ROUTINES:
	Name                    Description
	----                    -----------

	
REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	martin  11/8/94         Initial version


DESCRIPTION:
	
		

	$Id: spriteMain.asm,v 1.1 98/07/06 19:04:22 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @-------------------------------------------------------------------
		SpriteUpdatePosition
----------------------------------------------------------------------------

DESCRIPTION:    

CALLED BY:      GLOBAL - MSG_SPRITE_UPDATE_POSITION

PASS:           *ds:si  = SpriteClass object
		ds:di   = SpriteClass instance data
		ds:bx   = SpriteClass object (same as *ds:si)
		es      = dgroup
		ax      = message #
		bp      = GState

RETURN:         
DESTROYED:      

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	martin  6/12/92         Initial version

----------------------------------------------------------------------------@
SpriteUpdatePosition    method  dynamic SpriteClass, 
					MSG_SPRITE_UPDATE_POSITION
		.enter

		mov     ax, MSG_SPRITE_ERASE
		call    ObjCallInstanceNoLock

		mov     ax, MSG_SPRITE_MOVE
		call    ObjCallInstanceNoLock
;               jc      done            ; if carry, object no longer exists
					; (was destroyed during move)

		mov     ax, MSG_SPRITE_DRAW
		call    ObjCallInstanceNoLock
done:
		.leave
		ret

SpriteUpdatePosition    endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpriteMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       

CALLED BY:      GLOBAL - MSG_SPRITE_MOVE

PASS:           *ds:si  = SpriteClass object
		ds:di   = SpriteClass instance data
		ds:bx   = SpriteClass object (same as *ds:si)
		es      = segment of SpriteClass
		ax      = message #

RETURN:         
DESTROYED:      

SIDE EFFECTS:   
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	martin  11/8/94         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpriteMove      method dynamic SpriteClass, 
					MSG_SPRITE_MOVE
		.enter
	;
	; Update the current image pointer.
	;
		mov     ax, ds:[di].SI_currentImage
		inc     ax
		cmp     ax, ds:[di].SI_imageCount
		jl      updateImage
		clr     ax
updateImage:
		mov     ds:[di].SI_currentImage, ax

	;
	; Perform any necessary rotation...
	;
		mov     ax, ds:[di].SI_rotation
		add     ds:[di].SI_angle, ax

		test    ds:[di].SI_flags, mask MF_WRAPPING
		jnz     noWrap
	;
	; Update the X position with wrapping.
	;
		mov     ax, ds:[di].SI_XVelocity
		add     ax, ds:[di].VI_bounds.R_left
		rcr     ax, 1
		cbw     
		rcl     ax, 1                   ; 9  bit region = 1 shift
						; 10 bit region = 2 shifts
		mov     ds:[di].VI_bounds.R_left, ax
		mov_tr  cx, ax
	;
	; Update the Y position with wrapping.
	;
		mov     ax, ds:[di].SI_YVelocity
		add     ax, ds:[di].VI_bounds.R_top
		rcr     ax, 1
		cbw     
		rcl     ax, 1                   ; 9  bit region = 1 shift
						; 10 bit region = 2 shifts
		mov     ds:[di].VI_bounds.R_top, ax
		mov_tr  dx, ax
	
updateCollisionDetect:
		test    ds:[di].SI_flags, mask MF_DETECT_COLLISIONS
		jz      skip
	;
	; Update the collision detection mechanism with the new position
	;
		mov     ax, MSG_SPRITE_CONTENT_UPDATE_POSITION_TABLE
		call    VisCallParent
skip:
		.leave
		ret

noWrap:
		mov     ax, ds:[di].SI_XVelocity
		add     ds:[di].VI_bounds.R_left, ax
		mov     ax, ds:[di].SI_YVelocity
		add     ds:[di].VI_bounds.R_top, ax
		jmp     updateCollisionDetect

SpriteMove      endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpriteDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       

CALLED BY:      MSG_SPRITE_DRAW
PASS:           *ds:si  = SpriteClass object
		ds:di   = SpriteClass instance data
		ds:bx   = SpriteClass object (same as *ds:si)
		es      = segment of SpriteClass
		ax      = message #
		^hbp    = GState to draw to

RETURN:         
DESTROYED:      

SIDE EFFECTS:   
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	martin  2/1/95          Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpriteDraw      method dynamic SpriteClass, 
					MSG_SPRITE_DRAW
		.enter
	;
	; Put gstate in di, dereference the chunk of 
	; the current gstring into si, and load the gstring
	;
		xchg    di, bp
	;
	; macro GetCurrentImage(pself) = optr to gstring
	;
		mov     bx,   ds:[bp].SI_gstringArray
		add     bx,   ds:[bp].SI_currentImage
		movdw	bxsi, ds:[bx]

		mov     cl, GST_CHUNK
		call    GrLoadGString           ; ^hsi = GState of GString

		call    GrSaveState
		mov     ax, ds:[bp].SI_color
		call    GrSetLineColor          
		call    GrSetAreaColor          

		clr     cx, ax
		mov     dx, ds:[bp].VI_bounds.R_left
		mov     bx, ds:[bp].VI_bounds.R_top
		call    GrApplyTranslation
		mov     dx, ds:[bp].SI_angle
		call    GrApplyRotation

		clr     ax, bx, dx
		call    GrDrawGString
		call    GrRestoreState
		mov     dl, GSKT_LEAVE_DATA
		call    GrDestroyGString
		xchg    di, bp

		.leave
		ret
SpriteDraw      endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpriteErase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       

CALLED BY:      MSG_SPRITE_ERASE
PASS:           *ds:si  = SpriteClass object
		ds:di   = SpriteClass instance data
		ds:bx   = SpriteClass object (same as *ds:si)
		es      = segment of SpriteClass
		ax      = message #
		^hbp    = GState to draw to

RETURN:         
DESTROYED:      

SIDE EFFECTS:   
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	martin  2/1/95          Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpriteErase     method dynamic SpriteClass, 
					MSG_SPRITE_ERASE
		.enter
	;
	; Put gstate in di, dereference the chunk of 
	; the current gstring into si, and load the gstring
	;
		xchg    di, bp

; (old)		mov     bx, ds:[bp].SI_gstringArray
;		mov     bx, ds:[bx]
;		add     bx, ds:[bp].SI_currentImage
;		mov     si, ds:[bx]                     
;		mov     bx, ds:[LMBH_handle]    ; ^lbx:si = current GString
	;
	; macro GetCurrentImage(pself) = optr to gstring
	;
		mov     bx,   ds:[bp].SI_gstringArray
		add     bx,   ds:[bp].SI_currentImage
		movdw	bxsi, ds:[bx]

		mov     cl, GST_CHUNK
		call    GrLoadGString           ; ^hsi = GState of GString

		clr     dx
		call    GrGetGStringBounds
		push    ax, bx, cx, dx
		
		call    GrSaveState
		clr     cx, ax
		mov     dx, ds:[bp].VI_bounds.R_left
		mov     bx, ds:[bp].VI_bounds.R_top
		call    GrApplyTranslation
		mov     dx, ds:[bp].SI_angle
		call    GrApplyRotation
		mov     al, MM_CLEAR
		call    GrSetMixMode

		pop     ax, bx, cx, dx
		call    GrFillRect
		call    GrRestoreState
		mov     dl, GSKT_LEAVE_DATA
		call    GrDestroyGString
		xchg    di, bp

		.leave
		ret
SpriteErase     endm

