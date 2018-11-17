/**********************************************************************
 * NEWS.H - News Reader Header File                                   *
 * Project - News Reader                                              *
 * Started 4/28/98                                                    *
 **********************************************************************/

#ifndef __NEWS_H
#define __NEWS_H

#include "bucketha.h"

/**********************************************************************
 * Defines                                                            *
 **********************************************************************/

#define MAX_GROUP_NAME_SIZE		254
#define MAX_SENDER_BUFFER_SIZE	64

#define NCS_CONNECTED        0x0001
#define NCS_POSTING_ALLOWED  0x0002

typedef word ArticleEntryFlags ;
#define AEF_READ            0x0001
#define AEF_HAS_BODY_TEXT   0x0002
#define AEF_PARSED          0x0004
#define AEF_ATTACHMENTS     0x0008
#define AEF_ERROR           0x0010

#define NO_SHOW_HEADERS      0x0001

#define NO_DEFAULT_OPTIONS   NO_SHOW_HEADERS

#ifdef DO_ERROR_CHECKING
#define DEBUG
#endif

typedef WordFlags ShowToolbarOptions;
#define STO_MAIN_TOOLBAR    0x8000
#define STO_READ_TOOLBAR    0x4000
#define STO_COMPOSE_TOOLBAR 0x2000


typedef WordFlags ServerOpts;
#define SERVER_OPTS_USE_AUTH    0x0001

/**********************************************************************
 * Enums                                                              *
 **********************************************************************/

typedef enum {
  NGLV_SUBSCRIBED = 1,
  NGLV_ALL
} NewsgroupListViewType;

typedef enum {
  NGRT_CURRENT,
  NGRT_SUBSCRIBED,
  NGRT_ALL
} NewsgroupListRequestType;

/**********************************************************************
 * Structs                                                            *
 **********************************************************************/

typedef dword NewsUniqueID ;

/* Map block used in the database */
typedef struct {
    /* Huge array of unsubscribed entries */
    BucketHugeArrayHandle DMB_groupsArray;

    /* Huge array of NewsgroupEntry structures */
    BucketHugeArrayHandle DMB_subscribedArray;

    /* Version identifier (starts at 100) */
    word version ;
} DatabaseMapBlock;

typedef struct {
    char UGE_text[MAX_GROUP_NAME_SIZE+1] ;
} UnsubscribedGroupEntry ;

/* Structure defining a single newsgroup data structure */
typedef struct {
    /* Huge array to array of ThreadEntry structures */
    BucketHugeArrayHandle NE_threadArray ;

    /* Huge array of ArticleEntries sorted by AE_articleID */
    BucketHugeArrayHandle NE_articleArray ;

    /* Last unique id on server */
    dword NE_lastRead;

    /* Number of unread articles */
    word NE_unread;

    /* Keep track of the new id's for articles and threads */
    NewsUniqueID NE_nextArticleID ;
    NewsUniqueID NE_nextThreadID ;

    /* Huge array of ArticleHashEntry sorted by AHE_hashValue */
    BucketHugeArrayHandle NE_articleHashArray ;

    /* Name of article (MUST BE LAST) */
    char NE_groupName[];
} NewsgroupEntry;

/* This structure is the same as NewsgroupEntry, except it is used */
/* to determine the complete size when the group's name is maximum in */
/* length */
typedef struct {
    NewsgroupEntry NEB_header ;
    char NE_groupName[MAX_GROUP_NAME_SIZE+1];
} NewsgroupEntryBuffer ;

typedef struct {
    /* ID to uniquely declare this thread in the newsgroup */
    /* NOTE:  Must be head of structure */
    NewsUniqueID TE_threadID ;

    /* HugeArray of ArticleReference structures */
    BucketHugeArrayHandle TE_articleArray ;

    /* Number of unread articles */
    word TE_unread;
} ThreadEntry ;

typedef struct {
    /* Reference to article in Newsgroup's article list */
    NewsUniqueID AR_articleID ;
} ArticleReferenceEntry ;

typedef struct {
   /* ID to identify article uniquely.  NOTE:  Has to be first entry */
   NewsUniqueID AE_articleID ;

   /* ID to thread */
   NewsUniqueID AE_threadID ;

   /* ID used on server */
   dword AE_messageId;

   /* Hashing value used to quickly narrow down article reference searches */
   /* for determining threads */
   dword AE_hashValue ;

   /* Huge array of character lines for header */
   BucketHugeArrayHandle AE_headers;

   /* Huge array of character lines for body */
   BucketHugeArrayHandle AE_body;

   /* position extracted body text is starting for mime docs, so end of real body 
    * 0 if nothing separat is stored , or
    * line uuencoded doc us following, everything before is the message */
   dword AE_separationLine;

   /* Various flags noting the state of the article (most notibly if read) */
   ArticleEntryFlags AE_flags;

} ArticleEntry;

typedef struct {
    dword AHE_hashValue ;
    NewsUniqueID AHE_articleID ;
} ArticleHashEntry ;

/**********************************************************************
 * External Variables                                                 *
 **********************************************************************/

extern VMFileHandle G_databaseVMFH;
extern DatabaseMapBlock *G_mapBlock;
extern ArticleEntry *G_article;
extern ThreadEntry *G_thread;
extern word NewsConnectionStatus;
extern MemHandle G_articleListRespondReference;


/**********************************************************************
 * Function Prototypes                                                *
 **********************************************************************/

extern Boolean ConnectToServer(void);
extern void DisconnectFromServer(Boolean showDialog);
extern word GetGroups(void);
extern Boolean PostMessage(MemHandle groupsMH, MemHandle subjectMH, 
                        MemHandle reference, VMBlockHandle textVMH);
extern void GenerateMsgID(char *lineBuf);
extern void PrepareText(VMBlockHandle textVMH);
extern dword GetNewMessages(byte *lineBuf, word groupNum, Boolean *isCancelled);
extern Boolean GetMessageBody(
         word groupIndex,
         word threadIndex,
         word articleIndex);
extern Boolean GetMessageBodyDirectly(
        NewsgroupEntry *p_group,
        ArticleEntry *p_article,
        char *lineBuf) ;
extern void ScramblePassword(optr passwd);
extern void UnScramblePassword(optr passwd);
extern void SaveINIPassword(optr passwd);

Boolean
CheckIfConnected(void) ;

void
ForceCloseMedium(void) ;

void
CloseMedium(void) ;

void
OpenMedium(void) ;

#endif
