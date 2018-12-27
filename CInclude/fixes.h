/***********************************************************************
 *
 * FILE:          fixes.h
 *                Various fixed data structures from the SDK
 *
 * AUTHOR:        Marcus Gr”ber
 *
 ***********************************************************************/

#if !defined(__FIXES_H)
#define __FIXES_H

/* TOKEN_CHARS used with variables shorter than dword fails because types
   are not promoted correctly... */
#define TOKEN_CHARS_fixed(a,b,c,d)\
  TOKEN_CHARS((dword)(a),(dword)(b),(dword)(c),(dword)(d))

typedef struct {
    AppInstanceReference	ALB_appRef;
    word			ALB_appMode;
    AppLaunchFlags		ALB_launchFlags;
    MemHandle			ALB_diskHandle;
    char			ALB_path[PATH_BUFFER_SIZE];
    FileLongName                ALB_dataFile;
    optr			ALB_genParent;
    optr			ALB_userLoadAckOutput;
    Message			ALB_userLoadAckMessage;
    word			ALB_userLoadAckID;
    word			ALB_extraData;
} myAppLaunchBlock;

typedef struct {
  HugeArrayDirectory  TLRAH_meta;
  VMBlockHandle       TLRAH_elementVMBlock;   /* Element block or 0 */
} myTextLargeRunArrayHeader;

/* fix bad definition for display color types in win.h (win.def is right...) */
#ifndef DC_COLOR_8
  #undef DC_CF_RGB

  #define DC_COLOR_8 7
  #define DC_CF_RGB 8
#endif

#endif
