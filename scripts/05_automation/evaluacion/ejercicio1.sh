#!/bin/bash

disco=$(df -x tmpfs  --output=source | tail -n +2)

echo "$disco" | tr  ' ' '\n' > fichero.txt

while read nombre; do
    porcentaje=$(df --output=pcent $nombre | tail -n +2 | sed 's/^  //' | cut -d'%' -f1)
    if [[ "$porcentaje" -gt 7 ]]; then
        echo "Almacenamiento lleno"
    else
        echo "Aun queda espacio"
    fi
done < fichero.txt

rm fichero.txt

