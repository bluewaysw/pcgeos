COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		amateurSound.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/13/92   	Initial version.

DESCRIPTION:
	

	$Id: amateurSound.asm,v 1.1 97/04/04 15:12:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


AmateurCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AmateurInitSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init the !*#^# sound handles

CALLED BY:	AmateurOpenApplication

PASS:		ds, es, - dgroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AmateurInitSound	proc near
		uses	ax,bx,cx,dx,di,si,bp
		.enter
		
		mov	bp, 2		; skip first entry
soundLoop:
		mov	bx, es
		mov	si, cs:soundOffsetTable[bp]
		mov	cx, 1
		call	SoundAllocMusic		; allocate the sound
						; handle returned in bx
		mov	di, cs:soundHandleTable[bp]
		mov	es:[di], bx			; save the handle
		add	bp, 2
		cmp	bp, size soundOffsetTable
		jl	soundLoop
		
		.leave
		ret
AmateurInitSound	endp


soundOffsetTable	word	\
	0,
	offset	SoundClownHit,
	offset	SoundExtraClown,
	offset	SoundGameOver,
	offset	SoundNoPellets,
	offset	SoundFewPellets,
	offset	SoundClownTally,
	offset	SoundMaxPelletsOnScreen

soundHandleTable	word	\
	0,
	offset	SoundClownHitHandle,
	offset	SoundExtraClownHandle,
	offset	SoundGameOverHandle,
	offset	SoundNoPelletsHandle,
	offset	SoundFewPelletsHandle,
	offset	SoundClownTallyHandle,
	offset  SoundMaxPelletsOnScreenHandle





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AmateurExitSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AmateurExitSound	proc near
		uses	ax,bx,cx,dx,di,si,bp
		.enter

		mov	bp, 2
shutoffLoop:
		mov	di, cs:soundHandleTable[bp]
		mov	bx, es:[di]
		call	SoundStopMusic
		call	SoundFreeMusic
		add	bp, 2
		cmp	bp, size soundHandleTable
		jl	shutoffLoop

		.leave
		ret
AmateurExitSound	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentPlaySound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play a sound

CALLED BY:	ContentDisplay

PASS:		ds:di - content

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentPlaySound	proc near	
		uses	ax,dx
		class	AmateurContentClass 
		.enter
EC <		call	ECCheckContentDSDI		> 

	; see if there are any sounds to be played

		mov	dl, ds:[di].ACI_sound
		tst	dl
		jz	done

		clr	dh
		mov	ax, SST_CUSTOM_BUFFER
		call	ContentStandardSound
		clr	ds:[di].ACI_sound
done:
		.leave
		ret

ContentPlaySound	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ContentStandardSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Plays the passed buffer, depending on the
		Sound On/Sound Off/System Default setting.

CALLED BY:	ContentPlaySound

Pass:		dx - AmateurSoundType

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar  6, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentStandardSound	proc	near
	uses	bp, es, di, ax, cx
	.enter

	call	GetContentSoundSetting		;bp <- GameSoundSetting

	;
	;	If sound is off, do nothing
	;
	cmp	bp, SS_SOUND_OFF
	je	done

	;
	;	If sound is on, send it directly to the sound library
	;
	cmp	bp, SS_SOUND_ON
	je	soundOn

	;
	;	System default
	;

	segmov	es, <segment dgroup>, bp
	mov	bp, dx
	mov	di, cs:soundHandleTable[bp]
	mov	cx, es:[di]
	mov	ax, SST_CUSTOM_SOUND
	mov	dx, AMATEUR_TEMPO
	call	UserStandardSound
	jmp	done
	
soundOn:
	segmov	es, <segment dgroup>, bp
	mov	bp, dx
	mov	di, cs:soundHandleTable[bp]
	mov	ax, SP_GAME
	mov	bx, es:[di]
	mov	dl, mask EOSF_UNLOCK
	mov	cx, AMATEUR_TEMPO
	call	SoundPlayMusic
done:
	.leave
	ret

ContentStandardSound	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GetContentSoundSetting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns the currrent GameSoundSetting for this game.

Pass:		nothing

Return:		bp = GameSoundSetting

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar  6, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContentSoundSetting	proc	near
	uses	ax, bx, cx, dx, di, si
	.enter

	mov	bx, handle SoundList
	mov	si, offset SoundList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov	bp, ax

	.leave
	ret
GetContentSoundSetting	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlaySound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play a sound. 

CALLED BY:	anywhere

PASS:		al - AmateurSoundType
		ds - segment of game objects

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlaySound	proc near	
	uses	di
	.enter
	class	AmateurContentClass 
	assume	ds:GameObjects
	mov	di, ds:[ContentObject]
	assume	ds:dgroup

	add	di, ds:[di].Vis_offset
	mov	ds:[di].ACI_sound, al
	call	ContentPlaySound
	.leave
	ret
PlaySound	endp


AmateurCode	ends


idata	segment


SoundClownHit		label	byte
			SoundNote 0, LOW_E, DOTTED_EIGHTH, FORTE
			SoundNote 0, LOW_C, DOTTED_EIGHTH, FORTE
			SoundNote 0, LOW_A/2, DOTTED_EIGHTH, FORTE
			General	GE_END_OF_SONG

SoundExtraClown		label	byte
		Staccato 0, LOW_C, QUARTER, FORTE
		Staccato 0, LOW_D, QUARTER, FORTE
		Staccato 0, LOW_E, QUARTER, FORTE
		Staccato 0, LOW_D, HALF, FORTE
		Staccato 0, LOW_E, QUARTER, FORTE
		Staccato 0, LOW_C, WHOLE, FORTE
		General	 GE_END_OF_SONG

MyRest	macro	delay
	General GE_NO_EVENT
	DeltaTempo	delay
endm		


; Shave-and-a-haircut
SoundGameOver	label	byte

		Staccato	0, LOW_C, QUARTER, FORTE
		MyRest		HALF
		Staccato	0, LOW_G/2, QUARTER, FORTE
		MyRest		HALF
		Staccato	0, LOW_G/2, QUARTER, FORTE
		Staccato	0, LOW_A/2, QUARTER, FORTE
		MyRest		HALF
		Staccato	0, LOW_G/2, QUARTER, FORTE
		MyRest		WHOLE
		MyRest		QUARTER
		Staccato	0, LOW_B/2, QUARTER, FORTE
		MyRest		HALF
		Staccato	0, LOW_C, QUARTER, FORTE
		General		GE_END_OF_SONG


SoundFewPellets		label	byte
			SoundNote 0 ,LOW_B, SIXTEENTH, FORTE
			General		GE_END_OF_SONG

SoundMaxPelletsOnScreen		label	byte
			SoundNote 0 ,MIDDLE_D, SIXTEENTH, FORTE
			General		GE_END_OF_SONG


SoundNoPellets		label	byte	
			SoundNote 0, LOW_B, SIXTEENTH, FORTE
			SoundNote 0, MIDDLE_D, SIXTEENTH, FORTE
			General		GE_END_OF_SONG


SoundClownTally		label	byte
			SoundNote 0, LOW_F/2, EIGHTH, FORTE
			General		GE_END_OF_SONG


SoundClownHitHandle	hptr
SoundExtraClownHandle	hptr
SoundGameOverHandle	hptr
SoundNoPelletsHandle	hptr
SoundFewPelletsHandle	hptr
SoundClownTallyHandle	hptr
SoundMaxPelletsOnScreenHandle	hptr


idata	ends



