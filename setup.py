from Cython.Build import cythonize
from setuptools import Extension, setup


# TODO: Move to pyproject.toml setup like in pyduktape3 in 0.1.6
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

