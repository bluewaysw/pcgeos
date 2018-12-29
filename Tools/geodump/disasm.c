/*
   ESDE 0.92� (pre-release for GeoDump 0.5)
   Embedded Segment Disassembler Engine

   by Marcus Gr�ber 1993-94, based on original 2asm sourcecode
   This code was last compiled on MSC7, but it should be fairly easy to port...

   Being a GNU type thing, the license below is inherited for this code. :-)

   Anyway, if you plan to use this engine in your own code, I'd ask you to
   contact me anyway, because I'm planning to release it as a separate
   piece of code with a clearly defined interface to the symbol and fixup
   callbacks.

   Fido: 2:243/8605.1 - Internet: marcusg@ph-cip.uni-koeln.de

  -----------------------------------------------------------------------------
   Original copyright notes & remarks follow:
  -----------------------------------------------------------------------------

   2asm: Convert binary files to 80*86 assembler. Version 1.00

License:

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

Comments:

   The code was originally snaffled from the GNU C++ debugger, as ported
   to DOS by DJ Delorie and Kent Williams (williams@herky.cs.uiowa.edu).
   Extensively modified by Robin Hilliard in Jan and May 1992.

   This source compiles under Turbo C v2.01.  The disassembler is entirely
   table driven so it's fairly easy to change to suit your own tastes.

   The instruction table has been modified to correspond with that in
   `Programmer's Technical Reference: The Processor and Coprocessor',
   Robert L. Hummel, Ziff-Davis Press, 1992.  Missing (read "undocumented")
   instructions were added and many mistakes and omissions corrected.

   [Command line switches ommitted... @mg@]

Health warning:

   When writing and degbugging this code, I didn't have (and still don't have)
   a 32-bit disassembler to compare this guy's output with.  It's therefore
   quite likely that bugs will appear when disassembling instructions which use
   the 386 and 486's native 32 bit mode.  It seems to work fine in 16 bit mode.

Any comments/updates/bug reports to:

   Robin Hilliard, Lough Guitane, Killarney, Co. Kerry, Ireland.
   Tel:         [+353] 64-54014
   Internet:    softloft@iruccvax.ucc.ie
   Compu$erve:  100042, 1237

   If you feel like registering, and possibly get notices of updates and
   other items of software, then send me a post card of your home town.

   Thanks and enjoy!

------------------------------------------------------------------------------*/

/* Code starts here... */

#include <stdio.h>
#include <string.h>
#include <setjmp.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>


/*
 * prototypes for "callback routines" - these must be defined in the
 * main program to adapt the disassembler for the various possibles uses...
 */
char *   create_label(unsigned short seg,unsigned short ofs,char type);
char *   test_fixup(unsigned short ofs, unsigned short type, unsigned char *buf,int addinfo);
unsigned test_jmplist(unsigned ofs,unsigned *label,int *addinfo);
unsigned enumerate_global_jmp(unsigned short n,unsigned short *ofs);
int      test_data_map(unsigned short ofs);
void     prepost_hook(unsigned short ofs,unsigned short len,int silent_run,int type);


typedef unsigned int word32;
typedef unsigned short word16;
typedef unsigned char word8;
typedef signed int int32;
typedef signed short int16;
typedef signed char int8;

typedef union {
  struct {
    word16 ofs;
    word16 seg;
  } w;
  word32 dword;
} WORD32;

/* variables controlled by command line flags */
static int8  seg_size=16;   /* default size is 16 */
static int8  do_hex = 0;    /* default is to use reassemblable instructions */
static int8  do_distance = 1; /* default is to use jmp length keywords */
static word8 do_emul87 = 0; /* don't try to disassemble emulated instrcutions */
static word8 do_size = 1;   /* default to outputting explicit operand size */
static word8 must_do_size;  /* used with do_size */

static int wordop;           /* dealing with word or byte operand */
static word8 instruction_length;
static instruction_offset;
static word16 done_space; /* for opcodes with > one space */
static word8 patch87;     /* fudge variable used in 8087 emu patching code */

static char ubuf[100], *ubufp, hbuf[40];
static short col;               /* output column */
static short prefix;            /* segment override prefix byte */
static short modrmv;            /* flag for getting modrm byte */
static short sibv;              /* flag for getting sib byte   */
static short opsize;            /* just like it says ...       */
static short addrsize;
static jmp_buf reached_eof; /* jump back when reached eof */

static word8 *code_buf;
static word16 codep,code_len;
static word16 max_jmp;

static int silent_run,cont_flow,data_area,jl_last;
static char jmp_subtype;

/* some defines for extracting instruction bit fields from bytes */

#define MOD(a)	  (((a)>>6)&7)
#define REG(a)	  (((a)>>3)&7)
#define RM(a)	  ((a)&7)
#define SCALE(a)  (((a)>>6)&7)
#define INDEX(a)  (((a)>>3)&7)
#define BASE(a)   ((a)&7)


extern char *opmap1[];      /* stuff from text.c */
extern char *second[];
extern char *groups[][8];
extern char *f0[];
extern char *fop_9[];
extern char *fop_10[];
extern char *fop_12[];
extern char *fop_13[];
extern char *fop_14[];
extern char *fop_15[];
extern char *fop_21[];
extern char *fop_28[];
extern char *fop_32[];
extern char *fop_33[];
extern char *fop_36[];
extern char *fop_37[];
extern char *fop_38[];
extern char *fop_39[];
extern char *fop_40[];
extern char *fop_42[];
extern char *fop_43[];
extern char *fop_44[];
extern char *fop_45[];
extern char *fop_48[];
extern char *fop_49[];
extern char *fop_51[];
extern char *fop_52[];
extern char *fop_53[];
extern char *fop_54[];
extern char *fop_55[];
extern char *fop_60[];
extern char **fspecial[];
extern char *floatops[];


/* prototypes */

static void ua_str(char *);
static word8 unassemble(word16);
static char *addr_to_hex(int32,char);
static word8 getbyte(void);
static word8 silent_getbyte(void);
static word8 silent_returnbyte(word8 );
static modrm(void);
static sib(void);
static void uprintf(char *, ...);
static void uputchar(char );
static int bytes(char );
static void outhex(char , int , int , int , int );
static void reg_name(int , char );
static void do_sib(int );
static void do_modrm(char );
static void floating_point(int );
static void percent(char , char );

static word8 jmp_map[8192];
static word16 jmp_count;

/******************************************************************************/

static void init_jmp_map(void)
{
        jmp_count = 0;                  /* no jump targets in segment yet */
        _fmemset(jmp_map,0,sizeof(jmp_map));
                                        /* reset jump target map */
}

static int test_jmp_map(word16 offset)
{
        return jmp_map[offset>>3] & (1<<(offset & 7));
                                        /* test bit in jump map */
}

static void set_jmp_map(word16 offset)
{
        if(test_jmp_map(offset) == 0)   /* if new target, count it */
          jmp_count++;
        jmp_map[offset>>3] |= (1<<(offset & 7));
                                        /* set bit in jump map */
}
/*------------------------------------------------------------------------*/

static char *addr_to_hex(int32 addr, char splitup)
{
  static char buffer[11];
  WORD32 adr;
  char hexstr[2];

  strcpy(hexstr, do_hex?"h":"");
  adr.dword = addr;
  if (splitup) {
    if (adr.w.seg==0 || adr.w.seg==0xffff) /* 'coz of wraparound */
      sprintf(buffer, "%04X%s", adr.w.ofs, hexstr);
    else
      sprintf(buffer, "%04X%s:%04X%s", adr.w.seg, hexstr, adr.w.ofs, hexstr);
  } else {
    if (adr.w.seg==0 || adr.w.seg==0xffff) /* 'coz of wraparound */
      sprintf(buffer, "%04X%s", adr.w.ofs, hexstr);
    else
      sprintf(buffer, "%08lX%s", addr, hexstr);
  }
  return buffer;
}


static word8 getbyte(void)
{
  int16 c;

  if (codep>=code_len)
    longjmp(reached_eof, 1);
  c = code_buf[codep++];
  sprintf(hbuf+strlen(hbuf),"%02X", c);   /* print out byte */

  if (patch87==1) {
    c -= 0x5C;          /* fixup second byte in emulated '87 instruction */
    if(c==0xFFE0) {     /* segment override */
      patch87 = 2;      /* modified opcode will follow */
      c=0x26 + (((code_buf[codep]>>3)&0x18)^0x18);
                        /* equivalent 8086 override from following byte */
    }
    else
      patch87 = 0;
  }
  else if (patch87==2) {
    c |= 0xD8;          /* fix into floating point opcode */
    patch87 = 0;
  }

  instruction_length++;
  instruction_offset++;
  return (word8)c;
}

/* used for lookahead */
static word8 silent_getbyte(void)
{
  return code_buf[codep++];
}
/* return byte to input stream */
static word8 silent_returnbyte(word8 c)
{
  return code_buf[--codep];
}


/*
   only one modrm or sib byte per instruction, tho' they need to be
   returned a few times...
*/

static modrm(void)
{
  if (modrmv == -1)
    modrmv = getbyte();
  return modrmv;
}


static sib(void)
{
  if (sibv == -1)
    sibv = getbyte();
  return sibv;
}

/*------------------------------------------------------------------------*/

static void uprintf(char *s, ...)
{
  va_list marker;

  va_start(marker,s);
  vsprintf(ubufp, s, marker);
  va_end(marker);
  while (*ubufp)
    ubufp++;
}



static void uputchar(char c)
{
  if (c == '\t') {
    if (done_space) {      /* don't tab out if already done so */
      uputchar(' ');
    } else {
      done_space = 1;
      do {
        *ubufp++ = ' ';
      } while ((ubufp-ubuf) % 8);
    }
  } else
    *ubufp++ = c;
  *ubufp = 0;
}


/*------------------------------------------------------------------------*/
static int bytes(char c)
{
  switch (c) {
  case 'b':
       return 1;
  case 'w':
       return 2;
  case 'd':
       return 4;
  case 'v':
       if (opsize == 32)
         return 4;
       else
         return 2;
  }
  return 0;
}



/*------------------------------------------------------------------------*/
static void outhex(char subtype, int extend, int optional, int defsize, int sign)
{
  int n=0, s=0, i;
  int32 delta;
  unsigned char buff[6];
  char *name;
  char  signchar;
  char *label;
  unsigned start_ofs;

  switch (subtype) {
  case 'q':
       if (wordop) {
         if (opsize==16) {
           n = 2;
         } else {
           n = 4;
         }
       } else {
         n = 1;
       }
       break;

  case 'a':
       break;
  case 'x':
       extend = 2;
       n = 1;
       break;
  case 'b':
       n = 1;
       break;
  case 'w':
       n = 2;
       break;
  case 'd':
       n = 4;
       break;
  case 's':
       n = 6;
       break;
  case 'c':
  case 'v':
       if (defsize == 32)
         n = 4;
       else
         n = 2;
       break;
  case 'p':
       if (defsize == 32)
         n = 6;
       else
         n = 4;
       s = 1;
       break;
  }

  start_ofs = instruction_offset;       /* start of data item in memory */
  for (i=0; i<n; i++)                   /* get data item */
    buff[i] = getbyte();
  if(silent_run>-1 &&
     (label = test_fixup(start_ofs,n,buff,jmp_subtype?0xFFFF:0))) {
                                        /* 0xFFFF indicates that we know we're
                                           dealing with an abs jump adress */
    uprintf(sign?"+%s":"%s",label);
    return;
  }

  for (; i<extend; i++)
    buff[i] = (buff[i-1] & 0x80) ? 0xff : 0;
  if (s) {
    uprintf("%02X%02X:", buff[n-1], buff[n-2]);
    n -= 2;
  }
  switch (n) {
  case 1:
       delta = *(signed char *)buff;
       break;
  case 2:
       delta = *(signed int *)buff;
       break;
  case 4:
       delta = *(signed long *)buff;
       break;
  }
  if (extend > n) {
    if (subtype!='x') {
      if ((long)delta<0) {
        delta = -delta;
        signchar = '-';
      } else
        signchar = '+';
      if (delta || !optional)
        uprintf(do_hex?"%c%0*lX":"%c%0*lXh", signchar, do_hex?extend:extend+1, delta);
    } else {
      if (extend==2)
        delta = (word16) delta;
      uprintf(do_hex?"%0.*lX":"%0.*lXh", 2*extend+1, delta);
/*      uprintf(do_hex?"%0.*lX":"%0.*lXh", 2*(do_hex?extend:extend+1), delta); */
    }
    return;
  }
  if ((n == 4) && !sign) {
    name = addr_to_hex(delta, 0);
    uprintf("%s", name);
    return;
  }
  switch (n) {
  case 1:
       if (sign && (signed char)delta<0) {
         delta = -delta;
         signchar = '-';
       } else
         signchar = '+';
       if (sign)
         uprintf(do_hex?"%c%02X":"%c%03Xh",signchar,(unsigned char)delta);
       else
         uprintf(do_hex?"%02X":"%03Xh", (unsigned char)delta);
       break;

  case 2:
       if (sign && (int)delta<0) {
         signchar = '-';
         delta = -delta;
       } else
         signchar = '+';
       if (sign)
         uprintf(do_hex?"%c%04X":"%c%05Xh", signchar,(int)delta);
       else
         uprintf(do_hex?"%04X":"%05Xh", (unsigned int)delta);
       break;

  case 4:
       if (sign && (long)delta<0) {
         delta = -delta;
         signchar = '-';
       } else
         signchar = '+';
       if (sign)
         uprintf(do_hex?"%c%08X":"%c%09lXh", signchar, (unsigned long)delta);
       else
         uprintf(do_hex?"%08X":"%09lXh", (unsigned long)delta);
       break;
  }
}


/*------------------------------------------------------------------------*/
static void reg_name(int regnum, char size)
{
  if (size == 'F') { /* floating point register? */
    uprintf("st(%d)", regnum);
    return;
  }
  if (((size == 'v') && (opsize == 32)) || (size == 'd'))
    uputchar('e');
  if ((size=='q' || size == 'b' || size=='c') && !wordop) {
    uputchar("acdbacdb"[regnum]);
    uputchar("llllhhhh"[regnum]);
  } else {
    uputchar("acdbsbsd"[regnum]);
    uputchar("xxxxppii"[regnum]);
  }
}


/*------------------------------------------------------------------------*/
static void do_sib(int m)
{
  int s, i, b;

  s = SCALE(sib());
  i = INDEX(sib());
  b = BASE(sib());
  switch (b) {     /* pick base */
  case 0: ua_str("[%p:eax"); break;
  case 1: ua_str("[%p:ecx"); break;
  case 2: ua_str("[%p:edx"); break;
  case 3: ua_str("[%p:ebx"); break;
  case 4: ua_str("[%p:esp"); break;
  case 5:
       if (m == 0) {
         ua_str("[%p:");
         outhex('d', 4, 0, addrsize, 0);
       } else {
         ua_str("%p:[ebp");
       }
       break;
  case 6: ua_str("[%p:esi"); break;
  case 7: ua_str("[%p:edi"); break;
  }
  switch (i) {     /* and index */
  case 0: uprintf("+eax"); break;
  case 1: uprintf("+ecx"); break;
  case 2: uprintf("+edx"); break;
  case 3: uprintf("+ebx"); break;
  case 4: break;
  case 5: uprintf("+ebp"); break;
  case 6: uprintf("+esi"); break;
  case 7: uprintf("+edi"); break;
  }
  if (i != 4) {
    switch (s) {    /* and scale */
      case 0: uprintf(""); break;
      case 1: uprintf("*2"); break;
      case 2: uprintf("*4"); break;
      case 3: uprintf("*8"); break;
    }
  }
}



/*------------------------------------------------------------------------*/
static void do_modrm(char subtype)
{
  int mod = MOD(modrm());
  int rm = RM(modrm());
  int extend = (addrsize == 32) ? 4 : 2;

  if (mod == 3) { /* specifies two registers */
    reg_name(rm, subtype);
    return;
  }
  if (must_do_size) {
    if (wordop) {
      if (addrsize==32 || opsize==32) {       /* then must specify size */
        ua_str("dword ptr ");
      } else {
        ua_str("word ptr ");
      }
    } else {
      ua_str("byte ptr ");
    }
  }
  if ((mod == 0) && (rm == 5) && (addrsize == 32)) {/* mem operand with 32 bit ofs */
    ua_str("[%p!");
    outhex('d', extend, 0, addrsize, 0);
    uputchar(']');
    return;
  }
  if ((mod == 0) && (rm == 6) && (addrsize == 16)) { /* 16 bit dsplcmnt */
    ua_str("[%p!");
    outhex('w', extend, 0, addrsize, 0);
    uputchar(']');
    return;
  }
  if ((addrsize != 32) || (rm != 4))
    ua_str("[%p:");
  if (addrsize == 16) {
    switch (rm) {
    case 0: uprintf("bx+si"); break;
    case 1: uprintf("bx+di"); break;
    case 2: uprintf("bp+si"); break;
    case 3: uprintf("bp+di"); break;
    case 4: uprintf("si"); break;
    case 5: uprintf("di"); break;
    case 6: uprintf("bp"); break;
    case 7: uprintf("bx"); break;
    }
  } else {
    switch (rm) {
    case 0: uprintf("eax"); break;
    case 1: uprintf("ecx"); break;
    case 2: uprintf("edx"); break;
    case 3: uprintf("ebx"); break;
    case 4: do_sib(mod); break;
    case 5: uprintf("ebp"); break;
    case 6: uprintf("esi"); break;
    case 7: uprintf("edi"); break;
    }
  }
  switch (mod) {
  case 1:
       outhex('b', extend, 1, addrsize, 0);
       break;
  case 2:
       outhex('v', extend, 1, addrsize, 1);
       break;
  }
  uputchar(']');
}



/*------------------------------------------------------------------------*/
static void floating_point(int e1)
{
  int esc = e1*8 + REG(modrm());

  if (MOD(modrm()) == 3) {
    if (fspecial[esc]) {
      if (fspecial[esc][0][0] == '*') {
        ua_str(fspecial[esc][0]+1);
      } else {
        ua_str(fspecial[esc][RM(modrm())]);
      }
    } else {
      if(floatops[esc]) {
        ua_str(floatops[esc]);
        ua_str(" %EF");
      }
    }
  } else
    if(floatops[esc]) {
      ua_str(floatops[esc]);
      ua_str(" %EF");
    }
}




/*------------------------------------------------------------------------*/
/* Main table driver                                                      */
static void percent(char type, char subtype)
{
  int32 vofs;
  char *name;
  int extend = (addrsize == 32) ? 4 : 2;
  unsigned char c;

  switch (type) {
  case 'A':                          /* direct address */
       jmp_subtype = subtype;        /* only use in jump adresses */
       switch (subtype) {
       case 'p':
            ua_str("far ptr ");
            break;
       }
       outhex(subtype, extend, 0, addrsize, 0);
       break;

  case 'C':                          /* reg(r/m) picks control reg */
       uprintf("C%d", REG(modrm()));
       must_do_size = 0;
       break;

  case 'D':                          /* reg(r/m) picks debug reg */
       uprintf("D%d", REG(modrm()));
       must_do_size = 0;
       break;

  case 'E':                          /* r/m picks operand */
       do_modrm(subtype);
       break;

  case 'G':                          /* reg(r/m) picks register */
       if (subtype == 'F')           /* 80*87 operand?   */
         reg_name(RM(modrm()), subtype);
       else
         reg_name(REG(modrm()), subtype);
       must_do_size = 0;
       break;

  case 'I':                            /* immed data */
       outhex(subtype, 0, 0, opsize, 0);
       break;

  case 'J':                            /* relative IP offset */
  case 'c':
       switch(bytes(subtype)) {                 /* sizeof offset value */
       case 1:
            vofs = (int8)getbyte();
            break;
       case 2:
            vofs = getbyte();
            vofs += getbyte()<<8;
            vofs = (int16)vofs;
            break;
       case 4:
            vofs = (word32)getbyte();           /* yuk! */
            vofs |= (word32)getbyte() << 8;
            vofs |= (word32)getbyte() << 16;
            vofs |= (word32)getbyte() << 24;
            break;
       }
       if(!silent_run)
         name = create_label(0xFFFF,(unsigned)(vofs+instruction_offset),'H');
       else
         name = "*";
       set_jmp_map((word16)(vofs+instruction_offset));

       if(type=='J' && (word16)(vofs+instruction_offset) > max_jmp)
         max_jmp=(word16)(vofs+instruction_offset);
                                        /* update maximum jump distance */
       uprintf("%s", name);             /* put label into output */
       break;

  case 'K':
       if (do_distance==0)
         break;
       switch (subtype) {
/*
       case 'f':
            ua_str("far ");
            break;
       case 'n':
            ua_str("near ");
            break;
 */
       case 's':
            ua_str("short ");
            must_do_size = 0;
            break;
       }
       break;

  case 'M':                            /* r/m picks memory */
       do_modrm(subtype);
       break;

  case 'O':                            /* offset only */
       ua_str("[%p!");
       outhex(subtype, extend, 0, addrsize, 0);
       uputchar(']');
       break;

  case 'P':                            /* prefix byte (rh) */
       ua_str("%p:");
       break;

  case 'R':                            /* mod(r/m) picks register */
       reg_name(REG(modrm()), subtype);/* rh */
       must_do_size = 0;
       break;

  case 'S':                            /* reg(r/m) picks segment reg */
       uputchar("ecsdfg"[REG(modrm())]);
       uputchar('s');
       must_do_size = 0;
       break;

  case 'T':                            /* reg(r/m) picks T reg */
       uprintf("tr%d", REG(modrm()));
       must_do_size = 0;
       break;

  case 'X':                            /* ds:si type operator */
       uprintf("[ds:");
       if (addrsize == 32)
         uputchar('e');
       uprintf("si]");
       break;

  case 'Y':                            /* es:di type operator */
       uprintf("[es:");
       if (addrsize == 32)
         uputchar('e');
       uprintf("di]");
       break;

  case 'Z':
       cont_flow = 0;                  /* flow of control does not continue */
       break;

  case '2':                            /* old [pop cs]! now indexes */
       ua_str(second[getbyte()]);      /* instructions in 386/486   */
       break;

  case 'g':                            /* modrm group `subtype' (0--7) */
       ua_str(groups[subtype-'0'][REG(modrm())]);
       break;

  case 'd':                             /* sizeof operand==dword? */
       if (opsize == 32)
         uputchar('d');
       uputchar(subtype);
       break;

  case 'w':                             /* insert explicit size specifier */
       if (opsize == 32)
         uputchar('d');
       else
         uputchar('w');
       uputchar(subtype);
       break;

  case 'e':                         /* extended reg name */
       if (opsize == 32) {
         if (subtype == 'w')
           uputchar('d');
         else {
           uputchar('e');
           uputchar(subtype);
         }
       } else
         uputchar(subtype);
       break;

  case 'f':                    /* '87 opcode */
       floating_point(subtype-'0');
       break;

  case 'j':
       if (addrsize==32 || opsize==32) /* both of them?! */
         uputchar('e');
       break;

  case 'p':                    /* prefix byte */
       switch (subtype)  {
       case 'c':
       case 'd':
       case 'e':
       case 'f':
       case 'g':
       case 's':
            prefix = subtype;
            c = getbyte();
            wordop = c & 1;
            if(opmap1[c]!=NULL) ua_str(opmap1[c]);
            break;
       case '!':
            if (prefix==0) prefix='d';
       case ':':
            if (prefix)
              uprintf("%cs:", prefix);
            break;
       case ' ':
            c = getbyte();
            wordop = c & 1;
            ua_str(opmap1[c]);
            break;
       case 'z':                        // ugly fix for assemblers which allow
                                        // repe only with cmps and scas
            c = getbyte();
            uprintf((c==0xa6 || c==0xa7 || c==0xae || c==0xaf)?"e\t":"\t");
            wordop = c & 1;
            ua_str(opmap1[c]);
            break;
       }
       break;

  case 's':                           /* size override */
       switch (subtype) {
       case 'a':
            addrsize = 48 - addrsize;
            c = getbyte();
            wordop = c & 1;
            ua_str(opmap1[c]);
/*            ua_str(opmap1[getbyte()]); */
            break;
       case 'o':
            opsize = 48 - opsize;
            c = getbyte();
            wordop = c & 1;
            ua_str(opmap1[c]);
/*            ua_str(opmap1[getbyte()]); */
            break;
       }
       break;
   }
}



static void ua_str(char *str)
{
  int c;

  if (str == 0) return;
  if (strpbrk(str, "CDFGRST")) /* specifiers for registers=>no size 2b specified */
    must_do_size = 0;
  while ((c = *str++) != 0) {
    if (c == '%') {
      c = *str++;
      percent((char)c, *str++);
    } else {
      if (c == ' ') {
        uputchar('\t');
      } else {
        uputchar((char)c);
      }
    }
  }
}


static int isletter(int c)
{
        if(isalnum(c) || (ispunct(c) && c!='\'') || c==' ') return 1;
        return 0;
}


static int check_string(word16 ofs,word16 p,word16 maxlen,word16 *datalen)
{
        unsigned len=0,ended=0;

        while(!ended &&                 /* string ends when terminator found */
              len<maxlen &&             /* do not exceed buffer limits */
              !test_jmp_map(ofs+len) &&
              !test_fixup(ofs+len, 4, code_buf+p+len, 0) &&
              !test_fixup(ofs+len, 2, code_buf+p+len, 0)) {
                                        /* fixups or jumps end string; 0
                                           indicates a data item... */
          if(code_buf[p+len]==0)        /* terminator: end after this letter */
            ended=1;
          else if(!isletter(code_buf[p+len]))
            break;                      /* abort now if invalid character */
          len++;
        }
        if(len>4) {                     /* string valid only if 5+ chars */
          *datalen=len;
          return 1;                     /* yes, looks like a string */
        }
        return 0;                       /* no string found */
}


static word8 unassemble(word16 ofs)
{
  int   c, c2;
  int   old_codep;
  char  *label;
  unsigned short len,p;
  int jl_flag;            /* set if jumplist a starts here */
  int addinfo;            /* additional info passed from jl recognition to
                             fixup resolution */

  sprintf(hbuf, "%04X ", ofs);
  prefix = 0;
  cont_flow = 1;          /* default: flow continues */
  jmp_subtype = 0;        /* default: is not a jump */
  modrmv = sibv = -1;     /* set modrm and sib flags */
  opsize = addrsize = seg_size;
  ubufp = ubuf;
  done_space = 0;
  instruction_length = 0;
  old_codep = codep;
  must_do_size = do_size;
  jl_flag = 0;            /* no jumplist identified yet */
  addinfo = 0;            /* not in jumplist */

/* "pre"-hook before starting of instruction decoding */
  prepost_hook(ofs,0,silent_run,0);

  c = getbyte();
  wordop = c & 1;

  if(data_area && test_jmp_map(ofs)) {
    if(!silent_run && data_area==-1) putchar('\n');
    data_area = 0;
  }
  if(data_area==1) data_area=-1;    /* data area continues */
  if(!data_area && test_data_map(ofs))
    data_area=1;                    /* data_map overrides code to data */

  len=0;                            /* no data item */
  if (!setjmp(reached_eof) && !data_area) {
    if (do_emul87) {
      if (c==0xcd) {                /* wanna do emu '87 and ->ing to int? */
        c2 = silent_getbyte();
        if (c2 >= 0x34 && c2 <= 0x3C) {
          patch87 = 1;       /* emulated instruction!  => repatch two bytes */
          c -= 0x32;                /* decode emulated opcode */
        }
        silent_returnbyte((char)c2);
        if(c2 == 0x3D) {            /* standalone wait */
          c -= 0x32;                /* decode to FWAIT opcode in the same way */
          getbyte();                /* swallow one byte */
        }
      }
    }
    ua_str(opmap1[c]);              /* attempt to disassemble instruction */
  }
  else if (silent_run>-1 && data_area) {
    len = test_jmplist(ofs,&jl_flag,&addinfo);
    if (len && (label = test_fixup(ofs,len,code_buf + old_codep,addinfo)))
      instruction_offset -= instruction_length;
    else
      len=0;
  }
  else {
    ubufp = ubuf;                   /* invalidate instruction */
    len = 0;
  }

  if (ubufp==ubuf && len==0) {      /* invalid instruction or inside data? */
    if(instruction_length==0)
      return 0;                     /* end of block - abort */
    instruction_offset -= instruction_length;
                                    /* roll back all bytes */
    len = 1;                        /* default: dump one byte */
    if (silent_run>-1) {            /* "visible" run: attempt 2 & 4 bytes */
      if ( (code_len-old_codep)>=4 &&
           (label = test_fixup(ofs,4,code_buf + old_codep,0)))
                                    /* 0 indicates a data item */
        len = 4;
      else if( (code_len-old_codep)>=2 &&
               (label = test_fixup(ofs,2,code_buf + old_codep,0)))
        len = 2;
      else
        check_string(ofs,old_codep,min(40,code_len-old_codep),&len);
    }
  }

  if(len) {                             /* disassemble as data */
    instruction_length = len;           /* length of data instruction */
    instruction_offset += len;
    codep = old_codep + len;
  }

  if(data_area && codep<code_len && test_jmp_map(ofs+instruction_length))
    cont_flow = 0;                      /* force hard separation after data-
                                           to-code change */

/* "pre"-hook before instruction */
  prepost_hook(ofs,instruction_length,silent_run,1);

/* Display instruction */
  if(!silent_run) {                     /* "silent" suppresses output */
    if(len) {                           /* data with definded length... */
      if (len == 1)                     /* no special location: dump 1 byte */
        uprintf(do_hex?"db      %02X":"db      0%02Xh",c);
      else if(len<=4)
        uprintf("d%c      %s",(len==4)?'d':'w',label);
      else {
        uprintf("db      '%c",c);
        for(p=1;p<len-1;p++)
          uprintf("%c", code_buf[old_codep + p]);
        c2=code_buf[old_codep + len-1];
        uprintf(isletter(c2)?"%c'":"',0%xh",c2);
      }
      sprintf(hbuf, "%04X", ofs);       /* offset only */
    }

    if(test_jmp_map(ofs))               /* should a jump label go here? */
    {
      if(data_area)
        printf("%s = $\n",create_label(0xFFFF,ofs,'H'));
      else
        printf("%s:\n",create_label(0xFFFF,ofs,'H'));
                                        /* yes: insert it */
    }
    else if(jl_flag)                    /* does a jumplist start here? */
      printf("\n%s = $\n",create_label(0xFFFF,ofs,'J'));
                                        /* yes: insert a special label */
    else if(test_data_map(ofs))         /* data item starts here? */
      printf("%s = $\n",create_label(0xFFFF,ofs,'D'));
                                        /* yes: insert a special label */

    if(old_codep && addinfo == 0 && data_area && jl_last)
                                        /* jumplist ended and data continues? */
        putchar('\n');                  /* make separation clear */

    col = printf("    %s", ubuf);
    if(*hbuf) {
      do {
        putchar(' ');
        col++;
      } while (col < 43);
      printf("; %s",hbuf);
    }
    putchar('\n');
  }

/* "post"-hook after instruction */
  prepost_hook(ofs,instruction_length,silent_run,2);

/* Display separation if there is any significant change */
  if(!silent_run) {
    if(!cont_flow && codep<code_len) {
      putchar('\n');                    /* blank line after interruptions */
      if(ofs+instruction_length>max_jmp) {
        putchar(';');
        for(c=0;c<39;c++) putchar('-');
        putchar('\n');
      }
    }
  }

  if(!cont_flow) data_area = 1;         /* default: data mode */
  jl_last = addinfo;                    /* store if in jumplist */

  return instruction_length;
}


void disassemble(unsigned char *c,unsigned int len,unsigned int offset,int all_silent)
{
  word16 instr_len,ofs;
  word16 old_jmp_count;
  word16 n;

  do_emul87=1;                          /* recognize Borland FP emulation */
  do_distance=1;                        /* do not output "short","near","far" */

  init_jmp_map();                       // no jumps yet
  for(n=enumerate_global_jmp(0,&ofs); n!=0xFFFF; n=enumerate_global_jmp(n,&ofs))
    set_jmp_map(ofs);                   // mark entry points know to be code

  silent_run = -1;                      /* totally silent */
  old_jmp_count = 0xFFFF;               /* at least two iterations */
  do {
    if(jmp_count == old_jmp_count)
      silent_run = (all_silent)?1:0;    /* final run visible or hidden? */
    old_jmp_count = jmp_count;          /* remember # of jmp targets */
    code_buf = c;
    code_len = len;
    ofs = instruction_offset = offset;
    data_area = 1;                      /* default: start with data */
    codep = 0;                          /* start at the beginning */
    max_jmp = 0;                        /* no jump found yet */
    patch87 = 0;                        /* no 8087 emulator instruction yet */
    do {
      instr_len = unassemble(ofs);
      ofs += instr_len;
    } while (instr_len);                /* whoops, no files > 64k */
  } while(jmp_count != old_jmp_count || silent_run == -1);
}
