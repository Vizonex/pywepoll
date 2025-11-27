# Msvc runtime bindings needed for handles with this library

cdef extern from "msvc_compat.h":
   # we don't need except -1 since we do error handling ourselves but if you want to use this code elsewhere I can't stop you, 
   # I made sure I fully documented it if you need it. - Vizonex
   int get_osfhandle(void** ret_handle, int fd) # excpet -1 

   