#/bin/sh
compute_budget() {
  echo "scale=0; ($1*$2+0.5)/1" | bc
}

DIR="analysis"
if [ ! -f $DIR/inspect.data ]; then
   DIR="analysis" OPT="--analyze-design" make 
fi

TOKENS=$(cat $DIR/inspect.data)
BUDGET=( $TOKENS )
CONST=$(compute_budget ${BUDGET[0]} $1 )
OP=$(compute_budget ${BUDGET[1]} $2 )
BRANCH=$(compute_budget ${BUDGET[2]} $3 )

DIR="obf_${CONST}_${OP}_${BRANCH}" OPT="--obfuscate --input-key input.key --key-budget \"$CONST,$OP,$BRANCH\" --generate-conformal=on" make

