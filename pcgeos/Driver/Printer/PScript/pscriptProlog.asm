
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		pscriptProlog.asm

AUTHOR:		Jim DeFrisco, 19 Feb 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/91		Initial revision


DESCRIPTION:
	This file contains some PostScript code that is added to the beginning
	of the PostScript file.
		

	$Id: pscriptProlog.asm,v 1.1 97/04/18 11:56:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------
;       An abbreviated function header has been adopted for use here.
;       There are three parts to the header:
;               SYNOPSIS:       As before, this contains a brief description
;                               of the function
;               STACK USAGE:    As PostScript is a stack-based language,
;                               this field effectively describes what is
;                               passed and what is returned.  The form of
;                               this line is
;                                       <arg> <arg> ..  FUNCTION  <retvalue>..
;                               So, the items to the left of the FUNCTION
;                               name are items passed on the stack, the
;                               rightmost item in the list is the item on
;                               the top of the stack.  The FUNCTION is the
;                               actual function name, and the items to the
;                               right are the items left on the stack when
;                               the operation is completed.  Again, the right-
;                               most item is the topmost item on the stack.
;                               If there are no arguments or return values,
;                               a dash is used instead.  As an example, the
;                               PostScript operator "moveto", which consumes
;                               two integers on the stack would be represented
;                               as
;                                       <x> <y> moveto -
;
;               SIDE EFFECTS:   This section describes any other effects the
;                               procedure might have, such as altering other
;                               variables defined in this prolog.
;
;
;       A few coding conventions:
;               Procedure Names - all uppercase, no more than 3 characters
;               Variable Names  - all lowercase, no more than 3 characters
;
;               The reason that the names are so short is to decrease the
;               amount of data sent to the printer.
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------
;	NOTE
;	The procedures in this file make use of variables and procedures
;	defined as part of the prolog written for the PostScript Translation
;	Library.  The way that printing will work (to both an EPS file and
;	for a device) is this:  The PScript printer driver will create 
;	a file for the PostScript code to be written to, will invoke the 
;	funtion in the translation library to write out the header, will
;	copy this prolog after the other prolog, then will start to translate
;	the document.  At each page boundary, the PScript printer driver will
;	output a few page-related items like the setting of the page transform
;	and the saving/restoring of state.
;
;-----------------------------------------------------------------------

Prolog	segment	resource

beginPSProlog	label	byte
ForceRef	beginPSProlog

endPSProlog	label	byte
ForceRef	endPSProlog

Prolog	ends
