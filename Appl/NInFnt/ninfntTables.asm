COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Nimbus Font Converter
FILE:		ninfntTables.asm

AUTHOR:		Gene Anderson, Apr 19, 1991

ROUTINES & TABLES:
	Name			Description
	----			-----------
EXT	MapURWToGEOS		Map URW character to GEOS character

TABLE	urwToGEOS		map of URW <--> PC/GEOS character set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/19/91		Initial revision

DESCRIPTION:
	Tables for Nimbus Font Convert

	$Id: ninfntTables.asm,v 1.1 97/04/04 16:16:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertCode	segment	resource

urwToGeos	CharConvertEntry \
	<-1,	166,	0>,  			;space
	<614,	0,  	0>,			;exclamation (!)
	<636,	0,	0>,			;quote (\")
	<638,	0,	0>,			;number sign (#)
	<512,	0,	0>,			;dollar sign ($)
	<698,	0,	0>,			;percent (%)
	<630,	0,	0>,			;ampersand (&)
	<635,	0,	0>,			;single quote (')
	<626,	0,	0>,			;left parenthesis (()
	<627,	0,	0>,			;right parenthesis ())
	<634,	0,	0>,			;asterisk (*)
	<640,	0,	0>,			;plus (+)
	<607,	0,	0>,			;comma ()
	<623,	0,	0>,			;minus (-)
	<601,	0,	0>,			;period (.)
	<622,	0,	0>,			;slash (/)
	<510,	0,	0>,			;zero (0)
	<501,	0,	0>,			;one (1)
	<502,	0,	0>,			;two (2)
	<503,	0,	0>,			;three (3)
	<504,	0,	0>,			;four (4)
	<505,	0,	0>,			;five (5)
	<506,	0,	0>,			;six (6)
	<507,	0,	0>,			;seven (7)
	<508,	0,	0>,			;eight (8)
	<509,	0,	0>,			;nine (9)
	<602,	0,	0>,			;colon (:)
	<608,	0,	0>,			;semicolon (;)
	<1111,	0,	0>,			;less than ()
	<644,	0,	0>,			;equal (=)
	<1112,	0,	0>,			;greater than ()
	<616,	0,	0>,			;question mark (?)
	<637,	0,	0>,			;at sign (@)
	<101,	0,	mask CCF_CAP>,		;capital A
	<102,	0,	mask CCF_CAP>,		;capital B
	<103,	0,	mask CCF_CAP>,		;capital C
	<104,	0,	mask CCF_CAP>,		;capital D
	<105,	0,	mask CCF_CAP>,		;capital E
	<106,	0,	mask CCF_CAP>,		;capital F
	<107,	0,	mask CCF_CAP>,		;capital G
	<108,	0,	mask CCF_CAP>,		;capital H
	<109,	0,	mask CCF_CAP>,		;capital I
	<110,	0,	mask CCF_CAP>,		;capital J
	<111,	0,	mask CCF_CAP>,		;capital K
	<112,	0,	mask CCF_CAP>,		;capital L
	<113,	0,	mask CCF_CAP>,		;capital M
	<114,	0,	mask CCF_CAP>,		;capital N
	<115,	0,	mask CCF_CAP>,		;capital O
	<116,	0,	mask CCF_CAP>,		;capital P
	<117,	0,	mask CCF_CAP>,		;capital Q
	<118,	0,	mask CCF_CAP>,		;capital R
	<119,	0,	mask CCF_CAP>,		;capital S
	<120,	0,	mask CCF_CAP>,		;capital T
	<121,	0,	mask CCF_CAP>,		;capital U
	<122,	0,	mask CCF_CAP>,		;capital V
	<123,	0,	mask CCF_CAP>,		;capital W
	<124,	0,	mask CCF_CAP>,		;capital X
	<125,	0,	mask CCF_CAP>,		;capital Y
	<126,	0,	mask CCF_CAP>,		;capital Z
	<628,	0,	0>,			;left bracket ([)
	<700,	0,	0>,			;back slash (\\)
	<629,	0,	0>,			;right bracket (])
	<1151,	0,	0>,			;ASCII circumflex (^)
	<1154,	0,	0>,			;underscore (_)
	<755,	0,	0>,			;grave (`)
	<301,	64,	0>,			;small a
	<302,	14,	mask CCF_ASCENT>,	;small b
	<303,	27,	mask CCF_MEAN>,		;small c
	<304,	35,	mask CCF_ASCENT>,	;small d
	<305,	100,	mask CCF_MEAN>,		;small e
	<306,	20,	mask CCF_ASCENT>,	;small f
	<307,	14,	mask CCF_DESCENT>,	;small g
	<308,	42,	mask CCF_ASCENT>,	;small h
	<309,	63,	mask CCF_ASCENT>,	;small i
	<310,	3,	mask CCF_DESCENT>,	;small j
	<311,	6,	mask CCF_ASCENT>,	;small k
	<312,	35,	mask CCF_ASCENT>,	;small l
	<313,	20,	mask CCF_MEAN>,		;small m
	<314,	56,	mask CCF_MEAN>,		;small n
	<315,	56,	mask CCF_MEAN>,		;small o
	<316,	17,	mask CCF_DESCENT>,	;small p
	<317,	4,	mask CCF_DESCENT>,	;small q
	<318,	49,	mask CCF_MEAN>,		;small r
	<319,	56,	mask CCF_MEAN>,		;small s
	<320,	71,	0>,			;small t
	<321,	31,	mask CCF_MEAN>,		;small u
	<322,	10,	mask CCF_MEAN>,		;small v
	<323,	18,	mask CCF_MEAN>,		;small w
	<324,	3,	mask CCF_MEAN>,		;small x
	<325,	18,	mask CCF_DESCENT>,	;small y
	<326,	2,	mask CCF_MEAN>,		;small z
	<655,	0,	0>,			;left brace ({)
	<1152,	0,	0>,			;bar (|)
	<656,	0,	0>,			;right brace (})
	<1108,	0,	0>,			;ASCII tilde (~)
	<0,	0,	0>,			;ASCII delete
	<201,	0,	mask CCF_ACCENT>,	;A dieresis
	<208,	0,	mask CCF_ACCENT>,	;A ring
	<210,	0,	mask CCF_ACCENT>,	;C cedilla
	<217,	0,	mask CCF_ACCENT>,	;E acute
	<236,	0,	mask CCF_ACCENT>,	;N tilde
	<237,	0,	mask CCF_ACCENT>,	;O dieresis
	<251,	0,	mask CCF_ACCENT>,	;U dieresis
	<402,	0,	0>,			;a acute
	<403,	0,	0>,			;a grave
	<404,	0,	0>,			;a circumflex
	<401,	0,	0>,			;a dieresis
	<407,	0,	0>,			;a tilde
	<408,	0,	0>,			;a ring
	<413,	0,	0>,			;c cedilla
	<417,	0,	0>,			;e acute
	<418,	0,	0>,			;e grave
	<419,	0,	0>,			;e circumflex
	<416,	0,	0>,			;e dieresis
	<427,	0,	0>,			;i acute
	<428,	0,	0>,			;i grave
	<429,	0,	0>,			;i circumflex
	<426,	0,	0>,			;i dieresis
	<435,	0,	0>,			;n tilde
	<437,	0,	0>,			;o acute
	<438,	0,	0>,			;o grave
	<439,	0,	0>,			;o circumflex
	<436,	0,	0>,			;o dieresis
	<440,	0,	0>,			;o tilde
	<450,	0,	0>,			;u acute
	<451,	0,	0>,			;u grave
	<452,	0,	0>,			;u circumflex
	<449,	0,	0>,			;u dieresis
	<632,	0,	0>,			;dagger
	<639,	0,	0>,			;degree
	<513,	0,	0>,			;cent
	<511,	0,	0>,			;sterling
	<631,	0,	0>,			;section
	<1016,	0,	0>,			;bullet
	<651,	0,	0>,			;paragraph
	<330,	0,	0>,			;German double S
	<796,	0,	0>,			;registered
	<795,	0,	0>,			;copyright
	<650,	0,	0>,			;trademark
	<754,	0,	0>,			;acute accent
	<751,	0,	0>,			;dieresis accent
	<1101,	0,	0>,			;not equal
	<127,	0,	mask CCF_CAP>,		;capital AE
	<129,	0,	mask CCF_CAP>,		;capital O slash
	<1124,	0,	0>,			;infinity
	<659,	0,	0>,			;plus minus
	<1113,	0,	0>,			;less than or equal
	<1114,	0,	0>,			;greater than or equal
	<516,	0,	0>,			;yen
	<2312,	0,	0>,			;lower mu
	<1137,	0,	0>,			;partial diff
	<1134,	0,	0>,			;sigma / summation
	<1133,	0,	0>,			;product
	<2316,	0,	0>,			;pi
	<1105,	0,	0>,			;integral
	<657,	0,	0>,			;ord feminine
	<658,	0,	0>,			;ord masculine
	<2124,	0,	0>,			;omega
	<327,	0,	0>,			;small ae
	<329,	0,	0>,			;small o slash
	<617,	0,	0>,			;question down
	<615,	0,	0>,			;exclamation down
	<1117,	0,	0>,			;logical not
	<1104,	0,	0>,			;root
	<514,	0,	0>,			;florin
	<1109,	0,	0>,			;approximately equal
	<2104,	0,	0>,			;delta
	<619,	0,	0>,			;guilled dbl left
	<618,	0,	0>,			;guilled dbl right
	<606,	0,	0>,			;ellipsis
	<-1,	0,	0>,			;non-brk space
	<203,	0,	mask CCF_ACCENT>,	;A grave
	<207,	0,	mask CCF_ACCENT>,	;A tilde
	<241,	0,	mask CCF_ACCENT>,	;O tilde
	<128,	0,	mask CCF_ACCENT>,	;capital OE
	<328,	0,	0>,			;small oe
	<624,	0,	0>,			;en dash
	<625,	0,	0>,			;em dash
	<612,	0,	0>,			;quote dbl left
	<611,	0,	0>,			;quote dbl right
	<610,	0,	0>,			;quote sgl left
	<609,	0,	0>,			;quote sgl right
	<643,	0,	0>,			;division
	<1049,	0,	0>,			;lozenge
	<461,	0,	0>,			;y dieresis
	<268,	0,	mask CCF_ACCENT>,	;Y dieresis
	<677,	0,	0>,			;fraction
	<652,	0,	0>,			;currency
	<621,	0,	0>,			;guilled sgl left
	<620,	0,	0>,			;guilled sgl right
	<455,	0,	0>,			;y acute
	<257,	0,	mask CCF_ACCENT>,	;Y acute
	<633,	0,	0>,			;double dagger
	<604,	0,	0>,			;centered dot
	<653,	0,	0>,			;quote sgl low
	<613,	0,	0>,			;quote dbl low
	<699,	0,	0>,			;per thousand
	<204,	0,	mask CCF_ACCENT>,	;A circumflex
	<219,	0,	mask CCF_ACCENT>,	;E circumflex
	<202,	0,	mask CCF_ACCENT>,	;A acute
	<216,	0,	mask CCF_ACCENT>,	;E dieresis
	<218,	0,	mask CCF_ACCENT>,	;E grave
	<227,	0,	mask CCF_ACCENT>,	;I acute
	<229,	0,	mask CCF_ACCENT>,	;I circumflex
	<226,	0,	mask CCF_ACCENT>,	;I dieresis
	<228,	0,	mask CCF_ACCENT>,	;I grave
	<238,	0,	mask CCF_ACCENT>,	;O acute
	<240,	0,	mask CCF_ACCENT>,	;O circumflex
	<0,	0,	0>,			;logo
	<239,	0,	mask CCF_ACCENT>,	;O grave
	<252,	0,	mask CCF_ACCENT>,	;U acute
	<254,	0,	mask CCF_ACCENT>,	;U circumflex
	<253,	0,	mask CCF_ACCENT>,	;U grave
	<331,	0,	0>,			;i dotless
	<756,	0,	0>,			;circumflex
	<759,	0,	0>,			;tilde
	<764,	0,	0>,			;macron
	<758,	0,	0>,			;breve
	<752,	0,	0>,			;dot accent
	<753,	0,	0>,			;ring accent
	<711,	0,	0>,			;cedilla
	<760,	0,	0>,			;Hungarian umlat
	<713,	0,	0>,			;ogonek
	<757,	0,	0>			;caron


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapURWToGEOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map URW character value to PC/GEOS character
CALLED BY:	CountGEOSChars()

PASS:		ax - URW character value
RETURN:		carry - set if character not found
		al - PC/GEOS character value
		bl - weight for weighted average width
		bh - CharConvFlags for character
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack	<Chars-1 eq 255>

MapURWToGEOS	proc	near
	uses	si
	.enter

	clr	si
	mov	bl, ' '				;bl <- first character in table
charLoop:
	cmp	ax, cs:urwToGeos[si].CCE_urwID	;character match?
	je	foundChar			;branch if character found

	add	si, (size CharConvertEntry)	;ds:si <- ptr to next entry
	inc	bl				;bl <- next character
	jnz	charLoop			;branch if more characters
	stc					;carry <- indicate not found
done:
	.leave
	ret

foundChar:
	mov	al, bl				;al <- Chars value
	mov	bl, cs:urwToGeos[si].CCE_weight	;bl <- weight
	mov	bh, cs:urwToGeos[si].CCE_flags	;bh <- CharConvFlags
	clc					;carry <- indicate found
	jmp	done
MapURWToGEOS	endp

ConvertCode	ends
