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
 * File:    WFWINPUT.C
 *
 ***************************************************************************/

#include <geos.h>
#include <heap.h>
#include <resource.h>
#include <ec.h>
#include <char.h>
#include <sstor.h>
#include <Ansi/string.h>
#include "wfwinput.h"
#include "warnings.h"
#include "global.h"
#include "charset.h"
#include "structs.h"
#include "sprm.h"
#include "text.h"
#include "style.h"
#include "list.h"
#include "wfwfont.h"
#include "debug.h"

static Boolean _Read(StgStream s, void *p, word c)
{
    if (StgStreamRead(s,p,c) == c)
	return FALSE;
    else
	return !SetErrorStg(StgStreamGetLastError(s));
}

static Boolean _Seek(StgStream s, dword o, StgPosMode m)
{
    StgError error;
    if ((error = StgStreamSeek(s,o,m)) != STGERR_NONE)
	return FALSE;
    else
	return !SetErrorStg(error);
}

#define SEEK(s,o,m) if (_Seek(s,o,m)) return FALSE
/* Seek relative (from cur pos) */
#define SEEKR(s,o) SEEK(s,o,STG_POS_RELATIVE)
/* Seek absolute (from start) */
#define SEEKA(s,o) SEEK(s,o,STG_POS_START)
#define READ(s,p,c) if (_Read(s,p,c)) return FALSE
/* Read a variable */
#define READV(s,v) READ(s,&v,sizeof(v))

#define PRM_HANDLE_USE_CUR_PRM  0xFFFF

typedef struct {
    StgStream   hStream;    /* handle of stream for access */
    FC          fcStart;    /* starting pos of PLCF in stream */
    word        cbStruct;   /* byte length of stored structure */
    dword       iMac;       /* number of structure instances */
    sdword      iLast;      /* index of last FC read */
} PLCF;

#define INPUT_BUFFER_SIZE   512

byte acInputBuf[INPUT_BUFFER_SIZE];
word nInputBufLen, nInputBufPos;
FIBFCLCB sInputClx;
PLCF sInputPlcfpcd;
MemHandle hInputClxtGrpprl;
PRM sInputCurPcdPrm;
FIBFCLCB sInputPlcfsed;
CP cpInputSepxEnd;

CP cpInputTextPcdStart;
FC fcInputTextPcdStart;
CP cpInputTextPcdEnd;
FC fcInputTextPcdEnd;
CP cpInputTextEnd;
CP cpInputTextPos;
FC fcInputTextPos;
Boolean bInputTextIsUnicode;
Boolean bInputNewPcd;
DosCodePage InputCodePage;

//CP cpInputChpxStart;
FC fcInputChpxStart;
FC fcInputChpxEnd;
FC fcInputChpxFkpStart;
FC fcInputChpxFkpEnd;
PN pnInputChpPos;
PLCF sInputPlcfbteChpx;
PLCF sInputChpxFkp;
CHP sInputChp;
byte bInputChpxOff;
Boolean bInputRedoChp;
Boolean bInputNewChp;

CP cpInputPapxStart;
FC fcInputPapxStart;
FC fcInputPapxEnd;
FC fcInputPapxFkpStart;
FC fcInputPapxFkpEnd;
PN pnInputPapPos;
PLCF sInputPlcfbtePapx;
PLCF sInputPapxFkp;
PAP sInputPap;
Boolean bInputNewPap;
FC fcInputParaMark;
MemHandle hInputParaPrm;
Boolean bInputParaList;

word wInputDefaultTab;

#ifdef DEBUG_P
StgStream hInputTestStream;
#endif

#ifdef ERROR_CHECK
Warnings toot;
#endif

extern void InputFreePrm(MemHandle *pph);


void PLCFInit(PLCF *plcf, StgStream hStream, FC fcStart, dword lcb,
    word cbStruct)
{
    plcf->hStream = hStream;
    plcf->fcStart = fcStart;
    plcf->cbStruct = cbStruct;
    plcf->iMac = (lcb - sizeof(FC)) / (sizeof(FC) + cbStruct);
}

Boolean PLCFGetFirst(PLCF *plcf, FC *pFCStart)
{
    SEEKA(plcf->hStream, plcf->fcStart);
    READV(plcf->hStream, *pFCStart);
    plcf->iLast = 0;
    return TRUE;
}

Boolean PLCFRead(PLCF *plcf, void *pStruct)
{
    SEEKA(plcf->hStream, plcf->fcStart + (plcf->iMac + 1) * sizeof(FC) +
      (plcf->iLast - 1) * plcf->cbStruct);
    READ(plcf->hStream, pStruct, plcf->cbStruct);
    return TRUE;
}

Boolean PLCFGetNext(PLCF *plcf, FC *pFC, void *pStruct)
{
    if (++ plcf->iLast > plcf->iMac)
        *pFC = EOF;
    else
    {
        SEEKA(plcf->hStream, plcf->fcStart + plcf->iLast * sizeof(FC));
        READV(plcf->hStream, *pFC);
        if (pStruct != NULL)
            return PLCFRead(plcf, pStruct);
    }
    return TRUE;
}

Boolean PLCFEOF(PLCF *plcf)
{
    return (plcf->iLast >= plcf->iMac);
}

CHP *InputGetChp(void)
{
    return &sInputChp;
}

PAP *InputGetPap(void)
{
    return &sInputPap;
}

Boolean InputSeekClx(byte clxt, word idx)
{
    byte clxtRead;
    long lcbInClx = 0;

    /* Skip past any grpprls to the plcfpcd. */
    SEEKA(hInputTableStream, sInputClx.fc);
    while (lcbInClx < sInputClx.lcb)
    {
        READV(hInputTableStream, clxtRead);
        lcbInClx += sizeof(clxtRead);

        /* Did we find it? */
        if (clxt == clxtRead)
        {
            if (!(clxt == clxtGrpprl && idx != 0))
                // The item was found!
                return TRUE;
        }
        /* Nope, skip this block. */
        if (clxtRead == clxtGrpprl)
        {
            word cb;
            READV(hInputTableStream, cb);
            SEEKR(hInputTableStream, cb);
            lcbInClx += sizeof(cb) + cb;
            idx --;
        }
        else
        {
            // We hit the piece table; didn't find the indexed item.
            SetError(TE_IMPORT_ERROR);
            return FALSE;
        }
    }

    // If we have reached this point, the CLX is short!
    EC_WARNING(WFW_WARNING_CLX_ENDED_EARLY);
    SetError(TE_IMPORT_ERROR);
    return FALSE;
}

void InputSetCodePage(Boolean bUnicode)
{
    /* Initially, we're set to read non-Unicode text with the default codepage. */
    static Boolean bISCPUnicode = FALSE;
    static DosCodePage ISCPCodePage = DEFAULT_CODEPAGE;
    DosCodePage targetCP;

    /* When the reader wants to switch to/form Unicode text mode, or has changed the
       codepage, we must take action. */
    if (bUnicode != bISCPUnicode || InputCodePage != ISCPCodePage)
    {
        if (InputCodePage == CP_NIL)
            targetCP = CP_NIL;
        else
        {
            if (bUnicode)
                targetCP = CP_UNICODE;
            else
                targetCP = InputCodePage;
        }
        WFWSetCodePage(targetCP);
        ISCPCodePage = InputCodePage;
        bISCPUnicode = bUnicode;
    }
}

Boolean InputInit(FileHandle fh)
{
    FIB_FIBH fib;
    ushort csw, clw;
    FIBFCLCB plcfbteChpx, plcfbtePapx, stshf, plcfLst, plfLfo, sttbfffn;
    StgError error = STGERR_NONE;
    
    hInputFile = fh;
    nInputBufPos = INPUT_BUFFER_SIZE;
    nInputBufLen = 0;
    //RTFReportStatus(nInputFileSize, nInputFilePos);
    hInputClxtGrpprl = hInputParaPrm = NullHandle;
    hInputStyle = 0;
    bInputChpxOff = 0;
    bInputNewPcd = bInputRedoChp = bInputNewPap = bInputNewChp = TRUE;
    bInputParaList = FALSE;
    cpInputPapxStart = /*cpInputChpxStart = */0;
    cpInputTextPos = fcInputTextPcdStart = 0;
    fcInputPapxFkpStart = fcInputPapxFkpEnd = FC_MAX;
    fcInputPapxStart = fcInputPapxEnd = FC_MAX;
    fcInputChpxFkpStart = fcInputChpxFkpEnd = FC_MAX;
    fcInputChpxStart = fcInputChpxEnd = FC_MAX;
    InputCodePage = DEFAULT_CODEPAGE;
    hInputDoc = hInputRootStg = hInputDocStream
	= hInputTableStream = hInputDataStream = NullHandle;
#ifdef DEBUG_P
    hInputTestStream = NullHandle;
#endif

    /* Load the default codepage. */
	WFWSetCodePage(DEFAULT_CODEPAGE);

    /* Initialize the many Word structures to defaults. */
    DefaultGetCharAttrs(&sInputChp);
    DefaultGetParaAttrs(&sInputPap);
    DefaultGetSepAttrs(&sGlobalSep);
    
    /* Open the document stream and get the FIB header. */
    if ((error = StgOpenDocfile(fh, &hInputDoc, &hInputRootStg)) != STGERR_NONE
	|| (error = StgStreamOpen(hInputRootStg, "WordDocument", 
				  &hInputDocStream)) != STGERR_NONE
	|| (error = StgStreamRead(hInputDocStream, &fib, 
				  sizeof(fib)) != sizeof(fib)) != STGERR_NONE)
	return SetErrorStg(error);

    if (fib.nFib > 105)         /* Word 8.0 */
    {
        char table[] = "0Table";    /* the default table stream name */

        /* Flag the Word 8.0 file format. */
        G_WFW8 = TRUE;
        
        /* Open the table stream. */
        if (fib.fWhichTblStm)       /* if set, use the other table name */
            table[0] = '1';
        if ((error = StgStreamOpen(hInputRootStg, table, &hInputTableStream))
	    != STGERR_NONE)
            return SetErrorStg(error);

        /* Open the data stream if one exists. */
        error = StgStreamOpen(hInputRootStg, "Data", &hInputDataStream);
        if (error != STGERR_NONE && error != STGERR_NAME_NOT_FOUND)
            return SetErrorStg(error);
    }
#if SUPPORT_WORD_6
    else if (fib.nFib >= 101)   /* Word 6.0/7.0 */
    {
        /* Flag the Word 6.0/7.0 file format. */
        G_WFW8 = FALSE;

        /* These files don't have a separate table stream, so whenever the
           reader refers to an offset in the table stream, use the
           main stream instead. */
        if ((hInputTableStream = StgStreamClone(hInputDocStream)) == NullHandle)
        {
            SetError(TE_OUT_OF_MEMORY);
            return FALSE;
        }
    }
#endif
    else
    {
        /* What the heck is this?  It's not a Word file, that's fer sher.. */
        SetError(TE_IMPORT_NOT_SUPPORTED);
        return FALSE;
    }

    /* Get the length of the main document text stream. */
    if (IsWord8)
    {
        READV(hInputDocStream, csw);
        SEEKR(hInputDocStream, csw * sizeof(short));
        SEEKR(hInputDocStream, offsetof(FIB_RGLW, ccpText));
        READV(hInputDocStream, cpInputTextEnd);
    }
    else
    {
        /* cpInputTextEnd = fib.ccpText; */
    }
    
    /* Setup a stream to read the text. */
    if ((hInputTextStream = StgStreamClone(hInputDocStream)) == NullHandle)
    {
        SetError(TE_OUT_OF_MEMORY);
        return FALSE;
    }

    /* Setup a PLCF to read the piece table. */
    if (IsWord8)
    {
        /* Get fcClx and lcbClx from fib.rgcflcb. */
        SEEKA(hInputDocStream, sizeof(fib) + sizeof(csw) + csw * sizeof(short));
        READV(hInputDocStream, clw);
        SEEKR(hInputDocStream, clw * sizeof(long) + offsetof(FIB_RGFCLCB, fcClx));
        READV(hInputDocStream, sInputClx);
    }
    if (sInputClx.lcb)
    {
        long lcb;

        if (!InputSeekClx(clxtPlcfpcd, 0))
            return FALSE;

        /* Get the length of the pclfpcd. */
        READV(hInputTableStream, lcb);
        
        /* Setup a PLCF to read it. */
        PLCFInit(&sInputPlcfpcd, hInputTableStream,
          StgStreamPos(hInputTableStream), lcb, sizeof(PCD));

        /* Read the first entry. */
        /* This will force the first PCD to be read on InputFillBuf. */
        if (!PLCFGetFirst(&sInputPlcfpcd, &cpInputTextPcdStart))
            return FALSE;
        cpInputTextPcdEnd = cpInputTextPcdStart;
    }
    else
    {
        /* Word 8.0 files always have a complex part (CLX). */
        if (IsWord8)
            return FALSE;
        else
        {
            sInputPlcfpcd.hStream = NullHandle;
            cpInputTextPcdEnd = cpInputTextEnd;
            bInputTextIsUnicode = FALSE;
            SEEKA(hInputTextStream, fib.fcMin);
        }
    }

    /* Trigger a call to InputFillBuf on the first call to InputGet. */
    nInputBufPos = nInputBufLen = 0;

    /* Setup a PLCF to read the plcfbteChpx. */
    if (IsWord8)
    {
        SEEKA(hInputDocStream, sizeof(fib) + sizeof(csw) + csw * sizeof(short)
          + sizeof(clw) + clw * sizeof(long)
          + offsetof(FIB_RGFCLCB, fcPlcfbteChpx));
        READV(hInputDocStream, plcfbteChpx);
    }
    if (plcfbteChpx.lcb)
    {
        PLCFInit(&sInputPlcfbteChpx, hInputTableStream,
          plcfbteChpx.fc, plcfbteChpx.lcb, sizeof(PN));
    }

    /* Setup a PLCF to read the plcfbtePapx. */
    if (IsWord8)
    {
        SEEKA(hInputDocStream, sizeof(fib) + sizeof(csw) + csw * sizeof(short)
          + sizeof(clw) + clw * sizeof(long)
          + offsetof(FIB_RGFCLCB, fcPlcfbtePapx));
        READV(hInputDocStream, plcfbtePapx);
    }
    if (plcfbtePapx.lcb)
    {
        PLCFInit(&sInputPlcfbtePapx, hInputTableStream,
          plcfbtePapx.fc, plcfbtePapx.lcb, sizeof(PN));
    }

    /* Locate and read the style table. */
    if (IsWord8)
    {
        SEEKA(hInputDocStream, sizeof(fib) + sizeof(csw) + csw * sizeof(short)
          + sizeof(clw) + clw * sizeof(long)
          + offsetof(FIB_RGFCLCB, fcStshf));
        READV(hInputDocStream, stshf);
    }
    if (stshf.lcb)
    {
        SEEKA(hInputTableStream, stshf.fc);
        if (!StyleRead())
            return FALSE;
    }

    /* Locate and read the list tables. */
    if (IsWord8)
    {
        SEEKA(hInputDocStream, sizeof(fib) + sizeof(csw) + csw * sizeof(short)
          + sizeof(clw) + clw * sizeof(long)
          + offsetof(FIB_RGFCLCB, fcPlcfLst));
        READV(hInputDocStream, plcfLst);
        READV(hInputDocStream, plfLfo);
    }
    if (!ListRead(plcfLst, plfLfo))
        return FALSE;

    /* Locate and read the font table. */
    if (IsWord8)
    {
        SEEKA(hInputDocStream, sizeof(fib) + sizeof(csw) + csw * sizeof(short)
          + sizeof(clw) + clw * sizeof(long)
          + offsetof(FIB_RGFCLCB, fcSttbfffn));
        READV(hInputDocStream, sttbfffn);
    }
    if (!FontRead(sttbfffn))
        return FALSE;

    /* Locate the plcfsed. */
    if (IsWord8)
    {
        /* Get fcPlcfsed and lcbPlcfsed from fib.rgcflcb. */
        SEEKA(hInputDocStream, sizeof(fib) + sizeof(csw) + csw * sizeof(short)
          + sizeof(clw) + clw * sizeof(long)
          + offsetof(FIB_RGFCLCB, fcPlcfsed));
        READV(hInputDocStream, sInputPlcfsed);
    }

    /* Read the dop. */
    if (IsWord8)
    {
        DOP dop;
        FC fcDop;
        
        /* Get fib.fcDop. */
        SEEKA(hInputDocStream, sizeof(fib) + sizeof(csw) + csw * sizeof(short)
          + sizeof(clw) + clw * sizeof(long)
          + offsetof(FIB_RGFCLCB, fcDop));
        READV(hInputDocStream, fcDop);
        SEEKA(hInputTableStream, fcDop);
        READV(hInputTableStream, dop);

        /* We're interested in the default tab width at dop.dxaTab. */
        wInputDefaultTab = TWIPS_TO_133(dop.dxaTab);
    }

#ifdef DEBUG_P
    hInputTestStream = StgStreamClone(hInputDocStream);
#endif

    return TRUE;
}

void InputFree(void)
{
    /* Free any stored PRM's. */
    InputFreePrm(&hInputParaPrm);
    InputFreePrm(&hInputClxtGrpprl);

    /* Free any resources alloc'd by the List code. */
    ListFree();

    /* Close any open streams. */
#ifdef DEBUG_P
    if (hInputTestStream) {
	StgStreamClose(hInputDocStream);
	hInputDocStream = NullHandle;
    }
#endif
    if (hInputDataStream) {
	StgStreamClose(hInputDataStream);
	hInputDataStream = NullHandle;
    }
    if (hInputTableStream) {
	StgStreamClose(hInputTableStream);
	hInputTableStream = NullHandle;
    }
    if (hInputTextStream) {
	StgStreamClose(hInputTextStream);
	hInputTextStream = NullHandle;
    }
    if (hInputDocStream) {
	StgStreamClose(hInputDocStream);
	hInputDocStream = NullHandle;
    }

    /* Close the document storage. */
    if (hInputDoc) {
	StgCloseDocfile(hInputDoc);
	hInputDoc = NullHandle;
    }
}

void InputFreePrm(MemHandle *pph)
{
    /* If a memblock for the PRM exists, free it. */
    if (*pph != NullHandle)
    {
        if (*pph != PRM_HANDLE_USE_CUR_PRM)
            MemFree(*pph);
        *pph = NullHandle;
    }
}

Boolean InputStorePrm(MemHandle *pph, PRM *prm)
{
    word cb;
    byte *pGrpprl;
    word sprm = 0;
    
    if (!prm->prm_2.fComplex && prm->prm_2.igrpprl == 0)
        return TRUE;            /* This PRM is empty. */

    /* Allocate a memblock to hold the grpprl. */
    if (!prm->prm_1.fComplex)
    {
        /* The PRM contains a compressed SPRM. */
        sprm = SprmUpgradeOpcode(prm->prm_1.isprm);
        cb = sizeof(sprm) + SprmGetCount(sprm);
    }
    else
    {
        /* The PRM contains the index of a clxtGrpprl in the CLX. */
        if (!InputSeekClx(clxtGrpprl, prm->prm_2.igrpprl))
            return FALSE;
        READV(hInputTableStream, cb);
        if (cb == 0)
            return TRUE;        /* What grpprl? */
    }
    if ((*pph = MemAlloc(cb + sizeof(cb), HF_DYNAMIC,
      HAF_STANDARD_LOCK)) == NullHandle)
    {
        SetError(TE_OUT_OF_MEMORY);
        return FALSE;
    }
    pGrpprl = MemDeref(*pph);

    /* Fill the memblock. */
    *(((word *)pGrpprl)++) = cb;    // length of the grpprl

    if (!prm->prm_1.fComplex)
    {
        /* Expand the compressed SPRM. */
        *(((word *)pGrpprl)++) = sprm;
        if (cb > sizeof(sprm))
        {                           // sprm has an operand
            int i;
            *(pGrpprl++) = prm->prm_1.val;
            for (i = sizeof(sprm) + 1; i < cb; i++)
                *(pGrpprl++) = 0;   // zero-pad the operand
        }
    }
    else
    {
        /* Read the grpprl into the memblock. */
        READ(hInputTableStream, pGrpprl, cb);
    }

    MemUnlock(*pph);
    return TRUE;
}

Boolean InputApplyPcdPrm(MemHandle ph, void *p, ushort sgc)
{
    Boolean retval = TRUE;

    if (ph == PRM_HANDLE_USE_CUR_PRM)
        ph = hInputClxtGrpprl;

    if (ph != NullHandle)
    {
        word *pGrpprl = MemLock(ph);
        word cbGrpprl = *(pGrpprl++);

        retval = SprmReadGrpprlMem((byte *)pGrpprl, cbGrpprl, p, sgc);
        MemUnlock(ph);
    }
    return retval;
}

void SetColor(ColorQuad *cq, byte ico)
{
    static const RGBValue colors[16] = { { 0, 0, 0 }, { 0, 0, 255 }, 
        { 0, 255, 255 }, { 0, 255, 0 }, { 255, 0, 255 }, { 255, 0, 0 }, 
        { 255, 255, 0 }, { 255, 255, 255 }, { 0, 0, 128 }, { 0, 128, 128 }, 
        { 0, 128, 0 }, { 128, 0, 128 }, { 128, 0, 0 }, { 128, 128, 0 }, 
        { 128, 128, 128 }, { 192, 192, 192 } };
    cq->CQ_redOrIndex = colors[ico - 1].RGB_red;
    cq->CQ_info = CF_RGB;
    cq->CQ_green = colors[ico - 1].RGB_green;
    cq->CQ_blue = colors[ico - 1].RGB_blue;
}

#define P2S(p) ( SDM_0 - (byte)((p) / 1.5625) )

void SetPattern(SystemDrawMask *sdm, GraphicPattern *gp, byte ipat)
{
    static const SystemDrawMask masks1[] = { P2S(5), P2S(10), P2S(20), P2S(25),
        P2S(30), P2S(40), P2S(50), P2S(60), P2S(70), P2S(75), P2S(80), P2S(90),
        P2S(2.5), P2S(7.5), P2S(12.5) };
    static const SystemDrawMask masks2[] = { P2S(2.5), P2S(7.5), P2S(12.5),
        P2S(15), P2S(17.5), P2S(22.5), P2S(27.5), P2S(32.5), P2S(35), P2S(37.5),
        P2S(42.5), P2S(45), P2S(47.5), P2S(52.5), P2S(55), P2S(57.5), P2S(62.5),
        P2S(65), P2S(72.5), P2S(77.5), P2S(82.5), P2S(85), P2S(87.5), P2S(92.5),
        P2S(95), P2S(97.5), P2S(97) };
    static const SystemHatch hatches[] = { SH_HORIZONTAL, SH_VERTICAL,
        SH_135_DEGREE, SH_45_DEGREE, SH_BRICK, SH_SLANTED_BRICK,
        SH_HORIZONTAL, SH_VERTICAL, SH_135_DEGREE, SH_45_DEGREE, SH_BRICK,
        SH_SLANTED_BRICK };

    if (ipat >=2 && ipat <= 13)
        *sdm = masks1[ipat - 2];
    else if (ipat >= 35 && ipat <= 62)
        *sdm = masks2[ipat - 35];
    else if (ipat >= 14 && ipat <= 25)
    {
        *sdm = SDM_100;
        gp->HP_type = PT_SYSTEM_HATCH;
        gp->HP_data = hatches[ipat - 14];
    }
}

Boolean SetBGColorAndPattern(SHD shd, ColorQuad *bgColor,
  SystemDrawMask *bgGrayScreen, GraphicPattern *bgPattern)
{
    byte bTemp1;
    
    if (shd.ipat <= 1 && shd.icoBack != 0)
    {
        *bgGrayScreen = SDM_100;
        if (shd.ipat == 0)
            bTemp1 = shd.icoBack;
        else
            bTemp1 = shd.icoFore;
        SetColor(bgColor, bTemp1);
        return TRUE;
    }
    else if (shd.ipat >= 2)
    {
        SetPattern(bgGrayScreen, bgPattern, shd.ipat);
        if ((bTemp1 = shd.icoFore) == 0)
            bTemp1 = 1;
        SetColor(bgColor, bTemp1);
        return TRUE;
    }
    else
        return FALSE;
}

#define TC(st,type,offset) ( *(type *)(((byte *)&(st))+(offset)) )

void InputAppendPap(void)
{
    static const VisTextParaAttr default_attr =
      PARA_ATTR_STYLE_JUST_LEFT_RIGHT_PARA(0, CA_NULL_ELEMENT, J_LEFT, 0, 0, 0);
    VisTextMaxParaAttr attr;
    const Justification justify[4] = {J_LEFT, J_CENTER, J_RIGHT, J_FULL };
    int i;
    word wTemp1;
    sword swTemp1;
    BRC *brc;

    attr.VTMPA_paraAttr = default_attr;
    memset(attr.VTMPA_tabs, 0, sizeof(attr.VTMPA_tabs));
    
    /* VTPA_attributes:
     * jc, fKeep, fKeepFollow, fNoAutoHyph, fPageBreakBefore */
    wTemp1 = 0;
    if (sInputPap.jc < 4)
        wTemp1 = (word)(justify[sInputPap.jc]) << VTPAA_JUSTIFICATION_OFFSET;
    if (sInputPap.fKeep)
        wTemp1 |= VTPAA_KEEP_PARA_TOGETHER;
    if (sInputPap.fKeepFollow)
        wTemp1 |= VTPAA_KEEP_PARA_WITH_NEXT;
    if (sInputPap.fPageBreakBefore)
        wTemp1 |= VTPAA_COLUMN_BREAK_BEFORE;
// TODO: Uncomment this when GPC allows hyphenation again.
//    if (!sInputPap.fNoAutoHyph)
//        wTemp1 |= VTPAA_ALLOW_AUTO_HYPHENATION;
    attr.VTMPA_paraAttr.VTPA_attributes = wTemp1;

    /* VTPA_leftMargin (13.3) = dxaLeft (twips) */
    attr.VTMPA_paraAttr.VTPA_leftMargin = TWIPS_TO_133(sInputPap.dxaLeft);

    /* VTPA_rightMargin (13.3) = dxaRight (twips) */
    attr.VTMPA_paraAttr.VTPA_rightMargin = TWIPS_TO_133(sInputPap.dxaRight);

    /* VTPA_paraMargin (13.3) = dxaLeft + dxaLeft1 (twips) */
    attr.VTMPA_paraAttr.VTPA_paraMargin = TWIPS_TO_133(sInputPap.dxaLeft + sInputPap.dxaLeft1);

    /* VTPA_lineSpacing (BBFixed): lspd */
    swTemp1 = sInputPap.lspd.dyaLine;
    if (swTemp1 < 0)
        swTemp1 = -swTemp1;
    attr.VTMPA_paraAttr.VTPA_lineSpacing = (word)(GrSDivWWFixed(MakeWWFixed(swTemp1),
      MakeWWFixed(240)) >> 8);

    /* VTPA_spaceOnTop (13.3) = dyaBefore (twips) */
    if (sInputPap.dyaBefore)
        attr.VTMPA_paraAttr.VTPA_spaceOnTop = TWIPS_TO_133(sInputPap.dyaBefore);

    /* VTPA_spaceOnBottom (13.3) = dyaAfter (twips) */
    if (sInputPap.dyaAfter)
        attr.VTMPA_paraAttr.VTPA_spaceOnBottom = TWIPS_TO_133(sInputPap.dyaAfter);

    /* VTPA_bgColor, VTPA_bgGrayScreen, VTPA_bgPattern */
    SetBGColorAndPattern(sInputPap.shd, &attr.VTMPA_paraAttr.VTPA_bgColor,
      &attr.VTMPA_paraAttr.VTPA_bgGrayScreen, &attr.VTMPA_paraAttr.VTPA_bgPattern);

    /* VTPA_numberOfTabs, VTMPA_tabs: itbdMac, rgdxaTab, rgtbd */
    for (i = 0; i < sInputPap.itbdMac && i < VIS_TEXT_MAX_TABS; i++)
    {
        byte bTemp1 = 0;
        TBD tbd;

        attr.VTMPA_tabs[i].T_position = TWIPS_TO_133(sInputPap.rgdxaTab[i]);
        tbd = *(TBD *)(&sInputPap.rgtbd[i]);
        if (tbd.jc < 4)
            bTemp1 = tbd.jc;
        else if (tbd.jc == 4)
        {
            // bTemp1 = 0;
            attr.VTMPA_tabs[i].T_lineWidth = 1 * 8;
            attr.VTMPA_tabs[i].T_lineSpacing = 1 * 8;
            attr.VTMPA_tabs[i].T_grayScreen = SDM_100;
        }
        if (tbd.tlc >= 2)
            bTemp1 |= TL_LINE << TabLeader_OFFSET;
        else
            bTemp1 |= tbd.tlc << TabLeader_OFFSET;
        attr.VTMPA_tabs[i].T_attr = bTemp1;
        attr.VTMPA_tabs[i].T_anchor = '.';
    }
    attr.VTMPA_paraAttr.VTPA_numberOfTabs = i;
    
    /* VTPA_defaultTabs: dop.dxaTab */
    attr.VTMPA_paraAttr.VTPA_defaultTabs = wInputDefaultTab;
    
    /* VTPA_borderFlags, VTPA_borderColor, VTPA_borderWidth, VTPA_borderSpacing,
       VTPA_borderShadow: brc... */
    wTemp1 = 0;
    if (sInputPap.brcBetween.brcType)
    {
        wTemp1 |= VTPBF_DRAW_INNER_LINES;
        brc = &sInputPap.brcBetween;
    }
    if (sInputPap.brcTop.brcType)
    {
        wTemp1 |= VTPBF_TOP;
        brc = &sInputPap.brcTop;
    }
    if (sInputPap.brcLeft.brcType)
    {
        wTemp1 |= VTPBF_LEFT;
        brc = &sInputPap.brcLeft;
    }
    if (sInputPap.brcBottom.brcType)
    {
        wTemp1 |= VTPBF_BOTTOM;
        brc = &sInputPap.brcBottom;
    }
    if (sInputPap.brcRight.brcType)
    {
        wTemp1 |= VTPBF_RIGHT;
        brc = &sInputPap.brcRight;
    }
    if (wTemp1)
    {
        attr.VTMPA_paraAttr.VTPA_borderFlags = wTemp1;
        attr.VTMPA_paraAttr.VTPA_borderWidth = brc->dptLineWidth;
        attr.VTMPA_paraAttr.VTPA_borderSpacing = brc->dptSpace * 8;
        SetColor(&attr.VTMPA_paraAttr.VTPA_borderColor, brc->ico);
        if (sInputPap.brcTop.brcType == 3 && sInputPap.brcLeft.brcType == 3
          && sInputPap.brcBottom.brcType == 3 && sInputPap.brcRight.brcType == 3)
            attr.VTMPA_paraAttr.VTPA_borderFlags |= VTPBF_DOUBLE;
        if (sInputPap.brcBottom.fShadow && sInputPap.brcRight.fShadow)
            attr.VTMPA_paraAttr.VTPA_borderFlags |= (VTPBF_SHADOW | SA_TOP_LEFT);
    }

    TextAppendParaAttrs(&attr.VTMPA_paraAttr);
}

void InputAppendChp(void)
{
    VisTextCharAttr attr = CHAR_ATTR_FONT_SIZE(FID_DTC_URW_ROMAN, 10);
    byte bTemp1;
    word wTemp1;
    FontID fid;
    DosCodePage cp;

    /* VTCA_textStyles:
     * fBold, fItalic, fOutline, fStrike, iss, kul */
    wTemp1 = TC(sInputChp, word, 0);    /* fBold - fOle2 */
    bTemp1 = 0;
    if (wTemp1 & 0x0001)
        bTemp1 |= TS_BOLD;
    if (wTemp1 & 0x0002)
        bTemp1 |= TS_ITALIC;
    if (wTemp1 & 0x0008)
        bTemp1 |= TS_OUTLINE;
    if (wTemp1 & 0x0400)
        bTemp1 |= TS_STRIKE_THRU;
    wTemp1 = TC(sInputChp, byte, 22);   /* iss, kul */
    if (wTemp1 & 0x01)
        bTemp1 |= TS_SUPERSCRIPT;
    if (wTemp1 & 0x02)
        bTemp1 |= TS_SUBSCRIPT;
    if (wTemp1 & 0x78)
        bTemp1 |= TS_UNDERLINE;
    attr.VTCA_textStyles = bTemp1;

    /* VTCA_pointSize (BBFixed) = hps / 2 */
    attr.VTCA_pointSize.WBF_int = sInputChp.hps / 2;
    attr.VTCA_pointSize.WBF_frac = (byte)sInputChp.hps << 7;

    /* VTCA_fontID: ftcAscii */
    if ((fid = FontFindFont(sInputChp.ftcAscii, &cp)) != FID_INVALID)
    {
        attr.VTCA_fontID = fid;
        InputCodePage = cp;
    }
    
    /* VTCA_color: ico */
    if ((bTemp1 = sInputChp.ico) == 0 || bTemp1 > 16)
        bTemp1 = 1;     /* auto defaults to black */
    SetColor(&attr.VTCA_color, bTemp1);
    
    /* VTCA_fontWidth: wCharScale */
    attr.VTCA_fontWidth = sInputChp.wCharScale;
    
    /* VTCA_bgColor, VTCA_bgGrayScreen, VTCA_bgPattern: shd */
    if (SetBGColorAndPattern(sInputChp.shd, &attr.VTCA_bgColor, &attr.VTCA_bgGrayScreen,
      &attr.VTCA_bgPattern))
        attr.VTCA_extendedStyles |= VTES_BACKGROUND_COLOR;

    TextAppendCharAttrs(&attr);
}

Boolean InputApplyChpx(MemHandle hprm)
{
    /* Set sInputChp to the current paragraph and character style (istd). */
    if (!StyleGetPara(sInputPap.istd, NULL, &sInputChp)
      || !StyleGetChar(sInputChp.istd, &sInputChp))
        return FALSE;

    sInputStyleChp = sInputChp;
    
    if (bInputChpxOff == 0)
    {
        /* The properties of the run of text are exactly equal to the
           character properties inherited from the style of the paragraph
           it is in. */
    }
    else
    {
        byte cbGrpprl;

        SEEKA(hInputDocStream, PN_TO_FC(pnInputChpPos) +
          (word)bInputChpxOff * sizeof(word));
        READV(hInputDocStream, cbGrpprl);

        /* Read the grpprl. */
        if (!SprmReadGrpprl(hInputDocStream, cbGrpprl, &sInputChp, SGC_CHP))
            return FALSE;
    }

    /* Process any character sprms in the PRM of the current PCD. */
    if (!InputApplyPcdPrm(hprm, &sInputChp, SGC_CHP))
        return FALSE;

    bInputNewChp = TRUE;

    return TRUE;
}

Boolean InputScanChpxFkp(FC fc)
{
    /* Seek the FKP that contains fc. */
    if (fc < fcInputChpxFkpStart || fc >= fcInputChpxFkpEnd)
    {
        /* fc is not in the current CHPX FKP. */
        PN pn;

        /* Search the CHP FKPs for fc. */
        if (fc < fcInputChpxFkpStart)
        {
            /* Start at beginning. */
            if (!PLCFGetFirst(&sInputPlcfbteChpx, &fcInputChpxFkpStart))
                return FALSE;
            fcInputChpxFkpEnd = fcInputChpxFkpStart;
        }
        while ((fc < fcInputChpxFkpStart || fc >= fcInputChpxFkpEnd)
          && fcInputChpxFkpEnd != EOF)
        {
            fcInputChpxFkpStart = fcInputChpxFkpEnd;

            if (!PLCFGetNext(&sInputPlcfbteChpx, &fcInputChpxFkpEnd, &pn))
                return FALSE;
        }
        if (fcInputChpxFkpEnd == EOF)
        {
            /* fc wasn't found in the plcfbteChpx. */
            EC_WARNING(WFW_WARNING_PLCFBTECHPX_ENDED_EARLY);
            SetError(TE_IMPORT_ERROR);
            return FALSE;
        }
        else
        {
            byte crun;
            
            /* Setup the CHPX FKP PLCF. */
            pnInputChpPos = pn;
            SEEKA(hInputDocStream, PN_TO_FC(pnInputChpPos) + FKP_CRUN);
            READV(hInputDocStream, crun);       /* Get the run count. */
            PLCFInit(&sInputChpxFkp, hInputDocStream, PN_TO_FC(pnInputChpPos),
              PLCF_SIZE(crun, sizeof(byte)), sizeof(byte));
            fcInputChpxStart = FC_MAX;
        }
    }

    /* Search the FKP to find the first FC larger than fc. */
    if (fc < fcInputChpxStart)
    {
        if (!PLCFGetFirst(&sInputChpxFkp, &fcInputChpxEnd))
            return FALSE;
    }
    while (fc < fcInputChpxStart || fc >= fcInputChpxEnd)
    {
        fcInputChpxStart = fcInputChpxEnd;
        if (!PLCFGetNext(&sInputChpxFkp, &fcInputChpxEnd, NULL))
            return FALSE;
        if (fcInputChpxEnd == EOF)
        {
            EC_WARNING(WFW_WARNING_CHPX_FKP_ENDED_EARLY);
            SetError(TE_IMPORT_ERROR);
            return FALSE;
        }
    }

    return TRUE;
}

Boolean InputGetChpx(FC fc)
{
    if (fc < fcInputChpxStart || fc >= fcInputChpxEnd)
    {
        byte newOff;
        
        /* We're no longer in the current CHPX run. */
        
        /* Search the CHPX FKPs for fc. */
        if (!InputScanChpxFkp(fc))
            return FALSE;

        /* Read the CHPX for the next grpprl. */
        if (!PLCFRead(&sInputChpxFkp, &newOff))
            return FALSE;

        if (bInputChpxOff != newOff)
        {
            bInputChpxOff = newOff;
            bInputRedoChp = TRUE;
        }
    }

    return TRUE;
}

Boolean InputGetPcdPrm(MemHandle *pph, PCD *pcd)
{
    if (PRM_TO_WORD(pcd->prm) != PRM_TO_WORD(sInputCurPcdPrm))
    {
        /* Temporarily load and expand the PRM. (Caller will free) */
        return InputStorePrm(pph, &pcd->prm);
    }
    else
    {
        *pph = PRM_HANDLE_USE_CUR_PRM;
        return TRUE;
    }
}

Boolean InputApplyPapx(byte *rgbx)
{
    byte cwPapx;
    word cbGrpprl = 0;
    ushort istd;
    
    /* Get the paragraph style and exceptions for this run. */
    if (rgbx[0] == 0)
    {
        /* The properties of the run of text are exactly equal to the
           properties of the Normal style (istd == 0). */
        istd = 0;
    }
    else
    {
        SEEKA(hInputDocStream, PN_TO_FC(pnInputPapPos) +
          (word)rgbx[0] * sizeof(word));
        READV(hInputDocStream, cwPapx);
        if (cwPapx == 0)
        {
            READV(hInputDocStream, cwPapx);
            cbGrpprl = (word)cwPapx * 2 - sizeof(istd);
        }
        else
            cbGrpprl = (word)cwPapx * 2 - (sizeof(byte) + sizeof(istd));
        READV(hInputDocStream, istd);
        /* The stream is now positioned at the start of the grpprl. */
    }

    /* Set sInputPap and sInputStyleChp to the paragraph style for this run. */
    if (!StyleGetPara(istd, &sInputPap, &sInputStyleChp))
        return FALSE;
    EC_WARNING_IF(sInputPap.istd != istd, WFW_WARNING_PAP_ISTD_INCORRECT);
    
    if (cbGrpprl > 0)
    {
        /* The PAPX contains a grpprl. */
        if (!SprmReadGrpprl(hInputDocStream, cbGrpprl, &sInputPap, SGC_PAP))
            return FALSE;
    }

    /* Process any paragraph sprms in the PRM of the current PCD. */
    if (!InputApplyPcdPrm(hInputParaPrm, &sInputPap, SGC_PAP))
        return FALSE;

    bInputNewPap = TRUE;

    /* Handle the association of a list with this paragraph. */
    if (sInputPap.ilfo != 0)
    {
#ifdef DEBUG
        printf("(ilfo=%d,ilvl=%d)\n",sInputPap.ilfo,sInputPap.ilvl);
#endif
#if 0
        /* Apply the paragraph exceptions for the list. */
        if (!ListApplyPapx(&sInputPap))
            return FALSE;
#endif
        /* Flag the presence of list autotext for this paragraph. */
        bInputParaList = TRUE;
    }

    if (hInputStyle != istd)
    {
        hInputStyle = istd;
        /* If the paragraph style changed, the CHP might have changed too. */
        bInputRedoChp = TRUE;
    }

    return TRUE;
}

#pragma warn -par
Boolean InputScanPapxFkp(FC fcTest, FC fcPcdEnd, CP cpPcdStart,
  CP cpPcdEnd, Boolean *bFound)
{
    *bFound = FALSE;
    /* Seek the FKP that contains fcTest. */
    if (fcTest < fcInputPapxFkpStart || fcTest >= fcInputPapxFkpEnd)
    {
        /* fcTest is not in the current PAPX FKP. */
        PN pn;

        /* Search the plcfbtePapx for fcInputTextPos. */
        if (fcTest < fcInputPapxFkpStart)
        {
            /* Start at beginning. */
            if (!PLCFGetFirst(&sInputPlcfbtePapx, &fcInputPapxFkpStart))
                return FALSE;
            fcInputPapxFkpEnd = fcInputPapxFkpStart;
        }
        while ((fcTest < fcInputPapxFkpStart || fcTest >= fcInputPapxFkpEnd)
          && fcInputPapxFkpEnd != EOF)
        {
            fcInputPapxFkpStart = fcInputPapxFkpEnd;

            if (!PLCFGetNext(&sInputPlcfbtePapx, &fcInputPapxFkpEnd, &pn))
                return FALSE;
        }
        if (fcInputPapxFkpEnd == EOF)
            /* fcTest wasn't found in the plcfbtePapx. */
            return TRUE;
        else
        {
            byte crun;

            /* Setup the PAPX FKP PLCF. */
            pnInputPapPos = pn;
            SEEKA(hInputDocStream, PN_TO_FC(pnInputPapPos) + FKP_CRUN);
            READV(hInputDocStream, crun);       /* Get the run count. */
            PLCFInit(&sInputPapxFkp, hInputDocStream, PN_TO_FC(pnInputPapPos),
              PLCF_SIZE(crun, PAPX_FKP_BX_SIZE), PAPX_FKP_BX_SIZE);
            fcInputPapxStart = FC_MAX;
        }
    }

    /* Search the FKP to find the first FC larger than fcTest. */
    if (fcTest < fcInputPapxStart)
    {
        if (!PLCFGetFirst(&sInputPapxFkp, &fcInputPapxEnd))
            return FALSE;
    }
    while (fcInputPapxEnd <= fcTest)
    {
        fcInputPapxStart = fcInputPapxEnd;
        if (!PLCFGetNext(&sInputPapxFkp, &fcInputPapxEnd, NULL))
            return FALSE;
        if (fcInputPapxEnd == EOF)
        {
            EC_WARNING(WFW_WARNING_PAPX_FKP_ENDED_EARLY);
            SetError(TE_IMPORT_ERROR);
            return FALSE;
        }
    }

    /* Test if the FC that was found is less than or equal to fcPcdEnd. */
    if (fcInputPapxEnd <= fcPcdEnd)
    {
        /* fcTest was found! */
        *bFound = TRUE;
    }
    return TRUE;
}
#pragma warn +par

typedef Boolean InputSPTFunc(FC fcPcdStart, FC fcPcdEnd, CP cpPcdStart,
    CP cpPcdEnd, Boolean *bFound);
typedef InputSPTFunc *InputSPTFuncPtr;

Boolean InputScanPieceTable(PLCF *plcf, PCD *pcd, CP *cpPcdStart,
    CP *cpPcdEnd, Boolean *bUnicode, InputSPTFuncPtr pFunc)
{
    Boolean bFound = FALSE;
    FC fcPcdEnd;

    while (!bFound)
    {
        *cpPcdStart = *cpPcdEnd;
        if (!PLCFGetNext(plcf, cpPcdEnd, pcd))
            return FALSE;
        if (*cpPcdEnd == EOF)
        {
            /* End of piece table. */
            EC_WARNING(WFW_WARNING_PCD_ENDED_WHILE_SEARCHING);
            return FALSE;
        }
        else
        {
            if (pcd->fc & PCD_FC_VIRTUAL)
            {
                pcd->fc = (pcd->fc & ~PCD_FC_VIRTUAL) >> 1;
                *bUnicode = FALSE;
            }
            else
                *bUnicode = TRUE;
            fcPcdEnd = CP_TO_FC(pcd->fc, *cpPcdStart,
              *cpPcdEnd, *bUnicode);
        }
        if (pFunc != NULL)
        {
            if (!ProcCallFixedOrMovable_cdecl(pFunc, pcd->fc,
              fcPcdEnd, *cpPcdStart, *cpPcdEnd, &bFound))
                return FALSE;
        }
        else
            bFound = TRUE;
    }

    return TRUE;
}

#ifdef DEBUG_P
Boolean InputTestParaMark(void)
{
    char c;
    
    SEEKA(hInputTestStream, fcInputParaMark);
    READV(hInputTestStream, c);
    return (c == 13 || c == 7);
}
#endif

Boolean InputNextPapx(void)
{
    if (cpInputTextPos == cpInputPapxStart)
    {
        byte bx[PAPX_FKP_BX_SIZE];
        Boolean bFound;
        Boolean bUnicode = bInputTextIsUnicode;
        CP cpTemp;
        PCD pcd;
        CP cpPcdStart = cpInputTextPcdStart;
        FC fcStart = fcInputTextPos;
    
        /* We've reached the end of this PAPX run. */

        /* Free the old paragraph PRM. */
        InputFreePrm(&hInputParaPrm);

        /* Search the PAPX FKPs for the next paragraph end. */
        pcd.fc = fcInputTextPos;
        if (!InputScanPapxFkp(fcInputTextPos, fcInputTextPcdEnd, 0, 0, &bFound))
            return FALSE;
        if (!bFound)
        {
            CP cpPcdEnd = cpInputTextPcdEnd;
            CP cpPcdOldEnd = cpPcdEnd;
            PLCF plcfpcd = sInputPlcfpcd;

            /* Compensate for leaving the current piece. */
            cpInputPapxStart += cpPcdEnd - cpInputTextPos;
            
            /* Find the piece that contains the paragraph end. */
            if (!InputScanPieceTable(&plcfpcd, &pcd, &cpPcdStart, &cpPcdEnd,
              &bUnicode, InputScanPapxFkp))
                return FALSE;

            /* Compensate for skipped pieces. */
            cpInputPapxStart += cpPcdStart - cpPcdOldEnd;
            fcStart = pcd.fc;

            /* Load the PRM of the PCD. */
            if (!InputGetPcdPrm(&hInputParaPrm, &pcd))
                return FALSE;
        }
        else
            hInputParaPrm = PRM_HANDLE_USE_CUR_PRM;

        /* Read the PAPX. */
        if (!PLCFRead(&sInputPapxFkp, bx))
            return FALSE;

        /* If necessary, copy bx[1..] into sInputPap.phe. */

        /* Set the new start to the end of this PAPX run. */
        cpTemp = (fcInputPapxEnd - fcStart);
        if (bUnicode)
            cpTemp /= 2;
        cpInputPapxStart += cpTemp;

        /* Compute the FC of the paragraph mark. */
        fcInputParaMark = CP_TO_FC(fcInputTextPcdStart, cpPcdStart,
          cpInputPapxStart - 1, bUnicode);
#ifdef DEBUG_P
        if (!InputTestParaMark())
        {
            printf("PARA MARK NOT FOUND\n");
            printf("-------------------\n");
        }
        else
        {
            printf("Para mark found\n");
            printf("---------------\n");
        }
        printf("fcInputParaMark = %ld\n", fcInputParaMark);
        printf("cpPcdStart = %ld\n", cpPcdStart);
        printf("fcInputTextPcdStart = %ld\n", fcInputTextPcdStart);
        printf("cpInputPapxStart = %ld\n", cpInputPapxStart);
        printf("fcInputPapxEnd = %ld\n", fcInputPapxEnd);
#endif

        /* Generate the complete PAP for this run. */
        if (!InputApplyPapx(bx))
            return FALSE;

//        /* Unload the PRM. */
//        InputFreePrm(&hInputParaPrm);
    }
    return TRUE;
}

Boolean InputApplyList(void)
{
    /* Store the current CHP. */
    CHP sTempChp = sInputChp;
    char cAutoSpace;
    
    /* Construct the CHP for the list autotext (paragraph mark). */
    if (!InputGetChpx(fcInputParaMark) || !InputApplyChpx(hInputParaPrm)
      || !ListApplyChpx(sInputPap.ilfo, sInputPap.ilvl, &sInputChp))
        return FALSE;

    /* Reset the shading attributes that apparently don't appear in list autotext. */
    sInputChp.shd.ipat = sInputChp.shd.icoBack = sInputChp.shd.icoFore = 0;
    
    /* Append the CHP. */
    TextBufferDump();
    InputAppendChp();

    /* Switch to the appropriate codepage for Unicode text. */
    InputSetCodePage(TRUE);

    /* Insert the list autotext. */
    if (!ListInsertText(sInputPap.ilvl, &cAutoSpace))
        return FALSE;

    /* Insert any post-autotext spacing. */
    if (cAutoSpace != C_NULL)
        TextBufferAddChar(cAutoSpace);

    /* Restore and append the original CHP. */
    sInputChp = sTempChp;
    TextBufferDump();
    InputAppendChp();

    /* Clear the flags set by the CHP routines. */
    bInputRedoChp = bInputNewChp = bInputNewChp = FALSE;

    return TRUE;
}

#pragma warn -par
Boolean InputTestSepx(FC fcPcdStart, FC fcPcdEnd, CP cpPcdStart,
    CP cpPcdEnd, Boolean *bFound)
{
    if (!(cpInputSepxEnd < cpPcdStart || cpInputSepxEnd > cpPcdEnd))
        *bFound = TRUE;
    return TRUE;
}
#pragma warn +par

Boolean InputNextSepx(void)
{
    /* Until impex handles multiple section definitions, we only load the
       section properties of the first available section in the Word
       document. */
    if (cpInputTextPos == 0)
    {
        CP cpSepxStart;
        PLCF plcfsed;
        SED sed;
        MemHandle hSepxPrm = NullHandle;
        
        /* Setup and read the first entry in the plcfsed. */
        PLCFInit(&plcfsed, hInputTableStream,
          sInputPlcfsed.fc, sInputPlcfsed.lcb, sizeof(SED));
        if (!PLCFGetFirst(&plcfsed, &cpSepxStart)
          || !PLCFGetNext(&plcfsed, &cpInputSepxEnd, &sed))
            return FALSE;

        EC_ERROR_IF(cpSepxStart != cpInputTextPos, -1);
        
        if (sed.fcSepx == FC_NIL)
        {
            /* The section properties for the section are equal to the
               standard SEP.  Nothing to do here. */
        }
        else
        {
            /* Apply the SEPX at sed.fcSepx to sGlobalSep. */
            ushort cbGrpprl;
            
            SEEKA(hInputDocStream, sed.fcSepx);
            READV(hInputDocStream, cbGrpprl);
            if (!SprmReadGrpprl(hInputDocStream, cbGrpprl, &sGlobalSep,
              SGC_SEP))
                return FALSE;
        }

        /* Locate the PCD that contains the section end mark. */
        if (cpInputSepxEnd < cpInputTextPcdStart
          || cpInputSepxEnd > cpInputTextPcdEnd)
        {
            CP cpPcdStart = cpInputTextPcdStart;
            CP cpPcdEnd = cpInputTextPcdEnd;
            PCD pcd;
            PLCF plcfpcd = sInputPlcfpcd;
            Boolean bUnicode;

            pcd.fc = fcInputTextPos;
            if (!InputScanPieceTable(&plcfpcd, &pcd, &cpPcdStart, &cpPcdEnd,
              &bUnicode, InputTestSepx))
                return FALSE;

            /* Load the PRM of the PCD. */
            if (!InputGetPcdPrm(&hSepxPrm, &pcd))
                return FALSE;
        }
        else
            hSepxPrm = PRM_HANDLE_USE_CUR_PRM;

        /* Process any section sprms in the PRM of the current PCD. */
        if (!InputApplyPcdPrm(hSepxPrm, &sGlobalSep, SGC_SEP))
            return FALSE;

        /* Unload the PRM. */
        InputFreePrm(&hSepxPrm);
    }

    return TRUE;
}

Boolean InputFillBuf(void)
{
    PCD pcd;

    if (cpInputTextPos == cpInputTextPcdEnd)
    {
        /* Time to read the piece table. */
        if (sInputPlcfpcd.hStream == NullHandle)
        {
            /* No piece table - we've reached the end. */
            cpInputTextPos = cpInputTextPcdEnd = EOF;
        }
        else
        {
            if (!InputScanPieceTable(&sInputPlcfpcd, &pcd, &cpInputTextPcdStart,
              &cpInputTextPcdEnd, &bInputTextIsUnicode, NULL))
                return FALSE;
            /* Point the text stream to the proper FC. */
            SEEKA(hInputTextStream, pcd.fc);

            fcInputTextPos = fcInputTextPcdStart = pcd.fc;
            fcInputTextPcdEnd = CP_TO_FC(fcInputTextPos, cpInputTextPos,
              cpInputTextPcdEnd, bInputTextIsUnicode);

            /* Read and store the PRM attached to this piece. */

            /* Is this PRM different from the one currently in memory? */
            if (PRM_TO_WORD(sInputCurPcdPrm) != PRM_TO_WORD(pcd))
            {
                PRM_TO_WORD(sInputCurPcdPrm) = PRM_TO_WORD(pcd);
                bInputNewPcd = TRUE;
                InputFreePrm(&hInputClxtGrpprl);
                PRM_TO_WORD(sInputCurPcdPrm) = 0;
                if (!InputStorePrm(&hInputClxtGrpprl, &pcd.prm))
                    return FALSE;
            }
        }
    }

    nInputBufLen = INPUT_BUFFER_SIZE;
    if (fcInputTextPcdEnd - fcInputTextPos < nInputBufLen)
        nInputBufLen = fcInputTextPcdEnd - fcInputTextPos;
    if (nInputBufLen > 0)
        READ(hInputTextStream, acInputBuf, nInputBufLen);
    nInputBufPos = 0;

    return TRUE;
}

Boolean InputTrans(void)
{
    Boolean bFieldCode = FALSE;
    int c = 0;

    while (cpInputTextPos < cpInputTextEnd && GetError() == TE_NO_ERROR)
    {
        /* Fill the input buffer if necessary. */
        if (nInputBufPos >= nInputBufLen)
        {
            if (!InputFillBuf())
                return FALSE;

            if (nInputBufPos >= nInputBufLen)
                return FALSE;
        }

        /* Process and apply the section property runs. */
        if (!InputNextSepx())
            return FALSE;
        
        /* Process and apply the paragraph exception runs. */
        if (!InputNextPapx())
            return FALSE;

        /* Process the character exception runs. */
        if (!InputGetChpx(fcInputTextPos))
            return FALSE;

        /* Apply any new character property changes. */
        if (bInputNewPcd || bInputRedoChp)
        {
            if (!InputApplyChpx(hInputClxtGrpprl))
                return FALSE;
        }
    
        bInputRedoChp = FALSE;
        bInputNewPcd = FALSE;

        /* Process the text. */
        if (bInputTextIsUnicode)
        {
            c = *(wchar *)(&acInputBuf[nInputBufPos]);
            nInputBufPos += 2;
            fcInputTextPos += 2;
        }
        else
        {
            /* Convert the codepage-1252 character to GEOS. */
            c = acInputBuf[nInputBufPos ++];
            fcInputTextPos ++;
        }
        cpInputTextPos ++;

        /* Apply any new paragraph and character formatting. */
        if (bInputNewPap || bInputNewChp)
        {
            TextBufferDump();

            if (bInputNewPap)
            {
                InputAppendPap();
                bInputNewPap = FALSE;
            }
            if (bInputNewChp)
            {
                InputAppendChp();
                bInputNewChp = FALSE;
            }
        }

        /* Handle insertion of list autotext.  Delay the insertion until
           a character is encountered that isn't a GEOS paragraph endmark.
           This includes page breaks, column breaks, and row marks, which
           may translate to enters. */
        if (bInputParaList && !sInputChp.fSpec
          && !(c == 14 || c == 12 ||
          (c == 7 && sInputPap.fInTable && sInputPap.fTtp)))
        {
            if (!InputApplyList())
                return FALSE;
            bInputParaList = FALSE;
        }
        
        /* Handle the "special" characters. */
        if (sInputChp.fSpec)
        {
            switch (c)
            {
            case 19:        /* field begin mark */
                c = C_NULL;
                bFieldCode = TRUE;
                break;
            case 20:        /* field separator */
            case 21:        /* field end mark */
                c = C_NULL;
                bFieldCode = FALSE;
                break;
            default:
                c = C_NULL;
            }
        }
        /* Handle the normal character exceptions. */
        else if (c < 32)
        {
            switch (c)
            {
            case 9:         /* tab: C_TAB = 9 */
            case 12:        /* page/section break: C_PAGE_BREAK = 12 */
            case 13:        /* paragraph end: C_ENTER = 13 */
                break;
            case 11:        /* hard line break */
                c = C_ENTER;        // there is no equivalent
                break;
            case 30:        /* non-breaking hyphen */
                c = C_NONBRKHYPHEN;
                break;
            case 31:        /* non-required hyphen */
                c = C_OPTHYPHEN;
                break;
            case 14:        /* column break */
                c = C_COLUMN_BREAK;
                break;
            case 7:         /* cell/row mark */
                if (sInputPap.fInTable)
                {
                    if (sInputPap.fTtp)
                        c = C_ENTER;    /* row mark */
                    else
                        c = C_TAB;      /* cell mark */
                }
                else
                    c = C_NULL;
                break;
            default:		/* eat all other 00h-1Fh chars */
            	c = C_NULL;
            	break;
            }
        }
        /* Handle standard text. */
        else
        {
            InputSetCodePage(bInputTextIsUnicode);
            c = WFWCodePageToGeos(c);
        }

        /* Append the character if not null and not in a field. */
        if (c != C_NULL && !bFieldCode)
            TextBufferAddChar(c);
    }
    TextBufferDump();

    return TRUE;
}

