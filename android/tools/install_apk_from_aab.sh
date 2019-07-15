#!/bin/sh

rm -rf build/app/outputs/apks
mkdir build/app/outputs/apks
mkdir build/app/outputs/apks/release

java -jar android/tools/bundletool-all-0.10.0.jar \
build-apks \
--bundle=build/app/outputs/bundle/release/app.aab \
--output=build/app/outputs/apks/release/app.apks \
--ks=android/app/キーストア.jks \
--ks-pass=pass:ストアパスワード \
--ks-key-alias=キーエイリアスパスワード \
--key-pass=pass:キーパスワード

java -jar android/tools/bundletool-all-0.10.0.jar \
install-apks \
--apks=build/app/outputs/apks/release/app.apks

if [ $? -eq 0 ]; then
    echo "install success!"
    echo "apks は、build/app/outputs/apks に出力済"
else
    echo "build error occur!"
fi
