<?php
/**
 *  Charlink Connect - Hotspot Billing (https://github.com/MarkCalebChomba/charlink-system)
 *  by Charlink Connect
 **/

if(function_exists($routes[1])){
    call_user_func($routes[1]);
}else{
    r2(getUrl('dashboard'), 'e', 'Function not found');
}