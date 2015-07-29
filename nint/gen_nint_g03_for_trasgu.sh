#! /bin/bash

for ii in *.gjf ; do
    i=${ii%.gjf}
    echo $(pwd)/${i}.sub
    cat > ${i}.sub <<EOF
cd $(pwd)
g03 ${i}.gjf
EOF
done
