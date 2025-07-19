# You can theoretically send off _wepoll to other cython
# programs if you really wanted to however doing so may require
# you to have a copy of the C Library
from ._wepoll cimport *
