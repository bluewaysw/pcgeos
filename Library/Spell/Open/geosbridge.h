/*
 * SPDX-License-Identifier: Apache-2.0
 * geosbridge.h - OpenSpellGEOS file adapter for the OpenLex formats.
 *
 * OpenGeoFile must remain locked while a core call is running: the callback
 * stores its address. Rebind lex.userP after every MemLock of a movable block.
 * The stored read callback lives in the fixed OpenReadCode resource.
 * File names are DOS 8.3 basenames below SP_USER_DATA/DICTS, never paths.
 */
#ifndef OPEN_GEOSBRIDGE_H
#define OPEN_GEOSBRIDGE_H
#include <geos.h>
#include <file.h>
#include <heap.h>
#include <geode.h>
#include "openlex.h"

typedef struct {
    FileHandle fileH;
    OLContext lex;
} OpenGeoFile;

/* Keep standalone hyphenation/file contexts within the same block budget. */
typedef char OpenGeoFileSizeCheck[(sizeof(OpenGeoFile) <= 8192) ? 1 : -1];

/* Open a selected DCT/THS/HYP, validating the header before returning 1. */
int _pascal OpenGeoOpen(OpenGeoFile *fileP, unsigned char kind,
                       const char *filenameP);
/* Close an initialized adapter, including after an unsuccessful open. */
void _pascal OpenGeoClose(OpenGeoFile *fileP);
/* Copy the selected dictionary basename and substitute a three-byte suffix. */
int _pascal OpenGeoName(char *nameP, const char *extensionP);
/* Return bounded string length; capacity means there was no terminator. */
word _pascal OpenGeoLength(const unsigned char *textP, word capacity);
/* Fold GEOS SBCS bytes using exactly the same table as the host builder. */
void _pascal OpenGeoFold(unsigned char *textP, word length);
#endif
