/*******************************************************************
 *
 *  tttags.h
 *
 *    tags for TrueType tables (specification only).
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
 ******************************************************************/

#ifndef TTAGS_H
#define TTAGS_H

#include "ttconfig.h"
#include "freetype.h"   /* for MAKE_TT_TAG() */

#define TTAG_BASE  MAKE_TT_TAG( 'B', 'A', 'S', 'E' )
#define TTAG_bloc  MAKE_TT_TAG( 'b', 'l', 'o', 'c' )
#define TTAG_bdat  MAKE_TT_TAG( 'b', 'd', 'a', 't' )
#define TTAG_cmap  MAKE_TT_TAG( 'c', 'm', 'a', 'p' )
#define TTAG_cvt   MAKE_TT_TAG( 'c', 'v', 't', ' ' )
#define TTAG_EBDT  MAKE_TT_TAG( 'E', 'B', 'D', 'T' )
#define TTAG_EBLC  MAKE_TT_TAG( 'E', 'B', 'L', 'C' )
#define TTAG_EBSC  MAKE_TT_TAG( 'E', 'B', 'S', 'C' )
#define TTAG_fpgm  MAKE_TT_TAG( 'f', 'p', 'g', 'm' )
#define TTAG_gasp  MAKE_TT_TAG( 'g', 'a', 's', 'p' )
#define TTAG_glyf  MAKE_TT_TAG( 'g', 'l', 'y', 'f' )
#define TTAG_GDEF  MAKE_TT_TAG( 'G', 'D', 'E', 'F' )
#define TTAG_GPOS  MAKE_TT_TAG( 'G', 'P', 'O', 'S' )
#define TTAG_GSUB  MAKE_TT_TAG( 'G', 'S', 'U', 'B' )
#define TTAG_hdmx  MAKE_TT_TAG( 'h', 'd', 'm', 'x' )
#define TTAG_head  MAKE_TT_TAG( 'h', 'e', 'a', 'd' )
#define TTAG_hhea  MAKE_TT_TAG( 'h', 'h', 'e', 'a' )
#define TTAG_hmtx  MAKE_TT_TAG( 'h', 'm', 't', 'x' )
#define TTAG_JSTF  MAKE_TT_TAG( 'J', 'S', 'T', 'F' )
#define TTAG_kern  MAKE_TT_TAG( 'k', 'e', 'r', 'n' )
#define TTAG_loca  MAKE_TT_TAG( 'l', 'o', 'c', 'a' )
#define TTAG_LTSH  MAKE_TT_TAG( 'L', 'T', 'S', 'H' )
#define TTAG_maxp  MAKE_TT_TAG( 'm', 'a', 'x', 'p' )
#define TTAG_name  MAKE_TT_TAG( 'n', 'a', 'm', 'e' )
#define TTAG_OS2   MAKE_TT_TAG( 'O', 'S', '/', '2' )
#define TTAG_PCLT  MAKE_TT_TAG( 'P', 'C', 'L', 'T' )
#define TTAG_post  MAKE_TT_TAG( 'p', 'o', 's', 't' )
#define TTAG_prep  MAKE_TT_TAG( 'p', 'r', 'e', 'p' )
#define TTAG_ttc   MAKE_TT_TAG( 't', 't', 'c', ' ' )
#define TTAG_ttcf  MAKE_TT_TAG( 't', 't', 'c', 'f' )
#define TTAG_VDMX  MAKE_TT_TAG( 'V', 'D', 'M', 'X' )
#define TTAG_vhea  MAKE_TT_TAG( 'v', 'h', 'e', 'a' )
#define TTAG_vmtx  MAKE_TT_TAG( 'v', 'm', 't', 'x' )

#endif /* TTAGS_H */


/* END */
