#ifndef _PREF_APPL_LOW_H_
#define _PREF_APPL_LOW_H_

#include <file.h>
#include <geode.h>

typedef enum {
    PREF_APPL_ERROR_NONE,
    PREF_APPL_SCAN_ERROR_DISTAPPL_MISSING,
    PREF_APPL_SCAN_ERROR_OUT_OF_MEMORY
} PrefApplError;

typedef struct {
    GeodeToken PAAR_token;
    FileLongName PAAR_name;
    Boolean PAAR_selected;
} PrefApplApplicationRecord;

Boolean PrefApplCreateApplicationLink(const PrefApplApplicationRecord *record);
Boolean PrefApplDeleteScannedLinksForToken(const GeodeToken *token);

Boolean PrefApplRefreshApplicationData(void);
word PrefApplGetDisabledApplicationCount(void);
word PrefApplGetLinkedApplicationCount(void);
Boolean PrefApplGetApplicationRecord(word index, PrefApplApplicationRecord *record);
Boolean PrefApplMapDisabledIndexToApplicationIndex(word disabledIndex,
                                                   word *appIndexPtr);
Boolean PrefApplMapLinkedIndexToApplicationIndex(word linkedIndex, word *appIndexPtr);
PrefApplError PrefApplGetLastScanError(void);

#endif
