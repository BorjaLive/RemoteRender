<?php
    $dir_subida = 'data/';
    $file_name = basename($_FILES['sourceFile']['name']);
    $fichero_subido = $dir_subida . $file_name;

    $lockFile = $fichero_subido.".lock";

    $lock = fopen($lockFile, 'w');
    fwrite($lock, "Preparando");
    fwrite($lock, "\n");
    fwrite($lock, "");
    fclose($lock);

    move_uploaded_file($_FILES['sourceFile']['tmp_name'], $fichero_subido);

    unlink($lockFile);
?>
