COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		syssound.asm

AUTHOR:		jmagasin, May 15, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/15/96   	Initial revision


DESCRIPTION:
	The sound component.
		

	$Id: syssound.asm,v 1.1 98/03/11 04:31:13 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


idata	segment
	SystemSoundClass
idata	ends


makeActionEntry sound, StandardSound, \
	MSG_SYSTEM_SOUND_ACTION_STANDARDSOUND, LT_TYPE_VOID, 1

compMkActTable sound, StandardSound

MakeSystemActionRoutines SystemSound, sound


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemSoundMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the system know our real class tree. 

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= SystemSoundClass object
		ds:di	= SystemSoundClass instance data
		ds:bx	= SystemSoundClass object (same as *ds:si)
		es 	= segment of SystemSoundClass
		ax	= message #
RETURN:		cx:dx	= fptr to class
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemSoundMetaResolveVariantSuperclass	method dynamic SystemSoundClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
		
		compResolveSuperclass SystemSound, ML2

SystemSoundMetaResolveVariantSuperclass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemSoundMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear default bits on object

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= SystemSoundClass object
		ds:di	= SystemSoundClass instance data
		ds:bx	= SystemSoundClass object (same as *ds:si)
		es 	= segment of SystemSoundClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemSoundMetaInitialize	method dynamic SystemSoundClass, 
					MSG_META_INITIALIZE
		.enter
		mov	di, offset SystemSoundClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
	; clear the visual bits
		andnf	ds:[di].EI_state, not (mask ES_IS_GEN or mask ES_IS_VIS)
		.leave
		ret
SystemSoundMetaInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemSoundEntGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= SystemSoundClass object
		ds:di	= SystemSoundClass instance data
		ds:bx	= SystemSoundClass object (same as *ds:si)
		es 	= segment of SystemSoundClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemSoundEntGetClass	method dynamic SystemSoundClass, 
					MSG_ENT_GET_CLASS
		.enter
		mov	cx, segment SystemSoundString
		mov	dx, offset SystemSoundString
		.leave
		ret
SystemSoundEntGetClass	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysUIPlayUISound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays one of the StandardSoundType's

PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- whatever an EDAA is.
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Sounds are as follows:
		SS_ERROR (0)
		SS_WARNING (1)
		SS_NOTIFY(2)
		SS_NO_INPUT (3)
		SS_KEY_CLICK (4)
		SS_ALARM (5)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemSoundStandardSound	method dynamic 	SystemSoundClass, 
			MSG_SYSTEM_SOUND_ACTION_STANDARDSOUND
	.enter

		
	call	GadgetUtilGetSingleIntegerArg
	jc	done

	cmp	ax, SST_ALARM
	jbe	playSound
	mov	ax, SST_ERROR

playSound:
	call	UserStandardSound
done:
	.leave
	ret
SystemSoundStandardSound	endm

GadgetUtilGetSingleIntegerArg	proc	near
	uses	di
	.enter

	mov	ax, 1
	call	GadgetUtilCheckNumArgs
	jc	done

	;
	;  Make sure the thing's an integer.
	;
	les     di, ss:[bp].EDAA_argv
	cmp	es:[di].CD_type, LT_TYPE_INTEGER
	jz	getArg
	les	di, ss:[bp].EDAA_retval
	mov     es:[di].CD_type, LT_TYPE_ERROR
	mov     es:[di].CD_data.LD_integer, CAE_WRONG_TYPE
	stc
	jmp	done
		
	;
	;  Looks good.
	;
getArg:
	mov	ax, es:[di].CD_data.LD_integer
	clc
		
done:
	.leave
	ret
GadgetUtilGetSingleIntegerArg	endp

GadgetUtilCheckNumArgs	proc	near
	.enter

	cmp     ss:[bp].EDAA_argc, ax
	;
	; the carry will be clear on fall-thru
	;
	jne     bogus

done:
	.leave
	ret

bogus:
	les	di, ss:[bp].EDAA_retval
	mov     es:[di].CD_type, LT_TYPE_ERROR
	mov     es:[di].CD_data.LD_integer, CAE_WRONG_NUMBER_ARGS

	;
	;  indicate bogosity.
	;
	stc
	jmp	done
GadgetUtilCheckNumArgs	endp
