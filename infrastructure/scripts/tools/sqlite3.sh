# Downloads and installs sqlite3 CLI in the Cloud Shell
# Depends on gitBranch variable

declare sqlitePath=~/.sqlite3
declare sqliteUrl=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/binaries/sqlite3
echo "${newline}${headingStyle}Installing SQLite3 CLI tool...${newline}${defaultTextStyle}"
# Bug out if it's already installed
if [ -d "${sqlitePath}" ]; then
    if [ -f "${sqlitePath}/sqlite3" ]; then
        echo "${warningStyle}SQLite3 CLI tool already installed."
        return 1;
    fi
fi

# Download and install the binary
mkdir $sqlitePath;
wget -q -O $sqlitePath/sqlite3 $sqliteUrl
chmod +x $sqlitePath/sqlite3

# Add the path
if ! [ $(echo $PATH | grep $sqlitePath) ]; then 
    export PATH=$PATH:$sqlitePath
    echo "# SQLite 3 CLI tool path" >> ~/.bashrc
    echo "export PATH=\$PATH:$sqlitePath" >> ~/.bashrc
fi
echo