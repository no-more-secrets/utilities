return vertical{
  [1]=horizontal{
    [1]=command{ 'watch -c -n20 "nmcli --color=yes dev wifi"' },
    [2]=vertical{
      [1]=command{ 'bluetoothctl' },
      [2]=vertical{
        [1]=command{ 'pulsemixer' },
        [2]=command{ 'fish' }
      }
    }
  },
  [2]=horizontal{
    [1]=command{ 'htop' },
    [2]=command{ 'bashtop' }
  },
}
