#!/bin/sh
set -e
set -x

_cleanup()
{
    if [[ ! -z "${PANELPID}" ]]; then
        kill "${PANELPID}"
    fi
    if [[ ! -z "${WMPID}" ]]; then
        kill "${WMPID}"
    fi
    if [[ ! -z "${XPID}" ]]; then
        kill "${XPID}"
    fi
}

trap _cleanup SIGINT EXIT

if [[ -z "${LOCAL_DISPAY}" ]]; then
    LOCAL_DISPLAY=":5"
fi

if [[ -z "${SCREEN_SIZE}" ]]; then
    SCREEN_SIZE="1024x768"
fi

Xephyr -title "Budgie Test" +iglx -screen "${SCREEN_SIZE}" "${LOCAL_DISPLAY}" &
XPID="$!"

GTK_THEME="Budgie-Darker" DISPLAY="${LOCAL_DISPLAY}" budgie-wm &
WMPID="$!"

sleep 1

GTK_THEME="Budgie-Darker" DISPLAY="${LOCAL_DISPLAY}" budgie-panel
PANELPID="$1"
