void abort(void) {
    while (1); 
}

void _abort(void) {
    abort();
}

void *memcpy(void *dest, const void *src, unsigned int n) {
    char *d = dest;
    const char *s = src;
    while (n--) {
        *d++ = *s++;
    }
    return dest;
}

void *memset(void *s, int c, unsigned int n) {
    char *p = s;
    while (n--) {
        *p++ = c;
    }
    return s;
}
