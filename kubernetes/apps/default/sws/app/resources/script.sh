#!/usr/bin/env bash
# setup-codex.sh — Setup Codex dùng CLIProxy
# Tạo ~/.codex/auth.json (key do người dùng nhập) + ~/.codex/config.toml
#
# Người dùng cuối chỉ cần 1 lệnh (thay URL bằng URL thật sau khi bạn host file này):
#   curl -fsSL https://example.com/setup-codex.sh | bash
#   # hoặc an toàn hơn (stdin vẫn là terminal):
#   bash -c "$(curl -fsSL https://example.com/setup-codex.sh)"
#
# Script BẮT BUỘC hỏi 2 thứ (không có mặc định thầm lặng):
#   1. CLIProxy API key (nhập ẩn, nhập 2 lần để xác nhận)
#   2. Bật/tắt WebSocket (phải gõ y hoặc n, Enter trống sẽ hỏi lại)
#
# Chỉ dành cho automation (CI): truyền thẳng thì bỏ qua câu hỏi tương ứng:
#   ./setup-codex.sh --key sk-xxxx --websockets false
#
# Tuỳ chọn khác:
#   --base-url <url>   mặc định: https://cliproxy.sunsilk.id.vn/v1
#   --model <model>    ghi thêm model = "..." (tuỳ chọn)
#   -h, --help         hiện hướng dẫn

set -euo pipefail

BASE_URL="https://cliproxy.sunsilk.id.vn/v1"
API_KEY=""
WEBSOCKETS=""
MODEL=""
KEY_FROM_FLAG=0
WS_FROM_FLAG=0

usage() {
  cat <<'EOF'
setup-codex.sh — Setup Codex dùng CLIProxy

Người dùng cuối:
  curl -fsSL <URL-của-file-này> | bash

Script bắt buộc hỏi: (1) API key, (2) bật/tắt WebSocket (y/n).

Tuỳ chọn (chỉ cho automation, truyền thì bỏ qua câu hỏi tương ứng):
  --key <key>          API key
  --websockets <bool>  true/false, yes/no, y/n, on/off, 1/0
                       true = WebSocket (nhanh hơn, lỗi trả về luôn),
                       false = HTTP (gateway retry được khi Codex overload)
  --no-websockets      = --websockets false
  --with-websockets    = --websockets true
  --base-url <url>     mặc định: https://cliproxy.sunsilk.id.vn/v1
  --model <model>      ghi thêm model = "..."
  -h, --help           hiện hướng dẫn này
EOF
}

to_bool() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    true|1|yes|y|on)  echo "true" ;;
    false|0|no|n|off) echo "false" ;;
    *) return 1 ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key)            API_KEY="${2:?--key cần giá trị}"; KEY_FROM_FLAG=1; shift 2 ;;
    --key=*)          API_KEY="${1#*=}"; KEY_FROM_FLAG=1; shift ;;
    --websockets)     WEBSOCKETS="$(to_bool "${2:?--websockets cần true/false}")" || { echo "❌ --websockets chỉ nhận true/false" >&2; exit 1; }; WS_FROM_FLAG=1; shift 2 ;;
    --websockets=*)   WEBSOCKETS="$(to_bool "${1#*=}")" || { echo "❌ --websockets chỉ nhận true/false" >&2; exit 1; }; WS_FROM_FLAG=1; shift ;;
    --no-websockets)  WEBSOCKETS="false"; WS_FROM_FLAG=1; shift ;;
    --with-websockets|--websockets-on) WEBSOCKETS="true"; WS_FROM_FLAG=1; shift ;;
    --base-url)       BASE_URL="${2:?--base-url cần giá trị}"; shift 2 ;;
    --base-url=*)     BASE_URL="${1#*=}"; shift ;;
    --model)          MODEL="${2:?--model cần giá trị}"; shift 2 ;;
    --model=*)        MODEL="${1#*=}"; shift ;;
    -h|--help)        usage; exit 0 ;;
    *) echo "❌ Tham số không rõ: $1 (dùng --help)" >&2; exit 1 ;;
  esac
done

CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
AUTH_FILE="$CODEX_DIR/auth.json"
CONFIG_FILE="$CODEX_DIR/config.toml"

# --- Chọn nguồn nhập liệu ---
# Khi chạy `curl ... | bash`, stdin là nội dung script, không phải bàn phím.
# Vì vậy mọi câu hỏi phải đọc từ /dev/tty (terminal thật), không đọc từ stdin.
if [[ -t 0 ]]; then
  INPUT_DEV="/dev/stdin"
elif [[ -r /dev/tty ]]; then
  INPUT_DEV="/dev/tty"
else
  INPUT_DEV="/dev/stdin"  # không có terminal: các read bên dưới sẽ báo lỗi rõ ràng
fi

ask() { # $1 = prompt -> in ra biến ASK_RESULT (đọc từ terminal)
  printf '%s' "$1" >&2
  IFS= read -r ASK_RESULT < "$INPUT_DEV" || {
    echo >&2
    echo "❌ Không đọc được từ terminal. Hãy chạy trong terminal thật (đừng redirect stdin), ví dụ:" >&2
    echo "   bash -c \"\$(curl -fsSL <URL>)\"" >&2
    exit 1
  }
}

ask_secret() { # $1 = prompt -> in ra biến ASK_RESULT (nhập ẩn)
  printf '%s' "$1" >&2
  IFS= read -r -s ASK_RESULT < "$INPUT_DEV" || {
    echo >&2
    echo "❌ Không đọc được từ terminal. Hãy chạy trong terminal thật." >&2
    exit 1
  }
  printf '\n' >&2
}

echo "=== Setup Codex (CLIProxy) ===" >&2

# --- 1. BẮT BUỘC hỏi key (trừ khi automation truyền --key) ---
if [[ "$KEY_FROM_FLAG" -eq 0 ]]; then
  while true; do
    ask_secret "1) Nhập CLIProxy API key (sk-..., nhập ẩn): "
    API_KEY="$(printf '%s' "$ASK_RESULT" | tr -d '[:space:]')"
    [[ -n "$API_KEY" ]] || { echo "❌ Key trống, nhập lại." >&2; continue; }
    ask_secret "   Nhập lại key để xác nhận: "
    _confirm="$(printf '%s' "$ASK_RESULT" | tr -d '[:space:]')"
    [[ "$API_KEY" == "$_confirm" ]] || { echo "❌ Key nhập lại không khớp, nhập lại từ đầu." >&2; continue; }
    break
  done
else
  API_KEY="$(printf '%s' "$API_KEY" | tr -d '[:space:]')"
  [[ -n "$API_KEY" ]] || { echo "❌ Key trống." >&2; exit 1; }
fi

# --- 2. BẮT BUỘC hỏi bật/tắt websocket: phải gõ y/n, Enter trống hỏi lại ---
if [[ "$WS_FROM_FLAG" -eq 0 ]]; then
  cat >&2 <<'EOF'
2) Chọn kiểu kết nối: WebSocket hay HTTP?
   • Bật (y): dùng WebSocket — phản hồi nhanh hơn, chữ hiện ra gần như tức thì.
     Nhưng khi server lỗi (ví dụ Codex đang quá tải/overload) thì lỗi sẽ trả
     về luôn, không tự thử lại được, bạn phải gửi lại thủ công.
   • Tắt (n): dùng HTTP thường — phản hồi có thể chậm hơn một chút.
     Bù lại gateway tự retry được khi gặp lỗi tạm thời như overload,
     nên ổn định hơn, ít bị văng giữa chừng.
   Không chắc thì chọn n (ổn định hơn).
EOF
  while true; do
    ask "   Bật WebSocket? Gõ y = bật, n = tắt (bắt buộc chọn): "
    case "$(printf '%s' "$ASK_RESULT" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')" in
      y|yes|true|1|on)  WEBSOCKETS="true"; break ;;
      n|no|false|0|off) WEBSOCKETS="false"; break ;;
      *) echo "❌ Chưa chọn. Gõ y để bật hoặc n để tắt." >&2 ;;
    esac
  done
fi

mkdir -p "$CODEX_DIR"
chmod 700 "$CODEX_DIR" 2>/dev/null || true

backup() { # $1 = file
  [[ -f "$1" ]] && cp -a "$1" "$1.bak.$(date +%Y%m%d%H%M%S)" && echo "  backup: $1.bak.*" >&2
  return 0
}

# --- 3. Ghi auth.json (đúng format server: auth_mode + OPENAI_API_KEY, chmod 600) ---
echo "→ Ghi $AUTH_FILE" >&2
backup "$AUTH_FILE"
if command -v python3 >/dev/null 2>&1; then
  API_KEY="$API_KEY" AUTH_FILE="$AUTH_FILE" python3 - <<'PY'
import json, os, pathlib
p = pathlib.Path(os.environ["AUTH_FILE"])
data = {"auth_mode": "apikey", "OPENAI_API_KEY": os.environ["API_KEY"]}
tmp = p.with_suffix(".json.tmp")
tmp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
tmp.replace(p)
PY
else
  esc=$(printf '%s' "$API_KEY" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{\n  "auth_mode": "apikey",\n  "OPENAI_API_KEY": "%s"\n}\n' "$esc" > "$AUTH_FILE"
fi
chmod 600 "$AUTH_FILE"

# --- 4. Ghi/cập nhật config.toml (giữ nguyên phần còn lại nếu đã có) ---
echo "→ Cập nhật $CONFIG_FILE (supports_websockets = $WEBSOCKETS)" >&2
backup "$CONFIG_FILE"
touch "$CONFIG_FILE"
if command -v python3 >/dev/null 2>&1; then
  CONFIG_FILE="$CONFIG_FILE" BASE_URL="$BASE_URL" WEBSOCKETS="$WEBSOCKETS" MODEL="$MODEL" python3 - <<'PY'
import os, pathlib, re
p = pathlib.Path(os.environ["CONFIG_FILE"])
text = p.read_text(encoding="utf-8") if p.exists() else ""
ws = os.environ["WEBSOCKETS"]
base = os.environ["BASE_URL"]
model = os.environ.get("MODEL", "").strip()

provider_block = (
    "[model_providers.cliproxy]\n"
    'name = "CLIProxy"\n'
    f'base_url = "{base}"\n'
    'wire_api = "responses"\n'
    "requires_openai_auth = true\n"
    f"supports_websockets = {ws}\n"
)

# Cách cũ chỉ thêm openai_base_url ở đầu file: xóa hẳn dòng đó (mọi vị trí).
text = re.sub(r"(?m)^openai_base_url\s*=.*\n?", "", text)

m = re.search(r"(?m)^\[", text)
head, rest = (text[:m.start()], text[m.start():]) if m else (text, "")

def set_kv(block: str, key: str, raw_value: str) -> str:
    pat = re.compile(rf"(?m)^{re.escape(key)}\s*=.*$")
    line = f"{key} = {raw_value}"
    return pat.sub(line, block, count=1) if pat.search(block) else (block.rstrip() + "\n" + line + "\n" if block.strip() else line + "\n")

head = set_kv(head, "model_provider", '"cliproxy"')
if model:
    head = set_kv(head, "model", f'"{model}"')

# Block cliproxy luôn nằm ngay đầu file, ngay sau các key top-level,
# trước mọi section khác ([tui], [projects.*], ...). Block cũ ở bất cứ đâu đều bị gỡ.
pat_block = re.compile(r"(?ms)^\[model_providers\.cliproxy\]\n.*?(?=^\[|\Z)")
rest = pat_block.sub("", rest).strip()
text = head.rstrip() + "\n\n" + provider_block
if rest:
    text += "\n" + rest + "\n"

p.write_text(text.rstrip() + "\n", encoding="utf-8")
print(p.read_text(encoding="utf-8"))
PY
else
  # Không có python3: làm cùng việc bằng awk (giữ nguyên phần config còn lại).
  echo "⚠️  Không có python3: dùng awk để cập nhật config.toml." >&2
  _tmp_config="$(mktemp "${TMPDIR:-/tmp}/codex-config.XXXXXX")"
  MODEL="$MODEL" BASE_URL="$BASE_URL" WEBSOCKETS="$WEBSOCKETS" awk '
    /^openai_base_url[[:space:]]*=/ { next }
    /^\[model_providers\.cliproxy\][[:space:]]*$/ { inprov = 1; next }
    /^\[/ { inprov = 0 }
    inprov { next }
    /^\[/ { inrest = 1 }
    {
      if (!inrest) {
        if ($0 ~ /^model_provider[[:space:]]*=/) { head[++hn] = "model_provider = \"cliproxy\""; seen_mp = 1 }
        else if (ENVIRON["MODEL"] != "" && $0 ~ /^model[[:space:]]*=/) { head[++hn] = "model = \"" ENVIRON["MODEL"] "\""; seen_m = 1 }
        else head[++hn] = $0
      } else {
        rest[++rn] = $0
      }
    }
    END {
      if (!seen_mp) head[++hn] = "model_provider = \"cliproxy\""
      if (ENVIRON["MODEL"] != "" && !seen_m) head[++hn] = "model = \"" ENVIRON["MODEL"] "\""
      for (i = 1; i <= hn; i++) print head[i]
      print ""
      print "[model_providers.cliproxy]"
      print "name = \"CLIProxy\""
      print "base_url = \"" ENVIRON["BASE_URL"] "\""
      print "wire_api = \"responses\""
      print "requires_openai_auth = true"
      print "supports_websockets = " ENVIRON["WEBSOCKETS"]
      if (rn) {
        print ""
        for (i = 1; i <= rn; i++) print rest[i]
      }
    }
  ' "$CONFIG_FILE" > "$_tmp_config"
  cat "$_tmp_config" > "$CONFIG_FILE"
  rm -f "$_tmp_config"
  cat "$CONFIG_FILE"
fi
chmod 600 "$CONFIG_FILE" 2>/dev/null || true

# --- 5. Kiểm tra lại ---
echo
echo "✅ Xong. Kiểm tra:"
masked="${API_KEY:0:4}…${API_KEY: -4} (len=${#API_KEY})"
echo "  auth.json : $AUTH_FILE  key=$masked  (chmod $(stat -c '%a' "$AUTH_FILE" 2>/dev/null || echo '?'))"
echo "  websockets: $WEBSOCKETS   base_url: $BASE_URL"
command -v codex >/dev/null 2>&1 && codex --version || echo "  (chưa thấy lệnh 'codex' trong PATH — cài Codex xong chạy: codex)"
echo "  Chạy thử: codex   |   Muốn đổi websocket thì chạy lại script này."
