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
 *	05.12.22  JK	    Initial version
 *      21.09.25  JK        refactoring
 *
 * DESCRIPTION:
 *	Functions for mapping character from FreeGEOS charset zu Unicode 
 *      charset.
 ***********************************************************************/

#include <ttcharmapper.h>
#include <freetype.h>
#include <ttmemory.h>
#include <geos.h>
#include <geode.h>
#include <unicode.h>
#include <Ansi/stdlib.h>

#define NUM_CHARMAPENTRIES      ( sizeof(geosCharMap) / sizeof(word) )
#define MIN_GEOS_CHAR           ( C_SPACE )
#define MAX_GEOS_CHAR           ( NUM_CHARMAPENTRIES + MIN_GEOS_CHAR )
#define GEOS_CHAR_INDEX( i )    ( i - MIN_GEOS_CHAR )


/***********************************************************************
 *      internal functions
 ***********************************************************************/

int _pascal compareLookupEntries(const void *a, const void *b);


word geosCharMap[] = 
{
/*      unicode */
        C_SPACE,
        C_EXCLAMATION_MARK,
        C_QUOTATION_MARK,
        C_NUMBER_SIGN,
        C_DOLLAR_SIGN,
        C_PERCENT_SIGN,
        C_AMPERSAND,
        C_APOSTROPHE_QUOTE,
        C_OPENING_PARENTHESIS,
        C_CLOSING_PARENTHESIS,
        C_ASTERISK,
        C_PLUS_SIGN,   
        C_COMMA,   
        C_HYPHEN_MINUS,   
        C_PERIOD,  
        C_SLASH,   
        C_DIGIT_ZERO,  
        C_DIGIT_ONE,   
        C_DIGIT_TWO,   
        C_DIGIT_THREE, 
        C_DIGIT_FOUR,  
        C_DIGIT_FIVE,  
        C_DIGIT_SIX,   
        C_DIGIT_SEVEN, 
        C_DIGIT_EIGHT, 
        C_DIGIT_NINE, 
        C_COLON,   
        C_SEMICOLON,   
        C_LESS_THAN_SIGN, 
        C_EQUALS_SIGN, 
        C_GREATER_THAN_SIGN,   
        C_QUESTION_MARK,  
        C_COMMERCIAL_AT,  
        C_LATIN_CAPITAL_LETTER_A, 
        C_LATIN_CAPITAL_LETTER_B, 
        C_LATIN_CAPITAL_LETTER_C, 
        C_LATIN_CAPITAL_LETTER_D, 
        C_LATIN_CAPITAL_LETTER_E, 
        C_LATIN_CAPITAL_LETTER_F, 
        C_LATIN_CAPITAL_LETTER_G, 
        C_LATIN_CAPITAL_LETTER_H, 
        C_LATIN_CAPITAL_LETTER_I, 
        C_LATIN_CAPITAL_LETTER_J, 
        C_LATIN_CAPITAL_LETTER_K, 
        C_LATIN_CAPITAL_LETTER_L, 
        C_LATIN_CAPITAL_LETTER_M, 
        C_LATIN_CAPITAL_LETTER_N, 
        C_LATIN_CAPITAL_LETTER_O, 
        C_LATIN_CAPITAL_LETTER_P, 
        C_LATIN_CAPITAL_LETTER_Q, 
        C_LATIN_CAPITAL_LETTER_R, 
        C_LATIN_CAPITAL_LETTER_S, 
        C_LATIN_CAPITAL_LETTER_T, 
        C_LATIN_CAPITAL_LETTER_U, 
        C_LATIN_CAPITAL_LETTER_V, 
        C_LATIN_CAPITAL_LETTER_W, 
        C_LATIN_CAPITAL_LETTER_X, 
        C_LATIN_CAPITAL_LETTER_Y, 
        C_LATIN_CAPITAL_LETTER_Z, 
        C_OPENING_SQUARE_BRACKET,   
        C_BACKSLASH,   
        C_CLOSING_SQUARE_BRACKET,   
        C_SPACING_CIRCUMFLEX,  
        C_SPACING_UNDERSCORE,  
        C_SPACING_GRAVE,  
        C_LATIN_SMALL_LETTER_A, 
        C_LATIN_SMALL_LETTER_B, 
        C_LATIN_SMALL_LETTER_C, 
        C_LATIN_SMALL_LETTER_D, 
        C_LATIN_SMALL_LETTER_E, 
        C_LATIN_SMALL_LETTER_F, 
        C_LATIN_SMALL_LETTER_G, 
        C_LATIN_SMALL_LETTER_H, 
        C_LATIN_SMALL_LETTER_I, 
        C_LATIN_SMALL_LETTER_J, 
        C_LATIN_SMALL_LETTER_K, 
        C_LATIN_SMALL_LETTER_L, 
        C_LATIN_SMALL_LETTER_M, 
        C_LATIN_SMALL_LETTER_N, 
        C_LATIN_SMALL_LETTER_O, 
        C_LATIN_SMALL_LETTER_P, 
        C_LATIN_SMALL_LETTER_Q, 
        C_LATIN_SMALL_LETTER_R, 
        C_LATIN_SMALL_LETTER_S, 
        C_LATIN_SMALL_LETTER_T, 
        C_LATIN_SMALL_LETTER_U, 
        C_LATIN_SMALL_LETTER_V, 
        C_LATIN_SMALL_LETTER_W, 
        C_LATIN_SMALL_LETTER_X, 
        C_LATIN_SMALL_LETTER_Y, 
        C_LATIN_SMALL_LETTER_Z, 
        C_OPENING_CURLY_BRACKET,    
        C_VERTICAL_BAR,   
        C_CLOSING_CURLY_BRACKET,    
        C_TILDE,   
        C_DELETE,  
        C_LATIN_CAPITAL_LETTER_A_DIAERESIS, 
        C_LATIN_CAPITAL_LETTER_A_RING,  
        C_LATIN_CAPITAL_LETTER_C_CEDILLA,   
        C_LATIN_CAPITAL_LETTER_E_ACUTE, 
        C_LATIN_CAPITAL_LETTER_N_TILDE, 
        C_LATIN_CAPITAL_LETTER_O_DIAERESIS, 
        C_LATIN_CAPITAL_LETTER_U_DIAERESIS, 
        C_LATIN_SMALL_LETTER_A_ACUTE,     
        C_LATIN_SMALL_LETTER_A_GRAVE,     
        C_LATIN_SMALL_LETTER_A_CIRCUMFLEX, 
        C_LATIN_SMALL_LETTER_A_DIAERESIS, 
        C_LATIN_SMALL_LETTER_A_TILDE,     
        C_LATIN_SMALL_LETTER_A_RING,      
        C_LATIN_SMALL_LETTER_C_CEDILLA,   
        C_LATIN_SMALL_LETTER_E_ACUTE,     
        C_LATIN_SMALL_LETTER_E_GRAVE,     
        C_LATIN_SMALL_LETTER_E_CIRCUMFLEX, 
        C_LATIN_SMALL_LETTER_E_DIAERESIS, 
        C_LATIN_SMALL_LETTER_I_ACUTE,     
        C_LATIN_SMALL_LETTER_I_GRAVE,     
        C_LATIN_SMALL_LETTER_I_CIRCUMFLEX, 
        C_LATIN_SMALL_LETTER_I_DIAERESIS, 
        C_LATIN_SMALL_LETTER_N_TILDE,     
        C_LATIN_SMALL_LETTER_O_ACUTE,     
        C_LATIN_SMALL_LETTER_O_GRAVE,     
        C_LATIN_SMALL_LETTER_O_CIRCUMFLEX, 
        C_LATIN_SMALL_LETTER_O_DIAERESIS, 
        C_LATIN_SMALL_LETTER_O_TILDE,     
        C_LATIN_SMALL_LETTER_U_ACUTE,     
        C_LATIN_SMALL_LETTER_U_GRAVE,     
        C_LATIN_SMALL_LETTER_U_CIRCUMFLEX, 
        C_LATIN_SMALL_LETTER_U_DIAERESIS, 
        C_DAGGER,  
        C_DEGREE_SIGN, 
        C_CENT_SIGN,   
        C_POUND_SIGN,  
        C_SECTION_SIGN,   
        C_BULLET,  
        C_PARAGRAPH_SIGN, 
        C_LATIN_SMALL_LETTER_SHARP_S,     
        C_REGISTERED_TRADE_MARK_SIGN,     
        C_COPYRIGHT_SIGN, 
        C_TRADEMARK,   
        C_SPACING_ACUTE,  
        C_SPACING_DIAERESIS,   
        C_NOT_EQUAL_TO,   
        C_LATIN_CAPITAL_LETTER_A_E, 
        C_LATIN_CAPITAL_LETTER_O_SLASH, 
        C_INFINITY,
        C_PLUS_OR_MINUS_SIGN,  
        C_LESS_THAN_OR_EQUAL_TO,    
        C_GREATER_THAN_OR_EQUAL_TO, 
        C_YEN_SIGN,
        C_MICRO_SIGN,  
        C_PARTIAL_DIFFERENTIAL,     
        C_N_ARY_SUMMATION,     
        C_N_ARY_PRODUCT,  
        C_GREEK_SMALL_LETTER_PI,    
        C_INTEGRAL,
        C_FEMININE_ORDINAL_INDICATOR,     
        C_MASCULINE_ORDINAL_INDICATOR,    
        C_GREEK_CAPITAL_LETTER_OMEGA,     
        C_LATIN_SMALL_LETTER_A_E,   
        C_LATIN_SMALL_LETTER_O_SLASH,     
        C_INVERTED_QUESTION_MARK,   
        C_INVERTED_EXCLAMATION_MARK,      
        C_NOT_SIGN,
        C_SQUARE_ROOT, 
        C_LATIN_SMALL_LETTER_SCRIPT_F,    
        C_ALMOST_EQUAL_TO,     
        C_GREEK_CAPITAL_LETTER_DELTA,     
        C_LEFT_POINTING_GUILLEMET,  
        C_RIGHT_POINTING_GUILLEMET, 
        C_HORIZONTAL_ELLIPSIS, 
        C_NON_BREAKING_SPACE,  
        C_LATIN_CAPITAL_LETTER_A_GRAVE, 
        C_LATIN_CAPITAL_LETTER_A_TILDE, 
        C_LATIN_CAPITAL_LETTER_O_TILDE, 
        C_LATIN_CAPITAL_LETTER_O_E,     
        C_LATIN_SMALL_LETTER_O_E,   
        C_EN_DASH, 
        C_EM_DASH, 
        C_DOUBLE_TURNED_COMMA_QUOTATION_MARK, 
        C_DOUBLE_COMMA_QUOTATION_MARK,    
        C_SINGLE_TURNED_COMMA_QUOTATION_MARK, 
        C_SINGLE_COMMA_QUOTATION_MARK,    
        C_DIVISION_SIGN,  
        C_BLACK_DIAMOND,  
        C_LATIN_SMALL_LETTER_Y_DIAERESIS, 
        C_LATIN_CAPITAL_LETTER_Y_DIAERESIS, 
        C_FRACTION_SLASH, 
        C_EURO_SIGN,   
        C_LEFT_POINTING_SINGLE_GUILLEMET, 
        C_RIGHT_POINTING_SINGLE_GUILLEMET, 
        C_LATIN_SMALL_LETTER_Y_ACUTE,     
        C_LATIN_CAPITAL_LETTER_Y_ACUTE,   
        C_DOUBLE_DAGGER,  
        C_MIDDLE_DOT,  
        C_LOW_SINGLE_COMMA_QUOTATION_MARK, 
        C_LOW_DOUBLE_COMMA_QUOTATION_MARK, 
        C_PER_MILLE_SIGN, 
        C_LATIN_CAPITAL_LETTER_A_CIRCUMFLEX, 
        C_LATIN_CAPITAL_LETTER_E_CIRCUMFLEX, 
        C_LATIN_CAPITAL_LETTER_A_ACUTE, 
        C_LATIN_CAPITAL_LETTER_E_DIAERESIS, 
        C_LATIN_CAPITAL_LETTER_E_GRAVE, 
        C_LATIN_CAPITAL_LETTER_I_ACUTE, 
        C_LATIN_CAPITAL_LETTER_I_CIRCUMFLEX, 
        C_LATIN_CAPITAL_LETTER_I_DIAERESIS, 
        C_LATIN_CAPITAL_LETTER_I_GRAVE, 
        C_LATIN_CAPITAL_LETTER_O_ACUTE, 
        C_LATIN_CAPITAL_LETTER_O_CIRCUMFLEX,  
        0,  //no character
        C_LATIN_CAPITAL_LETTER_O_GRAVE, 
        C_LATIN_CAPITAL_LETTER_U_ACUTE, 
        C_LATIN_CAPITAL_LETTER_U_CIRCUMFLEX, 
        C_LATIN_CAPITAL_LETTER_U_GRAVE, 
        C_LATIN_SMALL_LETTER_DOTLESS_I,   
        C_MODIFIER_LETTER_CIRCUMFLEX,     
        C_SPACING_TILDE,  
        C_SPACING_MACRON, 
        C_SPACING_BREVE,  
        C_SPACING_DOT_ABOVE,   
        C_SPACING_RING_ABOVE,  
        C_SPACING_CEDILLA,     
        C_SPACING_DOUBLE_ACUTE,     
        C_SPACING_OGONEK, 
        C_MODIFIER_LETTER_HACEK,
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

        return geosCharMap[ GEOS_CHAR_INDEX( geosChar ) ];
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
#pragma code_seg(ttcmap_TEXT)
word CountValidGeosChars( const TT_CharMap  map, char*  firstChar, char*  lastChar )
{
        word  charIndex;
        word  firstFound = NUM_CHARMAPENTRIES;
        word  lastFound = 0;


        for( charIndex = 0; charIndex < NUM_CHARMAPENTRIES; ++charIndex )
        {
                if( TT_Char_Index( map, geosCharMap[charIndex] ) )
                {
                        if( firstFound > charIndex ) firstFound = charIndex;
                        lastFound = charIndex;
                }
        }

        *firstChar = (firstFound < NUM_CHARMAPENTRIES) ? (char)(firstFound + C_SPACE) : 255;
        *lastChar = (lastFound > 0) ? (char)(lastFound + C_SPACE) : 0;

        return (*firstChar <= *lastChar) ? (1 + *lastChar - *firstChar) : 0;
}
#pragma code_seg()

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
#pragma code_seg(ttcmap_TEXT)
MemHandle CreateIndexLookupTable( const TT_CharMap  map )
{
        MemHandle     memHandle;
        LookupEntry*  lookupTable;
        int           i;


        memHandle = MemAllocSetOwner( GeodeGetCodeProcessHandle(), 
                                NUM_CHARMAPENTRIES * sizeof( LookupEntry ),
                              	HF_SHARABLE | HF_SWAPABLE, HAF_LOCK | HAF_NO_ERR);
EC(     ECCheckMemHandle( memHandle ) );

        lookupTable = (LookupEntry*)MemDeref( memHandle );
EC(     ECCheckBounds( lookupTable ) );

        for( i = 0; i < NUM_CHARMAPENTRIES; ++i )
        {
                lookupTable[i].ttindex = TT_Char_Index( map, geosCharMap[i] );
                lookupTable[i].geoscode = (char)i + C_SPACE;
        }

        qsort( lookupTable, NUM_CHARMAPENTRIES, sizeof( LookupEntry ), compareLookupEntries );

        MemUnlock( memHandle );
        return memHandle;
}


int _pascal compareLookupEntries( const void *a, const void *b ) 
{
        return (int)((LookupEntry *)a)->ttindex - (int)((LookupEntry *)b)->ttindex;
}
#pragma code_seg()

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

