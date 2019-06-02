#!/bin/sh

export ABI_TYPE=android-arm64

flutter clean
flutter build apk --release --target-platform=android-arm64

if [ $? -eq 0 ]; then
    echo "build success!"
    echo "64bit ビルド APK は、build/app/outputs/apk に出力済"
else
    echo "build error occur!"
fi
