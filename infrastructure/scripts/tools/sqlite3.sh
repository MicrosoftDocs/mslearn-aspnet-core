(
    declare sqlitePath=~/.sqllite3
    declare sqliteUrl=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/binaries/sqlite3
    echo "${newline}${headingStyle}Installing SQLite3 CLI tool...${newline}${defaultTextStyle}"
    if [ -d "${sqlitePath}" ]; then
        if [ -f "${sqlitePath}/sqlite3" ]; then
            echo "${warningStyle}SQLite3 CLI tool already installed."
            return 1;
        fi
    fi
    mkdir $sqlitePath;
    wget -O $sqlitePath/sqlite3 $sqliteUrl
    if ! [ $(echo $PATH | grep $sqlitePath) ]; then 
        export PATH=$PATH:$sqlitePath
        echo "# SQLite 3 CLI tool path" >> ~/.bashrc
        echo "export PATH=\$PATH:$sqlitePath" >> ~/.bashrc
    fi
)
echo