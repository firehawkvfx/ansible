'''
    Stolen from Gavin's great example on this forum thread:
    https://forums.thinkboxsoftware.com/viewtopic.php?f=11&t=13396#p59978
'''

from System.Diagnostics import *
from System.IO import *
from System import TimeSpan

from Deadline.Events import *
from Deadline.Scripting import *

import re
import sys
import os
import subprocess
import traceback
import shlex

SLAVE_NAME_PREFIX = "ip-" # Example: "mobile-"
POOLS = ["one", "two", "three"] # Example: ["one", "two", "three"]
GROUPS = ["cloud"]
# LISTENING_PORT=None # or 27100
LISTENING_PORT=27100

def GetDeadlineEventListener():
    return ConfigSlaveEventListener()


def CleanupDeadlineEventListener(eventListener):
    eventListener.Cleanup()


class ConfigSlaveEventListener (DeadlineEventListener):
    def __init__(self):
        self.OnSlaveStartedCallback += self.OnSlaveStarted

    def Cleanup(self):
        del self.OnSlaveStartedCallback

    # This is called every time the Slave starts
    def OnSlaveStarted(self, slavename):
        # Load slave settings for when we needed
        slave = RepositoryUtils.GetSlaveSettings(slavename, True)

        # Skip over Slaves that don't match the prefix
        if not slavename.lower().startswith(SLAVE_NAME_PREFIX):
            return

        print("Slave automatic configuration for {0}".format(slavename))

        # Set up the Groups we want to use
        for group in GROUPS:
            try:
                print("   Adding group {0}".format(group))
                RepositoryUtils.AddGroupToSlave(slavename, group)
            except:
                ClientUtils.LogText(traceback.format_exc())

        # Set up the Pools we want to use
        for pool in POOLS:
            try:
                print("   Adding pool {0}".format(pool))
                RepositoryUtils.AddPoolToSlave(slavename, pool)

                # Power management example:
                # pmanage = RepositoryUtils.GetPowerManagementOptions()
                # pmanage.Groups[0].SlaveNames.append(slavename)

            except:
                ClientUtils.LogText(traceback.format_exc())

        # Set up the listening port
        if LISTENING_PORT:
            print("   Configuring Slave to listen on port {0}".format(LISTENING_PORT))
            slave.SlaveListeningPort = LISTENING_PORT
            slave.SlaveOverrideListeningPort = True
        else:
            print("   Configuring Slave to use random listening port".format(LISTENING_PORT))
            slave.SlaveOverrideListeningPort = False

        # Save any changes we've made back to the database
        RepositoryUtils.SaveSlaveSettings(slave)
