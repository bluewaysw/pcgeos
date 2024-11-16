/***********************************************************************
 *
 * PROJECT:       VConvert
 * FILE:          VConvert.h
 * DESCRIPTION:   Vector file converter common definitions
 *
 * AUTHOR:        Marcus Groeber
 *
 ***********************************************************************/

#include <meta.h>
#include "vconv_ui.h"

#define NULL_HANDLE 0

#define VIEW_MARGIN 18          /* margin around image in view (in pt) */
#define RULER_WIDTH 20          /* thickness of rulers on screen */

#define CLIPBOARD_NAME "Image converted by V-Convert"

#define GRAPH_FORMAT FormatIDFromManufacturerAndType(MANUFACTURER_ID_GEOWORKS,\
                                                     CIF_GRAPHICS_STRING)

optr Create_GrBody(VMFileHandle vmf);
int Finish_GrBody(
  optr body,VMFileHandle vmf,VMBlockHandle *gsh,VMBlockHandle *grobjh,
  RectDWord *bounds);

void ExportGString(GStateHandle gs);

/*
 * "Wrappers" to pass parameters for MSG_GB_CREATE_*_TRANSFER_FORMAT
 */
VMBlockHandle _far _pascal
  My_GB_CreateGStringTransferFormat(optr body,VMFileHandle vmf,PointDWFixed *o);
VMBlockHandle _far _pascal
  My_GB_CreateGrObjTransferFormat(optr body,VMFileHandle vmf,PointDWFixed *o);

