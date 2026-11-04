# Zebra label design (ZPL)

Templates: `workshop-daemon/app/Config/LabelTemplates/*.zpl`, authored at 300 dpi. `V1LabelerController` renders `{{field}}` placeholders, `{{#field}}...{{/field}}` optional blocks, scales every dot value with `scaleZplDots(..., 300, printer_dpi)` and shrinks `^FB<w>,1` fields with a uniform em estimate (`fitZplFieldBlocks`). Values lose `" ^ ~ \`. `small_uuid` is derived from `uuid` (uppercased).

## Loop that does not waste labels
1. Edit locally, render with Labelary: `curl -s -H 'Accept: image/png' --data-binary @tpl.zpl http://api.labelary.com/v1/printers/<8dpmm|12dpmm>/labels/<w_in>x<h_in>/0/ -o out.png` (8dpmm = 203 dpi, 12dpmm = 300). Render the ZPL the server returns with `?debug=1`, not the raw 300-dpi template. 1 px = 1 dot, so boxes measured on the PNG are exact.
2. Send the PNG with SendUserFile; the user cannot see Read output.
3. On the server, `POST /labeler/jobs?debug=1` first: proves the server has the new template (`grep ^PW`) and the right `printer_dpi`.
4. Print one label with a unique `job_name`.

## Measuring
- Never derive mm, dpi or roll size from phone photos (+-2 mm errors gave wrong conclusions twice). Print a frame/ruler (`^GB` box + ticks at known dots) and ask whether it hugs the edges.
- "Too big / too small" = check `printer_dpi` in the request and the template version on the server first; `printer_dpi` 300 on a 203 head prints 1.48x larger, 203 on a 300 head 0.68x smaller.
- Physical size: `dots / dpi * 25.4` mm. Read the head with SGD `head.resolution.in_dpi`, not from the model name.
- The same template can sit a few mm off on two printers of the same model: per-printer offset, not a template bug.

## ZPL facts
- `^FB<w>,<lines>` overflow prints over the last line; `\&` is the line break inside `^FB`.
- QR `^BQN,2,<mag>` + `^FDMM,A<data>`: error correction M, manual alphanumeric. `*:` + 36-char uuid = 38 chars = exactly version 2-M (25 modules). Size = 25 x mag dots (mag 4 at 203 dpi = 12.5 mm). One more char jumps to version 3.
- Font 0 (`^A0N,h,h`) is proportional. Width per char in em (ink / height, measured on Labelary at 24 dots): M 0.75, W 0.82, I 0.27, typical uppercase ~0.55, space 0.30, digits 0.48. Use a per-char table for line fitting; a uniform em under-fills short names and overflows wide ones.
- Test data: uppercase uuids, Spanish day names, one distinct `job_name` per test.
