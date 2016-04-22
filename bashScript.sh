#!/bin/bash

#>>Script para listar directorio "home"
#>>Guardar la salida en un file
#>>Comprimir el file
#>>Solicitar conectar una USB -> Verificar si Está montada
#>>Guardar el archivo en la USB
#>>Desmontar USB

ofile="outputfile.txt"		# Archivo donde guardaremos toda la información contenida en home
medDir1="mediaDir1.txt"		# Directorio donde almacenaremos la información actual que existe en el directorio /media/ a través del comando "df --output=target"
medDir2="mediaDir2.txt"		# Directorio donde refrescaremos la información contenida en "df --output=target" para verificar si hay algún cambio. En caso verdadero, hemos conectado una USB

#En esta parte, crearemos el archivo "outputfile.txt".
#Haremos una llamada a cd y posteriormente a ls para que, sin importar el directorio en que nos encontremos ejecutando el script, 
#	podamos recuperar la informacion contenida en home. Posteriormente la guardamos en ofile
for f in $( cd && ls); do
	echo "$f" >> ${ofile}
done

#Funcion para eliminar todas las dependencias existentes
function deleteAll {
	rm $medDir2 $medDir1 $ofile $1 $final
}

#Función para comprimir el archivo que le indiquemos como primer argumento.
#Posteriormente, elimina el archivo origen y guarda el nombre del archivo en la varaible "final", que
#	posteriormente será usada para comprobar que ha sido copiado correctamente
function comprimeArchivo {
	#Comprimimos archivo
	tar -czf directorioHome.tar.gz $1
	rm $1
	final=directorioHome.tar.gz
}

#Función para comprobar la existencia del archivo que le indiquemos como primer argumento
function comprobarExistenciaDe {
	if [ -e $1 ]; then
		echo "El archivo" $1 "fue creado con exito."
	else
		echo "El archivo" $1 "no existe"
		deleteAll
	fi
}

#Función para copiar un archivo (primer argumento) a una ruta (segundo argumento) dada.
#Por default, el archivo es el comprimido (final) y la ruta es el USB en cuestión.
function copiarArchivo {
	echo `mv -f $1 $2 `
	if [ -f $2"/"$1 ]; then
		echo "Copiado con exito. Desmontando USB."
		umount $2
		deleteAll
	else
		echo "Error al realizar la copia. Por favor, desmonte su USB y reinicie el script"
		#Eliminamos todos los archivos creados para evitar alguna mezcla de información.
		deleteAll
	fi
}

#Función para comparar dos archivos dados como argumentos en base a la cantidad de líneas que tengan.
#Si detecta un cambio en el tamaño de size2 (segundo argumento passado por parámetro), entonces procedemos a obtener la ruta.
function comprarArchivos {
	local size1
	local size2
	size1=$( cat $1 | wc -l )
	size2=$( cat $2 | wc -l )
	#echo "Tamano1: " $size1
	#echo "Tamano2: " $size2
	while [[ $size2 -eq $size1 ]]; do
		rm $2
		for findingUsbRoute in $( df --output=target ); do
			#echo "Reescribiendo mediaDir2"
			echo "$findingUsbRoute" >> ${medDir2}
		done
		size2=$( cat $2 | wc -l )
		#echo "Tamano1: " $size1
		#echo "Tamano2: " $size2
		echo "Por favor, inserte una memoria USB"
		sleep 1
	done
	#Hemos detectado un cambio en $2.
	for usbRoute in $( df --output=target ); do
		#Reescribiendo mediaDir2 con sólo un valor. Por default, el último. Que será la ruta de la memoria
		echo "$usbRoute" > ${medDir2}
	done
	echo "USB detectada"
}

#Parte principal del programa.
#Creamos los archivos necesarios para trabajar y realizamos las llamadas a las funciones pernitentes.
if [ -e $ofile ]; then
	echo "Archivo "ofile" creado con exito"
	comprimeArchivo	$ofile
	comprobarExistenciaDe "directorioHome.tar.gz"
	#Si el archivo 
	if [ -e $medDir1 ] || [ -e $medDir2 ]; then
		#echo "Duplicidad de archivos. Eliminando antiguos..."
		rm mediaDir*
	fi
	#Crear archivos donde almacenen los valores de las ubicaciones montadas usando df
	for file in $( df --output=target ); do
		echo "$file" >> ${medDir1}
		echo "$file" >> ${medDir2}
	done
	comprobarExistenciaDe $medDir1
	comprobarExistenciaDe $medDir2

	comprarArchivos $medDir1 $medDir2
	copiarArchivo $final $usbRoute

	else
		echo "Fallo en la creacion del archivo a comprimir. Por favor, reinicie el script."
		deleteAll
fi