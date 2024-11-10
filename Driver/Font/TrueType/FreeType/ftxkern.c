/*******************************************************************
 *
 *  ftxkern.c                                                    1.0
 *
 *    Kerning support extension.
 *
 *  Copyright 1996-1999 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg.
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT. By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 *
 *  The kerning support is currently part of the engine extensions.
 *
 ******************************************************************/

#include "ftxkern.h"

#include "tttypes.h"
#include "ttmemory.h"
#include "ttfile.h"
#include "ttobjs.h"
#include "ttload.h"  /* For the macros */
#include "tttags.h"
#include <ec.h>

/* Required by the tracing mode */
#undef  TT_COMPONENT
#define TT_COMPONENT  trace_any


/*******************************************************************
 *
 *  Function    :  SubTable_Load_0
 *
 *  Description :  Loads a format 0 kerning subtable data.
 *
 *  Input  :  kern0   pointer to the kerning subtable
 *
 *  Output :  error code
 *
 *  Notes  :  - Assumes that the stream is already `used'
 *
 *            - the file cursor must be set by the caller
 *
 *            - in case of error, the function _must_ destroy
 *              the data it allocates!
 *
 ******************************************************************/

  static TT_Error  Subtable_Load_0( TT_Kern_0*  kern0,
                                    PFace       input )
  {
    DEFINE_LOAD_LOCALS( input->stream );

    UShort            num_pairs, n;
    TT_Kern_0_Pair*   pairs;


    if ( ACCESS_Frame( 8 ) )
      return error;

    num_pairs            = GET_UShort();
    kern0->nPairs        = 0;
    kern0->searchRange   = GET_UShort();
    kern0->entrySelector = GET_UShort();
    kern0->rangeShift    = GET_UShort();

    /* we only set kern0->nPairs if the subtable has been loaded */

    FORGET_Frame();

    if ( GEO_ALLOC_ARRAY( kern0->pairsBlock, num_pairs, TT_Kern_0_Pair ) )
      return error;

    if ( ACCESS_Frame( num_pairs * 6 ) )
      goto Fail;

    pairs = GEO_LOCK( kern0->pairsBlock );
EC( ECCheckBounds( pairs ) );

    for ( n = 0; n < num_pairs; ++n )
    {
      pairs[n].left  = GET_UShort();
      pairs[n].right = GET_UShort();
      pairs[n].value = GET_UShort();

      if ( pairs[n].left >= input->numGlyphs || pairs[n].right >= input->numGlyphs )
      {
        FORGET_Frame();
        error = TT_Err_Invalid_Kerning_Table;
        goto Fail;
      }
    }

    GEO_UNLOCK( kern0->pairsBlock );

    FORGET_Frame();

    /* we're ok, set the pairs count */
    kern0->nPairs = num_pairs;

    return TT_Err_Ok;

    Fail:
      GEO_FREE( kern0->pairsBlock );
      return error;
  }

#ifdef TT_CONFIG_OPTION_SUPPORT_KERN2

/*******************************************************************
 *
 *  Function    :  SubTable_Load_2
 *
 *  Description :  Loads a format 2 kerning subtable data.
 *
 *  Input  :  kern2   pointer to the kerning subtable
 *            length  subtable length.  This is required as
 *                    the subheader doesn't give any indication
 *                    of the size of the `array' table.
 *
 *  Output :  error code
 *
 *  Notes  :  - Assumes that the stream is already `used'
 *
 *            - the file cursor must be set by the caller
 *
 *            - in case of error, the function _must_ destroy
 *              the data it allocates!
 *
 ******************************************************************/

  static TT_Error  Subtable_Load_2( TT_Kern_2*  kern2,
                                    PFace       input )
  {
    DEFINE_LOAD_LOCALS( input->stream );

    Long  table_base;

    UShort  left_offset, right_offset, array_offset;
    ULong   array_size;
    UShort  left_max, right_max, n;


    /* record the table offset */
    table_base = FILE_Pos();

    if ( ACCESS_Frame( 8 ) )
      return error;

    kern2->rowWidth = GET_UShort();
    left_offset     = GET_UShort();
    right_offset    = GET_UShort();
    array_offset    = GET_UShort();

    FORGET_Frame();

    /* first load left and right glyph classes */

    if ( FILE_Seek( table_base + left_offset ) ||
         ACCESS_Frame( 4 ) )
      return error;

    kern2->leftClass.firstGlyph = GET_UShort();
    kern2->leftClass.nGlyphs    = GET_UShort();

    FORGET_Frame();

    if ( ALLOC_ARRAY( kern2->leftClass.classes,
                      kern2->leftClass.nGlyphs,
                      UShort ) )
      return error;

    /* load left offsets */

    if ( ACCESS_Frame( kern2->leftClass.nGlyphs << 1 ) )
      goto Fail_Left;

    for ( n = 0; n < kern2->leftClass.nGlyphs; n++ )
      kern2->leftClass.classes[n] = GET_UShort();

    FORGET_Frame();

    /* right class */

    if ( FILE_Seek( table_base + right_offset ) ||
         ACCESS_Frame( 4 ) )
      goto Fail_Left;

    kern2->rightClass.firstGlyph = GET_UShort();
    kern2->rightClass.nGlyphs    = GET_UShort();

    FORGET_Frame();

    if ( ALLOC_ARRAY( kern2->rightClass.classes,
                      kern2->rightClass.nGlyphs,
                      UShort ) )
      goto Fail_Left;

    /* load right offsets */

    if ( ACCESS_Frame( kern2->rightClass.nGlyphs << 1 ) )
      goto Fail_Right;

    for ( n = 0; n < kern2->rightClass.nGlyphs; n++ )
      kern2->rightClass.classes[n] = GET_UShort();

    FORGET_Frame();

    /* Now load the kerning array.  We don't have its size, we */
    /* must compute it from what we know.                      */

    /* We thus compute the maximum left and right offsets and  */
    /* add them to get the array size.                         */

    left_max = right_max = 0;

    for ( n = 0; n < kern2->leftClass.nGlyphs; n++ )
      left_max = MAX( left_max, kern2->leftClass.classes[n] );

    for ( n = 0; n < kern2->rightClass.nGlyphs; n++ )
      right_max = MAX( right_max, kern2->leftClass.classes[n] );

    array_size = left_max + right_max + 2;

    if ( ALLOC( kern2->array, array_size ) )
      goto Fail_Right;

    if ( ACCESS_Frame( array_size ) )
      goto Fail_Array;

    for ( n = 0; n < array_size/2; n++ )
      kern2->array[n] = GET_Short();

    FORGET_Frame();

    /* we're good now */

    return TT_Err_Ok;

  Fail_Array:
    FREE( kern2->array );

  Fail_Right:
    FREE( kern2->rightClass.classes );
    kern2->rightClass.nGlyphs = 0;

  Fail_Left:
    FREE( kern2->leftClass.classes );
    kern2->leftClass.nGlyphs = 0;

    return error;
  }

#endif


/*******************************************************************
 *
 *  Function    :  Kerning_Create
 *
 *  Description :  Creates the kerning directory if a face is
 *                 loaded.  The tables however are loaded on
 *                 demand to save space.
 *
 *  Input  :  face    pointer to the parent face object
 *            kern    pointer to the extension's kerning field
 *
 *  Output :  error code
 *
 *  Notes  :  as in all constructors, the memory allocated isn't
 *            released in case of failure.  Rather, the task is left
 *            to the destructor (which is called if an error
 *            occurs during the loading of a face).
 *
 ******************************************************************/

  static TT_Error  Kerning_Create( TT_Kerning*  kern,
                                   PFace        face )
  {
    DEFINE_LOAD_LOCALS( face->stream );

    UShort             num_tables;
    Short              table;
    TT_Kern_Subtable*  sub;


    /* by convention */
    if ( !kern )
      return TT_Err_Ok;

    /* Now load the kerning directory. We're called from the face */
    /* constructor.  We thus need not use the stream.             */

    kern->version = 0;
    kern->nTables = 0;
    kern->tables  = NULL;

    table = TT_LookUp_Table( face, TTAG_kern );
    if ( table < 0 )
      return TT_Err_Ok;  /* The table is optional */

    if ( FILE_Seek( face->dirTables[table].Offset ) ||
         ACCESS_Frame( 4 ) )
      return error;

    kern->version = GET_UShort();
    num_tables    = GET_UShort();

    FORGET_Frame();

    /* we don't set kern->nTables until we have allocated the array */

    if ( ALLOC_ARRAY( kern->tables, num_tables, TT_Kern_Subtable ) )
      return error;

    kern->nTables = num_tables;

    /* now load the directory entries, but do _not_ load the tables ! */

    sub = kern->tables;

    for ( table = 0; table < num_tables; ++table )
    {
      if ( ACCESS_Frame( 6 ) )
        return error;

      sub->loaded   = FALSE;             /* redundant, but good to see */
      sub->version  = GET_UShort();
      sub->length   = GET_UShort() - 6;  /* substract header length */
      sub->format   = GET_Byte();
      sub->coverage = GET_Byte();

      FORGET_Frame();

      sub->offset = FILE_Pos();

      /* now skip to the next table */

      if ( FILE_Skip( sub->length ) )
        return error;

      ++sub;
    }

    /* that's fine, leave now */

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TT_Kerning_Directory_Done
 *
 *  Description :  Destroys all kerning information.
 *
 *  Input  :  directory   pointer to the extension's kerning field
 *
 *  Output :  error code
 *
 *  Notes  :  This function is a destructor; it must be able
 *            to destroy partially built tables.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Kerning_Directory_Done( TT_Kerning*  directory )
  {
    TT_Kern_Subtable*  sub;
    UShort             n;


    /* by convention */
    if ( !directory || directory->nTables == 0 )
      return TT_Err_Ok;

    /* scan the table directory and release loaded entries */

    sub = directory->tables;
    for ( n = 0; n < directory->nTables; ++n )
    {
      if ( sub->loaded )
      {
        switch ( sub->format )
        {
        case 0:
          GEO_FREE( sub->t.kern0.pairsBlock );
          sub->t.kern0.nPairs        = 0;
          sub->t.kern0.searchRange   = 0;
          sub->t.kern0.entrySelector = 0;
          sub->t.kern0.rangeShift    = 0;
          break;

#ifdef TT_CONFIG_OPTION_SUPPORT_KERN2
        case 2:
          FREE( sub->t.kern2.leftClass.classes );
          sub->t.kern2.leftClass.firstGlyph = 0;
          sub->t.kern2.leftClass.nGlyphs    = 0;

          FREE( sub->t.kern2.rightClass.classes );
          sub->t.kern2.rightClass.firstGlyph = 0;
          sub->t.kern2.rightClass.nGlyphs    = 0;

          FREE( sub->t.kern2.array );
          sub->t.kern2.rowWidth = 0;
          break;
#endif
        }

        sub->loaded   = FALSE;
        sub->version  = 0;
        sub->offset   = 0;
        sub->length   = 0;
        sub->coverage = 0;
        sub->format   = 0;
      }
      ++sub;
    }

    FREE( directory->tables );
    directory->nTables = 0;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TT_Load_Kerning_Directory
 *
 *  Description :  Returns a given face's kerning directory.
 *
 *  Input  :  face       handle to the face object
 *            directory  pointer to client's target directory
 *
 *  Output :  error code
 *
 *  Notes  :  The kerning table directory is loaded with the face
 *            through the extension constructor.  However, the kerning
 *            tables themselves are only loaded on demand, as they
 *            may represent a lot of data, unneeded by most uses of
 *            the engine.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Load_Kerning_Directory( TT_Face      face,
                                       TT_Kerning*  directory )
  {
    PFace        faze = HANDLE_Face( face );


    if ( !faze )
      return TT_Err_Invalid_Face_Handle;

    /* copy directory header */
    return Kerning_Create( directory, faze );
  }


/*******************************************************************
 *
 *  Function    :  TT_Load_Kerning_Table
 *
 *  Description :  Loads a kerning table intro memory.
 *
 *  Input  :  face          face handle
 *            kern_index    index in the face's kerning directory
 *
 *  Output :  error code
 *
 *  Notes  :
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Load_Kerning_Table( TT_Face      face,
                                   TT_Kerning*  directory,
                                   TT_UShort    kern_index )
  {
    TT_Error   error;
    TT_Stream  stream;
    TT_Kern_Subtable*  sub;


    PFace  faze = HANDLE_Face( face );

    if ( !faze )
      return TT_Err_Invalid_Face_Handle;

    if ( !directory )
      return TT_Err_Bad_Argument;

    if ( directory->nTables == 0 )
      return TT_Err_Table_Missing;

    if ( kern_index >= directory->nTables )
      return TT_Err_Invalid_Argument;

    sub = directory->tables + kern_index;

#ifdef TT_CONFIG_OPTION_SUPPORT_KERN2
    if ( sub->format != 0 && sub->format != 2 )
#else
    if ( sub->format != 0 )
#endif
      return TT_Err_Invalid_Kerning_Table_Format;

    if ( sub->loaded )
      return TT_Err_Ok;

    /* now access stream */
    if ( USE_Stream( faze->stream, stream ) )
      return error;

    if ( FILE_Seek( sub->offset ) )
      goto Fail;

    if ( sub->format == 0 )
      error = Subtable_Load_0( &sub->t.kern0, faze );
#ifdef TT_CONFIG_OPTION_SUPPORT_KERN2
    else if ( sub->format == 2 )
      error = Subtable_Load_2( &sub->t.kern2, faze );
#endif

    if ( !error )
      sub->loaded = TRUE;

  Fail:
    /* release stream */
    DONE_Stream( stream );

    return error;
  }


/* END */
