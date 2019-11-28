##### Constante
ON=0  # Online
OFF=0 # Offline
SORTT=0 # Ordenado por tiempo consumido de CPU
SORTD=0 # Ordenado por tiempo ejecucion de proceso
U=0   # UID ordenada
R=0   # R Reverse
K=0   # K Kill
N=    # Numero procesos máximo 
ERROR=0 # Error
REG='^[0-9]+$' # Numero positivo entero
##### Funciones
opciones() {
##### Flags
for i in $@; do
  if [ "$N" = "-1" ]; then 
    if [[ "$i" =~ "$REG" ]]; then
      N=$i
    else
      echo Error despues de -K debe de haber un numero entero positivo
      exit 1
    fi
  elif [ "$i" = "-ON" ]; then
    ON=1
  elif [ "$i" = "-OFF" ]; then
    OFF=1
  elif [ "$i" = "-sortt" ]; then
    SORTT=1
  elif [ "$i" = "-sortd" ]; then
    SORTD=1
  elif [ "$i" = "-U" ]; then
    U=1
  elif [ "$i" = "-R" ]; then
    R=1
  elif [ "$i" = "-K" ]; then
    K=1
    N=-1 # Cuando N esta igual a -1 esta esperando a que el siguiente valor sea un numero (Simular comportamiento de los comandos de bash)
  else 
    echo La opcion $i no esta permitida
    exit 1
  fi
done

# echo Flags: #
# echo ON $ON #
# echo OFF $OFF #  
# echo U $U  #
# echo R $R  #
# echo K $K  #
# echo N $N  #
# echo SORTT $SORTT  #
# echo SORTD $SORTD  #
##### Control de errores
if [[ "$ON" = "1" && "$OFF" = "1" ]];then 
  ON=0
  OFF=0
fi
if [[ ("$U" = 1 && ("$SORTD" = "1" || "$SORTT" = "1")) || ("$SORTD" = 1 && "$SORTT" = "1") ]];then 
  echo Demasiadas opciones de ordenacion eliga entre -U -sortt o -sortd
  exit 1
fi
listado_usuarios 
}
##### Imprimir
mostrar() {
  # Usuario
  printf "%-19s" $i
  # UID
  printf "%-19i" $(id $i | cut -d '=' -f2 | cut -d '(' -f1) 
  # GID
  printf "%-19i" $(id $i | cut -d '=' -f3 | cut -d '(' -f1)
  # Nombre, consumo y tiempo del proceso que mas CPU consume
  printf "%-19s" $(ps -Ao user,fname,pcpu,time --sort pcpu | uniq | grep ^$i | tail -n1 | 
                    awk '{$1=""; print $0}')
  # Nombre y tiempo del proceso que mas tiempo de ejecución tenga
  printf "%-19s" $(ps -Ao user,fname,etime |  grep ^$i | head -n1 | awk '{$1=""; print $0}')
  # Numero total de archivos
  printf "%-19i" $(lsof -u $i | wc -l)
  # Numero de procesos del usuario
  printf "%-19i" $(ps -Ao user,cmd | grep ^$i | wc -l)
  printf "\n"
}

listado_usuarios() {

sort=user
reverse=cat
if [ "$U" = "1" ]; then
  echo Por uid
  sort=uid
elif [ "$SORTT" = "1" ]; then
  sort=time
  echo Por time sortt tiempo CPU
elif [ "$SORTD" = "1" ]; then
  sort=etime
  echo Por time sortd tiempo proceso
fi
if [ "$R" = "1" ];then
  reverse=tac
fi
  declare -a usuarios=($(ps -Ao user --sort=$sort | sed -n '1!p' | uniq | "$reverse")) 

##### Simulo que mato los procesos
if [ "$K" = "1" ]; then
  for i in "${usuarios[@]}"; do
    procesos_de_usuario=($(ps -Ao user,fname | grep ^$i | awk '{print $2}'))
    for i in ${procesos_de_usuario[@]}; do
      if [ "$(lsof -c $i | wc -l)" -gt "$N" ]; then
        echo Kill $i \(Numero de ficheros $(lsof -c $i | wc -l)\)
      fi
    done 
  done 
fi

printf "%-19s" USER UID GID PROCESOCPU %CPU Tiempo_CPU Proceso_tiempo tiempo_proceso Archivos_abiertos Numero_de_procesos  
printf "\n"

### http://www.linfo.org/uid.html ###
# Also, it can be convenient to reserve a block of UIDs for local users, such as 1000 through 9999, and another block for remote users (i.e., users elsewhere on the network), such as 10000 to 65534. 
#####################################
for i in "${usuarios[@]}"; do
  UID_user=$(id $i | cut -d '=' -f2 | cut -d '(' -f1)
  # usuarios locales
  if [[ "$ON" = "1" && ("$UID_user" -ge 1000 && "$UID_user" -le 65534) ]]; then # 1000 <= user <= 9999 (usuarios locales) or # 10000 <= user <= 65534 (usuarios remotos)
    mostrar $i
  # usuarios generados por el sistema
  elif [[ "$OFF" = "1" && ("$UID_user" -lt 1000 || "$UID_user" -gt 65534) ]]; then # user < 1000 or user > 65534
    mostrar $i
  # Salida por defectos (todos los usuarios)
  elif [[ "$ON" = "0" && "$OFF" = "0" ]]; then 
    mostrar $i
  fi
done

}

##### Programa principal
cat << _EOF_
$(opciones $@)
_EOF_
