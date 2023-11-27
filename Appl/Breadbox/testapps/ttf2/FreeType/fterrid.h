/*******************************************************************
 *
 *  fterrid.h
 *
 *    TrueType Error ID definitions
 *
 *  Copyright 1996-1999 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg.
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT.  By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 ******************************************************************/

#ifndef FREETYPE_H
#error "Don't include this file! Use freetype.h instead."
#endif

#ifndef FTERRID_H
#define FTERRID_H

  /************************ error codes declaration **************/

  /* The error codes are grouped in 'classes' used to indicate the */
  /* 'level' at which the error happened.                          */
  /* The class is given by an error code's high byte.              */


  /* ------------- Success is always 0 -------- */

#define TT_Err_Ok                       0


  /* -------- High-level API error codes ------ */

#define TT_Err_Invalid_Face_Handle      0x001
#define TT_Err_Invalid_Instance_Handle  0x002
#define TT_Err_Invalid_Glyph_Handle     0x003
#define TT_Err_Invalid_CharMap_Handle   0x004
#define TT_Err_Invalid_Result_Address   0x005
#define TT_Err_Invalid_Glyph_Index      0x006
#define TT_Err_Invalid_Argument         0x007
#define TT_Err_Could_Not_Open_File      0x008
#define TT_Err_File_Is_Not_Collection   0x009

#define TT_Err_Table_Missing            0x00A
#define TT_Err_Invalid_Horiz_Metrics    0x00B
#define TT_Err_Invalid_CharMap_Format   0x00C
#define TT_Err_Invalid_PPem             0x00D
#define TT_Err_Invalid_Vert_Metrics     0x00E

#define TT_Err_Invalid_File_Format      0x010

#define TT_Err_Invalid_Engine           0x020
#define TT_Err_Too_Many_Extensions      0x021
#define TT_Err_Extensions_Unsupported   0x022
#define TT_Err_Invalid_Extension_Id     0x023

#define TT_Err_No_Vertical_Data         0x030

#define TT_Err_Max_Profile_Missing      0x080
#define TT_Err_Header_Table_Missing     0x081
#define TT_Err_Horiz_Header_Missing     0x082
#define TT_Err_Locations_Missing        0x083
#define TT_Err_Name_Table_Missing       0x084
#define TT_Err_CMap_Table_Missing       0x085
#define TT_Err_Hmtx_Table_Missing       0x086
#define TT_Err_OS2_Table_Missing        0x087
#define TT_Err_Post_Table_Missing       0x088
#define TT_Err_Glyf_Table_Missing       0x089


  /* -------- Memory component error codes ---- */

  /* this error indicates that an operation cannot */
  /* be performed due to memory exhaustion.        */

#define TT_Err_Out_Of_Memory            0x100


  /* -------- File component error codes ------ */

  /* these error codes indicate that the file could */
  /* not be accessed properly.  Usually, this means */
  /* a broken font file!                            */

#define TT_Err_Invalid_File_Offset      0x200
#define TT_Err_Invalid_File_Read        0x201
#define TT_Err_Invalid_Frame_Access     0x202


  /* -------- Glyph loader error codes -------- */

  /* Produced only by the glyph loader, these error */
  /* codes indicate a broken glyph in a font file.  */

#define TT_Err_Too_Many_Points          0x300
#define TT_Err_Too_Many_Contours        0x301
#define TT_Err_Invalid_Composite        0x302
#define TT_Err_Too_Many_Ins             0x303


  /* --- bytecode interpreter error codes ----- */

  /* These error codes are produced by the TrueType */
  /* bytecode interpreter.  They usually indicate a */
  /* broken font file, a broken glyph within a font */
  /* file, or a bug in the interpreter!             */

#define TT_Err_Invalid_Opcode           0x400
#define TT_Err_Too_Few_Arguments        0x401
#define TT_Err_Stack_Overflow           0x402
#define TT_Err_Code_Overflow            0x403
#define TT_Err_Bad_Argument             0x404
#define TT_Err_Divide_By_Zero           0x405
#define TT_Err_Storage_Overflow         0x406
#define TT_Err_Cvt_Overflow             0x407
#define TT_Err_Invalid_Reference        0x408
#define TT_Err_Invalid_Distance         0x409
#define TT_Err_Interpolate_Twilight     0x40A
#define TT_Err_Debug_OpCode             0x40B
#define TT_Err_ENDF_In_Exec_Stream      0x40C
#define TT_Err_Out_Of_CodeRanges        0x40D
#define TT_Err_Nested_DEFS              0x40E
#define TT_Err_Invalid_CodeRange        0x40F
#define TT_Err_Invalid_Displacement     0x410
#define TT_Err_Execution_Too_Long       0x411


  /* ------ internal failure error codes ----- */

  /* These error codes are produced when an incoherent */
  /* library state has been detected.  These reflect a */
  /* severe bug in the engine! (Or a major overwrite   */
  /* of your application into the library's data.)     */

#define TT_Err_Nested_Frame_Access      0x500
#define TT_Err_Invalid_Cache_List       0x501
#define TT_Err_Could_Not_Find_Context   0x502
#define TT_Err_Unlisted_Object          0x503


  /* ---- scan-line converter error codes ----- */

  /* These error codes are produced by the raster component.  */
  /* They indicate that an outline structure was incoherently */
  /* setup, or that you're trying to render an horribly       */
  /* complex glyph!                                           */

#define TT_Err_Raster_Pool_Overflow     0x600
#define TT_Err_Raster_Negative_Height   0x601
#define TT_Err_Raster_Invalid_Value     0x602
#define TT_Err_Raster_Not_Initialized   0x603

#endif /* FTERRID_H */


/* END */
