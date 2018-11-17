COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		amateurBlaster.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

DESCRIPTION:
	

	$Id: amateurBlaster.asm,v 1.1 97/04/04 15:12:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlasterResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	set size based on display type

PASS:		*ds:si	= BlasterClass object
		ds:di	= BlasterClass instance data
		es	= Segment of BlasterClass.

RETURN:		width added to BP

DESTROYED:	ax,cx,dx 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BlasterResize	method	dynamic	BlasterClass, 
					MSG_VIS_RECALC_SIZE
	.enter


	cmp	es:[displayType], CGA_DISPLAY_TYPE
	je	cga

	mov	cx, BLASTER_WIDTH
	mov	dx, STANDARD_BLASTER_HEIGHT
	jmp	store
cga:
	mov	cx, BLASTER_WIDTH
	mov	dx, CGA_BLASTER_HEIGHT
store:
	call	BitmapResizeCommon

	.leave
	ret
BlasterResize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlasterDrawAlt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw the "alt" blaster -- don't draw in B/W modes

PASS:		*ds:si	= BlasterClass object
		ds:di	= BlasterClass instance data
		es	= Segment of BlasterClass.
		ax	= message #
RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	Don't draw if image is invalid, and don't draw if B/W mode.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BlasterDrawAlt	method	BlasterClass, 
					MSG_BITMAP_DRAW_ALT
	.enter
	andnf	ds:[di].BI_state, not mask BS_DRAW_ALT

	; Don't draw "alt" in B/W modes

	mov	bl, es:[displayType]
	andnf	bl, mask DT_DISP_CLASS
	cmp	bl, DC_GRAY_1 shl offset DT_DISP_CLASS
	je	done

	test	ds:[di].BI_state, mask BS_INVALID
	jnz	done
	ornf	ds:[di].BI_state, mask BS_INVALID

	; superclass does the actual draw

	mov	di, offset BlasterClass
	call	ObjCallSuperNoLock
done:
	.leave
	ret
BlasterDrawAlt	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlasterDrawIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= BlasterClass object
		ds:di	= BlasterClass instance data
		es	= Segment of BlasterClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	See if need to draw the "ALT" bitmap, then see if need
	to draw the normal bitmap.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BlasterDrawIfNeeded	method	dynamic	BlasterClass, 
					MSG_BITMAP_DRAW_IF_NEEDED
	uses	ax,cx,dx,bp
	.enter

	test	ds:[di].BI_state, mask BS_DRAW_ALT
	jnz	drawAlt
	
	test	ds:[di].BI_state, mask BS_INVALID
	jz	done

	mov	ax, MSG_VIS_DRAW
	call	ObjCallInstanceNoLock 	
done:
	.leave
	ret
drawAlt:
	mov	ax, MSG_BITMAP_DRAW_ALT
	call	BlasterDrawAlt
	jmp	done

BlasterDrawIfNeeded	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlasterDrawAltNextTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= BlasterClass object
		ds:di	= BlasterClass instance data
		es	= Segment of BlasterClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BlasterDrawAltNextTime	method	dynamic	BlasterClass, 
					MSG_BLASTER_DRAW_ALT_NEXT_TIME

	ornf	ds:[di].BI_state, mask BS_DRAW_ALT
	ret
BlasterDrawAltNextTime	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlasterCheckPeanut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	See if this blaster should redraw itself.

PASS:		*ds:si	= BlasterClass object
		ds:di	= BlasterClass instance data
		es	= Segment of BlasterClass.

		cx, dx  = coordinates of peanut 

RETURN:		carry clear always

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BlasterCheckPeanut	method	dynamic	BlasterClass, 
					MSG_BITMAP_CHECK_PEANUT
	.enter
	call	VisTestPointInBounds
	jnc	done
	ornf	ds:[di].BI_state, mask BS_INVALID
	clc
done:
	.leave
	ret
BlasterCheckPeanut	endm

