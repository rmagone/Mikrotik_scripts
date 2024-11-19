# Define variables stored in mikrotik Memory for reuse in other script
:global desiredCellId;
:global fallbackCellId;
:global wasChangeSuccess true;

:if ([:len $desiredCellId] = 0) do={ :set desiredCellId "187" }
:if ([:len $fallbackCellId] = 0) do={ :set fallbackCellId "352" }
/log info message= "debug";
# Function to perform band locking via AT command
:global firstLockBand do={
    # Lock to the first band (Band 352)
    :put "Switching to tower 352";
    /interface lte at-chat lte1 input="at+qnwlock=\"common/4g\",3,1300,352,9360,352,100,352";
}

:global secondLockBand do={
    # Lock to the first band (Band 352)
    :put "Executing secondLockBand to switch to tower 187";
    /interface lte at-chat lte1 input="at+qnwlock=\"common/4g\",2,1300,187,6300,187";
    :put "AT command sent: Locking to tower 187";
}

:local getActualTower do={
    :put "I am here";
    #get tower data
    :local myTowerData [/interface lte monitor lte1 once as-value];
    #fetch specific entry
    
    :local phyCellId ([($myTowerData->"phy-cellid")]);
   # :set $desiredCellId "159";
:put ("Desired Cell ID: " . $desiredCellId);
:put ("Actual Cell ID: " . $phyCellId);
:put ("fallback Cell ID: " . $fallbackCellId);
:if ($phyCellId!=$desiredCellId) do={
        :put "BlackBird down";
        :if ($desiredCellId = "352") do={
            :put "Setting to 352";
            :global firstLockBand;
            $firstLockBand;
        } else={
            :put "Setting to 187";
            :global secondLockBand;
            $secondLockBand;
        }
} else={
    :put "BlackBird alive, we are good";
}
}

:local checkIfConnected do={
    :global getNetworkState;
    :local status $getNetworkState;
    :if ($status = false) do={
        :if ($fallbackCellId="352") do={
            :global firstLockBand;
            $firstLockBand;
        } else={
            :global secondLockBand;
            $secondLockBand;
        }
        :delay 10;
      $getNetworkState;
    } else={
        :put "We are connected";
        :set $wasChangeSuccess true;
    }
}

:global getNetworkState do={
    :local networkState [/interface lte monitor lte1 once as-value];
    :local status ([($networkState->"status")]);
    :put $status;
    :if ($status !="connected") do={
        :set $wasChangeSuccess false;
        :return false;
    } else={
         :set $wasChangeSuccess true;
         :return true;
    }
}
$getActualTower desiredCellId=$desiredCellId fallbackCellId=$fallbackCellId;

:delay 10;
$checkIfConnected fallbackCellId=$fallbackCellId;