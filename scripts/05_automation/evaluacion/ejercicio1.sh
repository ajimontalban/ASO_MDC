#!/bin/bash

# almacena los discos que estan en el sistema en un fichero 
df -x tmpfs -x devtmpfs --output=source | tail -n +2 | tr ' ' '\n' > fichero.txt

# lee del fichero los nombres de los discos y comprueba 
# el porcentaje del disco usado. Por cada disco que 
# supere el 90% de capacidad lleno enviara un mensaje al 
# administrador del sistema medinte el comando mail.
while read nombre; do
    porcentaje=$(df --output=pcent $nombre | tail -n +2 | sed 's/^  //' | cut -d'%' -f1)
    if [[ "$porcentaje" -gt 7 ]]; then
        echo "El disco $nombre se encuentra por encima del 90% de su almacenamiento." >> mensaje.txt
    fi
done < fichero.txt

# Comprueba que el fichero mensaje.txt existe y que su tamaño es mayor a 0 bytes
if [[ (-f mensaje.txt) && (-s mensaje.txt) ]];then
    # llama al archivo y lo redirecciona al cuerpo del mensaje de comando mail, el 
    # cual es enviado al usuario root. La informacion se almacena en /var/mail/root
    cat mensaje.txt | mail -s "Almacenamiento del sistema" hostmaster@localhost
    rm mensaje.txt
fi

rm fichero.txt

