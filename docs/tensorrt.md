### Dependencies

Download deb from https://developer.download.nvidia.cn/compute/machine-learning/repos/ubuntu1804/x86_64/

		libnvinfer7
		libnvinfer-dev
		libnvinfer-plugin7
		libnvinfer-plugin-dev
		
Check installed

    $ dpkg -L libnvinfer-dev
        /.
        /usr
        /usr/include
        /usr/include/x86_64-linux-gnu
        /usr/include/x86_64-linux-gnu/NvInfer.h
        ...
    $ dpkg 
        /.
        /usr
        /usr/include
        /usr/include/x86_64-linux-gnu
        /usr/include/x86_64-linux-gnu/NvInferPlugin.h
        /usr/include/x86_64-linux-gnu/NvInferPluginUtils.h
        ...
	Just NvInfer.h and NvInferPlugin.h we use for tritonserver cmake.
	
### Install TensorRT

The deb file can be install with many dependent packages, so it is recommended to use tar which compiled package to be installed.
        
* Pycuda

    Pycuda should be installed when use python API.
```            
    $ pip install 'pycuda>=2017.1.1'
```      

* TensorRT
Pull installation documentation from https://developer.nvidia.com/nvidia-tensorrt-download
   
#### Unpacking
    $ tar xzvf TensorRT-7.1.3.4.Ubuntu-18.04.x86_64-gnu.cuda-10.2.cudnn8.0.tar.gz

#### Add lib to environment variables
    $ export TRT_RELEASE=/opt/TensorRT-7.1.3.4
    $ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/lthpc/tensorrt_tar/TensorRT-7.1.3.4/lib
 
#### Install TensorRT
    $ cd TensorRT-7.1.3.4/python
    $ pip install tensorrt-7.1.3.4-cp36-none-linux_x86_64.whl
 
#### Install UFF
    $ cd TensorRT-7.1.3.4/uff
    $ pip install uff-0.6.9-py2.py3-none-any.whl
 
#### Install graphsurgeon
    $ cd TensorRT-7.1.3.4/graphsurgeon
    $ pip install graphsurgeon-0.4.5-py2.py3-none-any.whl
    
In case Later DeepStream couldn't find tensorrt's library，It is recommended that tensorRT's libraries and headers be added to the system path.

    # Under TensorRT Path
    $ sudo cp -r ./lib/* /usr/lib
    $ sudo cp -r ./include/* /usr/include