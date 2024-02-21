<?php
include_once(__DIR__."/lib/lib.php");
if ($_SERVER['REQUEST_METHOD'] == 'GET') {
        $files = getFileList($SCANS_DIR, GETFILELIST_SORT_CREATEDATE_DESC);
        $num = $_GET["num"] ?? count($files);
        for ($i = 0; $i < $num; $i++) {
                echo $files[$i]."<br>";
        }
} else {
        http_reponse_code(405);
        die("Error: Method not allowed!");
}
?>
