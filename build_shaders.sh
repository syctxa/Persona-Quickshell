#!/usr/bin/env bash
# Compile all Persona-Quickshell shaders using qsb
# Run from anywhere: bash build_shaders.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHADER_DIR="$SCRIPT_DIR/Assets/shaders"

# Find qsb — check PATH first, then common Nix locations
QSB=$(command -v qsb 2>/dev/null)
if [[ -z "$QSB" ]]; then
    QSB=$(find /nix/store -name "qsb" -path "*/qtshadertools*/bin/qsb" 2>/dev/null | sort -V | tail -1)
fi
if [[ -z "$QSB" ]]; then
    echo "ERROR: qsb not found. Install qt6-shader-tools or add it to PATH."
    exit 1
fi
echo "Using qsb: $QSB"

compile_pair() {
    local dir="$1"
    local base="$2"
    local frag="$dir/$base.frag"
    local vert="$dir/$base.vert"

    if [[ -f "$frag" ]]; then
        echo "  Compiling $frag ..."
        "$QSB" --glsl "100 es,120,150" --hlsl 50 --msl 12 \
            -o "$dir/$base.frag.qsb" "$frag" && echo "    OK: $base.frag.qsb"
    fi
    if [[ -f "$vert" ]]; then
        echo "  Compiling $vert ..."
        "$QSB" --glsl "100 es,120,150" --hlsl 50 --msl 12 \
            -o "$dir/$base.vert.qsb" "$vert" && echo "    OK: $base.vert.qsb"
    fi
}

echo "=== Compiling shaders in $SHADER_DIR ==="
for dir in "$SHADER_DIR"/*/; do
    name=$(basename "$dir")
    echo "[ $name ]"
    compile_pair "$dir" "$name"
done

echo ""
echo "=== Done. Restart Quickshell to pick up changes. ==="
