#!/bin/sh
# Los certificados llegan por variables privadas (CERT_<NIT>_B64), nunca desde el repositorio.
set -e
DESTINO="${DIRECTORIO_CERTIFICADOS:-/uploads}"
mkdir -p "$DESTINO"
for variable in $(env | sed -n 's/^\(CERT_[0-9]\{14\}_B64\)=.*/\1/p'); do
  nit=$(echo "$variable" | sed 's/^CERT_\([0-9]*\)_B64$/\1/')
  eval "valor=\$$variable"
  echo "$valor" | base64 -d > "$DESTINO/$nit.crt"
  chmod 600 "$DESTINO/$nit.crt"
  echo "Certificado cargado para el NIT $nit"
done
exec java -cp 'app:app/lib/*' sv.mh.fe.Application
