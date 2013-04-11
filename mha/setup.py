from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

ext_modules = [Extension("mht_c",
	["mht/mht_c.pyx"],
	libraries=['m'])
]

setup(
  name = 'MHT Compiled Portion',
  cmdclass = {'build_ext': build_ext},
  ext_modules = ext_modules
)
