
#!/bin/sh

# Check the operating system type
if [ "$(uname)" = "Linux" ]; then
    echo "Linux"
      # apt 更新
    # sudo apt update
    # echo "apt 更新完成"

    # 中文环境
    sudo apt install language-pack-zh-hans
    sudo update-locale LANG=en_US.UTF-8 LC_ALL=zh_CN.UTF-8
    echo "中文环境安装完成"

    # 换源
    curl -L https://gitee.com/RubyMetric/chsrc/releases/download/pre/chsrc-x64-linux -o chsrc; chmod +x ./chsrc
    sudo ./chsrc set ubuntu
    echo "换源完成"

    # 安装 curl
    sudo apt install -y curl
    echo "安装 curl 完成"

    # 安装 wget
    sudo apt install -y wget
    echo "安装 wget 完成"

    # 安装 htop
    sudo apt install -y htop
    echo "安装 htop 完成"

    # 安装 git
    sudo apt install -y git
    echo "安装 git 完成"

    # 安装 vim
    sudo apt install -y vim
    echo "安装 vim 完成"

    # neofetch
    sudo apt install -y neofetch
    echo "安装 neofetch 完成"

    # 安装 node
    sudo apt install -y npm
    sudo ./chsrc set npm
    sudo npm install -g n live-server pm2 nodemon
    echo "安装 node 完成"

    # 安装 zsh
    sudo apt install -y zsh
    echo "安装 zsh 完成"

    # 安装 starship
    curl -sS https://starship.rs/install.sh | sh
    echo "安装 starship 完成"

    # # 安装 docker
    # # Add Docker's official GPG key:
    # sudo apt-get install ca-certificates curl gnupg
    # sudo install -m 0755 -d /etc/apt/keyrings
    # curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    # sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # # Add the repository to Apt sources:
    # echo \
    # "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    # $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    # sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    # sudo apt-get update
    # sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
elif [ "$(uname)" = "Darwin" ]; then
    echo "macOS"

    # 安装 brew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "安装 brew 完成"

    # 安装 curl
    brew install curl
    echo "安装 curl 完成"

    # 安装 wget
    brew install wget
    echo "安装 wget 完成"

    # 安装 git
    brew install git
    echo "安装 git 完成"

    # htop
    brew install htop
    echo "安装 htop 完成"

    # 安装 node
    brew install node
    echo "安装 node 完成"

    # 安装 zsh
    brew install zsh
    echo "安装 zsh 完成"

    # 安装 starship
    curl -sS https://starship.rs/install.sh | sh
    echo "安装 starship 完成"

    # neofetch
    brew install neofetch
    echo "安装 neofetch 完成"

else
    echo "Unknown operating system"
fi

# 公共操作
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "安装 oh-my-zsh 完成"

# zsh 插件
# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
echo "安装 zsh-autosuggestions 完成"
# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
echo "安装 zsh-syntax-highlighting 完成"
# 导入配置
cp zshrc ~/.zshrc
echo "导入 zsh 配置完成"
mkdir ~/.config && cp starship.toml ~/.config/starship.toml && zsh
echo "导入 starship 配置完成"

# node
sudo npm install -g vtop live-server