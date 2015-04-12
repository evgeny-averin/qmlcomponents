QTDIR=$1
PWD=$2

$QTDIR/bin/rcc --binary $PWD/resource/main.qrc > /sdcard/Develop/main.rcc
touch /sdcard/Develop/flag/resource.lck

/home/eaverin/opt/android-sdk-linux/platform-tools/adb push /sdcard/Develop/main.rcc /sdcard/Develop/
/home/eaverin/opt/android-sdk-linux/platform-tools/adb push /sdcard/Develop/flag/resource.lck /sdcard/Develop/flag/
