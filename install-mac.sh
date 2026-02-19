#!/usr/bin/env bash
# =============================================================
# macOS Development Tools Installer (Latest Versions)
# =============================================================
# รายการโปรแกรมที่ติดตั้ง:
#   - Homebrew             (package manager)
#   - Git                  (latest) → brew
#   - PHP 8.x              (latest stable) → brew
#   - Composer             (latest) → installer
#   - Laravel Installer    (latest) → composer global
#   - Node.js LTS          (latest) → nvm
#   - Bun                  (latest) → brew
#   - Docker Desktop       (latest) → brew --cask
#   - DBeaver Community    (latest) → brew --cask
#   - Antigravity          (latest) → npm install -g
# =============================================================
# วิธีใช้งาน:
#   chmod +x install-mac.sh
#   ./install-mac.sh
# =============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; GRAY='\033[0;37m'; NC='\033[0m'

header()  { echo -e "\n${CYAN}============================================================${NC}"; echo -e "${CYAN} $1${NC}"; echo -e "${CYAN}============================================================${NC}"; }
step()    { echo -e "${YELLOW}[*] $1${NC}"; }
success() { echo -e "${GREEN}[✓] $1${NC}"; }
fail()    { echo -e "${RED}[✗] $1${NC}"; }
info()    { echo -e "${GRAY}    $1${NC}"; }

# ============================================================
# 0. Homebrew
# ============================================================
header "0. ติดตั้ง Homebrew"
if command -v brew &>/dev/null; then
    info "Homebrew ติดตั้งแล้ว: $(brew --version | head -1)"
    step "กำลังอัปเดต Homebrew..."
    brew update --quiet
else
    step "กำลังติดตั้ง Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "ติดตั้ง Homebrew สำเร็จ"
fi

# ============================================================
# 1. Git (latest) → brew
# ============================================================
header "1. ติดตั้ง Git (latest)"
brew install git
info "เวอร์ชัน: $(git --version)"
success "Git พร้อมใช้งาน"

# ============================================================
# 2. PHP 8 (latest stable) → brew
# ============================================================
header "2. ติดตั้ง PHP 8 (latest stable)"
brew install php
# link ให้ php ชี้ไปเวอร์ชันนี้
brew link --overwrite --force php 2>/dev/null || true
PHP_BIN="$(brew --prefix php)/bin"
export PATH="$PHP_BIN:$PATH"
grep -qF "$(brew --prefix php)/bin" "$HOME/.zshrc" 2>/dev/null || \
    echo "export PATH=\"$(brew --prefix php)/bin:\$PATH\"" >> "$HOME/.zshrc"
info "เวอร์ชัน: $(php --version | head -1)"
success "PHP พร้อมใช้งาน"

# ============================================================
# 3. Composer (latest) → official installer
# ============================================================
header "3. ติดตั้ง Composer (latest)"
if command -v composer &>/dev/null; then
    info "พบ Composer แล้ว กำลัง self-update..."
    composer self-update
else
    step "กำลังติดตั้ง Composer..."
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"
    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        fail "Checksum ไม่ถูกต้อง!"
        rm -f /tmp/composer-setup.php; exit 1
    fi
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f /tmp/composer-setup.php
fi
info "เวอร์ชัน: $(composer --version | head -1)"
success "Composer พร้อมใช้งาน"

# ============================================================
# 4. Laravel Installer (latest) → composer global
# ============================================================
header "4. ติดตั้ง Laravel Installer (latest)"
composer global require laravel/installer
COMPOSER_BIN="$HOME/.composer/vendor/bin"
export PATH="$COMPOSER_BIN:$PATH"
grep -qF "$COMPOSER_BIN" "$HOME/.zshrc" 2>/dev/null || \
    echo "export PATH=\"$COMPOSER_BIN:\$PATH\"" >> "$HOME/.zshrc"
success "ติดตั้ง Laravel Installer สำเร็จ"

# ============================================================
# 5. Node.js LTS (latest) → nvm
# ============================================================
header "5. ติดตั้ง Node.js LTS (latest via nvm)"
if [ ! -d "$HOME/.nvm" ]; then
    step "กำลังติดตั้ง nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

step "กำลังติดตั้ง Node.js LTS ล่าสุด..."
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'
info "เวอร์ชัน: $(node --version)"
success "Node.js พร้อมใช้งาน"

# ============================================================
# 6. Bun (latest) → brew
# ============================================================
header "6. ติดตั้ง Bun (latest)"
brew install bun
info "เวอร์ชัน: $(bun --version 2>/dev/null || echo 'เปิด terminal ใหม่')"
success "Bun พร้อมใช้งาน"

# ============================================================
# 7. Docker Desktop (latest) → brew --cask
# ============================================================
header "7. ติดตั้ง Docker Desktop (latest)"
if [ -d "/Applications/Docker.app" ]; then
    info "Docker Desktop ติดตั้งแล้ว"
    brew upgrade --cask docker 2>/dev/null || true
else
    step "กำลังติดตั้ง Docker Desktop..."
    brew install --cask docker
fi
success "Docker Desktop พร้อมใช้งาน (เปิดแอปครั้งแรกเพื่อ setup)"

# ============================================================
# 8. DBeaver Community (latest) → brew --cask
# ============================================================
header "8. ติดตั้ง DBeaver Community (latest)"
if [ -d "/Applications/DBeaver.app" ]; then
    info "DBeaver ติดตั้งแล้ว"
    brew upgrade --cask dbeaver-community 2>/dev/null || true
else
    step "กำลังติดตั้ง DBeaver..."
    brew install --cask dbeaver-community
fi
success "DBeaver พร้อมใช้งาน"

# ============================================================
# 9. Antigravity (latest) → npm install -g
# ============================================================
header "9. ติดตั้ง Antigravity (latest)"
if command -v npm &>/dev/null; then
    npm install -g @antigravity/cli
    success "ติดตั้ง Antigravity สำเร็จ"
else
    fail "ไม่พบ npm กรุณาตรวจสอบ Node.js"
fi

# ============================================================
# สรุปผล
# ============================================================
header "สรุปผลการติดตั้ง"
source "$HOME/.zshrc" 2>/dev/null || true

check() {
    local name="$1" cmd="$2"
    local ver; ver=$(eval "$cmd" 2>/dev/null | head -1) || true
    if [ -n "$ver" ]; then success "$name: $ver"
    else fail "$name: ไม่พบ (ลองเปิด terminal ใหม่)"; fi
}

check "Git"         "git --version"
check "PHP"         "php --version"
check "Composer"    "composer --version"
check "Laravel"     "laravel --version"
check "Node.js"     "node --version"
check "npm"         "npm --version"
check "Bun"         "bun --version"
check "Docker CLI"  "docker --version"
check "Antigravity" "antigravity --version"

echo ""
echo -e "${MAGENTA}============================================================${NC}"
echo -e "${GREEN} การติดตั้งเสร็จสมบูรณ์!${NC}"
echo -e "${YELLOW} หมายเหตุ:${NC}"
echo -e "${YELLOW}   - เปิด Terminal ใหม่เพื่อให้ PATH มีผล${NC}"
echo -e "${YELLOW}   - เปิด Docker Desktop จาก Applications ครั้งแรก${NC}"
echo -e "${MAGENTA}============================================================${NC}"
echo ""
echo -e "${GRAY}กด Enter เพื่อปิด...${NC}"
read -r
