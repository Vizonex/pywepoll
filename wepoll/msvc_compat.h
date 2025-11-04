#ifndef __MSVC_COMPAT_H__
#define __MSVC_COMPAT_H__

/* Made under the terms of the MIT License but feel free to copy and 
paste if you need to borrow this code elsewhere... - Vizonex */

#include <io.h> /* _get_osfhandle */
#include "Python.h"

/* There's some operations that C does better than cython hence doing it here... */
/* this is a copy of _Py_get_osfhandle but with an added optimization for better error handling */

/// @brief Same as _Py_get_osfhandle but with some minor improvements taken into 
/// account for better speed and control using rust-like error handling. The one unfortunate 
/// downside might be that sys.audit is not used for better or for worse...
/// @param ret_handle handle to be returned on (success = handle) or (failure = NULL)
/// @param fd the file descriptor to obtain the handle from
/// @return -1 on error, 0 on success... raises OSError if this function ends up failing...
int get_osfhandle(void** ret_handle, int fd){
    intptr_t handle = _get_osfhandle(fd);
    if (handle == -1){
        PyErr_SetFromErrno(PyExc_OSError);
        *ret_handle = NULL;
        return -1;
    }
    *ret_handle = (void*)(handle);
    return 0;
}

#endif // __MSVC_COMPAT_H__