#include <pthread.h>
#include <sys/mman.h>		/* PROT_*, MAP_* */
#include <fcntl.h>		/* O_* */

/* Declarations. These are split this way to avoid compiler warnings. */

extern size_t sizeof_pthread_mutex_t;
extern size_t sizeof_pthread_mutexattr_t;

extern int pthread_process_shared;

extern int o_rdwr;
extern int o_creat;

extern int prot_read;
extern int prot_write;
extern int prot_exec;
extern int prot_none;

extern void * map_failed;

extern int map_shared;
extern int map_private;

/* Definitions. These are split from declrations to avoid compiler warnings. */

size_t sizeof_pthread_mutex_t = sizeof (pthread_mutex_t);
size_t sizeof_pthread_mutexattr_t = sizeof (pthread_mutexattr_t);

int pthread_process_shared = PTHREAD_PROCESS_SHARED;

int o_rdwr = O_RDWR;
int o_creat = O_CREAT;

int prot_read = PROT_READ;
int prot_write = PROT_WRITE;
int prot_exec = PROT_EXEC;
int prot_none = PROT_NONE;

void * map_failed = MAP_FAILED;

int map_shared = MAP_SHARED;
int map_private = MAP_PRIVATE;
