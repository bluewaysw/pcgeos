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
#include <ttmemory.h>
#include <geos.h>
#include <unicode.h>
#include <Ansi/stdlib.h>

#define NUM_CHARMAPENTRIES      ( sizeof(geosCharMap) / sizeof(CharMapEntry) )
#define MIN_GEOS_CHAR           ( C_SPACE )
#define MAX_GEOS_CHAR           ( NUM_CHARMAPENTRIES + MIN_GEOS_CHAR )
#define GEOS_CHAR_INDEX( i )    ( i - MIN_GEOS_CHAR )


/***********************************************************************
 *      internal functions
 ***********************************************************************/

static int _pascal compareLookupEntries(const void *a, const void *b);


//TODO: put geosCharMap into movable ressource
CharMapEntry geosCharMap[] = 
{
/*      unicode                                 flags */
        C_SPACE,                                0,
        C_EXCLAMATION_MARK,                     0,
        C_QUOTATION_MARK,                       0,
        C_NUMBER_SIGN,                          0,
        C_DOLLAR_SIGN,                          0,
        C_PERCENT_SIGN,                         0,
        C_AMPERSAND,                            0,
        C_APOSTROPHE_QUOTE,                     0,
        C_OPENING_PARENTHESIS,                  0,
        C_CLOSING_PARENTHESIS,                  0,
        C_ASTERISK,                             0,
        C_PLUS_SIGN,                            0,
        C_COMMA,                                0,
        C_HYPHEN_MINUS,                         0,
        C_PERIOD,                               0,
        C_SLASH,                                0,
        C_DIGIT_ZERO,                           0,
        C_DIGIT_ONE,                            0,
        C_DIGIT_TWO,                            0,
        C_DIGIT_THREE,                          0,
        C_DIGIT_FOUR,                           0,
        C_DIGIT_FIVE,                           0,
        C_DIGIT_SIX,                            0,
        C_DIGIT_SEVEN,                          0,
        C_DIGIT_EIGHT,                          0,
        C_DIGIT_NINE,                           0,
        C_COLON,                                0,
        C_SEMICOLON,                            0,
        C_LESS_THAN_SIGN,                       0,
        C_EQUALS_SIGN,                          0,
        C_GREATER_THAN_SIGN,                    0,
        C_QUESTION_MARK,                        0,
        C_COMMERCIAL_AT,                        0,
        C_LATIN_CAPITAL_LETTER_A,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_B,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_C,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_D,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_E,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_F,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_G,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_H,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_I,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_J,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_K,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_L,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_M,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_N,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_O,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_P,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_Q,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_R,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_S,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_T,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_U,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_V,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_W,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_X,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_Y,               CMF_CAP,
        C_LATIN_CAPITAL_LETTER_Z,               CMF_CAP,
        C_OPENING_SQUARE_BRACKET,               0,
        C_BACKSLASH,                            0,
        C_CLOSING_SQUARE_BRACKET,               0,
        C_SPACING_CIRCUMFLEX,                   0,
        C_SPACING_UNDERSCORE,                   0,
        C_SPACING_GRAVE,                        0,
        C_LATIN_SMALL_LETTER_A,                 CMF_MEAN,
        C_LATIN_SMALL_LETTER_B,                 CMF_ASCENT,
        C_LATIN_SMALL_LETTER_C,                 CMF_MEAN,
        C_LATIN_SMALL_LETTER_D,                 CMF_ASCENT,
        C_LATIN_SMALL_LETTER_E,                 CMF_MEAN,
        C_LATIN_SMALL_LETTER_F,                 CMF_ASCENT,
        C_LATIN_SMALL_LETTER_G,                 CMF_DESCENT,
        C_LATIN_SMALL_LETTER_H,                 CMF_ASCENT,
        C_LATIN_SMALL_LETTER_I,                 CMF_ASCENT,
        C_LATIN_SMALL_LETTER_J,                 CMF_DESCENT,
        C_LATIN_SMALL_LETTER_K,                 CMF_ASCENT,
        C_LATIN_SMALL_LETTER_L,                 CMF_ASCENT,
        C_LATIN_SMALL_LETTER_M,                 CMF_MEAN,
        C_LATIN_SMALL_LETTER_N,                 CMF_MEAN,
        C_LATIN_SMALL_LETTER_O,                 CMF_MEAN,
        C_LATIN_SMALL_LETTER_P,                 CMF_DESCENT,
        C_LATIN_SMALL_LETTER_Q,                 CMF_DESCENT,
        C_LATIN_SMALL_LETTER_R,                 CMF_MEAN,
        C_LATIN_SMALL_LETTER_S,                 CMF_MEAN,
        C_LATIN_SMALL_LETTER_T,                 CMF_ASCENT,
        C_LATIN_SMALL_LETTER_U,                 CMF_MEAN,
        C_LATIN_SMALL_LETTER_V,                 CMF_MEAN,
        C_LATIN_SMALL_LETTER_W,                 CMF_MEAN,
        C_LATIN_SMALL_LETTER_X,                 CMF_MEAN,
        C_LATIN_SMALL_LETTER_Y,                 CMF_DESCENT,
        C_LATIN_SMALL_LETTER_Z,                 CMF_MEAN,
        C_OPENING_CURLY_BRACKET,                0,
        C_VERTICAL_BAR,                         0,
        C_CLOSING_CURLY_BRACKET,                0,
        C_TILDE,                                0,
        C_DELETE,                               0,
        C_LATIN_CAPITAL_LETTER_A_DIAERESIS,     CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_A_RING,          CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_C_CEDILLA,       CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_E_ACUTE,         CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_N_TILDE,         CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_O_DIAERESIS,     CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_U_DIAERESIS,     CMF_ACCENT,
        C_LATIN_SMALL_LETTER_A_ACUTE,           0,
        C_LATIN_SMALL_LETTER_A_GRAVE,           0,
        C_LATIN_SMALL_LETTER_A_CIRCUMFLEX,      0,
        C_LATIN_SMALL_LETTER_A_DIAERESIS,       0,
        C_LATIN_SMALL_LETTER_A_TILDE,           0,
        C_LATIN_SMALL_LETTER_A_RING,            0,
        C_LATIN_SMALL_LETTER_C_CEDILLA,         0,
        C_LATIN_SMALL_LETTER_E_ACUTE,           0,
        C_LATIN_SMALL_LETTER_E_GRAVE,           0,
        C_LATIN_SMALL_LETTER_E_CIRCUMFLEX,      0,
        C_LATIN_SMALL_LETTER_E_DIAERESIS,       0,
        C_LATIN_SMALL_LETTER_I_ACUTE,           0,
        C_LATIN_SMALL_LETTER_I_GRAVE,           0,
        C_LATIN_SMALL_LETTER_I_CIRCUMFLEX,      0,
        C_LATIN_SMALL_LETTER_I_DIAERESIS,       0,
        C_LATIN_SMALL_LETTER_N_TILDE,           0,
        C_LATIN_SMALL_LETTER_O_ACUTE,           0,
        C_LATIN_SMALL_LETTER_O_GRAVE,           0,
        C_LATIN_SMALL_LETTER_O_CIRCUMFLEX,      0,
        C_LATIN_SMALL_LETTER_O_DIAERESIS,       0,
        C_LATIN_SMALL_LETTER_O_TILDE,           0,
        C_LATIN_SMALL_LETTER_U_ACUTE,           0,
        C_LATIN_SMALL_LETTER_U_GRAVE,           0,
        C_LATIN_SMALL_LETTER_U_CIRCUMFLEX,      0,
        C_LATIN_SMALL_LETTER_U_DIAERESIS,       0,
        C_DAGGER,                               0,
        C_DEGREE_SIGN,                          0,
        C_CENT_SIGN,                            0,
        C_POUND_SIGN,                           0,
        C_SECTION_SIGN,                         0,
        C_BULLET_OPERATOR,                      0,
        C_PARAGRAPH_SIGN,                       0,
        C_LATIN_SMALL_LETTER_SHARP_S,           0,
        C_REGISTERED_TRADE_MARK_SIGN,           0,
        C_COPYRIGHT_SIGN,                       0,
        C_TRADEMARK,                            0,
        C_SPACING_ACUTE,                        0,
        C_SPACING_DIAERESIS,                    0,
        C_NOT_EQUAL_TO,                         0,
        C_LATIN_CAPITAL_LETTER_A_E,             CMF_CAP,
        C_LATIN_CAPITAL_LETTER_O_SLASH,         CMF_CAP,
        C_INFINITY,                             0,
        C_PLUS_OR_MINUS_SIGN,                   0,
        C_LESS_THAN_OR_EQUAL_TO,                0,
        C_GREATER_THAN_OR_EQUAL_TO,             0,
        C_YEN_SIGN,                             0,
        C_MICRO_SIGN,                           0,
        C_PARTIAL_DIFFERENTIAL,                 0,
        C_N_ARY_SUMMATION,                      0,
        C_N_ARY_PRODUCT,                        0,
        C_GREEK_SMALL_LETTER_PI,                0,
        C_INTEGRAL,                             0,
        C_FEMININE_ORDINAL_INDICATOR,           0,
        C_MASCULINE_ORDINAL_INDICATOR,          0,
        C_GREEK_CAPITAL_LETTER_OMEGA,           0,
        C_LATIN_SMALL_LETTER_A_E,               0,
        C_LATIN_SMALL_LETTER_O_SLASH,           0,
        C_INVERTED_QUESTION_MARK,               0,
        C_INVERTED_EXCLAMATION_MARK,            0,
        C_NOT_SIGN,                             0,
        C_SQUARE_ROOT,                          0,
        C_LATIN_SMALL_LETTER_SCRIPT_F,          0,
        C_ALMOST_EQUAL_TO,                      0,
        C_GREEK_CAPITAL_LETTER_DELTA,           0,
        C_LEFT_POINTING_GUILLEMET,              0,
        C_RIGHT_POINTING_GUILLEMET,             0,
        C_HORIZONTAL_ELLIPSIS,                  0,
        C_NON_BREAKING_SPACE,                   0,
        C_LATIN_CAPITAL_LETTER_A_GRAVE,         CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_A_TILDE,         CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_O_TILDE,         CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_O_E,             CMF_ACCENT,
        C_LATIN_SMALL_LETTER_O_E,               0,
        C_EM_DASH,                              0,
        C_EN_DASH,                              0,
        C_DOUBLE_TURNED_COMMA_QUOTATION_MARK,   0,
        C_DOUBLE_COMMA_QUOTATION_MARK,          0,
        C_SINGLE_TURNED_COMMA_QUOTATION_MARK,   0,
        C_SINGLE_COMMA_QUOTATION_MARK,          0,
        C_DIVISION_SIGN,                        0,
        C_BLACK_DIAMOND,                        0,
        C_LATIN_SMALL_LETTER_Y_DIAERESIS,       0,
        C_LATIN_CAPITAL_LETTER_Y_DIAERESIS,     CMF_ACCENT,
        C_FRACTION_SLASH,                       0,
        C_EURO_SIGN,                            0,
        C_LEFT_POINTING_SINGLE_GUILLEMET,       0,
        C_RIGHT_POINTING_SINGLE_GUILLEMET,      0,
        C_LATIN_SMALL_LETTER_Y_ACUTE,           0,
        C_LATIN_CAPITAL_LETTER_Y_ACUTE,         0,
        C_DOUBLE_DAGGER,                        0,
        C_MIDDLE_DOT,                           0,
        C_LOW_SINGLE_COMMA_QUOTATION_MARK,      0,
        C_LOW_DOUBLE_COMMA_QUOTATION_MARK,      0,
        C_PER_MILLE_SIGN,                       0,
        C_LATIN_CAPITAL_LETTER_A_CIRCUMFLEX,    CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_E_CIRCUMFLEX,    CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_A_ACUTE,         CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_E_DIAERESIS,     CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_E_GRAVE,         CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_I_ACUTE,         CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_I_CIRCUMFLEX,    CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_I_DIAERESIS,     CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_I_GRAVE,         CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_O_ACUTE,         CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_O_CIRCUMFLEX,    CMF_ACCENT, 
        0,                                      0,              //no character
        C_LATIN_CAPITAL_LETTER_O_GRAVE,         CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_U_ACUTE,         CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_U_CIRCUMFLEX,    CMF_ACCENT,
        C_LATIN_CAPITAL_LETTER_U_GRAVE,         CMF_ACCENT,
        C_LATIN_SMALL_LETTER_DOTLESS_I,         0,
        C_NON_SPACING_CIRCUMFLEX,               0,
        C_NON_SPACING_TILDE,                    0,
        C_SPACING_MACRON,                       0,
        C_SPACING_BREVE,                        0,
        C_SPACING_DOT_ABOVE,                    0,
        C_SPACING_RING_ABOVE,                   0,
        C_SPACING_CEDILLA,                      0,
        C_SPACING_DOUBLE_ACUTE,                 0,
        C_SPACING_OGONEK,                       0,
        C_MODIFIER_LETTER_HACEK,                0
};


/********************************************************************
 *                      GeosCharToUnicode
 ********************************************************************
 * SYNOPSIS:       Converts a GEOS character code to its corresponding
 *                 Unicode value.
 * 
 * PARAMETERS:     word geosChar
 *                    The GEOS character code to be converted.
 * 
 * RETURNS:        word
 *                    The corresponding Unicode value, or 0 if the input
 *                    character code is out of bounds.
 * 
 * STRATEGY:       - Check if the GEOS character code is within the valid
 *                   range.
 *                 - If valid, retrieve the corresponding Unicode value
 *                   from the character map.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      30.09.24  JK        Initial Revision
 *******************************************************************/

word GeosCharToUnicode( const word  geosChar )
{
        if( geosChar < MIN_GEOS_CHAR || geosChar > MAX_GEOS_CHAR )
                return 0;

        return geosCharMap[ GEOS_CHAR_INDEX( geosChar ) ].unicode;
}


/********************************************************************
 *                      GeosCharMapFlag
 ********************************************************************
 * SYNOPSIS:       Retrieves the character map flags for a given GEOS
 *                 character code.
 * 
 * PARAMETERS:     word geosChar
 *                    The GEOS character code for which the flags are needed.
 * 
 * RETURNS:        CharMapFlags
 *                    The flags associated with the GEOS character code,
 *                    or 0 if the input character code is out of bounds.
 * 
 * STRATEGY:       - Verify if the GEOS character code is within the valid
 *                   character range.
 *                 - If valid, return the corresponding flags from the
 *                   character map.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      30.09.24  JK        Initial Revision
 *******************************************************************/

CharMapFlags GeosCharMapFlag( const word  geosChar )
{
       if( geosChar < MIN_GEOS_CHAR || geosChar > MAX_GEOS_CHAR )
                return 0;

       return geosCharMap[ GEOS_CHAR_INDEX( geosChar ) ].flags;
}


/********************************************************************
 *                      CountValidGeosChars
 ********************************************************************
 * SYNOPSIS:       Counts the number of valid GEOS characters mapped 
 *                 in the provided TrueType character map.
 * 
 * PARAMETERS:     TT_CharMap map
 *                    The character map to be used for checking 
 *                    the availability of GEOS characters.
 *                 char* firstChar
 *                    Pointer to a character that will store the first
 *                    valid GEOS character code.
 *                 char* lastChar
 *                    Pointer to a character that will store the last
 *                    valid GEOS character code.
 * 
 * RETURNS:        word
 *                    The count of valid GEOS characters found in the
 *                    character map, ranging from the first valid 
 *                    character to the last.
 * 
 * STRATEGY:       - Initialize `firstChar` to the maximum possible value 
 *                   and `lastChar` to zero.
 *                 - Iterate over each entry in the character map to determine 
 *                   if it has a valid TrueType index.
 *                 - For each valid character, update `firstChar` and 
 *                   `lastChar` accordingly.
 *                 - Calculate the total number of valid characters.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      06.12.22  JK        Initial Revision
 *******************************************************************/

word CountValidGeosChars( const TT_CharMap  map, char*  firstChar, char*  lastChar )
{
        word  charIndex;
        word  firstFound = NUM_CHARMAPENTRIES;
        word  lastFound = 0;


        for( charIndex = 0; charIndex < NUM_CHARMAPENTRIES; ++charIndex )
        {
                if( TT_Char_Index( map, geosCharMap[charIndex].unicode ) )
                {
                        if( firstFound > charIndex ) firstFound = charIndex;
                        lastFound = charIndex;
                }
        }

        *firstChar = (firstFound < NUM_CHARMAPENTRIES) ? (char)(firstFound + C_SPACE) : 255;
        *lastChar = (lastFound > 0) ? (char)(lastFound + C_SPACE) : 0;

        return (*firstChar <= *lastChar) ? (1 + *lastChar - *firstChar) : 0;
}


/********************************************************************
 *                      CreateIndexLookupTable
 ********************************************************************
 * SYNOPSIS:       Creates a lookup table for character mapping
 *                 information based on a given TrueType character map.
 * 
 * PARAMETERS:     TT_CharMap map
 *                    The character map used to create the lookup table.
 * 
 * RETURNS:        MemHandle
 *                    A memory handle for the created lookup table.
 * 
 * STRATEGY:       - Allocate memory for the lookup table.
 *                 - Populate the lookup table by mapping Unicode values
 *                   to corresponding PC/GEOS character indexes.
 *                 - Sort the lookup table entries based on TrueType
 *                   character index for efficient lookup.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      30.09.24  JK        Initial Revision
 *******************************************************************/

MemHandle CreateIndexLookupTable( const TT_CharMap  map )
{
        MemHandle     memHandle;
        LookupEntry*  lookupTable;
        int           i;


        memHandle = MemAlloc( NUM_CHARMAPENTRIES * sizeof( LookupEntry ),
                              HF_SHARABLE | HF_SWAPABLE, HAF_LOCK );
EC(     ECCheckMemHandle( memHandle ) );

        lookupTable = (LookupEntry*)MemDeref( memHandle );
EC(     ECCheckBounds( lookupTable ) );

        for( i = 0; i < NUM_CHARMAPENTRIES; ++i )
        {
                lookupTable[i].ttindex = TT_Char_Index( map, geosCharMap[i].unicode );
                lookupTable[i].geoscode = (char)i + C_SPACE;
        }

        qsort( lookupTable, NUM_CHARMAPENTRIES, sizeof( LookupEntry ), compareLookupEntries );

        MemUnlock( memHandle );
        return memHandle;
}


static int _pascal compareLookupEntries( const void *a, const void *b ) 
{
        return (int)((LookupEntry *)a)->ttindex - (int)((LookupEntry *)b)->ttindex;
}


/********************************************************************
 *                      GetGEOSCharForIndex
 ********************************************************************
 * SYNOPSIS:       Searches the lookup table for a given TrueType
 *                 character index and returns the corresponding GEOS
 *                 character code.
 * 
 * PARAMETERS:     LookupEntry* lookupTable
 *                    Pointer to the lookup table containing character
 *                    mapping information.
 * 
 *                 word index
 *                    The TrueType character index to search for.
 * 
 * RETURNS:        word
 *                    The corresponding GEOS character code, or 0 if
 *                    the index is not found in the lookup table.
 * 
 * STRATEGY:       - Implement a binary search over the sorted lookup table
 *                   to efficiently find the corresponding GEOS character.
 *                 - The search iterates by adjusting the left and right
 *                   bounds until the matching index is found or the search
 *                   space is exhausted.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      30.09.24  JK        Initial Revision
 *******************************************************************/

word  GetGEOSCharForIndex( const LookupEntry* lookupTable, const word index )
{
        int  left = 0;
        int  right = NUM_CHARMAPENTRIES - 1;


        while( left <= right )
        {
                int mid = left + ( (right - left) >> 1 );
                if( lookupTable[mid].ttindex == index )
                        return lookupTable[mid].geoscode; 
                else if( lookupTable[mid].ttindex < index )
                        left = mid + 1;
                else
                        right = mid - 1;
        }
        return 0;
}

