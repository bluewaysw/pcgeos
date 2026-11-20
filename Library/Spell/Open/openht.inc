/*
 * OpenSpellGEOS - legacy hyphenation and thesaurus entry points.
 * SPDX-License-Identifier: Apache-2.0
 *
 * These adapters preserve the public Spell library and its existing assembly
 * UI. No proprietary dictionary data, algorithm, or implementation is used.
 * All language data is read through the bounded, seekable OpenLex reader.
 * The original IH/ET control blocks keep one GEOS memory handle; no movable
 * pointer survives MemUnlock. See TechDocs/Markdown/OpenSpellGEOS.md for formats,
 * build instructions and compatibility limits.
 *
 * This file is included by spellopen.c. IH and ET have different historical
 * calling conventions, so keep their entry point declarations explicit.
 */

#include "geosbridge.h"

#define OHT_WORD_LIMIT 64
#define OHT_VALUE_LIMIT 4096
#define OHT_OUTPUT_LIMIT 1600
#define OHT_SENSE_LIMIT 26
#define OHT_LABEL_LIMIT 180
#define OHT_SYNONYM_LIMIT 80
#define OHT_SYNONYM_LENGTH 26

/* The assembly definitions are byte-packed, including their far pointers. */
#pragma pack(1)
typedef struct {
    word task;
    word retcode;
    unsigned long hypmap[2];
    unsigned long alternateMap[2];
    unsigned long hardHyphenMap[2];
    unsigned long capitalMap[2];
    char filename[129];
    char alternateSpelling[65];
    unsigned char language;
    unsigned char capitalCode;
    unsigned char mandatoryFlag;
    unsigned char errorFlags;
    unsigned char processFlags;
    unsigned char initializeFlags;
    MemHandle contextH;
    void *unusedContextP;
    unsigned char unusedDiskBuffer[512];
} OpenIHBuffer;

typedef struct {
    word ramSectors;
    char *filenameP;
    word unusedFileHandle;
    void *lookupP;
    MemHandle contextH;
    MemHandle unusedTableH;
    void *unusedDictionaryP;
    void *unusedTableP;
} OpenETControl;
#pragma pack()

#ifdef __WATCOMC__
/* A changed memory model or packing option must fail at compile time. */
typedef char OpenIHSizeCheck[(sizeof(OpenIHBuffer) == 754) ? 1 : -1];
typedef char OpenETSizeCheck[(sizeof(OpenETControl) == 24) ? 1 : -1];
#endif

typedef struct {
    OpenGeoFile file;
    unsigned char value[OHT_VALUE_LIMIT];
    unsigned char key[OHT_WORD_LIMIT + 1];
} OpenETState;

/* Include the reader caches while keeping each allocation within 8 KB. */
typedef char OpenETStateSizeCheck[(sizeof(OpenETState) <= 8192) ? 1 : -1];

#pragma code_seg("IHCODE")

/*
 * Open or close the exact-word hyphenation database, or return legal breaks.
 * The Pascal declaration follows the existing assembly push order: word,
 * control block. Return zero on success and the historical IHFAILURE (8) on
 * invalid input, unavailable data, allocation failure, or corrupt records.
 * Missing words succeed with an empty map; guessing syllables is unsafe.
 * ATTENTION: breaks cover only the generated vocabulary. Extend the host
 * vocabulary/pattern inputs for more coverage without increasing runtime RAM.
 */
int _pascal _export
IHhyp(const unsigned char *wordP, OpenIHBuffer *bufferP)
{
    OpenGeoFile *fileP;
    MemHandle contextH;
    unsigned char key[OHT_WORD_LIMIT + 1];
    unsigned char positions[OHT_WORD_LIMIT];
    unsigned short length;
    unsigned short positionCount;
    unsigned short index;
    unsigned short position;
    unsigned short previousPosition;
    int result;

    bufferP->retcode = 8;
    bufferP->hypmap[0] = 0;
    bufferP->hypmap[1] = 0;
    if (bufferP->task == 0) {
        if (bufferP->contextH != 0) {
            return 8;
        }
        /* Shared library state must survive the calling application's exit. */
        contextH = MemAllocSetOwner(GeodeGetCodeProcessHandle(),
            sizeof(OpenGeoFile), HF_SWAPABLE | HF_SHARABLE, HAF_ZERO_INIT);
        if (contextH == 0) {
            return 8;
        }
        fileP = MemLock(contextH);
        /* All services follow the selected dictionary's language stem. */
        result = OpenGeoOpen(fileP, OL_HYPHENATION, (void *)0);
        MemUnlock(contextH);
        if (result != 1) {
            MemFree(contextH);
            return 8;
        }
        bufferP->contextH = contextH;
        bufferP->retcode = 0;
        return 0;
    }
    if (bufferP->task == 2) {
        if (bufferP->contextH != 0) {
            fileP = MemLock(bufferP->contextH);
            OpenGeoClose(fileP);
            MemFree(bufferP->contextH);
            bufferP->contextH = 0;
        }
        bufferP->retcode = 0;
        return 0;
    }
    if (bufferP->task != 1 || bufferP->contextH == 0) {
        return 8;
    }
    length = OpenGeoLength(wordP, OHT_WORD_LIMIT + 1);
    if (length == 0 || length > OHT_WORD_LIMIT) {
        return 8;
    }
    for (index = 0; index < length; ++index) {
        key[index] = wordP[index];
    }
    OpenGeoFold(key, length);
    fileP = MemLock(bufferP->contextH);
    /* A movable block may have a new segment after the previous unlock. */
    fileP->lex.userP = fileP;
    result = olFind(&fileP->lex, key, length, positions,
                    sizeof(positions), &positionCount);
    MemUnlock(bufferP->contextH);
    if (result < 0) {
        return 8;
    }
    if (result == 1) {
        previousPosition = 0;
        /* Validate the complete record before exposing any output bits. */
        for (index = 0; index < positionCount; ++index) {
            position = positions[index];
            if (position <= previousPosition || position >= length) {
                return 8;
            }
            previousPosition = position;
        }
        for (index = 0; index < positionCount; ++index) {
            position = positions[index] - 1;
            /* The legacy map is MSB first in each little-endian dword. */
            bufferP->hypmap[position / 32] |=
                1UL << (31 - (position % 32));
        }
    }
    bufferP->retcode = 0;
    return 0;
}

#pragma code_seg("STDLIB")

/*
 * Retain the historical conversion ABI while preserving GEOS SBCS bytes.
 * New files use GEOS characters directly, so conversion to proprietary DEC
 * encoding is neither required nor appropriate. The only caller owns a
 * 66-byte destination and passes the source length including its terminator.
 */
int _pascal _export
SLcnv(const unsigned char *sourceP, word length, unsigned char *destinationP,
      word direction)
{
    word index;

    (void)direction;
    if (length == 0 || length > OHT_WORD_LIMIT + 2) {
        destinationP[0] = 0;
        return 8;
    }
    for (index = 0; index + 1 < length; ++index) {
        destinationP[index] = sourceP[index];
    }
    destinationP[length - 1] = 0;
    return 0;
}

#pragma code_seg("ETCODE")

/*
 * Validate every thesaurus field and both legacy output capacities in one
 * bounded pass. The old parsers use punctuation delimiters without lengths;
 * this boundary therefore rejects delimiter-bearing synonyms and controls.
 * All sums remain below 8192, including on a compiler with 16-bit unsigned.
 */
int _pascal
OpenETValidate(const unsigned char *valueP, unsigned short valueLength)
{
    unsigned short offset;
    unsigned short senseCount;
    unsigned short sense;
    unsigned short labelLength;
    unsigned short synonymCount;
    unsigned short synonym;
    unsigned short textLength;
    unsigned short character;
    unsigned short meaningsLength;
    unsigned short synonymsLength;
    unsigned char byte;

    if (valueLength == 0) {
        return 0;
    }
    senseCount = valueP[0];
    if (senseCount == 0 || senseCount > OHT_SENSE_LIMIT) {
        return 0;
    }
    offset = 1;
    meaningsLength = 2;
    for (sense = 0; sense < senseCount; ++sense) {
        if (offset + 2 > valueLength ||
            (valueP[offset] > 3 && valueP[offset] != 255)) {
            return 0;
        }
        labelLength = valueP[offset + 1];
        offset += 2;
        if (labelLength == 0 || labelLength > OHT_LABEL_LIMIT ||
            offset + labelLength >= valueLength) {
            return 0;
        }
        for (character = 0; character < labelLength; ++character) {
            if (valueP[offset + character] < 32) {
                return 0;
            }
        }
        meaningsLength += labelLength + 8;
        if (meaningsLength > OHT_OUTPUT_LIMIT) {
            return 0;
        }
        offset += labelLength;
        synonymCount = valueP[offset++];
        if (synonymCount == 0 || synonymCount > OHT_SYNONYM_LIMIT) {
            return 0;
        }
        synonymsLength = 1;
        for (synonym = 0; synonym < synonymCount; ++synonym) {
            if (offset >= valueLength) {
                return 0;
            }
            textLength = valueP[offset++];
            if (textLength == 0 || textLength > OHT_SYNONYM_LENGTH ||
                offset + textLength > valueLength) {
                return 0;
            }
            for (character = 0; character < textLength; ++character) {
                byte = valueP[offset + character];
                if (byte < 32 || byte == ',' || byte == '.') {
                    return 0;
                }
            }
            if (valueP[offset] == ' ' ||
                valueP[offset + textLength - 1] == ' ') {
                return 0;
            }
            synonymsLength += textLength + 1;
            if (synonymsLength > OHT_OUTPUT_LIMIT) {
                return 0;
            }
            offset += textLength;
        }
    }
    return offset == valueLength;
}

/*
 * Supply the THS basename to the original availability and open wrappers.
 * Their 26-byte buffer exceeds the bridge's 13-byte DOS 8.3 requirement.
 * Empty output on invalid configuration makes FileOpen fail safely; no old
 * thesaurus preference can silently select data from a different language.
 */
void _pascal _export
OpenThesaurusFilename(char *filenameP)
{
    if (OpenGeoName(filenameP, "THS") != 1) {
        filenameP[0] = 0;
    }
}

/*
 * Allocate one movable state block and open its THS file. The obsolete
 * kilobyte preload argument is accepted but ignored: the paged reader avoids
 * the old mandatory 20 KB resident dictionary. Return 1, -1 for allocation
 * failure, or -2 for an unavailable/invalid database, as the ET ABI requires.
 */
int _cdecl _export
et_load(word preloadKilobytes, OpenETControl *controlP)
{
    OpenETState *stateP;
    MemHandle contextH;
    int result;

    (void)preloadKilobytes;
    if (controlP->contextH != 0) {
        return -2;
    }
    /* The global ET control block is shared by clients of spell.geo. */
    contextH = MemAllocSetOwner(GeodeGetCodeProcessHandle(),
        sizeof(OpenETState), HF_SWAPABLE | HF_SHARABLE, HAF_ZERO_INIT);
    if (contextH == 0) {
        return -1;
    }
    stateP = MemLock(contextH);
    result = OpenGeoOpen(&stateP->file, OL_THESAURUS, (void *)0);
    MemUnlock(contextH);
    if (result != 1) {
        MemFree(contextH);
        return -2;
    }
    controlP->contextH = contextH;
    return 1;
}

/*
 * Release only the new state and its file. The assembly owner allocates the
 * EtCtrl, filename and legacy Lookup in a separate block and frees it itself.
 * Closing a zero handle succeeds, making partial-open cleanup safe.
 */
int _cdecl _export
et_close(OpenETControl *controlP)
{
    OpenETState *stateP;

    if (controlP->contextH != 0) {
        stateP = MemLock(controlP->contextH);
        OpenGeoClose(&stateP->file);
        MemFree(controlP->contextH);
        controlP->contextH = 0;
    }
    return 1;
}

/*
 * Look up meanings (option zero) or synonyms for a one-based sense number.
 * All pointers use the historical far cdecl ABI; the caller removes 18 bytes
 * of arguments. Text is rendered only after complete structural validation.
 * Return a count, zero for an absent word/sense, or a negative ET error.
 * ATTENTION: the retained UI limits each synonym to 26 GEOS characters.
 * A future longer-word UI must change both this bound and its chunk parser.
 */
int _cdecl _export
et(const unsigned char *wordP, word option, unsigned char *outputP,
   word *partsOfSpeechP, OpenETControl *controlP)
{
    OpenETState *stateP;
    unsigned short keyLength;
    unsigned short valueLength;
    unsigned short offset;
    unsigned short outputOffset;
    unsigned short senseCount;
    unsigned short sense;
    unsigned short partOfSpeech;
    unsigned short labelLength;
    unsigned short synonymCount;
    unsigned short synonym;
    unsigned short textLength;
    unsigned short index;
    unsigned char byte;
    int result;
    int count;

    outputP[0] = '.';
    outputP[1] = 0;
    if (controlP->contextH == 0) {
        return -2;
    }
    keyLength = OpenGeoLength(wordP, OHT_WORD_LIMIT + 1);
    if (keyLength == 0 || keyLength > OHT_WORD_LIMIT) {
        return 0;
    }
    stateP = MemLock(controlP->contextH);
    for (index = 0; index < keyLength; ++index) {
        stateP->key[index] = wordP[index];
    }
    OpenGeoFold(stateP->key, keyLength);
    /* Refresh the reader callback pointer after locking movable storage. */
    stateP->file.lex.userP = &stateP->file;
    result = olFind(&stateP->file.lex, stateP->key, keyLength, stateP->value,
                    sizeof(stateP->value), &valueLength);
    if (result != 1) {
        MemUnlock(controlP->contextH);
        return result == 0 ? 0 : -3;
    }
    if (!OpenETValidate(stateP->value, valueLength)) {
        MemUnlock(controlP->contextH);
        return -3;
    }
    senseCount = stateP->value[0];
    if (option > senseCount) {
        MemUnlock(controlP->contextH);
        return 0;
    }
    offset = 1;
    outputOffset = 0;
    count = 0;
    for (sense = 1; sense <= senseCount; ++sense) {
        partOfSpeech = stateP->value[offset++];
        labelLength = stateP->value[offset++];
        if (option == 0) {
            /* Disk 255 is unknown; the UI's fifth entry preserves that fact. */
            partsOfSpeechP[sense - 1] = partOfSpeech == 255 ? 4 : partOfSpeech;
            /* ASCII capital S makes every old parser boundary unambiguous. */
            outputP[outputOffset++] = 'S';
            outputP[outputOffset++] = 'e';
            outputP[outputOffset++] = 'n';
            outputP[outputOffset++] = 's';
            outputP[outputOffset++] = 'e';
            outputP[outputOffset++] = ':';
            outputP[outputOffset++] = ' ';
            for (index = 0; index < labelLength; ++index) {
                byte = stateP->value[offset + index];
                outputP[outputOffset++] = byte == '.' ? ';' : byte;
            }
            outputP[outputOffset++] = '.';
            ++count;
        }
        offset += labelLength;
        synonymCount = stateP->value[offset++];
        for (synonym = 0; synonym < synonymCount; ++synonym) {
            textLength = stateP->value[offset++];
            if (option == sense) {
                for (index = 0; index < textLength; ++index) {
                    outputP[outputOffset++] = stateP->value[offset + index];
                }
                outputP[outputOffset++] =
                    synonym + 1 == synonymCount ? '.' : ',';
                ++count;
            }
            offset += textLength;
        }
    }
    if (option == 0) {
        outputP[outputOffset++] = '.';
    }
    outputP[outputOffset] = 0;
    MemUnlock(controlP->contextH);
    return count;
}
