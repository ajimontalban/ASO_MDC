#!/bin/bash

read -p "Por favor, la ruta a un directorio: " DIRECTORIO

if [[ -e "$DIRECTORIO" || -d "$DIRECTORIO" ]];then
    echo "Debes introducir una ruta valida a un directorio"
    exit 1
fi


