/***********************************************************************
 *
 *	Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttadapter.c
 *
 * AUTHOR:	  Marcus Groeber: July 16 2023
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	16/07/23  MG	    Initial version
 *
 * DESCRIPTION:
 *	Common functions used by TrueType Adapter.
 ***********************************************************************/

#include "ttadapter.h"
#include "ttcharmapper.h"
#include <ec.h>
#include <geode.h>

static int strcmp( const char* s1, const char* s2 );


/********************************************************************
 *                      TrueType_Lock_Face
 ********************************************************************
 * SYNOPSIS:	  Active a particular face.
 * 
 * PARAMETERS:    *trueTypeVars        
 *                *entry                Ptr to font entry.
 * 
 * RETURNS:       TT_Error
 * 
 * STRATEGY:      - check if face is already loaded
 *                - if not, open file with face and instance
 *                - load face from file
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      16/07/23  MG        Initial Revision
 * 
 *******************************************************************/

Boolean TrueType_Lock_Face(TRUETYPE_VARS, TrueTypeOutlineEntry* entry)
{
        Boolean failure = TRUE;

        if( strcmp( entry->TTOE_fontFileName, trueTypeVars->entry.TTOE_fontFileName )==0 )
        {
            failure = FALSE;
            goto Fin;
        }
        
        TrueType_Free_Face( trueTypeVars );

        FilePushDir();
        FileSetCurrentPath( SP_FONT, TTF_DIRECTORY );

        /* get filename and load ttf file */
        TTFILE = FileOpen( entry->TTOE_fontFileName, FILE_ACCESS_R | FILE_DENY_W );    
EC(     ECCheckFileHandle( TTFILE) );

        /* change owner to ourselves, to make handle persist if application closes */
        HandleModifyOwner( (MemHandle)TTFILE, GeodeGetCodeProcessHandle() );
        FilePopDir();

        if( TT_Open_Face( TTFILE, &FACE ) )
                goto Fin;
        if ( TT_Get_Face_Properties( FACE, &FACE_PROPERTIES ) )
                goto Fail;
        if ( getCharMap( trueTypeVars, &CHAR_MAP ) )
                goto Fail;
        if ( TT_New_Instance( FACE, &INSTANCE ) )
                goto Fail;

        /* font has been fully loaded */
        trueTypeVars->entry = *entry;
        failure = FALSE;
Fin:
        return failure;
Fail:
        TT_Close_Face( FACE );
        goto Fin;
}


/********************************************************************
 *                      TrueType_Unlock_Face
 ********************************************************************
 * SYNOPSIS:	  Deactivate the currently active face.
 * 
 * PARAMETERS:    *trueTypeVars        
 * 
 * RETURNS:       TT_Error
 * 
 * STRATEGY:      - free resources used by face
 *                - close file
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      16/07/23  MG        Initial Revision
 * 
 *******************************************************************/

void TrueType_Unlock_Face(TRUETYPE_VARS)
{
        /* Will be used for unlocking moveable font resources */
        (void)trueTypeVars;
}

/********************************************************************
 *                      TrueType_Free_Face
 ********************************************************************
 * SYNOPSIS:	  Close the currently active face.
 * 
 * PARAMETERS:    *trueTypeVars        
 * 
 * RETURNS:       TT_Error
 * 
 * STRATEGY:      - free resources used by instance and face
 *                - close file
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      16/07/23  MG        Initial Revision
 * 
 *******************************************************************/

void TrueType_Free_Face(TRUETYPE_VARS)
{
        if ( trueTypeVars->entry.TTOE_fontFileName[0] )
        {
            TT_Done_Instance( INSTANCE );
            TT_Close_Face( FACE );
            trueTypeVars->entry.TTOE_fontFileName[0] = 0;
        }
        if ( TTFILE )
        {
            FileClose( TTFILE, FALSE );
            TTFILE = NullHandle;
        }
}

static int strcmp( const char* s1, const char* s2 )
{
        while ( *s1 && ( *s1 == *s2 ) )
        {
                ++s1;
                ++s2;
        }
        return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}
