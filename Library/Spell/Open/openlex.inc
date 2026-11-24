/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * OpenSpellGEOS bounded-memory lexical lookup for PC/GEOS Ensemble.
 * All disk integers are decoded explicitly. A validated 1 KiB leaf, one 1 KiB
 * index page and seven top-level index records are cached per context. The same C89 source is tested
 * on the host and compiled for the 16-bit target. The caller serializes use
 * and supplies a movable-memory-safe context and exact-read callback.
 * Helper functions use external object linkage for the supplied Watcom/glue
 * LPUBDEF compatibility; they are not additional exported GEOS APIs.
 */
#include "openlex.h"

/* Decode an unaligned little-endian word without depending on host layout. */
unsigned short OL_CALL olWord(const unsigned char *dataP)
{
    return (unsigned short)(dataP[0] | ((unsigned short)dataP[1] << 8));
}

/* Decode an unaligned little-endian double word, including on a 16-bit CPU. */
unsigned long OL_CALL olLong(const unsigned char *dataP)
{
    return (unsigned long)olWord(dataP) |
           ((unsigned long)olWord(dataP + 2) << 16);
}

/* Compare explicit-length GEOS strings in unsigned byte order. */
int OL_CALL olCompare(const unsigned char *leftP,
                             unsigned short leftLength,
                             const unsigned char *rightP,
                             unsigned short rightLength)
{
    unsigned short index;
    unsigned short count;

    count = leftLength < rightLength ? leftLength : rightLength;
    for (index = 0; index < count; ++index) {
        if (leftP[index] != rightP[index]) {
            return leftP[index] < rightP[index] ? -1 : 1;
        }
    }
    return leftLength < rightLength ? -1 : leftLength != rightLength;
}

/* Reject out-of-file ranges before handing an exact read to the platform. */
int OL_CALL olReadRange(OLContext *contextP, unsigned long offset,
                               unsigned short count, unsigned char *bufferP)
{
    if (offset > contextP->fileSize ||
        (unsigned long)count > contextP->fileSize - offset) {
        return 0;
    }
    return contextP->read(contextP->userP, offset, count, bufferP) == 1;
}

/* Validate nonempty keys and reject NUL/control bytes in disk and API keys. */
int OL_CALL olKeyValid(const unsigned char *keyP,
                              unsigned short length)
{
    unsigned short index;

    if (length == 0 || length > OL_KEY_MAX) {
        return 0;
    }
    for (index = 0; index < length; ++index) {
        if (keyP[index] < 32 || keyP[index] == 127) {
            return 0;
        }
    }
    return 1;
}

/* Fetch a sparse-index record through a bounded 1 KiB page cache. Records
 * can cross page boundaries; copy each part before replacing the cached page.
 * Only index bytes are read, so the final short page never consumes leaf data. */
int OL_CALL olIndexBytes(OLContext *contextP, unsigned long blockNumber)
{
    unsigned long offset;
    unsigned long pageOffset;
    unsigned long available;
    unsigned short copied;
    unsigned short withinPage;
    unsigned short amount;
    unsigned short index;

    offset = 64UL + blockNumber * OL_INDEX_SIZE;
    copied = 0;
    while (copied < OL_INDEX_SIZE) {
        pageOffset = (offset / OL_INDEX_PAGE) * OL_INDEX_PAGE;
        if (contextP->indexPageLength == 0 ||
            contextP->indexPageOffset != pageOffset) {
            contextP->indexPageLength = 0;
            available = contextP->dataOffset - pageOffset;
            amount = available < OL_INDEX_PAGE ? (unsigned short)available :
                                                OL_INDEX_PAGE;
            if (!olReadRange(contextP, pageOffset, amount,
                             contextP->indexPage)) {
                return 0;
            }
            contextP->indexPageOffset = pageOffset;
            contextP->indexPageLength = amount;
        }
        withinPage = (unsigned short)(offset - pageOffset);
        if (withinPage >= contextP->indexPageLength) {
            return 0;
        }
        amount = contextP->indexPageLength - withinPage;
        if (amount > OL_INDEX_SIZE - copied) {
            amount = OL_INDEX_SIZE - copied;
        }
        for (index = 0; index < amount; ++index) {
            contextP->index[copied + index] =
                contextP->indexPage[withinPage + index];
        }
        copied += amount;
        offset += amount;
    }
    return 1;
}

/* Read and validate a sparse-index record. The first three binary-search
 * levels have seven permanent slots, avoiding their recurring mechanical disk
 * seeks. Lower levels share one page cache. Both caches are lazy and fixed in
 * size; changing the file requires olOpen, which invalidates every slot. */
int OL_CALL olIndex(OLContext *contextP, unsigned long blockNumber,
                           unsigned short cacheSlot)
{
    unsigned short index;
    OLIndexNode *nodeP;

    if (blockNumber >= contextP->indexCount) {
        return 0;
    }
    nodeP = cacheSlot < OL_TOP_COUNT ? contextP->top + cacheSlot : (void *)0;
    if (nodeP != (void *)0 && nodeP->valid &&
        nodeP->blockNumber == blockNumber) {
        for (index = 0; index < OL_INDEX_SIZE; ++index) {
            contextP->index[index] = nodeP->record[index];
        }
        return 1;
    }
    if (!olIndexBytes(contextP, blockNumber) ||
        !olKeyValid(contextP->index + 1, contextP->index[0])) {
        return 0;
    }
    for (index = contextP->index[0] + 1; index < OL_INDEX_SIZE; ++index) {
        if (contextP->index[index] != 0) {
            return 0;
        }
    }
    if (nodeP != (void *)0) {
        nodeP->blockNumber = blockNumber;
        for (index = 0; index < OL_INDEX_SIZE; ++index) {
            nodeP->record[index] = contextP->index[index];
        }
        nodeP->valid = 1;
    }
    return 1;
}

/* Find the leaf with the greatest first key not greater than the query.
 * The half-open binary search avoids signed arithmetic and midpoint overflow. */
int OL_CALL olLocate(OLContext *contextP, const unsigned char *keyP,
                            unsigned short length, unsigned long *blockP)
{
    unsigned long low;
    unsigned long high;
    unsigned long middle;
    unsigned short cacheSlot;

    cacheSlot = 0;
    low = 0;
    high = contextP->indexCount;
    while (low < high) {
        middle = low + (high - low) / 2;
        if (!olIndex(contextP, middle, cacheSlot)) {
            return 0;
        }
        if (olCompare(contextP->index + 1, contextP->index[0], keyP,
                      length) <= 0) {
            low = middle + 1;
            if (cacheSlot < OL_TOP_COUNT) {
                cacheSlot = cacheSlot * 2 + 2;
            }
        } else {
            high = middle;
            if (cacheSlot < OL_TOP_COUNT) {
                cacheSlot = cacheSlot * 2 + 1;
            }
        }
    }
    *blockP = low == 0 ? 0 : low - 1;
    return 1;
}

/* Reconstruct one front-coded key and identify its inline value or pointer.
 * A large value uses four bytes in the leaf, not its entire payload length. */
int OL_CALL olRecord(OLContext *contextP, unsigned short *positionP,
                            unsigned short *keyLengthP,
                            unsigned short *valueLengthP,
                            unsigned short *valuePositionP)
{
    unsigned short position;
    unsigned short prefix;
    unsigned short suffix;
    unsigned short storedLength;
    unsigned short index;

    position = *positionP;
    if (position > contextP->used || contextP->used - position < 4) {
        return 0;
    }
    prefix = contextP->block[position];
    suffix = contextP->block[position + 1];
    *valueLengthP = olWord(contextP->block + position + 2);
    position += 4;
    if (prefix > *keyLengthP || suffix == 0 ||
        prefix + suffix > OL_KEY_MAX || *valueLengthP > OL_VALUE_MAX) {
        return 0;
    }
    storedLength = *valueLengthP <= OL_INLINE_MAX ? *valueLengthP : 4;
    if (contextP->used - position < suffix + storedLength) {
        return 0;
    }
    for (index = 0; index < suffix; ++index) {
        contextP->key[prefix + index] = contextP->block[position + index];
    }
    *keyLengthP = prefix + suffix;
    contextP->key[*keyLengthP] = 0;
    *valuePositionP = position + suffix;
    *positionP = position + suffix + storedLength;
    return olKeyValid(contextP->key, *keyLengthP);
}

/* Read and validate an entire leaf before caching it. Validation includes
 * sorted keys, exact bounds, kind-specific compact values and blob ranges. */
int OL_CALL olLoad(OLContext *contextP, unsigned long blockNumber)
{
    unsigned short position;
    unsigned short keyLength;
    unsigned short previousLength;
    unsigned short valueLength;
    unsigned short valuePosition;
    unsigned short record;
    unsigned short index;
    unsigned long valueOffset;

    if (contextP->cachedBlock == blockNumber) {
        return 1;
    }
    contextP->cachedBlock = 0xffffffffUL;
    if (!olIndex(contextP, blockNumber, OL_TOP_COUNT) ||
        !olReadRange(contextP,
                     contextP->dataOffset + blockNumber * OL_BLOCK_SIZE,
                     OL_BLOCK_SIZE, contextP->block)) {
        return 0;
    }
    contextP->used = olWord(contextP->block);
    contextP->recordCount = olWord(contextP->block + 2);
    if (contextP->used < 9 || contextP->used > OL_BLOCK_SIZE ||
        contextP->recordCount == 0 || contextP->recordCount > 204) {
        return 0;
    }
    position = 4;
    keyLength = 0;
    previousLength = 0;
    for (record = 0; record < contextP->recordCount; ++record) {
        if (!olRecord(contextP, &position, &keyLength, &valueLength,
                      &valuePosition)) {
            return 0;
        }
        if (record == 0) {
            if (olCompare(contextP->key, keyLength, contextP->index + 1,
                          contextP->index[0]) != 0) {
                return 0;
            }
        } else if (olCompare(contextP->previous, previousLength,
                             contextP->key, keyLength) >= 0) {
            return 0;
        }
        for (index = 0; index < keyLength; ++index) {
            contextP->previous[index] = contextP->key[index];
        }
        previousLength = keyLength;
        if (valueLength > OL_INLINE_MAX) {
            valueOffset = olLong(contextP->block + valuePosition);
            if (valueOffset < contextP->blobOffset ||
                valueOffset > contextP->fileSize ||
                valueLength > contextP->fileSize - valueOffset) {
                return 0;
            }
        }
        if (contextP->kind == OL_DICTIONARY &&
            (valueLength != 1 ||
             (contextP->block[valuePosition] != OL_FOLD_CASE &&
              contextP->block[valuePosition] != OL_EXACT_CASE))) {
            return 0;
        }
        if (contextP->kind == OL_HYPHENATION) {
            if (valueLength >= keyLength) {
                return 0;
            }
            for (index = 0; index < valueLength; ++index) {
                if (contextP->block[valuePosition + index] == 0 ||
                    contextP->block[valuePosition + index] >= keyLength ||
                    (index != 0 && contextP->block[valuePosition + index] <=
                     contextP->block[valuePosition + index - 1])) {
                    return 0;
                }
            }
        }
    }
    if (position != contextP->used) {
        return 0;
    }
    for (index = contextP->used; index < OL_BLOCK_SIZE; ++index) {
        if (contextP->block[index] != 0) {
            return 0;
        }
    }
    contextP->lastKeyLength = (unsigned char)previousLength;
    contextP->cachedBlock = blockNumber;
    return 1;
}

/* Initialize from the explicit 64-byte v1 header. Maximum offsets are kept
 * below 2 GiB to match the target FilePos signed-offset interface. */
int OL_CALL olOpen(OLContext *contextP, OLRead read, void *userP,
                   unsigned char expectedKind)
{
    unsigned short index;
    unsigned long entries;

    contextP->valid = 0;
    contextP->cachedBlock = 0xffffffffUL;
    contextP->indexPageOffset = 0xffffffffUL;
    contextP->indexPageLength = 0;
    for (index = 0; index < OL_TOP_COUNT; ++index) {
        contextP->top[index].valid = 0;
    }
    contextP->read = read;
    contextP->userP = userP;
    if (expectedKind < OL_DICTIONARY || expectedKind > OL_HYPHENATION ||
        read(userP, 0, 64, contextP->block) != 1) {
        return -1;
    }
    if (contextP->block[0] != 'O' || contextP->block[1] != 'L' ||
        contextP->block[2] != 'X' || contextP->block[3] != '1' ||
        contextP->block[4] != expectedKind || contextP->block[5] != 1 ||
        contextP->block[6] != OL_KEY_MAX || contextP->block[7] != 0 ||
        olWord(contextP->block + 8) != 64 ||
        olWord(contextP->block + 10) != OL_BLOCK_SIZE ||
        olLong(contextP->block + 20) != 64) {
        return -1;
    }
    for (index = 44; index < 64; ++index) {
        if (contextP->block[index] != 0) {
            return -1;
        }
    }
    contextP->kind = expectedKind;
    entries = olLong(contextP->block + 12);
    contextP->indexCount = olLong(contextP->block + 16);
    contextP->dataOffset = olLong(contextP->block + 24);
    contextP->blobOffset = olLong(contextP->block + 28);
    contextP->fileSize = olLong(contextP->block + 32);
    if (contextP->indexCount > (0x7fffffffUL - 64) /
                               (OL_INDEX_SIZE + OL_BLOCK_SIZE) ||
        contextP->dataOffset != 64 + contextP->indexCount * OL_INDEX_SIZE ||
        contextP->blobOffset != contextP->dataOffset +
                                contextP->indexCount * OL_BLOCK_SIZE ||
        contextP->fileSize < contextP->blobOffset ||
        contextP->fileSize > 0x7fffffffUL ||
        entries < contextP->indexCount ||
        entries > contextP->indexCount * 204UL ||
        (contextP->indexCount == 0 && contextP->fileSize != 64)) {
        return -1;
    }
    if (contextP->fileSize > 64 &&
        !olReadRange(contextP, contextP->fileSize - 1, 1, contextP->key)) {
        return -1;
    }
    contextP->valid = 1;
    return 1;
}

/* Perform one exact lookup and copy the value only after checking capacity. */
int OL_CALL olFind(OLContext *contextP, const unsigned char *keyP,
                   unsigned short keyLength, unsigned char *valueP,
                   unsigned short capacity, unsigned short *lengthP)
{
    unsigned long blockNumber;
    unsigned short position;
    unsigned short decodedLength;
    unsigned short valueLength;
    unsigned short valuePosition;
    unsigned short record;
    unsigned short index;
    int comparison;

    *lengthP = 0;
    if (!contextP->valid || !olKeyValid(keyP, keyLength)) {
        return -1;
    }
    if (contextP->indexCount == 0) {
        return 0;
    }
    /* Nearby mutation probes commonly stay inside the current leaf. Its
     * first and last keys were validated by olLoad; this closed range can
     * answer both hits and misses without seeking through the index again. */
    if (contextP->cachedBlock == 0xffffffffUL ||
        olCompare(contextP->block + 8, contextP->block[5], keyP, keyLength) > 0 ||
        olCompare(contextP->previous, contextP->lastKeyLength, keyP, keyLength) < 0) {
        if (!olLocate(contextP, keyP, keyLength, &blockNumber) ||
            !olLoad(contextP, blockNumber)) {
            return -1;
        }
    }
    position = 4;
    decodedLength = 0;
    for (record = 0; record < contextP->recordCount; ++record) {
        if (!olRecord(contextP, &position, &decodedLength, &valueLength,
                      &valuePosition)) {
            return -1;
        }
        comparison = olCompare(contextP->key, decodedLength, keyP, keyLength);
        if (comparison > 0) {
            return 0;
        }
        if (comparison == 0) {
            *lengthP = valueLength;
            if (valueLength > capacity) {
                return -2;
            }
            if (valueLength > OL_INLINE_MAX) {
                if (!olReadRange(contextP,
                                 olLong(contextP->block + valuePosition),
                                 valueLength, valueP)) {
                    return -1;
                }
            } else {
                for (index = 0; index < valueLength; ++index) {
                    valueP[index] = contextP->block[valuePosition + index];
                }
            }
            return 1;
        }
    }
    return 0;
}

/* Immutable GEOS case tables shared by both directions. These contain no
 * per-caller state; one copy keeps the target fixed-data footprint small. */
static const unsigned char olCapitals[] = {
    0x80,0x81,0x82,0x83,0x84,0x85,0x86,0xae,0xaf,0xcb,0xcc,0xcd,
    0xce,0xd9,0xdf,0xe5,0xe6,0xe7,0xe8,0xe9,0xea,0xeb,0xec,0xed,
    0xee,0xef,0xf1,0xf2,0xf3,0xf4
};

static const unsigned char olLowercase[] = {
    0x8a,0x8c,0x8d,0x8e,0x96,0x9a,0x9f,0xbe,0xbf,0x88,0x8b,0x9b,
    0xcf,0xd8,0xde,0x89,0x90,0x87,0x91,0x8f,0x92,0x94,0x95,0x93,
    0x97,0x99,0x98,0x9c,0x9e,0x9d
};

/* Fold ASCII and the one-byte uppercase letters of the GEOS SBCS charset.
 * The paired arrays contain only uppercase letters representable in GEOS;
 * sharp s is not expanded to two letters, preserving byte/character offsets. */
unsigned char OL_CALL olLower(unsigned char character)
{
    unsigned short index;

    if (character >= 'A' && character <= 'Z') {
        return (unsigned char)(character + ('a' - 'A'));
    }
    if (character < 0x80) {
        return character;
    }
    for (index = 0; index < sizeof(olCapitals); ++index) {
        if (character == olCapitals[index]) {
            return olLowercase[index];
        }
    }
    return character;
}

/* Uppercase only characters with a one-byte GEOS lowercase counterpart.
 * In particular, sharp s is not expanded, preserving word and buffer lengths. */
unsigned char OL_CALL olUpper(unsigned char character)
{
    unsigned short index;

    if (character >= 'a' && character <= 'z') {
        return (unsigned char)(character - ('a' - 'A'));
    }
    if (character < 0x80) {
        return character;
    }
    for (index = 0; index < sizeof(olLowercase); ++index) {
        if (character == olLowercase[index]) {
            return olCapitals[index];
        }
    }
    return character;
}

#ifdef __WATCOMC__
/* Keep correction code out of the reader resource used by IH and ET. */
#pragma code_seg("OpenSuggestCode")
#endif

/* Compute a bounded optimal-string-alignment distance using three byte rows.
 * Adjacent transpositions count once; the two-edit band bounds CPU work to
 * approximately five cells per character. Values are saturated at three. */
unsigned short OL_CALL olDistance(OLContext *contextP,
                                         const unsigned char *wordP,
                                         unsigned short wordLength,
                                         unsigned short candidateLength)
{
    unsigned short row;
    unsigned short column;
    unsigned short first;
    unsigned short last;
    unsigned short current;
    unsigned short previous;
    unsigned short before;
    unsigned short cost;
    unsigned short best;
    unsigned short value;

    if (wordLength > candidateLength + 2 ||
        candidateLength > wordLength + 2) {
        return 3;
    }
    for (column = 0; column <= candidateLength; ++column) {
        contextP->distance[0][column] = column > 2 ? 3 :
                                                   (unsigned char)column;
        contextP->distance[1][column] = 3;
        contextP->distance[2][column] = 3;
    }
    for (row = 1; row <= wordLength; ++row) {
        current = row % 3;
        previous = (row - 1) % 3;
        before = (row + 1) % 3;
        contextP->distance[current][0] = row > 2 ? 3 : (unsigned char)row;
        first = row > 2 ? row - 2 : 1;
        last = row + 2 < candidateLength ? row + 2 : candidateLength;
        /* Only band-adjacent cells can be read by the next row. Clearing
         * those boundaries avoids a quadratic whole-row reset. */
        if (first > 1) {
            contextP->distance[current][first - 1] = 3;
        }
        if (last < candidateLength) {
            contextP->distance[current][last + 1] = 3;
        }
        for (column = first; column <= last; ++column) {
            cost = olLower(wordP[row - 1]) ==
                   olLower(contextP->key[column - 1]) ? 0 : 1;
            best = contextP->distance[previous][column - 1] + cost;
            value = contextP->distance[previous][column] + 1;
            if (value < best) {
                best = value;
            }
            value = contextP->distance[current][column - 1] + 1;
            if (value < best) {
                best = value;
            }
            if (row > 1 && column > 1 &&
                olLower(wordP[row - 1]) ==
                olLower(contextP->key[column - 2]) &&
                olLower(wordP[row - 2]) ==
                olLower(contextP->key[column - 1])) {
                value = contextP->distance[before][column - 2] + 1;
                if (value < best) {
                    best = value;
                }
            }
            contextP->distance[current][column] = best > 3 ? 3 :
                                                          (unsigned char)best;
        }
    }
    return contextP->distance[wordLength % 3][candidateLength];
}

/* Copy a bounded candidate including its terminator without libc or a stack
 * buffer. Every caller supplies a validated length no greater than 64. */
void OL_CALL olSuggestCopy(unsigned char *targetP,
                           const unsigned char *sourceP, unsigned short length)
{
    unsigned short index;

    for (index = 0; index < length; ++index) {
        targetP[index] = sourceP[index];
    }
    targetP[length] = 0;
}

/* Compare folded candidates for deduplication without expanding characters. */
int OL_CALL olSameFold(const unsigned char *leftP, unsigned short leftLength,
                       const unsigned char *rightP, unsigned short rightLength)
{
    unsigned short index;

    if (leftLength != rightLength) {
        return 0;
    }
    for (index = 0; index < leftLength; ++index) {
        if (olLower(leftP[index]) != olLower(rightP[index])) {
            return 0;
        }
    }
    return 1;
}

/* Insert a decoded dictionary candidate into the best-eight list. Distance
 * always wins over the small mutation tie-break; raw lexical order settles
 * remaining ties deterministically. Scanning never stops merely because the
 * list is full, so a later one-edit correction can replace an earlier near miss. */
void OL_CALL olSuggestOffer(OLContext *contextP, OLSuggestWorkspace *workspaceP,
                            const unsigned char *wordP, unsigned short wordLength,
                            unsigned short keyLength, unsigned short hint,
                            unsigned short capacity)
{
    unsigned short distance;
    unsigned short score;
    unsigned short index;
    unsigned short position;
    unsigned short move;

    if (keyLength + 1 > capacity ||
        olCompare(contextP->key, keyLength, wordP, wordLength) == 0) {
        return;
    }
    distance = olDistance(contextP, wordP, wordLength, keyLength);
    if (distance > 2) {
        return;
    }
    score = distance * 8 + hint;
    for (index = 0; index < workspaceP->count; ++index) {
        if (olSameFold(contextP->key, keyLength, workspaceP->words[index],
                       workspaceP->lengths[index])) {
            if (score >= workspaceP->scores[index]) {
                return;
            }
            /* Remove a weaker duplicate before inserting its better score. */
            --workspaceP->count;
            for (move = index; move < workspaceP->count; ++move) {
                olSuggestCopy(workspaceP->words[move], workspaceP->words[move + 1],
                               workspaceP->lengths[move + 1]);
                workspaceP->lengths[move] = workspaceP->lengths[move + 1];
                workspaceP->scores[move] = workspaceP->scores[move + 1];
            }
            break;
        }
    }
    position = 0;
    while (position < workspaceP->count &&
           (workspaceP->scores[position] < score ||
            (workspaceP->scores[position] == score &&
             olCompare(workspaceP->words[position], workspaceP->lengths[position],
                       contextP->key, keyLength) < 0))) {
        ++position;
    }
    if (position == OL_SUGGEST_MAX) {
        return;
    }
    if (workspaceP->count < OL_SUGGEST_MAX) {
        ++workspaceP->count;
    }
    for (move = workspaceP->count - 1; move > position; --move) {
        olSuggestCopy(workspaceP->words[move], workspaceP->words[move - 1],
                       workspaceP->lengths[move - 1]);
        workspaceP->lengths[move] = workspaceP->lengths[move - 1];
        workspaceP->scores[move] = workspaceP->scores[move - 1];
    }
    olSuggestCopy(workspaceP->words[position], contextP->key, keyLength);
    workspaceP->lengths[position] = (unsigned char)keyLength;
    workspaceP->scores[position] = (unsigned char)score;
}

/* Examine four leaves around one lexical region while sharing the ranked list
 * across typed and folded searches. Prefix extensions such as hous -> house
 * receive a useful one-edit tie-break without claiming corpus frequencies. */
int OL_CALL olSuggestWindow(OLContext *contextP, OLSuggestWorkspace *workspaceP,
                            const unsigned char *queryP,
                            const unsigned char *wordP, unsigned short wordLength,
                            unsigned short capacity)
{
    unsigned long blockNumber;
    unsigned long endBlock;
    unsigned short position;
    unsigned short keyLength;
    unsigned short valueLength;
    unsigned short valuePosition;
    unsigned short record;
    unsigned short hint;

    if (!olLocate(contextP, queryP, wordLength, &blockNumber)) {
        return 0;
    }
    blockNumber = blockNumber == 0 ? 0 : blockNumber - 1;
    endBlock = blockNumber + 4;
    if (endBlock > contextP->indexCount) {
        endBlock = contextP->indexCount;
    }
    while (blockNumber < endBlock) {
        if (!olLoad(contextP, blockNumber)) {
            return 0;
        }
        position = 4;
        keyLength = 0;
        for (record = 0; record < contextP->recordCount; ++record) {
            if (!olRecord(contextP, &position, &keyLength, &valueLength,
                          &valuePosition)) {
                return 0;
            }
            hint = keyLength == wordLength + 1 &&
                   olSameFold(contextP->key, wordLength, wordP, wordLength) ? 1 : 5;
            olSuggestOffer(contextP, workspaceP, wordP, wordLength,
                            keyLength, hint, capacity);
        }
        ++blockNumber;
    }
    return 1;
}

/* Try one exact key under the global I/O work budget. A hit leaves its canonical
 * key in contextP->key; only actual dictionary records can enter suggestions. */
int OL_CALL olSuggestTry(OLContext *contextP, OLSuggestWorkspace *workspaceP,
                         const unsigned char *candidateP, unsigned short length,
                         const unsigned char *wordP, unsigned short wordLength,
                         unsigned short hint, unsigned short capacity)
{
    unsigned char flag;
    unsigned short valueLength;
    int result;

    if (workspaceP->probes == OL_SUGGEST_PROBES) {
        return 0;
    }
    ++workspaceP->probes;
    result = olFind(contextP, candidateP, length, &flag, 1, &valueLength);
    if (result == 1) {
        olSuggestOffer(contextP, workspaceP, wordP, wordLength, length, hint, capacity);
    }
    return result;
}

/* Probe one case form in a grouped pass: lowercase, typed, then titlecase.
 * Grouping avoids bouncing between distant uppercase/lowercase leaves for
 * every miss. Duplicate case forms cost no I/O; only dictionary hits qualify. */
int OL_CALL olSuggestProbe(OLContext *contextP, OLSuggestWorkspace *workspaceP,
                           unsigned short length, const unsigned char *wordP,
                           unsigned short wordLength, unsigned short hint,
                           unsigned short capacity, unsigned short casePass)
{
    unsigned short index;

    for (index = 0; index < length; ++index) {
        workspaceP->probe[index] = olLower(workspaceP->mutation[index]);
    }
    workspaceP->probe[length] = 0;
    if (casePass == 1) {
        if (olCompare(workspaceP->mutation, length, workspaceP->probe, length) == 0) {
            return 1;
        }
        olSuggestCopy(workspaceP->probe, workspaceP->mutation, length);
    } else if (casePass == 2) {
        if (olUpper(workspaceP->probe[0]) == workspaceP->probe[0]) {
            return 1;
        }
        workspaceP->probe[0] = olUpper(workspaceP->probe[0]);
        if (olCompare(workspaceP->mutation, length, workspaceP->probe, length) == 0) {
            return 1;
        }
    }
    return olSuggestTry(contextP, workspaceP, workspaceP->probe, length,
                         wordP, wordLength, hint, capacity) >= 0;
}

/* Immutable accent bytes shared by equivalence checks and probe generation;
 * storing one copy avoids duplicate fixed data in the 16-bit library. */
static const unsigned char olAccents[] = {
    0x8a,0x8c,0x87,0x88,0x89,0x8b,0x8d,0x8e,0x8f,0x90,0x91,
    0x92,0x93,0x94,0x95,0x96,0x9a,0x97,0x98,0x99,0x9b,
    0x9f,0x9c,0x9d,0x9e,0xd8,0xde
};

/* Return the basic Latin letter for the supported one-byte accent variants.
 * The equivalence is used to propose corrections, never to accept spelling. */
unsigned char OL_CALL olAccentBase(unsigned char character)
{
    static const unsigned char bases[] = "aaaaaaceeeeiiiinooooouuuuyy";
    unsigned short index;

    character = olLower(character);
    for (index = 0; index < sizeof(olAccents); ++index) {
        if (character == olAccents[index]) {
            return bases[index];
        }
    }
    return character;
}

/* Generate a small set of common one-edit mistakes, bounded by exact probes.
 * Deletions, transpositions and doubled-letter insertions cover typing errors;
 * accent substitutions bridge distant GEOS lexical regions such as a and ae
 * with dieresis. No generated string is returned without a dictionary hit. */
int OL_CALL olSuggestMutations(OLContext *contextP, OLSuggestWorkspace *workspaceP,
                               const unsigned char *wordP,
                               unsigned short wordLength, unsigned short capacity,
                               unsigned short casePass)
{
    unsigned short position;
    unsigned short index;
    unsigned short variant;
    unsigned short hint;
    unsigned char letter;
    unsigned char replacement;

    for (position = 0; position < wordLength &&
                       workspaceP->probes < OL_SUGGEST_PROBES; ++position) {
        if (wordLength > 1 && (position == 0 ||
            olLower(wordP[position]) != olLower(wordP[position - 1]))) {
            for (index = 0; index < wordLength - 1; ++index) {
                workspaceP->mutation[index] = wordP[index < position ? index : index + 1];
            }
            workspaceP->mutation[wordLength - 1] = 0;
            letter = olAccentBase(wordP[position]);
            /* An extra doubled letter or interior vowel is a useful generic
             * typo tie-break, not a claim about the word's corpus frequency. */
            hint = position + 1 < wordLength &&
                   olLower(wordP[position]) == olLower(wordP[position + 1]) ? 1 :
                   (position > 0 && position + 1 < wordLength &&
                    (letter == 'a' || letter == 'e' || letter == 'i' ||
                     letter == 'o' || letter == 'u')) ? 2 : 3;
            if (!olSuggestProbe(contextP, workspaceP, wordLength - 1,
                                 wordP, wordLength, hint, capacity, casePass)) {
                return 0;
            }
        }
        if (position + 1 < wordLength &&
            olLower(wordP[position]) != olLower(wordP[position + 1])) {
            olSuggestCopy(workspaceP->mutation, wordP, wordLength);
            workspaceP->mutation[position] = wordP[position + 1];
            workspaceP->mutation[position + 1] = wordP[position];
            if (!olSuggestProbe(contextP, workspaceP, wordLength,
                                 wordP, wordLength, 4, capacity, casePass)) {
                return 0;
            }
        }
        if (wordLength < OL_KEY_MAX && (position == 0 ||
            olLower(wordP[position]) != olLower(wordP[position - 1]))) {
            for (index = 0; index <= wordLength; ++index) {
                workspaceP->mutation[index] = wordP[index <= position ? index : index - 1];
            }
            workspaceP->mutation[wordLength + 1] = 0;
            if (!olSuggestProbe(contextP, workspaceP, wordLength + 1,
                                 wordP, wordLength, 1, capacity, casePass)) {
                return 0;
            }
        }
        letter = olLower(wordP[position]);
        for (variant = 0; variant <= sizeof(olAccents) &&
                          workspaceP->probes < OL_SUGGEST_PROBES; ++variant) {
            replacement = variant < sizeof(olAccents) ? olAccents[variant] : olAccentBase(letter);
            if (replacement != letter && olAccentBase(replacement) == olAccentBase(letter)) {
                olSuggestCopy(workspaceP->mutation, wordP, wordLength);
                workspaceP->mutation[position] = wordP[position] != letter ?
                                                olUpper(replacement) : replacement;
                if (!olSuggestProbe(contextP, workspaceP, wordLength,
                                     wordP, wordLength, 0, capacity, casePass)) {
                    return 0;
                }
            }
        }
    }
    return 1;
}

/* Return a jointly ranked, bounded correction list in canonical dictionary
 * spelling. Typed-case results cannot fill the list before lowercase results
 * are considered. ATTENTION: eight window leaves plus 48 exact probes are the
 * hard ceilings; probes may load additional leaves. Search is not exhaustive;
 * a compact correction index would be needed for exhaustive one-edit recall. */
int OL_CALL olSuggest(OLContext *contextP, const unsigned char *wordP,
                      unsigned short wordLength, unsigned char *outputP,
                      unsigned short capacity, unsigned short *lengthP,
                      OLSuggestWorkspace *workspaceP)
{
    unsigned short index;
    unsigned short length;

    *lengthP = 0;
    workspaceP->count = 0;
    workspaceP->probes = 0;
    if (!contextP->valid || contextP->kind != OL_DICTIONARY ||
        !olKeyValid(wordP, wordLength)) {
        return -1;
    }
    if (contextP->indexCount == 0 || capacity == 0) {
        return 1;
    }
    for (index = 0; index < wordLength; ++index) {
        workspaceP->folded[index] = olLower(wordP[index]);
    }
    workspaceP->folded[wordLength] = 0;
    if (!olSuggestWindow(contextP, workspaceP, wordP, wordP, wordLength, capacity)) {
        return -1;
    }
    if (olCompare(wordP, wordLength, workspaceP->folded, wordLength) != 0 &&
        !olSuggestWindow(contextP, workspaceP, workspaceP->folded,
                          wordP, wordLength, capacity)) {
        return -1;
    }
    for (index = 0; index < 3 && workspaceP->probes < OL_SUGGEST_PROBES; ++index) {
        if (!olSuggestMutations(contextP, workspaceP, wordP, wordLength, capacity, index)) {
            return -1;
        }
    }
    for (index = 0; index < workspaceP->count; ++index) {
        /* Once a closer correction exists, do not fill the UI with a worse
         * distance tier. Keep equally close alternatives for ambiguous typos. */
        if (workspaceP->scores[index] / 8 != workspaceP->scores[0] / 8) {
            break;
        }
        length = workspaceP->lengths[index];
        if (length + 1 <= capacity - *lengthP) {
            olSuggestCopy(outputP + *lengthP, workspaceP->words[index], length);
            *lengthP += length + 1;
        }
    }
    return 1;
}

#ifdef __WATCOMC__
#pragma code_seg("OpenLexCode")
#endif
