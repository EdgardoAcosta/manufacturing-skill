// Baseline on first run (/tmp/cc_base.json), then everything written after it. SELECT + LIMIT only.
// Reset the baseline: rm /tmp/cc_base.json
$db = DB::connection("legacy");
$b = json_decode(@file_get_contents('/tmp/cc_base.json') ?: 'null', true);
if (!$b) {
    $b = [
        'mgmt_log' => $db->selectOne("SELECT MAX(id) m FROM invt_mgmt_transaction_log")->m,
        'prod_log' => $db->selectOne("SELECT MAX(id) m FROM invt_production_transaction_log")->m,
        'req' => $db->selectOne("SELECT MAX(id) m FROM invt_mgmt_adjust_requests")->m,
        'aff' => $db->selectOne("SELECT MAX(id) m FROM inventory_adjust_log")->m,
        'mw' => $db->selectOne("SELECT MAX(id) m FROM invt_mgmt_wastes")->m,
        'pw' => $db->selectOne("SELECT MAX(id) m FROM invt_production_wastes")->m,
        'cc' => $db->selectOne("SELECT MAX(id) m FROM invt_mgmt_cycle_count_material_categories")->m,
    ];
    file_put_contents('/tmp/cc_base.json', json_encode($b));
    echo "BASELINE ".json_encode($b).PHP_EOL;
}
echo "stock mgmt55792 ".json_encode($db->selectOne("SELECT current_quantity q, current_unit_cost c, current_total_value v FROM invt_mgmt WHERE id=55792"))
    ." prod4832 ".json_encode($db->selectOne("SELECT current_quantity q FROM invt_production WHERE id=4832")).PHP_EOL;
foreach ($db->select("SELECT id, reference, reference_id, request_platform, quantity, current_qty, new_qty FROM invt_mgmt_transaction_log WHERE id > ? AND invt_mgmt_id=55792 ORDER BY id LIMIT 60", [$b['mgmt_log']]) as $r) echo "mk ".json_encode($r).PHP_EOL;
foreach ($db->select("SELECT id, reference, reference_id, request_platform, quantity, current_qty, new_qty FROM invt_production_transaction_log WHERE id > ? AND invt_production_id=4832 ORDER BY id LIMIT 60", [$b['prod_log']]) as $r) echo "pk ".json_encode($r).PHP_EOL;
foreach ($db->select("SELECT id, status, operation, quantity FROM invt_mgmt_adjust_requests WHERE id > ? LIMIT 30", [$b['req']]) as $r) echo "req ".json_encode($r).PHP_EOL;
foreach ($db->select("SELECT id, adjust_type, quantity, sended_to_queue FROM inventory_adjust_log WHERE id > ? LIMIT 30", [$b['aff']]) as $r) echo "aff ".json_encode($r).PHP_EOL;
foreach ($db->select("SELECT id, invt_mgmt_id, quantity, status FROM invt_mgmt_wastes WHERE id > ? LIMIT 30", [$b['mw']]) as $r) echo "mw ".json_encode($r).PHP_EOL;
foreach ($db->select("SELECT id, quantity FROM invt_production_wastes WHERE id > ? LIMIT 30", [$b['pw']]) as $r) echo "pw ".json_encode($r).PHP_EOL;
foreach ($db->select("SELECT id, workshop_id, material_category_id, frequency FROM invt_mgmt_cycle_count_material_categories WHERE id > ? LIMIT 10", [$b['cc']]) as $r) echo "cc ".json_encode($r).PHP_EOL;
// Unbroken chain: each row's current_qty must equal the previous row's new_qty.
foreach (['invt_mgmt_transaction_log' => ['invt_mgmt_id', 55792, 'mgmt_log'], 'invt_production_transaction_log' => ['invt_production_id', 4832, 'prod_log']] as $t => [$col, $id, $k]) {
    $prev = null; $breaks = 0;
    foreach ($db->select("SELECT current_qty, new_qty FROM $t WHERE id > ? AND $col=? ORDER BY id LIMIT 200", [$b[$k], $id]) as $r) {
        if ($prev !== null && (float) $r->current_qty !== (float) $prev) $breaks++;
        $prev = $r->new_qty;
    }
    echo "chain $t/$id breaks=$breaks".PHP_EOL;
}
