#ifndef __FIX_313_H__
#define __FIX_313_H__

// #if (PY_VERSION_HEX >= 0x030d00f0)
#include "Python.h"
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

/* Dear CPython devs, please stop having me try to force my hand 
 * by performing Code injections I don't like this at all. */

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

#endif // __FIX_313_H__