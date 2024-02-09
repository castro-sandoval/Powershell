# production FSx

# dev   amznfsx4gsbryes.llamadev.local\share
# prod  amznfsxumd0wg1i.scg.guru\share



get-childitem -Path "\\amznfsxumd0wg1i.scg.guru\share\Backups\IP-0AE87D75\*_5abd69e4-76bc-45c9-b163-ac7200dbeadf.bak" | Sort-Object -Descending LastWriteTime