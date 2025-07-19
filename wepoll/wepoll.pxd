from libc.stdint cimport uint32_t as uint32_t
from libc.stdint cimport uint64_t as uint64_t
from libc.stdint cimport uintptr_t as uintptr_t


cdef extern from "wepoll.h" nogil:
    enum EPOLL_EVENTS:
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

    # Documentation was copied over from wepoll's readme 
    # to help any user troubleshooting this library.

    HANDLE epoll_create(int size)
    HANDLE epoll_create1(int flags)
    # Create a new epoll instance (port).
    # `size` is ignored but most be greater than zero.
    # `flags` must be zero as there are no supported flags.
    # Returns `NULL` on failure.

    int epoll_close(HANDLE ephnd)
    # Close an epoll port.
    # Do not attempt to close the epoll port with `close()`,
    # `CloseHandle()` or `closesocket()`.

    int epoll_ctl(HANDLE ephnd, int op, SOCKET sock, epoll_event* event)
    # Control which socket events are monitored by an epoll port.
    # `ephnd` must be a HANDLE created by
    #   epoll_create() or epoll_create1().
    #  `op` must be one of `EPOLL_CTL_ADD`, `EPOLL_CTL_MOD`, `EPOLL_CTL_DEL`.
    # `sock` must be a valid socket created by socket()[msdn socket],
    #   WSASocket()[msdn wsasocket], or accept()[msdn accept].
    # `event` should be a pointer to a struct epoll_event(#struct-epoll_event).<br>
    #   If `op` is `EPOLL_CTL_DEL` then the `event` parameter is ignored, and it
    #   may be `NULL`.
    # Returns 0 on success, -1 on failure.
    # It is recommended to always explicitly remove a socket from its epoll
    #   set using `EPOLL_CTL_DEL` *before* closing it.<br>
    #   As on Linux, closed sockets are automatically removed from the epoll set, but
    #   wepoll may not be able to detect that a socket was closed until the next call
    #   to epoll_wait()
    
    int epoll_wait(HANDLE ephnd, epoll_event* events, int maxevents, int timeout)
    # Receive socket events from an epoll port.
    # * `events` should point to a caller-allocated array of
    #   `epoll_event` structs, which will receive the
    #   reported events.
    # * `maxevents` is the maximum number of events that will be written to the
    #   `events` array, and must be greater than zero.
    # * `timeout` specifies whether to block when no events are immediately available.
    #   - `<0` block indefinitely
    #   - `0`  report any events that are already waiting, but don't block
    #   - `≥1` block for at most N milliseconds
    # * Return value:
    #   - `-1` an error occurred
    #   - `0`  timed out without any events to report
    #   - `≥1` the number of events stored in the `events` buffer


