COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		sokoban
FILE:		sokobanScores.asm

AUTHOR:		Steve Yegge, Jun 15, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/15/93		Initial revision

DESCRIPTION:
	

	$Id: sokobanScores.asm,v 1.1 97/04/04 15:12:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ScoreCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateScoreList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to add the user's score to the HS list.

CALLED BY:	SokobanDetachUIFromDocument

PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/15/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateScoreList	proc	far
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	;  Make a data block to hold stats string.
	;
		mov	ax, STAT_STRING_LENGTH
		mov	cx, (mask HAF_ZERO_INIT shl 8) or ALLOC_DYNAMIC_LOCK
		call	MemAlloc		; bx = handle, ax = segment
	;
	;  Convert level to ascii.
	;
		mov	es, ax
		clr	di, cx, dx		; ptr, flags, high word of score
		mov	ax, ds:[scoreLevel]
		call	UtilHex32ToAscii	; cx = length
		add	di, cx			; move to end
	;
	;  Put in a "/" character.
	;
		mov	ax, C_SLASH
		LocalPutChar	esdi, ax
	;
	;  Convert the moves to ascii.
	;
		mov	ax, ds:[scoreMoves]
		clr	cx			; flags
		call	UtilHex32ToAscii	; cx = length
		add	di, cx			; move to end
	;
	;  Put in a "/" character.
	;
		mov	ax, C_SLASH
		LocalPutChar	esdi, ax
	;
	;  Convert the pushes to ascii and null-terminate the string
	;
		mov	cx, mask UHTAF_NULL_TERMINATE
		mov	ax, ds:[scorePushes]
		call	UtilHex32ToAscii
		call	MemUnlock
		mov	bp, bx
	;
	;  Send their score to the controller.  dx is still zero.
	;
		call	ConvertStatsToScore	; dx:cx = score

		GetResourceHandleNS	SokobanHighScoreControl, bx
		mov	si, offset	SokobanHighScoreControl
		mov	di, mask MF_CALL
		mov	ax, MSG_HIGH_SCORE_ADD_SCORE
		call	ObjMessage
	;
	;  If the score was added (carry set), act accordingly.
	;
		jnc	done

		call	CongratulateUser
done:
		.leave
		ret
UpdateScoreList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertStatsToScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute a score based on the user's level, moves & pushes.

CALLED BY:	UpdateScoreList

PASS:		ds = dgroup

RETURN:		dx:cx = dword-sized score

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	The algorithm I'm using is:

		Score = 10,000 * level +
			10,000 * (1 - .9(moves/8192)) +
			1,000 * (1 - pushes/4096)

	Thus:	- each level is worth 10,000
		- moves are worth between 1,000 and 10,000 (moves
		  are truncated to 8192, just for the hell of it)
		- pushes are worth between 0 and 1,000, with any
		  pushes over 4096 not mattering (it's still 0 points).

	This is a pretty easy algorithm to calculate, and the
	weights are about right:  higher level always overrides
	lower level regardless of moves and pushes, and lower moves
	*almost* always overriding higher moves, except in a few
	bizarre cases where the number of pushes is vastly different).

	A slightly better algorithm, which would achieve a better
	distribution of points over the ranges (1-10k for moves,
	0-1k for pushes) would be:

		Score = 10,000 * level +
			10,000 * (1 - sin(pi * moves/8192)) +
			1,000 * (1 - sin(pi * pushes/4096))

	This calculation takes advantage of the fact that the
	sine function is changing very rapidly over values close
	to zero, and less rapidly over values close to pi.  Since
	the average level will have between ~200 and ~1500 moves,
	representing the bottom of the 0-8192 range, the fraction
	of the total score determined by moves will vary between
	5,000-10,000, instead of (say) 9,000-10,000.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/15/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertStatsToScore	proc	near
		uses	ax,bx
		.enter
	;
	;  Calculate the level portion of the score.
	;
		mov	ax, ds:[scoreLevel]		; ax = level
		mov	dx, BASE_LEVEL_SCORE_FACTOR	; score per level
		mul	dx				; dx.ax = level score
		movdw	bxcx, dxax			; cx.dx = total
	;
	;  Calculate the moves portion of the score.  First truncate
	;  the moves to 8192 if necessary.
	;
		mov	ax, ds:[scoreMoves]
		cmp	ax, MAX_SIGNIFICANT_MOVES	; moves above this
		jbe	movesOK				;  don't affect scoring

		mov	ax, MAX_SIGNIFICANT_MOVES
movesOK:
		mov	dx, EXTRA_MOVES_SCORE_FACTOR	; the ".9" above
		mul	dx				; dx.ax = 9000*moves
	;
	;  Shift the quantity in dxax right 13 bits (52 cycles, not
	;  counting prefetch queue, which probably kills us).
	;
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax				; ax = 9000*moves/8192

		mov	dx, BASE_MOVES_SCORE_FACTOR	; max poss. moves score
		sub	dx, ax				; dx = moves score
		mov_tr	ax, dx				; ax = moves score	
		clr	dx				; dx.ax = moves score
	;
	;  Add the moves & level scores.
	;
		adddw	bxcx, dxax
	;
	;  Compute the pushes score, first truncating pushes to 4096.
	;
		mov	ax, ds:[scorePushes]
		cmp	ax, MAX_SIGNIFICANT_PUSHES
		jbe	pushesOK

		mov	ax, MAX_SIGNIFICANT_PUSHES
pushesOK:
		mov	dx, BASE_PUSHES_SCORE_FACTOR
		mul	dx				; dx.ax = 1000*pushes
	;
	;  Shift dxax right 12 bits (dividing by 4096).
	;
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax				; ax = 1000*pushes/4096

		mov	dx, BASE_PUSHES_SCORE_FACTOR
		sub	dx, ax				; dx = pushes score
		mov_tr	ax, dx				; ax = pushes score
		clr	dx				; dx.ax = pushes score
	;
	;  Add in the pushes score to the total.
	;
		adddw	bxcx, dxax			; bxcx = score
		mov	dx, bx				; dxcx = score (return)

		.leave
		ret
ConvertStatsToScore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanHighScoreGetName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the user's name from the map block.

CALLED BY:	MSG_HIGH_SCORE_GET_NAME

PASS:		*ds:si	= SokobanHighScoreClass object
		ds:di	= SokobanHighScoreClass instance data
		es	= dgroup
		dx:bp	= ptr to buffer to hold MAX_USER_NAME_SIZE
		characters plus one null

RETURN:		cx = string length, not counting null
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanHighScoreGetName	method dynamic SokobanHighScoreClass, 
					MSG_HIGH_SCORE_GET_NAME
		.enter
	;
	;  Get the name and copy it to the passed buffer.
	;
		pushdw	dxbp				; save passed buffer

		mov	bx, es:[vmFileHandle]		; game vm file
		call	VMGetMapBlock			; ax = map block
		call	VMLock				; ax = segment

		mov	ds, ax
		mov	si, offset SMB_name		; ds:si = source
		
		segmov	es, ds, ax
		mov	di, si
		call	LocalStringLength		; cx = length w/o null
		mov	ax, cx
		inc	cx				; include NULL

		popdw	esdi				; es:di = dest buffer
		rep	movsb
		call	VMUnlock

		mov_tr	cx, ax				; return length

		.leave
		ret
SokobanHighScoreGetName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CongratulateUser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog and play a song.

CALLED BY:	SokobanHighScoreGetName

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/16/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CongratulateUser	proc	near
		uses	ax,bx,cx,si,es
		.enter
	;
	;  Start the song a-playin'.
	;
		GetResourceSegmentNS	dgroup, es
		mov	cx, SS_HIGH_SCORE
		call	SoundPlaySound
	;
	;  Put up the dialog.
	;
		GetResourceHandleNS	CongratsDialog, bx
		mov	si, offset	CongratsDialog
		call	UserDoDialog

		.leave
		ret
CongratulateUser	endp



ScoreCode	ends
