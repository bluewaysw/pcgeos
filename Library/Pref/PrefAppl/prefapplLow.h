#ifndef _PREF_APPL_SCAN_H_
#define _PREF_APPL_SCAN_H_

#include <file.h>
#include <geode.h>

typedef enum {
    PREF_APPL_ERROR_NONE,
    PREF_APPL_SCAN_ERROR_DISTAPPL_MISSING,
    PREF_APPL_SCAN_ERROR_OUT_OF_MEMORY,
    PREF_APPL_OPERATION_SUCCESS,
    PREF_APPL_OPERATION_PARTIAL_FAILURE
} PrefApplError;

typedef struct {
    GeodeToken PAAR_token;
    FileLongName PAAR_name;
    Boolean PAAR_selected;
} PrefApplApplicationRecord;

typedef struct {
    StandardPath PALR_sourceRoot;
    DiskHandle PALR_targetDisk;
    GeodeToken PALR_targetToken;
    PathName PALR_relativeDir;
    FileLongName PALR_linkName;
    PathName PALR_targetPath;
} PrefApplLinkRecord;

Boolean PrefApplRescanApplicationLinks(void);
void PrefApplClearScannedLinks(void);
word PrefApplGetScannedLinkCount(void);
Boolean PrefApplGetScannedLinkRecord(word index, PrefApplLinkRecord *record);
Boolean PrefApplDidHitTraversalDepthLimit(void);
Boolean PrefApplCreateApplicationLink(const PrefApplApplicationRecord *record);
Boolean PrefApplAddScannedApplicationLink(const PrefApplApplicationRecord *record);
Boolean PrefApplDeleteScannedLinksForToken(const GeodeToken *token);
void PrefApplRemoveScannedLinksForToken(const GeodeToken *token);

Boolean PrefApplRefreshApplicationData(void);
void PrefApplClearScannedApplications(void);
word PrefApplGetApplicationCount(void);
word PrefApplGetLinkedApplicationCount(void);
Boolean PrefApplGetApplicationRecord(word index, PrefApplApplicationRecord *record);
Boolean PrefApplMapLinkedIndexToApplicationIndex(word linkedIndex, word *appIndexPtr);
Boolean PrefApplMapApplicationIndexToLinkedIndex(word appIndex, word *linkedIndexPtr);
Boolean PrefApplSetApplicationSelected(word index, Boolean selected);
PrefApplError PrefApplGetLastScanError(void);

#endif
