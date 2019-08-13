# Downloads and installs sqlite3 command-line shell in the Cloud Shell

# Depends on binariesPath variable
if [[ ! $binariesPath ]]; then
    echo "${newline}${errorStyle}\$binariesPath is not set.${newline}${defaultTextStyle}"
    return 0;
fi

declare sqliteDirectory=~/.sqlite3
declare sqliteUrl=$binariesPath/sqlite3

# Bug out if it's already installed
if [ -d "${sqliteDirectory}" ]; then
    if [ -f "${sqliteDirectory}/sqlite3" ]; then
        echo "${warningStyle}SQLite3 command-line shell already installed.${newline}${defaultTextStyle}"
        return 1;
    fi
fi

# Download and install the binary
echo "${newline}${headingStyle}Installing SQLite3 command-line shell...${newline}${defaultTextStyle}"
mkdir $sqliteDirectory
wget -q -O $sqliteDirectory/sqlite3 $sqliteUrl
chmod +x $sqliteDirectory/sqlite3

# Resource file (default values)
if ! [ -f "~/.sqliterc" ]; then
    echo ".mode columns" > ~/.sqliterc
    echo ".headers on" >> ~/.sqliterc
    echo ".nullvalue NULL" >> ~/.sqliterc
fi

# Add the path
if ! [ $(echo $PATH | grep $sqliteDirectory) ]; then 
    export PATH=$PATH:$sqliteDirectory
    echo "# SQLite 3 CLI tool path" >> ~/.bashrc
    echo "export PATH=\$PATH:$sqliteDirectory" >> ~/.bashrc
fi
echo