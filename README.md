# gcc-vxworks
Helpers script to compile a version of GCC that crosscompiles to VxWorks. 

Table of Contents
=================
  * [Installation from binaries and usage](#installation-from-binaries-and-usage)
    * [Windows](#windows)
  * [Compilation from source code](#compilation-from-source-code)
    * [Windows with MSYS2 MinGW 64-bit](#windows-with-msys2-mingw-64-bit) 
    * [Ubuntu](#ubuntu-1804)
  * [Troubleshooting](#troubleshooting)

## Installation from binaries and usage

### Windows 
To use the GCC-based VxWorks compiler on Windows, you need to install [`CMake`](https://cmake.org/), [`Ninja`](https://ninja-build.org/) and [`Git for Windows`](https://gitforwindows.org/). Make sure that both `CMake` and `Ninja` executables are on the [`Path` enviromental variable](https://superuser.com/questions/297947/is-there-a-convenient-way-to-edit-path-in-windows-7), so that if you type `cmake` or `ninja` in the Git Bash, the commands are execute out of the box. 

To install the compiler, you can download the binaries at https://github.com/iit-danieli-joint-lab/idjl-gcc-vxworks/releases/download/v0.2.0/idjl-gcc-vxworks-windows-x64.zip, and unzip them in any directory.

To use the GCC-based VxWorks compiler, open the Git bash and source the `setup.sh` file:
~~~
source /path/where/you/downloaded/gcc-vxworks/setup.sh
~~~
Note that for any new terminal in which you want to run the compiler, you need to source the `setup.sh` script again. 
To source the script automatically, you can create a `.bash_profile` file in your home and add the source command there. 


To generate a CMake project that target VxWorks, create a `build-vxworks` directory and pass `vxworks_toolchain.cmake.in` as the [`CMAKE_TOOLCHAIN_FILE`](https://cmake.org/cmake/help/v3.10/variable/CMAKE_TOOLCHAIN_FILE.html) option, using the `Ninja` generator.
~~~
mkdir build-vxworks
cd build-vxworks
cmake -GNinja -DCMAKE_TOOLCHAIN_FILE=/path/where/you/downloaded/gcc-vxworks/vxworks_toolchain.cmake.in /path/of/the/cmake/project/srcs 
~~~
then, you can compile your code using the `ninja` command:
~~~
ninja
~~~

## Compilation from source code

For compiling the GCC compiler with VxWorks support, you need a bash like enviroment. 
The enviroment in which this has been tested have been Ubuntu 18.04 and on Windows the MSYS2 MinGW 64-bit enviroment. 

## Windows with MSYS2 MinGW 64-bit

First, install the [MSYS2](https://www.msys2.org/) enviroment using the [installer](http://repo.msys2.org/distrib/x86_64/msys2-x86_64-20180531.exe). 

Then, open an `MSYS2 MinGW 64-bit` terminal (not a `MSYS2 MSYS` or `MSYS2 MinGW 32-bit` one!) and first install the development tools:
~~~
pacman -S base-devel git mingw-w64-x86_64-toolchain mingw-w64-x86_64-cmake unzip
~~~

After the installation terminates successfully, open a new `MSYS2 MinGW 64-bit` terminal to make sure that all the installed packages are available, and clone the repo and run the script:
~~~
git clone https://github.com/genIoco/gcc-vxworks
cd  gcc-vxworks
./build_gcc_vxworks.sh 
~~~
the build can take some time (up to one hour). 
If the build ends successfully (i.e. it prints  'Success!' at the end of the output), then the compiler and related tools are 
installed in the `gcc-vxworks/install` directory and ready to be used. 

To prepare a new release that can be used as described in the [previous section](#installation-from-binaries-and-usage), you just need to zip the the `install` directory, renaming the directory `idjl-gcc-vxworks-windows-x64` and naming the `.zip` file `idjl-gcc-vxworks-windows-x64.zip`.

### Ubuntu 18.04 

Install development tools: 
~~~
sudo apt install \
  bison \
  build-essential \
  dejagnu \
  expect \
  flex \
  git \
  gnat-7 \
  libisl-dev \
  libisl15 \
  libisl19 \
  texinfo \
  unzip \
  wget
~~~

Clone this repository and cd in the directory:
~~~
git clone https://github.com/genIoco/gcc-vxworks
cd  gcc-vxworks
~~~

Launch the building script (warning: the build can take more than an hour. To avoid losing time if there are problems and the build needs to restart, it is recommended to use [ccache](https://ccache.samba.org/)):
~~~
./build_gcc_vxworks.sh 
~~~

If the build ends successfully (i.e. it prints  'Success!' at the end of the output), then the compiler is ready to be used. 

## Troubleshooting
### environment variable ‘WIND_BASE’ not defined

If then compiling you get the error: 
~~~
i586-wrs-vxworks-gcc: fatal error: environment variable ‘WIND_BASE’ not defined
~~~
that means that in that terminal the `WIND_BASE` env variables is not defined, so you need to source the `gcc-vxworks/setup.sh` script again.
