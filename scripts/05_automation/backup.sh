#!/bin/bash
# Si existe la carpeta temporal anterior, eleminala para crear una nueva
if [[ -d /tmp/backup ]];then
    rm -r /tmp/backup
fi

mkdir /tmp/backup

#Comprueba si se han introducido argumentos de entrada
#if [[ $# -eq 0 ]];then
#    echo "Debes indircar al menos un fichero o directorio"
#    exit 1
#fi

# Cambios realizados para poder usar systemd
# Si recibe argumentos, los argumentos son guardados en un array
if [[ $# -gt 0 ]];then
    RUTAS=("$@")

# Comprueba que $SOURCES no está vacía
elif [[ -n $SOURCES ]];then
    # Lee el contenido de sources y read asigna los valores en un array usando IFS por defecto para separarlo en distintos elementos
    read -a RUTAS <<< "$SOURCES"
else
    echo "Debes pasar al menos un fichero o directorio, o bien especificar las rutas en /etc/backup/backup.conf"
    exit 1
fi

# Bucle que itera por las rutas pasadas como argumentos
#for arg in "$@"; do
for arg in "${RUTAS[@]}"; do
    # Comprueba si existe la ruta dada. Si no existe, manda mensaje por stderr y pasa a la siguiente ruta
    if [[ ! -e $arg ]];then
        echo "Error en la ruta \"$arg\": No existe el fichero o directorio" >&2
        echo "Ignorando \"$arg\"" >&2
        continue

    # Si es un directorio, primero agrupa en un archivo temporal .tar los archivos
    elif [[ -d "$arg" ]];then
        tar -cf  /tmp/backup/$(basename "$arg").tar "$arg"  2&> /dev/null
        # Comprimimos el .tar
        zstd "/tmp/backup/$(basename "$arg").tar" -o /tmp/backup/$(basename "$arg").tar.zst
        # Eliminamos el .tar original una vez ya hemos comprimido
        rm "/tmp/backup/$(basename "$arg").tar"

    else
        # Comprime los archivos
        zstd "$arg" -o /tmp/backup/$(basename "$arg").zst
    fi

done

# Comprueba que la carpeta no esté vacía
if [[ "$(find "/tmp/backup" -maxdepth 0 -type d -empty)" == "/tmp/backup" ]];then
    echo "No existen archivos a los que hacer una copia"
    rmdir /tmp/backup
else
    # Genera un .tar de todos los archivos comprimidos, con nombre de la maquina y fecha
    ruta="/tmp/backup_$(hostname)_$(date +'%Y%m%d%H%M')"
    tar cf "${ruta}".tar /tmp/backup/* 2&> /dev/null

    # Envia mediante scp el archivo .tar. Usa una clave ssh
    scp -i "$HOME"/.ssh/backup_proxmox "${ruta}".tar asir@10.255.212.8:backup/

    # Si el comando scp ha salido con codigo distinto de 0, envia mensaje y no borra la carpeta backup
    if [[ $? -ne 0 ]];then
        echo "No se ha podido completar el copiado del archivo \"${ruta}\".tar"
        exit 2
    else
        rm -r /tmp/backup
    fi

    lista_archivos=$(ssh -q -i ~/.ssh/backup_proxmox asir@10.255.212.8 ls -1 backup  | wc -l)
    
    # Comprueba si existen mas de 10 archivos en remoto
    while [[ $lista_archivos -gt 10 ]];do
        # Guarda el nombre del archivo en una variable y elimina el archivo con ese nombre
        archivo_viejo=$(ssh -q -i ~/.ssh/backup_proxmox asir@10.255.212.8 ls -1 backup  | head -1)
        echo "Eliminando $archivo_viejo"
        ssh -q -i ~/.ssh/backup_proxmox asir@10.255.212.8 rm backup/"$archivo_viejo"

        # Reduce el contador lista_archivos por cada archivo eliminado
        lista_archivos=$((lista_archivos - 1))
    done
fi
