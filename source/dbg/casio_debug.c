
#include <gint/display.h>
#include <gint/keyboard.h>

void dtext_line_wrap(char* str, int maxsize)
{
    char y;
    char * t;

    for (t = str; *t != '\0'; t++) {
        if ((int)(str - t) % maxsize == 0) {
            dtext_opt(1, y, C_BLACK, C_WHITE, 0, 0, t, maxsize);
            y += 7;
        }
    }
}

void debug_and_wait(char* str)
{
    dclear(C_WHITE);
    dtext_line_wrap(str, 21);
    dupdate();
    getkey();
}