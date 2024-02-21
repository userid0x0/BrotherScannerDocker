<?php
include_once(__DIR__."/lib/lib.php");

if ($_SERVER['REQUEST_METHOD'] == 'GET') {


        if(array_key_exists("file", $_GET)) {
                $filename = $_GET["file"];
                $filepath=$SCANS_DIR . $filename;
                if(file_exists($filepath) && is_sub_dir($filepath, $SCANS_DIR)) {
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