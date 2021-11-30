echo "请输入您想要操作的序号 ? [ 1:apk 2:aab 3:dev]"

read number
while([[ $number != 1 ]] && [[ $number != 2 ]] && [[ $number != 3 ]])
do
echo "错误!只能输入1、2、3！！！"
echo "请输入您想要操作的序号 ? [ 1:apk 2:aab 3:dev]"
read number
done

echo "请输入版本名:"
read version
echo "请输入版本号:"
read buildNumber

project_path=$(cd `dirname $0`; pwd)

if [ $number == 1 ]; then
    echo "flutter build apk --release"
    flutter build apk --release

    apkPath=${project_path}/build/app/outputs/flutter-apk/
    apkName=polkawallet-v${version}-beta.${buildNumber:0-1}.apk
    mv ${apkPath}app-release.apk ~/Downloads/${apkName}

elif [ $number == 2 ]; then
    echo "flutter build appbundle --release -t lib/main-google.dart"
    flutter build appbundle --release -t lib/main-google.dart

    apkPath=${project_path}/build/app/outputs/bundle/release/
    apkName=polkawallet-v${version}-beta.${buildNumber:0-1}.aab
    mv ${apkPath}app-release.aab ~/Downloads/${apkName}

elif [ $number == 3 ]; then
    echo "flutter build apk --release -t lib/main-dev.dart"
    flutter build apk --release -t lib/main-dev.dart

    apkPath=${project_path}/build/app/outputs/flutter-apk/
    apkName=polkawallet-v${version}-dev.${buildNumber:0-1}.apk
    mv ${apkPath}app-release.apk ~/Downloads/${apkName}
fi

#scp ${apkPath}${apkName} root@47.244.26.104:/data/www/polkawallet
exit 1