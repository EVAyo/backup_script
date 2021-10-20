#!/system/bin/sh
MODDIR="${0%/*}"
tools_path="$MODDIR/tools"
bin_path="$tools_path/bin"
script_path="$tools_path/script"
script="${0##*/}"
[[ $(echo "$MODDIR" | grep -v 'mt') = "" ]] && echo "我他媽骨灰給你揚了撒了TM不解壓縮？用毛線 憨批" && exit 1
[[ ! -d $tools_path ]] && echo "$tools_path目錄遺失" && exit 1
[[ ! -d $script_path ]] && echo "$script_path目錄遺失" && exit 1
[[ ! -d $tools_path/META-INF ]] && echo "$tools_path/META-INF目錄遺失" && exit 1
[[ ! -d $tools_path/apk ]] && echo "$tools_path/apk目錄遺失" && exit 1
. "$bin_path/bin.sh"
. "$MODDIR/backup_settings.conf"
case $MODDIR in
/storage/emulated/0/Android/*|/data/media/0/Android/*|/sdcard/Android/*) echoRgb "請勿在$MODDIR內備份" "0" && exit 2 ;;
esac
case $Compression_method in
zstd|Zstd|ZSTD|tar|Tar|TAR|lz4|Lz4|LZ4) ;;
*) echoRgb "$Compression_method為不支持的壓縮算法" "0" &&  exit 2 ;;
esac
[[ ! -f $MODDIR/backup_settings.conf ]] && echoRgb "backup_settings.conf遺失" "0" && exit 1
if [[ $(pgrep -f "$script" | grep -v grep | wc -l) -ge 2 ]]; then
	echoRgb "檢測到進程殘留，請重新執行腳本 已銷毀進程" "0"
	pgrep -f "$script" | grep -v grep | while read i; do
		[[ $i != "" ]] && kill -9 " $i" >/dev/null
	done
fi
#效驗選填是否正確
isBoolean "$Lo" && Lo="$nsx"
if [[ $Lo = false ]]; then
	isBoolean "$Splist" && Splist="$nsx"
	isBoolean "$Backup_obb_data" && Backup_obb_data="$nsx"
	isBoolean "$path" && path3="$nsx"
	isBoolean "$Backup_user_data" && Backup_user_data="$nsx"
	isBoolean "$backup_media" && backup_media="$nsx"
	isBoolean "$Hybrid_backup" && Hybrid_backup="$nsx"
else
	echoRgb "備份路徑位置為絕對位置或是當前環境位置\n 音量上當前環境位置，音量下腳本絕對位置"
	get_version "當前環境位置" "腳本絕對位置" && path3="$branch"
fi
i=1
#數據目錄
path="/data/media/0/Android"
path2="/data/user/0"
TMPDIR="/data/local/tmp"
[[ ! -d $TMPDIR ]] && mkdir "$TMPDIR"
if [[ $path3 = true ]]; then
	Backup="$PWD/Backup_$Compression_method"
	txt="$PWD/應用列表.txt"
else
	Backup="$MODDIR/Backup_$Compression_method"
	txt="$MODDIR/應用列表.txt"
fi
PU="$(ls /dev/block/vold | grep public)"
[[ ! -f $txt ]] && echoRgb "請執行\"生成應用列表.sh\"獲取應用列表再來備份" "0" && exit 1
r="$(cat "$txt" | grep -v "#" | sed -e '/^$/d' | sed -n '$=')"
[[ $r = "" ]] && echoRgb "爬..應用列表.txt是空的或是包名被注釋了這樣備份個鬼" "0" && exit 1
data=/data
hx="本地"
if [[ $(pm path ice.message) = "" ]]; then
	echoRgb "未安裝toast 開始安裝" "0"
	cp -r "$tools_path/apk"/*.apk "$TMPDIR" && pm install --user 0 -r "$TMPDIR"/*.apk &>/dev/null && rm -rf "$TMPDIR"/* 
	[[ $? = 0 ]] && echoRgb "安裝toast成功" "1" || echoRgb "安裝toast失敗" "0"
fi
echoRgb "-壓縮方式:$Compression_method"
echoRgb "-提示 腳本支持後台壓縮 可以直接離開腳本\n -或是關閉終端也能備份 如需終止腳本\n -請再次執行$script即可停止\n -備份結束將發送toast提示語" "2"
if [[ $PU != "" ]]; then
	[[ -f /proc/mounts ]] && PT="$(cat /proc/mounts | grep "$PU" | awk '{print $2}')"
	if [[ -d $PT ]]; then
		echoRgb "檢測到usb 是否在usb備份\n 音量上是，音量下不是"
		get_version "USB備份" "本地備份"
		if $branch = true ]]; then
			Backup="$PT/Backup_$Compression_method"
			data="/dev/block/vold/$PU"
			hx="USB"
		fi
	fi
else
	echoRgb "沒有檢測到USB於本地備份" "2"
fi
[[ $Backup_user_data = false ]] && echoRgb "當前backup_settings.conf的\n -Backup_user_data為0將不備份user數據" "0"
[[ $Backup_obb_data = false ]] && echoRgb "當前backup_settings.conf的\n -Backup_obb_data為0將不備份外部數據" "0"
[[ $Hybrid_backup = true ]] && echoRgb "當前backup_settings.conf的\n -Hybrid_backup為1將不備份任何應用" "0"
[[ ! -d $Backup ]] && mkdir -p "$Backup"
[[ ! -f $Backup/應用列表.txt ]] && echo "#不需要恢復還原的應用請在開頭注釋# 比如#xxxxxxxx 酷安" >"$Backup/應用列表.txt"
[[ ! -d $Backup/tools ]] && cp -r "$bin_path" "$Backup" && cp -r "$tools_path/apk" "$Backup/bin" && rm -rf "$Backup/bin/toast" "$Backup/bin/zip"
[[ ! -f $Backup/還原備份.sh ]] && cp -r "$script_path/restore" "$Backup/還原備份.sh"
[[ ! -f $Backup/掃描資料夾名.sh ]] && cp -r "$script_path/Get_DirName" "$Backup/掃描資料夾名.sh"
filesize="$(du -ks "$Backup" | awk '{print $1}')"
#調用二進制
Quantity=0
#顯示執行結果
echo_log() {
	if [[ $? = 0 ]]; then
		echoRgb "$1成功" "1" && result=0
	else
		echoRgb "$1失敗，過世了" "0" && result=1 && let ERROR++
	fi
}
#檢測apk狀態進行備份
Backup_apk() {
	#創建APP備份文件夾
	[[ ! -d $Backup_folder ]] && mkdir -p "$Backup_folder"
	[[ $(cat "$Backup/應用列表.txt" | grep -v "#" | sed -e '/^$/d' | awk '{print $2}' | grep -w "^${name}$" | head -1) = "" ]] && echo "$name2 $name" >>"$Backup/應用列表.txt"
	if [[ $apk_version = $(dumpsys package "$name" | awk '/versionName=/{print $1}' | cut -f2 -d '=' | head -1) ]]; then
		unset xb ; result=0
		echoRgb "Apk版本無更新 跳過備份"
	else
		[[ $lxj -ge 95 ]] && echoRgb "$data空間不足,達到$lxj%" "0" && exit 2
		rm -rf "$Backup_folder"/*.apk
		#備份apk
		echoRgb "$1"
		[[ $name != $Open_apps ]] && am force-stop "$name"
		echo "$apk_path" | sed -e '/^$/d' | while read; do
			path="$REPLY"
			b_size="$(ls -l "$path" | awk '{print $5}')"
			k_size="$(awk 'BEGIN{printf "%.2f\n", "'$b_size'"/'1024'}')"
			m_size="$(awk 'BEGIN{printf "%.2f\n", "'$k_size'"/'1024'}')"
			echoRgb "${path##*/} ${m_size}MB(${k_size}KB)" "2"
		done
		(cd "$apk_path2"
		case $Compression_method in
		tar|TAR|Tar) tar -cf "$Backup_folder/apk.tar" *.apk ;;
		lz4|LZ4|Lz4) tar -cf - *.apk | lz4 -1 >"$Backup_folder/apk.tar.lz4" ;;
		zstd|Zstd|ZSTD) tar -cf - *apk | zstd -r -T0 -6 -q >"$Backup_folder/apk.tar.zst" ;;
		esac)
		echo_log "備份$apk_number個Apk"
		if [[ $result = 0 ]]; then
			echo "apk_version=\"$(dumpsys package "$name" | awk '/versionName=/{print $1}' | cut -f2 -d '=' | head -1)\"" >>"$app_details"
			[[ $PackageName = "" ]] && echo "PackageName=\"$name\"" >>"$app_details"
			[[ $ChineseName = "" ]] && echo "ChineseName=\"$name2\"" >>"$app_details"
			[[ ! -f $Backup_folder/還原備份.sh ]] && cp -r "$script_path/restore2" "$Backup_folder/還原備份.sh"
		fi
		if [[ $name = com.android.chrome ]]; then
			#刪除所有舊apk ,保留一個最新apk進行備份
			ReservedNum=1
			FileNum="$(ls /data/app/*/com.google.android.trichromelibrary_*/base.apk 2>/dev/null | wc -l)"
			while [[ $FileNum -gt $ReservedNum ]]; do
				OldFile="$(ls -rt /data/app/*/com.google.android.trichromelibrary_*/base.apk 2>/dev/null | head -1)"
				echoRgb "刪除文件:${OldFile%/*/*}"
				rm -rf "${OldFile%/*/*}"
				let "FileNum--"
			done
			[[ -f $(ls /data/app/*/com.google.android.trichromelibrary_*/base.apk 2>/dev/null) && $(ls /data/app/*/com.google.android.trichromelibrary_*/base.apk 2>/dev/null | wc -l) = 1 ]] && cp -r "$(ls /data/app/*/com.google.android.trichromelibrary_*/base.apk 2>/dev/null)" "$Backup_folder/nmsl.apk"
		fi
	fi
	[[ $name = bin.mt.plus && -f $apk_path && ! -f $Backup/$name2.apk ]] && cp -r "$apk_path" "$Backup/$name2.apk"
	unset ChineseName PackageName ; D=1
}
#檢測數據位置進行備份
Backup_data() {
	unset  zsize
	case $1 in
	user) Size="$userSize" && data_path="$path2/$name" ;;
	data) Size="$dataSize" && data_path="$path/$1/$name" ;;
	obb) Size="$obbSize" && data_path="$path/$1/$name" ;;
	*) [[ -f $app_details ]] && Size="$(cat "$app_details" | awk "/$1Size/"'{print $1}' | cut -f2 -d '=' | tail -n1 | sed 's/\"//g')" ; data_path="$2" ; Compression_method=tar ; zsize=1
	esac
	if [[ -d $data_path ]]; then
		if [[ $Size != $(du -ks "$data_path" | awk '{print $1}') ]]; then
			[[ $lxj -ge 95 ]] && echoRgb "$data空間不足,達到$lxj%" "0" && exit 2
			echoRgb "備份$1數據" "2"
			case $1 in
			user)
				case $Compression_method in
				tar|Tar|TAR) tar --exclude="${data_path##*/}/.ota" --exclude="${data_path##*/}/cache" --exclude="${data_path##*/}/lib" -cpf - -C "${data_path%/*}" "${data_path##*/}" 2>/dev/null | pv >"$Backup_folder/$1.tar" ;;
				zstd|Zstd|ZSTD) tar --exclude="${data_path##*/}/.ota" --exclude="${data_path##*/}/cache" --exclude="${data_path##*/}/lib" -cpf - -C "${data_path%/*}" "${data_path##*/}" 2>/dev/null | pv | zstd -r -T0 -6 -q >"$Backup_folder/$1.tar.zst" ;;
				lz4|Lz4|LZ4) tar --exclude="${data_path##*/}/.ota" --exclude="${data_path##*/}/cache" --exclude="${data_path##*/}/lib" -cpf - -C "${data_path%/*}" "${data_path##*/}" 2>/dev/null | pv | lz4 -1 >"$Backup_folder/$1.tar.lz4" ;;
				esac ;;
			*)
				case $Compression_method in
				tar|Tar|TAR) tar --exclude="Backup_"* -cPpf - "$data_path" 2>/dev/null | pv >"$Backup_folder/$1.tar" ;;
				zstd|Zstd|ZSTD) tar --exclude="Backup_"* -cPpf - "$data_path" 2>/dev/null | pv | zstd -r -T0 -6 -q >"$Backup_folder/$1.tar.zst" ;;
				lz4|Lz4|LZ4) tar --exclude="Backup_"* -cPpf - "$data_path" 2>/dev/null | pv | lz4 -1 >"$Backup_folder/$1.tar.lz4" ;;
				esac ;;
			esac
			echo_log "備份$1數據"
			if [[ $result = 0 ]]; then
				if [[ $zsize != "" ]]; then
					echo "#$1Size=\"$(du -ks "$data_path" | awk '{print $1}')\"" >>"$app_details"
				else
					echo "$1Size=\"$(du -ks "$data_path" | awk '{print $1}')\"" >>"$app_details"
				fi
			fi
		else
			echoRgb "$1數據無發生變化 跳過備份"
		fi
	else
		echoRgb "$1數據不存在跳過備份"
	fi
}
recovery_backup() {
	echo "$name2 $name $apk_path2" >>"$script_path/應用列表.txt"
	if [[ $i = $r ]]; then
		if [[ -f $tools_path/META-INF/com/google/android/update-binary ]]; then
			echoRgb "輸出用於recovery的備份卡刷包" ; rm -rf "$MODDIR/recovery卡刷備份.zip" ; mkdir -p "$MODDIR/tmp"
			tar -cpf - -C "$tools_path" "META-INF" "script" "bin" "apk" | tar --delete "script/restore3" --delete "bin/busybox_path" --delete "bin/lz4" --delete "bin/zip" | pv | tar --recursive-unlink -xmpf - -C "$MODDIR/tmp"
			(cd "$MODDIR/tmp" && zip -r "recovery卡刷備份.zip" *)
			echo_log "打包卡刷包"
			[[ $result = 0 ]] && (mv "$MODDIR/tmp/recovery卡刷備份.zip" "$MODDIR" && rm -rf "$MODDIR/tmp" "$script_path/應用列表.txt" ; echoRgb "輸出:$MODDIR/recovery卡刷備份.zip" "2")
		else
			echoRgb "update-binary卡刷腳本遺失" "0"
		fi
	fi
}
[[ $Lo = true ]] && {
echoRgb "選擇是否只備份split apk(分割apk檔)\n 如果你不知道這意味什麼請選擇音量下進行混合備份\n 音量上是，音量下不是"
get_version "是" "不是，混合備份" && Splist="$branch"
echoRgb "是否備份外部數據 即比如原神的數據包\n 音量上備份，音量下不備份"
get_version "備份" "不備份" && Backup_obb_data="$branch"
echoRgb "是否備份使用者數據\n 音量上備份，音量下不備份"
get_version "備份" "不備份" && Backup_user_data="$branch"
echoRgb "全部應用備份結束後是否備份自定義目錄\n 音量上備份，音量下不備份"
get_version "備份" "不備份" && backup_media="$branch"
echoRgb "單獨生成可供recovery中救急備份的卡刷包？\n 音量上生成，音量下備份應用+生成(混合)"
get_version "單獨生成" "備份應用+卡刷包" && Hybrid_backup="$branch"
}
echo "#不需要恢復還原的應用請在開頭注釋# 比如#xxxxxxxx 酷安" >"$script_path/應用列表.txt"
#開始循環$txt內的資料進行備份
#記錄開始時間
starttime1="$(date -u "+%s")"
TIME="$starttime1"
#記錄error次數起點
ERROR=1
{
while [[ $i -le $r ]]; do
	name="$(cat "$txt" | grep -v "#" | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $2}')"
	name2="$(cat "$txt" | grep -v "#" | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $1}')"
	[[ $name = "" ]] && echoRgb "警告! 應用列表.txt應用包名獲取失敗，可能修改有問題" "0" && exit 1
	apk_path="$(pm path "$name" | cut -f2 -d ':')"
	apk_path2="$(echo "$apk_path" | head -1)" ; apk_path2="${apk_path2%/*}"
	if [[ -d $apk_path2 ]]; then
		if [[ $Hybrid_backup = false ]]; then
			echoRgb "備份第$i個應用 總共$r個 剩下$((r-i))個應用"
			if [[ $name2 = *! || $name2 = *！ ]]; then
				name2="$(echo "$name2" | sed 's/!//g ; s/！//g')"
				echoRgb "跳過備份$name2 所有數據" "0"
				No_backupdata=1
			else
				[[ $No_backupdata != "" ]] && unset No_backupdata
			fi
			Backup_folder="$Backup/${name2}[${name}]"
			app_details="$Backup_folder/app_details"
			[[ -f $app_details ]] && . "$app_details"
			lxj="$(df -h "$data" | awk 'END{print $4}' | sed 's/%//g')"
			starttime2="$(date -u "+%s")"
			echoRgb "備份$name2 ($name)"
			[[ $name = com.tencent.mobileqq ]] && echo "QQ可能恢復備份失敗或是丟失聊天記錄，請自行用你信賴的應用備份"
			[[ $name = com.tencent.mm ]] && echo "WX可能恢復備份失敗或是丟失聊天記錄，請自行用你信賴的應用備份"
			apk_number="$(echo "$apk_path" | wc -l)"
			if [[ $apk_number = 1 ]]; then
				if [[ $Splist = false ]]; then
					Backup_apk "非Split Apk"
				else
					echoRgb "非Split Apk跳過備份" && unset D
				fi
			else
				Backup_apk "Split Apk支持備份"
			fi
			if [[ $D != ""  && $result = 0 && $No_backupdata = "" ]]; then
				if [[ $Backup_obb_data = true ]]; then
					#備份data數據
					Backup_data "data"
					#備份obb數據
					Backup_data "obb"
				fi
				#備份user數據
				[[ $Backup_user_data = true ]] && Backup_data "user"
			fi
			endtime 2 "$name2備份"
			echoRgb "完成$((i*100/r))% $hx$(df -h "$data" | awk 'END{print "剩餘:"$3"使用率:"$4}')"
			echoRgb
			recovery_backup
		else
			recovery_backup
		fi
	else
		echoRgb "$name2[$name]不在安裝列表，備份個寂寞？" "0"
	fi
	if [[ $i = $r ]]; then
		endtime 1 "應用備份"
		if [[ $backup_media = true && $Hybrid_backup = false ]]; then
			echoRgb "備份結束，備份多媒體"
			starttime1="$(date -u "+%s")"
			Backup_folder="$Backup/媒體"
			A=1
			B="$(echo "$Custom_path" | grep -v "#" | sed -e '/^$/d' | sed -n '$=')"
			[[ ! -d $Backup_folder ]] && mkdir -p "$Backup_folder"
			[[ ! -f $Backup_folder/恢復多媒體數據.sh ]] && cp -r "$script_path/restore3" "$Backup_folder/恢復多媒體數據.sh"
			app_details="$Backup_folder/app_details"
			[[ -f $app_details ]] && . "$app_details"
			echo "$Custom_path" | grep -v "#" | sed -e '/^$/d' | while read; do
				echoRgb "備份第$A個資料夾 總共$B個 剩下$((B-A))個"
				Backup_data "${REPLY##*/}" "$REPLY"
				echoRgb "完成$((A*100/B))% $hx$(df -h "$data" | awk 'END{print "剩餘:"$3"使用率:"$4}')" && let A++
			done
			endtime 1 "自定義備份"
		fi
	fi
	[[ $ERROR -ge 5 ]] && echoRgb "錯誤次數達到上限 環境已重設\n -請重新執行腳本" "0" && rm -rf "$filepath" && exit 2
	let i++
done

echoRgb "你要備份跑路？祝你卡米9008" "2"
#計算出備份大小跟差異性
filesizee="$(du -ks "$Backup" | awk '{print $1}')"
dsize="$(($((filesizee - filesize)) / 1024))"
echoRgb "備份資料夾路徑:$Backup" "2"
echoRgb "備份資料夾總體大小$(du -ksh "$Backup" | awk '{print $1}')"
if [[ $dsize -gt 0 ]]; then
	if [[ $((dsize / 1024)) -gt 0 ]]; then
		echoRgb "本次備份: $((dsize / 1024))gb"
	else
		echoRgb "本次備份: ${dsize}mb"
	fi
else
	echoRgb "本次備份: $(($((filesizee - filesize)) * 1000 / 1024))kb"
fi
echoRgb "批量備份完成"
starttime1="$TIME"
endtime 1 "批量備份開始到結束"
exit 0
}&
wait
longToast "批量備份完成"
Print "批量備份完成 執行過程請查看$Status_log"