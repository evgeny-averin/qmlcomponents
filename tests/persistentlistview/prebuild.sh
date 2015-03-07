QTDIR=$1
PWD=$2

$QTDIR/bin/rcc --binary $PWD/resource/main.qrc > /sdcard/Develop/main.rcc
touch /sdcard/Develop/flag/resource.lck

$ANDROID_SDK_ROOT/platform-tools/adb push /sdcard/Develop/main.rcc /sdcard/Develop/
$ANDROID_SDK_ROOT/platform-tools/adb push /sdcard/Develop/flag/resource.lck /sdcard/Develop/flag/
