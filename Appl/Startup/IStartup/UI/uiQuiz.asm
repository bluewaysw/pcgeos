COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		eqeditDialog.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/14/93   	Initial version.

DESCRIPTION:
	

	$Id: uiQuiz.asm,v 1.1 97/04/04 16:52:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuizCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuizDialogInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initiate the dialog, resetting values, etc.

PASS:		*ds:si	- QuizDialogClass object
		ds:di	- QuizDialogClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nullText char 0
QuizDialogInitiate	method	dynamic	QuizDialogClass, 
					MSG_GEN_INTERACTION_INITIATE
		uses	ax,cx,dx,bp,si
		.enter

	;
	; Get the target text object.  If there is none, just bail.
	;
		
		call	QuizGetTargetTextOD
		jc	continue

		.leave
		ret
continue:

	;
	; Get the selection, but make sure it's not too big
	;
		sub	sp, size VisTextRange
		mov	bp, sp
		mov	dx, ss
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
		mov	di, mask MF_CALL
		call	ObjMessage

		movdw	dxax, ss:[bp].VTR_end
		subdw	dxax, ss:[bp].VTR_start

		add	sp, size VisTextRange
		
		tst	dx
		jnz	setDefaults
		cmp	ax, QUESTION_INFORMATION_BUFFER_SIZE
		ja	setDefaults
		
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_BLOCK
		clr	dx
		mov	di, mask MF_CALL
		call	ObjMessage

		call	QuizDialogParseString
		jnc	callSuper

	;
	; Well, there's no selection, or it's not a valid information
	; line, so set some default values instead
	;
		
setDefaults:

		clr	cx
		mov	dx, cs
		mov	bp, offset nullText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	si, offset QuestionLabelText
		call	ObjCallInstanceNoLock
		
callSuper:
		.leave
		mov	di, offset QuizDialogClass
		GOTO	ObjCallSuperNoLock
QuizDialogInitiate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuizDialogParseString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the dang thing

CALLED BY:	QuizDialogInitiate

PASS:		ds - segment of objects in the Edit Dialog's block
		cx - block handle of string data
		ax - size of string

RETURN:		block freed
		ds - fixed up

		if error
			carry set
		else
			carry clear 

DESTROYED:	ax,bx,cx,dx,di,si

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuizDialogParseString	proc near

		uses	es

		.enter

		mov	bx, cx		; handle of text block

		cmp	ax, size backslashQ
		jbe	error

	;
	; Lock it on down.
	;
		push	ax
		call	MemLock
		mov	es, ax
		clr	di
		pop	ax

	;
	; Check the beginning
	;

		push	ds
		segmov	ds, cs
		mov	si, offset backslashQ
		mov	cx, size backslashQ
		repe	cmpsb
		pop	ds
		jne	error

	;
	; Now, set CX to the length of the remainder, and keep parsing.
	;
		
		mov_tr	cx, ax
		sub	cx, size backslashQ

		mov	si, offset QuestionLabelText
		call	QuizDialogSetText
		jc	done

		mov	si, offset ObjectiveText
		call	QuizDialogSetText
		jc	done

		push	cx
		mov	cl, es:[di]
		clr	ch
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	si, offset QuestionTypeItemGroup
		call	ObjCallInstanceNoLock
		pop	cx
		
		add	di, 2 * size char	; skip past comma
		sub	cx, 2 * size char
		jle	error

		mov	si, offset GroupNumberValue
		call	QuizDialogSetValue
		jc	done

		mov	si, offset QuestionTimeValue
		call	QuizDialogSetValue
		jc	done

		mov	si, offset DifficultyIndexValue
		call	QuizDialogSetValue
		jc	done

		mov	si, offset UsedCountValue
		call	QuizDialogSetValue
		clc			; ignore error, in case used
					; count not found.
		
done:
		pushf
		call	MemFree
		popf
		
		.leave
		ret
error:
		stc
		jmp	done
QuizDialogParseString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuizDialogSetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the text from the buffer, and stick it in the
		text object

CALLED BY:	QuizDialogParseString

PASS:		*ds:si - text object
		es:di - buffer
		cx - # of chars remaining in buffer

RETURN:		di & cx updated

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuizDialogSetText	proc near
		uses	bp
		.enter
		mov	bp, di

	;
	; Search for a comma, replace it with a NULL
	;
		
		mov	al, ','
		repne	scasb
		stc
		jne	done

		push	cx
		mov	{char} es:[di]-size char, 0
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	dx, es
		clr	cx
		call	ObjCallInstanceNoLock
		pop	cx
		clc
done:
		.leave
		ret
QuizDialogSetText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuizDialogSetValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stick the stuff from the buffer into the GenValue object

CALLED BY:	QuizDialogInitiate

PASS:		*ds:si - GenValue object to update
		es:di - buffer
		cx - # of chars remaining in buffer
		al - character to search for

RETURN:		di, cx updated

DESTROYED:	ax,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuizDialogSetValue	proc near
		uses	bp
		
		.enter

		mov	dx, di
		
	;
	; Look for a terminator, either a comma or a carriage return
	; Replace the character BEFORE it with a null.
	;
startLoop:
		mov	al, es:[di]
		cmp	al, ','
		je	found
		cmp	al, C_CR
		je	found

		inc	di
		loop	startLoop
		stc
		jmp	done

found:
	;
	; Stick in a NULL, and send it.
	;
		push	cx
		mov	{char} es:[di]-size char, 0
		mov	ax, MSG_GEN_VALUE_SET_VALUE_FROM_TEXT
		mov	cx, es
		mov	bp, GVT_VALUE
		call	ObjCallInstanceNoLock
		pop	cx
		clc

		inc	di			; get past the comma
done:

		.leave
		ret
QuizDialogSetValue	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuizDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Insert the stuff from the dialog into the text.

PASS:		*ds:si	- QuizDialogClass object
		ds:di	- QuizDialogClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
backslashQ char	"\\q "

QuizDialogApply	method	dynamic	QuizDialogClass, 
					MSG_GEN_APPLY

		uses	ax,cx,dx,bp,es,si
		
		.enter

	;
	; Call superclass FIRST to have objects apply their changes, etc.
	;
		
		mov	di, offset QuizDialogClass
		call	ObjCallSuperNoLock

		sub	sp, QUESTION_INFORMATION_BUFFER_SIZE
		mov	di, sp

	;
	; Backslash Q thing
	;
		
		push	ds
		segmov	es, ss
		segmov	ds, cs
		mov	si, offset backslashQ
		mov	cx, size backslashQ
		rep	movsb
		pop	ds

	;
	; Question label
	;
		
		mov	si, offset QuestionLabelText
		call	QuizGetText
		
		call	QuizAddComma

	;
	; Objective text
	;
		
		mov	si, offset ObjectiveText
		call	QuizGetText

		call	QuizAddComma

	;
	; Question Type
	;
		mov	si, offset QuestionTypeItemGroup
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		stosb

		call	QuizAddComma

	;
	; Group number.  Fetch the text, scan to the end, and add a
	; pound sign.
	;
		mov	si, offset GroupNumberValue
		call	QuizGetValueText
		
		
		mov	al, '#'
		stosb

		call	QuizAddComma

	;
	; Time
	;
		mov	si, offset QuestionTimeValue
		call	QuizGetValueText

		mov	al, 'm'
		stosb

		call	QuizAddComma

	;
	; Difficulty
	;
		
		mov	si, offset DifficultyIndexValue
		call	QuizGetValueText

		mov	al, 'd'
		stosb

		call	QuizAddComma


	;
	; Used count
	;
		mov	si, offset UsedCountValue
		call	QuizGetValueText

		mov	al, 'u'			; null-terminate
		stosb

		mov	ax, C_CR
		stosw


	;
	; Now, send it to the target text object.  Hope there's one
	; there! 
	;
		call	QuizGetTargetTextOD
		jnc	done

		mov	ax, MSG_VIS_TEXT_REPLACE_SELECTION_PTR
		clr	cx
		mov	dx, ss
		mov	bp, sp
		mov	di, mask MF_CALL
		call	ObjMessage
done:
		add	sp, QUESTION_INFORMATION_BUFFER_SIZE
		
		.leave
		ret
QuizDialogApply	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuizGetTargetTextOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the OD of the target text object.  

CALLED BY:	QuizDialogInitiate, QuizDialogApply

PASS:		nothing 

RETURN:		carry SET if found
			^lbx:si - OD of system target text object
		carry clear otherwise


DESTROYED:	ax,cx,dx,bp,di 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The OD is NOT guaranteed to be valid -- the text object could
	easily be destroyed when, or soon after, this procedure
	returns.  Oh well.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/16/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuizGetTargetTextOD	proc near
		.enter

		
	;
	; Get the OD of the target text object.  Note:  We have a
	; window here where the text object could be destroyed
	; between the time that we get its OD and the time that we
	; query the object for its text.  This should never happen in
	; normal usage, so I'm not too worried about it.  Some dickwad
	; tester will probably do this and crash occasionally, but who
	; cares?
	;

	;
	; First, get the target field
	;
		
		mov	ax, MSG_META_GET_TARGET_AT_TARGET_LEVEL
		mov	cx, TL_GEN_FIELD
		call	UserCallSystem	; ^lcx:dx - field OD
		clc
		jcxz	done
		
		movdw	bxsi, cxdx

	;
	; From that, get the top application.  Is this the same as the
	; "target" app?  Who knows?  There's no message to get the
	; target app.
	;
		mov	ax, MSG_GEN_FIELD_GET_TOP_GEN_APPLICATION
		mov	di, mask MF_CALL
		call	ObjMessage
		clc
		jcxz	done

		movdw	bxsi, cxdx
	;
	; Now, ask that app which object has the target.
	;
		
		mov	ax, MSG_META_GET_TARGET_AT_TARGET_LEVEL
		mov	cx, TL_TARGET
		mov	di, mask MF_CALL
		call	ObjMessage 
		clc
		jcxz	done
		movdw	bxsi, cxdx
		
	;
	; Make sure we're looking at a text object.  
	;
		
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	cx, segment VisLargeTextClass
		mov	dx, offset VisLargeTextClass
		mov	di, mask MF_CALL
		call	ObjMessage
done:
		.leave
		ret
QuizGetTargetTextOD	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuizGetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Felch some text from a text object

CALLED BY:	QuizDialogApply

PASS:		*ds:si - text object
		es:di - destination buffer

RETURN:		es:di - updated 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuizGetText	proc near

		.enter

		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	dx, es
		mov	bp, di
		call	ObjCallInstanceNoLock
		add	di, cx

		.leave
		ret
QuizGetText	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuizGetValueText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the text from the value into the text buffer

CALLED BY:	QuizDialogApply

PASS:		*ds:si - GenValue
		es:di - destination buffer

RETURN:		es:di - points at end of buffer 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuizGetValueText	proc near

		.enter

	;
	; Fetch the text
	;
		
		mov	ax, MSG_GEN_VALUE_GET_VALUE_TEXT
		mov	cx, es
		mov	dx, di
		mov	bp, GVT_VALUE
		call	ObjCallInstanceNoLock

	;
	; Scan to the end
	;
		
		clr	al
		mov	cx, -1
		repne	scasb
		dec	di

		.leave
		ret
QuizGetValueText	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuizAddComma
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a comma.  Do we really need a procedure?  Oh well.

CALLED BY:	QuizDialogApply

PASS:		es:di - text buffer

RETURN:		es:di - updated to point after comma 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuizAddComma	proc near
		
		mov	al, ','
		stosb

		ret
QuizAddComma	endp




QuizCode	ends
