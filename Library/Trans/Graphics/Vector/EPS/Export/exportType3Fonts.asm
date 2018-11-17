COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		exportType3Fonts.asm

AUTHOR:		Jim DeFrisco, 21 Feb 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/91		Initial revision


DESCRIPTION:
	This file contains the template for a type 3 downloaded font program
		

	$Id: exportType3Fonts.asm,v 1.1 97/04/07 11:25:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------
;	An abbreviated function header has been adopted for use here.
;	There are three parts to the header:  
;		SYNOPSIS: 	As before, this contains a brief description 
;			  	of the function
;		STACK USAGE:	As PostScript is a stack-based language,
;				this field effectively describes what is 
;				passed and what is returned.  The form of
;				this line is
;					<arg> <arg> ..  FUNCTION  <retvalue>..
;				So, the items to the left of the FUNCTION
;				name are items passed on the stack, the 
;				rightmost item in the list is the item on
;				the top of the stack.  The FUNCTION is the
;				actual function name, and the items to the
;				right are the items left on the stack when
;				the operation is completed.  Again, the right-
;				most item is the topmost item on the stack.
;				If there are no arguments or return values,
;				a dash is used instead.  As an example, the
;				PostScript operator "moveto", which consumes
;				two integers on the stack would be represented
;				as
;					<x> <y> moveto -
;
;		SIDE EFFECTS:	This section describes any other effects the
;				procedure might have, such as altering other
;				variables defined in this prolog.
;
;
;	A few coding conventions:
;		Procedure Names	- all uppercase, no more than 3 characters
;		Variable Names	- all lowercase, no more than 3 characters
;
;		The reason that the names are so short is to decrease the
;		amount of data sent to the printer.
;-----------------------------------------------------------------------


PSType3		segment	resource



;-----------------------------------------------------------------------
;	Procedure Definitions
;-----------------------------------------------------------------------

; emitVMtest	char	"vmstatus exch sub exch pop "

beginType3Header label	byte
; 	char	"000 ge { /fsaved false def}", NL
; 	char	"{/fsaved true def /fsave save def}ifelse", NL

	char	"12 dict begin", NL
	char	"/FontType 3 def", NL
	char	"/LanguageLevel 1 def", NL
	char	"/PaintType 0 def", NL

	; the character procedures are encoded into hex ascii strings, to
	; save on space.  It's not the hex ascii that saves the space, it's
	; not using procedures.  For hex strings, the VM usage is one byte
	; per character.  For procedures, which are actually just executable
	; arrays, the storage requirement is 8 bytes per element.  yikes.
	; 
	; The way we break up the 256 values in a byte are as follows.
	; 0x00-0x0d	- opcode space.
	; 0x0e-0xea	- -110 thru 110  (0 = 7c)
	; 0xeb-0xff	- -1100 thru 1100 (0 = f5) 
	;
	char	"/fops [{moveto}{rmoveto}{lineto}{rlineto}{0 rlineto}", NL
	char	"{0 exch rlineto}{curveto}{rcurveto}{closepath fill}", NL
	char	"{setcachedevice 0 0 moveto}] def", NL

	char	"/BuildGlyph {1 index begin exch /CharProcs get exch 2 copy known not", NL
	char	"{pop /.notdef}if get {dup 13 le { fops exch get exec}", NL
	char	"{dup 234 le {124 sub}{245 sub 110 mul add}ifelse}ifelse}", NL
	char	"forall end} bind def", NL
	char	"/BuildChar {1 index /Encoding get exch get", NL
	char	"1 index /BuildGlyph get exec} bind def", NL
endType3Header	label	byte

emitCPstart	char	"/CharProcs "

beginCPdefine	label	byte
	char	" dict def", NL
	char	"CharProcs begin", NL
	char	"/.notdef <> def", NL
	char	"end", NL
endCPdefine	label	byte

beginEVdefine	label	byte
	char	"/Encoding 256 array def", NL
	char	"0 1 255 {Encoding exch /.notdef put}for", NL
endEVdefine	label	byte

emitFontBBox	char	"end",NL,"/FontBBox [ "
emitFMDef	char	" def", NL
emitBBDef	char	" ] def", NL
cpstart		char	"CharProcs begin", NL
cpend		char	"currentdict end", NL

emitFontMatrix	char	"/FontMatrix "
emitDefineFont	char	" exch definefont pop",NL
;emitEndFont	label	char
		char	" MFC}ifelse", NL

emitEAend char	">",NL,"{Encoding exch dup 3 string cvs /es 2 index 100 ge",NL,\
"{(c   )}{(c  )}ifelse def es exch 1 exch putinterval es cvn put}forall", NL

PSType3		ends

