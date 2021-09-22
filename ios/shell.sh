#使用方法

#当前工程绝对路径
project_path=$(cd `dirname $0`; pwd)

#工程名 将XXX替换成自己的工程名
project_name=Runner

#scheme名 将XXX替换成自己的sheme名
scheme_name=Runner

#打包模式 Debug/Release
development_mode=Debug

#plist文件所在路径
exportOptionsPlistPath=${project_path}/exportTest.plist

#build文件夹路径
build_path=${project_path}/build

#导出.ipa文件所在路径
exportIpaPath=${project_path}/IPADir/${development_mode}


echo "请输入你想要输出的数字? [ 1:app-store 2:ad-hoc] "

##
read number
while([[ $number != 1 ]] && [[ $number != 2 ]])
do
echo "错误!只能输入1或者2！！！"
echo "输入你想要输出的数字? [ 1:app-store 2:ad-hoc] "
read number
done

if [ $number == 1 ];then
development_mode=Release
exportOptionsPlistPath=${project_path}/exportAppstore.plist
exportIpaPath=${project_path}/IPADir/${development_mode}
else
development_mode=Release
exportOptionsPlistPath=${project_path}/exportTest.plist
exportIpaPath=${project_path}/IPADir/${development_mode}
fi


# echo '======* 正在清理工程 *======'
# xcodebuild \
# clean -configuration ${development_mode} -quiet  || exit
# echo ''

rm -r $exportIpaPath

path_info_plist="${project_path}/${project_name}/info.plist"
if [ -e $path_info_plist ]; then
echo "${path_info_plist}"
fi

# 版本完全由flutter控制了
# echo "当前Version：\c"
# /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$path_info_plist"
# echo "当前Build：\c"
# /usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$path_info_plist"
# # 还没想好怎么更好
# echo "请输入bundleVersion："
# read bundleVersion
# /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $bundleVersion" "$path_info_plist"

# echo "请输入bundleBuild："
# read bundleBuild
# /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $bundleBuild" "$path_info_plist"

echo "======* 正在编译工程:${development_mode} *======"
xcodebuild \
archive -workspace ${project_path}/${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${build_path}/${project_name}.xcarchive  -quiet  || exit

echo ''
echo '======* 开始ipa打包 *======'
xcodebuild -exportArchive -archivePath ${build_path}/${project_name}.xcarchive \
-configuration ${development_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-quiet || exit

if [ $number == 1 ];then
echo '======* 构建app并上传appStore成功 *======'
rm -r $build_path
exit 1

elif [ -e $exportIpaPath/$scheme_name.ipa ]; then
echo "======* ipa包已导出:$exportIpaPath/$scheme_name.ipa *======"
open $exportIpaPath
rm -r $build_path

else
echo '======* ipa包导出失败 *======'
exit 1
fi

# if [ $number == 2 ];then
# echo ''
# echo '======* 开始发布内测平台 *======'

# #上传到Fir
# #echo "+++++上传到Fir平台+++++"
# # 将XXX替换成自己的Fir平台的token
# #fir login -T XXX
# #fir publish $exportIpaPath/$scheme_name.ipa


# #上传到蒲公英
# #将XXX替换成自己蒲公英上的User Key
# uKey="XXX"
# #将XXX替换成自己蒲公英上的API Key
# apiKey="XXX"
# #执行上传至蒲公英的命令
# echo "+++++上传到蒲公英平台+++++"
# curl -F "file=@${exportIpaPath}/${scheme_name}.ipa" -F "uKey=${uKey}" -F "_api_key=${apiKey}" http://www.pgyer.com/apiv1/app/upload
# fi

exit 0