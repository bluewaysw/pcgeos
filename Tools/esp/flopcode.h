/* C code produced by gperf version 1.9 (K&R C version) */
/* Command-line: /usr/public/gperf -i14 -o -j1 -agSDptlTC -k2-5,$ -N findFlopcode -H hashFlopcode flopcodes.gperf  */



#define MIN_WORD_LENGTH 3
#define MAX_WORD_LENGTH 8
#define MIN_HASH_VALUE 45
#define MAX_HASH_VALUE 232
/*
   96 keywords
  188 is the maximum key range
*/

#ifdef __GNUC__
inline
#endif
static int
hashFlopcode (register const char *str, register int len)
{
  static const unsigned char hash_table[] =
    {
     232, 232, 232, 232, 232, 232, 232, 232, 232, 232,
     232, 232, 232, 232, 232, 232, 232, 232, 232, 232,
     232, 232, 232, 232, 232, 232, 232, 232, 232, 232,
     232, 232, 232, 232, 232, 232, 232, 232, 232, 232,
     232, 232, 232, 232, 232, 232, 232, 232,  16,  25,
      50, 232, 232, 232, 232, 232, 232, 232, 232, 232,
     232, 232, 232, 232, 232, 232, 232, 232, 232, 232,
     232, 232, 232, 232, 232, 232, 232, 232, 232, 232,
     232, 232, 232, 232, 232, 232, 232, 232, 232, 232,
     232, 232, 232, 232, 232, 232, 232,  55,  64,  29,
      14,  41,  24,  14,  15,  14, 232, 232,  14,  23,
      59,  87,  19,  14,  16,  14,  15,  65,  38,  54,
      36,  55,  16, 232, 232, 232, 232, 232,
    };
  register int hval = len ;

  switch (hval)
    {
      default:
      case 5:
        hval += hash_table[str[4]];
      case 4:
        hval += hash_table[str[3]];
      case 3:
        hval += hash_table[str[2]];
      case 2:
        hval += hash_table[str[1]];
    }
  return hval + hash_table[str[len - 1]] ;
}

#ifdef __GNUC__
inline
#endif
const OpCode*
findFlopcode (register const char *str, register unsigned int len)
{

  static const OpCode wordlist[] =
    {
      {"fld", 	FLDST,	0xd9c0,},
      {"fst", 	FLDST,	0xddd0,},
      {"fild", 	FINT,	0x1000, /* FINT: only thing we need is */},
      {"fist", 	FINT,	0x0200, /* 3 bits for the opcode */},
      {"ftst", 	FZOP,	0xd9e4,},
      {"fldz", 	FZOP,	0xd9ee,},
      {"fstp", 	FLDST,	0xddd8,},
      {"fdisi", 	FGROUP0, 0x1be1,},
      {"fchs", 	FZOP,	0xd9e0,},
      {"fsqrt", 	FZOP,	0xd9fa,},
      {"fldpi", 	FZOP,	0xd9eb,},
      {"fld1", 	FZOP,	0xd9e8,},
      {"fistp", 	FINT,	0x0100,},
      {"ftstp", 	FZOP,	0xd9e6,},
      {"frstpm", 	FZOP,	0xdbf6,},
      {"fxch", 	FXCH,	0xd9c9,},
      {"frichop",  FZOP,	0xddfc,},
      {"fadd", 	FBIOP,	0x0000,	/* 1st 0 = no pop, last 0 is add */},
      {"fidivr", 	FINT,	0x0038,},
      {"fdivr", 	FBIOP,	0x0030, /*1st zero = no pop, 38 = divr */},
      {"fdivrp", 	FBIOP,	0x1030, /* 1 = pop, 38 = divr */},
      {"fdiv",  	FBIOP,	0x0038, /* 1st 0 = no pop, 30 = div */},
      {"fdivp",  	FBIOP,	0x1038, /* 1 = pop, 30 = div */},
      {"fbld", 	FGROUP1, 0x04df,},
      {"fldlg2", 	FZOP,	0xd9ec,},
      {"fldl2t", 	FZOP,	0xd9e9,},
      {"fiadd", 	FINT,	0x0000,	},
      {"fsetpm", 	FZOP,	0xdbe4,},
      {"fmul",  	FBIOP,	0x0008, /* 1st 0 = no pop, 08 = mul */},
      {"fndisi",  FGROUP0, 0x0be1,},
      {"finit", 	FGROUP0, 0x1be3, },
      {"fidiv", 	FINT,	0x0030,},
      {"fdecstp",  FZOP,	0xd9f6,},
      {"frndint",  FZOP,	0xd9fc,},
      {"faddp",  	FBIOP,	0x1000, /* 1 = pop, last 0 is add */},
      {"fprem", 	FZOP,	0xd9f8,},
      {"fprem1", 	FZOP,	0xd9f5,},
      {"feni", 	FGROUP0, 0x1be0,},
      {"fsbp0", 	FZOP,	0xdbe8,},
      {"fimul", 	FINT,	0x0008,},
      {"fbstp", 	FGROUP1, 0x06df,},
      {"fsincos",  FZOP,	0xdbfb,},
      {"fldl2e", 	FZOP,	0xd9ea,},
      {"fstswax",  FGROUP0, 0x1fe0,},
      {"fxam", 	FZOP,	0xd9e5,},
      {"fincstp",  FZOP,	0xd9f7,},
      {"fxtract",  FZOP,	0xd9f4,},
      {"fmulp", 	FBIOP,	0x1008, /* 1 = pop, 08 = mul */},
      {"fnstswax",  FGROUP0, 0x0fe0, },
      {"ffreep", 	FFREE,	0xdfc0,},
      {"fcos", 	FZOP,	0xd9ff,},
      {"fsin", 	FZOP,	0xd9fe,},
      {"fabs", 	FZOP,	0xd9e1,},
      {"fsbp1", 	FZOP,	0xdbeb,},
      {"frinear",  FZOP,	0xdffc,},
      {"frstor", 	FGROUP1, 0x04dd,},
      {"fstsw",  	FGROUP1, 0x17dd, },
      {"fldln2", 	FZOP,	0xd9ed,},
      {"fwait", 	NOARG,	0x009b,},
      {"fscale", 	FZOP,	0xd9fd,},
      {"frint2", 	FZOP,	0xdbfc,},
      {"fclex", 	FGROUP0, 0x1be2,},
      {"fnstsw",  FGROUP1, 0x07dd, },
      {"f2xm1", 	FZOP,	0xd9f0,},
      {"fcom", 	FCOM,	0x28d1,},
      {"fninit", 	FGROUP0, 0x0be3,},
      {"ffree", 	FFREE,	0xddc0,},
      {"fldcw", 	FGROUP1, 0x05d9,},
      {"fstcw", 	FGROUP1, 0x17d9, },
      {"fldenv",  FGROUP1, 0x04d9,},
      {"fstenv", 	FGROUP1, 0x16d9,},
      {"fnstenv", FGROUP1, 0x06d9,},
      {"fnstcw",  FGROUP1, 0x07d9, },
      {"ficomp", 	FINT,	0x0018,},
      {"fisubr", 	FINT,	0x0028,},
      {"fsubr", 	FBIOP,	0x0020,	/* 1st 0 = no pop, 28 = subr */},
      {"ficom", 	FINT,	0x0010,},
      {"fcomp", 	FCOM,	0x38d9,},
      {"fcompp", 	FGROUP0, 0x0ed9,},
      {"fsubrp", 	FBIOP,	0x1020, /* 1 = pop, 28 = subr */},
      {"fnclex",  FGROUP0, 0x0be2,},
      {"fsubp", 	FBIOP,	0x1028, /* 1 = pop, 20 = sub */},
      {"fyl2xp1",  FZOP,	0xd9f9,},
      {"fnop", 	FZOP,	0xd9d0,},
      {"fneni", 	FGROUP0, 0x0be0,},
      {"fsave",   FGROUP1, 0x16dd,},
      {"fyl2x", 	FZOP,	0xd9f1,},
      {"fsbp2", 	FZOP,	0xdbea,},
      {"fpatan", 	FZOP,	0xd9f3,},
      {"fsub", 	FBIOP,	0x0028, /* 1st 0 = no pop, 20 = sub */},
      {"fptan", 	FZOP,	0xd9f2,},
      {"fnsave",  FGROUP1, 0x06dd,},
      {"fisub", 	FINT,	0x0020,},
      {"fucomp", 	FXCH,	0xdde9,},
      {"fucompp",  FZOP, 	0xdae9,},
      {"fucom", 	FXCH,	0xdde1,},
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hashFlopcode (str, len);

      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE)
        {
          const OpCode *resword; int key_len;

          switch (key)
            {
            case   45:
              resword = &wordlist[0]; key_len = 3; break;
            case   47:
              resword = &wordlist[1]; key_len = 3; break;
            case   60:
              resword = &wordlist[2]; key_len = 4; break;
            case   62:
              resword = &wordlist[3]; key_len = 4; break;
            case   63:
              resword = &wordlist[4]; key_len = 4; break;
            case   64:
              resword = &wordlist[5]; key_len = 4; break;
            case   71:
              resword = &wordlist[6]; key_len = 4; break;
            case   75:
              resword = &wordlist[7]; key_len = 5; break;
            case   76:
              resword = &wordlist[8]; key_len = 4; break;
            case   79:
              resword = &wordlist[9]; key_len = 5; break;
            case   80:
              resword = &wordlist[10]; key_len = 5; break;
            case   82:
              resword = &wordlist[11]; key_len = 4; break;
            case   86:
              resword = &wordlist[12]; key_len = 5; break;
            case   87:
              resword = &wordlist[13]; key_len = 5; break;
            case   93:
              resword = &wordlist[14]; key_len = 6; break;
            case   99:
              resword = &wordlist[15]; key_len = 4; break;
            case  100:
              resword = &wordlist[16]; key_len = 7; break;
            case  101:
              resword = &wordlist[17]; key_len = 4; break;
            case  102:
              resword = &wordlist[18]; key_len = 6; break;
            case  103:
              resword = &wordlist[19]; key_len = 5; break;
            case  107:
              resword = &wordlist[20]; key_len = 6; break;
            case  108:
              resword = &wordlist[21]; key_len = 4; break;
            case  109:
              resword = &wordlist[22]; key_len = 5; break;
            case  110:
              resword = &wordlist[23]; key_len = 4; break;
            case  112:
              resword = &wordlist[24]; key_len = 6; break;
            case  113:
              resword = &wordlist[25]; key_len = 6; break;
            case  116:
              resword = &wordlist[26]; key_len = 5; break;
            case  118:
              resword = &wordlist[27]; key_len = 6; break;
            case  120:
              resword = &wordlist[28]; key_len = 4; break;
            case  121:
              resword = &wordlist[29]; key_len = 6; break;
            case  122:
              resword = &wordlist[30]; key_len = 5; break;
            case  123:
              resword = &wordlist[31]; key_len = 5; break;
            case  124:
              resword = &wordlist[32]; key_len = 7; break;
            case  125:
              resword = &wordlist[33]; key_len = 7; break;
            case  126:
              resword = &wordlist[34]; key_len = 5; break;
            case  127:
              resword = &wordlist[35]; key_len = 5; break;
            case  130:
              resword = &wordlist[36]; key_len = 6; break;
            case  132:
              resword = &wordlist[37]; key_len = 4; break;
            case  134:
              resword = &wordlist[38]; key_len = 5; break;
            case  135:
              resword = &wordlist[39]; key_len = 5; break;
            case  136:
              resword = &wordlist[40]; key_len = 5; break;
            case  137:
              resword = &wordlist[41]; key_len = 7; break;
            case  139:
              resword = &wordlist[42]; key_len = 6; break;
            case  140:
              resword = &wordlist[43]; key_len = 7; break;
            case  141:
              resword = &wordlist[44]; key_len = 4; break;
            case  142:
              resword = &wordlist[45]; key_len = 7; break;
            case  144:
              resword = &wordlist[46]; key_len = 7; break;
            case  145:
              resword = &wordlist[47]; key_len = 5; break;
            case  146:
              resword = &wordlist[48]; key_len = 8; break;
            case  147:
              resword = &wordlist[49]; key_len = 6; break;
            case  148:
              resword = &wordlist[50]; key_len = 4; break;
            case  150:
              resword = &wordlist[51]; key_len = 4; break;
            case  151:
              resword = &wordlist[52]; key_len = 4; break;
            case  152:
              resword = &wordlist[53]; key_len = 5; break;
            case  153:
              resword = &wordlist[54]; key_len = 7; break;
            case  154:
              resword = &wordlist[55]; key_len = 6; break;
            case  156:
              resword = &wordlist[56]; key_len = 5; break;
            case  157:
              resword = &wordlist[57]; key_len = 6; break;
            case  158:
              resword = &wordlist[58]; key_len = 5; break;
            case  159:
              resword = &wordlist[59]; key_len = 6; break;
            case  160:
              resword = &wordlist[60]; key_len = 6; break;
            case  161:
              resword = &wordlist[61]; key_len = 5; break;
            case  162:
              resword = &wordlist[62]; key_len = 6; break;
            case  164:
              resword = &wordlist[63]; key_len = 5; break;
            case  166:
              resword = &wordlist[64]; key_len = 4; break;
            case  167:
              resword = &wordlist[65]; key_len = 6; break;
            case  168:
              resword = &wordlist[66]; key_len = 5; break;
            case  170:
              resword = &wordlist[67]; key_len = 5; break;
            case  171:
              resword = &wordlist[68]; key_len = 5; break;
            case  172:
              resword = &wordlist[69]; key_len = 6; break;
            case  173:
              resword = &wordlist[70]; key_len = 6; break;
            case  174:
              resword = &wordlist[71]; key_len = 7; break;
            case  177:
              resword = &wordlist[72]; key_len = 6; break;
            case  178:
              resword = &wordlist[73]; key_len = 6; break;
            case  179:
              resword = &wordlist[74]; key_len = 6; break;
            case  180:
              resword = &wordlist[75]; key_len = 5; break;
            case  181:
              resword = &wordlist[76]; key_len = 5; break;
            case  182:
              resword = &wordlist[77]; key_len = 5; break;
            case  183:
              resword = &wordlist[78]; key_len = 6; break;
            case  184:
              resword = &wordlist[79]; key_len = 6; break;
            case  185:
              resword = &wordlist[80]; key_len = 6; break;
            case  186:
              resword = &wordlist[81]; key_len = 5; break;
            case  187:
              resword = &wordlist[82]; key_len = 7; break;
            case  188:
              resword = &wordlist[83]; key_len = 4; break;
            case  192:
              resword = &wordlist[84]; key_len = 5; break;
            case  194:
              resword = &wordlist[85]; key_len = 5; break;
            case  196:
              resword = &wordlist[86]; key_len = 5; break;
            case  202:
              resword = &wordlist[87]; key_len = 5; break;
            case  209:
              resword = &wordlist[88]; key_len = 6; break;
            case  211:
              resword = &wordlist[89]; key_len = 4; break;
            case  212:
              resword = &wordlist[90]; key_len = 5; break;
            case  213:
              resword = &wordlist[91]; key_len = 6; break;
            case  226:
              resword = &wordlist[92]; key_len = 5; break;
            case  229:
              resword = &wordlist[93]; key_len = 6; break;
            case  230:
              resword = &wordlist[94]; key_len = 7; break;
            case  232:
              resword = &wordlist[95]; key_len = 5; break;
            default: return 0;
            }
          if (len == key_len && *str == *resword->name && !strcmp (str + 1, resword->name + 1))
            return resword;
      }
  }
  return 0;
}
