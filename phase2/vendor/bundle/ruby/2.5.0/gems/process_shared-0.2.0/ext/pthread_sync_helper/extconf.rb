require 'mkmf'

#have_func("pthread_mutex_init", "pthread.h")
#have_func("pthread_cond_init", "pthread.h")
#have_func("pthread_mutex_trylock", "pthread.h")

have_library("pthread", "pthread_mutex_init")

create_makefile("pthread_sync_helper")
