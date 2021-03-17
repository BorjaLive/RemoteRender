<?php
    const DATA = "DATA/";

    $action = sGet("action", "version");

    switch($action){
        case "version":
            echo "Remote Render Server";
        break;
        case "get":
            if(sGet("encode", "custom") == "json"){
                echo json_encode(array_values(checkJobs()));
            }else{
                $text = "";
                foreach(checkJobs() as $job){
                    $text .= $job["title"]."]".$job["status"]."]".$job["progress"]."|";
                }
                echo substr($text, 0, -1);
            }
        break;
        case "update":
            $mod = sGet("mod", "");
            switch($mod){
                case "set": //LLamdo cuando un nodo se adjudica un trabajo o actualiza su estado
                    $lockFile = DATA.sGet("job", "").".zip.lock";
                    if(file_exists($lockFile)) unlink($lockFile);
                    $lock = fopen($lockFile, 'w');
                    fwrite($lock, sGet("status", ""));
                    fwrite($lock, "\n");
                    fwrite($lock, sGet("progress", ""));
                    fclose($lock);
                break;
                case "unset": //LLamdo cuando un nodo termina un trabajo
                    $job = DATA.sGet("job", "");
                    if(file_exists($job.".zip")) unlink($job.".zip");
                    if(file_exists($job.".zip.lock")) unlink($job.".zip.lock");
                break;
            }
        break;
        case "remove":
            $job = DATA.sGet("job", "");
            if(file_exists($job.".zip")) unlink($job.".zip");
            if(file_exists($job.".zip.lock")) unlink($job.".zip.lock");
            if(file_exists($job.".7z")) unlink($job.".7z");
        break;
    }

    function checkJobs(){
        $jobs = [];
        foreach(glob(DATA."*.zip") as $file){
            $file = basename($file);
            $job = [
                "title" => substr($file, 0, strlen($file)-4),
                "status" => "Pendiente",
                "progress" => ""
            ];
            $lock = DATA.$file.".lock";
            if(file_exists($lock)){
                $handle = fopen($lock, "r");
                $job["status"] = fgets($handle);
                $job["progress"] = fgets($handle);
                fclose($handle);
            }
            $jobs[] = $job;
        }
        foreach(glob(DATA."*.7z") as $file){
            $file = basename($file);
            $job = [
                "title" => substr($file, 0, strlen($file)-3),
                "status" => "Finalizado",
                "progress" => "100"
            ];
            $jobs[] = $job;
        }
        return $jobs;
    }

    function sGet($name, $default = null){
        return empty($_GET[$name])?$default:$_GET[$name];
    }
?>
