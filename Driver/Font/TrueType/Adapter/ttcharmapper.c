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

#define MIN_GEOS_CHAR           ( C_SPACE )
#define FIRST_EXTENDED_CHAR     0x80
#define MAX_GEOS_CHAR           0xff

#define NUM_CHARMAPENTRIES      ( sizeof(geosCharMap) / sizeof(word) )
#define NUM_GEOS_CHARS          ( MAX_GEOS_CHAR - MIN_GEOS_CHAR + 1 )


/***********************************************************************
 *      internal functions
 ***********************************************************************/


word geosCharMap[] = 
{
/*      unicode */
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

        if( geosChar < FIRST_EXTENDED_CHAR )
                return geosChar;

        return geosCharMap[ geosChar - FIRST_EXTENDED_CHAR ];
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
        word  geosChar;
        word  unicode;
        word  firstFound = 0x100;
        word  lastFound  = 0;


        for( geosChar = MIN_GEOS_CHAR; geosChar <= MAX_GEOS_CHAR; ++geosChar )
        {
                unicode = GeosCharToUnicode( geosChar );

                if( unicode == 0 )
                        continue;

                if( TT_Char_Index( map, unicode ) )
                {
                        if( firstFound == 0x100 )
                                firstFound = geosChar;
                        lastFound = geosChar;
                }
        }

        *firstChar = (firstFound <= MAX_GEOS_CHAR) ? (char)firstFound : 255;
        *lastChar  = (lastFound >= MIN_GEOS_CHAR)  ? (char)lastFound  : 0;

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
        word          geosChar;
        word          unicode;
        int           i;


        memHandle = MemAllocSetOwner( GeodeGetCodeProcessHandle(), 
                                NUM_GEOS_CHARS * sizeof( LookupEntry ),
                              	HF_SHARABLE | HF_SWAPABLE, HAF_LOCK | HAF_NO_ERR);
EC(     ECCheckMemHandle( memHandle ) );

        lookupTable = (LookupEntry*)MemDeref( memHandle );
EC(     ECCheckBounds( lookupTable ) );

        for( geosChar = MIN_GEOS_CHAR, i = 0; geosChar <= MAX_GEOS_CHAR; ++geosChar, ++i )
        {
                unicode = GeosCharToUnicode( geosChar );
                lookupTable[i].ttindex = unicode ? TT_Char_Index( map, unicode ) : 0;
                lookupTable[i].geoscode = (char)geosChar;
        }

        SortLookupTable( lookupTable, NUM_GEOS_CHARS );

        MemUnlock( memHandle );
        return memHandle;
}


static void SortLookupTable(LookupEntry* table, int count)
{
    int         i, j;
    LookupEntry temp;

    for (i = 1; i < count; ++i)
    {
        temp = table[i];
        for (j = i; j > 0 && table[j - 1].ttindex > temp.ttindex; --j)
            table[j] = table[j - 1];
        table[j] = temp;
    }
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
        int  right = NUM_GEOS_CHARS - 1;


        while( left <= right )
        {
                int mid = (right + left) >> 1;
                if( lookupTable[mid].ttindex == index )
                        return lookupTable[mid].geoscode; 
                else if( lookupTable[mid].ttindex < index )
                        left = mid + 1;
                else
                        right = mid - 1;
        }
        return 0;
}

