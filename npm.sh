
namespace="@minecraft"
base_url="https://registry.npmjs.org/$namespace"

modules=(
	"server" 
	"server-ui" 
	"server-gametest" 
)

# "1.9.0"
re_stable="[0-9]+(.[0-9]+){2}\$"
# "1.10.0-beta.1.20.70-stable"
re_stable_exp=".+beta.+stable\$"
# "1.10.0-rc.1.20.80-preview.23"
re_preview=".+rc.+preview.+"
# "1.11.0-beta.1.20.80-preview.23"
re_preview_exp=".+beta.+preview.+"

readme=""
json="{"

for module in "${modules[@]}"; do
	echo Getting $module
	
	url_content=$(curl \
		-sH "Accept: application/vnd.npm.install-v1+json" \
		"$base_url/$module")
	
	modified=$(jq -r <<< $url_content '.modified')
	
	vers=$(jq <<< $url_content ".versions")
	keys=$(jq <<< $vers "keys_unsorted") 

	filter_last_key () {
		echo $(jq -r <<< $keys "map(select(test(\"$1\"))) | last")
	}
	
	get () {
		key="$1"
		
		if [ "$key" == "null" ]; then
			echo "null"
			return
		fi
		
		data=$( jq <<< $vers ".[\"$key\"] | .dist.tarball" )
		v="\"$key\""
		
		echo "{
			\"version\": $v,
			\"npm\": \"npm i @minecraft/$module@$key\",
			\"download\": $data
		}"
	}
	
	s=$( filter_last_key $re_stable )
	se=$( filter_last_key $re_stable_exp )
	p=$( filter_last_key $re_preview )
	pe=$( filter_last_key $re_preview_exp )

	sv=$( get $s )
	sev=$( get $se )
	pv=$( get $p )
	pev=$( get $pe )

	readme="$readme \
# $module \
### stable \
- $s \
### stable exp \
- $se \
### preview \
- $p \
### preview exp \
- $pe \

"
	
	json="$json
\"$module\": {
	\"modified\": $(date -d $modified +%s),
	\"versions\": {
		\"stable\": $sv,
		\"stable_exp\": $sev,
		\"preview\": $pv,
		\"preview_exp\": $pev
	}
},"
	
done

json="$json
\"last_fetch\": $(date +%s)
}"


echo $(jq <<< "$json") > data.json
echo $readme > README.md

