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
 * File:    style.c
 *
 ***************************************************************************/

#include <geos.h>
#include <heap.h>
#include <lmem.h>
#include <chunkarr.h>
#include <ec.h>
#include <Ansi/string.h>
#include "structs.h"
#include "global.h"
#include "sprm.h"
#include "warnings.h"

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

MemHandle hStyles = NullHandle;
ChunkHandle cStyleArray = NullChunk;
ChunkHandle cStyleIndexArray = NullChunk;

/* Maximum number of expanded styles to hold in the cache. */
#define STYLE_CACHE_EXPANDED_MAX    20

typedef struct {
    LMemBlockHeader SH_meta;
    STSHI           SH_stshi;
} StyleHeader;

typedef struct {
    word    SE_cbStd;      // size of the STD structure
    FC      SE_pos;        // position in table stream of STD structure
} StyleElement;

#define STYLE_ELEMENT_SIZE_NULL     2
#define STYLE_ELEMENT_SIZE_UNLOADED ( sizeof(StyleElement) + sizeof(STD) )

#define PSE_STD(p) ( (STD *)((byte *)(p) + sizeof(StyleElement)) )
#define PSE_PAP(p) ( (PAP *)((byte *)(p) + STYLE_ELEMENT_SIZE_UNLOADED) )
#define PSE_CHP(p) ( (CHP *)((byte *)(p) + STYLE_ELEMENT_SIZE_UNLOADED + sizeof(PAP)) )
#define PSE_CHPX(p) ( (UPD *)((byte *)(p) + STYLE_ELEMENT_SIZE_UNLOADED) )

/* Routine to initialize the style cache */
Boolean StyleInit(void)
{
    ushort *pistd;
    int i;
    
    hStyles = MemAllocLMem(LMEM_TYPE_GENERAL, sizeof(StyleHeader));
    if (hStyles == NullHandle) {
	SetError(TE_OUT_OF_MEMORY);
        return FALSE;
    }

    MemLock(hStyles);

    // Create index array, initialize to CA_NULL_ELEMENT
    cStyleIndexArray = LMemAlloc(hStyles,
      sizeof(ushort) * STYLE_CACHE_EXPANDED_MAX);

    pistd = LMemDerefHandles(hStyles, cStyleIndexArray);
    for (i = 0; i < STYLE_CACHE_EXPANDED_MAX; i++, pistd++)
        *pistd = CA_NULL_ELEMENT;

    // Create style array
    cStyleArray = ChunkArrayCreate(hStyles, 0, 0, 0);
    
    MemUnlock(hStyles);

    return TRUE;
}

/* Routine to free the style cache */
void StyleFree(void)
{
    if (hStyles) {
	MemFree(hStyles);
	hStyles = NullHandle;
    }
}

/* Routine to read the styles */
Boolean StyleRead(void)
{
    Boolean retval = TRUE;
    word cbStshi, cbStd, cb;
    StyleHeader *psh = MemLock(hStyles);

    if (READV(hInputTableStream, cbStshi) && cbStshi >= sizeof(STSHI)
      && READ(hInputTableStream, &psh->SH_stshi, sizeof(STSHI))
      && SEEKR(hInputTableStream, cbStshi - sizeof(STSHI)))
    {
        int i = psh->SH_stshi.cstd;
        while (i-- && retval)
        {
            if (READV(hInputTableStream, cbStd))
            {
                if (cbStd >= sizeof(STD))
                    cb = STYLE_ELEMENT_SIZE_UNLOADED;
                else if (cbStd == 0)
                    cb = STYLE_ELEMENT_SIZE_NULL;
                else
                {
                    EC_WARNING(WFW_WARNING_STYLE_STD_TOO_SMALL);
                    retval = FALSE;
                }
            }
            if (retval)
            {
                StyleElement *pse = ChunkArrayAppendHandles(hStyles,
                  cStyleArray, cb);
                if (cbStd)
                {
                    pse->SE_cbStd = cbStd;
                    pse->SE_pos = StgStreamPos(hInputTableStream);
                    READ(hInputTableStream, PSE_STD(pse), sizeof(STD));
                    SEEKR(hInputTableStream, cbStd - sizeof(STD));
                }
            }
        }
    }
    MemUnlock(hStyles);

    if (!retval)
	SetError(TE_IMPORT_ERROR);

    return retval;
}

/* Routine to initialize a style by a base style */
void StyleGetBase(ushort istd, ushort istdBase, ushort sgc)
{
    StyleElement *pstd, *pstdBase;
    word cb, cbb;

    if (sgc == sgcPara)
    {
        // Expand std.grupe to hold CHP+PAP
        cb = STYLE_ELEMENT_SIZE_UNLOADED + sizeof(CHP) + sizeof(PAP);
    }
    else if (sgc == sgcChp)
    {
        // Expand std.grupe to cbMaxGrpprlStyleChpx
        cb = STYLE_ELEMENT_SIZE_UNLOADED + cbMaxGrpprlStyleChpx;
    }
    ChunkArrayElementResizeHandles(hStyles, cStyleArray, istd, cb);

    pstd = ChunkArrayElementToPtrHandles(hStyles, cStyleArray, istd, &cb);

    if (sgc == sgcPara)
    {
        if (istdBase != stiNil)
        {
            // Copy stdBase.grupe to std.grupe
            pstdBase = ChunkArrayElementToPtrHandles(hStyles, cStyleArray,
              istdBase, &cbb);
            memcpy(PSE_PAP(pstd), PSE_PAP(pstdBase), sizeof(PAP) + sizeof(CHP));
        }
        else
        {
            DefaultGetParaAttrs(PSE_PAP(pstd));
            DefaultGetCharAttrs(PSE_CHP(pstd));
        }
    }
}

/* Routine to expand a UPX to a UPE. */
Boolean StyleExpand(ushort istd, ushort istdBase, ushort sgc)
{
    StyleElement *pstd;
    word cb, cbb;
    Boolean retval = TRUE;
    word cbGrpprl;
    
    pstd = ChunkArrayElementToPtrHandles(hStyles, cStyleArray, istd, &cb);
    if (sgc == sgcPara)
    {
        // Apply PAPX std.grupx[0] (from doc) to PAP std.grupe[0]
        if (READV(hInputTableStream, cbGrpprl)
          && READV(hInputTableStream, PSE_PAP(pstd)->istd))
            retval = SprmReadGrpprl(hInputTableStream, cbGrpprl - 2,
              PSE_PAP(pstd), SGC_PAP);
        if (retval && (cbGrpprl & 1))
            SEEKR(hInputTableStream, 1);
        // Apply CHPX std.grupx[1] (from doc) to CHP std.grupe[1]
        if (retval && READV(hInputTableStream, cbGrpprl))
            retval = SprmReadGrpprl(hInputTableStream, cbGrpprl,
              PSE_CHP(pstd), SGC_CHP);
    }
    if (sgc == sgcChp)
    {
        // Merge std.grupx[0].chpx.grpprl (from doc) with
        // stdBase.grupe[0].chpx.grpprl into std.grupe[0].chpx.grpprl
        SPRM_Opcode sobase, sodoc;
        Boolean bBase = TRUE, bDoc = TRUE;
        word cbBase = 0, cbDoc = 0;
        byte *pBase, *pNew = (byte *)PSE_CHPX(pstd);

        cb = 0;
        if (istdBase == stiNil)
        {
            pBase = NULL;
            cbb = 0;
        }
        else
        {
            pBase = (byte *)PSE_CHPX(ChunkArrayElementToPtrHandles(hStyles,
              cStyleArray, istdBase, &cbb));
            cbb -= STYLE_ELEMENT_SIZE_UNLOADED;
        }
        READV(hInputTableStream, cbGrpprl);
        
        while (retval && (cbb || cbGrpprl))
        {
            if (bBase && cbb)
            {
                // Read a sprm from the base style.
                sobase = WORD_TO_SPRM(*(((word *)pBase)++));
                cbBase = SprmGetCount(SPRM_TO_WORD(sobase));
                if (!cbBase)
                {
                    cbBase = *(pBase++);
                    cbb --;
                }
                bBase = FALSE;
            }
            if (bDoc && cbGrpprl)
            {
                // Read a sprm from the UPX.
                READV(hInputTableStream, sodoc);
                cbDoc = SprmGetCount(SPRM_TO_WORD(sodoc));
                if (!cbDoc)
                {
                    READV(hInputTableStream, cbDoc);
                    cbGrpprl --;
                }
                bDoc = FALSE;
            }
            if (!cbb || (cbb && cbGrpprl && sodoc.ispmd <= sobase.ispmd))
            {
                // Copy sprm from the UPX.
                *(((word *)pNew)++) = SPRM_TO_WORD(sodoc);
                if (sodoc.spra == SPRA_VAR)
                {
                    *(pNew++) = cbDoc;
                    cb ++;
                }
                READ(hInputTableStream, pNew, cbDoc);
                cb += cbDoc + 2;
                pNew += cbDoc;
                cbGrpprl -= cbDoc + 2;
                bDoc = TRUE;
                if (cbb && cbGrpprl && sodoc.ispmd == sobase.ispmd)
                {
                    // The UPX sprm overrides the same base sprm.
                    pBase += cbBase;
                    cbb -= cbBase + 2;
                    bBase = TRUE;
                }                    
            }
            else if (!cbGrpprl || (cbb && cbGrpprl && sodoc.ispmd >= sobase.ispmd))
            {
                // Copy sprm from the base.
                *(((word *)pNew)++) = SPRM_TO_WORD(sobase);
                if (sobase.spra == SPRA_VAR)
                {
                    *(pNew++) = cbBase;
                    cb ++;
                }
                memcpy(pNew, pBase, cbBase);
                cb += cbDoc + 2;
                pBase += cbBase;
                cbb -= cbBase + 2;
                bBase = TRUE;
            }
            if (cb > cbMaxGrpprlStyleChpx)
            {
                EC_WARNING(WFW_WARNING_CHAR_STYLE_TOO_LARGE);
                retval = FALSE;
            }
        }
        if (!retval)
            cb = 0;
        // Resize element to length of new grpprl
        ChunkArrayElementResizeHandles(hStyles, cStyleArray, istd,
          STYLE_ELEMENT_SIZE_UNLOADED + cb);
    }

    if (!retval)
	SetError(TE_IMPORT_ERROR);

    return retval;
}

/* Routine to determine if istd is a valid style. */
Boolean StyleIsValid(ushort istd, ushort sgc)
{
    Boolean retval = TRUE;
    StyleElement *pstd;
    StyleHeader *psh;
    word cb;

    if (istd == stiNil)
        return FALSE;
        
    psh = MemLock(hStyles);
    
    // Is the istd in the bounds of the array?
    if (istd >= psh->SH_stshi.cstd)
    {
        EC_WARNING(WFW_WARNING_INVALID_ISTD);
        retval = FALSE;
    }

    // Does the istd have any style data?
    if (retval)
    {
        pstd = ChunkArrayElementToPtrHandles(hStyles, cStyleArray, istd, &cb);
        if (cb == STYLE_ELEMENT_SIZE_NULL)
        {
            EC_WARNING(WFW_WARNING_INVALID_ISTD);
            retval = FALSE;
        }
    }

    // Do the style types match?
    if (retval)
    {
        if (PSE_STD(pstd)->sgc != sgc)
        {
            EC_WARNING(WFW_WARNING_STYLE_WRONG_TYPE);
            retval = FALSE;
        }
    }

    MemUnlock(hStyles);
    return retval;
}

/* Routine to unload a style */
void StyleUnload(ushort istd)
{
    word cb;
    
    // Simply truncate the element to the unloaded size.
    if (ChunkArrayElementToPtrHandles(hStyles, cStyleArray, istd, &cb)
      > STYLE_ELEMENT_SIZE_UNLOADED)
        ChunkArrayElementResizeHandles(hStyles, cStyleArray, istd,
          STYLE_ELEMENT_SIZE_UNLOADED);
}
    
/* Routine to load a style */
Boolean StyleLoad(ushort istd, Boolean *pbWasLoaded)
{
    Boolean retval = TRUE;
    StyleHeader *psh = MemLock(hStyles);
    word cb;
    StyleElement *pstd;
    ushort sgc;

    // If style element istd needs to be loaded:
    pstd = ChunkArrayElementToPtrHandles(hStyles, cStyleArray, istd, &cb);
    sgc = PSE_STD(pstd)->sgc;
    if (cb == STYLE_ELEMENT_SIZE_NULL)
    {
        EC_WARNING(WFW_WARNING_INVALID_ISTD);
        SetError(TE_IMPORT_ERROR);
        retval = FALSE;
    }
    else if (sgc > sgcChp)
    {
        EC_WARNING(WFW_WARNING_INVALID_SGC);
        SetError(TE_IMPORT_ERROR);
        retval = FALSE;
    }
    else if (cb == STYLE_ELEMENT_SIZE_UNLOADED)
    {
        // stdBase = Load style std.istdBase (nop if stiNil)
        ushort istdBase = PSE_STD(pstd)->istdBase;
        Boolean bWasLoaded = FALSE;

        if (istdBase != stiNil && StyleIsValid(istdBase, sgc))
            retval = StyleLoad(istdBase, &bWasLoaded);
        else
            istdBase = stiNil;

        // Seek to std.grupx
        if (retval)
        {
            word cbname;
            pstd = ChunkArrayElementToPtrHandles(hStyles, cStyleArray,
              istd, &cb);
            psh = MemDeref(hStyles);
            // Skip the base STD and the variable length style name
            if (SEEKA(hInputTableStream, pstd->SE_pos +
              psh->SH_stshi.cbSTDBaseInFile)
              && READV(hInputTableStream, cbname))
                SEEKR(hInputTableStream, (cbname + 1) * 2);
        }

        if (retval)
        {
            // Initialize std by stdBase
            StyleGetBase(istd, istdBase, sgc);

            // Expand std.grupx[] (from doc) to std.grupe[] (in ram)
            retval = StyleExpand(istd, istdBase, sgc);
        }

        // Unload std.istdBase (nop if stiNil **OR CACHED**)
        if (!bWasLoaded && istdBase != stiNil)
            StyleUnload(istdBase);
    }
    else
    {
        // Indicate that style was already loaded.
        if (pbWasLoaded != NULL)
            *pbWasLoaded = TRUE;
    }

    MemUnlock(hStyles);
    if (!retval)
	SetError(TE_IMPORT_ERROR);
    return retval;
}

Boolean StyleCache(ushort istd)
{
    word i;
    Boolean retval = TRUE;
    ushort *pistd, istdLast;

    MemLock(hStyles);

    // Search the index array for this style.
    pistd = LMemDerefHandles(hStyles, cStyleIndexArray);
    for (i = 0; i < STYLE_CACHE_EXPANDED_MAX; i++, pistd++)
        if (*pistd == istd)
            break;

    if (i == STYLE_CACHE_EXPANDED_MAX)
    {
        // Unload the last style in the array.
        pistd = LMemDerefHandles(hStyles, cStyleIndexArray);
        istdLast = pistd[STYLE_CACHE_EXPANDED_MAX - 1];
        if (istdLast != CA_NULL_ELEMENT)
        {
            pistd[STYLE_CACHE_EXPANDED_MAX - 1] = CA_NULL_ELEMENT;
            StyleUnload(istdLast);
        }
        // Now load the new style.
        if ((retval = StyleLoad(istd, NULL)) != FALSE)
        {
            pistd = LMemDerefHandles(hStyles, cStyleIndexArray);
            // Insert the style into the index array.
            for (i = STYLE_CACHE_EXPANDED_MAX - 1; i > 0; i--)
                pistd[i] = pistd[i - 1];
            *pistd = istd;
        }
    }
    MemUnlock(hStyles);
    return retval;
}        

/* Routine to get a PAP/CHP for a paragraph style. */
Boolean StyleGetPara(ushort istd, PAP *pPap, CHP *pChp)
{
    // Cache paragraph style istd
    Boolean retval = TRUE;

    if (StyleIsValid(istd, SGC_PAP))
    {
        if ((retval = StyleCache(istd)) != FALSE)
        {
            word cb;
            StyleElement *pstd;

            MemLock(hStyles);
            pstd = ChunkArrayElementToPtrHandles(hStyles,
              cStyleArray, istd, &cb);

            // Load UPE#1 into PAP
            if (pPap != NULL)
                memcpy(pPap, PSE_PAP(pstd), sizeof(PAP));
        
            // Load UPE#2 into CHP
            if (pChp != NULL)
                memcpy(pChp, PSE_CHP(pstd), sizeof(CHP));

            MemUnlock(hStyles);
        }
    }
    else
    {
        if (pPap != NULL)
            DefaultGetParaAttrs(pPap);
        if (pChp != NULL)
            DefaultGetCharAttrs(pChp);
    }

    return retval;
}

/* Routine to apply a CHPX for a character style. */
Boolean StyleGetChar(ushort istd, CHP *pChp)
{
    Boolean retval = TRUE;

    if (StyleIsValid(istd, SGC_CHP))
    {
        // Cache character style istd
        if ((retval = StyleCache(istd)) != FALSE)
        {
            word cb;
            StyleElement *pstd;

            MemLock(hStyles);
            pstd = ChunkArrayElementToPtrHandles(hStyles,
              cStyleArray, istd, &cb);

            // Apply UPE#1 to CHP
            cb -= STYLE_ELEMENT_SIZE_UNLOADED;
            retval = SprmReadGrpprlMem(PSE_CHPX(pstd), cb, pChp, SGC_CHP);
      
            MemUnlock(hStyles);
        }
    }
    return retval;
}

