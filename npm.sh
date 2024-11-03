namespace="@minecraft"
base_url="https://registry.npmjs.org/$namespace"

modules=(
    "server" 
    "server-ui" 
    "server-gametest" 
)

# Regex patterns
re_stable="[0-9]+(.[0-9]+){2}\$"
re_stable_exp=".+beta.+stable\$"
re_preview=".+rc.+preview.+"
re_preview_exp=".+beta.+preview.+"

# Prepare readme and json output
readme="[![Daily NPM Script](https://github.com/WavePlayz/minecraft-npms-auto/actions/workflows/fetch.yml/badge.svg)](https://github.com/WavePlayz/minecraft-npms-auto/actions/workflows/fetch.yml)"
json="{"
npms_output=""

# Create or empty the npms.txt file
echo "" > npms.txt

for module in "${modules[@]}"; do
    echo "Getting $module"
    
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
    
    s=$(filter_last_key $re_stable)
    se=$(filter_last_key $re_stable_exp)
    p=$(filter_last_key $re_preview)
    pe=$(filter_last_key $re_preview_exp)

    # Get the npm strings for output
    npm_stable="npm i @minecraft/$module@$s"
    npm_stable_exp="npm i @minecraft/$module@$se"
    npm_preview="npm i @minecraft/$module@$p"
    npm_preview_exp="npm i @minecraft/$module@$pe"

    # Append to the npms output variable
    npms_output+="$module $s $se $p $pe\n"

    readme="$readme
# $module
<details>

stable
\`\`\`
$s
\`\`\`

stable exp
\`\`\`
$se
\`\`\`

preview
\`\`\`
$p
\`\`\`

preview exp
\`\`\`
$pe
\`\`\`
</details>
"

    json="$json
\"$module\": {
    \"modified\": $(date -d $modified +%s),
    \"versions\": {
        \"stable\": $(get $s),
        \"stable_exp\": $(get $se),
        \"preview\": $(get $p),
        \"preview_exp\": $(get $pe)
    }
},"
    
done

json="$json
\"last_fetch\": $(date +%s)
}"

# Write to data.json and npms.txt
echo "$(jq <<< "$json")" > data.json
echo -e "$npms_output" > npms.txt
echo "$readme" > README.md
