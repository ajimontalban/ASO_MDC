#!/bin/bash

# Pasamos el archivo con las variables de entorno $TOKEN y $ID
source /usr/local/bin/.env

# almacena los discos que estan en el sistema en un fichero 
df -x tmpfs -x devtmpfs --output=source,target | tail -n +2 | sed 's/ \//,\//' > fichero.txt

# lee del fichero los nombres de los discos y comprueba 
# el porcentaje del disco usado. Por cada disco que 
# supere el 90% de capacidad lleno enviara un mensaje al 
# administrador del sistema medinte el comando mail.
while IFS=',' read nombre montaje; do
    porcentaje=$(df --output=pcent $montaje | tail -n +2 | sed 's/^  //' | cut -d'%' -f1)
    if [[ "$porcentaje" -gt 90 ]]; then
        echo "El disco $nombre se encuentra por encima del 90% de su almacenamiento." >> mensaje.txt
    fi
done < fichero.txt

# Comprueba que el fichero mensaje.txt existe y que su tamaño es mayor a 0 bytes
if [[ (-f mensaje.txt) && (-s mensaje.txt) ]];then
    # El contenido del archivo mensaje.txt es guardado en una variable para
    # notificar mediante telegram al administrador.
    MENSAJE=$(cat mensaje.txt) 
    # Usamos la URL de la api de telegram indicando el bot a usar y que debemos
    # mandarle un mensaje
    URL="https://api.telegram.org/bot$TOKEN/sendMessage"
    # Usamos curl para indicar que mensaje enviar y hacia donde
    # Redirigimos la salida standar para que no aparezca la informacion por 
    # la terminal pero permitimos que los errores si aparezcan 
    # Las flags son -s `silent` -X `metodo` y -d `datos`
    curl -s -X POST $URL -d chat_id="$ID" -d text="$MENSAJE" > /dev/null 

    rm mensaje.txt
fi

rm fichero.txt

