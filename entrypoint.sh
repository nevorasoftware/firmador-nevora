#!/bin/sh
# Los certificados llegan por variables privadas (CERT_<NIT>_B64) o del backend, nunca desde el repositorio.
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

# Descarga periódica de los certificados de las empresas. Un fallo aquí nunca detiene al firmador.
sincronizar() {
  set +e
  lista="$DESTINO/.certificados"
  estado=""
  while true; do
    if wget -q -T 15 --header "X-Firmador-Token: $CERTIFICADOS_TOKEN" -O "$lista" "$CERTIFICADOS_URL"; then
      if [ "$estado" != "ok" ]; then echo "Sincronización de certificados activa"; estado="ok"; fi
      while read -r nit contenido; do
        case "$nit" in ''|*[!0-9]*) continue ;; esac
        [ "${#nit}" -eq 14 ] || [ "${#nit}" -eq 9 ] || continue
        temporal="$DESTINO/.$nit.tmp"
        if echo "$contenido" | base64 -d > "$temporal" 2>/dev/null && [ -s "$temporal" ]; then
          chmod 600 "$temporal"
          mv "$temporal" "$DESTINO/$nit.crt"
        else
          rm -f "$temporal"
        fi
      done < "$lista"
    elif [ "$estado" != "error" ]; then
      echo "No se pudieron descargar los certificados; se reintenta"
      estado="error"
    fi
    rm -f "$lista"
    sleep "${CERTIFICADOS_INTERVALO:-30}"
  done
}

if [ -n "$CERTIFICADOS_URL" ] && [ -n "$CERTIFICADOS_TOKEN" ]; then
  sincronizar &
fi

exec java -cp 'app:app/lib/*' sv.mh.fe.Application
