adduser -s bash bitwardenrs
echo "bitwardenrs ALL=(ALL) ALL" > /usr/local/etc/sudoers

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

git clone https://github.com/dani-garcia/bitwarden_rs/
cd bitwarden_rs/
git checkout "$(git tag --sort=v:refname | tail -n1)"

# Build with sqlite backend
cargo build --features sqlite --release
cargo install diesel_cli --no-default-features --features sqlite-bundled
cd ..

# clone the repository
git clone --recurse-submodules https://github.com/bitwarden/web.git web-vault
cd web-vault
export WEB_VERSION="$(git tag --sort=v:refname | tail -n1)"
git checkout ${WEB_VERSION}

curl https://raw.githubusercontent.com/dani-garcia/bw_web_builds/master/patches/${WEB_VERSION}.patch >${WEB_VERSION}.patch
git apply ${WEB_VERSION}.patch -v

npm install
# Read the note below (we do use this for our docker builds).
# npm audit fix
npm run dist

cd
# copy bitwarden_rs dist
cp -r ~/bitwarden_rs/target/release bitwarden_rs_dist
cd bitwarden_rs_dist
# and copy the web-vault files
cp -r ../web-vault/build web-vault

sudo sysrc bitwardenrs_enable="YES"
sudo chmod +x /usr/local/etc/rc.