from setuptools import Extension, setup
from Cython.Build import cythonize

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
