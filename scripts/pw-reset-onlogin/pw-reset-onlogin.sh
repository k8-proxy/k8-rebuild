#!/bin/bash
CMD='force_pw_reset || exit'
grep 'function force_pw_reset' ~/.profile > /dev/null ; EXIT_CODE=$?
if [ "$EXIT_CODE" != 0 ] ; then
cat >> ~/.profile <<EOF

#####################################
function force_pw_reset () {
	passwd \$USER || exit 1
	sed -i '/^$CMD$/d' ~/.profile
}
EOF
fi
#####################################
echo $CMD >> ~/.profile
