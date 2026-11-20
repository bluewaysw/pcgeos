/*
 * SPDX-License-Identifier: Apache-2.0
 * geosbridge.inc - OpenSpellGEOS file services for the OpenLex reader.
 *
 * This module has no mutable global state. Each caller owns its reader and
 * file handle. All reads are positional, bounded, checked for short reads,
 * and restricted to the opened file. Paths come only from USERDATA/DICTS.
 */
#include "geosbridge.h"
#include <initfile.h>
#include <geode.h>

#pragma code_seg("CODE")

/* Return capacity rather than reading past an unterminated input buffer. */
word _pascal OpenGeoLength(const unsigned char *textP, word capacity)
{
    word length;
    for (length = 0; length < capacity && textP[length]; ++length) {
    }
    return length;
}

/* Keep dictionary generation and all three linguistic consumers in sync. */
void _pascal OpenGeoFold(unsigned char *textP, word length)
{
    word index;
    for (index = 0; index < length; ++index) {
        textP[index] = olLower(textP[index]);
    }
}

/* Reject separators, drive prefixes, wildcards, and non-8.3 names. */
int _pascal OpenGeoValidName(const char *nameP)
{
    word index;
    word dot;
    unsigned char letter;
    dot = 0;
    for (index = 0; index < 13 && nameP[index]; ++index) {
        letter = (unsigned char)nameP[index];
        if (letter == '.') {
            if (!index || index > 8 || dot) {
                return 0;
            }
            dot = index;
        } else if (!((letter >= 'A' && letter <= 'Z') ||
                     (letter >= 'a' && letter <= 'z') ||
                     (letter >= '0' && letter <= '9') || letter == '_')) {
            return 0;
        }
    }
    return index < 13 && dot && index == dot + 4;
}

/* Read the existing Preferences key, preserving selection for all services. */
int _pascal OpenGeoName(char *nameP, const char *extensionP)
{
    word size;
    word index;
    static const char defaultName[] = "EN_US.DCT";
    if (InitFileReadStringBuffer("text", "dictionary", nameP, 13, &size)) {
        for (index = 0; index < sizeof(defaultName); ++index) {
            nameP[index] = defaultName[index];
        }
    }
    nameP[12] = 0;
    if (!OpenGeoValidName(nameP)) {
        return -1;
    }
    for (index = 0; nameP[index] != '.'; ++index) {
    }
    nameP[++index] = extensionP[0];
    nameP[++index] = extensionP[1];
    nameP[++index] = extensionP[2];
    return 1;
}

/* The core stores this address and calls it as an ordinary far pointer.
 * Movable GEOS code addresses require ProcCallFixedOrMovable; putting this
 * tiny callback in the dedicated OpenReadCode resource keeps the portable reader
 * platform-independent and its saved function pointer valid across swaps.
 */
#pragma code_seg("OpenReadCode")

/* Supply an exact bounded read; the portable decoder validates offsets. */
int OL_CALL OpenGeoRead(void *userP, unsigned long offset,
                              unsigned short count, unsigned char *bufferP)
{
    OpenGeoFile *fileP;
    fileP = (OpenGeoFile *)userP;
    if (FilePos(fileP->fileH, offset, FILE_POS_START) != offset) {
        return 0;
    }
    return FileRead(fileP->fileH, bufferP, count, FALSE) == count;
}

#pragma code_seg("CODE")

/* Open only in DICTS, restoring the caller's thread-local current directory. */
int _pascal OpenGeoOpen(OpenGeoFile *fileP, unsigned char kind,
                       const char *filenameP)
{
    char name[13];
    const char *extensionP;
    word index;
    int result;
    fileP->fileH = 0;
    extensionP = kind == 1 ? "DCT" : (kind == 2 ? "THS" : "HYP");
    if (kind < 1 || kind > 3) {
        return -1;
    }
    if (filenameP == (void *)0) {
        if (OpenGeoName(name, extensionP) != 1) {
            return -1;
        }
    } else {
        if (!OpenGeoValidName(filenameP)) {
            return -1;
        }
        for (index = 0; index < 13; ++index) {
            name[index] = filenameP[index];
            if (!name[index]) {
                break;
            }
        }
    }
    FilePushDir();
    if (FileSetCurrentPath(SP_USER_DATA, "DICTS")) {
        fileP->fileH = FileOpen(name, FILE_ACCESS_R | FILE_DENY_W);
    }
    FilePopDir();
    if (!fileP->fileH) {
        return -1;
    }
    /* Library ownership outlives a client process and its temporary thread. */
    HandleModifyOwner(fileP->fileH, GeodeGetCodeProcessHandle());
    result = olOpen(&fileP->lex, OpenGeoRead, fileP, kind);
    if (result != 1 || fileP->lex.fileSize != FileSize(fileP->fileH)) {
        OpenGeoClose(fileP);
        return -1;
    }
    return 1;
}

/* Closing zero is deliberately harmless on failed initialization paths. */
void _pascal OpenGeoClose(OpenGeoFile *fileP)
{
    if (fileP->fileH) {
        FileClose(fileP->fileH, FALSE);
        fileP->fileH = 0;
    }
}
