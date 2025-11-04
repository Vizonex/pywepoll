# cython: freethreading = True
cimport cython
from cpython.exc cimport (
    PyErr_CheckSignals, 
    PyErr_SetFromErrno,
    PyErr_SetFromWindowsErr, 
    PyErr_SetObject
)
from cpython.mem cimport PyMem_Free, PyMem_Malloc
from cpython.object cimport PyObject_TypeCheck
from libc.limits cimport INT_MAX, INT_MIN

from cpython.time cimport PyTime_t as PyTime_t
from cpython.time cimport monotonic_ns as monotonic_ns

from .msvcrt cimport get_osfhandle
from .socket cimport cimport_socket, socket
from .wepoll cimport *

# Inspired by the original 2006 cython epoll twisted code and CPython's vesion


# TODO: make C-API Capsule in a later update and then migrate to CPython 
# so that the cython functionality can at least be retained.



cdef extern from "Python.h":
    """

/* Dear CPython devs, please stop having me try to force my hand 
 * by performing Code injections I don't like this at all. */

// 3.13 is cursed...
#if (PY_VERSION_HEX >= 0x030d00f0)

/* I hate this */
#include <math.h>

typedef int64_t _PyTime_t;

#ifndef PyTime_MIN
    #define PyTime_MIN INT64_MIN
#endif
#ifndef PyTime_MAX
    #define PyTime_MAX INT64_MAX
#endif

#define SEC_TO_MS 1000

/* To microseconds (10^-6) */
#define MS_TO_US 1000
#define SEC_TO_US (SEC_TO_MS * MS_TO_US)

/* To nanoseconds (10^-9) */
#define US_TO_NS 1000
#define MS_TO_NS (MS_TO_US * US_TO_NS)
#define SEC_TO_NS (SEC_TO_MS * MS_TO_NS)

/* Conversion from nanoseconds */
#define NS_TO_MS (1000 * 1000)
#define NS_TO_US (1000)
#define NS_TO_100NS (100)

typedef enum {
    // Round towards minus infinity (-inf).
    // For example, used to read a clock.
    _PyTime_ROUND_FLOOR=0,

    // Round towards infinity (+inf).
    // For example, used for timeout to wait "at least" N seconds.
    _PyTime_ROUND_CEILING=1,

    // Round to nearest with ties going to nearest even integer.
    // For example, used to round from a Python float.
    _PyTime_ROUND_HALF_EVEN=2,

    // Round away from zero
    // For example, used for timeout. _PyTime_ROUND_CEILING rounds
    // -1e-9 to 0 milliseconds which causes bpo-31786 issue.
    // _PyTime_ROUND_UP rounds -1e-9 to -1 millisecond which keeps
    // the timeout sign as expected. select.poll(timeout) must block
    // for negative values.
    _PyTime_ROUND_UP=3,

    // _PyTime_ROUND_TIMEOUT (an alias for _PyTime_ROUND_UP) should be
    // used for timeouts.
    _PyTime_ROUND_TIMEOUT = _PyTime_ROUND_UP
} _PyTime_round_t;


static void
pytime_time_t_overflow(void)
{
    PyErr_SetString(PyExc_OverflowError,
                    "timestamp out of range for platform time_t");
}


static void
pytime_overflow(void)
{
    PyErr_SetString(PyExc_OverflowError,
                    "timestamp too large to convert to C PyTime_t");
}

static double
pytime_round_half_even(double x)
{
    double rounded = round(x);
    if (fabs(x-rounded) == 0.5) {
        /* halfway case: round to even */
        rounded = 2.0 * round(x / 2.0);
    }
    return rounded;
}

static double
pytime_round(double x, _PyTime_round_t round)
{
    /* volatile avoids optimization changing how numbers are rounded */
    volatile double d;

    d = x;
    if (round == _PyTime_ROUND_HALF_EVEN) {
        d = pytime_round_half_even(d);
    }
    else if (round == _PyTime_ROUND_CEILING) {
        d = ceil(d);
    }
    else if (round == _PyTime_ROUND_FLOOR) {
        d = floor(d);
    }
    else {
        assert(round == _PyTime_ROUND_UP);
        d = (d >= 0.0) ? ceil(d) : floor(d);
    }
    return d;
}


static int
pytime_from_double(_PyTime_t *tp, double value, _PyTime_round_t round,
                   long unit_to_ns)
{
    /* volatile avoids optimization changing how numbers are rounded */
    volatile double d;

    /* convert to a number of nanoseconds */
    d = value;
    d *= (double)unit_to_ns;
    d = pytime_round(d, round);

    /* See comments in pytime_double_to_denominator */
    if (!((double)PyTime_MIN <= d && d < -(double)PyTime_MIN)) {
        pytime_time_t_overflow();
        *tp = 0;
        return -1;
    }
    _PyTime_t ns = (_PyTime_t)d;

    *tp = ns;
    return 0;
}

static inline int
pytime_mul_check_overflow(_PyTime_t a, _PyTime_t b)
{
    if (b != 0) {
        assert(b > 0);
        return ((a < PyTime_MIN / b) || (PyTime_MAX / b < a));
    }
    else {
        return 0;
    }
}


static inline int
pytime_mul(_PyTime_t *t, _PyTime_t k)
{
    assert(k >= 0);
    if (pytime_mul_check_overflow(*t, k)) {
        *t = (*t >= 0) ? PyTime_MAX : PyTime_MIN;
        return -1;
    }
    else {
        *t *= k;
        return 0;
    }
}


static int
pytime_from_object(_PyTime_t *tp, PyObject *obj, _PyTime_round_t round,
                   long unit_to_ns)
{
    if (PyFloat_Check(obj)) {
        double d;
        d = PyFloat_AsDouble(obj);
        if (isnan(d)) {
            PyErr_SetString(PyExc_ValueError, "Invalid value NaN (not a number)");
            return -1;
        }
        return pytime_from_double(tp, d, round, unit_to_ns);
    }

    long long sec = PyLong_AsLongLong(obj);
    if (sec == -1 && PyErr_Occurred()) {
        if (PyErr_ExceptionMatches(PyExc_OverflowError)) {
            pytime_overflow();
        }
        else if (PyErr_ExceptionMatches(PyExc_TypeError)) {
            PyErr_Format(PyExc_TypeError,
                         "'%T' object cannot be interpreted as an integer or float",
                         obj);
        }
        return -1;
    }

    static_assert(sizeof(long long) <= sizeof(_PyTime_t),
                  "PyTime_t is smaller than long long");
    _PyTime_t ns = (_PyTime_t)sec;
    if (pytime_mul(&ns, unit_to_ns) < 0) {
        pytime_overflow();
        return -1;
    }

    *tp = ns;
    return 0;
}


int
_PyTime_FromSecondsObject(_PyTime_t *tp, PyObject *obj, _PyTime_round_t round)
{
    return pytime_from_object(tp, obj, round, SEC_TO_NS);
}
 
#endif

typedef _PyTime_round_t PyTime_round_t;
#define PyTime_FromSecondsObject _PyTime_FromSecondsObject

/* From Python 3.14 Brought here for backwards comptability*/

#ifndef PyTime_MAX
    #define PyTime_MAX LLONG_MAX
#endif
#ifndef PyTime_MIN
    #define PyTime_MIN LLONG_MIN
#endif

static inline int
compat_pytime_add(int64_t *t1, int64_t t2)
{
    if (t2 > 0 && *t1 > PyTime_MAX - t2) {
        *t1 = PyTime_MAX;
        return -1;
    }
    else if (t2 < 0 && *t1 < PyTime_MIN - t2) {
        *t1 = PyTime_MIN;
        return -1;
    }
    else {
        *t1 += t2;
        return 0;
    }
}

int64_t
_PyTime_Add(int64_t t1, int64_t t2)
{
    (void)compat_pytime_add(&t1, t2);
    return t1;
}
#define PyTime_Add _PyTime_Add
"""
   
    enum _PyTime_round_t:
        # Round towards minus infinity (-inf).
        # For example, used to read a clock.
        _PyTime_ROUND_FLOOR = 0,
        # Round towards infinity (+inf).
        # For example, used for timeout to wait "at least" N seconds.
        _PyTime_ROUND_CEILING = 1,
        # Round to nearest with ties going to nearest even integer.
        # For example, used to round from a Python float.
        _PyTime_ROUND_HALF_EVEN =2 ,
        # Round away from zero
        # For example, used for timeout. _PyTime_ROUND_CEILING rounds
        # -1e-9 to 0 milliseconds which causes bpo-31786 issue.
        _PyTime_ROUND_UP = 3
        #    the timeout sign as expected. select.poll(timeout) must block
        #    for negative values."
        # _PyTime_ROUND_TIMEOUT (an alias for _PyTime_ROUND_UP) should be
        # used for timeouts.
        _PyTime_ROUND_TIMEOUT = 3

    ctypedef _PyTime_round_t PyTime_round_t
    # Comptable version of _PyTime_Add for older versions of Python
    PyTime_t PyTime_Add(PyTime_t t1, PyTime_t t2)
    int PyTime_FromSecondsObject(PyTime_t *t, object obj, PyTime_round_t round)
    PyTime_t _PyTime_AsMilliseconds(PyTime_t timeout, PyTime_round_t round)

# Recasts so that my Cyright extension doesn't misbehave
cdef PyTime_round_t PyTime_ROUND_TIMEOUT = _PyTime_ROUND_TIMEOUT
cdef PyTime_round_t PyTime_ROUND_FLOOR = _PyTime_ROUND_FLOOR
cdef PyTime_round_t PyTime_ROUND_UP = _PyTime_ROUND_UP
cdef PyTime_round_t PyTime_ROUND_CEILING = _PyTime_ROUND_CEILING
cdef PyTime_round_t PyTime_ROUND_HALF_EVEN = _PyTime_ROUND_HALF_EVEN



cdef extern from "windows.h" nogil:
    pass

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

# cdef extern from "Python.h":
#     ctypedef struct PyThreadState:
#         pass
#     cdef PyThreadState *PyEval_SaveThread()
#     cdef void PyEval_RestoreThread(PyThreadState*)

cdef extern from "errno.h" nogil:
    """
#define wepoll_set_errno(err) errno = err
    """
    cdef int errno
    cdef char *strerror(int)
    cdef int EINTR
    void wepoll_set_errno(int)

DEF FD_SETSIZE = 512


 
# Keep final the same way select does on linux
@cython.final
cdef class epoll:
    # internal methods first then try mimicing python
    # doing so this way allows us to create a 
    # cpython capsule if we wish...

    cdef SOCKET _fd_from_object(self, object obj) except -1:
        # Made threasafe in 0.1.3 by only making init need to cimport the capsule.
        if PyObject_TypeCheck(obj, self.socket_api.Sock_Type):
            return (<socket>obj).sock_fd
        elif isinstance(obj, int):
            return <SOCKET>obj
        else:
            PyErr_SetObject(TypeError, f"{obj!r} not supported")
            return -1
    
    # would've used nogil but it did not feel as clean as PyEval was
    cdef int _create(self, int sizehint):
        # cdef PyThreadState* save = PyEval_SaveThread()
        cdef void* handle
        with nogil:
            handle = epoll_create(sizehint)
        self.handle = handle
        return -1 if self.handle == NULL else 0

    cdef int _create1(self):
        cdef void* handle
        with nogil:
            handle = epoll_create1(0)
        self.handle = handle
        return -1 if self.handle == NULL else 0
        
    cdef int _close(self):
        cdef void* handle = self.handle
        cdef int ret
        with nogil:
            ret = epoll_close(handle)
            if ret < 0:
                wepoll_set_errno(ret)
        return ret
    
    # TODO: In the future I will provide a way to make it so that 
    # other types of data besides just sockets can get polled.

    cdef int _ctl(self, int op, SOCKET sock, epoll_event* event) except -1:
        cdef void* handle = self.handle
        cdef int ret
        with nogil:
            ret = epoll_ctl(handle, op, sock, event)

        if ret < 0:
            PyErr_SetFromErrno(OSError)
            return -1
        return ret

    cdef int _wait(self, epoll_event* events, int maxevents, int timeout):
        cdef void* handle = self.handle
        cdef int ret
        with nogil:
            ret = epoll_wait(self.handle, events, maxevents, timeout)
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
            wepoll_set_errno(result)
            PyErr_SetFromErrno(OSError)
            return -1
        return 0
    
    cdef int _pools_closed(self) except -1:
        if self.handle == NULL or self.closed:
            # Pools closed due to aids
            PyErr_SetObject(RuntimeError, "I/O operation on closed epoll object")
            return -1
        return 0
 
    # NOTE Flags are deprecated in select standard library so no point in using it here...
    def __init__(self, int sizehint = -1):
        if sizehint == -1:
            sizehint = FD_SETSIZE - 1
        
        elif sizehint <= 0:
            raise ValueError("negative sizehint")
        
        # NOTE: Throw me an issue if a memory leak is noticable.
        # I will then be able to diagnose if this was the reason.
        self.socket_api = cimport_socket()
        if self.socket_api == NULL:
            raise

        if self._init(sizehint, NULL) < 0:
            raise

    cpdef uintptr_t fileno(self):
        """Return the file descriptor number of the control fd.
        on windows this recasts the handle to a `uintptr_t` to a 
        PyLongObject (int)."""
        return <uintptr_t>self.handle


    cpdef object close(self):
        """Close the control file descriptor of the epoll object.

        Raises:
            OSError: if close fails.
        """
        cdef int _errno
        if not self.closed:
            _errno = self._close()
            if _errno < 0:
                wepoll_set_errno(_errno)
                PyErr_SetFromErrno(OSError)
                raise
            self.closed = True
    
    cpdef object register(self, object fd, unsigned int eventmask):
        cdef epoll_event ev
        cdef SOCKET _fd

        if self._pools_closed() < 0:
            raise

        _fd = self._fd_from_object(fd)
        ev.events = eventmask
        ev.data.sock = _fd
        if self._ctl(EPOLL_CTL_ADD, _fd, &ev) < 0:
            raise
            
    cpdef object modify(self, object fd, unsigned int eventmask):
        """Modify a registered file descriptor.
        
        Parameters
        ----------

        :param fd: a `socket` or `int` object of a file descriptor
        :param eventmask: A List of epoll flags to set for the modified fd.

        Raises:
            TypeError: if obtaining the file descriptor from the 
                python object fails or is an invalid type.

            RuntimeError: if epoll is closed.

        """
        cdef epoll_event ev
        cdef SOCKET _fd

        if self._pools_closed() < 0:
            raise
        _fd = self._fd_from_object(fd)
        ev.events = eventmask
        ev.data.sock = _fd
        if self._ctl(EPOLL_CTL_MOD, _fd, &ev) < 0:
            raise

    cpdef object unregister(self, object fd):
        """
        Remove a registered file descriptor from the epoll object.

        Parameters
        ----------

        :param fd: a `socket` or `int` object of a file descriptor


        Raises:
            OSError: if unregistering the file descriptor fails.

        """
        cdef epoll_event ev
        cdef SOCKET _fd
        cdef int result

        if self._pools_closed() < 0:
            raise
        
        _fd = self._fd_from_object(fd)
        if self._ctl(EPOLL_CTL_DEL, _fd, &ev) < 0:
            raise

    cpdef list poll(self, object timeout = None, int maxevents = -1):
        """
        Wait for events. timeout in seconds (float)
        
        Parameters
        ----------

        :param timeout: timeout in seconds (float or int)
        :param maxevent: maximum number of events to listen for default is -1 which will be a varaious amount.
            Passing -1 to maxevents is discouraged and should be left alone instead if chosen to omit or ignore
        Raises:
            TypeError: if timeout type is not supported
            ValueError: if maxevents is less than -1 


        """
        cdef PyTime_t _timeout, deadline, ms
        cdef epoll_event *evs = NULL
        cdef int nfds, i
        cdef list elist
        cdef void* handle = self.handle

        _timeout = deadline = -1
        nfds = 0
        if timeout is not None:
            if PyTime_FromSecondsObject(&_timeout, timeout, PyTime_ROUND_TIMEOUT) < 0:
                raise TypeError(f"{timeout!r} not supported")

            # add timeout by current time as a monotonic clock using Python's
            # Normal API So that we can mimic linux's python epoll system. 
            
            ms = _PyTime_AsMilliseconds(_timeout, _PyTime_ROUND_CEILING)
            if ms < INT_MIN or ms > INT_MAX:
                raise OverflowError("timeout is too large")
            if ms < 0:
                ms = -1
            
            if _timeout >= 0:
                deadline = PyTime_Add(monotonic_ns(), _timeout)
            

        if maxevents == -1:
            maxevents = FD_SETSIZE - 1
        elif maxevents < 1:
            raise ValueError(f"maxevents must be greater than 0, got {maxevents}")

        evs = <epoll_event*>PyMem_Malloc(sizeof(epoll_event) * maxevents)
        if evs == NULL:
            raise MemoryError
        
        while True:
            with nogil:
                errno = 0
                nfds = epoll_wait(handle, evs, maxevents, <int>ms)
    
            if nfds > 0:
                break

            if nfds < 0:
                PyMem_Free(evs)
                PyErr_SetFromErrno(OSError)
                raise

            # check for ctrl+C from end user wanting to stop program
            if PyErr_CheckSignals() < 0:
                PyMem_Free(evs)
                raise

            if timeout >= 0:
                timeout = deadline - monotonic_ns()
                if (timeout < 0):
                    nfds = 0
                    break
                ms = _PyTime_AsMilliseconds(timeout, _PyTime_ROUND_CEILING)

        elist = [(evs[i].data.fd, evs[i].events) for i in range(nfds)]
        PyMem_Free(evs)
        return elist

    def __enter__(self):
        return self
    
    def __exit__(self, *args):
        self.close()
    
    def __dealloc__(self):
        self.close()
    
    @classmethod
    def fromfd(cls, int fd):
        """creates a epoll (wepoll) from msvcrt using _get_osfhandle(fd) 
        from `io.h` in C to get the file descriptor's handle"""
        cdef epoll poll = cls.__new__(cls)
        cdef void* handle = NULL

        if get_osfhandle(&handle, fd) < 0:
            # Reraise the OS Error we had setup previously...
            raise 

        if poll._init(FD_SETSIZE - 1, handle) < 0:
            raise
        return poll    
