#ifndef CURSES_KEYS_H
#define CURSES_KEYS_H

#define CTRL_LEFT_ASCII        0xf3
#define CTRL_RIGHT_ASCII       0xf4

#if defined(_LINUX) || defined(CURSES_KEYS_TEST)
static int
CursesDecodeHorizontalArrow(const unsigned char *seq, int len)
{
    int key;

    if ((len < 2) || ((seq[len - 1] != 'C') && (seq[len - 1] != 'D'))) {
        return -1;
    }
    key = (seq[len - 1] == 'C') ? RIGHT_ARROW_ASCII : LEFT_ARROW_ASCII;
    if (seq[0] != '[') {
        return key;
    }
    if ((len >= 4) && (seq[len - 3] == ';') &&
        (seq[len - 2] >= '5') && (seq[len - 2] <= '8')) {
        return (key == RIGHT_ARROW_ASCII) ?
               CTRL_RIGHT_ASCII : CTRL_LEFT_ASCII;
    }
    return key;
}
#endif

#if defined(CURSES_KEYS_CONTROL) || defined(CURSES_KEYS_TEST)
static int
CursesControlArrowKey(int key, int control)
{
    if (control) {
        if (key == LEFT_ARROW_ASCII) {
            return CTRL_LEFT_ASCII;
        }
        if (key == RIGHT_ARROW_ASCII) {
            return CTRL_RIGHT_ASCII;
        }
    }
    return key;
}
#endif

#endif
