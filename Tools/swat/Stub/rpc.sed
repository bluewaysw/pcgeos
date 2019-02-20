1i\
;\
; This file was generated from rpc.h. DO NOT MODIFY IT.\
; Refer to rpc.h for comments and other tidbits of information.\
;
/_RPC_H_/d
/START C DEFINITIONS/,/END C DEFINITIONS/d
/^#define/s/#define[ 	]*\([^ 	]*\)[ 	]*\(.*\)$/\1=\2/
/^#ifndef/s/^#//
/^#endif/s/^#//
/^#if/s/^#//
/^#else/s/^#//
/STRUCT/s/STRUCT(\([^)]*\))/\1 struc/
/BYTEA/s/BYTEA(\([^,]*\),\([^)]*\))/\1 db \2 dup(?)/
/WORDA/s/WORDA(\([^,]*\),\([^)]*\))/\1 dw \2 dup(?)/
/LONGA/s/LONGA(\([^,]*\),\([^)]*\))/\1 dd \2 dup(?)/
/BYTE/s/BYTE(\([^)]*\))/\1 db ?/
/WORD/s/WORD(\([^)]*\))/\1 dw ?/
/LONG/s/LONG(\([^)]*\))/\1 dd ?/
/FSTRUC/s/FSTRUC(\([^,]*\),\([^)]*\))/\1 \2 <>/
/ENDST/s/ENDST(\([^)]*\))/\1 ends/
/\/\*.*\*\//s///
/\/\*.*$/{
s///
n
:loop
/\*\//bloopend
N
bloop
:loopend
d
}
/^[ 	]*$/d
