/***********************************************************************
 *
 *	Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttinit.c
 *
 * AUTHOR:	  Jirka Kunze: December 20 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	20/12/22  JK	    Initial version
 *
 * DESCRIPTION:
 *	Definition of driver function DR_INIT.
 ***********************************************************************/

#include "ttinit.h"
#include <fileEnum.h>
#include <geos.h>
#include <heap.h>
#include <ec.h>


void _pascal TrueType_Init()
{       
        //Speicherblöcke allocieren
        //FreeType Engine initialisiern
}

void _pascal TrueType_Exit()
{
        //FreeType Engine deinitialisieren
        //Speicherblöcke freen
}


void _pascal TrueType_InitFonts( MemHandle fontInfoBlock )
{
        FileEnumParams   ttfEnumParams;
        word             numOtherFiles;
        word             numFiles;
        word             file;
        FileLongName*    ptrFileName;
        MemHandle        fileEnumBlock    = NullHandle;
        FileExtAttrDesc  ttfExtAttrDesc[] =
                { { FEA_NAME, 0, sizeof( FileLongName ), NULL },
                  { FEA_END_OF_LIST, 0, 0, NULL } };


        FilePushDir();

        /* go to font/ttf directory */
        if( FileSetCurrentPath( SP_FONT, TTF_DIRECTORY ) == NullHandle )
                goto Fin;

        /* get all filenames contained in current directory */
        ttfEnumParams.FEP_searchFlags   = FESF_NON_GEOS;
        ttfEnumParams.FEP_returnAttrs   = &ttfExtAttrDesc;
        ttfEnumParams.FEP_returnSize    = sizeof( FileLongName );
        ttfEnumParams.FEP_matchAttrs    = NullHandle;
        ttfEnumParams.FEP_bufSize       = FE_BUFSIZE_UNLIMITED;
        ttfEnumParams.FEP_skipCount     = 0;
        ttfEnumParams.FEP_callback      = NullHandle;
        ttfEnumParams.FEP_callbackAttrs = NullHandle;
        ttfEnumParams.FEP_headerSize    = 0;

        numFiles = FileEnum( &ttfEnumParams, &fileEnumBlock, &numOtherFiles );

        if( numFiles == 0 )
                goto Fin;

        ECCheckMemHandle( fileEnumBlock );

        /* iterate over all filenames and try to register a font.*/
        ptrFileName = MemLock( fileEnumBlock );
        for( file = 0; file < numFiles; ++file )
                TrueType_ProcessFont( ptrFileName++, fontInfoBlock );

        MemFree( fileEnumBlock );

Fin:
        FilePopDir();
}


TT_Error TrueType_ProcessFont( const char* file, MemHandle fontInfoBlock )
{
        FileHandle      truetypeFile;
        TT_Face         face;
        TT_Error        error;


        /* open truetype file */
        truetypeFile = FileOpen( file, FILE_ACCESS_R | FILE_DENY_W );
        
        ECCheckFileHandle( truetypeFile );

        error = TT_Open_Face( truetypeFile, &face );
        if( error )
                goto Fail;

        //Font ID erzeugen
        //Font ID noch nicht bekannt?
                //FontsAvailEntry erzeugen und füllen
                //FontInfo erzeugen und füllen
                //Referenz auf FontInfo in FAE füllen
                //Outline anhängen und füllen
        //Gibt es schon noch keine Outline für den Style?
                //Outline anhängen und füllen

Fail:        
        FileClose( truetypeFile, FALSE );
        return error;
}
