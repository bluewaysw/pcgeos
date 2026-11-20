/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * OpenSpellGEOS lexical reader for PC/GEOS Ensemble and host verification.
 * The caller owns the context and performs all I/O. No heap allocation, libc
 * dependency, machine-endian structures, or 386 instructions are required.
 * See TechDocs/Markdown/OpenSpellGEOSFormat.md for the version 1 disk format.
 */
#ifndef OPENLEX_H
#define OPENLEX_H

#ifdef __WATCOMC__
#define OL_CALL _pascal
#else
#define OL_CALL
#endif

#define OL_DICTIONARY 1
#define OL_THESAURUS 2
#define OL_HYPHENATION 3
#define OL_KEY_MAX 64
#define OL_VALUE_MAX 4096
#define OL_BLOCK_SIZE 1024
#define OL_INDEX_SIZE 65
#define OL_INDEX_PAGE 1024
#define OL_TOP_COUNT 7
#define OL_INLINE_MAX 96
#define OL_FOLD_CASE 1
#define OL_EXACT_CASE 2
#define OL_SUGGEST_MAX 8
#define OL_SUGGEST_PROBES 48

/* Read exactly count bytes at absolute offset; return one, or zero on error. */
typedef int (OL_CALL *OLRead)(void *userP, unsigned long offset,
                            unsigned short count, unsigned char *bufferP);

/* A fixed binary-search node cache; never an index-sized allocation. */
typedef struct {
    unsigned long blockNumber;
    unsigned char valid;
    unsigned char record[OL_INDEX_SIZE];
} OLIndexNode;

/* Allocate outside the stack. One context is used serially by one caller. */
typedef struct {
    OLRead read;
    void *userP;
    unsigned long fileSize;
    unsigned long indexCount;
    unsigned long dataOffset;
    unsigned long blobOffset;
    unsigned long cachedBlock;
    unsigned long indexPageOffset;
    unsigned short indexPageLength;
    unsigned short used;
    unsigned short recordCount;
    unsigned char kind;
    unsigned char valid;
    unsigned char lastKeyLength;
    unsigned char block[OL_BLOCK_SIZE];
    unsigned char index[OL_INDEX_SIZE];
    unsigned char key[OL_KEY_MAX + 1];
    unsigned char previous[OL_KEY_MAX + 1];
    unsigned char distance[3][OL_KEY_MAX + 1];
    unsigned char indexPage[OL_INDEX_PAGE];
    OLIndexNode top[OL_TOP_COUNT];
} OLContext;

/* Keep this bounded even if compiler alignment or pointer defaults change. */
typedef char OLContextSizeCheck[(sizeof(OLContext) <= 3328) ? 1 : -1];

/* Only the spelling adapter allocates this workspace; IH/ET do not need it. */
typedef struct {
    unsigned char words[OL_SUGGEST_MAX][OL_KEY_MAX + 1];
    unsigned char lengths[OL_SUGGEST_MAX];
    unsigned char scores[OL_SUGGEST_MAX];
    unsigned char count;
    unsigned char folded[OL_KEY_MAX + 1];
    unsigned char mutation[OL_KEY_MAX + 1];
    unsigned char probe[OL_KEY_MAX + 1];
    unsigned short probes;
} OLSuggestWorkspace;

typedef char OLSuggestSizeCheck[(sizeof(OLSuggestWorkspace) <= 768) ? 1 : -1];

/* Initialize a context and validate the header. Return one or -1 on error. */
int OL_CALL olOpen(OLContext *contextP, OLRead read, void *userP,
                   unsigned char expectedKind);

/* Exact byte lookup: 1 found, 0 missing, -1 malformed/I/O, -2 buffer too small.
 * lengthP is set to the full value length on found and buffer-too-small.
 * keyP and valueP must not alias context storage. No terminator is appended. */
int OL_CALL olFind(OLContext *contextP, const unsigned char *keyP,
                   unsigned short keyLength, unsigned char *valueP,
                   unsigned short capacity, unsigned short *lengthP);

/* Rank up to eight canonical dictionary words across typed/folded searches.
 * Scan up to eight nearby leaves, plus 48 exact lookup probes; distance one
 * outranks distance two; only the best available distance tier is returned.
 * The caller owns a separate, serially used workspace.
 * lengthP includes each output NUL. Return one or -1 on malformed data/I/O.
 * ATTENTION: bounded search is not exhaustive. The adapter applies display
 * case only after checking each candidate's dictionary case flag. */
int OL_CALL olSuggest(OLContext *contextP, const unsigned char *wordP,
                      unsigned short wordLength, unsigned char *outputP,
                      unsigned short capacity, unsigned short *lengthP,
                      OLSuggestWorkspace *workspaceP);

/* Lowercase one SBCS GEOS character without locale or Unicode expansion. */
unsigned char OL_CALL olLower(unsigned char character);

/* Uppercase one SBCS GEOS character using the inverse one-byte case map. */
unsigned char OL_CALL olUpper(unsigned char character);

#endif
