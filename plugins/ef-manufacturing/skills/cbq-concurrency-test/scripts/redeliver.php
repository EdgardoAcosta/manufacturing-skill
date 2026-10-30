// Re-dispatch payloads of events ALREADY applied, twice each, through the toolkit.
// Before running, fill in the source_id values with real ids from the run (see snapshot.php).
// Expected: "event_commands: movimiento saltado" in the log and 0 new kardex rows.
use Enviaflores\ManufacturingCore\EventCommands\DispatchesEvent;
use Enviaflores\ManufacturingCore\Domains\InventoryAdjustment\Commands\ApplyRawMaterialAdjustMovement as MP;
use Enviaflores\ManufacturingCore\Domains\InventoryAdjustment\Commands\ApplyAffiliateAdjustmentMovement as AFF;
use Enviaflores\ManufacturingCore\Domains\Inventory\Commands\RemoveMgmtInventory as MW;
use Enviaflores\ManufacturingCore\Domains\Inventory\Commands\RemoveProductionInventory as PW;

$ids = json_decode(@file_get_contents('/tmp/redeliver_ids.json') ?: '{}', true);
$d = new class { use DispatchesEvent; public function go($c, $p) { return $this->dispatchTo($c, $p, 101470); } };
$jobs = array_filter([
    isset($ids['mp']) ? [MP::class, ['invt_mgmt_id' => 55792, 'source' => $ids['mp_source'] ?? 'adjust_entry', 'quantity' => $ids['mp_qty'] ?? 1, 'source_id' => $ids['mp'], 'origin_id' => 101470]] : null,
    isset($ids['aff']) ? [AFF::class, ['invt_mgmt_id' => 55792, 'source' => 'adjust_entry', 'quantity' => 1, 'source_id' => $ids['aff'], 'origin_id' => 101470]] : null,
    isset($ids['mw']) ? [MW::class, ['command' => 'MgmtRemove', 'source' => 'wastes', 'invt_mgmt_id' => 55792, 'quantity' => 1, 'source_id' => $ids['mw'], 'origin_id' => 101470]] : null,
    isset($ids['pw']) ? [PW::class, ['command' => 'MgmtRemove', 'source' => 'florist_waste', 'invt_mgmt_id' => 17074, 'quantity' => 1, 'source_id' => $ids['pw'], 'origin_id' => 101470]] : null,
]);
if ($jobs === []) { echo "Missing /tmp/redeliver_ids.json, e.g. {\"mp\":61789,\"mp_qty\":2,\"aff\":29837,\"mw\":209426,\"pw\":682587}".PHP_EOL; return; }
foreach ([1, 2] as $round) {
    foreach ($jobs as [$c, $p]) {
        echo class_basename($c)." #$round ".json_encode($d->go($c, $p)).PHP_EOL;
    }
}
