#!/bin/sh
#sent mail and move log

APP_HOME="/home/tdmdf/HS_forecast"
APP_INPUT="$APP_HOME/input"
APP_OUTPUT="$APP_HOME/output"
APP_SCRIPT="$APP_HOME/script"
APP_LOG="$APP_HOME/log"
APP_LOG_FILE="$APP_LOG/HS_forecast.log"

DT=`date +%d%m%y`; export DT

mailx -s "HS forcast log" danaisuj@ais.co.th,pitchaym@ais.co.th,vasarucr@ais.co.th,puttipon@ais.co.th < $APP_LOG_FILE

mv $APP_LOG_FILE $APP_LOG_FILE.$DT



