from libc.stdint cimport uint32_t as uint32_t
from libc.stdint cimport uint64_t as uint64_t
from libc.stdint cimport uintptr_t as uintptr_t


cdef extern from "wepoll/wepoll.h" nogil:
    enum EPOLL_EVENTS:
        # Aliasing so that python gets the real name
        EPOLLIN  = 1
        EPOLLPRI = 2
        EPOLLOUT = 4
        EPOLLERR = 8
        EPOLLHUP = 16
        EPOLLRDNORM = 64
        EPOLLRDBAND = 128
        EPOLLWRNORM = 256
        EPOLLWRBAND = 512
        EPOLLMSG = 1024
        EPOLLRDHUP = 8192
        EPOLLONESHOT = -2147483648
    
    int EPOLL_CTL_ADD
    int EPOLL_CTL_MOD
    int EPOLL_CTL_DEL
    ctypedef void* HANDLE
    ctypedef uintptr_t SOCKET
    union epoll_data:
        void* ptr
        int fd
        uint32_t u32
        uint64_t u64
        SOCKET sock
        HANDLE hnd
    ctypedef epoll_data epoll_data_t
    struct epoll_event:
        uint32_t events
        epoll_data_t data
    HANDLE epoll_create(int)
    HANDLE epoll_create1(int)
    int epoll_close(HANDLE)
    int epoll_ctl(HANDLE, int, SOCKET, epoll_event*)
    int epoll_wait(HANDLE, epoll_event*, int, int)




