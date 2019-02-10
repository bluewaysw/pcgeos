#include <geos.h>

typedef sword CABICallBack(void *pElement, void *pData);

void NormalizeName(char *name, char *normal);
word NormalizedCompare(char *str1, char *str2);
void RoastPassword(char *password, char *roasted);
void RemoveHTML(char *in, char *out);
Boolean ParseArgs(char *args, word num, char **argv);
Boolean PrependUsername(MemHandle text, char *username);
void *ChunkArrayBInsert(optr array, void *pData, CABICallBack *pCBF);

