<?php
    if($_GET["passSecretCode"] == "atornilladorDiscoZumoPlastico"){
        $dir_subida = 'data/';
        $fichero_subido = $dir_subida . basename($_FILES['finishFile']['name']);
        move_uploaded_file($_FILES['finishFile']['tmp_name'], $fichero_subido);
    }
?>
