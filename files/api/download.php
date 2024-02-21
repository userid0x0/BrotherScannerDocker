<?php
include(dirname(__DIR__)."/lib/lib.php");

if ($_SERVER['REQUEST_METHOD'] == 'GET') {

        $SCAN_FOLDER = "/scans/";

        if(array_key_exists("file", $_GET)) {
                $filename = $_GET["file"];
                $filepath=$SCAN_FOLDER . $filename;
                if(file_exists($filepath) && is_sub_dir($filepath, $SCAN_FOLDER)) {
                        header("Content-type: " . (mime_content_type($filepath) || 'application/octet-stream'));
                        header("Content-Disposition: attachment; filename=\"" . $filename . "\"");
                        readfile($filepath);
                } else {
                        http_reponse_code(404);
                        die("Error: File does not exist!");
                }
        } else {
                http_reponse_code(400);
                die("Error: No file provided!");
        }
} else {
        http_reponse_code(405);
        die("Error: Method not allowed!");
}
?>