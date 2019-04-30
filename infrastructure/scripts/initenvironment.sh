    # Set location
    cd ~

    # Display installed .NET Core SDK version
    echo "${heading}Using .NET Core SDK version $dotnetsdkversion${white}${plain}"

    # Install .NET Core global tool to display connection info
    dotnet tool install dotnetsay --global

    # Greetings!
    greeting="${newline}${white}${bold}Hi there!${plain}${newline}"
    greeting+="I'm going to provision some ${cyan}${bold}Azure${white}${plain} resources${newline}"
    greeting+="and get the code you'll need for this module.${magenta}${bold}"

    dotnetsay "$greeting"