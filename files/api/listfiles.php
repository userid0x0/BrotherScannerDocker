<?php
include_once(__DIR__."/lib/lib.php");

if ($_SERVER['REQUEST_METHOD'] == 'GET') {

    $path = '/scans';
    $files = getFileList($path, GETFILELIST_SORT_CREATEDATE_DESC);
    for ($i = 0; $i < min(10, count($files)); $i++) {
            echo "<a class='listitem' href=/download.php?file=" . $files[$i] . ">" . $files[$i] . "</a><br>";
    }
}
else {
    http_reponse_code(405);
    die("Error: Method not allowed!");
}
?>