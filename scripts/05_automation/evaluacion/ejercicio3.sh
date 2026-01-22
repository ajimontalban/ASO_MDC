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
    journalctl -u "${elem}".service -S "-24h" > /tmp/backup/"${elem}"-$(date +%Y%m%d-%H%M).log
done

# Comprueba que la carpeta no esté vacia, si lo está borra directamente la carpeta
if [[ "$(find "/tmp/backup" -maxdepth 0 -type d -empty)" == "/tmp/backup" ]]; then
    echo "No existen archivos a los que hacer una copia"
    rmdir /tmp/backup
else
    # Creamos una variable ruta para usarla varias veces y hacemos agrupacion y 
    # compresion de todos los archivos dentro de la carpeta /tmp/backup
    ruta="/tmp/backup_$(date +'%Y%m%d%H%M')"
    tar -czf "${ruta}".tar.gz /tmp/backup/* # 2$> /dev/null
fi


 

