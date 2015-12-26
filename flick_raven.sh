#!/bin/sh

gdbus call --session --dest com.solus_project.budgie.Raven --object-path /com/solus_project/budgie/Raven --method com.solus_project.budgie.Raven.Toggle
