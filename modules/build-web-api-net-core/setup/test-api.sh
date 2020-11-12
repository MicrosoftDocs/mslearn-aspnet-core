# Text formatting
declare red=`tput setaf 1`
declare green=`tput setaf 2`
declare yellow=`tput setaf 3`
declare blue=`tput setaf 4`
declare magenta=`tput setaf 5`
declare cyan=`tput setaf 6`
declare white=`tput setaf 7`
declare defaultColor=`tput setaf 9`
declare bold=`tput bold`
declare plain=`tput sgr0`
declare newline=$'\n'

# Element styling
declare azCliCommandStyle="${plain}${cyan}"
declare defaultTextStyle="${plain}${white}"
declare dotnetCliCommandStyle="${plain}${magenta}"
declare dotnetSayStyle="${magenta}${bold}"
declare headingStyle="${white}${bold}"
declare successStyle="${green}${bold}"
declare warningStyle="${yellow}${bold}"
declare errorStyle="${red}${bold}"

echo
echo
echo "${headingStyle}eShopOnContainers API Test${defaultTextStyle}"
echo

# Invalid POST
curlCmd="curl -i -k -H \"Content-Type: application/json\" -d \"\{\\\"name\\\":\\\"PlushSquirrel\\\",\\\"price\\\":0.00\}\" https://localhost:5001/products"

echo "Testing ${red}invalid ${headingStyle}POST${defaultTextStyle}..."
echo
echo "> ${yellow}$curlCmd${defaultTextStyle}"
echo
eval $curlCmd
echo

# Valid POST
curlCmd="curl -i -k -H \"Content-Type: application/json\" -d \"\{\\\"name\\\":\\\"PlushSquirrel\\\",\\\"price\\\":12.99\}\" https://localhost:5001/products"

echo "Testing ${green}valid ${headingStyle}POST${defaultTextStyle}..."
echo
echo "> ${yellow}$curlCmd${defaultTextStyle}"
echo
eval $curlCmd
echo

# GET
curlCmd="curl -k -s https://localhost:5001/products/3 | jq"

echo "Testing ${headingStyle}GET${defaultTextStyle}..."
echo
echo "> ${yellow}$curlCmd${defaultTextStyle}"
echo
eval $curlCmd
echo

# PUT
curlCmd="curl -i -k -X PUT -H \"Content-Type: application/json\" -d \"\{\\\"id\\\":2,\\\"name\\\":\\\"Knotted Rope\\\",\\\"price\\\":14.99\}\" https://localhost:5001/products/2"

echo "Testing ${headingStyle}PUT${defaultTextStyle}..."
echo
echo "> ${yellow}$curlCmd${defaultTextStyle}"
echo
eval $curlCmd
echo

# DELETE
curlCmd="curl -i -k -X DELETE https://localhost:5001/products/1"

echo "Testing ${headingStyle}DELETE${defaultTextStyle}..."
echo
echo "> ${yellow}$curlCmd${defaultTextStyle}"
echo
eval $curlCmd
echo

# Verification
curlCmd="curl -k -s https://localhost:5001/products | jq"

echo "Testing ${headingStyle}GET${defaultTextStyle}..."
echo
echo "> ${yellow}$curlCmd${defaultTextStyle}"
echo
eval $curlCmd
echo

echo "${successStyle}Done!${defaultTextStyle}"
echo

