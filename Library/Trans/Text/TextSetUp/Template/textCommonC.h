/*********************************************************************/
/*                                                                   */
/* Copyright (c) GeoWorks 1992 -- All Rights Reserved                */
/*                                                                   */
/* PROJECT:        PC GEOS                                           */
/* MODULE:	   Template Translation Library		             */
/* FILE:           textCommonC.h                                     */
/*                                                                   */
/* AUTHOR:         Jenny Greenwood, 7 October 1992                   */
/*                                                                   */
/* REVISION HISTORY:                                                 */
/*      Name    Date            Description                          */
/*      ----    ----            -----------                          */
/*      jenny   10/7/92         Initial version                      */
/*                                                                   */
/* DESCRIPTION:                                                      */
/*      Constant definitions to allow compilation of this library    */
/*      to include only those files from                             */
/*              /s/p/Library/Translation/Text/TextCommonC            */
/*      which the library actually uses.                             */
/*                                                                   */
/*      $Id: textCommonC.h,v 1.1 97/04/07 11:40:35 newdeal Exp $
/*                                                                   */
/*********************************************************************/

/* Constants representing TextCommonC files which are probably used
   by every MasterSoft-code-based text translation library; all
   ten of the current such libraries use them. 7 October 1992 */

#define __BIORTNS
#define __BIOTEMP
#define __ERREXIT
#define __EXCEPT
#define __COMDOS
#define __COMMONF
#define __COMMONT
#define __COMPUB
#define __ICFCODES

/* Constants representing TextCommonC files which are used by this
   MasterSoft-code-based text translation library, but not
   by every one of the others. */

#define __BLDCOLS
#define __COMFCTX
#define __COMFNTB
#define __COMFSNL
#define __COMFXCS
#define __COMMONFX
#define __COMMONTX
#define __COMTDTF
#define __COMTLLEN
#define __COMTNTB
#define __COMTSTM
#define __COMTTAB
#define __COMTWID
#define __COMTXCS
#define __COMXCS
#define __DSPRTNS
#define __GENFNAM
#define __HEXTRAN
#define __INTCVT
#define __PCREV
#define __PTRNUM
#define __PUTNEXT
#define __STCCPY
#define __STCD_I
#define __STCH_I
#define __STCI_D
#define __STCL_D
#define __STPCHR
#define __STRSTRI
#define __THROWAWY
#define __TRANS
