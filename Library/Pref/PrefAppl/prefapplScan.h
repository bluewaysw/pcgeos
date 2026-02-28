#ifndef _PREF_APPL_SCAN_H_
#define _PREF_APPL_SCAN_H_

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

Boolean PrefApplRefreshApplicationData(void);
void PrefApplClearScannedApplications(void);
word PrefApplGetApplicationCount(void);
Boolean PrefApplGetApplicationRecord(word index, PrefApplApplicationRecord *record);
PrefApplError PrefApplGetLastScanError(void);

#endif
