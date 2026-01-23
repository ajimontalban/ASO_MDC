#!/bin/bash


source /etc/ejercicio4.conf
if [[ $# -gt 0 ]];then
    directorio_backup="$1"
    directorio_destino="$2"
elif [[ -n $SOURCES ]];then
    read -a DIRECT <<< "$SOURCES"
    directorio_backup=${DIRECT[0]}
    directorio_destino=${DIRECT[1]}
else
    echo "Debes pasar un directorio"
    exit 1
fi

if [[ ! -e $directorio_backup || ! -e $directorio_destino ]];then
    echo "Error en la ruta: No existe alguno de los dos directorios" >&2
    exit 2
elif [[ ! -d $directorio_backup || ! -d $directorio_destino ]];then
    echo "Debes indicar un directorio" >&2 
    exit 3
else 
    rsync -avzu --exclude '*.swp' --exclude '*.bak' --exclude '*.tmp' ${directorio_backup}/* ${directorio_destino} 
fi
    
