/***********************************************************************
 *
 *                      Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttadapter.c
 *
 * AUTHOR:	  Jirka Kunze: July 5 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/5/22	  JK	    Initial version
 *
 * DESCRIPTION:
 *	Functions to adapt the FreeGEOS font driver interface to the 
 *      FreeType library interface.
 *
 ***********************************************************************/

#include "ttadapter.h"
#include <heap.h>


/********************************************************************
 *                      Init_FreeType
 ********************************************************************
 * SYNOPSIS:	  Initialises the FreeType Engine with the kerning 
 *                extension. This is the adapter function for DR_INIT.
 * 
 * PARAMETERS:    void
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      Initialises the FreeType engine by delegating to 
 *                TT_Init_FreeType() and TT_Init_Kerning().
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      7/15/22   JK        Initial Revision
 *******************************************************************/

TT_Error _pascal Init_FreeType()
{
        TT_Error        error;
 
 
        error = TT_Init_FreeType();
        if ( error != TT_Err_Ok )
                return error;

        //TT_Init_Kerning()

        return TT_Err_Ok;
}


/********************************************************************
 *                      Exit_FreeType
 ********************************************************************
 * SYNOPSIS:	  Deinitialises the FreeType Engine. This is the 
 *                adapter function for DR_EXIT.
 * 
 * PARAMETERS:    void
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      Deinitialises the FreeType engine by delegating to 
 *                TT_Done_FreeType().
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      7/15/22   JK        Initial Revision
 *******************************************************************/

TT_Error _pascal Exit_FreeType() 
{
        return TT_Done_FreeType();
}


/********************************************************************
 *                      Get_Font_Info
 ********************************************************************
 * SYNOPSIS:	  Returns the FontID, FontWeight and FontStyle of the 
 *                font with the given FileHandle.
 * 
 * PARAMETERS:    FileHandle    Handle of the font.
 *                FontID*       Pointer in which the ID of the 
 *                              font returned.
 *                FontWeight*   Pointer in which the weight of the 
 *                              font returned.
 *                TextStyle*    Pointer in which the style of the 
 *                              font returned.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *       / /22  JK        Initial Revision
 *******************************************************************/

TT_Error _pascal Get_Font_Info( const FileHandle  fileHandle, 
                                FontID* fontID, 
                                FontWeight* fontWeight,
                                TextStyle* textStyle )
{
        TT_Error        error;
        TT_Face         face;


        ECCheckFileHandle( fileHandle );

        error = TT_Open_Face( fileHandle, &face );
        if ( error != TT_Err_Ok )
                return error;

        /* load font family name for ID generation */
        //TODO

        /* load font weight */
        //TODO

        /* load text style */
        //TODO


        TT_Flush_Face( face );

        return TT_Err_Ok;
}


/********************************************************************
 *                      Get_Char_Metrics
 ********************************************************************
 * SYNOPSIS:	  Returns the metrics of the passed glyph of the font. 
 * 
 * PARAMETERS:    FileHandle    Handle of the font.
 *                word          Character to get metrics of.
 *                WBFixed*      Pointer in wich the minimum of x returned.
 *                WBFixed*      Pointer in wich the minimum of y returned.
 *                WBFixed*      Pointer in wich the maximum of x returned.
 *                WBFixed*      Pointer in wich the maximum of y returned.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *       / /22   JK        Initial Revision
 *******************************************************************/
TT_Error _pascal Get_Char_Metrics( const FileHandle  fileHandle,
                                   const word        character,
                                   WBFixed*          minX,
                                   WBFixed*          minY,
                                   WBFixed*          maxX,
                                   WBFixed*          maxY )
{
        return TT_Err_Ok;
}
