COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		mainQuiz.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/16/93   	Initial version.

DESCRIPTION:
	

	$Id: mainQuiz.asm,v 1.1 97/04/04 16:52:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupDoQuizDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Bring up the old quiz dialog, unless this is a student

PASS:		*ds:si	- StartupClass object
		ds:di	- StartupClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/16/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StartupDoQuizDialog	method	dynamic	StartupClass, 
					MSG_STARTUP_DO_QUIZ_DIALOG
		.enter
		call	IclasGetCurrentUserType
		cmp	ah, UT_GENERIC
		je	done
		cmp	ah, UT_STUDENT
		je	done

		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	bx, handle QuestionEditDialog
		mov	si, offset QuestionEditDialog
		clr	di
		call	ObjMessage
done:
		.leave
		ret
StartupDoQuizDialog	endm


CommonCode	ends
