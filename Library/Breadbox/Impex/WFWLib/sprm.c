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
 * File:    sprm.c
 *
 ***************************************************************************/

#include <geos.h>
#include <heap.h>
#include <resource.h>
#include <Ansi/string.h>
#include <ec.h>
#include "sprm.h"
#include "structs.h"
#include "warnings.h"
#include "global.h"
#include "style.h"
#include "list.h"

#include "sprm.tbl"

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

/* Converts a W6 SPRM opcode to a W8 SPRM opcode. */
word SprmUpgradeOpcode(byte sprm)
{
    static const /*_far*/ word SprmOpcodeW6ToW8Table[] = {
        0,      0,      0x4600, 0xc601, 0x2602, 0x2403, 0x2404, 0x2405,
        0x2406, 0x2407, 0x2408, 0x2409, 0,      0,      0x240c, 0xc60d,
        0x840e, 0x840f, 0x4610, 0x8411, 0x6412, 0xa413, 0xa414, 0xc615,
        0x2416, 0x2417, 0x8418, 0x8418, 0x841a, 0x261b, 0x461c, 0x461d,
        0x461e, 0x461f, 0x4620, 0x4621, 0x4622, 0x2423, 0x6424, 0x6425,
        0x6426, 0x6427, 0x6428, 0x6629, 0x242a, 0x442b, 0x442c, 0x442d,
        0x842e, 0x842f, 0x2430, 0x2431, 0xc632, 0,      0,      0,
        0,      0,      0,      0,      0,      0,      0,      0,
        0,      0x0800, 0x0801, 0x0802, 0x6a03, 0x4804, 0x6805, 0x0806,
        0x4807, 0xea08, 0x6a09, 0x080a, 0,      0,      0,      0,
        0x4a30, 0xca31, 0x2a32, 0x2a33, 0,      0x0835, 0x0836, 0x0837,
        0x0838, 0x0839, 0x083a, 0x083b, 0x083c, 0,      0x2a3e, 0xea3f,
        0x8840, 0,      0x2a42, 0x4a43, 0x2a44, 0x4845, 0x2a46, 0xca47,
        0x2a48, 0xca49, 0xca4a, 0x484b, 0xca4c, 0x4a4d, 0x484e, 0,
        0,      0,      0,      0,      0,      0x0855, 0x0856, 0x2e00,
        0xce01, 0x6c02, 0x6c03, 0x6c04, 0x6c05
    };
    word *pTable = MemLockFixedOrMovable(SprmOpcodeW6ToW8Table);
    word retval = 0;

    if (sprm < ARRAY_LEN(SprmOpcodeW6ToW8Table, word))
        retval = pTable[sprm];
        
    MemUnlockFixedOrMovable(pTable);

    return retval;
}

word SprmGetCount(word op)
{
    word cch = 0;
    
    switch (WORD_TO_SPRM(op).spra)
    {
        case SPRA_BIT:
        case SPRA_BYTE:
            cch = 1; break;     /* one byte operand */
        case SPRA_WORD:
        case SPRA_COORD:
        case SPRA_COORD2:
            cch = 2; break;     /* two byte operand */
        case SPRA_WAAH:
            cch = 3; break;     /* three byte operand */
        case SPRA_DWORD:
            cch = 4; break;     /* four byte operand */
        case SPRA_VAR:
            break;              /* variable length operand */
        default:
            EC_WARNING(WFW_WARNING_UNKNOWN_SPRA_VALUE);
    }
    return cch;
}

Boolean SprmHandlePChgTabs(byte *pData, word *pcch)
{
    if (*pcch == 255)
    {
        pData += (*pcch = (sizeof(byte) + (*pData) * 4));
        *pcch += sizeof(byte) + (*pData) * 3;
        return TRUE;
    }
    else
        return FALSE;
}

Boolean SprmHandlePChgTabsPapx(byte *pData, word *pcch)
{
    if (*pcch == 255)
    {
        pData += (*pcch = (sizeof(byte) + (*pData) * 2));
        *pcch += sizeof(byte) + (*pData) * 3;
        return TRUE;
    }
    else
        return FALSE;
}

Boolean SprmReadGrpprl(StgStream hStream, word cbGrpprl, void *p, ushort sgc)
{
    Boolean retval = TRUE;
    word cb = 0;

    while (retval && cb < cbGrpprl)
    {
        SPRM_Opcode op;
        word cch;
        byte data[MAX_SPRM_OPERAND_SIZE];

        READV(hStream, op);
        if (SPRM_TO_WORD(op) == SPRM_TDefTable || SPRM_TO_WORD(op) == SPRM_TDefTable10)
        {
            /* This sprm is always being skipped for now.  If we need to read it,
               MAX_SPRM_OPERAND_SIZE may have to be increased.  */
            READ(hStream, &cch, sizeof(word));   /* this is Intel-dependent */
            cch --;
            SEEKR(hStream, cch);
            cb += sizeof(op) + sizeof(word) + cch;
        }
        else
        {
            cch = SprmGetCount(SPRM_TO_WORD(op));
            if (!cch)
            {
                READ(hStream, &cch, sizeof(byte));   /* this is Intel-dependent */
                cb += sizeof(byte);
                if (cch > sizeof(data))
                {
                    // Skip data that would otherwise overflow the buffer.
                    SEEKR(hStream, cch - sizeof(data));
                    EC_WARNING(WFW_WARNING_SPRM_READ_GRPPRL_TRUNCATING_PARAMETER);
                    cch = sizeof(data);
                }
            }
            READ(hStream, data, cch);
#if 0 // Assuming sprmPChgTabs will never be read from a stream.
            /* Handle sprmPChgTabs here.  (Compute real cch and get remainder) */
            if (SPRM_TO_WORD(op) == SPRM_PChgTabs && SprmHandlePChgTabs(data, &cch))
                READ(hStream, data + 255, cch - 255);
#endif
            /* Handle sprmPChgTabsPapx here.  (Compute real cch and get remainder) */
            if (SPRM_TO_WORD(op) == SPRM_PChgTabsPapx && SprmHandlePChgTabsPapx(data, &cch))
                READ(hStream, data + 255, cch - 255);
            cb += sizeof(op) + cch;
            if (op.sgc == sgc)
                retval = SprmProcess(SPRM_TO_WORD(op), cch, data, p, sgc);
        }
    }
    EC_WARNING_IF(cb > cbGrpprl, WFW_WARNING_SPRM_READ_GRPPRL_EXCEEDED_BOUNDS);
    return retval;
}

#define BUFFER_CHECK(cb)    if (cbGrpprl < (cb)) { \
    EC_WARNING(WFW_WARNING_SPRM_READ_GRPPRL_MEM_EXCEEDED_BOUNDS); return FALSE; }

Boolean SprmReadGrpprlMem(byte *pGrpprl, word cbGrpprl, void *p, ushort sgc)
{
    Boolean retval = TRUE;
    
    while (retval && cbGrpprl)
    {
        SPRM_Opcode op;
        word cch;
        byte *data;

        BUFFER_CHECK(sizeof(op));        
        op = WORD_TO_SPRM(*(((word *)pGrpprl)++));
        cbGrpprl -= sizeof(op);
        cch = SprmGetCount(SPRM_TO_WORD(op));
        if (!cch)
        {
            BUFFER_CHECK(sizeof(byte));
            cch = *(pGrpprl++);
            cbGrpprl -= sizeof(byte);
        }
        BUFFER_CHECK(cch);
        data = pGrpprl;
        /* Handle sprmPChgTabs here.  (Compute real cch and get remainder) */
        if (SPRM_TO_WORD(op) == SPRM_PChgTabs)
            SprmHandlePChgTabs(pGrpprl, &cch);
        /* Handle sprmPChgTabsPapx here.  (Compute real cch and get remainder) */
        if (SPRM_TO_WORD(op) == SPRM_PChgTabsPapx)
            SprmHandlePChgTabsPapx(pGrpprl, &cch);
        pGrpprl += cch;
        cbGrpprl -= cch;
        if (op.sgc == sgc)
            retval = SprmProcess(SPRM_TO_WORD(op), cch, data, p, sgc);
    }
    return retval;
}

static int FindMaskOffset(word nMask)
{
    int i;

    for (i = 0; i < 16; i++, nMask >>= 1)
        if (nMask & 1)
            break;

    return i;
}

static Boolean SprmCMajority(CHP *chp, word cch, byte *pData)
{
    /*
     * "The parameter of sprmCMajority (opcode 0xCA47) is itself a list
     * of character sprms which encodes a criterion under which certain fields
     * of the chp are to be set equal to the values stored in a style's CHP.
     * Bytes 0 and 1 of sprmCMajority contains the opcode, byte 2 contains the
     * length of the following list of character sprms. . Word begins
     * interpretation of this sprm by applying the stored character sprm list
     * to a standard chp. That chp has chp.istd = istdNormalChar. chp.hps=20,
     * chp.lid=0x0400 and chp.ftc = 4. Word then compares fBold, fItalic,
     * fStrike, fOutline, fShadow, fSmallCaps, fCaps, ftc, hps, hpsPos, kul,
     * qpsSpace and ico in the original CHP with the values recorded for these
     * fields in the generated CHP.. If a field in the original CHP has the
     * same value as the field stored in the generated CHP, then that field is
     * reset to the value stored in the style's CHP. If the two copies differ,
     * then the original CHP value is left unchanged. sprmCMajority is stored
     * only in grpprls linked to piece table entries."
     *
     * As of this moment, the following code does not produce the correct
     * results.  The reason for this is unknown, and I'm going to just let
     * it go at that, since I've spent far too much time trying to figure out
     * what Microsoft is REALLY doing with this sprm. - DH 12/6/99
     */

    Boolean retval = TRUE;
    CHP chpStd;

//    retval = StyleGetPara(stiNormal, NULL, &chpStd)
//      && StyleGetChar(10, &chpStd);
    DefaultGetCharAttrs(&chpStd);
    chpStd.ftc = 4;
    if (retval)
        retval = SprmReadGrpprlMem(pData, cch, &chpStd, SGC_CHP);
    if (retval)
    {
        if (chp->fBold == chpStd.fBold)
            chp->fBold = sInputStyleChp.fBold;
        if (chp->fItalic == chpStd.fItalic)
            chp->fItalic = sInputStyleChp.fItalic;
        if (chp->fStrike == chpStd.fStrike)
            chp->fStrike = sInputStyleChp.fStrike;
        if (chp->fOutline == chpStd.fOutline)
            chp->fOutline = sInputStyleChp.fOutline;
        if (chp->fShadow == chpStd.fShadow)
            chp->fShadow = sInputStyleChp.fShadow;
        if (chp->fSmallCaps == chpStd.fSmallCaps)
            chp->fSmallCaps = sInputStyleChp.fSmallCaps;
        if (chp->fCaps == chpStd.fCaps)
            chp->fCaps = sInputStyleChp.fCaps;
        if (chp->ftc == chpStd.ftc)
            chp->ftc = sInputStyleChp.ftc;
        if (chp->hps == chpStd.hps)
            chp->hps = sInputStyleChp.hps;
        if (chp->hpsPos == chpStd.hpsPos)
            chp->hpsPos = sInputStyleChp.hpsPos;
        if (chp->kul == chpStd.kul)
            chp->kul = sInputStyleChp.kul;
        if (chp->ico == chpStd.ico)
            chp->ico = sInputStyleChp.ico;
    }
    
    return retval;
}

static Boolean SprmPHugePapx(FC fc, void *p)
{
    word cb;
    
    /* Make sure we have a data stream to read. */
    if (hInputDataStream == NullHandle)
        return FALSE;

    /* Seek the passed FC in the data stream. */
    SEEKA(hInputDataStream, fc);
    
    /* The first word contains the byte length of the grpprl. */
    READV(hInputDataStream, cb);

    /* Let the normal sprm reader take things from here. */
    return SprmReadGrpprl(hInputDataStream, cb, p, SGC_PAP);
}

#define PCHP(p) ( (CHP *)(p) )
#define PPAP(p) ( (PAP *)(p) )
#define PSEP(p) ( (SEP *)(p) )

Boolean SprmProcess(word op, word cch, byte *pData, void *p, ushort sgc)
{
    int i, j, pos, count;
    SprmTableEntry *pEntry;
    Boolean retval = TRUE;
    
    if (WORD_TO_SPRM(op).sgc != sgc)
        return retval;

    switch (op)
    {
    /**** Paragraph SPRMs ****/
    case SPRM_PIstd:
        retval = StyleGetPara(*(word *)pData, p, NULL);
        break;
    case SPRM_PIncLvl:
        if (PPAP(p)->istd >= 1 && PPAP(p)->istd <= 9)
        {
            ushort istd = PPAP(p)->istd + (sbyte)*pData;
            if (istd < 1)
                istd = 1;
            else if (istd > 9)
                istd = 9;
            PPAP(p)->istd = istd;
            PPAP(p)->lvl += (sbyte)*pData;
            retval = StyleGetPara(istd, p, NULL);
        }
        break;
    case SPRM_PIlfo:
        if (cch >= 2 && *((short *)pData) != 2047)
        {
            PPAP(p)->ilfo = *((short *)pData);
            // This works on the assumption that the value for pap.ilvl has
            // already been set.
            retval = ListApplyPapx(PPAP(p));
        }
        break;
    case SPRM_PChgTabsPapx:
        if (cch >= 2)
        {
            count = *(pData++);
            for (i = 0; i < count; i++)
            {
                pos = ((short *)pData)[i];
                for (j = 0; j < PPAP(p)->itbdMac; j++)
                    if (PPAP(p)->rgdxaTab[j] == pos)
                        break;
                if (j < PPAP(p)->itbdMac)
                {
                    PPAP(p)->itbdMac --;
                    while (j < PPAP(p)->itbdMac)
                    {
                        PPAP(p)->rgdxaTab[j] = PPAP(p)->rgdxaTab[j + 1];
                        PPAP(p)->rgtbd[j] = PPAP(p)->rgtbd[j + 1];
                        j ++;
                    }
                }
            }
            pData += count * sizeof(short);
            count = *(pData++);
            for (i = 0; i < count; i++)
            {
                pos = ((short *)pData)[i];
                for (j = PPAP(p)->itbdMac; j > 0; j--)
                {
                    if (pos > PPAP(p)->rgdxaTab[j - 1])
                        break;
                    PPAP(p)->rgdxaTab[j] = PPAP(p)->rgdxaTab[j - 1];
                    PPAP(p)->rgtbd[j] = PPAP(p)->rgtbd[j - 1];
                }
                PPAP(p)->rgdxaTab[j] = pos;
                PPAP(p)->rgtbd[j] = pData[count * sizeof(short) + i];
                PPAP(p)->itbdMac ++;
            }
        }
        break;
    case SPRM_PChgTabs:
        if (cch >= 2)
        {
            count = *(pData++);
            for (i = 0; i < count; i++)
            {
                short close = ((short *)pData)[count * sizeof(short) + i];
                pos = ((short *)pData)[i];
                for (j = 0; j < PPAP(p)->itbdMac; j++)
                    if (PPAP(p)->rgdxaTab[j] >= pos - close)
                        break;
                while (j < PPAP(p)->itbdMac
                  && PPAP(p)->rgdxaTab[j] <= pos + close)
                {
                    int k;
                    PPAP(p)->itbdMac --;
                    for (k = j; k < PPAP(p)->itbdMac; k++)
                    {
                        PPAP(p)->rgdxaTab[k] = PPAP(p)->rgdxaTab[k + 1];
                        PPAP(p)->rgtbd[k] = PPAP(p)->rgtbd[k + 1];
                    }
                }
            }
            pData += count * sizeof(short) * 2;
            count = *(pData++);
            for (i = 0; i < count; i++)
            {
                pos = ((short *)pData)[i];
                for (j = PPAP(p)->itbdMac; j > 0; j--)
                {
                    if (pos > PPAP(p)->rgdxaTab[j - 1])
                        break;
                    PPAP(p)->rgdxaTab[j] = PPAP(p)->rgdxaTab[j - 1];
                    PPAP(p)->rgtbd[j] = PPAP(p)->rgtbd[j - 1];
                }
                PPAP(p)->rgdxaTab[j] = pos;
                PPAP(p)->rgtbd[j] = pData[count * sizeof(short) + i];
                PPAP(p)->itbdMac ++;
            }
        }
        break;
    case SPRM_POutLvl:
        if (PPAP(p)->istd >= 1 && PPAP(p)->istd <= 9)
            PPAP(p)->lvl = *pData;
        break;
    case SPRM_PHugePapx:
        retval = SprmPHugePapx(*(FC *)(pData), p);
        break;

    /***** Character SPRMs *****/
    case SPRM_CChs:
        if (cch >= 3)
        {
            PCHP(p)->fChsDiff = pData[0];
            PCHP(p)->chse = *(word *)(pData + 1);
        }
        break;
    case SPRM_CSymbol:
        if (cch >= 4)
        {
            PCHP(p)->ftcSym = *(word *)pData;
            PCHP(p)->xchSym = *(word *)(pData + 2);
            PCHP(p)->fSpec = 1;
        }
        break;
    case SPRM_CIstd:
        retval = StyleGetPara(hInputStyle, NULL, p)
          && StyleGetChar(*(word *)pData, p);
        sInputStyleChp = *PCHP(p);
        break;
    case SPRM_CDefault:
        PCHP(p)->fBold = 0;
        PCHP(p)->fItalic = 0;
        PCHP(p)->fOutline = 0;
        PCHP(p)->fStrike = 0;
        PCHP(p)->fShadow = 0;
        PCHP(p)->fSmallCaps = 0;
        PCHP(p)->fCaps = 0;
        PCHP(p)->fVanish = 0;
        PCHP(p)->kul = 0;
        PCHP(p)->ico = 0;
        break;
    case SPRM_CPlain:
        i = PCHP(p)->fSpec;
        /* Load *p with the style sheet CHP. */
        retval = StyleGetPara(hInputStyle, NULL, p);
        PCHP(p)->fSpec = i;
        break;
    case SPRM_CMajority:
        if (cch > 1)
            retval = SprmCMajority(PCHP(p), cch, pData);
        break;

    /***** Default handler for field replacement *****/
    default:
        switch (sgc)
        {
        case SGC_CHP:
            pEntry = MemLockFixedOrMovable(SprmChpxTable);
            count = ARRAY_LEN(SprmChpxTable, SprmTableEntry);
            break;
        case SGC_PAP:
            pEntry = MemLockFixedOrMovable(SprmPapxTable);
            count = ARRAY_LEN(SprmPapxTable, SprmTableEntry);
            break;
        case SGC_SEP:
            pEntry = MemLockFixedOrMovable(SprmSepxTable);
            count = ARRAY_LEN(SprmSepxTable, SprmTableEntry);
            break;
        default:
            return retval;
        }
        for (i = 0; i < count; i++, pEntry ++)
            if (pEntry->STE_opcode == (byte)(WORD_TO_SPRM(op).ispmd))
                break;

        if (i != count)     /* opcode was found */
        {
            byte *pField = (byte *)p + pEntry->STE_offset;
            word nExtra = pEntry->STE_extra;
            word value = *pData;
        
            switch (WORD_TO_SPRM(op).spra)
            {
                case SPRA_BIT:  /* STE_extra is the bit mask */
                    if (value & 0x80)
                    {
                        if (value & 0x7f)
                            *pField ^= nExtra;
                    }
                    else if (value)
                        *pField |= nExtra;
                    else
                        *pField &= ~nExtra;
                    break;
                case SPRA_BYTE: /* if nonzero, STE_extra is the field mask */
                    if (nExtra)
                    {
                        int n = FindMaskOffset(nExtra);

                        *pField &= ~nExtra;
                        *pField |= (value << n) & nExtra;
                    }
                    else
                        *pField = value;
                    break;
                default:        /* all other cases, copy byte for byte */
                    memcpy(pField, pData, cch);
            }
        }
        switch (sgc)
        {
        case SGC_CHP:
            MemUnlockFixedOrMovable(SprmChpxTable);
            break;
        case SGC_PAP:
            MemUnlockFixedOrMovable(SprmPapxTable);
            break;
        case SGC_SEP:
            MemUnlockFixedOrMovable(SprmSepxTable);
            break;
        }
    }

    return retval;
}
    

