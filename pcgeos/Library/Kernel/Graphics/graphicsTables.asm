COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Graphics
FILE:		Graphics/grTables.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
		none, this file contains tables for the graphics routines


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	6/88	initial version


DESCRIPTION:
	This file contains the tables required by the graphics routines.

	$Id: graphicsTables.asm,v 1.1 97/04/05 01:13:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

;	SYSTEM PATTERNS.  The first 32 values of the pattern index (used for
;	various graphics objects) are reserved by the system.  The remaining
;	32 indices may be modified and used by an application.

sysPatt00	label	byte
		byte	10011001b		; Tile
		byte	01000010b
		byte	00100100b
		byte	10011001b
		byte	10011001b
		byte	00100100b
		byte	01000010b
		byte	10011001b

;sysPatt01	
		byte	11111011b		; Bar chart
		byte	11110101b
		byte	11111011b
		byte	11110101b
		byte	11111011b
		byte	11110101b
		byte	11111011b
		byte	11110101b

;sysPatt02	
		byte	11111111b		; Horizontal lines
		byte	00000000b
		byte	11111111b
		byte	00000000b
		byte	11111111b
		byte	00000000b
		byte	11111111b
		byte	00000000b

;sysPatt03	
		byte	01010101b		; - Vertical lines
		byte	01010101b
		byte	01010101b
		byte	01010101b
		byte	01010101b
		byte	01010101b
		byte	01010101b
		byte	01010101b

;sysPatt04	
		byte	00000001b		; - Slanting black lines n.e.
		byte	00000010b
		byte	00000100b
		byte	00001000b
		byte	00010000b
		byte	00100000b
		byte	01000000b
		byte	10000000b

;sysPatt05	
		byte	10000000b		; - Slanting black lines s.e.
		byte	01000000b
		byte	00100000b
		byte	00010000b
		byte	00001000b
		byte	00000100b
		byte	00000010b
		byte	00000001b

;sysPatt06	
		byte	11111111b		; - Checkerboard small
		byte	10001000b
		byte	10001000b
		byte	10001000b
		byte	11111111b
		byte	10001000b
		byte	10001000b
		byte	10001000b

;sysPatt07	
		byte	11111111b		; - Checkerboard large
		byte	10000000b
		byte	10000000b
		byte	10000000b
		byte	10000000b
		byte	10000000b
		byte	10000000b
		byte	10000000b

;sysPatt08	
		byte	11111111b		; - Brick wall
		byte	10000000b
		byte	10000000b
		byte	10000000b
		byte	11111111b
		byte	00001000b
		byte	00001000b
		byte	00001000b

;sysPatt09	
		byte	00001000b		; - Brick wall slanted
		byte	00011100b
		byte	00100010b
		byte	11000001b
		byte	10000000b
		byte	00000001b
		byte	00000010b
		byte	00000100b

;sysPatt10	
		byte	10001000b		; - Special
		byte	00010100b
		byte	00100010b
		byte	01000001b
		byte	10001000b
		byte	00000000b
		byte	10101010b
		byte	00000000b

;sysPatt11	
		byte	10000000b		; - Special
		byte	01000000b
		byte	00100000b
		byte	00000000b
		byte	00000010b
		byte	00000100b
		byte	00001000b
		byte	00000000b

;sysPatt12	
		byte	01000000b		; - Special
		byte	10100000b
		byte	00000000b
		byte	00000000b
		byte	00000100b
		byte	00001010b
		byte	00000000b
		byte	00000000b

;sysPatt13	
		byte	10000010b		; - Special
		byte	01000100b
		byte	00111001b
		byte	01000100b
		byte	10000010b
		byte	00000001b
		byte	00000001b
		byte	00000001b

;sysPatt14	
		byte	00000011b		; - Special
		byte	10000100b
		byte	01001000b
		byte	00110000b
		byte	00001100b
		byte	00000010b
		byte	00000001b
		byte	00000001b

;sysPatt15	
		byte	11111000b		; - Special
		byte	01110100b
		byte	00100010b
		byte	01000111b
		byte	10001111b
		byte	00010111b
		byte	00100010b
		byte	01110001b

;sysPatt16	
		byte	10000000b		; - Special
		byte	10000000b
		byte	01000001b
		byte	00111110b
		byte	00001000b
		byte	00001000b
		byte	00010100b
		byte	11100011b

;sysPatt17	
		byte	01010101b		; - Special
		byte	10100000b
		byte	01000000b
		byte	01000000b
		byte	01010101b
		byte	00001010b
		byte	00000100b
		byte	00000100b

;sysPatt18	
		byte	00010000b		; - Special
		byte	00100000b
		byte	01010100b
		byte	10101010b
		byte	11111111b
		byte	00000010b
		byte	00000100b
		byte	00001000b

;sysPatt19	
		byte	00100000b		; - Special
		byte	01010000b
		byte	10001000b
		byte	10001000b
		byte	10001000b
		byte	10001000b
		byte	00000101b
		byte	00000010b

;sysPatt20	
		byte	01110111b		; - Special
		byte	10001001b
		byte	10001111b
		byte	10001111b
		byte	01110111b
		byte	10011000b
		byte	11111000b
		byte	11111000b

;sysPatt21	
		byte	10111111b		; - Special
		byte	00000000b
		byte	10111111b
		byte	10111111b
		byte	10110000b
		byte	10110000b
		byte	10110000b
		byte	10110000b

;sysPatt22	
		byte	00000000b		; - Special
		byte	00001000b
		byte	00010100b
		byte	00101010b
		byte	01010101b
		byte	00101010b
		byte	00010100b
		byte	00001000b
;sysPatt23	
		byte	00000000b		; - Special
		byte	00000000b
		byte	00000000b
		byte	11111111b
		byte	00000000b
		byte	00000000b
		byte	00000000b
		byte	00000000b

;sysPatt24	
		byte	00010000b		; - Special
		byte	00010000b
		byte	00010000b
		byte	00010000b
		byte	00010000b
		byte	00010000b
		byte	00010000b
		byte	00010000b


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	WARNING:	DO NOT PUT ANYTHING HERE.  The system draw masks
;			continue on through the dither patterns.
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	GREY_SCALE TABLE
;
;	This is a table of 64-different grey scale levels (dither patterns).
;	The dots are distributed so as to give an even looking pattern over
;	a large area.  The order in which to fill the bits was taken from
;	Foley and Van Damm, page 601.
;
;	The labels for each 8x8 pattern indicate the percentage of coverage
;	provided.
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ditherPatterns	label	byte

;	dither64		100%
;	sysPatt25		
ditherOnes	label	byte
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b

    ;	dither63		98.4%
    ;	sysPatt26
	    
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	01111111b


    ;	dither62		96.9%
    ;	sysPatt27
	    
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	11110111b
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	01111111b

    ;	dither61		95.3%
    ;	sysPatt28
	    
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	11110111b
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	01110111b

    ;	dither60		93.75%
    ;	sysPatt29
	    
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	01110111b
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	01110111b

    ;	dither59		92.2%
    ;	sysPatt30
	    
	    byte	11111111b
	    byte	11111111b
	    byte	11111111b
	    byte	01110111b
	    byte	11111111b
	    byte	11011111b
	    byte	11111111b
	    byte	01110111b

    ;	dither58		90.1%
    ;	sysPatt31
	    
	    byte	11111111b
	    byte	11111101b
	    byte	11111111b
	    byte	01110111b
	    byte	11111111b
	    byte	11011111b
	    byte	11111111b
	    byte	01110111b

    ;	dither57		89.1%
    ;	sysPatt32
	    
	    byte	11111111b
	    byte	11111101b
	    byte	11111111b
	    byte	01110111b
	    byte	11111111b
	    byte	11011101b
	    byte	11111111b
	    byte	01110111b

    ;	dither56		87.5%
    ;	sysPatt33
	    
	    byte	11111111b
	    byte	11011101b
	    byte	11111111b
	    byte	01110111b
	    byte	11111111b
	    byte	11011101b
	    byte	11111111b
	    byte	01110111b

    ;	dither55		85.9%
    ;	sysPatt34
	    
	    byte	11111111b
	    byte	11011101b
	    byte	11111111b
	    byte	01110111b
	    byte	11111111b
	    byte	11011101b
	    byte	11111111b
	    byte	01010111b

    ;	dither54		84.4%
    ;	sysPatt35
	    
	    byte	11111111b
	    byte	11011101b
	    byte	11111111b
	    byte	01110101b
	    byte	11111111b
	    byte	11011101b
	    byte	11111111b
	    byte	01010111b

    ;	dither53		82.8%
    ;	sysPatt36
	    
	    byte	11111111b
	    byte	11011101b
	    byte	11111111b
	    byte	01110101b
	    byte	11111111b
	    byte	11011101b
	    byte	11111111b
	    byte	01010101b

    ;	dither52		81.25%
    ;	sysPatt37
	    
	    byte	11111111b
	    byte	11011101b
	    byte	11111111b
	    byte	01010101b
	    byte	11111111b
	    byte	11011101b
	    byte	11111111b
	    byte	01010101b

    ;	dither51		79.7%
    ;	sysPatt38
	    
	    byte	11111111b
	    byte	11011101b
	    byte	11111111b
	    byte	01010101b
	    byte	11111111b
	    byte	01011101b
	    byte	11111111b
	    byte	01010101b

    ;	dither50		78.1%
    ;	sysPatt39
	    
	    byte	11111111b
	    byte	11010101b
	    byte	11111111b
	    byte	01010101b
	    byte	11111111b
	    byte	01011101b
	    byte	11111111b
	    byte	01010101b

    ;	dither49		76.6%
    ;	sysPatt40
	    
	    byte	11111111b
	    byte	11010101b
	    byte	11111111b
	    byte	01010101b
	    byte	11111111b
	    byte	01010101b
	    byte	11111111b
	    byte	01010101b

    ;	dither48		75.0%
    ;	sysPatt41
	    
	    byte	11111111b
	    byte	01010101b
	    byte	11111111b
	    byte	01010101b
	    byte	11111111b
	    byte	01010101b
	    byte	11111111b
	    byte	01010101b

    ;	dither47		73.4%
    ;	sysPatt42
	    
	    byte	11111111b
	    byte	01010101b
	    byte	11111111b
	    byte	01010101b
	    byte	11111111b
	    byte	01010101b
	    byte	10111111b
	    byte	01010101b

    ;	dither46		71.9%
    ;	sysPatt43
	    
	    byte	11111111b
	    byte	01010101b
	    byte	11111011b
	    byte	01010101b
	    byte	11111111b
	    byte	01010101b
	    byte	10111111b
	    byte	01010101b

    ;	dither45		70.3%
    ;	sysPatt44
	    
	    byte	11111111b
	    byte	01010101b
	    byte	11111011b
	    byte	01010101b
	    byte	11111111b
	    byte	01010101b
	    byte	10111011b
	    byte	01010101b

    ;	dither44		68.75%
    ;	sysPatt45
	    
	    byte	11111111b
	    byte	01010101b
	    byte	10111011b
	    byte	01010101b
	    byte	11111111b
	    byte	01010101b
	    byte	10111011b
	    byte	01010101b

    ;	dither43		67.2%
    ;	sysPatt46
	    
	    byte	11111111b
	    byte	01010101b
	    byte	10111011b
	    byte	01010101b
	    byte	11101111b
	    byte	01010101b
	    byte	10111011b
	    byte	01010101b

    ;	dither42		65.6%
    ;	sysPatt47
	    
	    byte	11111110b
	    byte	01010101b
	    byte	10111011b
	    byte	01010101b
	    byte	11101111b
	    byte	01010101b
	    byte	10111011b
	    byte	01010101b

    ;	dither41		64.1%
    ;	sysPatt48
	    
	    byte	11111110b
	    byte	01010101b
	    byte	10111011b
	    byte	01010101b
	    byte	11101110b
	    byte	01010101b
	    byte	10111011b
	    byte	01010101b

    ;	dither40		62.5%
    ;	sysPatt49
	    
	    byte	11101110b
	    byte	01010101b
	    byte	10111011b
	    byte	01010101b
	    byte	11101110b
	    byte	01010101b
	    byte	10111011b
	    byte	01010101b

    ;	dither39		60.9%
    ;	sysPatt50
	    
	    byte	11101110b
	    byte	01010101b
	    byte	10111011b
	    byte	01010101b
	    byte	11101110b
	    byte	01010101b
	    byte	10101011b
	    byte	01010101b

    ;	dither38		59.4%
    ;	sysPatt51
	    
	    byte	11101110b
	    byte	01010101b
	    byte	10111010b
	    byte	01010101b
	    byte	11101110b
	    byte	01010101b
	    byte	10101011b
	    byte	01010101b

    ;	dither37		57.8%
    ;	sysPatt52
	    
	    byte	11101110b
	    byte	01010101b
	    byte	10111010b
	    byte	01010101b
	    byte	11101110b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b

    ;	dither36		56.25%
    ;	sysPatt53
	    
	    byte	11101110b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b
	    byte	11101110b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b

    ;	dither35		54.7%
    ;	sysPatt54
	    
	    byte	11101110b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b
	    byte	10101110b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b

    ;	dither34		53.1%
    ;	sysPatt55
	    
	    byte	11101010b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b
	    byte	10101110b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b

    ;	dither33		51.6%
    ;	sysPatt56
	    
	    byte	11101010b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b

    ;	dither32		50.0%
    ;	sysPatt57
	    
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b

    ;	dither31		48.4%
    ;	sysPatt58
	    
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	00010101b

    ;	dither30		46.9%
    ;	sysPatt59
	    
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	01010001b
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	00010101b

    ;	dither29		45.3%
    ;	sysPatt60
	    
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	01010001b
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	00010001b

    ;	dither28		43.75%
    ;	sysPatt61
	    
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	00010001b
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	00010001b

    ;	dither27		42.2%
    ;	sysPatt62
	    
	    byte	10101010b
	    byte	01010101b
	    byte	10101010b
	    byte	00010001b
	    byte	10101010b
	    byte	01000101b
	    byte	10101010b
	    byte	00010001b

    ;	dither26		40.6%
    ;	sysPatt63
	    
	    byte	10101010b
	    byte	01010100b
	    byte	10101010b
	    byte	00010001b
	    byte	10101010b
	    byte	01000101b
	    byte	10101010b
	    byte	00010001b

;	dither25		39.1%
    ;	sysPatt64
	
	    byte	10101010b
	    byte	01010100b
	    byte	10101010b
	    byte	00010001b
	    byte	10101010b
	    byte	01000100b
	    byte	10101010b
	    byte	00010001b

;	dither24		37.5%
    ;	sysPatt65
	
	    byte	10101010b
	    byte	01000100b
	    byte	10101010b
	    byte	00010001b
	    byte	10101010b
	    byte	01000100b
	    byte	10101010b
	    byte	00010001b

;	dither23		35.9%
    ;	sysPatt66
	
	    byte	10101010b
	    byte	01000100b
	    byte	10101010b
	    byte	00010001b
	    byte	10101010b
	    byte	01000100b
	    byte	10101010b
	    byte	00000001b

;	dither22		34.4%
    ;	sysPatt67
	
	    byte	10101010b
	    byte	01000100b
	    byte	10101010b
	    byte	00010000b
	    byte	10101010b
	    byte	01000100b
	    byte	10101010b
	    byte	00000001b

;	dither21		32.8%
    ;	sysPatt68
	
	    byte	10101010b
	    byte	01000100b
	    byte	10101010b
	    byte	00010000b
	    byte	10101010b
	    byte	01000100b
	    byte	10101010b
	    byte	00000000b

;	dither20		31.25%
    ;	sysPatt69
	
	    byte	10101010b
	    byte	01000100b
	    byte	10101010b
	    byte	00000000b
	    byte	10101010b
	    byte	01000100b
	    byte	10101010b
	    byte	00000000b

;	dither19		29.7%
    ;	sysPatt70
	
	    byte	10101010b
	    byte	01000100b
	    byte	10101010b
	    byte	00000000b
	    byte	10101010b
	    byte	00000100b
	    byte	10101010b
	    byte	00000000b

;	dither18		28.1%
    ;	sysPatt71
	
	    byte	10101010b
	    byte	01000000b
	    byte	10101010b
	    byte	00000000b
	    byte	10101010b
	    byte	00000100b
	    byte	10101010b
	    byte	00000000b

;	dither17		26.6%
    ;	sysPatt72
	
	    byte	10101010b
	    byte	01000000b
	    byte	10101010b
	    byte	00000000b
	    byte	10101010b
	    byte	00000000b
	    byte	10101010b
	    byte	00000000b

;	dither16		25.0%
    ;	sysPatt73
	
	    byte	10101010b
	    byte	00000000b
	    byte	10101010b
	    byte	00000000b
	    byte	10101010b
	    byte	00000000b
	    byte	10101010b
	    byte	00000000b

;	dither15		23.4%
    ;	sysPatt74
	
	    byte	10101010b
	    byte	00000000b
	    byte	10101010b
	    byte	00000000b
	    byte	10101010b
	    byte	00000000b
	    byte	00101010b
	    byte	00000000b

;	dither14		21.9%
    ;	sysPatt75
	
	    byte	10101010b
	    byte	00000000b
	    byte	10100010b
	    byte	00000000b
	    byte	10101010b
	    byte	00000000b
	    byte	00101010b
	    byte	00000000b

;	dither13		20.3%
    ;	sysPatt76
	
	    byte	10101010b
	    byte	00000000b
	    byte	10100010b
	    byte	00000000b
	    byte	10101010b
	    byte	00000000b
	    byte	00100010b
	    byte	00000000b

;	dither12		18.75%
    ;	sysPatt77
	
	    byte	10101010b
	    byte	00000000b
	    byte	00100010b
	    byte	00000000b
	    byte	10101010b
	    byte	00000000b
	    byte	00100010b
	    byte	00000000b

;	dither11		17.2%
    ;	sysPatt78
	
	    byte	10101010b
	    byte	00000000b
	    byte	00100010b
	    byte	00000000b
	    byte	10001010b
	    byte	00000000b
	    byte	00100010b
	    byte	00000000b

;	dither10		15.6%
    ;	sysPatt79
	
	    byte	10101000b
	    byte	00000000b
	    byte	00100010b
	    byte	00000000b
	    byte	10001010b
	    byte	00000000b
	    byte	00100010b
	    byte	00000000b

;	dither09		14.1%
    ;	sysPatt80
	
	    byte	10101000b
	    byte	00000000b
	    byte	00100010b
	    byte	00000000b
	    byte	10001000b
	    byte	00000000b
	    byte	00100010b
	    byte	00000000b

;	dither08		12.5%
    ;	sysPatt81
	
	    byte	10001000b
	    byte	00000000b
	    byte	00100010b
	    byte	00000000b
	    byte	10001000b
	    byte	00000000b
	    byte	00100010b
	    byte	00000000b

;	dither07		10.9%
    ;	sysPatt82
	
	    byte	10001000b
	    byte	00000000b
	    byte	00100010b
	    byte	00000000b
	    byte	10001000b
	    byte	00000000b
	    byte	00000010b
	    byte	00000000b

;	dither06		9.4%
    ;	sysPatt83
	
	    byte	10001000b
	    byte	00000000b
	    byte	00100000b
	    byte	00000000b
	    byte	10001000b
	    byte	00000000b
	    byte	00000010b
	    byte	00000000b

;	dither05		7.8%
    ;	sysPatt84
	
	    byte	10001000b
	    byte	00000000b
	    byte	00100000b
	    byte	00000000b
	    byte	10001000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b

;	dither04		6.25%
    ;	sysPatt85
	
	    byte	10001000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b
	    byte	10001000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b

;	dither03		4.7%
    ;	sysPatt86
	
	    byte	10001000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00001000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b

;	dither02		3.1%
    ;	sysPatt87
	
	    byte	10000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00001000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b

;	dither01		1.6%
    ;	sysPatt88
	
	    byte	10000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b

;	dither00		0%
    ;	sysPatt89
	
ditherZeroes	label	byte
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b
	    byte	00000000b

LAST_SYSTEM_DRAW_MASK		=	0x80 + 89

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	DEFAULT COLOR INDEX TABLE
;
;	This is a table of 256-different RGB values that correspond to the
;	colors assigned to the default palette.  All 4 and 8 bit/pixel
;	devices should implement this table for their default palette.
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

defPalStruct	label	byte
ForceRef	defPalStruct
	Palette <256>			; 256 entries
defaultPalette	label	byte
	byte	0x00, 0x00, 0x00 	; index 0
	byte	0x00, 0x00, 0xaa
	byte	0x00, 0xaa, 0x00
	byte	0x00, 0xaa, 0xaa	
	byte	0xaa, 0x00, 0x00	; index 4
	byte	0xaa, 0x00, 0xaa
	byte	0xaa, 0x55, 0x00
	byte	0xaa, 0xaa, 0xaa	
	byte	0x55, 0x55, 0x55	; index 8
	byte	0x55, 0x55, 0xff
	byte	0x55, 0xff, 0x55
	byte	0x55, 0xff, 0xff
	byte	0xff, 0x55, 0x55	; index c
	byte	0xff, 0x55, 0xff
	byte	0xff, 0xff, 0x55
	byte	0xff, 0xff, 0xff		

	; 16 shades of grey

	byte	0x00, 0x00, 0x00	; index 10	 0.0%
	byte	0x11, 0x11, 0x11	;		 6.7%
	byte	0x22, 0x22, 0x22	;		13.3%
	byte	0x33, 0x33, 0x33	;		20.0%
	byte	0x44, 0x44, 0x44	; index 14	26.7%
	byte	0x55, 0x55, 0x55	;		33.3%
	byte	0x66, 0x66, 0x66	;		40.0%
	byte	0x77, 0x77, 0x77	;		46.7%
	byte	0x88, 0x88, 0x88	; index 18	53.3%
	byte	0x99, 0x99, 0x99	;		60.0%
	byte	0xaa, 0xaa, 0xaa	;		67.7%
	byte	0xbb, 0xbb, 0xbb	;		73.3%
	byte	0xcc, 0xcc, 0xcc	; index 1c	80.0%
	byte	0xdd, 0xdd, 0xdd	;		87.7%
	byte	0xee, 0xee, 0xee	;		93.3%
	byte	0xff, 0xff, 0xff	;	       100.0%	

	; 8 extra slots

	byte	0x00, 0x00, 0x00	; index 20
	byte	0x00, 0x00, 0x00
	byte	0x00, 0x00, 0x00
	byte	0x00, 0x00, 0x00		
	byte	0x00, 0x00, 0x00	; index 24
	byte	0x00, 0x00, 0x00
	byte	0x00, 0x00, 0x00
	byte	0x00, 0x00, 0x00		

	; 216 entries, evenly spaced throughout the RGB space

	byte	0x00, 0x00, 0x00	; index 28
	byte	0x00, 0x00, 0x33
	byte	0x00, 0x00, 0x66
	byte	0x00, 0x00, 0x99	
	byte	0x00, 0x00, 0xcc	; index 2c
	byte	0x00, 0x00, 0xff
	byte	0x00, 0x33, 0x00
	byte	0x00, 0x33, 0x33
	byte	0x00, 0x33, 0x66	; inxed 30
	byte	0x00, 0x33, 0x99	
	byte	0x00, 0x33, 0xcc
	byte	0x00, 0x33, 0xff
	byte	0x00, 0x66, 0x00	; index 34
	byte	0x00, 0x66, 0x33
	byte	0x00, 0x66, 0x66
	byte	0x00, 0x66, 0x99	
	byte	0x00, 0x66, 0xcc	; index 38
	byte	0x00, 0x66, 0xff
	byte	0x00, 0x99, 0x00
	byte	0x00, 0x99, 0x33
	byte	0x00, 0x99, 0x66	; index 3c
	byte	0x00, 0x99, 0x99	
	byte	0x00, 0x99, 0xcc
	byte	0x00, 0x99, 0xff
	byte	0x00, 0xcc, 0x00	; index 40
	byte	0x00, 0xcc, 0x33
	byte	0x00, 0xcc, 0x66
	byte	0x00, 0xcc, 0x99	
	byte	0x00, 0xcc, 0xcc	; index 44
	byte	0x00, 0xcc, 0xff
	byte	0x00, 0xff, 0x00
	byte	0x00, 0xff, 0x33
	byte	0x00, 0xff, 0x66	; index 48
	byte	0x00, 0xff, 0x99	
	byte	0x00, 0xff, 0xcc
	byte	0x00, 0xff, 0xff
	byte	0x33, 0x00, 0x00	; index 4c
	byte	0x33, 0x00, 0x33
	byte	0x33, 0x00, 0x66
	byte	0x33, 0x00, 0x99	
	byte	0x33, 0x00, 0xcc	; index 50
	byte	0x33, 0x00, 0xff
	byte	0x33, 0x33, 0x00
	byte	0x33, 0x33, 0x33
	byte	0x33, 0x33, 0x66	; index 54
	byte	0x33, 0x33, 0x99	
	byte	0x33, 0x33, 0xcc
	byte	0x33, 0x33, 0xff
	byte	0x33, 0x66, 0x00	; index 58
	byte	0x33, 0x66, 0x33
	byte	0x33, 0x66, 0x66
	byte	0x33, 0x66, 0x99	
	byte	0x33, 0x66, 0xcc	; index 5c
	byte	0x33, 0x66, 0xff
	byte	0x33, 0x99, 0x00
	byte	0x33, 0x99, 0x33
	byte	0x33, 0x99, 0x66	; index 60
	byte	0x33, 0x99, 0x99	
	byte	0x33, 0x99, 0xcc
	byte	0x33, 0x99, 0xff
	byte	0x33, 0xcc, 0x00	; index 64
	byte	0x33, 0xcc, 0x33
	byte	0x33, 0xcc, 0x66
	byte	0x33, 0xcc, 0x99	
	byte	0x33, 0xcc, 0xcc	; index 68
	byte	0x33, 0xcc, 0xff
	byte	0x33, 0xff, 0x00
	byte	0x33, 0xff, 0x33
	byte	0x33, 0xff, 0x66	; index 6c
	byte	0x33, 0xff, 0x99	
	byte	0x33, 0xff, 0xcc
	byte	0x33, 0xff, 0xff
	byte	0x66, 0x00, 0x00	; index 70
	byte	0x66, 0x00, 0x33
	byte	0x66, 0x00, 0x66
	byte	0x66, 0x00, 0x99	
	byte	0x66, 0x00, 0xcc	; index 74
	byte	0x66, 0x00, 0xff
	byte	0x66, 0x33, 0x00
	byte	0x66, 0x33, 0x33
	byte	0x66, 0x33, 0x66	; index 78
	byte	0x66, 0x33, 0x99	
	byte	0x66, 0x33, 0xcc
	byte	0x66, 0x33, 0xff
	byte	0x66, 0x66, 0x00	; index 7c
	byte	0x66, 0x66, 0x33
	byte	0x66, 0x66, 0x66
	byte	0x66, 0x66, 0x99	
	byte	0x66, 0x66, 0xcc	; index 80
	byte	0x66, 0x66, 0xff
	byte	0x66, 0x99, 0x00
	byte	0x66, 0x99, 0x33
	byte	0x66, 0x99, 0x66	; index 84
	byte	0x66, 0x99, 0x99	
	byte	0x66, 0x99, 0xcc
	byte	0x66, 0x99, 0xff
	byte	0x66, 0xcc, 0x00	; index 88
	byte	0x66, 0xcc, 0x33
	byte	0x66, 0xcc, 0x66
	byte	0x66, 0xcc, 0x99	
	byte	0x66, 0xcc, 0xcc	; index 8c
	byte	0x66, 0xcc, 0xff
	byte	0x66, 0xff, 0x00
	byte	0x66, 0xff, 0x33
	byte	0x66, 0xff, 0x66	; index 90
	byte	0x66, 0xff, 0x99	
	byte	0x66, 0xff, 0xcc
	byte	0x66, 0xff, 0xff
	byte	0x99, 0x00, 0x00	; index 94
	byte	0x99, 0x00, 0x33
	byte	0x99, 0x00, 0x66
	byte	0x99, 0x00, 0x99	
	byte	0x99, 0x00, 0xcc	; index 98
	byte	0x99, 0x00, 0xff
	byte	0x99, 0x33, 0x00
	byte	0x99, 0x33, 0x33
	byte	0x99, 0x33, 0x66	; index 9c
	byte	0x99, 0x33, 0x99	
	byte	0x99, 0x33, 0xcc
	byte	0x99, 0x33, 0xff
	byte	0x99, 0x66, 0x00	; index a0
	byte	0x99, 0x66, 0x33
	byte	0x99, 0x66, 0x66
	byte	0x99, 0x66, 0x99	
	byte	0x99, 0x66, 0xcc	; index a4
	byte	0x99, 0x66, 0xff
	byte	0x99, 0x99, 0x00
	byte	0x99, 0x99, 0x33
	byte	0x99, 0x99, 0x66	; index a8
	byte	0x99, 0x99, 0x99	
	byte	0x99, 0x99, 0xcc
	byte	0x99, 0x99, 0xff
	byte	0x99, 0xcc, 0x00	; index ac
	byte	0x99, 0xcc, 0x33
	byte	0x99, 0xcc, 0x66
	byte	0x99, 0xcc, 0x99	
	byte	0x99, 0xcc, 0xcc	; index b0
	byte	0x99, 0xcc, 0xff
	byte	0x99, 0xff, 0x00
	byte	0x99, 0xff, 0x33
	byte	0x99, 0xff, 0x66	; index b4
	byte	0x99, 0xff, 0x99	
	byte	0x99, 0xff, 0xcc
	byte	0x99, 0xff, 0xff
	byte	0xcc, 0x00, 0x00	; index b8
	byte	0xcc, 0x00, 0x33
	byte	0xcc, 0x00, 0x66
	byte	0xcc, 0x00, 0x99	
	byte	0xcc, 0x00, 0xcc	; index bc
	byte	0xcc, 0x00, 0xff
	byte	0xcc, 0x33, 0x00
	byte	0xcc, 0x33, 0x33
	byte	0xcc, 0x33, 0x66	; index c0
	byte	0xcc, 0x33, 0x99	
	byte	0xcc, 0x33, 0xcc
	byte	0xcc, 0x33, 0xff
	byte	0xcc, 0x66, 0x00	; index c4
	byte	0xcc, 0x66, 0x33
	byte	0xcc, 0x66, 0x66
	byte	0xcc, 0x66, 0x99	
	byte	0xcc, 0x66, 0xcc	; index c8
	byte	0xcc, 0x66, 0xff
	byte	0xcc, 0x99, 0x00
	byte	0xcc, 0x99, 0x33
	byte	0xcc, 0x99, 0x66	; index cc
	byte	0xcc, 0x99, 0x99	
	byte	0xcc, 0x99, 0xcc
	byte	0xcc, 0x99, 0xff
	byte	0xcc, 0xcc, 0x00	; index d0
	byte	0xcc, 0xcc, 0x33
	byte	0xcc, 0xcc, 0x66
	byte	0xcc, 0xcc, 0x99	
	byte	0xcc, 0xcc, 0xcc	; index d4
	byte	0xcc, 0xcc, 0xff
	byte	0xcc, 0xff, 0x00
	byte	0xcc, 0xff, 0x33
	byte	0xcc, 0xff, 0x66	; index d8
	byte	0xcc, 0xff, 0x99	
	byte	0xcc, 0xff, 0xcc
	byte	0xcc, 0xff, 0xff
	byte	0xff, 0x00, 0x00	; index dc
	byte	0xff, 0x00, 0x33
	byte	0xff, 0x00, 0x66
	byte	0xff, 0x00, 0x99	
	byte	0xff, 0x00, 0xcc	; index e0
	byte	0xff, 0x00, 0xff
	byte	0xff, 0x33, 0x00
	byte	0xff, 0x33, 0x33
	byte	0xff, 0x33, 0x66	; index e4
	byte	0xff, 0x33, 0x99	
	byte	0xff, 0x33, 0xcc
	byte	0xff, 0x33, 0xff
	byte	0xff, 0x66, 0x00	; index e8
	byte	0xff, 0x66, 0x33
	byte	0xff, 0x66, 0x66
	byte	0xff, 0x66, 0x99	
	byte	0xff, 0x66, 0xcc	; index ec
	byte	0xff, 0x66, 0xff
	byte	0xff, 0x99, 0x00
	byte	0xff, 0x99, 0x33
	byte	0xff, 0x99, 0x66	; index f0
	byte	0xff, 0x99, 0x99	
	byte	0xff, 0x99, 0xcc
	byte	0xff, 0x99, 0xff
	byte	0xff, 0xcc, 0x00	; index f4
	byte	0xff, 0xcc, 0x33
	byte	0xff, 0xcc, 0x66
	byte	0xff, 0xcc, 0x99	
	byte	0xff, 0xcc, 0xcc	; index f8
	byte	0xff, 0xcc, 0xff
	byte	0xff, 0xff, 0x00
	byte	0xff, 0xff, 0x33
	byte	0xff, 0xff, 0x66	; index fc
	byte	0xff, 0xff, 0x99	
	byte	0xff, 0xff, 0xcc
	byte	0xff, 0xff, 0xff

idata	ends



GraphicsObscure	segment	resource

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	Sine table for graphics transformation routines
;
;	These two tables hold 16-bit fractional values that each represent
;	the sine of an angle (multiplied by 65536).  The 1st table has values
;	for sine from 0-90 degrees, in one degree increments, and the 2nd
;	holds values from 0.5 to 89.5 degrees, again in one degree increments.
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sinIntTable	word	00000h			;  0 degrees
		word	00478h			;  1 degree
		word	008efh			;  2 degrees
		word	00d66h			;  3 degrees
		word	011dch			;  4 degrees
		word	01650h			;  5 degrees
		word	01ac2h			;  6 degrees
		word	01f33h			;  7 degrees
		word	023a1h			;  8 degrees
		word	0280ch			;  9 degrees
		word	02c74h			; 10 degrees
		word	030d9h			; 11 degrees
		word	0353ah			; 12 degrees
		word	03996h			; 13 degrees
		word	03defh			; 14 degrees
		word	04242h			; 15 degrees
		word	04690h			; 16 degrees
		word	04ad9h			; 17 degrees
		word	04f1ch			; 18 degrees
		word	05358h			; 19 degrees
		word	0578fh			; 20 degrees
		word	05bbeh			; 21 degrees
		word	05fe6h			; 22 degrees
		word	06407h			; 23 degrees
		word	06820h			; 24 degrees
		word	06c31h			; 25 degrees
		word	07039h			; 26 degrees
		word	07439h			; 27 degrees
		word	0782fh			; 28 degrees
		word	07c1ch			; 29 degrees
		word	08000h			; 30 degrees
		word	083dah			; 31 degrees
		word	087a9h			; 32 degrees
		word	08b6dh			; 33 degrees
		word	08f27h			; 34 degrees
		word	092d6h			; 35 degrees
		word	09679h			; 36 degrees
		word	09a11h			; 37 degrees
		word	09d9ch			; 38 degrees
		word	0a11bh			; 39 degrees
		word	0a48eh			; 40 degrees
		word	0a7f3h			; 41 degrees
		word	0ab4ch			; 42 degrees
		word	0ae97h			; 43 degrees
		word	0b1d5h			; 44 degrees
		word	0b505h			; 45 degrees
		word	0b827h			; 46 degrees
		word	0bb3ah			; 47 degrees
		word	0be3fh			; 48 degrees
		word	0c135h			; 49 degrees
		word	0c41bh			; 50 degrees
		word	0c6f3h			; 51 degrees
		word	0c9bbh			; 52 degrees
		word	0cc73h			; 53 degrees
		word	0cf1ch			; 54 degrees
		word	0d1b4h			; 55 degrees
		word	0d43ch			; 56 degrees
		word	0d6b3h			; 57 degrees
		word	0d91ah			; 58 degrees
		word	0db6fh			; 59 degrees
		word	0ddb4h			; 60 degrees
		word	0dfe7h			; 61 degrees
		word	0e209h			; 62 degrees
		word	0e419h			; 63 degrees
		word	0e617h			; 64 degrees
		word	0e804h			; 65 degrees
		word	0e9deh			; 66 degrees
		word	0eba6h			; 67 degrees
		word	0ed5ch			; 68 degrees
		word	0eeffh			; 69 degrees
		word	0f090h			; 70 degrees
		word	0f20eh			; 71 degrees
		word	0f378h			; 72 degrees
		word	0f4d0h			; 73 degrees
		word	0f615h			; 74 degrees
		word	0f747h			; 75 degrees
		word	0f865h			; 76 degrees
		word	0f970h			; 77 degrees
		word	0fa68h			; 78 degrees
		word	0fb4ch			; 79 degrees
		word	0fc1ch			; 80 degrees
		word	0fcd9h			; 81 degrees
		word	0fd82h			; 82 degrees
		word	0fe18h			; 83 degrees
		word	0fe99h			; 84 degrees
		word	0ff07h			; 85 degrees
		word	0ff60h			; 86 degrees
		word	0ffa6h			; 87 degrees
		word	0ffd8h			; 88 degrees
		word	0fff6h			; 89 degrees
		word	0ffffh			; 90 degrees

sinFracTable	word	0023ch			;  0.5 degrees
		word	006b4h			;  1.5 degree
		word	00b2bh			;  2.5 degrees
		word	00fa1h			;  3.5 degrees
		word	01416h			;  4.5 degrees
		word	01889h			;  5.5 degrees
		word	01cfbh			;  6.5 degrees
		word	0216ah			;  7.5 degrees
		word	025d7h			;  8.5 degrees
		word	02a41h			;  9.5 degrees
		word	02ea7h			; 10.5 degrees
		word	0330ah			; 11.5 degrees
		word	03769h			; 12.5 degrees
		word	03bc3h			; 13.5 degrees
		word	04019h			; 14.5 degrees
		word	0446ah			; 15.5 degrees
		word	048b5h			; 16.5 degrees
		word	04cfbh			; 17.5 degrees
		word	0513bh			; 18.5 degrees
		word	05574h			; 19.5 degrees
		word	059a7h			; 20.5 degrees
		word	05dd3h			; 21.5 degrees
		word	061f8h			; 22.5 degrees
		word	06614h			; 23.5 degrees
		word	06a29h			; 24.5 degrees
		word	06e36h			; 25.5 degrees
		word	0723ah			; 26.5 degrees
		word	07635h			; 27.5 degrees
		word	07a27h			; 28.5 degrees
		word	07e0fh			; 29.5 degrees
		word	081eeh			; 30.5 degrees
		word	085c2h			; 31.5 degrees
		word	0898ch			; 32.5 degrees
		word	08d4ch			; 33.5 degrees
		word	09100h			; 34.5 degrees
		word	094a9h			; 35.5 degrees
		word	09846h			; 36.5 degrees
		word	09bd8h			; 37.5 degrees
		word	09f5dh			; 38.5 degrees
		word	0a2d6h			; 39.5 degrees
		word	0a642h			; 40.5 degrees
		word	0a9a1h			; 41.5 degrees
		word	0acf3h			; 42.5 degrees
		word	0b038h			; 43.5 degrees
		word	0b36fh			; 44.5 degrees
		word	0b698h			; 45.5 degrees
		word	0b9b2h			; 46.5 degrees
		word	0bcbeh			; 47.5 degrees
		word	0bfbch			; 48.5 degrees
		word	0c2aah			; 49.5 degrees
		word	0c589h			; 50.5 degrees
		word	0c859h			; 51.5 degrees
		word	0cb19h			; 52.5 degrees
		word	0cdcah			; 53.5 degrees
		word	0d06ah			; 54.5 degrees
		word	0d2fah			; 55.5 degrees
		word	0d57ah			; 56.5 degrees
		word	0d7e9h			; 57.5 degrees
		word	0da47h			; 58.5 degrees
		word	0dc94h			; 59.5 degrees
		word	0ded0h			; 60.5 degrees
		word	0e0fah			; 61.5 degrees
		word	0e313h			; 62.5 degrees
		word	0e51ah			; 63.5 degrees
		word	0e710h			; 64.5 degrees
		word	0e8f3h			; 65.5 degrees
		word	0eac4h			; 66.5 degrees
		word	0ec83h			; 67.5 degrees
		word	0ee30h			; 68.5 degrees
		word	0efcah			; 69.5 degrees
		word	0f151h			; 70.5 degrees
		word	0f2c5h			; 71.5 degrees
		word	0f427h			; 72.5 degrees
		word	0f575h			; 73.5 degrees
		word	0f6b0h			; 74.5 degrees
		word	0f7d9h			; 75.5 degrees
		word	0f8edh			; 76.5 degrees
		word	0f9efh			; 77.5 degrees
		word	0fadch			; 78.5 degrees
		word	0fbb7h			; 79.5 degrees
		word	0fc7dh			; 80.5 degrees
		word	0fd30h			; 81.5 degrees
		word	0fdcfh			; 82.5 degrees
		word	0fe5bh			; 83.5 degrees
		word	0fed2h			; 84.5 degrees
		word	0ff36h			; 85.5 degrees
		word	0ff86h			; 86.5 degrees
		word	0ffc2h			; 87.5 degrees
		word	0ffeah			; 88.5 degrees
		word	0fffeh			; 89.5 degrees

GraphicsObscure	ends
