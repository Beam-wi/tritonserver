## INSTALL WITH SOURCE CODE
### Remove Old Version

```
    $ sudo apt remove cmake
```
　　
### Load New

Load tar from https://cmake.org/download/ or https://cmake.org/files/.

```　
　　$ tar -zxvf 	cmake-3.19.0-rc3.tar.gz
　　$ cd cmake-3.19.0
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

##  INSTALL WITH COMPILED PACKAGE

### Load the compiled package 

Load tar cmake-3.19.0-rc3-Linux-x86_64.tar.gz from https://cmake.org/download/ or https://cmake.org/files/.

Only add to environment variables.

```
    tar -zxvf cmake-3.19.0-rc3-Linux-x86_64.tar.gz
    
    vim ~/.bashrc 
        export PATH=/******/cmake-3.19.0-rc3-Linux-x86_64/bin:$PATH
    source ~/.bashrc
    
```

Get the version

```
   $ cmake --version
```