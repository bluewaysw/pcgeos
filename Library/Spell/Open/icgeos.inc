/*
 * SPDX-License-Identifier: Apache-2.0
 * icgeos.inc - OpenSpellGEOS spelling and personal dictionary implementation.
 *
 * The public assembly exports, ICBuff layout and thread model are unchanged.
 * Assembly entrypoints use _export so Watcom loads and restores library DS;
 * callers are allowed to enter with DS pointing at their own text or objects.
 * Every ICBuff owns one movable reader/ignore block; no raw pointer is retained
 * while that block is unlocked. One library-owned user dictionary is shared
 * across clients and protected by the existing spell semaphore. This shared
 * state is necessary to keep concurrent Preferences and Writer edits coherent.
 *
 * Dictionaries are exact-word OpenLex files. The engine never loads an entire
 * language dictionary. Personal entries are GEOS SBCS, at most 64
 * bytes, sorted and NUL-terminated within a 4096-byte bounded file. See the
 * accompanying format and integration documentation for the deliberate limits.
 */
#include "geosbridge.h"
#ifndef OPEN_SPELL_HOST_TEST
#include <initfile.h>
#include <geode.h>
#include <sem.h>
#endif
#include <sllang.h>
#include <stddef.h>

/* The assembly ABI uses words, whereas compiler enum sizes are configurable. */
typedef word SpellTask;
typedef word SpellResult;
typedef word SpellErrorFlags;
typedef word SpellErrorFlagsHigh;
typedef word LanguageDialect;
#pragma pack(push, 1)
#include <Internal/icbuff.h>
#pragma pack(pop)

#define OPEN_OK 0
#define OPEN_INVALID 3
#define OPEN_PRE_PROC 4
#define OPEN_ERROR 8
#define OPEN_FOUND 10
#define OPEN_NOT_FOUND 11
#define OPEN_NOMEM 15
#define OPEN_NO_OPEN 16
#define OPEN_USER_SAVE_ERROR 11
#define OPEN_USER_LOAD_ERROR 12
#define OPEN_USER_VERSION_ERROR 13
#define OPEN_USER_MEMORY_ERROR 14
#define OPEN_USER_SAVE_RESULT 10 /* UR_SER in Internal/spelllib.def. */
#define OPEN_IGNORED 20
#define OPEN_VERIFY 3
#define OPEN_CORRECT 100
#define OPEN_USER_BYTES 4088
#define OPEN_IGNORE_BYTES 1024
#define OPEN_CASE_MIXED 0
#define OPEN_CASE_LOWER 1
#define OPEN_CASE_TITLE 2
#define OPEN_CASE_UPPER 3

/* Compile-time checks fail rather than silently changing assembly offsets. */
#ifdef __WATCOMC__
typedef char OpenCheckWordOffset[(offsetof(ICBuff, ICB_word) == 101) ? 1 : -1];
typedef char OpenCheckCountOffset[(offsetof(ICBuff, ICB_numAlts) == 362) ? 1 : -1];
typedef char OpenCheckContextOffset[(offsetof(ICBuff, ICB_hctlBuff) ==
                                    610 + 2 * ICS_ANAGRAM) ? 1 : -1];
typedef char OpenCheckBufferSize[(sizeof(ICBuff) == 634 + 2 * ICS_ANAGRAM) ? 1 : -1];
#endif

typedef struct {
    OpenGeoFile dictionary;
    word ignoreUsed;
    unsigned char ignore[OPEN_IGNORE_BYTES];
    unsigned char folded[65];
    OLSuggestWorkspace suggestions;
    unsigned char suggestionWords[ICCORMAX];
} OpenSpellContext;

/* Keep the reader cache and all per-client scratch below the GEOS budget. */
typedef char OpenCheckSpellContextSize[(sizeof(OpenSpellContext) <= 8192) ? 1 : -1];

typedef struct {
    unsigned char magic[4];
    word used;
    word count;
    unsigned char words[OPEN_USER_BYTES];
} OpenUserDictionary;

typedef char OpenCheckUserSize[(sizeof(OpenUserDictionary) == 4096) ? 1 : -1];

/* Match the existing assembly symbols without changing their public names. */
extern SemaphoreHandle spellSem;
#pragma aux spellSem "spellSem";
static MemHandle openUsersH;
static word openUserReferences;

/* Reuse the existing localized Strings pairs through the native notifier. */
extern void _pascal OpenUserNotify(word errorCode);

#pragma code_seg("CODE")

/* Compare NUL-terminated GEOS byte strings without signed-char ordering. */
int _pascal OpenWordCompare(const unsigned char *leftP,
                                  const unsigned char *rightP)
{
    while (*leftP && *leftP == *rightP) {
        ++leftP;
        ++rightP;
    }
    return (int)*leftP - (int)*rightP;
}

/* Copy a validated short word, including its terminator, without libc. */
void _pascal OpenWordCopy(unsigned char *destP,
                                const unsigned char *sourceP)
{
    do {
        *destP++ = *sourceP;
    } while (*sourceP++);
}

/* Locate an exact entry or its sorted insertion offset in a bounded list. */
word _pascal OpenUserOffset(OpenUserDictionary *usersP,
                                  const unsigned char *wordP, int *foundP)
{
    word offset;
    int comparison;
    offset = 0;
    *foundP = 0;
    while (offset < usersP->used) {
        comparison = OpenWordCompare(usersP->words + offset, wordP);
        if (comparison >= 0) {
            *foundP = comparison == 0;
            break;
        }
        offset += OpenGeoLength(usersP->words + offset, 65) + 1;
    }
    return offset;
}

/* Personal words retain display case but match all case variants in text. */
int _pascal OpenUserContains(OpenUserDictionary *usersP,
                                   const unsigned char *wordP)
{
    word offset;
    word index;
    offset = 0;
    while (offset < usersP->used) {
        index = 0;
        while (wordP[index] && usersP->words[offset + index] &&
               olLower(wordP[index]) == olLower(usersP->words[offset + index])) {
            ++index;
        }
        if (!wordP[index] && !usersP->words[offset + index]) {
            return 1;
        }
        offset += OpenGeoLength(usersP->words + offset, 65) + 1;
    }
    return 0;
}

/* Check every byte and record before accepting an on-disk personal list. */
int _pascal OpenUserValid(OpenUserDictionary *usersP, word fileBytes)
{
    word offset;
    word length;
    word count;
    word previous;
    word index;
    if (fileBytes < 8 || usersP->magic[0] != 'O' ||
        usersP->magic[1] != 'S' || usersP->magic[2] != 'U' ||
        usersP->magic[3] != '1' || usersP->used > OPEN_USER_BYTES ||
        fileBytes != usersP->used + 8) {
        return 0;
    }
    offset = 0;
    previous = 0;
    count = 0;
    while (offset < usersP->used) {
        length = OpenGeoLength(usersP->words + offset,
                              usersP->used - offset);
        if (!length || length > 64 || length == usersP->used - offset) {
            return 0;
        }
        for (index = 0; index < length; ++index) {
            if (usersP->words[offset + index] < 33) {
                return 0;
            }
        }
        if (count && OpenWordCompare(usersP->words + previous,
                                    usersP->words + offset) >= 0) {
            return 0;
        }
        previous = offset;
        offset += length + 1;
        ++count;
    }
    return count == usersP->count;
}

/* Return zero or SP-12/13/14; recover BAK only if USR is absent. */
int _pascal OpenUserLoad(void)
{
    OpenUserDictionary *usersP;
    FileHandle fileH;
    dword size;
    word readSize;
    int result;
    openUsersH = MemAllocSetOwner(GeodeGetCodeProcessHandle(),
                                 sizeof(OpenUserDictionary), HF_DYNAMIC | HF_SHARABLE,
                                 HAF_ZERO_INIT);
    if (!openUsersH) {
        return OPEN_USER_MEMORY_ERROR;
    }
    usersP = (OpenUserDictionary *)MemLock(openUsersH);
    usersP->magic[0] = 'O';
    usersP->magic[1] = 'S';
    usersP->magic[2] = 'U';
    usersP->magic[3] = '1';
    result = OPEN_USER_LOAD_ERROR;
    FilePushDir();
    if (FileSetCurrentPath(SP_USER_DATA, "DICTS")) {
        fileH = FileOpen("OPENUSER.USR", FILE_ACCESS_R | FILE_DENY_W);
        if (!fileH && ThreadGetError() == ERROR_FILE_NOT_FOUND) {
            fileH = FileOpen("OPENUSER.BAK", FILE_ACCESS_R | FILE_DENY_W);
            if (!fileH && ThreadGetError() == ERROR_FILE_NOT_FOUND) {
                result = 0;
            }
        }
        if (fileH) {
            size = FileSize(fileH);
            readSize = 4;
            if (size >= 8 && size <= sizeof(OpenUserDictionary)) {
                readSize = (word)size;
            }
            /* A future version may exceed OSU1's bounded table size. */
            if (size >= 4 && FileRead(fileH, usersP, readSize, FALSE) == readSize) {
                if (usersP->magic[0] == 'O' && usersP->magic[1] == 'S' &&
                    usersP->magic[2] == 'U' && usersP->magic[3] != '1') {
                    result = OPEN_USER_VERSION_ERROR;
                } else if (readSize == size &&
                           OpenUserValid(usersP, readSize)) {
                    result = 0;
                }
            }
            if (FileClose(fileH, FALSE)) {
                result = OPEN_USER_LOAD_ERROR;
            }
        }
    }
    FilePopDir();
    MemUnlock(openUsersH);
    if (result) {
        MemFree(openUsersH);
        openUsersH = 0;
    }
    return result;
}

/* Commit a complete replacement before publishing it to concurrent clients. */
int _pascal OpenUserSave(OpenUserDictionary *usersP)
{
    FileHandle fileH;
    word size;
    word error;
    int result;
    int hadOriginal;
    result = 0;
    size = usersP->used + 8;
    FilePushDir();
    if (FileSetCurrentPath(SP_USER_DATA, "DICTS")) {
        fileH = FileCreate("OPENUSER.TMP", FCF_NATIVE |
                           FILE_CREATE_TRUNCATE | FILE_ACCESS_W |
                           FILE_DENY_RW, 0);
        if (fileH) {
            error = FileWrite(fileH, usersP, size, FALSE) != size;
            if (!error) {
                error = FileCommit(fileH, FALSE);
            }
            if (FileClose(fileH, FALSE)) {
                error = 1;
            }
            if (!error) {
                /* BAK is never the only copy when it is removed here. */
                fileH = FileOpen("OPENUSER.USR", FILE_ACCESS_R | FILE_DENY_W);
                hadOriginal = fileH != 0;
                if (fileH) {
                    FileClose(fileH, FALSE);
                    error = FileDelete("OPENUSER.BAK");
                    if (error == ERROR_FILE_NOT_FOUND) {
                        error = 0;
                    }
                    if (!error) {
                        error = FileRename("OPENUSER.USR", "OPENUSER.BAK");
                    }
                } else {
                    error = ThreadGetError();
                    if (error == ERROR_FILE_NOT_FOUND) {
                        error = 0;
                    }
                }
                if (!error) {
                    error = FileRename("OPENUSER.TMP", "OPENUSER.USR");
                    if (error && hadOriginal) {
                        FileRename("OPENUSER.BAK", "OPENUSER.USR");
                    }
                    result = !error;
                }
            }
        }
    }
    FilePopDir();
    return result;
}

/* Validate personal/ignore entries, preserving spelling for the legacy UI. */
word _pascal OpenPersonalWord(const unsigned char *sourceP,
                                    unsigned char *destP)
{
    word length;
    word index;
    length = OpenGeoLength(sourceP, 65);
    if (!length || length > 64) {
        return 0;
    }
    for (index = 0; index < length; ++index) {
        if (sourceP[index] < 33) {
            return 0;
        }
        destP[index] = sourceP[index];
    }
    destP[length] = 0;
    return length;
}

#pragma code_seg("INIT")

/* Compatibility hook: initialization belongs to each ICBuff, not this call. */
word _pascal _export ICGEOSplInit(void)
{
    return OPEN_OK;
}

/* Bind a dictionary and shared users; unwind every allocation on failure. */
word _pascal _export ICGEOSplInitICBuff(MemHandle bufferH)
{
    ICBuff *bufferP;
    OpenSpellContext *contextP;
    MemHandle contextH;
    word language;
    word dialect;
    word result;
    word userError;
    userError = 0;
    bufferP = (ICBuff *)MemLock(bufferH);
    bufferP->ICB_initFlags = 0;
    contextH = MemAllocSetOwner(GeodeGetCodeProcessHandle(),
                               sizeof(OpenSpellContext), HF_DYNAMIC | HF_SHARABLE,
                               HAF_ZERO_INIT);
    result = OPEN_NOMEM;
    if (!contextH) {
        bufferP->ICB_initFlags = SIF_ALLOC_ERR;
    } else {
        contextP = (OpenSpellContext *)MemLock(contextH);
        result = OPEN_NO_OPEN;
        if (OpenGeoName(bufferP->ICB_masterFname, "DCT") == 1 &&
            OpenGeoOpen(&contextP->dictionary, 1,
                        bufferP->ICB_masterFname) == 1) {
            ThreadPSem(spellSem);
            if (!openUsersH) {
                userError = OpenUserLoad();
            }
            if (!userError) {
                ++openUserReferences;
                result = OPEN_OK;
            } else {
                result = OPEN_ERROR;
                bufferP->ICB_initFlags = SIF_USER_DICT_ERR;
            }
            ThreadVSem(spellSem);
        } else {
            bufferP->ICB_initFlags = SIF_OPEN_ERR;
        }
        if (result != OPEN_OK) {
            OpenGeoClose(&contextP->dictionary);
        }
        MemUnlock(contextH);
        if (result != OPEN_OK) {
            MemFree(contextH);
        } else {
            bufferP->ICB_hctlBuff = contextH;
            bufferP->ICB_initFlags = SIF_INIT_OK;
            language = SL_ENGLISH;
            dialect = LD_DEFAULT;
            InitFileReadInteger("text", "language", &language);
            InitFileReadInteger("text", "dialect", &dialect);
            bufferP->ICB_language = (byte)language;
            bufferP->ICB_dialect = dialect;
            bufferP->ICB_task = OPEN_VERIFY;
        }
    }
    MemUnlock(bufferH);
    if (userError) {
        /* Notify only after releasing the semaphore and movable blocks. */
        OpenUserNotify(userError);
    }
    return result;
}

#pragma code_seg("EXIT")

/* Release this client's movable reader and its reference to shared users. */
void _pascal _export ICGEOSplExitICBuff(MemHandle bufferH)
{
    ICBuff *bufferP;
    OpenSpellContext *contextP;
    MemHandle contextH;
    bufferP = (ICBuff *)MemLock(bufferH);
    contextH = bufferP->ICB_hctlBuff;
    bufferP->ICB_hctlBuff = 0;
    if (contextH) {
        contextP = (OpenSpellContext *)MemLock(contextH);
        OpenGeoClose(&contextP->dictionary);
        MemUnlock(contextH);
        MemFree(contextH);
        ThreadPSem(spellSem);
        if (openUserReferences && !--openUserReferences) {
            MemFree(openUsersH);
            openUsersH = 0;
        }
        ThreadVSem(spellSem);
    }
    MemUnlock(bufferH);
}

/* Edits are committed synchronously; unloading has no deferred disk writes. */
void _pascal _export ICGEOSplExit(void)
{
    if (openUsersH) {
        MemFree(openUsersH);
        openUsersH = 0;
    }
    openUserReferences = 0;
}

#pragma code_seg("CODE")

/* Recognize harmless edge punctuation while retaining true text offsets. */
int _pascal OpenEdgePunctuation(unsigned char letter)
{
    return letter == '.' || letter == ',' || letter == '!' || letter == '?' ||
           letter == ':' || letter == ';' || letter == '(' || letter == ')' ||
           letter == '[' || letter == ']' || letter == '{' || letter == '}' ||
           letter == '"' || letter == '\'' || letter == ' ' ||
           letter == 0xc7 || letter == 0xc8 || letter == 0xc9 ||
           (letter >= 0xd0 && letter <= 0xd5);
}

/* Classify SBCS case without treating punctuation as a lowercase letter.
 * The same GEOS byte mapping drives lookup and suggestion capitalization.
 * A title has its sole uppercase letter at byte zero; mixed case is retained.
 */
word _pascal OpenWordCase(const unsigned char *wordP, word length)
{
    word index;
    int title;
    int capitals;
    int uppercase;
    title = 1;
    capitals = 1;
    uppercase = 0;
    for (index = 0; index < length; ++index) {
        if (olLower(wordP[index]) != wordP[index]) {
            uppercase = 1;
            if (index) {
                title = 0;
            }
        }
        if (olUpper(wordP[index]) != wordP[index]) {
            capitals = 0;
        }
    }
    if (!uppercase) {
        return OPEN_CASE_LOWER;
    }
    if (capitals) {
        return OPEN_CASE_UPPER;
    }
    return title ? OPEN_CASE_TITLE : OPEN_CASE_MIXED;
}

/* Populate all bounded alternates in one pass. The legacy UI calls ST_CORRECT
 * with an empty source and loops only while IC_RET_FOUND is returned; return
 * NOT_FOUND to signal completion while retaining the populated alternate list.
 */
word _pascal OpenSpellSuggest(ICBuff *bufferP, OpenSpellContext *contextP)
{
    word length;
    word outputLength;
    word candidateLength;
    word candidateOffset;
    word offset;
    word index;
    word valueLength;
    word caseMode;
    unsigned char flag;
    unsigned char *candidateP;
    int result;
    int duplicate;
    length = OpenGeoLength((unsigned char *)bufferP->ICB_word, 65);
    bufferP->ICB_numAlts = 0;
    bufferP->ICB_nextAlt = 0;
    if (!length || length > 64) {
        return OPEN_NOT_FOUND;
    }
    caseMode = OpenWordCase((unsigned char *)bufferP->ICB_word, length);
    /* The core jointly ranks typed and folded candidates before applying the
     * result limit. Project only ordinary lowercase entries; a dictionary's
     * exact-case names and German nouns retain their canonical spelling.
     */
    result = olSuggest(&contextP->dictionary.lex,
                       (unsigned char *)bufferP->ICB_word, length,
                       contextP->suggestionWords, ICCORMAX,
                       &outputLength, &contextP->suggestions);
    if (result < 0 || outputLength > ICCORMAX) {
        return OPEN_ERROR;
    }
    offset = 0;
    candidateOffset = 0;
    while (candidateOffset < outputLength && bufferP->ICB_numAlts < ICMAXALT) {
        candidateP = contextP->suggestionWords + candidateOffset;
        candidateLength = OpenGeoLength(candidateP, outputLength - candidateOffset);
        if (!candidateLength || candidateLength > 64 ||
            candidateLength == outputLength - candidateOffset) {
            bufferP->ICB_numAlts = 0;
            return OPEN_ERROR;
        }
        result = olFind(&contextP->dictionary.lex, candidateP, candidateLength,
                        &flag, 1, &valueLength);
        if (result != 1 || valueLength != 1 ||
            (flag != OL_FOLD_CASE && flag != OL_EXACT_CASE)) {
            bufferP->ICB_numAlts = 0;
            return OPEN_ERROR;
        }
        if (flag == OL_FOLD_CASE && caseMode >= OPEN_CASE_TITLE) {
            candidateP[0] = olUpper(candidateP[0]);
            if (caseMode == OPEN_CASE_UPPER) {
                for (index = 1; index < candidateLength; ++index) {
                    candidateP[index] = olUpper(candidateP[index]);
                }
            }
        }
        duplicate = 0;
        for (index = 0; index < bufferP->ICB_numAlts; ++index) {
            if (!OpenWordCompare((unsigned char *)bufferP->ICB_altList +
                                 bufferP->ICB_correctPtr[index], candidateP)) {
                duplicate = 1;
                break;
            }
        }
        if (!duplicate) {
            /* Projection preserves byte lengths; removing duplicates can
             * only shrink the already bounded core result buffer.
             */
            bufferP->ICB_correctPtr[bufferP->ICB_numAlts++] = offset;
            OpenWordCopy((unsigned char *)bufferP->ICB_altList + offset, candidateP);
            offset += candidateLength + 1;
        }
        candidateOffset += candidateLength + 1;
    }
    return OPEN_NOT_FOUND;
}

/* Run one bounded spelling operation using the existing Pascal stack ABI. */
word _pascal _export ICGEOSpl(const unsigned char *sourceP, MemHandle bufferH)
{
    ICBuff *bufferP;
    OpenSpellContext *contextP;
    OpenUserDictionary *usersP;
    MemHandle contextH;
    word sourceLength;
    word left;
    word right;
    word length;
    word index;
    word offset;
    word valueLength;
    word result;
    unsigned char flag;
    int found;
    int numeric;
    int lookup;
    bufferP = (ICBuff *)MemLock(bufferH);
    contextH = bufferP->ICB_hctlBuff;
    result = OPEN_ERROR;
    if (!contextH) {
        MemUnlock(bufferH);
        return result;
    }
    contextP = (OpenSpellContext *)MemLock(contextH);
    contextP->dictionary.lex.userP = &contextP->dictionary;
    if (bufferP->ICB_task == OPEN_CORRECT) {
        result = OpenSpellSuggest(bufferP, contextP);
        bufferP->ICB_retCode = result;
        MemUnlock(contextH);
        MemUnlock(bufferH);
        return result;
    }
    bufferP->ICB_numAlts = 0;
    bufferP->ICB_nextAlt = 0;
    bufferP->ICB_errorFlags = 0;
    bufferP->ICB_errorFlagsHigh = 0;
    bufferP->ICB_processFlags = 0;
    bufferP->ICB_lside = 0;
    bufferP->ICB_rside = 0;
    bufferP->ICB_slashMap.WM_data[0] = 0;
    bufferP->ICB_hyphenMap.WM_data[0] = 0;
    bufferP->ICB_emDashMap.WM_data[0] = 0;
    bufferP->ICB_elDashMap.WM_data[0] = 0;
    sourceLength = OpenGeoLength(sourceP, 65);
    if (sourceLength > 64) {
        result = OPEN_INVALID;
    } else {
        left = 0;
        right = sourceLength;
        while (left < right && OpenEdgePunctuation(sourceP[left])) {
            ++left;
        }
        while (right > left && OpenEdgePunctuation(sourceP[right - 1])) {
            --right;
        }
        length = right - left;
        bufferP->ICB_lside = left;
        /* Existing assembly expects the inclusive index of the last byte. */
        bufferP->ICB_rside = length ? right - 1 : left;
        bufferP->ICB_len = length;
        numeric = length != 0;
        for (index = 0; index < length; ++index) {
            flag = sourceP[left + index];
            /* GEOS smart apostrophes occupy one byte, as does ASCII quote. */
            if (flag == 0xd5) {
                flag = '\'';
            }
            bufferP->ICB_word[index] = flag;
            contextP->folded[index] = olLower(flag);
            if (flag < '0' || flag > '9') {
                numeric = 0;
            }
            if (flag == '/') {
                bufferP->ICB_slashMap.WM_data[0] = 1;
            }
            if (flag == '-') {
                bufferP->ICB_hyphenMap.WM_data[0] = 1;
            }
            if (flag == 0xd1 || flag == 0xd0) {
                bufferP->ICB_emDashMap.WM_data[0] = 1;
            }
            if (flag == 0xc9) {
                bufferP->ICB_elDashMap.WM_data[0] = 1;
            }
        }
        bufferP->ICB_word[length] = 0;
        contextP->folded[length] = 0;
        result = OPEN_NOT_FOUND;
        if (!length || numeric) {
            result = OPEN_PRE_PROC;
        } else if (bufferP->ICB_task != OPEN_VERIFY) {
            /* ATTENTION: wildcard/anagram enumeration is not implemented. */
            result = OPEN_INVALID;
        } else {
            offset = 0;
            while (offset < contextP->ignoreUsed) {
                if (!OpenWordCompare(contextP->ignore + offset, contextP->folded)) {
                    result = OPEN_IGNORED;
                    break;
                }
                offset += OpenGeoLength(contextP->ignore + offset, 65) + 1;
            }
            if (result != OPEN_IGNORED) {
                ThreadPSem(spellSem);
                usersP = (OpenUserDictionary *)MemLock(openUsersH);
                found = OpenUserContains(usersP, contextP->folded);
                MemUnlock(openUsersH);
                ThreadVSem(spellSem);
                if (found) {
                    result = OPEN_FOUND;
                    bufferP->ICB_processFlags = SPF_IN_USER_DICT;
                } else {
                    lookup = olFind(&contextP->dictionary.lex,
                                    (unsigned char *)bufferP->ICB_word, length,
                                    &flag, 1, &valueLength);
                    if (lookup == 1 && (valueLength != 1 ||
                        (flag != OL_FOLD_CASE && flag != OL_EXACT_CASE))) {
                        lookup = -1;
                    }
                    if (!lookup && OpenWordCase(
                            (unsigned char *)bufferP->ICB_word, length) !=
                            OPEN_CASE_MIXED) {
                        lookup = olFind(&contextP->dictionary.lex,
                                        contextP->folded, length,
                                        &flag, 1, &valueLength);
                        if (lookup == 1) {
                            if (valueLength != 1 ||
                                (flag != OL_FOLD_CASE && flag != OL_EXACT_CASE)) {
                                lookup = -1;
                            } else if (flag != OL_FOLD_CASE) {
                                lookup = 0;
                            }
                        }
                    }
                    result = lookup < 0 ? OPEN_ERROR :
                             (lookup ? OPEN_FOUND : OPEN_NOT_FOUND);
                }
            }
        }
    }
    if (bufferP->ICB_task == OPEN_VERIFY) {
        if (result == OPEN_FOUND) {
            if (!OpenWordCompare((unsigned char *)bufferP->ICB_prevWord,
                                 contextP->folded)) {
                bufferP->ICB_errorFlags |= 0x8000;
            }
            OpenWordCopy((unsigned char *)bufferP->ICB_prevWord,
                         contextP->folded);
        } else {
            bufferP->ICB_prevWord[0] = 0;
        }
    }
    bufferP->ICB_retCode = result;
    MemUnlock(contextH);
    MemUnlock(bufferH);
    return result;
}

/* Copy a terminated indexed alternate; invalid indices/tails yield empty. */
void _pascal _export ICGEOGetAlternate(unsigned char *destP,
                               const unsigned char *sourceP,
                               MemHandle bufferH, word index)
{
    ICBuff *bufferP;
    word offset;
    word remaining;
    word length;
    sourceP = sourceP;
    destP[0] = 0;
    bufferP = (ICBuff *)MemLock(bufferH);
    if (index < bufferP->ICB_numAlts && index < ICMAXALT) {
        offset = bufferP->ICB_correctPtr[index];
        if (offset < ICCORMAX) {
            remaining = ICCORMAX - offset;
            length = OpenGeoLength((unsigned char *)bufferP->ICB_altList + offset,
                                   remaining);
            /* A short remaining tail is not proof that a NUL was present. */
            if (length < remaining && length <= 64) {
                OpenWordCopy(destP, (unsigned char *)bufferP->ICB_altList + offset);
            }
        }
    }
    MemUnlock(bufferH);
}

#pragma code_seg("IPCODE")

/* Apply one user edit to a private copy, then publish only after disk commit. */
dword _pascal OpenUserEdit(const unsigned char *wordP, int remove)
{
    unsigned char personalWord[65];
    OpenUserDictionary *oldP;
    OpenUserDictionary *newP;
    MemHandle replacementH;
    MemHandle oldH;
    word length;
    word offset;
    word index;
    word result;
    word userResult;
    int found;
    length = OpenPersonalWord(wordP, personalWord);
    if (!length) {
        return ((dword)15 << 16) | OPEN_INVALID;
    }
    result = OPEN_ERROR;
    userResult = 7;
    ThreadPSem(spellSem);
    oldP = (OpenUserDictionary *)MemLock(openUsersH);
    offset = OpenUserOffset(oldP, personalWord, &found);
    if ((!remove && found) || (remove && !found)) {
        result = found ? OPEN_ERROR : OPEN_NOT_FOUND;
        userResult = found ? 5 : 2;
    } else if (!remove && oldP->used + length + 1 > OPEN_USER_BYTES) {
        result = OPEN_NOMEM;
        userResult = 12;
    } else {
        replacementH = MemAllocSetOwner(GeodeGetCodeProcessHandle(),
                                        sizeof(OpenUserDictionary), HF_DYNAMIC | HF_SHARABLE,
                                        HAF_ZERO_INIT);
        if (!replacementH) {
            result = OPEN_NOMEM;
            userResult = 12;
        } else {
            newP = (OpenUserDictionary *)MemLock(replacementH);
            for (index = 0; index < sizeof(OpenUserDictionary); ++index) {
                ((unsigned char *)newP)[index] = ((unsigned char *)oldP)[index];
            }
            if (remove) {
                for (index = offset; index + length + 1 < newP->used; ++index) {
                    newP->words[index] = newP->words[index + length + 1];
                }
                newP->used -= length + 1;
                --newP->count;
            } else {
                index = newP->used;
                while (index > offset) {
                    --index;
                    newP->words[index + length + 1] = newP->words[index];
                }
                OpenWordCopy(newP->words + offset, personalWord);
                newP->used += length + 1;
                ++newP->count;
            }
            if (OpenUserSave(newP)) {
                result = OPEN_OK;
                userResult = remove ? 0 : 1;
            } else {
                userResult = OPEN_USER_SAVE_RESULT;
            }
            MemUnlock(replacementH);
            if (result == OPEN_OK) {
                oldH = openUsersH;
                openUsersH = replacementH;
                MemUnlock(oldH);
                MemFree(oldH);
                oldP = (void *)0;
            } else {
                MemFree(replacementH);
            }
        }
    }
    if (oldP != (void *)0) {
        MemUnlock(openUsersH);
    }
    ThreadVSem(spellSem);
    if (userResult == OPEN_USER_SAVE_RESULT) {
        /* The old list is still live and the failed candidate was freed. */
        OpenUserNotify(OPEN_USER_SAVE_ERROR);
    }
    return ((dword)userResult << 16) | result;
}

/* Return SpellResult in AX and UserResult in DX, as the assembly UI expects. */
dword _pascal _export IPGEOAddUser(const unsigned char *wordP, MemHandle bufferH)
{
    bufferH = bufferH;
    return OpenUserEdit(wordP, 0);
}

/* Delete persistently; a failed disk commit leaves the live list unchanged. */
dword _pascal _export IPGEODeleteUser(const unsigned char *wordP, MemHandle bufferH)
{
    bufferH = bufferH;
    return OpenUserEdit(wordP, 1);
}

/* Legacy user-lookup entry retained for source compatibility with old code. */
word _pascal _export IPGEOUsr(const unsigned char *wordP, MemHandle bufferH)
{
    unsigned char personalWord[65];
    OpenUserDictionary *usersP;
    int found;
    bufferH = bufferH;
    if (!OpenPersonalWord(wordP, personalWord)) {
        return OPEN_INVALID;
    }
    ThreadPSem(spellSem);
    usersP = (OpenUserDictionary *)MemLock(openUsersH);
    found = OpenUserContains(usersP, personalWord);
    MemUnlock(openUsersH);
    ThreadVSem(spellSem);
    return found ? OPEN_FOUND : OPEN_NOT_FOUND;
}

/* Add an exact folded word to this session only, with a 1024-byte ceiling. */
void _pascal _export ICGEOIgnoreString(const unsigned char *wordP, MemHandle bufferH)
{
    ICBuff *bufferP;
    OpenSpellContext *contextP;
    word length;
    word offset;
    bufferP = (ICBuff *)MemLock(bufferH);
    if (bufferP->ICB_hctlBuff) {
        contextP = (OpenSpellContext *)MemLock(bufferP->ICB_hctlBuff);
        length = OpenPersonalWord(wordP, contextP->folded);
        OpenGeoFold(contextP->folded, length);
        offset = 0;
        while (offset < contextP->ignoreUsed &&
               OpenWordCompare(contextP->ignore + offset, contextP->folded)) {
            offset += OpenGeoLength(contextP->ignore + offset, 65) + 1;
        }
        if (length && offset == contextP->ignoreUsed) {
            if (offset + length + 1 <= OPEN_IGNORE_BYTES) {
                OpenWordCopy(contextP->ignore + offset, contextP->folded);
                contextP->ignoreUsed += length + 1;
            } else {
                /* The legacy void API cannot report ignore-list exhaustion. */
                bufferP->ICB_retCode = OPEN_NOMEM;
            }
        }
        MemUnlock(bufferP->ICB_hctlBuff);
    }
    MemUnlock(bufferH);
}

/* Clear only the client's ignore list; personal dictionary entries persist. */
void _pascal _export ICResetIgnoreUserDict(MemHandle bufferH)
{
    ICBuff *bufferP;
    OpenSpellContext *contextP;
    bufferP = (ICBuff *)MemLock(bufferH);
    if (bufferP->ICB_hctlBuff) {
        contextP = (OpenSpellContext *)MemLock(bufferP->ICB_hctlBuff);
        contextP->ignoreUsed = 0;
        MemUnlock(bufferP->ICB_hctlBuff);
    }
    MemUnlock(bufferH);
}

#pragma code_seg("IPPRINT")

/* No deferred updates exist: each successful add/delete already reached disk. */
void _pascal _export UpdateUserDictionary(MemHandle bufferH)
{
    bufferH = bufferH;
}

/* Return UserDictionaryListInfo (four words) followed by sorted NUL strings. */
MemHandle _pascal _export IPGEOBuildUserList(MemHandle bufferH)
{
    OpenUserDictionary *usersP;
    unsigned char *listP;
    word *headerP;
    MemHandle listH;
    word index;
    bufferH = bufferH;
    ThreadPSem(spellSem);
    usersP = (OpenUserDictionary *)MemLock(openUsersH);
    listH = MemAlloc(usersP->used + 8, HF_DYNAMIC | HF_SHARABLE, HAF_ZERO_INIT);
    if (listH) {
        listP = (unsigned char *)MemLock(listH);
        headerP = (word *)listP;
        headerP[0] = usersP->count;
        headerP[1] = usersP->used + 8;
        headerP[2] = 0;
        headerP[3] = 8;
        for (index = 0; index < usersP->used; ++index) {
            listP[index + 8] = usersP->words[index];
        }
        MemUnlock(listH);
    }
    MemUnlock(openUsersH);
    ThreadVSem(spellSem);
    return listH;
}
