#!/bin/bash -e

#### NOTE ####
# Мое мнение, что студенты должны писать хедер, где будет описаны границы использования их скрипта
# Также приучать их это делать на английском языке
#### /NOTE ####


#### Example ####
# Ubuntu 14.04.5 or Ubuntu 16.04.xx (Kernel 4.4)
# Due to the USB 3.0 translation layer between native hardware and virtual machine, 
# the librealsense team does not recommend or support installation in a VM.
#### /Example ####


#### NOTE ####
# Вот тут хорошая практика, проверить, установлено что-то уже или нет
# После можно позадавать интересные вопросы на понимание того, что написано
#### /NOTE ####


#### Example ####
# Install git
if ! [ -x "$(command -v git)" ]; then
	echo 'Git is not installed. Installing git...'
	sudo apt install git
else
	echo 'Git is already installed'
fi
#### /Example ####

# clone repo
git clone https://github.com/IntelRealSense/librealsense.git

# Ensure apt-get is up to date.
# Note: Use sudo apt-get dist-upgrade, instead of sudo apt-get upgrade, 
# in case you have an older Ubuntu 14.04 version (with deprecated nvidia-331* packages installed), 
# as this prevents the linux 4.4* kernel to compile properly.
sudo apt-get update && sudo apt-get upgrade

# Install libusb-1.0 and pkg-config via apt-get
sudo apt-get install libusb-1.0-0-dev pkg-config

# Installs glfw3 from source as a shared lib
sudo apt-get install build-essential cmake git xorg-dev libglu1-mesa-dev
git clone https://github.com/glfw/glfw.git /tmp/glfw
cd /tmp/glfw
git checkout latest
cmake . -DBUILD_SHARED_LIBS=ON
make
sudo make install
sudo ldconfig
rm -rf /tmp/glfw
echo "Done installing glfw3!"

# QtCreator is presently configured to use the V4L2 backend by default
sudo apt-get install qtcreator
sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu trusty universe"
sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu trusty main"
sudo apt-get update
sudo apt-get install qdbus qmlscene qt5-default qt5-qmake qtbase5-dev-tools qtchooser qtdeclarative5-dev xbitmaps xterm libqt5svg5-dev qttools5-dev qtscript5-dev qtdeclarative5-folderlistmodel-plugin qtdeclarative5-controls-plugin -y
echo "Done installing qt5!"

# The library will be installed in /usr/local/lib and header files in /usr/local/include.
cd librealsense/
mkdir build
cd build
cmake ..
make && sudo make install

# Compile the code examples
# The example executables will build into ./examples and install into /usr/local/bin.
cmake .. -DBUILD_EXAMPLES:BOOL=true
make && sudo make install

# Ensure no cameras are presently plugged into the system.
# Install udev rules
sudo cp config/99-realsense-libusb.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && udevadm trigger

LINUX_BRANCH=$(uname -r) 

# Get the required tools and headers to build the kernel
sudo apt-get install libusb-1.0-0-dev
sudo apt-get install linux-headers-generic build-essential 

# Get the linux kernel and change into source tree
[ ! -d ubuntu-xenial ] && git clone git://kernel.ubuntu.com/ubuntu/ubuntu-xenial.git --depth 1
cd ubuntu-xenial

# Apply UVC formats patch for RealSense devices
patch -p1 < ../"$( dirname "$0" )"/realsense-camera-formats_ubuntu16.patch

# Copy configuration
cp /usr/src/linux-headers-$(uname -r)/.config .
cp /usr/src/linux-headers-$(uname -r)/Module.symvers .

# Basic build so we can build just the uvcvideo module
make scripts oldconfig modules_prepare

# Build the uvc modules
KBASE=`pwd`
cd drivers/media/usb/uvc
cp $KBASE/Module.symvers .
make -C $KBASE M=$KBASE/drivers/media/usb/uvc/ modules

# Copy to sane location
sudo cp $KBASE/drivers/media/usb/uvc/uvcvideo.ko ~/$LINUX_BRANCH-uvcvideo.ko

# Unload existing module if installed 
echo "Unloading existing uvcvideo driver..."
sudo modprobe -r uvcvideo

# Delete existing module
sudo rm /lib/modules/`uname -r`/kernel/drivers/media/usb/uvc/uvcvideo.ko

# Copy out to module directory
sudo cp ~/$LINUX_BRANCH-uvcvideo.ko /lib/modules/`uname -r`/kernel/drivers/media/usb/uvc/uvcvideo.ko

# load the new module
sudo modprobe uvcvideo
echo "Script has completed. Please consult the installation guide for further instruction."

# Reload the uvcvideo driver
sudo modprobe uvcvideo

# Check installation by examining the last 50 lines of the dmesg log
sudo dmesg | tail -n 50
