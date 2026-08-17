#!/bin/bash

# ============================================================
#  BOJ - 경쟁 프로그래밍 문제 풀이 관리 스크립트 (AtCoder)
# ============================================================
#  사용법:
#    boj start <문제ID> <언어>    - 새 문제 풀이 시작
#    boj done  [시간ms] [메모리KB] - 풀이 완료 → 정리 + git push
#    boj config                   - 설정 확인/변경
# ============================================================

# ── 설정 ──────────────────────────────────────────────────────
# 설정 파일 위치는 홈 디렉토리에 고정 (어디서든 찾을 수 있도록)
CONFIG_FILE="$HOME/.bojrc"

# 기본값
BOJ_ROOT=""
GIT_ENABLED=true
DATE_FMT="%Y%m%d"

# 설정 파일이 있으면 불러오기 (BOJ_ROOT 등을 덮어씀)
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# BOJ_ROOT 기반 경로 계산 (init 전이면 비어있을 수 있음)
WORKSPACE="$BOJ_ROOT/workspace"
TEMPLATE_DIR="$BOJ_ROOT/templates"
ARCHIVE_DIR="$BOJ_ROOT/archive"

# init 외의 명령어에서 BOJ_ROOT가 설정되어 있는지 확인
require_init() {
    if [[ -z "$BOJ_ROOT" ]] || [[ ! -d "$BOJ_ROOT" ]]; then
        error "BOJ가 초기화되지 않았습니다.\n       원하는 디렉토리에서 'boj init'을 먼저 실행하세요."
    fi
}

# ── 색상 ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ── 유틸 함수 ────────────────────────────────────────────────
info()    { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*"; exit 1; }
header()  { echo -e "\n${CYAN}━━━ $* ━━━${NC}"; }

ensure_dir() {
    [[ -d "$1" ]] || mkdir -p "$1"
}

# ── start: 새 문제 풀이 시작 ─────────────────────────────────
cmd_start() {
    require_init
    local problem="$1"
    local lang="$2"

    [[ -z "$problem" || -z "$lang" ]] && error "사용법: boj start <문제ID> <언어>"

    header "문제 $problem 풀이 시작 ($lang)"

    # workspace 비어있는지 확인
    if [[ -d "$WORKSPACE" ]] && [[ -n "$(ls -A "$WORKSPACE" 2>/dev/null)" ]]; then
        warn "workspace에 파일이 남아있습니다:"
        ls -la "$WORKSPACE"
        echo ""
        read -p "계속 진행하시겠습니까? 기존 파일이 유지됩니다. (y/N): " confirm
        [[ "$confirm" != [yY] ]] && { echo "취소됨."; exit 0; }
    fi

    ensure_dir "$WORKSPACE"

    # 1) 템플릿 복사
    local tmpl_dir="${TEMPLATE_DIR}/${lang}_template"
    if [[ ! -d "$tmpl_dir" ]]; then
        error "템플릿 폴더를 찾을 수 없습니다: $tmpl_dir\n       'boj init' 실행 후 템플릿 파일을 추가하세요."
    fi
    if [[ -z "$(ls -A "$tmpl_dir" 2>/dev/null)" ]]; then
        error "템플릿 폴더가 비어있습니다: $tmpl_dir\n       템플릿 파일을 먼저 추가하세요."
    fi
    cp -r "$tmpl_dir"/. "$WORKSPACE"/
    info "템플릿 복사 완료: $tmpl_dir → workspace"

    # 2) 문제 URL txt 파일 생성
    local contest="${problem%_*}"  # abc123_a → abc123
    local url="https://atcoder.jp/contests/${contest}/tasks/${problem}"
    local txt_name="${problem}_${lang}.txt"
    echo "$url" > "$WORKSPACE/$txt_name"
    info "문제 URL 파일 생성: $txt_name → $url"

    echo ""
    info "준비 완료! workspace에서 풀이를 시작하세요."
    echo -e "    ${CYAN}cd $WORKSPACE${NC}"
}

# ── done: 풀이 완료 → 아카이브 + git push ────────────────────
cmd_done() {
    require_init
    local time_ms="$1"
    local memory_kb="$2"

    # workspace 확인
    [[ ! -d "$WORKSPACE" ]] && error "workspace가 존재하지 않습니다."
    [[ -z "$(ls -A "$WORKSPACE" 2>/dev/null)" ]] && error "workspace가 비어있습니다."

    # txt 파일에서 문제번호와 언어 자동 추출
    local txt_file
    txt_file=$(find "$WORKSPACE" -maxdepth 1 -name '*_*.txt' | head -1)

    if [[ -z "$txt_file" ]]; then
        error "workspace에 문제 정보 txt 파일이 없습니다.\n       'boj start'로 시작한 문제인지 확인하세요."
    fi

    local basename=$(basename "$txt_file" .txt)  # 예: abc123_a_cpp
    local problem="${basename%_*}"               # abc123_a (마지막 _ 앞)
    local lang="${basename##*_}"                 # cpp (마지막 _ 뒤)

    local today=$(date +"$DATE_FMT")
    local dest_name="${problem}_${lang}_${today}"
    local dest_path="$ARCHIVE_DIR/$dest_name"

    header "문제 $problem 풀이 완료 ($lang)"

    # 시간/메모리 미입력 경고
    if [[ -z "$time_ms" || -z "$memory_kb" ]]; then
        warn "채점 결과가 입력되지 않았습니다."
        warn "  사용법: boj done <시간ms> <메모리KB>"
        read -p "채점 결과 없이 계속 진행하시겠습니까? (y/N): " confirm
        [[ "$confirm" != [yY] ]] && { echo "취소됨."; exit 0; }
    fi

    # 시간/메모리 정보를 txt 파일에 추가
    if [[ -n "$time_ms" || -n "$memory_kb" ]]; then
        # ms → 초 변환 (예: 4 → 0.004s, 1234 → 1.234s)
        local time_sec=""
        if [[ -n "$time_ms" ]]; then
            time_sec=$(awk "BEGIN { printf \"%.3f\", $time_ms / 1000 }")
        fi

        echo "" >> "$txt_file"
        echo "── 채점 결과 ──" >> "$txt_file"
        [[ -n "$time_ms" ]]  && echo "시간: ${time_sec}s (${time_ms}ms)" >> "$txt_file"
        [[ -n "$memory_kb" ]] && echo "메모리: ${memory_kb} KB" >> "$txt_file"
        echo "날짜: ${today}" >> "$txt_file"
        info "채점 결과 기록: ${time_sec:-?}s / ${memory_kb:-?} KB"
    fi

    # 같은 이름의 폴더가 이미 있으면 처리
    if [[ -d "$dest_path" ]]; then
        # 기존 버전 모두 수집 (원본 + _1, _2, ...)
        local existing=("$dest_path")
        local n=1
        while [[ -d "${dest_path}_${n}" ]]; do
            existing+=("${dest_path}_${n}")
            ((n++))
        done
        local next_num=$n

        warn "이미 존재하는 풀이가 ${#existing[@]}개 있습니다:"
        echo ""
        local i=1
        for e in "${existing[@]}"; do
            echo "  [$i] $(basename "$e")"
            ((i++))
        done
        echo ""
        echo "  [N] 따로 저장 → ${dest_name}_${next_num}"
        echo "  [D] 덮어쓸 번호 선택"
        echo "  [Q] 취소"
        echo ""
        read -p "선택 (N/D/Q): " choice

        case "$choice" in
            [nN])
                dest_name="${dest_name}_${next_num}"
                dest_path="$ARCHIVE_DIR/$dest_name"
                info "새 이름으로 저장: $dest_name"
                ;;
            [dD])
                echo ""
                read -p "덮어쓸 번호를 선택하세요 (1-${#existing[@]}): " overwrite_idx
                if [[ "$overwrite_idx" =~ ^[0-9]+$ ]] && (( overwrite_idx >= 1 && overwrite_idx <= ${#existing[@]} )); then
                    local target="${existing[$((overwrite_idx-1))]}"
                    rm -rf "$target"
                    dest_path="$target"
                    dest_name=$(basename "$target")
                    info "덮어쓰기 대상: $dest_name"
                else
                    error "잘못된 선택입니다."
                fi
                ;;
            *)
                echo "취소됨."
                exit 0
                ;;
        esac
    fi

    ensure_dir "$ARCHIVE_DIR"

    # 1) workspace → archive로 이동
    mv "$WORKSPACE" "$dest_path"
    info "파일 이동 완료: workspace → $dest_name"

    # workspace 재생성 (다음 문제를 위해)
    ensure_dir "$WORKSPACE"

    # 2) Git push
    if [[ "$GIT_ENABLED" == true ]]; then
        header "Git Push"

        cd "$BOJ_ROOT" || error "BOJ_ROOT 디렉토리로 이동 실패"

        # git 저장소 확인
        if ! git rev-parse --is-inside-work-tree &>/dev/null; then
            warn "git 저장소가 아닙니다. git init을 먼저 실행하세요."
            warn "  cd $BOJ_ROOT && git init"
            return
        fi

        # git 사용자 정보 확인
        local git_email=$(git config user.email 2>/dev/null)
        local git_name=$(git config user.name 2>/dev/null)
        if [[ -z "$git_email" || -z "$git_name" ]]; then
            warn "git 사용자 정보가 설정되지 않았습니다. 먼저 설정하세요."
            echo -e "    ${CYAN}git config --global user.email \"your@email.com\"${NC}"
            echo -e "    ${CYAN}git config --global user.name \"이름\"${NC}"
            return
        fi

        git add -A
        if git commit -m "solved: ${problem} (${lang}) - ${today}"; then
            if git remote | grep -q origin; then
                git push origin "$(git branch --show-current)"
                info "Git push 완료!"
            else
                warn "원격 저장소(origin)가 설정되지 않았습니다."
                warn "  git remote add origin <your-repo-url>"
                info "로컬 커밋은 완료되었습니다."
            fi
        else
            warn "git commit에 실패했습니다."
        fi
    fi

    echo ""
    info "문제 $problem 아카이브 완료!"
    echo -e "    ${CYAN}$dest_path${NC}"
}

# ── load: 아카이브에서 이전 풀이 불러오기 ─────────────────────
cmd_load() {
    require_init
    local problem="$1"

    # 인자 없으면 archive 목록 표시
    if [[ -z "$problem" ]]; then
        header "아카이브 목록"
        if [[ ! -d "$ARCHIVE_DIR" ]] || [[ -z "$(ls -A "$ARCHIVE_DIR" 2>/dev/null)" ]]; then
            warn "아카이브가 비어있습니다."
            return
        fi
        echo ""
        local i=1
        for dir in "$ARCHIVE_DIR"/*/; do
            local name=$(basename "$dir")
            echo "  [$i] $name"
            ((i++))
        done
        echo ""
        echo -e "사용법: ${CYAN}boj load <문제ID>${NC} 또는 ${CYAN}boj load <폴더이름>${NC}"
        return
    fi

    # workspace 비어있는지 확인
    if [[ -d "$WORKSPACE" ]] && [[ -n "$(ls -A "$WORKSPACE" 2>/dev/null)" ]]; then
        warn "workspace에 파일이 남아있습니다."
        read -p "기존 파일을 비우고 불러오시겠습니까? (y/N): " confirm
        [[ "$confirm" != [yY] ]] && { echo "취소됨."; exit 0; }
        rm -rf "$WORKSPACE"/*
    fi

    ensure_dir "$WORKSPACE"

    # 문제번호로 검색 (여러 개일 수 있음)
    local matches=()
    for dir in "$ARCHIVE_DIR"/*/; do
        local name=$(basename "$dir")
        # 정확한 폴더이름 또는 문제번호로 시작하는 폴더
        if [[ "$name" == "$problem" ]] || [[ "$name" == ${problem}_* ]]; then
            matches+=("$dir")
        fi
    done

    if [[ ${#matches[@]} -eq 0 ]]; then
        error "문제 '$problem'에 해당하는 아카이브를 찾을 수 없습니다."
    elif [[ ${#matches[@]} -eq 1 ]]; then
        # 하나만 매칭 → 바로 복사
        local src="${matches[0]}"
        cp -r "$src"/. "$WORKSPACE"/
        info "불러오기 완료: $(basename "$src") → workspace"
    else
        # 여러 개 매칭 → 선택
        header "여러 결과가 있습니다"
        echo ""
        local i=1
        for dir in "${matches[@]}"; do
            echo "  [$i] $(basename "$dir")"
            ((i++))
        done
        echo ""
        read -p "번호를 선택하세요 (1-${#matches[@]}): " choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#matches[@]} )); then
            local src="${matches[$((choice-1))]}"
            cp -r "$src"/. "$WORKSPACE"/
            info "불러오기 완료: $(basename "$src") → workspace"
        else
            error "잘못된 선택입니다."
        fi
    fi

    echo ""
    info "workspace에서 이전 풀이를 확인하세요."
    echo -e "    ${CYAN}cd $WORKSPACE${NC}"
}

# ── config: 현재 설정 확인 ───────────────────────────────────
cmd_config() {
    require_init
    header "현재 설정"
    echo "  BOJ_ROOT     = $BOJ_ROOT"
    echo "  WORKSPACE    = $WORKSPACE"
    echo "  TEMPLATE_DIR = $TEMPLATE_DIR"
    echo "  ARCHIVE_DIR  = $ARCHIVE_DIR"
    echo "  GIT_ENABLED  = $GIT_ENABLED"
    echo "  DATE_FMT     = $DATE_FMT"

    header "Git 정보"
    if cd "$BOJ_ROOT" 2>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
        local branch=$(git branch --show-current 2>/dev/null)
        local remote=$(git remote get-url origin 2>/dev/null)
        local status=$(git status --short 2>/dev/null | wc -l)
        local git_name=$(git config user.name 2>/dev/null)
        local git_email=$(git config user.email 2>/dev/null)
        echo "  브랜치       = ${branch:-없음}"
        echo "  원격 저장소  = ${remote:-설정 안 됨}"
        echo "  사용자 이름  = ${git_name:-설정 안 됨}"
        echo "  사용자 이메일 = ${git_email:-설정 안 됨}"
        echo "  변경 파일 수 = ${status}개"
        if [[ -z "$git_name" || -z "$git_email" ]]; then
            echo ""
            warn "git 사용자 정보가 설정되지 않았습니다. 커밋을 하려면 설정하세요."
            echo -e "    ${CYAN}git config --global user.name \"이름\"${NC}"
            echo -e "    ${CYAN}git config --global user.email \"your@email.com\"${NC}"
        fi
        if [[ -z "$remote" ]]; then
            echo ""
            warn "원격 저장소가 설정되지 않았습니다. push를 하려면 설정하세요."
            echo -e "    ${CYAN}cd $BOJ_ROOT && git remote add origin <your-repo-url>${NC}"
        fi
    else
        warn "git 저장소가 아닙니다."
        echo -e "    ${CYAN}cd $BOJ_ROOT && git init${NC}"
    fi

    echo ""
    echo -e "설정 변경: ${CYAN}$CONFIG_FILE${NC} 파일을 편집하세요."
}

# ── init: 초기 디렉토리 구조 생성 ────────────────────────────
cmd_init() {
    header "BOJ 디렉토리 초기화"

    # 현재 디렉토리를 BOJ_ROOT로 설정
    BOJ_ROOT="$(pwd)"
    WORKSPACE="$BOJ_ROOT/workspace"
    TEMPLATE_DIR="$BOJ_ROOT/templates"
    ARCHIVE_DIR="$BOJ_ROOT/archive"

    # 설정 파일에 저장 (~/.bojrc)
    cat > "$CONFIG_FILE" << EOF
# BOJ 설정 파일 (boj init 시 자동 생성)
BOJ_ROOT="$BOJ_ROOT"
GIT_ENABLED=$GIT_ENABLED
DATE_FMT="$DATE_FMT"
EOF
    info "설정 저장: $CONFIG_FILE → BOJ_ROOT=$BOJ_ROOT"

    ensure_dir "$WORKSPACE"
    ensure_dir "$TEMPLATE_DIR"
    ensure_dir "$ARCHIVE_DIR"

    info "디렉토리 생성 완료:"
    echo "  $WORKSPACE"
    echo "  $TEMPLATE_DIR"
    echo "  $ARCHIVE_DIR"

    # .gitignore 생성 (archive만 git에 포함)
    local gitignore="$BOJ_ROOT/.gitignore"
    if [[ ! -f "$gitignore" ]]; then
        cat > "$gitignore" << 'GIEOF'
# workspace와 templates는 git에서 제외
workspace/
templates/

# C# 빌드 산출물 제외
**/bin/
**/obj/
GIEOF
        info ".gitignore 생성 (workspace, templates 제외)"
    fi

    # 빈 템플릿 폴더 생성 (사용자가 직접 템플릿 파일을 넣어야 함)
    local langs=("cpp" "python" "java" "csharp")
    for l in "${langs[@]}"; do
        local tmpl="$TEMPLATE_DIR/${l}_template"
        if [[ ! -d "$tmpl" ]]; then
            ensure_dir "$tmpl"
            info "템플릿 폴더 생성: $tmpl"
        fi
    done

    echo ""
    warn "템플릿 폴더가 비어있습니다. 각 폴더에 템플릿 파일을 직접 추가하세요."
    echo -e "    예: ${CYAN}vim $TEMPLATE_DIR/cpp_template/main.cpp${NC}"
    info "초기화 완료! 'boj start <문제ID> <언어>'로 시작하세요."
}

# ── 도움말 ────────────────────────────────────────────────────
cmd_help() {
    echo -e "${CYAN}"
    echo "┌──────────────────────────────────────────────┐"
    echo "│       BOJ 문제 풀이 관리 스크립트 (AtCoder)   │"
    echo "└──────────────────────────────────────────────┘"
    echo -e "${NC}"
    echo "사용법:"
    echo "  boj init                              초기 디렉토리 구조 생성"
    echo "  boj start <문제ID> <언어>              새 문제 풀이 시작"
    echo "  boj done  [시간ms] [메모리KB]          풀이 완료 (아카이브 + git push)"
    echo "  boj load  [문제ID|폴더이름]            이전 풀이 불러오기"
    echo "  boj config                            현재 설정 확인"
    echo "  boj help                              이 도움말"
    echo ""
    echo "예시:"
    echo "  cd ~/my-boj && boj init    # 현재 디렉토리에서 초기화"
    echo "  boj start abc300_a cpp      # ABC300 A번을 C++로 시작"
    echo "  boj start arc180_b csharp   # ARC180 B번을 C#으로 시작"
    echo "  boj done  4 2020            # 풀이 완료 (4ms, 2020KB 기록)"
    echo "  boj done                    # 채점 결과 없이 완료"
    echo "  boj load                    # 아카이브 목록 보기"
    echo "  boj load  abc300_a          # ABC300 A번 풀이 불러오기"
    echo ""
    echo "디렉토리 구조 (init 실행 위치 기준):"
    echo "  <init 디렉토리>/"
    echo "  ├── workspace/              ← 현재 풀이 중인 작업 공간"
    echo "  ├── templates/"
    echo "  │   ├── cpp_template/"
    echo "  │   ├── python_template/"
    echo "  │   ├── java_template/"
    echo "  │   └── csharp_template/"
    echo "  └── archive/"
    echo "      ├── abc300_a_cpp_20260325/"
    echo "      └── arc180_b_csharp_20260325/"
}

# ── 메인 ──────────────────────────────────────────────────────
case "${1:-help}" in
    start)  cmd_start "$2" "$3" ;;
    done)   cmd_done  "$2" "$3" ;;
    load)   cmd_load  "$2" ;;
    config) cmd_config ;;
    init)   cmd_init ;;
    help|*) cmd_help ;;
esac