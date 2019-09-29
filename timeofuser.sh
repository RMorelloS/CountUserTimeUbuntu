#!/bin/bash

########
  #
  # This script is used to calculate the time a user spent logged in to ubuntu. 
  # Usage: ./timeofuser.sh [-u <user-name> -f <file-name>] [-h]
  # Created and mainteined by Ricardo Morello Santos <ricardo_morello@hotmail.com>
  #
########
########variables auxiliares########
NOMBRE_USUARIO=''
NOMBRE_ARCHIVO=''
##arreglo declarativo para mapear el usuario a la cantidad de minutos
declare -A array_users_time
#variables para calcular la cantidad de minutos de cada usuario
NO_PARENTESIS=''
USER=''
USER_TIME_IN_MINUTES=0
USER_IN_ARRAY=''
NEW_USER_HOURS=0
NEW_USER_MINUTES=0
NEW_USER_DAYS=0
OLD_USER_MINUTES=0
OLD_USER_HOURS=0
OLD_USER_DAYS=0
######fin variables auxiliares######

########funciones##########
#presentar la forma de uso del programa
function print_usage {
  echo 'Programa para calcular la cantidad de tiempo que un usuario (o grupo de usuarios) permanecio conectado a la maquina'
  echo 'banderas:'
  echo '-h: presentar ayuda'
  echo '-u: nombre del usuario'
  echo '-f: nombre del archivo con los registros de conexion'
  
}
#presentar el arreglo completo de usuarios y sus respectivos tiempos
function print_array {
    echo "USUARIO      |   TIEMPO"
    #para cada clave en el dicionario de usuarios con sus tiempos
    for KEY in "${!array_users_time[@]}"; do
        #total de minutos que el usuario paso conectado 
        MINUTES_SPENT_ON=${array_users_time[$KEY]}
        #total de dias
        TOTAL_DAYS=$((10#$MINUTES_SPENT_ON/1440))
        #total de horas
        TOTAL_HOURS=$(((10#$MINUTES_SPENT_ON%10#1440)/10#60))
        #cantidad final de minutos descontados los dias y horas
        TOTAL_MINUTES=$(((10#$MINUTES_SPENT_ON%10#1440)%10#60))
        #tamano del nombre del usuario para formatar la salida
        KEY_LENGTH=${#KEY} 
        #seran impresos espacios en blanco para formatar la presentacion al usuario
        COUNT=$((10#13-10#$KEY_LENGTH))
        #imprimindo el nombre del usuario
        printf "$KEY"
        #imprimir espacios en blanco en la pantalla para formatar la salida
        for i in `seq 1 $COUNT`
        do
            printf " "
        done
        #imprime un pipe de separacion del nombre del usuario a su tiempo en la pantalla
        printf "|"
        #imprime espacios en blanco para formatar el tiempo 
        for i in `seq 1 3`
        do
            printf " "
        done
        #imprime el tiempo
        printf "$TOTAL_DAYS:$TOTAL_HOURS:$TOTAL_MINUTES\n"
    done
}
#presentar solo uno usuario - la logica es la misma a la funcion de arriba
function print_user {
    echo "USUARIO      |   TIEMPO"
    MINUTES_SPENT_ON=${array_users_time[$NOMBRE_USUARIO]}  
    TOTAL_DAYS=$((10#$MINUTES_SPENT_ON/1440))
    TOTAL_HOURS=$(((10#$MINUTES_SPENT_ON%10#1440)/10#60))
    TOTAL_MINUTES=$(((10#$MINUTES_SPENT_ON%10#1440)%10#60))
    KEY_LENGTH=${#NOMBRE_USUARIO} 
    COUNT=$((10#13-10#$KEY_LENGTH))
    printf "$NOMBRE_USUARIO"
    for i in `seq 1 $COUNT`
    do
        printf " "
    done
    printf "|"
    for i in `seq 1 3`
    do
        printf " "
    done
    printf "$TOTAL_DAYS:$TOTAL_HOURS:$TOTAL_MINUTES\n"
}
#ler el archivo y interpretar cada linea
function read_file {
    #para cada linea del archivo
    while IFS= read -r line
    do
        #se a linea contiene un parenteses, esto quiere decir que tiene un tiempo asociado
        if [[ $line == *"("* ]]; then
            #separando el tiempo de la linea y almacenando en la variable NO_PARENTESIS
            #asi, la variable tera los tiempos en formato string en HH:MM
            #por ejemplo, 00:52
            NO_PARENTESIS=$(echo $line | cut -d '(' -f 2 | cut -d ')' -f 1)
            #separando el nombre del usuario
            USER=$(echo $line | cut -d ' ' -f 1)
            #variable para almacenar el tiempo que el usuario estuvo conectado hasta la liena $line
            USER_IN_ARRAY=${array_users_time[$USER]}
            #si el usuario no existe en el dicionario
           if [ -z "$USER_IN_ARRAY" ] 
           then
               #se el tiempo tiene un "+", esto quiere decir que hay dias tambien en la linea $line
               #por ejemplo, 1+02:52 quiere decir que el usuario estuvo conectado por 1 dia, 2 horas y 52 minutos
               if [[ $NO_PARENTESIS == *"+"* ]]; then
                   #capturando el dia 
                   NEW_USER_DAYS=$(echo $NO_PARENTESIS | cut -d '+' -f 1)
                   #variable que almacena las horas y los minutos, quitando los dias
                   #1+02:51 se cambiara en 02:51 en la variable TEMP_HOURS_MINUTES
                   TEMP_HOURS_MINUTES=$(echo $NO_PARENTESIS | cut -d '+' -f 2)
                   #separando la cantidad de horas para el nuevo usuario del dicionario
                   NEW_USER_HOURS=$(echo $TEMP_HOURS_MINUTES | cut -d ':' -f1)
                   #separando los minutos
                   NEW_USER_MINUTES=$(echo $TEMP_HOURS_MINUTES | cut -d ':' -f2)
                   #calculando el tiempo en minutos que el usuario estuvo conectado
                   #el tiempo total sera almacenado en minutos
                   array_users_time[$USER]=$((10#$NEW_USER_MINUTES+10#$NEW_USER_HOURS*60+10#$NEW_USER_DAYS*1440))
               else
                   #si no hay informacion de dias en la linea $line, solo captura las horas y los minutos y almacena
                   #en el dicionario
                   NEW_USER_MINUTES=$(echo $NO_PARENTESIS | cut -d ':' -f2)
                   NEW_USER_HOURS=$(echo $NO_PARENTESIS | cut -d ':' -f1)
                   array_users_time[$USER]=$((10#$NEW_USER_MINUTES+10#$NEW_USER_HOURS*60))
               fi
           else
                #si ya existe un usuario, se realiza el mismo proceso, pero agregando la cantidad ya almacenada de minutos
                OLD_USER_MINUTES=${array_users_time[$USER]}
                if [[ $NO_PARENTESIS == *"+"* ]]; then
                    OLD_USER_DAYS=$(echo $NO_PARENTESIS | cut -d '+' -f 1)
                    TEMP_HOURS_MINUTES=$(echo $NO_PARENTESIS | cut -d '+' -f 2)
                    OLD_USER_HOURS=$(echo $TEMP_HOURS_MINUTES | cut -d ':' -f1)
                    MINUTES=$(echo $TEMP_HOURS_MINUTES | cut -d ':' -f2)
                    array_users_time[$USER]=$((10#$MINUTES+10#$OLD_USER_HOURS*60+10#$OLD_USER_DAYS*1440+10#$OLD_USER_MINUTES))
                else
                    MINUTES=$(echo $NO_PARENTESIS | cut -d ':' -f2)
                    OLD_USER_MINUTES=$((10#$OLD_USER_MINUTES+10#$MINUTES))
                    OLD_USER_HOURS=$(echo $NO_PARENTESIS | cut -d ':' -f1)
                    OLD_USER_MINUTES=$((10#$OLD_USER_MINUTES+10#$OLD_USER_HOURS*60))
                    array_users_time[$USER]=$OLD_USER_MINUTES
                fi
           fi
 
        fi
    done < $NOMBRE_ARCHIVO
}
#capturando las banderas del usuario y verificando las entradas
PRINT_ONE_USER=false
if [[ "$#" -eq 1 || "$#" -eq 0 ]]; then
    echo "Error:"
    echo "Verifique el numero de argumentos y las banderas"
    print_usage
    exit 2
fi
while getopts u:f:h opcion; do
    case $opcion in
          h)
              print_usage
              ;;
          u)
              NOMBRE_USUARIO=${OPTARG} 
              PRINT_ONE_USER=true
              ;;
          f)
              NOMBRE_ARCHIVO=${OPTARG} 
              ;;
          :)
              echo "Error:"
              echo 'Ingrese los parametros requeridos en las banderas'
              exit 2
              ;;
    esac
done  
if [[ -n "$NOMBRE_USUARIO" && -z "$NOMBRE_ARCHIVO" ]]
then
    echo "Error:"
    echo "No se puede ingresar solo el nombre del usuario!"
    exit 2
fi

read_file
#si solo se debe imprimir uno usuario o todo el arreglo
if $PRINT_ONE_USER; then
    print_user
else   
    print_array 
fi
exit 0
