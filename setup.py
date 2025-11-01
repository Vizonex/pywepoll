from Cython.Build import cythonize
from setuptools import Extension, setup

import sys
if sys.version_info[:2] < (3, 10):
    from warnings import warn
    warn(
        "3.9 will be dropped in"
        "version 0.1.4 consider upgrading",
        DeprecationWarning
    )


# TODO: Move to pyproject.toml setup like in pyduktape3
setup(
    ext_modules=cythonize(
        [
            Extension(
                "wepoll._wepoll",
                ["wepoll/_wepoll.pyx", "vendor/wepoll/wepoll.c"],
                include_dirs=["vendor/wepoll"],
                libraries=["advapi32", "iphlpapi", "psapi", "ws2_32"],
            )
        ]
    )
)
