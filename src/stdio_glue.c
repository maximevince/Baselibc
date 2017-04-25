#include <stdio.h>
#include <unistd.h>

#if defined(linux)

/* Connects the baselibc stdio to normal POSIX stdio */
size_t write(int fd, const void *buf, size_t count);
size_t read(int fd, const void *buf, size_t count);

__attribute__( (weak) )
static size_t _write(FILE *instance, const char *bp, size_t n)
{
    if (instance == stdout)
        return write(1, bp, n);
    else
        return write(2, bp, n);
}

static struct File_methods stdio_methods = {
        &_write, &read
};

#else

//extern size_t write(FILE *file, const char *buf, size_t count);
//extern size_t read(FILE *file, const char *buf, size_t count);
static struct File_methods stdio_methods = {
        (void *)&write, (void *)&read
};
#endif

static struct File _stdall = {
        &stdio_methods
};

FILE* const stdin = &_stdall;
FILE* const stdout = &_stdall;
FILE* const stderr = &_stdall;
