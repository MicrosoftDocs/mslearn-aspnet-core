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
declare genericCommandStyle="${plain}${yellow}"
declare dotnetSayStyle="${magenta}${bold}"
declare headingStyle="${white}${bold}"
declare successStyle="${green}${bold}"
declare warningStyle="${yellow}${bold}"
declare errorStyle="${red}${bold}"
