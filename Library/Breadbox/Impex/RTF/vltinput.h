#define EOT (0)

/* Initialize input routines. */
Boolean VLTInputInit(optr oText);
/* Release resources. */
void VLTInputFree(void);

/* Get the next character. */
char VLTInputGetChar(void);

/*  Get the element token of a run for the next character. */
/*  NOTE: Token routines will return the token used by the character which
    was last returned by VLTInputGetChar.  Calling order is important! */
word VLTInputGetCharToken(void);
word VLTInputGetParaToken(void);
word VLTInputGetTypeToken(void);
word VLTInputGetGraphicToken(void);

/* future expansion
word VLTInputGetGraphicToken(void);
word VLTInputGetTypeToken(void);
word VLTInputGetRegionToken(void);
word VLTInputGetStyleToken(void);
*/

/*  Lock an element by token and get a pointer to it. */
/*  NOTE: The handle returned must be VMUnlock'd when access to the structure
    is finished. After unlocking, the pointer is invalid. May be called in a
    loop without repeatedly locking/unlocking by passing the same MemHandle
    pointer, setting it to NullHandle before the loop, and VMUnlock after. */
VisTextCharAttr* VLTInputGetCharAttrByToken(word token, MemHandle* phMem);
VisTextParaAttr* VLTInputGetParaAttrByToken(word token, MemHandle* phMem);
VisTextType* VLTInputGetTypeAttrByToken(word token, MemHandle* phMem);
VisTextGraphic* VLTInputGetGraphicByToken(word token, MemHandle* phMem);

/*	Directly jump to the next used element token in an element array. */
word VLTInputGetNextCharToken(MemHandle* mem);
word VLTInputGetNextParaToken(MemHandle* mem);

/* Reached end of text? */
Boolean VLTInputEOT(void);
