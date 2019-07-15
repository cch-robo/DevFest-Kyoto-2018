#!/bin/sh

flutter clean
flutter build appbundle --release

if [ $? -eq 0 ]; then
    echo "build success!"
    echo "AAB は、build/app/outputs/bundle に出力済"
else
    echo "build error occur!"
fi
