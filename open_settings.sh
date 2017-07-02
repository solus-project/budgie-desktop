#!/bin/bash

# Quick hacky script so we can check the new SettingsWindow

gdbus call --session --dest org.budgie_desktop.Panel --object-path /org/budgie_desktop/Panel --method org.budgie_desktop.Panel.OpenSettings 
