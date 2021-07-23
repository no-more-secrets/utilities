set -e
set -o pipefail

get_id() {
    awk '/Virtual core pointer/,/Logitech/ {print}' \
     | tail -n1 | grep 'Logitech USB Receiver'      \
     | sed -nr 's/.*id=([0-9]+).*/\1/p'
}

get_prop_id() {
    grep 'Natural Scrolling Enabled (' \
      | sed -nr 's/.*\(([0-9]+)\).*/\1/p'
}

get_prop_val() {
    grep 'Natural Scrolling Enabled (' \
      | sed -nr 's/.*([01])$/\1/p'
}

id=$(xinput list | get_id)
[[ ! -z "$id" ]]
echo id: $id

prop_id=$(xinput list-props $id | get_prop_id)
[[ ! -z "$prop_id" ]]
echo prop_id: $prop_id

prop_val=$(xinput list-props $id | get_prop_val)
[[ ! -z "$prop_val" ]]
echo prop_val: $prop_val

prop_val=$(( 1-prop_val ))

echo setting prop to $prop_val

xinput set-prop $id $prop_id $prop_val
