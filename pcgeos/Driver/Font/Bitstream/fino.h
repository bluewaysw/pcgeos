/***********************************************************************
 *
 *	Copyright (c) Geoworks 1993 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	fino.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: fino.h,v 1.1 97/04/18 11:45:11 newdeal Exp $
 *
 ***********************************************************************/

/*  Use this file to add structures or typedefs that everyone needs. */
/*  This header is included in every module. */





#if   WINDOWS_4IN1
   typedef  struct
   {
      void (WDECL *sp_report_error)(PROTO_DECL2 n);
      void (WDECL *sp_open_bitmap)(PROTO_DECL2 fix31 x_set_width, fix31 y_set_width, fix31 xorg, fix31 yorg, fix15 xsize, fix15 ysize);
      void (WDECL *sp_set_bitmap_bits)(PROTO_DECL2 fix15 y, fix15 xbit1, fix15 xbit2);
      void (WDECL *sp_close_bitmap)(PROTO_DECL1);
      buff_t FONTFAR* (WDECL *sp_load_char_data)(PROTO_DECL2 fix31 file_offset, fix15 no_bytes, fix15 cb_offset);
      boolean  (WDECL *get_byte)(char STACKFAR*next_char);
      unsigned char  STACKFAR* (WDECL *dynamic_load)(ufix32 file_position, fix15 num_bytes, unsigned char success);
   }callback_struct;
extern   callback_struct   callback_ptrs;
/* structure that holds pointers to all callback functions. */
#endif
