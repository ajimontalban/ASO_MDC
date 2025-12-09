#!/bin/bash

if [[ -d /tmp/backup ]];then
    rm -r /tmp/backup
fi

mkdir /tmp/backup

if [[ $# -eq 0 ]];then
    echo "Debes indircar al menos un fichero o directorio"
    exit 1
fi

for arg in "$@"; do
    if [[ ! -e $arg ]];then
        echo "Error en la ruta \"$arg\": No existe el fichero o directorio" >&2
        echo "Ignorando \"$arg\"" >&2
        continue
    elif [[ -d "$arg" ]];then
        tar -cf  /tmp/backup/$(basename "$arg").tar "$arg"  2&> /dev/null
        zstd "/tmp/backup/$(basename "$arg").tar" -o /tmp/backup/$(basename "$arg").tar.zst
        rm "/tmp/backup/$(basename "$arg").tar"

    else
        zstd "$arg" -o /tmp/backup/$(basename "$arg").zst
    fi

done

if find "/tmp/backup" -maxdepth 0 -type d -empty &>/dev/null;then
    echo "No existen archivos a los que hacer una copia"
    rmdir /tmp/backup
else
    ruta="/tmp/backup_$(hostname)_$(date +'%Y%m%d%H%M')"
    tar cf "${ruta}".tar /tmp/backup/* 2&> /dev/null

    scp -i "$HOME"/.ssh/backup_proxmox "${ruta}".tar asir@10.255.212.8:backup/

    if [[ $? -ne 0 ]];then
        echo "No se ha podido completar el copiado del archivo \"${ruta}\".tar"
        exit 2
    else
        rm -r /tmp/backup
    fi

    lista_archivos=$(ssh -q -i ~/.ssh/backup_proxmox asir@10.255.212.8 ls -1 backup  | wc -l)
    echo "$lista_archivos"
    while [[ $lista_archivos -gt 10 ]];do
        archivo_viejo=$(ssh -q -i ~/.ssh/backup_proxmox asir@10.255.212.8 ls -1 backup  | head -1)
        echo "Eliminando $archivo_viejo"
        ssh -q -i ~/.ssh/backup_proxmox asir@10.255.212.8 rm backup/"$archivo_viejo"
        lista_archivos=$((lista_archivos - 1))
    done
fi
