#!/bin/bash

# Pide al usuario un archivo o ruta al mismo
read -p "Introduce un archivo: " ARCHIVO

# Comprueba si el archivo existe y es un fichero, si no cumple alguna de estas
# condiciones, se sale de script
if [[ ! -e "$ARCHIVO" || !  -f "$ARCHIVO" ]];then
    echo "Debes introducir un archivo existente"
    exit 1
fi

# Guarda en una variable el nombre que tomará el nuevo archivo al copiarlo
ARCHIVO2=${ARCHIVO}-$(date +%Y%m%d).bak

# Si no existe ningun archivo con ese nombre lo copia
if [[ ! -e "$ARCHIVO2" ]];then
    cp "$ARCHIVO" "$ARCHIVO2"
    if [[ $? == 0 ]];then
        echo "El archivo $ARCHIVO2 se ha podido crear"
    else
        echo "El archivo $ARCHIVO2 no se ha podido crear"
    fi
# Si ya existe el archivo para esa fecha, no lo copia
else 
    echo "El archivo $ARCHIVO2 ya existe"
fi
