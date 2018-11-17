/****************************************************************************
 *
 * ==CONFIDENTIAL INFORMATION== 
 * COPYRIGHT 1994-2000 BREADBOX COMPUTER COMPANY --
 * ALL RIGHTS RESERVED  --
 * THE FOLLOWING CONFIDENTIAL INFORMATION IS BEING DISCLOSED TO YOU UNDER A
 * NON-DISCLOSURE AGREEMENT AND MAY NOT BE DISCLOSED OR FORWARDED BY THE
 * RECIPIENT TO ANY OTHER PERSON OR ENTITY NOT COVERED BY THE SAME
 * NON-DISCLOSURE AGREEMENT COVERING THE RECIPIENT. USE OF THE FOLLOWING
 * CONFIDENTIAL INFORMATION IS RESTRICTED TO THE TERMS OF THE NON-DISCLOSURE
 * AGREEMENT.
 *
 * Project: Word For Windows Core Library
 * File:    list.c
 *
 ***************************************************************************/

#include <geos.h>
#include <heap.h>
#include <lmem.h>
#include <chunkarr.h>
#include <ec.h>
#include <Ansi/string.h>
#include <system.h>
#include <char.h>
#include "global.h"
#include "structs.h"
#include "global.h"
#include "sprm.h"
#include "warnings.h"
#include "wfwinput.h"
#include "charset.h"
#include "rtfdefs.h"
#include "debug.h"

#pragma warn -pia

static Boolean _Read(StgStream s, void *p, word c)
{
    if (StgStreamRead(s,p,c) == c)
	return TRUE;
    else
	return SetErrorStg(StgStreamGetLastError(s));
}

static Boolean _Seek(StgStream s, dword o, StgPosMode m)
{
    StgError error;
    if ((error = StgStreamSeek(s,o,m)) != STGERR_NONE)
	return TRUE;
    else
	return SetErrorStg(error);
}    

#define SEEK(s,o,m) (retval = _Seek(s,o,m))
/* Seek relative (from cur pos) */
#define SEEKR(s,o) SEEK(s,o,STG_POS_RELATIVE)
/* Seek absolute (from start) */
#define SEEKA(s,o) SEEK(s,o,STG_POS_START)
#define READ(s,p,c) (retval = _Read(s,p,c))
/* Read a variable */
#define READV(s,v) READ(s,&v,sizeof(v))

#define SEEKT(o,m) SEEK(hInputTableStream,o,m)
#define SEEKRT(o) SEEKR(hInputTableStream,o)
#define SEEKAT(o) SEEKA(hInputTableStream,o)
#define READT(p,c) READ(hInputTableStream,p,c)
#define READVT(v) READV(hInputTableStream,v)
#define POSAT() StgStreamPos(hInputTableStream);

#define NIL_LVL ( LIST_MAX_LVL_COUNT )
#define LVL_CHPX(p) ( (byte *)((p) + 1) )
#define LVL_PAPX(p) ( (byte *)((p) + 1) + (p)->CLE_lvlf.cbGrpprlChpx )
#define LVL_XCH(p) ( (XCHAR *)((byte *)((p) + 1) \
  + (p)->CLE_lvlf.cbGrpprlChpx + (p)->CLE_lvlf.cbGrpprlPapx) )

MemHandle hLists = NullHandle;
ChunkHandle cListLFO = NullChunk;
ChunkHandle cListLST = NullChunk;
optr oListCurList = NullOptr;
short ListCurIlfo = 0;
uchar ListCurIlvl = NIL_LVL;
long ListCurNum[LIST_MAX_LVL_COUNT];

typedef struct {
    long    LFOE_lfoLsid;           // List ID of corresp. LSTF
    uchar   LFOE_lfoClfolvl;        // Count of LFOLVLs
    FC      LFOE_fcLfolvl[LIST_MAX_LVL_COUNT];  // FCs of each LFOLVL
} LFOElement;

#define LFO_BASE_SIZE   ( sizeof(long) + sizeof(uchar) )

typedef struct {
    FC      LSTV_fc;                // FCs of the LVL
    long    LSTV_num;               // Current number for the LVL
} LSTVar;

typedef struct {
    long    LSTE_lstfLsid;          // Unique List ID
    uchar   LSTE_clvl;              // Count of LVLs
    uchar   LSTE_curlvl;            // Current level
    LSTVar  LSTE_lvl[LIST_MAX_LVL_COUNT];
} LSTElement;

#define LST_BASE_SIZE   ( offsetof(LSTElement, LSTE_lvl) )
#define LST_VAR_SIZE    ( sizeof(LSTVar) )

typedef struct {
    ChunkArrayHeader CLH_meta;
    long    CLH_lsid;               // Unique List ID
    uchar   CLH_clvl;               // Count of levels
    uchar   CLH_clfolvl;            // Count of LFOLVLs
    LFOLVL  CLH_lfolvl[LIST_MAX_LVL_COUNT];
} CurListHeader;

typedef struct {
//  long    CLE_num;
    LVLF    CLE_lvlf;
} CurListElement;

static Boolean ListSkipLVL(long *pNum)
{
    Boolean retval = TRUE;
    byte cbGC, cbGP;
    word cxch;

    if (((pNum) ? READVT(*pNum) : SEEKRT(sizeof(long)))
      && SEEKRT(offsetof(LVLF, cbGrpprlChpx) - sizeof(long))
      && READVT(cbGC)
      && READVT(cbGP)
      && SEEKRT(sizeof(LVLF) - offsetof(LVLF, wRsv26)
        + cbGC + cbGP)
      && READVT(cxch))
        SEEKRT(cxch * sizeof(XCHAR));

    return retval;
}

Boolean ListRead(FIBFCLCB plcfLst, FIBFCLCB plfLfo)
{
    Boolean retval = TRUE;
    int i, j;
    word cb;

    /* Clear important globals. */
    oListCurList = NullHandle;

    // Create the lmem heap for the two chunk arrays
    hLists = MemAllocLMem(LMEM_TYPE_GENERAL, sizeof(LMemBlockHeader));
    if (hLists == NullHandle)
    {
        SetError(TE_OUT_OF_MEMORY);
        return FALSE;
    }

    MemLock(hLists);

    // Create the LST array
    cListLST = ChunkArrayCreate(hLists, 0, 0, 0);

    if (plcfLst.lcb)
    {
        LSTElement *plst;
        short clst;
        
        // Get the number of LST elements
        SEEKAT(plcfLst.fc);
        READVT(clst);
        if (clst > (64000 / sizeof(LSTElement)))
        {
            EC_WARNING(WFW_WARNING_PLCFLST_TOO_LARGE);
            SetError(TE_OUT_OF_MEMORY);
            retval = FALSE;
        }

        // Read each LST from the plcflst
        for (i = 0; retval && i < clst; i++)
        {
            LSTF lstf;
            uchar clvl;

            // Read the base LSTF struct
            if (!READVT(lstf))
                break;

            // Append the LST element and fill in the basics
            clvl = (lstf.fSimpleList) ? LSTF_SIMPLE_LVL_COUNT
              : LSTF_COMPLEX_LVL_COUNT;
            plst = ChunkArrayAppendHandles(hLists, cListLST,
              LST_BASE_SIZE + LST_VAR_SIZE * clvl);
            plst->LSTE_lstfLsid = lstf.lsid;
            plst->LSTE_clvl = clvl;
            plst->LSTE_curlvl = NIL_LVL;
        }

        // Get the positions of each LVL
        for (i = 0; retval && i < clst; i++)
        {
            plst = ChunkArrayElementToPtrHandles(hLists, cListLST, i, &cb);
            for (j = 0; retval && j < plst->LSTE_clvl; j++)
            {
                // Store the starting position
                plst->LSTE_lvl[j].LSTV_fc = POSAT();
                
                // Skip the following LVL struct
                retval = ListSkipLVL(&plst->LSTE_lvl[j].LSTV_num);
            }
        }
    }

    // Create the LFO array
    cListLFO = ChunkArrayCreate(hLists, 0, 0, 0);

    if (plfLfo.lcb)
    {
        LFOElement *plfo;
        long clfo;

        // Get the number of LFO elements
        SEEKAT(plfLfo.fc);
        READVT(clfo);
        if (clfo > (64000 / sizeof(LFOElement)))
        {
            EC_WARNING(WFW_WARNING_PLFLFO_TOO_LARGE);
            SetError(TE_OUT_OF_MEMORY);
            retval = FALSE;
        }

        // Read each LFO from the plflfo
        for (i = 0; retval && i < clfo; i++)
        {
            LFO lfo;

            // Read the base LFO struct
            if (!READVT(lfo))
                break;

            // Append the LFO element and fill in the basics
            plfo = ChunkArrayAppendHandles(hLists, cListLFO,
              LFO_BASE_SIZE + sizeof(FC) * lfo.clfolvl);
            plfo->LFOE_lfoLsid = lfo.lsid;
            plfo->LFOE_lfoClfolvl = lfo.clfolvl;
        }

        // Get the positions of each LFOLVL
        for (i = 0; retval && i < clfo; i++)
        {
            dword sep;
            
            // Skip the 4-byte separator before each LFOLVL group
            if (!READVT(sep) || sep != 0xFFFFFFFF)
            {
                EC_WARNING(WFW_wARNING_PLFLFO_INVALID);
                retval = FALSE;
            }
            else
            {
                plfo = ChunkArrayElementToPtrHandles(hLists, cListLFO, i, &cb);
                for (j = 0; retval && j < plfo->LFOE_lfoClfolvl; j++)
                {
                    LFOLVL lfolvl;

                    // Store the starting position
                    plfo->LFOE_fcLfolvl[j] = POSAT();
                
                    // Read the base LFOLVL struct
                    if (!READVT(lfolvl))
                        break;

                    if (lfolvl.fFormatting)
                    {
                        // Skip the following LVL struct
                        retval = ListSkipLVL(NULL);
                    }
                }
            }
        }
    }
    MemUnlock(hLists);
    return retval;
}

static LSTElement *ListFindLST(long lsid)
{
    // NOTE: hLists MUST be locked!

    LSTElement *plst;
    int i, count;
    word dummy;

    count = ChunkArrayGetCountHandles(hLists, cListLST);
    for (i = 0; i < count; i++)
    {
        plst = ChunkArrayElementToPtrHandles(hLists, cListLST, i, &dummy);
        if (plst->LSTE_lstfLsid == lsid)
            return plst;
    }

    return NULL;
}

static uchar ListFindLFOLVL(CurListHeader *clh, uchar ilvl)
{
    int i;
    
    for (i = 0; i < clh->CLH_clfolvl; i++)
    {
        if (ilvl == clh->CLH_lfolvl[i].ilvl)
            return i;
    }
    return NIL_LVL;
}

static void ListUnload(void)
{
    CurListHeader *clh;
    LSTElement *plst;
    int i, count;

    if (oListCurList == NullOptr)
        return;

    MemLock(hLists);
    MemLock(OptrToHandle(oListCurList));
    clh = LMemDeref(oListCurList);
    count = ChunkArrayGetCount(oListCurList);

    // Copy the current status back into the LST array.
    if ((plst = ListFindLST(clh->CLH_lsid)) != NULL)
    {
        plst->LSTE_curlvl = ListCurIlvl;
        for (i = 0; i < count; i++)
            plst->LSTE_lvl[i].LSTV_num = ListCurNum[i];
    }

    MemUnlock(OptrToHandle(oListCurList));
    MemFree(OptrToHandle(oListCurList));
    MemUnlock(hLists);

    oListCurList = NullOptr;
}

void ListFree(void)
{
    /* Unload the current list if there is one. */
    ListUnload();

    /* Free the list arrays. */
    if (hLists) {
	MemFree(hLists);
	hLists = NullHandle;
    }
}     

static Boolean ListLoad(short ilfo)
{
    Boolean retval = TRUE;
    MemHandle mh;
    word dummy;
    int i;
    CurListHeader *clh;
    LFOElement *plfo;
    LSTElement *plst;
    StgStream hStream;

    // Return immediately if LFO index is zero
    if (ilfo == 0)
        return TRUE;

    // Unload the old list
    ListUnload();

    hStream = StgStreamClone(hInputTableStream);
    if (hStream == NullHandle)
    {
        SetError(TE_OUT_OF_MEMORY);
        return FALSE;
    }

    // Create the lmem heap for the new list
    mh = MemAllocLMem(LMEM_TYPE_GENERAL, sizeof(LMemBlockHeader));
    if (mh == NullHandle)
    {
        SetError(TE_OUT_OF_MEMORY);
        return FALSE;
    }
    MemLock(mh);

    // Create the list array
    oListCurList = ConstructOptr(mh,
      ChunkArrayCreate(mh, 0, sizeof(CurListHeader), 0));
    clh = LMemDeref(oListCurList);
    
    MemLock(hLists);

    // Get the LFO
    if (ilfo > ChunkArrayGetCountHandles(hLists, cListLFO))
    {
        EC_WARNING(WFW_WARNING_INVALID_ILFO);
        retval = FALSE;
    }
    if (retval)
    {
        plfo = ChunkArrayElementToPtrHandles(hLists, cListLFO, ilfo - 1, &dummy);
        clh->CLH_clfolvl = plfo->LFOE_lfoClfolvl;
#ifdef DEBUG
        printf("LFO #%d:\n", ilfo);
        printf(" LFOE_lfoLsid = %ld\n", plfo->LFOE_lfoLsid);
        printf(" LFOE_lfoClfolvl = %d\n", plfo->LFOE_lfoClfolvl);
#endif
        // Search for the LST by lsid
        if ((plst = ListFindLST(plfo->LFOE_lfoLsid)) == NULL)
        {
            EC_WARNING(WFW_WARNING_LFO_REFERENCES_UNKNOWN_LSID);
            retval = FALSE;
        }
        else
        {
            clh->CLH_clvl = plst->LSTE_clvl;
            clh->CLH_lsid = plst->LSTE_lstfLsid;
            ListCurIlvl = plst->LSTE_curlvl;
        }

        // Read each LFOLVL
        for (i = 0; retval && i < clh->CLH_clfolvl; i++)
        {
            if (SEEKA(hStream, plfo->LFOE_fcLfolvl[i])
              && READV(hStream, clh->CLH_lfolvl[i]))
            {
                if (clh->CLH_lfolvl[i].ilvl > LIST_MAX_LVL_COUNT)
                {
                    EC_WARNING(WFW_WARNING_INVALID_LFOLVL_ILVL);
                    retval = FALSE;
                }
            }
#ifdef DEBUG
            printf("   LFOLVL #%d (overrides level %d):\n", i, clh->CLH_lfolvl[i].ilvl);
            printf("    iStartAt = %ld\n", clh->CLH_lfolvl[i].iStartAt);
            printf("    fStartAt = %d\n", clh->CLH_lfolvl[i].fStartAt);
            printf("    fFormatting = %d\n", clh->CLH_lfolvl[i].fFormatting);
#endif
        }
    }
    if (retval)
    {
        LVLF lvlf;
        CurListElement *plvl;
        XCHAR cxch;
        uchar clvl;

        clvl = clh->CLH_clvl;
        for (i = 0; retval && i < clvl; i++)
        {
            uchar ilfolvl = ListFindLFOLVL(clh, i);
            long num = plst->LSTE_lvl[i].LSTV_num;

            // Determine which LVL to read
            // If LFOLVL.fFormatting, read the LFOLVL LVL
            if (ilfolvl != NIL_LVL && clh->CLH_lfolvl[ilfolvl].fFormatting)
                SEEKA(hStream, plfo->LFOE_fcLfolvl[ilfolvl] + sizeof(LFOLVL));
            // Otherwise, read the LST LVL
            else
                SEEKA(hStream, plst->LSTE_lvl[i].LSTV_fc);
            if (retval && READV(hStream, lvlf))
            {
                word len = sizeof(CurListElement)
                  + lvlf.cbGrpprlChpx + lvlf.cbGrpprlPapx;
#ifdef DEBUG
                printf("LVL #%d:", i);
                printf(" iStartAt = %ld", lvlf.iStartAt);
                printf(" nfc = %d", lvlf.nfc);
                printf(" jc = %d", lvlf.jc);
                printf(" fLegal = %d", lvlf.fLegal);
                printf(" fNoRestart = %d", lvlf.fNoRestart);
                printf(" ixchFollow = %d", lvlf.ixchFollow);
                printf(" fWord6 = %d\n", lvlf.fWord6);
                if (lvlf.fWord6)
                {
                    printf(" fPrev = %d", lvlf.fPrev);
                    printf(" fPrevSpace = %d", lvlf.fPrevSpace);
                    printf(" dxaSpace = %ld", lvlf.dxaSpace);
                    printf(" dxaIndent = %ld\n", lvlf.dxaIndent);
                }
#endif
                plvl = ChunkArrayAppend(oListCurList, len);
                memcpy(&plvl->CLE_lvlf, &lvlf, sizeof(lvlf));
                if (READ(hStream, LVL_PAPX(plvl), lvlf.cbGrpprlPapx)
                  && READ(hStream, LVL_CHPX(plvl), lvlf.cbGrpprlChpx)
                  && READV(hStream, cxch))
                {
#ifdef DEBUG
                    if (lvlf.cbGrpprlChpx)
                    {
                        printf(" CHPX: ");
                        dump(LVL_CHPX(plvl), lvlf.cbGrpprlChpx);
                    }
                    if (lvlf.cbGrpprlPapx)
                    {
                        printf(" PAPX: ");
                        dump(LVL_PAPX(plvl), lvlf.cbGrpprlPapx);
                    }
#endif
                    len += (cxch + 1) * sizeof(XCHAR);
                    ChunkArrayElementResize(oListCurList, i, len);
                    plvl = ChunkArrayElementToPtr(oListCurList, i, &dummy);
                    LVL_XCH(plvl)[0] = cxch;
#ifdef DEBUG
                    printf(" Text (pos %lx): ", StgStreamPos(hStream));
#endif
                    READ(hStream, LVL_XCH(plvl) + 1, cxch * sizeof(XCHAR));
#ifdef DEBUG
                    for (dummy = 0; dummy < cxch; dummy++)
                    {
                        unsigned char c = (unsigned char)(LVL_XCH(plvl)[dummy + 1]);
                        if (c < LIST_MAX_LVL_COUNT && lvlf.nfc != nfcBullet && lvlf.nfc != nfcNone)
                            printf("{%d}", c);
                        else if (c >= 32 && c <= 127)
                            printf("%c", c);
                        else
                            printf("\\%02x", c);
                    }
                    printf("\n");
#endif
                }
            }
            if (retval)
            {
                clh = LMemDeref(oListCurList);

                // Get the starting level number
                if (ilfolvl != NIL_LVL && clh->CLH_lfolvl[ilfolvl].fStartAt)
                {
                    // Reset the current level.
                    if (i == ListCurIlvl)
                        ListCurIlvl = NIL_LVL;
                    
                    // If both are set, number comes from attached LVL.
                    // If just fStartAt, number comes from LFOLVL.
                    if (!clh->CLH_lfolvl[ilfolvl].fFormatting)
                        plvl->CLE_lvlf.iStartAt = clh->CLH_lfolvl[ilfolvl].iStartAt;
                    num = plvl->CLE_lvlf.iStartAt;
                }

                // Get the current level number
                ListCurNum[i] = num;
            }
        }
    }

#ifdef DEBUG
    printf("\n");
#endif
    StgStreamClose(hStream);
    MemUnlock(hLists);
    MemUnlock(mh);
    return retval;
}

static void ListATArabic(long num, Boolean bZero)
{
    char buffer[UHTA_NULL_TERM_BUFFER_SIZE], *pc;

    if (bZero && num < 10)
        TextBufferAddChar('0');
    UtilHex32ToAscii(buffer, num, UHTAF_NULL_TERMINATE);
    for (pc = buffer; *pc != '\0'; pc++)
        TextBufferAddChar(*pc);
}

static void ListATRSub(int num, char *pc)
{
    static const byte pre[9] =  { 1, 2, 3, 1, 0, 0, 0, 0, 1 };
    static const byte post[9] = { 0, 0, 0, 1, 1, 2, 3, 4, 0 };
    int i;
    char c;

    i = pre[num - 1];
    c = pc[2];
    while (i --)
        TextBufferAddChar(c);

    i = post[num - 1];
    if (i --)
    {
        TextBufferAddChar(pc[1]);
        while (i --)
            TextBufferAddChar(c);
    }
    if (num == 9)
        TextBufferAddChar(pc[0]);
}

static void ListATRoman(long num, Boolean bUpper)
{
    /* M = 1000, D = 500, C = 100, L = 50, X = 10, V = 5, I = 1 */
    static const char uchars[] = "MDCLXVI";
    static const char lchars[] = "mdclxvi";
    const char *pc = (bUpper) ? uchars : lchars;
    long thousands;
    int hundreds, tens, ones;

    thousands = num / 1000;
    num %= 1000;
    hundreds = (int)(num / 100);
    num %= 100;
    tens = (int)(num / 10);
    ones = (int)(num % 10);
    
    while (thousands --)
        TextBufferAddChar(pc[0]);
    if (hundreds)
        ListATRSub(hundreds, &pc[0]);
    if (tens)
        ListATRSub(tens, &pc[2]);
    if (ones)
        ListATRSub(ones, &pc[4]);
}

static void ListATLetter(long num, Boolean bUpper)
{
    int rep = ((num - 1) / 26) + 1;
    char c = ((bUpper) ? 'A' : 'a') + ((num - 1) % 26);

    while (rep --)
        TextBufferAddChar(c);
}

static void ListATOrdinalPost(long num)
{
    static const char posts[][3] = { "st", "nd", "rd" };
    int tens, ones;

    num %= 100;
    tens = num / 10;
    ones = num % 10;

    if (tens != 1 && (ones > 0 && ones < 4))
        TextBufferAddString(posts[ones - 1]);
    else
        TextBufferAddString("th");
}

static void ListATONWSub(char *buffer, int num, Boolean bTh)
{
    static const char *sOnes[] = { "one", "two", "three", "four",
        "five", "six", "seven", "eight", "nine" };
    static const char *sFirsts[] = { "first", "second", "third", "fourth",
        "fifth", "sixth", "seventh", "eighth", "ninth" };
    static const char *sTeens[] = { "eleven", "twelve", "thirteen",
        "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen" };
    static const char *sTeenths[] = { "eleventh", "twelfth", "thirteenth",
        "fourteenth", "fifteenth", "sixteenth", "seventeenth", "eighteenth",
        "nineteenth" };
    static const char *sTens[] = { "ten", "twenty", "thirty", "forty",
        "fifty", "sixty", "seventy", "eighty", "ninety" };
    static const char *sTenths[] = { "tenth", "twentieth", "thirtieth",
        "fortieth", "fiftieth", "sixtieth", "seventieth", "eighteith",
        "ninetieth" };

    int tens = num / 10, ones = num % 10;

    if (num > 10 && num < 20)
    {
        if (bTh)
            strcat(buffer, sTeenths[num - 11]);
        else
            strcat(buffer, sTeens[num - 11]);
    }
    else
    {
        if (bTh)
        {
            if (!ones)  /* && tens */
                strcat(buffer, sTenths[tens - 1]);
            else    /* if (ones) */
            {
                if (tens)
                {
                    strcat(buffer, sTens[tens - 1]);
                    strcat(buffer, "-");
                }
                strcat(buffer, sFirsts[ones - 1]);
            }
        }
        else
        {
            if (tens)
                strcat(buffer, sTens[tens - 1]);
            if (tens && ones)
                strcat(buffer, "-");
            if (ones)
                strcat(buffer, sOnes[ones - 1]);
        }
    }
    strcat(buffer, " ");
}

static void ListATOrdinalNumWord(long num, Boolean bTh)
{
    long thousands;
    int hundreds, teens;
    char buffer[100];

    thousands = num / 1000;
    num %= 1000;
    hundreds = (int)(num / 100);
    teens = (int)(num % 100);

    if (thousands >= 100)
        return;

    buffer[0] = '\0';
    if (thousands)
    {
        ListATONWSub(buffer, thousands, FALSE);
        if (bTh && !(hundreds || teens))
            strcat(buffer, "thousandth ");
        else
            strcat(buffer, "thousand ");
    }
    if (hundreds)
    {
        ListATONWSub(buffer, hundreds, FALSE);
        if (bTh && (!teens))
            strcat(buffer, "hundredth ");
        else
            strcat(buffer, "hundred ");
    }
    if (teens)
        ListATONWSub(buffer, teens, bTh);

    if (buffer[0] != '\0')
    {
        buffer[0] = toupper((uchar)buffer[0]);
        *(strrchr(buffer, ' ')) = '\0';
        TextBufferAddString(buffer);
    }
}

static void ListAppendText(CurListElement *cle)
{
    int i, count;
    XCHAR *pxch;

    if (cle->CLE_lvlf.nfc == nfcNone)
        return;

    pxch = LVL_XCH(cle);
    count = *(pxch++);

    // Emit the autonumber string.
    for (i = 1; i <= count; i++, pxch++)
    {
        if (*pxch < LIST_MAX_LVL_COUNT && cle->CLE_lvlf.nfc != nfcBullet)
        {
            // This is a number for a particular level.
            word dummy;
            CurListElement *plvl = ChunkArrayElementToPtr(
              oListCurList, *pxch, &dummy);
            byte nfc = plvl->CLE_lvlf.nfc;
            long num = ListCurNum[*pxch];

            if (num <= 0)
                num = 1;

            // Convert number to the specified format.
            if (cle->CLE_lvlf.fLegal && nfc <= nfcOrdtext)
                nfc = nfcArabic;
            switch (nfc)
            {
            case nfcArabic:     /* Arabic numbering (1, 2, 3...) */
            default:
                ListATArabic(num, FALSE); break;
            case nfcUCRoman:    /* Upper case Roman (I, II, III...) */
                ListATRoman(num, TRUE); break;
            case nfcLCRoman:    /* Lower case Roman (i, ii, iii...) */
                ListATRoman(num, FALSE); break;
            case nfcUCLetter:   /* Upper case Letter (A, B, C...) */
                ListATLetter(num, TRUE); break;
            case nfcLCLetter:   /* Lower case Letter (a, b, c...) */
                ListATLetter(num, FALSE); break;
            case nfcOrdinal:    /* Ordinal (1st, 2nd, 3rd...) */
                ListATArabic(num, FALSE);
                ListATOrdinalPost(num); break;
            case nfcCardtext:   /* Cardinal text (One, Two, Three...) */
                ListATOrdinalNumWord(num, FALSE); break;
            case nfcOrdtext:    /* Ordinal text (First, Second, Third...) */
                ListATOrdinalNumWord(num, TRUE); break;
            case nfcArabicLZ:   /* Arabic numbering w/ leading zero (01, 02, 03...) */
                ListATArabic(num, TRUE); break;
            }
        }
        else
            TextBufferAddChar(WFWCodePageToGeos(*pxch));
    }
}

Boolean ListCheckAndLoad(short ilfo)
{
    if (ilfo != ListCurIlfo)
    {
        if (!ListLoad(ilfo))
            return FALSE;
        ListCurIlfo = ilfo;
    }
    return TRUE;
}

/* The paragraph properties of a list are determined as follows:
 * 1. The PAPX of the list is applied while reading the paragraph's FKP PAPX;
 *    the list defaults are contained therein.
 * 2. The remainder of the FKP PAPX may override the list defaults if the
 *    left margin, first line indent, or tabs are different.
 * 3. The PCD PRM may have further adjustments made before the last full save.
 */

Boolean ListApplyPapx(PAP *pap)
{
    Boolean retval = TRUE;
    CurListElement *plvl;
    word dummy;
    
    // Return immediately if ilfo is zero
    if (pap->ilfo == 0)
        return TRUE;

    // Load the LFO at ilfo if necessary
    if (!ListCheckAndLoad(pap->ilfo))
        return FALSE;
        
    MemLock(OptrToHandle(oListCurList));
    plvl = ChunkArrayElementToPtr(oListCurList, pap->ilvl, &dummy);

    if (!plvl->CLE_lvlf.fWord6)
    {
        // Apply the paragraph exception grpprl.
        retval = SprmReadGrpprlMem(LVL_PAPX(plvl), plvl->CLE_lvlf.cbGrpprlPapx,
          pap, SGC_PAP);
    }
    else
    {
        // Apply the Word 6 compatibility options.
        pap->dxaLeft += plvl->CLE_lvlf.dxaIndent;
        pap->dxaLeft1 += -plvl->CLE_lvlf.dxaIndent;
    }

    MemUnlock(OptrToHandle(oListCurList));
    return retval;
}

/*
 * The character properties of any autolist text are determined as follows:
 * 1. The CHPX of the paragraph mark is first acquired.
 * 2. The PCD PRM may have further adjustments made before the last full save.
 * 3. The CHPX of the list is then applied, perhaps overriding some properties.
 *
 * This routine assumes that ListApplyPapx has already loaded the list.
 */
Boolean ListApplyChpx(short ilfo, ushort ilvl, CHP *chp)
{
    Boolean retval = TRUE;
    CurListElement *plvl;
    word dummy;
    
    // Return immediately if ilfo is zero
    if (ilfo == 0)
        return TRUE;

    // Load the LFO at ilfo if necessary
    if (!ListCheckAndLoad(ilfo))
        return FALSE;

    MemLock(OptrToHandle(oListCurList));
    plvl = ChunkArrayElementToPtr(oListCurList, ilvl, &dummy);

    // Apply the character exception grpprl.
    retval = SprmReadGrpprlMem(LVL_CHPX(plvl), plvl->CLE_lvlf.cbGrpprlChpx,
      chp, SGC_CHP);

    MemUnlock(OptrToHandle(oListCurList));
    return retval;
}

Boolean ListInsertText(ushort ilvl, char *cSpace)
{
    Boolean retval = TRUE;
    CurListElement *plvl;
    int i;
    word dummy;
    
    // Get the LFO
    MemLock(OptrToHandle(oListCurList));

    // When the level is decreased, levels from the old level to the one 
    // above the new level are flagged for reset to their start values.
    if (ilvl <= ListCurIlvl && ListCurIlvl != NIL_LVL)
    {
        for (i = ListCurIlvl; i > ilvl; i--)
        {
            plvl = ChunkArrayElementToPtr(oListCurList, i, &dummy);
            if (!plvl->CLE_lvlf.fNoRestart)
            {
                ListCurNum[i] = plvl->CLE_lvlf.iStartAt;
#ifdef DEBUG
                printf("[Reset level %d to %ld]\n", i, ListCurNum[i]);
#endif
            }
        }

        // When the level is decreased or remains the same, the value of
        // the new level is increased.
        ListCurNum[ilvl]++;
#ifdef DEBUG
        printf("[Incremented level %d to %ld]\n", ilvl, ListCurNum[ilvl]);
#endif
    }
    ListCurIlvl = ilvl;
    plvl = ChunkArrayElementToPtr(oListCurList, ilvl, &dummy);

    // Append the number text.
    if (retval)
        ListAppendText(plvl);

    // Set the followup character.
    switch (plvl->CLE_lvlf.ixchFollow)
    {
        case 0: *cSpace = C_TAB; break;
        case 1: *cSpace = C_SPACE; break;
        case 2:
        default: *cSpace = C_NULL; break;
    }

    MemUnlock(OptrToHandle(oListCurList));
    return retval;
}
