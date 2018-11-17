COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		stringCharTablesDBCS.asm

AUTHOR:		Gene Anderson, Sep 13, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/13/93		Initial revision


DESCRIPTION:
	DBCS version of char class tables

	$Id: stringCharTablesDBCS.asm,v 1.1 97/04/05 01:16:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


StringMod	segment	resource

	;I
	;N
	;C
	;L
	;A
	;S
	;S
controlTypeTable CharTypeStruct \
<
	<1,0,0,0,0,0,0,0>, C_SPACE-1
>,<
	<0,0,0,0,0,0,0,0>, C_TILDE
>,<
	<1,0,0,0,0,0,0,0>, C_NON_BREAKING_SPACE-1
>,<
	<0,0,0,0,0,0,0,0>, C_LAST_UNICODE_CHARACTER
>

printableTypeTable CharTypeStruct \
<
	<0,0,0,0,0,0,0,0>, C_SPACE-1
>,<
	<1,0,0,0,0,0,0,0>, C_TILDE
>,<
	<0,0,0,0,0,0,0,0>, C_NON_BREAKING_SPACE-1
>,<
	<1,0,0,0,0,0,0,0>, C_LAST_UNICODE_CHARACTER
>

graphicTypeTable CharTypeStruct \
<
	<0,0,0,0,0,0,0,0>, C_SPACE
>,<
	<1,0,0,0,0,0,0,0>, C_TILDE
>,<
	<0,0,0,0,0,0,0,0>, C_NON_BREAKING_SPACE
>,<
	<1,0,0,0,0,0,0,0>, C_EN_QUAD-1
>,<
	<0,0,0,0,0,0,0,0>, C_RIGHT_TO_LEFT_MARK
>,<
	<1,0,0,0,0,0,0,0>, C_LAST_UNICODE_CHARACTER
>

hexTypeTable CharTypeStruct \
<
	<0,0,0,0,0,0,0,0>, C_DIGIT_ZERO-1
>,<
	<1,0,0,0,0,0,0,0>, C_DIGIT_NINE
>,<
	<0,0,0,0,0,0,0,0>, C_LATIN_CAPITAL_LETTER_A-1
>,<
	<1,0,0,0,0,0,0,0>, C_LATIN_CAPITAL_LETTER_F
>,<
	<0,0,0,0,0,0,0,0>, C_LATIN_SMALL_LETTER_A-1
>,<
	<1,0,0,0,0,0,0,0>, C_LATIN_SMALL_LETTER_F
>,<
	<0,0,0,0,0,0,0,0>, C_LAST_UNICODE_CHARACTER
>

digitTypeTable CharTypeStruct \
<
	<0,0,0,0,0,0,0,0>, C_DIGIT_ZERO-1
>,<
	<1,0,0,0,0,0,0,0>, C_DIGIT_NINE
>,<
	<0,0,0,0,0,0,0,0>, C_LAST_UNICODE_CHARACTER
>

spaceTypeTable CharTypeStruct \
<
	<0,0,0,0,0,0,0,0>, C_TAB-1
>,<
	<1,0,0,0,0,0,0,0>, C_ENTER
>,<
	<0,0,0,0,0,0,0,0>, C_SPACE-1
>,<
	<1,0,0,0,0,0,0,0>, C_SPACE
>,<
	<0,0,0,0,0,0,0,0>, C_NON_BREAKING_SPACE-1
>,<
	<1,0,0,0,0,0,0,0>, C_NON_BREAKING_SPACE
>,<
	<0,0,0,0,0,0,0,0>, C_EN_QUAD-1
>,<
	<1,0,0,0,0,0,0,0>, C_ZERO_WIDTH_SPACE
>,<
	<0,0,0,0,0,0,0,0>, C_IDEOGRAPHIC_SPACE-1
>,<
	<1,0,0,0,0,0,0,0>, C_IDEOGRAPHIC_SPACE
>,<
	<0,0,0,0,0,0,0,0>, C_LAST_UNICODE_CHARACTER
>

alphaTypeTable CharTypeStruct \
<
	<0,0,0,0,0,0,0,0>, C_LATIN_CAPITAL_LETTER_A-1
>,<
	<1,0,0,0,0,0,0,0>, C_LATIN_CAPITAL_LETTER_Z
>,<
	<0,0,0,0,0,0,0,0>, C_LATIN_SMALL_LETTER_A-1
>,<
	<1,0,0,0,0,0,0,0>, C_LATIN_SMALL_LETTER_Z
>,<
	<0,0,0,0,0,0,0,0>, C_LATIN_CAPITAL_LETTER_A_GRAVE-1
>,<
	<1,0,0,0,0,0,0,0>, C_MULTIPLICATION_SIGN-1
>,<
	<0,0,0,0,0,0,0,0>, C_MULTIPLICATION_SIGN
>,<
	<1,0,0,0,0,0,0,0>, C_DIVISION_SIGN-1
>,<
	<0,0,0,0,0,0,0,0>, C_DIVISION_SIGN
>,<
	<1,0,0,0,0,0,0,0>, C_MODIFIER_LETTER_SMALL_H-1
>,<
	<0,0,0,0,0,0,0,0>, C_GREEK_CAPITAL_LETTER_ALPHA_TONOS-1
>,<
	<1,0,0,0,0,0,0,0>, C_EN_QUAD-1
>,<
	<0,0,0,0,0,0,0,0>, C_FULLWIDTH_LATIN_CAPITAL_LETTER_A-1
>,<
	<1,0,0,0,0,0,0,0>, C_FULLWIDTH_LATIN_CAPITAL_LETTER_Z
>,<
	<0,0,0,0,0,0,0,0>, C_FULLWIDTH_LATIN_SMALL_LETTER_A-1
>,<
	<1,0,0,0,0,0,0,0>, C_FULLWIDTH_LATIN_SMALL_LETTER_Z
>,<
	<0,0,0,0,0,0,0,0>, C_HALFWIDTH_KATAKANA_LETTER_WO-1
>,<
	<1,0,0,0,0,0,0,0>, C_FULLWIDTH_CENT_SIGN-1
>,<
	<0,0,0,0,0,0,0,0>, C_LAST_UNICODE_CHARACTER
>

puncTypeTable CharTypeStruct \
<
	<0,0,0,0,0,0,0,0>, C_SPACE
>,<
	<1,0,0,0,0,0,0,0>, C_SLASH
>,<
	<0,0,0,0,0,0,0,0>, C_DIGIT_NINE
>,<
	<1,0,0,0,0,0,0,0>, C_COMMERCIAL_AT
>,<
	<0,0,0,0,0,0,0,0>, C_LATIN_CAPITAL_LETTER_Z
>,<
	<1,0,0,0,0,0,0,0>, C_SPACING_GRAVE
>,<
	<0,0,0,0,0,0,0,0>, C_LATIN_SMALL_LETTER_Z
>,<
	<1,0,0,0,0,0,0,0>, C_TILDE
>,<
	<0,0,0,0,0,0,0,0>, C_NON_BREAKING_SPACE
>,<
	<1,0,0,0,0,0,0,0>, C_INVERTED_QUESTION_MARK
>,<
	<0,0,0,0,0,0,0,0>, C_MULTIPLICATION_SIGN-1
>,<
	<1,0,0,0,0,0,0,0>, C_MULTIPLICATION_SIGN
>,<
	<0,0,0,0,0,0,0,0>, C_DIVISION_SIGN-1
>,<
	<1,0,0,0,0,0,0,0>, C_DIVISION_SIGN
>,<
	<0,0,0,0,0,0,0,0>, C_NON_SPACING_GRAVE-1
>,<
	<1,0,0,0,0,0,0,0>, C_GREEK_NON_SPACING_DIAERESIS_TONOS
>,<
	<0,0,0,0,0,0,0,0>, C_EN_QUAD-1
>,<
	<1,0,0,0,0,0,0,0>, C_CIRCLED_DIGIT_ONE-1
>,<
	<0,0,0,0,0,0,0,0>, C_FORMS_LIGHT_HORIZONTAL-1
>,<
	<1,0,0,0,0,0,0,0>, C_IDEOGRAPHIC_HALF_FILL_SPACE-1
>,<
	<0,0,0,0,0,0,0,0>, C_NON_SPACING_KATAKANA_HIRAGANA_VOICED_SOUND_MARK-1
>,<
	<1,0,0,0,0,0,0,0>, C_HIRAGANA_VOICED_ITERATION_MARK
>,<
	<0,0,0,0,0,0,0,0>, C_KATAKANA_MIDDLE_DOT-1
>,<
	<1,0,0,0,0,0,0,0>, C_KATAKANA_VOICED_ITERATION_MARK
>,<
	<0,0,0,0,0,0,0,0>, C_FULLWIDTH_EXCLAMATION_MARK-1
>,<
	<1,0,0,0,0,0,0,0>, C_FULLWIDTH_SLASH
>,<
	<0,0,0,0,0,0,0,0>, C_FULLWIDTH_DIGIT_NINE
>,<
	<1,0,0,0,0,0,0,0>, C_FULLWIDTH_COMMERCIAL_AT
>,<
	<0,0,0,0,0,0,0,0>, C_FULLWIDTH_LATIN_CAPITAL_LETTER_Z
>,<
	<1,0,0,0,0,0,0,0>, C_FULLWIDTH_SPACING_GRAVE
>,<
	<0,0,0,0,0,0,0,0>, C_FULLWIDTH_LATIN_SMALL_LETTER_Z
>,<
	<1,0,0,0,0,0,0,0>, C_HALFWIDTH_KATAKANA_MIDDLE_DOT
>,<
	<0,0,0,0,0,0,0,0>, C_LAST_UNICODE_CHARACTER
>

if DBCS_PCGEOS

kanaTypeTable CharTypeStruct \
<
	<0,0,0,0,0,0,0,0>, C_HIRAGANA_LETTER_SMALL_A-1
>,<
	<1,0,0,0,0,0,0,0>, C_KATAKANA_VOICED_ITERATION_MARK
>,<
	<0,0,0,0,0,0,0,0>, C_HALFWIDTH_KATAKANA_MIDDLE_DOT-1
>,<
	<1,0,0,0,0,0,0,0>, C_HALFWIDTH_KATAKANA_VOICED_ITERATION_MARK
>,<
	<0,0,0,0,0,0,0,0>, C_LAST_UNICODE_CHARACTER
>

kanjiTypeTable CharTypeStruct \
<
	<0,0,0,0,0,0,0,0>, 0x4e00-1		;Kanji start - 1
>,<
	<1,0,0,0,0,0,0,0>, 0xa000-1		;Kanji end - 1
>,<
	<0,0,0,0,0,0,0,0>, 0xf900-1		;Kanji2 start - 1
>,<
	<1,0,0,0,0,0,0,0>, 0xfb00-1		;Kanji2 end - 1
>,<
	<0,0,0,0,0,0,0,0>, C_LAST_UNICODE_CHARACTER
>

endif

StringMod	ends

if PZ_PCGEOS

kcode	segment

nonJapaneseTypeTable CharTypeStruct \
<
	<1,0,0,0,0,0,0,0>, C_IDEOGRAPHIC_SPACE-1
>,<
	<0,0,0,0,0,0,0,0>, C_KATAKANA_VOICED_ITERATION_MARK
>,<
	<1,0,0,0,0,0,0,0>, 0x4e00-1		;Kanji start - 1
>,<
	<0,0,0,0,0,0,0,0>, 0xa000-1		;Kanji end - 1
>,<
	<1,0,0,0,0,0,0,0>, 0xf900-1		;Kanji2 start - 1
>,<
	<0,0,0,0,0,0,0,0>, 0xfb00-1		;Kanji2 end - 1
>,<
	<1,0,0,0,0,0,0,0>, C_HALFWIDTH_KATAKANA_MIDDLE_DOT-1
>,<
	<0,0,0,0,0,0,0,0>, C_HALFWIDTH_KATAKANA_VOICED_ITERATION_MARK
>,<
	<1,0,0,0,0,0,0,0>, C_LAST_UNICODE_CHARACTER
>

kcode	ends

endif

kcode	segment

wordPartTypeList	WordPartTypeStruct <
	WPT_SPACE, 		C_SPACE
>,<
	WPT_PUNCTUATION,	C_SLASH
>,<
	WPT_ALPHA_NUMERIC,	C_DIGIT_NINE
>,<
	WPT_PUNCTUATION,	C_COMMERCIAL_AT
>,<
	WPT_ALPHA_NUMERIC,	C_LATIN_CAPITAL_LETTER_Z
>,<
	WPT_PUNCTUATION,	C_SPACING_GRAVE
>,<
	WPT_ALPHA_NUMERIC,	C_LATIN_SMALL_LETTER_Z
>,<
	WPT_PUNCTUATION,	C_DELETE
>,<
	WPT_SPACE,		C_NON_BREAKING_SPACE
>,<
	WPT_PUNCTUATION,	C_INVERTED_QUESTION_MARK
>,<
	WPT_ALPHA_NUMERIC,	C_LATIN_SMALL_LETTER_T_C_CURL
>,<
	WPT_PUNCTUATION,	C_GREEK_NON_SPACING_DIAERESIS_TONOS
>,<
	WPT_ALPHA_NUMERIC,	C_EN_QUAD-1
>,<
	WPT_SPACE,		C_ZERO_WIDTH_NON_JOINER
>,<
	WPT_PUNCTUATION,	C_SUPERSCRIPT_DIGIT_ZERO-1
>,<
	WPT_OTHER,		C_IDEOGRAPHIC_SPACE-1
>,<
	WPT_SPACE,		C_IDEOGRAPHIC_SPACE
>,<
	WPT_OTHER,		C_HIRAGANA_LETTER_SMALL_A-1
>,<
	WPT_HIRAGANA,		C_HIRAGANA_VOICED_ITERATION_MARK
>,<
	WPT_KATAKANA,		C_KATAKANA_VOICED_ITERATION_MARK
>,<
	WPT_OTHER,		0x4e00-1
>,<
	WPT_KANJI,		0x9fa5
>,<
	WPT_OTHER,			C_FULLWIDTH_SLASH
>,<
	WPT_FULLWIDTH_ALPHA_NUMERIC,	C_FULLWIDTH_DIGIT_NINE
>,<
	WPT_OTHER,			C_FULLWIDTH_COMMERCIAL_AT
>,<
	WPT_FULLWIDTH_ALPHA_NUMERIC,	C_FULLWIDTH_LATIN_CAPITAL_LETTER_Z
>,<
	WPT_OTHER,			C_FULLWIDTH_SPACING_GRAVE
>,<
	WPT_FULLWIDTH_ALPHA_NUMERIC,	C_FULLWIDTH_LATIN_SMALL_LETTER_Z
>,<
	WPT_OTHER,			C_FULLWIDTH_SPACING_TILDE
>,<
	WPT_HALFWIDTH_KATAKANA, C_HALFWIDTH_KATAKANA_VOICED_ITERATION_MARK
>,<
	WPT_OTHER,		C_LAST_UNICODE_CHARACTER
>

kcode	ends
