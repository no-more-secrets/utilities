return vertical{
  [1]=horizontal{
    [1]=command{ 'watch -c -n240 "nmcli --color=yes dev wifi list --rescan yes"' },
    [2]=vertical{
      [1]=command{ 'bluetoothctl' },
      [2]=command{ 'pulsemixer' },
    }
  },
  [2]=horizontal{
    [1]=command{ 'htop' },
    [2]=command{ 'fish' }
  },
}
