// PsionDoomDoc.cpp
//
// Copyright 17/02/2019
//

#ifndef FX

#include "i_system_win.h"

#include <stdarg.h>
#include <stdio.h>

#include "i_system_e32.h"

#include "lprintf.h"

#include "config.h"

/*
 SCREEN PROPERTIES
*/

#define I_SCREEN_WIDTH PHYSICAL_WIDTH
#define I_SCREEN_HEIGHT PHYSICAL_HEIGHT

#define SCALE_W 4
#define SCALE_H 4

//**************************************************************************************

unsigned int vid_width = 0;
unsigned int vid_height = 0;

unsigned int y_pitch = 0;

DoomWindow *window = NULL;

QApplication *app = NULL;

unsigned char *pb = NULL;
unsigned char *pl = NULL;

unsigned char *thearray = NULL;
int thesize;

unsigned short backbuffer[I_SCREEN_WIDTH * I_SCREEN_HEIGHT];
unsigned short frontbuffer[I_SCREEN_WIDTH * I_SCREEN_HEIGHT];

//**************************************************************************************

void I_InitScreen_e32()
{
    vid_width = I_SCREEN_WIDTH;

    vid_height = I_SCREEN_HEIGHT;
}

//**************************************************************************************

void I_BlitScreenBmp_e32()
{
}

//**************************************************************************************

void I_StartWServEvents_e32()
{
}

//**************************************************************************************

void I_PollWServEvents_e32()
{
}

//**************************************************************************************

void I_ClearWindow_e32()
{
}

unsigned short *I_GetBackBuffer()
{
    return &backbuffer[0];
}

unsigned short *I_GetFrontBuffer()
{
    return &frontbuffer[0];
}

//**************************************************************************************

void I_CreateWindow_e32()
{
    int z = 0;

    app = new QApplication(z, nullptr);

    window = new DoomWindow();

    window->setAttribute(Qt::WA_PaintOnScreen);

    window->resize(vid_width * SCALE_W, vid_height * SCALE_H);

    window->show();
}

//**************************************************************************************

void I_CreateBackBuffer_e32()
{
    I_CreateWindow_e32();
}

//**************************************************************************************

void I_FinishUpdate_e32(const char *srcBuffer, const char *pallete, const unsigned int width, const unsigned int height)
{
    pb = (unsigned char *)srcBuffer;
    pl = (unsigned char *)pallete;

    window->repaint();

    app->processEvents();

    int arrayCount = thesize;

    if (arrayCount == 0)
        return;

    // dump the _g->viewangletox var
    QFile f("C:\\temp\\gfx_stbar.c");
    f.open(QIODevice::ReadWrite);

    f.write("const byte gfx_stbar[");
    f.write(QString::number(arrayCount).toLatin1().constData());

    f.write("] =\n{\n");

    for (int i = 0; i < arrayCount; i++)
    {
        f.write(QString::number(thearray[i]).toLatin1().constData());
        f.write(",");

        if ((i % 16) == 0)
            f.write("\n");
    }

    f.write("\n};\n");

    f.close();
}

//**************************************************************************************

void I_SetPallete_e32(const char *pallete)
{
}

//**************************************************************************************

int I_GetVideoWidth_e32()
{
    return vid_width;
}

//**************************************************************************************

int I_GetVideoHeight_e32()
{
    return vid_height;
}

//**************************************************************************************

void I_ProcessKeyEvents()
{
    I_PollWServEvents_e32();
}

//**************************************************************************************

#define MAX_MESSAGE_SIZE 1024

void I_Error(const char *error, ...)
{
    char msg[MAX_MESSAGE_SIZE];

    va_list v;
    va_start(v, error);

    vsprintf(msg, error, v);

    va_end(v);

    printf("%s\n", msg);

    fflush(stderr);
    fflush(stdout);

    // fgets(msg, sizeof(msg), stdin);

    I_Quit_e32();
}

//**************************************************************************************

void I_Quit_e32()
{
}

//**************************************************************************************

#endif
