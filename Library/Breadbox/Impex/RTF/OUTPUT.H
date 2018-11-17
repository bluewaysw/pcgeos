#ifndef _OUTPUT_H
#define _OUTPUT_H
#define OUTPUT_BUFFER_LEN 127

Boolean RTFOutputInit(FileHandle fh);
Boolean RTFOutputAddChar(unsigned char c);
Boolean RTFOutputAddString(char* pString);
Boolean RTFOutputAddEncodedString(char* pString);
Boolean RTFOutputAddControl(char* pString, Boolean bAddSpace);
Boolean RTFOutputAddControlParameter(char* pString, long int nParam,
  Boolean bAddSpace);
Boolean RTFOutputFlush(void);
dword RTFOutputGetPos(void);
void RTFOutputFree(void);
void RTFOutputStartOfHyperlink(word contextToken, word contextFileToken);
void RTFOutputEndOfHyperlink(void);
void RTFOutputStartOfContextRange(void);
void RTFOutputEndOfContextRange(void);

typedef struct
    {
    byte OBS_nCount;
    char OBS_cData[OUTPUT_BUFFER_LEN + 3];
    }
OutputBufferStruct;
#endif /* OUTPUT_H */
