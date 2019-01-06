/*
        GSOL.H

        <G>raphics <S>tring <O>wner <L>ink specification
*/

#ifndef __GSOL_H
#define __GSOL_H

typedef struct {
  dword          GSOLC_magic;           /* GSOL_START or GSOL_END */
  GeodeToken     GSOLC_creatorToken;    /* token of creator application */
  ProtocolNumber GSOLC_creatorProtocol; /* protocol level used in GString */
} GSOLComment;

#define GSOL_START 0x4CCF53C7           /* "GSOL" with Bit 7 of G and O set */
#define GSOL_END   0xCC4FD347           /* "GSOL" with Bit 7 of S and L set */

word _pascal GSOLMarkGStringStart(
  GStateHandle gs, GeodeToken *token, word PN_major, word PN_minor);
word _pascal GSOLMarkGStringEnd(
  GStateHandle gs, GeodeToken *token, word PN_major, word PN_minor);
word _pascal GSOLCheckGString(
  GStateHandle gs, GeodeToken *token,
  ProtocolNumber *prot, void *retbuf, word bufsize);
word _pascal GSOLIdentifyGString(
  GStateHandle gs, GeodeToken *token, ProtocolNumber *prot);

#define GSOL_ERROR_GENERAL   1
#define GSOL_ERROR_NO_OWNER  2  /* GString doesn't contain any GSOL comment */
#define GSOL_ERROR_OTHER_APP 3  /* GString contains GSOL from other creator */
#define GSOL_ERROR_AMBIGUOUS 4  /* GS contains GSOL comments of multiple apps */
#define GSOL_ERROR_MULTIPLE  5  /* GS contains multiple objects of this app */
#define GSOL_ERROR_TRUNCATED 6  /* GS contains unmatched START/END pair */
#define GSOL_ERROR_NO_DATA   7  /* app-specific data comment missing */

#endif
