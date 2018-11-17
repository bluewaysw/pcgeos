/* C code produced by gperf version 2.7.1 (19981006 egcs) */
/* Command-line: gperf -i14 -o -j1 -S 1 -DtlTC -k2-5,$ -N findFlopcode -H hashFlopcode flopcodes.gperf  */

#define TOTAL_KEYWORDS 96
#define MIN_WORD_LENGTH 3
#define MAX_WORD_LENGTH 8
#define MIN_HASH_VALUE 45
#define MAX_HASH_VALUE 232
/* maximum key range = 188, duplicates = 0 */

#ifdef __GNUC__
__inline
#endif
static unsigned int
hashFlopcode (str, len)
     register const char *str;
     register unsigned int len;
{
  static const unsigned char asso_values[] =
    {
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233,  16,  25,
       50, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233,  55,  64,  29,
       14,  41,  24,  14,  15,  14, 233, 233,  14,  23,
       59,  87,  19,  14,  16,  14,  15,  65,  38,  54,
       36,  55,  16, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233, 233, 233, 233, 233,
      233, 233, 233, 233, 233, 233
    };
  register int hval = len;

  switch (hval)
    {
      default:
      case 5:
        hval += asso_values[(unsigned char)str[4]];
      case 4:
        hval += asso_values[(unsigned char)str[3]];
      case 3:
        hval += asso_values[(unsigned char)str[2]];
      case 2:
        hval += asso_values[(unsigned char)str[1]];
        break;
    }
  return hval + asso_values[(unsigned char)str[len - 1]];
}

#ifdef __GNUC__
__inline
#endif
const OpCode *
findFlopcode (str, len)
     register const char *str;
     register unsigned int len;
{
  static const OpCode wordlist[] =
    {
      {"fld",	FLDST,	0xd9c0,},
      {"fst",	FLDST,	0xddd0,},
      {"fild",	FINT,	0x1000, /* FINT: only thing we need is */},
      {"fist",	FINT,	0x0200, /* 3 bits for the opcode */},
      {"ftst",	FZOP,	0xd9e4,},
      {"fldz",	FZOP,	0xd9ee,},
      {"fstp",	FLDST,	0xddd8,},
      {"fdisi",	FGROUP0, 0x1be1,},
      {"fchs",	FZOP,	0xd9e0,},
      {"fsqrt",	FZOP,	0xd9fa,},
      {"fldpi",	FZOP,	0xd9eb,},
      {"fld1",	FZOP,	0xd9e8,},
      {"fistp",	FINT,	0x0100,},
      {"ftstp",	FZOP,	0xd9e6,},
      {"frstpm",	FZOP,	0xdbf6,},
      {"fxch",	FXCH,	0xd9c9,},
      {"frichop", FZOP,	0xddfc,},
      {"fadd",	FBIOP,	0x0000,	/* 1st 0 = no pop, last 0 is add */},
      {"fidivr",	FINT,	0x0038,},
      {"fdivr",	FBIOP,	0x0030, /*1st zero = no pop, 38 = divr */},
      {"fdivrp",	FBIOP,	0x1030, /* 1 = pop, 38 = divr */},
      {"fdiv", 	FBIOP,	0x0038, /* 1st 0 = no pop, 30 = div */},
      {"fdivp", 	FBIOP,	0x1038, /* 1 = pop, 30 = div */},
      {"fbld",	FGROUP1, 0x04df,},
      {"fldlg2",	FZOP,	0xd9ec,},
      {"fldl2t",	FZOP,	0xd9e9,},
      {"fiadd",	FINT,	0x0000,	},
      {"fsetpm",	FZOP,	0xdbe4,},
      {"fmul", 	FBIOP,	0x0008, /* 1st 0 = no pop, 08 = mul */},
      {"fndisi", FGROUP0, 0x0be1,},
      {"finit",	FGROUP0, 0x1be3, },
      {"fidiv",	FINT,	0x0030,},
      {"fdecstp", FZOP,	0xd9f6,},
      {"frndint", FZOP,	0xd9fc,},
      {"faddp", 	FBIOP,	0x1000, /* 1 = pop, last 0 is add */},
      {"fprem",	FZOP,	0xd9f8,},
      {"fprem1",	FZOP,	0xd9f5,},
      {"feni",	FGROUP0, 0x1be0,},
      {"fsbp0",	FZOP,	0xdbe8,},
      {"fimul",	FINT,	0x0008,},
      {"fbstp",	FGROUP1, 0x06df,},
      {"fsincos", FZOP,	0xdbfb,},
      {"fldl2e",	FZOP,	0xd9ea,},
      {"fstswax", FGROUP0, 0x1fe0,},
      {"fxam",	FZOP,	0xd9e5,},
      {"fincstp", FZOP,	0xd9f7,},
      {"fxtract", FZOP,	0xd9f4,},
      {"fmulp",	FBIOP,	0x1008, /* 1 = pop, 08 = mul */},
      {"fnstswax", FGROUP0, 0x0fe0, },
      {"ffreep",	FFREE,	0xdfc0,},
      {"fcos",	FZOP,	0xd9ff,},
      {"fsin",	FZOP,	0xd9fe,},
      {"fabs",	FZOP,	0xd9e1,},
      {"fsbp1",	FZOP,	0xdbeb,},
      {"frinear", FZOP,	0xdffc,},
      {"frstor",	FGROUP1, 0x04dd,},
      {"fstsw", 	FGROUP1, 0x17dd, },
      {"fldln2",	FZOP,	0xd9ed,},
      {"fwait",	NOARG,	0x009b,},
      {"fscale",	FZOP,	0xd9fd,},
      {"frint2",	FZOP,	0xdbfc,},
      {"fclex",	FGROUP0, 0x1be2,},
      {"fnstsw", FGROUP1, 0x07dd, },
      {"f2xm1",	FZOP,	0xd9f0,},
      {"fcom",	FCOM,	0x28d1,},
      {"fninit",	FGROUP0, 0x0be3,},
      {"ffree",	FFREE,	0xddc0,},
      {"fldcw",	FGROUP1, 0x05d9,},
      {"fstcw",	FGROUP1, 0x17d9, },
      {"fldenv", FGROUP1, 0x04d9,},
      {"fstenv",	FGROUP1, 0x16d9,},
      {"fnstenv",FGROUP1, 0x06d9,},
      {"fnstcw", FGROUP1, 0x07d9, },
      {"ficomp",	FINT,	0x0018,},
      {"fisubr",	FINT,	0x0028,},
      {"fsubr",	FBIOP,	0x0020,	/* 1st 0 = no pop, 28 = subr */},
      {"ficom",	FINT,	0x0010,},
      {"fcomp",	FCOM,	0x38d9,},
      {"fcompp",	FGROUP0, 0x0ed9,},
      {"fsubrp",	FBIOP,	0x1020, /* 1 = pop, 28 = subr */},
      {"fnclex", FGROUP0, 0x0be2,},
      {"fsubp",	FBIOP,	0x1028, /* 1 = pop, 20 = sub */},
      {"fyl2xp1", FZOP,	0xd9f9,},
      {"fnop",	FZOP,	0xd9d0,},
      {"fneni",	FGROUP0, 0x0be0,},
      {"fsave",  FGROUP1, 0x16dd,},
      {"fyl2x",	FZOP,	0xd9f1,},
      {"fsbp2",	FZOP,	0xdbea,},
      {"fpatan",	FZOP,	0xd9f3,},
      {"fsub",	FBIOP,	0x0028, /* 1st 0 = no pop, 20 = sub */},
      {"fptan",	FZOP,	0xd9f2,},
      {"fnsave", FGROUP1, 0x06dd,},
      {"fisub",	FINT,	0x0020,},
      {"fucomp",	FXCH,	0xdde9,},
      {"fucompp", FZOP, 	0xdae9,},
      {"fucom",	FXCH,	0xdde1,}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hashFlopcode (str, len);

      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE)
        {
          register const unsigned char *lengthptr;
          register const OpCode *wordptr;
          register const OpCode *wordendptr;
          register const OpCode *resword;

          switch (key - 45)
            {
              case 0:
                if (len == 3)
                  {
                    resword = &wordlist[0];
                    goto compare;
                  }
                break;
              case 2:
                if (len == 3)
                  {
                    resword = &wordlist[1];
                    goto compare;
                  }
                break;
              case 15:
                if (len == 4)
                  {
                    resword = &wordlist[2];
                    goto compare;
                  }
                break;
              case 17:
                if (len == 4)
                  {
                    resword = &wordlist[3];
                    goto compare;
                  }
                break;
              case 18:
                if (len == 4)
                  {
                    resword = &wordlist[4];
                    goto compare;
                  }
                break;
              case 19:
                if (len == 4)
                  {
                    resword = &wordlist[5];
                    goto compare;
                  }
                break;
              case 26:
                if (len == 4)
                  {
                    resword = &wordlist[6];
                    goto compare;
                  }
                break;
              case 30:
                if (len == 5)
                  {
                    resword = &wordlist[7];
                    goto compare;
                  }
                break;
              case 31:
                if (len == 4)
                  {
                    resword = &wordlist[8];
                    goto compare;
                  }
                break;
              case 34:
                if (len == 5)
                  {
                    resword = &wordlist[9];
                    goto compare;
                  }
                break;
              case 35:
                if (len == 5)
                  {
                    resword = &wordlist[10];
                    goto compare;
                  }
                break;
              case 37:
                if (len == 4)
                  {
                    resword = &wordlist[11];
                    goto compare;
                  }
                break;
              case 41:
                if (len == 5)
                  {
                    resword = &wordlist[12];
                    goto compare;
                  }
                break;
              case 42:
                if (len == 5)
                  {
                    resword = &wordlist[13];
                    goto compare;
                  }
                break;
              case 48:
                if (len == 6)
                  {
                    resword = &wordlist[14];
                    goto compare;
                  }
                break;
              case 54:
                if (len == 4)
                  {
                    resword = &wordlist[15];
                    goto compare;
                  }
                break;
              case 55:
                if (len == 7)
                  {
                    resword = &wordlist[16];
                    goto compare;
                  }
                break;
              case 56:
                if (len == 4)
                  {
                    resword = &wordlist[17];
                    goto compare;
                  }
                break;
              case 57:
                if (len == 6)
                  {
                    resword = &wordlist[18];
                    goto compare;
                  }
                break;
              case 58:
                if (len == 5)
                  {
                    resword = &wordlist[19];
                    goto compare;
                  }
                break;
              case 62:
                if (len == 6)
                  {
                    resword = &wordlist[20];
                    goto compare;
                  }
                break;
              case 63:
                if (len == 4)
                  {
                    resword = &wordlist[21];
                    goto compare;
                  }
                break;
              case 64:
                if (len == 5)
                  {
                    resword = &wordlist[22];
                    goto compare;
                  }
                break;
              case 65:
                if (len == 4)
                  {
                    resword = &wordlist[23];
                    goto compare;
                  }
                break;
              case 67:
                if (len == 6)
                  {
                    resword = &wordlist[24];
                    goto compare;
                  }
                break;
              case 68:
                if (len == 6)
                  {
                    resword = &wordlist[25];
                    goto compare;
                  }
                break;
              case 71:
                if (len == 5)
                  {
                    resword = &wordlist[26];
                    goto compare;
                  }
                break;
              case 73:
                if (len == 6)
                  {
                    resword = &wordlist[27];
                    goto compare;
                  }
                break;
              case 75:
                if (len == 4)
                  {
                    resword = &wordlist[28];
                    goto compare;
                  }
                break;
              case 76:
                if (len == 6)
                  {
                    resword = &wordlist[29];
                    goto compare;
                  }
                break;
              case 77:
                if (len == 5)
                  {
                    resword = &wordlist[30];
                    goto compare;
                  }
                break;
              case 78:
                if (len == 5)
                  {
                    resword = &wordlist[31];
                    goto compare;
                  }
                break;
              case 79:
                if (len == 7)
                  {
                    resword = &wordlist[32];
                    goto compare;
                  }
                break;
              case 80:
                if (len == 7)
                  {
                    resword = &wordlist[33];
                    goto compare;
                  }
                break;
              case 81:
                if (len == 5)
                  {
                    resword = &wordlist[34];
                    goto compare;
                  }
                break;
              case 82:
                if (len == 5)
                  {
                    resword = &wordlist[35];
                    goto compare;
                  }
                break;
              case 85:
                if (len == 6)
                  {
                    resword = &wordlist[36];
                    goto compare;
                  }
                break;
              case 87:
                if (len == 4)
                  {
                    resword = &wordlist[37];
                    goto compare;
                  }
                break;
              case 89:
                if (len == 5)
                  {
                    resword = &wordlist[38];
                    goto compare;
                  }
                break;
              case 90:
                if (len == 5)
                  {
                    resword = &wordlist[39];
                    goto compare;
                  }
                break;
              case 91:
                if (len == 5)
                  {
                    resword = &wordlist[40];
                    goto compare;
                  }
                break;
              case 92:
                if (len == 7)
                  {
                    resword = &wordlist[41];
                    goto compare;
                  }
                break;
              case 94:
                if (len == 6)
                  {
                    resword = &wordlist[42];
                    goto compare;
                  }
                break;
              case 95:
                if (len == 7)
                  {
                    resword = &wordlist[43];
                    goto compare;
                  }
                break;
              case 96:
                if (len == 4)
                  {
                    resword = &wordlist[44];
                    goto compare;
                  }
                break;
              case 97:
                if (len == 7)
                  {
                    resword = &wordlist[45];
                    goto compare;
                  }
                break;
              case 99:
                if (len == 7)
                  {
                    resword = &wordlist[46];
                    goto compare;
                  }
                break;
              case 100:
                if (len == 5)
                  {
                    resword = &wordlist[47];
                    goto compare;
                  }
                break;
              case 101:
                if (len == 8)
                  {
                    resword = &wordlist[48];
                    goto compare;
                  }
                break;
              case 102:
                if (len == 6)
                  {
                    resword = &wordlist[49];
                    goto compare;
                  }
                break;
              case 103:
                if (len == 4)
                  {
                    resword = &wordlist[50];
                    goto compare;
                  }
                break;
              case 105:
                if (len == 4)
                  {
                    resword = &wordlist[51];
                    goto compare;
                  }
                break;
              case 106:
                if (len == 4)
                  {
                    resword = &wordlist[52];
                    goto compare;
                  }
                break;
              case 107:
                if (len == 5)
                  {
                    resword = &wordlist[53];
                    goto compare;
                  }
                break;
              case 108:
                if (len == 7)
                  {
                    resword = &wordlist[54];
                    goto compare;
                  }
                break;
              case 109:
                if (len == 6)
                  {
                    resword = &wordlist[55];
                    goto compare;
                  }
                break;
              case 111:
                if (len == 5)
                  {
                    resword = &wordlist[56];
                    goto compare;
                  }
                break;
              case 112:
                if (len == 6)
                  {
                    resword = &wordlist[57];
                    goto compare;
                  }
                break;
              case 113:
                if (len == 5)
                  {
                    resword = &wordlist[58];
                    goto compare;
                  }
                break;
              case 114:
                if (len == 6)
                  {
                    resword = &wordlist[59];
                    goto compare;
                  }
                break;
              case 115:
                if (len == 6)
                  {
                    resword = &wordlist[60];
                    goto compare;
                  }
                break;
              case 116:
                if (len == 5)
                  {
                    resword = &wordlist[61];
                    goto compare;
                  }
                break;
              case 117:
                if (len == 6)
                  {
                    resword = &wordlist[62];
                    goto compare;
                  }
                break;
              case 119:
                if (len == 5)
                  {
                    resword = &wordlist[63];
                    goto compare;
                  }
                break;
              case 121:
                if (len == 4)
                  {
                    resword = &wordlist[64];
                    goto compare;
                  }
                break;
              case 122:
                if (len == 6)
                  {
                    resword = &wordlist[65];
                    goto compare;
                  }
                break;
              case 123:
                if (len == 5)
                  {
                    resword = &wordlist[66];
                    goto compare;
                  }
                break;
              case 125:
                if (len == 5)
                  {
                    resword = &wordlist[67];
                    goto compare;
                  }
                break;
              case 126:
                if (len == 5)
                  {
                    resword = &wordlist[68];
                    goto compare;
                  }
                break;
              case 127:
                if (len == 6)
                  {
                    resword = &wordlist[69];
                    goto compare;
                  }
                break;
              case 128:
                if (len == 6)
                  {
                    resword = &wordlist[70];
                    goto compare;
                  }
                break;
              case 129:
                if (len == 7)
                  {
                    resword = &wordlist[71];
                    goto compare;
                  }
                break;
              case 132:
                if (len == 6)
                  {
                    resword = &wordlist[72];
                    goto compare;
                  }
                break;
              case 133:
                if (len == 6)
                  {
                    resword = &wordlist[73];
                    goto compare;
                  }
                break;
              case 134:
                if (len == 6)
                  {
                    resword = &wordlist[74];
                    goto compare;
                  }
                break;
              case 135:
                if (len == 5)
                  {
                    resword = &wordlist[75];
                    goto compare;
                  }
                break;
              case 136:
                if (len == 5)
                  {
                    resword = &wordlist[76];
                    goto compare;
                  }
                break;
              case 137:
                if (len == 5)
                  {
                    resword = &wordlist[77];
                    goto compare;
                  }
                break;
              case 138:
                if (len == 6)
                  {
                    resword = &wordlist[78];
                    goto compare;
                  }
                break;
              case 139:
                if (len == 6)
                  {
                    resword = &wordlist[79];
                    goto compare;
                  }
                break;
              case 140:
                if (len == 6)
                  {
                    resword = &wordlist[80];
                    goto compare;
                  }
                break;
              case 141:
                if (len == 5)
                  {
                    resword = &wordlist[81];
                    goto compare;
                  }
                break;
              case 142:
                if (len == 7)
                  {
                    resword = &wordlist[82];
                    goto compare;
                  }
                break;
              case 143:
                if (len == 4)
                  {
                    resword = &wordlist[83];
                    goto compare;
                  }
                break;
              case 147:
                if (len == 5)
                  {
                    resword = &wordlist[84];
                    goto compare;
                  }
                break;
              case 149:
                if (len == 5)
                  {
                    resword = &wordlist[85];
                    goto compare;
                  }
                break;
              case 151:
                if (len == 5)
                  {
                    resword = &wordlist[86];
                    goto compare;
                  }
                break;
              case 157:
                if (len == 5)
                  {
                    resword = &wordlist[87];
                    goto compare;
                  }
                break;
              case 164:
                if (len == 6)
                  {
                    resword = &wordlist[88];
                    goto compare;
                  }
                break;
              case 166:
                if (len == 4)
                  {
                    resword = &wordlist[89];
                    goto compare;
                  }
                break;
              case 167:
                if (len == 5)
                  {
                    resword = &wordlist[90];
                    goto compare;
                  }
                break;
              case 168:
                if (len == 6)
                  {
                    resword = &wordlist[91];
                    goto compare;
                  }
                break;
              case 181:
                if (len == 5)
                  {
                    resword = &wordlist[92];
                    goto compare;
                  }
                break;
              case 184:
                if (len == 6)
                  {
                    resword = &wordlist[93];
                    goto compare;
                  }
                break;
              case 185:
                if (len == 7)
                  {
                    resword = &wordlist[94];
                    goto compare;
                  }
                break;
              case 187:
                if (len == 5)
                  {
                    resword = &wordlist[95];
                    goto compare;
                  }
                break;
            }
          return 0;
        multicompare:
          while (wordptr < wordendptr)
            {
              if (len == *lengthptr)
                {
                  register const char *s = wordptr->name;

                  if (*str == *s && !strcmp (str + 1, s + 1))
                    return wordptr;
                }
              lengthptr++;
              wordptr++;
            }
          return 0;
        compare:
          {
            register const char *s = resword->name;

            if (*str == *s && !strcmp (str + 1, s + 1))
              return resword;
          }
        }
    }
  return 0;
}
