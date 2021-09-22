echo "请输入您想要操作的序号 ? [ 1:仅flutter打包 2:仅ios打包和发布 3:1+2]"

read number
while([[ $number != 1 ]] && [[ $number != 2 ]] && [[ $number != 3 ]])
do
echo "错误!只能输入1、2、3！！！"
echo "请输入您想要操作的序号 ? [ 1:仅flutter打包 2:仅ios打包和发布 3:1+2]"
read number
done

if [ $number == 1 ]; then
    echo "Build xhome..."
    flutter build ios --release
    exit 1

elif [ $number == 2 ]; then
    sh ./ios/shell.sh
    exit 1

elif [ $number == 3 ]; then
    echo "Build xhome..."
    flutter build ios --release
    sh ./ios/shell.sh
    exit 1
fi
