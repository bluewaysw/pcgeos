COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		objectInteractive.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			
	----			
INT GrObjCreateSpriteTransform	
INT GrObjDestroySpriteTransform 
INT GrObjCopyNormalToSprite	
INT GrObjCopySpriteToNormal	
INT GrObjPtrResizeCommon	
INT GrObjConvertPointToDelta	
INT GrObjDragMoveCommon		
INT GrObjDragResizeCommon	
INT GrObjDragRotateCommon	
INT GrObjStartCreateSetupRuler
    GrObjGenerateUndoResizeChain
    GrObjGenerateUndoCreateChain

METHOD HANDLERS:
	Name:		
	----	
	GrObjDrawSprite		
	GrObjUnDrawSprite	
	GrObjInvertGrObjSprite 	
	GrObjInvertGrObjNormalSprite
	GrObjActivateMove	
	GrObjActivateResize	
	GrObjActivateCreate	
	GrObjSendAnotherToolActivated
	GrObjReactivateCreate	
	GrObjActivateRotate	
	GrObjInitCreate	Instance
	GrObjJumpStartMove	
	GrObjJumpStartResize	
	GrObjJumpStartRotate	
	GrObjPtrMove		
	GrObjPtrResize		
	GrObjPtrCreateAbs	
	GrObjPtrRotate		
	GrObjEndMove		
	GrObjEndResize		
	GrObjEndCreateAbs	
	GrObjCompleteCreate	
	GrObjEndRotate		
	GrObjStartSelect	
	GrObjPtr		
	GrObjEndSelect		
	GrObjStartCreate
	GrObjMetaPtr
	GrObjGetPointerImage
	GrObjEndCreate


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
		

	$Id: grobjInteractive.asm,v 1.1 97/04/04 18:07:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjExtInteractiveCode	segment resource





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCreateSpriteTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate chunk to hold sprite transform information
		and initialize it from normal transform

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data

RETURN:		
		OT_spriteTransform - chunk handle
		all fields copied from normal transform
		ds - updated if block moved

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCreateSpriteTransform		proc	far
	uses	ax,cx,dx,di
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	;   Allocate chunk and store handle in spriteTransform
	;

	mov	cx,size ObjectTransform
	mov	al,mask OCF_DIRTY 
	call	LMemAlloc
	GrObjDeref	di,ds,si			;incase chunk moved
	mov	ds:[di].GOI_spriteTransform,ax

	call	GrObjCopyNormalToSprite

	.leave
	ret
GrObjCreateSpriteTransform		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDestroySpriteTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the sprite data chunk

CALLED BY:	INTERNAL
		GrObjEndMove

PASS:		
		*(ds:si) - instance data

RETURN:		
		GOI_spriteTransform = 0

DESTROYED:	
		nothing
	
PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDestroySpriteTransform		proc	far
	uses	ax,di
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	GrObjDeref	di,ds,si	
	clr	ax
	xchg	ax,ds:[di].GOI_spriteTransform
EC <	tst	ax						>
EC <	ERROR_Z	SPRITE_TRANSFORM_DOESNT_EXIST			>

	call	LMemFree

	.leave
	ret
GrObjDestroySpriteTransform		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCopyNormalToSprite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy normalTransform info to spriteTranform info

CALLED BY:	INTERNAL
		GrObjCreateSpriteTransform

PASS:		
		*(ds:si) - instance data
		OT_spriteTransform must have been allocated

RETURN:		
		normalTransform data in spriteTransform

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCopyNormalToSprite		proc	far
	uses	cx,si,di,es
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;   pt ds:si at normalTransform and
	;   es:di an spriteTransform
	;

	GrObjDeref	di,ds,si
	mov	si,di				;ptr to instance data
	mov	si,ds:[si].GOI_normalTransform	
	mov	di,ds:[di].GOI_spriteTransform

EC <	tst	si						>
EC <	ERROR_Z		NORMAL_TRANSFORM_DOESNT_EXIST		>

	mov	si, ds:[si]			;ptr to normal transform

EC <	tst	di						>
EC <	ERROR_Z		SPRITE_TRANSFORM_DOESNT_EXIST		>

	mov	di, ds:[di]			;ptr to spriteTransform


	segmov	es,ds,cx			;dest segment

	MoveConstantNumBytes	<size ObjectTransform>,cx

	.leave
	ret
GrObjCopyNormalToSprite		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCopySpriteToNormal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy spriteTranform info to normalTransform info 

CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - instance data
		OT_spriteTransform must have been allocated

RETURN:		
		spriteTransform data in normalTransform

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCopySpriteToNormal		proc	far
	uses	cx,si,di,es
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;   pt es:di at normalTransform and
	;   ds:si an spriteTransform
	;

	GrObjDeref	di,ds,si
	mov	si,di				;ptr to instance data
	mov	di,ds:[di].GOI_normalTransform	
	mov	di,ds:[di]			;ptr to normal transform
	mov	si,ds:[si].GOI_spriteTransform

EC <	tst	si						>
EC <	ERROR_Z		SPRITE_TRANSFORM_DOESNT_EXIST		>

	mov	si,ds:[si]			;ptr to spriteTransform
	segmov	es,ds,cx
	mov	cx,size ObjectTransform
	MoveBytes 	cx,cx

	.leave
	ret
GrObjCopySpriteToNormal		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawSprite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws object sprite 

PASS:		
		*(ds:si) - instance data of object
		dx - gstate or 0
		bp - GrObjFunctionsActive

	
		THIS IS A STATIC MESSAGE HANDLER, SO IT CAN'T COUNT
		ON ANY PARAMETERS EXCEPT *(ds:si) AND IT CAN'T
		DESTROY ANYTHING

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:

		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	public	GrObjDrawSprite
GrObjDrawSprite	method static GrObjClass, MSG_GO_DRAW_SPRITE
	uses	ax,cx,di

	.enter

EC <	call	ECGrObjCheckLMemObject		>

	GrObjDeref	di,ds,si

	;    If action is not happening then don't draw sprite
	;

	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	done

	;    If sprite is already drawn the don't draw it
	;

	test	ds:[di].GOI_tempState, mask GOTM_SPRITE_DRAWN
	jnz	done					

	;    Mark sprite as drawn
	;

	mov	cl, mask GOTM_SPRITE_DRAWN
	mov	ch, mask GOTM_SPRITE_DRAWN_HI_RES
	test	bp,mask GOFA_VIEW_ZOOMED
	jnz	hiRes

setBits:
	call	GrObjChangeTempStateBits

	mov	ax,MSG_GO_INVERT_GROBJ_SPRITE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

hiRes:
	ornf	cl,mask GOTM_SPRITE_DRAWN_HI_RES
	andnf	ch,not mask GOTM_SPRITE_DRAWN_HI_RES
	jmp	setBits

GrObjDrawSprite endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjUnDrawSprite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases the sprite

PASS:		
		*(ds:si) - instance data of object
		dx - gstate or 0

		THIS IS A STATIC MESSAGE HANDLER, SO IT CAN'T COUNT
		ON ANY PARAMETERS EXCEPT *(ds:si) AND IT CAN'T
		DESTROY ANYTHING
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	public	GrObjUnDrawSprite
GrObjUnDrawSprite method static GrObjClass, MSG_GO_UNDRAW_SPRITE
	uses	ax,cx,di
	.enter

EC <	call	ECGrObjCheckLMemObject		>

	GrObjDeref	di,ds,si

	;    If sprite isn't currently drawn then don't erase it
	;

	test	ds:[di].GOI_tempState, mask GOTM_SPRITE_DRAWN
	jz	done

	
	mov	ax,MSG_GO_INVERT_GROBJ_SPRITE
	call	ObjCallInstanceNoLock

	;    Mark sprite as not drawn
	;

	clr	cl
	mov	ch, mask GOTM_SPRITE_DRAWN or mask GOTM_SPRITE_DRAWN_HI_RES
	call	GrObjChangeTempStateBits

done:
	.leave
	ret


GrObjUnDrawSprite endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjActivateMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up object for move. Does not actually start move.
		Need to send a MSG_GO_DRAG_MOVE for that.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjActivateMove method dynamic GrObjClass, MSG_GO_ACTIVATE_MOVE
	uses	bp
	.enter

	call	GrObjCanMove?
	jnc	done

	mov	bp,GOANT_PRE_MOVE
	call	GrObjOptNotifyAction

	call	ObjMarkDirty

	ornf	ds:[di].GOI_actionModes, mask GOAM_MOVE or \
						mask GOAM_ACTION_ACTIVATED
done:
	.leave
	ret
GrObjActivateMove endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjActivateResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up object for resize. Does not actually start resize.
		Need to send a MSG_GO_DRAG_RESIZE for that.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjActivateResize method dynamic GrObjClass, MSG_GO_ACTIVATE_RESIZE
	uses	bp
	.enter

	call	GrObjCanResize?
	jnc	done

	mov	bp,GOANT_PRE_RESIZE
	call	GrObjOptNotifyAction

	call	ObjMarkDirty

	ornf	ds:[di].GOI_actionModes,mask GOAM_RESIZE or \
					mask GOAM_ACTION_ACTIVATED
done:
	.leave
	ret
GrObjActivateResize endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjActivateRotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up object for resize. Does not actually start resize.
		Need to send a MSG_GO_DRAG_RESIZE for that.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjActivateRotate method dynamic GrObjClass, MSG_GO_ACTIVATE_ROTATE
	uses	ax,cx,bp
	.enter

	call	GrObjCanRotate?
	jnc	done

	mov	bp,GOANT_PRE_ROTATE
	call	GrObjOptNotifyAction

	call	ObjMarkDirty

	ornf	ds:[di].GOI_actionModes,mask GOAM_ROTATE or \
					mask GOAM_ACTION_ACTIVATED

done:
	.leave
	ret
GrObjActivateRotate endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjReactivateCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return object in create mode to activate create mode
		


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjReactivateCreate	method dynamic GrObjClass, MSG_GO_REACTIVATE_CREATE
	.enter

	call	ObjMarkDirty

	clr	ds:[di].GOI_actionModes

	.leave
	ret
GrObjReactivateCreate		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjJumpStartMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Jump starts move by doing an activate,start and drag stuff

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		bp - GrObjFunctionsActive
		dx - gstate to draw through or 0

RETURN:		
		ax - MouseReturnFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjJumpStartMove	method dynamic GrObjClass, MSG_GO_JUMP_START_MOVE
	.enter

	;    Attempt to activate move, if it fails then punt
	;

	mov	ax,MSG_GO_ACTIVATE_MOVE
	call	ObjCallInstanceNoLock
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_ACTIVATED
	jz	notHandled

	;    Pretend we got start select
	;

	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_ACTIVATED
	ornf	ds:[di].GOI_actionModes, mask GOAM_ACTION_PENDING

	test	bp, mask GOFA_RULER_HAS_SEEN_EVENT
	jz	setReference

afterRuler:
	call	GrObjDragMoveCommon

	;   Draw sprite in initial position
	;

	call	MSG_GO_DRAW_SPRITE, GrObjClass	

	mov	ax, mask MRF_PROCESSED

done:
	.leave
	ret

notHandled:
	clr	ax
	jmp	done

setReference:

	;
	;	Get the center and set the reference
	;
	push	dx,bp				;gstate, GrObjFunctionsActive
	mov	dx, size PointDWFixed
	sub	sp, dx
	mov	bp, sp

	mov	ax, MSG_GO_GET_CENTER
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_RULER_SET_REFERENCE
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	GrObjMessageToRuler
	add	sp, dx
	pop	dx,bp				;gstate, GrObjFunctionsActive

	BitSet	bp, GOFA_RULER_HAS_SEEN_EVENT
	jmp	afterRuler
GrObjJumpStartMove		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjJumpStartResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Jump starts resize by doing an activate,start and drag resize

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		bp - GrObjFunctionsActive
		dx - gstate to draw through or 0


RETURN:		
		ax - MouseReturnFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjJumpStartResize	method dynamic GrObjClass, MSG_GO_JUMP_START_RESIZE
	uses	bp,dx
	.enter

	;    Attempt to activate resize, if it fails then punt
	;

	mov	ax,MSG_GO_ACTIVATE_RESIZE
	call	ObjCallInstanceNoLock
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_ACTIVATED
	jz	notHandled

	;    Pretend we got start select
	;

	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_ACTIVATED
	ornf	ds:[di].GOI_actionModes, mask GOAM_ACTION_PENDING

	;    Pretend we got a drag
	;

	call	GrObjDragResizeCommon

	;  Draw sprite in initial position
	;

	call	MSG_GO_DRAW_SPRITE, GrObjClass	

	mov	ax, mask MRF_PROCESSED

done:
	.leave
	ret

notHandled:
	clr	ax
	jmp	done

GrObjJumpStartResize		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjJumpStartRotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Jump starts rotate by doing an activate,start and drag stuff

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		bp - GrObjFunctionsActive
		cl - GrObjHandleSpecification
		dx - gstate to draw through or 0
	

RETURN:		
		ax - MouseReturnFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjJumpStartRotate	method dynamic GrObjClass, MSG_GO_JUMP_START_ROTATE
	.enter

	;    Attempt to activate rotate, if it fails then punt
	;

	mov	ax,MSG_GO_ACTIVATE_ROTATE
	call	ObjCallInstanceNoLock
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_ACTIVATED
	jz	notHandled

	;    Pretend we got start select
	;

	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_ACTIVATED
	ornf	ds:[di].GOI_actionModes, mask GOAM_ACTION_PENDING

	call	GrObjDragRotateCommon

	;   Draw sprite in initial position
	;

	call	MSG_GO_DRAW_SPRITE, GrObjClass	

	mov	ax, mask MRF_PROCESSED
	
done:
	.leave
	ret

notHandled:
	clr	ax
	jmp	done

GrObjJumpStartRotate		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBeginCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Basically puts object in create mode. It can now
		receive a start,ptr and end selects for use
		in creating itself

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
	
		ss:bp - GrObjMouseData

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object in create activate mode

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBeginCreate	method dynamic GrObjClass, MSG_GO_BEGIN_CREATE
	uses	cx,dx
	.enter

	call	ObjMarkDirty
	ornf	ds:[di].GOI_actionModes, mask GOAM_ACTION_ACTIVATED or \
						mask GOAM_CREATE

	;    Take the mouse grab away from the floater, use it
	;    to create ourselves.
	;

	mov	ax,MSG_GO_GRAB_MOUSE
	call	ObjCallInstanceNoLock

	;   The user is creating a new object so they must be done
	;   editing the current grab
	;

	mov	cl,DONT_SELECT_AFTER_EDIT
	mov	ax,MSG_GO_BECOME_UNEDITABLE
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToEdit

	;    The whole create operation will be undone by simply deleting
	;    so don't let anything be added to the undo chain between
	;    now and MSG_GO_END_CREATE
	;

	call	GrObjGlobalUndoIgnoreActions

	;    Have object initialize its basic instance data for interactive
	;    creating
	;

	mov	ax,MSG_GO_INIT_CREATE
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBeginCreate		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjStartCreateSetupRuler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the ruler for starting a create

CALLED BY:	INTERNAL
		GrObjJumpStartCreateAbs

PASS:		
		*ds:si - GrObj
		ss:bp - GrObjMouseData

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjStartCreateSetupRuler		proc	near
	uses	cx
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	mov	cx, mask VRCS_OVERRIDE or mask VRCS_SET_REFERENCE

	test	ss:[bp].GOMD_goFA, mask GOFA_SNAP_TO
	jz	setReference

	mov	cx, mask VRCS_OVERRIDE or mask VRCS_SET_REFERENCE or \
			VRCS_SNAP_TO_GRID_ABSOLUTE or VRCS_SNAP_TO_GUIDES
	call	GrObjRulePoint

done:
	.leave
	ret

setReference:
	mov	ax, MSG_VIS_RULER_SET_REFERENCE
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToRuler
	jmp	done
GrObjStartCreateSetupRuler		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDragMoveCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform common functionality for handling drag events
		when in move mode

CALLED BY:	INTERNAL
		GrObjJumpStartMove

PASS:		
		*(ds:si) - instance data
		bp - GrObjFunctionsActive
		dx - gstate to draw through or 0

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		mark block dirty
		clear handles
		set state to action happening
		set sprite draw modes

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE - MAY CAUSE OBJECT BLOCK TO MOVE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDragMoveCommon	proc near
	uses	ax,di,dx
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	call	GrObjCreateSpriteTransform

	mov	ax,MSG_GO_UNDRAW_HANDLES	
	call	ObjCallInstanceNoLock

	;   Change state to reflect that action is now happening
	;

	GrObjDeref	di,ds,si
	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_PENDING
	ornf	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING

	.leave
	ret

GrObjDragMoveCommon endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDragResizeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform common functionality for drag events when in
		resize mode
		
CALLED BY:	INTERNAL
		GrObjJumpStartResize

PASS:		
		*(ds:si) - instance data
		bp - GrObjFunctionsActive
		dx - gstate to draw through or 0

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		mark block dirty
		clear handles
		set state to action happening
		set sprite draw modes

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE - MAY CAUSE OBJECT BLOCK TO MOVE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDragResizeCommon proc near
	uses	ax,di,dx
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	call	GrObjCreateSpriteTransform

	;    Clear handles if they are currently drawn
	;	

	mov	ax,MSG_GO_UNDRAW_HANDLES		;clear handles
	call	ObjCallInstanceNoLock

	;    Change state to reflect that action is now happening
	;

	GrObjDeref	di,ds,si
	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_PENDING
	ornf	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING

	.leave
	ret

GrObjDragResizeCommon endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDragRotateCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform common functionality for handling drag events
		when in rotate mode

CALLED BY:	INTERNAL
		GrObjJumpStartRotate

PASS:		
		*(ds:si) - instance data
		bp - GrObjFunctionsActive
		dx - gstate to draw through or 0

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		mark block dirty
		clear handles
		set state to action happening
		set sprite draw modes

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE - MAY CAUSE OBJECT BLOCK TO MOVE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDragRotateCommon	proc near
	uses	ax,di,dx
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	call	GrObjCreateSpriteTransform

	;   Clear handles if they are currently drawn
	;

	mov	ax,MSG_GO_UNDRAW_HANDLES	
	call	ObjCallInstanceNoLock

	;   Change state to reflect that action is now happening
	;

	GrObjDeref	di,ds,si
	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_PENDING
	ornf	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING

	.leave
	ret

GrObjDragRotateCommon endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInitCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intialize objects instance data to a zero size object,
		with no rotation and flipping, at the point passed so
		that it can be interactively dragged open.
		
PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		ss:bp - PointDWFixed - location to start create from
RETURN:		
		nothing

DESTROYED:	
		WARNING: May cause block to move and/or chunk to move
		within block

PSEUDO CODE/STRATEGY:
		nothing
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInitCreate method dynamic GrObjClass, MSG_GO_INIT_CREATE
	uses	ax,cx,dx,bp
	.enter

	;    Get default attributes from body. Must do attributes
	;    before initializing basic data because the visible
	;    bounds of objects with line attributes are affected
	;    by the line width
	;

	mov	ax,MSG_GO_INIT_TO_DEFAULT_ATTRS
	call	ObjCallInstanceNoLock

	mov	bx,bp				;PointDWFixed stack frame

	sub	sp,size BasicInit
	mov	bp,sp

	;    Set center to passed PointDWFixed
	;

	mov	ax,ss:[bx].PDF_x.DWF_int.high
	mov	ss:[bp].BI_center.PDF_x.DWF_int.high,ax
	mov	ax,ss:[bx].PDF_x.DWF_int.low
	mov	ss:[bp].BI_center.PDF_x.DWF_int.low,ax
	mov	ax,ss:[bx].PDF_x.DWF_frac
	mov	ss:[bp].BI_center.PDF_x.DWF_frac,ax

	mov	ax,ss:[bx].PDF_y.DWF_int.high
	mov	ss:[bp].BI_center.PDF_y.DWF_int.high,ax
	mov	ax,ss:[bx].PDF_y.DWF_int.low
	mov	ss:[bp].BI_center.PDF_y.DWF_int.low,ax
	mov	ax,ss:[bx].PDF_y.DWF_frac
	mov	ss:[bp].BI_center.PDF_y.DWF_frac,ax

	;     Set GrObj dimensions at 0 by 0 for additive resize
	;     and 1 bx 1 for multiplicative resize. 0 by 0 is
	;     really the correct way but mult resize needs something
	;     to mult by
	;

	mov	bx,1
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags, mask GOAF_MULTIPLICATIVE_RESIZE
	jnz	setDimensions
	clr	bx
setDimensions:
	clr	ax
	mov	ss:[bp].BI_width.low,ax
	mov	ss:[bp].BI_height.low,ax
	mov	ss:[bp].BI_width.high,bx
	mov	ss:[bp].BI_height.high,bx

	push	ds,si
	segmov	ds,ss,si
	mov	si,bp
	add	si, offset BI_transform
	call	GrObjGlobalInitGrObjTransMatrix
	pop	ds,si

	;    Send method to initialize basic data
	;    and then clear stack frame
	;

	mov	ax,MSG_GO_INIT_BASIC_DATA
	call	ObjCallInstanceNoLock
	add	sp,size BasicInit



	.leave
	ret

GrObjInitCreate endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjPtrMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when a ptr event is received and the object is
		in move mode

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		ss:bp = GrObjMouseData - point is deltas to move object

RETURN:		
		ax - MouseReturnFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		erase current object
		set constrain mode
		move spritetransform data in relation to normal transform
		draw new sprite
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjPtrMove method dynamic GrObjClass, MSG_GO_PTR_MOVE
	uses	dx,bp
	.enter

	test	ds:[di].GOI_actionModes,mask GOAM_MOVE
	jz	notHandled
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	notHandled

	mov	dx,ss:[bp].GOMD_gstate
	call	MSG_GO_UNDRAW_SPRITE, GrObjClass	;clear old sprite

	CallMod	GrObjMoveSpriteRelative

	call	GrObjPtrRuleMove

	mov	dx,ss:[bp].GOMD_gstate
	mov	bp,ss:[bp].GOMD_goFA
	call	MSG_GO_DRAW_SPRITE,GrObjClass		;draw new sprite

	mov	ax,mask MRF_PROCESSED

done:
	.leave
	ret

notHandled:
	clr	ax
	jmp	done

GrObjPtrMove endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjPtrRuleMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the GrObj any additional amount needed if this
		move is being ruled.

CALLED BY:	GrObjPtrMove

PASS:		*(ds:si) - instance data
		ss:[bp]  - GrObjMouseData

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	14 jan 1992	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjPtrRuleMove		proc	near
	class	GrObjClass
	uses	ax,bx,cx,bp,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;
	;  If the ruler's already done its job, bail
	;
	test	ss:[bp].GOMD_goFA, mask GOFA_RULER_HAS_SEEN_EVENT
	jz	doRule

done:
	.leave
	ret

doRule:
	;	Set up the proper VisRulerConstrainStrategy in cx
	;	according to our GrObjFunctionsActive
	;
	mov	cx, mask VRCS_OVERRIDE
	test	ss:[bp].GOMD_goFA, mask GOFA_SNAP_TO
	jz	constrain
	ornf	cx, VRCS_SNAP_TO_GRID_RELATIVE
constrain:
	test	ss:[bp].GOMD_goFA, mask GOFA_CONSTRAIN
	jz	rulePoint
	ornf	cx, VRCS_CONSTRAIN_TO_HV_AXES
rulePoint:
	AccessSpriteTransformChunk di, ds, si

	mov	dx, bp					;ss:dx <- GOMD
	sub	sp, size PointDWFixed
	mov	bp, sp

	movpdf	ss:[bp], ds:[di].OT_center, ax

	CallMod	GrObjRulePoint

	;
	;  Calculate the additional amount we need to move to be ruled
	;
	subpdf	ss:[bp], ds:[di].OT_center, ax

	;
	;  Add the extra amount to the past deltas so that all the
	;  grobjs will preserve their relative positions

	mov	bx, dx					;ss:bx <- GOMD
	addpdf	ss:[bx].GOMD_point, ss:[bp], ax

	;
	;  Record that the event has been snapped
	;
	BitSet	ss:[bx].GOMD_goFA, GOFA_RULER_HAS_SEEN_EVENT

	CallMod	GrObjMoveSpriteRelativeToSprite
	add	sp, size PointDWFixed
	jmp	done
GrObjPtrRuleMove	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjPtrResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when a ptr event is received and the object is in
		resize mode

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp = GrObjResizeMouseData
			GORSMD_point - deltas to resize
			GORSMD_anchor - anchored handle
			GORSMD_grabbed - grabbed handle
			GORSMD_gstate - gstate to draw with
			GORSMD_goFA - GrObjFunctionsActive

RETURN:		
		ax - MouseReturnFlags		

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjPtrResize method dynamic GrObjClass, MSG_GO_PTR_RESIZE
	uses	cx,dx,bp
	.enter

	;   To simplify create, this message accepts both resize and
	;   create modes as valid. The action must be happening
	;   though for any modification to take place
	;

	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	notHandled

	mov	cl,ss:[bp].GORSMD_anchor
	mov	ch,ss:[bp].GORSMD_grabbed
	mov	dx,ss:[bp].GORSMD_gstate
	mov	ax, ss:[bp].GORSMD_goFA
	call	GrObjPtrResizeCommon

	mov	bp,ax					;GrObjFunctionsActive
	call	MSG_GO_DRAW_SPRITE, GrObjClass	

	mov	ax,mask MRF_PROCESSED

done:
	.leave
	ret

notHandled:
	clr	ax
	jmp	done

GrObjPtrResize endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertPointToDelta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the delta between the event point passed in the 
		GrObjMouseData structure at es:bx and normalTransform center
		of the passed object and return it in GrObjResizeMouseData structure
		at ss:bp

CALLED BY:	INTERNAL
		GrObjPtr
		GrObjEndCreate

PASS:		
		*(ds:si) - object instance data
		es:bx - GrObjMouseData 	
		ss:bp - GrObjMouseData

RETURN:		
		
		ss:bp - GrObjMouseData
		

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Subtract WW documentOffset from DWF event point
		Subtract WWF drawPt from DWF event point
		Slap that puppy in the stack frame

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertPointToDelta		proc	near
	uses	ax,cx,dx,si
	class	GrObjClass
	.enter

	AccessNormalTransformChunk	si,ds,si

	;   Calc x of delta first
	;   

	mov	ax,es:[bx].GOMD_point.PDF_x.DWF_int.high
	mov	cx,es:[bx].GOMD_point.PDF_x.DWF_int.low
	mov	dx,es:[bx].GOMD_point.PDF_x.DWF_frac

	sub	dx,ds:[si].OT_center.PDF_x.DWF_frac
	sbb	cx,ds:[si].OT_center.PDF_x.DWF_int.low
	sbb	ax,ds:[si].OT_center.PDF_x.DWF_int.high

	mov	ss:[bp].GORSMD_point.PDF_x.DWF_int.high,ax
	mov	ss:[bp].GORSMD_point.PDF_x.DWF_int.low,cx
	mov	ss:[bp].GORSMD_point.PDF_x.DWF_frac,dx

	;   Calc y of delta 
	;   

	mov	ax,es:[bx].GOMD_point.PDF_y.DWF_int.high
	mov	cx,es:[bx].GOMD_point.PDF_y.DWF_int.low
	mov	dx,es:[bx].GOMD_point.PDF_y.DWF_frac

	sub	dx,ds:[si].OT_center.PDF_y.DWF_frac
	sbb	cx,ds:[si].OT_center.PDF_y.DWF_int.low
	sbb	ax,ds:[si].OT_center.PDF_y.DWF_int.high

	mov	ss:[bp].GORSMD_point.PDF_y.DWF_int.high,ax
	mov	ss:[bp].GORSMD_point.PDF_y.DWF_int.low,cx
	mov	ss:[bp].GORSMD_point.PDF_y.DWF_frac,dx

	mov	ax,es:[bx].GOMD_gstate
	mov	ss:[bp].GORSMD_gstate,ax
	mov	ax,es:[bx].GOMD_goFA
	mov	ss:[bp].GORSMD_goFA,ax

	;    Set anchored handle based on GrObjFunctionsActive
	;

	mov	dl,HANDLE_LEFT_TOP				;assume
	test	ax,mask GOFA_FROM_CENTER
	jz	setAnchor
	mov	dl,HANDLE_MOVE

setAnchor:
	mov	ss:[bp].GORSMD_anchor,dl
	mov	ss:[bp].GORSMD_grabbed,HANDLE_RIGHT_BOTTOM

	.leave
	ret
GrObjConvertPointToDelta		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjPtrResizeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common functionality performed on MSG_PTR_RESIZE and
		MSG_PTR_CREATE_ABS

CALLED BY:	INTERNAL
		GrObjPtrResize
		GrObjPtrCreateAbs


PASS:		
		*(ds:si) - instance data
		ss:bp - PointDWFixed - point is deltas to resize object
					in document coords
			
		cl - GrObjHandleSpecification of anchored handle
		ch - GrObjHandleSpecification of grabbed handle

		ax - GrObjFunctionsActive
		dx - gstate

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjPtrResizeCommon		proc	near
	class	GrObjClass
	uses	ax,bx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	push	ax						;save GOFA

	;    Erase current sprite
	;

	call	MSG_GO_UNDRAW_SPRITE, GrObjClass

	;    Apply resize deltas to object and store the new
	;    information in the sprite transform

	CallMod	GrObjInteractiveResizeSpriteRelative

	;    Do the funky ruler hooey here
	;
	pop	ax
	call	GrObjPtrRuleResize

	;    Perform constrain if necessary
	;

	GrObjDeref	bx,ds,si
	test	ds:[bx].GOI_msgOptFlags, mask GOMOF_SPECIAL_RESIZE_CONSTRAIN
	jnz	doSpecialConstrain

done:
	.leave
	ret

doSpecialConstrain:
	mov	ax,MSG_GO_SPECIAL_RESIZE_CONSTRAIN
	call	ObjCallInstanceNoLock
	jmp	done

GrObjPtrResizeCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjPtrRuleResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common functionality performed on MSG_PTR_RESIZE and
		MSG_PTR_CREATE_ABS

CALLED BY:	INTERNAL
		GrObjPtrResize
		GrObjPtrCreateAbs
		GrObjEndResizeCommon

PASS:		
		*(ds:si) - instance data

		cl - GrObjHandleSpecification of anchored handle
		ch - GrObjHandleSpecification of grabbed handle

		ax - GrObjFunctionsActive

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjPtrRuleResize		proc	near
	class	GrObjClass
	uses	ax,bx,di

ruledPoint	local	PointDWFixed
unruledPoint	local	PointDWFixed

	.enter

EC <	call	ECGrObjCheckLMemObject				>

	push	cx					;save grabbed/anchor
	push	ax					;save GOFA

	;    set the reference point = anchor point
	;
	mov	bx, bp					;bx <- local ptr
	lea	bp, ss:ruledPoint			;bp <- ruledPoint

	;
	;	If not constraining, no need to set reference, vector
	;
	test	ax, mask GOFA_CONSTRAIN
	LONG_EC	jz	afterVector

	call	GrObjGetNormalDOCUMENTHandleCoords

	mov	ax, MSG_VIS_RULER_SET_REFERENCE
	mov	dx, size PointDWFixed
	mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	call	GrObjMessageToRuler

	;    see if we need to set the vector point, too
	;
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_actionModes, mask GOAM_RESIZE
	jz	afterVector

	xchg	cl, ch					;cl <- grabbed
							;ch <- anchor
	call	GrObjGetNormalDOCUMENTHandleCoords
	mov	ax, MSG_VIS_RULER_SET_VECTOR
	mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	call	GrObjMessageToRuler

	;
	;	Fill in the GrObj portion on the TMatrix
	;

	push	es, bp, cx

	sub	sp, size TransMatrix
	mov	bp, sp					;es:bp <- dest TMatrix

	push	si					;save grobj

	AccessSpriteTransformChunk si, ds, si
	add	si, offset OT_transform

	segmov	es, ss
	mov	di, bp					;es:di <- dest TMatrix
	mov	cx, (size TransMatrix - size PointDWFixed) / 2
	rep movsw

	;
	;	Clear out the PointDWFixed at the end of it
	;
	mov_tr	ax, cx					;ax <- 0
	mov	cx, size PointDWFixed / 2
	rep stosw

	pop	si					;*ds:si <- grobj
	mov	ax, MSG_VIS_RULER_SET_CONSTRAIN_TRANSFORM
	mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	call	GrObjMessageToRuler
	add	sp, size TransMatrix

	pop	es, bp, cx
	xchg	cl, ch					;cl <- anchor
							;ch <- grabbed
afterVector:
	xchg	cl, ch					;cl <- grabbed
							;ch <- anchor
	AccessSpriteTransformChunk di, ds, si

	;    ruledPoint <- location of grabbed handle after initial resize
	;

	call	GrObjGetSpriteDOCUMENTHandleCoords

	;    Copy the point into unruledPoint so we can track the difference
	;    between the ruled and unruled points
	;

	xchg	bx, bp					;bp <- local ptr
							;bx <- ruledPoint
	movpdf	ss:[unruledPoint], ss:[ruledPoint], ax

	;    let the ruler hooey with it
	;
	pop	ax					;ax <- GOFA
	mov	cx, mask VRCS_OVERRIDE
	test	ax, mask GOFA_SNAP_TO
	jz	checkConstrain

	ornf	cx, VRCS_SNAP_TO_GRID_ABSOLUTE or VRCS_SNAP_TO_GUIDES

checkConstrain:
	test	ax, mask GOFA_CONSTRAIN
	jz	snap

	;
	;	If this resize is part of a create, then we want to
	;	constrain to diagonals. Otherwise we want to conform to the
	;	object's original aspect ratio.
	;
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_actionModes, mask GOAM_RESIZE
	jz	create
	ornf	cx, VRCS_VECTOR_CONSTRAIN
	jmp	snap
create:
	ornf	cx, VRCS_CONSTRAIN_TO_DIAGONALS or VRCS_CONSTRAIN_TO_HV_AXES
snap:
	xchg	bx, bp					;bx <- local ptr
							;bp <- ruledPoint
	call	GrObjRulePoint
	xchg	bx, bp					;bp <- local ptr
							;bx <- ruledPoint
	pop	cx					;cl <- anchor
	jnc	done					;if no snap, no
							;more to do

	;    See how much the ruler moved our point in OBJECT coords
	;

	subpdf	ss:[ruledPoint], ss:[unruledPoint], ax

	;    Do the second (ruled) resize
	;

	push	bp					;save local ptr
	mov	bp, bx					;bp <- ruledPoint
	CallMod	GrObjInteractiveResizeSpriteRelativeToSprite
	pop	bp					;bp <- local ptr

done:
	.leave
	ret
GrObjPtrRuleResize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjPtrRotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when a ptr event is received and the object is in
		rotate mode

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - GrObjRotateMouseData 
			GORMD_degrees - delta to rotate
			GORMD_gstate - to draw with
			GORMD_anchor - GrObjHandleSpecification to rotate about

RETURN:		
		ax - MouseReturnFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		nothing
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjPtrRotate method dynamic GrObjClass, MSG_GO_PTR_ROTATE
	uses	dx,cx,bp
	.enter

	test	ds:[di].GOI_actionModes,mask GOAM_ROTATE
	jz	notHandled
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	notHandled

	mov	dx,ss:[bp].GORMD_gstate
	call	MSG_GO_UNDRAW_SPRITE, GrObjClass	

	call	GrObjPtrRuleRotate

	mov	cl,ss:[bp].GORMD_anchor
	CallMod	GrObjRotateSpriteRelative

	mov	bp,ss:[bp].GORMD_goFA
	call	MSG_GO_DRAW_SPRITE,GrObjClass	

	mov	ax,mask MRF_PROCESSED
done:
	.leave
	ret

notHandled:
	clr	ax
	jmp	done

GrObjPtrRotate endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjPtrRuleRotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GrObjPtrRotate

PASS:		ss:[bp] = GrObjRotateMouseData

RETURN:		if coonstrain bit is set, then GORMD_degrees is properly
		constrained

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	25 mar 1992	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjPtrRuleRotate		proc	near


	test	ss:[bp].GORMD_goFA, mask GOFA_CONSTRAIN
	jz	afterLeave

	uses	ax, bx, cx, dx
	.enter

	mov	dx, ss:[bp].GORMD_degrees.WWF_int
	mov	cx, ss:[bp].GORMD_degrees.WWF_frac

	;
	;	bx:ax <- ROTATE_CONSTRAIN_ANGLE
	;
	mov	bx, ROTATE_CONSTRAIN_ANGLE
	clr	ax

	;
	;	dx:cx <- degrees/45
	;
	call	GrSDivWWFixed

	RoundWWFixed	dx, cx			;dx <- int degrees/45

	mov_tr	ax, dx				;ax <- int degrees/45
	mul	bx				;ax <- total degrees
						;dx <- 0

	mov	ss:[bp].GORMD_degrees.WWF_int, ax
	mov	ss:[bp].GORMD_degrees.WWF_frac, dx
	
	.leave
afterLeave:
	ret
GrObjPtrRuleRotate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjEndMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when an end select event is received and the object is
		in move mode

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		ss:bp = GrObjMouseData - point is deltas to move 
					object in document coords

RETURN:		
		ax - MouseReturnFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjEndMove method dynamic GrObjClass, MSG_GO_END_MOVE
	uses	dx,bp
	.enter

	;    If not in interactive move then just ignore. If not
	;    happening then didn't get drag select, so reset to
	;    previous state
	;
	test	ds:[di].GOI_actionModes,mask GOAM_MOVE
	jz	notHandled
	test	ds:[di].GOI_actionModes,mask GOAM_ACTION_HAPPENING
	jz	reset

	;    Invalidate object at its original position
	;

	call	GrObjOptInvalidate

	;    Move object as if this was a pointer event. This
	;    gets us ruler constrain and such.
	;

	mov	ax,MSG_GO_PTR_MOVE
	call	ObjCallInstanceNoLock

	;   Erase final sprite drawn in PTR_MOVE
	;

	mov	dx,ss:[bp].GOMD_gstate
	call	MSG_GO_UNDRAW_SPRITE, GrObjClass

	call	GrObjGenerateUndoMoveChain

	;    Copy new position from sprite to normal
	;

	call	GrObjCopySpriteToNormal
	call	GrObjDestroySpriteTransform

	mov	bp,GOANT_MOVED
	mov	ax,MSG_GO_COMPLETE_TRANSLATE
	call	ObjCallInstanceNoLock

reset:
	call	ObjMarkDirty

	;   Set state instance back to normal, redraw handles if necessary
	;

	GrObjDeref	di,ds,si
	andnf	ds:[di].GOI_actionModes, not ( mask GOAM_MOVE or \
						mask GOAM_ACTION_ACTIVATED or \
						mask GOAM_ACTION_PENDING or \
						mask GOAM_ACTION_HAPPENING )


	mov	ax,mask MRF_PROCESSED

done:
	.leave
	ret

notHandled:
	clr	ax
	jmp	done

GrObjEndMove endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoResizeChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for a resize action

CALLED BY:	INTERNAL
		GrObjEndResize

PASS:		*ds:si - object

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateUndoResizeChain		proc	far
	uses	ax,cx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	cx,handle resizeString
	mov	dx,offset resizeString
	mov	ax,MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_CHAIN
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjGenerateUndoResizeChain		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjEndResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when an end select is received and the object is
		in resize mode

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp = GrObjResizeMouseData
			GORSMD_point - deltas to resize
			GORSMD_gstate - gstate to draw with
			GORSMD_goFA - GrObjFunctionsActive
			GORSMD_anchor - anchored handle

RETURN:		
		ax - MouseReturnFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		purposely leaves constrain as currently set so as to not 
		hose guy who releases the constrain key too quickly when 
		ending the resize

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjEndResize method dynamic GrObjClass, MSG_GO_END_RESIZE
	uses	cx,dx,bp
	.enter

	;    If not in interactive resize then just ignore. If not
	;    happening then didn't get drag select, so reset to
	;    previous state
	;

	test	ds:[di].GOI_actionModes,mask GOAM_RESIZE
	jz	notHandled
	test	ds:[di].GOI_actionModes,mask GOAM_ACTION_HAPPENING
	jz	reset

	;    Invalidate object at its original position
	;

	call	GrObjOptInvalidate

	;    Resize sprite data
	;

	mov	cl,ss:[bp].GORSMD_anchor
	mov	ch,ss:[bp].GORSMD_grabbed
	mov	dx,ss:[bp].GORSMD_gstate
	mov	ax,ss:[bp].GORSMD_goFA
	call	GrObjPtrResizeCommon

	call	GrObjGenerateUndoResizeChain

	;    Copy new size from sprite to normal
	;

	call	GrObjCopySpriteToNormal
	call	GrObjDestroySpriteTransform

	mov	bp,GOANT_RESIZED
	mov	ax,MSG_GO_COMPLETE_TRANSFORM
	call	ObjCallInstanceNoLock

reset:
	call	ObjMarkDirty

	;   Set state instance back to normal, redraw handles if necessary
	;

	GrObjDeref	di,ds,si
	andnf	ds:[di].GOI_actionModes, not ( mask GOAM_RESIZE or \
						mask GOAM_ACTION_ACTIVATED or \
						mask GOAM_ACTION_PENDING or \
						mask GOAM_ACTION_HAPPENING )

	mov	ax,mask MRF_PROCESSED

done:
	.leave
	ret


notHandled:
	clr	ax
	jmp	done

GrObjEndResize endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSuspendCompleteCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete interactive creation of object with body suspension

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSuspendCompleteCreate	method dynamic GrObjClass, 
				MSG_GO_SUSPEND_COMPLETE_CREATE
	.enter

	mov	ax, MSG_GB_IGNORE_UNDO_ACTIONS_AND_SUSPEND
	clr	di
	call	GrObjMessageToBody

	mov	ax, MSG_GO_COMPLETE_CREATE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GB_UNSUSPEND_AND_ACCEPT_UNDO_ACTIONS
	clr	di
	call	GrObjMessageToBody

	.leave
	ret
GrObjSuspendCompleteCreate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCompleteCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete interactive creation of object.
		Upon handling this message an object is expected to.
			Calculate its parent dimensions.
			Send notify grobj valid to itself.
			Draw itself to the screen
			Notify head of completed create
			Send action notification
			*Become selected or editable

		*The default handler won't do this. Each object
		should subclass and make its own decision.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCompleteCreate	method dynamic GrObjClass, 
						MSG_GO_COMPLETE_CREATE
	uses	cx,bp
	.enter

	;    When creating mulitple objects with the same tool
	;    the previous objects would not get deselected unless
	;    GrObjRemoveGrObjsFromSelectionList is called here
	;

	call	GrObjRemoveGrObjsFromSelectionList

	;   Calculate new document dimensions data based on
	;   the new normalTransform
	;

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	;    Notify ourselves that we are ready for action, because
	;    our normalTransform data is complete and we have attributes.
	;    What more could an object want?
	;

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	call	ObjCallInstanceNoLock

	;    We now are truly no longer in create mode
	;

	call	ObjMarkDirty	
	GrObjDeref	di,ds,si
	BitClr	ds:[di].GOI_actionModes,GOAM_CREATE

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GB_DRAW_GROBJ
	call	GrObjMessageToBody

	mov	ax,MSG_GH_FLOATER_FINISHED_CREATE
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToHead

	mov	bp, GOANT_CREATED
	call	GrObjOptNotifyAction

	.leave
	ret
GrObjCompleteCreate		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjEndRotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when an end select event is received and the object
		is in rotate mode

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		ss:bp - GrObjRotateMouseData - degrees are delta

RETURN:		
		ax - MouseReturnFlags
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		nothing


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjEndRotate method dynamic GrObjClass, MSG_GO_END_ROTATE
	uses	ax,cx,dx,bp
	.enter

	;    If not in interactive rotate then just ignore. If not
	;    happening then didn't get drag select, so reset to
	;    previous state
	;

	test	ds:[di].GOI_actionModes,mask GOAM_ROTATE
	jz	notHandled
	test	ds:[di].GOI_actionModes,mask GOAM_ACTION_HAPPENING
	jz	reset

	;    Invalidate object at its original position
	;

	call	GrObjOptInvalidate

	;    Rotate object as if this was a pointer event. This
	;    gets us ruler constrain and such.
	;

	mov	ax,MSG_GO_PTR_ROTATE
	call	ObjCallInstanceNoLock

	;   Erase final sprite drawn in PTR_ROTATE
	;

	mov	dx,ss:[bp].GORMD_gstate
	call	MSG_GO_UNDRAW_SPRITE, GrObjClass

	call	GrObjGenerateUndoRotateChain

	;    Copy new object info from sprite to normal
	;    and destroy sprite data chunk
	;  

	call	GrObjCopySpriteToNormal
	call	GrObjDestroySpriteTransform

	mov	bp,GOANT_ROTATED
	mov	ax,MSG_GO_COMPLETE_TRANSFORM
	call	ObjCallInstanceNoLock

reset:
	call	ObjMarkDirty

	;   Set state instance back to normal, redraw handles if necessary
	;   and make sure object stays on document
	;

	GrObjDeref	di,ds,si
	andnf	ds:[di].GOI_actionModes, not ( mask GOAM_ROTATE or \
						mask GOAM_ACTION_ACTIVATED or \
						mask GOAM_ACTION_PENDING or \
						mask GOAM_ACTION_HAPPENING )
	mov	ax,mask MRF_PROCESSED

done:
	.leave
	ret

notHandled:
	clr	ax
	jmp	done


GrObjEndRotate endm










COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCompleteTranslate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Object sends this message to itself to complete
	a move or other translation.
	Object needs to adjust its position to make sure 
	it is on the document, invalidate itself and redraw 
	handles if necessary. Then send out MSG_GO_ACTION_NOTIFY 
	to themselves.
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		bp - GrObjActionNotificationType
RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCompleteTranslate	method dynamic GrObjClass, MSG_GO_COMPLETE_TRANSLATE
	uses	ax
	.enter

	call	GrObjEndGeometryCommon

	call	GrObjOptNotifyAction

	.leave
	ret
GrObjCompleteTranslate		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate floater into document.

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		ss:bp - GrObjMouseData

RETURN:		
		ax - MouseReturnFlags
		if MRF_SET_POINTER_IMAGE
			cx,dx - optr of pointer image
		else
			cx,dx - destoryed

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjStartSelect method dynamic GrObjClass, MSG_GO_LARGE_START_SELECT
	.enter

	;    We want to interact with this mouse event but we (the grobject)
	;    don't actually want the target or focus, so tell the body
	;    to grab them. 
	;

	mov	ax,MSG_GB_GRAB_TARGET_FOCUS
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER
	jz	document


	call	GrObjFloaterStartSelect

done:

	.leave
	ret

notHandled:
	clr	ax
	jmp	done


document:
	;    An object in the document has received a start select.
	;    This default handler only provides create functionality
	;

	test	ds:[di].GOI_actionModes,mask GOAM_CREATE
	jz	notHandled

	call	GrObjStartSelectCreate
	jmp	done


GrObjStartSelect		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjFloaterStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when object is floater and it received a start
		select.
		Check for handle being hit and deal with it, otherwise
		start interactive object create.


CALLED BY:	INTERNAL
		GrObjStartSelect

PASS:		*ds:si - floater
		ss:bp - GrObjMouseData

RETURN:		
		ax - MouseReturnFlags
		^lcx:dx - optr of mouse image if MRF_SET_POINTER_IMAGE
				
DESTROYED:	
		cx,dx - if not returned

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjFloaterStartSelect		proc	near
	class	GrObjClass
	uses	bx,di,si
	.enter

EC <	call	ECGrObjCheckLMemObject	>

	mov	al,mask PM_HANDLES_RESIZE
	call	PointerTryHandleHit
	jc	processed

	;    Didn't hit a handle so create a new object.
	;   

	mov	cx,ds:[LMBH_handle]			;floater handle
	mov	dx,si					;floater chunk
	mov	ax,MSG_GB_ADD_DUPLICATE_FLOATER
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	call	GrObjStartCreateSetupRuler

	mov	bx,cx					;new object handle
	mov	si,dx					;new object chunk
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_BEGIN_CREATE
	call	ObjMessage
	
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_GO_LARGE_START_SELECT
	call	ObjMessage

done:
	.leave
	ret

processed:
	mov	ax,mask MRF_PROCESSED
	jmp	done

GrObjFloaterStartSelect		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjStartSelectCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a MSG_GO_LARGE_START_SELECT while in
		create mode. Set up instance data from drawing 
		sprite while dragging open object.

CALLED BY:	INTERNAL
		GrObjStartSelect

PASS:		
		*ds:si - grobject
		ss:bp - GrObjMouseData

RETURN:		
		ax - MouseReturnFlags
		if MRF_SET_POINTER_IMAGE
			cx:dx - optr of pointer image
		else
			cx,dx - destoryed

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			action is pending

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjStartSelectCreate		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;    If action isn't pending then never received BEGIN_CREATE
	;    so ignore message

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_actionModes,mask GOAM_ACTION_ACTIVATED
	jz	notHandled


	BitClr	ds:[di].GOI_actionModes, GOAM_ACTION_ACTIVATED
	BitSet	ds:[di].GOI_actionModes, GOAM_ACTION_PENDING

	;    Create sprite transform so we can draw sprite
	;    when we receive a ptr event
	;

	call	GrObjCreateSpriteTransform

	mov	ax,MSG_GO_GET_POINTER_IMAGE
	call	ObjCallInstanceNoLock
	ornf	ax,mask MRF_PROCESSED

done:
	.leave
	ret

notHandled:
	clr	ax
	jmp	done

GrObjStartSelectCreate		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle pointer events. This default handler provides
		only resize create functionality.

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - GrObjMouseData

RETURN:		
		ax - MouseReturnFlags
		if MRF_SET_POINT_IMAGE
			cx:dx - optr of pointer image
		else
			cx,dx - destroyed

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjPtr	method dynamic GrObjClass, MSG_GO_LARGE_PTR,
						MSG_GO_LARGE_DRAG_SELECT
	.enter

	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER
	jz	document

	call	GrObjFloaterPtr

	mov	ax,MSG_GO_GET_POINTER_IMAGE
	call	ObjCallInstanceNoLock
	ornf	ax,mask MRF_PROCESSED

done:
	.leave
	ret

document:
	;    Object in document has received ptr event. The default
	;    handler provides no editing. It just provides
	;    resize create functionality.
	;

	test	ds:[di].GOI_actionModes, mask GOAM_CREATE
	jz	notHandled

	cmp	ax,MSG_GO_LARGE_DRAG_SELECT
	je	drag

doPtrCreate:
	call	GrObjPtrCreate
	jmp	done

notHandled:
	clr	ax
	jmp	done

drag:
	BitClr	ds:[di].GOI_actionModes, GOAM_ACTION_PENDING
	BitSet	ds:[di].GOI_actionModes, GOAM_ACTION_HAPPENING
	jmp	doPtrCreate

GrObjPtr	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjFloaterPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The floater tool received a PTR event. Handle move/resize
		etc that we may be in the middle of.

CALLED BY:	INTERNAL
		GrObjPtr

PASS:		*ds:si - grobject
		ss:bp - GrObjMouseData

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			grobj will be in create mode

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjFloaterPtr		proc	near
	class	GrObjClass
	uses	di
	.enter

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_actionModes, mask GOAM_CREATE
	jz	otherMode


done:
	.leave
	ret

otherMode:

	;    On drag event switch action from pending to happening
	;    The prevents an accidental click from wasting a lot of
	;    time moving many selected objects nowhere
	;

	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_PENDING
	ornf	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING

	test	ds:[di].GOI_actionModes, mask GOAM_MOVE
	jz	tryResize
	mov	ax,MSG_GO_PTR_MOVE
	call	PointerSendMouseDelta
	jmp	done

tryResize:
	test	ds:[di].GOI_actionModes, mask GOAM_RESIZE
	jz	tryRotate
	mov	ax,MSG_GO_PTR_RESIZE
	call	PointerSendResizeDelta
	jmp	done

tryRotate:
	test	ds:[di].GOI_actionModes, mask GOAM_ROTATE
	jz	done
	mov	ax,MSG_GO_PTR_ROTATE
	call	PointerSendRotateDelta
	jmp	done

GrObjFloaterPtr		endp
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjPtrCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle PTR event for object in create mode.
		Treats PTR as resize for creation

CALLED BY:	INTERNAL
		GrObjPtr
		GrObjEndSelect

PASS:		
		*ds:si - object
		ss:bp - GrObjMouseData

RETURN:		
		ax - MouseReturnFlags
		if MRF_SET_POINTER_IMAGE
			cx:dx - optr of pointer image
		else
			cx,dx - DESTROYED

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjPtrCreate		proc	far
	class	GrObjClass
	uses	bx,bp,es
	.enter

EC <	call	ECGrObjCheckLMemObject		>

	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	notHandled

	;    Point es:bx at original stack frame, create a
	;    new stack frame to hold mouse deltas and calc those
	;    deltas
	;
	
	segmov	es,ss,bx
	mov	bx,bp					;orig stack frame
	sub	sp,size GrObjResizeMouseData
	mov	bp,sp
	call	GrObjConvertPointToDelta

	mov	ax,MSG_GO_PTR_RESIZE
	call	ObjCallInstanceNoLock

	add	sp,size GrObjResizeMouseData

	mov	ax,MSG_GO_GET_POINTER_IMAGE
	call	ObjCallInstanceNoLock
	ornf	ax,mask MRF_PROCESSED

done:
	.leave
	ret

notHandled:
	clr	ax
	jmp	done

GrObjPtrCreate		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle end select

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)

		ss:bp - GrObjMouseData

		es - segment of GrObjClass

RETURN:		
		ax - MouseReturnFlags
		if MRF_SET_POINTER_IMAGE
			cx:dx - optr of pointer image
		else
			cx,dx - DESTROYED


DESTROYED:	
		nothing
		

PSEUDO CODE/STRATEGY:
		none
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjEndSelect 	method dynamic GrObjClass, MSG_GO_LARGE_END_SELECT
	.enter

	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER
	jz	document

	call	GrObjFloaterEndSelect

mouseImage:
	mov	ax,MSG_GO_GET_POINTER_IMAGE
	call	ObjCallInstanceNoLock

release:
	push	ax				;MouseReturnFlags
	mov	ax,MSG_GO_RELEASE_MOUSE
	call	ObjCallInstanceNoLock
	pop	ax				;MouseReturnFlags

	.leave
	ret

document:
	test	ds:[di].GOI_actionModes, mask GOAM_CREATE
	jz	notHandled

	call	GrObjPtrCreate

	push	cx				;mouse image handle
	mov	cx,mask ECPF_ADJUSTED_CREATE
	test	ss:[bp].GOMD_uiFA, mask UIFA_ADJUST
	jnz	endCreate
	clr	cx
endCreate:
	mov	ax,MSG_GO_END_CREATE
	call	ObjCallInstanceNoLock

	;    If MSG_GO_END_CREATE destroyed the object then
	;    treat the click as a select click.
	;
	
	test	cx,mask ECRF_DESTROYED
	pop	cx				;mouse image handle
	jz	mouseImage			;jmp if not destroyed

	;    Suspend the body so that all the objects that are becoming
	;    selected and unselected won't try and update the controllers
	;    independently
	;

	mov	ax, MSG_GB_IGNORE_UNDO_ACTIONS_AND_SUSPEND
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	test	ss:[bp].GOMD_goFA,mask GOFA_ADJUST
	jnz	adjustSelect

	call	GrObjRemoveGrObjsFromSelectionList
	mov	ax,MSG_GO_BECOME_SELECTED
	mov	dl, HUM_NOW
sendToChild:
	call	GrObjMessageToChildUnderPoint

	mov	ax, MSG_GB_UNSUSPEND_AND_ACCEPT_UNDO_ACTIONS
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>
	
	jmp	mouseImage

adjustSelect:
	mov	ax,MSG_GO_TOGGLE_SELECTION
	jmp	sendToChild

notHandled:
	clr	ax
	jmp	release

GrObjEndSelect	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMessageToChildUnderPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill priority list with children that could be selected
		by the passed point and send a message to the first child
		of priority list
		

CALLED BY:	INTERNAL
		GrObjEndSelect

PASS:		
		*(ds:si) - pointer instance data
		ss:bp - PointDWFixed
		ax - message
		cx,dx - other message data

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMessageToChildUnderPoint		proc	near
	uses	bx,di
	.enter

EC <	call	ECGrObjCheckLMemObject	>

	push	ax,cx,dx				;message and data
	mov	ax, MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION
	mov	cx, MAX_PRIORITY_LIST_ELEMENTS
	mov	dl, mask PLI_DONT_INSERT_OBJECTS_WITH_SELECTION_LOCK or \
			mask PLI_ONLY_INSERT_HIGH

	call	GrObjGlobalInitAndFillPriorityList

	;    If no child under point then bail
	;

	mov	ax,MSG_GB_PRIORITY_LIST_GET_NUM_ELEMENTS
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>
	jcxz	popDone

	;    Send message to first child
	;

	clr	cx				;first child
	mov	ax,MSG_GB_PRIORITY_LIST_GET_ELEMENT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>
	mov	bx,cx				;first child handle
	mov	di,dx				;first child chunk
	pop	ax,cx,dx			;message and data
	push	si				;object chunk
	mov	si,di				;first child chunk
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	pop	si				;object chunk

done:
	.leave
	ret

popDone:
	pop	ax,cx,dx
	jmp	done

GrObjMessageToChildUnderPoint		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjFloaterEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The floater received an end select. Complete any move/resize
		etc that we might be in the middle of

CALLED BY:	INTERNAL
		GrObjEndSelect

PASS:		*ds:si - grobject
		ss:bp - GrObjMouseData

RETURN:		
		nothing

DESTROYED:	
		see RETURNED

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			grobj will be in create mode

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjFloaterEndSelect		proc	near
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_actionModes, mask GOAM_CREATE
	jz	otherMode

done:
	.leave
	ret

otherMode:
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	done


	test	ds:[di].GOI_actionModes, mask GOAM_MOVE
	jz	tryResize

	;   The suspend gives as undo chain for undoing the move of 
	;   potentially many objects and it fixes a bug when moving a 
	;   large number of flow regions in geowrite.
	;

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_META_SUSPEND
	call	GrObjMessageToBody
	mov	ax,MSG_GO_END_MOVE
	call	PointerSendMouseDelta
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_META_UNSUSPEND
	call	GrObjMessageToBody
	jmp	finishUp

tryResize:
	test	ds:[di].GOI_actionModes, mask GOAM_RESIZE
	jz	tryRotate
	mov	ax,MSG_GO_END_RESIZE
	call	PointerSendResizeDelta

finishUp:
	call	PointerEndCleanUp
	jmp	done

tryRotate:
	test	ds:[di].GOI_actionModes, mask GOAM_ROTATE
	jz	done
	mov	ax,MSG_GO_END_ROTATE
	call	PointerSendRotateDelta
	jmp	finishUp

GrObjFloaterEndSelect		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAdjustCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish creating the object given whatever data
		is currently available. Use the sprite data
		as the desired size and position of this beast.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAdjustCreate	method dynamic GrObjClass, MSG_GO_ADJUST_CREATE
	uses	cx
	.enter

	mov	cl, SDM_0
	mov	ax, MSG_GO_SET_AREA_MASK
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjAdjustCreate		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjEndCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish creating the object given whatever data
		is currently available. Use the sprite data
		as the desired size and position of this beast.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx - EndCreatePassFlags

RETURN:		
		cx - EndCreateReturnFlags
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjEndCreate	method dynamic GrObjClass, MSG_GO_END_CREATE
	uses	dx
	.enter

	test	ds:[di].GOI_optFlags,mask GOOF_FLOATER
	jnz	error

	test	ds:[di].GOI_actionModes, mask GOAM_CREATE
	jz	error

	test	ds:[di].GOI_actionModes,mask GOAM_ACTION_HAPPENING
	jz	dontCreate

	;    Erase any existing sprite
	;

	clr	dx					;no gstate
	call	MSG_GO_UNDRAW_SPRITE, GrObjClass

	;    If the object is really small then we assume it was
	;    an accident.
	;

	call	GrObjCheckForTinySprite
	jc	dontCreate

	;    Copy new object data from sprite to normal then
	;    eat the evidence.
	;

	call	GrObjCopySpriteToNormal
	call	GrObjDestroySpriteTransform

	;    Clean up mode bits
	;

	GrObjDeref	di,ds,si
	andnf	ds:[di].GOI_actionModes, not (	mask GOAM_ACTION_PENDING or \
						mask GOAM_ACTION_HAPPENING or \
						mask GOAM_ACTION_ACTIVATED )

	test	cx,mask ECPF_ADJUSTED_CREATE
	jz	complete

	mov	ax,MSG_GO_ADJUST_CREATE
	call	ObjCallInstanceNoLock

complete:
	;    Notify ourselves that we have sucessfuly completed the 
	;    interactive create
	;

	mov	ax,MSG_GO_SUSPEND_COMPLETE_CREATE
	call	ObjCallInstanceNoLock

	;    Release mouse is in here instead of MSG_GO_COMPLETE_CREATE
	;    because objects like the spline don't want to give up the
	;    mouse at this point
	;

	mov	ax,MSG_GO_RELEASE_MOUSE
	call	ObjCallInstanceNoLock

	clr	cx				;no return flags

unignoreUndo:
	;    We started ignoring actions in MSG_GO_BEGIN_CREATE.
	;

	call	GrObjGlobalUndoAcceptActions

	;    Make the creation of the object undoable, assuming we
	;    actually created it you know.
	;

	test	cx,mask ECRF_DESTROYED
	jnz	done
	call	GrObjGenerateUndoCreateChain

done:
	.leave
	ret

error:
	mov	cx,mask ECRF_NOT_CREATING
	jmp	done

dontCreate:
	mov	ax,MSG_GO_CLEAR_SANS_UNDO
	call	ObjCallInstanceNoLock
	mov	cx,mask ECRF_DESTROYED
	jmp	unignoreUndo

GrObjEndCreate		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCheckForTinySprite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the width and height of the spriteTransform
		to be really small. Take into account the view factor
		by using nudge units so that min size is in screen pixels

CALLED BY:	INTERNAL 
		GrObjEndCreate

PASS:		*ds:si - object
		spriteTransform exists

RETURN:		
		stc - it is a tiny sprite
		clc - it is not a tiny sprite

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MIN_ACCEPTABLE_SPRITE_DIMENSION equ 8
GrObjCheckForTinySprite		proc	near
	class	GrObjClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>
	AccessSpriteTransformChunk	di,ds,si
	call	GrObjGetCurrentNudgeUnitsWWFixed

	pushwwf	dxcx					;x nudge
	movwwf	dxcx,ds:[di].OT_height
	tst	dx
	jns	10$
	negwwf	dxcx
10$:
	call	GrUDivWWFixed
	popwwf	bxax					;y nudge
	cmp	dx,MIN_ACCEPTABLE_SPRITE_DIMENSION
	jge	notTiny

	movwwf	dxcx,ds:[di].OT_width
	tst	dx
	jns	20$
	negwwf	dxcx
20$:
	call	GrUDivWWFixed
	cmp	dx,MIN_ACCEPTABLE_SPRITE_DIMENSION
	jl	tiny

notTiny:
	clc
done:
	.leave
	ret

tiny:
	stc	
	jmp	done

GrObjCheckForTinySprite		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoCreateChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for the creation of an object

CALLED BY:	INTERNAL
		GrObjEndCreate

PASS:		*ds:si - object

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateUndoCreateChain		proc	near
	.enter

	mov	cx,handle createString
	mov	dx,offset createString
	call	GrObjGlobalStartUndoChain
	jc	endChain

	;    Make that undo action
	;

	mov	ax,MSG_GO_CLEAR				;undo message
	clr	bx					;AddUndoActionFlags
	call	GrObjGlobalAddFlagsUndoAction

endChain:
	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjGenerateUndoCreateChain		endp







GrObjExtInteractiveCode	ends



GrObjRequiredInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return od of pointer image

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - PointDWFixed

RETURN:		
		ax - mask MRF_NEW_POINTER_IMAGE
		cx:dx - od of pointer image
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			object will be in create mode

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetPointerImage	method dynamic GrObjClass, 
			MSG_GO_GET_POINTER_IMAGE
	.enter

	mov	al,ds:[di].GOI_actionModes
	test	al,mask GOAM_CREATE
	jz	otherMode

	mov	cl, GOPIS_CREATE
getImage:
	mov	ax,MSG_GO_GET_SITUATIONAL_POINTER_IMAGE
	call	ObjCallInstanceNoLock
	clr	al
	ornf	ax, mask MRF_PROCESSED

	.leave
	ret

otherMode:
	test	al,mask GOAM_MOVE
	jz	tryResize
	mov	cl,GOPIS_MOVE
	jmp	getImage

tryResize:
	test	al,mask GOAM_RESIZE or mask GOAM_ROTATE
	jz	checkHandle
	mov	cl,GOPIS_RESIZE_ROTATE
	jmp	getImage

checkHandle:
	call	GrObjGetPointOverAHandlePointerImageSituation
	jmp	getImage

GrObjGetPointerImage		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetPointOverAHandlePointerImageSituation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the point over handle and return the
		GrObjPointerImageSituation that is appropriate. If the
		point is not over a handle return GOPIS_NORMAL

CALLED BY:	INTERNAL UTILITY

PASS:		
		ss:bp - PointDWFixed

RETURN:		
		cl - GrObjPointerImageSituation
		first child in priority list is the one whose handle was hit

DESTROYED:	
		ch

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetPointOverAHandlePointerImageSituation		proc	far
	uses	ax
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	mov	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_RESIZE
	call	GrObjGlobalCheckForPointOverAHandle
	jc	handleHit

	mov	cl,GOPIS_NORMAL
done:
	.leave
	ret

handleHit:
	cmp	al,HANDLE_MOVE
	jne	resize
	mov	cl,GOPIS_MOVE
	jmp	done

resize:
	mov	cl,GOPIS_RESIZE_ROTATE
	jmp	done

GrObjGetPointOverAHandlePointerImageSituation		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetSituationalPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return default pointer images for situation

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cl - GrObjPointerImageSituation

RETURN:		
		ah - high byte of MouseReturnFlags
			MRF_SET_POINTER_IMAGE or MRF_CLEAR_POINTER_IMAGE
		if MRF_SET_POINTER_IMAGE
		cx:dx - optr of mouse image
	
DESTROYED:	
		al

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetSituationalPointerImage	method dynamic GrObjClass, 
					MSG_GO_GET_SITUATIONAL_POINTER_IMAGE
	.enter

	mov	bl,cl
	clr	bh
	shl	bx
	shl	bx
	add	bx,offset GrObjPointerImageTable
	mov	cx,cs:[bx].handle
	mov	dx,cs:[bx].offset
	mov	ax,mask MRF_SET_POINTER_IMAGE
	
	.leave
	ret
GrObjGetSituationalPointerImage		endm


GrObjPointerImageTable	optr \
	ptrCreate,				;GOPIS_NORMAL
	ptrCreate,				;GOPIS_CREATE
	ptrCreate,				;GOPIS_EDIT
	ptrMove,				;GOPIS_MOVE
	ptrResize				;GOPIS_RESIZE_ROTATE

.assert (length GrObjPointerImageTable eq GrObjPointerImageSituation)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetLocksOfFirstPriorityListChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the locks of the first child in the
		priority list

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - pointer tool

RETURN:		
		cx - locks 

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetLocksOfFirstPriorityListChild		proc	far
	uses	ax,bx,dx,si,di
	.enter

	clr	cx				;get first child
	mov	ax,MSG_GB_PRIORITY_LIST_GET_ELEMENT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>
	jcxz	noObj

	movdw	bxsi,cxdx			;object w/handle hit od
	mov	ax,MSG_GO_GET_LOCKS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	cx,ax				;locks

done:
	.leave
	ret

noObj:
	clr	cx
	jmp	done

GrObjGetLocksOfFirstPriorityListChild		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMetaPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A grobject should be receiving MSG_META_PTR only
		when it is the floater and the mouse has wandered
		over a body that is not the target. We handle this
		message for the sole purpose of setting the pointer 
		image.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - LargeMouseData


RETURN:		
		ax - MouseReturnFlags
		if MRF_SET_POINTER_IMAGE
			cx:dx - optr of pointer image
		else
			cx,dx - DESTROYED

	
DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMetaPtr	method dynamic GrObjClass, MSG_META_PTR, MSG_META_LARGE_PTR
	.enter

	mov	ax,MSG_GO_GET_POINTER_IMAGE
	call	ObjCallInstanceNoLock
	ornf	ax,mask MRF_PROCESSED

	.leave
	ret
GrObjMetaPtr		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjActivateCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent when the object has been selected as a tool.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		cl - ActivateCreateFlags


RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjActivateCreate method dynamic GrObjClass, MSG_GO_ACTIVATE_CREATE
	uses	ax,cx,dx,bp
	.enter

EC <	test	cl, not (mask ACF_NOTIFY)			>
EC <	ERROR_NZ BAD_ACTIVATE_CREATE_FLAGS			>

	call	ObjMarkDirty

	mov	dl,cl				;ActivateCreateFlags


	BitSet	ds:[di].GOI_optFlags, GOOF_FLOATER
	clr	ds:[di].GOI_actionModes

	;    If ACF_NOTIFY set then send method to all objects on
	;    the selection list notifying them of activation.  Send
	;    an UpdateUI in case objects dropped the selection due
	;    to the activation notification
	;

	test	dl, mask ACF_NOTIFY
	jz	done
	mov	ax,MSG_GO_SEND_ANOTHER_TOOL_ACTIVATED
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
GrObjActivateCreate endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSendAnotherToolActivated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GO_ANOTHER_TOOL_ACTIVATED to selected and
		editable grobjects

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSendAnotherToolActivated	method dynamic GrObjClass, 
					MSG_GO_SEND_ANOTHER_TOOL_ACTIVATED
	uses	ax,cx,dx,bp
	.enter

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	bp, mask ATAF_SHAPE			;default assumption
	mov	ax,MSG_GO_ANOTHER_TOOL_ACTIVATED
	clr	di					;MessageFlags
	call	GrObjSendToSelectedGrObjsAndEditAndMouseGrabSuspended

	.leave
	ret
GrObjSendAnotherToolActivated		endm


GrObjRequiredInteractiveCode	ends



GrObjAlmostRequiredCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCompleteTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Object sends this message to itself to complete
		a resize, rotate, skew or other transformation.
		Object needs to calculate its parent dimensions,
		adjust its position to make sure it is on the document,
		invalidate itself and redraw handles if necessary.
		Then send out MSG_GO_ACTION_NOTIFY to themselves.
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		bp - GrObjActionNotificationType
RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCompleteTransform	method dynamic GrObjClass, MSG_GO_COMPLETE_TRANSFORM
	uses	ax
	.enter

	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	call	GrObjEndGeometryCommon

	call	GrObjOptNotifyAction

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret
GrObjCompleteTransform		endm

GrObjAlmostRequiredCode	ends
