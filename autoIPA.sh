#!/bin/sh

# 程序中使用AppConfig.plist文件保存所有渠道号及当前渠道号

####获取当前shell文件所在目录
base_dir=$(cd "$(dirname "$0")"; pwd)
echo "base_dir: $base_dir"
cd $base_dir #切换到base_dir目录

####解压IPA文件-->Payload目录
sourceIPAName=$1                #sh脚本第一个参数: 如"嘀嘀打车.ipa"
echo "${sourceIPAName}"
tempIPAName="tmp.ipa"           #临时ipa文件
#ipa文件不存在则退出执行
if [[ -z "$sourceIPAName" ]] || [[ ! -f "$sourceIPAName" ]];
then
    echo "autoIPA Error: The IPA file is not exist!"
    exit #退出当前shell执行
else
    #复制源ipa文件到当前工作目录
    cp -f "${sourceIPAName}" "${tempIPAName}"
    unzip "${tempIPAName}"
fi

####创建distDir目录
distDir="$(dirname ${sourceIPAName})""/autoIPA_distDir"               #打包后ipa文件存储目录(相对路径)
echo $distDir
rm -rdf "${distDir}"
mkdir "${distDir}"

####PlistBuddy命令
PLISTBUDDY="/usr/libexec/PlistBuddy"

########################################################################
##### 在Payload目录中递归搜索AppConfig.plist文件，并将搜索到文件完整路径赋值给plistfile变量
plistfile=$(find "Payload" -name "AppConfig.plist" -print)
echo "plistfile: ${plistfile}"

####搜索并获取info.plist文件完整路径
infoPlist=$(find "Payload" -name "Info.plist" -print)
echo "infoPlist: ${infoPlist}"
########################################################################

#appId:程序唯一编号bundleId
appid=`${PLISTBUDDY} -c "Print :CFBundleIdentifier" "${infoPlist}"`
echo "appid: ${appid}"

####程序包名bundleName
bundleName=`${PLISTBUDDY} -c "Print :CFBundleName" "${infoPlist}"`
echo "bundleName: ${bundleName}"

#获取version版本号
version=`${PLISTBUDDY} -c "Print :CFBundleVersion" "${infoPlist}"`
echo "version: ${version}"

#获取version(短)版本号
versionShort=`${PLISTBUDDY} -c "Print :CFBundleShortVersionString" "${infoPlist}"`
echo "versionShort: ${versionShort}"

#获取displayName显示名
displayName=`${PLISTBUDDY} -c "Print :CFBundleDisplayName" "${infoPlist}"`
echo "displayName: ${displayName}"

#### allChannel数组长度(数组中元素为Dict)
settingsCnt=`${PLISTBUDDY} -c "Print allChannel:" ${plistfile} | grep "Dict"|wc -l`
#echo "$settingsCnt"

#### 循环遍历allChannel数据
ipaNameString=""
for((i=0;i<$settingsCnt;i++));
do
    #echo $i;
    ChannelNo=`${PLISTBUDDY} -c "Print allChannel:$i:ChannelNo string" ${plistfile}`
    ChannelNo_APPCPA=`${PLISTBUDDY} -c "Print allChannel:$i:ChannelNo_APPCPA string" ${plistfile}`
    ChanneName=`${PLISTBUDDY} -c "Print allChannel:$i:ChanneName string" ${plistfile}`
    echo "ChannelNo: $ChannelNo";
    echo "ChannelNo_APPCPA: $ChannelNo_APPCPA" ;
    echo "ChanneName: $ChanneName" ;

    ####修改AppConfig.plist中当前渠道号
    ${PLISTBUDDY} -c "Set :ChannelNo ${ChannelNo}" ${plistfile}
    ${PLISTBUDDY} -c "Set :ChannelNo_APPCPA ${ChannelNo_APPCPA}" ${plistfile}

    ####压缩Payload目录得到ipa文件并存放到distDir中
    ipaName="${bundleName}_${versionShort}_${ChannelNo}_${ChanneName}.ipa"
    #echo $ipaName; #输出文件名
    zip -r ${ipaName} Payload
    mv ${ipaName} ${distDir}
    echo "created IPA: $ipaName";

    ipaNameString="${ipaNameString}""${ipaName}""\n"
done

####清理Payload目录和tempIPA文件
rm -rdf Payload
rm -rdf "${tempIPAName}"

####打开结果目录
open "${distDir}"
#`osascript -e 'tell app "System Events" to (display dialog "恭喜您，IPA已经全部生成完成。\n存放路径: '${distDir}' " with title "自动打包已完成" buttons {"ok"})'`

#shell中调用applescript代码
exec osascript <<EOF
tell application "System Events"
display dialog "本次IPA存放路径:\n${distDir}  \n\nIPA文件清单:\n${ipaNameString}" with title "自动打包已完成" buttons {"ok"}
end tell
EOF





