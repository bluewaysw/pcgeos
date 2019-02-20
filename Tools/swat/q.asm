foo segment

biff proc near
biff endp

whuffle proc
jmp {far} biff
whuffle endp
foo ends
