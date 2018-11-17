#include <geos.h>
#include <heap.h>
#include <lmem.h>
#include <initfile.h>
#include <system.h>
#include <Ansi/string.h>

char *GetInitStringOrDefault(optr oCategory, optr oKey, char *pBuffer,
                             int nBuflen, optr oDefault)
{
    char *pCategory, *pKey;
    word size;

    MemLock(HandleOf(oCategory));
    MemLock(HandleOf(oKey));
    
    pCategory = LMemDeref(oCategory);
    pKey = LMemDeref(oKey);
    
    if (InitFileReadStringBuffer(pCategory, pKey, pBuffer, 
      (InitFileReadFlags)nBuflen, &size))
    {
        /* The key is not present or an error occurred, use the default. */
        char *pDefault;
        
        MemLock(HandleOf(oDefault));
        pDefault = LMemDeref(oDefault);
        strncpy(pBuffer, pDefault, nBuflen - 1);

        /* Write the default to init. */
        InitFileWriteString(pCategory, pKey, pDefault);

        MemUnlock(HandleOf(oDefault));
    }
    MemUnlock(HandleOf(oCategory));
    MemUnlock(HandleOf(oKey));
    
    return pBuffer;
}

word GetInitIntegerOrDefault(optr oCategory, optr oKey, word nDefault)
{
    char *pCategory, *pKey;
    word retval;

    MemLock(HandleOf(oCategory));
    MemLock(HandleOf(oKey));
    
    pCategory = LMemDeref(oCategory);
    pKey = LMemDeref(oKey);
    
    if (InitFileReadInteger(pCategory, pKey, &retval))
    {
        /* The key is not present or an error occurred, use the default. */
        retval = nDefault;

        /* Write the default to init. */
        InitFileWriteInteger(pCategory, pKey, retval);
    }
    MemUnlock(HandleOf(oCategory));
    MemUnlock(HandleOf(oKey));
    
    return retval;
}
