#!/bin/sh
#Version 1.02 : Add code to collect script running log
#Version 1.03 : Add step transfer model_mapping to workspace
#Version 1.10 : Modify model_mapping and expand forecast range
#Version 1.11 : Turn off model mapping feature due to bug
#Version 2.0 : Adding product subtype input fields
#Version 2.1 : Boosting new handset model
#Version 2.2 : Fix bug for some newly launch model
#Version 2.3 : Limit training to 3 month and unlock cap max
#Version 2.4 : Fixed bug for cap max and setting limit

I_AM_VERSION="V2.4"
APP_HOME="/home/tdmdf/HS_forecast"
APP_INPUT="$APP_HOME/input"
APP_OUTPUT="$APP_HOME/output"
APP_SCRIPT="$APP_HOME/script"
APP_LOG="$APP_HOME/log"
APP_LOG_FILE="$APP_LOG/HS_forecast.log"
NAS_INPUT="/app/MNT_NFS/SH_TDM/DATA/DWH/OUT/DATASCIENCE"
NAS_OUTPUT="/app/MNT_NFS/SH_TDM/DATA/DWH/IN/DATASCIENCE"
echo "================================================================" >> "$APP_LOG_FILE" 2>&1
echo "$(date +"%Y-%m-%d %H:%M:%S") : Begin : Forecast Script : $I_AM_VERSION" >> "$APP_LOG_FILE" 2>&1
echo "$(date +"%Y-%m-%d %H:%M:%S") : Begin : Initial and Validate Resource Path" >> "$APP_LOG_FILE" 2>&1
#0. validate important path
#- local input
    if [ -d "$APP_INPUT" ]
    then
       echo "Input path exist : $APP_INPUT" >> "$APP_LOG_FILE" 2>&1
    else
       echo "Not found input path : $APP_INPUT" >> "$APP_LOG_FILE" 2>&1
       exit 2
    fi

#- local output
    if [ -d "$APP_OUTPUT" ]
    then
       echo "Output path exist : $APP_OUTPUT" >> "$APP_LOG_FILE" 2>&1
    else
       echo "Not found output path : $APP_OUTPUT" >> "$APP_LOG_FILE" 2>&1
       exit 2
    fi

#- script
    if [ -d "$APP_SCRIPT" ]
    then
       echo "Script path exist : $APP_SCRIPT" >> "$APP_LOG_FILE" 2>&1
    else
       echo "Not found Script path : $APP_SCRIPT" >> "$APP_LOG_FILE" 2>&1
       exit 2
    fi

#- log
    if [ -d "$APP_LOG" ]
    then
       echo "Log path exist : $APP_LOG" >> "$APP_LOG_FILE" 2>&1
    else
       echo "Not found Log path : $APP_LOG" >> "$APP_LOG_FILE" 2>&1
       exit 2
    fi

echo "$(date +"%Y-%m-%d %H:%M:%S") : Complete : Initial and Validate Resource Path" >> "$APP_LOG_FILE" 2>&1

#1. validate NAS input path and get lastest 2 input files name
#    if [ -d "NAS_INPUT" ]
#    then
#       echo "NAS_input path exist" >> "$APP_LOG_FILE" 2>&1
#    else
#       echo "Not found NAS_input path" >> "$APP_LOG_FILE" 2>&1
#    fi

echo "$(date +"%Y-%m-%d %H:%M:%S") : Begin : Transfer Resource file to workspace" >> "$APP_LOG_FILE" 2>&1
#2. Transfer input file to working directory + rename for script
    #- get Sale Data file from NAS and rename
    list_input_sale_sync=$(ls -rt $NAS_INPUT/INPUT_SALE_DATA*.sync|tail -1)
    echo "Latest Sale Sync : $list_input_sale_sync" >> "$APP_LOG_FILE" 2>&1
    list_input_sale_dat=$(echo $list_input_sale_sync|cut -f1 -d ".")".dat"
    echo "Latest Sale Data : $list_input_sale_dat" >> "$APP_LOG_FILE" 2>&1
    cp $list_input_sale_dat "$APP_INPUT/latest_TDM_HS.dat" >> "$APP_LOG_FILE" 2>&1

    #- get control handset model file from NAS and rename
    list_ctl_hs_sync=$(ls -rt $NAS_INPUT/INPUT_LUNCH_DATE*.sync|tail -1)
    echo "Latest LUNCH SYNC : $list_ctl_hs_sync" >> "$APP_LOG_FILE" 2>&1
    list_ctl_hs_dat=$(echo $list_ctl_hs_sync|cut -f1 -d ".")".dat"
    echo "Lastest LUNCH Data : $list_ctl_hs_dat" >> "$APP_LOG_FILE" 2>&1
    cp $list_ctl_hs_dat "$APP_INPUT/latest_control.dat" >> "$APP_LOG_FILE" 2>&1

    #- get model mapping file from NAS and rename
    list_model_map_sync=$(ls -rt $NAS_INPUT/model_mapping*.sync|tail -1)
    echo "Latest Model Mapping Sync : $list_model_map_sync" >> "$APP_LOG_FILE" 2>&1
    list_model_map_dat=$(echo $list_model_map_sync|cut -f1 -d ".")".dat"
    echo "Lastest Model Mapping Data : $list_model_map_dat" >> "$APP_LOG_FILE" 2>&1
    cp $list_model_map_dat "$APP_INPUT/model_mapping.dat" >> "$APP_LOG_FILE" 2>&1

echo "$(date +"%Y-%m-%d %H:%M:%S") : Complete : Transfer Resource file to workspace" >> "$APP_LOG_FILE" 2>&1
#3. run

    echo "----------------------------------------------------------------" >> "$APP_LOG_FILE" 2>&1
    echo "$(date +"%Y-%m-%d %H:%M:%S") : Start Forecasting Script" >> "$APP_LOG_FILE" 2>&1

    Rscript "$APP_SCRIPT/0_main.R" >> "$APP_LOG_FILE" 2>&1

    if [ "$?" -eq 0 ]
     then
         echo "$(date +"%Y-%m-%d %H:%M:%S") : Forecast R-Script Finished" >> "$APP_LOG_FILE" 2>&1
         echo "----------------------------------------------------------------" >> "$APP_LOG_FILE" 2>&1
     else
         echo "$(date +"%Y-%m-%d %H:%M:%S") : Forecast Script Error" >> "$APP_LOG_FILE" 2>&1
         echo "----------------------------------------------------------------" >> "$APP_LOG_FILE" 2>&1

         echo "$(date +"%Y-%m-%d %H:%M:%S") : HS Forecast Fail at R-Script" >> "$APP_LOG_FILE" 2>&1
         echo "$(date +"%Y-%m-%d %H:%M:%S") : HS Forecast Fail at R-Script" | mailx -s "HS_Forecast Job" pitchaym@ais.co.th lurtratr@ais.co.th danaisuj@ais.co.th

         exit 2
    fi

echo "$(date +"%Y-%m-%d %H:%M:%S") : Begin : Transfer Output file to NAS" >> "$APP_LOG_FILE" 2>&1
#4. Transfer output to NAS + rename
    #- put branch file to NAS
    list_branch_dat=$(ls -rt $APP_OUTPUT/branch*csv|tail -1)
    echo "Current Branch Output : $list_branch_dat" >> "$APP_LOG_FILE" 2>&1
    #add for change permission on NAS
    chmod 777 $list_branch_dat
    umask 11
    cp $list_branch_dat "$NAS_OUTPUT" >> "$APP_LOG_FILE" 2>&1
    list_branch_sync=$(echo $list_branch_dat|cut -f1 -d ".")".sync"
    echo "Current Branch Sync : $list_branch_sync" >> "$APP_LOG_FILE" 2>&1

    touch "$list_branch_sync"
    #add for change permission on NAS
    chmod 777 $list_branch_sync
    umask 11
    cp $list_branch_sync "$NAS_OUTPUT" >> "$APP_LOG_FILE" 2>&1

    #- put lambda file to NAS
    list_lambda_dat=$(ls -rt $APP_OUTPUT/lambda*csv|tail -1)
    echo "Current Lambda : $list_lambda_dat" >> "$APP_LOG_FILE" 2>&1
    #add for change permission on NAS
    chmod 777 $list_lambda_dat
    umask 11
    cp $list_lambda_dat "$NAS_OUTPUT" >> "$APP_LOG_FILE" 2>&1
    list_lambda_sync=$(echo $list_lambda_dat|cut -f1 -d ".")".sync"
    echo "Latest Lambda Sync : $list_lambda_sync" >> "$APP_LOG_FILE" 2>&1

    touch "$list_lambda_sync"
    #add for change permission on NAS
    chmod 777 $list_lambda_sync
    umask 11
    cp $list_lambda_sync "$NAS_OUTPUT" >> "$APP_LOG_FILE" 2>&1

    if [ "$?" -eq 0 ]
    then
     echo "$(date +"%Y-%m-%d %H:%M:%S") : HS Forecast Completed" >> "$APP_LOG_FILE" 2>&1
     echo "$(date +"%Y-%m-%d %H:%M:%S") : HS Forecast Completed" | mailx -s "HS_Forecast Job" pitchaym@ais.co.th lurtratr@ais.co.th danaisuj@ais.co.th
    else
     echo "$(date +"%Y-%m-%d %H:%M:%S") : HS Forecast Fail" >> "$APP_LOG_FILE" 2>&1
     echo "$(date +"%Y-%m-%d %H:%M:%S") : HS Forecast Fail" | mailx -s "HS_Forecast Job" pitchaym@ais.co.th lurtratr@ais.co.th danaisuj@ais.co.th
    fi

echo "================================================================" >> "$APP_LOG_FILE" 2>&1
