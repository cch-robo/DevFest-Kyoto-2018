#!/bin/sh

export ABI_TYPE=android-arm

flutter clean
flutter build apk --release --target-platform=android-arm

if [ $? -eq 0 ]; then
    echo "build success!"
    echo "32bit ビルド APK は、build/app/outputs/apk に出力済"
else
    echo "build error occur!"
fi
