/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	stylesh.h
 * AUTHOR:	Tony Requist: February 1, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines style sheet structures
 *
 *	$Id: stylesh.h,v 1.1 97/04/04 15:58:52 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__STYLESH_H
#define __STYLESH_H

#include "chunkarr.h"

typedef struct {
    RefElementHeader	SSEH_meta;
    word		SSEH_style;
} StyleSheetElementHeader;

typedef WordFlags StyleElementFlags;
#define SEF_DISPLAY_IN_TOOLBOX	0x8000

typedef struct {
    NameArrayElement	SEH_meta;
    word		SEH_baseStyle;
    StyleElementFlags	SEH_flags;
    byte		SEH_reserved[6];
    dword		SEH_privateData;
} StyleElementHeader;


typedef struct {
    VMFileHandle	SCD_vmFile;
    word		SCD_vmBlockOrMemHandle;
    ChunkHandle		SCD_chunk;
} StyleChunkDesc;

#define MAX_STYLE_SHEET_ATTRS		4

typedef struct {
    void		*SSP_descriptionCallbacks[MAX_STYLE_SHEET_ATTRS];
    void		*SSP_specialDescriptionCallback;
    void		*SSP_mergeCallbacks[MAX_STYLE_SHEET_ATTRS];
    void		*SSP_substitutionCallbacks[MAX_STYLE_SHEET_ATTRS];
    StyleChunkDesc	SSP_styleArray;
    StyleChunkDesc	SSP_attrArrays[MAX_STYLE_SHEET_ATTRS];
    word		SSP_attrTokens[MAX_STYLE_SHEET_ATTRS];
    StyleChunkDesc	SSP_xferStyleArray;
    StyleChunkDesc	SSP_xferAttrArrays[MAX_STYLE_SHEET_ATTRS];
} StyleSheetParams;

#endif
