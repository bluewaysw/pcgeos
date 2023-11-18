/***********************************************************************
 *
 *                      Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttcharmapper.c
 *
 * AUTHOR:	  Jirka Kunze: December 5 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/5/22	  JK	    Initial version
 *
 * DESCRIPTION:
 *	Functions for mapping character from FreeGEOS charset zu Unicode 
 *      charset.
 ***********************************************************************/

#include <ttcharmapper.h>
#include <freetype.h>
#include <geos.h>
#include <unicode.h>

#define NUM_CHARMAPENTRIES      ( sizeof(geosCharMap) / sizeof(CharMapEntry) )
#define MIN_GEOS_CHAR           ( C_SPACE )
#define MAX_GEOS_CHAR           ( NUM_CHARMAPENTRIES + MIN_GEOS_CHAR )
#define GEOS_CHAR_INDEX( i )    ( i - MIN_GEOS_CHAR )


//TODO: put geosCharMap into movable ressource
CharMapEntry geosCharMap[] = 
{
/*      unicode                                 flags           ttIndex   */
        C_SPACE,                                0,              0,
        C_EXCLAMATION_MARK,                     0,              0,
        C_QUOTATION_MARK,                       0,              0,
        C_NUMBER_SIGN,                          0,              0,
        C_DOLLAR_SIGN,                          0,              0,
        C_PERCENT_SIGN,                         0,              0,
        C_AMPERSAND,                            0,              0,
        C_APOSTROPHE_QUOTE,                     0,              0,
        C_OPENING_PARENTHESIS,                  0,              0,
        C_CLOSING_PARENTHESIS,                  0,              0,
        C_ASTERISK,                             0,              0,
        C_PLUS_SIGN,                            0,              0,
        C_COMMA,                                0,              0,
        C_HYPHEN_MINUS,                         0,              0,
        C_PERIOD,                               0,              0,
        C_SLASH,                                0,              0,
        C_DIGIT_ZERO,                           0,              0,
        C_DIGIT_ONE,                            0,              0,
        C_DIGIT_TWO,                            0,              0,
        C_DIGIT_THREE,                          0,              0,
        C_DIGIT_FOUR,                           0,              0,
        C_DIGIT_FIVE,                           0,              0,
        C_DIGIT_SIX,                            0,              0,
        C_DIGIT_SEVEN,                          0,              0,
        C_DIGIT_EIGHT,                          0,              0,
        C_DIGIT_NINE,                           0,              0,
        C_COLON,                                0,              0,
        C_SEMICOLON,                            0,              0,
        C_LESS_THAN_SIGN,                       0,              0,
        C_EQUALS_SIGN,                          0,              0,
        C_GREATER_THAN_SIGN,                    0,              0,
        C_QUESTION_MARK,                        0,              0,
        C_COMMERCIAL_AT,                        0,              0,
        C_LATIN_CAPITAL_LETTER_A,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_B,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_C,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_D,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_E,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_F,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_G,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_H,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_I,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_J,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_K,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_L,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_M,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_N,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_O,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_P,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_Q,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_R,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_S,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_T,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_U,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_V,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_W,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_X,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_Y,               CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_Z,               CMF_CAP,        0,
        C_OPENING_SQUARE_BRACKET,               0,              0,
        C_BACKSLASH,                            0,              0,
        C_CLOSING_SQUARE_BRACKET,               0,              0,
        C_SPACING_CIRCUMFLEX,                   0,              0,
        C_SPACING_UNDERSCORE,                   0,              0,
        C_SPACING_GRAVE,                        0,              0,
        C_LATIN_SMALL_LETTER_A,                 CMF_MEAN,       0,
        C_LATIN_SMALL_LETTER_B,                 CMF_ASCENT,     0,
        C_LATIN_SMALL_LETTER_C,                 CMF_MEAN,       0,
        C_LATIN_SMALL_LETTER_D,                 CMF_ASCENT,     0,
        C_LATIN_SMALL_LETTER_E,                 CMF_MEAN,       0,
        C_LATIN_SMALL_LETTER_F,                 CMF_ASCENT,     0,
        C_LATIN_SMALL_LETTER_G,                 CMF_DESCENT,    0,
        C_LATIN_SMALL_LETTER_H,                 CMF_ASCENT,     0,
        C_LATIN_SMALL_LETTER_I,                 CMF_ASCENT,     0,
        C_LATIN_SMALL_LETTER_J,                 CMF_DESCENT,    0,
        C_LATIN_SMALL_LETTER_K,                 CMF_ASCENT,     0,
        C_LATIN_SMALL_LETTER_L,                 CMF_ASCENT,     0,
        C_LATIN_SMALL_LETTER_M,                 CMF_MEAN,       0,
        C_LATIN_SMALL_LETTER_N,                 CMF_MEAN,       0,
        C_LATIN_SMALL_LETTER_O,                 CMF_MEAN,       0,
        C_LATIN_SMALL_LETTER_P,                 CMF_DESCENT,    0,
        C_LATIN_SMALL_LETTER_Q,                 CMF_DESCENT,    0,
        C_LATIN_SMALL_LETTER_R,                 CMF_MEAN,       0,
        C_LATIN_SMALL_LETTER_S,                 CMF_MEAN,       0,
        C_LATIN_SMALL_LETTER_T,                 CMF_ASCENT,     0,
        C_LATIN_SMALL_LETTER_U,                 CMF_MEAN,       0,
        C_LATIN_SMALL_LETTER_V,                 CMF_MEAN,       0,
        C_LATIN_SMALL_LETTER_W,                 CMF_MEAN,       0,
        C_LATIN_SMALL_LETTER_X,                 CMF_MEAN,       0,
        C_LATIN_SMALL_LETTER_Y,                 CMF_DESCENT,    0,
        C_LATIN_SMALL_LETTER_Z,                 CMF_MEAN,       0,
        C_OPENING_CURLY_BRACKET,                0,              0,
        C_VERTICAL_BAR,                         0,              0,
        C_CLOSING_CURLY_BRACKET,                0,              0,
        C_TILDE,                                0,              0,
        C_DELETE,                               0,              0,
        C_LATIN_CAPITAL_LETTER_A_DIAERESIS,     CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_A_RING,          CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_C_CEDILLA,       CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_E_ACUTE,         CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_N_TILDE,         CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_O_DIAERESIS,     CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_U_DIAERESIS,     CMF_ACCENT,     0,
        C_LATIN_SMALL_LETTER_A_ACUTE,           0,              0,
        C_LATIN_SMALL_LETTER_A_GRAVE,           0,              0,
        C_LATIN_SMALL_LETTER_A_CIRCUMFLEX,      0,              0,
        C_LATIN_SMALL_LETTER_A_DIAERESIS,       0,              0,
        C_LATIN_SMALL_LETTER_A_TILDE,           0,              0,
        C_LATIN_SMALL_LETTER_A_RING,            0,              0,
        C_LATIN_SMALL_LETTER_C_CEDILLA,         0,              0,
        C_LATIN_SMALL_LETTER_E_ACUTE,           0,              0,
        C_LATIN_SMALL_LETTER_E_GRAVE,           0,              0,
        C_LATIN_SMALL_LETTER_E_CIRCUMFLEX,      0,              0,
        C_LATIN_SMALL_LETTER_E_DIAERESIS,       0,              0,
        C_LATIN_SMALL_LETTER_I_ACUTE,           0,              0,
        C_LATIN_SMALL_LETTER_I_GRAVE,           0,              0,
        C_LATIN_SMALL_LETTER_I_CIRCUMFLEX,      0,              0,
        C_LATIN_SMALL_LETTER_I_DIAERESIS,       0,              0,
        C_LATIN_SMALL_LETTER_N_TILDE,           0,              0,
        C_LATIN_SMALL_LETTER_O_ACUTE,           0,              0,
        C_LATIN_SMALL_LETTER_O_GRAVE,           0,              0,
        C_LATIN_SMALL_LETTER_O_CIRCUMFLEX,      0,              0,
        C_LATIN_SMALL_LETTER_O_DIAERESIS,       0,              0,
        C_LATIN_SMALL_LETTER_O_TILDE,           0,              0,
        C_LATIN_SMALL_LETTER_U_ACUTE,           0,              0,
        C_LATIN_SMALL_LETTER_U_GRAVE,           0,              0,
        C_LATIN_SMALL_LETTER_U_CIRCUMFLEX,      0,              0,
        C_LATIN_SMALL_LETTER_U_DIAERESIS,       0,              0,
        C_DAGGER,                               0,              0,
        C_DEGREE_SIGN,                          0,              0,
        C_CENT_SIGN,                            0,              0,
        C_POUND_SIGN,                           0,              0,
        C_SECTION_SIGN,                         0,              0,
        C_BULLET_OPERATOR,                      0,              0,
        C_PARAGRAPH_SIGN,                       0,              0,
        C_LATIN_SMALL_LETTER_SHARP_S,           0,              0,
        C_REGISTERED_TRADE_MARK_SIGN,           0,              0,
        C_COPYRIGHT_SIGN,                       0,              0,
        C_TRADEMARK,                            0,              0,
        C_SPACING_ACUTE,                        0,              0,
        C_SPACING_DIAERESIS,                    0,              0,
        C_NOT_EQUAL_TO,                         0,              0,
        C_LATIN_CAPITAL_LETTER_A_E,             CMF_CAP,        0,
        C_LATIN_CAPITAL_LETTER_O_SLASH,         CMF_CAP,        0,
        C_INFINITY,                             0,              0,
        C_PLUS_OR_MINUS_SIGN,                   0,              0,
        C_LESS_THAN_OR_EQUAL_TO,                0,              0,
        C_GREATER_THAN_OR_EQUAL_TO,             0,              0,
        C_YEN_SIGN,                             0,              0,
        C_MICRO_SIGN,                           0,              0,
        C_PARTIAL_DIFFERENTIAL,                 0,              0,
        C_N_ARY_SUMMATION,                      0,              0,
        C_N_ARY_PRODUCT,                        0,              0,
        C_GREEK_SMALL_LETTER_PI,                0,              0,
        C_INTEGRAL,                             0,              0,
        C_FEMININE_ORDINAL_INDICATOR,           0,              0,
        C_MASCULINE_ORDINAL_INDICATOR,          0,              0,
        C_GREEK_CAPITAL_LETTER_OMEGA,           0,              0,
        C_LATIN_SMALL_LETTER_A_E,               0,              0,
        C_LATIN_SMALL_LETTER_O_SLASH,           0,              0,
        C_INVERTED_QUESTION_MARK,               0,              0,
        C_INVERTED_EXCLAMATION_MARK,            0,              0,
        C_NOT_SIGN,                             0,              0,
        C_SQUARE_ROOT,                          0,              0,
        C_LATIN_SMALL_LETTER_SCRIPT_F,          0,              0,
        C_ALMOST_EQUAL_TO,                      0,              0,
        C_GREEK_CAPITAL_LETTER_DELTA,           0,              0,
        C_LEFT_POINTING_GUILLEMET,              0,              0,
        C_RIGHT_POINTING_GUILLEMET,             0,              0,
        C_MIDLINE_HORIZONTAL_ELLIPSIS,          0,              0,
        C_NON_BREAKING_SPACE,                   0,              0,
        C_LATIN_CAPITAL_LETTER_A_GRAVE,         CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_A_TILDE,         CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_O_TILDE,         CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_O_E,             CMF_ACCENT,     0,
        C_LATIN_SMALL_LETTER_O_E,               0,              0,
        C_EM_DASH,                              0,              0,
        C_EN_DASH,                              0,              0,
        C_DOUBLE_TURNED_COMMA_QUOTATION_MARK,   0,              0,
        C_DOUBLE_COMMA_QUOTATION_MARK,          0,              0,
        C_SINGLE_TURNED_COMMA_QUOTATION_MARK,   0,              0,
        C_SINGLE_COMMA_QUOTATION_MARK,          0,              0,
        C_DIVISION_SIGN,                        0,              0,
        C_BLACK_DIAMOND,                        0,              0,
        C_LATIN_SMALL_LETTER_Y_DIAERESIS,       0,              0,
        C_LATIN_CAPITAL_LETTER_Y_DIAERESIS,     CMF_ACCENT,     0,
        C_FRACTION_SLASH,                       0,              0,
        C_EURO_SIGN,                            0,              0,
        C_LEFT_POINTING_SINGLE_GUILLEMET,       0,              0,
        C_RIGHT_POINTING_SINGLE_GUILLEMET,      0,              0,
        C_LATIN_SMALL_LETTER_Y_ACUTE,           0,              0,
        C_LATIN_CAPITAL_LETTER_Y_ACUTE,         0,              0,
        C_DOUBLE_DAGGER,                        0,              0,
        C_MIDDLE_DOT,                           0,              0,
        C_LOW_SINGLE_COMMA_QUOTATION_MARK,      0,              0,
        C_LOW_DOUBLE_COMMA_QUOTATION_MARK,      0,              0,
        C_PER_MILLE_SIGN,                       0,              0,
        C_LATIN_CAPITAL_LETTER_A_CIRCUMFLEX,    CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_E_CIRCUMFLEX,    CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_A_ACUTE,         CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_E_DIAERESIS,     CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_E_GRAVE,         CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_I_ACUTE,         CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_I_CIRCUMFLEX,    CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_I_DIAERESIS,     CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_I_GRAVE,         CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_O_ACUTE,         CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_O_CIRCUMFLEX,    CMF_ACCENT,     0,
        0,                                      0,              0,              //no character
        C_LATIN_CAPITAL_LETTER_O_GRAVE,         CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_U_ACUTE,         CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_U_CIRCUMFLEX,    CMF_ACCENT,     0,
        C_LATIN_CAPITAL_LETTER_U_GRAVE,         CMF_ACCENT,     0,
        C_LATIN_SMALL_LETTER_DOTLESS_I,         0,              0,
        C_NON_SPACING_CIRCUMFLEX,               0,              0,
        C_NON_SPACING_TILDE,                    0,              0,
        C_SPACING_MACRON,                       0,              0,
        C_SPACING_BREVE,                        0,              0,
        C_SPACING_DOT_ABOVE,                    0,              0,
        C_SPACING_RING_ABOVE,                   0,              0,
        C_SPACING_CEDILLA,                      0,              0,
        C_SPACING_DOUBLE_ACUTE,                 0,              0,
        C_SPACING_OGONEK,                       0,              0,
        C_MODIFIER_LETTER_HACEK,                0,              0
};


word GeosCharToUnicode( word geosChar )
{
        if( geosChar < MIN_GEOS_CHAR || geosChar > MAX_GEOS_CHAR )
                return 0;

        return geosCharMap[ GEOS_CHAR_INDEX( geosChar ) ].unicode;
}


CharMapFlags GeosCharMapFlag( word geosChar )
{
       if( geosChar < MIN_GEOS_CHAR || geosChar > MAX_GEOS_CHAR )
                return 0;

       return geosCharMap[ GEOS_CHAR_INDEX( geosChar ) ].flags;
}


/*
 * Get microsoft unicode charmap in face.
 */
TT_Error getCharMap( TRUETYPE_VARS, TT_CharMap* charMap )
{
        TT_UShort           platform;
        TT_UShort           encoding;
        int                 map;


        TT_Get_Face_Properties( FACE, &FACE_PROPERTIES );

	for ( map = 0; map < FACE_PROPERTIES.num_CharMaps; ++map ) 
        {
		TT_Get_CharMap_ID( FACE, map, &platform, &encoding );
		if ( platform == TT_PLATFORM_MICROSOFT && encoding == TT_MS_ID_UNICODE_CS )
                {
		        TT_Get_CharMap(FACE, map, charMap);
			break;
		}
	}

        if ( map == FACE_PROPERTIES.num_CharMaps ) return TT_Err_CMap_Table_Missing;
        else                                       return TT_Err_Ok;
}


/*
 * Counts the GEOS characters that are present in the font.
 */
word InitGeosCharsInCharMap( TT_CharMap map, char *firstChar, char *lastChar )
{
        word charIndex;
        word truetypeIndex;


        *firstChar = 255;
        *lastChar  = 0;

        for( charIndex = 0; charIndex < NUM_CHARMAPENTRIES; ++charIndex )
        {
                if( truetypeIndex = TT_Char_Index( map, geosCharMap[ charIndex ].unicode ) )
                {
                        geosCharMap[ charIndex ].ttIndex = truetypeIndex;
                        if ( firstChar != NULL && *firstChar > ( charIndex + C_SPACE ) ) *firstChar = charIndex + C_SPACE;
                        if ( lastChar  != NULL && *lastChar  < ( charIndex + C_SPACE ) ) *lastChar  = charIndex + C_SPACE;
                }
        }

        return 1 + ( *lastChar - *firstChar );
}


Boolean isGeosCharPair( word ttIndex_1, word ttIndex_2 )
{
        word charIndex;
        word hits = 0;

        for( charIndex = 0; charIndex < NUM_CHARMAPENTRIES; ++charIndex )
        {
                if( geosCharMap[charIndex].ttIndex == ttIndex_1 || 
                    geosCharMap[charIndex].ttIndex == ttIndex_2 )
                        ++hits; 

                if( hits == 2 )
                        return TRUE;

        }

        return FALSE;
}


char getGeosCharForIndex( word ttIndex )
{
        word charIndex;

        for( charIndex = 0; charIndex < NUM_CHARMAPENTRIES; ++charIndex )
                if( ttIndex == geosCharMap[charIndex].ttIndex )
                        return charIndex + C_SPACE;

        return 0;        
}
