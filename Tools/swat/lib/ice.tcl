#
# Functions for emulating the ICE unit everyone's used to.
#
[defsubr imem {mode addr}
{
}]

[defcommand asm {addr}
{}
{
    imem a $addr
}]
alias a asm
[defcommand mem {addr}
{}
{
    imem b $addr
}]
