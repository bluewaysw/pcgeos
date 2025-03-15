COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Impex
MODULE:		Template Translation Library
FILE:		libMain.asm

AUTHOR: 	Jenny Greenwood, 2 September 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/2/92		Initial version

DESCRIPTION:
	This file contains the defined formats for this translation library.
		
	$Id: libFormat.asm,v 1.1 97/04/07 11:40:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Define all of the formats we support, and the structures Impex expects.
;
; If you change these, you *MUST* change the corresponding enumeration in
; CommonH/libFormat.h.
;
DefTransLib

DefTransFormat	TF_NAME_OF_FIRST_TRANSFORMAT_CONSTANT, \
		"first format name", \
		"file search string - e.g. "*.doc"", \
		0, \
		0

DefTransFormat	TF_NAME_OF_SECOND_TRANSFORMAT_CONSTANT, \
		"second format name", \
		"file search string - e.g. "*.doc"", \
		0, \
		0

EndTransLib	<mask IDC_TEXT>
