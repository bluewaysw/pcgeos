#ifndef CURSES_KEYS_H
#define CURSES_KEYS_H

#define CTRL_UP_ASCII          0xf1
#define CTRL_DOWN_ASCII        0xf2
#define CTRL_LEFT_ASCII        0xf3
#define CTRL_RIGHT_ASCII       0xf4

#if defined(_LINUX) || defined(CURSES_KEYS_CONTROL) || \
    defined(CURSES_KEYS_TEST)
static int
CursesControlArrowKey(int key, int control)
{
    if (control) {
        switch (key) {
        case UP_ARROW_ASCII:
            return CTRL_UP_ASCII;
        case DOWN_ARROW_ASCII:
            return CTRL_DOWN_ASCII;
        case LEFT_ARROW_ASCII:
            return CTRL_LEFT_ASCII;
        case RIGHT_ARROW_ASCII:
            return CTRL_RIGHT_ASCII;
        }
    }
    return key;
}
#endif

#if defined(_LINUX) || defined(CURSES_KEYS_TEST)
static int
CursesDecodeArrow(const unsigned char *seq, int len)
{
    int key;

    if (len < 2) {
        return -1;
    }
    switch (seq[len - 1]) {
    case 'A':
        key = UP_ARROW_ASCII;
        break;
    case 'B':
        key = DOWN_ARROW_ASCII;
        break;
    case 'C':
        key = RIGHT_ARROW_ASCII;
        break;
    case 'D':
        key = LEFT_ARROW_ASCII;
        break;
    default:
        return -1;
    }
    if ((seq[0] == '[') && (len >= 4) && (seq[len - 3] == ';') &&
        (seq[len - 2] >= '5') && (seq[len - 2] <= '8')) {
        return CursesControlArrowKey(key, 1);
    }
    return key;
}
#endif

#if defined(_MSDOS) || defined(CURSES_KEYS_TEST)
static int
CursesDecodeDosExtendedKey(int scan)
{
    /* These enhanced scan codes would wrap into control characters. */
    if (scan == 0x8d) {
        return CTRL_UP_ASCII;
    }
    if (scan == 0x91) {
        return CTRL_DOWN_ASCII;
    }
    return (0x80 + scan) & 0xff;
}
#endif

#endif
