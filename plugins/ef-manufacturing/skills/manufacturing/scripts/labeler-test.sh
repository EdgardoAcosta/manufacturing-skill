#!/bin/sh
# Uso (en el servidor de impresión, sin sudo):
#   sh labeler-test.sh                        primera cola ZTC-*, template material_reception
#   sh labeler-test.sh ZTC-ZD421-XXXX material_reception_small
#   DEBUG=1 sh labeler-test.sh                solo muestra el ZPL, no imprime
set -eu
CUPS=localhost:2631
PORT=${PORT:-4857}
TPL=${2:-material_reception}

Q=${1:-$(lpstat -h "$CUPS" -p | awk '/^printer ZTC-/{print $2; exit}')}
[ -n "$Q" ] || { echo "No hay colas ZTC-* en CUPS $CUPS" >&2; exit 1; }

IP=$(lpstat -h "$CUPS" -v "$Q" | sed -n 's#.*socket://\([^:/]*\).*#\1#p')
[ -n "$IP" ] || { echo "La cola $Q no es socket://IP:9100" >&2; exit 1; }

DPI=$(printf '! U1 getvar "head.resolution.in_dpi"\r\n' | timeout 3 nc -w2 "$IP" 9100 | tr -dc 0-9 || true)
case "$DPI" in
  203|300) ;;
  *) echo "La impresora $IP no respondió el dpi ('$DPI')" >&2; exit 1 ;;
esac

SRV=$(hostname -I | awk '{print $1}')
U=$(tr a-z A-Z </proc/sys/kernel/random/uuid)
case $(date +%u) in
  1) DAY=LUNES ;; 2) DAY=MARTES ;; 3) DAY=MIERCOLES ;; 4) DAY=JUEVES ;;
  5) DAY=VIERNES ;; 6) DAY=SABADO ;; *) DAY=DOMINGO ;;
esac

BODY=$(cat <<EOF
{"template_name":"$TPL","printer_name":"$Q","printer_dpi":$DPI,
"job_name":"prueba-$(date +%H%M%S)","uuid":"*:$U",
"provider_name":"PRUEBA $(hostname -s)","sku":"0000",
"name":"ROSA","variety":"ROJA","material_name":"Rosa Roja",
"units":"1","packages":"1","arrival_day":"$DAY","arrival_date":"$(date +%d/%m/%y)"}
EOF
)

URL="http://$SRV:$PORT/labeler/jobs${DEBUG:+?debug=1}"
echo "Servidor $SRV:$PORT  cola $Q  impresora $IP  dpi $DPI  template $TPL${DEBUG:+  [DEBUG]}" >&2
curl -sS -X POST "$URL" -H 'Content-Type: application/json' -d "$BODY"
echo
