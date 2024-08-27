## Script to get a list of trackers in Navixy and odometers
## Author Miguel Osornio m.osornio@squaregps.com
## v1.3 Aug 26, 2024
## tested with
## GNU bash, version 3.2.57(1)-release (arm64-apple-darwin23)
## curl 8.6.0 (x86_64-apple-darwin23.0)
## Special requirement of:
## jq-1.7.1 command
## json_pp 4.06
##
#!/bin/bash

clear
echo "Welcome - Navixy List of trackers report"
echo
echo ' ____  _____       _  ____   ____  _____  ____  ____  ____  ____  '
echo '|_   \|_   _|     / \|_  _| |_  _||_   _||_  _||_  _||_  _||_  _| '
echo '  |   \ | |      / _ \ \ \   / /    | |    \ \  / /    \ \  / /   ' 
echo '  | |\ \| |     / ___ \ \ \ / /     | |     \ \/ /      \ \/ /    ' 
echo ' _| |_\   |_  _/ /   \ \_\   /     _| |_   _/ / \ \_    _|  |_    ' 
echo '|_____|\____||____| |____|\_/     |_____||____||____|  |______|   '
echo
echo
echo
filename="tracker_list.csv"

if [ -f ${filename} ]
then
    echo "Deleting existing file "${filename}
    rm ${filename}
    echo "deleted trackers list file"
fi

if [ -f odometers.txt ]
then
    echo "Deleting existing file odometers.txt"
    rm odometers.txt
    echo "deleted odometers file"
fi

if [ -f raw_list.json ]
then
    echo "Deleting existing file raw_list.json"
    rm raw_list.json
    echo "deleted raw file"
fi

echo
echo
echo "Select the server you use"
echo "1 https://api.eu.navixy.com/v2 for European Navixy ServerMate platform"
echo "2 https://api.us.navixy.com/v2 for American Navixy ServerMate platform"
read serv_opt
echo


case $serv_opt in

    1) echo "You're going to use EU Server"
       navixy_server='https://api.eu.navixy.com/v2'
       echo $navixy_server
;; 
        
    2) echo "You're going to use US Server"
       navixy_server='https://api.us.navixy.com/v2'
       echo $navixy_server
;;
        
    *) echo "Please! Enter a valid option."
       exit 1

;;

esac

echo
echo 
echo "Enter the desired auth method"
echo "1 user/pass"
echo "2 hash"

read auth_opt

case $auth_opt in

    1) echo "User and Password selected"
       echo "Enter your user:"
       read -r navixy_user
       echo "Enter your password:"
       read -r -s navixy_password

         navixy_hash=$(curl ''${navixy_server}'/user/auth?login='${navixy_user}'&password='${navixy_password}'' | jq -r '.hash')


         echo $navixy_hash
         if [ "${navixy_hash}" = "null" ]
         then
            echo
            echo "The user or password is wrong"
            echo "Check your credentials or the server you have selected"
            echo
            exit 1
         else
            echo
            echo "The hash has been generated"
            echo $navixy_hash
            echo
         fi


    ;; 
        
    2) echo "Hash Authentication selected"
       echo "Enter your hash:"
       read -r navixy_hash
    ;;
        
    *) echo "Please! Enter a valid option."
       exit 1
    ;;
    esac

echo
echo
echo
echo "Getting the tracker list ..."
echo
echo
curl -X POST ''${navixy_server}'/tracker/list' -H 'Content-Type: application/json' -d '{"hash": "'${navixy_hash}'"}' | json_pp > raw_list.json
echo
echo
echo "Filtering Device IDs and creating temporal files"

jq '.list.[].id' raw_list.json > ${filename}
jq '.list.[].clone' raw_list.json | awk '{print ", " $1 }' > combine_clone.txt
jq '.list.[].label' raw_list.json | awk -F '"' '{print ", " $2 }' > combine_label.txt
jq '.list.[].source.device_id' raw_list.json | awk '{print ", " $1 }' > combine_deviceid.txt
jq '.list.[].source.model' raw_list.json | awk '{print ", " $1 }'> combine_model.txt
jq '.list.[].source.phone' raw_list.json | awk '{print ", " $1 }'> combine_phone.txt

echo
echo "List of trackers" 
cat ${filename}
echo
echo
echo
echo "Getting odometers"

for device in $(cat ${filename}); do
echo
echo "getting odometer for the Device ID " $device 
echo
TEMP_ODO=$(curl -X POST ''${navixy_server}'/tracker/counter/value/list' -H 'Content-Type: application/json' -d '{"hash": "'${navixy_hash}'", "trackers": ['${device}'], "type": "odometer"}' | jq '.value.[]')
echo "printing the temp" ${TEMP_ODO}

if [ -z ${TEMP_ODO} ]
         then
            echo "Odometer is not set for this tracker"
            echo ", NA" >> odometers.txt
      
         else
            echo "Odometer is set for this tracker"
            echo "," ${TEMP_ODO} >> odometers.txt
            echo
         fi
echo
done
echo
echo "Creating final file"

paste ${filename} combine_label.txt > final.csv
cp final.csv ${filename}
paste ${filename} combine_clone.txt > final.csv
cp final.csv ${filename}
paste ${filename} combine_model.txt > final.csv
cp final.csv ${filename}
paste ${filename} combine_deviceid.txt > final.csv
cp final.csv ${filename}
paste ${filename} combine_phone.txt > final.csv
cp final.csv ${filename}
paste ${filename} odometers.txt > final.csv
cp final.csv ${filename}

echo "adding headers"
echo "Tracker_ID, Label, Clone, Model, Device_ID, Phone, Odometers " > final.csv
echo
cat ${filename} >> final.csv
cp final.csv ${filename} 
echo
echo "Cleaning temporal files"

rm combine_label.txt
rm combine_clone.txt
rm combine_deviceid.txt
rm combine_model.txt
rm combine_phone.txt
rm raw_list.json
rm odometers.txt
rm final.csv
echo "Finishing clean-up"


echo "script end!"

