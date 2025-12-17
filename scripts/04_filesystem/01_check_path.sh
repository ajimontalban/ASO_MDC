#!/bin/bash 

# Lee una ruta introducida por el usuario
read -p "Introduce una ruta: " RUTA

# Comprobación de si existe la ruta mediante la flag -e
if [[ ! -e "$RUTA" ]];then
    echo "La ruta introducida no existe"
    exit 1

# Comprueba si el elemento pasado en la ruta es de tipo fichero
elif [[ -f "$RUTA" ]];then
    echo "Es un archivo regular"

# Comprueba si el elemento pasado en la ruta es de tipo directorio
elif [[ -d "$RUTA" ]];then
    echo "Es un directorio"

else
    echo "El elemento no es ni un fichero ni un directorio"
fi

