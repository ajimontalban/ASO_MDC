#!/bin/bash

# Comprueba si existe una carpeta donde guardar los logs y si no existe la crea
if [[ -d /tmp/backup ]];then
    rm -r /tmp/backup
fi

mkdir /tmp/backup

# Si los argumentos los paso por consola, los guardo en el array rutas
if [[ $# -gt 0 ]];then
    RUTAS=("$@")
# El archivo $SOURCES sera el que cargará systemd para saber que servicios controlar
elif [[ -n $SOURCES ]];then
    read -a RUTAS <<< "$SOURCES"
else
    echo "Debes indicar al menos un servicio al que realizar el seguimiento de los logs"
    exit 1
fi


# Selecciona los logs de las ultimas 24 horas del servicio de almacenamiento que creamos en el 
# ejercicio 1 y los almacena en la carpeta mencionada antes. El almacenamiento cuenta con fecha y hora, 
# la intencion es ejecutar el script cada 23 horas y si no se ha podido ejecutar por estar el equipo apagado
# que se ejecute al encender el equipo

# Recorre el array y crea un archivo .log por cada servicio seleccionado
for elem in "${RUTAS[@]}";do
    journalctl -u "${elem}".service -S "-12h" > /tmp/backup/"${elem}"-$(date +%Y%m%d-%H%M).log
done

# Comprueba que la carpeta no esté vacia, si lo está borra directamente la carpeta
if [[ "$(find "/tmp/backup" -maxdepth 0 -type d -empty)" == "/tmp/backup" ]]; then
    echo "No existen archivos a los que hacer una copia"
    rmdir /tmp/backup
else
    # Creamos una variable ruta para usarla varias veces y hacemos agrupacion y 
    # compresion de todos los archivos dentro de la carpeta /tmp/backup
    ruta="/tmp/backup_$(date +'%Y%m%d%H%M')"
    tar -czf "${ruta}".tar.gz /tmp/backup/* 2&> /dev/null

    scp -i ~/.ssh/backup_proxmox "${ruta}".tar.gz asir@10.255.212.8:backup_logs/

    if [[ $? -ne 0 ]];then
        echo "No se ha podido completar el copiado de los logs \"${ruta}\".tar.gz"
        exit 2
    else
        rm -r /tmp/backup
    fi

    # Es un contador
    lista_archivos=$(ssh -q -i ~/.ssh/backup_proxmox asir@10.255.212.8 ls -1 backup  | wc -l)
    # Comprueba si existen mas de 30 archivos en remoto
    while [[ $lista_archivos -gt 30 ]];do
        # Guarda el nombre del archivo en una variable y elimina el archivo con ese nombre
        archivo_viejo=$(ssh -q -i ~/.ssh/backup_proxmox asir@10.255.212.8 ls -1 backup  | head -1)
        echo "Eliminando $archivo_viejo"
        ssh -q -i ~/.ssh/backup_proxmox asir@10.255.212.8 rm backup/"$archivo_viejo"

        # Reduce el contador lista_archivos por cada archivo eliminado
        lista_archivos=$((lista_archivos - 1))
    done
fi


 

