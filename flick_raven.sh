#!/bin/bash

gdbus call --session --dest com.solus_project.arc.Raven --object-path /com/solus_project/arc/Raven --method com.solus_project.arc.Raven.Toggle 
