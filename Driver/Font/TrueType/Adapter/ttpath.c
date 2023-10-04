/***********************************************************************
 *
 *                      Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttpath.c
 *
 * AUTHOR:	  Jirka Kunze: December 23 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/23/22  JK	    Initial version
 *
 * DESCRIPTION:
 *	Definition of driver function DR_FONT_CHAR_METRICS.
 ***********************************************************************/

#include "ttadapter.h"


/********************************************************************
 *                      TrueType_Gen_Path
 ********************************************************************
 * SYNOPSIS:	  Draw outline of the given charcode to gstate.
 * 
 * PARAMETERS:    gstate                GStateHande in which the outline 
 *                                      of the character is written.
 *                pathFlags             FGPF_POSTSCRIPT - transform for 
 *                                           use as Postscript Type 1 or Type 3 font.
 *			                FGPF_SAVE_STATE - do save/restore for GState
 *                character             Character to build (GEOS Char).
 *                pointSize             Desired point size.
 *                *fontInfo             Pointer to FontInfo structure.
 *                *outlineEntry         Ptr. to outline entry containing 
 *                                      TrueTypeOutlineEntry.
 *                varBlock              Memory handle to var block.
 * 
 * RETURNS:       void 
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

void _pascal TrueType_Gen_Path(          
                        GStateHandle         gstate,
                        FontGenPathFlags     pathFlags,
                        word                 character,
                        WWFixedAsDWord       pointSize,
                        const FontInfo*      fontInfo, 
                        const OutlineEntry*  outlineEntry,
                        MemHandle            varBlock )
{
        TrueTypeVars*          trueTypeVars;
        TrueTypeOutlineEntry*  trueTypeOutline;
        TT_UShort              charIndex;


EC(     ECCheckGStateHandle( gstate ) );
EC(     ECCheckBounds( (void*)fontInfo ) );
EC(     ECCheckBounds( (void*)outlineEntry ) );
EC(     ECCheckMemHandle( varBlock ) );

        /* get trueTypeVar block */
        trueTypeVars = MemLock( varBlock );
EC(     ECCheckBounds( (void*)trueTypeVars ) );

        /* open face, create instance and glyph */
        if( TrueType_Lock_Face(trueTypeVars, trueTypeOutline) )
                goto Fail;

        TT_New_Glyph( FACE, &GLYPH );

         /* get TT char index */
        charIndex = TT_Char_Index( CHAR_MAP, GeosCharToUnicode( character ) );

        /* set pointsize and get metrics */
        TT_Set_Instance_CharSize( INSTANCE, ( pointSize >> 10 ) );

        /* load glyph and load glyphs outline */
        TT_Load_Glyph( INSTANCE, GLYPH, charIndex, TTLOAD_DEFAULT );
        TT_Get_Glyph_Outline( GLYPH, &OUTLINE );

        /* write prologue */
        if( pathFlags & FGPF_SAVE_STATE )
                GrSaveState( gstate );


        //TODO


        /* write epilogue */
        if( pathFlags & FGPF_SAVE_STATE )
                GrRestoreState( gstate );

        TT_Done_Glyph( GLYPH );

Fail:
        MemUnlock( varBlock );
}


/********************************************************************
 *                      TrueType_Gen_In_Region
 ********************************************************************
 * SYNOPSIS:	  
 * 
 * PARAMETERS:    
 * 
 * RETURNS:       
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

void _pascal TrueType_Gen_In_Region( 
                        GStateHandle         gstate,
                        Handle               regionPath,
                        word                 character,
                        WWFixedAsDWord       pointSize,
			const FontInfo*      fontInfo, 
                        const OutlineEntry*  outlineEntry,
                        MemHandle            varBlock )
{

}
