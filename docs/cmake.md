## Install With Source Code
### Remove Old Version

```
    $ sudo apt remove cmake
```
　　
### Load New

Load [cmake-3.19.0-rc3.tar.gz](https://cmake.org/files/v3.19/cmake-3.19.0-rc3.tar.gz) from https://cmake.org/download/ or https://cmake.org/files/.

```　
　　$ tar -zxvf cmake-3.19.0-rc3.tar.gz
　　$ cd cmake-3.19.0-rc3
　　$ ./configure
　　$ make
　　$ sudo make install
```

Add to environment variables.

```
    $ vim ~/.bashrc
        
        export PATH=/******/cmake-3.19.0-rc3/bin:$PATH

    $ source ~/.bashrc
```

##  Or Install With Compiled Package

### Load the compiled package 

Load [cmake-3.19.0-rc3-Linux-x86_64.tar.gz](https://cmake.org/files/v3.19/cmake-3.19.0-rc3-Linux-x86_64.tar.gz) from https://cmake.org/download/ or https://cmake.org/files/. Only support `Linux-x86_64`.

Only add to environment variables.

```
    $ tar -zxvf cmake-3.19.0-rc3-Linux-x86_64.tar.gz
    
    $ vim ~/.bashrc 
        export PATH=/******/cmake-3.19.0-rc3-Linux-x86_64/bin:$PATH
    $ source ~/.bashrc
    
```

Get the version

```
   $ cmake --version
```
