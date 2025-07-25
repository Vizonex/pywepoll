from .wepoll cimport *


# NOTE: Many portions of code can be externally 
# used in cython hence it's creation & setup
cdef class epoll:
    cdef:
        HANDLE handle
        readonly bint closed

    cdef int _create(self, int sizehint)
    cdef int _create1(self)
    cdef int _close(self)
    cdef int _ctl(self, int op, SOCKET sock, epoll_event* event)
    cdef int _wait(self, epoll_event* events, int maxevents, int timeout)
    cdef int _init(self, int sizehint, HANDLE handle)
    cdef int _handle_ctl_result(self, int result) except -1
    cdef int _pools_closed(self) except -1
    cpdef object close(self)
    cpdef object register(self, object fd, unsigned int eventmask)
    cpdef object modify(self, object fd, int eventmask)
    cpdef object unregister(self, object fd)
    cpdef list poll(self, object timeout =*, int maxevents =*)
