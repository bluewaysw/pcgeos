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
#include <unicode.h>

#define NUM_CHARMAPENTRIES      ( sizeof(geosCharMap) / sizeof(CharMapEntry) )
#define MIN_GEOS_CHAR           ( C_SPACE )
#define MAX_GEOS_CHAR           ( NUM_CHARMAPENTRIES + MIN_GEOS_CHAR )
#define GEOS_CHAR_INDEX( i )    ( i - MIN_GEOS_CHAR )


CharMapEntry geosCharMap[] = 
{
/*      unicode                                 weight         flags   */
        C_SPACE,                                0,             0,
        C_EXCLAMATION_MARK,                     0,             0,
        C_QUOTATION_MARK,                       0,             0,
        C_NUMBER_SIGN,                          0,             0,
        C_DOLLAR_SIGN,                          0,             0,
        C_PERCENT_SIGN,                         0,             0,
        C_AMPERSAND,                            0,             0,
        C_APOSTROPHE_QUOTE,                     0,             0,
        C_OPENING_PARENTHESIS,                  0,             0,
        C_CLOSING_PARENTHESIS,                  0,             0,
        C_ASTERISK,                             0,             0,
        C_PLUS_SIGN,                            0,             0,
        C_COMMA,                                0,             0,
        C_HYPHEN_MINUS,                         0,             0,
        C_PERIOD,                               0,             0,
        C_SLASH,                                0,             0,
        C_DIGIT_ZERO,                           0,             0,
        C_DIGIT_ONE,                            0,             0,
        C_DIGIT_TWO,                            0,             0,
        C_DIGIT_THREE,                          0,             0,
        C_DIGIT_FOUR,                           0,             0,
        C_DIGIT_FIVE,                           0,             0,
        C_DIGIT_SIX,                            0,             0,
        C_DIGIT_SEVEN,                          0,             0,
        C_DIGIT_EIGHT,                          0,             0,
        C_DIGIT_NINE,                           0,             0,
        C_COLON,                                0,             0,
        C_SEMICOLON,                            0,             0,
        C_LESS_THAN_SIGN,                       0,             0,
        C_EQUALS_SIGN,                          0,             0,
        C_GREATER_THAN_SIGN,                    0,             0,
        C_QUESTION_MARK,                        0,             0,
        C_COMMERCIAL_AT,                        0,             0,
        C_LATIN_CAPITAL_LETTER_A,               0,             0,
        C_LATIN_CAPITAL_LETTER_B,               0,             0,
        C_LATIN_CAPITAL_LETTER_C,               0,             0,
        C_LATIN_CAPITAL_LETTER_D,               0,             0,
        C_LATIN_CAPITAL_LETTER_E,               0,             0,
        C_LATIN_CAPITAL_LETTER_F,               0,             0,
        C_LATIN_CAPITAL_LETTER_G,               0,             0,
        C_LATIN_CAPITAL_LETTER_H,               0,             0,
        C_LATIN_CAPITAL_LETTER_I,               0,             0,
        C_LATIN_CAPITAL_LETTER_J,               0,             0,
        C_LATIN_CAPITAL_LETTER_K,               0,             0,
        C_LATIN_CAPITAL_LETTER_L,               0,             0,
        C_LATIN_CAPITAL_LETTER_M,               0,             0,
        C_LATIN_CAPITAL_LETTER_N,               0,             0,
        C_LATIN_CAPITAL_LETTER_O,               0,             0,
        C_LATIN_CAPITAL_LETTER_P,               0,             0,
        C_LATIN_CAPITAL_LETTER_Q,               0,             0,
        C_LATIN_CAPITAL_LETTER_R,               0,             0,
        C_LATIN_CAPITAL_LETTER_S,               0,             0,
        C_LATIN_CAPITAL_LETTER_T,               0,             0,
        C_LATIN_CAPITAL_LETTER_U,               0,             0,
        C_LATIN_CAPITAL_LETTER_V,               0,             0,
        C_LATIN_CAPITAL_LETTER_W,               0,             0,
        C_LATIN_CAPITAL_LETTER_X,               0,             0,
        C_LATIN_CAPITAL_LETTER_Y,               0,             0,
        C_LATIN_CAPITAL_LETTER_Z,               0,             0,
        C_OPENING_SQUARE_BRACKET,               0,             0,
        C_BACKSLASH,                            0,             0,
        C_CLOSING_SQUARE_BRACKET,               0,             0,
        C_SPACING_CIRCUMFLEX,                   0,             0,
        C_SPACING_UNDERSCORE,                   0,             0,
        C_SPACING_GRAVE,                        0,             0,
        C_LATIN_SMALL_LETTER_A,                 0,             0,
        C_LATIN_SMALL_LETTER_B,                 0,             0,
        C_LATIN_SMALL_LETTER_C,                 0,             0,
        C_LATIN_SMALL_LETTER_D,                 0,             0,
        C_LATIN_SMALL_LETTER_E,                 0,             0,
        C_LATIN_SMALL_LETTER_F,                 0,             0,
        C_LATIN_SMALL_LETTER_G,                 0,             0,
        C_LATIN_SMALL_LETTER_H,                 0,             0,
        C_LATIN_SMALL_LETTER_I,                 0,             0,
        C_LATIN_SMALL_LETTER_J,                 0,             0,
        C_LATIN_SMALL_LETTER_K,                 0,             0,
        C_LATIN_SMALL_LETTER_L,                 0,             0,
        C_LATIN_SMALL_LETTER_M,                 0,             0,
        C_LATIN_SMALL_LETTER_N,                 0,             0,
        C_LATIN_SMALL_LETTER_O,                 0,             0,
        C_LATIN_SMALL_LETTER_P,                 0,             0,
        C_LATIN_SMALL_LETTER_Q,                 0,             0,
        C_LATIN_SMALL_LETTER_R,                 0,             0,
        C_LATIN_SMALL_LETTER_S,                 0,             0,
        C_LATIN_SMALL_LETTER_T,                 0,             0,
        C_LATIN_SMALL_LETTER_U,                 0,             0,
        C_LATIN_SMALL_LETTER_V,                 0,             0,
        C_LATIN_SMALL_LETTER_W,                 0,             0,
        C_LATIN_SMALL_LETTER_X,                 0,             0,
        C_LATIN_SMALL_LETTER_Y,                 0,             0,
        C_LATIN_SMALL_LETTER_Z,                 0,             0,
        C_OPENING_CURLY_BRACKET,                0,             0,
        C_VERTICAL_BAR,                         0,             0,
        C_CLOSING_CURLY_BRACKET,                0,             0,
        C_TILDE,                                0,             0,
        C_DELETE,                               0,             0,
        C_LATIN_CAPITAL_LETTER_A_DIAERESIS,     0,             0,
        C_LATIN_CAPITAL_LETTER_A_RING,          0,             0,
        C_LATIN_CAPITAL_LETTER_C_CEDILLA,       0,             0,
        C_LATIN_CAPITAL_LETTER_E_ACUTE,         0,             0
};


sword GeosCharToUnicode( word geosChar )
{
        if( geosChar < MIN_GEOS_CHAR || geosChar > MAX_GEOS_CHAR )
                return -1;

        return geosCharMap[ GEOS_CHAR_INDEX( geosChar ) ].unicode;
}


word CountGeosCharsInCharMap( TT_CharMap map, word *firstChar, word *lastChar )
{
        word charIndex;
        word charCount = 0;


        *firstChar = 9999;
        *lastChar  = 0;

        for( charIndex = 0; charIndex < NUM_CHARMAPENTRIES; ++charIndex )
        {
                if( TT_Char_Index( map, geosCharMap[ charIndex ].unicode ) )
                {
                        ++charCount;
                        if ( *firstChar > ( charIndex + C_SPACE ) ) *firstChar = charIndex + C_SPACE;
                        if ( *lastChar  < ( charIndex + C_SPACE ) ) *lastChar  = charIndex + C_SPACE;
                }
        }

        return charCount;
}
