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
#include <font.h>
#include <graphics.h>


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
 *                char*         Pointer to name of font family.
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
                                FontID*           fontID, 
                                char*             fontFamilyName, 
                                FontWeight*       fontWeight,
                                TextStyle*        textStyle )
{
        TT_Error            error;
        TT_Face             face;
        TT_Face_Properties  props;
        TT_UShort           nameIndexFamily;
        TT_UShort           nameIndexStyle;
        TT_UShort           nameIndex;
        TT_String*          stringPtr;
        TT_UShort*          length;


        ECCheckFileHandle( fileHandle );

        error = TT_Open_Face( fileHandle, &face );
        if ( error != TT_Err_Ok )
                return error;

        error = TT_Get_Face_Properties( face, &props );
        if ( error != TT_Err_Ok )
                return error;

        /* process fontweight */
        *fontWeight = mapFontWeight( props.os2->usWeightClass );

        /* find index for name and family in name table */
        for( nameIndex = 0; nameIndex < props.num_Names; ++nameIndex )
        {
                TT_UShort  platformID;
                TT_UShort  encodingID;
                TT_UShort  languageID;
                TT_UShort  nameID;

                error = TT_Get_Name_ID( face,
                                        nameIndex,
                                        &platformID,
                                        &encodingID,
                                        &languageID,
                                        &nameID );
                if ( error != TT_Err_Ok )
                        return error;

                if ( nameID == NAME_ID_FAMILY )
                        nameIndexFamily = nameIndex;

                if ( nameID == NAME_ID_STYLE )
                        nameIndexStyle = nameIndex;
        }

        /* process font family name */
        error = TT_Get_Name_String( face,
                                    nameIndexFamily,
                                    &stringPtr,
                                    &length );
        if ( error != TT_Err_Ok )
                return error;

        //*fontID = calculateFontID( stringPtr );
        copyFamilyName( stringPtr, fontFamilyName );

        /* process text style */
        error = TT_Get_Name_String( face,
                                    nameIndexStyle,
                                    &stringPtr,
                                    &length );
        if ( error != TT_Err_Ok )
                return error;

        *textStyle = mapTextStyle( stringPtr );

        /* free resouces and exit */
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
 *                boolean       Indicates that the rounded results are expected.
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
                                   Boolean           rounded,
                                   WBFixed*          minX,
                                   WBFixed*          minY,
                                   WBFixed*          maxX,
                                   WBFixed*          maxY )
{
        return TT_Err_Ok;
}


static
int /* TextStyle */  
mapTextStyle( TT_String*  style )
{
        return TS_BOLD;
}

static
int /* FontWeight */  
mapFontWeight( TT_UShort  weight )
{
        //TODO: definition of FontWeight in font.h is incomplete
        return FW_NORMAL;
}

/*static
FontID
calculateFontID( TT_String*  familyName ) 
{
        return 0;
}*/

static 
void 
copyFamilyName( TT_String* familyNameFromFile, char* fontFamilyName ) 
{

}
