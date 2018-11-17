
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Lib
FILE:		exportMoreFonts.asm

AUTHOR:		Jim DeFrisco, 5/9/91

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/9/91		Initial revision
   jfh	10/7/07	try and get sans right - he has SANS mapped to Helvetica?


DESCRIPTION:
	This file holds lots of fonts
		

	$Id: exportMoreFonts.asm,v 1.1 97/04/07 11:25:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Extended Font Sets
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;	The following resource will contain all the other Adobe font info.
;	Since the printers covered here also have the basic 35 (usually), those
;	font entries will need to be repeated.

MoreFonts	segment	resource


QMS43		label	nptr.nptr.AdobeFontEntry
		nptr	offset MoreStandard13Fonts
		nptr	offset MoreStandard35Balance
		nptr	offset MoreHelvNarrowSet
		nptr	offset MoreHelvCondensedSet
		nptr	offset AGaramondSet
		nptr	0

FullSet		label	nptr.nptr.AdobeFontEntry
Agfa74		label	nptr.nptr.AdobeFontEntry
		nptr	offset MoreStandard13Fonts
		nptr	offset MoreStandard35Balance
		nptr	offset HelvLightBlack
		nptr	offset MoreHelvNarrowSet
		nptr	offset MoreHelvCondensedSet
		nptr	offset Typewriter
		nptr	offset GaramondSet
		nptr	offset KorinnaSet
		nptr	offset LubalinSet
		nptr	offset SouvenirSet
		nptr	offset LetterGothicSet
		nptr	offset LucidaSet
		nptr	offset OptimaSet
		nptr	offset ParkAvenueSet
		nptr	0

DEC29		label	nptr.nptr.AdobeFontEntry
		nptr	offset MoreStandard13Fonts
		nptr	offset LubalinSet
		nptr	offset SouvenirSet
		nptr	offset MoreAvantGardeSet
		nptr	offset MoreNewCenturySet
		nptr	0

IBM39		label	nptr.nptr.AdobeFontEntry
		nptr	offset MoreStandard13Fonts
		nptr	offset MoreHelvNarrowSet
		nptr	offset HelvLightBlack
		nptr	offset MoreAvantGardeSet
		nptr	offset MoreBookmanSet
		nptr	offset MoreZapfSet
		nptr	offset MoreNewCenturySet
		nptr	offset MorePalatinoSet
		nptr	0

IBM43		label	nptr.nptr.AdobeFontEntry
		nptr	offset MoreStandard13Fonts
		nptr	offset HelvLightBlack
		nptr	offset MoreAvantGardeSet
		nptr	offset MoreBookmanSet
		nptr	offset GaramondSet
		nptr	offset KorinnaSet
		nptr	offset MoreZapfSet
		nptr	offset MoreNewCenturySet
		nptr	offset MorePalatinoSet
		nptr	0


IBM47		label	nptr.nptr.AdobeFontEntry
		nptr	offset Standard13Fonts
		nptr	offset MoreHelvNarrowSet
		nptr	offset HelvLightBlack
		nptr	offset MoreAvantGardeSet
		nptr	offset MoreBookmanSet
		nptr	offset GaramondSet
		nptr	offset KorinnaSet
		nptr	offset MoreZapfSet
		nptr	offset MoreNewCenturySet
		nptr	offset MorePalatinoSet
		nptr	0

Monotype8	label	nptr.nptr.AdobeFontEntry
		nptr	offset TimesNewSet
		nptr	0

Monotype70	label	nptr.nptr.AdobeFontEntry
		nptr	offset TimesNewSet
		nptr	0

Japanese2	label	nptr.nptr.AdobeFontEntry
		nptr	RyuminLightSet
		nptr	GothicBBBSet
		nptr	0

Japanese5	label	nptr.nptr.AdobeFontEntry
		nptr	RyuminLightSet
		nptr	GothicBBBSet
		nptr	0

Wang32		label	nptr.nptr.AdobeFontEntry
		nptr	offset MoreStandard13Fonts
		nptr	offset MoreHelvNarrowSet
		nptr	offset MoreAvantGardeSet
		nptr	offset MoreZapfSet
		nptr	offset MoreNewCenturySet
		nptr	offset MorePalatinoSet
		nptr	0

AdobeTC1	label	nptr.nptr.AdobeFontEntry
		nptr	offset TypeCart1Set
		nptr	0

AdobeTC2	label	nptr.nptr.AdobeFontEntry
		nptr	offset AGaramondSet
		nptr	offset HelvLightBlack
		nptr	offset BodoniSet
		nptr	offset TektonSet
		nptr	offset TypeCart2Set
		nptr	0

;------------------------------------------------------------------------
;	Standard Font Lists
;------------------------------------------------------------------------

MoreStandard13Fonts	label	nptr.AdobeFontEntry
		nptr	offset MoreTimesRoman	; FG_SERIF
		nptr	offset MoreTimesItalic
		nptr	offset MoreTimesBold
		nptr	offset MoreTimesBoldItalic
		nptr	offset MoreHelvetica	; FG_SANS_SERIF
		nptr	offset MoreHelvItalic
		nptr	offset MoreHelvBold
		nptr	offset MoreHelvBoldItalic
		nptr	offset MoreSymbol		; FG_SYMBOL
		nptr	offset MoreCourier		; FG_MONO
		nptr	offset MoreCourierItalic
		nptr	offset MoreCourierBold
		nptr	offset MoreCourierBoldItalic
		word	0			; table terminator

MoreStandard35Balance label	nptr.AdobeFontEntry
		nptr	offset MoreNewCentRoman	; FG_SERIF
		nptr	offset MoreNewCentItalic
		nptr	offset MoreNewCentBold
		nptr	offset MoreNewCentBoldItalic
		nptr	offset MorePalatinoRoman
		nptr	offset MorePalatinoItalic
		nptr	offset MorePalatinoBold
		nptr	offset MorePalatinoBoldItalic
		nptr	offset MoreBookmanLight	; for now, map light -> normal
		nptr	offset MoreBookmanItal	;          and demi  -> bold
		nptr	offset MoreBookmanDemi
		nptr	offset MoreBookmanDemiItal
		nptr	offset MoreSans		; FG_SANS_SERIF
		nptr	offset MoreSansItalic
		nptr	offset MoreSansBold
		nptr	offset MoreSansBoldItalic
		nptr	offset MoreAvantGarde	; for now, map book -> normal
		nptr	offset MoreAvantGardeObl ;          and demi -> bold
		nptr	offset MoreAvantGardeBold
		nptr	offset MoreAvantGardeBoldObl
		nptr	offset MoreZapfChancery	; FG_SCRIPT
		nptr	offset MoreZapfDingbats	
		word	0			; table terminator

MoreZapfSet	label	nptr.AdobeFontEntry
		nptr	offset MoreZapfChancery	; FG_SCRIPT
		nptr	offset MoreZapfDingbats	
		nptr	0

MorePalatinoSet	label	nptr.AdobeFontEntry
		nptr	offset MorePalatinoRoman
		nptr	offset MorePalatinoItalic
		nptr	offset MorePalatinoBold
		nptr	offset MorePalatinoBoldItalic
		nptr	0

TimesNewSet	label	nptr.AdobeFontEntry
		nptr	offset TimesNewRoman
		nptr	offset TimesNewItalic
		nptr	offset TimesNewBold
		nptr	offset TimesNewBoldItalic
		nptr	0

MoreBookmanSet	label	nptr.AdobeFontEntry
		nptr	offset MoreBookmanLight	; for now, map light -> normal
		nptr	offset MoreBookmanItal	;          and demi  -> bold
		nptr	offset MoreBookmanDemi
		nptr	offset MoreBookmanDemiItal
		nptr	0

MoreAvantGardeSet	label	nptr.AdobeFontEntry
		nptr	offset AvantGarde	; for now, map book -> normal
		nptr	offset AvantGardeObl	;          and demi -> bold
		nptr	offset AvantGardeBold
		nptr	offset AvantGardeBoldObl
		nptr	0

MoreNewCenturySet	label	nptr.AdobeFontEntry
		nptr	offset MoreNewCentRoman	; FG_SERIF
		nptr	offset MoreNewCentItalic
		nptr	offset MoreNewCentBold
		nptr	offset MoreNewCentBoldItalic
		nptr	0

MoreHelvNarrowSet label	nptr.AdobeFontEntry
		nptr	offset MoreHelvNarrow
		nptr	offset MoreHelvNarObl
		nptr	offset MoreHelvNarBold
		nptr	offset MoreHelvNarBoldObl
		nptr	0

MoreHelvCondensedSet label	nptr.AdobeFontEntry
		nptr	offset MoreHelvCondensed
		nptr	offset MoreHelvCondObl
		nptr	offset MoreHelvCondBold
		nptr	offset MoreHelvCondBoldObl
		nptr	0

HelvLightBlack label	nptr.AdobeFontEntry
		nptr	offset HelvLight
		nptr	offset HelvLightObl
		nptr	offset HelvBlack
		nptr	offset HelvBlackObl
		nptr	0

Typewriter	label	nptr.AdobeFontEntry
		nptr	offset TypeBold
		nptr	offset TypeMedium
		nptr	0

GaramondSet	label	nptr.AdobeFontEntry
		nptr	offset GaramondLight
		nptr	offset GaramondLightItal
		nptr	offset GaramondBold
		nptr	offset GaramondBoldItal
		nptr	0

KorinnaSet	label	nptr.AdobeFontEntry
		nptr	offset KorinnaReg
		nptr	offset KorinnaKursReg
		nptr	offset KorinnaBold
		nptr	offset KorinnaKursBold
		nptr	0

LubalinSet	label	nptr.AdobeFontEntry
		nptr	offset LubalinBook
		nptr	offset LubalinBookObl
		nptr	offset LubalinDemi
		nptr	offset LubalinDemiObl
		nptr	0

SouvenirSet	label	nptr.AdobeFontEntry
		nptr	offset SouvenirLight
		nptr	offset SouvenirLightItal
		nptr	offset SouvenirDemi
		nptr	offset SouvenirDemiItal
		nptr	0

LetterGothicSet	label	nptr.AdobeFontEntry
		nptr	offset LetterGothic
		nptr	offset LetterGothicSlanted
		nptr	offset LetterGothicBold
		nptr	offset LetterGothicBoldSlanted
		nptr	0

LucidaSet	label	nptr.AdobeFontEntry
		nptr	offset Lucida
		nptr	offset LucidaItalic
		nptr	offset LucidaBold
		nptr	offset LucidaBoldItalic
		nptr	0

OptimaSet	label	nptr.AdobeFontEntry
		nptr	offset Optima
		nptr	offset OptimaObl
		nptr	offset OptimaBold
		nptr	offset OptimaBoldObl
		nptr	0

ParkAvenueSet	label	nptr.AdobeFontEntry
		nptr	offset ParkAvenue
		nptr	0

RyuminLightSet	label	nptr.AdobeFontEntry
		nptr	0

GothicBBBSet	label	nptr.AdobeFontEntry
		nptr	0

TypeCart1Set	label	nptr.AdobeFontEntry
		nptr	offset BodoniPoster
		nptr	offset CooperBlack
		nptr	offset Copperplate31AB
		nptr	offset Cottonwood
		nptr	offset FranklinGothic
		nptr	offset FreestyleScript
		nptr	offset Hobo
		nptr	offset Juniper
		nptr	offset Linotext
		nptr	offset LithosBold
		nptr	offset PeignotDemi
		nptr	offset PresentScript
		nptr	offset Stencil
		nptr	offset Trajan
		nptr	offset VAGRoundedBold
		nptr	0

AGaramondSet	label	nptr.AdobeFontEntry
		nptr	offset	AGaramondReg
		nptr	offset	AGaramondItal
		nptr	offset	AGaramondBold
		nptr	offset	AGaramondBoldItal
		nptr	offset	AGaramondSBold
		nptr	offset	AGaramondSBoldItal
		nptr	0

BodoniSet	label	nptr.AdobeFontEntry
		nptr	offset	Bodoni
		nptr	offset	BodoniItal
		nptr	offset	BodoniBold
		nptr	offset	BodoniBoldItal
		nptr	0

TypeCart2Set	label	nptr.AdobeFontEntry
		nptr	offset HelvCompressed
		nptr	offset BodoniPoster
		nptr	offset BodoniBoldCond
		nptr	0

TektonSet	label	nptr.AdobeFontEntry
		nptr	offset Tekton
		nptr	offset TektonObl
		nptr	0

;------------------------------------------------------------------------
;	Fonts
;------------------------------------------------------------------------

;TimesRoman ____________________________________________________________

MoreTimesRoman	word	FID_PS_TIMES_ROMAN
		byte	length mtrname, 0, AFE_STANDARD
mtrname		char	"/Times-Roman"

MoreTimesItalic	word	FID_PS_TIMES_ROMAN
		byte	length mtriname, mask TS_ITALIC, AFE_STANDARD
mtriname	char	"/Times-Italic"

MoreTimesBold	word	FID_PS_TIMES_ROMAN
		byte	length mtrbname, mask TS_BOLD, AFE_STANDARD
mtrbname	char	"/Times-Bold"

MoreTimesBoldItalic	word	FID_PS_TIMES_ROMAN
		byte	length mtrbiname, mask TS_BOLD or mask TS_ITALIC, \
					 AFE_STANDARD
mtrbiname	char	"/Times-BoldItalic"

;TimesNewRomanPSRoman __________________________________________________

TimesNewRoman	word	FID_PS_TIMES_ROMAN
		byte	length tnrname, 0, AFE_STANDARD
tnrname		char	"/TimesNewRomanPS"

TimesNewItalic	word	FID_PS_TIMES_ROMAN
		byte	length tnriname, mask TS_ITALIC, AFE_STANDARD
tnriname	char	"/TimesNewRomanPS-Italic"

TimesNewBold	word	FID_PS_TIMES_ROMAN
		byte	length tnrbname, mask TS_BOLD, AFE_STANDARD
tnrbname	char	"/TimesNewRomanPS-Bold"

TimesNewBoldItalic	word	FID_PS_TIMES_ROMAN
		byte	length tnrbiname, mask TS_BOLD or mask TS_ITALIC, \
					 AFE_STANDARD
tnrbiname	char	"/TimesNewRomanPS-BoldItalic"

;Lucida ____________________________________________________________

Lucida		word	FID_PS_LUCIDA
		byte	length lucname, 0, AFE_STANDARD
lucname		char	"/Lucida"

LucidaItalic	word	FID_PS_LUCIDA
		byte	length luciname, mask TS_ITALIC, AFE_STANDARD
luciname	char	"/Lucida-Italic"

LucidaBold	word	FID_PS_LUCIDA
		byte	length lucbname, mask TS_BOLD, AFE_STANDARD
lucbname	char	"/Lucida-Bold"

LucidaBoldItalic	word	FID_PS_LUCIDA
		byte	length lucbiname, mask TS_BOLD or mask TS_ITALIC, \
					 AFE_STANDARD
lucbiname	char	"/Lucida-BoldItalic"

;Souvenir ________________________________________________________

SouvenirLight	word	FID_PS_SOUVENIR
		byte	length slname, 0, AFE_STANDARD
slname		char	"/Souvenir-Light"

SouvenirLightItal word	FID_PS_SOUVENIR
		byte	length sliname, mask TS_ITALIC, AFE_STANDARD
sliname		char	"/Souvenir-LightItalic"

SouvenirDemi	word	FID_PS_SOUVENIR
		byte	length slbname, mask TS_BOLD, AFE_STANDARD
slbname		char	"/Souvenir-Demi"

SouvenirDemiItal	word	FID_PS_SOUVENIR
		byte	length slbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
slbiname	char	"/Souvenir-DemiItalic"

;LubalinGraph ____________________________________________________________

LubalinBook	word	FID_PS_LUBALIN_GRAPH
		byte	length lugname, 0, AFE_STANDARD
lugname		char	"/LubalinGraph-Book"

LubalinBookObl	word	FID_PS_LUBALIN_GRAPH
		byte	length luginame, mask TS_ITALIC, AFE_STANDARD
luginame	char	"/LubalinGraph-BookOblique"

LubalinDemi	word	FID_PS_LUBALIN_GRAPH
		byte	length lugbname, mask TS_BOLD, AFE_STANDARD
lugbname	char	"/LubalinGraph-Demi"

LubalinDemiObl	word	FID_PS_LUBALIN_GRAPH
		byte	length lugbiname, mask TS_BOLD or mask TS_ITALIC, \
					 AFE_STANDARD
lugbiname	char	"/LubalinGraph-DemiOblique"

;Garamond ____________________________________________________________

GaramondLight	word	FID_PS_GARAMOND
		byte	length glname, 0, AFE_STANDARD
glname		char	"/Garamond-Light"

GaramondLightItal	word	FID_PS_GARAMOND
		byte	length gliname, mask TS_ITALIC, AFE_STANDARD
gliname		char	"/Garamond-LightItalic"

GaramondBold	word	FID_PS_GARAMOND
		byte	length gbname, mask TS_BOLD, AFE_STANDARD
gbname		char	"/Garamond-Bold"

GaramondBoldItal	word	FID_PS_GARAMOND
		byte	length gbiname, mask TS_BOLD or mask TS_ITALIC, \
					 AFE_STANDARD
gbiname		char	"/Garamond-BoldItalic"

AGaramondReg	word	FID_PS_ADOBE_GARAMOND
		byte	length aglname, 0, AFE_STANDARD
aglname		char	"/AGaramond-Regular"

AGaramondItal	word	FID_PS_ADOBE_GARAMOND
		byte	length agliname, mask TS_ITALIC, AFE_STANDARD
agliname	char	"/AGaramond-Italic"

AGaramondBold	word	FID_PS_ADOBE_GARAMOND
		byte	length aagbname, mask TS_BOLD, AFE_STANDARD
aagbname	char	"/AGaramond-Bold"

AGaramondBoldItal	word	FID_PS_ADOBE_GARAMOND
		byte	length aagbiname, mask TS_BOLD or mask TS_ITALIC, \
					 AFE_STANDARD
aagbiname	char	"/AGaramond-BoldItalic"

AGaramondSBold	word	FID_PS_ADOBE_GARAMOND
		byte	length agsbname, mask TS_BOLD, AFE_STANDARD
agsbname	char	"/AGaramond-Semibold"

AGaramondSBoldItal	word	FID_PS_ADOBE_GARAMOND
		byte	length agsbiname, mask TS_BOLD or mask TS_ITALIC, \
					 AFE_STANDARD
agsbiname	char	"/AGaramond-SemiboldItalic"

;Korinna ____________________________________________________________

KorinnaReg	word	FID_PS_KORINNA
		byte	length krname, 0, AFE_STANDARD
krname		char	"/Korinna-Regular"

KorinnaKursReg	word	FID_PS_KORINNA
		byte	length kriname, mask TS_ITALIC, AFE_STANDARD
kriname		char	"/Korinna-KursivRegular"

KorinnaBold	word	FID_PS_KORINNA
		byte	length kbname, mask TS_BOLD, AFE_STANDARD
kbname		char	"/Korinna-Bold"

KorinnaKursBold	word	FID_PS_KORINNA
		byte	length kbiname, mask TS_BOLD or mask TS_ITALIC, \
					 AFE_STANDARD
kbiname		char	"/Korinna-KursivBold"

;NewCenturySchoolbook __________________________________________________

MoreNewCentRoman	word	FID_PS_CENTURY_SCHOOLBOOK
		byte	length mncname, 0, AFE_STANDARD
mncname		char	"/NewCenturySchlbk-Roman"

MoreNewCentItalic	word	FID_PS_CENTURY_SCHOOLBOOK
		byte	length mnciname, mask TS_ITALIC, AFE_STANDARD
mnciname	char	"/NewCenturySchlbk-Italic"

MoreNewCentBold	word	FID_PS_CENTURY_SCHOOLBOOK
		byte	length mncbname, mask TS_BOLD, AFE_STANDARD
mncbname	char	"/NewCenturySchlbk-Bold"

MoreNewCentBoldItalic	word	FID_PS_CENTURY_SCHOOLBOOK
		byte	length mncbiname, mask TS_BOLD or mask TS_ITALIC, \
					 AFE_STANDARD
mncbiname	char	"/NewCenturySchlbk-BoldItalic"

;Palatino ________________________________________________________

MorePalatinoRoman	word	FID_PS_PALATINO
		byte	length mpname, 0, AFE_STANDARD
mpname		char	"/Palatino-Roman"

MorePalatinoItalic	word	FID_PS_PALATINO
		byte	length mpiname, mask TS_ITALIC, AFE_STANDARD
mpiname		char	"/Palatino-Italic"

MorePalatinoBold	word	FID_PS_PALATINO
		byte	length mpbname, mask TS_BOLD, AFE_STANDARD
mpbname		char	"/Palatino-Bold"

MorePalatinoBoldItalic	word	FID_PS_PALATINO
		byte	length mpbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
mpbiname	char	"/Palatino-BoldItalic"

;Bodoni ________________________________________________________

Bodoni		word	FID_PS_BODONI
		byte	length bodname, 0, AFE_STANDARD
bodname		char	"/Bodoni"

BodoniItal	word	FID_PS_BODONI
		byte	length bodiname, mask TS_ITALIC, AFE_STANDARD
bodiname	char	"/Bodoni-Italic"

BodoniBold	word	FID_PS_BODONI
		byte	length bodbname, mask TS_BOLD, AFE_STANDARD
bodbname	char	"/Bodoni-Bold"

BodoniBoldItal	word	FID_PS_BODONI
		byte	length bodbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
bodbiname	char	"/Bodoni-BoldItalic"

BodoniPoster	word	FID_PS_BODONI
		byte	length bodpname, mask TS_BOLD, AFE_STANDARD
bodpname	char	"/Bodoni-Poster"

BodoniBoldCond	word	FID_PS_BODONI
		byte	length bodbcname, mask TS_BOLD, AFE_STANDARD
bodbcname	char	"/Bodoni-BoldCondensed"

;Bookman ________________________________________________________

MoreBookmanLight	word	FID_PS_BOOKMAN
		byte	length mbname, 0, AFE_STANDARD
mbname		char	"/Bookman-Light"

MoreBookmanItal	word	FID_PS_BOOKMAN
		byte	length mbiname, mask TS_ITALIC, AFE_STANDARD
mbiname		char	"/Bookman-LightItalic"

MoreBookmanDemi	word	FID_PS_BOOKMAN
		byte	length mbbname, mask TS_BOLD, AFE_STANDARD
mbbname		char	"/Bookman-Demi"

MoreBookmanDemiItal	word	FID_PS_BOOKMAN
		byte	length mbbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
mbbiname	char	"/Bookman-DemiItalic"

;Helvetica ________________________________________________________

MoreHelvetica	word	FID_PS_HELVETICA
		byte	length mhname, 0, AFE_STANDARD
mhname		char	"/Helvetica"

MoreHelvItalic	word	FID_PS_HELVETICA
		byte	length mhiname, mask TS_ITALIC, AFE_STANDARD
mhiname		char	"/Helvetica-Oblique"

MoreHelvBold	word	FID_PS_HELVETICA
		byte	length mhbname, mask TS_BOLD, AFE_STANDARD
mhbname		char	"/Helvetica-Bold"

MoreHelvBoldItalic	word	FID_PS_HELVETICA
		byte	length mhbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
mhbiname	char	"/Helvetica-BoldOblique"

MoreHelvNarrow	word	FID_PS_HELVETICA
		byte	length mhnname, 0, AFE_STANDARD
mhnname		char	"/Helvetica-Narrow"

MoreHelvNarObl	word	FID_PS_HELVETICA
		byte	length mhniname, mask TS_ITALIC, AFE_STANDARD
mhniname	char	"/Helvetica-Narrow-Oblique"

MoreHelvNarBold	word	FID_PS_HELVETICA
		byte	length mhnbname, mask TS_BOLD, AFE_STANDARD
mhnbname	char	"/Helvetica-Narrow-Bold"

MoreHelvNarBoldObl word	FID_PS_HELVETICA
		byte	length mhnbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
mhnbiname	char	"/Helvetica-Narrow-BoldOblique"

MoreHelvCondensed	word	FID_PS_HELVETICA
		byte	length mhcname, 0, AFE_STANDARD
mhcname		char	"/Helvetica-Condensed"

MoreHelvCondObl	word	FID_PS_HELVETICA
		byte	length mhciname, mask TS_ITALIC, AFE_STANDARD
mhciname	char	"/Helvetica-Condensed-Oblique"

MoreHelvCondBold	word	FID_PS_HELVETICA
		byte	length mhcbname, mask TS_BOLD, AFE_STANDARD
mhcbname	char	"/Helvetica-Condensed-Bold"

MoreHelvCondBoldObl	word	FID_PS_HELVETICA
		byte	length mhcbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
mhcbiname	char	"/Helvetica-Condensed-BoldOblique"

HelvLight	word	FID_PS_HELVETICA
		byte	length hlname, 0, AFE_STANDARD
hlname		char	"/Helvetica-Light"

HelvLightObl	word	FID_PS_HELVETICA
		byte	length hliname, mask TS_ITALIC, AFE_STANDARD
hliname		char	"/Helvetica-LightOblique"

HelvBlack	word	FID_PS_HELVETICA
		byte	length hblkname, 0, AFE_STANDARD
hblkname	char	"/Helvetica-Black"

HelvBlackObl	word	FID_PS_HELVETICA
		byte	length hblkiname, mask TS_ITALIC, AFE_STANDARD
hblkiname	char	"/Helvetica-BlackOblique"

HelvCompressed	word	FID_PS_HELVETICA
		byte	length hcomname, 0, AFE_STANDARD
hcomname	char	"/Helvetica-Compressed"


;Optima ________________________________________________________

Optima		word	FID_PS_OPTIMA
		byte	length optname, 0, AFE_STANDARD
optname		char	"/Optima"

OptimaObl	word	FID_PS_OPTIMA
		byte	length optiname, mask TS_ITALIC, AFE_STANDARD
optiname	char	"/Optima-Oblique"

OptimaBold	word	FID_PS_OPTIMA
		byte	length optbname, mask TS_BOLD, AFE_STANDARD
optbname	char	"/Optima-Bold"

OptimaBoldObl	word	FID_PS_OPTIMA
		byte	length optbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
optbiname	char	"/Optima-BoldOblique"

;Sans ________________________________________________________
; jfh - as with the export fonts file
MoreSans		word	FID_PS_URW_SANS
		byte	length msname, 0, AFE_STANDARD
;msname		char	"/Helvetica"
msname		char	"/Sans"

MoreSansItalic	word	FID_PS_URW_SANS
		byte	length msiname, mask TS_ITALIC, AFE_STANDARD
;msiname		char	"/Helvetica-Oblique"
msiname		char	"/Sans-Oblique"

MoreSansBold	word	FID_PS_URW_SANS
		byte	length msbname, mask TS_BOLD, AFE_STANDARD
;msbname		char	"/Helvetica-Bold"
msbname		char	"/Sans-Bold"

MoreSansBoldItalic	word	FID_PS_URW_SANS
		byte	length msbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
;msbiname	char	"/Helvetica-BoldOblique"
msbiname	char	"/Sans-BoldOblique"

;AvanteGarde ________________________________________________________

MoreAvantGarde	word	FID_PS_AVANTE_GARDE
		byte	length magname, 0, AFE_STANDARD
magname		char	"/AvantGarde-Book"

MoreAvantGardeObl	word	FID_PS_AVANTE_GARDE
		byte	length maginame, mask TS_ITALIC, AFE_STANDARD
maginame	char	"/AvantGarde-BookOblique"

MoreAvantGardeBold	word	FID_PS_AVANTE_GARDE
		byte	length magbname, mask TS_BOLD, AFE_STANDARD
magbname	char	"/AvantGarde-Demi"

MoreAvantGardeBoldObl word	FID_PS_AVANTE_GARDE
		byte	length magbiname, mask TS_BOLD or mask TS_ITALIC, \
					 AFE_STANDARD
magbiname	char	"/AvantGarde-DemiOblique"

;Courier ________________________________________________________

MoreCourier		word	FID_PS_COURIER
		byte	length mcname, 0, AFE_STANDARD
mcname		char	"/Courier"

MoreCourierItalic	word	FID_PS_COURIER
		byte	length mciname, mask TS_ITALIC, AFE_STANDARD
mciname		char	"/Courier-Oblique"

MoreCourierBold	word	FID_PS_COURIER
		byte	length mcbname, mask TS_BOLD, AFE_STANDARD
mcbname		char	"/Courier-Bold"

MoreCourierBoldItalic word	FID_PS_COURIER
		byte	length mcbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
mcbiname	char	"/Courier-BoldOblique"

;LetterGothic ________________________________________________________

LetterGothic		word	FID_PS_LETTER_GOTHIC
		byte	length lgname, 0, AFE_STANDARD
lgname		char	"/LetterGothic"

LetterGothicSlanted	word	FID_PS_LETTER_GOTHIC
		byte	length lginame, mask TS_ITALIC, AFE_STANDARD
lginame		char	"/LetterGothic-Slanted"

LetterGothicBold	word	FID_PS_LETTER_GOTHIC
		byte	length lgbname, mask TS_BOLD, AFE_STANDARD
lgbname		char	"/LetterGothic-Bold"

LetterGothicBoldSlanted word	FID_PS_LETTER_GOTHIC
		byte	length lgbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
lgbiname	char	"/LetterGothic-BoldSlanted"

;Typewriter ________________________________________________________

TypeMedium	word	FID_PS_AMERICAN_TYPEWRITER
		byte	length tmname, 0, AFE_STANDARD
tmname		char	"/AmericanTypewriter-Medium"

TypeBold	word	FID_PS_AMERICAN_TYPEWRITER
		byte	length tbname, mask TS_BOLD, AFE_STANDARD
tbname		char	"/AmericanTypewriter-Bold"

;Symbol ________________________________________________________

MoreSymbol		word	FID_PS_SYMBOL
		byte	length msyname, 0, AFE_SYMBOL
msyname		char	"/Symbol"

;ParkAvenue ________________________________________________________

ParkAvenue	word	FID_PS_PARK_AVENUE
		byte	length paname, 0, AFE_STANDARD
paname		char	"/ParkAvenue"

;ZapfChancery ________________________________________________________

MoreZapfChancery	word	FID_PS_ZAPF_CHANCERY
		byte	length mzcname, mask TS_ITALIC, AFE_STANDARD
mzcname		char	"/ZapfChancery-MediumItalic"

;ZapfDingbats ________________________________________________________

MoreZapfDingbats	word	FID_PS_ZAPF_DINGBATS
		byte	length mzdname, 0, AFE_SPECIAL
mzdname		char	"/ZapfDingbats"

;Tekton ________________________________________________________

Tekton		word	FID_PS_TEKTON
		byte	length tekname, 0, AFE_STANDARD
tekname		char	"/Tekton"

TektonObl	word	FID_PS_TEKTON
		byte	length tekoname, mask TS_ITALIC, AFE_STANDARD
tekoname	char	"/Tekton-Oblique"

;CooperBlack ________________________________________________________

CooperBlack	word	FID_PS_COOPER_C_BLACK
		byte	length cobname, 0, AFE_STANDARD
cobname		char	"/CooperBlack"

;Copperplate ________________________________________________________

Copperplate31AB	word	FID_PS_COPPERPLATE
		byte	length coopname, 0, AFE_STANDARD
coopname	char	"/Copperplate-ThirtyOneAB"

;Cottonwood ________________________________________________________

Cottonwood	word	FID_PS_COTTONWOOD
		byte	length cotname, 0, AFE_STANDARD
cotname		char	"/Cottonwood"

;FranklinGothic ________________________________________________________

FranklinGothic	word	FID_PS_FRANKLIN_GOTHIC
		byte	length fgname, 0, AFE_STANDARD
fgname		char	"/FranklinGothic-Book"

;Freestyle ________________________________________________________

FreestyleScript	word	FID_PS_FREESTYLE_SCRIPT
		byte	length freename, 0, AFE_STANDARD
freename	char	"/FreestyleScript"

;Hobo ________________________________________________________

Hobo		word	FID_PS_HOBO
		byte	length hoboname, 0, AFE_STANDARD
hoboname	char	"/Hobo"

;Juniper ________________________________________________________

Juniper		word	FID_PS_JUNIPER
		byte	length junname, 0, AFE_STANDARD
junname		char	"/Juniper"

;Linotext ________________________________________________________

Linotext	word	FID_PS_LINOTEXT
		byte	length linoname, 0, AFE_STANDARD
linoname	char	"/Linotext"

;Lithos ________________________________________________________

LithosBold	word	FID_PS_LITHOS
		byte	length litbname, mask TS_BOLD, AFE_STANDARD
litbname	char	"/Lithos-Bold"

;Peignot ________________________________________________________

PeignotDemi	word	FID_PS_PEIGNOT
		byte	length peidname, mask TS_BOLD, AFE_STANDARD
peidname	char	"/Peignot-Demi"

;PresentScript ________________________________________________________

PresentScript	word	FID_PS_PRESENT_SCRIPT
		byte	length presname, 0, AFE_STANDARD
presname	char	"/Present"

;Stencil ________________________________________________________

Stencil		word	FID_PS_STENCIL
		byte	length stenname, 0, AFE_STANDARD
stenname	char	"/Stencil"

;Trajan ________________________________________________________

Trajan		word	FID_PS_TRAJAN
		byte	length trajname, 0, AFE_STANDARD
trajname	char	"/Trajan-Regular"

;VAGRounded ________________________________________________________

VAGRoundedBold	word	FID_PS_VAG_RUNDSCHRIFT
		byte	length vagrbname, mask TS_BOLD, AFE_STANDARD
vagrbname	char	"/VAGRounded-Bold"


MoreFonts	ends
