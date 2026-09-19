#include <assert.h>

#define LEFT_ARROW_ASCII       0xcb
#define RIGHT_ARROW_ASCII      0xcd
#define CURSES_KEYS_TEST

#include "../cursesKeys.h"

int
main(void)
{
    static const unsigned char plainLeft[] = "[D";
    static const unsigned char ctrlLeft[] = "[1;5D";
    static const unsigned char ctrlRight[] = "[1;5C";
    static const unsigned char shiftLeft[] = "[1;2D";
    static const unsigned char ctrlShiftRight[] = "[1;6C";
    static const unsigned char longModifier[] =
        "[1;555555555555555555555555555D";

    assert(CursesDecodeHorizontalArrow(plainLeft, 2) ==
           LEFT_ARROW_ASCII);
    assert(CursesDecodeHorizontalArrow(ctrlLeft, 5) ==
           CTRL_LEFT_ASCII);
    assert(CursesDecodeHorizontalArrow(ctrlRight, 5) ==
           CTRL_RIGHT_ASCII);
    assert(CursesDecodeHorizontalArrow(shiftLeft, 5) ==
           LEFT_ARROW_ASCII);
    assert(CursesDecodeHorizontalArrow(ctrlShiftRight, 5) ==
           CTRL_RIGHT_ASCII);
    assert(CursesDecodeHorizontalArrow(longModifier,
           sizeof(longModifier) - 1) == LEFT_ARROW_ASCII);
    assert(CursesControlArrowKey(LEFT_ARROW_ASCII, 1) ==
           CTRL_LEFT_ASCII);
    assert(CursesControlArrowKey(RIGHT_ARROW_ASCII, 1) ==
           CTRL_RIGHT_ASCII);
    assert(CursesControlArrowKey(LEFT_ARROW_ASCII, 0) ==
           LEFT_ARROW_ASCII);

    return 0;
}
