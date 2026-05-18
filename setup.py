from Cython.Build import cythonize
from setuptools import Extension, setup

# TODO: add linux support for compatability with other Epoll libraries
# as an extra bonus feature.
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
