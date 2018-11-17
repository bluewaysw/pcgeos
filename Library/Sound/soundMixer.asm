COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	Global PC
MODULE:		Sound Librray
FILE:		soundMixer.asm

AUTHOR:		Todd Stumpf, Jan 07, 1999

ROUTINES:
	Name				Description
	----				-----------
	SoundMixerGetMasterVolume
	SoundMixerSetMasterVolume
	SoundMixerGetSourceCount 
	SoundMixerGetMapSource   
	SoundMixerGetSourceVolume
	SoundMixerSetSourceVolume
	SoundMixerGetEffectCount
	SoundMixerMapEffect     
	SoundMixerGetEffectLevel
	SoundMixerSetEffectLevel

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Todd    1/07/99   	Initial revision


DESCRIPTION:
	Mixer interface.

	Why, oh why, did I ever listen to Adam and put in a
	driver interface to the library?  It's a pointless step.
	GEOS will never go protected... and even if it did,
	everything would have to be rewritten anyway...

	The mixer code just talks straight to the registered
	drivers.  It doesn't bother with the LibDriver interface...

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDMIXERGETMASTERVOLUME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundReallocMusic

C DECLARATION:  extern Boolean
                 _pascal SoundMixerGetMasterVolume(word *left, word *right);

RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDMIXERGETMASTERVOLUME	proc	far	left:fptr.word,
						right:fptr.word
	uses	si, di, ds, es
	.enter

	call	SoundMixerGetMasterVolume
	jc	done			; did they?

	mov	ds, left.segment	; ds <- song segment
	mov	si, left.offset		; si <- song offset
	mov	es, right.segment	; ds <- song segment
	mov	di, right.offset	; si <- song offset
	push	ax
	shr	ax, 8
	mov	ds:[si], ax
	pop	ax
	clr	ah	
	mov	es:[di], ax
	mov	ax, SOUND_ERROR_NO_ERROR
done:
	.leave
	ret
SOUNDMIXERGETMASTERVOLUME	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDMIXERSETMASTERVOLUME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundReallocMusic

C DECLARATION:  extern Boolean
                 _pascal SoundMixerSetMasterVolume(byte left, byte right);

RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDMIXERSETMASTERVOLUME	proc	far	left:word,
						right:word
	uses	bx, si, ds
	.enter
	mov	bx, left
	mov	ah, bl
	mov	bx, right
	mov	al, bl

	call	SoundMixerSetMasterVolume
	jc	done			; did they?

	mov	ax, SOUND_ERROR_NO_ERROR
done:
	.leave
	ret
SOUNDMIXERSETMASTERVOLUME	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundMixerGetMasterVolume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retreive master volume settings

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		carry clear on success
		AL <- ChannelLevel for left channel
		AH <- ChannelLevel for right channel
				- or -
		carry set on error
		AX <- SoundError
DESTROYED:	flags
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Ask driver to give us what we want...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Todd    1/07/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundMixerGetMasterVolume	proc	far
	uses	di, ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax

	mov	di, DRE_SOUND_MIXER_GET_MASTER_VOLUME
	call	ds:[soundSynthStrategy]	; carry clear on success
					; AL <- left ChannelLevel
					; AH <- right ChannelLevel
	.leave
	ret
SoundMixerGetMasterVolume	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundMixerSetMasterVolume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust master volume setting of mixer

CALLED BY:	EXTERNAL
PASS:		AL -> desired ChannelLevel for left channel
		AH -> desired ChannelLevel for right channel
RETURN:		carry clear on success
		AL <- new ChannelLevel for left channel
		AH <- new ChannelLevel for right channel
				- or -
		carry set on error
		AX <- SoundError
DESTROYED:	(flags)
SIDE EFFECTS:	Changes the volume level of the mixer

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Todd    	1/07/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundMixerSetMasterVolume	proc	far
	uses	di, ds
	.enter
	mov	di, segment dgroup
	mov	ds, di
						; AL -> left ChannelLevel
						; AH -> right ChannelLevel
	mov	di, DRE_SOUND_MIXER_SET_MASTER_VOLUME
	call	ds:[soundSynthStrategy]	; carry clear on success
					; AL <- left ChannelLevel
					; AH <- right ChannelLevel
	.leave
	ret
SoundMixerSetMasterVolume	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundMixerGetSourceCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return # of sources (independent devices) supported by mixer

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		CX <- # of sources supported
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Use ubiquitous driver info call, and supply our caller
		with the information they want.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Todd    	1/07/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundMixerGetSourceCount	proc	far
	uses	ax, dx, di, ds
	.enter
	pushf
	mov	ax, segment dgroup
	mov	ds, ax

	mov	di, DRE_SOUND_MIXER_GET_CAPABILITIES
	call	ds:[soundSynthStrategy]	; carry clear on success
					; AX <- source count
					; DX <- effect count
	mov_tr	cx, ax				; CX <- source count
	popf
	.leave
	ret
SoundMixerGetSourceCount	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundMixerMapSource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine what source # to use for a StdSourceType

CALLED BY:	EXTERNAL
PASS:		AX -> StdSourceType desired
RETURN:		carry clear on success
		CX <- source # for source
		BX <- StdSourceBehavior for source
				- or -
		carry set on error
		AX <- SoundErrors
DESTROYED:	flags
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Todd    	1/07/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundMixerMapSource	proc	far
	uses	di, ds
	.enter
	mov	di, segment dgroup
	mov	ds, di

						; AX -> StdSourceType desired
	mov	di, DRE_SOUND_MIXER_MAP_SOURCE
	call	ds:[soundSynthStrategy]	; carry clear on success
					; CX <- source #
					; BX <- StdSourceBehavior
	.leave
	ret
SoundMixerMapSource	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundMixerGetSourceVolume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return volume level for individual mixer source

CALLED BY:	EXTERNAL
PASS:		CX -> source #
RETURN:		carry clear on success
		AL <- left ChannelLevel for left channel source
		AH <- right ChannelLevel for right channel source
				- or -
		carry set on error
		AX <- SoundErrors
DESTROYED:	flags
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Assume everything is stereo.
		If we're actually querying for a mono device,
			the caller will just ignore AH, as they
			will have previously called 'Map' which
			returns a StdSourceBehavior that let's
			them know this source is mono-only.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Todd    	1/07/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundMixerGetSourceVolume	proc	far
	uses	di, ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax

						; CX -> source #
	mov	di, DRE_SOUND_MIXER_GET_SOURCE_VOLUME
	call	ds:[soundSynthStrategy]	; carry clear on success
					; AL <- left ChannelLevel
					; AH <- right ChannelLevel
	.leave
	ret
SoundMixerGetSourceVolume	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundMixerSetSourceVolume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change volume level of individual mixer source

CALLED BY:	EXTERNAL
PASS:		CX -> source #
		AL -> desired ChannelLevel for left channel of source
		AH -> desired ChannelLevel for right channel of source
RETURN:		carry clear on success
		AL <- new ChannelLevel for left channel of source
		AH <- new ChannelLevel for right channel of source
				- or -
		carry set on error
		AX <- SoundErrors
DESTROYED:	flags
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Much like GetSourceVolume, we can assume everything
		is stereo.  Mono devices will not be confused by
		any extraneous parameters...

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Todd    	1/07/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundMixerSetSourceVolume	proc	far
	uses	di, ds
	.enter
	mov	di, segment dgroup
	mov	ds, di

						; CX -> source #
						; AL -> left ChannelLevel
						; AH -> right ChannelLevel
	mov	di, DRE_SOUND_MIXER_SET_SOURCE_VOLUME
	call	ds:[soundSynthStrategy]	; carry clear on success
					; AL <- left ChannelLevel
					; AH <- right ChannelLevel
	.leave
	ret
SoundMixerSetSourceVolume	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundMixerGetEffectCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return # of effects (bass, expansion, etc) supported by mixer

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		CX <- # of effects supported
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Use ubiquitous info call, and return only desired info

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Todd    	1/07/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundMixerGetEffectCount	proc	far
	uses	ax, dx, di, ds
	.enter
	pushf
	mov	ax, segment dgroup
	mov	ds, ax

	mov	di, DRE_SOUND_MIXER_GET_CAPABILITIES
	call	ds:[soundSynthStrategy]	; carry clear on success
					; AX <- source count
					; DX <- effect count
	mov	cx, dx				; CX <- effect count
	popf
	.leave
	ret
SoundMixerGetEffectCount	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundMixerMapEffect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine what effect # to use for a StdEffectType

CALLED BY:	EXTERNAL
PASS:		AX -> StdEffectType desired
RETURN:		carry clear on success
		CX <- effect # for effect
		BX <- StdEffectBehavior for effect
				- or -
		carry set on error
		AX <- SoundErrors
DESTROYED:	flags
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Todd    	1/07/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundMixerMapEffect	proc	far
	uses	di, ds
	.enter
	mov	di, segment dgroup
	mov	ds, di

						; AX -> StdEffectype desired
	mov	di, DRE_SOUND_MIXER_MAP_EFFECT
	call	ds:[soundSynthStrategy]	; carry clear on success
					; CX <- effect #
					; BX <- StdEffectBehavior
	.leave
	ret
SoundMixerMapEffect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundMixerGetEffectLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return level for individual mixer effect

CALLED BY:	EXTERNAL
PASS:		CX -> effect #
RETURN:		carry clear on success
		AL <- left ChannelLevel for left channel effect
		AH <- right ChannelLevel for right channel effect
				- or -
		carry set on error
		AX <- SoundErrors
DESTROYED:	flags
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Much like sources, all effects can be treated as
		if they are stereo.  The caller knows (by the
		previous call to MapEffect) which ones are mono
		and which ones aren't, and should ignore the
		extraneous channel of data.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Todd    	1/07/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundMixerGetEffectLevel	proc	far
	uses	di, ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax

						; CX -> effect #
	mov	di, DRE_SOUND_MIXER_GET_EFFECT_LEVEL
	call	ds:[soundSynthStrategy]	; carry clear on success
					; AL <- left ChannelLevel
					; AH <- right ChannelLevel
	.leave
	ret
SoundMixerGetEffectLevel	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundMixerSetEffectLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change level of individual mixer effect

CALLED BY:	EXTERNAL
PASS:		CX -> effect #
		AL -> desired ChannelLevel for left channel of effect
		AH -> desired ChannelLevel for right channel of effect
RETURN:		carry clear on success
		AL <- new ChannelLevel for left channel of effect
		AH <- new ChannelLevel for right channel of effect
				- or -
		carry set on error
		AX <- SoundErrors
DESTROYED:	flags
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We can treat all effects as stereo effects, as
		mono effects will just ignore the extra channel
		of data...

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Todd    	1/07/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundMixerSetEffectLevel	proc	far
	uses	di, ds
	.enter
	mov	di, segment dgroup
	mov	ds, di

						; CX -> effect #
						; AL -> left ChannelLevel
						; AH -> right ChannelLevel
	mov	di, DRE_SOUND_MIXER_SET_EFFECT_LEVEL
	call	ds:[soundSynthStrategy]	; carry clear on success
					; AL <- left ChannelLevel
					; AH <- right ChannelLevel
	.leave
	ret
SoundMixerSetEffectLevel	endp

CommonCode		ends
