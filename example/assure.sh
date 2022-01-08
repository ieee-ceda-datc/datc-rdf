mkdir -p assure
[ -d assure ] && echo "Clean-up old results." && rm -rf assure/*

generate_key -b 512 -o assure/key_512bit.txt

assure \
    --top Core \
    -D SYNTHESIS \
    --enable-key-reuse \
    --obfuscate-ops \
    --obfuscate-branch \
    --output=./assure/out \
    --input-key=./assure/key_512bit.txt \
    ./riscv-mini/generated-src/Tile.v
