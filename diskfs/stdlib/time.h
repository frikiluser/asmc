#ifndef __TIME_H
#define __TIME_H

#include "asmc.h"

typedef long time_t;

struct tm {
    int tm_sec;
    int tm_min;
    int tm_hour;
    int tm_mday;
    int tm_mon;
    int tm_year;
    int tm_wday;
    int tm_yday;
    int tm_isdst;
};

// STUB
struct tm *localtime(const time_t *time) {
    __unimplemented();
    abort();
}

// STUB
time_t time(time_t *arg) {
    __unimplemented();
    abort();
}

#endif
