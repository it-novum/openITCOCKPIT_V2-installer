<?php
/**
# Copyright (C) 20011-2022 it-novum GmbH
#
# This program is free software; you can redistribute it and/or modify it 
# under the terms of the GNU General Public License version 2 as published 
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
# See the GNU General Public License for more details.
#
# Nagvis add basic user 
#
#    CHANGELOG
#    2012-03-04 (daniel.ziegler@it-novum.com)
#     - created (v0.1)
*/

// Password is not important, because user will only be checkes against the openITC database

if(isset($_SERVER['argv'][1]) && strlen($_SERVER['argv'][1])>0){
        $username = $_SERVER['argv'][1];
        $db = SQL3Connect();
        SQL3CreateUser($db, $username, 'open2itc', '4');
        exit(0);
}else{
        echo "Error: Username or password not set!\n";
        exit(2);
}

/**
 * creates a connection to the NagVis database (SQLite 3.x)
 * @return NagVis database as PDO object
 */
function SQL3Connect(){
    $db = null;
    $dbfile = '/opt/openitc/nagios/share/3rd/nagvis/etc/auth.db';
    $db = new PDO("sqlite:".$dbfile);
    return $db;
}
/**
 * executes a given query on the SQLite database.
 * @param db    Datenbank als PDO Objekt
 * @param query SQL-Statement as string
 * @return result as an array
 */
function SQL3Query($db, $query){
    $queryArr = array();
        $SQLResult = $db->query($query);
        if(!empty($SQLResult)){
            foreach($db->query($query) as $raw){
                        array_push($queryArr, $raw);
            }
        }
    array_unique($queryArr);
    return $queryArr;
}

/**
 * creates a new user in the NagVis database
 * @param db         database as a PDO object
 * @param username   user you wish to create, as a string
 * @param role       rights of the user as an intager (2=user (read-only), 4=manager)
 * @param password   password for the user in plain text. the password will be written in md5 to the database
 */
function SQL3CreateUser($db, $username, $password, $role){
    //check if the user already exists
    $query = "SELECT * FROM users WHERE name LIKE '".strtolower($username)."'";
    if(isset($db) && isset($role)){
        $result = SQL3Query($db, $query);

        //add the user
        if(empty($result)){
            $db->exec("INSERT INTO users
                        (
                         name,
                         password
                        )
                        VALUES
                        ('".strtolower($username)."',
                         '".md5($password)."'
                        )"
                      );
            //get user ID
            $userId = SQL3GetUserId($db, $username);
            unset($query);
            //check if a role for this user(ID) already exists
            $query = "SELECT * FROM user2roles WHERE userId LIKE '".$userId."'";
            $CheckForID = SQL3Query($db, $query);
            if(empty($CheckForID)){
                $db->exec("INSERT INTO users2roles
                            (
                             userId,
                             roleId
                            )
                            VALUES
                            ('".$userId."',
                             '".$role."'
                            )"
                         );
            }
            //print_r($result);
        }else{
            echo "Username already exists in database.\n";
            exit(1);
        }
    }
}

/**
 * get an ID of a given user
 * @param db         database as a PDO Objekt
 * @param username   user, from wich you want the ID 
 * @return           ID as an integer
 */
function SQL3GetUserId($db, $username){
    $query = "SELECT * FROM users WHERE name LIKE '".strtolower($username)."'";
    $result = SQL3Query($db, $query);
        if(!empty($result[0]['userId'])){
        return $result[0]['userId'];
        }
}

/**
 * close the connection to the NagVis database
 * @param db    database as a PDO object
 */
function SQL3Disconnect($db){
    if(isset($db))
        $db = null;
        unset($db);
}

?>
