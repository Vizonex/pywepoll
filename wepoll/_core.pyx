from cpython.exc cimport PyErr_SetFromErrno, PyErr_SetObject, PyErr_SetFromWindowsErr, PyErr_SetFromErrno, PyErr_CheckSignals 
from cpython.bool cimport PyBool_FromLong
from cpython.time cimport PyTime_t, time
from cpython.mem cimport PyMem_Malloc, PyMem_Free
from .wepoll cimport *
from libc.math cimport ceil, floor

cdef extern from "handleapi.h" nogil:
    """
#ifndef HANDLE_FLAG_INHERIT
#define HANDLE_FLAG_INHERIT 0x00000001
#endif
    """
    ctypedef unsigned long DWORD
    bint SetHandleInformation(
        HANDLE hObject,
        DWORD  dwMask,
        DWORD  dwFlags
    )
    DWORD HANDLE_FLAG_INHERIT

cdef extern from "Python.h":
    ctypedef struct PyThreadState:
        pass
    cdef PyThreadState *PyEval_SaveThread()
    cdef void PyEval_RestoreThread(PyThreadState*)

cdef extern from "errno.h" nogil:
    cdef int errno
    cdef char *strerror(int)
    cdef int EINTR

DEF FD_SETSIZE = 512





cdef class epoll:
    cdef:
        HANDLE handle
        readonly bint closed

    # internal methods first then try mimicing python
    # doing so this way allows us to create a 
    # cpython capsule if we wish...
    
    # would've used nogil but it did not feel as clean as PyEval was
    cdef int _create(self, int sizehint):
        cdef PyThreadState* save = PyEval_SaveThread()
        self.handle = epoll_create(sizehint)
        PyEval_RestoreThread(save)
        return -1 if self.handle == NULL else 0

    cdef int _create1(self):
        cdef PyThreadState* save = PyEval_SaveThread()
        self.handle = epoll_create1(0)
        PyEval_RestoreThread(save)
        return -1 if self.handle == NULL else 0
        
    cdef int _close(self):
        cdef PyThreadState* save = PyEval_SaveThread()
        cdef int ret = epoll_close(self.handle)
        if ret < 0:
            errno = ret 
        PyEval_RestoreThread(save)
        return ret
    
    cdef int _ctl(self, int op, SOCKET sock, epoll_event* event):
        cdef PyThreadState* save = PyEval_SaveThread()
        cdef int ret = epoll_ctl(self.handle, op, sock, event)
        PyEval_RestoreThread(save)
        return ret
    
    cdef int _wait(self, epoll_event* events, int maxevents, int timeout):
        cdef PyThreadState* save = PyEval_SaveThread()
        cdef int ret = epoll_wait(self.handle, events, maxevents, timeout)
        PyEval_RestoreThread(save)
        return ret
    

    cdef int _init(self, int sizehint, HANDLE handle):
        if handle == NULL:
            if sizehint > 0:
                self._create(sizehint)
            else:
                self._create1()
                # optimzed version of _Py_set_inheritable for windows
                if not SetHandleInformation(self.handle, HANDLE_FLAG_INHERIT, 0):
                    PyErr_SetFromWindowsErr(0)
                    return -1
        else:
            self.closed = 0
            self.handle = handle
        return 0

    cdef int _handle_ctl_result(self, int result) except -1:
        if result < 0:
            errno = result
            PyErr_SetFromErrno(OSError)
            return -1
        return 0
    
    cdef int _pools_closed(self) except -1:
        if self.handle == NULL or self.closed:
            # Pools closed due to aids
            PyErr_SetObject(ValueError, "I/O operation on closed epoll object")
            return -1
        return 0

 
    # NOTE Flags is deprecated in select so no point in using it...
    def __init__(self, int sizehint = -1):
        if sizehint == -1:
            sizehint = FD_SETSIZE - 1
        
        elif sizehint <= 0:
            raise ValueError("negative sizehint")
        
        if self._init(sizehint, NULL) < 0:
            raise
    
    cpdef object close(self):
        if not self.closed:
            errno = self._close()
            if errno < 0:
                PyErr_SetFromErrno(errno)
            self.closed = True
    
    cpdef object register(self, SOCKET fd, unsigned int eventmask):
        cdef epoll_event ev
        cdef int result

        if self._pools_closed() < 0:
            raise

        ev.events = eventmask
        ev.data.sock = fd

        if self._handle_ctl_result(
            self._ctl(
                EPOLL_CTL_ADD, 
                fd,
                &ev
            )
        ) < 0:
            raise
            
    cpdef object modify(self, SOCKET fd, int eventmask):
        cdef epoll_event ev
        cdef int result
        if self._pools_closed() < 0:
            raise

        
        ev.events = eventmask
        ev.data.sock = fd

        if self._handle_ctl_result(
            self._ctl(
                EPOLL_CTL_MOD, 
                fd,
                &ev
            )
        ) < 0:
            raise

    cpdef object unregister(self, SOCKET fd):
        cdef epoll_event ev
        cdef int result

        if self._pools_closed() < 0:
            raise

        if self._handle_ctl_result(
            self._ctl(
                EPOLL_CTL_DEL, 
                fd,
                &ev
            )
        ) < 0:
            raise

    
    cpdef list poll(self, object timeout = None, int maxevents = -1):
        cdef double _timeout, deadline
        cdef epoll_event *evs = NULL
        cdef int nfds, i
        cdef list elist
        nfds = 0

        if timeout is not None:
            if isinstance(timeout, int):
                _timeout = <double>(<int>timeout * 1000)
            elif isinstance(timeout, float):
                _timeout = <double>((round(timeout, 3)) * 1000)

            else:
                raise TypeError(f"{type(timeout)} not supported")
            deadline = time() + _timeout
        else:
            _timeout = deadline = -1

        if maxevents == -1:
            maxevents = FD_SETSIZE - 1
        elif maxevents < 1:
            raise ValueError(f"maxevents must be greater than 0, got {maxevents}")
        
        evs = <epoll_event*>PyMem_Malloc(sizeof(epoll_event) * maxevents)
        if evs == NULL:
            raise MemoryError
        
        while True:
            errno = 0
            nfds = self._wait(evs, maxevents, <int>_timeout)
            if errno != EINTR:
                PyMem_Free(evs)
                break 
            if PyErr_CheckSignals() < 0:
                PyMem_Free(evs)
                raise

            if deadline != -1 and (time() > deadline):
                break
    
        elist = [(evs[i].data.fd, evs[i].events) for i in range(nfds)]
        PyMem_Free(evs)
        return elist

    def __enter__(self):
        return self
    
    def __exit__(self, *args):
        self.close()
    
    def __dealloc__(self):
        self.close()













        
        

    





