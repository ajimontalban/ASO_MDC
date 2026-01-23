# Proyecto de evaluación
## Ejercicio 1
Para este ejercicio la primera idea que tuve fue la de contactar con la cuenta  de root mediante el `mail` que ya viene incluido en el sistema. Como eso era secundario, comencé a tratar de sacar mediante el comando `df` el espacio disponible que quedaba en los discos. 

Para el comando `df` he usado los flags `-x` que se usa para excluir los sistemas de ficheros que indiques después. He usado `--output` y las opciones `source` y `target`para que solo me muestre el nombre que usa el sistema y donde va montado. Al principio solo pensaba usar el nombre pero existen sistemas como carpetas compartidas de VirtualBox que no se encuentran por nombre, por lo que la búsqueda la he hecho por punto de montaje. 

Luego, mediante un bucle saco el porcentaje y compruebo que sea menor al 90% ya que considero que puede ser problemático un disco con menos capacidad. Como la notificación por mail me daba muchos problemas, cambie de MTA de EXIM4 a POSTFIX y eso ya solucionaba gran parte, pero consideré que sería mejor descartar la opción de mail y usar notificaciones en el móvil. Conecté un bot para tener un chat al que enviarle los mensajes de los discos que estén por encima del umbral que he elegido.

Para conectar con el bot de Telegram, lo que hice fue obtener un bot y que te proporcionen su `TOKEN` y por otra parte obtener mi `ID` de usuario. Metí los dos valores en un archivo `.env` y añadí un `.gitignore` para que no haga seguimiento de ese fichero. Una vez hecho esto, le pasamos todas las variables necesarias a la **API** de Telegram con el comando `curl`, pasando tanto el método que queremos que use (POST) como los datos que serian el `ID` de usuario y el mensaje que queremos que envíe. Lo ultimo que hacemos es borrar los ficheros temporales que creamos durante la ejecución.
![Systemd ejercicio1](media/SituacionEjercicio1Systemd.png)
Los mensajes están programados para enviarse solo en caso de superar cierto umbral y la comprobación del disco la tengo programada para realizarla cada hora ya que considero un intervalo suficiente sin llegar a ser excesivo.
![Bot Telegram](media/BotTelegram.png)
### Código y archivos usados
Hemos elegido `Unit files` de **Systemd** aunque para este caso concreto con **Crontab** es posible hacerlo sin demasiada complicación.

==ejercicio1.sh==
```bash
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
   porcentaje=$(df --output=pcent $montaje | tail -n +2 | sed 's/^  //' | cut -d'%' -f1)  
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
```

==ejercicio1.service==
```bash
[Unit]  
Description=Ejecuta un script que comprueba el almacenamiento de los discos  
  
[Service]  
Type=oneshot  
ExecStart=/usr/local/bin/ejercicio1.sh  
User=1000
Group=1000  
  
[Install]  
WantedBy=multi-user.target
```

Para este servicio vamos a ejecutarlo como el usuario 1000 y lo importante es que los permisos de los scripts correspondan con lo indicado aquí, el usuario debe ser dueño del `.sh`a ejecutar. Indicamos donde se encuentra el **script** y cuando se puede ejecutar (multi-user.target). 


==ejercicio1.timer==
```bash
[Unit]  
Description=Timer para ejecutar ejercicio1.service  
  
[Timer]  
OnCalendar=*:00    
Unit=ejercicio1.service  
  
[Install]  
WantedBy=timers.target
```

Seleccionamos que queremos que se ejecute cada hora y que unidad queremos ejecutar.  Usamos `WantedBy=timers.target`para poder activar el timer al iniciar el sistema con `sudo systemctl enable ejercicio1.timer`.

Realmente sería posible en lugar de usar un archivo `.env`, usar un archivo que lo cargue systemd mediante la variable `EnvironmentFile`, indicando donde se encuentran esas variables. 

==.env==
```bash
TOKEN="TOKENID"
ID="USERID"
```

## Ejercicio 2
El ejercicio 2 es realmente sencillo aunque puede que tengamos que dar unos permisos especiales. La carpeta `/tmp`puede ser escrita por cualquier usuario, por lo que puede contener archivos de root y que no tengamos los permisos necesarios. Como lo que se pide es simple, no vamos a usar un script sino que lo ejecutaremos directamente desde el Unit File como un solo comando.

### Código
==ejercicio2.service==
```bash
[Unit]  
Description=Elimina el contenido de la carpeta `/tmp`    
  
[Service]  
Type=oneshot  
ExecStart=/bin/bash -c 'rm -rf /tmp/*'
; ExecStart=/usr/local/bin/ejercicio2.sh  
Persistant=true  
User=root  
Group=root  
  
[Install]  
WantedBy=multi-user.target
```

En este servicio lo que indicamos es que realice el comando `/bin/bash -c 'rm -rf /tmp/*'` para borrar el contenido de la carpeta. Como vemos en el código, está la opción comentada de realizar esto mediante un script pero para este caso no lo veo necesario. Esto como ya hemos indicado antes lo hacemos con permisos de root y además añadimos `Persistant=true` ya que si queremos que se ejecute cada ciertos días, pero no se puede ejecutar debido a que el sistema se encuentre apagado, la acción no se realizaría.

==ejercicio2.timer==
```bash
[Unit]  
Description=Timer para ejecutar ejercicio2.service  
  
[Timer]  
; Cada siete dias a las 00:00, todos los meses    
OnCalendar=*-*/7 00:00  
Unit=ejercicio2.service  
  
[Install]  
WantedBy=timers.target
```

Para este timer, lo que he elegido es que la acción se realice cada 7 días ya que me parece un tiempo suficiente para poder ir eliminando la información acumulada.

## Ejercicio 3 
Para el ejercicio 3, lo que he elegido es que podamos indicar a que servicios queremos que haga el seguimiento de logs, ya sea como argumentos de entrada del script o como un archivo que le pasamos a systemd con los argumentos metidos en una variable `$SOURCES`que separa los elementos por un espacio. podemos usar otro separador e indicarlo en el script. Una vez indicados los servicios a los que hacer seguimiento, para nuestro ejemplo vamos a usar el servicio del ejercicio 1 y `httpd`, generamos un archivo .log mediante el acceso a los logs de `journalctl`, indicando el servicio concreto con `-u`. El archivo lo guardamos con el nombre del servicio y la fecha en la que ha sido guardado. 

Lo siguiente que hacemos es comprobar que la carpeta en la que guardamos los logs no esté vacía debido a un error en el acceso a los logs mediante `journalctl` y si todo está correcto generamos un archivo `.tar.gz` (comprimido con `gzip` y agrupado con `tar`). El archivo generado cuenta con la fecha de creación del archivo. 

Después lo que hacemos es enviar al servidor remoto mediante `scp` el contenido generado y lo guardamos en la carpeta backup_logs del servidor.

Lo ultimo que hacemos es comprobar la rotación en el servidor con un bucle y un contador, el cuál debe ser menor de 30 en nuestro caso.

![logs](media/logs.png)
### Código
==ejercicio3.sh==
```bash
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
# la intencion es que si no se ha podido ejecutar por estar el equipo apagado  
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
   lista_archivos=$(ssh -q -i ~/.ssh/backup_proxmox asir@10.255.212.8 ls -1 backup  | wc -l)  
   # Comprueba si existen mas de 30 archivos en remoto  
   while [[ $lista_archivos -gt 30 ]];do  
       # Guarda el nombre del archivo en una variable y elimina el archivo con ese nombre  
       archivo_viejo=$(ssh -q -i ~/.ssh/backup_proxmox asir@10.255.212.8 ls -1 backup  | head -1)  
       echo "Eliminando $archivo_viejo"  
       ssh -q -i ~/.ssh/backup_proxmox asir@10.255.212.8 rm backup/"$archivo_viejo"  
  
       # Reduce el contador lista_archivos por cada archivo eliminado  
       lista_archivos=$((lista_archivos - 1))  
   done  
fi
```
==ejercicio3.service==
```bash
[Unit]  
Description=Ejecuta un script que almacena los logs en una maquina remota y genera rotación  
After=ejercicio1.service  
  
[Service]  
Type=oneshot  
EnvironmentFile=/etc/ejercicio3.conf  
ExecStart=/usr/local/bin/ejercicio3.sh  
User=1000  
Group=1000  
  
[Install]  
WantedBy=multi-user.target
```

Uso `After=`ya que se ejecutan los dos servicios con la misma frecuencia y quiero que se guarden los últimos logs generados por el ejercicio 1. El servicio es ejecutado con los permisos de usuario ya que no es necesario escalar privilegios para lo que realiza este script.

==ejercicio3.timer==
```bash
[Unit]  
Description=Timer para ejecutar ejercicio3.service  
  
[Timer]  
OnCalendar=*:00    
Persistent=true  
Unit=ejercicio3.service  
  
[Install]  
WantedBy=timers.target
```

Para el timer uso prácticamente el mismo que para el ejercicio 1.

==ejercicio3.conf==
```bash
SOURCES="ejercicio1 httpd"
```

De esta manera puedo elegir a que servicios hacerle el seguimiento de los logs.

## Ejercicio 4
Para realizar el ejercicio 4, la opción elegida ha sido usar el comando `rsync` ya que es una herramienta propia del sistema, muy potente y que realiza lo que buscamos sin necesidad de unir varios comandos. La otra opción que habría usado si no hubiese estado rsync habría sido el comando `find` con la opción que comprueba el tiempo desde la última vez modificado. 

Lo primero que hacemos es comprobar si los datos han sido introducidos mediante argumentos o mediante el archivo ejercicio4.conf en service. De cualquiera de las dos maneras, se guardan en las variables `directorio_backup` (origen) y `directorio_destino`. La manera desde `SOURCES` es usando el _Here String_ `<<<` que redirecciona a read el contenido del string dentro de la variable. En el código se omite `IFS=' '`.  Una vez asignados a variables, comprobamos que las rutas pasadas existen y que son directorios ambos. Si esto es correcto pasamos a ejecutar `rsync`.

El comando `rsync` nos permite copiar contenido de una carpeta a otra, realizando copias incrementales de los archivos que han sido modificados dentro de la carpeta origen con diferencia de la carpeta destino. Usamos las flags `-a`que indica el modo de copiado equivalente a escribir `-rlptgoD`(`-r: Recursivo`,`-l:Links`,`-p;permisos`,`-t: Times o modificacion`, `-g:grupos`,`-o:Owner`,`-D:Devices`). La flag `v` no es necesaria aunque lo guarda en `journalctl` por lo que la he dejado, la flag `-z` sirve para comprimir durante la transmisión pero no en la carpeta destino y la flag `-u` sirve como `--update` que es lo que hace que este copiado sea incremental.

### Código

==ejercicio4.sh==
```bash
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
   rsync -avzu --exclude '*.swp' --exclude '*.bak' --exclude '*.tmp' ${directorio_bac  
kup}/* ${directorio_destino}    
fi
```

==ejercicio4.service==
```bash
[Unit]  
Description=Ejecuta un script que guarda los archivos que han sido modificados previam  
ente en una carpeta concreta  
  
[Service]  
Type=oneshot  
ExecStart=/usr/local/bin/ejercicio4.sh  
EnvironmentFile=/etc/ejercicio4.conf  
User=1000  
Group=1000  
  
[Install]  
WantedBy=multi-user.target
```

Ejecuta con permisos de usuario normal.

==ejercicio4.timer==
```bash
[Unit]  
Description=Timer para ejecutar ejercicio4.service  
  
[Timer]  
OnCalendar=*:*    
Unit=ejercicio4.service  
Persistent=true  
  
[Install]  
WantedBy=timers.target
```
El temporizador comprueba cambios cada minuto y si no hay cambios no hace nada.

==ejercicio4.conf==
```bash
SOURCES="ejercicio1 httpd"
```