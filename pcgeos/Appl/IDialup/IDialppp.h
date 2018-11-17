#ifndef __IDIALUP_H_
#define __IDIALUP_H_

extern void
    _pascal PPPFuncs (unsigned char *data, word libHandle, word funcNum);

#ifdef __HIGHC__
pragma Alias(PPPFuncs, "PPPFUNCS");
#endif /* __HIGHC__ */

#endif
