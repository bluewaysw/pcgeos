
#include <file.h>

#define EOF (-1)

void InputInit(FileHandle fh);
int InputGet(void);
void InputUnGet(char c);
Boolean InputEof(void);
