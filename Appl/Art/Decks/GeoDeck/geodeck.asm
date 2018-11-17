COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Artwork -- Default Card Deck
FILE:		geodeck.asm

AUTHOR:		Adam de Boor, November 1, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/1/90		Initial revision
	jon	18 oct 92	revised for 2.0
	tom	9/8/97		Added breadbox video driver support


DESCRIPTION:
	Manager file for the GeoWorks default card deck
		

	$Id: geodeck.asm,v 1.2 97/09/10 14:06:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	geos.def
include geode.def
include product.def
include ec.def
include	library.def
include resource.def
include object.def
include	graphics.def
include gstring.def
include	Objects/winC.def
include heap.def
include lmem.def
include	vm.def
include vmdef.def
include hugearr.def
include Objects/inputC.def
include deckMap.def

; SYNC_UPDATE to prevent enlarging of header as blocks are loaded. The
; beast is always opened read-only, so...
DefVMFile	DeckMap, <mask VMA_SYNC_UPDATE>, 70

;==============================================================================
;
;	Display -> Deck Map
;
;==============================================================================
DefVMBlock	DeckMap

deckMap	DeckDirectoryStruct <
	length resolutionArray		; # of supported resolutions
>
resolutionArray	DeckResStruct <
	    CGA_DISPLAY_TYPE,			; CGA
	    9,					; font size
	    2, 2,				; down-card spread
	    16, 8,				; up-card spread
	    8, 3,				; deck spread	
	    CGADeck				; map block
	>, <
	    VGA_DISPLAY_TYPE,			; VGA
	    18, 				; font size
	    4,4,				; down-card spread
	    16,16,				; up-card spread
	    16, 16,				; deck spread	
	    LargeColorDeck			; map block
	>, <
	    VGA8_DISPLAY_TYPE,			; VGA
	    18, 				; font size
	    4,4,				; down-card spread
	    16,16,				; up-card spread
	    16, 16,				; deck spread	
	    LargeColorDeck			; map block
	>, <
	    VGA24_DISPLAY_TYPE,			; VGA True Color
	    18, 				; font size
	    4,4,				; down-card spread
	    16,16,				; up-card spread
	    16, 16,				; deck spread	
	    LargeColorDeck			; map block
	>, <
	    EGA_DISPLAY_TYPE,			; EGA
	    12,					; font size
	    3,3,				; down-card spread
	    16,11,				; up-card spread
	    11, 5,				; deck spread	
	    LargeColorDeck			; map block
	>, <
	    SVGA_DISPLAY_TYPE,			; SVGA
	    18,					; font size
	    6,6,				; down-card spread
	    20,20,				; up-card spread
	    20, 20,				; deck spread	
	    LargeColorDeck			; map block
	>, <
	    SVGA8_DISPLAY_TYPE,			; SVGA
	    18,					; font size
	    6,6,				; down-card spread
	    20,20,				; up-card spread
	    20, 20,				; deck spread	
	    LargeColorDeck			; map block
	>, <
	    SVGA24_DISPLAY_TYPE,		; SVGA True Color
	    18, 				; font size
	    6,6,				; down-card spread
	    20,20,				; up-card spread
	    20,20,				; deck spread	
	    LargeColorDeck			; map block
	>, <
	    MCGA_DISPLAY_TYPE,			; MCGA
	    18, 				; font size
	    4,4,				; down-card spread
	    16,16,				; up-card spread
	    16,16,				; deck spread	
	    LargeMonoDeck			; map block
	>, <
	    HGC_DISPLAY_TYPE,			; HGC
	    12,					; font size
	    4,4,				; down-card spread
	    12,12,				; up-card spread
	    12,12,				; deck spread	
	    LargeMonoDeck			; map block
	>, <
	    TV8_DISPLAY_TYPE,			; TV
	    18, 				; font size
	    4,4,				; down-card spread
	    16,16,				; up-card spread
	    16, 16,				; deck spread	
	    LargeColorDeck			; map block
	>, <
	    TV24_DISPLAY_TYPE,			; TV True Color
	    18, 				; font size
	    4,4,				; down-card spread
	    16,16,				; up-card spread
	    16, 16,				; deck spread	
	    LargeColorDeck			; map block
	>
EndVMBlock	DeckMap

;==============================================================================
;
;	Large/Standard 4-bit Color
;
;==============================================================================

DefVMBlock	LargeColorDeck
LCDeck	DeckMapStruct	<
	; CARD BITMAPS
	<
	    LCDiamondA, LCDiamond2, LCDiamond3, LCDiamond4, LCDiamond5,
	    LCDiamond6, LCDiamond7, LCDiamond8, LCDiamond9, LCDiamondT,
	    LCDiamondJ, LCDiamondQ, LCDiamondK,

	    LCHeartA, LCHeart2, LCHeart3, LCHeart4, LCHeart5, LCHeart6,
	    LCHeart7, LCHeart8, LCHeart9, LCHeartT,
	    LCHeartJ, LCHeartQ, LCHeartK,

	    LCClubA, LCClub2, LCClub3, LCClub4, LCClub5, LCClub6,
	    LCClub7, LCClub8, LCClub9, LCClubT,
	    LCClubJ, LCClubQ, LCClubK,

	    LCSpadeA, LCSpade2, LCSpade3, LCSpade4, LCSpade5, LCSpade6,
	    LCSpade7, LCSpade8, LCSpade9, LCSpadeT,
	    LCSpadeJ, LCSpadeQ, LCSpadeK, LCSpadeA,

	    LCJoker
	>,
	LCDFrameRegion,		; Frame region (in this block)
	LCDInteriorRegion,	; Interior region (also in this block)
	LCWin,			; Card back for when game is won, if
				;  appropriate...
	length LCBackArray	; Number of backs in this deck
    >

if _NDO2000
LCBackArray	fptr	LCGeoback, LCNefertite, LCGrapes, LCClassic,
			LCPyramid, LCEagle, LCHinge, LCBubbles, LCMasks,
			LCFlowers, LCCheese, LCFractal1, LCFractal2
else
LCBackArray	fptr	LCNefertite, LCGrapes, LCClassic,
			LCPyramid, LCEagle, LCHinge, LCBubbles, LCMasks,
			LCFlowers, LCCheese, LCFractal1, LCFractal2
endif

LCDFrameRegion	word	-1, EOREGREC
		word	0, 3, 67, EOREGREC
		word	1, 1, 2, 68, 69, EOREGREC
		word	2, 1, 1, 69, 69, EOREGREC
		word	96, 0, 0, 70, 70, EOREGREC
		word	97, 1, 1, 69, 69, EOREGREC
		word	98, 1, 2, 68, 69, EOREGREC
		word	99, 3, 67, EOREGREC
		word	EOREGREC

LCDInteriorRegion word	0, EOREGREC
		word	1, 3, 67, EOREGREC
		word	2, 2, 68, EOREGREC
		word	96, 1, 69, EOREGREC
		word	97, 2, 68, EOREGREC
		word	98, 3, 67, EOREGREC
		word	EOREGREC

EndVMBlock	LargeColorDeck

DefVMBlock	LCJokerBlock
include LCJoker.asm
EndVMBlock	LCJokerBlock

DefVMBlock	LCWinBlock
include LCWin.asm
EndVMBlock	LCWinBlock

DefVMBlock	LCGeobackBlock
include LCGeoback.asm
EndVMBlock	LCGeobackBlock

DefVMBlock	LCNefertiteBlock
include LCNefertite.asm
EndVMBlock	LCNefertiteBlock

DefVMBlock	LCGrapesBlock
include LCGrapes.asm
EndVMBlock	LCGrapesBlock

DefVMBlock	LCClassicBlock
include LCClassic.asm
EndVMBlock	LCClassicBlock

DefVMBlock	LCPyramidBlock
include LCPyramid.asm
EndVMBlock	LCPyramidBlock

DefVMBlock	LCEagleBlock
include LCEagle.asm
EndVMBlock	LCEagleBlock

DefVMBlock	LCHingeBlock
include LCHinge.asm
EndVMBlock	LCHingeBlock

DefVMBlock	LCBubblesBlock
include LCBubbles.asm
EndVMBlock	LCBubblesBlock

DefVMBlock	LCMasksBlock
include LCMasks.asm
EndVMBlock	LCMasksBlock

DefVMBlock	LCFlowersBlock
include LCFlowers.asm
EndVMBlock	LCFlowersBlock

DefVMBlock	LCCheeseBlock
include LCCheese.asm
EndVMBlock	LCCheeseBlock

DefVMBlock	LCFractal1Block
include LCFractal1.asm
EndVMBlock	LCFractal1Block

DefVMBlock	LCFractal2Block
include LCFractal2.asm
EndVMBlock	LCFractal2Block

DefVMBlock	LCClubJBlock
include LCClubJ.asm
EndVMBlock	LCClubJBlock

DefVMBlock	LCClubKBlock
include LCClubK.asm
EndVMBlock	LCClubKBlock

DefVMBlock	LCClubQBlock
include LCClubQ.asm
EndVMBlock	LCClubQBlock

DefVMBlock	LCDiamondJBlock
include LCDiamondJ.asm
EndVMBlock	LCDiamondJBlock

DefVMBlock	LCDiamondKBlock
include LCDiamondK.asm
EndVMBlock	LCDiamondKBlock

DefVMBlock	LCDiamondQBlock
include LCDiamondQ.asm
EndVMBlock	LCDiamondQBlock

DefVMBlock	LCHeartJBlock
include LCHeartJ.asm
EndVMBlock	LCHeartJBlock

DefVMBlock	LCHeartKBlock
include LCHeartK.asm
EndVMBlock	LCHeartKBlock

DefVMBlock	LCHeartQBlock
include LCHeartQ.asm
EndVMBlock	LCHeartQBlock

DefVMBlock	LCSpadeJBlock
include LCSpadeJ.asm
EndVMBlock	LCSpadeJBlock

DefVMBlock	LCSpadeKBlock
include LCSpadeK.asm
EndVMBlock	LCSpadeKBlock

DefVMBlock	LCSpadeQBlock
include LCSpadeQ.asm
EndVMBlock	LCSpadeQBlock

DefVMBlock	LCNonFaceDiamond
include LCDiamond2.asm
include LCDiamond3.asm
include LCDiamond4.asm
include LCDiamond5.asm
include LCDiamond6.asm
include LCDiamond7.asm
include LCDiamond8.asm
include LCDiamond9.asm
include LCDiamondA.asm
include LCDiamondT.asm
EndVMBlock	LCNonFaceDiamond

DefVMBlock	LCNonFaceHeart
include LCHeart2.asm
include LCHeart3.asm
include LCHeart4.asm
include LCHeart5.asm
include LCHeart6.asm
include LCHeart7.asm
include LCHeart8.asm
include LCHeart9.asm
include LCHeartA.asm
include LCHeartT.asm
EndVMBlock	LCNonFaceHeart

DefVMBlock	LCNonFaceClub
include LCClub2.asm
include LCClub3.asm
include LCClub4.asm
include LCClub5.asm
include LCClub6.asm
include LCClub7.asm
include LCClub8.asm
include LCClub9.asm
include LCClubA.asm
include LCClubT.asm
EndVMBlock	LCNonFaceClub

DefVMBlock	LCNonFaceSpade
include LCSpade2.asm
include LCSpade3.asm
include LCSpade4.asm
include LCSpade5.asm
include LCSpade6.asm
include LCSpade7.asm
include LCSpade8.asm
include LCSpade9.asm
include LCSpadeA.asm
include LCSpadeT.asm
EndVMBlock	LCNonFaceSpade

;==============================================================================
;
;	Large/Standard Monochrome
;
;==============================================================================

DefVMBlock	LargeMonoDeck
LMDeck	DeckMapStruct	<
	; CARD BITMAPS
	<
	    LMDiamondA, LMDiamond2, LMDiamond3, LMDiamond4, LMDiamond5,
	    LMDiamond6, LMDiamond7, LMDiamond8, LMDiamond9, LMDiamondT,
	    LMDiamondJ, LMDiamondQ, LMDiamondK,

	    LMHeartA, LMHeart2, LMHeart3, LMHeart4, LMHeart5, LMHeart6,
	    LMHeart7, LMHeart8, LMHeart9, LMHeartT,
	    LMHeartJ, LMHeartQ, LMHeartK,

	    LMClubA, LMClub2, LMClub3, LMClub4, LMClub5, LMClub6,
	    LMClub7, LMClub8, LMClub9, LMClubT,
	    LMClubJ, LMClubQ, LMClubK,

	    LMSpadeA, LMSpade2, LMSpade3, LMSpade4, LMSpade5, LMSpade6,
	    LMSpade7, LMSpade8, LMSpade9, LMSpadeT,
	    LMSpadeJ, LMSpadeQ, LMSpadeK, LMSpadeA,

	    LMJoker
	>,
	LMDFrameRegion,		; Frame region (in this block)
	LMDInteriorRegion,	; Interior region (also in this block)
	LMWin,			; Card back for when game is won, if
				;  appropriate...
	length LMBackArray	; Number of backs in this deck
    >

LMBackArray	fptr	LMGeoback, LMNefertite, LMGrapes, LMClassic,
			LMPyramid, LMEagle, LMHinge, LMBubbles, LMMasks,
			LMFlowers, LMCheese, LMFractal1, LMFractal2

LMDFrameRegion	word	-1, EOREGREC
		word	0, 3, 67, EOREGREC
		word	1, 1, 2, 68, 69, EOREGREC
		word	2, 1, 1, 69, 69, EOREGREC
		word	96, 0, 0, 70, 70, EOREGREC
		word	97, 1, 1, 69, 69, EOREGREC
		word	98, 1, 2, 68, 69, EOREGREC
		word	99, 3, 67, EOREGREC
		word	EOREGREC

LMDInteriorRegion word	0, EOREGREC
		word	1, 3, 67, EOREGREC
		word	2, 2, 68, EOREGREC
		word	96, 1, 69, EOREGREC
		word	97, 2, 68, EOREGREC
		word	98, 3, 67, EOREGREC
		word	EOREGREC

EndVMBlock	LargeMonoDeck

DefVMBlock	LMJokerBlock
include LMJoker.asm
EndVMBlock	LMJokerBlock

DefVMBlock	LMWinBlock
include LMWin.asm
EndVMBlock	LMWinBlock

DefVMBlock	LMBackBlock1
include LMGeoback.asm
include LMNefertite.asm
include LMGrapes.asm
include LMClassic.asm
EndVMBlock	LMBackBlock1

DefVMBlock	LMBackBlock2
include LMPyramid.asm
include LMEagle.asm
include LMHinge.asm
include LMBubbles.asm
include LMMasks.asm
EndVMBlock	LMBackBlock2

DefVMBlock	LMBackBlock3
include LMFlowers.asm
include LMCheese.asm
include LMFractal1.asm
include LMFractal2.asm
EndVMBlock	LMBackBlock3

DefVMBlock	LMFaceClub
include LMClubJ.asm
include LMClubK.asm
include LMClubQ.asm
EndVMBlock	LMFaceClub

DefVMBlock	LMFaceDiamond
include LMDiamondJ.asm
include LMDiamondK.asm
include LMDiamondQ.asm
EndVMBlock	LMFaceDiamond

DefVMBlock	LMFaceHeart
include LMHeartJ.asm
include LMHeartK.asm
include LMHeartQ.asm
EndVMBlock	LMFaceHeart

DefVMBlock	LMFaceSpade
include LMSpadeJ.asm
include LMSpadeK.asm
include LMSpadeQ.asm
EndVMBlock	LMFaceSpade

DefVMBlock	LMNonFaceDiamond
include LMDiamond2.asm
include LMDiamond3.asm
include LMDiamond4.asm
include LMDiamond5.asm
include LMDiamond6.asm
include LMDiamond7.asm
include LMDiamond8.asm
include LMDiamond9.asm
include LMDiamondA.asm
include LMDiamondT.asm
EndVMBlock	LMNonFaceDiamond

DefVMBlock	LMNonFaceClub
include LMClub2.asm
include LMClub3.asm
include LMClub4.asm
include LMClub5.asm
include LMClub6.asm
include LMClub7.asm
include LMClub8.asm
include LMClub9.asm
include LMClubA.asm
include LMClubT.asm
EndVMBlock	LMNonFaceClub


DefVMBlock	LMNonFaceSpade
include LMSpade2.asm
include LMSpade3.asm
include LMSpade4.asm
include LMSpade5.asm
include LMSpade6.asm
include LMSpade7.asm
include LMSpade8.asm
include LMSpade9.asm
include LMSpadeA.asm
include LMSpadeT.asm
EndVMBlock	LMNonFaceSpade

DefVMBlock	LMNonFaceHeart
include LMHeart2.asm
include LMHeart3.asm
include LMHeart4.asm
include LMHeart5.asm
include LMHeart6.asm
include LMHeart7.asm
include LMHeart8.asm
include LMHeart9.asm
include LMHeartA.asm
include LMHeartT.asm
EndVMBlock	LMNonFaceHeart

;==============================================================================
;
;	CGA
;
;==============================================================================

DefVMBlock	CGADeck
DeckMapStruct	<
	; CARD BITMAPS
	<
	    CGADiamondA, CGADiamond2, CGADiamond3, CGADiamond4, CGADiamond5,
	    CGADiamond6, CGADiamond7, CGADiamond8, CGADiamond9, CGADiamondT,
	    CGADiamondJ, CGADiamondQ, CGADiamondK,

	    CGAHeartA, CGAHeart2, CGAHeart3, CGAHeart4, CGAHeart5, CGAHeart6,
	    CGAHeart7, CGAHeart8, CGAHeart9, CGAHeartT,
	    CGAHeartJ, CGAHeartQ, CGAHeartK,

	    CGAClubA, CGAClub2, CGAClub3, CGAClub4, CGAClub5, CGAClub6,
	    CGAClub7, CGAClub8, CGAClub9, CGAClubT,
	    CGAClubJ, CGAClubQ, CGAClubK,

	    CGASpadeA, CGASpade2, CGASpade3, CGASpade4, CGASpade5, CGASpade6,
	    CGASpade7, CGASpade8, CGASpade9, CGASpadeT,
	    CGASpadeJ, CGASpadeQ, CGASpadeK, CGASpadeA,

	    CGAJoker
	>,
	CGADFrameRegion,		; Frame region (in this block)
	CGADInteriorRegion,	; Interior region (also in this block)
	CGAWin,			; Card back for when game is won, if
				;  appropriate...
	length CGABackArray	; Number of backs in this deck
    >

CGABackArray	fptr	CGAGeoback, CGANefertite, CGAGrapes, CGAClassic,
			CGAPyramid, CGAEagle, CGAHinge, CGABubbles, CGAMasks,
			CGAFlowers, CGACheese, CGAFractal1, CGAFractal2

CGADFrameRegion	word	-1, EOREGREC
		word	0, 2, 64, EOREGREC
		word	1, 1, 1, 65, 65, EOREGREC
		word	38, 0, 0, 66, 66, EOREGREC
		word	39, 1, 1, 65, 65, EOREGREC
		word	40, 2, 64, EOREGREC
		word	EOREGREC

CGADInteriorRegion word	0, EOREGREC
		word	1, 2, 64, EOREGREC
		word	38, 1, 65, EOREGREC
		word	39, 2, 64, EOREGREC
		word	EOREGREC

EndVMBlock	CGADeck

DefVMBlock	CGABackBlock
include CGAJoker.asm
include CGAWin.asm
include CGAGeoback.asm
include CGANefertite.asm
include CGAGrapes.asm
include CGAClassic.asm
include CGAPyramid.asm
include CGAEagle.asm
include CGAHinge.asm
include CGABubbles.asm
include CGAMasks.asm
include CGAFlowers.asm
include CGACheese.asm
include CGAFractal1.asm
include CGAFractal2.asm
EndVMBlock	CGABackBlock

DefVMBlock	CGAFaceClub
include CGAClubJ.asm
include CGAClubK.asm
include CGAClubQ.asm
EndVMBlock	CGAFaceClub

DefVMBlock	CGAFaceDiamond
include CGADiamondJ.asm
include CGADiamondK.asm
include CGADiamondQ.asm
EndVMBlock	CGAFaceDiamond

DefVMBlock	CGAFaceHeart
include CGAHeartJ.asm
include CGAHeartK.asm
include CGAHeartQ.asm
EndVMBlock	CGAFaceHeart

DefVMBlock	CGAFaceSpade
include CGASpadeJ.asm
include CGASpadeK.asm
include CGASpadeQ.asm
EndVMBlock	CGAFaceSpade

DefVMBlock	CGANonFaceDiamond
include CGADiamond2.asm
include CGADiamond3.asm
include CGADiamond4.asm
include CGADiamond5.asm
include CGADiamond6.asm
include CGADiamond7.asm
include CGADiamond8.asm
include CGADiamond9.asm
include CGADiamondA.asm
include CGADiamondT.asm
EndVMBlock	CGANonFaceDiamond

DefVMBlock	CGANonFaceClub
include CGAClub2.asm
include CGAClub3.asm
include CGAClub4.asm
include CGAClub5.asm
include CGAClub6.asm
include CGAClub7.asm
include CGAClub8.asm
include CGAClub9.asm
include CGAClubA.asm
include CGAClubT.asm
EndVMBlock	CGANonFaceClub


DefVMBlock	CGANonFaceSpade
include CGASpade2.asm
include CGASpade3.asm
include CGASpade4.asm
include CGASpade5.asm
include CGASpade6.asm
include CGASpade7.asm
include CGASpade8.asm
include CGASpade9.asm
include CGASpadeA.asm
include CGASpadeT.asm
EndVMBlock	CGANonFaceSpade

DefVMBlock	CGANonFaceHeart
include CGAHeart2.asm
include CGAHeart3.asm
include CGAHeart4.asm
include CGAHeart5.asm
include CGAHeart6.asm
include CGAHeart7.asm
include CGAHeart8.asm
include CGAHeart9.asm
include CGAHeartA.asm
include CGAHeartT.asm
EndVMBlock	CGANonFaceHeart

