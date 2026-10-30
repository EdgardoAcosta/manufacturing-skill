#!/bin/sh
# Run inside the container from /app. Scans the log since /tmp/logmark (set with: wc -l < storage/logs/laravel.log > /tmp/logmark).
M=$(cat /tmp/logmark 2>/dev/null || echo 1)
tail -n +"$M" storage/logs/laravel.log > /tmp/win.log
echo "levels:"; grep -oE "local\.[A-Z]+" /tmp/win.log | sort | uniq -c
echo "perm errors: $(grep -c 'Permissions fetch failed' /tmp/win.log)"
echo "identity/movement failures: $(grep -cE 'identity_conflict|source_row_missing|identity_not_written|missing_source_id|movimiento fallido|no se encoló' /tmp/win.log)"
echo "skipped (idempotency): $(grep -c 'movimiento saltado' /tmp/win.log)"
echo "sent to Kafka:"; grep 'Sending message to Kafka' /tmp/win.log | grep -oE '"cmd":"[^"]+"' | sort | uniq -c
echo "processed via Redis:"; grep 'processed successfully' /tmp/win.log | grep -oE '"cmd":"[^"]+"' | sort | uniq -c
echo "dead-letter:"; grep 'dead-lettered' /tmp/win.log | grep -oE '"uuid":"[^"]+"' | while read -r u; do
    id=$(echo "$u" | cut -d'"' -f4)
    echo "  $id $(grep "$id" /tmp/win.log | grep -oE 'exception_message":"[^"]{0,160}' | head -1)"
done
